      *****************************************************************
      * COPYBOOK: CNAB240-DET-U
      * Registro Detalhe - Segmento U (Retorno, obrigatorio) - Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 15
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-DET-U.
           05 DU-CODIGO-BANCO           PIC 9(03).
           05 DU-CODIGO-LOTE            PIC 9(04).
           05 DU-TIPO-REGISTRO          PIC 9(01).
           05 DU-NUM-REGISTRO           PIC 9(05).
           05 DU-SEGMENTO               PIC X(01).
           05 DU-BRANCO-1               PIC X(01).
           05 DU-COD-OCORRENCIA         PIC 9(02).
           05 DU-JUROS-MULTA            PIC 9(13)V9(02).
           05 DU-VALOR-DESCONTO         PIC 9(13)V9(02).
           05 DU-VALOR-ABATIMENTO       PIC 9(13)V9(02).
           05 DU-VALOR-IOF              PIC 9(13)V9(02).
           05 DU-VALOR-PAGO             PIC 9(13)V9(02).
           05 DU-VALOR-LIQUIDO          PIC 9(13)V9(02).
           05 DU-ZEROS-1                PIC 9(30).
           05 DU-DATA-OCORRENCIA        PIC 9(08).
           05 DU-DATA-CREDITO           PIC 9(08).
           05 DU-COD-OCORRENCIA-PAG     PIC 9(04).
           05 DU-DATA-OCORRENCIA-PAG    PIC 9(08).
           05 DU-VALOR-OCORRENCIA-PAG   PIC 9(13)V9(02).
           05 DU-BRANCOS-1              PIC X(30).
           05 DU-ZEROS-2                PIC 9(23).
           05 DU-BRANCOS-2              PIC X(07).
