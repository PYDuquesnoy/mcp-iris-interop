/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Credentials page of the ZEN application.
Class EnsPortal.Credentials Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Credentials";

/// User needs READ permissions on the %Ens_Credentials resource to view this page.
Parameter RESOURCE = "%Ens_Credentials:READ";

/// User needs WRITE permissions on the %Ens_Credentials resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Credentials:WRITE";

/// ID of credentials to display.
Property credentialsId As %String(ZENURL = "ID");

/// Whether or not the URL supplied a valid credentials ID value
Property idExists As %ZEN.Datatype.boolean;

/// Whether or not the page should warn upon reload
Property skipWarning As %ZEN.Datatype.boolean;

/// Whether or not the user has modified the password
Property passwordChanged As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	color: #404040;
	font-size: 10pt;
}

.tnbrTable {
	border: 1px solid #808080;
	background: #D0D0D0;
	background-image: none;
}

#tableGroup {
	overflow: hidden;
	border-right: 1px solid #F0F0F0;
	border-left: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#descriptionPanel {
	width: 200px;
	background: white;
	font-size: 11pt;
	color: #404040;
	padding: 8px;
	overflow: auto;
}

#detailGroup {
	width: 350px;
	background: #E0E0D0;
	overflow: auto;
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#tableGroup {
	overflow: auto;
}

/* style for table pane */
table.tpTable {
	background: white;
}

table.tpTable th {
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
	background: #D0D0D0;
	background-image: none;
}

table.tpTable th.tpHdrSelected {
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
	background: #D0D0F0;
	background-image: none;
}

.page {
	width: auto;
	height: auto;
}

</style>
}

/// This XML block defines the contents of the main pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="pane" hidden="true">
<hgroup cellVAlign="top">
<html id="descriptionPanel" OnDrawContent="DrawDescription" />
<vgroup id="tableGroup">
<tablePane id="table" 
enableToggleSelect = "true"
cellSpacing="2"
useSnapshot="true"
maxRows="10000"
pageSize="10000"
queryClass="Ens.Config.Credentials"
queryName="List"
showZebra="true"
valueColumn="ID"
onselectrow="zenPage.rowSelected(zenThis);"
onunselectrow="zenPage.rowSelected(zenThis,1);"
>
<column colName="ID" header="ID"/>
<column colName="Username" header="User name" OnDrawCell="TruncateDisplay" />
<column colName="Password" header="Password"/>
<column colName="BusinessPartner" header="Business Partner" OnDrawCell="TruncateDisplay"/>
</tablePane>
</vgroup>
<vgroup id="detailGroup">
<form id="credForm" cellStyle="padding:3px;">
<hidden name="ID" id="txtID"/>
<text label="ID" name="SystemName" id="txtSystemName" size="35" hint="Identifier for this item" onkeyup="zenPage.setModified(true);"/>
<text label="User Name" name="Username" id="txtUsername" size="35" hint="User name used to connect to external system" onkeyup="zenPage.setModified(true);"/>
<password label="Password" name="Password" id="txtPassword" size="35" hint="Password used to connect to external system" onchange="zenPage.setModified(true); zenPage.editPassword(false);"/>
<textarea label="Password" name="Password" id="txtVisiblePassword" cols="28" rows="1" hint="Password used to connect to external system" onchange="zenPage.setModified(true); zenPage.editPassword(true);" hidden="true"/>
<hgroup>
<checkbox id="showPassword" onchange="zenPage.togglePasswordVisibility();"/>
<label hint="Show typing" />
</hgroup>
<hgroup label="Business Partner"  hint="Name of Business Partner Profile associated with this item">
<selector name="BusinessPartner" id="selBusinessPartner" context="Ens.ContextSearch/BusinessPartners" size="30" onkeyup="zenPage.setModified(true);" onchange="zenPage.setModified(true);"/>
<image src="deepsee/zoom_24.png" id="btnBusinessPartner" title="Show details for the selected Business Partner. Click the link below to go to the Business Partners configuration page." onclick="zenPage.showPartnerDetails();"/>
</hgroup>
<link caption="Business Partners Configuration Page" title="Click here to go to the Business Partners configuration page." href="EnsPortal.BusinessPartners.zen"/>
<spacer height="5"/>
<hgroup>
<button controlClass="commandButton" id="btnNew" caption="New" onclick="zenPage.doNew();"/>
<spacer width="5" />
<button controlClass="commandButton" id="btnSave" caption="Save" onclick="zenPage.save();"/>
<spacer width="5" />
<button controlClass="commandButtonRemove" id="btnRemove" caption="Remove" onclick="zenPage.deleteItem();" />
</hgroup>
</form>
</vgroup>
</hgroup>
</pane>
}

/// Draw the contents of the description panel.
Method DrawDescription(pSeed As %String) As %Status
{
	Write $$$Text("Credentials are your authorization keys to connect to systems and applications outside IRIS.")
	Write "<br/>"
	Write "<br/>"

	Write $$$Text("The table shows all the credentials currently defined for this namespace.")
	Write $$$Text("You can use the form on the right to create, edit, or delete credentials.")

	Quit $$$OK
}

/// Truncate the displayed value to fit on the page better
Method TruncateDisplay(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tDisplayLen = 60
	Set tVal = %query(pName)
	
	If $L(tVal) > tDisplayLen {
		Set tVal = $E(tVal,1,tDisplayLen)_"..."
	}
	Write $zcvt(tVal,"O","HTML")
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Credentials")
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Credentials")
}

/// This callback, if implemented returns information used to display
/// the standard ribbon bar.<br/>
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = $$$Text("Credentials Viewer")
	Quit $$$OK
}

/// User selected a row in the table
ClientMethod rowSelected(table, unselect) [ Language = javascript ]
{
	// update details pane using ID value from table
	var idx = table.selectedIndex
	if ((idx >= 0)&&(!unselect)) {
		var id = table.getProperty('value');
		this.UpdateDetails(id);
	} else {
		this.resetForm(); // this deletes the src value from the <image> component on more than one browser
		zen('btnBusinessPartner').setProperty('src','deepsee/zoom_24.png'); // reset the deleted src value
	}
}

/// UpdateDetails:
/// Update contents of details pane.
ClassMethod UpdateDetails(id) [ ZenMethod ]
{
	// try to open the object
	Set tObj = ##class(Ens.Config.Credentials).%OpenId(id)
	If $IsObject(tObj) {
		&js<zen('txtID').setValue('#($ZCVT(id,"O","JS"))#');>
		&js<zen('txtSystemName').setValue('#($ZCVT(id,"O","JS"))#');>
		// set value into variable 'x' first in order to avoid possible MAXSTRING error if Username is maximum length
		&js<var x;>
		&js<x='#($ZCVT(tObj.Username,"O","JS"))#';>
		&js<zen('txtUsername').setValue(x);>
		&js<zen('txtPassword').setValue('');>
		&js<zen('selBusinessPartner').setValue('#($ZCVT(tObj.BusinessPartner,"O","JS"))#');>
	}
	Else {
		&js<alert("Cannot open object!");>
	}
	Quit
}

/// Reset the form programmatically
ClientMethod resetForm() [ Language = javascript ]
{
	if (zenPage._ResettingForm) return;
	zenPage._ResettingForm=true;
	var form = zen('credForm');
	form.reset();
	var table = zen('table')
	table.selectRow(table.selectedIndex);
	zenPage._ResettingForm=false;
}

/// User clicked Delete button.
ClientMethod deleteItem() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var idx = zen('table').selectedIndex;
	var id = (idx >= 0) ? zen('table').getProperty('value') : '';
	if (id!='') {
		if (confirm($$$Text('Are you sure you want to delete this item?'))) {
			var msg = this.DeleteID(id);
			if (''!=msg) {
				alert(msg);
			}
			//zen('table').executeQuery(); // causes page to hang several seconds
			zenPage.skipWarning = true;
			self.document.location = self.document.location; // this works instead
		}
	} else {
		alert($$$Text('Please select a Credentials row to delete'));
	}
}

/// Delete the given id.
ClassMethod DeleteID(id) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(Ens.Config.Credentials).%DeleteId(id)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Save the contents of the form.
ClientMethod save() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var id = zen('txtID').getValue();
	var name = zen('txtSystemName').getValue();

	if (name == '') {
		alert($$$Text("Please provide an identifier for this item."));
		return;
	}

	if ((id!='')&&(id!=name)) {
		if (!confirm($$$Text("Do you wish to rename this item? This will not rename references to this item."))) {
			return;
		}
	}

	try {
		var user = zen('txtUsername').getValue();
		var bp = zen('selBusinessPartner').getValue();
		var pw = zen('txtPassword').getValue();
		var msg = this.SaveItem(zenPage.passwordChanged, id, name, user, pw, bp);
	} catch(err) {
		var msg = err.message;
	}
	if (msg != '') {
		alert(msg);
	}
	else {
		//zen('table').executeQuery(); // causes page to hang several seconds
		zenPage.skipWarning = true;
		self.document.location = self.document.location; // this works instead
		zenPage.resetFieldState();
	}
}

/// Reset the fields that control whether or not to warn the user about leaving the page
ClientMethod resetFieldState() [ Language = javascript ]
{
	zenPage.setModified(false);
	zenPage.skipWarning = false;
	zenPage.passwordChanged = false;
}

/// Save the given item.
ClassMethod SaveItem(pPWChanged As %Boolean, pID As %String, pSystemName As %String, pUsername As %String, pPassword As %String, pBusinessPartner As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		// test to see if we are replacing an old item, modifying an old item, or creating a new item
		If ((pID'="")&&##class(Ens.Config.Credentials).%ExistsId(pID)) {
			If (pSystemName'=pID) {
				// rename: delete old item
				Set tSC = ##class(Ens.Config.Credentials).%DeleteId(pID)
				Set tClsDef = ##class(Ens.Config.Credentials).%New()
			}
			Else {
				// modify old item
				Set tClsDef = ##class(Ens.Config.Credentials).%OpenId(pSystemName)
			}
		}
		Else {
			// should be new!
			If (##class(Ens.Config.Credentials).%ExistsId(pSystemName)) {
				Set tMsg = $$$Text("This id is already in use")
				Quit
			}
			Set tClsDef = ##class(Ens.Config.Credentials).%New()
		}

		Set tClsDef.SystemName = pSystemName

		// if it's long it may be received as a stream
		If $IsObject(pUsername) {
			Set tUsername = "", tNextChunk = ""
			Set tUserMaxLen = $$$comMemberArrayGet("Ens.Config.Credentials",$$$cCLASSproperty,"Username",$$$cPROPparameter,"MAXLEN")
			While 'pUsername.AtEnd {
				Set tNextChunk = pUsername.Read()
				If ($L(tUsername) + $L(tNextChunk)) > tUserMaxLen {
					Set tMsg = $$$FormatText($$$Text("Username exceeds maximum allowed length of %1"),tUserMaxLen)
					Quit
				}
				Set tUsername = tUsername_tNextChunk
			}
			Quit:(""'=tMsg)
			Set tClsDef.Username = tUsername
		} Else {
			// values longer than the maxlength won't be passed in as a string
			Set tClsDef.Username = pUsername
		}
		If (pPWChanged) {
			// if it's long it may be received as a stream
			If $IsObject(pPassword) {
				Set tPassword = "", tNextChunk = ""
				While 'pPassword.AtEnd {
					Set tNextChunk = pPassword.Read()
					If ($L(tPassword) + $L(tNextChunk)) > $$$MaxStringLength {
						Set tMsg = $$$FormatText($$$Text("Password exceeds maximum allowed length of %1"),$$$MaxStringLength)
						Quit
					}
					Set tPassword = tPassword_tNextChunk
				}
				Quit:(""'=tMsg)
			} Else {
				// values longer than MaxStringLength won't be passed in as a string
				Set tPassword = pPassword
			}
			Set tSC = tClsDef.PasswordSet(tPassword)
		}
		
		If tSC {
			Set tClsDef.BusinessPartner = pBusinessPartner
			Set tSC = tClsDef.%Save()
			// return new id value
			&js<zen('txtID').setValue('#($ZCVT(tClsDef.%Id(),"O","JS"))#')>
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClientMethod doNew() [ Language = javascript ]
{
	if (zenPage.pageModified) {
		if (!confirm($$$Text('Changes have been made on this page.')+'\n'+
		             $$$Text('Do you wish to discard the changes and start creating a new credentials record?'))) {
			return;
		}
	}
	// Un-select row in table
	var tbl = zenPage.getComponentById('table');
	tbl.selectRow(-1, false);
	// And clear the fields
	zen("txtID").setValue("");
	zen("txtSystemName").setValue("");
	zen("txtUsername").setValue("");
	zen("txtPassword").setValue("");
	zen("selBusinessPartner").setValue("");
	zenPage.passwordChanged = false;
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

/// A keystroke was entered in the Password field
ClientMethod editPassword(visible) [ Language = javascript ]
{
	var pwd = zenPage.getComponentById('txtPassword');
	var vpw = zenPage.getComponentById('txtVisiblePassword');
	var pw = '';
	if (visible) {
		pw = vpw.getValue();
		pwd.setValue(pw);
	} else {
		pw = pwd.getValue();
		vpw.setValue(pw);
	}

	var pwdLen = pw.length;
	if (pwdLen == 0) {
		zenPage.passwordChanged = false;
	} else {
		zenPage.passwordChanged = true;
	}
}

/// Switch between visible and obfuscated password fields
ClientMethod togglePasswordVisibility() [ Language = javascript ]
{
	var pwd = zenPage.getComponentById('txtPassword');
	var vpw = zenPage.getComponentById('txtVisiblePassword');
	var chkbox = zenPage.getComponentById('showPassword');
	var checked = chkbox.getProperty('value');
	if (checked) {
		pwd.setProperty('hidden', true);
		vpw.setProperty('hidden', false);
	} else {
		pwd.setProperty('hidden', false);
		vpw.setProperty('hidden', true);
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		if (this.inResizeLoop()) return;
		zen('pane').setHidden(false);

		var descDiv = zen('descriptionPanel').getEnclosingDiv();
		var tgDiv = zen('tableGroup').getEnclosingDiv();
		var tableDiv = zen('table').getEnclosingDiv();
		var detailDiv = zen('detailGroup').getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25;

		var tableHgt = hgt - 10;
		var tableWid = winWidth - descDiv.offsetWidth - detailDiv.offsetWidth - 20;

		descDiv.style.height = tableHgt + 'px';
		detailDiv.style.height = tableHgt + 'px';
		tgDiv.style.height = tableHgt + 'px';
		tgDiv.style.width = tableWid + 'px';
		tableDiv.style.width = tableWid + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Launch the profile info dialog.
ClientMethod showPartnerDetails() [ Language = javascript ]
{
	var bpName = zen('selBusinessPartner').getValue();
	if (''==bpName) {
		alert($$$Text("Click here after selecting a business partner to see the business partner's details"));
		return;
	}
	var parms = {
		NAME:bpName
	};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessPartnerDetails.zen'),'','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set %page.idExists = 0
	If %page.credentialsId '= "" { // try to match the provided id to an existing credential
		If ##class(Ens.Config.Credentials).%ExistsId(%page.credentialsId) {
			Set %page.idExists = 1
			Set tObj = ##class(Ens.Config.Credentials).%OpenId(%page.credentialsId)
			Set ..%GetComponentById("txtID").value = %page.credentialsId
			Set ..%GetComponentById("txtSystemName").value = %page.credentialsId
			Set ..%GetComponentById("txtUsername").value = tObj.Username
			Set ..%GetComponentById("txtPassword").value = tObj.Password
			Set ..%GetComponentById("selBusinessPartner").value = tObj.BusinessPartner
			Kill tObj
		} 
	}

	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	if (zenPage.idExists) { // a valid id value was supplied
		var tab = zen('table');
        var rowCount = parseInt(tab.rowCount); // table.rowCount can be a string value
		for (i = 0; i < rowCount; i++) { // highlight the row for the currently selected id
            var rowData = tab.getRenderedRowData(i);
            if (rowData && rowData.ID && (rowData.ID == zenPage.credentialsId))  {
                tab.setProperty('selectedIndex',i);
                return true;
            }		
        }
	}
	var pwd = zenPage.getComponentById('txtPassword');
	var pwdCtl = pwd.findElement('control');
	pwdCtl.placeholder = $$$Text('Password hidden. Click to enter new password.');
	zenPage.skipWarning = false;
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if ((!zenPage.skipWarning) && (this.pageModified)) {
		return $$$Text('Changes have been made on this page.')+'\n'+$$$Text('Do you wish to leave the page and discard the changes?');
	}
	return true;
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, 
						"DeleteID": ..#EDITRESOURCE,
						"SaveItem": ..#EDITRESOURCE,
							: "")
}

}
