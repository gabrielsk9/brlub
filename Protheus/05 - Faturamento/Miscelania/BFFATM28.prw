#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATM28
(Rotina que envia novo Link para aprovação da Diretoria quando da solicitação do Gerente)
@author MarceloLauschner
@since 18/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFFATM28()
	
	
	Local aOpenTable 	:= {"SC5","SA1","SC6","SB1","SA3","SZ9"}
	
	If Select("SM0") == 0
		
		RPCSetType(3)
		RPCSetEnv("02","01","tablet","imptablet","","",aOpenTable) // Abre todas as tabelas.
		Sleep(6000)
		sfExec()
		
		RpcClearEnv() // Limpa o environment
		RPCSetType(3)
		RPCSetEnv("02","04","tablet","imptablet","","",aOpenTable) // Abre todas as tabelas.
		Sleep(6000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		
		RPCSetType(3)
		RPCSetEnv("02","05","tablet","imptablet","","",aOpenTable) // Abre todas as tabelas.
		Sleep(6000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		
		RPCSetType(3)
		RPCSetEnv("02","07","tablet","imptablet","","",aOpenTable) // Abre todas as tabelas.
		Sleep(6000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		
		RPCSetType(3)
		RPCSetEnv("02","08","tablet","imptablet","","",aOpenTable) // Abre todas as tabelas.
		Sleep(6000)
		sfExec()
		RpcClearEnv() // Limpa o environment
	Else
		
		If !MsgNoYes("Deseja realmente importar??")
			Return
		Endif
		
		stImporta()
	Endif
	
Return


/*/{Protheus.doc} sfExec
(Executa a consulta das analises de alçadas pendentes )
@author MarceloLauschner
@since 18/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec()
	
	
	Local	cQry 	:= ""
	
	cQry := "SELECT Z9_DESCR,Z9_USER,Z9_ORIGEM,Z9_NUM,Z9_PRCRET,R_E_C_N_O_ Z9RECNO"
	cQry += "  FROM "+ RetSqlName("SZ9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND Z9_FILIAL = '" +xFilial("SZ9")+ "'"
	cQry += "   AND Z9_EVENTO IN('8','9')"
	cQry += "   AND Z9_PRCRET IN('A','D')"
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRZ9', .F., .T.)
	While !Eof()
		
		U_BFFATA30(.T./*lAuto*/,QRZ9->Z9_NUM/*cInPed*/,Iif(QRZ9->Z9_ORIGEM == "P",1,2)/*nInPedOrc*/,QRZ9->Z9_PRCRET,Padr(QRZ9->Z9_USER,6),QRZ9->Z9_DESCR)
		
		
		DbSelectArea("SZ9")
		DbGoto(QRZ9->Z9RECNO)
		RecLock("SZ9",.F.)
		SZ9->Z9_PRCRET	:= "S"
		MsUnlock()
		DbSelectArea("QRZ9")
		DbSkip()
	Enddo
	
	QRZ9->(DbCloseArea())
	
Return
