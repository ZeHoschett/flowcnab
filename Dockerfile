FROM ubuntu:24.04

# O nome do pacote do GnuCOBOL varia entre releases do Ubuntu/Debian,
# por isso a cascata. NAO VALIDADO: ver o aviso no README.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 && \
    ( apt-get install -y --no-install-recommends gnucobol4 || \
      apt-get install -y --no-install-recommends gnucobol  || \
      apt-get install -y --no-install-recommends open-cobol ) && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /flowcnab
COPY . /flowcnab

# Compila os tres programas COBOL (copybooks em ./copybooks)
RUN cobc -x -I copybooks -o remessa/gerarem   remessa/GERAREM.cbl && \
    cobc -x -I copybooks -o simulador/simbanco simulador/SIMBANCO.cbl && \
    cobc -x -I copybooks -o retorno/procret    retorno/PROCRET.cbl

ENV COB_LS_FIXED=Y

CMD ["bash", "scripts/run_e2e.sh"]
