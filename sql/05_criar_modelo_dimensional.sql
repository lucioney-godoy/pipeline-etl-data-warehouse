/*
===============================================================================
Projeto   : Pipeline ETL para Data Warehouse
Banco     : Microsoft SQL Server
Linguagem : T-SQL
Arquivo   : 05_criar_modelo_dimensional.sql
Autor     : Lucioney Godoy
Objetivo  : Criar o modelo dimensional do Data Warehouse, incluindo dimensões,
            tabelas fato, chaves substitutas, relacionamentos, constraints,
            índices e membros padrão para valores não informados.
===============================================================================
*/

USE DataSalesDW;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*=============================================================================
  1. ORIENTAÇÕES DO MODELO DIMENSIONAL

  - As dimensões utilizam chaves substitutas no padrão sk_nome.
  - As chaves naturais provenientes das fontes permanecem como atributos.
  - As dimensões de negócio estão preparadas para histórico do tipo SCD 2.
  - O membro de chave 0 representa valores não informados ou não localizados.
  - As tabelas fato armazenam medidas quantitativas e referências às dimensões.
=============================================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    /*=========================================================================
      2. DIMENSÃO: dw.dim_cliente
    =========================================================================*/

    IF OBJECT_ID(N'dw.dim_cliente', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.dim_cliente
        (
            sk_cliente                 BIGINT IDENTITY(0,1) NOT NULL,
            id_cliente                 INT NOT NULL,
            nome_cliente               NVARCHAR(200) NOT NULL,
            cidade                     NVARCHAR(100) NOT NULL,
            estado                     CHAR(2) NOT NULL,
            data_cadastro              DATE NULL,
            status_cliente             VARCHAR(20) NOT NULL,
            hash_atributos             VARBINARY(32) NULL,
            data_inicio_vigencia       DATE NOT NULL
                CONSTRAINT DF_dw_dim_cliente_inicio_vigencia
                DEFAULT CONVERT(DATE, SYSDATETIME()),
            data_fim_vigencia          DATE NULL,
            registro_atual             BIT NOT NULL
                CONSTRAINT DF_dw_dim_cliente_registro_atual
                DEFAULT 1,
            id_execucao_inclusao       BIGINT NULL,
            id_execucao_atualizacao    BIGINT NULL,
            data_inclusao              DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_dim_cliente_data_inclusao
                DEFAULT SYSDATETIME(),
            data_atualizacao           DATETIME2(0) NULL,

            CONSTRAINT PK_dw_dim_cliente
                PRIMARY KEY CLUSTERED (sk_cliente),

            CONSTRAINT FK_dw_dim_cliente_execucao_inclusao
                FOREIGN KEY (id_execucao_inclusao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_dw_dim_cliente_execucao_atualizacao
                FOREIGN KEY (id_execucao_atualizacao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_dim_cliente_status
                CHECK
                (
                    status_cliente IN
                    (
                        'ATIVO',
                        'INATIVO',
                        'NAO_INFORMADO'
                    )
                ),

            CONSTRAINT CK_dw_dim_cliente_vigencia
                CHECK
                (
                    data_fim_vigencia IS NULL
                    OR data_fim_vigencia >= data_inicio_vigencia
                ),

            CONSTRAINT CK_dw_dim_cliente_registro_atual
                CHECK
                (
                    (registro_atual = 1 AND data_fim_vigencia IS NULL)
                    OR
                    (registro_atual = 0 AND data_fim_vigencia IS NOT NULL)
                )
        );

        CREATE UNIQUE NONCLUSTERED INDEX UX_dw_dim_cliente_id_atual
            ON dw.dim_cliente (id_cliente)
            WHERE registro_atual = 1;

        CREATE NONCLUSTERED INDEX IX_dw_dim_cliente_localidade
            ON dw.dim_cliente (estado, cidade)
            INCLUDE (nome_cliente, status_cliente, registro_atual);

        INSERT INTO dw.dim_cliente
        (
            id_cliente,
            nome_cliente,
            cidade,
            estado,
            data_cadastro,
            status_cliente,
            hash_atributos,
            data_inicio_vigencia,
            data_fim_vigencia,
            registro_atual
        )
        VALUES
        (
            -1,
            N'Não informado',
            N'Não informado',
            'NI',
            NULL,
            'NAO_INFORMADO',
            NULL,
            CONVERT(DATE, '19000101', 112),
            NULL,
            1
        );

        PRINT N'Dimensão dw.dim_cliente criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A dimensão dw.dim_cliente já existe.';
    END;


    /*=========================================================================
      3. DIMENSÃO: dw.dim_produto
    =========================================================================*/

    IF OBJECT_ID(N'dw.dim_produto', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.dim_produto
        (
            sk_produto                 BIGINT IDENTITY(0,1) NOT NULL,
            id_produto                 INT NOT NULL,
            nome_produto               NVARCHAR(200) NOT NULL,
            categoria                  NVARCHAR(100) NOT NULL,
            subcategoria               NVARCHAR(100) NOT NULL,
            marca                      NVARCHAR(100) NOT NULL,
            valor_unitario_referencia  DECIMAL(19,2) NULL,
            status_produto             VARCHAR(20) NOT NULL,
            hash_atributos             VARBINARY(32) NULL,
            data_inicio_vigencia       DATE NOT NULL
                CONSTRAINT DF_dw_dim_produto_inicio_vigencia
                DEFAULT CONVERT(DATE, SYSDATETIME()),
            data_fim_vigencia          DATE NULL,
            registro_atual             BIT NOT NULL
                CONSTRAINT DF_dw_dim_produto_registro_atual
                DEFAULT 1,
            id_execucao_inclusao       BIGINT NULL,
            id_execucao_atualizacao    BIGINT NULL,
            data_inclusao              DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_dim_produto_data_inclusao
                DEFAULT SYSDATETIME(),
            data_atualizacao           DATETIME2(0) NULL,

            CONSTRAINT PK_dw_dim_produto
                PRIMARY KEY CLUSTERED (sk_produto),

            CONSTRAINT FK_dw_dim_produto_execucao_inclusao
                FOREIGN KEY (id_execucao_inclusao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_dw_dim_produto_execucao_atualizacao
                FOREIGN KEY (id_execucao_atualizacao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_dim_produto_valor
                CHECK
                (
                    valor_unitario_referencia IS NULL
                    OR valor_unitario_referencia >= 0
                ),

            CONSTRAINT CK_dw_dim_produto_status
                CHECK
                (
                    status_produto IN
                    (
                        'ATIVO',
                        'INATIVO',
                        'NAO_INFORMADO'
                    )
                ),

            CONSTRAINT CK_dw_dim_produto_vigencia
                CHECK
                (
                    data_fim_vigencia IS NULL
                    OR data_fim_vigencia >= data_inicio_vigencia
                ),

            CONSTRAINT CK_dw_dim_produto_registro_atual
                CHECK
                (
                    (registro_atual = 1 AND data_fim_vigencia IS NULL)
                    OR
                    (registro_atual = 0 AND data_fim_vigencia IS NOT NULL)
                )
        );

        CREATE UNIQUE NONCLUSTERED INDEX UX_dw_dim_produto_id_atual
            ON dw.dim_produto (id_produto)
            WHERE registro_atual = 1;

        CREATE NONCLUSTERED INDEX IX_dw_dim_produto_categoria
            ON dw.dim_produto (categoria, subcategoria, marca)
            INCLUDE
            (
                nome_produto,
                valor_unitario_referencia,
                status_produto,
                registro_atual
            );

        INSERT INTO dw.dim_produto
        (
            id_produto,
            nome_produto,
            categoria,
            subcategoria,
            marca,
            valor_unitario_referencia,
            status_produto,
            hash_atributos,
            data_inicio_vigencia,
            data_fim_vigencia,
            registro_atual
        )
        VALUES
        (
            -1,
            N'Não informado',
            N'Não informado',
            N'Não informado',
            N'Não informado',
            NULL,
            'NAO_INFORMADO',
            NULL,
            CONVERT(DATE, '19000101', 112),
            NULL,
            1
        );

        PRINT N'Dimensão dw.dim_produto criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A dimensão dw.dim_produto já existe.';
    END;


    /*=========================================================================
      4. DIMENSÃO: dw.dim_unidade
    =========================================================================*/

    IF OBJECT_ID(N'dw.dim_unidade', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.dim_unidade
        (
            sk_unidade                 BIGINT IDENTITY(0,1) NOT NULL,
            id_unidade                 INT NOT NULL,
            nome_unidade               NVARCHAR(200) NOT NULL,
            cidade                     NVARCHAR(100) NOT NULL,
            estado                     CHAR(2) NOT NULL,
            regiao                     NVARCHAR(50) NOT NULL,
            status_unidade             VARCHAR(20) NOT NULL,
            hash_atributos             VARBINARY(32) NULL,
            data_inicio_vigencia       DATE NOT NULL
                CONSTRAINT DF_dw_dim_unidade_inicio_vigencia
                DEFAULT CONVERT(DATE, SYSDATETIME()),
            data_fim_vigencia          DATE NULL,
            registro_atual             BIT NOT NULL
                CONSTRAINT DF_dw_dim_unidade_registro_atual
                DEFAULT 1,
            id_execucao_inclusao       BIGINT NULL,
            id_execucao_atualizacao    BIGINT NULL,
            data_inclusao              DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_dim_unidade_data_inclusao
                DEFAULT SYSDATETIME(),
            data_atualizacao           DATETIME2(0) NULL,

            CONSTRAINT PK_dw_dim_unidade
                PRIMARY KEY CLUSTERED (sk_unidade),

            CONSTRAINT FK_dw_dim_unidade_execucao_inclusao
                FOREIGN KEY (id_execucao_inclusao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_dw_dim_unidade_execucao_atualizacao
                FOREIGN KEY (id_execucao_atualizacao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_dim_unidade_status
                CHECK
                (
                    status_unidade IN
                    (
                        'ATIVA',
                        'INATIVA',
                        'NAO_INFORMADO'
                    )
                ),

            CONSTRAINT CK_dw_dim_unidade_vigencia
                CHECK
                (
                    data_fim_vigencia IS NULL
                    OR data_fim_vigencia >= data_inicio_vigencia
                ),

            CONSTRAINT CK_dw_dim_unidade_registro_atual
                CHECK
                (
                    (registro_atual = 1 AND data_fim_vigencia IS NULL)
                    OR
                    (registro_atual = 0 AND data_fim_vigencia IS NOT NULL)
                )
        );

        CREATE UNIQUE NONCLUSTERED INDEX UX_dw_dim_unidade_id_atual
            ON dw.dim_unidade (id_unidade)
            WHERE registro_atual = 1;

        CREATE NONCLUSTERED INDEX IX_dw_dim_unidade_localidade
            ON dw.dim_unidade (regiao, estado, cidade)
            INCLUDE (nome_unidade, status_unidade, registro_atual);

        INSERT INTO dw.dim_unidade
        (
            id_unidade,
            nome_unidade,
            cidade,
            estado,
            regiao,
            status_unidade,
            hash_atributos,
            data_inicio_vigencia,
            data_fim_vigencia,
            registro_atual
        )
        VALUES
        (
            -1,
            N'Não informado',
            N'Não informado',
            'NI',
            N'Não informado',
            'NAO_INFORMADO',
            NULL,
            CONVERT(DATE, '19000101', 112),
            NULL,
            1
        );

        PRINT N'Dimensão dw.dim_unidade criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A dimensão dw.dim_unidade já existe.';
    END;


    /*=========================================================================
      5. DIMENSÃO: dw.dim_vendedor
    =========================================================================*/

    IF OBJECT_ID(N'dw.dim_vendedor', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.dim_vendedor
        (
            sk_vendedor                BIGINT IDENTITY(0,1) NOT NULL,
            id_vendedor                INT NOT NULL,
            nome_vendedor              NVARCHAR(200) NOT NULL,
            id_unidade_origem          INT NOT NULL,
            cargo                      NVARCHAR(100) NOT NULL,
            data_admissao              DATE NULL,
            status_vendedor            VARCHAR(20) NOT NULL,
            hash_atributos             VARBINARY(32) NULL,
            data_inicio_vigencia       DATE NOT NULL
                CONSTRAINT DF_dw_dim_vendedor_inicio_vigencia
                DEFAULT CONVERT(DATE, SYSDATETIME()),
            data_fim_vigencia          DATE NULL,
            registro_atual             BIT NOT NULL
                CONSTRAINT DF_dw_dim_vendedor_registro_atual
                DEFAULT 1,
            id_execucao_inclusao       BIGINT NULL,
            id_execucao_atualizacao    BIGINT NULL,
            data_inclusao              DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_dim_vendedor_data_inclusao
                DEFAULT SYSDATETIME(),
            data_atualizacao           DATETIME2(0) NULL,

            CONSTRAINT PK_dw_dim_vendedor
                PRIMARY KEY CLUSTERED (sk_vendedor),

            CONSTRAINT FK_dw_dim_vendedor_execucao_inclusao
                FOREIGN KEY (id_execucao_inclusao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_dw_dim_vendedor_execucao_atualizacao
                FOREIGN KEY (id_execucao_atualizacao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_dim_vendedor_status
                CHECK
                (
                    status_vendedor IN
                    (
                        'ATIVO',
                        'INATIVO',
                        'NAO_INFORMADO'
                    )
                ),

            CONSTRAINT CK_dw_dim_vendedor_vigencia
                CHECK
                (
                    data_fim_vigencia IS NULL
                    OR data_fim_vigencia >= data_inicio_vigencia
                ),

            CONSTRAINT CK_dw_dim_vendedor_registro_atual
                CHECK
                (
                    (registro_atual = 1 AND data_fim_vigencia IS NULL)
                    OR
                    (registro_atual = 0 AND data_fim_vigencia IS NOT NULL)
                )
        );

        CREATE UNIQUE NONCLUSTERED INDEX UX_dw_dim_vendedor_id_atual
            ON dw.dim_vendedor (id_vendedor)
            WHERE registro_atual = 1;

        CREATE NONCLUSTERED INDEX IX_dw_dim_vendedor_unidade_cargo
            ON dw.dim_vendedor (id_unidade_origem, cargo)
            INCLUDE
            (
                nome_vendedor,
                status_vendedor,
                data_admissao,
                registro_atual
            );

        INSERT INTO dw.dim_vendedor
        (
            id_vendedor,
            nome_vendedor,
            id_unidade_origem,
            cargo,
            data_admissao,
            status_vendedor,
            hash_atributos,
            data_inicio_vigencia,
            data_fim_vigencia,
            registro_atual
        )
        VALUES
        (
            -1,
            N'Não informado',
            -1,
            N'Não informado',
            NULL,
            'NAO_INFORMADO',
            NULL,
            CONVERT(DATE, '19000101', 112),
            NULL,
            1
        );

        PRINT N'Dimensão dw.dim_vendedor criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A dimensão dw.dim_vendedor já existe.';
    END;


    /*=========================================================================
      6. DIMENSÃO: dw.dim_calendario

      A estrutura é criada neste arquivo. O preenchimento será realizado pelo
      script 06_criar_dim_calendario.sql.
    =========================================================================*/

    IF OBJECT_ID(N'dw.dim_calendario', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.dim_calendario
        (
            sk_data                    INT NOT NULL,
            data_completa              DATE NOT NULL,
            ano                        SMALLINT NOT NULL,
            semestre                   TINYINT NOT NULL,
            trimestre                  TINYINT NOT NULL,
            numero_mes                 TINYINT NOT NULL,
            nome_mes                   NVARCHAR(20) NOT NULL,
            nome_mes_abreviado         NVARCHAR(3) NOT NULL,
            ano_mes                    CHAR(7) NOT NULL,
            numero_dia_mes             TINYINT NOT NULL,
            numero_dia_semana          TINYINT NOT NULL,
            nome_dia_semana            NVARCHAR(20) NOT NULL,
            nome_dia_abreviado         NVARCHAR(3) NOT NULL,
            numero_semana_ano          TINYINT NOT NULL,
            indicador_fim_semana       BIT NOT NULL,
            indicador_feriado          BIT NOT NULL
                CONSTRAINT DF_dw_dim_calendario_feriado
                DEFAULT 0,
            descricao_feriado          NVARCHAR(100) NULL,

            CONSTRAINT PK_dw_dim_calendario
                PRIMARY KEY CLUSTERED (sk_data),

            CONSTRAINT UQ_dw_dim_calendario_data
                UNIQUE (data_completa),

            CONSTRAINT CK_dw_dim_calendario_semestre
                CHECK (semestre BETWEEN 1 AND 2),

            CONSTRAINT CK_dw_dim_calendario_trimestre
                CHECK (trimestre BETWEEN 1 AND 4),

            CONSTRAINT CK_dw_dim_calendario_mes
                CHECK (numero_mes BETWEEN 1 AND 12),

            CONSTRAINT CK_dw_dim_calendario_dia_mes
                CHECK (numero_dia_mes BETWEEN 1 AND 31),

            CONSTRAINT CK_dw_dim_calendario_dia_semana
                CHECK (numero_dia_semana BETWEEN 1 AND 7),

            CONSTRAINT CK_dw_dim_calendario_semana_ano
                CHECK (numero_semana_ano BETWEEN 1 AND 53)
        );

        INSERT INTO dw.dim_calendario
        (
            sk_data,
            data_completa,
            ano,
            semestre,
            trimestre,
            numero_mes,
            nome_mes,
            nome_mes_abreviado,
            ano_mes,
            numero_dia_mes,
            numero_dia_semana,
            nome_dia_semana,
            nome_dia_abreviado,
            numero_semana_ano,
            indicador_fim_semana,
            indicador_feriado,
            descricao_feriado
        )
        VALUES
        (
            0,
            CONVERT(DATE, '19000101', 112),
            1900,
            1,
            1,
            1,
            N'Não informado',
            N'N/I',
            '1900-01',
            1,
            1,
            N'Não informado',
            N'N/I',
            1,
            0,
            0,
            NULL
        );

        PRINT N'Dimensão dw.dim_calendario criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A dimensão dw.dim_calendario já existe.';
    END;


    /*=========================================================================
      7. TABELA FATO: dw.fato_vendas
    =========================================================================*/

    IF OBJECT_ID(N'dw.fato_vendas', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.fato_vendas
        (
            sk_venda                  BIGINT IDENTITY(1,1) NOT NULL,
            id_venda                  BIGINT NOT NULL,
            sk_data                   INT NOT NULL,
            sk_cliente                BIGINT NOT NULL,
            sk_produto                BIGINT NOT NULL,
            sk_vendedor               BIGINT NOT NULL,
            sk_unidade                BIGINT NOT NULL,
            quantidade                INT NOT NULL,
            valor_unitario            DECIMAL(19,2) NOT NULL,
            desconto_percentual       DECIMAL(9,4) NOT NULL,
            valor_bruto               DECIMAL(19,2) NOT NULL,
            valor_desconto            DECIMAL(19,2) NOT NULL,
            valor_total               DECIMAL(19,2) NOT NULL,
            canal_venda               NVARCHAR(100) NOT NULL,
            forma_pagamento           NVARCHAR(100) NOT NULL,
            status_venda              VARCHAR(20) NOT NULL,
            codigo_pedido             NVARCHAR(100) NOT NULL,
            id_execucao               BIGINT NOT NULL,
            data_carga                DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_fato_vendas_data_carga
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_dw_fato_vendas
                PRIMARY KEY CLUSTERED (sk_venda),

            CONSTRAINT UQ_dw_fato_vendas_id_venda
                UNIQUE (id_venda),

            CONSTRAINT UQ_dw_fato_vendas_codigo_pedido
                UNIQUE (codigo_pedido),

            CONSTRAINT FK_dw_fato_vendas_data
                FOREIGN KEY (sk_data)
                REFERENCES dw.dim_calendario (sk_data),

            CONSTRAINT FK_dw_fato_vendas_cliente
                FOREIGN KEY (sk_cliente)
                REFERENCES dw.dim_cliente (sk_cliente),

            CONSTRAINT FK_dw_fato_vendas_produto
                FOREIGN KEY (sk_produto)
                REFERENCES dw.dim_produto (sk_produto),

            CONSTRAINT FK_dw_fato_vendas_vendedor
                FOREIGN KEY (sk_vendedor)
                REFERENCES dw.dim_vendedor (sk_vendedor),

            CONSTRAINT FK_dw_fato_vendas_unidade
                FOREIGN KEY (sk_unidade)
                REFERENCES dw.dim_unidade (sk_unidade),

            CONSTRAINT FK_dw_fato_vendas_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_fato_vendas_quantidade
                CHECK (quantidade > 0),

            CONSTRAINT CK_dw_fato_vendas_valor_unitario
                CHECK (valor_unitario >= 0),

            CONSTRAINT CK_dw_fato_vendas_desconto
                CHECK (desconto_percentual BETWEEN 0 AND 100),

            CONSTRAINT CK_dw_fato_vendas_valores
                CHECK
                (
                    valor_bruto >= 0
                    AND valor_desconto >= 0
                    AND valor_total >= 0
                    AND valor_desconto <= valor_bruto
                    AND valor_total = valor_bruto - valor_desconto
                ),

            CONSTRAINT CK_dw_fato_vendas_status
                CHECK
                (
                    status_venda IN
                    (
                        'CONCLUIDA',
                        'CANCELADA'
                    )
                )
        );

        CREATE NONCLUSTERED INDEX IX_dw_fato_vendas_data
            ON dw.fato_vendas (sk_data)
            INCLUDE
            (
                sk_cliente,
                sk_produto,
                sk_vendedor,
                sk_unidade,
                quantidade,
                valor_total,
                status_venda
            );

        CREATE NONCLUSTERED INDEX IX_dw_fato_vendas_vendedor_unidade
            ON dw.fato_vendas (sk_vendedor, sk_unidade, sk_data)
            INCLUDE
            (
                quantidade,
                valor_bruto,
                valor_desconto,
                valor_total
            );

        CREATE NONCLUSTERED INDEX IX_dw_fato_vendas_produto
            ON dw.fato_vendas (sk_produto, sk_data)
            INCLUDE
            (
                quantidade,
                valor_total
            );

        PRINT N'Tabela fato dw.fato_vendas criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela fato dw.fato_vendas já existe.';
    END;


    /*=========================================================================
      8. TABELA FATO: dw.fato_metas
    =========================================================================*/

    IF OBJECT_ID(N'dw.fato_metas', N'U') IS NULL
    BEGIN
        CREATE TABLE dw.fato_metas
        (
            sk_meta                   BIGINT IDENTITY(1,1) NOT NULL,
            sk_data                   INT NOT NULL,
            sk_vendedor               BIGINT NOT NULL,
            sk_unidade                BIGINT NOT NULL,
            valor_meta                DECIMAL(19,2) NOT NULL,
            id_execucao               BIGINT NOT NULL,
            data_carga                DATETIME2(0) NOT NULL
                CONSTRAINT DF_dw_fato_metas_data_carga
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_dw_fato_metas
                PRIMARY KEY CLUSTERED (sk_meta),

            CONSTRAINT UQ_dw_fato_metas_periodo_vendedor
                UNIQUE
                (
                    sk_data,
                    sk_vendedor,
                    sk_unidade
                ),

            CONSTRAINT FK_dw_fato_metas_data
                FOREIGN KEY (sk_data)
                REFERENCES dw.dim_calendario (sk_data),

            CONSTRAINT FK_dw_fato_metas_vendedor
                FOREIGN KEY (sk_vendedor)
                REFERENCES dw.dim_vendedor (sk_vendedor),

            CONSTRAINT FK_dw_fato_metas_unidade
                FOREIGN KEY (sk_unidade)
                REFERENCES dw.dim_unidade (sk_unidade),

            CONSTRAINT FK_dw_fato_metas_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_dw_fato_metas_valor
                CHECK (valor_meta > 0)
        );

        CREATE NONCLUSTERED INDEX IX_dw_fato_metas_data
            ON dw.fato_metas (sk_data)
            INCLUDE
            (
                sk_vendedor,
                sk_unidade,
                valor_meta
            );

        CREATE NONCLUSTERED INDEX IX_dw_fato_metas_vendedor
            ON dw.fato_metas (sk_vendedor, sk_data)
            INCLUDE
            (
                sk_unidade,
                valor_meta
            );

        PRINT N'Tabela fato dw.fato_metas criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela fato dw.fato_metas já existe.';
    END;


    COMMIT TRANSACTION;

    PRINT N'Modelo dimensional criado com sucesso.';

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

    PRINT N'Falha durante a criação do modelo dimensional.';
    PRINT N'Número do erro: ' + CONVERT(NVARCHAR(20), @numero_erro);
    PRINT N'Linha do erro: '  + CONVERT(NVARCHAR(20), @linha_erro);
    PRINT N'Mensagem: '       + @mensagem_erro;

    THROW;

END CATCH;
GO

/*=============================================================================
  9. CONSULTAS DE CONFERÊNCIA
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
WHERE s.name = N'dw'
GROUP BY
    s.name,
    t.name
ORDER BY
    t.name;
GO

SELECT
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS schema_origem,
    OBJECT_NAME(fk.parent_object_id) AS tabela_origem,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS schema_destino,
    OBJECT_NAME(fk.referenced_object_id) AS tabela_destino
FROM sys.foreign_keys fk
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = N'dw'
ORDER BY
    tabela_origem,
    foreign_key_name;
GO

SELECT
    N'dw.dim_cliente' AS dimensao,
    sk_cliente AS chave_substituta,
    nome_cliente AS membro_padrao
FROM dw.dim_cliente
WHERE sk_cliente = 0

UNION ALL

SELECT
    N'dw.dim_produto',
    sk_produto,
    nome_produto
FROM dw.dim_produto
WHERE sk_produto = 0

UNION ALL

SELECT
    N'dw.dim_unidade',
    sk_unidade,
    nome_unidade
FROM dw.dim_unidade
WHERE sk_unidade = 0

UNION ALL

SELECT
    N'dw.dim_vendedor',
    sk_vendedor,
    nome_vendedor
FROM dw.dim_vendedor
WHERE sk_vendedor = 0;
GO
