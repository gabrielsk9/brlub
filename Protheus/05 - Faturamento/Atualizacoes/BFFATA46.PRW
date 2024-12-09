#include "rwmake.ch"
#include "topconn.ch"


/*/{Protheus.doc} BFFATA46
(Retornar pedido para assessoria - retirar da separa��o)
@author MarceloLauschner
@since 10/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA46()
	
Return U_BIG014()


/*/{Protheus.doc} BIG014
(Retornar pedido    )
@author MarceloLauschner
@since 11/07/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BIG014()
	
	
	Private oLeTxt
	Private cNum    	:= Space(6)
	Private cBco1   	:= Space(3)
	Private cLibera 	:= Space(1)
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	@ 000,1 TO 180,420 DIALOG oLeTxt TITLE OemToAnsi("Voltar pedido a TMK ou Reenvio para Separa��o!")
	@ 02,10 TO 070,190
	@ 10,018 Say "Numero do Pedido"
	@ 10,070 Get cNum
	@ 40,018 Say "Manter Bloqueio"
	@ 40,070 Combobox cLibera Items {"N=Estorna pend�ncia-Voltar p/TMK"} Size 90,10
	@ 72,133 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)
	
	Activate Dialog oLeTxt Centered
	
Return


/*/{Protheus.doc} OkLeTxt
(Executa altera��o dos dados na SC9)
@author MarceloLauschner
@since 10/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function OkLeTxt()
	
	
	If !__cUserId $ GetNewPar("GM_RTPDTMK","000191#000139#000184") // Andre/Alexandre/Lima
		MsgAlert("Usu�rio n�o autorizado a alterar pedido para liberar reenvio a separa��o ou voltar para TMK!","Sem autoriza��o!")
		Return
	Endif
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	If DbSeek(xFilial("SC5")+cNum)
	
	Else
		MsgAlert("Informe o numero do Pedido de Venda.","Atencao!")
		Return
	Endif
	
	DbSelectArea("SC5")
	Reclock("SC5",.F.)
	SC5->C5_BOX 	:= " "
	SC5->C5_BLPED	:= cLibera
	MSUnLock()
	
	DbSelectArea("SC9")
	DbSetOrder(1)
	DbSeek(xFilial("SC9")+SC5->C5_NUM)
	While !Eof() .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == xFilial("SC9")+SC5->C5_NUM
		If Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED)
			RecLock("SC9",.F.)
			SC9->C9_XWMSPED	:= 0					// Controle de que foi enviado para separa��o
			SC9->C9_XWMSEDI	:= 0
			SC9->C9_ORDSEP	:= ""
			SC9->C9_XWMSQTE	:= 0
			SC9->C9_FLGENVI	:= ' '					// Controle de que h� envio para faturamento ou alguma restri��o
			SC9->C9_LIBFAT 	:= CTOD("  /  /  ")   	// Data do envio para expedi��o
			SC9->C9_BLINF  	:= " "					// Hora do envio para expedi��o
			MsUnlock()
		Endif
		SC9->(DbSkip())
	Enddo
	
	MsgAlert("Entrada de Dados Realizada com sucesso!!","Informa��o!")
	
	U_GMCFGM01("EF",SC5->C5_NUM,"Contra prova: "+SC5->C5_BOX + " Pedido retornado op��o '"+cLibera+"'" ,FunName())
	
	Close(oLeTxt)
	
Return
