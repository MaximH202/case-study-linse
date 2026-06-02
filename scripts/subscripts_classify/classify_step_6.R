# 6. Hauptprotein durch mathematische Gewichtung ermitteln
# In einem Gericht wie "Nudeln mit Hähnchen" gibt es zwei Zutatenklassen. 
# Aber welche ist die "Hauptzutat" bzw. das primäre Protein? 
# Um das zu entscheiden, vergeben wir hier Punkte (Scores) für jede Zutat.

llm_classified_long <- llm_classified_long |> 
  # 1. Punkte-Vergabe für die Lebensmittelklasse
  # Fleisch und Fisch gelten traditionell oft als Hauptkomponente (100 Punkte).
  # Pflanzliche Alternativen bekommen etwas weniger, Sättigungsbeilagen (Getreide) oder Gemüse noch weniger.
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
    # 2. Punkte-Vergabe für den Anteil, den das LLM geschätzt hat
    # Eine dominante Zutat ist wichtiger als eine, die nur eine Beilage ist.
    p_anteil = case_when(
      anteil == "dominant" ~ 3,
      anteil == "mittel"   ~ 2,
      anteil == "gering"   ~ 1,
      TRUE                 ~ 0
    ),
    # Wir multiplizieren beide Werte. 
    score = p_klasse * p_anteil
  ) |> 
  
  # Jetzt schauen wir uns für jedes Gericht (id) die Scores aller Zutaten an.
  group_by(id) |> 
  mutate(
    # Wir suchen die Zutat mit dem höchsten Score.
    # Wenn der höchste Score allerdings sehr klein ist (<= 20), z.B. weil es nur Gemüse als Beilage gibt, 
    # dann sagen wir ehrlich: "Keine eindeutige Proteinquelle".
    code_main_protein = if_else(
      max(score) > 20, 
      group_level_2[which.max(score)], 
      "keine_eindeutige_proteinquelle"
    )
  ) |> 
  # Gruppierung wieder aufheben
  ungroup() |> 
  
  # 3. Aufräumen
  select(-p_klasse, -p_anteil, -score)
