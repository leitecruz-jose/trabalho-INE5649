# Análise e Previsão de Séries Temporais de Temperatura (INE5649 - UFSC)

Repositório dedicado ao trabalho prático da disciplina **INE5649**, com foco na análise exploratória, modelagem estatística e previsão de séries temporais para temperaturas médias mensais de diferentes capitais brasileiras.

---

## 🎯 Objetivo

Analisar o comportamento histórico do clima e comparar a acurácia de múltiplos métodos de previsão de séries temporais (clássicos e de aprendizado estatístico), avaliando o impacto da modelagem de tendência e sazonalidade nos dados entre **1961 e 2019**.

As cidades contempladas no estudo são:
* **Curitiba (PR)**
* **São Paulo (SP)**
* **Manaus (AM)**
* **Fortaleza (CE)**

---

## 🔬 Modelos Implementados

Para cada cidade, o conjunto de dados é dividido em treino e teste (últimos 12 meses), avaliando os seguintes modelos de previsão:

1. **SES (Simple Exponential Smoothing):** Suavização exponencial simples (sem tendência e sem sazonalidade).
2. **Holt:** Suavização exponencial linear com componente de tendência.
3. **Holt-Winters Aditivo:** Suavização exponencial com componentes de nível, tendência e sazonalidade aditiva.
4. **Holt-Winters Multiplicativo:** Suavização exponencial com sazonalidade proporcional ao nível.
5. **ETS (Error, Trend, Seasonal):** Modelagem de espaço de estados com seleção automática baseada em AICc.
6. **SARIMA (Seasonal ARIMA):** Modelo autorregressivo integrado de médias móveis com termos sazonais periódicos (`auto.arima`).

---

## 📊 Métricas de Avaliação

O desempenho preditivo dos modelos no horizonte de teste ($h = 12$ meses) é mensurado por meio de:
* **EAM / MAE:** Erro Absoluto Médio
* **RMSE:** Raiz do Erro Quadrático Médio
* **MAPE:** Erro Percentual Absoluto Médio
* **Viés:** Média dos resíduos observados

Além das métricas pontuais, são conduzidas análises de resíduos (`checkresiduals`) com teste de normalidade de **Shapiro-Wilk** e teste de autocorrelação (Ljung-Box).

---

## 📁 Estrutura do Repositório

```text
├── dados_curitiba.xlsx       # Dados climáticos de Curitiba (1961-2019)
├── dados_fortaleza.xlsx      # Dados climáticos de Fortaleza (1961-2019)
├── dados_manaus.xlsx         # Dados climáticos de Manaus (1961-2019)
├── dados_sao_paulo.xlsx      # Dados climáticos de São Paulo (1961-2019)
│
├── codigo_geral.R            # Script completo: AED, decomposição MSTL,
│                             # ajuste de todos os modelos, resíduos e exportação de figuras
├── cod_curitiba.R            # Script focado em modelagem e ranking de EAM para Curitiba
├── cod_sao_paulo.R           # Script focado em modelagem e ranking de EAM para São Paulo
│
├── figuras_curitiba/         # Gráficos e resultados visuais de Curitiba
├── figuras_fortaleza/        # Gráficos e resultados visuais de Fortaleza
├── figuras_manaus/           # Gráficos e resultados visuais de Manaus
├── figuras_sao_paulo/        # Gráficos e resultados visuais de São Paulo
│
├── LICENSE                   # Licença do projeto
└── README.md                 # Documentação do repositório
```

---

## 📄 Licença

Este projeto está sob a licença definida no arquivo [LICENSE](LICENSE).
