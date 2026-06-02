# 4. LLM-Output ins Long-Format überführen
# Bisher hatten wir pro Gericht eine Zeile (Short-Format), in der alle Zutaten-Klassen 
# mit Komma getrennt standen. Das ist schwer zu analysieren.
# Daher bauen wir den Datensatz jetzt ins "Long-Format" um: 
# Jedes Gericht wird in seine Zutaten zerlegt.

llm_classified_long <- results |>
  mutate(
    # JSON-Daten aus dem LLM-Ergebnis sicher auspacken
    parsed = map(llm_result, safe_parse),
    
    # Hauptprotein und Speise-Kennzeichnung extrahieren (falls nichts da ist, nehmen wir "FALSE")
    ist_speise   = map_lgl(parsed, ~ .x$ist_speise %||% FALSE),
    
    # Hier holen wir uns die genaue Tabelle der Zutatenklassen (Klasse + Anteil) aus dem JSON
    llm_klassen_df = map(parsed, ~ {
      klassen_data <- .x$alle_klassen
      
      # Fallback A: Das LLM hat keine Klassen geliefert oder der Parse ist fehlerhaft.
      # Dann geben wir eine Tabelle mit "NA" (Not Available) zurück.
      if (is.null(klassen_data) || length(klassen_data) == 0) {
        return(tibble(klasse = NA_character_, anteil = NA_character_))
      }
      
      # Wenn alles geklappt hat und wir einen Dataframe haben:
      if (is.data.frame(klassen_data)) {
          df_clean <- as_tibble(klassen_data) |> 
          # SICHERHEITSFILTER: Schmeißt alle Klassen raus, die das LLM evtl. halluziniert hat 
          # und die nicht in unserem Projekt-Schema (erlaubte_klassen) stehen.
          filter(klasse %in% erlaubte_klassen)
        
        # Falls das LLM NUR Quatsch geliefert hat und der Filter jetzt alles gelöscht hat:
        if (nrow(df_clean) == 0) {
          return(tibble(klasse = NA_character_, anteil = NA_character_))
        }
         return(df_clean)
      }
      # Fallback C: Absicherung für ganz unerwartete Formate, die das R-Skript abstürzen ließen.
      return(tibble(klasse = NA_character_, anteil = NA_character_))
    })
  ) |>
  # Wir werfen alles raus, was keine Hauptspeise ist.
  filter(ist_speise != FALSE) |>
   
  # Aus einer Zeile mit 3 Zutaten werden hier 3 separate Zeilen
  unnest(llm_klassen_df, keep_empty = TRUE) |>
  
  # Wir behalten nur die wichtigen Spalten und kleben den Original-Namen und Text wieder dran
  select(id, klasse, anteil) |> 
  left_join(unique_dishes |> select(id, product_name, menu_text), 
            by = "id") |> 
  rename(group_level_2 = klasse)|>
  
  # Hier sortieren wir Gerichte aus, die nur aus einer reinen Sättigungsbeilage (z.B. nur "getreide") 
  # bestehen und somit kein richtiges Hauptgericht sind.
  group_by(id) |>
  filter(
    !(n() == 1 & group_level_2 %in% c("getreide", "knollen", "gemuese"))
  ) |>
  ungroup()

# Zum Schluss geben wir jeder Zutatenklasse noch einen "proteincode".
llm_classified_long <- llm_classified_long |>
  mutate(
    proteincode = case_when(
      group_level_2 %in% c("milchprodukte", "eier") ~ "very_high",
      group_level_2 %in% c("rotes_fleisch", "gefluegel", "fisch") ~ "high",
      group_level_2 %in% c("huelsenfruechte", "leguminosen") ~ "medium",
      group_level_2 %in% c("getreide", "samen", "nuesse") ~ "low",
      group_level_2 %in% c("gemuese", "obst") ~ "very_low",
      TRUE ~ "unbekannt"
    )
  )
