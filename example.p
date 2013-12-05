
/*------------------------------------------------------------------------
    File        : example.p
    Purpose     : 

    Syntax      :

    Description : Example OO-ABL file showing how to interact with OE-QueryProfiler

    Author(s)   : Mark Abbott
    Created     : Thu Dec 05 17:49:18 GMT 2013
    Notes       :
  ----------------------------------------------------------------------*/

USING OETools.QueryProfiler.FileProcessor.
USING OETools.QueryProfiler.File.*.

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE objFileProcessor AS OETools.QueryProfiler.FileProcessor         NO-UNDO. /* Define variable to hold Processor */
DEFINE VARIABLE objFileList      AS OETools.QueryProfiler.File.FileList         NO-UNDO. /* Define variable to hold list of files */
DEFINE VARIABLE objReporter      AS OETools.QueryProfiler.Reporter.TextReporter NO-UNDO. /* Define variable to hold Reporter */

/* ***************************  Main Block  *************************** */

/* **** Step 1: Create objects **** */
ASSIGN

/* Create object to perform processing of files
 */
objFileProcessor = NEW OETools.QueryProfiler.FileProcessor()

/* Create object to hold list of files to be scanned */
objFileList = NEW OETools.QueryProfiler.File.FileList()

/* Create reporter object */
objReporter = NEW OETools.QueryProfiler.Reporter.TextReporter(INPUT "."). /* Output directory */


/* **** Step 2: Identify files **** */

/* Add in a single file */
objFileList:AddFile("./example.p").

/* Add in a whole directory, and any subdirectories */
objFileList:Scanner:ScanDirectory("./OETools", "*~~.cls"). /* Second parameter must be a valid for use with "MATCH" keyword. */

/* Set Maximum Directory Recursion Level. */
/* E.G.
 * When ? or Not Specified: Infinite
 * When 0, starting directory only
 * When 1, Starting Directory, and one level down
 * When 2, Starting Directory, and two levels down,
 * etc.
 */
objFileList:Scanner:MaxRecurseLevel = 0.

/* Scan again for .p files */
objFileList:Scanner:ScanDirectory("./", "*~~.p").



/* **** Step 3: Read list of files **** */

/* Process everything in the file list */
objFileProcessor:ProcessFileList(INPUT objFileList, INPUT objReporter).

