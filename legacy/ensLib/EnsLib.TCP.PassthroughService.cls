/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.PassthroughService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.CountedInboundAdapter";

/// Configuration item(s) to which to send file stream messages
Property TargetConfigNames As %String(MAXLEN = 1000);

/// Should we let the client know that we got the message?
Property SendAcknowledgement As %Boolean [ InitialExpression = 1 ];

/// Should we expect to receive a stream name text string prefix before each stream we receive?
Property GetStreamName As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SendAcknowledgement:Connection,GetStreamName:Connection";

Parameter CONTAINERCLASS = "Ens.StreamContainer";

/// Toggle string for 2-block protocol: name block, then stream content block
Property %HeaderFilename As %String;

/// Wrap the input stream object in a StreamContainer message object and send it.
/// If the SyncCall setting is true, send synchronously; otherwise send async
/// to ensure that we don't return to the Adapter and let it delete the stream before the
/// target Config Item is finished processing it.
Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	Set tSC=$$$OK
	If ""=..%HeaderFilename {
		Set tHeader=pInput.Read($L("Passthru:"))
		If "Passthru:"'=tHeader {
			$$$ASSERT($$$NULLOREF=..%RequestHeader)
			Set ..%RequestHeader=##class(Ens.MessageHeader).%New()  Set ..%SessionId=..%RequestHeader.MessageId()
			Set ..%HeaderFilename="TCP"_..%SessionId
			If ..GetStreamName { $$$LOGWARNING("Passthru 'name' header not found; using name '"_..%HeaderFilename_"'; got stream data("_pInput.Size_"):"_tHeader_pInput.Read(1000-$L(tHeader))) }
			Else { $$$sysTRACE("Got stream '"_..%HeaderFilename_"' ("_pInput.Size_")") }
		} Else {
			Set ..%HeaderFilename=pInput.Read()
			Set:""=..%HeaderFilename ..%HeaderFilename=tHeader
			$$$sysTRACE("Got stream name '"_..%HeaderFilename_"'")
			Quit tSC ; got the name, go back for the data w/ no reply at this time
		}
	}
	Do pInput.SetAttribute("Filename",..%HeaderFilename)  Set ..%HeaderFilename=""
	Set pInput=$classmethod(..#CONTAINERCLASS,"%New",pInput)
	Set tSC=..resolveAndIndex(pInput) Quit:$$$ISERR(tSC) tSC
	$$$SyncCommitSet(tSyncCommit)
	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		$$$sysTRACE("Sending input Stream "_pInput_" async from "_..%HeaderFilename_" to '"_tOneTarget)
		Set tSC1=..SendRequestAsync(tOneTarget,pInput)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	}
	$$$SyncCommitClear(tSyncCommit)
	Set:..SendAcknowledgement pOutput=##Class(%IO.StringStream).%New($S($$$ISOK(tSC):"OK",1:$$$StatusDisplayString(tSC)))
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

}
