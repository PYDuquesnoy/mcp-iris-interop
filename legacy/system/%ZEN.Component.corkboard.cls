/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.corkboard
Class %ZEN.Component.corkboard Extends abstractDragGroupMgr [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCorkboard.js";

/// The logical name of the manager with respect to the external JavaScript 
/// code that actually manages the space 
Property groupName As %ZEN.Datatype.string [ InitialExpression = "corkboard" ];

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for desktop group." */
.corkboardGroup {
	position:absolute;
	overflow:auto;
	width:100%;
	height:1px;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="#(..groupName)#Group" id="#(..%MakeId(..groupName))#" style="width:100%; height:100%; position:absolute;">>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	this.invokeSuper('onloadHandler',arguments);

	// set up geometry manager
    ZLM.registerManagerClass(this.groupName+"Group",ZLM_VCB.initCorkboard);
    ZLM.initLayout();
}

}
