library(tidyverse)
library(modelsummary)
library(stringr)
library(stringi)

one <- read_csv("raw_scores/fb_one_shot_clinton_trump_distribution.csv")
colnames(one) <- c("F1C", "F1T")
two <- read_csv("raw_scores/semeval_two_shot_clinton_trump_distribution.csv")
colnames(two) <- c("F1C", "F1T")

# Loading examples
# Facebook
fb <- read_csv("raw_scores/fb_train_100.csv") %>%
    mutate(Trump = as.factor(str_squish(Trump)),
           Clinton = as.factor(str_squish(Clinton)),
           wordcount = stri_count_words(prompt))
fb$Trump <- relevel(fb$Trump, ref = "None")
fb$Clinton <- relevel(fb$Clinton, ref = "None")

#
tw.c <- read_csv("raw_scores/semeval_clinton_train_100.csv")
colnames(tw.c) <- c("prompt_C", "completion_C")
tw.c <- tw.c %>% select(prompt_C, completion_C) %>%
    mutate(Clinton = as.factor(str_squish(completion_C)),
           wordcountClinton = stri_count_words(prompt_C))
tw.t <- read_csv("raw_scores/semeval_trump_train_100.csv") 
colnames(tw.t) <- c("prompt_T", "completion_T")
tw.t <- tw.t %>%
    mutate(Trump = as.factor(str_squish(completion_T)),
           wordcountTrump = stri_count_words(prompt_T))
levels(tw.c$Clinton)
levels(tw.c$Clinton) <- c("Against", "Favor", "None")
tw.c$Clinton <- relevel(tw.c$Clinton, ref = "None")
levels(tw.t$Trump) <- c("Against", "Favor", "None")
tw.t$Trump <- relevel(tw.t$Trump, ref = "None")

# merged
one <- one %>% bind_cols(fb)
two <- two %>% bind_cols(tw.c, tw.t)

# Regression models for FB
fbc1 <- lm(F1C ~ wordcount, data = one)
fbt1 <- lm(F1T ~ wordcount, data = one)
fbc2 <- lm(F1C ~ wordcount + Trump + Clinton, data = one)
fbt2 <- lm(F1T ~ wordcount + Trump + Clinton, data = one)
fbc3 <- lm(F1C ~ wordcount + Trump + Clinton + Trump*Clinton, data = one)
fbt3 <- lm(F1T ~ wordcount + Trump + Clinton + Trump*Clinton, data = one)

# Regression models for TW
twc1 <- lm(F1C ~ wordcountTrump + wordcountClinton, data = two)
twt1 <- lm(F1T ~ wordcountTrump + wordcountClinton, data = two)
twc2 <- lm(F1C ~ wordcountTrump + wordcountClinton + Trump + Clinton, data = two)
twt2 <- lm(F1T ~ wordcountTrump + wordcountClinton + Trump + Clinton, data = two)
twc3 <- lm(F1C ~ wordcountTrump + wordcountClinton + Trump + Clinton + Trump*Clinton, data = two)
twt3 <- lm(F1T ~ wordcountTrump + wordcountClinton + Trump + Clinton + Trump*Clinton, data = two)

# Output

modelsummary(list("C1" = fbc1, "C2" = fbc2, "C3" = fbc3,
                  "T1" = fbt1, "T2" = fbt2, "T3" = fbt3),
             stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001), 
             gof_omit = "AIC|BIC|Log.Lik.|RMSE|F",
             output = "output/FB_regressions.tex",
             fmt = fmt_decimal(digits =2))

modelsummary(list("C1" = twc1, "C2" = twc2, "C3" = twc3,
                  "T1" = twt1, "T2" = twt2, "T3" = twt3),
             stars = c("*" = 0.05, "**" = 0.01, "***" = 0.001), 
             gof_omit = "AIC|BIC|Log.Lik.|RMSE|F",
             output = "output/TW_regressions.tex",
             fmt = fmt_decimal(digits =2))

one$diff <- abs(one$F1C-one$F1T)
