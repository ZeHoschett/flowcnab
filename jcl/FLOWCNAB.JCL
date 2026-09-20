//FLOWCNAB JOB (ACCT),'BATCH CNAB240',CLASS=A,MSGCLASS=X,
//         NOTIFY=&SYSUID
//*--------------------------------------------------------------*
//* JCL DE EXEMPLO - FLOWCNAB                                     *
//* Encadeamento noturno do processamento de cobranca CNAB 240.   *
//*                                                                *
//* IMPORTANTE: este JCL e ILUSTRATIVO. Ele mostra como o job     *
//* seria agendado e encadeado em um ambiente z/OS real (com os   *
//* devidos PROCs, STEPLIBs e DDs de VSAM/DB2). A execucao DE FATO *
//* deste projeto acontece via GnuCOBOL local (ver README.md e    *
//* scripts/run_e2e.sh) - nao ha mainframe disponivel para rodar   *
//* este JCL de verdade.                                          *
//*--------------------------------------------------------------*
//*
//STEP010  EXEC PGM=GERAREM
//STEPLIB  DD DSN=FLOWCNAB.LOADLIB,DISP=SHR
//COBRANCA DD DSN=FLOWCNAB.PROD.COBRANCAS.PENDENTES,DISP=SHR
//REMESSA  DD DSN=FLOWCNAB.PROD.REMESSA.CNAB240,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(50,20),RLSE),
//            DCB=(LRECL=240,BLKSIZE=0,RECFM=FB)
//STATUS   DD DSN=FLOWCNAB.PROD.TITULOS.STATUS,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(50,20),RLSE),
//            DCB=(LRECL=130,BLKSIZE=0,RECFM=FB)
//SYSOUT   DD SYSOUT=*
//*
//*--------------------------------------------------------------*
//* STEP020 representa a etapa em que o arquivo de REMESSA e      *
//* efetivamente transmitido ao banco (via CNAB/Internet Banking, *
//* EDI ou similar). Fora do escopo deste projeto.                *
//*--------------------------------------------------------------*
//STEP020  EXEC PGM=IEFBR14
//REMESSA  DD DSN=FLOWCNAB.PROD.REMESSA.CNAB240,DISP=SHR
//*
//*--------------------------------------------------------------*
//* STEP030 roda no dia seguinte, apos o banco disponibilizar o   *
//* arquivo de RETORNO. Aqui simulado pelo SIMBANCO (ver README). *
//*--------------------------------------------------------------*
//STEP030  EXEC PGM=SIMBANCO
//STEPLIB  DD DSN=FLOWCNAB.LOADLIB,DISP=SHR
//REMESSA  DD DSN=FLOWCNAB.PROD.REMESSA.CNAB240,DISP=SHR
//RETORNO  DD DSN=FLOWCNAB.PROD.RETORNO.CNAB240,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(50,20),RLSE),
//            DCB=(LRECL=240,BLKSIZE=0,RECFM=FB)
//SYSOUT   DD SYSOUT=*
//*
//STEP040  EXEC PGM=PROCRET
//STEPLIB  DD DSN=FLOWCNAB.LOADLIB,DISP=SHR
//RETORNO  DD DSN=FLOWCNAB.PROD.RETORNO.CNAB240,DISP=SHR
//STATUSIN DD DSN=FLOWCNAB.PROD.TITULOS.STATUS,DISP=SHR
//STATUSOU DD DSN=FLOWCNAB.PROD.TITULOS.STATUS.NOVO,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(50,20),RLSE),
//            DCB=(LRECL=130,BLKSIZE=0,RECFM=FB)
//CONCILIA DD DSN=FLOWCNAB.PROD.CONCILIACAO.RPT,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(20,10),RLSE),
//            DCB=(LRECL=100,BLKSIZE=0,RECFM=FB)
//SYSOUT   DD SYSOUT=*
//*
//*--------------------------------------------------------------*
//* Agendamento sugerido (ex.: via CA7, Control-M ou TWS):         *
//*   STEP010 (gera remessa) ....... 22:00, dias uteis            *
//*   STEP020 (transmissao) ........ 22:15, apos STEP010 OK       *
//*   STEP030 (le retorno) ......... 06:00 do dia seguinte        *
//*   STEP040 (concilia + relatorio) 06:05, apos STEP030 OK       *
//*--------------------------------------------------------------*
