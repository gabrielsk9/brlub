#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} FA100CA2
//TODO Ponto de entrada na Exclus�o/Estorno de movimento banc�rio
@author Marcelo Alberto Lauschner
@since 09/06/2019
@version 1.0
@return lRet, Logical , Retorna .T./.F. se o movimento poder� ser exclu�do ou estornado
@type User Function
/*/
User function FA100CA2()
	Local	lRet	:= .T.
	Local	nInOpc	:= ParamIxb[1]
	
	If nInOpc == 5 .And. !RetCodUsr() $ GetNewPar("BR_FA100US","000027#000002")  // Se for Exclus�o n�o permitir� movimento pois o sistema n�o est� excluindo o movimento corretamente
		MsgInfo("N�o � permitida fazer a exclus�o de Movimentos banc�rios. Use a op��o Cancelar, que ir� gerar um movimento de Estorno!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		lRet	:= .F. 
	Endif
	
Return lRet
