USE [DM_ESTUDO]
GO

/****** Object:  StoredProcedure [dbo].[SP_POPULA_STG_MAILING_WELCOME_FINAL]    Script Date: 27/12/2022 09:55:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SP_POPULA_STG_MAILING_WELCOME_FINAL]  AS

 DECLARE 
		@DATA_I AS datetime,
		@DATA_F AS datetime,
		@DATA_FINAL AS datetime


SET @DATA_I = (CONVERT(char(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0), 112))
SET @DATA_F = @DATA_I
SET @DATA_FINAL = CONVERT(varchar(12), GETDATE(), 112)

----CONSTRUINDO RECEBIDAS
----APAGA TABELA TEMPORÁRIA #RESUMO

TRUNCATE TABLE [DM_ESTUDO].[dbo].[TB_CHM_WC_ANALITICA_01]


WHILE @DATA_I <= @DATA_FINAL
BEGIN
  ----CRIA TABELA TEMPORÁRIA #RESUMO
  INSERT INTO [DM_ESTUDO].[dbo].[TB_CHM_WC_ANALITICA_01]
    SELECT
      TB.ROW_DATE,
      TB.TELEFONE,
      TB.ID_PRODUTO,
      TB.ID_SERVICO,
      TB.ID_GRUPO_RPT,
      RECEBIDAS = SUM(TB.ATENDIDAS + TB.ABANDONADAS),
      ATENDIDAS = SUM(TB.ATENDIDAS),
      ABANDONADAS = SUM(TB.ABANDONADAS)

    FROM (SELECT
      A.ROW_DATE AS ROW_DATE,
      CASE
        WHEN A.ID_PRODUTO IN (1, 4) THEN A.ASAIUUI
        ELSE A.TELEFONE
      END AS TELEFONE,           --INCLUIDO EM 09/09
      SSG.ID_SERVICO AS ID_SERVICO,
      SSG.ID_GRUPO_RPT AS ID_GRUPO_RPT,
      SUM(A.ATENDIDAS) AS ATENDIDAS,
      0 AS ABANDONADAS,
      A.ID_PRODUTO AS ID_PRODUTO
    FROM DM_PERFORMANCE..TB_ATENDIDAS A WITH (INDEX (IDX_ROW_DATE), NOLOCK)
    INNER JOIN DM_PERFORMANCE..TB_SUB_SEGMENTO SSG
      ON A.ID_SUB_SEGMENTO = SSG.ID_SUB_SEGMENTO
      AND SSG.ATIVO = 'S'
    WHERE A.ROW_DATE BETWEEN @DATA_I AND @DATA_F
    AND A.ASAIUUI > 0
    --  WHERE A.ROW_DATE BETWEEN '20210704' AND '20210408'
    AND ((A.ID_PRODUTO IN (1, 4)
    AND A.ASAIUUI > 0)
    OR (A.ID_PRODUTO = 2))   -- INCLUÍDO EM 09/09
    GROUP BY A.ROW_DATE,
             CASE
               WHEN A.ID_PRODUTO IN (1, 4) THEN A.ASAIUUI
               ELSE A.TELEFONE
             END,        --INCLUIDO EM 09/09
             SSG.ID_SERVICO,
             SSG.ID_GRUPO_RPT,
             A.ID_PRODUTO

    UNION ALL

    SELECT
      AB.ROW_DATE AS ROW_DATE,
      CASE
        WHEN AB.ID_PRODUTO IN (1, 4) THEN AB.ASAIUUI
        ELSE AB.TELEFONE
      END AS TELEFONE,        --INCLUIDO EM 09/09
      SSG.ID_SERVICO AS ID_SERVICO,
      SSG.ID_GRUPO_RPT AS ID_GRUPO_RPT,
      0 AS ATENDIDAS,
      SUM(AB.ABANDONADAS) AS ABANDONADAS,
      AB.ID_PRODUTO AS ID_PRODUTO
    FROM DM_PERFORMANCE..TB_ABANDONADAS AB WITH (INDEX (IDX_ROW_DATE), NOLOCK)
    INNER JOIN DM_PERFORMANCE..TB_SUB_SEGMENTO SSG
      ON AB.ID_SUB_SEGMENTO = SSG.ID_SUB_SEGMENTO
      AND SSG.ATIVO = 'S'
    --WHERE AB.ROW_DATE BETWEEN @DATA_I AND @DATA_F AND AB.ASAIUUI > 0              -- RETIRADO EM 09/09
    WHERE AB.ROW_DATE BETWEEN @DATA_I AND @DATA_F
    AND ((AB.ID_PRODUTO IN (1, 4)
    AND AB.ASAIUUI > 0)
    OR (AB.ID_PRODUTO = 2
    AND AB.TELEFONE > 0))   -- INCLUÍDO EM 09/09
    GROUP BY AB.ROW_DATE,
             CASE
               WHEN AB.ID_PRODUTO IN (1, 4) THEN AB.ASAIUUI
               ELSE AB.TELEFONE
             END,         --INCLUIDO EM 09/09
             SSG.ID_SERVICO,
             SSG.ID_GRUPO_RPT,
             AB.ID_PRODUTO) TB

    GROUP BY TB.ROW_DATE,
             TB.TELEFONE,
             TB.ID_PRODUTO,
             TB.ID_SERVICO,
             TB.ID_GRUPO_RPT

  SET @DATA_I = @DATA_I + 1
  SET @DATA_F = @DATA_I

END

----APAGA TABELA TEMPORÁRIA #RESUMO2
TRUNCATE TABLE [DM_ESTUDO].[dbo].[TB_CHM_WC_ANALITICA_02]


INSERT INTO [DM_ESTUDO].[dbo].[TB_CHM_WC_ANALITICA_02]
  SELECT 
    ID_CONTATO--DISTINCT ID_CONTATO
    ,
    M.TELEFONE,
    MAILING,
    SEGMENTO,
    PLANO,
    ORIGEM,
    MODALIDADE,
    STATUS_CONTRATO,
    CANAL_VENDA,
    VENCIMENTO,
    DATA_ATIVACAO,
    DATA_CARGA_TIM,
    PORTABILIDADE,
    B.ROW_DATE AS DT_ATENDIMENTO_CARGA_TIM,
    B.RECEBIDAS AS RECEBIDAS_CARGA_TIM,
    B.ATENDIDAS AS ATENDIDAS_CARGA_TIM,
    B.ABANDONADAS AS ABANDONADAS_CARGA_TIM
  FROM DM_ESTUDO.DBO.STG_MAILING_WELCOME_V2 AS M WITH (NOLOCK)
  LEFT JOIN [DM_ESTUDO].[dbo].[TB_CHM_WC_ANALITICA_01] AS B WITH (NOLOCK)
    ON M.TELEFONE = B.TELEFONE COLLATE LATIN1_GENERAL_CS_AS_KS_WS
    AND (
    CONVERT(datetime, B.ROW_DATE) >= CONVERT(datetime, '20210401', 112)
    AND CONVERT(datetime, B.ROW_DATE) < (CONVERT(datetime, '20210401', 112) + 190)
    )
  WHERE 1 = 1



----APAGA TABELA TEMPORÁRIA #RESUMO2
TRUNCATE TABLE STG_MAILING_WELCOME_ANALITICA

INSERT INTO STG_MAILING_WELCOME_ANALITICA
  SELECT DISTINCT
    ID_CONTATO,
    TELEFONE,
    MAILING,
    SEGMENTO,
    PLANO,
    ORIGEM,
    MODALIDADE,
    STATUS_CONTRATO,
    CANAL_VENDA,
    VENCIMENTO,
    DATA_ATIVACAO,
    DATA_CARGA_TIM,
    PORTABILIDADE,
    DATA_ENVIO,
    CANAL,
    TEMPLATE,
    STATUS1,
    DATA_ENTREGA,
    DATA_LEITURA,
    FLAG_ENTREGUE,
    DT_ATENDIMENTO_CARGA_TIM AS DT_ATENDIMENTO,
    RECEBIDAS_CARGA_TIM AS RECEBIDAS,
    ATENDIDAS_CARGA_TIM AS ATENDIDAS,
    ABANDONADAS_CARGA_TIM AS ABANDONADAS,
    DATEDIFF(DAY, CONVERT(datetime, @DATA_I, 112), DT_ATENDIMENTO_CARGA_TIM) AS TEMPO_CONTATO_CARGA_TIM,
    CASE
      WHEN FLAG_ENTREGUE = 1 THEN DATEDIFF(DAY, CONVERT(datetime, DATA_ENTREGA, 112), DT_ATENDIMENTO_CARGA_TIM)
    END AS TEMPO_CONTATO_ENTREGA
  FROM (SELECT
    M.ID_CONTATO,
    M.TELEFONE,
    M.MAILING,
    M.SEGMENTO,
    M.PLANO,
    M.ORIGEM,
    M.MODALIDADE,
    M.STATUS_CONTRATO,
    M.CANAL_VENDA,
    M.VENCIMENTO,
    M.DATA_ATIVACAO,
    M.DATA_CARGA_TIM,
    M.PORTABILIDADE,
    M.DT_ATENDIMENTO_CARGA_TIM,
    M.RECEBIDAS_CARGA_TIM,
    M.ATENDIDAS_CARGA_TIM,
    M.ABANDONADAS_CARGA_TIM,
    B.DATA_ENVIO,
    B.CANAL,
    B.TEMPLATE,
    B.STATUS1,
    B.DATA_ENTREGA,
    B.DATA_LEITURA,
    CASE
      WHEN M.DT_ATENDIMENTO_CARGA_TIM >= B.DATA_ENTREGA AND
        M.DT_ATENDIMENTO_CARGA_TIM < (B.DATA_ENTREGA + 60) THEN 1
      ELSE 0
    END FLAG_ENTREGUE
  FROM TB_CHM_WC_ANALITICA_02 AS M WITH (NOLOCK)
  LEFT JOIN (SELECT DISTINCT
    ID_CONTATO,
    TELEFONE,
    DATA_ENVIO,
    CANAL,
    TEMPLATE,
    STATUS1,
    DATA_ENTREGA,
    DATA_LEITURA
  FROM DM_ESTUDO.DBO.STG_MAILING_WELCOME_V2) B
    ON M.TELEFONE = B.TELEFONE) A


----POPULA STG_MAILING_WELCOME_FINAL
TRUNCATE TABLE STG_MAILING_WELCOME_FINAL

INSERT INTO STG_MAILING_WELCOME_FINAL 
  SELECT
    ID_CONTATO,
    TELEFONE,
    MAILING,
    SEGMENTO,
    PLANO,
    ORIGEM,
    MODALIDADE,
    STATUS_CONTRATO,
    CANAL_VENDA,
    VENCIMENTO,
    DATA_ATIVACAO,
    DATA_CARGA_TIM,
    PORTABILIDADE,
    DATA_ENVIO,
    CANAL,
    TEMPLATE,
    STATUS1,
    FLAG_ENTREGUE,
    SUM(RECEBIDAS) AS RECEBIDAS,
    SUM(ATENDIDAS) AS ATENDIDAS,
    SUM(ABANDONADAS) AS ABANDONADAS,
    SUM(TEMPO_CONTATO_CARGA_TIM) AS TEMPO_CONTATO_CARGA_TIM,
    COUNT(DT_ATENDIMENTO) AS QNT_DIAS_ATENDIDAS_CARGA_TIM,
    SUM(TEMPO_CONTATO_ENTREGA) AS TEMPO_CONTATO_ENTREGA,
    SUM(FLAG_ENTREGUE) AS QNT_DIAS_ATENDIDAS_ENTREGUE,
    QNT_REPETICOES

  FROM STG_MAILING_WELCOME_ANALITICA A
  LEFT JOIN (SELECT
    TELEFONE AS TEL,
    COUNT(*) AS QNT_REPETICOES
  FROM (SELECT DISTINCT
    ID_CONTATO,
    TELEFONE,
    MAILING,
    SEGMENTO,
    PLANO,
    ORIGEM,
    MODALIDADE,
    STATUS_CONTRATO,
    CANAL_VENDA,
    VENCIMENTO,
    DATA_ATIVACAO,
    DATA_CARGA_TIM,
    PORTABILIDADE,
    DATA_ENVIO,
    CANAL,
    TEMPLATE,
    STATUS1
  FROM DM_ESTUDO.DBO.STG_MAILING_WELCOME_V2) AS A
  GROUP BY TELEFONE) B
    ON A.TELEFONE = B.TEL
  GROUP BY ID_CONTATO,
           TELEFONE,
           MAILING,
           SEGMENTO,
           PLANO,
           ORIGEM,
           MODALIDADE,
           STATUS_CONTRATO,
           CANAL_VENDA,
           VENCIMENTO,
           DATA_ATIVACAO,
           DATA_CARGA_TIM,
           PORTABILIDADE,
           DATA_ENVIO,
           CANAL,
           TEMPLATE,
           STATUS1,
           FLAG_ENTREGUE,
           QNT_REPETICOES


--SELECT TOP 10 * FROM STG_MAILING_WELCOME_FINAL
GO