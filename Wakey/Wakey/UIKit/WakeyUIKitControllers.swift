import UIKit
import Combine
import UserNotifications
import CoreLocation
import EventKit
import AVFoundation

@MainActor
final class WakeyAppContext {
    static let shared = WakeyAppContext()

    let alarmManager = AlarmManager()
    let notificationManager = NotificationManager()
    let weatherService = WeatherService()
    let locationService = LocationService()
    let calendarService = CalendarService()

    private init() {}
}

enum WakeyUIKitStyle {
    static let primary = WakeyGradientColors.primary.uiColor
    static let accent = WakeyGradientColors.accent.uiColor
    static let secondary = WakeyGradientColors.secondary.uiColor
    static let background = WakeyGradientColors.background.uiColor
    static let card = UIColor.white
    static let text = UIColor(hex: "2D2D2D")
    static let subtext = UIColor(hex: "8B8B8B")
    static let destructive = WakeyGradientColors.destructive.uiColor

    static let buttonGradientColors = [
        WakeyGradientColors.primary.uiColor,
        WakeyGradientColors.buttonEnd.uiColor
    ]

    static let softGradientColors = [
        WakeyGradientColors.primary.uiColor.withAlphaComponent(0.13),
        WakeyGradientColors.accent.uiColor.withAlphaComponent(0.13)
    ]

    static func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = card
        view.layer.cornerRadius = 24
        view.layer.borderColor = UIColor.black.withAlphaComponent(0.06).cgColor
        view.layer.borderWidth = 1
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.07
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        return view
    }

    static func softGradientCard() -> UIView {
        let view = WakeyGradientView(colors: softGradientColors)
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        return view
    }

    static func gradientButton(title: String, image: UIImage? = nil) -> UIButton {
        let button = WakeyGradientButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.imageView?.contentMode = .scaleAspectFit
        button.semanticContentAttribute = .forceLeftToRight
        button.configuration = nil
        button.layer.cornerRadius = 28
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.layer.shadowColor = primary.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        return button
    }

    static func plainButton(title: String, color: UIColor = text) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = card
        button.layer.cornerRadius = 26
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        button.layer.borderWidth = 1
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.04
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return button
    }
}

final class WakeyGradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        gradientLayer.colors = WakeyUIKitStyle.buttonGradientColors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        if let imageView {
            bringSubviewToFront(imageView)
        }
        if let titleLabel {
            bringSubviewToFront(titleLabel)
        }
    }
}

final class WakeyGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        locations: [NSNumber]? = nil
    ) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        gradientLayer.colors = WakeyUIKitStyle.softGradientColors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }
}

final class WakeyGradientBorderView: UIView {
    private let fillGradientLayer = CAGradientLayer()
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    private let borderWidthValue: CGFloat
    private let cornerRadiusValue: CGFloat

    init(
        colors: [UIColor],
        borderWidth: CGFloat = 1.5,
        cornerRadius: CGFloat = 24,
        fillColors: [UIColor]? = nil,
        fillAlpha: CGFloat = 0
    ) {
        self.borderWidthValue = borderWidth
        self.cornerRadiusValue = cornerRadius
        super.init(frame: .zero)
        backgroundColor = WakeyUIKitStyle.card
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        fillGradientLayer.colors = (fillColors ?? colors).map { $0.withAlphaComponent(fillAlpha).cgColor }
        fillGradientLayer.startPoint = CGPoint(x: 0, y: 0.1)
        fillGradientLayer.endPoint = CGPoint(x: 1, y: 0.9)
        layer.addSublayer(fillGradientLayer)

        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = borderWidth
        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        self.borderWidthValue = 1.5
        self.cornerRadiusValue = 24
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillGradientLayer.frame = bounds
        fillGradientLayer.cornerRadius = layer.cornerRadius
        gradientLayer.frame = bounds
        let inset = borderWidthValue / 2
        shapeLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: max(0, cornerRadiusValue - inset)
        ).cgPath
    }
}

final class WakeyBottomFadeView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            WakeyUIKitStyle.background.withAlphaComponent(0).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0.68).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0.9).cgColor
        ]
        gradientLayer.locations = [0, 0.52, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

final class WakeyTopFadeView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            WakeyUIKitStyle.background.withAlphaComponent(0.9).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0.62).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0).cgColor
        ]
        gradientLayer.locations = [0, 0.44, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

final class WakeyChipLabel: UILabel {
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        self.text = text
        font = .systemFont(ofSize: 14, weight: .medium)
        textColor = color
        textAlignment = .center
        backgroundColor = color.withAlphaComponent(0.18)
        layer.cornerRadius = 17
        clipsToBounds = true
        heightAnchor.constraint(equalToConstant: 34).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1
        )
    }
}

class WakeyBaseViewController: UIViewController {
    let context = WakeyAppContext.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = WakeyUIKitStyle.background
        navigationController?.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = WakeyUIKitStyle.background.withAlphaComponent(0.96)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.05)
        appearance.titleTextAttributes = [
            .foregroundColor: WakeyUIKitStyle.text,
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = WakeyUIKitStyle.text
    }

    func makeScrollStack() -> (UIScrollView, UIStackView) {
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 22),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -22),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -22),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -44)
        ])

        return (scrollView, stackView)
    }

    func label(_ text: String, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = WakeyUIKitStyle.text, lines: Int = 0) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = lines
        return label
    }

    func card(_ content: UIView, padding: CGFloat = 22) -> UIView {
        let container = WakeyUIKitStyle.cardView()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        ])
        return container
    }

    func softGradientCard(_ content: UIView, padding: CGFloat = 28) -> UIView {
        let container = WakeyUIKitStyle.softGradientCard()
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        ])
        return container
    }

    func chipRow(_ chips: [UIView]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: chips)
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .leading
        return row
    }

    func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Wakey", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    func configureCardCell(_ cell: UITableViewCell, title: String, subtitle: String, accessory: UIView?) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentConfiguration = nil
        cell.accessoryView = nil

        let card = WakeyUIKitStyle.cardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(card)

        let titleLabel = label(title, size: 24, weight: .medium)
        let subtitleLabel = label(subtitle, size: 15, color: WakeyUIKitStyle.subtext, lines: 1)
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [textStack, UIView()])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        if let accessory {
            row.addArrangedSubview(accessory)
        }

        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -22),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22)
        ])
    }
}

final class WakeyTabBarController: UITabBarController {
    static weak var activeInstance: WakeyTabBarController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Self.activeInstance = self

        let home = UINavigationController(rootViewController: HomeUIKitViewController())
        home.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house.fill"), tag: 0)

        let alarms = UINavigationController(rootViewController: AlarmListUIKitViewController())
        alarms.tabBarItem = UITabBarItem(title: "알람", image: UIImage(systemName: "alarm.fill"), tag: 1)

        let library = UINavigationController(rootViewController: LibraryUIKitViewController())
        library.tabBarItem = UITabBarItem(title: "라이브러리", image: UIImage(systemName: "music.note.list"), tag: 2)

        let settings = UINavigationController(rootViewController: SettingsUIKitViewController())
        settings.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "gearshape.fill"), tag: 3)

        viewControllers = [home, alarms, library, settings]
        tabBar.tintColor = WakeyUIKitStyle.primary
        tabBar.unselectedItemTintColor = WakeyUIKitStyle.text
        tabBar.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        tabBar.layer.cornerRadius = 26
        tabBar.layer.masksToBounds = true
    }

    func showRingingAlarm(_ alarm: AlarmSong) {
        dismiss(animated: false)
        selectedIndex = 1
        let controller = RingingAlarmUIKitViewController(alarm: alarm)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
}

@MainActor
enum WakeyNotificationRouter {
    static func openAlarm(from userInfo: [AnyHashable: Any], retryCount: Int = 0) {
        guard let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString),
              let alarm = WakeyAppContext.shared.alarmManager.alarms.first(where: { $0.id == alarmId }) else {
            return
        }

        if let tabBar = WakeyTabBarController.activeInstance ?? activeTabBarController() {
            tabBar.showRingingAlarm(alarm)
            return
        }

        guard retryCount < 10 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            openAlarm(from: userInfo, retryCount: retryCount + 1)
        }
    }

    private static func activeTabBarController() -> WakeyTabBarController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController as? WakeyTabBarController
    }
}

final class RingingAlarmUIKitViewController: UIViewController {
    private let alarm: AlarmSong
    private let player = AudioPlayerService()
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let slideTrack = UIView()
    private let slideThumb = UIView()
    private let slideLabel = UILabel()
    private var thumbLeadingConstraint: NSLayoutConstraint?
    private var didStop = false

    init(alarm: AlarmSong) {
        self.alarm = alarm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        alarm = AlarmSong(time: Date(), purpose: .wakeup, mood: .exciting, nickname: WakeyProfile.nickname, memo: "")
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupContent()
        player.volume = alarm.resolvedAlarmVolume
        player.play(url: alarm.originalAudioURL ?? alarm.notificationAudioURL)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        glowLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }

    private func setupBackground() {
        view.backgroundColor = .black
        gradientLayer.colors = [
            UIColor.black.cgColor,
            UIColor(red: 0.10, green: 0.04, blue: 0.02, alpha: 1).cgColor,
            UIColor.black.cgColor
        ]
        gradientLayer.locations = [0, 0.55, 1]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.1)
        gradientLayer.endPoint = CGPoint(x: 0.9, y: 0.9)
        view.layer.addSublayer(gradientLayer)

        glowLayer.colors = [
            WakeyUIKitStyle.primary.withAlphaComponent(0.0).cgColor,
            WakeyUIKitStyle.primary.withAlphaComponent(0.55).cgColor,
            UIColor(red: 1, green: 0.28, blue: 0.16, alpha: 0.28).cgColor,
            WakeyUIKitStyle.primary.withAlphaComponent(0.0).cgColor
        ]
        glowLayer.locations = [0, 0.36, 0.68, 1]
        glowLayer.startPoint = CGPoint(x: 0.08, y: 0.2)
        glowLayer.endPoint = CGPoint(x: 0.92, y: 0.86)
        view.layer.addSublayer(glowLayer)

        let animation = CABasicAnimation(keyPath: "startPoint")
        animation.fromValue = CGPoint(x: 0.05, y: 0.2)
        animation.toValue = CGPoint(x: 0.45, y: 0.05)
        animation.duration = 3.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        glowLayer.add(animation, forKey: "meshStart")

        let endAnimation = CABasicAnimation(keyPath: "endPoint")
        endAnimation.fromValue = CGPoint(x: 0.95, y: 0.85)
        endAnimation.toValue = CGPoint(x: 0.58, y: 0.98)
        endAnimation.duration = 4.2
        endAnimation.autoreverses = true
        endAnimation.repeatCount = .infinity
        glowLayer.add(endAnimation, forKey: "meshEnd")
    }

    private func setupContent() {
        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 28
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        let header = UIStackView()
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 12

        let titleLabel = UILabel()
        titleLabel.text = alarm.alarmName ?? "Alarm"
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        let timeLabel = UILabel()
        timeLabel.text = alarm.time.alarmTimeText
        timeLabel.font = .systemFont(ofSize: 88, weight: .semibold)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center

        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(timeLabel)
        content.addArrangedSubview(header)

        let lyricsBox = UIScrollView()
        lyricsBox.translatesAutoresizingMaskIntoConstraints = false
        lyricsBox.layer.cornerRadius = 24
        lyricsBox.backgroundColor = UIColor.black.withAlphaComponent(0.20)

        let lyricsLabel = UILabel()
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        lyricsLabel.text = alarm.isAIAlarmSong ? (alarm.lyrics ?? "") : ""
        lyricsLabel.font = .systemFont(ofSize: 21, weight: .semibold)
        lyricsLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        lyricsLabel.textAlignment = .center
        lyricsLabel.numberOfLines = 0
        lyricsBox.addSubview(lyricsLabel)
        NSLayoutConstraint.activate([
            lyricsLabel.topAnchor.constraint(equalTo: lyricsBox.contentLayoutGuide.topAnchor, constant: 24),
            lyricsLabel.leadingAnchor.constraint(equalTo: lyricsBox.contentLayoutGuide.leadingAnchor, constant: 22),
            lyricsLabel.trailingAnchor.constraint(equalTo: lyricsBox.contentLayoutGuide.trailingAnchor, constant: -22),
            lyricsLabel.bottomAnchor.constraint(equalTo: lyricsBox.contentLayoutGuide.bottomAnchor, constant: -24),
            lyricsLabel.widthAnchor.constraint(equalTo: lyricsBox.frameLayoutGuide.widthAnchor, constant: -44)
        ])
        content.addArrangedSubview(lyricsBox)
        NSLayoutConstraint.activate([
            lyricsBox.widthAnchor.constraint(equalTo: content.widthAnchor),
            lyricsBox.heightAnchor.constraint(equalToConstant: 220)
        ])

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        content.addArrangedSubview(spacer)

        let snoozeButton = UIButton(type: .system)
        snoozeButton.setTitle("다시 알림", for: .normal)
        snoozeButton.setTitleColor(.white, for: .normal)
        snoozeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        snoozeButton.backgroundColor = WakeyUIKitStyle.primary
        snoozeButton.layer.cornerRadius = 34
        snoozeButton.heightAnchor.constraint(equalToConstant: 68).isActive = true
        snoozeButton.addTarget(self, action: #selector(snoozeTapped), for: .touchUpInside)
        content.addArrangedSubview(snoozeButton)
        snoozeButton.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true

        content.addArrangedSubview(slideToStopControl())

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 54),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -34)
        ])
    }

    private func slideToStopControl() -> UIView {
        slideTrack.translatesAutoresizingMaskIntoConstraints = false
        slideTrack.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        slideTrack.layer.cornerRadius = 34
        slideTrack.clipsToBounds = true
        slideTrack.heightAnchor.constraint(equalToConstant: 68).isActive = true

        slideLabel.text = "밀어서 끄기"
        slideLabel.textColor = UIColor.white.withAlphaComponent(0.35)
        slideLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        slideLabel.translatesAutoresizingMaskIntoConstraints = false

        slideThumb.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        slideThumb.layer.cornerRadius = 30
        slideThumb.translatesAutoresizingMaskIntoConstraints = false
        let stopIcon = UIImageView(image: UIImage(systemName: "stop.fill"))
        stopIcon.tintColor = .white
        stopIcon.translatesAutoresizingMaskIntoConstraints = false
        slideThumb.addSubview(stopIcon)

        slideTrack.addSubview(slideLabel)
        slideTrack.addSubview(slideThumb)
        thumbLeadingConstraint = slideThumb.leadingAnchor.constraint(equalTo: slideTrack.leadingAnchor, constant: 4)
        thumbLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            slideTrack.widthAnchor.constraint(equalToConstant: max(260, UIScreen.main.bounds.width - 72)),
            slideLabel.centerXAnchor.constraint(equalTo: slideTrack.centerXAnchor, constant: 22),
            slideLabel.centerYAnchor.constraint(equalTo: slideTrack.centerYAnchor),
            slideThumb.topAnchor.constraint(equalTo: slideTrack.topAnchor, constant: 4),
            slideThumb.bottomAnchor.constraint(equalTo: slideTrack.bottomAnchor, constant: -4),
            slideThumb.widthAnchor.constraint(equalToConstant: 60),
            stopIcon.centerXAnchor.constraint(equalTo: slideThumb.centerXAnchor),
            stopIcon.centerYAnchor.constraint(equalTo: slideThumb.centerYAnchor),
            stopIcon.widthAnchor.constraint(equalToConstant: 24),
            stopIcon.heightAnchor.constraint(equalToConstant: 24)
        ])

        slideTrack.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleStopPan(_:))))
        return slideTrack
    }

    @objc private func snoozeTapped() {
        player.pause()
        scheduleSnoozeNotification()
        dismiss(animated: true)
    }

    private func scheduleSnoozeNotification() {
        let content = UNMutableNotificationContent()
        content.title = alarm.alarmName ?? "Wakey"
        content.body = "다시 알림 시간이 됐어요."
        content.userInfo = ["alarmId": alarm.id.uuidString]
        if let fileName = alarm.notificationSoundFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(fileName))
        } else {
            content.sound = .default
        }

        let minutes = max(alarm.snoozeIntervalMinutes ?? 5, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-snooze-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    @objc private func handleStopPan(_ sender: UIPanGestureRecognizer) {
        let maxOffset = max(0, slideTrack.bounds.width - 64)
        let translation = sender.translation(in: slideTrack).x
        let offset = min(max(4, translation + 4), maxOffset)
        thumbLeadingConstraint?.constant = offset
        slideLabel.alpha = max(0.12, 1 - offset / maxOffset)

        if sender.state == .ended || sender.state == .cancelled {
            if offset > maxOffset * 0.78 {
                stopAlarm()
            } else {
                UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                    self.thumbLeadingConstraint?.constant = 4
                    self.slideLabel.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }
        }
    }

    private func stopAlarm() {
        guard !didStop else { return }
        didStop = true
        player.pause()
        dismiss(animated: true)
    }
}

final class HomeUIKitViewController: WakeyBaseViewController {
    private var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "홈"
        (_, stackView) = makeScrollStack()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        render()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func render() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.addArrangedSubview(label("좋은 아침이에요!", size: 31, weight: .semibold))
        headerStack.addArrangedSubview(weatherSummaryRow())
        stackView.addArrangedSubview(headerStack)

        let nextInfo = nextAlarmInfo()
        let nextStack = UIStackView()
        nextStack.axis = .vertical
        nextStack.spacing = 10
        nextStack.addArrangedSubview(label("다음 알람", size: 15, weight: .medium, color: WakeyUIKitStyle.subtext))
        if let nextInfo {
            nextStack.addArrangedSubview(timeWithPeriodLabel(for: nextInfo.alarm.time))
            nextStack.addArrangedSubview(label(countdownText(until: nextInfo.fireDate), size: 14, weight: .medium, color: WakeyUIKitStyle.subtext))
            let alarmName = nextInfo.alarm.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines)
            var bottomItems: [UIView] = [homePurposeChip(for: nextInfo.alarm)]
            if let alarmName, !alarmName.isEmpty {
                bottomItems.append(label(alarmName, size: 16, weight: .medium, color: WakeyUIKitStyle.subtext))
            } else {
                bottomItems.append(label(" ", size: 16, weight: .medium, color: WakeyUIKitStyle.subtext))
            }
            let bottomRow = chipRow(bottomItems)
            bottomRow.alignment = .center
            nextStack.addArrangedSubview(bottomRow)
        } else {
            let topSpacer = UIView()
            let bottomSpacer = UIView()
            nextStack.addArrangedSubview(topSpacer)
            nextStack.addArrangedSubview(label("예정된 알람이 없어요", size: 24, weight: .semibold))
            nextStack.addArrangedSubview(bottomSpacer)
            topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor).isActive = true
        }
        let nextCard = softGradientCard(nextStack, padding: 26)
        nextCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 206).isActive = true
        stackView.addArrangedSubview(nextCard)

        let recentStack = UIStackView()
        recentStack.axis = .vertical
        recentStack.spacing = 14
        recentStack.addArrangedSubview(label("최근 생성된 알람송", size: 21, weight: .semibold))
        let recent = context.alarmManager.recentGenerated
        if let recent {
            let songTitle = recent.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let titleLabel = label(songTitle?.isEmpty == false ? songTitle! : "Wakey Alarm Song", size: 23, weight: .semibold, lines: 1)
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let playButton = UIButton(type: .system)
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButton.tintColor = WakeyUIKitStyle.primary
            playButton.backgroundColor = .clear
            playButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .bold), forImageIn: .normal)
            playButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
            playButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
            playButton.addTarget(self, action: #selector(openRecentGeneratedSong), for: .touchUpInside)

            let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), playButton])
            row.axis = .horizontal
            row.spacing = 14
            row.alignment = .center

            let info = UIStackView(arrangedSubviews: [
                row,
                label("\"\((recent.lyrics ?? "").split(separator: "\n").first ?? "알람송이 준비됐어요")\"", size: 16, color: WakeyUIKitStyle.subtext, lines: 2)
            ])
            info.axis = .vertical
            info.spacing = 10
            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.addTarget(self, action: #selector(openRecentGeneratedSong), for: .touchUpInside)
            let container = card(info, padding: 24)
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            container.bringSubviewToFront(button)
            recentStack.addArrangedSubview(container)
        } else {
            recentStack.addArrangedSubview(label("아직 생성된 알람송이 없어요", size: 18, color: WakeyUIKitStyle.subtext, lines: 2))
        }
        stackView.addArrangedSubview(recentStack)

        stackView.addArrangedSubview(homeStatsRow())

        let createButton = WakeyUIKitStyle.gradientButton(title: "나만의 알람 만들기")
        createButton.addTarget(self, action: #selector(openCreate), for: .touchUpInside)
        stackView.addArrangedSubview(createButton)
    }

    private func homeStatsRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [
            statCard(value: "\(context.alarmManager.generatedSongs.count)", title: "저장된 알람송"),
            statCard(value: "\(context.alarmManager.enabledAlarms.count)", title: "활성 알람")
        ])
        row.axis = .horizontal
        row.spacing = 18
        row.distribution = .fillEqually
        return row
    }

    private func statCard(value: String, title: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.addArrangedSubview(label(value, size: 28, weight: .medium))
        stack.addArrangedSubview(label(title, size: 14, weight: .medium, color: WakeyUIKitStyle.subtext))

        let container = card(stack, padding: 18)
        container.heightAnchor.constraint(equalToConstant: 112).isActive = true
        return container
    }

    private func timeWithPeriodLabel(for date: Date) -> UILabel {
        let periodFormatter = DateFormatter()
        periodFormatter.locale = Locale(identifier: "en_US_POSIX")
        periodFormatter.dateFormat = "a"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.dateFormat = "h:mm"

        let text = NSMutableAttributedString(
            string: "\(periodFormatter.string(from: date)) ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: WakeyUIKitStyle.text
            ]
        )
        text.append(NSAttributedString(
            string: timeFormatter.string(from: date),
            attributes: [
                .font: UIFont.systemFont(ofSize: 52, weight: .medium),
                .foregroundColor: WakeyUIKitStyle.text
            ]
        ))

        let label = UILabel()
        label.attributedText = text
        label.numberOfLines = 1
        return label
    }

    private func homePurposeChip(for alarm: AlarmSong) -> UILabel {
        let text = isAIAlarm(alarm) ? alarm.purpose.rawValue : "기본"
        let chip = UILabel()
        chip.text = text
        chip.font = .systemFont(ofSize: 14, weight: .medium)
        chip.textColor = WakeyUIKitStyle.text
        chip.textAlignment = .center
        chip.backgroundColor = WakeyUIKitStyle.primary.withAlphaComponent(0.34)
        chip.layer.cornerRadius = 17
        chip.clipsToBounds = true
        chip.heightAnchor.constraint(equalToConstant: 34).isActive = true
        chip.widthAnchor.constraint(equalToConstant: 70).isActive = true
        return chip
    }

    private func isAIAlarm(_ alarm: AlarmSong) -> Bool {
        alarm.isAIAlarmSong
    }

    @objc private func openRecentGeneratedSong() {
        guard let recent = context.alarmManager.recentGenerated else { return }
        let controller = AlarmDetailUIKitViewController(alarm: recent)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func nextAlarmInfo() -> (alarm: AlarmSong, fireDate: Date)? {
        context.alarmManager.enabledAlarms
            .compactMap { alarm -> (AlarmSong, Date)? in
                guard let fireDate = nextFireDate(for: alarm) else { return nil }
                return (alarm, fireDate)
            }
            .min { $0.1 < $1.1 }
    }

    private func nextFireDate(for alarm: AlarmSong) -> Date? {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: alarm.time)
        let now = Date()

        if alarm.repeatDays.isEmpty {
            let base = calendar.startOfDay(for: alarm.date)
            let date = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: base) ?? alarm.date
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)
        }

        return (0..<14).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            guard alarm.repeatDays.contains(weekday(for: day)) else { return nil }
            let candidate = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: day)
            guard let candidate, candidate > now else { return nil }
            return candidate
        }.min()
    }

    private func weekday(for date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }

    private func countdownText(until date: Date) -> String {
        let seconds = max(60, Int(date.timeIntervalSince(Date())))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        var parts: [String] = []
        if days > 0 {
            parts.append("\(days)일")
        }
        if hours > 0 {
            parts.append("\(hours)시간")
        }
        parts.append("\(minutes)분")
        return "\(parts.joined(separator: " ")) 뒤에 알람이 울립니다"
    }

    private func weatherSummaryRow() -> UIStackView {
        let icon = UIImageView(image: UIImage(systemName: context.weatherService.iconName))
        icon.tintColor = WakeyUIKitStyle.accent
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let text = label("\(Date().koreanFullDateText) · \(context.weatherService.summary)", size: 17, weight: .medium, color: WakeyUIKitStyle.subtext, lines: 2)
        let row = UIStackView(arrangedSubviews: [icon, text])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        return row
    }

    @objc private func openCreate() {
        let controller = CreateAlarmUIKitViewController()
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}

class AlarmListUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let weekdayDisplayOrder: [Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    private let deleteRevealWidth: CGFloat = 80
    private let alarmCardTag = 2701
    private let deleteButtonTag = 2702
    private var ignoresNextTapClose = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알람"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(openCreate))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 132
        tableView.sectionHeaderHeight = 14
        tableView.sectionFooterHeight = 14
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeRevealedCardsFromTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        tableView.addGestureRecognizer(tapGesture)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = context.alarmManager.sortedAlarms.count
        if count == 0 {
            let emptyLabel = UILabel()
            emptyLabel.text = "알람이 없습니다"
            emptyLabel.textColor = WakeyUIKitStyle.subtext
            emptyLabel.font = .systemFont(ofSize: 15)
            emptyLabel.textAlignment = .center
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let alarms = context.alarmManager.sortedAlarms

        let alarm = alarms[indexPath.row]
        let toggle = UISwitch()
        toggle.isOn = alarm.isEnabled
        toggle.onTintColor = WakeyUIKitStyle.primary
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(toggleAlarm(_:)), for: .valueChanged)
        configureAlarmCardCell(cell, alarm: alarm, accessory: toggle, index: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !ignoresNextTapClose else { return }
        if let card = tableView.cellForRow(at: indexPath)?.contentView.viewWithTag(alarmCardTag),
           abs(card.transform.tx) > 1 {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                card.transform = .identity
                self.deleteButton(for: card)?.alpha = 0
            }
            return
        }

        let alarms = context.alarmManager.sortedAlarms
        guard alarms.indices.contains(indexPath.row) else { return }
        let alarm = alarms[indexPath.row]
        let controller = CreateAlarmUIKitViewController(alarm: alarm, isReadOnly: isAIAlarm(alarm))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func openAlarmSongFromButton(_ sender: UIButton) {
        let alarms = context.alarmManager.sortedAlarms
        guard alarms.indices.contains(sender.tag) else { return }
        let controller = AlarmDetailUIKitViewController(alarm: alarms[sender.tag])
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let currentView = view {
            if currentView is UIButton {
                return false
            }
            view = currentView.superview
        }
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        nil
    }

    @objc private func toggleAlarm(_ sender: UISwitch) {
        let alarms = context.alarmManager.sortedAlarms
        guard alarms.indices.contains(sender.tag), let updated = context.alarmManager.setEnabled(alarms[sender.tag], isEnabled: sender.isOn) else { return }
        Task {
            if updated.isEnabled {
                try? await context.notificationManager.schedule(updated)
            } else {
                context.notificationManager.cancel(updated)
            }
        }
    }

    @objc private func openCreate() {
        let controller = CreateAlarmUIKitViewController()
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func configureAlarmCardCell(_ cell: UITableViewCell, alarm: AlarmSong, accessory: UIView, index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = nil
        cell.accessoryView = nil
        cell.selectionStyle = .none
        cell.clipsToBounds = false
        cell.contentView.clipsToBounds = false
        cell.contentView.alpha = 1
        cell.contentView.transform = .identity

        let deleteButton = UIButton(type: .system)
        deleteButton.tag = deleteButtonTag
        deleteButton.accessibilityIdentifier = "\(index)"
        deleteButton.backgroundColor = WakeyUIKitStyle.destructive
        deleteButton.tintColor = .white
        deleteButton.alpha = 0
        deleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        deleteButton.layer.cornerRadius = 20
        deleteButton.clipsToBounds = true
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteAlarmFromButton(_:)), for: .touchUpInside)
        cell.contentView.addSubview(deleteButton)

        let aiAlarm = isAIAlarm(alarm)
        let card: UIView
        if aiAlarm {
            card = WakeyUIKitStyle.cardView()
            card.layer.borderColor = WakeyUIKitStyle.primary.withAlphaComponent(0.34).cgColor
            card.layer.borderWidth = 2.5
        } else {
            card = WakeyUIKitStyle.cardView()
        }
        card.tag = alarmCardTag
        card.translatesAutoresizingMaskIntoConstraints = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleAlarmCardPan(_:)))
        pan.cancelsTouchesInView = false
        card.addGestureRecognizer(pan)
        cell.contentView.addSubview(card)

        let name = alarm.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let topView: UIView
        if aiAlarm {
            let play = UIButton(type: .system)
            play.tag = index
            play.setImage(UIImage(systemName: "play.fill"), for: .normal)
            play.tintColor = WakeyUIKitStyle.primary
            play.backgroundColor = .clear
            play.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .bold), forImageIn: .normal)
            play.widthAnchor.constraint(equalToConstant: 26).isActive = true
            play.heightAnchor.constraint(equalToConstant: 26).isActive = true
            play.addTarget(self, action: #selector(openAlarmSongFromButton(_:)), for: .touchUpInside)

            let titleText = name?.isEmpty == false ? name! : "Wakey Alarm Song"
            let titleLabel = label("\(titleText) · \(alarm.purpose.rawValue)", size: 14, weight: .semibold, color: WakeyUIKitStyle.text, lines: 1)
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let row = UIStackView(arrangedSubviews: [play, titleLabel])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 10
            topView = row
        } else {
            topView = label(name?.isEmpty == false ? name! : " ", size: 14, weight: .semibold, color: WakeyUIKitStyle.text, lines: 1)
        }

        let timeLabel = timeLabel(for: alarm.time)
        let scheduleLabel = scheduleLabel(for: alarm)
        let timeView: UIView
        timeView = timeLabel

        let leftStack = UIStackView(arrangedSubviews: [topView, timeView, scheduleLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4
        leftStack.alignment = .leading

        let rightStack = UIStackView()
        rightStack.axis = .vertical
        rightStack.alignment = .center
        rightStack.addArrangedSubview(accessory)

        let contentRow = UIStackView(arrangedSubviews: [leftStack, UIView(), rightStack])
        contentRow.axis = .horizontal
        contentRow.alignment = .center
        contentRow.spacing = 12
        contentRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentRow)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -22),
            deleteButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: deleteRevealWidth),

            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -22),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            contentRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            contentRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        cell.alpha = alarm.isEnabled ? 1 : 0.62
    }

    private func timeLabel(for date: Date) -> UILabel {
        let periodFormatter = DateFormatter()
        periodFormatter.locale = Locale(identifier: "en_US_POSIX")
        periodFormatter.dateFormat = "a"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.dateFormat = "h:mm"

        let text = NSMutableAttributedString(
            string: "\(periodFormatter.string(from: date)) ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: WakeyUIKitStyle.text
            ]
        )
        text.append(NSAttributedString(
            string: timeFormatter.string(from: date),
            attributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .medium),
                .foregroundColor: WakeyUIKitStyle.text
            ]
        ))

        let label = UILabel()
        label.attributedText = text
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    private func scheduleLabel(for alarm: AlarmSong) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1

        if alarm.repeatDays.isEmpty {
            label.text = alarm.date.koreanMonthDayWeekdayText
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = WakeyUIKitStyle.subtext
            return label
        }

        let text = NSMutableAttributedString()
        for (index, day) in weekdayDisplayOrder.enumerated() {
            if index > 0 {
                text.append(NSAttributedString(string: " "))
            }
            text.append(NSAttributedString(
                string: day.rawValue,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                    .foregroundColor: alarm.repeatDays.contains(day)
                        ? WakeyUIKitStyle.primary
                        : WakeyUIKitStyle.subtext.withAlphaComponent(0.34)
                ]
            ))
        }
        label.attributedText = text
        return label
    }

    private func smallPurposeChip(text: String) -> UILabel {
        let chip = UILabel()
        chip.text = text
        chip.font = .systemFont(ofSize: 12, weight: .semibold)
        chip.textColor = WakeyUIKitStyle.text
        chip.textAlignment = .center
        chip.backgroundColor = WakeyUIKitStyle.primary
        chip.layer.cornerRadius = 12.5
        chip.clipsToBounds = true
        chip.widthAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        return chip
    }

    private func isAIAlarm(_ alarm: AlarmSong) -> Bool {
        alarm.isAIAlarmSong
    }

    @objc private func deleteAlarmFromButton(_ sender: UIButton) {
        let alarms = context.alarmManager.sortedAlarms
        guard let indexText = sender.accessibilityIdentifier,
              let index = Int(indexText),
              alarms.indices.contains(index) else {
            tableView.reloadData()
            return
        }
        let alarm = alarms[index]
        context.notificationManager.cancel(alarm)
        let indexPath = IndexPath(row: index, section: 0)
        let deleteRows = { [weak self] in
            guard let self else { return }
            self.context.alarmManager.deleteAlarm(alarm)
            let remainingCount = self.context.alarmManager.sortedAlarms.count
            if remainingCount == 0 {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                    self?.tableView.reloadData()
                }
            } else {
                self.tableView.performBatchUpdates {
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                } completion: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            }
        }

        guard let cell = tableView.cellForRow(at: indexPath) else {
            deleteRows()
            return
        }

        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut]) {
            cell.contentView.alpha = 0
            cell.contentView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            deleteRows()
        }
    }

    @objc private func handleAlarmCardPan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view else { return }

        switch gesture.state {
        case .began:
            closeRevealedCards(excluding: card)
            card.layer.setValue(card.transform.tx, forKey: "swipeStartX")
        case .changed:
            let startX = (card.layer.value(forKey: "swipeStartX") as? NSNumber)?.doubleValue ?? 0
            let translation = gesture.translation(in: card.superview).x
            let targetX = min(0, max(-deleteRevealWidth, CGFloat(startX) + translation))
            card.transform = CGAffineTransform(translationX: targetX, y: 0)
            updateDeleteButtonAlpha(for: card)
        case .ended, .cancelled, .failed:
            let velocityX = gesture.velocity(in: card.superview).x
            let shouldReveal = card.transform.tx < -8 || velocityX < -120
            ignoresNextTapClose = true
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                card.transform = shouldReveal ? CGAffineTransform(translationX: -self.deleteRevealWidth, y: 0) : .identity
                self.deleteButton(for: card)?.alpha = shouldReveal ? 1 : 0
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.ignoresNextTapClose = false
                }
            }
        default:
            break
        }
    }

    @objc private func closeRevealedCardsFromTap(_ gesture: UITapGestureRecognizer) {
        guard !ignoresNextTapClose else { return }
        let point = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point),
           let cell = tableView.cellForRow(at: indexPath),
           let card = cell.contentView.viewWithTag(alarmCardTag),
           abs(card.transform.tx) <= 1 {
            return
        }
        closeRevealedCards()
    }

    private func closeRevealedCards(excluding excludedCard: UIView? = nil) {
        for cell in tableView.visibleCells {
            guard let card = cell.contentView.viewWithTag(alarmCardTag), card !== excludedCard, abs(card.transform.tx) > 1 else { continue }
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                card.transform = .identity
                self.deleteButton(for: card)?.alpha = 0
            }
        }
    }

    private func updateDeleteButtonAlpha(for card: UIView) {
        deleteButton(for: card)?.alpha = min(1, max(0, abs(card.transform.tx) / deleteRevealWidth))
    }

    private func deleteButton(for card: UIView) -> UIButton? {
        card.superview?.viewWithTag(deleteButtonTag) as? UIButton
    }
}

final class CreateAlarmUIKitViewController: WakeyBaseViewController {
    private static let memoPlaceholder = "가사에 포함하고 싶은 내용을 입력하세요."
    private let editingAlarm: AlarmSong?
    private let isReadOnly: Bool
    private let timePicker = UIDatePicker()
    private let repeatSummaryLabel = UILabel()
    private let alarmNameField = UITextField()
    private let snoozeSwitch = UISwitch()
    private let snoozeIntervalControl = UISegmentedControl(items: ["5분", "10분", "15분", "30분", "직접설정"])
    private let snoozeCustomIntervalField = UITextField()
    private let snoozeCountControl = UISegmentedControl(items: ["3회", "5회", "계속반복"])
    private let nicknameField = UITextField()
    private let memoView = UITextView()
    private let purposeControl = UISegmentedControl(items: AlarmPurpose.allCases.map(\.rawValue))
    private let moodControl = UISegmentedControl(items: AlarmMood.allCases.map(\.rawValue))
    private let includeNameSwitch = UISwitch()
    private let customSongSwitch = UISwitch()
    private let locationSwitch = UISwitch()
    private let weatherSwitch = UISwitch()
    private let calendarSwitch = UISwitch()
    private let generateButton = WakeyUIKitStyle.gradientButton(title: "알람송 생성하기")
    private let selectedDefaultSoundTitleLabel = UILabel()
    private let selectedDefaultSoundSubtitleLabel = UILabel()
    private let soundVolumeSlider = UISlider()
    private let soundVolumeValueLabel = UILabel()
    private let audioFileService = AudioFileService()
    private var previewPlayer: AVAudioPlayer?
    private var aiOptionsCard: UIView?
    private var defaultAlarmCard: UIView?
    private var selectedWeekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    private var selectedSpecificDate: Date?
    private var bundledAlarmSounds: [URL] = []
    private var selectedDefaultSoundURL: URL?
    private var selectedDefaultLibrarySong: AlarmSong?
    private var previewVolume: Float = 0.8
    private var weekdayButtons: [Weekday: UIButton] = [:]
    private let weekdayDisplayOrder: [Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    init(alarm: AlarmSong? = nil, isReadOnly: Bool = false) {
        self.editingAlarm = alarm
        self.isReadOnly = isReadOnly
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        editingAlarm = nil
        isReadOnly = false
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        title = isReadOnly ? "알람 보기" : (editingAlarm == nil ? "새 알람송 만들기" : "알람 수정")
        bundledAlarmSounds = AudioFileService.bundledAlarmSoundURLs()
        selectedDefaultSoundURL = bundledAlarmSounds.first

        timePicker.datePickerMode = .time
        timePicker.date = editingAlarm?.time ?? Date()
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)

        let stack = makeCreateAlarmLayout()
        if isReadOnly {
            stack.addArrangedSubview(readOnlyNoticeLabel())
        }
        stack.addArrangedSubview(card(scheduleAndAlarmSettingsStack(), padding: 20))

        customSongSwitch.isOn = true
        customSongSwitch.addTarget(self, action: #selector(customSongSwitchChanged), for: .valueChanged)
        locationSwitch.isOn = false
        weatherSwitch.isOn = false
        calendarSwitch.isOn = false

        nicknameField.placeholder = "닉네임을 입력하세요"
        nicknameField.text = WakeyProfile.nickname
        nicknameField.borderStyle = .none
        nicknameField.backgroundColor = .clear
        nicknameField.font = .systemFont(ofSize: 17)
        nicknameField.textColor = WakeyUIKitStyle.text
        nicknameField.clearButtonMode = .whileEditing
        nicknameField.heightAnchor.constraint(equalToConstant: 34).isActive = true

        purposeControl.selectedSegmentIndex = 0
        moodControl.selectedSegmentIndex = 0
        purposeControl.selectedSegmentTintColor = WakeyUIKitStyle.primary
        moodControl.selectedSegmentTintColor = WakeyUIKitStyle.primary

        memoView.font = .systemFont(ofSize: 16)
        memoView.layer.cornerRadius = 14
        memoView.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        memoView.layer.borderWidth = 1
        memoView.backgroundColor = .white
        memoView.text = Self.memoPlaceholder
        memoView.textColor = WakeyUIKitStyle.subtext
        memoView.delegate = self
        memoView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        memoView.textContainer.lineFragmentPadding = 0
        memoView.heightAnchor.constraint(equalToConstant: 110).isActive = true

        weatherSwitch.isOn = false
        stack.addArrangedSubview(card(songGenerationStack(), padding: 20))

        generateButton.addTarget(self, action: #selector(generate), for: .touchUpInside)

        [customSongSwitch, snoozeSwitch, locationSwitch, weatherSwitch, calendarSwitch].forEach {
            $0.onTintColor = WakeyUIKitStyle.primary
        }
        updateScheduleControls()
        updateSnoozeControls()
        updateCustomSongControls()
        applyEditingAlarmIfNeeded()
        if editingAlarm != nil && !isReadOnly {
            customSongSwitch.isUserInteractionEnabled = false
            customSongSwitch.alpha = 0.45
        }
        if isReadOnly {
            applyReadOnlyMode()
        }
    }

    private func makeCreateAlarmLayout() -> UIStackView {
        let timeContainer = UIView()
        let scrollView = UIScrollView()
        let stackView = UIStackView()
        let topFadeView = WakeyTopFadeView()
        let bottomFadeView = WakeyBottomFadeView()

        timeContainer.translatesAutoresizingMaskIntoConstraints = false
        timeContainer.backgroundColor = .clear
        timeContainer.clipsToBounds = true
        timePicker.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20

        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.constraints
            .filter { $0.firstAttribute == .height }
            .forEach { $0.constant = 50 }
        generateButton.layer.cornerRadius = 25
        generateButton.layer.shadowRadius = 8
        generateButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        topFadeView.translatesAutoresizingMaskIntoConstraints = false
        bottomFadeView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(timeContainer)
        timeContainer.addSubview(timePicker)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(topFadeView)
        view.addSubview(bottomFadeView)
        view.addSubview(generateButton)

        NSLayoutConstraint.activate([
            timeContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 2),
            timeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            timeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            timeContainer.heightAnchor.constraint(equalToConstant: 126),

            timePicker.centerXAnchor.constraint(equalTo: timeContainer.centerXAnchor),
            timePicker.centerYAnchor.constraint(equalTo: timeContainer.centerYAnchor),
            timePicker.widthAnchor.constraint(equalTo: timeContainer.widthAnchor, multiplier: 1.35),
            timePicker.heightAnchor.constraint(equalToConstant: 210),

            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            bottomFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomFadeView.topAnchor.constraint(equalTo: generateButton.topAnchor, constant: -52),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: -14),
            topFadeView.heightAnchor.constraint(equalToConstant: 52),

            scrollView.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -8),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 15),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -22),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -15),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -44)
        ])

        return stackView
    }

    private func readOnlyNoticeLabel() -> UILabel {
        let notice = label("AI 알람송을 재생하는 알람은 수정할 수 없어요", size: 13, weight: .medium, color: WakeyUIKitStyle.subtext, lines: 0)
        notice.textAlignment = .center
        return notice
    }

    private func labeled(_ title: String, _ view: UIView) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [label(title, size: 14, weight: .medium, color: WakeyUIKitStyle.subtext), view])
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }

    private func optionStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            optionRow(title: "위치 정보 반영", control: locationSwitch),
            optionRow(title: "날씨 정보 반영", control: weatherSwitch),
            optionRow(title: "캘린더 일정 반영", control: calendarSwitch)
        ])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }

    private func optionRow(title: String, control: UISwitch) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [label(title, size: 16), UIView(), control])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }

    private func alarmSettingsStack() -> UIStackView {
        alarmNameField.placeholder = "알람 이름"
        alarmNameField.text = nil
        alarmNameField.borderStyle = .none
        alarmNameField.font = .systemFont(ofSize: 17, weight: .medium)
        alarmNameField.textColor = WakeyUIKitStyle.text
        alarmNameField.clearButtonMode = .whileEditing
        alarmNameField.heightAnchor.constraint(equalToConstant: 34).isActive = true

        snoozeSwitch.isOn = true
        snoozeSwitch.addTarget(self, action: #selector(snoozeSwitchChanged), for: .valueChanged)

        configureSegmentedControl(snoozeIntervalControl, selectedIndex: 0)
        snoozeIntervalControl.addTarget(self, action: #selector(snoozeIntervalChanged), for: .valueChanged)

        snoozeCustomIntervalField.placeholder = "분"
        snoozeCustomIntervalField.keyboardType = .numberPad
        snoozeCustomIntervalField.borderStyle = .roundedRect
        snoozeCustomIntervalField.font = .systemFont(ofSize: 16)
        snoozeCustomIntervalField.text = "20"
        snoozeCustomIntervalField.heightAnchor.constraint(equalToConstant: 42).isActive = true

        configureSegmentedControl(snoozeCountControl, selectedIndex: 0)

        alarmNameField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        alarmNameField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [
            alarmNameField,
            divider(),
            optionRow(title: "반복알림", control: snoozeSwitch),
            divider(),
            labeled("다시알림 간격", snoozeIntervalControl),
            snoozeCustomIntervalField,
            divider(),
            labeled("횟수", snoozeCountControl)
        ])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }

    private func scheduleAndAlarmSettingsStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            scheduleSelectorStack(),
            divider(),
            alarmSettingsStack()
        ])
        stack.axis = .vertical
        stack.spacing = 18
        return stack
    }

    private func configureSegmentedControl(_ control: UISegmentedControl, selectedIndex: Int) {
        control.selectedSegmentIndex = selectedIndex
        control.selectedSegmentTintColor = WakeyUIKitStyle.primary
        control.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: WakeyUIKitStyle.text
        ], for: .normal)
        control.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.white
        ], for: .selected)
    }

    private func scheduleSelectorStack() -> UIStackView {
        repeatSummaryLabel.font = .systemFont(ofSize: 13, weight: .medium)
        repeatSummaryLabel.textColor = WakeyUIKitStyle.subtext

        let calendarButton = UIButton(type: .system)
        calendarButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarButton.tintColor = WakeyUIKitStyle.primary
        calendarButton.backgroundColor = .clear
        calendarButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        calendarButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        calendarButton.addTarget(self, action: #selector(openDatePicker), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [repeatSummaryLabel, UIView(), calendarButton])
        header.axis = .horizontal
        header.alignment = .center

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        row.spacing = 8

        for day in weekdayDisplayOrder {
            let button = UIButton(type: .system)
            button.setTitle(day.rawValue, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.layer.cornerRadius = 17
            button.widthAnchor.constraint(equalToConstant: 34).isActive = true
            button.heightAnchor.constraint(equalToConstant: 34).isActive = true
            button.tag = weekdayDisplayOrder.firstIndex(of: day) ?? 0
            button.addTarget(self, action: #selector(toggleWeekday(_:)), for: .touchUpInside)
            weekdayButtons[day] = button
            row.addArrangedSubview(button)
        }

        let stack = UIStackView(arrangedSubviews: [header, row])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func aiOptionsStack() -> UIStackView {
        let memoStack = labeled("메모", memoView)
        memoStack.spacing = 14

        let stack = UIStackView(arrangedSubviews: [
            labeled("부를 이름", nicknameField),
            divider(),
            labeled("알람 목적", purposeControl),
            divider(),
            labeled("분위기", moodControl),
            divider(),
            memoStack,
            divider(),
            optionStack()
        ])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }

    private func songGenerationStack() -> UIStackView {
        let aiOptions = aiOptionsStack()
        let defaultAlarm = defaultAlarmSelectionStack()
        aiOptionsCard = aiOptions
        defaultAlarmCard = defaultAlarm

        let stack = UIStackView(arrangedSubviews: [
            optionRow(title: "AI 알람송 생성", control: customSongSwitch),
            divider(),
            aiOptions,
            defaultAlarm
        ])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }

    private func defaultAlarmSelectionStack() -> UIStackView {
        let title = label("아이폰 기본 알람", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext)
        let selectedRow = UIStackView()
        selectedRow.axis = .horizontal
        selectedRow.alignment = .center
        selectedRow.spacing = 12

        let icon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))
        icon.tintColor = WakeyUIKitStyle.primary
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 25, weight: .semibold)
        icon.widthAnchor.constraint(equalToConstant: 46).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 46).isActive = true

        selectedDefaultSoundTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        selectedDefaultSoundTitleLabel.textColor = WakeyUIKitStyle.text
        selectedDefaultSoundSubtitleLabel.font = .systemFont(ofSize: 13)
        selectedDefaultSoundSubtitleLabel.textColor = WakeyUIKitStyle.subtext
        updateSelectedDefaultSoundLabels()

        let textStack = UIStackView(arrangedSubviews: [selectedDefaultSoundTitleLabel, selectedDefaultSoundSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        selectedRow.addArrangedSubview(icon)
        selectedRow.addArrangedSubview(textStack)
        selectedRow.addArrangedSubview(UIView())

        let stack = UIStackView(arrangedSubviews: [title, selectedRow, soundVolumeControl()])
        stack.axis = .vertical
        stack.spacing = 12
        selectedRow.isUserInteractionEnabled = true
        selectedRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSoundPicker)))
        return stack
    }

    private func soundVolumeControl() -> UIStackView {
        soundVolumeSlider.minimumValue = 0
        soundVolumeSlider.maximumValue = 1
        soundVolumeSlider.value = previewVolume
        soundVolumeSlider.minimumTrackTintColor = WakeyUIKitStyle.primary
        soundVolumeSlider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.10)
        soundVolumeSlider.addTarget(self, action: #selector(soundVolumeChanged(_:)), for: .valueChanged)
        soundVolumeSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(soundVolumeTapped(_:))))

        soundVolumeValueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        soundVolumeValueLabel.textColor = WakeyUIKitStyle.subtext
        updateSoundVolumeLabel()

        let header = UIStackView(arrangedSubviews: [
            label("알람 음량", size: 13, weight: .medium, color: WakeyUIKitStyle.subtext),
            UIView(),
            soundVolumeValueLabel
        ])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, soundVolumeSlider])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }

    private func updateSelectedDefaultSoundLabels() {
        if let selectedDefaultLibrarySong {
            selectedDefaultSoundTitleLabel.text = selectedDefaultLibrarySong.alarmName ?? "AI 알람송"
            selectedDefaultSoundSubtitleLabel.text = "라이브러리 AI 알람송"
        } else {
            selectedDefaultSoundTitleLabel.text = selectedDefaultSoundURL?.deletingPathExtension().lastPathComponent ?? "기본 알림음"
            selectedDefaultSoundSubtitleLabel.text = bundledAlarmSounds.isEmpty ? "AlarmSounds 폴더에 사운드를 넣어주세요" : "탭해서 알림음을 고르고 미리 듣기"
        }
    }

    private func divider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.06)
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    private func inputWithSwitch(_ input: UIView, _ control: UISwitch) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [input, control])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }

    @objc private func customSongSwitchChanged() {
        updateCustomSongControls()
    }

    @objc private func includeNameSwitchChanged() {
        updateCustomSongControls()
    }

    @objc private func snoozeSwitchChanged() {
        updateSnoozeControls()
    }

    @objc private func snoozeIntervalChanged() {
        updateSnoozeControls()
    }

    @objc private func openSoundPicker() {
        guard !bundledAlarmSounds.isEmpty || !context.alarmManager.generatedSongs.isEmpty else {
            showMessage("선택할 알림음이나 AI 알람송이 없어요.")
            return
        }

        let controller = AlarmSoundSelectionUIKitViewController(
            sounds: bundledAlarmSounds,
            librarySongs: context.alarmManager.generatedSongs,
            selectedSoundURL: selectedDefaultSoundURL,
            selectedLibrarySongId: selectedDefaultLibrarySong?.id,
            volume: previewVolume,
            onSelect: { [weak self] soundURL in
                self?.selectedDefaultLibrarySong = nil
                self?.selectedDefaultSoundURL = soundURL
                self?.updateSelectedDefaultSoundLabels()
            },
            onSelectLibrarySong: { [weak self] song in
                self?.selectedDefaultLibrarySong = song
                self?.selectedDefaultSoundURL = song.originalAudioURL
                self?.updateSelectedDefaultSoundLabels()
            },
            onVolumeChange: { [weak self] volume in
                self?.previewVolume = volume
                self?.soundVolumeSlider.value = volume
                self?.updateSoundVolumeLabel()
                self?.previewPlayer?.volume = volume
            }
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    private func preview(_ soundURL: URL) {
        previewPlayer?.stop()
        previewPlayer = try? AVAudioPlayer(contentsOf: soundURL)
        previewPlayer?.volume = previewVolume
        previewPlayer?.prepareToPlay()
        previewPlayer?.play()
    }

    @objc private func soundVolumeChanged(_ sender: UISlider) {
        previewVolume = sender.value
        updateSoundVolumeLabel()
        if previewPlayer?.isPlaying == true {
            previewPlayer?.volume = previewVolume
        } else if let selectedDefaultSoundURL {
            preview(selectedDefaultSoundURL)
        }
    }

    @objc private func soundVolumeTapped(_ sender: UITapGestureRecognizer) {
        guard let slider = sender.view as? UISlider else { return }
        let location = sender.location(in: slider)
        let ratio = min(max(location.x / slider.bounds.width, 0), 1)
        slider.value = Float(ratio) * (slider.maximumValue - slider.minimumValue) + slider.minimumValue
        soundVolumeChanged(slider)
    }

    private func updateSoundVolumeLabel() {
        soundVolumeValueLabel.text = "\(Int(round(previewVolume * 100)))%"
    }

    @objc private func toggleWeekday(_ sender: UIButton) {
        let day = weekdayDisplayOrder[sender.tag]
        selectedSpecificDate = nil
        if selectedWeekdays.contains(day) {
            selectedWeekdays.remove(day)
        } else {
            selectedWeekdays.insert(day)
        }
        updateScheduleControls()
    }

    @objc private func openDatePicker() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.minimumDate = Calendar.current.startOfDay(for: Date())
        picker.date = selectedSpecificDate ?? Date()

        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 42),
            picker.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 12),
            picker.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -12),
            picker.heightAnchor.constraint(equalToConstant: 210)
        ])
        alert.addAction(UIAlertAction(title: "선택", style: .default) { [weak self] _ in
            self?.selectedSpecificDate = picker.date
            self?.selectedWeekdays.removeAll()
            self?.updateScheduleControls()
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(alert, animated: true)
    }

    private func updateScheduleControls() {
        if let selectedSpecificDate {
            repeatSummaryLabel.text = selectedSpecificDate.koreanMonthDayWeekdayText
        } else if selectedWeekdays.isEmpty {
            repeatSummaryLabel.text = "반복 없음"
        } else {
            let days = weekdayDisplayOrder
                .filter { selectedWeekdays.contains($0) }
                .map(\.rawValue)
                .joined(separator: ", ")
            repeatSummaryLabel.text = "매주 \(days)"
        }

        for (day, button) in weekdayButtons {
            let isSelected = selectedWeekdays.contains(day)
            button.backgroundColor = isSelected ? WakeyUIKitStyle.primary : UIColor.black.withAlphaComponent(0.06)
            button.setTitleColor(isSelected ? .white : WakeyUIKitStyle.text, for: .normal)
        }
    }

    private func updateSnoozeControls() {
        let enabled = snoozeSwitch.isOn
        [snoozeIntervalControl, snoozeCountControl].forEach {
            $0.isUserInteractionEnabled = enabled
            $0.alpha = enabled ? 1.0 : 0.45
        }

        let usesCustomInterval = enabled && snoozeIntervalControl.selectedSegmentIndex == 4
        snoozeCustomIntervalField.isHidden = !usesCustomInterval
        snoozeCustomIntervalField.isUserInteractionEnabled = usesCustomInterval
        snoozeCustomIntervalField.alpha = usesCustomInterval ? 1.0 : 0.45
    }

    private func selectedSnoozeIntervalMinutes() -> Int {
        switch snoozeIntervalControl.selectedSegmentIndex {
        case 1:
            return 10
        case 2:
            return 15
        case 3:
            return 30
        case 4:
            let customValue = Int((snoozeCustomIntervalField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 5
            return max(customValue, 1)
        default:
            return 5
        }
    }

    private func selectedSnoozeRepeatCount() -> Int? {
        switch snoozeCountControl.selectedSegmentIndex {
        case 1:
            return 5
        case 2:
            return nil
        default:
            return 3
        }
    }

    private var resolvedMemoText: String {
        let memo = (memoView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return memo == Self.memoPlaceholder ? "" : memo
    }

    private func updateCustomSongControls() {
        let enabled = customSongSwitch.isOn
        aiOptionsCard?.isHidden = !enabled
        defaultAlarmCard?.isHidden = enabled
        generateButton.setTitle(enabled ? "알람송 생성하기" : "알람 저장하기", for: .normal)

        nicknameField.isUserInteractionEnabled = enabled
        nicknameField.alpha = enabled ? 1.0 : 0.45

        [purposeControl, moodControl, memoView, locationSwitch, weatherSwitch, calendarSwitch].forEach {
            $0.isUserInteractionEnabled = enabled
            $0.alpha = enabled ? 1.0 : 0.45
        }
    }

    private func applyEditingAlarmIfNeeded() {
        guard let alarm = editingAlarm else { return }
        let usesCustomSong = alarm.isAIAlarmSong

        timePicker.date = alarm.time
        selectedSpecificDate = alarm.repeatDays.isEmpty ? alarm.date : nil
        selectedWeekdays = alarm.repeatDays
        alarmNameField.text = alarm.alarmName ?? ""
        nicknameField.text = alarm.nickname
        customSongSwitch.isOn = usesCustomSong
        snoozeSwitch.isOn = alarm.snoozeEnabled ?? true
        snoozeIntervalControl.selectedSegmentIndex = snoozeIntervalIndex(for: alarm.snoozeIntervalMinutes ?? 5)
        snoozeCustomIntervalField.text = "\(alarm.snoozeIntervalMinutes ?? 5)"
        snoozeCountControl.selectedSegmentIndex = snoozeRepeatIndex(for: alarm.snoozeRepeatCount)
        purposeControl.selectedSegmentIndex = AlarmPurpose.allCases.firstIndex(of: alarm.purpose) ?? 0
        moodControl.selectedSegmentIndex = AlarmMood.allCases.firstIndex(of: alarm.mood) ?? 0
        memoView.text = alarm.memo.isEmpty ? Self.memoPlaceholder : alarm.memo
        memoView.textColor = alarm.memo.isEmpty ? WakeyUIKitStyle.subtext : WakeyUIKitStyle.text
        locationSwitch.isOn = alarm.locationSummary != nil
        weatherSwitch.isOn = alarm.weatherSummary != nil
        calendarSwitch.isOn = alarm.calendarSummary != nil
        previewVolume = alarm.resolvedAlarmVolume
        soundVolumeSlider.value = previewVolume
        updateSoundVolumeLabel()

        if let soundFileName = alarm.notificationAudioURL?.lastPathComponent,
           let soundURL = bundledAlarmSounds.first(where: { $0.lastPathComponent == soundFileName }) {
            selectedDefaultSoundURL = soundURL
            updateSelectedDefaultSoundLabels()
        }

        updateScheduleControls()
        updateSnoozeControls()
        updateCustomSongControls()
    }

    private func snoozeIntervalIndex(for minutes: Int) -> Int {
        switch minutes {
        case 5: return 0
        case 10: return 1
        case 15: return 2
        case 30: return 3
        default: return 4
        }
    }

    private func snoozeRepeatIndex(for count: Int?) -> Int {
        switch count {
        case 5: return 1
        case nil: return 2
        default: return 0
        }
    }

    private func applyReadOnlyMode() {
        generateButton.isEnabled = false
        generateButton.alpha = 0.35
        disableEditableControls(in: view)
    }

    private func disableEditableControls(in root: UIView) {
        for subview in root.subviews {
            if let control = subview as? UIControl {
                control.isUserInteractionEnabled = false
                control.alpha = min(control.alpha, 0.55)
            }
            if let textView = subview as? UITextView {
                textView.isEditable = false
                textView.isSelectable = false
                textView.alpha = min(textView.alpha, 0.55)
            }
            if let picker = subview as? UIDatePicker {
                picker.isUserInteractionEnabled = false
                picker.alpha = min(picker.alpha, 0.55)
            }
            if !(subview is UIScrollView) {
                subview.gestureRecognizers?.forEach { $0.isEnabled = false }
            }
            disableEditableControls(in: subview)
        }
    }

    @objc private func generate() {
        guard !isReadOnly else { return }
        generateButton.isEnabled = false
        generateButton.alpha = 0.72
        let alarmName = (alarmNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = (nicknameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !nickname.isEmpty {
            WakeyProfile.nickname = nickname
        }
        let purpose = AlarmPurpose.allCases[purposeControl.selectedSegmentIndex]
        let mood = AlarmMood.allCases[moodControl.selectedSegmentIndex]
        let draft = AlarmDraft(
            time: timePicker.date,
            selectedDate: selectedSpecificDate,
            alarmName: alarmName,
            nickname: nickname,
            includeNameInLyrics: !nickname.isEmpty,
            useCustomSong: customSongSwitch.isOn,
            defaultAlarmSoundFileName: selectedDefaultSoundURL?.lastPathComponent,
            defaultAlarmVolume: previewVolume,
            snoozeEnabled: snoozeSwitch.isOn,
            snoozeIntervalMinutes: selectedSnoozeIntervalMinutes(),
            snoozeRepeatCount: selectedSnoozeRepeatCount(),
            purpose: purpose,
            mood: mood,
            memo: resolvedMemoText,
            repeatDays: selectedWeekdays,
            useLocation: locationSwitch.isOn,
            useWeather: weatherSwitch.isOn,
            useCalendar: calendarSwitch.isOn
        )

        guard customSongSwitch.isOn else {
            saveDefaultAlarm(from: draft)
            return
        }

        generateButton.isEnabled = true
        generateButton.alpha = 1
        let controller = GeneratingUIKitViewController(draft: draft)
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    private func saveDefaultAlarm(from draft: AlarmDraft) {
        Task { [weak self] in
            guard let self else { return }
            var notificationAudioURL: URL?
            let alarmId = editingAlarm?.id ?? UUID()
            if let sourceURL = selectedDefaultLibrarySong?.originalAudioURL
                ?? selectedDefaultSoundURL {
                notificationAudioURL = try? await audioFileService.createShortNotificationAudio(
                    from: sourceURL,
                    alarmId: alarmId,
                    volume: draft.defaultAlarmVolume
                )
            }

            var alarm = AlarmSong(
                id: alarmId,
                time: draft.time,
                date: draft.selectedDate ?? Date(),
                isEnabled: editingAlarm?.isEnabled ?? true,
                alarmName: draft.alarmName.isEmpty ? nil : draft.alarmName,
                purpose: draft.purpose,
                mood: draft.mood,
                nickname: draft.nickname,
                memo: draft.memo,
                repeatDays: draft.repeatDays,
                snoozeEnabled: draft.snoozeEnabled,
                snoozeIntervalMinutes: draft.snoozeIntervalMinutes,
                snoozeRepeatCount: draft.snoozeRepeatCount,
                notificationAudioFilePath: notificationAudioURL?.lastPathComponent,
                alarmVolume: draft.defaultAlarmVolume,
                usesAIAlarmSong: false,
                createdAt: editingAlarm?.createdAt ?? Date()
            )

            if let editingAlarm {
                context.notificationManager.cancel(editingAlarm)
            }
            do {
                try await context.notificationManager.schedule(alarm)
            } catch {
                alarm.isEnabled = false
            }

            if editingAlarm == nil {
                context.alarmManager.add(alarm)
            } else {
                context.alarmManager.update(alarm)
            }
            generateButton.isEnabled = true
            generateButton.alpha = 1
            navigationController?.popViewController(animated: true)
        }
    }

    private func defaultAlarmCountdownText(for alarm: AlarmSong) -> String {
        guard let fireDate = nextFireDate(for: alarm) else {
            return "알람이 저장되었습니다."
        }

        let seconds = max(60, Int(fireDate.timeIntervalSince(Date())))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let dayText = days > 0 ? "\(days)일 " : ""
        return "\(dayText)\(hours)시간 \(minutes)분 뒤에 알람이 울립니다"
    }

    private func nextFireDate(for alarm: AlarmSong) -> Date? {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: alarm.time)
        let now = Date()

        if alarm.repeatDays.isEmpty {
            let base = calendar.startOfDay(for: alarm.date)
            let date = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: base) ?? alarm.date
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)
        }

        return (0..<14).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            guard alarm.repeatDays.contains(weekday(for: day)) else { return nil }
            let candidate = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: day)
            guard let candidate, candidate > now else { return nil }
            return candidate
        }.min()
    }

    private func weekday(for date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}

extension CreateAlarmUIKitViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        guard textView.text == Self.memoPlaceholder else { return }
        textView.text = ""
        textView.textColor = WakeyUIKitStyle.text
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        textView.text = Self.memoPlaceholder
        textView.textColor = WakeyUIKitStyle.subtext
    }
}

final class AlarmSoundSelectionUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let sounds: [URL]
    private let librarySongs: [AlarmSong]
    private var selectedSoundURL: URL?
    private var selectedLibrarySongId: UUID?
    private var volume: Float
    private let onSelect: (URL) -> Void
    private let onSelectLibrarySong: (AlarmSong) -> Void
    private let onVolumeChange: (Float) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let volumeSlider = UISlider()
    private let volumeValueLabel = UILabel()
    private var previewPlayer: AVAudioPlayer?

    init(
        sounds: [URL],
        librarySongs: [AlarmSong],
        selectedSoundURL: URL?,
        selectedLibrarySongId: UUID?,
        volume: Float,
        onSelect: @escaping (URL) -> Void,
        onSelectLibrarySong: @escaping (AlarmSong) -> Void,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.sounds = sounds
        self.librarySongs = librarySongs
        self.selectedSoundURL = selectedSoundURL
        self.selectedLibrarySongId = selectedLibrarySongId
        self.volume = volume
        self.onSelect = onSelect
        self.onSelectLibrarySong = onSelectLibrarySong
        self.onVolumeChange = onVolumeChange
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        sounds = []
        librarySongs = []
        selectedSoundURL = nil
        selectedLibrarySongId = nil
        volume = 0.8
        onSelect = { _ in }
        onSelectLibrarySong = { _ in }
        onVolumeChange = { _ in }
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알림 사운드"
        setupTable()
        setupVolumeBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previewPlayer?.stop()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.black.withAlphaComponent(0.08)
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "soundCell")
        view.addSubview(tableView)
    }

    private func setupVolumeBar() {
        let container = WakeyUIKitStyle.cardView()
        container.translatesAutoresizingMaskIntoConstraints = false

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = volume
        volumeSlider.minimumTrackTintColor = WakeyUIKitStyle.primary
        volumeSlider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.10)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(volumeTapped(_:))))

        volumeValueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        volumeValueLabel.textColor = WakeyUIKitStyle.subtext
        updateVolumeLabel()

        let header = UIStackView(arrangedSubviews: [
            label("알람 음량", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext),
            UIView(),
            volumeValueLabel
        ])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, volumeSlider])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -12)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sounds.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "soundCell", for: indexPath)

        cell.backgroundColor = WakeyUIKitStyle.background
        cell.selectionStyle = .default
        cell.contentView.backgroundColor = WakeyUIKitStyle.background
        cell.contentView.layer.cornerRadius = 0
        cell.contentView.layer.borderWidth = 0

        var configuration = UIListContentConfiguration.cell()
        if indexPath.row == 0 {
            configuration.text = "라이브러리에서 AI 알람송 선택"
            configuration.secondaryText = librarySongs.isEmpty ? "저장된 AI 알람송이 없어요" : "\(librarySongs.count)개의 알람송"
            configuration.image = UIImage(systemName: "music.note.list")
            configuration.textProperties.font = .systemFont(ofSize: 18, weight: .semibold)
            configuration.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
            configuration.secondaryTextProperties.color = WakeyUIKitStyle.subtext
            configuration.imageProperties.tintColor = WakeyUIKitStyle.primary
            cell.accessoryType = .disclosureIndicator
        } else {
            let soundURL = sounds[indexPath.row - 1]
            let isSelected = selectedLibrarySongId == nil && selectedSoundURL?.lastPathComponent == soundURL.lastPathComponent
            configuration.text = soundURL.deletingPathExtension().lastPathComponent
            configuration.textProperties.font = .systemFont(ofSize: 19, weight: .semibold)
            cell.accessoryType = isSelected ? .checkmark : .none
        }
        configuration.textProperties.color = WakeyUIKitStyle.text
        cell.contentConfiguration = configuration
        cell.tintColor = WakeyUIKitStyle.primary

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let controller = AIAlarmSongSelectionUIKitViewController(
                songs: librarySongs,
                selectedSongId: selectedLibrarySongId,
                volume: volume,
                onSelect: { [weak self] song in
                    self?.selectedLibrarySongId = song.id
                    self?.selectedSoundURL = song.originalAudioURL
                    self?.onSelectLibrarySong(song)
                    self?.tableView.reloadData()
                },
                onVolumeChange: { [weak self] volume in
                    self?.volume = volume
                    self?.volumeSlider.value = volume
                    self?.updateVolumeLabel()
                    self?.onVolumeChange(volume)
                }
            )
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        let soundURL = sounds[indexPath.row - 1]
        selectedLibrarySongId = nil
        selectedSoundURL = soundURL
        onSelect(soundURL)
        preview(soundURL)
        tableView.reloadData()
    }

    private func preview(_ soundURL: URL) {
        previewPlayer?.stop()
        previewPlayer = try? AVAudioPlayer(contentsOf: soundURL)
        previewPlayer?.volume = volume
        previewPlayer?.prepareToPlay()
        previewPlayer?.play()
    }

    @objc private func volumeChanged(_ sender: UISlider) {
        volume = sender.value
        updateVolumeLabel()
        onVolumeChange(volume)
        if previewPlayer?.isPlaying == true {
            previewPlayer?.volume = volume
        } else if let selectedSoundURL {
            preview(selectedSoundURL)
        }
    }

    @objc private func volumeTapped(_ sender: UITapGestureRecognizer) {
        guard let slider = sender.view as? UISlider else { return }
        let location = sender.location(in: slider)
        let ratio = min(max(location.x / slider.bounds.width, 0), 1)
        slider.value = Float(ratio) * (slider.maximumValue - slider.minimumValue) + slider.minimumValue
        volumeChanged(slider)
    }

    private func updateVolumeLabel() {
        volumeValueLabel.text = "\(Int(round(volume * 100)))%"
    }
}

final class AIAlarmSongSelectionUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let songs: [AlarmSong]
    private var selectedSongId: UUID?
    private var volume: Float
    private let onSelect: (AlarmSong) -> Void
    private let onVolumeChange: (Float) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let volumeSlider = UISlider()
    private let volumeValueLabel = UILabel()
    private var previewPlayer: AVAudioPlayer?

    init(
        songs: [AlarmSong],
        selectedSongId: UUID?,
        volume: Float,
        onSelect: @escaping (AlarmSong) -> Void,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.songs = songs
        self.selectedSongId = selectedSongId
        self.volume = volume
        self.onSelect = onSelect
        self.onVolumeChange = onVolumeChange
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        songs = []
        selectedSongId = nil
        volume = 0.8
        onSelect = { _ in }
        onVolumeChange = { _ in }
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI 알람송 선택"
        setupTable()
        setupVolumeBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previewPlayer?.stop()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.black.withAlphaComponent(0.08)
        tableView.rowHeight = 68
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "aiSongCell")
        view.addSubview(tableView)
    }

    private func setupVolumeBar() {
        let container = WakeyUIKitStyle.cardView()
        container.translatesAutoresizingMaskIntoConstraints = false

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = volume
        volumeSlider.minimumTrackTintColor = WakeyUIKitStyle.primary
        volumeSlider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.10)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(volumeTapped(_:))))

        volumeValueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        volumeValueLabel.textColor = WakeyUIKitStyle.subtext
        updateVolumeLabel()

        let header = UIStackView(arrangedSubviews: [
            label("알람 음량", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext),
            UIView(),
            volumeValueLabel
        ])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, volumeSlider])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -12)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aiSongCell", for: indexPath)
        let song = songs[indexPath.row]

        cell.backgroundColor = WakeyUIKitStyle.background
        cell.selectionStyle = .default
        cell.contentView.backgroundColor = WakeyUIKitStyle.background

        var configuration = UIListContentConfiguration.subtitleCell()
        configuration.text = song.alarmName ?? "AI 알람송"
        configuration.secondaryText = song.generatedAt?.formatted(date: .abbreviated, time: .omitted) ?? song.purpose.rawValue
        configuration.image = UIImage(systemName: "music.note")
        configuration.textProperties.font = .systemFont(ofSize: 18, weight: .semibold)
        configuration.textProperties.color = WakeyUIKitStyle.text
        configuration.secondaryTextProperties.font = .systemFont(ofSize: 13, weight: .regular)
        configuration.secondaryTextProperties.color = WakeyUIKitStyle.subtext
        configuration.imageProperties.tintColor = WakeyUIKitStyle.primary
        cell.contentConfiguration = configuration
        cell.accessoryType = selectedSongId == song.id ? .checkmark : .none
        cell.tintColor = WakeyUIKitStyle.primary
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = songs[indexPath.row]
        selectedSongId = song.id
        onSelect(song)
        if let url = song.originalAudioURL {
            preview(url)
        }
        tableView.reloadData()
    }

    private func preview(_ soundURL: URL) {
        previewPlayer?.stop()
        previewPlayer = try? AVAudioPlayer(contentsOf: soundURL)
        previewPlayer?.volume = volume
        previewPlayer?.prepareToPlay()
        previewPlayer?.play()
    }

    @objc private func volumeChanged(_ sender: UISlider) {
        volume = sender.value
        updateVolumeLabel()
        onVolumeChange(volume)
        previewPlayer?.volume = volume
    }

    @objc private func volumeTapped(_ sender: UITapGestureRecognizer) {
        guard let slider = sender.view as? UISlider else { return }
        let location = sender.location(in: slider)
        let ratio = min(max(location.x / slider.bounds.width, 0), 1)
        slider.value = Float(ratio) * (slider.maximumValue - slider.minimumValue) + slider.minimumValue
        volumeChanged(slider)
    }

    private func updateVolumeLabel() {
        volumeValueLabel.text = "\(Int(round(volume * 100)))%"
    }
}

final class GeneratingUIKitViewController: WakeyBaseViewController {
    private let draft: AlarmDraft
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let debugLabel = UILabel()
    private let viewModel = GeneratingViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var debugTimer: Timer?

    init(draft: AlarmDraft) {
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        draft = AlarmDraft()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "생성 중"
        let (_, stack) = makeScrollStack()
        stack.alignment = .center
        spinner.color = WakeyUIKitStyle.primary
        spinner.startAnimating()
        statusLabel.text = "알람송을 생성하는 중입니다."
        statusLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        debugLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        debugLabel.textColor = WakeyUIKitStyle.subtext
        debugLabel.numberOfLines = 0
        debugLabel.backgroundColor = UIColor.black.withAlphaComponent(0.04)
        debugLabel.layer.cornerRadius = 14
        debugLabel.clipsToBounds = true
        debugLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        let icon = UIImageView(image: UIImage(systemName: "music.note"))
        icon.tintColor = WakeyUIKitStyle.primary
        icon.contentMode = .center
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 64, weight: .medium)
        icon.widthAnchor.constraint(equalToConstant: 150).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 150).isActive = true
        icon.backgroundColor = WakeyUIKitStyle.primary.withAlphaComponent(0.10)
        icon.layer.cornerRadius = 75
        icon.clipsToBounds = true

        let detail = label("당신만을 위한 특별한 노래를 생성하고 있어요", size: 16, color: WakeyUIKitStyle.subtext, lines: 0)
        detail.textAlignment = .center
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(detail)
        statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true
        detail.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true

        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(debugLabel)
        debugLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true

        bindDebugState()
        updateDebugLabel()
        debugTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateDebugLabel()
        }

        Task {
            async let generatedAlarm = viewModel.generate(
                draft: draft,
                weatherService: context.weatherService,
                locationService: context.locationService,
                calendarService: context.calendarService,
                notificationService: context.notificationManager
            )
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            var alarm = await generatedAlarm
            do {
                try await context.notificationManager.schedule(alarm)
            } catch {
                alarm.isEnabled = false
            }
            context.alarmManager.upsert(alarm)
            statusLabel.text = "알람송이 준비되었습니다."
            
            if let navController = navigationController {
                var vcs = navController.viewControllers
                vcs.removeAll { $0 is CreateAlarmUIKitViewController || $0 is GeneratingUIKitViewController }
                vcs.append(AlarmDetailUIKitViewController(alarm: alarm, savesAlarmOnDone: true))
                navController.setViewControllers(vcs, animated: true)
            }
        }
    }

    private func bindDebugState() {
        Publishers.CombineLatest3(viewModel.$phase, viewModel.$debugStep, viewModel.$startedAt)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.updateDebugLabel()
            }
            .store(in: &cancellables)

        viewModel.$statusDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDebugLabel()
            }
            .store(in: &cancellables)

        viewModel.$lyrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDebugLabel()
            }
            .store(in: &cancellables)

        viewModel.$sunoDebugInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDebugLabel()
            }
            .store(in: &cancellables)
    }

    private func updateDebugLabel() {
        let elapsed = elapsedText(since: viewModel.startedAt, now: Date())
        let phaseText = phaseLabel(viewModel.phase)
        let lyricsText = "\(viewModel.lyrics?.count ?? 0) chars"
        let statusText = viewModel.statusDetail ?? "-"
        debugLabel.text = """
        DEBUG
        phase: \(phaseText)
        step: \(viewModel.debugStep)
        elapsed: \(elapsed)
        lyrics: \(lyricsText)
        status: \(statusText)
        suno:
        \(viewModel.sunoDebugInfo)
        """
    }

    private func phaseLabel(_ phase: GeneratingViewModel.Phase) -> String {
        switch phase {
        case .idle: return "idle"
        case .gatheringContext: return "gatheringContext"
        case .generatingLyrics: return "generatingLyrics"
        case .requestingMusic: return "requestingMusic"
        case .pollingMusic: return "pollingMusic"
        case .downloadingAudio: return "downloadingAudio"
        case .creatingNotificationAudio: return "creatingNotificationAudio"
        case .scheduling: return "scheduling"
        case .completed: return "completed"
        case .failed(let message): return "failed(\(message))"
        }
    }

    private func elapsedText(since startedAt: Date?, now: Date) -> String {
        guard let startedAt else { return "-" }
        let seconds = max(0, Int(now.timeIntervalSince(startedAt)))
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
}

final class AlarmDetailUIKitViewController: WakeyBaseViewController, UIScrollViewDelegate {
    private var alarm: AlarmSong
    private let savesAlarmOnDone: Bool
    private let player = AudioPlayerService()
    private let audioFileService = AudioFileService()
    private let playButton = UIButton(type: .system)
    private let volumeSlider = UISlider()
    private let volumeValueLabel = UILabel()
    private let artworkView = UIView()
    private let artworkIcon = UIImageView(image: UIImage(systemName: "music.note"))
    private let artworkLyricsScrollView = UIScrollView()
    private let artworkLyricsLabel = UILabel()
    private let progressSlider = UISlider()
    private let elapsedTimeLabel = UILabel()
    private let durationTimeLabel = UILabel()
    private var playbackTimer: Timer?
    private var isShowingArtworkLyrics = false
    private weak var detailScrollView: UIScrollView?
    private weak var volumeContainerView: UIView?
    private weak var doneButtonView: UIView?

    init(alarm: AlarmSong, savesAlarmOnDone: Bool = false) {
        self.alarm = alarm
        self.savesAlarmOnDone = savesAlarmOnDone
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        alarm = AlarmSong(time: Date(), purpose: .wakeup, mood: .exciting, nickname: WakeyProfile.nickname, memo: "")
        savesAlarmOnDone = false
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = savesAlarmOnDone ? "알람송 결과" : "알람송"
        player.volume = alarm.resolvedAlarmVolume
        render()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playbackTimer?.invalidate()
        playbackTimer = nil
        player.pause()
    }

    private func render() {
        let (scrollView, stack) = makeScrollStack()
        detailScrollView = scrollView
        scrollView.delegate = self
        stack.spacing = 18
        stack.alignment = .center

        let playerHero = UIStackView()
        playerHero.axis = .vertical
        playerHero.spacing = 24
        playerHero.alignment = .center
        playerHero.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 44)).isActive = true
        playerHero.heightAnchor.constraint(greaterThanOrEqualToConstant: detailHeroHeight()).isActive = true

        playerHero.addArrangedSubview(artworkSection())

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 8
        let songTitle = label(songTitleText, size: 28, weight: .semibold, lines: 2)
        songTitle.textAlignment = .center
        let songSubtitle = label("Wakey & Suno", size: 17, weight: .medium, color: WakeyUIKitStyle.subtext)
        songSubtitle.textAlignment = .center
        titleStack.addArrangedSubview(songTitle)
        titleStack.addArrangedSubview(songSubtitle)
        titleStack.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 56)).isActive = true
        playerHero.addArrangedSubview(titleStack)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        playerHero.addArrangedSubview(spacer)

        playerHero.addArrangedSubview(playbackSection())
        stack.addArrangedSubview(playerHero)
        let volume = volumeControl()
        volume.alpha = 0
        volume.isUserInteractionEnabled = false
        volumeContainerView = volume
        stack.addArrangedSubview(volume)

        let done = WakeyUIKitStyle.gradientButton(title: "완료")
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        done.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 44)).isActive = true
        done.alpha = 0
        done.isUserInteractionEnabled = false
        doneButtonView = done
        stack.addArrangedSubview(done)
    }

    private func detailContentWidth(inset: CGFloat) -> CGFloat {
        max(240, min(UIScreen.main.bounds.width - inset, 420))
    }

    private func detailHeroHeight() -> CGFloat {
        max(620, UIScreen.main.bounds.height - 190)
    }

    private var songTitleText: String {
        let title = alarm.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "Wakey Alarm Song" : title
    }

    private func artworkSection() -> UIView {
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.backgroundColor = WakeyUIKitStyle.primary
        artworkView.layer.cornerRadius = 32
        artworkView.clipsToBounds = false
        artworkView.layer.shadowColor = WakeyUIKitStyle.primary.cgColor
        artworkView.layer.shadowOpacity = 0.45
        artworkView.layer.shadowRadius = 26
        artworkView.layer.shadowOffset = CGSize(width: 0, height: 12)

        let inner = UIView()
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.backgroundColor = WakeyUIKitStyle.primary
        inner.layer.cornerRadius = 32
        inner.clipsToBounds = true
        artworkView.addSubview(inner)

        artworkIcon.tintColor = .white
        artworkIcon.contentMode = .center
        artworkIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 78, weight: .semibold)
        artworkIcon.translatesAutoresizingMaskIntoConstraints = false
        inner.addSubview(artworkIcon)

        artworkLyricsScrollView.translatesAutoresizingMaskIntoConstraints = false
        artworkLyricsScrollView.alpha = 0
        artworkLyricsScrollView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        artworkLyricsScrollView.clipsToBounds = true
        inner.addSubview(artworkLyricsScrollView)

        artworkLyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        artworkLyricsLabel.text = spaciousLyricsText(alarm.lyrics ?? AlarmManager.sampleLyrics)
        artworkLyricsLabel.textColor = .white
        artworkLyricsLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        artworkLyricsLabel.numberOfLines = 0
        artworkLyricsLabel.textAlignment = .center
        artworkLyricsScrollView.addSubview(artworkLyricsLabel)

        NSLayoutConstraint.activate([
            artworkView.widthAnchor.constraint(equalToConstant: max(240, min(UIScreen.main.bounds.width * 0.76, 340))),
            artworkView.heightAnchor.constraint(equalTo: artworkView.widthAnchor),
            inner.topAnchor.constraint(equalTo: artworkView.topAnchor),
            inner.leadingAnchor.constraint(equalTo: artworkView.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: artworkView.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: artworkView.bottomAnchor),
            artworkIcon.centerXAnchor.constraint(equalTo: inner.centerXAnchor),
            artworkIcon.centerYAnchor.constraint(equalTo: inner.centerYAnchor),
            artworkIcon.widthAnchor.constraint(equalToConstant: 120),
            artworkIcon.heightAnchor.constraint(equalToConstant: 120),
            artworkLyricsScrollView.topAnchor.constraint(equalTo: inner.topAnchor),
            artworkLyricsScrollView.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            artworkLyricsScrollView.trailingAnchor.constraint(equalTo: inner.trailingAnchor),
            artworkLyricsScrollView.bottomAnchor.constraint(equalTo: inner.bottomAnchor),
            artworkLyricsLabel.topAnchor.constraint(equalTo: artworkLyricsScrollView.contentLayoutGuide.topAnchor, constant: 24),
            artworkLyricsLabel.leadingAnchor.constraint(equalTo: artworkLyricsScrollView.contentLayoutGuide.leadingAnchor, constant: 22),
            artworkLyricsLabel.trailingAnchor.constraint(equalTo: artworkLyricsScrollView.contentLayoutGuide.trailingAnchor, constant: -22),
            artworkLyricsLabel.bottomAnchor.constraint(equalTo: artworkLyricsScrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            artworkLyricsLabel.widthAnchor.constraint(equalTo: artworkLyricsScrollView.frameLayoutGuide.widthAnchor, constant: -44)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleArtworkLyrics))
        tap.cancelsTouchesInView = false
        artworkView.addGestureRecognizer(tap)
        return artworkView
    }

    private func spaciousLyricsText(_ lyrics: String) -> String {
        lyrics
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: "\n\n")
    }

    private func playbackSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 28
        stack.alignment = .center
        stack.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 44)).isActive = true

        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = WakeyUIKitStyle.primary
        progressSlider.maximumTrackTintColor = WakeyUIKitStyle.primary.withAlphaComponent(0.18)
        progressSlider.thumbTintColor = WakeyUIKitStyle.primary
        progressSlider.isUserInteractionEnabled = false

        elapsedTimeLabel.text = "0:00"
        elapsedTimeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        elapsedTimeLabel.textColor = WakeyUIKitStyle.text
        durationTimeLabel.text = "--:--"
        durationTimeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        durationTimeLabel.textColor = WakeyUIKitStyle.text

        let timeRow = UIStackView(arrangedSubviews: [elapsedTimeLabel, UIView(), durationTimeLabel])
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 58)).isActive = true

        let progressStack = UIStackView(arrangedSubviews: [timeRow, progressSlider])
        progressStack.axis = .vertical
        progressStack.spacing = 8
        progressStack.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 58)).isActive = true
        stack.addArrangedSubview(progressStack)

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = WakeyUIKitStyle.primary
        playButton.layer.cornerRadius = 40
        playButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 27, weight: .bold), forImageIn: .normal)
        playButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        playButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        stack.addArrangedSubview(playButton)
        return stack
    }

    private func volumeControl() -> UIView {
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = player.volume
        volumeSlider.minimumTrackTintColor = WakeyUIKitStyle.primary
        volumeSlider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.10)
        volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
        volumeSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(volumeTapped(_:))))

        volumeValueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        volumeValueLabel.textColor = WakeyUIKitStyle.subtext
        updateVolumeLabel()

        let header = UIStackView(arrangedSubviews: [
            label("알람 음량", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext),
            UIView(),
            volumeValueLabel
        ])
        header.axis = .horizontal
        header.alignment = .center

        let stack = UIStackView(arrangedSubviews: [header, volumeSlider])
        stack.axis = .vertical
        stack.spacing = 8
        let container = card(stack, padding: 20)
        container.widthAnchor.constraint(equalToConstant: detailContentWidth(inset: 44)).isActive = true
        return container
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === detailScrollView else { return }
        let alpha = max(0, min(1, (scrollView.contentOffset.y - 24) / 88))
        volumeContainerView?.alpha = alpha
        doneButtonView?.alpha = alpha

        let isInteractive = alpha > 0.35
        volumeContainerView?.isUserInteractionEnabled = isInteractive
        doneButtonView?.isUserInteractionEnabled = isInteractive
    }

    @objc private func toggleArtworkLyrics() {
        isShowingArtworkLyrics.toggle()
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.artworkLyricsScrollView.alpha = self.isShowingArtworkLyrics ? 1 : 0
            self.artworkIcon.alpha = self.isShowingArtworkLyrics ? 0.12 : 1
            self.artworkView.transform = self.isShowingArtworkLyrics
                ? CGAffineTransform(scaleX: 0.985, y: 0.985)
                : .identity
        }
    }

    @objc private func togglePlayback() {
        player.toggle(url: alarm.originalAudioURL)
        if let message = player.message {
            showMessage(message)
        }
        playButton.setImage(UIImage(systemName: player.isPlaying ? "pause.fill" : "play.fill"), for: .normal)
        if player.isPlaying {
            startPlaybackTimer()
        } else {
            playbackTimer?.invalidate()
            playbackTimer = nil
        }
        updatePlaybackProgress()
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackProgress()
            }
        }
    }

    private func updatePlaybackProgress() {
        let duration = player.duration
        let currentTime = player.currentTime
        elapsedTimeLabel.text = timeText(currentTime)
        durationTimeLabel.text = duration > 0 ? timeText(duration) : "--:--"
        progressSlider.value = duration > 0 ? Float(currentTime / duration) : 0

        if duration > 0, currentTime >= duration {
            playbackTimer?.invalidate()
            playbackTimer = nil
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }

    private func timeText(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }

    @objc private func volumeChanged(_ sender: UISlider) {
        player.volume = sender.value
        updateVolumeLabel()
    }

    @objc private func volumeTapped(_ sender: UITapGestureRecognizer) {
        guard let slider = sender.view as? UISlider else { return }
        let location = sender.location(in: slider)
        let ratio = min(max(location.x / slider.bounds.width, 0), 1)
        slider.value = Float(ratio) * (slider.maximumValue - slider.minimumValue) + slider.minimumValue
        volumeChanged(slider)
    }

    private func updateVolumeLabel() {
        volumeValueLabel.text = "\(Int(round(player.volume * 100)))%"
    }

    @objc private func doneTapped() {
        guard savesAlarmOnDone else {
            navigationController?.popViewController(animated: true)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            var scheduledAlarm = alarm
            scheduledAlarm.alarmVolume = player.volume
            if let originalAudioURL = scheduledAlarm.originalAudioURL,
               let notificationAudioURL = try? await audioFileService.createShortNotificationAudio(
                from: originalAudioURL,
                alarmId: scheduledAlarm.id,
                volume: player.volume
               ) {
                scheduledAlarm.notificationAudioFilePath = notificationAudioURL.lastPathComponent
            }
            do {
                try await context.notificationManager.schedule(scheduledAlarm)
            } catch {
                scheduledAlarm.isEnabled = false
            }
            context.alarmManager.upsert(scheduledAlarm)
            navigationController?.popToRootViewController(animated: true)
        }
    }

    private func defaultAlarmCountdownText(for alarm: AlarmSong) -> String {
        guard let fireDate = nextFireDate(for: alarm) else {
            return "알람이 저장되었습니다."
        }

        let seconds = max(60, Int(fireDate.timeIntervalSince(Date())))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        let dayText = days > 0 ? "\(days)일 " : ""
        return "\(dayText)\(hours)시간 \(minutes)분 뒤에 알람이 울립니다"
    }

    private func nextFireDate(for alarm: AlarmSong) -> Date? {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: alarm.time)
        let now = Date()

        if alarm.repeatDays.isEmpty {
            let base = calendar.startOfDay(for: alarm.date)
            let date = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: base) ?? alarm.date
            return date > now ? date : calendar.date(byAdding: .day, value: 1, to: date)
        }

        return (0..<14).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            guard alarm.repeatDays.contains(weekday(for: day)) else { return nil }
            let candidate = calendar.date(bySettingHour: time.hour ?? 7, minute: time.minute ?? 0, second: 0, of: day)
            guard let candidate, candidate > now else { return nil }
            return candidate
        }.min()
    }

    private func weekday(for date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}

final class LibraryUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let player = AudioPlayerService()
    private let deleteRevealWidth: CGFloat = 80
    private let libraryCardTag = 3701
    private let deleteButtonTag = 3702
    private var ignoresNextTapClose = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "라이브러리"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 88
        tableView.sectionHeaderHeight = 10
        tableView.sectionFooterHeight = 10
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "libraryCell")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeRevealedLibraryCardsFromTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        tableView.addGestureRecognizer(tapGesture)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = context.alarmManager.generatedSongs.count
        if count == 0 {
            let emptyLabel = UILabel()
            emptyLabel.text = "AI 알람송이 없어요"
            emptyLabel.textColor = WakeyUIKitStyle.subtext
            emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
            emptyLabel.textAlignment = .center
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath)
        let songs = context.alarmManager.generatedSongs
        let song = songs[indexPath.row]
        configureLibrarySongCell(cell, song: song, index: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let songs = context.alarmManager.generatedSongs
        guard songs.indices.contains(indexPath.row) else { return }
        guard !ignoresNextTapClose else { return }
        if let card = tableView.cellForRow(at: indexPath)?.contentView.viewWithTag(libraryCardTag),
           abs(card.transform.tx) > 1 {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                card.transform = .identity
                self.deleteButton(for: card)?.alpha = 0
            }
            return
        }
        navigationController?.pushViewController(AlarmDetailUIKitViewController(alarm: songs[indexPath.row]), animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let currentView = view {
            if currentView is UIButton {
                return false
            }
            view = currentView.superview
        }
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let songs = context.alarmManager.generatedSongs
        guard songs.indices.contains(indexPath.row) else { return }
        let song = songs[indexPath.row]
        context.alarmManager.deleteGeneratedSong(song)
        tableView.reloadData()
    }

    private func configureLibrarySongCell(_ cell: UITableViewCell, song: AlarmSong, index: Int) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.contentConfiguration = nil
        cell.accessoryView = nil
        cell.selectionStyle = .none
        cell.clipsToBounds = false
        cell.contentView.clipsToBounds = false
        cell.contentView.alpha = 1
        cell.contentView.transform = .identity

        let deleteButton = UIButton(type: .system)
        deleteButton.tag = deleteButtonTag
        deleteButton.accessibilityIdentifier = "\(index)"
        deleteButton.backgroundColor = WakeyUIKitStyle.destructive
        deleteButton.tintColor = .white
        deleteButton.alpha = 0
        deleteButton.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        deleteButton.layer.cornerRadius = 20
        deleteButton.clipsToBounds = true
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteLibrarySongFromButton(_:)), for: .touchUpInside)
        cell.contentView.addSubview(deleteButton)

        let card = WakeyUIKitStyle.cardView()
        card.tag = libraryCardTag
        card.translatesAutoresizingMaskIntoConstraints = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleLibraryCardPan(_:)))
        pan.cancelsTouchesInView = false
        card.addGestureRecognizer(pan)
        cell.contentView.addSubview(card)

        let album = UIView()
        album.backgroundColor = WakeyUIKitStyle.primary
        album.layer.cornerRadius = 12
        album.clipsToBounds = true
        album.translatesAutoresizingMaskIntoConstraints = false
        album.widthAnchor.constraint(equalToConstant: 54).isActive = true
        album.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let note = UIImageView(image: UIImage(systemName: "music.note"))
        note.tintColor = .white
        note.contentMode = .center
        note.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        note.translatesAutoresizingMaskIntoConstraints = false
        album.addSubview(note)
        NSLayoutConstraint.activate([
            note.centerXAnchor.constraint(equalTo: album.centerXAnchor),
            note.centerYAnchor.constraint(equalTo: album.centerYAnchor)
        ])

        let title = song.alarmName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleLabel = label(title?.isEmpty == false ? title! : "Wakey Alarm Song", size: 17, weight: .semibold, lines: 1)
        let subtitleLabel = label("\(song.purpose.rawValue) · \(song.mood.rawValue) · \((song.generatedAt ?? song.createdAt).koreanMonthDayText)", size: 13, color: WakeyUIKitStyle.subtext, lines: 1)
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [album, textStack, UIView()])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -22),
            deleteButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: deleteRevealWidth),
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 22),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -22),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
    }

    @objc private func deleteLibrarySongFromButton(_ sender: UIButton) {
        let songs = context.alarmManager.generatedSongs
        guard let indexText = sender.accessibilityIdentifier,
              let index = Int(indexText),
              songs.indices.contains(index) else {
            tableView.reloadData()
            return
        }
        let song = songs[index]
        let indexPath = IndexPath(row: index, section: 0)
        let deleteRows = { [weak self] in
            guard let self else { return }
            self.context.alarmManager.deleteGeneratedSong(song)
            let remainingCount = self.context.alarmManager.generatedSongs.count
            if remainingCount == 0 {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                    self?.tableView.reloadData()
                }
            } else {
                self.tableView.performBatchUpdates {
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                } completion: { [weak self] _ in
                    self?.tableView.reloadData()
                }
            }
        }

        guard let cell = tableView.cellForRow(at: indexPath) else {
            deleteRows()
            return
        }

        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut]) {
            cell.contentView.alpha = 0
            cell.contentView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            deleteRows()
        }
    }

    @objc private func handleLibraryCardPan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view else { return }

        switch gesture.state {
        case .began:
            closeRevealedLibraryCards(excluding: card)
            card.layer.setValue(card.transform.tx, forKey: "swipeStartX")
        case .changed:
            let startX = (card.layer.value(forKey: "swipeStartX") as? NSNumber)?.doubleValue ?? 0
            let translation = gesture.translation(in: card.superview).x
            let targetX = min(0, max(-deleteRevealWidth, CGFloat(startX) + translation))
            card.transform = CGAffineTransform(translationX: targetX, y: 0)
            updateDeleteButtonAlpha(for: card)
        case .ended, .cancelled, .failed:
            let velocityX = gesture.velocity(in: card.superview).x
            let shouldReveal = card.transform.tx < -8 || velocityX < -120
            ignoresNextTapClose = true
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                card.transform = shouldReveal ? CGAffineTransform(translationX: -self.deleteRevealWidth, y: 0) : .identity
                self.deleteButton(for: card)?.alpha = shouldReveal ? 1 : 0
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.ignoresNextTapClose = false
                }
            }
        default:
            break
        }
    }

    @objc private func closeRevealedLibraryCardsFromTap(_ gesture: UITapGestureRecognizer) {
        guard !ignoresNextTapClose else { return }
        let point = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point),
           let cell = tableView.cellForRow(at: indexPath),
           let card = cell.contentView.viewWithTag(libraryCardTag),
           abs(card.transform.tx) <= 1 {
            return
        }
        closeRevealedLibraryCards()
    }

    private func closeRevealedLibraryCards(excluding excludedCard: UIView? = nil) {
        for cell in tableView.visibleCells {
            guard let card = cell.contentView.viewWithTag(libraryCardTag), card !== excludedCard, abs(card.transform.tx) > 1 else { continue }
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                card.transform = .identity
                self.deleteButton(for: card)?.alpha = 0
            }
        }
    }

    private func updateDeleteButtonAlpha(for card: UIView) {
        deleteButton(for: card)?.alpha = min(1, max(0, abs(card.transform.tx) / deleteRevealWidth))
    }

    private func deleteButton(for card: UIView) -> UIButton? {
        card.superview?.viewWithTag(deleteButtonTag) as? UIButton
    }
}

final class SettingsUIKitViewController: WakeyBaseViewController {
    private let nicknameValueLabel = UILabel()
    private let notificationStatusLabel = UILabel()
    private let locationStatusLabel = UILabel()
    private let weatherStatusLabel = UILabel()
    private let calendarStatusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "설정"
        let (_, stack) = makeScrollStack()
        stack.spacing = 34

        stack.addArrangedSubview(settingsSection(title: "프로필", rows: [
            settingsRow(
                iconName: "person",
                iconColor: WakeyUIKitStyle.primary,
                title: "닉네임",
                subtitleLabel: nicknameValueLabel,
                action: #selector(editNickname)
            )
        ]))

        stack.addArrangedSubview(settingsSection(title: "권한 설정", rows: [
            settingsRow(
                iconName: "bell",
                iconColor: WakeyUIKitStyle.destructive,
                title: "알림",
                subtitleLabel: notificationStatusLabel,
                action: #selector(requestNotification)
            ),
            settingsRow(
                iconName: "mappin.and.ellipse",
                iconColor: WakeyUIKitStyle.accent,
                title: "위치",
                subtitleLabel: locationStatusLabel,
                action: #selector(requestLocation)
            ),
            settingsRow(
                iconName: "cloud.sun",
                iconColor: WakeyUIKitStyle.secondary,
                title: "날씨",
                subtitleLabel: weatherStatusLabel,
                action: #selector(requestLocation)
            ),
            settingsRow(
                iconName: "calendar",
                iconColor: WakeyUIKitStyle.primary,
                title: "캘린더",
                subtitleLabel: calendarStatusLabel,
                action: #selector(requestCalendar)
            )
        ]))

        let copyright = label("Wakey © 2026", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext)
        copyright.textAlignment = .center
        stack.addArrangedSubview(copyright)

        refreshSettingsRows()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        context.notificationManager.refreshStatus()
        context.locationService.refreshStatus()
        context.calendarService.refreshStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.refreshSettingsRows()
        }
    }

    private func settingsSection(title: String, rows: [UIView]) -> UIView {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 18

        let titleLabel = label(title, size: 14, weight: .semibold, color: WakeyUIKitStyle.subtext)
        contentStack.addArrangedSubview(titleLabel)

        for (index, row) in rows.enumerated() {
            contentStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.black.withAlphaComponent(0.07)
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                contentStack.addArrangedSubview(divider)
            }
        }

        return card(contentStack, padding: 24)
    }

    private func settingsRow(iconName: String, iconColor: UIColor, title: String, subtitleLabel: UILabel, action: Selector) -> UIControl {
        let row = UIControl()
        row.addTarget(self, action: action, for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = WakeyUIKitStyle.primary
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        icon.widthAnchor.constraint(equalToConstant: 44).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let titleLabel = label(title, size: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = WakeyUIKitStyle.subtext

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = WakeyUIKitStyle.subtext
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let rowStack = UIStackView(arrangedSubviews: [icon, textStack, UIView(), chevron])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 14
        rowStack.isUserInteractionEnabled = false
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 2),
            rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -2),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 62)
        ])
        return row
    }

    private func refreshSettingsRows() {
        nicknameValueLabel.text = WakeyProfile.nickname
        notificationStatusLabel.text = notificationSubtitle
        locationStatusLabel.text = locationSubtitle
        weatherStatusLabel.text = weatherSubtitle
        calendarStatusLabel.text = calendarSubtitle
    }

    @objc private func editNickname() {
        let alert = UIAlertController(title: "닉네임", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = WakeyProfile.nickname
            textField.placeholder = "닉네임"
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self, weak alert] _ in
            WakeyProfile.nickname = alert?.textFields?.first?.text ?? WakeyProfile.defaultNickname
            self?.refreshSettingsRows()
            self?.showMessage("닉네임이 저장되었습니다.")
        })
        present(alert, animated: true)
    }

    @objc private func requestNotification() {
        context.notificationManager.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshSettingsRows()
        }
    }

    @objc private func requestLocation() {
        context.locationService.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshSettingsRows()
        }
    }

    @objc private func requestCalendar() {
        context.calendarService.requestPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshSettingsRows()
        }
    }

    private var notificationSubtitle: String {
        switch context.notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "허용됨"
        case .denied:
            return "허용 안 함"
        case .notDetermined:
            return "권한 요청 필요"
        @unknown default:
            return "확인 필요"
        }
    }

    private var locationSubtitle: String {
        switch context.locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return "허용됨"
        case .denied, .restricted:
            return "허용 안 함"
        case .notDetermined:
            return "권한 요청 필요"
        @unknown default:
            return "확인 필요"
        }
    }

    private var weatherSubtitle: String {
        switch context.locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return "사용 가능"
        case .denied, .restricted:
            return "위치 권한 필요"
        case .notDetermined:
            return "권한 요청 필요"
        @unknown default:
            return "확인 필요"
        }
    }

    private var calendarSubtitle: String {
        let status = context.calendarService.authorizationStatus
        if #available(iOS 17.0, *) {
            switch status {
            case .fullAccess, .authorized:
                return "허용됨"
            case .writeOnly:
                return "읽기 권한 필요"
            case .denied, .restricted:
                return "허용 안 함"
            case .notDetermined:
                return "권한 요청 필요"
            @unknown default:
                return "확인 필요"
            }
        } else {
            switch status {
            case .authorized:
                return "허용됨"
            case .denied, .restricted:
                return "허용 안 함"
            case .notDetermined:
                return "권한 요청 필요"
            default:
                return "확인 필요"
            }
        }
    }
}
