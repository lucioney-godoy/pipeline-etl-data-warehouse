# 🗄️ Camada SQL — DataSalesDW

Esta pasta contém os scripts T-SQL responsáveis pela construção da camada de banco de dados do projeto **Pipeline ETL para Data Warehouse**.

A solução utiliza **Microsoft SQL Server** como plataforma principal e contempla a criação do banco de dados, organização dos schemas, tabelas de staging, controles de execução, tratamento de registros inválidos, modelo dimensional e consultas analíticas.

Os scripts foram organizados em uma sequência lógica de execução e documentados para demonstrar práticas utilizadas em projetos corporativos de Engenharia de Dados, ETL e Business Intelligence.

---

## Tecnologias da camada SQL

- Microsoft SQL Server
- T-SQL
- SQL Server Management Studio
- SQL Server Integration Services
- Modelagem dimensional
- Data Warehouse

## 🛠️ Padrão tecnológico

A camada de banco de dados deste projeto utiliza **Microsoft SQL Server** e **T-SQL**, seguindo padrões aplicados em ambientes corporativos de Engenharia de Dados e Business Intelligence.

### Recursos utilizados

- Microsoft SQL Server;
- SQL Server Management Studio — SSMS;
- SQL Server Integration Services — SSIS;
- linguagem T-SQL;
- schemas para organização das camadas;
- procedures, views e functions;
- colunas `IDENTITY`;
- tipos `NVARCHAR`, `DATE`, `DATETIME2` e `DECIMAL`;
- tratamento de erros com `TRY...CATCH`;
- transações para garantir consistência;
- tabelas de controle, auditoria e rejeição;
- consultas às views de sistema do SQL Server.

A solução foi estruturada com foco em organização, rastreabilidade, qualidade dos dados, reexecução segura e facilidade de manutenção.

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
