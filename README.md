<img src="https://github.com/mathenaangeles/Omni/blob/main/assets/green_logo.png" width="100%">

# Omni
Omni is a personalized learning app for persons with special needs. It was built using the **Gemini API**.

## Getting Started
1. Run `flutter clean`.
2. To install all the package dependencies, run `flutter pub get`.
3. Create a `.env` file with the following variables.
```
FIREBASE_API_KEY_WEB = <YOUR API KEY>
FIREBASE_API_KEY_ANDROID = <YOUR API KEY>
FIREBASE_API_KEY_IOS = <YOUR API KEY>
FIREBASE_API_KEY_MACOS = <YOUR API KEY>
FIREBASE_API_KEY_WINDOWS = <YOUR API KEY>
GOOGLE_API_KEY = <YOUR API KEY>
FIREBASE_STORAGE_BUCKET = <YOUR BUCKET NAME>
FLASK_APP = "api.py"
FLASK_DEBUG = 1
```
4. Navigate to the `server` directory. Create and activate a virtual environment.
5. Set-up OAuth with service accounts. Add a `service_account_key.json` file to the server directory.
5. Run `pip install -r requirements.txt`
6. Start the server by running `flask run`.
7. To start the application, run `flutter run -d chrome --web-renderer html `.



