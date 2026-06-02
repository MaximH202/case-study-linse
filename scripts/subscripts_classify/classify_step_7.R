#Join und schreiben der Daten
# Ergebnisse mit dem ursprünglichen unique_dishes-Datensatz zusammenführen

llm_classified_short <- llm_classified_short |> 
  left_join(llm_classified_long |> distinct(id, code_main_protein), by = "id")

menus_short <- menus |> 
  select(-menu_text) |> 
  inner_join(llm_classified_short, by = "product_name") |> 
  rename(id = id.x) |> 
  select(-id.y)

menus_long <- menus |> 
  select(-menu_text) |> 
  inner_join(llm_classified_long, by = "product_name") |> 
  rename(id= id.x) |> 
  select(-id.y)

#schönere Anordnung
menus_long <- menus_long |> 
  select(
    id,
    student_service,
    cafeteria,
    source_file,
    date,
    prod_type,
    production_location,
    actual_output,
    product_name,
    menu_text,
    group_level_2,
    anteil,
    code_main_protein,
    proteincode
  )

menus_short <- menus_short |> 
  select(
        id,
    student_service,
    cafeteria,
    source_file,
    date,
    prod_type,
    production_location,
    actual_output,
    product_name,
    menu_text,
    group_level_2,
    code_main_protein,
    group_level_1
  )
# Ergebnisse als CSV-Dateien für die weitere Analyse speichern
write_csv2(menus_short, "data/menus_classified.csv")
write_csv2(menus_long, "data/menu_components.csv")

#Join mit der gesamten menus liste um alle Einträge zu bekommen