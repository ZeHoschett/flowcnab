      ******************************************************************
      * PROGRAMA: PROCRET
      * Processa o arquivo de RETORNO CNAB 240 (gerado pelo banco real
      * ou, neste projeto, pelo SIMBANCO): localiza cada titulo pelo
      * NOSSO NUMERO, atualiza o status (PAGO / PAGO COM ATRASO /
      * REJEITADO com motivo) e emite o relatorio de conciliacao.
      *
      * Entradas: saida/RETORNO.TXT        (CNAB 240 - segmentos T/U)
      *           dados/titulos_status.txt (TITULO-STATUS, PENDENTE)
      * Saidas  : dados/titulos_status_novo.txt (TITULO-STATUS novo)
      *           saida/CONCILIACAO.TXT         (relatorio texto)
      *
      * DATAS: o segmento U traz a data de ocorrencia em DDMMAAAA
      * (layout CNAB); TS-VENCIMENTO esta em AAAAMMDD (contrato do
      * copybook). Comparar DDMMAAAA numericamente da resultado errado
      * (01/10 vira 01102026, menor que 20092026), entao a data de
      * ocorrencia e convertida para AAAAMMDD em
      * 560-CONVERTER-DATA-OCORRENCIA antes de qualquer comparacao.
      *
      * RETURN-CODE: 0 = ok / 4 = conciliacao com divergencia /
      *              8 = erro fatal.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROCRET.
       AUTHOR. FLOWCNAB.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-RETORNO ASSIGN TO WS-PATH-RETORNO
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-RETORNO.

           SELECT F-STATUS-IN ASSIGN TO WS-PATH-STATUS-IN
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-STATUS-IN.

           SELECT F-STATUS-OUT ASSIGN TO WS-PATH-STATUS-OUT
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-STATUS-OUT.

           SELECT F-RELATORIO ASSIGN TO WS-PATH-RELATORIO
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-RELATORIO.

       DATA DIVISION.
       FILE SECTION.
       FD  F-RETORNO.
       01  FD-RETORNO-REC                PIC X(240).

       FD  F-STATUS-IN.
       01  FD-STATUS-IN-REC              PIC X(130).

       FD  F-STATUS-OUT.
       01  FD-STATUS-OUT-REC             PIC X(130).

       FD  F-RELATORIO.
       01  FD-RELATORIO-REC              PIC X(100).

       WORKING-STORAGE SECTION.

           COPY "FLOWCNAB-CONST.cpy".
           COPY "CNAB240-DET-T.cpy".
           COPY "CNAB240-DET-U.cpy".
           COPY "TITULO-STATUS.cpy".

       01  WS-PATH-RETORNO               PIC X(80)
               VALUE "saida/RETORNO.TXT".
       01  WS-PATH-STATUS-IN             PIC X(80)
               VALUE "dados/titulos_status.txt".
       01  WS-PATH-STATUS-OUT            PIC X(80)
               VALUE "dados/titulos_status_novo.txt".
       01  WS-PATH-RELATORIO             PIC X(80)
               VALUE "saida/CONCILIACAO.TXT".

       01  WS-FS-RETORNO                 PIC X(02).
       01  WS-FS-STATUS-IN               PIC X(02).
       01  WS-FS-STATUS-OUT              PIC X(02).
       01  WS-FS-RELATORIO               PIC X(02).

       01  WS-EOF-RETORNO                PIC X(01) VALUE "N".
           88 FIM-RETORNO                          VALUE "S".

      * ---- tabela em memoria com todos os titulos (carregada do
      *      arquivo de status gerado pelo GERAREM). A capacidade vem
      *      de CT-MAX-TITULOS, o mesmo limite que o GERAREM impoe na
      *      geracao - por isso os dois copiam FLOWCNAB-CONST. ----
       01  WS-TAB-TITULOS.
           05 WS-TITULO OCCURS CT-MAX-TITULOS TIMES
                        INDEXED BY IDX-T.
              10 WT-NOSSO-NUMERO         PIC 9(08).
              10 WT-NOME-PAGADOR         PIC X(30).
              10 WT-VENCIMENTO           PIC 9(08).
              10 WT-VALOR-TITULO         PIC 9(13)V9(02).
              10 WT-STATUS               PIC X(16).
              10 WT-DATA-OCORRENCIA      PIC 9(08).
              10 WT-VALOR-PAGO           PIC 9(13)V9(02).
              10 WT-MOTIVO-REJEICAO      PIC X(30).
       01  WS-QTDE-TITULOS-TAB           PIC 9(04) VALUE 0.
       01  WS-ACHOU-TITULO               PIC X(01).

      * ---- dados extraidos dos segmentos T/U do retorno ----
       01  WS-T-NOSSO-NUMERO             PIC 9(08).
       01  WS-T-COD-OCORRENCIA           PIC 9(02).
       01  WS-T-ERROS                    PIC 9(08).
       01  WS-U-DATA-OCORRENCIA          PIC 9(08).
       01  WS-U-VALOR-PAGO               PIC 9(13)V9(02).
       01  WS-TEM-PENDENTE-T             PIC X(01) VALUE "N".

      * ---- conversao da data de ocorrencia DDMMAAAA -> AAAAMMDD ----
       01  WS-OCOR-DDMMAAAA              PIC 9(08).
       01  WS-OCOR-DDMMAAAA-R REDEFINES WS-OCOR-DDMMAAAA.
           05 WS-OCOR-D-DD               PIC 9(02).
           05 WS-OCOR-D-MM               PIC 9(02).
           05 WS-OCOR-D-AAAA             PIC 9(04).
       01  WS-OCOR-AAAAMMDD              PIC 9(08).
       01  WS-OCOR-AAAAMMDD-R REDEFINES WS-OCOR-AAAAMMDD.
           05 WS-OCOR-AAAA               PIC 9(04).
           05 WS-OCOR-MM                 PIC 9(02).
           05 WS-OCOR-DD                 PIC 9(02).

      * ---- descricoes dos motivos de rejeicao (mesma codificacao
      *      emitida pelo SIMBANCO em DT-ERROS) ----
       01  WS-DESCR-MOTIVOS-TAB.
           05 FILLER PIC X(30) VALUE "SALDO INSUFICIENTE".
           05 FILLER PIC X(30) VALUE "DADOS CADASTRAIS INCONSIST.".
           05 FILLER PIC X(30) VALUE "TITULO JA BAIXADO/CANCELADO".
       01  WS-DESCR-MOTIVOS-RED REDEFINES WS-DESCR-MOTIVOS-TAB.
           05 WS-DESCR-MOTIVO OCCURS 3 TIMES PIC X(30).
       78  CT-QTDE-MOTIVOS               VALUE 3.
       01  WS-DESCR-MOTIVO-DEFAULT PIC X(30)
           VALUE "MOTIVO NAO IDENTIFICADO".

      * ---- contadores do relatorio de conciliacao ----
       01  WS-QTDE-ENVIADOS              PIC 9(06) VALUE 0.
       01  WS-QTDE-PAGOS                 PIC 9(06) VALUE 0.
       01  WS-QTDE-PAGOS-ATRASO          PIC 9(06) VALUE 0.
       01  WS-QTDE-REJEITADOS            PIC 9(06) VALUE 0.
       01  WS-QTDE-PENDENTES             PIC 9(06) VALUE 0.
       01  WS-QTDE-SOMA-STATUS           PIC 9(06) VALUE 0.
       01  WS-QTDE-NAO-LOCALIZADOS       PIC 9(06) VALUE 0.
       01  WS-QTDE-DIVERGENTES           PIC 9(06) VALUE 0.
       01  WS-QTDE-OCOR-REPETIDAS        PIC 9(06) VALUE 0.
       01  WS-QTDE-PARES-QUEBRADOS       PIC 9(06) VALUE 0.
       01  WS-VALOR-ENVIADO              PIC 9(13)V9(02) VALUE 0.
       01  WS-VALOR-CONCILIADO           PIC 9(13)V9(02) VALUE 0.
       01  WS-CONCILIACAO-OK             PIC X(01) VALUE "S".

       01  WS-LINHA-REL                  PIC X(100).
       01  WS-VALOR-EDIT                 PIC Z,ZZZ,ZZZ,ZZ9.99.
       01  WS-QTDE-EDIT                  PIC ZZZ,ZZ9.

       PROCEDURE DIVISION.

       000-PRINCIPAL.
           PERFORM 100-ABRIR-ARQUIVOS
           PERFORM 150-CARREGAR-STATUS
           PERFORM 200-LER-RETORNO
           PERFORM UNTIL FIM-RETORNO
               EVALUATE TRUE
                   WHEN DT-SEGMENTO OF WS-DET-T = "T"
                       PERFORM 300-TRATAR-SEGMENTO-T
                   WHEN DU-SEGMENTO OF WS-DET-U = "U"
                       AND WS-TEM-PENDENTE-T = "S"
                       PERFORM 400-TRATAR-SEGMENTO-U
                       PERFORM 500-ATUALIZAR-TITULO
                       MOVE "N" TO WS-TEM-PENDENTE-T
               END-EVALUATE
               PERFORM 200-LER-RETORNO
           END-PERFORM

      * Um T que sobrou sem o U dele no fim do arquivo e um retorno
      * truncado: o titulo nao foi atualizado e precisa ser acusado.
           IF WS-TEM-PENDENTE-T = "S"
               PERFORM 310-ACUSAR-PAR-QUEBRADO
           END-IF

           PERFORM 600-REGRAVAR-STATUS
           PERFORM 650-VALIDAR-CONCILIACAO
           PERFORM 700-EMITIR-CONCILIACAO
           PERFORM 900-FECHAR-ARQUIVOS
           PERFORM 950-ENCERRAR
           STOP RUN.

       100-ABRIR-ARQUIVOS.
           OPEN INPUT F-RETORNO
           IF WS-FS-RETORNO NOT = "00"
              DISPLAY "PROCRET: ERRO ao abrir "
                  FUNCTION TRIM(WS-PATH-RETORNO)
                  " - FILE STATUS " WS-FS-RETORNO
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN INPUT F-STATUS-IN
           IF WS-FS-STATUS-IN NOT = "00"
              DISPLAY "PROCRET: ERRO ao abrir "
                  FUNCTION TRIM(WS-PATH-STATUS-IN)
                  " - FILE STATUS " WS-FS-STATUS-IN
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN OUTPUT F-STATUS-OUT
           IF WS-FS-STATUS-OUT NOT = "00"
              DISPLAY "PROCRET: ERRO ao criar "
                  FUNCTION TRIM(WS-PATH-STATUS-OUT)
                  " - FILE STATUS " WS-FS-STATUS-OUT
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN OUTPUT F-RELATORIO
           IF WS-FS-RELATORIO NOT = "00"
              DISPLAY "PROCRET: ERRO ao criar "
                  FUNCTION TRIM(WS-PATH-RELATORIO)
                  " - FILE STATUS " WS-FS-RELATORIO
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF.

       150-CARREGAR-STATUS.
           PERFORM WITH TEST AFTER
               UNTIL WS-FS-STATUS-IN = "10"
               READ F-STATUS-IN INTO WS-TITULO-STATUS
                   AT END
                       MOVE "10" TO WS-FS-STATUS-IN
                   NOT AT END
                       PERFORM 160-INCLUIR-TITULO-NA-TABELA
               END-READ
           END-PERFORM

           IF WS-QTDE-TITULOS-TAB = 0
               DISPLAY "PROCRET: ERRO - arquivo de status esta "
                   "vazio. Rode o GERAREM antes."
               MOVE 8 TO RETURN-CODE
               STOP RUN
           END-IF.

      * Guarda de capacidade: sem isso o MOVE para WT-*(IDX-T) grava
      * fora da tabela e o programa morre com violacao de memoria,
      * sem mensagem util.
       160-INCLUIR-TITULO-NA-TABELA.
           IF WS-QTDE-TITULOS-TAB >= CT-MAX-TITULOS
               DISPLAY "PROCRET: ERRO FATAL - o arquivo de status tem "
                   "mais de " CT-MAX-TITULOS " titulos, a capacidade "
                   "da tabela em memoria. Aumente CT-MAX-TITULOS em "
                   "copybooks/FLOWCNAB-CONST.cpy e recompile os tres "
                   "programas."
               MOVE 8 TO RETURN-CODE
               STOP RUN
           END-IF

           ADD 1 TO WS-QTDE-TITULOS-TAB
           SET IDX-T TO WS-QTDE-TITULOS-TAB
           MOVE TS-NOSSO-NUMERO    TO WT-NOSSO-NUMERO(IDX-T)
           MOVE TS-NOME-PAGADOR    TO WT-NOME-PAGADOR(IDX-T)
           MOVE TS-VENCIMENTO      TO WT-VENCIMENTO(IDX-T)
           MOVE TS-VALOR-TITULO    TO WT-VALOR-TITULO(IDX-T)
           MOVE TS-STATUS          TO WT-STATUS(IDX-T)
           MOVE TS-DATA-OCORRENCIA TO WT-DATA-OCORRENCIA(IDX-T)
           MOVE TS-VALOR-PAGO      TO WT-VALOR-PAGO(IDX-T)
           MOVE TS-MOTIVO-REJEICAO TO WT-MOTIVO-REJEICAO(IDX-T)
           ADD 1 TO WS-QTDE-ENVIADOS
           ADD TS-VALOR-TITULO TO WS-VALOR-ENVIADO.

       200-LER-RETORNO.
           READ F-RETORNO INTO WS-DET-T
               AT END
                   MOVE "S" TO WS-EOF-RETORNO
           END-READ
           IF NOT FIM-RETORNO
              MOVE FD-RETORNO-REC TO WS-DET-U
           END-IF.

       300-TRATAR-SEGMENTO-T.
      * Os segmentos T e U vem sempre em par. Se um T chega com outro
      * T ainda pendente, o U do anterior nao veio: sem esta guarda o
      * titulo anterior era sobrescrito em silencio e ficava PENDENTE
      * para sempre - e a identidade da conciliacao continuava
      * fechando, porque ele era contado como pendente.
           IF WS-TEM-PENDENTE-T = "S"
               PERFORM 310-ACUSAR-PAR-QUEBRADO
           END-IF

           MOVE DT-NOSSO-NUMERO     TO WS-T-NOSSO-NUMERO
           MOVE DT-COD-OCORRENCIA   TO WS-T-COD-OCORRENCIA
           MOVE DT-ERROS            TO WS-T-ERROS
           MOVE "S"                 TO WS-TEM-PENDENTE-T.

       310-ACUSAR-PAR-QUEBRADO.
           DISPLAY "PROCRET: AVISO - segmento T do nosso numero "
               WS-T-NOSSO-NUMERO " chegou sem o segmento U "
               "correspondente. O titulo permanece PENDENTE."
           ADD 1 TO WS-QTDE-PARES-QUEBRADOS
           MOVE "N" TO WS-TEM-PENDENTE-T
           MOVE "N" TO WS-CONCILIACAO-OK.

       400-TRATAR-SEGMENTO-U.
           MOVE DU-DATA-OCORRENCIA  TO WS-U-DATA-OCORRENCIA
           MOVE DU-VALOR-PAGO       TO WS-U-VALOR-PAGO.

      * Busca sequencial limitada a quantidade realmente carregada -
      * varrer as CT-MAX-TITULOS posicoes compararia lixo nao
      * inicializado.
       500-ATUALIZAR-TITULO.
           MOVE "N" TO WS-ACHOU-TITULO
           PERFORM VARYING IDX-T FROM 1 BY 1
               UNTIL IDX-T > WS-QTDE-TITULOS-TAB
                  OR WS-ACHOU-TITULO = "S"
               IF WT-NOSSO-NUMERO(IDX-T) = WS-T-NOSSO-NUMERO
                   MOVE "S" TO WS-ACHOU-TITULO
                   PERFORM 550-APLICAR-OCORRENCIA
               END-IF
           END-PERFORM

           IF WS-ACHOU-TITULO = "N"
               DISPLAY "PROCRET: AVISO - retorno para nosso numero "
                   "inexistente na remessa: " WS-T-NOSSO-NUMERO
               ADD 1 TO WS-QTDE-NAO-LOCALIZADOS
               MOVE "N" TO WS-CONCILIACAO-OK
           END-IF.

       550-APLICAR-OCORRENCIA.
      * Um titulo que ja saiu de PENDENTE recebendo outra ocorrencia
      * significa nosso numero repetido no retorno - a contagem por
      * status deixaria de fechar com a quantidade de enviados.
           IF WT-STATUS(IDX-T) NOT = "PENDENTE"
               DISPLAY "PROCRET: AVISO - nosso numero "
                   WS-T-NOSSO-NUMERO " recebeu mais de uma ocorrencia "
                   "no retorno. Ocorrencia ignorada."
               ADD 1 TO WS-QTDE-OCOR-REPETIDAS
               MOVE "N" TO WS-CONCILIACAO-OK
               EXIT PARAGRAPH
           END-IF

           EVALUATE WS-T-COD-OCORRENCIA
               WHEN CT-OCOR-LIQUIDACAO
                   PERFORM 560-CONVERTER-DATA-OCORRENCIA
                   MOVE WS-U-VALOR-PAGO  TO WT-VALOR-PAGO(IDX-T)
                   MOVE WS-OCOR-AAAAMMDD TO WT-DATA-OCORRENCIA(IDX-T)
                   IF WS-OCOR-AAAAMMDD > WT-VENCIMENTO(IDX-T)
                       MOVE "PAGO COM ATRASO" TO WT-STATUS(IDX-T)
                       ADD 1 TO WS-QTDE-PAGOS-ATRASO
                   ELSE
                       MOVE "PAGO"            TO WT-STATUS(IDX-T)
                       ADD 1 TO WS-QTDE-PAGOS
                   END-IF
                   ADD WS-U-VALOR-PAGO TO WS-VALOR-CONCILIADO
                   IF WS-U-VALOR-PAGO NOT = WT-VALOR-TITULO(IDX-T)
                       DISPLAY "PROCRET: AVISO - valor pago diverge "
                           "do valor do titulo. Nosso numero: "
                           WT-NOSSO-NUMERO(IDX-T)
                       ADD 1 TO WS-QTDE-DIVERGENTES
                       MOVE "N" TO WS-CONCILIACAO-OK
                   END-IF
               WHEN CT-OCOR-ENTRADA-REJEITADA
                   MOVE "REJEITADO"     TO WT-STATUS(IDX-T)
                   MOVE 0               TO WT-VALOR-PAGO(IDX-T)
                   IF WS-T-ERROS >= 1 AND WS-T-ERROS <= CT-QTDE-MOTIVOS
                       MOVE WS-DESCR-MOTIVO(WS-T-ERROS)
                           TO WT-MOTIVO-REJEICAO(IDX-T)
                   ELSE
                       MOVE WS-DESCR-MOTIVO-DEFAULT
                           TO WT-MOTIVO-REJEICAO(IDX-T)
                   END-IF
                   ADD 1 TO WS-QTDE-REJEITADOS
               WHEN OTHER
                   DISPLAY "PROCRET: AVISO - ocorrencia nao tratada ("
                       WS-T-COD-OCORRENCIA ") para o nosso numero "
                       WT-NOSSO-NUMERO(IDX-T) ". Titulo segue "
                       "PENDENTE."
           END-EVALUATE.

      *=================================================================
      * A data vem do segmento U em DDMMAAAA. Comparar DDMMAAAA como
      * numero e errado (01/10/2026 = 01102026 < 20/09/2026 =
      * 20092026); convertemos para AAAAMMDD, onde a ordem numerica e
      * a ordem cronologica.
      *=================================================================
       560-CONVERTER-DATA-OCORRENCIA.
           MOVE WS-U-DATA-OCORRENCIA TO WS-OCOR-DDMMAAAA
           MOVE WS-OCOR-D-DD   TO WS-OCOR-DD
           MOVE WS-OCOR-D-MM   TO WS-OCOR-MM
           MOVE WS-OCOR-D-AAAA TO WS-OCOR-AAAA.

       600-REGRAVAR-STATUS.
           PERFORM VARYING IDX-T FROM 1 BY 1
               UNTIL IDX-T > WS-QTDE-TITULOS-TAB
               MOVE SPACES TO WS-TITULO-STATUS
               MOVE WT-NOSSO-NUMERO(IDX-T)    TO TS-NOSSO-NUMERO
               MOVE WT-NOME-PAGADOR(IDX-T)    TO TS-NOME-PAGADOR
               MOVE WT-VENCIMENTO(IDX-T)      TO TS-VENCIMENTO
               MOVE WT-VALOR-TITULO(IDX-T)    TO TS-VALOR-TITULO
               MOVE WT-STATUS(IDX-T)          TO TS-STATUS
               MOVE WT-DATA-OCORRENCIA(IDX-T) TO TS-DATA-OCORRENCIA
               MOVE WT-VALOR-PAGO(IDX-T)      TO TS-VALOR-PAGO
               MOVE WT-MOTIVO-REJEICAO(IDX-T) TO TS-MOTIVO-REJEICAO
               IF WT-STATUS(IDX-T) = "PENDENTE"
                   ADD 1 TO WS-QTDE-PENDENTES
               END-IF
               WRITE FD-STATUS-OUT-REC FROM WS-TITULO-STATUS
           END-PERFORM.

      *=================================================================
      * A identidade que o projeto promete:
      *   enviados = pagos + pagos com atraso + rejeitados + pendentes
      * Se nao fechar, algo se perdeu no caminho e o relatorio precisa
      * dizer isso em vez de exibir numeros que nao somam.
      *=================================================================
       650-VALIDAR-CONCILIACAO.
           COMPUTE WS-QTDE-SOMA-STATUS =
               WS-QTDE-PAGOS + WS-QTDE-PAGOS-ATRASO
               + WS-QTDE-REJEITADOS + WS-QTDE-PENDENTES

           IF WS-QTDE-SOMA-STATUS NOT = WS-QTDE-ENVIADOS
               MOVE "N" TO WS-CONCILIACAO-OK
           END-IF.

       700-EMITIR-CONCILIACAO.
           MOVE "===== FLOWCNAB - RELATORIO DE CONCILIACAO ====="
               TO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA
           PERFORM 795-EMITIR-LINHA-BRANCO

           MOVE WS-QTDE-ENVIADOS TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Titulos enviados na remessa.......: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           MOVE WS-QTDE-PAGOS TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Pagos no prazo....................: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           MOVE WS-QTDE-PAGOS-ATRASO TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Pagos com atraso..................: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           MOVE WS-QTDE-REJEITADOS TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Rejeitados/com erro...............: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           MOVE WS-QTDE-PENDENTES TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Ainda pendentes (sem retorno).....: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           PERFORM 795-EMITIR-LINHA-BRANCO

      * ---- conferencia explicita da identidade ----
           MOVE WS-QTDE-SOMA-STATUS TO WS-QTDE-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Soma por status (deve bater)......: " WS-QTDE-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

      * A conferencia reflete WS-CONCILIACAO-OK, nao apenas a soma
      * por status: retorno orfao, par T/U quebrado, ocorrencia
      * repetida e valor divergente nao quebram a identidade, mas o
      * relatorio nao pode dizer OK quando o RETURN-CODE diz 4.
           MOVE SPACES TO WS-LINHA-REL
           IF WS-CONCILIACAO-OK = "S"
               MOVE "Conferencia.......................: OK"
                   TO WS-LINHA-REL
           ELSE
               MOVE "Conferencia.......................: DIVERGENTE"
                   TO WS-LINHA-REL
           END-IF
           PERFORM 790-EMITIR-LINHA

           IF WS-QTDE-NAO-LOCALIZADOS > 0
               MOVE WS-QTDE-NAO-LOCALIZADOS TO WS-QTDE-EDIT
               MOVE SPACES TO WS-LINHA-REL
               STRING "Retornos sem titulo na remessa....: "
                   WS-QTDE-EDIT
                   DELIMITED BY SIZE INTO WS-LINHA-REL
               PERFORM 790-EMITIR-LINHA
           END-IF

           IF WS-QTDE-PARES-QUEBRADOS > 0
               MOVE WS-QTDE-PARES-QUEBRADOS TO WS-QTDE-EDIT
               MOVE SPACES TO WS-LINHA-REL
               STRING "Segmentos T sem o U correspondente: "
                   WS-QTDE-EDIT
                   DELIMITED BY SIZE INTO WS-LINHA-REL
               PERFORM 790-EMITIR-LINHA
           END-IF

           IF WS-QTDE-OCOR-REPETIDAS > 0
               MOVE WS-QTDE-OCOR-REPETIDAS TO WS-QTDE-EDIT
               MOVE SPACES TO WS-LINHA-REL
               STRING "Ocorrencias repetidas no retorno..: "
                   WS-QTDE-EDIT
                   DELIMITED BY SIZE INTO WS-LINHA-REL
               PERFORM 790-EMITIR-LINHA
           END-IF

           IF WS-QTDE-DIVERGENTES > 0
               MOVE WS-QTDE-DIVERGENTES TO WS-QTDE-EDIT
               MOVE SPACES TO WS-LINHA-REL
               STRING "Pagos com valor divergente........: "
                   WS-QTDE-EDIT
                   DELIMITED BY SIZE INTO WS-LINHA-REL
               PERFORM 790-EMITIR-LINHA
           END-IF

           PERFORM 795-EMITIR-LINHA-BRANCO

           MOVE WS-VALOR-ENVIADO TO WS-VALOR-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Valor total enviado (R$)..........: " WS-VALOR-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           MOVE WS-VALOR-CONCILIADO TO WS-VALOR-EDIT
           MOVE SPACES TO WS-LINHA-REL
           STRING "Valor total conciliado (R$).......: " WS-VALOR-EDIT
               DELIMITED BY SIZE INTO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA

           PERFORM 795-EMITIR-LINHA-BRANCO

           MOVE "Detalhe dos titulos rejeitados:" TO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA
           PERFORM VARYING IDX-T FROM 1 BY 1
               UNTIL IDX-T > WS-QTDE-TITULOS-TAB
               IF WT-STATUS(IDX-T) = "REJEITADO"
                   MOVE SPACES TO WS-LINHA-REL
                   STRING "  Nosso Numero " WT-NOSSO-NUMERO(IDX-T)
                       " - " WT-NOME-PAGADOR(IDX-T)
                       " - Motivo: " WT-MOTIVO-REJEICAO(IDX-T)
                       DELIMITED BY SIZE INTO WS-LINHA-REL
                   PERFORM 790-EMITIR-LINHA
               END-IF
           END-PERFORM.

      * Uma linha do relatorio e montada UMA vez e sai nos dois
      * destinos - arquivo e tela - para que nunca divirjam.
       790-EMITIR-LINHA.
           WRITE FD-RELATORIO-REC FROM WS-LINHA-REL
           DISPLAY FUNCTION TRIM(WS-LINHA-REL TRAILING).

       795-EMITIR-LINHA-BRANCO.
           MOVE SPACES TO WS-LINHA-REL
           PERFORM 790-EMITIR-LINHA.

       900-FECHAR-ARQUIVOS.
           CLOSE F-RETORNO
           CLOSE F-STATUS-IN
           CLOSE F-STATUS-OUT
           CLOSE F-RELATORIO.

       950-ENCERRAR.
           DISPLAY "PROCRET: conciliacao em "
               FUNCTION TRIM(WS-PATH-RELATORIO)

           IF WS-CONCILIACAO-OK = "S"
               MOVE 0 TO RETURN-CODE
           ELSE
               PERFORM 960-EXPLICAR-DIVERGENCIA
               MOVE 4 TO RETURN-CODE
           END-IF.

      * A mensagem antiga citava apenas enviados x soma por status -
      * que sao IGUAIS quando a causa e orfao, par quebrado,
      * ocorrencia repetida ou valor divergente, e o operador lia
      * "nao fechou" ao lado de dois numeros identicos.
       960-EXPLICAR-DIVERGENCIA.
           DISPLAY "PROCRET: ATENCAO - a conciliacao NAO fechou:"
           IF WS-QTDE-SOMA-STATUS NOT = WS-QTDE-ENVIADOS
               DISPLAY "  enviados (" WS-QTDE-ENVIADOS ") diferente "
                   "da soma por status (" WS-QTDE-SOMA-STATUS ")"
           END-IF
           IF WS-QTDE-NAO-LOCALIZADOS > 0
               DISPLAY "  " WS-QTDE-NAO-LOCALIZADOS " retorno(s) sem "
                   "titulo correspondente na remessa"
           END-IF
           IF WS-QTDE-PARES-QUEBRADOS > 0
               DISPLAY "  " WS-QTDE-PARES-QUEBRADOS " segmento(s) T "
                   "sem o segmento U correspondente"
           END-IF
           IF WS-QTDE-OCOR-REPETIDAS > 0
               DISPLAY "  " WS-QTDE-OCOR-REPETIDAS " ocorrencia(s) "
                   "repetida(s) para o mesmo nosso numero"
           END-IF
           IF WS-QTDE-DIVERGENTES > 0
               DISPLAY "  " WS-QTDE-DIVERGENTES " titulo(s) pago(s) "
                   "com valor diferente do titulo"
           END-IF.
