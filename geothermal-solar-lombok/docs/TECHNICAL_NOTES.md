# Technical Notes — Geothermal-Solar Hybrid Power Plant

## 1. Geothermal Power Plant — Thermodynamic Model

### Plant Configuration

The geothermal plant uses a **dual-pressure flash steam** design drawing from two borehole types:

- **High-pressure boreholes** → Steam Separator 1 → Turbine 1 (40 MW generator)
- **Low-pressure boreholes** → Steam Separator 2 → Turbines 2 & 3 (30 MW generator)

Both lines converge through condensers and cooling towers, with a deaerator and pump loop recycling condensate.

### Thermodynamic Cycle

The T-s diagram shows the complete cycle operating between:
- Upper pressure: 200 bar (superheated region)
- Intermediate pressures: 40.13 bar, 8.925 bar
- Condenser pressure: 0.1 bar

Key state points:
- States 1–6, 15: Compressed liquid / subcooled region
- States 7, 27, 28, 33: Saturated liquid at intermediate pressure
- States 8–9: Superheated vapor entering turbines
- States 10, 11, 18: Turbine exhaust (wet region)
- States 12, 13, 16: Saturated vapor at low pressure
- State 14: Condenser outlet (saturated liquid at 0.1 bar)

### Energy Balance (Sankey Diagram)

The Sankey diagram tracks energy through 23+ streams:

| Component | Energy In | Energy Out | Losses |
|-----------|-----------|------------|--------|
| Reservoir (input) | 652.1 MJ (98.3%) | — | — |
| Steam Separator | 652.1 MJ | 608.9 MJ (91.8%) | 2.7 MJ (0.4%) |
| Steam Trap | 10.2 MJ (1.5%) | — | waste steam |
| Moisture Separator | 608.9 MJ | 377.1 + 225.2 MJ | 0.4 MJ (0.1%) |
| Turbines 2&3 | 318.7 MJ (48%) | 58.4 MJ work (8.8%) | — |
| Turbine 1 | 183.8 MJ (27.7%) | 41.4 MJ work (6.2%) | — |
| Generators | 99.8 MJ work | 96.6 MJ electricity | 3.0 MJ (0.5%) |
| Condensers | 536.6 + 294.2 MJ | recycled | 214 + cooling losses |
| Cooling Towers | — | — | 322.6 + 179.7 MJ |

### Sankey Diagram Implementation

`SankeyDiagramEDIT.m` uses the `plotFlowDiagram` MATLAB toolbox to visualize energy flows. Each component is defined with:
- X/Y coordinates for positioning
- Input/output connections with energy values (in MW)
- Flow type classification (heat, work, electricity, saturated liquid/vapor, mixture)
- Font sizing scaled by flow magnitude for readability

The diagram is color-coded:
- Red: Heat input
- Yellow: Energy losses
- Dark blue: Saturated liquid
- Light blue: Saturated vapor / mixture
- Orange: Work (turbine output)
- Green: Electricity (generator output)


## 2. Solar Power Plant — Heliostat Field Model

### Solar Geometry

The model computes solar position for Lombok (latitude -8.65°, longitude 116.3°, UTC+8) at 30-minute intervals from 6:00 to 21:00 for all 365 days:

1. **Equation of Time** — corrects for Earth's orbital eccentricity:
   ```
   EoT = 9.87·sin(2β) - 7.53·cos(β) - 1.5·sin(β)
   where β = 360/365 · (n - 81)
   ```

2. **Solar Time Correction:**
   ```
   TC = 4·(Longitude - LSTM) + EoT
   ```

3. **Hour Angle:**
   ```
   HRA = 15° · (LST - 12:00)
   ```

4. **Declination Angle:**
   ```
   δ = -23.45° · cos(360/365 · (n + 10))
   ```

5. **Elevation Angle:**
   ```
   α = arcsin(sin(δ)·sin(φ) + cos(δ)·cos(φ)·cos(HRA))
   ```

### Atmospheric Model

Beam irradiance reaching the heliostats is computed using:

1. **Optical air mass** — accounts for atmospheric path length:
   - For elevation > 30°: `m = 1/sin(α)`
   - For elevation ≤ 30°: Kasten-Young approximation (polynomial correction)

2. **Rayleigh optical thickness** — piecewise function of air mass

3. **Beam irradiance** via Beer-Lambert extinction:
   ```
   Gb = G₀ · (1 + 0.033·cos(360n/365)) · cos(θz) · exp(-0.8662 · TL · m · δR)
   ```
   where TL is the Linke turbidity factor (set to 1.5 for tropical maritime conditions)

### Heliostat Field Layout

The field uses a **radial stagger** layout around a central tower:

- **Zones:** 2–4 concentric zones (configurable)
- **Rows per zone:** computed from zone radii and minimum radial spacing
- **Heliostats per row:** doubles at each zone boundary (azimuthal spacing halves)
- **Minimum separation:** `CharDiam · cos(30°)` to prevent mechanical collision

Key geometric parameters:
- Characteristic diameter: `√(W² + L²) + separation`
- First-row distance from tower: `N₁ · CharDiam / (2π)`
- Azimuthal spacing: `2·arcsin(CharDiam / (2·R))`

### Efficiency Chain

Total optical efficiency is the product of:

| Factor | Value | Description |
|--------|-------|-------------|
| Cosine efficiency | variable | Function of solar angle and heliostat tilt |
| Reflectivity | 0.96 | Mirror reflectance (clean, high-quality) |
| Atmospheric | 0.99 | Short-range atmospheric attenuation |
| Blocking & shadowing | 0.944 | Inter-heliostat obstruction |

### Optimization Algorithm

`EnergyEfficiencySolar.m` performs a **brute-force grid search** over three parameters:

| Parameter | Range | Step |
|-----------|-------|------|
| Tower height | 70–100 m | 5 m |
| Field zones | 2–4 | 1 |
| First-row heliostats | 10–50 | 1 |

For each combination, the full annual simulation runs (365 days × 31 time steps), and the best result is selected based on the user's chosen objective:

1. **Maximum energy** — selects configuration with highest annual output
2. **Just enough energy** — finds configuration closest to the required 2.121×10¹⁰ kJ/day
3. **Minimum area** — finds smallest field footprint that meets energy demand

The field area is estimated as: `A = π · (2^zones · CharDiam / AzimutSpacing)²`


## 3. References

- PV Education: Solar Time and Hour Angle — https://www.pveducation.org/pvcdrom/properties-of-sunlight/solar-time
- Hnin Wah, Nang Saw Yuzana Kyaing: "Design Calculations of Heliostat Field Layout for Solar Thermal Power Generation"
- ERA5 / Copernicus Climate Data (for regional solar validation)
- Kasten, F. & Young, A.T. (1989): "Revised optical air mass tables and approximation formula"
