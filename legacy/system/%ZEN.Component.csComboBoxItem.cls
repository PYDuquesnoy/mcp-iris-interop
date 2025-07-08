/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csComboBoxItem
Class %ZEN.Component.csComboBoxItem Extends component [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

/// label normally associated with the menu pick
Property caption As %ZEN.Datatype.caption;

/// If defined, keystroke of caption to invoke functionality when
/// menu is active
Property contextKey As %ZEN.Datatype.string;

/// If defined, an internal alternative return value for the combo box
/// If undefined, the caption is used as the value.
Property value As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for csComboBoxItem." */
.csComboBoxItem {
    position:absolute;
    cursor:pointer;
    font: 12px sans-serif;
    background: white;
    color: black;
    height:20px;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csComboBoxItem" id="#(..%MakeId("csComboBoxItem"))#" #(..%Attr("caption",..caption))# #(..%Attr("contextKey",..contextKey))# #(..%Attr("value",..value))# >>
	&html<</div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	//this.invokeSuper('onloadHandler',arguments);
	ZMS.initialize();
    var div=this.getEnclosingDiv();
	for (var k=div.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="csComboBoxItem") {
			ZMS.createComboItemSubtree(k);
	        div.item=k;
	        return;
		}
	}
}

}
