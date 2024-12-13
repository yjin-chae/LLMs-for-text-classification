library(tidyverse)
library(xtable)
library(knitr)
library(kableExtra)

empty_rows_semeval = tibble(
  "dataset"="semeval",
  "model"=c("BERT", "BERT", "SBERT", "SBERT", "DeBERTa", "GPT-4o", "GPT-4o", "GPT-4o"),
  "regime"=c("zero-shot", "one-shot", "zero-shot", "one-shot", "one-shot", "10", "100", "all")
)
empty_rows_fb = tibble(
  "dataset"="fb",
  "model"=c("BERT", "BERT", "SBERT", "SBERT", "DeBERTa", "GPT-4o", "GPT-4o", "GPT-4o","GPT-4o"),
  "regime"=c("zero-shot", "one-shot", "zero-shot", "one-shot", "one-shot", "10", "100","1000", "all")
)
model_list = c("BERT", "SBERT", "DeBERTa", "Flan-T5", "Mistral-7B", "Llama3-8B", "Llama3-70B", "GPT3-Ada", "GPT3-Davinci", "GPT-4o")

# Tasks 1 and 2 combined output scores
task12 = read_csv("raw_scores/tasks_1_2.csv") %>% 
  bind_rows(empty_rows_semeval) %>% 
  bind_rows(empty_rows_fb) %>% 
  filter(model %in% model_list) %>% 
  mutate(regime = factor(regime, levels=c("zero-shot", "one-shot", "10", "100", "1000", "all"),
                         labels=c("0", "1", "10", "100", "1000", "All")),
         model = factor(model, levels=model_list)) %>% 
  dplyr::select(dataset, model, regime, subset, ends_with("estimate")) %>%
  mutate(across(ends_with("estimate"), ~ round(.x, 2))) %>%
  arrange(dataset, model, regime)

# Twitter
task1 = task12 %>% 
  filter(dataset=="semeval") %>% 
  pivot_wider(names_from = subset, values_from = ends_with("estimate")) %>% 
  dplyr::select(-ends_with("NA")) %>% 
  rename_all(~ str_remove(.x, "estimate_")) %>% 
  dplyr::select(model, regime, starts_with("f1"), starts_with("recall"), starts_with("precision")) %>% 
  rename_all(~ str_replace_all(.x, pattern=c("f1"="F1","recall"="R","precision"="P",
                                             "target"="{T}","stance"="{S}","joint"="{Joint}"))) %>% 
  mutate(across(everything(), as.character)) %>% 
  mutate(across(everything(), ~ replace_na(.x, replace = "-")))

kbl(task1, format = "latex", booktabs=T) %>% 
  column_spec(c(5, 8), border_right = T) %>%
  collapse_rows(columns = 1, latex_hline = "major", row_group_label_position = "first") %>% 
  kable_styling(font_size = 10) %>% 
  write_file("output/task1.tex")

# Facebook
task2 = task12 %>% 
  filter(dataset=="fb") %>% 
  pivot_wider(names_from = subset, values_from = ends_with("estimate")) %>% 
  dplyr::select(-ends_with("NA")) %>% 
  rename_all(~ str_remove(.x, "estimate_")) %>% 
  dplyr::select(model, regime, starts_with("f1"), starts_with("recall"), starts_with("precision")) %>% 
  rename_all(~ str_replace_all(.x, pattern=c("f1"="F1","recall"="R","precision"="P",
                                             "clinton"="{C}","trump"="{T}","joint"="{Joint}"))) %>% 
  mutate(across(everything(), as.character)) %>% 
  mutate(across(everything(), ~ replace_na(.x, replace = "-")))

kbl(task2, format = "latex", booktabs=T) %>% 
  column_spec(c(5, 8), border_right = T) %>%
  collapse_rows(columns = 1, latex_hline = "major", row_group_label_position = "first") %>% 
  kable_styling(font_size = 9) %>% 
  write_file("output/task2.tex")

###################
task3 = read.csv("raw_scores/task3.csv") %>% 
  rbind(read.csv("raw_scores/task3_baseline.csv")) %>% 
  dplyr::select(regime, reply_set, reply_set_id, model, subset, ends_with("estimate")) %>% 
  pivot_wider(names_from = subset, values_from = ends_with("estimate")) %>% 
  mutate(across(matches("estimate"), ~ round(.x, 2))) %>% 
  rename_all(~ str_remove(.x, "estimate_")) %>% 
  mutate(regime = factor(regime, levels=c("zero-shot", "SFT", "Base"), labels=c("Zero", "SFT", "Baseline")),
         model_label = factor(paste(model, regime), levels=c("Llama3-8B Zero", "Llama3-8B SFT","Llama3-70B Zero", "Llama3-70B SFT", "GPT-4o Zero", "GPT-4o Baseline")),
         reply_set = factor(reply_set, levels=c("overall", "0", "1", "2", "3", "4", "5"), labels=c("All", "0", "1", "2", "3", "4", "5")),
         reply_set_id = factor(reply_set_id, levels=c("overall", "0", "1", "2", "3", "4", "5"), labels=c("All", "0", "1", "2", "3", "4", "5"))) %>% 
  arrange(reply_set, reply_set_id, model_label) %>% 
  filter(!(reply_set == 0 & reply_set_id == "All")) %>%
  rename_all(~ str_replace_all(.x, pattern=c("f1"="F1","recall"="R","precision"="P",
                                             "clinton"="{C}","trump"="{T}","joint"="{Joint}"))) %>% 
  dplyr::select(reply_set, reply_set_id, model_label, starts_with(c("F1", "R", "P")), -regime)

kbl(task3, "latex", longtable = T, booktabs=T) %>%
  column_spec(c(3, 6, 9), border_right = T) %>%
  collapse_rows(columns = 1:3, latex_hline = "custom", custom_latex_hline = 1:2, row_group_label_position = "first") %>% 
  kable_styling(latex_options = c("repeat_header")) %>% 
  write_file("output/task3.tex")
  
### Task 3 thread-wise joint score
task3_thread_joint = read.csv("raw_scores/task3_threadwise_joint.csv") %>% 
  dplyr::select(regime, reply_set, model, subset, ends_with("estimate")) %>% 
  pivot_wider(names_from = subset, values_from = ends_with("estimate")) %>% 
  mutate(across(matches("estimate"), ~ round(.x, 2))) %>% 
  rename_all(~ str_remove(.x, "estimate_")) %>% 
  mutate(regime = factor(regime, levels=c("zero-shot", "SFT", "Base"), labels=c("Zero", "SFT", "Baseline")),
         model_label = factor(paste(model, regime), levels=c("Llama3-8B Zero", "Llama3-8B SFT","Llama3-70B Zero", "Llama3-70B SFT", "GPT-4o Zero", "GPT-4o Baseline")),
         reply_set = factor(reply_set, levels=c("overall", "0", "1", "2", "3", "4", "5"), labels=c("All", "0", "1", "2", "3", "4", "5"))) %>% 
  arrange(reply_set, model_label) %>% 
  dplyr::select(reply_set, model_label, everything(), -regime, -model)

kbl(task3_thread_joint, "latex", longtable = T, booktabs=T) %>%
  column_spec(c(2, 5, 8), border_right = T) %>%
  collapse_rows(columns = 1:2, latex_hline = "major", row_group_label_position = "first") %>% 
  kable_styling(latex_options = c("repeat_header")) %>% 
  write_file("output/task3_threadwise_joint.tex")
