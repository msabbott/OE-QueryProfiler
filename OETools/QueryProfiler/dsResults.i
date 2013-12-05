
/*------------------------------------------------------------------------
    File        : dsResults.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Thu Dec 05 20:10:36 GMT 2013
    Notes       :
  ----------------------------------------------------------------------*/


DEFINE {1} DATASET dsResults
FOR ttSearch, ttIndexSearchField
DATA-RELATION FOR ttSearch, ttIndexSearchField RELATION-FIELDS (SearchNumber, SearchNumber).