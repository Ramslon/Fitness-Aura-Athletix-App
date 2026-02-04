
# Encryption Info

**Effective date:** 2026-02-04

This page explains, at a high level, how **Fitness Aura Athletix** stores data and what encryption protections may apply.

This is an informational overview and not a security guarantee.

## What the app stores

The app stores workout logs, exercise records, and preferences primarily **on your device**.

Examples include:

- Exercise records (sets, reps, weight, difficulty, notes, dates)
- App preferences and privacy toggles
- Optional saved exercise images

## Encryption at rest (on your device)

The app itself does not implement full-database encryption for all workout records.

Instead, protection typically comes from:

- **Your device’s built-in storage encryption** (enabled by default on many modern devices)
- **Your device lock screen security** (PIN / password / biometrics)

If someone can unlock your device (or access unencrypted backups), they may be able to view your data.

## Secure storage for secrets

If you use features that require storing sensitive secrets (for example, an AI API key), the app attempts to store those using platform secure storage when available:

- Android: Keystore-backed storage
- iOS: Keychain

This is implemented using Flutter secure storage.

## Encryption in transit

When the app communicates with online services (for example, Firebase Authentication or an AI endpoint you configure), transmission security depends on the endpoint and platform network stack.

Typically, HTTPS/TLS is used for network requests when properly configured by the service.

## What you can do to improve security

- Enable a strong device lock (PIN/password + biometrics)
- Keep your OS up to date
- Avoid writing sensitive personal information in workout notes
- Be careful when exporting/sharing CSV files (treat them like personal health data)

## Questions

If you have questions about security, use the in-app support/contact options or the project support channel.

