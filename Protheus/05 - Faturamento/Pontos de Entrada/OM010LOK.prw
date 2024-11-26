#Include 'Protheus.ch'

/*/{Protheus.doc} OM010LOK
(Ponto de entrada de valida��o de linha da tela de cadastro de pre�os de vendas)
@type User Function
@author Marcelo Alberto Lauschner
@since 18/12/2016
@version 1.0
@return lRet, Logical
@example
(examples)
@see (links_or_references)
/*/
User Function OM010LOK()

	Local lRet  	:= .T.
	Local aArea 	:= GetArea()
	Local aAreaDA0 	:= DA0->(GetArea())
	Local nPosProd	:= 0
	Local nPosRegBo	:= 0
	Local nUsado	:= 0
	Local cRegBon	:= ""
	Local cPrdAux	:= ""
	Local lExcluido	:= .F. 

	// Verifica se o campo existe na empresa para n�o validar o processo customizado abaixo
	If DA1->(FieldPos("DA1_XREGBO")) <= 0
		RestArea(aAreaDA0)
		RestArea(aArea)
		Return(lRet)
	Endif

	If MV_PAR01 == 2 // Por Produto
		// Verifica se � Protheus 12 - MVC 
		If GETVERSAO(.F.)>="12"
			oModelx 	:= FWModelActive()//->Carregando Model Ativo
			oModelxDet 	:= oModelx:GetModel('DA1DETAIL') //Carregando grid de dados a partir o ID que foi instanciado no fonte.
			cRegBon 	:= oModelxDet:GetValue('DA1_XREGBO')//Utilizando fun��o para atribuir valor ao campo em tempo de execu��o
			lExcluido	:= oModelxDet:IsDeleted()
		Else
			nPosRegBo	:= aScan(aHeader,{|x|AllTrim(x[2])=="DA1_XREGBO"})	 //Regra de Bonifica��o
			nUsado		:= Len(aHeader)
			cRegBon 	:= aCols[n][nPosRegBo]
			lExcluido	:= 	aCols[n][nUsado+1]			
		Endif		
		cPrdAux	:= MV_PAR02

		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+cPrdAux)
			If Substr(SB1->B1_COD,1,3) == "CB-" .And. SB1->B1_UM == "KT"


				If !lExcluido// !aCols[n][nUsado+1]
					// Verifica se a correla��o de fato j� est� cadastrada
					DbSelectArea("ACQ")
					DbSetOrder(3) // ACQ_FILIAL+ACQ_CODTAB+ACQ_CODPRO+ACQ_CODREG
					If DbSeek(xFilial("ACQ")+Padr(" ",Len(ACQ->ACQ_CODTAB))+SB1->B1_COD+cRegBon)

					Else
						MsgStop("Para o produto '" + Alltrim(SB1->B1_COD) + " " + Alltrim(SB1->B1_DESC) + " n�o h� regra de Combo cadastrada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						lRet	:= .F.
					EndIf
				Endif
			Endif
		Endif
	Else	
		nPosProd	:= aScan(aHeader,{|x|AllTrim(x[2])=="DA1_CODPRO"})	 // C�digo do Produto
		nPosRegBo	:= aScan(aHeader,{|x|AllTrim(x[2])=="DA1_XREGBO"})	 //Regra de Bonifica��o
		nUsado		:= Len(aHeader)
		If !aCols[n][nUsado+1]
			cPrdAux	:= aCols[n][nPosProd]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+cPrdAux)
				If Substr(SB1->B1_COD,1,3) == "CB-" .And. SB1->B1_UM == "KT"
					cRegBon := aCols[n][nPosRegBo]
					// Verifica se a correla��o de fato j� est� cadastrada
					DbSelectArea("ACQ")
					DbSetOrder(3) // ACQ_FILIAL+ACQ_CODTAB+ACQ_CODPRO+ACQ_CODREG
					If DbSeek(xFilial("ACQ")+Padr(" ",Len(ACQ->ACQ_CODTAB))+SB1->B1_COD+cRegBon)

					Else
						MsgStop("Para o produto '" + Alltrim(SB1->B1_COD) + " " + Alltrim(SB1->B1_DESC) + " n�o h� regra de Combo cadastrada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						lRet	:= .F.
					EndIf
				Endif
			Endif
		Endif

	Endif

	RestArea(aAreaDA0)
	RestArea(aArea)

Return(lRet)
