#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"
//--------------------------------+
// Favor Documentar altera��es.   |
// Data - Analista - Descri��o	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo revisado
//
//-------------------------------------------------------------------------------------------------

/*/{Protheus.doc} A410EXC
(Registrar no Z0 a hora de exclus�o do Pedido)
@author MarceloLauschner
@since 04/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function A410EXC()

	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������ͻ��
	���Programa �A410EXC � Autor � Rafael Meyer          � Data �  03/08/07   ���
	�������������������������������������������������������������������������͹��
	���Descricao � Registrar no Z0 a hora de exclus�o do Pedido               ���
	���          �                                                            ���
	�������������������������������������������������������������������������͹��
	���Uso       � Sigafat                                                    ���
	�������������������������������������������������������������������������ͼ��
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("A410EXC")
		Return .T. 
	Endif

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	// Grava Log
Return U_GMCFGM01("EP",SC5->C5_NUM,,FunName(),.T.)[2]

