      *****************************************************************
      * COPYBOOK: CNAB240-DET-P
      * Registro Detalhe - Segmento P (Remessa, obrigatorio) - Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 9
      * Tamanho fixo: 240 posicoes
      *****************************************************************
       01  WS-DET-P.
           05 DP-CODIGO-BANCO           PIC 9(03).
           05 DP-CODIGO-LOTE            PIC 9(04).
           05 DP-TIPO-REGISTRO          PIC 9(01).
           05 DP-NUM-REGISTRO           PIC 9(05).
           05 DP-SEGMENTO               PIC X(01).
           05 DP-BRANCO-1               PIC X(01).
           05 DP-COD-OCORRENCIA         PIC 9(02).
           05 DP-ZERO-1                 PIC 9(01).
           05 DP-AGENCIA                PIC 9(04).
           05 DP-BRANCO-2               PIC X(01).
           05 DP-ZEROS-1                PIC 9(07).
           05 DP-CONTA                  PIC 9(05).
           05 DP-BRANCO-3               PIC X(01).
           05 DP-DAC-AG-CONTA           PIC 9(01).
           05 DP-NUM-CARTEIRA           PIC 9(03).
           05 DP-NOSSO-NUMERO           PIC 9(08).
           05 DP-DAC-NOSSO-NUMERO       PIC 9(01).
           05 DP-BRANCOS-1              PIC X(08).
           05 DP-ZEROS-2                PIC 9(05).
           05 DP-NUM-DOCUMENTO          PIC X(10).
           05 DP-BRANCOS-2              PIC X(05).
           05 DP-VENCIMENTO             PIC 9(08).
           05 DP-VALOR-TITULO           PIC 9(13)V9(02).
           05 DP-AGENCIA-COBRADORA      PIC 9(05).
           05 DP-DAC-AG-COBRADORA       PIC 9(01).
           05 DP-ESPECIE-TITULO         PIC 9(02).
           05 DP-ACEITE                 PIC X(01).
           05 DP-DATA-EMISSAO           PIC 9(08).
           05 DP-ZERO-2                 PIC 9(01).
           05 DP-DATA-JUROS-MORA        PIC 9(08).
           05 DP-JUROS-1-DIA            PIC 9(13)V9(02).
           05 DP-ZERO-3                 PIC 9(01).
           05 DP-DATA-1-DESC            PIC 9(08).
           05 DP-VALOR-1-DESC           PIC 9(13)V9(02).
           05 DP-VALOR-IOF              PIC 9(13)V9(02).
           05 DP-VALOR-ABATIMENTO       PIC 9(13)V9(02).
           05 DP-USO-EMPRESA            PIC X(25).
           05 DP-COD-PROTESTO           PIC 9(01).
           05 DP-PRAZO-PROTESTO         PIC 9(02).
           05 DP-COD-BAIXA              PIC 9(01).
           05 DP-PRAZO-BAIXA            PIC 9(02).
           05 DP-ZEROS-3                PIC 9(13).
           05 DP-BRANCO-4               PIC X(01).
