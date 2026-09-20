      *****************************************************************
      * COPYBOOK: CNAB240-TRL-ARQ
      * Registro Trailer de Arquivo - CNAB 240 - Banco Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 16
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-TRL-ARQUIVO.
           05 TA-CODIGO-BANCO           PIC 9(03).
           05 TA-CODIGO-LOTE            PIC 9(04).
           05 TA-TIPO-REGISTRO          PIC 9(01).
           05 TA-BRANCOS-1              PIC X(09).
           05 TA-TOTAL-LOTES            PIC 9(06).
           05 TA-TOTAL-REGISTROS        PIC 9(06).
           05 TA-ZEROS-1                PIC 9(06).
           05 TA-BRANCOS-2              PIC X(205).
