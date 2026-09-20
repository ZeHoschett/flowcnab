#!/usr/bin/env python3
"""Gera um arquivo de cobrancas pendentes de teste para alimentar o
GERAREM, no layout fixo COBRANCA-PENDENTE (165 posicoes).

Contratos que este gerador precisa respeitar (ver
copybooks/COBRANCA-PENDENTE.cpy):
  - vencimento em AAAAMMDD (nao DDMMAAAA - a conversao para o formato
    do CNAB 240 e feita pelo GERAREM);
  - valor do titulo em CENTAVOS, 13 digitos, sem ponto decimal
    (PIC 9(11)V9(02));
  - nosso numero unico dentro do arquivo (o GERAREM descarta
    duplicatas);
  - linha com exatamente 165 caracteres.

Uso:
    python3 scripts/gerar_cobrancas_teste.py [quantidade]
"""
import os
import random
import sys

TAMANHO_REGISTRO = 165
ARQUIVO_SAIDA = "dados/cobrancas_pendentes.txt"

nomes = [
    "JOAO DA SILVA SANTOS", "MARIA OLIVEIRA COSTA", "CARLOS EDUARDO LIMA",
    "ANA PAULA FERREIRA", "PEDRO HENRIQUE ALVES", "JULIANA SOUZA ROCHA",
    "RICARDO ALMEIDA DIAS", "FERNANDA GOMES PINTO", "LUCAS MARTINS REIS",
    "PATRICIA NUNES BRITO", "BRUNO CARDOSO TEIXEIRA", "CAMILA BARBOSA MOURA",
]
cidades = [("SAO PAULO", "SP"), ("CAMPINAS", "SP"), ("RIO DE JANEIRO", "RJ"),
           ("BELO HORIZONTE", "MG"), ("CURITIBA", "PR"), ("PORTO ALEGRE", "RS")]


def rec(nosso_numero, nome, cidade, uf, venc_aaaammdd, valor_centavos, doc):
    tipo_insc = "1"
    cpf = f"{random.randint(1, 99999999999):011d}" + "0000"
    endereco = f"RUA DOS TESTES, {random.randint(1, 999)}"
    bairro = "CENTRO"
    cep = f"{random.randint(1000000, 9999999):08d}"
    line = (
        f"{nosso_numero:08d}"
        f"{tipo_insc}"
        f"{cpf:0>15}"
        f"{nome:<30.30}"
        f"{endereco:<40.40}"
        f"{bairro:<15.15}"
        f"{cep:0>8}"
        f"{cidade:<15.15}"
        f"{uf:<2.2}"
        f"{venc_aaaammdd}"
        f"{valor_centavos:013d}"
        f"{doc:<10.10}"
    )
    assert len(line) == TAMANHO_REGISTRO, (
        f"registro com {len(line)} posicoes, esperado {TAMANHO_REGISTRO}")
    return line


def main(quantidade=20):
    random.seed(42)
    linhas = []
    base_nosso_numero = 10000001
    # AAAAMMDD - ver docstring
    datas = ["20260920", "20260922", "20260925", "20260930"]
    for i in range(quantidade):
        nome = random.choice(nomes)
        cidade, uf = random.choice(cidades)
        venc = random.choice(datas)
        # centavos: de R$ 50,00 a R$ 3.500,00
        valor_centavos = random.randint(5000, 350000)
        doc = f"NF{1000 + i}"
        linhas.append(rec(base_nosso_numero + i, nome, cidade, uf, venc,
                          valor_centavos, doc))

    os.makedirs(os.path.dirname(ARQUIVO_SAIDA), exist_ok=True)
    with open(ARQUIVO_SAIDA, "w", newline="\n") as f:
        f.write("\n".join(linhas) + "\n")
    print(f"Gerado {ARQUIVO_SAIDA} com {len(linhas)} cobrancas")


if __name__ == "__main__":
    main(int(sys.argv[1]) if len(sys.argv) > 1 else 20)
