#Include 'Protheus.ch'


/*/{Protheus.doc} BFFATA35
(long_description)
@author MarceloLauschner
@since 03/06/2014
@version 1.0
@param cZ9ORIGEM, character, (Descri��o do par�metro)
@param cZ9NUM, character, (Descri��o do par�metro)
@param cZ9EVENTO, character, (Descri��o do par�metro)
@param cZ9DESCR, character, (Descri��o do par�metro)
@param cZ9SMAIL, character, (Descri��o do par�metro)
@param cZ9DEST, character, (Descri��o do par�metro)
@param cZ9USER, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA35(cZ9ORIGEM,cZ9NUM,cZ9EVENTO,cZ9DESCR,cZ9DEST,cZ9USER,cZ9PRCRET)
	
	Local	aAreaOld	:= GetArea()
	Default	cZ9DEST		:= ""
	Default	cZ9USER		:= ""
	Default	cZ9PRCRET	:= ""
	
	DbSelectArea("SZ9")
	RecLock("SZ9",.T.)
	SZ9->Z9_FILIAL	:= xFilial("SZ9")
	SZ9->Z9_ORIGEM	:= cZ9ORIGEM
	SZ9->Z9_NUM		:= cZ9NUM
	SZ9->Z9_DATA	:= Date()
	SZ9->Z9_HORA	:= Time()
	SZ9->Z9_EVENTO	:= cZ9EVENTO
	SZ9->Z9_DESCR	:= cZ9DESCR
	SZ9->Z9_DEST	:= cZ9DEST
	SZ9->Z9_USER	:= cZ9USER
	SZ9->Z9_PRCRET	:= cZ9PRCRET
	MsUnlock()
	RestArea(aAreaOld)
	
Return

/*/{Protheus.doc} sfRetOpc
(Retornar lista de op��es de followup de pedidos)
@author MarceloLauschner
@since 03/06/2014
@version 1.0
@param cInOpc, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRetOpc(cInOpc)
	
	Local	aOpcRet	:= {	{"1","1-Envio de e-mail para aprova��o"},;
		{"2","2-Follow-up de comunica��o"},;
		{"3","3-Rejei��o de libera��o de Pedido"},;
		{"4","4-Aprova��o e libera��o de Pedido"},;
		{"5","5-Libera��o Pedido"},;
		{"6","6-Envio de Workflow"},;
		{"7","7-Libera��o Autom�tica Pedido-Callcenter"},;
		{"8","8-Solicita��o de Al�ada Price"},;
		{"9","9-Solicita��o de Al�ada Diretoria"}}
	Local	nV 
	 	
	For nV	:= 1 To Len(aOpcRet)
		If aOpcRet[nV,1] == cInOpc
			Return aOpcRet[nV,2]
		Endif
	Next
	
Return ""

