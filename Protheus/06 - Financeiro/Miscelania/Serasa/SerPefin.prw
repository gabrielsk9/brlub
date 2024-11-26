#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Define _Enter Chr( 13 ) + Chr( 10 )
#DEFINE N_REMESSA    1
#DEFINE N_EXCLUSAO   2
#DEFINE N_SELECIONAR 3
#DEFINE N_DESMARCAR  4

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �SERPEFIN  �Autor  � Eduardo Donato     � Data �  Abr/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     �                                                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       �Protheus8.11 - Parmalat                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function SerPefin(lInFilCli,cInCliIni,cInCliFim,nINMVPAR01)

	Local 	Titulo		:= OemToAnsi("Serasa-Pefin")
	Local 	cDesc1		:= OemToAnsi("Essa Rotina tem como objetivo Gerar o arquivo de remessa")
	Local 	cDesc2		:= OemToAnsi("para o Serasa, tendo como Objetivo a Inclus�o do Cnpj das")
	Local 	cDesc3		:= OemToAnsi("Empresas que est�o com d�bitos em aberto com a " + Capital(SM0->M0_NOMECOM))
	Local 	aSay	  	:= {}
	Local 	aButton 	:= {}
	Local 	nOpc	  	:= 0
	Local 	aPergSX1	:= {}
	Local	aAreaOld	:= {}
	Private _cMarca		:= 'Ok'
	Private cPerg		:= "SERPEFINF "
	Private cNorma 		:= ''
	Private cDest	 	:= ''
	Default lInFilCli	:= .F.
	Private lFilCli		:= lInFilCli
	Default nINMVPAR01	:= 1
	Private nMV_PAR01	:= nINMVPAR01

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	If lFilCli 
		FSeleciona(cInCliIni,cInCliFim)
		Return	
	Endif
	//             "X1_GRUPO","X1_ORDEM","X1_PERGUNT"   ,"X1_PERSPA","X1_PERENG","X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO","X1_DECIMAL","X1_PRESEL","X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01","X1_DEFSPA1","X1_DEFENG1","X1_CNT01","X1_VAR02"	,"X1_DEF02","X1_DEFSPA2","X1_DEFENG2","X1_CNT02","X1_VAR03"	,"X1_DEF03"		,"X1_DEFSPA3"  ,"X1_DEFENG3"	,"X1_CNT03","X1_VAR04","X1_DEF04"	  ,"X1_DEFSPA4"	 ,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"

	Aadd(aPergSX1,{ cPerg    ,"01"      ,"Tipo Remessa:","" 		,""			,"mv_ch1"	 ,"N"		,01			 ,0			  ,0		  ,"C"		,""			,"MV_PAR01" ,"Remessa" ,"Remessa"   ,"Remessa"   ,""		,""			,"Exclus�o","Exclus�o"  ,"Exclus�o"  ,""		,""			,"Marcar Envio" ,"Marcar Envio" ,"Marcar Envio" ,""		   ,""		  ,"Limpar Enviar","Limpar Envio","Limpar Envio",""         ,""         ,""         ,""          ,""            ,""         ,""         ,""         ,""             ,""})
	Aadd(aPergSX1,{cPerg,"02","Destino:"			,"","","mv_ch2","C",40,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	aAdd(aPergSX1,{cPerg,"03","Prefixo De:"		,"","","mv_ch3","C",03,0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","","","" })
	Aadd(aPergSX1,{cPerg,"04","Prefixo Ate:"	,"","","mv_ch4","C",03,0,0,"G","","MV_PAR04","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{cPerg,"05","Numero De:"		,"","","mv_ch5","C",06,0,0,"G","","MV_PAR05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aPergSX1,{cPerg,"06","Numero Ate:"		,"","","mv_ch6","C",06,0,0,"G","","MV_PAR06","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{cPerg,"07","Natureza De:"	,"","","mv_ch7","C",10,0,0,"G","","MV_PAR07","","","","","","","","","","","","","","","","","","","","","","","","","SED","","","",""})
	Aadd(aPergSX1,{cPerg,"08","Natureza Ate:"	,"","","mv_ch8","C",10,0,0,"G","","MV_PAR08","","","","","","","","","","","","","","","","","","","","","","","","","SED","","","",""})

	Aadd(aPergSX1,{cPerg,"09","Tipo De:"			,"","","mv_ch9","C",03,0,0,"G","","MV_PAR09","","","","","","","","","","","","","","","","","","","","","","","","","SES","","","",""})
	Aadd(aPergSX1,{cPerg,"10","Tipo Ate:"			,"","","mv_cha","C",03,0,0,"G","","MV_PAR10","","","","","","","","","","","","","","","","","","","","","","","","","SES","","","",""})

	Aadd(aPergSX1,{cPerg,"11","Cliente De:"		,"","","mv_chb","C",06,0,0,"G","","MV_PAR11","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})
	Aadd(aPergSX1,{cPerg,"12","Cliente Ate:"	,"","","mv_chc","C",06,0,0,"G","","MV_PAR12","","","","","","","","","","","","","","","","","","","","","","","","","SA1","","","",""})

	Aadd(aPergSX1,{cPerg,"13","Loja De:"			,"","","mv_chd","C",02,0,0,"G","","MV_PAR13","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aPergSX1,{cPerg,"14","Loja Ate:"			,"","","mv_che","C",02,0,0,"G","","MV_PAR14","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{cPerg,"15","Portador De:"	,"","","mv_chf","C",04,0,0,"G","","MV_PAR15","","","","","","","","","","","","","","","","","","","","","","","","","SA6","","","",""})
	Aadd(aPergSX1,{cPerg,"16","Portador Ate:"	,"","","mv_chg","C",04,0,0,"G","","MV_PAR16","","","","","","","","","","","","","","","","","","","","","","","","","SA6","","","",""})

	Aadd(aPergSX1,{cPerg,"17","Emissao De:"		,"","","mv_chh","D",08,0,0,"G","","MV_PAR17","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aPergSX1,{cPerg,"18","Emissao Ate:"	,"","","mv_chi","D",08,0,0,"G","","MV_PAR18","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{cPerg,"19","Vencto De:"		,"","","mv_chj","D",08,0,0,"G","","MV_PAR19","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aPergSX1,{cPerg,"20","Vencto Ate:"		,"","","mv_chk","D",08,0,0,"G","","MV_PAR20","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{cPerg,"21","Valor De:"			,"","","mv_chl","N",17,02,0,"G","","MV_PAR21","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aPergSX1,{cPerg,"22","Valor Ate:"		,"","","mv_chm","N",17,02,0,"G","","MV_PAR22","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

	Aadd(aPergSX1,{ cPerg    ,"23"      ,"Saldo se Exclus�o","" 		,""			,"mv_chn"	 ,"N"		,01			 ,0			  ,0		  ,"C"		,""			,"MV_PAR23" ,"Saldo Zerado" ,"Saldo Zerado"   ,"Saldo Zerado"   ,""		,""			,"Baixa Parcial","Baixa Parcial"  ,"Baixa Parcial"  ,""		,""			,"Sem Baixas" ,"Sem Baixas" ,"Sem Baixas" ,""		   ,""		  ,"Todos","Todos","Todos",""         ,""         ,""         ,""          ,""            ,""         ,""         ,""         ,""             ,""})

	DbSelectArea("SX1")
	DbSetOrder(1)
	For i:=1 to Len(aPergSX1)
		If !dbSeek(cPerg+aPergSX1[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aPergSX1[i])
					FieldPut(j,aPergSX1[i,j])
				Endif
			Next
			MsUnlock("SX1")
		Endif
	Next

	If lFilCli 
		
		U_GravaSX1(cPerg,aPergSX1[11,2],cInCliIni)
		
		U_GravaSX1(cPerg,aPergSX1[12,2],cInCliIni)
	
		U_GravaSX1(cPerg,aPergSX1[1,2],nMV_PAR01)
		
	Endif

	
	Pergunte(cPerg,.T.)

	nMV_PAR01	:= MV_PAR01

	aAdd( aSay, cDesc1 )
	aAdd( aSay, cDesc2 )
	aAdd( aSay, cDesc3 )

	aAdd( aButton, { 1, .T., {|| nOpc := 1, FechaBatch()	}} )
	aAdd( aButton, { 2, .T., {|| FechaBatch()           	}} )
	Aadd( aButton, { 5, .T., {|| Pergunte(cPerg,.T. ) 		}} )

	FormBatch( Titulo, aSay, aButton )

	If nOpc == 1
		cDest := AllTrim( Mv_Par02 )
		cNorma:= IIF( Mv_PAR01 == N_REMESSA, 'serasa_pefin.ini',IIf(MV_PAR01 == N_EXCLUSAO, 'serasa_pefin_1.ini',''))
		Begin Transaction
			Processa({ || ValParam() })
		End Transaction	
	EndIf

Return .T.

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �ValParam  �Autor  � Eduardo Donato     � Data �  Mai/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     �Valida o Conteudo dos Parametros                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function ValParam()

	Local lRet := .T.

	If Empty( Mv_Par02 ) .Or. Empty( Mv_Par04 ) .Or. Empty( Mv_Par06 ) .Or. Empty( Mv_Par08 ) .Or. ;
	Empty( Mv_Par10 ) .Or. Empty( Mv_Par12 ) .Or. Empty( Mv_Par14 ) .Or. Empty( Mv_Par16 ) .Or. ;
	Empty( Mv_Par20 ) .Or. Empty( Mv_Par22 )
		ApMsgStop( 'Preencha Corretamente os Parametros Inicias !','Aten��o' )
		Return .F.
	EndIf

	FSeleciona()

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �FSeleciona�Autor  �  Eduardo Donato     � Data �  Abr/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     �Rotina responsavel por Processar a Consulta e Montar a		  ���
���          �MarkBrow para a Selecao dos Titulos.                        ���
�������������������������������������������������������������������������͹��
���Uso       �Protheus8.11 - Parmalat                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function FSeleciona(cInCliIni,cInCliFim)

	Private _oDlg
	Private oGet1

	DEFINE MSDIALOG _oDlg TITLE OemtoAnsi("Sele��o T�tulos para Serasa-Pefin " + IIF( nMv_Par01 == 1,"'Envio de Remessa'",IIf(nMV_PAR01 == 2,"'Envio de Exclus�o'",IIf(nMV_PAR01 == 3,"'Marcar para Envio'","'Limpar marcados para Envio'")))) FROM C(145),C(0-3) TO C(608),C(780) PIXEL

	@ C(006),C(002) TO C(232),C(392) LABEL "Serasa - Pefin" PIXEL OF _oDlg
	@ C(210),C(005) Button OemtoAnsi("&Marcar Todos") Size C(050),C(010) Action( MarkAll( 1 ) ) PIXEL OF _oDlg
	@ C(210),C(065) Button OemtoAnsi("&Desmarcar Todos") Size C(050),C(010) Action( MarkAll( 2 ) ) PIXEL OF _oDlg
	If nMV_PAR01 == N_REMESSA
		@ C(210),C(185) Button OemtoAnsi("&Gerar Arquivo Envio") Size C(050),C(010) Action(GeraRlt2(), GeraArq(),_oDlg:End() ) PIXEL OF _oDlg
		@ C(210),C(125) Button OemtoAnsi("&Imprimir") Size C(050),C(010) Action( GeraRlt2() ) PIXEL OF _oDlg
	ElseIf nMV_PAR01 == N_EXCLUSAO
		@ C(210),C(185) Button OemtoAnsi("&Gerar Arquivo Exclus�o") Size C(050),C(010) Action(GeraRlt2(), GeraArq(),_oDlg:End() ) PIXEL OF _oDlg
		@ C(210),C(125) Button OemtoAnsi("&Imprimir") Size C(050),C(010) Action( GeraRlt2() ) PIXEL OF _oDlg
	ElseIf nMV_PAR01 == N_SELECIONAR
		@ C(210),C(245) Button OemtoAnsi("&Marcar Envio") Size C(050),C(010) Action( GeraArq(),_oDlg:End() ) PIXEL OF _oDlg
	ElseIf nMV_PAR01 == N_DESMARCAR
		@ C(210),C(245) Button OemtoAnsi("&Excluir Marcados") Size C(050),C(010) Action( GeraArq(),_oDlg:End() ) PIXEL OF _oDlg
	Endif
	@ C(210),C(305) Button OemtoAnsi("&Sair") Size C(050),C(010) Action( _oDlg:End() ) PIXEL OF _oDlg

	If !PRMAGet1(cInCliIni,cInCliFim)   
	
	Else	
		// Executo a marca��o de todos os titulos como padr�o
		MarkAll( 1 )		
	Endif
	
	ACTIVATE MSDIALOG _oDlg CENTERED

Return(.T.)

/*������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������Ŀ��
���Programa   �PRMAGet1()  � Autor �Eduardo Donato     � Data �27/04/2007���
����������������������������������������������������������������������������Ĵ��
���Descricao  � Montagem da GetDados                                         ���
����������������������������������������������������������������������������Ĵ��
���Observacao � O Objeto oGet1  foi criado como Private no inicio do Fonte   ���
���           � desta forma voce podera trata-lo em qualquer parte do        ���
���           � seu programa:                                                ���
���           �                                                              ���
���           � Para acessar o aCols desta MsNewGetDados: oGet1 :aCols[nX,nY]���
���           � Para acessar o aHeader: oGet1 :aHeader[nX,nY]                ���
���           � Para acessar o "n"    : oGet1 :nAT                           ���
�����������������������������������������������������������������������������ٱ�
��������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function PRMAGet1(cInCliIni,cInCliFim)

	Local cQry 			:= ""
	Local lRet			:= .T.
	Local nCols			:= 0
	Local nUsado		:= 0
	Local nX			:= 0
	Local nY			:= 0
	Local nOpcx			:= 1
	Local nSuperior    	:= C(019)           // Distancia entre a MsNewGetDados e o extremidade superior do objeto que a contem
	Local nEsquerda    	:= C(003)           // Distancia entre a MsNewGetDados e o extremidade esquerda do objeto que a contem
	Local nInferior    	:= C(201)           // Distancia entre a MsNewGetDados e o extremidade inferior do objeto que a contem
	Local nDireita     	:= C(391)           // Distancia entre a MsNewGetDados e o extremidade direita  do objeto que a contem
	Local nOpc         	:= GD_INSERT+GD_DELETE+GD_UPDATE
	Local cLinhaOk     	:= "AllwaysTrue"    // Funcao executada para validar o contexto da linha atual do aCols
	Local cTudoOk      	:= "AllwaysTrue"    // Funcao executada para validar o contexto geral da MsNewGetDados (todo aCols)
	Local cIniCpos     	:= ""               // Nome dos campos do tipo caracter que utilizarao incremento automatico.
	Local nFreeze      	:= 000              // Campos estaticos na GetDados.
	Local nMax         	:= 000              // Numero maximo de linhas permitidas. Valor padrao 99
	Local cCampoOk     	:= "AllwaysTrue"    // Funcao executada na validacao do campo
	Local cSuperApagar 	:= ""               // Funcao executada quando pressionada as teclas <Ctrl>+<Delete>
	Local cApagaOk     	:= "AllwaysTrue"    // Funcao executada para validar a exclusao de uma linha do aCols
	Local oWnd          := _oDlg
	Local aHead        	:= {}               // Array a ser tratado internamente na MsNewGetDados como aHeader
	Local aCol         	:= {}               // Array a ser tratado internamente na MsNewGetDados como aCols
	Local aAlter       	:= {"E1_OK","E1_XMEMOBS"}
	Local cCampo 		:= ""
	Local aCpoGDa       := {"E1_OK",;		// 1
	"E1_PREFIXO",;	// 2
	"E1_NUM",;		// 3
	"E1_PARCELA" ,; // 4
	"E1_NATUREZ" ,;	// 5
	"E1_TIPO" ,;	// 6 	
	"E1_VALOR",;	// 7
	"E1_SALDO",;	// 8	
	"E1_NOMCLI",;	// 9
	"E1_LOJA",;     // 10    	
	"A1_CGC",;		// 11
	"E1_EMISSAO",;	// 12
	"E1_VENCTO",;	// 13
	"E1_VENCREA",;	// 14
	"E1_XMEMOBS" } // 15

	// dbSelectArea("SX3")
	// SX3->(dbSetOrder(2)) // Campo
	// For nX := 1 to Len(aCpoGDa)
	// 	cCampo := aCpoGDa[nX]
	// 		Aadd(aHead,{ IIF(nX == 1,'', ;
	// 		AllTrim(X3Titulo())),;
	// 		SX3->X3_CAMPO	,;
	// 		SX3->X3_PICTURE,;
	// 		SX3->X3_TAMANHO,;
	// 		SX3->X3_DECIMAL,;
	// 		SX3->X3_VALID	,;
	// 		SX3->X3_USADO	,;
	// 		SX3->X3_TIPO	,;
	// 		SX3->X3_F3 		,;
	// 		SX3->X3_CONTEXT,;
	// 		SX3->X3_CBOX	,;
	// 		SX3->X3_RELACAO })
	// 	nUsado++
	// Next nX

	For nX := 1 to Len(aCpoGDa)
		cCampo := aCpoGDa[nX]
		Aadd(aHeader,{IIF(nX == 1,'',AllTrim(GetSx3Cache(cCampo,"X3_TITULO")))	,;	//	1
			GetSx3Cache(cCampo,"X3_CAMPO")										,;	//	2
			GetSx3Cache(cCampo,"X3_PICTURE")									,;	//	3
			GetSx3Cache(cCampo,"X3_TAMANHO")									,;	//	4
			GetSx3Cache(cCampo,"X3_DECIMAL")									,;	//	5
			GetSx3Cache(cCampo,"X3_VALID")										,;	//	SX3->X3_VALID	,;	//	6
			GetSx3Cache(cCampo,"X3_USADO")										,;	//	7
			GetSx3Cache(cCampo,"X3_TIPO")										,;	//	8
			GetSx3Cache(cCampo,"X3_F3")											,;	//	9
			GetSx3Cache(cCampo,"X3_CONTEXT")									,;	//	10
			GetSx3Cache(cCampo,"X3_CBOX")										,;	//	11
			GetSx3Cache(cCampo,"X3_RELACAO")									})	//SX3->X3_RELACAO })					//	12
			nUsado++
			&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),4,7)) := nUsado
	Next


	cQry := "SELECT SE1.R_E_C_N_O_ SE1RECNO,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_NATUREZ,E1_NOMCLI,E1_LOJA,A1_CGC,E1_EMISSAO,"
	cQry += "       E1_VENCTO,E1_VENCREA,E1_VALOR,E1_SALDO,E1_XMEMOBS "
	cQry += "  FROM "+RetSqlName("SE1")+" SE1, "+RetSqlName("SA1") + " SA1 "
	cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "            
	cQry += "   AND A1_LOJA = E1_LOJA "
	cQry += "   AND A1_COD = E1_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry += "   AND E1_FILORIG = '"+cFilAnt+"' "       // Garanto que apenas titulos da propria filial originaria ser�o apresentados na tela
	cQry += "   AND E1_TIPO NOT IN('NCC','RA','RAT','CHQ','CHD','TES') " 
	cQry += "   AND E1_PREFIXO NOT IN('TES') "   
	If nMV_PAR01 == N_REMESSA
		cQry += "  AND E1_X_STATU = 'X' "
		cQry += "  AND E1_OPER1 = '"+GetMv("GM_SERASA1")+"' "
	ElseIf nMV_PAR01 == N_EXCLUSAO
		cQry += "   AND E1_X_STATU = 'R' " 
		cQry += "   AND E1_OPER1 != '"+GetMv("GM_SERASA1")+"' "
		cQry += "   AND E1_PREFIXO BETWEEN '"+Mv_Par03+"' AND '"+Mv_Par04+"' "
		cQry += "   AND E1_NUM  BETWEEN '"+Mv_Par05+"' AND '"+Mv_Par06+"'  "
		cQry += "   AND E1_NATUREZ BETWEEN '"+Mv_Par07+"' AND '"+Mv_Par08+"' "
		cQry += "   AND E1_TIPO    BETWEEN '"+Mv_Par09+"' AND '"+Mv_Par10+"' "
		cQry += "   AND E1_CLIENTE BETWEEN '"+Mv_Par11+"' AND '"+Mv_Par12+"' "
		cQry += "   AND E1_LOJA    BETWEEN '"+Mv_Par13+"' AND '"+Mv_Par14+"' "
		cQry += "   AND E1_PORTADO BETWEEN '"+Mv_Par15+"' AND '"+Mv_Par16+"' "
		cQry += "   AND E1_EMISSAO BETWEEN '"+Dtos( Mv_Par17 )+"' AND '"+Dtos( Mv_Par18 )+"' "
		cQry += "   AND E1_VENCREA BETWEEN '"+Dtos( Mv_Par19 )+"' AND '"+Dtos( Mv_Par20 )+"' "
		cQry += "   AND E1_VALOR   BETWEEN '"+Str( Mv_Par21 )+"' AND '"+Str( Mv_Par22 )+"' "

		If MV_PAR23 == 1 // Apenas Saldo Zerado
			cQry += "   AND E1_SALDO = 0 "
		ElseIf MV_PAR23 == 2 // Apenas com baixa parcial
			cQry += "   AND E1_SALDO > 0 "
			cQry += "   AND E1_BAIXA != '        ' "
		ElseIf MV_PAR23 == 3 // Apenas sem Baixas
			cQry += "   AND E1_BAIXA = '        ' "
		Endif  		

	ElseIf nMV_PAR01 == N_SELECIONAR
		cQry += " AND E1_VENCTO BETWEEN TO_CHAR(SYSDATE-1790,'YYYYMMDD') AND TO_CHAR(SYSDATE-5,'YYYYMMDD') " 
		// Data da ocorr�ncia ( AAAAMMDD) � data do vencimento da d�vida, n�o superior a 4 anos e 11 meses , e inferior � 4 dias da data do movimento
		cQry += " AND E1_SALDO > 0 "
		cQry += " AND E1_X_STATU = ' ' "
		cQry += " AND E1_OPER1 = '"+Space(TamSX3("E1_OPER1")[1])+"' "
		If lFilCli
			cQry += " AND E1_CLIENTE >= '"+cInCliIni+"' "
			cQry += " AND E1_CLIENTE <= '"+cInCliFim+"' "
		Else
			cQry += "   AND E1_PREFIXO BETWEEN '"+Mv_Par03+"' AND '"+Mv_Par04+"' "
			cQry += "   AND E1_NUM  BETWEEN '"+Mv_Par05+"' AND '"+Mv_Par06+"'  "
			cQry += "   AND E1_NATUREZ BETWEEN '"+Mv_Par07+"' AND '"+Mv_Par08+"' "
			cQry += "   AND E1_TIPO    BETWEEN '"+Mv_Par09+"' AND '"+Mv_Par10+"' "
			cQry += "   AND E1_CLIENTE BETWEEN '"+Mv_Par11+"' AND '"+Mv_Par12+"' "
			cQry += "   AND E1_LOJA    BETWEEN '"+Mv_Par13+"' AND '"+Mv_Par14+"' "
			cQry += "   AND E1_PORTADO BETWEEN '"+Mv_Par15+"' AND '"+Mv_Par16+"' "
			cQry += "   AND E1_EMISSAO BETWEEN '"+Dtos( Mv_Par17 )+"' AND '"+Dtos( Mv_Par18 )+"' "
			cQry += "   AND E1_VENCREA BETWEEN '"+Dtos( Mv_Par19 )+"' AND '"+Dtos( Mv_Par20 )+"' "
			cQry += "   AND E1_VALOR   BETWEEN '"+Str( Mv_Par21 )+"' AND '"+Str( Mv_Par22 )+"' "
		Endif
		// Permite escolher titulos marcados para envio para desmarcar o envio para Pefin	
	ElseIf nMV_PAR01 == N_DESMARCAR
		cQry += "  AND E1_X_STATU = 'X' "
		cQry += "  AND E1_OPER1 = '"+Alltrim(GetMv("GM_SERASA1"))+"' "
	EndIf
	cQry += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_LOJA"

	AADD( aHead, { "Recno WT","SE1_REC_WT", "", 09, 0,, GetSx3Cache("SE1_REC_WT","X3_USADO"), "N", "SE1", "V","",""} )
	
	//Msgalert(cQry)
	TcQuery cQry New Alias 'WORK'  
	                                             
	TcSetField("WORK","E1_EMISSAO","D")
	TcSetField("WORK","E1_VENCREA","D")
	TcSetField("WORK","E1_VENCTO","D")

	dbSelectArea( 'WORK' )
	WORK->( dbGoTop() )
	
	If Eof()
		MsgAlert('N�o Existem Registros Relacionados a Essa Consulta !', 'Aten��o')
		WORK->( dbCloseArea() )
		Return .F.	
	Else
		While !Eof()
			//Msgalert(WORK->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_NATUREZ+E1_NOMCLI))
			Aadd(aCol,Array(Len(aHead)+1))
			nCols ++
			
			For nY := 1 To Len(aHead)-1
				If aCpoGDa[nY] == "E1_OK"
					aCol[nCols][nY] := CriaVar("E1_OK",.F.)
				ElseIf aCpoGDa[nY] $ "E1_EMISSAO#E1_VENCTO#E1_VENCREA"          
					aCol[nCols][nY] := FieldGet(FieldPos(Alltrim(aHead[nY][2])))					
				ElseIf aCpoGDa[nY] $ "E1_XMEMOBS"
					DbSelectArea("SE1")
					DbGoto(WORK->SE1RECNO)
					aCol[nCols][nY] := SE1->E1_XMEMOBS
				Else          
					aCol[nCols][nY] := FieldGet(FieldPos(Alltrim(aHead[nY][2])))
				Endif
			Next nY
			aCol[nCols][nUsado+1] := WORK->SE1RECNO
			aCol[nCols][nUsado+2] := .F.
			dbSelectArea( 'WORK' )
			WORK->( dbSkip() )
		EndDo
		WORK->( dbCloseArea() )
		
		oGet1 := MsNewGetDados():New(nSuperior,nEsquerda,nInferior,nDireita,nOpc,cLinhaOk,cTudoOk,cIniCpos,;
		aAlter,nFreeze,nMax,cCampoOk,cSuperApagar,cApagaOk,oWnd,aHead,aCol)
		oGet1:oBrowse:bLDblClick := {|| Iif(oGet1:oBrowse:nColPos == 1 ,(DuploC1(),oGet1:oBrowse:Refresh()),oGet1:EditCell()) }
		oGet1:oBrowse:Refresh()
	EndIf

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �GeraArq   �Autor  � Eduardo Donato     � Data �  Mai/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     | Rotina Responsavel por separar os registros selecionados   ���
���          � e envia-los para a rotina Padrao.                          ���
�������������������������������������������������������������������������͹��
���Uso       � Versao 8.11 - Parmalat																			���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function GeraArq()

	Local lRet := .T.
	Local _k := 0, _j := 0
	Local aDadosSE1 := {}
	Local cGM_SERASA1 := AllTrim(GetMv('GM_SERASA1'))
	Local cGM_SERASA7 := AllTrim(GetMv('GM_SERASA7'))
	Local cDir
	Local cDrive 
	Local cNome
	Local cExt 

	If nMV_PAR01 == N_REMESSA
		If !MsgYesNo("Deseja realmente continuar e gerar o arquivo '"+mv_par02+"' do SERASA-PEFIN - REMESSA?")
			Return
		Endif
		// Quebra o nome do arquivo de destino em Drive / diret�rio / nome arquivo / extens�o 
		SplitPath( mv_par02, @cDrive, @cDir, @cNome, @cExt )
		
		// Verifica se o Drive e Diret�rio existem 
		If !(ExistDir(cDrive+cDir))
			MsgAlert("Diret�rito inexistente: " + cDrive+cDir )
			Return 
		Endif 
		
		// Inclui no nome do arquivo o n�mero da remessa para nunca se sobrepor o arquivo e tb facilitar a localiza��o do n�mero de remessa pelo nome do arquivo 
		cDest 	+= "_seq_"+cValToChar(GetMv("GM_SERASA2")) + ".txt"
	
	ElseIf nMV_PAR01 == N_EXCLUSAO
		If !MsgYesNo("Deseja realmente continuar e gerar o arquivo '"+mv_par02+"' do SERASA-PEFIN - EXCLUS�O?")
			Return
		Endif

		// Quebra o nome do arquivo de destino em Drive / diret�rio / nome arquivo / extens�o 
		SplitPath( mv_par02, @cDrive, @cDir, @cNome, @cExt )
		
		// Verifica se o Drive e Diret�rio existem 
		If !(ExistDir(cDrive+cDir))
			MsgAlert("Diret�rito inexistente: " + cDrive+cDir )
			Return 
		Endif 
		
		// Inclui no nome do arquivo o n�mero da remessa para nunca se sobrepor o arquivo e tb facilitar a localiza��o do n�mero de remessa pelo nome do arquivo 
		cDest 	+= "_seq_"+cValToChar(GetMv("GM_SERASA2")) + ".txt"
	

	ElseIf nMV_PAR01 == N_SELECIONAR
		If !MsgYesNo("Deseja realmente continuar e marcar os titulos para posterior envio para SERASA-PEFIN?")
			Return
		Endif
	ElseIf nMV_PAR01 == N_DESMARCAR
		If !MsgYesNo("Deseja realmente continuar e estornar envio dos titulos para envio para SERASA-PEFIN?")
			Return
		Endif
	Endif



	dbSelectArea( 'SE1' )
	SE1->( dbSetOrder( 1 ) )
	SE1->( dbGoTop() )

	If Len( oGet1:aCols ) > 0
		For _k := 1 To Len( oGet1:aCols )
			If oGet1:aCols[_k, 1] ==  _cMarca .And. !(oGet1:aCols[_k, 17])
			
				Aadd( aDadosSE1,{	oGet1:aCols[_k,1],oGet1:aCols[_k,2],oGet1:aCols[_k,3],oGet1:aCols[_k,4],oGet1:aCols[_k,5],;
				oGet1:aCols[_k,6],oGet1:aCols[_k,7],oGet1:aCols[_k,8],oGet1:aCols[_k,9],oGet1:aCols[_k,10],;
				oGet1:aCols[_k,11],oGet1:aCols[_k,12],oGet1:aCols[_k,13],oGet1:aCols[_k,14],oGet1:aCols[_k,15],;
				oGet1:aCols[_k,16] })
			EndIf
		Next _k

		// Envio Remessa
		If nMV_PAR01 == N_REMESSA
			For _j := 1 To Len( aDadosSE1 )
				SE1->( dbGoTo( aDadosSE1[_j,16] ) )
				RecLock('SE1',.F.)
				SE1->E1_OK 			:= _cMarca
				SE1->E1_X_STATU 	:= 'R'					// titulo enviado para inclusao
				SE1->E1_OPER1		:= cGM_SERASA1
				cE1XMEMOBS			:= aDadosSE1[_j,15]
				cE1_HIST			:= SE1->E1_HIST
				SE1->E1_HIST		:= Substr("PEFIN-"+DTOC(Date())+"|"+cE1_HIST,1,Len(SE1->E1_HIST))
				SE1->E1_XMEMOBS		:= cE1XMEMOBS + _Enter + DTOC(Date()) + " " + Time() + " " + cUserName + " ->Gerado Arquivo INCLUS�O PEFIN" 
				MsUnLock()
			Next _j
			// Envio de Exclus�o
		ElseIf nMV_PAR01 == N_EXCLUSAO
			For _j := 1 To Len( aDadosSE1 )
				SE1->( dbGoTo( aDadosSE1[_j,16] ) )
				RecLock('SE1',.F.)
				SE1->E1_OK 			:= _cMarca
				SE1->E1_X_STATU 	:= 'E'                 // Titulo enviado para exclusao 
				SE1->E1_OPER1		:= cGM_SERASA7
				cE1XMEMOBS			:= aDadosSE1[_j,15]
				SE1->E1_XMEMOBS		:= cE1XMEMOBS + _Enter + DTOC(Date()) + " " + Time() + " " + cUserName + " ->Gerado Arquivo EXCLUS�O PEFIN" 
				MsUnLock()
			Next _j         
			// Marca��o de titulos para posterior envio
		ElseIf nMV_PAR01 == N_SELECIONAR
			For _j := 1 To Len( aDadosSE1 )
				SE1->( dbGoTo( aDadosSE1[_j,16] ) )
				RecLock('SE1',.F.)
				SE1->E1_OK 			:= _cMarca
				SE1->E1_X_STATU 	:= 'X'                 // Titulo marcado para posterior envio
				SE1->E1_OPER1		:= cGM_SERASA1
				cE1XMEMOBS			:= aDadosSE1[_j,15]
				SE1->E1_XMEMOBS		:= cE1XMEMOBS + _Enter + DTOC(Date()) + " " + Time() + " " + cUserName + " ->Selecionado para envio PEFIN" 
				MsUnLock()
			Next _j
			// Exclus�o dos titulos marcados para posterior envio ou baixa de titulos baixados diretamente pelo Site.
		ElseIf nMV_PAR01 == N_DESMARCAR
			For _j := 1 To Len( aDadosSE1 )
				SE1->( dbGoTo( aDadosSE1[_j,16] ) )
				RecLock('SE1',.F.)
				SE1->E1_OK 			:= ' '
				SE1->E1_X_STATU 	:= ' '                 // Titulo marcado para envio por�m desmarcado posteriormente
				SE1->E1_OPER1		:= ' '
				cE1XMEMOBS			:= aDadosSE1[_j,15]
				SE1->E1_XMEMOBS		:= cE1XMEMOBS + _Enter + DTOC(Date()) + " " + Time() + " " + cUserName + " ->Estorno de envio PEFIN" 
				MsUnLock()
			Next _j
		EndIf
		_oDlg:End()

		If nMV_PAR01 <= 2
			MsgRun("Gerando Arquivo de Remessa Serasa-Pefin ", "Selecionando registros...", {||ProcNorma(cNorma,cDest)} )
		Endif

		If nMv_Par01 == N_REMESSA
			cValSX6	:= Soma1(Alltrim(GetMv("GM_SERASA1")))
			PutMv("GM_SERASA1",cValSX6)

			nValSX6	:= GetMv("GM_SERASA2")+1
			PutMv("GM_SERASA2",nValSX6)

		ElseIf nMV_PAR01 == N_EXCLUSAO         

			// Atualizo tamb�m o parametro de sequencia de transmissao, pois o Serasa mantem um s� controle
			nValSX6	:= GetMv("GM_SERASA2")+1
			PutMv("GM_SERASA2",nValSX6)

			cValSX6	:= Soma1(Alltrim(GetMv("GM_SERASA7")))
			PutMv("GM_SERASA7",cValSX6)

			cValSX6	:= Soma1(Alltrim(GetMv("GM_SERASA3")))
			PutMv("GM_SERASA3",cValSX6)

		EndIf
		ApMsgStop("O Processo Foi Conclu�do Com Sucesso !","Aten��o")
	Else
		ApMsgStop('N�o Existe Nenhum T�tulo Selecionado !!!','Aten��o')
		Return .F.
	EndIf

Return lRet


/*������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������Ŀ��
���Programa   � DUPLOC1 � Autores � Eduardo Donato     � Data � Abr/2007 ���
����������������������������������������������������������������������������Ĵ��
���Descricao  � Funcao responsavel pelo funcionamento do Duplo Clique em uma ���
���           � linha no aCols                                               ���
�����������������������������������������������������������������������������ٱ�
��������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function DuploC1()
	Local nPosFLAG	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "E1_OK"})

	If oGet1:aCols[oGet1:nAt][nPosFLAG]	== Space(2) 	// DESMARCADO
		oGet1:aCols[oGet1:nAt][nPosFLAG]	:= _cMarca 		// MARCADO
		oGet1:oBrowse:Refresh()
	Else
		oGet1:aCols[oGet1:nAt][nPosFLAG]:= Space(2) // DESMARCADO
		oGet1:oBrowse:Refresh()
	EndIf

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MarkAll   �Autor  �Eduardo Donato     � Data �  Abr/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     �Rotina Utilizada para Marcar e Desmarcar todos os Tiutlos   ���
���          �Existentes na GetDados.                                     ���
���          �_nParam == 1 -> Marca Todos                                 ���
���          �_nParam == 2 -> Desmarca Todos                              ���
�������������������������������������������������������������������������͹��
���Uso       � Versao8.11 - Parmalat                                      ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MarkAll( _nParam )
	Local _i 				:= 0
	Local lRet 			:= .T.
	Local nPosFLAG	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "E1_OK"})

	If Len( oGet1:aCols ) > 0
		If _nParam == 1
			For _i := 1 To Len(oGet1:aCols)
				oGet1:aCols[_i][nPosFLAG]	:= _cMarca
			Next _i
		Else
			For _i := 1 To Len(oGet1:aCols)
				oGet1:aCols[_i][nPosFLAG]	:= Space(2)
			Next _i
		EndIf
	Else
		ApMsgStop('N�o Existem T�tulos para Serem Selecionados !!!','Aten��o')
		lRet := .F.
	EndIf
	oGet1:oBrowse:Refresh()

Return lRet

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �GeraRlt2  �Autor  � Eduardo Donato     � Data �  Mai/2007   ���
�������������������������������������������������������������������������͹��
���Desc.     �Gera o Relatorio com os titulos que foram selecionados para ���
���          �Envio de Remessa / Correcao.                                ���
�������������������������������������������������������������������������͹��
���Uso       �Versao8.11 - Parmalat                                       ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

Static Function GeraRlt2()

	Local _nX := 0
	Local aDadosIMP	:= {}

	If Len( oGet1:aCols ) > 0
		For _nX := 1 To Len( oGet1:aCols )
			If oGet1:aCols[_nX, 1] ==  _cMarca .And. !(oGet1:aCols[_nX, 17])
				Aadd( aDadosIMP,{	oGet1:aCols[_nX,1],oGet1:aCols[_nX,2],oGet1:aCols[_nX,3],oGet1:aCols[_nX,4],oGet1:aCols[_nX,5],;
				oGet1:aCols[_nX,6],oGet1:aCols[_nX,7],oGet1:aCols[_nX,8],oGet1:aCols[_nX,9],oGet1:aCols[_nX,10],;
				oGet1:aCols[_nX,11],oGet1:aCols[_nX,12],oGet1:aCols[_nX,13],oGet1:aCols[_nX,14],;
				Iif(nMV_PAR01 == N_REMESSA ,"Inclus�o Pefin","Exclus�o Pefin"),;
				oGet1:aCols[_nX,16] })
			EndIf
		Next _nX
	Else
		ApMsgStop('Selecione os T�tulos para Envio Antes de Solicitar a Impress�o do Relat�rio !','Aten��o')
	EndIf

	U_Imprime2( Mv_Par01, aDadosIMP )

Return 


/*������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������Ŀ��
���Programa   �   C()      � Autor � Eduardo Donato     � Data � Abr/2007 ���
����������������������������������������������������������������������������Ĵ��
���Descricao  � Funcao responsavel por manter o Layout independente da       ���
���           � resolu��o horizontal do Monitor do Usuario.                  ���
�����������������������������������������������������������������������������ٱ�
��������������������������������������������������������������������������������
������������������������������������������������������������������������������*/
Static Function C(nTam)
	Local nHRes	:=	oMainWnd:nClientWidth	//Resolucao horizontal do monitor
	Do Case
		Case nHRes == 640	//Resolucao 640x480
		nTam *= 0.8
		Case nHRes == 800	//Resolucao 800x600
		nTam *= 1
		OtherWise			//Resolucao 1024x768 e acima
		nTam *= 1.28
	EndCase
	If "MP8" $ oApp:cVersion
		//���������������������������Ŀ
		//�Tratamento para tema "Flat"�
		//�����������������������������
		If (Alltrim(GetTheme()) == "FLAT").Or. SetMdiChild()
			nTam *= 0.90
		EndIf
	EndIf
Return Int(nTam)
