#Hauptprotein durch mathematische Gewichtung ermitteln
llm_classified_long <- llm_classified_long |> 
  # 1. Punkte für Klasse und Anteil direkt im Datensatz vergeben (ohne Joins)
  mutate(
    p_klasse = case_when(
      group_level_2 %in% c("rotes_fleisch", "gefluegel", "fisch") ~ 100,
      group_level_2 == "huelsenfruechte"                           ~ 90,
      group_level_2 %in% c("milchprodukte", "ei")                  ~ 80,
      group_level_2 %in% c("nuesse", "samen")                      ~ 70,
      group_level_2 == "getreide"                                  ~ 40,
      group_level_2 == "knollen"                                   ~ 30,
      group_level_2 == "gemuese"                                   ~ 10,
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
    code_main_protein = if_else(
      max(score) > 20, 
      group_level_2[which.max(score)], 
      "keine_eindeutige_proteinquelle"
    )
  ) |> 
  ungroup() |> 
  
  # 3. Rechenspalten löschen und Spalte umbenennen für die Abgabe
  select(-p_klasse, -p_anteil, -score)
