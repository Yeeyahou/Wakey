//
//  SceneDelegate.swift
//  Wakey
//
//  Created by jungwon on 6/5/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = WakeyTabBarController()
        window.makeKeyAndVisible()
        self.window = window

        if let response = connectionOptions.notificationResponse {
            DispatchQueue.main.async {
                WakeyNotificationRouter.openAlarm(from: response.notification.request.content.userInfo)
            }
        } else {
            showLaunchAnimation(in: window)
        }
    }

    private func showLaunchAnimation(in window: UIWindow) {
        let splash = WakeyLaunchAnimationView(frame: window.bounds)
        splash.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(splash)
        splash.play {
            splash.removeFromSuperview()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

private final class WakeyLaunchAnimationView: UIView {
    private let logoImageView = UIImageView(image: UIImage(named: "LaunchLogo"))
    private let appNameLabel = UILabel()
    private let taglineLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
        isUserInteractionEnabled = false

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        logoImageView.layer.cornerRadius = 58
        logoImageView.layer.cornerCurve = .continuous
        logoImageView.clipsToBounds = true
        addSubview(logoImageView)

        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        appNameLabel.text = "Wakey"
        appNameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        appNameLabel.textColor = UIColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1)
        appNameLabel.textAlignment = .center
        appNameLabel.alpha = 0
        appNameLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        addSubview(appNameLabel)

        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineLabel.text = "나만의 AI 알람앱"
        taglineLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        taglineLabel.textColor = UIColor(red: 0.52, green: 0.48, blue: 0.43, alpha: 1)
        taglineLabel.textAlignment = .center
        taglineLabel.alpha = 0
        taglineLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        addSubview(taglineLabel)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -58),
            logoImageView.widthAnchor.constraint(equalToConstant: 238),
            logoImageView.heightAnchor.constraint(equalToConstant: 238),

            appNameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 26),
            appNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            appNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            appNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            taglineLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 8),
            taglineLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            taglineLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
            taglineLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func play(completion: @escaping () -> Void) {
        layoutIfNeeded()
        UIView.animate(
            withDuration: 0.42,
            delay: 0.06,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut]
        ) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }

        UIView.animate(withDuration: 0.34, delay: 0.24, options: [.curveEaseOut]) {
            self.appNameLabel.alpha = 1
            self.taglineLabel.alpha = 1
            self.appNameLabel.transform = .identity
            self.taglineLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.36, delay: 1.05, options: [.curveEaseIn]) {
            self.alpha = 0
            self.logoImageView.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        } completion: { _ in
            completion()
        }
    }
}
