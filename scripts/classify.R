source("scripts/setup.R")

# Read the consolidated menus
menus <- read_csv("data/menus_consolidated.csv") |> 
  mutate(
    student_service = as_factor(student_service),
    cafeteria = as_factor(cafeteria)
  )

# Run an R subscript (example)
source("scripts/subscripts_classify/classify_step_1.R")  

# Run a Python subscript
reticulate::source_python("scripts/subscripts_classify/classify_with_llm_openai.py")

# EXAMPLE 1: ONLY PROMPT, NO STRUCTURED OUTPUT ####

user_prompt_template = "Classify the following text into 'nice' or 'mean'. Return only the label: '{text}.'" 
text = "Have a great day"
user_prompt = str_glue(user_prompt_template)

result = process_with_llm_openai(
  model_name = "gpt-5-nano",
  system_prompt = "You are a helpful assistant",
  user_prompt = user_prompt
)

# Convert the result from Python to a tibble
result <- as_tibble(result)
print(result)


# EXAMPLE 2: BATCH PROCESSING OF A TIBBLE (ROW-BY-ROW) ####

# Prepare data for batch processing (example)
batch_menus <- menus |> 
  slice_sample(n = 5) |> 
  select(text = menu_text) 

user_prompt_template <- "
Classify the following menu item from a university's cafeteria into 'healthy' or ' unhealthy'. Return only the label.

Here is the name of the menu item:
   
{text}
"

results = process_rows_with_llm_openai(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a helpful assistant.",
  user_prompt_template = user_prompt_template,
  log_fn = log_to_r
)

results <- as_tibble(results)

results |> 
  select(llm_result, text)


# EXAMPLE 3: BATCH PROCESSING WITH STRUCTURED OUTPUT ####

user_prompt_template <- "
Classify the following menu item from a university's cafeteria into 'healthy' or ' unhealthy'. 

Return label and a one-sentence explanation for your decision.

Here is the name of the menu item:
   
{text}
"
# Define a schema for the output
schema <- '{
  "type": "object",
  "properties": {
    "label": {
      "type": "string",
      "enum": ["healthy", "unhealthy"]
    },
    "explanation": {
      "type": "string"
    }
  },
  "required": ["label", "explanation"],
  "additionalProperties": false
}'

results = process_rows_with_llm_openai(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a helpful assistant.",
  user_prompt_template = user_prompt_template,
  schema = schema,
  log_fn = log_to_r
)

results <- as_tibble(results)

results |> 
  glimpse()

safe_parse <- possibly(fromJSON, otherwise = NA)

results |>
  mutate(parsed = map(llm_result, safe_parse)) |>
  unnest_wider(parsed) |> 
  select(label, explanation, text)

# EXAMPLE 4: BATCH PROCESSING WITH STRUCTURED OUTPUT INCLUDING LISTS ####

user_prompt_template <- "
Extract the most likely ingredients from the following cafetearia menu item.

Do not consider ingredients that only appear in small quantities like salt, sugar, herbs or spices. Only
ingredients that constitute a main part of the food and contain proteins, carbs or fats.

Here is the name of the menu item:
   
{text}
"

schema = '{
  "type": "object",
  "properties": {
    "menu_ingredients": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "ingredient": { 
            "type": "string" 
          },
          "share": { 
            "type": "string", 
            "description": "An estimation of the share of this ingredient in the overall meal.",
            "enum": ["low", "medium", "high"] 
            }
        },
        "required": ["ingredient", "share"],
        "additionalProperties": false
      }
    }
  },
  "required": ["menu_ingredients"],
  "additionalProperties": false
}'

results = process_rows_with_llm_openai(
  data = batch_menus,
  model = "gpt-5-nano",
  system_prompt = "You are a helpful assistant.",
  user_prompt_template = user_prompt_template,
  schema = schema,
  log_fn = log_to_r
)

results <- as_tibble(results)

results |> 
  select(llm_result)

menus_with_ingredients <- results |>
  mutate(parsed = map(llm_result, safe_parse)) |> 
  unnest_wider(parsed) |> 
  unnest_longer(menu_ingredients) |>
  unnest_wider(menu_ingredients) |>
  select(ingredient, share, text, total_tokens, model_used)


# Write the results of the classification to "data/menus_classified.csv" (example)
menus_with_ingredients |>
  write_csv("data/menus_classified.csv")
