/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>A test for invoking commands from an AutoPage.
Class %CSP.Util.TableForm Extends (%RegisteredObject, AutoForm) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Set this to 1 for command forms...
Parameter COMMANDFORM = 1;

Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
        // pID contains $ID values from URL
        If (pSubmit = "$AUTOFORM_PURGE") {
	        If $G(pID(1))'="",$G(pID(2))'="" {
	        	Do ##class(%SQL.Manager.API).PurgeQueriesForTable(pID(1)_"."_pID(2))
	        }
        }
        ELseIf (pSubmit = "$AUTOFORM_DROP") {
	        If $G(pID(1))'="",$G(pID(2))'="" {
	        	Do ##class(%SQL.Manager.API).DropTable(pID(1)_"."_pID(2), "TABLE", .SQLCODE, .%msg)
				If SQLCODE '= 0 {
					Write !,"SQLCODE = " + SQLCODE + %msg
				} Else {
					//Draw Tables page	
				}
	        }   
        }

        Quit $$$OK
}

ClassMethod OnDefineButtons(ByRef pButtons As FormButton)
{
        Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
        Set pButtons(1).Name = "$AUTOFORM_OPEN"
        Set pButtons(1).Caption = "Open Table"
        Set pButtons(1).HREF = "UtilSqlOpenTable.csp"
        Set pButtons(1).Type = "popup"

        Set pButtons(2) = ##class(%CSP.Util.FormButton).%New()
        Set pButtons(2).Name = "$AUTOFORM_PURGE"
        Set pButtons(2).Caption = "Purge Queries"
        Set pButtons(2).Confirm = "Are you sure you want to purge all queries for this table?"

        Set pButtons(3) = ##class(%CSP.Util.FormButton).%New()
        Set pButtons(3).Name = "$AUTOFORM_REBUILD"
        Set pButtons(3).Caption = "Rebuild Indices"
        Set pButtons(3).HREF = "UtilSqlRebuildIndices.csp"
        Set pButtons(3).Type = "popup"

        Set pButtons(4) = ##class(%CSP.Util.FormButton).%New()
        Set pButtons(4).Name = "$AUTOFORM_TUNETABLE"
        Set pButtons(4).Caption = "Tune Table"
        Set pButtons(4).Confirm = "This function has not been completed yet."
        Set pButtons(4).HREF = "UtilSqlTuneTable.csp"
        Set pButtons(4).Type = "popup"

        Set pButtons(5) = ##class(%CSP.Util.FormButton).%New()
        Set pButtons(5).Name = "$AUTOFORM_DROP"
        Set pButtons(5).Caption = "Drop Table"
        Set pButtons(5).Confirm = "Are you sure you want to drop this table?"

      //  Set pButtons(6) = ##class(%CSP.Util.FormButton).%New()
      //  Set pButtons(6).Name = "$AUTOFORM_DOC"
      //  Set pButtons(6).Caption = "Show Documentation"
      //  Set pButtons(6).Type = "popup"
}

}
