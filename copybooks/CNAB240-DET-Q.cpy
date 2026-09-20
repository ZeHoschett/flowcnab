      *****************************************************************
      * COPYBOOK: CNAB240-DET-Q
      * Registro Detalhe - Segmento Q (Remessa, obrigatorio) - Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 10
      * Tamanho fixo: 240 posicoes
      *
      * LIMITACAO CONHECIDA: o layout reserva 40 posicoes para o nome
      * do pagador (34-73) e 40 para o sacador avalista (170-209).
      * Aqui cada um e X(30) seguido de X(10) em branco - o
      * alinhamento das posicoes seguintes fica correto, mas nomes
      * com mais de 30 caracteres sao truncados. O limite nasce de
      * CP-NOME-PAGADOR em COBRANCA-PENDENTE, tambem X(30).
      *****************************************************************
       01  WS-DET-Q.
           05 DQ-CODIGO-BANCO           PIC 9(03).
           05 DQ-CODIGO-LOTE            PIC 9(04).
           05 DQ-TIPO-REGISTRO          PIC 9(01).
           05 DQ-NUM-REGISTRO           PIC 9(05).
           05 DQ-SEGMENTO               PIC X(01).
           05 DQ-BRANCO-1               PIC X(01).
           05 DQ-COD-OCORRENCIA         PIC 9(02).
           05 DQ-CODIGO-INSCRICAO       PIC 9(01).
           05 DQ-NUM-INSCRICAO          PIC 9(15).
           05 DQ-NOME-PAGADOR           PIC X(30).
           05 DQ-BRANCOS-1              PIC X(10).
           05 DQ-LOGRADOURO             PIC X(40).
           05 DQ-BAIRRO                 PIC X(15).
           05 DQ-CEP                    PIC 9(05).
           05 DQ-SUFIXO-CEP             PIC 9(03).
           05 DQ-CIDADE                 PIC X(15).
           05 DQ-UF                     PIC X(02).
           05 DQ-COD-INSCRICAO-SAC      PIC 9(01).
           05 DQ-NUM-INSCRICAO-SAC      PIC 9(15).
           05 DQ-NOME-SACADOR-AVALISTA  PIC X(30).
           05 DQ-BRANCOS-2              PIC X(10).
           05 DQ-ZEROS-1                PIC 9(03).
           05 DQ-BRANCOS-3              PIC X(28).
