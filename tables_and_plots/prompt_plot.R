library(tidyverse)
library(scico)
library(stringr)
library(viridis)

###### Prompt engineering table
prompt_engineering <- read.csv("raw_scores/prompt_engineering.csv") %>%
    mutate(target = factor(target, levels = c("Trump", "Clinton", "Joint")),
           regime = factor(regime, levels = c("Minimal", "Sentence", "Context")),
           dataset = factor(dataset, levels=c("semeval", "fb"), labels=c("SemEval", "Facebook"))) %>%
    group_by(dataset, target) %>%
    mutate(best_score = ifelse(f1_estimate == max(f1_estimate), 1, 0))

head(prompt_engineering)

# Pivoting the data
pe_long <- prompt_engineering %>%
    pivot_longer(
        cols = starts_with("f1_") | starts_with("recall_") | starts_with("precision_"),
        names_to = c("metric", "type"),
        names_sep = "_",
        values_to = "value"
    ) %>%
    pivot_wider(
        names_from = type,
        values_from = value
    )

pe_long <- pe_long %>% mutate(
    dataset = recode(dataset, SemEval = "Twitter"),
    dataset = factor(dataset, levels = c("Twitter", "Facebook")),
    metric = str_to_title(metric),
    metric = factor(metric, levels = c("F1", "Precision", "Recall")),
    target = factor(target, levels = c( "Clinton","Trump", "Joint"))
)

colors <- viridis(2, option = "turbo")

color_mapping <- c("Trump" = colors[2],
                   "Clinton" = colors[1],
                   "Joint" = "grey50")

dodge = position_dodge(width = 0.4)
ggplot(pe_long %>% filter(metric == "F1"), aes(y = estimate, x = regime, group = target, color = target, shape=target)) +
    geom_pointrange(aes(ymin=ci.low, ymax=ci.high), position=dodge, size = 0.25) +
    geom_line(position=dodge, alpha = 0.5, linetype = "dashed") +
    scale_color_manual(values = color_mapping) +
    scale_shape_manual(values=c("square", "triangle", "circle")) +
    facet_wrap(~ interaction(dataset)) +
    theme_classic(base_size = 11) +
    labs(y = "F1", x = "Prompt") +
    theme(legend.position = "bottom",
          legend.title = element_blank())
ggsave("output/prompt_variations.pdf", width = 5, height = 4)
