/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user add or edit Range Expression for level definition.
Class %DeepSee.UI.Dialog.RangeExpression Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property levelName As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property rangeExpression As %ZEN.Datatype.string(ZENURL = "VALUE");

Property itemNumber As %ZEN.Datatype.integer [ InitialExpression = "1" ];

Property msgHasEmpty As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("There is at least one empty 'Replacement Value'. Replacement without a value will not be saved. Proceed?")} ];

Property msgHasNan As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("There is at least one value that is not numeric where it should be. Please correct and try again.")} ];

Property msgReset As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This will discard all changes and reload the form. Proceed?")} ];

Property titleBtnE As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Exclusive. Click to change to Inclusive.")} ];

Property titleBtnI As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Inclusive. Click to change to Exclusive.")} ];

XData Style
{
<style type="text/css">
.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}
<!-- style for button on this page
.button {
	background: #346c8d;
	color: white;
	font-size: 9pt;
}
-->
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
<label id="levelName" label="Level name:" enclosingClass="zenLabel"/>
</vgroup>
<label label="Enter a set of replacement values." enclosingStyle="padding:2px;"/>
<vgroup>
<radioButton name="formType" id="radNum" label="Form of original values" 
caption="Numeric ranges (possibly open-ended)" optionValue="1" onclick="zenPage.changeForm(1);"/>
<radioButton name="formType" id="radStr" caption="Strings" optionValue="0" onclick="zenPage.changeForm(0);"/>
</vgroup>

<vgroup id="holder" >
<hgroup id="item1" cellVAlign="bottom" >
<button id="btnFrom1" caption="(" title="Exclusive. Click to change to Inclusive." onclick="zenPage.btnChange('btnFrom1');"/>
<text id="from1" label="From" value=""/>
<text id="to1" label="To" value=""/>
<button id="btnTo1" caption=")" title="Exclusive. Click to change to Inclusive." onclick="zenPage.btnChange('btnTo1');"/>
<text id="caption1" label="Replacement Value (Required)" value="" required="true" />
</hgroup>
</vgroup>
<hgroup>
<button id="btnAdd" caption="Add Replacement" onclick="zenPage.addItem();"/>
<button id="btnClear" caption="Clear Changes" onclick="zenPage.resetForm();"/>
</hgroup>
<!--
<hgroup id="idNum">
<label label="Exclusive: " labelClass="zenHint"/>
<button caption="(" title="Exclusive. Click to change to Inclusive." />
<button caption=")" title="Exclusive. Click to change to Inclusive."/>
<label label="Inclusive: " labelClass="zenHint" containerStyle="padding-left:10px;"/>
<button caption="[" title="Inclusive. Click to change to Exclusive."/>
<button caption="]" title="Inclusive. Click to change to Exclusive."/>
<label label="Click a button to toggle between Exclusive and Inclusive." labelClass="zenHint" containerStyle="padding-left:10px;"/>
</hgroup>
-->
</pane>
}

/// User changed the form of original values (this is only available if user has not "Added" any new item.
/// Convert what's been defined to the new form.
ClientMethod changeForm(value) [ Language = javascript ]
{
	try {
		for (var m = 1; m <= this.itemNumber; m++) {
			var text1 = "from" + m;
			var text2 = "to" + m;
			var btnFrom = "btnFrom" + m;
			var btnTo = "btnTo" + m;
			if (value == 0) {
				/// Strings:
				if (m == 1) {
					zen(text1).setProperty("label",$$$Text("Original Value"));
				}
				zen(text2).setHidden(true);
				zen(btnFrom).setHidden(true);
				zen(btnTo).setHidden(true);
			} else {
				/// Numeric ranges
				if (m == 1) {
					zen(text1).setProperty("label",$$$Text("From"));
				}
				zen(text2).setHidden(false);
				zen(btnFrom).setHidden(false);
				zen(btnTo).setHidden(false);
			}
		}			
	}
	catch(ex) {
		zenExceptionHandler('changeForm'+ex,arguments);
	}
}

/// Add a new row. <br>
/// formType = 0 means user selected "Strings" to be the form of original values.
/// formType = 1 means user selected "Numeric ranges" to be the form of original values.
ClientMethod addItem() [ Language = javascript ]
{
	try {
		var formType = zen("radNum").getValue();
		var holder = zen("holder");
		var hgroup = zenPage.createComponent('hgroup');
		this.itemNumber++;
		hgroup.setProperty('id','item'+this.itemNumber);
		var text1 = zenPage.createComponent('text');
		if (formType == 1) {
			zen("radStr").setDisabled(true);
			var btn1 = zenPage.createComponent('button');
			var text2 = zenPage.createComponent('text');
			var btn2 = zenPage.createComponent('button');
			hgroup.addChild(btn1);
			hgroup.addChild(text1);
			hgroup.addChild(text2);
			hgroup.addChild(btn2);
			text2.setProperty('id','to'+this.itemNumber);
			var btn1Id = 'btnFrom'+this.itemNumber;
			btn1.setProperty('id',btn1Id);
			btn1.setProperty('caption','(');
			btn1.setProperty('onclick',"zenPage.btnChange('"+btn1Id+"');");
			btn1.setProperty('title',this.titleBtnE);
			var btn2Id = 'btnTo'+this.itemNumber;
			btn2.setProperty('id',btn2Id);
			btn2.setProperty('caption',')');
			btn2.setProperty('onclick',"zenPage.btnChange('"+btn2Id+"');");
			btn1.setProperty('title',this.titleBtnE);
		} else {
			zen("radNum").setDisabled(true);	
			hgroup.addChild(text1);
		}
		// for formType = 0 we have text1 and text3 per row
		var text3 = zenPage.createComponent('text');
		var button = zenPage.createComponent('button');
		//var image = zenPage.createComponent('image');
		hgroup.addChild(text3);
		hgroup.addChild(button);
		holder.addChild(hgroup);
		text1.setProperty('id','from'+this.itemNumber);
		//Joe, the following doesn't work
		//text1.setProperty('size',8);
		//text2.setProperty('size',8);
		text3.setProperty('id','caption'+this.itemNumber);
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

/// Discard whatever user entered and reload form
ClientMethod resetForm() [ Language = javascript ]
{
	if (confirm(this.msgReset) == true) {
		document.location = document.location.href;
	}
}

ClientMethod btnChange(itemId) [ Language = javascript ]
{
	var currentState = zen(itemId).getProperty("caption");
	switch (currentState) {
		case "[":
			zen(itemId).setProperty("caption","(");
			zen(itemId).setProperty("title",this.titleBtnE);
			break;	
		case "(":
			zen(itemId).setProperty("caption","[");
			zen(itemId).setProperty("title",this.titleBtnI);
			break;
		case "]":
			zen(itemId).setProperty("caption",")");
			zen(itemId).setProperty("title",this.titleBtnE);
			break;
		case ")":
			zen(itemId).setProperty("caption","]");
			zen(itemId).setProperty("title",this.titleBtnI);
			break;
		default:
		alert("no caption");
		zen(itemId).setProperty("caption","(");	
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
	Quit $$$TextHTML("Range Expression")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Edit range expression for Architect.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		var formType = zen("radNum").getValue();
		var values = "";
		var v1,v2,v3,text1,text2,text3,btnFrom,btnTo;
		for (var m = 1; m <= this.itemNumber; m++) {
			text1 = "from" + m;
			text3 = "caption" + m;
			v1 = zen(text1).getValue();
			v3 = zen(text3).getValue();
			if (zen(text1)) {
				// as long as the user entered a caption and have not been removed, we are saving it 
				if (formType == 1) {
					text2 = "to" + m;
					btnFrom = "btnFrom" + m;
					btnTo = "btnTo" + m;
					v2 = zen(text2).getValue();
					s1 = zen(btnFrom).getProperty('caption');
					s2 = zen(btnTo).getProperty('caption');
					if ((v3 != "")&&(zen(text3).getProperty("hidden")==false)) {
					values = values + s1 + v1 + "," + v2 + s2 + ":" + v3 + ";";
					}
				} else {
					if ((v1 != "") && (v3 != "")) {						
						values = values + v1 + ":" + v3 + ";";
					}
				}
			}
		}
		// JMD: add call to encode
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
		var isok = true;
		var hasEmpty = 0;
		var hasNan = 0;
		var text1;
		var text3;
		var formType = zen("radNum").getValue();
		for (var m = 1; m <= this.itemNumber; m++) {
			text1 = "from" + m;
			text3 = "caption" + m;
			if (zen(text3) && zen(text1)) {
				if (zen(text3).getValue()=="" && zen(text1).getValue()!="") {
					hasEmpty = 1;
					break;
				}
			}
			if ((formType == 1) && (zen(text1))) {
				if (isNaN(zen(text1).getValue())==true) {
					hasNan = 1;
					break;
				}
			}
			if (zen(text3)) {
				// validate Replacement Value 
				if (!this.validateKey(zen(text3).getValue())) {
					alert($$$Text("Replacement value cannot contain any of these characters: ") + "\n\n" + "| & : ~");
					isok = false;
					zen(text3).focus();
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
		if (hasNan == 1) {
			alert(this.msgHasNan)
			isok = false;
			zen(text1).focus();
		}		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return isok;
}

ClientMethod validateKey(string) [ Language = javascript ]
{
	if (string.indexOf('|')>-1 || string.indexOf('&')>-1 || string.indexOf(':')>-1 || string.indexOf('~')>-1) return false;
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("levelName").value = ..levelName
		Set rangeTotal = +($L(..rangeExpression,";")-1)
		If rangeTotal = 0 {
			Set ..%GetComponentById("radNum").value = 1
			Quit
		}
		Set ..itemNumber = rangeTotal
		Set formType = 1
		For m = 1:1:..itemNumber {
			Set value = $P(..rangeExpression,";",m)
			Set text1 = $P($P(value,":",1),",",1)
			Set btnFrom = $E(text1,1)
			If btnFrom '= "(",btnFrom '= "[" Set btnFrom = ""
			Else  Set text1 = $E(text1,2,$L(text1))
			Set text2 = $P($P(value,":",1),",",2)
			Set btnTo = $E(text2,$L(text2))
			If btnTo '= ")",btnTo '= "]" Set btnTo = ""
			Else  Set text2 = $E(text2,1,$L(text2)-1)
		
			Set text3 = $P(value,":",2)
			If m = 1 {
				If btnFrom '= "" {
					Set ..%GetComponentById("btnFrom"_m).caption = btnFrom
					Set ..%GetComponentById("btnTo"_m).caption = btnTo
					Set ..%GetComponentById("to"_m).value = text2
				} Else {
					Set formType = 0
					Set ..%GetComponentById("btnFrom"_m).hidden = 1
					Set ..%GetComponentById("btnTo"_m).hidden = 1
					Set ..%GetComponentById("to"_m).hidden = 1						
				}
				Set ..%GetComponentById("from"_m).value = text1			
				Set ..%GetComponentById("caption"_m).value = text3
			} Else {
				Set holder = ..%GetComponentById("holder")
				Set group = ##class(%ZEN.Component.hgroup).%New()
				Set group.id = "item"_m
				Do holder.%AddChild(group)
				Set ctrl = ##class(%ZEN.Component.button).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "btnFrom"_m
				Set ctrl.caption = $S(btnFrom'="":btnFrom,1:"(")
				Set ctrl.onclick = "zenPage.btnChange('"_ctrl.id_"');"
				Set ctrl.hidden = formType = 0
				
				Set ctrl = ##class(%ZEN.Component.text).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "from"_m
				Set ctrl.value = text1

				Set ctrl = ##class(%ZEN.Component.text).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "to"_m
				Set ctrl.value = text2
				Set ctrl.hidden = formType = 0
				
				Set ctrl = ##class(%ZEN.Component.button).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "btnTo"_m
				Set ctrl.caption = $S(btnTo'="":btnTo,1:")")
				Set ctrl.onclick = "zenPage.btnChange('"_ctrl.id_"');"
				Set ctrl.hidden = formType = 0


				Set ctrl = ##class(%ZEN.Component.text).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.id = "caption"_m
				Set ctrl.value = text3
				Set ctrl = ##class(%ZEN.Component.image).%New()
				Do group.%AddChild(ctrl)
				Set ctrl.width = "16"
				Set ctrl.src = "deepsee/close_a_16.png"
				Set ctrl.onclick = "zenPage.clearItem('"_m_"');"
				Set ctrl.title = $$$Text("Remove range")
			}
		}
		If formType = 0 {
			Set ..%GetComponentById("from1").label = $$$Text("Original Value")
		}
		Set ..%GetComponentById("radNum").value = formType
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
