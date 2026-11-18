# Sunset Street Racing — Project Handoff & Context Guide

> **Cara Pakai di Laptop Baru (Antigravity):**
> 1. Buka folder project `racing` ini di Antigravity laptop baru.
> 2. Buka chat baru, lalu copy-paste prompt di bawah ini:
>
> ```text
> Baca file HANDOFF.md dan (jika perlu detail riwayat) docs/handoff/conversation_log.md sebagai konteks lengkap project Godot 4.7 ini. Ikuti semua aturan penting di HANDOFF.md. Setelah selesai membaca, konfirmasi singkat bahwa kamu siap lanjut.
> ```

---

## 1. Informasi Project & Engine

- **Nama Game:** Sunset Street Racing
- **Engine:** Godot Engine `4.7.1-stable`
- **Renderer:** `GL Compatibility` (`gl_compatibility`, OpenGL 3.3)
- **Resolusi Target:** `1920 × 1080` (`stretch/mode="canvas_items"`, `stretch/aspect="expand"`)
- **Main Scene:** `res://scenes/main/home_screen.tscn`
- **In-Game Race Scene:** `res://scenes/race/RaceTrack3D.tscn`
- **Autoload:** `PlayerProfile` (`res://scripts/core/player_profile.gd`)
- **Physics:** `common/physics_interpolation=true`, `common/physics_jitter_fix=0.0`

---

## 2. Arsitektur & File Penting

### Core & Profile
- `project.godot` — Konfigurasi utama engine, renderer, autoload, physics interpolation.
- `scripts/core/home_screen.gd` — Controller utama Homescreen (lighting, koneksi UI ke `ShowcaseCar`, load profil).
- `scripts/core/player_profile.gd` & `scripts/core/player_profile_data.gd` — Sistem profil pemain (nama, XP, level, coins, gems, mobil unlocked & equipped).
- `data/player_profile.tres` — Default save profil pemain (mobil aktif saat ini: `porsche_mission_x` / sesuai save `user://player_profile.tres`).
- `scripts/core/quality_settings.gd` — Pengaturan kualitas grafis (`LOW`, `MEDIUM`, `HIGH`). **Tidak boleh meng-override `Engine.max_fps`**.

### Kendaraan & Physics
- `vehicles/core/VehiclePhysicsCore.gd` — Core fisika kendaraan berbasis `RigidBody3D` dengan 4-wheel independent raycast suspension, anti-roll bar, friction-circle tire dynamics, automatic transmission, slope hold, dan auto-unflip.
- `vehicles/core/VehicleVisualAdapter.gd` — Rig visual roda (dual-pivot steer + spin), suspensi roda, dan body roll/pitch/heave.
- `vehicles/core/VehicleMaterialEnhancer.gd` — Pengaturan material PBR kendaraan & custom paint color.
- `scripts/race/RaceCar3D.gd` — Subclass `VehiclePhysicsCore` untuk in-game (tire smoke particles, `ReflectionProbe` mode `UPDATE_ONCE`, audio disabled).
- `scripts/vehicle/showcase_car.gd` — Controller mobil 3D di panggung Homescreen.

### Race Track, Camera & In-Game HUD
- `scripts/race/RaceTrack3D.gd` — Controller balapan, lap & checkpoint, dan **ChaseCamera** (pakai `car.get_global_transform_interpolated()` + `PHYSICS_INTERPOLATION_MODE_OFF` + exponential smoothing + physics-thread raycast).
- `scripts/race/CollisionGuard.gd` — Audit collider map saat runtime agar tidak ada ghost collider.
- `scripts/race/ModernRacingHUD.gd` — HUD balapan (Lap/Timer, Exit Race, Settings/Pause modal, Best Lap, Pos).
- `scripts/race/ModernMinimap.gd` — Minimap GPS real-time dengan spline sirkuit dan panah posisi pemain (interpolated).
- `scripts/race/ModernSpeedometer.gd` — Speedometer analog + digital RPM/Gear/KMH/N2O dengan exponential smoothing.

### Homescreen UI & Camera
- `scenes/main/home_screen.tscn` & `scenes/ui/home_screen_ui.tscn`
- `scripts/ui/home_screen_ui.gd` — Controller seluruh UI Homescreen, Garage, Tuning, Paint Shop, Settings (termasuk Smart FPS/VSync untuk 30/60/120/Unlimited), dan Profile.
- Widget UI custom (dibuat procedural/vektor 100%, **BUKAN cropping gambar**):
  - `scripts/ui/profile_card_widget.gd`
  - `scripts/ui/top_nav_bar.gd`
  - `scripts/ui/currency_bar.gd`
  - `scripts/ui/settings_hex_btn.gd`
  - `scripts/ui/notif_ping_widget.gd`
  - `scripts/ui/daily_missions_ui.gd`
  - `scripts/ui/mail_btn_ui.gd`
  - `scripts/ui/news_banner_ui.gd`
  - `scripts/ui/season_pass_ui.gd`
- `scripts/camera/showcase_camera_rig.gd` — Kamera orbit 360° interaktif di Homescreen.

### Map & Environment
- `assets/models/environment/city_map/source/Untitled.glb` — Map kota utama yang dipakai di Homescreen dan In-Game (`RaceTrack3D.tscn`).
- `assets/models/environment/city_map/source/Untitled_Image_49.png.import` — Konfigurasi import tekstur aspal jalanan (**WAJIB dijaga**: `compress/mode=0`, `compress/normal_map=2`, `roughness/src_normal=""`).

---

## 3. Riwayat Pekerjaan & Fix yang Sudah Selesai

1. **Fix Mobil Kia Seltos Turbo Terbalik (W mundur / S maju):**
   - Orientasi/yaw model dan arah roda Kia Seltos sudah diperbaiki agar kontrol W = maju, S = mundur sesuai standar.
2. **Audio / Sound Mobil (Saat ini Sengaja Dimatikan):**
   - Sempat dicoba implementasi engine sound (termasuk MP3 untuk Porsche Mission X), lalu atas permintaan user di-**undo sepenuhnya** agar **tidak ada sound mobil sama sekali** untuk saat ini (`_setup_audio()` & `_update_engine_audio()` di `RaceCar3D.gd` sengaja kosong/disabled).
3. **Remake UI Homescreen (100% Native/Procedural — Tanpa Cropping):**
   - Layout, tipografi, bentuk card miring (*slanted*), badge `NEW!`, tombol `PLAY` sampai `PROFILE`, top nav bar (`HOME`, `CAREER`, `MULTIPLAYER`, `SHOP`, `COMMUNITY`), currency bar, `DAILY MISSIONS`, `MAIL`, `NEWS & UPDATES`, dan `SEASON PASS` sudah dibuat ulang secara native tanpa mengubah background 3D homescreen.
   - Tombol baru (selain `PLAY` sampai `PROFILE`) hanya visual UI saja (tanpa route).
   - 2 card sebelah kanan (`LIMITED TIME EVENT / NIGHT SPEEDRUN` dan `ONLINE FRIENDS`) sudah **dihilangkan** sesuai permintaan user.
4. **Import McLaren 650S GT3 (Di-Undo):**
   - Sempat diimpor, lalu atas permintaan user di-**undo sepenuhnya** dan dikembalikan ke kondisi sebelum import.
5. **Fix Bug Jalanan Berwarna Kuning-Hijau (Homescreen & In-Game):**
   - **Root cause:** `Untitled_Image_49.png` dipakai sebagai albedo jalanan sekaligus normal map oleh material lain di `Untitled.glb`, sehingga Godot otomatis mengubah `compress/normal_map=1` (VRAM RGTC 2-channel yang membuang channel Blue → aspal abu-abu jadi kuning/hijau neon).
   - **Fix:** Diubah di `assets/models/environment/city_map/source/Untitled_Image_49.png.import` menjadi `compress/mode=0`, `compress/normal_map=2` (Disabled permanen), `roughness/src_normal=""`, cache `.ctex` lama dihapus & dire-import ulang. Terverifikasi bersih di Homescreen dan In-Game.
6. **Fix Bug Stuttering ("Ngendat-Ngendat") di 120 FPS (serta Stabilisasi 30 & 60 FPS):**
   - **Root cause:**
     1. `ChaseCamera` membaca `car.global_position` (60 Hz un-interpolated) di `_process()` (120 Hz) sambil double-interpolated + world-space lerp.
     2. `ReflectionProbe.UPDATE_ALWAYS` di `RaceCar3D.gd` merender ulang kota 6x per frame (720x/detik di 120 FPS).
     3. VSync bentrok dengan `Engine.max_fps = 120` di monitor 60Hz/144Hz, dan `physics_jitter_fix` default bentrok dengan `physics_interpolation=true`.
   - **Fix:**
     - `RaceTrack3D.gd`: `camera.physics_interpolation_mode = OFF`, baca `car.get_global_transform_interpolated()`, exponential smoothing `1.0 - exp(-k * dt)`, raycast obstacle dipindah ke `_physics_process()`.
     - `RaceCar3D.gd`: `ReflectionProbe.UPDATE_ONCE`, `enable_shadows = false`.
     - `project.godot`: `common/physics_jitter_fix=0.0`.
     - `home_screen_ui.gd`: Smart VSync pacing untuk 30 / 60 / 120 / Unlimited FPS berdasarkan refresh rate layar.
     - `quality_settings.gd`: Hapus paksaan `Engine.max_fps = 60`.
     - `showcase_camera_rig.gd`, `showcase_car.gd`, `ModernMinimap.gd`, `ModernSpeedometer.gd`: Interpolasi & exponential smoothing disamakan.
   - **Terverifikasi benchmark RTX 2050:** 30.0 FPS, 60.0 FPS, dan 120.0 FPS berjalan stabil tanpa stutter.

---

## 4. Aturan Penting & Preferensi User (WAJIB DIPATUHI)

- **Bahasa komunikasi:** Bahasa Indonesia santai, singkat, jelas, dan cepat (user mengejar deadline).
- **JANGAN mengotak-atik background 3D Homescreen** kecuali diminta secara eksplisit.
- **JANGAN pernah cropping/slicing screenshot untuk bikin tombol UI** — semua tombol/card UI harus dibuat native/kode/vektor rapi di Godot.
- **JANGAN menyalakan/menambah audio mesin mobil** kecuali user meminta lagi.
- **JANGAN ubah `Untitled_Image_49.png.import`** kembali ke `compress/normal_map=0` atau `1` (nanti jalanan kuning lagi).
- **JANGAN ubah `ReflectionProbe`** di `RaceCar3D.gd` kembali ke `UPDATE_ALWAYS` (nanti 120 FPS stuttering lagi).
- Saat mengubah script kamera yang berjalan di `_process()`, selalu gunakan `get_global_transform_interpolated()` dan `PHYSICS_INTERPOLATION_MODE_OFF` pada node kamera.

---

## 5. File Log Percakapan Lengkap

Jika agent di laptop baru membutuhkan detail percakapan sebelumnya kata per kata:
- **Versi Ringkas & Mudah Dibaca:** `docs/handoff/conversation_log.md`
- **Versi Mentah Lengkap (JSONL):** `docs/handoff/transcript.jsonl`

