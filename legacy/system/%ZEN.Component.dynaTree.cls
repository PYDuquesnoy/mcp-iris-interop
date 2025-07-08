/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component draws an HTML tree control based on executing
/// a user-provided callback method.<br/>
/// There are several ways that you can provide data for the tree control:
/// <ul>
/// <li>Using the <property>OnGetNodeInfo</property> callback to get data for each node within the tree.</li>
/// <li>Using the <property>dataGlobal</property> property to use data stored within a global to supply the contents of the tree.</li>
/// <li>Using the <property>OnGetTreeInfo</property> callback to fill in a local array that supplies the contents of the tree.</li>
/// </ul>
Class %ZEN.Component.dynaTree Extends component [ Deprecated, System = 3 ]
{

/// Default url of image used for expanded tree node.
/// This is only used when <property>showLines</property> is false.
Parameter IMAGEEXPANDED;

/// Default url of image used for contracted tree node.
/// This is only used when <property>showLines</property> is false.
Parameter IMAGECONTRACTED;

/// Default url of image used for open folder nodes.
Parameter IMAGEFOLDEROPEN = "folderopen.gif";

/// Default url of image used for closed folder nodes.
Parameter IMAGEFOLDERCLOSED = "folderclosed.gif";

/// Default url of image used for a leaf node in the tree.
Parameter IMAGENODE = "node.gif";

/// Index (0-based) of current selected tree node.<br>
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Specifies amount child nodes should be indented.
/// This value is only applied when <property>showLines</property> is false.
Property childIndent As %ZEN.Datatype.length [ InitialExpression = 20 ];

/// url of image used for expanded tree nodes (when <property>showLines</property> is false).<br/>
/// If you set this, make sure you also set <property>imageContracted</property>.
Property imageExpanded As %ZEN.Datatype.uri;

/// url of image used for contracted tree node (when <property>showLines</property> is false).<br/>
Property imageContracted As %ZEN.Datatype.uri;

/// url of image used for an open folder node in the tree.<br/>
/// If not specified, a default image is supplied.
Property imageFolderOpen As %ZEN.Datatype.uri;

/// url of image used for a closed folder node in the tree.<br/>
/// If not specified, a default image is supplied.
Property imageFolderClosed As %ZEN.Datatype.uri;

/// url of image used for a leaf node in the tree.<br/>
/// If not specified, a default image is supplied.
Property imageNode As %ZEN.Datatype.uri;

/// If true, show dashed lines (as a series of images) between
/// the nodes of the tree.
Property showLines As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true and <property>showLines</property> is false, display open and closed folder icons as well as icons for
/// each node in the tree. The default is true.<br/>
/// If <property>showLines</property> is true, this property is ignored.
Property showFolders As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// onclick event handler:
/// If defined, this event is fired when
/// the user clicks on an item
Property onclick As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// If defined, this event is fired when
/// the user double-clicks on an item
Property ondblclick As %ZEN.Datatype.eventHandler;

/// onchange event handler:
/// If defined, this event is fired when
/// the user changes the value of this component.
Property onchange As %ZEN.Datatype.eventHandler;

/// Text (display) value of current item within the view.
/// Do not access this directly; use getProperty('text') instead.
Property text As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Logical value of current item within the view.
/// Do not access this directly; use getProperty('value') instead.
Property value As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// User-defined set of parameters. These values are passed on
/// to the user callback function that provides the contents of 
/// this view. Typically this is used to hold search parameters.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// This is used to keep track of how many nodes are in this tree.
Property nodeCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// Name of Server-side callback method to call to get information
/// for each node of this tree.<br>
/// This must be the name of a server-only method in the page
/// class that contains this component.
Property OnGetNodeInfo As %ZEN.Datatype.delegator(FORMALSPEC = "*tSC:%Status,&tParameters:%String,pLevel:%Integer,&pHandle:%String,pNodeInfo:%ZEN.Auxiliary.NodeInfo", RETURNTYPE = "%Boolean");

/// Name of Server-side callback method to call to get information
/// for the entire contents of the tree.<br>
/// This is a lower-level callback than the <property>OnGetNodeInfo</property>
/// callback. It lets you define the contents of the entire tree using 
/// a multi-dimensional array.<br/>
/// If this is defined then the <property>OnGetNodeInfo</property> callback is not used.<br>
/// This must be the name of a server-only method in the page
/// class that contains this component.<br/>
/// The callback method should be similar to this:
/// <example language="CLS!MEMBER">
/// ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
/// {
/// 	#; top-most nodes are children of 0
/// 	Set pTree(0,"ch",1) = ""
/// 	Set pTree(0,"ch",2) = ""
/// 	Set pTree(0,"ch",3) = ""
/// 
/// 	#; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
/// 	Set pTree(1) = $LB("Animal",1,1,"",1)
/// 	Set pTree(2) = $LB("Mineral",2,1,"",1)
/// 	Set pTree(3) = $LB("Vegetable",3,1,"",1)
/// 
/// 	#; child nodes are placed under "ch"
/// 	Set pTree(1,"ch",4) = ""
/// 
/// 	Set pTree(4) = $LB("Cow",4,0,"",1)
/// 	Quit $$$OK
/// }
/// </example>
Property OnGetTreeInfo As %ZEN.Datatype.delegator(FORMALSPEC = "pRoot:%String,*pTree:%List,&tParameters:%String", RETURNTYPE = "%Status");

/// If defined, and there is no user-defined <method>OnGetNodeInfo</method>
/// callback method, then this is the name of a global that is
/// used to provide the contents of this tree.<br>
/// The global takes the form:<br>
/// ^glvn("A","B") = URL<br>
/// The global subscripts define the node names; The URL value
/// is a link that is used when the user clicks on the node.
Property dataGlobal As %ZEN.Datatype.glvn;

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

/* @doc="div for node in tree." */
.dynaTreeNode {
	white-space: nowrap;
	font-size: 12px;
	font-family: Arial,Helvetica,sans-serif;
	margin: 0px;
	padding: 1px;
	text-decoration: none;
}

/* @doc="div for node in tree when showLines is true." */
.dynaTreeNodeLines {
	white-space: nowrap;
	vertical-align: middle;
	font-size: 12px;
	height: 16px;
	overflow: visible;
	font-family: Arial,Helvetica,sans-serif;
	margin: 0px;
	padding: 0px;
}

/* @doc="expando image for node in tree." */
.dynaTreeExp {
	cursor: pointer;
}

/* @doc="icon image for node in tree." */
.dynaTreeIcon {
	cursor: pointer;
}

/* @doc="Caption for node (a) in tree." */
a.dynaTreeItem {
	color: darkblue;
	text-decoration: none;
	white-space: nowrap;
	vertical-align: middle;
	cursor: pointer;
	padding: 1px;
}

/* @doc="Current selected node (a) in tree." */
a.dynaTreeItemSelected {
	color: black;
	font-weight: bold;
	background: #D0D0F0;
	border: 1px dotted darkblue;
	padding: 0px;
	text-decoration: none;
	white-space: nowrap;
	vertical-align: middle;
	cursor: pointer;
}

.dynaTreeNode img, .dynaTreeNodeLines img {
	border: none;
}

a.dynaTreeItem:hover {
	color: black;
	background: #FFFAE7;
	border: 1px dotted gray;
	padding: 0px;
}
a.dynaTreeItem:active {
	text-decoration: none;
}
.dynaTreeItem:focus {
	color: white;
	background: darkblue;
}

</style>
}

/// Return the directory from which built-in images are supplied.
ClassMethod %GetImageDirectory() As %String [ CodeMode = expression ]
{
"images/"
}

/// Draw HTML for this component.
Method %DrawHTML()
{
	Set ..nodeCount = 0
	
	#; set up links for images
	Set tDir = ..%GetImageDirectory()
	Set:(..imageNode="")&&(..#IMAGENODE'="") ..imageNode = tDir _ ..#IMAGENODE
	Set:(..imageExpanded="")&&(..#IMAGEEXPANDED'="") ..imageExpanded = tDir _ ..#IMAGEEXPANDED
	Set:(..imageContracted="")&&(..#IMAGECONTRACTED'="") ..imageContracted = tDir _ ..#IMAGECONTRACTED
	Set:(..imageFolderOpen="")&&(..#IMAGEFOLDEROPEN'="") ..imageFolderOpen = tDir _ ..#IMAGEFOLDEROPEN
	Set:(..imageFolderClosed="")&&(..#IMAGEFOLDERCLOSED'="") ..imageFolderClosed = tDir _ ..#IMAGEFOLDERCLOSED

	#; get info
	Set tSC = ..%BuildTreeData(.tTree)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		Quit
	}
	#; draw the tree
	Do ..%DrawTree(.tTree)
}

/// Construct an array that describes the contents of the tree.
/// This is a graph of the form:<br/>
/// pTree(n) = $LB(text,value,haschildren,link,expanded,icon,tooltip,style)<br/>
/// pTree(n,"ch",childn) = ""<br/>
/// Top-most nodes are in:<br/>
/// pTree(0,"ch",topchildn) = ""<br/>
Method %BuildTreeData(ByRef pTree) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $$$ZENVAL(value)
			Set key = ..parameters.Next(key)
		}

		#; test for callback
		If (..OnGetTreeInfo '= "") {
			Set tSC = ..%GetTreeInfo("",.pTree,.tParms)
			Quit
		}

		#; init handle and other vars
		Set tHandle = ""
		Set tNodeNo = 1
		Set tLevel = 1

		#; gather tree info; call user callback to get nodes for the tree
		#; create NodeInfo object used by callback
		Set tNodeInfo = ##class(%ZEN.Auxiliary.NodeInfo).%New()

		#; stack of parent node #s
		Set tParent(1) = 0

		While (tLevel>0) {
			#; reset node info and invoke callback
			Set tNodeInfo.text = ""
			Set tNodeInfo.value = ""
			Set tNodeInfo.expanded = 0
			Set tNodeInfo.hasChildren = 0
			Set tNodeInfo.icon = ""
			Set tNodeInfo.title = ""
			Set tNodeInfo.style = ""
			Set tHasNode = ..%GetNodeInfo(.tSC,tLevel,.tHandle,tNodeInfo,.tParms)
			Quit:$$$ISERR(tSC)

			#; is there a node here
			If ('tHasNode) {
				#; no node; back out
				Set tLevel = tLevel - 1
			}
			Else {
				#; add node to tree
				#; $LB(text,value,haschildren,link,expanded,icon,tooltip,style)
				Set pTree(tNodeNo) = $LB(tNodeInfo.text,tNodeInfo.value,tNodeInfo.hasChildren,tNodeInfo.link,tNodeInfo.expanded,tNodeInfo.icon,tNodeInfo.title,tNodeInfo.style)
				Set pTree(tParent(tLevel),"ch",tNodeNo) = ""

				#; see if we need to descend into children
				If (tNodeInfo.hasChildren) {
					Set tLevel = tLevel + 1
					Set tParent(tLevel) = tNodeNo
				}
				Set tNodeNo = tNodeNo + 1
			}
		}
	} While(0)
	Quit tSC
}

/// Draw HTML to display the given tree graph.
Method %DrawTree(ByRef pTree, pLevel As %Integer = 1, pParentNode As %Integer = 0, pStateList As %String = "") [ Internal ]
{
	#; loop over top-most items in the graph
	Set tFirst = 1
	Set tOffset = ..nodeCount
	Set tNode = $O(pTree(0,"ch",""))
	While (tNode '= "") {
		If (tFirst) {
			Set tFirst = 0
			Set tState(pLevel) = $S($O(pTree(0,"ch",tNode))="":0,1:3)
		}
		Else {
			Set tState(pLevel) = $S($O(pTree(0,"ch",tNode))="":1,1:2)
		}
		#; for sub tree, we need to fill in state values
		If (pLevel > 1) {
			For n = 1:1:pLevel-1 {
				Set tState(n) = +$P(pStateList,",",n)
			}
		}

		Set ..nodeCount =..nodeCount + 1
		Do ..%DrawNode(.pTree,tNode,tOffset, pLevel,.tState,pParentNode)
		Set tNode = $O(pTree(0,"ch",tNode))
	}
}

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
	Set tTooltip = $ZCVT($LG(tData,7),"O","HTML")
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

/// Built-in drag handler for tree component.
/// Let the user drag the selected node.
ClientMethod dragStartHandler(dragData) [ Language = javascript ]
{
	var ok = false;

	// drag item is index of node to drag
	var dragItem = this._dragSource;
	if (null != dragItem) {
		dragData.sourceItem = dragItem;
		delete this._dragSource;
		var anchor = this.findElement('a_' + dragItem);
		if (anchor) {
			ok = true;
			dragData.value = this.getNodeValue(dragItem);
			if ('' == dragData.value) {
				// don't drag missing values
				return false;
			}
			dragData.text = this.getNodeText(dragItem);

			// construct avatar
			var icon = anchor.parentNode.cloneNode(true);
			icon.style.position="absolute";
			icon.style.border ="1px solid darkgray";
			icon.style.background ="#D0D0F0";
			icon.style.zIndex = 10;
			icon.style.boxShadow ="2px 2px 2px #808080";
			ZLM.setDragAvatar(icon);
		}
	}

	return ok;
}

/// This is a test method that is used to test the dynaTree component.
ClassMethod %TestCallback(pClass As %String, pMethod As %String) [ Internal ]
{
	Set tLevel = 1
	Set tHandle = ""

	#; create NodeInfo object used by callback
	Set tNodeInfo = ##class(%ZEN.Auxiliary.NodeInfo).%New()

	#; create page object 
	Set tPage = $zobjclassmethod(pClass,"%New")

	While (tLevel>0) {
		#; reset node info and invoke callback
		Set tNodeInfo.text = ""
		Set tNodeInfo.value = ""
		Set tNodeInfo.hasChildren = 0
		Set tParams("param") = "" // not used

		Set tHasNode = $zobjmethod(tPage,pMethod,.tSC,.tParams,tLevel,.tHandle,tNodeInfo)

		#; is there a node here
		If ('tHasNode) {
			#; no node; back out
			Set tLevel = tLevel - 1
		}
		Else {
			Write ?(tLevel*3),$S(tNodeInfo.hasChildren:"*",1:" "),tNodeInfo.text,!
			#; see if we need to descend into children
			If (tNodeInfo.hasChildren) {
				Set tLevel = tLevel + 1
			}
		}
	}
}

/// This callback gets information used to get the contents of the entire
/// tree.<br/>
/// This should return a graph of the form:<br/>
/// pTree(n) = $LB(text,value,link,expanded,icon)<br/>
/// pTree(n,"ch",childno) = ""<br/>
/// Top-most nodes are in:<br/>
/// pTree(0,"ch",topchildno) = ""<br/>
/// The default implementation is to call the page method specified
/// by the <property>OnGetTreeInfo</property> property.<br>
Method %GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetTreeInfo '= "")) {
		Set tSC = $zobjmethod(tHost,..OnGetTreeInfo,pRoot,.pTree,.pParms)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This callback gets information used to draw the next node within
/// the dynamic tree control.<br>
/// The default implementation is to call the page method specified
/// by the <property>OnGetNodeInfo</property> property.<br>
/// Returns true if there is a node at the current location/level else false.
Method %GetNodeInfo(Output tSC As %Status, pLevel As %Integer, ByRef pHandle As %String, pNodeInfo As %ZEN.Auxiliary.NodeInfo, ByRef pParms) As %Boolean [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Set tHasNode = 0

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetNodeInfo '= "")) {
		Set tHasNode = $zobjmethod(tHost,..OnGetNodeInfo,.tSC,.pParms,pLevel,.pHandle,pNodeInfo)
	}

	If ((..OnGetNodeInfo="") && (..dataGlobal'="")) {
		#; build tree from user-provided data global
		Kill tParameters // not used!
		Set tHasNode = ..%BuildTreeFromGlobal(.tSC,.tParameters,pLevel,.pHandle,pNodeInfo)
	}
Done
	Quit tHasNode
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Set tHasNode = 0
	Goto Done
}

/// This method is used to provide contents of a tree from 
/// a user defined data global.
Method %BuildTreeFromGlobal(Output tSC As %Status, ByRef pParams As %String, pLevel As %Integer, ByRef pHandle As %String, pNodeInfo As %ZEN.Auxiliary.NodeInfo) As %Boolean [ Internal, Private ]
{
	If (pHandle = "") {
		#; first call; set up pHandle
		Set pHandle = ..dataGlobal
	}

	#; $Order to next node at current level
	Set glvn = pHandle
	Set:pLevel>1 glvn = glvn _ "("
	For n=1:1:pLevel-1 {
		Set glvn = glvn _ $S(n>1:",",1:"") _ $$$quote($G(pHandle(n)))
	}
	Set:pLevel>1 glvn = glvn _ ")"

	Set pHandle(pLevel) = $O(@glvn@($G(pHandle(pLevel))))

	If (pHandle(pLevel) '= "") {
		Set pNodeInfo.expanded = (pLevel < 2)
		Set pNodeInfo.hasChildren = ($D(@glvn@(pHandle(pLevel)))>=10)
		Set pNodeInfo.text = pHandle(pLevel) // subscript
		Set pNodeInfo.value = $G(@glvn@(pHandle(pLevel))) // node
		Set pNodeInfo.link = pNodeInfo.value // link=value
		Set ret = 1
	}
	Else {
		Kill pHandle(pLevel)
		Set ret = 0
	}
	Quit ret
}

/// Select the given node within the tree.
/// <var>idx</var> is index of node (0 based).
ClientMethod selectItem(idx) [ Language = javascript ]
{
	// unhighlight old selection
	if (-1 != this.selectedIndex) {
		var anchor = this.findElement('a_' + this.selectedIndex);
		if (anchor) {
			anchor.className = 'dynaTreeItem';
		}
	}

	// mark new selection
	this.selectedIndex = idx;
	this.text = '';
	this.value = '';

	if (-1 != this.selectedIndex) {
		var anchor = this.findElement('a_' + this.selectedIndex);
		if (anchor) {
			anchor.className = 'dynaTreeItemSelected';
			this.text = anchor.getAttribute('zenText');
			this.value = anchor.getAttribute('zenValue');
		}
	}

	// call user event handler
	zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

/// User clicked on an item.
/// <var>idx</var> is index of node (0 based).
/// <var>level</var> is indentation level of node (0 based); this
/// is passed on to the callback.
ClientMethod itemClicked(idx, level) [ Language = javascript ]
{
	this.selectItem(idx);

	// call user event handler.
	var ret = zenInvokeCallbackMethod(this.onclick,this,'onclick','level',level);
	return (null==ret) ? true : ret;
}

/// Mouse down handler for nodes.
ClientMethod itemMouseDown(evt, idx) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
	
		this._dragSource = idx;
		this.selectItem(idx);
	}
}

/// Mouse up handler for nodes.
ClientMethod itemMouseUp(evt) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
	
		delete this._dragSource;
	}
}

/// User double-clicked on an item.
ClientMethod itemDblClicked(idx, level) [ Language = javascript ]
{
	// call user event handler, 
	var ret = zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick','level',level);
	return (null==ret) ? true : ret;
}

/// User pressed key within a node
ClientMethod itemKeyPress(evt, idx, canExpand) [ Internal, Language = javascript ]
{
	// trap space key: mozilla & IE code
	if (canExpand) {
		if ((32 == evt.charCode) || (32 == evt.keyCode)) {
			this.toggleExpanded(idx);
			return true;
		}
	}
	
	return false;
}

/// Toggle the current expanded state of a given node within the tree.
/// <var>nodeNo</var> is the index number of the node (0-based).
ClientMethod toggleExpanded(nodeNo) [ Language = javascript ]
{
	var anchor = this.findElement('a_' + nodeNo);

	var div = this.findElement('exp_' + nodeNo);
	zenASSERT(div,'Unable to find div element for children',arguments);

	var img = this.findElement('image_' + nodeNo);
	var icon = this.findElement('icon_' + nodeNo);

	// is node expanded?
	var expanded = !(div.style.display == '');

	div.style.display = expanded ? '' : 'none';
	if (img) {
		img.src = this.getExpandoImage(img.src, expanded);
	}

	if (icon) {
		if (this.showFolders||this.showLines) {
			icon.src = expanded ? this.imageFolderOpen : this.imageFolderClosed;
		}
		else {
			icon.src = '';
		}
	}

	if (anchor && expanded && (1 == parseInt(anchor.getAttribute('zenLoad')))) {
		anchor.setAttribute('zenLoad',0);
		var state = anchor.getAttribute('zenState');
		var value = anchor.getAttribute('zenValue');

		var level = parseInt(anchor.getAttribute('zenLevel'));
		div.innerHTML = '<div style="font-size:8pt; color: blue; padding-left:'+((level+2)*16)+ 'px;">loading...</div>';
		this.LoadSubTree(nodeNo,level,value,state);
	}

	return false;
}

/// This method returns the expanded state of a given nodeNo. true = expanded.
ClientMethod isNodeExpanded(nodeNo) [ Language = javascript ]
{
	var div = this.findElement('exp_' + nodeNo);
	zenASSERT(div,'Unable to find div element for children',arguments);
	// div.style.display == "" means node is expanded; "none" means not expanded.
	var expanded = (div.style.display == '');
	return expanded;
}

/// Reload the child nodes of the given node.
/// <var>nodeNo</var> is the index number of the node (0-based).<br/>
/// This method does nothing if it called for a leaf node (a node without
/// children).<br/>
/// This method only works when the <property>OnGetTreeInfo</property>
/// callback is used to supply the contents of the tree.
ClientMethod reloadNode(nodeNo) [ Language = javascript ]
{
	var anchor = this.findElement('a_' + nodeNo);
	var div = this.findElement('exp_' + nodeNo);
	
	if (anchor && div) {
		anchor.setAttribute('zenLoad',0);
		var state = anchor.getAttribute('zenState');
		var value = anchor.getAttribute('zenValue');
		var level = parseInt(anchor.getAttribute('zenLevel'));
		div.innerHTML = '<div style="font-size:8pt; color: blue; padding-left:'+((level+2)*16)+ 'px;">loading...</div>';
		this.LoadSubTree(nodeNo,level,value,state);
		return true;
	}
	return false;
}

/// Internal method that is used to load a portion of the tree from the server.
Method LoadSubTree(pNodeNo As %Integer, pLevel As %Integer, pValue As %String, pState As %String) [ Internal, ZenMethod ]
{
	#; state contains sibling state for given node

	&js<
		var tree = zenPage.getComponent(#(..index)#);
		var div = tree.findElement('exp_' + #(pNodeNo)#);
	>

	#; execute our callback method and capture it as JavaScript
	Write "var html = '"

	#; use JS output to properly escape HTML for JS
	Set io = ##class(%ZEN.Controller).%BeginJSTranslation()
	Set $ZT = "Trap"

	Set tSC = $$$OK
	Do {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParms(key) = $$$ZENVAL(value)
			Set key = ..parameters.Next(key)
		}

		#; test for callback
		If (..OnGetTreeInfo '= "") {
			#; get subtree info
			Set tSC = ..%GetTreeInfo(pValue,.tTree,.tParms)
		}

		If $D(tTree) {
			#; draw the tree
			Do ..%DrawTree(.tTree,pLevel+1,pNodeNo+1,pState)
		}
	} While(0)

	#; error
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
	}

	Do ##class(%ZEN.Controller).%EndJSTranslation(io)
	Write "';",!
	Set $ZT = ""

	Write "div.innerHTML = html;",!
	Write "html=null;",!
	Quit
Trap
	Set $ZT = ""
	Do ##class(%ZEN.Controller).%EndJSTranslation(io)
	Write "';",!
	Do ##class(%ZEN.Utils).%DisplayErrorJS(##this,$$$ERROR($$$GeneralError,$ZE))
	Quit
}

/// Convert the given image url to either a expanded or contracted image.
ClientMethod getExpandoImage(src, expanded) [ Internal, Language = javascript ]
{
	if (this.showLines) {
		if (src.indexOf('plus-') != -1) {
			return expanded ? src.split('plus-').join('minus-') : src;
		}
		else {
			return expanded ? src : src.split('minus-').join('plus-');
		}
	}
	return expanded ? this.imageExpanded : this.imageContracted;
}

/// Expand (if flag is true) or contract (if flag is false) all
/// nodes within the true;
/// Does not invoke any callback methods.
ClientMethod expandAll(flag) [ Language = javascript ]
{
	// loop over all nodes; expand or contract any parent nodes
	var n = 0;
	while(this.findElement('a_' + n)) {
		// do we have children?
		var div = this.findElement('exp_' + n);
		if (div) {
			var img = this.findElement('image_' + n);
			var icon = this.findElement('icon_' + n);

			div.style.display = flag ? '' : 'none';
			if (img) {
				img.src = this.getExpandoImage(img.src, flag);
			}
			if (icon) {
				if (this.showFolders||this.showLines) {
					icon.src = flag ? this.imageFolderOpen : this.imageFolderClosed;
				}
				else {
					icon.src = '';
				}
			}
		}
		n++;
	}
}

/// Set the display value of a given node.
/// <var>nodeNo</var> is the index number of the node (0-based).
ClientMethod setNodeText(nodeNo, text) [ Language = javascript ]
{
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		anchor.setAttribute('zenText',text);
		anchor.innerHTML = text + '&nbsp;';
	}
}

/// Get the display value of a given node.
/// <var>nodeNo</var> is the index number of the node (0-based).
/// If <var>nodeNo</var> is not provided use the current selected noded.
ClientMethod getNodeText(nodeNo) [ Language = javascript ]
{
	if (null == nodeNo) { nodeNo = this.selectedIndex; }
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		return anchor.getAttribute('zenText');
	}
	return null;
}

/// Return the index number (0-based) of the parent of the specified node.
/// <var>nodeNo</var> is the index number of the node (0-based).
ClientMethod getNodeParent(nodeNo) [ Language = javascript ]
{
	var p = null;
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		p = anchor.getAttribute('zenParent');
	}
	return (p==null) ? -1 : p;
}

/// Set the logical value of a given node.
/// <var>nodeNo</var> is the index number of the node (0-based).
ClientMethod setNodeValue(nodeNo, value) [ Language = javascript ]
{
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		anchor.setAttribute('zenValue',value);
	}
}

/// Get the logical value of the current selected node.
ClientMethod getValue() [ Language = javascript ]
{
	var val = null;
	if (this.selectedIndex >=0) {
		var anchor = this.findElement('a_' + this.selectedIndex);
		if (anchor) {
			val = anchor.getAttribute('zenValue');
		}
	}
	return (val == null) ? '' : val;
}

/// Get the logical value of a given node.
/// <var>nodeNo</var> is the index number of the node (0-based).
/// If <var>nodeNo</var> is not provided use the current selected noded.
ClientMethod getNodeValue(nodeNo) [ Language = javascript ]
{
	if (null == nodeNo) { nodeNo = this.selectedIndex; }
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		return anchor.getAttribute('zenValue');
	}
	return null;
}

/// Return the index number (0-based) of the current node.
/// Return -1 if no node is selected.
ClientMethod getSelectedIndex() [ Language = javascript ]
{
	return this.selectedIndex;
}

/// Set the css style for of a given node.
/// <var>style</var> should contain css style declarations
/// (e.g., 'color: red;')<br/>
/// <var>nodeNo</var> is the index number of the node (0-based).
ClientMethod setNodeStyle(nodeNo, style) [ Language = javascript ]
{
	var anchor = this.findElement('a_' + nodeNo);
	if (anchor) {
		anchor.style.cssText = style;
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'OnGetTreeInfo':
		if (this.OnGetTreeInfo != value) {
			this.OnGetTreeInfo = value;
			this.refreshContents(true);
		}		
		break;
	case 'OnGetNodeInfo':
		if (this.OnGetNodeInfo != value) {
			this.OnGetNodeInfo = value;
			this.refreshContents(true);
		}		
		break;

	case 'showFolders':
	case 'childIndent':
	case 'imageExpanded':
	case 'imageContracted':
	case 'imageFolderOpen':
	case 'imageFolderClosed':
		if (this[property] != value) {
			this[property] = value;
			this.refreshContents();
		}		
		break;

	case 'showLines':
		value = value ? true : false;
		if (this.showLines != value) {
			this.showLines = value;
			this.refreshContents();
		}		
		break;

	case 'parameters':
		// set value of named parameter
		// only works for pre-defined parameter names!
		if ('' != value) {
			 if (this.parameters[value]) {
				 if (this.parameters[value].value != value2) {
					this.parameters[value].value = value2;
					this.refreshContents();
				 }
			 }
		}
		break;

	case 'text':
	case 'value':
		// readonly
		break;
	case 'selectedIndex':
		this.selectItem(value);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
