#INCLUDE "PROTHEUS.CH"
#INCLUDE "topconn.ch"
#INCLUDE "AP5MAIL.CH"
      
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �TMKCFIM   �Autor  �Marcelo Lauschner   � Data �  07/07/11   ���
�������������������������������������������������������������������������͹��
���Desc.     �Ponto de Entrada ao Finalizar Telecobran�a                  ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

// Fun��o de Ponto de Entrada ap�s gravar o atendimento TElecobran�a
//U_TMKCFIM(M->ACF_CODIGO)
User Function TMKCFIM(cInCodigoACF)
	Local 	iW 
	Local	lContinua	:= .F.
	Private	oCbSituacao,oDlg1,oDtRetorno,oDtDeposito
	Private	dDtRetorno	:= CTOD("  /  /  ")
	Private	dDtDeposito	:= CTOD("  /  /  ")
	Private	cComb	:= aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})]

// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Informa��es adicionais para Finaliza��o do Atendimento de Cobran�a") From 000,000 to 220,500 of oMainWnd PIXEL
         
	@ 005,005 To 095,248 of oDlg1 Pixel
	@ 017,015 Say "Informe uma Situa��o" of oDlg1 Pixel
	@ 015,075 Combobox oCbSituacao Var cComb ITEMS {"1=Serasa","2=Inad.Nova","3=Retornar Liga��o","4=Novo c/Hist�rico","5=Cart�rio","6=Agendado Dep�sito","7=Protestado","8=Sem Status"} Valid sfCbox() of oDlg1 Pixel Size 80,11
	@ 032,015 Say "Data Retorno" of oDlg1 Pixel
	@ 030,075 Msget oDtRetorno Var dDtRetorno Size 040,11 of oDlg1 Pixel
	oDtRetorno:Disable()
	@ 047,015 Say "Agendado Dep�sito" of oDlg1 Pixel
	@ 045,075 Msget oDtDeposito Var dDtDeposito  Size 040,11 of oDlg1 Pixel
	oDtDeposito:Disable()
	@ 097,050 BUTTON "&Grava"  of oDlg1 pixel SIZE 60,12 ACTION (IIf(sfVld(),(lContinua := .T.,oDlg1:End())	,MsgAlert("Inconsist�ncia","TMKCFIM.prw")))
	@ 097,120 BUTTON "&Cancela" of oDlg1 pixel SIZE 60,12 ACTION (MsgAlert("Nenhum Status ser� salvo para o cliente e os t�tulos!","A T E N � � O!!"), oDlg1:End() )

	ACTIVATE MSDIALOG oDlg1 CENTERED


	If lContinua

		U_MLDBSLCT("CONDORTMKC",.F.,1)
		If DbSeek(cEmpAnt+xFilial("SA1")+M->ACF_CLIENT+M->ACF_LOJA)
			RecLock("CONDORTMKC",.F.)
			CONDORTMKC->CTC_ULTACF	:= dDataBase
			CONDORTMKC->CTC_RETORN	:= dDtRetorno
			CONDORTMKC->CTC_AGEDEP	:= dDtDeposito
			CONDORTMKC->CTC_STATUS	:= cComb
			MsUnlock()
		Endif
		cMensagem	:= ""
	
		For iW := 1 To Len(aCols)
			DbSelectArea("SK1")
			DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
			If DbSeek(xFilial("SK1")+aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_FILORI"})])
			
		 	// Efetuo a verifiaca��o se h� titulo marcado para Serasa e valida se n�o estava marcado ainda
				If aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})] $ "1" .And. SK1->K1_XSTATUS # "1"
					RecLock("CONDORTMKC",.F.)
					CONDORTMKC->CTC_DTSERA	:= dDataBase
					CONDORTMKC->CTC_NSERAS	+= 1
					MsUnlock()
				Endif

			// Efetuo verifica��o se h� titulo marcado para ser enviado para Cartorio
				If aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})] $ "5" .And. SK1->K1_XSTATUS # "5" // Enviado Cartorio e se o Status do Titulo ainda n�o era de Cartorio
					If Empty(cMensagem)
						cMensagem	+= "Empresa  :"+Capital(SM0->M0_NOMECOM)
						cMensagem 	+= Chr(13)+Chr(10)
						cMensagem	+= "Solicita��o feita pelo Atendimento Telecobran�a N� :"+M->ACF_CODIGO
						cMensagem 	+= Chr(13)+Chr(10)
						cMensagem	+= "Operador Microsiga:"+cUserName
						cMensagem 	+= Chr(13)+Chr(10)
					Endif
					cMensagem	+= "Titulo: Prefixo/N�mero/Parcela/Tipo: "+	aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+ "/"+ ;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+"/"+;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+"/"+;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})]
								 
					cMensagem 	+= Chr(13)+Chr(10)
					DbSelectArea("SE1")
					DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
					If DbSeek(xFilial("SE1")+aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})])
						cE1_HIST	:= SE1->E1_HIST
						RecLock("SE1",.F.)
						SE1->E1_HIST	:= Substr("Solicitado Cart�rio Via Telecobran�a N�:"+M->ACF_CODIGO+" em:"+DTOC(dDataBase) +"|"+cE1_HIST,1,Len(SE1->E1_HIST))
						MsUnlock()
						If Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_HIST"}) > 0
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_HIST"})]	:= SE1->E1_HIST
						Endif
					Endif
				Endif
				DbSelectArea("SK1")
				RecLock("SK1",.F.)
				SK1->K1_XSTATUS	:= aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})]
				MsUnlock()
			
			Endif
		Next
		If !Empty(cMensagem)
			cRecebe		:= UsrRetMail(__cUserId)
			cAssunto 	:= "Envio de T�tulos para Cart�rio do Cliente '"+M->ACF_CLIENT+"/"+M->ACF_LOJA+" " +Alltrim(Posicione("SA1",1,xFilial("SA1")+M->ACF_CLIENT+M->ACF_LOJA,"A1_NOME"))
			stSendMail( cRecebe, cAssunto, cMensagem )
		Endif
	
	Endif
   

Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome fun��o: sfVld
// Parametros : 
// Objetivo   : Valido as datas do Dialog ao encerrar atendimento, impedindo que a data 
//				agendada seja menor que a atual
// Retorno    : 
// Altera��es : 
//---------------------------------------------------------------------------------------
Static Function sfVld()

	If cComb == "6"
		Return dDtDeposito >= dDataBase
	Elseif cComb	== "3"
		Return dDtRetorno  >= dDataBase
	Endif

Return .T.


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome fun��o: sfCbox
// Parametros : 
// Objetivo   : Valido o Foco dos Gets de data conforme op��o do Combobox
// Retorno    : 
// Altera��es : 
//---------------------------------------------------------------------------------------
Static Function sfCbox()
                    
// Desabilito os dois campos de data
	oDtDeposito:Disable()
	dDtDeposito	:= CTOD("  /  /  ")
	oDtDeposito:Refresh()
	oDtRetorno:Disable()
	dDtRetorno	:= CTOD("  /  /  ")
	oDtRetorno:Refresh()

// Somente habilito os campos de data conforme sele��o
	If cComb == "6"
		oDtDeposito:Enable()
		oDtDeposito:SetFocus()
	Elseif cComb	== "3"
		oDtRetorno:Enable()
		oDtRetorno:SetFocus()
	Endif

Return .T.


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome fun��o: stSendMail
// Parametros : cRecebe,cAssunto,cMensagem
// Objetivo   : Efetua envio de email (No caso de T�tulos para Cartorio)
// Retorno    : 
// Altera��es : 
//---------------------------------------------------------------------------------------
Static Function stSendMail( cMailTo, cAssunto, cMensagem)

	Local	aAreaOld 		:= GetArea()
	Local 	lOk 		:= .F.
	Local	lAutOk 		:= .F.
	Local	lSendOk 	:= .T.

	Local cMailServer := AllTrim(GetNewPar("MV_RELSERV"," "))        // Servidor utilizado para envio do e-mail
	Local cMailConta  := AllTrim(GetNewPar("MV_RELACNT"," "))        // Conta utilizada para envio
	Local cMailSenha  := AllTrim(GetNewPar("MV_RELPSW" ," "))        // Senha da conta de envio
	Local lSmtpAuth   := GetNewPar("MV_RELAUTH", .F.)                // Verifica se deve realizar autentica��o
	Local nTimeOut    := GetNewPar("MV_RELTIME", 120)                // Tempo de Espera antes de abortar a Conex�o
	Local cUserAut    := Alltrim(GetNewPar("MV_RELAUSR",cMailConta)) // Usu�rio para Autentica��o no Servidor de Email
	Local cSenhAut    := Alltrim(GetNewPar("MV_RELAPSW",cMailSenha)) // Senha para Autentica��o no Servidor de Email
	Local lRetMail 		:= .T.

	// Campos a serem repassados no e-mail
	Default cMailTo   := Space(20)
	Default cAssunto  := Space(20)
	Default cMensagem := Space(20)

	cMailTo := cMailTo //U_BFFATM15(cMailTo,"BIG005")


	CONNECT SMTP SERVER cMailServer ACCOUNT cMailConta PASSWORD cMailSenha TIMEOUT nTimeOut RESULT lOk

// Valida existencia de campos necessarios para o envio do e-mail
	If !Empty(cMailServer) .And. !Empty(cMailConta)
		// Verifica autentica��o no servidor descrito, se necessario
		If !lAutOk
			If lSmtpAuth
				If !(lAutOk := MailAuth(cUserAut,cSenhAut))
					cMsgSend := "Falha na autentica��o do usu�rio no provedor de e-mail"
					lRetMail := .F.
				Endif
			Else
				lAutOk := .T.
			EndIf
		EndIf

		If lRetMail // Caso a autentica��o tenha sido efetuada corretamente.
			If lOk  // Caso a conexao com o servidor, esteja estabelecida, e possibilite o envio do e-mail
				SEND MAIL FROM cMailConta TO cMailTo SUBJECT cAssunto BODY cMensagem RESULT lSendOk  // Efetua envio do e-mail

				If !lSendOk
					Get MAIL ERROR cError // Verifica erro indicado pelo servidor, no ato do envio do e-mail
				Endif

				// Armazena informa��es para retorno
				cMsgSend := If(lSendOk, "E-mail enviado com sucesso!", cError) // "E-mail enviado com sucesso!"
				lRetMail := lSendOk
			Else
				cMsgSend := "Erro na conex�o com o servidor SMTP." + CHR(13) + CHR(10) + ; // "Erro na conex�o com o servidor SMTP."
				"Verifique configura��es e autentica��es do servidor de e-mail." // "Verifique configura��es e autentica��es do servidor de e-mail."
				lRetMail := .F.
			EndIf
		Endif

		DISCONNECT SMTP SERVER // Finaliza conexao com servidor de e-mail
	Else
		cMsgSend := "As configura��es para o acesso ao servidor de e-mail est�o incorretas." + CHR(13) + CHR(10) + ; // "As configura��es para o acesso ao servidor de e-mail est�o incorretas."
		"Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW" // "Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW"
		lRetMail := .F.
	EndIf

	RestArea(aAreaOld)

Return
