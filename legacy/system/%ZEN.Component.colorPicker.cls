/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A simple color selection control.<br>
/// This displays a set of cells of different colors, as
/// specified by the <property>colorList</property> property.<br>
/// The value of the control is the most recently selected color.
Class %ZEN.Component.colorPicker Extends control [ Deprecated, System = 3 ]
{

/// Do not include in "form" module.
Parameter SYSMODULE;

/// Comma-delimited list of CSS color values displayed within the control.
Property colorList As %ZEN.Datatype.csv;

/// Width of color cells.
Property cellWidth As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// Number of color cells in one row.
Property cellsPerRow As %ZEN.Datatype.integer [ InitialExpression = 16 ];

/// Optional. Choose a more extensive set of colors to display.
Property palette As %ZEN.Datatype.string(VALUELIST = ",basic,expanded") [ InitialExpression = "basic" ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Table wrapper for colorPicker." */
table.colorPicker {
	border: 1px darkblue solid;
}

/* @doc="Cell in colorPicker." */
.colorPickerCell {
	border: 2px #F0F0FF solid;
	cursor: pointer;
}

/* @doc="Selected cell in colorPicker." */
.colorPickerCellSelected {
	border: 2px red solid;
	cursor: pointer;
}

</style>
}

Method %DrawHTML()
{
	If (..colorList'="") {
		Set tColorList = ..colorList
	}
	ElseIf (..palette="expanded") {
		Set tColorList = ",black,#404040,#606060,#808080,#A0A0A0,#D0D0D0,white,#000080,#4040D0,#8080D0,#8080FF,#2020FF,#800000,#D04040,#D08080,#FF8080,#FF2020,#008000,#40D040,#80D080,#80FF80,#20FF20,#808000,#D0D040,#D0D080,#FFFF80,#FFFF20,#800080,#D040D0,#D080D0,#FF80FF"
	}
	Else {
		Set tColorList = ",black,gray,darkblue,darkred,darkgreen,blue,red,green,yellow,orange,plum,purple,white"
	}
	
	#; draw color picking control
	#; use hidden control to make sure there is a value to submit
	&html<<input type="hidden" id="#(..%MakeId("colorPicker"))#" #(..%Name())# value="#($ZCVT(..value,"O","HTML"))#"/>>

	&html<<table class="colorPicker" title="#($ZCVT(..title,"O","HTML"))#" border="0" cellpadding="0" cellspacing="0">
	<tr>>

	Set tNumColors = $L(tColorList,",")
	For c = 1:1:tNumColors {
		Set tColor = $P(tColorList,",",c)
		Set tCls = $S(..value=tColor:"colorPickerCellSelected",1:"colorPickerCell")
		Set tBGColor = $S(tColor="":"white",1:tColor)
		&html<<td class="#(tCls)#" id="#(..%MakeId("colorPicker_"_tColor))#" style="width:#(..cellWidth)#px;" onclick="zenPage.getComponent(#(..index)#).selectColor('#(tColor)#',true);">
		<div #($S(tColor="":"title=""No color""",1:""))# style="background:#(tBGColor)#; border:1px solid black;height:#(..cellWidth)#px;">&nbsp;</div>
		</td>>
		If ((+..cellsPerRow>0) && (c < tNumColors)&& '(c#..cellsPerRow)) {
			&html<</tr><tr>>
		}
	}

	&html<</tr>
	</table>>
}

/// User has selected a color. If <var>notify</var>
/// is true invoke onchange notification.
ClientMethod selectColor(color, notify) [ Language = javascript ]
{
	notify = (null==notify) ? false : notify;
	
	// update our hidden control:
	var ctrl = this.findElement('colorPicker');
	zenASSERT(ctrl,"Unable to find control.",arguments);
	
	if (this.disabled) {
		return;
	}

	var oldcolor = ctrl.value;
	ctrl.value = color;
	this.value = color;

	// update control
	var div;

	div = this.findElement('colorPicker'+'_'+oldcolor);
	if (div) {
		div.className = 'colorPickerCell';
	}

	div = this.findElement('colorPicker'+'_'+color);
	if (div) {
		div.className = 'colorPickerCellSelected';
	}

	// notify
	if (notify) {
		this.onchangeHandler();
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'colorList':
		this.colorList = value;
		this.refreshContents();
		break;
	case 'value':
		this.selectColor(value,false);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
