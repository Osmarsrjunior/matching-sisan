# Fontes e proveniência

## Tratamento — adesão ao SISAN

- Responsável: Ministério do Desenvolvimento e Assistência Social, Família e Combate à Fome.
- Página do sistema: <https://www.gov.br/mds/pt-br/Sisan>
- Arquivo consultado: <https://www.gov.br/mds/pt-br/Sisan/lista-atualizada_2467.pdf>
- Atualização declarada no arquivo: 26 de agosto de 2026.
- Transformação: extração das tabelas do PDF, padronização do código IBGE e conversão da data da resolução em ano.
- Validação: 2.467 códigos municipais únicos; totais anuais reproduzidos em `table_01_sisan_adoptions_by_year.csv`.

## Resultado — compras da agricultura familiar no PNAE

- Responsável: Fundo Nacional de Desenvolvimento da Educação.
- Página de dados: <https://www.gov.br/fnde/pt-br/acesso-a-informacao/acoes-e-programas/programas/pnae/consultas/pnae-dados-da-agricultura-familiar>
- Arquivos arquivados: planilhas anuais de 2011 a 2022; a análise usa 2014–2022.
- Transformações: identificação programática do cabeçalho, filtragem da esfera municipal, parsing brasileiro de números, harmonização de percentuais e limite de 0–100.
- Alerta: o FNDE alterou layouts e regras de extração. A cobertura anual é reportada em `table_02_pnae_data_coverage.csv`.

## Covariáveis — Atlas do Desenvolvimento Humano

- Produtores originais: PNUD Brasil, Ipea e Fundação João Pinheiro.
- Arquivo utilizado: cópia pública versionada de `municipal.csv` no repositório <https://github.com/mauriciocramos/IDHM>, commit `f960e9725c68aec633d704e527855b37fd911c82`.
- Transformação: seleção de variáveis municipais de 2010 e renomeação documentada no dicionário.
- Alerta: a cópia de conveniência não substitui a citação institucional do Atlas; antes da submissão, confirmar a versão equivalente no portal oficial.

## Integridade

`data-raw/sources_manifest.csv` registra tamanho, SHA-256, origem e papel de cada arquivo. Para conferir localmente:

```bash
sha256sum -c data-raw/checksums.sha256
```
