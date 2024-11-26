//#Include 'Serasa.ch'
#Include 'Protheus.ch'
#Include 'TbiConn.ch'

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  �SERASA    � Autor �Eduardo Donato     � Data � Mar/2007 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o �Integracao com Sofware SERASA PEFIN e IP123                 ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �Nenhum                                                      ���
�������������������������������������������������������������������������Ĵ��
���Parametros�Nenhum                                                      ���
���          �                                                            ���
�������������������������������������������������������������������������Ĵ��
���   DATA   � Programador   �Manutencao Efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function GRPEFIN1()

Local aArea			:=  GetArea()
Local cTitulo			:=	"SERASA - RELATO" //"SERASA - RELATO"
Local cMsg1			:=	"   Esta rotina tem como objetivo gerar o arquivo pre-formatado para o sistema" //"   Esta rotina tem como objetivo gerar o arquivo pre-formatado para o sistema"
Local cMsg2			:=	"SERASA/RELATO ( Relatorio de comportamento em Negocios ), conforme os parametos" //"SERASA/RELATO ( Relatorio de comportamento em Negocios ), conforme os parametos"
Local cMsg3			:=	"da rotina e o manual de homologacao da SERASA." //"da rotina e o manual de homologacao da SERASA."
Local cNorma    		:= ""
Local cDest    		:= ""
Local cPerg			:= "SERASA"
Local nOpcA			:= 0
Local dDataIni  := dDataBase
Local dDataFim  := dDataBase
Local oDlg
Private SERASA_PERIODO := ""


// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

//��������������������������������������������������������������Ŀ
//� Monta Tabela de Codigos de Unid. de Medida                   �
//����������������������������������������������������������������
AjustaSX1()
Pergunte(cPerg,.F.)

FormBatch( cTitulo, { OemToAnsi( cMsg1 ), OemToAnsi( cMsg2 ), OemToAnsi( cMsg3 ) },;
	{ { 5,.T.,{|o| Pergunte(cPerg,.T.) } },;
	{ 1,.T.,{|o| nOpcA := 1,o:oWnd:End()}},;
	{ 2,.T.,{|o| nOpca := 2,o:oWnd:End()}}})
	If ( nOpcA == 1 )
		//������������������������������������������������������������������������Ŀ
		//�Preparacao do inicio de processamento do arquivo pre-formatado          �
		//��������������������������������������������������������������������������
		cNorma 		:= AllTrim(Lower(MV_PAR03))+".ini"
		cDest  		:= AllTrim(Lower(MV_PAR04))
		dDataIni	:= MV_PAR01
		dDataFim	:= MV_PAR02
		//������������������������������������������������������������������������Ŀ
		//�Ajusta a data inicial e final conforme o periodo identificado           �
		//��������������������������������������������������������������������������
		Do Case
			Case dDataFim - dDataIni >= 16 //Periodicidade Mensal
				SERASA_PERIODO := "Mensal" //"Mensal"
				dDataIni := FirstDay( dDataIni )
				dDataFim := LastDay( dDataIni )
			Case dDataFim - dDataIni >= 8 //Periodicidade Quinzenal
				SERASA_PERIODO := "Quinzenal" //"Quinzenal"
				If Day( dDataIni ) >= 16
					dDataIni := Stod( SubStr( Dtos( dDataIni ), 1, 6) + "16" )
					dDataFim := LastDay( dDataIni )
				Else
					dDataIni := FirstDay( dDataIni )
					dDataFim := Stod( SubStr( Dtos( dDataIni ), 1, 6) + "15")
				EndIf
			Case dDataFim - dDataIni >= 5 //Periodicidade Semanal
				SERASA_PERIODO := "Semanal" //"Semanal"
				While Dow( dDataIni )== 2
					dDataIni--
				EndDo
				dDataFim := dDataIni + 6
			OtherWise //Periodicidade Diaria
				SERASA_PERIODO := "Diaria" //"Diaria"
				dDataFim := dDataIni
		EndCase
		If MV_PAR01 <> dDataIni .Or. MV_PAR02 <> dDataFim
			MsgInfo( "Periodicidade ajustada para: " + SERASA_PERIODO ) //"Periodicidade ajustada para: "
		EndIf
		MV_PAR01 := dDataIni
		MV_PAR02 := dDataFim
		
		Processa( { ||ProcNorma1( cNorma, cDest ) } )
		
		//������������������������������������������������������������������������Ŀ
		//�Reabre os Arquivos do Modulo desprezando os abertos pela Normativa      �
		//��������������������������������������������������������������������������
		dbCloseAll()
		OpenFile( SubStr( cNumEmp, 1, 2 ) )
	EndIf
	
	//��������������������������������������������������������������Ŀ
	//� Restaura area                                                �
	//����������������������������������������������������������������
	RestArea( aArea )
	AtuParam()
	Return(.T.)
	
	/*
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������ͻ��
	���Programa  �AtuParam  �Autor  �Eduardo Donato     � Data �  Mar/2007   ���
	�������������������������������������������������������������������������͹��
	���Desc.     �Rotina para a Atualizacao do Parametro MV_SERASA8, que      ���
	���          �determina o Numero da Remessa do PEFIN.											���
	�������������������������������������������������������������������������͹��
	���Uso       � Versao 8.11 - Parmalat                                     ���
	�������������������������������������������������������������������������ͼ��
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	*/
	Static Function AtuParam()
		Local aAreaSX6 := SX6->( GetArea() )
		Local _nNumRem := StrZero( GetMv( "MV_SERASA8" ), 6 )
		
		// GetMv( "MV_SERASA8" )
		// RecLock( "SX6",.F. )
		// SX6->X6_CONTEUD := Soma1( _nNumRem )
		// MsUnlock()

		PutMv("MV_SERASA8", Soma1(_nNumRem))

		RestArea( aAreaSX6 )

	Return Nil
	
	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	���Funcao    �AjustaSX1 � Autor �Eduardo Donato     � Data � Mar/2007 ���
	�������������������������������������������������������������������������Ĵ��
	���Descri��o �Cria as perguntas necesarias para o programa                ���
	�������������������������������������������������������������������������Ĵ��
	���Retorno   �Nenhum                                                      ���
	�������������������������������������������������������������������������Ĵ��
	���Parametros�Nenhum                                                      ���
	���          �                                                            ���
	�������������������������������������������������������������������������Ĵ��
	���   DATA   � Programador   �Manutencao Efetuada                         ���
	�������������������������������������������������������������������������Ĵ��
	���          �               �                                            ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	Static Function AjustaSX1()
	Local aHelpPor	:= {}
	Local aHelpEng	:= {}
	Local aHelpSpa	:= {}
	
	PutSx1( "SERASA",;
	"01",;
	"Data Inicial",; //"Data Inicial"
	"Data Inicial",; //"Data Inicial"
	"Data Inicial",; //"Data Inicial"
	"mv_ch1",;
	"D",;
	8,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par01",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	PutSx1( "SERASA",;
	"02",;
	"Data Final",; //"Data Final"
	"Data Final",; //"Data Final"
	"Data Final",; //"Data Final"
	"mv_ch2",;
	"D",;
	8,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par02",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	PutSx1( "SERASA",;
	"03",;
	"Lay-Out",;
	"Lay-Out",;
	"Lay-Out",;
	"mv_ch3",;
	"C",;
	20,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par03",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	PutSx1( "SERASA",;
	"04",;
	"Destino",;
	"Destino",;
	"Destino",;
	"mv_ch4",;
	"C",;
	40,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par04",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	PutSx1( "SERASA",;
	"05",;
	"Tipo de Remessa",;
	"Tipo de Remessa",;
	"Tipo de Remessa",;
	"mv_ch5",;
	"N",;
	1,;
	0,;
	0,;
	"C",;
	"",;
	"",;
	"",;
	"",;
	"mv_par05",;
	"Remessa",;
	"Remessa",;
	"Remessa",;
	"",;
	"Correcao",;
	"Correcao",;
	"Correcao",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	PutSx1( "SERASA",;
	"06",;
	"Segmento",;
	"Segmento",;
	"Segmento",;
	"mv_ch6",;
	"C",;
	3,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par06",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	
	Aadd( aHelpPor, "Informe o tipo do t�tulo inicial do " )
	Aadd( aHelpPor, "intervalo de t�tulos para envio ao " )
	Aadd( aHelpPor, "Serasa." )
	
	Aadd( aHelpEng, "Inform the model of initial interval " )
	Aadd( aHelpEng, "lable for sending to Serasa." )
	
	Aadd( aHelpSpa, "Informe el modelo del t�tulo inicial " )
	Aadd( aHelpSpa, "del intervalo de los t�tulos para env�o " )
	Aadd( aHelpSpa, "al Serasa." )
	
	PutSx1( "SERASA",;
	"07",;
	"Tipo Titulo Inicial",;
	"Initial Bill Type",;
	"Tipo T�tulo Inicial",;
	"mv_ch7",;
	"C",;
	3,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par07",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	
	PutSX1Help("P.SERASA07.",aHelpPor,aHelpEng,aHelpSpa)
	
	aHelpPor	:= {}
	aHelpEng	:= {}
	aHelpSpa	:= {}
	
	Aadd( aHelpPor, "Informe o tipo do t�tulo final do " )
	Aadd( aHelpPor, "intervalo de t�tulos para envio ao " )
	Aadd( aHelpPor, "Serasa." )
	
	Aadd( aHelpEng, "Inform the model of final interval " )
	Aadd( aHelpEng, "lable for sending to Serasa." )
	
	Aadd( aHelpSpa, "Informe el modelo del t�tulo final " )
	Aadd( aHelpSpa, "del intervalo de los t�tulos para " )
	Aadd( aHelpSpa, "env�o al Serasa." )
	
	PutSx1( "SERASA",;
	"08",;
	"Tipo Titulo Final",;
	"Final Bill Type",;
	"Tipo T�tulo Final",;
	"mv_ch8",;
	"C",;
	3,;
	0,;
	0,;
	"G",;
	"",;
	"",;
	"",;
	"",;
	"mv_par08",;
	"",;
	"",;
	"",;
	"ZZZ",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	
	PutSX1Help("P.SERASA08.",aHelpPor,aHelpEng,aHelpSpa)
	
	Aadd( aHelpPor, "Informe se considera os titulos de " )
	Aadd( aHelpPor, "abatimento." )
	
	Aadd( aHelpEng, "Inform whether considers allowance " )
	Aadd( aHelpEng, "lables." )
	
	Aadd( aHelpSpa, "Considera rebajas. " )
	
	PutSx1( "SERASA",;
	"09",;
	"Consid. Abatimentos",;
	"Allowance",;
	"Rebaja",;
	"mv_ch9",;
	"N",;
	1,;
	0,;
	1,;
	"C",;
	"",;
	"",;
	"",;
	"",;
	"mv_par09",;
	"Sim",;
	"Si",;
	"Yes",;
	"",;
	"Nao",;
	"No",;
	"No",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"",;
	"")
	
	PutSX1Help("P.SERASA09.",aHelpPor,aHelpEng,aHelpSpa)
	Return
	
	/*/
	�������������������������������������������������������������������������������
	�������������������������������������������������������������������������������
	���������������������������������������������������������������������������Ŀ��
	���Fun��o    �FsQuery   � Autor � Eduardo Riera         � Data �16/01/2003  ���
	���������������������������������������������������������������������������Ĵ��
	���Descri��o � Rotina de selecao de registros atraves de comandos SQL      	���
	���������������������������������������������������������������������������Ĵ��
	���Parametro �ExpA1: Array de controle                                    	���
	���          �       [1] Alias da tabela principal                          ���
	���          �       [2] Controle Interno ( ExpC )                          ���
	���          �ExpN2: [1] Inicializacao                                    	���
	���          �       [2] Finalizacao                                        ���
	���          �ExpC3: Expressao SQL ( WHERE )                           (OPC)���
	���          �ExpC4: Expressao ADVPL ( Filter )                        (OPC)���
	���          �ExpC5: Expressao ADVPL ( Index  )                        (OPC)���
	���������������������������������������������������������������������������Ĵ��
	���Retorno   �ExpA [1] Quantidade do Produto                              	���
	���          �     [2] Valor do Produto                                   	���
	���������������������������������������������������������������������������Ĵ��
	��� Uso      � Generico                                                   	���
	���������������������������������������������������������������������������Ĵ��
	��� ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL.                     	���
	���������������������������������������������������������������������������Ĵ��
	��� PROGRAMADOR  � DATA   � BOPS �  MOTIVO DA ALTERACAO                   	���
	���������������������������������������������������������������������������Ĵ��
	����������������������������������������������������������������������������ٱ�
	�������������������������������������������������������������������������������
	��������������������������������������������������������������������������������
	*/
	Static Function FpQuery(aControle,nTipo,cWhere,cFilter,cKey, aIN)
	
	#IFDEF TOP
		Local aStru     := {}
		Local nX      := 0
	#ENDIF
	
	//������������������������������������������������������������������������Ŀ
	//�Selecao dos dados a serem filtrados                                     �
	//��������������������������������������������������������������������������
	#IFDEF TOP
		Local cQuery := ""
		DEFAULT aIn := {}
		
		If nTipo == 1
			//aStru := (aControle[1])->(dbStruct())
			cQuery := "SELECT REPLACE(ROUND(E1_VALOR,2),',','') E1_VALDUPL,SE1.* "
			cQuery += "FROM "+RetSqlName(aControle[1])+"  SE1 "
			cQuery += "WHERE "
			If !Empty(cWhere)
				cQuery += cWhere+" AND "
			EndIf			
			If !empty( aIN )
				cQuery += " "+aIn[1]+" IN " +aIn[2] + " AND "
			EndIf			
			cQuery += "D_E_L_E_T_=' ' "
			If !Empty(cKey)
				cQuery += "ORDER BY "+SqlOrder(cKey)
			EndIf			
			cQuery := ChangeQuery(cQuery)
			
			If Select( aControle[2] ) > 0
				(aControle[1])->( dbCloseArea() )
			EndIf
			
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),aControle[2])
			aStru := (aControle[2])->(dbStruct())
			For nX := 1 To Len( aStru )
			 //	If aStru[nX][2] <> "C"
				TcSetField(aControle[2],aStru[nX][1],aStru[nX][2],aStru[nX][3],aStru[nX][4])
			//	EndIf
			Next nX
		Else
			dbSelectArea(aControle[1])
			dbCloseArea()
			dbSelectArea(aControle[1])
		EndIf
	#ELSE
		If nTipo == 1
			dbSelectArea(aControle[1])
			aControle[2] := CriaTrab(,.F.)
			Do Case
				Case !Empty(cKey) .And. !Empty(cFilter)
					IndRegua(aControle[1],aControle[2],cKey,,cFilter,Nil,.F.)
				Case !Empty(cKey)
					IndRegua(aControle[1],aControle[2],cKey,,,Nil,.F.)
			EndCase
		Else
			RetIndex(aControle[1])
			FErase(aControle[2]+OrdBagExt())
		EndIf
	#ENDIF
	Return(.T.)
	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	���Funcao    �ReadNorma � Autor �Eduardo Riera          � Data �17.07.1999���
	�������������������������������������������������������������������������Ĵ��
	���Descri��o �Funcao de Leitura dos arquivos de Instrucao Normativa       ���
	�������������������������������������������������������������������������Ĵ��
	���Retorno   �Array com o Lay-Out da Instr.Normativa                      ���
	�������������������������������������������������������������������������Ĵ��
	���Parametros�ExpC1: Arquivo                                              ���
	���          �                                                            ���
	�������������������������������������������������������������������������Ĵ��
	���   DATA   � Programador   �Manutencao Efetuada                         ���
	�������������������������������������������������������������������������Ĵ��
	���          �               �                                            ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	Static Function ReadNorma1(cNorma, lImprime, cMdb, cMaskVlr)
	
	Local aNorma 	:= {}
	Local cLinha 	:= ""
	Local aArq      := {{}}
	Local aAlias 	:= {{}}//{NIL,NIL,NIL}
	Local aPre	 	:= {{}}
	Local aPos	 	:= {{}}
	Local aPreReg	:= {{}}
	Local aPosReg	:= {{}}
	Local aStru  	:= {{}}
	Local aConteudo	:= {{}}
	Local aContReg	:= {{}}
	Local aIni      := {{}}
	Local cAux		:= ""
	Local aArea		:= GetArea()
	Local nNivel   	:= 1
	Local aImprime 	:= {.F.,,,,.F.}
	Local aDelimit  := {{}}
	Local aConsolidado	:=	{{"cFilAnt", "cFilAnt", "", ""}}
	Local aChv		:=	{}
	Local aOrd		:=	{""}
	
	Default cMaskVlr	:=	""
	Default cMdb 		:= 	{}
	Default lImprime	:=	.F.
	
	//������������������������������������������������������������������������Ŀ
	//�Estrutura do Arquivo a Ser Lido                                         �
	//�                                                                        �
	//�[XXX] Onde XXX eh o Alias Principal - Identifica um Registro de Arquivo�
	//�(ARQ) Definicao do Nome do Arquivo TXT referente ao Bloco []            �
	//�(PRE) Pre-Processamento do Registro de Arquivo                          �
	//�(PREREG) Pre-Processamento para cada registro do Alias Principal        �
	//�WWWWWWWWWW X YYY Z CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC �
	//�|          | |   | |                                                    �
	//�|          | |   | -> Conteudo                                          �
	//�|          | |   | -> Numero de Decimais                                �
	//�|          | | -----> Tamanho da Coluna                                 �
	//�|          | -------> Formato de Gravacao ( Numerico Caracter Data      �
	//�| ------------------> Nome da Coluna                                    �
	//�(POSREG) Pos-Processamento para cada registro do Alias Principal        �
	//�(POS) Pos-Processamento do Registro de Arquivo                          �
	//�(INI:<Nome>) Normativa a ser processada apos este registro.             �
	//��������������������������������������������������������������������������
	
	//������������������������������������������������������������������������Ŀ
	//�Efetua a Abertura do Arquivo NormaXXX.Ini                               �
	//��������������������������������������������������������������������������
	If (File(cNorma))
		FT_FUse(cNorma)
		FT_FGotop()
		
		While ( !FT_FEof() )
			cLinha := FT_FREADLN()
			
			Do Case
				Case "["==SubStr(cLinha,1,1)
					If ( !Empty(aAlias[nNivel]) )
						aadd(aNorma,{ aAlias,aPre,aPreReg,aPos,aPosReg,aStru,aConteudo,aArq,aContReg,aINI, aImprime, aDelimit, aConsolidado, aChv, aOrd})
						aPre 		:= {{}}
						aPreReg 	:= {{}}
						aPos		:= {{}}
						aPosReg		:= {{}}
						aStru		:= {{}}
						aConteudo	:= {{}}
						aContReg	:= {{}}
						aINI    	:= {{}}
						aAlias		:= {{}} //{NIL,NIL,NIL}
						nNivel   	:= 1
						aArq        := {{}}
						aDelimit 	:= {{}}
						aConsolidado:=	{{"cFilAnt", "cFilAnt", "", ""}}
						aChv		:=	{{}}
					EndIf
					aAlias[nNivel] := SubStr(cLinha,2,3)
					
					aImprime 	:= {.F.,,,,.F.}
					aOrd		:=	{""}
					
				Case "{"==SubStr(cLinha,1,1)
					nNivel++
					aadd(aAlias,SubStr(cLinha,2,3))
					aadd(aPre,{})
					aadd(aPreReg,{})
					aadd(aPos,{})
					aadd(aPosReg,{})
					aadd(aStru,{})
					aadd(aConteudo,{})
					aadd(aContReg,{})
					aadd(aINI,{})
					aadd(aArq,{})
					aadd(aDelimit,{})
					aAdd(aConsolidado, {"cFilAnt", "cFilAnt", "", ""})
					aadd(aChv,{})
					aadd(aOrd,"")
					
					//Identifica em que ordem deve ser impresso um determinado registro no INI. Esta clausula deve ser utilizada para os blocos
					//	que nao possuem Alias, ou seja, deve ser XXX e que o bloco esteja no INI principal (nao podendo estar dentro de um outro
					//	INI chamado pelo principal. Ex: SISIF). Um exemplo de utilizacao eh para totalizador, onde os valores calculados durante o
					//	o processamento do INI deverao compor o registro HEADER, na primeira linha do meio-magnetico.
					//	- Sua clausula pode indicar TOP para o primeiro registro do meio-magnetico ou BOT (Bottom) para o ultimo registro do meio-magnetico.
					//	- Se nao for informado, sera considerado na posicao em que aparecer no INI.
					//
					//INI Utilizado: GIARS.INI
				Case "(ORD"==SubStr (cLinha,1,4)
					aOrd[nNivel]	:=	AllTrim (SubStr (cLinha, 6))
					
					//Esta chave eh utilizada para otimizar o while quando nao for possivel implementar um FSQUERY por exemplo, esta chave faz
					//	parte do while para a tabela passada como Alias no bloco do registro.
				Case "(CHV"==SubStr (cLinha,1,4)
					aChv[nNivel]	:=	AllTrim (SubStr (cLinha, 6))
					
				Case "//"==SubStr (cLinha,1,2)
					//Nao faz nada, pois eh comentario.
					
					//Esta clausula define uma mascara padrao para todos os campos valores gerados pela IN no meio-magnetico.
					//	Ex. MANAD.INI: @MASKVLR="@E 9999999.99"
				Case "@MASKVLR="==SubStr (cLinha,1,9)
					cMaskVlr	:=	&(AllTrim (SubStr (cLinha, 10)))
					
				Case "(CONSOLIDADO)"==SubStr (cLinha,1,13)
					aConsolidado[nNivel]	:=	&(AllTrim (SubStr (cLinha, 14)))
					
				Case "(ARQ"==SubStr(cLinha,1,4) .And.(")"==SubStr(cLinha,5,1).or.")"==SubStr(cLinha,6,1)).And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,7))
					If ("&"$cAux)
						cAux	:=	&(AllTrim(SubStr (cAux, At ("&", cAux)+1)))
					EndIf
					//
					If ( !Empty(cAux) )
						aadd(aArq[nNivel],cAux)
					EndIf
					
				Case "(PRE"==SubStr(cLinha,1,4) .And.(")"==SubStr(cLinha,5,1).or.")"==SubStr(cLinha,6,1)).And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,7))
					If ( !Empty(cAux) )
						aadd(aPre[nNivel],cAux)
					EndIf
				Case "(IMP"==SubStr(cLinha,1,4)
					aImprime	:=	&(AllTrim (AllTrim (SubStr (cLinha, 6))))
					
				Case "(LEG"==SubStr(cLinha,1,4)
					
				Case "(CMP"==SubStr(cLinha,1,4)
					
				Case "(DEL"==SubStr(cLinha,1,4)
					If ("&"$AllTrim (AllTrim (SubStr (cLinha, 6))))
						aDelimit[nNivel]	:=	&(SubStr (AllTrim (SubStr (cLinha, 6)),2))
					Else
						aDelimit[nNivel]	:=	AllTrim (AllTrim (SubStr (cLinha, 6)))
					EndIf
					
				Case "(PREREG"==SubStr(cLinha,1,7) .And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,10))
					If ( !Empty(cAux) )
						aadd(aPreReg[nNivel],cAux)
					EndIf
					
				Case "(POS"==SubStr(cLinha,1,4) .And.(")"==SubStr(cLinha,5,1).or.")"==SubStr(cLinha,6,1)) .And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,7))
					If ( !Empty(cAux) )
						aadd(aPos[nNivel],cAux)
					EndIf
					
				Case "(POSREG"==SubStr(cLinha,1,7) .And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,10))
					If ( !Empty(cAux) )
						aadd(aPosReg[nNivel],cAux)
					EndIf
					
				Case "(CONT"==SubStr(cLinha,1,5) .And. !Empty(aAlias[nNivel])
					cAux := AllTrim(SubStr(cLinha,7))
					If ( !Empty(cAux) )
						aadd(aContReg[nNivel],cAux)
					EndIf
					
				Case "(INI:"==SubStr(cLinha,1,5)
					cAux := AllTrim(SubStr(cLinha,6))
					If ( !Empty(cAux) )
						aadd(aIni[nNivel],Left(cAux,Len(cAux)-1))
					EndIf
				Case "@MDB="==SubStr(cLinha,1,5)
					cMdb	:=	AllTrim (SubStr (cLinha,6))
					
				OtherWise
					If !lImprime .And. aImprime[1]
						lImprime	:=	.T.
					EndIf
					If ( !Empty(aAlias[nNivel]) ) .And. !Empty(SubStr(cLinha,01,10))
						aadd(aStru[nNivel], {	SubStr(cLinha,01,10) ,; 		//Campo
						SubStr(cLinha,12,01) ,; 		//Tipo
						Val(SubStr(cLinha,14,03)) ,; 	//Tamanho
						Val(SubStr(cLinha,18,01)) })	//Decimal
						
						aadd(aConteudo[nNivel], SubStr(cLinha,20) )
						
					EndIf
					
			EndCase
			
			FT_FSkip()
		EndDo
		
		//������������������������������������������������������������������������Ŀ
		//�Adiciona o ultimo registro                                              �
		//��������������������������������������������������������������������������
		If ( !Empty(aAlias[nNivel]) )
			aadd(aNorma,{ aAlias,aPre,aPreReg,aPos,aPosReg,aStru,aConteudo,aArq,aContReg,aINI, aImprime, aDelimit, aConsolidado, aChv, aOrd})
		EndIf
		
		//������������������������������������������������������������������������Ŀ
		//�Fecha o Arquivo NormaXXX.INI                                            �
		//��������������������������������������������������������������������������
		FT_FUse()
	Else
		Help(" ",1,"NORMAERRO1")
	EndIf
	
	RestArea(aArea)
	
	Return(aNorma)
	
	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	���Funcao    �ProcNorma � Autor �Eduardo Riera          � Data �17.07.1999���
	�������������������������������������������������������������������������Ĵ��
	���Descri��o �Rotina de Processamento de Instr.Normativa                  ���
	�������������������������������������������������������������������������Ĵ��
	���Retorno   �Nenhum                                                      ���
	�������������������������������������������������������������������������Ĵ��
	���Parametros�ExpC1: Arquivo da Normativa                                 ���
	���          �ExpC2: Arquivo de Destino                                   ���
	�������������������������������������������������������������������������Ĵ��
	���   DATA   � Programador   �Manutencao Efetuada                         ���
	�������������������������������������������������������������������������Ĵ��
	���          �               �                                            ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	Static Function ProcNorma1(cNorma,cDest,cDir)
	
	Local aArea 	 := GetArea()
	Local lImprime	 :=	.F.
	Local cMdb		 :=	""
	Local cMaskVlr   :=	""
	Local aNorma     :=	ReadNorma1(cNorma, @lImprime, @cMdb, @cMaskVlr)
	Local cTrab	     := CriaTrab(,.F.)+".txt"
	Local nHandle    := 0
	Local nX     	 := 0
	Local lApaga   	 := .T.
	Local aArqSpool  := {}
	Local cBufferFim := ""
	Local cBuffer    := ""
	
	DEFAULT cDir := ""
	nHandle 	:= FCreate(cTrab,0)
	
	If ( FError() == 0 )
		//������������������������������������������������������������������������Ŀ
		//�Declara Variaveis que podem ser utilizadas nas Normativas.              �
		//��������������������������������������������������������������������������
		Private _aTotal[100]
		Private lAbtMT950	:=	.F.
		
		//������������������������������������������������������������������������Ŀ
		//�Calcula o Numero de Registros da Normativa a Processar                  �
		//��������������������������������������������������������������������������
		ProcRegua(Len(aNorma),24)
		
		//������������������������������������������������������������������������Ŀ
		//�Processa a Normativa                                                    �
		//��������������������������������������������������������������������������
		aEval(aNorma,{|x| cBufferFim += RegNorma1(x,@nHandle,@cTrab,cDir, cMaskVlr),IncProc(24) })
		
		//������������������������������������������������������������������������Ŀ
		//�Encerra o arquivo binario                                               �
		//��������������������������������������������������������������������������
		FClose(nHandle)
		//������������������������������������������������������������������������Ŀ
		//�Efetua a gravacao no Cliente                                            �
		//��������������������������������������������������������������������������
		For nX := 1 to len(aNorma)
			If len(aNorma[nX][8][1]) > 0
				If !Empty(aNorma[nX][8][1][1])
					If (aNorma[nX][11][1])	//Se for para gerar registro no spool
						aAdd (aArqSpool, aNorma[nX][8][1][1])
					EndIf
					lApaga := .F.
				EndIf
			EndIf
		Next nX
		
		//
		If !Empty (cBufferFim)
			FErase (cDir+cDest)
			nHdle := FCreate (cDir+cDest, 0)
			If ("T"$SubStr (cBufferFim, 1, 1))
				FWrite(nHdle, SubStr (cBufferFim, 2)+Chr(13)+Chr(10))
			EndIf
			
			FT_FUse (cTrab)
			FT_FGoTop ()
			
			Do While !FT_FEoF ()
				cBuffer := FT_FReadLn ()
				FWrite(nHdle, cBuffer+Chr(13)+Chr(10))
				//
				FT_FSkip ()
			EndDo
			
			If ("B"$SubStr (cBufferFim, 1, 1))
				FWrite(nHdle, SubStr (cBufferFim, 2)+Chr(13)+Chr(10))
			EndIf
			
			FT_FUse ()
			FClose (nHdle)
		Else
			If lApaga
				Ferase(cDir+cDest)
				__CopyFIle(cTrab,cDir+cDest)
				Ferase(cTrab)
			Else
				If cPaisLoc <> "MEX"
					Aviso("Instrucoes Normativas",; //"Instrucoes Normativas"
					"Esta instrucao normativa possui arquivos de destino especificos e portanto o parametro de destino nao foi respeitado!",; //"Esta instrucao normativa possui arquivos de destino especificos e portanto o parametro de destino nao foi respeitado!"
					{"OK"})
				Endif
			EndIf
		EndIf
		Ferase(cTrab)
	Else
		Help(" ",1,"NORMAERRO2")
	EndIf
	
	If (lImprime) .And. !(lAbtMt950)
		ImpSpool (cNorma, cDest, cDir, aArqSpool)
	EndIf
	//
	If !Empty (cMdb)
		If (File (cDir+cMdb))
			FErase (cDir+cMdb)
		EndIf
		WaitRun ("TxtToMdb "+cDir+cDest+" "+cDir+cMdb+" -ver=4", SW_HIDE)
	EndIf
	//
	Return(.T.)
	
	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	���Funcao    �RegNorma  � Autor �Eduardo Riera          � Data �17.07.1999���
	�������������������������������������������������������������������������Ĵ��
	���Descri��o �Processa um registro de Instrucao Normativa                 ���
	�������������������������������������������������������������������������Ĵ��
	���Retorno   �Nenhum                                                      ���
	�������������������������������������������������������������������������Ĵ��
	���Parametros�ExpA1: Registro da Norma                                    ���
	���          �ExpN1: Handle do Arquivo a Ser Gravado                      ���
	�������������������������������������������������������������������������Ĵ��
	���   DATA   � Programador   �Manutencao Efetuada                         ���
	�������������������������������������������������������������������������Ĵ��
	���          �               �                                            ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	
	Static Function RegNorma1(aReg,nHandle,cTrab,cDir, cMaskVlr)
	
	Local aArea		:= GetArea()
	Local aArea1	:= {}
	Local aArea2	:= {}
	Local aArea3	:= {}
	Local aAlias	:= aReg[1]
	Local aPre	 	:= aReg[2]
	Local aPreReg	:= aReg[3]
	Local aPos		:= aReg[4]
	Local aPosReg   := aReg[5]
	Local aStru		:= aReg[6]
	Local aConteudo := aReg[7]
	Local aArq		:= aReg[8]
	Local aContReg	:= aReg[9]
	Local aINI      := aReg[10]
	Local aDelimit	:= aReg[12]
	Local aConsolidado := aReg[13]
	Local aChv		:= aReg[14]
	Local aOrd		:= aReg[15]
	Local cFilDe		:=	""
	Local cFilAte		:=	""
	Local cChaveCons	:=	""
	Local cCmpGrvCon	:=	""
	Local aArqNew		:=	{}
	Local uConteudo
	Local cBuffer	:= ""
	Local nCntFor	:= 0
	Local bError
	Local lContinua := Len(aStru) > 0
	Local nNivel    := 0
	Local cDelimit  := ""
	Local aAreaSm0	 :=	SM0->(GetArea ())
	Local cBufferFim := ""
	Local aChvNivel	:= {.F., .F., .F.}
	Local aSkipChv	:=	{.F., .F., .F.}
	//
	//lAbtMt950 - Aborta a rotina
	If (lAbtMT950)
		RestArea(aAreaSm0)
		Return (cBufferFim)
	EndIf
	
	If aAlias[1] <> "XXX"
		dbSelectArea(aAlias[1])
	EndIf
	
	aArea1 := GetArea()
	
	cFilDe		:=	&(aConsolidado[1][1])	//Filial de passado pelo INI
	cFilAte		:=	&(aConsolidado[1][2])	//Filial ate passado pelo INI
	cChaveCons	:=	aConsolidado[1][3]
	cCmpGrvCon	:=	aConsolidado[1][4]
	If Empty (cFilDe) .And. Empty (cFilAte)
		cFilDe		:=	cFilAnt
		cFilAte		:=	cFilAnt
	EndIf
	If (cFilDe#cFilAte)
		TrbConso (1, 1, aStru, cChaveCons, @aArqNew)
	EndIf
	
	DbSelectArea("SM0")
	SM0->(DbSeek (cEmpAnt+cFilDe, .T.))
	
	Do While !SM0->(Eof ()) .And. SM0->M0_CODIGO+SM0->M0_CODFIL<=cEmpAnt+cFilAte
		cFilAnt	:=	SM0->M0_CODFIL
		
		If aAlias[1] <> "XXX"
			dbSelectArea(aAlias[1])
		EndIf
		
		//������������������������������������������������������������������������Ŀ
		//�Efetua o Pre-Processamento                                              �
		//��������������������������������������������������������������������������
		aEval(aPre[1],{|x| &(x) })
		
		If aAlias[1] <> "XXX"
			
			dbSelectArea(aAlias[1])
			
			aChvNivel[1] := Len (aChv)>=1 .And. !Empty (aChv[1]) .And. &(aChv[1])
			While ( !Eof() ) .And. lContinua .And. Iif (aChvNivel[1], &(aChv[1]), .T.)
				
				cBuffer := ""
				aSkipChv	:=	{.T., .F., .F.}	//Controle para execucao do skip de cada nivel, este controle eh utilizado para quando a IN estah usando a clausula CHV.
				
				If (sfVldPReg (@aPreReg[1], @nHandle))
					cDelimit	:=	AllTrim (aDelimit[1])
					cBuffer		+=	""
					//
					//�����������������������������������������������������������������������������������������������������������������������������������������������������������������������Ŀ
					//�Ha casos em que o delimitador eh so considerado no meio, ou so no inicio e fim, ou so no meio e fim, portanto foi criado a seguinte regra:                             �
					//�A clausula (DEL) no INI devera ser criada na seguinte estrutura:                                                                                                       �
					//�Ex: (DEL)|IMF, onde | eh o delimitador, I eh para gerar no incio de cada linha, M eh para gerar entre os campos de cada linha e F eh para gerar no final de cada linha.�
					//�Algumas formas de se utilizar:                                                                                                                                         �
					//�(DEL)|MF                                                                                                                                                               �
					//�(DEL)|M                                                                                                                                                                �
					//�(DEL)|IMF                                                                                                                                                              �
					//�(DEL)|IF                                                                                                                                                               �
					//�������������������������������������������������������������������������������������������������������������������������������������������������������������������������
					If (cFilDe#cFilAte)	//Somente para o Nivel 1, inicialmente resolver o caso do MANAD
						ConsoFil (aArqNew, cChaveCons, 1, aStru, aConteudo, cCmpGrvCon)
						DbSelectArea (aAlias[1])
						(aAlias[1])->(DbSkip ())
						Loop
					EndIf
					
					If (Len (cDelimit)>1)
						If ("I"$SubStr (cDelimit, 2))
							cBuffer	+=	SubStr (cDelimit, 1, 1)
						EndIf
					EndIf
					
					For nCntFor := 1 To Len(aStru[1])
						
						bError := ErrorBlock({|e| Help(" ",1,"NORMAERRO3",,aAlias[1]+"->"+aStru[1][nCntFor][1]+"|"+aConteudo[1][nCntFor],3,1) })
						BEGIN SEQUENCE
						
						uConteudo := &(aConteudo[1][nCntFor])
						
						Do Case
							Case ( aStru[1][nCntFor][2] == "N" )
								
								If ( uConteudo == Nil )
									uConteudo := 0
								EndIf
								
								If Empty (cMaskVlr) .Or. (aStru[1][nCntFor][4])==0
									uConteudo := NoRound(uConteudo*(10**(aStru[1][nCntFor][4])),aStru[1][nCntFor][4])
									//
									If (!Empty (aDelimit[1]))
										cBuffer += Iif (Empty (AllTrim (Str (uConteudo,aStru[1][nCntFor][3]))), "", AllTrim (Str (uConteudo,aStru[1][nCntFor][3])))
									Else
										cBuffer += StrZero(uConteudo,aStru[1][nCntFor][3])
									EndIf
								Else
									cBuffer += AllTrim (Transform (uConteudo, cMaskVlr))
								EndIf
								
							Case ( aStru[1][nCntFor][2] == "D" )
								
								If ( uConteudo == Nil )
									uConteudo := dDataBase
								EndIf
								cBuffer += PadR(Dtos(uConteudo),aStru[1][nCntFor][3])
								
							Case ( aStru[1][nCntFor][2] == "C" )
								
								If ( uConteudo == Nil )
									uConteudo := ""
								EndIf
								
								If (!Empty (aDelimit[1]))
									cBuffer += AllTrim (uConteudo)
								Else
									cBuffer += PadR(uConteudo,aStru[1][nCntFor][3])
								EndIf
								
						EndCase
						
						END SEQUENCE
						ErrorBlock(bError)
						//�����������������������������������������������������������������������������������������������������������������������������������������������������������������������Ŀ
						//�Ha casos em que o delimitador eh so considerado no meio, ou so no inicio e fim, ou so no meio e fim, portanto foi criado a seguinte regra:                             �
						//�A clausula (DEL) no INI devera ser criada na seguinte estrutura:                                                                                                       �
						//�Ex: (DEL)|IMF, onde | eh o delimitador, I eh para gerar no incio de cada linha, M eh para gerar entre os campos de cada linha e F eh para gerar no final de cada linha.�
						//�Algumas formas de se utilizar:                                                                                                                                         �
						//�(DEL)|MF                                                                                                                                                               �
						//�(DEL)|M                                                                                                                                                                �
						//�(DEL)|IMF                                                                                                                                                              �
						//�(DEL)|IF                                                                                                                                                               �
						//�������������������������������������������������������������������������������������������������������������������������������������������������������������������������
						If (Len (cDelimit)>1)
							If (nCntFor==Len(aStru[1]))
								If ("F"$SubStr (cDelimit, 2))
									cBuffer	+=	SubStr (cDelimit, 1, 1)
								EndIf
							Else
								If ("M"$SubStr (cDelimit, 2))
									cBuffer	+=	SubStr (cDelimit, 1, 1)
								EndIf
							EndIf
						EndIf
						
					Next nCntFor
					
					//������������������������������������������������������������������������Ŀ
					//�Efetua a Gravacao da Linha                                              �
					//��������������������������������������������������������������������������
					If !Empty(cBuffer)
						FWrite(nHAndle,cBuffer+Chr(13)+Chr(10))
						If ( Ferror()!=0 )
							Help(" ",1,"NORMAERRO4")
						EndIf
					EndIf
					//�����������������������Ŀ
					//�Incrementa o contador  �
					//�������������������������
					aEval(aContReg[1],{|x| &(x) })
					//�����������������������������������������Ŀ
					//�FIM DO PRIMEIRO NIVEL                    �
					//�������������������������������������������
					If Len(aAlias)>=2
						dbSelectArea(aAlias[2])
						aArea2 := GetArea()
						
						aEval(aPre[2],{|x| &(x) })
						
						aChvNivel[2] := Len (aChv)>=2 .And. !Empty (aChv[2])
						While ( !Eof() )  .And. Iif (aChvNivel[2], &(aChv[2]), .T.)
							cBuffer := ""
							aSkipChv	:=	{.T., .T., .F.}	//Controle para execucao do skip de cada nivel, este controle eh utilizado para quando a IN estah usando a clausula CHV.
							If (sfVldPReg (@aPreReg[2], @nHandle))
								
								cDelimit	:=	AllTrim (aDelimit[2])
								If (Len (cDelimit)>1)
									If ("I"$SubStr (cDelimit, 2))
										cBuffer	+=	SubStr (cDelimit, 1, 1)
									EndIf
								EndIf
								
								For nCntFor := 1 To Len(aStru[2])
									bError := ErrorBlock({|e| Help(" ",1,"NORMAERRO3",,aAlias[2]+"->"+aStru[2][nCntFor][1]+"|"+aConteudo[2][nCntFor],3,1) })
									BEGIN SEQUENCE
									uConteudo := &(aConteudo[2][nCntFor])
									Do Case
										Case ( aStru[2][nCntFor][2] == "N" )
											If ( uConteudo == Nil )
												uConteudo := 0
											EndIf
											
											If Empty (cMaskVlr) .Or. (aStru[1][nCntFor][4])==0
												uConteudo := NoRound(uConteudo*(10**(aStru[2][nCntFor][4])),aStru[2][nCntFor][4])
												If (!Empty (aDelimit[2]))
													cBuffer += Iif (Empty (AllTrim (Str (uConteudo,aStru[1][nCntFor][3]))), "", AllTrim (Str (uConteudo,aStru[1][nCntFor][3])))
												Else
													cBuffer += StrZero(uConteudo,aStru[2][nCntFor][3])
												EndIf
											Else
												cBuffer += AllTrim (Transform (uConteudo, cMaskVlr))
											EndIf
											
										Case ( aStru[2][nCntFor][2] == "D" )
											If ( uConteudo == Nil )
												uConteudo := dDataBase
											EndIf
											cBuffer += PadR(Dtos(uConteudo),aStru[2][nCntFor][3])
										Case ( aStru[2][nCntFor][2] == "C" )
											If ( uConteudo == Nil )
												uConteudo := ""
											EndIf
											
											If (!Empty (aDelimit[2]))
												cBuffer += AllTrim (uConteudo)
											Else
												cBuffer += PadR(uConteudo,aStru[2][nCntFor][3])
											EndIf
									EndCase
									END SEQUENCE
									ErrorBlock(bError)
									
									If (Len (cDelimit)>1)
										If (nCntFor==Len(aStru[2]))
											If ("F"$SubStr (cDelimit, 2))
												cBuffer	+=	SubStr (cDelimit, 1, 1)
											EndIf
										Else
											If ("M"$SubStr (cDelimit, 2))
												cBuffer	+=	SubStr (cDelimit, 1, 1)
											EndIf
										EndIf
									EndIf
									
								Next nCntFor
								//������������������������������������������������������������������������Ŀ
								//�Efetua a Gravacao da Linha  nivel 2                                     �
								//��������������������������������������������������������������������������
								If !Empty(cBuffer)
									FWrite(nHAndle,cBuffer+Chr(13)+Chr(10))
									If ( Ferror()!=0 )
										Help(" ",1,"NORMAERRO4")
									EndIf
								EndIf
								//�����������������������Ŀ
								//�Incrementa o contador  �
								//�������������������������
								aEval(aContReg[2],{|x| &(x) })
							EndIf
							//�������������������������������������Ŀ
							//�Inicio do nivel 3                    �
							//���������������������������������������
							If Len(aAlias)==3
								dbSelectArea(aAlias[3])
								aArea3 := GetArea()
								aEval(aPre[3],{|x| &(x) })
								
								aChvNivel[3] := Len (aChv)>=3 .And. !Empty (aChv[3])
								While ( !Eof() ) .And. Iif (aChvNivel[3], &(aChv[3]), .T.)
									
									cBuffer := ""
									aSkipChv	:=	{.T., .T., .T.}	//Controle para execucao do skip de cada nivel, este controle eh utilizado para quando a IN estah usando a clausula CHV.
									
									If (sfVldPReg (@aPreReg[3], @nHandle))
										
										cDelimit	:=	AllTrim (aDelimit[3])
										If (Len (cDelimit)>1)
											If ("I"$SubStr (cDelimit, 2))
												cBuffer	+=	SubStr (cDelimit, 1, 1)
											EndIf
										EndIf
										
										For nCntFor := 1 To Len(aStru[3])
											bError := ErrorBlock({|e| Help(" ",1,"NORMAERRO3",,aAlias[3]+"->"+aStru[3][nCntFor][1]+"|"+aConteudo[3][nCntFor],3,1) })
											BEGIN SEQUENCE
											uConteudo := &(aConteudo[3][nCntFor])
											Do Case
												Case ( aStru[3][nCntFor][2] == "N" )
													If ( uConteudo == Nil )
														uConteudo := 0
													EndIf
													
													If Empty (cMaskVlr) .Or. (aStru[1][nCntFor][4])==0
														uConteudo := NoRound(uConteudo*(10**(aStru[3][nCntFor][4])),aStru[3][nCntFor][4])
														If (!Empty (aDelimit[3]))
															cBuffer += Iif (Empty (AllTrim (Str (uConteudo,aStru[1][nCntFor][3]))), "", AllTrim (Str (uConteudo,aStru[1][nCntFor][3])))
														Else
															cBuffer += StrZero(uConteudo,aStru[3][nCntFor][3])
														EndIf
													Else
														cBuffer += AllTrim (Transform (uConteudo, cMaskVlr))
													EndIf
													
												Case ( aStru[3][nCntFor][2] == "D" )
													If ( uConteudo == Nil )
														uConteudo := dDataBase
													EndIf
													cBuffer += PadR(Dtos(uConteudo),aStru[3][nCntFor][3])
												Case ( aStru[3][nCntFor][2] == "C" )
													If ( uConteudo == Nil )
														uConteudo := ""
													EndIf
													
													If (!Empty (aDelimit[3]))
														cBuffer += AllTrim (uConteudo)
													Else
														cBuffer += PadR(uConteudo,aStru[3][nCntFor][3])
													EndIf
											EndCase
											END SEQUENCE
											ErrorBlock(bError)
											
											If (Len (cDelimit)>1)
												If (nCntFor==Len(aStru[3]))
													If ("F"$SubStr (cDelimit, 2))
														cBuffer	+=	SubStr (cDelimit, 1, 1)
													EndIf
												Else
													If ("M"$SubStr (cDelimit, 2))
														cBuffer	+=	SubStr (cDelimit, 1, 1)
													EndIf
												EndIf
											EndIf
											
										Next nCntFor
										//������������������������������������������������������������������������Ŀ
										//�Efetua a Gravacao da Linha  nivel 3                                     �
										//��������������������������������������������������������������������������
										If !Empty(cBuffer)
											FWrite(nHAndle,cBuffer+Chr(13)+Chr(10))
											If ( Ferror()!=0 )
												Help(" ",1,"NORMAERRO4")
											EndIf
										EndIf
										//�����������������������Ŀ
										//�Incrementa o contador  �
										//�������������������������
										aEval(aContReg[3],{|x| &(x) })
									EndIf
									aEval(aPosReg[3],{|x| &(x) })
									dbSelectArea(aAlias[3])
									dbSkip()
								EndDo
								//����������������������������������������������Ŀ
								//�Efetua o Pos-Processamento do nivel 3         �
								//������������������������������������������������
								aEval(aPos[3],{|x| &(x) })
								//����������������������������������������������Ŀ
								//�Efetua o INI-Processamento do nivel 3         �
								//������������������������������������������������
								aEval(aINI[3],{|x| ProcIni(x,nHAndle,@cTrab,cDir) })
								//��������������������������������������������������������������������������������������Ŀ
								//�Esta condicao se deve quando estiver utilizando a clausula (CHV), pois nao devo       �
								//�   retornar a Area salva antes do while, pois quando estiver utilizando esta clausula �
								//�   e sair do while jah estarah posicionado no proximo registro que deverah ser pro-   �
								//�   cessado novamente desde o nivel anterior, ou seja, neste caso, nivel 2.            �
								//����������������������������������������������������������������������������������������
								If !aChvNivel[3]
									RestArea(aArea3)
								EndIf
							EndIf
							//�����������������������Ŀ
							//�Fim do nivel 3         �
							//�������������������������
							If Len(aArq)>2
								If Len(aArq[3]) >= 1 .And. !Empty(aArq[3][1])
									//������������������������������������Ŀ
									//�Fecha e efetua a gravacao por bloco �
									//��������������������������������������
									FClose(nHAndle)
									// Caso seja necessario utilizar alguma informacao lancada em tempo de execucao no nome do arquivo, sera necessario gravar em um _aTotal
									If ("_ATOTAL["$Upper(aArq[3][1]))
										aArq[3][1]	:=	&(aArq[3][1])
									EndIf
									Ferase(cDir+aArq[3][1])
									__CopyFIle(cTrab,cDir+aArq[3][1])
									Ferase(cTrab)
									cTrab	:= CriaTrab(,.F.)+".TXT"
									nHAndle  := FCreate(cTrab,0)
								EndIf
							EndIf
							
							aEval(aPosReg[2],{|x| &(x) })
							dbSelectArea(aAlias[2])
							//�������������������������������������������������������������������������������������������Ŀ
							//�Tratamento para quando estiver utilizando a clausula (CHV) (condicao para o while).        �
							//�OBS: Nao precisarei dar SKIP novamente quando sair do terceiro NIVEL que tenha             �
							//�         o controle pela clausula (CHV), pois jah estara no proximo registro e nao deverah �
							//�         dar o SKIP novamente e sim voltar e processar o registro atual desde o nivel ante-�
							//�         rior, ou seja, neste caso o nivel 2                                               �
							//�OBS 2: A condicao abaixo determina NAO serah dado SKIP quando possuir a clausula CHV no    �
							//�         bloco em execucao, quando o alias do nivel 2 for igual ao alias do nivel 3 e quan-�
							//�         estiver executado o while do nivel 3, onde jah foi executado o SKIP e a tabela jah�
							//�         jah saiu do while com SKIP.                                                       �
							//���������������������������������������������������������������������������������������������
							If !(aChvNivel[3] .And. Len (aAlias)>=3 .And. aAlias[2]==aAlias[3] .And. aSkipChv[3])
								dbSkip()
							EndIf
						EndDo
						//����������������������������������������������Ŀ
						//�Efetua o Pos-Processamento do nivel 2         �
						//������������������������������������������������
						aEval(aPos[2],{|x| &(x) })
						//����������������������������������������������Ŀ
						//�Efetua o INI-Processamento do nivel 2         �
						//������������������������������������������������
						aEval(aINI[2],{|x| ProcIni(x,nHAndle,@cTrab,cDir) })
						//��������������������������������������������������������������������������������������Ŀ
						//�Esta condicao se deve quando estiver utilizando a clausula (CHV), pois nao devo       �
						//�   retornar a Area salva antes do while, pois quando estiver utilizando esta clausula �
						//�   e sair do while jah estarah posicionado no proximo registro que deverah ser pro-   �
						//�   cessado novamente desde o nivel anterior, ou seja, neste caso, nivel 1.            �
						//����������������������������������������������������������������������������������������
						If !(aChvNivel[2])
							RestArea(aArea2)
						EndIf
					EndIf
					//�����������������������Ŀ
					//�Fim do nivel 2         �
					//�������������������������
					If Len(aArq)>=2
						If Len(aArq[2]) >= 1 .And. !Empty(aArq[2][1])
							//������������������������������������Ŀ
							//�Fecha e efetua a gravacao por bloco �
							//��������������������������������������
							FClose(nHAndle)
							// Caso seja necessario utilizar alguma informacao lancada em tempo de execucao no nome do arquivo, sera necessario gravar em um _aTotal
							If ("_ATOTAL["$Upper(aArq[2][1]))
								aArq[2][1]	:=	&(aArq[2][1])
							EndIf
							Ferase(cDir+aArq[2][1])
							__CopyFIle(cTrab,cDir+aArq[2][1])
							Ferase(cTrab)
							cTrab	:= CriaTrab(,.F.)+".TXT"
							nHAndle  := FCreate(cTrab,0)
						EndIf
					EndIf
					aEval(aPosReg[1],{|x| &(x) })
				EndIf
				
				dbSelectArea(aAlias[1])
				//�������������������������������������������������������������������������������������������Ŀ
				//�Tratamento para quando estiver utilizando a clausula (CHV) (condicao para o while).        �
				//�OBS: Nao precisarei dar SKIP novamente quando sair do terceiro/segundo NIVEL que tenha     �
				//�         o controle pela clausula (CHV), pois jah estarah no proximo registro e nao deverah�
				//�         dar o SKIP novamente e sim voltar e processar o registro atual desde o nivel ante-�
				//�         rior, ou seja, neste caso o nivel 1                                               �
				//�OBS 2: A condicao abaixo determina NAO serah dado SKIP quando possuir a clausula CHV no    �
				//�         bloco em execucao, quando o alias do nivel 1 for igual ao alias do nivel 2 e quan-�
				//�         estiver executado o while do nivel 2, onde jah foi executado o SKIP e a tabela jah�
				//�         jah saiu do while com SKIP.                                                       �
				//���������������������������������������������������������������������������������������������
				If !(aChvNivel[2] .And. Len (aAlias)>=2 .And. aAlias[1]==aAlias[2] .And. aSkipChv[2])
					dbSkip()
				EndIf
			EndDo
		Else
			cBuffer := ""
			If (sfVldPReg (@aPreReg[1], @nHandle))
				
				cDelimit	:=	AllTrim (aDelimit[1])
				If (Len (cDelimit)>1)
					If ("I"$SubStr (cDelimit, 2))
						cBuffer	+=	SubStr (cDelimit, 1, 1)
					EndIf
				EndIf
				
				For nCntFor := 1 To Len(aStru[1])
					bError := ErrorBlock({|e| Help(" ",1,"NORMAERRO3",,aAlias[1]+"->"+aStru[1][nCntFor][1]+"|"+aConteudo[1][nCntFor],3,1) })
					BEGIN SEQUENCE
					uConteudo := &(aConteudo[1][nCntFor])
					Do Case
						Case ( aStru[1][nCntFor][2] == "N" )
							If ( uConteudo == Nil )
								uConteudo := 0
							EndIf
							
							If Empty (cMaskVlr) .Or. (aStru[1][nCntFor][4])==0
								uConteudo := NoRound(uConteudo*(10**(aStru[1][nCntFor][4])),aStru[1][nCntFor][4])
								If (!Empty (aDelimit[1]))
									cBuffer += Iif (Empty (AllTrim (Str (uConteudo,aStru[1][nCntFor][3]))), "", AllTrim (Str (uConteudo,aStru[1][nCntFor][3])))
								Else
									cBuffer += StrZero(uConteudo,aStru[1][nCntFor][3])
								EndIf
							Else
								cBuffer += AllTrim (Transform (uConteudo, cMaskVlr))
							EndIf
							
						Case ( aStru[1][nCntFor][2] == "D" )
							If ( uConteudo == Nil )
								uConteudo := dDataBase
							EndIf
							cBuffer += PadR(Dtos(uConteudo),aStru[1][nCntFor][3])
						Case ( aStru[1][nCntFor][2] == "C" )
							If ( uConteudo == Nil )
								uConteudo := ""
							EndIf
							
							If (!Empty (aDelimit[1]))
								cBuffer += AllTrim (uConteudo)
							Else
								cBuffer += PadR(uConteudo,aStru[1][nCntFor][3])
							EndIf
					EndCase
					END SEQUENCE
					ErrorBlock(bError)
					
					If (Len (cDelimit)>1)
						If (nCntFor==Len(aStru[1]))
							If ("F"$SubStr (cDelimit, 2))
								cBuffer	+=	SubStr (cDelimit, 1, 1)
							EndIf
						Else
							If ("M"$SubStr (cDelimit, 2))
								cBuffer	+=	SubStr (cDelimit, 1, 1)
							EndIf
						EndIf
					EndIf
					
				Next nCntFor
				//������������������������������������������������������������������������Ŀ
				//�Efetua a Gravacao da Linha                                              �
				//��������������������������������������������������������������������������
				If !Empty(cBuffer)
					If ("TOP"$aOrd[1])
						cBufferFim += "T"+cBuffer
					ElseIf ("BOT"$aOrd[1])
						cBufferFim += "B"+cBuffer
					Else
						FWrite(nHAndle,cBuffer+Chr(13)+Chr(10))
						If ( Ferror()!=0 )
							Help(" ",1,"NORMAERRO4")
						EndIf
					EndIf
				EndIf
				aEval(aPosReg[1],{|x| &(x) })
				//�����������������������Ŀ
				//�Incrementa o contador  �
				//�������������������������
				aEval(aContReg[1],{|x| &(x) })
			EndIf
		EndIf
		//
		SM0->(DbSkip ())
	EndDo
	//������������������������������������������������������������������������Ŀ
	//�Restaura a integridade da rotina                                        �
	//��������������������������������������������������������������������������
	RestArea(aAreaSm0)
	cFilAnt	:=	SM0->M0_CODFIL
	
	//������������������������������������������������������������������������Ŀ
	//�Efetua o Pos-Processamento                                              �
	//��������������������������������������������������������������������������
	aEval(aPos[1],{|x| &(x) })
	//����������������������������������������������Ŀ
	//�Efetua o INI-Processamento do nivel 1         �
	//������������������������������������������������
	aEval(aINI[1],{|x| ProcIni(x,nHAndle,@cTrab,cDir) })
	//���������������������Ŀ
	//�Restaura demais areas�
	//�����������������������
	RestArea(aArea1)
	RestArea(aArea)
	
	If (cFilDe#cFilAte)
		GeroConso (nHAndle, aDelimit, aStru, aArqNew, aAlias, aConteudo, aPosReg, aContReg, cMaskVlr)
		TrbConso (2,,,, aArqNew)
	EndIf
	
	If Len(aArq) >= 1
		If Len(aArq[1]) >= 1  .And. !Empty(aArq[1][1])
			//������������������������������������Ŀ
			//�Fecha e efetua a gravacao por bloco �
			//��������������������������������������
			FClose(nHAndle)
			// Caso seja necessario utilizar alguma informacao lancada em tempo de execucao no nome do arquivo, sera necessario gravar em um _aTotal
			If ("_ATOTAL["$Upper(aArq[1][1]))
				aArq[1][1]	:=	&(aArq[1][1])
			EndIf
			Ferase(cDir+aArq[1][1])
			__CopyFile(cTrab,cDir+aArq[1][1])
			Ferase(cTrab)
			cTrab	:= CriaTrab(,.F.)+".TXT"
			nHAndle  := FCreate(cTrab,0)
		EndIf
	EndIf
	
	Return(cBufferFim)
	/*/
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������Ŀ��
	���Programa  �sfVldPReg � Autor � Gustavo G. Rueda      � Data �26.06.2003���
	�������������������������������������������������������������������������Ĵ��
	���Descri��o �Funcao utilizada para validar o (PREREG) dos INI's, podendo ���
	���          �inserir uma condicao ou uma funcao retornando uma string.   |��
	�������������������������������������������������������������������������Ĵ��
	���Retorno   �ExpL: .T./.F.                                               ���
	���          �                                                            ���
	�������������������������������������������������������������������������Ĵ��
	���Parametros�ExpA1: Array contendo todos PreReg                          ���
	���          �ExpN2: Controle                                             ���
	�������������������������������������������������������������������������Ĵ��
	���   DATA   � Programador   �Manutencao Efetuada                         ���
	�������������������������������������������������������������������������Ĵ��
	���          �               �                                            ���
	��������������������������������������������������������������������������ٱ�
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	/*/
	Static Function sfVldPReg (aPreReg, nHandle)
	Local	lRet	:=	.T.
	Local	nInd	:=	0
	Local	aArea	:=	GetArea ()
	Local	xVar
	Local   cVar
	//
	If (Len (aPreReg)<>0)
		For nInd := 1 To Len (aPreReg)
			cVar	:= aPreReg[nInd]
			xVar	:=	&(aPreReg[nInd])
			If (ValType(xVar)=="C") .And. !":="$cVar
				FWrite (nHandle, xVar+Chr(13)+Chr(10))
				lRet	:=	.T.
			Else
				If (ValType (xVar)=="L")
					If !xVar
						lRet	:=	xVar
						Exit
					EndIf
				Else
					lRet	:=	.T.
				EndIf
			EndIf
		Next (nInd)
	EndIf
	RestArea (aArea)
Return (lRet)

Static Function AjustaSE1( _nValor )
Local _nVlRet := 0
Local _cValor := AllTrim( Str( _nValor ) )
Local _nPos   := At('.', _cValor )

If Len( _nPos ) > 0
_nVlRet := Val( SubStr( _cValor, 1, _nPos-1 ) + SubStr( _cValor, _nPos+1, 2 ) )
Else
_nVlRet := Val( _cValor )
EndIf

Return _nVlRet
