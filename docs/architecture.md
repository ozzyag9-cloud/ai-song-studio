# AI Song Studio Architecture

## Overview

AI Song Studio is a hybrid AI music production platform allowing users to create songs through a combination of local and cloud inference. The architecture is modular, with clear separation between presentation, domain, orchestration, and provider layers.

```
┌─────────────────────────────────────────────────────────────┐
│                     AI SONG STUDIO                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
    ┌───▼────┐                  ┌────▼────┐
    │ Web    │                  │  Apple  │
    │ Client │                  │ Native  │
    └───┬────┘                  └────┬────┘
        │                            │
        └──────────────┬─────────────┘
                       │
              ┌────────▼────────┐
              │  Song Project   │
              │  (Shared Model) │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │ Producer Orchestrator
              │ (Local/Cloud/Hybrid)
              └────────┬────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    ┌───▼────┐   ┌─────▼───┐   ┌─────▼───┐
    │ Local  │   │  Cloud  │   │ Hybrid  │
    │ Core AI│   │ Engines │   │ Blend   │
    └────────┘   └─────────┘   └─────────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
    ┌───▼────────┐           ┌────────▼────┐
    │   Audio    │           │   Providers │
    │  Analysis  │           │  (Adapters) │
    └────────────┘           └─────────────┘
```

## Layers

### 1. Presentation Layer

**Web**: React/Next.js frontend with API client
**Apple**: SwiftUI with dependency injection

Responsibilities:
- User interaction and feedback
- Form validation
- Session state management
- Audio playback and visualization

### 2. Domain Model: Song Project

A portable, platform-agnostic representation of a music project.

**Location**: `Shared/schemas/SongProject.swift` or `SongProject.ts`

**Required fields**:
- `id: UUID`
- `title: string`
- `brief: string` (user description)
- `language: [Language]` (English, French, etc.)
- `lyrics: string | null`
- `style: string` (genre, mood)
- `durationSeconds: int`
- `producerMode: ProducerMode` (local, cloud, hybrid)
- `generationEngine: string` (provider name)
- `versions: [SongVersion]` (immutable snapshots)
- `createdAt: ISO8601`
- `updatedAt: ISO8601`

**Design rule**: The project format must NOT contain API secrets, tokens, or provider credentials.

### 3. Producer Orchestrator

Central coordinator for music generation workflow.

**Location**: `Apple/AISongStudio/Producer/` or `Services/producer/`

**Responsibilities**:
- Select appropriate providers based on mode and project config
- Coordinate local/cloud generation
- Manage generation workflow and retries
- Orchestrate versioning
- Route analysis and critique tasks
- Integrate with Zylos agent if enabled

**Modes**:
- **Local**: Use only on-device Core AI (Apple) or local models
- **Cloud**: Use only external music-generation APIs
- **Hybrid**: Use Core AI for planning/analysis, cloud for music generation

### 4. Model/Inference Layer

#### Apple Core AI

**Location**: `Apple/AISongStudio/CoreAI/`

Responsibilities:
- Discover available `.aimodel` bundles
- Load and manage model lifecycle
- Execute inference through `InferenceFunction`
- Map results to Song Project
- Handle device capability checks (simulator vs. real device)

**Interface** (Protocol):
```swift
protocol LocalInferenceProvider {
    func discoverModels() -> [AIModelInfo]
    func loadModel(_ id: String) throws -> AIModel
    func generateLyrics(brief: String, ...) async throws -> String
    func analyzeMood(audio: Data) async throws -> MoodAnalysis
}
```

#### Cloud Engines

**Location**: `Apple/AISongStudio/CloudEngines/` or `Services/music-engines/`

Adapters for external music-generation providers:
- ElevenLabs
- Google Lyria
- Suno.ai
- Udio

Each adapter implements a standard interface:
```swift
protocol MusicGenerationEngine {
    func generateMusic(project: SongProject) async throws -> Audio
    func generateLyrics(brief: String, ...) async throws -> String
}
```

Credentials are loaded from secure platform storage (environment, Keychain, etc.), never embedded in code.

### 5. Audio Analysis & Critique

**Location**: `Apple/AISongStudio/Audio/` or `Services/audio-analysis/`

Responsibilities:
- Transcription (speech-to-text)
- Audio feature extraction (tempo, key, loudness, etc.)
- Quality scoring (coherence, musicality)
- Mood/emotion analysis
- Comparison and diff reporting

### 6. Persistent Memory

**Location**: `Services/memory/` or `Apple/AISongStudio/Services/`

Responsibilities:
- Store Song Projects
- Version history
- User preferences
- Generation history/cache

### 7. Provider Credentials & Configuration

**Location**: Environment variables, Keychain (Apple), or secure backend storage

**Security rules**:
- Never commit credentials to version control
- Use `.env` locally; `.env.example` as template
- Load credentials at runtime from platform-specific secure storage
- Implement adapter pattern so apps work without secrets (graceful degradation)

## Data Flow: Generate a Song

1. **User Input** → Present UI form
2. **Validate & Create Project** → Song Project instance
3. **Orchestrate**:
   - Select mode (local/cloud/hybrid)
   - Select engine based on config
4. **Local (if applicable)**:
   - Load Core AI models
   - Generate lyrics, structure, melody
5. **Cloud (if applicable)**:
   - Call music engine API with project
   - Stream or download audio
6. **Analyze & Critique**:
   - Extract audio features
   - Score quality
   - Generate report
7. **Persist & Version**:
   - Store Song Project + audio snapshots
   - Increment version number
8. **Return to User** → Display result with playback, critique, regeneration options

## Deployment

### Local (Simulator/Device)
- Xcode build & run
- Core AI models bundled or downloaded dynamically
- Credentials from `.env` (simulator) or Keychain (device)

### Cloud Backend (Optional)
- Docker container or serverless function
- Expose REST API for web client
- Manage shared Song Project storage
- Proxy cloud music engine calls if needed

### Web
- Static site (React/Next.js)
- API client calls backend
- Credentials never sent to frontend (backend proxies)

## API Boundaries

### Apple Native
- No direct HTTP calls to music engines (go through Producer)
- Core AI calls isolated behind `LocalInferenceProvider` protocol
- Credentials in Keychain; loaded by Producer

### Web
- Frontend talks to backend API only
- Backend proxies all provider calls
- Frontend never holds credentials

### Shared
- Song Project serialization (JSON/Codable)
- Import/export format
- No provider secrets in the schema

## Security Checklist

- [ ] `.env` in `.gitignore`
- [ ] `.env.example` as template (no real secrets)
- [ ] All credential loading at runtime
- [ ] Adapter pattern so app works without secrets
- [ ] Song Project schema audit (no secrets embedded)
- [ ] Keychain usage on Apple (not UserDefaults)
- [ ] Backend proxies provider APIs (web clients don't call providers directly)
- [ ] Audit logs for credential access

## Next Steps

1. Implement Song Project Codable (Swift/JSON)
2. Create Producer orchestrator skeleton
3. Add ElevenLabs adapter (first cloud engine)
4. Add mock/simulator Core AI provider
5. Build basic web and native UIs
6. Add version history and persistence
7. Integrate Zylos agent bridge
8. Add audio analysis module
