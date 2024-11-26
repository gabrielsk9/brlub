#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} BOLXFN
Retorno vai depender de onde a fun��o estiver sendo chamada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/12/2022
@param cID, character, ID do local onde a fun��o est� sendo chamada
@return variadic, xRet
/*/
user function BOLXFN( cID )
    
    local xRet := Nil
    local aSubVet := {} as array
    
    default cID := "" 

    if cID == '740BRW'
        xRet := {}      // Retorno ser� um vetor de novos bot�es da rotina FINA740 - Fun��es do Contas a Receber
        
        // SubMenu do bot�o Boleto
        aAdd( aSubVet, { 'Imprimir Boleto', 'U_B1740BRW', 0, 3 } )

        // Bot�o Boleto
        aAdd( xRet, { 'Boletos', aSubVet, 0, 4 } )

    endif

return xRet

/*/{Protheus.doc} B1740BRW
Bot�o Imprimir Boleto da rotina FINA740
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/12/2022
/*/
user function B1740BRW()
    
    local aArea := getArea()
    
    // Chama impress�o de boletos
    U_BOLRULES( 'SE1' )

    restArea( aArea )
return Nil

