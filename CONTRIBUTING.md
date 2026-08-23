# Contributing to AI Song Studio

## Code of Conduct

Be respectful, inclusive, and focused on making AI music creation accessible to everyone.

## Getting Started

1. **Read the docs** in `docs/` - especially `architecture.md`
2. **Check the roadmap** in `PROJECT_STATUS.md`
3. **Clone and setup**: `./scripts/setup`
4. **Run tests**: `./scripts/test`

## Workflow

### Creating a Feature Branch

```bash
# Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### Commit Messages

Use conventional commits:

```
feat: add ElevenLabs music generation adapter
fix: correct lyric validation logic
docs: update deployment guide
test: add integration tests for producer
chore: update dependencies
refactor: simplify credential manager
```

### Code Style

#### Swift
- Follow Apple's Swift style guide
- Use 4-space indentation
- Prefer `async/await` over callbacks
- Add docstring comments for public APIs

#### TypeScript/JavaScript
- Use ESLint configuration
- Prefer `async/await`
- Add TypeScript types
- Meaningful variable names

### Testing

**Before committing**:

```bash
# Run all tests
./scripts/test

# Run specific test suite
cd Apple && xcodebuild test -scheme AISongStudio
# or
cd Web/backend && npm test
```

**Coverage target**: Aim for >80% on new code

### Security Review

Before submitting any PR with:
- New provider integration
- Credential handling
- API calls
- Audio file handling

Ensure:
- [ ] No hardcoded credentials
- [ ] Error messages don't leak sensitive info
- [ ] Song Project schema audit complete
- [ ] Credential manager used correctly
- [ ] HTTPS for all external calls

## Pull Request Process

1. **Create descriptive title**: "feat: integrate ElevenLabs music generation"

2. **Write PR description**:
   ```markdown
   ## Description
   Brief summary of changes
   
   ## Related Issue
   Closes #123
   
   ## Testing
   - [ ] Unit tests added
   - [ ] Integration tests added
   - [ ] Manual testing done
   
   ## Security
   - [ ] No credentials in code
   - [ ] Error messages sanitized
   - [ ] Sensitive data handled securely
   
   ## Checklist
   - [ ] Code follows style guide
   - [ ] Documentation updated
   - [ ] Tests pass locally
   ```

3. **Wait for review** from maintainers

4. **Address feedback** in follow-up commits

5. **Merge** when approved and all tests pass

## Architecture Guidelines

### Layers

Keep clear separation between:
- **UI Layer**: SwiftUI, React components
- **Domain Model**: `SongProject`, value types
- **Orchestration**: `ProducerOrchestrator`
- **Provider Adapters**: Cloud engines, local inference
- **Services**: Credentials, storage, analysis

### Protocols

Use protocols for provider adapters:

```swift
protocol MusicGenerationEngine {
    func generateMusic(project: SongProject) async throws -> GeneratedAudio
    func isConfigured() -> Bool
}
```

This allows:
- Easy testing with mocks
- Swappable implementations
- Clear interfaces

### Error Handling

Define custom error types:

```swift
enum ProducerError: LocalizedError {
    case validationFailed([String])
    case engineNotConfigured(String)
    
    var errorDescription: String? {
        // User-friendly, sanitized messages
    }
}
```

## Adding a New Provider

### Step 1: Create Adapter

```swift
// Services/music-engines/ElevenLabsEngine.swift
class ElevenLabsEngine: MusicGenerationEngine {
    let name = "elevenlabs"
    let requiresAuth = true
    
    func isConfigured() -> Bool {
        return CredentialManager.shared.exists(key: "ELEVENLABS_API_KEY")
    }
    
    func generateMusic(project: SongProject) async throws -> GeneratedAudio {
        // Implementation
    }
}
```

### Step 2: Add to Factory

```swift
class MusicEngineProviderImpl: MusicEngineProvider {
    func getEngine(name: String, mode: ProducerMode) throws -> MusicGenerationEngine {
        switch name {
        case "elevenlabs":
            return ElevenLabsEngine()
        case "mock":
            return MockMusicEngine()
        default:
            throw ProducerError.unknownEngine(name)
        }
    }
}
```

### Step 3: Write Tests

```swift
func testElevenLabsGeneratesMusic() async throws {
    let engine = ElevenLabsEngine()
    // Assume .env has ELEVENLABS_API_KEY set
    
    let project = SongProject.create(
        title: "Test Song",
        brief: "A test",
        generationEngine: "elevenlabs"
    )
    
    let result = try await engine.generateMusic(project: project)
    XCTAssertNotNil(result.audioUrl)
}
```

### Step 4: Update Provider List

Update `docs/providers.md` with:
- Status (Implemented)
- Features
- Any gotchas
- Cost/quota info

## Documentation

When adding a feature:
1. Add docstring to public APIs
2. Update relevant file in `docs/`
3. Update `PROJECT_STATUS.md` roadmap
4. Add README section if new module

## Performance

### Guidelines
- Network calls should timeout after 30s
- Large audio files should stream, not load entirely
- UI should remain responsive during generation
- Cache analysis results (24h TTL)

## Debugging

### Apple Native
```swift
// Check credential loading
if let apiKey = CredentialManager.shared.retrieve(key: "ELEVENLABS_API_KEY") {
    os_log("API key loaded successfully", log: .default, type: .debug)
}

// Verbose logging
ProcessInfo.processInfo.environment["DEBUG"] == "true"
```

### Web/Backend
```javascript
// Set log level
process.env.LOG_LEVEL = 'debug';

// Check credentials
const key = process.env.ELEVENLABS_API_KEY;
if (!key) console.warn('ELEVENLABS_API_KEY not set');
```

## Getting Help

- **Architecture questions**: Check `docs/architecture.md`
- **Integration help**: See `docs/providers.md`
- **Deployment issues**: Check `docs/deployment.md`
- **Security concerns**: Contact maintainers privately
- **Other questions**: Open an issue or discussion

## Recognition

All contributors will be:
- Added to CONTRIBUTORS.md
- Mentioned in release notes
- Credited in app (if significant contribution)

Thank you for helping build AI Song Studio! 🎵
