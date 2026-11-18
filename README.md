# RACEZONE — 2D Arcade Racing Game

A complete, polished, offline-first **2D arcade racing game** built in **Godot Engine 4.x** with GDScript. Inspired by classic console arcade racers with high-fidelity 2D UI, responsive controls, customizable livery, progression systems, and playable top-down circuit racing.

---

## 🎮 Engine Compatibility & Requirements

- **Engine Version:** Godot Engine 4.x (Tested on **Godot 4.3 / 4.4 / 4.7.1**)
- **Platform:** Windows, macOS, Linux (Cross-platform 2D)
- **Target Resolution:** 1600×900 (Canvas Items stretch mode, Aspect: `keep`), responsively adapts to 1920×1080, 1366×768, and 1280×720
- **Mode:** Pure 2D (`Control`, `Node2D`, `CanvasItem`, `CharacterBody2D`). Zero 3D dependencies or models.

---

## 🚀 How to Open, Run, and Play

### In Godot Editor:
1. Launch **Godot Engine 4.x**.
2. Click **Import** and browse to this project directory: `c:\Users\Pongo\OneDrive\Documents\racing\`.
3. Select `project.godot` and click **Import & Edit**.
4. Press **F5** (or the **Play** button in the top-right of the editor) to run the project.

### From Command Line:
```powershell
godot --path "c:\Users\Pongo\OneDrive\Documents\racing"
```
Or with Godot console binary:
```powershell
& "Godot_v4.7.1-stable_win64_console.exe" --path "."
```

---

## ⌨️ Full Keyboard Controls

### 🏁 In-Race Controls (2D Driving)
| Key Binding | Action | Description |
|---|---|---|
| **W** / **Up Arrow** | Accelerate | Drives the car forward |
| **S** / **Down Arrow** / **Space** | Brake / Reverse | Slows the vehicle down or reverses |
| **A** / **Left Arrow** | Steer Left | Turns steering wheels left (scaled by Sensitivity) |
| **D** / **Right Arrow** | Steer Right | Turns steering wheels right (scaled by Sensitivity) |
| **Escape** / **P** | Pause Menu | Opens in-game pause menu (Resume, Restart, Exit) |

*Note: If **Auto Accelerate** is enabled in Settings, the car maintains throttle automatically while you focus on steering and braking.*

### 🖥️ Menu & Navigation Controls
| Key Binding | Action | Description |
|---|---|---|
| **Tab** / **Shift+Tab** / **Arrow Keys** | Focus Navigation | Moves focus between interactive buttons and cards |
| **Enter** / **Space** | Activate | Presses the currently focused button or item |
| **Escape** | Back / Cancel | Closes current subpage or dialog, returning to previous screen |

---

## 💾 Save System & Data Schema

All data persists locally and offline in the user directory:
- **Location:** `user://racezone_save.cfg`
  - Windows: `%APPDATA%\Godot\app_userdata\RACEZONE\racezone_save.cfg`
  - macOS: `~/Library/Application Support/Godot/app_userdata/RACEZONE/racezone_save.cfg`
  - Linux: `~/.local/share/godot/app_userdata/RACEZONE/racezone_save.cfg`

### Configuration Schema (`racezone_save.cfg`)

```ini
[player]
name="RacerX"
avatar_id="avatar_1"
level=12
xp=420

[economy]
coins=12750
diamonds=120

[garage]
selected_car="starter_gt"
owned_cars=["starter_gt"]

[customize]
paint_id="silver_red"
decal_id="stripe_01"
wheel_id="sport_01"

[progress]
races_completed=0
wins=0
event_races_completed=0
claimed_achievements=[]
last_daily_claim=""
daily_streak=0
claimed_welcome_gift=false

[records]
# Best lap and total race times stored per track
sunset_circuit_best_lap=0.0
harbor_run_best_lap=0.0
neon_loop_best_lap=0.0

[settings]
master_volume=1.0
music_volume=0.7
sfx_volume=0.85
mute_all=false
music_enabled=true
ui_sfx_enabled=true
window_mode="windowed"
resolution="1600x900"
vsync=true
fps_limit=60
graphics_quality="high"
ui_scale=1.0
screen_shake=true
reduced_motion=false
steering_sensitivity=5
control_scheme="keyboard"
auto_accelerate=false
show_race_tutorial=true
confirm_before_leaving_race=true
language="id"
high_contrast=false
color_assist="off"
text_size="normal"
```

---

## 🌟 Feature Summary

### 1. 2D Arcade Racing Experience
- Top-down 2D physics car controller with acceleration, realistic drifting, dynamic turn handling, and boundary collision.
- 3 Distinct Tracks: **Sunset Circuit** (Full circuit with barriers & checkpoints), **Harbor Run**, and **Neon Loop**.
- 3 Difficulties: **Easy**, **Normal**, **Hard**.
- In-race HUD with 3-2-1-GO animated countdown, digital speedometer, current/best lap timer, lap counter, collision screen shake, and start tutorial banner.
- Post-race results screen awarding coins, checking record lap times, and triggering achievement & event milestones.

### 2. High-Fidelity Racing Home Screen
- Faithfully modeled after the reference composition with layered 2D parallax sunset sky, city silhouette, pit lane asphalt, and animated stadium floodlights.
- 2D hero showcase car with ambient idle vibration and underglow.
- Interactive Profile card with real-time level/XP bar and editable racer identity.
- Currency counters with animated updates and toast notifications.

### 3. Economy & Progression
- **Free Offline Top-Up Centers:** Demo coin (+250, +1,000, +5,000) and diamond (+10, +25, +50) claim centers.
- **Garage:** Multi-car selection and coin purchase system with real-time attribute specs (Speed, Acceleration, Handling).
- **Shop:** Cosmetic store offering paints, decals, wheels, and aerodynamic bundles.
- **Daily Login:** 7-day reward calendar with persistent claim timestamps and streak logic.
- **Racing Festival Event:** Live offline event card with objectives, lap tracking, and quick "GO RACE" navigation.
- **Achievements:** 6 functional progression achievements with coin rewards and persistent claim tracking.
- **Local Leaderboard:** Track records, CPU benchmark times, and "My Records" filter.

### 4. Customization & Identity
- Live 2D vehicle customization screen previewing body paints, decal liveries, and rims with real-time Apply/Reset/Cancel flow.
- Profile editor with 4 avatar portraits and 3–16 character validation.
- Inbox system with 3 local messages, unread badge notification, one-time Welcome Gift claim, and "Mark All Read".
- News center with local lore and patch notes.

### 5. Settings & Accessibility
- **Audio:** Master, Music, SFX volume sliders, individual mute toggles, and "Test Sound" button.
- **Display:** Window Mode (Windowed, Fullscreen, Borderless), resolution presets, VSync, FPS limits (30/60/120/Unlimited), Graphics Quality, UI Scale (80%–120%), Screen Shake, and Reduced Motion.
- **Gameplay:** Steering Sensitivity (1–10), Keyboard/Mouse control toggle, Show Race Tutorial, Auto Accelerate, and Confirm Before Leaving Race.
- **Accessibility:** Bilingual localization (**English / Bahasa Indonesia**), High Contrast mode, Color Assist (Off, Protanopia, Deuteranopia), and Text Size scaling (Normal / Large).
- **Data & Support:** "Restore Defaults" (safe settings reset), "Reset Save Data" (double-confirmation protected wipe), and Game Credits.

### 6. Audio Design & Feedback
- Synthesized procedural arcade UI audio assets (`ui_hover.wav`, `ui_click.wav`, countdown & engine sounds).
- Uniform `RaceButton` component ensuring clean hover scaling, focus outlines, and single-trigger SFX playback.

---

## 🏛️ Architecture Overview

```text
res://
├── scenes/
│   ├── main/                 # Main bootstrap scene & window initialization
│   ├── home/                 # HomeScreen layout & visual composition
│   ├── profile/              # Profile & Avatar edit dialog
│   ├── garage/               # Car ownership & purchase garage
│   ├── shop/                 # Cosmetic parts shop
│   ├── achievements/         # Achievements listing & claim dialog
│   ├── leaderboard/          # Local records & leaderboard table
│   ├── settings/             # 5-Tab settings screen
│   ├── customize/            # Live 2D vehicle livery customization
│   ├── news/                 # News articles and update patch notes
│   ├── inbox/                # Mailbox & one-time gift claim
│   ├── rewards/              # 7-Day daily login streak calendar
│   ├── race/                 # RaceSetupScreen, RaceScene, Car, Track & HUD
│   └── common/               # ConfirmDialog, Toast, Coin/Diamond Centers
├── scripts/
│   ├── autoload/             # Singletons (SaveManager, AudioManager, Navigation, ToastManager)
│   ├── system/               # Localization (EN/ID dictionary manager)
│   ├── ui/                   # RaceButton component, Panel styling
│   └── race/                 # 2D Car physics, track logic, lap checkpoints
├── assets/
│   ├── art/                  # 2D backgrounds, car sprites, textures, icons
│   └── audio/                # UI hover/click blips, countdown, engine sfx
└── theme/
    └── RacezoneTheme.tres    # Global racing UI theme (colors, chamfers, styles)
```

---

## 🛡️ Verification & Quality Assurance

All features are tested against Godot 4.x engine specifications with zero red console errors, complete keyboard accessibility, safe bounds checks, and robust data integrity protection.
