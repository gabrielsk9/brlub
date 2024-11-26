
/*/{Protheus.doc} TMKVHO
(P.E. para impedir carregar orcamento que j� gerou pedido )
	
@author MarceloLauschner
@since 28/03/2011
@version 1.0
		
@param cNumPed, character, (Descri��o do par�metro)

@return logico, impede carga do pedido na tela

@example
(examples)

@see (links_or_references)
/*/
User Function TMKVHO(cNumPed)

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.

	DbSelectArea("SUA")
	DbSetOrder(1)
	If Dbseek(xFilial("SUA")+cNumPed)
		If !Empty(SUA->UA_NUMSC5)
			MsgAlert("Este atendimento j� se transformou em pedido de venda. N�o � mais permitido alterar!","Permiss�o Negada. 'TMKVHO' ")
			lRet	:= .F.
		Endif
	Endif

	RestArea(aAreaOld)

Return (lRet)
