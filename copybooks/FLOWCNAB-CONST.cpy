      *****************************************************************
      * COPYBOOK: FLOWCNAB-CONST
      * Constantes compartilhadas pelos tres programas do FLOWCNAB.
      * Centraliza o que antes estava duplicado em GERAREM, SIMBANCO e
      * PROCRET (codigo do banco, dados da empresa, codigos de layout).
      *
      * Sao constantes de compilacao (nivel 78): nao ocupam memoria e
      * nao podem ser alteradas em tempo de execucao.
      *
      * ESCOPO v1: um unico banco (Itau 341) e uma unica empresa. Este
      * copybook e o ponto unico a mudar caso um dia entre outro banco
      * ou outra empresa - nenhum dos tres .cbl carrega esses valores.
      *****************************************************************

      * ---- Banco / layout CNAB 240 (Itau 341) ----
       78  CT-CODIGO-BANCO              VALUE 341.
       78  CT-NOME-BANCO                VALUE "BANCO ITAU SA".
       78  CT-LAYOUT-ARQUIVO            VALUE 40.
       78  CT-LAYOUT-LOTE               VALUE 30.
       78  CT-NUM-CARTEIRA              VALUE 109.
       78  CT-CODIGO-LOTE               VALUE 1.
       78  CT-CODIGO-LOTE-TRAILER       VALUE 9999.
       78  CT-CODIGO-SERVICO            VALUE 1.

      * ---- Tipos de registro CNAB 240 ----
       78  CT-TIPO-HDR-ARQUIVO          VALUE 0.
       78  CT-TIPO-HDR-LOTE             VALUE 1.
       78  CT-TIPO-DETALHE              VALUE 3.
       78  CT-TIPO-TRL-LOTE             VALUE 5.
       78  CT-TIPO-TRL-ARQUIVO          VALUE 9.

      * ---- Codigo do arquivo (header de arquivo, pos. 143) ----
       78  CT-ARQUIVO-REMESSA           VALUE 1.
       78  CT-ARQUIVO-RETORNO           VALUE 2.

      * ---- Codigos de ocorrencia usados no projeto ----
       78  CT-OCOR-ENTRADA-TITULO       VALUE 01.
       78  CT-OCOR-ENTRADA-REJEITADA    VALUE 03.
       78  CT-OCOR-LIQUIDACAO           VALUE 06.

      * ---- Empresa cedente ----
       78  CT-EMPRESA-NOME VALUE "FLOWCNAB TREINAMENTO LTDA".
       78  CT-EMPRESA-CNPJ              VALUE 12345678000199.
       78  CT-EMPRESA-AGENCIA           VALUE 1234.
       78  CT-EMPRESA-CONTA             VALUE 56789.
       78  CT-EMPRESA-DAC               VALUE 0.
       78  CT-EMPRESA-TIPO-INSCRICAO    VALUE 2.

      * ---- Limites operacionais ----
      * Capacidade da tabela em memoria do PROCRET e do controle de
      * nosso-numero duplicado do GERAREM. Os dois DEVEM usar o mesmo
      * valor, senao o GERAREM aceita remessas que o PROCRET nao
      * consegue conciliar.
       78  CT-MAX-TITULOS               VALUE 500.

      * ---- Dias de atraso simulados pelo SIMBANCO ----
       78  CT-DIAS-ATRASO-SIMULADO      VALUE 11.
