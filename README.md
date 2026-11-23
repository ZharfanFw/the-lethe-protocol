# The Lethe Protocol: Concord 2084

Narrative-driven top-down detective & puzzle adventure game (*Pixel Art Cyberpunk Noir Nusantara*) built with **Godot 4.7.2**.

## Struktur Direktori

- `godot/` — Proyek utama Godot 4 (`res://`), berisi `project.godot`, scene, script, data dialog/bukti, aset runtime, dan headless test.
- `docs/` — Dokumentasi desain, proposal capstone, naskah 5 chapter, Twine script, dan spesifikasi cutscene.
- `art_sources/` — File sumber mentah `.aseprite` dan sprite sheet sebelum dipotong ke `godot/`.

## Menjalankan Proyek

1. Buka **Godot Engine 4.7.2**.
2. Klik **Import** dan arahkan ke `godot/project.godot`.
3. Jalankan proyek (`F5`) — scene utama adalah `res://scenes/menu/main_menu.tscn`.

### Kontrol Dasar

- `W A S D` / `Arrow Keys`: Bergerak
- `E`: Interaksi / Periksa objek & bicara dengan NPC
- `Tab`: Buka/tutup *Detective Notebook*
- `C`: Buka/tutup *Item Combiner*
- `Esc` / `P`: Pause Menu

## Pengujian Headless

```bash
godot --headless --path godot res://tests/smoke_test.tscn
godot --headless --path godot res://tests/test_interaction.tscn
godot --headless --path godot res://tests/audit_dialogue_box.tscn
```
