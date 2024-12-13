library(tidyverse)
library(scico)
library(ggrepel)
library(stringr)


################# Tasks 1 and 2
## Load data
data <- read.csv("raw_scores/tasks_1_2.csv")

data <- data %>%
    filter(subset == "joint") %>%
    mutate(#regime = factor(regime),#, levels = c("Minimal", "Contextualized I", "Contextualized II"), labels=c("Minimal", "Context I", "Context II")),
           dataset = factor(dataset, levels=c("semeval", "fb"), labels=c("Twitter", "Facebook")))


# Pivoting the data
long <- data %>%
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

# Adding numbers for all, varying by dataset
long <- long %>% mutate(regime = ifelse(dataset == "Facebook" & regime == "all", "2000",
                                        ifelse(dataset == "Twitter" & regime == "all", "1352", regime)))

long <- long %>% mutate(
    metric = str_to_title(metric),
    metric = factor(metric, levels = c("F1", "Precision", "Recall")),
    regime = factor(regime, levels=c("zero-shot", "one-shot", "10", "100", "1000", "1352", "2000"),
                    labels=c("Zero-shot", "Few-shot", "10", "100", "1000", "1352", "2000")),
    model = factor(model, levels=c("BERT", "SBERT", "DeBERTa", "Mistral-7B",
                                   "Gemma-7B", "Llama3-8B", "Flan-T5", "Llama3-70B",
                                   "GPT3-Ada",
                                   "GPT3-Davinci", "Gemini-1.5", "GPT-4o")),

    )

long_subset <- long %>% filter(model %in% c("BERT", "DeBERTa", "Flan-T5", "Llama3-8B", "Llama3-70B", "GPT3-Ada",
                                            "GPT3-Davinci", "GPT-4o", "SBERT", "Mistral-7B"))

# Recode levels
levels(long_subset$model)[levels(long_subset$model) == "Flan-T5"] <- "Flan-T5 XXL"
levels(long_subset$model)[levels(long_subset$model) == "GPT3-Ada"] <- "GPT-3 Ada"
levels(long_subset$model)[levels(long_subset$model) == "GPT3-Davinci"] <- "GPT-3 Davinci"

label_positions <- data.frame(
    model = c("GPT4o", "GPT3-Davinci"),
    regime = c("Few-shot", "1352"),
    dataset = c("Facebook", "Twitter")
)

# Filter to include only relevant data points for the labels
labels <- long_subset %>%
  filter(metric == "F1" & paste(dataset, regime) %in% paste(label_positions$dataset, label_positions$regime)) %>%
  inner_join(label_positions, by = c("model", "regime", "dataset"))

dodge = position_dodge(width = 0.4)

hline_data <- data.frame(
    dataset = c("Twitter", "Facebook"),
    yintercept = c(0.48, 0.54)  # specify the yintercepts for each facet
)

hline_data_random <- data.frame(
    dataset = c("Twitter", "Facebook"),
    yintercept = c(1/6, 1/9)  # specify the yintercepts for each facet
)

ggplot(long_subset %>% filter(metric == "F1"), aes(y = estimate, x = regime, group = model, color = model)) +
    geom_pointrange(aes(ymin = ci.low, ymax = ci.high), position = dodge, size = 0.25) +
    geom_line(position = dodge, alpha = 0.5) +
    scale_color_viridis_d(option = "turbo") +
    geom_hline(data = hline_data, aes(yintercept = yintercept),color = "grey20", linetype = "dashed", size = 0.3) +
    geom_hline(data = hline_data_random, aes(yintercept = yintercept), color = "grey20", linetype = "dotted", size = 0.3) +
    facet_wrap(~ interaction(dataset), scales = "free_x", nrow = 2) +
    theme_classic(base_size = 11) +
    theme(legend.position = "bottom") +
    ylim(0,.95) +
    labs(y = "F1", x = "Learning regime", color = "Model")
ggsave("output/main_figure_baseline.pdf", width = 8.2)