       ctl-opt decedit('0,') datedit(*dmy.)
       actgrp(*caller) dftactgrp(*no) option(*nodebugio:*srcstmt);
      //-------------------------------------------------------------*
      // Bill Of Material development
      //
      // Reads the BOM from base item and develops all components
      //  and related required quantities, down to raw material.
      // Output is written to a work file
      //
      // INPUT PARMS:
      //  - item type     CHAR(1)
      //  - item code     CHAR(20)
      //-------------------------------------------------------------*
      // BOM master file
       dcl-f BomDT01l  disk usage(*input) keyed;
       // work file
       dcl-f BomWRK    disk usage(*output) prefix(W_);
      // ENTRY     -------------------------------------------------
       dcl-pi FAQ40014B;
           dcl-parm pType    char(1);
           dcl-parm pCode    char(20);
       end-pi;
      // Prototypes ------------------------------------------------
       dcl-pr getBOM;
           *n char(1);
           *n char(20);
           *n zoned(9:2);
           *n zoned(4:0);
       end-pr;
      // Variables   -----------------------------------------------
       dcl-ds dsBOM     extname('BOMDT00F') end-ds;
       dcl-s  qty0      like(Quantity);
       dcl-s  level0    zoned(4:0);
      // PSDS ------------------------------------------------------
       dcl-ds pgmDS psds qualified;
           user     char(10) pos(254);
       end-ds;
      //*********************************************************
      // SQL options
       Exec SQL
          SET OPTION COMMIT = *None,
          ALWCPYDTA = *Yes,
          CLOSQLCSR = *EndMod,
          DLYPRP    = *Yes
         ;
      //  Clear work file
        Exec SQL
        DELETE FROM BomWRK ;

      // Get initial item

        chain (pType:pCode) BomDT01l;
        if %found(BomDT01l);
           qty0 = 1;
           level0 = 1;
           getBOM(pType:pCode:qty0:level0);
        endif;

        close *all;
        *inLR = *on;
        return;
        // --------------------------------------------------
        // BOM development
        // --------------------------------------------------
       dcl-proc getBOM;
      // Procedure interface -------------------
         dcl-pi getBOM ;
             dcl-parm   pType  char(1);        // item type
             dcl-parm   pItem  char(20);       // item code
             dcl-parm   pQty   zoned(9:2);     // required quantity
             dcl-parm   pLevel zoned(4:0);     // depth level
         end-pi;
      // BOM master file
       dcl-f BomDT01l  disk usage(*input) keyed;
      // Variables -------------------------------------------------
       dcl-s qtyComp    like(Quantity);
       dcl-s level      zoned(4:0);
       dcl-ds dsBOM2    extname('BOMDT01L':*all) end-ds;

        // read item's components and develop BOM
        setll (pType:pItem) BomDT01l;
        level = pLevel + 1;
        dou %eof(BomDT01l);
            reade (pType:pItem) BomDT01l dsBOM2;
            if not %eof(BomDT01l) and CompCode <> *blank;
               eval(h) qtyComp = pQty * quantity;
               exsr wrtFile;
               // recursive call
               getBOM(CompType:
                      CompCode:
                      qtyComp:
                      level);
            endif;
        enddo;

        // --------------------------------------------------
        // write item component to work file
        // --------------------------------------------------
        begsr wrtFile;
                Clear WBOM;
                W_Level    = pLevel;
                W_itemType = pType;
                W_itemCode = pItem;
                W_compType = compType;
                W_compCode = compCode;
                W_quantity = qtyComp;
                Write WBOM;
        endsr;
        // --------------------------------------------------
       end-proc;
 