# Apple Core AI Integration Guide

## Overview

Apple Core AI provides on-device machine learning capabilities for lyrics generation, mood analysis, and other NLP tasks. This guide explains how to integrate and test Core AI in AI Song Studio.

## Supported Devices

- **iOS**: 18+ (iPhone 11 Pro, XS, or newer with A12+ chip)
- **macOS**: 14.6+ (with Apple Silicon or compatible Intel)
- **Simulator**: Limited (Core AI not available on simulator)

## Available Models

### Lyrics Generation
- Model ID: `com.apple.CoreML.lyrics-generator-v1`
- Input: Brief description, style, mood, language
- Output: Lyrical content
- Latency: 2-10 seconds (device-dependent)

### Mood Analysis
- Model ID: `com.apple.CoreML.mood-analyzer-v1`
- Input: Audio file (URL)
- Output: Mood, intensity, emotion scores
- Latency: 1-5 seconds

### Transcription
- Framework: `Speech` (standard, not Core AI)
- Input: Audio file
- Output: Transcribed text
- Supported languages: 20+

## Integration Steps

### 1. Add Frameworks to Xcode

```swift
// In your target Build Phases > Link Binary With Libraries:
- CoreML
- NaturalLanguage
- Speech (optional, for transcription)
```

### 2. Create Core AI Provider

```swift
import CoreML
import NaturalLanguage

class AppleCoreAIProvider: LocalInferenceProvider {
    private var loadedModels: [String: MLModel] = [:]
    
    func discoverModels() -> [AIModelInfo] {
        // Return available .aimodel bundles
        return [
            AIModelInfo(
                id: "lyrics-v1",
                name: "Apple Lyrics Generator",
                version: "1.0",
                type: "lyrics",
                requiresDownload: false
            )
        ]
    }
    
    func loadModel(_ id: String) async throws -> AIModel {
        // Load .aimodel from app bundle
        guard let modelURL = Bundle.main.url(forResource: id, withExtension: "mlmodel") else {
            throw CoreAIError.modelNotFound(id)
        }
        
        let model = try MLModel(contentsOf: modelURL)
        loadedModels[id] = model
        return AIModel(id: id, name: id)
    }
    
    func generateLyrics(
        brief: String,
        style: String,
        mood: String,
        language: Language
    ) async throws -> String {
        let model = try await loadModel("lyrics-v1")
        
        // Prepare input
        let input = LyricsGeneratorInput(
            brief: brief,
            style: style,
            mood: mood,
            language: language.rawValue
        )
        
        // Run inference
        let output = try model.prediction(input: input)
        return output.lyrics
    }
    
    func isAvailable() -> Bool {
        // Check if device supports Core AI
        return !ProcessInfo.processInfo.environment.contains { $0.key == "SIMULATOR_UDID" }
    }
}
```

### 3. Handle Simulator vs Device

Core AI is unavailable on simulator. Use mock provider:

```swift
let inferenceProvider: LocalInferenceProvider = {
    #if targetEnvironment(simulator)
    return MockLocalInferenceProvider()
    #else
    return AppleCoreAIProvider()
    #endif
}()
```

### 4. Add .aimodel Files

Drag `.aimodel` files into Xcode:
1. Select target
2. Build Phases > Copy Bundle Resources
3. Verify .aimodel files are included

## Testing

### Unit Tests

```swift
func testLyricsGeneration() async throws {
    let provider = MockLocalInferenceProvider()
    let lyrics = try await provider.generateLyrics(
        brief: "A summer romance",
        style: "pop",
        mood: "upbeat",
        language: .english
    )
    XCTAssertFalse(lyrics.isEmpty)
}
```

### Integration Tests

```swift
func testCoreAIOnDevice() async throws {
    let provider = AppleCoreAIProvider()
    
    // Skip if on simulator
    guard provider.isAvailable() else {
        print("Skipping: Core AI not available on simulator")
        return
    }
    
    let lyrics = try await provider.generateLyrics(...)
    XCTAssertFalse(lyrics.isEmpty)
}
```

### Manual Testing

1. Deploy to real device
2. Create Song Project in app
3. Tap "Generate Lyrics" (local mode)
4. Verify lyrics appear in 2-10 seconds
5. Check Xcode Console for errors

## Performance Tuning

### Batch Processing
For generating multiple lyrics, batch requests:

```swift
let briefDescriptions = ["Song 1", "Song 2", "Song 3"]
let results = try await withThrowingTaskGroup(of: String.self) { group in
    for brief in briefDescriptions {
        group.addTask {
            try await provider.generateLyrics(brief: brief, ...)
        }
    }
    return try await group.reduce(into: []) { $0.append($1) }
}
```

### Memory Management
Core AI models can be memory-intensive. Unload when not needed:

```swift
func unloadModel(_ id: String) {
    loadedModels.removeValue(forKey: id)
}
```

## Error Handling

```swift
enum CoreAIError: LocalizedError {
    case modelNotFound(String)
    case inferenceError(String)
    case unsupportedDevice
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model not found: \(id)"
        case .inferenceError(let msg):
            return "Inference failed: \(msg)"
        case .unsupportedDevice:
            return "Device does not support Core AI"
        case .memoryError:
            return "Insufficient memory for inference"
        }
    }
}
```

## Fallback Strategy

If Core AI unavailable or fails:

```swift
func generateLyricsWithFallback(brief: String, ...) async throws -> String {
    do {
        return try await coreAIProvider.generateLyrics(brief: brief, ...)
    } catch {
        os_log("Core AI failed, falling back to cloud: %{public}s", error.localizedDescription)
        return try await cloudEngineProvider.generateLyrics(brief: brief, ...)
    }
}
```

## Privacy & Security

- Core AI runs entirely on-device
- No data sent to Apple or external servers
- Models are part of app bundle (not downloaded at runtime)
- User data never leaves device unless explicitly uploaded

## Future Enhancements

- [ ] Music generation on device (when models available)
- [ ] Faster lyrics with optimized quantization
- [ ] Multi-language support expansion
- [ ] Fine-tuning with user-provided examples
- [ ] On-device audio feature extraction
