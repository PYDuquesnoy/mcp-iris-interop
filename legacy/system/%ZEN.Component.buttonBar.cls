/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.buttonBar
Class %ZEN.Component.buttonBar Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for COMP_NAME." */
.buttonBar {
	 display:block;
     background: #e0e0e0;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="buttonBar" id="#(..%MakeId("buttonBar"))#" >>
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
	var div =this.getEnclosingDiv();
	for(var k=div.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="buttonBar") {
			div.buttonBar=k;
			ZMS.sizeButtonBar(k);
			//ZLM.setLocalAttribute(k,"onresize","ZMS.organizeButtonBar(this);");
			ZLM.notifyResize(document.body);
			return;
		}
	}
}

}
