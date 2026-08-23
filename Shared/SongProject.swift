/// Shared domain model for Song Projects across all platforms.
///
/// A Song Project is the central, portable unit representing a music composition.
/// It can be created, edited, and stored on any platform (Apple native, web, backend).
/// The format is intentionally simple and does not contain provider credentials or secrets.

import Foundation

/// Unique project identifier
typealias ProjectID = UUID

/// Supported languages for lyrics and generation
enum Language: String, Codable {
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case japanese = "ja"
    case chinese = "zh"
    case korean = "ko"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        case .korean: return "한국어"
        }
    }
}

/// Producer execution mode
enum ProducerMode: String, Codable {
    /// Prefer on-device inference (Core AI, local models)
    case local
    /// Use only cloud-based engines (ElevenLabs, Suno, etc.)
    case cloud
    /// Hybrid: use Core AI for analysis/planning, cloud for generation
    case hybrid
}

/// Generation status for a version
enum GenerationStatus: String, Codable {
    case draft = "draft"           // Not yet generated
    case generating = "generating" // In progress
    case completed = "completed"   // Successfully generated
    case failed = "failed"         // Generation failed
    case cancelled = "cancelled"   // User cancelled
}

/// Information about a generated version
struct SongVersion: Codable, Identifiable {
    let id: UUID
    let versionNumber: Int
    let timestamp: ISO8601DateFormatter.ISO8601DateFormatter
    
    /// URL to the generated audio file (cloud storage, local file URI, etc.)
    let audioUrl: URL?
    
    /// Generation status
    let status: GenerationStatus
    
    /// Which engine generated this version
    let generatedBy: String?
    
    /// Optional generation parameters and metadata
    let metadata: [String: String]
    
    /// Quality score if available (0.0 to 1.0)
    let qualityScore: Double?
    
    /// User notes about this version
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, versionNumber, timestamp, audioUrl, status, generatedBy, metadata, qualityScore, notes
    }
    
    init(
        id: UUID = UUID(),
        versionNumber: Int,
        timestamp: String,
        audioUrl: URL? = nil,
        status: GenerationStatus = .draft,
        generatedBy: String? = nil,
        metadata: [String: String] = [:],
        qualityScore: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.versionNumber = versionNumber
        self.timestamp = timestamp
        self.audioUrl = audioUrl
        self.status = status
        self.generatedBy = generatedBy
        self.metadata = metadata
        self.qualityScore = qualityScore
        self.notes = notes
    }
}

/// Core Song Project data structure
struct SongProject: Codable, Identifiable {
    /// Unique project identifier
    let id: ProjectID
    
    /// User-provided title
    let title: String
    
    /// Brief description of the song idea
    let brief: String
    
    /// Supported languages for the song
    let language: [Language]
    
    /// Lyrical content (if provided/generated)
    var lyrics: String?
    
    /// Style/genre descriptor (e.g., "pop", "jazz", "electronic")
    let style: String
    
    /// Mood descriptor (e.g., "upbeat", "melancholic", "energetic")
    let mood: String
    
    /// Target duration in seconds
    let durationSeconds: Int
    
    /// Producer execution mode
    let producerMode: ProducerMode
    
    /// Preferred music generation engine
    let generationEngine: String
    
    /// Version history (immutable snapshots)
    var versions: [SongVersion]
    
    /// Additional project metadata
    var metadata: ProjectMetadata
    
    /// ISO8601 creation timestamp
    let createdAt: String
    
    /// ISO8601 last modification timestamp
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, brief, language, lyrics, style, mood, durationSeconds
        case producerMode, generationEngine, versions, metadata, createdAt, updatedAt
    }
}

/// Project metadata (tags, favorites, archival status, etc.)
struct ProjectMetadata: Codable {
    var tags: [String]
    var archived: Bool
    var favorite: Bool
    var customData: [String: String]
    
    init(
        tags: [String] = [],
        archived: Bool = false,
        favorite: Bool = false,
        customData: [String: String] = [:]
    ) {
        self.tags = tags
        self.archived = archived
        self.favorite = favorite
        self.customData = customData
    }
}

// MARK: - Factory Methods

extension SongProject {
    /// Create a new Song Project with defaults
    static func create(
        title: String,
        brief: String,
        language: [Language] = [.english],
        style: String = "pop",
        mood: String = "neutral",
        durationSeconds: Int = 180,
        producerMode: ProducerMode = .hybrid,
        generationEngine: String = "elevenlabs"
    ) -> SongProject {
        let now = ISO8601DateFormatter().string(from: Date())
        return SongProject(
            id: UUID(),
            title: title,
            brief: brief,
            language: language,
            lyrics: nil,
            style: style,
            mood: mood,
            durationSeconds: durationSeconds,
            producerMode: producerMode,
            generationEngine: generationEngine,
            versions: [
                SongVersion(
                    versionNumber: 1,
                    timestamp: now,
                    status: .draft
                )
            ],
            metadata: ProjectMetadata(),
            createdAt: now,
            updatedAt: now
        )
    }
}

// MARK: - Validation

extension SongProject {
    /// Validate project required fields
    func validate() -> [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Title is required")
        }
        
        if brief.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Brief description is required")
        }
        
        if language.isEmpty {
            errors.append("At least one language must be selected")
        }
        
        if style.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Style is required")
        }
        
        if durationSeconds <= 0 || durationSeconds > 600 {
            errors.append("Duration must be between 1 and 600 seconds")
        }
        
        if generationEngine.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Generation engine must be selected")
        }
        
        return errors
    }
}

// MARK: - Version Management

extension SongProject {
    /// Get the current (latest) version
    func currentVersion() -> SongVersion? {
        return versions.sorted { $0.versionNumber < $1.versionNumber }.last
    }
    
    /// Create a new version for regeneration
    mutating func createNewVersion(
        status: GenerationStatus = .draft,
        generatedBy: String? = nil
    ) -> SongVersion {
        let nextVersion = (versions.map { $0.versionNumber }.max() ?? 0) + 1
        let now = ISO8601DateFormatter().string(from: Date())
        let newVersion = SongVersion(
            versionNumber: nextVersion,
            timestamp: now,
            status: status,
            generatedBy: generatedBy
        )
        versions.append(newVersion)
        updatedAt = now
        return newVersion
    }
    
    /// Update the current version with generated audio
    mutating func updateCurrentVersion(
        audioUrl: URL?,
        status: GenerationStatus,
        qualityScore: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        guard var current = currentVersion() else { return }
        
        let now = ISO8601DateFormatter().string(from: Date())
        current.timestamp = now
        current.audioUrl = audioUrl
        current.status = status
        current.qualityScore = qualityScore
        
        if let index = versions.firstIndex(where: { $0.id == current.id }) {
            versions[index] = current
        }
        
        updatedAt = now
    }
}

// MARK: - Export/Import

extension SongProject {
    /// Encode to JSON data
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    
    /// Decode from JSON data
    static func fromJSON(_ data: Data) throws -> SongProject {
        let decoder = JSONDecoder()
        return try decoder.decode(SongProject.self, from: data)
    }
    
    /// Save to file URL
    func saveToFile(url: URL) throws {
        let data = try toJSON()
        try data.write(to: url)
    }
    
    /// Load from file URL
    static func loadFromFile(url: URL) throws -> SongProject {
        let data = try Data(contentsOf: url)
        return try fromJSON(data)
    }
}
