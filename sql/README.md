# 🗄️ Scripts SQL — DataSalesDW

Esta pasta contém os scripts SQL utilizados na construção do projeto **Pipeline ETL para Data Warehouse**.

Os arquivos são responsáveis pela criação do banco de dados, organização dos schemas, preparação das tabelas de staging, implementação do modelo dimensional, controle das execuções, tratamento de registros inválidos e validação das cargas.

---

## 🎯 Objetivo

Construir a camada de banco de dados necessária para suportar o seguinte fluxo:

```text
Arquivos CSV
     ↓
Tabelas de Staging
     ↓
Validação e Qualidade
     ↓
Registros válidos e inválidos
     ↓
Dimensões e Tabelas Fato
     ↓
Data Warehouse
     ↓
Power BI
