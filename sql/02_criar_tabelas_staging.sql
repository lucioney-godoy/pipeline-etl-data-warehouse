/*
===============================================================================
Projeto   : Pipeline ETL para Data Warehouse
Banco     : Microsoft SQL Server
Linguagem : T-SQL
Arquivo   : 02_criar_tabelas_staging.sql
Autor     : Lucioney Godoy
Objetivo  : Criar as tabelas da camada staging responsáveis por receber os
            dados brutos provenientes dos arquivos CSV do projeto.
===============================================================================
*/

USE DataSalesDW;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*=============================================================================
  1. ORIENTAÇÕES DA CAMADA STAGING

  - Os campos recebidos dos arquivos CSV serão armazenados inicialmente como
    texto, permitindo a ingestão de registros válidos e inválidos.
  - As conversões de tipo e regras de qualidade serão aplicadas posteriormente.
  - Cada tabela possuirá colunas técnicas para rastreabilidade da carga.
=============================================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    /*=========================================================================
      2. TABELA: staging.clientes
    =========================================================================*/

    IF OBJECT_ID(N'staging.clientes', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.clientes
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            id_cliente             NVARCHAR(50) NULL,
            nome_cliente           NVARCHAR(200) NULL,
            cidade                 NVARCHAR(100) NULL,
            estado                 NVARCHAR(10) NULL,
            data_cadastro          NVARCHAR(50) NULL,
            status_cliente         NVARCHAR(30) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_clientes_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_clientes_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_clientes
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_clientes_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_clientes_execucao_status
            ON staging.clientes (id_execucao, status_processamento);

        PRINT N'Tabela staging.clientes criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.clientes já existe.';
    END;


    /*=========================================================================
      3. TABELA: staging.produtos
    =========================================================================*/

    IF OBJECT_ID(N'staging.produtos', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.produtos
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            id_produto             NVARCHAR(50) NULL,
            nome_produto           NVARCHAR(200) NULL,
            categoria              NVARCHAR(100) NULL,
            subcategoria           NVARCHAR(100) NULL,
            marca                  NVARCHAR(100) NULL,
            valor_unitario         NVARCHAR(50) NULL,
            status_produto         NVARCHAR(30) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_produtos_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_produtos_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_produtos
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_produtos_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_produtos_execucao_status
            ON staging.produtos (id_execucao, status_processamento);

        PRINT N'Tabela staging.produtos criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.produtos já existe.';
    END;


    /*=========================================================================
      4. TABELA: staging.unidades
    =========================================================================*/

    IF OBJECT_ID(N'staging.unidades', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.unidades
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            id_unidade             NVARCHAR(50) NULL,
            nome_unidade           NVARCHAR(200) NULL,
            cidade                 NVARCHAR(100) NULL,
            estado                 NVARCHAR(10) NULL,
            regiao                 NVARCHAR(50) NULL,
            status_unidade         NVARCHAR(30) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_unidades_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_unidades_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_unidades
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_unidades_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_unidades_execucao_status
            ON staging.unidades (id_execucao, status_processamento);

        PRINT N'Tabela staging.unidades criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.unidades já existe.';
    END;


    /*=========================================================================
      5. TABELA: staging.vendedores
    =========================================================================*/

    IF OBJECT_ID(N'staging.vendedores', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.vendedores
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            id_vendedor            NVARCHAR(50) NULL,
            nome_vendedor          NVARCHAR(200) NULL,
            id_unidade             NVARCHAR(50) NULL,
            cargo                  NVARCHAR(100) NULL,
            data_admissao          NVARCHAR(50) NULL,
            status_vendedor        NVARCHAR(30) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_vendedores_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_vendedores_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_vendedores
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_vendedores_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_vendedores_execucao_status
            ON staging.vendedores (id_execucao, status_processamento);

        PRINT N'Tabela staging.vendedores criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.vendedores já existe.';
    END;


    /*=========================================================================
      6. TABELA: staging.metas
    =========================================================================*/

    IF OBJECT_ID(N'staging.metas', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.metas
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            ano                    NVARCHAR(20) NULL,
            mes                    NVARCHAR(20) NULL,
            id_vendedor            NVARCHAR(50) NULL,
            id_unidade             NVARCHAR(50) NULL,
            valor_meta             NVARCHAR(50) NULL,
            data_atualizacao       NVARCHAR(50) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_metas_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_metas_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_metas
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_metas_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_metas_execucao_status
            ON staging.metas (id_execucao, status_processamento);

        PRINT N'Tabela staging.metas criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.metas já existe.';
    END;


    /*=========================================================================
      7. TABELA: staging.vendas
    =========================================================================*/

    IF OBJECT_ID(N'staging.vendas', N'U') IS NULL
    BEGIN
        CREATE TABLE staging.vendas
        (
            id_staging             BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao            BIGINT NULL,
            id_venda               NVARCHAR(50) NULL,
            data_venda             NVARCHAR(50) NULL,
            id_cliente             NVARCHAR(50) NULL,
            id_produto             NVARCHAR(50) NULL,
            id_vendedor            NVARCHAR(50) NULL,
            id_unidade             NVARCHAR(50) NULL,
            quantidade             NVARCHAR(50) NULL,
            valor_unitario         NVARCHAR(50) NULL,
            desconto_percentual    NVARCHAR(50) NULL,
            valor_total            NVARCHAR(50) NULL,
            canal_venda            NVARCHAR(100) NULL,
            forma_pagamento        NVARCHAR(100) NULL,
            status_venda           NVARCHAR(30) NULL,
            codigo_pedido          NVARCHAR(100) NULL,
            nome_arquivo           NVARCHAR(260) NULL,
            numero_linha           INT NULL,
            data_carga             DATETIME2(0) NOT NULL
                CONSTRAINT DF_staging_vendas_data_carga
                DEFAULT SYSDATETIME(),
            status_processamento   VARCHAR(20) NOT NULL
                CONSTRAINT DF_staging_vendas_status_processamento
                DEFAULT 'PENDENTE',

            CONSTRAINT PK_staging_vendas
                PRIMARY KEY CLUSTERED (id_staging),

            CONSTRAINT CK_staging_vendas_status_processamento
                CHECK (status_processamento IN
                ('PENDENTE', 'VALIDO', 'INVALIDO', 'PROCESSADO'))
        );

        CREATE NONCLUSTERED INDEX IX_staging_vendas_execucao_status
            ON staging.vendas (id_execucao, status_processamento);

        CREATE NONCLUSTERED INDEX IX_staging_vendas_id_venda
            ON staging.vendas (id_venda);

        PRINT N'Tabela staging.vendas criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela staging.vendas já existe.';
    END;


    COMMIT TRANSACTION;

    PRINT N'Tabelas da camada staging criadas e validadas com sucesso.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    DECLARE
        @mensagem_erro NVARCHAR(4000) = ERROR_MESSAGE(),
        @numero_erro   INT            = ERROR_NUMBER(),
        @linha_erro    INT            = ERROR_LINE();

    PRINT N'Falha durante a criação das tabelas de staging.';
    PRINT N'Número do erro: ' + CONVERT(NVARCHAR(20), @numero_erro);
    PRINT N'Linha do erro: '  + CONVERT(NVARCHAR(20), @linha_erro);
    PRINT N'Mensagem: '       + @mensagem_erro;

    THROW;

END CATCH;
GO

/*=============================================================================
  8. CONSULTA DE CONFERÊNCIA
=============================================================================*/

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS quantidade_registros
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions p
    ON p.object_id = t.object_id
   AND p.index_id IN (0, 1)
WHERE s.name = N'staging'
GROUP BY
    s.name,
    t.name
ORDER BY
    t.name;
GO
