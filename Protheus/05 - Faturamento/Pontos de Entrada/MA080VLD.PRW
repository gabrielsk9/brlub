#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"

/*/{Protheus.doc} MA080VLD
Ponto de entrada p/envio workflow de altera��o de cadastro de tipos de entrada e saida TES
@type function
@version 1.00
@author Marcelo Alberto Lauschner
@since 03/11/2005
@return Logical, Retorna .t. / .f. se a inclus�o ou altera��o ser�o permitidas
/*/
User function MA080VLD()

	Local aCamp     := {}
	Local lContinua := .F.
	Local aFora     := {}
	Local x, nX

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	If !ALTERA .And. !INCLUI
		Return .T.
	Endif

	aFields := {}

	aFields := FWSX3Util():GetAllFields("SF4", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)
		cCampo := aFields[nx]
		If Ascan(aFora,Trim(GetSx3Cache(cCampo,"X3_CAMPO"))) <= 0
			Aadd(aCamp, { GetSx3Cache(cCampo,"X3_CAMPO"), GetSx3Cache(cCampo,"X3_TIPO"), GetSx3Cache(cCampo,"X3_TAMANHO"), GetSx3Cache(cCampo,"X3_DECIMAL"),GetSx3Cache(cCampo,"X3_TITULO") } )
		Endif		
	Next nX


	For x := 1 To Len(aCamp)

		If &("SF4->"+aCamp[x,1]) <> &("M->"+aCamp[x,1])
			lContinua := .T.
		Endif
	next

	If &("SF4->F4_CODIGO") <> &("M->F4_CODIGO")	// verifica se o c�digo do produto � diferente, pois ent�o � inclus�o.
		If !FwIsInCallStack("COPYSF4")
			Inc()  // chama workflow de inclus�o de produto
		Endif
		lContinua := .F.  // inativa workflow de altera��o de produto
		Return(.T.)
	Endif

	If lContinua

		If MsgYesno("Continua altera��o?","MA080VLD")

			cProcess := "100000"
			cStatus  := "100000"
			oProcess := TWFProcess():New(cProcess,OemToAnsi("Altera��o de cadastro de Tipos de Entrada e Sa�da"))

			//���������������������������������������������������������������������Ŀ
			//� Abre o HTML criado                                                  �
			//�����������������������������������������������������������������������
			If IsSrvUnix()
				If File("/workflow/tes_ma080vld.htm")
					oProcess:NewTask("Gerando HTML","/workflow/tes_ma080vld.htm")
				Else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "N�o localizou arquivo  /workflow/tes_ma080vld.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Return
				Endif
			Else
				oProcess:NewTask("Gerando HTML","\workflow\tes_ma080vld.htm")
			Endif

			oProcess:cSubject := "TES alterada-> "+AllTrim(SF4->F4_CODIGO)
			oProcess:bReturn  := ""
			oHTML := oProcess:oHTML



			For x := 1 To Len(aCamp)
				If &("SF4->"+aCamp[x,1]) <> &("M->"+aCamp[x,1])
					AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
					AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

					If aCamp[x,2] == "N"
						AAdd((oHtml:ValByName("p.orig")),Transform(&("SF4->"+aCamp[x,1]),"@E 999,999,999.99"))
						AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
					Else
						AAdd((oHtml:ValByName("p.orig")),&("SF4->"+aCamp[x,1]))
						AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
					Endif

				Endif
			next


			oHtml:ValByName("DATA",DTOC(dDataBase))
			oHtml:ValByName("HORA",Time())

			oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
			oProcess:cTo := "fiscal1@atrialub.com.br"

			oProcess:Start()
			oProcess:Finish()

			// For�a disparo dos e-mails pendentes do workflow
			WFSENDMAIL()


			Return(.T.)
		Endif
	Endif

Return (.F.)


/*/{Protheus.doc} Inc
Executa fun��o de envio de WF de inclus�o de TES
@type function
@version 1.00
@author Marcelo Alberto Lauschner
@since 31/03/2021
/*/
Static Function Inc()

	Local aCamp     := {}
	Local x,nX

	aFields := {}

	aFields := FWSX3Util():GetAllFields("SF4", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)
		cCampo := aFields[nx]
		Aadd(aCamp, { GetSx3Cache(cCampo,"X3_CAMPO"), GetSx3Cache(cCampo,"X3_TIPO"), GetSx3Cache(cCampo,"X3_TAMANHO"), GetSx3Cache(cCampo,"X3_DECIMAL"),GetSx3Cache(cCampo,"X3_TITULO") } )
	Next nX


	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclus�o de cadastro de produto."))

	//���������������������������������������������������������������������Ŀ
	//� Abre o HTML criado                                                  �
	//�����������������������������������������������������������������������
	If IsSrvUnix()
		If File("/workflow/tes_ma080vld.htm")
			oProcess:NewTask("Gerando HTML","/workflow/tes_ma080vld.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "N�o localizou arquivo  /workflow/tes_ma080vld.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\tes_ma080vld.htm")
	Endif


	oProcess:cSubject := "Cadastro de TES inclu�do -> "+M->F4_CODIGO
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
	oProcess:cTo := "fiscal1@atrialub.com.br"

	oProcess:Start()
	oProcess:Finish()

	// For�a disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return

