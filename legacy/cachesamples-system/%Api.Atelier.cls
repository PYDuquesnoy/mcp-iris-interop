/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Routing class for the Atelier REST services
Class %Api.Atelier Extends %Atelier.REST
{

/// Specifies the default character set for the page.  This can be overriden using the
/// &lt;CSP:CONTENT CHARSET=&gt; tag, or by setting the <b>%response</b>.CharSet property
/// in the <method>OnPreHTTP</method> method.  If this parameter is not specified, then
/// for the default charset is utf-8.
Parameter CHARSET = "utf-8";

/// Specifies if input %request.Content or %request.MimeData values are converted from their
/// original character set on input. By default (0) we do not modify these and receive them
/// as a binary stream which may need to be converted manually later. If 1 then if there
/// is a 'charset' value in the request Content-Type or mime section we will convert from this
/// charset when the input data is text based. For either json or xml data with no charset
/// this will convert from utf-8 or honor the BOM if one is present.
Parameter CONVERTINPUTSTREAM = 1;

/// Specifies the default content type for the page.  This can be overriden using the
/// &lt;CSP:CONTENT TYPE=&gt; tag, or by setting the <b>%response</b>.ContentType property
/// in the <method>OnPreHTTP</method> method.  The default value if this parameter is
/// not set is text/html.
Parameter CONTENTTYPE = "application/json";

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest = 1;

/// This parameter controls the CSP session support. By default the CSP session will be
/// ended after each request in accordance with the spirit of REST. However this CAN be
/// overridden by the user. To use a session, it's necessary to manage the CSPSESSION cookie.
/// Browsers do this automatically but command line tools such as CURL require the setting of
/// options.<p>
/// Note that if you choose to use a session then this will use a CSP license until the session
/// is ended or expires and the grace period has been satisfied. If you use the default of no
/// session then this will be the same behavior as SOAP requests of holding a license for ten
/// seconds.
Parameter UseSession As Integer = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<!-- Ping Server -->
<Route Url="/" Method="HEAD" Call="HeadServer"/>

<!-- Get information about the server -->
<Route Url="/" Method="GET" Call="GetServer"/>

<Map Prefix="/v1" Forward="%Api.Atelier.v1"/>
<Map Prefix="/v2" Forward="%Api.Atelier.v2"/>
<Map Prefix="/v3" Forward="%Api.Atelier.v3"/>
<Map Prefix="/v4" Forward="%Api.Atelier.v4"/>
<Map Prefix="/v5" Forward="%Api.Atelier.v5"/>
<Map Prefix="/v6" Forward="%Api.Atelier.v6"/>
<Map Prefix="/v7" Forward="%Api.Atelier.v7"/>
<Map Prefix="/v8" Forward="%Api.Atelier.v8"/>

</Routes>
}

/// This method gets called prior to dispatch of the request. Put any common code here
/// that you want to be executed for EVERY request. If pContinue is set to 0, the
/// request will NOT be dispatched according to the UrlMap. In this case it's the
/// responsibility of the user to return a response.
/// 
/// HTTP Codes returned:-
/// 
/// HTTP 406 will be returned if the Accepts header does not contain */* or application/json
/// HTTP 404 will be returned in the namespace specified does not exist
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status [ Internal ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tAccepts,tNamespace,tNamespaceList As %String
    
    Try {
        
        #; MUST unlock the session
        Do %session.Unlock()
        
        #; /v1/%SYS/metadata/IRISSYS"
        If $Piece(pUrl,"/",4)="metadata" {
            
            #; Mainly, we are only providing json, so check accepts header
            If ('..AcceptsContentType("application/octet-stream")) {
                Set tSC=..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE),pContinue=0
                Quit
                
            } else {
                
                #; We are returning a octet stream in this instance
                Set %response.ContentType="application/octet-stream"
            }
            
        } else {
        
            #; Mainly, we are only providing json, so check accepts header
            If ('..AcceptsContentType("application/json")) {
                    
                Set tSC=..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE),pContinue=0
                Quit
                
            } else {
                
                #; We always return json
                Set %response.ContentType="application/json"
            }
        }
        
        #; This is a bit of a hack, we have to insist that the third piece of the 
        #; url is the namespace, but so be it ...
        If pUrl="/" {
            Set tNamespace="%SYS"
        } else {
            Set tNamespace=$Piece(pUrl,"/",3)
            If $E(tNamespace)="^" Set tNamespace=$Tr(tNamespace,"#","/")
        }
        
        Try {
            
            #; Need to change to appropriate namespace here
            If tNamespace'=$namespace Set $namespace=tNamespace
            
        } Catch (e) {
            Set %response.Status=..#HTTP404NOTFOUND,pContinue=0 
            Quit
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status [ Internal ]
{
    #; This is always entered in namespace %SYS.
    #; We do no checks here, relying on the user and application to be defined
    #; with appropriate resources. Any access failures will be reported by the
    #; individual api routines.
    
    Set pAuthorized=1
    Quit $$$OK
}

/// This method returns information about the server.
/// 
/// GET http://localhost:57772/api/atelier/
/// 
/// HTTP Codes returned:-
/// 
/// HTTP 200 if OK
/// HTTP 500 if an error occurs (details will be in status error array)
/// 
/// Returned content is a server descriptor.
/// 
/// {
///   "status": {
///     "errors": [],
///     "summary": ""
///   },
///   "console": [],
///   "result": {
///     "content": {
///       "version": "IRIS for UNIX (Apple Mac OS X for x86-64) 2081.1 (Build 513U) Fri Jan 26 2018 18:21:02 EST",
///       "id": "6D1CB774-B314-11E5-888C-38C986213273",
///       "api": 1,
///       "features": [
///         {
///           "name": "ENSEMBLE",
///           "enabled": true
///         }
///       ],
///       "namespaces": [
///         "%SYS",
///         "DOCBOOK",
///         "ENSDEMO",
///         "ENSEMBLE",
///         "SAMPLES",
///         "USER"
///       ]
///     }
///   }
/// }
/// 
ClassMethod GetServer() As %Status
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tContent,tFeature,tNS,tNSArray,tResult As %DynamicObject
    
    Set tResult = {}
    
    Try {
        
        Set tContent = {}
        Set tContent.version=$ZV,
            tContent.id=##class(%SYS.System).InstanceGUID()
        
        #; Important, this is the API level supported by THIS server
        Set tContent.api=8
        
        #; Features
        Set tContent.features = []
       
        Set tFeature = {}
        Set tFeature.name="DEEPSEE"
        Do tFeature.%Set("enabled",##class(%DeepSee.Utils).%IsDeepSeeEnabled() ,"boolean")
        
        Do tContent.features.%Push(tFeature)
        
        Set tFeature = {}
        Set tFeature.name="ENSEMBLE"
        Do tFeature.%Set("enabled",##class(%EnsembleMgr).IsEnsembleInstalled() ,"boolean")
        
        Do tContent.features.%Push(tFeature)
        
        Set tFeature = {}
        Set tFeature.name="HEALTHSHARE"
        Do tFeature.%Set("enabled",##class(%EnsembleMgr).IsHealthShareInstalled() ,"boolean")
        
        Do tContent.features.%Push(tFeature)

        #; Namespaces  
        Do ##class(%Atelier.v1.Utils.General).AccessibleNamespaces(.tNSArray)

        Set tContent.namespaces = []
        Set tNS="" For  {
            Set tNS=$Order(tNSArray(tNS)) If tNS="" Quit
            Do tContent.namespaces.%Push(tNS)
        }
        
        Set tResult.content=tContent
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit ..RenderResponseBody(tSC,,tResult)
}

/// This method returns information about the server.
/// 
/// HEAD http://localhost:57772/api/atelier/
/// 
/// HTTP Codes returned:-
/// 
/// HTTP 200 if OK
/// HTTP 500 if an error occurs (details will be in status error array)
/// 
/// No returned content
ClassMethod HeadServer() As %Status
{
    Quit $$$OK
}

}
