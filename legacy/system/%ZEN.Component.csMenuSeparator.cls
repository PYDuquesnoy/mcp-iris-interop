/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csMenuSeparator
Class %ZEN.Component.csMenuSeparator Extends component [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for COMP_NAME." */
.csMenuSeparator {
    position:absolute;
    cursor:pointer;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csMenuSeparator" id="#(..%MakeId("csMenuSeparator"))#"></div>>
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

}
