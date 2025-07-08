/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.SQL.QButtons.RuntimeStatsDetails Extends (%ZEN.Portal.standardPage, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "SQL PTools View Stats Details";

Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

Property CursorName As %String(ZENURL = "CursorName");

Property RoutineName As %String(ZENURL = "RoutineName");

Property PlanPage As %ZEN.Datatype.string [ InitialExpression = {$P(..Link("%25SQL.Manager.ShowPlan.cls"),"?$NAMESPACE",1)} ];

Property PrintImage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/broker/deepsee/printer_24.png")} ];

XData Style
{
<style type="text/css">
div.pageTitle {
	display: table;
	width: 100%;
	table-layout: fixed;   /* for cells of equal size */	
}
div.pageTitle span {
    display: table-cell;
    text-align: center;
    vertical-align: middle;
}
#propertyPane {
	background: white;
	height: 100%;
	width: 100%;
	border-right: none;
	border-bottom: none;
	margin: 20px;
	display: none;
}
#propertyTitle {
	height: 130px;
	width: 100%;
	overflow:auto;
}
/* --- Query Text --- */
.qp-header {
   color: white;
   width: 100%;
   height: 20px;
   
   text-align: center;
   vertical-align: bottom;
   font-size: 16px;
   font-weight: bold;
}

.qp-query-text-header {
   /* Use CSS 'qp-header' first in the class definition */
   background: rgb(53,107,141); /* For browsers that do not support gradients */
   background: -webkit-linear-gradient(rgb(53,107,141),rgb(23,77,101)); /* For Safari 5.1 to 6.0 */
   background: -o-linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	  /* For Opera 11.1 to 12.0 */
   background: -moz-linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	  /* For Firefox 3.6 to 15 */
   background: linear-gradient(rgb(53,107,141),rgb(23,77,101)); 	 	  /* Standard syntax (must be last) */
}

.qp-query-text-body {
   text-align: left;
   font-family: monospace;
   white-space: normal;
  
   padding-top:    0px;
   padding-left:   5px;
   padding-bottom: 5px;	
   
   margin-top: 0px;
}

.qp-query-text-body pre {
   vertical-align: top;
   text-align: left;
   white-space: normal;
   
   margin-top: 3px;
}
.mt-20 {
	margin-top: 20px;
}
#propRoutine {
	font-size: 1.2em;	
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen">
<jsonProvider id="jsonQueryInfo" OnGetTargetObject="GetQueryInfo">
<parameter paramName="parmNamespace" value="#(%page.NAMESPACE)#"/>
<parameter paramName="parmCursorName" value="#(%page.CursorName)#"/>
<parameter paramName="parmRoutineName" value="#(%page.RoutineName)#"/>
 </jsonProvider>

<html>
<div class="pageTitle portalTitle">
<span id="loginname">User:</span>
<span id="server">Server:</span>
<span id="instance">Instance:</span>
<span id="namespace">Namespace:</span>
</div>
</html>
<vgroup id="propertyPane" valign="top">
<html>
<div>
<span id="propRoutine">routine</span>
<span align="right" valign="top" style="margin-right:8px;float:right;">
<a id="idPrint" href="javascript:window.print();" title="" target="_top" style="pointer-events:auto;cursor:pointer;">
	<img id="printImage" src="" width="24" height="24" border="0"/></a>
</span>
</div>
<div id="statementTitle" class="qp-header qp-query-text-header">statement title</div>
<div class="qp-query-text-body">
<pre id="queryText">
queryText
</pre>
</div>
<div id="statsTitle" class="mt-20 qp-header qp-query-text-header">stats title</div>
</html>

<tablePane id="tableDetails"
queryClass="%SYS.PTools.StatsSQL"
queryName="ViewStatsSQLDetails"
cellSpacing="1"
dataSource="columns"
fixedHeaders="false"
multiSelect="false"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="QueryText"
useSnapshot="true"
initialExecute="false"
>
<column colName="QueryText" hidden="true"/>
<column colName="RunCount" header="Run Count"/>
<column colName="ModuleName" header="Module Name"/>
<column colName="AvgModCount" header="Avg Module Exec Count"/>
<column colName="AvgRows" header="Avg Rows"/>
<column colName="AvgGlobalRefs" header="Avg Global Refs"/>
<column colName="AvgCommands" header="Avg Commands"/>
<column colName="AvgDiskWait" header="Avg Disk Wait"/>
<column colName="AvgTime" header="Avg Time"/>

<parameter value=""/>
<parameter value=""/>
</tablePane>
<iframe id="outputShowplan3" valign="top" containerStyle="padding-top:10px;"/>

</vgroup>

</page>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	this.adjustSizes();
	var json = zen('jsonQueryInfo').getContentObject();
	if (json.error) {
		alert("Unexpected error occurred trying to obtain query data: "+json.error);
		return;	
	}

	if (json && json.queryText) {
		document.getElementById("queryText").innerHTML = json.queryText;
	}
	
	var table = zen("tableDetails");
	table.parameters[0].value = this.CursorName;
	table.parameters[1].value = this.RoutineName;
	table.executeQuery();

	if (json && json.prepareShowPlan) {
		var planlink = this.PlanPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&stats=2&verbose=1";
		zen('outputShowplan3').setProperty('src',planlink);
	}

	this.loadLocalizedStrings(json);

	var propDiv = zen('propertyPane').getEnclosingDiv();
	propDiv.style.display = 'block';
}

ClientMethod loadLocalizedStrings(json) [ Language = javascript ]
{
	document.getElementById("loginname").innerHTML = json.user;
	document.getElementById("server").innerHTML = json.server;
	document.getElementById("instance").innerHTML = json.instance;
	document.getElementById("namespace").innerHTML = json.namespace;
	
	document.getElementById("propRoutine").innerHTML = json.routine;
	document.getElementById("statementTitle").innerHTML = zenText("statementTitle");
	document.getElementById("statsTitle").innerHTML = zenText("statsTitle");
	
	document.getElementById("printImage").src = this.PrintImage;
	document.getElementById("idPrint").title = zenText("printTooltip");
}

ClientMethod adjustSizes() [ Language = javascript ]
{

	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var propDiv = zen('propertyPane').getEnclosingDiv();			
		propDiv.style.width = (winWidth - 58) + 'px';
	
		var th = 100;
		var hgt = winHeight - th - 100;
		var tabBodyHgt = (hgt - 30);

		tabBodyHgt = (tabBodyHgt < 141 ? 141 : tabBodyHgt);
		propDiv.style.height = tabBodyHgt - 100 + 'px';

		frame = zen("outputShowplan3");
		frame.setProperty("width",propDiv.style.width);
		frame.setProperty("height",tabBodyHgt - 140 + 'px');

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Return query information to the client. 
Method GetQueryInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tNamespace = pParms("parmNamespace")
		Set tCursorName = pParms("parmCursorName")
		Set tRoutineName = pParms("parmRoutineName")
		Set tSC = ##class(%CSP.UI.Portal.SQL.QButtons.Utils).GetQueryData(tNamespace, tCursorName, tRoutineName, .pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("statementTitle") = $$$TextHTML("SQL Statement")
	Set pResources("statsTitle") = $$$TextHTML("Query Statistics")
	Set pResources("printTooltip") = $$$TextHTML("Print this page")
	Quit $$$OK
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	this.adjustSizes();
}

}
