#include "protheus.ch"

/*/{Protheus.doc} GMTMKM01
(Analise de e-mail via valida��o em PHP)

@author MarceloLauschner
@since 29/01/2014
@version 1.0

@param cInEmail, character, (Descri��o do par�metro)
@param cInOldEmail, character, (Descri��o do par�metro)
@param cA1MSBLQL, character, (Descri��o do par�metro)
@param lValdAlcada, logico, (Descri��o do par�metro)
@param lExibeAlerta,logico, Se chamado por outras rotinas que ir�o exibir o alerta n�o exibe mensagens desta rotina
@return logico, Se validou ou n�o o e-mail

@example
(examples)

@see (links_or_references)
/*/
User Function GMTMKM01(cInEmail,cInOldEmail,cA1MSBLQL,lValdAlcada,lExibeAlerta,cInTxtPad)
	
	Local	cUrlValid			:= Alltrim(GetNewPar("BF_URLVLML",'https://app.verify-email.org/api/v1/Ov8yGlRE2P61gOUsUtXSkCCtAeKGdg4Ozutm3WCztbwZaGqB2B/verify/')) + Alltrim(cInEmail)
	Local	lRet				:= .T.
	Local	lVldEmail			:= .F.
	Local	cRetUrl				:= ""
	Local	aListMailBlq		:= {}
	Local	cTxtFalso			:= ""
	Local   iX
	Default	cA1MSBLQL			:= " "
	Default	lValdAlcada			:= .F.
	Default lExibeAlerta		:= .T.
	Default	cInTxtPad			:= ""
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	If Alltrim(Lower(GetEnvServer())) $ "desenvolvimento"
		Return lRet
	Endif
	
	// Se for Altera��o - Somente valida se o email alterou
	If !lVldEmail .And. Type("ALTERA") <> "U" .And. ALTERA
		If cInOldEmail <> cInEmail
			lVldEmail	:= .T.
		Endif
	Endif
	
	If !lVldEmail .And. Type("INCLUI") <> "U" .And. INCLUI
		lVldEmail	:= .T.
	Endif
	
	// Se for cliente bloqueado n�o precisa mais validar email
	If lVldEmail .And. cA1MSBLQL == "1"
		lVldEmail	:= .F.
	Endif
	
	// Se a rotina for externa de cadastros a chamada dever� sempre validar o e-mail
	If !lExibeAlerta
		lVldEmail	:= .T.
	Endif
	
	// Se valida o email, chama o Httpget
	If lVldEmail
		// Assume texto inicial
		cTxtFalso	:= cInTxtPad
		
		
		Aadd(aListMailBlq,"sheila.comrl@gmail.com")
		Aadd(aListMailBlq,"mah_bnu@yahoo.com.br")
		Aadd(aListMailBlq,"renano.bnu@gmail.com")
		Aadd(aListMailBlq,"minescblu@hotmail.com")
		Aadd(aListMailBlq,"nathybus@hotmail.com")
		Aadd(aListMailBlq,"mmayerbarbosa@gmail.com")
		Aadd(aListMailBlq,"cynarametzger@hotmail.com")
		Aadd(aListMailBlq,"gisele.netblumenau@hotmail.com")
		Aadd(aListMailBlq,"luisbrodzinski@hotmail.com")
		Aadd(aListMailBlq,"greice@hotmail.com")
		Aadd(aListMailBlq,"mah_bnu@yahoo.com.br")
		Aadd(aListMailBlq,"camilafischborn@hotmail.com")
		Aadd(aListMailBlq,"kiki_ap_92@hotmail.com")
		Aadd(aListMailBlq,"napoleao.texaco@gmail.com")
		Aadd(aListMailBlq,"adriana.janase@yahoo.com.br")
		Aadd(aListMailBlq,"claudineiklaumann@hotmail.com")
		Aadd(aListMailBlq,"regiane-psilva@hotmail.com")
		Aadd(aListMailBlq,"luribeiro1989@hotmail.com")
		Aadd(aListMailBlq,"larissamewes@hotmail.com")
		Aadd(aListMailBlq,"@bigforta.com.br")
		Aadd(aListMailBlq,"@llust.com.br")
		Aadd(aListMailBlq,"@atrialub.com.br")
		Aadd(aListMailBlq,"atrialub@gmail.comf")
		Aadd(aListMailBlq,"@xxx.com.br")
		Aadd(aListMailBlq,"@yyy.com.br")
		Aadd(aListMailBlq,"@zzz.com.br")
		Aadd(aListMailBlq,"@aaa.com.br")
		Aadd(aListMailBlq,"@bbb.com.br")
		Aadd(aListMailBlq,"@ccc.com.br")
		Aadd(aListMailBlq,"@ddd.com.br")
		
		For iX := 1 To Len(aListMailBlq)
			If aListMailBlq[iX] $ Alltrim(Lower(cInEmail))
				If lExibeAlerta
					MsgAlert("O e-mail informado '"+cInEmail+"' n�o foi validado pela rotina pois est� na lista de e-mails n�o permitidos!","EMAIL INFORMADO COM PROBLEMA!")
				Else
					cTxtFalso += "O e-mail informado '"+cInEmail+"' n�o foi validado pela rotina pois est� na lista de e-mails n�o permitidos!"+Chr(13)+Chr(10)
				Endif
				lRet	:= .F.
			Endif
		Next
		
		// For�a verifica��o do e-mail pela fun��o padr�o Totvs - http://tdn.totvs.com/display/tec/ISEMAIL
		If !IsEmail(Lower(Alltrim(cInEmail)))
			lRet 	:= .F.
			If lExibeAlerta
				MsgAlert("O e-mail informado '"+cInEmail+"' n�o foi validado pela rotina por n�o estar no padr�o de formato de e-mail permitido.","EMAIL INFORMADO COM PROBLEMA!")
			Else
				cTxtFalso += "O e-mail informado '"+cInEmail+"' n�o foi validado pela rotina por n�o estar no padr�o de formato de e-mail permitido."
			Endif
		Endif
		
		If lRet
			// Se a verifica��o n�o vier da liber��o de al�adas e rotinas externas de cadastros
			If !lValdAlcada	.And. lExibeAlerta				
				Processa( {|| cRetUrl := Alltrim(HttpGet(cUrlValid)) },"Aguarde... Validando E-mail")
				If '"credits":0' $ cRetUrl 
					lRet	:= .T. 
				ElseIf '"status":1' $ cRetUrl .And. '"smtp_log":"Success"' $ cRetUrl
					lRet	:= .T.
				ElseIf '"smtp_log":"MailboxDoesNotExist"' $ cRetUrl 
					If !IsBlind()
						lRet := MsgNoYes("O e-mail informado '"+cInEmail+"' n�o existe! Favor verificar se est� correto! Deseja confirmar assim mesmo?","EMAIL INFORMADO COM PROBLEMA!")
					Else
						lRet := .T.
					EndIf										
				
				Else
					// IAGO 28/03/2016 Ajuste para nao validar no job.
					If !isBlind()
						lRet := MsgNoYes("O e-mail informado '"+cInEmail+"' n�o foi validado pela rotina! Favor verificar se est� correto! Deseja confirmar assim mesmo?","EMAIL INFORMADO COM PROBLEMA!")
					Else
						lRet := .T.
					EndIf										
				Endif
			Endif
		Endif
		
	Endif
	
Return lRet


/*/{Protheus.doc} GMTMKM02
(Efetua valida��o via Thread do email em p�gina PHP)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@param cEmp, character, (Descri��o do par�metro)
@param cFil, character, (Descri��o do par�metro)
@param cUrlValid, character, (Descri��o do par�metro)
@param cTxtFalso, character, (Descri��o do par�metro)
@param cInMail, character, (Descri��o do par�metro)
@param cMails, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMTMKM02(cEmp,cFil,cUrlValid,cTxtFalso,cInMail,cMails)
	
	// Seta job para nao consumir licensas
	RpcSetType(3)
	// Seta job para empresa filial desejada
	RpcSetEnv( cEmp, cFil,,,)
	
	If Alltrim(HttpGet(cUrlValid)) <> "1"
		U_WFGERAL(cMails,;
			"E-mail '"+Alltrim(cInMail)+"'n�o validado em autentica��o de provedor",;
			cTxtFalso)
	Endif
	
Return
