/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.FTP.PassthroughService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

/// Configuration item(s) to which to send file stream messages
Property TargetConfigNames As %String(MAXLEN = 1000);

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Parameter CONTAINERCLASS = "Ens.StreamContainer";

/// Wrap the input stream object in a StreamContainer message object and send it.
/// If the adapter has a value for ArchivePath, send async; otherwise send synchronously
/// to ensure that we don't return to the Adapter and let it delete the file before the
/// target Config Item is finished processing it.
Method OnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status
{
	Set tSource=pInput.Attributes("Filename"), pInput=$zobjclassmethod(..#CONTAINERCLASS,"%New",pInput)
	Set tSC=..resolveAndIndex(pInput) Quit:$$$ISERR(tSC) tSC
	Set tWorkArchive=(""'=..Adapter.ArchivePath)
	$$$SyncCommitSet(tSyncCommit)
	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		$$$sysTRACE("Sending input Stream "_pInput.Stream_"("_pInput.Stream.Size_")"_$S(tWorkArchive:" Async",1:" Sync")_" from '"_tSource_"' to '"_tOneTarget_"'")
		If tWorkArchive {
			Set tSC1=..SendRequestAsync(tOneTarget,pInput)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		} Else {
			#; If not archiving send Sync to avoid Adapter deleting file before Operation gets it
			Set tSC1=..SendRequestSync(tOneTarget,pInput)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
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
