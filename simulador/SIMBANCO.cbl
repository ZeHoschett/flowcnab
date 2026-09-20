      ******************************************************************
      * PROGRAMA: SIMBANCO
      * "Simulador de banco para fins de teste."
      * Le o arquivo de REMESSA gerado pelo GERAREM e produz um arquivo
      * de RETORNO plausivel, sem depender de nenhum banco real:
      * a maioria dos titulos e marcada como PAGA (parte no prazo,
      * parte com atraso) e uma fracao menor e REJEITADA com motivos
      * variados (saldo insuficiente, dados inconsistentes, etc.).
      *
      * Isso substitui a resposta do banco nos testes do FLOWCNAB; nao
      * e uma gambiarra, e uma peca legitima do projeto (ver README).
      *
      * Entrada : saida/REMESSA.TXT   (CNAB 240 - segmentos P gerados
      *                                 pelo GERAREM)
      * Saida   : saida/RETORNO.TXT   (CNAB 240 - segmentos T/U)
      *
      * DATAS: dentro deste programa tudo esta em DDMMAAAA, porque
      * tanto a entrada (segmento P) quanto a saida (segmento U) sao
      * registros CNAB. A data de liquidacao com atraso e CALCULADA a
      * partir do vencimento do proprio titulo (vencimento +
      * CT-DIAS-ATRASO-SIMULADO dias), nao uma constante fixa - uma
      * data fixa deixaria de ser "atraso" com o passar do tempo.
      *
      * RETURN-CODE: 0 = ok / 8 = erro (ou remessa sem titulos).
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SIMBANCO.
       AUTHOR. FLOWCNAB.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-REMESSA ASSIGN TO WS-PATH-REMESSA
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-REMESSA.

           SELECT F-RETORNO ASSIGN TO WS-PATH-RETORNO
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-RETORNO.

       DATA DIVISION.
       FILE SECTION.
       FD  F-REMESSA.
       01  FD-REMESSA-REC                PIC X(240).

       FD  F-RETORNO.
       01  FD-RETORNO-REC                PIC X(240).

       WORKING-STORAGE SECTION.

           COPY "FLOWCNAB-CONST.cpy".
           COPY "CNAB240-HDR-ARQ.cpy".
           COPY "CNAB240-HDR-LOTE.cpy".
           COPY "CNAB240-DET-P.cpy".
           COPY "CNAB240-DET-T.cpy".
           COPY "CNAB240-DET-U.cpy".
           COPY "CNAB240-TRL-LOTE.cpy".
           COPY "CNAB240-TRL-ARQ.cpy".

       01  WS-PATH-REMESSA               PIC X(80)
               VALUE "saida/REMESSA.TXT".
       01  WS-PATH-RETORNO               PIC X(80)
               VALUE "saida/RETORNO.TXT".

       01  WS-FS-REMESSA                 PIC X(02).
       01  WS-FS-RETORNO                 PIC X(02).

       01  WS-EOF-REMESSA                PIC X(01) VALUE "N".
           88 FIM-REMESSA                          VALUE "S".

       01  WS-NUM-REGISTRO-LOTE          PIC 9(05) VALUE 0.
       01  WS-QTDE-TITULOS               PIC 9(06) VALUE 0.
       01  WS-QTDE-REJEITADOS            PIC 9(06) VALUE 0.
       01  WS-QTDE-ATRASADOS             PIC 9(06) VALUE 0.
       01  WS-VALOR-TOTAL                PIC 9(15)V9(02) VALUE 0.
       01  WS-TOTAL-REGISTROS-ARQ        PIC 9(06) VALUE 0.

      * ---- data de geracao do arquivo (DDMMAAAA, layout CNAB) ----
       01  WS-HOJE-AAAAMMDD              PIC 9(08).
       01  WS-HOJE-AAAAMMDD-R REDEFINES WS-HOJE-AAAAMMDD.
           05 WS-HOJE-AAAA               PIC 9(04).
           05 WS-HOJE-MM                 PIC 9(02).
           05 WS-HOJE-DD                 PIC 9(02).
       01  WS-HOJE-DDMMAAAA              PIC 9(08).
       01  WS-HOJE-DDMMAAAA-R REDEFINES WS-HOJE-DDMMAAAA.
           05 WS-HOJE-D-DD               PIC 9(02).
           05 WS-HOJE-D-MM               PIC 9(02).
           05 WS-HOJE-D-AAAA             PIC 9(04).

      * ---- dados extraidos do segmento P lido da remessa ----
       01  WS-P-NOSSO-NUMERO             PIC 9(08).
       01  WS-P-NUM-DOCUMENTO            PIC X(10).
       01  WS-P-VENCIMENTO               PIC 9(08).
       01  WS-P-VALOR-TITULO             PIC 9(13)V9(02).

      * ---- calculo da data de liquidacao (vencimento + N dias) ----
       01  WS-VENC-DDMMAAAA              PIC 9(08).
       01  WS-VENC-DDMMAAAA-R REDEFINES WS-VENC-DDMMAAAA.
           05 WS-VENC-D-DD               PIC 9(02).
           05 WS-VENC-D-MM               PIC 9(02).
           05 WS-VENC-D-AAAA             PIC 9(04).
       01  WS-VENC-AAAAMMDD              PIC 9(08).
       01  WS-VENC-AAAAMMDD-R REDEFINES WS-VENC-AAAAMMDD.
           05 WS-VENC-AAAA               PIC 9(04).
           05 WS-VENC-MM                 PIC 9(02).
           05 WS-VENC-DD                 PIC 9(02).
       01  WS-LIQ-AAAAMMDD               PIC 9(08).
       01  WS-LIQ-AAAAMMDD-R REDEFINES WS-LIQ-AAAAMMDD.
           05 WS-LIQ-AAAA                PIC 9(04).
           05 WS-LIQ-MM                  PIC 9(02).
           05 WS-LIQ-DD                  PIC 9(02).
       01  WS-LIQ-DDMMAAAA               PIC 9(08).
       01  WS-LIQ-DDMMAAAA-R REDEFINES WS-LIQ-DDMMAAAA.
           05 WS-LIQ-D-DD                PIC 9(02).
           05 WS-LIQ-D-MM                PIC 9(02).
           05 WS-LIQ-D-AAAA              PIC 9(04).
       01  WS-DIAS-ABSOLUTOS             PIC 9(08).

      * ---- motivos de rejeicao (rotativos) ----
      * Codigos numericos, como manda o campo DT-ERROS PIC 9(08).
      * As descricoes correspondentes estao no PROCRET.
       01  WS-MOTIVOS-TAB.
           05 FILLER                     PIC 9(02) VALUE 01.
           05 FILLER                     PIC 9(02) VALUE 02.
           05 FILLER                     PIC 9(02) VALUE 03.
       01  WS-MOTIVOS-RED REDEFINES WS-MOTIVOS-TAB.
           05 WS-MOTIVO OCCURS 3 TIMES   PIC 9(02).
       78  CT-QTDE-MOTIVOS               VALUE 3.
       01  WS-IDX-MOTIVO                 PIC 9(01) VALUE 0.

       01  WS-CONTADOR-TITULO            PIC 9(08) VALUE 0.
       01  WS-REJEITAR                   PIC X(01).
           88 TITULO-REJEITADO                     VALUE "S".
       01  WS-COM-ATRASO                 PIC X(01).
           88 TITULO-COM-ATRASO                    VALUE "S".

      * ---- regras da simulacao (ver 500-GERAR-RETORNO-TITULO) ----
       78  CT-PERIODO-REJEICAO           VALUE 7.
       78  CT-PERIODO-ATRASO             VALUE 3.

       PROCEDURE DIVISION.

       000-PRINCIPAL.
           PERFORM 100-INICIALIZAR
           PERFORM 200-ABRIR-ARQUIVOS
           PERFORM 300-GERAR-HEADERS
           PERFORM 400-LER-REMESSA
           PERFORM UNTIL FIM-REMESSA
               IF DP-SEGMENTO OF WS-DET-P = "P"
                   PERFORM 500-GERAR-RETORNO-TITULO
               END-IF
               PERFORM 400-LER-REMESSA
           END-PERFORM
           PERFORM 600-GERAR-TRAILERS
           PERFORM 900-FECHAR-ARQUIVOS
           PERFORM 950-ENCERRAR
           STOP RUN.

       100-INICIALIZAR.
           ACCEPT WS-HOJE-AAAAMMDD FROM DATE YYYYMMDD
           MOVE WS-HOJE-DD   TO WS-HOJE-D-DD
           MOVE WS-HOJE-MM   TO WS-HOJE-D-MM
           MOVE WS-HOJE-AAAA TO WS-HOJE-D-AAAA.

       200-ABRIR-ARQUIVOS.
           OPEN INPUT F-REMESSA
           IF WS-FS-REMESSA NOT = "00"
              DISPLAY "SIMBANCO: ERRO ao abrir "
                  FUNCTION TRIM(WS-PATH-REMESSA)
                  " - FILE STATUS " WS-FS-REMESSA
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN OUTPUT F-RETORNO
           IF WS-FS-RETORNO NOT = "00"
              DISPLAY "SIMBANCO: ERRO ao criar "
                  FUNCTION TRIM(WS-PATH-RETORNO)
                  " - FILE STATUS " WS-FS-RETORNO
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF.

       300-GERAR-HEADERS.
      * ---- Header de Arquivo (tipo 0) ----
           MOVE SPACES              TO WS-HDR-ARQUIVO
           MOVE CT-CODIGO-BANCO     TO HA-CODIGO-BANCO
           MOVE 0                   TO HA-CODIGO-LOTE
           MOVE CT-TIPO-HDR-ARQUIVO TO HA-TIPO-REGISTRO
           MOVE SPACES              TO HA-BRANCOS-1
           MOVE CT-EMPRESA-TIPO-INSCRICAO TO HA-TIPO-INSCRICAO
           MOVE CT-EMPRESA-CNPJ     TO HA-NUM-INSCRICAO
           MOVE SPACES              TO HA-BRANCOS-2
           MOVE 0                   TO HA-ZERO-1
           MOVE CT-EMPRESA-AGENCIA  TO HA-AGENCIA
           MOVE SPACES              TO HA-BRANCOS-3
           MOVE 0                   TO HA-ZEROS-2
           MOVE CT-EMPRESA-CONTA    TO HA-CONTA
           MOVE SPACES              TO HA-BRANCOS-4
           MOVE CT-EMPRESA-DAC      TO HA-DAC-AG-CONTA
           MOVE CT-EMPRESA-NOME     TO HA-NOME-EMPRESA
           MOVE CT-NOME-BANCO       TO HA-NOME-BANCO
           MOVE SPACES              TO HA-BRANCOS-5
           MOVE CT-ARQUIVO-RETORNO  TO HA-CODIGO-ARQUIVO
           MOVE WS-HOJE-DDMMAAAA    TO HA-DATA-GERACAO
           MOVE 0                   TO HA-HORA-GERACAO
           MOVE 1                   TO HA-NUM-SEQ-ARQUIVO
           MOVE CT-LAYOUT-ARQUIVO   TO HA-LAYOUT-ARQUIVO
           MOVE 0                   TO HA-ZEROS-3
           MOVE SPACES              TO HA-BRANCOS-6
           MOVE 0                   TO HA-ZEROS-4
           MOVE SPACES              TO HA-BRANCOS-7
           WRITE FD-RETORNO-REC FROM WS-HDR-ARQUIVO
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ

      * ---- Header de Lote (tipo 1) ----
           MOVE SPACES              TO WS-HDR-LOTE
           MOVE CT-CODIGO-BANCO     TO HL-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO HL-CODIGO-LOTE
           MOVE CT-TIPO-HDR-LOTE    TO HL-TIPO-REGISTRO
           MOVE "T"                 TO HL-OPERACAO
           MOVE CT-CODIGO-SERVICO   TO HL-CODIGO-SERVICO
           MOVE 0                   TO HL-ZEROS-1
           MOVE CT-LAYOUT-LOTE      TO HL-LAYOUT-LOTE
           MOVE SPACES              TO HL-BRANCO-1
           MOVE CT-EMPRESA-TIPO-INSCRICAO TO HL-CODIGO-INSCRICAO
           MOVE CT-EMPRESA-CNPJ     TO HL-NUM-INSCRICAO
           MOVE SPACES              TO HL-BRANCOS-1
           MOVE 0                   TO HL-ZERO-1
           MOVE CT-EMPRESA-AGENCIA  TO HL-AGENCIA
           MOVE SPACES              TO HL-BRANCO-2
           MOVE 0                   TO HL-ZEROS-2
           MOVE CT-EMPRESA-CONTA    TO HL-CONTA
           MOVE SPACES              TO HL-BRANCO-3
           MOVE CT-EMPRESA-DAC      TO HL-DAC-AG-CONTA
           MOVE CT-EMPRESA-NOME     TO HL-NOME-EMPRESA
           MOVE SPACES              TO HL-BRANCOS-2
           MOVE 1                   TO HL-NUM-SEQ-ARQ-RETORNO
           MOVE WS-HOJE-DDMMAAAA    TO HL-DATA-GRAVACAO
           MOVE WS-HOJE-DDMMAAAA    TO HL-DATA-CREDITO
           MOVE SPACES              TO HL-BRANCOS-3
           WRITE FD-RETORNO-REC FROM WS-HDR-LOTE
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

       400-LER-REMESSA.
           READ F-REMESSA INTO WS-DET-P
               AT END
                   MOVE "S" TO WS-EOF-REMESSA
           END-READ.

      *=================================================================
      * Regra de simulacao: 1 a cada CT-PERIODO-REJEICAO titulos e
      * rejeitado; dos que sobram, 1 a cada CT-PERIODO-ATRASO e
      * liquidado com atraso. Distribuicao aproximada: ~85% pagos,
      * ~15% rejeitados.
      *=================================================================
       500-GERAR-RETORNO-TITULO.
           MOVE DP-NOSSO-NUMERO     TO WS-P-NOSSO-NUMERO
           MOVE DP-NUM-DOCUMENTO    TO WS-P-NUM-DOCUMENTO
           MOVE DP-VENCIMENTO       TO WS-P-VENCIMENTO
           MOVE DP-VALOR-TITULO     TO WS-P-VALOR-TITULO

           ADD 1 TO WS-CONTADOR-TITULO
           ADD 1 TO WS-QTDE-TITULOS
           ADD WS-P-VALOR-TITULO    TO WS-VALOR-TOTAL

           IF FUNCTION MOD(WS-CONTADOR-TITULO, CT-PERIODO-REJEICAO) = 0
               MOVE "S" TO WS-REJEITAR
               ADD 1 TO WS-QTDE-REJEITADOS
           ELSE
               MOVE "N" TO WS-REJEITAR
           END-IF

           MOVE "N" TO WS-COM-ATRASO
           IF NOT TITULO-REJEITADO
               IF FUNCTION MOD(WS-CONTADOR-TITULO, CT-PERIODO-ATRASO)
                   = 0
                   MOVE "S" TO WS-COM-ATRASO
                   ADD 1 TO WS-QTDE-ATRASADOS
               END-IF
           END-IF

           PERFORM 510-CALCULAR-DATA-LIQUIDACAO
           PERFORM 520-GRAVAR-SEGMENTO-T
           PERFORM 530-GRAVAR-SEGMENTO-U.

      *=================================================================
      * Data de liquidacao a partir do vencimento do proprio titulo.
      * O vencimento vem do segmento P em DDMMAAAA; a aritmetica de
      * datas exige AAAAMMDD (INTEGER-OF-DATE), entao convertemos para
      * calcular e voltamos para DDMMAAAA ao gravar no segmento U.
      *=================================================================
       510-CALCULAR-DATA-LIQUIDACAO.
           MOVE WS-P-VENCIMENTO TO WS-VENC-DDMMAAAA
           MOVE WS-VENC-D-DD    TO WS-VENC-DD
           MOVE WS-VENC-D-MM    TO WS-VENC-MM
           MOVE WS-VENC-D-AAAA  TO WS-VENC-AAAA

           IF TITULO-COM-ATRASO
               COMPUTE WS-DIAS-ABSOLUTOS =
                   FUNCTION INTEGER-OF-DATE(WS-VENC-AAAAMMDD)
                   + CT-DIAS-ATRASO-SIMULADO
               COMPUTE WS-LIQ-AAAAMMDD =
                   FUNCTION DATE-OF-INTEGER(WS-DIAS-ABSOLUTOS)
           ELSE
               MOVE WS-VENC-AAAAMMDD TO WS-LIQ-AAAAMMDD
           END-IF

           MOVE WS-LIQ-DD   TO WS-LIQ-D-DD
           MOVE WS-LIQ-MM   TO WS-LIQ-D-MM
           MOVE WS-LIQ-AAAA TO WS-LIQ-D-AAAA.

       520-GRAVAR-SEGMENTO-T.
           ADD 1 TO WS-NUM-REGISTRO-LOTE
           MOVE SPACES              TO WS-DET-T
           MOVE CT-CODIGO-BANCO     TO DT-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO DT-CODIGO-LOTE
           MOVE CT-TIPO-DETALHE     TO DT-TIPO-REGISTRO
           MOVE WS-NUM-REGISTRO-LOTE TO DT-NUM-REGISTRO
           MOVE "T"                 TO DT-SEGMENTO
           MOVE SPACES              TO DT-BOLETO-DDA
           IF TITULO-REJEITADO
               MOVE CT-OCOR-ENTRADA-REJEITADA TO DT-COD-OCORRENCIA
           ELSE
               MOVE CT-OCOR-LIQUIDACAO        TO DT-COD-OCORRENCIA
           END-IF
           MOVE 0                   TO DT-ZERO-1
           MOVE CT-EMPRESA-AGENCIA  TO DT-AGENCIA
           MOVE 0                   TO DT-ZEROS-1
           MOVE CT-EMPRESA-CONTA    TO DT-CONTA
           MOVE 0                   TO DT-ZERO-2
           MOVE CT-EMPRESA-DAC      TO DT-DAC-AG-CONTA
           MOVE CT-NUM-CARTEIRA     TO DT-NUM-CARTEIRA
           MOVE WS-P-NOSSO-NUMERO   TO DT-NOSSO-NUMERO
           MOVE 0                   TO DT-DAC-NOSSO-NUMERO
           MOVE SPACES              TO DT-BRANCOS-1
           MOVE 0                   TO DT-ZERO-3
           MOVE WS-P-NUM-DOCUMENTO  TO DT-SEU-NUMERO
           MOVE SPACES              TO DT-BRANCOS-2
           MOVE WS-P-VENCIMENTO     TO DT-VENCIMENTO
           MOVE WS-P-VALOR-TITULO   TO DT-VALOR-TITULO
           MOVE 0                   TO DT-ZEROS-2
           MOVE CT-EMPRESA-AGENCIA  TO DT-AGENCIA-COBRADORA
           MOVE 0                   TO DT-DAC-AG-COBRADORA
           MOVE WS-P-NUM-DOCUMENTO  TO DT-USO-EMPRESA
           MOVE 0                   TO DT-ZEROS-3
           MOVE 0                   TO DT-COD-INSCRICAO-PAG
           MOVE 0                   TO DT-NUM-INSCRICAO-PAG
           MOVE SPACES              TO DT-NOME-PAGADOR
           MOVE SPACES              TO DT-BRANCOS-3
           MOVE 0                   TO DT-ZEROS-4
           MOVE 0                   TO DT-TARIFAS-CUSTAS
           IF TITULO-REJEITADO
               PERFORM 525-PROXIMO-MOTIVO
               MOVE WS-MOTIVO(WS-IDX-MOTIVO) TO DT-ERROS
           ELSE
               MOVE 0               TO DT-ERROS
           END-IF
           MOVE "01"                TO DT-COD-LIQUIDACAO
           MOVE SPACES              TO DT-BRANCOS-4
           WRITE FD-RETORNO-REC FROM WS-DET-T
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

      * Avanca a rotacao ANTES de usar o indice, comecando em 1 - a
      * versao anterior incrementava a partir de 1 e nunca emitia o
      * motivo 01.
       525-PROXIMO-MOTIVO.
           IF WS-IDX-MOTIVO >= CT-QTDE-MOTIVOS
               MOVE 1 TO WS-IDX-MOTIVO
           ELSE
               ADD 1 TO WS-IDX-MOTIVO
           END-IF.

       530-GRAVAR-SEGMENTO-U.
           ADD 1 TO WS-NUM-REGISTRO-LOTE
           MOVE SPACES              TO WS-DET-U
           MOVE CT-CODIGO-BANCO     TO DU-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO DU-CODIGO-LOTE
           MOVE CT-TIPO-DETALHE     TO DU-TIPO-REGISTRO
           MOVE WS-NUM-REGISTRO-LOTE TO DU-NUM-REGISTRO
           MOVE "U"                 TO DU-SEGMENTO
           MOVE SPACES              TO DU-BRANCO-1
           IF TITULO-REJEITADO
               MOVE CT-OCOR-ENTRADA-REJEITADA TO DU-COD-OCORRENCIA
           ELSE
               MOVE CT-OCOR-LIQUIDACAO        TO DU-COD-OCORRENCIA
           END-IF
           MOVE 0                   TO DU-JUROS-MULTA
           MOVE 0                   TO DU-VALOR-DESCONTO
           MOVE 0                   TO DU-VALOR-ABATIMENTO
           MOVE 0                   TO DU-VALOR-IOF
           IF TITULO-REJEITADO
               MOVE 0               TO DU-VALOR-PAGO
               MOVE 0               TO DU-VALOR-LIQUIDO
               MOVE 0               TO DU-DATA-OCORRENCIA
               MOVE 0               TO DU-DATA-CREDITO
           ELSE
               MOVE WS-P-VALOR-TITULO TO DU-VALOR-PAGO
               MOVE WS-P-VALOR-TITULO TO DU-VALOR-LIQUIDO
               MOVE WS-LIQ-DDMMAAAA   TO DU-DATA-OCORRENCIA
               MOVE WS-LIQ-DDMMAAAA   TO DU-DATA-CREDITO
           END-IF
           MOVE 0                   TO DU-ZEROS-1
           MOVE 0                   TO DU-COD-OCORRENCIA-PAG
           MOVE 0                   TO DU-DATA-OCORRENCIA-PAG
           MOVE 0                   TO DU-VALOR-OCORRENCIA-PAG
           MOVE SPACES              TO DU-BRANCOS-1
           MOVE 0                   TO DU-ZEROS-2
           MOVE SPACES              TO DU-BRANCOS-2
           WRITE FD-RETORNO-REC FROM WS-DET-U
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

       600-GERAR-TRAILERS.
      * ---- Trailer de Lote (tipo 5) ----
           MOVE SPACES              TO WS-TRL-LOTE
           MOVE CT-CODIGO-BANCO     TO TL-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO TL-CODIGO-LOTE
           MOVE CT-TIPO-TRL-LOTE    TO TL-TIPO-REGISTRO
           MOVE SPACES              TO TL-BRANCOS-1
           COMPUTE TL-QTDE-REGISTROS = 2 + (WS-QTDE-TITULOS * 2)
           MOVE WS-QTDE-TITULOS     TO TL-QTDE-COBR-SIMPLES
           MOVE WS-VALOR-TOTAL      TO TL-VLR-COBR-SIMPLES
           MOVE 0                   TO TL-QTDE-COBR-VINCULADA
           MOVE 0                   TO TL-VLR-COBR-VINCULADA
           MOVE ALL "0"             TO TL-ZEROS-1
           MOVE SPACES              TO TL-AVISO-BANCARIO
           MOVE SPACES              TO TL-BRANCOS-2
           WRITE FD-RETORNO-REC FROM WS-TRL-LOTE
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ

      * ---- Trailer de Arquivo (tipo 9) ----
           MOVE SPACES              TO WS-TRL-ARQUIVO
           MOVE CT-CODIGO-BANCO     TO TA-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE-TRAILER TO TA-CODIGO-LOTE
           MOVE CT-TIPO-TRL-ARQUIVO TO TA-TIPO-REGISTRO
           MOVE SPACES              TO TA-BRANCOS-1
           MOVE 1                   TO TA-TOTAL-LOTES
           ADD 1                    TO WS-TOTAL-REGISTROS-ARQ
           MOVE WS-TOTAL-REGISTROS-ARQ TO TA-TOTAL-REGISTROS
           MOVE 0                   TO TA-ZEROS-1
           MOVE SPACES              TO TA-BRANCOS-2
           WRITE FD-RETORNO-REC FROM WS-TRL-ARQUIVO.

       900-FECHAR-ARQUIVOS.
           CLOSE F-REMESSA
           CLOSE F-RETORNO.

       950-ENCERRAR.
           DISPLAY "SIMBANCO: " WS-QTDE-TITULOS
               " titulo(s) no retorno simulado ("
               WS-QTDE-REJEITADOS " rejeitado(s), "
               WS-QTDE-ATRASADOS " com atraso)."

           IF WS-QTDE-TITULOS = 0
               DISPLAY "SIMBANCO: ERRO - a remessa nao contem nenhum "
                   "segmento P. Nada a simular."
               MOVE 8 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
