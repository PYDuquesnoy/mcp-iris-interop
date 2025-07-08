/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog allows the user to select from 
Class %DeepSee.UI.Dialog.SelectCubeList Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// If true, the selection options will be limited to cubes only
Property CubesOnly As %ZEN.Datatype.boolean(ZENURL = "CUBESONLY") [ InitialExpression = 0 ];

/// If supplied, these cubes will be pre-selected when the dialog loads
Property CubeList As %ZEN.Datatype.string(ZENURL = "CUBELIST");

Property msgDefineRequest As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Select the cubes and subject areas which can use this listing group.")} ];

XData Style
{
<style type="text/css">
.labelValue {
	color: #404040;
}
.errorStyle {
	color: red;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<spacer height="10"/>
<vgroup id="activeInfo" hidden="false">
<label id="activeInfoLabel" value="#(%page.msgDefineRequest)#"/>
<spacer height="5"/>
</vgroup>
<vgroup>
<hgroup cellStyle="padding-left:20px;padding-bottom:8px;">
<multiSelectSet id="cubeList" valign="top" value="" label="Cubes available in this namespace."/>
<multiSelectSet id="subjectList" valign="top" hidden="true" value="" label="Subject Areas available in this namespace."/>
</hgroup>
</vgroup>
<vgroup id="errorMsg" hidden="true">
<label id="errorText" value="Test Error" controlClass="errorStyle"/>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {			
		// Process the incoming cubelist to remove leading and trailing spaces and extra commas
		Set tNormalizedCubeList = ""
		For n = 1:1:$Length(..CubeList) {
			Set tInputCube = $P(..CubeList,",",n)
			Set tInputCube = $ZStrip(tInputCube,"<>"," ")
			Set:tInputCube'="" tNormalizedCubeList = tNormalizedCubeList _ $S($L(tNormalizedCubeList):",",1:"") _ tInputCube
		}
		Set ..CubeList = tNormalizedCubeList
		
		
		Set ..%GetComponentById("btnCancel").hidden=1
		Set tCubeSelect = ..%GetComponentById("cubeList")
		Set tSubjectSelect = ..%GetComponentById("subjectList")
		
		Set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tCubeInfo,"cubes")
		If $$$ISERR(tSC) Quit
		
		Set tValueList = ""
		Set tDisplayList = ""
		Set tKey = $O(tCubeInfo(""))
		While tKey'="" {
			Set tValueList = tValueList _ $S($L(tValueList):",",1:"") _ tKey
			Set tDisplayList = tDisplayList _ $S($L(tDisplayList):",",1:"") _ $LG(tCubeInfo(tKey),1)
			Set tKey = $O(tCubeInfo(tKey))
		}
		
		Set tCubeSelect.valueList = tValueList
		Set tCubeSelect.displayList = tDisplayList
		Set tCubeSelect.value = $$$UPPER(..CubeList)
		
		If '..CubesOnly {
			Set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tSAInfo,"subjectAreas")
			If $$$ISERR(tSC) Quit
			
			Set tValueList = ""
			Set tDisplayList = ""
			Set tKey = $O(tSAInfo(""))
			While tKey'="" {
				// Check security
				Set tCubeResource = ..GetCubeResource(tKey)
				If tCubeResource=""||($system.Security.Check(tCubeResource)'="") {
					Set tValueList = tValueList _ $S($L(tValueList):",",1:"") _ tKey
					Set tDisplayList = tDisplayList _ $S($L(tDisplayList):",",1:"") _ $LG(tSAInfo(tKey),1)
					Set tKey = $O(tSAInfo(tKey))
				}
			}
			
			Set tSubjectSelect.hidden = 0
			Set tSubjectSelect.valueList = tValueList
			Set tSubjectSelect.displayList = tDisplayList
			Set tSubjectSelect.value = $$$UPPER(..CubeList)
		}
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GetCubeResource(pCubeName) As %String
{
	Set tResource=""
	Try {
		If pCubeName'="" {
			Set tResource = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName),"resource"))
		}
	}
	Catch ex {
		// Swallow errors
	}
	Quit tResource
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Select Cube List")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var cubeList = zen('cubeList').getValue();
	var subjectList = zen('subjectList').getValue();
	
	if ( (cubeList.length>0) && (subjectList.length>0) ) {
		var returnList = cubeList + ',' + subjectList;
	} else {
		var returnList = cubeList + subjectList;
	}
	
	return returnList;
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

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
}

}
