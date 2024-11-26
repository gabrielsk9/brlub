#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} sfNew
(Verifica a existencia da conta e chama o cadastro auto)
@author Marcelo Lauschner
@since 11/12/2013
@version 1.0
@return sem retorno
/*/
User Function BFCTBM24(cA2XCCPASV,cA2COD,cA2NOME)

	Local	oModelA1 	:= FWModelActive()//->Carregando Model Ativo
	local   cPREFCTA    := AllTriM( SuperGetMv( 'BF_PREFCTA',,'210101' ) )

	If ALTERA .Or. INCLUI
		If Empty(cA2XCCPASV)
			DbSelectArea("CT1")
			DbSetOrder(6) //CT1_DESC01
			If DbSeek(xFilial("CT1")+cA2COD+"-"+cA2NOME) .Or. ;
					DbSeek(xFilial("CT1")+cA2NOME)
				MsgAlert("Já existe a conta contábil '"+CT1->CT1_CONTA+"' com a descrição '"+CT1->CT1_DESC01,"Conta já existe")
				cA2XCCPASV	:= CT1->CT1_CONTA
				If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
					oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
				Endif
				If Type("M->A2_XCCPASV") == "C"
					M->A2_XCCPASV	:= cA2XCCPASV
				Endif
			Else
				//sfExec('210104',M->A2_NOME)
				// Para empresa Redelog o Grupo de contas de Fornecedores é 210101
				sfModelCT1( cPREFCTA,cA2NOME)

				DbSelectArea("CT1")
				DbSetOrder(6) //CT1_DESC01
				If DbSeek(xFilial("CT1")+cA2COD+"-"+cA2NOME) .Or. ;
						DbSeek(xFilial("CT1")+cA2NOME)
					cA2XCCPASV	:= CT1->CT1_CONTA
					If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
						oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
					Endif
					If Type("M->A2_XCCPASV") == "C"
						M->A2_XCCPASV	:= cA2XCCPASV
					Endif
				Endif
			Endif
		Else
			MsgAlert("Já há Conta Contábil informada no campo Conta Passivo","A T E N Ç Ã O!!")
		Endif
	Endif

Return .T.


/*/{Protheus.doc} sfExec
(long_description)

@author MarceloLauschner
@since 12/12/2013
@version 1.0

@param cCodSup, character, (Descrição do parâmetro)
@param cDescCT1, character, (Descrição do parâmetro)

/*/
Static Function sfExec(cCodSup,cDescCT1)

	Local nX,nY
	Local aItens 		:= {}
	Local aCab			:= {}
	Local cNextCT1  	:= ""
	Local cCodCT1   	:= cCodSup + "001"
	Local cAliasS1
	Local cCdPlanoRef	:= IIf(cEmpAnt=="06","000001","014")
	PRIVATE lMsErroAuto := .F.

	cAliasS1  := GetNextAlias()

	BeginSql Alias cAliasS1
		SELECT COALESCE(MAX(CT1_CONTA),%Exp:cCodCT1%) NEXTCT1
		FROM %Table:CT1% CT1
		WHERE CT1.%NotDel%
		AND CT1_FILIAL = %xFilial:CT1%
		AND CT1_CTASUP = %Exp:cCodSup%
	EndSql

	If !Eof()
		cNextCT1	:= Soma1(Padr((cAliasS1)->NEXTCT1,9))
	Endif
	(cAliasS1)->(DbCloseArea())


	If !Empty(cNextCT1)
		If cNextCT1 < cCodSup + "999"

			aCab 		:= {;
				{'CT1_CONTA'  	,cNextCT1 						,NIL},;
				{'CT1_DESC01' 	,cDescCT1				 		,NIL},;
				{'CT1_CLASSE' 	,'2' 							,NIL},;
				{'CT1_NORMAL' 	,'2' 							,NIL},;
				{'CT1_BLOQ'   	,'2'							,NIL},;
				{'CT1_DTEXIS' 	,FirstDay(FirstDay(dDataBase)-1),NIL},;
				{'CT1_CTALP' 	,'240203003'					,NIL},;
				{'CT1_NTSPED' 	,'02'							,NIL},;		// Natureza Conta Sped - 02-Passivo
				{'CT1_ACCUST' 	,'2'                        	,NIL},; 	// Aceita Centro de Custo - 2=Não
				{'CT1_SPEDST' 	,'2'                       		,NIL},;		//
				{'CT1_INDNAT' 	,'2'							,NIL},;		// Classe Manad - 2-Passivo
				{'CT1_NATCTA' 	,'02'                       	,NIL}}		// Natureza da Conta = 02-Passivo
			If cEmpAnt == "14"
				Aadd(aCab,{'CT1_GRUPO'	,'00020000'						,NIL})
			Endif 

			DbSelectArea("CVD")
			DbSetOrder(1)
			//as linhas da getdados do plano referencial sempre devem ser do mesmo plano
			aAdd(aItens,{;
				{'CVD_FILIAL'  	,CVD->(xFilial('CVD'))   						, NIL},;
				{'CVD_CONTA'  	,PadR(cNextCT1,Len(CVD->CVD_CONTA))   			, NIL},;
				{'CVD_ENTREF' 	,'10'   										, NIL},;
				{'CVD_CODPLA'  	,PadR(cCdPlanoRef,Len(CVD->CVD_CODPLA)) 		, NIL},;
				{'CVD_CTAREF'  	,PadR('2.01.01.03.01', Len(CVD->CVD_CTAREF))	, NIL},;
				{'CVD_CLASSE'  	,'2' 											, NIL},;
				{'CVD_TPUTIL'  	,'A' 											, NIL},;				
				{'CVD_NATCTA'  	,'02' 											, NIL},;
				{'CVD_CTASUP'  	,'2.01.01.03'									, NIL}})

			//necessario jogar para variavel de memoria os campos do acols
			For nX := 1 TO Len(aItens)
				For nY := 1 TO Len(aItens[nX])
					_SetOwnerPrvt( aItens[nX,nY,1], aItens[nX,nY,2] )
				Next
			Next
			//necessario retirar os gatilhos da tabela "CVD" para nao influir na inclusao dos itens da grade
			// dbSelectArea("SX7")
			// dbSetOrder(1)
			// dbSeek("CVD_")
			// While ! Eof() .And. Left(x7_campo,4) == "CVD_"
			// 	aAdd(aRecSX7, Recno())
			// 	//salva os recnos para recuperar depois da msexecauto
			// 	Reclock("SX7", .F.)
			// 	dbDelete()
			// 	MsUnlock()
			// 	dbSkip()
			// EndDo
			MSExecAuto( {|X,Y,Z| CTBA020(X,Y,Z)} ,aCab , 3, aItens)

			If lMsErroAuto <> Nil
				If !lMsErroAuto
					If !IsBlind()
						MsgInfo('Inclusão com sucesso!')
					EndIf
				Else
					If !IsBlind()
						MostraErro()
						MsgAlert('Erro na inclusao!')
					Endif
				EndIf
			EndIf
			//volta os gatilhos para inclusao manual das amarracoes a conta referencial
			// dbSelectArea("SX7")
			// For nX := 1 TO Len(aRecSX7)
			// 	dbGoto(aRecSX7[nX])
			// 	Reclock("SX7", .F.)
			// 	dbRecall()
			// 	MsUnlock()
			// Next
		Else
			MsgAlert("Estourou limite de criação de contas deste grupo. Favor informar CPD para mudar faixa de numeração!","Estouro de faixa de contas")
		Endif
	Else
		MsgAlert("Erro ao obter dados para incluir conta contábil automática!","Erro Select")
	Endif

Return


//Exemplo de rotina automática para inclusão de contas contábeis no ambiente Contabilidade Gerencial (SigaCTB).
/// ROTINA AUTOMATICA - INCLUSAO DE CONTA CONTABIL CTB
Static Function sfModelCT1(cCodSup,cDescCT1)

	Local cNextCT1  	:= ""
	Local cCodCT1   	:= cCodSup + "001"
	Local nOpcAuto :=0
	Local oCT1
	Local aLog
	Local cLog :=""
	Local lRet := .T.
	Local __oModelAut
	Local oCVD
	local nX
	local lExists := .T. as logical

	PRIVATE lMsErroAuto := .F.

	cNextCT1 := cCodCT1

	// Percorre a tabela CT1 verificando por faixas de contas contábeis não utilizadas
	DBSelectArea( "CT1" )
	CT1->( DBSetOrder( 1 ) )
	while lExists .and. cNextCT1 < (cCodSup + "999")
		lExists := CT1->( DBSeek( FWxFilial( "CT1" ) + cNextCT1 ) )
		if lExists
			cNextCT1 := Soma1( cNextCT1 )
		endif
	enddo

	If !Empty(cNextCT1)
		If cNextCT1 < cCodSup + "999"

			If __oModelAut == Nil //somente uma unica vez carrega o modelo CTBA020-Plano de Contas CT1
				__oModelAut := FWLoadModel('CTBA020')
			EndIf


			nOpcAuto:=3


			__oModelAut:SetOperation(nOpcAuto) // 3 - Inclusão | 4 - Alteração | 5 - Exclusão
			__oModelAut:Activate() //ativa modelo

			//---------------------------------------------------------
			// Preencho os valores da CT1
			//---------------------------------------------------------

			oCT1 := __oModelAut:GetModel('CT1MASTER') //Objeto similar enchoice CT1
			oCT1:SETVALUE('CT1_CONTA'		,cNextCT1)
			oCT1:SETVALUE('CT1_DESC01'		,Padr(cDescCT1,Len(CT1->CT1_DESC01)))
			oCT1:SETVALUE('CT1_CLASSE'		,'2')
			oCT1:SETVALUE('CT1_NORMAL' 		,'2')
			oCT1:SETVALUE('CT1_BLOQ' 		,'2')
			oCT1:SETVALUE('CT1_DTEXIS' 		,FirstDay(FirstDay(dDataBase)-1))
			oCT1:SETVALUE('CT1_CTALP' 		,'240203003')
			If cEmpAnt == "14"
				oCT1:SETVALUE('CT1_GRUPO' 		,'00020000')
			Endif 
			oCT1:SETVALUE('CT1_NTSPED'	 	,'02')
			oCT1:SETVALUE('CT1_ACCUST' 		,'2')
			oCT1:SETVALUE('CT1_SPEDST' 		,'2')
			oCT1:SETVALUE('CT1_NATCTA' 		,'02')
			oCT1:SETVALUE('CT1_INDNAT' 		,'2')		// Classe Manad - 2-Passivo

			//---------------------------------------------------------
			// Preencho os valores da CVD
			//---------------------------------------------------------

			oCVD := __oModelAut:GetModel('CVDDETAIL') //Objeto similar getdados CVD

			oCVD:SETVALUE('CVD_FILIAL' ,CVD->(xFilial('CVD')))
			oCVD:SETVALUE('CVD_ENTREF','10')
			If cEmpAnt == "14"
				oCVD:SETVALUE('CVD_CODPLA',PadR('014LP',Len(CVD->CVD_CODPLA)))
			ElseIf cEmpAnt == "06"
				oCVD:SETVALUE('CVD_CODPLA',PadR('000001',Len(CVD->CVD_CODPLA)))
			Else
				oCVD:SETVALUE('CVD_CODPLA',PadR('014',Len(CVD->CVD_CODPLA)))
			Endif
			oCVD:SETVALUE('CVD_VERSAO',PadR('0001',Len(CVD->CVD_VERSAO)))
			oCVD:SETVALUE('CVD_CTAREF',PadR('2.01.01.03.01', Len(CVD->CVD_CTAREF)))// 2.01.01.03.01
			oCVD:SETVALUE('CVD_CUSTO',' ')
			oCVD:SETVALUE('CVD_CLASSE','2')
			oCVD:SETVALUE('CVD_TPUTIL','A')
			oCVD:SETVALUE('CVD_NATCTA','02')
			oCVD:SETVALUE('CVD_CTASUP',Padr('2.01.01.03',Len(CVD->CVD_CTASUP)))	//2.01.01.03

			//---------------------------------------------------------
			// Preencho os valores da CTS
			//---------------------------------------------------------


			//	oCTS := __oModelAut:GetModel('CTSDETAIL') //Objeto similar getdados CTS
			//	oCTS:SETVALUE('CTS_FILIAL' ,CTS->(xFilial('CTS')))
			//	oCTS:SETVALUE('CTS_CODPLA' ,'001')
			//	oCTS:SETVALUE('CTS_CONTAG' ,'0000021')


			If __oModelAut:VldData() //validacao dos dados pelo modelo
				__oModelAut:CommitData() //gravacao dos dados
			Else

				aLog := __oModelAut:GetErrorMessage() //Recupera o erro do model quando nao passou no VldData

				//laco para gravar em string cLog conteudo do array aLog
				For nX := 1 to Len(aLog)
					If !Empty(aLog[nX])
						cLog += Alltrim(aLog[nX]) + CRLF
					EndIf
				Next nX

				lMsErroAuto := .T. //seta variavel private como erro
				AutoGRLog(cLog) //grava log para exibir com funcao mostraerro
				mostraerro()
				lRet := .F. //retorna false

			EndIf

			__oModelAut:DeActivate() //desativa modelo
		Else
			MsgAlert("Estourou limite de criação de contas deste grupo. Favor informar CPD para mudar faixa de numeração!","Estouro de faixa de contas")
		Endif
	Else
		MsgAlert("Erro ao obter dados para incluir conta contábil automática!","Erro Select")
	Endif
Return( lRet )
