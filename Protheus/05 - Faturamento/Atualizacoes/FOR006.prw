#INCLUDE "rwmake.ch"

User Function FOR006

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa � FOR006 � Autor � Leonardo J Koerich Jr  � Data �  28/11/03  ���
�������������������������������������������������������������������������͹��
���Descricao � Historico pedido workflow                                  ���
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

Local cVldAlt := ".F." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Local cVldExc := ".F." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

dbSelectArea("SZ0")
dbSetOrder(1)

AxCadastro("SZ0","Historico Pedido - Workflow",cVldAlt,cVldExc)

Return
