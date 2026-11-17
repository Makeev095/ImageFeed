@testable import ImageFeed
import XCTest

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?
    var updateTableViewAnimatedCalled = false

    func updateTableViewAnimated() {
        updateTableViewAnimatedCalled = true
    }
}

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var view: ImagesListViewControllerProtocol?
    var photos: [Photo] = []
    var viewDidLoadCalled = false
    var fetchPhotosNextPageCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }

    func updatePhotos() {
        view?.updateTableViewAnimated()
    }
}

final class ImagesListTests: XCTestCase {
    func testViewControllerCallsViewDidLoad() {
        let viewController = ImagesListViewController()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        _ = viewController.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterCallsUpdateTableViewAnimated() {
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        presenter.updatePhotos()

        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
    }
}
