#Include "PROTHEUS.CH"

User Function Modelo2_1()

//Framework do mBrowser que � chamado diretamente do menu

Local aLegenda	:= {}
Private aRotina 	:= {}
Private cCadastro	:= "Solicita��o de Software"

AAdd(aRotina, {"Pesquisar" , "AxPesqui"   , 0, 1})
AAdd(aRotina, {"Visualizar", "u_Mod2Manut", 0, 2})
AAdd(aRotina, {"Incluir"   , "u_Mod2Manut", 0, 3})
AAdd(aRotina, {"Alterar"   , "u_Mod2Manut", 0, 4})
AAdd(aRotina, {"Excluir"   , "u_Mod2Manut", 0, 5})
AAdd(aRotina, {"Legenda"   , "u_LegSZ1"	, 0, 6})
AAdd(aRotina, {"Baixar"    , "u_BaixaSZ1"	, 0, 7})
AAdd(aRotina, {"ListBox"   , "u_ListBox"	, 0, 8})
AAdd(aRotina, {"ListBox do Flavio "   , "u_ListBox1"	, 0, 9})


AAdd(aLegenda, {"Z1_LEGENDA = 1", "BR_VERDE"})
AAdd(aLegenda, {"Z1_LEGENDA = 2", "BR_VERMELHO"})
                                               
dbSelectArea("SZ1")
dbSetOrder(1)
dbGoTop()

//mBrowse(,,,,"SZ1")

//mBrowse( <nLinha1>, <nColuna1>, <nLinha2>, <nColuna2>, <cAlias>, <aFixe>, <cCpo>, <nPar>, <cCorFun>, <nClickDef>, <aColors>, <cTopFun>, <cBotFun>, <nPar14>, <bInitBloc>, <lNoMnuFilter>, <lSeeAll>, <lChgAll>, <cExprFilTop>, <nInterval>, <uPar22>, <uPar23> )
//< aColors > Array contendo as cores que ser�o mostradas na primeira coluna do browse para indicar o status do registro.

mBrowse( , , , , "SZ1", , , , , 4, aLegenda)

Return Nil

// ----------------------------------------------------------------------

User Function LegSZ1()

	Local cQualquer := "Legenda"
	Local aCor := {}

	brwlegenda(cCadastro,cQualquer,aCor)
	
	AAdd(aLegenda, {"VERDE", "Em Aberto"})
	AAdd(aLegenda, {"VERMELHO", "Fianlizado"})
	
	
Return ( NIL)

// ----------------------------------------------------------------------

User Function BaixaSZ1(cAlias,nReg,nOpc)

Local cPedido	:= SZ1->Z1_COD

If MsgYesNo("Deseja dar baixa TODO o pedido? " + (cAlias)->Z1_COD )
	
	(cAlias)->(dbSetOrder(1))
	
	If MsSeek( xFilial(cAlias) + SZ1->Z1_COD )
		
		While ! SZ1->( EOF() ) .AND. SZ1->Z1_COD == cPedido
			RecLock(cAlias, .F.)
			(cAlias)->Z1_LEGENDA := 2
			//SZ1->Z1-LEGENDA := 2
			MSUnlock() 
			SZ1->(dbSkip())
		EndDo
	
	EndIf

Else
	
	RecLock(cAlias, .F.)
	(cAlias)->Z1_LEGENDA := 2
	//SZ1->Z1-LEGENDA := 2
	MSUnlock() 
	
EndIf

Return( NIL )
	