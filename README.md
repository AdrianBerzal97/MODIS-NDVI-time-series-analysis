# MODIS NDVI Time-Series Analysis of Mediterranean Grasslands

## Overview

This repository presents a portfolio-oriented workflow for analysing long-term vegetation dynamics in Mediterranean grasslands using MODIS NDVI time series.

The project focuses on three grassland sites located along a climatic gradient in the Community of Madrid, Spain: **Piñuecar (Mountain)**, **Colmenar Viejo (Foothill)**, and **Tielmes (Flatland)**. The analysis explores long-term and seasonal vegetation dynamics and NDVI accumulation within hydrological years. The broader research compares the relationship between MODIS NDVI and biomass simulated with SIMPAST under two climate-data inputs: AdapteCCa climate-model data and observed AEMET station data.

This public repository demonstrates the remote-sensing and environmental time-series methodology used in the research workflow. It is not a complete reproduction package and does not include the original research datasets.

## Study area

The three study sites represent contrasting Mediterranean grassland environments across the Community of Madrid.

![Study area and NDVI study sites](figures/Figure_1.png)

## Study workflow

The portfolio workflow is organised around:

1. MODIS NDVI time-series preparation.
2. Assignment of observations to hydrological years beginning in September.
3. Analysis of long-term and seasonal vegetation dynamics across the three study sites.
4. Calculation of simple cumulative NDVI.
5. Calculation of conditional cumulative NDVI, where NDVI is accumulated only when the current observation is greater than or equal to the previous observation.
6. Visual comparison of vegetation behaviour across the climatic gradient.

## Long-term NDVI dynamics

The long-term time series illustrates contrasting vegetation dynamics at Piñuecar, Colmenar Viejo, and Tielmes over more than two decades of satellite observations.

![Long-term NDVI time series for the three study sites](figures/Time_Series_3_Locations_Mean_NDVI.png)

## Seasonal NDVI patterns

A comparison by observation period highlights the different seasonal trajectories of the mountain, foothill, and flatland grassland systems.

![Mean NDVI by observation month for the three study sites](figures/Figure_2.png)

## Key findings

- **Piñuecar (Mountain)** shows the highest seasonal NDVI values, with a pronounced spring maximum followed by a summer decline.
- **Colmenar Viejo (Foothill)** also displays strong seasonality, with high vegetation activity through the cool and spring growing period and a marked decline towards summer.
- **Tielmes (Flatland)** generally maintains lower NDVI values and a weaker seasonal amplitude than the other two sites.
- The contrast among the three sites illustrates how long-term satellite observations can characterise vegetation dynamics along a Mediterranean climatic gradient.
- Hydrological-year accumulation provides complementary indicators for summarising vegetation activity beyond individual NDVI observations.

These observations are descriptive interpretations of the figures included in this portfolio repository.

## NDVI accumulation methods

### Simple cumulative NDVI

NDVI observations are cumulatively summed within each hydrological year.

### Conditional cumulative NDVI

The current NDVI observation is added to the cumulative value only when it is greater than or equal to the preceding observation. Otherwise, the accumulated value remains unchanged.

Both accumulation approaches are reset at the beginning of each hydrological year (September). The figure below illustrates the original NDVI time series together with the simple and conditional accumulation approaches.

![NDVI simple and conditional cumulative indicators](figures/Figure_S1.png)

### Supplementary example: Tielmes

The supplementary figure below shows the original NDVI series and both within-year accumulation approaches at Tielmes. It complements the [first-difference sensitivity results](results/supplementary_table_S1_first_differences.csv).

![Tielmes NDVI time series, simple cumulative NDVI and conditional cumulative NDVI (Figure S2)](figures/Figure_S2.png)

## SIMPAST biomass–NDVI comparison: AdapteCCa vs AEMET

The scientific comparison is between **MODIS NDVI and SIMPAST-simulated biomass**, not a direct NDVI–climate-variable correlation. SIMPAST is driven separately by two climate-data sources:

1. **AdapteCCa** climate-model NetCDF inputs (downloaded **manually via the AdapteCCa THREDDS server**; the NetCDF scripts process files already downloaded).
2. **AEMET** daily observations from weather stations, downloaded using R scripts and the AEMET API (Buitrago del Lozoya, Colmenar Viejo and Aranjuez). These station locations differ from the MODIS site centroids.

The resulting SIMPAST biomass estimates are related to MODIS NDVI and the two climate-input pathways are compared. Climate inputs include maximum, minimum and mean temperature and precipitation, subject to the original model's input specification. **This repository does not yet contain the SIMPAST–NDVI comparison scripts or validated biomass outputs**; the Python NDVI modules currently represent vegetation time-series preparation and visualization only.

**Study-site coordinates (WGS84, latitude, longitude):** Piñuecar (41.037396, -3.605052), Colmenar Viejo (40.614862, -3.772985), and Tielmes (40.221771, -3.295980). The public AdapteCCa extraction script uses these sites.

The supplied diagnostic and date-control workbooks for `tasmax` were generated using a separate three-municipality workflow; their outputs should **not** be interpreted as validation of extraction at the MODIS sites. See [climate-data workflow notes](src/climate_data/README.md). No original AEMET observations, NetCDF datasets, or biomass research data are published.

## Climate-data acquisition and processing

AdapteCCa NetCDF files were downloaded manually from its THREDDS server. The repository contains R functions for local NetCDF extraction and metadata diagnosis, **not** a THREDDS download script. The AEMET API scripts cover 2000–2020 and 2021–2025, use an environment variable named `AEMET_API_KEY` and write local outputs to `outputs/aemet/`. Never commit the key or downloaded datasets. These scripts are portfolio adaptations and have not been validated end-to-end.

See [climate-data documentation](src/climate_data/README.md) for station identifiers, usage and limitations. The scripts comparing SIMPAST biomass with NDVI and validated biomass outputs are not yet included.

## Published manuscript results (under review)

The accompanying manuscript, *Temporally Integrated MODIS NDVI and Simulated Cumulative Biomass in Mediterranean Grasslands*, compares temporally matched eight-day NDVI–simulated biomass production with pooled cumulative relationships. The figures below are reported R² values, not predictive-validation scores.

| Site | Forcing | Eight-day reference | Simple cumulative NDVI | Conditional cumulative NDVI |
| --- | --- | ---: | ---: | ---: |
| Piñuecar | Climate models (mean of six) | 0.188 | 0.746 | 0.723 |
| Piñuecar | Observed meteorology | 0.263 | 0.620 | 0.648 |
| Colmenar Viejo | Climate models (mean of six) | 0.069 | 0.722 | 0.600 |
| Colmenar Viejo | Observed meteorology | 0.146 | 0.763 | 0.656 |
| Tielmes | Climate models (mean of six) | 0.073 | 0.714 | 0.700 |
| Tielmes | Observed meteorology | 0.122 | 0.787 | 0.775 |

*Source: manuscript Table 2 (author-provided version, under review). The cumulative and eight-day relationships use different temporal representations, so larger pooled cumulative R² values must not be interpreted as improved predictive performance.*

### Supplementary first-difference sensitivity analysis

The supplementary material also examines first differences of accumulated NDVI and first differences of SIMPAST-simulated cumulative biomass across six original forcing trajectories. Mean R² values for simple versus conditional accumulation were **0.180 vs 0.050** (Piñuecar), **0.004 vs 0.001** (Colmenar Viejo), and **0.097 vs 0.013** (Tielmes). These much weaker associations highlight the effect of shared cumulative temporal structure.

The full transcribed [supplementary Table S1 (CSV)](results/supplementary_table_S1_first_differences.csv) includes individual trajectories and reported p-values. Values such as `<0.001` are preserved as text, rather than converted into numeric estimates. These are **reported research results**, not outputs regenerated by the portfolio scripts.

## Code organisation

The public workflow is divided into three small, reusable modules:

- `01_ndvi_time_series_processing.py` cleans dates and NDVI values, assigns hydrological years, and organises observations chronologically.
- `02_ndvi_accumulation.py` implements simple and conditional cumulative NDVI independently within each hydrological year.
- `03_ndvi_visualization.py` provides reusable functions for long-term time-series plots, seasonal summaries, and cumulative-NDVI visualisation.

## Python dependencies

The portfolio scripts use a lightweight scientific Python stack:

```text
numpy
pandas
matplotlib
```

Dependencies are also listed in `requirements.txt`.

## Repository structure

```text
MODIS-NDVI-time-series-analysis/
├── README.md
├── .gitignore
├── requirements.txt
├── data/
│   └── README.md
├── figures/
│   ├── README.md
│   ├── Figure_1.png
│   ├── Figure_2.png
│   ├── Figure_S1.png
│   └── Time_Series_3_Locations_Mean_NDVI.png
└── src/
    ├── climate_data/
    │   ├── README.md
    │   ├── 01_extract_adaptecca_netcdf.R
    │   ├── 02_diagnose_netcdf.R
    │   ├── 03_download_aemet_2000_2020.R
    │   └── 04_download_aemet_2021_2025.R
    ├── README.md
    ├── 01_ndvi_time_series_processing.py
    ├── 02_ndvi_accumulation.py
    └── 03_ndvi_visualization.py
```

## Skills demonstrated

- Remote sensing and vegetation-index analysis
- MODIS NDVI time-series processing
- Environmental time-series analysis
- Hydrological-year aggregation
- Python data analysis with pandas and NumPy
- Scientific visualisation with Matplotlib
- Geospatial interpretation across an environmental gradient
- Research workflow design comparing SIMPAST biomass–NDVI relationships under gridded and observed climate inputs
- NetCDF diagnostics and climate-data quality-control concepts
- Reproducible organisation of research workflows

## Data availability

The original MODIS-derived research datasets are **not distributed** in this portfolio repository. The `data/` directory documents the expected data structure without publishing the underlying research data.

## Reproducibility note

The source code has been cleaned and reorganised for portfolio presentation. It demonstrates the analytical methodology but is not intended as a complete, ready-to-run reproduction of the research study.
