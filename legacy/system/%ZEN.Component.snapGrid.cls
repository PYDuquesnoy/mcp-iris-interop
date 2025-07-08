/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.snapGrid is a dynamic layout control designed to organize 
/// dragGroups in a tiled layout with an automatic snap to grid feature.
/// The underlying grid is defined by the number of rows and columns requested.
/// The resulting gird is a normalized space where, for example a four column layout
/// would result in each column being 25% of the total width wide.<p/>
/// The grid itself does not scroll, however the dragGroups themselves may.<p/>
/// The layout may be further refined into portrait and landscape modes such that
/// the number of columns and rows may change if the geometry of the widget itself
/// becomes taller than it is wide (or vise versa).  This is particularly useful 
/// for adapting layouts on tablet devices such as the iPad. 
Class %ZEN.Component.snapGrid Extends abstractDragGroupMgr [ Deprecated, LegacyInstanceContext, System = 3 ]
{

Parameter INCLUDEFILES = "zenSnapGrid.js";

/// If defined, this is used to define the number of columns used for both
/// portrait and landscape layouts
Property cols As %ZEN.Datatype.integer [ InitialExpression = 3 ];

/// If defined, this is used to define the number of columns when the rendered
/// width of the widget is greater than or equal to its height
Property colsLandscape As %ZEN.Datatype.integer;

/// If defined, this is used to define the number of columns when the rendered
/// width of the widget is less than its height
Property colsPortrait As %ZEN.Datatype.integer;

/// If defined, this is used to define the number of rows used for both
/// portrait and landscape layouts
Property rows As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// If defined, this is used to define the number of rows when the rendered
/// width of the widget is greater than or equal to its height
Property rowsLandscape As %ZEN.Datatype.integer;

/// If defined, this is used to define the number of rows when the rendered
/// width of the widget is less than its height
Property rowsPortrait As %ZEN.Datatype.integer;

/// The logical name of the manager with respect to the external JavaScript 
/// code that actually manages the space 
Property groupName As %ZEN.Datatype.string [ InitialExpression = "snapGrid" ];

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for snapGrid group." */
.snapGridGroup {
	top:0px;
	left:0px;
	position:relative;
	overflow:hidden;
	width:100%;
	height:100%;
}

.snapGridGroup::-webkit-scrollbar {
	display:none;
}

</style>
}

Method %DrawHTML()
{
	&html<<div class="#(..groupName)#Group" id="#(..%MakeId(..groupName))#" style="width:100%; height:100%; position:relative; top:0px; left:0px;" 
	#(..%Attr("cols",..cols))# #(..%Attr("colsLandscape",..colsLandscape))# #(..%Attr("colsPortrait",..colsPortrait))# 
	#(..%Attr("rows",..rows))# #(..%Attr("rowsLandscape",..rowsLandscape))# #(..%Attr("rowsPortrait",..rowsPortrait))# >>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var mgr = this.getGroupManager();
	switch(property) {
		case "cols":
			this.cols = value;
			mgr.setNumberOfColumns(parseInt(value,10));
			break;
		case "rows":
			this.rows = value;
			mgr.setNumberOfRows(parseInt(value,10));
			break;
		case 'width':
		case 'height':
			// these affect the group this component is in
			this[property] = value;
			eDiv = this.getEnclosingDiv();
			eDiv.style[property]=value;
			this.forceResize();
			break;
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
	// set up geometry manager
    ZLM.registerManagerClass(this.groupName+"Group",ZLM_VSG.initSnapGrid);
    ZLM.initLayout();
}

}
