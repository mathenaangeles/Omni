import os
from flask import Flask, request, jsonify
from dotenv import load_dotenv
import google.generativeai as genai
from google.cloud import firestore
from llama_index import LlamaIndex 

load_dotenv()
app = Flask(__name__)

genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
model = genai.GenerativeModel('gemini-1.0-pro-latest')

db = firestore.Client()

llama_index = LlamaIndex()

@app.route('/generate_report', methods=['POST'])
def generate_report():
    try:
        student_id = request.json.get('student_id')
        if not student_id:
            return jsonify({'error': 'Student ID is required'}), 400

        student_docs = db.collection('students').document(student_id).collection('documents').stream()

        llama_index.clear()

        for doc in student_docs:
            doc_data = doc.to_dict()
            llama_index.add_document(doc_data['content']) 


        prompt = """
        Generate a detailed progress report for a student using the following indexed documents:
        - Academic Grade
        - Employment Grade
        - Community Grade
        - Academic Report
        - Employment Report
        - Community Report
        - Skill Gaps

        The grades should be either Proficient, Satisfactory, Developing, Emerging, or Skill Not Observed. The reports should provide detailed paragraphs and identify skill gaps.
        """

        response = model.generate_content(prompt)
        if not response:
            return jsonify({'error': 'Failed to generate report'}), 500

        report_data = response.get('content', {})

        return jsonify({
            'academicGrade': report_data.get('academicGrade', 'Skill Not Observed'),
            'employmentGrade': report_data.get('employmentGrade', 'Skill Not Observed'),
            'communityGrade': report_data.get('communityGrade', 'Skill Not Observed'),
            'academicReport': report_data.get('academicReport', ''),
            'employmentReport': report_data.get('employmentReport', ''),
            'communityReport': report_data.get('communityReport', ''),
            'skillGaps': report_data.get('skillGaps', [])
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
