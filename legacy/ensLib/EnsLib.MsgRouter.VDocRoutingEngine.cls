/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.MsgRouter.VDocRoutingEngine Extends EnsLib.MsgRouter.RoutingEngine [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/* Override InitialExpression and description */

/*
	Validation: a string specifying types of validation to perform; If you override OnValidate() and need to provide more
	options, you can add more supported values to it and document them by also overriding the definition of this Validation property.
*/
/// String specifying types of Validation to perform <p>
/// Set to 1 to block documents that don't pass default validation. Default validation checks for DocType assignment and successful BuildMapStatus.<p>
/// This is equivalent to 'dm' <br>
/// 'd' - require DocType <br>
/// 'm' - require successful BuildMap status
Property Validation As %String(MAXLEN = 20) [ InitialExpression = "m", Transient ];

Parameter SETTINGS = "Validation:Basic";

Property DocType As %String(MAXLEN = 128) [ Transient ];

Property DocName As %String(MAXLEN = "") [ Transient ];

/// Override this method to implement your own method for validating a Document
/// Return non-zero to prevent default validation of the message(if any);
/// return an error code in pStatus to indicate a validation failure.
Method OnValidate(pDoc As %Persistent, pValSpec As %String, Output pStatus As %Status = {$$$OK}) As %Boolean
{
	#; do validation - by default validate DocType, BuildMapStatus
	Set:pValSpec=1 pValSpec="dm"  Set pValSpec=..normalizeValSpec(pValSpec)
	If ""=pDoc.DocType {
		Set:pValSpec["d" pStatus=$$$ERROR($$$EnsErrGeneral,"Message has no DocType set")
		Quit 1
	}
	Quit:pValSpec'["m" 1
	If pDoc.%Extends("EnsLib.EDI.Segmented") {
		Do:""=pDoc.BuildMapStatus pDoc.BuildMap()
		Set pStatus=pDoc.BuildMapStatus  Set:""=pStatus pStatus=$$$OK
	}
	Quit 1
}

Method OnRequest(request As %Persistent, Output response As %Persistent) As %Status
{
	Set ..DocType = request.DocType
	Set ..DocName = request.Name
	Set tSC = ##super(request,.response)
	Quit tSC
}

Method OnPrepareReply(request As %Persistent, ByRef response As %Persistent)
{
	Set tSCErr=..%ErrorStatus, tSC=..OnConstructReply(.response, request,.tSCErr)
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
}

/// Override this method to construct a customized reply document. Inputs are the original document and
///  the status code that the framework produced in processing the original document.
///  If you change the status code but do not construct a reply document, the framework will use the new value to construct a standard reply document.
Method OnConstructReply(Output pReplyDoc As Ens.VDoc.Interface, pOriginalDoc As Ens.VDoc.Interface, ByRef pSC As %Status) As %Status
{
	Quit $$$OK
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest ]
{
	#; override to be based on OnConstructReply() method args instead of OnRequest() args
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnConstructReply",$$$cMETHformalspecparsed)
	Set tClass=$lg($lg(tSignature,2),2)
	Do %code.WriteLine(" Quit $lb("""_tClass_""")")
	Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnRequest ]
{
	#; override to be based on OnConstructReply() method args instead of OnRequest() args
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnConstructReply",$$$cMETHformalspecparsed)
	Set tRequestClass=$lg($lg(tSignature,1),2)
	Set tClass=$lg($lg(tSignature,1),2)
	Do %code.WriteLine(" If pRequest=""""||(pRequest="""_tRequestClass_""") Quit $lb("""_tClass_""")")
	Do %code.WriteLine(" Quit """"")
	Quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
