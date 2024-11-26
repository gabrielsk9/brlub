#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MTVLDACE
//Efetua valida��o de acesso a rotina de Banco de Conhecimento
@author Marcelo A Lauschner
@since 22/10/2017
@version 6

@type function
/*/
User function MTVLDACE()

	Local	lRet	:= .T.
	// Se for na rotina de Cadastro de Clientes ou Consulta Especifica
	If IsInCallStack("MATA030") .Or. IsInCallStack("U_FC010CON")
		If !(__cUserId $ GetMv("BF_USRSERA")) 
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
							{"Rotina com restri��o de informa��es financeiras.",;
							"Dados inseridos pelo financeiro n�o estar�o vis�veis."},;
							5,;
							{"Verificar junto com Financeiro necessidade",;
							"de acesso � alguma informa��o espec�fica."},;
							5) 
		Endif
	Endif
	
Return lRet