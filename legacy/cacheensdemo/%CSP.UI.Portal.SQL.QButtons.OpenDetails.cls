/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.SQL.QButtons.OpenDetails Extends (%ZEN.Portal.standardPage, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "SQL PTools Open Details";

Property NAMESPACE As %String(ZENURL = "$NAMESPACE");

/// ID for %SQL.Manager.QButtons.Base
Property PID As %String(ZENURL = "PID");

Property PlanPage As %ZEN.Datatype.string [ InitialExpression = {..Link("%25CSP.UI.Portal.SQL.QButtons.ShowPlanOutput.zen")} ];

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
/*  make a table using CSS only */
div.prop {
	display: table;
	margin: auto;
	align: center;
}
div.prop div.rowGroup {
	display: table-row-group;	
}
div.prop div.row {
	display: table-row;	
}
div.prop div.caption {
	border-bottom: 1px solid #848482;
	display: table-cell;
	width: 30%;
}
div.prop div.value {
	border-bottom: 1px solid #848482;
	display: table-cell;
	width: 70%;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen">
<jsonProvider id="jsonQueryInfo" OnGetTargetObject="GetQueryInfo">
<parameter paramName="parmNamespace" value="#(%page.NAMESPACE)#"/>
<parameter paramName="parmPID" value="#(%page.PID)#"/>
 </jsonProvider>

<html>
<div class="pageTitle portalTitle">
<span id="loginname">User:</span>
<span id="server">Server:</span>
<span id="instance">Instance:</span>
<span id="namespace">Namespace:</span>
</div>
</html>
<html>
<div align="right" valign="top" style="margin-top:8px;margin-right:8px;float:right;">
<a id="idPrint" href="javascript:window.print();" title="" target="_top" style="pointer-events:auto;cursor:pointer;">
<img id="printImage" src="" width="24" height="24" border="0"/></a>
</div>
</html>
<vgroup id="propertyPane" valign="top">
<html>
<div id="statementTitle" class="qp-header qp-query-text-header">statement title</div>
<div class="qp-query-text-body">
<pre id="queryText">
queryText
</pre>
</div>

<div id="statsTitle" class="mt-20 qp-header qp-query-text-header">properties</div>
<div class="prop">

<div class="rowGroup row">
<div class="caption" id="WRCNumber">wrc</div>
<div class="value" id="WRCNumberValue">value</div>
</div>


<div class="rowGroup">
<div class="row">
<div class="caption" id="ClassList">class</div>
<div class="value" id="ClassListValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="TimeInserted">time</div>
<div class="value" id="TimeInsertedValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="UserInserted">user</div>
<div class="value" id="UserInsertedValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="AllowDelimitedIdentifiers">allow</div>
<div class="value" id="AllowDelimitedIdentifiersValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="DefaultSchema">schema</div>
<div class="value" id="DefaultSchemaValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="VersionString">version</div>
<div class="value" id="VersionStringValue">value</div>
</div>
</div>

<div class="rowGroup">
<div class="row">
<div class="caption" id="BackgroundJobNumber">jobnumber</div>
<div class="value" id="BackgroundJobNumberValue">value</div>
</div>
</div>

</div> <!-- End of Prop table -->

</html>

<iframe id="outputShowplan3" valign="top" containerStyle="padding-top:10px;"/>

</vgroup>

</page>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.adjustSizes();
	var json = zen('jsonQueryInfo').getContentObject();
	//alert(JSON.stringify(json));
	if (json.error) {
		alert("Unexpected error occurred trying to obtain query data: "+json.error);
		return;	
	}
	
	if (json.queryText) {
		document.getElementById("queryText").innerHTML = json.queryText;
	}
	var planlink = this.PlanPage + "?namespace="+encodeURIComponent(this.NAMESPACE)+"&jobNumber="+json.jobNumber+"&status=done";
	zen('outputShowplan3').setProperty('src',planlink);

	this.loadLocalizedStrings(json);

	document.getElementById("WRCNumberValue").innerHTML = json.WRCNumber;
	document.getElementById("ClassListValue").innerHTML = json.ClassList;
	document.getElementById("TimeInsertedValue").innerHTML = json.TimeInserted;	
	document.getElementById("UserInsertedValue").innerHTML = json.UserInserted;
	document.getElementById("AllowDelimitedIdentifiersValue").innerHTML = json.AllowDelimitedIdentifiers;
	document.getElementById("DefaultSchemaValue").innerHTML = json.DefaultSchema;
	document.getElementById("VersionStringValue").innerHTML = json.VersionString;
	document.getElementById("BackgroundJobNumberValue").innerHTML = json.jobNumber;
		
	var propDiv = zen('propertyPane').getEnclosingDiv();
	propDiv.style.display = 'block';
}

ClientMethod loadLocalizedStrings(json) [ Language = javascript ]
{
	document.getElementById("loginname").innerHTML = json.user;
	document.getElementById("server").innerHTML = json.server;
	document.getElementById("instance").innerHTML = json.instance;
	document.getElementById("namespace").innerHTML = json.namespace;
	
	document.getElementById("statementTitle").innerHTML = zenText("statementTitle");
	document.getElementById("statsTitle").innerHTML = zenText("statsTitle");
	
	document.getElementById("printImage").src = this.PrintImage;
	document.getElementById("idPrint").title = zenText("printTooltip");

	document.getElementById("WRCNumber").innerHTML = zenText("WRCNumber");
	document.getElementById("ClassList").innerHTML = zenText("ClassList");
	document.getElementById("TimeInserted").innerHTML = zenText("TimeInserted");	
	document.getElementById("UserInserted").innerHTML = zenText("UserInserted");
	document.getElementById("AllowDelimitedIdentifiers").innerHTML = zenText("AllowDelimitedIdentifiers");
	document.getElementById("DefaultSchema").innerHTML = zenText("DefaultSchema");
	document.getElementById("VersionString").innerHTML = zenText("VersionString");
	document.getElementById("BackgroundJobNumber").innerHTML = zenText("BackgroundJobNumber");
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
		Set pNamespace = pParms("parmNamespace")
		Set PID = pParms("parmPID")
		Set tObj = ##class(%SQL.Manager.QButtons.Base).%OpenId(PID)
		If '$IsObject(tObj) {
			Quit	
		}
		Set ClassList = tObj.ClassList.Count()
		Set tClasses = ""
		If ClassList > 0 {
			For n = 1:1:ClassList {
				Set tClasses = tClasses _ $S(tClasses'="":", ",1:"") _ tObj.ClassList.GetAt(n)
			}
		}
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		Set pObject.children = ##class(%ListOfObjects).%New()
		Set pObject.server = $$$FormatText($$$Text("Server: %1"), $zu(110))
		Set pObject.instance = $$$FormatText($$$Text("Instance: %1"), $P($zu(86),"*",2))
		Set pObject.namespace = $$$FormatText($$$Text("Namespace: %1"), pNamespace)
		Set pObject.user = $$$FormatText($$$Text("User: %1"), $Username)
		Set pObject.queryText = tObj.QueryStatement
		Set pObject.jobNumber = tObj.BackgroundJobNumber
		Set pObject.WRCNumber = tObj.WRCNumber
		Set pObject.ClassList = tClasses
		Set pObject.TimeInserted = tObj.TimeInserted	
		Set pObject.UserInserted = tObj.UserInserted
		Set pObject.AllowDelimitedIdentifiers = tObj.AllowDelimitedIdentifiers_ " ("_$S(tObj.AllowDelimitedIdentifiers=1:$$$TextHTML("Yes"),1:$$$TextHTML("No"))_")"
		Set pObject.DefaultSchema = tObj.DefaultSchema
		Set pObject.VersionString = tObj.VersionString

		Set tJobNumber = tObj.BackgroundJobNumber
		Set tCount = tObj.QueryPlanArray.Count()
		If (tCount > 0) && ('$D($$$TempMgtPortalTask(tJobNumber,"%plan"))) {
			For i=1:1:tCount {
				Set $$$TempMgtPortalTask(tJobNumber,"%plan", i) = tObj.QueryPlanArray.GetAt(i)
			}
			Set $$$TempMgtPortalTask(tJobNumber,"%plan") = tCount		
			Set frozenplan = 0
			Set minStats = 1
			Set stats = 2
			Set cssLinkHref = "/csp/sys/intersystems.css"
			Set $$$TempMgtPortalTask(tJobNumber,"params") = frozenplan_"^"_minStats_"^"_stats_"^"_cssLinkHref_"^"_tJobNumber
		}

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
	Set pResources("statsTitle") = $$$TextHTML("Properties")
	Set pResources("printTooltip") = $$$TextHTML("Print this page")
	Set pResources("WRCNumber") = $$$TextHTML("WRC Number:")
	Set pResources("ClassList") = $$$TextHTML("Class List:")
	Set pResources("TimeInserted") = $$$TextHTML("Time Inserted:")
	Set pResources("UserInserted") = $$$TextHTML("User Inserted:")
	Set pResources("AllowDelimitedIdentifiers") = $$$TextHTML("Allow Delimited Identifiers:")
	Set pResources("DefaultSchema") = $$$TextHTML("Default Schema:")
	Set pResources("VersionString") = $$$TextHTML("Version:")
	Set pResources("BackgroundJobNumber") = $$$TextHTML("Background Job Number:")
	Quit $$$OK
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	this.adjustSizes();
}

}
