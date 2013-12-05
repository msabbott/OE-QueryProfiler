 
 /*------------------------------------------------------------------------
    File        : FileList
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Mark Abbott
    Created     : Fri Nov 01 11:10:30 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.File.FileList: 
    
    {OETools\QueryProfiler\File\ttFile.i PROTECTED}
    {OETools\QueryProfiler\File\dsFile.i PROTECTED}
    
    /* Holds FileScanner object, linked to this FileList object */
	DEFINE PUBLIC PROPERTY Scanner AS OETools.QueryProfiler.File.FileScanner NO-UNDO 
	GET.
	SET. 

	/*------------------------------------------------------------------------------
	 Purpose: Default contructor
	 Notes:
	------------------------------------------------------------------------------*/
	CONSTRUCTOR PUBLIC FileList (  ):
		SUPER ().
		
		/* Create file scanner object */
		ASSIGN Scanner = NEW OETools.QueryProfiler.File.FileScanner(THIS-OBJECT).
		
	END CONSTRUCTOR.

    /*------------------------------------------------------------------------------
     Purpose: Adds a single file to the list of files
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID AddFile( INPUT pcFileName AS CHARACTER ):
        
        IF NOT CAN-FIND(FIRST ttFile NO-LOCK
                        WHERE ttFile.FileName = pcFileName) THEN
        DO:
            CREATE ttFile.
            
            ASSIGN ttFile.FileName = pcFileName.
        END.
        
        RETURN.

    END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Fetches entire file list as a dataset.
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC VOID FetchAll( OUTPUT DATASET dsFile ):
               
        /* Contents of dataset should already be filled */

	END METHOD.	
	

END CLASS.