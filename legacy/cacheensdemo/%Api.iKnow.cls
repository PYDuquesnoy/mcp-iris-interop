/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// Routing class for iKnow REST API
Class %Api.iKnow Extends %CSP.REST [ Deprecated, System = 4 ]
{

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies the default content type for the page.  This can be overriden using the
/// &lt;CSP:CONTENT TYPE=&gt; tag, or by setting the <b>%response</b>.ContentType property
/// in the <method>OnPreHTTP</method> method.  The default value if this parameter is
/// not set is text/html.
Parameter CONTENTTYPE = "application/json";

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest = 1;

XData UrlMap
{
<Routes>
 <Map Prefix="/v1/:namespace" Forward="%iKnow.REST.v1"/>
 <Map Prefix="/v1.0/:namespace" Forward="%iKnow.REST.v1"/>
 <Map Prefix="/v1.1/:namespace" Forward="%iKnow.REST.v1dot1"/>
 
 <!-- when bumping the latest version, also update the corresponding parameter in %iKnow.REST.Base -->
 <Map Prefix="/latest/:namespace" Forward="%iKnow.REST.v1dot1"/>
</Routes>
}

/// This method Gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. If this case it's the
/// responsibility of the user to return a response.
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		
		// Insist that the first piece of the url is a version
		Set tVersion = $Piece(pUrl,"/",2)
		If ("v1"'[tVersion) && (tVersion'="latest") {
			Set tSC = $$$ERROR($$$GeneralError,"Version is not supported by the /api/iKnow/ REST application:" _ tVersion)
			Quit
		}
		
		// Insist that the second piece of the url is a valid namespace and switch to it
		Set tNamespace=$Piece(pUrl,"/",3)
		
		// Ensure that the specified namespace exists and is enabled
		If (tNamespace="") || '##class(%SYS.Namespace).Enabled(tNamespace) {
			Set tSC = $$$ERROR($$$GeneralError,"Calls to the /api/iKnow/ REST application must provide a valid namespace")
			Quit
		}
		
		// Prefer changing into the appropriate namespace here
		If (tNamespace'=$namespace) Set $namespace=tNamespace

		// De-escalate privileges back to the user's login privileges now that 
		// namespace redirection is complete
		$$$ResetToLoginRoles
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	quit ##class(%iKnow.REST.Base).%ErrorHandler(tSC, .pContinue)
}

ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status
{
	// BDB746 - relevant access checks will be performed inside individual methods
    set pAuthorized=1
    quit $$$OK
}

}
