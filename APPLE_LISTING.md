# Apple Listing — Checkers (SEPARATE game, NOT a bundle)

- Checklist #: 4
- Slug / Repo: checkers / game-checkers
- Source: https://github.com/wjia-n/game-checkers (public, as of 3 Nov 2026; Android version untouched, this copy is Apple-ready only)
- Free / Paid: FREE — App Store price: Free
- Apple Bundle ID (PROVISIONAL, do not finalise for games 56-100): com.gameswajiha.checkers
  - Later change: if Play Store re-check says NOT FOUND, change to com.games.board.checkers before App Store Connect record creation.
  - Play Store check status (from PLAYSTORE_CHECK.md): FOUND for first 5
- Android Bundle ID in repo: com.gameswajiha.checkers (unchanged, Android untouched)
- iOS folder originally present: NO — scaffold added from Flutter 3.47.6 flutter create, bundle ID set to provisional, in this copy only
- Apple name (SEO, meaningful, to check availability in App Store Connect): Checkers – Classic Board Game
  - If this exact name is taken on Apple, add a unique meaningful word (from the game's own style/theme, never nonsense) and record the final name here before submission. Do not use a Play Store screenshot title blindly.
- Apple IAP (meaningful only): checkerspro — Pro unlock — $4.99
  - Tips coffee $0.99 / chocolate $1.99 are Android only, NOT Apple purchases.
- App Icon: OK 1024x1024 from checkers_logo.webp (1600, 1600) — file APPLE_ICON_1024.png in this folder (1024x1024, RGB, no transparency)
- Screenshots: NOT invented. Required for submission: iPhone 6.9-inch 1290x2796, iPhone 6.5-inch 1284x2778, iPhone 5.5-inch 1242x2208, iPad 13-inch 2064x2752 — minimum 1 per size, up to 10. Capture from a real TestFlight / simulator build of this copy, do not use Play Store screenshots as Apple screenshots without re-checking size and content.
- Privacy: PRIVACY_POLICY.md in this folder (no data collected, on-device only, to be hosted on GitHub per Wajiha option B). Privacy link in App Store Connect: TO BE FILLED BY WAJIHA AT SUBMIT TIME (GitHub link, not published yet). Contacts: LEFT BLANK for Wajiha, as instructed.
- Age / Data: Draft label — Data Not Collected, general audiences, no ads in Apple version, no external payment links. To confirm at submission.
- GitHub Actions workflow: .github/workflows/ios-build.yml in this folder (macOS runner, Flutter, build ios --release --no-codesign for now — signing/IPA blocked until Apple sign-in, see below).
- Submission: NOT submitted. Wajiha submits herself in App Store Connect. No store settings changed.

## Description (DRAFT, unique wording per game, check against actual gameplay before submission)
A clean, modern take on Checkers, built for players who want the real rules and a fair match every time.
Checkers - 100% free fun game.
In this game you play Checkers with the rules as built into the game itself, on your iPhone and iPad. The Apple version is free at Free on the App Store, with an Apple in-app purchase for Pro unlock (checkerspro, $4.99) where the game offers it. No tips are sold on Apple, because every Apple purchase must unlock something real.
The game is designed to be easy to pick up and hard to put down, without rushing you.
This listing description is a DRAFT for submission. It was written from the game's repo description and title, not from invented gameplay screenshots, and must be checked against the actual game before submission. No restricted or misleading claims are made: no claim that the game is free when it is paid, no trademark claim, and no feature is promised that is not in the game itself.

