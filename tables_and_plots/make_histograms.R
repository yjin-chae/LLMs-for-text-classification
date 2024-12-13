library(tidyverse)
library(ggplot2)
library(reshape2)
library(ggpubr)
library(scales)

one <- read_csv("raw_scores/fb_one_shot_clinton_trump_distribution.csv")
two <- read_csv("raw_scores/semeval_two_shot_clinton_trump_distribution.csv")

# Defining the line
df_line <- data.frame(
    x = seq(from = 0, to = 1, by = 0.01),
    y = seq(from = 0, to = 1, by = 0.01))

# Defining areas either side of the line
df_poly_under <- df_line %>%
    tibble::add_row(x = c(1, 0),
                    y = c(-Inf, -Inf))

df_poly_above <- df_line %>%
    tibble::add_row(x = c(1, 0),
                    y = c(Inf, Inf))

# Getting shading colors
palette <- scales::viridis_pal(option = "turbo")(2)

S1A <- ggplot(data = one, aes(x=Clinton, y = Trump)) + geom_point(alpha = 0.8) +
    geom_smooth(method = "lm", se = F, linetype = "dashed",
                color = "black") + theme_classic() +
    labs(x = "F1 Clinton",
         y = "F1 Trump",
         title = "FB 1-shot") +
    scale_x_continuous(labels = scales::number_format(accuracy = 0.01),
                       breaks = seq(0,1, 0.1)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                       breaks = seq(0,1, 0.1)) +
    geom_polygon(data = df_poly_under,
                 aes(x = x, y = y),
                 fill = palette[1],
                 alpha = 0.3) +
    geom_polygon(data = df_poly_above,
                 aes(x = x, y = y),
                 fill = palette[2],
                 alpha = 0.1) +
    coord_cartesian(xlim = range(one$Clinton),
                    ylim = range(one$Trump))

S2A <- ggplot(data = two, aes(x=Clinton, y = Trump)) + geom_point(alpha = 0.8) +
    geom_smooth(method = "lm", se = F, linetype = "dashed",
                color = "black") + theme_classic() +
    labs(x = "F1 Clinton",y = "F1 Trump",
         title = "TW 2-shot") +
    scale_x_continuous(labels = scales::number_format(accuracy = 0.01),
                       breaks = seq(0,1, 0.1)) +
    scale_y_continuous(labels = scales::number_format(accuracy = 0.01),
                       breaks = seq(0,1, 0.1)) +
    geom_polygon(data = df_poly_under,
                 aes(x = x, y = y),
                 fill = palette[1],
                 alpha = 0.3) +
    geom_polygon(data = df_poly_above,
                 aes(x = x, y = y),
                 fill = palette[2],
                 alpha = 0.1) +
    coord_cartesian(xlim = range(two$Clinton),
                    ylim = range(two$Trump))

f <- ggarrange(S1A, S2A,ncol = 2)
ggsave("output/1shot_2shot_correlations_shaded.pdf",f, width = 4, height = 4)

# HISTOGRAMS
colnames(one) <- c("FB Clinton 1-shot", "FB Trump 1-shot")
colnames(two) <- c("TW Clinton 2-shot", "TW Trump 2-shot")
data <- bind_cols(one, two) %>% melt()

data <- data %>% mutate(Target = 
                            ifelse(variable == "FB Trump 1-shot" | variable == "TW Trump 2-shot","T","C"))

# Need to calculate means first to use in faceted plot
dataline <- data %>% group_by(variable) %>% summarize(m = mean(value))

ggplot(data=data, aes(x=value, group = variable, fill = Target)) + 
    geom_histogram(alpha = 0.75, bins = 25) + 
    facet_wrap(~variable) +
    theme_classic() + labs(y = "Count", x = "F1 score") +
    scale_fill_viridis_d(option = "turbo") +
    geom_vline(data  = dataline, aes(xintercept = m), linetype = "dashed") +
    theme(legend.position = "none")
ggsave("output/1shot2shot_histograms.pdf", width = 4, height = 4)