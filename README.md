# FLOWCNAB — Batch de Remessa e Retorno Bancário (CNAB 240)

Simulação do processo noturno (batch) que qualquer empresa que cobra
clientes em volume precisa rodar: empacotar as cobranças pendentes num
arquivo que o banco entende (**remessa**), e depois ler a resposta do
banco (**retorno**) para saber quem pagou. É a peça de mainframe do
ecossistema **FlowPay → FLOWCNAB → CopyBridge**, mas funciona de forma
100% independente — não depende dos outros dois projetos para existir.

**Repositório:** <https://github.com/ZeHoschett/flowcnab>

```bash
git clone https://github.com/ZeHoschett/flowcnab.git
cd flowcnab
bash scripts/run_e2e.sh
```

> Escrito em **COBOL** (GnuCOBOL 3.3), sem mainframe: roda em Linux,
> macOS ou Windows via Git Bash. Os scripts em Python e Shell existem
> só para gerar carga de teste, validar os copybooks e orquestrar o
> fluxo — a lógica de negócio está inteira nos três `.cbl`.

## O que o projeto faz

1. **Geração de remessa** (`remessa/GERAREM.cbl`): lê uma lista de
   cobranças pendentes e gera um arquivo **CNAB 240** para cobrança via
   **boleto**, no layout do **Banco Itaú (código 341)**, seguindo a
   hierarquia padrão FEBRABAN: header de arquivo → header de lote →
   um registro de detalhe (segmentos **P** + **Q**) por cobrança →
   trailer de lote → trailer de arquivo. Cada linha tem exatamente
   **240 posições fixas** — isso é a regra do jogo, e é validado
   automaticamente (ver `scripts/check_len.py` e `scripts/test_e2e.sh`).
   A entrada passa por uma crítica antes de virar título: nosso número
   inválido ou zerado, valor zerado ou não numérico, vencimento
   inválido, campo numérico do pagador (CEP, CPF/CNPJ, tipo de
   inscrição) não numérico e **nosso número duplicado** são descartados
   com aviso. A régua é uma só: nada que vire `PIC 9` no CNAB entra sem
   ser numérico — um `MOVE` de texto para campo numérico não falha em
   COBOL, grava zeros (ou as próprias letras) e o erro só apareceria no
   banco. E um nosso número repetido quebra a conciliação lá na frente.

2. **Simulador de banco** (`simulador/SIMBANCO.cbl`): como não existe
   banco de verdade para testar contra, este programa lê a remessa
   gerada e produz um arquivo de **retorno plausível** — a maioria dos
   títulos é marcada como paga (parte no prazo, parte com atraso) e
   uma fração menor é rejeitada com motivos variados (saldo
   insuficiente, dados cadastrais inconsistentes, título já baixado).
   **Isso substitui o banco nos testes e é uma peça legítima do
   projeto, não uma gambiarra.**

3. **Processamento de retorno + conciliação** (`retorno/PROCRET.cbl`):
   lê o arquivo de retorno (do simulador, ou de um banco de verdade —
   o layout é o mesmo), identifica cada cobrança pelo **nosso número**,
   atualiza o status dela (`PAGO`, `PAGO COM ATRASO` ou `REJEITADO` com
   o motivo) e gera um **relatório de conciliação**: quantos títulos
   foram enviados, quantos voltaram pagos, quantos com erro e o valor
   total conciliado.

## Fluxo

```
cobrancas_pendentes.txt
        |
        v
   [ GERAREM ]  ---->  REMESSA.TXT (CNAB 240)  ---->  titulos_status.txt (PENDENTE)
        |                     |
        |                     v
        |              [ SIMBANCO ]  (simulador de banco para fins de teste)
        |                     |
        |                     v
        |              RETORNO.TXT (CNAB 240)
        |                     |
        v                     v
titulos_status.txt  ---->  [ PROCRET ]  ---->  titulos_status_novo.txt
                                  |
                                  v
                          CONCILIACAO.TXT
```

## Decisões conscientes de simplificação

- **Um banco, um tipo de cobrança.** Só boleto via CNAB 240, layout do
  **Itaú (341)**, com os segmentos obrigatórios da remessa (P, Q) e do
  retorno (T, U). Nenhum outro banco ou meio de cobrança (PIX, débito
  automático, TED) é tratado — o objetivo é ir fundo no layout de um
  banco só, não cobrir todos.
- **Persistência em arquivo texto de largura fixa, não banco
  relacional.** A "tabela" de cobranças pendentes
  (`dados/cobrancas_pendentes.txt`) e o controle de status dos títulos
  (`dados/titulos_status.txt`) são arquivos sequenciais de posições
  fixas, lidos e escritos com `LINE SEQUENTIAL` em GnuCOBOL. Isso é
  uma das duas opções explicitamente previstas no escopo do projeto
  (a outra seria uma tabela PostgreSQL acessada via `EXEC SQL` com
  OCESQL). O schema equivalente para essa segunda opção está
  documentado em `sql/schema.sql`, incluindo o exemplo de acesso via
  OCESQL, como caminho natural de evolução — trocar os `SELECT`/`OPEN
  INPUT` em arquivo pelos `EXEC SQL` correspondentes não exige mudar a
  estrutura dos copybooks.
- **Sem preocupação com volume/performance.** O foco é a correção do
  layout CNAB 240 (240 posições exatas, campos numéricos e
  alfanuméricos alinhados corretamente) e da lógica de conciliação,
  não throughput.
- **JCL de exemplo, não executável de verdade.** `jcl/FLOWCNAB.JCL`
  mostra como este processo seria agendado e encadeado em um z/OS
  real (STEPLIBs, DDs de arquivo, sugestão de horários via
  agendador). A execução de fato acontece via **GnuCOBOL local**
  (Docker ou instalação direta) — isso está documentado no próprio
  JCL para não passar a impressão de que ele roda "de verdade" aqui.

## Estrutura do repositório

```
copybooks/    definições de registro (240 posições, reaproveitável pelo CopyBridge)
  CNAB240-HDR-ARQ.cpy      header de arquivo
  CNAB240-HDR-LOTE.cpy     header de lote
  CNAB240-DET-P.cpy        detalhe - segmento P (dados do título)
  CNAB240-DET-Q.cpy        detalhe - segmento Q (dados do pagador)
  CNAB240-DET-T.cpy        detalhe - segmento T (retorno)
  CNAB240-DET-U.cpy        detalhe - segmento U (retorno, valores)
  CNAB240-TRL-LOTE.cpy     trailer de lote
  CNAB240-TRL-ARQ.cpy      trailer de arquivo
  COBRANCA-PENDENTE.cpy    registro de entrada (fila de cobranças)
  TITULO-STATUS.cpy        registro de controle/conciliação
  FLOWCNAB-CONST.cpy       constantes compartilhadas (nível 78)

remessa/      GERAREM.cbl      — gera o arquivo de remessa
simulador/    SIMBANCO.cbl     — simula a resposta do banco
retorno/      PROCRET.cbl      — processa retorno e concilia
jcl/          FLOWCNAB.JCL     — exemplo de agendamento em z/OS
sql/          schema.sql       — schema alternativo (PostgreSQL + OCESQL)
scripts/
  gerar_cobrancas_teste.py     — gera carga de teste
  check_len.py                 — valida o tamanho fixo de cada copybook
  run_e2e.sh                   — roda o fluxo completo de ponta a ponta
  test_e2e.sh                  — testes de regressão (verifica o resultado)
dados/        cobrancas_pendentes.txt, titulos_status*.txt (gerados)
saida/        REMESSA.TXT, RETORNO.TXT, CONCILIACAO.TXT (gerados)
```

## Convenções internas

Três contratos que valem para os três programas — quebrá-los é o tipo
de bug que não aparece no dia em que se escreve o código:

### Formato de data

| Onde | Formato | Por quê |
|---|---|---|
| `cobrancas_pendentes.txt`, `titulos_status.txt` | **AAAAMMDD** | ordem numérica = ordem cronológica, dá para comparar direto |
| Registros CNAB 240 (segmentos P/T/U, headers) | **DDMMAAAA** | é o que o layout do Itaú exige |

A conversão acontece em **exatamente dois lugares**:
`GERAREM.520-CONVERTER-VENCIMENTO` (ao gravar o segmento P) e
`PROCRET.560-CONVERTER-DATA-OCORRENCIA` (ao ler o segmento U). Comparar
`DDMMAAAA` numericamente dá resultado errado — `01/10/2026` vira
`01102026`, que é *menor* que `20/09/2026` = `20092026` — e era
exatamente assim que o "pago com atraso" seria decidido pelo motivo
errado.

### Constantes compartilhadas

Código do banco, dados da empresa, códigos de layout, códigos de
ocorrência e o limite de títulos ficam em `copybooks/FLOWCNAB-CONST.cpy`
como constantes de compilação (nível 78), copiadas pelos três
programas. Nenhum `.cbl` carrega `341`, o CNPJ ou o nome da empresa
escrito à mão. É o ponto único a mudar se um dia entrar outro banco —
o que, aliás, é o melhor argumento a favor da decisão de escopo de
tratar só o Itaú.

### RETURN-CODE

Convenção de batch, respeitada pelos três programas e verificada pelo
`run_e2e.sh`:

| Código | Significado |
|---|---|
| `0` | tudo certo |
| `4` | concluiu com aviso (títulos descartados na crítica, conciliação divergente) |
| `8` | erro fatal — arquivo não abre, entrada vazia, capacidade estourada |

### Limite de títulos

`CT-MAX-TITULOS` (500) dimensiona a tabela em memória do PROCRET, e o
GERAREM impõe o **mesmo** limite na geração. Acima disso o GERAREM
aborta com uma mensagem explicando o que fazer, em vez de o PROCRET
gravar fora da tabela e morrer com violação de memória.

## Como rodar localmente

### Opção 1 — GnuCOBOL local (caminho testado)

```bash
sudo apt-get install gnucobol4   # ou gnucobol, dependendo da distro
bash scripts/run_e2e.sh
```

É assim que o projeto foi desenvolvido e é o que a bateria de
regressão usa — GnuCOBOL 3.3, tanto no Linux quanto no Windows via
Git Bash.

### Opção 2 — Docker (não validado)

```bash
docker compose up --build
```

> **Aviso honesto:** o `Dockerfile` existe e tenta instalar
> `gnucobol4`, `gnucobol` e `open-cobol` nessa ordem, porque o nome do
> pacote varia entre releases do Ubuntu — mas ele **nunca foi
> executado de fato**. Se falhar, use a Opção 1, que é o caminho
> coberto pelos testes.

O script `run_e2e.sh`:

1. valida o tamanho fixo de todos os copybooks (`check_len.py`);
2. compila os três programas (`cobc -x -I copybooks ...`);
3. gera uma carga de teste com 20 cobranças pendentes, caso
   `dados/cobrancas_pendentes.txt` ainda não exista;
4. roda `GERAREM` → `SIMBANCO` → `PROCRET` em sequência, abortando se
   algum passo devolver `RETURN-CODE >= 8`;
5. imprime o relatório de conciliação (também salvo em
   `saida/CONCILIACAO.TXT`).

No Windows (Git Bash) o script detecta o sufixo `.exe` e coloca o
diretório do `cobc` na frente do `PATH` — sem isso o `/mingw64/bin`
sombreia as DLLs do GnuCOBOL e o binário compilado morre com
`command not found`.

> **Nota técnica:** os programas definem
> `ORGANIZATION IS LINE SEQUENTIAL` para os arquivos CNAB, e a
> variável de ambiente `COB_LS_FIXED=Y` (já exportada pelo script e
> pelo Dockerfile) instrui o runtime do GnuCOBOL a **não truncar os
> espaços em branco no fim da linha**, preservando os 240 bytes fixos
> exigidos pelo layout — sem isso, o GnuCOBOL grava linhas de
> comprimento variável (só o texto útil), o que ainda funciona para
> este projeto (a releitura preenche com espaços de volta) mas deixa
> de ser um arquivo CNAB 240 "de verdade" se aberto por outra
> ferramenta.

## Critério de "pronto" (v1) — verificado

Rodando `scripts/run_e2e.sh` a partir de uma base limpa, com a carga
de teste de 20 cobranças:

- ✅ Remessa gerada com 20 títulos, todos os registros com 240 bytes;
- ✅ Simulador de banco processa a remessa e devolve um retorno
  plausível: 18 títulos pagos (12 no prazo + 6 com atraso) e 2
  rejeitados;
- ✅ Retorno processado e relatório de conciliação batendo os
  números certos: 20 enviados = 12 + 6 + 2, com **pelo menos um caso
  de erro tratado corretamente** (2, na verdade — motivos "SALDO
  INSUFICIENTE" e "DADOS CADASTRAIS INCONSIST." — e o valor total
  conciliado refletindo apenas os títulos efetivamente pagos:
  R$ 27.282,83 de R$ 31.427,76 enviados);
- ✅ O próprio relatório confere a identidade
  `enviados = pagos + com atraso + rejeitados + pendentes` e imprime
  `Conferencia: OK` / `DIVERGENTE` — não é o leitor que precisa somar
  as linhas na mão;
- ✅ `scripts/test_e2e.sh` passa (36 verificações), cobrindo também
  nosso número duplicado, nosso número não numérico, campo numérico do
  pagador inválido, arquivo de entrada vazio, estouro da capacidade da
  tabela e as quatro anomalias de retorno (par T/U quebrado, retorno
  órfão, ocorrência repetida e pagamento com valor divergente) — cada
  uma com `RETURN-CODE 4` e linha própria no relatório.

Para reproduzir a validação de layout (tamanho fixo por copybook):

```bash
python3 scripts/check_len.py          # sai com código 1 se divergir
```

E para rodar a bateria de regressão completa (caminho feliz + casos de
borda):

```bash
bash scripts/test_e2e.sh
```

## Referências

- **Manual de Cobrança CNAB 240 do Banco Itaú (código 341)** — layout
  dos segmentos P/Q (remessa) e T/U (retorno) e dos header/trailer de
  arquivo e de lote. Distribuído pelo próprio banco, na área de
  layouts de cobrança do Itaú.
- **Padrão FEBRABAN CNAB 240** — a especificação genérica sobre a qual
  o layout do Itaú é construído.

Os PDFs dos manuais **não são versionados aqui** por serem material de
terceiros. Os comentários no topo dos copybooks citam a página do
manual do Itaú de onde cada registro saiu, e a posição de cada campo
está documentada no próprio copybook.

Uma ressalva registrada de propósito: a conferência posicional do
**segmento T** está pendente — as posições 1 a 188 conferem com o
padrão FEBRABAN, da 189 em diante o copybook diverge. Está tabelado em
`copybooks/CNAB240-DET-T.cpy`. Como o SIMBANCO grava e o PROCRET lê o
mesmo copybook, o fluxo do projeto fecha; um arquivo de retorno de um
banco real precisaria dessa conferência antes.
