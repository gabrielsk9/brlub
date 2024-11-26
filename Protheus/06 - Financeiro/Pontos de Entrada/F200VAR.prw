#include 'totvs.ch'

/*/{Protheus.doc} F200VAR
PE para manipular informa��es obtidas por meio de importa��o do arquivo de retorno CNAB
@type function
@version 12.1.033
@author Jean Carlos Pandolfo Saggin
@since 6/29/2022
@return array, aNewData
/*/
user function F200VAR()

    local aDados := PARAMIXB[01]
    local aArea := GetArea()

    if ValType( aDados ) == 'A' .and. len( aDados ) > 0
        dBaixa    := aDados[02]
        dDataCred := aDados[13]
        // Valida��o para preenchimento autom�tico das vari�veis de data de cr�dito quando entrada no ponto de entrada for ap�s a leitura da 
        // �ltima linha do arquivo. Nesse momento, n�o existem mais informa��es a serem lidas e as vari�veis precisam estar preenchidas para
        // que o movimento banc�rio referente as despesas seja gravado na data correta
        if Empty( aDados[16] ) .and. Empty( dBaixa ) .and. Empty( dDataCred )      // Depois de lida a �ltima linha do arquivo
            dBaixa    := DataValida( dDataBase, .T. )
            dDataCred := DataValida( dDataBase, .T. )
        endif
    endif

    RestArea( aArea )
return aDados
