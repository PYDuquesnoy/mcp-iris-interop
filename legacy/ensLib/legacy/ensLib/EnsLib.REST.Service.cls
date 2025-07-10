/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// REST Service class. Can use an HTTP InboundAdapter listener, or the standard CSP Service mechanism, or both.
/// In order for the CSP mechanism to work, HTTP Services using this class must be configured with the invoking URL including ?CfgItem= giving the config item name.
/// (Configured Services exposed using the HTTP Inbound Adapter may also be invoked with this URL parameter but because
///  each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.REST.Service Extends (EnsLib.HTTP.Service, %CSP.REST, Ens.Util.JSON) [ Abstract, System = 4 ]
{

Parameter ADAPTER = "EnsLib.HTTP.InboundAdapter";

/// This prefix will be removed from the beginning of the actual URL before matching it against the UrlMap.
/// If this prefix begins with '^' then the CSP Application will also be removed from the beginning of the URL if this service is being invoked via the CSP gateway.
/// If this prefix begins with '|' then the Config Name for this service will be removed from the beginning of the URL, as well as the CSP Application if this service is being invoked via the CSP gateway.
Parameter EnsServicePrefix As STRING;

Parameter PREFIXCASESENSITIVE As BOOLEAN = 0;

ClassMethod Page(skipheader As %Boolean = 1) As %Status [ Final, ProcedureBlock = 0 ]
{
	#; We do not want the session token
	Set %response.OutputSessionToken=(''..#UseSession)

	#; For this REST service we do not want the %CSP.REST implementation of Page(); go right to the super-superclass
	Quit ##class(EnsLib.HTTP.Service).Page(skipheader)
}

/// Override this method in your subclass if you want to handle dispatching yourself.
/// This implementation paraphrases the %CSP.REST:DispatchRequest() implementation with modifications to support the input and output streams used by the HTTP Adapter.
Method OnProcessInput(pInput As %Library.AbstractStream, Output pOutput As %Stream.Object = {$$$NULLOREF}) As %Status
{
	#Dim tMethod, tURL, tApp, tCfg As %String = ""
	Set tMethod=$ZConvert(pInput.GetAttribute("HttpRequest"),"U")
	Set tURL=pInput.GetAttribute("URL") ; don't URL-decode because that could mess up the parse into '/' pieces
	Set tApp=pInput.GetAttribute("CSPApplication")
	Set tCfg=pInput.GetAttribute("EnsConfigName")

	Set tService=..#EnsServicePrefix, tPre1=$E(tService)
	If tPre1="^" {
		#; strip Application from URL, if any
		Set:(""'=tApp)&&$S(..#PREFIXCASESENSITIVE:(tApp=$E(tURL,1,$L(tApp))), 1:($ZCVT(tApp,"L")=$ZCVT($E(tURL,1,$L(tApp)),"L")))&&("/"=$E(tApp,*)) tURL=$E(tURL,$L(tApp),*)
		Set $E(tService,1)=""
	} ElseIf tPre1="|" {
		#; strip Application and ConfigName from URL, if any
		If ""=tApp { Set:""'=tCfg tCfg="/"_tCfg_"/" } Else { Set tCfg=$S(""=tCfg:tApp, 1:tApp_tCfg_"/") }
		Set:(""'=tCfg)&&$S(..#PREFIXCASESENSITIVE:(tCfg=$E(tURL,1,$L(tCfg))), 1:($ZCVT(tCfg,"L")=$ZCVT($E(tURL,1,$L(tCfg)),"L"))) tURL=$E(tURL,$L(tCfg),*)
		Set $E(tService,1)=""
	}
	Set:"*"=tService tService=""  Set:"/"'=$E(tService,1) tService="/"_tService  Set:"/"'=$E(tService,*) tService=tService_"/"
	Set:'..#PREFIXCASESENSITIVE tService=$ZCVT(tService,"L")
	Set tURLPrefix=$E(tURL,1,$L(tService))
	Set:'..#PREFIXCASESENSITIVE tURLPrefix=$ZCVT(tURLPrefix,"L")
	If tService'=tURLPrefix {
		Quit $$$ERROR($$$EnsErrGeneral,"Service "_tURLPrefix_" does not match supported service prefix "_tService_".")
	}
	Set $E(tURL,1,$L(tService)-1)=""

	#; Ensure that any query string is not taken into account
	Set tMatchUrl=$Piece(tURL,"?")

	#; Save local variables so super class classmethods can have access to them
	Set $$$EnsJobLocal("REST.Svc")=$this, $$$EnsJobLocal("REST.InStream")=pInput
	Try {
		#; Modified code from %CSP.REST
		Set tContinue=1, tSC=..OnPreDispatch(tMatchUrl,tMethod,.tContinue)
		Quit:$$$ISERR(tSC)

		#; It's the user's responsibility to return the response in OnPreDispatch() if Continue = 0
		Quit:'tContinue

		#; marshall the standard arguments
		Set tArgs=0
		Set tArgs($I(tArgs))=pInput
		Set pOutput=##class(%GlobalBinaryStream).%New()
		Set tArgs($I(tArgs))=pOutput
		Set $$$EnsJobLocal("REST.OutStream")=pOutput
		
		#; route = $listbuild(type,call,class,CORS)
		Set tRoute = ..DispatchMap(tURL,tMethod,.tVerbsMatched,.tArgs)
		If tRoute'="" {
			#; If we are a simple route
			If $list(tRoute,1)="R" {
				#; Support OPTIONS VERB (cannot be overriden)
				If tMethod="OPTIONS" {
					$$$ThrowOnError(..OnHandleOptionsRequest(tURL))
					#; Dispatch CORS
					$$$ThrowOnError(..ProcessCorsRequest(tURL,$list(tRoute,4) /* CORS */))
				} Else {                
					#; Dispatch CORS
					$$$ThrowOnError(..ProcessCorsRequest(tURL,$list(tRoute,4) /* CORS */))
										
					#; Check for optional ClassName prefix
					Set tCall = $list(tRoute,2) /* call */
					Set tInstance = 0
					If tCall[":" {
						Set tClass = $Piece(tCall,":",1)
						Set tTarget = $Piece(tCall,":",2)
					} Else {
						Set tClass = $list(tRoute,3) /* class */
						Set tTarget = tCall
						Set tInstance = (tClass=$classname())
					}
					
					#; If writes are to be ignored, then set flag in %response
					If ..#IgnoreWrites Set %response.IgnoreRESTOutput=1
					
					#; Dispatch
					If tInstance {
						Set tSC = $method($this,tTarget,tArgs...)	
					} Else {
						Set tSC = $classmethod(tClass,tTarget,tArgs...)
					}
				}
			} Else { // type = "M"
				#; We found a Map, but OnPreDispatch() for the target class returned 0.
				#; Terminate processing, as above.
				Quit
			}
		} Else { // No Route
			If tVerbsMatched="" {
				#; No match for the resource, report not found
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Unsupported REST URL: "_tMatchUrl_" for HTTP command "_tMethod)  Quit
			} Else {
				#; Had a match for resource but method not matched
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Unsupported HTTP command "_tMethod_" for REST URL: "_tMatchUrl)  Quit
			}
		}
 	} Catch e {
		Set tSC = e.AsStatus()
	}
	#; Remove the local stream references; the service host reference can stay for now
	Kill $$$EnsJobLocal("REST.InStream"), $$$EnsJobLocal("REST.OutStream")
	Quit tSC
}

/// Handle an OPTIONS request for this CSP application
ClassMethod HandleDefaultOptionsRequest(pURL As %String) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	try {
		#; No content
		Set outStream = $$$EnsJobLocal("REST.OutStream")
		Set outStream.Attributes("Content-Type")=""
		Set tSC=..SupportedVerbs(pURL,.supportedVerbs)  Quit:$$$ISERR(tSC)
		Set outStream.Attributes("Allow")=supportedVerbs
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// Provide reasonable default handling for a CORS-enabled request for those who 'JUST WANT IT TO WORK'
ClassMethod HandleDefaultCorsRequest(pURL As %String) As %Status [ Internal, Private ]
{
	Set tSC = $$$OK
	try {
		// Get the origin
		Set inStream = $$$EnsJobLocal("REST.InStream")
		Set outStream = $$$EnsJobLocal("REST.OutStream")
		Set origin=$Get(inStream.Attributes("Origin"))
		If origin'="" {
			// Allow requested origin
			Set:""=$Get(outStream.Attributes("Access-Control-Allow-Origin")) outStream.Attributes("Access-Control-Allow-Origin") = origin

			// Set Allow-Credentials to true
			Set:""=$Get(outStream.Attributes("Access-Control-Allow-Credentials")) outStream.Attributes("Access-Control-Allow-Credentials") = "true"
		}
		// Allow requested headers
		Set headers=$Get(inStream.Attributes("Access-Control-Request-Headers"))
		Set:""=$Get(outStream.Attributes("Access-Control-Allow-Headers")) outStream.Attributes("Access-Control-Allow-Headers") = headers

		// Allow requested method
		Set method=$Get(inStream.Attributes("Access-Control-Request-Method"))
		Set:""=$Get(outStream.Attributes("Access-Control-Allow-Methods")) outStream.Attributes("Access-Control-Allow-Methods") = method
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// Issue a '405' error ( user can override)
ClassMethod Http405(pSupportedVerbs As %String = "") As %Status
{
	Set outStream = $$$EnsJobLocal("REST.OutStream")
	Set outStream.Attributes("ResponseCode")=..#HTTP405METHODNOTALLOWED
	Set outStream.Attributes("Allow")=pSupportedVerbs
	Set outStream.Attributes("Content-Type")=""
	Quit $$$OK
}

/// Issue an HTTP error
ClassMethod ReportHttpStatusCode(pHttpStatus, pSC As %Status = {$$$OK}) As %Status
{
		//Set %response.Status=pHttpStatus
	Set outStream = $$$EnsJobLocal("REST.OutStream")
	Set outStream.Attributes("ResponseCode")=pHttpStatus
	If $$$ISERR(pSC) {
		Set outStream.Attributes("Content-Type")=..#CONTENTTYPEJSON
		Set tSC = ..StatusToProxyObject(pSC, .tJSON)  Quit:$$$ISERR(tSC) tSC
		Set tSC = ##class(Ens.Util.JSON).ObjectToJSONStream(tJSON,outStream)  Quit:$$$ISERR(tSC) tSC
	}
	Quit $$$OK
}

}
