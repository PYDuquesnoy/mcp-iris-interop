/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Accepts files from the File Inbound Adapter, encapsulates each one as a Stream object within a StreamContainer object and forwards the container object to the configured target configuration item or items.
Class EnsLib.File.PassthroughService Extends Ens.BusinessService [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

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
	#dim tSC,tSC1 As %Status = $$$OK
	#dim tSource, tWorkArchive, iTarget, tOneTarget As %String
	#dim tSyncCommit As %Integer
	
	Set tSource=$G(pInput.Attributes("Filename"),pInput), pInput=$classmethod(..#CONTAINERCLASS,"%New",pInput)
	Set tSC=..resolveAndIndex(pInput) Quit:$$$ISERR(tSC) tSC
	Set tWorkArchive=(""'=..Adapter.ArchivePath)&&(..Adapter.ArchivePath=..Adapter.WorkPath || (""=..Adapter.WorkPath && (..Adapter.ArchivePath=..Adapter.FilePath)))
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

	/* 
		If we are going to go on to delete/move the file
		when ProcessInput returns success we need to delete
		the Stream property from pInput.
		Need to do after sending to all targets.
	*/

	If 'tWorkArchive && $$$ISOK(tSC) {
		Set tSC1 = ..removeStreamFromInput(pInput)
		Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
	}
	
	$$$SyncCommitClear(tSyncCommit)
	Quit tSC
}

/// This method is called if the actual input file pointed to by the request object
/// will be deleted by the Adapter.<br>
/// It requires the request object (CONTAINERCLASS parameter) to be Ens.StreamContainer<br>
/// It also requires the Adapter to be the EnsLib.File.InboundAdapter. <br>
/// If this class has been subclassed to override CONTAINERCLASS or the adapter
/// it may be necessary to override this method and act accordingly.
Method removeStreamFromInput(pInput As Ens.StreamContainer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	If ($classname(pInput) = "Ens.StreamContainer") {
		Try {
			#; Double check using Adapter logic to see if will be deleted and if so remove reference to file
			If (..Adapter.DeleteFromServer||(""'=..Adapter.ArchivePath&&(..Adapter.ArchivePath'=..Adapter.FilePath))) {
				Set pInput.Stream = ""
				Do pInput.%Save()
			}
		} Catch ex {
			Set tSC = ex.AsStatus()
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

}
