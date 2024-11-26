#INCLUDE "totvs.ch"


User Function CALLFUNC()


	/*
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	�������������������������������������������������������������������������ͻ��
	���Programa  �CALLFUNC  �Autor  �Marcelo Alberto Lauschner Data �03/02/06 ���
	�������������������������������������������������������������������������͹��
	���Desc.     �Dialog que onde digita qualquer funcao sem precisar chamar  ���
	���          �o menu, basta digitar o nome da fun��o que o programa abre  ���
	�������������������������������������������������������������������������͹��
	���Uso       � AP                                                        ���
	�������������������������������������������������������������������������ͼ��
	�����������������������������������������������������������������������������
	�����������������������������������������������������������������������������
	*/


	Private cFunc := Space(50)
	Private cProg := Space(10)
	Private cForm := space(32655)
	Private aTabelas := {"SC5","SA1","SB1","SC6","DA1","DA0","SX1","SX2","SX3"}


	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Digite o nome da Fun��o") From 000,000 to 260,500 of oMainWnd PIXEL

	@ 005,005 To 120,245 of oDlg1 Pixel
	@ 008,010 Say "Fun��o de Usu�rio" of oDlg1 Pixel
	@ 007,080 Msget oFunc Var cfunc Size 050,11 of oDlg1 Pixel

	@ 023,010 Say "Programa Padr�o" of oDlg1 Pixel
	@ 022,080 Msget oProc Var cProg  Size 050,11 of oDlg1 Pixel
	
	@ 024,145 Say "Appserver.ini= SE��O;CHAVE;VALOR;" of oDlg1 Pixel
	
	@ 038,010 Say "Express�o Advpl/SQL/Ini" of oDlg1 Pixel
	@ 037,080 Get oObserv Var cForm of oDlg1 MEMO Size 160,70 Pixel

	@ 050,010 BUTTON "&Executar"  of oDlg1 pixel SIZE 60,12 ACTION (ExecFun())
	@ 065,010 BUTTON "&SQL Exec"  of oDlg1 pixel SIZE 60,12 ACTION (ExecSql())
	@ 080,010 BUTTON "&Appserver.Ini"  of oDlg1 pixel SIZE 60,12 ACTION (ExecAppIni())
	@ 095,010 BUTTON "&Cancela" of oDlg1 pixel SIZE 60,12 ACTION oDlg1:End()

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return


Static Function  ExecFun()


	If !Empty(cFunc)
		If !Empty(cProg)
			MsgInfo("Somente uma fun��o pode ser executada por vez","Erro ")
			Return
		Endif
		
		If FindFunction(("U_"+StrTran(StrTran(cfunc,"(",""),")","")))
			&("U_"+cfunc+IIf(At("(",cFunc)==0,"()",""))
		Else 
			MsgAlert("Fun��o de usu�rio '"+cfunc+"' n�o encontrada no reposit�rio","FindFunction sem retorno")
		Endif 
	Endif

	If !Empty(cProg)
		If FindFunction(cProg)
			&(cProg+"()")
		Else
			MsgAlert("Fun��o de sistema n�o encontrada no reposit�rio!","FindFunction sem retorno")
		Endif 
	Endif

	If !Empty(cForm)
		fExecuta()
	Endif

Return
Static Function ExecAppIni()

	Local aArea    := GetArea()
	Local cError   := ""
	Local bError   := ErrorBlock({ |oError| cError := oError:Description})
	Local cConteudo 	
	Local cSecao
	Local cChvSec
	Local cNewValue		
	Local cEnv       	:=  GetAdv97()
	Local aChvIni 		:= {} 

	//Se tiver conte�do digitado
	If ! Empty(cForm)
		//Inicio a utiliza��o da tentativa
		Begin Sequence
			aChvIni		:= StrTokArr(cForm,";")
			cSecao		:= aChvIni[1]		
			cChvSec		:= aChvIni[2]
			cNewValue	:= aChvIni[3]

			cConteudo       := GetPvProfString(cSecao,cChvSec,"ERROR",cEnv)
			If ('ERROR' $ Upper(cConteudo) ) .Or. (Alltrim(cConteudo) <> Alltrim(cNewValue) .And. MsgYesNo("Deseja alterar a chave? De:"+cConteudo+" Para:"+cNewValue))
				U_MLFWLMSG("Configura��o Se��o: '"+cSecao+"' Chave: '"+cChvSec+"' Incompleta")
				If !MsgYesNo("Deseja configurar? " + CRLF+"Se��o ["+cSecao+"] " + CRLF + "Chave:"+ cChvSec + CRLF + "Valor:"+cNewValue,"Configura��o de Chave")
					Return .F.
				Else
					WritePProString (cSecao/*cSecao*/, cChvSec/*cChave*/, cNewValue/*cConteudo*/,cEnv/* "appserver.ini" *//*cArqIni*/ )
				Endif
			Endif
		End Sequence

		//Restaurando bloco de erro do sistema
		ErrorBlock(bError)

		//Se houve erro, ser� mostrado ao usu�rio
		If ! Empty(cError)
			MsgStop("Houve um erro na f�rmula digitada: "+CRLF+CRLF+cError, "Aten��o")
		EndIf
	EndIf

	RestArea(aArea)


Return

Static Function ExecSql()

	Local aArea    := GetArea()
	Local cError   := ""
	Local bError   := ErrorBlock({ |oError| cError := oError:Description})
	Local nret

	//Se tiver conte�do digitado
	If ! Empty(cForm)
		//Inicio a utiliza��o da tentativa
		Begin Sequence
			nret :=    TcSqlExec(cForm)
		End Sequence
		MsgAlert(TCSQLERROR(),"Retorno" + cValToChar(nRet))

		//Restaurando bloco de erro do sistema
		ErrorBlock(bError)

		//Se houve erro, ser� mostrado ao usu�rio
		If ! Empty(cError)
			MsgStop("Houve um erro na f�rmula digitada: "+CRLF+CRLF+cError, "Aten��o")
		EndIf
	EndIf

	RestArea(aArea)

Return

Static Function fExecuta()

	Local aArea    := GetArea()
	Local cFormula := Alltrim(cForm)
	Local cError   := ""
	Local bError   := ErrorBlock({ |oError| cError := oError:Description})

	//Se tiver conte�do digitado
	If ! Empty(cFormula)
		//Inicio a utiliza��o da tentativa
		Begin Sequence
			&(cFormula)
		End Sequence

		//Restaurando bloco de erro do sistema
		ErrorBlock(bError)

		//Se houve erro, ser� mostrado ao usu�rio
		If ! Empty(cError)
			MsgStop("Houve um erro na f�rmula digitada: "+CRLF+CRLF+cError, "Aten��o")
		EndIf
	EndIf

	RestArea(aArea)
Return



