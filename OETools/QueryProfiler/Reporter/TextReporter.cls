 
 /*------------------------------------------------------------------------
    File        : TextReporter
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mabbott
    Created     : Thu Dec 05 17:51:48 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OETools.QueryProfiler.Reporter.AbstractReporter.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.Reporter.TextReporter INHERITS AbstractReporter:

    /*------------------------------------------------------------------------------
     Purpose: Default constructor
     Notes:
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PUBLIC TextReporter ( INPUT cOutputDirectory AS CHARACTER ):
        
        SUPER (cOutputDirectory).
        
    END CONSTRUCTOR.

    /*------------------------------------------------------------------------------
     Purpose: Reports details on a file
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD OVERRIDE PUBLIC LOGICAL ReportFile( INPUT oFile AS OETools.QueryProfiler.File ):
        
        OUTPUT TO VALUE(oFile:FileName + ".txt") UNBUFFERED.
        
        /* Fetch data results from the File object */
        oFile:FetchMatchedResults(OUTPUT DATASET dsResults).
        
        PUT UNFORMATTED "Query Profile for File: " oFile:FileName SKIP(2).
        
        FOR EACH ttSearch NO-LOCK
              BY ttSearch.LineNumber
              ON ERROR UNDO, RETURN ERROR RETURN-VALUE:
              
            PUT UNFORMATTED
                "Primary File: " ttSearch.MainFile SKIP
                "Secondary File: " ttSearch.SecondaryFile SKIP
                "SEARCH LineNumber: " ttSearch.LineNumber " Table: " ttSearch.SearchTable " Index: " ttSearch.SearchIndex " Search Quality: " ttSearch.IndexQuality SKIP.

            FOR EACH ttIndexSearchField EXCLUSIVE-LOCK
               WHERE ttIndexSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttIndexSearchField.SearchNumber
                  BY ttIndexSearchField.ListOrder
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

                PUT "~t"
                    (IF ttIndexSearchField.SearchFieldName = ? THEN "" ELSE ttIndexSearchField.SearchFieldName) FORMAT "x(40)"
                    "=>~t"
                    (IF ttIndexSearchField.IndexFieldName = ?  THEN "" ELSE ttIndexSearchField.IndexFieldName ) FORMAT "x(40)" SKIP.

            END.

            PUT UNFORMATTED SKIP(1).


        END.
        
        OUTPUT CLOSE.
        
        RETURN TRUE.

    END METHOD. 

END CLASS.