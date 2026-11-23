# Project State: The Lethe Protocol: Concord 2084

## Overview
- **Game Title**: The Lethe Protocol: Concord 2084
- **Engine**: Godot 4.7.2 (Forward+/OpenGL)
- **Genre**: Narrative-Driven Top-Down Detective / Puzzle Adventure (Pixel Art Cyberpunk Noir Nusantara)
- **Lead Character**: Arthur Vance

## Architecture & Directory Structure
- `project.godot`: Project settings, 16:9 resolution 640x360 (window override 1280x720), stretch mode `canvas_items`, nearest texture filter, custom global font `PressStart2P-Regular.ttf`, and input mappings (`move_up`, `move_down`, `move_left`, `move_right`, `toggle_notebook`).
- `assets/`:
  - `characters/`: Frame animasi aktif berada di folder `characters/player/` dan `characters/npcs/` (termasuk portrait wajah `depan.png`).
  - `fonts/`: Font global retro pixel `PressStart2P-Regular.ttf`.
  - `map/`: Base city map (`city.png`, native 1280x960) dan `WorldMap.png`.
  - `ui/`: Complete UI Essential Pack Free dan Cozyland UI (frame, tombol, ikon, banner).
  - `wallpaper/`: Ikon barang bukti untuk Item Combiner (`Kaset.png`, `Kaset2.png`).
- `scenes/`:
  - `player.tscn`: `CharacterBody2D` with `AnimatedSprite2D` (`player_sprite_frames.tres`, scale `Vector2(0.12, 0.12)`, rendered height ~55px), body collision shape (`RectangleShape2D` `22x18` at `Vector2(0, 16)`), and smoothed `Camera2D`. `player.gd` exposes `set_map_bounds(size, follow, zoom)`; the world scene applies it per map (`outdoor` follow camera, `indoor` fixed full-room camera, both at zoom 0.85).
  - `npc.tscn`: `StaticBody2D` representing Director Lucian Graves (The Registry) with `AnimatedSprite2D` (`lucian_sprite_frames.tres`, scale `Vector2(0.12, 0.12)`, normalized 4-direction rendered height ~55px matching Arthur Vance), foot collision `(22, 18)` at `(0, 16)`, interaction detection radius, 4-directional facing, and floating "[E] Bicara" prompt.
  - `npc_garrick.tscn`: Modular NPC scene for Garrick Shaw with `garrick_sprite_frames.tres` (4-directional walk & idle) and unified `scale = Vector2(0.12, 0.12)`.
  - `npc_lucian.tscn`: Modular NPC scene for Director Lucian Graves with `lucian_sprite_frames.tres` (4-directional walk & idle) and unified `scale = Vector2(0.12, 0.12)`.
  - `npc_edward.tscn`: Modular NPC scene for Edward Vance with `edward_sprite_frames.tres` (4-directional walk & idle) and unified `scale = Vector2(0.12, 0.12)`.
  - `dialogue_box.tscn`: Cyberpunk noir UI dialogue box berfitur lengkap (layout panel bawah layar 600x66px beraksen Cyberpunk Blue/Cyan dengan StyleBoxFlat obsidian blue #041424, border neon cyan #00f0ff 2px, corner radius 4px, tanpa portrait/foto karakter, banner nameplate dinamis di kiri atas dengan teks cyan, aksen role tab di kanan atas, padding/margin rapi tanpa offset hack, teks putih es #e8fcff, panah pulsing next indicator cyan, dan pilihan respons dialog cabang bergaya cyberpunk dengan navigasi keyboard panah atas/bawah).
  - `detective_notebook.tscn`: UI Buku Catatan Detektif / Inventory (tab Bukti, Catatan, Profil, Peta investigasi) dengan hotkey [Tab], autoscaling responsif, dan animasi buka/tutup buku (unfold horizontal + fade, bisa diinterupsi).
  - `item_combiner.tscn`: CanvasLayer UI sintesis barang bukti (daftar bukti, dua slot komponen, hasil, HP bar, tombol proses), hotkey [C], autoscaling ke viewport (skala ~0.55, sedikit lebih kecil dari notebook). Design palette disamakan dengan notebook (teal/cyan), slot hasil 84x84 konsisten dengan slot komponen, close label `Tutup [Esc]`. Nine-patch margins diperbaiki (panel/slot 12px, banner 16/8) supaya border tidak melar dan tidak muncul garis gelap di judul. Duplikat aset dibersihkan: folder `assets/ui` dihapus (isi identik dengan pack di `assets/`), font root `assets/PressStart2P-Regular.ttf` dihapus dan semua referensi diarahkan ke `assets/fonts/`. Readability pass: overlay scanline dihapus, UI di-set `texture_filter = 2` (linear) agar teks tidak kasar saat diskalakan, ukuran font body/title dinaikkan, line spacing RichTextLabel diperlebar, dan baris inventory diubah jadi dua baris (nama 11px di atas, qty/status 9px di bawah) supaya tidak berdesakan. Outline seleksi item diganti dari tekstur `UI_Flat_Select01a_2` (punya end-cap hitam) menjadi border cyan 2px bersih via `StyleBoxFlat` di notebook dan combiner. Background baris dan tab juga diganti `Button` + `StyleBoxFlat` (tekstur lama punya border hitam yang melar). Scrollbar combiner disamakan dengan notebook: track `UI_Flat_Bar02a` 14px + handle `UI_Flat_Handle01a` 18x28 (x386, tidak menabrak list yang berakhir di x382).
  - `main_menu.tscn`: Main scene (`project.godot`) — layar judul "THE LETHE PROTOCOL / CONCORD 2084" dengan dot-grid + corner bracket, vignette radial, tombol `MULAI INVESTIGASI` dan `KELUAR` (StyleBoxFlat, fokus keyboard), hint kontrol, dan fade-in.
  - `world.tscn`: Gameplay scene with a black `Backdrop` CanvasLayer, `MapRoot` container, `DialogueBox`, `DetectiveNotebook`, `ItemCombiner`, and a fade `FadeLayer`; owns the persistent Player and swaps maps.
  - `maps/outdoor_city.tscn`: Outdoor map `1280x960` (native city.png, no upscale), `StaticBody2D` road boundaries matching the new building layout (L-shaped top-left block plus 5 building lots), 4 NPCs (Lucian 1060, 550; Garrick 290, 550; Edward 290, 220; Patrol Officer 1060, 220), and an entrance door at the top-centre building (952, 152) leading indoors.
  - `maps/indoor_office.tscn`: Indoor office `640x340` with walls, desk, shelf, cabinet, plant, rug, exit mat, and a bottom door (320, 330) returning outdoors; fixed 0.85 camera shows the whole room with black borders.
- `scripts/`:
  - `player.gd`: Top-down movement controller handling 4-directional sprite animation playback (`walk_down`, `walk_up`, `walk_left`, `walk_right`, `idle_*`), normalized movement, WASD/arrow key input handling, collision physics, per-map camera bounds (`set_map_bounds`), `player` group membership, dan otomatis pause saat berdialog atau membuka notebook.
  - `main_menu.gd`: Main-menu logic — builds background decor, connects Start (`change_scene_to_file` ke `world.tscn`) dan Quit, grab focus tombol Start, fade-in, `[Esc]` keluar.
  - `world.gd`: Map manager — instantiates map scenes under `MapRoot`, reparents the persistent Player into the active map (shared Y-sort with NPCs), applies camera config, connects door signals, and runs fade transitions.
  - `item_combiner.gd`: Item-combiner logic (inventory rows, recipe matching, wrong-combine HP penalty, craft result, open/close animations, [C]/[Esc] input, responsive scale).
  - `map_door.gd`: `Area2D` door trigger (class `MapDoor`) emitting `door_entered(target_map, spawn_position)` when the player group touches it.
  - `npc.gd`: Modular NPC trigger script supporting `AnimatedSprite2D` 4-arah, otomatis menatap arah player saat didekati/diajak bicara, customizable `speaker_name`, `dialogue_lines`.
  - `dialogue_box.gd`: Dialogue system manager handling typewriter text effect, responsive speaker nameplate auto-sizing, line transitions, input advancing (E / Spacebar / Enter / Click), dan keyboard-navigable branch choices (focus grabs).
  - `detective_notebook.gd`: Inventory / notebook manager handling tab switching, item navigation, log inspection, dan map pin tracking.

## Current Status (2026-11-18)
- [x] Initial Godot 4 project configuration.
- [x] Top-down 4-directional player movement with directional sprite swapping.
- [x] Smooth Camera2D following the player with bounding limits.
- [x] Road & perimeter collision system (11 collision boxes restricting movement to valid streets).
- [x] NPC Entity placed at far southeast road intersection (530, 335) with 4-directional turn-to-face.
- [x] Floating interaction indicator ("[E] Bicara") appearing when entering NPC proximity.
- [x] Interactive cyberpunk noir dialogue box with living half-body portraits, typewriter text effect, choice buttons, and automatic player freeze.
- [x] Detective Notebook / Inventory system with 4 tabs (Bukti, Catatan, Profil, Peta) toggleable with [Tab] / [Esc], with automatic player freeze.
- [x] Global project font configured to `PressStart2P-Regular.ttf` across all UI and labels.
- [x] High-resolution 4-directional walk and idle animation frames updated for all NPCs (Garrick, Lucian, Edward) and Player.
- [x] Normalized all NPC sprite frame assets across 4 directions (front, back, left, right) to canonical height (~458px, 55px rendered), aligning baseline foot at y=673 and head level with Arthur Vance.
- [x] Unified all character node scales to `Vector2(0.12, 0.12)` with foot collision `(22, 18)` at `(0, 16)`.
- [x] Updated NPC `face_target()` to calmly use `idle_*` animations when facing the player instead of walking in place.
- [x] NPCs now keep their default front-facing idle when the player approaches; they only turn toward the player at the moment [E] interaction starts, and return to `idle_down` (front) once the dialogue ends.
- [x] Headless verification passing with zero errors across all 4 directions.
- [x] Placed all 4 NPCs across the city map intersections with distinct lore dialogues, non-overlapping interaction radiuses, and dynamic player-facing.
- [x] Player/NPC collision fixed: body colliders enlarged to `(22, 18)` at `(0, 16)`, player `motion_mode` set to Floating, and `Main` Y-sorted for correct front/back depth.
- [x] Switched to 16:9 (viewport 640x360, window 1280x720) and made camera bounds configurable per map (`map_size`, `follow_player`).
- [x] Outdoor world `1280x960` using the new native-resolution city map (`assets/maps/city-fix.png`, copied to `assets/map/city.png`, drawn 1:1).
- [x] Main menu (`main_menu.tscn`) sebagai scene utama, dengan tombol Mulai/Keluar dan gaya UI yang sama (teal/cyan, PressStart2P).
- [x] Multi-map world system (`world.tscn` + `world.gd`): persistent player reparented per map, door triggers with fades, and per-map camera config.
- [x] Indoor office map `640x340` with a fixed 0.714 camera (whole room + black borders) reached from the top-centre building entrance; exit door returns to the city at (952, 200).
- [x] Dialogue box and Detective Notebook made responsive for the 640x360 base: dialogue now uses a side-by-side layout (64px portrait left, text panel right, total box 608x64 / ~18% height) with the speaker nameplate and DATA STREAM tab floating above the box, font 8, and the next arrow anchored bottom-right; the notebook scales to 82% of the viewport while accounting for the left bookmark overhang (book ~487x277, tabs stay inside the window).
- [x] Notebook styling polish: tab labels now fill the 74px tab and center cleanly, title banner and tab dots centered to the page axis, row name/qty columns widened to 208/76, empty rows hidden, scrollbar hidden when all items fit, map pin labels centered, interactive labels set to mouse-ignore, and English labels localized (`Bukti`, `Tutup [Esc]`).
- [x] Item Combiner UI integrated into the world: opens/closes with [C] or [Esc], freezes the player, and autoscales to ~0.55x on the 640x360 viewport (slightly smaller than the notebook).
- [x] Item Combiner polish: palette, frame colors, typography (name 10px + ellipsis, tag right-aligned), 84x84 result slot, shorter connector beam, scrollbar for >6 items, hidden empty rows, and footer hints (`[Enter] Pilih Slot  [Tab] Catatan`, `[C]/[Esc] Tutup`).
- [x] Camera zoom set to 0.85 on both maps (wider than the original 1.4); indoor camera is fixed and shows the entire room with black borders.
- [x] Notebook open/close animation: fast horizontal unfold from the center with a slight overshoot and fade (0.26s open, 0.2s close), pivot-centred on the book so the responsive 82% scale is preserved; toggling mid-animation reverses cleanly.
- [x] Notebook now shows a "Tekan [C] untuk Gabungkan Bukti" reminder, and the notebook/item-combiner are mutually exclusive with sequenced transitions: [C] fully closes the notebook first (0.2s) then opens the combiner, [Tab] fully closes the combiner first (0.38s) then opens the notebook, with player freeze held through the whole switch.

## GODOT_AI_PLAN Integration (2026-11-23)

### Implemented
- **Autoload core**: `SettingsManager`, `SaveManager`, `GameManager`, `UIManager` registered in `project.godot`.
- **Settings system**: `SettingsManager.gd` + `scenes/menu/settings_menu.tscn` (Master/BGM/SFX sliders via AudioServer, Fullscreen toggle via DisplayServer, persistent to `user://settings.cfg`).
- **In-Game Pause Menu**: `scenes/menu/pause_menu.tscn` + `UIManager.gd` (dibuka via `Esc` / `P` saat in-game; berisi opsi Lanjutkan, Pengaturan in-game, Simpan Cepat, Menu Utama, dan Keluar; UI bergaya cyberpunk dengan margin dan padding rapi).
- **Save system & slot management**: JSON slots at `user://saves/slot_N.json`, slot metadata reader, delete, typed-array-safe load, serta preservasi posisi terakhir karakter (`player_pos_x`, `player_pos_y`, dan `current_map`) saat manual maupun quick-save. UI Save Select dibersihkan dari indikator internal MEM & SUS sehingga hanya menampilkan judul chapter dan timestamp rekaman.
- **Dialogue UI Polish**: Menghapus seluruh dependensi portrait/foto karakter dan merombak tampilan dari warna kuning/beige parchment ke tema **Cyberpunk Blue / Neon Cyan**:
  - Background panel utama menggunakan obsidian dark blue (`Color(0.02, 0.08, 0.14, 0.96)`) dengan border 2px neon cyan (`#00f0ff`), corner radius 4px, dan bayangan glow cyan halus.
  - Membuang hack offset kotor (`SelectOutline` dengan offset -2px telah dihapus).
  - Merapikan padding dan margin secara simetris: `MarginContainer` margin kiri 16px, atas 10px, kanan 32px (memberi ruang nafas bagi indikator panah), bawah 10px.
  - Nameplate pembicara melekat rapi di sudut kiri atas (`offset_left = 12px`, `offset_top = -22px`, `offset_bottom = 0px`) dengan teks neon cyan (`#00f0ff`) dan penyesuaian lebar dinamis berbasis panjang nama.
  - Tab kanan ("DATA STREAM" / Role badge) melekat di sudut kanan atas dengan teks soft cyan (`#88d4e8`).
  - Warna teks dialog diganti menjadi putih es tajam berdaya kontras tinggi (`#e8fcff`) menggantikan teks abu gelap lama (`#1e242b`).
  - Next indicator panah berkedip halus (pulsing tween) dengan warna neon cyan (`#00f0ff`).
  - Tombol pilihan respons (branch choices) diubah menggunakan `StyleBoxFlat` bertema cyberpunk biru/cyan dengan efek hover/fokus bercahaya dan navigasi panah keyboard.
- **Menu flow**: `scenes/menu/main_menu.tscn` (Start, Load, Settings modal, Exit) → `scenes/menu/save_select.tscn` (3 slots, continue, new game, delete button with danger styling, modal konfirmasi cyberpunk, dan padding lega).
- **Prologue cutscene**: `scenes/cutscenes/cutscene_player.tscn` (text slides, skip, fade, auto-advance to Chapter 1).
- **Chapter chain**: `scenes/chapters/chapter_1..5/` with `chapter_base.gd`, map config, exit triggers, and suspicion-based Ending 4 trigger in Chapter 4.
- **Reusable components**: `scenes/common/interactable.tscn`, `exit_trigger.tscn`, `ending_terminal.tscn`, `player.tscn`.
- **Endings**: `scenes/endings/ending_1..5.tscn` + shared ending screen; eligibility checks for memory/suspicion thresholds.
- **Sintesis Bukti & Sinkronisasi Inventaris**: Fitur puzzle memutar-mutar bukti (`AffinePuzzle`) resmi dihilangkan dari gameplay dan tidak ada titik stasiun puzzle pengganti di map. Sebagai gantinya, bukti yang diinteraksi di dunia langsung otomatis masuk ke Inventaris (`DetectiveNotebook` tab Bukti) dan `ItemCombiner` (dibuka via `[C]`). Ketika 2 bukti berhasil digabungkan di `ItemCombiner`, kedua bukti asal dihapus dan digantikan oleh bukti gabungan baru di `ItemCombiner`, `DetectiveNotebook`, dan `GameManager` secara reaktif via sinyal `inventory_updated`.
- **Input Interaksi**: Tombol interaksi difokuskan eksklusif hanya ke tombol `[E]` (input Spasi dihapus dari action `interact` dan seluruh script interaksi). Seluruh prompt HUD menggunakan format `[E] ...`.
- **Smoke test & Verifikasi**: Seluruh unit test, scene loader, save/load slot, dan tes sinkronisasi inventaris lolos pengujian headless (`TEST INTERACTION & INVENTORY SYNC PASS` & `SMOKE_TEST_DONE`).

### Partial / Not Yet Wired
- Chapter scenes reuse the existing `world.tscn` maps; full per-chapter tilesets, cutscene art, and audio are not present.
- Dialogue JSON and evidence database are source-of-truth files, but runtime still uses hardcoded NPC lines and the notebook's internal `db` dictionary.
- `UIManager` HUD and Mind Vault are stubs (`HUDPanel` empty; `toggle_mind_vault` looks for a `MindVaultUI` node that does not exist yet).
- Deduction chain is exposed through `GameManager.unlock_deduction` but there is no Mind Vault connection UI.
- `DialogueBox`, `DetectiveNotebook`, and `ItemCombiner` remain under `scenes/` + `scripts/` (not moved into `UIManager`) to avoid regressing the working overlays.

## Next Steps for Future Iterations
1. Build the Mind Vault deduction UI and connect it to `GameManager.unlock_deduction`.
2. Add chapter-specific interactables/tilesets and connect chapter data JSON into `DialogueManager`/notebook.
3. Replace placeholder cutscene colors with real still-frame art in `assets/cutscenes/` according to `../docs/CUTSCENE_SPECIFICATION.md`.
