/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Database Details 
Class %CSP.UI.Portal.DatabaseDetails Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.DatabaseDetails.zen";

Parameter HELPADDRESS = "Home,Databases,Database Info";

/// Displayed name of this page.
Parameter PAGENAME = "Operation DatabaseDetails";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.OpDatabases.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// Database Directory
Property Directory As %String(ZENURL = "$ID1");

/// Database Name
Property DBName As %String(ZENURL = "DBName");

/// this page's link with Directory and DBName
Property DatabaseDetailsPage As %String;

Property BackgroundPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen",,1)} ];

Property CompactDialog As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Background.Dialog.DatabaseCompact.zen",,1)} ];

Property DefragDialog As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Background.Dialog.DatabaseDefragment.zen",,1)} ];

/// parent page link
Property DatabasesPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/op/%CSP.UI.Portal.OpDatabases.zen")} ];

Property TaskInfoDialog As %String [ InitialExpression = {..Link("/csp/sys/%CSP.UI.Portal.Background.Dialog.TaskInfo.zen",,1)} ];

Property TruncateDialog As %ZEN.Datatype.string [ InitialExpression = {..Link("%CSP.UI.Portal.Background.Dialog.DatabaseTruncate.zen",,1)} ];

/// ID for Systems background task id 
Property SysBGTaskId As %String;

/// Server-side reference to the pane object so that the head and body sections can be added to the page correctly.
Property %Pane As %CSP.Util.Pane [ ServerOnly = 1 ];

/// Flag to indicate whether <property>%Pane</property>'s OnDrawHEAD() method has been executed.
Property paneDone As %Boolean;

Property msgDismount As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to dismount database %1?")} ];

Property AllowMount As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

Property AllowDismount As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

Property BackgroundTasks As %ZEN.Datatype.integer [ InitialExpression = "0" ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}

TABLE.DetailTable	{ 
	border: 1px #888888 solid;
	border-collapse: collapse;
	font-size: 0.9em;
	width: 50%;
}
TABLE.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: left;
}
TABLE.DetailTable TR {
	 cursor: pointer;
	 background: #b8d1f3;
	 border-top: 1px #888888 solid;
}
TABLE.DetailTable TR:hover {
	 background: #ffff99;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<timer id="taskTimer" timeout="0" ontimeout="zenPage.taskTimeout();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>

<group id="page_1" width="100%">
<html id="taskBlock" OnDrawContent="DrawTasks" seed="#(%page.Directory)#"/>
<html id="detailBlock" OnDrawContent="DrawDetails"/>
</group>
<spacer height="20"/>
<group id="idVolumeFile" enclosingClass="EditForm" cellStyle="padding:5px;"  labelPosition="left" hidden="true">
<hgroup label="Show Volume Files by:">
 <radioSet id="tableviewSwitch" valueList="0,1" displayList="Volume Number,Directory" originalValue="0" value="0" onchange="zenPage.doTableViewSwitch();"/>
 </hgroup>
<hgroup id="idVolumeFiles" label="Volume Files:" >
<tablePane id="tablebydir" hidden="true"
queryClass="SYS.Database"
queryName="VolumeFiles"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="221"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="false"
>
<column colName="VolumeDirectory" header="Directory"/>
 <column colName="VolumeNumber" hidden="true"/>
<column colName="VolumeDirectoryTotalSize" header="Total Size" OnDrawCell="DrawSize"/>
 <column colName="File" header="File Name"/>
 <column colName="Size" header="File Size" OnDrawCell="DrawSize"/>
 <column colName="DiskFree" header="Disk Free Space" OnDrawCell="DrawSize"/>
<parameter value="#(%page.Directory)#"/>
<parameter value="1"/>
</tablePane>
<tablePane id="tablebyvol"
queryClass="SYS.Database"
queryName="VolumeFiles"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="201"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
useSnapshot="false"
>
 <column colName="VolumeNumber" header="Volume Number"/>
<column colName="VolumeDirectory" header="Directory"/>
 <column colName="VolumeDirectoryTotalSize" hidden="true"/>
 <column colName="File" header="File Name"/>
 <column colName="Size" header="File Size" OnDrawCell="DrawSize"/>
 <column colName="DiskFree" header="Disk Free Space" OnDrawCell="DrawSize"/>
<parameter value="#(%page.Directory)#"/>
<parameter value="0"/>
</tablePane>
 </hgroup>
 </group>
</pane>
}

ClientMethod doTableViewSwitch() [ Language = javascript ]
{
	var viewswitch = parseInt(zen("tableviewSwitch").getValue());		
	if (viewswitch == 1) {
		zen("tablebydir").setHidden(false);
		zen("tablebyvol").setHidden(true);
	} else {
		zen("tablebydir").setHidden(true);
		zen("tablebyvol").setHidden(false);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	$$$SetRefreshTimer

	Set tDBOBJ = ..GetDBOBJ(..Directory)
	If '$IsObject(tDBOBJ) {
		Quit tDBOBJ
	}
	#;SML3048+ ; Display Volume Files info only when this is a multi-Volume database.
	if tDBOBJ.MultiVolume {
		Set ..%GetComponentById("idVolumeFile").hidden = 0
	}
	#;SML3048-
	#; System databases cannot be mounted nor dismounted
	If ##class(SYS.Database).IsSystemDB(..Directory) {
		Set ..AllowMount = 0
		Set ..AllowDismount = 0
	} Else {
		#; If it is not a system database then check the status and decide whether Mount or Dismount is allowed
		Set StatusInt = tDBOBJ.GetStatus(1)
		If (StatusInt = "Dismounted") || (StatusInt = "Unmounted") || (StatusInt = "Unavailable") {
			Set ..AllowDismount = 0
			Set ..AllowMount = 1
		} ElseIf StatusInt = "Expanding" {
			Set ..AllowMount = 0
			Set ..AllowDismount = 0
		} ElseIf (StatusInt = "ClusterMounted/R") || (StatusInt = "ClusterMounted/RW") || (StatusInt = "Mounted/R") || (StatusInt = "Mounted/RW") {
			Set ..AllowMount = 0
			Set ..AllowDismount = 1
		}
	}
	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	Set ..%Pane=..GetDetailPane(tPage)

	Set ..LocatorHeader = $$$FormatText($$$Text("Database %1"),..DBName)

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("Databases")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set tURL = ..Link($ZCVT($className(),"O","URL")_".zen?$ID1="_..EscapeURL(..Directory)_"&DBName="_..EscapeURL(..DBName)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE)))
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	Set ..DatabaseDetailsPage = tURL

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnMount",$$$Text("Mount"),$$$Text("Mount this database if the database can be mounted."),"zenPage.doMount();")
	Set pCommands(2) = $LB("btnDismount",$$$Text("Dismount"),$$$Text("Dismount this database if the database can be dismounted."),"zenPage.doDismount();")
	Set pCommands(3) = $LB("btnTruncate",$$$Text("Truncate"),$$$Text("Truncate this database."),"zenPage.doAction('truncate');")
	Set pCommands(4) = $LB("btnCompact",$$$Text("Compact"),$$$Text("Compact this database."),"zenPage.doAction('compact');")
	Set pCommands(5) = $LB("btnDefragment",$$$Text("Defragment"),$$$Text("Defragment this database."),"zenPage.doAction('defrag');")
	Quit $$$OK
}

ClassMethod GetDBOBJ(pDir) As %String [ ZenMethod ]
{
	Set dbObj = ##class(SYS.Database).%OpenId(pDir,,.Status)
	If $$$ISERR(Status) {
		Quit Status
	}
	Quit dbObj
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Database Details")
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.AllowMount) {
		this.disableCommandButton("btnMount");
	} else {
		this.enableCommandButton("btnMount");
	}
	if (!this.AllowDismount) {
		this.disableCommandButton("btnDismount");
	}
	if ((this.DBName == '') || (this.AllowMount) || (this.BackgroundTasks > 0)) {
		this.disableCommandButton("btnTruncate");
		this.disableCommandButton("btnCompact");
		this.disableCommandButton("btnDefragment");
	}
}

ClientMethod doDismount() [ Language = javascript ]
{
	var msg = this.msgDismount;
	msg = msg.replace("%1",this.DBName);
	var ok = confirm(msg);
	if (ok == false) return;
	ok = this.Dismount(this.Directory);
	if (ok != "") {
		alert(ok);
	} else {
		document.location.reload();	
	}
}

ClientMethod doMount() [ Language = javascript ]
{
	var dir = this.Directory;
	var dbname = this.DBName;
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.DBActions.zen?Dir=' + encodeURIComponent(dir) + '&DBName=' + encodeURIComponent(dbname) + '&ACTION=Mount','mountDB','resizable,width=500,height=600');
}

ClientMethod doAction(action) [ Language = javascript ]
{
	var url = '';
	switch (action) 
	{
		case 'truncate':
			url = this.TruncateDialog;
			break;
		case 'compact':
			url = this.CompactDialog;
			break;
		case 'defrag':
			url = this.DefragDialog;
			break;
	
	}
	url = url + 'DBName='+encodeURIComponent(this.DBName)+'&Directory='+encodeURIComponent(this.Directory);
	zenLaunchPopupWindow(url,action,'status,scrollbars,resizable,width=750,height=600');
}

ClientMethod openTaskPage(SysBGTaskId) [ Language = javascript ]
{
	var url = this.TaskInfoDialog + '&SysBGTaskId=' + encodeURIComponent(SysBGTaskId);
	zenLaunchPopupWindow(url,'taskinfo','status,scrollbars,resizable,width=750,height=600');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {

	case 'compact':			
	case 'defrag':
		if (action == "ok") {
			this.SysBGTaskId = value;
			var timer = zen('taskTimer');
			timer.setProperty('timeout',500);
			timer.startTimer();
		}
		break;
	case 'mountDB':
	case 'truncate':
	case 'taskinfo':
	default:
		document.location.reload();	
		break;
	}
	return true;
}

/// open task status info page after an action (such as Compact and Defragment) is commited and the page is closed.
ClientMethod taskTimeout() [ Language = javascript ]
{
	if (this.SysBGTaskId) {
		this.openTaskPage(this.SysBGTaskId);
	}
}

/// For auto-refresh on this page.
ClientMethod updateView() [ Language = javascript ]
{
	document.location = this.DatabaseDetailsPage;
}

/// Dismount a DB.
ClassMethod Dismount(Dir As %String) As %String [ ZenMethod ]
{
	Set tmsg = ""
	If '##class(SYS.Database).%ExistsId(Dir) {
		Set tmsg = $$$Text("Database no longer exists.")
		Quit tmsg
	}
	Set dbOBJ = ##class(SYS.Database).%OpenId(Dir,,.Status)
	If '$$$ISOK(Status) {
		Set tmsg = Status
		Quit tmsg
	}
	Set Mounted = dbOBJ.Mounted
	Kill dbOBJ
	If Mounted = 0 {
		Set tmsg = $$$Text("Database is not mounted. Cannot perform dismount.")
	} Else {
		Set Status = ##class(SYS.Database).DismountDatabase(Dir)
		If Status '= 1 {
			Set tmsg = $ZCVT(Status,"O","HTML")
		} 
	}
	Quit tmsg
}

/// Draw the contents of the ongoing tasks.
Method DrawTasks(pDirectory As %String) As %Status
{
	Set tSC = ##class(%CSP.UI.Portal.Background.Utils).GetTaskList(pDirectory, .pTaskList)
	If $$$ISERR(tSC) {
		Quit tSC	
	}
	Set tTotal = 0
	If pTaskList '= "" {
		Set tTotal = $Length(pTaskList,"^")
	}
	If (tTotal = 0) {
		Quit tSC
	}
	Set %page.BackgroundTasks = tTotal
	Set url = "<a href='"_%page.BackgroundPage_"' target='_blank'>"_$$$Text("Background Tasks")_"</a>"
	Set text = $$$FormatText($$$Text("Running Database Tasks.  Click to view status or open %1 page for history."),url)
	&html<<div>#(text)#</div>>
	&html<<table class="DetailTable"
				border="0"
				cellpadding="3"
				cellspacing="3"
				>
		>
	&html<<tr><th>#($$$TextHTML("ID"))#</th><th>#($$$TextHTML("Start Time"))#</th><th>#($$$TextHTML("Type"))#</th></tr>>

	For r = 1:1:tTotal {
		Set rValue = $P(pTaskList,"^",r)
		Set SysBGTaskId = $P(rValue,";",1)
		Set StartTime = $P(rValue,";",2)
		Set Type = $P(rValue,";",3)
		&html<<tr onclick='javascript:zenPage.openTaskPage(#(SysBGTaskId)#);'>>
		&html<<td>#(..EscapeHTML(SysBGTaskId))#</td><td>#(..EscapeHTML(StartTime))#</td><td>#(..EscapeHTML(Type))#</td>>
		&html<</tr>>
	}
	&html<</table><div style="height:12px;"/>>
	Quit tSC
}

/// Draw the contents of the diagram header, in the HTMLDashboard style.
Method DrawDetails(pSeed As %String) As %Status
{
	Set tPage = ##class(%CSP.Util.PageInstance).%New()
	If '$IsObject(..%Pane) Set ..%Pane=..GetDetailPane(tPage)
	If '..paneDone {
		Do ..%Pane.DrawHEAD(tPage)
		Set ..paneDone = 1
	}
	Set tSC = ..%Pane.DrawBODY(tPage)
	Quit tSC
}

/// Add the HEAD section for <property>%Pane</property> and override some CSS styles if HTML5 is enabled.
/// Without these overrides, the font size is calculated to be 0.8px and padding is calculated to be 0 for the header cells..
Method %OnDrawHTMLHead() As %Status
{
	If $IsObject(..%Pane) {
		Set tPage = ##class(%CSP.Util.PageInstance).%New()
		Do ..%Pane.DrawHEAD(tPage)
		Set ..paneDone = 1
	}
	If ..cssLevel >= 3 {
		&html<<style type="text/css">
.HTMLMeterLabel, .HTMLMeterLabelSELECTED, .ValueMeterValue, .BarOn {
	font-size: 12.8px;
}
table.group td.HTMLGroupLabel {
	padding: 2px 2px 2px 20px;
}
</style>>
	}
	Quit $$$OK
}

/// Set properties for HTMLDashboardPane to draw details.
ClassMethod GetDetailPane(pInstance As %CSP.Util.PageInstance) As %CSP.Util.Pane [ Language = objectscript ]
{
	
	Set tPane = ##class(%CSP.Util.HTMLDashboardPane).%New()
	Set tPane.Text = "" 
	Set tPane.MetricClass = "SYS.Metrics"
	Set tPane.MetricMethod = "GetDatabaseMetrics"
	Set tPane.Orientation = "horizontal"
	Set tPane.ShowLegend = 0
	Set tPane.ShowIcons = 0
	#; Must set RefreshRate here otherwise the select row does not work. Though we do not intend use the built-in auto-refresh feature on this page (we have our own refresh control), thus the big number.
	Set tPane.RefreshRate = "6000000"
 
	#; First Group on the left containing "General Information"
	Set tGroup1 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tPane.Meters.Insert(tGroup1)
	Set tGroup1.Dashboard = tPane
	Set tGroup1.Orientation = "horizontal"
	Set tGroup1.Width = 500
	Set tGroup1.Height = 20

	#; Group 11: "General Information"
	Set tGroup11 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup1.InsertMeter(tGroup11)
	Set tGroup11.Label=$$$Text("General Information")
	Set tGroup11.Orientation = "vertical"
	Set tGroup11.Width = 500
	Set tGroup11.Style="Standard"
	
	// Add horizontal spacer in between two column groups
	Set tSpacer = ##class(%CSP.Util.HTMLSpacer).%New()
 	Do tGroup1.Meters.Insert(tSpacer)
	Set tSpacer.Width = 20

	// Add horizontal spacer in between two column groups
	Set tSpacer = ##class(%CSP.Util.HTMLSpacer).%New()
 	Do tGroup1.Meters.Insert(tSpacer)
	Set tSpacer.Width = 20
	
	#; Second Group on right containing "Database Size"
	Set tGroup2 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup1.InsertMeter(tGroup2)
	Set tGroup2.Dashboard = tPane
	Set tGroup2.Orientation = "vertical"
	Set tGroup2.Width = 500
	Set tGroup2.Height = 20

	#; Group 21: "Execution Details"
	Set tGroup21 = ##class(%CSP.Util.HTMLGroup).%New()
	Do tGroup2.InsertMeter(tGroup21)
	Set tGroup21.Label=$$$Text("Database Size")
	Set tGroup21.Orientation = "vertical"
	Set tGroup21.Width = 500
	Set tGroup21.Style="Standard"

	// Add vertical spacer in between two groups
	Set tSpacer = ##class(%CSP.Util.HTMLSpacer).%New()
	Do tGroup2.Meters.Insert(tSpacer)
	Set tSpacer.Height = 20
	
	#; *************** LOAD DETAILS TO GROUPS ************************ ;#
 
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Directory"),"Directory",500,"",$$$Text("Name of directory where this database resides.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Resource Name"),"ResourceName",500,"",$$$Text("Resource name assigned to this database.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Mounted"),"Mounted",500,"",$$$Text("Indicates that this database is mounted.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Read Only"),"ReadOnlyMounted",500,"",$$$Text("Indicates that this database is mounted as Read Only.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Read Only Reason"),"ROReasonText",500,"",$$$Text("The reason of the database is mounted as Read Only.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Encrypted"),"EncryptedDB",500,"",$$$Text("Indicates whether this database is encrypted.")))
 	Do tGroup11.InsertMeter(..BuildMeter($$$Text("Encryption Key ID"),"EncryptionKeyID",500,"",$$$Text("Indicates encryption key ID.")))

	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Block Size"),"BlockSize",500,"",$$$Text("Block size (bytes) for this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Blocks"),"Blocks",500,"",$$$Text("Current number of blocks within this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Max Size"),"MaxSize",500,"",$$$Text("Maximum size (Mbytes) allowed for this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Size"),"Size",500,"",$$$Text("Current size (Mbytes) of this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Expansion Size"),"ExpansionSize",500,"",$$$Text("Amount (Mbytes) this database will expand by.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Available Space"),"AvailableSpace",500,"",$$$Text("Available space within this database.")))
  	Do tGroup21.InsertMeter(..BuildMeter($$$Text("% Free Space"),"%Free",500,"",$$$Text("% Free space within this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Disk Free Space"),"DiskFree",500,"",$$$Text("Free space on disk containing this database.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Last Expansion Time"),"LastExpansionTime",500,"",$$$Text("Last time this database expanded.")))
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("Full"),"Full",500,"",$$$Text("Indicates that this database is full.")))
 	#;SML3048 ; Display NewVolumeThreshold property.
 	Do tGroup21.InsertMeter(..BuildMeter($$$Text("New Volume Threshold Size (MB)"),"NewVolumeThreshold",500,"",$$$Text("If non-zero, when the current last volume expands past this size in MB, a new database volume will be created instead.")))

 Quit tPane
}

Method DrawSize(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell in proper DB size.
	Set dbSizeLogicalToDisplay = ##class(SYS.Database).FormatSizes(%query(pName))
	&html<&nbsp;#(dbSizeLogicalToDisplay)#>
	Quit $$$OK
}

}
