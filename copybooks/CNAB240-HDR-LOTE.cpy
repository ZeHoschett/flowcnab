      *****************************************************************
      * COPYBOOK: CNAB240-HDR-LOTE
      * Registro Header de Lote - CNAB 240 - Banco Itau (341)
      * Fonte: cobranca_cnab240.pdf (manual Itau), pag. 8
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-HDR-LOTE.
           05 HL-CODIGO-BANCO           PIC 9(03).
           05 HL-CODIGO-LOTE            PIC 9(04).
           05 HL-TIPO-REGISTRO          PIC 9(01).
           05 HL-OPERACAO               PIC X(01).
           05 HL-CODIGO-SERVICO         PIC 9(02).
           05 HL-ZEROS-1                PIC 9(02).
           05 HL-LAYOUT-LOTE            PIC 9(03).
           05 HL-BRANCO-1               PIC X(01).
           05 HL-CODIGO-INSCRICAO       PIC 9(01).
           05 HL-NUM-INSCRICAO          PIC 9(15).
           05 HL-BRANCOS-1              PIC X(20).
           05 HL-ZERO-1                 PIC 9(01).
           05 HL-AGENCIA                PIC 9(04).
           05 HL-BRANCO-2               PIC X(01).
           05 HL-ZEROS-2                PIC 9(07).
           05 HL-CONTA                  PIC 9(05).
           05 HL-BRANCO-3               PIC X(01).
           05 HL-DAC-AG-CONTA           PIC 9(01).
           05 HL-NOME-EMPRESA           PIC X(30).
           05 HL-BRANCOS-2              PIC X(80).
           05 HL-NUM-SEQ-ARQ-RETORNO    PIC 9(08).
           05 HL-DATA-GRAVACAO          PIC 9(08).
           05 HL-DATA-CREDITO           PIC 9(08).
           05 HL-BRANCOS-3              PIC X(33).
