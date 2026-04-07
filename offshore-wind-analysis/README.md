# Offshore Wind Farm Techno-Economic Assessment

**Tech Stack:** Python (NumPy, xarray) · MATLAB · ERA5 Data · Financial Modeling  
**Duration:** 3 months  
**Type:** Bachelor's thesis (solo research)  
**Location:** Southeast Euboea – North Andros region, Greece

## The Challenge

Assess technical feasibility and economic viability of a large-scale offshore wind farm in Greek waters — a region with significant wind potential but emerging regulatory framework and limited precedent. Required rigorous validation of wake modeling under Mediterranean conditions and comprehensive financial analysis accounting for capital constraints and market conditions.

## The Solution

Conducted end-to-end techno-economic analysis combining meteorological data science, advanced wake modeling, and financial engineering. Processed 2.3 GB of ERA5 hourly wind data (u/v velocity components at 10m and 100m heights) using Python, then implemented Jensen/PARK wake model in MATLAB to simulate turbine interactions and power generation across the full year.

## Key Achievements

- **Data Engineering:** Extracted, processed, and validated 2.3 GB ERA5 meteorological dataset; converted NetCDF files to structured CSV using Python (NumPy, xarray)
- **Scientific Modeling:** Implemented Jensen/PARK wake model from first principles, accounting for wind shear, air density variation, and turbine thrust dynamics
- **Validation:** Proved model reliability for Greek maritime conditions; identified seasonal variability and wake loss patterns (14.03% annual mean)
- **Economic Analysis:** Computed NPV, IRR, and LCOE with sensitivity analysis identifying capital optimization as primary cost driver
- **Stakeholder Assessment:** Analyzed ecosystem of actors and global precedents for successful project deployment

## Impact

| Metric | Value |
|--------|-------|
| Net Present Value | €5.46 billion |
| Internal Rate of Return | 17.28% |
| Annual Energy Production | 9,216 GWh |
| Capacity Factor | 55.31% |
| LCOE | €134/MWh |
| Wake Losses (annual mean) | 14.03% |
| Dataset Processed | 2.3 GB |
| Total Capacity | 1,905 MW |

**Key Finding:** Project is both technically viable and financially attractive under current market conditions.

## Repository Structure

```
offshore-wind-analysis/
├── README.md
├── data/               # Sample data and data processing scripts
├── matlab/             # MATLAB wake model implementation
├── python/             # Python data extraction and processing
├── results/            # Output visualizations and analysis
└── docs/               # Thesis excerpts and methodology notes
```

## Related Work

- Social embedding paper with stakeholder analysis covering implementation barriers and institutional context
- Preliminary location analysis report (collaborative)
