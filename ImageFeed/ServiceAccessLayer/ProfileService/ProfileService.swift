import Foundation

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?

    private enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private(set) var profile: Profile?

    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService.fetchProfile]: не удалось создать URLRequest")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let profileResult):
                let name = [profileResult.firstName, profileResult.lastName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                let profile = Profile(
                    username: profileResult.username,
                    name: name,
                    loginName: "@\(profileResult.username)",
                    bio: profileResult.bio
                )
                self?.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService.fetchProfile]: \(error)")
                completion(.failure(error))
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "\(Constants.defaultBaseURLString)/me") else {
            print("[ProfileService.makeProfileRequest]: не удалось создать URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
