#Include 'Protheus.ch'


/*/{Protheus.doc} MT119TOK
Ponto de entrada com objetivo de customizar a valida��o executada pela fun��o TudoOk da rotina de Despesa de Importa��o.
@author Iago Luiz Raimondi
@since 28/01/2015
@version 1.0
@return ${lRet}, ${Retorno l�gico determinando o resultado da valida��o customizada para permitir continuar (.T.) ou n�o permitir (.F.).}
@example
Possibilita validar o total da despesa de importa��o para que somente seja gerada se for inferior a R$200,00.
@see http://tdn.totvs.com/pages/releaseview.action?pageId=6085705
/*/
User Function MT119TOK()

	Local lRet := .T.

	If ExistBlock("MT103DNF")
		lRet := ExecBlock("MT103DNF",.F.,.F.,{aNFEDanfe})
	Endif

Return lRet

