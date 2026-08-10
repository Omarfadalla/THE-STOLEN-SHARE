# The Stolen Share — Horror Splash / Loading Screen

## Files
- `SplashScreen.tscn` — the scene
- `SplashScreen.gd` — the logic
- `assets/splash_bg.png` — your title art, used as the animated background

## Setup (Godot 4.x)
1. Drop this whole folder into your project (or copy `SplashScreen.tscn`,
   `SplashScreen.gd`, and `assets/splash_bg.png` in, keeping the same
   relative paths — the scene references the texture at
   `res://assets/splash_bg.png`).
2. Open `SplashScreen.tscn`, select the root **SplashScreen** node, and in
   the Inspector set **Next Scene Path** to whatever scene should load
   after the splash (your main menu or game world), e.g.
   `res://scenes/MainMenu.tscn`.
3. Go to **Project > Project Settings > Application > Run > Main Scene**
   and set it to `SplashScreen.tscn`.
4. Run the project.

## What it does
- Fades the key art in from black with a slow, endless "Ken Burns" breathing
  zoom.
- A vignette shader darkens the edges and gently pulses like candlelight,
  with rare sharp red flicker bursts for dread.
- A loading panel fades in beneath the art: a rotating list of in-world
  loading messages ("Sharpening the blades...", "The key remembers..."),
  a blood-red progress bar, a percentage readout, and a flavor-text hint
  line.
- The progress bar is wired to Godot's real threaded resource loader
  (`ResourceLoader.load_threaded_request`) for the scene you set in
  **Next Scene Path** — it shows genuine load progress, not a fake timer,
  though `Min Display Time` (default 4.5s) guarantees it never flashes by
  too quickly even on a fast load.
- If the target scene isn't found yet (e.g. you haven't built it), it
  falls back to a smooth simulated bar over `Min Display Time` so you can
  still preview the splash on its own.
- On finish: message swaps to "The door is open...", holds a beat, then
  the whole screen fades to black and switches to your next scene.

## Easy tweaks
- **Messages / hints**: edit the `loading_messages` and `hints` arrays at
  the top of `SplashScreen.gd`.
- **Timing**: `min_display_time` (export var) controls the minimum splash
  length. Tween durations throughout the script control fade/zoom speed.
- **Flicker intensity/frequency**: `_schedule_harsh_flicker()` — adjust the
  `randf_range()` delay and the alpha values in the tween chain.
- **Colors**: the progress bar, text outline, and flicker overlay all use
  dark blood-red tones (`Color(0.55, 0.03, 0.03, 1)` etc.) — change these
  in the `.tscn` (StyleBoxFlat / theme overrides) to match your palette.
- **Vignette strength**: tweak the `strength` / `softness` uniforms on the
  shader in `SplashScreen.tscn`, or expose them and adjust in the Inspector.
- **Add sound**: add an `AudioStreamPlayer` node as a child of
  `SplashScreen`, assign an ambient drone / creaking sound, and call
  `$AudioStreamPlayer.play()` near the top of `_ready()` in the script.
