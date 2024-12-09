#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} M460FIL
(Filtra pedidos na tela de Faturamento Manual Padr�o MATA460A)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M460FIL()
	
	Local aAliasOld := GetArea()
	Local cFiltroC9 := ""
	Local lPedLiber := !(__cUserId $ GetNewPar("BF_M460FIL"))
	local lContOnline := GetNewPar("GM_CTBONLN",.T.)
	
	
	// For�a a contabiliza��o Online - Chamado 21.591
	If lContOnline
		//� mv_par01 Mostra Lan�.Contab     ?  Sim/Nao                         �
		U_GravaSx1("MT460A","01",2)
		//� mv_par02 Aglut. Lan�amentos     ?  Sim/Nao                         �
		U_GravaSx1("MT460A","02",1)
		//� mv_par03 Lan�.Contab.On-Line    ?  Sim/Nao                         �
		U_GravaSx1("MT460A","03",1)
		
	Endif
	
	
	// Efetua verifica��o se esta valida��o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M460FIL")
		Return ".T."
	Endif
	
	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()
	
	If lPedLiber
		cFiltroC9 += "(Alltrim(C9_FLGENVI) == 'E') "  //"(!Empty(C9_FLGENVI)) "
	Else
		cFiltroC9 += " .T. "
	endif
	
	RestArea( aAliasOld )
	
Return cFiltroC9

