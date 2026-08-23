/// Shared protocol definitions for provider adapters and services.

import Foundation

// MARK: - Local Inference

/// Local on-device inference provider (Core AI, local models)
protocol LocalInferenceProvider: AnyObject {
    /// Discover available local models
    func discoverModels() -> [AIModelInfo]
    
    /// Load a specific model
    func loadModel(_ id: String) async throws -> AIModel
    
    /// Generate lyrics from brief description
    func generateLyrics(
        brief: String,
        style: String,
        mood: String,
        language: Language
    ) async throws -> String
    
    /// Analyze audio mood/emotion
    func analyzeMood(audio: URL) async throws -> MoodAnalysis
    
    /// Check if model inference is available on this device
    func isAvailable() -> Bool
}

struct AIModelInfo: Codable {
    let id: String
    let name: String
    let version: String
    let type: String  // "lyrics", "music", "analysis"
    let requiresDownload: Bool
}

struct AIModel {
    let id: String
    let name: String
}

struct MoodAnalysis: Codable {
    let mood: String
    let confidence: Double
    let intensity: Double
}

// MARK: - Music Generation

/// Music generation engine adapter
protocol MusicGenerationEngine: AnyObject {
    var name: String { get }
    var requiresAuth: Bool { get }
    
    /// Check if engine has valid credentials
    func isConfigured() -> Bool
    
    /// Generate music from song project
    func generateMusic(project: SongProject) async throws -> GeneratedAudio
    
    /// Generate lyrics
    func generateLyrics(
        brief: String,
        style: String,
        mood: String,
        language: Language
    ) async throws -> String
}

struct GeneratedAudio {
    let audioUrl: URL?
    let mimeType: String
    let duration: Double?
    let sampleRate: Int?
}

/// Factory for creating music generation engines
protocol MusicEngineProvider: AnyObject {
    func getEngine(name: String, mode: ProducerMode) throws -> MusicGenerationEngine
    func listAvailableEngines() -> [String]
}

// MARK: - Audio Analysis

/// Audio analysis service
protocol AudioAnalysisService: AnyObject {
    /// Analyze audio file
    func analyze(audioUrl: URL) async throws -> AudioAnalysis
    
    /// Transcribe audio to text
    func transcribe(audioUrl: URL) async throws -> Transcript
}

struct Transcript: Codable {
    let text: String
    let language: String
    let confidence: Double
    let timing: [TimingSegment]
}

struct TimingSegment: Codable {
    let text: String
    let start: Double
    let end: Double
}

// MARK: - Persistent Storage

/// Song project storage service
protocol SongProjectStore: AnyObject {
    /// Save or update project
    func save(_ project: SongProject) async throws
    
    /// Load project by ID
    func load(_ id: UUID) async throws -> SongProject?
    
    /// List all projects
    func listAll() async throws -> [SongProject]
    
    /// Delete project
    func delete(_ id: UUID) async throws
    
    /// Export project as JSON
    func export(_ id: UUID) async throws -> Data
    
    /// Import project from JSON
    func import(_ data: Data) async throws -> SongProject
}

// MARK: - Credential Management

/// Secure credential storage
protocol CredentialStore: AnyObject {
    /// Store credential
    func store(key: String, value: String) throws
    
    /// Retrieve credential
    func retrieve(key: String) -> String?
    
    /// Remove credential
    func remove(key: String) throws
    
    /// Check if credential exists
    func exists(key: String) -> Bool
}

// MARK: - Configuration

/// Producer configuration
struct ProducerConfig {
    let mode: ProducerMode
    let primaryEngine: String
    let fallbackEngine: String?
    let enableLocalInference: Bool
    let enableAnalysis: Bool
    
    static let `default` = ProducerConfig(
        mode: .hybrid,
        primaryEngine: "elevenlabs",
        fallbackEngine: nil,
        enableLocalInference: true,
        enableAnalysis: true
    )
}
