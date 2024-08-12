import os
from flask import Flask, jsonify
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
app = Flask(__name__)

genai.configure(api_key=os.environ["GOOGLE_API_KEY"])
model = genai.GenerativeModel('gemini-1.0-pro-latest')

@app.route('/', methods = ['GET','POST'])
def generate_progress_report():
    res =  model.generate_content("The opposite of hot is")
    print(res)
    return ''

if __name__=="main":
    app.run()