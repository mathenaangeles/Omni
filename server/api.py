import os
import PyPDF2
import textwrap
import numpy as np
from io import BytesIO
from dotenv import load_dotenv
import typing_extensions as typing
import google.generativeai as genai
from google.oauth2 import service_account
from flask import Flask, request, jsonify
import google.ai.generativelanguage as glm
from google.cloud import firestore, storage

load_dotenv()
app = Flask(__name__)

genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
model = genai.GenerativeModel(
    model_name='gemini-1.5-pro', 
)

firestore_client = firestore.Client()
storage_client = storage.Client()

class Report(typing.TypedDict):
  academic_grade: str
  employment_grade: str
  community_grade: str
  academic_report: str
  employment_report: str
  community_report: str
  skill_gaps: list[str]

credentials = service_account.Credentials.from_service_account_file('./service_account_key.json')
scoped_credentials = credentials.with_scopes(
    ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/generative-language.retriever'])
retriever_service_client = glm.RetrieverServiceClient(credentials=credentials)

def get_files(student_id=None):
    try:
        bucket_name = os.environ.get('FIREBASE_STORAGE_BUCKET')
        if not bucket_name:
            return jsonify({'message': 'No valid storage bucket name is set in the environment variables.'}), 500
        bucket = storage_client.get_bucket(bucket_name)
        if student_id:
            blobs = bucket.list_blobs(prefix=f"{student_id}/")
        else:
            blobs = bucket.list_blobs(prefix=f"general/")
        documents = {}
        for blob in blobs:
            filename = blob.name
            try:
                content = blob.download_as_text(encoding='utf-8')
            except UnicodeDecodeError:
                content = blob.download_as_bytes()
                if filename.endswith('.pdf'):
                    pdf_reader = PyPDF2.PdfReader(BytesIO(content))
                    text = ""
                    for page in range(len(pdf_reader.pages)):
                        text += pdf_reader.pages[page].extract_text()
                    content = text
                else:
                    content = content.decode('latin-1')
            documents[filename] = content
        return documents
    except Exception as e:
        return e

def split_content(content, chunk_size=1000):
    return textwrap.wrap(content, chunk_size)
    
def generate_student_embeddings(student_id):
    documents = get_files(student_id)
    if not isinstance(documents, dict):
        return {'error': 'Unexpected response format...'}
    student_embeddings = firestore_client.collection("students").document(student_id).collection('embeddings')
    existing_filenames = set()
    existing_documents = student_embeddings.stream()
    for document in existing_documents:
        existing_filenames.add(document.to_dict().get('name'))
    for filename, content in documents.items():
        if filename in existing_filenames:
            continue
        chunks = split_content(content)
        for index, chunk in enumerate(chunks):
            if not chunk.strip():
                continue
            try:
                embedding = genai.embed_content(
                    model="models/text-embedding-004",
                    content=chunk,
                    task_type="retrieval_document",
                )["embedding"]
                document = {
                    "name": f"{filename}_{index}",
                    "embedding": embedding,
                    "text": chunk,
                }
                student_embeddings.add(document) 
            except Exception as e:
                print(f"ERROR: {str(e)}")
    return student_embeddings

def get_context(query, student_embeddings):
  embeddings_list = [doc['embedding'] for doc in student_embeddings]
  texts_list = [doc['text'] for doc in student_embeddings]
  query_embedding = genai.embed_content(model="models/text-embedding-004",
                                        content=query,
                                        task_type="retrieval_query")
  embeddings_matrix = np.stack(embeddings_list)
  query_embedding_vector = np.array(query_embedding["embedding"])
  dot_products = np.dot(embeddings_matrix, query_embedding_vector)
  relevant_indices = np.argsort(dot_products)[::-1][:5]
  relevant_snippets = [texts_list[idx] for idx in relevant_indices]
  return relevant_snippets

@app.route('/generate_report', methods=['POST'])
def generate_report():
    student_id = request.json.get('student_id')
    if not student_id:
        return jsonify({'error': 'No student was found.'}), 400
    try:
        generate_student_embeddings(student_id)
        student_embeddings_ref = firestore_client.collection("students").document(student_id).collection('embeddings')
        student_embeddings = [doc.to_dict() for doc in student_embeddings_ref.stream()]
        if not student_embeddings:
            return jsonify({'message': 'No embeddings were found for the given student.'}), 404
        query = """"What are the most relevant snippets that will inform a progress report detailing the performance of 
        a student in terms of their academics, employment, and community?"""
        context = get_context(query, student_embeddings)
        prompt = textwrap.dedent("""
        Based on the provided context, generate a comprehensive progress report for the student. The report should be thorough and include the following:
        - **Academic Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed):** Evaluate the student's academic performance or scholastic ability.
        - **Employment Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed):** Evaluate the student's employment-related skills.
        - **Community Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed):** Evaluate the student's community living skills. 
        - **Academic Report:** Write a detailed report (at least 5 sentences) summarizing the student's academic achievements, areas of strength, and areas for improvement
            in the subjects they are learning.
        - **Employment Report:** Write a detailed report (at least 5 sentences) discussing the student's employability skills, including practical applications, 
            strengths, and areas needing development.
        - **Community Report:** Write a detailed report (at least 5 sentences) that highlights the student's contributions and engagement within their community, 
            as well as any notable social or life skills that are indicative of how well they can integrate into society.
        - **Skill Gaps:** Identify and list specific skill gaps observed in the student. Some examples of skill gaps are Mathematics, Science, 
            Understanding Citizenship, Financial Literacy, Collaboration, etc.
        Ensure that each section of the report is detailed, well-organized, and provides a clear picture of the student's overall performance. For the grades, please refer to
            the grading criteria below:
        - **Proficient:** Student is able to perform skill successfully and independently.
        - **Satisfactory:** Student is able to perform skill successfully with minimal cues (e.g. auditory cues).
        - **Developing:** Student is able to perform skill successfully with moderate prompts/cues.        
        - **Emerging:** Student is able to perform skill successfully with maximal assistance (e.g. hand over hand assistance). 
        - **Skill Not Observed:** Student may still be adjusting to the curriculum; external problems.                  
        CONTEXT: '{context}'
        """).format(context=context)
        response = model.generate_content(prompt, 
            generation_config={"response_mime_type": "application/json",
            "response_schema": Report})
        return jsonify(response.text), 200
    except Exception as e:
        return jsonify({'message': str(e)}), 500

def create_corpus_and_add_documents(documents):
    corpus = glm.Corpus(display_name="Omni Corpus")
    create_corpus_request = glm.CreateCorpusRequest(corpus=corpus)
    create_corpus_response = retriever_service_client.create_corpus(create_corpus_request)
    corpus_resource_name = create_corpus_response.name
    
    for filename, content in documents.items():
        document = glm.Document(display_name=filename)
        document_metadata = [glm.CustomMetadata(key="filename", string_value=filename)]
        document.custom_metadata.extend(document_metadata)
        create_document_request = glm.CreateDocumentRequest(parent=corpus_resource_name, document=document)
        create_document_response = retriever_service_client.create_document(create_document_request)
        document_resource_name = create_document_response.name

        chunks = split_content(content)
        if not chunks:
            print(f"No chunks created for document: {filename}")
            continue
        
        create_chunk_requests = []
        for chunk in chunks:
            chunk_entity = glm.Chunk(data={'string_value': chunk})
            chunk_entity.custom_metadata.append(glm.CustomMetadata(key="tags", string_list_value=glm.StringList(values=["General"])))
            create_chunk_request = glm.CreateChunkRequest(parent=document_resource_name, chunk=chunk_entity)
            create_chunk_requests.append(create_chunk_request)
        
        if create_chunk_requests:
            batch_create_chunks_request = glm.BatchCreateChunksRequest(parent=document_resource_name, requests=create_chunk_requests)
            retriever_service_client.batch_create_chunks(batch_create_chunks_request)
        else:
            print(f"No chunk requests created for document: {filename}")
    
    return corpus_resource_name

def query_corpus(corpus_resource_name, user_query, results_count=5):
    retriever_service_client = glm.RetrieverServiceClient()
    chunk_metadata_filter = glm.MetadataFilter(
        key='chunk.custom_metadata.tags',
        conditions=[glm.Condition(string_value='General', operation=glm.Condition.Operator.INCLUDES)]
    )
    query_request = glm.QueryCorpusRequest(
        name=corpus_resource_name,
        query=user_query,
        results_count=results_count,
        metadata_filters=[chunk_metadata_filter]
    )
    query_response = retriever_service_client.query_corpus(query_request)
    return query_response

@app.route('/assistant', methods=['POST'])
def assistant():
    data = request.json
    corpus_resource_name = data.get("corpus_resource_name")
    query = data.get("user_query")
    try:
        documents = get_files()
        corpus_resource_name = create_corpus_and_add_documents(documents)
        if not corpus_resource_name or not query:
            return jsonify({'error': 'Missing required parameters...'}), 400
        response = query_corpus(corpus_resource_name, query, 1)
        return jsonify(response), 200
    except Exception as e:
        return jsonify({'message': str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)