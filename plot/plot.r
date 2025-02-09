library(ggplot2)
library(readr)
library(tidyr)
library(dplyr)

rm(list = ls(all = TRUE))
print(Sys.time())

# ---- Color code ----
# color_code_scenario <- c(
#   "sv_1p5c" = "#00BFFF",
#   "sv_2c" = "#0000CD",
#   "sv_2c_rapid_xcoal" = "#aad4d4",
#   "sv_2c_buffer_decoal" = "#aad4d4",
#   "sv_cpol" = "grey"
# )

color_code_scenario <- c(
  "1p5c" = "#00BFFF",
  "2c" = "#0000CD",
  "2c_rapid_xcoal" = "#ff7885",
  "2c_buffer_decoal" = "#aa5059",
  "cpol" = "grey"
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

# ---- Load rdata ----
load("d_plot.RData")

d_sv %>% mutate(Region = gsub("R12_", "", Region)) -> d_sv
d_sv %>% mutate(Scenario = gsub("sv_", "", Scenario)) -> d_sv
d_sv$Scenario %>% factor(levels = names(color_code_scenario)) -> d_sv$Scenario

# ---- Plot Figure stranded CAP ----
d_sv -> dp
dp$CAP_stranded <- dp$CAP_stranded / 5 # period to year

plot_name <- "Stranded capacity of coal-fired power plants"
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
ggsave(paste0("Figure_CAP_stranded_bytech", ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot Figure stranded value ----
d_sv -> dp
dp$sv <- dp$sv / 5 # period to year
dp$sv <- dp$sv / 1000 # to billion

plot_name <- "Stranded value of coal-fired power plants"
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
ggsave(paste0("Figure_SV_bytech", ".png"), width = 9, height = 5, dpi = 330)

# ---- Plot Figure type ----
d_sv -> dp
dp$Scenario %>% factor(levels = names(color_code_scenario)) -> dp$Scenario
dp$CAP_stranded <- dp$CAP_stranded / 5 # period to year

dp <- dp %>%
  group_by(Scenario, Year, type) %>%
  summarise(CAP_sum = sum(CAP_stranded))

dpp <- dp %>%
  group_by(Scenario, Year) %>%
  summarise(sum = sum(CAP_sum))

plot_name <- "Stranded capacity of coal-fired power plants"

dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: all; Type: ret, idl",
    x = "(A)", y = "Unit: GW/yr"
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "1p5c", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "2c_rapid_xcoal", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "2c_buffer_decoal", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_point(
    data = dp[dp$Scenario == "1p5c", ],
    aes(y = CAP_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  geom_point(
    data = dp[dp$Scenario == "2c_rapid_xcoal", ],
    aes(y = CAP_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  geom_point(
    data = dp[dp$Scenario == "2c_buffer_decoal", ],
    aes(y = CAP_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  # theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_color_manual(values = color_code_scenario) +
  scale_shape_manual(values = c("ret" = 16, "idle" = 6)) -> p

print(p)
ggsave(paste0("Figure_SV_bytype_1", ".png"), width = 6, height = 4, dpi = 330)

# ---- Plot Figure type ----
d_sv -> dp

dp$sv <- dp$sv / 5 # period to year
dp$sv <- dp$sv / 1000 # to billion

dp <- dp %>%
  group_by(Scenario, Year, type) %>%
  summarise(sv_sum = sum(sv))

dpp <- dp %>%
  group_by(Scenario, Year) %>%
  summarise(sum = sum(sv_sum))

plot_name <- "Stranded value of coal-fired power plants"

dp %>%
  ggplot() +
  theme_bw() +
  labs(
    title = plot_name,
    subtitle = "Region: all; Type: ret, idl",
    x = "(B)", y = "Unit: Billion USD/yr"
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "1p5c", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "2c_rapid_xcoal", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_line(
    data = dpp[dpp$Scenario == "2c_buffer_decoal", ],
    aes(y = sum, x = Year, group = Scenario, color = Scenario), size = 1
  ) +
  geom_point(
    data = dp[dp$Scenario == "1p5c", ],
    aes(y = sv_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  geom_point(
    data = dp[dp$Scenario == "2c_rapid_xcoal", ],
    aes(y = sv_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  geom_point(
    data = dp[dp$Scenario == "2c_buffer_decoal", ],
    aes(y = sv_sum, x = Year, color = Scenario, shape = type), size = 3
  ) +
  # theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_color_manual(values = color_code_scenario) +
  scale_shape_manual(values = c("ret" = 16, "idle" = 6)) -> p

print(p)
ggsave(paste0("Figure_SV_bytype_2", ".png"), width = 6, height = 4, dpi = 330)
