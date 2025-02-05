library(ggplot2)
library(readr)
library(tidyr)
library(dplyr)

rm(list = ls(all = TRUE))
print(Sys.time())

# ---- Color code ----
color_code_scenario <- c(
  "sv_1p5c" = "#00BFFF",
  "sv_2c" = "#0000CD",
  "sv_2c_rapid_xcoal" = "#aad4d4",
  "sv_2c_buffer_decoal" = "#aad4d4",
  "sv_cpol" = "grey"
)

color_code_coal <- c(
  "igcc_ccs" = "#ffcd5e",
  "coal_adv_ccs" = "#ec8433",
  "coal_adv_rccs" = "#faf700",
  "igcc" = "#9a6746",
  "coal_adv" = "#ac2000",
  "coal_ppl" = "#6c2c17",
  "coal_ppl_u" = "#170605",
  "coal_adv_cfNH3" = "#bcfffe",
  "coal_ppl_cfNH3" = "#89ffcb",
  "coal_ppl_u_cfNH3" = "#72d4a9",
  "coal_adv_cfbio" = "#d4e6a6",
  "coal_ppl_cfbio" = "#a2bb87",
  "coal_ppl_u_cfbio" = "#7d9169"
)

tech_parent <- c(
  "igcc_ccs",
  "coal_adv_ccs",
  "igcc",
  "coal_adv",
  "coal_ppl",
  "coal_ppl_u"
)

# ---- Load csv ----
df <- read_csv("d_prep.csv")

# Show column names
colnames(df)[colnames(df) == "sc"] <- "Scenario"
colnames(df)[colnames(df) == "nl"] <- "Region"
colnames(df)[colnames(df) == "t"] <- "Technology"
colnames(df)[colnames(df) == "yv"] <- "Year_start"
colnames(df)[colnames(df) == "ya"] <- "Year"
colnames(df)[colnames(df) == "m"] <- "Mode"
colnames(df)[colnames(df) == "ACT"] <- "ACT"
colnames(df)[colnames(df) == "CAP"] <- "CAP"
colnames(df)[colnames(df) == "inv_cost"] <- "inv_cost"

# Remove additional modes to avoid double-counting parent technologies
df %>% filter(!((df$Mode == "M2") & (df$Technology %in% tech_parent))) -> df
df %>% filter(!((df$Mode == "M3") & (df$Technology %in% tech_parent))) -> df
df %>% filter(!((df$Mode == "M4") & (df$Technology %in% tech_parent))) -> df

# ---- Calculate CAP_ret ----
df$prox <- df$Year
df$value <- df$CAP
t <- df %>% select(
  "Scenario",
  "Region",
  "Technology",
  "Mode",
  "Year_start",
  "prox",
  "value"
)
t$Year_prox_act <- t$prox
t$prox <- t$prox - 5

d <- right_join(t, df, by = c(
  "Scenario",
  "Region",
  "Technology",
  "Mode",
  "Year_start",
  "prox"
))

d$CAP_retire <- ifelse(
  is.na(d$value.x) | is.na(d$value.y), NA, d$value.x - d$value.y
)
d$life_retire <- ifelse(
  is.na(d$Year) | d$Year_start == "hist" | is.na(d$Year_start),
  NA, d$Year - as.numeric(d$Year_start) + 5
)
d$life_actual <- ifelse(
  is.na(d$Year) | d$Year_start == "hist" | is.na(d$Year_start),
  NA, d$Year - as.numeric(d$Year_start)
)
d$life_expected <- 30

d %>% filter((d$CAP_retire < 0) & (d$Year >= 2010)) -> d_ret
d_ret$type <- "ret"

# ---- Plot CAP_ret ----
d_ret$Year <- d_ret$Year_prox_act
d_ret$CAP_stranded <- d_ret$CAP_retire
d_ret -> dp

dp$CAP_retire <- dp$CAP_retire / 5

plot_name <- "CAP_ret"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GW/yr"
  ) +
  geom_bar(
    data = dp, aes(y = CAP_retire, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot CAP_idle ----
d %>% filter((d$CAP_retire >= 0) &
  (d$Year_start != "hist") &
  (d$CAP != 0)) -> d_idle
d_idle <- d_idle %>%
  mutate(idle_share = ifelse(
    (d_idle$ACT / d_idle$CAP - 0.85) > 0, 0,
    d_idle$ACT / d_idle$CAP - 0.85
  )) # The max capacity factor = 0.85

d_idle$CAP_idling <- d_idle$CAP * d_idle$idle_share
d_idle$CAP_stranded <- d_idle$CAP_idling
d_idle$type <- "idle"
d_idle -> dp

dp$CAP_idling <- dp$CAP_idling / 5

plot_name <- "CAP_idl"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GW/yr"
  ) +
  geom_bar(
    data = dp, aes(y = CAP_idling, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot CAP_stranded ----
set <- c(
  "Scenario",
  "Region",
  "Technology",
  "Mode",
  "Year_start",
  "Year",
  "ACT",
  "type",
  "CAP",
  "CAP_stranded",
  "life_actual",
  "life_retire",
  "life_expected",
  "inv_cost"
)

t1 <- d_idle %>% select(set)
t2 <- d_ret %>% select(set)

d_sv <- rbind(t1, t2)
d_sv -> dp
dp$CAP_stranded <- dp$CAP_stranded / 5

plot_name <- "CAP_stranded"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GW/yr"
  ) +
  geom_bar(
    data = dp, aes(y = CAP_stranded, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

# ---- Calculate SV ----
d_sv <- d_sv %>%
  mutate(sv_share = ifelse((life_expected - life_retire) < 0, 1,
    (life_expected - life_retire) / life_expected
  ))
d_sv <- d_sv %>%
  mutate(idle_share = ifelse(type == "ret", 1,
    -(ACT / CAP - 0.85)
  ))
d_sv <- d_sv %>% # adjust investment cost for addon technologies
  mutate(Technology_parent = case_when(
    Technology == "coal_adv_cfNH3" ~ "coal_adv",
    Technology == "coal_ppl_cfNH3" ~ "coal_ppl",
    Technology == "coal_ppl_u_cfNH3" ~ "coal_ppl_u",
    Technology == "coal_adv_cfbio" ~ "coal_adv",
    Technology == "coal_ppl_cfbio" ~ "coal_ppl",
    Technology == "coal_ppl_u_cfbio" ~ "coal_ppl_u",
    Technology == "coal_adv_rccs" ~ "coal_adv",
    TRUE ~ Technology
  ))
set <- c(
  "Scenario",
  "Region",
  "Technology",
  "Mode",
  "Year_start",
  "Year",
  "Technology_parent",
  "inv_cost"
)
d_sv <- d_sv %>%
  left_join(d_sv %>% select(set),
    by = c(
      "Technology_parent" = "Technology",
      "Year_start" = "Year_start",
      "Year" = "Year",
      "Scenario" = "Scenario",
      "Region" = "Region",
      "Mode" = "Mode"
    ),
    suffix = c("", "_add")
  ) %>%
  mutate(inv_cost_all = case_when(
    Technology == "coal_ppl_cfNH3" ~ inv_cost + inv_cost_add,
    Technology == "coal_adv_cfNH3" ~ inv_cost + inv_cost_add,
    Technology == "coal_ppl_u_cfNH3" ~ inv_cost + inv_cost_add,
    Technology == "coal_ppl_cfbio" ~ inv_cost + inv_cost_add,
    Technology == "coal_adv_cfbio" ~ inv_cost + inv_cost_add,
    Technology == "coal_ppl_u_cfbio" ~ inv_cost + inv_cost_add,
    Technology == "coal_adv_rccs" ~ inv_cost + inv_cost_add,
    TRUE ~ inv_cost
  )) %>%
  select(-ends_with("_add"))

d_sv$sv <- d_sv$sv_share * d_sv$inv_cost * d_sv$CAP_stranded * d_sv$idle_share

# ---- Plot SV ----
d_sv -> dp
dp$sv <- dp$sv / 5
dp$sv <- dp$sv / 1000

plot_name <- "SV_tech"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: Billion USD/yr"
  ) +
  geom_bar(
    data = dp, aes(y = sv, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

plot_name <- "SV_type"
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: Billion USD/yr"
  ) +
  geom_bar(
    data = dp, aes(y = sv, x = Year, fill = type),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot CAP ----
d -> dp

dp %>% filter(dp$Year %in% c(
  "2010", "2015", "2020", "2025", "2030", "2035", "2040",
  "2045", "2050", "2055", "2060", "2070", "2080"
)) -> dp

plot_name <- "CAP"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GW"
  ) +
  geom_bar(
    data = dp, aes(y = CAP, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot ACT ----
d -> dp

dp %>% filter(dp$Year %in% c(
  "2010", "2015", "2020", "2025", "2030", "2035", "2040",
  "2045", "2050", "2055", "2060", "2070", "2080"
)) -> dp

plot_name <- "ACT"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GWa"
  ) +
  geom_bar(
    data = dp, aes(y = ACT, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, "_gas_coal.png"), width = 9, height = 5, dpi = 330)

d %>% filter(d$Technology %in% names(color_code_coal)) -> dp

dp %>% filter(dp$Year %in% c(
  "2010", "2015", "2020", "2025", "2030", "2035", "2040",
  "2045", "2050", "2055", "2060", "2070", "2080"
)) -> dp

plot_name <- "ACT"
dp$Technology %>% factor(levels = names(color_code_coal)) -> dp$Technology
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: SAS, CHN, RCPA, PAS; Scenario: all",
    x = "", y = "Unit: GWa"
  ) +
  geom_bar(
    data = dp, aes(y = ACT, x = Year, fill = Technology),
    stat = "identity", position = "stack", width = 4
  ) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  facet_grid(vars(Region), vars(Scenario), scales = "free_y") +
  scale_fill_manual(values = color_code_coal) -> p

print(p)
ggsave(paste0(plot_name, "_coal.png"), width = 9, height = 5, dpi = 330)
