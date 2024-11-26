//#INCLUDE "RWMAKE.CH"
#include "totvs.ch"

/*/{Protheus.doc} TMKCBPRO
(Adiciona um botao na barra de ferramentas do call center. )

@author Marcelo Lauschner
@since 04/10/2004
@version 1.0

@return aButtons, Array com novos bot�es

@example
(User Function TMKCBPRO()Local aButtons := {}
Alert("Ponto de Entrada TMKCBPRO")
AAdd(aButtons ,{ "TESTE1"	,	{|| Mensagem1()}, 'Teste 1','Teste 1'})
AAdd(aButtons ,{ "TESTE2"	,	{|| Mensagem2()}, 'Teste 2','Teste 2'})
Return(aButtons)
Static Function Mensagem1()
	Alert('Teste 1')Return
Static Function Mensagem2()
	Alert('Teste 2')
Return)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6787833)
/*/
User Function TMKCBPRO()
	Local aButtons := {}
	
	Local aAreaOld	:= GetArea()
	
	If __cUserId $ GetMv("BF_USRSERA")
		Aadd(aButtons,{"SIMULACA"	,{|| sfSendBoleto() }  ,"Reimprimir Boleto"})
	Endif
	
	//Aadd(aButtons,{"PRETO",{|| sfCallPhone()},"Liga��o IPBX"})
	
	// IAGO 26/09/2016 Adicionado consulta estoque michelin;
	// Marcelo 07/11/2020 - Alterado para usar consulta em SC e RS ( Continental )
	// Marcelo 09/12/2021 - Adicionado MG 
	If cEmpAnt+cFilAnt $ "0201#0204#0205#0208"
		Aadd(aButtons,{"PRETO",{|| U_BFESTC01()},"Estoque Pneus"})
	EndIf
	
	RestArea(aAreaOld)
	
Return (aButtons)



/*/{Protheus.doc} TMKBARLA
(long_description)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@return aButtons, Array com novos bot�es

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6787776)
/*/
User Function TMKBARLA()
	
	Local aButtons := {}
	
	Local aAreaOld	:= GetArea()
	
	Aadd(aButtons,{"AMARELO"	,{||U_BIG0381()}  ,"Rever A��o"})
	If cEmpAnt $ "02#11"
		Aadd(aButtons,{"AZUL"		,{||sfBonus()  }  ,"Promo��o" })
		Aadd(aButtons,{"VERDE"		,{||U_BIG0382()}  ,"Campanha"})
		Aadd(aButtons,{"VENDEDOR"	,{||U_BIG038()}   ,"Vendedor"})
		Aadd(aButtons,{"EMAIL" 		,{||U_BFAFAT03()} ,"Atualiza Email Cliente"})
	Endif
	
	/*DESCRI��O DE ALGUNS BOT�ES:
	WEB -> GLOBO
	PENDENTE -> UM CHECK LIST
	PROJETPMS -> GRAFICO DE PROJETOS
	SDUSETDEL -> FOLHA COM UM SINAL DE OK NO MEIO
	PRECO -> UM SIFR�O SOBRE UMA CAIXA
	ESTOMOVI -> SIMBOLO DA SKOL (CIRCULO COM SETA) SOBRE UMA CAIXA
	PMSPRINT -> IMPRESSORA (PARECE UMA M�QUINA DE ESCREVER)
	EMAIL -> UM @ SOBRE UM ENVELOPE AMARELO
	*/
	
	RestArea(aAreaOld)
	
Return (aButtons)



/*/{Protheus.doc} sfSendBoleto
(long_description)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/



/*/{Protheus.doc} sfSendBoleto
//TODO Descri��o auto-gerada.
@author Administrator
@since 19/05/2017
@version undefined

@type function
/*/
Static Function sfSendBoleto()
	
	If Type("aCols") <> "U" .And. !Empty(aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})])
		
		DbSelectArea("SE1")
		DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
		If DbSeek(xFilial("SE1")+aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+;
				aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+;
				aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+;
				aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})])
				
			If !Empty(SE1->E1_PORTADO) .Or. (SE1->(FieldPos("E1_BCOIMP")) > 0 .And. !Empty(SE1->E1_BCOIMP))
				U_DIS111B(.T./*lAuto*/,2/* IMPRESSAO/REIMPRESSAO nOpc*/,SE1->(Recno()),.T.)
			Else
				MsgAlert("N�o h� boleto impresso para este t�tulo!","Sem boleto!")
			Endif
			
		Endif
	Endif
	
Return




Static Function sfBonus()
	
	Local		aAreaOld	:= GetArea()
	Local 		aBonus   	:= {}      							// Array com os bonus que o cliente tem direito
	Local 		aBtn	   	:= Array(4)							// Array com os botoes da enchoicebar
	Local 		aSize    	:= MsAdvSize(.T.,.F.,400)			// Tamanho da Janela
	Local 		oDlg											// Janela Bonus
	Local 		oLbx											// Listbox com os bonus
	Local 		oBar											// Barra de Botoes
	Local 		aInfo    	:= {}								// Informacoes para a divisao da area de trabalho
	Local 		aObjects 	:= {}								// Definicoes dos objetos
	Local 		aPosLabel	:= {}								// Posicao do Objeto Label
	Local 		lRet	   	:= .F.								// Retorno da funcao
	Local		aButtons	:= {}
	Local 		nLinha    	:= Len(aCols)					// Contador do total de linhas adicionadas
	Local 		nCont	   	:= 0          				// Contador de Linhas do Acols
	Local 		nUsado    	:= Len(aHeader)				// Total de campos (colunas)
	Local 		nPProd    	:= aPosicoes[1][2]			// Posicao do Produto
	Local 		nPDescri  	:= aPosicoes[2][2]			// Posicao da descricao
	Local 		nPSitProd 	:= aPosicoes[3][2]			// Posicao da Situacao do Produto
	Local 		nPQtd     	:= aPosicoes[4][2]  		// Posicao da Quantidade
	Local 		nPVrUnit  	:= aPosicoes[5][2]			// Posicao do Valor unitario
	Local		nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
	Local 		nPLocal   	:= aPosicoes[7][2]			// Posicao do Local (Estoque)
	Local 		nPUm	   	:= aPosicoes[8][2]			// Posicao da Unidade de Medida
	Local		nPDesc 		:= aPosicoes[9][2]			// % Desconto
	Local		nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
	Local 		nPTES	   	:= aPosicoes[11][2]			// Posicao do TES
	Local 		nPCf		:= aPosicoes[12][2]			// Posicao do CFO
	Local 		nPItem		:= aPosicoes[20][2]			// Posicao do n�mero do item
	Local		nPPrcTab 	:= aPosicoes[15][2]			// Pre�o Tabela
	Local		nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
	Local		nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor
	Local		nPOper		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_OPER"})
	Local		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
	Local		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
	Local		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	Local		nPVlrTampa	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
	Local		nPxFlex		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
	Local		nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	Local		cCodReg		:= ""
	Local 		cItem		:= "00"						// N�mero do item a ser adicionado
	Local 		cEstado   	:= SuperGetMv("MV_ESTADO")	// Estado da empresa atual
	Local		nQteBrinde	:= 1
	Local		nPrcCombo	:= 0
	Local		aCodRegBon	:= {}
	Local		iQ
	Local		aRegCombo	:= {}
	Local		aItemCombo	:= {}
	Local		nPosCb		:= 0
	Local		oPrcCombo
	Local		nCol,nAux
	Local		cTabBk		:= ""
	Local		aRetTamp	:= {}
	
	//�������������������������������������������������������Ŀ
	//�Verifica se quem esta executando a rotina e Televendas �
	//���������������������������������������������������������
	If (TkGetTipoAte() == "4" .AND. nFolder == 2) .OR. (TkGetTipoAte() == "2")
	
	Else
		Help( " ", 1, "TLVROTINA" )
		Return(lRet)
	Endif
	
	If n == nLinha .And. Empty(aCols[n][nPProd]) .And. nLinha > 1 .And. ReadVar() <> "M->UB_PRODUTO"
		MsgStop("N�o � permitido selecionar um Combo com uma linha nova e vazia no GetDados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return lRet
	Endif
	For iQ := 1 To Len(aCols)
		If !aCols[iQ][nUsado+1] .And. !Empty(aCols[iQ][nPRegBnf])
			Aadd(aCodRegBon,aCols[iQ][nPRegBnf])
		Endif
	Next
	
	// Lista Bonifica��es/promo��es dispon�veis - Tipo 1
	aBonus	:= U_BFFATA43(aCodRegBon,M->UA_CLIENTE,M->UA_LOJA,M->UA_TABELA,M->UA_CONDPG,Nil,Nil,"1"/*cTipoRet*/)
	
	For iQ := 1 To Len(aBonus)
		nPosCb	:= Ascan(aRegCombo, {|x| AllTrim(x[1]) == Substr(aBonus[iQ,2],1,6)})
		If nPosCb == 0	
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+aBonus[iQ,3])
			Aadd(aRegCombo,{Substr(aBonus[iQ,2],1,6),;
		                    aBonus[iQ,3],;
		                    aBonus[iQ,4],;
		                    SB1->B1_DESC,;
		                    MaTabPrVen(M->UA_TABELA,aBonus[iQ,3],1,M->UA_CLIENTE,M->UA_LOJA,1/*nMoeda*/,M->UA_EMISSAO/*dDataVld*/,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/),;
		                    SB1->B1_XFXCOMI,;
		                    SB1->B1_DESCMAX})
		Endif
	Next
	
	//aBonus:= FtRgrBonus(aCols,{nPProd,nPQuant,nPTes},M->UA_CLIENTE,M->UA_LOJA,M->UA_TABELA,M->UA_CONDPG,NIL,NIL)
	
	//��������������������������������������������������
	//�Se nao tiver nenhum bonus exibe o help SEMDADOS �
	//��������������������������������������������������
	If (Len(aBonus) == 0)
		Help( " ", 1, "SEMDADOS" )
		Return(lRet)
	Endif
	
	//������������������������������������Ŀ
	//� Ajusta o tamanho do Label	       �
	//��������������������������������������
	aObjects := {}
	
	AAdd( aObjects, { 01, 01, .T., .T. , .F.} )
	
	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 0, 0 }
	aPosLabel:= MsObjSize( aInfo, aObjects,  , .T. )
	
	DEFINE MSDIALOG oDlg FROM  0,0 TO aSize[6],aSize[5] TITLE "Promo��es" PIXEL OF oMainWnd //"Bonus"
	
	
	//@aPosLabel[1,1] 	, aPosLabel[1,2] 	TO aPosLabel[1,3] , aPosLabel[1,4] LABEL "" OF oDlg  PIXEL
	
	@aPosLabel[1,1]  	, aPosLabel[1,2]+2  LISTBOX oLbxCombo FIELDS ;
		HEADER;
	"C�d.Regra",;		//	1
	"C�d.Prod",;		//	2
	"Nome Combo",;		//	3
	"Descri��o",;		// 	4
	"Pre�o Combo",;		//	5
	"Faixa Comiss�o",;	//  6
	"Desc.M�ximo";		//  7
	SIZE aPosLabel[1,4]-4 ,190 OF oDlg PIXEL
	
	oLbxCombo:SetArray(aRegCombo)
	oLbxCombo:bLine:={|| aRegCombo[oLbxCombo:nAt] }
	oLbxCombo:bChange := {|| sfItensCombo(aRegCombo[oLbxCombo:nAt,1],aBonus,@aItemCombo),oLbx:SetArray(aItemCombo),oLbx:bLine:={|| aItemCombo[oLbx:nAt] },oLbx:Refresh(),nPrcCombo := aRegCombo[oLbxCombo:nAt,5],oPrcCombo:Refresh() }
	
	sfItensCombo(aRegCombo[oLbxCombo:nAt,1],aBonus,@aItemCombo)
	
	nPrcCombo := aRegCombo[oLbxCombo:nAt,5]
	
	@aPosLabel[1,1]+197 	, aPosLabel[1,2]+2 Say "Informe Quantidade" of oDlg Pixel
	@aPosLabel[1,1]+195 	, aPosLabel[1,2]+60 MsGet nQteBrinde Size 40,10 Picture "@E 999,999" Valid nQteBrinde > 0  of oDlg Pixel
	
	@aPosLabel[1,1]+197 	, aPosLabel[1,2]+115 Say "Pre�o Negociado" of oDlg Pixel
	@aPosLabel[1,1]+195 	, aPosLabel[1,2]+160 MsGet oPrcCombo Var nPrcCombo	Picture "@E 999,999.99" Size 50,10 Valid sfVldPrc(@oPrcCombo,@nPrcCombo,@oLbx,@aItemCombo,aRegCombo[oLbxCombo:nAt,5],aRegCombo[oLbxCombo:nAt,7])  of oDlg Pixel
	
	@aPosLabel[1,1]+220  	, aPosLabel[1,2]+2  LISTBOX oLbx FIELDS ;
		HEADER;
		" ",;			//	1
	"C�d.Regra",;		//	2
	"C�d.Prod",;		//	3
	"Nome",;			//	4
	"Produto",;			//	5
	"Descricao",;		// 	6
	"Quantidade",;		//	7
	"Tipo Oper.",;		//	8
	"Pre�o Unit�rio",;	//	9
	"Soma Combo?",;		//	10
	"C�d.Tabela",;		//  11
	"Pre�o Venda",;		//  12
	"% Fra��o";			//  13
	SIZE aPosLabel[1,4]-4 ,aPosLabel[1,3]-250 OF oDlg PIXEL
	
	oLbx:SetArray(aItemCombo)
	oLbx:bLine:={|| aItemCombo[oLbx:nAt] }
	
	ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| lRet := .T. ,cCodReg	:= aRegCombo[oLbxCombo:nAt,1] ,oDlg:End()},{||oDlg:End()},,aButtons)
	
	If lRet
		
		If Empty(M->UA_CLIENTE)
			MsgAlert("N�o h� cliente informado ainda para validar a regra de promo��o!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			RestArea(aAreaOld)
			Return .F.
		Endif
		
		nTotal := Len(aItemCombo)
		
		cItem  := Alltrim(aCols[Len(aCols),nPItem])
		
		For nAux := 1 To nTotal
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1") + aItemCombo[nAux][5]) .And.  Substr(aItemCombo[nAux][2],1,6) == cCodReg
				// Se for o primeiro item e n�o tiver produto
				If n > 1 .Or. !Empty(aCols[nLinha,nPProd]) 					
					cItem	:= Soma1( cItem )
					AAdd(aCols,Array(nUsado+1))
					nLinha ++
					
					For nCol := 1 To nUsado
						If IsHeadRec(aHeader[nCol,2])
							aCols[nLinha,nCol] :=	 0
						ElseIf IsHeadAlias(aHeader[nCol,2])
							aCols[nLinha,nCol] := "SUB"
						Else
							aCols[nLinha,nCol] := CriaVar(aHeader[nCol,2],.T.)
						EndIf
					Next nCol
					aCols[nLinha,nUsado+1] 	:= .F.
					aCols[nLinha,nPItem]	:= cItem
				Endif
				
				aRetTamp	:= U_BFTMKA07(M->UA_CLIENTE,M->UA_LOJA,SB1->B1_COD,M->UA_REEMB,,,3)//U_BFTMKA07(M->UA_CLIENTE,M->UA_LOJA,SB1->B1_COD,M->UA_REEMB)
				nValTampa	:= aRetTamp[1]+aRetTamp[2]	 
				
				n := nLinha
				
				aCols[nLinha,nPProd] 	:= aItemCombo[nAux][5]
				M->UB_PRODUTO			:= aItemCombo[nAux][5]
				If ExistTrigger("UB_PRODUTO")
   					RunTrigger(2,Len(aCols))
				Endif	
				
				// For�o o zeramento da tabela para evitar chamada de ponto de entrada OM010PRC
				cTabBk			:= M->UA_TABELA
				M->UA_TABELA	:= ""
				Tk273Calcula("UB_PRODUTO",nLinha)
				//TKP000A(M->UB_PRODUTO,	nLinha,	NIL )
				
				M->UA_TABELA	:= cTabBk
				
				n	:= nLinha
				
				
				aCols[nLinha,nPQtd]  	:= aItemCombo[nAux][7]*nQteBrinde
				M->UB_QUANT				:= aItemCombo[nAux][7]*nQteBrinde
				
				
				TKP000B(M->UB_QUANT,	nLinha )
				
				aCols[nLinha,nPOper]	:= aItemCombo[nAux][8]// Tipo de opera��o
				aCols[nLinha,nPTes] 	:= MaTesInt(2,aCols[nLinha,nPOper],M->UA_CLIENTE,M->UA_LOJA,"C",aCols[nLinha,nPProd],"UB_TES")
				
				DbSelectArea("SF4")
				DbSetOrder(1)
				SF4->(MsSeek(xFilial("SF4")+aCols[nLinha,nPTes]))
				//������������������������������������������������������Ŀ
				//� Define o CFO                                         �
				//��������������������������������������������������������
				aDadosCFO := {}
				Aadd(aDadosCfo,{"OPERNF","S"})
				Aadd(aDadosCfo,{"TPCLIFOR","R"})
				Aadd(aDadosCfo,{"UFDEST"  ,SA1->A1_EST})
				Aadd(aDadosCfo,{"INSCR"   ,SA1->A1_INSCR})
				
				aCols[nLinha,nPCf] := MaFisCfo(,SF4->F4_CF,aDadosCfo)
				 
				
				nXPrcAux	:= aItemCombo[nAux][12]				
				// Soma-se o valor de Tampas do clientes
				nXPrcAux	+= nValTampa
				aCols[n][nPPrcMax]	:= nXPrcAux
				aCols[n][nPPrcMin]	:= nXPrcAux
				
				aCols[nLinha][nPVrUnit] := nXPrcAux
				
				aCols[nLinha][nPPrcTab]	:=  aItemCombo[nAux][9]				
				nXPrcAux	:= aCols[nLinha][nPPrcTab]
				
				aCols[n][nPCodTab]	:= aItemCombo[nAux][11]
				aCols[n][nPVlrTampa]:= aRetTamp[1]
				aCols[n][nPxFlex]	:= aRetTamp[2]
				
				aCols[nLinha][nPRegBnf]	:= aItemCombo[nAux][2]
				//Tk273Calcula("UB_PRODUTO",nLinha)
				
				// Recalcula o Valor de Desconto
				aCols[nLinha][nPValDesc] := Round( (nXPrcAux - aCols[nLinha][nPVrUnit]) * aCols[nLinha][nPQtd],TamSX3("UB_VALDESC")[2])
				If aCols[nLinha][nPValDesc] < 0
					aCols[nLinha][nPValDesc]	:= 0
				Endif
				// Recalcula o Percentual de desconto
				aCols[nLinha][nPDesc] := Round( aCols[nLinha][nPValDesc] / (nXPrcAux * aCols[nLinha][nPQtd]) * 100,TamSX3("UB_DESC")[2])
				
				// Recalcula o Valor do Acrescimo
				aCols[nLinha][nPValAcre] := Round( (aCols[nLinha][nPVrUnit] - nXPrcAux) * aCols[nLinha][nPQtd],TamSX3("UB_VALACRE")[2])
				If 	aCols[nLinha][nPValAcre] < 0
					aCols[nLinha][nPValAcre] 	:= 0
				Endif
				// Recalcula o Percentual de Acrescimo
				aCols[nLinha][nPAcre] := Round( aCols[nLinha][nPValAcre] / (nXPrcAux * aCols[nLinha][nPQtd]) * 100,TamSX3("UB_ACRE")[2])
				
				aCols[nLinha][nPVrUnit] := A410Arred(nXPrcAux - (aCols[nLinha][nPValDesc] / aCols[nLinha][nPQtd]) + (aCols[nLinha][nPValAcre] / aCols[nLinha][nPQtd]),"UB_VLRITEM")
				
				aCols[nLinha][nPVlrItem]:= A410Arred(aCols[nLinha][nPQtd] * aCols[nLinha][nPVrUnit],"UB_VLRITEM")
				
				MaFisAlt("IT_QUANT",aCols[nLinha][nPQtd],nLinha)
				MaFisAlt("IT_PRCUNI",aCols[nLinha][nPVrUnit],nLinha)
				MaFisAlt("IT_VALMERC",aCols[nLinha][nPVlrItem],nLinha)
				
				
				Eval(bListRefresh)
				//�����������������������������������������������������������Ŀ
				//�Atualiza a variavel n novamente, pois a funcao Tk273Calcula�
				//�executa um refresh no getDados.                            �
				//�������������������������������������������������������������
				//n	:= nLinha
				
				//MafisRef("IT_PRODUTO",	"TK273",M->UB_PRODUTO )
				
			Endif
			
		Next nAux
	Endif
	
Return(lRet)

Static Function sfItensCombo(cCodReg,aBonus,aItemCombo)
	
	Local	iE
	aItemCombo	:= {}
	For iE := 1 To Len(aBonus)
		If Substr(aBonus[iE][2],1,6) == cCodReg
			Aadd(aItemCombo,aClone(aBonus[iE]))
		Endif
	Next

Return 

Static Function sfVldPrc(oPrcCombo,nPrcCombo,oLbx,aItemCombo,nPrcTab,nDescMax)
	Local	iZ
	Local	lRet	:= .T.

	If nPrcCombo <   (Round(nPrcTab * (100-nDescMax)/100,2))
		lRet	:= .F.		
	Else
		For iZ := 1 To Len(aItemCombo)
			If aItemCombo[iZ,10] == "1"
				aItemCombo[iZ,12] := Round(nPrcCombo * aItemCombo[iZ,13] / 100 /  aItemCombo[iZ,7],2)
			Endif
		Next
		oLbx:Refresh()
	Endif
	
Return lRet 
/*/{Protheus.doc} sfCallPhone
(Efetuar liga��o via integra��o)
@author MarceloLauschner
@since 20/07/2015
@version 1.0
@return Nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCallPhone()
	
	Local		cUrlCall	:= ""
	Local		cIdUniq	:= ""
	Local		aIdUniq	:= {}
	Local		cTelefone	:= ""
	
	Local		aAreaOld	:= GetArea()
	Local		aAreaSA1	:= SA1->(GetArea())
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		oDlgCli
	Local		cCliF4		:= SA1->A1_COD
	Local		cLojF4		:= SA1->A1_LOJA
	Local		lOk			:= .F.
	Local		cCallDest	:= "0" + Alltrim(SA1->A1_DDD) + Alltrim(SA1->A1_TEL)
	Private 	oCallDest
	
	DEFINE MSDIALOG oDlgCli FROM 000,000 TO 120,400 Of oMainWnd Pixel Title OemToAnsi("Efetuar liga��o para o Cliente" )
	
	@ 010,005 Say "Cliente/Loja" of oDlgCli Pixel
	@ 010,050 MsGet cCliF4	Size 40,10 Valid sfVldCliCall(cCliF4,cLojF4,@cCallDest) F3 "SA1" Size 30,10 of oDlgCli Pixel
	@ 010,090 MsGet cLojF4	Size 40,10 Valid sfVldCliCall(cCliF4,cLojF4,@cCallDest) Size 15,10 of oDlgCli Pixel
	@ 021,005 Say "Telefone" of oDlgCli Pixel
	@ 022,050 MsGet oCallDest Var cCallDest Size 40,10  Size 15,10 of oDlgCli Pixel
	
	Activate MsDialog oDlgCli On Init EnchoiceBar(oDlgCli,{|| lOk := .T., oDlgCli:End() },{|| oDlgCli:End()},,)
	
	If lOk
		DbSelectArea("SU7")
		DbSetOrder(4)
		DbSeek(xFilial("SU7")+__cUserId)
		
		cUrlCall	:= "http://192.168.10.12/api/logon.php?" + Alltrim(SU7->U7_AGENTID)+"&dispositivo="+Alltrim(SU7->U7_XDISPOS)
		//{"sessao":"h8833r8u3dnjpvptpav1njvsa5"}
		
		//MsgAlert(cUrlCall)
		
		cIdUniq	:= HttpGet(cUrlCall)
		aIdUniq	:= StrTokArr(cIdUniq,":")
		cIdUniq	:= aIdUniq[2]
		cIdUniq	:= StrTran(cIdUniq,"}","")
		cIdUniq	:= StrTran(cIdUniq,'"',"")
		//             http://192.168.10.12/api/chamada/realizaChamada.php?usuario=2074&pass=83379130&destino=30358355&mobile=false
		cUrlCall	:= "http://192.168.10.12/api/chamada/realizaChamada.php?" + Alltrim(SU7->U7_AGENTID) +"&destino="+Alltrim(cCallDest)+"&mobile=false&sid="+cIdUniq
		
		If MsgYesNo("Pronto para fazer a liga��o? ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Discagem!")
			MsgAlert(HttpGet(cUrlCall))
		Endif
		
	Endif
	
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaSA1)
	RestArea(aAreaOld)
	
	
	
Return

Static Function sfVldCliCall(cCliF4,cLojF4,cCallDest)
	
	Local	lRet	:= .F.
	
	cCallDest		:= Space(30)
	DbSelectArea("SA1")
	DbSetOrder(1)
	lRet	:= DbSeek(xFilial("SA1")+cCliF4+cLojF4)
	
	If lRet
		cCallDest := "0" + Alltrim(SA1->A1_DDD) + Alltrim(SA1->A1_TEL)
	Endif
	oCallDest:Refresh()
	
Return lRet



/*/{Protheus.doc} sfRestPerg
(Salva e restaura perguntas para controle da Rotina)
@author MarceloLauschner
@since 22/04/2014
@version 1.0
@param lSalvaPerg, ${param_type}, (Descri��o do par�metro)
@param aPerguntas, array, (Descri��o do par�metro)
@param nTamSx1, num�rico, (Descri��o do par�metro)
@return array, Perguntas num vetor
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRestPerg(lSalvaPerg,aPerguntas,nTamSx1)
	
	Local ni
	DEFAULT lSalvaPerg	:=.F.
	Default nTamSX1		:= 40
	DEFAULT aPerguntas	:=Array(nTamSX1)
	
	For ni := 1 to Len(aPerguntas)
		If lSalvaPerg
			aPerguntas[ni] := &("mv_par"+StrZero(ni,2))
		Else
			&("mv_par"+StrZero(ni,2)) :=	aPerguntas[ni]
		EndIf
	Next ni
	
Return(aPerguntas)
