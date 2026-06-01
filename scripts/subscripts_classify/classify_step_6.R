#Hauptprotein durch mathematische Gewichtung ermitteln
llm_classified_long <- llm_classified_long |> 
  # 1. Punkte für Klasse und Anteil direkt im Datensatz vergeben (ohne Joins)
  mutate(
    p_klasse = case_when(
      klasse %in% c("rotes_fleisch", "gefluegel", "fisch") ~ 100,
      klasse == "huelsenfruechte"                           ~ 90,
      klasse %in% c("milchprodukte", "ei")                  ~ 80,
      klasse %in% c("nuesse", "samen")                      ~ 70,
      klasse == "getreide"                                  ~ 40,
      klasse == "knollen"                                   ~ 30,
      klasse == "gemuese"                                   ~ 10,
      TRUE                                                  ~ 0
    ),
    p_anteil = case_when(
      anteil == "dominant" ~ 3,
      anteil == "mittel"   ~ 2,
      anteil == "gering"   ~ 1,
      TRUE                 ~ 0
    ),
    score = p_klasse * p_anteil
  ) |> 
  
 group_by(id) |> 
  mutate(
    # Finde die Klasse mit dem höchsten Score. Falls der Score <= 30 ist, nimm den Fallback.
    hauptprotein = if_else(
      max(score) > 30, 
      klasse[which.max(score)], 
      "keine_eindeutige_proteinquelle"
    )
  ) |> 
  ungroup() |> 
  
  # 3. Rechenspalten löschen und Spalte umbenennen für die Abgabe
  select(-p_klasse, -p_anteil, -score) |> 
  rename(group_level_2 = klasse)
