# KIM1025 1.7.16 — player behind translucent menus

Native Fit player Pokemon are drawn into the full battlefield before the menu, bypassing the stock row/menu clipping. Their baseline follows the HD player platform at native row 110, leaving the lower 14 rows behind the menu at row 96. Transparent battle menus reveal the overlapping sprite. Native provider and animation calls remain active; source player duplication is suppressed. Trainer placement is unchanged.

Validation: all 20 suites pass and 46 Lua files compile. A production compositor regression verifies player-only replay, menu-clip bypass and restored state. Full live gameplay remains unverified.

Replace the entire old mod folder, keep downloaded assets, and restart.
