/*
===============================================================================
Projeto   : Pipeline ETL para Data Warehouse
Banco     : Microsoft SQL Server
Linguagem : T-SQL
Arquivo   : 03_criar_tabelas_controle.sql
Autor     : Lucioney Godoy
Objetivo  : Criar as tabelas de controle responsáveis pelo registro das
            execuções do ETL, arquivos processados, mensagens de log,
            contagens, duração e reconciliação das cargas.
===============================================================================
*/

USE DataSalesDW;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*=============================================================================
  1. ORIENTAÇÕES DA CAMADA DE CONTROLE

  - Cada execução do pipeline possuirá um identificador único.
  - Os arquivos processados serão vinculados à execução correspondente.
  - As mensagens de acompanhamento serão registradas por etapa.
  - As contagens permitirão comparar origem, staging e Data Warehouse.
  - Os registros serão mantidos para rastreabilidade e auditoria.
=============================================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    /*=========================================================================
      2. TABELA: controle.execucao_etl
    =========================================================================*/

    IF OBJECT_ID(N'controle.execucao_etl', N'U') IS NULL
    BEGIN
        CREATE TABLE controle.execucao_etl
        (
            id_execucao               BIGINT IDENTITY(1,1) NOT NULL,
            nome_processo             NVARCHAR(150) NOT NULL,
            tipo_carga                VARCHAR(20) NOT NULL,
            data_referencia           DATE NULL,
            data_inicio               DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_execucao_etl_data_inicio
                DEFAULT SYSDATETIME(),
            data_fim                  DATETIME2(0) NULL,
            duracao_segundos          BIGINT NULL,
            status_execucao           VARCHAR(20) NOT NULL
                CONSTRAINT DF_controle_execucao_etl_status
                DEFAULT 'INICIADO',
            registros_lidos           BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_lidos
                DEFAULT 0,
            registros_validos         BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_validos
                DEFAULT 0,
            registros_invalidos       BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_invalidos
                DEFAULT 0,
            registros_inseridos       BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_inseridos
                DEFAULT 0,
            registros_atualizados     BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_atualizados
                DEFAULT 0,
            registros_descartados     BIGINT NOT NULL
                CONSTRAINT DF_controle_execucao_etl_descartados
                DEFAULT 0,
            mensagem_execucao         NVARCHAR(2000) NULL,
            usuario_execucao          NVARCHAR(128) NOT NULL
                CONSTRAINT DF_controle_execucao_etl_usuario
                DEFAULT ORIGINAL_LOGIN(),
            servidor_execucao         NVARCHAR(128) NOT NULL
                CONSTRAINT DF_controle_execucao_etl_servidor
                DEFAULT @@SERVERNAME,
            data_registro             DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_execucao_etl_data_registro
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_controle_execucao_etl
                PRIMARY KEY CLUSTERED (id_execucao),

            CONSTRAINT CK_controle_execucao_etl_tipo_carga
                CHECK (tipo_carga IN ('COMPLETA', 'INCREMENTAL')),

            CONSTRAINT CK_controle_execucao_etl_status
                CHECK (status_execucao IN
                ('INICIADO', 'EM_EXECUCAO', 'CONCLUIDO',
                 'CONCLUIDO_ALERTA', 'ERRO', 'CANCELADO')),

            CONSTRAINT CK_controle_execucao_etl_contagens
                CHECK
                (
                    registros_lidos       >= 0
                    AND registros_validos >= 0
                    AND registros_invalidos >= 0
                    AND registros_inseridos >= 0
                    AND registros_atualizados >= 0
                    AND registros_descartados >= 0
                ),

            CONSTRAINT CK_controle_execucao_etl_datas
                CHECK
                (
                    data_fim IS NULL
                    OR data_fim >= data_inicio
                )
        );

        CREATE NONCLUSTERED INDEX IX_controle_execucao_etl_processo_data
            ON controle.execucao_etl
            (
                nome_processo,
                data_inicio DESC
            )
            INCLUDE
            (
                status_execucao,
                tipo_carga,
                data_fim,
                duracao_segundos
            );

        CREATE NONCLUSTERED INDEX IX_controle_execucao_etl_status
            ON controle.execucao_etl
            (
                status_execucao,
                data_inicio DESC
            );

        PRINT N'Tabela controle.execucao_etl criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela controle.execucao_etl já existe.';
    END;


    /*=========================================================================
      3. TABELA: controle.arquivo_carga
    =========================================================================*/

    IF OBJECT_ID(N'controle.arquivo_carga', N'U') IS NULL
    BEGIN
        CREATE TABLE controle.arquivo_carga
        (
            id_arquivo_carga          BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao               BIGINT NOT NULL,
            nome_arquivo              NVARCHAR(260) NOT NULL,
            caminho_arquivo           NVARCHAR(1000) NULL,
            extensao_arquivo          NVARCHAR(20) NULL,
            tamanho_bytes             BIGINT NULL,
            hash_arquivo              VARCHAR(64) NULL,
            data_modificacao_arquivo  DATETIME2(0) NULL,
            data_inicio_processamento DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_inicio
                DEFAULT SYSDATETIME(),
            data_fim_processamento    DATETIME2(0) NULL,
            duracao_segundos          BIGINT NULL,
            registros_lidos           BIGINT NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_lidos
                DEFAULT 0,
            registros_validos         BIGINT NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_validos
                DEFAULT 0,
            registros_invalidos       BIGINT NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_invalidos
                DEFAULT 0,
            status_arquivo            VARCHAR(20) NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_status
                DEFAULT 'PENDENTE',
            mensagem_processamento    NVARCHAR(2000) NULL,
            data_registro             DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_arquivo_carga_data_registro
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_controle_arquivo_carga
                PRIMARY KEY CLUSTERED (id_arquivo_carga),

            CONSTRAINT FK_controle_arquivo_carga_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_controle_arquivo_carga_tamanho
                CHECK (tamanho_bytes IS NULL OR tamanho_bytes >= 0),

            CONSTRAINT CK_controle_arquivo_carga_contagens
                CHECK
                (
                    registros_lidos >= 0
                    AND registros_validos >= 0
                    AND registros_invalidos >= 0
                ),

            CONSTRAINT CK_controle_arquivo_carga_status
                CHECK (status_arquivo IN
                ('PENDENTE', 'EM_PROCESSAMENTO', 'PROCESSADO',
                 'PROCESSADO_ALERTA', 'ERRO', 'IGNORADO')),

            CONSTRAINT CK_controle_arquivo_carga_datas
                CHECK
                (
                    data_fim_processamento IS NULL
                    OR data_fim_processamento >= data_inicio_processamento
                )
        );

        CREATE NONCLUSTERED INDEX IX_controle_arquivo_carga_execucao
            ON controle.arquivo_carga
            (
                id_execucao,
                status_arquivo
            )
            INCLUDE
            (
                nome_arquivo,
                registros_lidos,
                registros_validos,
                registros_invalidos
            );

        CREATE NONCLUSTERED INDEX IX_controle_arquivo_carga_hash
            ON controle.arquivo_carga
            (
                hash_arquivo
            )
            WHERE hash_arquivo IS NOT NULL;

        PRINT N'Tabela controle.arquivo_carga criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela controle.arquivo_carga já existe.';
    END;


    /*=========================================================================
      4. TABELA: controle.log_execucao
    =========================================================================*/

    IF OBJECT_ID(N'controle.log_execucao', N'U') IS NULL
    BEGIN
        CREATE TABLE controle.log_execucao
        (
            id_log                    BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao               BIGINT NOT NULL,
            id_arquivo_carga          BIGINT NULL,
            nome_etapa                NVARCHAR(150) NOT NULL,
            nivel_log                 VARCHAR(20) NOT NULL,
            mensagem                  NVARCHAR(2000) NOT NULL,
            detalhe_erro              NVARCHAR(MAX) NULL,
            numero_erro               INT NULL,
            linha_erro                INT NULL,
            objeto_origem             NVARCHAR(256) NULL,
            data_log                  DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_log_execucao_data_log
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_controle_log_execucao
                PRIMARY KEY CLUSTERED (id_log),

            CONSTRAINT FK_controle_log_execucao_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_controle_log_execucao_arquivo
                FOREIGN KEY (id_arquivo_carga)
                REFERENCES controle.arquivo_carga (id_arquivo_carga),

            CONSTRAINT CK_controle_log_execucao_nivel
                CHECK (nivel_log IN
                ('DEBUG', 'INFORMACAO', 'ALERTA', 'ERRO', 'CRITICO'))
        );

        CREATE NONCLUSTERED INDEX IX_controle_log_execucao_execucao_data
            ON controle.log_execucao
            (
                id_execucao,
                data_log
            )
            INCLUDE
            (
                nivel_log,
                nome_etapa,
                mensagem
            );

        CREATE NONCLUSTERED INDEX IX_controle_log_execucao_nivel
            ON controle.log_execucao
            (
                nivel_log,
                data_log DESC
            );

        PRINT N'Tabela controle.log_execucao criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela controle.log_execucao já existe.';
    END;


    /*=========================================================================
      5. TABELA: controle.reconciliacao_carga
    =========================================================================*/

    IF OBJECT_ID(N'controle.reconciliacao_carga', N'U') IS NULL
    BEGIN
        CREATE TABLE controle.reconciliacao_carga
        (
            id_reconciliacao          BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao               BIGINT NOT NULL,
            nome_entidade             NVARCHAR(150) NOT NULL,
            camada_origem             NVARCHAR(50) NOT NULL,
            camada_destino            NVARCHAR(50) NOT NULL,
            quantidade_origem         BIGINT NOT NULL,
            quantidade_destino        BIGINT NOT NULL,
            diferenca_quantidade      AS
                (quantidade_origem - quantidade_destino),
            valor_origem              DECIMAL(19,2) NULL,
            valor_destino             DECIMAL(19,2) NULL,
            diferenca_valor           AS
                (ISNULL(valor_origem, 0) - ISNULL(valor_destino, 0)),
            status_reconciliacao      VARCHAR(20) NOT NULL,
            observacao                NVARCHAR(2000) NULL,
            data_reconciliacao        DATETIME2(0) NOT NULL
                CONSTRAINT DF_controle_reconciliacao_data
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_controle_reconciliacao_carga
                PRIMARY KEY CLUSTERED (id_reconciliacao),

            CONSTRAINT FK_controle_reconciliacao_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT CK_controle_reconciliacao_quantidades
                CHECK
                (
                    quantidade_origem >= 0
                    AND quantidade_destino >= 0
                ),

            CONSTRAINT CK_controle_reconciliacao_status
                CHECK (status_reconciliacao IN
                ('CONCILIADO', 'DIVERGENTE', 'PENDENTE'))
        );

        CREATE NONCLUSTERED INDEX IX_controle_reconciliacao_execucao
            ON controle.reconciliacao_carga
            (
                id_execucao,
                status_reconciliacao
            )
            INCLUDE
            (
                nome_entidade,
                camada_origem,
                camada_destino,
                quantidade_origem,
                quantidade_destino
            );

        PRINT N'Tabela controle.reconciliacao_carga criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela controle.reconciliacao_carga já existe.';
    END;


    /*=========================================================================
      6. RELACIONAMENTO ENTRE STAGING E CONTROLE DE EXECUÇÃO
    =========================================================================*/

    IF OBJECT_ID(N'staging.clientes', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_clientes_execucao'
       )
    BEGIN
        ALTER TABLE staging.clientes WITH CHECK
        ADD CONSTRAINT FK_staging_clientes_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.clientes criado.';
    END;

    IF OBJECT_ID(N'staging.produtos', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_produtos_execucao'
       )
    BEGIN
        ALTER TABLE staging.produtos WITH CHECK
        ADD CONSTRAINT FK_staging_produtos_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.produtos criado.';
    END;

    IF OBJECT_ID(N'staging.unidades', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_unidades_execucao'
       )
    BEGIN
        ALTER TABLE staging.unidades WITH CHECK
        ADD CONSTRAINT FK_staging_unidades_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.unidades criado.';
    END;

    IF OBJECT_ID(N'staging.vendedores', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_vendedores_execucao'
       )
    BEGIN
        ALTER TABLE staging.vendedores WITH CHECK
        ADD CONSTRAINT FK_staging_vendedores_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.vendedores criado.';
    END;

    IF OBJECT_ID(N'staging.metas', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_metas_execucao'
       )
    BEGIN
        ALTER TABLE staging.metas WITH CHECK
        ADD CONSTRAINT FK_staging_metas_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.metas criado.';
    END;

    IF OBJECT_ID(N'staging.vendas', N'U') IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1
           FROM sys.foreign_keys
           WHERE name = N'FK_staging_vendas_execucao'
       )
    BEGIN
        ALTER TABLE staging.vendas WITH CHECK
        ADD CONSTRAINT FK_staging_vendas_execucao
            FOREIGN KEY (id_execucao)
            REFERENCES controle.execucao_etl (id_execucao);

        PRINT N'Relacionamento staging.vendas criado.';
    END;


    COMMIT TRANSACTION;

    PRINT N'Estruturas da camada de controle criadas com sucesso.';

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

    PRINT N'Falha durante a criação das tabelas de controle.';
    PRINT N'Número do erro: ' + CONVERT(NVARCHAR(20), @numero_erro);
    PRINT N'Linha do erro: '  + CONVERT(NVARCHAR(20), @linha_erro);
    PRINT N'Mensagem: '       + @mensagem_erro;

    THROW;

END CATCH;
GO

/*=============================================================================
  7. CONSULTA DE CONFERÊNCIA
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
WHERE s.name = N'controle'
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
WHERE fk.name LIKE N'FK_staging_%_execucao'
ORDER BY
    fk.name;
GO
