#!/usr/bin/env bash
# Roda o fluxo completo do FLOWCNAB de ponta a ponta:
#   1) gera uma carga de teste de cobrancas pendentes (se nao existir)
#   2) GERAREM   -> gera saida/REMESSA.TXT
#   3) SIMBANCO  -> simula o banco e gera saida/RETORNO.TXT
#   4) PROCRET   -> concilia e gera saida/CONCILIACAO.TXT
#
# Interrompe no primeiro passo que falhar (RETURN-CODE >= 8).
set -euo pipefail
cd "$(dirname "$0")/.."

# COB_LS_FIXED=Y impede o GnuCOBOL de truncar os espacos a direita em
# arquivos LINE SEQUENTIAL - sem isso as linhas deixam de ter os 240
# bytes fixos exigidos pelo CNAB 240. Ver README, "Nota tecnica".
export COB_LS_FIXED=Y

# No Windows (Git Bash / MSYS) o cobc gera .exe; no Linux e macOS nao.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        EXE=".exe"
        # No Git Bash o /mingw64/bin vem antes no PATH e sombreia as
        # DLLs do GnuCOBOL (libcob-4.dll e companhia), fazendo o
        # binario compilado morrer com "command not found" (127).
        # Colocamos o diretorio do cobc na frente.
        COBC_DIR=$(dirname "$(command -v cobc)")
        PATH="${COBC_DIR}:${PATH}"
        export PATH
        ;;
    *)  EXE="" ;;
esac

PY="${PYTHON:-python3}"
command -v "$PY" >/dev/null 2>&1 || PY=python

# Convencao de RETURN-CODE dos programas: 0 = ok, 4 = concluiu com
# aviso (segue o fluxo), >= 8 = erro fatal (aborta).
rodar_passo() {
    local passo="$1"
    set +e
    "$passo"
    local rc=$?
    set -e
    if [ "$rc" -ge 8 ]; then
        echo ">> ABORTADO: $passo terminou com RETURN-CODE $rc" >&2
        exit "$rc"
    elif [ "$rc" -ne 0 ]; then
        echo ">> AVISO: $passo terminou com RETURN-CODE $rc (seguindo)" >&2
    fi
}

mkdir -p dados saida

echo ">> Validando tamanho dos copybooks..."
"$PY" scripts/check_len.py

echo ">> Compilando programas COBOL..."
cobc -x -I copybooks -o remessa/gerarem    remessa/GERAREM.cbl
cobc -x -I copybooks -o simulador/simbanco simulador/SIMBANCO.cbl
cobc -x -I copybooks -o retorno/procret    retorno/PROCRET.cbl

if [ ! -f dados/cobrancas_pendentes.txt ]; then
    echo ">> Gerando carga de teste de cobrancas pendentes..."
    "$PY" scripts/gerar_cobrancas_teste.py
fi

echo ">> 1/3 Gerando remessa (GERAREM)..."
rodar_passo "./remessa/gerarem${EXE}"

echo ">> 2/3 Simulando retorno do banco (SIMBANCO)..."
rodar_passo "./simulador/simbanco${EXE}"

echo ">> 3/3 Processando retorno e conciliando (PROCRET)..."
rodar_passo "./retorno/procret${EXE}"

echo
echo ">> Fluxo concluido. Veja saida/REMESSA.TXT, saida/RETORNO.TXT e"
echo "   saida/CONCILIACAO.TXT."
