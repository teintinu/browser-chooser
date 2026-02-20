import Foundation

class AIClient {
    static let shared = AIClient()
    
    private init() {}
    
    func fetchModels(baseURL: String, apiKey: String?) async throws -> [String] {
        var urlString = baseURL
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += "v1/models"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        if let key = apiKey, !key.isEmpty {
            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct ModelResponse: Codable {
            struct Model: Codable {
                let id: String
            }
            let data: [Model]
        }
        
        let response = try JSONDecoder().decode(ModelResponse.self, from: data)
        return response.data.map { $0.id }
    }
    
    func suggestRegexes(for url: String, browserName: String) async throws -> [String] {
        let config = AIConfigStore.shared.config
        var urlString = config.baseURL
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += "v1/chat/completions"
        
        guard let fetchURL = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: fetchURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = config.apiKey, !key.isEmpty {
            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        let prompt = """
        Analyze the URL: "\(url)" for the browser: "\(browserName)".
        Generate 15 to 20 Regular Expression (Regex) patterns for routing, ranging from highly specific to very broad.
        
        Requirements:
        1. Format: Must be compatible with Swift's NSRegularExpression (ICU standard).
        2. Escaping: Ensure backslashes are properly escaped for a JSON string (e.g., use "\\\\." for a literal dot, "\\\\d" for digits).
        3. Variations to include:
           - Exact match for the full URL.
           - Matches for any subdomain of the main domain (e.g., if URL is 'app.linear.app', include 'https://.*\\\\.linear\\\\.app/.*').
           - Patterns that ignore query parameters (everything after ?) and fragments (everything after #).
           - Broad domain-level matching (e.g., '.*google\\\\.com.*').
           - Common paths or subdirectories if applicable.
        
        Return ONLY a JSON object in this format: {"patterns": ["regex1", "regex2", ...]}.
        """
        
        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": "You are a specialized assistant that generates valid Swift-compatible NSRegularExpression patterns for URL routing. Output must be valid JSON."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct ChatResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            return []
        }
        
        struct RegexResponse: Codable {
            let patterns: [String]
        }
        
        let regexResponse = try JSONDecoder().decode(RegexResponse.self, from: content.data(using: .utf8)!)
        return regexResponse.patterns
    }
}
