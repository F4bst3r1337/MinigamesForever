# Minigames Forever

A collection of simple minigames to play while you're on a 10-minute flight, waiting out Resurrection Sickness, or doing something else.

A World of Warcraft addon (built for WoW Forever, interface `16001`).

## Games

- **Bejeweled** (`/bj`) - match three or more gems
- **Blackjack** (`/bjk`, `/blackjack`, `/21`) - beat the dealer to 21 with in-game chips
- **2048** (`/2048`) - slide and merge tiles

Open the main window with `/mgf`. Settings (language, animation speed, effects, gem style) are behind the gear icon. Available in English, Deutsch, Français, Español, Italiano and Português.

## Installation

Copy the `MinigamesForever` folder into `Interface/AddOns/`, restart the game and enable the addon on the character select screen.

## Repository layout

| Path | Contents |
| --- | --- |
| `MinigamesForever/` | The addon itself (this is what gets installed or zipped) |
| `curseforge/` | CurseForge project description (EN/DE) and logo |

To build a release archive, zip the `MinigamesForever` folder so that it is the top-level folder inside the archive.

## Adding a game

Each game is its own Lua file that registers itself with `MG.RegisterGame`, builds its UI with `MG.NewPage` and adds its texts with `MG.AddLocale`. Add the file to `MinigamesForever.toc` after `Core.lua`. See `Game2048.lua` for a compact example.

*Vibe-coded by @f4bst3r*