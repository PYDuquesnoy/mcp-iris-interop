/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
Class %CSP.Util.HTMLDashboardPane Extends (%CSP.Util.Pane, %ZEN.Portal.abstractRefreshable) [ ServerOnly = 1, System = 4 ]
{

/// Default domain for the Portal's localization.
Parameter DOMAIN = "%Utility";

/// Refresh rate for dashboard in milliseconds.
Property RefreshRate As %Integer [ InitialExpression = 5000 ];

/// Name of class that defines the callback method to provide data for dashboard.
Property MetricClass As %String(MAXLEN = 255) [ InitialExpression = "SYS.Metrics" ];

/// Name of callback method that provides data for dashboard.
Property MetricMethod As %String(MAXLEN = 64);

/// List of meters displayed by this dashboard.
Property Meters As list Of HTMLMeter(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Direction in which to layout meters within this dashboard.
Property Orientation As %String(MAXLEN = 10, VALUELIST = ",horizontal,vertical", XMLPROJECTION = "element") [ InitialExpression = "horizontal" ];

/// Show dashboard legend 
Property ShowLegend As %Boolean(XMLPROJECTION = "element") [ InitialExpression = 1 ];

/// Show dashboard icons
Property ShowIcons As %Boolean(XMLPROJECTION = "element") [ InitialExpression = 1 ];

/// Transient list of Meter objects
Property MeterObjects As %String(XMLPROJECTION = "NONE") [ MultiDimensional ];

/// Transient list of Meter classes
Property MeterClasses As %String(XMLPROJECTION = "NONE") [ MultiDimensional ];

Method DrawHEAD(pInstance As %CSP.Util.PageInstance) As %Status
{
	Merge tID = pInstance.IDValues

	Do ..BuildMeterLists()

	Set ..ShowIcons = 0 // always turn these off
	Set ..ShowLegend = 0

	// invoke meter callbacks
	Set cls = $O(..MeterClasses(""))
	While (cls '= "") {
		Do $classmethod(cls,"OnHTMLHead")
		Set cls = $O(..MeterClasses(cls))
	}

	// generic and specific meter styles
	&html<<style>

table.HTMLDashboardTable {
	background: #FFFFFF;
	font-size: 1px;
}

table.HTMLDashboardDetail {
	background: white;
	border: 1px solid #cbcbcb;
	border-radius: 5px;
}

table.HTMLDashboardDetail th {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
	border-bottom: 1px solid #cbcbcb;
	padding: 2px;
}

td.HTMLDashboardDetail {
	color: black;
	font-size: 12px;
	padding: 2px;
	padding-top: 5px;
	padding-bottom: 5px;
}

.HTMLMeterStatus {
	background: white;
	color: #333695;
}

.HTMLMeterStatusWARNING {
	background: orange;
	color: black;
}

.HTMLMeterStatusERROR {
	background: #da4848;
	color: yellow;
}

.HTMLMeterStatusDISABLED {
	background: #f7f7f7;
	color: #cbcbcb;
}

.HTMLMeterLabel {
	text-decoration: none;
	font-size: 12px;
	color: black;
}

.HTMLMeterLabel a:visited {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabel a:link {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabel a:active {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabel a:hover {
	text-decoration: none;
	color: #333695;
}

.HTMLMeterLabelSELECTED {
	text-decoration: none;
	font-size: 12px;
	font-weight: bold;
	color: black;
}

.HTMLMeterLabelSELECTED a:visited {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabelSELECTED a:link {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabelSELECTED a:active {
	text-decoration: none;
	color: black;
}

.HTMLMeterLabelSELECTED a:hover {
	text-decoration: none;
	color: blue;
}

.Legend {
	background: lightblue;
	border: 1px solid #cbcbcbk;
	padding: 0px;
	padding-right: 2px;
	font-size: 0.7em;
}

.Legend th {
	background: lightblue;
	border-bottom: 1px solid #cbcbcb;
	padding: 2px;
	text-align: left;
	padding-top: 5px;
}

.MessageText {
	color: darkgreen;
	font-style: italic;
}

.MessageTextDISABLED {
	color: #202020;
	font-style: italic;
}

.MessageTextWARNING {
	color: darkred;
	font-weight: bold;
}

.MessageTextERROR {
	color: red;
	font-weight: bold;
}

a.detailsLink {
	color: black;
}

a.detailsLink:hover {
	color: black;
	background: #FFEEAA;
}

	</style>>


	Write "<style>",!
	Set cls = $O(..MeterClasses(""))
	While (cls '= "") {
		Do $classmethod(cls,"OnHTMLStyle")
		Set cls = $O(..MeterClasses(cls))
	}
	Write "</style>",!
	Set msgDetails = $$$Text("Click on an item to display its details.")
	Set msgDetailsMore = $$$Text("Click here for more details")
	&html<
<script language="javascript">

// time used for refresh

var timerID = null;
var enableAutoRefresh = #($select(..enableAutoRefresh: "true", 1: "false"))#;
var refreshRate = (enableAutoRefresh) ? #(..RefreshRate)# : 0;

var refreshCount = 1;
var pageID = '#($ZCVT($G(tID(1)),"O","JS"))#';

// called when dashboard page is loaded
function initDashboard()
{
	startAutoRefresh();
	showDetail(null);
}

// call this to dynamically refresh the dashboard
function refreshDashboard()
{
	if (timerID) {
		self.clearTimeout(timerID);
	}
	// build request to send to server
	var list = '';
	for (var n = 0; n < meterList.length; n++) {
		var meter = meterList[n];
		if ('' != meter.property) {
			list += ((n>0) ? "^" : "") + meter.id + ":" + meter.property + ":" + meter.elements;
		}
	}

	callServerRefresh(list);
	refreshCount++;
}

// set a property for a specific dashboard meter
function document_setMeterProperty(meterid, property, value, status, msg)
{
	// dispatch to meter method
	var meter = meterList[meterid];
	if (meter) {
		var update = (status != meter.status) || (msg != meter.message);
		meter.status = status;
		meter.message = msg;
		meter.setProperty(property, value, status);
		
		if (update && (currMeterId == meter.id)) {
			// update details
			showDetail(meter);
		}
	}
}

function setLastUpdate(time)
{
	var el = self.document.getElementById("lastUpdate");
	if (el) {
		el.innerHTML = time;
	}
}

function startAutoRefresh()
{
	if (refreshRate != 0 && enableAutoRefresh) {
		timerID = self.setTimeout("refreshDashboard()",refreshRate);
	}
}

var currMeterId = null;

/// update status indicator for meter
function setMeterStatus(id, status)
{
	var img = self.document.getElementById("indicator_" + id);
	if (img) {
		switch (status) {
		case 'ERROR':
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/dashboard-error.gif"))#';
			break;
		case 'WARNING':
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/dashboard-warning.gif"))#';
			break;
		case 'DISABLED':
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#';
			break;

		default:
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/dashboard-ok.gif"))#';
			break;
		}
	}
}

/// select a given meter
function selectMeter(id)
{
	if (null != currMeterId) {
		// unselect old meter
		var img = self.document.getElementById("selector_" + currMeterId);
		if (img) {
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#';
		}
		var label = self.document.getElementById("label_" + currMeterId);
		if (label) {
			label.className = 'HTMLMeterLabel';
		}
	}

	currMeterId = id;
	if (currMeterId) {
		// select new meter
		var img = self.document.getElementById("selector_" + currMeterId);
		if (img) {
			img.src = '#(##class(%CSP.Page).Link("/csp/sys/images/dashboard-select.gif"))#';
		}
		var label = self.document.getElementById("label_" + currMeterId);
		if (label) {
			label.className = 'HTMLMeterLabelSELECTED';
		}

		if (meterList[currMeterId]) {
			showDetail(meterList[currMeterId]);
		}
	}
}

function showDetail(meter)
{
	var detail = self.document.getElementById("DetailHTML");
	var link = self.document.getElementById("DetailLink");
	var label = self.document.getElementById("DetailLabel");
	var message = self.document.getElementById("MessageHTML");

	if (detail && link && label) {
		if (null == meter) {
			// default message
			detail.innerHTML = '<i>#($ZCVT($ZCVT(msgDetails,"O","HTML"),"O","JS"))#</i>';
			link.innerHTML = '&nbsp;';
			label.innerHTML = '&nbsp;';
			message.innerHTML = '&nbsp;';
		}
		else {
			detail.innerHTML = ('' != meter.detail) ? meter.detail : '&nbsp;';
			link.innerHTML = ('' != meter.link) ? ('<a class="detailsLink" href="' + meter.link + '">#($ZCVT($ZCVT(msgDetailsMore,"O","HTML"),"O","JS"))#</a>') : '&nbsp;';
			label.innerHTML = ('' != meter.label) ? meter.label : '&nbsp;';
			message.innerHTML = ('' != meter.message) ? meter.message : '&nbsp;';
			message.className = 'MessageText' + meter.status;
		}
	}
}

</script>>

	// write out methods that perform the hyper-calls
	Write "<script language=""javascript"">",!
	Write "function callServerRefresh(list)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall("%CSP.Util.HTMLDashboardPane.RefreshDashboard","'"_..MetricClass_"','"_..MetricMethod_"',pageID,refreshCount,list",0)
 	Write ";",!
	Write "}",!

	// write out client-side meter object create code

	Write "// construct meter objects",!
	&js<
var meterList = new Array();
	>

	// Get initial list of property values
	Set tSC = ..CalculatePropertyValues($G(tID(1)),0,..MetricClass, ..MetricMethod, .tValues, .tStatus, .tMsg)

	// specific js code for each meter
	Set id = $O(..MeterObjects(""))
	While (id '= "") {
		Set tMeter = ..MeterObjects(id)
		Set tMeter.MeterId = id - 1
		Set:(tMeter.Property'="") tMeter.InitialValue = $G(tValues(tMeter.Property))
		Set:(tMeter.Property'="") tMeter.InitialStatus = $G(tStatus(tMeter.Property))
	
		// create meter object & links to methods
		&js<

// -------------------------------
// meter: #(id)#
var meter = new Object();
meterList[#(id-1)#] = meter;
meter.id = #(id-1)#;
meter.type = '#($ZCVT(tMeter.%ClassName(),"O","JS"))#';
meter.label = '#($ZCVT(tMeter.Label,"O","JS"))#';
meter.detail = '#($ZCVT(tMeter.Detail,"O","JS"))#';
meter.link = '#($ZCVT(tMeter.Link,"O","JS"))#';
meter.property = '#($ZCVT(tMeter.FullProperty,"O","JS"))#';
meter.level = '';
meter.elements = '';
meter.message = '#($ZCVT($S(tMeter.Property'="":$G(tMsg(tMeter.Property)),1:""),"O","JS"))#';
meter.status = '#($ZCVT(tMeter.InitialStatus,"O","JS"))#';
		>

		// setProperty method: based on class name
		Write "meter.setProperty = ",tMeter.%ClassName(0),"_setProperty;",!

		// callback to get user JS
		Do tMeter.OnHTMLInitJS()

		Set id = $O(..MeterObjects(id))
	}

	// write out meter specific js
	Set cls = $O(..MeterClasses(""))
	While (cls '= "") {
		Do $classmethod(cls,"OnHTMLScript")
		Set cls = $O(..MeterClasses(cls))
	}

	Write "</script>",!
	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As %CSP.Util.PageInstance) As %Status
{
	Set $ZT = "Trap"
	
	Merge tID = pInstance.IDValues

	Set updatemsg = $ZCVT($S(##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled():$$$Text("Last auto-update: "),1:$$$Text("Last update: ")),"O","HTML")
	Set updatehelp = $ZCVT($$$Text("Click here to refresh this table."),"O","HTML")

	Do ..DrawCommands(pInstance)
	
	If (..Text '= "") {
		&html<<table border="0" cellpadding="3" cellspacing="0" width="90%"><tr>
			<td valign="bottom" class="Text1"><div>#($ZCVT(..LocalizeText(..Text),"O","HTML"))#</div></td>
			<td align="left" class="Text" nowrap width="30%" style='cursor:pointer;'>
			<div align="left" width="100%" style="padding-top:6px;">
			<a title="#(updatehelp)#" class="LastUpdate" onclick="refreshDashboard();">
			#(updatemsg)#<b>
			<span id="lastUpdate">#($ZDT($ZU(188),3,,3))#</span></b>&nbsp;</a>
			</div>
			</td>
			<td>&nbsp;</td>
			</tr></table>
		<br>>
	}

	&html<<table class="HTMLDashboardTable" border="0" cellspacing="0" cellpadding="0">>

	If (..Orientation = "horizontal") { &html<<tr>> }

	// Draw meter HTML (top-level items only)
	Set id = $O(..MeterObjects(""))
	While (id '= "") {
		Set tMeter = ..MeterObjects(id)
		If (tMeter.Parent = "") {
			If (..Orientation '= "horizontal") { &html<<tr>> }
			&html<<td width="#(tMeter.Width)#">>
			Do tMeter.OnHTMLBody()
			&html<</td>>
			If (..Orientation '= "horizontal") { &html<</tr>> }
		}
		Set id = $O(..MeterObjects(id))
	}

	If (..Orientation = "horizontal") { &html<</tr>> }

	&html<</table>>

	Set lblSelectItem = $ZCVT($$$Text("Details for selected item"),"O","HTML")
	// details
	&html<<br>
	<hr style="color:#cbcbcb;">
	<br>
	<table border="0" cellspacing="0" cellpadding="0" width="90%">
	<tr>
	<td width="50%">
	<table class="HTMLDashboardDetail" border="0" cellspacing="0" cellpadding="0" width="100%" height="100%">
	<tr>
		<th align="left" width="45%">#(lblSelectItem)#:</th>
		<th align="left" nowrap id="DetailLabel" style="color:#404080;">&nbsp;</th>
		<th align="right" nowrap id="DetailLink" width="50%">&nbsp;</th>
	</tr>
	<tr height="50"><td align="left" colspan="3" class="HTMLDashboardDetail" id="DetailHTML">&nbsp;</td>
	<tr height="50"><td align="left" colspan="3" class="HTMLDashboardDetail"><span id="MessageHTML" class="MessageText">&nbsp;</span></td>
	<tr><td colspan="3" class="HTMLDashboardDetail">&nbsp;</td>
	</tr>
	</table>
	
	</td>
	<td width="40">&nbsp;</td>>

	/*
	If (..ShowLegend) {
		&html<
		<!-- legend -->
		<td>
			<table class="Legend" border="0" cellspacing="0" cellpadding="1">
			<tr><th colspan="2" align="left">Legend</th></tr>
			<tr>
				<td class="HTMLMeterStatus" style="border-right: 1px solid gray">
				<image src="#(..Link("/csp/sys/images/dashboard-ok.gif"))#">&nbsp;</td>
				<td valign="bottom">&nbsp;These items are functioning correctly&nbsp;</td>
			</tr>
			<tr>
				<td class="HTMLMeterStatusWARNING" style="border-right: 1px solid gray">
				<image src="#(..Link("/csp/sys/images/dashboard-warning.gif"))#">&nbsp;</td>
				<td valign="bottom">&nbsp;These items should be investigated&nbsp;</td></tr>
			<tr>
				<td class="HTMLMeterStatusERROR" style="border-right: 1px solid gray">
				<image src="#(..Link("/csp/sys/images/dashboard-error.gif"))#">&nbsp;</td>
				<td valign="bottom">&nbsp;These items have encountered problems&nbsp;</td>
			</tr>
			<tr>
				<td class="HTMLMeterStatusDISABLED" style="border-right: 1px solid gray">
				<image src="#(..Link("/csp/sys/images/spacer.gif"))#" width="24">&nbsp;</td>
				<td valign="bottom">&nbsp;These items are either disabled or not in use&nbsp;</td>
			</tr>
			</table>
		</td>>
	}
	*/
	&html<</tr></table>>

	Write "<script language=""javascript"">",!
	Write "initDashboard();",!

	// specific js init code for each meter
	Set id = $O(..MeterObjects(""))
	While (id '= "") {
		Set tMeter = ..MeterObjects(id)
		set initVal = $ZCVT(tMeter.InitialValue,"O","HTML")
		set initVal = $REPLACE(initVal,"&amp;nbsp;","&nbsp;")
		set initVal = $REPLACE(initVal,$c(10),"<br>")
		set initVal = $ZCVT(initVal,"O","JS")
		Write "meterList[",id-1,"].setProperty('level','",initVal,"','",$ZCVT($ZCVT(tMeter.InitialStatus,"O","HTML"),"O","JS"),"');",!
		Set id = $O(..MeterObjects(id))
	}

	Write "</script>",!

Done
	Quit $$$OK

Trap
	Set $ZT=""
	// display error
	&html<<div class="Error">#("Error rendering Dashboard: " _ $ZCVT($ZE,"O","HTML"))#</div>>
	Goto Done
}

/// Build list of meter objects and classes
Method BuildMeterLists() [ Private ]
{
	// make list of all meter objects (flattened)
	Set id = 1
	Set stackptr = 1
	Set tGroup(stackptr) = $this
	Set tProperty(stackptr) = ""
	Set tNum(stackptr) = 1
	Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))

	While ((stackptr > 0) && $IsObject(tMeter)) {
		Set objects(id) = tMeter
		Set tMeter.MeterId = id
		Set objParent(id) = $S(tGroup(stackptr)=$this:"",1:tGroup(stackptr))
		Set id = id + 1

		// calculate full property name (with leading group)
		Set tMeter.FullProperty = tProperty(stackptr) _ tMeter.Property

		// find next item
		If (tMeter.%IsA("%CSP.Util.HTMLGroup")) {
			// recurse
			Set stackptr = stackptr + 1
			Set tGroup(stackptr) = tMeter
			Set tProperty(stackptr) = tProperty(stackptr-1) _ $S(tMeter.Property="":"",1:tMeter.Property_".")
			Set tNum(stackptr) = 1
			Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
		}
		Else {
			Set tNum(stackptr) = tNum(stackptr) + 1
			Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
		}

		// do we need to pop items off the stack
		While ((stackptr > 0) && '$IsObject(tMeter)) {
			Set stackptr = stackptr - 1
			If (stackptr > 0) {
				Set tNum(stackptr) = tNum(stackptr) + 1
				Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
			}
		}
	}

	// make list of all meter classes
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)
		Set classes(meter.%ClassName(1)) = ""
		Set id = $O(objects(id))
	}

	Merge ..MeterObjects = objects
	Merge ..MeterClasses = classes
}

/// Subclasses override this to generate code during CSP processing
Method OnGenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tPane.MetricClass = """ _ ..MetricClass _ """"_ $$$EOL
	Set code = code _ " Set tPane.MetricMethod = """ _ ..MetricMethod _ """"_ $$$EOL
	Set code = code _ " Set tPane.Orientation = """ _ ..Orientation _ """" _ $$$EOL
	Set code = code _ " Set tPane.ShowLegend = " _ +..ShowLegend _ $$$EOL
	Set code = code _ " Set tPane.ShowIcons = " _ +..ShowIcons _ $$$EOL

	If (..RefreshRate '= "") {
		Set code = code _ " Set tPane.RefreshRate = " _ +..RefreshRate _ $$$EOL
	}

	Set tStream = ##class(%GlobalCharacterStream).%New()
	For i = 1:1:..Meters.Count() {
		Set tMeter = ..Meters.GetAt(i)
		Do tStream.WriteLine(" Set tMeter = ##class(" _ tMeter.%ClassName(1) _ ").%New()")
		Do tStream.WriteLine(" Do tPane.Meters.Insert(tMeter)")
		Do tStream.WriteLine(" Set tMeter.Dashboard = tPane")
		Set tSC = tMeter.GenerateCode(tStream)
	}
	#;YSD2871 Set code = code _ tStream.Read(20000)
	Set code = code _ tStream.Read(32000)
	Quit code
}

/// Called from client to refresh the dashboard
ClassMethod RefreshDashboard(pMetricClass As %String, pMetricMethod As %String, pID As %String, pLastCount As %String, metricList As %String)
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		If (metricList = "") {
			Quit
		}

		// Get list of property values
		Set tSC = ..CalculatePropertyValues(pID, pLastCount, pMetricClass, pMetricMethod,.tValues,.tStatus,.tMsg)

		// metricList contains list of property values to fetch
		// id:property:elements^id:property:elements
		For n = 1:1:$L(metricList,"^") {
			Set id = $P($P(metricList,"^",n),":",1)
			Set prop = $P($P(metricList,"^",n),":",2)
			Set elements = $P($P(metricList,"^",n),":",3)
			If ((prop '= "") && $D(tValues(prop))) {
				// if prop is in update list, notify client
				Set tValue = $ZCVT(tValues(prop),"O","JS")
				Set tStat = $ZCVT($G(tStatus(prop)),"O","JS")
				Set tMsg = $ZCVT($G(tMsg(prop)),"O","JS")
				Write "CSPPage.document_setMeterProperty(",id,",'level','",tValue,"','",tStat,"','",tMsg,"');",!
			}
		}
	} While(0)
	
	// last update
	Set tTime = $ZDT($ZU(188),3,,3)
	&js<CSPPage.setLastUpdate('#(tTime)#');>

	// restart time
	
	If ##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled() {
		&js<if (CSPPage.refreshRate &gt; 0) {
			CSPPage.timerID = CSPPage.setTimeout("refreshDashboard()",CSPPage.refreshRate);
		}
		>
	}

Done
	Quit

Trap
	Set $ZT = ""
	&js<alert("RefreshDashboard Error: #($ZE)#");>
	Goto Done
}

/// This callback is responsible for returning the set of property values
/// for the dashboard.<br>
/// On exit, <var>pValues</var> contains list of values indexed by property name.<br>
/// <var>pStatus</var> contains list of status values indexed by property name.<br>
/// <var>pMsg</var> contains a status message indexed by property name.<br>
/// This invokes the callback specified by the MetricClass and MetricProperty properties.
ClassMethod CalculatePropertyValues(pID As %String, pLastCount As %Integer, pMetricClass As %String, pMetricMethod As %String, Output pValues As %String, Output pStatus As %String, Output pMsg As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		// dispatch to specified callback
		Set tSC = $classmethod(pMetricClass,pMetricMethod,pID,pLastCount,.pValues,.pStatus,.pMsg)
		If $$$ISERR(tSC) Quit

	} While(0)
Done
	Quit tSC

Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Done
}

}
