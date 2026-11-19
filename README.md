# Tabletop

Tabletop RPG **battle map with a grid and tokens**, made to run on an **old iPad with iOS 8** (tested on an iPad 3, A5X, iOS 8.4.1). Designed with Cyberpunk RED in mind, but works with any grid-based system.

Native Objective-C/UIKit app, no storyboards, built for **armv7** with the Xcode 13.4.1 toolchain running on current macOS.

## Install

Add the Cydia repository **https://douugr.github.io/repo/** (Cydia or Melder → Sources → Edit → Add) and install **Tabletop**.

## Features

- Map imported from Photos or from the app's Documents folder; scaled down to at most 3072 px
- Two-finger zoom and pan; one finger is for tokens and the ruler
- Grid overlay (for maps without a printed grid): size, offset, opacity and meters per square (default 2 m)
- Tokens with name, label, color, size from 1×1 to 3×3, HP (yellow below half, red at 0) and a "down" state
- Dragging a token shows the distance moved; dragging on empty space is a ruler (diagonals count as 1 square)
- Initiative: draggable order, current turn highlighted, round counter, skips tokens that are down
- Multiple scenes, each with its own map and tokens; everything is saved automatically

## Requirements (to build)

- Mac with **Xcode 13.4.1** extracted (only the toolchain is used). Newer Xcode versions can't build armv7.
- `ldid` (`brew install ldid`)
- To install without Cydia: a jailbroken iPad with **AppSync Unified** and `ideviceinstaller` (the one bundled with [Legacy iOS Kit](https://github.com/LukeZGD/Legacy-iOS-Kit) works)

## Build and install

```bash
# By default the script looks for ../Xcode-13.4.1.app; or point to it with X13:
export X13=/path/to/Xcode-13.4.1.app/Contents/Developer

./build.sh            # builds Tabletop.ipa
./build.sh install    # builds and installs on the connected iPad
```

## Maps

iOS 8 can't open WebP: convert maps to JPG or PNG first.

- **Installed from Cydia:** the app's Documents folder is `/var/mobile/Documents`. Copy maps there with SSH or Filza, then use **Map → App files**.
- **Installed with AppSync:** use Finder (iPad → Files tab → drag onto "Tabletop"), then **Map → App files**.

### Automatic grid from the file name

If the file name contains `grid <N>px (<M> m)` (also `square` or the Portuguese `quadrado`), the app sets up the grid by itself when the map is loaded through **App files**:

```
Netrunner Cafe - grid 128px (2 m).jpg   → 128 px squares, 2 m per square
Shop - grid 70px.png                    → 70 px squares (meters unchanged)
```

The size is in pixels of the original image (if the app scales the image down, the grid follows). If the scene still has its default name ("Scene 1"…), it takes the map's name.

## Structure

```
src/TTModel.*              tokens, scenes and persistence
src/TTBoardView.*          map, grid, tokens and ruler
src/TTMainViewController.* toolbar, grid panel, initiative, menus
src/main.m                 AppDelegate
```

## License

MIT, see [LICENSE](LICENSE). The icon is original, made for the project.
