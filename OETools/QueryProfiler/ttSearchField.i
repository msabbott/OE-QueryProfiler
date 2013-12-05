DEFINE {1} TEMP-TABLE ttSearchField NO-UNDO
    FIELD SearchNumber      AS INTEGER
    FIELD SearchFieldNumber AS INTEGER 
    FIELD FieldName         AS CHARACTER FORMAT "x(30)"
        INDEX PriKey IS PRIMARY UNIQUE SearchNumber ASCENDING SearchFieldNumber DESCENDING.
