# NetCDF diagnostics for AdapteCCa files — no data are published
# Requires: install.packages("ncdf4")
library(ncdf4)

diagnose_netcdf <- function(nc_file, variable = "tasmax") {
  if (!file.exists(nc_file)) stop("File not found: ", nc_file)
  nc <- tryCatch(ncdf4::nc_open(nc_file), error = function(e) e)
  if (inherits(nc, "error")) {
    return(data.frame(file = basename(nc_file), status = "open_error",
                      detail = conditionMessage(nc)))
  }
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  if (!variable %in% names(nc$var)) {
    return(data.frame(file = basename(nc_file), status = "variable_missing",
                      detail = paste(names(nc$var), collapse = ", ")))
  }
  v <- nc$var[[variable]]
  dims <- paste(vapply(v$dim, function(x) x$name, character(1)), collapse = ", ")
  units <- ncdf4::ncatt_get(nc, variable, "units")$value
  time_dim <- Filter(function(x) grepl("time", x$name, ignore.case = TRUE), v$dim)
  calendar <- if (length(time_dim)) {
    ncdf4::ncatt_get(nc, time_dim[[1]]$name, "calendar")$value
  } else NA_character_
  time_units <- if (length(time_dim)) time_dim[[1]]$units else NA_character_
  data.frame(file = basename(nc_file), status = "opened",
             variable = variable, dimensions = dims, units = as.character(units),
             time_units = as.character(time_units),
             calendar = as.character(calendar), layers = prod(v$varsize))
}

# Example:
# diagnose_netcdf("path/to/tasmax_file.nc", "tasmax")
