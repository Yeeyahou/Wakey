import UIKit
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
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {
        super.init(frame: .zero)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
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

final class WakeyBottomFadeView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            WakeyUIKitStyle.background.withAlphaComponent(0).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0.98).cgColor,
            WakeyUIKitStyle.background.cgColor
        ]
        gradientLayer.locations = [0, 0.38, 1]
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
            WakeyUIKitStyle.background.cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0.94).cgColor,
            WakeyUIKitStyle.background.withAlphaComponent(0).cgColor
        ]
        gradientLayer.locations = [0, 0.46, 1]
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
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -110),
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
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 38),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -38),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22)
        ])
    }
}

final class WakeyTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

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
        render()
    }

    private func render() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(label("좋은 아침이에요!", size: 31, weight: .semibold))
        stackView.addArrangedSubview(weatherSummaryRow())

        let next = context.alarmManager.nextAlarm
        let nextStack = UIStackView()
        nextStack.axis = .vertical
        nextStack.spacing = 12
        nextStack.addArrangedSubview(label("다음 알람", size: 15, weight: .medium, color: WakeyUIKitStyle.subtext))
        nextStack.addArrangedSubview(label(next?.time.alarmTimeText ?? "예정된 알람이 없어요", size: next == nil ? 24 : 44, weight: .medium))
        if let next {
            nextStack.addArrangedSubview(chipRow([
                WakeyChipLabel(text: next.purpose.rawValue, color: WakeyUIKitStyle.primary),
                label("\(next.mood.rawValue) 분위기", size: 16, weight: .medium, color: WakeyUIKitStyle.subtext)
            ]))
        }
        stackView.addArrangedSubview(softGradientCard(nextStack, padding: 28))

        let recentStack = UIStackView()
        recentStack.axis = .vertical
        recentStack.spacing = 14
        recentStack.addArrangedSubview(label("최근 생성된 알람송", size: 23, weight: .semibold))
        let recent = context.alarmManager.recentGenerated
        if let recent {
            let info = UIStackView()
            info.axis = .vertical
            info.spacing = 10
            info.addArrangedSubview(chipRow([
                label(recent.time.alarmTimeText, size: 25, weight: .medium),
                WakeyChipLabel(text: recent.purpose.rawValue, color: WakeyUIKitStyle.secondary)
            ]))
            info.addArrangedSubview(label("\"\((recent.lyrics ?? "").split(separator: "\n").first ?? "알람송이 준비됐어요")\"", size: 16, color: WakeyUIKitStyle.subtext, lines: 2))
            recentStack.addArrangedSubview(info)
        } else {
            recentStack.addArrangedSubview(label("아직 생성된 알람송이 없어요", size: 18, color: WakeyUIKitStyle.subtext, lines: 2))
        }
        stackView.addArrangedSubview(card(recentStack, padding: 24))

        let createButton = WakeyUIKitStyle.gradientButton(title: "나만의 알람송 만들기", image: UIImage(systemName: "plus"))
        createButton.addTarget(self, action: #selector(openCreate), for: .touchUpInside)
        stackView.addArrangedSubview(createButton)
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
        navigationController?.pushViewController(CreateAlarmUIKitViewController(), animated: true)
    }
}

class AlarmListUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알람"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(openCreate))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 132
        tableView.sectionHeaderHeight = 18
        tableView.sectionFooterHeight = 18
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        max(context.alarmManager.sortedAlarms.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let alarms = context.alarmManager.sortedAlarms
        guard !alarms.isEmpty else {
            configureCardCell(cell, title: "알람이 없어요", subtitle: "새 알람송을 만들어 알람을 추가하세요", accessory: nil)
            return cell
        }

        let alarm = alarms[indexPath.row]
        let toggle = UISwitch()
        toggle.isOn = alarm.isEnabled
        toggle.onTintColor = WakeyUIKitStyle.primary
        toggle.tag = indexPath.row
        toggle.addTarget(self, action: #selector(toggleAlarm(_:)), for: .valueChanged)
        let alarmTitle = alarm.alarmName.flatMap { $0.isEmpty ? nil : $0 } ?? alarm.purpose.rawValue
        configureCardCell(
            cell,
            title: "\(alarm.time.alarmTimeText)  \(alarmTitle)",
            subtitle: "\(alarm.mood.rawValue) · \(alarm.memo)",
            accessory: toggle
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alarms = context.alarmManager.sortedAlarms
        guard alarms.indices.contains(indexPath.row) else { return }
        navigationController?.pushViewController(AlarmDetailUIKitViewController(alarm: alarms[indexPath.row]), animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let alarm = context.alarmManager.sortedAlarms[indexPath.row]
        context.notificationManager.cancel(alarm)
        context.alarmManager.delete(alarm)
        tableView.reloadData()
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
        navigationController?.pushViewController(CreateAlarmUIKitViewController(), animated: true)
    }
}

final class CreateAlarmUIKitViewController: WakeyBaseViewController {
    private static let memoPlaceholder = "가사에 포함하고 싶은 내용을 입력하세요."
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
    private var previewVolume: Float = 0.8
    private var weekdayButtons: [Weekday: UIButton] = [:]
    private let weekdayDisplayOrder: [Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "새 알람송 만들기"
        bundledAlarmSounds = AudioFileService.bundledAlarmSoundURLs()
        selectedDefaultSoundURL = bundledAlarmSounds.first

        timePicker.datePickerMode = .time
        timePicker.date = Date()
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)

        let stack = makeCreateAlarmLayout()
        stack.addArrangedSubview(card(scheduleAndAlarmSettingsStack(), padding: 20))

        customSongSwitch.isOn = true
        customSongSwitch.addTarget(self, action: #selector(customSongSwitchChanged), for: .valueChanged)

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

        weatherSwitch.isOn = true
        stack.addArrangedSubview(card(songGenerationStack(), padding: 20))

        generateButton.addTarget(self, action: #selector(generate), for: .touchUpInside)

        [customSongSwitch, snoozeSwitch, locationSwitch, weatherSwitch, calendarSwitch].forEach {
            $0.onTintColor = WakeyUIKitStyle.primary
        }
        updateScheduleControls()
        updateSnoozeControls()
        updateCustomSongControls()
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
            bottomFadeView.topAnchor.constraint(equalTo: generateButton.topAnchor, constant: -72),
            bottomFadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topFadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topFadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topFadeView.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: -28),
            topFadeView.heightAnchor.constraint(equalToConstant: 78),

            scrollView.topAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -8),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 22),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -22),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -44)
        ])

        return stackView
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
            optionRow(title: "AI 알림송 생성", control: customSongSwitch),
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

        let icon = UIImageView(image: UIImage(systemName: "bell.fill"))
        icon.tintColor = WakeyUIKitStyle.primary
        icon.contentMode = .center
        icon.backgroundColor = WakeyUIKitStyle.primary.withAlphaComponent(0.12)
        icon.layer.cornerRadius = 20
        icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 40).isActive = true

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
        selectedDefaultSoundTitleLabel.text = selectedDefaultSoundURL?.deletingPathExtension().lastPathComponent ?? "기본 알림음"
        selectedDefaultSoundSubtitleLabel.text = bundledAlarmSounds.isEmpty ? "AlarmSounds 폴더에 사운드를 넣어주세요" : "탭해서 알림음을 고르고 미리 듣기"
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
        guard !bundledAlarmSounds.isEmpty else {
            showMessage("AlarmSounds 폴더에 wav, caf, aiff 파일을 넣어주세요.")
            return
        }

        let controller = AlarmSoundSelectionUIKitViewController(
            sounds: bundledAlarmSounds,
            selectedSoundURL: selectedDefaultSoundURL,
            volume: previewVolume,
            onSelect: { [weak self] soundURL in
                self?.selectedDefaultSoundURL = soundURL
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

    @objc private func generate() {
        let alarmName = (alarmNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = (nicknameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !customSongSwitch.isOn || !nickname.isEmpty else {
            showMessage("부를 이름을 입력하세요.")
            return
        }

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
        navigationController?.pushViewController(GeneratingUIKitViewController(draft: draft), animated: true)
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
    private var selectedSoundURL: URL?
    private var volume: Float
    private let onSelect: (URL) -> Void
    private let onVolumeChange: (Float) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let volumeSlider = UISlider()
    private let volumeValueLabel = UILabel()
    private var previewPlayer: AVAudioPlayer?

    init(
        sounds: [URL],
        selectedSoundURL: URL?,
        volume: Float,
        onSelect: @escaping (URL) -> Void,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.sounds = sounds
        self.selectedSoundURL = selectedSoundURL
        self.volume = volume
        self.onSelect = onSelect
        self.onVolumeChange = onVolumeChange
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        sounds = []
        selectedSoundURL = nil
        volume = 0.8
        onSelect = { _ in }
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
        sounds.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "soundCell", for: indexPath)
        let soundURL = sounds[indexPath.row]
        let isSelected = selectedSoundURL?.lastPathComponent == soundURL.lastPathComponent

        cell.backgroundColor = WakeyUIKitStyle.background
        cell.selectionStyle = .default
        cell.contentView.backgroundColor = WakeyUIKitStyle.background
        cell.contentView.layer.cornerRadius = 0
        cell.contentView.layer.borderWidth = 0

        var configuration = UIListContentConfiguration.cell()
        configuration.text = soundURL.deletingPathExtension().lastPathComponent
        configuration.textProperties.font = .systemFont(ofSize: 19, weight: .semibold)
        configuration.textProperties.color = WakeyUIKitStyle.text
        cell.contentConfiguration = configuration
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.tintColor = WakeyUIKitStyle.primary

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let soundURL = sounds[indexPath.row]
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

final class GeneratingUIKitViewController: WakeyBaseViewController {
    private let draft: AlarmDraft
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let viewModel = GeneratingViewModel()

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
        let cardStack = UIStackView(arrangedSubviews: [
            chipRow([
                WakeyChipLabel(text: draft.mood.rawValue, color: WakeyUIKitStyle.accent),
                WakeyChipLabel(text: draft.purpose.rawValue, color: WakeyUIKitStyle.secondary)
            ]),
            label("\"\(draft.memo)\"", size: 14, color: WakeyUIKitStyle.subtext, lines: 2)
        ])
        cardStack.axis = .vertical
        cardStack.spacing = 14

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(detail)
        let contextCard = card(cardStack, padding: 24)
        stack.addArrangedSubview(contextCard)
        contextCard.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true
        statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true
        detail.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -56).isActive = true

        stack.addArrangedSubview(spinner)

        Task {
            let alarm = await viewModel.generate(
                draft: draft,
                weatherService: context.weatherService,
                locationService: context.locationService,
                calendarService: context.calendarService,
                notificationService: context.notificationManager
            )
            context.alarmManager.add(alarm)
            statusLabel.text = "알람이 저장되었습니다."
            try? await Task.sleep(nanoseconds: 500_000_000)
            navigationController?.setViewControllers([HomeUIKitViewController(), AlarmDetailUIKitViewController(alarm: alarm)], animated: true)
        }
    }
}

final class AlarmDetailUIKitViewController: WakeyBaseViewController {
    private var alarm: AlarmSong
    private let player = AudioPlayerService()

    init(alarm: AlarmSong) {
        self.alarm = alarm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        alarm = AlarmSong(time: Date(), purpose: .wakeup, mood: .exciting, nickname: WakeyProfile.nickname, memo: "")
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "알람송"
        render()
    }

    private func render() {
        let (_, stack) = makeScrollStack()
        let time = label(alarm.time.alarmTimeText, size: 54, weight: .medium)
        time.textAlignment = .center
        stack.addArrangedSubview(time)
        stack.addArrangedSubview(chipRow([
            WakeyChipLabel(text: alarm.purpose.rawValue, color: WakeyUIKitStyle.secondary),
            WakeyChipLabel(text: alarm.mood.rawValue, color: WakeyUIKitStyle.accent)
        ]))

        let memoStack = UIStackView()
        memoStack.axis = .vertical
        memoStack.spacing = 10
        memoStack.addArrangedSubview(label("메모", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext))
        memoStack.addArrangedSubview(label("\"\(alarm.memo.isEmpty ? "메모가 없어요" : alarm.memo)\"", size: 17, lines: 0))
        stack.addArrangedSubview(card(memoStack, padding: 24))

        let lyricsStack = UIStackView()
        lyricsStack.axis = .vertical
        lyricsStack.spacing = 18
        lyricsStack.addArrangedSubview(label("가사 미리보기", size: 14, weight: .medium, color: WakeyUIKitStyle.subtext))
        let lyrics = label(alarm.lyrics ?? AlarmManager.sampleLyrics, size: 18, lines: 0)
        lyrics.textAlignment = .center
        lyricsStack.addArrangedSubview(lyrics)
        stack.addArrangedSubview(softGradientCard(lyricsStack, padding: 24))

        let infoText = "날씨: \(alarm.weatherSummary ?? "반영 안 함")\n위치: \(alarm.locationSummary ?? "반영 안 함")\n일정: \(alarm.calendarSummary ?? "반영 안 함")"
        stack.addArrangedSubview(card(label(infoText, size: 15, color: WakeyUIKitStyle.subtext, lines: 0)))

        let play = WakeyUIKitStyle.plainButton(title: "전체 노래 듣기")
        play.addTarget(self, action: #selector(playAudio), for: .touchUpInside)
        stack.addArrangedSubview(play)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        let regenerate = WakeyUIKitStyle.plainButton(title: "다시 생성")
        regenerate.addTarget(self, action: #selector(regenerateSong), for: .touchUpInside)
        let delete = WakeyUIKitStyle.plainButton(title: "삭제", color: WakeyUIKitStyle.destructive)
        delete.addTarget(self, action: #selector(deleteAlarm), for: .touchUpInside)
        row.addArrangedSubview(regenerate)
        row.addArrangedSubview(delete)
        stack.addArrangedSubview(row)

        let done = WakeyUIKitStyle.gradientButton(title: "완료", image: UIImage(systemName: "checkmark"))
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        stack.addArrangedSubview(done)
    }

    @objc private func playAudio() {
        player.toggle(url: alarm.originalAudioURL)
        if let message = player.message {
            showMessage(message)
        }
    }

    @objc private func regenerateSong() {
        context.notificationManager.cancel(alarm)
        context.alarmManager.delete(alarm)
        let draft = AlarmDraft(
            time: alarm.time,
            selectedDate: alarm.repeatDays.isEmpty ? alarm.date : nil,
            alarmName: alarm.alarmName ?? "",
            nickname: alarm.nickname,
            includeNameInLyrics: !alarm.nickname.isEmpty,
            useCustomSong: alarm.lyrics != nil || alarm.originalAudioURL != nil,
            snoozeEnabled: alarm.snoozeEnabled ?? true,
            snoozeIntervalMinutes: alarm.snoozeIntervalMinutes ?? 5,
            snoozeRepeatCount: alarm.snoozeRepeatCount ?? 3,
            purpose: alarm.purpose,
            mood: alarm.mood,
            memo: alarm.memo,
            repeatDays: alarm.repeatDays,
            useLocation: alarm.locationSummary != nil,
            useWeather: alarm.weatherSummary != nil,
            useCalendar: alarm.calendarSummary != nil
        )
        navigationController?.pushViewController(GeneratingUIKitViewController(draft: draft), animated: true)
    }

    @objc private func deleteAlarm() {
        context.notificationManager.cancel(alarm)
        context.alarmManager.delete(alarm)
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func doneTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}

final class LibraryUIKitViewController: WakeyBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let player = AudioPlayerService()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "라이브러리"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = WakeyUIKitStyle.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 132
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "libraryCell")
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
        max(context.alarmManager.generatedSongs.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath)
        let songs = context.alarmManager.generatedSongs
        guard !songs.isEmpty else {
            configureCardCell(cell, title: "알람송이 없어요", subtitle: "새 알람송을 만들어보세요", accessory: nil)
            return cell
        }

        let song = songs[indexPath.row]
        let play = UIButton(type: .system)
        play.setImage(UIImage(systemName: "play.fill"), for: .normal)
        play.tintColor = .white
        play.backgroundColor = WakeyUIKitStyle.primary.withAlphaComponent(0.88)
        play.layer.cornerRadius = 24
        play.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
        play.widthAnchor.constraint(equalToConstant: 48).isActive = true
        play.heightAnchor.constraint(equalToConstant: 48).isActive = true
        play.tag = indexPath.row
        play.addTarget(self, action: #selector(playSong(_:)), for: .touchUpInside)
        configureCardCell(
            cell,
            title: "\(song.time.alarmTimeText)  \(song.purpose.rawValue)",
            subtitle: "\(song.mood.rawValue) · \((song.generatedAt ?? song.createdAt).koreanMonthDayText)",
            accessory: play
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let songs = context.alarmManager.generatedSongs
        guard songs.indices.contains(indexPath.row) else { return }
        navigationController?.pushViewController(AlarmDetailUIKitViewController(alarm: songs[indexPath.row]), animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let songs = context.alarmManager.generatedSongs
        guard songs.indices.contains(indexPath.row) else { return }
        let song = songs[indexPath.row]
        context.notificationManager.cancel(song)
        context.alarmManager.delete(song)
        tableView.reloadData()
    }

    @objc private func playSong(_ sender: UIButton) {
        let songs = context.alarmManager.generatedSongs
        guard songs.indices.contains(sender.tag) else { return }
        player.toggle(url: songs[sender.tag].originalAudioURL)
        if let message = player.message {
            showMessage(message)
        }
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

        let iconContainer = UIView()
        iconContainer.backgroundColor = iconColor.withAlphaComponent(0.11)
        iconContainer.layer.cornerRadius = 23
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.widthAnchor.constraint(equalToConstant: 46).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = iconColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])

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

        let rowStack = UIStackView(arrangedSubviews: [iconContainer, textStack, UIView(), chevron])
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
