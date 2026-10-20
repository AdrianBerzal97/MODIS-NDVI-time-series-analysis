# AdapteCCa NetCDF site extraction — MODIS study locations
# Requires: install.packages(c("terra", "ncdf4"))
# Input: locally downloaded NetCDF files. No research data distributed.
library(terra)
library(ncdf4)

sites <- data.frame(
  site = c("Piñuecar", "Colmenar Viejo", "Tielmes"),
  lon = c(-3.605052, -3.772985, -3.295980),
  lat = c(41.037396, 40.614862, 40.221771)
)

extract_site_series <- function(nc_file, variable = "tasmax", sites_df = sites) {
  if (!file.exists(nc_file)) stop("NetCDF file not found: ", nc_file)
  nc <- ncdf4::nc_open(nc_file)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  if (!variable %in% names(nc$var)) stop("Variable not found: ", variable)
  var_units <- ncdf4::ncatt_get(nc, variable, "units")$value

  r <- terra::rast(nc_file, subds = variable)
  if (is.na(terra::crs(r)) || !nzchar(terra::crs(r))) {
    stop("NetCDF raster CRS missing: verify spatial coordinates before extraction.")
  }
  pts <- terra::vect(sites_df, geom = c("lon", "lat"), crs = "EPSG:4326")
  pts <- terra::project(pts, terra::crs(r))
  if (!all(terra::relate(pts, terra::ext(r), relation = "intersects"))) {
    stop("One or more study sites fall outside the NetCDF raster extent.")
  }
  extracted <- terra::extract(r, pts, ID = FALSE)
  if (ncol(extracted) != terra::nlyr(r)) stop("Unexpected NetCDF layer count.")
  out <- data.frame(site = rep(sites_df$site, each = ncol(extracted)),
                    layer = rep(seq_len(ncol(extracted)), times = nrow(extracted)),
                    value = as.vector(t(as.matrix(extracted))),
                    variable = variable, units = var_units)
  # Time must be interpreted using the NetCDF calendar/time metadata.
  # Do not infer dates from layer number or assume a Gregorian calendar.
  out
}

# Example (set to an existing local file):
# result <- extract_site_series("path/to/tasmax_file.nc", "tasmax")
# print(head(result))
