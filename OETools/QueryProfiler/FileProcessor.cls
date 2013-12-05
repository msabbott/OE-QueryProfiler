 
 /*------------------------------------------------------------------------
    File        : FileProcessor
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mabbott
    Created     : Wed Dec 04 08:47:28 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OETools.QueryProfiler.File.
USING OETools.QueryProfiler.File.FileList.
USING OETools.QueryProfiler.Reporter.AbstractReporter.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.FileProcessor:
    
    {OETools\QueryProfiler\File\ttFile.i PROTECTED}
    {OETools\QueryProfiler\File\dsFile.i PROTECTED}
    
	/*------------------------------------------------------------------------------
	 Purpose: Process an individual file
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL ProcessFile( INPUT cFileName AS CHARACTER, INPUT oReporter AS OETools.QueryProfiler.Reporter.AbstractReporter ):
		
		DEFINE VARIABLE oFile AS OETools.QueryProfiler.File NO-UNDO.
		
		/* Create File object and process the file */
		ASSIGN oFile = NEW OETools.QueryProfiler.File(INPUT cFileName).
		
		/* Run processing on the files */
		IF(FALSE = oFile:CompileFile()  ) THEN RETURN FALSE.
		IF(FALSE = oFile:ReadFile()     ) THEN RETURN FALSE.
		IF(FALSE = oFile:ProcessFile()  ) THEN RETURN FALSE.
		IF(FALSE = oFile:LinkToIndexes()) THEN RETURN FALSE.
		
		/* Give file details to reporter */
		oReporter:ReportFile(INPUT oFile).
		
		RETURN TRUE.

	END METHOD.

	/*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	METHOD PUBLIC LOGICAL ProcessFileList( INPUT oFileList AS OETools.QueryProfiler.File.FileList, INPUT oReporter AS OETools.QueryProfiler.Reporter.AbstractReporter ):
		
		/* Pull through list of files added to list */
		oFileList:FetchAll(OUTPUT DATASET dsFile).
		
		/* Process each individual file separately */
		FOR EACH ttFile NO-LOCK:
		    
		    ProcessFile(INPUT ttFile.FileName, INPUT oReporter).
		    
		END.

		RETURN TRUE.

	END METHOD.

END CLASS.