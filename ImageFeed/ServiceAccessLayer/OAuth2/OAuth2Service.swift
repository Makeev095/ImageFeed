import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

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

    private let dataStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?
    private var lastCode: String?

    private(set) var authToken: String? {
        get {
            dataStorage.token
        }
        set {
            dataStorage.token = newValue
        }
    }

    private init() { }

    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        if task != nil {
            if lastCode != code {
                task?.cancel()
            } else {
                print("[OAuth2Service.fetchAuthToken]: AuthServiceError.invalidRequest — повторный запрос с тем же code")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        } else {
            if lastCode == code {
                print("[OAuth2Service.fetchAuthToken]: AuthServiceError.invalidRequest — запрос с этим code уже выполнялся")
                completion(.failure(AuthServiceError.invalidRequest))
                return
            }
        }

        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service.fetchAuthToken]: AuthServiceError.invalidRequest — не удалось создать URLRequest")
            completion(.failure(AuthServiceError.invalidRequest))
            return
        }

        let task = object(for: request) { [weak self] result in
            guard let self else { return }

            self.task = nil
            self.lastCode = nil

            switch result {
            case .success(let body):
                let authToken = body.accessToken
                self.authToken = authToken
                completion(.success(authToken))
            case .failure(let error):
                switch error {
                case NetworkError.httpStatusCode(let statusCode):
                    print("[OAuth2Service.fetchAuthToken]: ошибка Unsplash, statusCode=\(statusCode)")
                case NetworkError.urlRequestError(let requestError):
                    print("[OAuth2Service.fetchAuthToken]: сетевая ошибка URLSession.dataTask — \(requestError)")
                case NetworkError.urlSessionError:
                    print("[OAuth2Service.fetchAuthToken]: сетевая ошибка URLSession.dataTask — urlSessionError")
                case NetworkError.decodingError(let decodingError):
                    print("[OAuth2Service.fetchAuthToken]: decodingError — \(decodingError)")
                default:
                    print("[OAuth2Service.fetchAuthToken]: \(error)")
                }
                completion(.failure(error))
            }
        }
        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            print("[OAuth2Service.makeOAuthTokenRequest]: не удалось создать URLComponents")
            return nil
        }

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

extension OAuth2Service {
    private func object(
        for request: URLRequest,
        completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(body))
                } catch {
                    print("[OAuth2Service.object]: decodingError — \(error), body: \(String(data: data, encoding: .utf8) ?? "")")
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
