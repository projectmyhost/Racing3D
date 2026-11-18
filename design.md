# RACEZONE — 2D Racing Game Home Screen & UI Design Specification

> Dokumen implementasi untuk Godot Engine 4.x. Gunakan `reference_home.png` sebagai acuan visual utama. Spesifikasi ini menuntut UI yang benar-benar interaktif, bukan mockup atau screenshot yang ditempel sebagai satu gambar.

## 1. Tujuan produk

Buat game racing **2D murni** dengan home screen bergaya arcade racing premium. Nuansanya seperti game balap konsol/PC yang punya HUD kaya detail: latar kota saat sunset, pit garage, mobil balap 2D, panel gelap bertekstur, aksen kuning-oranye, tipografi racing italic/condensed, dan tombol dengan bentuk serta hierarki visual yang jelas.

Nama kerja game: **RACEZONE**. Nama ini boleh dibuat sebagai konstanta agar mudah diganti.

### Prinsip wajib

1. **2D only.** Gunakan `Control`, `CanvasItem`, `Sprite2D`, `AnimatedSprite2D`, `TileMapLayer`, `Polygon2D`, `Line2D`, dan node 2D Godot. Dilarang memakai 3D scene, `MeshInstance3D`, model 3D, kamera 3D, atau render mobil 3D.
2. Referensi adalah panduan komposisi dan art direction. Jangan menempel screenshot penuh sebagai background. Semua panel, label, ikon, tombol, angka, dan interaksi harus dibuat sebagai node UI terpisah.
3. Semua tombol yang terlihat harus aktif dan memiliki hasil yang jelas. Jangan tinggalkan tombol dekoratif, `TODO`, atau `print()` sebagai pengganti fungsi.
4. Interaksi mouse dan keyboard harus berfungsi. Tombol wajib memiliki keadaan normal, hover, pressed, disabled, dan focus.
5. Setiap tombol yang menerima hover memainkan SFX hover satu kali saat pointer masuk. SFX click dimainkan saat tombol ditekan. Jangan memainkan SFX berulang-ulang selama pointer diam di atas tombol.
6. Semua data penting disimpan secara lokal/offline. Tidak memerlukan akun, server, internet, iklan, atau payment gateway.
7. Coin top-up adalah **gratis untuk game offline**. Tidak ada pembayaran sungguhan, pembelian eksternal, atau klaim transaksi uang.
8. Layout harus responsif pada rasio 16:9, tetap terbaca pada ukuran jendela lebih kecil, dan tidak saling menimpa.

## 2. Acuan visual dan komposisi

### Art direction

- Genre visual: 2D arcade racing, ilustrasi game UI dengan outline tegas dan sedikit tekstur cetak/halftone.
- Latar: pit lane / area luar garasi balap, pagar pembatas sirkuit, lampu stadion, skyline kota, langit sunset ungu-jingga.
- Mobil: mobil sport balap **tampak samping 2D**, rendah dan lebar, warna putih-perak dengan strip merah/hitam. Mobil menjadi hero visual di area tengah-bawah. Boleh dianimasikan dengan idle bob kecil atau lampu yang berkedip halus.
- Jangan gunakan lighting/render realistis 3D. Hindari mobil dengan sudut kamera 3D/isometrik.
- Panel UI: navy gelap hampir hitam, bevel/chamfer pada sudut, garis tepi terang tipis, highlight atas, aksen garis diagonal seperti livery mobil.
- Tombol utama memakai kuning balap. Tombol sekunder memakai navy gelap, teks putih, ikon yang relevan, dan strip diagonal kecil.
- Gunakan ikon konsisten: mobil untuk Garage, keranjang untuk Shop, piala untuk Achievements, grafik untuk Leaderboard, koran untuk News, kaus untuk Customize, amplop untuk Inbox, roda gigi untuk Settings.

### Warna acuan

| Token | Warna | Pemakaian |
|---|---|---|
| `BG_NIGHT` | `#171827` | dasar panel / overlay |
| `PANEL` | `#24263A` | panel utama |
| `PANEL_LIGHT` | `#34364E` | highlight / panel sekunder |
| `INK` | `#10121D` | outline / shadow |
| `TEXT` | `#F4F2F2` | teks utama |
| `MUTED` | `#A8A9B8` | teks sekunder |
| `RACE_YELLOW` | `#FFB51B` | tombol Play / CTA / coin |
| `RACE_ORANGE` | `#F36A3D` | aksen sunset / warning |
| `RACE_RED` | `#C83B43` | badge / indikator |
| `SKY_PURPLE` | `#625A83` | langit / ambient |
| `SUCCESS` | `#62C58A` | status berhasil |

Jaga kontras teks. Teks kecil jangan menggunakan warna muted di atas panel yang terlalu terang.

### Tipografi

- Display/title: sans-serif condensed, bold, italic, uppercase. Kesan cepat dan teknis.
- Body/UI: sans-serif modern yang sangat terbaca.
- Angka currency, level, waktu, dan statistik memakai angka tabular/monospace bila tersedia.
- Gunakan maksimum dua keluarga font. Jangan memakai font futuristik yang sulit dibaca.
- Sediakan fallback font bawaan Godot jika font eksternal tidak tersedia. Jika mengambil font eksternal, pilih font berlisensi OFL dan simpan di folder project beserta catatan lisensinya.

### Grid dan area layout

Acuan gambar berukuran 1672 × 941 px, kira-kira 16:9. Gunakan ukuran desain dasar 1672 × 941 atau koordinat anchor yang proporsional. Untuk resolusi lain, gunakan `Control` anchors dan `Container`, bukan posisi absolut untuk semua elemen.

| Area | Posisi acuan | Isi |
|---|---|---|
| Header kiri | x 28–600, y 18–155 | avatar, nama, level, XP |
| Header kanan | x 990–1640, y 18–100 | coin, diamond, inbox, settings |
| Event card | x 25–495, y 175–345 | Racing Festival, countdown, trophy |
| Hero car | x 270–940, y 535–750 | mobil 2D samping |
| CTA kanan | x 1155–1640, y 315–455 | Play besar |
| Menu kanan | x 1180–1620, y 465–785 | Garage, Shop, Achievements, Leaderboard |
| Daily Login | x 15–505, y 805–905 | hadiah harian |
| Footer kanan | x 945–1650, y 810–905 | News, Customize, Quit |

Beri ruang kosong yang cukup di sekitar mobil agar tidak tertutup menu. Pada window yang lebih kecil, gunakan skala UI adaptif dan izinkan panel isi scroll bila perlu. Jangan mengecilkan teks sampai sulit dibaca.

## 3. Struktur scene yang direkomendasikan

Buat struktur modular seperti berikut (nama boleh disesuaikan, fungsi harus tetap ada):

```text
res://
  project.godot
  scenes/
    main/Main.tscn
    home/HomeScreen.tscn
    profile/ProfileScreen.tscn
    garage/GarageScreen.tscn
    shop/ShopScreen.tscn
    achievements/AchievementsScreen.tscn
    leaderboard/LeaderboardScreen.tscn
    settings/SettingsScreen.tscn
    customize/CustomizeScreen.tscn
    news/NewsScreen.tscn
    inbox/InboxScreen.tscn
    rewards/DailyRewardsScreen.tscn
    race/RaceSetupScreen.tscn
    race/RaceScene.tscn
    common/ConfirmDialog.tscn
    common/Toast.tscn
  scripts/
    autoload/SaveManager.gd
    autoload/AudioManager.gd
    autoload/Navigation.gd
    ui/RaceButton.gd
    ui/PanelFrame.gd
    ui/ToastManager.gd
    screens/*.gd
    race/*.gd
  assets/
    art/background/
    art/cars/
    art/icons/
    audio/ui_hover.wav
    audio/ui_click.wav
    audio/music_menu.ogg
    fonts/
  theme/RacezoneTheme.tres
```

### Autoload / singleton

Daftarkan melalui Project Settings → Autoload:

- `SaveManager`: load/save `user://racezone_save.cfg`, profil, currency, car, setting, klaim reward, achievement, dan local record.
- `AudioManager`: mengatur bus `Master`, `Music`, dan `SFX`; memainkan musik dan UI SFX; menerapkan volume/mute dari pengaturan.
- `Navigation`: pindah halaman, menjaga halaman sebelumnya, menyediakan tombol Back/Escape, dan mengelola transisi.
- `ToastManager` (opsional): notifikasi singkat seperti “Nama berhasil disimpan”, “+500 Coins”, “Koin tidak cukup”.

Gunakan sistem signal untuk komunikasi antarscene. Hindari satu script raksasa yang mengurus semua menu.

## 4. Home screen — elemen dan perilaku

### 4.1 Profile card — pojok kiri atas

Tampilan:
- Avatar portrait berbentuk frame persegi dengan border metalik.
- Nama pemain default `RacerX`.
- Level default `Lv. 12`.
- Progress XP contoh `420 / 1000` dengan progress bar kuning.
- Kartu gelap dengan garis diagonal dan aksen racing.

Aksi:
- Seluruh area profile card bisa diklik.
- Buka `ProfileScreen`, bukan hanya tooltip.
- Tampilkan nama, avatar pilihan, level, XP, total race, win, best time, dan total distance.
- Edit nama menggunakan `LineEdit`.
- Tombol **SAVE** menyimpan nama secara lokal dan kembali ke profil/home dengan toast sukses.
- Tombol **CANCEL** membuang perubahan yang belum disimpan dan mengembalikan nilai nama sebelumnya.
- Nama hanya boleh 3–16 karakter setelah `strip_edges()`. Tolak nama kosong. Tampilkan pesan validasi yang terlihat; jangan diam-diam mengubah nama.
- Pastikan klik Save tidak menutup profil bila validasi gagal.
- Nama baru tetap ada setelah game ditutup dan dibuka kembali.
- Pilihan avatar minimal 4 preset 2D. Pilihan avatar juga disimpan.

### 4.2 Coin dan Diamond — header kanan

- Coin awal: `12,750`.
- Diamond awal: `120`.
- Masing-masing tampil sebagai counter dengan ikon dan tombol plus kecil.
- Counter harus langsung refresh setelah nilai berubah.

**Tombol plus coin:** buka dialog/halaman `Free Coin Center` dengan pilihan:
- +250 Coins — gratis
- +1,000 Coins — gratis
- +5,000 Coins — gratis

Saat dipilih, tampilkan tombol `CLAIM FREE COINS`; setelah diklik, tambahkan coin ke saldo, simpan, update header, dan tampilkan toast. Tidak ada pembayaran uang sungguhan. Beri penjelasan kecil: “Offline demo — all coin packs are free.” Tambahkan cooldown harian opsional hanya bila dijelaskan; rekomendasi: **tanpa cooldown** agar mode testing benar-benar gratis.

**Tombol plus diamond:** buka `Free Diamond Center` yang juga memberi paket gratis (+10, +25, +50) agar tombol tidak menjadi dead end. Tulis “Offline demo — no real purchases”.

- Cegah angka menjadi negatif.
- Gunakan pemisah ribuan yang konsisten.
- Tambahkan batas aman saldo, misalnya 2,000,000,000, untuk mencegah overflow.

### 4.3 Inbox / Mail

- Ikon amplop di header kanan, badge merah jika ada pesan belum dibaca.
- Klik membuka `InboxScreen` berisi minimal 3 pesan lokal: welcome gift, event announcement, patch note.
- Klik pesan membuka detail isi pesan.
- Tombol `CLAIM` pada welcome gift memberikan hadiah satu kali; setelah diambil berubah menjadi `CLAIMED` dan tersimpan.
- Tombol `MARK ALL READ` menghapus badge dan menandai pesan dibaca.

### 4.4 Settings shortcut

- Ikon roda gigi membuka `SettingsScreen`.
- Jangan hanya memunculkan popup kecil. Gunakan halaman/panel penuh dengan kategori dan kontrol yang berfungsi.

### 4.5 Event card — Racing Festival

- Tampilkan label `EVENT`, judul `Racing Festival`, ilustrasi trophy, dan sisa waktu.
- Untuk game offline, countdown boleh berupa event demo tetap (misalnya `6d 12h left`) atau tanggal lokal yang dihitung; jangan bergantung server.
- Klik event membuka halaman detail: deskripsi event, hadiah, target contoh `Finish 3 races`, progress, dan tombol `GO RACE` yang membuka Race Setup dengan event challenge terpilih.
- Progress bertambah setelah race selesai.

### 4.6 PLAY — CTA utama

- Tombol paling besar dan paling mencolok, warna kuning.
- Bentuk panel racing dengan sudut chamfer/diagonal, checkered accent, tulisan `PLAY`, icon/chevron.
- Hover: highlight menyala, skala ringan (maks 1.025), sedikit naik, SFX hover.
- Pressed: turun 1–2 px, warna lebih gelap, SFX click.
- Klik membuka `RaceSetupScreen`.

### 4.7 GARAGE

- Klik membuka `GarageScreen`.
- Halaman menampilkan mobil 2D yang sedang dipilih, nama model, kategori, statistik Speed / Acceleration / Handling, status Owned/Locked, dan daftar mobil.
- Minimal 3 mobil offline: satu starter gratis, dua mobil yang dapat dibeli menggunakan coin.
- Tombol `SELECT` memilih mobil yang sudah dimiliki.
- Tombol `BUY` membeli mobil jika coin cukup; kurangi saldo, simpan ownership, dan pilih mobil setelah berhasil (atau tampilkan tombol Select setelah membeli).
- Jika coin tidak cukup, munculkan toast/dialog jelas.
- Mobil starter tidak dapat dijual. Jangan memungkinkan pembelian mobil yang sama dua kali.
- Kembali ke home dengan Back button dan Escape.

### 4.8 SHOP

- Halaman shop offline berisi item lokal, bukan katalog online.
- Minimal: paint finish, decal, wheel style, dan 1 bundle kosmetik.
- Setiap item memiliki preview, harga coin, tombol `BUY` / `OWNED` / `EQUIPPED`.
- Pembelian memeriksa saldo, mengurangi coin, menyimpan item, dan memberi toast.
- Item tidak boleh dibeli dua kali.
- Tidak boleh ada tombol Buy yang tidak punya aksi.

### 4.9 ACHIEVEMENTS

Minimal 6 achievement yang punya syarat dan reward nyata:
- First Lap — selesaikan 1 race.
- Rookie Driver — selesaikan 5 race.
- Clean Run — selesaikan race tanpa tabrakan (jika collision diimplementasikan).
- Speed Freak — capai kecepatan target.
- Collector — miliki 3 mobil.
- Festival Starter — selesaikan 3 event race.

Setiap kartu menunjukkan judul, deskripsi, progress, reward coin, status Locked/Ready/Claimed. Tombol `CLAIM` hanya aktif jika target tercapai. Claim menambah coin dan tersimpan. Achievement yang sudah diklaim tidak dapat diambil lagi.

### 4.10 LEADERBOARD

- Karena offline, tampilkan `LOCAL LEADERBOARD`, bukan leaderboard online palsu.
- Tampilkan tabel nama, track, waktu, dan tanggal.
- Data record pemain disimpan lokal; baris contoh CPU/bot boleh digunakan dan diberi label `CPU`.
- Filter track: All / Sunset Circuit / Harbor Run / Neon Loop.
- Sort waktu tercepat di atas.
- Tombol `MY RECORDS` memfilter hanya catatan lokal pemain.

### 4.11 Daily Login

- Panel bawah kiri berisi gift icon, `Daily Login`, subtitle `Claim your reward!`, dan chevron.
- Klik membuka layar kalender hadiah 7 hari.
- Tombol `CLAIM TODAY` memberikan coin sesuai hari (contoh 100, 150, 200, 250, 300, 400, 750), menyimpan tanggal klaim dan hari streak.
- Tidak bisa klaim dua kali pada tanggal lokal yang sama.
- Jika sudah klaim, tombol menjadi `CLAIMED TODAY` dan menampilkan kapan bisa klaim lagi.
- Jika streak terputus, aturan reset harus jelas. Gunakan tanggal sistem lokal, bukan timer server.

### 4.12 NEWS

- Footer `NEWS` membuka `NewsScreen`.
- Berisi minimal 3 artikel lokal: Welcome to Racezone, Sunset Circuit now open, Update 1.0 — handling improvements.
- Klik kartu membuka isi artikel.
- Semua konten statis lokal; tidak memerlukan koneksi internet.

### 4.13 CUSTOMIZE

- Footer `CUSTOMIZE` membuka `CustomizeScreen`.
- Sediakan pilihan warna body minimal 6 warna, decal minimal 3, dan wheel style minimal 2.
- Perubahan terlihat langsung pada sprite 2D mobil preview.
- Tombol `APPLY` menyimpan pilihan ke SaveManager.
- Tombol `RESET` mengembalikan tampilan ke konfigurasi tersimpan atau default (jelaskan dengan label `RESET PREVIEW`).
- Tombol `CANCEL` membuang perubahan yang belum disimpan.

### 4.14 QUIT

- Footer `QUIT` membuka Confirm Dialog: “Exit Racezone?” dengan tombol `EXIT GAME` dan `KEEP RACING`.
- `KEEP RACING` menutup dialog.
- `EXIT GAME` menyimpan data lalu menjalankan `get_tree().quit()`.
- Jangan langsung keluar tanpa konfirmasi.

## 5. Settings — spesifikasi wajib

Settings adalah halaman penuh dengan tab/kategori. Semua kontrol wajib benar-benar mengubah perilaku, bukan sekadar dekorasi.

### Audio

- Master Volume slider 0–100%.
- Music Volume slider 0–100%.
- SFX Volume slider 0–100%.
- Mute All toggle.
- Music toggle.
- UI Sound Effects toggle.
- Tombol `TEST SOUND` memainkan SFX click/preview.
- Perubahan slider langsung terdengar dan tersimpan (atau gunakan Apply untuk commit, tetapi harus konsisten). Rekomendasi: apply langsung dan simpan saat nilai berubah.

### Display / Graphics

- Window Mode: Windowed / Fullscreen / Borderless (gunakan mode yang didukung platform).
- Resolution selector: opsi umum 1280×720, 1366×768, 1600×900, 1920×1080; hanya tampilkan resolusi yang valid/tersedia bila bisa dideteksi.
- VSync toggle.
- FPS Limit: 30 / 60 / 120 / Unlimited.
- Graphics Quality: Low / Medium / High. Pada game 2D, pilihan ini mengatur efek dekoratif, jumlah partikel, dan kualitas background; jangan berpura-pura mengubah kualitas 3D.
- UI Scale slider 80–120%.
- Screen Shake toggle; benar-benar mengaktifkan/nonaktifkan efek getaran kamera saat race.
- Reduced Motion toggle; mematikan animasi dekoratif yang berlebihan.

### Gameplay

- Steering Sensitivity slider 1–10; berpengaruh pada respons kontrol kendaraan.
- Control Scheme: Keyboard / Mouse (jika mouse control disediakan). Default Keyboard.
- Show Race Tutorial toggle; memunculkan petunjuk awal balapan.
- Auto Accelerate toggle; bila aktif mobil terus akselerasi dan user mengontrol belok/rem.
- Confirm Before Leaving Race toggle.

### Accessibility / Language

- Language: Bahasa Indonesia / English. Minimal semua label utama dan menu diterjemahkan melalui satu sistem dictionary/translation; jangan hanya mengubah satu label.
- High Contrast UI toggle; meningkatkan kontras outline, teks, dan panel.
- Color Assist: Off / Protanopia-friendly / Deuteranopia-friendly. Implementasikan sebagai palet UI alternatif yang jelas; tidak perlu filter layar global yang mahal.
- Text Size: Normal / Large.

### Data / Support

- `RESTORE DEFAULTS`: menampilkan confirm dialog, setelah disetujui reset semua setting ke default, bukan menghapus progress game.
- `RESET SAVE DATA`: tampilkan dialog berbahaya yang menjelaskan bahwa nama, currency, mobil, achievement, dan record lokal akan dihapus. Harus ada konfirmasi kedua (misalnya ketik RESET atau tekan confirm dua kali). Jangan pernah reset tanpa konfirmasi eksplisit.
- `CREDITS`: tampilkan halaman credits, versi game, dan kredit aset/font/audio yang benar.
- Tombol `APPLY` (jika digunakan), `CANCEL`, dan `BACK` harus punya perilaku yang konsisten.

**Catatan implementasi:** jangan menampilkan opsi yang tidak bisa diterapkan di platform aktif. Jika resolusi tidak bisa diganti saat berjalan di platform tertentu, tampilkan opsi yang didukung atau berikan feedback yang jujur.

## 6. Hover, focus, click, dan sound design

Buat satu komponen reusable `RaceButton` (turunan `Button`) untuk semua tombol utama dan sekunder.

State visual:
- Normal: panel navy, outline 2 px, bevel/chamfer, teks uppercase.
- Hover: border/inner highlight kuning-oranye, icon/label lebih terang, scale ringan 1.02–1.03, glow/shadow lembut. Jangan menggeser layout di sekitarnya.
- Pressed: scale sekitar 0.98 atau offset 2 px dan fill lebih gelap.
- Disabled: saturasi rendah dan opacity/kontras turun, serta tidak memainkan click SFX.
- Focus: outline tegas agar navigasi keyboard terlihat.

SFX:
- `ui_hover.wav`: blip elektronik lembut 50–100 ms, tidak menusuk telinga.
- `ui_click.wav`: klik mekanis/arcade 70–140 ms.
- Sediakan satu `AudioStreamPlayer` khusus hover dan satu click, atau pool player agar suara yang berdekatan tidak saling memotong secara kasar.
- Hover sound hanya dari `mouse_entered`, click sound hanya saat `pressed`; pastikan signal tidak terhubung ganda setelah scene dibuka berulang.
- Saat SFX dimute, visual hover tetap berjalan.
- Semua audio melewati AudioManager dan menghormati volume global serta SFX.

## 7. Navigasi dan konsistensi UX

- Setiap subpage memiliki header judul, tombol Back yang terlihat, serta tombol Escape untuk kembali.
- Dialog modal memiliki overlay gelap, fokus default pada aksi aman, dan dapat ditutup dengan Escape kecuali dialog destructive yang sedang meminta konfirmasi akhir.
- Toast muncul 2–3 detik, tidak menghalangi CTA penting, dan tidak memerlukan klik.
- Semua menu punya empty state dan feedback validasi.
- Tombol disabled harus tampak disabled dan memberi alasan jika relevan.
- Gunakan focus order logis agar semua menu dapat dijalankan tanpa mouse.
- Cegah klik cepat ganda pada tombol transaksi agar hadiah tidak diberikan dua kali.

## 8. Race setup dan playable 2D race minimum

Walau fokus utama adalah home screen, tombol Play harus menuju alur yang benar-benar bisa dicoba.

### Race Setup

- Pilih track: Sunset Circuit, Harbor Run, Neon Loop.
- Pilih difficulty: Easy, Normal, Hard.
- Tampilkan mobil terpilih dan ringkasan statistik.
- Tombol `START RACE` membuka race 2D.

### Race Scene

- Game 2D top-down atau side-view 2D yang konsisten (rekomendasi: top-down 2D untuk kontrol racing yang mudah dibangun). Jangan membuatnya 3D.
- Kontrol default: A/D atau Left/Right untuk steer, W/Up untuk accelerate, S/Down/Space untuk brake.
- Ada countdown 3-2-1-GO, timer, lap counter, posisi, pause, resume, restart, dan return to menu.
- Minimal satu track yang benar-benar dapat dilalui dan memiliki collision boundary. Dua track lain dapat memakai layout sederhana yang berbeda.
- Race harus dapat selesai. Setelah finish, tampilkan result screen berisi waktu, posisi, reward coin, dan tombol `RETRY` / `HOME`.
- Simpan local best time dan tambah progress achievement/event setelah finish.
- Jangan memberi reward berulang karena membuka result screen berulang kali. Setiap hasil race punya ID/session flag yang hanya bisa diklaim satu kali.

## 9. Penyimpanan offline dan data default

Gunakan `ConfigFile` atau JSON lokal melalui `user://`. Rekomendasi `ConfigFile` karena sederhana untuk Godot.

Data minimum:

```ini
[player]
name="RacerX"
avatar_id="avatar_01"
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

Ketentuan:
- Load saat aplikasi dimulai. Jika file belum ada atau rusak, buat data default yang aman.
- Save setelah perubahan penting (nama, currency, purchase, selection, setting, reward, achievement, race record).
- Gunakan helper `add_coins(amount)` dan `spend_coins(amount)` agar validasi saldo terpusat.
- Jangan menyimpan password atau data sensitif; game tidak memerlukan akun.
- Sediakan versi schema (`save_version`) dan penanganan default jika ada field baru.

## 10. Kualitas implementasi dan performa

- Godot 4.x + GDScript, typed variables bila masuk akal.
- Gunakan signal dan scene composition; hindari hard-coded absolute path yang rapuh.
- Pisahkan data item/car/achievement dari layout UI (Resource atau dictionary terpusat).
- Gunakan `Theme` global agar ukuran font, warna, dan state komponen konsisten.
- Gunakan `Container` untuk komposisi subpage dan layout responsive.
- Hindari memuat ulang seluruh scene hanya untuk memperbarui saldo; emit signal dan update widget.
- Bersihkan koneksi signal bila node dibuat/dihapus berulang.
- Tangani error load/save dengan `push_warning` dan fallback; jangan crash.
- Tidak boleh ada error merah berulang di Godot Output saat navigasi normal.

## 11. Definition of Done / acceptance checklist

Implementasi baru dianggap selesai bila seluruh hal berikut lolos:

- [ ] Home screen secara komposisi jelas mengikuti `reference_home.png`.
- [ ] Semua elemen visual UI dibuat sebagai node terpisah, bukan screenshot datar.
- [ ] Tampilan benar-benar 2D; tidak ada objek atau scene 3D.
- [ ] Profile di kiri atas membuka halaman profil.
- [ ] Edit nama: Save menyimpan, Cancel membuang perubahan, validasi berfungsi, data bertahan setelah restart.
- [ ] Avatar dapat dipilih dan tersimpan.
- [ ] Tombol plus coin membuka Free Coin Center dan semua paket gratis benar-benar menambah saldo.
- [ ] Tombol plus diamond juga punya halaman/aksi offline yang jelas.
- [ ] Inbox membuka pesan; claim hadiah tidak bisa dobel; Mark All Read menghilangkan badge.
- [ ] Event card membuka detail event dan Go Race mengarah ke Race Setup.
- [ ] Play membuka Race Setup; Start Race dapat memulai race 2D yang playable.
- [ ] Garage dapat memilih dan membeli mobil dengan validasi saldo.
- [ ] Shop dapat membeli dan meng-equip item kosmetik offline.
- [ ] Achievements memiliki progress, klaim reward satu kali, dan tersimpan.
- [ ] Leaderboard menampilkan local record yang benar dan filter bekerja.
- [ ] Daily Login hanya bisa diklaim sekali per hari.
- [ ] News membuka artikel lokal dan detailnya.
- [ ] Customize preview berubah, Apply menyimpan, Cancel membuang perubahan.
- [ ] Quit meminta konfirmasi sebelum keluar.
- [ ] Settings seluruh kategori berfungsi: audio, display, gameplay, accessibility/language, data/support.
- [ ] Volume slider mengubah volume aktual; mute dan toggle audio benar-benar bekerja.
- [ ] Fullscreen/window mode, VSync, FPS, UI scale, reduced motion, screen shake, sensitivity, auto accelerate, language, high contrast, dan text size benar-benar diterapkan.
- [ ] Restore Defaults dan Reset Save Data punya dialog konfirmasi yang aman.
- [ ] Semua tombol menunjukkan hover state saat pointer masuk.
- [ ] Setiap hover memutar satu SFX; click memutar click SFX; tidak ada suara berulang saat pointer diam.
- [ ] Keyboard navigation, Enter/Space activate, dan Escape/back bekerja.
- [ ] UI tetap rapi pada 1920×1080, 1600×900, 1366×768, dan 1280×720.
- [ ] Tidak ada tombol dead, placeholder kosong, transaksi dobel, atau error runtime kritis.

## 12. Catatan akhir untuk developer

Prioritaskan kualitas home screen dan semua alur tombol sebelum memperluas konten race. Buat versi awal yang lengkap dan konsisten, bukan banyak menu kosong. Jika suatu fitur harus disederhanakan karena waktu/asset, implementasikan versi offline minimal yang benar-benar bekerja dan beri label yang jujur. Jangan mengganti fungsi nyata dengan animasi palsu atau tombol dekoratif.
