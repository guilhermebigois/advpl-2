#include "rwmake.ch"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � MkBrwSA2 �Autor  � Arnaldo R. Junior  � Data �  18/11/06  ���
�������������������������������������������������������������������������͹��
���Desc.     � MarkBrowse Gen�rica                                        ���
�������������������������������������������������������������������������͹��
���Uso       � Curso de ADVPL Intermedi�rio                               ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/

USER FUNCTION MkBrwSA2()

Local aCpos		    := {}
Local aCampos		:= {}
Local nI			:= 0 
Local cAlias		:= "SA2"

Private aRotina     := {}
Private cCadastro   := "Cadastro de Fornecedores"
Private aRecDel 	:= {}	

AADD(aRotina,{"Pesquisar"	,"AxPesqui"	 ,0,1})
AADD(aRotina,{"Visualizar"	,"AxVisual"	 ,0,2})
AADD(aRotina,{"Incluir"		,"AxInclui"  ,0,3})
AADD(aRotina,{"Alterar"		,"AxAltera"	 ,0,4})
AADD(aRotina,{"Excluir"		,"AxDeleta"	 ,0,5})
AADD(aRotina,{"Excluir Lote","U_DelLote" ,0,6})

AADD(aCpos,"A2_OK"		)
AADD(aCpos,"A2_FILIAL"	)
AADD(aCpos,"A2_COD"		)
AADD(aCpos,"A2_LOJA"	)
AADD(aCpos,"A2_NOME"	)
AADD(aCpos,"A2_TIPO"	)

dbSelectArea("SX3")
dbSetOrder(2)
For nI := 1 To Len(aCpos)
  	 IF dbSeek(aCpos[nI])
  	 	aAdd(aCampos,{X3_CAMPO,"",Iif(nI==1,"",Trim(X3_TITULO)),;
   			 Trim(X3_PICTURE)})
	ENDIF
Next

DbSelectArea(cAlias)
DbSetOrder(1)
//MarkBrow(cAlias,<campo_marca>,<quem n�o pode>,<array_camposbrw>,<condi��o_inicial>,<marca_atual>,,,,,<fun��o_na_marca>)
MarkBrow(cAlias,aCpos[1],"A2_TIPO == ' '",aCampos,.F.,;
		 GetMark(,"SA2","A2_OK"))

LimpaMarca()

Return

USER FUNCTION DelLote()

Local cMarca  := ThisMark()
Local nX	  := 0
Local lInvert := ThisInv()

DbSelectArea("SA2")
DbGoTop()
While SA2->(!EOF())

	// IsMark("A2_OK", cMarca, lInverte)
	IF SA2->A2_OK == cMarca .AND. !lInvert 
		AADD(aRecDel,SA2->(Recno()))
	ELSEIF SA2->A2_OK != cMarca .AND. lInvert 
		AADD(aRecDel,SA2->(Recno()))
	ENDIF

	SA2->(dbSkip())
End

IF Len(aRecDel) > 0 .AND. MsgYesNo( "Deseja excluir os :"+;
								    cValToChar(Len(aRecDel))+;
									" fornecedores selecionados?")

	For nX := 1 to Len(aRecDel)
		SA2->(DbGoto(aRecDel[nX]))
		RecLock("SA2",.F.)
			dbDelete()
		MsUnLock()	
	Next nX

ENDIF


RETURN