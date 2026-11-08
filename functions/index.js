const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { TextToSpeechClient } = require("@google-cloud/text-to-speech");

initializeApp();
const textToSpeech = new TextToSpeechClient();

// Same voice and pace as the Sanskrit pronunciation clips (pose_audio.py)
const VOICE = "en-US-Chirp3-HD-Achernar";
const SPEAKING_RATE = 0.9;

// Limits that keep one call cheap; the app sends phrases in batches of this size
const MAX_PHRASES = 20;
const MAX_LENGTH = 500;

/**
 * Turns practice phrases (pose names, teaching cues) into natural-voice MP3 recordings.
 * Each phrase is recorded once and kept in Storage under a hash of the voice and text,
 * so repeats (and the same phrase from other users) reuse the recording.
 * Returns a playable link per phrase, or null where recording failed.
 */
exports.synthesizeSpeech = onCall(
  { enforceAppCheck: true, maxInstances: 5, memory: "256MiB", timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to use the practice voice.");
    }

    const phrases = request.data?.texts;
    const valid = Array.isArray(phrases) &&
      phrases.length > 0 &&
      phrases.length <= MAX_PHRASES &&
      phrases.every((text) => typeof text === "string" && text.trim() !== "" && text.length <= MAX_LENGTH);
    if (!valid) {
      throw new HttpsError("invalid-argument", `Send 1 to ${MAX_PHRASES} phrases of up to ${MAX_LENGTH} characters.`);
    }

    const bucket = getStorage().bucket();
    const results = await Promise.allSettled(phrases.map((text) => recordingURL(bucket, text.trim())));
    const urls = results.map((result, index) => {
      if (result.status === "fulfilled") return result.value;
      logger.error("Recording failed", { text: phrases[index], error: result.reason?.message });
      return null;
    });
    return { urls };
  },
);

async function recordingURL(bucket, text) {
  const key = crypto.createHash("sha256").update(`${VOICE}|${SPEAKING_RATE}|${text}`).digest("hex");
  const file = bucket.file(`speech/${key}.mp3`);

  let token;
  const [exists] = await file.exists();
  if (exists) {
    const [metadata] = await file.getMetadata();
    token = metadata.metadata?.firebaseStorageDownloadTokens?.split(",")[0];
  }

  if (!token) {
    const [response] = await textToSpeech.synthesizeSpeech({
      input: { text },
      voice: { languageCode: "en-US", name: VOICE },
      audioConfig: { audioEncoding: "MP3", speakingRate: SPEAKING_RATE },
    });
    // A download token makes the link playable without signing in, like a link from the Firebase console
    token = crypto.randomUUID();
    await file.save(response.audioContent, {
      contentType: "audio/mpeg",
      metadata: { metadata: { firebaseStorageDownloadTokens: token } },
    });
  }

  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
}
