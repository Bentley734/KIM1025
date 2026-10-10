# KIM1025

## 1.7.4 — Downloader selector and Gen 1 battle animation

The KIM ASSETS downloader now draws a visible selection arrow beside the selected download or removal option, independent of the game's font.

Red/Blue/Yellow battle constructors receive HD Pokemon art as soon as its assets are available. Native battle draws use an immutable image for each animation frame so image-processing caches cannot freeze a reused canvas; the fullscreen HD pass uses the same frame-safe presentation. Animation continues across repeated loops. Missing assets retain vanilla fallback, and ANIMATION OFF still holds the first frame.

Install `kim1025-1.7.4.zip` (about 9 MB), replace the installed `mods/kim1025` folder, keep the downloaded asset cache, and restart. The existing KIM1025 artwork pack remains version 1.0.0, served from release v1.7.3; installed artwork does not need another download.

Validation: 17 runnable regression suites passed; 86 Lua files compiled. Includes 930 downloader checks and 73 battle constructor/animation checks. The installed Mac LOVE runtime passed 28 GPU checks for selector positioning and repeated animation through an image-processing cache. Full ROM and physical phone gameplay remain unverified.

## 1.7.3 — Persistent in-app KIM1025 assets

The installable mod ZIP is now about 9 MB. The 216 portrait, widescreen and ultrawide battle backgrounds live in an independently versioned KIM1025 artwork pack, downloaded once into the persistent mod cache. Future code updates retain this cache and do not require another 400+ MB download.

Open KIM ASSETS in the main KIM asset downloader. DOWNLOAD ALL installs missing original KIM packs, then KIM1025 assets. DOWNLOAD KIM1025 installs only the new artwork pack. Users with original KIM assets already installed are prompted for KIM1025 assets after updating. B defers the prompt; the download remains available in KIM ASSETS. Existing packaged artwork can migrate locally when upgrading in place; a clean small mod installation downloads the artwork.

Install `kim1025-1.7.3.zip`, close the game, replace `mods/kim1025` with its extracted `kim1025` folder, retain the downloaded asset cache, and restart. Accept the in-app download prompt. `KIM1025-assets-v1.0.0.zip` is an artwork pack used by the downloader, not an installable mod ZIP. Pack version 1.0.0 remains independent of code version 1.7.3. Keep release v1.7.3 and its asset ZIP available for future clients.

Each downloaded artwork file is SHA-256 checked before installation. Completion is recorded only after extraction and metadata/index writes succeed. Original KIM and KIM1025 packs use separate cache namespaces and separate removal indexes. Cancelling an asset download defers missing packs, and retry resumes the failing pack without restarting installed original packs. The existing portable and mobile download paths are reused.

Validation: all 17 runnable headless suites pass and 86 Lua files compile, including 426 hub-flow checks and 90 production ZIP/cache checks. Full-pack validation in the installed Mac LÖVE runtime passed 12 checks, verified all 216 real artwork hashes, and decoded portrait, widescreen and ultrawide art. Full ROM and physical phone gameplay remain unverified.

# KIM1025 1.7.2

Fixes small or misplaced player trainers in mobile HD battle intros. Trainers now draw once, at the authored player platform, at a readable size that scales with the arena rather than the native UI. ROM/default trainer art and BATTLE SPRITES OFF use the same alignment. Native slide timing, animation, desktop presentation, Safari/demo scenes, and external stage ownership are preserved.

Includes the v1.7.1 player Pokemon animation fix and all supporting libraries, data, and packaged artwork.

Install the complete KIM1025-v1.7.2.zip: close the game, replace mods/kim1025 with its extracted kim1025 folder, retain the external downloaded asset cache, and restart. Avoid a nested kim1025/kim1025 folder. The small hotfix is an overlay: merge into an existing full installation and keep assets.

Validation: 15 runnable headless suites pass, including 82 trainer-intro checks; 83 Lua files compile. The previous build reproduces the trainer scale failure. The installed Mac game's LÖVE runtime rendered the production trainer code and actual art in an isolated test scene at 1320x2868 and 660x1434; 9 GPU checks pass and visible trainer contact is within one pixel of the platform anchor. This was a renderer fixture, not a full ROM gameplay test or physical iPhone test.

---

# KIM1025 1.7.1

Includes the Gen 1/2 player battle-sprite animation hotfix and every required supporting library, including lib/flat_world_orientation.lua. This is a complete mod package.

## Install

Close Gen1Recomp, extract KIM1025-v1.7.1.zip, and replace the old mods/kim1025 folder with the extracted kim1025 folder. Confirm main.lua and lib/flat_world_orientation.lua are directly under that folder; avoid a nested kim1025/kim1025 directory. Retain the external downloaded KIM asset cache, then restart the game.

Use the complete release ZIP for installation. The earlier six-file hotfix was an overlay and could not replace a full mod folder.

## Fixes

- Restores Gen 1/2 player battle-sprite animation when an inherited native scissor clips the cached sprite canvas.
- Retains the same cached drawable while advancing animation frames, fixes front/back virtual-path routing, and preserves host clipping and animation/sprite toggle behavior.
- Includes all libraries, data, and packaged artwork to prevent missing-file load failures after folder replacement.
- Includes the Gen 3 compatibility and Kanto in Motion 1.7.0 updates from the preceding release.

Validation: all 14 runnable headless suites pass and all 82 Lua files compile. ZIP integrity and supporting-file completeness pass. Live device gameplay and the separate production 1025Dex integration remain unverified.

---

# KIM1025 1.7.1

Player battle animation hotfix for Gen 1/2. Replace the installed kim1025 folder with the full release ZIP, or overlay the hotfix ZIP onto the existing 1.7.0 installation, then restart the game. Keep the HD asset cache.

# KIM1025 1.7.0

Updated from the supplied KIM1025 1.6.31 and Kanto in Motion 1.7.0 packages for gen1recomp 0.3.71.

- Gen 3 Start Menu → KIM1025 opens the complete native settings page. UI SETTINGS and BATTLE SETTINGS expose the complete schema, including player/enemy size. OPTIONS also retains KIM1025 and ASSETS access; OPTIONS → MODS → KIM1025 uses the expanded registered schema.
- Gen 3 HD backgrounds can use KIM1025's packaged complete arenas when the external PNG pack is absent. Embedded platform coordinates are respected. HD BATTLE BACKGROUNDS OFF restores the native field. Hoenn environments without suitable art retain their native scenes.
- Adds upstream Gen 3 Modern menus, dialogue, naming, Trainer Card, storage, Summary, Pokédex and lower battle panels, readability fixes and controller navigation improvements.
- Adds cooperative 1025Dex routing: supported #001–386 HD art uses KIM, expanded species retain the Dex art provider. Missing HD files fall back safely. Turning BATTLE SPRITES off restores the provider.
- Adds upstream Unown/Deoxys form metadata, layered asset upgrades, Gen 2 Summary and Battle Art compatibility, and responsive UI fixes.
- Preserves the kim1025 mod ID, existing settings/cache ownership, custom portrait/widescreen/ultrawide arenas, Gen 1 sizing controls and mobile/iOS corrections. General UI font scale now follows upstream's 200% cap.

## Install

Replace the old kim1025 folder with this package's kim1025 folder in your mods directory. Keep only one KIM1025 copy and disable the standalone Kanto in Motion mod; they replace the same presentation layers. Restart the game session after replacement.

Open Start Menu → KIM1025 → BATTLE SETTINGS for HD backgrounds and battler sizing. HD ASSET MANAGER is available from the KIM1025 page and ASSETS from OPTIONS. Existing base artwork is retained; the manager downloads the missing 1.1.0 Unown and 1.2.0 Deoxys supplements in order. Packaged backgrounds do not require that download.

Validation is headless against supplied 0.3.71 engine code. No live ROM playthrough or graphical confirmation has been performed. See VALIDATION-1.7.0.md.

---

# Current compatibility fork: v1.6.8

Open **OPTION → ASSETS**, then press A to open the HD asset manager. B returns to OPTION. This replaces the older ASSETS Start/title entry described in upstream historical notes below.

# KIM1025 v1.6.6

**Kanto in Motion** is an HD animated Pokémon presentation and battle overhaul for **Gen1Recomp**.

It supports:

- **Pokémon Red / Blue / Yellow** — National Dex #001–151
- **Pokémon Gold / Silver / Crystal** — National Dex #001–251
- **Pokémon FireRed / LeafGreen** — National Dex #001–386

The compatibility fork is named KIM1025 with its own internal mod ID, `kim1025`. Its repository is Bentley734/KIM1025.

## Compatibility fork v1.6.6

Merges upstream Kanto in Motion 1.6.2 while preserving our 1025Dex animated
sprites/shinies, native icon alignment, readable asset manager and enemy ground
alignment. This build uses its own mod ID, `kim1025`.

## Enemy placement in v1.6.5

When 1025Dex and KIM HD backgrounds run together, enemy pictures align to the
background ground line using their existing bounds metadata and native species
coordinates. Player positioning, floating elevation and animation remain intact.
The adjustment is inactive without an available HD background.

## Gen3 asset manager in v1.6.4

The ASSETS menu uses Gen3's native screen stack and text renderer. If HD assets
are not installed, select **ASSETS**, then press **A** to download them.
The installer reports progress and any download/cache errors on screen.
Party and PC icons now stay on 1025Dex’s native placement when both mods run.

## 1025Dex compatibility in v1.6.2

Use this build with **1025Dex v1.2.5 or newer**. In Gen3, 1025Dex supplies the
animated Pokémon pictures, shiny palettes and sprite positioning. Kanto in
Motion retains its HD backgrounds, battle effects and native HUD. Its separate
battler and menu preview overlays defer to Dex to prevent provider conflicts.
Without 1025Dex, Kanto in Motion keeps its existing sprite presentation.

## Upstream changes from v1.6.2

v1.6.2 is a multi-generation compatibility and asset-management update focused on the shared HD cache, FR/LG/Game3 presentation, Gen 2 menu behavior, and iOS Battle Art compatibility.

- **Remove and re-download HD assets:** the HD Asset Manager can now delete KIM's cached HD Pokémon/background pack, either to reclaim storage or recover from corrupted assets. After removal, users can download the pack again immediately or reopen the manager later.
- **Portable-mode Asset Manager:** Gen1Recomp portable mode is now supported. KIM uses Gen1Recomp's binary-safe download path and native temporary-file handoff, while final assets continue to live in portable-aware `mod.cache`.
- **FireRed/LeafGreen Asset Manager:** FR/LG now has a native **ASSETS** OPTION entry on desktop and mobile. FR/LG can download the shared pack itself; it no longer needs another supported game to populate the cache first.
- **FR/LG mobile downloads:** Android/iOS FireRed/LeafGreen now reopens the completed ZIP through Gen1Recomp's engine-owned save-directory helper before extraction, fixing the Game3 mobile filesystem mismatch.
- **Gold/Silver/Crystal mobile HD assets:** downloaded Johto HD Pokémon assets, including National Dex #152–251, now resolve correctly from the shared cache on mobile.
- **FR/LG in-battle Party/Summary:** full-screen Party/Summary menus opened during battle keep KIM's final-resolution HD menu Pokémon/icons instead of being overwritten by the underlying battle compositor.
- **FR/LG + GameShark:** KIM prevents a native-sprite provider recursion when **BATTLE SPRITES = OFF**. This compatibility fix is entirely on the KIM side; GameShark is not modified.
- **Gen 2 Start Menu visibility:** larger UI scales/densities now keep the selected native row visible, including the bottom **MODS** and **QUIT** entries.
- **iOS + Battle Art:** the world-only orientation bridge now follows Battle Art's live 3D battlefield at the final world handoff and includes an iOS/LÖVE 12 fallback. KIM's HUD, Modern UI, and touch controls stay outside the flip. Community iPhone/iPad validation is still requested.

## What’s new in v1.6.1

v1.6.1 is a focused post-v1.6.0 compatibility and stability update, with most changes centered on Gen 1 mobile battles.

- **Android / mobile Gen 1 battle stability:** hardened KIM's battle rendering boundaries so failed presentation draws cannot leave unmatched LÖVE graphics-state pushes and later trigger `Maximum stack depth reached`.
- **Controller-equipped Android handhelds:** Modern battle dialogue, commands, move selection, and battle messages no longer depend on virtual TouchControls being visible. Devices such as the Retroid Pocket 6 can keep touch controls hidden while using the built-in controller without losing the lower battle UI.
- **Oak's Lab first rival battle:** restores KIM's packaged `garyfrontplayer` presentation at the corrected mobile scale and suppresses the duplicate native rival image during the battle outro.
- **Gen 1 NEW GAME Modern UI:** Oak's native intro artwork and timing remain source-owned, while the dialogue, choices, and naming child screens can use KIM Modern UI when **INTEGRATED MODERN UI** and the matching UI surface are enabled.
- **Gen 1 PC Modern UI:** the initial `WHICH PC?` menu can now use KIM Modern UI while retaining the native PC item list, callbacks, and Player PC / Bill's PC behavior.
- **iOS + Battle Art compatibility:** adds a narrowly scoped world-canvas orientation correction for the affected Apple/Metal renderer used by current Battle Art builds. Only Battle Art's 3D world is corrected; KIM's HUD, Modern battle UI, and touch controls remain upright. This path is included for community validation because the maintainer does not have iOS hardware for local testing.
- Turning Modern UI off continues to return supported surfaces to their native Gen 1 presentation.

## What’s new in v1.6.0

v1.6.0 is a major presentation, compatibility, and distribution update across all supported game families.

- **Slim core + one-time HD Asset Manager:** the large HD battle Pokémon and HD battle-background pack is now downloaded separately from the official `HaseoSora/Kanto-in-Motion-Assets` release, cached outside the mod folder, and reused by future KIM updates.
- **Expanded Gen 2 Modern UI:** the title/main menu, complete NEW GAME setup flow, dialogue/choices, naming screens, Start Menu and supported menus now use KIM Modern UI when **MODERN UI** is enabled.
- **Gen 2 UI gating fixed:** **MODERN UI** is the master presentation switch, while **MENU UI**, **DIALOGUE UI**, **POKEMON SCREENS**, and battle UI controls remain per-surface opt-outs. Turning Modern UI off restores native G/S/C presentation.
- **Gen 2 Start Menu cleanup:** removes the stray `MAPA` row without leaving a hidden selectable entry.
- **Dex Radar 1.2.0 compatibility:** KIM can present the unmodified Dex Radar mod through Modern UI on both Gen 1 and Gen 2 while leaving all Dex Radar logic untouched.
- **Gen 1 native-fit HD backgrounds:** new **BATTLE BG MODE** options let vanilla/default battlers use KIM HD backgrounds with stock battle coordinates while preserving the full-screen KIM arena for HD battle sprites.
- **Gen 1 battle fixes:** corrected trainer placement/size on the widened field, enemy attack-side ownership for moves such as Growl / Quick Attack / Fury Attack, and cleanup of lingering KRBA BG/FG timing planes.
- **FR/LG fallback and stability:** missing Johto/Hoenn HD battle art now falls back to native FR/LG sprites instead of disappearing, and the `BATTLE SPRITES = OFF` path yields cleanly back to the native provider.
- Preserves native gameplay/state ownership underneath KIM presentation layers in Gen 2 and FR/LG.

## Main features

### Red / Blue / Yellow

- HD animated front/back Pokémon
- Normal and shiny battle presentation
- Integrated Modern UI, including supported NEW GAME dialogue/choices/naming and PC menus
- KIM HP/status HUD
- Integrated move animations
- HD location/time-aware battle backgrounds
- Pokémon shadows
- Shiny encounter presentation
- Player trainer selection
- Animated title-screen Pokémon
- HD Pokémon icons
- Native-fit HD background mode for vanilla/default battlers
- Battle Art and PotatoVoxel compatibility

### Gold / Silver / Crystal

- HD animated Pokémon through National Dex **#251**
- Integrated KIM **Modern UI** for menus, dialogue, shops, save/options, Pokédex, Party, and supported battle UI surfaces
- Native Gen 2 battle logic, HP/status HUD, trainers, backgrounds, and move animations
- Modern UI themes and applicable UI customization controls shared with KIM’s Gen 1 presentation
- HD animated battle Pokémon
- HD Summary-screen Pokémon
- HD Pokédex Pokémon
- HD Pokémon icons
- Pokémon shadows
- Full Modern UI title/main menu and NEW GAME setup flow
- Dex Radar 1.2.0 Modern UI compatibility
- Final-window rendering for crisp HD menus and Pokémon art
- Shared external HD cache use on desktop and mobile, including Johto #152–251

### FireRed / LeafGreen

- HD animated Pokémon through National Dex **#386**
- Native FR/LG HUD, commands, dialogs, and move animations
- HD animated battle Pokémon
- HD Summary / Pokédex / scripted Pokémon previews
- HD party, storage, and menu icons
- Optional HD battle backgrounds
- Pokémon shadows
- Final-resolution HD rendering for cleaner menu and battle presentation
- Desktop and mobile portrait/landscape support
- Mobile **SCREEN POS** support
- Native sprite fallback when KIM HD battle artwork is unavailable
- Native **ASSETS** Start Menu access for download/remove/re-download
- In-battle Party/Summary compatibility for final-resolution HD menu Pokémon/icons

## HD Pokémon icons

Kanto in Motion includes HD Rescaled Pokémon icons for **National Dex #001–386**.

- R/B/Y uses KIM's established icon path.
- G/S/C renders the HD icons at final window resolution instead of magnifying the native 16×16 icon canvas.
- FR/LG renders the HD icons at final window resolution and aligns them to the native Game3/OAM menu geometry.
- `POKEMON ICONS = OFF` restores the native game icons or yields to a compatible icon provider.
- Icon animation follows the main `ANIMATION` setting.
- Separate shiny menu-icon artwork is not included yet; shiny Pokémon currently use the normal HD menu icon.

## Kanto in Motion settings

Open **KANTO IN MOTION** from the mod settings screen. On **Red / Blue / Yellow**, the Gen 1 battle-specific controls are grouped under **BATTLE → OPEN**. The HD Asset Manager can also remove an installed external pack and make it available for a later re-download.

### Red / Blue / Yellow — main settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Enables KIM's animated Pokémon presentation on supported menu, Summary/Status, Pokédex, Party, evolution, and other presentation surfaces. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in party and other native icon slots. OFF yields icon presentation to the game or another compatible icon provider such as HGSS_SPRITES. |
| **INTEGRATED MODERN UI** | ON / OFF | ON | Enables KIM's customized Gen 1 Modern UI presentation. |
| **ANIMATION** | ON / OFF | ON | Enables animated Pokémon playback and supported animated trainer presentation. OFF holds supported animated art on its first frame. |
| **TITLE SCREEN** | ON / OFF | ON | Enables KIM's animated title-screen Pokémon presentation. |
| **TITLE TRAINER** | ANIMATED / ORIGINAL GEN 1 | ANIMATED | Chooses KIM's animated Red title trainer or Gen1Recomp's original title trainer. |
| **TITLE CYCLE SPEED** | NORMAL / SLOW / SLOWER | SLOW | Controls how quickly the title-screen Pokémon changes. |
| **TITLE PKMN SIZE** | 50%–125% in 5% steps | 75% | Scales only the cycling title-screen Pokémon. Red and the custom logo are unchanged. |
| **ASSET MANAGER** | OPEN | — | Opens the HD Asset Manager for downloading, removing, re-downloading, checking, or reusing the external HD battle asset pack. |

### Red / Blue / Yellow — BATTLE settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **BATTLE SYSTEM** | ON / OFF | ON | Master switch for KIM's Gen 1 battle scene/HUD presentation. OFF yields those layers to vanilla Gen1Recomp or another compatible battle owner. |
| **MODERN BATTLE UI** | ON / OFF | ON | Uses KIM's integrated command, move-selection, and battle-message presentation. |
| **BATTLE SPRITES** | ON / OFF | ON | Enables KIM's HD animated battle Pokémon. Compatible external battle scenes can honor this setting independently. |
| **MOVE ANIMATIONS** | ON / OFF | ON | Uses KIM's integrated Kanto Rework / Pokémon Essentials-style animations for all 165 Gen 1 moves. OFF falls back to the active battle provider's native move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality. Higher levels add progressively softer feathering. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts shadow darkness without changing Pokémon size or position. |
| **SHINY ODDS** | NATIVE 1/8192; 1/4096; 1/2048; 1/1024; 1/512; 1/256; 1/128; 1/64; 1/32; 1/16; 1/8; 1/4; 1/2; ALWAYS | NATIVE 1/8192 | Controls wild shiny generation. NATIVE leaves the normal DV behavior intact. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD battle backgrounds. |
| **BATTLE BG MODE** | AUTO / FULLSCREEN / NATIVE FIT | AUTO | Controls how Gen 1 HD battle backgrounds are framed. AUTO keeps the full-screen KIM arena with KIM battle sprites, but switches to native-fit framing when BATTLE SPRITES is OFF. NATIVE FIT keeps vanilla/default battlers and native attack effects at their original 160×144 positions while showing the arena through a wider FR/LG-style 240×160 viewing window, with a calibrated vertical offset to align the HD pads to stock battlers. |
| **PLAYER TRAINER** | RED / DEFAULT-ROM / GEN 1 / GEN 2 / GEN 3 / GEN 4 / GEN 5 / ASH / GARY / front-sprite choices | RED | Chooses the player trainer shown during battle intro/send-out. |
| **PLAYER PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the player-side Pokémon. |
| **ENEMY PKMN SIZE** | 50%–200% in 5% steps | 100% | Scales only the enemy-side Pokémon. |
| **3D PKMN SIZE** | 50%–125% in 5% steps | 100% | Scales Pokémon in compatible staged 3D battles. 100% is KIM's neutral reference. |
| **POTATO CAMERA** | 100%–150% in 5% steps | 115% | PotatoVoxel only. Higher values pull the camera farther back. |
| **POTATO MOBILE ENEMY SIZE** | 50%–125% in 5% steps | 85% | Mobile PotatoVoxel only. Fine-tunes enemy Pokémon size. |
| **HUD SCALE** | OG / SCALED | OG | Chooses the HP/status HUD scale preset. |
| **HUD SIZE** | 60%–100% in 5% steps | 100% | Fine-tunes the enemy/player HP/status HUD size. |
| **HUD OPACITY** | 25%–100% in 5% steps | 100% | Adjusts HP/status HUD opacity. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Changes the footprint of the lower command/move/message panel. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts the lower panel background opacity. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales Modern UI battle command, move, and message text. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move layout. VERTICAL lists moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected move's type, PP, power, and accuracy. |
| **HUD COLOR** | COLOR / INVERTED | COLOR | Chooses the HP/status glyph treatment. |

### Gold / Silver / Crystal settings

Gold / Silver / Crystal retain their native gameplay and battle logic. KIM's Modern UI is a presentation layer: the native Gen 2 HP/status HUD, trainers, battle timing, backgrounds, move animations, scripts, shops, save logic, option logic, and state transitions remain authoritative underneath it.

#### Main Kanto in Motion settings

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | KIM HD / VANILLA | KIM HD | Chooses KIM's HD animated menu Pokémon or the native Gold/Silver/Crystal Pokémon artwork. This is independent from POKEMON ICONS and BATTLE SPRITES. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM's HD Pokémon icons in native G/S/C icon slots. OFF restores the game or another compatible icon provider. |
| **ANIMATION** | ON / OFF | ON | Master animation control for supported KIM Pokémon/trainer presentation. OFF holds supported animated KIM artwork on its first frame. |
| **MODERN UI** | ON / OFF | ON | Master switch for KIM's Gen 2 Modern UI across the title/main menu, Start/menu screens, Party, Pokédex, Pack, PokéGear, Trainer Card, Save, Options/KIM settings, dialogue, shops, choices, level-up messages, and supported battle UI surfaces. OFF yields those presentation surfaces to the native game. |
| **UI SETTINGS** | OPEN | — | Opens the dedicated Gen 2 UI customization submenu described below. |
| **ASSET MANAGER** | OPEN | — | Opens the HD Asset Manager for downloading, removing, re-downloading, checking, or reusing the external HD battle asset pack. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in native G/S/C battles while retaining native Gen 2 battle logic and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts Gen 2 battle shadow darkness without changing Pokémon size or position. |

#### Gold / Silver / Crystal — UI SETTINGS

These controls are grouped under **KANTO IN MOTION → UI SETTINGS**. They mirror the applicable Gen 1 Modern UI customization options while keeping Gen 2 game/state ownership native.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **UI THEME** | GEN1 MODERN / CLASSIC MONO / CRIMSON / CRIMSON GLASS / MODERN GLASS / POCKET GREEN / MIDNIGHT / MIDNIGHT GLASS / FROST / LIGHT / DARK | GEN1 MODERN | Chooses the palette used across the Gen 2 Modern UI. |
| **UI FRAME STYLE** | THEME / PIXEL / SOFT / PLAIN | PIXEL | Chooses the Modern UI panel border treatment. |
| **PIXEL FRAME** | FRAME 1 / FRAME 2 / FRAME 3 | FRAME 2 | Chooses the authored PNG frame used when PIXEL framing is active. |
| **PIXEL FRAME SCALE** | 1X / 2X / 3X / 4X | 2X | Scales the pixel-frame artwork by a whole-number multiplier. |
| **UI DENSITY** | AUTO / COMPACT / COMFORTABLE | AUTO | Adjusts panel spacing and row height. |
| **UI SCALE** | AUTO; 75%–150% in 5% steps; 175%–400% in 25% steps | 100% | Scales Gen 2 Modern UI panels and control spacing. 100% is calibrated to the cleaner Gen 1-like footprint. |
| **FONT SCALE** | AUTO; 80%–200% in 5% steps; 225%–400% in 25% steps | 100% | Scales Modern UI title, body, caption, value, and hint text independently of panel size. |
| **PIXEL ART FONT** | ON / OFF | OFF | ON uses the Plain Pixel font. OFF uses the normal scalable system font, matching the cleaner Gen 1-style presentation. |
| **DIALOGUE TEXT SCALE** | INHERIT / 110% / 125% / 150% / 175% / 200% | INHERIT | Boosts dialogue, choices, quantities, and confirmation text separately from general font scale. |
| **LAYOUT STYLE** | ADAPTIVE / FLOATING / FULL SCREEN | ADAPTIVE | Chooses responsive/floating cards or a larger full-screen presentation. |
| **PANEL OPACITY** | 0%–100% in 5% steps | 100% | Adjusts panel-background opacity independently from text and borders. |
| **TEXT / LINE OPACITY** | 0%–100% in 5% steps | 100% | Adjusts text, labels, borders, dividers, and accent opacity. |
| **HIDE ORIGINAL UI** | ON / OFF | ON | Hides the native Gen 2 UI where KIM supplies the complete Modern UI presentation. |
| **START MENU FAST JUMP** | ON / OFF | ON | Lets left/right directional presses jump five rows in the Gen 2 Start Menu. |
| **START MENU PARTY VIEW** | ON / OFF | OFF | Shows a compact party summary beside the Start Menu. |
| **SIDE MENU INSET** | 0 / 10 / 20 / 30 / 40 / 50 | 0 | Moves the floating Start Menu inward on wide displays. |
| **MINIMAL UI** | ON / OFF | OFF | Uses tighter spacing and less secondary detail. |
| **DIALOGUE UI** | ON / OFF | ON | Enables Modern UI for Gen 2 text boxes, choices, quantities, and confirmation prompts. |
| **MENU UI** | ON / OFF | ON | Enables Modern UI for the Gen 2 title/main menu, Start Menu, Pack, PokéGear, Save, and Options screens. |
| **POKEMON SCREENS** | ON / OFF | ON | Enables Modern UI for Party, Pokédex, Trainer Card, and supported Pokémon screens. |
| **MOD MANAGER UI** | ON / OFF | ON | Enables Modern UI presentation for Kanto in Motion's own settings screens. |
| **SPRITE ANIMATION** | ON / OFF | ON | Animates supported KIM menu/Party/Pokédex artwork without changing the selected MENU SPRITES source. |
| **MODERN BATTLE UI** | ON / OFF | ON | Replaces only the native lower battle dialogue/command/move surface; the native Gen 2 HP/status HUD and battle logic remain unchanged. |
| **BATTLE UI SIZE** | 60%–100% in 5% steps | 100% | Adjusts the Gen 2 Modern lower battle-panel footprint while keeping it bottom-anchored. |
| **BATTLE UI OPACITY** | 25%–100% in 5% steps | 100% | Adjusts only the Gen 2 Modern lower battle-panel background opacity. |
| **BATTLE TEXT SIZE** | 100%–400% in 25% steps | 150% | Scales Gen 2 Modern battle command, move, and message text independently of the native HP/status HUD. |
| **MOVE LAYOUT** | GRID / VERTICAL | GRID | GRID uses a 2×2 move selector. VERTICAL lists the four moves top-to-bottom. |
| **MOVE INFO** | ON / OFF | OFF | Shows the selected Gen 2 move's type, PP, power, and accuracy beside the move list. |

The UI Settings submenu also includes **RESET TO DEFAULT** for restoring the Gen 2 Modern UI controls to their current defaults.

#### Gen 2 Modern UI coverage

With **MODERN UI = ON**, KIM currently presents:

- title/main menu (`CONTINUE`, `NEW GAME`, `OPTION`, `EXIT GAME`) over the animated Gen 2 title artwork
- Start Menu rows remain visible/scroll correctly at enlarged UI scales, including the bottom `MODS` / `QUIT` (return-to-title) entries
- complete NEW GAME setup presentation: Crystal gender selection, clock setup/confirmation, Oak/Elm speech dialogue, player-name preset selection, the Gen 2 naming keyboard, and the final shrink/intro dialogue
- Start Menu
- Party and Pokémon status/details
- Gen2 Clean UI-based Pokédex list and entry presentation
- Pack
- PokéGear, including native map/phone data presented through the KIM theme
- Trainer Card
- Save Menu
- native Options categories and submenus
- Kanto in Motion's own settings and Battle submenu
- common NPC / field / phone dialogue
- YES/NO prompts and scripted choice menus
- Poké Mart buy/sell/quantity/confirmation presentation
- supported level-up/stat and battle prompt presentation
- battle commands, move selection, and battle messages when **MODERN BATTLE UI = ON**

### FireRed / LeafGreen settings

FireRed / LeafGreen keep Gen1Recomp's native Game3 UI, HUD, commands, dialogs, and move-animation system while KIM supplies HD Pokémon presentation.

| Setting | Choices | Default | What it does |
| --- | --- | --- | --- |
| **MENU SPRITES** | ON / OFF | ON | Uses KIM animated Pokémon on supported FR/LG menu, Summary, Pokédex, and scripted presentation screens. |
| **POKEMON ICONS** | ON / OFF | ON | Uses KIM HD Pokémon icons in party, storage, Pokédex, and other native icon slots. OFF restores the game's native icons. |
| **ANIMATION** | ON / OFF | ON | Enables animated KIM Pokémon. OFF holds supported animated Pokémon on the first frame. |
| **BATTLE SPRITES** | ON / OFF | ON | Uses KIM HD animated Pokémon in FR/LG battles while keeping the native FR/LG HUD, commands, dialogs, and move animations. |
| **PKMN SHADOWS** | OFF / LOW / MEDIUM / HIGH / ULTRA | MEDIUM | Controls ground-contact shadow quality for KIM HD battle Pokémon. Shadows follow battlers during send-out/slide movement. |
| **SHADOW OPACITY** | 50%–150% in 10% steps | 100% | Adjusts FR/LG battle shadow darkness without changing Pokémon size or position. |
| **HD BATTLE BACKGROUNDS** | ON / OFF | ON | Uses KIM's location-aware HD Kanto battle backgrounds while preserving FR/LG's native battler/HUD geometry. OFF restores the native FR/LG battle background. |
| **ASSET MANAGER** | OPTION → ASSETS | — | FR/LG uses the native Game3 OPTION entry **ASSETS** to download, remove, or re-download the shared external HD battle asset pack. On the installed-pack screen, **A = REMOVE** and **B = CLOSE**; removal asks for a second **A** confirmation. |

## Mobile support

- R/B/Y keeps separate desktop/mobile KIM battle presentation paths with graphics-state protection on Android/iOS.
- On controller-equipped Android handhelds, the Gen 1 Modern battle lower UI remains available even when Gen1Recomp's virtual TouchControls are hidden.
- The first Oak's Lab rival battle uses KIM's corrected Gary front presentation without duplicating the native rival at the outro.
- Battle Art on the affected iOS Apple/Metal/LÖVE 12 path receives a world-only orientation correction at the final Battle Art world handoff; KIM HUD/UI/touch layers are intentionally left unflipped. This compatibility path is awaiting broader community hardware validation.
- G/S/C keeps KIM's final-resolution HD Pokémon/menu rendering architecture and native Gen 2 gameplay state beneath the Modern UI presentation. v1.6.2 also fixes mobile lookup of downloaded Johto (#152–251) HD assets from the shared cache.
- FR/LG uses the native Game3 geometry with KIM HD art rendered at final resolution. Full-screen Party/Summary menus opened during battle temporarily own the frame so their HD menu Pokémon/icons are not overwritten by the battle compositor.
- FR/LG portrait and landscape honor Gen1Recomp's **SCREEN POS** setting.
- FR/LG uses a single mobile battle presentation path to avoid duplicate HUD/menu rendering.

## HGSS_SPRITES compatibility

When Kanto in Motion is used with **HGSS_SPRITES**:

- In Gen 1, `BATTLE SYSTEM = ON` blocks HGSS battle-side hooks from replacing or rescaling KIM/Battle Art battle presentation.
- HGSS overworld/player presentation remains available where it does not conflict with KIM ownership.
- `POKEMON ICONS = ON` keeps KIM in control of Pokémon icons.
- `POKEMON ICONS = OFF` yields icon presentation back to HGSS or the native game.

## Dex Radar compatibility

Kanto in Motion includes presentation-only compatibility for **Dex Radar 1.2.0** on both Gen 1 and Gen 2. Dex Radar remains completely unmodified and continues to own encounter collection, rates, levels, cursor/input, hotkeys, and closing behavior.

- **MODERN UI ON + MENU UI ON:** KIM presents the Dex Radar screen with the active Modern UI theme, font, frame, opacity, scale, density, and layout settings.
- **MODERN UI OFF** (or **MENU UI OFF**): Dex Radar keeps its original native presentation.
- The `D.RADAR` row injected by Dex Radar is retained in KIM's Modern Start Menu on both generations.
- KIM uses its HD menu icons when `POKEMON ICONS` is enabled and falls back to Dex Radar/native icon art when it is disabled or unavailable.

No files in the Dex Radar mod are patched or replaced.

## Optional compatibility

Kanto in Motion includes compatibility paths for optional external mods such as:

- Battle Art
- PotatoVoxel
- Typed Move Colors
- Useful Bag
- Advanced Box System
- HGSS_SPRITES
- supported translation/UI mods

External compatibility mod packages are not bundled. v1.6.0 directly vendors only the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter pieces used by KIM's Gen 2 Pokédex presentation; the separate Gen2 Clean UI mod is not required for that Pokédex presentation.

## Installation

### Installation / first launch

1. Install **Kanto in Motion v1.6.2** and enable it in Gen1Recomp.
2. On Red/Blue/Yellow and Gold/Silver/Crystal, KIM opens the **HD ASSET MANAGER** when the external HD battle pack is not already cached. On FireRed/LeafGreen, open OPTION and choose **ASSETS**.
3. Choose **A — DOWNLOAD** to download the official asset ZIP once, or **B — USE VANILLA / LATER** to continue without it.
4. After a successful install, the HD assets remain in Gen1Recomp's installation-scoped KIM cache and are reused by later KIM code updates.

The internal mod ID remains `animated_menu_pokemon`, so compatible KIM settings continue to carry forward.

### Updating from v1.5.x or earlier

The v1.6.0 release moves the large HD battle asset pack out of the KIM mod folder and into Gen1Recomp's persistent KIM cache. Because Gen1Recomp replaces the old mod directory during a normal update, the old embedded HD battle assets are not carried forward automatically.

After updating to v1.6.0, KIM will offer the **one-time HD asset download** on first launch. Once that download finishes, the asset pack lives outside the KIM mod folder and is reused by future KIM updates, so normal updates after v1.6.0 no longer require downloading the large asset pack again.

### Downloadable HD battle assets

The large HD Pokémon battle sprite sheets and HD battle backgrounds are no longer stored inside the normal KIM release ZIP. KIM's small battle-support assets, trainer art, UI art, effects, move-animation resources, icons, and code remain packaged with the core mod.

The **HD ASSET MANAGER** downloads the official `HaseoSora/Kanto-in-Motion-Assets` release as one temporary ZIP, verifies `asset-pack.json`, extracts only its `assets/` payload into KIM's installation-scoped cache, and deletes the temporary ZIP after a successful install.

- **A — DOWNLOAD:** checks the official tagged asset release and starts the one-time ZIP download.
- **B — USE VANILLA / LATER:** continues without downloading; missing HD battle artwork falls back safely where supported.
- **B while downloading:** cancels the temporary ZIP download and continues without the HD pack.
- Extraction runs incrementally after the ZIP download completes.
- **R/B/Y + G/S/C:** **KANTO IN MOTION → ASSET MANAGER** reopens the installer at any time.
- **FR/LG:** use **OPTION → ASSETS** to open the same manager.
- **R/B/Y + G/S/C installed pack:** press **B — REMOVE**, then confirm with **A — REMOVE** to delete KIM's cached HD Pokémon/background pack.
- **FR/LG installed pack:** press **A — REMOVE** from **ASSETS**, then confirm with **A — REMOVE**. **B — CLOSE** returns to OPTION.
- Removing the pack is useful for reclaiming storage or repairing a corrupted cache.
- After removal, KIM does not force another download. Choose **A — DOWNLOAD AGAIN** immediately or reopen **ASSET MANAGER** later to reinstall the pack. Restarting Gen1Recomp after removing/reinstalling assets is recommended so any already-loaded artwork is refreshed.
- Existing cached assets are reused automatically; ordinary KIM code updates do not redownload the pack.
- **Portable mode is supported:** when `portable.txt` is active, KIM keeps Gen1Recomp's normal asynchronous ZIP downloader, then reopens the completed temporary ZIP through Gen1Recomp's native file helper for extraction. Final HD assets still live in portable-aware `mod.cache`, and the temporary ZIP is deleted after install/cancel/error. Normal installs keep the standard streamed temporary-ZIP path.
- **FR/LG mobile download handoff:** Android/iOS FireRed/LeafGreen uses the same engine-owned native temporary-ZIP handoff after Gen1Recomp's binary-safe downloader finishes, avoiding a Game3 mobile sandbox mismatch between the worker-owned save directory and the mod-visible filesystem. Desktop FR/LG keeps the normal raw filesystem path.

KIM requires the **NETWORK** permission only for the optional HD asset download path.

## Credits

- **Animated Pokémon battle sprites — Battle Sprites Reloded**
  - Creator: **JDChaos**
  - https://forums.pokemmo.com/index.php?/topic/142585-battle-sprites-reloded/

- **HD Rescaled Pokémon Icons — LockeGriss and contributors**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/

- **Charizard and Cyndaquil-family icon edits — HaseoSora**
  - https://forums.pokemmo.com/index.php?/topic/183919-hd-rescaled-icons/#comment-2173491

- **Animated Trainer Card badges — xpixelpriorx**
  - https://www.deviantart.com/xpixelpriorx

- **Gen1 Modern UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen1-modern-ui

- **Gen2 Clean UI — ArmstrongThomas**
  - https://github.com/ArmstrongThomas/gen2-clean-ui
  - v1.6.0 vendors the Gen2 Clean UI 0.4.1 Pokédex adapter/presenter used by KIM's Gen 2 Pokédex presentation.

- **Kanto Rework Suite — Faendra**
  - https://github.com/Faendra/kanto-rework-suite

- **Poké Ball Colorfix — keberos**
  - https://github.com/keberos/pokeball-colorfix

- **Dex Radar — Zetto22**
  - https://github.com/Zetto22/dex_radar
  - Optional external mod; KIM provides presentation-only compatibility and does not modify Dex Radar.

## Disclaimer

Kanto in Motion is an unofficial fan-made mod and is not affiliated with or endorsed by Nintendo, Game Freak, Creatures Inc., or The Pokémon Company.

### Slim-core asset split note
The downloadable HD pack contains only the large HD Pokémon battle sprite sheets and HD battle backgrounds. KIM's small battle-support assets (including selectable player trainer frames/animations) remain packaged with the core mod so battles can initialize safely before/without the HD pack.
