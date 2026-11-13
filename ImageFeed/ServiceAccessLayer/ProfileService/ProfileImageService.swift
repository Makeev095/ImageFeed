import Foundation

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}

    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    private(set) var avatarURL: String?

    private var task: URLSessionTask?

    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ProfileImageService.fetchProfileImageURL]: нет токена авторизации")
            completion(.failure(URLError(.userAuthenticationRequired)))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            print("[ProfileImageService.fetchProfileImageURL]: не удалось создать URLRequest")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.data(for: request) { [weak self] result in
            switch result {
            case .success(let data):
                guard let self else { return }

                do {
                    let userResult = try JSONDecoder().decode(UserResult.self, from: data)
                    let avatarURL = userResult.profileImage.small
                    self.avatarURL = avatarURL
                    completion(.success(avatarURL))
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": avatarURL]
                    )
                } catch {
                    print("[ProfileImageService.fetchProfileImageURL]: decodingError — \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: \(error)")
                completion(.failure(error))
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
    }

    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(Constants.defaultBaseURLString)/users/\(encodedUsername)") else {
            print("[ProfileImageService.makeProfileImageRequest]: не удалось создать URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
