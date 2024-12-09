#INCLUDE "PROTHEUS.CH"


/*/{Protheus.doc} GMCFGM01
(Grava��o de log de pedidos em diversos pontos do sistema)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@param cTipo, character, (Descri��o do par�metro)
@param cPedido, character, (Descri��o do par�metro)
@param cObserv, character, (Descri��o do par�metro)
@param cResp, character, (Descri��o do par�metro)
@param lBtnCancel, ${param_type}, (Descri��o do par�metro)
@param cMotDef, character, (Descri��o do par�metro)
@param lAutoExec, ${param_type}, (Descri��o do par�metro)
@param cInUserAuto, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function GMCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto)
	//-------------------------------------------------------------------------------------------------
	// 23/07/2011 - Marcelo Lauschner
	// Alterado tratativa da variavel cPedido no caso de cancelamento de Documento para a Superlog
	// pois CTRC n�o possui Pedido de venda para gravar historico na SZ0 e portanto fica o valor de F2_DOC
	//-------------------------------------------------------------------------------------------------
	
	Local		aAreaOld	:= GetArea()
	Local		cDescTipo	:= ""
	Local		oDlgObs
	Local		cMotBlq		:= Space(150)
	Local		lJustif		:= .F.
	Local		lContinua	:= .F.
	Default		cMotDef		:= cMotBlq
	Default		cTipo		:= "LG"
	Default 	lBtnCancel	:= .F.
	Default 	cObserv		:= ""
	Default		lAutoExec	:= .F.
	Default		cInUserAuto	:= cUserName
	Default		cPedido		:= ""
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("GMCFGM01")
		Return   {cMotBlq,.T. /*lContinua*/}
	Endif
	
	If !Empty(cMotDef)
		cMotBlq	:= Padr(cMotDef,150)
	Endif
	
	
	If cTipo == "IP"
		cDescTipo	:= "Inclus�o de Pedido"
	ElseIf cTipo == "AP"
		cDescTipo	:= "Altera��o de Pedido"
	ElseIf cTipo == "AC"
		cDescTipo	:= "Altera��o Cabe�alho de Pedido"
	ElseIf cTipo == "FL"
		cDescTipo	:= "Follwo-up de Pedido"
	ElseIf cTipo == "LF"
		cDescTipo	:= "Libera��o de Al�ada"
	ElseIf cTipo == "LP"
		cDescTipo	:= "Libera��o de Pedido"
	ElseIf cTipo == "BT"
		cDescTipo	:= "Bloqueio/Pend�ncia Comercial"
	ElseIf cTipo == "BF"
		cDescTipo	:= "Bloqueio/Pend�ncia Financeira"
	ElseIf cTipo == "BA"
		cDescTipo	:= "Bloqueio/Pagto Antecipado"
	ElseIf cTipo == "LA"
		cDescTipo	:= "Libera��o/Pgto Antecipado"
	ElseIf cTipo == "LC"
		cDescTipo	:= "Libera��o Cr�dito"
	ElseIf cTipo == "LR"
		cDescTipo	:= "Pedido Rejeitado"
		lJustif	:= .T.
	ElseIf cTipo == "ED"
		cDescTipo	:= "Enviado p/Expedi��o"
	ElseIf cTipo == "IM" // Impressao manual para separacao
		cDescTipo	:= "Impress�o Pedido p/Separa��o"
	ElseIf cTipo == "EC"
		cDescTipo	:= "Enviado p/Separa��o/Emiss�o NF"
	ElseIf cTipo == "CP"
		cDescTipo	:= "Confer�ncia/Emiss�o Etiquetas"
	ElseIf cTipo == "ET"
		cDescTipo	:= "Exportado para Arquivo EDI"
	ElseIf cTipo == "CN"
		cDescTipo	:= "Cancelamento NotaFiscal/Pedido"
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
		lJustif		:= .T.
	ElseIf cTipo == "NF"
		cDescTipo	:= "Gerada Nota Fiscal Doc.Sa�da"
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
	ElseIf cTipo == "IN"
		cDescTipo	:= "Gera��o/Impress�o da Danfe "
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cPedido		:= SD2->D2_PEDIDO
		
	ElseIf cTipo == "EF"
		cDescTipo	:= "Pedido Retornado ao TMK"
		lJustif		:= .T.
	ElseIf cTipo == "DB"
		cDescTipo	:= "Lan�amento Box/Sep/Conf/Mes"
	ElseIf cTipo == "ER"
		cDescTipo	:= "Elimina��o de Res�duos"
		lJustif		:= .T.
	ElseIf cTipo == "EP"
		cDescTipo	:= "Exclus�o do Pedido"
		lJustif		:= .T.
	ElseIf cTipo == "LE"
		cDescTipo	:= "Libera��o de Estoque"
		lJustif		:= .T.
	ElseIf cTipo == "EL"
		cDescTipo	:= "Exclusao de Lote Cont�bil"
		lJustif		:= .T.
	Endif
	
	If lJustif
		
		If !lAutoExec
			DEFINE MSDIALOG oDlgObs FROM 000,000 TO 150,370 OF oMainWnd PIXEL TITLE OemToAnsi(cDescTipo +" "+ cPedido )
			@ 010,010 Say "Justificativa" of oDlgObs Pixel
			@ 025,010 MsGet cMotBlq	Size 175,10 Valid(Len(Alltrim(StrTran(StrTran(cMotBlq," ",""),".",""))) > 12)   of oDlgObs Pixel
			@ 050,010 BUTTON "&Avan�a" of oDlgObs pixel SIZE 40,10 ACTION (lContinua	:= .T.,oDlgObs:End() )
			If lBtnCancel
				@ 050,050 BUTTON "&Cancela" of oDlgObs pixel SIZE 40,10 ACTION (oDlgObs:End() )
			Endif
			ACTIVATE msDIALOG oDlgObs CENTERED Valid(Len(Alltrim(StrTran(StrTran(cMotBlq," ",""),".",""))) > 12)
			If lBtnCancel
				If !lContinua
					cMotBlq	:= "Opera��o cancelada pelo usu�rio/"+cMotBlq
				Endif
			Endif
		Else
			cMotBlq	+= "/Processo autom�tico."
		Endif
	Endif
	
	RecLock("SZ0",.T.)
	SZ0->Z0_FILIAL := xFilial("SZ0")
	SZ0->Z0_PEDIDO := cPedido
	SZ0->Z0_DATA   := Date()
	SZ0->Z0_HORA   := Time()
	SZ0->Z0_USER   := cInUserAuto
	SZ0->Z0_DEST   := cResp
	SZ0->Z0_TIPO   := cTipo
	
	If SZ0->(FieldPos("Z0_DESCOC")) <> 0
		SZ0->Z0_DESCOC	:= cDescTipo
	Endif
	If SZ0->(FieldPos("Z0_CONTEUD")) <> 0
		SZ0->Z0_CONTEUD	:= cDescTipo
	Endif
	If SZ0->(FieldPos("Z0_OBS")) <> 0
		SZ0->Z0_OBS    := IIf(!Empty(cMotBlq),"Motivo: "+cMotBlq + Chr(13)+ Chr(10)+cObserv,cObserv)
	Endif
	MsUnLock()
	
	RestArea(aAreaOld)
	
Return {cMotBlq,lContinua}
