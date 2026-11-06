# =============================================================================
# fetch_data.R — Téléchargement de la consommation électrique nationale (France)
# -----------------------------------------------------------------------------
# Source : éCO2mix (RTE), via la plateforme ODRÉ (Opendatasoft), sans clé d'API.
#   - eco2mix-national-cons-def : données définitives + consolidées (pas 30 min),
#                                 depuis 2012, mises à jour avec quelques mois de
#                                 retard.
#   - eco2mix-national-tr       : données temps réel (pas 15 min), qui couvrent
#                                 la période non encore consolidée.
#
# Sorties (non versionnées, cf. .gitignore) :
#   data/raw/eco2mix/<dataset>_<annee>.csv   un fichier par jeu de données et année
#   data/raw/eco2mix_national.csv            assemblage de tous les fichiers
#
# Les données sont laissées brutes : horodatage en UTC, aucune agrégation, aucun
# rééchantillonnage (le passage 15 min -> 30 min se fera au prétraitement).
#
# Utilisation :
#   Rscript scripts/fetch_data.R                # 2012 -> aujourd'hui
#   Rscript scripts/fetch_data.R 2020           # 2020 -> aujourd'hui
#   Rscript scripts/fetch_data.R 2020 --force   # retélécharge tout
#
# Ou depuis R : source("scripts/fetch_data.R"); fetch_eco2mix(start_year = 2020)
# =============================================================================

suppressPackageStartupMessages({
  library(httr2)
  library(readr)
})

ODRE_BASE_URL <- "https://odre.opendatasoft.com/api/explore/v2.1/catalog/datasets"
DATASET_DEF   <- "eco2mix-national-cons-def"
DATASET_TR    <- "eco2mix-national-tr"

# Colonnes conservées : consommation réalisée et prévisions officielles de RTE
# (utiles comme modèle de référence).
DEFAULT_FIELDS <- c("date_heure", "nature", "consommation",
                    "prevision_j1", "prevision_j")

COL_TYPES <- cols(
  date_heure   = col_datetime(format = ""),
  nature       = col_character(),
  consommation = col_double(),
  prevision_j1 = col_double(),
  prevision_j  = col_double(),
  .default     = col_double()
)

#' Télécharge un jeu de données éCO2mix entre deux dates (UTC, borne de fin exclue).
#' Seules les lignes avec une consommation renseignée sont conservées.
odre_export <- function(dataset, from, to, fields = DEFAULT_FIELDS) {
  where <- sprintf(
    'consommation is not null and date_heure >= "%s" and date_heure < "%s"',
    format(from, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    format(to,   "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )

  resp <- request(ODRE_BASE_URL) |>
    req_url_path_append(dataset, "exports", "csv") |>
    req_url_query(
      select    = paste(fields, collapse = ","),
      where     = where,
      order_by  = "date_heure",
      delimiter = ";",
      timezone  = "UTC"
    ) |>
    req_user_agent("energy-consumption-forecasting (R/httr2)") |>
    req_timeout(300) |>
    req_retry(max_tries = 4, backoff = function(i) 5 * i) |>
    req_perform()

  read_delim(resp_body_raw(resp), delim = ";", col_types = COL_TYPES,
             locale = locale(tz = "UTC"), progress = FALSE)
}

#' Renvoie la date de la dernière consommation disponible dans un jeu de données.
odre_last_timestamp <- function(dataset) {
  resp <- request(ODRE_BASE_URL) |>
    req_url_path_append(dataset, "records") |>
    req_url_query(select = "max(date_heure) as last",
                  where  = "consommation is not null") |>
    req_retry(max_tries = 4) |>
    req_perform() |>
    resp_body_json()
  as.POSIXct(resp$results[[1]]$last, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
}

#' Télécharge l'historique éCO2mix national et l'assemble en un seul fichier.
#'
#' @param start_year Première année à récupérer (les données commencent en 2012).
#' @param out_dir    Dossier de sortie des données brutes.
#' @param force      TRUE pour retélécharger les années déjà présentes.
#' @return Le data frame assemblé (invisible).
fetch_eco2mix <- function(start_year = 2012,
                          out_dir = file.path("data", "raw"),
                          force = FALSE) {
  year_dir <- file.path(out_dir, "eco2mix")
  dir.create(year_dir, recursive = TRUE, showWarnings = FALSE)

  now      <- Sys.time()
  last_def <- odre_last_timestamp(DATASET_DEF)
  message("Données consolidées disponibles jusqu'au ",
          format(last_def, "%Y-%m-%d %H:%M UTC"))

  # Découpage par année : requêtes de taille raisonnable et reprise possible.
  years <- seq(start_year, as.integer(format(now, "%Y", tz = "UTC")))
  plan <- rbind(
    data.frame(dataset = DATASET_DEF, year = years[years <= as.integer(format(last_def, "%Y"))]),
    data.frame(dataset = DATASET_TR,  year = years[years >= as.integer(format(last_def, "%Y"))])
  )

  files <- character(0)
  for (i in seq_len(nrow(plan))) {
    ds   <- plan$dataset[i]
    yr   <- plan$year[i]
    path <- file.path(year_dir, sprintf("%s_%d.csv", ds, yr))
    files <- c(files, path)

    from <- as.POSIXct(sprintf("%d-01-01", yr),     tz = "UTC")
    to   <- as.POSIXct(sprintf("%d-01-01", yr + 1), tz = "UTC")
    # Une année est « figée » si elle est entièrement consolidée.
    frozen <- ds == DATASET_DEF && to <= last_def
    if (file.exists(path) && frozen && !force) {
      message(sprintf("  [cache] %s %d", ds, yr))
      next
    }

    # Le temps réel ne sert qu'à compléter après la fin des données consolidées.
    if (ds == DATASET_TR) from <- max(from, last_def + 1)

    message(sprintf("  [télécharge] %s %d ...", ds, yr), appendLF = FALSE)
    df <- odre_export(ds, from, to)
    write_csv(df, path)
    message(sprintf(" %d lignes", nrow(df)))
  }

  all <- do.call(rbind, lapply(files[file.exists(files)], read_csv,
                               col_types = COL_TYPES, progress = FALSE))
  all <- all[order(all$date_heure), ]
  all <- all[!duplicated(all$date_heure), ]

  out_file <- file.path(out_dir, "eco2mix_national.csv")
  write_csv(all, out_file)
  message(sprintf("OK : %d lignes, du %s au %s -> %s", nrow(all),
                  format(min(all$date_heure), "%Y-%m-%d"),
                  format(max(all$date_heure), "%Y-%m-%d %H:%M UTC"), out_file))
  invisible(all)
}

# Exécution en ligne de commande -------------------------------------------------
if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  years <- suppressWarnings(as.integer(setdiff(args, "--force")))
  fetch_eco2mix(start_year = if (length(years) && !is.na(years[1])) years[1] else 2012,
                force = force)
}
