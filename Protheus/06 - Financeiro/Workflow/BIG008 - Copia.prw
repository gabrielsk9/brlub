#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

User Function BIG008
	
	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
	±±ºPrograma  ³BIG008 º Autor ³ Marcelo       º Data ³  23/11/04           º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºDescricao ³ Enviar workflow da inadimplência diária                    º±±
	±±º          ³                                                            º±±
	±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
	±±ºUso       ³ Sigafat                                                    º±±
	±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	/*/
	
	sfExec()
	
Return

User Function BIG008SC()
	
	Local xCodEmp := "14" 	// Empresa
	Local xCodFil := "01" 	// Filial

	Local aOpenTable := {"SE1","SA1","SA6","SK1"}
	
	If (Select("SE1") == 0)
		RPCSetEnv(xCodEmp,xCodFil,"","","","","",aOpenTable) // Abre todas as tabelas.
	Endif
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	sfExec()
	
Return


Static Function sfExec(xCodEmp,xCodFil)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	
	// Cria um novo processo...
	cProcess := "100002"
	cStatus  := "100002"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Envio diário inadimplência Atrialub"))
	//Abre o HTML criado
	
	If IsSrvUnix()
		If File("/workflow/inadimplencia_diaria.htm")
			oProcess:NewTask("Gerando HTML","/workflow/inadimplencia_diaria.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/inadimplencia_diaria.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\inadimplencia_diaria.HTM")
	Endif
	
	oProcess:cSubject := "Inadimplência Brlub "
	
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML
	nTotal := 0


	//Adicionado sessão para clientes em cartório
	cQry := ""
	cQry += "SELECT E1_PREFIXO, E1_NUM, E1_PARCELA, E1_VEND1, E1_CLIENTE, E1_PORTADO, "
	cQry += "       E1_VALJUR, E1_VENCREA, E1_EMISSAO, E1_AGEDEP, E1_CONTA, "
	cQry += "       E1_TIPO, E1_LOJA, E1_VEND2, E1_SALDO,(R_E_C_N_O_) AS ITEM "
	cQry += "       K1_PREFIXO, K1_NUM, K1_PARCELA, K1_CLIENTE, K1_PORTADO, "
	cQry += "       K1_XSTATUS, K1_LOJA, K1_(R_E_C_N_O_) AS ITEM_SK1 "
	cQry += "  FROM " + RetSqlName("SE1") + " SE1 "
	cQry += "  INNER JOIN " + RetSqlName("SK1") + " SK1 ON SE1.E1_CLIENTE = SK1.K1_CLIENTE " // Relacionamento das tabelas
	cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SK1.D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_TIPO NOT IN ('NCC', 'RA ') "// Filtro ativado novamente em 26/04/2011 a Pedido de Maria Zaniz
	cQry += "   AND E1_VENCREA <= '" + DTOS(Date() - 3) + "' "
	cQry += " ORDER BY E1_VEND1, E1_PREFIXO, E1_NUM, E1_PARCELA "
	
	TCQUERY cQry NEW ALIAS "QRG"
	
	nTotVend1 :=0.00
	While !Eof()
		
		dbselectarea("SA1")
		dbsetorder(1)
		dbseek(xFilial("SA1")+QRG->E1_CLIENTE+QRG->E1_LOJA)
		
		dbselectarea("SA3")
		dbsetorder(1)
		dbseek(xFilial("SA3")+QRG->E1_VEND1)
		
		dbselectarea("SA6")
		dbsetorder(1)
		dbseek(xFilial("SA6")+QRG->E1_PORTADO+QRG->E1_AGEDEP+QRG->E1_CONTA)

		dbselectarea("SK1")
		dbsetorder(1)
		dbseek(xfilial("SK1")+QRG->K1_PORTADO)
		
		
		AAdd((oHtml:ValByName("l.titulo" )),QRG->E1_NUM + "-" + QRG->E1_PARCELA)	//titulo parcela
		AAdd((oHtml:ValByName("l.cliente" )),QRG->E1_CLIENTE + "/" + QRG->E1_LOJA)      //codigo cliente loja
		AAdd((oHtml:ValByName("l.clienome" )),SA1->A1_NOME)                         //nome cliente
		If QRG->E1_TIPO == 'NCC'
			AAdd((oHtml:ValByName("l.tp" )),"NF D")                     //se for devolucao
		Else
			AAdd((oHtml:ValByName("l.tp" )),"NF N")                           //nome red vendedor
		Endif
		AAdd((oHtml:ValByName("l.vend" )),SA3->A3_NREDUZ)                           //nome red vendedor
		AAdd((oHtml:ValByName("l.emissao" )),STOD(QRG->E1_VENCREA) - STOD(QRG->E1_EMISSAO))     //prazo vcto titulo
		AAdd((oHtml:ValByName("l.vcto" )),STOD(QRG->E1_VENCREA))                          //data vencimento real
		aadd((oHtml:ValByName("l.atras" )),(date() - STOD(QRG->E1_VENCREA)))              //dias de atraso
		AAdd((oHtml:ValByName("l.vltit" )),transform(QRG->E1_SALDO,'@E 999,999.99'))//saldo do titulo
		AAdd((oHtml:ValByName("l.juros" )),transform(QRG->E1_VALJUR*(date() - STOD(QRG->E1_VENCREA)),'@E 999,999.99'))
		AAdd((oHtml:ValByName("l.port" )),QRG->E1_PORTADO+"-"+SA6->A6_NREDUZ)
		nTotal += QRG->E1_SALDO

		//Clientes em cartório
		AAdd((oHtml:ValByName("c.titulo" )),QRG->E1_NUM + "-" + QRG->K1_PARCELA)//titulo parcela
		AAdd((oHtml:ValByName("c.cliente" )),QRG->E1_CLIENTE + "/" + QRG->K1_LOJA)//codigo cliente loja
		AAdd((oHtml:ValByName("c.clienome" )),SA1->A1_NOME)//nome cliente

		If QRG->K1_TIPO == 'NCC'
			AAdd((oHtml:ValByName("c.tp" )),"NF D") //se for devolucao
		Else
			AAdd((oHtml:ValByName("c.tp" )),"NF N")//Nota normal
		Endif

		AAdd((oHtml:ValByName("c.vend" )),SA3->A3_NREDUZ)                           //nome red vendedor
		AAdd((oHtml:ValByName("c.emissao" )),STOD(QRG->E1_VENCREA) - STOD(QRG->E1_EMISSAO))     //prazo vcto titulo
		AAdd((oHtml:ValByName("c.vcto" )),STOD(QRG->K1_VENCREA))                          //data vencimento real
		aadd((oHtml:ValByName("c.atras" )),(date() - STOD(QRG->K1_VENCREA)))              //dias de atraso
		AAdd((oHtml:ValByName("c.vltit" )),transform(QRG->K1_SALDO,'@E 999,999.99'))//saldo do titulo
		AAdd((oHtml:ValByName("c.juros" )),transform(QRG->E1_VALJUR*(date() - STOD(QRG->K1_VENCREA)),'@E 999,999.99'))//Juros acumulados
		AAdd((oHtml:ValByName("c.port" )),QRG->K1_PORTADO+"-"+SA6->A6_NREDUZ)//Portador
		
		dbselectarea("QRG")
		DBSKIP()
	Enddo
	
	QRG->(DbCloseArea())
	
	Aadd((oHtml:ValByName("p.tmk")),"Total Inadimplência -> ")
	Aadd((oHtml:ValByName("p.valor")),Transform(nTotal,"@E 999,999,999.99"))

	Aadd((oHtml:ValByName("p.tmk")),".")
	Aadd((oHtml:ValByName("p.valor")),".")

	cQry := ""
	cQry += "SELECT SUM(E1_SALDO) AS TOT14,A3_COD,A3_NREDUZ "
	cQry += "  FROM "+RetSqlName("SE1") + " SE1, " + RetSqlName("SA3") + " SA3 "
	cQry += " WHERE SE1.D_E_L_E_T_ = ' ' AND SA3.D_E_L_E_T_ = ' '"
	cQry += "   AND SA3.A3_FILIAL = '" + xFilial("SA3")+"' "
	cQry += "   AND SE1.E1_SALDO > 0  "
	cQry += "   AND SE1.E1_VENCREA <= '" + DTOS(Date()-3) + "' "
	cQry += "   AND SE1.E1_VEND1 = SA3.A3_COD "
	cQry += "   AND E1_TIPO NOT IN('NCC','RA ') "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1") + "' "
	cQry += "GROUP BY A3_COD,A3_NREDUZ "
	
	TCQUERY cQry NEW ALIAS "QRG"
	
	nAcobrar := 0.00
	
	While !Eof()
		
		Aadd((oHtml:ValByName("p.tmk")),QRG->A3_COD + "-"+QRG->A3_NREDUZ)
		Aadd((oHtml:ValByName("p.valor")),Transform(QRG->TOT14,"@E 999,999,999.99"))
		nAcobrar += QRG->TOT14
		
		Dbselectarea("QRG")
		Dbskip()
	Enddo
	QRG->(DbCloseArea())
	
	Aadd((oHtml:ValByName("p.tmk")),"TOTAL A COBRAR -> ")
	Aadd((oHtml:ValByName("p.valor")),Transform(nAcobrar,"@E 999,999,999.99"))
	
	
	oProcess:ClientName(Substr(cUsuario,7,15))
	
	// Controle de destinatarios sera feito pelo S4 ( Favor conferir no apelido em contas de email para remover\adicionar destinatarios)
	oProcess:cTo 	:= U_BFFATM15("inadimplencia@brlub.com.br","BIG008")
	//oProcess:cTo 	:= U_BFFATM15("ml-servicos@outlook.com","BIG008")
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
	
	MsgInfo("Processo Finalizado com Sucesso.","BIG008")
	
Return
