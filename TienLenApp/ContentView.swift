import SwiftUI

struct ContentView: View {
    @StateObject private var game = TienLenGame()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.09, green: 0.39, blue: 0.22), Color(red: 0.03, green: 0.18, blue: 0.09)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        modePicker
                        playerOverview
                        currentTrickPanel
                        handSection
                        actionSection
                        ruleNotes
                    }
                    .padding()
                }
            }
            .navigationTitle("Tien Len")
        }
        .alert("Round Finished", isPresented: $game.showingRoundResult) {
            Button("New Round") {
                game.startNewRound()
            }
        } message: {
            Text(game.roundSummary)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.mode == .singlePlayer ? "Vietnamese climbing card game" : "Local multiplayer pass-and-play")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
            Text(
                game.mode == .singlePlayer
                ? "Play against three AI opponents, climb by type and strength, and use bombs to crack powerful twos."
                : "Four players share one device. Finish a turn, pass the phone, and reveal the next hand when the next player is ready."
            )
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mode")
                .font(.headline)
                .foregroundStyle(.white)

            Picker("Mode", selection: Binding(
                get: { game.mode },
                set: { game.setMode($0) }
            )) {
                ForEach(TienLenGameMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(game.mode.description)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var playerOverview: some View {
        VStack(spacing: 12) {
            ForEach(game.players) { player in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(player.name)
                                .font(.headline)
                            if player.id == game.currentPlayerID {
                                Text("TURN")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.yellow.opacity(0.85), in: Capsule())
                            }
                            if player.id == game.visiblePlayerID {
                                Text("VISIBLE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.8), in: Capsule())
                            }
                            if player.hasPassed {
                                Text("PASSED")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.white.opacity(0.15), in: Capsule())
                            }
                        }
                        Text(cardsText(for: player))
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                    }
                    Spacer()
                    Text("\(player.hand.count)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                .foregroundStyle(.white)
                .padding()
                .background(player.id == game.currentPlayerID ? .white.opacity(0.18) : .black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func cardsText(for player: Player) -> String {
        if player.id == game.visiblePlayerID {
            return player.hand.map(\.displayText).joined(separator: "  ")
        }
        return "Cards left: \(player.hand.count)"
    }

    private var currentTrickPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Trick")
                .font(.headline)
                .foregroundStyle(.white)

            if let trick = game.currentTrick {
                Text("\(trick.ownerName) played \(trick.cards.map(\.displayText).joined(separator: " "))")
                    .foregroundStyle(.white.opacity(0.9))
                Text(trick.combo.description)
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            } else {
                Text("Table is clear. Lead any valid combination.")
                    .foregroundStyle(.white.opacity(0.8))
            }

            if !game.statusMessage.isEmpty {
                Text(game.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var handSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.handTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(game.handSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }

            if game.isAwaitingTurnReveal {
                VStack(spacing: 12) {
                    Text("Pass the device to \(game.currentPlayerName).")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("When ready, reveal only this player's cards.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    Button("Reveal Hand") {
                        game.revealCurrentTurn()
                    }
                    .buttonStyle(ActionButtonStyle(background: .yellow, foreground: .black))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(game.visibleHand) { card in
                        Button {
                            game.toggleSelection(for: card)
                        } label: {
                            VStack(spacing: 8) {
                                Text(card.rank.label)
                                    .font(.title3.bold())
                                Text(card.suit.symbol)
                                    .font(.title2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .foregroundStyle(card.suit.color)
                            .background(game.isSelected(card) ? Color.white : Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(game.isSelected(card) ? Color.yellow : Color.clear, lineWidth: 3)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Play Selected") {
                    game.playSelectedCards()
                }
                .buttonStyle(ActionButtonStyle(background: .yellow, foreground: .black))
                .disabled(game.isAwaitingTurnReveal)

                Button("Pass") {
                    game.humanPass()
                }
                .buttonStyle(ActionButtonStyle(background: .white.opacity(0.15), foreground: .white))
                .disabled(game.isAwaitingTurnReveal)

                Button("New Round") {
                    game.startNewRound()
                }
                .buttonStyle(ActionButtonStyle(background: .black.opacity(0.25), foreground: .white))
            }

            if !game.selectedCards.isEmpty {
                Text("Selected: \(game.selectedCards.sorted().map(\.displayText).joined(separator: " "))")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var ruleNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wikipedia rule highlights")
                .font(.headline)
                .foregroundStyle(.white)
            Text("• Supports singles, pairs, triples, quads, straights, and double sequences of 3+ pairs.\n• Twos rank highest and cannot be used inside straights or double sequences here.\n• A single 2 can be bombed by any quad or a 3+ pair double sequence.\n• A pair of 2s can be bombed by any quad or a 4+ pair double sequence.\n• A triple of 2s can be bombed by a 5+ pair double sequence.\n• The opening leader must include the 3♠, and the table resets after everyone else passes.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ActionButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(background.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(foreground)
    }
}

#Preview {
    ContentView()
}
