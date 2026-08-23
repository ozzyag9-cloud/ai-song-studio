/// Mock Providers for Testing and Development
/// These provide realistic responses without requiring real API credentials.

import Foundation

// MARK: - Mock Local Inference

class MockLocalInferenceProvider: LocalInferenceProvider {
    func discoverModels() -> [AIModelInfo] {
        return [
            AIModelInfo(
                id: "lyrics-v1",
                name: "Lyrics Generator v1",
                version: "1.0",
                type: "lyrics",
                requiresDownload: false
            ),
            AIModelInfo(
                id: "mood-analyzer-v1",
                name: "Mood Analyzer v1",
                version: "1.0",
                type: "analysis",
                requiresDownload: false
            )
        ]
    }
    
    func loadModel(_ id: String) async throws -> AIModel {
        return AIModel(id: id, name: "Mock Model: \(id)")
    }
    
    func generateLyrics(
        brief: String,
        style: String,
        mood: String,
        language: Language
    ) async throws -> String {
        // Simulate delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return """
        Verse 1:
        \(brief.prefix(20))...
        Dancing in the light, feeling so right
        
        Chorus:
        \(mood.uppercased()) emotions in the night
        Everything feels \(mood) and bright
        
        Verse 2:
        \(style) rhythm in my soul
        Making my heart whole
        """
    }
    
    func analyzeMood(audio: URL) async throws -> MoodAnalysis {
        return MoodAnalysis(
            mood: "upbeat",
            confidence: 0.87,
            intensity: 0.75
        )
    }
    
    func isAvailable() -> Bool {
        return true
    }
}

// MARK: - Mock Music Generation Engine

class MockMusicEngine: MusicGenerationEngine {
    let name = "mock-engine"
    let requiresAuth = false
    
    func isConfigured() -> Bool {
        return true
    }
    
    func generateMusic(project: SongProject) async throws -> GeneratedAudio {
        // Simulate generation delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Return mock audio URL
        let mockURL = URL(fileURLWithPath: "/tmp/mock-song-\(project.id).mp3")
        
        return GeneratedAudio(
            audioUrl: mockURL,
            mimeType: "audio/mpeg",
            duration: Double(project.durationSeconds),
            sampleRate: 44100
        )
    }
    
    func generateLyrics(
        brief: String,
        style: String,
        mood: String,
        language: Language
    ) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Mock lyrics for \(brief)"
    }
}

// MARK: - Mock Engine Provider

class MockMusicEngineProvider: MusicEngineProvider {
    private let mockEngine = MockMusicEngine()
    
    func getEngine(name: String, mode: ProducerMode) throws -> MusicGenerationEngine {
        return mockEngine
    }
    
    func listAvailableEngines() -> [String] {
        return ["mock-engine"]
    }
}

// MARK: - Mock Audio Analysis

class MockAudioAnalysisService: AudioAnalysisService {
    func analyze(audioUrl: URL) async throws -> AudioAnalysis {
        return AudioAnalysis(
            tempo: 120.5,
            key: "C Major",
            loudness: -10.2,
            duration: 180.0,
            confidence: 0.92,
            features: [
                "energy": 0.75,
                "danceability": 0.82,
                "acousticness": 0.15
            ]
        )
    }
    
    func transcribe(audioUrl: URL) async throws -> Transcript {
        return Transcript(
            text: "Mock transcription of audio",
            language: "en",
            confidence: 0.88,
            timing: [
                TimingSegment(text: "Mock", start: 0.0, end: 0.5),
                TimingSegment(text: "transcription", start: 0.5, end: 1.0)
            ]
        )
    }
}
