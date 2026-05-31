# 5. Ernährungsformen klassifizieren und CSV-Dateien exportieren
# Hierarchische Zuordnung: Fleisch dominierend (omnivor), gefolgt von Fisch (pescetarisch) und Milch/Ei (vegetarisch), ansonsten vegan
# Hilfsfunktion zur Ermittlung der Ernährungsform definieren
assign_level1 <- function(klassen_str= " ", menu_text = " ") {
  
  # Null- und Leerwerte abfangen
  if (is.na(menu_text)) menu_text <- " "
  if (is.na(klassen_str) || klassen_str == " ") return(NA_character_)
  
  # Direkte Textsuche im Gerichtsnamen bevorzugen (Explizite Kennzeichnung als vegetarisch/vegan)
  if (grepl("vegan", menu_text, ignore.case = TRUE)) return("vegan")
  if (grepl("vegetarisch", menu_text, ignore.case = TRUE)) return("vegetarisch")
  
  # Komma-getrennten String in einen Vektor einzelner Klassen zerlegen
  klassen_vector <- trimws(strsplit(klassen_str, ",")[[1]])
  
  # Priorisierte Zuordnung der Ernährungsform
  if (any(c("rotes_fleisch", "gefluegel") %in% klassen_vector)) return("omnivor")
  if ("fisch" %in% klassen_vector) return("pescetarisch")
  if (any(c("milchprodukte", "ei") %in% klassen_vector)) return("vegetarisch")
  if (length(klassen_vector) > 0) return("vegan")
  
  return(NA_character_)
}

# Hilfsfunktion zeilenweise auf den Datensatz anwenden
llm_classified_short <- llm_classified_short |>
  mutate(
    ernaehrungsform = map2_chr(
      klassen,
      menu_text,
      ~ assign_level1(klassen = .x, menu_text = .y)
    )
  )
# Ergebnisse als CSV-Dateien für die weitere Analyse speichern
write_csv(llm_classified_short, "data/menus_classified.csv")
write_csv(llm_classified_long, "data/menu_components.csv")

#Join mit der gesamten menus liste um alle Einträge zu bekommen
menus_short <- menus |> 
  inner_join(llm_classified_short, by = "product_name")
