
/*/{Protheus.doc} M410ABN
(Ponto Entrada ao abandonar pedido de venda ,Se abandonar inclus�o desfaz reserva de Tambores     )
	
@author MarceloLauschner
@since 06/08/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (http://tdn.totvs.com/display/public/mp/M410ABN+-+Cancelamento+de+pedido)
/*/
User Function M410ABN()

	Local		aAreaOld	:= GetArea()
	Local		iW
	Local		nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2NUM"})
	Local		nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2LIN"})
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxItem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})
	
	
	sfAtuaF3k1()
	
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410ABN")
		Return .T. 
	Endif
    
        
	// Limpa os dados da Produ��o somente se for inclus�o abandonada
	If INCLUI
		For iW := 1 To Len(aCols)
		// Somente produtos sujeitos a envasamento. 
		// N�o deve filtrar linhas deletadas, por que todos os itens digitados est�o sendo abandonados e dever�o restaurar a reserva
			If aCols[iW,nPxProd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do c�digo do produto
			// Evita erro de n�o existir os campos ainda na base de produ��o
				If nPxPA2NUM > 0
					DbSelectArea("PA2")
					DbSetOrder(3)
					If DbSeek(xFilial("PA2")+aCols[iW,nPxPA2NUM]+aCols[iW,nPxPA2LIN])
						RecLock("PA2",.F.)
						PA2->PA2_RESERV	:= " "
						PA2->PA2_PEDIDO	:= " "
						MsUnlock()
					Endif
				Endif
			Endif
		Next
	ElseIf ALTERA
		For iW := 1 To Len(aCols)
		// Somente produtos sujeitos a envasamento. 
		// Somente se o item ainda n�o estava digitado no pedido anteriormente
			DbSelectArea("SC6")
			DbSetOrder(1)
			If !DbSeek(xFilial("SC6")+M->C5_NUM+aCols[iW,nPxItem]+aCols[iW,nPxProd])
				If aCols[iW,nPxProd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do c�digo do produto
				// Evita erro de n�o existir os campos ainda na base de produ��o
					If nPxPA2NUM > 0
						DbSelectArea("PA2")
						DbSetOrder(3)
						If DbSeek(xFilial("PA2")+aCols[iW,nPxPA2NUM]+aCols[iW,nPxPA2LIN])
							RecLock("PA2",.F.)
							PA2->PA2_RESERV	:= " "
							PA2->PA2_PEDIDO	:= " "
							MsUnlock()
						Endif
					Endif
				Endif
			Endif
		Next
	
	Endif

	
	
	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfAtuaF3k1
// Fun��o para gravar Produtos na tabela de Ajustes de C�digos
// Foi usado neste ponto de entrada s� para fazer uma carga a partir de pedidos j� encerrados.  
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return Nil
@type function
/*/
Static Function sfAtuaF3k1

	Local	iW 
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxItem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})
	
	For iW := 1 To Len(aCols)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+M->C5_NUM+aCols[iW,nPxItem]+aCols[iW,nPxProd])
		//DbSeek(xFilial("SC6")+"002793")
		//While !Eof()
	
		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4") + SC6->C6_TES)
		sfAtuF3k2()
		
		//DbSelectArea("SC6")
		//DbSkip()
		//Enddo
	Next 

Return 



User Function XXF3KFORCE(cInPedido)

	Local 	cKeyC5		:= xFilial("SC6")+ cInPedido
	Private ALTERA	:= .T.
	Private INCLUI	:= .F.
	
	//RPCSetType(3)
	//RPCSetEnv("02","04","","","","",{"SC5","SC6","F3K"}) // Abre todas as tabelas.
	
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	//Set Filter To C5_NUM $ "216240#"
	//While SC5->(!Eof())
	If DbSeek(xFilial("SC5")+cInPedido)
	
		
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+SC5->C5_NUM)
		While SC6->(!Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == cKeyC5
			
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido: " + SC6->C6_NUM + " Item: " + SC6->C6_ITEM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			
			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4") + SC6->C6_TES)
			sfAtuF3k2()
		
			DbSelectArea("SC6")
			DbSkip()
		Enddo
	Endif 	
	//	DbSelectArea("SC5")
	//	SC5->(DbSkip())
	//Enddo 

Return 


/*/{Protheus.doc} sfAtuF3k2
// Efetua grava��o na tabela F3K
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return NIl 
@type function
/*/
Static Function sfAtuF3k2()

	Local	aAreaOld	:= GetArea()
	Local	cCodProd	:= SC6->C6_PRODUTO
	Local	cCfopPv		:= SC6->C6_CF
	Local	cCodVlDec	:= ""
	Local	cCodAjust	:= ""
	Local	cTipValor	:= "9"
	Local	cClasFis	:= Substr(SC6->C6_CLASFIS,2,2)
	Local	lGrvF3K		:= .F. 
	Local 	cPosIpi		:= Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_POSIPI")
	
	// Se a CST estiver em Branco assume do TES 
	If Empty(cClasFis)
		cClasFis	:= SF4->F4_SITTRIB
	Endif
	
	// Se for Atrialub RS - Chamado 22.800 - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	If SM0->M0_ESTENT == "RS" .And. (INCLUI .Or. ALTERA)

		// Chamado 25993 - REvis�o dos c�digos de Ajuste x cfop x cst 
		// 5114	Remessa consigna��o			90	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                    
		// 5405	VENDA MERC ST				60	OUTROS			RS052427	ANEXO V.B - AP.II,S.III,XX-PECAS,COMP.E ACES.P/PROD.AUTOP.                                                                                                                                                                                                  
		// 5655	VENDA LUBRIFICANTE ST		60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                    
		// 5656	VENDA LUB - Consumidor Fina 60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                   
		// 5663	Remessa Armazenagem			41	N�O-INCID�NCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL                                                                                                                                                                                                                    
		// 5905	Remessa Armazenagem			41	N�O-INCID�NCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL                                                                                                                                                                                                                    

		// VENDA DIFERIMENTO PARCIAL
		// Chamado 25816 - 19/04/2021
		If Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "RS052158"
			cCodVlDec	:= "0000170"
			cTipValor	:= "4"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5114" .And. cClasFis == "90"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5554#5908#6552#5910" .And. cClasFis == "41"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6659" .And. cClasFis == "41"
			cCodAjust	:= "RS051502"
			cCodVlDec	:= "0001001" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#5663" .And. cClasFis == "41"
			cCodAjust	:= "RS051510"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905" 
			cCodAjust	:= "RS051511"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "40"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5911" .And. cClasFis == "40" 
			cCodAjust	:= "RS051004"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5906#5907#5665"
			cCodAjust	:= "RS051512"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "RS051011"
			cCodVlDec	:= "0001002" // Remessa de Vasilhames e Sacarias
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5405" .And. cClasFis == "60"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5656#5655" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "84213990#84219999#84814000#84212100#84212300" .And.  Alltrim(cCfopPv) $ "5927#5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "27101932#27101931" .And.  Alltrim(cCfopPv) $ "5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5119#5656#5655#5910#5912#5923#5927#5949" .And. cClasFis == "60"
			cCodAjust	:= "RS052001"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		Endif
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// N�o faz nada por que j� existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situa��es que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")	// 9-Valor Cont�bil 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())
			
			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " C�d.Ajuste: " + cCodAjust + " CST: " + cClasFis + " C�d.Valor:" + cCodVlDec,"M410ABN")
			
		Endif
	//Se for Atrialub PR - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	ElseIf SM0->M0_ESTENT == "PR" .And. (INCLUI .Or. ALTERA)
		
		// VENDA DIFERIMENTO PARCIAL
		If Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170"
			lGrvF3K		:= .T.
			cTipValor	:= "8"
		// REMESSA BRINDE
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "41"
			cCodAjust	:= "PR809999"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// BONIFICA��O DIFERIMENTO PARCIAL
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170" 
			lGrvF3K		:= .T.
			cTipValor	:= "8"
		// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5905" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
		// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5663" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
		// REMESSA VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// TRANSF. ATIVO
		ElseIf Alltrim(cCfopPv) $ "5555" .And. cClasFis == "41"
			cCodAjust	:= "PR800014"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REM. EXPOSI��O OU FEIRA
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cClasFis == "40"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// RET. VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5921" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA COMODATO
		ElseIf Alltrim(cCfopPv) $ "5908" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA TROCA - ATIVO
		ElseIf Alltrim(cCfopPv) $ "5949" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA USO FORA DA EMPRESA
		ElseIf Alltrim(cCfopPv) $ "5554" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5915" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5916" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		Endif
		
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// N�o faz nada por que j� existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situa��es que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= cTipValor 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " C�d.Ajuste: " + cCodAjust + " CST: " + cClasFis + " C�d.Valor:" + cCodVlDec,"M410ABN")
			
		Endif
	// Se for Redelog RS - Chamado 22.800 - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	ElseIf SM0->M0_ESTENT == "RS" .And. (INCLUI .Or. ALTERA)
		
		If Alltrim(cCfopPv) $ "5554#5908#6552"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905"
			cCodAjust	:= "RS051511"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5906#5907#5665"
			cCodAjust	:= "RS051512"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5920"
			cCodAjust	:= "RS051011"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		Endif
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// N�o faz nada por que j� existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situa��es que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= "9"	// 9-Valor Cont�bil 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " C�d.Ajuste: " + cCodAjust + " CST: " + cClasFis + " C�d.Valor:" + cCodVlDec,"M410ABN")

		Endif		
	Endif
	RestArea(aAreaOld)
Return 
