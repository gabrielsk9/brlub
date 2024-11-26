#include 'totvs.ch'
#include 'topconn.ch'

#define CEOL chr(13)+chr(10)

/*/{Protheus.doc} BFFATM41
Fun��o respons�vel pela importa��o dos dados referente ao processo de exporta��o do hist�rico
de clientes da Onix para a BRLub
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/5/2022
/*/
user function BFFATM41()

    local aArea    := getArea()
    local cFile    := ""  as character
    local cDirSrv  := "/transitoria/"
    local lSuccess := .T. as logical
    local cDrive := "" as character
    local cPath := "" as character
    local cArq := "" as character
    local cExt := "" as character

    Private cAliHist := AllTrim(SuperGetMv( 'MV_X_ALIH',,'' ))      // Alias referente ao hist�rico de movimenta��es da Onix

    // Valida configura��o do alias da tabela de hist�rico antes de prosseguir
    if Empty( cAliHist )
        Hlp( 'MV_X_ALIH','Tabela de hist�rico de clientes n�o definido!',;
        '� necess�rio definir um alias por meio do par�metro MV_X_ALIH para '+;
        'que o sistema saiba qual � a tabela de onde deve ler os dados hist�ricos dos clientes.' )
        return Nil
    endif
    //SplitPath( cPatharq, @cDrive, @cDir, @cArq, @cExt )
    
    // Captura path local do arquivo para importar
    cFile := AllTrim( cGetFile( 'Arquivo de Texto .CSV | *.csv ','Selecione o arquivo para importar...', 1,"",;
                        .F./* lSave */, GETF_LOCALHARD ) )
    // Se o conte�do retornou vazio, � porque usu�rio pressionou o bot�o de cancelar
    if ! Empty( cFile )
        // Valida exist�ncia do arquivo selecionado ou digitado
        if File( cFile )
            // Chama fun��o interna que copia os dados do remote para o server
            SplitPath( cFile, @cDrive, @cPath, @cArq, @cExt )
            lSuccess := CPYT2S( cFile, cDirSrv, .T. /* lCompact */ )
            if lSuccess
                lSuccess := runImport( Lower( cDirSrv + cArq + cExt ) )
            else
                MsgStop( "N�o foi poss�vel copiar o arquivo <b>"+ cArq + cExt +"</b> para o diret�rio <b>"+ cDirSrv +"</b> do servidor !","F A L H A !" )                
            endif
        else
            MsgStop( "O arquivo selecionado/informado <b>"+ cFile +"</b> n�o � v�lido!","F A L H A !" )
        endif
    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} Hlp
Fun��o para facilitar apresenta��o de help sem necessidade de informar tantos par�metros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/4/2022
@param cTitulo, character, Titulo da mensagem (obrigat�rio)
@param cFalha, character, Descri��o da falha (obrigat�rio)
@param cHelp, character, Texto de ajuda para o usu�rio saber o que fazer (Obrigat�rio)
/*/
static function Hlp( cTitulo, cFalha, cHelp )
return Help( Nil, Nil, cTitulo, Nil, cFalha, 1, 1, .F. /* lPop */, Nil /* hWnd */, Nil, Nil,;
         .F. /* lGravaLog */, { cHelp } )

/*/{Protheus.doc} runImport
Fun��o respons�vel pela importa��o dos dados
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/5/2022
@param cPathSrv, character, path completo do arquivo no servidor
@return logical, lSuccess
/*/
static function runImport( cPathSrv )
    
    local lSuccess := .T. as logical
    local oFile    := FWFileReader():New(cPathSrv )
    local aHeader  := {} as array
    local nLnFile  := 0 as numeric
    local cLine    := "" as character
    local aLine    := {} as array
    local aFile    := {} as array

    // Valida se conseguiu abrir o arquivo para leitura
    if oFile:Open()
        while oFile:hasLine()
            cLine := oFile:getLine()
            nLnFile++
            if nLnFile == 1     // Quando ler a primeira linha do arquivo, interpreta como cabe�alho
                aHeader := StrTokArr2( cLine, ';', .T. /* lEmptyCell */ )
            else
                aLine := StrTokArr2( cLine, ';', .T. )
                aAdd( aFile, aClone( aLine ) )
                aLine := {} 
            endif
        end
        oFile:Close()

        // Verifica se o arquivo tem conte�do e se o cabe�alho tamb�m est� prenchido
        if len( aFile ) > 0 .and. len( aHeader ) > 0
            Processa( {|| lSuccess := runInsert( aFile, aHeader ) }, 'Aguarde!', 'Processando informa��es...' )
        endif

    else
        lSuccess := .F.
    endif

return lSuccess

/*/{Protheus.doc} runInsert
Fun��o de inser��o dos dados na tabela de hist�rico de clientes
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param aFile, array, vetor com os dados do arquivo
@param aHeader, array, vetor com os campos do cabe�alho
@param aDePara, array, vetor com o de/para dos campos do cabe�alho do arquivo x campos da tabela
@return logical, lSuccess
/*/
static function runInsert( aFile, aHeader )
    
    local lSuccess := .T. as logical
    local nX := 0 as numeric
    local nHdr := 0 as numeric
    local nPerc := 0 as numeric

    DBSelectArea( cAliHist )
    ( cAliHist )->( DBSetOrder( 1 ) )
    if !( cAliHist )->(EOF())
        While ! ( cAliHist )->( EOF() )
            
            RecLock( cAliHist, .F. )
            ( cAliHist )->( DBDelete() )
            ( cAliHist )->( MsUnlock() )
            
            ( cAliHist )->( DBSkip() )
        enddo
    endif

    /*
    // Campos contendo informa��es em excel
    aFields := { "A1_NOME","A4_NREDUZ","B1_DESC","B1_QTELITS","C5_PROPRI","C5_XPEDCLI","D2_CF","D2_CLIENTE",;
                "D2_COD", "D2_DOC","D2_EMISSAO","D2_FILIAL","D2_LOJA","D2_PEDIDO","D2_PRCVEN","D2_QUANT",;
                "D2_SERIE","D2_TES","D2_TOTAL","D2_VALBRUT","D2_VALPROM","E4_DESCRI","F2_CLIENTE","F2_COND",;
                "F2_DOC","F2_DUPL","F2_EMISSAO","F2_FILIAL","F2_LOJA","F2_SERIE","F2_TRANSP","F2_VALBRUT",;
                "F4_TEXTO" } 
    */
    ProcRegua( len( aFile ) )

    DBSelectArea( cAliHist )
    ( cAliHist )->( DBSetOrder( 1 ) )

    for nX := 1 to len( aFile )
        nPerc := Round((nX/len( aFile ))*100,0)
        IncProc( 'Processando importa��o de dados: '+ cValToChar( nPerc ) +' %' )
        RecLock( cAliHist, .T. )
        &( cAliHist +'->'+ cAliHist +'_FILIAL' ) := deParaFil( aFile[nX][aScan(aHeader,{|x| AllTrim(x) == 'D2_FILIAL' })] )
        for nHdr := 1 to len( aHeader )
            // Verifica se conseguiu encontrar o campo do cabe�alho do arquivo no vetor de de/para
            if ( cAliHist )->( FieldPos( fn( aHeader[nHdr] ) ) ) > 0
                // Quando  estiver gravando informa��o do campo filial, � necess�rio fazer de/para
                if "FILIAL" $ aHeader[nHdr]
                    &( cAliHist +'->'+ fn( aHeader[nHdr] ) ) := deParaFil( aFile[nX][nHdr] )
                else
                    &( cAliHist +'->'+ fn( aHeader[nHdr] ) ) := changeType( aFile[nX][nHdr] /* cConteudo */, fn( aHeader[nHdr] ) /* cField */ )
                endif
            endif
        next nHdr
        ( cAliHist )->( MsUnlock() )
    next nX

return lSuccess

/*/{Protheus.doc} deParaFil
Fun��o para fazer o de/para de filial pois a filial 02 e 04 foram criadas de forma invertida no novo ambiente
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/16/2022
@param cFilHist, character, filial que veio no movimento hist�rico
@return character, cNewFil
/*/
static function deParaFil( cFilHist )
    local cNewFil := "" as character
    if cFilHist == '02'     // SC
        cNewFil := '04'
    elseif cFilHist == '04' // MG
        cNewFil := "02"
    else
        cNewFil := cFilHist
    endif
return cNewFil

/*/{Protheus.doc} changeType
Converte o conte�do capturado durante a leitura do arquivo para o formato correto do campo no sistema
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param cConteudo, character, conte�do do arquivo (obrigat�rio)
@param cField, character, campo da tabela de hist�rico do cliente (obrigat�rio)
@return variadic, xCont
/*/
static function changeType( cConteudo, cField )
    
    local xCont := Nil
    local cFieldType := FWSX3Util():GetFieldType( cField )
    
    if cFieldType == 'N'                // Num�rico
        xCont := Val( StrTran( StrTran( cConteudo, '.', '' ), ',', '.' ) )
    elseif cFieldType == 'D'            // Data
        xCont := StoD( cConteudo )
    elseif cFieldType == 'L'            // L�gico
        xCont := (cConteudo == 'T' .or. cConteudo == '.T.')
    else
        xCont := cConteudo
    endif
return xCont

/*/{Protheus.doc} fn
Fun��o para retornar o nome do campo de acordo com a tabela de hist�rico
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param cField, character, nome do campo da tabela original (obrigat�rio)
@return character, cNameNewField 
/*/
static function fn( cField )
return cAliHist +"_"+ SubStr( StrTran( cField, '_', '' ), 01, 06 )
