#include 'protheus.ch'

/*/{Protheus.doc} XMLCTE24
// Ponto de entrada para adicionar bot�es na tela da Central XML
// Este ponto de entrada deve ser usado em conjunto com o XMLCTE07 ( Adiciona bot�es no vetor aButton que vai para a rotina Outras A��es )
@author Marcelo Alberto Lauschner
@since 03/08/2019
@version 1.0
@return Nil
@type User Function
/*/
User function XMLCTE24()

	Local	cInObj		:= ParamIxb[1]
	Local	oInObj		:= ParamIxb[2]
	Local	aAreaOld	:= GetArea()
	
	// Grupo Documento Entrada
	If cInObj == 'DOC'

	// Grupo Relat�rios
	ElseIf cInObj == 'REL'
	// Grupo Consultas 
	ElseIf cInObj == 'CON'
	// Grupo Exportar 
	ElseIf cInObj == 'EXP'
		//If !lSuperUsr // Se n�o for usu�rio do tipo Fiscal ainda assim permite op��o de exportar XMLs 
			// Adiciona bot�o de exportar 
			Private oBtnExp11 := TMenuItem():New(oInObj, "Exportar Xml posicionado"	 , , , ,{|| Processa({||stExpXml(),"Gerando exporta��o dos dados...."})}, , , , , , , , , .T. )
			oInObj:add(oBtnExp11)
		//Endif 
	Endif
	
	RestArea(aAreaOld)
	
Return

Static Function stExpXml() 

	cLocDir	:= cGetFile("",OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Selecione Diret�rio"),0,"c:\temp\",.T.,GETF_RETDIRECTORY+GETF_LOCALHARD,.F.,)

	If Empty(cLocDir)
		oArqXml:SetFocus()
		Return
	Endif

	If !MsgYesNo("Deseja realmente exportar o arquivo XML para o diret�rio informado?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Exporta��o de XML�s")
		oArqXml:SetFocus()
		Return
	Endif

	U_MLDBSLCT("CONDORXML",.F.,1)
	If DbSeek(aArqXml[oArqXml:nAt,nPosChvNfe])
		MemoWrite(cLocDir+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+".xml",CONDORXML->XML_ARQ)

		If !Empty(CONDORXML->XML_ATT2)
			MemoWrite(cLocDir+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+".pdf",CONDORXML->XML_ATT2)
		Endif
		
	Else
		MsgAlert("N�o encontrou o arquivo da Chave '"+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+"' para gerar o arquivo XML",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" A T E N � � O!! ")
	Endif
	
	shellExecute("Open", cLocDir, "", cLocDir, 1 )

	U_MLDBSLCT("CONDORXML",.F.,1)
	DbSeek(aArqXml[oArqXml:nAt,nPosChvNfe])
	oArqXml:SetFocus()

Return 
