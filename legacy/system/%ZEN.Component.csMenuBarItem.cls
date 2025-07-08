/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csMenuBarItem
Class %ZEN.Component.csMenuBarItem Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

/// label normally associated with the menu pick
Property caption As %ZEN.Datatype.caption;

/// If defined, keystroke of caption to invoke functionality when
/// menu is active
Property contextKey As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
.csMenuBarItem {
    display:inline;
    cursor:pointer;
    font: 12px sans-serif;
    background: white;
    color: black;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csMenuBarItem" id="#(..%MakeId("csMenuBarItem"))#" #(..%Attr("caption",..caption))# #(..%Attr("contextKey",..contextKey))# >>
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
	  if (k.nodeType==1 && k.className=="csMenuBarItem") {
		 ZMS.createMenuBarItemSubtree(k,20);
		 div.item=k; 
	  }
    }
}

}
