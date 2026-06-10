import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var alarmManager: AlarmManager
    let onShowDetail: (AlarmSong) -> Void
    @State private var searchQuery = ""
    @State private var selectedMood: AlarmMood?
    @State private var showFilter = false
    @StateObject private var audioPlayer = AudioPlayerService()

    private var filteredSongs: [AlarmSong] {
        alarmManager.generatedSongs
            .filter { alarm in
                guard !searchQuery.isEmpty else { return true }
                let target = "\(alarm.time.alarmTimeText) \(alarm.purpose.rawValue) \(alarm.mood.rawValue) \(alarm.lyrics ?? "") \(alarm.memo)"
                return target.localizedCaseInsensitiveContains(searchQuery)
            }
            .filter { selectedMood == nil || $0.mood == selectedMood }
            .sorted { ($0.generatedAt ?? .distantPast) > ($1.generatedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 16) {
                    if filteredSongs.isEmpty {
                        EmptyStateView(icon: "music.note.list", title: "알람송이 없어요", message: "새 알람송을 만들어보세요")
                    } else {
                        if let message = audioPlayer.message {
                            Text(message)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(WakeyColors.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        ForEach(filteredSongs) { song in
                            LibrarySongCard(
                                song: song,
                                onOpen: { onShowDetail(song) },
                                onPlay: { audioPlayer.toggle(url: song.originalAudioURL) }
                            )
                            .swipeActions {
                                Button(role: .destructive) {
                                    alarmManager.delete(song)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
        }
        .wakeyScreenBackground()
        .sheet(isPresented: $showFilter) {
            NavigationStack {
                List {
                    Button("전체") {
                        selectedMood = nil
                        showFilter = false
                    }
                    ForEach(AlarmMood.allCases) { mood in
                        Button(mood.rawValue) {
                            selectedMood = mood
                            showFilter = false
                        }
                    }
                }
                .navigationTitle("분위기 필터")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("라이브러리")
                .font(.system(size: 31, weight: .semibold))
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(WakeyColors.textSecondary)
                    TextField("알람송 검색", text: $searchQuery)
                        .font(.system(size: 17))
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
                .wakeyCard(cornerRadius: 18)

                Button {
                    showFilter = true
                } label: {
                    Image(systemName: selectedMood == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .frame(width: 56, height: 56)
                        .wakeyCard(cornerRadius: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .background(WakeyColors.background.opacity(0.96))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.05)).frame(height: 1) }
    }
}

private struct LibrarySongCard: View {
    let song: AlarmSong
    let onOpen: () -> Void
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(song.time.alarmTimeText)
                        .font(.system(size: 27, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text((song.generatedAt ?? Date()).koreanMonthDayText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(WakeyColors.textSecondary)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        songChips
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        songChips
                    }
                }
                Text((song.lyrics ?? "").replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 15))
                    .foregroundStyle(WakeyColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            IconCircleButton(systemName: "play.fill", action: onPlay)
        }
        .padding(24)
        .wakeyCard(cornerRadius: 26)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture(perform: onOpen)
    }

    private var songChips: some View {
        Group {
            WakeyChip(text: song.purpose.rawValue, color: WakeyColors.secondary)
            WakeyChip(text: song.mood.rawValue, color: WakeyColors.primary)
        }
    }
}
