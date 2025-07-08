/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility methods for "available-selected" list box components
/// If isPage = 1, the list boxes are drawn on a page, not as part of a component
Class %CSP.UI.Component.SelectBoxUtils [ Abstract, System = 3 ]
{

Parameter DOMAIN [ Internal ] = "%Utility";

Parameter avaList = "avaList";

Parameter selList = "selList";

Property avaList As %String [ InitialExpression = {..#avaList} ];

Property selList As %String [ InitialExpression = {..#selList} ];

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
.arrowButton {
	cursor:pointer;
	margin:5px 0;
}
</style>
}

ClientMethod doSelectBoxMove(flag, isPage) [ Language = javascript ]
{
	if (isPage == 1) {
		var avaList = document.getElementById(this.avaList);
		var selList = document.getElementById(this.selList);
	} else {
		var avaList = this.findElement(this.avaList);
		var selList = this.findElement(this.selList);
	}
	switch (flag) {
		case "selectOne":
			this.doSelectBoxMoveList(avaList,selList);
			break;
		case "deselectOne":
			this.doSelectBoxMoveList(selList,avaList);
			break;
		case "selectAll":
			this.doSelectBoxMoveAll(avaList,selList);
			break;
		case "deselectAll":
			this.doSelectBoxMoveAll(selList,avaList);
			break;
		case "moveUp":
			this.doSelectBoxMoveItem(selList,true);
			break;
		case "moveDown":
			this.doSelectBoxMoveItem(selList,false);
			break;
	}
	if (this.onSelectBoxMove) {
		ok = this.onSelectBoxMove(flag, isPage);
	}
}

ClientMethod doSelectBoxMoveList(from, to) [ Language = javascript ]
{
	// move one or multiple selected items from one box to another
	var len = from.options.length;
	var o;
	for(var i=0;i<len;i++) {
		o = from.options[i];
		if (o.selected) {
			if (o.value != "_") {
				to.options[to.options.length] = new Option(o.text,o.value,false,true);
			}
		}
	}
	for(var i=len-1;i>=0;i--) {
		o = from.options[i];
		if (o.selected) {
			if (o.value != "_") {
				from.options[i] = null;
			}
		}
	}
	from.selectedIndex = from.options.length > 1 ? 1 : -1
}

ClientMethod doSelectBoxMoveAll(from, to) [ Language = javascript ]
{
	// move all from From list to To list
	var len = from.options.length;
	for(var i=0;i<len;i++) {
		var o = from.options[i];
		// skip width dummy - new Option(text,value,[defaultSelected],[selected])
		if (o.value != "_") to.options[to.options.length] =  new Option(o.text,o.value,false,true);
	}
	// set From list to null
	var len = len - 1;
	for(var i=len;i>=0;i--) {
		var o = from.options[i];
		if (o.value != "_") from.options[i] = null;
	}
	// set the default to the to's last
	to.selectedIndex = to.options.length-1;
	to.focus;
}

ClientMethod doSelectBoxMoveItem(list, bUp) [ Language = javascript ]
{
	var currentIdx = list.selectedIndex;
	if (currentIdx == -1) return false;
	if (list.options[currentIdx].value == "_") return false;
	var newIdx = bUp ? currentIdx - 1 : currentIdx + 1;
	if (newIdx < 1 || newIdx > (list.options.length - 1) ) return false;
	var sSwap = list[newIdx].value;
	var sSwapText = list[newIdx].text;
	var sTarget = list[currentIdx].value;
	var sTargetText = list[currentIdx].text;
	list[newIdx].value = sTarget;
	list[newIdx].text = sTargetText;
	list[currentIdx].value = sSwap;
	list[currentIdx].text = sSwapText;
	list.selectedIndex = newIdx;
	return false;
}

/// Clear all options from a box (except for the first, instructional one)
ClientMethod clearList(listID, isPage) [ Language = javascript ]
{
	if (isPage == 1) {
		var list = document.getElementById(listID);
	} else {
		var list = this.findElement(listID);
	}
	for (var i=list.options.length-1;i>=1;i--) {
		list.remove(i);
	}
}

/// Return a delimited string of selected items
ClientMethod getSelList(delim, includeLeadingDelim, isPage) [ Language = javascript ]
{
	if (isPage == 1) {
		var selList = document.getElementById(this.selList);
	} else {
		var selList = this.findElement(this.selList);
	}
	var returnList = ""
	for (var i = 1; i < selList.length; i++) {
		if (includeLeadingDelim || (returnList != "")) returnList = returnList + delim;
		returnList = returnList + selList.options[i].value;
	}
	return returnList;
}

/// Draw the beginning of the Available list box
Method DrawAvailableList(index As %String = "", isPage As %Boolean = 0) As %Status
{
	If isPage {
		Set ID = ..#avaList
		Set scope = "zenPage"
	} Else {
		Set ID = ..%MakeId(..#avaList)
		Set scope = "zenPage.getComponent('"_index_"')"
	}
	&html<<table width="100%" border="0" cellpadding="2" cellspacing="2">>
	&html<
		<tr>
			<th class="zenLabel">#($$$TextHTML("Available"))#</th>
			<th>&nbsp;</th>
			<th class="zenLabel">#($$$TextHTML("Selected"))#</th>
			<th>&nbsp;</th>
		</tr>
		<tr>
	  		<td align="center">
	  			<select id=#(ID)# size="30" multiple ondblclick="#(scope)#.doSelectBoxMove('selectOne',#(isPage)#);">
	  				<option value="_">#($$$TextHTML(" ----- Select One or More ----- "))#</option>>
	  Quit $$$OK
}

/// Draw the end of the Available list box, the arrows, and the Selected list box
Method DrawSelectList(index As %String = "", isPage As %Boolean = 0, SelectedItems As %String = "") As %Status
{
	If isPage {
		Set ID = ..#selList
		Set scope = "zenPage"
	} Else {
		Set ID = ..%MakeId(..#selList)
		Set scope = "zenPage.getComponent('"_index_"')"
	}
	
	&html<</select></td>>
	
	Set tSC = ..DrawArrows($G(index),isPage)
	If $$$ISERR(tSC) Quit tSC
	
	&html<
		<td align="center">
			<select id=#(ID)# size="30" multiple ondblclick="#(scope)#.doSelectBoxMove('deselectOne',#(isPage)#);">
			<option value="_">#($$$TextHTML(" ----- Select One or More ----- "))#</option>>
	If (SelectedItems '= "") {
		For i=1:1:$LENGTH(SelectedItems,",") {
			Set item = $PIECE(SelectedItems,",",i)
			&html<<option value="#(i)#">#($ZCVT(item,"O","HTML"))#</option>>
		}
	}	
	&html<
			</select>
		</td>>
		
	If isPage {
		&html<</tr></table>>
	}
	Quit $$$OK
}

/// Draw arrows between Available and Selected list boxes.
ClassMethod DrawArrows(index As %String = "", isPage As %Boolean = 0) As %Status
{
	If isPage {
		Set scope = "zenPage"
	} Else {
		Set scope = "zenPage.getComponent('"_index_"')"
	}
	
	Set lbl1 = $$$TextHTML("select")
	Set lbl2 = $$$TextHTML("deselect")
	Set lbl3 = $$$TextHTML("select all")
	Set lbl4 = $$$TextHTML("deselect all")
	&html<
		<td align="center">
			<div class="arrowButton"><img onclick="#(scope)#.doSelectBoxMove('selectOne',#(isPage)#);" title="#(lbl1)#" src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_right.gif"))#" alt="select one" width="24" height="24" border="0"></div>
			<div class="arrowButton"><img onclick="#(scope)#.doSelectBoxMove('deselectOne',#(isPage)#);" title="#(lbl2)#" src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_left.gif"))#" alt="select one" width="24" height="24" border="0"></div>
			<div class="arrowButton"><img onclick="#(scope)#.doSelectBoxMove('selectAll',#(isPage)#);" title="#(lbl3)#" src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_right2.gif"))#" alt="select all" width="24" height="24" border="0"></div>
			<div class="arrowButton"><img onclick="#(scope)#.doSelectBoxMove('deselectAll',#(isPage)#);" title="#(lbl4)#" src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_left2.gif"))#" alt="deselect all" width="24" height="24" border="0"></div>
		</td>>
	Quit $$$OK
}

/// Draw arrows between Available and Selected list boxes.
/// Generic method used by other wizards
ClassMethod DrawArrowsOld()
{
	Set SpaceImage = ##class(%CSP.Page).Link("/csp/sys/images/spacer.gif")
	Set lbl1 = $$$Text("select one","%Utility")
	Set lbl2 = $$$Text("deselect","%Utility")
	Set lbl3 = $$$Text("select all","%Utility")
	Set lbl4 = $$$Text("deselect all","%Utility")
	&html<
		<td>
			<br><a href="javascript:move('selectone');" title="#(lbl1)#"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_right.gif"))#" alt="select one" width="24" height="24" border="0"></a><img src="#(SpaceImage)#" width="1" height="2"></div>
			<div><a href="javascript:move('deselectone');" title="#(lbl2)#"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_left.gif"))#" alt="select one" width="24" height="24" border="0"></a><img src="#(SpaceImage)#" width="1" height="2"></div>
			<div><a href="javascript:move('selectall');" title="#(lbl3)#"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_right2.gif"))#" alt="select all" width="24" height="24" border="0"></a><img src="#(SpaceImage)#" width="1" height="2"></div>
			<div><a href="javascript:move('deselectall');" title="#(lbl4)#"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_left2.gif"))#" alt="deselect all" width="24" height="24" border="0"></a> 
		</td>>
}

/// Draw up and down arraws next to the Selected list box
/// Generic method used by other wizards
ClassMethod DrawUpArrowsOld()
{
	&html<
	  	<div><a href="javascript:move('moveup');"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_up.gif"))#" alt="move item up" width="24" height="24" border="0"></a><img src="#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#" width="1" height="2"></div>
	  	<div><a href="javascript:move('movedown');"><img src="#(##class(%CSP.Page).Link("/csp/sys/images/arrow_down.gif"))#" alt="move item down" width="24" height="24" border="0"></a></div>>
}

}
