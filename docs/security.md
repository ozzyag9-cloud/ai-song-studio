# Security Policy

## Core Principles

1. **Never commit secrets** to version control.
2. **No embedded credentials** in application code.
3. **Platform-specific secure storage** for runtime credentials.
4. **Adapter pattern** to allow graceful degradation if credentials are missing.
5. **Zero trust** for external APIs — validate all responses.

## Secrets Management

### Prohibited
- API keys in code
- Private SSH keys or certificates
- OAuth tokens
- Database passwords
- Hardcoded configuration

### Permitted
- Template files (`.env.example`)
- Documentation of expected fields
- Public keys or certs
- Non-sensitive configuration (e.g., backend URL, log level)

### Implementation

#### Local Development
1. Copy `.env.example` to `.env` (gitignored)
2. Fill in real credentials
3. Application loads from `.env` at startup

#### Apple Device
1. Store credentials in Keychain at first launch or settings
2. Retrieve from Keychain at runtime
3. Example:
```swift
import Security

func storeInKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]
    SecItemAdd(query as CFDictionary, nil)
}

func retrieveFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: kCFBooleanTrue as Any
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
}
```

#### Web (Simulator/Browser)
1. Credentials stored securely on backend
2. Frontend never holds API keys
3. Backend proxies all provider calls
4. Example flow:
   - Frontend: `POST /api/generate-music` with project data
   - Backend: Load provider credentials, call ElevenLabs API
   - Backend: Return generated audio to frontend
   - Frontend: Display result

#### Backend/Server
1. Load from environment variables at startup
2. Use `process.env.PROVIDER_KEY` (Node.js) or equivalent
3. Consider secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.) for production

### Audit & Monitoring

Log credential access (sanitized):

```swift
os_log("Loaded credentials for %{public}s", log: .security, type: .info, provider)
```

Never log the actual key value.

## Song Project Security

The Song Project format must **never** include:
- API keys
- OAuth tokens
- Provider credentials
- User personal information (beyond title/brief)

Rationale: Projects may be exported, shared, or stored in untrusted locations.

**Approved fields**:
- `id`, `title`, `brief`
- `language`, `lyrics`, `style`, `mood`
- `durationSeconds`, `producerMode`, `generationEngine`
- `versions` (references to generated audio, not raw credentials)

**Disallowed**:
- `elevenlabsApiKey`
- `googleCloudServiceAccount`
- `userPassword`

## API Call Security

### Client Verification
When calling external APIs:
1. Verify SSL/TLS certificates
2. Use certificate pinning for sensitive providers (optional, high-security)
3. Validate response signatures if supported by provider

### Error Handling
- Never leak credentials in error messages
- Log error codes, not raw responses with keys
- Return user-friendly error messages

```swift
// Bad
os_log("Failed to call ElevenLabs: %{public}s", error.description)
// ^ Might include API key in error message

// Good
os_log("Music generation failed for engine %{public}s", engine.name)
// ^ Sanitized
```

### Rate Limiting & Backoff
- Implement exponential backoff for API calls
- Respect `Retry-After` headers
- Cache results where safe to do so

## Code Review Checklist

Before committing, check:
- [ ] No `.env` file (only `.env.example`)
- [ ] No API keys in strings or code
- [ ] Credentials loaded from secure storage at runtime
- [ ] Error messages sanitized (no credential leaks)
- [ ] All external calls use HTTPS
- [ ] Song Project schema audit complete
- [ ] Logging statements reviewed for PII

## Breach Response

1. **Immediate**: Revoke compromised credentials in provider dashboard
2. **Audit**: Identify where secret was exposed (code commit, log file, etc.)
3. **Fix**: Update code to prevent recurrence (new secret management strategy, rotation, etc.)
4. **Communicate**: Alert users if their data was at risk
5. **Document**: Update this guide with lessons learned

## Compliance

### GDPR
- Users can request data export (Song Project + metadata)
- Users can request deletion of projects and audio
- Privacy policy must disclose third-party provider usage (ElevenLabs, Google, etc.)

### API Terms
- ElevenLabs: Disclose that user audio may be used for model training (unless opted out)
- Google Lyria: Comply with Google Cloud terms
- Others: Review each provider's terms before integrating

## Future Enhancements

- [ ] OAuth 2.0 flow for user-provided credentials
- [ ] Credential rotation (auto-refresh tokens)
- [ ] Hardware security module (HSM) support for production
- [ ] Secrets manager integration (AWS Secrets Manager, etc.)
- [ ] End-to-end encryption for project storage
