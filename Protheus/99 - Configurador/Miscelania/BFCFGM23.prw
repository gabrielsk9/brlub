#Include 'Protheus.ch'

/*/{Protheus.doc} BFCFGM23
(Rotina gen�rica para controle de semaforo)
@type function
@author Iago Luiz Raimondi
@since 05/04/2017
@version 1.0
@param lLock, boolean, (Reserva ou Libera)
@param cKey, character, (Chave para cria��o do semaforo)
@param cMsg, character, (Mensagem � ser apresentada quando n�o conseguir reservar)
@return ${return}, ${return_description}
@example (examples)
@see (links_or_references)
/*/
User Function BFCFGM23(lLock,cKey,cMsg,lTrvEmp,lTrvFil,lExeAuto)

	Local	nTentativas	:= 0
	
	Default lLock		:= .F.
	Default cKey 		:= "BFCFGM23"
	Default cMsg		:= "Aguarde, arquivo sendo alterado por outro usu�rio."
	Default	lTrvEmp		:= .F.
	Default lTrvFil		:= .F. 
	Default lExeAuto	:= .F. 
	
	If lLock
		While !LockByName(cKey,lTrvEmp,lTrvFil,.T.)
			If lExeAuto
				Sleep(1000)
			Else
				MsAguarde({|| Sleep(1000) }, "Semaforo de processamento... tentativa "+AllTrim(Str(nTentativas)), cMsg)
			Endif
			nTentativas++
			
			If nTentativas > 5
				If !lExeAuto .And. MsgYesNo("N�o foi poss�vel acesso exclusivo � rotina. Deseja tentar novamente ?")
					nTentativas := 0
					Loop
				Else
					Return .F.
				EndIf
			EndIf
		EndDo
		
	Else
		UnLockByName(cKey,lTrvEmp,lTrvFil,.T.)
	Endif

Return .T.

