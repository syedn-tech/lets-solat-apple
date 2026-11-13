import Foundation

public final class APIClient {
    public static let shared = APIClient()
    
    private let baseURL = "https://letssolat.syedn.xyz/api"
    private let defaultBearerToken = "1|XVgvHUzdJDMJSi6hcLhsiqUKHJi8xd9qmv50yF8O9f81557b"
    
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetch daily prayer times by Malaysian zone (e.g. WLY01)
    public func fetchDailyPrayerTimes(zone: String, date: String? = nil) async throws -> PrayerTimeResponse {
        var components = URLComponents(string: "\(baseURL)/prayer-times")!
        var queryItems = [
            URLQueryItem(name: "type", value: "daily"),
            URLQueryItem(name: "zone", value: zone)
        ]
        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        components.queryItems = queryItems
        
        return try await performRequest(url: components.url!)
    }
    
    /// Fetch daily prayer times by GPS coordinates (Malaysia or worldwide)
    public func fetchDailyPrayerTimes(latitude: Double, longitude: Double, date: String? = nil) async throws -> PrayerTimeResponse {
        var components = URLComponents(string: "\(baseURL)/prayer-times")!
        var queryItems = [
            URLQueryItem(name: "type", value: "daily"),
            URLQueryItem(name: "latitude", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.6f", longitude))
        ]
        if let date = date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        components.queryItems = queryItems
        
        return try await performRequest(url: components.url!)
    }
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(defaultBearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NSError(
                domain: "APIClient",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server error (\(httpResponse.statusCode)): \(errorString)"]
            )
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
