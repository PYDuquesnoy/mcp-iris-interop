/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This is the Productions page of the ZEN application.
Class EnsPortal.AutoStartProduction Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Auto-Start Production";

/// User needs READ permissions on the %Ens_ProductionConfig resource to access this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_ProductionConfig:WRITE";

/// If user cannot access Ens.AutoStart in all namespaces we will not show the table
Property canAccessAll As %Boolean [ InitialExpression = 0 ];

Property currentAutoStartProduction As %String;

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
<label label="Choose a production to start automatically in this namespace on startup, then click Apply:" labelStyle="font-size:12pt;" />
<spacer height="10" />
<label id="lblPrio1" hidden="true" label="Productions are started in order of highest priority to lowest." labelStyle="font-size:10pt;" />
<spacer height="5" />
<label id="lblPrio2" hidden="true" label="Those with equal priority will be started alphabetically according to namespace name." labelStyle="font-size:10pt;" />
<spacer height="20" />
<dataCombo
	id="prodList"
	queryClass="Ens.Config.Production"
	queryName="Extent"
	size="85"
	onchange="zenPage.getrecommendAndWarn();"
	/>
<spacer height="10"/>
	<hgroup hidden="true" id="grpPrio">
	<label label="Relative Startup Priority:"/>
	<spacer width="4px" />
	<text name="StartupPriority"
		id="startupPriority"
		size="5"
		value="0"
		onchange="zenPage.doWarning();"
		/>
	</hgroup>
<spacer height="20"/>
<tablePane id ="tblProdsByPriority"
	hidden="true"
	caption="Startup sequence priorities for productions set to Auto-Start:"
	queryClass="%EnsembleMgr"
	queryName="ListProductionsByAutoStartPriority"
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
	if (zenPage.currentAutoStartProduction === id) return;
	zenPage.currentAutoStartProduction = id;
	var priorityObject = zen('startupPriority');
	/* if (priorityObject.getProperty('hidden') {then the user cannot see the priority setting and it is being changed} */
	if (priorityObject) {
		if (id.length > 0) {
			var recommendedPriority = zenPage.GetAutoStartRecommendedPriority(id)
			priorityObject.setProperty('value',recommendedPriority);
		} else {
			priorityObject.setProperty('value','');
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
	if (!this.checkEdit()) { return false; }

	/* look to see if default db is Read Only*/
	if (zenPage.defaultMountedReadOnly()) {
		alert($$$Text("The default database is mounted Read Only."));
		return false;
	}

	var id = zen('prodList').getProperty('value');
	/* if startup priority hidden then any bad data will have come from the global not user input. Keep same code though */
	try {
		var priority = zen('startupPriority').getValue().replace(/^\s+|\s+$/g,'');   // Remove leading and trailing spaces
		if ((priority.length>1)&&(/^-?[0-9]+$/.test(priority))) {priority = Number(priority)}; // Remove leading 0 provided a base 10 number unless it is just 0
	} catch (ex) {
		alert( $$$FormatText($$$Text("Error: %1"),ex) );
		return false;
	}
	/* if startup priority not hidden then check the value entered is either 0 or a positive or negative integer */
	if ((id.length > 0)&&(!zen('startupPriority').getProperty('hidden'))) {
		if (isNaN(priority)||('' === priority)||!(priority % 1 === 0)||!(/^-?[0-9]+$/.test(priority))) {
			alert($$$Text("Value entered for startup priority is not an integer or 0."));
			return false;
		}
	}

	if (id.length > 0) {
		if (zenPage.canAccessAll) {
			ok = confirm($$$FormatText($$$Text("Are you sure you want to start %1 automatically on startup with sequence priority %2?"),id,priority));
		} else {
			ok = confirm($$$FormatText($$$Text("Are you sure you want to start %1 automatically on startup?"),id));
		}
	}
	else {
		ok = confirm($$$Text("Are you sure you want no production to start automatically on startup in this namespace?"));
	}
	if (ok) {
		if (priority) {
			ret = zenPage.ApplyID(id,priority);
		} else {
			ret = zenPage.ApplyID(id,0);
		}
		if (ret.length > 0) alert(ret);
		if (zenPage.canAccessAll) {
			var table = zen('tblProdsByPriority');
			if (table) {table.executeQuery();} 
		}
	}
	zenPage.pageModified = false; // we can leave the page if we have applied the change (see onunloadHandler)
}

ClassMethod ApplyID(id, priority) As %String [ ZenMethod ]
{
	Set tSC = ##class(Ens.Director).SetAutoStart(id,priority)
	If $$$ISERR(tSC) {
		Set tmsg = $ZCVT($$$StatusDisplayString(tSC),"O","JS")
		Quit tmsg
	}
	Else {
		Quit ""
	}
}

ClassMethod GetAutoStartRecommendedPriority(id) As %Integer [ ZenMethod ]
{
	Quit ##class(Ens.Director).GetAutoStartRecommendedPriority(id)
}

/// This class method callback is called just before the server-side page
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	#; check if this user has rights to all namespaces
	#dim tTemp, tIDs
	#dim tPrivCheck As %Status = ##class(%EnsembleMgr).GetNamespacesByStartupPriority(.tTemp)
	Kill tTemp
	If $$$ISOK(tPrivCheck) {
		Set ..canAccessAll = 1
		For tIDs="lblPrio1","lblPrio2","grpPrio","tblProdsByPriority" {
			Set ..%GetComponentById(tIDs).hidden = "false"
		}		
	}
	#dim tProductionName
	If $Data(^Ens.AutoStart,tProductionName)#2 {
		Set ..currentAutoStartProduction = tProductionName
		Set ..%GetComponentById("prodList").value = tProductionName
		Set ..%GetComponentById("startupPriority").value = $G(^Ens.AutoStart("StartupPriority"),0)
	}
	Else {
		Set ..%GetComponentById("prodList").value = ""
		Set ..%GetComponentById("startupPriority").value = ""
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
	Quit $$$Text("Auto-Start Production","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnApply",$$$Text("Apply"),$$$Text("Choose the selected production as the one to auto-start."),"zenPage.doApply();")
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

}
