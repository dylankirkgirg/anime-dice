# Anime Dice

Obsidian-UI script for the Roblox game **Anime Dice**. Fires the game's own
remotes — mapped from `ReplicatedStorage.Network` with the recon tools in
[`tools/`](tools). No hidden payloads, no third-party hub loader.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/dylankirkgirg/anime-dice/main/loader.lua"))()
```

Drop it in Opiumware's autoexec folder to run on join. (raw CDN caches ~5 min;
paste `src/main.lua` raw for instant iteration.)

## Tabs

- **Farm** — Auto Roll (+delay), Auto Collect Money (+plot id), Auto Rebirth, Auto Spin, Auto Claim Quest / Claim All, Redeem Code · Equip: Auto Equip Best, Auto Equip Best Dice
- **Units** — Auto Grade (unit + keep-grades), Auto Trait (unit + keep-traits), Auto Lock (by rarity), Sell Inventory / Sell When Full, Auto Upgrade placed units. Reads your live inventory; **Refresh Unit List** rescans.
- **Tower** — Auto Tower, mode, map rotation, runs per map, stop-at-floor, auto equip best team
- **Shop** — Auto Use Potions (multi-select), Auto Buy Dice. (Auto-buy upgrades deferred — remote not captured.)
- **Trade** — request by username, auto-accept, requests-enabled toggle. (Auto-offer/confirm deferred — needs a captured trade.)
- **Webhook** — Unit webhook (new rolls, rarity-filtered → Discord) + Inventory webhook. Needs executor `http_request`.
- **Player** — WalkSpeed, Infinite Jump, NoClip, Instant ProximityPrompt, Fly, FPS Boost, GPU Saver, Anti-AFK
- **Settings** — config save/load/**autoload** (SaveManager) + theme (ThemeManager)

**RightShift** or the on-screen button toggles the UI. Native cursor (no crosshair).

## Data sources (ground truth)

| What              | From                                             |
|-------------------|--------------------------------------------------|
| Remote paths      | `tools/dump.lua` → `reference/AnimeDice_dump.txt` |
| Remote args       | `tools/argspy.lua` (namecall hook)               |
| Dropdown lists    | `tools/values.lua`                               |
| Inventory shape   | `tools/inv.lua` → `Client.data.___X.Inventory`   |

Unit rarity isn't stored per-unit — it's mapped from `UnitConfig.entries[name]`
at runtime.

## Inferred / deferred

- **Inferred** (fired by analogy, verify on use): `Unequip(uuid)`, `SetGradeProtected/SetTraitProtected({[uuid]=bool})`, `BuyDice(name)`, `SpinUse("Lucky Spin")`.
- **Deferred** (need capture): trade offer/confirm (`ChangeOffer`/`AdvanceTrade`), auto-buy upgrades remote.
