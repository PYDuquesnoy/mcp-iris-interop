/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// The first page for Testing Service.
/// If there is a Production running, display the name in the title.
/// If no Production is running or if the Production is not enabled for testing, display an error message and terminate.
/// Populate the "Config Item Name" drop-down according to the selection of "Business Process" or "Business Operation".
/// Allow user to select one item from the list.
/// When user clicks button "Test", present the popup, passing the name of the production and the config item name selected.
Class EnsPortal.TestingService Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Testing Service";

/// User needs USE permissions on the %Ens_TestingService resource to view this page.
Parameter RESOURCE = "%Ens_TestingService:USE";

Property Production As %String(MAXLEN = 128);

Property HostType As %String;

Property HostName As %String(MAXLEN = 128);

XData Style
{
<style type="text/css">
.labelText,.zenLabel {
	font-size: 10pt;
	font-weight: bold;
	padding-right: 5px;
}

#topMessages {
	font-size: 10pt;
}

.errorMessage {
	color: red;
	font-weight: bold;
}

.radioButtonCaption {
	text-decoration: none;
	font-size: 10pt;
	padding-right: 8px;
}


</style>
}

/// Contents of this page
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<spacer width="20" />
<vgroup>
<spacer height="30" />
<html id="topMessages" OnDrawContent="DrawTopMessages" />
<spacer height="30" />
<group id="targetSelectionGroup" hidden="true">
<hgroup>
<label label="Target Type:" />
<radioButton id="typeProcess" name="hostType" value="Process" caption="Business Process" captionClass="radioButtonCaption" title="Select this option to test a Business Process" onclick="zenPage.changeTargetType('P');" valign="top" />
<radioButton id="typeOperation" name="hostType" value="Operation" caption="Business Operation" captionClass="radioButtonCaption" title="Select this option to test a Business Operation" onclick="zenPage.changeTargetType('O');" valign="top" />
</hgroup>
<html><p></p></html>
<hgroup>
<label label="Target Name:" />
<combobox id="cmbTarget" name="cmbTarget" size="80" hzScroll="true" editable="false" onchange="zenPage.changeTargetName();" disabled="true" valign="top">
</combobox>
</hgroup>
<html><p></p></html>
<button id="btnTest" name="btnTest" caption="Test" onclick="zenPage.testThisTarget()" controlClass="commandButton" title="Test the selected target item." />
</group>
</vgroup>
</hgroup>
</pane>
}

/// Draw the messages at the top of the contents panel.
/// If there is a running Production enabled for testing, make visible the controls to select target type and name.
Method DrawTopMessages(pSeed As %String) As %Status
{
	Write $$$TextHTML("You can use this page to manually test Business Processes and Business Operations.")
	Write "<br><p>"
	Set tProduction = ..GetRunningProduction()
	If tProduction ="" {
		Write "<span class='errorMessage'>",$$$TextHTML("No Production is running. In order to use the Testing Service you must start a Production."),"</span>"
	}
	Else {
		Set tEnabled = ..GetIsTestingEnabled(tProduction)
		If 'tEnabled {
			Write "<span class='errorMessage'>",$$$TextHTML("In order to use the Testing Service you must enable testing for this Production."),"</span>"
		}
		Else {
			Write $$$TextHTML("To proceed, select the test target below.")
			Set %page.Production = tProduction
			Set ..%GetComponentById("targetSelectionGroup").hidden = 0
		}
	}
	Write "</p>"
	Quit $$$OK
}

/// Return the name of the running production, or null if no production is currently running.
ClassMethod GetRunningProduction() As %String
{
	If $Data($$$EnsRuntime) {
		Quit $G($$$EnsRuntime("Name"))
	}
	Else {
		Quit ""
	}
}

/// Return a boolean indicating if the production is enabled for testing or not.
ClassMethod GetIsTestingEnabled(pProduction) As %Boolean
{
	Set tEnabled = 0

	If ##class(Ens.Config.DefaultSettings).%GetSetting(pProduction,"$Production",pProduction,"","TestingEnabled",.tSDSEnabled) {
		Set tEnabled = tSDSEnabled
	} Else {
		&sql(SELECT TestingEnabled INTO :e
			FROM Ens_Config.Production
			WHERE Name = :pProduction)

		If (SQLCODE = 0) && e {
			Set tEnabled = 1
		}
	}

	Quit tEnabled
}

/// Populate control with the list of hosts of the given type.
/// Type can be "P" (Process) or "O" (Operation).
Method populateListOfHosts(pType As %String) [ ZenMethod ]
{
	Set tControl = %page.%GetComponentById("cmbTarget")
	Set tControl.disabled = "false"
	Set tProduction = %page.Production

	If pType = "P" {
		&sql(DECLARE sql1 CURSOR FOR
			SELECT Name,ClassName INTO :tName, :tCls
			FROM Ens_Config.Item
			WHERE Production->Name = :tProduction
			ORDER BY Name
		)
		&sql(OPEN sql1)
		&sql(FETCH sql1)
		While (SQLCODE = 0) {
			Set tName = $S(tName="":tCls,1:tName)
			If ((tCls'="EnsLib.Testing.Process") && $zobjclassmethod(tCls,"%IsA","Ens.BusinessProcess")) {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tControl.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = tName
				Set tOption.value = tName
			}
			&sql(FETCH sql1)
		}
		&sql(CLOSE sql1)
	}

	ElseIf pType = "O" {
		&sql(OPEN sql1)
		&sql(FETCH sql1)
		While (SQLCODE = 0) {
			Set tName = $S(tName="":tCls,1:tName)
			If ($zobjclassmethod(tCls,"%IsA","Ens.BusinessOperation")) {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tControl.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = tName
				Set tOption.value = tName
			}
			&sql(FETCH sql1)
		}
		&sql(CLOSE sql1)
	}
	Else {
		// This should never happen
	}

	// If there is only one option, select it
	If tControl.options.Count()=1 {
		Set tDefChoice = tControl.options.GetAt(1).value
		Set tControl.value = tDefChoice
		Set %page.HostName = tDefChoice
	}
}

/// User selected/changed a target type.
/// Load the target name control with the config item names of that type.
ClientMethod changeTargetType(type) [ Language = javascript ]
{
	zenPage.HostType = type;
	zen('cmbTarget').resetOptions();
	zenPage.populateListOfHosts(type);
}

/// User selected a target name.
ClientMethod changeTargetName() [ Language = javascript ]
{
	var name = zen('cmbTarget').getValue();
	zenPage.HostName = name;
}

/// Invoked when the user clicks the "Test" button.
/// Check if a target has been selected and pass it on to the popup dialog.
ClientMethod testThisTarget() [ Language = javascript ]
{
	if (zenPage.Production=='') {
		alert($$$Text('No Production is running'));
	}
	else if (zenPage.HostType=='') {
		alert($$$Text('Please select the target type (Business Process or Business Operation)'));
	}
	else if (zenPage.HostName=='') {
		alert($$$Text('Please select the name of the configuration item to be tested'));
	}
	else {
		var parms = {
			PRODUCTION:zenPage.Production,
			HOSTTYPE:zenPage.HostType,
			HOSTNAME:zenPage.HostName
				};
		var url = this.GetDialogURL();
		zenLaunchPopupWindow(url,'','status,scrollbars,resizable=yes,left=100,top=100,width=1000,height=800',parms);
	}
}

Method GetDialogURL() As %String [ ZenMethod ]
{
	Quit ..Link("EnsPortal.Dialog.TestingService.cls")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Testing Service","Ensemble")
}

/// Get the (localized) title string for the page.
/// If there is a production running, its name will appear here; otherwise, we use the page name.
Method %OnGetTitle() As %String
{
	Set tProduction = ..GetRunningProduction()
	If tProduction'="" {
		Quit tProduction
	}
	Else {
		Quit ..%OnGetPageName()
	}
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Quit $$$OK
}

}
