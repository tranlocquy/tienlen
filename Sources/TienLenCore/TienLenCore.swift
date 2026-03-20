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
        case doubleSequence
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
        case .doubleSequence: return "Double sequence (\(cardCount / 2) pairs)"
        }
    }

    public var isBomb: Bool {
        switch kind {
        case .quad:
            return true
        case .doubleSequence:
            return cardCount >= 6
        default:
            return false
        }
    }

    public var bombPairCount: Int {
        guard kind == .doubleSequence else { return 0 }
        return cardCount / 2
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
            guard let card = sorted.last else { return nil }
            self = Combo(kind: .single, cardCount: 1, strength: Combo.rankSuitStrength(for: card))
        case 2 where Set(sorted.map(\.rank)).count == 1:
            guard let card = sorted.last else { return nil }
            self = Combo(kind: .pair, cardCount: 2, strength: Combo.rankSuitStrength(for: card))
        case 3:
            if Set(sorted.map(\.rank)).count == 1 {
                self = Combo(kind: .triple, cardCount: 3, strength: sorted.last!.rank.strength)
            } else if Combo.isStraight(sorted) {
                self = Combo(kind: .straight, cardCount: 3, strength: Combo.rankSuitStrength(for: sorted.last!))
            } else {
                return nil
            }
        case 4:
            if Set(sorted.map(\.rank)).count == 1 {
                self = Combo(kind: .quad, cardCount: 4, strength: sorted.last!.rank.strength)
            } else if Combo.isStraight(sorted) {
                self = Combo(kind: .straight, cardCount: 4, strength: Combo.rankSuitStrength(for: sorted.last!))
            } else {
                return nil
            }
        default:
            if Combo.isDoubleSequence(sorted) {
                self = Combo(kind: .doubleSequence, cardCount: sorted.count, strength: Combo.rankSuitStrength(for: sorted.last!))
            } else if Combo.isStraight(sorted) {
                self = Combo(kind: .straight, cardCount: sorted.count, strength: Combo.rankSuitStrength(for: sorted.last!))
            } else {
                return nil
            }
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

    private static func isDoubleSequence(_ cards: [Card]) -> Bool {
        guard cards.count >= 6, cards.count.isMultiple(of: 2) else { return false }
        let sorted = cards.sorted()
        let grouped = Dictionary(grouping: sorted, by: \.rank)
        let ranks = grouped.keys.sorted { $0.strength < $1.strength }

        guard ranks.count * 2 == cards.count else { return false }
        guard !ranks.contains(.two) else { return false }
        guard grouped.values.allSatisfy({ $0.count == 2 }) else { return false }

        for index in 1..<ranks.count where ranks[index].strength != ranks[index - 1].strength + 1 {
            return false
        }

        return true
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

        if !playableRanks.isEmpty {
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
        }

        let pairableRanks = playableRanks.filter { (groups[$0]?.count ?? 0) >= 2 }
        if !pairableRanks.isEmpty {
            for start in 0..<pairableRanks.count {
                var run: [Rank] = [pairableRanks[start]]
                for next in (start + 1)..<pairableRanks.count {
                    if pairableRanks[next].strength == run.last!.strength + 1 {
                        run.append(pairableRanks[next])
                        if run.count >= 3 {
                            let cards = run.flatMap { rank in
                                Array(groups[rank]!.sorted().prefix(2))
                            }
                            if let combo = Combo(cards: cards) {
                                results.append(Candidate(cards: cards, combo: combo))
                            }
                        }
                    } else if pairableRanks[next].strength > run.last!.strength + 1 {
                        break
                    }
                }
            }
        }

        var deduped: [Candidate] = []
        var seen = Set<String>()
        for candidate in results {
            let key = candidate.cards.sorted().map { "\($0.rank.rawValue)-\($0.suit.rawValue)" }.joined(separator: "|")
            if seen.insert(key).inserted {
                deduped.append(candidate)
            }
        }

        return deduped
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
    private let playerRoster: [(id: UUID, name: String)]
    private var previousRoundWinnerID: UUID?
    public private(set) var state = TienLenRoundState()

    public init(playerNames: [String] = ["You", "Lan", "Minh", "Khoa"], humanPlayerIndex: Int = 0) {
        precondition(!playerNames.isEmpty, "TienLenEngine requires at least one player.")
        precondition(playerNames.indices.contains(humanPlayerIndex), "humanPlayerIndex must reference an existing player.")

        let roster = playerNames.map { (UUID(), $0) }
        self.humanPlayerID = roster[humanPlayerIndex].0
        self.playerRoster = roster
        startNewRound()
    }

    public convenience init(humanPlayerID: UUID = UUID(), aiNames: [String] = ["Lan", "Minh", "Khoa"]) {
        let playerNames = ["You"] + aiNames
        self.init(playerNames: playerNames, humanPlayerIndex: 0)
    }

    public func startNewRound() {
        let deck = Deck.shuffled()

        state.players = playerRoster.enumerated().map { index, pair in
            let hand = Array(deck[index * 13..<(index + 1) * 13]).sorted()
            return Player(id: pair.id, name: pair.name, hand: hand)
        }

        if let winnerID = previousRoundWinnerID,
           state.players.contains(where: { $0.id == winnerID }) {
            state.currentPlayerID = winnerID
            state.statusMessage = "\(state.players.first(where: { $0.id == winnerID })?.name ?? "Previous winner") leads this hand."
        } else {
            let owner = state.players.first(where: { $0.hand.contains(where: { $0.rank == .three && $0.suit == .spades }) })
            state.currentPlayerID = owner?.id
            state.statusMessage = "\(owner?.name ?? "You") leads with the 3♠ holder."
        }

        state.currentTrick = nil
        state.winningPlayerName = nil
        clearPasses()

        if let playerIndex = state.players.firstIndex(where: { hasAutomaticWin(for: $0) }) {
            state.winningPlayerName = state.players[playerIndex].name
            previousRoundWinnerID = state.players[playerIndex].id
            state.currentPlayerID = nil
            state.statusMessage = "\(state.players[playerIndex].name) was dealt all four 2s and wins automatically."
        }
    }

    public func humanHand() -> [Card] {
        state.players.first(where: { $0.id == humanPlayerID })?.hand ?? []
    }

    public func canPlay(_ cards: [Card], by playerID: UUID) -> Result<Combo, TienLenMoveError> {
        guard !cards.isEmpty else { return .failure(.message("Select at least one card.")) }
        guard let combo = Combo(cards: cards) else { return .failure(.message("That selection is not a valid Tien Len combination.")) }
        guard let player = state.players.first(where: { $0.id == playerID }) else { return .failure(.message("Unknown player.")) }
        guard state.currentPlayerID == playerID else { return .failure(.message("It is not your turn.")) }

        for card in cards where !player.hand.contains(card) {
            return .failure(.message("You can only play cards from your hand."))
        }

        if let trick = state.currentTrick {
            if trick.ownerID != playerID {
                if canBeatTwoWithBomb(challenger: combo, current: trick.combo) {
                    return .success(combo)
                }

                guard combo.kind == trick.combo.kind, combo.cardCount == trick.combo.cardCount else {
                    return .failure(.message("You must match the current combination type and size."))
                }
                guard combo.strength > trick.combo.strength else {
                    return .failure(.message("That play does not beat the current trick."))
                }
            }
        } else if previousRoundWinnerID == nil, player.hand.count == 13 {
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

            let sortedCards = cards.sorted()
            state.players[playerIndex].hand.removeAll { card in sortedCards.contains(card) }
            state.players[playerIndex].hasPassed = false
            state.currentTrick = Trick(ownerID: playerID, ownerName: state.players[playerIndex].name, cards: sortedCards, combo: combo)
            state.statusMessage = "\(state.players[playerIndex].name) played \(sortedCards.map(\.displayText).joined(separator: " "))."

            if state.players[playerIndex].hand.isEmpty {
                state.winningPlayerName = state.players[playerIndex].name
                previousRoundWinnerID = state.players[playerIndex].id
                state.currentPlayerID = nil
                return .success(())
            }

            advanceTurn(after: playerID)
            return .success(())
        }
    }

    public func pass(playerID: UUID) -> Result<Void, TienLenMoveError> {
        guard state.currentPlayerID == playerID else {
            let message = "It is not your turn."
            state.statusMessage = message
            return .failure(.message(message))
        }
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

        let activeOpponents = state.players.filter { $0.id != state.currentTrick?.ownerID && !$0.hasPassed && !$0.hand.isEmpty }
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
                    if $0.combo.cardCount == $1.combo.cardCount {
                        return $0.combo.strength < $1.combo.strength
                    }
                    return $0.combo.cardCount < $1.combo.cardCount
                }
                return comboPriority($0.combo) < comboPriority($1.combo)
            }

        if let trick = state.currentTrick {
            if let exactMatch = candidates.first(where: {
                $0.combo.kind == trick.combo.kind &&
                $0.combo.cardCount == trick.combo.cardCount &&
                $0.combo.strength > trick.combo.strength
            }) {
                return exactMatch.cards
            }

            return candidates.first(where: { canBeatTwoWithBomb(challenger: $0.combo, current: trick.combo) })?.cards
        }

        if previousRoundWinnerID == nil, player.hand.count == 13 {
            return candidates.first(where: { $0.cards.contains(where: { $0.rank == .three && $0.suit == .spades }) })?.cards
        }

        return candidates.first?.cards
    }

    func setStateForTesting(_ state: TienLenRoundState) {
        self.state = state
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

    private func hasAutomaticWin(for player: Player) -> Bool {
        Set(player.hand.filter { $0.rank == .two }.map(\.suit)).count == Suit.allCases.count
    }

    private func canBeatTwoWithBomb(challenger: Combo, current: Combo) -> Bool {
        switch current.kind {
        case .single:
            return current.cardCount == 1 && current.strength / 10 == Rank.two.strength &&
                (challenger.kind == .quad || (challenger.kind == .doubleSequence && challenger.bombPairCount >= 3))
        case .pair:
            return current.cardCount == 2 && current.strength / 10 == Rank.two.strength &&
                (challenger.kind == .quad || (challenger.kind == .doubleSequence && challenger.bombPairCount >= 4))
        case .triple:
            return current.cardCount == 3 && current.strength == Rank.two.strength && challenger.kind == .doubleSequence && challenger.bombPairCount >= 5
        default:
            return false
        }
    }

    private func comboPriority(_ combo: Combo) -> Int {
        switch combo.kind {
        case .single: return 0
        case .pair: return 1
        case .triple: return 2
        case .straight: return 3
        case .doubleSequence: return 4
        case .quad: return 5
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
            if nextPlayer.hand.isEmpty {
                continue
            }
            if !nextPlayer.hasPassed || state.currentTrick == nil {
                state.currentPlayerID = nextPlayer.id
                return
            }
        }
        state.currentPlayerID = nil
    }
}
