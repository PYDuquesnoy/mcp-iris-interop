/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page is used to set the ShutdownGroup of the production.<br>
/// Note: Setting ShutdownGroup to a value other than default or empty value can lead to extending the time it takes to
/// stop the instance in a controlled manner. This can have implications for time sensitive failovers <br><br>
/// Productions are requested to be shutdown in parallel when the system is stopped in a controlled manner <br>
/// It is possible to control the shutdown order in separate parallel groups by entering an integer. <br>
/// Running productions will be shutdown in parallel grouped by this integer.<br>
/// The default if not specified will be taken as $$$ensDefaultShutdownGroup (2). <br>
Class EnsPortal.ProductionShutdownGroup Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Production Shutdown Group";

/// User needs READ permissions on the %Ens_ProductionConfig resource to access this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to make changes on this page.
/// as well as canAccessAll.
Parameter EDITRESOURCE = "%Admin_Manage:USE";

/// If user cannot access Ens.Configuration in all namespaces we will not show the table
/// and the user will not be able to make changes.
Property canAccessAll As %Boolean [ InitialExpression = 0 ];

Property currentProduction As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of the table pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<spacer height="20" />
<hgroup>
<spacer width="20" />
<vgroup>
<label id="lblProdRW" hidden="true" label="Choose a production from this namespace to set a Shutdown Group then click Apply. The default group is 2." labelStyle="font-size:12pt;" />
<label id="lblProdRO" hidden="true" label="Information on production Shutdown Group for this namespace shown below. The default group is 2." labelStyle="font-size:12pt;" />
<spacer height="10" />
<label id="lblStop1" hidden="true" label="Productions are requested to be shutdown in parallel when the system is stopped in a controlled manner. The table lists running or last run production in each namespace." labelStyle="font-size:10pt;" />
<spacer height="5" />
<label id="lblStop2" hidden="true" label="It is possible to control the shutdown order using separate groups by entering different shutdown group numbers." labelStyle="font-size:10pt;" />
<spacer height="10" />
<label id="lblNote1" hidden="true" label="Note: Setting Shutdown Group to a value other than the default can lead to extending the time it takes to stop the instance in a controlled manner." labelStyle="font-size:12pt;" />
<spacer height="20" />

<dataCombo
	id="prodList"
	queryClass="Ens.Config.Production"
	queryName="Extent"
	size="85"
	onchange="zenPage.getrecommendAndWarn();"
	/>
<spacer height="10"/>
	<hgroup hidden="false" id="grpStop">
	<label label="Relative Shutdown Group:"/>
	<spacer width="4px" />
	<text name="ShutdownGroup"
		id="shutdownGroup"
		size="5"
		value="0"
		onchange="zenPage.doWarning();"
		/>
	</hgroup>
<spacer height="20"/>
<tablePane id ="tblProdsByShutdownGroup"
	hidden="true"
	caption="Shutdown Groups used to stop running productions in parallel during controlled system shutdown:"
	queryClass="%Library.EnsembleMgr"
	queryName="ListProductionsByShutdownGroup"
	showZebra="true"
	rowSelect="false"/>
</vgroup>
<spacer width="20" />
</hgroup>
</pane>
}

ClientMethod getrecommendAndWarn() [ Language = javascript ]
{
	var id = zen('prodList').getProperty('value');
	if (zenPage.currentProduction === id) return;
	zenPage.currentProduction = id;
	var shutdownObject = zen('shutdownGroup');
	/* if (shutdownObject.getProperty('hidden') {then the user cannot see the shutdown setting and it is being changed} */
	if (shutdownObject) {
		if (id.length > 0) {
			var shutdownGroup = zenPage.GetShutdownGroup(id)
			shutdownObject.setProperty('value',shutdownGroup);
		} else {
			shutdownObject.setProperty('value','');
		}
	}
	zenPage.pageModified = true; // do not leave the page if we have not applied the change (see onunloadHandler)
}

ClientMethod doWarning() [ Language = javascript ]
{
	zenPage.pageModified = true; // do not leave the page if we have not applied the change (see onunloadHandler)
}

ClientMethod doApply() [ Language = javascript ]
{
	if (!this.checkEdit()) { 
		zenPage.pageModified = false;
		return false;
	}

	/* look to see if default db is Read Only*/
	if (zenPage.defaultMountedReadOnly()) {
		alert($$$Text("The default database is mounted Read Only."));
		return false;
	}

	var ok = false;
	var id = zen('prodList').getProperty('value');

	/* if shutdown group hidden then any bad data will have come from the global not user input. Keep same code though */
	try {
		var group = zen('shutdownGroup').getValue().replace(/^\s+|\s+$/g,'');   // Remove leading and trailing spaces
		if ((group.length>1)&&(/^-?[0-9]+$/.test(group))) {group = Number(group)}; // Remove leading 0 provided a base 10 number unless it is just 0
	} catch (ex) {
		alert( $$$FormatText($$$Text("Error: %1"),ex) );
		return false;
	}
	/* if shutdownGroup  not hidden then check the value entered is either 0 or a positive or negative integer */
	if ((id.length > 0)&&(!zen('shutdownGroup').getProperty('hidden'))) {
		if (isNaN(group)||('' === group)||!(group % 1 === 0)||!(/^-?[0-9]+$/.test(group))) {
			alert($$$Text("Value entered for shutdown group is not an integer or 0."));
			return false;
		}
	}

	if ((id.length > 0) && (zenPage.canAccessAll)) {
		ok = confirm($$$FormatText($$$Text("Are you sure you want to set %1 to be in shutdown group %2?"),id,group));
		if (ok) {
			if (group) {
				ret = zenPage.ApplyID(id,group);
			} else {
				ret = zenPage.ApplyID(id,2);
			}
			if (ret.length > 0) alert(ret);
			var table = zen('tblProdsByShutdownGroup');
			if (table) {table.executeQuery();} 
			zenPage.pageModified = false; // we can leave the page if we have applied the change (see onunloadHandler)
		}
	}
}

ClassMethod ApplyID(id, group) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Director).SetProductionShutdownGroup(id,group)
	If $$$ISERR(tSC) {
		Set tmsg = $ZCVT($$$StatusDisplayString(tSC),"O","JS")
		Quit tmsg
	}
	Else {
		Quit ""
	}
}

ClassMethod GetShutdownGroup(id) As %Integer [ ZenMethod ]
{
	Quit ##class(Ens.Director).GetProductionShutdownGroup(id,,0)
}

/// This class method callback is called just before the server-side page
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; check if this user has rights to all namespaces
	#dim tTemp, tIDs
	#dim tPrivCheck As %Status = ##class(%Library.EnsembleMgr).GetNamespacesByShutdownGroup(.tTemp)
	Kill tTemp
	If $$$ISOK(tPrivCheck) {
		Set ..canAccessAll = 1
		For tIDs="lblProdRW","lblStop1","lblStop2","lblNote1","tblProdsByShutdownGroup" {
			Set ..%GetComponentById(tIDs).hidden = "false"
		}
	} Else {
		#; Even if %Admin_Manage cannot edit if not see table
		Set ..canEdit = 0
		Set ..%GetComponentById("lblProdRO").hidden = "false"
	}

	#dim tProductionName
	#dim tShutdownGroup = ##class(Ens.Director).GetRunningProductionShutdownGroup(.tProductionName)
	If (tProductionName '= "") {
		Set ..currentProduction = tProductionName
		Set ..%GetComponentById("prodList").value = tProductionName
		Set ..%GetComponentById("shutdownGroup").value = tShutdownGroup
	}
	Else {
		Set ..%GetComponentById("prodList").value = ""
		Set ..%GetComponentById("shutdownGroup").value = ""
	}

	Quit tSC
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Shutdown Group","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnApply",$$$Text("Apply"),$$$Text("Set the specified shutdown group to the selected production."),"zenPage.doApply();")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "ApplyID": ..#EDITRESOURCE, : "")
}

ClassMethod defaultMountedReadOnly(ByRef pSC As %Status) As %Boolean [ Internal, ZenMethod ]
{
	#dim tIsRO As %Integer = 0
	#dim e As %Exception.SystemException
	#dim tInfo As %String
	Set pSC = $$$OK
	Try {
		Do ##class(%SYS.Namespace).GetNSInfo($namespace,.tInfo)
		Set tIsRO = $G(tInfo("ReadOnly"),0)
		Set pSC = $G(tInfo("Status"),1)
	} Catch e {Set pSC = e.AsStatus()}
	Quit tIsRO
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if ((load)&&(!zenPage.canEdit)) {
			var btnApply = document.getElementById('command_btnApply');
			if (btnApply) {btnApply.className = 'commandButtonDisabled';}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

}
