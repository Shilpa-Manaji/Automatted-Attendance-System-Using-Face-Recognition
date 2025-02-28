from flask import Flask, request, jsonify, send_file
import os
import pandas as pd
from datetime import datetime
import pickle
import face_recognition
import numpy as np
import io
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests

# Directory to store the attendance file, images, and model data
ATTENDANCE_DIR = os.path.join(os.path.dirname(__file__), 'data')
ATTENDANCE_FILE_PATH = os.path.join(ATTENDANCE_DIR, 'attendance.xlsx')
IMAGE_DIR = os.path.join(os.path.dirname(__file__), 'images')
MODEL_FILE_PATH = os.path.join(ATTENDANCE_DIR, 'model.pkl')

# Ensure the directories exist
os.makedirs(ATTENDANCE_DIR, exist_ok=True)
os.makedirs(IMAGE_DIR, exist_ok=True)

# Global variables to store face encodings, names, and roll numbers
known_face_encodings = []
known_face_names = []
roll_number_dict = {}

# Helper function to download an image from a URL
def download_image(url, local_path):
    import requests
    if 'drive.google.com' in url:
        file_id = url.split('/d/')[1].split('/')[0]
        url = f'https://drive.google.com/uc?export=download&id={file_id}'

    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(local_path, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        return local_path
    else:
        print(f"Failed to download image from {url}")
        return None

# Load training data
def load_training_data(excel_file):
    data = pd.read_excel(excel_file)
    
    global known_face_encodings, known_face_names, roll_number_dict
    known_face_encodings = []
    known_face_names = []
    roll_number_dict = {}  # Reset roll number dictionary
    
    for index, row in data.iterrows():
        image_url = row['Images']
        name = row['Names']
        roll_number = row.get('Roll no', '')  # Get roll number if available
        
        roll_number_dict[name] = roll_number  # Store roll number for each name
        
        local_image_path = os.path.join(IMAGE_DIR, f"{name}.jpg")
        if not os.path.exists(local_image_path):
            local_image_path = download_image(image_url, local_image_path)
        
        if not local_image_path or not os.path.exists(local_image_path):
            print(f"Warning: Image file not found: {local_image_path}")
            continue
        
        image = face_recognition.load_image_file(local_image_path)
        
        if image is None:
            continue
        
        face_encodings = face_recognition.face_encodings(image)
        
        if not face_encodings:
            print(f"No face encodings found in image: {local_image_path}")
            continue
        
        if name not in known_face_names:
            known_face_encodings.append(face_encodings[0])
            known_face_names.append(name)
    
    # Save model data to a file
    save_model_data()

def save_model_data():
    with open(MODEL_FILE_PATH, 'wb') as file:
        pickle.dump({
            'encodings': known_face_encodings,
            'names': known_face_names,
            'roll_numbers': roll_number_dict
        }, file)

def load_model_data():
    global known_face_encodings, known_face_names, roll_number_dict
    if os.path.exists(MODEL_FILE_PATH):
        with open(MODEL_FILE_PATH, 'rb') as file:
            model_data = pickle.load(file)
            known_face_encodings = model_data['encodings']
            known_face_names = model_data['names']
            roll_number_dict = model_data['roll_numbers']

# Recognize faces
def recognize_face(image_path, tolerance=0.6):
    if not os.path.exists(image_path):
        print(f"Error: Image file not found: {image_path}")
        return []
    
    image = face_recognition.load_image_file(image_path)
    face_locations = face_recognition.face_locations(image)
    face_encodings = face_recognition.face_encodings(image, face_locations)
    
    face_names = set()
    for face_encoding in face_encodings:
        matches = face_recognition.compare_faces(known_face_encodings, face_encoding, tolerance)
        name = "Unknown"
        
        if any(matches):
            face_distances = face_recognition.face_distance(known_face_encodings, face_encoding)
            best_match_index = np.argmin(face_distances)
            if matches[best_match_index]:
                name = known_face_names[best_match_index]
        
        if name != "Unknown":
            face_names.add(name)
    
    return list(face_names)

# Mark attendance
def mark_attendance(names):
    if names:
        # Create a new DataFrame with the updated attendance
        attendance_data = pd.DataFrame(columns=['Roll Number', 'Name', 'Timestamp'])

        new_entries = []
        for name in names:
            roll_number = roll_number_dict.get(name, '')  # Get roll number from the dictionary
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            new_entries.append({'Roll Number': roll_number, 'Name': name, 'Timestamp': timestamp})

        # Add new entries to the DataFrame
        attendance_data = pd.concat([attendance_data, pd.DataFrame(new_entries)], ignore_index=True)

        # Sort by Roll Number
        attendance_data.sort_values(by='Roll Number', ascending=True, inplace=True)

        # Save the updated DataFrame to Excel, overwriting the existing file
        try:
            attendance_data.to_excel(ATTENDANCE_FILE_PATH, index=False)
            print("Attendance marked!")
        except Exception as e:
            print(f"Error saving attendance data: {e}")
    else:
        # If no faces recognized, clear the attendance file if it exists
        if os.path.exists(ATTENDANCE_FILE_PATH):
            os.remove(ATTENDANCE_FILE_PATH)
            print("No known faces recognized, attendance file cleared.")
        else:
            print("No known faces recognized, attendance file already empty.")

@app.route('/train', methods=['POST'])
def train():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file and file.filename.endswith('.xlsx'):
        try:
            excel_file = io.BytesIO(file.read())
            load_training_data(excel_file)
            return jsonify({"message": "Training complete!"}), 200
        except Exception as e:
            return jsonify({"error": f"Error processing file: {e}"}), 500
    else:
        return jsonify({"error": "Invalid file type"}), 400

@app.route('/recognize', methods=['POST'])
def recognize():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file and file.filename.lower().endswith(('.jpg', '.jpeg', '.png')):
        try:
            image_path = 'temp_image.jpg'
            file.save(image_path)

            # Load the model data (encodings, names, etc.)
            load_model_data()

            # Perform face recognition
            recognized_names = recognize_face(image_path)

            # Remove the temporary file after processing
            os.remove(image_path)

            if len(recognized_names) == 0:
                # No faces detected, clear the attendance file
                mark_attendance([])  # Call with an empty list to clear the file
                return jsonify({"message": "No faces detected, attendance file cleared", "status": "failure"}), 204
            else:
                # Only mark attendance if faces are recognized
                mark_attendance(recognized_names)
                return jsonify({"message": "Attendance marked", "status": "success", "recognized_names": recognized_names}), 200

        except Exception as e:
            return jsonify({"error": f"Error processing file: {e}"}), 500
    else:
        return jsonify({"error": "Invalid file type"}), 400
    
@app.route('/view_attendance', methods=['GET'])
def view_attendance():
    if os.path.exists(ATTENDANCE_FILE_PATH):
        return send_file(ATTENDANCE_FILE_PATH, as_attachment=True)
    else:
        return jsonify({"error": "Attendance file not found"}), 404

if __name__ == '__main__':
    load_model_data()  # Load model data on startup
    app.run(debug=True, port=5000)
