#Include 'Protheus.ch'


/*/{Protheus.doc} WFGERAL
//TODO Descri��o auto-gerada.
@author Iago Luiz Raimondi
@since 09/11/2018
@version 1.0
@return ${return}, ${return_description}
@param cEmail, characters, Destinat�rios
@param cTitulo, characters, T�tulo do Email
@param cTexto, characters, Corpo do e-mail
@param cRotina, characters, Nome da rotina que efetuou a chamada
@param cAnexo, characters, Nome do arquivo de anexo
@type function
/*/
User Function WFGERAL(cEmail,cTitulo,cTexto,cRotina,cAnexo)

	Local 	oHTML
	Local 	lRetorno := .F.
	Local	oProcess
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	Default cEmail 	:= "marcelo@centralxml.com.br;informatica1@atrialub.com.br"
	Default cTitulo := "Workflow Gen�rico"
	Default	cTexto	:= "Mensagem de workflow"
	Default cRotina := "WFGERAL"
	Default cAnexo	:= ""

	// Troca a quebra de linha CRLF para tag html 
	cTexto	:= StrTran(cTexto,CRLF,"<br>")

	// Cria um novo processo (inst�ncia do processo)
	oProcess := TWFProcess():New("000001",OemToAnsi("Workflow gen�rico"))

	//Abre o HTML criado
	If IsSrvUnix()
		If File("/workflow/wfgeral.htm")
			oProcess:NewTask("Gerando HTML","/workflow/wfgeral.htm")
		Else
			// ConOut("N�o localizou arquivo  /workflow/wfgeral.htm")
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "N�o localizou arquivo  /workflow/wfgeral.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\wfgeral.htm")
	Endif

	//define o assunto do email
	oProcess:cSubject 	:= cTitulo 
	oProcess:bReturn  	:= ""
	oProcess:bTimeOut	:= {}
	oProcess:fDesc 		:= cTitulo
	oProcess:ClientName(Substr(cUsuario,7,15))

	If !Empty(cAnexo)
		oProcess:AttachFile(cAnexo)
	EndIf

	//Come�o a preencher os valores do HTML. Inicialmente preencho o objeto
	oHTML := oProcess:oHTML
	oHTML:ValByName('CTITULO',ALLTRIM(cTitulo))
	oHTML:ValByName('CTEXTO',ALLTRIM(cTexto))
	oHTML:ValByName('CROTINA',ALLTRIM(cRotina))
	oProcess:cTo := U_BFFATM15(cEmail,cRotina)

	// Inicia o processo
	oProcess:Start()

	// FInaliza o processo
	oProcess:Finish()

	// For�a disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return

