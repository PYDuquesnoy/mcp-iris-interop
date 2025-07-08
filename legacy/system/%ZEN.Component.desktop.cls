/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a desktop group.<br/>
/// A desktop is a specialized group that allows the user to drag and 
/// position its child components within a matrix of rows and columns.
/// The immediate children of a desktop component MUST be dragGroups
/// but there are no restrictions placed on the contents of the dragGroups
/// themselves. <br>
/// The desktop honors all the innate functionality of the dragGroup 
/// component, including: free resize; maximize; minimize; close; and,
/// restore <br>
/// The desktop component supports interactive layout changes via mouse
/// drag operations.  DragGroups may be rearranged, resized or removed
/// at will. <br>
/// The arrangement of dragGroups within the Desktop is biased in favor
/// of row collapse.  This means that if a dragGroup is removed from a 
/// given row, any other groups in the same row will move to the left,
/// collapsing the length of the row and possibly creating blank space 
/// at the extreme right end ofthe row.  This is done to bias ithe display
/// in favor of maximizing ther use of the visible portions of the window
/// and minimizing the need for horizontal scrolling. <br>
/// In addition to the auto row collapse, the component supports row and 
/// column style settings that can enforce certain geometry and alignment
/// constraints on the dragGroups sub-windows of the widget as a whole <br>
/// The initial layout of the groups within the destkop may be hinted at
/// via the use of CSS top and left properties.  The page designer may 
/// suggest the initial location of the window and the desktop manager will
/// make every effort to abide by the suggestion within the other contraints
/// actively being enforced by the widget.  Row and column styles, automatic
/// row colapse and a prohibition against overlapping dragGroups make it
/// impossible to guarantee that the placement suggested via CSS will be 
/// respected to the pixel.  If an exact location for the dragGroup sub-
/// windows is required, see the corkboard component.<br>
/// The current state of the desktop's internal layout may be querried
/// or saved at any time.  The return value of the query function may also
/// be used to restore the layout at a later time.
Class %ZEN.Component.desktop Extends abstractDragGroupMgr [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenDesktop.js";

/// Subclasses can change this to alter the default geometry and
/// alignment of dragGroups within rows.
Parameter DEFAULTROWSTYLE As STRING = "ALIGN_ROW_TOP";

/// Subclasses can change this to alter the default geometry and
/// alignment of dragGroups within rows.
Parameter DEFAULTCOLSTYLE As STRING;

/// The desktop enforces sizing and alignment constraints on the groups
/// within its rows.  There are eight possible configurations.<br>
/// FILL_ROW: All groups within a row have the height of the tallest
/// group in the row.  By default the top and bottom edges of all the
/// sub-windows align.  Height is allowed to vary from one row to the
/// next.<br>
/// ALIGN_ROW_TOP: (the default) The top edge of all subwidows within
/// a row align.  The height of individual subwindows within the row is
/// allowed to vary.  The row spacing is driven by the tallest group
/// within the row. <br>
/// ALIGN_ROW_CENTER: All subwidows are centered vertically within their 
/// respective rows.  The height of individual dragGroups is allowed to
/// vary.  The row spacing is driven by the tallest group within the row.<br>
/// ALIGN_ROW_BOTTOM: The bottom edge of all subwidows within a row align.
/// The height of individual subwindows within the row is allowed to vary.
///  The row spacing is driven by the tallest group within the row. <br>
/// FILL_UNIFORM: ALL subwindows within the desktop take on the height of
/// the tallest dragGroup. This results in all rows being uniformly spaced
/// vertically and all dragGroups being both top and bottom aligned. <br>
/// ALIGN_UNIFORM_TOP: All rows within the desktop take on uniform spacing
/// dictated by the height of the tallest group within the component.
/// Within each row, the top edges of individual dragGroups align.  The
/// height of individual dragGroups is aloowed to vary. <br>
/// ALIGN_UNIFORM_CENTER: All rows within the desktop take on uniform 
/// spacing dictated by the height of the tallest group within the 
/// component. Within each row, individual dragGroups are centered 
/// vertically. The height of individual dragGroups is aloowed to vary. <br>
/// ALIGN_UNIFORM_BOTTOM: All rows within the desktop take on uniform 
/// spacing dictated by the height of the tallest group within the 
/// component. Within each row, the bottom edges of individual dragGroups 
/// align.  The height of individual dragGroups is aloowed to vary.
Property rowStyle As %ZEN.Datatype.string(MAXLEN = 24, VALUELIST = ",FILL_ROW,ALIGN_ROW_TOP,ALIGN_ROW_CENTER,ALIGN_ROW_BOTTOM,FILL_UNIFORM,ALIGN_UNIFORM_TOP,ALIGN_UNIFORM_CENTER,ALIGN_UNIFORM_BOTTOM") [ InitialExpression = {..#DEFAULTROWSTYLE} ];

/// The desktop enforces sizing and alignment constraints on the groups
/// within its columns.  The matrix of the desktop container is row biased
/// and does not, by default, recognize the existence of columns.  Changing
/// the column style, however, will alter this behavoir such that all the
/// first elements of the rows will be treated as column one, all the second
/// elements become column two, etc.  Unlike rows (which repack themselves
/// when are removed or added) columns are allowed to have embedded gaps
/// where a short row does not reach a given column. There are thirteen 
/// possible configurations.<br>
/// (null): (the default) The concept of columns is ignored, only row-based
/// constraints apply.  The width of individual dragGroups is allowed to
/// vary at will<br>
/// FILL_COLUMN: All dragGroups within a given column take on the width of
/// the widest group within the column.  All subwindows become both left
/// and right aligned.  The spacing of the columns is allowed to vary from
/// one column to the next <br>
/// ALIGN_COLUMN_LEFT: The width of the column is dictated by the width of
/// the widest group within that column but the width of individual sub-
/// windows is allowed to vary.  All dragGroups are left aligned within 
/// their columns. The spacing of the columns is allowed to vary from
/// one column to the next <br>
/// ALIGN_COLUMN_CENTER: The width of the column is dictated by the width 
/// of the widest group within that column but the width of individual
/// subwindows is allowed to vary.  All dragGroups are centered within 
/// their columns. The spacing of the columns is allowed to vary from
/// one column to the next <br>
/// ALIGN_COLUMN_RIGHT: The width of the column is dictated by the width of
/// the widest group within that column but the width of individual sub-
/// windows is allowed to vary.  All dragGroups are right aligned within 
/// their columns. The spacing of the columns is allowed to vary from
/// one column to the next <br>
/// FILL_WIDTH: The total width of the longest row dictates the layout
/// bounds for the entire desktop container.  The widths of dragGroups 
/// within shorter rows are scaled up proportionately so as to ensure 
/// that right edge of the the last group in each row is aligned
/// with that of every other row on the desktop. <br>
/// ALIGN_WIDTH_LEFT: Similar to FILL_WIDTH, the subwindows within rows
/// are horizontally spaced based on the width of the longest row. The
/// widths of individual windows is not padded, creating (seemingly)
/// random spacing between groups within a row. <br>    
/// ALIGN_WIDTH_CENTER: Similar to FILL_WIDTH, the subwindows within rows
/// are horizontally spaced based on the width of the longest row. The
/// widths of individual windows is not padded, and the subwindows are
/// centered within the revised spacing bounds. <br>    
/// ALIGN_WIDTH_RIGHT: Similar to FILL_WIDTH, the subwindows within rows
/// are horizontally spaced based on the width of the longest row. The
/// widths of individual windows is not padded. The subwindows are
/// right aligned within the revised spacing bounds.<br>    
/// FILL_UNIFORM: All columns take on the width and spacing dictated by
/// the widest dragGroup within the desktop.  All groups are given uniform
/// width, and are automatically left and right aligned <br>
/// ALIGN_UNIFORM_LEFT: All columns take on the width and spacing dictated
/// by the widest dragGroup within the desktop. The widths of individual
/// dragGroups is allowed to vary.  All groups within a column are left
/// aligned. <br>
/// ALIGN_UNIFORM_CENTER: All columns take on the width and spacing dictated
/// by the widest dragGroup within the desktop. The widths of individual
/// dragGroups is allowed to vary.  All groups within a column are centered
/// within the column spacing. <br>
/// ALIGN_UNIFORM_RIGHT: All columns take on the width and spacing dictated
/// by the widest dragGroup within the desktop. The widths of individual
/// dragGroups is allowed to vary.  All groups within a column are right
/// aligned. <br>
Property colStyle As %ZEN.Datatype.string(MAXLEN = 24, VALUELIST = ",,FILL_COLUMN,ALIGN_COLUMN_LEFT,ALIGN_COLUMN_CENTER,ALIGN_COLUMN_RIGHT,FILL_WIDTH,ALIGN_WIDTH_LEFT,ALIGN_WIDTH_CENTER,ALIGN_WIDTH_RIGHT,FILL_UNIFORM,ALIGN_UNIFORM_LEFT,ALIGN_UNIFORM_CENTER,ALIGN_UNIFORM_RIGHT") [ InitialExpression = {..#DEFAULTCOLSTYLE} ];

/// The logical name of the manager with respect to the external JavaScript 
/// code that actually manages the space 
Property groupName As %ZEN.Datatype.string [ InitialExpression = "desktop" ];

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for desktop group." */
.desktopGroup {
	position:absolute;
	overflow:auto;
	width:100%;
	height:1px;
}

.zenDesktopGhostPane {
	border: solid gray;
	background-color: silver;
}

</style>
}

Method %DrawHTML()
{
	&html<<div class="#(..groupName)#Group" id="#(..%MakeId(..groupName))#" style="width:100%; height:100%; position:absolute;" #(..%Attr("rowStyle",..rowStyle))#  #(..%Attr("colStyle",..colStyle))# >>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
		case 'rowStyle':
			this.setRowStyle(value);
			break;
		case 'colStyle' :
			this.setColStyle(value);
			break;
		case 'width' :
			var desk = this.getEnclosingDiv();
			desk.style.width = value;
			break;
		case 'height' :
			var desk = this.getEnclosingDiv();
			desk.style.height = value;
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
    ZLM.registerManagerClass(this.groupName+"Group",ZLM_VDP.initDesktop);
    ZLM.initLayout();
}

/// Set the vertical spacing between rows of dragGroups within the 
/// desktop area
ClientMethod setVerticalGap(size) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setVerticalGap(size);
 	}
}

/// Set the horizontal spacing between rows of dragGroups within the 
/// desktop area
ClientMethod setHorizontalGap(size) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setHorizontalGap(size);
 	}
}

/// Set the top margin between first rows of dragGroups within the 
/// desktop area and the top of the desktop itself
ClientMethod setTopMargin(size) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setTopMargin(size);
 	}
}

/// Set the left margin between first rows of dragGroups within the 
/// desktop area and the left edge of the desktop itself
ClientMethod setLeftMargin(size) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setLeftMargin(size);
 	}
}

ClientMethod setRowStyle(style) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setRowStyle(style);
 	}
}

ClientMethod setColumnStyle(style) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.setColumnStyle(style);
	}
}

ClientMethod getState() [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		return(manager.getStateString());
	}
	return(null);
}

ClientMethod restoreState(layout) [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.restoreState(layout);
	}
}

ClientMethod onRefreshContents() [ Language = javascript ]
{
	setTimeout("zen('"+this.id+"').doDeferredRefresh();",0); // update AFTER the reset of the page
}

ClientMethod doDeferredRefresh() [ Language = javascript ]
{
	var manager = this.getGroupManager();
	if (manager) {
		manager.resynchronize(this.getEnclosingDiv().firstChild);
	}
}

}
