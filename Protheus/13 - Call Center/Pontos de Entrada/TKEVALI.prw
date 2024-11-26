#Include 'Protheus.ch'

/*/{Protheus.doc} TKEVALI
(Valida��o da linha dos produtos na tela de atendimento televendas)
@author MarceloLauschner
@since 05/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TKEVALI()
	
	Local	aAreaOld		:= GetArea()
	Local	aAreaSB1		:= SB1->(GetArea())
	Local 	nPProd    		:= aPosicoes[1][2]					// Posicao do Produto
	Local 	nPQtd     		:= aPosicoes[4][2]					// Posicao da Quantidade
	Local 	nPVrUnit  		:= aPosicoes[5][2]					// Posicao do Valor Unitario
	Local 	nPVlrItem 		:= aPosicoes[6][2]					// Posicao do Valor do item
	Local 	nPTes	    	:= aPosicoes[11][2]					// Posicao do Tes
	Local 	lRetPe     		:= .T.								// Retorno da funcao
	Local 	nValAnt4		:= M->UA_DESC4						// Valor anterior do desconto em cascata
	Local 	nValAnt3		:= M->UA_DESC3						// Valor anterior do desconto em cascata
	Local 	nValAnt2		:= M->UA_DESC2						// Valor anterior do desconto em cascata
	Local 	nValAnt1		:= M->UA_DESC1						// Valor anterior do desconto em cascata
	Local	lIsAuto			:= IsBlind()
	Local	nPPrcMax		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
	Local	nPPrcMin		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	Local	nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
	Local	nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRCTAB"})
	Local	nPxComis1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
	Local	nPxComis2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
	Local	nPxComis3		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS3"})
	Local	nPRegBnf		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	Local	nPxFlex			:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
	Local	nPVlrTampa		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
	Local	nPosLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_LOCAL"})
	Local	nCF				:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_CF"})
	Local	aContLocal	:= {0,0}	// Posi��o 1 - Armaz�m 01 / Posi��o 2  - Armaz�m 02
	Local	nPosLin			:= 1
	Local	nX
	Local	nMxFor			:= 0
	Local	cVend1			:= ""
	Local	cVend2			:= ""
	Local	cVend3			:= M->UA_VEND03 //SA1->A1_VEND03
	Local	nPComis1 		:= 0
	Local	nPComis2 		:= 0
	Local	nPComis3 		:= 0
	Local	nPxPA2NUM		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2NUM"})
	Local	nPxPA2LIN		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2LIN"})
	Local	cCfopTransf		:= "659/658/557/552/409/408/209/208/156/155/152/151" // V�lido para Cfops iniciados com 5 e 6 ( 5659/6659 5658/6658 etc.)
	Local	nSumVolum		:= 0
	Local   cMV_ESTADO		:= GetMv("MV_ESTADO")
	Local 	iX 

	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If Type("cCondOld") == "U"
		Public 	cCondOld	:= M->UA_CONDPG
	Endif
	
	If !U_BFCFGM25("TKEVALI")
		RestArea(aAreaOld)
		Return .T. 
	Endif
	
	
	
	If RetCodUsr() $ GetNewPar("BF_USAVEN3","000000")
		cVend1	:= M->UA_VEND
		cVend2	:= Posicione("SA3",1,xFilial("SA3")+cVend1,"A3_ACESSOR")
	Else
		cVend1	:= M->UA_VEND
		cVend2	:= Posicione("SA3",1,xFilial("SA3")+cVend1,"A3_ACESSOR")
	Endif
	
	// Se o Vendedor 2 for o pr�prio vendedor n�o ir� retornar valor de comiss�o
	If cVend2 == cVend1
		cVend2 := ""
	Endif
	// 09/03/2018 - Sumarizo os volumes do pedido
	For iX := 1 To Len(aCols)
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+aCols[iX][nPProd])
			If SB1->B1_PROC == "000468" .And. aCols[iX][nPQtd] > 0
				nSumVolum	+= (aCols[iX][nPQtd] * SB1->B1_QTELITS ) / 20 
			Endif
		Endif 
	Next
	RestArea(aAreaSB1)
	
	// Se for valida��o do cabe�alho- ir� validar todas as linhas
	If FwIsInCallStack("TK273GETOK")
		nMxFor		:= Len(aCols)
		
		// Deleta automaticametne a linha pois usu�rio n�o tem capacidade de interpretar o erro e faltou treinamento
		// Chamado 22.975 
		If Val(M->UA_OPER) == 3 // Atendimento
			For nX	:= nPosLin To nMxFor
				If Empty(aCols[nX][nPProd])
					aCols[nX][Len(aHeader)+1]	:= .T. 
				Endif
			Next nX 
		Endif
		
		// IAGO 23/06/2015 Chamado(11396)
		If !lIsAuto .And. Empty(cVend1) .and. Val(M->UA_OPER) <> 1
			MsgAlert("Campo de vendedor n�o est� preenchido, favor verificar o cadastro do cliente!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Sem vendedor!")
		EndIf
		
		If !lIsAuto .And. !Empty(M->UA_OPER) .And. Val(M->UA_OPER) == 1 // 1=Faturamento
			If (dDataBase - M->UA_EMISSAO) > 14
				MsgAlert("Este or�amento j� est� emitido h� mais de 14 dias no sistema. N�o ser� poss�vel converter o mesmo em Pedido de Venda! Favor incluir novo or�amento para gerar um novo processo de libera��o de al�adas",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Or�amento expirou!")
				lRetPe	:= .F.
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Este or�amento j� est� emitido h� mais de 14 dias no sistema. N�o ser� poss�vel converter o mesmo em Pedido de Venda! Favor incluir novo or�amento para gerar um novo processo de libera��o de al�adas" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Endif
		Endif
		
		// 30/09/2018 - Valida que seja informado obrigatoriamente o n�mero da Ordem de Compra
		If M->UA_CLIENTE $ "013581"
			If Empty(M->UA_XPEDCLI) .Or. Len(Alltrim(M->UA_XPEDCLI)) <> 10 
				If !lIsAuto
					MsgAlert("Pedido digitado para um cliente 'Dpaschoal' e n�o foi informado o campo 'O.C. Cliente' com 10 d�gitos. Favor preencher e Confirmar novamente!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					lRetPe	:= .F.
				Else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Pedido digitado para um cliente 'Dpaschoal' e n�o foi informado o campo 'O.C. Cliente' com 10 d�gitos. Favor preencher e Confirmar novamente!" +ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Endif
			Endif
		Endif
				
		// 06/07/2016 - Calculo de comiss�o baseado em desconto m�dio do pedido
		// Efetua o calculo de comiss�es
		U_BFFATM32(.F./*lIsSC5*/,.T./*lIsSUA*/,cVend1/*cInVend1*/,cVend2/*cInVend2*/,aCols/*aInAcols*/,M->UA_CLIENTE/*cInCli*/,M->UA_LOJA/*cInLoja*/,M->UA_EMISSAO/*dInEmissao*/)
		
	Else
		// Somente valida a linha em quest�o
		nPosLin		:= N
		nMxFor		:= nPosLin
	Endif
	
	For nX	:= nPosLin To nMxFor
		
		If !aCols[nX][Len(aHeader)+1]
			If  !Empty(M->UA_OPER) .And. Val(M->UA_OPER) <> 3  // 1=Faturamento;2=Orcamento;3=Atendimento
				If 	Empty(aCols[nX][nPProd]) 	.Or. Empty(aCols[nX][nPVrUnit]) .Or. Empty(aCols[nX][nPTes])
					Help(" ",1,"A010VAZ")
					lRetPe := .F.
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Produto, Valor unit�rio ou tes em branco ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Endif
			Endif
			If Val(M->UA_OPER) <> 3	// Se n�o for atendimento -
				// Efetua as valida��es
				// Se o CFOP do Item for de Transfer�ncia de mercadoria n�o valida pre�o m�nimo e m�ximo
				// 29/09/2017 - Chamado 19.040 
				If lRetPe .And. Substr(aCols[nX][nCF],2,3) $ cCfopTransf
					// Nenhuma a��o necess�ria
				
				ElseIf lRetPe .And. Round(aCols[nX][nPVrUnit],2) < Round(aCols[nX][nPPrcMin],2)
					// Se estiver na menor faixa de pre�o e for or�amento, exibir� apenas alerta sem bloqueio
					If aCols[nX][nPCodTab] $ "M01#0AA#T07#T14#T21#T28#T35#T42#T49#T56#T63#T70" .And. Val(M->UA_OPER) == 2//Orcamento
						If !lIsAuto
							MsgAlert("O produto '"+aCols[nX][nPProd]+"' est� ABAIXO do pre�o m�nimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " para a faixa de volumes na tabela '"+aCols[nX][nPCodTab]+"'! Sujeito a libera��o de al�adas!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pre�o abaixo do m�nimo desta faixa!")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/,"TKEVALI.PRW - Valor digitado " + cValToChar(Round(aCols[nX][nPVrUnit],2)) + " - Valor minimo " + cValToChar(Round(aCols[nX][nPPrcMin],2)) + " - Valor M�ximo " + cValToChar( Round(aCols[nX][nPPrcMax],2)) /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						// 21/09/2015 - Permite que Granel passe na valida��o de pre�o abaixo da 0AA mesmo como 1-Faturamento
					ElseIf aCols[nX][nPCodTab] $ "M01#0AA" .And. Val(M->UA_OPER) == 1 .And. aCols[nX][nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
						If !lIsAuto
							MsgAlert("O produto '"+aCols[nX][nPProd]+"' est� ABAIXO do pre�o m�nimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " para a faixa '0AA' ou 'M01'! Sujeito a libera��o de al�adas!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pre�o abaixo do m�nimo desta faixa!")
						Endif
					Else
						If !lIsAuto
							MsgAlert("O pre�o digitado do produto '"+aCols[nX][nPProd]+"' est� ABAIXO do pre�o m�nimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de pre�os!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pre�o abaixo do m�nimo desta faixa!")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - O pre�o digitado do produto '"+aCols[nX][nPProd]+"' est� ABAIXO do pre�o m�nimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de pre�os! " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				ElseIf lRetPe .And. Round(aCols[nX][nPVrUnit],2) > Round(aCols[nX][nPPrcMax],2)
					If !lIsAuto
						MsgAlert("O pre�o digitado do produto '"+aCols[nX][nPProd]+"' est� ACIMA do pre�o m�ximo R$ " + Transform(aCols[nX][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de pre�os!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pre�o acima do m�ximo desta faixa!")
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW - O pre�o digitado do produto '"+aCols[nX][nPProd]+"' est� ACIMA do pre�o m�ximo R$ " + Transform(aCols[nX][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de pre�os!" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Endif
					lRetPe	:= .F.
				Endif
				
				If aCols[nX,nPosLocal] == "01"
					aContLocal[1] += 1
				ElseIf aCols[nX,nPosLocal] == "02"
					aContLocal[2] += 1
				Endif
				
				If aContLocal[1] > 0 .And. aContLocal[2] > 0
					If !lIsAuto
						MsgAlert("Este pedido cont�m produtos digitados em armaz�ns diferentes. A digita��o deve ser feita somente usando o mesmo armaz�m para todos os itens ou em pedidos separados OBRIGATORIAMENTE!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Armaz�ns diferentes n�o permitidos!")
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW - Este pedido cont�m produtos digitados em armaz�ns diferentes. A digita��o deve ser feita somente usando o mesmo armaz�m para todos os itens ou em pedidos separados OBRIGATORIAMENTE!!" = ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Endif
					lRetPe	:= .F.
				Endif
				// 30/04/2017 - Chamado 18042 - Validar CFOP na digita��o do or�amento tamb�m. 
				DbSelectArea("SA1")
				DbSetOrder(1)
				MsSeek(xFilial("SA1")+M->UA_CLIENTE+M->UA_LOJA)
				If SA1->A1_EST $ cMV_ESTADO
					If aCols[nX][nCF] > "6000"
						If !lIsAuto
							MsgAlert("CFOP inv�lido para o produto '"+aCols[nX][nPProd]+"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Cfop")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - CFOP inv�lido para o produto '"+aCols[nX][nPProd]+"'" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				Else
					If aCols[nX][nCF] < "6000"
						If !lIsAuto
							MsgAlert("CFOP inv�lido para o produto '"+aCols[nX][nPProd]+"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Cfop")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - CFOP inv�lido para o produto '"+aCols[nX][nPProd]+"'" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				Endif
				
				
			Endif
			// 28/10/2016 - Chamado 16236 - Calcular ST for�ado para produto bonificado PR
			If lRetPe .And. cFilAnt == "03" .And. aCols[nX][nPProd] == Padr("42100300",TamSX3("UB_PRODUTO")[1]) .And. M->UA_TIPOCLI == "R"
				MsgAlert("Foi encontrado o produto '42100300' digitado neste pedido/or�amento e o campo 'Tipo de Cliente' precisa ser alterado para 'S-Solid�rio' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Tipo de cliente incorreto!")
				lRetPe	:= .F.
			Endif
		Endif
	Next
	RestArea(aAreaOld)
	
	
Return lRetPe

