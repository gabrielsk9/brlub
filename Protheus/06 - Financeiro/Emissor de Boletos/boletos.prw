#INCLUDE "totvs.ch"
#INCLUDE "TOPCONN.ch"
#INCLUDE "TBICONN.CH"    
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"    
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH" 
#INCLUDE "PARMTYPE.CH"   
#DEFINE PAD_LEFT            0
#DEFINE PAD_RIGHT           1
#DEFINE PAD_CENTER          2                             

#define DIRCONTROL 	"/boletos/"
#define CDIRSRV		"/boletos/"
#define CLOCPDF 	GetTempPath(.T.)		// diret�rio tempor�rio do usu�rio no smartclient
#define BANK_HOM 	"001/004/033/041/104/224/237/246/320/341/399/422/623/637/655/707/745/748/756"	// Bancos com cobran�a homologada para emiss�o de boleto
#define MAX_LOCK 	60		// Quantidade m�xima de vezes que o sistema deve mandar o usu�rio aguardar at� desbloquear e deixar o usu�rio atual prosseguir
#define SEGUNDOS 	2		// Quantidade (em segundos) que o sistema deve pedir que o usu�rio aguarde at� uma nova checagem para ver se o outro usu�rio ainda est� processando os boletos
#define ESP_LINE 	20		// tamanho em pixel da espessura da linha
#define COL_INI  	35		// quantidade de pixels para o in�cio da escrita (da esquerda para a direita)
#define H_LEFT   	0		// identa��o � esquerda
#define H_RIGHT  	1 		// identa��o � direita
#define H_CENTER 	2		// identa��o centralizada (horizontal)
#define V_CENTER 	0		// identa��o centralizada (vertical)
#define V_TOP    	1		// alinhado ao topo
#define V_BOTTOM 	2		// alinhamento inferior
#define CLR_HGREY 	RGB(211,211,211)	// LightGray
#define BANRISUL    "041"	// C�digo do banco Banrisul

/*/{Protheus.doc} Boletos
Rotina padr�o GMAD para emiss�o e reimpress�o de boletos
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 30/05/2012
@param _cCli, character, codigo do cliente quando impress�o autom�tica
@param _cLoja, character, loja do cliente para impress�o autom�tica
@param _cDoc, character, n�mero do t�tulo para impress�o autom�tica
@param _cPref, character, prefixo para impressao autom�tica
@param _cBco, character, c�digo do banco para emiss�o autom�tica
@param _cAge, character, c�digo da ag�ncia para impress�o autom�tica
@param _cCta, character, c�digo da conta para impress�o autom�tica
@param _cSubCta, character, c�digo da subconta (parametros de banco) para impress�o autom�tica
@param _lAuto, logical, indica se a chamada est� sendo feita por rotina autom�tica
@param oDanfe, object, objeto do danfe quando a impress�o autom�tica for chamada pela impress�o de NFe
@return array, aResult[lSuccess, aFiles, aMessages]
/*/
User Function Boletos(_cCli,_cLoja,_cDoc,_cPref,_cBco,_cAge,_cCta,_cSubCta,_lAuto, oDanfe, _cParc)

	Local aMarked      := {}
	local oDlg         := Nil
	local nDlgHor      := MsAdvSize()[5]				// Tamanho na horizontal em pixels (90% do tamanho da resolu��o)
	local nDlgVer      := MsAdvSize()[6]				// Tamanho na vertical em pixels
	local aButtons     := {}
	local aCampos      := {}
	local oBrw         := Nil
	local oGroup       := Nil
	local lSuccess     := .F.
	local aMsg         := {}
	local cMsg         := "" as character
	local aFiles       := {}
	local aValid       := {} as array
	local nLock        := 0 as numeric
	local oLayer       as object

	Private cMarca     := GetMark()                    // Busca aleatoriamente uma marca para atribuir ao browses
	Private cPerg      := Padr("BOLETOS",len(SX1->X1_GRUPO))

	default _lAuto   := .F.
	default _cBco    := Space(TAMSX3("EE_CODIGO" )[1])
	default _cAge    := Space(TAMSX3("EE_AGENCIA")[1])
	default _cCta    := Space(TAMSX3("EE_CONTA"  )[1])
	default _cSubSta := Space(TAMSX3("EE_SUBCTA" )[1])

	// Verifica a exist�ncia do grupo de perguntas da rotina antes de prosseguir, e faz a cria��o de forma autom�tica, caso necess�rio
	validPerg(cPerg)

	// Adiciona bot�es personalizados na enchoiceBar
	aAdd( aButtons, { "FILTER", {|| FilterEdit( cPerg, oBrw ) }, "Editar Filtro", "Editar Filtro", {||.T. } } )
	aAdd( aButtons, { "CONFIG", {|| U_BOLPRCFG() }, "Prioridades de faturamento", "Prioridades de Faturamento", {|| .T. } } )

	if ! _lAuto .and. ! pergunte( cPerg, ! _lAuto )
		aAdd( aMsg, "Opera��o cancelada pelo usu�rio..." )
		return { lSuccess, aFiles, aMsg }
	elseif _lAuto
		// Atribui aos par�metros as vari�veis recebidas pela fun��o para impress�o autom�tica
		pergunte( cPerg, .F. )
		MV_PAR01 := PADR( AlLTrim( _cPref ), TAMSX3( 'E1_PREFIXO' )[1] )
		MV_PAR02 := PADR( AlLTrim( _cPref ), TAMSX3( 'E1_PREFIXO' )[1] )
		MV_PAR03 := PADR( AlLTrim( _cDoc ), TAMSX3( 'E1_NUM' )[1] )
		MV_PAR04 := PADR( AlLTrim( _cDoc ), TAMSX3( 'E1_NUM' )[1] )
		if _cParc <> Nil
			MV_PAR05 := PADR( AlLTrim( _cParc ), TAMSX3( 'E1_PARCELA' )[1] )
			MV_PAR06 := PADR( AlLTrim( _cParc ), TAMSX3( 'E1_PARCELA' )[1] )
		else
			MV_PAR05 := Space( TAMSX3( 'E1_PARCELA' )[1] )
			MV_PAR06 := Replicate( 'Z' , TAMSX3( 'E1_PARCELA' )[1] )
		endif
		MV_PAR07 := Space( TAMSX3( 'E1_CLIENTE' )[1] )
		MV_PAR08 := Replicate( 'Z' , TAMSX3( 'E1_CLIENTE' )[1] )
		MV_PAR09 := Space( TAMSX3( 'E1_LOJA' )[1] )
		MV_PAR10 := Replicate( 'Z' , TAMSX3( 'E1_LOJA' )[1] )
		MV_PAR11 := PADR( AllTrim( _cBco ), TAMSX3("EE_CODIGO")[1], " " )
		MV_PAR12 := PADR( AllTrim( _cAge ), TAMSX3("EE_AGENCIA")[1], " " )
		MV_PAR13 := PADR( AllTrim( _cCta ), TAMSX3("EE_CONTA" )[1], " " )
		MV_PAR14 := PADR( AllTrim( _cSubCta ), TAMSX3("EE_SUBCTA")[1], " " )
	endif

	// Chama fun��o que valida se o banco est� preparado para emiss�o de boleto
	aValid := validBco()
	if ! aValid[1]
		if !isBlind()
			Help( ,, 'Banco N�o Homologado',, aValid[2], 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{ 'Utilize outro banco ou verifique com a pessoa respons�vel a possibilidade de configurar o banco pretendido.' } )
		endif
		aAdd( aMsg, aValid[2] )
		return { lSuccess, aFiles, aMsg }
	endif

	if ! _lAuto

		oDlg := TDialog():New( 0,0,nDlgVer,nDlgHor, AllTrim( SM0->M0_FILIAL ) +' - Painel de Emiss�o de Boletos',,,,,CLR_BLACK,CLR_WHITE,,,.T. )
		
		// Inicializa o gerenciador das camadas
		oLayer := FWLayer():New()
		oLayer:Init( oDlg )	// Vincula ao Dlg principal
		oLayer:AddCollumn( 'TITULOS', 100, .T. )		// Add coluna com o restante do tamanho para os t�tulos selecionados
		oLayer:AddWindow( 'TITULOS', 'TITULO', 'Titulos Filtrados', TamByPerc( nDlgVer, nDlgVer-60 ), .F., .T., {|| },, )
		oGroup  := oLayer:GetWinPanel( 'TITULOS', 'TITULO' )	// Identifica a janela dos t�tulos

		// Define montagem do grid dos pedidos de retira
		oBrw := FWBrowse():New( oGroup )
		oBrw:SetDataQuery( .T. )
		oBrw:SetAlias( "TITTMP" )
		oBrw:SetQuery( doQuery() )
		oBrw:DisableConfig()
		oBrw:DisableReport()
		oBrw:SetClrAlterRow( RGB(220,220,220) )

		// Adiciona regra de marca��o
		oBrw:AddMarkColumns( {|oBrw| if( TITTMP->MARK == cMarca, 'LBOK','LBNO' ) },{|oBrw| fMark( 'TITTMP' /* cAlias */, .F. /*lAll*/, oBrw ) },{|oBrw| fMark( 'TITTMP' /* cAlias */, .T. /*lAll*/, oBrw ) })
		oBrw:GetColumn(1):SetReadVar( 'TITTMP->MARK' )
		// Configura duplo-click
		oBrw:SetDoubleClick( {|oBrw| fMark( 'TITTMP' /* cAlias */, .F. /*lAll*/, oBrw ) } )
		
		// Adiciona legendas ao browse de t�tulos
		oBrw:AddLegend( "Empty( E1_PORTADO ) .or. Empty( E1_NUMBCO )", "BR_VERMELHO", "Boleto n�o impresso" )
		oBrw:AddLegend( "!Empty( E1_PORTADO ) .and. !Empty( E1_NUMBCO )", "BR_VERDE", "Boleto impresso" )

		// Adiciona os campos a serem exibidos no browse
		aCampos := {}
		aAdd( aCampos, {{ 'Banco'    , &('{|| iif( !Empty( E1_NUMBCO ), E1_PORTADO, " " ) }'), 'C', '@!', 1, TAMSX3('E1_PORTADO')[01], TAMSX3('E1_PORTADO')[02] }} )
		aAdd( aCampos, {{ 'Pref'     , &('{|| E1_PREFIXO  }'), 'C', '@!', 1, TamSX3("E1_PREFIXO" )[01], TamSX3("E1_PREFIXO" )[02] }} )
		aAdd( aCampos, {{ 'Numero'   , &('{|| E1_NUM      }'), 'C', '@!', 1, TamSX3("E1_NUM"     )[01], TamSX3("E1_NUM"     )[02] }} )
		aAdd( aCampos, {{ 'Parc.'    , &('{|| E1_PARCELA  }'), 'C', '@!', 1, TamSX3("E1_PARCELA" )[01], TamSX3("E1_PARCELA" )[02] }} )
		aAdd( aCampos, {{ 'Tipo'     , &('{|| E1_TIPO     }'), 'C', '@!', 1, TamSX3("E1_TIPO"    )[01], TamSX3("E1_TIPO"    )[02] }} )
		aAdd( aCampos, {{ 'Cliente'  , &('{|| E1_CLIENTE  }'), 'C', '@!', 1, TamSX3("E1_CLIENTE" )[01], TamSX3("E1_CLIENTE" )[02] }} )
		aAdd( aCampos, {{ 'Loja'     , &('{|| E1_LOJA     }'), 'C', '@!', 1, TamSX3("E1_LOJA"    )[01], TamSX3("E1_LOJA"    )[02] }} )
		aAdd( aCampos, {{ 'Fantasia' , &('{|| E1_NOMCLI   }'), 'C', '@!', 1, TamSX3("E1_NOMCLI"  )[01], TamSX3("E1_NOMCLI"  )[02] }} )
		aAdd( aCampos, {{ 'Valor'    , &('{|| E1_VALOR    }'), 'N', PesqPict( 'SE1', 'E1_VALOR' ), 2, TamSX3("E1_VALOR"  )[01], TamSX3("E1_VALOR"  )[02] }} )
		aAdd( aCampos, {{ 'Saldo'    , &('{|| E1_SALDO    }'), 'N', PesqPict( 'SE1', 'E1_SALDO' ), 2, TamSX3("E1_SALDO"  )[01], TamSX3("E1_SALDO"  )[02] }} )
		aAdd( aCampos, {{ 'Vencto'   , &('{|| StoD(E1_VENCTO)   }'), 'D', '@D', 2, TamSX3("E1_VENCTO"  )[01], TamSX3("E1_VENCTO"  )[02] }} )
		aAdd( aCampos, {{ 'Venc.Real', &('{|| StoD(E1_VENCREA)  }'), 'D', '@D', 2, TamSX3("E1_VENCREA" )[01], TamSX3("E1_VENCREA" )[02] }} )
		aAdd( aCampos, {{ 'Num.Bco'  , &('{|| E1_NUMBCO   }'), 'C', '@!', 1, TamSX3("E1_NUMBCO" )[01], TamSX3("E1_NUMBCO" )[02] }} )
		aEval( aCampos, {|x| oBrw:SetColumns( aClone( x ) ) } )
		oBrw:Activate()

		oDlg:Activate(,,,.T.,{||.T.},,{|| EnchoiceBar(oDlg,{|| aMarked := fGetSel( oBrw ), oDlg:End() },{||oDlg:End()},,@aButtons) } )

		// Executa fechamento do arquivo tempor�rio
		if select( "TITTMP" ) > 0
			TITTMP->( DBCloseArea() )
		endif

	Else			// Na impress�o autom�tica, simplesmente faz o select e busca o conte�do sem apresentar a Dialog

		// Quando n�o utiliza interface, cria apenas a tabela tempor�ria
		DBUseArea( .T. /*lNew*/, "TOPCONN", TcGenQry( ,,doQuery() ), "TITTMP", .F. /*lShared*/, .T. /*lReadOnly*/ )

		if !TITTMP->( EOF() )
			aMarked := {}
			while !TITTMP->( EOF() )

				DBSelectarea( 'SE1' )
				SE1->( DBGoTo( TITTMP->RECSE1 ) )

				aAdd( aMarked, TITTMP->RECSE1 )
				TITTMP->( DBSkip() )
			end
		endif
		TITTMP->( DBCloseArea() )

	endif

	// Vari�vel para controlar a quantidade de vezes que a solicita��o foi negada antes de eliminar o lock existente
	nLock := 0

	// Quando a execu��o n�o for autom�tica, solici
	If Len( aMarked ) > 0 .and. ! _lAuto

		// Controle de sem�foto para que um usu�rio n�o consiga gerar boletos no mesmo momento em que outro usu�rio estiver gerando para a mesma empresa
		// While !U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .F. /*lUnlock*/ )[1]
		// 	Processa({|| fAguarda(SEGUNDOS) }, "Aguarde...", "O usu�rio "+ AllTrim( U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .F. /*lUnlock*/ )[4] ) +" est� emitindo boleto, a rotina vai aguardar 2 segundos e tentar novamente!", .F.)
		// 	nLock++
		// 	// Quando atingir a quantidade m�xima de esperas, libera o sistema para que o usu�rio atual prossiga
		// 	if nLock >= MAX_LOCK
		// 		U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .T. /*lUnlock*/ )
		// 		nLock := 0
		// 	endif
		// EndDo
		RptStatus({|| aFiles := MontaRel(aMarked, nil, _lAuto, @aMsg)}, "Aguarde...", "Gerando Boletos...", .T.)
		// U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .T. /*lUnlock*/ )

	ElseIf Len( aMarked ) > 0 .and. _lAuto

		// Controle de sem�foto para que um usu�rio n�o consiga gerar boletos no mesmo momento em que outro usu�rio estiver gerando para a mesma empresa
		// While !U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .F. /*lUnlock*/ )[1]

		// 	// Verifica se a execu��o est� ocorrendo sem interface
		// 	if IsBlind()
		// 		ConOut( "O usu�rio "+ AllTrim( U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .F. /*lUnlock*/ )[4] ) +" est� emitindo boleto, a rotina vai aguardar 2 segundos e tentar novamente!" )
		// 		Sleep( SEGUNDOS*1000 )
		// 	else
		// 		Processa({|| fAguarda(SEGUNDOS) }, "Aguarde...", "O usu�rio "+ AllTrim( U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .F. /*lUnlock*/ )[4] ) +" est� emitindo boleto, a rotina vai aguardar 2 segundos e tentar novamente!", .F.)
		// 	endif

		// 	nLock++
		// 	// Quando atingir a quantidade m�xima de esperas, libera o sistema para que o usu�rio atual prossiga
		// 	if nLock >= MAX_LOCK
		// 		U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .T. /*lUnlock*/ )
		// 		nLock := 0
		// 	endif

		// Enddo

		// Chama fun��o de impress�o
		aFiles := MontaRel(aMarked, @oDanfe, _lAuto, @aMsg )
		// U_CTLCKEXE( DIRCONTROL,"boletos" + cEmpAnt +'.key', .T. /*lUnlock*/ )

	Endif

	// Mostra mensagens de processamento ao final da rotina.
	if Len(aMsg) > 0
		lSuccess := .F.
		if _lAuto
			Conout( 'BOLETOS - '+ DtoC( Date() ) +' - '+ Time() +' - OCORRERAM FALHA DURANTE EXECUCAO ' )
			aEval( aMsg, {|x| ConOut( 'BOLETOS - '+ DtoC( Date() ) +' - '+ Time() +': '+ x ) } )
		else
			cMsg := ""
			aEval( aMsg, {|x| cMsg += x + chr(13)+chr(10) } )
			MsgStop( 'Ocorreram falhas durante a execu��o: '+ chr(13)+chr(10) + cMsg, 'A T E N � � O' )
		endif
	elseif len( aFiles ) == 0		// Se n�o retornou mensagem de erro, mas tamb�m n�o retornou nenhum boleto, a execu��o foi sem sucesso
		lSuccess := .F.
		aAdd( aMsg, "N�o houve retorno de boletos gerados pela rotina" )
	elseif len( aFiles ) > 0		// Se retornou conte�do de boletos gerados, o processamento ocorreu com sucesso
		lSuccess := .T.
	EndIf

Return { lSuccess, aFiles, aMsg }

/*/{Protheus.doc} FilterEdit
Fun��o para atualizar os dados do grid da tela com base nos par�metros informados pelo usu�rio atrav�s do bot�o Outras A��es
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/21/2022
@param cPerg, character, grupo de perguntas da rotina
@param oBrowse, object, objeto do browse
/*/
static function FilterEdit( cPerg, oBrowse )
	if Pergunte( cPerg, .T. )
		oBrowse:SetQuery( doQuery() )
		( oBrowse:GetAlias() )->( DbGoTop() )
		oBrowse:Refresh(.T.)
	endif
return Nil

/*/{Protheus.doc} doQuery
fun��o que edita query com base nos par�metros e filtros informados pelo usu�rio
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/21/2022
@return character, cQuery
/*/
static function doQuery()
	
	local cQuery := "" as character
	
	// Define query para leitura dos t�tulos
	cQuery := "SELECT "
	cQuery += " '  ' MARK, "
	cQuery += " R_E_C_N_O_ RECSE1, "
	cQuery += " E1.E1_PREFIXO, "
	cQuery += " E1.E1_NUM, "
	cQuery += " E1.E1_PARCELA, "
	cQuery += " E1.E1_TIPO, "
	cQuery += " E1.E1_CLIENTE, "
	cQuery += " E1.E1_LOJA, "
	cQuery += " E1.E1_NOMCLI, "
	cQuery += " E1.E1_VALOR, "
	cQuery += " E1.E1_SALDO, "
	cQuery += " E1_VENCTO, "
	cQuery += " E1_VENCREA, "
	cQuery += " E1_PORTADO, "
	cQuery += " E1_NUMBCO "
	cQuery += " FROM "+ RetSqlName( 'SE1' ) +" E1 "

	cQuery += "WHERE E1.E1_FILIAL = '"+ FWxFilial( 'SE1' ) +"' "
	cQuery += "  AND E1.E1_PREFIXO BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
	cQuery += "  AND E1.E1_NUM     BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' "
	cQuery += "  AND E1.E1_PARCELA BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"' "
	cQuery += "  AND E1.E1_CLIENTE BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR08 +"' "
	cQuery += "  AND E1.E1_LOJA    BETWEEN '"+ MV_PAR09 +"' AND '"+ MV_PAR10 +"' "
	cQuery += "  AND E1.E1_TIPO    NOT IN ('RA ','NCC','IR-','CF-','PI-','CS-') "			// Desconsidera antecipa��es ou devolu��es ou Abatimentos 
	cQuery += "  AND E1.E1_STATUS  = 'A' "
	cQuery += "  AND E1.D_E_L_E_T_ = ' ' "

return cQuery

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

/*/{Protheus.doc} TamByPerc
Redefine o tamanho dos pixels em percentual
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/19/2022
@param nPixelsTot, numeric, quantidade de pixels original
@param nPixels, numeric, novo tamanho em pixels
@return numeric, nNewPerc
/*/
static function TamByPerc( nPixelsTot, nPixels )
return Round((nPixels * 100)/nPixelsTot,0)

/*/{Protheus.doc} MontaRel
Fun��o respons�vel pela montagem do boleto gr�fico
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 27/01/2014
@param aMarked, array, vetor com os t�tulos selecionados para impress�o (obrigat�rio)
@param oDanfe, object, objeto do danfe quando impress�o autom�tica originada pela emiss�o do danfe (opcional)
@param lAuto, logical, indica se a chamada foi feita de maneira autom�tica ou manual, .T. ou .F., respectivamente (opcional)
@param aMsg, array, vetor de mensagens de log do processamento (obrigatorio)
@return array, array de arquivos referente aos boletos gerados
/*/
Static Function MontaRel( aMarked, oDanfe, lAuto, aMsg )

local nX              := 0
local lNNOk           := .F.
local aFiles          := {}
local lAdjustToLegacy := .F.
local lDisableSetup   := ! "MAC" $ Upper(GetRmtInfo()[2] )
local lReimp          := .F. as logical
local cDataVcto       := ""
local nPerMulta       := SuperGetMv("MV_LJMULTA",,0) 	// Percentual de multa por atraso no pagamento
local nPEMulta        := Nil
local nPerJuros       := SuperGetMv("MV_TXPER",,0) 		// Percentual de juros por dia de atraso
local uRetPE          := Nil
local nMsgPE          := 0 as numeric
local aValidCustom    := {} as array
local aPESEE          := Nil
local aRatedTit       := {} as array
local aEnv            := {} as array

Private cFatorVcto    := "" as character
Private cNossoNum     := "" as character
Private cDVBol        := "" as character
Private nValLiq       := 0
Private aMensagem     := {}
Private aDadosBanco   := {}
Private cNomePDF      := "default.rel"
Private oPrn
default lAuto := .F.

//Pergunte(cPerg,.F.)

cBanco   := MV_PAR11
cAgencia := MV_PAR12
cConta   := MV_PAR13
cSubCta  := MV_PAR14
cLinha   := ""

DBSelectArea( "SA6" )
SA6->( DBSetOrder( 1 ) )		// A6_FILIAL + A6_COD + A6_AGENCIA + A6_NUMCON
if ! DBSeek( FWxFilial( "SA6" ) + cBanco + cAgencia + cConta )
	Help( ,, 'Par�metros Inv�lidos',, 'Banco ('+ cBanco +'), '+;
	                                  'Ag�ncia ('+ Trim( cAgencia ) +'),'+;
									  'Conta ('+ Trim( cConta ) +') ou '+;
									  'SubConta ('+ Trim( cSubCta ) +') n�o encontrados', 1, 0, NIL, NIL, NIL, NIL, NIL,;
                        			{ 'Verifique os par�metros informados e tente novamente.' } )
	return aFiles
endif

DBSelectArea( "SEE" )
SEE->( DBSetOrder( 1 ) )		// EE_FILIAL + EE_CODIGO + EE_AGENCIA + EE_CONTA + EE_NUMCTA
if ! DBSeek( FWxFilial( "SEE" ) + cBanco + cAgencia + cConta + cSubCta )
	Help( ,, 'Par�metros Inv�lidos',, 'Banco ('+ cBanco +'), '+;
	                                  'Ag�ncia ('+ Trim( cAgencia ) +'),'+;
									  'Conta ('+ Trim( cConta ) +') ou '+;
									  'SubConta ('+ Trim( cSubCta ) +') n�o encontrados', 1, 0, NIL, NIL, NIL, NIL, NIL,;
                        			{ 'Verifique os par�metros informados e tente novamente.' } )
	return aFiles
endif

aValidCustom := validCustom( cBanco )
if len( aValidCustom ) > 0
	aEval( aValidCustom, {|x| aAdd( aMsg, x ) } )
	return aFiles
endif

if !lAuto
	SetRegua( len( aMarked ) )
endif

if Len( aMarked ) > 0
	for nX := 1 to Len( aMarked )
		
		// Posiciona na SE1 para continuar o processamento
		DBSelectArea( 'SE1' )
		SE1->( DBGoTo( aMarked[ nX ] ) )

		If !lAuto
			IncRegua()
		Endif

		// Posiciona no cadastro do cliente
		DbSelectArea("SA1")
		DbSetOrder(1)
		if ! DbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA )
			aAdd( aMsg, "CLIENTE "+ SE1->E1_CLIENTE +" E LOJA " + SE1->E1_LOJA +" NAO LOCALIZADO" )
			Loop
		endif
 
		//nValLiq := Round(SE1->E1_SALDO, 2)
		nTotAbImp		:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
		nValLiq			:= SE1->E1_SALDO+SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp //(Iif(SA1->A1_RECIRRF $ "1",SE1->E1_IRRF,0)+Iif(SA1->A1_RECISS $ "1",SE1->E1_ISS,0))
		

		lReimp := !Empty(SE1->E1_NUMBCO)

		// Guarda os par�metros na vari�vel para ser utilizada em todas as fun��es
		aDadosBanco := getDadosBanco( cBanco, cAgencia, cConta, cSubCta, lReimp, SE1->( Recno() ) )
		if len( aDadosBanco ) == 0
			Loop
		endif

		// Valida exist�ncia de ponto de entrada para manipula��o dos dados dos par�metros de bancos
		if ExistBlock( 'PEBOLSEE' )
			aPESEE := ExecBlock( 'PEBOLSEE',.F.,.F.,{aDadosBanco} )
			if ValType( aPESEE ) == 'A'
				aDadosBanco := aClone( aPESEE )
			endif
		endif

		// C�lculo do d�gito verificador do c�digo da empresa
		aDadosBanco[09] := fDadosBanco(aDadosBanco)

		// 1� Impress�o - vai ser necess�rio gerar novo nosso-n�mero
		if ! lReimp
			
			// Forma sequencial com base na faixa dispon�vel nos par�metros de banco
			cNumBco := fSeqNNro( AllTrim( SEE->EE_FAXATU ) )

			// Valida se o n�mero sequencial est� entre a faixa num�rica estipulada pelo banco e cadastrada nos par�metros
			if (Val(cNumBco) < Val(SEE->EE_FAXINI) .or. Val(cNumBco) > Val(SEE->EE_FAXFIM))
				aAdd(aMsg, "SEQUENCIA NUMERICA "+AllTrim(cNumBco)+" ESTA FORA DA FAIXA PERMITIDA NO CADASTRO DE PARAMETROS DE BANCOS (ADQUIRA NOVA FAIXA NUMERICA JUNTO AO BANCO).")
				Return aFiles
			endIf
			cNossoNum  := fGerNNro( cNumBco )
		Else
			// Valida se o boleto foi impresso em outro banco para evitar erro de rec�lculo de nosso n�mero e c�digo de barras
			If AllTrim(SE1->E1_PORTADO) != aDadosBanco[01] .or. AllTrim(SE1->E1_AGEDEP) != aDadosBanco[03] .or. AllTrim(SE1->E1_CONTA) != aDadosBanco[05]
				aAdd(aMsg, "O TITULO "+Trim(SE1->E1_NUM)+ iif(!Empty(SE1->E1_PARCELA),"/"+SE1->E1_PARCELA,"") +;
				" JA FOI REGISTRADO NO BANCO "+SE1->E1_PORTADO+" AGENCIA: "+SE1->E1_AGEDEP+" CONTA "+SE1->E1_CONTA )
				Loop
			Endif
			cNossoNum := fMontaSeq(SE1->E1_NUMBCO)
		Endif

		// Calcula e armazena o d�gito verificador do nosso n�mero
		cDVBol := fCalcDvNN(@cNossoNum)
		
		// Quando n�o foi reimpress�o, grava os dados do nosso-n�mero calculado no t�tulo do contas a receber
		If ! lReimp
			
			// Valida se o nosso n�mero j� existe antes de grav�-lo.
			lNNOk := ValidNNum(aDadosBanco[01], AllTrim(cNossoNum)+AllTrim(cDVBol))
			While !lNNOk
				cNossoNum := fGerNNro(AllTrim(fSeqNNro(SEE->EE_FAXATU)))
				cDVBol	  := fCalcDvNN(@cNossoNum)
				lNNOk     := ValidNNum(aDadosBanco[01], AllTrim(cNossoNum)+AllTrim(cDVBol))
			EndDo

			// Atribui os dados calculados no t�tulo do contas a receber
			RecLock("SE1",.F.)
			SE1->E1_NUMBCO  := AllTrim(cNossoNum) + AllTrim(cDVBol)
			SE1->E1_PORTADO := SEE->EE_CODIGO
			SE1->E1_AGEDEP  := SEE->EE_AGENCIA
			SE1->E1_CONTA   := SEE->EE_CONTA

			SE1->( MsUnlock() )

		Endif
		
		// Armazena data no formato DD/MM/AAAA
		cDataVcto := DtoC( SE1->E1_VENCREA )
		
		aMensagem := {}
		// Particularidade do banco ABC
		if aDadosBanco[01] == "246"
			Aadd(aMensagem, "T�tulo transferido ao Banco ABC Brasil S/A.")
		EndIf
		
		// Particularidade do Banco do Brasil
		if aDadosBanco[01] == "001"
			Aadd(aMensagem, "N�o dispensar juros de mora.")
		EndIf      

		if aDadosBanco[01] == BANRISUL
			aAdd( aMensagem, "SAC Banrisul: 0800-646-1515 e Ouvidoria Banrisul: 0800-644-2200" )
		endif
								
		// Particularidade do Bic Banco
		if aDadosBanco[01] == "320"
			Aadd(aMensagem, "Tit. cedido fiduciariamente, n�o pagar diretamente � "+Upper(Trim(SubStr(SM0->M0_NOMECOM, 01, 30)))+".")
		EndIf
		
		// Particularidade do Safra
		If aDadosBanco[01] == "422" .And. Val(aDadosBanco[13]) == 2 
			Aadd(aMensagem,"Este boleto representa duplicata cedida fiduciariamente ao Banco Safra S/A,")
			Aadd(aMensagem,"Ficando vedado o pagamento de qualquer outra forma que n�o atrav�s do presente boleto.")
		Endif 
		// Banco Votorantim
		if aDadosBanco[01] == "655"
			Aadd(aMensagem, "Titulo caucionado em favor do BANCO VOTORANTIM S/A.")
		EndIf
		Aadd(aMensagem, "Pagamento atrav�s de DOC, TED, PIX, transfer�ncia ou dep�sito banc�rio n�o quitam o boleto.")

		// Banco Bradesco
		If aDadosBanco[01] == "237" 
			Aadd(aMensagem, "***VALORES EXPRESSOS EM REAIS***") 
			Aadd(aMensagem, "CR�DITO EMPENHADO AO BANCO BBM S.A")	
			Aadd(aMensagem, "O PAGTO SOMENTE PODE SER FEITO POR ESTE BOLETO")
		EndIf
		
		// Valida exist�ncia do ponto de entrada de defini��o de �ndice de multa personalizado
		if ExistBlock( 'PEBOLMLT' )
			nPEMulta := ExecBlock( "PEBOLMLT",.F., .F., {aDadosBanco} )
			if valType( nPEMulta ) == "N"
				nPerMulta := nPEMulta
			endif
		endif
		// Informa no boleto o valor da multa pelo atraso, caso o par�metro MV_LJMULTA esteja configurado no sistema com �ndice maior do que zero
		If nPerMulta > 0
			aAdd(aMensagem, "Ap�s "+ cDataVcto +" cobrar multa de R$ "+ AllTrim(Transform(Round(nValLiq*(nPerMulta/100),2),"@E 99,999.99")))
		EndIf
		
		// Valida exist�ncia de ponto de entrada do cliente para defini��o de �ndice de juros
		if ExistBlock( 'PEBOLJUR' )
			nPEJuros := ExecBlock( 'PEBOLJUR',.F., .F., {aDadosBanco} )
			if valType( nPEJuros ) == 'N'
				nPerJuros := nPEJuros
			endif
		endif
		// Verifica se existe percentual de juros/dia configurado por meio do par�metro MV_TXPER.
		if nPerJuros > 0
			Aadd(aMensagem, "Ap�s "+ cDataVcto +" cobrar juros/mora di�ria de R$ "+ AllTrim(Transform(nValLiq*(nPerJuros/100)," @E 99,999.99")))
		endif
		
		// Verifica se o campo Dias.Prot est� preenchido e se a quantidade de dias � maior do que zero
		If !Empty(aDadosBanco[14]) .and. val(aDadosBanco[14]) > 0
			Aadd(aMensagem, "Sujeito a protesto ap�s "+ AllTrim(aDadosBanco[14]) +" dias do vencimento.") 
		EndIf

		// Verifica se o t�tulo tem desconto incondicional. Se tiver, especifica o valor no boleto.
		//If (SE1->E1_DECRESC > 0)
		//	Aadd(aMensagem, "Conceder abatimento no valor de R$ " +AllTrim(Transform(SE1->E1_DECRESC,PesqPict("SE1","E1_SALDO"))))
		//EndIf
		
		// Se existe desconto condicional no t�tulo a receber, imprime mensagem no boleto
		If SE1->E1_DESCONT > 0
			Aadd(aMensagem, "Para pagamento at� "+ cDataVcto + " conceder desconto de R$ " +;
			AllTrim(Transform(SE1->E1_DESCONT,PesqPict("SE1","E1_VALOR"))))
		endIf
		
		// Particularidade do BIC para impress�o de dados da Empresa
		if aDadosBanco[01] == "320"
			Aadd(aMensagem, Upper(Trim(SM0->M0_NOMECOM)) + " CNPJ: "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
			Aadd(aMensagem, Upper(Trim(SM0->M0_ENDENT)))
			Aadd(aMensagem, SubStr(SM0->M0_CEPENT,01,02) +"."+ SubStr(SM0->M0_CEPENT,03,03) +"-"+ SubStr(SM0->M0_CEPENT,06,03) +;
			" "+ Upper(Trim(SM0->M0_CIDENT)) + " " + SM0->M0_ESTENT)
		EndIf
		
		// Ponto de entrada para o cliente poder adicionar novas mensagens personalizadas caso seja de seu interesse
		if ExistBlock("PEBOLMSG")
			uRetPE := ExecBlock("PEBOLMSG",.F.,.F., {aDadosBanco})
			if ValType( uRetPE ) == "A"
				for nMsgPE := 1 to len( uRetPE )
					aAdd( aMensagem, uRetPE[nMsgPE] )
				next nMsgPE
			endif
		endif
		
		// Inicializa Objetos de Impressao quando a chamada for autom�tica ou quando o objeto do danfe n�o estiver instanciado
		If ValType( oDanfe ) == "O"
			if nX == 1
				oPrn  := oDanfe
				oPrn:SetResolution(78)
				oPrn:SetMargin(10,10,10,10)
			endif
		else
			if nX == 1
				cNomePDF := cEmpAnt + cFilAnt + Trim(SE1->E1_PREFIXO) + Trim(SE1->E1_NUM) + Trim(SE1->E1_PARCELA) + ".rel"
				oPrn := FWMSPrinter():New(cNomePDF, IMP_PDF, lAdjustToLegacy,, lDisableSetup, , , , .F., , .F.)
				oPrn:SetResolution(78)
				oPrn:SetPortrait()
				oPrn:SetPaperSize(DMPAPER_A4) 
				oPrn:SetMargin(10,10,10,10)
				oPrn:linjob   := .F. 
				oPrn:cPathPDF := CLOCPDF
				oPrn:SetDevice(IMP_PDF)
				oPrn:SetViewPDF(!lAuto)
			endif
		Endif
		
		// Inicializa p�gina
		oPrn:StartPage()

		// Chama a fun��o de impress�o dos dados no formul�rio instanciado ou recebido por par�metro
		printDoc( @oPrn )
		oPrn:EndPage()

		// Quando a chamada n�o estiver vindo das regras de prioriza��o
		if ! lReimp .and. ! IsInCallStack( 'U_BOLRULES' )
			
			// Monta a estrutura do titulo para enviar por par�metro para a fun��o de controle de garantias
			aRatedTit := U_BOLTITCR( SE1->(Recno()), Nil )
			
			// Devido ao local onde a estrutura do titulo est� sendo montada, a reimpress�o sempre vai vir como .T., por isso
			// o conte�do precisa ser ajustado manualmente
			aRatedTit[ aScan( aRatedTit, {|x| x[1] == 'reimpressao' } ) ][02] := lReimp
			aAdd( aRatedTit, {"banco"   , SEE->EE_CODIGO  } )
			aAdd( aRatedTit, {"agencia" , SEE->EE_AGENCIA } )
			aAdd( aRatedTit, {"conta"   , SEE->EE_CONTA   } )
			aAdd( aRatedTit, {"subconta", SEE->EE_SUBCTA  } )
			
			// Aciona a fun��o de controle de garantias
			U_BOLGARCT( aRatedTit, .T. )

		endif

		// Caso o objeto do danfe tenha sido recebido por par�metro, finaliza a impress�o da p�gina para o sistema pode prosseguir com o uso do objeto
		if ValType( oDanfe ) == "O"
			
			// Apenas migra os dados de volta para o objeto do danfe quando chegar ao final do processamento
			if nX == len( aMarked )
				
				oDanfe := oPrn
				oDanfe:SetMargin(60,60,60,60)

			endif

		EndIf
		
		// Adiciona no vetor de titulos para enviar por e-mail para o cliente
		if SA1->(FieldPos('A1_BLEMAIL')) > 0 .and. SA1->A1_BLEMAIL == '1'       // 1=Sim
			aAdd( aEnv, { { 'cliente', SE1->E1_CLIENTE },;
							{ 'loja', SE1->E1_LOJA },;
							{ 'prefixo', SE1->E1_PREFIXO },;
							{ 'numero', SE1->E1_NUM },;
							{ 'parcela', SE1->E1_PARCELA },;
							{ 'emissao', SE1->E1_EMISSAO },;
							{ 'vencimento', SE1->E1_VENCREA },;
							{ 'valor', SE1->E1_SALDO } } )
		endif

	next nX
endif

// Imprime direto na impressora ou Visualiza antes de imprimir 
If !lAuto .and. len( aMsg ) == 0
	oPrn:Print()

	// Verifica se a estrutura existe no server
	if ! ExistDir( CDIRSRV )
		MakeDir( CDIRSRV )
	endif

	// Valida exist�ncia do PDF logo ap�s a conclus�o da gera��o do arquivo
	if File( oPrn:cPathPDF + StrTran(oPrn:cFileName,'.rel','.pdf' ) ) 
		// Manda copiar arquivo para diret�rio no servidor
		if CpyT2S( oPrn:cPathPDF + StrTran(oPrn:cFileName,'.rel','.pdf' ), CDIRSRV, .F.)
			cPathPDF := CDIRSRV + StrTran(oPrn:cFileName,'.rel','.pdf' )
			if file( cPathPDF )
				aAdd(aFiles, cPathPDF )
				if len( aEnv ) > 0
					U_BolSndWf( aEnv, cPathPDF )
				endif
			endif
			
		EndIf
	EndIf
	
	FreeObj(oPrn)
	oPrn := nil
Endif

Return aFiles

/*/{Protheus.doc} getDadosBanco
Fun��o para retornar os dados do banco selecionado nos par�metros ou os dados do banco utilizado para impress�o do t�tulo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/21/2022
@param cBanco, character, codigo do banco
@param cAgencia, character, codigo da agencia
@param cConta, character, codigo da conta
@param cSubConta, character, subconta
@param lReimp, logical, indica se � reimpress�o
@param nRecSE1, numeric, Recno da tabela SE1
@return array, aGetDadosBanco
/*/
static function getDadosBanco( cBanco, cAgencia, cConta, cSubConta, lReimp, nRecSE1 )
	
	local aDados := {} as array
	local cBco   := "" as character
	local cAge   := "" as character
	local cCta   := "" as character
	local cSub   := "" as character

	default lReimp  := .F.
	default nRecSE1 := 0

	cBco := cBanco
	cAge := cAgencia
	cCta := cConta
	cSub := cSubConta
	
	// Quando for reimpress�o, assume o banco, agencia e conta j� utilizados para o t�tulo
	if lReimp .and. nRecSE1 > 0
		
		DBSelectArea( "SE1" )
		SE1->( DBGoTo( nRecSE1 ) )
		
		cBco := SE1->E1_PORTADO
		cAge := SE1->E1_AGEDEP
		cCta := SE1->E1_CONTA
		cSub := RetField( 'SEE', 1, FWxFilial( 'SEE' ) + cBco + cAge + cCta, "EE_SUBCTA" )
		
	endif

	DBSelectArea( "SA6" )
	SA6->( DBSetOrder( 1 ) )
	if SA6->( DBSeek( FWxFilial( 'SA6' ) + cBco + cAge + cCta ) )

		DBSelectArea( "SEE" )
		SEE->( DBSetOrder( 1 ) )
		if SEE->( DBSeek( FWxFilial( 'SEE' ) + cBco + cAge + cCta + cSub ) )

			aDados := { SA6->A6_COD,;                  				    						// 01 - C�digo do Banco
						Trim(SA6->A6_NOME),;                            						// 02 - Nome do Banco
						Trim(SEE->EE_AGENCIA),;                         						// 03 - Ag�ncia
						Trim(SEE->EE_DVAGE),;                           						// 04 - D�gito Verificador Ag�ncia
						Trim(SEE->EE_CONTA),;                           						// 05 - Conta Corrente
						Trim(SEE->EE_DVCTA),;                           						// 06 - D�gito Verificador Conta
						"N",;                                           						// 07 - Aceite S/N
						Trim(SEE->EE_TIPCART),;                         						// 08 - Tipo da carteira de Cobranca 
						Trim(SEE->EE_CODEMP),;                          						// 09 - C�digo da Empresa
						iif( SEE->(FieldPos('EE_X_COSMO')) > 0, Trim(SEE->EE_X_COSMO), ''),; 	// 10 - Conta Cosmo (Citibank)
						Trim(SEE->EE_AGEOFI),;                          						// 11 - Ag�ncia Bco Corresp
						Trim(SEE->EE_CTAOFI),; 						    						// 12 - Conta Bco Corresp
						Trim(SEE->EE_CODCART),;						    						// 13 - Codigo da carteira 
						Trim(SEE->EE_DIASPRT),;													// 14 - Quantidade de dias para protesto
						iif( SEE->(FieldPos('EE_X_BYTE')) > 0, SEE->EE_X_BYTE, ''),; 			// 15 - Byte utilizado para gera��o do nosso n�mero do Sicredi
						iif( SEE->(FieldPos('EE_X_POSTO')) > 0, SEE->EE_X_POSTO, ''),;			// 16 - Codigo do Posto utilizado para gera��o do nosso n�mero do Sicredi							
						iif( Empty( SEE->EE_TPCOBRA ), '2', SEE->EE_TPCOBRA ),;					// 17 - Tipo da cobran�a 1-Registrada ou 2-N�o Registrada
						Trim( SEE->EE_CODCART ) }												// 18 - Codigo da carteira

		endif

	endif

return aDados

/*/{Protheus.doc} printDoc
Fun��o respons�vel pelo processo de impress�o dos dados no formul�rio do boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/23/2021
@param oPrn, object, objeto oPrn instanciado pronto pra ser usado para impress�o
/*/
Static Function printDoc( oPrn )

	private cDvCod    := "" as character
	private cLinhaDig := "" as character
	private cCodBar   := "" as character
	private nLine     := 0  as numeric

	// Atribui o D�gito do Codigo do Banco a uma Vari�vel
	cDvCod := fDvBco(aDadosBanco[01])

	// Calcula o C�digo de Barras
	cCodBar := fCodigoBarras(aDadosBanco[01])

	// Montar a Linha Digitavel da Boleta
	cLinhaDig := fLinhaDigitavel(aDadosBanco[01])

	// RECIBO DE ENTREGA (Terceira Via)
	doPart(3, @oPrn )

	// RECIBO DO PAGADOR (Segunda Via)
	doPart(2, @oPrn )

	// FICHA DE COMPENSA��O (Primeira Via)
	doPart(1, @oPrn )

Return Nil

/*/{Protheus.doc} fCodigoBarras
Fun��o para c�lculo do c�digo de barras com base no banco recebido por par�metro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/13/2022
@param cBanco, character, c�digo do banco
@return character, cCodigoBarras
/*/
Static Function fCodigoBarras(cBanco)

Local _cBarra   := ""
Local _cResult  := ""
Local cBarDV    := "" 
local dDtFator  := iif( SE1->E1_VENCTO >= CtoD("22/02/2025"), CtoD( "29/05/2022" ), Ctod("07/10/1997" ) )
local cFreeText := "" as character

Private cBco    := cBanco

cFatorVcto := StrZero( SE1->E1_VENCTO - dDtFator, 04)

Do Case
	
	Case cBanco == "004"		// Banco do Nordeste
		_cBarra := "004"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += aDadosBanco[03] + AllTrim(StrZero(Val(aDadosBanco[09]),8)) + Trim(cNossoNum) + Trim(cDVBol) + aDadosBanco[8] + "000"
		
	Case cBanco == "001"		// Banco do Brasil
		lConv7 := .F.
		lConv7 := Len(aDadosBanco[09]) == 7
		If lConv7
			_cBarra := "001"  + "9" + cFatorVcto
			_cBarra += StrZero(nValLiq*100,10)
			_cBarra += "000000" + Trim(cNossoNum) + aDadosBanco[08]
		Else
			_cBarra := "001"  + "9" + cFatorVcto
			_cBarra += StrZero(nValLiq*100,10)
			_cBarra += Trim(cNossoNum) + aDadosBanco[03] + aDadosBanco[05] + aDadosBanco[08]
		EndIf
		
	Case cBanco == "033"		// Santander
		cTpMod := aDadosBanco[13] 
		_cBarra := "033"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10) + "9"
		_cBarra += aDadosBanco[09] + Trim(cNossoNum) + Trim(cDVBol) + "0" + cTpMod
	
	Case cBanco == BANRISUL
		_cBarra := "041"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		cFreeText := "21"+ aDadosBanco[3] + SubStr(aDadosBanco[09],1,7) + SubStr(cNossoNum,1,8) +"40"
		_cBarra += cFreeText + doubleDig( cFreeText )

	Case cBanco == "104"		// Caixa Economica Federal
		lSIGCB := Len(aDadosBanco[09]) == 7 
		
		if lSIGCB   
		  
		    cBarDV += aDadosBanco[09] + SuBStr(cNossoNum, 03, 03) + SuBStr(cNossoNum, 01, 01) + SuBStr(cNossoNum, 06, 03)
			cBarDV += SuBStr(cNossoNum, 02, 01) + SuBStr(cNossoNum, 09, 09) 
		
		
			_cBarra := "104"  + "9" + cFatorVcto
			_cBarra += StrZero(nValLiq*100,10)
			_cBarra += aDadosBanco[09] + SuBStr(cNossoNum, 03, 03) + SuBStr(cNossoNum, 01, 01) + SuBStr(cNossoNum, 06, 03)
			_cBarra += SuBStr(cNossoNum, 02, 01) + SuBStr(cNossoNum, 09, 09) 
			_cBarra += fDvCpoLv(cBarDV)
							
		Else
			_cBarra := "104"  + "9" + cFatorVcto
			_cBarra += StrZero(nValLiq*100,10)
			_cBarra += Trim(cNossoNum) + aDadosBanco[03] + SubStr(aDadosBanco[09],01,11)
		EndIf

	Case cBanco == "224"		// banco Fibra
		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := SubStr(aDadosBanco[12], 01, 05) + SubStr(aDadosBanco[12], 07, 01)
		
		_cBarra := "341"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += aDadosBanco[08] + Trim(cNossoNum) + Trim(cDVBol) + cAgeCor + cCtaCor + "000"
		
	Case cBanco == "237"		// Bradesco
		_cBarra := "237"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += aDadosBanco[03] + StrZero(Val(aDadosBanco[08]),2) + cNossoNum + aDadosBanco[05] + "0"

	Case cBanco == "246"		// Banco ABC
		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := StrZero(Val(SubStr(aDadosBanco[12], 01, At("-",aDadosbanco[12])-1)),07)
		
		_cBarra := "237"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += cAgeCor + aDadosBanco[08] + Trim(cNossoNum) + cCtaCor + "0"
		
	Case cBanco == "320"		// Bic Banco
		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := StrZero(Val(SubStr(aDadosBanco[12], 01, At("-",aDadosbanco[12])-1)),07)
		
		_cBarra := "237"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += cAgeCor + aDadosBanco[08] + Trim(aDadosBanco[09]) + Trim(cNossoNum) + cCtaCor + "0"
		
	Case cBanco == "341"		// Ita�
		_cBarra := "341"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += aDadosBanco[18] + Trim(cNossoNum) + Trim(cDVBol) + aDadosBanco[03] + aDadosBanco[05] +;
		Mod10Itau(aDadosBanco[03] + aDadosBanco[05]) + "000"
		                          
	Case cBanco == "399"		// HSBC
		_cBarra := "399"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += Trim(cNossoNum) + Trim(cDVBol) + aDadosBanco[03] + aDadosBanco[05] + "00" + "1"

	Case cBanco == "422"		// Banco Safra

		//cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		//cCodCed := aDadosBanco[12]
		//cRet := cCodAge + " / " + cCodCed

		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := StrZero(Val(SubStr(aDadosBanco[12], 01, At("-",aDadosbanco[12])-1)),07)
		
//		_cBarra := "237"  + "9" + cFatorVcto
//		_cBarra += StrZero(nValLiq*100,10)
//		_cBarra += cAgeCor + aDadosBanco[08] + Right(Str(Year(SE1->E1_EMISSAO)),2) +;
//		Trim(cNossoNum) + cCtaCor + "0"
		//	422 9 1 9367 0000010000 7 00700 005835142 000000278 2
		_cBarra := "422"  													// 01-03 Identificacao do banco 
		_cBarra += "9" 														// 04-04 - Moeda
		//DAC - Digito de AutoConferencia									// 05-05 - Digito Verificador a ser calculado abaixo
		_cBarra += cFatorVcto												// 06-09 - Fator de Vencimento
		_cBarra += StrZero(nValLiq*100,10)									// 10-19 Valor do titulo
		// Campo Livre			
		_cBarra += "7"														// 20-20 - Sistema - Fixo 7 	
		_cBarra += SubStr(aDadosBanco[11], 01, 05) + Substr(aDadosBanco[12],1,9)		// 21-34 - Cliente - C�digo Cedente = Agencia + Conta 
		_cBarra += StrZero(Val(cNossoNum),8)+Trim(cDVBol)					// 35-43 - Nosso numero 8 digitos
		_cBarra += "2"														// 44-44 - Conta do Cedente - Fixo 0176300
		

	Case cBanco == "623"		// Banco Panamericano
		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := StrZero(Val(SubStr(aDadosBanco[12], 01, At("-",aDadosbanco[12])-1)),07)
		
		_cBarra := "237"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += cAgeCor + aDadosBanco[08] + Trim(cNossoNum) + cCtaCor + "0"
		
	Case cBanco == "655"		// Banco Votorantim
		_cBarra := "001"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += "000000" + Trim(cNossoNum) + SubStr(aDadosBanco[08],01,02)

	Case cBanco == "707"		// Banco Daycoval
		cAgeCor := ""
		cAgeCor := SubStr(aDadosBanco[11], 01, 04)
		cCtaCor := ""
		cCtaCor := StrZero(Val(SubStr(aDadosBanco[12], 01, At("-",aDadosbanco[12])-1)),07)
		
		_cBarra := "237"  + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += cAgeCor + aDadosBanco[08] + Trim(cNossoNum) + cCtaCor + "0"

	Case cBanco == "745"		// Citibank
		_cBarra := "745" + "9" + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)
		_cBarra += "3" + aDadosBanco[08] + SubStr(aDadosBanco[10],2,9) + cNossoNum + cDVBol
		
	Case cBanco == '748'		// Sicredi
		
		// Monta o Campo Livre
		cFreeText := aDadosBanco[17] + aDadosBanco[08] + cNossoNum + cDVBol + aDadosBanco[03] + aDadosBanco[16] + aDadosBanco[09] + '1' + '0'
		cFreeText += modulo11( cFreeText )

		_cBarra   := cBanco + "9" + cFatorVcto
		_cBarra   += StrZero(nValLiq*100,10)
		_cBarra   += cFreeText

	Case cBanco == "756"		// Sicoob
		_cBarra := cBanco + '9' + cFatorVcto
		_cBarra += StrZero(nValLiq*100,10)		
		_cBarra += aDadosBanco[13] + aDadosBanco[03] + aDadosBanco[08] + StrZero( Val( aDadosBanco[09] ), 07) + cNossoNum + cDVBol +; 
		           iif( SE1->E1_PARCELA == '   ', '001', SE1->E1_PARCELA )
		
EndCase

// Insere D�gito Verificador no C�digo de Barras
_cResult := Substr(_cBarra,1,4) + BarraDV(_cBarra) + SubStr(_cBarra,5)

Return(_cResult)

/*/{Protheus.doc} doubleDig
Fun��o para obter o d�gito verificador duplo do campo livre, usado para compor o c�digo de barras
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 17/10/2024
@param cPart, character, parte do c�digo de barras que refere-se ao campo livre
@return character, cDoubleDV
/*/
static function doubleDig( cPart )
	
	local cDoubleDV := "" as character
	local cDV1      := "" as character
	local aRetMod11 := {} as array

	cDV1 := mod10banri( cPart )
	aRetMod11 := mod11banri( cPart + cDV1 )
	cDoubleDV := aRetMod11[1] + aRetMod11[2]

return cDoubleDV

/*/{Protheus.doc} mod11banri
Fun��o para calcular MOD11 do banco Banrisul
@type function
@version 12.1.2310
@author Jean Carlos Pandolfo Saggin
@since 17/10/2024
@param cPart, character, string base para calcular o mod11
@param lDAC, logical, indica se o c�lculo a ser feito � o d�gito geral do c�digo de barras (neste caso o c�lculo � diferente)
@return character, cDV
/*/
static function mod11banri( cPart, lDAC )
	
	local lValid  := .F. as logical
	local nCount  := 0 as numeric
	local nFator  := 2 as numeric
	local cNumTmp := cPart
	local i       := 0 as numeric
	local cDv     := "" as character
	local nResto  := 0 as numeric
	local nMax    := 0 as numeric
	local cDV1    := SubStr( cPart, len( cPart ), 1 )
	
	nMax := iif( lDAC, 9, 7 )

	while ! lValid
		nCount := 0
		nFator := 2
		nResto := 0
		i      := 0
		cDv    := ""

		for i := len( cNumTmp ) to 1 step -1
			nCount += Val( SubStr( cNumTmp, i, 1 ) ) * nFator
			nFator++
			if nFator > nMax
				nFator := 2
			endif
		next i
		nResto := nCount % 11
		if lDAC
			if nResto == 0 .or. nResto == 1
				cDv := '1'
				lValid := .T.
			else
				cDv := AllTrim( cValToChar( 11-nResto ) )
				lValid := .T.
			endif
		else
			if nResto == 0
				cDv    := "0"
				lValid := .T.
			elseif nResto == 1		
				// nosso n�mero inv�lido, pois 11-1 retornaria 10. 
				// Neste caso, o banco orienta a acrescer um n�mero no DV do m�dulo 10 calculado na etapa anterior e 
				// refazer o c�lculo do m�dulo 11.
				if SubStr( cNumTmp, len( cNumTmp ), 1 ) == '9'		// Se o �ltimo DV for 9, ao inv�s de somar 1, atribui 0
					cNumTmp := SubStr( cNumTmp, 1, len( cNumTmp ) - 1 ) + '0'
					cDV1 := "0"
				else
					cNumTmp := Soma1( cNumTmp )
					cDV1 := SubStr( cNumTmp, len( cNumTmp ), 1 )
				endif
			else
				cDv := AllTrim( cValToChar( 11 - nResto ) )
				lValid := .T.
			endif
		endif
	end
return { cDV1, cDv }

/*/{Protheus.doc} mod10banri
Fun��o para calcular MOD10 do banco Banrisul
@type function
@version 12.1.2310
@author Jean Carlos Pandolfo Saggin
@since 17/10/2024
@param cPart, character, trexo base para c�lculo do mod10
@return character, cDV
/*/
static function mod10banri( cPart )
	
	local i     := 0 as numeric
	local nMult := 0 as numeric
	local cDV   := "" as character
	local nDV   := 0 as numeric
	local nMod  := 0 as numeric
	local nSoma := 0 as numeric
	local nPeso := 2 as numeric

	for i := len( cPart ) to 1 step -1
		nMult := Val( SubStr( cPart, i, 1 ) ) * nPeso
		if nPeso == 2
			nPeso := 1
		else
			nPeso := 2
		endif
		if nMult > 9
			nMult := nMult - 9
		endif
		nSoma += nMult
	next i
	nMod := nSoma % 10
	if nMod == 0
		nDV := 0
	else
		nDV := 10 - nMod
	endif
	cDV := AllTrim( cValToChar( nDV ) )

return cDV

/*/{Protheus.doc} fDvCpoLv
Calcula o d�gito verificador do campo livre da Caixa Economica Federal
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/13/2022
@param cBarDV, character, campo livre
@return character, cDV
/*/
Static Function fDvCpoLv(cBarDV)

	Local cRet  := ""
	Local Resto := ""
	Local nCont := 0
	Local nPeso := 2
	local i     := 0

	For i := len(cBarDV) to 1 step -1
		nCont += Val(SubStr(cBarDV, i, 01)) * nPeso
		nPeso++
		if nPeso > 9
			nPeso := 2
		EndIf
	Next i

	if nCont < 11
		cRet   := AllTrim(Str(11 - nCont))
	Else
		Resto  := nCont % 11
		cRet   := AllTrim(Str(11 - Resto))

		if (11 - Resto) > 9
			cRet := "0"
		EndIf
	Endif

Return cRet

/*/{Protheus.doc} BarraDV
Fun��o que calcula e insere o d�gito verificado na linha digit�vel do boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/13/2022
@param _cBarCampo, character, linha digit�vel sem d�gito verificador
@return character, cBarraDV
/*/
Static Function BarraDV(_cBarCampo)

Local i      := 0
Local nCont  := 0
Local nPeso  := 0
Local nResto  := 0
Local nResult := 0
Local DV_BAR := Space(1)

Do Case

	Case cBco == "004"		// Banco do nordeste
		nCont := 0
		nPeso := 2
		For i := 43 To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResto == 10 .or. nResto == 0 .or. nResto == 1
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
		
	Case cBco == "001"		// Banco do Brasil
		cFator := "4329876543298765432987654329876543298765432"
		nVal1  := 0
		nResult:= 0
		For I:=1 to Len(_cBarCampo)
			nResult := Val(Substr(_cBarCampo,I,1)) * Val(Substr(cFator,I,1))
			nVal1   += nResult
		Next
		
		nResto := nVal1 % 11
		nResto := 11 - nResto
		If nResto == 10
			nDig := 1
		ElseIf nResto == 11
			nDig := 1
		Else
			nDig := nResto
		EndIf
		DV_BAR := AllTrim(Str(nDig))
		
	Case cBco == "033"		// Santander
		
		nCont := 0
		nPeso := 2
		
		For i := 43 To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		
		nCont := nCont * 10
		nResto  := nCont % 11
		nResult := nResto
		
		if (nResto == 0 .or. nResto == 1 .or. nResto == 10)
			DV_BAR := "1"
		Else
			DV_BAR := AlLTrim(Str(nResult))
		EndIf

	Case cBco == BANRISUL
		DV_BAR := mod11banri( _cBarCampo, .T. /* lDAC */ )[2]

	Case cBco == "104"		// Caixa Economica Federal
		nCont := 0
		nPeso := 2
		
		For i := len(_cBarCampo) to 1 step -1
			nCont += Val(SubStr(_cBarCampo, i, 01)) * nPeso
			nPeso++
			if nPeso > 9
				nPeso := 2
			EndIf
		Next i
		
		nResto  := nCont % 11
		DV_BAR := AllTrim(Str(11 - nResto))
		
		if (11 - nResto) == 0 .or. (11 - nResto) > 9
			DV_BAR := "1"
		EndIf

	Case cBco == "224"		// Banco Fibra
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := len(_cBarCampo) To 1 Step -1
			nCont += Val( SubStr( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
		
	Case cBco == "237"		// Bradesco
		i      := 0
		nCont  := 0
		nResto  := 0
		nResult := 0
		nPeso  := 2
		For i := Len(_cBarCampo) To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase

	Case cBco == "246"		// Banco ABC
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := len(_cBarCampo) To 1 Step -1
			nCont += Val(SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
		
	Case cBco == "320"		// Bic Banco
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := len(_cBarCampo) To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1)) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next i
		
		nResto  := nCont % 11
		nResult := 11 - nResto
		
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
		
	Case cBco == "341"		// Ita�
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := len(_cBarCampo) To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase

	Case cBco == "399"		// HSBC
		i      := 0
		nResto := 0
		nCont  := 0
		nPeso  := 2
		
		for i := Len(_cBarCampo) to 1 Step -1
			nCont += Val(SubStr(_cBarCampo, i, 1)) * nPeso
			nPeso++
			If nPeso == 10
				nPeso := 2
			EndIf
		Next i
		
		nResto := nCont % 11
		
		Do Case
			Case nResto == 0 .or. nResto == 1 .or. nResto == 10
				DV_BAR := "1"
			OtherWise
				DV_BAR := AllTrim(Str(11 - nResto))
		EndCase
		
	Case cBco == "422"		// Banco Safra
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := 43 To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next i
		
		nResto  := nCont % 11
		nResult := 11 - nResto
		
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
	
	Case cBco == "623"		// Banco Panamericano
		i      := 0
		nCont  := 0
		nResto  := 0
		nResult := 0
		nPeso  := 2
		For i := Len(_cBarCampo) To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResult == 10 .or. nResult == 11
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase

	Case cBco == "655"		// Banco Votorantim
		cFator := "4329876543298765432987654329876543298765432"
		nVal1  := 0
		nResult:= 0
		For I:=1 to Len(_cBarCampo)
			nResult := Val(Substr(_cBarCampo,I,1)) * Val(Substr(cFator,I,1))
			nVal1   += nResult
		Next
		
		nResto := nVal1 % 11
		nResto := 11 - nResto
		
		If nResto == 0
			nDig := 1
		ElseIf nResto == 10
			nDig := 1
		ElseIf nResto == 11
			nDig := 1
		Else
			nDig := nResto
		EndIf
		DV_BAR := AllTrim(Str(nDig))

	Case cBco == "707"		// Daycoval
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := len(_cBarCampo) To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next i
		
		nResto  := nCont % 11
		nResult := 11 - nResto
		
		Do Case
			Case nResult > 9 .or. nResult == 0 .or. nResult == 1
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase

	Case cBco == "745"		// Citibank
		i      := 0
		nResto  := 0
		nResult := 0
		nCont  := 0
		nPeso  := 2
		
		For i := 43 To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next i
		
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResto == 0 .or. nResto == 1
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
	
	Case cBco == '748'		// Sicredi
		DV_BAR := Modulo11(_cBarCampo, .T. /* lCodBar */)

	Case cBco == "756"		// Sicoob
		i       := 0
		nResto  := 0
		nResult := 0
		nCont   := 0
		nPeso   := 2
		
		For i := 43 To 1 Step -1
			nCont += Val( SUBSTR( _cBarCampo,i,1 )) * nPeso
			nPeso++
			If nPeso >  9
				nPeso := 2
			Endif
		Next i
		
		nResto  := nCont % 11
		nResult := 11 - nResto
		Do Case
			Case nResto == 0 .or. nResto == 1
				DV_BAR := "1"
			OtherWise
				DV_BAR := Str(nResult,1)
		EndCase
		
EndCase

Return(DV_BAR)

/*/{Protheus.doc} fLinhaDigitavel
Fun��o respons�vel pela gera��o da linha digit�vel do boleto, que utiliza como base o conte�do do c�digo de barras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco
@return character, cLinhaDigitavel
/*/
Static Function fLinhaDigitavel(cBanco)

	Local cDigito  := ""
	Local cPedaco   := ""
	local cLineDig := ""
	
	Private cBco   := cBanco

	// Primeiro campo
	cPedaco  := Substr(cCodBar,01,03) + Substr(cCodBar,04,01) + Substr(cCodBar,20,3) + Substr(cCodBar,23,2)
	cDigito  := LinhaDV(cPedaco)
	cLineDig := Substr(cCodBar,1,3)+Substr(cCodBar,4,1)+Substr(cCodBar,20,1)+"."+;
			Substr(cCodBar,21,2) + Substr(cCodBar,23,2) + cDigito + Space(2)

	// Segundo campo
	cPedaco  := Substr(cCodBar,25,10)
	cDigito  := LinhaDV(cPedaco)
	cLineDig := cLineDig+Substr(cPedaco,1,5)+"."+Substr(cPedaco,6,5)+;
		cDigito+Space(2)

	// Terceiro Campo
	cPedaco  := Substr(cCodBar,35,10)
	cDigito  := LinhaDV(cPedaco)
	cLineDig := cLineDig + Substr(cPedaco,1,5)+"."+Substr(cPedaco,6,5)+cDigito+Space(2)

	// Quarto campo
	cLineDig := cLineDig + Substr(cCodBar,5,1) + Space(2)

	// Quinto campo
	cLineDig := cLineDig + cFatorVcto + StrZero(nValLiq*100,10)

Return( cLineDig )

/*/{Protheus.doc} LinhaDV
C�lculo do d�gito verificador da linha digit�vel
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param _cCampo, variant, peda�o de conte�do recebido para c�lculo do d�gito
@return character, cLinhaDV
/*/
Static Function LinhaDV(_cCampo)

Local _cResult := ""
Local nPeso     := 0			// Vari�vel controladora do peso na hora da multiplica��o
Local i        := 0				// Vari�vel de controle de la�o do For 
local nResto   := 0 as numeric
local nAux     := 0 as numeric
local cLinha   := "" as character
local nFator   := 0 as numeric
local nDig     := 0 as numeric
local nGeral   := 0 as numeric
local nResult  := 0 as numeric
local cDezena  := "" as character

Do Case
	
	Case cBco == "004"		// Banco do nordeste
		nCont  := 0
		nVal   := 0
		nResto := 0
		nPeso  := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso > 9
				nVal  := Val(SUBSTR(_cCampo,i,1)) * nPeso
				nCont += nVal - 9
			Else
				nCont += Val(SUBSTR(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		nResto  := nCont % 10
		
		If nResto  == 0
			_cResult := "0"
		Else
			_cResult := AllTrim(Str(10 - nResto))
		Endif
		
	Case cBco == "001"		// Banco do brasil
		cLinha  := _cCampo
		nAux    := Len(cLinha) % 2
		nFator  := 0
		nDig    := 0
		nGeral  := 0
		nResult := 0
		
		If nAux == 0
			nFator  := 1
		Else
			nFator  := 2
		EndIf
		
		For I := 1 to Len(cLinha)
			nResult := nFator * Val(Substr(cLinha,I,1))
			If nResult > 09
				nResult := Val(Substr(Alltrim(Str(Int(nResult))),1,1))+Val(Substr(Alltrim(Str(Int(nResult))),2,1))
			EndIf
			nGeral += nResult
			If nFator == 1
				nFator := 2
			Else
				nFator := 1
			EndIf
		Next
		
		If nGeral < 11
			nDig := 10 - nGeral
		ElseIf nGeral > 90
			nDig := 100 - nGeral
		Else
			nAux := Val(Substr(Alltrim(Str(nGeral)),1,1)) + 1
			nDig := Val(Alltrim(Str(nAux)+"0")) - nGeral
		EndIf
		nDig     := If(nDig == 10 , 0 , nDig)
		_cResult := AllTrim(Str(nDig))

	Case cBco == "033"		// Santander
		nCont := 0
		nVal  := 0
		nPeso := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso > 9
				nVal  := Val(SUBSTR(_cCampo,i,1)) * nPeso
				nCont += Val(SUBSTR(Str(nVal,2),1,1)) + Val(SUBSTR(Str(nVal,2),2,1))
			Else
				nCont += Val(SUBSTR(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		if (nCont % 10) == 0
			_cResult := "0"
		else
			_cResult := AllTrim(Str(10 - (nCont % 10)))
		EndIf
	
	Case cBco == BANRISUL
		_cResult := mod10banri( _cCampo )

	Case cBco == "104"		// Caixa Economica Federal
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SUBSTR(_cCampo,i,1)) * nPeso
				nCont += Val(SUBSTR(Str(nVal,2),1,1)) + Val(SUBSTR(Str(nVal,2),2,1))
			Else
				nCont += Val(SUBSTR(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
		
	Case cBco == "224"		// Banco Fibra
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
		
	Case cBco == "237"		// Bradesco
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SUBSTR(_cCampo,i,1)) * nPeso
				nCont += Val(SUBSTR(Str(nVal,2),1,1)) + Val(SUBSTR(Str(nVal,2),2,1))
			Else
				nCont += Val(SUBSTR(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif

	Case cBco == "246"		// Banco ABC
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
		
	Case cBco == "320"		// Bic Banco
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next i
		
		cDezena := Substr(Str(nCont,2),1,1)
		nResto  := ((Val(cDezena)+1) * 10) - nCont
		
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif

	Case cBco == "341"		// Ita�
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next i
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
		                    
	Case cBco == "399"		// HSBC
	i      := 0
	nCont  := 0
	nPeso := 2
	nTmp   := 0
	nResto := 0
	  
	For i := Len(_cCampo) to 1 step -1
	 	nTmp  := Val(SubStr(_cCampo, i, 1)) * nnPeso
		nCont += iif(nTmp > 9, Val(SubStr(AllTrim(Str(nTmp)),1,1)) + Val(SubStr(AllTrim(Str(nTmp)),2,1)),nTmp)
	  	
    	nPeso--
      
    	If nnPeso == 0
    		nPeso := 2
    	EndIf
	  	
	Next i
		
	nResto := nCont % 10
		
	Do Case
		Case nCont < 10
			_cResult := AllTrim(Str(10 - nCont))
		Case nResto == 0
			_cResult := "0"
		OtherWise
			_cResult := AllTrim(Str(10 - nResto))
	EndCase
		
	Case cBco == "422"		// Safra
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := AllTrim(Str(nResto))
		Endif

	Case cBco == "623"		// Panamericano
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SUBSTR(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SUBSTR(_cCampo,i,1)) * nPeso
				nCont += Val(SUBSTR(Str(nVal,2),1,1)) + Val(SUBSTR(Str(nVal,2),2,1))
			Else
				nCont += Val(SUBSTR(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif

	Case cBco == "655"		// Votorantim
		cLinha  := _cCampo
		nAux    := Len(cLinha) % 2
		nFator  := 0
		nDig    := 0
		nGeral  := 0
		nResult := 0
		nResto  := 0
		
		If nAux == 0
			nFator  := 1
		Else
			nFator  := 2
		EndIf
		
		For I := 1 to Len(cLinha)
			nResult := nFator * Val(Substr(cLinha,I,1))
			If nResult > 09
				nResult := Val(Substr(Alltrim(Str(Int(nResult))),1,1))+Val(Substr(Alltrim(Str(Int(nResult))),2,1))
			EndIf
			nGeral += nResult
			If nFator == 1
				nFator := 2
			Else
				nFator := 1
			EndIf
		Next
		
		nResto := nGeral % 10
		
		if nResto != 0
			nAux := Val(Substr(Alltrim(StrZero(nGeral,2)),1,1)) + 1
			nDig := Val(Alltrim(Str(nAux)+"0")) - nGeral
		Else
			nDig := nResto
		EndIf
		_cResult := AllTrim(Str(nDig))

	Case cBco == "707"		// Daycoval
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next i
		
		cDezena := Substr(Str(nCont,2),1,1)
		nResto  := ((Val(cDezena)+1) * 10) - nCont
		
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif

	Case cBco == "745"		// Citibank
		nVal    := 0
		cDezena := ""
		nResto  := 0
		nCont   := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
	
	Case cBco == "748"		// Sicredi
		
		nPeso  := 2
		nVal   := 0
		nTotal := 0
		nAux   := 0
		nCont  := 0

		for i := len( _cCampo ) to 1 step -1
			nVal := Val( SubStr( _cCampo, i, 1 ) ) * nPeso
			if nVal > 9
				nVal := 1 + (nVal-10)
			endif
			nTotal += nVal
			nPeso--
			if nPeso == 0
				nPeso := 2
			endif
		next i
		nAux := nTotal
		while ( nAux % 10 ) > 0
			nCont++
			nAux++
		end
		_cResult := AllTrim( cValToChar( nCont ) )

	Case cBco == "756"		// Sicoob
		
		nVal   := 0
		cDezena := ""
		nResto  := 0
		nCont  := 0
		nPeso   := 2
		
		For i := Len(_cCampo) to 1 Step -1
			
			If nPeso == 3
				nPeso := 1
			Endif
			
			If Val(SubStr(_cCampo,i,1)) * nPeso >= 10
				nVal  := Val(SubStr(_cCampo,i,1)) * nPeso
				nCont += Val(SubStr(Str(nVal,2),1,1)) + Val(SubStr(Str(nVal,2),2,1))
			Else
				nCont += Val(SubStr(_cCampo,i,1)) * nPeso
			Endif
			
			nPeso++
		Next
		
		cDezena  := Substr(Str(nCont,2),1,1)
		nResto   := ((Val(cDezena)+1) * 10) - nCont
		If nResto  == 10
			_cResult := "0"
		Else
			_cResult := Str(nResto,1)
		Endif
		
EndCase

Return(_cResult)

/*/{Protheus.doc} ValidPerg
Fun��o respons�vel pela cria��o do cadastro de perguntas, quando as mesmas n�o existem no sistema
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/12/2021
@param cPerg, character, ID do grupo de perguntas
/*/
Static Function validPerg( cPerg )

	Local i     := 0
	Local j     := 0
	local aRegs := {}

	// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
	aadd(aRegs, {cPerg, "01", "Do Prefixo " , "", "", "mv_ch1", "C", TAMSX3("E1_PREFIXO")[1], 00, 0, "G", "", "mv_par01", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", ""})
	aadd(aRegs, {cPerg, "02", "Ate Prefixo ", "", "", "mv_ch2", "C", TAMSX3("E1_PREFIXO")[1], 00, 0, "G", "", "mv_par02", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", ""})
	aadd(aRegs, {cPerg, "03", "Do Titulo "  , "", "", "mv_ch3", "C", TAMSX3("E1_NUM")[1]    , 00, 0, "G", "", "mv_par03", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "018"})
	aadd(aRegs, {cPerg, "04", "Ate Titulo " , "", "", "mv_ch4", "C", TAMSX3("E1_NUM")[1]    , 00, 0, "G", "", "mv_par04", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "018"})
	aadd(aRegs, {cPerg, "05", "Da Parcela " , "", "", "mv_ch5", "C", TAMSX3("E1_PARCELA")[1], 00, 0, "G", "", "mv_par05", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "011"})
	aadd(aRegs, {cPerg, "06", "Ate Parcela ", "", "", "mv_ch6", "C", TAMSX3("E1_PARCELA")[1], 00, 0, "G", "", "mv_par06", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "011"})
	aadd(aRegs, {cPerg, "07", "Do Cliente " , "", "", "mv_ch9", "C", TAMSX3("E1_CLIENTE")[1], 00, 0, "G", "", "mv_par07", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "SA1"   , "", "001"})
	aadd(aRegs, {cPerg, "08", "Ate Cliente ", "", "", "mv_cha", "C", TAMSX3("E1_CLIENTE")[1], 00, 0, "G", "", "mv_par08", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "SA1"   , "", "001"})
	aadd(aRegs, {cPerg, "09", "Da Loja "    , "", "", "mv_chb", "C", TAMSX3("E1_LOJA")[1]   , 00, 0, "G", "", "mv_par09", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "002"})
	aadd(aRegs, {cPerg, "10", "Ate Loja "   , "", "", "mv_chc", "C", TAMSX3("E1_LOJA")[1]   , 00, 0, "G", "", "mv_par10", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "002"})
	aadd(aRegs, {cPerg, "11", "Banco "      , "", "", "mv_chd", "C", TAMSX3("A6_COD")[1]    , 00, 0, "G", "", "mv_par11", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "SEEBOL", "", "007"})
	aadd(aRegs, {cPerg, "12", "Agencia "    , "", "", "mv_che", "C", TAMSX3("A6_AGENCIA")[1], 00, 0, "G", "", "mv_par12", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "008"})
	aadd(aRegs, {cPerg, "13", "Conta "      , "", "", "mv_chf", "C", TAMSX3("A6_NUMCON")[1] , 00, 0, "G", "", "mv_par13", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , "", "009"})
	aadd(aRegs, {cPerg, "14", "Sub Conta "  , "", "", "mv_chg", "C", TAMSX3("EE_SUBCTA")[1] , 00, 0, "G", "", "mv_par14", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""      , ""})

	dbSelectArea("SX1")
	dbSetOrder(1)
	For i:=1 to Len(aRegs)
		// Valida exist�ncia da pergunta antes de realizar a cria��o
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

Return nil


/*/{Protheus.doc} fSeqNNro
Fun��o para identifica��o e tratamento do pr�ximo sequencial num�rico para execu��o do c�culo do nosso n�mero
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2021
@param cSeqBco, character, sequencia atual dispon�vel no cadastro de par�metros de banco
@return character, cSeq
/*/
Static Function fSeqNNro(cSeqBco)

	Local cSeqNNro := ""

	Do Case
		
		Case aDadosBanco[01] == "004"	// Banco do Nordeste
			cSeqNNro := StrZero(Val(cSeqBco)+1,7,0)
			
		Case aDadosBanco[01] == "001"	// Banco do Brasil
			if Len(AllTrim(aDadosBanco[09])) == 7
				cSeqNNro := StrZero(Val(cSeqBco)+1,10)
			Else
				cSeqNNro := StrZero(Val(cSeqBco)+1,5)
			EndIf
			
		Case aDadosBanco[01] == "033"	// Santander
			cSeqNNro := StrZero(Val(cSeqBco)+1,12)

		Case aDadosBanco[01] == BANRISUL
			cSeqNNro := StrZero(Val(cSeqBco)+1,8)

		Case aDadosBanco[01] == "104"	// Caixa Economica Federal
			cSeqNNro := StrZero(Val(cSeqBco)+1,12)
		
		Case aDadosBanco[01] == "224"	// Fibra
			cSeqNNro := StrZero(Val(cSeqBco)+1,08)
			
		Case aDadosBanco[01] == "237"	// Bradesco
			cSeqNNro := StrZero(Val(cSeqBco)+1,11)

		Case aDadosBanco[01] == "246"	// Banco ABC
			cSeqNNro := StrZero(Val(cSeqBco)+1,11)

		Case aDadosBanco[01] == "320"	// Bic Banco
			cSeqNNro := StrZero(Val(cSeqBco)+1, 06)

		Case aDadosBanco[01] == "341"	// Ita�
			cSeqNNro := StrZero(Val(cSeqBco)+1,8)

		Case aDadosBanco[01] == "399"	// HSBC
			cSeqNNro := StrZero(Val(cSeqBco)+1,10)

		Case aDadosBanco[01] == "422"	// Safra
			cSeqNNro := StrZero(Val(cSeqBco)+1,8)
			
		Case aDadosBanco[01] == "623"	// Panamericano
			cSeqNNro := StrZero(Val(cSeqBco)+1,11)
			
		Case aDadosBanco[01] == "637"	// Banco Sofisa
			cSeqNNro := StrZero(Val(cSeqBco)+1,8)

		Case aDadosBanco[01] == "655"	// Votorantim
			cSeqNNro := StrZero(Val(cSeqBco)+1,10)

		Case aDadosBanco[01] == "707"	// Daycoval
			cSeqNNro := StrZero(Val(cSeqBco)+1,11)
			
		Case aDadosBanco[01] == "745"	// Citibank
			cSeqNNro := StrZero(Val(cSeqBco)+1,11)
		
		Case aDadosBanco[01] == "748"	// Sicredi
			cSeqNNro := Soma1( cSeqBco )

		Case aDadosBanco[01] == "756"	// Sicoob
			cSeqNNro := StrZero(Val(cSeqBco)+1,07)
			
	EndCase

	// Grava imediatamente o sequencial atual nos par�metros de banco para evitar que outro usu�rio consiga utilizar o mesmo nosso n�mero
	DbSelectArea("SEE")
	RecLock("SEE", .F.)
	SEE->EE_FAXATU := cSeqNNro
	SEE->(MsUnlock())

Return cSeqNNro

/*/{Protheus.doc} fCalcDvNN
Fun��o para c�lculo do d�gito verificador do nosso n�mero do boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2021
@param cNumBco, character, base do nosso n�mero (v�m por refer�ncia, logo, pode ser alterado)
@return character, cDVNNro
/*/
Static Function fCalcDvNN( cNumBco )
	
	Local cDv     := Space(1)
	Local i       := 0
	Local j       := 0
	Local nCont   := 0
	Local nPeso   := 0
	Local nResto   := 0
	Local lConv7  := .F.
	Local cNumCon := ""			// Vari�vel para armazenar n�mero da constante de c�lculo
	local cCooper := ""			// codigo da cooperativa
	local cPosto  := "" 		// codigo do posto
	local cBenef  := ""			// codigo do benefici�rio
	local cCalc   := ""			// Vari�vel tempor�ria do conte�do do nosso n�mero a ser utilizado temporariamente para c�lculo do DV
	local cDV1    := "" as character
	local aRetM11 := {}			// Array para retorno da fun��o mod11banri

	Do Case
		
		Case aDadosBanco[01] == "004"		// Banco do Nordeste
			
			nCont   := 0
			nPeso   := 2
			cCalc := cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SUBSTR(cCalc,i,1)) * nPeso)
				nPeso := nPeso + 1
				If nPeso > 8
					nPeso := 2
				Endif
			Next
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 1 .or. nResto == 0
					cDv   := "0"
				OtherWise
					nResto := ( 11 - nResto )
					cDv   := AllTrim(Str(nResto))
			EndCase
			
		Case aDadosBanco[01] == "001"		// Banco do Brasil
			cFator  := ""
			nResto  := 0
			nResult := 0
			nVal1   := 0
			
			lConv7 := Len(aDadosBanco[09]) == 7
			
			if lConv7
				cDv := ""
			Else
				cFator := "78923456789"
				nVal1  := 0
				For i := 1 to Len(cNumBco)
					nResult := Val(Substr(cNumBco,I,1)) * Val(Substr(cFator,I,1))
					nVal1   += nResult
				Next
				
				nResto := nVal1 % 11
				If nResto < 10
					cDv := Alltrim(Str(nResto))
				ElseIf nResto == 10
					cDv := "X"
				ElseIf nResto == 0
					cDv := "0"
				EndIf
			EndIf
		
		Case aDadosBanco[01] == "033"		// Santander
			i       := 0
			nResto   := 0
			nCont   := 0
			nPeso   := 2
			cCalc := AllTrim(cNumBco)
			
			For i := len(cCalc) To 1 step -1
				if nPeso > 9
					nPeso := 2
				EndIf
				nCont := nCont + Val(SUBSTR(cCalc,i,1)) * nPeso
				nPeso++
			Next
			
			nResto := (nCont % 11)
			
			if (nCont % 11 == 10)
				cDv := "1"
			elseif (nCont % 11 == 0) .or. (nCont % 11 == 1)
				cDv := "0"
			else
				cDv := AllTrim(Str(11 - nResto))
			EndIf
		
		Case aDadosBanco[01] == BANRISUL
			aRetM11 := mod11banri( cNumBco )
			cDV1 := aRetM11[1]		// D�gito calculado no Mod10
			cDv  := aRetM11[2]		// D�gito calculado no Mod11

			// Ajusta a base do nosso n�mero devido ao fato do m�dulo 11 poder alterar o d�gito calculado na etapa anterior do Mod10,
			// quando uma exce��o ocorrer no m�dulo 11
			cNumBco := SubStr( cNumBco, 1, 8 ) + cDV1

		Case aDadosBanco[01] == "104"		// Caixa Economica Federal
			nCont   := 0
			i       := 0
			nFator  := 2
			nResto   := 0
			cCalc := Trim(cNumBco)
			
			For i := len(cCalc) to 1 step -1
				nCont += Val(SubStr(cCalc,i,01)) * nFator
				nFator++
				if nFator > 9
					nFator := 2
				EndIf
			Next i
			
			nResto := nCont % 11
			nResto := 11 - nResto
			
			if nResto > 9
				nResto := 0
				cDv := "0"
			Else
				cDv := AllTrim(Str(nResto))
			EndIf
			
		Case aDadosBanco[01] == "224"		// Banco Fibra
			nCont   := 0
			nPeso   := 2
			nTmp    := 0
			cCalc := aDadosBanco[11] + SubStr(aDadosBanco[12],01,05) +;
			aDadosBanco[08] + cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nTmp := (Val(SubStr(cCalc,i,1))) * nPeso
				nCont += iif(nTmp <= 9, nTmp, Val(SubStr(AllTrim(Str(nTmp)),1,1)) + Val(SubStr(AllTrim(Str(nTmp)),2,1)))
				nPeso--
				
				If nPeso == 0
					nPeso := 2
				Endif
			Next
			
			nResto := nCont % 10
			
			if nResto == 0
				cDv := "0"
			Else
				cDv := AllTrim(Str(10 - nResto))
			EndIf

		Case aDadosBanco[01] == "237"		// Bradesco
			nCont   := 0
			nPeso   := 2
			cCalc := aDadosBanco[08] + cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SubStr(cCalc,i,1))) * nPeso
				nPeso := nPeso + 1
				If nPeso == 8
					nPeso := 2
				Endif
				
			Next i
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 1
					cDv := "P"
				Case nResto == 0
					cDv := "0"
				OtherWise
					nResto := ( 11 - nResto )
					cDv := AllTrim(Str(nResto))
			EndCase

		Case aDadosBanco[01] == "246"		// Banco ABC
			nCont   := 0
			nPeso   := 2
			cCalc := ADadosBanco[08] + cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SubStr(cCalc,i,1))) * nPeso
				nPeso := nPeso + 1
				If nPeso == 8
					nPeso := 2
				Endif
			Next
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 1
					cDv := "P"
				Case nResto == 0
					cDv := "0"
				OtherWise
					nResto := ( 11 - nResto )
					cDv   := AllTrim(Str(nResto))
			EndCase
			
		Case aDadosBanco[01] == "320"		// Bic Banco
			nCont   := 0
			nPeso   := 2
			cCalc := aDadosBanco[03] + cNumBco
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SubStr(cCalc,i,1))) * nPeso
				nPeso := nPeso + 1
				If nPeso == 10
					nPeso := 0
				Endif
			Next
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 0
					cDv := "1"
				Case nResto == 1
					cDv := "0"
				Case nResto == 10
					cDv := "1"
				OtherWise
					nResto   := ( 11 - nResto )
					cDv := AllTrim(Str(nResto))
			EndCase

		Case aDadosBanco[01] == "341"		// Ita�
			cData := aDadosBanco[03] + aDadosBanco[05] + aDadosBanco[18] + cNumBco
			cDv   := Mod10Itau(cData)

		Case aDadosBanco[01] == "399"		// HSBC
			i       := 0
			nResto  := 0
			nCont   := 0
			nPeso   := 2
			cBoleta := cNumBco
			
			for i := Len(cBoleta) to 1 Step -1
				nCont := nCont + Val(SubStr(cBoleta,i,1)) * nPeso
				nPeso++
				if nPeso == 8
					nPeso := 2
				EndIf
			Next i
			
			nResto := nCont % 11
			
			If nResto == 0 .or. nResto == 1
				cDv := "0"
			Else
				cDv := AllTrim(Str(11 - nResto))
			EndIf
			
		Case aDadosBanco[01] == "422"		// Safra
			
			cDv	:= sf422DV(cNumBco)

		Case aDadosBanco[01] == "623"		// Panamericano
			nCont   := 0
			nPeso   := 2
			cCalc := aDadosBanco[08] + cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SubStr(cCalc,i,1))) * nPeso
				nPeso := nPeso + 1
				If nPeso == 8
					nPeso := 2
				Endif
				
			Next i
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 1
					cDv := "P"
				Case nResto == 0
					cDv := "0"
				OtherWise
					nResto := ( 11 - nResto )
					cDv := AllTrim(Str(nResto))
			EndCase

		case aDadosBanco[01] == "637"		// Banco Sofisa (correspondente Ita�)
			cData := aDadosBanco[03] + aDadosBanco[05] + aDadosBanco[08] + cNumBco
			cDv   := Mod10Itau(cData)

		Case aDadosBanco[01] == "655"		// Votorantim
			cDv := ""
			
		Case aDadosBanco[01] == "707"		// Daycoval
			nCont   := 0
			nPeso   := 2
			cCalc := aDadosBanco[08] + cNumBco
			
			For i := len(cCalc) To 1 Step -1
				nCont := nCont + (Val(SubStr(cCalc,i,1)) * nPeso)
				nPeso := nPeso + 1
				If nPeso > 7
					nPeso := 2
				Endif
			Next i
			
			nResto := ( nCont % 11 )
			
			Do Case
				Case nResto == 1
					cDv := "P"
				Case nResto == 0
					cDv := "0"
				OtherWise
					nResto := ( 11 - nResto )
					cDv   := AllTrim(Str(nResto))
			EndCase
			
		Case aDadosBanco[01] == "745"		// Citibank
			cDv   := modulo11( cNumBco )
		
		case aDadosBanco[01] == '748'		// Sicredi
			cCooper := aDadosBanco[03]												/* Codigo da Cooperativa */
			cPosto  := iif( Val( aDadosBanco[16] ) == 0, "00", aDadosBanco[16] )	/* Posto Sicredi */
			cBenef  := aDadosBanco[09]												/* Codigo do Benefici�rio */
			cCalc   := cCooper + cPosto + cBenef + cNumBco
			cDv     := modulo11( cCalc )

		Case aDadosBanco[01] == "756"		// Sicoob
			cNumCon := Trim( aDadosBanco[05] )
			nCont   := 0
			j       := 1	
			cCalc := aDadosBanco[03] + aDadosBanco[09] + cNumBco
			For i := 1 to Len(cCalc)
				if j > 4
					j := 1
				EndIf
				
				nCont+= Val( SubStr( cCalc, i, 1 ) ) * Val( SubStr( cNumCon, j, 1 ) )
				
				j++
			Next i
			
			nResto := nCont % 11 
			If nResto == 0 .or. nResto == 1
				cDv := "0"
			Else
				cDv := AllTrim( Str( 11 - nResto ) )
			EndIf
			
	EndCase

Return cDv

/*/{Protheus.doc} modulo11
Fun��o para c�lculo do m�dulo 11
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/13/2022
@param cInfo, character, String contendo o trexo que ser� utilizado como base para c�lculo do DV (obrigat�rio)
@param lCodBar, Logical, indica se o c�lculo do m�dulo 11 foi chamado para c�lcular o DV geral do c�digo de barras
@return character, cDV
/*/
static function modulo11( cInfo, lCodBar )
	
	local cDV    := "" as character
	local nPeso  := 2  as numeric
	local nX     := 0  as numeric
	local nRes   := 0  as numeric
	local nSoma  := 0  as numeric
	local nResto := 0  as numeric
	local nDV    := 0 as numeric

	default lCodBar := .F.

	for nX := len( cInfo ) to 1 step -1
		nRes := val( substr( cInfo, nX, 1 ) ) * nPeso
		nSoma += nRes
		nPeso++
		if nPeso > 9
			nPeso := 2
		endif
	next nX
	nResto := nSoma % 11
	nDV := 11 - nResto
	if nDV > 9
		nDV := 0
	endif
	// tratativa espec�fica para c�lculo do modulo 11 do d�gito verificador do c�digo de barras
	if lCodBar .and. ( nDV == 0 .or. nDV == 1 .or. nDV > 9 )
		nDV := 1
	endif
	cDV := AllTrim( cValToChar( nDV ) )

return cDV

/*/{Protheus.doc} fMontaSeq
FUn��o respons�vel por recuperar a sequ�ncia do nosso n�mero do t�tulo a receber para reimpress�o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/11/2022
@param cNumBco, character, nosso n�mero do t�tulo
@return character, cSequencia
/*/
Static Function fMontaSeq(cNumBco)

Local cSeq    := ""
Local lConv7  := .F.
local cNNro   := cNumBco
local lPE     := ExistBlock( 'BLRESTNN' )		// PE para restaurar nosso n�mero de acordo com as regras da empresa
local cRetPE  := "" as character

if lPE
	cRetPE := ExecBlock( 'BLRESTNN',.F.,.F.,{ aDadosBanco[01], cNumBco } )
	if ValType( cRetPE ) == 'C'
		cNNro := cRetPE
	endif
Endif

Do Case
	
	Case aDadosBanco[01] == "004"		// Banco do Nordeste
		cSeq := StrZero(Val(SubStr(AllTrim(cNNro),1,7)),7)

	Case aDadosBanco[01] == "001"		// Banco do brasil
		lConv7 := Len(aDadosBanco[09]) == 7
		If lConv7
			cSeq := SubStr(Alltrim(cNNro),1,17)
		Else
			cSeq := SubStr(Alltrim(cNNro),1,11)
		EndIf
		
	Case aDadosBanco[01] == "033"		// Santander
		cSeq := SubStr(AllTrim(cNNro),1,12)
	
	Case aDadosBanco[01] == BANRISUL
		cSeq := SubStr(AllTrim(cNNro),1,8) + mod10banri( SubStr(AllTrim(cNNro),1,8) )
		
	Case aDadosBanco[01] == "104"		// Caixa Economica Federal
		cSeq := SubStr(AllTrim(cNNro),1,17)

	Case aDadosBanco[01] == "224"		// Banco Fibra
		cSeq := StrZero(Val(SubStr(cNNro,01,08)),08)

	Case aDadosBanco[01] == "237"		// Banco bradesco
		cSeq := StrZero(Val(SubStr(cNNro,01,11)),11)

	Case aDadosBanco[01] == "246"		// Banco ABC
		cSeq := StrZero(Val(SubStr(cNNro,01,11)),11)

	Case aDadosBanco[01] == "320"		// Banco Bic
		if SE1->E1_EMISSAO <= STOD("20121021")
			cSeq := StrZero(Val(SubStr(cNNro,06,06)),06)
		Else
			cSeq := StrZero(Val(SubStr(cNNro,01,06)),06)
		EndIf

	Case aDadosBanco[01] == "341"		// Banco Ita�
		cSeq := StrZero(Val(SubStr(cNNro,01,08)),08)

	Case aDadosBanco[01] == "399"		// HSBC
		cSeq := StrZero(Val(SubStr(cNNro, 01, 10)),10)

	Case aDadosBanco[01] == "422"		// Banco Safra

		cSeq := StrZero(Val(SubStr(cNNro,01,08)),08) 
		
	Case aDadosBanco[01] == "623"		// Banco Panamericano
		cSeq := StrZero(Val(SubStr(cNNro,01,11)),11)

	Case aDadosBanco[01] == "655"		// Banco Votorantim
		cSeq := SubStr(Alltrim(cNNro),1,17)

	Case aDadosBanco[01] == "707"		// Banco Daycoval
		cSeq := StrZero(Val(SubStr(cNNro,01,11)),11)
		
	Case aDadosBanco[01] == "745"		// Citibank
		cSeq := StrZero(Val(SubStr(cNNro,01,11)),11)

	Case aDadosBanco[01] == '748'		// Sicredi
		cSeq := SubStr( cNNro, 01, 08 )

	Case aDadosBanco[01] == "756"		// Sicoob
		cSeq := StrZero(Val(SubStr(cNNro,01,07)),07)
		
EndCase

Return cSeq 

/*/{Protheus.doc} fValImage
Fun��o que valida exist�ncia da imagem referente � logo do banco no diret�rio system do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco que est� sendo utilizado
@return array, {lExists,cImage}
/*/
Static Function fValImage(cBanco)
	
	Local lRet   := .F. as logical
	Local cImage := "/boletos/"+cBanco+".png"

	Resource2File( cBanco +".png", cImage )
	lRet := File( cImage )

Return {lRet,cImage}

/*/{Protheus.doc} fRetLocPag
Retorna string do local de pagamento conforme especifica��o do layout de cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco
@return character, cLocPag
/*/
Static Function fRetLocPag(cBanco)
Local cRet := ""

Do Case
	
	Case cBanco == "004"		// Banco do Nordeste
		cRet := "AP�S O VENCIMENTO PAGUE SOMENTE NO BANCO DO NORDESTE"
		
	Case cBanco == "001"		// Banco do brasil
		cRet := "PAG�VEL EM QUALQUER BANCO AT� O VENCIMENTO"

	Case cBanco == "033"		// Santander
		cRet := "PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC"
	
	Case cBanco == BANRISUL
		cRet := "PAGAVEL PREFERENCIALMENTE NA REDE INTEGRADA BANRISUL"
		
	Case cBanco == "104"		// Caixa Economica Federal
		cRet := "PREFERENCIALMENTE NAS CASAS LOT�RICAS AT� O VALOR LIMITE"

	Case cBanco == "224"		// Fibra
		cRet := "PAG�VEL EM QUALQUER BANCO AT� A DATA DO VENCIMENTO"

	Case cBanco == "237"		// Bradesco
		cRet := "PAG�VEL PREFERENCIALMENTE NO BRADESCO"
		
	Case cBanco == "246"		// Banco ABC
		cRet := "PAGAVEL PREFERENCIALMENTE NAS AG�NCIAS BRADESCO"
		
	Case cBanco == "320"		// Bic Banco
		cRet := "AT� O VENCIMENTO, PAG�VEL EM QUALQUER AG�NCIA BANC�RIA"
		
	Case cBanco == "341"		// Ita�
		cRet := "AT� O VENCIMENTO, PREF. NO ITA�. AP�S O VENCIMENTO, SOMENTE NO ITA�" 

	Case cBanco == "399"		// HSBC
		cRet := "PAGAR PREFERENCIALMENTE EM AG�NCIA DO HSBC"

	Case cBanco == "422"		// Banco Safra
		cRet := "Pag�vel em qualquer Banco do Sistema de Compensa��o"

	Case cBanco == "623"		// Panamericano
		cRet := "PAG�VEL PREFERENCIALMENTE EM QUALQUER AG�NCIA BRADESCO"

	Case cBanco == "655"		// Banco Votorantim
		cRet := "PAG�VEL EM QUALQUER BANCO AT� O VENCIMENTO"
	
	Case cBanco == "707"		// Banco Daycoval
		cRet := "PAG�VEL PREFERENCIALMENTE EM QUALQUER AG�NCIA BRADESCO"

	Case cBanco == "745"		// Citibank
		cRet := "PAG�VEL NA REDE BANC�RIA AT� O VENCIMENTO"

	case cBanco == '748'		// Sicredi
		cRet := "PAG�VEL PREF. EM CANAIS ELETR�NICOS DA SUA INSTITUI��O FINANCEIRA"

	Case cBanco == "756"		// Sicoob
		cRet := "PAG�VEL EM QUALQUER BANCO AT� A DATA DE VENCIMENTO"
		
EndCase

Return cRet

/*/{Protheus.doc} fRetCed
Fun��o para retornar o c�digo do benefici�rio de acordo com as regras do banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco
@return character, cBeneficiario
/*/
Static Function fRetCed(cBanco)

Local cRet := ""

Do Case
	
	Case cBanco == "004"		// Banco do Nordeste
		cRet := Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99") +;
		"  " + Upper(AllTrim(SM0->M0_NOMECOM))

	Case  cBanco == "001" 		// Banco do brasil
	  	cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
	  	"CNPJ/CPF: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99") 
		
	Case cBanco == "033"		// Santander
		cRet := Upper(AllTrim(SUBSTR( SM0->M0_NOMECOM, 01, 30))) + " " +;
		"CNPJ/CPF: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")
	
	Case cBanco == BANRISUL	
		cRet := "End.: "+ Capital( AllTrim( SM0->M0_ENDCOB ) ) +; 
		iif( !Empty( SM0->M0_COMPENT ), " Compl.: ", "" ) + AllTrim( SM0->M0_COMPENT ) +;
		" Bairro: "+ Capital( AllTrim( SM0->M0_BAIRENT ) ) +;
		" Mun.: "+Capital( AllTrim( SM0->M0_CIDENT ) ) +"-"+ AllTrim( SM0->M0_ESTENT ) +" "+;
		'Cep: '+ Transform(AllTrim( SM0->M0_CEPENT ), "@R 99.999-999" )

	Case cBanco == "104"		// Caixa Economica Federal	
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
		"CNPJ/CPF: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")
		
	Case cBanco == "224"		// Banco Fibra
		cRet := "BANCO FIBRA S/A"

	Case  cBanco == "237" 		// Bradesco
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) 

	Case cBanco == "246"		// Banco ABC
		cRet := "BANCO ABC BRASIL S/A"

	Case cBanco == "320"		// Bic Banco
		cRet := "BCO INDL E COML S.A. (BIC BANCO) " +;
		"CNPJ: 07.450.604/0001-89"
	
	Case cBanco == "341"		// Ita�
		cRet := Upper(AllTrim(SM0->M0_NOMECOM))    

	Case cBanco == "399"		// HSBC
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
		"CNPJ: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")	
		
	Case cBanco == "422"		// Banco Safra
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
		"CNPJ/CPF: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")
		
	Case cBanco == "623"		// Banco Panamericano
		cRet := "BANCO PAN S/A"
		
	Case cBanco == "655"		// Banco Votorantim
		cRet := Upper(AllTrim(SM0->M0_NOMECOM))
		
	Case cBanco == "707"		// Banco Daycoval
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " / " + "BANCO DAYCOVAL S/A"
		
	Case cBanco == "745"		// Citibank
		cRet := Upper(AllTrim(SM0->M0_NOMECOM))

	Case cBanco == '748'		// Sicredi
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
		"CNPJ: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")
	
	Case cBanco == "756"		// Sicoob
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " " +;
		"CNPJ: " + Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99")
		
EndCase

Return cRet

/*/{Protheus.doc} fAgeCodCed
Fun��o para retornar strinng da Ag�ncia/Codigo Benefici�rio conforme layout de cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param aDadosBanco, array, vetor com os dados dos par�metros do banco utilizado
@return character, cAgeCodCed
/*/
Static Function fAgeCodCed(aDadosBanco)

Local cRet := ""
Local cCodAge := ""
Local cCodCed := "" 

Do Case
	
	Case aDadosBanco[01] == "004"		// Banco do Nordeste
		cCodAge := aDadosBanco[03]
		cCodCed := aDadosBanco[05]+"-"+aDadosBanco[6]
		cRet := cCodAge + "  " + cCodCed

	Case aDadosBanco[01] == "001"		// Banco do brasil
		cCodAge := aDadosBanco[03] + "-" + aDadosBanco[04]
		cCodCed := aDadosBanco[05] + "-" + aDadosBanco[06]
		cRet := cCodAge + " / " + cCodCed

	Case aDadosBanco[01] == "033"		// Santander
		cCodAge := aDadosBanco[03] + "-" + aDadosBanco[04]
		cCodCed := aDadosBanco[09]
		cRet := cCodAge + "/" + cCodCed
	
	Case aDadosBanco[01] == BANRISUL
		cCodAge := aDadosBanco[03]
		cCodCed := Trim(aDadosBanco[03]) + Trim( aDadosBanco[09] )
		cRet := cCodAge +" / "+ cCodCed
		
  Case  aDadosBanco[01] == "104" 		// Caixa Economica Federal
      cCodAge := aDadosBanco[03]
      cCodCed := aDadosBanco[09] 
        
       If aDadosBanco[01] == "104" .and. Len(cCodCed) != 12  
          cRet := cCodAge + " / " + SubStr(cCodCed, 01, 06) + "-" + SubStr(cCodCed, 07, 01) 
       
       Else
          cRet := cCodAge + "." + SubStr(cCodCed, 01, 03) + "." + SubStr(cCodCed, 04, 08) + "-" +  SubStr(cCodCed, 12, 01)   
       Endif
               
	Case aDadosBanco[01] == "224"		// Banco Fibra
		cCodAge := aDadosBanco[11]
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed

	Case aDadosBanco[01] == "237"		// Bradesco
		cCodAge := aDadosBanco[03] + "-" +	aDadosBanco[04]
		cCodCed := aDadosBanco[05] + "-" +	aDadosBanco[06]
		cRet := cCodAge + " / " + cCodCed

	Case aDadosBanco[01] == "246"		// Banco ABC
		cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed
		
	Case aDadosBanco[01] == "320"		// Bic Banco
		cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed
		
	Case aDadosBanco[01] == "341"		// Ita�
		cCodAge := aDadosBanco[03]
		cCodCed := aDadosBanco[05] + "-" + aDadosBanco[06]
		cRet := cCodAge + " / " + cCodCed  
	
	Case aDadosBanco[01] == "399"		// HSBC
		cRet := aDadosBanco[03] + " " + aDadosBanco[05] 
		
	Case aDadosBanco[01] == "422"		// Safra
		cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed

	Case aDadosBanco[01] == "623"		// Panamericano
		cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed
		
	Case aDadosBanco[01] == "655"		// Votorantim
		cCodAge := aDadosBanco[03] + "-" + aDadosBanco[04]
		cCodCed := aDadosBanco[05] + "-" + aDadosBanco[06]
		cRet := cCodAge + " / " + cCodCed
		
	Case aDadosBanco[01] == "707"		// Daycoval
		cCodAge := SubStr(aDadosBanco[11], 01, 04) + "-" + SubStr(aDadosBanco[11], 05, 01)
		cCodCed := aDadosBanco[12]
		cRet := cCodAge + " / " + cCodCed
		
	Case aDadosBanco[01] == "745"		// Citibank
		cCodAge := aDadosBanco[03]
		cCodCed := SubStr(aDadosBanco[10],01,01) + "." + SubStr(aDadosBanco[10],02,06) + "." +;
		SubStr(aDadosBanco[10],08,02) + "." + SubStr(aDadosBanco[10],10,01)
		cRet := cCodAge + " / " + cCodCed
	
	Case aDadosBanco[01] == '748'		// Sicredi
		cRet := aDadosBanco[03] + '.' + aDadosBanco[16] +'.'+ aDadosBanco[09]
	
	Case aDadosBanco[01] == "756"		// Sicoob
		cCodAge := aDadosBanco[03]
		cCodCed := aDadosBanco[09]
		cRet    := cCodAge + " / " + cCodCed
		
EndCase

Return cRet

/*/{Protheus.doc} fLbCpoNNro
Define a label do campo do nosso n�mero do boleto conforme o layout definido para cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco utilizado
@return character, cLabelNNro
/*/
Static Function fLbCpoNNro(cBanco)

Local cRet := ""

Do Case

	Case cBanco == "004"		// Banco do Nordeste
		cRet := "Nosso N�mero / Carteira"
		
	Case cBanco == "623"		// Panamericano
		cRet := "Carteira / Nosso N�mero"

	Case cBanco == "707"		// Daycoval
		cRet := "Carteira / Nosso N�mero"
		
	OtherWise
		cRet := "Nosso N�mero"
		
EndCase

Return cRet

/*/{Protheus.doc} fCpoNNro
Retorna a string do campo do nosso n�mero conforme especifica��o de cada entidade financeira
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBoleto, character, String com o corpo do nosso-n�mero
@param cDv, character, DV calculado do nosso-n�mero
@param aDadosBanco, array, vetor com os par�metros de banco da entidade escolhida
@return character, cNossoNumero
/*/
Static Function fCpoNNro(cBoleto, cDv, aDadosBanco)

Local cRet := ""
Local i    := 0

Do Case
	
	Case aDadosBanco[01] == "004"		// Banco do Nordeste
		cRet := Trim(cBoleto) + "-" + Trim(cDv) + "  " + Trim(adadosBanco[08])
		
	Case aDadosBanco[01] == "001"		// Banco do brasil
		lConv7 := .F.
		lConv7 := Len(aDadosBanco[09]) == 7
		if lConv7
			cRet := Trim(cBoleto) + Trim(cDv)
		Else
			cRet := Trim(cBoleto) + "-" + Trim(cDv)
		EndIf
		
	Case aDadosBanco[01] == "033"		// Santander
		cRet := Trim(cBoleto) + " " + Trim(cDv)
	
	Case aDadosBanco[01] == BANRISUL
		cRet := Trim( cBoleto ) + Trim( cDv )
		
	Case aDadosBanco[01] == "104"		// Caixa Economica Federal
		cRet := Trim(cBoleto) + "-" + Trim(cDv)
		
	Case aDadosBanco[01] == "224"		// Banco Fibra
		cRet := aDadosBanco[08] + " / "	+ Trim(cBoleto) + "-" + Trim(cDv)
		
	Case aDadosBanco[01] == "237"		// Bradesco
		cRet := aDadosBanco[08] + " / " + Trim(cBoleto) + "-" +	Trim(cDv)
		
	Case aDadosBanco[01] == "246"		// Banco ABC
		cRet := aDadosBanco[08] + " / " + Trim(cBoleto) + "-" + Trim(cDv)

	Case aDadosBanco[01] == "320"		// Bic Banco
		nCont   := 0
		nPeso   := 2
		cDig    := ""
		cCalc := aDadosBanco[08] + aDadosBanco[09] + SubStr(cBoleto,01,06)
		For i := len(cCalc) To 1 Step -1
			nCont := nCont + (Val(SubStr(cCalc,i,1))) * nPeso
			nPeso := nPeso + 1
			If nPeso == 8
				nPeso := 2
			Endif
		Next
		
		nResto := ( nCont % 11 )
		
		Do Case
			Case nResto == 0
				cDig := "0"
			Case nResto == 1
				cDig := "P"
			OtherWise
				nResto   := ( 11 - nResto )
				cDig := AllTrim(Str(nResto))
		EndCase
		
		cRet := aDadosBanco[08] + " / " + aDadosBanco[09] +	Trim(cBoleto) + "-" +	Trim(cDig)
		
	Case aDadosBanco[01] == "341"		// Ita�
		cRet := aDadosBanco[18] + " / " + Trim(cBoleto) + "-" +	Trim(cDv) 

	Case aDadosBanco[01] == "399"		// HSBC
		cRet := SubStr(Trim(cBoleto), 01, 02) + " " +; 
						SubStr(Trim(cBoleto), 03, 03) + " " +;
						SubStr(Trim(cBoleto), 06, 03) + " " +;
						SubStr(Trim(cBoleto), 09, 02) + " " + cDv

	Case aDadosBanco[01] == "422"		// Banco Safra
		cRet := Trim(cBoleto) + "-" + Trim(cDv)
		
	Case aDadosBanco[01] == "623"		// Panamericano
		cRet := aDadosBanco[08] + " / " + Trim(cBoleto) + "-" +	Trim(cDv)
		
	Case aDadosBanco[01] == "655"		// Votorantim
		cRet := Trim(cBoleto) + Trim(cDv)

	Case aDadosBanco[01] == "707"		// Daycoval
		cRet := aDadosBanco[08] + " / " +	Trim(cBoleto) + "-" + Trim(cDv)
		
	Case aDadosBanco[01] == "745"		// Citibank
		cRet := Trim(cBoleto) + "-" + Trim(cDv)

	Case aDadosBanco[01] == '748'		// Sicredi
		cRet := SubStr( cBoleto, 01, 02 ) +'/'+ SubStr( cBoleto, 03 ) + '-' + cDv
		
	Case aDadosBanco[01] == "756"		// Sicoob
		cRet := Trim(cBoleto) + "-" + Trim(cDv)
		
EndCase

Return cRet

/*/{Protheus.doc} fGerNNro
Fun��o para gera��o da base do nosso n�mero
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2021
@param cSequencia, character, sequencia obtida por meio dos par�metros de banco (obrigat�rio)
@return character, cNossoNumero (sem DV)
/*/
Static Function fGerNNro( cSequencia )

	Local cRet   := ""

	Do Case
		
		Case aDadosBanco[01] == "001"		// Banco do Brasil
			cRet := aDadosBanco[09] + cSequencia
		
		Case aDadosBanco[01] == BANRISUL	// Banrisul
			cRet := cSequencia + mod10banri( cSequencia )

		Case aDadosBanco[01] == "104" 		// Caixa Economica Federal
		
			If aDadosBanco[01] == "104" .and. Len(aDadosBanco[09]) != 12 
			cRet := "1" + "4" + "000" + cSequencia 
			Else 
				cRet := "9" + SubStr(cSequencia, 04,10)   
			EndIf	

		Case aDadosBanco[01] == "320"		// Bic Banco
			cRet := cSequencia

		Case aDadosBanco[01] == "422"		// Safra
			
			cRet := cSequencia 

		Case aDadosBanco[01] == "655"		// Banco Votorantim
			cRet := aDadosBanco[09] + cSequencia
		
		case aDadosBanco[01] == '748'		// Sicredi
			cRet := SubStr(DtoS(SE1->E1_EMISSAO),03,02)  + aDadosBanco[15] + cSequencia
		
		OtherWise
			cRet := cSequencia
	EndCase

Return cRet

/*/{Protheus.doc} fDvBco
Retorna d�gito verificador do c�digo do banco, conforme a entidade recebida por par�metro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/4/2022
@param cBanco, character, C�digo do banco
@return character, cDV
/*/
Static Function fDvBco(cBanco)
	Local cRet := ""

	Do Case

		Case cBanco == "001"	// Banco do Brasil
			cRet := "9"
		
		Case cBanco == "004"	// Banco do Nordeste
			cRet := "3"
			
		Case cBanco == "033"	// Santander
			cRet := "7"

		Case cBanco == BANRISUL
			cRet := "8"

		Case cBanco == "104"	// Caixa Economica Federal
			cRet := "0"

		Case cBanco == "224"	// Fibra
			cRet := "7"

		Case cBanco == "237"	// Bradesco
			cRet := "2"

		Case cBanco == "246"	// Banco ABC
			cRet := "2"

		Case cBanco == "320"	// BicBanco
			cRet := "2"

		Case cBanco == "341"	// Ita�
			cRet := "7"

		Case cBanco == "399"	// HSBC
			cRet := "9"

		Case cBanco == "422"	// Safra
			cRet := "7"

		Case cBanco == "623"	// Panamericano
			cRet := "2"

		case cBanco == "637"	// Sofisa
			cRet := "8"
			
		Case cBanco == "655"	// Votorantim
			cRet := "9"

		Case cBanco == "707"	// Daycoval
			cRet := "2"

		Case cBanco == "745"	// Citibank
			cRet := "5"
		
		cASE cBanco == '748'	// Sicredi
			cRet := 'X'

		Case cBanco == "756"	// Sicoob
			cRet := "0"
			
	EndCase

Return cRet   

/*/{Protheus.doc} fCpoCart
Retorna o c�digo da carteira conforme layout de cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param aDadosBanco, array, vetor com parametros do banco
@return charactere, cCpoCart
/*/
Static Function fCpoCart(aDadosBanco)

Local cRet := ""

Do Case
	
	Case aDadosBanco[01] == "004"		// Bannco do Nordeste
		cRet := aDadosBanco[08]

	Case aDadosBanco[01] == "001"		// Banco do brasil
		cRet := SubStr(aDadosBanco[08],01,02)

	Case aDadosBanco[01] == "033"		// Santander
		if aDadosBanco[13] == "101"
			cRet := aDadosBanco[13] + " - " + "RAPIDA COM REGISTRO"
		Else
			cRet := aDadosBanco[13] + " - " + "COBRAN�A SEM REGISTRO"
		EndIf

	Case aDadosBanco[01] == "104"		// Caixa Economica Federal
		cRet := "CR"
		
	Case aDadosBanco[01] == "224"		// Banco Fibra
		cRet := aDadosBanco[08]

	Case aDadosBanco[01] == "237"		// Bradesco
		cRet := aDadosBanco[08]

	Case aDadosBanco[01] == "246"		// Banco ABC
		cRet := aDadosBanco[08]

	Case aDadosBanco[01] == "320"		// Bic Banco
		cRet := aDadosBanco[08]
	
	Case aDadosBanco[01] == "399"		// HSBC
	 cRet := "CSB"

	Case aDadosBanco[01] == "341"		// Itau
		cRet := aDadosBanco[18]
		
	Case aDadosBanco[01] == "422"		// Safra
		cRet := aDadosBanco[13] 		// Codigo da Carteira ee_codcart 
		
	Case aDadosBanco[01] == "623"		// Panamericano
		cRet := aDadosBanco[08]

	Case aDadosBanco[01] == "655"		// Votorantim
		cRet := SubStr(aDadosBanco[08],01,02)

	Case aDadosBanco[01] == "707"		// Daycoval
		cRet := aDadosBanco[08]
		
	Case aDadosBanco[01] == "745"		// Citibank
		cRet := aDadosBanco[08]
		
EndCase

Return cRet

/*/{Protheus.doc} cCpoUsoBco
Retorna String do campo Uso do Banco conforme o layout de cada um
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, banco em que o boleto est� sendo emitido
@return character, cUsoBco
/*/
Static Function cCpoUsoBco(cBanco)

Local cRet := ""

Do Case
	
	Case cBanco == "320"		// Bic Banco
		cRet := "EXPRESSA"
		
	Case cBanco == "422"		// Safra
		cRet := ""
		
	Case cBanco == "707"		// Daycoval
		cRet := "8600"
		
	Case cBanco == "745"		// Citibank
		cRet := "CLIENTE"
		
	OtherWise
		cRet := " "
		
EndCase

Return cRet

/*/{Protheus.doc} fRetCodBco
Retorna o codigo do banco na linha digit�vel (utilizado tamb�m para tratar codigo do banco correspondente)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, banco em que est� sendo emitido o boleto
@return character, cNewBanco
/*/
Static Function fRetCodBco(cBanco)

Local cRet := ""

Do Case
	
	Case cBanco == "224"		// Banco Fibra
		cRet := "341"
		
	Case cBanco == "246"		// Banco ABC
		cRet := "237"
		
	Case cBanco == "320"		// BIC Banco
		cRet := "237"
		
	Case cBanco == "422"		// Banco Safra
		cRet := "422"

	Case cBanco == "623"		// Banco Panamericano
		cRet := "237"
		
	Case cBanco == "655"		// Votorantim
		cRet := "001"
		
	Case cBanco == "707"		// Daycoval
		cRet := "237"
		
	OtherWise
		cRet := cBanco
		
EndCase

Return cRet

/*/{Protheus.doc} Mod10Itau
Retorna o calculo do MODULO10 ita�
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cParam, character, String base do c�lculo
@return character, cDVItau
/*/
Static Function Mod10Itau(cParam)
Local cRet  := ""
Local cData := cParam
Local L,D,P := 0
Local B     := .F.

L := Len(cData)
B := .T.
D := 0
While L > 0
	P := Val(SubStr(cData, L, 1))
	If (B)
		P := P * 2
		If P > 9
			P := P - 9
		End
	End
	D := D + P
	L := L - 1
	B := !B
End
D := 10 - (Mod(D,10))
If D = 10
	D := 0
End

cRet := AllTrim(Str(D))

Return cRet

/*/{Protheus.doc} fSacAva
Retorna o sacador/avalista conforme especifica��o do layout de cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, codigo do banco utilizado
@return character, cSacAva
/*/
Static Function fSacAva( cBanco )

Local cRet := ""

Do Case

	Case cBanco == "707"		// Daycoval
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " CNPJ: " + Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")
		
	Case cBanco == "001"		// Banco do Brasil
		cRet := " "

	Case cBanco == "033"		// Santander
		cRet := " "

	Case cBanco == BANRISUL
		cRet := " "

	Case cBanco == "320"		// Banco BIC
		cRet := Upper(AllTrim(SM0->M0_NOMECOM)) + " CNPJ: " + Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")

    Case cBanco == "399"		// HSBC																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
		cRet := " "

	Case cBanco == "422"		// Safra
		cRet := " "
	
	Case cBanco == '748'		// Sicredi
		cRet := " "

	Case cBanco == "756"		// Sicoob
		cRet := " "
	
	OtherWise
		cRet := Upper(AllTrim(SM0->M0_NOMECOM))
		
EndCase

Return cRet

/*/{Protheus.doc} fEspDoc
Retorna especie do documento conforme definido no layout do banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, codigo do banco que est� sendo utilizado
@return character, cEspDoc
/*/
Static Function fEspDoc(cBanco)
	Local cRet := ""

	Do Case

		Case cBanco == "745"		// Citibank
			cRet := "DMI"       

		Case cBanco == "399"		// HSBC
			cRet := "PD"
		
		Case cBanco == '748'		// Sicredi
			cRet := "DMI"

		OtherWise
			cRet := "DM"
			
	EndCase

Return cRet

/*/{Protheus.doc} fNroDoc
Fun��o que retorna o n�mero do documento formatado conforme especificado no layout do banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, c�digo do banco utilizado
@return character, cNroDoc
/*/
Static Function fNroDoc(cBanco)
	
	Local cRet := ""

	Do Case
		
		Case cBanco == "745"		// Citibank
			cRet := SubStr(SE1->E1_NUM, 04, 06) + SE1->E1_PARCELA
			
		OtherWise
			cRet := SE1->E1_NUM + SE1->E1_PARCELA
			
	EndCase

Return cRet

/*/{Protheus.doc} fEspecie
Retorna esp�cie da moeda utilizada na emiss�o do t�tulo conforme o banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/06/2022
@param cBanco, character, c�digo do banco utilizado
@return character, cEspecie
/*/
Static Function fEspecie(cBanco)

	Local cRet := ""

	Do Case

		Case cBanco == "033"		// Santander
			cRet := "REAL" 

		Case cBanco == "399"		// HSBC
			cRet := "REAL"
		
		Case cBanco == '748'		// Sicredi
			cRet := "REAL"

		OtherWise
			cRet := "R$"
			
	EndCase

Return cRet

/*/{Protheus.doc} fLbEsp
Define a label do campo Esp�cie
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param cBanco, character, codigo do banco utilizado
@return character, cLabelEspecie
/*/
Static Function fLbEsp(cBanco)
	Local cRet := ""

	Do Case
	Case cBanco == "104"
		cRet := "Moeda "
	Case cbanco == "623"
		cRet := "Moeda "
	OtherWise
		cRet := "Esp�cie"
	EndCase

Return cRet

/*/{Protheus.doc} doPart
Fun��o respons�vel pela impress�o das partes de um boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/23/2021
@param _nVia, numeric, nPart (obrigat�rio)
@param oPrn, object, objeto instanciado para impress�o (obrigat�rio)
/*/
Static Function doPart( _nVia, oPrn )

	local cAux       := ""  as character
	local nColumn    := 0   as numeric
	local nHor       := 02  as numeric // Espa�amento entre o box e a label do campo
	local nVer       := 08  as numeric // Espa�amento entre o texto e o box na vertical
	local nAux       := 0   as numeric
	local oFont1     := Nil
	local oFont2     := Nil
	local oFont3Bold := nil
	local oFont4     := nil
	local oFont5     := nil
	local oFont6     := nil
	local oFont7     := nil
	local oFont8     := nil
	local oFont9Bold := nil
	local oFontBar   := Nil
	local oFont18n   := nil
	local oFontMsg   := nil as object
	local oBckGrd    := TBrush():New(, CLR_HGREY)
	local nLineOld   := 0   as numeric
	local nX         := 0   as numeric

	// Define as fontes que ser�o utilizadas para o processo de impress�o
	oFont1     := TFont():New("Arial"      , , -06,    , .F.,  ,    ,  ,    , .F.) //** T�tulo das Grades
	oFont2     := TFont():New("Arial"      , , -08,    , .F.,  ,    ,  ,    , .F.) //** Conte�do dos Campos
	oFont3Bold := TFont():New("Arial"      , , -15,    , .T.,  ,    ,  ,    , .F.) //** Dados do Recibo de Entrega
	oFont4     := TFont():New("Arial"      , , -12,    , .T.,  ,    ,  ,    , .F.) //** Codigo de Compensa��o do Banco
	oFont5     := TFont():New("Arial"      , , -18,    , .T.,  ,    ,  ,    , .F.) //** Codigo de Compensa��o do Banco
	oFont6     := TFont():New("Arial"      , , -14,    , .T.,  ,    ,  ,    , .F.) //** Conteudo dos Campos em Negrito
	oFont7     := TFont():New("Arial"      , , -10,    , .T.,  ,    ,  ,    , .F.) //** Dados do Cliente
	oFont8     := TFont():New("Arial"      , , -09,    , .F.,  ,    ,  ,    , .F.) //** Conteudo Campos
	oFont9Bold := TFont():New("Arial"      , , -12, .T., .F.,  ,    ,  ,    , .F.) //** Linha Digitavel
	oFont18n   := TFont():New("Arial"      , , -18, .T., .T., 5, .T., 5, .T., .F.) //** Para C�digo do banco
	oFontMsg   := TFont():New("Arial"      , , -07,    , .F.,  ,    ,  ,    , .F.) //** Fonte para impressao das mensagens de instru��o de cobran�a
	oFontBar   := TFont():New('Courier new', , -16, .T.)						   //** Fonte para impressao do codigo de barras do boleto

	cAux    := ""
	nColumn := COL_INI

	// Imprime linha tracejada para indicar local para destacamento das vias
	if _nVia == 1 .or. _nVia == 2
		cAux := Replicate("- ",700)
		oPrn:SayAlign(nLine,nColumn,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_CENTER, V_CENTER)
		nLine += ESP_LINE
	endif

	// Valida se existe imagem de logo pra por no boleto, sen�o imprime o nome do banco
	cAux := fValImage(aDadosBanco[01])[2]
	if fValImage(aDadosBanco[01])[1]
		oPrn:sayBitmap(nLine-4,nColumn,cAux,nColumn+75,ESP_LINE )
	Else
		cAux := aDadosBanco[02]
		oPrn:SayAlign(nLine,nColumn,cAux,oFont3Bold,tamText(cAux, oFont3Bold),Nil/* oFont3Bold:nHeight */, CLR_BLACK, H_LEFT, V_TOP )
	EndIf
	nColumn := 165
	oPrn:Line(nLine,nColumn,nLine+ESP_LINE,nColumn) 	//** Linhas Verticais do Codigo
	cAux := fRetCodBco(aDadosBanco[01])+"-"+cDvCod
	oPrn:sayAlign(nLine,nColumn+nHor,cAux,oFont3Bold, tamText(cAux, oFont3Bold),Nil/* oFont3Bold:nHeight */,CLR_BLACK, H_LEFT, V_CENTER) //** Codigo "001-9"
	oPrn:Line(nLine,nColumn+40,nLine+ESP_LINE,nColumn+40) 	//** Ex:  | 001-9 |
	oPrn:SayAlign(nLine,nColumn, cLinhaDig, oFont9Bold, tamText(cLinhaDig, oFont9Bold),Nil/* oFont9Bold:nHeight */, CLR_BLACK, H_RIGHT, V_CENTER)	// Linha digit�vel

	nColumn := COL_INI
	nLine   += ESP_LINE
	oPrn:Box(nLine,nColumn,nLine+ESP_LINE,nColumn+340) 	//** Local de Pagamento
	cAux := "Local de Pagamento"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,/* tamText(cAux,oFont1) */ 340, Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := fRetLocPag( aDadosBanco[01] )
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,340/* tamText(cAux, oFont2) */, Nil, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 340
	oPrn:Box(nLine,nColumn,nLine+ESP_LINE,nColumn+175) 	//** Vencimento
	// Pinta o campo da data de vencimento para ficar em destaque
	oPrn:FillRect( {nLine+1, nColumn+1, nLine+ESP_LINE-1,nColumn+175-1}, oBckGrd )
	cAux := "Vencimento"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */,CLR_BLACK, H_LEFT, V_TOP)
	cAux := DtoC(SE1->E1_VENCTO)						// converte a data para string com separador para ficar no formato padr�o para ser impresso no boleto
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont7,150,Nil/* oFont7:nHeight */,CLR_BLACK,H_RIGHT,V_TOP)

	nLine   += ESP_LINE
	nColumn := COL_INI
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+340) //** Benefici�rio
	cAux := fLbBenef( aDadosBanco[01] )
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := fRetCed(aDadosBanco[01])
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux, oFont2,tamText(cAux,oFont2), Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 340
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175) //** Agencia / Codigo Benefici�rio
	cAux := "Ag�ncia / C�digo Benefici�rio"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := fAgeCodCed(aDadosBanco)
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux, oFont7,150,Nil/* oFont7:nHeight */, CLR_BLACK, H_RIGHT, V_TOP)

	nColumn := COL_INI
	nLine   += ESP_LINE
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+60) //** Data Documento
	cAux := "Data Doc."
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)               // Data do documento
	cAux := DtoC(SE1->E1_EMISSAO)
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 60
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+80) //** Nr Documento
	cAux := "N�mero Doc."
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)              // N�mero do documento
	cAux := fNroDoc(aDadosBanco[01])
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2)+10, Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 80
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+47) //** Especie Doc
	cAux := "Esp. Doc"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)                 // Esp�cie Doc
	cAux := fEspDoc(aDadosBanco[01])
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,30, Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 47
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+43)	// Aceite
	cAux := "Aceite"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := fRetAce(aDadosBanco)
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2)+10, Nil/* oFont2:nHeight */, CLR_BLACK, H_CENTER, V_TOP)

	nColumn += 43
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+110)	// Data Processamento
	cAux := "Data Processamento"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := DtoC(dDataBase)
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil/* oFont2:nHeight */, CLR_BLACK, H_CENTER, V_TOP)

	nColumn += 110
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)	// Nosso N�mero
	cAux := fLbCpoNNro(aDadosBanco[01])
	oPrn:SayAlign(nLine, nColumn+nHor, cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */,CLR_BLACK, H_LEFT, V_TOP)
	cAux := fCpoNNro(cNossoNum, cDVBol, aDadosBanco)
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont7,150,Nil/* oFont7:nHeight */,CLR_BLACK,H_RIGHT,V_TOP)

	nLine   += ESP_LINE
	nColumn := COL_INI

	// Tratativa espec�fica para estrutura de boleto diferenciada para alguns bancos
	Do Case

	Case aDadosBanco[01] == "320"		// BicBanco

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+52)         							//** Uso do Banco
		cAux := "Uso do Banco"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := cCpoUsoBco(aDadosBanco[01])
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 52
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+25) 									//** CIP
		cAux := "CIP"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := "521"
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,25, Nil, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 25
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+50) 									//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 50

	Case aDadosBanco[01] == "422"		// Safra

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+52)         							//** Uso do Banco
		cAux := "Uso do Banco"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := cCpoUsoBco(aDadosBanco[01])
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 52
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+25) 									//** CIP
		cAux := " "
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := " "
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,25, Nil, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 25
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+50) 									//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 50
	Case aDadosBanco[01] == "623"		// Panamericano

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+52)         							//** Uso do Banco
		cAux := "Uso do Banco"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := cCpoUsoBco(aDadosBanco[01])
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 52
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+25) 									//** CIP
		cAux := "CIP"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := "000"
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 25
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+50) 									//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 50

	Case aDadosBanco[01] == "707"		// Daycoval

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+52)         							//** Uso do Banco
		cAux := "Uso do Banco"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := cCpoUsoBco(aDadosBanco[01])
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 52
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+25) 									//** CIP
		cAux := "CIP"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := "504"
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux, oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 25
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+50) 									//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 50

	Case aDadosBanco[01] == "033"		// Santander

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+127)									//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux, oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		nColumn += 127

	OtherWise

		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+52)         						//** Uso do Banco
		cAux := "Uso do Banco"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := cCpoUsoBco(aDadosBanco[01])
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,tamText(cAux,oFont2), Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn += 52
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+75)      							//** Carteira
		cAux := "Carteira"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux, oFont1), nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		cAux := fCpoCart(aDadosBanco)
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,60, Nil/* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		nColumn += 75

	EndCase

	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+38)         							//** Esp�cie
	cAux := fLbEsp(aDadosBanco[01])
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := fEspecie(aDadosBanco[01])
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont2,30,Nil /* oFont2:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 38
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+102)         							//** Quantidade
	cAux := "Quantidade"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 102
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+73) 									//** Valor
	cAux := "Valor"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nColumn += 73
	oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Valor do documento
	// Pinta de cinza o campo do valor do boleto para dar um destaque maior
	oPrn:FillRect( {nLine+1, nColumn+1, nLine+ESP_LINE-1, nColumn+175-1}, oBckGrd )
	cAux := "(=) Valor do Documento"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := AllTrim( Transform(nValLiq,"@E 999,999,999.99") )
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont7, 150,Nil/* oFont7:nHeight */,CLR_BLACK, H_RIGHT, V_TOP)

	nColumn := COL_INI
	nLine   += ESP_LINE
	if _nVia == 3		// Controle do benefici�rio

		// Cria a �rea de assinatura para controle do benefici�rio
		oprn:box(nLine,nColumn,nLine+(ESP_LINE*4),nColumn+515)								// �rea de assinatura
		nLine += (ESP_LINE*3)
		cAux := " Assinatura: " + Replicate("_",80) + Space(04) +"Data: " + Replicate("_",10) + "/" +Replicate("_", 10) + "/" + Replicate("_", 15)
		oPrn:SayAlign(nLine,nColumn,cAux,oFont1,tamText(cAux,oFont1), Nil /* oFont1:nHeight */, CLR_BLACK, H_CENTER, V_TOP )

	else

		// Quando n�o for controle do benefici�rio, cria os campos de desconto, dedu��es, juros, multa, outros acr�scimos e valor cobrado
		oprn:box(nLine,nColumn,nLine+(ESP_LINE*5),nColumn+340)								// Instru��es
		cAux := lblBenef( _nVia, aDadosBanco[01] )
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP )

		nColumn += 340
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Desconto
		cAux := "(-) Desconto"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		if _nVia == 1			// Ficha de Compensa��o

			// Armazena a linha atual para posteriormente devolver a posi��o para continuar o desenho da estrutura do boleto
			nLineOld := nLine
			nColumn := COL_INI

			// Adequa fonte para mensageria do boleto para que todas caibam no espa�o dedicado para essa finalidade
			oFontMsg := fontMsg( oFontMsg, aMensagem )
			if len( aMensagem ) > 0
				for nX := 1 to len( aMensagem )
					oPrn:SayAlign(nLine+nVer,nColumn+nHor, aMensagem[nX], oFontMsg,tamText(aMensagem[nX],oFontMsg), Nil /* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP )
					nLine += iif( oFontMsg:nHeight > 0, oFontMsg:nHeight*0.8, Abs(oFontMsg:nHeight))
				next nX
			endif

			// Devolve a posi��o da linha para dar continuidade no desenho da estrutura do boleto
			nLine := nLineOld
		elseif _nVia == 2		// Recibo do Pagador

			nLineOld := nLine
			nColumn  := COL_INI

			// Tratativa espec�fica BicBanco para imprimir as mesmas instru��es de cobran�a no recibo do pagador
			if aDadosBanco[01] == "320"			// BicBanco

				// Adequa fonte para mensageria do boleto para que todas caibam no espa�o dedicado para essa finalidade
				oFontMsg := fontMsg( oFontMsg, aMensagem )
				if len( aMensagem ) > 0
					for nX := 1 to len( aMensagem )
						oPrn:SayAlign(nLine+nVer,nColumn+nHor, aMensagem[nX], oFontMsg,tamText(aMensagem[nX],oFontMsg), Nil/* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP )
						nLine += iif( oFontMsg:nHeight > 0, oFontMsg:nHeight*0.8, Abs(oFontMsg:nHeight))
					next nX
				endif

			elseif aDadosbanco[01] == '748'		// Sicredi

				// Adequa fonte para mensageria do boleto para que todas caibam no espa�o dedicado para essa finalidade
				oFontMsg := fontMsg( oFontMsg, aMensagem )
				if len( aMensagem ) > 0
					for nX := 1 to len( aMensagem )
						oPrn:SayAlign(nLine+nVer,nColumn+nHor, aMensagem[nX], oFontMsg,tamText(aMensagem[nX],oFontMsg), Nil/* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP )
						nLine += iif( oFontMsg:nHeight > 0, oFontMsg:nHeight*0.8, Abs(oFontMsg:nHeight))
					next nX
				endif

			ElseIf aDadosBanco[01] == "422" 	// Safra 
				//ESTE BOLETO REPRESENTA DUPLICATA CEDIDA FIDUCIARIAMENTE AO BANCO SAFRA S/A, FICANDO   VEDADO O PAGAMENTO DE QUALQUER OUTRA FORMA QUE N�O ATRAV�S DO PRESENTE BOLETO
				// Adequa fonte para mensageria do boleto para que todas caibam no espa�o dedicado para essa finalidade
				oFontMsg := fontMsg( oFontMsg, aMensagem )
				if len( aMensagem ) > 0
					for nX := 1 to len( aMensagem )
						oPrn:SayAlign(nLine+nVer,nColumn+nHor, aMensagem[nX], oFontMsg,tamText(aMensagem[nX],oFontMsg), Nil/* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP )
						nLine += iif( oFontMsg:nHeight > 0, oFontMsg:nHeight*0.8, Abs(oFontMsg:nHeight))
					next nX
				endif
			else

				// Reseta configura��o original da fonte de mensagens para exibir os dados do benefici�rio
				oFontMsg :=   TFont():New("Arial" ,,-07,,.F.,,,,,.F.)
				cAux := Upper(AllTrim(SUBSTR(SM0->M0_NOMECOM,01,30))) + " CNPJ: "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")
				oPrn:SayAlign(nLine+nVer,nColumn+nHor, cAux, oFontMsg,tamText(cAux, oFontMsg), Nil /* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
				nLine += Abs(oFontMsg:nHeight)
				cAux := Upper(AllTrim(SM0->M0_ENDENT)) +" "+ iif( !Empty( SM0->M0_COMPENT ), "Compl.: ", "" ) + AllTrim( SM0->M0_COMPENT )
				oPrn:SayAlign(nLine+nVer,nColumn+nHor, cAux, oFontMsg, tamText(cAux,oFontMsg), Nil /* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
				nLine += Abs(oFontMsg:nHeight)
				cAux := "Cep: "+ SubStr(SM0->M0_CEPENT,01,02) +"."+ SubStr(SM0->M0_CEPENT,03,03) +"-"+ SubStr(SM0->M0_CEPENT,06,03) +" "+ Upper(AllTrim(SM0->M0_CIDENT)) + "/" + SM0->M0_ESTENT
				oPrn:SayAlign(nLine+nVer,nColumn+nHor, cAux, oFontMsg, tamText(cAux, oFontMsg), Nil /* oFontMsg:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

			endif

			nLine := nLineOld

		endif

		nColumn := COL_INI + 340
		nLine   += ESP_LINE
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Outras Dedu��es (abatimento)
		cAux := "(-) Outras Dedu��es (abatimento)"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1),Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn := COL_INI + 340
		nLine   += ESP_LINE
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Mora / Multa (Juros)
		cAux := "(+) Mora / Multa (Juros)"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux, oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn := COL_INI + 340
		nLine   += ESP_LINE
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Outros Acr�scimos
		cAux := "(+) Outros Acr�scimos"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux, oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

		nColumn := COL_INI + 340
		nLine   += ESP_LINE
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+175)									// Valor Cobrado
		cAux := "(=) Valor Cobrado"
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	Endif

	nLine += ESP_LINE
	nColumn := COL_INI
	oprn:box(nLine,nColumn,nLine+ESP_LINE*2,nColumn+515)									// Pagador
	cAux := "Pagador"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
	cAux := AllTrim( SA1->A1_NOME ) +" CNPJ/CPF: " + iif(  SA1->A1_PESSOA == "J", Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"), Transform(SA1->A1_CGC,"@R 999.999.999-99") )
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont8,tamText(cAux, oFont8), Nil/* oFont8:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nLine += ESP_LINE/2
	cAux  := "Endere�o: "+ AllTrim( SA1->A1_END) +" Bairro: "+ AllTrim( Upper(SA1->A1_BAIRRO) )
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont8,tamText(cAux, oFont8), Nil/* oFont8:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nLine += ESP_LINE/2
	cAux  := "CEP: " + Transform( SA1->A1_CEP, "@R 99.999-999" ) +" Mun.: "+ AllTrim( SA1->A1_MUN )+"/"+SA1->A1_EST
	oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont8,tamText(cAux,oFont8), Nil/* oFont8:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	nLine += ESP_LINE
	// Quando houver sacador/avalista, projeta campo mais largo para que seja poss�vel realizar o preenchimento
	if !Empty( AllTrim( fSacAva(aDadosBanco[01]) ) )
		oprn:box(nLine,nColumn,nLine+ESP_LINE,nColumn+515)
		If aDadosbanco[01] == '422'		// Safra
			cAux  := "Benefici�rio Final"
		Else 
			cAux  := "Sac./Aval."
		Endif 
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)              // Sacador / Avalista
		cAux  := fSacAva( aDadosBanco[01] )
		oPrn:SayAlign(nLine+nVer,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)
		nAux += ESP_LINE
	else
		// Define o box com apenas metade do tamanho pois o campo n�o vai receber conte�do
		oprn:box(nLine,nColumn,nLine+ESP_LINE/2,nColumn+515)									// Sacador/Avalista
		If aDadosbanco[01] == '422'		// Safra
			cAux  := "Benefici�rio Final"
		Else 
			cAux  := "Sac./Aval."
		Endif 
		oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)              // Sacador / Avalista
		nAux += ESP_LINE/2
	endif

	nColumn := COL_INI + 340 
	cAux    := "C�digo de Baixa"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_TOP)

	// Nesse caso utiliza nAux porque vai depender do tamanho que for definido no campo Sacador/Avalista
	nLine   += nAux
	nColumn := COL_INI + 300
	cAux    := "Autentica��o Mec�nica"
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont1,tamText(cAux,oFont1), Nil/* oFont1:nHeight */, CLR_BLACK, H_LEFT, V_BOTTOM)
	cAux    := iif( _nVia == 1, "Ficha de Compensa��o", iif( _nVia == 2, "Recibo do Pagador", "Controle do Benefici�rio" ) )
	nColumn += 80
	oPrn:SayAlign(nLine,nColumn+nHor,cAux,oFont4,130,Nil/* oFont4:nHeight */,CLR_BLACK,H_RIGHT,V_TOP)

	nLine   += ESP_LINE/2
	nColumn := COL_INI
	if _nVia == 1	// Ficha de Compensa��o
		//oPrn:FwMsBar( "INT25",nLine/3.74, nColumn, cCodBar, oPrn,.F.,CLR_BLACK,.T.,0.0164,1.0,.F.,"Arial",Nil,.F.,2,2,.F.)			// Codigo de Barras
		oPrn:Int25( nLine, nColumn, cCodBar, 0.73, 40, .F., .F., oFontBar )
	endif

Return nil

/*/{Protheus.doc} fRetAce
Retorna o codigo de aceite que ser� exibido no boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2022
@param aDadosBanco, array, vetor contendo os parametros do banco utilizado
@return character, cCodAceite
/*/
Static Function fRetAce(aDadosBanco)

	Local cRet := ""

	Do Case
	
		Case aDadosBanco[01] == "399"		// HSBC
			cRet := "N�O"

		OtherWise
			cRet := aDadosBanco[7]

	EndCase

Return cRet

/*/{Protheus.doc} fDadosBanco
Calcula o d�gito verificador do c�digo da empresa, quando necess�rio
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/15/2021
@param aDadosBanco, array, vetor com dados do banco para emiss�o dos boletos
@return character, cNewCodEmp
/*/
Static Function fDadosBanco(aDadosBanco)

	Local cRet := ""
	Local nX   := 0

	Do Case

		// Caixa, quando cobran�a for layout SIGCB
	Case aDadosBanco[01] == '104' .and. Len(aDadosBanco[09]) != 12
		nPeso   := 2
		nSoma   := 0
		nResult := 0
		nResto  := 0

		For nX := Len(aDadosBanco[09]) to 1 step -1
			nSoma += Val(SubStr(aDadosBanco[09], nX, 1)) * nPeso
			nPeso++
		Next nX

		if nSoma < 11
			nResult := 11 - nSoma
		Else
			nResto  := nSoma % 11
			nResult := 11 - nResto
		EndIf

		if nResult > 9
			nResult := 0
		EndIf

		cRet := aDadosBanco[09] + AllTrim(Str(nResult))

	OtherWise
		cRet := aDadosBanco[09]

	EndCase

Return cRet

/*/{Protheus.doc} fAguarda
Fun��o que manda o usu�rio aguardar n segundos at� que outra esta��o finalize o processamento dos boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/14/2021
@param nSegundos, numeric, quantidade de segundos que o usu�rio deve esperar
/*/
Static Function fAguarda(nSegundos)

	Local nX := 0
	ProcRegua(nSegundos)
	For nX := 1 to nSegundos
		IncProc()
		Sleep(1000)
	Next nX

Return

/*/{Protheus.doc} validBco
Fun��o para validar os par�metros de banco recebidos nas perguntas
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/12/2021
@return array, aReturn[lAllOk, cMessage]
/*/
Static Function validBco()

	Local aRet := {}

	DBSelectArea( "SEE" )
	SEE->( DBSetOrder( 1 ) )	// EE_CODIGO + EE_AGENCIA + EE_CONTA + EE_SUBCTA
	if SEE->(FieldPos("EE_X_EMBOL")) > 0 .and. SEE->EE_X_EMBOL

		// Verifica se o banco selecionado pode ser utilizado para emiss�o de boletos.
		if MV_PAR11 $ BANK_HOM
			// Verifica se conseguiu encontrar os par�metros de banco
			if SEE->(dbSeek(xfilial("SEE") + MV_PAR11 + MV_PAR12 + MV_PAR13 + MV_PAR14 ))

				// Valida se o campo customizado est� com valor "true"
				if SEE->EE_X_EMBOL
					aRet := {.T., "" }
				else
					aRet := {.F., "Par�metros desabilitados para o banco: "+ MV_PAR11 +" agencia: "+ Trim(MV_PAR12) +" conta: "+ Trim(MV_PAR13) + " e subconta: "+ MV_PAR14}
				endif

			EndIf
		else
			aRet := {.F., "O banco: "+ MV_PAR11 +" n�o est� homologado para emiss�o de boletos" }
		EndIf

	else
		aRet := {.F., "Par�metros n�o encontrados para o banco: "+ MV_PAR11 +" agencia: "+ Trim(MV_PAR12) +" conta: "+ Trim(MV_PAR13) + " e subconta: "+ Trim(MV_PAR14) +;
			" ou o campo de controle EE_X_EMBOL n�o existe" }
	EndIf

Return aRet

/*/{Protheus.doc} ValidNNum
Fun��o para validar exist�ncia de nosso n�mero j� gravado 
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 14/10/2020
@param cBanco, character, N�mero do Portador
@param cNossoNum, character, Nosso N�mero Calculadoo
@return logical, lNotExist
/*/
Static Function ValidNNum( cBanco, cNossoNum )

	local aArea    := GetArea()
	local nRecOri  := SE1->( Recno() )
	Local lNDuplic := .F.

	DBSelectArea( 'SE1' )
	SE1->( DBOrderNickName( "NUMBCO" ) )		// E1_PORTADO + E1_NUMBCO
	lNDuplic := !SE1->( DBSeek( cBanco + cNossoNum ) )

	// Devolve o recno que estava posicionado
	SE1->( DBGoTo( nRecOri ) )

	restArea( aArea )
Return lNDuplic

/*/{Protheus.doc} fGetSel
Retorna os t�tulos selecionados em formato de vetor
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 17/07/2020
@param oBrowse, object, Objeto do browse de t�tulos selecionados pelo operador
@return array, aSelected
/*/
static function fGetSel( oBrowse )

	local aArea  := GetArea()
	local aRet   := {}
	local cAlias := oBrowse:GetAlias()

	DBSelectArea( cAlias )
	( cAlias )->( DBGoTop() )
	if !( cAlias )->( EOF() )
		while !( cAlias )->( EOF() )

			//Adiciona os t�tulos marcados ao vetor para posterior impress�o
			if ( cAlias )->MARK == cMarca
				aAdd( aRet, ( cAlias )->RECSE1 )
			endif

			( cAlias )->( DBSkip() )
		end										
	endif

	restArea( aArea )
return ( aRet )

/*/{Protheus.doc} fMark
Marca/Desmarca registros no grid
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 25/06/2020
@param cAlias, character, Alias do grid 
@param lAll, logical, Marca tudo?
@param oBrowse, object, objeto do browse que est� sendo alterado
/*/
Static Function fMark( cAlias, lAll, oBrowse )

	local nRec   := ( cAlias )->( Recno() )			// Guarda o Recno da temp-table
	local lMarca := ( cAlias )->MARK != cMarca

	default lAll := .F.

	if lAll

		// Posiciona e marca/desmarca todos os registros da temp-table
		( cAlias )->( DBGoTop() )
		while !( cAlias )->( EOF() )

			// Verifica a regra e marca/desmarca todos os registros
			RecLock( ( cAlias ), .F. )
			( cAlias )->MARK := iif( lMarca, cMarca, Space(2) )
			( cAlias )->( MsUnlock() )

			( cAlias )->( DbSkip() )
		enddo

		// For�a jogar para o topo do browse
		oBrowse:GoTop( .T. /*lFor�a*/ )
		( cAlias )->( DbGoTop() )

	else
		// Altera apenas o registro posicionado
		RecLock( ( cAlias ), .F. )
		( cAlias )->MARK := iif( lMarca, cMarca, Space(2) )
		( cAlias )->( MsUnlock() )

		// Devolve o Recno que estava posicionado anteriormente
		( cAlias )->( DBGoTo( nRec ) )
	endif

return ( Nil )

/*/{Protheus.doc} tamText
Fun��o para definir tamanho do texto em pixels conforme a fonte utilizada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/5/2022
@param cText, character, texto a ser analisado
@param oFont, object, objeto da fonte que ser� utilizada para impress�o
@return numeric, nPixels
/*/
static function tamText(cText, oFont )

	local nWidth := 0 as numeric
	local cAux   := "" as character
	local nX     := 0 as numeric

	if len( AllTrim(cText) ) > 0
		nWidth := 0
		for nX := 1 to len( AllTrim( cText ) )
			cAux := SubStr( AllTrim( cText ), nX, 1 )
			if isUpper( cAux )
				nWidth += iif(oFont:nHeight > 0, oFont:nHeight * 0.8, Abs( oFont:nHeight ) ) * 0.65
			else
				nWidth += iif(oFont:nHeight > 0, oFont:nHeight * 0.8, Abs( oFont:nHeight ) ) * 0.55
			endif
		next nX
	endif

return Round(nWidth,0)

/*/{Protheus.doc} fontMsg
Fun��o para adequar o tamanho da fonte de mensagens para que todas caibam dentro do espa�o pr�-definido para tal finalidade
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 06/01/2022
@param oFntMsg, object, fonte default de mensagens
@param aMensagem, array, vetor contendo todas as mensagens a serem impressas
@return object, oNewFont
/*/
static function fontMsg( oFntMsg, aMensagem )

	local oNewFont := oFntMsg               as object
	local lOk      := .F.                   as logical
	local nTam     := Round(iif(oNewFont:nHeight > 0, oNewFont:nHeight*0.8, Abs(oNewFont:nHeight)),0) as numeric
	local nMax     := (ESP_LINE*5)-10 // o tamanho m�ximo considera o espa�o de 5 linhas, desconsiderando o tamanho ocupado pela label do campo

	while !lOk .and. len( aMensagem ) > 0
		lOk := ((len( aMensagem ) * nTam ) < nMax)
		if !lOk
			nTam-=1
			oNewFont := TFont():New("Arial" ,,(nTam*-1),,.F.,,,,,.F.)
		endif
	enddo

return oNewFont

/*/{Protheus.doc} lblBenef
Fun��o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 06/01/2022
@param nVia, numeric, 1=Ficha de Compensa��o 2=Recibo do Pagador 3=Controle do Benefici�rio
@param cBanco, character, c�digo do banco que est� sendo utilizado para impress�o do boleto
@return character, cLabel
/*/
static function lblBenef( nVia, cBanco )

	local cLabel := iif( nVia == 1, "Instru��es (todas as instru��es desse bloqueto s�o de exclusiva responsabilidade do benefici�rio)", "Dados do benefici�rio" )

	Do Case
		
		Case cBanco == "320" .and. nVia == 2		//  BicBanco
			cLabel := "Instru��es (todas as instru��es desse bloqueto s�o de exclusiva responsabilidade do benefici�rio)"

 		Case cbanco == '748' .and. nVia == 2		// Sicredi
			cLabel := "Instru��es (todas as instru��es desse bloqueto s�o de exclusiva responsabilidade do benefici�rio)"

	endCase

return cLabel

/*/{Protheus.doc} validCustom
Fun��o para validar exist�ncia de campos customizados para gera��o dos boletos de cada banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/13/2022
@param cBanco, character, codigo do banco que est� sendo usado para emitir o boleto
@return array, aMessages
/*/
static function validCustom( cBanco )
	
	local aMessage := {} as array

	// Valida estrutura customizada do campo Byte Sicredi
	if cbanco == '748' .and. SEE->( FieldPos( 'EE_X_BYTE' ) ) == 0
		aAdd( aMessage, 'CAMPO PERSONALIZADO EE_X_BYTE (Byte Sicredi) NAO LOCALIZADO NO CADASTRO DE PARAMETROS DE BANCOS' )
	endif

	// Valida estrutura customizada do campo Posto Sicredi
	if cBanco == '748' .and. SEE->( FieldPos( 'EE_X_POSTO' ) ) == 0
		aAdd( aMessage, 'CAMPO PERSONALIZADO EE_X_POSTO (Posto Sicred) NAO LOCALIZADO NO CADASTRO DE PARAMETROS DE BANCOS' )
	endif

	// Valida campo conta cosmo Citibank
	if cBanco == '745' .and. SEE->( FieldPos( 'EE_X_COSMO' ) ) == 0 
		aAdd( aMessage, 'CAMPO PERSONALIZADO EE_X_COSMO (Conta Cosmo) NAO LOCALIZADO NO CADASTRO DE PARAMETROS DE BANCOS' )
	endif
	
return aMessage




//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 29/08/2011
// Nome fun��o: st422DV
// Parametros : Codigo a calcular digito verificador do DV do Nosso N�mero do Banco Safra
// Objetivo   : Retornar digito verificador Modulo 11 do Nosso N�mero Safra
// Retorno    : Digito Verificador
// Altera��es :
//---------------------------------------------------------------------------------------
Static Function sf422DV(cInCod)


	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	// Resto da Divis�o
	nSumDv	:= Mod(nSumDv,11)

	// Se Resto for Zero, o DV ser� Um
	// Se Resto for Um, o DV ser� Zero
	If nSumDv == 0    	// Igual a 0
		nSumDv := 1		// Sempre ser� um
	ElseIf nSumDv == 1  // Igual a Um
		nSumDv := 0 	// Sempre ser�  Zero
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)

/*/{Protheus.doc} fLbBenef
Fun��o para retornar a label do campo benefici�rio
@type function
@version 12.1.2310
@author Jean Carlos Pandolfo Saggin
@since 19/10/2024
@param cBanco, character, ID do banco que est� sendo utilizado para gera��o do boleto
@return character, cData benfe,,,
/*/
static function fLbBenef( cBanco )
	
	local cLblBenef := "Benefici�rio: " as character

	if cBanco == BANRISUL
		cLblBenef += AllTrim( SM0->M0_NOMECOM ) + " CGC/CPF: "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")
	endif

return cLblBenef
