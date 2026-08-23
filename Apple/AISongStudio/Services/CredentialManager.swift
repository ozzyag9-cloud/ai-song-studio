/// Credential Manager
/// Handles loading and managing provider credentials securely.

import Foundation
import Security

class CredentialManager: CredentialStore {
    static let shared = CredentialManager()
    
    private let keychain = KeychainStorage()
    private let environment = EnvironmentStorage()
    private let userDefaults = UserDefaultsStorage()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - CredentialStore Protocol
    
    func store(key: String, value: String) throws {
        // Prefer Keychain on device
        if !ProcessInfo.processInfo.environment.contains(where: { $0.key == "SIMULATOR_UDID" }) {
            try keychain.store(key: key, value: value)
        } else {
            // Fall back to environment/UserDefaults for simulator
            try environment.store(key: key, value: value)
        }
    }
    
    func retrieve(key: String) -> String? {
        // Try in order: Keychain, Environment, UserDefaults
        if let value = keychain.retrieve(key: key) {
            return value
        }
        if let value = environment.retrieve(key: key) {
            return value
        }
        if let value = userDefaults.retrieve(key: key) {
            return value
        }
        return nil
    }
    
    func remove(key: String) throws {
        try keychain.remove(key: key)
        try environment.remove(key: key)
        try userDefaults.remove(key: key)
    }
    
    func exists(key: String) -> Bool {
        return retrieve(key: key) != nil
    }
}

// MARK: - Keychain Storage

class KeychainStorage {
    private let serviceName = "com.aisionstudio.credentials"
    
    func store(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing if present
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CredentialError.keychainError("Failed to store credential: \(status)")
        }
    }
    
    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        // Ignore if not found
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialError.keychainError("Failed to remove credential: \(status)")
        }
    }
}

// MARK: - Environment Storage

class EnvironmentStorage {
    func store(key: String, value: String) throws {
        // Environment variables are read-only in runtime
        // This is for simulator testing only
        UserDefaults.standard.set(value, forKey: "env_\(key)")
    }
    
    func retrieve(key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key] {
            return env
        }
        return UserDefaults.standard.string(forKey: "env_\(key)")
    }
    
    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: "env_\(key)")
    }
}

// MARK: - UserDefaults Storage

class UserDefaultsStorage {
    private let prefix = "credential_"
    
    func store(key: String, value: String) throws {
        UserDefaults.standard.set(value, forKey: prefix + key)
    }
    
    func retrieve(key: String) -> String? {
        return UserDefaults.standard.string(forKey: prefix + key)
    }
    
    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: prefix + key)
    }
}

// MARK: - Error Types

enum CredentialError: LocalizedError {
    case keychainError(String)
    case invalidCredential(String)
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .invalidCredential(let message):
            return "Invalid credential: \(message)"
        }
    }
}
