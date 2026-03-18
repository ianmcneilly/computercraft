# Direwolf20 1.21 — CC:T Mod Integration Overview

> Modpack: FTB Presents Direwolf20 1.21 (Season 14, pack version 1.14.2)
> CC:T Version: 1.115.1
> Total mods in pack: ~292

This document tracks which mods in the Direwolf20 1.21 pack have CC:T peripheral support and what can be done with them.

## Confirmed Mods with CC:T Peripheral Support

### Mekanism
- **Peripheral types**: Most machines and multiblock controllers expose peripherals. Types include machine-specific names like `"mekanism:fission_reactor_logic"`, `"mekanism:digital_miner"`, `"mekanism:energy_cube"`, etc.
- **Capabilities**: Read energy levels, temperatures, production rates. Monitor fission reactor status (damage, temp, coolant). Control digital miner. Read chemical tank contents. Monitor fusion/SPS stats.
- **Sub-mods in pack**: Mekanism, Mekanism Generators, Mekanism Tools, Mekanism Additions
- **Doc status**: NOT YET DOCUMENTED

### Applied Energistics 2
- **Peripheral types**: ME Bridge block provides `"ae2:me_bridge"` (if Advanced Peripherals is present), or native CC:T integration via network-connected blocks
- **Capabilities**: List items in ME network, request autocrafting, check craftable items, monitor storage capacity, get energy usage
- **Doc status**: NOT YET DOCUMENTED

### Refined Storage
- **Peripheral types**: `"rs_bridge"` (via Advanced Peripherals if present), or generic inventory peripheral
- **Capabilities**: List stored items, request crafting, import/export items, energy monitoring
- **Doc status**: NOT YET DOCUMENTED

### Ender IO
- **Peripheral types**: Machine-specific peripherals, generic inventory/energy access
- **Capabilities**: Read energy, transfer items, check machine progress, conduit interaction
- **Doc status**: NOT YET DOCUMENTED

### Create
- **Peripheral types**: Limited native CC:T support. Some blocks accessible as generic peripherals.
- **Capabilities**: Basic block interaction via generic inventory/fluid peripherals. Rotation speed and stress monitoring may require addon mods.
- **Doc status**: NOT YET DOCUMENTED

### PneumaticCraft: Repressurized
- **Peripheral types**: Most machines expose CC:T peripherals natively
- **Capabilities**: Read pressure levels, monitor drone status, interact with logistics system, read temperature, control machines
- **Doc status**: NOT YET DOCUMENTED

### RFTools (Power + Utility)
- **Peripheral types**: Various machine peripherals
- **Capabilities**: Energy monitoring, dimension management, spawner control, shield management
- **Doc status**: NOT YET DOCUMENTED

### Industrial Foregoing
- **Peripheral types**: Machine peripherals
- **Capabilities**: Monitor machine status, energy levels, progress
- **Doc status**: NOT YET DOCUMENTED

### Occultism
- **Peripheral types**: Some blocks may expose peripherals
- **Capabilities**: TBD — investigate when needed
- **Doc status**: NOT YET DOCUMENTED

## Generic Peripheral Access

Any mod block that exposes Forge capabilities can be wrapped by CC:T when connected via wired modem:

- **`"inventory"`** — Any block with item handler (chests, machines, hoppers, etc.)
  - Methods: `list()`, `pushItems()`, `pullItems()`, `getItemDetail()`, `size()`, `getItemLimit()`
- **`"fluid_storage"`** — Any block with fluid handler
  - Methods: `tanks()`, `pushFluid()`, `pullFluid()`
- **`"energy_storage"`** — Any block with Forge Energy
  - Methods: `getEnergy()`, `getEnergyCapacity()`

This means virtually every machine in the pack can at minimum be queried for items, fluids, and energy via CC:T.

## Mods Without CC:T Peripheral Support

These mods are in the pack but have no known CC:T integration:
- JEI, Jade, AppleSkin (client-side / UI mods)
- Waystones, The Twilight Forest, Dungeon Crawl (gameplay/exploration)
- Mouse Tweaks, Clumps, Light Overlay (QoL/utility)
- Curios API, KubeJS (framework/API mods)
- MineColonies / Structurize (own automation system)

## Notes

- **Advanced Peripherals**: Check if this mod is installed — it dramatically expands CC:T integration with AE2, RS, Mekanism, and adds chat boxes, player detectors, etc. Needs confirmation whether it's in this pack.
- Peripheral docs will be created on-demand in `docs/peripherals/<modname>.md` as needed.
- Use `peripheral.getType()` and `peripheral.getMethods()` in-game to discover available peripherals on any block.
