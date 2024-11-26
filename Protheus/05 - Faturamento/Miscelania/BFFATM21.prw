#Include 'Protheus.ch'



/*/{Protheus.doc} BFFATM21
(Rotina de valida��o de al�adas unificada)
@author MarceloLauschner
@since 11/09/2014
@version 1.0
@param cInTipo, character, (Tipo de Origem SC5 / MC5 / SUA / MUA)
@param nTotDup, num�rico, (Valor de Duplicata)
@param nTotPed, num�rico, (Valor Total)
@param nPrzMed, num�rico, (Prazo m�dio)
@param cDescE4, character, (Descri��o Condi��o Pagamento)
@param aInCols, array, (aCols do processo)
@param aInHeader, array, (aHeader do processo)
@param cRetAlc, character, (Retorno dos bloqueios de Al�adas)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM21(cInTipo,nTotDup,nTotPed,nPrzMed,cDescE4,aInCols,aInHeader,cRetAlc,aMotBloq,nInCusFrete)
	
	Local		aAreaOld	:= GetArea()
	Local		nQteParc	:= 0
	Local		nDias		:= 0
	Local		cNumPed		:= ""
	Local		cCondPag	:= ""
	Local		nPercent	:= 1.00066030548229
	Local		dData1		:= CTOD("")
	Local		dData2		:= CTOD("")
	Local		dData3		:= CTOD("")
	Local		dData4		:= CTOD("")
	Local		dEmissao	:= dDataBase
	Local		cVend1		:= ""
	Local		cVend2		:= ""
	Local		cCliente	:= ""
	Local		cLoja		:= ""
	Local		cTransp		:= ""
	Local		cReemb		:= ""
	Local		cMsgInt		:= ""
	Local		cPedPalm	:= ""
	Local		iQ
	Local		nItFis		:= 0	// Vari�vel necess�ria para posicionar registro do MafisRet
	Local		nPxItem		:= 0
	Local		nPxProd		:= 0
	Local		nPxTes		:= 0
	Local		nPxCfop		:= 0
	Local		nPxPrcVen	:= 0
	Local		nPxPrcTab	:= 0
	Local		nPxQtdVen	:= 0
	Local		nPxComis1	:= 0
	Local		nPxComis2	:= 0
	Local		nPxLocal	:= 0
	Local		nPxFlgAlc	:= 0
	Local		nPxLibAlc	:= 0
	Local		nPxCodTab	:= 0
	Local		nPxPrcMax	:= 0
	Local		nPxPrcMin	:= 0
	Local		nPVlrTampa	:= 0
	Local		nPxFlex		:= 0
	Local		nVlrMg1		:= 0
	Local		nPerMg1		:= 0
	Local		nTotMg1		:= 0
	Local		nVlrMg2		:= 0
	Local		nPerMg2		:= 0
	Local		nTotMg2		:= 0
	Local		nTotMgOk	:= 0
	Local		nTotVlrOk	:= 0
	Local		nTotTab		:= 0
	Local		nTotPrc		:= 0
	Local		nTotBon		:= 0
	Local		lLibera		:= .T.
	Local		lFlgFiscal	:= .F.	// Flag de pedido do Fiscal
	Local		lFlgCtrl	:= .F.	// Flag de pedido da Controladoria - Sobrepoe regras
	Local		lUfDif		:= .F.
	Local		cFlgAlc		:= ""
	Local		cFlgAlcAux	:= ""
	Local		cFlgItem	:= ""
	Local		nPCusFixo	:= U_BFFATM02(cEmpAnt) - Iif(nInCusFrete > 0 , 3 ,0 ) // Se houver valor de frete real, diminuo 3% do custo fixo
	Local		nTotPeso	:= 0
	Local		cUfDest		:= ""
	Local		lLibAnt		:= .T.
	Local		nSumLibAnt	:= 0
	Local		lExistDel	:= .F. 
	Local		cXLibAlc	:= ""
	Local		nVlrCM1		:= 0
	Local		cF4Duplic	:= ""
	Local		nPRegBnf	:= 0
	Local 		nX 
	Default	nPrzmed			:= 0
	Default	cDescE4			:= ""
	Default	aMotBloq		:= {}
	//SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + cUser
	
	If cInTipo=="SC5"
		cNumPed	:= 	SC5->C5_NUM
		cCondPag	:= 	SC5->C5_CONDPAG
		dData1		:= 	SC5->C5_DATA1
		dData2		:= 	SC5->C5_DATA2
		dData3		:= 	SC5->C5_DATA3
		dData4		:= 	SC5->C5_DATA4
		dEmissao	:= 	SC5->C5_EMISSAO
		cVend1		:= 	SC5->C5_VEND1
		cCliente	:=	SC5->C5_CLIENTE
		cLoja		:= 	SC5->C5_LOJACLI
		cTransp		:= 	SC5->C5_TRANSP
		cReemb		:= 	SC5->C5_REEMB
		cMsgInt		:= 	SC5->C5_MSGINT
		cPedPalm	:= 	SC5->C5_PEDPALM
		nPxItem		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
		nPxProd		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPxTes    	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_TES"})
		nPxCfop		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_CF"})
		nPxPrcVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPxPrcTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPxQtdVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
		nPxComis1	:=	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_COMIS1"})
		nPxComis2	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_COMIS2"})
		nPxLocal	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
		nPxFlgAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XALCADA"})
		nPxLibAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XLIBALC"})
		nPxCodTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
		nPxPrcMax	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
		nPxPrcMin	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
		nPVlrTampa	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XVLRTAM"})
		nPxFlex		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XFLEX"})
		nPRegBnf	:=  aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	ElseIf cInTipo=="MC5"
		cNumPed		:=	M->C5_NUM
		cCondPag	:= 	M->C5_CONDPAG
		dData1		:= 	M->C5_DATA1
		dData2		:= 	M->C5_DATA2
		dData3		:= 	M->C5_DATA3
		dData4		:= 	M->C5_DATA4
		dEmissao	:= 	M->C5_EMISSAO
		cVend1		:= 	M->C5_VEND1
		cCliente	:= 	M->C5_CLIENTE
		cLoja		:= 	M->C5_LOJACLI
		cTransp		:= 	M->C5_TRANSP
		cReemb		:= 	M->C5_REEMB
		cMsgInt		:= 	M->C5_MSGINT
		cPedPalm	:= 	M->C5_PEDPALM
		nPxItem		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
		nPxProd		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPxTes    	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_TES"})
		nPxCfop		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_CF"})
		nPxPrcVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPxPrcTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPxQtdVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
		nPxComis1	:=	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_COMIS1"})
		nPxComis2	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_COMIS2"})
		nPxLocal	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
		nPxFlgAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XALCADA"})
		nPxLibAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XLIBALC"})
		nPxCodTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
		nPxPrcMax	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
		nPxPrcMin	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
		nPVlrTampa	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XVLRTAM"})
		nPxFlex		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XFLEX"})
		nPRegBnf	:=  aScan(aInHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	ElseIf cInTipo=="SUA"
		cNumPed		:= 	SUA->UA_NUM
		cCondPag	:= 	SUA->UA_CONDPG
		dData1		:= 	Iif(SUA->(FieldPos("UA_DATA1")) > 0 ,SUA->UA_DATA1,CTOD(""))
		dData2		:= 	Iif(SUA->(FieldPos("UA_DATA2")) > 0 ,SUA->UA_DATA2,CTOD(""))
		dData3		:= 	Iif(SUA->(FieldPos("UA_DATA3")) > 0 ,SUA->UA_DATA3,CTOD(""))
		dData4		:= 	Iif(SUA->(FieldPos("UA_DATA4")) > 0 ,SUA->UA_DATA4,CTOD(""))
		dEmissao	:= 	SUA->UA_EMISSAO
		cVend1		:= 	SUA->UA_VEND
		cCliente	:= 	SUA->UA_CLIENTE
		cLoja		:= 	SUA->UA_LOJA
		cTransp		:= 	SUA->UA_TRANSP
		cReemb		:= 	IIf(SUA->(FieldPos("UA_REEMB"))>0,SUA->UA_REEMB,"")
		cMsgInt		:= 	SUA->UA_MSGINT
		cPedPalm	:= 	Iif(SUA->(FieldPos("UA_PEDPALM"))> 0,SUA->UA_PEDPALM,"")
		nPxItem		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})
		nPxProd		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})
		nPxTes    	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_TES"})
		nPxCfop		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_CF"})
		nPxPrcTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_PRCTAB"})
		nPxPrcVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_VRUNIT"})
		nPxQtdVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_QUANT"})
		nPxComis1	:=	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
		nPxComis2	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
		nPxLocal	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_LOCAL"})
		nPxFlgAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XALCADA"})
		nPxLibAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XLIBALC"})
		nPxCodTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
		nPxPrcMax	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
		nPxPrcMin	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
		nPVlrTampa	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
		nPxFlex		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
		nPRegBnf	:=  aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	ElseIf cInTipo=="MUA"
		cNumPed		:= 	M->UA_NUM
		cCondPag	:= 	M->UA_CONDPG
		dData1		:=  Iif(SUA->(FieldPos("UA_DATA1")) > 0 ,M->UA_DATA1,CTOD(""))
		dData2		:= 	Iif(SUA->(FieldPos("UA_DATA1")) > 0 ,M->UA_DATA1,CTOD(""))
		dData3		:= 	Iif(SUA->(FieldPos("UA_DATA1")) > 0 ,M->UA_DATA1,CTOD(""))
		dData4		:= 	Iif(SUA->(FieldPos("UA_DATA1")) > 0 ,M->UA_DATA1,CTOD(""))
		dEmissao	:= 	M->UA_EMISSAO
		cVend1		:= 	M->UA_VEND
		cCliente	:= 	M->UA_CLIENTE
		cLoja		:= 	M->UA_LOJA
		cTransp		:= 	M->UA_TRANSP
		cReemb		:= 	IIf(SUA->(FieldPos("UA_REEMB"))>0,SUA->UA_REEMB,"")
		cMsgInt		:= 	M->UA_MSGINT
		cPedPalm	:= 	Iif(SUA->(FieldPos("UA_PEDPALM"))> 0,SUA->UA_PEDPALM,"")
		nPxItem		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})
		nPxProd		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})
		nPxTes    	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_TES"})
		nPxCfop		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_CF"})
		nPxPrcVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_VRUNIT"})
		nPxPrcTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_PRCTAB"})
		nPxQtdVen	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_QUANT"})
		nPxComis1	:=	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
		nPxComis2	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
		nPxLocal	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_LOCAL"})
		nPxFlgAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XALCADA"})
		nPxLibAlc	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XLIBALC"})
		nPxCodTab	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
		nPxPrcMax	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
		nPxPrcMin	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
		nPVlrTampa	:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
		nPxFlex		:= 	aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
		nPRegBnf	:=  aScan(aInHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	Endif
	
	// Posiciono no cliente para garantir os dados validados
	DbSelectArea("SA1")
	DbSetOrder(1)
	If !DbSeek(xFilial("SA1")+cCliente+cLoja)
		RestArea(aAreaOld)
		Return .F.
	Endif
	
	cUfDest	:= SA1->A1_EST
	
	// Chama fun��o que executa a verifica��o se o cliente est� cadastrado como Item cont�bil
	// Objetivo desta regra � que qualquer cliente cadastrado novo que venha a ter pedido j� esteja cadastrado
	U_BFCTBM21()
	
	DbSelectArea("SA3")
	DbSetOrder(1)
	If DbSeek(xFilial("SA3")+cVend1) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
		nPCusFixo		:= U_BFFATM02(Iif(SA3->A3_XSEGEMP $ "LL","03",cEmpAnt)) - Iif(nInCusFrete > 0 , 3 ,0 ) // Se houver valor de frete real, diminuo 3% do custo fixo
	Endif
	
	// Posiciona na condi��o de pagamento para valida��o de prazos
	DbSelectArea("SE4")
	DbSetOrder(1)
	If dbSeek(xFilial("SE4")+cCondPag)
		aCond := {}
		cDescE4	:= cCondPag+" - "+SE4->E4_DESCRI
		
		If cCondPag == '999'
			IF !Empty(dData1)
				nQteParc := 1
				nDias := dData1 - dEmissao
				AADD(aCond,{dData1,1})
			EndIf
			
			IF !Empty(dData2)
				nQteParc += 1
				nDias += dData2 - dEmissao
				AADD(aCond,{dData2,1})
			EndIf
			
			IF !Empty(dData3)
				nQteParc += 1
				nDias += dData3 - dEmissao
				AADD(aCond,{dData3,1})
			EndIf
			
			IF !Empty(dData4)
				nQteParc += 1
				nDias += dData4 - dEmissao
				AADD(aCond,{dData4,1})
			EndIf
			nPrzMed := Round(nDias/nQteParc,0)
		Else
			aCond 	:= Condicao(1,cCondPag,nTotDup,dEmissao)
			For nX := 1 to Len(aCond)
				nDias 	+= aCond[nX][1] - dEmissao
				cDescE4	+= " - " + DTOC(aCond[nX][1])
				nQteParc++
			Next
			nPrzMed := Round(nDias / Len(aCond),0)
		Endif
		
		// Valida regra de valor minimo por parcela
		If (nTotDup / nQteParc ) < GetNewPar("BF_VMINDUP",250)
			
			Aadd(aMotBloq,{"A2-Pedido abaixo do Valor m�nimo de R$ " + Transform(GetNewPar("BF_VMINDUP",250),"@E 999,999.99")+ " por parcela"})
			lLibera := .F.
			cFlgAlc	+= "A2#"
		Endif
		
		// Valida regra de prazo m�dio acima de 35 dias
		If nPrzMed > GetNewPar("BF_VMAXPRZ",35)
			Aadd(aMotBloq,{"A3-Prazo m�dio do pedido acima do limite de " + cValToChar(GetNewPar("BF_VMAXPRZ",35))+ " dias"})
			lLibera := .F.
			cFlgAlc	+= "A3#"
		Endif
	Endif
	
	
	// Verifica se o vendedor do pedido � vendedor prateleira.
	If Alltrim(cVend1)+Alltrim(SA1->A1_VEND) $ GetNewPar("BF_VNDPRTL",'000004#000005#000006#000010')// .Or. Alltrim(SA1->A1_VEND) $ ('000004#000005#000006')
		Aadd(aMotBloq,{"A9-Vendedor Prateleira!"})
		cFlgAlc	+= "A9#"
		lLibera := .F.
	Endif
	
	
	// Verifica no cadastro da transportadora alguns dados para valida��o
	DbSelectArea("SA4")
	DbSetOrder(1)
	If dbSeek(xFilial("SA4")+cTransp) .And. SA4->(FieldPos("A4_VLRMIN")) > 0
		If nTotPed < SA4->A4_VLRMIN
			
			Aadd(aMotBloq,{"A1-Valor do Pedido R$ " + Transform(nTotPed,"@E 999,999.99") + " Inferior ao m�nimo de R$ " + Transform(SA4->A4_VLRMIN,"@E 999,999.99") + " da transportadora "+SA4->A4_NREDUZ})
			
			lLibera := .F.
			cFlgAlc	+= "A1#"
		Endif
	Endif
	
	// Pedido de vendedor com observa��o - ap�s altera��es da assessora, observa��es devem ser retiradas.
	// Desativada regra de observa��o. Assessora que se dane conforme Jonathan. 
	//If !Empty(cMsgInt) .And. !Empty(cPedPalm)
	//	Aadd(aMotBloq,{"B2-Pedido/Or�amento Origem Tablet e com observa��o na Mensagem interna, sujeito a an�lise de leitura"})
		//lLibera := .F.
	//	cFlgAlc	+= "B2#"
	//Endif
	
	// Verifica regra por itens
	For iQ	:= 1 To Len(aInCols)
		// Caso tenha algum item deletado
		If aInCols[iQ,Len(aInHeader)+1]
			// Chamado 18.883 - Se houver algum item deletado que j� existia anteriormente no pedido salvo, valida a al�ada
			If cInTipo $ "SUA#MUA"				
				DbSelectArea("SUB")
				DbSetOrder(1) //UB_FILIAL, UB_NUM, UB_ITEM, UB_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
				If DbSeek(xFilial("SUB")+cNumPed+aInCols[iQ,nPxItem]+aInCols[iQ,nPxProd])
					cRetAlc	+= "|"+aInCols[iQ,nPxItem] + "= Deletado do Or�amento"
					lLibera 	:= .F.
					lLibAnt		:= .F.
					nSumLibAnt	+= 1 
					lExistDel	:= .T. 
					Aadd(aMotBloq,{"Item "+aInCols[iQ,nPxItem] + " deletado do Or�amento."})
				Endif
				cFlgItem	:= ""
			ElseIf cInTipo $ "SC5#MC5"
				DbSelectArea("SC6")
				DbSetOrder(1) //C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
				If DbSeek(xFilial("SC6")+cNumPed+aInCols[iQ,nPxItem]+aInCols[iQ,nPxProd])
					cRetAlc	+= "|"+aInCols[iQ,nPxItem] + "= Deletado do pedido"
					lLibera 	:= .F.
					lLibAnt		:= .F.
					nSumLibAnt	+= 1 
					lExistDel	:= .T. 
					Aadd(aMotBloq,{"Item "+aInCols[iQ,nPxItem] + " deletado do Pedido."})
				Endif
				cFlgItem	:= ""			
			Endif
		Else
			// Chamado 20.834 - Se o or�amento j� estava liberado e foram adicionados itens, valida a al�ada novamente, mesmo que os novos itens estejam dentro da regra
			If cInTipo $ "SUA#MUA"				
				DbSelectArea("SUB")
				DbSetOrder(1) //UB_FILIAL, UB_NUM, UB_ITEM, UB_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
				If DbSeek(xFilial("SUB")+cNumPed+aInCols[iQ,nPxItem]+aInCols[iQ,nPxProd])
				
				Else
					DbSelectArea("SUA")
					DbSetOrder(1)
					If DbSeek(xFilial("SUA")+ cNumPed)
						cRetAlc	+= "|"+aInCols[iQ,nPxItem] + "= Adicionado ao Or�amento"
						lLibera 	:= .F.
						lLibAnt		:= .F.
						nSumLibAnt	+= 1 
						lExistDel	:= .T. 
						Aadd(aMotBloq,{"Item "+aInCols[iQ,nPxItem] + " Adicionado ao Or�amento."})
					Endif
				Endif
				cFlgItem	:= ""
			ElseIf cInTipo $ "SC5#MC5"
				DbSelectArea("SC6")
				DbSetOrder(1) //C6_FILIAL, C6_NUM, C6_ITEM, C6_PRODUTO, R_E_C_N_O_, D_E_L_E_T_
				If DbSeek(xFilial("SC6")+cNumPed+aInCols[iQ,nPxItem]+aInCols[iQ,nPxProd])
				
				Else
					// Sen�o existe o item mas j� existe o pedido de venda. 
					DbSelectArea("SC5")
					DbSetOrder(1)
					If DbSeek(xFilial("SC5")+cNumPed)
						cRetAlc	+= "|"+aInCols[iQ,nPxItem] + "= Adicionado ao pedido"
						lLibera 	:= .F.
						lLibAnt		:= .F.
						nSumLibAnt	+= 1 
						lExistDel	:= .T. 
						Aadd(aMotBloq,{"Item "+aInCols[iQ,nPxItem] + " Adicionado ao Pedido."})
					Endif
				Endif
				cFlgItem	:= ""			
			Endif
		
		Endif
	Next iQ

	cEstado := GetMv("MV_ESTADO")
		
	// Verifica regra por itens
	For iQ	:= 1 To Len(aInCols)
		If !aInCols[iQ,Len(aInHeader)+1]
			nItFis++	// Incrementa item para retorno MaFisRet
			
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+aInCols[iQ,nPxProd])
			
			DbSelectArea("SB2")
			DbSetOrder(1)
			DbSeek(xFilial("SB2")+aInCols[iQ,nPxProd]+aInCols[iQ,nPxLocal])
			
			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4")+aInCols[iQ,nPxTes])
			cF4Duplic	:= SF4->F4_DUPLIC
			If cF4Duplic == "N" .And. Empty(aInCols[iQ,nPRegBnf])	
				
				Aadd(aMotBloq,{"B1-Item " + aInCols[iQ,nPxItem] + " n�o Gera Duplicata"})
				lLibera := .F.
				cFlgItem	+= "B1#"
			Endif
			
			nTotPeso	+= SB1->B1_PESBRU * aInCols[iQ,nPxQtdVen]
			
			// Monta valores para calculo da Margem
			aRetTmka08	:= U_BFTMKA08(cCliente,cLoja,aInCols[iQ,nPxProd])
			nPercFI		:= aRetTmka08[1]
			nPercMKT	:= aRetTmka08[2]
			nPercRet	:= aRetTmka08[3]
			
			nValTamp	:= aInCols[iQ,nPVlrTampa]+aInCols[iQ,nPxFlex] //U_BFTMKA07(cCliente,cLoja,aInCols[iQ,nPxProd],cReemb)
			
			nVlrMg1		:= 0
			nVlrMg2		:= 0
			
			
			If cF4Duplic =="S"
				// Monta vari�vel para controle de Margem 1
				nVlrMg2	:= (aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen])+MaFisRet(nItFis,"IT_FRETE")+MaFisRet(nItFis,"IT_DESPESA")
				nVlrMg1	:= (aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen])+MaFisRet(nItFis,"IT_FRETE")+MaFisRet(nItFis,"IT_DESPESA")
				// Subtraio somente valores que est�o envolvidos quando houver gera��o de contas a receber
				nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen]) * aInCols[iQ,nPxComis1] / 100,2)
				nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen]) * aInCols[iQ,nPxComis2] / 100,2)
				// Custo do financeiro prazo m�dio
				nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * ((1.00066030548229^nPrzMed)-1),2)
				// Subtrai o custo da empresa
				nVlrMg2	-= Round( (aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * nPCusFixo / 100 ,2)
			Endif
			// Subtrai o Valor do Pis
			nVlrMg2	-= MaFisRet(nItFis,"IT_VALPS2")
			nVlrMg1	-= MaFisRet(nItFis,"IT_VALPS2")
			
			// Subtrai o valor do custo de estoque
			nVlrCM1	:= U_BFFT30B3(aInCols[iQ,nPxProd]/*cInCodPrd*/,;
				aInCols[iQ,nPxQtdVen] /*nInQte*/,;
				(SB2->B2_QATU - SB2->B2_RESERVA) /*nInSaldB2*/,;
				(aInCols[iQ,nPxQtdVen]*SB2->B2_CM1)/*nInCusto*/,;
				SB1->B1_PROC /*cInFor*/,;
				SB1->B1_LOJPROC /*cInLoj*/,;
				SB1->B1_CUSTD /*nInCustD*/)
			
			nVlrMg2	-= Round(nVlrCM1 ,2)
			nVlrMg1	-= Round(nVlrCM1 ,2)
			
			// Subtrai o valor do Cofins
			nVlrMg2	-= MaFisRet(nItFis,"IT_VALCF2")
			nVlrMg1	-= MaFisRet(nItFis,"IT_VALCF2")
			
			// Subtrai o valor do ICMS
			nVlrMg2	-= MaFisRet(nItFis,"IT_VALICM")
			nVlrMg1	-= MaFisRet(nItFis,"IT_VALICM")
			
			// Subtrai o valor da despesa
			nVlrMg2	-= MaFisRet(nItFis,"IT_DESPESA")
			
			// Subtrai o valor do frete
			nVlrMg2	-= MaFisRet(nItFis,"IT_FRETE")
			
			// Subtrai o valor das tampas
			nVlrMg2	-= Round(aInCols[iQ,nPxQtdVen] * nValTamp ,2)
			nVlrMg1	-= Round(aInCols[iQ,nPxQtdVen] * nValTamp ,2)
			nTotBon += Round(aInCols[iQ,nPxQtdVen] * nValTamp ,2)
			
			// Subtrai o valor da Verba de Marketing
			nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * nPercMKT / 100 ,2)
			// Subtrai o valor do F&I
			nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * nPercFI / 100 ,2)
			
			// Subtrai o valor da Reten��o
			nVlrMg2	-= Round((aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * nPercRet / 100 ,2)
			
			// Subtrai o percentual de ajuste do cadastro de produto
			If SB1->(FieldPos("B1_PRMINFO")) > 0
				nVlrMg1		-= Round((aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen]) * SB1->B1_PRMINFO / 100 , 2 )
				nVlrMg2		-= Round((aInCols[iQ,nPxQtdVen] * aInCols[iQ,nPxPrcVen]) * SB1->B1_PRMINFO / 100 , 2 )
			Endif
			// Calcula percentual da margem por item
			nPerMg2		:= Round(nVlrMg2 / (aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * 100 ,2)
			nPerMg1		:= Round(nVlrMg1 / (aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen]) * 100 ,2)
			
			// Trecho desativado Junho/2016 - Nova regra por desconto
			//If nPerMg1	<= 0 .And. !(aInCols[iQ,nPxCodTab] $ "00P#F01#F02#F03")
			//	Aadd(aMotBloq,{"B3-Item " + aInCols[iQ,nPxItem] +" problema margem" })//+ " com margem negativa R$ " + Transform(nVlrMg2,"@E 999,999.99")})
			//	lLibera := .F.
			//	cFlgItem	+= "B3#"
			//Endif
			//If aInCols[iQ,nPxCodTab] $ "00P#F01#F02#F03#M01#M02#M03#M04" .Or. (aInCols[iQ,nPxCodTab] $ "00D#00C#00B#00A#0AA" .And. (aInCols[iQ,nPxPrcVen] >= aInCols[iQ,nPxPrcTab]))
			//	nTotMgOk	+= nVlrMg1
			//	nTotVlrOk	+= Iif(cF4Duplic =="S",aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen],0)
			//Endif
			If (100-(aInCols[iQ,nPxPrcVen]/aInCols[iQ,nPxPrcTab]*100)) < 5 
				nTotVlrOk	+= Iif(cF4Duplic =="S",aInCols[iQ,nPxQtdVen]*aInCols[iQ,nPxPrcVen],0)
			Endif
			nTotTab		+= Iif(cF4Duplic =="S",aInCols[iQ,nPxPrcTab]*aInCols[iQ,nPxQtdVen],0)
			nTotPrc		+= Iif(cF4Duplic =="S",aInCols[iQ,nPxPrcVen]*aInCols[iQ,nPxQtdVen],0)
			// Se o brinde estiver num Combo, o Brinde n�o subtrai do valor faturamento para calcular o desconto m�dio concedido. 
			nTotBon		+= Iif(cF4Duplic =="N".And. Empty(aInCols[iQ,nPRegBnf]),aInCols[iQ,nPxPrcVen]*aInCols[iQ,nPxQtdVen],0)
			nTotMg1		+= nVlrMg1
			nTotMg2		+= nVlrMg2
			
			If aInCols[iQ,nPxCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63#T70"
				// N�o desconta o pre�o da Tampa pois a coluna Pre�o j� tem a informa��o somada pelo OM010PRC
				If Round(aInCols[iQ,nPxPrcVen],2) < Round(aInCols[iQ,nPxPrcMin],2)
					Aadd(aMotBloq,{"B5-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B5","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "B5#"
				Endif
				// N�o desconta o pre�o da Tampa pois a coluna Pre�o j� tem a informa��o somada pelo OM010PRC
				If Round(aInCols[iQ,nPxPrcVen],2) > Round(aInCols[iQ,nPxPrcMax],2)
					Aadd(aMotBloq,{"B6-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B6","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "B6#"
				Endif
			ElseIf aInCols[iQ,nPxCodTab] $ "0AA"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+"0AA"+SB1->B1_COD)
					// Desconta o valor da Tampa do pre�o de venda pois valida direto com o pre�o de Tabela
					If (Round(aInCols[iQ,nPxPrcVen]-nValTamp,2)) < sfCalcPrc("0AA",DA1->DA1_PRCVEN,nPrzMed)
						Aadd(aMotBloq,{"A6-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"A6","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "A6#"
					Endif
				Else
					Aadd(aMotBloq,{"B7-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B7","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "B7#"
				Endif
			ElseIf aInCols[iQ,nPxCodTab] $ "M01"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// Desconta o valor da Tampa do pre�o de venda pois valida direto com o pre�o de Tabela
					If (Round(aInCols[iQ,nPxPrcVen]-nValTamp,2)) < sfCalcPrc(aInCols[iQ,nPxCodTab],DA1->DA1_PRCVEN,nPrzMed)
						Aadd(aMotBloq,{"A6-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"A6","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "A6#"
					Endif
				Else
					Aadd(aMotBloq,{"B7-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B7","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "B7#"
				Endif
			ElseIf aInCols[iQ,nPxCodTab] $ "300#400#500"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// Desconta o valor da Tampa do pre�o de venda pois valida direto com o pre�o de Tabela
					If Round(aInCols[iQ,nPxPrcVen]-nValTamp,2) < sfCalcPrc(aInCols[iQ,nPxCodTab],DA1->DA1_PRCVEN,nPrzMed)
						Aadd(aMotBloq,{"A7-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"A7","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "A7#"
					Endif
				Else
					Aadd(aMotBloq,{"B9-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B9","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "B9#"
				Endif
			ElseIf aInCols[iQ,nPxCodTab] >= "301" .And. aInCols[iQ,nPxCodTab] <= "3ZZ"
				
				DbSelectArea("DA0")
				DbSetOrder(1)
				DbSeek(xFilial("DA0")+aInCols[iQ,nPxCodTab])
				
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// N�o desconta o valor de tampas pois o mesmo deve estar embutido na tabela do cliente
					If DA0->DA0_XACRES > 0 .And. Round(aInCols[iQ,nPxPrcVen],2) > Round(DA1->DA1_PRCVEN * (100 + DA0->DA0_XACRES )/100 ,TamSX3("UB_VRUNIT")[2]) 
					  	Aadd(aMotBloq,{"B8-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B8","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "B8#"
					ElseIf DA0->DA0_XACRES <= 0 .And. Round(aInCols[iQ,nPxPrcVen],2) <> DA1->DA1_PRCVEN
						Aadd(aMotBloq,{"B8-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"B8","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "B8#"
					Endif
				Else
					Aadd(aMotBloq,{"C1-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C1","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "C1#"
				Endif
				
			ElseIf aInCols[iQ,nPxCodTab] >= "401" .And. aInCols[iQ,nPxCodTab] <= "4ZZ"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// N�o desconta o valor de tampas pois o mesmo deve estar embutido na tabela do cliente
					If Round(aInCols[iQ,nPxPrcVen],2) <> DA1->DA1_PRCVEN
						Aadd(aMotBloq,{"C2-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C2","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "C2#"
					Endif
				Else
					Aadd(aMotBloq,{"C3-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C3","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "C3#"
				Endif
				
			ElseIf aInCols[iQ,nPxCodTab] >= "501" .And. aInCols[iQ,nPxCodTab] <= "5ZZ"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// N�o desconta o valor de tampas pois o mesmo deve estar embutido na tabela do cliente
					If Round(aInCols[iQ,nPxPrcVen],2) <> DA1->DA1_PRCVEN
						Aadd(aMotBloq,{"C4-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C4","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "C4#"
					Endif
				Else
					Aadd(aMotBloq,{"C5-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C5","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "C5#"
				Endif
			ElseIf aInCols[iQ,nPxCodTab] $ "00P"
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+"00P"+SB1->B1_COD)
					// N�o desconta o valor da Tampa pois item promocional n�o tem tampa no pre�o
					If Round(aInCols[iQ,nPxPrcVen],2) <> DA1->DA1_PRCVEN
						Aadd(aMotBloq,{"C6-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C6","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "C6#"
					Endif
				Else
					Aadd(aMotBloq,{"C7-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"C7","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "C7#"
				Endif
			Else 
				DbSelectArea("DA1")
				DbSetOrder(1)
				If DbSeek(xFilial("DA1")+aInCols[iQ,nPxCodTab]+SB1->B1_COD)
					// Desconta o valor da Tampa do pre�o de venda pois valida direto com o pre�o de Tabela
					If Round(aInCols[iQ,nPxPrcVen]-nValTamp,2) < sfCalcPrc(aInCols[iQ,nPxCodTab],DA1->DA1_PRCVEN,nPrzMed)
						Aadd(aMotBloq,{"E6-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E6","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "E6#"
					Endif
				Else
					Aadd(aMotBloq,{"E7-Item " + aInCols[iQ,nPxItem]+ " "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E7","X5_DESCRI")})
					lLibera := .F.
					cFlgItem	+= "E7#"
				Endif
			Endif
			// Analisa se a Filial � SP e o produto � Baston
			// Avalia regra de condi��o de pagamento X valor do pedido
			If cFilAnt == "07" .And. SB1->B1_GRUPO == "1400"
				If nTotDup < 2000
					If !(cCondPag $ "128#331")
						Aadd(aMotBloq,{"E8-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E8","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "E8#"
					Endif
				Else
					If !(cCondPag $ "128#331#135#335")
						Aadd(aMotBloq,{"E9-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E9","X5_DESCRI")})
						lLibera := .F.
						cFlgItem	+= "E9#"
					Endif
				Endif
			Endif
			
			// Analise se o produto � Michelin
			//If SB1->B1_CABO $ "MIC"
			//	Aadd(aMotBloq,{"E3-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E3","X5_DESCRI")})
			//	lLibera := .F.
			//	cFlgItem	+= "E3#"
			//Endif
			
			// Analisa se o produto � CarCare - 
			If SB1->B1_CABO $ "CAR"
				Aadd(aMotBloq,{"E9-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E3","X5_DESCRI")})
				lLibera := .F.
				cFlgItem	+= "E9#"
			Endif
						
			// 30/03/2015 Chamado 10425 - Se o cliente de destino for diferente da UF da empresa emitente
			If cUfDest <> cEstado
				Aadd(aMotBloq,{"E4-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E4","X5_DESCRI")})
				lLibera := .F.
				cFlgItem	+= "E4#"
				lUfDif		:= .T.
			Endif
			
			// Regra E4- Exce��o de CFOP fiscais que n�o precisam de outra al�ada exceto do Depto Fiscal
			// 5927-6152-6659-6409 Ou CFOP 5949/6949 e n�o sendo remessa de expositor
			// 24/10/2016 - Adicionado CFOP 5119/5923 a pedido de Cristian 
			// 31/10/2017 - Adicionado CFOP 6551/5551 a pedido de Cristian - Chamado 19.288
			If Alltrim(aInCols[iQ,nPxCfop]) $ "5927#6152#6659#6409#5933#6933#5926#6926#5119#5923#5551#6551#5552#6552" .Or.;
					(Alltrim(aInCols[iQ,nPxCfop]) $ "5949#6949" .And. SF4->F4_XTPMOV <> "RE")
				aMotBloq	:= {}
				Aadd(aMotBloq,{"E4-Item " + aInCols[iQ,nPxItem] +" "+Posicione("SX5",1,xFilial("SX5")+"XD"+"E4","X5_DESCRI")})
				lLibera := .F.
				lFlgFiscal	:= .T.
				// Zera todos os outros motivos
				cFlgItem	:= "E4#"
				cFlgAlc	:= ""
			Endif
			
			// Regra A8 - Exce��o de pedidos com comodato que n�o precisam de outras analises
			
			If SB1->B1_TIPO == "AI" .Or. (SB1->(FieldPos("B1_BLOQFAT")) > 0 .And.  SB1->B1_BLOQFAT == "A")
				aMotBloq	:= {}
				Aadd(aMotBloq,{"A8-Produto '" + SB1->B1_COD + SB1->B1_DESC + "' � comodato. Precisa baixar cr�ditos."})
				lLibera := .F.
				// Zera todos os outros Motivos
				cFlgItem	:= "A8#"
				cFlgAlc	:= ""
				lFlgCtrl	:= .T.
			Endif
			
			
			
			// Sendo pedido de venda grava flag de bloqueio por itens
			If cInTipo $ "MC5#SC5"
				
				// Verifica se o item j� estava liberado anteriormente
				If 	lExistDel
				 	cXLibAlc	:= "ZZzzzz"
				 	cFlgItem	+= "D5#"
				Else
					cXLibAlc	:= cCliente+"|"+cLoja+"|"+cCondPag+"|"+aInCols[iQ,nPxProd]+"|"+cValToChar(aInCols[iQ,nPxQtdVen])+"|"+cValToChar(aInCols[iQ,nPxPrcVen])+"|"
				Endif
				
				If !lExistDel .And. !lUfDif .And. Empty(aInCols[iQ,nPxFlgAlc]) .And. cXLibAlc $ aInCols[iQ,nPxLibAlc]
					cFlgItem	:= ""
				Else
					lLibAnt		:= .F.
				Endif
				
				If ValAtrib("aCols") == "A"
					// Preciso percorrer o aCols original para identificar o mesmo do aColsAux que est� ordenado de outra forma
					For iZ := 1 To Len(aCols)
						If aCols[iZ,nPxItem]	== aInCols[iQ,nPxItem]
							aCols[iZ,nPxFlgAlc]	:= cFlgItem
							Exit
						Endif
					Next
				Endif
			Endif
			
			// Sendo pedido de venda grava flag de bloqueio por itens
			If cInTipo $ "SUA#MUA"
				//SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + cUser
				
				// Verifica se o item j� estava liberado anteriormente
				If 	lExistDel
				 	cXLibAlc	:= "ZZzzzz"
				 	cFlgItem	+= "D5#"
				Else
					cXLibAlc	:= cCliente+"|"+cLoja+"|"+cCondPag+"|"+aInCols[iQ,nPxProd]+"|" +aInCols[iQ,nPxTes] +"|"+cValToChar(aInCols[iQ,nPxQtdVen])+"|"+cValToChar(aInCols[iQ,nPxPrcVen])+"|"
				Endif
				
				If !lExistDel .And. !lUfDif .And. Empty(aInCols[iQ,nPxFlgAlc]) .And. cXLibAlc $ aInCols[iQ,nPxLibAlc]
					cFlgItem	:= ""					
				Else
					lLibAnt	:= .F.
					nSumLibAnt	+= 1
				Endif
				
				DbSelectArea("SUB")
				DbSetOrder(1)
				If DbSeek(xFilial("SUB")+cNumPed+aInCols[iQ,nPxItem])
					RecLock("SUB",.F.)
					SUB->UB_XALCADA	:= cFlgItem
					MsUnlock()
				Endif
				
				If ValAtrib("aCols") == "A"
					//aCols[iQ,nPxFlgAlc]	:= cFlgItem
					// Preciso percorrer o aCols original para identificar o item no mesmo aAcolsAux para gravar corretamente o flag do bloqueio
					For iZ := 1 To Len(aCols)
						If aCols[iZ,nPxItem]	== aInCols[iQ,nPxItem]
							aCols[iZ,nPxFlgAlc]	:= cFlgItem
							Exit
						Endif
					Next
				Endif
				
			Endif
			
			
			If !Empty(cFlgItem)
				cRetAlc	+= "|"+aInCols[iQ,nPxItem] + "="+cFlgItem
			Endif
			cFlgItem	:= ""
		
		Endif
	Next
	
	// Regra de valida��o E5 - Cota��o de fretes
	If nSumLibAnt == 0 .And. nTotDup > 0 .And. nTotPeso > 2000
		Aadd(aMotBloq,{"E5-Pedido com peso acima de 2 Toneladas. Avaliar cota��o de Frete"})
		lLibera := .F.
		cFlgAlc	+= "E5#"
	Endif
	
	// Trecho desativado Junho/2016 - Nova regra por desconto
	//If !lLibAnt .And. ( nTotMg1/nTotDup * 100 ) < 0 .And. !lFlgFiscal .And. !lFlgCtrl
	//	Aadd(aMotBloq,{"B4-Pedido com problemas de margem"})
	//	lLibera := .F.
	//	cFlgAlc	+= "B4#"
	//Endif
	
	// 06/07/2015 - Novos motivos de al�adas cadastrados
	// BA e BB - para controlar percentuais de margens liberadas
	// 13/06/2016 - Novos motivos de ala�das cadastrados D5/D6 para controlar desconto m�dio
	If nSumLibAnt == 0 .And. !lFlgFiscal .And. !lFlgCtrl
		// Pre�o de tabela
		If nTotVlrOk == nTotTab .And. nTotBon == 0
			Aadd(aMotBloq,{"Pre�o de tabela - Aprova��o Autom�tica "})
		// Trecho desativado Mar�o/2018 - Tabela pre�os por volume
		// Desconto m�dio abaixo ou igual a 5% 
		//ElseIf (100-((nTotPrc-nTotBon)/nTotTab*100)) <= 5 
		//	Aadd(aMotBloq,{"Desconto m�dio abaixo de 5% - Aprova��o Autom�tica ( Desc.M�dio " + cValToChar(Round((100-((nTotPrc-nTotBon)/nTotTab*100)),2))+ ")"})
		// Trecho desativado Mar�o/2018 - Tabela pre�os por volume
		// Desconto m�dio entre 5 e 8% - Al�ada Gerente
		//ElseIf  (100-((nTotPrc-nTotBon)/nTotTab*100)) <= 8.02 .And.  (100-(nTotPrc/nTotTab*100)) > 5 
		//	Aadd(aMotBloq,{"D5-Desconto m�dio entre 5,01 a 8,00% - Aprova��o Gerente ( Desc.M�dio " + cValToChar(Round((100-((nTotPrc-nTotBon)/nTotTab*100)),2))+ ")"})
		//	lLibera := .F.
		//	cFlgAlc	+= "D5#"
		// Trecho desativado Mar�o/2018 - Tabela pre�os por volume
		// Desconto m�dio acima de 8% - Al�ada diretoria
		//ElseIf  (100-((nTotPrc-nTotBon)/nTotTab*100)) > 8.02 // 1 cent�simo para aceitar diferen�as de arredondamento  
		//	Aadd(aMotBloq,{"D6-Desconto m�dio acima de 8,00% - Aprova��o Diretoria ( Desc.M�dio " + cValToChar(Round((100-((nTotPrc-nTotBon)/nTotTab*100)),2))+ ")"})
		//	lLibera := .F.
		//	cFlgAlc	+= "D5#D6#"
		// Trecho desativado Junho/2016 - Nova regra por desconto	
		//ElseIf nTotMgOk <> nTotMg1 .And. (( (nTotMg1 - nTotMgOk)/(nTotDup - nTotVlrOk) * 100 ) < 8)
		//	Aadd(aMotBloq,{"BB-Pedido com problemas de margem - Aprova��o Diretoria"})
		//	lLibera := .F.
		//	cFlgAlc	+= "BB#B4"
		//ElseIf  ( nTotMg1  /nTotDup  * 100 ) < 10 .And. ( nTotMg1/nTotDup  * 100 ) >= 8
		//	Aadd(aMotBloq,{"BA-Pedido com problemas de margem - Aprova��o Interna "})
		//	lLibera := .F.
		//	cFlgAlc	+= "BA#"
		// Trecho desativado Junho/2016 - Nova regra por desconto
		//ElseIf  (nTotMg1 /nTotDup  * 100 ) < 8
		//	Aadd(aMotBloq,{"BB-Pedido com problemas de margem - Aprova��o Diretoria"})
		//	lLibera := .F.
		//	cFlgAlc	+= "BB#B4"
		Endif
	Endif
	
	// 07/08/2015 - Regra para evitar libera��es autom�ticas de pedidos com restri��o financeira
	// Clientes com crit�rios para serem classificados como Antecipado
	//If cInTipo$"MC5#SC5"
	// 22/8/2015 - removida a al�ada F1 pois verifica��o de libera��o autom�tica do pedido foi transferido para o PE MTA410
	//If SA1->A1_RISCO $ "E" .And. SA1->A1_LC == 1
	//Aadd(aMotBloq,{"F1-Bloqueio Financeiro.Cliente com risco 'E' !"})
	//cFlgAlc	+= "F1#"
	//lLibera := .F.
	//Endif
	
	//If cCondPag $ "099"
	//Aadd(aMotBloq,{"F1-Bloqueio Financeiro.Pedido definido como Antecipado!"})
	//cFlgAlc	+= "F1#"
	//lLibera := .F.
	//Endif
	//Endif
	// Se for pedido de venda - Verifica se bloquear por Al�ada de Antecipado 
	If cInTipo=="MC5"
		// Cliente com Risco 	
		If SA1->A1_RISCO $ "E" .And. SA1->A1_LC == 1 .And. !INCLUI
			cFlgAlc	+= "F1#"
			Aadd(aMotBloq,{"F1-"+Posicione("SX5",1,xFilial("SX5")+"XD"+"F1","X5_DESCRI")})
		Endif
		// Condi��o de pagamento antecipado
		If M->C5_CONDPAG $ "099" .And. !INCLUI
			cFlgAlc	+= "F1#"
			Aadd(aMotBloq,{"F1-"+Posicione("SX5",1,xFilial("SX5")+"XD"+"F1","X5_DESCRI")})
		Endif
	Endif
		
	// Se houveram bloqueios pelo cabe�alho do pedido, adiciona aos itens
	If !Empty(cFlgAlc)
		If cInTipo=="MC5"
			If ValAtrib("aCols") == "A"
				For iQ	:= 1 To Len(aInCols)
					If !aInCols[iQ,Len(aInHeader)+1]
						aCols[iQ,nPxFlgAlc]	+= "|"+cFlgAlc
					Endif
				Next
			Endif
		Endif
		// Sendo pedido de venda grava flag de bloqueio por itens
		If cInTipo=="SUA"
			DbSelectArea("SUB")
			DbSetOrder(1)
			DbGotop()
			DbSeek(xFilial("SUB")+cNumPed)
			
			While !Eof() .And. SUB->UB_FILIAL+SUB->UB_NUM == xFilial("SUB")+cNumPed
				RecLock("SUB",.F.)
				SUB->UB_XALCADA	:= Alltrim(SUB->UB_XALCADA)+"|"+cFlgAlc
				MsUnlock()
				
				If ValAtrib("aCols") == "A"
					For iQ	:= 1 To Len(aInCols)
						If !aInCols[iQ,Len(aInHeader)+1]
							aCols[iQ,nPxFlgAlc]	+= "|"+cFlgAlc
						Endif
					Next
				Endif
				DbSelectArea("SUB")
				DbSkip()
			Enddo
		Endif
		
		cRetAlc	+= "|"+cFlgAlc
	Endif
	RestArea(aAreaOld)
	
Return lLibera


/*/{Protheus.doc} sfCalcPrc
(long_description)
@author MarceloLauschner
@since 16/09/2014
@version 1.0
@param cCodTab, character, (Descri��o do par�metro)
@param nPrcVend, num�rico, (Descri��o do par�metro)
@param nSumPrz, num�rico, (Descri��o do par�metro)
@param lPrzDA0, ${param_type}, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCalcPrc(cCodTab,nPrcVend,nSumPrz,lPrzDA0)
	
	Default	lPrzDA0	:= .F.
	// Calcular pre�o de tabela por prazo se definido campo na DA0
	// Coteudo do campo DA0_XPRZME esperado: {{7,0.98},{14,0.99},{28,1},{35,1.01}}
	// Array com o prazo m�dio e o percentual a ser considerado em ordem crescente de prazo m�dio
	DbSelectArea("DA0")
	DbSetOrder(1)
	DbSeek(xFilial("DA0")+cCodTab)
	If DA0->(FieldPos("DA0_XPRZME")) > 0
		aPrzDA0	:= &(DA0->DA0_XPRZME)
		If ValAtrib("aPrzDA0") == "A"
			For iD := 1 To Len(aPrzDA0)
				If nSumPrz <= aPrzDA0[iD,1]
					nPrcVend	:= nPrcVend * aPrzDA0[iD,2]
					lPrzDA0	:= .T.
					Exit
				Endif
			Next
		Endif
	Endif
	
	If !lPrzDA0
		//07 Dias = -1,5% s/28dd
		//14 Dias = -1,0% s/28dd
		//21 Dias = -0,5% s/28dd
		//28 Dias = 0,0% s/28dd
		//35 Dias = 1,0% s/28dd
		//42 Dias = 2,0% s/28dd
		//49 Dias = 3,0% s/28dd
		//56 Dias = 4,0% s/28dd
		
		If nSumPrz <= 7
			nPrcRetur 	:= nPrcVend * 0.985
		ElseIf nSumPrz <= 14
			nPrcRetur 	:= nPrcVend * 0.99
		ElseIf nSumPrz <= 21
			nPrcRetur 	:= nPrcVend * 0.995
		ElseIf nSumPrz <= 28
			nPrcRetur 	:= nPrcVend 
		ElseIf nSumPrz <= 35
			nPrcRetur 	:= nPrcVend * 1.01
		ElseIf nSumPrz <= 42
			nPrcRetur 	:= nPrcVend * 1.02
		ElseIf nSumPrz <= 49
			nPrcRetur 	:= nPrcVend * 1.03
		Else
			nPrcRetur 	:= nPrcVend * 1.04
		Endif
	Endif
	
	nPrcVend	:= Round(nPrcVend,2)
	
Return nPrcVend

Static Function ValAtrib(atributo)
Return (Type(atributo) )
