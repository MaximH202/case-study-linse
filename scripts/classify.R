source("scripts/setup.R")

# Read the consolidated menus
menus <- read_csv("data/menus_consolidated.csv") |> 
  mutate(
    student_service = as_factor(student_service),
    cafeteria = as_factor(cafeteria)
  )

# Run an R subscript (example)
source("scripts/subscripts_classify/classify_step_1.R")
source("scripts/subscripts_classify/classify_step_2.R") 
source("scripts/subscripts_classify/classify_step_3.R") #LLM Skript, hier vorher sample_size festlegen
source("scripts/subscripts_classify/classify_step_4.R") 
source("scripts/subscripts_classify/classify_step_5.R") 
source("scripts/subscripts_classify/classify_step_6.R") 
source("scripts/subscripts_classify/classify_step_7.R")