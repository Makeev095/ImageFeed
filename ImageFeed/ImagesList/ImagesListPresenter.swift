import Foundation

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func updateTableViewAnimated()
}

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photos: [Photo] { get }
    func viewDidLoad()
    func fetchPhotosNextPage()
    func updatePhotos()
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    private(set) var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?

    func viewDidLoad() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePhotos()
        }
        fetchPhotosNextPage()
    }

    func fetchPhotosNextPage() {
        imagesListService.fetchPhotosNextPage()
    }

    func updatePhotos() {
        photos = imagesListService.photos
        view?.updateTableViewAnimated()
    }
}
