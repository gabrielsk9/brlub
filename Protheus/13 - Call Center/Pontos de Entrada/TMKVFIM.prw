#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TMKVFIM
(Ponto de entrada ao finalizar Atendimento Callcenter )
@author Marcelo Lauschner
@since 02/12/2013
@version 1.0
@return Sem retorno
@example
(User Function TMKVFIM(cNumAtend, cNumPedido)Alert('Passou pelo ponto de entrada TMKVFIM.')Return)
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6787791)
/*/
User Function TMKVFIM()
	
    DbSelectArea("SUA")
    // Se for Or�amento
	If	SUA->UA_OPER == "2"
		U_WFTMKORC()
	//	Se for Faturamento
	ElseIf	SUA->UA_OPER == "1"
		U_WFTMKPED()
	EndIf

	// Utilizado esse ponto de entrada pois quando a execu��o ocorre por execauto, o ponto de entrada n�o � executado
	DbSelectArea("SUA")
	If SUA->UA_OPER == "2" .and. IsInCallStack( 'U_ICGERPED' )
		U_BFFATA30(.T./*lAuto*/,SUA->UA_NUM/*cInPed*/,2/*nInPedOrc*/)	
	EndIf
	
	
Return
