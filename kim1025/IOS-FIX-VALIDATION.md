# Preserved mobile fixes — 1.7.7

Retained production code covers physical-pixel canvas sizing, renderer/viewport alignment, portrait and landscape arena framing, authored player/enemy ground anchors, the mobile player compensation correction, screen-position lift, aspect artwork transforms, native text/HUD placement, graphics-stack cleanup before touch controls, current/legacy world orientation, trainer size and platform placement, and native catch/move targets.

The trainer remains independent from Pokémon sprite ownership. Selecting a custom trainer with 1025Dex battle sprites now uses the same accepted placement. Its GPU bounds were checked at 1320×2868 and 660×1434. Native/1025Dex picture hooks are called on every source pass even when both pictures are relocated.

The regression suites verify mobile orientation and geometry using Gen1Recomp 0.3.71 source, including the renderer's real endFrame. This is not physical iPhone validation.
