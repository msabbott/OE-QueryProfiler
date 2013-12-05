 
 /*------------------------------------------------------------------------
    File        : File
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mabbott
    Created     : Wed Dec 04 16:56:17 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.File: 

    {OETools\QueryProfiler\ttLine.i             PROTECTED}
    {OETools\QueryProfiler\ttSearch.i           PROTECTED}
    {OETools\QueryProfiler\ttSearchField.i      PROTECTED}
    {OETools\QueryProfiler\ttIndexSearchField.i PROTECTED}
    
    {OETools\QueryProfiler\dsResults.i          PROTECTED}
    
	DEFINE PUBLIC PROPERTY FileName AS CHARACTER NO-UNDO 
	GET.
	SET. 

   /*------------------------------------------------------------------------------
	 Purpose: Construct object with given file name
	 Notes:
	------------------------------------------------------------------------------*/
	CONSTRUCTOR PUBLIC File ( INPUT pcFileName AS CHARACTER ):
		SUPER ().
		
		ASSIGN FileName = pcFileName.
		
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose: Compiles a file into an XREF file
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL CompileFile(  ):
		
		COMPILE VALUE(FileName) XREF VALUE(GetXrefFileName()).

		RETURN TRUE.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Returns Dataset which contains the matched results
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC VOID FetchMatchedResults( OUTPUT DATASET dsResults ):
		
		RETURN.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Returns the name of the Xref file
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PROTECTED CHARACTER GetXrefFileName(  ):
		
		RETURN Filename + ".xref".

	END METHOD.	

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL LinkToIndexes(  ):
		
        DEFINE VARIABLE iListOrder AS INTEGER    NO-UNDO.

        FOR EACH ttSearch NO-LOCK,
        
           FIRST _file NO-LOCK
           WHERE _file._file-name = ENTRY(2, ttSearch.SearchTable, "."),
           
           FIRST _index NO-LOCK
              OF _file
           WHERE _index._index-name = ttSearch.SearchIndex
           
              BY ttSearch.LineNumber
              ON ERROR UNDO, RETURN ERROR RETURN-VALUE:
    
            FOR EACH ttSearchField
               WHERE ttSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttSearchField.SearchNumber
                  BY ttSearchField.SearchFieldNumber DESCENDING
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:
    
                CREATE ttIndexSearchField.
    
                ASSIGN ttIndexSearchField.SearchNumber      = ttSearchField.SearchNumber
                       ttIndexSearchField.SearchFieldNumber = ttSearchField.SearchFieldNumber
                       ttIndexSearchField.SearchFieldName   = ttSearchField.FieldName.
    
            END.
    
    
            /* Now iterate through all the fields in the index, and match them back to the table fields */
            FOR EACH _index-field NO-LOCK
                  OF _index,
    
               FIRST _field NO-LOCK
                  OF _index-field
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:
    
                FIND FIRST ttIndexSearchField
                     WHERE ttIndexSearchField.SearchNumber    = ttSearch.SearchNumber
                       AND ttIndexSearchField.SearchFieldName = _field._field-name
                           EXCLUSIVE-LOCK NO-ERROR.
    
                /* Create if it does not exist */
                IF NOT AVAILABLE ttIndexSearchField THEN
                DO:
                    CREATE ttIndexSearchField.
    
                    ASSIGN ttIndexSearchField.SearchNumber   = ttSearch.SearchNumber.
                END.
    
                ASSIGN ttIndexSearchField.IndexFieldName      = _field._field-name
                       ttIndexSearchField.IndexSequenceNumber = _index-field._index-seq.
    
            END.
    
            /* List order should be the index order, for the moment, until I can work out the right way to do this! */
            ASSIGN iListOrder = 1.
    
            FOR EACH ttIndexSearchField EXCLUSIVE-LOCK
               WHERE ttIndexSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttIndexSearchField.IndexSequenceNumber
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:
    
                ASSIGN ttIndexSearchField.ListOrder = iListOrder
                       iListOrder                   = iListOrder + 1.
    
            END.
    
        END.		

		RETURN TRUE.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Use data read in, identify the items to search
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL ProcessFile(  ):
		
        DEFINE VARIABLE cMainFile      AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE cSecondaryFile AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE iLineNumber    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cVerb          AS CHARACTER  NO-UNDO.
    
        DEFINE VARIABLE iSearchNumber      AS INTEGER    NO-UNDO INITIAL 0.
        DEFINE VARIABLE iSearchFieldNumber AS INTEGER    NO-UNDO.
    
        FOR EACH ttLine
              BY ttLine.LineNumber DESCENDING:

            /* There must be at least 6 entries on this line for us to process it */
            IF NUM-ENTRIES(ttLine.LineText, " ") < 6 THEN NEXT.

            /* Interpret the parameters of the line */
            ASSIGN cMainFile      =         ENTRY(1, ttLine.LineText, " ")
                   cSecondaryFile =         ENTRY(2, ttLine.LineText, " ")
                   iLineNumber    = INTEGER(ENTRY(3, ttLine.LineText, " "))
                   cVerb          =         ENTRY(4, ttLine.LineText, " ").

            IF cVerb = "SEARCH" THEN
            DO:
                ASSIGN iSearchNumber      = iSearchNumber + 1
                       iSearchFieldNumber = 1.

                CREATE ttSearch.

                ASSIGN ttSearch.SearchNumber  = iSearchNumber
                       ttSearch.SearchTable   = ENTRY(5, ttLine.LineText, " ")
                       ttSearch.SearchIndex   = ENTRY(6, ttLine.LineText, " ")
                       ttSearch.MainFile      = cMainFile
                       ttSearch.SecondaryFile = cSecondaryFile
                       ttSearch.LineNumber    = iLineNumber.
            END.
            ELSE IF cVerb = "ACCESS" THEN
            DO:
                /* Could be that last line of file is not "SEARCH" but "ACCESS", therefore there will be no ttSearch
                 * available - this is absolutely fine.
                 */
                /* It looks like, for each search, the line numbers are always the same between all the fields and the
                 * initial "SEARCH", so can use that for better comparison too
                 */
                IF AVAILABLE ttSearch AND ENTRY(5, ttLine.LineText, " ") = ttSearch.SearchTable AND iLineNumber = ttSearch.LineNumber THEN
                DO:
                    CREATE ttSearchField.

                    ASSIGN ttSearchField.SearchNumber      = ttSearch.SearchNumber
                           ttSearchField.SearchFieldNumber = iSearchFieldNumber
                           ttSearchField.FieldName         = ENTRY(6, ttLine.LineText, " ").

                    ASSIGN iSearchFieldNumber = iSearchFieldNumber + 1.
                END.
            END.
        END.
    
		RETURN TRUE.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Reads in Xref file into temp-tables
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL ReadFile(  ):
	    
	    DEFINE VARIABLE cLine       AS CHARACTER NO-UNDO.
	    DEFINE VARIABLE iLineNumber AS INTEGER   NO-UNDO.
		
		INPUT THROUGH VALUE('grep -E " [0-9]* (SEARCH|ACCESS)" ' + GetXrefFileName()).

        REPEAT
            ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

            IMPORT UNFORMATTED cLine.
            
            CREATE ttLine.
            
            ASSIGN ttLine.LineNumber = iLineNumber
                   ttLine.LineText   = cLine
                   iLineNumber       = iLineNumber + 1.
        
        END.
        
        INPUT CLOSE.

		RETURN TRUE.

	END METHOD.	
    

END CLASS.