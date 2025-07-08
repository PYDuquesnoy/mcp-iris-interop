/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component is used to insert space between other components.
Class %ZEN.Component.spacer Extends component [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "core";

XData Style
{
<style type="text/css">
.spacer {
	font-size: 1px;
	line-height: 0px;
	border: 0px;
	margin: 0px;
	padding: 0px;
}

</style>
}

Method %DrawHTML()
{
	#; calculate which size to use
	Set tHeight = ""
	Set tWidth = ""
	Set tShow = 0

	If ((..height'="")&&(..width'="")) {
		Set tShow = 1, tWidth = ..width, tHeight = ..height
	}
	ElseIf ((..height'="")&&(..width="")) {
		Set tShow = 1, tHeight = ..height
	}
	ElseIf ((..height="")&&(..width'="")) {
		Set tShow = 1, tWidth = ..width
	}

	If (tShow) {
		#; construct style; use px if no units supplied
		Set tStyle = ""
		#; test for * (special case in conjunction with group layout)
		Set:tWidth="*" tWidth="1px"
		Set:tHeight="*" tHeight="1px"
		Set:tWidth'="" tStyle = tStyle_"width:"_tWidth_$S($IsValidNum(tWidth):"px;",1:";")
		Set:tHeight'="" tStyle = tStyle_"height:"_tHeight_$S($IsValidNum(tHeight):"px;",1:";")
		&html<<div class="spacer" id="#(..%MakeId("spacer"))#" style="#(tStyle)#"></div>>
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'height':
	case 'width':
		var el = this.findElement('spacer');
		this[property] = value;
		if (el) {
			value = ('*' == value) ? '100%' : value;
			if (zenIsHTML5 && (value == ('' + parseFloat(value)))) value += 'px';
			if ('height'==property) {
				el.style.height = value;
			}
			else {
				el.style.width = value;
			}
		}
		else {
			if (this.getEnclosingDiv()) {
				this.refreshContents();
			}
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
