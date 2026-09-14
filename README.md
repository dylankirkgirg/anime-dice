# Anime Dice

Obsidian-UI script for the Roblox game **Anime Dice**. Fires the game's own
`RollService` / `SellService` remotes — no hidden payloads, no third-party
hub loader.

## Tabs

**Main**
- **Auto Roll (native)** — flips the game's own `SetAutoRoll` toggle server-side.
- **Manual Roll Loop** + speed slider — hammers `RollDice` directly. Fallback if the native toggle doesn't roll.
- **Auto Sell (native)** — flips `UpdateAutoSell` so inventory doesn't cap out.
- **Sell Inventory / Sell Equipped** — one-shot sell buttons.

**Player**
- **Movement** — WalkSpeed toggle + amount slider, Infinite Jump, NoClip, Instant ProximityPrompt.
- **Fly** — toggle + speed slider. WASD + Space/Shift, camera-relative.
- **Performance** — FPS Boost (low quality, no shadows, no particles, flat water) · GPU Saver (disable 3D rendering — big GPU/battery win, UI stays) · Anti-AFK (blocks the 20-min idle kick). All reversible.
- **Configs** — save / load / **autoload** your settings (Obsidian SaveManager).
- **Themes** — Obsidian ThemeManager picker.

**RightShift** — show/hide the UI.

## Auto-execute

Two layers:

1. **Settings** — set a config as *autoload* in the UI tab. On every inject, saved
   toggles (Auto Roll, Auto Sell, FPS Boost, Anti-AFK) re-fire automatically.
2. **On launch** — drop `loader.lua`'s loadstring into Opiumware's **autoexec**
   folder so the script runs itself the moment you join, no manual inject.

Toggles also re-apply after a respawn.

## Setup

1. Create a GitHub repo named `anime-dice`, push these files (keep the `src/` folder).
2. Edit [`loader.lua`](loader.lua): set `GITHUB_USER` to your GitHub username.
3. Inject (or drop in autoexec):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/anime-dice/main/loader.lua"))()
```

`loader.lua` pulls the latest `src/main.lua` each run — edit, push, re-inject. No re-pasting.

## Notes

- Everything is **server-authoritative**: currency/rolls are decided by the
  server. This automates the real actions fast; it can't fabricate currency.
- If **Manual Roll Loop** does nothing, `RollDice` probably wants an argument
  (dice tier). Spy one real roll and we match the arg.

## Remote map (from `ReplicatedStorage.Network`)

| Purpose      | Remote                              | Type           | Call                |
|--------------|-------------------------------------|----------------|---------------------|
| Native auto  | `RollService.RE.SetAutoRoll`        | RemoteEvent    | `FireServer(bool)`  |
| Roll once    | `RollService.RF.RollDice`           | RemoteFunction | `InvokeServer()`    |
| Native sell  | `SellService.RE.UpdateAutoSell`     | RemoteEvent    | `FireServer(bool)`  |
| Sell all     | `SellService.RF.SellInventory`      | RemoteFunction | `InvokeServer()`    |
| Sell equipped| `SellService.RF.SellEquipped`       | RemoteFunction | `InvokeServer()`    |
