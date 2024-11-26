#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATV03
(Fun��o de valida��o de edi��o dos campos de itens do pedido de venda. Valida��o edi��o quando for Combo)
@type function
@author marce
@since 19/12/2016
@version 1.0
@return lRet, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATV03()
	
	Local	cReadVar	:= ReadVar()
	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local	nPCodPrd	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local	nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2NUM"})
	Local	nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2LIN"})
	Local	cRegBoni	:= ""
	
	// Se a linha for derivada de Combo
	If nPRegBnf > 0 .And. !Empty(aCols[n][nPRegBnf])
		cRegBoni	:= Substr(aCols[n][nPRegBnf],1,6)
		// Se o c�digo do combo for v�lido ( n�o alterado pela fun��o TMKVDEL que zera o c�digo se o combo foi deletado)
		If cRegBoni <> "XXXXXX"
			If cReadVar == "M->C6_PRODUTO"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o c�digo de produto se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_OPER"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o tipo de opera��o se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_QTDVEN"
				lRet	:= .F.
				MsgStop("N�o � permitido editar a quantidade se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_XUPRCVE"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o pre�o de venda se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_PRCVEN"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o pre�o de venda se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALOR"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o valor total do produto se o mesmo � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_DESCONT"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o percentual de desconto se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALDESC"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o valor do desconto se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_TES"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o tipo de sa�da se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_CF"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o c�digo fiscal se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALOR"
				lRet	:= .F.
				MsgStop("N�o � permitido editar o valor total se o produto � derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif 
	Else
		If cReadVar == "M->C6_PRODUTO"
			If Substr(M->C6_PRODUTO,1,3) == "CB-" 
				lRet	:= .F.
				MsgStop("N�o � permitido digitar o c�digo de produto Combo diretamente neste campo. Voc� deve selecionar o Combo na fun��o espec�fica!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			// Chamado 24.376 - Valida que usu�rio n�o pode trocar o produto durante a digita��o 
			ElseIf M->C6_PRODUTO <> aCols[n,nPCodPrd] .And. !Empty(aCols[n,nPxPA2NUM]) .And. aCols[n,nPCodPrd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ") 
				lRet	:= .F.
				MsgStop("N�o � permitido alterar o c�digo de produto se o original digitado era um Granel. Voc� deve deletar este item do pedido e adicionar um novo item em nova linha!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif
	Endif
	RestArea(aAreaOld)
Return lRet