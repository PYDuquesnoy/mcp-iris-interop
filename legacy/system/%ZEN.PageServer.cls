/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// Special CSP class used by the Zen Page Editor.
Class %ZEN.PageServer Extends %CSP.Page [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Event handler for <b>PreHTTP</b> event:
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	#; Make sure current user holds Developer privilege
	If ('$System.Security.Check("%Development","USE")) {
		Set %response.ContentType="text/html"
		Quit 1
	}

	#; find class name
	Set tClass = $G(%request.Data("$CLASS",1))

	#; create page object from XML
	Set %page = ..%CreatePage(tClass)
}

/// Create a page object from its XML definition.
ClassMethod %CreatePage(pClass As %String) As %ZEN.Component.page
{
	Set tPage = ""



	Quit tPage
}

}
