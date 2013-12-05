DEFINE {1} TEMP-TABLE ttSearch NO-UNDO
    FIELD SearchNumber  AS INTEGER
    FIELD SearchTable   AS CHARACTER FORMAT "x(30)"
    FIELD SearchIndex   AS CHARACTER FORMAT "x(30)"
    
    FIELD MainFile      AS CHARACTER
    FIELD SecondaryFile AS CHARACTER 
    FIELD LineNumber    AS INTEGER
    
    FIELD IndexQuality  AS INTEGER INITIAL 0
    
        INDEX PriKey    IS PRIMARY UNIQUE SearchNumber ASCENDING
        INDEX FileOrder                   LineNumber   ASCENDING.