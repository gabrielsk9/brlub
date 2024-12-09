#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} FA60FIL
(Ponto de entrada para filtrar t�tulos baseado no nome do Banco)
@author MarceloLauschner
@since 27/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FA60FIL()
	
	Local cRet    := ""
	local lMVBLEM := SuperGetMV( 'MV_X_BLEM' ,,.T. ) // Par�metro para indicar se o sistema deve considerar apenas t�tulos cujo boleto j� esteja emitido
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	cRet	:= "SE1->E1_PORTADO == '" + SA6->A6_COD + "' .And. SE1->E1_AGEDEP == '" + SA6->A6_AGENCIA + "' .And. SE1->E1_CONTA == '" + SA6->A6_NUMCON +  "'"
	// JEAN - 20/07/2022 - Filtra apenas t�tulos cujo boleto j� est� emitido (com nosso n�mero gravado)
	if lMVBLEM
		cRet += " .and. !Empty(SE1->E1_NUMBCO) "
	endif
	
Return(cRet)
