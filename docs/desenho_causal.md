# Desenho causal

## Intuição em poucas palavras

**Matching** procura montar um grupo de comparação com municípios observavelmente parecidos aos aderentes antes da política. Ele imita a etapa de desenho de um experimento, mas não randomiza nem elimina diferenças não observadas.

O artigo usa **matching por conjuntos de risco** porque os municípios aderem em anos distintos. Em cada ano, compara quem aderiu naquele momento com quem ainda estava elegível e continuou sem adesão durante todo o seguimento.

## Protocolo do estudo

| Componente | Definição operacional |
|---|---|
| População-alvo | Municípios brasileiros no universo do Atlas 2010 |
| Tratamento | Resolução de adesão municipal ao SISAN |
| Coortes | 2016–2019 |
| Pré-tratamento | `t−2` e `t−1` |
| Seguimento | `t+1`, `t+2`, `t+3` |
| Controles | Nunca aderentes ou adesão posterior a `t+3` |
| Exato | UF e classe populacional |
| Escore | Logit com estrutura municipal e trajetória prévia do PNAE |
| Distância | Mahalanobis dentro de caliper do escore |
| Razão | 1 aderente : 1 controle, sem reposição dentro da coorte |
| Estimando | ATT no suporte comum |
| Resultado primário | Média da participação da agricultura familiar em `t+1:t+3` |
| Resultado secundário | Frequência de cumprimento de 30% em `t+1:t+3` |

## Sequência analítica

1. Arquivar as fontes e padronizar códigos municipais.
2. Construir painel município-ano de 2014–2022.
3. Para cada coorte, excluir controles tratados durante o seguimento.
4. Estimar o escore sem usar resultados pós-tratamento.
5. Parear e verificar diferenças padronizadas.
6. Empilhar as coortes e estimar o ATT com efeitos fixos de coorte.
7. Repetir o desenho sob decisões alternativas.

## Hipóteses necessárias

- **Independência condicional:** dadas as covariáveis, não resta determinante não observado da adesão e do resultado potencial.
- **Sobreposição:** há controles comparáveis para os aderentes incluídos.
- **Não antecipação:** resultados anteriores não foram causados por preparação para a adesão.
- **Não interferência:** a adesão de um município não muda substancialmente o resultado de outro.
- **Mensuração comparável:** mudanças nas planilhas não afetam diferencialmente aderentes e controles.

O diagnóstico de equilíbrio informa se o matching funcionou para variáveis observadas; ele não prova a primeira hipótese.

## Por que não chamar de diferenças-em-diferenças

O gráfico de tempo relativo mostra diferenças pareadas em cada ano, mas o estimando principal é uma comparação pós-pareamento ajustada pelo desempenho anterior. Não há modelo DiD com interação tratamento × período nem uma identificação baseada formalmente em tendências paralelas. Isso evita confundir o método deste artigo com o artigo anterior de DiD.
