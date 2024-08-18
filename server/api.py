import os
import PyPDF2
import textwrap
import numpy as np
from io import BytesIO
from dotenv import load_dotenv
import typing_extensions as typing
import google.generativeai as genai
from flask import Flask, request, jsonify
import typing_extensions as typing
from google.cloud import firestore, storage

load_dotenv()
app = Flask(__name__)

genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
model = genai.GenerativeModel(
    model_name='gemini-1.0-pro-latest', 
    system_instruction="You are an expert special education assistant.")

firestore_client = firestore.Client()
storage_client = storage.Client()

class Report(typing.TypedDict):
  academic_grade: str
  employment_grade: str
  community_grade: str
  academic_report: str
  employment_report: str
  community_report: str
  skill_gaps: list

def get_student_files(student_id):
    try:
        bucket_name = os.environ.get('FIREBASE_STORAGE_BUCKET')
        if not bucket_name:
            return jsonify({'message': 'No valid storage bucket name is set in the environment variables.'}), 500
        bucket = storage_client.get_bucket(bucket_name)
        blobs = bucket.list_blobs(prefix=f"{student_id}/")
        documents = {}
        for blob in blobs:
            filename = blob.name
            try:
                content = blob.download_as_text(encoding='utf-8')
            except UnicodeDecodeError:
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
    documents = get_student_files(student_id)
    if not isinstance(documents, dict):
        return {'error': 'Unexpected response format from get_student_files...'}
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
  query_embedding = genai.embed_content(model=model,
                                        content=query,
                                        task_type="retrieval_query")
  embeddings_matrix = np.stack(embeddings_list)
  query_embedding_vector = np.array(query_embedding)
  dot_products = np.dot(embeddings_matrix, query_embedding_vector)
  relevant_indices = np.argsort(dot_products)[::-1][:3]
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
        print(context)
        prompt = textwrap.dedent("""
        Generate a detailed progress report based on the context provided. 
        The report should include:
        - Academic Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed)
        - Employment Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed)
        - Community Grade (Proficient, Satisfactory, Developing, Emerging, Skill Not Observed)
        - Academic Report (detailed paragraph)
        - Employment Report (detailed paragraph)
        - Community Report (detailed paragraph)
        - Skill Gaps (list of identified skill gaps)
        Ensure that the responses are detailed and comprehensive.
        CONTEXT: '{context}'
        """).format(context=context)
        response = model.generate_content(prompt, 
            generation_config={"response_mime_type": "application/json",
            "response_schema": Report})
        return jsonify({'response': response}), 200
    except Exception as e:
        return jsonify({'message': str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
