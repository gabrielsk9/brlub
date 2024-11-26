#Include 'Protheus.ch'

/*/{Protheus.doc} TMKACTIVE
(Ponto de entrada na ativa��o da tela do Callcenter)
@type function
@author marce
@since 22/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TMKACTIVE()
	// Verifica se � Televendas
	If (TkGetTipoAte() $ "245")
		// Verifica se a vari�vel p�blica j� existe e se for diferente o valor dela assume o valor da vari�vel de mem�ria M->UA_CONDPG
		If Type("cCondOld") <> "U" .And. M->UA_CONDPG <> cCondOld
			cCondOld	:= 	M->UA_CONDPG
		Endif
	Endif
Return

