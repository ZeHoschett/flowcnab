      *****************************************************************
      * COPYBOOK: CNAB240-HDR-ARQ
      * Registro Header de Arquivo - CNAB 240 - Banco Itau (341)
      * Fonte: cobranca_cnab240.pdf (manual Itau), pag. 7
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-HDR-ARQUIVO.
           05 HA-CODIGO-BANCO           PIC 9(03).
           05 HA-CODIGO-LOTE            PIC 9(04).
           05 HA-TIPO-REGISTRO          PIC 9(01).
           05 HA-BRANCOS-1              PIC X(09).
           05 HA-TIPO-INSCRICAO         PIC 9(01).
           05 HA-NUM-INSCRICAO          PIC 9(14).
           05 HA-BRANCOS-2              PIC X(20).
           05 HA-ZERO-1                 PIC 9(01).
           05 HA-AGENCIA                PIC 9(04).
           05 HA-BRANCOS-3              PIC X(01).
           05 HA-ZEROS-2                PIC 9(07).
           05 HA-CONTA                  PIC 9(05).
           05 HA-BRANCOS-4              PIC X(01).
           05 HA-DAC-AG-CONTA           PIC 9(01).
           05 HA-NOME-EMPRESA           PIC X(30).
           05 HA-NOME-BANCO             PIC X(30).
           05 HA-BRANCOS-5              PIC X(10).
           05 HA-CODIGO-ARQUIVO         PIC 9(01).
           05 HA-DATA-GERACAO           PIC 9(08).
           05 HA-HORA-GERACAO           PIC 9(06).
           05 HA-NUM-SEQ-ARQUIVO        PIC 9(06).
           05 HA-LAYOUT-ARQUIVO         PIC 9(03).
           05 HA-ZEROS-3                PIC 9(05).
           05 HA-BRANCOS-6              PIC X(54).
           05 HA-ZEROS-4                PIC 9(03).
           05 HA-BRANCOS-7              PIC X(12).
