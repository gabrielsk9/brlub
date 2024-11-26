#INCLUDE "rwmake.ch"
//--------------------------------+
// Favor Documentar altera��es.   |
// Data - Analista - Descri��o	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo Revisado
//
//-------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BIG021
//CADASTRO DE DEVOLU��ES         
@author marce
@since 09/02/205
@version 6

@type function
/*/
User Function BIG021()

	Private cCadastro		:= "Consulta de Autoriza��es de Devolu��o"
	Private aRotina         := {{'Procurar','AxPesqui',0,1},;
	{'Visualisar','AxVisual',0,2},;
	{'Relat�rio','U_BFFATR18',0,7}}

	// Executa grava��o do Log de Uso da rotina
	U_BFCFGM01()

	dbSelectArea("SZ3")
	dbSetOrder(1)

	MBrowse(6,1,22,75,"SZ3",,,,,,)


Return