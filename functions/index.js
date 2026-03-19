const admin = require('firebase-admin');
const functions = require('firebase-functions');
const crypto = require('crypto');
const nodemailer = require('nodemailer');

admin.initializeApp();
const db = admin.firestore();

const gmailUser = process.env.GMAIL_USER;
const gmailAppPassword = process.env.GMAIL_APP_PASSWORD;
const otpSecret = process.env.OTP_SECRET || 'change-this-secret';

function otpHash(uid, otp) {
    return crypto
        .createHmac('sha256', otpSecret)
        .update(`${uid}:${otp}`)
        .digest('hex');
}

function makeOtp() {
    return String(Math.floor(100000 + Math.random() * 900000));
}

function getTransporter() {
    if (!gmailUser || !gmailAppPassword) {
        throw new Error('Missing GMAIL_USER or GMAIL_APP_PASSWORD env vars');
    }

    return nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: gmailUser,
            pass: gmailAppPassword,
        },
    });
}

function setCors(res) {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
}

exports.sendEmailOtp = functions.https.onRequest(async (req, res) => {
    setCors(res);
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ success: false, message: 'Method not allowed' });
        return;
    }

    const { uid, email, name } = req.body || {};
    if (!uid || !email) {
        res.status(400).json({ success: false, message: 'uid and email are required' });
        return;
    }

    try {
        const otp = makeOtp();
        const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000);

        await db.collection('email_otps').doc(uid).set({
            otpHash: otpHash(uid, otp),
            expiresAt,
            attempts: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        const transporter = getTransporter();
        await transporter.sendMail({
            from: `CinnaLink <${gmailUser}>`,
            to: email,
            subject: 'CinnaLink verification code',
            html: `
        <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px;background:#ffffff;border-radius:10px;">
          <h2 style="margin:0 0 12px 0;color:#1f6f4a;">Verify your email</h2>
          <p style="margin:0 0 14px 0;">Hi ${name || 'there'}, use this OTP to verify your email:</p>
          <div style="font-size:34px;letter-spacing:6px;font-weight:700;background:#f3f8f6;border:1px dashed #1f6f4a;padding:14px 18px;border-radius:8px;display:inline-block;">${otp}</div>
          <p style="margin:14px 0 0 0;color:#555;">This OTP expires in 10 minutes.</p>
        </div>
      `,
        });

        res.status(200).json({ success: true, message: 'OTP sent' });
    } catch (error) {
        console.error('sendEmailOtp error:', error);
        res.status(500).json({ success: false, message: 'Failed to send OTP' });
    }
});

exports.verifyEmailOtp = functions.https.onRequest(async (req, res) => {
    setCors(res);
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ success: false, message: 'Method not allowed' });
        return;
    }

    const { uid, otp } = req.body || {};
    if (!uid || !otp) {
        res.status(400).json({ success: false, message: 'uid and otp are required' });
        return;
    }

    try {
        const otpRef = db.collection('email_otps').doc(uid);
        const otpDoc = await otpRef.get();

        if (!otpDoc.exists) {
            res.status(200).json({ success: false, message: 'OTP not found' });
            return;
        }

        const data = otpDoc.data() || {};
        const attempts = data.attempts || 0;

        if (attempts >= 5) {
            res.status(200).json({ success: false, message: 'Too many attempts' });
            return;
        }

        const expiresAt = data.expiresAt;
        if (!expiresAt || expiresAt.toMillis() < Date.now()) {
            res.status(200).json({ success: false, message: 'OTP expired' });
            return;
        }

        const valid = data.otpHash === otpHash(uid, String(otp));
        if (!valid) {
            await otpRef.update({
                attempts: attempts + 1,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            res.status(200).json({ success: false, message: 'Invalid OTP' });
            return;
        }

        await db.collection('users').doc(uid).set({
            emailVerified: true,
            requiresOtpVerification: false,
            emailVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await otpRef.delete();

        res.status(200).json({ success: true, message: 'Email verified' });
    } catch (error) {
        console.error('verifyEmailOtp error:', error);
        res.status(500).json({ success: false, message: 'Verification failed' });
    }
});
