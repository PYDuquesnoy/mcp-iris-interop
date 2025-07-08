/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.tabFrame
Class %ZEN.Component.tabFrame Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenWL.js";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for tabFrame." */
 .tabFrame {
    width:100%;
    height:1px;
    background:#e0e0e0;
    overflow:hidden;
  }
  
  .tabMenu {
    background:#005f5f;
    width:100%;
    height:50px;
    font-family:"Arial Black";
    font-size:14px;
  }

  .tabEdge {
    background:#000011;
  }
</style>
}

Method %DrawHTML()
{
	&html<<div class="tabFrame" id="#(..%MakeId("tabFrame"))#" style="width:400; height:200;">>
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
	ZWL.initTabFrame();
}

}
