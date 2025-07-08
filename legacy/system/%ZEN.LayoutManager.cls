/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This utility class provides a centralized place for
/// the coded used to implement control layout on a page.
Class %ZEN.LayoutManager [ Abstract, Deprecated, Final, System = 3 ]
{

/// Default layout: simply display components with no wrapping table.
ClassMethod default(pGroup As %ZEN.Component.group, pTuple As %Integer = "")
{
	Set tCount = pGroup.children.Count()

	For n=1:1:tCount {
		Set tChild = pGroup.children.GetAt(n)
		Set:pTuple'="" tChild.tuple = pTuple
		Write:(tChild.showLabel) ..%Label(tChild)
		Write ..%ErrorMsg(tChild)

		Set tDivStyle = ""
		Set:tChild.height'="" tDivStyle=tDivStyle_"height:"_tChild.height_$S($IsValidNum(tChild.height):"px;",1:";")
		Set:tChild.width'="" tDivStyle=tDivStyle_"width:"_tChild.width_$S($IsValidNum(tChild.width):"px;",1:";")
		Do tChild.%DrawComponentHTML(tDivStyle)
		Write ..%Hint(tChild)
		Set:pTuple'="" tChild.tuple = ""
	}
}

/// Layout out components vertically.
ClassMethod vertical(pGroup As %ZEN.Component.group, pTuple As %Integer = "")
{
	#; use table for layout;
	#; if user has given this group a size, then the table is always 100% of enclosing space
	Set tTableStyle = $S(pGroup.width="":"",1:"width:100%;") _ $S(pGroup.height="":"",1:"height:100%;")_pGroup.groupStyle
	Write !
	&html<<table id="#(pGroup.%MakeId("group"))#" #(..%Attr("class",pGroup.groupClass))# #(..%Attr("style",tTableStyle))# #(..GetBorder(pGroup.index))# cellspacing="0" cellpadding="0">>

	Set tCellStyle = pGroup.cellStyle

	#; first pass: find total slice of cells & # of visible cells
	Set tVisibleCells = 0
	Set tCount = pGroup.children.Count()
	Set tSlice = 0
	For n=1:1:tCount {
		Set tChild = pGroup.children.GetAt(n)
		If (tChild.visible) {
			Set tSlice = tSlice + tChild.slice
			Set tVisibleCells = tVisibleCells + 1
		}
	}

	#; do we need slack rows
	Set slackTop=0,slackBottom=0,slackMiddle=0,slackRows=0
	If (pGroup.cellSize '= "stretch") {
		Set:(pGroup.cellVAlign="top") slackBottom=1,slackRows=1
		Set:(pGroup.cellVAlign="bottom") slackTop=1,slackRows=1
		Set:(pGroup.cellVAlign="even") slackMiddle=1,slackRows=tCount-1
		Set:(pGroup.cellVAlign="middle") slackTop=1,slackBottom=1,slackMiddle=1,slackRows=tCount+1
	}

	#; guess size of slack rows (assume each item is about 5% high)
	Set slackHeight = ""
	If (slackRows>0) {
		If ((slackRows=1) && (pGroup.cellSize="")) {
			Set slackHeight = $S(pGroup.height="":"10%",1:"99%")  // take up all slack
		}
		Else {
			Set slackHeight = 100 - (5 * tVisibleCells)
			Set:slackHeight<10 slackHeight = 10
			Set slackHeight = $FN((slackHeight / slackRows),"",0) _ "%"
		}
	}

	#; now layout cells
	If (slackTop) {
		Set tStyleTop = $S(slackHeight="":"",1:"height:"_slackHeight_$S($IsValidNum(slackHeight):"px;",1:";"))
		&html<<tr #(..%Attr("style",tStyleTop))#><td #(..%Attr("style",tCellStyle))#></td></tr>>
	}
	If (tCount = 0) {
		#; put *some* content here
		Write "<tr><td>&nbsp;</td></tr>"
	}
	For n=1:1:tCount {
		Set tChild = pGroup.children.GetAt(n)	
		If ('tChild.visible) {
			Continue
		}
		Set:pTuple'="" tChild.tuple = pTuple

		Set height=""
		Set width=""

		#; use cellAlign unless overridden by child
		Set align = $S(tChild.align'="":tChild.align,1:$Case(pGroup.cellAlign,"left":"left","right":"right","center":"center","even":"center",:""))
		Set align=tChild.align
		Set valign=tChild.valign
		
		#; do we need a cell height?
		If ((pGroup.cellSize = "stretch") || (pGroup.cellSize = "same")) {
			If ((pGroup.cellSize = "same")||(tSlice = 0)) {
				#; split evenly ("stretch" with no slice is same as "same")
				Set height = $FN((100 / tVisibleCells),"",0)_"%"
			}
			ElseIf (tChild.slice '= "") {
				Set height = $FN((tChild.slice / tSlice) * 100,"",0)_"%"
			}
		}
		Else {
			#; if height specified for component, use it
			Set:tChild.height'="" height=tChild.height
		}

		#; if width specified for component, use it for child div
		Set tDivStyle = ""
		Set:tChild.width'="" tDivStyle=tDivStyle_"width:"_tChild.width_$S($IsValidNum(tChild.width):"px;",1:";")
		If tChild.hidden Set tDivStyle = tDivStyle_"display: none;"

		Set tCellStyle2 = $S(tChild.containerStyle="":tCellStyle,1:tChild.containerStyle)

		Set align = $S(align="":"",1:" align="""_align_"""")
		Set valign = $S(valign="":"",1:"vertical-align:"_valign_";")
		Set width = $S(width="":"",1:"width:"_width_$S($IsValidNum(width):"px;",1:";"))
		Set height = $S(height="":"",1:"height:"_height_$S($IsValidNum(height):"px;",1:";"))

		Set tLblLoc = pGroup.labelPosition

		#; best default is to use valign top here
		&html<<tr style="vertical-align:top;">>
		Write:(tChild.showLabel)&&(tLblLoc="left") "<td id=""",tChild.%MakeId("zenLayoutLabelCell"),""" class=""vtLabelLeft"" nowrap=""1"" ",..%Attr("style",tCellStyle2_valign),">",..%Label(tChild),"</td>"
		&html<<td id="#(tChild.%MakeId("zenLayoutTableCell"))#"#($S(tChild.showLabel:"",1:" colspan=""2"""))# #(align)# #(..%Attr("style",tCellStyle2_valign_height_width))#>>
		Write:(tChild.showLabel)&&(tLblLoc="top") ..%Label(tChild)
		Write ..%ErrorMsg(tChild)
		Do tChild.%DrawComponentHTML(tDivStyle)
		Write ..%Hint(tChild)
		&html<</td>>
		&html<</tr>>

		If (slackMiddle && (n<tVisibleCells)) {
			Set tStyleMid = $S(slackHeight="":"",1:"height:"_slackHeight_$S($IsValidNum(slackHeight):"px;",1:";"))
			&html<<tr #(..%Attr("style",tStyleMid))#><td #(..%Attr("style",tCellStyle))#></td></tr>>
		}
		Set:pTuple'="" tChild.tuple = ""
	}

	Set:$zconvert($g(%request.CgiEnvs("HTTP_USER_AGENT")),"U")["EDGE" slackBottom=0 

	If (slackBottom) {
		Set tStyleBottom = $S(slackHeight="":"",1:"height:"_slackHeight_$S($IsValidNum(slackHeight):"px;",1:";"))
		&html<<tr #(..%Attr("style",tStyleBottom))#><td #(..%Attr("style",tCellStyle))#></td></tr>>
	}

	&html<</table>>
}

/// Layout out components horizontally.
ClassMethod horizontal(pGroup As %ZEN.Component.group, pTuple As %Integer = "")
{
	#; use table for layout;
	#; if user has given this group a size, then the table is always 100% of enclosing space
	Set tTableStyle = $S(pGroup.width="":"",1:"width:100%;") _ $S(pGroup.height="":"",1:"height:100%;")_pGroup.groupStyle
	Write !

	&html<<table id="#(pGroup.%MakeId("group"))#" #(..%Attr("class",pGroup.groupClass))# #(..%Attr("style",tTableStyle))# #(..GetBorder(pGroup.index))# cellspacing="0" cellpadding="0"><tr style="height:100%;">>

	Set tCellStyle = pGroup.cellStyle

	#; first pass: find total slice of cells & # of visible cells
	Set tVisibleCells = 0
	Set tCount = pGroup.children.Count()
	Set tSlice = 0
	For n=1:1:tCount {
		Set tChild = pGroup.children.GetAt(n)
		If (tChild.visible) {
			Set tSlice = tSlice + tChild.slice
			Set tVisibleCells = tVisibleCells + 1
		}
	}

	#; do we need slack columns
	Set slackLeft=0,slackRight=0,slackMiddle=0,slackCols=0
	If (pGroup.cellSize '= "stretch") {
		Set:(pGroup.cellAlign="left") slackRight=1,slackCols=1
		Set:(pGroup.cellAlign="right") slackLeft=1,slackCols=1
		Set:(pGroup.cellAlign="even") slackMiddle=1,slackCols=tCount-1
		Set:(pGroup.cellAlign="center") slackLeft=1,slackRight=1,slackMiddle=1,slackCols=tCount+1
	}

	#; guess size of slack columns (assume each item is about 2% wide)
	Set slackWidth = ""
	If (slackCols>0) {
		If ((slackCols=1) && (pGroup.cellSize="")) {
			Set slackWidth = "99%"  // take up all slack
		}
		Else {
			Set slackWidth = 100 - (2 * tVisibleCells)
			Set:slackWidth<10 slackWidth = 10
			Set slackWidth = $FN((slackWidth / slackCols),"",0) _ "%"
		}
	}

	#; now layout cells
	If (slackLeft) {
		Set tCellStyleLeft = tCellStyle _ $S(slackWidth="":"",1:"width:"_slackWidth_$S($IsValidNum(slackWidth):"px;",1:";"))
		&html<<td #(..%Attr("style",tCellStyleLeft))#>&nbsp;</td>>
	}
	If (tCount = 0) {
		#; put *some* content here
		Write "<td>&nbsp;</td>"
	}
	Set tWidths = ""
	For n=1:1:tCount {
		Set tChild = pGroup.children.GetAt(n)
		If ('tChild.visible) {
			Continue
		}
		Set:pTuple'="" tChild.tuple = pTuple

		Set height = ""
		Set width = ""
		#; use cellVAlign unless overridden by child
		Set valign = $S(tChild.valign'="":tChild.valign,1:$Case(pGroup.cellVAlign,"top":"top","bottom":"bottom","middle":"middle","even":"middle",:""))
 		Set align = tChild.align
	
		#; do we need a cell width?
		If ((pGroup.cellSize = "stretch") || (pGroup.cellSize = "same")) {
			If ((pGroup.cellSize = "same")||(tSlice = 0)) {
				#; split evenly ("stretch" with no slice is same as "same")
				Set width = $FN((100 / tVisibleCells),"",0)_"%"
			}
			ElseIf (tChild.slice '= "") {
				Set width = $FN((tChild.slice / tSlice) * 100,"",0)_"%"
			}
		}
		Else {
			#; if width specified for component, use it
			Set:tChild.width'="" width=tChild.width
		}

		#; if height specified for component, use it for child div
		Set tDivStyle = ""
		Set:tChild.height'="" tDivStyle=tDivStyle_"height:"_tChild.height_$S($IsValidNum(tChild.height):"px;",1:";")
		Set tHiddenStyle = $select(tChild.hidden: "display: none;", 1: "")

		Set tCellStyle2 = $S(tChild.containerStyle="":tCellStyle,1:tChild.containerStyle)

		Set align = $S(align="":"",1:" align="""_align_"""")
		Set valign = $S(valign="":"",1:"vertical-align:"_valign_";")
		Set width = $S(width="":"",1:"width:"_width_$S($IsValidNum(width):"px;",1:";"))
		Set height = $S(height="":"",1:"height:"_height_$S($IsValidNum(height):"px;",1:";"))

		Set tLblLoc = pGroup.labelPosition

		Write:(tChild.showLabel)&&(tLblLoc="left")&&(tChild.label'="") "<td id=""",tChild.%MakeId("zenLayoutLabelCell"),""" class=""hzLabelLeft"" nowrap=""1"" ",..%Attr("style",valign_tHiddenStyle),">",..%Label(tChild),"</td>"
		&html<<td id="#(tChild.%MakeId("zenLayoutTableCell"))#" #(align)# #(..%Attr("style",tCellStyle2_valign_height_width_tHiddenStyle))#>>
		Write:(tChild.showLabel)&&(tLblLoc="top") ..%Label(tChild)
		Write ..%ErrorMsg(tChild)
		#; width of component should be *this* cell
		Do tChild.%DrawComponentHTML(tDivStyle)
		Write ..%Hint(tChild)
		&html<</td>>

		If (slackMiddle && (n<tCount)) {
			Set tCellStyleMid = tCellStyle _ $S(slackWidth="":"",1:"width:"_slackWidth_$S($IsValidNum(slackWidth):"px;",1:";"))
			&html<<td #(..%Attr("style",tCellStyleMid))#>&nbsp;</td>>
		}
		Set:pTuple'="" tChild.tuple = ""
	}

	If (slackRight) {
		Set tCellStyleRight = tCellStyle _ $S(slackWidth="":"",1:"width:"_slackWidth_$S($IsValidNum(slackWidth):"px;",1:";"))
		&html<<td #(..%Attr("style",tCellStyleRight))#>&nbsp;</td>>
	}
	&html<</tr></table>>
}

/// Get border attribute for layout tables
ClassMethod GetBorder(pIndex As %Integer) As %String [ CodeMode = expression ]
{
"border=""0"""
}

/// Return HTML fragment to show visible borders. 
/// Deprecated.
ClassMethod GetDebugBorder(pIndex As %Integer) As %String [ Deprecated, Private ]
{
	#; find unique color for each group
	Set bg = "#"_$J($ZHEX(((pIndex*113)#127)+128),2)_$J($ZHEX(((pIndex*7)#127)+128),2)_$J($ZHEX(((pIndex*17)#127)+128),2)
	Set bg = $TR(bg," ",0)
	Quit "border=""1"" style=""background: "_bg_";"""
}

/// Utility method used when writing out HTML attribute values.
/// Given an attribute name and value, this returns the string
/// attr=""value"" with value HTML escaped. If value is "", then ""
/// is returned.<br>
ClassMethod %Attr(pName As %String, pValue As %String) As %String [ CodeMode = expression ]
{
$S(pValue="":"",1:pName_"="""_$ZCVT(pValue,"O","HTML")_"""")
}

/// Return label for component
ClassMethod %Label(tChild As %ZEN.Component.component) As %String [ CodeMode = expression ]
{
$S(tChild.label="":"",1:"<span id=""zenlbl_"_tChild.index_""" "_..%Attr("class",tChild.labelClass)_" "_..%Attr("style",tChild.labelStyle_$S(..%ZENVAL(tChild,tChild.hidden):"display:none;",1:""))_" "_..%Attr("title",tChild.title)_">"_$ZCVT(..%ZENVAL(tChild,tChild.label),"O","HTML")_"</span>")
}

/// Return hint text for component
ClassMethod %Hint(tChild As %ZEN.Component.component) As %String [ CodeMode = expression ]
{
$S(tChild.hint="":"",1:"<div id=""zenhint_"_tChild.index_""" "_..%Attr("class",tChild.hintClass)_" "_..%Attr("style",tChild.hintStyle_$S(..%ZENVAL(tChild,tChild.hidden):"display:none;",1:""))_">"_$ZCVT(..%ZENVAL(tChild,tChild.hint),"O","HTML")_"</div>")
}

/// Return error message for component
ClassMethod %ErrorMsg(tChild As %ZEN.Component.component) As %String [ CodeMode = expression ]
{
$S(tChild.error="":"",1:"<span class=""zenError"">"_$ZCVT(tChild.error,"O","HTML")_"</span>")
}

/// Replacement for $$$ZENVAL macro when used outside of the context of a component OREF.
ClassMethod %ZENVAL(pObj As %ZEN.Component.object, pExpr As %String, pEscape As %String = "") As %String [ CodeMode = expression, Internal ]
{
$S(pExpr'["#(":pExpr,1:pObj.%Eval(pExpr))
}

}
