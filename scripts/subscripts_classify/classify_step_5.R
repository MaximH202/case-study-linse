#Zuweisung der Lebensmittelklassen zu Ernährungsformen. 
#Die Zuweisung erfolgt durch eine Abstufung. Sobald Fleisch in der Mahlzeit ist, handelt es sich um omnivor, die restlichen Klassen sind egal.
#Befindet sich nur Fisch in der Mahlzeit, wird der Mahlzeit Pescetarisch zugewiesen, die restlichen Klassen sind egal. 
# etc.
# 1. Erst Funktion definieren
assign_level1 <- function(matched_classes, menu_text = "") {
  
  if (is.na(menu_text)) menu_text <- ""
  
  if (grepl("vegan", menu_text, ignore.case = TRUE)) return("vegan")
  if (grepl("vegetarisch", menu_text, ignore.case = TRUE)) return("vegetarisch")
  
  if (any(c("rotes_fleisch", "gefluegel") %in% matched_classes)) return("omnivor")
  if ("fisch" %in% matched_classes) return("pescetarisch")
  if (any(c("milchprodukte", "ei") %in% matched_classes)) return("vegetarisch")
  if (length(matched_classes) > 0) return("vegan")
  
  return(NA_character_)
}

# 2. Dann separat anwenden
classified <- classified |>
  mutate(
    ernaehrungsform = map2_chr(
      matched_classes,
      menu_clean,
      ~ assign_level1(matched_classes = .x, menu_text = .y)
    )
  )

classified_ausgeschrieben <- classified |>
  select(product_name, matched_classes, menu_text, ernaehrungsform) |>
  mutate(
    matched_classes_str = map_chr(matched_classes, ~ str_c(.x, collapse = ", "))
  )

