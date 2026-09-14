# Anime Dice — Game Data

Straight from the game's config (`tools/exportall.lua` → `AnimeDice_gamedata.txt`).
Ground truth, not a fan wiki.

## Grades (income multiplier, low → high)

| Grade | Income × | Weight | Protected |
|-------|----------|--------|-----------|
| D  | 1.1×  | 4500 | |
| C  | 1.25× | 2800 | |
| B  | 1.6×  | 1500 | |
| A  | 3×    | 800  | |
| A+ | 4.5×  | 300  | |
| S  | 7×    | 90   | ✓ |
| S+ | 10×   | 11   | ✓ |
| Z  | 15×   | 3    | ✓ |
| Z+ | 25×   | 0.8  | ✓ |
| 神 | 50×   | 0.2  | ✓ |

Lower weight = rarer. "Keep Grades" should target S and up.

## Traits (multiplier, low → high)

| Trait | Effect | Weight | Protected |
|-------|--------|--------|-----------|
| Money I / II / III  | income 1.2 / 1.5 / 2× | 1000 / 250 / 50 | |
| Damage I / II / III | dmg 1.2 / 1.5 / 2×    | 1000 / 250 / 50 | |
| Health I / II / III | hp 1.2 / 1.5 / 2×     | 1000 / 250 / 50 | |
| Samurai      | 3× income/dmg/hp   | 20   | ✓ |
| Shogun       | 5× all             | 5    | ✓ |
| Monarch      | 8× all             | 1    | ✓ |
| Transcendent | 15× all            | 0.25 | ✓ |
| Eternal      | 5× all             | —    | |

## Dice (by luck — the real "best" order)

| Dice | Luck | Rarity | Price |
|------|------|--------|-------|
| Toxic     | 150,000,000 | Secret II | 7.5e23 |
| Cyber     | 62,500,000  | Secret I  | 1e23 |
| Chrono    | 25,000,000  | Secret I  | 1.5e22 |
| Titan     | 10,000,000  | Secret I  | 1e21 |
| Corrupted | 5,000,000   | Celestial | 1.5e20 |
| Arcane    | 2,000,000   | Celestial | 1.2e19 |
| Prismatic | 1,000,000   | Celestial | 1e18 |
| Royal     | 400,000     | Exotic    | 1e17 |
| Dragon    | 200,000     | Exotic    | 8.5e15 |
| Black Hole| 100,000     | Divine    | 1e15 |
| Galaxy    | 50,000      | Divine    | 1.5e14 |
| Lunar     | 25,000      | Mythical  | 3.75e13 |
| Solar     | 12,500      | Mythical  | 5e12 |
| Void      | 6,000       | Legendary | 7.5e11 |
| Blood Moon| 3,000       | Legendary | 1e11 |
| Light     | 1,500       | Legendary | 1.2e10 |
| Shadow    | 750         | Epic      | 1.5e9 |
| Storm     | 400         | Epic      | 2e8 |
| Magma     | 200         | Epic      | 3e7 |
| Ice       | 100         | Rare      | 4e6 |
| Lightning | 42.5        | Rare      | 5e5 |
| Nature    | 20          | Rare      | 75,000 |
| Water     | 10          | Uncommon  | 10,000 |
| Fire      | 5           | Uncommon  | 2,500 |
| Normal    | 2           | Common    | 1 |
| Basic     | 1           | Common    | — |

Auto Equip Best keeps **Toxic** on (highest luck).

## Potions (categories × tiers)

Categories: **Damage / Luck / Income** (base) plus themed families **Cursed,
Dragon, Leaf, Pirate**. One of each *category* can be active at once — the
script auto-picks the highest tier per category and re-uses only on expiry.

Durations by family: base **300s**, Leaf **210s**, Pirate **240s**, Cursed
**180s**, Dragon **120s**.

Peak multipliers: Damage IV 5×, Income IV 4×, Luck IV 4.25×; Leaf III 4× (dmg/luck),
3× (income); themed tiers scale 1.25× → 4×.

## Spins

- **Lucky Spin** — 100× luck next roll (Exotic)
- **Jackpot Spin** — 1,000× luck next roll (Celestial)

## Towers (difficulty / floors)

| Tower | Difficulty | Order | Drops |
|-------|-----------|-------|-------|
| Dragon Tower      | Easy    | 1 | Dragon potions, Gems |
| Cursed Tower      | Medium  | 2 | Cursed potions, Gems, Trait Reroll |
| Pirate Tower      | Hard    | 3 | Pirate potions, Gems, Trait Reroll |
| Hidden Leaf Tower | Extreme | 4 | Leaf potions, Gems, Trait Reroll |
| Infinity Tower    | Infinity| 5 | base potions, Gems, Trait Reroll (best, no floor cap) |

Drop tiers unlock at floors 1 / 25 / 60 (Infinity adds 100 / 150).

## Rebirths (12 tiers)

| # | Cost | Money & Luck × |
|---|------|----------------|
| 1 | 50K   | 1.5× |
| 2 | 5M    | 2× |
| 3 | 500M  | 2.5× |
| 4 | 50B   | 3× |
| 5 | 5T    | 4× |
| 6 | 500T  | 5× |
| 7 | 1e16  | 6.5× |
| 8 | 1e18  | 8.5× |
| 9 | 1e20  | 11× |
| 10| 1e22  | 14× |
| 11| 1e24  | 17.5× |
| 12| 1e26  | 22.5× |

## Codes

`RELEASE` (+10K money), `UPDATE1`–`UPDATE4`, `1KCCU`, `5KCCU`, `10KCCU`, `20KCCU`
— all give Gems / Trait Reroll / Lucky Spin. `UPDATE4` is the biggest
(10× Gems/Tickets/Trait Reroll + 3 Lucky Spin).
