
/*/{Protheus.doc} MTA455I
(Registrar no Z0 a hora da Libera��o de Estoque  )
@author Leonardo J Koerich Jr
@since 27/11/03
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MTA455I()

	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MTA455I")
		Return .T.
	Endif
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	// Grava Log e pergunta motivo
	U_GMCFGM01("LE",SC9->C9_PEDIDO,,FunName())
	
Return(.T.)
