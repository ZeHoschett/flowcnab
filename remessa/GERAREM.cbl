      ******************************************************************
      * PROGRAMA: GERAREM
      * Gera o arquivo de REMESSA CNAB 240 (cobranca via boleto,
      * banco Itau - 341) a partir da lista de cobrancas pendentes.
      *
      * Entrada : dados/cobrancas_pendentes.txt  (COBRANCA-PENDENTE)
      * Saidas  : saida/REMESSA.TXT              (CNAB 240)
      *           dados/titulos_status.txt       (TITULO-STATUS, status
      *                                            inicial = PENDENTE)
      *
      * DATAS: a entrada traz vencimento em AAAAMMDD (ver
      * COBRANCA-PENDENTE.cpy); o segmento P exige DDMMAAAA. A
      * conversao acontece em 520-CONVERTER-VENCIMENTO e em lugar
      * nenhum mais.
      *
      * RETURN-CODE: 0 = ok / 4 = remessa gerada com titulos
      * descartados / 8 = erro que impede gerar a remessa.
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GERAREM.
       AUTHOR. FLOWCNAB.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-COBRANCAS ASSIGN TO WS-PATH-COBRANCAS
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-COBRANCAS.

           SELECT F-REMESSA ASSIGN TO WS-PATH-REMESSA
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-REMESSA.

           SELECT F-STATUS ASSIGN TO WS-PATH-STATUS
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FS-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  F-COBRANCAS.
       01  FD-COBRANCA-REC              PIC X(165).

       FD  F-REMESSA.
       01  FD-REMESSA-REC               PIC X(240).

       FD  F-STATUS.
       01  FD-STATUS-REC                PIC X(130).

       WORKING-STORAGE SECTION.

           COPY "FLOWCNAB-CONST.cpy".
           COPY "COBRANCA-PENDENTE.cpy".
           COPY "TITULO-STATUS.cpy".
           COPY "CNAB240-HDR-ARQ.cpy".
           COPY "CNAB240-HDR-LOTE.cpy".
           COPY "CNAB240-DET-P.cpy".
           COPY "CNAB240-DET-Q.cpy".
           COPY "CNAB240-TRL-LOTE.cpy".
           COPY "CNAB240-TRL-ARQ.cpy".

       01  WS-PATH-COBRANCAS            PIC X(80)
               VALUE "dados/cobrancas_pendentes.txt".
       01  WS-PATH-REMESSA              PIC X(80)
               VALUE "saida/REMESSA.TXT".
       01  WS-PATH-STATUS               PIC X(80)
               VALUE "dados/titulos_status.txt".

       01  WS-FS-COBRANCAS              PIC X(02).
       01  WS-FS-REMESSA                PIC X(02).
       01  WS-FS-STATUS                 PIC X(02).

       01  WS-EOF-COBRANCAS             PIC X(01) VALUE "N".
           88 FIM-COBRANCAS                        VALUE "S".

       01  WS-NUM-REGISTRO-LOTE         PIC 9(05) VALUE 0.
       01  WS-QTDE-TITULOS              PIC 9(06) VALUE 0.
       01  WS-VALOR-TOTAL               PIC 9(15)V9(02) VALUE 0.
       01  WS-TOTAL-REGISTROS-ARQ       PIC 9(06) VALUE 0.

      * ---- contadores de critica da entrada ----
       01  WS-QTDE-LIDAS                PIC 9(06) VALUE 0.
       01  WS-QTDE-DESCARTADAS          PIC 9(06) VALUE 0.
       01  WS-REGISTRO-VALIDO           PIC X(01) VALUE "S".
           88 REGISTRO-VALIDO                      VALUE "S".

      * ---- data corrente, nas duas representacoes ----
       01  WS-HOJE-AAAAMMDD             PIC 9(08).
       01  WS-HOJE-AAAAMMDD-R REDEFINES WS-HOJE-AAAAMMDD.
           05 WS-HOJE-AAAA              PIC 9(04).
           05 WS-HOJE-MM                PIC 9(02).
           05 WS-HOJE-DD                PIC 9(02).
       01  WS-HOJE-DDMMAAAA             PIC 9(08).
       01  WS-HOJE-DDMMAAAA-R REDEFINES WS-HOJE-DDMMAAAA.
           05 WS-HOJE-D-DD              PIC 9(02).
           05 WS-HOJE-D-MM              PIC 9(02).
           05 WS-HOJE-D-AAAA            PIC 9(04).

       01  WS-HORA-ATUAL.
           05 WS-HORA-HH                PIC 9(02).
           05 WS-HORA-MM                PIC 9(02).
           05 WS-HORA-SS                PIC 9(02).
       01  WS-HORA-HHMMSS               PIC 9(06).
       01  WS-HORA-HHMMSS-R REDEFINES WS-HORA-HHMMSS.
           05 WS-HHMMSS-HH              PIC 9(02).
           05 WS-HHMMSS-MM              PIC 9(02).
           05 WS-HHMMSS-SS              PIC 9(02).

      * ---- vencimento do titulo, nas duas representacoes ----
       01  WS-VENC-AAAAMMDD             PIC 9(08).
       01  WS-VENC-AAAAMMDD-R REDEFINES WS-VENC-AAAAMMDD.
           05 WS-VENC-AAAA              PIC 9(04).
           05 WS-VENC-MM                PIC 9(02).
           05 WS-VENC-DD                PIC 9(02).
       01  WS-VENC-DDMMAAAA             PIC 9(08).
       01  WS-VENC-DDMMAAAA-R REDEFINES WS-VENC-DDMMAAAA.
           05 WS-VENC-D-DD              PIC 9(02).
           05 WS-VENC-D-MM              PIC 9(02).
           05 WS-VENC-D-AAAA            PIC 9(04).

      * ---- controle de nosso-numero duplicado ----
      * A remessa e a chave de toda a conciliacao: dois titulos com o
      * mesmo nosso numero fazem o PROCRET atualizar sempre o primeiro
      * e deixar o segundo eternamente PENDENTE. Barramos aqui.
      * A tabela usa CT-MAX-TITULOS, o mesmo limite da tabela em
      * memoria do PROCRET.
       01  WS-TAB-NOSSO-NUMERO.
           05 WS-NN-EMITIDO OCCURS CT-MAX-TITULOS TIMES
                            INDEXED BY IDX-NN     PIC 9(08).
       01  WS-QTDE-NN-EMITIDOS          PIC 9(04) VALUE 0.
       01  WS-NN-DUPLICADO              PIC X(01).

       PROCEDURE DIVISION.

       000-PRINCIPAL.
           PERFORM 100-INICIALIZAR
           PERFORM 200-ABRIR-ARQUIVOS
           PERFORM 300-GERAR-HEADERS
           PERFORM 400-LER-COBRANCAS
           PERFORM UNTIL FIM-COBRANCAS
               PERFORM 450-CRITICAR-COBRANCA
               IF REGISTRO-VALIDO
                   PERFORM 500-GERAR-DETALHE
               END-IF
               PERFORM 400-LER-COBRANCAS
           END-PERFORM
           PERFORM 600-GERAR-TRAILERS
           PERFORM 900-FECHAR-ARQUIVOS
           PERFORM 950-ENCERRAR
           STOP RUN.

       100-INICIALIZAR.
           ACCEPT WS-HOJE-AAAAMMDD FROM DATE YYYYMMDD
           MOVE WS-HOJE-DD   TO WS-HOJE-D-DD
           MOVE WS-HOJE-MM   TO WS-HOJE-D-MM
           MOVE WS-HOJE-AAAA TO WS-HOJE-D-AAAA
           ACCEPT WS-HORA-ATUAL FROM TIME
           MOVE WS-HORA-HH TO WS-HHMMSS-HH
           MOVE WS-HORA-MM TO WS-HHMMSS-MM
           MOVE WS-HORA-SS TO WS-HHMMSS-SS.

       200-ABRIR-ARQUIVOS.
           OPEN INPUT F-COBRANCAS
           IF WS-FS-COBRANCAS NOT = "00"
              DISPLAY "GERAREM: ERRO ao abrir "
                  FUNCTION TRIM(WS-PATH-COBRANCAS)
                  " - FILE STATUS " WS-FS-COBRANCAS
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN OUTPUT F-REMESSA
           IF WS-FS-REMESSA NOT = "00"
              DISPLAY "GERAREM: ERRO ao criar "
                  FUNCTION TRIM(WS-PATH-REMESSA)
                  " - FILE STATUS " WS-FS-REMESSA
              MOVE 8 TO RETURN-CODE
              STOP RUN
           END-IF

           OPEN OUTPUT F-STATUS
           IF WS-FS-STATUS NOT = "00"
              DISPLAY "GERAREM: ERRO ao criar "
                  FUNCTION TRIM(WS-PATH-STATUS)
                  " - FILE STATUS " WS-FS-STATUS
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
           MOVE CT-ARQUIVO-REMESSA  TO HA-CODIGO-ARQUIVO
           MOVE WS-HOJE-DDMMAAAA    TO HA-DATA-GERACAO
           MOVE WS-HORA-HHMMSS      TO HA-HORA-GERACAO
           MOVE 1                   TO HA-NUM-SEQ-ARQUIVO
           MOVE CT-LAYOUT-ARQUIVO   TO HA-LAYOUT-ARQUIVO
           MOVE 0                   TO HA-ZEROS-3
           MOVE SPACES              TO HA-BRANCOS-6
           MOVE 0                   TO HA-ZEROS-4
           MOVE SPACES              TO HA-BRANCOS-7
           WRITE FD-REMESSA-REC FROM WS-HDR-ARQUIVO
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ

      * ---- Header de Lote (tipo 1) ----
           MOVE SPACES              TO WS-HDR-LOTE
           MOVE CT-CODIGO-BANCO     TO HL-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO HL-CODIGO-LOTE
           MOVE CT-TIPO-HDR-LOTE    TO HL-TIPO-REGISTRO
           MOVE "R"                 TO HL-OPERACAO
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
           MOVE 0                   TO HL-NUM-SEQ-ARQ-RETORNO
           MOVE WS-HOJE-DDMMAAAA    TO HL-DATA-GRAVACAO
           MOVE 0                   TO HL-DATA-CREDITO
           MOVE SPACES              TO HL-BRANCOS-3
           WRITE FD-REMESSA-REC FROM WS-HDR-LOTE
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

       400-LER-COBRANCAS.
           READ F-COBRANCAS INTO WS-COBRANCA-PENDENTE
               AT END
                   MOVE "S" TO WS-EOF-COBRANCAS
               NOT AT END
                   ADD 1 TO WS-QTDE-LIDAS
           END-READ.

      *=================================================================
      * Critica do registro de entrada. Um registro reprovado e
      * descartado com aviso (e contado em WS-QTDE-DESCARTADAS), sem
      * derrubar a remessa inteira - excecao para o estouro de
      * capacidade, que e erro fatal.
      *=================================================================
       450-CRITICAR-COBRANCA.
           MOVE "S" TO WS-REGISTRO-VALIDO

      * ---- capacidade da tabela (limite compartilhado com o PROCRET)
           IF WS-QTDE-NN-EMITIDOS >= CT-MAX-TITULOS
               DISPLAY "GERAREM: ERRO FATAL - a remessa excedeu o "
                   "limite de " CT-MAX-TITULOS " titulos suportado "
                   "pelo PROCRET. Divida a carga em lotes menores."
               PERFORM 900-FECHAR-ARQUIVOS
               MOVE 8 TO RETURN-CODE
               STOP RUN
           END-IF

      * ---- nosso numero ----
      * Vem primeiro porque e a chave que identifica o titulo nas
      * mensagens seguintes - e porque um valor nao numerico aqui
      * atravessava a critica inteira e ia parar, letra por letra,
      * dentro de DP-NOSSO-NUMERO PIC 9(08) (pos. 41-48 do segmento
      * P). O banco rejeita o arquivo e o PROCRET nunca casaria o
      * retorno de volta.
           IF CP-NOSSO-NUMERO NOT NUMERIC
              OR CP-NOSSO-NUMERO = 0
               DISPLAY "GERAREM: AVISO - titulo descartado, nosso "
                   "numero invalido ou zerado: [" CP-NOSSO-NUMERO "]"
               MOVE "N" TO WS-REGISTRO-VALIDO
           END-IF

      * ---- valor do titulo ----
           IF REGISTRO-VALIDO
               IF CP-VALOR-TITULO NOT NUMERIC
                  OR CP-VALOR-TITULO = 0
                   DISPLAY "GERAREM: AVISO - titulo descartado, "
                       "valor invalido ou zerado. Nosso numero: "
                       CP-NOSSO-NUMERO
                   MOVE "N" TO WS-REGISTRO-VALIDO
               END-IF
           END-IF

      * ---- vencimento (AAAAMMDD) ----
           IF REGISTRO-VALIDO
               MOVE CP-VENCIMENTO TO WS-VENC-AAAAMMDD
               IF WS-VENC-MM < 1 OR WS-VENC-MM > 12
                  OR WS-VENC-DD < 1 OR WS-VENC-DD > 31
                  OR WS-VENC-AAAA < 1900
                   DISPLAY "GERAREM: AVISO - titulo descartado, "
                       "vencimento invalido (esperado AAAAMMDD): "
                       CP-VENCIMENTO " - Nosso numero: "
                       CP-NOSSO-NUMERO
                   MOVE "N" TO WS-REGISTRO-VALIDO
               END-IF
           END-IF

      * ---- campos numericos do pagador (alimentam o segmento Q) ----
      * Um MOVE de campo nao numerico para PIC 9 nao falha: o
      * GnuCOBOL grava zeros e a remessa sai com o CEP ou o CNPJ do
      * pagador zerado, sem aviso nenhum.
           IF REGISTRO-VALIDO
               IF CP-CEP-PAGADOR NOT NUMERIC
                  OR CP-CPF-CNPJ-PAGADOR NOT NUMERIC
                  OR CP-TIPO-INSCRICAO-PAG NOT NUMERIC
                   DISPLAY "GERAREM: AVISO - titulo descartado, "
                       "dados do pagador com campo numerico "
                       "invalido. Nosso numero: " CP-NOSSO-NUMERO
                   MOVE "N" TO WS-REGISTRO-VALIDO
               END-IF
           END-IF

      * ---- nosso numero duplicado ----
           IF REGISTRO-VALIDO
               PERFORM 460-VERIFICAR-DUPLICIDADE
               IF WS-NN-DUPLICADO = "S"
                   DISPLAY "GERAREM: AVISO - titulo descartado, "
                       "nosso numero duplicado na mesma remessa: "
                       CP-NOSSO-NUMERO
                   MOVE "N" TO WS-REGISTRO-VALIDO
               END-IF
           END-IF

           IF NOT REGISTRO-VALIDO
               ADD 1 TO WS-QTDE-DESCARTADAS
           END-IF.

       460-VERIFICAR-DUPLICIDADE.
           MOVE "N" TO WS-NN-DUPLICADO
           PERFORM VARYING IDX-NN FROM 1 BY 1
               UNTIL IDX-NN > WS-QTDE-NN-EMITIDOS
                  OR WS-NN-DUPLICADO = "S"
               IF WS-NN-EMITIDO(IDX-NN) = CP-NOSSO-NUMERO
                   MOVE "S" TO WS-NN-DUPLICADO
               END-IF
           END-PERFORM.

       500-GERAR-DETALHE.
           ADD 1 TO WS-QTDE-TITULOS
           ADD CP-VALOR-TITULO TO WS-VALOR-TOTAL

           ADD 1 TO WS-QTDE-NN-EMITIDOS
           SET IDX-NN TO WS-QTDE-NN-EMITIDOS
           MOVE CP-NOSSO-NUMERO TO WS-NN-EMITIDO(IDX-NN)

           PERFORM 520-CONVERTER-VENCIMENTO
           PERFORM 530-GRAVAR-SEGMENTO-P
           PERFORM 540-GRAVAR-SEGMENTO-Q
           PERFORM 550-GRAVAR-STATUS-INICIAL.

      *=================================================================
      * UNICO ponto de conversao AAAAMMDD (arquivo interno) ->
      * DDMMAAAA (layout CNAB 240 do Itau).
      *=================================================================
       520-CONVERTER-VENCIMENTO.
           MOVE CP-VENCIMENTO TO WS-VENC-AAAAMMDD
           MOVE WS-VENC-DD    TO WS-VENC-D-DD
           MOVE WS-VENC-MM    TO WS-VENC-D-MM
           MOVE WS-VENC-AAAA  TO WS-VENC-D-AAAA.

       530-GRAVAR-SEGMENTO-P.
           ADD 1 TO WS-NUM-REGISTRO-LOTE
           MOVE SPACES              TO WS-DET-P
           MOVE CT-CODIGO-BANCO     TO DP-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO DP-CODIGO-LOTE
           MOVE CT-TIPO-DETALHE     TO DP-TIPO-REGISTRO
           MOVE WS-NUM-REGISTRO-LOTE TO DP-NUM-REGISTRO
           MOVE "P"                 TO DP-SEGMENTO
           MOVE SPACES              TO DP-BRANCO-1
           MOVE CT-OCOR-ENTRADA-TITULO TO DP-COD-OCORRENCIA
           MOVE 0                   TO DP-ZERO-1
           MOVE CT-EMPRESA-AGENCIA  TO DP-AGENCIA
           MOVE SPACES              TO DP-BRANCO-2
           MOVE 0                   TO DP-ZEROS-1
           MOVE CT-EMPRESA-CONTA    TO DP-CONTA
           MOVE SPACES              TO DP-BRANCO-3
           MOVE CT-EMPRESA-DAC      TO DP-DAC-AG-CONTA
           MOVE CT-NUM-CARTEIRA     TO DP-NUM-CARTEIRA
           MOVE CP-NOSSO-NUMERO     TO DP-NOSSO-NUMERO
           MOVE 0                   TO DP-DAC-NOSSO-NUMERO
           MOVE SPACES              TO DP-BRANCOS-1
           MOVE 0                   TO DP-ZEROS-2
           MOVE CP-NUM-DOCUMENTO    TO DP-NUM-DOCUMENTO
           MOVE SPACES              TO DP-BRANCOS-2
           MOVE WS-VENC-DDMMAAAA    TO DP-VENCIMENTO
           MOVE CP-VALOR-TITULO     TO DP-VALOR-TITULO
           MOVE CT-EMPRESA-AGENCIA  TO DP-AGENCIA-COBRADORA
           MOVE 0                   TO DP-DAC-AG-COBRADORA
           MOVE 2                   TO DP-ESPECIE-TITULO
           MOVE "N"                 TO DP-ACEITE
           MOVE WS-HOJE-DDMMAAAA    TO DP-DATA-EMISSAO
           MOVE 0                   TO DP-ZERO-2
           MOVE 0                   TO DP-DATA-JUROS-MORA
           MOVE 0                   TO DP-JUROS-1-DIA
           MOVE 0                   TO DP-ZERO-3
           MOVE 0                   TO DP-DATA-1-DESC
           MOVE 0                   TO DP-VALOR-1-DESC
           MOVE 0                   TO DP-VALOR-IOF
           MOVE 0                   TO DP-VALOR-ABATIMENTO
           MOVE CP-NUM-DOCUMENTO    TO DP-USO-EMPRESA
           MOVE 3                   TO DP-COD-PROTESTO
           MOVE 0                   TO DP-PRAZO-PROTESTO
           MOVE 1                   TO DP-COD-BAIXA
           MOVE 60                  TO DP-PRAZO-BAIXA
           MOVE 0                   TO DP-ZEROS-3
           MOVE SPACES              TO DP-BRANCO-4
           WRITE FD-REMESSA-REC FROM WS-DET-P
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

       540-GRAVAR-SEGMENTO-Q.
           ADD 1 TO WS-NUM-REGISTRO-LOTE
           MOVE SPACES              TO WS-DET-Q
           MOVE CT-CODIGO-BANCO     TO DQ-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO DQ-CODIGO-LOTE
           MOVE CT-TIPO-DETALHE     TO DQ-TIPO-REGISTRO
           MOVE WS-NUM-REGISTRO-LOTE TO DQ-NUM-REGISTRO
           MOVE "Q"                 TO DQ-SEGMENTO
           MOVE SPACES              TO DQ-BRANCO-1
           MOVE CT-OCOR-ENTRADA-TITULO TO DQ-COD-OCORRENCIA
           MOVE CP-TIPO-INSCRICAO-PAG TO DQ-CODIGO-INSCRICAO
           MOVE CP-CPF-CNPJ-PAGADOR TO DQ-NUM-INSCRICAO
           MOVE CP-NOME-PAGADOR     TO DQ-NOME-PAGADOR
           MOVE SPACES              TO DQ-BRANCOS-1
           MOVE CP-LOGRADOURO-PAGADOR TO DQ-LOGRADOURO
           MOVE CP-BAIRRO-PAGADOR   TO DQ-BAIRRO
           MOVE CP-CEP-PAGADOR(1:5) TO DQ-CEP
           MOVE CP-CEP-PAGADOR(6:3) TO DQ-SUFIXO-CEP
           MOVE CP-CIDADE-PAGADOR   TO DQ-CIDADE
           MOVE CP-UF-PAGADOR       TO DQ-UF
           MOVE 0                   TO DQ-COD-INSCRICAO-SAC
           MOVE 0                   TO DQ-NUM-INSCRICAO-SAC
           MOVE SPACES              TO DQ-NOME-SACADOR-AVALISTA
           MOVE SPACES              TO DQ-BRANCOS-2
           MOVE 0                   TO DQ-ZEROS-1
           MOVE SPACES              TO DQ-BRANCOS-3
           WRITE FD-REMESSA-REC FROM WS-DET-Q
           ADD 1 TO WS-TOTAL-REGISTROS-ARQ.

       550-GRAVAR-STATUS-INICIAL.
      * TS-VENCIMENTO permanece em AAAAMMDD (contrato do copybook).
           MOVE SPACES              TO WS-TITULO-STATUS
           MOVE CP-NOSSO-NUMERO     TO TS-NOSSO-NUMERO
           MOVE CP-NOME-PAGADOR     TO TS-NOME-PAGADOR
           MOVE CP-VENCIMENTO       TO TS-VENCIMENTO
           MOVE CP-VALOR-TITULO     TO TS-VALOR-TITULO
           MOVE "PENDENTE"          TO TS-STATUS
           MOVE 0                   TO TS-DATA-OCORRENCIA
           MOVE 0                   TO TS-VALOR-PAGO
           MOVE SPACES              TO TS-MOTIVO-REJEICAO
           WRITE FD-STATUS-REC FROM WS-TITULO-STATUS.

       600-GERAR-TRAILERS.
      * ---- Trailer de Lote (tipo 5) ----
           MOVE SPACES              TO WS-TRL-LOTE
           MOVE CT-CODIGO-BANCO     TO TL-CODIGO-BANCO
           MOVE CT-CODIGO-LOTE      TO TL-CODIGO-LOTE
           MOVE CT-TIPO-TRL-LOTE    TO TL-TIPO-REGISTRO
           MOVE SPACES              TO TL-BRANCOS-1
      * quantidade de registros do lote = header(1) + 2 por titulo
      *                                 + trailer(1)
           COMPUTE TL-QTDE-REGISTROS =
               2 + (WS-QTDE-TITULOS * 2)
           MOVE WS-QTDE-TITULOS     TO TL-QTDE-COBR-SIMPLES
           MOVE WS-VALOR-TOTAL      TO TL-VLR-COBR-SIMPLES
           MOVE 0                   TO TL-QTDE-COBR-VINCULADA
           MOVE 0                   TO TL-VLR-COBR-VINCULADA
           MOVE ALL "0"             TO TL-ZEROS-1
           MOVE SPACES              TO TL-AVISO-BANCARIO
           MOVE SPACES              TO TL-BRANCOS-2
           WRITE FD-REMESSA-REC FROM WS-TRL-LOTE
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
           WRITE FD-REMESSA-REC FROM WS-TRL-ARQUIVO.

       900-FECHAR-ARQUIVOS.
           CLOSE F-COBRANCAS
           CLOSE F-REMESSA
           CLOSE F-STATUS.

       950-ENCERRAR.
           DISPLAY "GERAREM: " WS-QTDE-LIDAS " registro(s) lido(s), "
               WS-QTDE-TITULOS " titulo(s) na remessa, "
               WS-QTDE-DESCARTADAS " descartado(s)."
           DISPLAY "GERAREM: valor total da remessa: " WS-VALOR-TOTAL

           EVALUATE TRUE
               WHEN WS-QTDE-LIDAS = 0
                   DISPLAY "GERAREM: ERRO - arquivo de cobrancas "
                       "pendentes esta vazio. Nenhuma remessa util "
                       "foi gerada."
                   MOVE 8 TO RETURN-CODE
               WHEN WS-QTDE-TITULOS = 0
                   DISPLAY "GERAREM: ERRO - todos os registros foram "
                       "descartados pela critica. Nenhuma remessa "
                       "util foi gerada."
                   MOVE 8 TO RETURN-CODE
               WHEN WS-QTDE-DESCARTADAS > 0
                   DISPLAY "GERAREM: ATENCAO - remessa gerada com "
                       "titulos descartados. Verifique os avisos "
                       "acima."
                   MOVE 4 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.
