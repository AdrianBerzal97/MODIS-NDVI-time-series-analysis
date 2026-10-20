# Portfolio adaptation of original AEMET research script.
# Set AEMET_API_KEY in your local environment; never commit credentials or downloaded data.
# Original station selection: Buitrago del Lozoya, Colmenar Viejo, Aranjuez.
# Not validated end-to-end; inspect API responses, station coverage and checkpoint logic before research reuse.

library(httr)
library(jsonlite)
library(dplyr)
library(openxlsx)

# ============================================================
# API KEY AEMET
# ============================================================

api_key <- Sys.getenv("AEMET_API_KEY")

api_key <- trimws(api_key)

if (api_key == "") {
  stop("Introduce tu API key real de AEMET.")
}

# ============================================================
# ESTACIONES
# ============================================================

estaciones <- data.frame(
  indicativo = c(
    "3110C",
    "3191E",
    "3100B"
  ),
  localidad = c(
    "Buitrago_del_Lozoya",
    "Colmenar_Viejo",
    "Aranjuez"
  ),
  stringsAsFactors = FALSE
)

id_estaciones <- paste(
  estaciones$indicativo,
  collapse = ","
)

# ============================================================
# PERIODO
# ============================================================

fecha_inicio <- as.Date("2000-01-01")
fecha_final  <- as.Date("2020-12-31")

fechas <- seq(
  fecha_inicio,
  fecha_final,
  by = "day"
)

cat(
  "Número de días a procesar:",
  length(fechas),
  "\n"
)

# ============================================================
# CARPETA DE SALIDA
# ============================================================

carpeta_salida <- file.path("outputs", "aemet")

if (!dir.exists(carpeta_salida)) {
  dir.create(
    carpeta_salida,
    recursive = TRUE
  )
}

# ============================================================
# ARCHIVOS
# ============================================================

archivo_excel <- file.path(
  carpeta_salida,
  "AEMET_Buitrago_Colmenar_Aranjuez_2000_2020.xlsx"
)

archivo_temporal <- file.path(
  carpeta_salida,
  "AEMET_temporal_2000_2020.csv"
)

# ============================================================
# FUNCIÓN PARA DESCARGAR UN DÍA
# ============================================================

descargar_dia <- function(
    fecha,
    estaciones,
    api_key,
    reintentos = 3
) {
  
  fecha_txt <- paste0(
    format(fecha, "%Y-%m-%d"),
    "T00:00:00UTC"
  )
  
  fecha_url <- URLencode(
    fecha_txt,
    reserved = TRUE
  )
  
  url <- paste0(
    "https://opendata.aemet.es/opendata/api/",
    "valores/climatologicos/diarios/datos/",
    "fechaini/", fecha_url,
    "/fechafin/", fecha_url,
    "/estacion/", estaciones
  )
  
  for (intento in seq_len(reintentos)) {
    
    res <- tryCatch(
      GET(
        url,
        add_headers(
          "api_key" = api_key,
          "accept" = "application/json"
        ),
        timeout(60)
      ),
      error = function(e) NULL
    )
    
    if (is.null(res)) {
      Sys.sleep(3)
      next
    }
    
    txt <- content(
      res,
      "text",
      encoding = "UTF-8"
    )
    
    if (status_code(res) != 200) {
      Sys.sleep(3)
      next
    }
    
    info <- tryCatch(
      fromJSON(txt),
      error = function(e) NULL
    )
    
    if (is.null(info)) {
      Sys.sleep(3)
      next
    }
    
    if (
      !is.null(info$estado) &&
      info$estado != 200
    ) {
      
      descripcion <- ifelse(
        is.null(info$descripcion),
        "Sin descripción",
        info$descripcion
      )
      
      return(
        list(
          datos = NULL,
          estado = paste0(
            "AEMET_",
            info$estado
          ),
          mensaje = descripcion
        )
      )
    }
    
    if (
      is.null(info$datos) ||
      length(info$datos) == 0 ||
      all(is.na(info$datos)) ||
      info$datos == ""
    ) {
      
      return(
        list(
          datos = NULL,
          estado = "SIN_DATOS",
          mensaje = "AEMET no proporcionó URL de datos."
        )
      )
    }
    
    res2 <- tryCatch(
      GET(
        info$datos,
        timeout(60)
      ),
      error = function(e) NULL
    )
    
    if (is.null(res2)) {
      Sys.sleep(3)
      next
    }
    
    if (status_code(res2) != 200) {
      Sys.sleep(3)
      next
    }
    
    txt_datos <- content(
      res2,
      "text",
      encoding = "UTF-8"
    )
    
    datos <- tryCatch(
      fromJSON(
        txt_datos,
        flatten = TRUE
      ),
      error = function(e) NULL
    )
    
    if (is.null(datos)) {
      
      return(
        list(
          datos = NULL,
          estado = "SIN_DATOS",
          mensaje = "No fue posible interpretar los datos."
        )
      )
    }
    
    datos <- as.data.frame(datos)
    
    if (nrow(datos) == 0) {
      
      return(
        list(
          datos = NULL,
          estado = "SIN_DATOS",
          mensaje = "0 registros."
        )
      )
    }
    
    return(
      list(
        datos = datos,
        estado = "OK",
        mensaje = ""
      )
    )
  }
  
  return(
    list(
      datos = NULL,
      estado = "ERROR",
      mensaje = "Se agotaron los reintentos."
    )
  )
}

# ============================================================
# RECUPERAR DESCARGA TEMPORAL
# ============================================================

if (file.exists(archivo_temporal)) {
  
  cat(
    "\nSe ha encontrado una descarga temporal anterior.\n"
  )
  
  datos_totales <- read.csv(
    archivo_temporal,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  
  if ("fecha" %in% names(datos_totales)) {
    datos_totales$fecha <- as.Date(
      datos_totales$fecha
    )
  }
  
  cat(
    "Registros recuperados:",
    nrow(datos_totales),
    "\n\n"
  )
  
} else {
  
  datos_totales <- data.frame()
}

# ============================================================
# DESCARGAR DÍA A DÍA
# ============================================================

for (i in seq_along(fechas)) {
  
  fecha_actual <- fechas[i]
  
  # Saltar días ya descargados
  if (
    nrow(datos_totales) > 0 &&
    "fecha" %in% names(datos_totales)
  ) {
    
    if (fecha_actual %in% datos_totales$fecha) {
      
      cat(
        sprintf(
          "[%d/%d] %s - YA DESCARGADA\n",
          i,
          length(fechas),
          as.character(fecha_actual)
        )
      )
      
      next
    }
  }
  
  cat(
    sprintf(
      "[%d/%d] %s",
      i,
      length(fechas),
      as.character(fecha_actual)
    )
  )
  
  resultado <- descargar_dia(
    fecha = fecha_actual,
    estaciones = id_estaciones,
    api_key = api_key
  )
  
  if (resultado$estado == "OK") {
    
    datos_dia <- resultado$datos
    
    datos_totales <- bind_rows(
      datos_totales,
      datos_dia
    )
    
    cat(
      " - OK -",
      nrow(datos_dia),
      "registros\n"
    )
    
  } else {
    
    cat(
      " -",
      resultado$estado,
      "-",
      resultado$mensaje,
      "\n"
    )
  }
  
  # Guardado temporal cada 20 días
  if (
    i %% 20 == 0 &&
    nrow(datos_totales) > 0
  ) {
    
    write.csv(
      datos_totales,
      archivo_temporal,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
    
    cat(
      "   Copia temporal guardada.\n"
    )
  }
  
  Sys.sleep(1)
}

# ============================================================
# COMPROBAR DATOS
# ============================================================

if (nrow(datos_totales) == 0) {
  stop(
    "No se ha podido descargar ningún dato."
  )
}

# ============================================================
# FUNCIÓN PARA CONVERTIR NÚMEROS AEMET
# ============================================================

a_numero <- function(x) {
  
  if (is.numeric(x)) {
    return(x)
  }
  
  as.numeric(
    gsub(
      ",",
      ".",
      x,
      fixed = TRUE
    )
  )
}

# ============================================================
# FORMATO DE FECHA
# ============================================================

datos_totales$fecha <- as.Date(
  datos_totales$fecha
)

# ============================================================
# CONVERTIR SOLO LAS VARIABLES QUE NOS INTERESAN
# ============================================================

if ("altitud" %in% names(datos_totales)) {
  datos_totales$altitud <- a_numero(
    datos_totales$altitud
  )
}

if ("tmed" %in% names(datos_totales)) {
  datos_totales$tmed <- a_numero(
    datos_totales$tmed
  )
}

if ("prec" %in% names(datos_totales)) {
  datos_totales$prec <- a_numero(
    datos_totales$prec
  )
}

if ("tmin" %in% names(datos_totales)) {
  datos_totales$tmin <- a_numero(
    datos_totales$tmin
  )
}

if ("tmax" %in% names(datos_totales)) {
  datos_totales$tmax <- a_numero(
    datos_totales$tmax
  )
}

# ============================================================
# CONSERVAR EXACTAMENTE LAS COLUMNAS QUE QUIERES
# ============================================================

datos_finales <- datos_totales %>%
  
  select(
    fecha,
    indicativo,
    nombre,
    provincia,
    altitud,
    tmed,
    prec,
    tmin,
    tmax
  ) %>%
  
  distinct(
    indicativo,
    fecha,
    .keep_all = TRUE
  ) %>%
  
  arrange(
    indicativo,
    fecha
  )

# ============================================================
# SEPARAR LAS ESTACIONES
# ============================================================

datos_buitrago <- datos_finales %>%
  filter(
    indicativo == "3110C"
  )

datos_colmenar <- datos_finales %>%
  filter(
    indicativo == "3191E"
  )

datos_aranjuez <- datos_finales %>%
  filter(
    indicativo == "3100B"
  )

# ============================================================
# IDENTIFICAR FECHAS SIN ALGUNA VARIABLE
# ============================================================

fechas_sin_datos <- datos_finales %>%
  
  filter(
    is.na(tmed) |
      is.na(prec) |
      is.na(tmin) |
      is.na(tmax)
  )

# ============================================================
# CREAR EXCEL
# ============================================================

wb <- createWorkbook()

# ------------------------------------------------------------
# HOJA GENERAL
# ------------------------------------------------------------

addWorksheet(
  wb,
  "datos_completos"
)

writeData(
  wb,
  "datos_completos",
  datos_finales,
  withFilter = TRUE
)

freezePane(
  wb,
  "datos_completos",
  firstRow = TRUE
)

setColWidths(
  wb,
  "datos_completos",
  cols = 1:ncol(datos_finales),
  widths = "auto"
)

# ------------------------------------------------------------
# BUITRAGO
# ------------------------------------------------------------

addWorksheet(
  wb,
  "Buitrago"
)

writeData(
  wb,
  "Buitrago",
  datos_buitrago,
  withFilter = TRUE
)

freezePane(
  wb,
  "Buitrago",
  firstRow = TRUE
)

setColWidths(
  wb,
  "Buitrago",
  cols = 1:ncol(datos_buitrago),
  widths = "auto"
)

# ------------------------------------------------------------
# COLMENAR VIEJO
# ------------------------------------------------------------

addWorksheet(
  wb,
  "Colmenar_Viejo"
)

writeData(
  wb,
  "Colmenar_Viejo",
  datos_colmenar,
  withFilter = TRUE
)

freezePane(
  wb,
  "Colmenar_Viejo",
  firstRow = TRUE
)

setColWidths(
  wb,
  "Colmenar_Viejo",
  cols = 1:ncol(datos_colmenar),
  widths = "auto"
)

# ------------------------------------------------------------
# ARANJUEZ
# ------------------------------------------------------------

addWorksheet(
  wb,
  "Aranjuez"
)

writeData(
  wb,
  "Aranjuez",
  datos_aranjuez,
  withFilter = TRUE
)

freezePane(
  wb,
  "Aranjuez",
  firstRow = TRUE
)

setColWidths(
  wb,
  "Aranjuez",
  cols = 1:ncol(datos_aranjuez),
  widths = "auto"
)

# ------------------------------------------------------------
# FECHAS CON DATOS AUSENTES
# ------------------------------------------------------------

addWorksheet(
  wb,
  "fechas_sin_datos"
)

writeData(
  wb,
  "fechas_sin_datos",
  fechas_sin_datos,
  withFilter = TRUE
)

# ============================================================
# GUARDAR EXCEL
# ============================================================

saveWorkbook(
  wb,
  archivo_excel,
  overwrite = TRUE
)

# ============================================================
# GUARDAR CSV POR LOCALIDAD
# ============================================================

write.csv(
  datos_buitrago,
  file.path(
    carpeta_salida,
    "Buitrago_3110C_AEMET_2000_2020.csv"
  ),
  row.names = FALSE
)

write.csv(
  datos_colmenar,
  file.path(
    carpeta_salida,
    "Colmenar_Viejo_3191E_AEMET_2000_2020.csv"
  ),
  row.names = FALSE
)

write.csv(
  datos_aranjuez,
  file.path(
    carpeta_salida,
    "Aranjuez_3100B_AEMET_2000_2020.csv"
  ),
  row.names = FALSE
)

# ============================================================
# RESUMEN FINAL
# ============================================================

cat("\n")
cat("============================================\n")
cat("PROCESO FINALIZADO\n")
cat("============================================\n\n")

cat(
  "Buitrago:",
  nrow(datos_buitrago),
  "registros\n"
)

cat(
  "Colmenar Viejo:",
  nrow(datos_colmenar),
  "registros\n"
)

cat(
  "Aranjuez:",
  nrow(datos_aranjuez),
  "registros\n"
)

cat(
  "Filas con alguna variable climática ausente:",
  nrow(fechas_sin_datos),
  "\n\n"
)

cat(
  "Excel guardado en:\n",
  archivo_excel,
  "\n"
)

cat("\n============================================\n")