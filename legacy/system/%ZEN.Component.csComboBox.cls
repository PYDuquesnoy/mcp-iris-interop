/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csComboBox
Class %ZEN.Component.csComboBox Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

/// label normally associated with the menu pick
Property defaultCaption As %ZEN.Datatype.string [ InitialExpression = "Select..." ];

Property onchange As %ZEN.Datatype.eventHandler;

Property value As %ZEN.Datatype.string;

Property icon As %ZEN.Datatype.uri [ InitialExpression = "images/SmDownArrow.png" ];

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for csComboBox." */
.csComboBox {
    cursor:pointer;
    height:22px;
    width:150px;
    background: #e0e0e0;
    color: black;
}
  
.csComboBoxText {
    border:1px solid black;
    background:#f0f0f0;
    color:black;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csComboBox" id="#(..%MakeId("csComboBox"))#" #(..%Attr("defaultCaption",..defaultCaption))# #(..%Attr("icon",..icon))# #(..%Attr("onchange",..onchange))#>>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
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
	this.invokeSuper('onloadHandler',arguments);
	ZMS.initialize();
    var div=this.getEnclosingDiv();
	for (var k=div.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="csComboBox") {
			ZMS.organizeComboBox(k);
	        div.item=k;
	        return;
		}
	}
}

}
