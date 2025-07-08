/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog displays an analysis of the selected cell(s) within a pivot table.
/// This class is a wrapper that lets the user select one of the available
/// options.
Class %DeepSee.UI.Dialog.PivotAnalysis Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property queryKey As %ZEN.Datatype.string(ZENURL = "KEY");

Property selectedRange As %ZEN.Datatype.string(ZENURL = "RANGE");

Property sortColumn As %ZEN.Datatype.integer(ZENURL = "SORTCOL") [ InitialExpression = 0 ];

Property sortDir As %ZEN.Datatype.string(ZENURL = "SORTDIR") [ InitialExpression = "ASC" ];

/// Class name of current analysis.
Property analysisType As %ZEN.Datatype.string(ZENURL = "TYPE");

/// Measure to use for analysis.
Property measureName As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// WITH clause for query
Property withClause As %ZEN.Datatype.string(ZENURL = "WITH");

XData Style
{
<style type="text/css">

body {
	background: #E0E0FF;
}

#body {
	background: #E0E0FF;
	overflow: hidden;
}

#analysisMenu {
	height: 600px;
	width: 150px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: auto;
}

.zenLabel {
	color: #404040;
	font-size: 10px;
}

.checkboxCaption {
	color: #404040;
	font-size: 12px;
}

.lookoutButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
}

.lookoutButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
.Icon,.IconSelected {
	padding: 4px;
	display: block;
	font-size: 11px;
	text-decoration: none;
	color: black;
	border: 1px solid #D0D0D0;
	box-shadow: 2px 2px 2px #D0D0D0;
}

.IconSelected {
	padding: 1px;
	background: white;
	border: 2px solid darkred;
}

.Icon:hover, .IconSelected:hover {
	background: #FFEEAA;
}

.Icon img,.IconSelected img {
	border: none;
}

iframe {
	background: #F0F0F0;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
cellStyle="padding-bottom:8px;"
>
<hgroup cellVAlign="top">
<lookoutMenu id="analysisMenu">
</lookoutMenu>
<iframe id="iframe"/>
</hgroup>
</pane>
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	var body = zen('body');
	var divBody = body.getEnclosingDiv();

	var menu = zen('analysisMenu');
	menu.setSize(null,divBody.offsetHeight - 20);

	var iframe = zen('iframe');
	if (iframe) {
		var menuDiv = menu.getEnclosingDiv();
		var w = divBody.offsetWidth - menuDiv.offsetWidth - 20;
		w = (w < 200) ? 200 : w;
		var ifDiv = iframe.getEnclosingDiv();
		ifDiv.style.width =  w + 'px';
		ifDiv.style.height =  divBody.offsetHeight - 20 + 'px';
		var ifel = iframe.findElement('iframe');
		ifel.style.width =  w + 'px';
		ifel.style.height =  divBody.offsetHeight - 20 + 'px';
	}
}

/// Add elements to the analysis menu.
Method CreateAnalysisMenu(pMenu As %ZEN.Component.lookoutMenu) As %Status
{
	Set tSC = ..%GetAnalysisClasses(.tInfo)
	If $$$ISERR(tSC) Quit tSC

	Set tTab = ##class(%ZEN.Component.tab).%New()
	Set tTab.caption = $$$Text("Analysis Options")
	Set tTab.enclosingStyle = "background:#F0F0F0;overflow-x:hidden;"
	Set tTab.id = "tab_1"
	Do pMenu.%AddChild(tTab)

	Set tTabIKnow = ##class(%ZEN.Component.tab).%New()
	Set tTabIKnow.caption = $$$Text("iKnow Options")
	Set tTabIKnow.enclosingStyle = "background:#F0F0F0;overflow-x:hidden;"
	Set tTabIKnow.id = "tab_2"
	Do pMenu.%AddChild(tTabIKnow)

	Set tItem = $O(tInfo(""))
	While (tItem'="") {
		Set tClassName = $LG(tInfo(tItem),1)
		Set tName = $LG(tInfo(tItem),2)
		Set tTitle = $LG(tInfo(tItem),3)
		Set tImage = $LG(tInfo(tItem),4)
		Set:tImage="" tImage = "deepsee/line_chart_48.gif"

		Set tMenuItem = ##class(%ZEN.Component.html).%New()
		Set tMenuItem.OnDrawContent="DrawAnalysisIcon"
		Set tMenuItem.enclosingStyle="width:150px;"

		// n.b., seed can't be a $list as it is shipped to the client
		Set tMenuItem.seed = tClassName_"^"_tName_"^"_tTitle_"^"_tImage
		if ($e(tClassName,1,6)="%iKnow") {
			Do tTabIKnow.%AddChild(tMenuItem)
		} else {
			Do tTab.%AddChild(tMenuItem)
		}
		Set tItem = $O(tInfo(tItem))
	}
	Quit $$$OK
}

/// Draw an icon box.
/// <var>pInfo</var> is type^name^title^icon
Method DrawAnalysisIcon(pInfo As %String) As %Status
{
	&html<<table border="0" width="100%">>
	&html<<tr valign="middle">>
	Set tType = $P(pInfo,"^",1)
	Set tName = $P(pInfo,"^",2)
	Set tTitle = $P(pInfo,"^",3)
	Set tImage = $P(pInfo,"^",4)
	Set tSelected = $S((tType=..analysisType):1,1:0)
	&html<<td width="25%">&nbsp</td><td align="center" valign="top" width="75"><a id="icon_#(tType)#" class="#($S(tSelected:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectAnalysisType('#($ZCVT(tType,"O","JS"))#');return false;"><img src="#($ZCVT(tImage,"O","HTML"))#" title="#($ZCVT(tTitle,"O","HTML"))#"/><br/>#($ZCVT(tName,"O","HTML"))#</a></td><td width="25%">&nbsp</td>>
	&html<</tr>>
	&html<</table>>
	Quit $$$OK
}

/// Apply changes to page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..hideApplyButton = 1

		// Construct analysis menu
		Set tMenu = ..%GetComponentById("analysisMenu")
		Set tSC = ..CreateAnalysisMenu(tMenu)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Pivot Analysis")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Analyze a cell within a Pivot Table.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		var iframe = zen('iframe');
		var doc = iframe.getDocument();
		doc.write($$$Text('Select an analysis option'));
	}
	catch(ex) {
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in ondialogFinish');
	}
	return true;
}

/// Click on a new analysis type.
ClientMethod selectAnalysisType(type) [ Language = javascript ]
{
	if (this.analysisType != type) {
		var a = self.document.getElementById('icon_' + this.analysisType);
		if (a) {
			a.className = 'Icon';
		}

		this.analysisType = type;
		var a = self.document.getElementById('icon_' + this.analysisType);
		if (a) {
			a.className = 'IconSelected';
		}

		// display the analysis
		var url = type + '.cls';
		url = url.replace(/\%DeepSee/,"_DeepSee");
		url = url.replace(/\%iKnow/,"_iKnow");
		url += '?CUBE=' + encodeURIComponent(this.cubeName);
		url += '&KEY=' + encodeURIComponent(this.queryKey);
		url += '&RANGE=' + encodeURIComponent(this.selectedRange);
		url += '&MEASURE=' + encodeURIComponent(this.measureName);
		url += '&SORTCOL=' + encodeURIComponent(this.sortColumn);
		url += '&SORTDIR=' + encodeURIComponent(this.sortDir);
		zen('iframe').setProperty('src',url);
	}
}

/// Return an array of all available analysis types
/// pInfo(n) = $LB(class,caption,tooltip,icon)
ClassMethod %GetAnalysisClasses(Output pInfo As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pInfo
		
		// find all subclasses of widget
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%DeepSee.UI.Analysis.AbstractAnalysis")
		If $$$ISERR(tSC) Quit
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tName = $G(tRS.Data("Name"))

			// make sure class is non-abstract and published
			Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
			Set tPublished = $zobjclassmethod(tName,"%GetParameter","PUBLISHED")
			If (('tAbstract) && tPublished) {
				Set tClasses(tName) = ""
			}
		}
		
		Set n = 0
		Set tClass = $O(tClasses(""))
		While (tClass'="") {
			Set n = n + 1
			Kill tInfo
			Set tSC = $zobjclassmethod(tClass,"%GetAnalysisInfo",.tInfo)
			If $$$ISERR(tSC) Quit

			Set tInfoList(n) = $LB(tClass,$G(tInfo("caption")),$G(tInfo("tooltip")),$G(tInfo("icon")),$G(tInfo("rank")))
			Set tClass = $O(tClasses(tClass))
		}
		
		// sort according to ranking
		Set k = $O(tInfoList(""))
		While(k'="") {
			Set tRanking = $LG(tInfoList(k),5)
			Set:tRanking="" tRanking = 999
			Set tRankedList((tRanking*1000)+k) = tInfoList(k)
			Set k = $O(tInfoList(k))
		}

		Set n = 0
		Set k = $O(tRankedList(""))
		While(k'="") {
			Set pInfo($I(n)) = tRankedList(k)
			Set k = $O(tRankedList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
