#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFCFGM25
//Fun��o que verifica se o programa deve ser executado para esta empresa ou n�o. Compatibiliza��o nova para Frimazo 
@author Marcelo Alberto Lauschner
@since 06/04/2018
@version 6
@return ${return}, ${return_description}
@param cInFunc, characters, descricao
@type function
/*/
User Function BFCFGM25(cInFunc)

	Local	aAreaOld	:= GetArea()
	Local	aFuncOk		:= {}	
	Local	lRet		:= .T. 
	Local	iQ
	
	// Padroniza a descri��o da fun��o que ser� validada
	cInFunc	:= AllTrim(Upper(cInFunc))
	
	If cEmpAnt+cFilAnt $ "0601#0602#0603" 
		lRet	:= .F. 
		// Cria lista de Exce��es que pode ser executadas  
		Aadd(aFuncOk,{"XXXXXX",cEmpAnt+cFilAnt})
		Aadd(aFuncOk,{"MS520VLD",cEmpAnt+cFilAnt}) 	// 15/8/18 - Liberada a rotina de exclus�o de Lan�amento cont�bil
	Endif

	// Se for falso o retorno, verifico exce��es 
	If !lRet
		For iQ := 1 To Len(aFuncOk)
			If cInFunc == aFuncOk[iQ][1] .And. cEmpAnt+cFilAnt == aFuncOk[iQ][2]
				lRet	:= .T.
				Exit
			Endif
		Next iQ
	Endif	
	RestArea(aAreaOld)

Return lRet

