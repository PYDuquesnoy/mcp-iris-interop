/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Caption Editor page.
/// 
Class %DeepSee.UI.CaptionEditor Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Caption Editor";

/// Parameter DOCBOOKID = "D2ANLY_ch_intro";
/// Name of Cube (with extension).
Property cubeFullName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of cube to explore.
Property cubeName As %ZEN.Datatype.string;

/// If true, user can modify (non-read-only) pivots.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, user cannot modify captions.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Current context.
Property currContext As %ZEN.Datatype.string;

/// Current dimension.
Property currDim As %ZEN.Datatype.string;

/// Current hierarchy.
Property currHier As %ZEN.Datatype.string;

/// Current level.
Property currLevel As %ZEN.Datatype.string;

/// Current property.
Property currProp As %ZEN.Datatype.string;

/// Current caption.
Property currCaption As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

body {
	visibility: hidden;
	/* do not show scroll bars for ie */
	overflow: hidden;
}

#details {
	background: #F0F0F0;
}


select {
	font-size: 0.9em;
}

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

.dynaTreeNode {
	white-space: nowrap;
	font-size: 10pt;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}

#groupTree,#groupTree2 {
	width: 250px;
	overflow: hidden;
	border: 1px solid black;
	background: white;
}

#treeWrapper,#treeWrapper2 {
	overflow-y: auto;
	overflow-x: auto;
}

#dimTree,#dimTree2 {
	overflow: auto;
	display: block;
}

#cubeName,#cubeName2 {
	color: #404040;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
	border: none;
	border-bottom: 1px solid gray;
	width: 100%;
	overflow: hidden;
}

#cubeNameDiv,#cubeNameDiv2 {
	font-size: 10pt;
	font-weight: bold;
	color: #404040;
	padding: 3px;
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: darkblue;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	font-size: 10pt;
	font-weight: normal;
	color: gray;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: orange;
}

.ctrlRO {
	border: 1px solid #808080;
	background: #F8F8F8;
	color: #606060;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee"
>
<hgroup id="mainHGroup" cellVAlign="top">
<spacer width="10"/>
<vgroup id="groupTree">
<html id="cubeName" OnDrawContent="DrawCubeName"/>
<vgroup id="treeWrapper">
<dynaTree id="dimTree" 
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode=""
onchange="zenPage.treeChange(zenThis);"
showLines="false" showFolders="false" dragEnabled="false" 
OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="cube" value="#(%page.cubeName)#" />
</dynaTree>
</vgroup>
</vgroup>

<vgroup id="details" cellStyle="padding:5px; padding-left:10px;">

<spacer height="10"/>
<hgroup label="Context" cellVAlign="top">
<select id="textContext" onchange="zenPage.contextChange(zenThis.getValue());"/>
</hgroup>

<text id="textItem" label="Spec" readOnly="true" hidden="false" size="80" controlClass="ctrlRO"/>

<text id="textDim" label="Dimension" readOnly="true" size="50" controlClass="ctrlRO"/>

<text id="textHier" label="Hierarchy" readOnly="true" size="50" controlClass="ctrlRO"/>

<text id="textLevel" label="Level" readOnly="true" size="50" controlClass="ctrlRO"/>

<text id="textProp" label="Property" readOnly="true" size="50" controlClass="ctrlRO"/>

<hgroup label="Caption" cellVAlign="top" hint="Select an item from the tree on the left side">
<text id="textCaption" size="50"/>
<image src="deepsee/close_a_24.png" title="Delete this caption" onclick="zenPage.deleteCaption();"/>
</hgroup>

<button caption="Save" onclick="zenPage.saveCaption();"/>

</vgroup>


<vgroup id="groupTree2">
<html id="cubeName2" OnDrawContent="DrawCubeName" seed="output"/>
<vgroup id="treeWrapper2">
<dynaTree id="dimTree2" 
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode=""
showLines="false" showFolders="false" dragEnabled="false" 
OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed2" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="pcontext2" paramName="context" value="" />
</dynaTree>
</vgroup>
</vgroup>

</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If (..cubeName'="") {
		Quit ##class(%DeepSee.Utils).%GetCubeCaption(..cubeName)
	}
	Quit $$$Text("Caption Editor")
}

/// Get the name for the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Caption Editor")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Caption Editor")

	Quit $$$OK
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	Quit $$$OK
}

/// Draw cube name above member tree.
Method DrawCubeName(pSeed As %String) As %Status
{
	Set tCubeCaption = ""
	If (..cubeName'="") {
		Set tCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(..cubeName)
	}
	Set tCubeName = $S(tCubeCaption'="":tCubeCaption,1:..cubeName)
	Set hlpCube = $$$Text("Current Subject Area","%DeepSee")
	Set msgChange = $$$Text("Select Subject Area")
	Set hlpChange = $$$Text("Change to a different Subject Area")

	&html<<table width="100%" border="0" cellspacing="0"><tr>>
	&html<<td valign="middle" width="90%"><div id="cubeNameDiv" title="#(hlpCube)#">#($ZCVT(tCubeName,"O","HTML"))#</div></td>>

	&html<<td nowrap="1" valign="bottom">>

	// hilight icon if no cube 
	If (..cubeName="") {
		&html<<div style="font-size: 12pt;">>
		Write $ZCVT(msgChange,"O","HTML")
	}
	If (pSeed="") {
		&html<&nbsp;<img class="dsptIcon" title="#(hlpChange)#" onclick="zenPage.changeSubjectArea();" src="deepsee/cube_24.gif" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;" />>
	}
	Else {
		Write "&nbsp;","<b>","(Output)","</b>"
	}

	If (..cubeName="") {
		&html<</div>>
	}
	&html<</td>>

	&html<<td nowrap="1" width="2%">&nbsp;</td>>
	&html<</tr></table>>
	Quit $$$OK
}

/// Launch the subject area finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'PivotOpen':
		self.document.location = zenLink(this.analyzerURL + '?PIVOT=' + encodeURIComponent(value));
		break;
		break;
	case 'SubjectArea':
		// strip off extension
		var isCube = true;
		var name = '';
		var s = value.toString().split('.');
		if ('cube' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = true;
		}
		else if ('subjectArea' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = false;
		}

		if (name != this.cubeName) {
			self.document.location = zenLink('_DeepSee.UI.CaptionEditor.cls' + '?CUBE=' + encodeURIComponent(value));
		}
		break;
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value);
		self.document.location = url;
		break;
	}
}

/// Provide contents of the dimension tree.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))
		Set tContext = $G(pParms("context"))
		If (tContext'="") {
			Set %dsCaptionContext = tContext
		}

		If (tCube'="") {
			Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tCube,.pTree,,,pRoot,.tCalcMbrs,.tNamedSets,,,1)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen?home="_..EscapeURL($G(%request.Data("home",1)))_"&CUBE="_$ZCVT(..cubeFullName,"O","URL"))
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var tree = zen('groupTree');
		var divTree = tree.getEnclosingDiv();

		var treeWrap = zen('treeWrapper');
		var divTreeWrap = treeWrap.getEnclosingDiv();

		var treeHeader = zen('cubeName');
		var divTreeHeader = treeHeader ? treeHeader.getEnclosingDiv() : null;

		var tree2 = zen('groupTree2');
		var divTree2 = tree2.getEnclosingDiv();

		var treeWrap2 = zen('treeWrapper2');
		var divTreeWrap2 = treeWrap2.getEnclosingDiv();

		var treeHeader2 = zen('cubeName2');
		var divTreeHeader2 = treeHeader2 ? treeHeader2.getEnclosingDiv() : null;

		var details = zen('details');
		var divDetails = details.getEnclosingDiv();

		// show tree
		divTree.style.display = 'block';
		divTree2.style.display = 'block';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		// we need these commands or Chrome will make the title area too big
		// when initially displayed (on this page only!!!)
		// (which is kind of disappointing)
		var tdiv = zen('title').getEnclosingDiv();
		tdiv.style.width = winWidth + 'px';

		var tdiv = zen('toolRibbon').getEnclosingDiv();
		tdiv.style.width = winWidth + 'px';

		var cwid = winWidth - (25 + divTree.offsetWidth + divTree2.offsetWidth);
		cwid = (cwid>0)?cwid:0;

		var h = winHeight - (25 + th);
		var phgt = h;
		phgt = (phgt>0)?phgt:0;

		divDetails.style.display = 'block';

		divDetails.style.width = (cwid>0)?cwid:0 + 'px';
		divDetails.style.height = phgt + 'px';
		divTree.style.height = h>0?h:0 + 'px';
		divTree2.style.height = h>0?h:0 + 'px';

		divTreeWrap.style.width = divTree.offsetWidth + 'px';
		divTreeWrap2.style.width = divTree.offsetWidth + 'px';

		var dthoh = divTreeHeader ? divTreeHeader.offsetHeight : 0;
		divTreeWrap.style.height = ((h - dthoh)>0)?(h - dthoh):0 + 'px';

		var dthoh2 = divTreeHeader2 ? divTreeHeader2.offsetHeight : 0;
		divTreeWrap2.style.height = ((h - dthoh2)>0)?(h - dthoh2):0 + 'px';

		self.document.body.style.visibility = 'visible';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		//Set tSC = ##super()
		//If $$$ISERR(tSC) Quit

		// check privileges
		// Do CheckAnalyzerUseAccess^%qdsUtils()

		#; register visit
		Set tSC = ..%Register()
		If $$$ISERR(tSC) Quit

		Set tWrite = 1
		If ('tWrite) {
			Set ..canWrite = 0
		}
		Set ..readOnly = 0

		// override menu logic
		Set %page.aboutPage = ##class(%CSP.Page).Link("_CSP.UI.Portal.About.cls")

		// tLinks is an array of menu options
		Set tSC = ..GetContextLinks(.tLinks)
		If $$$ISERR(tSC) Quit

		If (..cubeFullName="") {
			Set ..cubeFullName = $G(^DeepSee.LastCube($UserName))
		}

		// Get set of context names
		Set tList = "<new context>"
		Set k = $O(^DeepSee.Captions(""))
		While (k'="") {
			Set tList = tList _ $S(tList="":"",1:",") _ k
			Set k = $O(^DeepSee.Captions(k))
		}
		Set ..%GetComponentById("textContext").valueList = tList
		Set ..%GetComponentById("textContext").value = $G(^DeepSee.LastContext($UserName))
		Set ..%GetComponentById("pcontext2").value = $G(^DeepSee.LastContext($UserName))

		// Strip off extension from name
		Set tExt = $P(..cubeFullName,".",$L(..cubeFullName,"."))
		If ((tExt = "cube")||(tExt = "subjectArea")) {
			Set tName = $P(..cubeFullName,".",1,$L(..cubeFullName,".")-1)
			Set ..cubeName = tName
		}
		Else {
			Set tExt = "cube"
			Set ..cubeName = ..cubeFullName
		}

		If ('##class(%DeepSee.Utils).%CubeExists(..cubeName, .tSC)) {
			// swallow the error
			Set tSC = $$$OK
			Set ..cubeName = ""
			Quit
		}
		Else {
			// Get original case of cube name
			Set ..cubeName = ##class(%DeepSee.Utils).%GetCubeName(..cubeName,.tSC)
		}

		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User has selected a new context.
ClientMethod contextChange(ctx) [ Language = javascript ]
{
	if (ctx == '<new context>') {
		ctx = prompt('Name of new context');
		if (ctx=='') return;
		zenSynchronousMode = true;
		zen('textContext').setProperty('valueList',zen('textContext').getProperty('valueList')+','+ctx);
		zenSynchronousMode = false;
	}
	this.currContext = ctx;
	zen('textContext').setValue(ctx);

	zen('pcontext2').value = ctx;
	zen('dimTree2').refreshContents();
}

/// User has selected a new element in the tree control.
ClientMethod treeChange(tree) [ Language = javascript ]
{
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);

	this.currContext = zen('textContext').getValue();

	zen('textItem').setValue(value);
	if (this.currContext != '') {
		var msg = this.ParseValue(this.cubeName,this.currContext,value);
		if (msg != '') {
			alert(msg);
		}
	}
	zen('textDim').setValue(this.currDim);
	zen('textHier').setValue(this.currHier);
	zen('textLevel').setValue(this.currLevel);
	zen('textProp').setValue(this.currProp);
	zen('textCaption').setValue(this.currCaption);
}

/// Pull apart the given member spec.
ClassMethod ParseValue(pCube As %String, pContext As %String, pValue As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pValue,.tSpecInfo,.tQuoted)

	Set pCube = $$$UPPER(pCube)
	Set tDim = $$$UPPER($G(tSpecInfo(1)))
	Set tHier = $$$UPPER($G(tSpecInfo(2)))
	Set:tHier="%TOPMEMBERS" tHier = ""

	Set tLevel = $$$UPPER($G(tSpecInfo(3)))

	// check for property reference
	Set tProp = ""
	If ($P($$$UPPER(pValue),".CURRENTMEMBER.PROPERTIES(""",2)'="") {
		Set tProp = $P($$$UPPER(pValue),".CURRENTMEMBER.PROPERTIES(""",2)
		Set tProp = $P(tProp,""")",1)
	}

	Set tCaption = ""
	If (tDim'="") {
		If (tHier'="") {
			If (tLevel'="") {
				Set tCaption = $G(^DeepSee.Captions(pContext,pCube,tDim,tHier,tLevel))
			}
			Else {
				Set tCaption = $G(^DeepSee.Captions(pContext,pCube,tDim,tHier))
			}
		}
		Else {
			Set tCaption = $G(^DeepSee.Captions(pContext,pCube,tDim))
		}
	}

	&js<zenPage.currDim = '#($ZCVT(tDim,"O","JS"))#';>
	&js<zenPage.currHier = '#($ZCVT(tHier,"O","JS"))#';>
	&js<zenPage.currLevel = '#($ZCVT(tLevel,"O","JS"))#';>
	&js<zenPage.currProp = '#($ZCVT(tProp,"O","JS"))#';>
	&js<zenPage.currCaption = '#($ZCVT(tCaption,"O","JS"))#';>
	Quit ""
}

/// Delete the current caption.
ClientMethod deleteCaption() [ Language = javascript ]
{
	if (confirm('Do you wish to delete this caption?')) {
		this.DeleteItem(this.cubeName,this.currContext,this.currDim,this.currHier,this.currLevel,this.currProp);
		zen('textCaption').setValue(this.currCaption);
	}
	zen('dimTree2').refreshContents();
}

/// Delete a caption.
ClassMethod DeleteItem(pCube As %String, pContext As %String, pDim As %String, pHier As %String, pLevel As %String, pProp As %String) As %String [ ZenMethod ]
{
	Set pCube = $$$UPPER(pCube)
	If (pDim'="") {
		If (pHier'="") {
			If (pLevel'="") {
				If (pProp'="") {
					Kill ^DeepSee.Captions(pContext,pCube,pDim,pHier,pLevel,pProp)
				}
				Else {
					Kill ^DeepSee.Captions(pContext,pCube,pDim,pHier,pLevel)
				}
			}
			Else {
				Kill ^DeepSee.Captions(pContext,pCube,pDim,pHier)
			}
		}
		Else {
			Kill ^DeepSee.Captions(pContext,pCube,pDim)
		}
	}
	&js<zenPage.currCaption = '';>
	Quit ""
}

/// Save the current caption.
ClientMethod saveCaption() [ Language = javascript ]
{
	var caption = zen('textCaption').getValue();
	var msg = this.SaveItem(this.cubeName,this.currContext,this.currDim,this.currHier,this.currLevel,this.currProp,caption);
	if (msg!='') {
		alert(msg);
	}
	zen('dimTree2').refreshContents();
}

/// Save a caption.
ClassMethod SaveItem(pCube As %String, pContext As %String, pDim As %String, pHier As %String, pLevel As %String, pProp As %String, pCaption As %String) As %String [ ZenMethod ]
{
	If (pCube="") {
		Quit "No cube selected"
	}
	If (pContext="") {
		Quit "No context selected"
	}

	Set ^DeepSee.LastContext($UserName) = pContext
	Set pCube = $$$UPPER(pCube)
	Set pProp = $$$UPPER(pProp)
	If (pDim'="") {
		If (pHier'="") {
			If (pLevel'="") {
				If (pProp'="") {
					Set ^DeepSee.Captions(pContext,pCube,pDim,pHier,pLevel,pProp) = pCaption
				}
				Else {
					Set ^DeepSee.Captions(pContext,pCube,pDim,pHier,pLevel) = pCaption
				}
			}
			Else {
				Set ^DeepSee.Captions(pContext,pCube,pDim,pHier) = pCaption
			}
		}
		Else {
			Set ^DeepSee.Captions(pContext,pCube,pDim) = pCaption
		}
	}
	Quit ""
}

}
