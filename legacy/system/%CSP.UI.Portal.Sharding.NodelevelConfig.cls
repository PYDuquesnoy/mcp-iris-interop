/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Sharding Configuration for NodeLevel Clusters
Class %CSP.UI.Portal.Sharding.NodelevelConfig Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Sharding.Utils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Sharding Configuration for Node Level Clusters";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.NodelevelConfig.zen";

Parameter HELPADDRESS = "Home,Configuration,Sharding,NodelevelConfig";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not allow this page to auto-switch namespaces if $NAMESPACE is specified
Parameter AUTONS As BOOLEAN = 0;

/// Do not use standare Save/Cancel buttons
Property IsEditForm As %Boolean [ InitialExpression = 0 ];

Property ActivateShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Activate.zen",,1)} ];

Property AdvancedSettingsPage As %ZEN.Datatype.string [ InitialExpression = {..SettingsLink()} ];

Property ConfigurePage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Configure.zen",,1)} ];

Property EnableShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Enable.zen",,1)} ];

Property NodeLevelPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.NodelevelConfig.zen",,1)} ];

Property RebalanceShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Rebalance.zen",,1)} ];

Property ShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Sharding.Configuration.zen",,1)} ];

Property TableDetailsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.TableDetails.zen",,1)} ];

Property VerifyShardingPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Verify.zen",,1)} ];

/// Allow Assign if the current namespace is a master or it is not a shard
Property AllowAssign As %Boolean [ InitialExpression = 1 ];

/// Allow Verify if the current namespace a master
Property AllowVerify As %Boolean [ InitialExpression = 1 ];

/// Allow Activate if the current namespace is a master and if any shard is inactive
Property AllowActivate As %Boolean [ InitialExpression = 0 ];

/// Whether user can use Enable Sharding
Property HasSecPriviledge As %Boolean [ InitialExpression = {$System.Security.Check("%Admin_Secure","USE")} ];

/// Double the default timeout interval so long-running VerifyShards calls don't distort the page
Property iTimeoutInterval As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// Whether the current InterSystems IRIS instance is enabled to act as a shard master or shard server.<br>
/// If it is not enabled, then this page will allow user to enable it.<br>
/// Once it is enabled, then user may be able to Add/Verify/Activate shard for namespace
Property IsShardingEnabled As %Boolean [ InitialExpression = 0 ];

Property PageMessage As %String;

Property MASTERNAMESPACE As %String;

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
<label id="Text1" value="" containerStyle="padding:10px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
<timer id="timer" timeout="0" ontimeout="zenPage.timeout();"/>

<form enclosingClass="formMessage">
<html>
  <div id="idMessage" class="sectionCaption"/>
 </html>
 </form>
 <vgroup id="groupContent" cellVAlign="top" hidden="true">

<hgroup>
<label id="lblNamespace" label="Cluster Namespace: "/>
<label value="#(%page.MASTERNAMESPACE)#"/>
</hgroup>
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
<column colName="DISPLAY_ROLE" header="Role" OnDrawCell="DrawRole"/>
<column colName="SHARD_DATABASE" header="Address" OnDrawCell="DrawAddress"/>
<column colName="MIRROR_NAME" header="Mirror Name"/>
<column colName="MIRROR_DATABASE" header="Backup Host:Port"/>
<column colName="VIP" header="VIP"/>
<column colName="ACTIVE" hidden="true"/>
<column colName="DISPLAY_ACTIVE" hidden="true"/>
<parameter id="shardnamespace" value="#(%page.MASTERNAMESPACE)#"/>
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
	if (this.PageMessage) {
		zen('svgTabArea').setHidden(true);
		var message = document.getElementById("idMessage");
		if (message) {
			message.innerHTML = this.PageMessage;
		}
		return;
	}
	else {
		this.onresizeHandler();
		if (!this.AllowAssign) {
			this.disableCommandButton("btnAssign");
		}
		if (!this.AllowVerify) {
			this.disableCommandButton("btnVerify");
			this.disableCommandButton("btnSettings");
		}
		if (!this.AllowActivate) {
			this.disableCommandButton("btnActivate");
		}
	}
	if ((this.MASTERNAMESPACE=='') || (!this.AllowVerify)) {
		zen('svgTabArea').setHidden(true);
		zen('groupContent').setHidden(true);
		zen('content').setHidden(true);
	} else {
		zenPage.tabChanged(0);
		zen('svgTabArea').setHidden(false);
		zen('groupContent').setHidden(false);
		zen('content').setHidden(false);
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

ClientMethod doVerify(SHARD) [ Language = javascript ]
{
	this.resetMsg();
	try {
		this.enableButtons(false);
		delete this._jobNumber;
		var proxy = this.StartVerify(this.MASTERNAMESPACE);
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

ClientMethod doRebalance() [ Language = javascript ]
{
	this.resetMsg();
	var namespace = encodeURIComponent(this.MASTERNAMESPACE);
	zenLaunchPopupWindow(this.RebalanceShardingPage+'NAMESPACE='+namespace+'&ISNODELEVEL=1','ShardRebalance','status,scrollbars,resizable=yes,width=750,height=600');
}

ClientMethod doConfigure() [ Language = javascript ]
{
	this.resetMsg();
	var url = this.ConfigurePage;
	zenLaunchPopupWindow(url,'Configure','status,scrollbars,resizable,width=750,height=600');
}

ClientMethod doSettings() [ Language = javascript ]
{
	this.resetMsg();
	var url = this.AdvancedSettingsPage+'MASTERNAMESPACE='+encodeURIComponent(this.MASTERNAMESPACE);
	zenLaunchPopupWindow(url,'AdvancedSettings','status,scrollbars,resizable,width=750,height=600');
}

ClientMethod doTableDetails(tableName, shardKey) [ Language = javascript ]
{
	this.resetMsg();
	var url = this.TableDetailsPage+'MASTERNAMESPACE='+encodeURIComponent(this.MASTERNAMESPACE)+'&TABLENAME='+encodeURIComponent(tableName)+'&SHARDKEY='+encodeURIComponent(shardKey);
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
				var msg = (this._proxy.action == 'verify') ? $$$Text("Verification completed successfully.") : $$$Text("Rebalance completed successfully.");
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
	if (flag) {
		if (this.AllowVerify) {
			this.enableCommandButton("btnVerify");
			this.enableCommandButton("btnSettings");
		}	
	} else {
		this.disableCommandButton("btnVerify");
		this.disableCommandButton("btnSettings");
	}
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
	Set %page.IsShardingEnabled = ..IsShardingEnabled(.pService)
	If %page.IsShardingEnabled {
		
		Set %page.MASTERNAMESPACE = $System.Cluster.ClusterNamespace()
		
		if (%page.MASTERNAMESPACE = "") {
			// nothing sharding-related here yet
			set %page.PageMessage = $$$TextHTML("This instance is not yet part of a Node-level cluster. Click ""Configure"" to initialize it.") 
		} 
		
		// check if we are in the state of waiting for the instance to be restarted
		If $G(%session.Data("Sharding","StartEnable")) {
			Set %page.PageMessage = $$$TextHTML("Sharding is enabled, but cannot be configured until the instance is restarted. Please restart the instance now.")
		}
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
	 Quit $$$Text("Configure Node-Level")
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
		If $System.Cluster.ClusterNamespace() = "" {
			Set pCommands(2) = $LB("btnConfigure",$$$Text("Configure"),$$$Text("Initialize or add this instance to a node-level cluster"),"zenPage.doConfigure();")
		} else {
			Set pCommands(3) = $LB("btnVerify",$$$Text("Verify Shards"),$$$Text("Verifies that assigned shards are reachable and are correctly configured"),"zenPage.doVerify();")
			Set pCommands(4) = $LB("btnRebalance",$$$Text("Rebalance"),$$$Text("Rebalance data across shards in the sharded cluster"),"zenPage.doRebalance();")	
			Set pCommands(5) = $LB("btnSettings",$$$Text("Advanced Settings"),$$$Text("Modify advanced settings for the cluster"),"zenPage.doSettings();")	
		}
	}
	Quit $$$OK
}

ClassMethod SaveOption(MASTERNAMESPACE, OptionName, OptionValue) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		Set tSC = $SYSTEM.Sharding.SetOption(MASTERNAMESPACE, OptionName, OptionValue)
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
ClassMethod StartVerify(pMASTERNAMESPACE) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tParms("masterNamespace") = pMASTERNAMESPACE
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

ClassMethod StartRebalance(pMASTERNAMESPACE) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tParms("masterNamespace") = pMASTERNAMESPACE
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

ClassMethod GetShardingRole(pNamespace) As %String [ ZenMethod ]
{
	Quit ##class(%BigData.ShardingManager).GetShardingRole(pNamespace)
}

/// Helper method to rename "Query" role to "Compute"
Method DrawRole(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	set value = $zcvt($g(%query(name),"Unknown"),"O","HTML")
	write $s($$$UPPER(value)="QUERY":"Compute", 1:value)
	quit $$$OK
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
	set p("CLUSTERLEVEL") = "NODE"
	return ..Link("/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Settings.zen", .p, 1)
}

}
