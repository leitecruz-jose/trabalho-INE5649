library(readxl)
library(zoo)
library(forecast)

# Importar e converter datas
dados <- read_excel("dados_sao_paulo.xlsx")
coluna <- "Temperatura" 

mes <- match(substr(dados$Data, 1, 3), c("jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez"))
ano <- as.integer(sub(".*/", "", dados$Data))
dados$Data <- as.yearmon(sprintf("%04d-%02d", ifelse(ano <= 26, 2000 + ano, 1900 + ano), mes), "%Y-%m")

# Criar série mensal, preservando meses ausentes
datas <- seq(min(dados$Data), max(dados$Data), by = 1/12)
valores <- dados[[coluna]][match(format(datas, "%Y-%m"), format(dados$Data, "%Y-%m"))]
serie <- ts(valores, start = c(as.integer(format(min(datas), "%Y")), as.integer(format(min(datas), "%m"))), frequency = 12)

library(forecast)

# Treino e teste (últimos 12 meses)
h <- 12
treino <- na.interp(window(serie, end = time(serie)[length(serie) - h]))
teste <- as.numeric(tail(serie, h))

# Ajustar modelos e prever
previsoes <- cbind(
  SES = ses(treino, h = h)$mean, #só adicionei por que o professor falou pra usar todos os modelos que ele passou
  HOLT = holt(treino, h = h)$mean,
  HW_Aditivo = hw(treino, seasonal = "additive", h = h)$mean,
  HW_Multiplicativo = hw(treino, seasonal = "multiplicative", h = h)$mean,
  ETS = forecast(ets(treino), h = h)$mean,
  SARIMA = forecast(auto.arima(treino, seasonal = TRUE), h = h)$mean
)

# Gráfico comparativo
comparacao <- cbind(Real = teste, previsoes)
matplot(1:h, comparacao, type = "l", lty = 1, lwd = 2,
        col = 1:7, xlab = "Mês", ylab = "Valor",
        main = "Valores reais vs. previsões")
legend("topleft", colnames(comparacao),
       col = 1:7, lty = 1, lwd = 2, cex = 0.7)

# EAM de todos os modelos (menor = melhor)
EAM <- sort(colMeans(abs(previsoes - teste), na.rm = TRUE))
print(EAM)

# Melhor modelo
names(EAM)[1]
