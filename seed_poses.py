import json
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
# Download serviceAccountKey.json from Firebase Console:
# Settings -> Project settings -> Service accounts -> Generate new private key
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

def seed_poses():
    # Load poses from JSON file
    with open('seed_poses.json', 'r') as f:
        poses = json.load(f)

    collection = db.collection('poses')

    print(f"Uploading {len(poses)} poses to Firestore...\n")

    for i, pose in enumerate(poses, 1):
        doc_id = pose.pop('id')  # Remove id from data, use as document ID
        collection.document(doc_id).set(pose)
        print(f"[{i}/{len(poses)}] Added: {pose['nameEnglish']} ({doc_id})")

    print(f"\nDone! Added {len(poses)} poses to Firestore.")

if __name__ == "__main__":
    seed_poses()
