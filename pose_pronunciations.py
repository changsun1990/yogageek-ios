import json
import os
import sys
import firebase_admin
from firebase_admin import credentials, firestore

# Adds Sanskrit pronunciations to the poses the app reads (new_poses).
# Uses the same serviceAccountKey.json as seed_poses.py, or the path in SERVICE_ACCOUNT_KEY.
#
#   python3 pose_pronunciations.py export   # read-only: saves current pose names to pose_names.json
#   python3 pose_pronunciations.py upload   # sets the "pronunciation" field from pose_pronunciations.json

COLLECTION = 'new_poses'
NAMES_FILE = 'pose_names.json'
PRONUNCIATIONS_FILE = 'pose_pronunciations.json'

cred = credentials.Certificate(os.environ.get('SERVICE_ACCOUNT_KEY', 'serviceAccountKey.json'))
firebase_admin.initialize_app(cred)

db = firestore.client()

def export_names():
    poses = []
    for doc in db.collection(COLLECTION).stream():
        data = doc.to_dict()
        poses.append({
            'id': doc.id,
            'nameEnglish': data.get('nameEnglish', ''),
            'nameSanskrit': data.get('nameSunskrit', ''),
            'pronunciation': data.get('pronunciation', ''),
        })

    poses.sort(key=lambda p: p['nameEnglish'])

    with open(NAMES_FILE, 'w') as f:
        json.dump(poses, f, indent=2, ensure_ascii=False)

    print(f"Exported {len(poses)} poses to {NAMES_FILE}")

def upload_pronunciations(pose_ids=()):
    with open(PRONUNCIATIONS_FILE, 'r') as f:
        entries = [e for e in json.load(f) if e['pronunciation']]
    # Naming poses updates just those, so pronunciations edited in Firestore elsewhere aren't overwritten
    if pose_ids:
        unknown = set(pose_ids) - {e['id'] for e in entries}
        if unknown:
            raise SystemExit(f"Not in {PRONUNCIATIONS_FILE}: {', '.join(sorted(unknown))}")
        entries = [e for e in entries if e['id'] in pose_ids]

    collection = db.collection(COLLECTION)

    # One batch, so either every pose is updated or none are (Firestore allows 500 writes per batch).
    # update() only changes the pronunciation field, and fails rather than creating a pose if an ID is wrong.
    batch = db.batch()
    for entry in entries:
        batch.update(collection.document(entry['id']), {'pronunciation': entry['pronunciation']})

    print(f"Updating pronunciation on {len(entries)} poses in {COLLECTION}...")
    batch.commit()

    for entry in entries:
        print(f"  {entry['nameSanskrit']}: {entry['pronunciation']}")
    print(f"\nDone! Updated {len(entries)} poses.")

if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ''
    if command == 'export':
        export_names()
    elif command == 'upload':
        upload_pronunciations(set(sys.argv[2:]))
    else:
        print("Usage: python3 pose_pronunciations.py export | upload [pose id ...]")
