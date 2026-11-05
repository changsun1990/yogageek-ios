import base64
import json
import os
import plistlib
import re
import sys
import uuid
from urllib.parse import quote

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account

# Records each pose's Sanskrit name with Google Cloud Text-to-Speech, uploads the clips to
# Firebase Storage, and saves each clip's link on its pose (pronunciationAudioURL in new_poses).
# Uses the same serviceAccountKey.json as seed_poses.py, or the path in SERVICE_ACCOUNT_KEY.
#
#   python3 pose_audio.py samples [language]      # a few names in each candidate voice (default en-US)
#   python3 pose_audio.py generate <voice name>   # one clip per pose, saved to pronunciation_audio/
#   python3 pose_audio.py upload                  # uploads the clips and sets pronunciationAudioURL

COLLECTION = 'new_poses'
PRONUNCIATIONS_FILE = 'pose_pronunciations.json'
SAMPLES_DIR = 'pronunciation_samples'
AUDIO_DIR = 'pronunciation_audio'
STORAGE_FOLDER = 'pronunciations'
KEY_FILE = os.environ.get('SERVICE_ACCOUNT_KEY', 'serviceAccountKey.json')
TTS_URL = 'https://texttospeech.googleapis.com/v1'

SAMPLE_NAMES = ['Tadasana', 'Adho Mukha Svanasana', 'Virabhadrasana II', 'Paschimottanasana', 'Ardha Matsyendrasana']

# English words joining two Sanskrit names, and English words left out, as in pose_pronunciations.json
CONNECTORS = {'or', 'in', 'with'}
ENGLISH = {
    'a', 'b', 'c', 'd', 'i', 'ii', 'iii', 'l', 'n', 'ankle', 'arms', 'block', 'blocks', 'bolster',
    'crunches', 'flow', 'flying', 'forehead', 'funky', 'legs', 'on', 'only', 'prep', 'preparatory',
    'shape', 'split', 'stretch', 'tiptoes', 'under', 'variation',
}

# Sounds used in the respellings ("tah-DAH-sah-nah") and their IPA, longest first.
# Indian voices get Sanskrit-style vowels; other English voices get the nearest English sounds.
CONSONANTS = [
    ('sh', 'ʃ'), ('ch', 'tʃ'),
    ('b', 'b'), ('d', 'd'), ('f', 'f'), ('g', 'ɡ'), ('h', 'h'), ('j', 'dʒ'), ('k', 'k'), ('l', 'l'),
    ('m', 'm'), ('n', 'n'), ('p', 'p'), ('s', 's'), ('t', 't'), ('v', 'v'), ('x', 'ks'), ('y', 'j'),
]
SOUNDS = {
    'indian': [
        ('eer', 'iːr'), ('oor', 'uːr'),
        ('ah', 'a'), ('ay', 'eː'), ('ee', 'iː'), ('oo', 'uː'), ('oh', 'oː'), ('ow', 'aʊ'), ('ih', 'ɪ'),
        ('a', 'a'), ('e', 'e'), ('i', 'ɪ'), ('o', 'o'), ('u', 'u'), ('r', 'r'),
    ] + CONSONANTS,
    'english': [
        ('eer', 'iɹ'), ('oor', 'ʊɹ'),
        ('ah', 'ɑ'), ('ay', 'eɪ'), ('ee', 'i'), ('oo', 'u'), ('oh', 'oʊ'), ('ow', 'aʊ'), ('ih', 'ɪ'),
        ('a', 'ɑ'), ('e', 'ɛ'), ('i', 'ɪ'), ('o', 'oʊ'), ('u', 'u'), ('r', 'ɹ'),
    ] + CONSONANTS,
}


def sound_style(voice):
    return 'indian' if voice.startswith(('en-IN', 'hi-IN')) else 'english'


def ipa(respelled_word, style):
    """'tah-DAH-sah-nah' -> 'taˈdasana' (capitalized syllable is stressed)."""
    out = ''
    for syllable in respelled_word.split('-'):
        if syllable.isupper():
            out += 'ˈ'
        rest = syllable.lower()
        while rest:
            for sound, symbol in SOUNDS[style]:
                if rest.startswith(sound):
                    out += symbol
                    rest = rest[len(sound):]
                    break
            else:
                raise SystemExit(f"Can't convert {rest!r} in {respelled_word!r} to IPA")
    return out


def ssml(pronunciations, style, pause='700ms'):
    """SSML that tells the voice exactly how to say each respelled word."""
    phrases = []
    for pronunciation in pronunciations:
        words = []
        for word in pronunciation.split():
            if word in CONNECTORS:
                words.append(word)
            else:
                words.append(f'<phoneme alphabet="ipa" ph="{ipa(word, style)}">{word.replace("-", "").lower()}</phoneme>')
        phrases.append(' '.join(words))
    return '<speak>' + f'<break time="{pause}"/>'.join(phrases) + '</speak>'


def spoken_name(pose):
    """The Sanskrit name without its English words, matching the pronunciation word for word."""
    target = len(pose['pronunciation'].split())
    name = pose['nameSanskrit'].replace('/', ' or ')
    # Try without parentheses first; "(Eka Hasta)" is the kind that's part of the Sanskrit name
    for text in (re.sub(r'\([^)]*\)', ' ', name), name.replace('(', ' ').replace(')', ' ')):
        words = [w for w in re.split(r'[\s\-]+', text) if w and w.lower() not in ENGLISH]
        words = [w for i, w in enumerate(words)
                 if w.lower() not in CONNECTORS or 0 < i < len(words) - 1]
        if len(words) == target:
            return ' '.join(words)
    raise SystemExit(f"Couldn't match {pose['nameSanskrit']!r} to {pose['pronunciation']!r}")


# How voices that read the name as written (Chirp) should see words whose usual spelling hides
# the sound: ś/ṣ written "s" (Svanasana = shvanasana), c for "ch", and ṛ clusters like "vrks".
SPOKEN_SPELLINGS = {
    'svanasana': 'Shvanasana', 'sirsasana': 'Shirshasana', 'savasana': 'Shavasana',
    'salabhasana': 'Shalabhasana', 'parsva': 'Parshva', 'parsvakonasana': 'Parshvakonasana',
    'parsvottanasana': 'Parshvottanasana', 'vasisthasana': 'Vasishthasana', 'vasishthasana': 'Vasishthasana',
    'ustrasana': 'Ushtrasana', 'paschima': 'Pashchima', 'paschimottanasana': 'Pashchimottanasana',
    'upavistha': 'Upavishtha', 'padangusthasana': 'Padangushthasana', 'pristhasana': 'Prishthasana',
    'astavakrasana': 'Ashtavakrasana', 'vrksasana': 'Vrikshasana', 'vrischika': 'Vrishchika',
    'vrischikasana': 'Vrishchikasana', 'sucirandhrasana': 'Suchirandhrasana',
    'camatkarasana': 'Chamatkarasana', 'parivrtta': 'Paree vrittah', 'parivrtti': 'Paree vrittee',
}


def spoken_text(pose):
    return ' '.join(SPOKEN_SPELLINGS.get(w.lower(), w) for w in spoken_name(pose).split())


def uses_phonemes(voice):
    # Chirp voices don't take SSML phoneme tags, so they read the Sanskrit name as written
    return 'Chirp' not in voice


def tts_session():
    creds = service_account.Credentials.from_service_account_file(
        KEY_FILE, scopes=['https://www.googleapis.com/auth/cloud-platform'])
    return AuthorizedSession(creds)


def synthesize(session, voice, text=None, ssml_text=None):
    response = session.post(f'{TTS_URL}/text:synthesize', timeout=60, json={
        'input': {'ssml': ssml_text} if ssml_text else {'text': text},
        'voice': {'languageCode': '-'.join(voice.split('-')[:2]), 'name': voice},
        'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': 0.9},
    })
    if not response.ok:
        raise RuntimeError(f"Text-to-Speech error for {voice}: {response.text[:500]}")
    return base64.b64decode(response.json()['audioContent'])


def load_poses():
    with open(PRONUNCIATIONS_FILE, 'r') as f:
        return [p for p in json.load(f) if p['pronunciation']]


def make_samples(language):
    session = tts_session()
    poses = {p['nameSanskrit']: p for p in load_poses()}
    sample_poses = [poses[name] for name in SAMPLE_NAMES]

    # For each quality tier, the first female and male voice
    voices = session.get(f'{TTS_URL}/voices', params={'languageCode': language}, timeout=30).json()['voices']
    candidates = []
    for tier in ('Chirp3-HD', 'Studio', 'Neural2', 'Wavenet'):
        for gender in ('FEMALE', 'MALE'):
            match = next((v['name'] for v in voices
                          if v['name'].startswith(f'{language}-{tier}-') and v['ssmlGender'] == gender), None)
            if match:
                candidates.append((match, gender.lower()))

    os.makedirs(SAMPLES_DIR, exist_ok=True)
    print(f"Saying {', '.join(SAMPLE_NAMES)} in {len(candidates)} voices...\n")
    for i, (voice, gender) in enumerate(candidates, 1):
        try:
            if uses_phonemes(voice):
                audio = synthesize(session, voice, ssml_text=ssml([p['pronunciation'] for p in sample_poses],
                                                                  sound_style(voice)))
            else:
                audio = synthesize(session, voice, text='. '.join(spoken_text(p) for p in sample_poses) + '.')
        except RuntimeError as error:
            print(f"  skipped {voice}: {error}")
            continue
        path = os.path.join(SAMPLES_DIR, f'{i:02d} {voice} ({gender}).mp3')
        with open(path, 'wb') as f:
            f.write(audio)
        print(f"  {path}")
    print(f"\nDone! Listen to the clips in {SAMPLES_DIR}/ and pick a voice.")


def generate(voice):
    session = tts_session()
    poses = load_poses()
    os.makedirs(AUDIO_DIR, exist_ok=True)

    # What each clip was recorded from, so a re-run only re-records clips whose voice or words changed
    manifest_path = os.path.join(AUDIO_DIR, 'manifest.json')
    manifest = json.load(open(manifest_path)) if os.path.exists(manifest_path) else {}

    print(f"Recording {len(poses)} poses with {voice}...\n")
    recorded = 0
    for i, pose in enumerate(poses, 1):
        path = os.path.join(AUDIO_DIR, f"{pose['id']}.mp3")
        if uses_phonemes(voice):
            request = {'ssml_text': ssml([pose['pronunciation']], sound_style(voice))}
        else:
            request = {'text': spoken_text(pose)}
        recipe = f"{voice}|{next(iter(request.values()))}"
        if manifest.get(pose['id']) == recipe and os.path.exists(path):
            continue

        with open(path, 'wb') as f:
            f.write(synthesize(session, voice, **request))
        manifest[pose['id']] = recipe
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=1)
        recorded += 1
        print(f"[{i}/{len(poses)}] {pose['nameSanskrit']}: {next(iter(request.values()))}")
    print(f"\nDone! Recorded {recorded} clips ({len(poses) - recorded} unchanged) in {AUDIO_DIR}/")


def upload():
    import firebase_admin
    from firebase_admin import credentials, firestore, storage

    with open('test_yoga_ios/GoogleService-Info.plist', 'rb') as f:
        bucket_name = plistlib.load(f)['STORAGE_BUCKET']
    firebase_admin.initialize_app(credentials.Certificate(KEY_FILE), {'storageBucket': bucket_name})
    db = firestore.client()
    bucket = storage.bucket()

    poses = [p for p in load_poses() if os.path.exists(os.path.join(AUDIO_DIR, f"{p['id']}.mp3"))]

    # Poses deleted from Firestore since the clips were made are skipped, so the link batch can't fail on them
    existing = {doc.id for doc in db.collection(COLLECTION).select(['nameEnglish']).stream()}
    skipped = [p['id'] for p in poses if p['id'] not in existing]
    poses = [p for p in poses if p['id'] in existing]
    if skipped:
        print(f"Skipping poses no longer in {COLLECTION}: {', '.join(skipped)}")
    print(f"Uploading {len(poses)} clips to {bucket_name}/{STORAGE_FOLDER}/...\n")

    links = {}
    for i, pose in enumerate(poses, 1):
        path = f"{STORAGE_FOLDER}/{pose['id']}.mp3"
        # A download token makes the link playable without signing in, like a link from the Firebase console
        token = str(uuid.uuid4())
        blob = bucket.blob(path)
        blob.metadata = {'firebaseStorageDownloadTokens': token}
        blob.upload_from_filename(os.path.join(AUDIO_DIR, f"{pose['id']}.mp3"), content_type='audio/mpeg')
        links[pose['id']] = (f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/"
                             f"{quote(path, safe='')}?alt=media&token={token}")
        print(f"[{i}/{len(poses)}] {path}")

    # Links are saved only after every clip uploaded, in one batch, so poses never point at a missing clip.
    # update() only changes this field, and fails rather than creating a pose if an ID is wrong.
    collection = db.collection(COLLECTION)
    batch = db.batch()
    for pose_id, link in links.items():
        batch.update(collection.document(pose_id), {'pronunciationAudioURL': link})
    batch.commit()
    print(f"\nDone! Linked {len(links)} clips to their poses in {COLLECTION}.")


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ''
    if command == 'samples':
        make_samples(sys.argv[2] if len(sys.argv) > 2 else 'en-US')
    elif command == 'generate' and len(sys.argv) > 2:
        generate(sys.argv[2])
    elif command == 'upload':
        upload()
    else:
        print("Usage: python3 pose_audio.py samples | generate <voice name> | upload")
