library(tidyverse)
library(scico)
library(ggrepel)
library(stringr)
library(forcats)
library(viridis)

threads <- read_csv("raw_scores/task3.csv")


threads_bl <- read_csv("raw_scores/task3_baseline.csv")

data <- bind_rows(threads, threads_bl)

data <- rename(data,
       thread_length = reply_set,
       thread_position = reply_set_id)

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

long <- long %>% mutate(
    metric = str_to_title(metric),
    metric = factor(metric, levels = c("F1", "Precision", "Recall")),
    regime = factor(regime, levels=c("Base", "zero-shot", "SFT")),
    thread_length = factor(thread_length, levels=c("overall", "0", "1", "2", "3", "4", "5")),
    thread_position = factor(thread_position, levels=c("overall", "0", "1", "2", "3", "4", "5")),
    subset = factor(subset, levels = c("clinton", "trump", "joint")),
    model_label = case_when(model == "Llama3-70B" & regime == "zero-shot" ~ "Llama3-70B 0s",
                            model == "Llama3-70B" & regime == "SFT" ~ "Llama3-70B SFT",
                            model == "Llama3-8B" & regime == "zero-shot" ~ "Llama3-8B 0s",
                            model == "Llama3-8B" & regime == "SFT" ~ "Llama3-8B SFT",
                            model == "GPT-4o" & regime == "Base" ~ "GPT-4o 0s baseline",
                            model == "GPT-4o" & regime == "zero-shot" ~ "GPT-4o 0s",),
    model_label = factor(model_label, levels=c("GPT-4o 0s baseline", "Llama3-8B 0s", "Llama3-70B 0s", "GPT-4o 0s", "Llama3-8B SFT",  "Llama3-70B SFT")),
    model = factor(model, levels = c("GPT-4o", "Llama3-8B", "Llama3-70B"))

)

long$regime <- fct_recode(long$regime,
                          "Baseline: Zero-shot text" = "Base",
                          "Zero-shot JSON" = "zero-shot",
                          "Instruction-tuned JSON" = "SFT")

overall <- long %>% filter(thread_length == "overall" & thread_position == "overall" & metric == "F1" & subset == "joint")

# Using custom colors to match main plot

colors <- viridis(10, option = "turbo")

color_mapping <- c("GPT-4o" = colors[10],
                   "Llama3-8B" = colors[5],
                   "Llama3-70B" = colors[7])

# Making overall plot
dodge = position_dodge(width = 0.3)
ggplot(overall, aes(y = estimate, x = regime, group = model, color = model)) +
    geom_pointrange(aes(ymin = ci.low, ymax = ci.high), position = dodge, size = 0.3) +
    geom_line(position = dodge, alpha = 0.5) +
    #scale_color_scico_d(palette = "tokyo", begin = 0.05, end = 0.8) +
    scale_color_manual(values = color_mapping) +
    #facet_wrap(~ interaction(subset), scales = "free_x", nrow = 1) +
    theme_classic(base_size = 10) +
    labs(y = "F1", x = "Learning regime", color = "") +
    theme(legend.position = "bottom")
ggsave("output/task3_overall.pdf", width = 7, height = 4)

# Larger plot faceted by thread length and position
long$thread_position <- fct_recode(long$thread_position,
                          "Comment" = "0",
                          "Reply 1" = "1",
                          "Reply 2" = "2",
                          "Reply 3" = "3",
                          "Reply 4" = "4",
                          "Reply 5" = "5",
                          )

long_both_f1 <- long %>% filter(metric == "F1" & subset == "joint" &
                                    thread_position != "overall" & thread_length != "overall")

dodge = position_dodge(width = 0.5)

ggplot(long_both_f1 %>% filter(model_label %in% c("Llama3-70B SFT")),
       aes(y = estimate, x = thread_length, group = thread_position)) +
    geom_pointrange(aes(ymin = ci.low, ymax = ci.high), size = 0.3) +
    geom_line(alpha=0.5, linetype = "dashed") +
    scale_color_scico_d(palette = "glasgow", begin = 0.05, end = 0.8) +
    facet_grid(~ thread_position, scales = "free_x", space = "free_x") +
    theme_classic(base_size = 10) +
    labs(y = "F1", x = "Number of replies", color = "") + ylim(0.5,1)
ggsave("output/task3_by_length_and_position.pdf", width = 8.2, height = 4)
