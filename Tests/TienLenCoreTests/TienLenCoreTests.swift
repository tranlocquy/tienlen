import XCTest
@testable import TienLenCore

final class TienLenCoreTests: XCTestCase {
    func testStraightValidationRejectsTwo() {
        let cards = [
            Card(rank: .queen, suit: .spades),
            Card(rank: .king, suit: .clubs),
            Card(rank: .ace, suit: .diamonds),
            Card(rank: .two, suit: .hearts)
        ]

        XCTAssertNil(Combo(cards: cards))
    }

    func testQuadValidation() {
        let cards = [
            Card(rank: .nine, suit: .spades),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .nine, suit: .diamonds),
            Card(rank: .nine, suit: .hearts)
        ]

        let combo = Combo(cards: cards)
        XCTAssertEqual(combo?.kind, .quad)
        XCTAssertEqual(combo?.cardCount, 4)
    }

    func testDoubleSequenceValidation() {
        let cards = [
            Card(rank: .five, suit: .spades),
            Card(rank: .five, suit: .clubs),
            Card(rank: .six, suit: .diamonds),
            Card(rank: .six, suit: .hearts),
            Card(rank: .seven, suit: .spades),
            Card(rank: .seven, suit: .clubs)
        ]

        let combo = Combo(cards: cards)
        XCTAssertEqual(combo?.kind, .doubleSequence)
        XCTAssertEqual(combo?.cardCount, 6)
    }

    func testComboFinderProducesPairStraightAndDoubleSequence() {
        let hand = [
            Card(rank: .three, suit: .spades),
            Card(rank: .three, suit: .clubs),
            Card(rank: .four, suit: .diamonds),
            Card(rank: .four, suit: .hearts),
            Card(rank: .five, suit: .hearts),
            Card(rank: .five, suit: .spades),
            Card(rank: .six, suit: .clubs)
        ]

        let candidates = ComboFinder.validCombos(from: hand)
        XCTAssertTrue(candidates.contains { $0.combo.kind == .pair })
        XCTAssertTrue(candidates.contains { $0.combo.kind == .straight && $0.combo.cardCount == 4 })
        XCTAssertTrue(candidates.contains { $0.combo.kind == .doubleSequence && $0.combo.cardCount == 6 })
    }

    func testPlayerNamesInitializerSetsHumanPlayerIndex() {
        let engine = TienLenEngine(playerNames: ["Alpha", "Bravo", "Charlie", "Delta"], humanPlayerIndex: 2)

        XCTAssertEqual(engine.state.players.map(\.name), ["Alpha", "Bravo", "Charlie", "Delta"])
        XCTAssertEqual(engine.humanPlayerID, engine.state.players[2].id)
    }

    func testOpeningPlayMustContainThreeOfSpades() {
        let humanID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let engine = TienLenEngine(humanPlayerID: humanID, aiNames: ["A", "B", "C"])
        let opener = engine.state.players.first(where: { $0.id == engine.state.currentPlayerID })!
        let illegalOpeningCard = opener.hand.first(where: { !($0.rank == .three && $0.suit == .spades) })!

        let result = engine.canPlay([illegalOpeningCard], by: opener.id)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .message("The opening play must include the 3♠."))
        } else {
            XCTFail("Expected opening play validation to fail")
        }
    }

    func testQuadCanBombSingleTwo() {
        let humanID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
        let engine = TienLenEngine(humanPlayerID: humanID, aiNames: ["A", "B", "C"])
        let challengerID = engine.state.players[0].id
        let ownerID = engine.state.players[1].id

        var customState = engine.state
        customState.players = [
            Player(id: challengerID, name: "You", hand: [
                Card(rank: .three, suit: .spades),
                Card(rank: .nine, suit: .spades),
                Card(rank: .nine, suit: .clubs),
                Card(rank: .nine, suit: .diamonds),
                Card(rank: .nine, suit: .hearts)
            ]),
            Player(id: ownerID, name: "A", hand: [Card(rank: .two, suit: .clubs)]),
            Player(id: engine.state.players[2].id, name: "B", hand: [Card(rank: .four, suit: .spades)]),
            Player(id: engine.state.players[3].id, name: "C", hand: [Card(rank: .five, suit: .spades)])
        ]
        customState.currentPlayerID = challengerID
        customState.currentTrick = Trick(
            ownerID: ownerID,
            ownerName: "A",
            cards: [Card(rank: .two, suit: .clubs)],
            combo: Combo(cards: [Card(rank: .two, suit: .clubs)])!
        )
        engine.setStateForTesting(customState)

        let bomb = engine.state.players[0].hand.filter { $0.rank == .nine }
        XCTAssertEqual(engine.canPlay(bomb, by: challengerID), .success(Combo(cards: bomb)!))
    }

    func testDoubleSequenceCanBombPairOfTwos() {
        let humanID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let engine = TienLenEngine(humanPlayerID: humanID, aiNames: ["A", "B", "C"])
        let challengerID = engine.state.players[0].id
        let ownerID = engine.state.players[1].id

        let doubleSequence = [
            Card(rank: .four, suit: .spades), Card(rank: .four, suit: .clubs),
            Card(rank: .five, suit: .diamonds), Card(rank: .five, suit: .hearts),
            Card(rank: .six, suit: .spades), Card(rank: .six, suit: .clubs),
            Card(rank: .seven, suit: .diamonds), Card(rank: .seven, suit: .hearts)
        ]
        let pairOfTwos = [Card(rank: .two, suit: .clubs), Card(rank: .two, suit: .hearts)]

        var customState = engine.state
        customState.players = [
            Player(id: challengerID, name: "You", hand: doubleSequence + [Card(rank: .three, suit: .spades)]),
            Player(id: ownerID, name: "A", hand: pairOfTwos),
            Player(id: engine.state.players[2].id, name: "B", hand: [Card(rank: .four, suit: .spades)]),
            Player(id: engine.state.players[3].id, name: "C", hand: [Card(rank: .five, suit: .spades)])
        ]
        customState.currentPlayerID = challengerID
        customState.currentTrick = Trick(ownerID: ownerID, ownerName: "A", cards: pairOfTwos, combo: Combo(cards: pairOfTwos)!)
        engine.setStateForTesting(customState)

        XCTAssertEqual(engine.canPlay(doubleSequence, by: challengerID), .success(Combo(cards: doubleSequence)!))
    }
}
