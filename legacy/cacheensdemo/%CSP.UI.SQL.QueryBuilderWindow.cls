/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Popup window that display an SQL Query builder form.
Class %CSP.UI.SQL.QueryBuilderWindow Extends %CSP.Util.AutoPagePopup [ System = 4 ]
{

Parameter PAGENAME = "SQL Query Builder";

Parameter USENAMESPACE = 1;

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '$system.Security.Check($$$DevelopmentResourceName,"USE") Quit 0
	Quit ##super()
}

/// Get the details pane info object
ClassMethod GetDetailPane(pInstance As PageInstance) As Pane
{
	Set tDetailPane = ""
	
	// don't show if we are the popup outer frame
	If $D(%request.Data("$FRAME")) {
		Set tDetailPane = ##class(%CSP.UI.SQL.QueryBuilderPane).%New()
	}

	Quit tDetailPane
}

/// Define buttons displayed in footer bar
ClassMethod OnDefineButtons(ByRef pButtons As %CSP.Util.FormButton)
{
	Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(1).Name = "$AUTOFORM_OK"
	Set pButtons(1).Caption = $$$Text(" OK ")
	Set pButtons(1).OnClick = "btnOK();"

	Set pButtons(2) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(2).Name = "$AUTOFORM_EXECUTE"
	Set pButtons(2).Caption = $$$Text("Execute Query")
	Set pButtons(2).OnClick = "window.frames[0].executeSQL();"

	Set pButtons(3) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(3).Name = "$AUTOFORM_CANCEL"
	Set pButtons(3).Caption = $$$Text("Cancel")
	Set pButtons(3).OnClick = "btnCancel();"
}

}
