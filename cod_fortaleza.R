# pacotes
pacotes <- c("tidyverse", "forecast", "lubridate", "zoo", "gridExtra")
novos <- pacotes[!pacotes %in% rownames(installed.packages())]
if (length(novos) > 0) install.packages(novos)
invisible(lapply(pacotes, library, character.only = TRUE))

# parametros
CIDADE     <- "Fortaleza"
ARQUIVO    <- paste("dados_", tolower(CIDADE),".xlsx", sep = "")  # arquivo baixado do Kaggle
H          <- 12                       # horizonte do teste (últimos 12 meses)
PASTA_FIG  <- paste("figuras_", tolower(CIDADE), sep = "")# onde as figuras serão salvas
dir.create(PASTA_FIG, showWarnings = FALSE)

meses_pt <- c("jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez")
salvar <- function(p, nome, w = 9, h = 5)
  ggsave(file.path(PASTA_FIG, nome), p, width = w, height = h, dpi = 300)


dados <- read_excel(ARQUIVO)
mes   <- match(substr(dados$Data, 1, 3), meses_pt)
ano   <- as.integer(sub(".*/", "", dados$Data))
ano   <- ifelse(ano <= 26, 2000 + ano, 1900 + ano)
chave <- ano * 12 + mes - 1
idx   <- seq(min(chave), max(chave))
serie <- ts(dados$Temperatura[match(idx, chave)],
            start = c(min(chave) %/% 12, min(chave) %% 12 + 1), frequency = 12)

serie_c <- na.interp(serie)
n       <- length(serie_c)

datas <- seq(as.Date(sprintf("%d-%02d-01", start(serie_c)[1], start(serie_c)[2])),
             by = "month", length.out = n)
df <- data.frame(
  Data = datas,
  Ano  = year(datas),
  Mes  = factor(month(datas), 1:12, meses_pt),
  Temp = as.numeric(serie_c)
)
df$MM12 <- as.numeric(ma(serie_c, order = 12))   # média móvel centrada de 12 meses


# 1. ANÁLISE EXPLORATÓRIA
# 1.1 Série, média móvel de 12 meses e reta de tendência
p1 <- ggplot(df, aes(Data, Temp)) +
  geom_line(color = "grey55", linewidth = 0.4) +
  geom_line(aes(y = MM12, color = "Média móvel 12 meses"), linewidth = 1, na.rm = TRUE) +
  geom_smooth(aes(color = "Tendência linear"), method = "lm", se = FALSE,
              linetype = "dashed", linewidth = 0.9) +
  scale_color_manual(name = NULL, values = c("Média móvel 12 meses" = "red",
                                             "Tendência linear" = "blue")) +
  labs(x = "Ano", y = "Temperatura média (°C)",
       title = "Temperatura média mensal") + 
  theme_bw() + theme(legend.position = "bottom")
print(p1); salvar(p1, "01_serie.png")

# 1.2 Gráfico sazonal
p2 <- ggseasonplot(serie_c, continuous = TRUE, year.labels = FALSE) +
  scale_color_gradient(low = "#56B1F7", high = "#132B43", name = "Ano") +
  labs(title = "Gráfico sazonal", y = "°C") + theme_bw()
print(p2); salvar(p2, "02_sazonal.png");

# 1.3 Mapa de calor ano x mês
p3 <- ggplot(df, aes(Mes, Ano, fill = Temp)) +
  geom_tile() +
  scale_fill_viridis_c(option = "inferno", direction = -1, name = "°C") +
  scale_y_reverse() +
  labs(x = "Mês", y = "Ano", title = "Mapa de calor da temperatura (ano x mês)") +
  theme_bw()
print(p3); salvar(p3, "03_heatmap.png", w = 7, h = 8)

# 1.4 Anomalias
df$Anom <- df$Temp - ave(df$Temp, df$Mes)
df$Anom12 <- as.numeric(ma(ts(df$Anom, start = start(serie_c), frequency = 12), order = 12))
p4 <- ggplot(df, aes(Data, Anom)) +
  geom_col(aes(fill = Anom > 0), show.legend = FALSE) +
  scale_fill_manual(values = c("TRUE" = "firebrick", "FALSE" = "steelblue")) +
  geom_line(aes(y = Anom12), color = "black", linewidth = 0.8, na.rm = TRUE) +
  labs(x = "Ano", y = "Anomalia (°C)",
       title = "Anomalias mensais",
       subtitle = "Linha preta: média móvel de 12 meses") + theme_bw()
print(p4); salvar(p4, "04_anomalias.png")

# 1.5 Decomposição (MSTL) e força da tendência e da sazonalidade
dec <- mstl(serie_c)
p5 <- autoplot(dec) + labs(title = "Decomposição MSTL") + theme_bw()
print(p5); salvar(p5, "05_decomposicao.png", w = 9, h = 7)

# 2. TREINO E TESTE
treino    <- ts(serie_c[1:(n - H)], start = start(serie_c), frequency = 12)
teste_num <- as.numeric(serie_c[(n - H + 1):n])
datas_teste <- tail(datas, H)

# 3. MODELOS
# Dicionário de modelos: cada um recebe (série, horizonte) e devolve um objeto 'forecast'
modelos <- list(
  "SES"                 = function(y, h) ses(y, h = h),
  "Holt"                = function(y, h) holt(y, h = h),
  "HW aditivo"          = function(y, h) hw(y, seasonal = "additive", h = h),
  "HW multiplicativo"   = function(y, h) hw(y, seasonal = "multiplicative", h = h),
  "ETS (automático)"    = function(y, h) forecast(ets(y), h = h),
  "SARIMA (auto.arima)" = function(y, h) forecast(auto.arima(y, seasonal = TRUE), h = h)
)

# 4. ANÁLISE DE RESÍDUOS
fc_treino <- list(
  "SES"                      = modelos[["SES"]](treino, H),
  "Holt"                     = modelos[["Holt"]](treino, H),
  "HW aditivo"               = modelos[["HW aditivo"]](treino, H),
  "HW multiplicativo"        = modelos[["HW multiplicativo"]](treino, H),
  "ETS (automático)"         = modelos[["ETS (automático)"]](treino, H),
  "SARIMA (auto.arima)"      = modelos[["SARIMA (auto.arima)"]](treino, H)
)
for (nm in names(fc_treino)) {
  checkresiduals(fc_treino[[nm]])
  arq <- paste0("6_residuos_", gsub("[^A-Za-z]", "", nm), ".png")
  
  png(file.path(PASTA_FIG, arq), width = 2400, height = 1500, res = 300)
  
  invisible(checkresiduals(fc_treino[[nm]])); dev.off()
  r <- as.numeric(residuals(fc_treino[[nm]]))
  r <- r[!is.na(r)]
  print(shapiro.test(r))
}

# 5. ACURÁCIA NO TESTE (EAM) E GRÁFICOS
prev <- lapply(names(modelos), function(nm) {
  tryCatch(as.numeric(modelos[[nm]](treino, H)$mean), error = function(e) rep(NA_real_, H))
})
names(prev) <- names(modelos)

metricas <- function(real, p) c(EAM  = mean(abs(real - p)),
                                RMSE = sqrt(mean((real - p)^2)),
                                MAPE = mean(abs((real - p) / real)) * 100,
                                Vies = mean(real - p))
tab <- as.data.frame(t(sapply(prev, function(p) metricas(teste_num, p))))
tab$Modelo <- rownames(tab)
tab <- tab[order(tab$EAM), c("Modelo", "EAM", "RMSE", "MAPE", "Vies")]
rownames(tab) <- NULL
print(tab, digits = 3)
melhor <- tab$Modelo[1]

# 5.1 Valores reais x previsões (todos os modelos)
mat <- do.call(cbind, prev)
dfp <- cbind(data.frame(Data = datas_teste, Real = teste_num), as.data.frame(mat))
dfl <- pivot_longer(dfp, -c(Data, Real), names_to = "Modelo", values_to = "Previsao")

p7 <- ggplot() +
  geom_line(data = dfl, aes(Data, Previsao, color = Modelo), linewidth = 0.6, alpha = 0.8) +
  geom_line(data = dfp, aes(Data, Real), color = "black", linewidth = 1.2) +
  labs(x = "Data", y = "Temperatura (°C)",
       title = "Teste: valores reais (preto) x previsões de todos os modelos") +
  theme_bw() + theme(legend.position = "bottom", legend.text = element_text(size = 7))
print(p7); salvar(p7, "7_teste_todos.png", w = 10, h = 6)

# 5.2 Um painel por modelo
p8 <- ggplot(dfl, aes(Data)) +
  geom_line(aes(y = Real), color = "black", linewidth = 1) +
  geom_line(aes(y = Previsao), color = "red", linewidth = 0.8) +
  facet_wrap(~ Modelo, ncol = 3) +
  labs(x = NULL, y = "°C", title = "Real (preto) x previsão (vermelho), por modelo") +
  theme_bw() + theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6))
print(p8); salvar(p8, "8_teste_paineis.png", w = 11, h = 8)

# 5.3 Ranking de EAM
p9 <- ggplot(tab, aes(reorder(Modelo, -EAM), EAM, fill = Modelo == melhor)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = round(EAM, 3)), hjust = -0.1, size = 3) +
  scale_fill_manual(values = c("TRUE" = "firebrick", "FALSE" = "grey60")) +
  coord_flip(ylim = c(0, max(tab$EAM) * 1.12)) +
  labs(x = NULL, y = "EAM (°C)", title = "Erro absoluto médio no teste") + theme_bw()
print(p9); salvar(p9, "9_ranking_eam.png", w = 9, h = 6)

# 6. PREVISÃO FINAL
# Previsão final com o melhor modelo
fc_final <- modelos[[melhor]](serie_c, H)

p10 <- autoplot(fc_final, include = 10 * 12) +
  labs(x = "Ano", y = "Temperatura média (°C)",
       title = paste("Previsão de", H, "meses:", melhor)) + theme_bw()
print(p10); salvar(p10, "10_previsao_final.png")