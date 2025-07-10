/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts files from the MFT Inbound Adapter and forwards the container object to the configured target configuration item or items.
Class EnsLib.MFT.Service.Passthrough Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.MFT.Adapter.Inbound";

/// Configuration item(s) to which to send file stream messages
Property TargetConfigNames As %String(MAXLEN = 1000);

/// Send the inbound MFT message to the target Synchronously.<br>
/// This might be needed to control the processing of the documents
/// on the MFT server <br>
/// The default is Asynchronously
Property SyncCall As %Boolean [ InitialExpression = 0 ];

/// If the message is passed to the target as SyncCall then this
/// is the timeout to wait for a response from the target.<br>
/// Note the response is ignored.
/// The default is unlimited timeout. <br>
Property SyncCallTimeout As %Integer [ InitialExpression = -1 ];

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},,SyncCall:Basic,SyncCallTimeout:Basic";

Method OnProcessInput(pInput As Ens.MFT.StreamContainer, pOutput As %RegisteredObject) As %Status
{
	#dim tSC,tSC1 As %Status = $$$OK
	#dim iTarget As %Integer
	#dim tOneTarget As %String
	#dim tSyncCommit As %Integer

	$$$SyncCommitSet(tSyncCommit)

	For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
		$$$sysTRACE("Sending input MFT ObjectStream to target: '"_tOneTarget_"'")
		If ..SyncCall {
			Set tSC1=..SendRequestSync(tOneTarget,pInput,,..SyncCallTimeout)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		} Else {
			Set tSC1=..SendRequestAsync(tOneTarget,pInput)  Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
		}
	}

	$$$SyncCommitClear(tSyncCommit)
	Quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	#dim tValue, tOne As %String

	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

}
