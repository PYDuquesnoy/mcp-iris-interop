/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user select multiples from a list of definition, primarily used to select iKnow Dictionaries.<br>
/// An existing list (delimited by comma) may be passed in.<br>
Class %DeepSee.UI.Dialog.GetDictionaryList Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property ELEMENT As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property VALUE As %ZEN.Datatype.string(ZENURL = "VALUE");

Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

XData Style
{
<style type="text/css">
.errorNote {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 12px;
	background: #F2F1EC;
	border: 1px solid #4D3926;
	color: #da4848;
	padding: 10px;
	text-align: left;
	font-weight: bold;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" controlClass="zenLabel"/>
<label id="ELEMENT" label="Element name:" controlClass="zenLabel"/>
</vgroup>
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true"/>
<hgroup id="g1" cellVAlign="middle" enclosingStyle="padding-left:20px;">
<listBox name="lst1" id="lst1" label="Available Dictionaries" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lst1','lstselect1');" listWidth="220px" listHeight="80px" hzScroll="false">
</listBox>
<spacer width="4"/>
<button id="btnL1" caption="&lt;" onclick="zenPage.arrowClick('lstselect1','lst1');"/>
<button id="btnR1" caption="&gt;" onclick="zenPage.arrowClick('lst1','lstselect1');"/>
<spacer width="4"/>
<listBox name="lstselect1" id="lstselect1" label="Selected Dictionaries" labelStyle="font-size:10px;" ondblclick="zenPage.arrowClick('lstselect1','lst1');" listWidth="220px" listHeight="80px" hzScroll="false">
</listBox>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set value = $$$TextHTML("Unknown")
	If ..WHAT = "iKnowDictionaries" Set value = $$$TextHTML("iKnow Dictionaries")
	Quit value
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set value = ""
	If ..WHAT = "iKnowDictionaries" Set value = $$$TextHTML("Select iKnow dictionaries for iKnow measure.")
	Quit value
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {	
		var lst1 = "";
		var item = "";
		var cnt = this.getComponentById("lstselect1").getOptionCount();
		for (i=0;i<cnt;i++) {
			item = this.getComponentById("lstselect1").getOptionValue(i);
			if (i == 0) lst1 = item;
			else lst1 = lst1 + "," + item; 
		}
		return encodeURIComponent(lst1);
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
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return 1;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

/// ------------------ Utility Methods for Moving between lstboxes ------------------ ///
/// Moving a list item from one box to the next, then remove it from the original box ///
ClientMethod arrowClick(from, to) [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById(from);
	var currIndex = fromCtl.selectedIndex;
	if ( (currIndex < 0) || (currIndex >= fromCtl.getOptionCount()) ) return;	
	var optionValue = fromCtl.getOptionValue(currIndex);
	var optionText = fromCtl.getOptionText(currIndex);
	var toCtl = zenPage.getComponentById(to);
	toCtl.appendOption(optionValue,optionText);
	
	fromCtl.removeOption(currIndex);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("ELEMENT").value = ..ELEMENT
		Set selected = ..VALUE
		For n = 1:1:$L(selected,",") Set item = $P(selected,",",n) If item'="" Set selected(item) = item
		Set sc = ##class(%DeepSee.TermList).%GetTermLists(.dictList)
		#; display error message is failed to retrieve the term list
		If $$$ISERR(sc) {
			Set ..%GetComponentById("idRespond").value = $ZCVT(sc,"O","HTML")
			Set ..%GetComponentById("idRespond").hidden = 0
			Set ..%GetComponentById("btnOK").disabled = 1
			Set ..%GetComponentById("btnOK").controlClass = "commandButtonDisabled"
			Quit
		}
		#; load the available and selected dictionaries
		Set tCombo = ..%GetComponentById("lst1")
		Set tSelCombo = ..%GetComponentById("lstselect1")
		Set item = $O(dictList(""))
 		While (item '= "") {
	 		Set tName = $LG(dictList(item),1)
	 		Set tCaption = $LG(dictList(item),2)
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			If $G(selected(tName)) = "" Do tCombo.options.Insert(tOption)
			Else  Do tSelCombo.options.Insert(tOption)
			Set tOption.text = $S(tCaption'="":tCaption,1:tName)
			Set tOption.value = tName
			Do ..%AddComponent(tOption)
	 		Set item = $O(dictList(item))
 		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
