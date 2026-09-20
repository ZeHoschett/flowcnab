#!/usr/bin/env python3
"""Valida o tamanho fixo dos copybooks do FLOWCNAB.

Soma o tamanho de todas as clausulas PIC de um copybook e compara com
o tamanho esperado para aquele registro. Registros CNAB 240 precisam
ter exatamente 240 posicoes; os registros proprios do projeto tem os
tamanhos declarados em TAMANHOS_ESPERADOS.

Sai com codigo 1 se qualquer copybook divergir, para poder ser usado
como porta de CI / pre-commit.

Uso:
    python3 scripts/check_len.py copybooks/*.cpy
"""
import glob
import os
import re
import sys

# Tamanho esperado por copybook. Um copybook novo que nao esteja aqui
# e reportado como desconhecido (e falha), para ninguem esquecer de
# registrar o contrato de tamanho.
TAMANHOS_ESPERADOS = {
    "CNAB240-HDR-ARQ": 240,
    "CNAB240-HDR-LOTE": 240,
    "CNAB240-DET-P": 240,
    "CNAB240-DET-Q": 240,
    "CNAB240-DET-T": 240,
    "CNAB240-DET-U": 240,
    "CNAB240-TRL-LOTE": 240,
    "CNAB240-TRL-ARQ": 240,
    "COBRANCA-PENDENTE": 165,
    "TITULO-STATUS": 130,
    # Constantes de compilacao (nivel 78) nao ocupam posicao nenhuma.
    "FLOWCNAB-CONST": 0,
}


def pic_len(pic):
    """Soma o tamanho de uma clausula PIC: X(30), 9(03), 9(13)V9(02)..."""
    total = 0
    for m in re.finditer(r"([9XV])(?:\((\d+)\))?", pic):
        ch, n = m.group(1), m.group(2)
        if ch == "V":
            # V e ponto decimal implicito: nao ocupa byte.
            continue
        total += int(n) if n else 1
    return total


def tamanho_do_copybook(path):
    total = 0
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            # coluna 7 (indice 6) com '*' marca linha de comentario
            if len(line) > 6 and line[6] == "*":
                continue
            m = re.search(r"PIC\s+([9XV()0-9]+)\.", line, re.IGNORECASE)
            if m:
                total += pic_len(m.group(1))
    return total


def main(paths):
    falhas = 0
    for path in paths:
        nome = os.path.splitext(os.path.basename(path))[0]
        real = tamanho_do_copybook(path)
        esperado = TAMANHOS_ESPERADOS.get(nome)

        if esperado is None:
            print(f"FALHA  {path}: {real} bytes - copybook sem tamanho "
                  f"esperado registrado em TAMANHOS_ESPERADOS")
            falhas += 1
        elif real != esperado:
            print(f"FALHA  {path}: {real} bytes (esperado {esperado})")
            falhas += 1
        else:
            print(f"ok     {path}: {real} bytes")

    if falhas:
        print(f"\n{falhas} copybook(s) com tamanho divergente.")
        return 1
    print(f"\n{len(paths)} copybook(s) validado(s).")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        args = sorted(glob.glob("copybooks/*.cpy"))
    # o shell do Windows nao expande curingas; expandimos aqui
    expandidos = []
    for a in args:
        expandidos.extend(sorted(glob.glob(a)) if "*" in a else [a])
    sys.exit(main(expandidos))
