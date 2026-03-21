const admin = require('firebase-admin');

admin.initializeApp();

// Email verification is handled directly by Firebase Auth in the Flutter app.
// No custom Cloud Functions are required for signup verification right now.
