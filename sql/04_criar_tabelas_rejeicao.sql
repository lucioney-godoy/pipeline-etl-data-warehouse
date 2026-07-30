/*
===============================================================================
Projeto   : Pipeline ETL para Data Warehouse
Banco     : Microsoft SQL Server
Linguagem : T-SQL
Arquivo   : 04_criar_tabelas_rejeicao.sql
Autor     : Lucioney Godoy
Objetivo  : Criar as tabelas responsáveis pelo armazenamento dos registros
            rejeitados, seus motivos de rejeição e o histórico de tratamento.
===============================================================================
*/

USE DataSalesDW;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*=============================================================================
  1. ORIENTAÇÕES DA CAMADA DE REJEIÇÃO

  - Cada registro inválido será armazenado uma única vez.
  - Um registro poderá possuir um ou vários motivos de rejeição.
  - O conteúdo original poderá ser armazenado em formato JSON.
  - O histórico de tratamento permitirá acompanhar correções e reprocessamentos.
  - Todos os registros serão vinculados à execução do pipeline.
=============================================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    /*=========================================================================
      2. TABELA: rejeicao.registro_rejeitado

      Armazena o registro de origem que não atendeu às regras de qualidade.
    =========================================================================*/

    IF OBJECT_ID(N'rejeicao.registro_rejeitado', N'U') IS NULL
    BEGIN
        CREATE TABLE rejeicao.registro_rejeitado
        (
            id_rejeicao              BIGINT IDENTITY(1,1) NOT NULL,
            id_execucao              BIGINT NOT NULL,
            id_arquivo_carga         BIGINT NULL,
            entidade_origem          NVARCHAR(100) NOT NULL,
            schema_origem            SYSNAME NOT NULL,
            tabela_origem            SYSNAME NOT NULL,
            id_staging               BIGINT NOT NULL,
            chave_negocio            NVARCHAR(200) NULL,
            nome_arquivo             NVARCHAR(260) NULL,
            numero_linha             INT NULL,
            conteudo_registro        NVARCHAR(MAX) NULL,
            quantidade_motivos       INT NOT NULL
                CONSTRAINT DF_rejeicao_registro_quantidade_motivos
                DEFAULT 0,
            status_tratamento        VARCHAR(20) NOT NULL
                CONSTRAINT DF_rejeicao_registro_status
                DEFAULT 'PENDENTE',
            data_rejeicao            DATETIME2(0) NOT NULL
                CONSTRAINT DF_rejeicao_registro_data_rejeicao
                DEFAULT SYSDATETIME(),
            data_ultima_atualizacao  DATETIME2(0) NOT NULL
                CONSTRAINT DF_rejeicao_registro_data_atualizacao
                DEFAULT SYSDATETIME(),
            observacao               NVARCHAR(2000) NULL,

            CONSTRAINT PK_rejeicao_registro_rejeitado
                PRIMARY KEY CLUSTERED (id_rejeicao),

            CONSTRAINT FK_rejeicao_registro_execucao
                FOREIGN KEY (id_execucao)
                REFERENCES controle.execucao_etl (id_execucao),

            CONSTRAINT FK_rejeicao_registro_arquivo
                FOREIGN KEY (id_arquivo_carga)
                REFERENCES controle.arquivo_carga (id_arquivo_carga),

            CONSTRAINT UQ_rejeicao_registro_origem
                UNIQUE
                (
                    id_execucao,
                    schema_origem,
                    tabela_origem,
                    id_staging
                ),

            CONSTRAINT CK_rejeicao_registro_numero_linha
                CHECK (numero_linha IS NULL OR numero_linha > 0),

            CONSTRAINT CK_rejeicao_registro_quantidade_motivos
                CHECK (quantidade_motivos >= 0),

            CONSTRAINT CK_rejeicao_registro_status
                CHECK
                (
                    status_tratamento IN
                    (
                        'PENDENTE',
                        'EM_ANALISE',
                        'CORRIGIDO',
                        'DESCARTADO',
                        'REPROCESSADO'
                    )
                ),

            CONSTRAINT CK_rejeicao_registro_json
                CHECK
                (
                    conteudo_registro IS NULL
                    OR ISJSON(conteudo_registro) = 1
                )
        );

        CREATE NONCLUSTERED INDEX IX_rejeicao_registro_execucao_status
            ON rejeicao.registro_rejeitado
            (
                id_execucao,
                status_tratamento
            )
            INCLUDE
            (
                entidade_origem,
                tabela_origem,
                id_staging,
                quantidade_motivos,
                data_rejeicao
            );

        CREATE NONCLUSTERED INDEX IX_rejeicao_registro_entidade_data
            ON rejeicao.registro_rejeitado
            (
                entidade_origem,
                data_rejeicao DESC
            )
            INCLUDE
            (
                chave_negocio,
                status_tratamento,
                nome_arquivo,
                numero_linha
            );

        PRINT N'Tabela rejeicao.registro_rejeitado criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela rejeicao.registro_rejeitado já existe.';
    END;


    /*=========================================================================
      3. TABELA: rejeicao.motivo_rejeicao

      Permite registrar vários motivos de rejeição para o mesmo registro.
    =========================================================================*/

    IF OBJECT_ID(N'rejeicao.motivo_rejeicao', N'U') IS NULL
    BEGIN
        CREATE TABLE rejeicao.motivo_rejeicao
        (
            id_motivo_rejeicao      BIGINT IDENTITY(1,1) NOT NULL,
            id_rejeicao             BIGINT NOT NULL,
            codigo_regra            VARCHAR(50) NOT NULL,
            nome_regra              NVARCHAR(200) NOT NULL,
            campo_origem            NVARCHAR(128) NULL,
            valor_original          NVARCHAR(1000) NULL,
            descricao_motivo        NVARCHAR(2000) NOT NULL,
            severidade              VARCHAR(20) NOT NULL
                CONSTRAINT DF_rejeicao_motivo_severidade
                DEFAULT 'ERRO',
            data_registro           DATETIME2(0) NOT NULL
                CONSTRAINT DF_rejeicao_motivo_data_registro
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_rejeicao_motivo_rejeicao
                PRIMARY KEY CLUSTERED (id_motivo_rejeicao),

            CONSTRAINT FK_rejeicao_motivo_registro
                FOREIGN KEY (id_rejeicao)
                REFERENCES rejeicao.registro_rejeitado (id_rejeicao),

            CONSTRAINT UQ_rejeicao_motivo_regra
                UNIQUE
                (
                    id_rejeicao,
                    codigo_regra,
                    campo_origem
                ),

            CONSTRAINT CK_rejeicao_motivo_severidade
                CHECK
                (
                    severidade IN
                    (
                        'ALERTA',
                        'ERRO',
                        'CRITICO'
                    )
                )
        );

        CREATE NONCLUSTERED INDEX IX_rejeicao_motivo_rejeicao
            ON rejeicao.motivo_rejeicao
            (
                id_rejeicao
            )
            INCLUDE
            (
                codigo_regra,
                nome_regra,
                campo_origem,
                severidade
            );

        CREATE NONCLUSTERED INDEX IX_rejeicao_motivo_regra
            ON rejeicao.motivo_rejeicao
            (
                codigo_regra,
                severidade,
                data_registro DESC
            )
            INCLUDE
            (
                nome_regra,
                campo_origem,
                descricao_motivo
            );

        PRINT N'Tabela rejeicao.motivo_rejeicao criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela rejeicao.motivo_rejeicao já existe.';
    END;


    /*=========================================================================
      4. TABELA: rejeicao.historico_tratamento

      Registra as ações realizadas sobre os registros rejeitados.
    =========================================================================*/

    IF OBJECT_ID(N'rejeicao.historico_tratamento', N'U') IS NULL
    BEGIN
        CREATE TABLE rejeicao.historico_tratamento
        (
            id_historico            BIGINT IDENTITY(1,1) NOT NULL,
            id_rejeicao             BIGINT NOT NULL,
            status_anterior         VARCHAR(20) NULL,
            status_novo             VARCHAR(20) NOT NULL,
            tipo_acao               VARCHAR(30) NOT NULL,
            descricao_acao          NVARCHAR(2000) NOT NULL,
            usuario_responsavel     NVARCHAR(128) NOT NULL
                CONSTRAINT DF_rejeicao_historico_usuario
                DEFAULT ORIGINAL_LOGIN(),
            data_acao               DATETIME2(0) NOT NULL
                CONSTRAINT DF_rejeicao_historico_data
                DEFAULT SYSDATETIME(),

            CONSTRAINT PK_rejeicao_historico_tratamento
                PRIMARY KEY CLUSTERED (id_historico),

            CONSTRAINT FK_rejeicao_historico_registro
                FOREIGN KEY (id_rejeicao)
                REFERENCES rejeicao.registro_rejeitado (id_rejeicao),

            CONSTRAINT CK_rejeicao_historico_status_anterior
                CHECK
                (
                    status_anterior IS NULL
                    OR status_anterior IN
                    (
                        'PENDENTE',
                        'EM_ANALISE',
                        'CORRIGIDO',
                        'DESCARTADO',
                        'REPROCESSADO'
                    )
                ),

            CONSTRAINT CK_rejeicao_historico_status_novo
                CHECK
                (
                    status_novo IN
                    (
                        'PENDENTE',
                        'EM_ANALISE',
                        'CORRIGIDO',
                        'DESCARTADO',
                        'REPROCESSADO'
                    )
                ),

            CONSTRAINT CK_rejeicao_historico_tipo_acao
                CHECK
                (
                    tipo_acao IN
                    (
                        'IDENTIFICACAO',
                        'ANALISE',
                        'CORRECAO',
                        'DESCARTE',
                        'REPROCESSAMENTO'
                    )
                )
        );

        CREATE NONCLUSTERED INDEX IX_rejeicao_historico_rejeicao_data
            ON rejeicao.historico_tratamento
            (
                id_rejeicao,
                data_acao DESC
            )
            INCLUDE
            (
                status_anterior,
                status_novo,
                tipo_acao,
                usuario_responsavel
            );

        PRINT N'Tabela rejeicao.historico_tratamento criada com sucesso.';
    END
    ELSE
    BEGIN
        PRINT N'A tabela rejeicao.historico_tratamento já existe.';
    END;


    COMMIT TRANSACTION;

    PRINT N'Estruturas da camada de rejeição criadas com sucesso.';

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

    PRINT N'Falha durante a criação das tabelas de rejeição.';
    PRINT N'Número do erro: ' + CONVERT(NVARCHAR(20), @numero_erro);
    PRINT N'Linha do erro: '  + CONVERT(NVARCHAR(20), @linha_erro);
    PRINT N'Mensagem: '       + @mensagem_erro;

    THROW;

END CATCH;
GO

/*=============================================================================
  5. CONSULTA DE CONFERÊNCIA
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
WHERE s.name = N'rejeicao'
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
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = N'rejeicao'
ORDER BY
    fk.name;
GO
