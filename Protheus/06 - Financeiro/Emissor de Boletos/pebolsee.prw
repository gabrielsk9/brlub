#include 'protheus.ch'

/*/{Protheus.doc} PEBOLSEE
Modelo de PE para manipula��o dos dados de par�metros de bancos da rotina de emiss�o de boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 17/06/2022
@return array, aNewParams
/*/
user function PEBOLSEE()
    
    local aRetPE := PARAMIXB[1]

    if aRetPE[01] == '341'      // Ita�
        aRetPE[06] := SubStr( aRetPE[05], len( aRetPE[05] ), 1 )
        aRetPE[05] := SubStr( aRetPE[05], 1, len( aRetPE[05] )-1 )
    endif

return aRetPE
