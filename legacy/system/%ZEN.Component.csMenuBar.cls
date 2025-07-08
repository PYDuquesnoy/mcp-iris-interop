/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csMenuBar
Class %ZEN.Component.csMenuBar Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

XData Style
{
<style type="text/css">
.csMenuBar {
	 display:block;
     background-color:white;
     border:1px solid blue;
     height:20px;
     width:100%;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csMenuBar" id="#(..%MakeId("csMenuBar"))#" >>
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
	  if (k.nodeType==1 && k.className=="csMenuBar") {
		  div.item=k;
		  ZMS.sizeMenuBar(k);
		  ZMS.organizeMenuBar(k);
		  return;
	  }
    }
}

}
