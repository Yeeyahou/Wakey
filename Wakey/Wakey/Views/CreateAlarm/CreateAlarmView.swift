import SwiftUI

struct CreateAlarmView: View {
    let onBack: () -> Void
    let onGenerate: (AlarmDraft) -> Void
    @AppStorage("wakey.profile.nickname") private var storedNickname = "지우"
    @State private var draft = AlarmDraft()
    @State private var showValidation = false

    var body: some View {
        VStack(spacing: 0) {
            navBar
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    timePicker
                    nicknameField
                    optionGrid(title: "알람 목적", items: AlarmPurpose.allCases, selected: $draft.purpose, color: WakeyColors.primary)
                    optionGrid(title: "분위기", items: AlarmMood.allCases, selected: $draft.mood, color: WakeyColors.accent)
                    memoField
                    togglesCard
                    if showValidation && draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("닉네임을 입력하세요.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(WakeyColors.destructive)
                    }
                    GradientButton(title: "알람송 생성하기", systemImage: nil) {
                        guard !draft.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            withAnimation(.spring()) { showValidation = true }
                            return
                        }
                        storedNickname = draft.nickname
                        onGenerate(draft)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
        }
        .wakeyScreenBackground()
        .onAppear {
            draft.nickname = storedNickname
        }
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            Text("새 알람송 만들기")
                .font(.system(size: 22, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(WakeyColors.background.opacity(0.96))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.05)).frame(height: 1) }
    }

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("알람 시간")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            DatePicker("", selection: $draft.time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .wakeyCard(cornerRadius: 24)
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("닉네임")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            TextField("닉네임을 입력하세요", text: $draft.nickname)
                .font(.system(size: 17))
                .padding(16)
                .wakeyCard(cornerRadius: 18)
        }
    }

    private func optionGrid<T: RawRepresentable & CaseIterable & Identifiable & Equatable>(title: String, items: [T], selected: Binding<T>, color: Color) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            FlowLayout(spacing: 9) {
                ForEach(items) { item in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selected.wrappedValue = item
                        }
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selected.wrappedValue == item ? .white : WakeyColors.textPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selected.wrappedValue == item ? color : WakeyColors.cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black.opacity(0.07), lineWidth: selected.wrappedValue == item ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("메모")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WakeyColors.textSecondary)
            TextEditor(text: $draft.memo)
                .font(.system(size: 16))
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(12)
                .wakeyCard(cornerRadius: 18)
                .overlay(alignment: .topLeading) {
                    if draft.memo.isEmpty {
                        Text("알람송에 포함하고 싶은 내용을 입력하세요")
                            .font(.system(size: 16))
                            .foregroundStyle(WakeyColors.textSecondary.opacity(0.7))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 21)
                    }
                }
        }
    }

    private var togglesCard: some View {
        VStack(spacing: 18) {
            ToggleRow(icon: "mappin.and.ellipse", title: "위치 정보 반영", isOn: $draft.useLocation)
            Divider()
            ToggleRow(icon: "cloud.fill", title: "날씨 정보 반영", isOn: $draft.useWeather)
            Divider()
            ToggleRow(icon: "calendar", title: "캘린더 일정 반영", iconColor: WakeyColors.primary, isOn: $draft.useCalendar)
        }
        .padding(22)
        .wakeyCard(cornerRadius: 24)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
