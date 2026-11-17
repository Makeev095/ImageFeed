import CoreGraphics
import Foundation

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    var isLiked: Bool
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt: String?
    let width: Int
    let height: Int
    let likedByUser: Bool
    let description: String?
    let urls: UrlsResult

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case width
        case height
        case likedByUser = "liked_by_user"
        case description
        case urls
    }
}

struct UrlsResult: Decodable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct LikeResult: Decodable {
    let photo: PhotoResult
}

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []

    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private let dateFormatter = ISO8601DateFormatter()

    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        if task != nil {
            return
        }

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService.fetchPhotosNextPage]: NetworkError.invalidRequest — нет токена")
            return
        }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage, token: token) else {
            print("[ImagesListService.fetchPhotosNextPage]: NetworkError.invalidRequest — не удалось создать URLRequest page=\(nextPage)")
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { self.makePhoto(from: $0) }
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self
                )
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: \(error) page=\(nextPage)")
            }

            self.task = nil
        }

        self.task = task
        task.resume()
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService.changeLike]: NetworkError.invalidRequest — нет токена photoId=\(photoId)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike, token: token) else {
            print("[ImagesListService.changeLike]: NetworkError.invalidRequest — не удалось создать URLRequest photoId=\(photoId)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<LikeResult, Error>) in
            guard let self else { return }

            switch result {
            case .success:
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    self.photos[index].isLiked = isLike
                }
                completion(.success(()))
            case .failure(let error):
                print("[ImagesListService.changeLike]: \(error) photoId=\(photoId) isLike=\(isLike)")
                completion(.failure(error))
            }
        }
        task.resume()
    }

    func reset() {
        task?.cancel()
        task = nil
        lastLoadedPage = nil
        photos = []
    }

    private func makePhotosRequest(page: Int, token: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "\(Constants.defaultBaseURLString)/photos") else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "10")
        ]

        guard let url = urlComponents.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makeLikeRequest(photoId: String, isLike: Bool, token: String) -> URLRequest? {
        guard let encodedId = photoId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(Constants.defaultBaseURLString)/photos/\(encodedId)/like") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makePhoto(from result: PhotoResult) -> Photo {
        let date: Date?
        if let createdAt = result.createdAt {
            date = dateFormatter.date(from: createdAt)
        } else {
            date = nil
        }

        return Photo(
            id: result.id,
            size: CGSize(width: result.width, height: result.height),
            createdAt: date,
            welcomeDescription: result.description,
            thumbImageURL: result.urls.thumb,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }
}
