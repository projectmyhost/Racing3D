# MASTER PROMPT — Build RACEZONE 2D Racing Game in Godot

You are a senior Godot 4.x game developer, UI/UX designer, and 2D game artist. Build a complete, runnable **2D racing game prototype** named **RACEZONE**, using GDScript and Godot 4.x.

## Files you must read first

1. Read `design.md` completely. It is the source of truth for layout, visual direction, interactions, settings, persistence, and acceptance criteria.
2. Inspect `reference_home.png`. Match its composition and visual language closely: sunset city/pit-lane background, profile at the upper-left, currency and utility icons at the upper-right, event card at the left, large yellow Play CTA at the right, vertically stacked secondary racing menu buttons, low wide car illustration, and bottom utility navigation.
3. Do not skip requirements because they appear in another document. If any implementation choice conflicts with `design.md`, follow `design.md`.

## Core objective

Create an actually playable, polished, offline-first **2D** racing game home screen and menu system. The result must be a working Godot project, not a design mockup, pseudo-code, or a flat screenshot.

**Hard constraints:**
- Strictly 2D. Do not create 3D nodes, 3D models, 3D cameras, 3D-rendered cars, or pseudo-3D menus.
- Do not use `reference_home.png` as a flattened full-screen UI. Use it only as an art/layout reference. Rebuild all interface elements as independent Godot Controls so they can be hovered, focused, clicked, updated, and tested.
- Every visible button must have a meaningful, working action and a destination/content page.
- All profile, currency, garage, progression, customization, and settings data must persist locally under `user://`.
- No real payment, web API, account login, multiplayer server, or internet dependency. Coin and diamond top-ups are free offline demo rewards.
- Do not leave TODOs, inert controls, fake settings, or placeholder menu pages.

## Visual target

Reproduce the reference as a professional 2D arcade racer interface. Use a layered 2D sunset pit-lane scene with city silhouettes, fence, barriers, stadium lights, and a side-view 2D racing coupe. Use dark navy/champagne-black panels, chamfered racing shapes, metallic outlines, diagonal speed stripes, checkered flag details, bright golden-yellow primary actions, warm orange accents, and controlled red status badges. Typography should be bold, condensed, italic for display headings, and clean/legible for body labels. Avoid generic rounded-card UI, plain rectangular buttons, excessive gradients, random neon, and generic AI-generated dashboard patterns.

Reference composition at 1672×941 (16:9):
- Profile card top-left.
- Coin, diamonds, inbox and settings top-right.
- Racing Festival card below the profile.
- Side-view 2D car as the main hero, low center-left.
- Oversized yellow PLAY button at upper-right of the car.
- Garage, Shop, Achievements and Leaderboard stacked beneath Play.
- Daily Login lower-left.
- News, Customize and Quit in a compact bottom-right footer.

Use a responsive anchor/container-based layout. It must remain readable at 1920×1080, 1600×900, 1366×768 and 1280×720. The reference image is 1672×941; preserve its proportions rather than copying its pixel positions blindly.

## Required project architecture

Create a clean project with separate scenes and scripts. At minimum include:
- Main and HomeScreen scenes.
- Profile, Garage, Shop, Achievements, Leaderboard, Settings, Customize, News, Inbox, Daily Rewards, Race Setup and Race scenes/pages.
- Reusable racing button component with normal/hover/pressed/disabled/focus states.
- Confirm dialog and toast notification component.
- SaveManager, AudioManager and Navigation autoloads.
- A consistent global Theme.

Keep code modular. Use signals instead of fragile cross-scene references. Use typed GDScript where useful. Keep UI content/data separate from layout where practical.

## Functional requirements — no dead buttons

Implement every requirement in `design.md`. Pay special attention to these flows:

### Profile
- Profile card opens a real profile page.
- Show player avatar, name, level, XP, races, wins, best time and distance.
- Allow changing display name and selecting one of at least four avatar presets.
- Name input is trimmed and validated to 3–16 characters.
- SAVE persists the new name and shows success feedback.
- CANCEL discards unsaved edits and restores the previously saved name.
- Invalid input must display an error and must not close the page or overwrite the saved name.
- Profile and avatar must survive app restart.

### Offline currency / free top-up
- Start with 12,750 coins and 120 diamonds.
- Plus on the coin counter opens a Free Coin Center with free +250, +1,000 and +5,000 packages.
- Claiming a package adds the correct amount immediately, updates all displayed balances, writes the save file, and shows a toast.
- Plus on diamonds opens a Free Diamond Center with free +10, +25 and +50 packages.
- Clearly label both screens as offline/demo rewards. No real checkout or payment.
- Prevent negative balances, double-claim caused by double-click, and integer overflow.

### Header, event and home navigation
- Inbox opens a message page. Include welcome gift, event notice and update message. Gift can only be claimed once. Mark All Read clears the unread badge.
- Settings gear opens a full Settings page.
- Racing Festival card opens event details, displays reward/goal/progress, and has a working GO RACE action.
- PLAY opens Race Setup.
- Garage opens car ownership/selection/purchase.
- Shop opens local cosmetic inventory and purchase/equip flows.
- Achievements show at least six progress-based achievements and one-time coin rewards.
- Leaderboard shows a clearly labeled LOCAL leaderboard with local records and CPU entries; filters must work.
- Daily Login opens a 7-day calendar and gives one reward per local calendar day only.
- News opens local article cards and article details.
- Customize shows a live 2D vehicle preview with paint, decal and wheel options; Apply persists; Cancel discards pending changes.
- Quit asks for confirmation; only the confirm action exits the application.

### Garage and shop economy
- At least three offline cars: one free starter car and at least two cars purchasable with coins.
- Show Speed, Acceleration and Handling stats.
- Buying checks balance, deducts exact cost, saves ownership and prevents duplicate purchases.
- Selecting an owned car updates the active car used in home and race setup.
- Shop has locally available paints/decals/wheels/bundle; BUY/OWNED/EQUIPPED states must be truthful and functional.

### Settings — every control must actually work

Build a full page with categories:

**Audio:** Master, Music and SFX volume sliders; Mute All, Music and UI SFX toggles; Test Sound. Wire values to actual AudioServer buses/AudioManager and persist them.

**Display/Graphics:** Windowed/Fullscreen/Borderless; supported resolution selector; VSync; FPS cap 30/60/120/Unlimited; 2D Graphics Quality (controls particles/decorative effects/background detail); UI Scale 80–120%; Screen Shake; Reduced Motion. Apply the real platform-supported setting. Never show an option that silently does nothing.

**Gameplay:** steering sensitivity 1–10; keyboard/mouse control scheme if mouse controls are implemented; show race tutorial; auto accelerate; confirm before leaving a race. These settings must affect the actual race behavior or UX.

**Accessibility/Language:** Indonesian/English across the entire UI; High Contrast UI; Color Assist palette; Normal/Large text. Implement a centralized translation/key system; do not translate only the page title.

**Data/Support:** Restore Defaults (settings only, with confirmation); Reset Save Data (strong double confirmation and clear warning); Credits/version page. Reset Save Data must not happen from a single accidental click.

Persist settings. On launch, apply saved settings before showing HomeScreen. Sliders and toggles must reflect the saved value. Back/Cancel/Apply semantics must be consistent.

### Hover and sound
- Use one reusable `RaceButton` component across all buttons, including buttons created dynamically in lists/dialogs.
- On pointer enter: show a crisp hover highlight, accent border, restrained glow, tiny scale/offset animation, and play `ui_hover.wav` once.
- On pointer exit: return smoothly to normal state.
- On press: show a pressed state and play `ui_click.wav` once.
- Disabled buttons do not play click sound. Focus state must be visible for keyboard navigation.
- Avoid connecting the same signal more than once. Do not replay hover SFX every frame while the pointer stays on the button.
- Include real local audio assets. If no audio assets are supplied, generate short original UI blips/clicks programmatically and save them in `res://assets/audio/`; do not leave missing-file references.
- Audio controls and mute must affect these sounds.

### Playable race flow
- PLAY → Race Setup → Start Race → playable 2D Race → Result → Retry or Home.
- Provide at least one complete track with road boundaries/collision; other tracks may be simpler but distinct.
- Recommended race view: top-down 2D. Use keyboard A/D or arrows to steer, W/Up to accelerate, S/Down/Space to brake.
- Include countdown, timer, lap counter, pause/resume, restart, finish condition and result panel.
- Apply selected car, settings, track and difficulty.
- Save best local time and update achievements/event progress.
- Ensure rewards cannot be claimed more than once for the same race session.

## Persistence

Use ConfigFile or robust local JSON under `user://`. Follow the complete key list and defaults in `design.md`. Handle first launch, missing keys, corrupted save file, and future schema changes safely. Save immediately after important changes. Use centralized currency functions such as `add_coins()` and `spend_coins()`; never modify balances ad hoc in unrelated UI scripts.

## Implementation order

1. Read the reference and spec; create the project structure and Theme.
2. Implement SaveManager, AudioManager, Navigation, reusable button, modal, toast.
3. Build HomeScreen visual composition and ensure resize behavior.
4. Implement Profile and free currency centers with persistence.
5. Implement Inbox, Event detail, Daily Login, News and Quit confirmation.
6. Implement Garage, Shop, Achievements, Leaderboard and Customize.
7. Implement complete Settings page and verify each control changes real behavior.
8. Implement Race Setup, playable 2D race, result, records and progression.
9. Test all interactions, settings, save/reload, hover/click sounds, keyboard focus and all target resolutions.
10. Fix visual polish, spacing, typography, disabled states, focus order and runtime errors.

Do not stop after creating the home page. Complete the flows end-to-end.

## Required delivery

- A runnable Godot 4.x project folder with `project.godot`.
- All scenes, scripts, themes, original 2D assets, and local audio assets used by the project.
- `design.md` included at the project root.
- `README.md` with Godot version, how to open/run, controls, save location, and feature summary.
- No missing resource warnings, no red runtime errors during normal use, and no dead buttons.

Before declaring completion, walk through the acceptance checklist in `design.md` item by item. Fix every failure you can. Report any limitation honestly rather than claiming an unimplemented feature works.

**Build it as a real 2D game UI with working systems, not as a static concept image.**
