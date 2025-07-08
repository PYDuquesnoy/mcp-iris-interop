/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Sharding Configuration
Class %CSP.UI.Portal.Sharding.Configuration Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Sharding.Utils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Sharding Configuration";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Configuration.zen";

Parameter HELPADDRESS = "Home,Configuration,Sharding Configuration";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not allow this page to auto-switch namespaces if $NAMESPACE is specified
Parameter AUTONS As BOOLEAN = 0;

/// Do not use standare Save/Cancel buttons
Property IsEditForm As %Boolean [ InitialExpression = 0 ];

Property ActivateShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Activate.zen",,1)} ];

Property AssignShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Assign.zen",,1)} ];

Property AdvancedSettingsPage As %ZEN.Datatype.string [ InitialExpression = {..SettingsLink()} ];

Property InitializePage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Initialize.zen",,1)} ];

Property EnableShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Enable.zen",,1)} ];

Property NodeLevelPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.NodelevelConfig.zen",,1)} ];

Property RebalanceShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Rebalance.zen",,1)} ];

Property ShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.Configuration.zen",,1)} ];

Property TableDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.TableDetails.zen",,1)} ];

Property VerifyShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Verify.zen",,1)} ];

/// Allow Assign if the current namespace is a master or it is not a shard
Property AllowAssign As %Boolean [ InitialExpression = 0 ];

/// Allow Verify if the current namespace has any sharding config
Property AllowVerify As %Boolean [ InitialExpression = 0 ];

/// Whether Sharding license is present
Property HasShardingLicense As %Boolean [ InitialExpression = 0 ];

/// Whether user can use Enable Sharding
Property HasSecPriviledge As %Boolean [ InitialExpression = {$System.Security.Check("%Admin_Secure","USE")} ];

/// Whether the current InterSystems IRIS instance is enabled to act as a shard master or shard server.<br>
/// If it is not enabled, then this page will allow user to enable it.<br>
/// Once it is enabled, then user may be able to Add/Verify/Activate shard for namespace
Property IsShardingEnabled As %Boolean [ InitialExpression = 0 ];

Property PageMessage As %String;

/// status after EnableSharding is executed. It is either 1 or tSC. If it is 1 then we display restart instance message.
Property StartEnable As %String;

/// Captures the "current" namespace
Property CurrentNamespace As %String(ZENURL = "$NAMESPACE");

/// If the current <i>Namespace</i> is part of a Node-level cluster, this property holds the role
/// of this namespace for that cluster, so that <method>checkNode</method> can display a proper
/// warning.
/// Note that this value will be left empty if this <i>Instance</i> is part of a node-level cluster, 
/// but the current <i>Namespace</i> plays no role in it, as in those cases it's OK (though likely
/// not very practical) to change / initialize a namespace-level config here.
Property NodeLevelCluster As %String;

Property warningImage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/broker/images/warning.png")} ];

/// Double the default timeout interval so long-running VerifyShards calls don't distort the page
Property iTimeoutInterval As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

XData Style
{
<style type="text/css">
.sectionCaption {
	font-size: 16px;
	font-weight: bold;
}
.exp {
	font-size: 14px;
}
.changeNote {
	color: #4D3926;
	margin: 20px;
	background: white;
	border: 1px solid #4D3926;
	border-radius: 5px;
	font-size: 1em;
	padding: 10px;
}
</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground { fill:white; stroke:white; }	
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:0px 20px 20px 20px;">
<label id="Text1" value="" containerStyle="padding:10px 10px 10px 0px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<form enclosingClass="formMessage">
<html id="idMessage" enclosingClass="formTitle" seed="">
 </html>
 </form>
 <vgroup id="groupContent" cellVAlign="top" hidden="false">
<group labelPosition="left">
<select id="selNamespace" label="Namespace" 
title=""
showEmpty="false"
onchange="zenPage.setMaster();"/>
</group>
<html id="hintNamespace" OnDrawContent="DrawNamespaceHint" seed="#(%page.CurrentNamespace)#"></html>

<spacer height="10"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white; stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":Shards:Sharded Tables"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<group id="content" width="100%" hidden="true" >
<group id="page_1">
<vgroup id="idServers">
<spacer height="10"/>
<tableNavBar id="tableBar1" hidden="true" showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table1" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table1"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="%SQL.Manager.Catalog"
queryName="ListShards"
showValueInTooltip="true"
showZebra="true"
valueColumn="SHARD"
useSnapshot="true"
>
<column colName="SHARD" header="Shard #" style="text-align:center;"/>
<column colName="ROLE" hidden="true"/>
<column colName="DISPLAY_ROLE" header="Role"/>
<column colName="SHARD_DATABASE" header="Shard Namespace" OnDrawCell="DrawAddress" />
<column colName="MIRROR_NAME" header="Mirror Name"/>
<column colName="MIRROR_DATABASE" header="Backup Host:Port"/>
<column colName="VIP" header="VIP"/>
<column colName="ACTIVE" hidden="true"/>
<column colName="DISPLAY_ACTIVE" hidden="true"/>
<column linkCaption="Edit" link="javascript:zenPage.doEdit('#(%query.SHARD)#');" 
style="text-align:center;"
title="Edit this shard"
/>
<column linkCaption="Deassign" link="javascript:zenPage.doDeassign('#(%query.SHARD)#');" 
style="text-align:center;" 
linkConfirm="Are you sure you want to deassign this shard?"
title="Deassign this shard"
 />
<parameter id="shardnamespace" value="#(%page.CurrentNamespace)#"/>
<condition colName="ROLE" predicate="EQ" value="Query" cellStyle="disabled" targetCol="Edit" /> 
 </tablePane>

</vgroup>
</group>

<group id="page_2">
<vgroup id="idTables">
<spacer height="10"/>
<tableNavBar id="tableBar2" hidden="true" showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table2" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table2"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="%SQL.Manager.Catalog"
queryName="ShardedTables"
showValueInTooltip="true"
showZebra="true"
valueColumn="NAME"
useSnapshot="true"
>
<column colName="NAME" header="Table Name"/>
<column colName="OWNER" header="Owner"/>
<column colName="LAST_COMPILED" header="Last Compiled"/>
<column colName="CLASSNAME" header="Class Name"/>
<column colName="SHARD_KEY" header="Shard Key"/>
<column linkCaption="Details" link="javascript:zenPage.doTableDetails('#(%query.NAME)#','#(%query.SHARD_KEY)#');" />
 </tablePane>
</vgroup>
</group>
</group>
</vgroup>

</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var message = document.getElementById("idMessage");
	if (this.PageMessage) {
		zen('selNamespace').setHidden(true);
		zen('svgTabArea').setHidden(true);
		if (message) {
			message.innerHTML = this.PageMessage;
		}
		if (!this.HasSecPriviledge) {
			this.disableCommandButton("btnEnable");	
		}
		return;
	}
	else {
		this.onresizeHandler();
		if (this.StartEnable && this.StartEnable == 1) {
			if (message) {
				message.innerHTML = "<div class='sectionCaption'>"+$$$Text("Sharding is enabled, but cannot be configured until the instance is restarted. Please restart the instance now.")+"</div>";
			}
			zen('selNamespace').setHidden(true);
			zen('svgTabArea').setHidden(true);
			return;
		}
		if (!this.AllowAssign) {
			this.disableCommandButton("btnAssign");
		}
		if (!this.AllowVerify) {
			this.disableCommandButton("btnVerify");
			this.disableCommandButton("btnRebalance");
			this.disableCommandButton("btnSettings");
		}
		this.checkNode();
	}
	if (!this.AllowVerify) {
		zen('svgTabArea').setHidden(true);
		zen('content').setHidden(true);
	} else {
		zenPage.tabChanged(0);
		zen('svgTabArea').setHidden(false);
		zen('content').setHidden(false);
		this.checkNode();
	}
}

ClientMethod checkNode() [ Language = javascript ]
{
	if (this.NodeLevelCluster != "") {
		var message = document.getElementById("idMessage");
		var hint = $$$Text("click here to go to the Configure Node-level Cluster page");
		var link = "<a class='portalServerLink sectionCaption' title='"+hint+"' href='"+this.NodeLevelPage+"'>" + $$$Text("node-level cluster") + "</a>";
		var msg = $$$FormatText($$$Text("You have selected the %1 namespace of the %2. By making changes, you may convert the %3 to a namespace-level cluster (which cannot be reversed)."),this.NodeLevelCluster,link,link);	
		var image = '<img src="' + this.warningImage + '" width="16" height="16" border="0"/>&nbsp;';
		message.innerHTML = "<div class='changeNote'>"+ image + msg+"</div>";
	}
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	// these are the largest sizes for the iframe to be without triggering IE/FF/Chrome to create the browser's scroll bars.
	// do not change without testing on all three browsers.
	var wd = zenGetWindowWidth() - ((zenIsIE)?60:65);
	var ht = zenGetWindowHeight() - ((zenIsIE)?250:190);
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	zen("svgTabArea").setProperty("width",wd);
	zen("tabBar").setProperty("width",wd);
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	var option;
	for ( var i=0; i<2; i++ ) {
		option = i + 1;
		if ( i == index ) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}
	}
	return;
}

/// User changed master namespace. Reload page with new namespace.
ClientMethod setMaster() [ Language = javascript ]
{
	var master = zen('selNamespace').getValue();
	var url = this.ShardingPage;
	if (master) {
		url = url + '$NAMESPACE=' + master;
	}
	window.document.location = url;
}

ClientMethod doRebalance() [ Language = javascript ]
{
	this.resetMsg();
	var namespace = encodeURIComponent(this.CurrentNamespace);
	zenLaunchPopupWindow(this.RebalanceShardingPage+'NAMESPACE='+namespace+'&ISNODELEVEL=0','ShardRebalance','status,scrollbars,resizable=yes,width=750,height=600');
}

/// User changed RunQueriesAsync. Display appropriate hint.
ClientMethod doRunQueries() [ Language = javascript ]
{
	var value = zen("RunQueriesAsync").getValue();
	var text = '';
	switch (value) {
		case '':
			text = $$$Text("Queries are run synchronously when any shards are mirrored (for transparent completion on failover), otherwise asynchronously (faster in some cases).");
			break;
		case '0':
			text = $$$Text("All queries are run synchronously.");
			break;
		case '1':
			text = $$$Text("All queries are run asynchronously.");
			break;
	}
	zen("RunQueriesAsync").setProperty('hint',text);
}

/// Assign new shard or edit existing shard
ClientMethod doEdit(SHARD) [ Language = javascript ]
{
	this.resetMsg();	
	var url = this.AssignShardingPage+'MASTERNAMESPACE='+encodeURIComponent(this.CurrentNamespace);
	if (SHARD) {
		var table = zenPage.getComponentById("table1");
		var selectedIndex = table.getProperty("selectedIndex");
		var rowData = table.getRowData(selectedIndex);
		if (rowData && rowData["SHARD"] != "") {
			var param = "&ROLE="+encodeURIComponent(rowData["ROLE"]) + "&SHARD_DATABASE=" + encodeURIComponent(rowData["SHARD_DATABASE"]) + "&MIRROR_NAME=" + encodeURIComponent(rowData["MIRROR_NAME"]) + "&MIRROR_DATABASE=" + encodeURIComponent(rowData["MIRROR_DATABASE"]) + "&VIP=" + encodeURIComponent(rowData["VIP"]);
			url += '&SHARD='+encodeURIComponent(SHARD)+param;
		}
	}
	zenLaunchPopupWindow(url,'ShardEdit','status,scrollbars,resizable=yes,width=750,height=600');
}

ClientMethod doDeassign(SHARD) [ Language = javascript ]
{
	this.resetMsg();	
	if (SHARD) {
		var table = zenPage.getComponentById("table1");
		var selectedIndex = table.getProperty("selectedIndex");
		var rowData = table.getRowData(selectedIndex);
		if (rowData && rowData["SHARD_DATABASE"] != "") {
			var proxy = this.Deassign(this.CurrentNamespace, rowData["SHARD_DATABASE"]);
			if (proxy.error) {
				this.showMsg(proxy.error,1);
			} else {
				window.location.reload();
			}
		} else {
			// this should never happen but just in case
			this.showMsg($$$Text("Unable to find shard database info."),1);	
		}
	}
}

ClientMethod doVerify(SHARD) [ Language = javascript ]
{
	this.resetMsg();
	try {
		this.enableButtons(false);
		delete this._jobNumber;
		var proxy = this.StartVerify(this.CurrentNamespace);
		this._proxy = proxy;
		this._proxy.action = 'verify';
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this.msgWait = proxy.msg;
			this._jobNumber = proxy.jobNumber;
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
		} else {
			if (proxy.error) {
				this.showMsg(proxy.error, 1);
			} else {
				this.showMsg('Unknown error in verify', 1);	
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod doActivate() [ Language = javascript ]
{
	this.resetMsg();
	try {
		this.enableButtons(false);
		delete this._jobNumber;
		var proxy = this.StartActivate(this.CurrentNamespace);
		this._proxy = proxy;
		this._proxy.action = 'activate';
		if (proxy.jobNumber) {
			// start timer to check status
			// if background process is finished, display result
			this.msgWait = proxy.msg;
			this._jobNumber = proxy.jobNumber;
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
		} else {
			if (proxy.error) {
				this.showMsg(proxy.error, 1);
			} else {
				this.showMsg('Unknown error in activate', 1);	
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

ClientMethod doSettings() [ Language = javascript ]
{
	this.resetMsg();
	var url = this.AdvancedSettingsPage+'MASTERNAMESPACE='+encodeURIComponent(this.CurrentNamespace);
	zenLaunchPopupWindow(url,'AdvancedSettings','status,scrollbars,resizable,width=750,height=600');
}

ClientMethod doTableDetails(tableName, shardKey) [ Language = javascript ]
{
	this.resetMsg();
	var url = this.TableDetailsPage+'MASTERNAMESPACE='+encodeURIComponent(this.CurrentNamespace)+'&TABLENAME='+encodeURIComponent(tableName)+'&SHARDKEY='+encodeURIComponent(shardKey);
	zenLaunchPopupWindow(url,'TableDetails','status,scrollbars,resizable,width=750,height=600');
}

ClientMethod timeout() [ Language = javascript ]
{
	if (!this._jobNumber) {
		return;	
	}
	var proxy = this.CheckJobStatus(this._jobNumber);
	switch (proxy.status) {
		case 'running':
		case 'suspended':
			if (this._proxy) {
				if (proxy.msg != '') {
					var msg = proxy.msg;
				} else {
					this.msgWait = this.msgWait + '.';
					var msg = this.msgWait;
				}
				this.showMsg(msg,0);
			}
			var timer = zen('timer');
			timer.setProperty('timeout',this.iTimeoutInterval);
			timer.startTimer();
			break;
		case 'done':
			if (this._proxy) {
				delete this._jobNumber;
				var msg = (this._proxy.action == 'verify') ? $$$Text("Verification completed successfully.") : $$$Text("Activation completed successfully.");
				this.showMsg(msg,2);
				this.enableButtons(true);
			}
			break;
		case 'error':
		case 'terminated':
			if (this._proxy) {
				this.showMsg(proxy.msg,1);
				delete this._jobNumber;
				this.enableButtons(true);			
			} else {
				alert('cannot find this_proxy -- unable to continue.');
			}
			break;
	}
}

/// User hit Verify button (flag=false): disable currently enabled buttons
/// When verify finishes (flag=true): enable what needs enabled
ClientMethod enableButtons(flag) [ Language = javascript ]
{
	if (this.AllowAssign && flag) {
		this.enableCommandButton("btnAssign");
	} else {
		this.disableCommandButton("btnAssign");
	}
	if (this.AllowVerify && flag) {
		this.enableCommandButton("btnVerify");
		this.enableCommandButton("btnSettings");
		this.enableCommandButton("btnRebalance");
	} else {
		this.disableCommandButton("btnVerify");
		this.disableCommandButton("btnSettings");
		this.disableCommandButton("btnRebalance");
	}
	zen('selNamespace').setHidden(!flag);
	zen('svgTabArea').setHidden(!flag);
	zen('content').setHidden(!flag);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tLicense = $$Sharding^%SYS.LICENSE()
	If tLicense = 0 {
		Set %page.PageMessage = $$$TextHTML("Sharding is unavailable for current license.")
		Quit tSC
	}
	Set %page.HasShardingLicense = 1
	If ..IsShardingEnabled(.pService) '= 1 {
		Set %page.PageMessage = $$$TextHTML("Sharding is not enabled!")
		Quit 0
	}
	If ((pService("ECP") = 0) || (pService("Sharding") = 0)) {
		Set ..%GetComponentById("Text1").value = $$$TextHTML("To configure sharding, you must first enable the ECP service and the Sharding service. Click [Enable Sharding] to enable both services.")
		If (('%page.HasSecPriviledge) && ((pService("ECP") = 0) || (pService("Sharding") = 0))) {
			Set %page.PageMessage = %page.PageMessage _ "<div class='sectionCaption' style='padding-left:10px;'>" _ $$$TextHTML("You must have the %Admin_Secure privilege to enable sharding.")_"</div>"
		}
		If pService("ECP") = 0 {
			Set %page.PageMessage = %page.PageMessage _ "<div style='padding:10px;'>"_$$$TextHTML("ECP service is not enabled. ")
		} 
		If pService("Sharding") = 0 {
			Set %page.PageMessage = %page.PageMessage _ "<div style='padding-top:10px;'>"_$$$TextHTML("Sharding service is not enabled. ") _ "</div>"
		}
	} Else {
		Set %page.IsShardingEnabled	= 1
		Set %page.StartEnable = $G(%session.Data("Sharding","StartEnable"))
		
		// DP-409012
		set clusterNamespace = $System.Cluster.ClusterNamespace(),
			currentNamespace = $$$UPPER(..CurrentNamespace) // this is actually the current namespace
		If clusterNamespace '= "" {
			Set tMsg = $$$TextHTML("NOTE: This instance is currently defined as a member of a NODE-LEVEL cluster.")	
			Set ..%GetComponentById("Text1").value = tMsg
			
			// now figure out if this namespace is part of that node-level cluster so checkNode() 
			// can show a more explicit warning.
			if (currentNamespace = $$$UPPER(clusterNamespace)) {
				set %page.NodeLevelCluster = $$$Text("cluster")
			} else {
				do $system.Cluster.GetMetadata(.clusterConfig)
				if (currentNamespace = $$$UPPER($g(clusterConfig("MasterNamespace")))) {
					set %page.NodeLevelCluster = $$$Text("master")
				}
			}
		}
		
		Set selNamespace = ..%GetComponentById("selNamespace")
		Kill Namespaces
		Set ShardInfo = 1
		Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces, .ShardInfo)
		Set valueList = ""
		Set displayList = " --- " _ $$$Text("select a namespace") _ " --- "
		For i=1:1:tCnt {
			If Namespaces(i) '= "%SYS" {
				Set valueList = valueList _ "," _ Namespaces(i)
				Set displayList = displayList _ "," _ Namespaces(i) _ " " _ $lg($G(ShardInfo(i)),2)
				Set names(Namespaces(i)) = $lg($G(ShardInfo(i)),1)
			}
		}
		Set selNamespace.valueList = valueList
		Set selNamespace.displayList = displayList
		Set selNamespace.value = $S(..CurrentNamespace'="":..CurrentNamespace,$namespace'="%SYS":$namespace,1:"")
		
		// display Verify button in any shard-related namespace
		set %page.AllowVerify = (selNamespace.value'="") && (selNamespace.value'="%SYS") && ($g(names(selNamespace.value))'="")
		
		// display Assign button in non-sharded or master namespace (not in data or query shards)
		set %page.AllowAssign = (selNamespace.value'="") && (selNamespace.value'="%SYS") && ('$lf($lb("DS","QS"),$g(names(selNamespace.value))))
	}

	Quit $$$OK
}

Method HideComponent(id As %String)
{
	Set ..%GetComponentById(id).hidden = 1
	Set ..%GetComponentById(id).containerStyle = "padding:0;"
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Configure Namespace-Level")
}

ClientMethod doNew() [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.Namespace.zen?SRC=SHARD';
	zenPage.gotoPage(url);
}

/// This method resets the modified indicator and return user to the parent page. 
ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	self.document.location = this.ParentURL;
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if ((popupName == 'AdvancedSettings') || (popupName == 'TableDetails')) {
		return false;
	}
	window.location.reload();
	return true;
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	If ..IsShardingEnabled,'$G(%session.Data("Sharding","StartEnable")) {
			Set pCommands(2) = $LB("btnAssign",$$$Text("Assign Shard"),$$$Text("Assign shard to the selected master namespace"),"zenPage.doEdit('');")
			Set pCommands(3) = $LB("btnVerify",$$$Text("Verify Shards"),$$$Text("Verify shards for the master namespace"),"zenPage.doVerify();")
			Set pCommands(4) = $LB("btnRebalance",$$$Text("Rebalance"),$$$Text("Rebalance data across shards in the sharded cluster"),"zenPage.doRebalance();")	
			Set pCommands(5) = $LB("btnSettings",$$$Text("Advanced Settings"),$$$Text("Modify advanced settings for the master namespace"),"zenPage.doSettings();")	
	} 
	Set pCommands(7) = $LB("btnNamespace",$$$Text("Create Namespace"),$$$Text("Create a new namespace"),"zenPage.doNew();")
	Quit $$$OK
}

ClassMethod Deassign(Namespace, ShardDatabase) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set ShardHost = $P(ShardDatabase,":",1)
		Set ShardPort = $P(ShardDatabase,":",2)
		Set ShardNamespace = $P(ShardDatabase,":",3)
		Set tSC = $SYSTEM.Sharding.DeassignShard(Namespace, ShardHost, ShardPort, ShardNamespace)		
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)	
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in Deassign: "_$ZE
	Quit tProxy
}

ClassMethod SaveOption(Namespace, OptionName, OptionValue) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = $SYSTEM.Sharding.SetOption(Namespace, OptionName, OptionValue)
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $System.Status.GetErrorText(tSC)	
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in SaveOption: "_$ZE
	Quit tProxy
}

/// Start verifying shards
ClassMethod StartActivate(Namespace) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tParms("masterNamespace") = Namespace
		Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("ShardActivate",$zu(5),.tParms,.tItems,.tJob)
		If $$$ISOK(tSC) {
			Set tProxy.jobNumber = tJob
			Set tProxy.msg = $$$TextHTML("Activate shards in progress. Please wait...")
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $$$FormatText($$$Text("Error during activation: %1"),$System.Status.GetErrorText(tSC))
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartActivate: "_$ZE
	Quit tProxy
}

/// Start verifying shards
ClassMethod StartVerify(Namespace) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tParms("masterNamespace") = Namespace
		Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("ShardVerify",$zu(5),.tParms,.tItems,.tJob)
		If $$$ISOK(tSC) {
			Set tProxy.jobNumber = tJob
			Set tProxy.msg = $$$TextHTML("Verify shards in progress. Please wait...")
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = $$$FormatText($$$Text("Error during verification: %1"),$System.Status.GetErrorText(tSC))
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  "Error occurred in StartVerify: "_$ZE
	Quit tProxy
}

Method DrawNamespaceHint(seed) As %Status
{
	Set hint = ""
	If seed '= "" {
		Set shardRole = ##class(%BigData.ShardingManager).GetShardingRole(seed,.dataMaster,.shardNumber)
		If shardRole = "" {
			Set hint = $$$TextHTML("This namespace has not been configured as part of a sharded cluster.")
			Set hint = hint _ "<br>"_$$$TextHTML("To make this the master namespace, assign a shard.")
			Set hint = hint _ "<br>"_$$$TextHTML("To make this a shard namespace, select the master namespace and assign this one as a shard.")
		} Else {
			If $G(dataMaster) '= "" {
				Set hint = $$$FormatText($$$Text("This shard namespace is assigned to master namespace %1."),dataMaster)
			}
		}
		If %page.AllowVerify {
			// this is a Data master so we need no hint
			Set hint = ""
		}
	} Else {
		If %page.StartEnable && %page.StartEnable = 1 {
			Set hint = ""	
		}
	}
	&html<<div class="exp">#(hint)#>
	Quit $$$OK
}

ClassMethod GetShardingRole(pNamespace) As %String [ ZenMethod ]
{
	Quit ##class(%BigData.ShardingManager).GetShardingRole(pNamespace)
}

/// Helper method to flag the current instance
Method DrawAddress(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	set value = $zcvt($g(%query(name),"Unknown"),"O","HTML")
	write value
	if $$hostsEqual^%SYS.SHARDSRV($$getmyhostname^%SYS.SHARDSRV(), $p(value,":",1)) && (##class(%SQL.Manager.API).GetPort() = $p(value,":",2)) {
		write " (",$$$Text("local"),")"
	}
	quit $$$OK
}

ClassMethod SettingsLink() As %String [ Internal ]
{
	set p("CLUSTERLEVEL") = "NAMESPACE"
	return ..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Settings.zen", .p, 1)
}

}
