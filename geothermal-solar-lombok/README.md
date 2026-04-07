# Geothermal-Solar Hybrid Power Plant Analysis — Lombok, Indonesia

**Tech Stack:** MATLAB · Thermodynamic Modeling · Solar Field Optimization · Energy Flow Analysis  
**Type:** Academic project (group + individual contributions)  
**Location:** Lombok, Indonesia  
**Context:** University of Twente — Mechanical Engineering

## Overview

Combined techno-economic and thermodynamic analysis of a hybrid geothermal-solar power generation system for Lombok, Indonesia. The project integrates two complementary energy sources — a geothermal power plant using a Rankine cycle with dual-pressure steam separation, and a concentrated solar power (CSP) heliostat field — to assess feasibility and optimize energy output for the region.

## Project Components

### 1. Geothermal Power Plant — Thermodynamic Analysis (Group Work)

Modeled a geothermal power plant featuring dual-pressure steam separation (high-pressure and low-pressure boreholes), three turbines (40 MW + 2×30 MW generators), condensers, deaerator, and cooling towers.

**Key deliverables:**
- Complete thermodynamic cycle analysis with 23+ stream states
- T-s diagram mapping Rankine and geothermal flow paths across the vapor dome
- Sankey (Grassmann) diagram visualizing energy flows through every component, from 652.1 MJ reservoir input down to generator output and cooling losses
- Component-level energy balance with efficiency tracking

**Key findings:**
- Total reservoir input: 652.1 MJ (98.3%)
- Generator 1 output: 40 MW | Generators 2&3 output: 30 MW each
- Major loss pathways identified through condensers and cooling towers

### 2. Concentrated Solar Power — Heliostat Field Optimization (Individual Work)

Designed and optimized a heliostat field layout for a solar power tower system, computing annual energy yield based on real solar geometry for Lombok's coordinates (8.65°S, 116.3°E).

**Key deliverables:**
- Solar position model computing hourly elevation, azimuth, and zenith angles for every day of the year
- Jensen/PARK-style radial field layout with configurable zones, rows, and heliostats per row
- Multi-variable optimization across tower height (70–100m), field zones (2–4), and first-row heliostats (10–50)
- Three optimization modes: maximum energy, minimum sufficient energy, or minimum land area

**Technical details:**
- Heliostat dimensions: 7×7 m (49 m² each)
- Atmospheric modeling: optical mass, Rayleigh thickness, Linke turbidity factor
- Efficiency chain: cosine × reflectivity (0.96) × atmospheric (0.99) × blocking (0.944)
- Beam irradiance computed via Beer-Lambert atmospheric extinction

## Figures

| Figure | Description |
|--------|-------------|
| `PowerPlantConcept.png` | Geothermal plant schematic — dual-pressure boreholes, turbines, condensers, cooling towers |
| `ts-diagram.png` | Temperature-entropy diagram with Rankine cycle paths and isobars (0.1–200 bar) |
| `Sankey_Diagram.jpg` | Grassmann/Sankey energy flow diagram tracing MJ through every plant component |
| `Solar.png` | Heliostat field zone layout — concentric rings R1, R2, R3 around central tower |

## Repository Structure

```
geothermal-solar-lombok/
├── README.md
├── docs/
│   └── TECHNICAL_NOTES.md          # Detailed methodology and equations
├── figures/
│   ├── PowerPlantConcept.png       # Plant schematic
│   ├── Sankey_Diagram.jpg          # Energy flow diagram
│   ├── Solar.png                   # Heliostat field zones
│   └── ts-diagram.png             # T-s diagram
└── matlab/
    ├── geothermal-sankey/
    │   └── SankeyDiagramEDIT.m     # Sankey diagram generation (requires plotFlowDiagram toolbox)
    └── solar-field/
        ├── ThisIsMEnu.m            # Main script — user interface & plotting
        ├── SolarPowerPlant.m       # Core solar field simulation engine
        └── EnergyEfficiencySolar.m # Optimization wrapper — iterates over configurations
```

## How to Run

### Solar Field Optimization
```matlab
% Open MATLAB, navigate to matlab/solar-field/
% Run the main script:
ThisIsMEnu
% Choose optimization mode:
%   1 — Maximum power output
%   2 — Minimum energy to meet demand
%   3 — Minimum land area for required energy
```

### Sankey Diagram
```matlab
% Requires: plotFlowDiagram toolbox (add to MATLAB path)
% Requires: Stream_Data.m function with thermodynamic stream data
% Navigate to matlab/geothermal-sankey/
SankeyDiagramEDIT
```

## Dependencies

- MATLAB (R2019b or later recommended)
- [plotFlowDiagram](https://www.mathworks.com/matlabcentral/fileexchange/) toolbox (for Sankey diagram)
- `Stream_Data.m` — thermodynamic stream properties function (group-shared, not included)
