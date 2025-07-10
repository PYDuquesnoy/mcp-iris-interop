/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Business Partners page of the ZEN application.
Class EnsPortal.BusinessPartners Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Business Partners";

/// Users must have READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

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
cellSpacing="2" 
useSnapshot="true"
maxRows="10000"
pageSize="10000"
queryClass="Ens.Config.BusinessPartner"
queryName="List"
showZebra="true"
useKeys="true"
valueColumn="PartnerName"
onrefresh=""
onselectrow="zenPage.rowSelected(zenThis);"
onunselectrow="zenPage.rowSelected(zenThis);"
>
<column colName="PartnerName" header="Partner Name"/>
<column colName="Description" header="Description"/>
<column colName="PrimaryContact" header="Primary Contact"/>
<column colName="Phone" header="Phone"/>
</tablePane>
</vgroup>
<vgroup id="detailGroup">
<form id="bpForm" cellStyle="padding:3px;">
<hidden name="ID" id="txtID"/>
<text label="Partner Name" name="PartnerName" id="txtPartnerName" size="40" hint="Required. Must be unique." />
<textarea label="Description" name="Description" id="txtDescription" cols="30" rows="1" />

<expando caption="Primary Contact" animate="true" cellStyle="padding:3px;">
<text label="Name" name="PrimaryContactName" id="txtPCName" size="40" />
<text label="Title" name="PrimaryContactTitle" id="txtPCTitle" size="40" />
<text label="Email address" name="PrimaryContactEmail" id="txtPCEmail" size="40" />
<text label="Phone Number" name="PrimaryContactPhone" id="txtPCPhone" size="20" />
<text label="Mobile Phone Number" name="PrimaryContactMobile" id="txtPCMobile" size="20" />
<textarea label="Notes" name="PrimaryContactNotes" id="txtPCNotes" cols="30" rows="1" />
</expando>

<expando caption="Alternate Contact" expanded="false" animate="true" cellStyle="padding:3px;">
<text label="Name" name="AltContactName" id="txtAltName" size="40" />
<text label="Title" name="AltContactTitle" id="txtAltTitle" size="40" />
<text label="Email address" name="AltContactEmail" id="txtAltEmail" size="40" />
<text label="Phone Number" name="AltContactPhone" id="txtAltPhone" size="20" />
<text label="Mobile Phone Number" name="AltContactMobile" id="txtAltMobile" size="20" />
<textarea label="Notes" name="AltContactNotes" id="txtAltNotes" cols="30" rows="1" />
</expando>

<hgroup>
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
	Write $$$Text("Business Partner Profiles define information about the organizations and applications connected to your IRIS system.")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Business Partner Profiles")
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Business Partner Profiles")
}

/// This callback, if implemented returns information used to display
/// the standard ribbon bar.<br/>
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = $$$Text("Business Partner Viewer")
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// User selected a row in the table
ClientMethod rowSelected(table) [ Language = javascript ]
{
	// update details pane using ID value from table
	var idx = table.selectedIndex
	if (idx >= 0) {
		var id = table.getProperty('value');
		this.UpdateDetails(id);
	} else {
		this.resetForm();
	}
}

/// UpdateDetails:
/// Update contents of details pane.
ClassMethod UpdateDetails(id) [ ZenMethod ]
{
	// try to open the object
	Set tObj = ##class(Ens.Config.BusinessPartner).%OpenId(id)
	If $IsObject(tObj) {
		// note: remember ID and PartnerName seperately so that we can track name changes

		&js<
			zen('txtID').setValue('#($ZCVT(id,"O","JS"))#');
			zen('txtPartnerName').setValue('#($ZCVT(id,"O","JS"))#');
			zen('txtDescription').setValue('#($ZCVT(tObj.Description,"O","JS"))#');
			
			zen('txtPCName').setValue('#($ZCVT(tObj.PrimaryContact.Name,"O","JS"))#');
			zen('txtPCTitle').setValue('#($ZCVT(tObj.PrimaryContact.Title,"O","JS"))#');
			zen('txtPCPhone').setValue('#($ZCVT(tObj.PrimaryContact.PhoneNumber,"O","JS"))#');
			zen('txtPCMobile').setValue('#($ZCVT(tObj.PrimaryContact.MobileNumber,"O","JS"))#');
			zen('txtPCEmail').setValue('#($ZCVT(tObj.PrimaryContact.Email,"O","JS"))#');
			zen('txtPCNotes').setValue('#($ZCVT(tObj.PrimaryContact.Notes,"O","JS"))#');

			zen('txtAltName').setValue('#($ZCVT(tObj.AlternativeContact.Name,"O","JS"))#');
			zen('txtAltTitle').setValue('#($ZCVT(tObj.AlternativeContact.Title,"O","JS"))#');
			zen('txtAltPhone').setValue('#($ZCVT(tObj.AlternativeContact.PhoneNumber,"O","JS"))#');
			zen('txtAltMobile').setValue('#($ZCVT(tObj.AlternativeContact.MobileNumber,"O","JS"))#');
			zen('txtAltEmail').setValue('#($ZCVT(tObj.AlternativeContact.Email,"O","JS"))#');
			zen('txtAltNotes').setValue('#($ZCVT(tObj.AlternativeContact.Notes,"O","JS"))#');
		>
	}
	Else {
		&js<alert("Cannot open object!");>
	}
	Quit
}

/// Reset the form programmatically
ClientMethod resetForm() [ Language = javascript ]
{
	var form = zen('bpForm');
	form.reset();
	var table = zen('table')
	table.selectRow(table.selectedIndex);
}

/// User clicked Delete button.
ClientMethod deleteItem() [ Language = javascript ]
{
	var idx = zen('table').selectedIndex;
	var id = (idx >= 0) ? zen('table').getProperty('value') : '';
	if (id!='') {
		if (confirm($$$Text('Are you sure you want to delete this item?'))) {
			var msg = this.DeleteID(id);
			if (''!=msg) {
				alert(msg);
			}
			//zen('table').executeQuery(); // causes page to hang several seconds
			self.document.location = self.document.location; // this works instead
		}
	} else {
		alert($$$Text('Please select a Business Partner row to delete'));
	}
}

/// Delete the given id.
ClassMethod DeleteID(id) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(Ens.Config.BusinessPartner).%DeleteId(id)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Save the contents of the form.
ClientMethod save() [ Language = javascript ]
{
	var id = zen('txtID').getValue();
	var name = zen('txtPartnerName').getValue();

	if (name == '') {
		alert($$$Text('Please provide a name for this item.'));
		return;
	}

	if ((id!='')&&(id!=name)) {
		if (!confirm($$$Text('Do you wish to rename this item? This will not rename references to this item.'))) {
			return;
		}
	}

	var form = zen('bpForm');
	var data = form.getValuesAsObject();
	var msg = this.SaveItem(data);
	if (msg != '') {
		alert(msg);
	}
	else {
		//zen('table').executeQuery(); // causes page to hang several seconds
		self.document.location = self.document.location; // this works instead
	}
}

/// Save the given item.
ClassMethod SaveItem(pItem As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		Set id = pItem.ID
		Set name = pItem.PartnerName
		If ((id'="")&&##class(Ens.Config.BusinessPartner).%ExistsId(id)) {
			If (name'=id) {
				// rename: delete old item
				Set tSC = ##class(Ens.Config.BusinessPartner).%DeleteId(id)
				Set tClsDef = ##class(Ens.Config.BusinessPartner).%New()
			}
			Else {
				// modify old item
				Set tClsDef = ##class(Ens.Config.BusinessPartner).%OpenId(name)
			}
		}
		Else {
			// should be new!
			If (##class(Ens.Config.BusinessPartner).%ExistsId(name)) {
				Set tMsg = $$$Text("This name is already in use")
				Quit
			}
			Set tClsDef = ##class(Ens.Config.BusinessPartner).%New()
		}

		Set tClsDef.PartnerName = pItem.PartnerName
		Set tClsDef.Description = pItem.Description

		Set tClsDef.PrimaryContact.Name = pItem.PrimaryContactName
		Set tClsDef.PrimaryContact.Title = pItem.PrimaryContactTitle
		Set tClsDef.PrimaryContact.PhoneNumber = pItem.PrimaryContactPhone
		Set tClsDef.PrimaryContact.MobileNumber = pItem.PrimaryContactMobile
		Set tClsDef.PrimaryContact.Email = pItem.PrimaryContactEmail
		Set tClsDef.PrimaryContact.Notes = pItem.PrimaryContactNotes

		Set tClsDef.AlternativeContact.Name = pItem.AltContactName
		Set tClsDef.AlternativeContact.Title = pItem.AltContactTitle
		Set tClsDef.AlternativeContact.PhoneNumber = pItem.AltContactPhone
		Set tClsDef.AlternativeContact.MobileNumber = pItem.AltContactMobile
		Set tClsDef.AlternativeContact.Email = pItem.AltContactEmail
		Set tClsDef.AlternativeContact.Notes = pItem.AltContactNotes
		
		Set tSC = tClsDef.%Save()

		// return new id value
		&js<zen('txtID').setValue('#($ZCVT(tClsDef.%Id(),"O","JS"))#')>

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
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

		var tableHgt = hgt;
		var tableWid = winWidth - descDiv.offsetWidth - detailDiv.offsetWidth;

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

}
