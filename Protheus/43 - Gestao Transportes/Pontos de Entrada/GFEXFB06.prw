/*/{Protheus.doc} GFEXFB06
Ponto de entrada GFE - Altera vari�vel para n�o exibir regua de processamento 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/08/2022
@return variant, return_description
/*/
User Function GFEXFB06


    // Ponto de entrada para permitir a emiss�o de mensagem na gera��o
	// autom�tica de romaneio a partir cria��o de embarque no ERP
	//If ExistBlock("GFEXFB06")
    //lRet := ExecBlock("GFEXFB06",.F.,.F.,{aAgrFrt[1][2], aAgrFrt[1][5]})
	//EndIf

    lHideProcess    := .T. 
	

Return .T.
