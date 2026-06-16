// server.js  –  Node.js FCM Notification Backend
// Run: node server.js
//
// Endpoints:
//   GET  /                        – health check
//   POST /send-message            – chat message notification
//   POST /send-friend-request     – friend request notification
//   POST /send-request-accepted   – friend request accepted notification
//   POST /send-notification       – generic fallback (kept for backward compatibility)
//
//   NOTE: Call notifications are handled entirely by ZEGOCLOUD ZPNs (zego_services.dart).
//         Do NOT send call FCM from this server — it would cause duplicate notifications.

const express    = require('express');
const admin      = require('firebase-admin');
const bodyParser = require('body-parser');
const cors       = require('cors');

// =======================
// CONFIG
// =======================
const PORT = process.env.PORT || 3000;

// =======================
// APP INIT
// =======================
const app = express();
app.use(cors());
app.use(bodyParser.json());

// Request logger
app.use((req, res, next) => {
  const ts = new Date().toISOString();
  console.log(`[${ts}] ${req.method} ${req.path}`);
  next();
});

// =======================
// FIREBASE ADMIN INIT
// =======================
// On Render: set FIREBASE_SERVICE_ACCOUNT env var with the full JSON string.
// Locally:   place serviceAccountkey.json next to server.js.
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  console.log('🔑 Using service account from environment variable');
} else {
  serviceAccount = require('./serviceAccountkey.json');
  console.log('🔑 Using service account from local serviceAccountkey.json');
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log('✅ Firebase Admin Initialized');
console.log(`🚀 Server will start on port ${PORT}`);

// =======================
// HELPERS
// =======================

/**
 * Build a data-only FCM message (works in background/killed state on Android).
 * All values must be strings.
 */
function buildDataMessage(token, dataMap, priority = 'high') {
  return {
    token,
    data: Object.fromEntries(
      Object.entries(dataMap).map(([k, v]) => [k, String(v)])
    ),
    android: { priority },
  };
}

/** Send an FCM message and return the response. Throws on failure. */
async function sendFcm(message) {
  const response = await admin.messaging().send(message);
  console.log('✅ FCM sent:', response);
  return response;
}

/** Standard success response */
function ok(res, messageId) {
  return res.json({ success: true, messageId });
}

/** Standard error response */
function fail(res, error, status = 500) {
  console.error('❌ Error:', error.message || error);
  return res.status(status).json({ success: false, error: error.message || String(error) });
}

/** Validate required fields; returns missing fields array */
function missing(obj, fields) {
  return fields.filter(f => !obj[f]);
}

// =======================
// HEALTH CHECK
// =======================
app.get('/', (req, res) => {
  res.json({
    status : 'ok',
    message: 'VibeTalk FCM Notification Server',
    time   : new Date().toISOString(),
    endpoints: [
      'POST /send-message',
      'POST /send-friend-request',
      'POST /send-request-accepted',
      'POST /send-notification  (generic)',
    ],
    note: 'Call notifications are handled by ZEGOCLOUD ZPNs — no /send-call endpoint needed.',
  });
});

// =======================
// CHAT MESSAGE NOTIFICATION
// =======================
// Body: { token, senderName, senderId, chatId, body }
app.post('/send-message', async (req, res) => {
  try {
    const { token, senderName, senderId, chatId, body } = req.body;
    console.log('💬 /send-message:', { senderName, chatId });

    const required = missing(req.body, ['token', 'senderName', 'senderId', 'chatId', 'body']);
    if (required.length) {
      return res.status(400).json({ success: false, error: `Missing fields: ${required.join(', ')}` });
    }

    const message = buildDataMessage(token, {
      type      : 'message',
      title     : senderName,
      body,
      senderId,
      senderName,
      chatId,
    });

    const response = await sendFcm(message);
    return ok(res, response);
  } catch (e) {
    return fail(res, e);
  }
});

// =======================
// FRIEND REQUEST NOTIFICATION
// =======================
// Body: { token, senderName, senderId, requestId }
app.post('/send-friend-request', async (req, res) => {
  try {
    const { token, senderName, senderId, requestId } = req.body;
    console.log('👥 /send-friend-request:', { senderName, senderId });

    const required = missing(req.body, ['token', 'senderName', 'senderId', 'requestId']);
    if (required.length) {
      return res.status(400).json({ success: false, error: `Missing fields: ${required.join(', ')}` });
    }

    const message = buildDataMessage(token, {
      type     : 'friend_request',
      title    : 'New Friend Request',
      body     : `${senderName} sent you a friend request`,
      senderId,
      senderName,
      requestId,
    });

    const response = await sendFcm(message);
    return ok(res, response);
  } catch (e) {
    return fail(res, e);
  }
});

// =======================
// FRIEND REQUEST ACCEPTED NOTIFICATION
// =======================
// Body: { token, acceptorName, acceptorId, chatId }
app.post('/send-request-accepted', async (req, res) => {
  try {
    const { token, acceptorName, acceptorId, chatId } = req.body;
    console.log('✅ /send-request-accepted:', { acceptorName, chatId });

    const required = missing(req.body, ['token', 'acceptorName', 'acceptorId', 'chatId']);
    if (required.length) {
      return res.status(400).json({ success: false, error: `Missing fields: ${required.join(', ')}` });
    }

    const message = buildDataMessage(token, {
      type        : 'request_accepted',
      title       : 'Friend Request Accepted',
      body        : `${acceptorName} accepted your friend request`,
      userId      : acceptorId,
      acceptorName,
      chatId,
    });

    const response = await sendFcm(message);
    return ok(res, response);
  } catch (e) {
    return fail(res, e);
  }
});

// =======================
// GENERIC NOTIFICATION (backward-compatible)
// =======================
// Body: { token, title, body, data? }
app.post('/send-notification', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;
    console.log('📩 /send-notification:', { title });

    const required = missing(req.body, ['token', 'title', 'body']);
    if (required.length) {
      return res.status(400).json({ success: false, error: `Missing fields: ${required.join(', ')}` });
    }

    const message = buildDataMessage(token, {
      title,
      body,
      ...(data || {}),
    });

    const response = await sendFcm(message);
    return ok(res, response);
  } catch (e) {
    return fail(res, e);
  }
});

// =======================
// 404 HANDLER
// =======================
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.path}` });
});

// =======================
// SERVER START
// =======================
app.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('╔══════════════════════════════════════╗');
  console.log('║   VibeTalk FCM Notification Server   ║');
  console.log(`║   http://localhost:${PORT}              ║`);
  console.log('╚══════════════════════════════════════╝');
  console.log('');
});
