#INCLUDE "rwmake.ch" 
#INCLUDE "topconn.ch"

/*/

�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �CADZP  � Autor � CHRISTIAN DANIEL COSTA� Data �  14/02/13   ���
�������������������������������������������������������������������������͹��
���Descricao � TABELA DE AMARRA��O ENTRE CLIENTE E GRUPO DE PRODUTOS      ���
���          � PARA DEFINIR O PERCENTUAL DE F&I                           ���
�������������������������������������������������������������������������͹��
���Uso       � BIG FORTA                                                  ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function CADZP


//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Private cString                                                        	
//cVldAlt :=  // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
//cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

Private cString := "SZP"

dbSelectArea("SZP")
dbSetOrder(1) 
       
AxCadastro(cString,"F&I CLIENTE X GRUPO",,"U_SZPTudOk()", , , , , , , ,)

Return

//############################################################################
//FAZ A VERIFICA��O PARA EVITAR REGISTROS DUPLICADOS 						 #
//############################################################################

User Function SZPTudOk()

Local lRet     := .T.
Local nRecAtu  := 0
Local aAreaOld	:= GetArea()

//MsgAlert("Entrou na valida��o")

If lRet
	If ALTERA
		nRecAtu  := SZP->(Recno())
	EndIF
	
	cQry := " "
	cQry += "SELECT ZP_CLIENTE, ZP_LOJA, ZP_GRUPO, SZP.R_E_C_N_O_ "
	cQry += "  FROM " + RetSqlName("SZP") + " SZP "
	cQry += " WHERE SZP.D_E_L_E_T_ = ' '  "
	cQry += "   AND SZP.ZP_CLIENTE = '" + M->ZP_CLIENTE + "' "
	cQry += "   AND SZP.ZP_LOJA = '" + M->ZP_LOJA + "' "
	cQry += "   AND SZP.ZP_GRUPO = '" + M->ZP_GRUPO + "' "
	cQry += "   AND '" + DTOS(M->ZP_DATAINI) + "' <= SZP.ZP_DATAFIN AND '" + DTOS(M->ZP_DATAFIN) + "' >= SZP.ZP_DATAINI "
	If ALTERA
		cQry += "   AND SZP.R_E_C_N_O_ <> " + Alltrim(Str(nRecAtu)) + " "
	EndIf
	cQry += "   AND SZP.ZP_FILIAL = '" + xFilial("SZP") + "' "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	If !Eof()
		MsgAlert("Grupo j� cadastrado para esse cliente dentro desta vig�ncia! Favor verificar.")
		lRet := .F.
	End
	QRY->(dbCloseArea())
EndIF

RestArea(aAreaOld)

Return(lRet)