/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// The class responsible for organizing the information about the registered state of all cubes on the system.
Class %DeepSee.CubeManager.RegistryMap Extends (%RegisteredObject, %XML.Adaptor, %JSON.Adaptor) [ System = 4 ]
{

/// The collection of groups that are defined in the overall sysem registry map
Relationship Groups As %DeepSee.CubeManager.RegistryMapGroup [ Cardinality = many, Inverse = Map ];

/// The hour of the acceptable build window for the day,
/// used to construct the timestamp that defines the window when builds may be started.
Property BuildStartHour As %String(VALUELIST = ",00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23") [ InitialExpression = "21" ];

/// The quater hour of the acceptable build window for the day,
/// used to construct the timestamp that defines the window when builds may be started.
Property BuildStartMinute As %String(VALUELIST = ",00,15,30,45") [ InitialExpression = "00" ];

/// <var>Disabled</var> = true will suspend the automated Build and Synch tasks for this namespace.
Property Disabled As %ZEN.Datatype.boolean;

/// Controls whether cubes within a group are synchronized based on the relationship dependency (the default)
/// or if it synchronizes solely based on schedule.
Property IndependentSync As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If this property is set to 1, the updater tasks will not job off the group update code
/// and will instead run all updates in a single process.
Property SerialUpdates As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// When this is loaded into memory, this stores the name of the class 
/// the map was loaded from.
Property StorageClass As %String(XMLPROJECTION = "NONE");

/// Description of this registry definition.
Property Description As %String(MAXLEN = 2500);

/// This is a flag that can be set in the stored registry to prevent users from being able to adjust the 
/// Disabled setting and prevents builds from this item in the registry.
Property UserUpdatesLocked As %ZEN.Datatype.boolean [ Internal ];

/// Diagnostic method, prints information about the current map.
Method Print()
{
	w !,"==== Current Registry Map ===="
	w !,"Namespace: ",$NAMESPACE
	w !,"Storage Class: ",..StorageClass
	If (..Groups.Count() = 0) {
		w !!,?2,"There are no groups in this registry",!
	} 
	Else {
		set tGroupIndex = ""
		for ii=1:1:..Groups.Count() {    				// Loop on Groups
			set tGroup = ..Groups.GetNext(.tGroupIndex)
			w !,?2,tGroup.GroupName
			w ?35,"IsReg = ",tGroup.IsRegistered
			w ?50,"IsValid = ",tGroup.IsValid
			w ?60,"Disabled = ",tGroup.Disabled  
			
			set tCubeIndex = ""
			for jj=1:1:tGroup.Cubes.Count() {			// Loop on cubes within group
				set tCube = tGroup.Cubes.GetNext(.tCubeIndex)
				w !,?4,tCube.CubeDisplayName
				w ?37,"Disabled = ",tCube.Disabled
				w ?52,"DSTIME = ",tCube.DSTimeEnabled
				
				set tSAIndex = ""
				for kk=1:1:tCube.SubjectAreas.Count() {	// Loop on subject areas pointing to each cube
					set tSA = tCube.SubjectAreas.GetNext(.tSAIndex)
					w !,?6,tSA.SADisplayName
					w ?39,"IsCompound = ",tSA.IsCompound
				}
			}
		}
	}
}

/// Converts the current map into an array. If this is the full 
/// {registered}U{unregistered} map, the first three arrays will match those returned using the call<br>
/// ##class(<class>%DeepSee.CubeManager.Utils</class>).GetCubeGroups(.pGroups,.pCubes,.pBuildOrders)<br>
/// This method also returns a special lookup index which can be used to quickly reference the group or 
/// cube objects contained in the current map object.
/// <example>
/// Set CubeName = "HOLEFOODS"
/// Set Map = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap()
/// Do Map.ToArray(.Groups,.Cubes,.BuildOrders,.Lookup)
/// Set GroupIdx = $LG(Lookup("cubes",CubeName),1)
/// Set CubeIdx = $LG(Lookup("cubes",CubeName),2)
/// Set Cube = Map.Groups.GetAt(GroupIdx).Cubes.GetAt(CubeIdx)
/// </example>
Method ToArray(ByRef pGroups, ByRef pCubes, ByRef pBuildOrders, ByRef pLookup) As %Status
{
	Kill pGroups,pCubes,pBuildOrders,pLookup
	Set tSC = $$$OK
	Try {
		Set tGroupIndex = ""
		For ii=1:1:..Groups.Count() {
			Set tCurrentGroup = ..Groups.GetNext(.tGroupIndex)
			Set tCubeIndex = ""
			For jj = 1:1:tCurrentGroup.Cubes.Count() {
				Set tCurrentCube = tCurrentGroup.Cubes.GetNext(.tCubeIndex)
				Set tGroupName = tCurrentGroup.GroupName
				Set tCubeKey = tCurrentCube.CubeKey
				If tCurrentCube.CustomBuildOrder'="" {
					Set tBuildOrder = tCurrentCube.CustomBuildOrder
				} Else {
					Set tBuildOrder = tCurrentCube.NaturalBuildOrder
				}
				Set pGroups(tGroupName,tCubeKey) = tBuildOrder
				Set pCubes(tCubeKey) = tGroupName
				If $L(tCurrentCube.DependentCubes)>0 {
					Set pCubes(tCubeKey,"dependents") = $L(tCurrentCube.DependentCubes,",")
					For kk=1:1:pCubes(tCubeKey,"dependents") {
						Set pCubes(tCubeKey,"dependents",$P(tCurrentCube.DependentCubes,",",kk))=""
					}
				}
				Set pBuildOrders(tGroupName,tBuildOrder) = tCubeKey
				Set pLookup("cubes",tCubeKey) = $LB(tGroupIndex,tCubeIndex)
			}	
			Set pLookup("groups",tGroupName) = tGroupIndex
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Definition for the table view of the overall cube list,
/// as used by the Cube Registry page
Query RegistryMapTableView(pSearchKey As %String = "") As %Query(CONTAINID = 1, ROWSPEC = "CubeKey:%String,MgmtGroup:%String,NaturalBuildOrder:%Integer,CustomBuildOrder:%Integer,UpdatePlan:%String,Disabled:%String,BuildFrequency:%Integer,BuildTimeUnit:%String,SynchFrequency:%Integer,SynchTimeUnit:%String,IsRegistered:%String,BuildEvery:%String,SynchEvery:%String,DSTimeEnabled:%String,GroupIdx:%Integer,CubeIdx:%Integer") [ Internal, SqlProc ]
{
}

/// This does the actual work of building the rows of the 
/// Cube Registry table view.
ClassMethod RegistryMapTableViewExecute(ByRef pResults As %Binary, pSearchKey As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pResults = 1
	Set tGroupIndex = ""
	Set k = ""
	
	Set pSearchKey = $$$UPPER(pSearchKey)
	Set tRegistryMap = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap()
	
	Try {
		For i=1:1:tRegistryMap.Groups.Count() {
			Set tCurrentGroup = tRegistryMap.Groups.GetNext(.tGroupIndex)	
			Set tUserUpdatesLocked = tCurrentGroup.UserUpdatesLocked		// DTB691
			Set tCubeIndex = ""
			For j = 1:1:tCurrentGroup.Cubes.Count() {
				Set tCurrentCube = tCurrentGroup.Cubes.GetNext(.tCubeIndex)
				Set tBuildEvery = $S(('tCurrentGroup.IsRegistered)||tUserUpdatesLocked:"",		// DTB691
										(tCurrentCube.UpdatePlan '[ "Build"):"",
										1:tCurrentCube.BuildFrequency_" "_tCurrentCube.BuildTimeUnit)
				Set tSynchEvery = $S(('tCurrentGroup.IsRegistered)||tUserUpdatesLocked:"",		// DTB691
										(tCurrentCube.UpdatePlan '[ "Synch"):"",
										1:tCurrentCube.SynchFrequency_" "_tCurrentCube.SynchTimeUnit)
				Set tUpdatePlan = $S(('tCurrentGroup.IsRegistered)||tUserUpdatesLocked:"",		// DTB691
										1:tCurrentCube.UpdatePlanLogicalToDisplay(tCurrentCube.UpdatePlan))
				
				If ('$D(pSearchKey) || (tCurrentCube.CubeKey [ pSearchKey)) {
					Set pResults($increment(k)) = $LB(tCurrentCube.CubeKey,
															tCurrentCube.Group.GroupName,
															tCurrentCube.NaturalBuildOrder,
															tCurrentCube.CustomBuildOrder,
															tUpdatePlan,
															$S(tCurrentCube.Disabled:"Yes",1:"No"),
															tCurrentCube.BuildFrequency,
															tCurrentCube.BuildTimeUnit,
															tCurrentCube.SynchFrequency,
															tCurrentCube.SynchTimeUnit,
															$S(tCurrentGroup.IsRegistered:"Yes",1:"No"),
															tBuildEvery,
															tSynchEvery,
															$S(tCurrentCube.DSTimeEnabled:"Yes",1:"No"),
															i,			// DTB133 - add GroupIdx to output
															j)			// DTB133 - add CubeIdx to output
				} 
			}	
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
    Quit tSC
}

/// Fetch method to retrieve a given row from the Cube Registry
/// table representation.
ClassMethod RegistryMapTableViewFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = RegistryMapTableViewExecute ]
{
	If qHandle > $o(qHandle(""),-1) {
		Set AtEnd = 0
		Quit $$$OK	
	}
	Set Row = qHandle(qHandle)
	Set qHandle = $increment(qHandle)
	Quit $$$OK
}

ClassMethod RegistryMapTableViewClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = RegistryMapTableViewExecute ]
{
    // query cleanup code here
    Quit $$$OK
}

/// Serializes the current Registry structure into XML inside the 
/// XData block in the relevant Registry class.
Method SaveToClass(pClassName = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB737 - Validate map before proceeding with the save
		Set tSC = ..Validate()
		If $$$ISERR(tSC) Quit
		
		// Create the XML writer and prepare it for writing to the class definition
		Set tWriter = ##class(%XML.Writer).%New()
        Set tWriter.NoXMLDeclaration = 1
        Set tWriter.Indent = 1

        Set tStream = ##class(%Stream.TmpCharacter).%New()
        Set tSC = tWriter.OutputToStream(tStream)
        If $$$ISERR(tSC) Quit
        
        Set tSC = tWriter.RootObject($this)
        If $$$ISERR(tSC) Quit
       
        If (pClassName '= "") {
	        Set tClassName = pClassName
        }
        ElseIf (..StorageClass '="") {
			Set tClassName = ..StorageClass
        } 
        Else {
        	Set tClassName = "DeepSee.CubeManager.CubeRegistryDefinition"
        }
        
        // Check to see if we need to create this class, or if we have saved this before.
        Set tDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName,,.tSC)
        If $system.Status.Equals(tSC,$$$ERRORCODE($$$LoadObjectNotFound)) {
            Set tSC = $$$OK
            Set tDefinition = ##class(%Dictionary.ClassDefinition).%New()
            Do tDefinition.NameSet(tClassName)
            Do tDefinition.SuperSet("%DeepSee.CubeManager.RegistryDefinitionSuper")
        }
        ElseIf $$$ISERR(tSC) {
            Quit
        }
        
        If tDefinition.Super'["%DeepSee.CubeManager.RegistryDefinitionSuper" {
	        $$$ThrowStatus($$$ERROR($$$GeneralError,$$$Text("Class exists, but is not a valid Cube Registry storage class","%DeepSee")_": "_tClassName))
        }
        Else {
            // Remove current XData block if the class existed already
            Set tXDataLoc = tDefinition.XDatas.FindObjectId(tClassName_"||Registry")
            If tXDataLoc'="" Do tDefinition.XDatas.RemoveAt(tXDataLoc)
        }
        Set tDefinition.GeneratedBy = "%DeepSee.CubeManager.Utils"
        Do tDefinition.DescriptionSet("Cube Registry storage.<br/>"_$C(13,10)_
        							"THIS IS A GENERATED CLASS, DO NOT EDIT.<br/>"_$C(13,10)_
        							"Generated by the Cube Manager.<br/>"_$C(13,10)_
        							"Last saved "_$ZDT($H,3)_".")
        
        // Create the new XData block and write the stream to it
        Set tXData = ##class(%Dictionary.XDataDefinition).%New()
 
        Set tXData.Name = "Registry"
        Set tXData.parent = tDefinition
        Set tXData.XMLNamespace = "http://www.intersystems.com/deepsee"
        Do tStream.Rewind()
        
        Set tSC = tXData.Data.CopyFrom(tStream)
        If $$$ISERR(tSC) Quit
    
        Set tSC = tDefinition.%Save()
        If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus() 
	}
	Quit tSC
}

/// Deserialize the XML from the Registry XData block into a RegistryMap model.
ClassMethod LoadFromClass(pClassname As %String, Output pStatus As %Status) As %DeepSee.CubeManager.RegistryMap
{
	
    Set pStatus = $$$OK
    Try { 
        If $get(pClassname)= "" {
            Set pStatus = $$$ERROR($$$ClassNameInvalid, "")
            Quit
        }
        
        Set pClassname = $$$NormalizeClassname(pClassname)
        
        Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(pClassname,"Registry",,.pStatus)
	    If $$$ISERR(pStatus) Quit

        If tXData = "" {
            Set pStatus = $$$ERROR($$$LoadObjectNotFound)
            Quit
        }
        
        Set tReader = ##class(%XML.Reader).%New()
        
        Set pStatus = tReader.OpenStream(tXData.Data)
        If $$$ISERR(pStatus) Quit
        
        Do tReader.Correlate("RegistryMap", "%DeepSee.CubeManager.RegistryMap")
      
        If 'tReader.Next(.tRegistry, .pStatus) {
            If $$$ISERR(pStatus) Quit
            Set pStatus = $$$ERROR($$$LoadObjectNotFound)
            Quit
        }
    }
    Catch ex {
        Set pStatus = ex.AsStatus()
    }
    // If we had an error, return an empty map
    If ($$$ISERR(pStatus)) {
    	Do ##class(%DeepSee.Utils).%WriteToLog("CubeMgr",$system.Status.GetOneErrorText(pStatus))		// DTB449
    	Set tRegistry = ##class(%DeepSee.CubeManager.RegistryMap).%New()
    }
  
    Set tRegistry.StorageClass = pClassname

    Quit tRegistry
}

/// Return the current build time in hh:mm:ss format.
Method CreateMapTimeStamp() As %String
{
	Quit ..BuildStartHour _ ":" _ ..BuildStartMinute _ ":00"
}

/// Perform validation on the Map object to determine if it is ready for save.
Method Validate() As %Status
{
	// Method added by DTB737
	Set tSC = $$$OK
	
	Try {
		Set tGroupIndex = ""
		For g=1:1:..Groups.Count() {
			Set tGroup = ..Groups.GetNext(.tGroupIndex)
			
			If $D(tGroups(tGroup.GroupName)) {
				Set tSC = $$$ERROR($$$GeneralError,"Duplicate group name encountered in RegistryMap groups: "_tGroup.GroupName)
				$$$ThrowStatus(tSC)
			}
			Else {
				Set tGroups(tGroup.GroupName) = ""
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
