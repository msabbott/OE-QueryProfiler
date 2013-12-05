 
 /*------------------------------------------------------------------------
    File        : AbstractReporter
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mabbott
    Created     : Thu Dec 05 17:51:12 GMT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OETools.QueryProfiler.File.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS OETools.QueryProfiler.Reporter.AbstractReporter:

    {OETools\QueryProfiler\ttLine.i             PROTECTED}
    {OETools\QueryProfiler\ttSearch.i           PROTECTED}
    {OETools\QueryProfiler\ttSearchField.i      PROTECTED}
    {OETools\QueryProfiler\ttIndexSearchField.i PROTECTED}
    
    {OETools\QueryProfiler\dsResults.i          PROTECTED}
	
	DEFINE PUBLIC PROPERTY OutputDirectory AS CHARACTER NO-UNDO 
	GET.
	SET. 

	/*------------------------------------------------------------------------------
	 Purpose: Default constructor
	 Notes:
	------------------------------------------------------------------------------*/
	CONSTRUCTOR PUBLIC AbstractReporter ( INPUT cOutputDirectory AS CHARACTER ):
		SUPER ().
		
		ASSIGN OutputDirectory = cOutputDirectory.
		
	END CONSTRUCTOR.

	/*------------------------------------------------------------------------------
	 Purpose: Reports details on a file
	 Notes:
	------------------------------------------------------------------------------*/
	METHOD PUBLIC LOGICAL ReportFile( INPUT oFile AS OETools.QueryProfiler.File ):
		
		RETURN FALSE.

	END METHOD.	
	

END CLASS.