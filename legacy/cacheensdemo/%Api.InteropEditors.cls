/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Routing class for the InteropEditors REST services
/// Version can be specified in the end point or not.
/// Currently end points internal.
Class %Api.InteropEditors Extends %Api.InteropEditors.base.dispParent [ System = 4 ]
{

Parameter CHARSET = "utf-8";

Parameter CONVERTINPUTSTREAM = 1;

Parameter CONTENTTYPE = "application/json";

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest = 1;

Parameter UseSession As Integer = 0;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Map Prefix="/v1" Forward="%Api.InteropEditors.v1.disp"/>
<Map Prefix="/v2" Forward="%Api.InteropEditors.v2.disp"/>
<Map Prefix="/*" Forward="%Api.InteropEditors.v2.disp"/>
</Routes>
}

/// All routes are forwarded - leave OnPreDispatch and hence any namespace
/// adjustment to the OnPreDispatch of the forwarded disp class
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status [ Internal ]
{
    Quit $$$OK
}

}
