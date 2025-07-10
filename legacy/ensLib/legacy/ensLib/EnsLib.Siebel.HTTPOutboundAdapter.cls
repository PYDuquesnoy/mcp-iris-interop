/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A subclass that logs in to Siebel. It has a "virtual" StayConnected mode, i.e the HTTP TCP socket
///  is not persistent but a Session cookie maintains state.
Class EnsLib.Siebel.HTTPOutboundAdapter Extends EnsLib.HTTP.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Tells the Siebel Server the name of our system that's calling in.
Property SWEExtSource As %String;

/// This is the ID name of the set of credentials values to be used to log in to Siebel Workflow Engine (SWE)
Property SWECredentials As %String;

/// If non-zero, stay logged on to the remote system between handling Requests
Property UseCookies As %Boolean [ InitialExpression = 1 ];

/// A list of properties to set from HTTP headers, in the form: pkg.class.prop=hdrname,pkg.class.prop=hdrname,...
Property HttpHeaderProps As %String;

/// These are the production settings for this object
Parameter SETTINGS = "SWEExtSource,SWECredentials,UseCookies,HttpHeaderProps";

Property cookie As %String;

Property loggedIn As %Boolean [ InitialExpression = 0 ];

/// This is the credentials object containing the values to be used to access the datasouce
Property %SWECredentialsObj As Ens.Config.Credentials;

Method SWECredentialsSet(pInVal As %String) As %Status
{
	#; (Re)Set the CredentialsObject; do it always because we never know if the source row fields might have been updated
	#; make sure to instantiate even if re-setting to the InitialExpression string
	Set ..%SWECredentialsObj=$$$NULLOREF
	Set tClass = $$$comMemberKeyGet($classname(),$$$cCLASSproperty,"%SWECredentialsObj",$$$cPROPtype)
	If ""'=tClass&&(""'=pInVal) {
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tObj,$classname(),tClass,pInVal)
		Set:$$$ISOK(tSC) ..%SWECredentialsObj=tObj
	}
	Set i%SWECredentials=pInVal
	Quit $$$OK
}

Method OnInit() As %Status
{
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	if ..UseCookies Do ..Login()
	Quit tSC
}

Method Login() As %Status
{
	If '$IsObject(..%SWECredentialsObj) Do ..SWECredentialsSet(..SWECredentials) If '$IsObject(..%SWECredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..SWECredentials) Quit }

	Do ..DeleteCookies()
	Set tURL=..URL
	Set ..URL=tURL_"?SWEExtSource="_$$$URLENCODE(..SWEExtSource)_"&SWEExtCmd=ExecuteLogin&UserName="_$$$URLENCODE(..%SWECredentialsObj.Username)_"&Password="_$$$URLENCODE(..%SWECredentialsObj.Password)
	Set tSC =..Get(.tHttpResponse)
	Set ..URL=tURL
	Set:$$$ISOK(tSC) tSC=..getHttpStatus(tHttpResponse,1)
	If $$$ISOK(tSC) Set ..loggedIn=1
	Else  Do ..DeleteCookies() Set ..loggedIn=0
	Quit tSC
}

Method Logoff() As %Status
{
	Set tSC = ..Get(.tHttpResponse,"SWEExtCmd","Logoff")
	Set:$$$ISOK(tSC) tSC=..getHttpStatus(tHttpResponse,1)
	Do ..DeleteCookies()
	Set ..loggedIn=0
	Quit tSC
}

Method Execute(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status
{
	If ..UseCookies&&'..loggedIn //Set tSC = ..Login()  Quit:$$$ISERR(tSC) tSC
	Quit:'..loggedIn ..loginAndExecute(pRequest,.pResponse)
	Set tStr=##class(%FileCharacterStream).%New()  $$$ASSERT($IsObject(tStr))
	Do tStr.Write("<?xml version=""1.0"" encoding=""UTF-8"" ?><?Siebel-Property-Set EscapeNames=""false""?>")
	Set tSC=pRequest.XMLExportToStream(tStr)  Quit:$$$ISERR(tSC) tSC
	Set tSC =..Post(.tHttpResponse,"SWEExtSource,SWEExtCmd,SWEExtData",..SWEExtSource,"Execute",tStr)
	Set:$$$ISOK(tSC) tSC=..getResponse(tHttpResponse,pRequest.%GetParameter("RESPONSECLASSNAME"),.pResponse)
	#; Set the Retry flag depending on which error we got
	Set:$$$ISERR(tSC)&&$$$StatusEquals(tSC,$$$HttpRequestConnect,$$$CSPTimeout) ..BusinessHost.Retry = 1
	Quit tSC
}

Method loginAndExecute(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status [ Private ]
{
	If '$IsObject(..%SWECredentialsObj) Do ..SWECredentialsSet(..SWECredentials) If '$IsObject(..%SWECredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..SWECredentials) Quit }

	Set tSC=pRequest.XMLExportToString(.tStr)  Quit:$$$ISERR(tSC) tSC
	Set tStr=##class(%FileCharacterStream).%New()  $$$ASSERT($IsObject(tStr))
	Do tStr.Write("<?xml version=""1.0"" encoding=""UTF-8"" ?><?Siebel-Property-Set EscapeNames=""false""?>")
	Set tSC=pRequest.XMLExportToStream(.tStr)  Quit:$$$ISERR(tSC) tSC
	Set tSC =..Post(.tHttpResponse,"SWEExtSource,SWEExtCmd,UserName,Password,SWEExtData",..SWEExtSource,"Execute",..%SWECredentialsObj.Username,..%SWECredentialsObj.Password,tStr)
	Set:$$$ISOK(tSC) tSC=..getResponse(tHttpResponse,pRequest.%GetParameter("RESPONSECLASSNAME"),.pResponse)
	#; Set the Retry flag depending on which error we got
	Set:$$$ISERR(tSC)&&$$$StatusEquals(tSC,$$$HttpRequestConnect,$$$CSPTimeout) ..BusinessHost.Retry = 1
	Quit tSC
}

Method getResponse(pHttpResponse As %Net.HttpResponse, pResponseClass As %String, Output pResponse As Ens.Response) As %Status [ Private ]
{
	Do {
		Set tSC=$$$OK, tStream=pHttpResponse.Data
		$$$sysTRACE("Got Response Data (size="_tStream.Size_"), looking for  request of type "_pResponseClass_" from "_..URL)
		$$$sysTRACE("Response Content (size="_tStream.Size_") : "_tStream.Read(1000))  Do tStream.Rewind()
		If tStream.Size {
			If ""'=pResponseClass {
				Set tSC = ##Class(Ens.Util.XML.Reader).ObjectFromStream(.pResponse,tStream,pResponseClass)
				if $$$ISOK(tSC) {
					For i=1:1:$L(..HttpHeaderProps,",") {
						Set tItem=$P(..HttpHeaderProps,",",i)
						Set tHdr=$P(tItem,"=",2)
						Set tProp=$P(tItem,"=")
						Set tPropName=$P(tProp,".",$L(tProp,"."))
						Set tPropClass=$P(tProp,".",1,$L(tProp,".")-1)
						If ""=tPropClass||pResponse.%Extends(tPropClass) {
							Set tVal=$S(""=tHdr:"",1:pHttpResponse.GetHeader(tHdr))
							Set:""'=tVal $zobjproperty(pResponse,tPropName)=tVal
						}
					}
				}
				Else {
					$$$ASSERT('$IsObject(pResponse))
					If '$$$StatusEquals(tSC,$$$EnsErrNoObjFromStream) { $$$LOGSTATUS(tSC) }
				}
			}
		}
		#; If there was no body or failed body read, see if there was an HTTP error
		If 'tStream.Size||'$IsObject(pResponse) {
			Set tSC=..getHttpStatus(pHttpResponse)
		}
	} while 0
	Quit tSC
}

Method getHttpStatus(pHttpResponse As %Net.HttpResponse, pEmptyBodyOK As %Boolean = 0) As %Status [ Private ]
{
	If pHttpResponse.StatusCode'=200 Set tMsg="Http response status = "
	else  if 'pHttpResponse.Data.Size&&'pEmptyBodyOK Set tMsg="Http response body empty, status = "
	else  Quit $$$OK
	
	Set tDetails=pHttpResponse.StatusLine_"  "
	Set name="" For { Set name=pHttpResponse.GetNextHeader(name) Quit:""=name 
		Set:$Case($TR(name,"-"),"CONTENTTYPE":0,"CONTENTLENGTH":0,"DATE":0,"SETCOOKIE":0,"CACHECONTROL":0,"PRAGMA":0,:1) tDetails=tDetails_" & "_name_"='"_pHttpResponse.GetHeader(name)_"'"
	}
 w "size==="_pHttpResponse.Data.Size
	Set:pHttpResponse.Data.Size tDetails=tDetails_" && BODY='"_pHttpResponse.Data.Read(pHttpResponse.Data.Size)_"'"
	Quit $$$EnsError($$$EnsErrGeneral,tMsg_tDetails)
}

Method OnTearDown() As %Status
{
	Do:..loggedIn ..Logoff()
	Quit $$$OK
}

}
