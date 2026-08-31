# Checklist de revisão manual e submissão

## Autoria e transparência

- [ ] Confirmar nome de publicação, afiliação, ORCID e autor correspondente.
- [ ] Completar financiamento, conflitos de interesse e contribuições CRediT.
- [ ] Inserir URL e DOI do repositório depois de publicar no GitHub/Zenodo.
- [ ] Definir se os dados brutos do FNDE podem ser redistribuídos no suplemento da revista ou apenas referenciados.
- [ ] Informar no texto qualquer revisão manual feita nas datas de adesão.

## Validade substantiva

- [ ] Verificar com especialista do SISAN se a lista de 2026 mantém municípios suspensos ou somente adesões ativas.
- [ ] Conferir uma amostra aleatória de códigos, datas e resoluções diretamente no PDF.
- [ ] Confirmar se “ano da resolução” é a melhor data de início ou se há data de publicação/efeito distinta.
- [ ] Avaliar inclusão de indicador sobre existência e funcionamento do plano municipal, se uma base histórica for localizada.
- [ ] Discutir explicitamente que o PNAE é resultado correlato, não componente exclusivo do SISAN.

## Validade estatística

- [ ] Não apresentar `p = 0,030` como confirmação isolada: a robustez é fraca.
- [ ] Manter a análise de casos completos próxima ao resultado principal.
- [ ] Considerar uma análise de sensibilidade a confundimento não observado após revisão de pares.
- [ ] Conferir os pares da coorte de 2019 e considerar apêndice excluindo essa coorte.
- [ ] Reportar o número de aderentes descartados por falta de suporte em cada coorte.
- [ ] Preservar o diagnóstico de diferenças padronizadas, não testes de significância de balanceamento.

## Redação e periódico

- [ ] Adequar resumo, extensão, estilo de referências e número de figuras ao periódico escolhido.
- [ ] Decidir se o título deve enfatizar “coordenação”, “capacidade estatal” ou “institucionalização simbólica”.
- [ ] Enxugar a seção metodológica no corpo e transferir detalhes para o apêndice se houver limite de palavras.
- [ ] Atualizar a literatura publicada entre agosto de 2026 e a data da submissão.
- [ ] Fazer revisão de linguagem acadêmica e conferir todas as referências/DOIs.

## Reprodutibilidade

- [ ] Executar `Rscript run.R` em uma instalação limpa.
- [ ] Executar todos os testes.
- [ ] Confirmar que tabelas e números do DOCX coincidem com os CSVs.
- [ ] Criar uma release do GitHub e arquivá-la no Zenodo.
- [ ] Registrar a versão final do R e dos pacotes.
