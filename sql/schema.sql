-- ============================================================
-- FLOWCNAB - esquema alternativo em PostgreSQL
--
-- A v1 deste projeto usa arquivos texto de largura fixa para as
-- cobrancas pendentes e para o controle de status dos titulos
-- (ver README.md, secao "Decisoes de simplificacao"). Este schema
-- fica documentado aqui como o caminho de evolucao natural: trocar
-- os arquivos por tabelas relacionais acessadas via EXEC SQL com
-- OCESQL, o que da pratica adicional de acesso a banco em COBOL.
--
-- Equivalencias com os copybooks (v1 em arquivo):
--   - valores de titulo_status usam NUMERIC(15,2) porque o copybook
--     TITULO-STATUS guarda PIC 9(13)V9(02), a mesma precisao dos
--     campos de valor do CNAB 240;
--   - as datas viram DATE, o que dispensa o contrato AAAAMMDD x
--     DDMMAAAA descrito no README: a conversao para o formato do
--     CNAB passaria a ser feita so na formatacao do registro;
--   - o PRIMARY KEY em nosso_numero da de graca a critica de
--     duplicidade que o GERAREM hoje faz em memoria.
-- ============================================================

CREATE TABLE cobranca_pendente (
    nosso_numero       CHAR(8)  PRIMARY KEY,
    tipo_inscricao_pag CHAR(1)  NOT NULL,
    cpf_cnpj_pagador   CHAR(15) NOT NULL,
    nome_pagador       VARCHAR(30) NOT NULL,
    logradouro_pagador VARCHAR(40) NOT NULL,
    bairro_pagador     VARCHAR(15) NOT NULL,
    cep_pagador        CHAR(8)  NOT NULL,
    cidade_pagador     VARCHAR(15) NOT NULL,
    uf_pagador         CHAR(2)  NOT NULL,
    vencimento         DATE     NOT NULL,
    valor_titulo       NUMERIC(13,2) NOT NULL CHECK (valor_titulo > 0),
    num_documento      VARCHAR(10) NOT NULL,
    criado_em          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE titulo_status (
    nosso_numero       CHAR(8)  PRIMARY KEY,
    nome_pagador       VARCHAR(30) NOT NULL,
    vencimento         DATE     NOT NULL,
    valor_titulo       NUMERIC(15,2) NOT NULL,
    status             VARCHAR(16) NOT NULL DEFAULT 'PENDENTE',
        -- dominio: PENDENTE | PAGO | PAGO COM ATRASO | REJEITADO
    data_ocorrencia    DATE,
    valor_pago         NUMERIC(15,2) NOT NULL DEFAULT 0,
    motivo_rejeicao    VARCHAR(30),
    atualizado_em      TIMESTAMP DEFAULT NOW()
);

-- Script de carga de exemplo (equivalente ao gerador de teste em
-- scripts/gerar_cobrancas_teste.py), caso a opcao por banco relacional
-- seja adotada em uma proxima iteracao do projeto:
--
-- INSERT INTO cobranca_pendente
--   (nosso_numero, tipo_inscricao_pag, cpf_cnpj_pagador, nome_pagador,
--    logradouro_pagador, bairro_pagador, cep_pagador, cidade_pagador,
--    uf_pagador, vencimento, valor_titulo, num_documento)
-- VALUES
--   ('10000001','1','12345678901000','JOAO DA SILVA SANTOS',
--    'RUA DOS TESTES, 123','CENTRO','01310100','SAO PAULO','SP',
--    '2026-09-20', 1500.00, 'NF1000');
--
-- Em COBOL, o acesso a esta tabela seria feito com OCESQL, por exemplo:
--   EXEC SQL
--       SELECT nosso_numero, cpf_cnpj_pagador, nome_pagador, ...
--         INTO :WS-NOSSO-NUMERO, :WS-CPF-CNPJ, :WS-NOME, ...
--         FROM cobranca_pendente
--        WHERE nosso_numero = :WS-CHAVE
--   END-EXEC.
