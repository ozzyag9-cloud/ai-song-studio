# AI Song Studio

A multi-platform AI music creation and production studio for **songs, voices, instruments and lyrics**.

## Project direction

AI Song Studio is being built as a hybrid local + cloud production environment:

- **Apple Core AI** for on-device intelligence and model inference where supported.
- **Core AI Models / Catalog** for discovering and selecting compatible local models.
- **Zylos Core** as an optional producer-agent/orchestration layer.
- Pluggable cloud music engines such as ElevenLabs and Google Lyria.
- A shared Song Project format so projects can move between native and web clients.

## Native Apple target

The native client targets the current Apple Core AI development stack (iOS/iPadOS/macOS 27+ and Xcode 27+ where required). Core AI integration is isolated behind protocols so the application remains testable without Core AI in simulator environments.

## Security

Never commit API keys, GitHub tokens, private SSH keys, model credentials, or other secrets. Provider credentials belong in secure platform/server-side storage.

## Initial native architecture

```text
SwiftUI
  └── Song Studio UI
       ├── Song Project
       ├── Producer
       ├── Lyrics
       ├── Audio
       └── Model Manager

Producer Engine
  ├── Core AI Local
  ├── Cloud Music
  └── Zylos Agent Bridge

Core AI
  └── .aimodel / InferenceFunction
```

## Status

Native Apple/Core AI foundation: **in development**.

The web studio remains the cross-platform companion while native on-device inference is developed and tested on supported Apple hardware.
