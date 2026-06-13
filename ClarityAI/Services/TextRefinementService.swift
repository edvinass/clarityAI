import Foundation

protocol TextRefining {
    func refine(_ text: String) async throws -> String
}

enum TextRefinementError: LocalizedError {
    case emptyInput
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Select some text before refining."
        case .invalidResponse:
            return "The refinement service returned an unexpected response."
        case .apiError(let message):
            return message
        }
    }
}

struct StubTextRefinementService: TextRefining {
    func refine(_ text: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextRefinementError.emptyInput
        }

        try await Task.sleep(nanoseconds: 250_000_000)

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentences = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { sentence -> String in
                guard let first = sentence.first else { return sentence }
                return first.uppercased() + sentence.dropFirst()
            }

        return sentences.joined(separator: ". ") + (trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") ? "." : "")
    }
}

struct OpenAITextRefinementService: TextRefining {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func refine(_ text: String) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextRefinementError.emptyInput
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0.3,
            "messages": [
                [
                    "role": "system",
                    "content": "You improve writing. Return only the refined text with no commentary."
                ],
                [
                    "role": "user",
                    "content": text
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw TextRefinementError.apiError(message)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw TextRefinementError.invalidResponse
        }

        let refined = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !refined.isEmpty else {
            throw TextRefinementError.invalidResponse
        }

        return refined
    }
}
