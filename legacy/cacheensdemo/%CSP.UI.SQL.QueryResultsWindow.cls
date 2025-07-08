/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Popup window that display an SQL Query builder form.
Class %CSP.UI.SQL.QueryResultsWindow Extends %CSP.Util.AutoPagePopup [ System = 4 ]
{

Parameter PAGENAME = "SQL Query Results";

Parameter USENAMESPACE = 1;

/// Ensure user has %Development:USE.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '$system.Security.Check($$$DevelopmentResourceName,"USE") Quit 0
	Quit ##super()
}

ClassMethod GetDetailPane(pInstance As PageInstance) As Pane
{
	Set tDetailPane = ""
	
	// don't show if we are the popup outer frame
	If $D(%request.Data("$FRAME")) {
		Set tDetailPane = ##class(%CSP.UI.SQL.QueryPane).%New()
		Set tDetailPane.ShowRowNumbers = 1
		Set tDetailPane.ShowZebra = 1
	}

	Quit tDetailPane
}

}
