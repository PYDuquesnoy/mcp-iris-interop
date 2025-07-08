/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This extends the build dialog to build the set of dependent cubes
/// needed to "Repair" a given cube's integrity
Class %DeepSee.UI.Dialog.RepairBuild Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeList As %ZEN.Datatype.string(ZENURL = "CUBELIST");

/// Group Name, for repair and group modes we can use
/// "pseudo group" 1
Property group As %ZEN.Datatype.string(ZENURL = "GROUP");

/// Mode options are:<br> 
/// all - Initiate a full build of all groups in the registry<br>
/// group - Inititate a full build of a single group in the registry<br>
/// repair - Inititate a build of a single cube, along with the minimal set of cubes dependent upon it.
Property mode As %ZEN.Datatype.string(ZENURL = "MODE");

/// Id used to track progress.
Property trackingId As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
#statusgroup .statusTable {
	background: white;
	border: 1px solid #404040;
	width: 500px;
}

#statusgroup .statusTable td {
	padding: 2px;
	padding-right: 5px;
	padding-left: 5px;
	border-right: 1px solid #808080;
	border-bottom: 1px solid #808080;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<textarea id="cubeName" label="Cube Build List" cols="30" rows="5" readOnly="true" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

<radioSet id="buildOption" label="Build Option" value="all" valueList="all,incremental" displayList="Build Everything,Incremental Update" hidden="true"/>
<button id="btnBuild" caption="Build List" title="Click here to start an ordered build of the entire list above" onclick="zenPage.startBuild();"/>
<timer id="cleanupTimer" ontimeout="zenPage.cleanup();"/>
<vgroup id="statusgroup" name="statusgroup" >
</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Build Cube List")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Ordered build of the selected list of cubes")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	zen("btnBuild").focus();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeList = ..cubeList
		Set tCubeCount = 0
		
		// Used info from saved, safe map, not current JSON object. 
		// Both should now be exctly the same with DTB050
		// DTB241 - This map is now used in all three cases
		Set Map = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC,,1,.Lookup)
		If $$$ISERR(tSC) $$$ThrowStatus(tSC)
		
		/* ALL MODE */
		If (..mode="all") {
			Set tBuildOrder=""
			
			// Get all cubes in this group in the build index order
			Set tGroupIdx = ""
			Set tInvalidGroup = 0
			Set tCurrentGroup = Map.Groups.GetNext(.tGroupIdx)
			While (tGroupIdx'="") {
				If 'tCurrentGroup.Disabled {
					Set tCubeIdx = ""
					Set Cube = tCurrentGroup.Cubes.GetNext(.tCubeIdx)
					While (tCubeIdx '="") {
						Set tCubeCount=tCubeCount+1
						Set tBuildOrder(1,$I(tBuildOrder))=Cube.CubeKey
						Set Cube = tCurrentGroup.Cubes.GetNext(.tCubeIdx)
					}
				}
				Set tCurrentGroup = Map.Groups.GetNext(.tGroupIdx)
			}
			Quit:tInvalidGroup	// DTB241 - Fully Quit the Try block if a gorup was found to be invalid
		} /* END ALL MODE */
		If (..mode="group") {
			Set tBuildOrder=""
			Set tGroupIdx = Lookup("groups",..group)
			Set tCurrentGroup = Map.Groups.GetAt(tGroupIdx)
			
			Set tCurrentCubeIdx = ""
			Set Cube = tCurrentGroup.Cubes.GetNext(.tCurrentCubeIdx)
			While (tCurrentCubeIdx '="") {
				Set tCubeCount=tCubeCount+1
				Set tBuildOrder(1,$I(tBuildOrder))=Cube.CubeKey
				Set Cube = tCurrentGroup.Cubes.GetNext(.tCurrentCubeIdx)
			}
		} /* END GROUP MODE */
		If (..mode="repair") {
			For i=1:1:($Length(tCubeList,$c(10))-1) {
				Set tGroups(1,$p(tCubeList,$c(10),i)) = ""	
			}
			
			// DTB241 - In the dependency list case, test the validity of the group containing the first cube in the list
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			Set tTestCube = $$$UPPER($p(tCubeList,$c(10),1))
			Set tGroupIdx = $LG(Lookup("cubes",tTestCube),1)
			
			Set tSC = ##class(%DeepSee.CubeManager.Utils).FindGroupBuildOrders(.tGroups)
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)
	
			//Prune the new group build order item
			For i=1:1:($Length(tCubeList,$c(10))-1) {
				Set tCubeCount=tCubeCount+1
				Set tBuildOrder(1,tGroups(1,$p(tCubeList,$c(10),i))) = $p(tCubeList,$c(10),i) 
			}
		}
				
  		Set tStatusGroup = ##class(%ZEN.Component.group).%New()
  		Do %page.%GetComponentById("statusgroup").%AddChild(tStatusGroup)
  		
		// Loop through build ordered list of cubes and create
		// a timer and status area for each cube
		//Set ..cubeList=""
		Set i = $order(tBuildOrder(1,""))
		set tCubeIndex=""
		Set tOrderedCubeList = ""		// DTB131
		While (i'="") {
			Set tCubeIndex=$increment(tCubeIndex)
			Set tCurrentCubeName = tBuildOrder(1,i)
  			Set tStatus = ##class(%ZEN.Component.html).%New()
  			Set tStatus.id = "status" _ tCurrentCubeName
  			Set tTimer = ##class(%ZEN.Component.timer).%New()
  			Set tTimer.id = "timer" _ tCurrentCubeName
  			Set tSpacer = ##class(%ZEN.Component.spacer).%New()
  			Set tSpacer.id = "spacer" _ tCurrentCubeName
  			Set tSpacer.height = 25
  			// Tell each timer which cube to care about and whether cleanup should be done once finished
			Set tTimer.ontimeout = "zenPage.updateStatus('" _ tCurrentCubeName _ "'," _ $s((tCubeIndex=tCubeCount):1,1:0) _ ");"
  			Do tStatusGroup.%AddChild(tStatus)
  			Do tStatusGroup.%AddChild(tTimer)
  			Do tStatusGroup.%AddChild(tSpacer)
  			Set tOrderedCubeList = $G(tOrderedCubeList) _ tBuildOrder(1,i) _ $c(10)
  			Set i = $order(tBuildOrder(1,i))
		}
		Set ..cubeList=$G(tOrderedCubeList)
		
		// DTB050 - Adjust the height of the textbox
		Set tRows = $L(tOrderedCubeList,$C(10))
		Set tListDisplay = ..%GetComponentById("cubeName")
		Set tListDisplay.rows = $S(tRows<15:tRows,1:15)
		
		// Use the updated, ordered cubelist
		If (..cubeList'="") {
			Set %page.%GetComponentById("cubeName").value = ..cubeList
		}
		Else {
			// DTB131 - dialog was launched with no cubes registered
			Set tCubeText = %page.%GetComponentById("cubeName")
			Set tCubeText.value = $$$Text("No cubes are selected for build")
			Set tCubeText.cols = 60
			Set %page.%GetComponentById("btnBuild").disabled = 1
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Lock the Build List button and display an error indicating there is a problem.
ClassMethod %LockWithError(pError) As %Status
{
	// Method added by DTB241
	Set tSC = $$$OK
	Try {
		Set tStatusGroup = ##class(%ZEN.Component.group).%New()
  		Do %page.%GetComponentById("statusgroup").%AddChild(tStatusGroup)
		Set %page.%GetComponentById("btnBuild").disabled = 1
		Set %page.%GetComponentById("cubeName").disabled = 1
		Set tStatus = ##class(%ZEN.Component.html).%New()
		Set tStatus.id = "statusGroupError"
		Set tStatus.content = "<p><font color=""red"">"_$system.Status.GetErrorText(pError)_"</font><p>"
		Do tStatusGroup.%AddChild(tStatus)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Start the index build.
ClientMethod startBuild() [ Language = javascript ]
{
	var cubeList = this.cubeList.split("\n");
		this.currentCube=cubeList[0];	
		var option = zen('buildOption').getValue();
		switch(option) {
		case 'all':
			zen('btnBuild').setDisabled(true);
			var test = new zenProxy();
			// base this on mode
			if (this.mode=='repair') {
				this.trackingId = this.RepairBuild(this.currentCube);
			}
			else if (this.mode=='group') {
				this.trackingId = this.BuildOneRegisteredGroup(this.group);
			}
			else if (this.mode=='all') {
				this.trackingId = this.BuildAllRegisteredGroups();
			}
			// otherwise call the right method
			if (this.trackingId!='') {
				for (var i = 0; i < (cubeList.length - 1); i++) {
					zen('timer'+cubeList[i]).timeout = 500;
					zen('timer'+cubeList[i]).startTimer();
				}
			}
			else {
				zen('btnBuild').setDisabled(false);
			}
			break;
		case 'incremental':
			break;
		}
	return;
}

/// Start the repair build process in the background
/// Return the ID of the child process for tracking
/// Start the build cube process in the background.
/// Return the tracking id.
ClassMethod RepairBuild(pCubeName As %String) As %String [ ZenMethod ]
{
	Set tTrackingId = ""
	Set tJobTimeOut = 10
	
	Job ##class(%DeepSee.CubeManager.Utils).RepairBuild(pCubeName,"",1,0,0,0,1)::tJobTimeOut
	If '$Test {
		&js<alert('Unable to start background job.');>
		Set tTrackingId = ""
	}
	Else {
		Set tTrackingId = $ZChild
	}
	Quit tTrackingId
}

ClassMethod BuildOneRegisteredGroup(pGroupName As %String) As %String [ ZenMethod ]
{
	Set tTrackingId = ""
	Set tJobTimeOut = 10
	
	Job ##class(%DeepSee.CubeManager.Utils).BuildOneRegisteredGroup(pGroupName)::tJobTimeOut
	If '$Test {
		&js<alert('Unable to start background job.');>
		Set tTrackingId = ""
	}
	Else {
		Set tTrackingId = $ZChild
	}
	Quit tTrackingId
}

ClassMethod BuildAllRegisteredGroups() As %String [ ZenMethod ]
{
	Set tTrackingId = ""
	Set tJobTimeOut = 10
	
	Job ##class(%DeepSee.CubeManager.Utils).BuildAllRegisteredGroups()::tJobTimeOut
	If '$Test {
		&js<alert('Unable to start background job.');>
		Set tTrackingId = ""
	}
	Else {
		Set tTrackingId = $ZChild
	}
	Quit tTrackingId
}

/// Get the current status of the background task.
ClassMethod CheckCompletedStatus(pTrackingId As %String, pCubeName As %String) As %String [ ZenMethod ]
{
	Set tOutput = ""
	Set tIsComplete = 0

	If ('$D(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName))) quit "NotStarted"
	
	If ($G(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName)) = "Completed") quit "Completed"
	
	Set tStep = $O(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName,""),1,info)
	
	While (tStep'="") {
		If ($G(tLastStep)=0) {
			// DTB975 - Reset the output if the server has moved on to the actual progress reporting 
			Set tOutput = ""
		}
		
		Set tIsActive = ($O(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName,tStep))="")
		Set tPhase = $LG(info,1)
		Set:tPhase="complete"!(tPhase="error") tIsComplete = 1
		// DTB975 - Add "begin" phase
		Set tMsg = $Case(tPhase,"begin":$$$Text("Begin build"),"delete":$$$Text("Deleting facts"),"facts":$$$Text("Building facts"),"indices":$$$Text("Building indices"),"aggs":$$$Text("Computing aggregates"),"iknow":$$$Text("Processing iKnow measures"),"error":$$$Text("Error"),:$$$Text("Complete"))
		Set tCount = $LG(info,2)
		Set tPct = $LG(info,3)
		Set tErr = $LG(info,4)
		If (tCount="") {
			Set tCount = "&nbsp;"
		}
		Else {
			Set tCount = $FN(tCount,",") _ " " _ $$$Text("fact(s)")
		}
		If (tPct="") {
			Set tPct = "&nbsp;"
		}
		Else {
			Set tPct = $FN(tPct,",",2) _ "%"
		}
		Set tOutput = tOutput _ "<tr style="""_$S(tErr'="":"color:#da4848;",tIsActive:"font-weight:bold;",1:"background:#E0E0F0;")_""">"
		Set tOutput = tOutput _ "<td>"_tMsg_"</td>"
		If tErr = "" {
			Set tOutput = tOutput _ "<td align=""right"">"_tCount_"</td>"
			Set tOutput = tOutput _ "<td align=""right"">"_tPct_"</td>"
			Set tOutput = tOutput _ "<td>"_$S(tIsActive:"&nbsp;",1:$$$Text("Complete"))_"</td>"
			Set tOutput = tOutput _ "<td>&nbsp;</td>"
		} Else {
			/// Write out errors
			Set tOutput = tOutput _ "<td colspan=""4"">"_$ZCVT(tErr,"O","HTML")_"</td>"
		}
		Set tOutput = tOutput _ "</tr>"
		
		Set tLastStep = tStep		// DTB975
		Set tStep = $O(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName,tStep),1,info)
	}
	If (tOutput'="") {
		Set tOutput = "<div><b>"_pCubeName_" "_$$$Text("Status")_ "</b></div><div></div><table class=""statusTable"" cellspacing=""0"" width=""100%"">" _ tOutput _ "</table>"
	}
	
	If (tIsComplete) {
		Set ^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName) = "Completed"
	}

	Quit tOutput
}

/// Update the status area.
ClientMethod updateStatus(cubeName, final) [ Language = javascript ]
{
	var status = this.CheckCompletedStatus(this.trackingId,cubeName);
	var html = zen('status'+cubeName );
	if (status == 'NotStarted') {
		// Keep waiting on this cube to start building
		zen('timer'+cubeName).timeout = 250;
		zen('timer'+cubeName).startTimer();
	} else if (status != 'Completed') {
		// This means that the cube has started 
		// updating but isn't yet finished
		html.setContent(status);
		zen('timer'+cubeName).timeout = 250;
		zen('timer'+cubeName).startTimer();
	} 
	
	if (final != '') {
		// use a timer for cleanup since other timers may be pending
		// if the last cube is complete, the others are done but we may
		// be waiting on a timer for a a maximum of 250 msec, so set 
		// this timer for 500 msec
		zen('cleanupTimer').timeout=500;
		zen('cleanupTimer').startTimer();
	}
	return;
}

ClientMethod cleanup() [ Language = javascript ]
{
	zen('btnBuild').setDisabled(false);
	// when build finished, set focus on OK button so [Enter] key will exit easily.
	zen("btnOK").focus();
	
	// clear the tracking globals
	zenPage.ClearTracking(this.trackingId);
	this.trackingId = '';
}

ClassMethod ClearTracking(pTrackingId As %String) [ ZenMethod ]
{
	Kill ^IRIS.Temp.DeepSeeTracking(pTrackingId)
	Kill ^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId)
}

}
