#Einzelne Zutaten mit Anteil am Gericht | LLM Output formatieren

#Andere Formatierung für das LLM Ergebnis. Hier wird für jede Lebensmittelklasse eines Gerichts eine eigene Spalte entfernt
#Ermöglich eine bessere Auswertung der Lebensmittelklassen
llm_classified_long <- results |>
  mutate(
    #Textspalte sauber als Charakter extrahieren
    text = map_chr(text, ~ as.character(.x[[1]])),
    
    #JSON parsen
    parsed = map(llm_result, safe_parse),
    
    # Flache Werte extrahieren (mit Fallbacks)
    ist_speise   = map_lgl(parsed, ~ .x$ist_speise %||% FALSE),
    hauptprotein = map_chr(parsed, ~ .x$hauptprotein %||% "keine_eindeutige_proteinquelle"),
    
    # llm_klassen extrahieren
    llm_klassen_df = map(parsed, ~ {
      klassen_data <- .x$alle_klassen
      
      # Fallback A: Wenn der Parse fehlschlug (leere list()) oder llm_klassen leer ist []
      if (is.null(klassen_data) || length(klassen_data) == 0) {
        return(tibble(klasse = NA_character_, anteil = NA_character_))
      }
      
      # Fallback B: Wenn es ein valider Dataframe ist
      if (is.data.frame(klassen_data)) {
        return(as_tibble(klassen_data))
      }
      
      # leer zurückgeben, falls unerwartetes Format
      return(tibble(klasse = NA_character_, anteil = NA_character_))
    })
  ) |>
  #  Das "Entpacken" der Dataframes in Zeilen
  # "keep_empty = TRUE" stellt sicher, dass Nicht-Speisen/Desserts als Zeile im Datensatz bleiben
  unnest(llm_klassen_df, keep_empty = TRUE) |>
  
  # Spalten auswählen und anordnen
  select(gericht_name, text, klasse, anteil, hauptprotein)

