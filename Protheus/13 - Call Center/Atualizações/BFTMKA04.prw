/*/{Protheus.doc} BFTMKA04
(Valida��o da condi��o de pagamento)
@author MarceloLauschner
@since 26/01/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFTMKA04()                 

	Local		aAreaOld	:= GetArea()
	Local		lRet		:= .T.                          
	Local		cCodPg		:= &(ReadVar())	                          

	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("BFTMKA04")
		Return .T. 
	Endif

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	DbSelectArea("SE4")
	DbSetOrder(1)
	If DbSeek(xFilial("SE4")+cCodPg)
		
	Endif      

	RestArea(aAreaOld)

Return lRet
