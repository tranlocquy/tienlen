import SwiftUI

final class TienLenGame: ObservableObject {
    @Published private var engine = TienLenEngine()
    @Published private(set) var selectedCardIDs: Set<UUID> = []
    @Published var showingRoundResult = false
    @Published private(set) var roundSummary = ""

    var players: [Player] { engine.state.players }
    var currentPlayerID: UUID? { engine.state.currentPlayerID }
    var currentTrick: Trick? { engine.state.currentTrick }
    var statusMessage: String { engine.state.statusMessage }
    var humanPlayerID: UUID { engine.humanPlayerID }
    var humanHand: [Card] { engine.humanHand() }
    var selectedCards: [Card] { humanHand.filter { selectedCardIDs.contains($0.id) } }

    init() {
        startNewRound()
    }

    func isSelected(_ card: Card) -> Bool {
        selectedCardIDs.contains(card.id)
    }

    func toggleSelection(for card: Card) {
        guard currentPlayerID == humanPlayerID else { return }
        if selectedCardIDs.contains(card.id) {
            selectedCardIDs.remove(card.id)
        } else {
            selectedCardIDs.insert(card.id)
        }
        objectWillChange.send()
    }

    func playSelectedCards() {
        guard currentPlayerID == humanPlayerID else { return }
        let result = engine.play(selectedCards, by: humanPlayerID)
        selectedCardIDs.removeAll()
        objectWillChange.send()
        handlePostAction(result: result)
    }

    func humanPass() {
        guard currentPlayerID == humanPlayerID else { return }
        let result = engine.pass(playerID: humanPlayerID)
        objectWillChange.send()
        handlePostAction(result: result)
    }

    func startNewRound() {
        engine.startNewRound()
        selectedCardIDs.removeAll()
        showingRoundResult = false
        roundSummary = ""
        objectWillChange.send()
        if currentPlayerID != humanPlayerID {
            engine.stepAIUntilHumanTurn()
            objectWillChange.send()
        }
    }

    private func handlePostAction(result: Result<Void, TienLenMoveError>) {
        if case .success = result {
            if let winner = engine.state.winningPlayerName {
                roundSummary = "\(winner) wins the round!"
                showingRoundResult = true
            } else {
                engine.stepAIUntilHumanTurn()
                if let winner = engine.state.winningPlayerName {
                    roundSummary = "\(winner) wins the round!"
                    showingRoundResult = true
                }
            }
        }
        objectWillChange.send()
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
