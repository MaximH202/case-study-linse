#Zuweisung der Lebensmittelklassen zu Ernährungsformen. 
#Die Zuweisung erfolgt durch eine Abstufung. Sobald Fleisch in der Mahlzeit ist, handelt es sich um omnivor, die restlichen Klassen sind egal.
#Befindet sich nur Fisch in der Mahlzeit, wird der Mahlzeit Pescetarisch zugewiesen, die restlichen Klassen sind egal. 
# etc.
# Erst Funktion definieren
assign_level1 <- function(klassen_str= " ", menu_text = " ") {
  
  if (is.na(menu_text)) menu_text <- " "
  if (is.na(klassen_str) || klassen_str == " ") return(NA_character_)
  
  # 1. Priorität: Textsuche im Namen, wenn vegan oder vegetarisch drin steht ist die Ernährungsform klar
  if (grepl("vegan", menu_text, ignore.case = TRUE)) return("vegan")
  if (grepl("vegetarisch", menu_text, ignore.case = TRUE)) return("vegetarisch")
  
  # Text-String in einzelne Klassen aufteilen (z.B. "fisch, getreide" -> c("fisch", "getreide"))
  klassen_vector <- trimws(strsplit(klassen_str, ",")[[1]])
  
  # Die eigentliche Klassenzuweisung, nach Rangliste
  if (any(c("rotes_fleisch", "gefluegel") %in% klassen_vector)) return("omnivor")
  if ("fisch" %in% klassen_vector) return("pescetarisch")
  if (any(c("milchprodukte", "ei") %in% klassen_vector)) return("vegetarisch")
  if (length(klassen_vector) > 0) return("vegan")
  
  return(NA_character_)
}

#  Dann separat anwenden mit joined_df
llm_classified_short <- llm_classified_short |>
  mutate(
    ernaehrungsform = map2_chr(
      klassen,
      menu_text,
      ~ assign_level1(klassen = .x, menu_text = .y)
    )
  )
write_csv(llm_classified_short, "data/menus_classified.csv")
write_csv(llm_classified_long, "data/menu_components.csv")

