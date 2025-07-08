/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Container component.
/// A group is used to contain and layout a set of child components.
Class %ZEN.Component.group Extends abstractGroup [ Deprecated, System = 3 ]
{

/// Subclasses can set this to change default css class for a group.
Parameter DEFAULTGROUPCLASS = "group";

/// Subclasses can set this to change default layout for a group.
Parameter DEFAULTLAYOUT As STRING = "vertical";

/// Subclasses can set this to change default cellAlign for a group.
Parameter DEFAULTCELLALIGN As STRING [ Constraint = ",right,left,center,even", Flags = ENUM ];

/// Subclasses can set this to change default cellVAlign for a group.
Parameter DEFAULTCELLVALIGN As STRING [ Constraint = ",top,bottom,middle,even", Flags = ENUM ];

/// Subclasses can set this to change default labelPosition for a group.
Parameter DEFAULTLABELPOSITION As STRING [ Constraint = ",top,left", Flags = ENUM ] = "top";

/// Subclasses can set this to change default cellSize for a group.
Parameter DEFAULTCELLSIZE As STRING;

/// Subclasses can set this to change default groupStyle for a group.
Parameter DEFAULTGROUPSTYLE As STRING;

/// Subclasses can set this to change default cellStyle for a group.
Parameter DEFAULTCELLSTYLE As STRING;

/// Specifies how components within this group should be layed out. (VALUELIST = ",vertical,horizontal")
Property layout As %ZEN.Datatype.string(MAXLEN = 250, ZENENCRYPT = 1) [ InitialExpression = {..#DEFAULTLAYOUT} ];

/// Specifies horizontal alignment of cells layed out within this group.
Property cellAlign As %ZEN.Datatype.string(MAXLEN = 10, VALUELIST = ",left,right,center,even") [ InitialExpression = {..#DEFAULTCELLALIGN} ];

/// Specifies vertical alignment of cells layed out within this group.
Property cellVAlign As %ZEN.Datatype.string(MAXLEN = 10, VALUELIST = ",top,bottom,middle,even") [ InitialExpression = {..#DEFAULTCELLVALIGN} ];

/// Specifies how the size of cells within this group should be calculated (along layout direction).
Property cellSize As %ZEN.Datatype.string(MAXLEN = 10, VALUELIST = ",same,stretch") [ InitialExpression = {..#DEFAULTCELLSIZE} ];

/// Specifies where labels should be displayed for components within this group.
/// "top" places the labels above the components.
/// "left" places the labels to the left of the components.
Property labelPosition As %ZEN.Datatype.string(MAXLEN = 10, VALUELIST = ",left,top") [ InitialExpression = {..#DEFAULTLABELPOSITION} ];

/// Optional style used for table displayed by this group.
Property groupStyle As %ZEN.Datatype.style [ InitialExpression = {..#DEFAULTGROUPSTYLE} ];

/// Specifies additional style for cells layed out within this group.
/// This is primarily intended for cell padding.
Property cellStyle As %ZEN.Datatype.style [ InitialExpression = {..#DEFAULTCELLSTYLE} ];

/// Optional CSS class used for table displayed by this group.
Property groupClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTGROUPCLASS} ];

/// onclick event handler:
/// This event is fired when the mouse is clicked on the group.<br>
/// Note, if you need to specify an onclick event for a group, you have to
/// be very familiar with event handling in HTML/JavaScript. Your event handling code
/// will have to take into consideration that this event is fired whenever the mouse is clicked
/// within the enclosing div element for this group. For example, clicking on a button within the
/// group will fire the onclick handlers for both the button and the group.<br>
/// You can detect if the click was directly on the group by examining the event object (passed via the <var>zenEvent</var> variable).
/// For example:
/// <example language="JavaScript">
/// // look at source element; 
/// var target = (null == zenEvent.target) ? zenEvent.srcElement : zenEvent.target;
/// // all enclosing divs will define an attribute called 'zen'.
/// var zen = target.getAttribute('zen');
/// if (zen) {
/// }
/// </example>
Property onclick As %ZEN.Datatype.eventHandler;

XData Style
{
<style type="text/css">
/* @doc="Table used by groups." */
table.group {
	padding: 0px;
}

/* @doc="Cell within table used by groups." */
table.group td {
	padding: 0px;
}

/* @doc="Header within table used by groups." */
table.group th {
	padding: 0px;
}

/* @doc="Style for td containing component label in a vertical group." */
.vtLabelLeft {
	text-align: right;
}

/* @doc="Style for td containing component label in a horizontal group." */
.hzLabelLeft {
	text-align: right;
}

</style>
}

/// Override this method to inject additional event handlers into the enclosing div.
Method %OnDrawEnclosingDiv() As %String [ CodeMode = expression ]
{
$S(..onclick="":"",1:" onclick=""return zenFireEvent('"_..index_"','"_$ZCVT($$$ZENVALJS(..onclick),"O","JS")_"','onclick',event);""")
}

Method %DrawHTML()
{
	#; layout children (use tuple of *this* group
	#; as we may be part of a repeatingGroup)
	Do ..%LayoutChildren(..tuple)
}

/// Does the actual work of laying out the children of this group.
/// <var>pTuple</var> indicates the current tuple number in the
/// case of a repeatingGroup.
Method %LayoutChildren(pTuple As %Integer = "") [ Private ]
{
	Set $ZT = "Trap"
	#; dispatch to Layout Manager to provide HTML layout
	#; if a *built-in* method; dispatch directly
	If (..layout = "vertical") {
		Do ##class(%ZEN.LayoutManager).vertical($this,pTuple)
	}
	ElseIf (..layout = "horizontal") {
		Do ##class(%ZEN.LayoutManager).horizontal($this,pTuple)
	}
	ElseIf ((..layout = "")||(..layout = "none")) {
		#; no layout
		Do ##class(%ZEN.LayoutManager).default($this,pTuple)
	}
	Else {
		If (..layout [ ":") {
			#; dispatch to "class:method"
			Set tLayoutClass = $P(..layout,":",1)
			Set tLayoutMethod = $P(..layout,":",2)
		}
		Else {
			#; dispatch to "%ZEN.LayoutManager:method"
			Set tLayoutClass = "%ZEN.LayoutManager"
			Set tLayoutMethod = ..layout
		}
		Do $zobjclassmethod(tLayoutClass,tLayoutMethod,$this,pTuple)
	}
Done
	Quit
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
	Goto Done
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
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
