#Join und schreiben der Daten
# Ergebnisse mit dem ursprünglichen unique_dishes-Datensatz zusammenführen
llm_classified_short <- unique_dishes %>%
  distinct(product_name, .keep_all = TRUE) |> 
  select(-klassen, -menu_text) |> 
  right_join(llm_classified_short, by = "id")

llm_classified_short <- llm_classified_short |> 
  left_join(llm_classified_long |> distinct(id, code_main_protein), by = "id")


# Ergebnisse als CSV-Dateien für die weitere Analyse speichern
write_csv(llm_classified_short, "data/menus_classified.csv")
write_csv(llm_classified_long, "data/menu_components.csv")

#Join mit der gesamten menus liste um alle Einträge zu bekommen
menus_short <- menus |> 
  inner_join(llm_classified_short, by = "product_name")