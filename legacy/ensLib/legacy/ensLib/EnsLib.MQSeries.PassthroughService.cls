/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts messages from the MQSeries InboundAdapter, encapsulates each one as a Stream object within a StreamContainer object and forwards the container object to the configured target configuration item or items.
Class EnsLib.MQSeries.PassthroughService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.MQSeries.InboundAdapter";

/// Configuration item(s) to which to send file stream messages
Property TargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Parameter CONTAINERCLASS = "Ens.StreamContainer";

Method OnInit() As %Status
{
	Set ..Adapter.ContentStreamClassname ="%GlobalCharacterStream"
	Quit $$$OK
}

/// Wrap the input stream object in a StreamContainer message object and send it.
Method OnProcessInput(pInput As EnsLib.MQSeries.Message, pOutput As %RegisteredObject) As %Status
{
	Set tRequest=$classmethod(..#CONTAINERCLASS,"%New",pInput.BodyStream)
	Do:tRequest.%Extends("Ens.StreamContainer") tRequest.Attributes.SetAt(pInput.Source,"Source")
	Set tSC=..resolveAndIndex(tRequest) Quit:$$$ISERR(tSC) tSC
	$$$SyncCommitSet(tSyncCommit)
	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		$$$sysTRACE("Sending input Stream "_tRequest.Stream_"("_tRequest.Stream.Size_") Async from '"_pInput.Source_"' to '"_tOneTarget_"'")
		Set tSC1=..SendRequestAsync(tOneTarget,tRequest)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	}
	$$$SyncCommitClear(tSyncCommit)
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
