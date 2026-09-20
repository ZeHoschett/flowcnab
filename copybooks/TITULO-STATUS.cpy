      *****************************************************************
      * COPYBOOK: TITULO-STATUS
      * Registro de controle do titulo ao longo do ciclo de vida
      * (arquivo indexado por NOSSO NUMERO). Criado pela geracao de
      * remessa com status "PENDENTE" e atualizado pelo processamento
      * de retorno para "PAGO", "PAGO COM ATRASO" ou "REJEITADO".
      *
      * Os valores usam 9(13)V9(02), a MESMA precisao dos campos de
      * valor do CNAB 240 (segmentos P/T/U). Com 9(11)V9(02) um valor
      * vindo do retorno perdia digitos de alta ordem em silencio.
      * Tamanho fixo: 130 posicoes
      *
      * CONTRATO DE DATA: TS-VENCIMENTO e TS-DATA-OCORRENCIA estao em
      * AAAAMMDD (mesmo criterio de COBRANCA-PENDENTE). O PROCRET
      * converte a data de ocorrencia de DDMMAAAA (como vem do
      * segmento U) para AAAAMMDD antes de gravar aqui.
      *****************************************************************
       01  WS-TITULO-STATUS.
           05 TS-NOSSO-NUMERO           PIC 9(08).
           05 TS-NOME-PAGADOR           PIC X(30).
           05 TS-VENCIMENTO             PIC 9(08).
           05 TS-VALOR-TITULO           PIC 9(13)V9(02).
           05 TS-STATUS                 PIC X(16).
           05 TS-DATA-OCORRENCIA        PIC 9(08).
           05 TS-VALOR-PAGO             PIC 9(13)V9(02).
           05 TS-MOTIVO-REJEICAO        PIC X(30).
