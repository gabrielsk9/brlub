#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFFATG14
// Valida��o para executar gatilhos do SA1
@author Marcelo Alberto Lauschner
@since 04/03/2019
@version 1.0
@return Logical - Retorna se o Gatilho deve ser executado ou n�o
@type function
/*/
User function BFFATG14()
	
	Local	lRet	:= .F. 
	
	// Se for Altera��o de cliente e o usu�rio n�o estiver no par�metro de usu�rios permitidos
	// Retorna .T. para executar o Gatilho dos campos 
	If ALTERA .And. !(RetCodUsr() $ GetNewPar("BF_SA1_USR","000000"))
		// Se o limite de cr�dito ainda 
		If SA1->A1_LC > 2
			M->A1_VALREMB	:= SA1->A1_LC
		Endif
		lRet	:= .T. 
	Endif
	
Return lRet	