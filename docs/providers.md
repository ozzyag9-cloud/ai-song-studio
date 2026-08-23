# Music Generation & Voice Providers

This document details the expected integrations with external services for music generation, voice synthesis, and transcription.

## Music Generation

### ElevenLabs

**Type**: Music generation, voice synthesis  
**Status**: To be integrated  
**Auth**: API key  
**Docs**: https://elevenlabs.io/docs

**Features**:
- Text-to-music generation
- Voice cloning
- Mono/stereo output

**Integration requirements**:
- REST client for `/v1/music-generation/*` endpoints
- Handle async generation (check polling)
- Stream or download final audio

### Google Lyria

**Type**: Music generation  
**Status**: To be integrated  
**Auth**: API key + project ID  
**Docs**: https://cloud.google.com/ai/generative-ai/docs/music

**Features**:
- Lyrical/instrumental generation
- Style transfer
- Continuation

**Integration requirements**:
- Authenticate via Google Cloud SDK
- Call Music API endpoints
- Stream generated audio

### Suno.ai

**Type**: Music generation, lyrics  
**Status**: To be integrated  
**Auth**: API key  
**Docs**: https://app.suno.ai

**Features**:
- Full song generation (voice + instruments)
- Lyrics-to-music
- Style/mood control

**Integration requirements**:
- REST API client
- Handle long-running generation (webhook or polling)
- Download final MP3

### Udio

**Type**: Music generation  
**Status**: To be integrated  
**Auth**: API key  
**Docs**: https://www.udio.com

**Features**:
- Full instrumental generation
- Loop/continuation
- BPM/key control

**Integration requirements**:
- REST API client
- Async generation with status polling
- Download STEM or mixed audio

## Voice & Speech

### Google Cloud Speech-to-Text

**Type**: Transcription  
**Status**: Planned  
**Auth**: API key  
**Docs**: https://cloud.google.com/speech-to-text/docs

**Features**:
- Transcribe audio to text
- Speaker diarization
- Multi-language support

### Deepgram

**Type**: Speech-to-text, voice synthesis  
**Status**: Planned  
**Auth**: API key  
**Docs**: https://deepgram.com/docs

**Features**:
- Low-latency transcription
- Speaker recognition
- Audio enhancement

## Local Models

### Apple Core AI

**Type**: Local inference  
**Platform**: iOS 18+, macOS 14+, device with Neural Engine  
**Status**: To be integrated  
**Models**: `.aimodel` bundles

**Features**:
- On-device lyrics generation
- Mood/sentiment analysis
- Audio feature extraction

**Integration**:
- Use `CoreML` and `NaturalLanguage` frameworks
- Load custom `.aimodel` at runtime
- No internet required

## Adapter Pattern

All providers follow a standard adapter interface:

```swift
protocol MusicGenerationEngine {
    var name: String { get }
    var requiresAuth: Bool { get }
    
    func isConfigured() -> Bool
    func generateMusic(project: SongProject) async throws -> GeneratedAudio
    func generateLyrics(brief: String, ...) async throws -> String
    func cancel()
}

protocol VoiceSynthesisEngine {
    func synthesizeVoice(text: String, voice: Voice) async throws -> Audio
}

protocol TranscriptionEngine {
    func transcribe(audio: Data) async throws -> Transcript
}
```

## Credential Management

### Loading Credentials

```swift
// Pseudo-code

func loadCredentials(provider: String) -> Credentials? {
    // 1. Try Keychain (device)
    if let keychain = KeychainStorage.load(key: "provider_\(provider)") {
        return keychain
    }
    
    // 2. Try environment (simulator/development)
    if let env = ProcessInfo.processInfo.environment["PROVIDER_\(provider)_KEY"] {
        return env
    }
    
    // 3. None found - return nil (adapter will report "unconfigured")
    return nil
}
```

### Storing Credentials

**DO NOT**:
- Store in UserDefaults or plain text files
- Embed in Song Project
- Commit to version control

**DO**:
- Use Keychain on Apple
- Use secure backend storage on web
- Load from environment at runtime
- Use `.env` file locally (development only)

## Status Summary

| Provider          | Type                 | Status | Priority |
|-------------------|----------------------|--------|----------|
| ElevenLabs        | Music + Voice        | Planned | High    |
| Google Lyria      | Music                | Planned | High    |
| Suno.ai           | Music + Lyrics       | Planned | Medium  |
| Udio              | Music (instrumental) | Planned | Medium  |
| Google Speech     | Transcription        | Planned | Medium  |
| Deepgram          | Speech + Synthesis   | Planned | Low     |
| Apple Core AI     | Local inference      | High   | High    |

## Implementation Roadmap

1. **Phase 1**: Mock providers (for UI/UX testing)
2. **Phase 2**: ElevenLabs integration (first real provider)
3. **Phase 3**: Apple Core AI adapter (local inference)
4. **Phase 4**: Additional cloud engines (Suno, Udio, Lyria)
5. **Phase 5**: Voice synthesis and transcription

## Testing

### Unit Tests
- Mock network calls
- Validate adapter interface compliance
- Test error handling and retries

### Integration Tests
- Real API calls (gated by flag)
- Generate sample projects
- Validate audio output

### Manual Testing
- Test each provider with real credentials
- Verify audio quality
- Test error scenarios (invalid key, rate limit, network error)

## Monitoring & Logging

Each adapter should log:
- Credential validation attempts
- API calls and responses (sanitized)
- Generation times
- Error details (not including credentials)

Example:

```swift
os_log("Generated music via %{public}s in %.2f seconds", log: .providers, type: .info, engine.name, duration)
```

Never log raw credentials or API keys.
