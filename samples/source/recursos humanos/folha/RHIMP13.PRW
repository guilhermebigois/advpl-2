#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

/*
�����������������������������������������������������������������������������������
�����������������������������������������������������������������������������������
�������������������������������������������������������������������������������ͻ��
���Funcao    �RHIMP13          �Autor  �Leandro Drumond     � Data � 02/11/2012 ���
�������������������������������������������������������������������������������͹��
���Desc.     �Responsavel em Processar a Importacao do historico de             ���
���          �transferencia dos funcionarios. Tabela SRE                        ���
�������������������������������������������������������������������������������͹��
���Uso       �Integracao do Modulo de RH dos Sistemas Logix X Protheus.         ���
�������������������������������������������������������������������������������͹��
���Parametros�fName  - Nome do Arquivo 						                   	���
�������������������������������������������������������������������������������͹��
���Retorno   �                                                                  ���
�������������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������������
�����������������������������������������������������������������������������������
*/
User Function RHIMP13(fName)
Local aFuncOri		:= {}
Local aFuncDest		:= {}
Local aDeptoImp		:= {}
Local aCCImp		:= {}
Local aItemImp		:= {}
Local cBuffer       := ""
Local cEmpAux   	:= ""
Local cFilAux    	:= ""
Local cDescErro		:= ""
Local cEmpSMO		:= ""
Local cFilSMO		:= ""
Local cMatOri		:= ""
Local cCCOri		:= ""
Local cCCDest		:= ""
Local cDeptoOri		:= ""
Local cDeptoDest	:= ""
Local cDataTrans	:= ""
Local cEmpOri    	:= "##"
Local cFilOri		:= "##"
Local lIncluiu 		:= .F.
Local lBuscaAux		:= .F.
Local lTransfEmp	:= .F.
Local nCount        := 0
Local nLidos        := 0
Local nX			:= 0
Local nTamMat		:= 0
Local nTamCC		:= 0
Local nTamDepto		:= 0
Local nPosAux		:= 0

PRIVATE aErro := {}
Private lItemClVl 	:= .F.

nCount := U_RIM01Line(fName)

//���������������������������������������������������������������������Ŀ
//� Numero de registros a importar                                      �
//�����������������������������������������������������������������������
ProcRegua(nCount)

FT_FUSE(fName)
FT_FGOTOP()

/*Ordem dos campos no array que sera montado com base na linha do TXT
01 - RE_DATA    - Data de Transferencia
02 - RE_EMPD 	- Empresa Origem
03 - RE_FILIALD	- Filial Origem
04 - RE_MATD	- Matr�cula Origem
05 - RE_CCD 	- Centro de Custos Origem
06 - RE_EMPP	- Empresa Destino
07 - RE_FILIALP	- Filial Destino
08 - RE_MATP 	- Matricula Destino
09 - RE_CCP 	- Centro de Custos Destino
10 - RE_DEPTOD 	- Departamento Origem
11 - RE_DEPTOP 	- Departamento Destino
12 - RE_ITEMD 	- Item Contabil Origem
13 - RE_ITEMP	- Item Contabil Destino
*/

While !FT_FEOF()
	cBuffer := FT_FREADLN()

	aLinha := {}
	aLinha := Separa(cBuffer,"|") //Distribui os itens no array

	cEmpAux   := aLinha[2]
	cFilAux   := aLinha[3]

	If cEmpAux <> cEmpOri .or. cFilAux <> cFilOri

		lExiste:= .F.
		dbSelectArea("SM0")
		dbGoTop()

		RpcClearEnv()
		OpenSm0Excl()

		While ! Eof()
			cEmpSMO := SM0->M0_CODIGO
			cFilSMO := SM0->M0_CODFIL

			If cEmpSMO == cEmpAux .AND. (Empty(cFilAux) .OR. cFilAux == cFilSMO)
				lExiste = .T.
				Exit
			EndIf
			SM0->(dbSkip())
		EndDo

		If lExiste == .T.
			RpcSetType(3)
			PREPARE ENVIRONMENT EMPRESA (cEmpSMO) FILIAL (cFilSMO) MODULO "GPE" USER "ADMIN" FUNNAME "GPEA250"
			CHKFILE("SRA")
			CHKFILE("SRE")
			CHKFILE("CTT")
			CHKFILE("SQB")
			nTamMat   := TAMSX3('RA_MAT')[1]
			nTamCC	  := TAMSX3('CTT_CUSTO')[1]
			nTamDepto := TAMSX3('QB_DEPTO')[1]
			lItemClVl := SuperGetMv( "MV_ITMCLVL", .F., "2" ) == "1"	// Verificar contabilizacao por item contabil e classe de valor
			fDelSRE()
		Else
			lIncluiu := .F.
		EndIf
	EndIf

	If lExiste == .T.
		lTransfEmp := !(aLinha[2] == aLinha[6])

		//���������������������������������������������������������������������Ŀ
		//� Incrementa a regua                                                  �
		//�����������������������������������������������������������������������
		nLidos += 1
		lIncluiu := .T.

		cMatOri	 	:= aLinha[4] + Space(nTamMat-Len(aLinha[4]))
		cDataTrans 	:= aLinha[1]

		If !(SRA->(DbSeek(xFilial("SRA")+cMatOri)))
			If !Empty(aFuncOri)
				If aScan(aFuncOri,  { |x|  X[1]+X[2]+X[3]+x[4] == cEmpAux + cFilAux + cMatOri + cDataTrans}) == 0
					aAdd(aFuncOri, {cEmpAux,cFilAux,cMatOri,cDataTrans})
				EndIf
			Else
				aAdd(aFuncOri,{cEmpAux,cFilAux,cMatOri,cDataTrans})
			EndIf
			lIncluiu := .F.
		Else
			If lItemClVl
				If Empty(aLinha[12])
					If !Empty(aItemImp)
						If aScan(aItemImp,  { |x|  X[1]+X[2]+X[3]+x[4] == cEmpAux + cFilAux + cMatOri + cDataTrans}) == 0
							aAdd(aItemImp, {cEmpAux,cFilAux,cMatOri,cDataTrans,"O"})
						EndIf
					Else
						aAdd(aItemImp,{cEmpAux,cFilAux,cMatOri,cDataTrans,"O"})
					EndIf
					lIncluiu := .F.
				ElseIf Empty(aLinha[13])
					If !Empty(aItemImp)
						If aScan(aItemImp,  { |x|  X[1]+X[2]+X[3]+x[4] == cEmpAux + cFilAux + cMatOri + cDataTrans}) == 0
							aAdd(aItemImp, {cEmpAux,cFilAux,cMatOri,cDataTrans,"D"})
						EndIf
					Else
						aAdd(aItemImp,{cEmpAux,cFilAux,cMatOri,cDataTrans,"D"})
					EndIf
					lIncluiu := .F.
				EndIf
			EndIf
		EndIf

		If lIncluiu
			If lTransfEmp
				lBuscaAux := .T.
				If !Empty(aFuncDest)
					If ( nPosAux := aScan(aFuncDest,  { |x|  X[1]+X[2]+X[3] == aLinha[6] + aLinha[7] + aLinha[8] }) ) > 0
						If !aFuncDest[nPosAux,5]
							lIncluiu  := .F.
						EndIf
						lBuscaAux := .F.
					EndIf
				EndIf

				If lBuscaAux
					If fChkCpo('SRA',aLinha[6],aLinha[7],'RA_MAT',aLinha[8])//Tabela,Empresa,Filial,Campo,Chave
						aAdd(aFuncDest, {aLinha[6],aLinha[7],aLinha[8],aLinha[1],.T.})
					Else
						aAdd(aFuncDest, {aLinha[6],aLinha[7],aLinha[8],aLinha[1],.F.})
						lIncluiu := .F.
					EndIf
				EndIf
			Else
				cMatOri	 := aLinha[8] + Space(nTamMat-Len(aLinha[8]))

				If !(SRA->(DbSeek(aLinha[7]+cMatOri)))
					If !Empty(aFuncDest)
						If aScan(aFuncDest,  { |x|  X[1]+X[2]+X[3] == cEmpAux + aLinha[7] + aLinha[8] }) == 0
							aAdd(aFuncDest, {cEmpAux,aLinha[7],aLinha[8],aLinha[1],.F.})
						EndIf
					Else
						aAdd(aFuncDest,{cEmpAux,aLinha[7],aLinha[8],aLinha[1],.F.})
					EndIf
					lIncluiu := .F.
				EndIf
			EndIf
		EndIf

		cCCOri := aLinha[5] + Space(nTamCC-Len(aLinha[5]))
		cCCDest:= aLinha[9] + Space(nTamCC-Len(aLinha[9]))

		If !CTT->(DbSeek(xFilial("CTT")+cCCOri))
			If !Empty(aCCImp)
				If aScan(aCCImp,  { |x|  X[1]+X[2]+X[3]+x[4] == cEmpAux + cFilAux + cCCOri + cDataTrans}) == 0
					aAdd(aCCImp, {cEmpAux,cFilAux,cCCOri,cDataTrans,"O",.F.})
				EndIf
			Else
				aAdd(aCCImp,{cEmpAux,cFilAux,cCCOri,cDataTrans,"O",.F.})
			EndIf
			lIncluiu := .F.
		EndIf

		cDeptoOri := aLinha[10] + Space(nTamDepto-Len(aLinha[10]))
		cDeptoDest:= aLinha[11] + Space(nTamDepto-Len(aLinha[11]))

		If !Empty(cDeptoOri)
			If !SQB->(DbSeek(xFilial("SQB")+cDeptoOri))
				If !Empty(aDeptoImp)
					If aScan(aDeptoImp,  { |x|  X[1]+X[2]+X[3]+X[4] == cEmpAux + cFilAux + cDeptoOri + cDataTrans }) == 0
						aAdd(aDeptoImp, {cEmpAux,cFilAux,cDeptoOri,cDataTrans,"O",.F.})
					EndIf
				Else
					aAdd(aDeptoImp,{cEmpAux,cFilAux,cDeptoOri,cDataTrans,"O",.F.})
				EndIf
				lIncluiu := .F.
			EndIf
		EndIf

		If lIncluiu
			If lTransfEmp
				lBuscaAux := .T.
				If !Empty(aDeptoImp)
					If ( nPosAux := aScan(aDeptoImp,  { |x|  X[1]+X[2]+X[3] == aLinha[6] + aLinha[7] + cDeptoDest }) ) > 0
						If !aDeptoImp[nPosAux,6]
							lIncluiu  := .F.
						EndIf
						lBuscaAux := .F.
					EndIf
				EndIf

				If lBuscaAux
					If fChkCpo('SQB',aLinha[6],aLinha[7],'QB_DEPTO',cDeptoDest)//Tabela,Empresa,Filial,Campo,Chave
						aAdd(aDeptoImp, {aLinha[6],aLinha[7],cDeptoDest,aLinha[1],"D",.T.})
					Else
						aAdd(aDeptoImp, {aLinha[6],aLinha[7],cDeptoDest,aLinha[1],"D",.F.})
						lIncluiu := .F.
					EndIf
				EndIf

				lBuscaAux := .T.
				If !Empty(aCCImp)
					If ( nPosAux := aScan(aCCImp,  { |x|  X[1]+X[2]+X[3] == aLinha[6] + aLinha[7] + cCCDest }) ) > 0
						If !aCCImp[nPosAux,6]
							lIncluiu  := .F.
						EndIf
						lBuscaAux := .F.
					EndIf
				EndIf

				If lBuscaAux
					If fChkCpo('CTT',aLinha[6],aLinha[7],'CTT_CUSTO',cCCDest)//Tabela,Empresa,Filial,Campo,Chave
						aAdd(aCCImp, {aLinha[6],aLinha[7],cCCDest,aLinha[1],"D",.T.})
					Else
						aAdd(aCCImp, {aLinha[6],aLinha[7],cCCDest,aLinha[1],"D",.F.})
						lIncluiu := .F.
					EndIf
				EndIf
			Else
				If !Empty(cDeptoDest)
					If !SQB->(DbSeek(xFilial("SQB")+cDeptoDest))
						If !Empty(aDeptoImp)
							If aScan(aDeptoImp,  { |x|  X[1]+X[2]+X[3]+X[4] == aLinha[6] + aLinha[7] + cDeptoDest + cDataTrans }) == 0
								aAdd(aDeptoImp, {aLinha[6],aLinha[7],cDeptoDest,cDataTrans,"D",.F.})
							EndIf
						Else
							aAdd(aDeptoImp,{aLinha[6],aLinha[7],cDeptoDest,cDataTrans,"D",.F.})
						EndIf
						lIncluiu := .F.
					EndIf
				EndIf

				If !CTT->(DbSeek(xFilial("CTT")+cCCDest))
					If !Empty(aCCImp)
						If aScan(aCCImp,  { |x|  X[1]+X[2]+X[3]+x[4] == aLinha[6] + aLinha[7] + cCCDest + cDataTrans}) == 0
							aAdd(aCCImp, {aLinha[6],aLinha[7],cCCDest,cDataTrans,"D",.F.})
						EndIf
					Else
						aAdd(aCCImp,{aLinha[6],aLinha[7],cCCDest,cDataTrans,"D",.F.})
					EndIf
					lIncluiu := .F.
				EndIf
			EndIf
		EndIf

		If lIncluiu

			aCpoSRE  := {}

			aAdd(aCpoSRE,{'RE_FILIAL',xFilial('SRE')})
			aAdd(aCpoSRE,{'RE_DATA',CtoD(aLinha[1])})
			aAdd(aCpoSRE,{'RE_EMPD',aLinha[2]})
			aAdd(aCpoSRE,{'RE_FILIALD',aLinha[3]})
			aAdd(aCpoSRE,{'RE_MATD',aLinha[4]})
			aAdd(aCpoSRE,{'RE_CCD',aLinha[5]})
			aAdd(aCpoSRE,{'RE_EMPP',aLinha[6]})
			aAdd(aCpoSRE,{'RE_FILIALP',aLinha[7]})
			aAdd(aCpoSRE,{'RE_MATP',aLinha[8]})
			aAdd(aCpoSRE,{'RE_CCP',aLinha[9]})
			aAdd(aCpoSRE,{'RE_DEPTOD',aLinha[10]})
			aAdd(aCpoSRE,{'RE_DEPTOP',aLinha[11]})
			aAdd(aCpoSRE,{'RE_ITEMD',aLinha[12]})
			aAdd(aCpoSRE,{'RE_ITEMP',aLinha[13]})

			fGrvSRE(aCpoSRE)
		EndIf

	EndIf

	MSUnLock()
	IncProc()

	FT_FSKIP()

	cEmpOri  := cEmpAux
	cFilOri  := cFilAux

EndDo

If !Empty(aFuncOri)
	aSort( aFuncOri ,,, { |x,y| x[1]+x[2]+X[3]+X[4] < y[1]+Y[2]+Y[3]+Y[4] } )
	For nCount := 1 to Len(aFuncOri)
		cDescErro := "Transfer�ncia: " + AllTrim(aFuncOri[nCount,1]) + '/' + AllTrim(aFuncOri[nCount,2]) + '/' + AllTrim(aFuncOri[nCount,3]) + '/' + AllTrim(STRTRAN(aFuncOri[nCount,4],"/","-")) + " - Matr�cula de Origem n�o encontrada. Registros de Transfer�ncias nao foram importados."
		//U_RIM01ERR(cDescErro)
		aAdd(aErro,cDescErro)
	Next nCount
EndIf

If !Empty(aFuncDest)
	aSort( aFuncDest ,,, { |x,y| x[1]+x[2]+X[3]+X[4] < y[1]+Y[2]+Y[3]+Y[4] } )
	For nCount := 1 to Len(aFuncDest)
		If !aFuncDest[nCount,5]
			cDescErro := "Transfer�ncia: " + AllTrim(aFuncDest[nCount,1]) + '/' + AllTrim(aFuncDest[nCount,2]) + '/' + AllTrim(aFuncDest[nCount,3]) + '/' + AllTrim(STRTRAN(aFuncDest[nCount,4],"/","-")) + " - Matr�cula de Destino n�o encontrada. Registros de Transfer�ncias nao foram importados."
			//U_RIM01ERR(cDescErro)
			aAdd(aErro,cDescErro)
		EndIf
	Next nCount
EndIf

If !Empty(aCCImp)
	aSort( aCCImp ,,, { |x,y| x[1]+x[2]+X[3]+X[4] < y[1]+Y[2]+Y[3]+Y[4] } )
	For nCount := 1 to Len(aCCImp)
		If !aCCImp[nCount,6]
			If aCCImp[nCount,5] == "O"
				cDescErro := "Transfer�ncia: " + AllTrim(aCCImp[nCount,1]) + '/' + AllTrim(aCCImp[nCount,2]) + '/' + AllTrim(aCCImp[nCount,3]) + '/' + AllTrim(STRTRAN(aCCImp[nCount,4],"/","-")) + " - Centro de Custos de Origem n�o encontrado. Registros de Transfer�ncias nao foram importados."
			Else
				cDescErro := "Transfer�ncia: " + AllTrim(aCCImp[nCount,1]) + '/' + AllTrim(aCCImp[nCount,2]) + '/' + AllTrim(aCCImp[nCount,3]) + '/' + AllTrim(STRTRAN(aCCImp[nCount,4],"/","-")) + " - Centro de Custos de Destino n�o encontrado. Registros de Transfer�ncias nao foram importados."
			EndIf
			//U_RIM01ERR(cDescErro)
			aAdd(aErro,cDescErro)
		EndIf
	Next nCount
EndIf

If !Empty(aDEPTOImp)
	aSort( aDeptoImp ,,, { |x,y| x[1]+x[2]+X[3]+X[4] < y[1]+Y[2]+Y[3]+Y[4] } )
	For nCount := 1 to Len(aDeptoImp)
		If !aDeptoImp[nCount,6]
			If aDeptoImp[nCount,5] == "O"
				cDescErro := "Transfer�ncia: " + AllTrim(aDeptoImp[nCount,1]) + '/' + AllTrim(aDeptoImp[nCount,2]) + '/' + AllTrim(aDeptoImp[nCount,3]) + '/' + AllTrim(STRTRAN(aDeptoImp[nCount,4],"/","-")) + " - Departamento de Origem n�o encontrado. Registros de Transfer�ncias nao foram importados."
			Else
				cDescErro := "Transfer�ncia: " + AllTrim(aDeptoImp[nCount,1]) + '/' + AllTrim(aDeptoImp[nCount,2]) + '/' + AllTrim(aDeptoImp[nCount,3]) + '/' + AllTrim(STRTRAN(aDeptoImp[nCount,4],"/","-")) + " - Departamento de Destino n�o encontrado. Registros de Transfer�ncias nao foram importados."
			EndIf
			//U_RIM01ERR(cDescErro)
			aAdd(aErro,cDescErro)
		EndIf
	Next nCount
EndIf

If !Empty(aItemImp)
	aSort( aItemImp ,,, { |x,y| x[1]+x[2]+X[3]+X[4] < y[1]+Y[2]+Y[3]+Y[4] } )
	For nCount := 1 to Len(aItemImp)
		If aItemImp[nCount,5] == "O"
			cDescErro := "Transfer�ncia: " + AllTrim(aItemImp[nCount,1]) + '/' + AllTrim(aItemImp[nCount,2]) + '/' + AllTrim(aItemImp[nCount,3]) + '/' + AllTrim(STRTRAN(aItemImp[nCount,4],"/","-")) + " - N�o foi importado o registro. Atributo Item cont�bil de Origem n�o existe no arquivo e o sistema est� habilitado para utiliza��o com esta informa��o."
		Else
			cDescErro := "Transfer�ncia: " + AllTrim(aItemImp[nCount,1]) + '/' + AllTrim(aItemImp[nCount,2]) + '/' + AllTrim(aItemImp[nCount,3]) + '/' + AllTrim(STRTRAN(aItemImp[nCount,4],"/","-")) + " - N�o foi importado o registro. Atributo Item cont�bil de Destino n�o existe no arquivo e o sistema est� habilitado para utiliza��o com esta informa��o."
		EndIf
		//U_RIM01ERR(cDescErro)
		aAdd(aErro,cDescErro)
	Next nCount
ENDIF
U_RIM01ERA(aErro)

//���������������������������������������������������������������������Ŀ
//� Libera o arquivo                                                    �
//�����������������������������������������������������������������������
FT_FUSE()

Return Nil

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Funcao    �fGrvSRE   �Autor  �Leandro Drumond     � Data �  02/11/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Grava os dados na tabela SRE.                               ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP5                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function fGrvSRE(aCpoSRE)
Local nX := 0

Begin Transaction

	DbSelectArea("SRE")

	RecLock('SRE',.T.)

	For nX := 1 to Len(aCpoSRE)
		&(aCpoSRE[nX,1]) := aCpoSRE[nX,2]
	Next nX

	MsUnLock()

End Transaction

Return Nil

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Funcao    �fChkCpo   �Autor  �Leandro Drumond     � Data �  03/11/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Procura dados em outra empresa.                             ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP5                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function fChkCpo(cAlias,cEmpAux,cFilAux,cCampo,cChave)//Tabela,Empresa,Filial,Campo,Chave
Local cAliasAux := "QTABAUX"
Local cTabAux   := "%" + cAlias + cEmpAux + "0" + "%"
Local lRet	    := .F.

cCampo 	:= "%" + cCampo + "%"

//cQuery := "SELECT COUNT(*) FROM " + cAlias + cEmpAux + "0" + " WHERE " + cCampo + " = " + cChave

BeginSql alias cAliasAux
	SELECT COUNT(*) TOTALREG
	FROM %exp:cTabAux%
 	    WHERE  %exp:cCampo% = %exp:cChave%
EndSql

If (cAliasAux)->TOTALREG > 0
	lRet := .T.
EndIf

(cAliasAux)->(DbCloseArea())

Return lRet

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Funcao    �fDelSRE   �Autor  �Leandro Drumond     � Data �  03/11/12   ���
�������������������������������������������������������������������������͹��
���Desc.     �Exclui dados da SRE.			                              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP5                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function fDelSRE()

Local cQuery := ''
Local cAlias := 'SRE'

cQuery := " DELETE FROM " + InitSqlName(cAlias) + " "

TcSqlExec( cQuery )

TcRefresh( InitSqlName(cAlias) )

Return Nil