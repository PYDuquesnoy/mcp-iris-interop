/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Records a single history event for a given cube for analysis of cube management.
Class %DeepSee.CubeManager.CubeEvent Extends %Persistent [ System = 4 ]
{

/// The cube that is the subject of this event.
Property CubeKey As %DeepSee.Datatype.entityName [ Required ];

/// The event being recorded.
Property CubeEvent As %DeepSee.Datatype.entityName(DISPLAYLIST = ",PreSynchCode,PostSynchCode,PostBuildCode,Build,Synch,Register,Unregister,Update,Repair", VALUELIST = ",presynch,postsynch,postbuild,build,synch,register,unregister,update,repair");

/// Plan for how the cube is to be managed by the build/synch tasks.
Property UpdatePlan As %DeepSee.Datatype.entityName;

/// Management group the cube belongs to.   
Property MgmtGroup As %DeepSee.Datatype.entityName;

/// Name of the user that initiated the event.
Property UserName As %Library.Username;

/// Timestamp recorded prior to event execution
Property StartTime As %TimeStamp;

/// Timestamp recorded at the completion of the cube event.
Property FinishTime As %TimeStamp;

/// Total amount of time this event took;
Property TotalTime As %Numeric;

/// Stores the current cube size of the cube. If the event is constructive
/// (eg Build, Synch), this will be recorded after the event completes. If 
/// the event is destructive (eg Unregister) this is recorded prior to execution. 
Property CubeSize As %Integer;

/// The number of facts updated in this event. This will only be set in Build or
/// Synch operations. For builds, it is equal to the final cube size. 
Property FactsUpdated As %Integer;

/// Records the status message, if it exists, of the event after completion.
Property EventStatus As %Status;

/// Record of whether or not the build was called in asynchronous mode
Property AsynchUpdate As %Boolean;

/// Number of agents active on the system. This is the value returned by 
/// <method>##class(%DeepSee.Utils).%GetAgentCount()</method>
Property AgentCount As %Integer;

/// Indicates how often the cube is scheduled to be built, in units of
/// <var>BuidTimeUnit</var> 
Property BuildFrequency As %Integer;

/// Base unit of time for cube builds. 
Property BuildTimeUnit As %DeepSee.Datatype.entityName;

/// Indicates how often the cube is scheduled to be synched, in units of
/// <var>SynchTimeUnit</var>
Property SynchFrequency As %Integer;

/// Base unit of time for cube synchs.
Property SynchTimeUnit As %DeepSee.Datatype.entityName;

/// Number of CPU cores
Property NCores As %Integer;

/// For builds, the build time spent processing expressions
Property ExprTime As %Numeric;

/// For builds, the build time spent processing iKnow indices
Property iKnowTime As %Numeric;

/// For build and synchronize, the count of errors while processing facts during this update.
Property ErrorCount As %Integer;

/// For build and synchronize, the count of missing relationship references encountered while
/// processing facts.
Property MissingRefs As %Integer;

/// Log if the synchronize was exempt from the dependency and only updated due to schedule.
Property DependencyExempt As %Boolean [ InitialExpression = 0 ];

Index LastUpdateIndex On (CubeKey, CubeEvent, FinishTime);

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(pInsert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		// Normalize the cube key, mixed case name may be entered in a function call
		Set:pInsert ..CubeKey=$zcvt(..CubeKey,"U")
		
		// Store current username
		Set ..UserName = $USERNAME
		Set ..TotalTime = $system.SQL.Functions.DATEDIFF("s",..StartTime,..FinishTime)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Retrieves the current cube management settings from the cube registry and writes them to the event. If the target <var>pCube</var> is not registered
/// and has no schedule, nothing about the current CubeEvent is changed.
Method TransferRegistryInfo(pCube As %String = "", pAction = "", pMapCube As %DeepSee.CubeManager.RegistryMapCube = "", pMapGroup As %DeepSee.CubeManager.RegistryMapGroup = "") As %Status
{
	// DTB133 - refactor to use try/catch block
	Set tCubeUpper = $$$UPPER(pCube)
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCube) {
			Set tSC = $$$ERROR($$$CubeDNE,pCube)
			Quit
		}

		If '$IsObject(pMapCube) {
			// DTB382 - If we were passed a reusable object, skip the retrieval of the cube schedule from storage.
			// Otherwise attempt to load from a saved registry. Quit as a no-op if no registry exists.
			If (##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()="") Quit

			// Look for the cube in the registered map and fetch the relevant code
			Set tMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.tLookup)
			If $$$ISERR(tSC) Quit

			If '$D(tLookup("cubes",tCubeUpper),tMapLocation) Quit
			Set $LB(tGroupIdx,tCubeIdx) = tMapLocation

			// DTB133 - Load the cube object from the xml-based registry
			Set pMapCube = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap().Groups.GetAt(tGroupIdx).Cubes.GetAt(tCubeIdx)
		}
		
		// DTB588 - Check both the cube object and the optional group object for group registration
		Set tCubeIsRegistered = ($IsObject(pMapCube.Group)&&pMapCube.Group.IsRegistered)||($IsObject(pMapGroup)&&pMapGroup.IsRegistered)
		If 'tCubeIsRegistered {
			// If the cube isn't registered, there is nothing to transfer
			Quit
		}
		
		If ((pAction="build")||(pAction="synch"))&&pMapCube.Disabled {
			Set tSC = $SYSTEM.Status.Error($$$ERRORCODE($$$GeneralError),$$$Text("Cube is currently excluded from updates","%DeepSee")_":"_pCube)
			Quit
		}

		// transfer contents to current Event object.
		Set ..BuildFrequency = pMapCube.BuildFrequency
		Set ..BuildTimeUnit = pMapCube.BuildTimeUnit
		Set ..MgmtGroup = pMapCube.Group.GroupName
		Set ..SynchFrequency = pMapCube.SynchFrequency
		Set ..SynchTimeUnit = pMapCube.SynchTimeUnit
		Set ..UpdatePlan = pMapCube.UpdatePlan		
		
		// Use the logic from TaskMaster.%CreateAgents to find agent count and record it
		Set tAgentCount = ##class(%DeepSee.Utils).%GetAgentCount()
		If (tAgentCount="") {
			// set agents equal to 4*cores
			Set tCPU = ##class(%SYSTEM.CPU).%New()
			Set tAgentCount = tCPU.nCores * 4
		}
		Set:tAgentCount<1 tAgentCount = 1
		Set:tAgentCount>128 tAgentCount = 128
		Set ..AgentCount = tAgentCount
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Storage Default
{
<Data name="CubeEventDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CubeKey</Value>
</Value>
<Value name="3">
<Value>CubeEvent</Value>
</Value>
<Value name="4">
<Value>UpdatePlan</Value>
</Value>
<Value name="5">
<Value>MgmtGroup</Value>
</Value>
<Value name="6">
<Value>UserName</Value>
</Value>
<Value name="7">
<Value>StartTime</Value>
</Value>
<Value name="8">
<Value>FinishTime</Value>
</Value>
<Value name="9">
<Value>CubeSize</Value>
</Value>
<Value name="10">
<Value>FactsUpdated</Value>
</Value>
<Value name="11">
<Value>EventStatus</Value>
</Value>
<Value name="12">
<Value>BuildTime</Value>
</Value>
<Value name="13">
<Value>BuildFrequency</Value>
</Value>
<Value name="14">
<Value>BuildTimeUnit</Value>
</Value>
<Value name="15">
<Value>SynchFrequency</Value>
</Value>
<Value name="16">
<Value>SynchTimeUnit</Value>
</Value>
<Value name="17">
<Value>NCores</Value>
</Value>
<Value name="18">
<Value>ExprTime</Value>
</Value>
<Value name="19">
<Value>iKnowTime</Value>
</Value>
<Value name="20">
<Value>TotalTime</Value>
</Value>
<Value name="21">
<Value>AsynchUpdate</Value>
</Value>
<Value name="22">
<Value>AgentCount</Value>
</Value>
<Value name="23">
<Value>ErrorCount</Value>
</Value>
<Value name="24">
<Value>MissingRefs</Value>
</Value>
<Value name="25">
<Value>DependencyExempt</Value>
</Value>
</Data>
<DataLocation>^DeepSee.CubeManager.CubeEventD</DataLocation>
<DefaultData>CubeEventDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^DeepSee.CubeManager.CubeEventD</IdLocation>
<IndexLocation>^DeepSee.CubeManager.CubeEventI</IndexLocation>
<StreamLocation>^DeepSee.CubeManager.CubeEventS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
