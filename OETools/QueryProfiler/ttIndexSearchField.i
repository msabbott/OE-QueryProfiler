
DEFINE {1} TEMP-TABLE ttIndexSearchField NO-UNDO

    FIELD SearchNumber        AS INTEGER
    FIELD ListOrder           AS INTEGER   INITIAL 0
   
    FIELD SearchFieldNumber   AS INTEGER   INITIAL ?
    FIELD IndexSequenceNumber AS INTEGER   INITIAL ?
    
    FIELD IndexFieldName      AS CHARACTER INITIAL ? FORMAT "x(30)"
    FIELD SearchFieldName     AS CHARACTER INITIAL ? FORMAT "x(30)"
    
    INDEX PriKey IS PRIMARY SearchNumber ASCENDING ListOrder         ASCENDING
    INDEX SFKey             SearchNumber ASCENDING SearchFieldNumber DESCENDING
    INDEX idxKey            SearchNumber ASCENDING IndexFieldName    ASCENDING.