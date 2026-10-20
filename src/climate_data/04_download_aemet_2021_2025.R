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

# AEMET admite varios indicativos separados por comas
id_estaciones <- paste(
  estaciones$indicativo,
  collapse = ","
)

cat("Estaciones:\n")
print(estaciones)

# ============================================================
# PERIODO
# ============================================================

fecha_inicio <- as.Date("2021-01-01")
fecha_final  <- as.Date("2025-10-24")

fechas <- seq(
  fecha_inicio,
  fecha_final,
  by = "day"
)

cat("\nNúmero de días a descargar:", length(fechas), "\n\n")

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
  "AEMET_estaciones_Buitrago_Colmenar_Aranjuez_2021_2025.xlsx"
)

archivo_temporal <- file.path(
  carpeta_salida,
  "AEMET_descarga_temporal_2021_2025.csv"
)

# ============================================================
# FUNCIÓN PARA DESCARGAR UN SOLO DÍA
# ============================================================

descargar_dia <- function(
    fecha,
    estaciones,
    api_key,
    reintentos = 3
) {
  
  # IMPORTANTE:
  # inicio y fin son EXACTAMENTE IGUALES
  
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
      
      error = function(e) {
        NULL
      }
    )
    
    if (is.null(res)) {
      
      cat(
        "   Error de conexión. Intento",
        intento,
        "de",
        reintentos,
        "\n"
      )
      
      Sys.sleep(3)
      
      next
    }
    
    txt <- content(
      res,
      "text",
      encoding = "UTF-8"
    )
    
    # --------------------------------------------------------
    # ERROR HTTP
    # --------------------------------------------------------
    
    if (status_code(res) != 200) {
      
      cat(
        "   HTTP",
        status_code(res),
        "- intento",
        intento,
        "\n"
      )
      
      Sys.sleep(3)
      
      next
    }
    
    # --------------------------------------------------------
    # LEER RESPUESTA JSON
    # --------------------------------------------------------
    
    info <- tryCatch(
      
      fromJSON(txt),
      
      error = function(e) {
        NULL
      }
    )
    
    if (is.null(info)) {
      
      cat(
        "   Respuesta JSON inválida.\n"
      )
      
      Sys.sleep(3)
      
      next
    }
    
    # --------------------------------------------------------
    # COMPROBAR ESTADO INTERNO DE AEMET
    # --------------------------------------------------------
    
    if (
      !is.null(info$estado) &&
      info$estado != 200
    ) {
      
      descripcion <- ifelse(
        is.null(info$descripcion),
        "Sin descripción",
        info$descripcion
      )
      
      cat(
        "   AEMET:",
        info$estado,
        "-",
        descripcion,
        "\n"
      )
      
      # Si es el conocido error de fechas,
      # no tiene sentido repetir tres veces
      if (grepl(
        "fecha final",
        descripcion,
        ignore.case = TRUE
      )) {
        
        return(
          list(
            datos = NULL,
            estado = "ERROR_FECHA",
            mensaje = descripcion
          )
        )
      }
      
      Sys.sleep(3)
      
      next
    }
    
    # --------------------------------------------------------
    # COMPROBAR URL DE DATOS
    # --------------------------------------------------------
    
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
    
    # --------------------------------------------------------
    # SEGUNDA PETICIÓN: DATOS REALES
    # --------------------------------------------------------
    
    res2 <- tryCatch(
      
      GET(
        info$datos,
        timeout(60)
      ),
      
      error = function(e) {
        NULL
      }
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
      
      error = function(e) {
        NULL
      }
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
# RECUPERAR DESCARGA ANTERIOR SI EXISTE
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
    "Registros ya guardados:",
    nrow(datos_totales),
    "\n\n"
  )
  
} else {
  
  datos_totales <- data.frame()
}

# ============================================================
# RESUMEN DE DESCARGA
# ============================================================

resumen_descarga <- data.frame(
  fecha = as.Date(character()),
  estado = character(),
  registros = integer(),
  mensaje = character(),
  stringsAsFactors = FALSE
)

# ============================================================
# DESCARGAR DÍA A DÍA
# ============================================================

cat("\n")
cat("============================================\n")
cat("DESCARGA DIARIA AEMET\n")
cat("============================================\n\n")

for (i in seq_along(fechas)) {
  
  fecha_actual <- fechas[i]
  
  # ----------------------------------------------------------
  # Saltar fechas ya descargadas
  # ----------------------------------------------------------
  
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
  
  # ----------------------------------------------------------
  # SI FUNCIONA
  # ----------------------------------------------------------
  
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
    
    resumen_descarga <- bind_rows(
      resumen_descarga,
      data.frame(
        fecha = fecha_actual,
        estado = "OK",
        registros = nrow(datos_dia),
        mensaje = ""
      )
    )
    
  } else {
    
    cat(
      " -",
      resultado$estado,
      "-",
      resultado$mensaje,
      "\n"
    )
    
    resumen_descarga <- bind_rows(
      resumen_descarga,
      data.frame(
        fecha = fecha_actual,
        estado = resultado$estado,
        registros = 0,
        mensaje = resultado$mensaje
      )
    )
  }
  
  # ----------------------------------------------------------
  # GUARDADO TEMPORAL CADA 20 DÍAS
  # ----------------------------------------------------------
  
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
  
  # Pausa para no sobrecargar AEMET
  Sys.sleep(1)
}

# ============================================================
# COMPROBAR RESULTADO
# ============================================================

if (nrow(datos_totales) == 0) {
  
  cat("\n")
  cat("============================================\n")
  cat("NO SE HA PODIDO DESCARGAR NINGÚN DÍA\n")
  cat("============================================\n\n")
  
  cat(
    "Si incluso una petición con fecha inicial y final iguales\n",
    "devuelve 'La fecha final no puede ser mayor que la fecha inicial',\n",
    "el endpoint de climatologías diarias de AEMET está averiado\n",
    "y no existe una corrección posible desde R.\n"
  )
  
  stop("AEMET no ha devuelto datos.")
}

# ============================================================
# FORMATO FECHA
# ============================================================

datos_totales$fecha <- as.Date(
  datos_totales$fecha
)

# ============================================================
# AÑADIR NOMBRE DE LOCALIDAD
# ============================================================

datos_totales <- datos_totales %>%
  
  left_join(
    estaciones,
    by = "indicativo"
  ) %>%
  
  arrange(
    indicativo,
    fecha
  )

# ============================================================
# ELIMINAR POSIBLES DUPLICADOS
# ============================================================

datos_totales <- datos_totales %>%
  
  distinct(
    indicativo,
    fecha,
    .keep_all = TRUE
  )

# ============================================================
# CREAR AÑO, MES Y DÍA
# ============================================================

datos_totales <- datos_totales %>%
  
  mutate(
    
    day = as.integer(
      format(fecha, "%d")
    ),
    
    month = as.integer(
      format(fecha, "%m")
    ),
    
    year = as.integer(
      format(fecha, "%Y")
    )
  )

# ============================================================
# CREAR TASMEAN SI EXISTEN TMAX Y TMIN
# ============================================================

if (
  all(
    c("tmax", "tmin") %in%
    names(datos_totales)
  )
) {
  
  # AEMET suele usar coma decimal
  datos_totales$tmax_num <- as.numeric(
    gsub(
      ",",
      ".",
      datos_totales$tmax,
      fixed = TRUE
    )
  )
  
  datos_totales$tmin_num <- as.numeric(
    gsub(
      ",",
      ".",
      datos_totales$tmin,
      fixed = TRUE
    )
  )
  
  datos_totales$tasmean <- (
    datos_totales$tmax_num +
      datos_totales$tmin_num
  ) / 2
}

# ============================================================
# SEPARAR LOCALIDADES
# ============================================================

datos_buitrago <- datos_totales %>%
  filter(
    indicativo == "3110C"
  )

datos_colmenar <- datos_totales %>%
  filter(
    indicativo == "3191E"
  )

datos_aranjuez <- datos_totales %>%
  filter(
    indicativo == "3100B"
  )

# ============================================================
# CREAR EXCEL
# ============================================================

wb <- createWorkbook()

# ------------------------------------------------------------
# TODOS
# ------------------------------------------------------------

addWorksheet(
  wb,
  "datos_completos"
)

writeData(
  wb,
  "datos_completos",
  datos_totales,
  withFilter = TRUE
)

freezePane(
  wb,
  "datos_completos",
  firstRow = TRUE
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

# ------------------------------------------------------------
# COLMENAR
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

# ------------------------------------------------------------
# RESUMEN DE DESCARGA
# ------------------------------------------------------------

addWorksheet(
  wb,
  "resumen_descarga"
)

writeData(
  wb,
  "resumen_descarga",
  resumen_descarga,
  withFilter = TRUE
)

# ------------------------------------------------------------
# ESTACIONES
# ------------------------------------------------------------

addWorksheet(
  wb,
  "estaciones"
)

writeData(
  wb,
  "estaciones",
  estaciones
)

# ============================================================
# GUARDAR
# ============================================================

saveWorkbook(
  wb,
  archivo_excel,
  overwrite = TRUE
)

# ============================================================
# GUARDAR CSV INDIVIDUALES
# ============================================================

write.csv(
  datos_buitrago,
  file.path(
    carpeta_salida,
    "Buitrago_3110C_AEMET_2021_2025.csv"
  ),
  row.names = FALSE
)

write.csv(
  datos_colmenar,
  file.path(
    carpeta_salida,
    "Colmenar_Viejo_3191E_AEMET_2021_2025.csv"
  ),
  row.names = FALSE
)

write.csv(
  datos_aranjuez,
  file.path(
    carpeta_salida,
    "Aranjuez_3100B_AEMET_2021_2025.csv"
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
  "días\n"
)

cat(
  "Colmenar Viejo:",
  nrow(datos_colmenar),
  "días\n"
)

cat(
  "Aranjuez:",
  nrow(datos_aranjuez),
  "días\n\n"
)

cat(
  "Excel guardado en:\n",
  archivo_excel,
  "\n"
)

cat("\n============================================\n")