# Settings submenu preview

KIM1025 settings now use separate Pokemon, Battle, Interface, Title Screen and Advanced pages. Battle has General, Backgrounds, Pokemon / Trainer Size, Shadows, HUD and Menus / Text submenus. Interface has General, Appearance, Fonts / Text, Screens and Controls submenus. KIM Assets stays on the main KIM1025 settings page.

This is a development preview, not a published release. Existing option keys, defaults and saved values are preserved. Back returns to the previous submenu and selection. The mod manager uses the native option callbacks for toggles, choices, numbers and reset; other mods retain their existing options.

Validation: 19 automated suites passed, including 17 submenu navigation and save callback checks; all 90 Lua files compile. These checks do not establish a fix for the reported iOS battle animation problem. The sprite implementation is unchanged from v1.7.5 and the iOS issue remains unresolved.
