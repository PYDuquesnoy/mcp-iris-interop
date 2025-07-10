/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Configuring SAP BAPI/RFC through SAPJCo 3.x
/// Functionalities are: a) Import sapjco3.jar b)Generate message proxies for SAP BAPI/RFC
/// MM,2013-03-08
Class EnsPortal.Dialog.SAPJCO.BaseConfiguration Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "SAP BAPI/RFC configuration";

/// Is the user permitted to access the fileSelect popup.
/// MM 2014-03-25
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

XData Style
{
<style type="text/css">
.labelText,.zenLabel {
	font-size: 10pt;
	font-weight: bold;
	padding-right: 5px;
}

.ribbonTitle {
	color: rgb(71,72,67);
	background: lightblue;
}

#topMessages {
	font-size: 10pt;
}

.errorMessage {
	color: red;
}
.positiveMessage {
	color: green;
}

.radioButtonCaption {
	text-decoration: none;
	font-size: 10pt;
	padding-right: 8px;
}
.busy {
	background-color:lightgrey;
}


</style>
}

/// Contents of this page
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane width="600">
<hgroup>
<spacer width="20" />
<vgroup id="completeGroup" enclosingStyle="">
<expando id="expConnect" label="Connection information" expanded="false" onexpand="zen('expBootstrap').setProperty('expanded',false);zen('expSelect').setProperty('expanded',false);">
<label id="lblConnect" label="Please make sure to have a JavaGateway and SAP Operation properly defined and running within the production." />
<html id="htmlConnect" enclosingClass="errorMessage"/>

<text label="SAP Operation" id="SAPOPERATION" title="Name of a SAP Operation which currently runs in this namespace within a production." value=""/>
<spacer height="10" />
<button id="btnChangeConnectInfo" name="btnChangeConnectInfo" 
caption="Change connect information" 
onclick="zenPage.startBusy();zenPage.DoChangeConnectInfo();" controlClass="commandButton" title="Save the connect information to %session." />
<spacer height="60" />
</expando>
<expando id="expBootstrap" label="Import SAPJCO3.jar" expanded="false" onexpand="zen('expConnect').setProperty('expanded',false);zen('expSelect').setProperty('expanded',false);">
<label id="lblBootstrap" label=""/>
<html id="htmlBootstrap" enclosingClass="errorMessage"/>
<text size="80" label="SAPJCo3 Path" id="SAPJCOPATH" title="full path to the sapjco3.jar i.e. C:\\sapjco\\sapjco3.jar" value="" onclick="zenPage.selectJCOjar();"/>
<button id="btnGenerateSAPJCO" name="btnGenerateSAPJCO" caption="Import sapjco3.jar" onclick="zenPage.startBusy();zenPage.DoImportSAPJCO();" controlClass="commandButton" title="Import sapjco3.jar and generate serverside proy classes to use with javagteway." />
<spacer height="60" />
</expando>
<expando id="expSelect" label="Select BAPI/RFC" onexpand="zen('expConnect').setProperty('expanded',false);zen('expBootstrap').setProperty('expanded',false);">
<label id="lblSearch" label="Please enter a text to search for." />
<html id="html" enclosingClass="errorMessage"/>

<hgroup>
<text label="Search" id="txtSearch" value="Search criteria here" title="Fragments of the name of the RFC or BAPI function separated by space."/>
<button valign="bottom" id="btnSearch" name="btnSearch" caption="Search" onclick="zenPage.startBusy();zenPage.DoSearch();" controlClass="commandButton" title="Search for BAPI/RFC on SAP system." />
</hgroup>
<spacer height="10" />
<combobox id="cmbRFCs" name="cmbRFCs" size="80" label="Select RFC/BAPI to generate messages for" hzScroll="true" editable="false" onchange="zen('txtPACKAGE').setProperty('value',zenThis.getProperty('value').replace(/_/gi,'.').replace(/\//gi,'s'));" disabled="false" valign="top">
</combobox>
<text size="80" label="Class Package" id="txtPACKAGE" title="The class package to hold the message classes for this RFC." value=""/>
<button id="btnGenerate" name="btnGenerate" caption="Generate message classes." onclick="zenPage.startBusy();zenPage.DoGenerate();" controlClass="commandButton" title="Generate message classes." />
<spacer height="60" />
</expando>

</vgroup>
</hgroup>
</pane>
}

ClientMethod startBusy() [ Language = javascript ]
{
	zen('completeGroup').setProperty('enclosingClass','busy');
}

ClientMethod endBusy() [ Language = javascript ]
{
	zen('completeGroup').setProperty('enclosingClass','');
}

Method DoGenerate() [ ZenMethod ]
{
	#DEFINE errorMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="errorMessage"
	#DEFINE positiveMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="positiveMessage"
	#DIM success=0
	#DIM tRFC,tClassPath,tChildPID,i
	#DIM waittime=0.5

	set tRFC=%page.%GetComponentById("cmbRFCs").value
	set tClassPath=%page.%GetComponentById("txtPACKAGE").value
	job:tRFC'="" ..GenerateRFCMessageClasses(%session.Data("SAPOPERATION"),tRFC,tClassPath)
	set tChildPID=$ZCHILD
	set ^IRIS.TempSAPJCoClassGeneration(tChildPID,"tSC")=""
	for i=1:waittime:50 {
		quit:^IRIS.TempSAPJCoClassGeneration(tChildPID,"tSC")'=""
		hang waittime
	}
 	
	if +^IRIS.TempSAPJCoClassGeneration(tChildPID,"tSC") {
		$$$positiveMessage($$$Text("Message classes for the BAPI/RFC are now available: ")_tClassPath)
	}else {
		$$$errorMessage($$$Text("Message classes for the BAPI/RFC were not generated.")_"<br/>"_..EscapeHTML($system.Status.GetErrorText(^IRIS.TempSAPJCoClassGeneration(tChildPID,"tSC"))))
	}
	&js<zenPage.endBusy();>
}

Method DoChangeConnectInfo() [ ZenMethod ]
{
	#DEFINE errorMessage(%1) set %page.%GetComponentById("lblConnect").label=%1,%page.%GetComponentById("lblConnect").labelClass="errorMessage"
	#DEFINE positiveMessage(%1) set %page.%GetComponentById("lblConnect").label=%1,%page.%GetComponentById("lblConnect").labelClass="positiveMessage"
	#DIM tUtils,tSC,ex
	
	set %page.%GetComponentById("htmlConnect").content=""
	try {
		set %session.Data("SAPOPERATION")=%page.%GetComponentById("SAPOPERATION").value
		if %session.Data("SAPOPERATION")="" $$$ThrowStatus($$$ERROR(5001,"Input field for SAP Operation is empty."))
		// Try to connect
		Kill %objlasterror
		set tUtils=..GetSAPUtilsObject(%session.Data("SAPOPERATION"))
		If '$IsObject(tUtils) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.SAP.Utils")) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)

		if ##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") {
			#; Connect to SAP
			Set tSC=tUtils.Connect() 
			If 'tSC Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
			$$$positiveMessage($$$Text("Connect to SAP was successful."))
		} else {
			$$$errorMessage("Couldn't connect to SAP. The sapjco3.jar was not imported yet.")
		}
	} catch ex {
		$$$errorMessage($$$Text("A problem was thrown."))
		set %page.%GetComponentById("htmlConnect").content=..EscapeHTML(ex.DisplayString())_"<br/><b>Please check: Is there a typo or is the SAP Operation stopped within the production. Is the production running? Is the Operation of type EnsLib.SAP.Operation? Is the SAP Operation correctly configured and has access to the SAP instance.</b>"
	}
	
	&js<zenPage.endBusy();>
	Quit 1
}

Method DoImportSAPJCO() [ ZenMethod ]
{
	#DEFINE errorMessage(%1) set %page.%GetComponentById("lblBootstrap").label=%1,%page.%GetComponentById("lblBootstrap").labelClass="errorMessage"
	#DEFINE positiveMessage(%1) set %page.%GetComponentById("lblBootstrap").label=%1,%page.%GetComponentById("lblBootstrap").labelClass="positiveMessage"
	#DIM %page as %ZEN.Component.page
	#DIM tUtils as EnsLib.SAP.Utils
	#DIM tSC,i,ex

	set %page.%GetComponentById("htmlBootstrap").content=""
	try {
		If $G(%session.Data("SAPOPERATION"))="" $$$ThrowOnError($$$ERROR(5001,"Input field SAP Operation is empty. Please enter a valid SAP Operation host name."))
		set tUtils=..GetSAPUtilsObject(%session.Data("SAPOPERATION"))
		If '$IsObject(tUtils) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.SAP.Utils")) Quit

		if ##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") {
			job ##class(%SYSTEM.OBJ).DeletePackage("com")
		}
		if ##class(%File).Exists(%page.%GetComponentById("SAPJCOPATH").value)&&(##class(%File).GetFilename(%page.%GetComponentById("SAPJCOPATH").value)="sapjco3.jar") {
			job ##class(EnsLib.SAP.BootStrap).ImportSAP(%page.%GetComponentById("SAPJCOPATH").value,tUtils.JavaGatewayPort,tUtils.JavaGatewayAddress)
			for i=1:1:30 {
				quit:##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo")
				hang 0.7
			}
			if ##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") {
				$$$positiveMessage($$$Text("Importing the sapjco3.jar classes has been successful."))
				set (%page.%GetComponentById("lblSearch").label,%page.%GetComponentById("lblConnect").label)=""
			}else {
				$$$errorMessage($$$Text("Importing the sapjco3.jar classes failed."))
			}
		} else {
			$$$errorMessage($$$Text("Could not find sapjco3.jar at:")_" '"_%page.%GetComponentById("SAPJCOPATH").value_"'.")
		}
	 	
	}
	catch ex {
		$$$errorMessage($$$Text("A problem was thrown."))
		set %page.%GetComponentById("htmlBootstrap").content=..EscapeHTML(ex.DisplayString())_"<br/><b>Please check: Is there a typo or is the SAP Operation stopped within the production. Is the production running? Is the Operation of type EnsLib.SAP.Operation? Is the SAP Operation correctly configured and has access to the SAP instance.</b>"
	}
	&js<zenPage.endBusy();>
}

Method DoSearch() [ ZenMethod ]
{
	#DEFINE errorMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="errorMessage"
	#DEFINE positiveMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="positiveMessage"
	#DIM tSearchString=%page.%GetComponentById("txtSearch").value
	#DIM tUtils,tSC,tRFC,i,ex
	
	set %page.%GetComponentById("html").content=""
	
	try {
		Kill %objlasterror
		
		If $G(%session.Data("SAPOPERATION"))="" $$$ThrowOnError($$$ERROR(5001,"Input field SAP Operation is empty. Please enter a valid SAP Operation host name."))
		If '##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") $$$ThrowOnError($$$ERROR(5001,"Couldn't connect to SAP. The sapjco3.jar was not imported yet."))
				
		set tUtils=..GetSAPUtilsObject(%session.Data("SAPOPERATION"))
		If '$IsObject(tUtils) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.SAP.Utils")) Quit
		
		#; Connect to SAP
		Set tSC=tUtils.Connect() 
		If 'tSC Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tSC=tUtils.GetRFCList(.tRFC,tSearchString)
		If 'tSC Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
		
		#DIM tControl as %ZEN.Component.combobox
		set tControl=%page.%GetComponentById("cmbRFCs")
		set tSC=tControl.options.Clear()
		If 'tSC Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tControl.disabled = "false"
		for i=1:1:tRFC.Count() {
			quit:i>500

			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			do ..%AddComponent(tOption)
			if tOption="" Throw ##class(%Exception.StatusException).CreateFromStatus(%objlasterror)

			Set tOption.text = tRFC.GetAt(i)
			Set tOption.value = tRFC.GetAt(i)
			set tSC=tControl.options.Insert(tOption)
			Throw:'tSC ##class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		set tControl.selectedIndex=""
		set tControl.value=""
		if tRFC.Count()>1 $$$positiveMessage($$$Text("There have been RFCs or BAPIs found. Please select one from the Combobox. BAPI/RFC found: ")_tRFC.Count())
		if tRFC.Count()=1 $$$positiveMessage($$$Text("Exactly one BAPI/RFC has been found and it has been selected."))
		if (+$G(i)>500)&&(tRFC.Count()>0) $$$errorMessage($$$Text("There have been RFCs or BAPIs found. Only 500 will be available in the listbox. Please narrow down your search! BAPI/RFC found:")_tRFC.Count())
		if tRFC.Count()=0 $$$errorMessage($$$Text("No RFC or BAPI was found."))
		set:tRFC.Count()=1 tControl.value=tRFC.GetAt(1)
		
	} catch ex {
		set %page.%GetComponentById("html").content=..EscapeHTML(ex.DisplayString())
		$$$errorMessage($$$Text("A major problem appeared."))
	}
	&js<zenPage.endBusy();>
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

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("SAP BAPI/RFC configuration","Ensemble")
}

/// Get the (localized) title string for the page.
/// If there is a production running, its name will appear here; otherwise, we use the page name.
Method %OnGetTitle() As %String
{
	#DIM tProduction
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

ClassMethod GenerateRFCMessageClasses(pSAPOperationName, pRFC, pPackage) As %Status
{
	#DIM tUtils,tSC=1
	
	set tUtils=..GetSAPUtilsObject(pSAPOperationName)
	If '$IsObject(tUtils) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"EnsLib.SAP.Utils")) Quit tSC
	Set tSC=tUtils.CreateClasses(pRFC,pPackage)
	// If saving is OK, compile will start
	set:+tSC tSC=$system.OBJ.CompilePackage(pPackage)
	Set ^IRIS.TempSAPJCoClassGeneration($JOB,"tSC")=tSC
	Quit tSC
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	#DIM i,tSC = $$$OK
	
	set:$G(%session.Data("SAPOPERATION"))'="" %page.%GetComponentById("SAPOPERATION").value=%session.Data("SAPOPERATION")

	// Basic info if SAPJCo 3.x is available in this instance or not
	if ##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") {
		set %page.%GetComponentById("lblBootstrap").label=$$$Text("The class com.sap.conn.jco.JCo exists. This is a hint that the sapjco3.jar got already imported successfully. If you face problems you might want to import the sapjco3.jar again or import a newer sapjco3.jar because of upgrade reasons.")
		set %page.%GetComponentById("lblBootstrap").labelClass="positiveMessage"
	} else {
		for i="lblBootstrap","lblSearch","lblConnect" {
			set %page.%GetComponentById(i).label=$$$Text("The class com.sap.conn.jco.JCo doesn't exists. Start with importing the sapjco3.jar file.")
			set %page.%GetComponentById(i).labelClass="errorMessage"
		}
	}

	set tSC=##super()
	Quit tSC
}

ClassMethod GetSAPUtilsObject(pConfigName As %String) As EnsLib.SAP.Utils
{
	#DEFINE errorMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="errorMessage"
	#DEFINE positiveMessage(%1) set %page.%GetComponentById("lblSearch").label=%1,%page.%GetComponentById("lblSearch").labelClass="positiveMessage"
	#DIM tPropName

	Set tUtils=##class(EnsLib.SAP.Utils).%New()
	
	// Quit on missing ConfigName
	if $G(pConfigName)="" $$$errorMessage("Missing name for a configuration item of type 'SAP Operation'.")
	Quit:$G(pConfigName)="" ""

	// Quit on not running or not of class EnsLib.SAP.Operation
	if $G(^Ens.Runtime("ConfigItem",pConfigName,"ClassName"))'="EnsLib.SAP.Operation" $$$errorMessage("Missing name for a configuration item of type 'EnsLib.SAP.Operation' or the component is not running.")
	Quit:$G(^Ens.Runtime("ConfigItem",pConfigName,"ClassName"))'="EnsLib.SAP.Operation" ""
	
	
	set tHost=##class(EnsLib.SAP.Operation).%New(pConfigName)
	
	Quit:tHost=""
	
	// Complete list of all relevant properties
	For tPropName="SAPClient","SAPHost","SAPLanguage","SAPUser","SAPPassword","SAPSystemNumber","JavaGatewayAddress","JavaGatewayPort","SAPType","SAPMSHost","SAPGWHost","SAPGWServ","SAPGroup","SAPR3Name" {
		set $zobjproperty(tUtils,tPropName)=$zobjproperty(tHost,tPropName)
	}
	Quit tUtils
}

/// Launch a dialog so the user can choose a file to import a lookup table from.
ClientMethod selectJCOjar() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	parms = {
		Dir:zen('SAPJCOPATH').getValue(),
		wildcard:'sapjco3.jar'
	}
	zenLaunchPopupWindow(
  	zenLink('%ZEN.Dialog.fileSelect.zen'),
  	this.addPopupSuffix('selectJCOjar'),
  	'status,scrollbars,resizable,width=660,height=700',
  	parms);
}

/// Handle various dialogs.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action != "ok") {
			return false;
		}
		popupName = this.removePopupSuffix(popupName);
		switch(popupName) {
			case 'selectJCOjar':
				zen('SAPJCOPATH').setValue(value);
		}
	}
	catch (ex) {
		alert("Error: " + ex);	
	}
}

}
