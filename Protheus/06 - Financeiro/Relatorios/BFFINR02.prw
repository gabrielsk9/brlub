//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)

/*/{Protheus.doc} BFFINR02
Relat�rio - Relatorio Hospedagens         
@author zReport
@since 22/11/2019
@version 1.0
@example
u_BFFINR02()
@obs Fun��o gerada pelo zReport()
/*/

User Function BFFINR02()

	Local 	aArea   := GetArea()
	Local 	oReport
	Local 	lEmail  := .F.
	Local 	cPara   := ""
	Private cPerg 	:= ""

	//Defini��es da pergunta
	cPerg := "BFFINR02  "

	//Se a pergunta n�o existir, zera a vari�vel
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf

	//Cria as defini��es do relat�rio
	oReport := fReportDef()

	//Ser� enviado por e-Mail?
	If lEmail
		oReport:nRemoteType := NO_REMOTE
		oReport:cEmail := cPara
		oReport:nDevice := 3 //1-Arquivo,2-Impressora,3-email,4-Planilha e 5-Html
		oReport:SetPreview(.F.)
		oReport:Print(.F., "", .T.)
		//Sen�o, mostra a tela
	Else
		oReport:PrintDialog()
	EndIf

	RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
| Func:  fReportDef                                                             |
| Desc:  Fun��o que monta a defini��o do relat�rio                              |
*-------------------------------------------------------------------------------*/

Static Function fReportDef()
	Local oReport
	Local oSectDad := Nil
	Local oBreak := Nil

	//Cria��o do componente de impress�o
	oReport := TReport():New(	"BFFINR02",;		//Nome do Relat�rio
	"Relatorio Hospedagens",;		//T�tulo
	cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, ser� impresso uma p�gina com os par�metros, conforme privil�gio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de c�digo que ser� executado na confirma��o da impress�o
	)		//Descri��o
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()

	//Criando a se��o de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a se��o pertence
	"Dados",;		//Descri��o da se��o
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira ser� considerada como principal da se��o
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores ser�o impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relat�rio
	TRCell():New(oSectDad, "COLABORADOR"	, "QRY_AUX", "Colaborador"	, /*Picture*/, 14, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "HOTEL"			, "QRY_AUX", "Hotel"		, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NF"				, "QRY_AUX", "Num.Nota"		, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VALOR_NF"		, "QRY_AUX", "Valor Nota"	, "@E 999,999,999.99"/*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "EMISSAO_NF"		, "QRY_AUX", "Data Emiss�o"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "QTD_JANTA"		, "QRY_AUX", "Qtd Janta"	, /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CENTRO_CUSTO"	, "QRY_AUX", "Centro Custo"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOME_CCUSTO"	, "QRY_AUX", "Nome Custo"	, /*Picture*/, 40, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "FORNECEDOR"		, "QRY_AUX", "Fornecedor"	, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "LOJA"			, "QRY_AUX", "Loja"			, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "RAZAO"			, "QRY_AUX", "Raz�o"		, /*Picture*/, 60, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*-------------------------------------------------------------------------------*
| Func:  fRepPrint                                                              |
| Desc:  Fun��o que imprime o relat�rio                                         |
*-------------------------------------------------------------------------------*/

Static Function fRepPrint(oReport)
	Local aArea    := GetArea()
	Local cQryAux  := ""
	Local oSectDad := Nil
	Local nAtual   := 0
	Local nTotal   := 0

	//Pegando as se��es do relat�rio
	oSectDad := oReport:Section(1)

	//Montando consulta de dados
	cQryAux := ""
	cQryAux += "SELECT D1_PART COLABORADOR,D1_HOTEL HOTEL,D1_DOC NF,D1_TOTAL VALOR_NF,TO_DATE(D1_EMISSAO,'YYYYMMDD') EMISSAO_NF,D1_REFEIC QTD_JANTA,"		+ STR_PULA
	cQryAux += "       D1_CC CENTRO_CUSTO, NVL(CTT_DESC01,' ') NOME_CCUSTO,D1_FORNECE FORNECEDOR,D1_LOJA LOJA,A2_NOME RAZAO "		+ STR_PULA
	cQryAux += "  FROM " + RetSqlName("SD1") + " D1"		+ STR_PULA
	cQryAux += "  LEFT JOIN " + RetSqlName("CTT") + " CTT "		+ STR_PULA
	cQryAux += "    ON CTT.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND CTT_CUSTO = D1_CC"		+ STR_PULA
	cQryAux += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "		+ STR_PULA
	cQryAux += "  JOIN " + RetSqlName("SA2") + " A2"		+ STR_PULA
	cQryAux += "    ON A2.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND A2_LOJA = D1_LOJA"		+ STR_PULA
	cQryAux += "   AND A2_COD = D1_FORNECE"		+ STR_PULA
	cQryAux += "   AND A2_FILIAL = '"+xFilial("SA2")+"'"		+ STR_PULA
	cQryAux += " WHERE D1.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND D1_EMISSAO  BETWEEN '"+ DTOS(MV_PAR01) +"' AND '" + DTOS(MV_PAR02)+ "'"		+ STR_PULA
	cQryAux += "   AND D1_DTDIGIT BETWEEN '"+ DTOS(MV_PAR03) +"' AND '" + DTOS(MV_PAR04)+ "'"		+ STR_PULA
	cQryAux += "   AND D1_HOTEL <>  ' ' "		+ STR_PULA
	cQryAux += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "		+ STR_PULA
	

	//Executando consulta e setando o total da r�gua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)

	//Enquanto houver dados
	oSectDad:Init()
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		//Incrementando a r�gua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro "+cValToChar(nAtual)+" de "+cValToChar(nTotal)+"...")
		oReport:IncMeter()

		//Imprimindo a linha atual
		oSectDad:PrintLine()

		QRY_AUX->(DbSkip())
	EndDo
	oSectDad:Finish()
	QRY_AUX->(DbCloseArea())

	RestArea(aArea)
Return
