/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Routing class for the DeepSee REST services
Class %Api.DeepSee Extends %CSP.REST
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
 <Map Prefix="/v1/:namespace" Forward="%DeepSee.REST.v1"/>
 <Map Prefix="/v2/:namespace" Forward="%DeepSee.REST.v2"/>
 <Map Prefix="/v3/:namespace" Forward="%DeepSee.REST.v3"/>
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
		// DTB278 - switch to the namespace named in the URL
		
		// Insist that the first piece of the url is a version
		Set tVersion = $Piece(pUrl,"/",2)
		If (("v1"'[tVersion) && ("v2"'[tVersion) && ("v3"'=tVersion)) {
			Set tSC = $$$ERROR($$$dsRESTInvalidVersion,tVersion)
			Quit
		}
		
		// Insist that the second piece of the url is a valid namespace and switch to it
		Set tNamespace=$Piece(pUrl,"/",3)
		
		// Ensure that the specified namespace exists and is enabled
		If (tNamespace="") || '##class(%SYS.Namespace).Enabled(tNamespace) {
			Set tSC = $$$ERROR($$$dsRESTInvalidNamespace)
			Quit
		}
		
		// Prefer changing into the appropriate namespace here
		If (tNamespace'=$namespace) Set $namespace=tNamespace
		
		// DTB307 - Set the return type according to the Accept type in the request. Default is application/json.
		If ('..AcceptsContentType(..#CONTENTTYPEJSON)) {
			Set tSC=..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE),pContinue=0
			Quit 
        } 
        Else {   
			// This always returns json
			Set %response.ContentType=..#CONTENTTYPEJSON
        }

		// De-escalate privileges back to the user's login privileges now that 
		// namespace redirection is complete
		$$$ResetToLoginRoles
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set pContinue = 0
		Do ##class(%DeepSee.REST.REST).%ErrorToJSON(tSC)
	}

	Quit $$$OK
}

/// This method performs a basic access check. You can override this to add additional checks
ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status
{
	// Method overridden by DTB484
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tAccess As %String
    
    Try {
        // DTB484 - Always allow access through the application
        Set pAuthorized=1
    } catch (e) {
        Set tSC=e.AsStatus()
    }
    Quit tSC
}

}
