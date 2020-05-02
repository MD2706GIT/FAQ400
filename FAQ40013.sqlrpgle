        //
        // Display message in job log with SYSTOOLS.LPRINTF
        //

        // *ENTRY PLIST
        dcl-pi FAQ40013 ;
           pNation   char(3) ;
        end-pi;
        dcl-s  sqlStmt     varchar(5000) ;
        dcl-c  $q          x'7D';

        *inLR=*on;
        Exec SQL
          SET OPTION Commit = *none,
                     CloSqlCsr=*EndMod,
                     DlyPrp=*YES
          ;
         // Drop table, if existing
         Exec SQL
           DROP TABLE mduca1.Faq40013T ;
         // build SQL statement
         exsr setSqlStmt;
         // output statement to job log
         Exec SQL
            CALL SYSTOOLS.LPRINTF(:sqlStmt) ;
         // execute statement
         Exec SQL
           EXECUTE IMMEDIATE :sqlStmt ;

         return;

         //------------------------------------------------
         // Build SQL statement in string
         //------------------------------------------------
         begsr setSqlStmt;

         clear sqlStmt;
         sqlStmt = 'CREATE TABLE mduca1.Faq40013T AS (' +
         'SELECT CodCliente, RagioneSociale, NazCl, '   +
         'd.Articolo, Descrizione, SUM(OrdQty) QtOrder '  +
         'FROM AnCli00f '                             +
         'JOIN OrdDt00f d ON CodCliente = OrdCli '    +
         'JOIN AnaArt00f a ON a.Articolo = d.Articolo ' +
         'WHERE NazCl = ' + $q + pNation + $q + ' '     +
         'GROUP BY CodCliente, RagioneSociale, NazCl, ' +
         'd.Articolo, Descrizione '                     +
         'ORDER BY CodCliente)'                         +
         ' WITH DATA'
         ;

         endsr;

