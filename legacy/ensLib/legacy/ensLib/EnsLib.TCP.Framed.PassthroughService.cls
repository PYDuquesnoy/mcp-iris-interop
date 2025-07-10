/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.Framed.PassthroughService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.FramedInboundAdapter";

/// Configuration item(s) to which to send file stream messages
Property TargetConfigNames As %String(MAXLEN = 1000);

/// Send the inbound message stream to the target Synchronously.
/// The default is Asynchronously and any Acknowledgement is controlled 
/// by the SendAcknowledgement setting.
/// If the message is sent synchronously then the response from the 
/// target called is used as the Acknowledgement if it is a stream.
/// If it is not a stream then the SendAcknowledgement settings are used
/// and the ACK not OK character(s) are sent.
/// If there are more than one synchronous targets then the last response
/// is used as the Acknowledgement.
Property SyncCall As %Boolean [ InitialExpression = 0 ];

/// If the message is passed to the target as SyncCall then this
/// is the timeout to wait for a response from the target.
/// The default is unlimited timeout.
Property SyncCallTimeout As %Integer [ InitialExpression = -1 ];

/// Send AckOK/ActNotOK characters
Property SendAcknowledgement As %Boolean [ InitialExpression = 1 ];

/// Comma separated list of control characters that indicate
/// message received OK
/// Can be Decimal or Hex if have preceding 'x'
/// For example 6 or x06
Property AckOK As %String [ InitialExpression = "6" ];

/// Used to store actual Acknowledgement OK characters
Property AckOKAsChars As %String [ Transient ];

/// Comma separated list of control characters that indicate
/// message not received OK
/// Can be Decimal or Hex if have preceding 'x'
/// For example 21 or x15
Property AckNotOK As %String [ InitialExpression = "21" ];

/// Used to store actual Acknowledgement Not OK characters
Property AckNotOKAsChars As %String [ Transient ];

Parameter CONTAINERCLASS = "Ens.StreamContainer";

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SendAcknowledgement:Connection,AckOK:Connection,AckNotOK:Connection,SyncCall:Connection,SyncCallTimeout:Connection";

/// Wrap the input stream object in a StreamContainer message object and send it.
/// If the SyncCall setting is true, send synchronously; otherwise send async
/// to ensure that we don't return to the Adapter and let it delete the stream before the
/// target Config Item is finished processing it.
Method OnProcessInput(pInput As %Stream.Object, pOutput As %Stream.Object) As %Status
{
	Set tSC=$$$OK
	Set pInput=$classmethod(..#CONTAINERCLASS,"%New",pInput)
	Set tSC=..resolveAndIndex(pInput) Quit:$$$ISERR(tSC) tSC
	Set pOutput = $$$NULLOREF
	$$$SyncCommitSet(tSyncCommit)
	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget	
	If '..SyncCall {
			$$$sysTRACE("Sending input Stream "_pInput_" Async to '"_tOneTarget)
			Set tSC1=..SendRequestAsync(tOneTarget,pInput)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		} Else {
			$$$sysTRACE("Sending input Stream "_pInput_" Sync to '"_tOneTarget)
			Set tSC1=..SendRequestSync(tOneTarget,pInput,.pOutput,..SyncCallTimeout)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
	}
	$$$SyncCommitClear(tSyncCommit)
	If ..SendAcknowledgement {
		If ..SyncCall {
			If (($G(pOutput)="")||($IsObject($G(pOutput)&&('pOutput.%IsA("%Stream.Object")&&'pOutput.%IsA("Ens.StreamContainer")&&'pOutput.%IsA("Ens.StringContainer")&&'pOutput.%IsA("Ens.StringRequest")&&'pOutput.%IsA("Ens.StringResponse"))))) {
				Set pOutput=##Class(%IO.StringStream).%New(..AckNotOKAsChars)
			}
		} Else {
			Set pOutput=##Class(%IO.StringStream).%New($S($$$ISOK(tSC):..AckOKAsChars,1:..AckNotOKAsChars))
		}
	}
	Quit tSC
}

/// Initialize and perform requested validation if any
Method resolveAndIndex(pDoc As %Persistent) As %Status
{
	Quit $$$OK
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Try {
		#; No need to convert if not sending back an acknowledgement
		Quit:'..SendAcknowledgement
		#; Convert ACK/NACK settings to characters
		Set ..AckOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckOK)
		Set ..AckNotOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckNotOK)
	} Catch {}
	Quit ##super()
}

}
