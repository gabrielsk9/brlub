#include 'totvs.ch'

/*/{Protheus.doc} BFFATA68
Rotina de importa��o de planilha para migra��o de carteira de clientes.
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/1/2022
/*/
user function BFFATA68()

    local cFileName := "" as character
    local lDone     := .T. as logical
    local cFalhas   := '' as character
    local nX        := 0 as numeric

    private aFalhas := {} as array
    private aFile   := {} as array

    // Captura arquivo via smartclient no terminal do usu�rio
    cFileName := cGetFile( 'Arquivo de Texto .csv (*.csv) | *.csv' /* cMascara */,;
                            'Selecione o arquivo para impotar...' /* cTitulo */,;
                            Nil /* uCompat */,;
                            "" /* cLocalIni */,;
                            .F. /* lSaveDlg */,;
                            GETF_LOCALHARD,;
                            .T. /* lTree */ )
    // Valida se usu�rio configou sele��o de algum arquivo
    if Empty( cFileName )
        return Nil
    else
        if ! File( cFileName )        // verifica se � um arquivo v�lido
            Hlp( 'Arquivo inv�lido','O arquivo selecionado/informado ['+ AllTrim( cFileName ) +'] n�o foi localizado!',;
                'Selecione ou informe um arquivo v�lido para que seja poss�vel prosseguir' )
            Return Nil
        endif
    endif

    Processa({|| aFile := readFile( cFileName ) }, 'Aguarde!', 'Iniciando leitura do arquivo')
    Processa({|| lDone := runChange( aFile ) }, 'Aguarde!', 'Processando altera��es...')

    if lDone
        MsgInfo( 'Processamento do arquivo realizado com sucesso!', 'S U C E S S O !' )
    elseif len( aFalhas ) > 0
        cFalhas := ""
        for nX := 1 to len( aFalhas )
            cFalhas += aFalhas[nX] + chr(13)+chr(10)
            if nX < len( aFalhas )
                cFalhas += Replicate( ' -', 20 ) + chr(13) + chr(10)
            endif
        next nX
        MsgAlert( 'Houveram falhas durante o processamento: '+ chr(13)+chr(10) + cFalhas, 'A T E N � � O !')
    endif

return Nil

/*/{Protheus.doc} RunChange
Fun��o para realizar o processamento das informa��es lidas a partir do arquivo
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/7/2022
@param aFile, array, vetor contendo os dados lidos no arquivo
@return logical, lDone - indica se conseguiu realizar o processamento de todos os registros
/*/
static function RunChange( aFile )
    
    local nX := 0 as numeric
    local lDone := .T. as logical
    local aReg := {} as array

    aFalhas := {}

    if len( aFile ) > 0
        ProcRegua( len( aFile ) )
        for nX := 1 to len( aFile )
            IncProc( 'Alterando cliente '+ aFile[nX][1] +'...' )
            DBSelectArea( 'SA1' )
            SA1->( DBSetOrder( 1 ) )        // A1_FILIAL + A2_COD + A1_LOJA
            if DBSeek( FWxFilial( 'SA1' ) + StrTran( aFile[nX][1], '-','' ) )
                if ! SA1->A1_VEND == aFile[nX][2] 
                    if ExistCpo( 'SA3', aFile[nX][2], 1 )
                        RecLock( 'SA1', .F. )
                        SA1->A1_VEND := aFile[nX][2]
                        // Se os campos do ICmais existirem, atualiza os campos de data e hora da ultima altera��o
                        if SA1->(FieldPos( 'A1_X_DULT' )) > 0 .and. SA1->( FieldPos( 'A1_X_HULT' ) ) > 0
                            SA1->A1_X_DULT := date()
                            SA1->A1_X_HULT := time()
                            // Valida se existe o campo que indica se o registro deve ser enviado para o ICmais
                            // e se o conte�do est� "Sim"
                            if SA1->( FieldPos( 'A1_X_ENIC' ) ) > 0 .and. SA1->A1_X_ENIC == 'S'
                                aAdd( aReg, SA1->( Recno() ) )
                            endif
                        endif
                        SA1->( MsUnlock() )
                    else
                        aAdd( aFalhas, "O codigo de vendedor "+ aFile[nX][2] +" n�o existe, � inv�lido ou foi inativado!" )
                    endif
                endif
            else
                aAdd( aFalhas, "O c�digo de cliente "+ StrTran( aFile[nX][1], '-','' ) +" n�o foi localizado!" )
            endif
        next nX
    endif
    lDone := len( aFalhas ) == 0
    if len( aReg ) > 0
        IncProc( 'Sincronizando altera��es com ICmais...' )
        ExecBlock( "ICEXPDEF", .F., .F., { 'CRMA980', '1', Nil, aReg } )
    endif

return lDone

/*/{Protheus.doc} readFile
Fun��o para realizar a leitura do arquivo e salvar em formato de vetor para poder trabalhar 
mais rapidamente em mem�ria
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/7/2022
@param cFileName, character, path do arquivo
@return array, aFile
/*/
static function readFile( cFileName )
    
    local oFile          as object
    local cLine    := "" as character
    local aLine    := {} as array
    local nTamanho := 0  as numeric
    local nLido    := 0  as numeric
    local nPercent := 0  as numeric

    aFile := {}

    // Realiza a leitura do arquivo
    oFile := FWFileReader():New( cFileName )
    if oFile:Open()
        nTamanho := oFile:GetFileSize()     // Retorna o tamanho do arquivo em bytes
        ProcRegua( nTamanho )
        nRegua   := 0
        while oFile:hasLine()
            cLine := oFile:getLine()
            aLine := StrTokArr2( cLine, ';', .T. )
            aAdd( aFile, aClone( aLine ) )
            aLine := {}
            nLido := oFile:getBytesRead()
            while nRegua < nLido
                nRegua++
                nPercent := Round((nRegua/nTamanho)*100,0)
                IncProc( 'Identificando altera��es '+ cValToChar( nPercent ) +'%' )
            enddo
        enddo
        oFile:Close()
    endif

return aFile

/*/{Protheus.doc} Hlp
Fun��o para facilitar apresenta��o de help sem necessidade de informar tantos par�metros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/4/2022
@param cTitulo, character, Titulo da mensagem (obrigat�rio)
@param cFalha, character, Descri��o da falha (opcional)
@param cHelp, character, Texto de ajuda para o usu�rio saber o que fazer (Opcional)
/*/
static function Hlp( cTitulo, cFalha, cHelp )
    default cFalha := ""
    default cHelp  := ""
return Help( Nil, Nil, cTitulo, Nil, cFalha, 1, 1, .F. /* lPop */, Nil /* hWnd */, Nil, Nil,;
         .F. /* lGravaLog */, { cHelp } )
