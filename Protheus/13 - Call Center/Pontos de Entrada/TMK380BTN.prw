#Include 'Protheus.ch'

User Function TMK380BTN()
	
	Local	aBtnUser	:= {}
	
	//aUserBtn := U_TMK380BTN()
	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴커
	//쿑ormato do Array de Retorno.�
	//�                            �
	//쿪UserBtn[nBtn,1]  RESOURCE  �
	//쿪UserBtn[nBtn,2]  ACTION    �
	//쿪UserBtn[nBtn,3]  TOOLTIP   �
	//쿪UserBtn[nBtn,4]  CTITLE    �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴켸
	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	//쿔nsere botoes de usuario na barra de ferramentas.�
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	//If ValType(aUserBtn) == "A"
	//	If Len(aUserBtn) > 0
	//		For nBtn := 1 To Len(aUserBtn)
	//			AAdd(aButtons,{ aUserBtn[nBtn][1],	&( "aUserBtn["+STRZERO(nBtn,2)+"][2]"),aUserBtn[nBtn][3],aUserBtn[nBtn][4]})
	//			//AAdd(aButtons,&("{ aUserBtn["+Str(nBtn)+"][1],	{|| aUserBtn["+STRZERO(nBtn,2)+"][2]},aUserBtn["+Str(nBtn)+"][3],aUserBtn["+Str(nBtn)+"][4]}"))
	//		Next nBtn
	//	EndIf
	//EndIf
	
	Aadd(aBtnUser,{"AMARELO"		,{|| sfHist()	},"Hist�rico","Hist�rico"})
	
	
Return aBtnUser



Static Function sfHist()
	
	Local	aAreaOld	:= GetArea()
	Local	cCliEnt		:= Substr(oGetDados:aCols[oGetDados:nAt,aScan(oGetDados:aHeader,{|x| Alltrim(x[2]) == "U6_CODENT"})],1,TamSX3("A1_COD")[1])
	Local	cLojEnt		:= Substr(oGetDados:aCols[oGetDados:nAt,aScan(oGetDados:aHeader,{|x| Alltrim(x[2]) == "U6_CODENT"})],TamSX3("A1_COD")[1]+1,TamSX3("A1_LOJA")[1])
	
	U_BIG0381(cCliEnt,cLojEnt)
	
	RestArea(aAreaOld)
	
Return
