# Tien Len iOS Prototype

A lightweight SwiftUI prototype of the Vietnamese climbing card game **Tien Len**.

## What is included
- A playable local four-player round with one human player and three AI opponents.
- Core rule validation for singles, pairs, triples, four of a kind, and straights.
- Turn rotation, pass/reset flow, and opening-card enforcement using the 3♠.
- A small `Swift Package` target (`TienLenCore`) so the rule engine can be tested with `swift test` in CLI environments.

## Prototype limitations
- This version intentionally keeps the rules approachable and does **not** implement advanced “cut” interactions such as bombing twos.
- AI players use a simple lowest-valid-play strategy.
- App icon assets are placeholders.

## Opening in Xcode
Open `TienLenApp.xcodeproj` in Xcode 15 or newer, then run the `TienLenApp` scheme on an iPhone or iPad simulator.
