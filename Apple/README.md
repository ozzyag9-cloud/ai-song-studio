# Native Apple Client

This directory contains the SwiftUI/Core AI implementation of AI Song Studio.

## Planned modules

- `App`: SwiftUI application lifecycle and dependency injection.
- `SongProject`: shared project model.
- `Producer`: local/cloud/hybrid producer abstractions.
- `CoreAI`: `.aimodel` discovery, loading and inference adapters.
- `Audio`: local transcription and audio-analysis adapters.
- `ModelCatalog`: Core AI catalog integration.
- `CloudEngines`: provider adapters for music generation.

## Core AI boundary

All Apple Core AI calls must be isolated behind a local inference protocol. This keeps simulator builds and non-Core-AI environments functional while allowing real `.aimodel` inference on supported devices.
