/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.SQLParamSelection Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

Parameter APPLYBUTTON = 0;

Property settingStatement As %ZEN.Datatype.integer(ZENURL = "QUERY");

Property settingContainerClass As %ZEN.Datatype.string(ZENURL = "CONTAINER");

Property settingParam As %ZEN.Datatype.string(ZENURL = "QUERYPARAM");

Property settingParamNum As %ZEN.Datatype.string(ZENURL = "QUERYPARAMNUM");

Property prependAsterix As %Integer(ZENURL = "PREPENDASTERIX");

XData Style
{
<style type="text/css">

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
    <textarea id="sqlStatement" rows="4" cols="40" label="Query" readOnly="true"/>
    <combobox id="sqlParam" size="40" label="Parameter" unrestricted="true" editable="true" />
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("SQL Parameter Helper")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Enter a Parameter for the SQL Statement")
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

ClientMethod ondialogCancel() As %Boolean [ Language = javascript ]
{
	// Trigger resetting of the input box
	try { this.firePopupAction('cancel',false); } catch(ex) {}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
    return escape(zen('sqlParam').getValue());
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('sqlParam').focus();
		zen('sqlParam').select();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {

		Set tPropList = ..%GetPropertyList()
		Set ..%GetComponentById("sqlParam").valueList = tPropList
		Set ..%GetComponentById("sqlStatement").value = ..settingStatement
        Set ..%GetComponentById("sqlParam").value = ..settingParam
        Set ..%GetComponentById("sqlParam").label = "Parameter"_" "_..settingParamNum_" : "
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
}

/// Key handler for value edit control.
ClientMethod ctrlKeyDown(evt, escOnly) [ Language = javascript ]
{
	switch(evt.keyCode) {
	case zenENTER:
		if (!escOnly) {
			this.dialogFinish();
		}
		break;
	case zenESC:
		this.dialogCancel();
		break;
	}
	return true;
}

/// Build a csv-list of available properties.
Method %GetPropertyList() As %String
{
	Set tList = ""
	Try {
		// get properties for classes
		Set tSC = ..%GetPropertiesForClass(..settingContainerClass,.tCList)
		Merge tPropList("*") = tCList

		
		Set k = $O(tPropList(""))
		While (k'="") {
			Set p = $O(tPropList(k,""))
			While (p'="") {
				Set tList = tList _ $S(tList="":"",1:",") _ $Select(..prependAsterix:k,1:"") _ p
				Set p = $O(tPropList(k,p))
			}
			Set k = $O(tPropList(k))
		}

	}
	Catch (ex) {
		Set tList = $ZE
	}
	Quit tList
}

/// Return an array of properties for the given class.
Method %GetPropertiesForClass(pClass As %String, Output pList) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		If (pClass="") Quit

		Set tSC = ##class(Ens.Rule.Utils).GetPropertyList(.tList,pClass)
		If $$$ISERR(tSC) Quit

		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set:tName'="" pList(tName) = ""
			Set k = $O(tList(k))
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
