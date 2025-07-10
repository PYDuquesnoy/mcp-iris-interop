/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

Class EnsPortal.Setting.Report.Configuration Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Configure Settings Report Locations";

/// User must have READ permissions on the "%Ens_SettingsReportConfig" resource to view this page.
Parameter RESOURCE = "%Ens_SettingsReportConfig:READ";

/// User must have WRITE permissions on the "%Ens_SettingsReportConfig" resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_SettingsReportConfig:WRITE";

/// Setting Report Class being managed. 
Property reportClass As %String [ InitialExpression = "Ens.Setting.Report.Port", Internal, Private ];

Property reporterInstance As Ens.Setting.Reporter [ Internal, Private ];

Property reportNamespace As %String [ Internal, Private ];

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
<titleBox id="id_NspTitle" title="Select the namespace where Setting Report data will be saved, then click Apply"
		subtitle="" />
<spacer height="20" />
<hgroup>
<combobox id="cmbNamespace" label="Namespace:"
	editable="false">
</combobox>
<spacer width="30"/>
<button caption="Apply" id="btnApply" onclick="zenPage.doApply();" controlClass="commandButton" title="Save Namespace Setting" />
</hgroup>
</vgroup>
<spacer height="10" />

</hgroup>
</pane>
}

ClientMethod doApply() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }

	var nsp = zen('cmbNamespace').getProperty('value');
	if ((nsp.length > 0) && (nsp !== this.reportNamespace)) {
		ok = confirm($$$FormatText($$$Text("Are you sure you want to set %1 to be the namespace where Setting Report data is stored?"),nsp));
		if (ok) {
			ret = zenPage.ApplyNamespace(nsp);
			if ((ret) && (ret.length > 0)) {
				alert(ret);
				var nspCombo = zen('cmbNamespace');
				if (nspCombo) nspCombo.setProperty('value',this.reportNamespace);
			} else {
				this.reportNamespace = nsp ;
				alert($$$Text('Setting saved successfully'));
			}
		} else {
			var nspCombo = zen('cmbNamespace');
			if (nspCombo) nspCombo.setProperty('value',this.reportNamespace);
		}
	}
}

Method ApplyNamespace(nsp) As %String [ ZenMethod ]
{
	If '$IsObject(..reporterInstance) Set ..reporterInstance = ..reporterInstanceNewObject()
	Set ..reporterInstance.SettingReportClass = ..reportClass

	#dim tSC = ..reporterInstance.SetPersistentReportNamespace(nsp,1)

	If $$$ISERR(tSC) {
		#dim tmsg = $ZCVT($$$StatusDisplayString(tSC),"O","JS")
		Return tmsg
	}
	Else {
		Return ""
	}
}

/// This class method callback is called just before the server-side page
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Return tSC
	#dim tCombo = ..%GetComponentById("cmbNamespace")
	#dim tNS = $O(^%SYS("Ensemble","InstalledNamespace",""))
	While tNS '= "" {
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = tNS
		Set tOption.value = tNS
		Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",tNS))
	}

	Set ..reporterInstance = ..reporterInstanceNewObject()
	Set ..reporterInstance.SettingReportClass = ..reportClass

	If $$$ISOK(tSC) {

		Set ..reportNamespace = ..reporterInstance.GetPersistentReportNamespace(.tSC)

		If $$$ISOK(tSC) {

			Set ..%GetComponentById("cmbNamespace").value = ..reportNamespace

		}

	}

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
	Return $$$Text("Setting Report Configuration","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 0
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Return $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Return $case(pMethod, "ApplyNamespace": ..#EDITRESOURCE, : "")
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if ( zen('cmbNamespace') && (zen('cmbNamespace').getProperty('value') !== this.reportNamespace) ) {
		return $$$Text('Changes have been made on this page.','%Utility')+'\n'+$$$Text('Do you wish to leave the page and discard the changes?','%Utility');
	}
	return true;
}

}
