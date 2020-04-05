       //---------------------------------------------------------------
       //
       // Service program FAQ40012A
       //
       // Procedures:
       // - isCalledFrom = check if a given program is in call stack
       //
       // Compile instructions:
       // - Create binding directory SRVBND
       //   CRTBNDDIR BNDDIR(MYLIB/SRVBND)
       // - Add FAQ40012A service pgm to bnddir
       //   ADDBNDDIRE BNDDIR(MYLIB/SRVBND) OBJ((MYLIB/FAQ40012A *SRVPGM))
       // - Create module
       //   CRTSQLRPGI OBJ(mylib/FAQ40012A) SRCFILE(mylib/mySrcFile) SRCMBR(*OBJ)
       //    OBJTYPE(*MODULE) DBGVIEW(*SOURCE)
       // - Create service program
       //   CRTSRVPGM SRVPGM(MYLIB/FAQ40012A) MODULE(FAQ40012A) EXPORT(*ALL)
       //---------------------------------------------------------------
       ctl-opt option(*nodebugio: *srcstmt)
       fixnbr(*zoned : *inputpacked)
       bnddir('SRVBND')
       nomain ;
      *********************************************************************
       dcl-ds PgmDs  extname('PSDS') psds qualified   end-ds;
       dcl-s  $sql   char(5000) ;
       dcl-s  $ap    char(1) inz(x'7D');   // quote
       dcl-s  indNull        int(5);       // null inds

       Exec SQL
         SET OPTION
           COMMIT    = *None,
           ALWCPYDTA = *Yes,
           CLOSQLCSR = *EndActGrp,
           DLYPRP    = *Yes;

      ********************************************************************
      // isCalledFrom - Check if a given program is in call stack
      //
      // INPUT Parms:
      // - pPgm         - Program name            CHAR(10)
      //
      // OUTPUT Parms:
      // - Flag "1"=found "0"=not found           BOOLEAN
      //
      ********************************************************************
       dcl-proc  isCalledFrom   export;
          dcl-pi isCalledFrom   ind;
             dcl-parm pPgm   char(10)  const ;    // program name
          end-pi;

          dcl-s found        ind;

          monitor;
            found = *off;
            Exec SQL
            SET :found:indNull = (SELECT DISTINCT '1'
            FROM TABLE (QSYS2.STACK_INFO('*')) s
            WHERE program_library_name NOT LIKE 'QSYS%'
              AND program_name = :pPgm
            )
            ;
            if indNull = -1;
               found = *off;
            endif;

          on-error;
            found = *off;
          endmon;
          return found;

       end-proc;
