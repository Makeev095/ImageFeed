import Foundation

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let urlSession = URLSession.shared

    private init() { }

    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service.fetchAuthToken]: NetworkError.invalidRequest — не удалось создать URLRequest")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }

        let task = urlSession.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(response.accessToken))
                } catch {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    print("[OAuth2Service.fetchAuthToken]: decodingError — \(error), body: \(body)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                switch error {
                case NetworkError.httpStatusCode(let statusCode):
                    print("[OAuth2Service.fetchAuthToken]: ошибка Unsplash, statusCode=\(statusCode)")
                case NetworkError.urlRequestError(let requestError):
                    print("[OAuth2Service.fetchAuthToken]: сетевая ошибка URLSession.dataTask — \(requestError)")
                case NetworkError.urlSessionError:
                    print("[OAuth2Service.fetchAuthToken]: сетевая ошибка URLSession.dataTask — urlSessionError")
                default:
                    print("[OAuth2Service.fetchAuthToken]: \(error)")
                }
                completion(.failure(error))
            }
        }

        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "unsplash.com"
        urlComponents.path = "/oauth/token"
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service.makeOAuthTokenRequest]: не удалось получить URL из URLComponents")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
}
