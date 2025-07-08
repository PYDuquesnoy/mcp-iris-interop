/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the base class for all groups whose geometry is managed by
/// the client geometry manager.
Class %ZEN.Component.activeGroup Extends abstractGroup [ Deprecated, System = 3 ]
{

/// Subclasses can set this to change default css class for a group.
Parameter DEFAULTENCLOSINGCLASS = "activeGroup";

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for active group." */
.activeGroup {
	z-index: -100;
	overflow: hidden;
}

html { 
	height: 100%; 
}
    
#zenBody { 
    height: 100% 
} 

#zen1 { 
    height: 100%; 
} 

</style>
}

Method %DrawHTML()
{
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	this.invokeSuper('onloadHandler',arguments);

	// the activeGroup Div is only a shadow of the real
	// actively managed space but since the active space is
	// absolutely positioned this area might be zero-sized 
	// by browser layout managers.  If this is the case, grow 
	// as needed.
	
	// DO THAT CHECK HERE...
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
