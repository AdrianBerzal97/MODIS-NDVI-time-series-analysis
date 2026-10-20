# Climate-data workflows (R)

This directory documents the climate-data component of the wider research workflow, alongside the Python MODIS NDVI analysis.

## Data sources

- **AEMET**: daily observations from meteorological stations, obtained using the AEMET API. API credentials and downloaded observations must not be committed.
- **AdapteCCa**: gridded climate-model NetCDF files, including historical and SSP scenarios. Example variables are `tasmax` (maximum temperature), `tasmin` (minimum temperature), `tas` (mean near-surface temperature), and `pr` (precipitation). The variable names and units must be checked against each file's metadata.

## NetCDF processing steps

1. Inventory NetCDF files by variable, model, scenario and file size.
2. Inspect variables, dimensions, coordinate reference system, missing values, time units and calendar.
3. Validate the time axis from NetCDF metadata rather than assuming Gregorian daily dates starting in 1950 or 2015.
4. Extract grid-cell values for research locations only after checking coordinate alignment and spatial reference.
5. Convert units using NetCDF metadata (e.g. Kelvin to Celsius where applicable), not value thresholds.
6. Check date coverage and missing records by model, scenario, variable and location.
7. Compare climate variables with NDVI only after aligning study locations, time periods and temporal aggregation.

## Research-script provenance and limitations

The supplied `tasmax` research scripts include a multi-model extraction workflow, NetCDF integrity checks, spreadsheet exports and date-coverage checks. They were written for **Cipérez, Urraca-Miguel and Jarilla**. The public NDVI figures currently describe **Piñuecar, Colmenar Viejo and Tielmes**. The author confirms that both workflows belong to **the same MODIS article**. However, the supplied files do not explain how these two sets of locations correspond; do not assume a direct site-level match.

The same general inspection/extraction approach was reportedly used for `tasmin`, mean temperature and precipitation, but the supplied examples are for `tasmax`. No complete or validated four-variable pipeline is claimed here. The AEMET download scripts and original NetCDF files are not yet included in this directory.

## Publication safeguards

Do not publish API keys, absolute local computer paths, original research data or proprietary NetCDF files. Check dataset attribution, usage conditions and research-code ownership before publishing a cleaned implementation.
