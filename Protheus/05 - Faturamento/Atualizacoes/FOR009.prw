#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} FOR009
// Rotina de Cadastro de Tampinhas 
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return Nil
@type User Function
/*/
User Function FOR009()

	//AxCadastro("SZ8","Cadastro de Pre�o de Tampas.",,"U_SZ8TudOk()")

	Local aRotAdic 	:={}  //Array contendo as rotinas adicionais para ser acrescentado ao array aRotina.
	Local cDel		:= "" //"U_SZ8TudOk()" //Fun��o a ser executada ao deletar o registro.
	Local cTudoOk	:= "U_SZ8TudOk()" // Fun��o a ser executada ao clicar no bot�o OK para gravar o registro(inclus�o e altera��o).
	Local bPre 		:= {||MsgAlert('Chamada antes da fun��o')} //Codeblock a ser executado antes da abertura do di�logo de inclus�o, altera��o ou exclus�o.
	Local bOK  		:= {||MsgAlert('Chamada ao clicar em OK'), .T.} // Codeblock a ser executado ao clicar no bot�o OK do di�logo de inclus�o, altera��o ou exclus�o.
	Local bTTS  	:= {||MsgAlert('Chamada durante transacao')} // Codeblock a ser executado durante a transa��o de inclus�o, altera��o ou exclus�o.
	Local bNoTTS  	:= {||MsgAlert('Chamada ap�s transacao')}    // Codeblock a ser executado ap�s a transa��o de inclus�o, altera��o ou exclus�o.
	Local aAuto		:= {} //Array com os campos a serem considerados pela rotina autom�tica.
	Local nOpcAuto	:= 3 //Numero da op��o selecionada (Inclus�o, Altera��o, Exclus�o, Visualiza��o) para a rotina autom�tica.
	Local aButtons 	:= {}	//adiciona bot�es na tela de inclus�o, altera��o, visualiza��o e exclusao Array contendo os bot�es da EnchoiceBar com a seguinte estrutura: aButtons[1][1] � Nome do arquivo da imagem do bot�o.aButtons[1][2] � Bloco de execu��o.aButtons[1][3] � Mensagem de exibi��o no ToolTip.aButtons[1][4] � Nome do bot�o.

	Local aCores 		:= {;
	{"'REGISTRO DUPLICADO' $ Z8_OBS" ,'BR_PRETO' },;
	{"Z8_DATFIM < dDataBase" ,'BR_VERMELHO' },;
	{"Z8_DATFIM > dDataBase .And. Z8_DATCAD > dDataBase " ,'BR_AZUL'},;
	{"Z8_DATFIM >= dDataBase .And. Z8_DATCAD <= dDataBase " ,'BR_VERDE'}}

	Private aRotina := { {"Pesquisar","AxPesqui",0,1 } ,;
	{"Visualizar","AxVisual",0,2} ,;
	{"Incluir","U_FOR009X1(3)",0,3   } ,;
	{"Alterar","U_FOR009X1(4)",0,4   } ,;
	{"Replicar Cadastro","U_FOR009B",0,4},;
	{"Legenda","StaticCall(FOR009,sfLegenda)",0,2}}

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()


	//Aadd(aButtons,{ "PRODUTO", {|| MsgAlert("Teste")}, "Teste", "Bot�o Teste" }  ) //adiciona chamada no aRotina

	//Aadd(aRotAdic,{ "Replicar Cadastro","U_FOR009B", 0 , 3 })
	//Aadd(aRotAdic,{ "Legenda"          ,"StaticCall(FOR009,sfLegenda)", 0 , 6})

	//AxCadastro("SZ8", "Cadastro de Pre�o de Tampas", /*cDel*/ , cTudoOk, aRotAdic, /*bPre*/, /*bOK*/, /*bTTS*/, /*bNoTTS*/, , , aButtons, , )  


	Private cString 	:= "SZ8"
	Private cCadastro	:= "Cadastro de Pre�o de Tampas"
	
	
	dbSelectArea("SZ8")
	dbSetOrder(1)   
	
	mBrowse( 6,1,22,75,cString,,,,,6,aCores)
	
	// Faz o Checklist 
	sfChekDupl()
	

Return

User Function FOR009X1(nOpc)

	If nOpc == 3
		nOpcA 	:= AxInclui("SZ8",0,3,,,,"U_SZ8TudOk()")
	Elseif nOpc == 4
		AxAltera("SZ8",SZ8->(Recno()),4,,,,,"U_SZ8TudOk()")
		
	ElseIf nOpc == 5
		AxDeleta("SZ8",SZ8->(Recno()), 5)
	Endif
Return 

	

Static Function sfLegenda()

	BrwLegenda("Cadastro de Pre�os de Tampas",'Legenda',;
	{{"BR_VERDE"   ,'Cadastro Vigente'},;
	{"BR_VERMELHO" ,'Vig�ncia Encerrada' },;
	{"BR_PRETO"    ,'Vig�ncia Duplicada' },;
	{"BR_AZUL"     ,'Vig�ncia Futura'} })

Return 


Static Function sfChekDupl()

	Local	lExist		:= .F. 
	Local	cQry 		:= ""
	Local	aAreaOld	:= GetArea()
	
	cQry := "SELECT A.R_E_C_N_O_ Z8RECNO "
	cQry += "  FROM " + RetSqlName("SZ8") + " A "
	cQry += " WHERE D_E_L_E_T_ =' ' 
	cQry += "   AND A.Z8_FILIAL = '" + xFilial("SZ8") + "'"
	cQry += "   AND Z8_CLIENTE NOT IN('PADR3','PADR6','PADR2','PADR4','PADR1')
	cQry += "   AND EXISTS (SELECT R_E_C_N_O_ 
	cQry += "				  FROM " + RetSqlName("SZ8") + " B "
	cQry += "				 WHERE B.D_E_L_E_T_ =' '
	cQry += "                  AND B.R_E_C_N_O_ <>  A.R_E_C_N_O_ 
	cQry += "                  AND B.Z8_CODPROD = A.Z8_CODPROD
	cQry += "                  AND B.Z8_CLIENTE = A.Z8_CLIENTE
	cQry += "                  AND B.Z8_LOJA = A.Z8_LOJA
	cQry += "				   AND B.Z8_FILIAL = A.Z8_FILIAL
	cQry += "                  AND B.Z8_DATCAD < A.Z8_DATFIM
	cQry += "                  AND B.Z8_FILIAL = '" + xFilial("SZ8") + "'"
	cQry += "                  AND B.Z8_DATFIM > A.Z8_DATCAD)

	TcQuery cQry Alias "QRZ8"

	While !Eof()
		DbSelectArea("SZ8")
		DbGoto(QRZ8->Z8RECNO)
		RecLock("SZ8",.F.)
		SZ8->Z8_OBS 	:= "REGISTRO DUPLICADO "
		MsUnlock()
		lExist		:= .T.
		MsgInfo("Registro Duplicado - " + SZ8->Z8_CLIENTE + "/" + SZ8->Z8_LOJA + " " + SZ8->Z8_CODPROD)
		DbSelectArea("QRZ8")
		QRZ8->(DbSkip())
	Enddo
	QRZ8->(DbCloseArea()) 
	
	RestArea(aAreaOld)

Return lExist
