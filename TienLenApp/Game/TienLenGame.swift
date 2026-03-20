import SwiftUI

enum TienLenGameMode: String, CaseIterable, Identifiable {
    case singlePlayer
    case localMultiplayer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singlePlayer:
            return "Solo vs AI"
        case .localMultiplayer:
            return "Local 4P"
        }
    }

    var description: String {
        switch self {
        case .singlePlayer:
            return "One visible hand against three AI opponents."
        case .localMultiplayer:
            return "Four local players take turns on one device with a pass-and-play hand reveal."
        }
    }
}

final class TienLenGame: ObservableObject {
    @Published private var engine: TienLenEngine
    @Published private(set) var selectedCardIDs: Set<UUID> = []
    @Published private(set) var mode: TienLenGameMode
    @Published private(set) var isAwaitingTurnReveal = false
    @Published var showingRoundResult = false
    @Published private(set) var roundSummary = ""

    init(mode: TienLenGameMode = .singlePlayer) {
        self.mode = mode
        self.engine = TienLenGame.makeEngine(for: mode)
        startNewRound()
    }

    var players: [Player] { engine.state.players }
    var currentPlayerID: UUID? { engine.state.currentPlayerID }
    var currentTrick: Trick? { engine.state.currentTrick }
    var statusMessage: String { engine.state.statusMessage }
    var visiblePlayerID: UUID? {
        switch mode {
        case .singlePlayer:
            return engine.humanPlayerID
        case .localMultiplayer:
            return isAwaitingTurnReveal ? nil : engine.state.currentPlayerID
        }
    }
    var currentPlayerName: String {
        players.first(where: { $0.id == currentPlayerID })?.name ?? "Next player"
    }
    var visibleHand: [Card] {
        guard let visiblePlayerID else { return [] }
        return players.first(where: { $0.id == visiblePlayerID })?.hand ?? []
    }
    var selectedCards: [Card] { visibleHand.filter { selectedCardIDs.contains($0.id) } }
    var handTitle: String {
        switch mode {
        case .singlePlayer:
            return "Your Hand"
        case .localMultiplayer:
            return isAwaitingTurnReveal ? "Hidden Hand" : "\(currentPlayerName)'s Hand"
        }
    }
    var handSubtitle: String {
        switch mode {
        case .singlePlayer:
            return "Choose cards from your hand, then play or pass."
        case .localMultiplayer:
            return isAwaitingTurnReveal
                ? "Keep cards hidden until the next player is ready."
                : "Only the active player's cards are shown."
        }
    }

    func setMode(_ newMode: TienLenGameMode) {
        guard mode != newMode else { return }
        mode = newMode
        engine = Self.makeEngine(for: newMode)
        startNewRound()
    }

    func isSelected(_ card: Card) -> Bool {
        selectedCardIDs.contains(card.id)
    }

    func toggleSelection(for card: Card) {
        guard !isAwaitingTurnReveal, let visiblePlayerID, currentPlayerID == visiblePlayerID else { return }
        if selectedCardIDs.contains(card.id) {
            selectedCardIDs.remove(card.id)
        } else {
            selectedCardIDs.insert(card.id)
        }
        objectWillChange.send()
    }

    func playSelectedCards() {
        guard !isAwaitingTurnReveal, let playerID = controllablePlayerID else { return }
        let result = engine.play(selectedCards, by: playerID)
        selectedCardIDs.removeAll()
        objectWillChange.send()
        handlePostAction(result: result)
    }

    func humanPass() {
        guard !isAwaitingTurnReveal, let playerID = controllablePlayerID else { return }
        let result = engine.pass(playerID: playerID)
        objectWillChange.send()
        handlePostAction(result: result)
    }

    func revealCurrentTurn() {
        guard mode == .localMultiplayer, currentPlayerID != nil else { return }
        isAwaitingTurnReveal = false
        selectedCardIDs.removeAll()
        objectWillChange.send()
    }

    func startNewRound() {
        engine.startNewRound()
        selectedCardIDs.removeAll()
        showingRoundResult = false
        roundSummary = ""
        isAwaitingTurnReveal = false

        if mode == .singlePlayer {
            if currentPlayerID != engine.humanPlayerID {
                engine.stepAIUntilHumanTurn()
            }
        } else if currentPlayerID != nil {
            isAwaitingTurnReveal = true
        }

        objectWillChange.send()
    }

    private var controllablePlayerID: UUID? {
        switch mode {
        case .singlePlayer:
            return engine.humanPlayerID
        case .localMultiplayer:
            return currentPlayerID
        }
    }

    private func handlePostAction(result: Result<Void, TienLenMoveError>) {
        if case .success = result {
            if let winner = engine.state.winningPlayerName {
                roundSummary = "\(winner) wins the round!"
                showingRoundResult = true
                isAwaitingTurnReveal = false
            } else {
                if mode == .singlePlayer {
                    engine.stepAIUntilHumanTurn()
                    if let winner = engine.state.winningPlayerName {
                        roundSummary = "\(winner) wins the round!"
                        showingRoundResult = true
                    }
                } else if engine.state.currentPlayerID != nil {
                    isAwaitingTurnReveal = true
                }
            }
        }
        objectWillChange.send()
    }

    private static func makeEngine(for mode: TienLenGameMode) -> TienLenEngine {
        switch mode {
        case .singlePlayer:
            return TienLenEngine(playerNames: ["You", "Lan", "Minh", "Khoa"], humanPlayerIndex: 0)
        case .localMultiplayer:
            return TienLenEngine(playerNames: ["Player 1", "Player 2", "Player 3", "Player 4"], humanPlayerIndex: 0)
        }
    }
}

extension Suit {
    var color: Color {
        switch self {
        case .diamonds, .hearts:
            return .red
        case .spades, .clubs:
            return .black
        }
    }
}
