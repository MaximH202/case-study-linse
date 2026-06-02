#Join und schreiben der Daten
# Ergebnisse mit dem ursprünglichen unique_dishes-Datensatz zusammenführen
menus_short <- menus |> 
  select(-id) |> 
  inner_join(llm_classified_short, by = "menu_text")

llm_classified_short <- llm_classified_short |> 
  left_join(llm_classified_long |> distinct(id, code_main_protein), by = "id")

menus_short <- menus_short |> 
  left_join(llm_classified_long |> distinct(product_name, code_main_protein), by = "product_name")

menus_long <- menus |> 
  select(-id, -menu_text) |> 
  inner_join(llm_classified_long, by = "product_name")


# Ergebnisse als CSV-Dateien für die weitere Analyse speichern
write_csv(llm_classified_short, "data/menus_classified.csv")
write_csv(llm_classified_long, "data/menu_components.csv")

#Join mit der gesamten menus liste um alle Einträge zu bekommen

menus_long <- menus |> 
  inner_join(llm_classified_short, by = "product_name")