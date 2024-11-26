#Include 'Protheus.ch'


/*/{Protheus.doc} BFCOMV01
(Valida digita��o de c�digo de Fornecedor )
@author MarceloLauschner
@since 26/04/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCOMV01()
	
	Local     	aAreaOld  	:= GetArea()
	Local     	lRet      	:= .T.
	Local     	nZ
	Local	   	cReadFor	:= ""
	Local		cSeqRead	:= "01"
	Local		cFileFor	:= "\profcustom\" + cNFiscal + cSerie + "_"+ cValToChar(ThreadID())+".txt"
	
	// Caso o arquivo n�o exista ou o c�digo de fornecedor n�o foi informado ainda
	If !File(cFileFor)
		MemoWrite(cFileFor,cSeqRead+cA100For+cLoja)
		cReadFor	:= cA100For+cLoja
	ElseIf Empty(cA100For+cLoja)
		MemoWrite(cFileFor,cSeqRead+cA100For+cLoja)
		cReadFor	:= cA100For+cLoja
	Else
		cReadFor	:= MemoRead(cFileFor)
		cSeqRead	:= Substr(cReadFor,1,2)
		cReadFor	:= Substr(cReadFor,3)
	Endif
	
	// Sequencia de leitura somente a partir da terceira vez pois a valida��o deve ser atribuida
	// para o campo F1_FORNECE e F1_LOJA no configurador U_VLDCHGF1
	If cSeqRead > "02" .And. cReadFor <> (cA100For+cLoja)
		If !IsBlind()
			MsgAlert("Voc� trocou o c�digo/loja do Fornecedor. Todas as linhas ser�o marcadas como 'deletadas' e voc� ter� que analisar todas novamente! ","Troca de Fornecedor/Loja")
		Endif
		For nZ := 1 To Len(aCols)
			aCols[nZ,Len(aHeader)+1] := .T.
		Next
	Endif
	
	MemoWrite(cFileFor,Soma1(cSeqRead)+cA100For+cLoja)
	
	RestArea(aAreaOld)
	
Return lRet


