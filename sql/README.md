# 🗄️ Scripts SQL — Microsoft SQL Server

Esta pasta contém os scripts T-SQL utilizados na construção do projeto **Pipeline ETL para Data Warehouse**.

Todo o projeto foi desenvolvido exclusivamente para **Microsoft SQL Server**, com execução prevista para o **SQL Server Management Studio — SSMS**.

Os scripts são responsáveis pela criação do banco de dados, organização dos schemas, preparação das tabelas de staging, implementação do modelo dimensional, controle das execuções, tratamento de registros inválidos e validação das cargas.

---

## Tecnologias da camada SQL

- Microsoft SQL Server
- T-SQL
- SQL Server Management Studio
- SQL Server Integration Services
- Modelagem dimensional
- Data Warehouse

## Compatibilidade

Os scripts deste projeto foram desenvolvidos para Microsoft SQL Server.

Características utilizadas:

- separação de comandos com `GO`;
- schemas personalizados;
- colunas `IDENTITY`;
- tipos `NVARCHAR`, `DATETIME2` e `DECIMAL`;
- tratamento de erros com `TRY...CATCH`;
- funções e procedures em T-SQL;
- consultas às views de sistema `sys.schemas`, `sys.tables` e `sys.columns`.

Os scripts não foram preparados para execução direta em PostgreSQL, Oracle, MySQL, porém, podem ser facilmente convertidos.


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
