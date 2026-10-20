# Climate-data workflows (R)

This directory documents climate inputs for the MODIS–SIMPAST biomass comparison. The scientific response being compared with MODIS NDVI is **SIMPAST-simulated biomass** under AdapteCCa versus AEMET climate forcing, not the climate variables directly.

## Data sources

- **AEMET**: daily observations from meteorological stations, obtained using the AEMET API. API credentials and downloaded observations must not be committed.
- **AdapteCCa**: gridded climate-model NetCDF files **downloaded manually** from the platform because scripted downloads were unreliable, including historical and SSP scenarios. Example variables are `tasmax` (maximum temperature), `tasmin` (minimum temperature), `tas` (mean near-surface temperature), and `pr` (precipitation). The variable names and units must be checked against each file's metadata.

## NetCDF processing steps

1. Inventory NetCDF files by variable, model, scenario and file size.
2. Inspect variables, dimensions, coordinate reference system, missing values, time units and calendar.
3. Validate the time axis from NetCDF metadata rather than assuming Gregorian daily dates starting in 1950 or 2015.
4. Extract grid-cell values for research locations only after checking coordinate alignment and spatial reference.
5. Convert units using NetCDF metadata (e.g. Kelvin to Celsius where applicable), not value thresholds.
6. Check date coverage and missing records by model, scenario, variable and location.
7. Compare climate variables with NDVI only after aligning study locations, time periods and temporal aggregation.

## Research-script provenance and limitations

The original `tasmax` research scripts used Cipérez, Urraca-Miguel and Jarilla, which are **not** the MODIS study sites. The adapted extraction script now uses **Piñuecar (41.037396, -3.605052), Colmenar Viejo (40.614862, -3.772985), and Tielmes (40.221771, -3.295980)** (latitude, longitude, WGS84).

The same general inspection/extraction approach was reportedly used for `tasmin`, mean temperature and precipitation, but the supplied examples are for `tasmax`. No complete or validated four-variable pipeline is claimed here. The AEMET download scripts and original NetCDF files are not yet included in this directory. The new scripts `01_extract_adaptecca_netcdf.R` and `02_diagnose_netcdf.R` are portfolio adaptations and have **not** been validated on the original NetCDF inputs. The extraction function outputs layer indices, not dates, until the file-specific calendar is validated.

## Provenance of supplied diagnostics

The supplied `DIAGNOSTICO_NETCDF_TASMAX.xlsx` and `CONTROL_FECHAS_TASMAX_3_MUNICIPIOS.xlsx` refer to the original three-municipality tasmax processing workflow. They are not evidence that NetCDF values have been extracted and validated for Piñuecar, Colmenar Viejo or Tielmes. The original AEMET Excel workbook is retained outside this public repository. Biomass–NDVI comparison code and SIMPAST outputs still need to be identified and checked before claiming the analysis is reproducible.

## Publication safeguards

Do not publish API keys, absolute local computer paths, original research data or proprietary NetCDF files. Check dataset attribution, usage conditions and research-code ownership before publishing a cleaned implementation.
