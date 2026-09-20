#!/usr/bin/env bash
# Testes de regressao do FLOWCNAB.
#
# O run_e2e.sh RODA o fluxo; este script VERIFICA o resultado. Cobre
# o caminho feliz e os casos de borda que ja quebraram o projeto:
#   1. caminho feliz: larguras de linha e a identidade
#      enviados = pagos + com atraso + rejeitados + pendentes
#   2. formato das datas (AAAAMMDD interno x DDMMAAAA no CNAB)
#   3. nosso numero duplicado na entrada
#   4. arquivo de cobrancas vazio
#   5. estouro da capacidade da tabela do PROCRET
#
# Uso: bash scripts/test_e2e.sh
set -uo pipefail
cd "$(dirname "$0")/.."

export COB_LS_FIXED=Y

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

GERAREM="./remessa/gerarem${EXE}"
SIMBANCO="./simulador/simbanco${EXE}"
PROCRET="./retorno/procret${EXE}"

FALHAS=0
TESTES=0

ok()    { TESTES=$((TESTES+1)); echo "  ok    $1"; }
falha() { TESTES=$((TESTES+1)); FALHAS=$((FALHAS+1)); echo "  FALHA $1"; }

verificar() {  # verificar <descricao> <esperado> <obtido>
    if [ "$2" = "$3" ]; then
        ok "$1 ($3)"
    else
        falha "$1 - esperado [$2], obtido [$3]"
    fi
}

larguras() {   # imprime as larguras distintas das linhas de um arquivo
    awk '{ print length($0) }' "$1" | sort -un | paste -sd, -
}

# ---- registro COBRANCA-PENDENTE de 165 posicoes -------------------
# uso: registro <nosso_numero> <vencimento AAAAMMDD> <valor_centavos>
registro() {
    printf '%08d1123456789010000%-30.30s%-40.40s%-15.15s01310100%-15.15s%-2.2s%s%013d%-10.10s' \
        "$1" "TESTE PAGADOR" "RUA DOS TESTES, 1" "CENTRO" \
        "SAO PAULO" "SP" "$2" "$3" "NF9999"
    printf '\n'
}

mkdir -p dados saida
rm -f dados/cobrancas_pendentes.txt

echo ">> Compilando..."
cobc -x -I copybooks -o remessa/gerarem    remessa/GERAREM.cbl || exit 1
cobc -x -I copybooks -o simulador/simbanco simulador/SIMBANCO.cbl || exit 1
cobc -x -I copybooks -o retorno/procret    retorno/PROCRET.cbl || exit 1

echo
echo ">> Teste 0: tamanho dos copybooks"
if "$PY" scripts/check_len.py >/dev/null; then
    ok "todos os copybooks com o tamanho esperado"
else
    falha "check_len.py acusou divergencia de tamanho"
fi

echo
echo ">> Teste 1: caminho feliz (20 cobrancas)"
"$PY" scripts/gerar_cobrancas_teste.py 20 >/dev/null
"$GERAREM" >/dev/null;  verificar "GERAREM RETURN-CODE" "0" "$?"
"$SIMBANCO" >/dev/null; verificar "SIMBANCO RETURN-CODE" "0" "$?"
"$PROCRET" >/dev/null;  verificar "PROCRET RETURN-CODE" "0" "$?"

verificar "REMESSA.TXT com linhas de 240 bytes" \
    "240" "$(larguras saida/REMESSA.TXT)"
verificar "RETORNO.TXT com linhas de 240 bytes" \
    "240" "$(larguras saida/RETORNO.TXT)"
verificar "titulos_status.txt com linhas de 130 bytes" \
    "130" "$(larguras dados/titulos_status.txt)"
verificar "titulos_status_novo.txt com linhas de 130 bytes" \
    "130" "$(larguras dados/titulos_status_novo.txt)"

# identidade da conciliacao, lida do proprio relatorio
enviados=$(grep "Titulos enviados"  saida/CONCILIACAO.TXT | tr -dc '0-9')
pagos=$(grep    "Pagos no prazo"    saida/CONCILIACAO.TXT | tr -dc '0-9')
atraso=$(grep   "Pagos com atraso"  saida/CONCILIACAO.TXT | tr -dc '0-9')
rejeit=$(grep   "Rejeitados/com"    saida/CONCILIACAO.TXT | tr -dc '0-9')
penden=$(grep   "Ainda pendentes"   saida/CONCILIACAO.TXT | tr -dc '0-9')

verificar "enviados = pagos + atraso + rejeitados + pendentes" \
    "$enviados" "$(( pagos + atraso + rejeit + penden ))"
verificar "relatorio marca a conferencia como OK" "1" \
    "$(grep -c 'Conferencia.*: OK' saida/CONCILIACAO.TXT)"
verificar "houve pelo menos um titulo rejeitado" "true" \
    "$([ "$rejeit" -ge 1 ] && echo true || echo false)"
verificar "houve pelo menos um titulo pago com atraso" "true" \
    "$([ "$atraso" -ge 1 ] && echo true || echo false)"

echo
echo ">> Teste 2: formato das datas"
# segmento P (pos. 14 = 'P'): vencimento em DDMMAAAA nas posicoes 78-85
venc_cnab=$(awk 'substr($0,14,1)=="P" { print substr($0,78,8); exit }' \
    saida/REMESSA.TXT)
verificar "segmento P grava vencimento DDMMAAAA (dia <= 31)" "true" \
    "$([ "${venc_cnab:0:2}" -le 31 ] && [ "${venc_cnab:2:2}" -le 12 ] \
        && echo true || echo false)"
# arquivo de status: vencimento em AAAAMMDD nas posicoes 39-46
venc_int=$(awk 'NR==1 { print substr($0,39,8) }' dados/titulos_status.txt)
verificar "titulos_status grava vencimento AAAAMMDD (ano >= 1900)" "true" \
    "$([ "${venc_int:0:4}" -ge 1900 ] && echo true || echo false)"

echo
echo ">> Teste 3: nosso numero duplicado e descartado"
{ registro 10000001 20260920 10000
  registro 10000002 20260920 10000
  registro 10000001 20260920 10000
  registro 10000004 20260920 10000
} > dados/cobrancas_pendentes.txt
saida_ger=$("$GERAREM" 2>&1)
verificar "GERAREM avisa sobre o nosso numero duplicado" "1" \
    "$(echo "$saida_ger" | grep -c 'nosso numero duplicado')"
verificar "GERAREM gera 3 titulos (descarta a duplicata)" "1" \
    "$(echo "$saida_ger" | grep -c '000003 titulo(s) na remessa')"
"$SIMBANCO" >/dev/null 2>&1
"$PROCRET"  >/dev/null 2>&1
verificar "PROCRET fecha a conciliacao mesmo assim" "1" \
    "$(grep -c 'Conferencia.*: OK' saida/CONCILIACAO.TXT)"

echo
echo ">> Teste 4: arquivo de cobrancas vazio"
: > dados/cobrancas_pendentes.txt
"$GERAREM" >/dev/null 2>&1
verificar "GERAREM sai com RETURN-CODE 8" "8" "$?"

echo
echo ">> Teste 5: estouro da capacidade da tabela (600 titulos)"
: > dados/cobrancas_pendentes.txt
for i in $(seq 1 600); do
    registro $(( 20000000 + i )) 20260920 10000
done > dados/cobrancas_pendentes.txt
saida_ger=$("$GERAREM" 2>&1); rc=$?
verificar "GERAREM aborta com RETURN-CODE 8" "8" "$rc"
verificar "GERAREM explica o limite em vez de estourar a memoria" "1" \
    "$(echo "$saida_ger" | grep -c 'excedeu o limite')"

echo
echo ">> Teste 6: nosso numero invalido e descartado"
{ registro 10000001 20260920 10000
  registro 10000002 20260920 10000
} > dados/cobrancas_pendentes.txt
awk 'NR==2 { $0 = "ABC12345" substr($0,9) } { print }' \
    dados/cobrancas_pendentes.txt > dados/entrada.tmp
mv dados/entrada.tmp dados/cobrancas_pendentes.txt
saida_ger=$("$GERAREM" 2>&1); rc=$?
verificar "GERAREM avisa sobre o nosso numero invalido" "1" \
    "$(echo "$saida_ger" | grep -c 'nosso numero invalido ou zerado')"
verificar "GERAREM gera apenas o titulo valido" "1" \
    "$(echo "$saida_ger" | grep -c '000001 titulo(s) na remessa')"
verificar "GERAREM sai com RETURN-CODE 4" "4" "$rc"
verificar "nenhum segmento P com nosso numero nao numerico" "0" \
    "$(awk 'substr($0,14,1)=="P" && substr($0,41,8) !~ /^[0-9]+$/ \
        { n++ } END { print n+0 }' saida/REMESSA.TXT)"

echo
echo ">> Teste 7: campo numerico do pagador invalido e descartado"
{ registro 10000001 20260920 10000
  registro 10000002 20260920 10000
} > dados/cobrancas_pendentes.txt
# CP-CEP-PAGADOR ocupa as posicoes 110-117 do registro de 165
awk 'NR==2 { $0 = substr($0,1,109) "XXXXXXXX" substr($0,118) } { print }' \
    dados/cobrancas_pendentes.txt > dados/entrada.tmp
mv dados/entrada.tmp dados/cobrancas_pendentes.txt
saida_ger=$("$GERAREM" 2>&1)
verificar "GERAREM avisa sobre o campo numerico invalido" "1" \
    "$(echo "$saida_ger" | grep -c 'campo numerico invalido')"
verificar "nenhum segmento Q com CEP zerado" "0" \
    "$(awk 'substr($0,14,1)=="Q" && substr($0,129,8) == "00000000" \
        { n++ } END { print n+0 }' saida/REMESSA.TXT)"

# ---- os tres testes seguintes partem de uma remessa valida -------
"$PY" scripts/gerar_cobrancas_teste.py 20 >/dev/null
"$GERAREM" >/dev/null 2>&1

echo
echo ">> Teste 8: segmento T sem o segmento U correspondente"
"$SIMBANCO" >/dev/null 2>&1
awk 'substr($0,14,1)=="U" && !d { d=1; next } { print }' \
    saida/RETORNO.TXT > saida/RETORNO.TMP
mv saida/RETORNO.TMP saida/RETORNO.TXT
saida_pro=$("$PROCRET" 2>&1); rc=$?
verificar "PROCRET acusa o par T/U quebrado" "1" \
    "$(echo "$saida_pro" | grep -c 'chegou sem o segmento U')"
verificar "PROCRET sai com RETURN-CODE 4" "4" "$rc"
verificar "relatorio marca a conferencia como DIVERGENTE" "1" \
    "$(grep -c 'Conferencia.*: DIVERGENTE' saida/CONCILIACAO.TXT)"
verificar "relatorio conta os segmentos T sem U" "1" \
    "$(grep -c 'Segmentos T sem o U correspondente' saida/CONCILIACAO.TXT)"

echo
echo ">> Teste 9: retorno para nosso numero inexistente na remessa"
"$SIMBANCO" >/dev/null 2>&1
awk 'substr($0,14,1)=="T" && !d \
    { $0 = substr($0,1,40) "99999999" substr($0,49); d=1 } { print }' \
    saida/RETORNO.TXT > saida/RETORNO.TMP
mv saida/RETORNO.TMP saida/RETORNO.TXT
saida_pro=$("$PROCRET" 2>&1); rc=$?
verificar "PROCRET acusa o retorno orfao" "1" \
    "$(echo "$saida_pro" | grep -c 'inexistente na remessa')"
verificar "PROCRET sai com RETURN-CODE 4" "4" "$rc"
verificar "relatorio nao diz OK com retorno orfao" "1" \
    "$(grep -c 'Conferencia.*: DIVERGENTE' saida/CONCILIACAO.TXT)"

echo
echo ">> Teste 10: pagamento com valor divergente"
"$SIMBANCO" >/dev/null 2>&1
# derruba o valor pago do primeiro titulo liquidado para R$ 1,00
awk 'substr($0,14,1)=="U" && !d && substr($0,78,15)+0 > 0 \
    { $0 = substr($0,1,77) "000000000000100" substr($0,93); d=1 } \
    { print }' saida/RETORNO.TXT > saida/RETORNO.TMP
mv saida/RETORNO.TMP saida/RETORNO.TXT
saida_pro=$("$PROCRET" 2>&1); rc=$?
verificar "PROCRET acusa o valor divergente" "1" \
    "$(echo "$saida_pro" | grep -c 'valor pago diverge')"
verificar "PROCRET sai com RETURN-CODE 4" "4" "$rc"
verificar "relatorio conta os pagos com valor divergente" "1" \
    "$(grep -c 'Pagos com valor divergente' saida/CONCILIACAO.TXT)"

# ---- restaura a carga padrao ------------------------------------
echo
echo ">> Restaurando a carga de teste padrao..."
rm -f dados/cobrancas_pendentes.txt
"$PY" scripts/gerar_cobrancas_teste.py 20 >/dev/null
"$GERAREM" >/dev/null && "$SIMBANCO" >/dev/null && "$PROCRET" >/dev/null

echo
echo "=================================================="
if [ "$FALHAS" -eq 0 ]; then
    echo "TODOS OS $TESTES TESTES PASSARAM"
    exit 0
else
    echo "$FALHAS de $TESTES teste(s) FALHARAM"
    exit 1
fi
