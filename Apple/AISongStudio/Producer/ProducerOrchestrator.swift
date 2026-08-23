/// Producer Orchestrator
/// Central coordinator for music generation workflow across local/cloud/hybrid modes.

import Foundation

/// Main producer orchestration interface
protocol ProducerProtocol: AnyObject {
    func generate(project: SongProject) async throws -> SongProject
    func generateLyrics(project: SongProject) async throws -> String
    func analyzeAudio(url: URL) async throws -> AudioAnalysis
    func critiqueSong(project: SongProject) async throws -> CritiqueReport
    func cancel()
}

/// Audio analysis result
struct AudioAnalysis: Codable {
    let tempo: Double?           // BPM
    let key: String?             // e.g., "C Major"
    let loudness: Double?        // dB
    let duration: Double         // seconds
    let confidence: Double       // 0.0 to 1.0
    let features: [String: Double]
}

/// Critique/quality report
struct CritiqueReport: Codable {
    let score: Double            // 0.0 to 1.0
    let strengths: [String]
    let weaknesses: [String]
    let recommendations: [String]
    let timestamp: String
}

/// Generation result
struct GenerationResult {
    let audioUrl: URL?
    let status: GenerationStatus
    let qualityScore: Double?
    let metadata: [String: String]
    let error: Error?
}

class ProducerOrchestrator: ProducerProtocol {
    private let localInference: LocalInferenceProvider?
    private let engineFactoryProvider: MusicEngineProvider
    private let audioAnalyzer: AudioAnalysisService?
    private var cancellationToken: CancellationToken?
    
    init(
        localInference: LocalInferenceProvider? = nil,
        engineFactory: MusicEngineProvider,
        audioAnalyzer: AudioAnalysisService? = nil
    ) {
        self.localInference = localInference
        self.engineFactoryProvider = engineFactory
        self.audioAnalyzer = audioAnalyzer
    }
    
    // MARK: - Generation Workflow
    
    func generate(project: SongProject) async throws -> SongProject {
        // Validate project
        let validationErrors = project.validate()
        guard validationErrors.isEmpty else {
            throw ProducerError.validationFailed(validationErrors)
        }
        
        var workingProject = project
        cancellationToken = CancellationToken()
        
        do {
            // Step 1: Generate or use existing lyrics
            if workingProject.lyrics == nil {
                workingProject.lyrics = try await generateLyrics(project: workingProject)
            }
            
            // Step 2: Select and configure engine based on mode
            let engine = try engineFactoryProvider.getEngine(
                name: workingProject.generationEngine,
                mode: workingProject.producerMode
            )
            
            guard engine.isConfigured() else {
                throw ProducerError.engineNotConfigured(workingProject.generationEngine)
            }
            
            // Step 3: Create new version for this generation attempt
            var currentVersion = workingProject.createNewVersion(status: .generating)
            
            // Step 4: Generate music
            let result = try await engine.generateMusic(project: workingProject)
            
            // Step 5: Update version with result
            currentVersion.audioUrl = result.audioUrl
            currentVersion.status = result.status
            currentVersion.qualityScore = result.qualityScore
            currentVersion.generatedBy = workingProject.generationEngine
            
            if let index = workingProject.versions.firstIndex(where: { $0.id == currentVersion.id }) {
                workingProject.versions[index] = currentVersion
            }
            
            // Step 6: Optional analysis if audio available
            if let audioUrl = result.audioUrl, workingProject.producerMode != .cloud {
                do {
                    let analysis = try await analyzeAudio(url: audioUrl)
                    // Store analysis in metadata
                    if let index = workingProject.versions.firstIndex(where: { $0.id == currentVersion.id }) {
                        workingProject.versions[index].metadata["analysis"] = try JSONEncoder().encode(analysis).base64EncodedString()
                    }
                } catch {
                    // Analysis is optional; don't fail generation
                    os_log("Audio analysis failed: %{public}s", log: .producer, type: .warning, error.localizedDescription)
                }
            }
            
            return workingProject
            
        } catch {
            // Mark current version as failed
            if var lastVersion = workingProject.currentVersion() {
                lastVersion.status = .failed
                if let index = workingProject.versions.firstIndex(where: { $0.id == lastVersion.id }) {
                    workingProject.versions[index] = lastVersion
                }
            }
            throw error
        }
    }
    
    func generateLyrics(project: SongProject) async throws -> String {
        // Try local inference first if available and mode allows
        if (project.producerMode == .local || project.producerMode == .hybrid),
           let local = localInference {
            do {
                return try await local.generateLyrics(
                    brief: project.brief,
                    style: project.style,
                    mood: project.mood,
                    language: project.language.first ?? .english
                )
            } catch {
                os_log("Local lyrics generation failed, falling back to cloud: %{public}s", log: .producer, type: .warning, error.localizedDescription)
            }
        }
        
        // Fall back to cloud engine
        let engine = try engineFactoryProvider.getEngine(
            name: project.generationEngine,
            mode: project.producerMode
        )
        
        guard engine.isConfigured() else {
            throw ProducerError.engineNotConfigured(project.generationEngine)
        }
        
        return try await engine.generateLyrics(
            brief: project.brief,
            style: project.style,
            mood: project.mood,
            language: project.language.first ?? .english
        )
    }
    
    func analyzeAudio(url: URL) async throws -> AudioAnalysis {
        guard let analyzer = audioAnalyzer else {
            throw ProducerError.serviceUnavailable("Audio analysis service not configured")
        }
        return try await analyzer.analyze(audioUrl: url)
    }
    
    func critiqueSong(project: SongProject) async throws -> CritiqueReport {
        guard let currentVersion = project.currentVersion(),
              let audioUrl = currentVersion.audioUrl else {
            throw ProducerError.noAudioGenerated
        }
        
        let analysis = try await analyzeAudio(url: audioUrl)
        
        // Generate critique based on analysis and project parameters
        let score = calculateQualityScore(analysis: analysis, project: project)
        let strengths = identifyStrengths(analysis: analysis)
        let weaknesses = identifyWeaknesses(analysis: analysis)
        let recommendations = generateRecommendations(project: project, analysis: analysis, score: score)
        
        return CritiqueReport(
            score: score,
            strengths: strengths,
            weaknesses: weaknesses,
            recommendations: recommendations,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    func cancel() {
        cancellationToken?.cancel()
    }
    
    // MARK: - Private Helpers
    
    private func calculateQualityScore(analysis: AudioAnalysis, project: SongProject) -> Double {
        // Simple scoring heuristic
        var score = 0.5
        
        // Adjust based on confidence
        if let confidence = analysis.confidence {
            score += confidence * 0.2
        }
        
        // Adjust based on loudness (optimal is -14 to -6 dB)
        if let loudness = analysis.loudness {
            let optimalRange = (-14.0)...(-6.0)
            if optimalRange.contains(loudness) {
                score += 0.3
            } else if loudness < -20 || loudness > 0 {
                score -= 0.2
            }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    private func identifyStrengths(analysis: AudioAnalysis) -> [String] {
        var strengths: [String] = []
        
        if let confidence = analysis.confidence, confidence > 0.8 {
            strengths.append("High quality audio detection")
        }
        
        if let tempo = analysis.tempo, tempo > 80 && tempo < 160 {
            strengths.append("Good tempo range for dancing")
        }
        
        return strengths
    }
    
    private func identifyWeaknesses(analysis: AudioAnalysis) -> [String] {
        var weaknesses: [String] = []
        
        if let loudness = analysis.loudness, loudness < -20 {
            weaknesses.append("Audio is too quiet - may need normalization")
        }
        
        if let confidence = analysis.confidence, confidence < 0.5 {
            weaknesses.append("Low confidence in audio analysis")
        }
        
        return weaknesses
    }
    
    private func generateRecommendations(project: SongProject, analysis: AudioAnalysis, score: Double) -> [String] {
        var recommendations: [String] = []
        
        if score < 0.5 {
            recommendations.append("Consider regenerating with different parameters")
        }
        
        if let loudness = analysis.loudness, loudness < -14 {
            recommendations.append("Normalize audio levels for better playback")
        }
        
        if project.lyrics == nil {
            recommendations.append("Consider generating lyrics to complete the song")
        }
        
        return recommendations
    }
}

// MARK: - Cancellation Token

class CancellationToken {
    private(set) var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
}

// MARK: - Error Types

enum ProducerError: LocalizedError {
    case validationFailed([String])
    case engineNotConfigured(String)
    case generationFailed(String)
    case analysisUnavailable
    case noAudioGenerated
    case serviceUnavailable(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Project validation failed: \(errors.joined(separator: ", "))"
        case .engineNotConfigured(let engine):
            return "Music engine '\(engine)' is not configured. Please add credentials."
        case .generationFailed(let message):
            return "Music generation failed: \(message)"
        case .analysisUnavailable:
            return "Audio analysis service is unavailable"
        case .noAudioGenerated:
            return "No audio has been generated for this project"
        case .serviceUnavailable(let service):
            return "Service unavailable: \(service)"
        case .cancelled:
            return "Generation was cancelled"
        }
    }
}

// MARK: - Logging

import os.log

extension OSLog {
    static let producer = OSLog(subsystem: "com.aisionstudio.producer", category: "orchestrator")
}
