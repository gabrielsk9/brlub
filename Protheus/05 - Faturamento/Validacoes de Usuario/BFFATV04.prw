#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} BFFATV04
//Valida��o de usu�rio para os campos C5_BANCO / UA_BANCO 
@author Marcelo Alberto Lauschner
@since 17/08/2018
@version 1.0
@return logical , .F. / .T. 
@param cInBanco, characters, C�digo do banco 
@type function
/*/
User function BFFATV04(cInBanco)

	Local	lRet		:= .T. 
	Local	aAreaOld	:= GetArea()

	Default	cInBanco	:= ""

	If !IsBlind()
		
		// Se j� tem conte�do, apenas mant�m 
		If !Empty(cInBanco)
		
		// Sen�o valida conforme vari�vel posicionada	
		ElseIf ReadVar() == "M->C5_BANCO"
			cInBanco	:= M->C5_BANCO
		ElseIf ReadVar() == "M->UA_BANCO"
			cInBanco	:= M->UA_BANCO
		Endif

		// Verifica restri��o - Chamado 21.521 
		If cInBanco $ "900"
			If __cUserId $ GetNewPar("BF_FATV04A","000417#000180#000264#000077#000073") // Viviane/Thiago/Joice/Silvana/Leandro

			Else
				MsgAlert("Usu�rio sem permiss�o para usar o Banco '" + cInBanco + "'","BFFATV04 - Valida��o Portador!")
				lRet	:= .F. 
			Endif  
		Endif

	Endif

	RestArea(aAreaOld)


Return lRet