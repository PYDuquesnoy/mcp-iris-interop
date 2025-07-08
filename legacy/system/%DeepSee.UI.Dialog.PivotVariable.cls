/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create or edit a pivot variable within a DeepSee pivot table.
Class %DeepSee.UI.Dialog.PivotVariable Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property variableName As %ZEN.Datatype.string(ZENURL = "VARIABLE");

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee" cellStyle="padding-bottom:8px;">
<vgroup id="mainGroup" cellStyle="padding-top:8px;">
<text id="ctrlName" label="Variable Name" hint="Name of the pivot variable" size="25"/>

<text id="ctrlCaption" label="Caption" hint="Displayed name for the pivot variable" size="25"/>

<text id="ctrlDesc" label="Description" size="40"/>

<text id="ctrlDefValue" label="Default Value" size="40"/>

<radioSet id="ctrlContext" label="How is this variable used" valueList="expression,literal" displayList="Expression,Literal"/>

<radioSet id="ctrlType" label="What type of value will this variable have" valueList="expression,string,number,integer,day" displayList="Expression,String,Number,Integer,Day"/>

<radioSet id="ctrlSourceType" label="Source of values for this variable" valueList="manual,termlist,kpi" displayList="Manual,Termlist,KPI" onchange="zenPage.typeChange();"/>

<hgroup cellVAlign="bottom" id="groupTermlist">
<text id="ctrlTermlist" label="Termlist" size="40"/>
<image id="btnTermlist" src="deepsee/zoom_16.png" onclick="zenPage.loadTermlist();"/>
</hgroup>

<hgroup cellVAlign="bottom" id="groupKPI">
<text id="ctrlKPI" label="KPI" size="40"/>
<image id="btnKPI" src="deepsee/zoom_16.png" onclick="zenPage.loadKPI();"/>
</hgroup>

<hgroup cellVAlign="bottom" id="groupValues">
<textarea id="ctrlValueList" label="Values (one per line)" rows="8" cols="25"/>
<textarea id="ctrlDisplayList" label="Captions (one per line)" rows="8" cols="25"/>
</hgroup>

</vgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Pivot Variable")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Define a pivot variable.")
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
		var vname = zen('ctrlName').getValue();
		if (''==vname) {
			alert($$$Text('Please provide a name for this pivot variable'));
			return false;
		}
		
		// validate name
		var reg = /[\s,!@#$%^&*()+-\/]/
		if (reg.test(vname)) {
			alert($$$Text('Pivot variable cannot contain spaces or punctuation'));
			return false;
		}

		var vcaption = zen('ctrlCaption').getValue();
		var vdesc = zen('ctrlDesc').getValue();
		var vdefValue = zen('ctrlDefValue').getValue();
		var vcontext = zen('ctrlContext').getValue();
		var vtype = zen('ctrlType').getValue();
		var vsourceType = zen('ctrlSourceType').getValue();
		var vsourceName = '';
		var vlist = '';
		var dlist = '';

		switch (vsourceType) {
		case 'termlist':
			vsourceName = zen('ctrlTermlist').getValue();
			break;			
		case 'kpi':
			vsourceName = zen('ctrlKPI').getValue();
			break;			
		case 'manual':
			vlist = zen('ctrlValueList').getValue();
			dlist = zen('ctrlDisplayList').getValue();
			
			// DTB569 - Store escaped commas in each line
			if (vlist) {
				vlist = vlist.split(',').join('\\,');
				vlist = vlist.toString().split('\n').join(',');
			}
			if (dlist) {
				dlist = dlist.split(',').join('\\,');
				dlist = dlist.toString().split('\n').join(',');
			}
			break;			
		}

		// check for overwrite
		if (this.variableName!=vname) {
			var exists = this.PivotVariableExists(this.cubeName,vname);
			if (exists) {
				if (!confirm($$$Text('A pivot variable with this name already exists. Do you wish to replace it?'))) {
					return;
				}
			}
		}

		var msg = this.SavePivotVariable(this.cubeName,vname,vcaption,vdesc,vdefValue,vcontext,vtype,vsourceType,vsourceName,vlist,dlist);
		if (msg != '') {
			alert(msg);
			return false;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.typeChange();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		If (..variableName'="") {
			Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(..cubeName,..variableName,.tInfo)
			Set ..%GetComponentById("ctrlName").value = $G(tInfo("name"))
			Set ..%GetComponentById("ctrlCaption").value = $G(tInfo("displayName"))
			Set ..%GetComponentById("ctrlDesc").value = $G(tInfo("description"))
			Set ..%GetComponentById("ctrlDefValue").value = $G(tInfo("defaultValue"))
			Set ..%GetComponentById("ctrlContext").value = $G(tInfo("context"),"expression")
			Set ..%GetComponentById("ctrlType").value = $G(tInfo("type"),"expression")

			Set tSourceType = $G(tInfo("sourceType"),"manual")
			Set ..%GetComponentById("ctrlSourceType").value = tSourceType
			If (tSourceType = "termlist") {
				Set ..%GetComponentById("ctrlTermlist").value = $G(tInfo("sourceName"))
			}
			ElseIf (tSourceType = "kpi") {
				Set ..%GetComponentById("ctrlKPI").value = $G(tInfo("sourceName"))
			}
			ElseIf (tSourceType = "manual") {
				// DTB569 - Replace escaped commas with a special character,
				// insert line breaks at the commas, and replace escaped commas.
				Set tValueList = $Replace($G(tInfo("valueList")),"\,",$C(1))
				Set tValueList = $Replace(tValueList,",",$C(10))
				Set tValueList = $Replace(tValueList,$C(1),",")
				Set ..%GetComponentById("ctrlValueList").value = tValueList
				Set tDisplayList = $Replace($G(tInfo("displayList")),"\,",$C(1))
				Set tDisplayList = $Replace(tDisplayList,",",$C(10))
				Set tDisplayList = $Replace(tDisplayList,$C(1),",")
				Set ..%GetComponentById("ctrlDisplayList").value = tDisplayList
			}
		}
		Else {
			Set ..%GetComponentById("ctrlSourceType").value = "manual"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Save a pivot variable.
ClassMethod SavePivotVariable(pCube As %String, pVariableName As %String, pDisplayName As %String, pDescription As %String, pDefValue As %String, pContext As %String, pType As %String, pSourceType As %String, pSourceName As %String, pValueList As %String, pDisplayList As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tInfo("displayName") = pDisplayName
		Set tInfo("description") = pDescription
		Set tInfo("defaultValue") = pDefValue
		Set tInfo("context") = pContext
		Set tInfo("type") = pType
		Set tInfo("sourceType") = pSourceType
		Set tInfo("sourceName") = pSourceName
		Set tInfo("valueList") = pValueList
		Set tInfo("displayList") = pDisplayList

		Set tSC = ##class(%DeepSee.Utils).%SavePivotVariable(pCube,pVariableName,.tInfo)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Test if pivot variable exists.
ClassMethod PivotVariableExists(pCube As %String, pVariableName As %String) As %Boolean [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tExists = 0
	Try {
		Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(pCube,pVariableName,.tInfo)
		If $$$ISERR(tSC) Quit

		If $D(tInfo) {
			Set tExists = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tExists = 0
	}
	Quit tExists
}

ClientMethod typeChange() [ Language = javascript ]
{
	var type = zen('ctrlSourceType').getValue();
	switch (type) {
	case 'termlist':
		zen('groupTermlist').setHidden(false);
		zen('groupKPI').setHidden(true);
		zen('groupValues').setHidden(true);
		break;
	case 'kpi':
		zen('groupTermlist').setHidden(true);
		zen('groupKPI').setHidden(false);
		zen('groupValues').setHidden(true);
		break;
	default:
		zen('groupTermlist').setHidden(true);
		zen('groupKPI').setHidden(true);
		zen('groupValues').setHidden(false);
		break;
	}
}

/// Launch the termlist finder dialog.
ClientMethod loadTermlist() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists','Termlist','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the KPI finder dialog.
ClientMethod loadKPI() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=kpis','KPI','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'Termlist':
		zen('ctrlTermlist').setValue(value);
		break;

	case 'KPI':
		zen('ctrlKPI').setValue(value);
		break;
	}
}

}
