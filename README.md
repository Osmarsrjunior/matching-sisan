# Coordenação sem recursos?

Suplemento reproduzível do artigo **“Coordenação sem recursos? Efeitos da adesão municipal ao SISAN sobre as compras da agricultura familiar no PNAE”**.

O projeto avalia as coortes municipais de adesão ao Sistema Nacional de Segurança Alimentar e Nutricional (SISAN) de 2016 a 2019. Para cada coorte, municípios aderentes são pareados a municípios do mesmo estado e estrato populacional que permaneceram sem tratamento durante os três anos de seguimento. O resultado principal é a participação dos recursos do Programa Nacional de Alimentação Escolar (PNAE) destinada à agricultura familiar.

## Resultado em uma frase

O matching principal estima aumento ajustado de **3,09 pontos percentuais** nas compras da agricultura familiar (IC95%: 0,30; 5,88), mas o efeito diminui e se torna compatível com zero em várias especificações alternativas. O artigo interpreta a evidência como ganho possível, modesto e frágil — não como prova de que a adesão formal, sozinha, transforma a implementação.

## Reprodução rápida

Requisitos: R 4.3 ou superior e acesso local aos arquivos incluídos neste repositório.

```r
source("environment/install_packages.R")
```

Depois, no diretório raiz do projeto:

```bash
Rscript run.R
```

O comando reconstrói o painel, refaz todos os pareamentos e grava as tabelas e figuras em `outputs/`. A execução de referência levou menos de dois minutos em R 4.5.3; o tempo depende da máquina.

Para executar os testes:

```bash
Rscript -e 'testthat::test_dir("tests/testthat")'
```

## Desenho

- Tratamento: ano da resolução oficial de adesão municipal ao SISAN.
- Coortes avaliadas: 2016, 2017, 2018 e 2019.
- Conjunto de risco: aderentes da coorte e municípios nunca tratados ou tratados somente depois de `coorte + 3`.
- Matching principal: 1:1, sem reposição, exato por UF e classe populacional.
- Distância: Mahalanobis nas principais covariáveis, dentro de caliper de 0,20 desvio-padrão do escore de propensão.
- Resultado principal: média do percentual do PNAE destinado à agricultura familiar em `t+1`, `t+2` e `t+3`.
- Resultado secundário: proporção dos três anos que atingem o mínimo legal histórico de 30%.
- Estimando: ATT entre aderentes no suporte comum.
- Inferência: efeitos fixos de coorte e erros-padrão agrupados por município.

Detalhes formais e hipóteses de identificação estão em [`docs/desenho_causal.md`](docs/desenho_causal.md).

## Estrutura

```text
matching-sisan/
├── R/                         # importação, painel, matching e estimação
├── artifacts/                 # versão DOCX pronta para revisão
├── data-raw/                  # arquivos-fonte arquivados e manifesto
├── data/processed/            # painel e amostra pareada
├── docs/                      # desenho, proveniência e checklist editorial
├── environment/               # instalação e registro do ambiente R
├── manuscript/                # manuscrito-fonte e construtor do DOCX
├── outputs/figures/           # figuras reproduzidas por run.R
├── outputs/tables/            # resultados numéricos em CSV
├── tests/testthat/            # testes de parsing e invariantes substantivos
├── config.yml                 # decisões centrais do desenho
└── run.R                      # pipeline completo
```

## Decisões que exigem atenção

1. **Registro ausente no FNDE.** A análise principal interpreta ausência do extrato anual como zero compra registrada. A especificação de casos completos é obrigatória para a interpretação e está em `table_08_robustness.csv`.
2. **Cadastro do tratamento.** A cronologia foi derivada da lista oficial disponível em 26/08/2026. Eventuais suspensões ou exclusões históricas não identificáveis no arquivo podem gerar erro de classificação.
3. **Pandemia.** A coorte de 2019 tem seguimento em 2020–2022 e somente 15 aderentes pareados. O choque comum é absorvido pela comparação contemporânea, mas impactos locais heterogêneos permanecem possíveis.
4. **Validade externa.** Os resultados não devem ser extrapolados automaticamente à expansão de 2024–2026.
5. **Regra do PNAE.** O limiar de 30% é correto para 2014–2022. A partir de 2026, o mínimo nacional passou a 45%.

## Para publicar no GitHub

Antes do primeiro commit, substitua os campos entre colchetes no manuscrito e revise a declaração de autoria. Em seguida:

```bash
git init
git add .
git commit -m "Add SISAN matching replication package"
```

Não altere manualmente os CSVs em `outputs/`; ajuste o código e execute `Rscript run.R` novamente.

## Licença e citação

O código é distribuído sob licença MIT. Os dados preservam os termos e a atribuição de suas fontes originais. Use `CITATION.cff` como ponto de partida e atualize afiliação, DOI e versão quando o repositório for publicado.

