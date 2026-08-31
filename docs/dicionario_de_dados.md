# Dicionário de dados

## `data/processed/municipal_panel.csv`

| Variável | Descrição | Unidade/origem |
|---|---|---|
| `code_muni` | Código municipal IBGE com 7 dígitos | Identificador |
| `uf` | Unidade federativa | Atlas/FNDE |
| `municipality` | Nome do município | Atlas |
| `year` | Ano do resultado | 2014–2022 |
| `adoption_year` | Ano da resolução de adesão ao SISAN | MDS |
| `population_2010` | População municipal | Atlas 2010 |
| `population_class` | Estrato populacional do matching | Derivada |
| `log_population_2010` | Log natural da população | Derivada |
| `rural_share_2010` | População rural | % |
| `extreme_poverty_pct_2010` | Pessoas em extrema pobreza | % |
| `vulnerable_poverty_pct_2010` | Pessoas vulneráveis à pobreza | % |
| `income_pc_2010` | Renda per capita | R$ de referência do Atlas |
| `agricultural_employment_pct_2010` | Ocupados no setor agropecuário | % |
| `adult_illiteracy_pct_2010` | Analfabetismo adulto | % |
| `public_sector_employment_pct_2010` | Ocupados no setor público | % |
| `idhm_2010` | Índice de Desenvolvimento Humano Municipal | 0–1 |
| `value_transferred` | Recursos federais transferidos | R$ correntes |
| `value_family_farming` | Aquisições declaradas da agricultura familiar | R$ correntes |
| `af_share_observed` | Percentual publicado/calculado, limitado a 0–100 | % |
| `pnae_record_observed` | Município presente no extrato anual válido | 0/1 |
| `af_share` | Resultado primário anual; ausência codificada como zero | % |
| `compliant_30` | Alcançou o mínimo histórico de 30% | 0/1 |
| `treated_currently` | Já havia aderido naquele ano | 0/1 |

## `data/processed/matched_cohort_sample.csv`

Além das covariáveis anteriores, contém:

| Variável | Descrição |
|---|---|
| `cohort` | Ano que define o conjunto de risco |
| `treated` | 1 para aderente da coorte; 0 para controle |
| `pre_2`, `pre_1` | Resultado em `t−2` e `t−1` |
| `pre_average` | Média dos dois anos anteriores |
| `pre_trend` | Diferença `pre_1 − pre_2` |
| `post_average` | Média do resultado em `t+1:t+3` |
| `post_compliance` | Frequência de cumprimento em `t+1:t+3` |
| `distance` | Escore de propensão estimado pelo MatchIt |
| `weights` | Peso analítico do matching |
| `subclass` | Identificador do conjunto pareado dentro da coorte |

Valores ausentes são gravados como campos vazios. Os tipos e nomes são testados pelo pipeline.
