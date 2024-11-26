#include 'totvs.ch'

/*/{Protheus.doc} MALTCLI
PE executado ap�s a grava��o das altera��es do cliente quando a rotina n�o utilizar modelo MVC
@type function
@version 12.1.25
@author ICMAIS
@since 26/09/2020
@return return_type, Nil
/*/
User Function MALTCLI()
	
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall )  .And. GetNewPar("BL_ICMAIOK",.F.)

	// Manter o trexo de c�digo a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F. )
	EndIf
	
Return ( Nil )
