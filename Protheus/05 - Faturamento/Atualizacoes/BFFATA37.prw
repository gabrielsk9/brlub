#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATA37
(Cadastro de Motivos de Bloqueio por Al�adas)
@author MarceloLauschner
@since 09/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA37()

Private cString := "SZS"

// Executa grava��o do Log de Uso da rotina
U_BFCFGM01()

dbSelectArea("SZS")
dbSetOrder(1)

AxCadastro(cString,"Cadastro de motivos de Al�adas",".T."/*cVldExc*/,".T."/*cVldAlt*/)

Return

