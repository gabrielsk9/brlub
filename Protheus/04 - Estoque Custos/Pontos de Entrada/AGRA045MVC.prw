#include 'totvs.ch'
#include 'fwmvcdef.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} AGRA045
PE modelo MVC do cadastro de Armazens
@type function
@version 12.1.25
@author ICMAIS
@since 19/09/2019
@return variadic, xRet
/*/
User Function AGRA045()

	Local aParam    := PARAMIXB
	Local xRet      := .T.
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)

	// Verifica se conseguiu receber valor do PARAMIXB
	If aParam <> NIL

		// Manter o trexo de c�digo a seguir no final do fonte
		If lPEICMAIS
			xRet := ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
		EndIf

	EndIf

Return ( xRet )
