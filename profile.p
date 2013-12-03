
DEFINE VARIABLE gLineNumber AS INTEGER    NO-UNDO INITIAL ?.

DEFINE TEMP-TABLE ttLine NO-UNDO

    FIELD LineNumber AS INTEGER
    FIELD LineText   AS CHARACTER

        INDEX PriKey IS PRIMARY UNIQUE LineNumber DESCENDING.


DEFINE TEMP-TABLE ttSearch NO-UNDO
    FIELD SearchNumber  AS INTEGER
    FIELD SearchTable   AS CHARACTER FORMAT "x(30)"
    FIELD SearchIndex   AS CHARACTER FORMAT "x(30)"

    FIELD MainFile      AS CHARACTER
    FIELD SecondaryFile AS CHARACTER
    FIELD LineNumber    AS INTEGER

    FIELD IndexQuality  AS INTEGER INITIAL 0

        INDEX PriKey    IS PRIMARY UNIQUE SearchNumber ASCENDING
        INDEX FileOrder                   LineNumber   ASCENDING.


DEFINE TEMP-TABLE ttSearchField NO-UNDO
    FIELD SearchNumber      AS INTEGER
    FIELD SearchFieldNumber AS INTEGER
    FIELD FieldName         AS CHARACTER FORMAT "x(30)"

        INDEX PriKey IS PRIMARY UNIQUE SearchNumber ASCENDING SearchFieldNumber DESCENDING.



DEFINE TEMP-TABLE ttIndexSearchField NO-UNDO

    FIELD SearchNumber        AS INTEGER
    FIELD ListOrder           AS INTEGER   INITIAL 0

    FIELD SearchFieldNumber   AS INTEGER   INITIAL ?
    FIELD IndexSequenceNumber AS INTEGER   INITIAL ?

    FIELD IndexFieldName      AS CHARACTER INITIAL ? FORMAT "x(30)"
    FIELD SearchFieldName     AS CHARACTER INITIAL ? FORMAT "x(30)"

        INDEX PriKey IS PRIMARY /*UNIQUE*/ SearchNumber ASCENDING ListOrder         ASCENDING
        INDEX SFKey                    SearchNumber ASCENDING SearchFieldNumber DESCENDING
        INDEX idxKey                   SearchNumber ASCENDING IndexFieldName    ASCENDING.

RUN Main NO-ERROR.

IF ERROR-STATUS:ERROR THEN
DO:
    MESSAGE "Line Number: " gLineNumber.
    MESSAGE RETURN-VALUE.
END.


PROCEDURE Main :

    DO ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

        RUN ReadFile.
        RUN ProcessFile.
        RUN ProcessIndexes.
        RUN DumpAnalysis.

    END.

END.
/*
FOR EACH ttSearch NO-LOCK:

    DISPLAY ttSearch.

    FOR EACH ttSearchField OF ttSearch NO-LOCK:

        DISPLAY ttSearchField.
    END.

    FOR EACH ttIndexSearchField OF ttSearch NO-LOCK:

        DISPLAY ttIndexSearchField.

    END.
END.
*/


PROCEDURE ReadFile :

    DEFINE VARIABLE vLineNumber AS INTEGER    NO-UNDO INITIAL 1.
    DEFINE VARIABLE vLine       AS CHARACTER  NO-UNDO.

    DO ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

        INPUT FROM VALUE(SESSION:PARAMETER).

        REPEAT:

            IMPORT UNFORMATTED vLine.

            CREATE ttLine.

            ASSIGN ttLine.LineNumber = vLineNumber
                   ttLine.LineText   = vLine
                   vLineNumber       = vLineNumber + 1
                   gLineNumber       = vLineNumber.

        END.

        INPUT CLOSE.

    END.

END PROCEDURE.


PROCEDURE ProcessFile :

    DEFINE VARIABLE vMainFile      AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vSecondaryFile AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vLineNumber    AS INTEGER    NO-UNDO.
    DEFINE VARIABLE vVerb          AS CHARACTER  NO-UNDO.

    DEFINE VARIABLE vSearchNumber      AS INTEGER    NO-UNDO INITIAL 0.
    DEFINE VARIABLE vSearchFieldNumber AS INTEGER    NO-UNDO.

    DO ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

        FOR EACH ttLine
              BY ttLine.LineNumber DESCENDING
              ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

            /* Set LineNumber */
            ASSIGN gLineNumber = ttLine.LineNumber.

            /* There must be at least 6 entries on this line for us to process it */
            IF NUM-ENTRIES(ttLine.LineText, " ") < 6 THEN NEXT.

            /* Interpret the parameters of the line */
            ASSIGN vMainFile      = ENTRY(1, ttLine.LineText, " ")
                   vSecondaryFile = ENTRY(2, ttLine.LineText, " ")
                   vLineNumber    = INTEGER(ENTRY(3, ttLine.LineText, " "))
                   vVerb          = ENTRY(4, ttLine.LineText, " ").


            IF vVerb = "SEARCH" THEN
            DO:
                ASSIGN vSearchNumber      = vSearchNumber + 1
                       vSearchFieldNumber = 1.

                CREATE ttSearch.

                ASSIGN ttSearch.SearchNumber  = vSearchNumber
                       ttSearch.SearchTable   = ENTRY(5, ttLine.LineText, " ")
                       ttSearch.SearchIndex   = ENTRY(6, ttLine.LineText, " ")
                       ttSearch.MainFile      = vMainFile
                       ttSearch.SecondaryFile = vSecondaryFile
                       ttSearch.LineNumber    = vLineNumber.

            END.
            ELSE IF vVerb = "ACCESS" THEN
            DO:
                /* Could be that last line of file is not "SEARCH" but "ACCESS", therefore there will be no ttSearch
                 * available - this is absolutely fine.
                 */
                /* It looks like, for each search, the line numbers are always the same between all the fields and the
                 * initial "SEARCH", so can use that for better comparison too
                 */
                IF AVAILABLE ttSearch AND ENTRY(5, ttLine.LineText, " ") = ttSearch.SearchTable AND vLineNumber = ttSearch.LineNumber THEN
                DO:
                    CREATE ttSearchField.

                    ASSIGN ttSearchField.SearchNumber      = ttSearch.SearchNumber
                           ttSearchField.SearchFieldNumber = vSearchFieldNumber
                           ttSearchField.FieldName         = ENTRY(6, ttLine.LineText, " ").

                    ASSIGN vSearchFieldNumber = vSearchFieldNumber + 1.
                END.
            END.
        END.

    END.

END PROCEDURE.


PROCEDURE ProcessIndexes :

    DEFINE VARIABLE vListOrder AS INTEGER    NO-UNDO.

    DO ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

        FOR EACH ttSearch NO-LOCK
              BY ttSearch.LineNumber
              ON ERROR UNDO, RETURN ERROR RETURN-VALUE:


            /* Find the database table */
            FIND FIRST _file
                 WHERE _file._file-name = ENTRY(2, ttSearch.SearchTable, ".")
                       NO-LOCK NO-ERROR.

            IF NOT AVAILABLE _file THEN
            DO:
                NEXT.
            END.

            FIND FIRST _index
                    OF _file
                 WHERE _index._index-name = ttSearch.SearchIndex
                       NO-LOCK NO-ERROR.

            IF NOT AVAILABLE _index THEN
            DO:
                NEXT.
            END.

            FOR EACH ttSearchField
               WHERE ttSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttSearchField.SearchNumber
                  BY ttSearchField.SearchFieldNumber DESCENDING
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

                CREATE ttIndexSearchField.

                ASSIGN ttIndexSearchField.SearchNumber      = ttSearchField.SearchNumber
                       ttIndexSearchField.SearchFieldNumber = ttSearchField.SearchFieldNumber
                       ttIndexSearchField.SearchFieldName   = ttSearchField.FieldName.

            END.


            /* Now iterate through all the fields in the index, and match them back to the table fields */
            FOR EACH _index-field NO-LOCK
                  OF _index,

               FIRST _field NO-LOCK
                  OF _index-field
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

                FIND FIRST ttIndexSearchField
                     WHERE ttIndexSearchField.SearchNumber    = ttSearch.SearchNumber
                       AND ttIndexSearchField.SearchFieldName = _field._field-name
                           EXCLUSIVE-LOCK NO-ERROR.

                /* Create if it does not exist */
                IF NOT AVAILABLE ttIndexSearchField THEN
                DO:
                    CREATE ttIndexSearchField.

                    ASSIGN ttIndexSearchField.SearchNumber   = ttSearch.SearchNumber.
                END.

                ASSIGN ttIndexSearchField.IndexFieldName      = _field._field-name
                       ttIndexSearchField.IndexSequenceNumber = _index-field._index-seq.

            END.

            /* List order should be the index order, for the moment, until I can work out the right way to do this! */
            ASSIGN vListOrder = 1.

            FOR EACH ttIndexSearchField EXCLUSIVE-LOCK
               WHERE ttIndexSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttIndexSearchField.IndexSequenceNumber
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

                ASSIGN ttIndexSearchField.ListOrder = vListOrder
                       vListOrder                   = vListOrder + 1.

            END.

        END.

    END.

END PROCEDURE.


PROCEDURE DumpAnalysis :

    DO ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

        OUTPUT TO VALUE(SESSION:PARAMETER + ".analysis") UNBUFFERED.

        FOR EACH ttSearch NO-LOCK
              BY ttSearch.LineNumber:

            PUT UNFORMATTED 
                "Primary File: " ttSearch.MainFile SKIP
                "Secondary File: " ttSearch.SecondaryFile SKIP
                "SEARCH LineNumber: " ttSearch.LineNumber " Table: " ttSearch.SearchTable " Index: " ttSearch.SearchIndex " Search Quality: " ttSearch.IndexQuality SKIP.

            FOR EACH ttIndexSearchField EXCLUSIVE-LOCK
               WHERE ttIndexSearchField.SearchNumber = ttSearch.SearchNumber
                  BY ttIndexSearchField.SearchNumber
                  BY ttIndexSearchField.ListOrder
                  ON ERROR UNDO, RETURN ERROR RETURN-VALUE:

                PUT "~t"
                    (IF ttIndexSearchField.SearchFieldName = ? THEN "" ELSE ttIndexSearchField.SearchFieldName) FORMAT "x(40)"
                    "=>~t"
                    (IF ttIndexSearchField.IndexFieldName = ?  THEN "" ELSE ttIndexSearchField.IndexFieldName ) FORMAT "x(40)" SKIP.

            END.

            PUT UNFORMATTED SKIP(1).
                

        END.
            

        OUTPUT CLOSE.

    END.

END PROCEDURE.
