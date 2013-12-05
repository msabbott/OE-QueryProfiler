/*------------------------------------------------------------------------
    File        : ttFile.i
    Purpose     : 

    Syntax      :

    Description : Temp-Table Definition for ttFile table

    Author(s)   : Mark Abbott
    Created     : Fri Nov 01 12:49:37 GMT 2013
    Notes       :
  ----------------------------------------------------------------------*/

 DEFINE {1} TEMP-TABLE ttFile NO-UNDO
    FIELD FileName AS CHARACTER
    
        INDEX PriKey IS PRIMARY UNIQUE FileName ASCENDING.