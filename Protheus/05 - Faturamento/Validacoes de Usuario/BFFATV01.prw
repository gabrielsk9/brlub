#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATV01
(Valida��o de digita��o de quantidade )
@author MarceloLauschner
@since 27/01/2015
@version 1.0
@param cProduto, character, (Descri��o do par�metro)
@param nQtde, num�rico, (Descri��o do par�metro)
@param lHelp, ${param_type}, (Descri��o do par�metro)
@param cTipo, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATV01()

	Local lRet     	:= .T.
	Local aArea    	:= GetArea()
	Local aAreaSB1 	:= SB1->(GetArea())
	Local nPxProd   := 0
	Local lHelp 	:= !IsBlind()
	Local nQtde		:= 0
	Local nPosOper	:= 0

	If ReadVar() == "M->C6_QTDVEN"
		nQtde		:= M->C6_QTDVEN
		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
		nPosOper	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_OPER"})
	ElseIf ReadVar() == "M->UB_QUANT"
		nQtde		:= M->UB_QUANT
		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="UB_PRODUTO"})
		nPosOper	:= aScan(aHeader,{|x| AllTrim(x[2])=="UB_OPER"})
	Endif

	DbSelectArea("SB1")
	If SB1->(FieldPos("B1_LOTVEN")) > 0

		SB1->(dbSetOrder(1))
		If SB1->(DbSeek(xFilial("SB1")+aCols[n,nPxProd]))
			If nPosOper > 0 .And. !(aCols[n,nPosOper] $ GetNewPar("BF_FTVA01","BA#B ")) // 19/08/2019 - Melhoria para permitir que alguns tipos de OPera��o n�o validem as quantidades por lote de venda
				If SB1->B1_LOTVEN <> 0 .And. Mod(nQtde,SB1->B1_LOTVEN) <> 0
					If lHelp
						MsgAlert("A quantidade digitada n�o corresponde a um m�ltiplo de venda do produto que � de "+cValToChar(SB1->B1_LOTVEN),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" M�ltiplo Venda")
					Endif
					lRet := .F.
				Endif
			Endif
		Endif
	Endif

	RestArea(aAreaSB1)
	Restarea(aArea)

Return(lRet)

