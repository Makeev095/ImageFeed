import Foundation

protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateProfileDetails(name: String, loginName: String, bio: String)
    func updateAvatar(url: URL)
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    private var profileImageServiceObserver: NSObjectProtocol?

    func viewDidLoad() {
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile)
        }

        profileImageServiceObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAvatar()
        }
        updateAvatar()
    }

    func updateProfileDetails(_ profile: Profile) {
        let name = profile.name.isEmpty ? "Имя не указано" : profile.name
        let loginName = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        let bio = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : (profile.bio ?? "")
        view?.updateProfileDetails(name: name, loginName: loginName, bio: bio)
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else { return }
        view?.updateAvatar(url: url)
    }
}
