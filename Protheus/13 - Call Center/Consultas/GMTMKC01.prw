#include "topconn.ch"

/*/{Protheus.doc} GMTMKC01
(Localiza �tlimo registro de compra do cliente do produto )

@author MarceloLauschner
@since 18/05/2012
@version 1.0

@return numerico, Valor do �ltimo pre�o de venda do produto X cliente
@example
(examples)

@see (links_or_references)
/*/
User Function GMTMKC01()
	
	Local	nUltPrc		:= 0
	Local	aAreaOld	:= GetArea()
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	If Type("lProspect") <> "U" .And. !lProspect
		Processa({ || sfSearch(@nUltPrc) } ,"Localizando �ltimo pre�o de venda...")
	Endif
	
	RestArea(aAreaOld)
	
Return nUltPrc


/*/{Protheus.doc} sfSearch
(Localiza �tlimo registro de compra do cliente do produto )

@author MarceloLauschner
@since 05/03/2014
@version 1.0

@param nInUltPrc, numerico, (Descri��o do par�metro)

@return num�rico, valor do �ltimo pre�o do produto X cliente

@example
(examples)

@see (links_or_references)
/*/
Static Function sfSearch(nInUltPrc )
	
	Local	cQry		:= ""
	
	If ReadVar() <> "M->UB_PRODUTO" .Or. Type("M->UB_PRODUTO") <> "C"
		Return
	Endif
	
	
	// Delay for�ado para for�ar tmk a ver que est� consultando ultimo pre�o
	//Sleep(2000)
	
	cQry += "SELECT D2_PRCVEN "
	cQry += "  FROM "+RetSqlName("SD2") + " D2, " + RetSqlName("SF4") + " F4 "
	cQry += " WHERE F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4_CODIGO = D2_TES "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4") + "' "
	cQry += "   AND D2_EMISSAO >= TO_CHAR(SYSDATE-90,'YYYYMMDD') "
	cQry += "   AND D2_COD = '"+M->UB_PRODUTO+"' "
	cQry += "   AND D2_CLIENTE = '"+M->UA_CLIENTE+"' "
	cQry += "   AND D2_LOJA = '"+M->UA_LOJA+"' "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
	cQry += " ORDER BY D2_EMISSAO DESC,D2_DOC DESC "
	
	TCQUERY cQry NEW ALIAS "QSD2"
	If !Eof()
		nInUltPrc 	:= QSD2->D2_PRCVEN
	Endif
	QSD2->(DbCloseArea())
	
Return
