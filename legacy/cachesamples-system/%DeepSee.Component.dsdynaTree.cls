/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.Component.dsdynaTree Extends %ZEN.Component.dynaTree [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Draw HTML to display a given node in the tree graph.
/// <var>pState</var> contains state info for each level of the tree:
/// 0 no siblings; 1 prev sibling only; 2 both siblings; 3 next sibling only.
Method %DrawNode(ByRef pTree, pNode As %Integer, pOffset As %Integer, pLevel As %Integer, ByRef pState, pParentNode As %Integer) [ Internal ]
{
	Set tDir = ..%GetImageDirectory()
	Set tHasChildren = ''($D(pTree(pNode,"ch")))

	Set tNodeNo = pNode - 1 + pOffset // node # is 0-based
	Set tData = $G(pTree(pNode))

	#; Do not build empty node
	If tData = "" Quit

	Set tText = $ZCVT($LG(tData,1),"O","HTML")
	Set tValue = $ZCVT($LG(tData,2),"O","HTML")
	Set tChildFlag = +$LG(tData,3)
	Set tLink = $LG(tData,4)
	Set tExpanded = +$LG(tData,5)
	Set tUserIcon = $LG(tData,6)
	
	//Set tTooltip = $LG(tData,7)
	Set tTooltip = $ZCVT($LG(tData,7),"O","HTML")		// DTB805
	
	Set tStyle = $LG(tData,8)
	Set:(tChildFlag&&'tHasChildren) tExpanded = 0 // override

	Set tNodeCls = $S(..showLines:"dynaTreeNodeLines",1:"dynaTreeNode")
	&html<<div class="#(tNodeCls)#">>

	#; indent lines
	Set tStateList = ""
	If (..showLines) {
		For i = 1:1:pLevel-1 {
			Set wid = 16
			Set src = tDir _ $Case($G(pState(i),0),0:"spacer.gif",1:"spacer.gif",2:"line-ns.gif",3:"line-ns.gif")
			&html<<img src="#(src)#" align="middle" border="0" width="#(wid)#" height="#(wid)#" style="vertical-align:top;"/>>
			Set tStateList = tStateList _ $S(tStateList'="":",",1:"") _ $G(pState(i),0)
		}
		Set tStateList = tStateList _ $S(tStateList'="":",",1:"") _ $G(pState(pLevel),0)
	}
	Else {
		&html<<img src="#(tDir_"spacer.gif")#" width="#((pLevel-1)*(..childIndent))#" height="1"/>>
	}

	Set tLoad = ""
	Set tIconStyle = ""
	Set hgt = 16
	If (tChildFlag) {
		Set wid = 16
		Set imgCls = "class=""dynaTreeExp"""
		If (tExpanded) {
			If (..showLines) {
				Set src = tDir _ $Case($G(pState(pLevel),0),0:"minus-e.gif",1:"minus-ne.gif",2:"minus-nse.gif",3:$S(pLevel=1:"minus-se.gif",1:"minus-nse.gif"))
			}
			Else {
				Set wid = ""
				Set hgt = ""
				Set tIconStyle = "padding-right: 2px;"
				Set src = ..imageExpanded
			}
			Set nodeIcon = $S(..showLines||..showFolders:..imageFolderOpen,1:"")
		}
		Else {
			If (..showLines) {
				Set src = tDir _ $Case($G(pState(pLevel),0),0:"plus-e.gif",1:"plus-ne.gif",2:"plus-nse.gif",3:$S(pLevel=1:"plus-se.gif",1:"plus-nse.gif"))
			}
			Else {
				Set wid = ""
				Set hgt = ""
				Set tIconStyle = "padding-right: 2px;"
				Set src = ..imageContracted
			}
			Set nodeIcon = $S(..showLines||..showFolders:..imageFolderClosed,1:"")
		}
		Set imgId = "id="""_..%MakeId("image_"_tNodeNo)_""""
		If (tChildFlag&&'tHasChildren) {
			#; onclick will load the components of this node
			Set tLoad = "zenLoad=""1"""
		}
		Set onclick = "onclick=""return zenPage.getComponent("_..index_").toggleExpanded("_tNodeNo_");"""
		Set iconClick = "onclick=""return zenPage.getComponent("_..index_").toggleExpanded("_tNodeNo_");"""
	}
	Else {
		Set imgCls = ""
		If (..showLines) {
			Set wid = 16
			Set src = tDir _ $Case($G(pState(pLevel),0),0:"line-ne.gif",1:"line-ne.gif",2:"line-nse.gif",3:"line-nse.gif")
		}
		Else {
			Set wid = ""
			Set hgt = "1"
			Set src = ""
		}
		Set imgId = ""
		Set onclick = ""
		Set nodeIcon = ..imageNode
		Set iconClick = "onclick=""zenPage.getComponent("_..index_").itemClicked("_tNodeNo_","_(pLevel-1)_");"""
	}

	#; draw node
	Set tEvent = ""
	Set iconId = ..%MakeId("icon_"_tNodeNo)

	If (tLink = "") {
		Set tHREF = "#"
		Set tEvent = " onclick=""zenPage.getComponent("_..index_").itemClicked("_tNodeNo_","_(pLevel-1)_"); return false;"""
	}
	Else {
		Set tHREF = %page.%Link(tLink)
		#; make sure we also pick up onclick
		Set tEvent = " onclick=""return zenPage.getComponent("_..index_").itemClicked("_tNodeNo_","_(pLevel-1)_");"""
	}

	If (tUserIcon'="") {
		Set nodeIcon = tUserIcon
		Set iconId = "" // don't let user icons open and close
	}
	Set tTitle = ""
	If (tTooltip '= "") {
		// DTB138 - Descriptions in DeepSee can contain html that is interpreted in the documatic. 
		// For the tooltip, remove the html tags. Do not run $ZCVT and keep the escaped characters, 
		// so they are converted to the human-readable characters
	    While (tTooltip["<") { 
	        Quit:$P(tTooltip,"<",2)'[">" 
	        Set tTooltip=$P(tTooltip,"<")_$P(tTooltip,">",2,*) 
	    } 
	    
		Set tTitle = "title="""_tTooltip_""""
	}

	#; if we support drag & drop we need additional mouse event handling
	Set tMouseEvents = ""
	If (%page.dragAndDrop) {
		Set tMouseEvents = " onmousedown=""zenPage.getComponent("_..index_").itemMouseDown(event,"_tNodeNo_");""" _ 
							" onmouseup=""zenPage.getComponent("_..index_").itemMouseUp(event);"""
	}

	#; (expando | line) + icon + node
	If (src '= "") {
		Set iwid = $S(wid="":"",1:"width="""_wid_"""")
		Set ihgt = $S(hgt="":"",1:"height="""_hgt_"""")
		&html<<img src="#(src)#" #(imgCls)# align="middle" border="0" #(iwid)# #(ihgt)# style="vertical-align:top;#(tIconStyle)#" #(imgId)# #(onclick)#/><span>>
		if (nodeIcon '="") {
			&html<<img id="#(iconId)#" class="dynaTreeIcon" align="middle" border="0" height="16" width="16" src="#(nodeIcon)#" #(iconClick)# style="vertical-align:top;"/>>
		}
	}
	Else {
		&html<<span>>
		if (nodeIcon '="") {
			&html<<img id="#(iconId)#" class="dynaTreeIcon" align="middle" border="0" src="#(nodeIcon)#" width="16" #(iconClick)# style="vertical-align:top;"/>>
		}
	}
	&html<<a class="dynaTreeItem" id="#(..%MakeId("a_"_tNodeNo))#" #(tLoad)# #(tMouseEvents)# zenState="#(tStateList)#" zenLevel="#(pLevel)#" zenParent="#(pParentNode-1)#" zenText="#(tText)#" zenValue="#(tValue)#" href="#(tHREF)#" ondblclick="return zenPage.getComponent(#(..index)#).itemDblClicked(#(tNodeNo)#,#(pLevel-1)#);" onkeypress="zenPage.getComponent(#(..index)#).itemKeyPress(event,#(tNodeNo)#,#($S(tHasChildren:"true",1:"false"))#);"#(tEvent)# #(tTitle)# style="#(tStyle)#">#(tText)#&nbsp;</a></span></div>>

	#; wrap subnodes in div
	If (tChildFlag) {
		Set style = $S(tExpanded:"",1:"style=""display: none;""")
		&html<<div id="#(..%MakeId("exp_"_tNodeNo))#" #(style)#>>

		If (tHasChildren) {  // children exist
			#; loop over children of this node
			Set tFirst = 1
			Set tNode = $O(pTree(pNode,"ch",""))
			While (tNode '= "") {
				If (tFirst) {
					Set tFirst = 0
					Set pState(pLevel+1) = $S($O(pTree(pNode,"ch",tNode))="":0,1:3)
				}
				Else {
					Set pState(pLevel+1) = $S($O(pTree(pNode,"ch",tNode))="":1,1:2)
				}
				Set ..nodeCount =..nodeCount + 1
				Do ..%DrawNode(.pTree,tNode,pOffset, pLevel+1,.pState,pNode)
				Set tNode = $O(pTree(pNode,"ch",tNode))
			}
		}
		&html<</div>>
	}
}

}
