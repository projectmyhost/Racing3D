extends Node

signal language_changed(new_lang: String)

var current_language: String = "en"

const STRINGS: Dictionary = {
	"en": {
		# Common & Navigation
		"APP_NAME": "RACEZONE",
		"PLAY": "PLAY",
		"GARAGE": "GARAGE",
		"SHOP": "SHOP",
		"ACHIEVEMENTS": "ACHIEVEMENTS",
		"LEADERBOARD": "LEADERBOARD",
		"DAILY_LOGIN": "Daily Login",
		"CLAIM_REWARD": "Claim your reward!",
		"NEWS": "NEWS",
		"CUSTOMIZE": "CUSTOMIZE",
		"QUIT": "QUIT",
		"SETTINGS": "SETTINGS",
		"INBOX": "INBOX",
		"PROFILE": "PROFILE",
		"BACK": "BACK",
		"CANCEL": "CANCEL",
		"CONFIRM": "CONFIRM",
		"SAVE": "SAVE",
		"APPLY": "APPLY",
		"RESET": "RESET",
		"CLOSE": "CLOSE",
		"BUY": "BUY",
		"OWNED": "OWNED",
		"EQUIP": "EQUIP",
		"EQUIPPED": "EQUIPPED",
		"SELECT": "SELECT",
		"SELECTED": "SELECTED",
		"CLAIM": "CLAIM",
		"CLAIMED": "CLAIMED",
		"FREE": "FREE",
		"FREE_COINS": "Free Coin Center",
		"FREE_DIAMONDS": "Free Diamond Center",
		"CLAIM_FREE_COINS": "CLAIM FREE COINS",
		"CLAIM_FREE_DIAMONDS": "CLAIM FREE DIAMONDS",
		"OFFLINE_DEMO_NOTICE": "Offline demo — all coin & diamond packs are free.",
		"COINS": "Coins",
		"DIAMONDS": "Diamonds",
		"LEVEL": "Level",
		"XP": "XP",
		"YES": "YES",
		"NO": "NO",
		"OK": "OK",
		"SUCCESS": "Success",
		"WARNING": "Warning",
		"ERROR": "Error",

		# Profile Screen
		"PROFILE_TITLE": "DRIVER PROFILE",
		"PILOT_NAME": "Pilot Name",
		"SAVE_NAME": "SAVE NAME",
		"CHOOSE_AVATAR": "CHOOSE AVATAR",
		"NAME_HINT": "Enter 3-16 characters...",
		"NAME_ERR_EMPTY": "Name cannot be empty!",
		"NAME_ERR_LENGTH": "Name must be between 3 and 16 characters!",
		"NAME_SAVED_SUCCESS": "Profile name saved successfully!",
		"AVATAR_SELECTED": "Avatar updated!",
		"CAREER_STATS": "CAREER STATISTICS",
		"STAT_RACES": "Races Completed",
		"STAT_WINS": "Victories",
		"STAT_WIN_RATE": "Win Rate",
		"STAT_BEST_TIME": "Best Lap Time",
		"STAT_DISTANCE": "Total Distance",

		# Event
		"EVENT_BADGE": "SPECIAL EVENT",
		"EVENT_FESTIVAL": "Racing Festival",
		"EVENT_DESC": "Take part in the circuit championship! Finish 3 races to unlock special rewards.",
		"EVENT_TARGET": "Goal: Complete 3 Races",
		"EVENT_PROGRESS": "Progress: {0} / 3 Completed",
		"EVENT_TIME_LEFT": "6d 12h left",
		"GO_RACE": "GO RACE",
		"EVENT_COMPLETED": "Festival Championship Completed!",

		# Garage
		"GARAGE_TITLE": "GARAGE & VEHICLES",
		"CAR_STARTER_GT": "Apex GT-R",
		"CAR_STARTER_GT_DESC": "Well-balanced rear-wheel drive sports coupe. Easy to handle for beginners.",
		"CAR_PHANTOM_R": "Phantom RS",
		"CAR_PHANTOM_R_DESC": "V8 Twin-Turbo drag monster. Unmatched top speed on circuit straights.",
		"CAR_CYCLONE_V": "Cyclone Vector",
		"CAR_CYCLONE_V_DESC": "Lightweight aerodynamic carbon track car with blistering cornering grip.",
		"STAT_SPEED": "Top Speed",
		"STAT_ACCEL": "Acceleration",
		"STAT_HANDLING": "Handling",
		"BUY_CAR": "BUY FOR {0} COINS",
		"CAR_PURCHASED": "Congratulations! You acquired {0}!",
		"CAR_SELECTED_MSG": "{0} selected as your active car.",
		"NOT_ENOUGH_COINS": "Not enough coins to purchase this item!",

		# Shop
		"SHOP_TITLE": "RACE SHOP",
		"SHOP_TAB_PAINTS": "Body Paint",
		"SHOP_TAB_DECALS": "Livery Decals",
		"SHOP_TAB_WHEELS": "Rims & Wheels",
		"SHOP_TAB_BUNDLES": "Bundles",
		"ITEM_BOUGHT": "Item purchased successfully!",
		"ITEM_EQUIPPED": "Item equipped!",
		"BUNDLE_RACER_PACK": "Grand Prix Livery Pack",
		"BUNDLE_RACER_DESC": "Includes Crimson Blaze paint, Racing Dual Stripes, and Sport Forged rims.",

		# Achievements
		"ACHIEVEMENTS_TITLE": "ACHIEVEMENTS",
		"ACH_FIRST_LAP_TITLE": "First Lap",
		"ACH_FIRST_LAP_DESC": "Complete your first circuit race.",
		"ACH_ROOKIE_DRIVER_TITLE": "Rookie Driver",
		"ACH_ROOKIE_DRIVER_DESC": "Complete 5 race sessions.",
		"ACH_CLEAN_RUN_TITLE": "Clean Run",
		"ACH_CLEAN_RUN_DESC": "Complete a full race with zero wall collisions.",
		"ACH_SPEED_FREAK_TITLE": "Speed Freak",
		"ACH_SPEED_FREAK_DESC": "Reach a speed of 180 km/h.",
		"ACH_COLLECTOR_TITLE": "Collector",
		"ACH_COLLECTOR_DESC": "Own all 3 available cars in your garage.",
		"ACH_FESTIVAL_STARTER_TITLE": "Festival Starter",
		"ACH_FESTIVAL_STARTER_DESC": "Complete 3 festival circuit races.",
		"ACH_REWARD_CLAIMED": "Achievement reward claimed: +{0} Coins!",

		# Leaderboard
		"LEADERBOARD_TITLE": "LOCAL CIRCUIT LEADERBOARD",
		"LEADERBOARD_DESC": "Local lap records stored on device. CPU drivers provide benchmark times.",
		"FILTER_ALL": "All Tracks",
		"FILTER_SUNSET": "Sunset Circuit",
		"FILTER_HARBOR": "Harbor Run",
		"FILTER_NEON": "Neon Loop",
		"FILTER_MY_RECORDS": "My Records Only",
		"COL_RANK": "RANK",
		"COL_DRIVER": "DRIVER",
		"COL_TRACK": "TRACK",
		"COL_BEST_TIME": "BEST TIME",
		"COL_DATE": "DATE",

		# Daily Login
		"DAILY_LOGIN_TITLE": "7-DAY DAILY REWARDS",
		"DAY_1": "Day 1",
		"DAY_2": "Day 2",
		"DAY_3": "Day 3",
		"DAY_4": "Day 4",
		"DAY_5": "Day 5",
		"DAY_6": "Day 6",
		"DAY_7": "Day 7",
		"CLAIM_TODAY": "CLAIM TODAY",
		"CLAIMED_TODAY": "CLAIMED TODAY",
		"COME_BACK_TOMORROW": "Come back tomorrow for your next reward!",
		"DAILY_STREAK": "Current Streak: {0} Days",

		# News
		"NEWS_TITLE": "CIRCUIT NEWS",
		"NEWS_1_TITLE": "Welcome to RACEZONE Arcade",
		"NEWS_1_DATE": "Today",
		"NEWS_1_BODY": "Experience pure 2D arcade racing thrills! Tune your car, test your skills, and master all three circuits.",
		"NEWS_2_TITLE": "Sunset Circuit Grand Opening",
		"NEWS_2_DATE": "Yesterday",
		"NEWS_2_BODY": "The seaside track is officially open for drivers. Watch for the sharp chicane right before the final straightaway.",
		"NEWS_3_TITLE": "Patch 1.0 Handling Improvements",
		"NEWS_3_DATE": "2 days ago",
		"NEWS_3_BODY": "Refined steering responsiveness and physics simulation for sharper apex cornering.",

		# Customize
		"CUSTOMIZE_TITLE": "CUSTOMIZE VEHICLE",
		"COLOR_PAINT": "Body Paint",
		"DECAL_LIVERY": "Livery Stripe",
		"WHEEL_STYLE": "Rim Design",
		"APPLY_CUSTOMIZE": "APPLY",
		"RESET_CUSTOMIZE": "RESET PREVIEW",
		"CUSTOMIZE_SAVED": "Custom livery applied and saved!",

		# Inbox
		"INBOX_TITLE": "DRIVER INBOX",
		"MARK_ALL_READ": "MARK ALL READ",
		"MSG_WELCOME_TITLE": "Welcome Driver Bonus!",
		"MSG_WELCOME_BODY": "Thanks for joining RACEZONE! Here is a starting gift of 1,000 Coins.",
		"MSG_EVENT_TITLE": "Racing Festival Announcement",
		"MSG_EVENT_BODY": "The annual Racing Festival has kicked off. Join circuit challenges to earn trophies and bonus cash.",
		"MSG_PATCH_TITLE": "Update 1.0 Arcade Prototype Notes",
		"MSG_PATCH_BODY": "Welcome to version 1.0. Enjoy smooth offline gameplay with full keyboard controls and responsive settings.",
		"GIFT_CLAIMED": "Gift bonus already claimed!",
		"GIFT_CLAIM_SUCCESS": "Gift bonus of 1,000 Coins claimed!",

		# Quit Dialog
		"QUIT_CONFIRM_TITLE": "Exit Racezone?",
		"QUIT_CONFIRM_MSG": "Are you sure you want to quit the game? All progress has been saved.",
		"KEEP_RACING": "KEEP RACING",
		"EXIT_GAME": "EXIT GAME",

		# Race Setup
		"RACE_SETUP_TITLE": "RACE SETUP",
		"SELECT_TRACK": "SELECT TRACK",
		"SELECT_DIFFICULTY": "DIFFICULTY",
		"TRACK_SUNSET": "Sunset Circuit",
		"TRACK_SUNSET_DESC": "Fast sweeping turns under glorious city sunset skies.",
		"TRACK_HARBOR": "Harbor Run",
		"TRACK_HARBOR_DESC": "Challenging industrial port course with sharp technical chicanes.",
		"TRACK_NEON": "Neon Loop",
		"TRACK_NEON_DESC": "Blistering night course illuminated by towering neon signs.",
		"DIFF_EASY": "Amateur (Easy)",
		"DIFF_NORMAL": "Pro (Normal)",
		"DIFF_HARD": "Legend (Hard)",
		"START_RACE": "START RACE",

		# Race HUD & Gameplay
		"RACE_COUNTDOWN_3": "3",
		"RACE_COUNTDOWN_2": "2",
		"RACE_COUNTDOWN_1": "1",
		"RACE_COUNTDOWN_GO": "GO!",
		"HUD_LAP": "LAP {0}/{1}",
		"HUD_TIME": "TIME: {0}",
		"HUD_BEST": "BEST: {0}",
		"HUD_SPEED": "{0} KM/H",
		"HUD_POS": "POS: {0}/{1}",
		"RACE_TUTORIAL_HINT": "Accelerate: [W / Up] | Steer: [A/D or Arrows] | Brake/Drift: [S / Down / Space]",
		"RACE_PAUSED": "RACE PAUSED",
		"RESUME": "RESUME",
		"RESTART": "RESTART",
		"EXIT_TO_MENU": "EXIT TO MENU",
		"CONFIRM_LEAVE_RACE_TITLE": "Leave Race?",
		"CONFIRM_LEAVE_RACE_MSG": "Are you sure you want to exit the current race? Any ongoing lap progress will be lost.",
		"LEAVE_RACE": "LEAVE RACE",
		"CONTINUE_RACE": "CONTINUE",

		# Race Results
		"RACE_RESULT_TITLE": "RACE FINISHED!",
		"FINISH_POSITION_1": "1ST PLACE - VICTORY!",
		"FINISH_POSITION_2": "2ND PLACE - PODIUM!",
		"FINISH_POSITION_3": "3RD PLACE - PODIUM!",
		"FINISH_POSITION_OTHER": "{0}TH PLACE - FINISHED",
		"RESULT_TIME": "Total Time: {0}",
		"RESULT_BEST_LAP": "Best Lap: {0}",
		"RESULT_REWARD": "Reward: +{0} Coins",
		"NEW_RECORD": "★ NEW TRACK RECORD! ★",
		"RETRY": "RETRY",
		"HOME": "HOME",

		# Settings Screen
		"SETTINGS_TITLE": "SETTINGS",
		"AUDIO": "Audio",
		"DISPLAY": "Display",
		"GAMEPLAY": "Gameplay",
		"ACCESSIBILITY": "Accessibility",
		"DATA": "Data & Support",

		"MASTER_VOLUME": "Master Volume",
		"MUSIC_VOLUME": "Music Volume",
		"SFX_VOLUME": "SFX Volume",
		"MUTE_ALL": "Mute All",
		"MUSIC_ENABLED": "Music Enabled",
		"SFX_ENABLED": "UI Sound Effects",
		"TEST_SOUND": "TEST SOUND",

		"WINDOW_MODE": "Window Mode",
		"RESOLUTION": "Resolution",
		"VSYNC": "VSync",
		"FPS_LIMIT": "FPS Limit",
		"GRAPHICS_QUALITY": "Graphics Quality",
		"UI_SCALE": "UI Scale",
		"SCREEN_SHAKE": "Screen Shake",
		"REDUCED_MOTION": "Reduced Motion",

		"STEERING_SENSITIVITY": "Steering Sensitivity",
		"CONTROL_SCHEME": "Control Scheme",
		"SHOW_RACE_TUTORIAL": "Show Race Tutorial",
		"AUTO_ACCELERATE": "Auto Accelerate",
		"CONFIRM_LEAVING_RACE": "Confirm Before Leaving Race",

		"LANGUAGE": "Language",
		"HIGH_CONTRAST": "High Contrast UI",
		"COLOR_ASSIST": "Color Assist",
		"TEXT_SIZE": "Text Size",

		"RESTORE_DEFAULTS": "RESTORE DEFAULTS",
		"RESET_SAVE_DATA": "RESET SAVE DATA",
		"CREDITS": "CREDITS",

		"RESTORE_DEFAULTS_CONFIRM_TITLE": "Restore Default Settings?",
		"RESTORE_DEFAULTS_CONFIRM_MSG": "This will reset all audio, display, gameplay, and accessibility settings back to their default values. Your saved cars, coins, and achievements will not be affected.",
		"RESET_SAVE_CONFIRM_TITLE": "RESET ALL SAVE DATA?",
		"RESET_SAVE_CONFIRM_MSG": "DANGER: This will permanently wipe your profile, coins, diamonds, cars, records, and achievements. Are you sure?",
		"CREDITS_TITLE": "RACEZONE CREDITS",
		"CREDITS_CONTENT": "RACEZONE - 2D Arcade Racing\nVersion: v1.0.0 Arcade Prototype\nEngine: Godot Engine 4.x\n\nAudio: Synthesized Chiptune & Arcade SFX\nArt & UI: 2D Arcade Racing Vector & Pixel Art\n\nDeveloped for offline standalone play.",

		# Options values
		"OPT_WINDOWED": "Windowed",
		"OPT_FULLSCREEN": "Fullscreen",
		"OPT_BORDERLESS": "Borderless",
		"OPT_ENABLED": "Enabled",
		"OPT_DISABLED": "Disabled",
		"OPT_FPS_30": "30 FPS",
		"OPT_FPS_60": "60 FPS",
		"OPT_FPS_120": "120 FPS",
		"OPT_FPS_UNLIMITED": "Unlimited",
		"OPT_LOW": "Low",
		"OPT_MEDIUM": "Medium",
		"OPT_HIGH": "High",
		"OPT_KEYBOARD": "Keyboard (WASD / Arrows)",
		"OPT_MOUSE": "Mouse",
		"OPT_OFF": "Off",
		"OPT_PROTANOPIA": "Protanopia Friendly",
		"OPT_DEUTERANOPIA": "Deuteranopia Friendly",
		"OPT_NORMAL": "Normal",
		"OPT_LARGE": "Large",
		"OPT_LANG_EN": "English",
		"OPT_LANG_ID": "Bahasa Indonesia",

		# Toasts
		"TOAST_SETTINGS_SAVED": "Settings saved successfully!",
		"TOAST_DEFAULTS_RESTORED": "Settings restored to defaults.",
		"TOAST_SAVE_RESET": "Save data has been completely reset.",
	},
	"id": {
		# Common & Navigation
		"APP_NAME": "RACEZONE",
		"PLAY": "MAIN",
		"GARAGE": "GARASI",
		"SHOP": "TOKO",
		"ACHIEVEMENTS": "PENCAPAIAN",
		"LEADERBOARD": "PAPAN PERINGKAT",
		"DAILY_LOGIN": "Login Harian",
		"CLAIM_REWARD": "Klaim hadiahmu!",
		"NEWS": "BERITA",
		"CUSTOMIZE": "KUSTOMISASI",
		"QUIT": "KELUAR",
		"SETTINGS": "PENGATURAN",
		"INBOX": "KOTAK MASUK",
		"PROFILE": "PROFIL",
		"BACK": "KEMBALI",
		"CANCEL": "BATAL",
		"CONFIRM": "KONFIRMASI",
		"SAVE": "SIMPAN",
		"APPLY": "TERAPKAN",
		"RESET": "RESET",
		"CLOSE": "TUTUP",
		"BUY": "BELI",
		"OWNED": "DIMILIKI",
		"EQUIP": "PASANG",
		"EQUIPPED": "TERPASANG",
		"SELECT": "PILIH",
		"SELECTED": "TERPILIH",
		"CLAIM": "KLAIM",
		"CLAIMED": "DIKLAIM",
		"FREE": "GRATIS",
		"FREE_COINS": "Pusat Koin Gratis",
		"FREE_DIAMONDS": "Pusat Berlian Gratis",
		"CLAIM_FREE_COINS": "KLAIM KOIN GRATIS",
		"CLAIM_FREE_DIAMONDS": "KLAIM BERLIAN GRATIS",
		"OFFLINE_DEMO_NOTICE": "Demo offline — semua paket koin & berlian gratis.",
		"COINS": "Koin",
		"DIAMONDS": "Berlian",
		"LEVEL": "Level",
		"XP": "XP",
		"YES": "YA",
		"NO": "TIDAK",
		"OK": "OK",
		"SUCCESS": "Berhasil",
		"WARNING": "Peringatan",
		"ERROR": "Kesalahan",

		# Profile Screen
		"PROFILE_TITLE": "PROFIL PEMBALAP",
		"PILOT_NAME": "Nama Pembalap",
		"SAVE_NAME": "SIMPAN NAMA",
		"CHOOSE_AVATAR": "PILIH AVATAR",
		"NAME_HINT": "Masukkan 3-16 karakter...",
		"NAME_ERR_EMPTY": "Nama tidak boleh kosong!",
		"NAME_ERR_LENGTH": "Nama harus antara 3 hingga 16 karakter!",
		"NAME_SAVED_SUCCESS": "Nama profil berhasil disimpan!",
		"AVATAR_SELECTED": "Avatar berhasil diperbarui!",
		"CAREER_STATS": "STATISTIK KARIER",
		"STAT_RACES": "Balapan Selesai",
		"STAT_WINS": "Kemenangan",
		"STAT_WIN_RATE": "Rasio Menang",
		"STAT_BEST_TIME": "Waktu Putaran Terbaik",
		"STAT_DISTANCE": "Total Jarak",

		# Event
		"EVENT_BADGE": "EVENT SPESIAL",
		"EVENT_FESTIVAL": "Festival Balap",
		"EVENT_DESC": "Ikuti kejuaraan sirkuit! Selesaikan 3 balapan untuk membuka hadiah spesial.",
		"EVENT_TARGET": "Target: Selesaikan 3 Balapan",
		"EVENT_PROGRESS": "Progres: {0} / 3 Selesai",
		"EVENT_TIME_LEFT": "Sisa 6h 12j",
		"GO_RACE": "MULAI BALAP",
		"EVENT_COMPLETED": "Kejuaraan Festival Selesai!",

		# Garage
		"GARAGE_TITLE": "GARASI & KENDARAAN",
		"CAR_STARTER_GT": "Apex GT-R",
		"CAR_STARTER_GT_DESC": "Coupe sport penggerak roda belakang yang seimbang. Mudah dikendalikan untuk pemula.",
		"CAR_PHANTOM_R": "Phantom RS",
		"CAR_PHANTOM_R_DESC": "Monster V8 Twin-Turbo. Kecepatan maksimal tak tertandingi di lintasan lurus.",
		"CAR_CYCLONE_V": "Cyclone Vector",
		"CAR_CYCLONE_V_DESC": "Mobil trek karbon aerodinamis ringan dengan cengkeraman tikungan luar biasa.",
		"STAT_SPEED": "Kecepatan Puncak",
		"STAT_ACCEL": "Akselerasi",
		"STAT_HANDLING": "Pengendalian",
		"BUY_CAR": "BELI {0} KOIN",
		"CAR_PURCHASED": "Selamat! Anda berhasil membeli {0}!",
		"CAR_SELECTED_MSG": "{0} dipilih sebagai mobil aktif.",
		"NOT_ENOUGH_COINS": "Koin tidak cukup untuk membeli item ini!",

		# Shop
		"SHOP_TITLE": "TOKO BALAP",
		"SHOP_TAB_PAINTS": "Cat Bodi",
		"SHOP_TAB_DECALS": "Stiker Livery",
		"SHOP_TAB_WHEELS": "Velg & Roda",
		"SHOP_TAB_BUNDLES": "Paket Khusus",
		"ITEM_BOUGHT": "Item berhasil dibeli!",
		"ITEM_EQUIPPED": "Item berhasil dipasang!",
		"BUNDLE_RACER_PACK": "Paket Livery Grand Prix",
		"BUNDLE_RACER_DESC": "Termasuk cat Crimson Blaze, Stiker Garis Ganda, dan Velg Sport Forged.",

		# Achievements
		"ACHIEVEMENTS_TITLE": "PENCAPAIAN",
		"ACH_FIRST_LAP_TITLE": "Putaran Pertama",
		"ACH_FIRST_LAP_DESC": "Selesaikan balapan sirkuit pertamamu.",
		"ACH_ROOKIE_DRIVER_TITLE": "Pembalap Pemula",
		"ACH_ROOKIE_DRIVER_DESC": "Selesaikan 5 sesi balapan.",
		"ACH_CLEAN_RUN_TITLE": "Balapan Bersih",
		"ACH_CLEAN_RUN_DESC": "Selesaikan balapan penuh tanpa menabrak dinding pembatas.",
		"ACH_SPEED_FREAK_TITLE": "Raja Kecepatan",
		"ACH_SPEED_FREAK_DESC": "Capai kecepatan 180 km/jam.",
		"ACH_COLLECTOR_TITLE": "Kolektor Mobil",
		"ACH_COLLECTOR_DESC": "Miliki ketiga mobil di garasimu.",
		"ACH_FESTIVAL_STARTER_TITLE": "Bintang Festival",
		"ACH_FESTIVAL_STARTER_DESC": "Selesaikan 3 balapan festival.",
		"ACH_REWARD_CLAIMED": "Hadiah pencapaian berhasil diklaim: +{0} Koin!",

		# Leaderboard
		"LEADERBOARD_TITLE": "PAPAN PERINGKAT SIRKUIT LOKAL",
		"LEADERBOARD_DESC": "Catatan waktu lokal di perangkat. Pembalap CPU menyediakan waktu tolok ukur.",
		"FILTER_ALL": "Semua Sirkuit",
		"FILTER_SUNSET": "Sirkuit Senja",
		"FILTER_HARBOR": "Jalur Pelabuhan",
		"FILTER_NEON": "Lingkar Neon",
		"FILTER_MY_RECORDS": "Hanya Catatan Saya",
		"COL_RANK": "PERINGKAT",
		"COL_DRIVER": "PEMBALAP",
		"COL_TRACK": "SIRKUIT",
		"COL_BEST_TIME": "WAKTU TERBAIK",
		"COL_DATE": "TANGGAL",

		# Daily Login
		"DAILY_LOGIN_TITLE": "HADIAH HARIAN 7 HARI",
		"DAY_1": "Hari 1",
		"DAY_2": "Hari 2",
		"DAY_3": "Hari 3",
		"DAY_4": "Hari 4",
		"DAY_5": "Hari 5",
		"DAY_6": "Hari 6",
		"DAY_7": "Hari 7",
		"CLAIM_TODAY": "KLAIM HARI INI",
		"CLAIMED_TODAY": "SUDAH DIKLAIM HARI INI",
		"COME_BACK_TOMORROW": "Kembali lagi besok untuk hadiah berikutnya!",
		"DAILY_STREAK": "Rangkaian Hari Ini: {0} Hari",

		# News
		"NEWS_TITLE": "KABAR SIRKUIT",
		"NEWS_1_TITLE": "Selamat Datang di RACEZONE Arcade",
		"NEWS_1_DATE": "Hari Ini",
		"NEWS_1_BODY": "Rasakan sensasi balap arkade 2D murni! Modifikasi mobilmu, uji keahlianmu, dan kuasai ketiga sirkuit.",
		"NEWS_2_TITLE": "Pembukaan Sirkuit Senja",
		"NEWS_2_DATE": "Kemarin",
		"NEWS_2_BODY": "Lintasan tepi laut resmi dibuka untuk para pembalap. Waspadai chicane tajam tepat sebelum lintasan lurus akhir.",
		"NEWS_3_TITLE": "Patch 1.0 Peningkatan Kendali",
		"NEWS_3_DATE": "2 hari lalu",
		"NEWS_3_BODY": "Penyempurnaan responsivitas kemudi dan simulasi fisika untuk tikungan yang lebih presisi.",

		# Customize
		"CUSTOMIZE_TITLE": "KUSTOMISASI KENDARAAN",
		"COLOR_PAINT": "Cat Bodi",
		"DECAL_LIVERY": "Striping Livery",
		"WHEEL_STYLE": "Desain Velg",
		"APPLY_CUSTOMIZE": "TERAPKAN",
		"RESET_CUSTOMIZE": "RESET TAMPILAN",
		"CUSTOMIZE_SAVED": "Livery kustom berhasil disimpan!",

		# Inbox
		"INBOX_TITLE": "KOTAK MASUK PEMBALAP",
		"MARK_ALL_READ": "TANDAI SEMUA DIBACA",
		"MSG_WELCOME_TITLE": "Bonus Sambutan Pembalap!",
		"MSG_WELCOME_BODY": "Terima kasih telah bergabung di RACEZONE! Ini hadiah permulaan sebesar 1.000 Koin.",
		"MSG_EVENT_TITLE": "Pengumuman Festival Balap",
		"MSG_EVENT_BODY": "Festival Balap tahunan telah dimulai. Ikuti tantangan sirkuit untuk meraih trofi dan bonus koin.",
		"MSG_PATCH_TITLE": "Catatan Pembaruan 1.0 Prototipe Arkade",
		"MSG_PATCH_BODY": "Selamat datang di versi 1.0. Nikmati permainan offline lancar dengan kontrol keyboard lengkap dan pengaturan responsif.",
		"GIFT_CLAIMED": "Hadiah bonus sudah diklaim!",
		"GIFT_CLAIM_SUCCESS": "Hadiah bonus 1.000 Koin berhasil diklaim!",

		# Quit Dialog
		"QUIT_CONFIRM_TITLE": "Keluar dari Racezone?",
		"QUIT_CONFIRM_MSG": "Apakah Anda yakin ingin keluar dari permainan? Semua progres telah tersimpan.",
		"KEEP_RACING": "LANJUT MAIN",
		"EXIT_GAME": "KELUAR GAME",

		# Race Setup
		"RACE_SETUP_TITLE": "PERSIAPAN BALAPAN",
		"SELECT_TRACK": "PILIH SIRKUIT",
		"SELECT_DIFFICULTY": "TINGKAT KESULITAN",
		"TRACK_SUNSET": "Sirkuit Senja",
		"TRACK_SUNSET_DESC": "Tikungan menyapu cepat di bawah langit senja kota yang indah.",
		"TRACK_HARBOR": "Jalur Pelabuhan",
		"TRACK_HARBOR_DESC": "Lintasan pelabuhan industri menantang dengan tikungan teknis tajam.",
		"TRACK_NEON": "Lingkar Neon",
		"TRACK_NEON_DESC": "Lintasan malam berkecepatan tinggi diterangi lampu neon menjulang.",
		"DIFF_EASY": "Amatir (Mudah)",
		"DIFF_NORMAL": "Profesional (Normal)",
		"DIFF_HARD": "Legenda (Sulit)",
		"START_RACE": "MULAI BALAPAN",

		# Race HUD & Gameplay
		"RACE_COUNTDOWN_3": "3",
		"RACE_COUNTDOWN_2": "2",
		"RACE_COUNTDOWN_1": "1",
		"RACE_COUNTDOWN_GO": "GAS!",
		"HUD_LAP": "PUTARAN {0}/{1}",
		"HUD_TIME": "WAKTU: {0}",
		"HUD_BEST": "TERBAIK: {0}",
		"HUD_SPEED": "{0} KM/JAM",
		"HUD_POS": "POS: {0}/{1}",
		"RACE_TUTORIAL_HINT": "Gas: [W / Atas] | Belok: [A/D atau Panah] | Rem/Drift: [S / Bawah / Spasi]",
		"RACE_PAUSED": "BALAPAN DIJEDA",
		"RESUME": "LANJUTKAN",
		"RESTART": "ULANGI",
		"EXIT_TO_MENU": "KELUAR KE MENU",
		"CONFIRM_LEAVE_RACE_TITLE": "Tinggalkan Balapan?",
		"CONFIRM_LEAVE_RACE_MSG": "Apakah Anda yakin ingin keluar dari balapan? Progres putaran saat ini akan hilang.",
		"LEAVE_RACE": "TINGGALKAN",
		"CONTINUE_RACE": "LANJUTKAN",

		# Race Results
		"RACE_RESULT_TITLE": "BALAPAN SELESAI!",
		"FINISH_POSITION_1": "JUARA 1 - KEMENANGAN!",
		"FINISH_POSITION_2": "JUARA 2 - PODIUM!",
		"FINISH_POSITION_3": "JUARA 3 - PODIUM!",
		"FINISH_POSITION_OTHER": "PERINGKAT {0} - FINIS",
		"RESULT_TIME": "Total Waktu: {0}",
		"RESULT_BEST_LAP": "Putaran Terbaik: {0}",
		"RESULT_REWARD": "Hadiah: +{0} Koin",
		"NEW_RECORD": "★ REKOR SIRKUIT BARU! ★",
		"RETRY": "COBA LAGI",
		"HOME": "MENU UTAMA",

		# Settings Screen
		"SETTINGS_TITLE": "PENGATURAN",
		"AUDIO": "Audio",
		"DISPLAY": "Tampilan",
		"GAMEPLAY": "Gameplay",
		"ACCESSIBILITY": "Aksesibilitas",
		"DATA": "Data & Bantuan",

		"MASTER_VOLUME": "Volume Utama",
		"MUSIC_VOLUME": "Volume Musik",
		"SFX_VOLUME": "Volume SFX",
		"MUTE_ALL": "Bisukan Semua",
		"MUSIC_ENABLED": "Musik Aktif",
		"SFX_ENABLED": "Efek Suara UI",
		"TEST_SOUND": "UJI SUARA",

		"WINDOW_MODE": "Mode Jendela",
		"RESOLUTION": "Resolusi",
		"VSYNC": "VSync",
		"FPS_LIMIT": "Batas FPS",
		"GRAPHICS_QUALITY": "Kualitas Grafis",
		"UI_SCALE": "Skala UI",
		"SCREEN_SHAKE": "Goyangan Layar",
		"REDUCED_MOTION": "Pengurangan Gerakan",

		"STEERING_SENSITIVITY": "Sensitivitas Kemudi",
		"CONTROL_SCHEME": "Skema Kontrol",
		"SHOW_RACE_TUTORIAL": "Tampilkan Tutorial",
		"AUTO_ACCELERATE": "Akselerasi Otomatis",
		"CONFIRM_LEAVING_RACE": "Konfirmasi Tinggalkan Balapan",

		"LANGUAGE": "Bahasa",
		"HIGH_CONTRAST": "Kontras Tinggi",
		"COLOR_ASSIST": "Bantuan Warna",
		"TEXT_SIZE": "Ukuran Teks",

		"RESTORE_DEFAULTS": "PULIHKAN DEFAULT",
		"RESET_SAVE_DATA": "RESET DATA SIMPANAN",
		"CREDITS": "KREDIT",

		"RESTORE_DEFAULTS_CONFIRM_TITLE": "Pulihkan Pengaturan Default?",
		"RESTORE_DEFAULTS_CONFIRM_MSG": "Ini akan mengembalikan semua pengaturan audio, tampilan, gameplay, dan aksesibilitas ke nilai default. Mobil, koin, dan pencapaian Anda tidak akan terpengaruh.",
		"RESET_SAVE_CONFIRM_TITLE": "RESET SEMUA DATA SIMPANAN?",
		"RESET_SAVE_CONFIRM_MSG": "BAHAYA: Ini akan menghapus permanen profil, koin, berlian, mobil, rekor, dan pencapaian Anda. Apakah Anda yakin?",
		"CREDITS_TITLE": "KREDIT RACEZONE",
		"CREDITS_CONTENT": "RACEZONE - 2D Arcade Racing\nVersi: v1.0.0 Prototipe Arkade\nEngine: Godot Engine 4.x\n\nAudio: Efek Suara Prosedural & Musik Arkade\nSeni & UI: Seni Vektor & Piksel Balap Arkade 2D\n\nDikembangkan untuk permainan mandiri offline.",

		# Options values
		"OPT_WINDOWED": "Jendela",
		"OPT_FULLSCREEN": "Layar Penuh",
		"OPT_BORDERLESS": "Tanpa Batas",
		"OPT_ENABLED": "Aktif",
		"OPT_DISABLED": "Nonaktif",
		"OPT_FPS_30": "30 FPS",
		"OPT_FPS_60": "60 FPS",
		"OPT_FPS_120": "120 FPS",
		"OPT_FPS_UNLIMITED": "Tanpa Batas",
		"OPT_LOW": "Rendah",
		"OPT_MEDIUM": "Sedang",
		"OPT_HIGH": "Tinggi",
		"OPT_KEYBOARD": "Keyboard (WASD / Panah)",
		"OPT_MOUSE": "Mouse",
		"OPT_OFF": "Mati",
		"OPT_PROTANOPIA": "Ramah Protanopia",
		"OPT_DEUTERANOPIA": "Ramah Deuteranopia",
		"OPT_NORMAL": "Normal",
		"OPT_LARGE": "Besar",
		"OPT_LANG_EN": "English",
		"OPT_LANG_ID": "Bahasa Indonesia",

		# Toasts
		"TOAST_SETTINGS_SAVED": "Pengaturan berhasil disimpan!",
		"TOAST_DEFAULTS_RESTORED": "Pengaturan dikembalikan ke default.",
		"TOAST_SAVE_RESET": "Data penyimpanan telah direset sepenuhnya.",
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_godot_translations()
	
	if is_inside_tree() and has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_signal("settings_changed"):
			sm.settings_changed.connect(_on_save_settings_changed)
		_sync_from_save_manager()
	else:
		_apply_language(current_language)

func _register_godot_translations() -> void:
	for lang in ["en", "id"]:
		var t = Translation.new()
		t.locale = lang
		var dict: Dictionary = STRINGS[lang]
		for key in dict.keys():
			t.add_message(key, dict[key])
		TranslationServer.add_translation(t)

func _sync_from_save_manager() -> void:
	if not is_inside_tree() or not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var saved_lang = str(sm.get_setting("language", "en"))
	if saved_lang in ["en", "id"]:
		_apply_language(saved_lang)

func _on_save_settings_changed() -> void:
	if not is_inside_tree() or not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	var saved_lang = str(sm.get_setting("language", "en"))
	if saved_lang != current_language and saved_lang in ["en", "id"]:
		_apply_language(saved_lang)

func _apply_language(lang: String) -> void:
	current_language = lang
	TranslationServer.set_locale(lang)
	emit_signal("language_changed", current_language)

func set_language(lang: String) -> void:
	if lang in ["en", "id"]:
		_apply_language(lang)
		if is_inside_tree() and has_node("/root/SaveManager"):
			var sm = get_node("/root/SaveManager")
			sm.set_setting("language", lang)

func get_language() -> String:
	return current_language

func get_string(key: String, lang: String = "") -> String:
	var target_lang = lang if lang != "" else current_language
	if STRINGS.has(target_lang) and STRINGS[target_lang].has(key):
		return STRINGS[target_lang][key]
	if STRINGS.has("en") and STRINGS["en"].has(key):
		return STRINGS["en"][key]
	return key

func translate(message: StringName, context: StringName = &"") -> String:
	var key = str(message)
	var lang = str(context)
	return get_string(key, lang)

func t(message: StringName, context: StringName = &"") -> String:
	return translate(message, context)

@warning_ignore("native_method_override")
func tr(message: StringName, context: StringName = &"") -> String:
	return translate(message, context)

func format(key: String, args: Array, lang: String = "") -> String:
	var text = get_string(key, lang)
	for i in range(args.size()):
		text = text.replace("{%d}" % i, str(args[i]))
	return text
