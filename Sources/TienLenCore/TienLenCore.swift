import Foundation

public struct Player: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public var hand: [Card]
    public var hasPassed: Bool

    public init(id: UUID, name: String, hand: [Card], hasPassed: Bool = false) {
        self.id = id
        self.name = name
        self.hand = hand
        self.hasPassed = hasPassed
    }
}

public struct Trick: Equatable {
    public let ownerID: UUID
    public let ownerName: String
    public let cards: [Card]
    public let combo: Combo

    public init(ownerID: UUID, ownerName: String, cards: [Card], combo: Combo) {
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.cards = cards
        self.combo = combo
    }
}

public struct Card: Identifiable, Hashable, Comparable {
    public let id: UUID
    public let rank: Rank
    public let suit: Suit

    public init(id: UUID = UUID(), rank: Rank, suit: Suit) {
        self.id = id
        self.rank = rank
        self.suit = suit
    }

    public var displayText: String {
        "\(rank.label)\(suit.symbol)"
    }

    public static func < (lhs: Card, rhs: Card) -> Bool {
        if lhs.rank.strength == rhs.rank.strength {
            return lhs.suit.rawValue < rhs.suit.rawValue
        }
        return lhs.rank.strength < rhs.rank.strength
    }
}

public enum Suit: Int, CaseIterable, Hashable {
    case spades
    case clubs
    case diamonds
    case hearts

    public var symbol: String {
        switch self {
        case .spades: "♠"
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        }
    }
}

public enum Rank: Int, CaseIterable, Hashable {
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14
    case two = 15

    public var strength: Int { rawValue }

    public var label: String {
        switch self {
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .ten: "10"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        case .ace: "A"
        case .two: "2"
        }
    }
}

public struct Deck {
    public static func shuffled() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in
                Card(rank: rank, suit: suit)
            }
        }
        .shuffled()
    }
}

public struct Combo: Equatable {
    public enum Kind: String {
        case single
        case pair
        case triple
        case straight
        case quad
    }

    public let kind: Kind
    public let cardCount: Int
    public let strength: Int

    public var description: String {
        switch kind {
        case .single: return "Single"
        case .pair: return "Pair"
        case .triple: return "Triple"
        case .straight: return "Straight (\(cardCount) cards)"
        case .quad: return "Four of a kind"
        }
    }

    public init(kind: Kind, cardCount: Int, strength: Int) {
        self.kind = kind
        self.cardCount = cardCount
        self.strength = strength
    }

    public init?(cards: [Card]) {
        let sorted = cards.sorted()
        switch sorted.count {
        case 1:
            self = Combo(kind: .single, cardCount: 1, strength: Combo.rankSuitStrength(for: sorted.last!))
        case 2 where Set(sorted.map(\.rank)).count == 1:
            self = Combo(kind: .pair, cardCount: 2, strength: Combo.rankSuitStrength(for: sorted.last!))
        case 3:
            if Set(sorted.map(\.rank)).count == 1 {
                self = Combo(kind: .triple, cardCount: 3, strength: sorted.last!.rank.strength)
            } else if Combo.isStraight(sorted) {
                self = Combo(kind: .straight, cardCount: 3, strength: sorted.last!.rank.strength)
            } else {
                return nil
            }
        case 4:
            if Set(sorted.map(\.rank)).count == 1 {
                self = Combo(kind: .quad, cardCount: 4, strength: sorted.last!.rank.strength)
            } else if Combo.isStraight(sorted) {
                self = Combo(kind: .straight, cardCount: 4, strength: sorted.last!.rank.strength)
            } else {
                return nil
            }
        default:
            guard Combo.isStraight(sorted) else { return nil }
            self = Combo(kind: .straight, cardCount: sorted.count, strength: sorted.last!.rank.strength)
        }
    }

    private static func rankSuitStrength(for card: Card) -> Int {
        card.rank.strength * 10 + card.suit.rawValue
    }

    private static func isStraight(_ cards: [Card]) -> Bool {
        guard cards.count >= 3 else { return false }
        let sorted = cards.sorted()
        let ranks = sorted.map(\.rank)
        guard !ranks.contains(.two) else { return false }
        for index in 1..<ranks.count where ranks[index].strength != ranks[index - 1].strength + 1 {
            return false
        }
        return Set(ranks).count == cards.count
    }
}

public enum ComboFinder {
    public struct Candidate: Equatable {
        public let cards: [Card]
        public let combo: Combo

        public init(cards: [Card], combo: Combo) {
            self.cards = cards
            self.combo = combo
        }
    }

    public static func validCombos(from hand: [Card]) -> [Candidate] {
        var results: [Candidate] = []

        for card in hand {
            if let combo = Combo(cards: [card]) {
                results.append(Candidate(cards: [card], combo: combo))
            }
        }

        let groups = Dictionary(grouping: hand, by: \.rank)
        for group in groups.values {
            let sorted = group.sorted()
            if sorted.count >= 2, let combo = Combo(cards: Array(sorted.prefix(2))) {
                results.append(Candidate(cards: Array(sorted.prefix(2)), combo: combo))
            }
            if sorted.count >= 3, let combo = Combo(cards: Array(sorted.prefix(3))) {
                results.append(Candidate(cards: Array(sorted.prefix(3)), combo: combo))
            }
            if sorted.count == 4, let combo = Combo(cards: sorted) {
                results.append(Candidate(cards: sorted, combo: combo))
            }
        }

        let uniqueRanks = Array(Set(hand.map(\.rank))).sorted { $0.strength < $1.strength }
        let playableRanks = uniqueRanks.filter { $0 != .two }

        guard !playableRanks.isEmpty else {
            return results
        }

        for start in 0..<playableRanks.count {
            var run: [Rank] = [playableRanks[start]]
            for next in (start + 1)..<playableRanks.count {
                if playableRanks[next].strength == run.last!.strength + 1 {
                    run.append(playableRanks[next])
                    if run.count >= 3 {
                        let cards = run.compactMap { rank in
                            hand.filter { $0.rank == rank }.sorted().first
                        }
                        if let combo = Combo(cards: cards), cards.count == run.count {
                            results.append(Candidate(cards: cards, combo: combo))
                        }
                    }
                } else if playableRanks[next].strength > run.last!.strength + 1 {
                    break
                }
            }
        }

        return results
    }
}


public enum TienLenMoveError: Error, Equatable {
    case message(String)

    public var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

public struct TienLenRoundState: Equatable {
    public var players: [Player]
    public var currentPlayerID: UUID?
    public var currentTrick: Trick?
    public var statusMessage: String
    public var winningPlayerName: String?

    public init(players: [Player] = [], currentPlayerID: UUID? = nil, currentTrick: Trick? = nil, statusMessage: String = "", winningPlayerName: String? = nil) {
        self.players = players
        self.currentPlayerID = currentPlayerID
        self.currentTrick = currentTrick
        self.statusMessage = statusMessage
        self.winningPlayerName = winningPlayerName
    }
}

public final class TienLenEngine {
    public let humanPlayerID: UUID
    private let aiNames: [String]
    public private(set) var state = TienLenRoundState()

    public init(humanPlayerID: UUID = UUID(), aiNames: [String] = ["Lan", "Minh", "Khoa"]) {
        self.humanPlayerID = humanPlayerID
        self.aiNames = aiNames
        startNewRound()
    }

    public func startNewRound() {
        let deck = Deck.shuffled()
        let allPlayerIDs = [humanPlayerID] + aiNames.map { _ in UUID() }
        let names = ["You"] + aiNames

        state.players = zip(allPlayerIDs, names).enumerated().map { index, pair in
            let hand = Array(deck[index * 13..<(index + 1) * 13]).sorted()
            return Player(id: pair.0, name: pair.1, hand: hand)
        }

        let owner = state.players.first(where: { $0.hand.contains(where: { $0.rank == .three && $0.suit == .spades }) })
        state.currentPlayerID = owner?.id
        state.currentTrick = nil
        state.statusMessage = "\(owner?.name ?? "You") leads with the 3♠ holder."
        state.winningPlayerName = nil
        clearPasses()
    }

    public func humanHand() -> [Card] {
        state.players.first(where: { $0.id == humanPlayerID })?.hand ?? []
    }

    public func canPlay(_ cards: [Card], by playerID: UUID) -> Result<Combo, TienLenMoveError> {
        guard !cards.isEmpty else { return .failure(.message("Select at least one card.")) }
        guard let combo = Combo(cards: cards) else { return .failure(.message("That selection is not a valid Tien Len combination.")) }
        guard let player = state.players.first(where: { $0.id == playerID }) else { return .failure(.message("Unknown player.")) }

        for card in cards where !player.hand.contains(card) {
            return .failure(.message("You can only play cards from your hand."))
        }

        if let trick = state.currentTrick {
            if trick.ownerID != playerID {
                guard combo.kind == trick.combo.kind, combo.cardCount == trick.combo.cardCount else {
                    return .failure(.message("You must match the current combination type and size."))
                }
                guard combo.strength > trick.combo.strength else {
                    return .failure(.message("That play does not beat the current trick."))
                }
            }
        } else if player.hand.count == 13 {
            let containsOpeningCard = cards.contains { $0.rank == .three && $0.suit == .spades }
            guard containsOpeningCard else {
                return .failure(.message("The opening play must include the 3♠."))
            }
        }

        return .success(combo)
    }

    @discardableResult
    public func play(_ cards: [Card], by playerID: UUID) -> Result<Void, TienLenMoveError> {
        switch canPlay(cards, by: playerID) {
        case .failure(let error):
            state.statusMessage = error.description
            return .failure(error)
        case .success(let combo):
            guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }) else {
                let message = "Unknown player."
                state.statusMessage = message
                return .failure(.message(message))
            }

            state.players[playerIndex].hand.removeAll { card in cards.contains(card) }
            state.players[playerIndex].hasPassed = false
            state.currentTrick = Trick(ownerID: playerID, ownerName: state.players[playerIndex].name, cards: cards.sorted(), combo: combo)
            state.statusMessage = "\(state.players[playerIndex].name) played \(cards.sorted().map(\.displayText).joined(separator: " "))."

            if state.players[playerIndex].hand.isEmpty {
                state.winningPlayerName = state.players[playerIndex].name
                return .success(())
            }

            advanceTurn(after: playerID)
            return .success(())
        }
    }

    public func pass(playerID: UUID) -> Result<Void, TienLenMoveError> {
        guard state.currentTrick != nil else {
            let message = "You cannot pass on a clear table."
            state.statusMessage = message
            return .failure(.message(message))
        }
        guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }) else {
            let message = "Unknown player."
            state.statusMessage = message
            return .failure(.message(message))
        }

        state.players[playerIndex].hasPassed = true
        state.statusMessage = "\(state.players[playerIndex].name) passed."

        let activeOpponents = state.players.filter { $0.id != state.currentTrick?.ownerID && !$0.hasPassed }
        if activeOpponents.isEmpty, let ownerID = state.currentTrick?.ownerID {
            clearPasses()
            state.currentPlayerID = ownerID
            state.currentTrick = nil
            state.statusMessage = "Everyone else passed. Table resets for \(state.players.first(where: { $0.id == ownerID })?.name ?? "the lead player")."
            return .success(())
        }

        advanceTurn(after: playerID)
        return .success(())
    }

    public func bestMove(for player: Player) -> [Card]? {
        let candidates = ComboFinder.validCombos(from: player.hand.sorted())
            .sorted {
                if $0.combo.kind == $1.combo.kind {
                    return $0.combo.strength < $1.combo.strength
                }
                return $0.cards.count < $1.cards.count
            }

        if let trick = state.currentTrick {
            return candidates.first(where: {
                $0.combo.kind == trick.combo.kind &&
                $0.combo.cardCount == trick.combo.cardCount &&
                $0.combo.strength > trick.combo.strength
            })?.cards
        }

        if player.hand.count == 13 {
            return candidates.first(where: { $0.cards.contains(where: { $0.rank == .three && $0.suit == .spades }) })?.cards
        }

        return candidates.first?.cards
    }

    public func stepAIUntilHumanTurn() {
        while let currentPlayerID = state.currentPlayerID,
              currentPlayerID != humanPlayerID,
              state.winningPlayerName == nil,
              let index = state.players.firstIndex(where: { $0.id == currentPlayerID }) {
            let aiPlayer = state.players[index]
            if let move = bestMove(for: aiPlayer) {
                _ = play(move, by: aiPlayer.id)
            } else {
                _ = pass(playerID: aiPlayer.id)
            }
        }
    }

    private func clearPasses() {
        for index in state.players.indices {
            state.players[index].hasPassed = false
        }
    }

    private func advanceTurn(after playerID: UUID) {
        guard let currentIndex = state.players.firstIndex(where: { $0.id == playerID }) else { return }
        for offset in 1...state.players.count {
            let nextIndex = (currentIndex + offset) % state.players.count
            let nextPlayer = state.players[nextIndex]
            if !nextPlayer.hasPassed || state.currentTrick == nil {
                state.currentPlayerID = nextPlayer.id
                return
            }
        }
    }
}
