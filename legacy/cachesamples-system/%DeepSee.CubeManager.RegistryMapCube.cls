/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Contains the information about a specific cube within the registry map.
Class %DeepSee.CubeManager.RegistryMapCube Extends (%RegisteredObject, %XML.Adaptor, %JSON.Adaptor) [ System = 4 ]
{

/// The group this cube currently belongs to
Relationship Group As %DeepSee.CubeManager.RegistryMapGroup [ Cardinality = one, Inverse = Cubes ];

/// Group of subject areas that use this cube
Relationship SubjectAreas As %DeepSee.CubeManager.RegistryMapSubjectArea [ Cardinality = children, Inverse = BaseCube ];

/// Normalized Key of the cube
Property CubeKey As %ZEN.Datatype.string;

/// Current display name of the cube
Property CubeDisplayName As %ZEN.Datatype.string;

/// Store the information about this cube's minimal natural group
Property NaturalGroup As %String;

/// This is the cube's position within the determined build order for the group as a whole.
Property CustomBuildOrder As %Integer;

/// The build order that must be maintained within a cub'es natural group.
Property NaturalBuildOrder As %Integer;

/// Last modification date of this cube definition
Property LastModDate As %String(%JSONINCLUDE = "OUTPUTONLY", XMLPROJECTION = "NONE") [ Calculated ];

/// Last data update of this cube
Property LastUpdate As %String(%JSONINCLUDE = "OUTPUTONLY", XMLPROJECTION = "NONE") [ Calculated ];

/// Plan for how the cube is to be managed by the build/synch tasks.
Property UpdatePlan As %String(DISPLAYLIST = ",Manual,Build Only,Build and Synch,Synch Only", VALUELIST = ",Manual,Build,BuildSynch,Synch") [ InitialExpression = "BuildSynch" ];

/// <var>Disabled</var> = 1 will block all automatic updates while leaving the 
/// cube visible in the registry.
Property Disabled As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Indicates how often the cube is to be built, in units of
/// <var>BuidTimeUnit</var> 
Property BuildFrequency As %Integer [ InitialExpression = 1 ];

/// Base unit of time for cube builds. 
Property BuildTimeUnit As %String(DISPLAYLIST = ",Day,Week,Month", VALUELIST = ",Day,Week,Month") [ InitialExpression = "Week" ];

/// If week is selected for the BuildTimeUnit, this will allow the user to pick which day
/// of the week the build should take place.
Property BuildDayOfWeek As %String(DISPLAYLIST = ",Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday", VALUELIST = ",1,2,3,4,5,6,7") [ InitialExpression = "1" ];

/// If Month is selected as the BuildTimeUnit, this will allow the user to pick which day
/// of the month this build should take place.
Property BuildDayOfMonth As %Integer(MAXVAL = 31, MINVAL = 1) [ InitialExpression = 1 ];

/// Indicates how often the cube is to be synched, in units of
/// <var>SynchTimeUnit</var>
Property SynchFrequency As %Integer [ InitialExpression = 1 ];

/// Base unit of time for cube synchs.
Property SynchTimeUnit As %String(DISPLAYLIST = ",Minute,Hour,Day", VALUELIST = ",Minute,Hour,Day") [ InitialExpression = "Day" ];

/// Indicates whether or not the source class for this cube is DSTIME enabled, and so 
/// whether or not this cube can be synched. 
Property DSTimeEnabled As %ZEN.Datatype.boolean(%JSONINCLUDE = "OUTPUTONLY") [ Calculated ];

/// Flag which allows the user to select whether the build executes
/// synchronously or asynchronously. Asynchronous build is the default.
Property BuildAsynch As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// A COS executable line of code that will be run prior to the synchronization
/// of this cube.
Property PreSynchCode As %ZEN.Datatype.string(MAXLEN = "");

/// A COS executable line of code that will be run immediately after the synchronization
/// of this cube.
Property PostSynchCode As %ZEN.Datatype.string(MAXLEN = "");

/// A COS executable line of code that will be run immediately after the build
/// of this cube.
Property PostBuildCode As %ZEN.Datatype.string(MAXLEN = "");

/// A comma-delimited list of cubes that have relationship dependencies on this one
Property DependentCubes As %ZEN.Datatype.string(MAXLEN = "");

/// Transient property to indicate whether the cube should ignore dependencies when synchronized. This is
/// not stored as part of the registry definition and is controlled by the RegistryMap setting and 
/// environmental settings.
Property IndependentSync As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

Method %OnNew(pCubeName = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..CubeKey = pCubeName
 	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method UpdateSubjectAreas() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..SubjectAreas.Clear()
		If $$$ISERR(tSC) Quit

		Do ##class(%DeepSee.Utils).%GetCubeList(.tList,"subjectAreas",1,..CubeKey)
		Set tSubjectName = $O(tList(""))
		While tSubjectName'="" {
			Set tSubject = ##class(%DeepSee.CubeManager.RegistryMapSubjectArea).%New()
			Set tSubject.SAName = tSubjectName
			
			Do ..SubjectAreas.Insert(tSubject)				
			Set tSubjectName = $O(tList(tSubjectName))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convenience method for the UI interface to perform a repair build
/// of this cube's entire dependency chain.
Method Repair(pMap As %DeepSee.CubeManager.RegistryMap = "") As %Status
{
	Set tSC = ##class(%DeepSee.CubeManager.Utils).RepairBuild(..CubeKey,pMap,..BuildAsynch,0)
	If $$$ISERR(tSC) {
		Do ##class(%DeepSee.Utils).%WriteToLog("Cube.Repair",$system.Status.GetErrorText(tSC)_":"_$NAMESPACE)
		Quit 0
	}
	
	Quit tSC
}

Method DSTimeEnabledGet() As %Boolean
{
	// Look up the dstime setting for this cube's source class
	Try {
		Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(..CubeKey,.tSC)
		If $$$ISERR(tSC) Quit
		Set tSC = $zobjclassmethod(tClassName,"%GetSourceInfo",.tSourceInfo)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Do ##class(%DeepSee.Utils).%WriteToLog("DSTimeEnabledGet",$system.Status.GetErrorText(tSC)_":"_$NAMESPACE)
		Quit 0
	}

	Quit ( $G(tSourceInfo("dstime"))'="" )
}

Method CubeDisplayNameGet() As %String
{
	Set tDisplayName = ##class(%DeepSee.Utils).%GetCubeCaption(..CubeKey,.tSC)
	If $$$ISERR(tSC) {
		Quit $system.Status.GetErrorText(tSC)
	} Else {
		Quit tDisplayName
	}
}

Method LastModDateGet() As %String
{
	Quit ##class(%DeepSee.Utils).%GetCubeModifiedDate(..CubeKey)
}

Method LastUpdateGet() As %String
{
	Quit ##class(%DeepSee.CubeManager.Utils).GetLastUpdate(..CubeKey)
}

}
