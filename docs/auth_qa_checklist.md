# CinnaLink Auth QA Checklist

Use this checklist before each release and after auth-related code changes.

## Test Setup

- Environment: Firebase project connected to this app.
- Platforms: Android and Web.
- Test accounts:
  - A fresh unregistered email.
  - An existing unverified user account.
  - An existing verified user account.
- Inbox access for each test email (including Spam/Junk folder).

## Pre-Check

- App launches successfully.
- Internet connection is active.
- Firebase Auth Email/Password is enabled.

## Scenario 1: Register New Account

1. Open Register page.
2. Enter valid name, email, phone, password, and role.
3. Submit registration.
4. Verify app shows verification notice page.

Expected:
- Account is created in Firebase Auth.
- User record exists in Firestore.
- Verification email is sent.
- UI remains in current theme mode (dark/light).

## Scenario 2: Login With Unverified Account

1. Open Login page.
2. Enter unverified account email and password.
3. Tap Login.

Expected:
- Verification email is (re)sent.
- App navigates to email verification notice page.
- App does not bounce back to dashboard.
- Theme stays unchanged.

## Scenario 3: Resend Verification Email

1. On verification notice page, tap Resend Email.

Expected:
- Success or failure message is shown clearly.
- No crash or freeze.
- Theme remains unchanged.

## Scenario 4: Back To Login From Verification Page

1. On verification notice page, tap Back to Login.

Expected:
- User is signed out.
- Login page is shown.
- App does not immediately return to verification page.

## Scenario 5: Forgot Password

1. On Login page, tap Forgot password?.
2. Enter registered email.
3. Send reset link.
4. Verify reset email notice page appears.
5. Tap Resend Reset Email.

Expected:
- Reset email is sent.
- Reset notice page remains stable.
- Back to Login works.

## Scenario 6: Login With Verified Account

1. Verify account by clicking email link.
2. Return to app.
3. Login using verified account.

Expected:
- Login succeeds.
- User reaches correct dashboard by role.
- No verification notice is shown.

## Scenario 7: Wrong Credentials

1. Attempt login with wrong password.
2. Attempt login with unknown email.

Expected:
- Clear error messages are shown.
- App remains on login page.

## Scenario 8: No Network

1. Disable network.
2. Attempt login and forgot password actions.

Expected:
- User sees network-friendly error messages.
- App does not crash.

## Regression Notes

Record test result each run:

- Date:
- Platform (Android/Web):
- Build/Commit:
- Passed scenarios:
- Failed scenarios:
- Notes:
