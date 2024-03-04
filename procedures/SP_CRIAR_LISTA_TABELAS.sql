/************************************************************************************************************************|
| ∙ Procedure:		  [SP_CRIAR_LISTA_TABELAS]														    				 |
| ∙ Data de Criação:  2024-02-23																	    				 |
| ∙ Autor:			  Raphael Coelho																    				 |
|																														 |
| ∙ Objetivo:		  Esta procedure opera na obtenção de uma lista de todas as tabelas físicas presentes no banco de	 |
|					  dados atual, disponibilizando essas informações em uma tabela temporária global. Ela utiliza a	 |
|					  stored procedure 'sp_msforeachdb', que itera por todos os bancos de dados disponíveis no servidor	 |
|					  conectado, extraindo e formatando os resultados para disponibilizar essas informações em uma 		 |
|					  tabela temporária global, incluindo o nome do servidor, banco de dados, esquema e nome da tabela.	 |
|																														 |
| ∙ Utilização:		  EXEC [SP_CRIAR_LISTA_TABELAS]													    				 |
| 					  SELECT * FROM ##LISTA_TABELAS													    				 |
| 														    															 |
*************************************************************************************************************************/

CREATE PROCEDURE [SP_CRIAR_LISTA_TABELAS]
AS
BEGIN
    /* ETAPA 1: RETORNA TODAS AS TABELAS DO BANCO */
	--DESATIVA A CONTAGEM DE LINHAS AFETADAS NO PAINEL DE RESULTADOS
    SET NOCOUNT ON

	--DECLARA UMA TABELA DE VARIÁVEIS PARA ARMAZENAR O CAMINHO DAS TABELAS
    DECLARE @LISTA_TABELAS TABLE (CAMINHO_COMPLETO NVARCHAR(4000) COLLATE DATABASE_DEFAULT)
    
    --INSERE OS CAMINHOS DAS TABELAS NA TABELA DE VARIÁVEIS USANDO A STORED PROCEDURE 'sp_msforeachdb'
    INSERT INTO @LISTA_TABELAS (CAMINHO_COMPLETO)
    EXEC sp_msforeachdb 'SELECT @@SERVERNAME+''.''+''?''+''.''+B.name+''.''+A.name COLLATE DATABASE_DEFAULT
                           FROM [?].sys.tables AS A
						  INNER JOIN sys.schemas AS B
                             ON A.schema_id=B.schema_id'
        
    /* ETAPA 2: GERA A TABELA FINAL */
	--VERIFICA SE A TABELA TEMPORÁRIA JÁ EXISTE E, SE SIM, A REMOVE
    IF OBJECT_ID ('tempdb..##LISTA_TABELAS') <> 0
    DROP TABLE ##LISTA_TABELAS

    --CRIA A TABELA FINAL COM OS DADOS DAS TABELAS ENCONTRADAS E OS ORDENA POR BANCO
    SELECT SUBSTRING(CAMINHO_COMPLETO, 1, CHARINDEX('.', CAMINHO_COMPLETO) - 1) AS NOME_SERVIDOR,
		   SUBSTRING(CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1) - CHARINDEX('.', CAMINHO_COMPLETO) - 1) AS NOME_BANCO,
		   SUBSTRING(CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1) + 1, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1) + 1) - CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1) - 1) AS NOME_SCHEMA,
		   SUBSTRING(CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO, CHARINDEX('.', CAMINHO_COMPLETO) + 1) + 1) + 1, LEN(CAMINHO_COMPLETO)) AS NOME_TABELA
      INTO ##LISTA_TABELAS
      FROM @LISTA_TABELAS
	 WHERE CAMINHO_COMPLETO NOT LIKE '%tempdb%'
     ORDER BY 1,2,3,4

	--ATIVA NOVAMENTE A CONTAGEM DE LINHAS AFETADAS NO PAINEL DE RESULTADOS
    SET NOCOUNT OFF

	--MENSAGEM DE RETORNO
	PRINT('')
	PRINT('EXECUTE A CONSULTA ABAIXO PARA UTILIZR A TABELA CRIADA.')
	PRINT('')
	PRINT('SELECT * FROM ##LISTA_TABELAS')
	PRINT('_______________________________________________________')
END
GO
