/// dynaTree Control Test
Class ZENTest.DynaTreeTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Dynamic Tree Control Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">
#tree {
	border: 1px darkblue solid;
	background: #CBE6EB;
	background-position: right;
	background-image: url(images/docindexgradient.png);
	background-repeat: repeat-y;
	height: 600px;
	width: 300px;
	overflow: auto;
}

#label {
	border: 1px darkblue solid;
	background: white;
	padding: 2px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Dynamic Tree Control Test">
<demo:demoTitle id="title" title="Zen dynaTree Control Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="dynaTree" title="dynaTree Test Page" />
</locatorBar>


<spacer height="25"/>
<hgroup>
<dynaTree
	id="tree"
	OnGetTreeInfo="GetTreeInfo"
	onclick="zenPage.treeClick(zenThis);">
	<parameter paramName="count" value="20"/>
	</dynaTree>
<spacer width="25"/>
<vgroup valign="top">
<spacer height="25"/>
<radioSet displayList="Simple Tree,Class Hierarchy,Time" valueList="GetTreeInfo,GetClassInfo,GetTimeInfo"  value="GetTreeInfo" onchange="zenPage.setTreeCallback(zenThis.getValue());"/>
<spacer height="25"/>
<checkbox caption="Lines" onchange="zenPage.treeLines();"/>
<spacer height="25"/>
<label id="label" value="No click"/>
<spacer height="25"/>
<button caption="Set Node Text" onclick="zenPage.setNodeText();"/>
<button caption="Set Node Style" onclick="zenPage.setNodeStyle();"/>
<button caption="Get Node Parent" onclick="zenPage.getNodeParent();"/>
<button caption="Reload Node" onclick="zenPage.reloadNode();"/>
</vgroup>
</hgroup>
</page>
}

/// Sample of a OnGetTreeInfo callback.
ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	#; top-most nodes are children of 0
	#; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon)
	if pRoot=""
	{
		Set pTree(0,"ch",1) = ""
		Set pTree(0,"ch",2) = ""
		Set pTree(0,"ch",3) = ""

		Set pTree(1) = $LB("Animal","Animal",1,"",1,,"General types of animal")
		Set pTree(2) = $LB("Mineral","Mineral",1,"",1,,"General types of mineral")
		Set pTree(3) = $LB("Vegetable","Vegetable",1,"",1,,"General types of vegetable")
	}
	elseif pRoot="Animal" //id 1
	{
		Set pTree(4) = $LB("Mammal","Mammal",1,"",1)
		Set pTree(0,"ch",4) = ""
	}
	elseif pRoot="Mineral" //id 2
	{
		Set pTree(7) = $LB("Rock","Rock",0,"",1)
		Set pTree(0,"ch",7) = ""
	}
	elseif pRoot="Vegetable" //id 3
	{
		Set pTree(8) = $LB("Fruit","Fruit",1,"",1)
		Set pTree(0,"ch",8) = ""
	}
	elseif pRoot="Mammal" //id 4
	{
		Set pTree(5) = $LB("Cat","Cat",0,"",1)
		Set pTree(6) = $LB("Dog","Dog",0,"",1)
		Set pTree(0,"ch",5) = ""
		Set pTree(0,"ch",6) = ""
	}
	elseif pRoot="Fruit" //id 8
	{
		Set pTree(9) = $LB("Apple","Apple",0,"",1)
		Set pTree(10) = $LB("Banana","Banana",0,"",1)
		Set pTree(11) = $LB("Cherry","Cherry",0,"",1)
		Set pTree(0,"ch",9) = ""
		Set pTree(0,"ch",10) = ""
		Set pTree(0,"ch",11) = ""
	}

	Quit $$$OK
}

/// Sample of a OnGetTreeInfo callback.
ClassMethod GetTimeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	#; use utility method to build tree of time values
	Set tParms("spec") = "Y,M,D"
	Set tParms("startYear") = 2007
	Set tParms("endYear") = 2009
	Quit ##class(%ZEN.TreeUtils).TimePeriodTree(pRoot,.pTree,.tParms)
}

/// Sample of a OnGetTreeInfo callback.
/// This one recursively loads the set of visible packages and classes in 
/// the current namespace.
ClassMethod GetClassInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	#; pRoot is "" for the top-most call.
	#; otherwise it contains the package name at the folder node
	If (pRoot = "") {
		Set n = 1
		Set tCurrPkg = ""

		#; return top-level packages
		Set tKey = $O(^rINDEXCLASS(""))
		While (tKey '= "") {
			Set tClass = $LG(^rINDEXCLASS(tKey),2)
			Set tPkg = $P(tClass,".",1)
			If (tPkg '= tCurrPkg) {
				Set tCurrPkg = tPkg
				Set pTree(n) = $LB(tPkg,tPkg_".pkg",1)
				Set pTree(0,"ch",n) = ""
				Set n = n + 1
			}
			Set tKey = $O(^rINDEXCLASS(tKey))
		}
	}
	Else {
		#; pRoot is parent package; check extension
		Set tExt = $P(pRoot,".",$L(pRoot,"."))
		Set pRoot = $P(pRoot,".",1,$L(pRoot,".")-1)

		If (tExt = "pkg") {
			Set n = 1
			Set tCurrPkg = ""
			Set tLevel = $L(pRoot,".")
	
			#; find packages and classes within pRoot (at this level)
			Set tKey = $O(^rINDEXCLASS($ZCVT(pRoot,"U")))
			While (tKey '= "") {
				Set tClass = $LG(^rINDEXCLASS(tKey),2)
				If (pRoot '= $P(tClass,".",1,tLevel)) {
					#; we've moved on to the next top-level package
					Quit
				}
				Set tName = $P(tClass,".",tLevel+1)
				Set tPkg = $P(tClass,".",1,tLevel+1)
				If (tPkg = tClass) {
					#; this is a class name
					Set pTree(n) = $LB(tName,tClass_".cls",0)
					Set pTree(0,"ch",n) = ""
					Set n = n + 1
				}
				ElseIf (tPkg '= tCurrPkg) {
					Set tCurrPkg = tPkg
					Set pTree(n) = $LB(tName,tPkg_".pkg",1)
					Set pTree(0,"ch",n) = ""
					Set n = n + 1
				}
				Set tKey = $O(^rINDEXCLASS(tKey))
			}
		}
	}
	Quit $$$OK
}

/// Reload a node within the tree.
ClientMethod reloadNode() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.reloadNode(tree.getSelectedIndex());
}

/// Change the text of the current node in the tree.
ClientMethod setNodeText() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.setNodeText(tree.getSelectedIndex(),'New Text');
}

/// Change the style of the current node in the tree.
ClientMethod setNodeStyle() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.setNodeStyle(tree.getSelectedIndex(),'color: red;');
}

/// Show the index of the parent node of the current node.
ClientMethod getNodeParent() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	alert('Parent of this node is: ' + tree.getNodeParent(tree.getSelectedIndex()));
}

/// Change the callback for the tree
ClientMethod setTreeCallback(code) [ Language = javascript ]
{
 var tree = this.getComponentById('tree');
 zenPage.ReallySetTreeCallback(tree,code);
}

/// tree.setProperty('OnGetTreeInfo',code); is not allowed. This property must be set server-side.
/// Rather than blindly accepting any value, we validate the property name against a list of permitted values.
ClassMethod ReallySetTreeCallback(pTree As %ZEN.Component.dynaTree, pMethod As %String) [ ZenMethod ]
{
 If '$ListFind($ListBuild("GetTreeInfo","GetClassInfo","GetTimeInfo"),pMethod) Quit
 
 Set pTree.OnGetTreeInfo = pMethod
 Do pTree.ReallyRefreshContents() //Re-render the tree after changing the property.
}

/// Change the showLines property for the tree
ClientMethod treeLines() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.setProperty('showLines',!tree.getProperty('showLines'));
}

/// expand the tree
ClientMethod treeExpand(tree) [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.expandAll(true);
}

/// contract the tree
ClientMethod treeContract(tree) [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.expandAll(false);
}

/// treeClick
ClientMethod treeClick(tree) [ Language = javascript ]
{
	var label = this.getComponentById('label');
	label.setValue('Click on node: ' + tree.getProperty('selectedIndex') + ' text: ' + tree.getProperty('text')+ ' value: ' + tree.getProperty('value'));
}

}

