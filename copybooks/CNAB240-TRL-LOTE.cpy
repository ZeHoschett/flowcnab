      *****************************************************************
      * COPYBOOK: CNAB240-TRL-LOTE
      * Registro Trailer de Lote - CNAB 240 - Banco Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 16
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-TRL-LOTE.
           05 TL-CODIGO-BANCO           PIC 9(03).
           05 TL-CODIGO-LOTE            PIC 9(04).
           05 TL-TIPO-REGISTRO          PIC 9(01).
           05 TL-BRANCOS-1              PIC X(09).
           05 TL-QTDE-REGISTROS         PIC 9(06).
           05 TL-QTDE-COBR-SIMPLES      PIC 9(06).
           05 TL-VLR-COBR-SIMPLES       PIC 9(15)V9(02).
           05 TL-QTDE-COBR-VINCULADA    PIC 9(06).
           05 TL-VLR-COBR-VINCULADA     PIC 9(15)V9(02).
           05 TL-ZEROS-1                PIC X(46).
           05 TL-AVISO-BANCARIO         PIC X(08).
           05 TL-BRANCOS-2              PIC X(117).
