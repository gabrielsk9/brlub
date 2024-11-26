#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} BOLPRCFG
Fun��o principal para controle de garantias e prioridades de banco no momento da emiss�o de novos boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
/*/
user function BOLPRCFG()
    
    local aArea    := getArea()
    local oDlgPri        as object
    local aSize    := MsAdvSize()
    local bValid   :={|| .T. }
    local bConfirm :={|| iif( Confirma(), oDlgPri:End(), Nil )}
    local bCancel  :={|| oDlgPri:End() }
    local aButtons := {} as array
    local bInit    :={|| EnchoiceBar( oDlgPri, bConfirm, bCancel,,aButtons,,,.F. /*lMashups*/, .F. /*lImpCad*/, .F. /*lBotPad*/, .F. /*lConfirma*/, .F. /*lWalkthru*/ )}
    local oLayer         as object
    local cTitulo  := AllTrim(SM0->M0_FILIAL) + ' | Configurador de Prioridades do Emissor de Boletos'
    local nPerc    := Round((30/(aSize[5]/2))*100,2)
    local oWin01         as object
    local oWin02         as object
    local oBrwPri        as object
    local aHdrPri  := {} as array
    local aHdrGar  := {} as array
    local aFields  := {} as array
    local nX       := 0  as numeric
    local oBrwGar        as object
    local aFldGar  := {} as array
    local oWin03         as object
    local oWin04         as object
    local oBtEd1         as object
    local oBtEd2         as object
    local oBtNew         as object
    local oBtDel         as object
    local cOptions := "" as character

    Private cMVALPRI  := AllTrim( SuperGetMV( 'MV_X_BLPRI',,'' ) )
    Private cMVALGAR  := AllTrim( SuperGetMV( 'MV_X_BLGAR',,'' ) )
    Private cCadastro := "Crit�rios de Prioridade para Emiss�o de Boletos"

    // Valida conte�do do par�metro que vai definir o alias da tabela de prioridades na emiss�o dos boletos
    if Empty( cMVALPRI )
        Hlp( 'Crit�rios de Prioriza��o', 'Alias para configura��es de prioridades n�o configurado',;
        'Utilize o par�metro MV_X_BLPRI para definir o alias da tabela onde as prioridades ser�o configuradas.'  )
        return Nil
    endif

    // Valida a configura��o do par�metro que vai definir o alias da tabela para controle das garantias
    if Empty( cMVALGAR )
        Hlp( 'Controle de Garantias', 'Alias para configura��es e controle das garantias n�o configurado',;
        'Utilize o par�metro MV_X_BLGAR para definir o alias da tabela onde ser�o feitas as configura��es e controles das garantias.' )
        return Nil
    endif

    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

    DBSelectArea( cMVALGAR )
    ( cMVALGAR )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

    // Fun��o que faz o pr�-cadastro dos crit�rios para que o usu�rio apenas defina a prioridade entre os crit�rios
    Processa( {|| defaultInfo() }, 'Aguarde!','Verificando dados do ambiente...' )

    // Prepara os campos do cabe�alho do grid
    aFields := FWSX3Util():GetAllFields( cMVALPRI, .T. /* lVirtuais */)
    for nX := 1 to len( aFields )
        if ! "FILIAL" $ aFields[nX]
            aAdd( aHdrPri, FWBrwColumn():New() )
            aHdrPri[Len( aHdrPri )]:SetTitle( AllTrim( GetSX3Cache( aFields[nX], 'X3_TITULO' ) ) )
            aHdrPri[Len( aHdrPri )]:SetType( GetSX3Cache( aFields[nX], 'X3_TIPO' ) )
            aHdrPri[Len( aHdrPri )]:SetSize( GetSX3Cache( aFields[nX], 'X3_TAMANHO' ) )
            aHdrPri[Len( aHdrPri )]:SetDecimal( GetSX3Cache( aFields[nX], 'X3_DECIMAL' ) )
            aHdrPri[Len( aHdrPri )]:SetPicture( GetSX3Cache( aFields[nX], 'X3_PICTURE' ) )
            aHdrPri[Len( aHdrPri )]:SetData( &('{||'+ cMVALPRI +'->'+ aFields[nX]+' }' ) )
            if !Empty( GetSX3Cache( aFields[nX], 'X3_CBOX' ) )
                if Trim(aFields[nX]) == cMVALPRI +'_ID'
                    aHdrPri[Len( aHdrPri )]:SetOptions( StrTokArr( U_BLCBOID(), ';' ) )
                    aHdrPri[Len( aHdrPri )]:SetSize( MaxTamOpt( U_BLCBOID() ) )
                else
                    aHdrPri[Len( aHdrPri )]:SetOptions( StrTokArr( GetSX3Cache( aFields[nX], 'X3_CBOX' ), ';' ) )
                    aHdrPri[Len( aHdrPri )]:SetSize( MaxTamOpt( GetSX3Cache( aFields[nX], 'X3_CBOX' ) ) )
                endif
            endif
        endif
    next nX

    // Prepara os campos do cabe�alho do grid de controle de garantias
    aFldGar := FWSX3Util():GetAllFields( cMVALGAR, .T. /* lVirtuais */)
    for nX := 1 to len( aFldGar )
        if ! "FILIAL" $ aFldGar[nX]
            aAdd( aHdrGar, FWBrwColumn():New() )
            aHdrGar[Len( aHdrGar )]:SetTitle( AllTrim( GetSX3Cache( aFldGar[nX], 'X3_TITULO' ) ) )
            aHdrGar[Len( aHdrGar )]:SetType( GetSX3Cache( aFldGar[nX], 'X3_TIPO' ) )
            aHdrGar[Len( aHdrGar )]:SetSize( GetSX3Cache( aFldGar[nX], 'X3_TAMANHO' ) )
            aHdrGar[Len( aHdrGar )]:SetDecimal( GetSX3Cache( aFldGar[nX], 'X3_DECIMAL' ) )
            aHdrGar[Len( aHdrGar )]:SetPicture( GetSX3Cache( aFldGar[nX], 'X3_PICTURE' ) )
            aHdrGar[Len( aHdrGar )]:SetData( &('{||'+ cMVALGAR +'->'+ aFldGar[nX]+' }' ) )
            if !Empty( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) )
                // Quando houver fun��o para retornar o conte�do do combo, trata manualmente
                if '#' $ GetSX3Cache( aFldGar[nX], 'X3_CBOX' )
                    cOptions := &( StrTran( AllTrim( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) ), '#','') )
                    aHdrGar[Len( aHdrGar )]:SetOptions( StrTokArr( cOptions, ';' ) )
                else
                    aHdrGar[Len( aHdrGar )]:SetOptions( StrTokArr( &(GetSX3Cache( aFldGar[nX], 'X3_CBOX' )), ';' ) )
                endif
                aHdrGar[Len( aHdrGar )]:SetSize( MaxTamOpt( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) ) )
            endif
        endif
    next nX

    // Define cria��o de um Dialog utilizando toda a �rea de tela dispon�vel
    oDlgPri := TDialog():New( aSize[1],aSize[2],aSize[6],aSize[5],cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
    // Monta recurso de camadas para facilitar acomoda��o dos objetos
    oLayer := FWLayer():new()
    oLayer:Init( oDlgPri )
    oLayer:AddColumn( 'Col01', 100-((30/(aSize[6]/2))*100), .T. )
    oLayer:AddColumn( 'Col02', ((30/(aSize[6]/2))*100), .T. )
    oLayer:AddWindow( 'Col01', 'Win01', 'Crit�rios de Prioriza��o', 50-nPerc, .F., .T., {|| },,)
    oLayer:AddWindow( 'Col01', 'Win02', 'Controle de Garantias', 50-nPerc, .F., .T., {|| },,)
    oLayer:AddWindow( 'Col02', 'Btn01', 'Menu', 50-nPerc, .F., .T., {|| },, )
    oLayer:AddWindow( 'Col02', 'Btn02', 'Menu', 50-nPerc, .F., .T., {|| },, )
    oWin01 := oLayer:GetWinPanel( 'Col01', 'Win01' )        // Grid superior
    oWin02 := oLayer:GetWinPanel( 'Col01', 'Win02' )        // Grid inferior
    oWin03 := oLayer:GetWinPanel( 'Col02', 'Btn01' )        // Bot�es do lado direito superior
    oWin04 := oLayer:GetWinPanel( 'Col02', 'Btn02' )        // Bot�es do lado direiti inferior

    // Monta grid para edi��o das prioridades em rela��o ao crit�rio
    oBrwPri := FWBrowse():New( oWin01 )
    oBrwPri:SetDataTable()
    oBrwPri:SetAlias( cMVALPRI )
    oBrwPri:DisableConfig()
    oBrwPri:DisableSeek()
    oBrwPri:DisableSaveConfig()
    oBrwPri:DisableReport()
    oBrwPri:AddStatusColumns( {|| "UP_MDI.PNG"  }, {|| changePos( oBrwPri, "+" ) } )
    oBrwPri:AddStatusColumns( {|| "DOWN_MDI.PNG" }, {|| changePos( oBrwPri, "-" ) } )
    oBrwPri:SetColumns( aHdrPri )
    oBrwPri:Activate(.T.)

    // Define o grid da edi��o dos valores de garantias a serem controlados
    oBrwGar := FWBrowse():New( oWin02 )
    oBrwGar:SetDataTable()
    oBrwGar:SetAlias( cMVALGAR )
    oBrwGar:DisableConfig()
    oBrwGar:DisableSeek()
    oBrwGar:DisableSaveConfig()
    oBrwGar:DisableReport()
    oBrwGar:AddStatusColumns( { || "UP_MDI.PNG" }, {|| changePos( oBrwGar, "+" ) } )
    oBrwGar:AddStatusColumns( { || "DOWN_MDI.PNG" }, {|| changePos( oBrwGar, "-" ) } )
    oBrwGar:SetColumns( aHdrGar )
    oBrwGar:Activate(.T.)

    // Bot�es do browse superior para aumentar/diminuir prioridade
    oBtEd1 := TButton():New( 002, 002, "&Editar",oWin03,{|| cCadastro := "Crit�rios de Prioridade - Editar Prioridade",;
                                                        AxAltera( oBrwPri:GetAlias(), (oBrwPri:GetAlias())->(Recno()), 4 ),;
                                                        oBrwPri:Refresh(.T.) }, (oWin03:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    
    // Bot�es do browse inferior para aumentar/diminuir prioridade em rela��o aos demais registros
    oBtNew := TButton():New( 002, 002, "&Incluir" ,oWin04,{|| cCadastro := "Controle de Garantias - Incluir",;
                                                        AxInclui( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 3 ),;
                                                        oBrwGar:Refresh(.T.) }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtEd2 := TButton():New( 020, 002, "&Alterar" ,oWin04,{|| cCadastro := "Controle de Garantias - Alterar",;
                                                        AxAltera( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 4 ),;
                                                        oBrwGar:Refresh(.T.) }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtDel := TButton():New( 038, 002, "E&xcluir" ,oWin04,{|| cCadastro := "Controle de Garantias - Excluir",;
                                                        AxDeleta( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 5 ),;
                                                        (oBrwGar:GoBottom(.T.)),; 
                                                        (oBrwGar:GoTop(.T.)),; 
                                                        oBrwGar:Refresh(.T.),;
                                                        oDlgPri:Refresh() }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDlgPri:Activate(,,,.T., bValid,,bInit )

    restArea( aArea )
return Nil

/*/{Protheus.doc} BOLVALID
Valid dos campos da tabela de crit�rios de prioridades
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, ID de identifica��o interna dos campos
@return logical, lValidated
/*/
user function BOLVALID( cField )
    local lValidated := .T.
    if cField == 'BCO'
        if Empty( &( 'M->' + cMVALPRI + '_BCO' ) )
            &( 'M->' + cMVALPRI + '_AGE' ) := " "
            &( 'M->' + cMVALPRI + '_CTA' ) := " "
            &( 'M->' + cMVALPRI + '_SUB' ) := " "
        else
            lValidated := ExistCpo( "SEE", &( 'M->' + cMVALPRI + '_BCO' ), 1 )
        endif
    endif
return lValidated

/*/{Protheus.doc} BOLWHEN
When dos campos da tabela de crit�rios de prioriza��o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, ID de identifica�ao interna dos campos
@return logical, lWhen
/*/
user function BOLWHEN( cField )
    local lWhen := .T.
    if cField == 'BCO'
        // Libera edi��o do banco apena quando for para o Banco Padr�o definido pelo Financeiro
        lWhen := &( 'M->' + cMVALPRI + '_ID' ) == 'BF'
    endif
return lWhen

/*/{Protheus.doc} MaxTamOpt
Fun��o para encontrar o tamanho m�ximo de um campo do tipo combo para setar tamanho do campo no browse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2022
@param cOptions, character, conte�do do combo
@return numeric, nMax
/*/
static function MaxTamOpt( cOptions )
    local nMax := 1 as numeric
    local aOptions := StrTokArr(AllTrim( iif( '#' $ cOptions, &( StrTran( cOptions, '#','' ) ), cOptions ) ),";")
    aEval( aOptions, {|x| nMax := iif( nMax > len( AllTrim(StrTokArr( x, '=' )[2]) ), nMax, len( AllTrim(StrTokArr( x, '=' )[2]) ) ) } )
return nMax

/*/{Protheus.doc} changePos
Fun��o para aumentar/diminuir prioridade em rela��o aos demais registros do browse posicionado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 03/09/2022
@param oBrowse, object, Objeto do browse que deve receber a altera��o
@param cUpDown, character, + (deve aumentar a prioridade) - (deve diminuir a prioridade)
/*/
static function changePos( oBrowse, cUpDown )
    
    local cAli := oBrowse:GetAlias()
    local cPrior  := &( cAli +'->'+ cAli + '_PRIOR' )
    local cNewPrior := "" as chracter
    local nRecAtu := ( cAli )->( Recno() )
    
    if !( cAli )->( EOF() ) .or. !Empty( cPrior )

        ( cAli )->( DBSkip( iif( cUpDown == "+", -1, 1 ) ) )
        
        if ( cAli )->( Recno() ) != nRecAtu .and. ! ( cAli )->( EOF() ) 
            
            cNewPrior := &( cAli +'->'+ cAli +'_PRIOR' )
            nRecNext  := ( cAli )->( Recno() )
            
            RecLock( cAli, .F. )
            &( cAli +'->'+ cAli +'_PRIOR' ) := cPrior
            ( cAli )->( MsUnlock() )
            
            ( cAli )->( DBGoTo( nRecAtu ) )
            RecLock( cAli, .F. )
            &( cAli +'->'+ cAli +'_PRIOR' ) := cNewPrior
            ( cAli )->( MsUnlock() )

        endif

        ( cAli )->( DbGoTop() )
        oBrowse:Refresh(.T.)
        
        if nRecAtu > 0
            ( cAli )->( DbGoTo( nRecAtu ) )
            oBrowse:GoTo( nRecAtu )
        endif

    endif
    

return Nil

/*/{Protheus.doc} defaultInfo
Fun��o para cadastrar automaticamente os crit�rios de prioridade na tabela 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
/*/
static function defaultInfo()

    local aDefault := {} as array
    local cID      := "" as character
    local nX       := 0  as numeric
    local cPrior   := LastPrior()
    
    // Captura informa��es do combo
    aDefault := StrTokArr( AllTrim( U_BLCBOID() ), ';' )
    
    // Define o tamanho da r�gua de processamento
    ProcRegua( len( aDefault ) )

    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder( 1 ) )       // FILIAL + ID

    if len( aDefault ) > 0
        for nX := 1 to len( aDefault )
            
            // Comando evolu��o da r�gua de processamento
            IncProc('Avaliando crit�rio '+ cValToChar(nX) +'/'+ cValToChar( len( aDefault ) ) )

            // Formata o ID com o tamanho necess�rio para o campo
            cID   := PADR(StrTokArr( aDefault[nX],'=' )[1],TAMSX3( cMVALPRI +'_ID' )[1], ' ')

            // Verifica se consegue encontrar o crit�rio cadastrado na tabela
            if ! ( cMVALPRI )->( DBSeek( FWxFilial( cMVALPRI ) + cID ) )
                
                // Incrementa sequencial
                cPrior := Soma1( cPrior )

                RecLock( cMVALPRI, .T. )
                &(cMVALPRI +'->'+ cMVALPRI +'_FILIAL') := FWxFilial( cMVALPRI )
                &(cMVALPRI +'->'+ cMVALPRI +'_ID')     := cID
                &(cMVALPRI +'->'+ cMVALPRI +'_PRIOR')  := cPrior
                ( cMVALPRI )->( MsUnlock() )

            endif

        next nX

    endif

    // Devolve o indice utilizado para correta ordena��o dos registros no browse
    ( cMVALPRI )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

return Nil

/*/{Protheus.doc} LastPrior
Seleciona a maior prioridade gravada na tabela de crit�rios
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
@return character, cLast
/*/
static function LastPrior()
    
    local cLast := "" as character
    
    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder(2))      // FILIAL + PRIOR
    ( cMVALPRI )->( LastRec() )
    cLast := &( cMVALPRI +'->'+ cMVALPRI +'_PRIOR' )
    
return cLast

/*/{Protheus.doc} BLLSTGAR
Fun��o para identificar a �ltima prioridade cadastrada no grid de controle de garantias
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2022
@return character, cLastGar
/*/
user function BLLSTGAR()
    
    local cLastGar := StrZero( 0, TAMSX3( cMVALGAR +'_PRIOR' )[1] )
    
    // Posiciona na tabela de controle de garantias com o �ndice setado por prioridade
    DBSelectArea( cMVALGAR )
    ( cMVALGAR )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR
    ( cMVALGAR )->( LastRec() )
    
    // Se retornar conte�do vazio � porque a tabela est� vazia
    if !Empty( &( cMVALGAR +'->'+ cMVALGAR + '_PRIOR' ) )
        cLastGar := &( cMVALGAR +'->'+ cMVALGAR + '_PRIOR' )
    endif

return cLastGar

/*/{Protheus.doc} Confirma
Fun��o de confirma��o do Dialog de configura��o das prioridades do emissor de boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 01/09/2022
@return logical, lConfirm
/*/
static function Confirma()
    local lConfirm := .T.
return lConfirm

/*/{Protheus.doc} hlp
FUn��o simplificada para apresenta��o do help
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/19/2022
@param cTitulo, character, t�tulo da mensagem
@param cMensagem, character, descricao da mensagem
@param cHelp, character, texto de ajuda
/*/
static function hlp( cTitulo, cMensagem, cHelp )
return Help( ,, cTitulo,, cMensagem, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} U_BOLGARCT
Fun��o para adicionar ou remover valor do controle de garantias
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@param aRatedTit, array, vetor contendo os dados do t�tulo com banco, agencia e conta definidos para impress�o do boleto
@param lSum, logical, indica se deve somar ou subtrair (.T. Somar ou .F. Subtrair) (default .T.)
@since 03/10/2022
/*/
function U_BOLGARCT( aRatedTit, lSum )

    local aArea := getArea()
    
    private cMVALGAR := AllTrim( SuperGetMV( 'MV_X_BLGAR',,'' ) )       // Alias da tabela de controle de garantias

    default aRatedTit := {}
    default lSum      := .T.

    // Executa apenas se existir defini��o para o alias de controle de garantias e se o par�metro do t�tulo veio preenchido
    if !Empty( cMVALGAR ) .and. len( aRatedTit ) > 0 .and. gt( aRatedTit, 'banco' ) != Nil

        // Controle de garantias, verifica se tem controle de garantia ativa para a conta utilizada para emitir o boleto
        DBSelectArea( cMVALGAR )
        ( cMVALGAR )->( DBSetOrder( 1 ) )       // FILIAL + BCO + AGE + CTA + SUB
        if ( cMVALGAR )->( DBSeek( FWxFilial( cMVALGAR ) + gt( aRatedTit, 'banco' ) + gt( aRatedTit, 'agencia' ) +;
            gt( aRatedTit, 'conta' ) + gt( aRatedTit, 'subconta' ) ) )

            // Verifica se o registro do controle de garantias est� dentro da faixa de datas programada para o controle
            if &( cMVALGAR +'->'+ cMVALGAR + '_DTINI' ) <= dDataBase .and.;
                ( Empty( &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) ) .or. &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) >= dDataBase ) 
                
                // Verifica se � impress�o de novo boleto ou exclus�o de novo boleto
                if !lSum                            // Exclus�o ou cancelamento de opera��o somada anteriormente
                    RecLock( cMVALGAR, .F. )
                    &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) -= gt( aRatedTit, 'valor' )
                    ( cMVALGAR )->( MsUnlock() )
                    ConOut( 'BOLGARCT - '+ DtoC( date() ) +' '+ Time() +' - BCO: '+ gt( aRatedTit, 'banco' ) +;
                                                                       ' AGE: '+ gt( aRatedTit, 'agencia' ) +;
                                                                       ' CTA: '+ gt( aRatedTit, 'conta' ) +;
                                                                       ' SUB: '+ gt( aRatedTit, 'subconta' ) +;
                                                                       ' R$: '+ AllTrim( Transform( gt( aRatedTit, 'valor' )*-1, '@E 999,999,999.99' ) ) )
                elseif &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) < &( cMVALGAR +'->'+ cMVALGAR + '_VLALVO' )     // Valor atingido ainda � menor do que o valor alvo
                    // Verifica se n�o � uma reimpress�o
                    if gt( aRatedTit, 'reimpressao' ) == Nil .or. ( gt( aRatedTit, 'reimpressao' ) <> Nil .and. ! gt( aRatedTit, 'reimpressao' ) )
                        RecLock( cMVALGAR, .F. )
                        &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) += gt( aRatedTit, 'valor' )
                        ( cMVALGAR )->( MsUnlock() )
                        ConOut( 'BOLGARCT - '+ DtoC( date() ) +' '+ Time() +' - BCO: '+ gt( aRatedTit, 'banco' ) +;
                                                                       ' AGE: '+ gt( aRatedTit, 'agencia' ) +;
                                                                       ' CTA: '+ gt( aRatedTit, 'conta' ) +;
                                                                       ' SUB: '+ gt( aRatedTit, 'subconta' ) +;
                                                                       ' R$: '+ AllTrim( Transform( gt( aRatedTit, 'valor' ), '@E 999,999,999.99' ) ) )
                    endif
                endif

            endif

        endif

    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} gt
Fun��o para retornar informa��o de uma posicao de um vetor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 03/10/2022
@param aRef, array, vetor de referenncia
@param cKey, variant, chave a ser retornada
@return variadic, xInfo
/*/
static function gt( aRef, cKey )
return iif( aScan( aRef, {|x| AllTrim( x[1] ) == cKey } ) > 0,;
            aRef[ aScan( aRef, {|x| AllTrim( x[1] ) == cKey } ) ][2],;
            Nil )

/*/{Protheus.doc} BLCBOID
Fun��o respons�vel pela exibi��o das informa��es do combo de IDs de crit�rios de prioridade
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 01/09/2022
@return character, cOptions
/*/
user function BLCBOID()
    local cOptions := "" as character
    cOptions := "BC=Banco Preferencial do Cliente;"+;
                "BU=Banco Escolhido pelo Usu�rio;"+;
                "CG=Cobertura de Garantias;"+;
                "BF=Banco Escolhido pelo Financeiro"
return cOptions
