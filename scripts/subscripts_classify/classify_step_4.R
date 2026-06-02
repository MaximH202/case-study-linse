# 4. LLM-Output ins Long-Format überführen
# Jedes Gericht wird in seine einzelnen Zutatenklassen zerlegt (erleichtert die spätere Analyse)
llm_classified_long <- results |>
  mutate(
    # JSON-Daten aus dem LLM-Ergebnis parsen
    parsed = map(llm_result, safe_parse),
    
    # Hauptprotein und Speise-Kennzeichnung extrahieren (mit Default-Fallbacks)
    ist_speise   = map_lgl(parsed, ~ .x$ist_speise %||% FALSE),
    
    # Zutatenklassen aus der JSON-Struktur extrahieren
    llm_klassen_df = map(parsed, ~ {
      klassen_data <- .x$alle_klassen
      
      # Fallback A: Keine Klassen geliefert oder fehlerhafter Parse
      if (is.null(klassen_data) || length(klassen_data) == 0) {
        return(tibble(klasse = NA_character_, anteil = NA_character_))
      }
      
      # Fallback B: Daten liegen bereits als Dataframe vor
      if (is.data.frame(klassen_data)) {
        return(as_tibble(klassen_data))
      }
      # Fallback C: Absicherung für unerwartete Formate
      return(tibble(klasse = NA_character_, anteil = NA_character_))
    })
  ) |>
  # Geschachtelte Listen in einzelne Zeilen entpacken (keep_empty = TRUE erhält Desserts/Beilagen)
  unnest(llm_klassen_df, keep_empty = TRUE) |>
  
  # Relevante Spalten selektieren und mit Gerichts-ID verknüpfen
  select(id, klasse, anteil) |> 
  left_join(unique_dishes |> select(id, product_name, menu_text), 
            by = "id") 

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
