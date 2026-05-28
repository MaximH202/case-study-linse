#Einzelne Zutaten mit Anteil am Gericht | LLM Output formatieren

results_tbl <- as_tibble(results)

safe_parse <- possibly(fromJSON, otherwise = list())

