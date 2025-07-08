/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog builds facts and indices for a DeepSee cube and displays the output.
/// !!! % complete, view log file, show errors, make non-modal!!!
Class %DeepSee.UI.Dialog.CubeBuild Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube class name.
Property cubeClass As %ZEN.Datatype.string(ZENURL = "CLASS");

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Full list of cubes that a build on the target cube will update
Property cubeList As %ZEN.Datatype.string;

/// The maximum number of records for be built defined for the selected cube
Property maxFacts As %ZEN.Datatype.string(ZENURL = "maxFacts");

/// A list may be supplied to indicate that a known list of dimensions has been modified. This can be used to pre-set
/// selected build lists.
Property factsModifiedList As %ZEN.Datatype.string(ZENURL = "MODIFIED");

/// The maximum number of records to be built for the the selected cube in this session (overrides maxFacts)
Property TempMaxFacts As %ZEN.Datatype.string;

/// Id used to track progress.
Property trackingId As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
#status .statusTable {
	background: white;
	border: 1px solid #404040;
	width: 500px;
}

#status .statusTable td {
	padding: 2px;
	padding-right: 5px;
	padding-left: 5px;
	border-right: 1px solid #808080;
	border-bottom: 1px solid #808080;
}

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
<vgroup cellStyle="padding-bottom: 4px;">
<label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" controlClass="labelValue"/>
<textarea id="dependentCubes" label="Dependent Cubes" cols="30" rows="5" readOnly="true"/>
<text id="TempMaxFacts" label="Maximum Number of Records to Build" value="#(%page.TempMaxFacts)#" size="5"
hint="If blank or zero, DeepSee builds all the records."/>
<html id="prevBuildFinished"/> 
<spacer height="15"/>
<radioSet id="buildOption" layout="vertical" label="Build Option" value="all" valueList="all,selected" displayList="Build Everything,Selective Build" onchange="zenPage.toggleDimSelection(zenThis.value);" hidden="false"/>
<group id="buildCheckLists" hidden="true" label="Select model elements to build">
<hgroup>
<link id="linkSelectAll" caption="Select All" href="javascript:zenPage.setAllCheckLists(true);"/>
<spacer width="10px"/>
<link id="linkClearAll" caption="Clear All" href="javascript:zenPage.setAllCheckLists(false);"/>
</hgroup>
<multiSelectSet id="measuresList" valign="top" value="" label="Measures" onchange="zenPage.changeDimSelection();"/>
<multiSelectSet id="dimensionsList" valign="top" value="" label="Dimensions" onchange="zenPage.changeDimSelection();"/>
<multiSelectSet id="relationshipsList" valign="top" value="" label="Relationships" onchange="zenPage.changeDimSelection();"/>
</group>
</vgroup>
<vgroup id="statusgroup"/>
<timer id="cleanuptimer" ontimeout="zenPage.cleanup();"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Build Cube")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Build the fact table and indices for this cube.")
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
		this.startBuild();
		zen('btnOK').setHidden(true);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return false;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	zen("btnOK").focus();
	zen("btnOK").setProperty("caption",$$$Text("Build"));
	zen("btnCancel").setProperty("caption",$$$Text("Close"));		// DTB975 - This is always the caption

	this.updateStatus(this.cubeName,0);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		
		Set tCubeCount = 1		// DP-430862 - 1 if no dependents, total number if dependents are discovered in analysis below

		Set ..TempMaxFacts = $G(%session.Data($Username,"TempMaxFacts"))
		If ..maxFacts '= "" {
			#; if user defined maxFacts for the cube definition then change the hint
			Set ..%GetComponentById("TempMaxFacts").hint = $$$TextHTML("If blank or zero, DeepSee builds all the records.")_" (maxFacts = "_$ZCVT(..maxFacts,"O","HTML") _")"
			If ..TempMaxFacts = "" Set ..TempMaxFacts = ..maxFacts
		}

		// Determine if there is actually a list of cubes that will need to be built
		Set tSC = ##class(%DeepSee.CubeUtils).%GetUpdateLists(..cubeName,.tBuildOrders,.tGroupsToBuild,.tCubesToBuild)
		If $$$ISERR(tSC) Quit

		Set ..cubeList = ""		// Initialize cubeList if this cube has dependents
		Set tCubeCount = 0
		For {
			Set tGroup = $O(tGroupsToBuild($G(tGroup)))
			Quit:(tGroup="")

			For {
				Set tGroupPos = $O(tBuildOrders(tGroup,$G(tGroupPos)),1,tCubeToBuild)
				Quit:(tGroupPos="")

				// If this cube listed in the buildorders is flagged for a build, record this as a cube event also.
				If $D(tCubesToBuild(tCubeToBuild)) {
					Do $I(tCubeCount)
					Set ..cubeList = ..cubeList _ $S($L(..cubeList):$C(10),1:"") _ tCubeToBuild
				}		
			}
		}

		Set textArea = ..%GetComponentById("dependentCubes")
		If (tCubeCount>1) {
			//Set textArea.hidden = 0
			Set textArea.value = ..cubeList
		}
		Else {
			Set textArea.hidden = 1
		}



		// + DTB911
		// DTB965 - Test the current fact count. Selective Build will not work without a
		// pre-built cube.
		Set tFactClass = ##class(%DeepSee.Utils).%GetCubeFactClass(..cubeName)
		Set tFactCount = $S((tFactClass=""):0,1:$ClassMethod(tFactClass,"%Count"))
		If $$$dsSupportsSelectedList(..cubeName) && tFactCount {
			// Set the checklists for selected column build
			Set tSC = ..%SetCheckLists(.tSelected)
			If $$$ISERR(tSC) Quit
			
			If tSelected {
				// DTB913 - Default to the checklists if something is pre-checked
				Set ..%GetComponentById("buildOption").value = "selected"
				Set ..%GetComponentById("buildCheckLists").hidden = 0
				Set ..%GetComponentById("TempMaxFacts").hidden = 1		// DTB965 - Hide the maxFacts textBox in this case
			}
		}
		Else {
			// Hide the Build All/Build Selected controls
			Set ..%GetComponentById("buildOption").hidden = 1
		}
		// - DTB911

		Set tStatusGroup = ##class(%ZEN.Component.group).%New()
  		Do %page.%GetComponentById("statusgroup").%AddChild(tStatusGroup)

		// DP-430862 - Loop through build ordered list of cubes and create a timer and status area for each cube
		set tCubeIndex=""
		Set tOrderedCubeList = ""		// DTB131
		For c=1:1:$L(..cubeList,$C(10)) {
			Set tCubeIndex=$increment(tCubeIndex)
			//Set tCurrentCubeName = tBuildOrder(1,i)
			Set tCurrentCubeName = $P(..cubeList,$C(10),c)
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
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Fill in the details of the update checklists based on the current cube definition.
Method %SetCheckLists(pDefaultSelected = 0) As %Status
{
	// Method added by DTB911
	Set tSC = $$$OK
	
	Try {
		// DTB911 - Populate the selected build lists
		// - If anything is in the tModified array, default to the "selected" mode.
		Set tModified = ##class(%Library.DynamicObject).%FromJSON(..factsModifiedList)
		Set tTypes = $LB("measures","dimensions","relationships")
		For t=1:1:3 {
			// Build a lookup index for the items modified in this session
			Set tType = $LG(tTypes,t)
			Set tTypeList = $Property(tModified,tType)
			If $IsObject(tTypeList) {
				For i=1:1:tTypeList.%Size() {
					Set tItem = $$$UPPER(tTypeList.%Get(i-1))
					Set:(tItem'="") tModifiedIndex(tType,tItem) = "" 
				}
			}
		}
		
		// Look up all of the dimensions for display with the factID as the value and specs as the displayValue
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionList(..cubeName,.tFullList,,,1)		// DTB918 - Request extended info
		If $$$ISERR(tSC) Quit
		// Walk straight through the triple-subscript array since it will have everything in the same order as in the cube definition
		Set d = $O(tFullList(""))
		While (d'="") {
			Set h = $O(tFullList(d,""))
			While (h'="") {
				Set l = $O(tFullList(d,h,""),1,tFactInfo)
				While (l'="") {
					Set tTypeCode = $LG(tFactInfo,1)
					Set tTypeNo=0
					If (tTypeCode="m")&&($LG(tFactInfo,3)'="%COUNT") {
						Set tTypeNo = 1
						Set tSpec = "[" _ $LG(tFactInfo,2) _ "].[" _ $LG(tFactInfo,3) _ "]"
					}
					ElseIf (tTypeCode="l") {
						Set tTypeNo = 2
						Set tSpec = "[" _ $LG(tFactInfo,2) _ "].[" _ $LG(tFactInfo,3) _ "].[" _ $LG(tFactInfo,4) _ "]"
					}
					ElseIf (tTypeCode="r") {
						Set tTypeNo = 3
						Set tSpec = "[" _ $LG(tFactInfo,2) _ "]"
					}
					
					If tTypeNo {
						Set tType = $LG(tTypes,tTypeNo)
						Set tInclude = 1
						
						// DTB918 - Use the extended info from %GetDimensionList
						Set tFactID = $LG(tFactInfo,6)
						Set tSqlColID = $LG(tFactInfo,7)
						Set tIsEnabled = $LG(tFactInfo,8)
						Set tInProgress = $LG(tFactInfo,9)
						
						// + DTB915 - Do some final validation of this dimension 
						If (tFactID'="") {
							// DTB954 - Only perform the index type lookup if there is a fact ID to look it up! 
							Set tIndex = $G($$$DeepSeeMetaGLVN("cubes",$$$DeepSeeIndex(..cubeName),"fact","prop",tFactID,"index"))
							If (tIndex="") || ($E(tIndex,1,5)="iKnow") {
								// This has no physical index in the fact table so should not be on the list
								Set tInclude = 0
							}
						}
						Else {
							// Nothing more to do if there was no fact ID
							Set tInclude = 0
						}
						// - DTB915
						
						Set tSelect = 0
						If ($D(tModifiedIndex(tType,$$$UPPER(tSpec))) || 'tIsEnabled) && 'tInProgress {		// DTB915 - Do not pre-select facts in progress
							Set tSelect = 1	
						}
						
						If tInclude {
							Set tValues(tType) = $G(tValues(tType)) _ $S($L($G(tValues(tType))):",",1:"") _ tSqlColID
							Set tDisplays(tType) = $G(tDisplays(tType)) _ $S($L($G(tDisplays(tType))):",",1:"") _ tSpec
							Set:tSelect tSelected(tType) = $G(tSelected(tType)) _ $S($L($G(tSelected(tType))):",",1:"") _ tSqlColID
						}
					}
					
					Set l = $O(tFullList(d,h,l),1,tFactInfo)
				}
				
				Set h = $O(tFullList(d,h))
			}
			
			Set d = $O(tFullList(d))
		}
		
		For t=1:1:3 {
			// Build a lookup index for the items modified in this session
			Set tType = $LG(tTypes,t)
			Set tCheckList = ..%GetComponentById(tType_"List")
			If $D(tValues(tType)) {
				Set tCheckList.valueList = tValues(tType)
				Set:$D(tDisplays(tType)) tCheckList.displayList = tDisplays(tType)
				If $D(tSelected(tType)) {
					Set tCheckList.value = tSelected(tType)
					Set pDefaultSelected = 1
				}
			}
			Else {
				Set tCheckList.hidden = 1
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Start the index build.
ClientMethod startBuild() [ Language = javascript ]
{
	var option = zen('buildOption').getValue();
	var cubeList = this.cubeList.split("\n");
	this.currentCube=cubeList[0];

	zen('btnOK').setDisabled(true);
	zen('TempMaxFacts').setDisabled(true);		// DTB921
	switch(option) {
	case 'all':
		this.trackingId = this.BuildCube(this.cubeName,zen('TempMaxFacts').getValue());
		break;
	case 'selected':
		this.trackingId = this.BuildCube(this.cubeName,'',this.getFactList());		// DTB921 - Ignore max facts for Selective Build
		break;
	}
	
	// DTB911 - Track in either case
	if (this.trackingId!='') {
		this.setDimSelectionDisabled(true);		// DTB911 - Lock the controls while a build is ongoing
		for (let i = 0; i < (cubeList.length); i++) {
			zen('timer'+cubeList[i]).timeout = 500;
			zen('timer'+cubeList[i]).startTimer();
		}
		document.getElementById('status'+this.currentCube).scrollIntoView();		// DTB913
		this.getOpener().zenPage.setFactsModified(false);		// DTB911 - If the build is successfully started, clear the modified flags
	}
	else {
		zen('btnOK').setDisabled(false);
	}
	return;
}

/// Start the build cube process in the background.
/// Return the tracking id.
ClassMethod BuildCube(pCubeName As %String, pTempMaxFacts As %Integer, pFactList As %String = "") As %String [ ZenMethod ]
{
	Set tTrackingId = ""
	Set tJobTimeOut = 10
	Set ^IRIS.Temp.DeepSeeTracking.buildInProgress($namespace) = 1
	#; If user entered blank then use and save it as blank. Otherwise use and save the numeric 
	Set tTempMaxFacts = $S(pTempMaxFacts="":"",1:+pTempMaxFacts)
	Set %session.Data($Username,"TempMaxFacts") = tTempMaxFacts
	#; Reset text value if the numeric value differs from user's input.
	If pTempMaxFacts '= tTempMaxFacts {
		&js<zen("TempMaxFacts").setValue('#(tTempMaxFacts)#');>	
	}
	Job ##class(%DeepSee.Utils).%BuildCube(pCubeName,1,0,0,tTempMaxFacts,1,"",pFactList)::tJobTimeOut		// DTB911 - Add fact list
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
ClassMethod CheckStatus(pTrackingId = "", pCubeName As %String, pFinal = 0) As %String [ ZenMethod ]
{
	Set tOutput = ""
	Set tIsComplete = 0
	Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
	
	// DP-405621 - The tracking global will use the versioned name if applicable. 
	// If the cube does not support versions %GetVersionedCubeName returns the cube index.
	If (pTrackingId="") {
		Set (tOutput,tStep) = ""
	}
	Else {
		If ('$D(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName))) quit "NoData"
		If $D(^IRIS.Temp.CubeManager($j,"completed",pCubeName)) q "Completed"
		
		Set tStep = $O(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName,""),1,info)
	}
	
	While (tStep'="") {
		If ($G(tLastStep)=0) {
			// DTB975 - Reset the output if the server has moved on to the actual progress reporting
			Set tOutput = ""
		}
		
		//Set tIsActive = ($O(^IRIS.Temp.DeepSeeTracking($namespace, tCubeIndex,tStep))="")
		Set tIsActive = ($O(^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName,tStep))="")
		Set tPhase = $LG(info,1)
		Set:tPhase="complete"!(tPhase="error") tIsComplete = 1
		// DTB975 - Add "begin" phase
		// DTB1130 - Add "sync" phase
		Set tMsg = $Case(tPhase,"begin":$$$Text("Begin build"),"delete":$$$Text("Deleting facts"),"facts":$$$Text("Building facts"),"indices":$$$Text("Building indices"),"aggs":$$$Text("Computing aggregates"),"iknow":$$$Text("Processing iKnow measures"),"sync":$$$Text("Running final syncronize"),"error":$$$Text("Error"),:$$$Text("Complete"))
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
		Set tOutput = "<div><b>"_pCubeName_" "_$$$Text("Status")_ "</div><table class=""statusTable"" cellspacing=""0"" width=""100%"">" _ tOutput _ "</table>"
	}
	
	If (tIsComplete) {
		Kill ^IRIS.Temp.DeepSeeTracking($namespace, pTrackingId)
		
		// Clean up the tracking globals for this build request
		Kill ^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId,pCubeName)
		Set:pFinal ^IRIS.Temp.DeepSeeTracking.buildInProgress($namespace) = 0
		
	}
	
	Quit tOutput
}

/// Formats the date and time for the previous build 
ClassMethod FormatPrevBuild(pCubeName As %String) As %String [ ZenMethod ]
{
	Set tCubeNameU = $$$UPPER(pCubeName)
	Quit $S($DATA(^IRIS.Temp.DeepSeeBuildStats.prevBuildFinished($namespace, tCubeNameU)):
				$$$Text("Last build completed") _ ": " _ $ZDT(^IRIS.Temp.DeepSeeBuildStats.prevBuildFinished($namespace, tCubeNameU),4),
				1:"")
}

/// Update the status area.
ClientMethod updateStatus(cubeName, final) [ Language = javascript ]
{
	cubeName = cubeName.toUpperCase();
	if (!cubeName) {
		return;
	}

	var status = this.CheckStatus(this.trackingId,cubeName,final);
	var html = zen('status'+cubeName);
	document.getElementById("prevBuildFinished").innerText = this.FormatPrevBuild(this.cubeName);

	if (status == '') {
		return;
	//} else if ((status=='NoData')&&(!document.getElementById('status'+cubeName).children)) {
	} else if (status=='NoData') {
		// The cube has either not started. Keep waiting on this cube to start building	
		zen('timer'+cubeName).timeout = 250;
		zen('timer'+cubeName).startTimer();
	} else if ("Completed" != status) {
		// This means that the cube has started updating but isn't yet finished. Render the HTML that displays the available progress.
		html.setContent(status);

		// Restart the timer since there is more work to do. The status check will return "Completed" when all work is finished.
		zen('timer'+cubeName).timeout = 250;
		zen('timer'+cubeName).startTimer();
		document.getElementById('spacer'+cubeName).scrollIntoView(false);		// Focus on the bottom of the current cube's table.
	} 

	if (final) {
		// use a timer for cleanup since other timers may be pending
		// if the last cube is complete, the others are done but we may
		// be waiting on a timer for a a maximum of 250 msec, so set 
		// this timer for 500 msec
		zen('cleanuptimer').timeout=500;
		zen('cleanuptimer').startTimer();
	}
	
	return;
}

/// Toggle the display of the fact checklists.
ClientMethod toggleDimSelection(setting) [ Language = javascript ]
{
	// Method added by DTB911
	var buildAll = ('all'==setting);
	zen('buildCheckLists').setHidden(buildAll);
	zen('TempMaxFacts').setHidden(!buildAll);		// DTB921 - Do not present this for Selective Build
	if (buildAll) {
		// DTB913 - This is definitely ready to build
		zen('btnOK').setDisabled(false);
	}
	else {
		// DTB913 - Perform the check to see if this is build ready or not
		this.changeDimSelection();
	}
}

/// Set the disable value for all build selection controls in the dialog.
ClientMethod setDimSelectionDisabled(value) [ Language = javascript ]
{
	// Method added by DTB911
	zen('buildOption').setDisabled(value);
	if (value) {
		zen('linkSelectAll').setProperty('onclick','return false');		// DTB913
		zen('linkClearAll').setProperty('onclick','return false');		// DTB913
	}
	zen('measuresList').setDisabled(value);
	zen('dimensionsList').setDisabled(value);
	zen('relationshipsList').setDisabled(value);
}

/// Pull the values from the checklists to assemble a factList selection. 
ClientMethod getFactList() [ Language = javascript ]
{
	// Method added by DTB911
	var factList = '';
	var mList = zen('measuresList').getValue();
	var dList = zen('dimensionsList').getValue();
	var rList = zen('relationshipsList').getValue();
	
	var fullList = ((mList) ? mList+',' : '') + ((dList) ? dList+',' : '') + ((rList) ? rList+',' : '');
	return fullList.substr(0,fullList.length-1);
}

/// Set every checkBox in the checkLists to <var>value</var>.
ClientMethod setAllCheckLists(value) [ Language = javascript ]
{
	// Method added by DTB913
	var measures = zen('measuresList');
	var dimensions = zen('dimensionsList');
	var relations = zen('relationshipsList');
	if (value) {
		measures.value = measures.valueList;
		dimensions.value = dimensions.valueList;
		relations.value = relations.valueList;
	}
	else {
		measures.value = '';
		dimensions.value = '';
		relations.value = '';
	}
	
	measures.refreshContents();
	dimensions.refreshContents();
	relations.refreshContents();
	
	this.changeDimSelection();
}

/// Look at the current selection and make sure the Build button is only enabled if something is selected.
ClientMethod changeDimSelection() [ Language = javascript ]
{
	// Method added by DTB913
	var itemSelected = (this.getFactList().length > 0);
	zen('btnOK').setDisabled(!itemSelected);
	zen('btnOK').setProperty('controlClass',(itemSelected ? 'commandButton' : 'commandButtonDisabled'));
}

ClientMethod cleanup() [ Language = javascript ]
{
	zen('btnCancel').setDisabled(false);
	// when build finished, set focus on OK button so [Enter] key will exit easily.
	zen("btnOK").focus();

	var cubeList = this.cubeList.split('\n')
	for (let c=0; c < cubeList.length; c++) {
		//document.getElementById('timer' + cubeList[c]).clearTimer();
	}
	
	// clear the tracking globals
	zenPage.ClearTracking(this.trackingId);
	this.trackingId = '';
}

ClassMethod ClearTracking(pTrackingId As %String) [ ZenMethod ]
{
	Kill ^IRIS.Temp.DeepSeeTracking(pTrackingId)
	Kill ^IRIS.Temp.CubeManagerUpdateTracking(pTrackingId)
	Kill ^IRIS.Temp.CubeManager
}

}
