# Climate-data workflows (R)

This directory documents climate inputs for the MODIS–SIMPAST biomass comparison. The scientific response being compared with MODIS NDVI is **SIMPAST-simulated biomass** under AdapteCCa versus AEMET climate forcing, not the climate variables directly.

## Data sources

- **AEMET**: daily observations from meteorological stations, obtained using the AEMET API. API credentials and downloaded observations must not be committed.
- **AdapteCCa**: gridded climate-model NetCDF files **downloaded manually** from the AdapteCCa **THREDDS server**; the R scripts work on local NetCDF files and do not automate THREDDS downloads, including historical and SSP scenarios. Example variables are `tasmax` (maximum temperature), `tasmin` (minimum temperature), `tas` (mean near-surface temperature), and `pr` (precipitation). The variable names and units must be checked against each file's metadata.

## AEMET station downloads

- `03_download_aemet_2000_2020.R`: daily AEMET API downloads, 2000-01-01 to 2020-12-31.
- `04_download_aemet_2021_2025.R`: daily AEMET API downloads, 2021-01-01 to 2025-10-24.
- Both retain the original meteorological station identifiers: Buitrago del Lozoya (`3110C`), Colmenar Viejo (`3191E`) and Aranjuez (`3100B`). These are station locations, **not** the three MODIS site centroids. Any correspondence used to force SIMPAST should be documented and checked separately.
- Install the R packages `httr`, `jsonlite`, `dplyr` and `openxlsx`. Set the API credential locally using `Sys.setenv(AEMET_API_KEY = "YOUR_OWN_KEY")` (do not store the actual key in a script). Outputs default to `outputs/aemet/` and should remain untracked.
- The scripts are sanitized adaptations of research code, not tested end-to-end. Check API pagination/availability, missing stations and restart/checkpoint handling before scientific use.

## NetCDF processing steps

1. Inventory NetCDF files by variable, model, scenario and file size.
2. Inspect variables, dimensions, coordinate reference system, missing values, time units and calendar.
3. Validate the time axis from NetCDF metadata rather than assuming Gregorian daily dates starting in 1950 or 2015.
4. Extract grid-cell values for research locations only after checking coordinate alignment and spatial reference.
5. Convert units using NetCDF metadata (e.g. Kelvin to Celsius where applicable), not value thresholds.
6. Check date coverage and missing records by model, scenario, variable and location.
7. Feed the checked climate series into SIMPAST, then compare the resulting simulated biomass with MODIS NDVI using aligned sites, dates and temporal aggregation. The climate variables themselves are not the primary NDVI comparison.

## Research-script provenance and limitations

The original `tasmax` research scripts used Cipérez, Urraca-Miguel and Jarilla, which are **not** the MODIS study sites. The adapted extraction script now uses **Piñuecar (41.037396, -3.605052), Colmenar Viejo (40.614862, -3.772985), and Tielmes (40.221771, -3.295980)** (latitude, longitude, WGS84).

The same general inspection/extraction approach was reportedly used for `tasmin`, mean temperature and precipitation, but the supplied examples are for `tasmax`. No complete or validated four-variable pipeline is claimed here. Two sanitized AEMET download scripts are included, but original NetCDF files and downloaded AEMET observations are not. The new scripts `01_extract_adaptecca_netcdf.R` and `02_diagnose_netcdf.R` are portfolio adaptations and have **not** been validated on the original NetCDF inputs. The extraction function outputs layer indices, not dates, until the file-specific calendar is validated.

## Provenance of supplied diagnostics

The supplied `DIAGNOSTICO_NETCDF_TASMAX.xlsx` and `CONTROL_FECHAS_TASMAX_3_MUNICIPIOS.xlsx` refer to the original three-municipality tasmax processing workflow. They are not evidence that NetCDF values have been extracted and validated for Piñuecar, Colmenar Viejo or Tielmes. The original AEMET Excel workbook is retained outside this public repository. Biomass–NDVI comparison code and SIMPAST outputs still need to be identified and checked before claiming the analysis is reproducible.

## Publication safeguards

Do not publish API keys, absolute local computer paths, original research data or proprietary NetCDF files. Check dataset attribution, usage conditions and research-code ownership before publishing a cleaned implementation.
