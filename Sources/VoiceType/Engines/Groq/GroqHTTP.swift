import Foundation

/// Shared plumbing for the two Groq cloud engines: the base URL, a configured
/// `URLSession`, multipart encoding, and a thin error type the engines map onto
/// their own contracts.
///
/// Privacy note: requests carry the user's audio/transcript off-device. That is
/// only ever reached after explicit cloud consent (enforced upstream). We never
/// log the bearer token, request bodies, or responses here.
enum GroqHTTP {
    static let transcriptionURL = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    static let chatCompletionsURL = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    static let transcriptionModel = "whisper-large-v3-turbo"
    static let cleanupModel = "llama-3.1-8b-instant"

    /// A session with sensible timeouts; cloud is opt-in for speed, so don't let
    /// a stalled request hang the dictation flow indefinitely.
    static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    /// What went wrong at the transport/HTTP layer. The engines translate this
    /// into their own `TranscriptionError` / `CleanupError`.
    enum Failure: Error {
        /// URLSession/transport failure (offline, DNS, TLS, timeout…).
        case transport(String)
        /// Reached the server but it returned a non-2xx status.
        case http(status: Int, message: String)
        /// 2xx, but the body wasn't shaped the way we expected.
        case decoding(String)
    }

    /// Perform a request and return the body on a 2xx, mapping everything else to
    /// `Failure`. Never logs auth, bodies, or responses.
    static func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Failure.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else {
            throw Failure.transport("No HTTP response from Groq.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw Failure.http(status: http.statusCode,
                               message: errorMessage(from: data, status: http.statusCode))
        }
        return data
    }

    /// Build an authorized JSON request.
    static func jsonRequest(url: URL, apiKey: String, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    /// Build an authorized multipart/form-data request from text fields plus one
    /// file field (used for the audio upload).
    static func multipartRequest(
        url: URL,
        apiKey: String,
        fields: [(name: String, value: String)],
        file: (name: String, filename: String, contentType: String, data: Data)
    ) -> URLRequest {
        let boundary = "voicetype-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        let dashes = "--\(boundary)\r\n"
        for field in fields {
            body.append(string: dashes)
            body.append(string: "Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            body.append(string: "\(field.value)\r\n")
        }
        body.append(string: dashes)
        body.append(string: "Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.filename)\"\r\n")
        body.append(string: "Content-Type: \(file.contentType)\r\n\r\n")
        body.append(file.data)
        body.append(string: "\r\n")
        body.append(string: "--\(boundary)--\r\n")

        request.httpBody = body
        return request
    }

    /// Best-effort extraction of Groq's `{ "error": { "message": ... } }` body so
    /// failures carry a useful (non-sensitive) reason. Falls back to the status.
    private static func errorMessage(from data: Data, status: Int) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = obj["error"] as? [String: Any],
           let message = error["message"] as? String, !message.isEmpty {
            return message
        }
        return "HTTP \(status)"
    }
}

private extension Data {
    mutating func append(string: String) {
        append(contentsOf: string.utf8)
    }
}
