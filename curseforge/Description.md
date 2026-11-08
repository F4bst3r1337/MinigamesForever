# Minigames Forever

**Summary (for the short description field):**
A collection of simple minigames to play while you're on a 10-minute flight, waiting out Resurrection Sickness, or doing something else.

---

## Description

**Minigames Forever** is a collection of simple minigames you can play right inside WoW — perfect for long flights, the Resurrection Sickness timer, or any other time you're just waiting around.

Everything lives in one window: pick a game from the list on the left, play on the right. Your progress, high scores and settings are saved between sessions.

### Games

**Bejeweled** — `/bj`
Swap neighbouring gems to match three or more. Chain reactions earn combo points. Gems slide, fall and burst with sparkles, and the board reshuffles itself when no moves are left. Your high score is saved.

**Blackjack** — `/bjk` (also `/blackjack` or `/21`)
Beat the dealer to 21 with Hit, Stand and Double. Blackjack pays 3:2, the dealer stands on 17, and the game uses a 4-deck shoe. You play with in-game chips (no real gold involved), and your chip count is saved. Hand-drawn cards with proper suit symbols, a felt table, and animated dealing and flipping.

**2048** — `/2048`
Slide and merge tiles to reach 2048. Play with the arrow keys, WASD, by swiping with the mouse, or with the on-screen buttons. Your game is saved automatically, so you can stop at any time and pick it up again later.

### Features

- **One window for everything** — game list on the left, game on the right; open it with `/mgf`
- **Animated and polished** — sliding, falling and flipping animations, sparkles and pop effects
- **Settings** (gear icon next to the window): language, animation speed (slow / normal / fast), effects on/off, gem style (icons or plain colours)
- **6 languages:** English, Deutsch, Français, Español, Italiano, Português — defaults to your client language
- **Saves everything:** high scores, chips and your running 2048 game
- **Lightweight:** no dependencies, no libraries, nothing running in the background while the window is closed

### Slash commands

| Command | Action |
| --- | --- |
| `/mgf` | Open or close the minigames window |
| `/bj` | Bejeweled |
| `/bjk`, `/blackjack`, `/21` | Blackjack |
| `/2048` | 2048 |
| `/bj color` | Switch Bejeweled between gem icons and plain colours |

Press **Esc** to close the window.

### Installation

1. Download and extract the archive.
2. Copy the `MinigamesForever` folder into your `Interface\AddOns\` directory.
3. Restart the game and make sure **Minigames Forever** is enabled on the character select screen.
4. Type `/mgf` in game.

### Notes

- Blackjack is played with fictional chips only; no gold is ever spent or won.
- Splitting and insurance are not included in Blackjack.
- More games may follow. Suggestions and bug reports are welcome — if you hit a Lua error, please include the full message.

*Vibe-coded by @f4bst3r*
