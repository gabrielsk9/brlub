#Include 'Protheus.ch'

/*/{Protheus.doc} TMKDADOS
(Ponto de entrada para validar tela de condi��o de pagamento e transportadora)
@type function
@author marce
@since 21/12/2016
@version 1.0
@param cCodPagto, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TMKDADOS(cCodPagto)
	
	Local	lRet	:= .T.

	If Type("cCondOld") <> "U" .And. cCodPagto <> cCondOld
		MsgAlert("A condi��o de pagamento foi modificada! Favor manter a condi��o '"+cCondOld + "'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Altera��o de Condi��o Pagamento!")		
		Return .F.
	ElseIf Type("M->UA_CONDPG") <> "U" .And. cCodPagto <> M->UA_CONDPG
		MsgAlert("A condi��o de pagamento foi modificada! Favor manter a condi��o '"+M->UA_CONDPG + "'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Altera��o de Condi��o Pagamento!")		
		Return .F.
	Endif

	
Return lRet

