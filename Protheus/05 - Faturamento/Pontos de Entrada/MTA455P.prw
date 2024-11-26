#include "topconn.ch"
#include "protheus.ch"
#INCLUDE "AP5MAIL.CH"

/*/{Protheus.doc} MTA455P
(Impedir que usu�rios possam liberar estoque for�ado)

@author MarceloLauschner
@since 13/04/2012
@version 1.0

@return LRET(logico)  Variavel logica, sendo: .T. Libera o item normalmente .F. Impede a liberacao do item

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784411)
/*/
User Function MTA455P()
	
	Local 	cQry 	 	:= ""
	Local 	nQteLib  	:= 0
	Local   nQteBlq	:= 0
	Local 	nVlrCred 	:= 0
	Local   cFlgCol  	:= "   "
	Local 	aLib	 	:= { .T.,.T.,.F.,.F.}  //
	Local	nQteBkNew 	:= Iif(Type("nQteNew") <> "U",nQteNew,0)
	Local	nOpcR 		:= ParamIxb[1]
	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	aDadosSC9	:= {}
	Local	bBlockSC9	:= {|| .T.}
	local   cVend       := "" as character
	local   cMailTmk    := "" as character
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MTA455P")
		Return .T.
	Endif
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	
	// Se selecionada a op��o de for�ar a libera��o
	If nOpcR == 2
		// Verifica se Existe o parametro, e ent�o o cria
		//sfVerSX6()
		
		
		If SaldoSB2() < SC9->C9_QTDLIB
			If !(__cUserId $GetNewPar("BF_MTA455P","000000#"))   // Administrador/
				MsgAlert("Desde 16/01/2011 n�o est� mais liberado o uso for�ado da libera��o de estoque por esta rotina. Se houver necessidade efetiva de liberar o item contate o CPD!","A T E N � � O!! Permiss�o negada!")
				RestArea(aAreaOld)
				Return  .F.
			Endif
		Endif
	Endif
	
	
	If !MsgYesNo("Confirma ajuste customizado da altera��o da quantidade liberada? Se optar pelo 'N�o' a altera��o n�o funcionar� para a Expedi��o corretamente!!","Ajuste de libera��o!")
		RestArea(aAreaOld)
		Return .T.
	Endif
	
	DEFINE MSDIALOG oDlg1 FROM  001,001 TO 180,300 TITLE OemToAnsi("Libera��o de Estoque") PIXEL
	
	@ 013,015 SAY OemToAnsi("Pedido")                 SIZE 23, 7 OF oDlg1 PIXEL		//"Pedido"
	@ 013,042 SAY SC9->C9_PEDIDO                     SIZE 26, 7 OF oDlg1 PIXEL
	nQteBkNew := SC9->C9_QTDLIB
	@ 052,015 SAY OemToAnsi("Qtd Neste Item")                 SIZE 46, 7 OF oDlg1 PIXEL			//"Qtd.neste �tem"
	@ 052,062 MSGET nQteBkNew Picture PesqPictQt("C9_QTDLIB",10) Valid A455Qtdl(nQteBkNew) SIZE 53, 7 OF oDlg1 PIXEL
	
	DEFINE SBUTTON FROM 066,20 TYPE 1 ACTION (nOpcR := 2,oDlg1:End()) ENABLE OF oDlg1
	DEFINE SBUTTON FROM 066,56 TYPE 2 ACTION oDlg1:End() ENABLE OF oDlg1
	
	ACTIVATE MSDIALOG oDlg1 CENTERED
	
	If nOpcR <> 2
		Return .F.
	Endif
	
	cQry += "SELECT C9_PEDIDO,C9_QTDLIB,C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_XWMSEDI,C9_XWMSPED,C9_BLINF,C9_FLGENVI,C9_LIBFAT,C9_XWMSQTE,C9_ORDSEP"
	cQry += "  FROM " + RetSqlName("SC9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = ' ' " // Somente item de pedido n�o enviado para separa��o
	cQry += "   AND C9_NFISCAL = '  ' "
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_SEQUEN = '"+SC9->C9_SEQUEN+"' "
	cQry += "   AND C9_ITEM = '"+SC9->C9_ITEM+"' "
	cQry += "   AND C9_PEDIDO =  '" +SC9->C9_PEDIDO+"' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
	
	TCQUERY cQry NEW ALIAS "QRC9"
	If Eof()
		MsgAlert("Verifique se o pedido est� na Expedi��o, pois somente pedidos que n�o foram enviados para expedi��o poder�o ser alterados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Endif
	While !Eof()
		
		nQteBlq := QRC9->C9_QTDLIB
		
		// Se houver diferen�a entre a quantidade liberada e a quantidade separada e conferida
		If QRC9->C9_QTDLIB <> nQteBkNew
			DbSelectArea ("SC9")
			DbSetOrder(1)
			If DbSeek(xfilial("SC9")+QRC9->C9_PEDIDO+QRC9->C9_ITEM+QRC9->C9_SEQUEN+QRC9->C9_PRODUTO)
				
				// Executa Estorno do Item
				SC9->(A460Estorna(/*lMata410*/,/*lAtuEmp*/,@nVlrCred))
				// Cad. item do pedido de venda
				DbSelectArea("SC6")
				SC6->(DbSetOrder(1))
				SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM
				
				
				// Se a quantidade conferida for maior que zero -- evita que quantidades zeradas possam ser liberadas.
				If nQteBkNew > 0	// Garante que o Flag de separa��o v� para o novo item liberado
					MaLibDoFat(SC6->(RecNo()),nQteBkNew,aLib[1],aLib[2],aLib[3],aLib[4],.F.,.F.,/*aEmpenho*/,{|| SC9->C9_XWMSEDI := QRC9->C9_XWMSEDI,SC9->C9_XWMSPED := QRC9->C9_XWMSPED,SC9->C9_BLINF := QRC9->C9_BLINF,SC9->C9_FLGENVI := QRC9->C9_FLGENVI,SC9->C9_LIBFAT := STOD(QRC9->C9_LIBFAT),SC9->C9_XWMSQTE := QRC9->C9_XWMSQTE,SC9->C9_ORDSEP := QRC9->C9_ORDSEP }/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
				Endif
				// A quantidade n�o separada � liberada com bloqueio de estoque
				nQteBlq	-= nQteBkNew
				If nQteBlq > 0
					MaLibDoFat(SC6->(RecNo()),nQteBlq,.T./*lCredito*/,.F./*lEstoque*/,.F./*lAvCred*/,.F./*lAvEst*/,.F./*lLibPar*/,.F./*lTrfLocal*/,/*aEmpenho*/,/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
				Endif
				SC6->(MaLiberOk({SC9->C9_PEDIDO},.F.))
				aRetLog	:= U_GMCFGM01("LE",QRC9->C9_PEDIDO,"Produto "+QRC9->C9_PRODUTO +" Qte liberada: "+Alltrim(Str(nQteBkNew)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq)),FunName())
				
				// Identifica o vendedor do pedido
				cVend := RetField( 'SC5', 1, FWxFilial( 'SC5' ) + QRC9->C9_PEDIDO, 'C5_VEND1' )
				// Valida exist�ncia do campo customizado do e-mail do televendas
				if SA3->( FieldPos( 'A3_EMTMK' ) ) > 0
					// Captura o e-mail do televendas para enviar o e-mail com c�pia
					cMailTmk := RetField( 'SA3', 1, FWxFilial( 'SA3' ) + cVend, 'A3_EMTMK' )
				endif

				If !Empty(QRC9->C9_FLGENVI)
					stSendMail("marcelo@centralxml.com.br"+ iif( !Empty( cMailTmk ), ';', '' ) + cMailTmk,;
						"Altera��o de quantidade em pedido liberado/expedi��o "+SM0->M0_NOMECOM,;
						"Produto "+QRC9->C9_PRODUTO +" Qte liberada: "+Alltrim(Str(nQteBkNew)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq))+Chr(13)+Chr(10)+"Motivo:"+aRetLog[1])
				Else
					stSendMail("marcelo@centralxml.com.br"+ iif( !Empty( cMailTmk ), ';', '' ) + cMailTmk,;
						"Altera��o de quantidade em pedido liberado "+SM0->M0_NOMECOM,;
						"Produto "+QRC9->C9_PRODUTO +" Qte liberada: "+Alltrim(Str(nQteBkNew)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq))+Chr(13)+Chr(10)+"Motivo:"+aRetLog[1])
				Endif
			Endif
		Endif
		DbSelectArea("QRC9")
		DbSkip()
	Enddo
	QRC9->(DbCloseArea())
	
	RestArea(aAreaOld)
	
Return .F.


/*/{Protheus.doc} sfVerSX6
(Cria parametro)

@author MarceloLauschner
@since 09/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
//Static Function sfVerSX6()
//	
//	Local		aAreaOld	:= GetArea()
//	
//	DbSelectArea("SX6")
//	DbSetOrder(1)
//	
//	// Se executado o Wizard, ir� limpar o parametro de controle de
//	If !DbSeek(cFilAnt+"BF_MTA455P")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := cFilAnt
//		SX6->X6_VAR     := "BF_MTA455P"
//		SX6->X6_TIPO    := "C"
//		SX6->X6_DESCRIC := "Id de usu�rios para liberar/zerar estoque"
//		MsUnLock()
//		PutMv("BF_MTA455P","000000")
//	Endif
//	
//	RestArea(aAreaOld)
//	
//Return

/*/{Protheus.doc} stSendMail
(long_description)

@author MarceloLauschner
@since 09/12/2013
@version 1.0

@param cRecebe, character, (Descri��o do par�metro)
@param cAssunto, character, (Descri��o do par�metro)
@param cMensagem, character, (Descri��o do par�metro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function stSendMail( cMailTo, cAssunto, cMensagem)

	Local	aAreaOld 		:= GetArea()
	Local 	lOk 		:= .F.
	Local	lAutOk 		:= .F.
	Local	lSendOk 	:= .T.

	Local cMailServer := AllTrim(GetNewPar("MV_RELSERV"," "))        // Servidor utilizado para envio do e-mail
	Local cMailConta  := AllTrim(GetNewPar("MV_RELACNT"," "))        // Conta utilizada para envio
	Local cMailSenha  := AllTrim(GetNewPar("MV_RELPSW" ," "))        // Senha da conta de envio
	Local lSmtpAuth   := GetNewPar("MV_RELAUTH", .F.)                // Verifica se deve realizar autentica��o
	Local nTimeOut    := GetNewPar("MV_RELTIME", 120)                // Tempo de Espera antes de abortar a Conex�o
	Local cUserAut    := Alltrim(GetNewPar("MV_RELAUSR",cMailConta)) // Usu�rio para Autentica��o no Servidor de Email
	Local cSenhAut    := Alltrim(GetNewPar("MV_RELAPSW",cMailSenha)) // Senha para Autentica��o no Servidor de Email
	Local lRetMail 		:= .T.

	// Campos a serem repassados no e-mail
	Default cMailTo   := Space(20)
	Default cAssunto  := Space(20)
	Default cMensagem := Space(20)

	cMailTo := U_BFFATM15(cMailTo,"BIG005")


	CONNECT SMTP SERVER cMailServer ACCOUNT cMailConta PASSWORD cMailSenha TIMEOUT nTimeOut RESULT lOk

// Valida existencia de campos necessarios para o envio do e-mail
	If !Empty(cMailServer) .And. !Empty(cMailConta)
		// Verifica autentica��o no servidor descrito, se necessario
		If !lAutOk
			If lSmtpAuth
				If !(lAutOk := MailAuth(cUserAut,cSenhAut))
					cMsgSend := "Falha na autentica��o do usu�rio no provedor de e-mail"
					lRetMail := .F.
				Endif
			Else
				lAutOk := .T.
			EndIf
		EndIf

		If lRetMail // Caso a autentica��o tenha sido efetuada corretamente.
			If lOk  // Caso a conexao com o servidor, esteja estabelecida, e possibilite o envio do e-mail
				SEND MAIL FROM cMailConta TO cMailTo SUBJECT cAssunto BODY cMensagem RESULT lSendOk  // Efetua envio do e-mail

				If !lSendOk
					Get MAIL ERROR cError // Verifica erro indicado pelo servidor, no ato do envio do e-mail
				Endif

				// Armazena informa��es para retorno
				cMsgSend := If(lSendOk, "E-mail enviado com sucesso!", cError) // "E-mail enviado com sucesso!"
				lRetMail := lSendOk
			Else
				cMsgSend := "Erro na conex�o com o servidor SMTP." + CHR(13) + CHR(10) + ; // "Erro na conex�o com o servidor SMTP."
				"Verifique configura��es e autentica��es do servidor de e-mail." // "Verifique configura��es e autentica��es do servidor de e-mail."
				lRetMail := .F.
			EndIf
		Endif

		DISCONNECT SMTP SERVER // Finaliza conexao com servidor de e-mail
	Else
		cMsgSend := "As configura��es para o acesso ao servidor de e-mail est�o incorretas." + CHR(13) + CHR(10) + ; // "As configura��es para o acesso ao servidor de e-mail est�o incorretas."
		"Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW" // "Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW"
		lRetMail := .F.
	EndIf

	RestArea(aAreaOld)

Return



