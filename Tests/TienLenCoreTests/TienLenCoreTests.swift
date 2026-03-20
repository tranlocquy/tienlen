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

    func testComboFinderProducesPairAndStraight() {
        let hand = [
            Card(rank: .three, suit: .spades),
            Card(rank: .three, suit: .clubs),
            Card(rank: .four, suit: .diamonds),
            Card(rank: .five, suit: .hearts),
            Card(rank: .six, suit: .spades)
        ]

        let candidates = ComboFinder.validCombos(from: hand)
        XCTAssertTrue(candidates.contains { $0.combo.kind == .pair })
        XCTAssertTrue(candidates.contains { $0.combo.kind == .straight && $0.combo.cardCount == 4 })
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
}
