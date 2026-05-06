# Word Crush — Turkish Word Puzzle Game

A mobile word puzzle game built with Flutter for iOS, developed as a Kocaeli University Software Laboratory II project. Players form words by swiping across adjacent letters on a grid, earning points through combos, special power tiles, and strategic joker usage.

---

## Features

### Core Gameplay
- **8-directional letter selection** — swipe horizontally, vertically, or diagonally to chain letters
- **Turkish dictionary validation** — 59,000+ word database loaded into a Trie for O(m) lookup
- **Gravity engine** — matched letters explode, tiles above fall down, new letters fill from the top
- **Three difficulty levels** — Easy (10×10, 25 moves), Medium (8×8, 20 moves), Hard (6×6, 15 moves)
- **Solvability guarantee** — a background solver (Isolate + Trie DFS) scans after every move and auto-shuffles if no words remain

### Combo System
- Every valid word is scanned for contiguous sub-words (3+ letters)
- Each sub-word found awards its own letter-score points on top of the main word
- Example: **KALEM** → KALEM + KAL + KALE + ALEM = 4 scoring entries

### Special Power Tiles
Words of 4+ letters create a power tile on the last selected cell:

| Word Length | Power | Effect |
|---|---|---|
| 4 letters | Row Clear | Destroys the entire row |
| 5 letters | Area Blast | Destroys all 8 surrounding cells |
| 6 letters | Column Clear | Destroys the entire column |
| 7+ letters | Mega Blast | Destroys all cells within a 2-tile radius |

Power tiles chain-react — a power tile inside a blast radius fires its own effect.

### Joker System
Six jokers are purchasable from the in-game market with gold:

| Joker | Price | Effect |
|---|---|---|
| Fish | 100 | Destroys 3 randomly selected letters (previewed in blue before confirm) |
| Lollipop | 75 | Tap any single cell to remove it |
| Swap | 125 | Tap two adjacent cells to swap their letters |
| Wheel | 200 | Destroys the entire row + column of the tapped cell |
| Shuffle | 300 | Randomly rearranges all letters on the grid |
| Party | 400 | Clears every cell and refills the entire grid with new letters |

### Audio
- Background music with loop playback, toggleable at any time
- Per-action sound effects: letter selection, valid/invalid word, combos, power activations, game over
- Individual sound for each joker type (select + activation)

### Persistence
- Username, gold balance and game history stored locally via ObjectBox (no internet required)
- Session resumes seamlessly — no re-login after app restart

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ≥ 3.0) |
| State Management | Riverpod 2.4 (`StateNotifier`) |
| Local Database | ObjectBox 5.3.1 |
| Navigation | GoRouter 14.x |
| Animations | Lottie 3.x + Flutter built-in |
| Audio | audioplayers 6.x |
| Word Lookup | Custom Trie (prefix tree) |

---

## Architecture

The project follows a strict layered architecture:

```
┌─────────────────────────────────────────┐
│             UI Layer                    │
│   Screens / Widgets / Animations        │
├─────────────────────────────────────────┤
│           Logic Layer                   │
│  Riverpod Providers  │  Algorithms      │
│  GameProvider        │  Trie            │
│  GridProvider        │  GridSolver      │
│  ScoreProvider       │  GravityEngine   │
│  JokerProvider       │  GridGenerator   │
│  AudioProvider       │  ComboEngine     │
│  MarketProvider      │  PowerExecutor   │
│  PlayerProvider      │  JokerExecutor   │
├─────────────────────────────────────────┤
│            Data Layer                   │
│  ObjectBox (disk)  │  Trie (RAM)        │
│  PlayerProfile     │  59k Turkish words │
│  GameRecord        │                    │
│  JokerInventory    │                    │
└─────────────────────────────────────────┘
```

**Key design decisions:**
- The Trie is loaded once from `assets/data/turkish_words.txt` on splash and kept in RAM — all word lookups are O(m) with no disk I/O during gameplay
- `GridSolver` runs in a Flutter `Isolate` via `compute()` so solvability checks never block the UI thread
- Audio uses a per-SoundType pool of 3 players to prevent race conditions when the same sound fires in rapid succession

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart       # Grid sizes, move limits, gold prices
│   │   ├── letter_scores.dart       # Scrabble-style scores for 29 Turkish letters
│   │   └── letter_frequencies.dart  # Weighted letter pool for grid generation
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── char_normalizer.dart     # Turkish character normalization (ı→I, i→İ)
│
├── data/
│   ├── models/
│   │   ├── cell.dart                # Grid cell (row, col, letter, powerType)
│   │   ├── grid_model.dart          # 2D grid wrapper with helpers
│   │   ├── player_profile.dart      # @Entity: username, goldBalance
│   │   ├── game_record.dart         # @Entity: score, words, duration, date
│   │   └── joker_inventory.dart     # @Entity: jokerType, quantity
│   └── services/
│       ├── objectbox_service.dart   # Singleton store initialization
│       └── trie_service.dart        # Trie insert / search / hasPrefix
│
├── logic/
│   ├── algorithms/
│   │   ├── grid_generator.dart      # Frequency-based random letter generation
│   │   ├── grid_solver.dart         # DFS + Trie pruning word finder
│   │   ├── grid_solver_isolate.dart # Isolate entry point for compute()
│   │   └── gravity_engine.dart      # Remove cells → drop → refill
│   ├── scoring/
│   │   ├── score_calculator.dart    # Letter-score summation
│   │   └── combo_engine.dart        # Contiguous sub-word detection
│   ├── powers/
│   │   ├── power_type.dart          # PowerType enum
│   │   ├── power_executor.dart      # Blast radius calculation
│   │   └── joker_executor.dart      # All 6 joker effects + pickFishCells
│   └── providers/
│       ├── game_provider.dart       # Move counter, game state, endGame
│       ├── grid_provider.dart       # Grid matrix, selection, word processing
│       ├── score_provider.dart      # Live score, combo tracking
│       ├── player_provider.dart     # Profile load/save, gold spend
│       ├── joker_provider.dart      # Inventory load/add/spend
│       ├── market_provider.dart     # Purchase flow
│       ├── audio_provider.dart      # Sound pool, BGM toggle
│       └── trie_provider.dart       # FutureProvider wrapping Trie load
│
├── ui/
│   ├── screens/
│   │   ├── splash_screen.dart       # Asset loading, profile check, BGM start
│   │   ├── login_screen.dart        # First-time username entry
│   │   ├── home_screen.dart         # Main menu
│   │   ├── grid_size_screen.dart    # Difficulty selection
│   │   ├── move_count_screen.dart   # Move limit selection
│   │   ├── game_screen.dart         # Core gameplay (2,400+ lines)
│   │   ├── score_screen.dart        # History + statistics
│   │   └── market_screen.dart       # Joker shop
│   └── widgets/
│       ├── press_3d_button.dart     # Reusable 3D-depth button with sound
│       ├── pressable_area.dart      # Low-level gesture wrapper
│       └── torn_edge_clipper.dart   # Decorative torn-paper clip path
│
├── router/
│   └── app_router.dart              # GoRouter route definitions
└── main.dart

test/
└── unit/
    ├── trie_test.dart
    ├── grid_generator_test.dart
    ├── grid_solver_test.dart
    ├── score_calculator_test.dart
    ├── combo_engine_test.dart
    ├── joker_notifier_test.dart
    ├── game_flow_test.dart
    └── edge_cases_test.dart
```

---

## Prerequisites

Make sure the following are installed before you begin:

| Tool | Version | Check |
|---|---|---|
| Flutter SDK | ≥ 3.0.0 | `flutter --version` |
| Dart SDK | ≥ 3.0.0 | bundled with Flutter |
| Xcode | ≥ 15 | `xcode-select --version` |
| CocoaPods | ≥ 1.14 | `pod --version` |

> **Target platform:** iOS only. Android and web builds are not supported.

---

## Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/dilaydikbiyik/wordCrush-mobile.git
cd wordCrush-mobile
```

### 2. Install Dart dependencies

```bash
flutter pub get
```

### 3. Install iOS native dependencies

```bash
cd ios
pod install
cd ..
```

> This step downloads CocoaPods packages (~166 MB) required by ObjectBox and audioplayers. It runs once and caches locally.

### 4. Run the app

Connect a physical iPhone or start an iOS Simulator, then:

```bash
flutter run
```

To run on a specific device:

```bash
flutter devices               # list available devices
flutter run -d <device-id>
```

That's it — no additional build steps needed. `objectbox.g.dart` is pre-generated and included in the repository.

---

## Running Tests

```bash
# All unit tests
flutter test

# Single test file
flutter test test/unit/combo_engine_test.dart

# With verbose output
flutter test --reporter expanded
```

**Test coverage:**

| Test File | What it covers |
|---|---|
| `trie_test.dart` | Insert, search, prefix lookup |
| `grid_generator_test.dart` | Letter frequency distribution |
| `grid_solver_test.dart` | DFS word finding accuracy |
| `score_calculator_test.dart` | Per-letter score sums |
| `combo_engine_test.dart` | Contiguous sub-word detection, substring vs subsequence |
| `joker_notifier_test.dart` | Inventory add / spend logic |
| `game_flow_test.dart` | Full game turn simulation |
| `edge_cases_test.dart` | Empty grid, no-moves, gold limits |

---

## Game Constants

All tunable values live in `lib/core/constants/app_constants.dart` — no magic numbers in game logic:

| Constant | Value | Description |
|---|---|---|
| `easyGridSize` | 10 | Grid dimension for Easy |
| `mediumGridSize` | 8 | Grid dimension for Medium |
| `hardGridSize` | 6 | Grid dimension for Hard |
| `easyMaxMoves` | 25 | Move limit for Easy |
| `mediumMaxMoves` | 20 | Move limit for Medium |
| `hardMaxMoves` | 15 | Move limit for Hard |
| `initialGold` | 9000 | Starting gold balance |
| `goldPerScore` | 10 | Score points needed to earn 1 gold at game end |
| `minWordLength` | 3 | Minimum letters for a valid word |
| `fishDeleteCount` | 3 | Cells removed by the Fish joker |

### Letter Scores

Scrabble-style scoring adapted for Turkish:

| Points | Letters |
|---|---|
| 1 | A, E, İ, K, L, N, R, T |
| 2 | I, M, O, S, U |
| 3 | B, D, Ü, Y |
| 4 | C, Ç, Ş, Z |
| 5 | G, H, P |
| 7 | F, Ö, V |
| 8 | Ğ |
| 10 | J |

---

## Developers

| Name | Student No |
|---|---|
| Onur Akbaş | 230201090 |
| Dilay Dikbıyık | 240201120 |

Kocaeli University — Software Laboratory II, Spring 2026
