@testable import ImageFeed
import XCTest

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    var updateProfileDetailsCalled = false
    var name: String?
    var loginName: String?
    var bio: String?

    func updateProfileDetails(name: String, loginName: String, bio: String) {
        updateProfileDetailsCalled = true
        self.name = name
        self.loginName = loginName
        self.bio = bio
    }

    func updateAvatar(url: URL) {}
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    var view: ProfileViewControllerProtocol?
    var viewDidLoadCalled = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }
}

final class ProfileTests: XCTestCase {
    func testViewControllerCallsViewDidLoad() {
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        _ = viewController.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterUpdatesProfileDetails() {
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        let profile = Profile(
            username: "makeev095",
            name: "Dmitrii Makeev",
            loginName: "@makeev095",
            bio: "bio"
        )
        presenter.updateProfileDetails(profile)

        XCTAssertTrue(viewController.updateProfileDetailsCalled)
        XCTAssertEqual(viewController.name, "Dmitrii Makeev")
        XCTAssertEqual(viewController.loginName, "@makeev095")
        XCTAssertEqual(viewController.bio, "bio")
    }
}
