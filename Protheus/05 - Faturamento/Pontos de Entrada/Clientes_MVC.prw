#include "protheus.ch"
#include "parmtype.ch"

/*/{Protheus.doc} CRMA980
Pontos de entrada de clientes migrado para a vers�o MVC.
@type function
@author  Rafael Pianezzer de Souza
@since   03/02/2022
@version 1.0
/*/

User Function CRMA980()
	Local aParam            := PARAMIXB
	Local xRet              := .T.
	Local oObj              := ""
	Local cIdPonto          := ""
	Local cIdModel          := ""
	Local lIsGrid           := .F.
	Local cFunCall  		:= SubStr(ProcName(0),3)
	Local lPEICMAIS 		:= ExistBlock( 'T' + cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
	Local aCamp     	    := {}
	Local lRet		        := .T.
	Local lContinua 	    := .F.
	Local aFora     	    := {}
	Local aArea 		    := GetArea()
	Local ik
	Local cVldAltCpo	    := "A1_CGC#A1_INSCR#A1_NOME#A1_NREDUZ#A1_CEP#A1_END#A1_COMPLEM#A1_EST#A1_COD_MUN#A1_MUN#A1_BAIRRO#A1_DDD#A1_TEL#A1_CONTATO#A1_EMAIL#A1_REFCOM1#A1_REFCOM3"
	Local lAltCpo		    := .F.
	Local oField            := NIL
	Local lX3Usado          := .T.
	Local l123				:= IsInCallStack("PNUITPED")
	Local nX

	If aParam <> NIL
		
		If lPEICMAIS	
			ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
		EndIf

		If !l123

			oObj := aParam[1]
			cIdPonto := aParam[2]
			cIdModel := aParam[3]
			lIsGrid := (Len(aParam) > 3)

			If cIdPonto == "MODELPOS"
			ElseIf cIdPonto == "MODELVLDACTIVE"
			ElseIf cIdPonto == "FORMPOS"

				/* ==========================================   TROCA DE FUN��O MA030TOK ========================================== */
				If Alltrim(cIdModel) == "SA1MASTER"

					// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
					If !U_BFCFGM25("MA030TOK")
						Return .T.
					Endif

					// Executa grava��o do Log de Uso da rotina
					U_BFCFGM01()

					If !ALTERA .And. !INCLUI
						RestArea(aArea)
						Return .T.
					Endif

					oField := oObj:GetModel("SA1MASTER")
					oField:SetValue("SA1MASTER","A1_ULTALT",dDataBase)

					//IAGO 16/12/2015 - Ajuste para integracao Accera
					If oField:GetValue("SA1MASTER","A1_EST")  == "PR" .And. cEmpAnt == "02"
						If Empty(oField:GetValue("SA1MASTER","A1_RAMACCE"))
							MsgAlert("O preenchimento do campo [Ramo Accera] � obrigat�rio para clientes do PR!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							RestArea(aArea)
							Return .F.
						EndIf
					Endif

					//dbSelectArea("SX3")
					//dbSetOrder(1)
					//dbSeek("SA1")
					aFields := {}

					aFields := FWSX3Util():GetAllFields("SA1", .F. /*/lVirtual/*/)

					For nX := 1 to Len(aFields)

						cCampo := aFields[nx]
						//While !EOF() .And. (x3_arquivo == "SA1")
						If GetSx3Cache(cCampo,"X3_context") <> 'V'
							If Ascan(aFora,Trim(GetSx3Cache(cCampo,"X3_CAMPO"))) <= 0
								cCampo := GetSx3Cache(cCampo,"X3_CAMPO")
								lX3Usado := X3USO(GetSX3Cache(cCampo, "X3_USADO"))
								If lX3Usado
									Aadd(aCamp, { GetSx3Cache(cCampo,"X3_CAMPO"), GetSx3Cache(cCampo,"X3_TIPO"), GetSx3Cache(cCampo,"X3_TAMANHO"), GetSx3Cache(cCampo,"X3_DECIMAL"),GetSx3Cache(cCampo,"X3_TITULO") } )
								EndIf
							Endif
						Endif
						//	dbSkip()
						//EndDO
					Next nX

					If INCLUI
						sfInclusao(aCamp)  // chama workflow de inclus�o de produto
					ElseIf ALTERA

					cSA1_USR := GetNewPar("BF_SA1_USR","000000")

						For ik := 1 To Len(aCamp)
							If &("SA1->"+aCamp[ik,1]) <> oField:GetValue("SA1MASTER", aCamp[ik,1] )
								lContinua := .T.
								// 04/03/2019 - Chamado 22.670 - Define regra que cliente alterado ajustado o campo de limite cr�dito automaticamente para 1.99
								If !(__cUserId $ cSA1_USR ) .And. Alltrim(aCamp[ik,1]) $ cVldAltCpo
									lAltCpo			:= .T.
								Endif
								//Exit
							Endif
						Next

						If lContinua
							lRet := sfAltera(aCamp,lAltCpo,oField)
						Endif
					Endif

					RestArea(aArea)

				EndIf

				/* ==========================================   TROCA DE FUN��O MA030TOK ========================================== */

			ElseIf cIdPonto == "FORMLINEPRE"

			ElseIf cIdPonto == "FORMLINEPOS"

			ElseIf cIdPonto == "MODELCOMMITTTS"

			ElseIf cIdPonto == "MODELCOMMITNTTS"

			ElseIf cIdPonto == "FORMCOMMITTTSPRE"

			ElseIf cIdPonto == "FORMCOMMITTTSPOS"

			ElseIf cIdPonto == "MODELCANCEL"

			ElseIf cIdPonto == "BUTTONBAR"
				xRet	:= { {"Consulta Receita","AMARELO",{|| sfReceita() }} }
			EndIf

		EndIf
	EndIf

Return xRet


Static Function sfAltera(aCamp,lAltCpo,oField)

	Local	cSendMail	:= ""// Chamado 25777 Desativado o envio de email para o setor Cr�dito "credito1@atrialub.com.br;cobranca1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML
	Local   x

	DbSelectArea('SA1')
	DbSetOrder(1)
	DbSeek(xFilial('SA1')+oField:GetValue("SA1MASTER",'A1_COD') + oField:GetValue("SA1MASTER",'A1_LOJA') )

	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Altera��o de cadastro de Clientes"))

	//���������������������������������������������������������������������Ŀ
	//� Abre o HTML criado                                                  �
	//�����������������������������������������������������������������������
	If IsSrvUnix()
		If File("/workflow/ma030tok.htm")
			oProcess:NewTask("Gerando HTML","/workflow/ma030tok.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "N�o localizou arquivo  /workflow/ma030tok.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\ma030tok.htm")
	Endif

	oProcess:cSubject := "Cliente Alterado-> "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	// Preenche os dados do cabecalho
	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscri��o Estadual: " + SM0->M0_INSC)

	For x := 1 To Len(aCamp)
		If &("SA1->"+aCamp[x,1]) <> &("M->"+aCamp[x,1])
			AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
			AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

			If aCamp[x,2] == "N"
				AAdd((oHtml:ValByName("p.orig")),Transform(&("SA1->"+aCamp[x,1]),"@E 999,999,999.99"))
				AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
			Else
				AAdd((oHtml:ValByName("p.orig")),&("SA1->"+aCamp[x,1]))
				AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
			Endif

		Endif
	next

	If lAltCpo
		AAdd((oHtml:ValByName("p.col"))	,"Altera��o de dados Cadastrais")
		AAdd((oHtml:ValByName("p.camp")),"Ser� necess�rio revisar")
		AAdd((oHtml:ValByName("p.orig")),"cadastro e restaurar")
		AAdd((oHtml:ValByName("p.nov"))	,"o limite de cr�dito.")

		AAdd((oHtml:ValByName("p.col"))	,"A1_LC")
		AAdd((oHtml:ValByName("p.camp")),"Limite Cr�dito")
		AAdd((oHtml:ValByName("p.orig")),Transform(Iif(SA1->A1_LC == 1.99 .And. SA1->A1_VALREMB > 0, SA1->A1_VALREMB, SA1->A1_LC),"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("p.nov"))	,Transform(M->A1_LC,"@E 999,999,999.99"))
	Endif

	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	If lAltCpo
		cSendMail	+= UsrRetMail(RetCodUsr())
	Else
		cSendMail	:= UsrRetMail(RetCodUsr())
	Endif

	oProcess:cTo := U_BFFATM15(cSendMail,"MT030TOK")

	oProcess:Start()
	oProcess:Finish()

	// For�a disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return(.T.)


/*/{Protheus.doc} sfInclusao
//Gera Workflow quando for inclu�do um novo cliente
@author Marcelo Alberto Lauschner
@since 15/08/2017
@version 6

@type function
/*/
Static Function sfInclusao(aCamp)

	Local	cSendMail	:= "" // Chamado 25777 Desativado o envio de email para o setor Cr�dito  "credito1@atrialub.com.br;cobranca1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML
	Local   x

	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclus�o de cadastro de Cliente."))

	//���������������������������������������������������������������������Ŀ
	//� Abre o HTML criado                                                  �
	//�����������������������������������������������������������������������
	If IsSrvUnix()
		If File("/workflow/ma030tok.htm")
			oProcess:NewTask("Gerando HTML","/workflow/ma030tok.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "N�o localizou arquivo  /workflow/ma030tok.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\ma030tok.htm")
	Endif


	oProcess:cSubject := "Cadastro de Cliente inclu�do -> "+M->A1_COD+"/"+M->A1_LOJA +"-" +M->A1_NREDUZ
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	// Preenche os dados do cabecalho
	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscri��o Estadual: " + SM0->M0_INSC)


	For x := 1 To Len(aCamp)
		AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
		AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

		If aCamp[x,2] == "N"
			AAdd((oHtml:ValByName("p.orig")),"")
			AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
		Else
			AAdd((oHtml:ValByName("p.orig")),"")
			AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
		Endif


	next


	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	cSendMail	+= UsrRetMail(RetCodUsr())
	oProcess:cTo := U_BFFATM15(cSendMail,"MT030TOK")

	oProcess:Start()
	oProcess:Finish()

	// For�a disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return





/*/{Protheus.doc} sfReceita
//Fun��o que verifica via HTTPS os dados do cadastro do CNPJ
@author Marcelo Alberto Lauschner
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReceita()

	// Vari�vel Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + M->A1_CGC
	Local	cJsonRet	:=  HttpGet(cUrlRec)
	Local	cQry
	Local	cVarAux
	Local	oModelA1 	:= FWModelActive()
	// Vari�vel L�gica
	Local	lRetCep		:= .F.
	// Vari�vel Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Situa��o Cadastral diferente de 'Ativa'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necess�rio fazer o cadastro."},;
				5)
			Return
		Endif
	Else
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"Erro na chamada. Retorno: "+cJsonRet},;
			5,;
			{"Efetue o cadastro do cliente manualmente a partir da consulta no Sintegra!"},;
			5)
		Return
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Status diferente de 'OK'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necess�rio fazer o cadastro."},;
				5)
			Return
		Endif

	Endif

	//If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
	//	oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
	//Endif
	//If Type("M->A2_XCCPASV") == "C"
	//	M->A2_XCCPASV	:= cA2XCCPASV
	//Endif


	If Type("oParseJSON:nome") <> "U"
		M->A1_NOME	:= Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A1_NOME")[1])

		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NOME',M->A1_NOME)
		Endif
	Endif

	If Type("oParseJSON:fantasia") <> "U"
		M->A1_NREDUZ	:= Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A1_NREDUZ")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NREDUZ',M->A1_NREDUZ)
		Endif
	Endif

	If Type("oParseJSON:email") <> "U"
		M->A1_EMAIL	:= Padr(oParseJSON:email,TamSX3("A1_EMAIL")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_EMAIL',M->A1_EMAIL)
		Endif
	Endif

	If Type("oParseJSON:cep") <> "U"
		M->A1_CEP	:= Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_CEP',M->A1_CEP)
		Endif
		//lRetCep	    := Se necess�rio criar uma regra pr�pria para preenchimetno do CEP
		// Aciona gatilhos do campo CEP
		If ExistTrigger('A1_CEP')
			RunTrigger(1,nil,nil,,'A1_CEP')
		Endif
	Endif


	If Type("oParseJSON:abertura") <> "U"
		M->A1_DTNASC	:= CTOD(oParseJSON:abertura)
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_DTNASC',M->A1_DTNASC)
		Endif
	Endif

	// Se a valida��o do CEP n�o ocorreu, preenche os dados a partir da RECEITA
	If !lRetCep
		If Type("oParseJSON:logradouro") <> "U"
			M->A1_END	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:numero") <> "U"
			cVarAux		:= Alltrim(M->A1_END)
			M->A1_END	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:bairro") <> "U"
			M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
			M->A1_BAIRROE	:= M->A1_BAIRRO
			M->A1_BAIRROC	:= M->A1_BAIRRO
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
			Endif
		Endif

		If Type("oParseJSON:complemento") <> "U"
			M->A1_COMPLEM	:= Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_COMPLEM',M->A1_COMPLEM)
			Endif
		Endif

		If Type("oParseJSON:municipio") <> "U"
			M->A1_MUN	:= Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_MUN',M->A1_MUN)
			Endif
		Endif

		If Type("oParseJSON:uf") <> "U"
			M->A1_EST	:= Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_EST',M->A1_EST)
			Endif
		Endif

		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		cQry += "   AND CC2_MUN LIKE '%"+ oParseJSON:municipio + "%' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			M->A1_COD_MUN	:=  TBLEXIST->CC2_CODMUN
		Endif
		TBLEXIST->(DbCloseArea())

	Else
		If Type("oParseJSON:numero") <> "U"
			cVarAux			:= Alltrim(M->A1_END)
			If Empty(cVarAux)
				If Type("oParseJSON:logradouro") <> "U"
					cVarAux	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
				Endif
			Endif
			M->A1_END		:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDCOB")[1])
			M->A1_ENDENT	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDENT")[1])

			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
			cVarAux			:= Alltrim(M->A1_BAIRRO)

			If Empty(cVarAux) .And. Type("oParseJSON:bairro") <> "U"
				M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
				M->A1_BAIRROE	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROE")[1])
				M->A1_BAIRROC	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROC")[1])
				If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
				Endif
			Endif

		Endif
	Endif
Return


/*/{Protheus.doc} sfAjust
//Ajusta o texto do JSON
@author Marcelo Alberto Lauschneer
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}
@param cInChar, characters, descricao
@param lOutJson, logical, descricao
@type function
/*/
Static Function sfAjust(cInChar,lOutJson)

	Local	cOut		:= DecodeUTF8(cInChar, "iso8859-1")
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
	Aadd(aOut,{"�","\u00e1","a"})
	Aadd(aOut,{"�","\u00e0","a"})
	Aadd(aOut,{"�","\u00e2","a"})
	Aadd(aOut,{"�","\u00e3","a"})
	Aadd(aOut,{"�","\u00e4","a"})
	Aadd(aOut,{"�","\u00c1","a"})
	Aadd(aOut,{"�","\u00c0","a"})
	Aadd(aOut,{"�","\u00c2","a"})
	Aadd(aOut,{"�","\u00c3","a"})
	Aadd(aOut,{"�","\u00c4","a"})
	Aadd(aOut,{"�","\u00e9","e"})
	Aadd(aOut,{"�","\u00e8","e"})
	Aadd(aOut,{"�","\u00ea","e"})
	Aadd(aOut,{"�","\u00ea","e"})
	Aadd(aOut,{"�","\u00c9","e"})
	Aadd(aOut,{"�","\u00c8","e"})
	Aadd(aOut,{"�","\u00ca","e"})
	Aadd(aOut,{"�","\u00cb","e"})
	Aadd(aOut,{"�","\u00ed","i"})
	Aadd(aOut,{"�","\u00ec","i"})
	Aadd(aOut,{"�","\u00ee","i"})
	Aadd(aOut,{"�","\u00ef","i"})
	Aadd(aOut,{"�","\u00cd","i"})
	Aadd(aOut,{"�","\u00cc","i"})
	Aadd(aOut,{"�","\u00ce","i"})
	Aadd(aOut,{"�","\u00cf","i"})
	Aadd(aOut,{"�","\u00f3","o"})
	Aadd(aOut,{"�","\u00f2","o"})
	Aadd(aOut,{"�","\u00f4","o"})
	Aadd(aOut,{"�","\u00f5","o"})
	Aadd(aOut,{"�","\u00f6","o"})
	Aadd(aOut,{"�","\u00d3","o"})
	Aadd(aOut,{"�","\u00d2","o"})
	Aadd(aOut,{"�","\u00d4","o"})
	Aadd(aOut,{"�","\u00d5","o"})
	Aadd(aOut,{"�","\u00d6","o"})
	Aadd(aOut,{"�","\u00fa","u"})
	Aadd(aOut,{"�","\u00f9","u"})
	Aadd(aOut,{"�","\u00fb","u"})
	Aadd(aOut,{"�","\u00fc","u"})
	Aadd(aOut,{"�","\u00da","u"})
	Aadd(aOut,{"�","\u00d9","u"})
	Aadd(aOut,{"�","\u00db","u"})
	Aadd(aOut,{"�","\u00e7","c"})
	Aadd(aOut,{"�","\u00c7","c"})
	Aadd(aOut,{"�","\u00f1","n"})
	Aadd(aOut,{"�","\u00d1","n"})
	Aadd(aOut,{"&","\u0026"," "})
	Aadd(aOut,{"'","\u0027"," "})
	Aadd(aOut,{"�","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO

	Else
		cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut
