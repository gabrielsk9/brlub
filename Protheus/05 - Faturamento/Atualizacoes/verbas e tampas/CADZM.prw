#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �CADZM  � Autor � CHRISTIAN DANIEL COSTA� Data �  27/07/10   ���
�������������������������������������������������������������������������͹��
���Descricao � TABELA DE DE PRODUTOS POR CLIENTE EM COMODATO              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � BIG FORTA                                                  ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

User Function CADZM


//���������������������������������������������������������������������Ŀ
//� Declaracao de Variaveis                                             �
//�����������������������������������������������������������������������

Private cString
Private cZMContr
Private cZMClie
Private cZMLoja         
cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
//aBotoes := {} //"VERMELHO",U_SBIMPSA1(),"Adicionar Produtos","Produtos"
// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

Private cString := "SZM"

dbSelectArea("SZM")
dbSetOrder(1) 
//AADD(aBotoes,{"PRODUTO",{|| U_SB1XSZM(M->ZM_NUMCONT,M->ZM_CLIENTE,M->ZM_LOJA)},"Adicionar Produtos","Produtos"})
       
//AxCadastro(cString,"TAB CONTRATOS",cVldExc,cVldAlt, , ,{|| U_GravarSZO(M->ZM_NUMCONT)} , , , , ,aBotoes)
AxCadastro(cString,"TAB CONTRATOS",cVldExc,cVldAlt, , , ,{|| IIF(INCLUI .OR. ALTERA,U_SB1XSZM(M->ZM_NUMCONT,M->ZM_CLIENTE,M->ZM_LOJA),U_SB1XSZM(SZM->ZM_NUMCONT,SZM->ZM_CLIENTE,SZM->ZM_LOJA))} , , , ,)
//			1			2			 3		 4	   5 6 7			8											 9	 
Return 

