/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Generic HTTP Service based BusinessService class. Can use an HTTP InboundAdapter listener, or the standard CSP Service mechanism, or both.
/// In order for the CSP mechanism to work, HTTP Services using this class must be configured with the invoking URL including ?CfgItem= giving the config item name.
/// (Configured Services exposed using the HTTP Inbound Adapter may also be invoked with this URL parameter but because
///  each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.HTTP.GenericService Extends EnsLib.HTTP.Service [ System = 4 ]
{

Parameter DOCCLASS = "EnsLib.HTTP.GenericMessage";

/// Configuration item to which to send messages
Property TargetConfigName As Ens.DataType.ConfigName;

/// Store a set of searchable properties associated with each XML Document processed.<br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String;

/// Specifies types of Validation to perform.
/// Set to non-empty to invoke OnValidate() in your subclass. You may add it to SETTINGS in your subclass if you want to distinguish several types of validation.
Property Validation As %String;

Parameter SETTINGS = "TargetConfigName:Basic:selector?multiSelect=0&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},PersistInProcData:Additional,KeepCSPPartition:Additional,CSPNoCharSetConvert:Web Gateway Only,OneWay:Additional,CSPHeaderCharsetConvert:Web Gateway Only";

/// OneWay is true if no response is to be given.
/// If the request is queued successfully to the target an HTTP/1.1 202 Accepted will be returned.
Property OneWay As %Boolean;

/// Comma separated list of response HTTP Headers from the external systems not to be
/// passed back to the requesting service.
/// The values are case-insensitive.
/// The appropriate Content-Length will be used and ought not be specified here.
Property %ExcludeResponseHttpHeaders As %String(MAXLEN = "");

/// Set this to remove CSP inserted stream attributes (e.g. FileName, MimeSection)
/// Need these removed for generic.
Parameter REMOVECSPATTRIBS = 1;

/// Persist data to operations with invocation InProc that are called Synchronously.<br/>
/// The default is On. <br/>
/// This setting is only used if calling an operation with invocation InProc. <br/>
/// If this setting is off then no message headers will be created and message bodies will not be saved.<br/>
/// If this setting is off there will be no trace in the message viewer. <br/>
/// If this setting is off there will be no retry attempts by the operation - only one attempt will be made. <br/>
Property PersistInProcData As %Boolean [ InitialExpression = 1 ];

/// When calling the service through the CSP WebServer (Standard Request) and the target of the
/// service is a business operation invoked InProc then it is possible to attempt to maintain connection
/// to the external system defined in the operation in between messages by setting this to true.<br>
/// There is still the possibility that the external system will close the connection.<br/>
/// The default is On. <br/>
Property KeepCSPPartition As %Boolean [ InitialExpression = 1 ];

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	If ""=..TargetConfigName { $$$LOGWARNING("No Target Config Name configured") }
	Set $$$EnsInProcPersist=..PersistInProcData
	Quit ##super()
}

Method OnProcessInput(pRequestBody As %CharacterStream, pResponseBody As %CharacterStream, ByRef pAction As %String) As %Status
{
 #Dim tResponse As GenericMessage

	If $$$IsdefObject(%request) {
		#; If called from CSP, disable session and check if cached InProc object
		Set %session.UseSessionCookie=0
		Set %response.OutputSessionToken=0
		If ..KeepCSPPartition,$D($$$EnsLocalCache($$$EnsJobLocal("ConfigName"))) {
			Merge $$$EnsJobLocal("CachedObject")=$$$EnsLocalCache($$$EnsJobLocal("ConfigName"),"CachedObject")
			Merge $$$EnsJobLocal("CachedChecksum")=$$$EnsLocalCache($$$EnsJobLocal("ConfigName"),"CachedChecksum")
			Kill $$$EnsLocalCache($$$EnsJobLocal("ConfigName"))
		}
	}
	Set pResponseBody=$$$NULLOREF
	Set tRequest=##class(EnsLib.HTTP.GenericMessage).%New(pRequestBody,,pRequestBody)
	Do pRequestBody.SetAttributeList("") ; prevent double output; we just copied them to tRequest.HTTPHeaders
	Set tSC=..resolveAndIndex(tRequest)  Quit:$$$ISERR(tSC) tSC

	If ..OneWay {
		Set tSC = ..SendRequestAsync(..TargetConfigName,tRequest)
		Set:$$$ISOK(tSC) pResponseBody("ResponseCode")="202 Accepted"
		Quit tSC
	}

	Set tSC=..SendRequestSync(..TargetConfigName,tRequest,.tResponse)  Quit:$$$ISERR(tSC) tSC
	Set pResponseBody=tResponse.Stream

	If $$$IsdefObject(%request) {
		#; Since a CSP job can become multiple business services need to preserve even if current BS does not specify it.
		If ($D($$$EnsLocalCacheRoot)||(..KeepCSPPartition&&$D($$$EnsJobLocal("CachedObject")))) {
			Set %response.AvoidPartitionCleanup=1
		}
	}

	#; Pass along Status line and selected response HTTP headers
	Set tSL="",tDoNotPassThrough=","_$ZCVT(..%ExcludeResponseHttpHeaders,"L")_",content-length,"
	Set tHasAttrs=pResponseBody.%Extends("%Library.AbstractStream")
	Set tHeaderKey="" For { Set tHeaderKey=tResponse.HTTPHeaders.Next(tHeaderKey)  Quit:""=tHeaderKey  Set tHeaderLwr=$ZCVT(tHeaderKey,"L")
		If tHasAttrs { Set:tDoNotPassThrough'[(","_tHeaderLwr_",") pResponseBody.Attributes(tHeaderKey)=tResponse.HTTPHeaders.GetAt(tHeaderKey) } ; no need to handle multiple on one line
		Else {         Set:tDoNotPassThrough'[(","_tHeaderLwr_",") pResponseBody(tHeaderKey)=tResponse.HTTPHeaders.GetAt(tHeaderKey) }
		Set:tHeaderLwr="statusline" tSL=tResponse.HTTPHeaders.GetAt(tHeaderKey)
	}
	If tHasAttrs { Set:tDoNotPassThrough'["statusline"&&$L(tSL) pResponseBody.Attributes("StatusLine")=tSL }
	Else {         Set:tDoNotPassThrough'["statusline"&&$L(tSL) pResponseBody("StatusLine")=tSL }
	Quit tSC
}

/// Override this method to implement your own custom method for validating an incoming Document
/// Return non-zero to prevent default validation of the message (if any);
Method OnValidate(pMsg As EnsLib.HTTP.GenericMessage, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

/// Override this method to implement your own custom method for resolving the DocType of an incoming Message
/// Returning nonzero means you are overriding the framework's standard DocType resolution.
Method OnResolveDocType(pMsg As EnsLib.HTTP.GenericMessage, ByRef pDocType As %String, ByRef pHeaderDocType As %String) As %Boolean
{
	Quit 0
}

/// Accept only specified document names; resolve DocType and perform requested validation if any
Method resolveAndIndex(pMsg As EnsLib.HTTP.GenericMessage) As %Status
{
	Set tSC=$$$OK

	#; Do further validation if required
	If ""'=..Validation&&'..OnValidate(pMsg,..Validation,.tSC) {
		#; no default validation
	}
	Quit:$$$ISERR(tSC) tSC

	If ""'=..SearchTableClass {
		TRY {
			Set tObj=pMsg
			Set:$IsObject(tObj) tSCStore=$classmethod(..SearchTableClass,"IndexDoc",tObj)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_tObj_"/"_tObj.%Id()_" using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_tObj_"/"_tObj.%Id()_" with DocType='"_tObj.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit tSC
}

/// Return the DocType that this service will assign to this message's body document
Method resolveDocType(pMsg As EnsLib.HTTP.GenericMessage, Output pHeaderDocType As %String) As %String
{
	/// Subclass responsibility
	Set pHeaderDocType=""
	Quit ""
}

/// Callback for allowing Service to override and control construction of the HTTP response if invoked via the SOAP Inbound Adapter
/// Split www-authenticate HTTP header and add proxy-support header if needed
Method OnAdapterHTTPResponse(ByRef pStatus As %Status, ByRef pHTTPResponseStatus As %String, ByRef pBodyLen As %Integer, ByRef pResponseBodyStream As %Stream.Object, ByRef pMainResponseHeader As %String, ByRef pHeaderExtra As %String)
{
	Set pos=$F($ZCVT(pHeaderExtra,"L"),"www-authenticate: ")
	If pos {
		Set auth=$E(pHeaderExtra,pos-$L("www-authenticate: "),pos-1)
		Set pos2=$F(pHeaderExtra,$C(13,10),pos)
		Set pos2=$S(pos2:pos2-3,1:$L(pHeaderExtra))
		Set val=$E(pHeaderExtra,pos,pos2), tCount=$L(val,",")
		For i = 1:1:tCount { Set iVal=$ZStrip($P(val,",",i),"<>W")  Continue:""=iVal
			If i=1 { Set newHdr=iVal_$C(13,10) }
			Else { Set newHdr=newHdr_auth_iVal_$C(13,10) }
		}
		Set $E(pHeaderExtra,pos,pos2) = $E(newHdr,1,*-2)
	}
	Set:($P(pMainResponseHeader,$C(13,10))["401") pHeaderExtra = pHeaderExtra_"Proxy-support: Session-Based-Authentication"_$C(13,10)
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	#; Detect if webserver because IRIS is done and the job may get re-used by the CSP server
	If ""'=..%OutsideCreated {
		If 1'=..%OutsideCreated {
			Kill $$$EnsLocalCache(..%ConfigName)
			If ..KeepCSPPartition {
				Merge $$$EnsLocalCache(..%ConfigName,"CachedObject")=$$$EnsJobLocal("CachedObject")
				Merge $$$EnsLocalCache(..%ConfigName,"CachedChecksum")=$$$EnsJobLocal("CachedChecksum")
			}
		}
	}
	Quit ##super()
}

}
