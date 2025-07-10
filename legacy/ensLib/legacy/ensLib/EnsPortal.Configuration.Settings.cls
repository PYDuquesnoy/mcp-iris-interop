/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

Class EnsPortal.Configuration.Settings Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Configure Interoperability Settings";

Parameter RESOURCE = "%Admin_Manage:USE";

Parameter EDITRESOURCE = "%Admin_Manage:USE";

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
<hgroup>
<titleBox id="id_Settings" title="Change the setting as required, then click Apply"
		subtitle="" />
<spacer width="30"/>
<button caption="Apply" id="btnApply" onclick="zenPage.doApply();" controlClass="commandButton" title="Save" />
</hgroup>
<spacer height="20" />
<hgroup>
<titleBox id="id_SettingsNspSpecific" title="Namespace Specific" titleStyle="border-bottom:0px;font-weight:normal"
		subtitle="" />
</hgroup>
<spacer height="20" />
<hgroup>
<vgroup labelPosition="left">
<checkbox id="chkProdSCExclude" label="Exclude Production Configuration Page from Source Control" enclosingStyle="padding-bottom:4px;"/>
</vgroup>
</hgroup>
<spacer height="10"/>
<hgroup>
<vgroup labelPosition="left">
<checkbox id="chkDisableInactivity" title="Controls Automatic Logout Behavior of the Interoperability Management Portal Pages" label="Disable Inactivity Timeout for Interoperability Pages" enclosingStyle="padding-bottom:4px;"/>
</vgroup>
</hgroup>
<spacer height="10"/>
<hgroup>
<vgroup labelPosition="left">
<checkbox id="chkPurgeJournalData" title="Controls the transactional recording of old data values in the journal file when purging. When this setting is off there will be less written to the journal files during purging. Note: recording of the actual delete actions remain configured to be journalled irrespective of this setting." label="Enable Journalling of deleted data values when purging" enclosingStyle="padding-bottom:4px;"/>
</vgroup>
</hgroup>
<spacer height="40" />
<hgroup>
<titleBox id="id_SettingsInstance" title="All Namespaces" titleStyle="border-bottom:0px;font-weight:normal"
		subtitle="" />
</hgroup>
<spacer height="20" />
<hgroup>
<vgroup labelPosition="left">
<checkbox id="chkEnableRefresh" title="Controls Enabling Automatic Refreshes of Management Portal Pages" label="Permit Enabling Automatic Refresh of Management Portal Pages" enclosingStyle="padding-bottom:4px;"/>
</vgroup>
</hgroup>
</vgroup>
</hgroup>
</pane>
}

ClientMethod doApply() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }

	// Convert to 1 or 0 from true or false
	var check = +zen('chkProdSCExclude').getProperty('value');
	ret = zenPage.ProdSCExclude(check);
	var noAlerts = 1;
	if ((ret) && (ret.length > 0)) {
		alert(ret);
		noAlerts = 0;
	}

	check = +zen('chkDisableInactivity').getProperty('value');
	ret = zenPage.DisableInactivity(check);
	if ((ret) && (ret.length > 0)) {
		alert(ret);
		noAlerts = 0;
	}

	check = +zen('chkPurgeJournalData').getProperty('value');
	ret = zenPage.PurgeJournalData(check);
	if ((ret) && (ret.length > 0)) {
		alert(ret);
		noAlerts = 0;
	}

	check = +zen('chkEnableRefresh').getProperty('value');
	ret = zenPage.EnableRefresh(check);
	if ((ret) && (ret.length > 0)) {
		alert(ret);
		noAlerts = 0;
	}

	if (noAlerts) {
		alert($$$Text('All Settings saved successfully'));
	}
}

Method ProdSCExclude(check) As %String [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	Try {
		Do ##class(Ens.Util.Production).SetExcludeFromPortalSourceControl(..NormalizeCheck(check))
	} Catch ex {
		Return $ZCVT($$$StatusDisplayString(ex.AsStatus()),"O","JS")
	}
	Return ""
}

Method DisableInactivity(check) As %String [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	Try {
		Set ^EnsPortal("DisableInactivityTimeout","Portal") = ..NormalizeCheck(check)
	} Catch ex {
		Return $ZCVT($$$StatusDisplayString(ex.AsStatus()),"O","JS")
	}
	Return ""
}

Method PurgeJournalData(check) As %String [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	Try {
		Set $$$EnsPurgeJournalOldData = ..NormalizeCheck(check)
	} Catch ex {
		Return $ZCVT($$$StatusDisplayString(ex.AsStatus()),"O","JS")
	}
	Return ""
}

Method EnableRefresh(check) As %String [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	Try {
		Set ^%SYS("Portal","EnableAutoRefresh") = ..NormalizeCheck(check)
	} Catch ex {
		Return $ZCVT($$$StatusDisplayString(ex.AsStatus()),"O","JS")
	}
	Return ""
}

/// This class method callback is called just before the server-side page
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Return tSC
	#dim tCheckBox = ..%GetComponentById("chkProdSCExclude")
	Set tCheckBox.value = ##class(Ens.Util.Production).IsExcludedFromPortalSourceControl()
	#dim tInactivityCheckBox = ..%GetComponentById("chkDisableInactivity")
	Set tInactivityCheckBox.value = ''$Get(^EnsPortal("DisableInactivityTimeout","Portal"))
	#dim tPurgeJournalDataCheckBox = ..%GetComponentById("chkPurgeJournalData")
	Set tPurgeJournalDataCheckBox.value = $$$EnsPurgeJournalOldDataGet
	#dim tEnableRefreshCheckBox = ..%GetComponentById("chkEnableRefresh")
	Set tEnableRefreshCheckBox.value = ''$Get(^%SYS("Portal","EnableAutoRefresh"))
	Return tSC
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Return ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Return $$$Text("Configure Interoperability Settings","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 0
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Return $$$OK
}

ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Return $case(pMethod, 
			"ProdSCExclude"		: ..#EDITRESOURCE,
			"DisableInactivity"	: ..#EDITRESOURCE,
			"PurgeJournalData"	: ..#EDITRESOURCE,
			"EnableRefresh"		: ..#EDITRESOURCE,
								: ""
			)
}

Method NormalizeCheck(check) As %String [ Internal, Private ]
{
	#; check ought to come in as 1 or 0
	If (check="true") {
		Set check = 1
	} ElseIf (''check '= check) {
		Set check = 0
	}
	Return check
}

}
