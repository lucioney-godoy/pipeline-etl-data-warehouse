/*
===============================================================================
Projeto  : Pipeline ETL para Data Warehouse
Arquivo  : 01_criar_banco_e_schemas.sql
Autor    : Lucioney Godoy
Objetivo : Criar o banco de dados e os schemas utilizados pelo projeto.
SGBD     : Microsoft SQL Server
===============================================================================
*/

USE master;
GO

IF DB_ID(N'DataSalesDW') IS NULL
BEGIN
    PRINT N'Criando o banco de dados DataSalesDW...';

    CREATE DATABASE DataSalesDW;
END
ELSE
BEGIN
    PRINT N'O banco de dados DataSalesDW já existe.';
END;
GO

USE DataSalesDW;
GO

/*
Schema staging:
Receberá os dados brutos provenientes dos arquivos CSV.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'staging'
)
BEGIN
    EXEC(N'CREATE SCHEMA staging AUTHORIZATION dbo;');
    PRINT N'Schema staging criado.';
END
ELSE
BEGIN
    PRINT N'O schema staging já existe.';
END;
GO

/*
Schema dw:
Armazenará as dimensões e tabelas fato do Data Warehouse.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'dw'
)
BEGIN
    EXEC(N'CREATE SCHEMA dw AUTHORIZATION dbo;');
    PRINT N'Schema dw criado.';
END
ELSE
BEGIN
    PRINT N'O schema dw já existe.';
END;
GO

/*
Schema controle:
Armazenará logs de execução, controles de carga e reconciliações.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'controle'
)
BEGIN
    EXEC(N'CREATE SCHEMA controle AUTHORIZATION dbo;');
    PRINT N'Schema controle criado.';
END
ELSE
BEGIN
    PRINT N'O schema controle já existe.';
END;
GO

/*
Schema rejeicao:
Armazenará registros rejeitados ou considerados inválidos.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'rejeicao'
)
BEGIN
    EXEC(N'CREATE SCHEMA rejeicao AUTHORIZATION dbo;');
    PRINT N'Schema rejeicao criado.';
END
ELSE
BEGIN
    PRINT N'O schema rejeicao já existe.';
END;
GO

/*
Schema auditoria:
Armazenará informações complementares de rastreabilidade.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'auditoria'
)
BEGIN
    EXEC(N'CREATE SCHEMA auditoria AUTHORIZATION dbo;');
    PRINT N'Schema auditoria criado.';
END
ELSE
BEGIN
    PRINT N'O schema auditoria já existe.';
END;
GO

PRINT N'Estrutura inicial criada com sucesso.';
GO

/*
Consulta de conferência.
*/
SELECT
    name AS schema_name,
    schema_id
FROM sys.schemas
WHERE name IN (
    N'staging',
    N'dw',
    N'controle',
    N'rejeicao',
    N'auditoria'
)
ORDER BY name;
GO
