      *****************************************************************
      * COPYBOOK: COBRANCA-PENDENTE
      * Registro proprio (nao-CNAB) da "tabela" de cobrancas pendentes
      * que alimenta a geracao da remessa. Em producao seria uma tabela
      * relacional (ver sql/schema.sql); aqui e um arquivo texto de
      * largura fixa para manter o programa simples e 100% GnuCOBOL.
      * Tamanho fixo: 165 posicoes
      *
      * CONTRATO DE DATA: CP-VENCIMENTO esta em AAAAMMDD.
      * Os arquivos internos do FLOWCNAB (este e TITULO-STATUS) usam
      * AAAAMMDD porque nesse formato a ordem alfabetica e a ordem
      * cronologica coincidem, o que permite comparar datas
      * numericamente sem conversao. O layout CNAB 240 do Itau exige
      * DDMMAAAA; a conversao acontece SOMENTE na fronteira CNAB
      * (GERAREM ao gravar o segmento P, PROCRET ao ler o segmento U).
      *****************************************************************
       01  WS-COBRANCA-PENDENTE.
           05 CP-NOSSO-NUMERO           PIC 9(08).
           05 CP-TIPO-INSCRICAO-PAG     PIC 9(01).
           05 CP-CPF-CNPJ-PAGADOR       PIC 9(15).
           05 CP-NOME-PAGADOR           PIC X(30).
           05 CP-LOGRADOURO-PAGADOR     PIC X(40).
           05 CP-BAIRRO-PAGADOR         PIC X(15).
           05 CP-CEP-PAGADOR            PIC 9(08).
           05 CP-CIDADE-PAGADOR         PIC X(15).
           05 CP-UF-PAGADOR             PIC X(02).
           05 CP-VENCIMENTO             PIC 9(08).
           05 CP-VALOR-TITULO           PIC 9(11)V9(02).
           05 CP-NUM-DOCUMENTO          PIC X(10).
