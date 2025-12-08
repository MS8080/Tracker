import Foundation
import CryptoKit
import Security

/// Service for authenticating with Google Cloud using service account credentials
class GoogleAuthService {
    static let shared = GoogleAuthService()

    // Service account credentials
    private let clientEmail = "behavior-tracker-app@gen-lang-client-0564188419.iam.gserviceaccount.com"
    private let tokenURI = "https://oauth2.googleapis.com/token"

    // Private key (RSA)
    private let privateKeyPEM = """
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC0OJYESKqUL9wD
5zMq/dT80CAUulnAE8JhFRhFa8wgWNiQOhNeip9MbxGXylSPAmc60cJ5GydfSK60
Sggqy/nW6lkGhcujXECCZfenoE5q3zTZkFE+7x/yQnbRcvIS8KRKTAHtBoNt47w4
bOyVRm7LRJkdKrxoxKnVy8wgBgNwX2yChGNvMcwdYY9EmBnP7X/DDU721McBrF2n
+PnT7FsThZR6cJK5kDNrgHW/pR/mAuV3LtgEQPrMKALrSXl+E2mqL1V+g1abP0p9
x6RSPNy4Yd2gr9GfeK2aRlhUXoEu9PzPotJq/NK4wPcd6hrid9TU6G11PXFiHbke
uWBgAFsLAgMBAAECggEAAPF234jd0664cRDJtMTlU3lnYZRkGdxAnS92FA7vX4/3
ejHDnjANi2HdbrTxYlo53hXw9Z9NwnLn7yugBVFR+mz5kE4s9arq74PHGwp8vpRy
e10E/9ZSjXsJkikO2UiHI5hoPixVjcKuXoE7b8CRneC7CGsL12SIGwVZCSXe6Lyk
28XFTb8N0eHhP89B3toQBFrjVpvcysNUIhc3HQnteLzgHRhMI5PvI899pHkIyWV+
6rPPyCFzhc0cjLcueKXdIhrDm2/QiloynBml7k6FJDmLPNAK5gNXIjQTcMrcvAnF
wv3zHc2yr1ZEysLeShUn/v2XFhPDL7042lyPQBBHKQKBgQDrRbS7uJxakLh20lTM
vx9nLSoQKc75hAZMF1NvfAYMhdiR+gLXyh0vcLaHaqUIwrRZPBYbcykf6Xkldv29
3MnAZM5Zm/ge1F0X1+O67FSrWZ9JEobEr8BOcp273q7syCDuzdj5XiKt/pd0dKG2
T6vk2Pj0A1gkKliK+/dtwnvKdQKBgQDEGUNIikgld/yWz+z2aC26O6ZF5MGVyy37
m5T33jaIRcRB9srZoQcBL08wyO084Wqs7C+DI/OK1kSe47QVUeyHtWiposntw1jl
jRFqjSCU020mkyz/deLN9MADjhbuCebc7FwNerR2DcnhbRTbR9QWr16fwd5jO/GF
BhaTXO/ffwKBgGJoIZRzP1LSPZXVnAqX1na9eV6RXjUXd9rT1t5GrfEG+vLz88R2
kYaKSo6RmL31UqIQc96/aHAko7t77d5AP1Lt1zG7/yhGAzo53tMMjs2tCubxjNUv
/evSHQ+7sMbxXnUEPMDxEuhcGNVpA0rSQD/UUS0fSPq3i5l2kqOiOU0RAoGBAICl
WiCSpzX9ezWs/nXAbo9IZpJfuif8/ROdQ6NAomHP8yqbLwSKwT+ju73zcr+H2iXL
ZHgR88nXO3lJRHDgJ933wsvWwcY7a2xcmVpfb0pzUZ4G23RT8BDRSc6LPru2vz+b
x+AH6a+w6An9N7uLabXgIqGH288aGh38mn7eb3cdAoGANVe+syLKTg/4MIuKmqo+
FPCrZEPhjDSiKwZ6pEFcZBieJf3i5Rn7YR3N4HGkR3+TTj/gsjkVhFSdgYhTm1tU
LRInclgyB8JcHlp3daPJESs4lzXue8/BPMJC7FPTsVXTg8JSKFwm5MDbXrvtr3cG
A/h7DZA3uzbmYruXnBsSog0=
-----END PRIVATE KEY-----
"""

    // Cached access token
    private var cachedToken: String?
    private var tokenExpiry: Date?

    private init() {}

    /// Get a valid access token, refreshing if necessary
    func getAccessToken() async throws -> String {
        // Return cached token if still valid (with 5 minute buffer)
        if let token = cachedToken,
           let expiry = tokenExpiry,
           Date() < expiry.addingTimeInterval(-300) {
            return token
        }

        // Generate new token
        let token = try await fetchAccessToken()
        return token
    }

    /// Fetch a new access token from Google OAuth
    private func fetchAccessToken() async throws -> String {
        // Create JWT
        let jwt = try createSignedJWT()

        // Exchange JWT for access token
        guard let url = URL(string: tokenURI) else {
            throw GoogleAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleAuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDesc = errorJson["error_description"] as? String {
                throw GoogleAuthError.tokenError(errorDesc)
            }
            throw GoogleAuthError.httpError(httpResponse.statusCode)
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            throw GoogleAuthError.invalidTokenResponse
        }

        // Cache the token
        cachedToken = accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))

        return accessToken
    }

    /// Create a signed JWT for service account authentication
    private func createSignedJWT() throws -> String {
        let now = Date()
        let expiry = now.addingTimeInterval(3600) // 1 hour

        // JWT Header
        let header: [String: Any] = [
            "alg": "RS256",
            "typ": "JWT"
        ]

        // JWT Claims
        let claims: [String: Any] = [
            "iss": clientEmail,
            "sub": clientEmail,
            "aud": tokenURI,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(expiry.timeIntervalSince1970),
            "scope": "https://www.googleapis.com/auth/cloud-platform"
        ]

        // Encode header and claims
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)

        let headerBase64 = headerData.base64URLEncodedString()
        let claimsBase64 = claimsData.base64URLEncodedString()

        let signatureInput = "\(headerBase64).\(claimsBase64)"

        // Sign with RSA-SHA256
        guard let inputData = signatureInput.data(using: .utf8) else {
            throw GoogleAuthError.signingFailed
        }
        let signature = try signWithRSA(data: inputData)
        let signatureBase64 = signature.base64URLEncodedString()

        return "\(signatureInput).\(signatureBase64)"
    }

    /// Sign data using RSA-SHA256 with the private key
    private func signWithRSA(data: Data) throws -> Data {
        // Parse PEM to get raw key data
        let privateKeyData = try parsePrivateKeyPEM(privateKeyPEM)

        // Create SecKey from raw key data
        let keyDict: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(privateKeyData as CFData, keyDict as CFDictionary, &error) else {
            throw GoogleAuthError.invalidPrivateKey
        }

        // Sign the data
        guard let signedData = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            throw GoogleAuthError.signingFailed
        }

        return signedData as Data
    }

    /// Parse PEM format private key to raw DER data
    private func parsePrivateKeyPEM(_ pem: String) throws -> Data {
        // Remove PEM headers and newlines
        let base64String = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let derData = Data(base64Encoded: base64String) else {
            throw GoogleAuthError.invalidPrivateKey
        }

        // The DER data is in PKCS#8 format, we need to extract the RSA key
        // PKCS#8 has a header that we need to skip to get to the actual RSA key
        // For RSA keys, we skip the first 26 bytes of the PKCS#8 wrapper
        let pkcs8HeaderLength = 26
        guard derData.count > pkcs8HeaderLength else {
            throw GoogleAuthError.invalidPrivateKey
        }

        return derData.dropFirst(pkcs8HeaderLength) as Data
    }
}

// MARK: - Errors

enum GoogleAuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case tokenError(String)
    case invalidTokenResponse
    case invalidPrivateKey
    case signingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OAuth URL"
        case .invalidResponse:
            return "Invalid response from Google OAuth"
        case .httpError(let code):
            return "OAuth error (HTTP \(code))"
        case .tokenError(let message):
            return "Token error: \(message)"
        case .invalidTokenResponse:
            return "Could not parse access token response"
        case .invalidPrivateKey:
            return "Invalid service account private key"
        case .signingFailed:
            return "Failed to sign JWT"
        }
    }
}

// MARK: - Data Extension for Base64URL

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
