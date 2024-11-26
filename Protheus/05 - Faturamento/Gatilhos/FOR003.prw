#INCLUDE "rwmake.ch"

//--------------------------------+
// Favor Documentar altera��es.   |
// Data - Analista - Descri��o	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo Revisado
//
//-------------------------------------------------------------------------------------------------

User Function FOR003

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa �FOR003 � Autor � Leonardo J Koerich Jr  � Data �  12/09/03   ���
�������������������������������������������������������������������������͹��
���Descricao � verificar data de entrega                                  ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Sigafat                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������
Local 	aAreaOld	:= GetArea()
Local 	cCliente 	:= M->C5_CLIENTE
Local 	cLoja    	:= M->C5_LOJACLI
Local 	cCEP		:=" "
Local 	cRota		:=" "
Local 	nDiaAtu  	:= 0
Local 	nDiaEnt  	:= 0
Local 	dData    	:= dDataBase
Local 	aRota    	:= {}
Local 	aDias    	:= {1,2,3,4,5,6,7}

// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

//���������������������������������������������������������������������Ŀ
//� Verifica da de entrega                                              �
//�����������������������������������������������������������������������
dbSelectArea("SA1")
dbSetOrder(1)
If dbSeek(xFilial("SA1")+cCliente+cLoja)
	cCEP := SA1->A1_CEP
	
	IF SA1->A1_ROTA <> " "
		cRota := SA1->A1_ROTA
	Endif
	
	dbSelectArea("PAB")
	dbSetOrder(1)
	If dbSeek(xFilial("PAB")+cCEP)
		cRota := PAB->PAB_ROTA
		
		For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
			AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
		Next
	Endif
	
	IF SA1->A1_ROTA <> " "
		For x := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
			AADD(aRota,{SubStr(SA1->A1_ROTA,x,1)})
		Next
	Endif
	
Endif

nDia := Dow(dDatabase)
If Len(aRota) > 0
	While .T.
		If nDia > 7
			nDia := 1
		Endif
		nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
		If !Empty(nPos)
			nDiaEnt := Val(aRota[nPos][1])
			If nDiaEnt == Dow(dDatabase)
				dData := dDatabase
			Elseif (nDiaEnt - Dow(dDatabase)) > 0
				dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
			Else
				dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
			Endif
			Exit
		Endif
		nDia++
	End
Endif

RestArea(aAreaOld)

Return(dData)
