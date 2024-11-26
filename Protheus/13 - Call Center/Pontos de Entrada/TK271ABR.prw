#Include 'Protheus.ch'

/*/{Protheus.doc} TK271Abr
(Ponto de entrada para validar a abertura ou n�o do Atendimento)
	
@author MarceloLauschner
@since 10/12/2013
@version 1.0		

@return logico, 

@example
(examples)

@see (links_or_references)
/*/

User Function TK271ABR()

Local		lTipTlv	:=  TkGetTipoAte() $ "2" // Atendimento Televendas
Local		lRet		:=  .T.
Local		nInOpc		:= ParamIxb[1]			// Op��o aRotina
 
//lTK271Abr := ExecBlock("TK271ABR",.F.,.F.,{nOpc} )

If lTipTlv .And. nInOpc == 4 // Alterar
	If !Empty(SUA->UA_NUMSC5)
		MsgAlert("Este atendimento j� se transformou em pedido de venda!","Permiss�o Negada. 'TMK271ABR' ")
		lRet	:= .F.
	Endif
Endif
	
Return lRet

