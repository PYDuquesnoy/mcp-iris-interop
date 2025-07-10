/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user create or edit a context propery within a Business Process.
Class EnsPortal.Dialog.BusinessProcessContext Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_BPL:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE";

Parameter APPLYBUTTON = 0;

/// Index number of property, -1 for new.
Property propertyIndex As %ZEN.Datatype.integer(ZENURL = "INDEX");

/// Name of property.
Property propertyName As %ZEN.Datatype.string(ZENURL = "PROPERTY");

/// Type of property.
Property propertyType As %ZEN.Datatype.string(ZENURL = "TYPE");

/// Collection type.
Property propertyCollection As %ZEN.Datatype.string(ZENURL = "COLLECTION");

/// Default value of property.
Property propertyDefault As %ZEN.Datatype.string(ZENURL = "DEFAULT");

/// Description for property.
Property propertyDescription As %ZEN.Datatype.string(ZENURL = "DESC");

/// Instantiate flag.
Property propertyInstantiate As %ZEN.Datatype.integer(ZENURL = "INST");

/// ReadOnly flag.
Property readOnly As %ZEN.Datatype.boolean(ZENURL = "READONLY");

XData Style
{
<style type="text/css">

.checkboxCaption {
	color: #404040;
}

a.radioSetCaption {
	vertical-align: text-bottom;
}
.zenHint {
	font-size: 0.75em;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<text id="bpProperty" size="40" label="Property Name" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" hint="Must be a valid identifier name"/>

<radioSet id="bpCollection" valueList=",list,array" displayList="Single Value,List Collection, Array Collection" onchange="zenPage.changeCollection();"/>

<hgroup cellVAlign="top" label="Property Type" hint="Type of this property including parameters">
<combobox id="bpType" size="40" valueList="%String(MAXLEN=50),%String(MAXLEN=250),%String(MAXLEN=2500),%Integer,%Boolean,%Date,%TimeStamp,$$Other" displayList="%String(MAXLEN=50),%String(MAXLEN=250),%String(MAXLEN=2500),%Integer,%Boolean,%Date,%TimeStamp,--View all types--" unrestricted="true" editable="true" onchange="zenPage.typeChange();" />
<image id="bpTypeButton" src="deepsee/zoom_16.png" onclick="zenPage.selectClass();" title="Select new class"/>
</hgroup>

<text id="bpDefault" size="40" label="Default Value" onkeydown="return zenPage.ctrlKeyDown(zenEvent);" hint="Default value; ignored for collections"/>

<checkbox id="bpInstantiate" caption="Instantiate" captionClass="zenLabel" hint="For object-valued properties; instantiate on create"/>

<textarea id="bpDesc" label="Description" rows="3" cols="35" onkeydown="return zenPage.ctrlKeyDown(zenEvent,true);"/>

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Business Process Context Property")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	If (..propertyIndex=-1) {
		Quit $$$TextHTML("Add a new property to the Business Process context.")
	}
	Quit $$$TextHTML("Edit a property in the Business Process context.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

ClientMethod changeCollection() [ Language = javascript ]
{
	var isCollection = (zen('bpCollection').getValue() != '');
	var currObjectType = zen('bpType').getValue();
	var instantiate = zen('bpInstantiate');
	var noInstantiate = isCollection || ((currObjectType != '') && (this.CanInstantiate(currObjectType) == false));
	instantiate.setDisabled(noInstantiate);
	if (noInstantiate) instantiate.setValue(false);
	var instantiateCaption = instantiate.findElement('caption');
	if (instantiateCaption) instantiateCaption.className = 'zenLabel' + (noInstantiate ? 'Disabled' : '');
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.checkEdit() && (!this.readOnly)) {
			var main = this.getOpener();

			var bpName = zen('bpProperty').getValue();
			bpName = zenTrim(bpName);
			var bpType = zen('bpType').getValue();
			if ('' == bpType) {
				bpType = "%String";
			}
			var bpDesc = zen('bpDesc').getValue();
			var bpDefault = zen('bpDefault').getValue();
			var bpCollection = zen('bpCollection').getValue();
			var bpInstantiate = zen('bpInstantiate').getValue();
			// Ensure we get a boolean
			bpInstantiate = !!bpInstantiate;

			// test for missing name
			if ('' == bpName) {
				alert($$$Text('Please enter a name for this property.'));
				return false;
			}

			// test for valid name
			if (!zenPage.IsNameValid(bpName)) {
				alert($$$Text('Name is not valid for this property.'));
				return false;
			}

			// test for valid name
			if (!zenPage.IsTypeValid(bpType)) {
				alert($$$Text('Type is not valid for this property.'));
				return false;
			}

			// test for attempt to instantiate non-object property
			if (bpInstantiate && !zenPage.CanInstantiate(bpType)) {
				alert($$$FormatText($$$Text('Can\'t instantiate property because type %1 is not an object class'),bpType.split('(')[0]));
				bpInstantiate = false;
			}

			// add to main page
			if (main && main.zenPage && main.zenPage.setContextProperty) {
				main.zenPage.setContextProperty(this.propertyIndex,bpName,bpType,bpDefault,bpDesc,bpCollection,bpInstantiate);
			}
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
	zenPage.changeCollection();
	zen('bpProperty').focus();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Try {
		If (..propertyType="") {
			Set ..propertyType = "%String(MAXLEN=50)"
		}

		Set ..%GetComponentById("bpProperty").value = ..propertyName
		Set ..%GetComponentById("bpType").value = ..propertyType
		Set ..%GetComponentById("bpDefault").value = ..propertyDefault
		Set ..%GetComponentById("bpDesc").value = ..propertyDescription
		Set ..%GetComponentById("bpCollection").value = ..propertyCollection
		Set ..%GetComponentById("bpInstantiate").value = ''..propertyInstantiate
		
		If (..readOnly || '..canEdit) {
			For ctrl = "bpProperty","bpType","bpDefault","bpDesc","bpCollection","bpInstantiate" {
				Set ..%GetComponentById(ctrl).readOnly = 1
			}
			Set tButton = ..%GetComponentById("bpTypeButton")
			If $IsObject(tButton) {
				Set tButton.onclick = ""
				Set tButton.disabled = 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if the given name is valid.
ClassMethod IsNameValid(pName As %String) As %Boolean [ ZenMethod ]
{
	Quit $ZNAME(pName,3)
}

/// Test if the given type is valid.
ClassMethod IsTypeValid(pType As %String) As %Boolean [ ZenMethod ]
{
	// !!!! implement
	Quit 1
	Quit $ZNAME(pType,3)
}

/// Test if the given name is valid.
ClassMethod CanInstantiate(pType As %String) As %Boolean [ ZenMethod ]
{
	Set is = 0
	try {
		Set is = $classmethod($piece(pType,"(",1),"%Extends","%RegisteredObject")
	} catch {
	}
	Quit is
}

/// Change to type combo.
ClientMethod typeChange() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var value = zen('bpType').getValue();
	if ('$$Other'== value) {
		zen('bpType').setValue(this.propertyType);
		this.selectClass();
	}
	else {
		this.propertyType = value;
	}
	this.changeCollection();
}

/// Launch the select class dialog.
ClientMethod selectClass() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var parms = {
		MODE: 'classescontext',
		CATEGORY : 'localcontext'
	};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix('BPType'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'BPType':
			var t = value.toString().split('.');
			t.length--;
			zen('bpType').setValue(t.join('.'));
			this.propertyType = t.join('.');
			this.changeCollection();
			break;
	}
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

}
