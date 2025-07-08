/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user add or edit a list for definition.<br>
/// An existing list (delimited by comma) may be passed in.<br>
/// If WHAT is not 'MemberList' this this dialog only provide one textarea for you to edit one field.
Class %DeepSee.UI.Dialog.GetList Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property ELEMENT As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property Expression As %ZEN.Datatype.string(ZENURL = "VALUE");

Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

Property itemNumber As %ZEN.Datatype.integer [ InitialExpression = "1" ];

Property msgHasEmpty As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("There is at least one empty field. Proceed?")} ];

Property lblProperty As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Enter a data source Property:")} ];

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
<label id="ELEMENT" label="Element name:" enclosingClass="zenLabel"/>
</vgroup>
<label id="titleText" label="Manage a member list." enclosingStyle="padding:2px;"/>
<vgroup id="holder" valign="bottom">
<hgroup id="item1" valign="bottom">
<text id="caption1" label="Member" value="" required="true" size="60" />
<textarea id="expression1" label="Enter a data source Expression:" cols="60" rows="5" hidden="true"/>
</hgroup>
</vgroup>
<button id="btnAdd" caption="Add" onclick="zenPage.addItem();"/>
</pane>
}

/// Add a new row
ClientMethod addItem() [ Language = javascript ]
{
	try {	

	var holder = zen("holder");
	var hgroup = zenPage.createComponent('hgroup');
	this.itemNumber = this.itemNumber + 1;
	hgroup.setProperty('id','item'+this.itemNumber);
	var text3 = zenPage.createComponent('text');
	var button = zenPage.createComponent('button');
	//var image = zenPage.createComponent('image');
	hgroup.addChild(text3);
	hgroup.addChild(button);
	holder.addChild(hgroup);

	text3.setProperty('id','caption'+this.itemNumber);
	text3.setProperty('size','60');
	button.setProperty('caption','Remove');
	button.setProperty('onclick','zenPage.clearItem('+this.itemNumber+');');
	//image.setProperty('width','16px');
	//image.setProperty('title','Remove range');
	// the following line has problem!!! prodlog 76674	
	//image.setProperty('src','deepsee/close_b_16.png');

	holder.refreshContents();
	}
	catch(ex) {
		zenExceptionHandler('addItem'+ex,arguments);
	}
}

ClientMethod clearItem(itemNumber) [ Language = javascript ]
{
	zen("holder").removeChild(zen("item"+itemNumber));
	zen("caption"+itemNumber).setHidden(true);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set value = $$$TextHTML("Unknown")
	If ..WHAT = "MemberList" Set value = $$$TextHTML("Member List")
	Else  If ..WHAT [ "SetExpression" Set value = $$$TextHTML("NamedSet - Set Expression")
	Else  If ..WHAT [ "CalMemberValueExpression" Set value = $$$TextHTML("Calculated Member - Value Expression")
	Else  If ..WHAT [ "Expression" Set value = $$$TextHTML("Data Source Expression")
	Else  If ..WHAT [ "ListingSQL" Set value = $$$TextHTML("Listing - SQL Query")
	Else  If ..WHAT [ "BuildRestriction" Set value = $$$TextHTML("Cube - Build Restriction")
	Quit value
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set value = ""
	If ..WHAT = "MemberList" Set value = $$$TextHTML("Edit member list for Architect.")
	Else  If ..WHAT [ "SetExpression" Set value = $$$TextHTML("Edit set expression for Architect.")
	Else  If ..WHAT [ "CalMemberValueExpression" Set value = $$$TextHTML("Edit value expression for Architect")
	Else  If ..WHAT [ "Expression" Set value = $$$TextHTML("Edit data source expression for Architect.")
	Else  If ..WHAT [ "ListingSQL" Set value = $$$TextHTML("Edit SQL Query for Architect.")
	Quit value
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {	
		var values = "";
		var v3;
		if (zen("caption1").getProperty("hidden") == true) {
			 values = zen("expression1").getValue();
		} else {
			for (var m = 1; m <= this.itemNumber; m++) {
				var text3 = "caption" + m;

				if (zen(text3)) {				
					v3 = zen(text3).getValue();				
					// exclude the item that does not have value or have been removed 
					if ((v3 != "")&&(zen(text3).getProperty("hidden")==false)) {
						if (values != "") values = values + ",";
						values = values + v3;
					}			
				}
			}
		}
		return encodeURIComponent(values);
		}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.WHAT != "MemberList") return true;
		var isok = true;
		var hasEmpty = 0;
		var text3;

		if (zen("caption1").getProperty("hidden") == true) {
			if (zen("expression1").getValue()=="") hasEmpty=1;
		} else {
			for (var m = 1; m <= this.itemNumber; m++) {
				text3 = "caption" + m;
				if (zen(text3).getValue()=="") {
					hasEmpty = 1;
					break;
				}		
			}
		}
		if (hasEmpty == 1) {
			if (confirm(this.msgHasEmpty)== false) {
				isok = false;
				zen(text3).focus();
			}
		}
		return isok;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return isok;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("ELEMENT").value = ..ELEMENT
		#; For datasource Property or Expression, do not show list if there is a comma in the value. 
		#; Display in full.
		If ..WHAT '= "MemberList" {
			Set ..%GetComponentById("titleText").hidden = 1
			Set ..%GetComponentById("btnAdd").hidden = 1
			If ..WHAT [ "Source" {
				Set ..%GetComponentById("caption1").label = ..lblProperty
				Set ..%GetComponentById("caption1").value = ..Expression
			} Else {
				Set ..%GetComponentById("caption1").hidden = 1
				Set ..%GetComponentById("expression1").hidden = 0
				Set ..%GetComponentById("expression1").value = ..Expression
				If ..WHAT = "ListingSQL" {
					Set ..%GetComponentById("expression1").label = $$$Text("Enter SQL Query for Listing:")
					Set ..%GetComponentById("expression1").rows = 12
				}
				If ..WHAT = "SetExpression" {
					Set ..%GetComponentById("expression1").label = $$$Text("Enter Set Expression:")
					Set ..%GetComponentById("expression1").rows = 12
				}
				If ..WHAT = "CalMemberValueExpression" {
					Set ..%GetComponentById("expression1").label = $$$Text("Enter Value Expression:")
					Set ..%GetComponentById("expression1").rows = 12
				}
				If ..WHAT = "BuildRestriction" {
					Set ..%GetComponentById("expression1").label = $$$Text("Enter Build Restriction:")
					Set ..%GetComponentById("expression1").rows = 12
				}
			}
			Quit
		}
		Set rangeTotal = +($L(..Expression,","))
		If rangeTotal = 0 Quit
		#; For MemberList:
		Set ..itemNumber = rangeTotal	
		For m = 1:1:..itemNumber {
			Set value = $P(..Expression,",",m)
			If m = 1 {
				Set ..%GetComponentById("caption"_m).value = value
			} Else {
				Set holder = ..%GetComponentById("holder")
				Set group = ##class(%ZEN.Component.hgroup).%New()
				Set group.id = "item"_m
				Do holder.%AddChild(group)
				Set ctrl = ##class(%ZEN.Component.text).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "caption"_m
				Set ctrl.value = value
				Set ctrl.size = 60
				Set ctrl = ##class(%ZEN.Component.image).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.width = "16px"
				Set ctrl.src = "deepsee/close_a_16.png"
				Set ctrl.onclick = "zenPage.clearItem('"_m_"');"
				Set ctrl.title = $$$Text("Remove")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (!zen("expression1").getProperty("hidden")) {
		zen("expression1").focus();	
	}
}

}
