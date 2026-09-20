      *****************************************************************
      * COPYBOOK: CNAB240-DET-T
      * Registro Detalhe - Segmento T (Retorno, obrigatorio) - Itau (341)
      * Fonte: cobranca_cnab240.pdf, pag. 14
      * Tamanho fixo: 240 posicoes
      *
      * PENDENTE DE CONFERENCIA POSICIONAL (pos. 189 a 240).
      * As posicoes 1-188 conferem com o padrao FEBRABAN. Da 189 em
      * diante este copybook divergiu ao ser escrito sem o manual:
      *
      *   posicao | aqui                | FEBRABAN generico
      *   189-198 | DT-ZEROS-4          | brancos
      *   199-213 | DT-TARIFAS-CUSTAS   | 199-208 num. do contrato
      *           |                     | 209-223 valor da tarifa
      *   214-221 | DT-ERROS            | (dentro do valor da tarifa)
      *   224-233 | brancos             | motivos de ocorrencia
      *
      * O FLOWCNAB e internamente consistente (SIMBANCO grava e
      * PROCRET le ESTE copybook), entao o fluxo fecha nos testes.
      * Um retorno de banco de verdade, nao. Conferir contra o manual
      * do Itau antes de apontar o PROCRET para um arquivo real - ver
      * o item de divida tecnica no CLAUDE.md sobre check_len.py
      * validar a soma dos PICs e nao as posicoes.
      *****************************************************************
       01  WS-DET-T.
           05 DT-CODIGO-BANCO           PIC 9(03).
           05 DT-CODIGO-LOTE            PIC 9(04).
           05 DT-TIPO-REGISTRO          PIC 9(01).
           05 DT-NUM-REGISTRO           PIC 9(05).
           05 DT-SEGMENTO               PIC X(01).
           05 DT-BOLETO-DDA             PIC X(01).
           05 DT-COD-OCORRENCIA         PIC 9(02).
           05 DT-ZERO-1                 PIC 9(01).
           05 DT-AGENCIA                PIC 9(04).
           05 DT-ZEROS-1                PIC 9(08).
           05 DT-CONTA                  PIC 9(05).
           05 DT-ZERO-2                 PIC 9(01).
           05 DT-DAC-AG-CONTA           PIC 9(01).
           05 DT-NUM-CARTEIRA           PIC 9(03).
           05 DT-NOSSO-NUMERO           PIC 9(08).
           05 DT-DAC-NOSSO-NUMERO       PIC 9(01).
           05 DT-BRANCOS-1              PIC X(08).
           05 DT-ZERO-3                 PIC 9(01).
           05 DT-SEU-NUMERO             PIC X(10).
           05 DT-BRANCOS-2              PIC X(05).
           05 DT-VENCIMENTO             PIC 9(08).
           05 DT-VALOR-TITULO           PIC 9(13)V9(02).
           05 DT-ZEROS-2                PIC 9(03).
           05 DT-AGENCIA-COBRADORA      PIC 9(05).
           05 DT-DAC-AG-COBRADORA       PIC 9(01).
           05 DT-USO-EMPRESA            PIC X(25).
           05 DT-ZEROS-3                PIC 9(02).
           05 DT-COD-INSCRICAO-PAG      PIC 9(01).
           05 DT-NUM-INSCRICAO-PAG      PIC 9(15).
           05 DT-NOME-PAGADOR           PIC X(30).
           05 DT-BRANCOS-3              PIC X(10).
           05 DT-ZEROS-4                PIC 9(10).
           05 DT-TARIFAS-CUSTAS         PIC 9(13)V9(02).
           05 DT-ERROS                  PIC 9(08).
           05 DT-COD-LIQUIDACAO         PIC X(02).
           05 DT-BRANCOS-4              PIC X(17).
