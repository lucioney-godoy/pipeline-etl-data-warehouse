# Pipeline ETL para Data Warehouse

## Visão geral

Este projeto demonstra a construção de uma solução completa de Engenharia de Dados, desde a ingestão de arquivos até a disponibilização das informações para análise no Power BI.

O cenário representa uma empresa fictícia do setor comercial, com dados de clientes, produtos, vendedores, metas e vendas.

Todos os dados utilizados neste projeto serão fictícios e criados exclusivamente para fins de estudo e demonstração profissional.

## Objetivo

Construir um pipeline ETL capaz de:

- extrair informações de arquivos CSV;
- carregar os dados em uma área de staging;
- validar campos obrigatórios;
- identificar registros duplicados;
- separar registros válidos e inválidos;
- criar dimensões e tabela fato;
- registrar a execução das cargas;
- disponibilizar os dados para análise no Power BI.

## Problema de negócio

A empresa fictícia DataSales Comércio possui informações comerciais armazenadas em diferentes arquivos.

A ausência de uma estrutura centralizada dificulta:

- a consolidação das vendas;
- a comparação entre metas e resultados;
- a identificação dos produtos mais vendidos;
- a análise do desempenho dos vendedores;
- a validação da qualidade dos dados;
- a geração de relatórios confiáveis.

## Solução proposta

A solução utilizará uma arquitetura composta pelas seguintes etapas:

1. Recebimento dos arquivos de origem.
2. Carregamento dos dados na área de staging.
3. Aplicação das regras de qualidade.
4. Registro dos dados inválidos.
5. Carga das dimensões.
6. Carga da tabela fato.
7. Reconciliação dos dados.
8. Disponibilização para análise no Power BI.

## Tecnologias

- SQL Server
- T-SQL
- SQL Server Integration Services
- Modelagem dimensional
- Data Warehouse
- Power BI
- DAX
- Git e GitHub

## Modelo dimensional planejado

### Dimensões

- Dimensão Cliente
- Dimensão Produto
- Dimensão Vendedor
- Dimensão Calendário
- Dimensão Unidade

### Tabela fato

- Fato Vendas

## Indicadores planejados

- Receita total
- Quantidade vendida
- Ticket médio
- Total de clientes
- Vendas por período
- Vendas por produto
- Vendas por vendedor
- Vendas por unidade
- Comparação entre meta e realizado
- Percentual de atingimento da meta

## Qualidade de dados

O pipeline deverá validar:

- campos obrigatórios sem preenchimento;
- códigos de clientes inexistentes;
- códigos de produtos inexistentes;
- valores negativos;
- quantidades inválidas;
- registros duplicados;
- datas inválidas;
- registros já processados.

## Monitoramento

Serão criados controles para registrar:

- nome do processo;
- data e hora de início;
- data e hora de término;
- quantidade de registros lidos;
- quantidade de registros válidos;
- quantidade de registros inválidos;
- situação da execução;
- mensagem de erro.

## Estrutura planejada

```text
pipeline-etl-data-warehouse/
│
├── README.md
├── dados/
├── sql/
├── documentacao/
├── arquitetura/
├── etl/
└── dashboard/
