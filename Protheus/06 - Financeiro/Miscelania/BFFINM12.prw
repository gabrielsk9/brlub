#Include 'Protheus.ch'

/*/{Protheus.doc} BFFINM12
(Retornar Conta cont�bil na baixa por cheques em t�tulos de IRF - buscando conta do passivo da natureza do t�tulo pai)
@author MarceloLauschner
@since 28/09/2015
@version 1.0
@param cInDefConta, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFINM12(cInDefConta)
	
	Local	aAreaOld	:= GetArea()
	Local	cTitPai		:= ""
	Local	cNatPai		:= ""
	Local	aAreaSE2	:= SE2->(GetArea())
	Local	aAreaSED	:= SED->(GetArea())
	Local	cRetCtaDeb	:= ""
	Default	cInDefConta	:= SED->ED_XCCPASV
	
	// Atribui valor inicial para a conta 
	cRetCtaDeb	:= cInDefConta
	// Localiza t�tulos de Taxa com natureza IRF
	If SE2->E2_TIPO == Padr("TX",Len(SE2->E2_TIPO)) .And. SE2->E2_NATUREZ = Padr("IRF",Len(SE2->E2_NATUREZ)) .And. !Empty(SE2->E2_TITPAI)
		cTitPai		:= SE2->E2_TITPAI
		// Localiza t�tulo Pai
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+cTitPai)
			cNatPai		:=	SE2->E2_NATUREZ
			// Posiciona natureza do t�tulo Pai		
			DbSelectArea("SED")
			DbSetOrder(1)
			If DbSeek(xFilial("SED")+cNatPai)
				// Se tiver Conta do passivo para a Natureza
				If !Empty(SED->ED_XCCPASV)
					cRetCtaDeb	:= SED->ED_XCCPASV
				Endif
			Endif
		Endif			
	Endif
	RestArea(aAreaSE2)
	RestArea(aAreaSED)
	RestArea(aAreaOld)
	
Return cRetCtaDeb

