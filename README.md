# Tien Len iOS Prototype

A lightweight SwiftUI prototype of the Vietnamese climbing card game **Tien Len**.

## Wikipedia-based rules included
This prototype now covers the main rule structure described on Wikipedia's **Tiến lên** page:
- Four players with 13 cards each from a standard 52-card deck.
- Rank order from high to low: `2 A K Q J 10 9 8 7 6 5 4 3`.
- Suit order from high to low: `♥ ♦ ♣ ♠`.
- Valid leads and follow-up plays for singles, pairs, triples, four of a kind, straights, and double sequences of 3+ consecutive pairs.
- Pass/reset flow where players who pass are locked out until the pile clears.
- Bomb/slam interactions against twos:
  - a single 2 can be beaten by a four of a kind or a double sequence of 3+ pairs;
  - a pair of 2s can be beaten by a four of a kind or a double sequence of 4+ pairs;
  - a triple of 2s can be beaten by a double sequence of 5+ pairs.
- The first hand still requires the opening leader to include the `3♠`, matching the common rule variant already used by the app.
- If a player is dealt all four 2s, the round ends immediately with an automatic win.

## What is included
- A playable local four-player round with one human player and three AI opponents.
- Core rule validation shared by the SwiftUI app and the `TienLenCore` Swift package.
- Turn rotation, pass/reset flow, opening-card enforcement using the 3♠, and Wikipedia-style bomb handling for twos.
- A small `Swift Package` target (`TienLenCore`) so the rule engine can be tested with `swift test` in CLI environments.

## Prototype limitations
- The AI still uses a simple lowest-valid-play strategy and does not reason strategically about preserving bombs.
- Local multiplayer, scoring across rounds, and trading variants are not implemented.
- App icon assets are placeholders.

## Opening in Xcode
Open `TienLenApp.xcodeproj` in Xcode 15 or newer, then run the `TienLenApp` scheme on an iPhone or iPad simulator.
