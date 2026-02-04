
# Privacy Policy

**Effective date:** 2026-02-04

This Privacy Policy explains how **Fitness Aura Athletix** ("the app") handles information when you use the app.

This document is provided for transparency and clarity. It is not legal advice.

## Summary

- Your workout logs and most settings are stored **locally on your device** by default.
- If you enable optional AI features, some workout metadata (and optionally notes) may be sent to the AI endpoint you configure.
- If you sign in, authentication is handled through **Firebase Authentication** (and providers like Google/Apple if you choose).

## Information the app may process

### 1) Account information (if you sign in)

If you create an account or sign in, the app uses Firebase Authentication. Depending on your sign-in method, Firebase and your identity provider may process:

- Email address and/or provider identifiers
- Authentication tokens required to keep you signed in

We do not request unnecessary profile fields.

### 2) Workout and exercise data

The app lets you enter and store fitness information such as:

- Exercises performed, sets, reps, weight, rest time, difficulty/RPE
- Notes you type in (optional)
- The date you performed a workout/exercise
- (Optional) Custom exercise images you save

By default, these are stored locally on your device.

### 3) App settings and preferences

The app stores preferences locally (for example: privacy toggles, UI preferences, and feature settings).

### 4) Optional AI features

If you enable AI features, the app may send limited data to the AI endpoint you configure in settings.

What may be sent:

- Workout metadata needed to generate suggestions (e.g., exercise names, sets/reps/weights)
- If you enable the "Allow notes to be sent to AI" option, your notes may also be sent

What you control:

- Whether AI features are enabled at all
- Whether notes are allowed to be sent
- The endpoint and API key (stored using secure storage when available)

**Important:** Avoid entering sensitive personal information into notes if you plan to use AI features.

## Where your data is stored

- **On-device storage:** Most data is stored locally (device files and local preferences). Anyone with physical access to an unlocked device may be able to see it.
- **Secure storage (when available):** Some secrets (like an AI API key) may be stored using the platform’s secure storage (Android Keystore / iOS Keychain) via Flutter secure storage.
- **Firebase Authentication:** If you sign in, account authentication is handled by Firebase.

## Sharing and exporting

The app may let you export workout data (for example, as CSV). Exports are saved to a temporary file for sharing.

When you export or share, you control where the file goes. Treat exports like personal health data.

## Data retention

- On-device data remains until you delete it (by clearing records in-app where available, uninstalling the app, or clearing app storage).
- Authentication data is managed by Firebase; you can sign out at any time.

## Children’s privacy

This app is not intended for children. If you believe a child has provided personal information, please remove it from the device and discontinue use.

## Security

We use reasonable safeguards in the app (see **Encryption Info**) and recommend enabling a strong device lock (PIN/biometrics) to protect on-device data.

No method of storage or transmission is 100% secure.

## Changes to this policy

We may update this policy from time to time. The updated policy will be available in the app.

## Contact

For questions about privacy, use the in-app support/contact options or the project support channel.

