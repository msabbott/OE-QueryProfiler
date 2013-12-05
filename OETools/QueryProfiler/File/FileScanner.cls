 
 /*------------------------------------------------------------------------
    File        : FileScanner
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Mark Abbott
    Created     : Fri Nov 01 08:47:14 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OETools.QueryProfiler.File.FileList.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.File.FileScanner:
    
    /* Defines maximum depth directory scan should go to */
	DEFINE PUBLIC PROPERTY MaxRecurseLevel AS INTEGER INITIAL ? NO-UNDO 
	GET.
	SET. 

    /* Defines whether Directories should be recursed into */
	DEFINE PUBLIC PROPERTY RecurseDirectories AS LOGICAL INITIAL TRUE NO-UNDO 
	GET.
	SET. 
	
	/* Holds reference to the FileList to populate with data */
	DEFINE PROTECTED PROPERTY FileList AS OETools.QueryProfiler.File.FileList NO-UNDO
    GET.
    SET. 
	

	/*------------------------------------------------------------------------------
	 Purpose: Default constructor. FileList will be populated with contents of directory
	 Notes:
	------------------------------------------------------------------------------*/
	CONSTRUCTOR PUBLIC FileScanner ( INPUT poFileList AS OETools.QueryProfiler.File.FileList ):
		SUPER ().
		
		/* By default, recurse into directories with no limit on depth */
		ASSIGN RecurseDirectories = TRUE
		       MaxRecurseLevel    = ?
		       FileList           = poFileList.
		
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose: Scans the provided directory for files, up to the maximum recursion left.
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PROTECTED LOGICAL ScanAndRecurse( INPUT pcDirectory AS CHARACTER, INPUT pcPattern AS CHARACTER, INPUT piRecurseLevel AS INTEGER ):
	    
	    DEFINE VARIABLE cLine       AS CHARACTER NO-UNDO.
	    DEFINE VARIABLE cName       AS CHARACTER NO-UNDO.
	    DEFINE VARIABLE cFullPath   AS CHARACTER NO-UNDO.
	    DEFINE VARIABLE cAttributes AS CHARACTER NO-UNDO.
	    DEFINE VARIABLE iLoop       AS INTEGER NO-UNDO.
	    		
		/* Ensure that we have no recursed any further than needed */
		IF MaxRecurseLevel NE ? AND piRecurseLevel > MaxRecurseLevel THEN RETURN FALSE.
		
		/* Read from directory */
		INPUT FROM OS-DIR(pcDirectory).
		
		RepeatLoop:
		REPEAT:
		    
		    IMPORT UNFORMATTED cLine.
		    
		    /* Ignore "." and ".." entries */
		    IF cLine BEGINS '"."' OR cLine BEGINS '".."' THEN NEXT RepeatLoop.
		    
		    ASSIGN cName       = TRIM(ENTRY(1, cLine, " "), '"')
		           cAttributes = TRIM(ENTRY(NUM-ENTRIES(cLine, " "), cLine, " "), '"').

            /* Pull out the full path to the file, including any spaces in the file name */
            ASSIGN cFullPath = "".		           
		    DO iLoop = 2 TO NUM-ENTRIES(cLine, " ") - 1:
		        
		        ASSIGN cFullPath = cFullPath
		                         + (IF cFullPath = "" THEN "" ELSE " ")
		                         + ENTRY(iLoop, cLine, " ").
		        
		    END.
		    
		    ASSIGN cFullPath = TRIM(cFullPath, '"').
		    
		    /* Process item */
		    IF cAttributes MATCHES "*F*" THEN
		    DO:
		        /* Check if file name matches the pattern */
		        IF cName MATCHES pcPattern THEN
		        DO:
		            FileList:AddFile(INPUT cFullPath).
		        END.
		    END.
		    ELSE IF cAttributes MATCHES "*D*" THEN
		    DO:
		        /* Recurse into directory */
		        ScanAndRecurse( INPUT cFullPath, INPUT pcPattern, INPUT piRecurseLevel  + 1 ).
	        END.		               
		    
		END.
		
		INPUT CLOSE.

	END METHOD.

    /*------------------------------------------------------------------------------
     Purpose: Scans a directory with the provided file name pattern
     Notes: pcPattern parameter should be a statement that can be used by MATCHES keyword.
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL ScanDirectory( INPUT pcDirectory AS CHARACTER, INPUT pcPattern AS CHARACTER ):
        
        /* If pcDirectory is blank or ?, then assume the current directory */
        IF pcDirectory = ? OR TRIM(pcDirectory) = "" THEN ASSIGN pcDirectory = ".".
        
        /* If pcPattern is blank or ?, then assume all files */
        IF pcPattern = ? OR TRIM(pcPattern) = "" THEN ASSIGN pcPattern = "*".
        
        ScanAndRecurse(INPUT pcDirectory, INPUT pcPattern, INPUT 0).
        
        RETURN TRUE.

    END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose: Scans a directory for common Progress file extensions.
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL ScanDirectoryForCommonProgress( INPUT pcDirectory AS CHARACTER ):
	    
	    DEFINE VARIABLE cList      AS CHARACTER NO-UNDO INITIAL "p|i|cls|w".
	    DEFINE VARIABLE iLoop      AS INTEGER NO-UNDO.
	    DEFINE VARIABLE cExtension AS CHARACTER NO-UNDO.

        DO iLoop = 1 TO NUM-ENTRIES(cList, "|"):
            
            ASSIGN cExtension = "*~~." + ENTRY(iLoop, cList, "|").
		
    		/* Scan, returning false if an error occurred */
    		IF(NOT ScanDirectory(INPUT pcDirectory, INPUT cExtension)) THEN RETURN FALSE.
    		
        END.

	END METHOD.	

END CLASS.