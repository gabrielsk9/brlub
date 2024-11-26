#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"

/*/{Protheus.doc} M410ALOK
Ponto de entrada que permite alterar ou n�o o pedido Venda
@type function
@version 12.1.33
@author Marcelo Alberto Lauschner
@since 04/12/2013
@return logical, .T. / .F. se permite alterar/incluir o pedido ou n�o
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784143)
/*/
User Function M410ALOK()

	Local	lVerTamb	:= .F.
	Local	nPedRemVs	:= 0
	Local	nPedOutr	:= 0 	
	Local 	lUserEstAvc	:= RetCodUsr() $ GetNewPar("BF_USR41OK","000130#000235#")
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410ALOK")
		Return .T. 
	Endif

	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+SC5->C5_NUM)
	While !Eof() .And. SC6->C6_NUM == SC5->C5_NUM
		If SC6->(FieldPos("C6_XPA2NUM")) > 0
			If !Empty(SC6->C6_XPA2LIN)
				lVerTamb	:= .T.
			Endif
		Endif
		If Alltrim(SC6->C6_CF) == "6920"
			nPedRemVs++ 
		Else
			nPedOutr++ 
		Endif
		DbSelectArea("SC6")
		DbSkip()
	Enddo 
	// Altera��o de pedido integrado com Iconic - Estoque Avan�ado 
	If ALTERA .And. SC5->(FieldPos("C5_XESTAVC")) > 0 .And. SC5->C5_XESTAVC == "S" .And. !lUserEstAvc  .And. SC5->C5_TIPO == "N"
		MsgInfo("Altera��o de pedido n�o permitida para pedidos j� integrados com a Iconic via rotina Estoque Avan�ado!","Altera��o n�o permitida")
		Return (.F.)
	// C�pia de pedido integrado com Iconic - Estoque avan�ado 
	ElseIf !ALTERA .And. INCLUI .And. SC5->(FieldPos("C5_XESTAVC")) > 0 .And.  SC5->C5_XESTAVC == "S"  .And. !lUserEstAvc .And. SC5->C5_TIPO == "N"
		MsgInfo("C�pia de pedido n�o permitida para pedidos j� integrados com a Iconic via rotina Estoque Avan�ado!","C�pia n�o permitida")
		Return (.F.)
	
	ElseIf !ALTERA .And. INCLUI .And. lVerTamb
		MsgInfo("C�pia de pedido n�o permitida por que o pedido cont�m vinculo com tambores","C�pia n�o permitida")
		Return (.F.)

	ElseIf !ALTERA .And. INCLUI .And. SC5->C5_CLIENTE+SC5->C5_LOJACLI $ "01058901#00047204#9572  01#"
		MsgInfo("C�pia de pedido!","C�pia permitida!")
		Return (.T.)

	ElseIf !ALTERA .And. INCLUI .And. (nPedOutr == 0 .And. nPedRemVs > 0 )
		MsgInfo("C�pia de pedido permitida !","C�pia permitida!")		
		Return (.T.)
	
	ElseIf lUserEstAvc //__cUserId $ "000235#000300#000482"	// Exce��o para os usu�rios da Escrita fiscal -- Atualizado em 13/07/2017 Cristian/Vera
		Return (.T.)

	ElseIf !ALTERA .And. INCLUI .And. SC5->C5_EMISSAO < Date()-7 .and. !lUserEstAvc
		MsgInfo("N�o � permitido fazer c�pia de pedido de venda digitado a mais de 7 dias."+;
		"Ser� necess�rio fazer a digita��o manual do pedido por motivos de calculos fiscais!","C�pia n�o permitida!")
		Return (.F.)

	ElseIf ALTERA .And. SC5->C5_BLPED $ "S#M"
		Alert("Pedido enviado para faturamento, n�o pode ser alterado!!-M410ALOK")
		Return(.F.)

	ElseIf !ALTERA .And. !INCLUI
		// Pergunta e auto estorno implementados em 17/08/2010 para resolver problema dos pedidos antecipados.
		If __cUserId $ GetMv("GM_M410EXC")
			If !MsgYesNo("Deseja realmente estornar a libera��o do pedido e excluir o pedido?","A T E N � � O!!")
				Return .F.
			Endif
			DbSelectArea("SC9")
			DbSetOrder(1)
			DbSeek(xFilial("SC9")+SC5->C5_NUM)
			While ( !Eof() .And.C9_FILIAL == xFilial("SC9") .And.;
			C9_PEDIDO == SC5->C5_NUM)
				If ( C9_BLCRED != '10' .And. C9_BLEST != '10')
					SC9->(A460Estorna())
				EndIf
				dbSelectArea("SC9")
				dbSkip()
			EndDo
			Return(.T.)
		Else
			MsgAlert("Voc� n�o tem autoriza��o para efetuar exclus�o de pedidos","Permiss�o negada!")
			Return(.F.)

		Endif

	ElseIf ALTERA .And. SC5->C5_BLPED == "F" .And. !(__cUserId $ GetMv("BF_USRSERA"))
		Alert("Pedido bloqueado pelo Financeiro! Solicite ao Departamento Financeiro o desbloqueio do Pedido!!-M410ALOK")
		Return(.F.)

	ElseIf ALTERA .And. SC5->C5_BLPED <> " " .And. SC5->C5_BANCO == "987" .And. !(__cUserId $ GetMv("BF_USRSERA"))
		Alert("Pedido do Tipo 'Pagamento Antecipado! Solicite ao Departamento Financeiro a altera��o que precisar ser efetuada!!-M410ALOK")
		Return(.F.)

	Elseif ALTERA .And. SC5->C5_BLPED == "I"
		Alert("Saldo de pedido, favor informar liberador(a) ap�s altera��o!!-M410ALOK")
		Return(.T.)

	Elseif SC5->C5_BLPED == "X"
		Return(.T.)

	Elseif SC5->C5_BLPED == "N"
		Return(.T.)

	Elseif SC5->C5_BLPED == ' '
		Return(.T.)

	ElseIf ALTERA .And. SC5->C5_BLPED == "F" .And. (__cUserId $ GetMv("BF_USRSERA"))
		Alert("Pedido bloqueado pelo Financeiro! Permiss�o concedida a usu�rios do Financeiro!-M410ALOK")
		Return(.T.)

	ElseIf ALTERA .And. SC5->C5_BLPED <> " " .And. SC5->C5_BANCO == "987" .And. (__cUserId $ GetMv("BF_USRSERA"))
		Alert("Pedido do Tipo 'Pagamento Antecipado! Verifique se j� houve pagamento/dep�sito para este pedido antes de alterar!!-M410ALOK")
		Return(.F.)

	Endif

Return .T.
