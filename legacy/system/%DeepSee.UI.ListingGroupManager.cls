/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// DeepSee term list manager page.
/// This page lets you view and edit "term lists" (lookup tables used by DeepSee models).
Class %DeepSee.UI.ListingGroupManager Extends %DeepSee.UI.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "DeepSee Listing Group Manager";

Parameter RESOURCE = "%DeepSee_ListingGroup,%DeepSee_ListingGroupEdit";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE;

Parameter DOCBOOKID;

/// Indicates the page reloaded itself if LISTINGGROUP is empty 
Property reload As %ZEN.Datatype.boolean(ZENURL = "RELOAD") [ InitialExpression = 0 ];

/// The current copy of the listing group
Property %model As %DeepSee.Model.ListingGroup.listingGroup;

/// If true, the user has write access to the page.
Property canWritePage As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, user can modify this particular listing group.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, user is allowed to access teh custom SQL fields.
Property canViewSQL As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Name of listing group.
Property listingGroupName As %ZEN.Datatype.string(ZENURL = "LISTINGGROUP");

Property replaceExisting As %ZEN.Datatype.string(ZENURL = "REPLACE");

/// Source class for these listings
Property dataSource As %ZEN.Datatype.string;

/// Current CSP session.
Property sessionCookie As %ZEN.Datatype.string;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.dynaGridWrapper {
	border: 1px solid #808080;
}

body {
	background: #F8F8F8;
}

.dgCellInner {
	font-size: 12pt;
}

.zenLabel, .checkboxCaption {
	color: #404040;
	font-size: 10pt;
}
.zenLabelDisabled {
	color: #808080;
	font-size: 10pt;
}

.zenHint {
	color: #606060;
	font-size: 8pt;
}

#editGroup {
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

#propertyGroup {
	position: relative;
	width: 320px;
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	border-left: 1px solid #808080;
	border-right: 1px solid #808080;
	border-bottom: 1px solid #808080;
	overflow: auto;
background: #f6f8f9; /* Old browsers */
background: -moz-linear-gradient(-45deg,  #f6f8f9 0%, #e5ebee 50%, #d7dee3 51%, #f5f7f9 100%); /* FF3.6+ */
background: -webkit-gradient(linear, left top, right bottom, color-stop(0%,#f6f8f9), color-stop(50%,#e5ebee), color-stop(51%,#d7dee3), color-stop(100%,#f5f7f9)); /* Chrome,Safari4+ */
background: -webkit-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* Chrome10+,Safari5.1+ */
background: -o-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* Opera 11.10+ */
background: -ms-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* IE10+ */
background: linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* W3C */
filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#f6f8f9', endColorstr='#f5f7f9',GradientType=1 ); /* IE6-9 fallback on horizontal gradient */
}

.gridLabel {
	color: #808080;
	padding: 3px;
	font-size: 24px;
}

#help {
	padding: 10px;
	font-size: 12px;
	color: #606060;
}

#termList {
	width: 500px;
	height: 200px;
	border: 10px solid #E0E0E0;
	border-radius: 5px;
}

.termItemEven {
	width: 100%;
	background: #F8F8F8;
	color: #404040;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

.termItemOdd {
	width: 100%;
	color: #404040;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

.tlHeader {
	position: relative;
	height: 40px;
	vertical-align: middle;
	border-bottom: 1px solid white;
	padding: 4px;
	background: #808080;
	color: #F0F0F0;
	font-size: 10pt;
	font-weight: bold;
}

.tlBody {
	position: absolute;
	top: 40px;
	bottom: 0px;
	left:0px;
	right: 0px;
	background: #D0D0D0;
}

.tlItem,
.tlItemSelected {
	position: relative;
	padding: 4px;
	height: 25px;
	vertical-align: middle;
	font-size: 20px;
	color: #404040;
	background: #F0F0F0;
	border-bottom: 1px solid #D0D0D0;
}

.tlItemSelected {
	color: #F0F0F0;
	background: rgb(53,107,141);
}

.tlItem:hover {
	background: #E8E8E8;
}

.dynaTreeNode {
	white-space: nowrap;
	font-size: 10pt;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee">

<!-- data for current listing group -->
<jsonProvider id="json" contentType="object" 
	targetClass="%DeepSee.Model.ListingGroup.listing"
	OnGetTargetObject="GetListingGroupContent" 
	OnSubmitContent="SubmitListingGroupContent">
<parameter id="pListingGroup" paramName="listingGroup"/>
<parameter id="pListingGroupClass" paramName="listingGroupClass"/>
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">

<spacer width="25"/>
<vgroup id="editGroup" hidden="false">
<spacer height="15"/>
<!-- group attributes -->
<label id="noListingGroup" value="Please open an existing listing group or create a new one" hidden="false" enclosingStyle="font-style:italic;"/>
<hgroup>
<vgroup id="listingManage" hidden="true" valign="top">
<hgroup id="listTreeButtons">
<button id="buttonAddListing" caption="Add Listing" onclick="zenPage.addListing();"/>
<spacer width="5"/>
<button id="buttonRemoveListing" caption="Remove Listing" onclick="zenPage.deleteListing();"/>
</hgroup>
<spacer height="10"/>
<dynaTree id="listingTree" 
OnGetTreeInfo="GetListingTree"
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
dragEnabled="false"
showLines="false" 
showFolders="false"
valign="top"
onchange="zenPage.updateForm();"
onrefresh="zenPage.treePrepare();"
>
<parameter id="pgroupListingTree" paramName="group" value="#(%page.listingGroupName)#" />
</dynaTree>
</vgroup>
<spacer width="20"/>

<fieldSet id="listingGroupDetails" hidden="true" label="Listing Group Details" valign="top" cellStyle="padding:3px;">
<form id="listingGroupForm" hidden="true" onchange="zenPage.formChanged(control)" valign="top">
<vgroup id="listGroup" cellStyle="padding-bottom:5px">
<hgroup labelPosition="left">
<checkbox id="listGroupDisabled" label="Disabled"/>
</hgroup>
<spacer height="5px"/>
<text id="listGroupName" size="44" disabled="false" label="Listing Group Name" title="Enter the logical name of the listing group to load"/>
<text id="listGroupDisplayName" size="44" label="Listing Group Display Name" title="Enter the display name of the listing group to load"/>
<text id="listGroupClassName" size="44" label="Listing Group Class Name" title="Class name for storing the listing group"/>
<hgroup label="Listing Group Target Cubes" cellStyle="padding:0px;">
<text id="listGroupCubes" size="44" title="Comma delimited list of cubes and subject areas which can use this listing group. The first will be used to determine the source class."/>
<spacer width="3"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.selectCubeList();"/>
</hgroup>
<combobox id="listGroupResource" size="44" label="Listing Group Resource" title="Name of resource used to grant access to this listing group." editable="true" unrestricted="true"/>
<combobox id="listGroupDefaultResource" size="44" label="Default Resource For Listings" title="All listings in this group will require access to this resource by default." editable="true" unrestricted="true"/>
</vgroup>
<spacer height="5"/>
<hgroup label="Group Description" cellStyle="padding:0px;" cellVAlign="top">
<text id="listGroupDescription" size="44"/>
<textarea id="arealistGroupDescription" hidden="true" cols="45" rows="4" onchange="zenPage.applyDescription('listGroupDescription');"/>
<spacer width="3"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('listGroupDescription');"/>
</hgroup>
<spacer height="15"/>
</form>
</fieldSet>

<!-- individual listing attributes -->
<fieldSet id="listingDetails" hidden="true" label="Listing Details" valign="top" cellStyle="padding:3px;">
<form id="listingForm" onchange="zenPage.formChanged(control)">
<vgroup id="detailListGroup" cellStyle="padding-bottom:5px">
<hgroup labelPosition="left">
<checkbox id="detailListingDisabled" label="Disabled"/>
</hgroup>
<spacer height="5px"/>
<text id="detailListingName" label="Name" size="44" dropEnabled="true"/>
<text id="detailListingDisplayName" label="Display Name" size="44"/>
<hgroup label="Description" cellStyle="padding:0px;" cellVAlign="top">
<text id="detailListingDescription" size="44"/>
<textarea id="areadetailListingDescription" hidden="true" cols="45" rows="4" onchange="zenPage.applyDescription('detailListingDescription');"/>
<spacer width="3"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailListingDescription');"/>
</hgroup>
<hgroup>
<select id="detailListingType" label="Listing Type" valueList="table,map" displayList="Table,Map" required="true" showEmpty="false"/>
<spacer width="10%"/>
<select id="detailListingSelectMode" label="SQL Select Mode" valueList="0,1,2" displayList="Logical,ODBC,Display" showEmpty="false"/>
</hgroup>
<hgroup cellVAlign="bottom">
<combobox id="detailListingResource" label="Listing Resource" editable="true" size="44" unrestricted="true"/>
</hgroup>
<hgroup id="idListingFieldList" cellVAlign="top">
<textarea id="areadetailListingFieldList" label="Field List" cols="45" rows="6"/>
<vgroup cellStyle="padding:3px;">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingFieldList');"/>
</vgroup>
</hgroup>
<hgroup id="idListingOrderBy" cellVAlign="top">
<textarea id="areadetailListingOrderBy" label="Order By" cols="45" rows="2"/>
<vgroup cellStyle="padding:3px;">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingOrderBy');"/>
</vgroup>
</hgroup>
<combobox id="detailListingSourceClass" label="Data Connector" size="44" editable="true" valueList="" unrestricted="true"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailListingUseSQL" label="Custom SQL query" onchange="zenPage.changeUseSQL();"/>
</hgroup>
<hgroup id="idListingSQL" cellVAlign="top" hidden="true">
<textarea id="areadetailListingSQL" label="SQL Query" cols="32" rows="6"/>
<vgroup cellStyle="padding:3px;">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingSQL');"/>
</vgroup>
</hgroup>
</vgroup>
</form>
<label id="sqlViewMsg"  hidden="true" value="You do not have permission to view listings using custom SQL queries." enclosingStyle="font-style:italic;"/>
</fieldSet>
</hgroup>
</vgroup>
<vgroup id="propertyGroup" hidden="true">
<html id="help" OnDrawContent="DrawHelp"/>
</vgroup>
</hgroup>
</pane>
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Listing Group Manager")

	// commands
	// $LB(id,caption,help,onclick)
	Set:(..canWrite||..canWritePage) pCommands($I(cmdIdx)) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new listing group"),"zenPage.newListingGroup();")
	Set pCommands($I(cmdIdx)) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open an existing listing group"),"zenPage.changeListingGroup();")
	Set:..canWrite pCommands($I(cmdIdx)) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this listing group"),"zenPage.saveListingGroup(false);")
	Set:(..canWrite||..canWritePage) pCommands($I(cmdIdx)) = $LB("cmdSaveAs",$$$Text("Save As"),$$$Text("Save a copy this listing group"),"zenPage.saveListingGroup(true);")
	Set:..canWrite pCommands($I(cmdIdx)) = $LB("cmdCompile",$$$Text("Compile"),$$$Text("Save and Compile this listing group to make it accessible to DeepSee models"),"zenPage.saveListingGroup(false,true);")
	Set:..canWrite pCommands($I(cmdIdx)) = $LB("cmdRemove",$$$Text("Delete"),$$$Text("Delete this listing group"),"zenPage.deleteListingGroup();")
	//Set pCommands($I(cmdIdx)) = $LB("cmdExport",$$$Text("Export"),$$$Text("Export this term list in CSV format"),"zenPage.notImplemented();")
	
	Quit $$$OK
}

/// Create a new listing group.
ClientMethod newListingGroup() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ListingGroupAdd.cls','ListingGroupAdd','status,scrollbars,resizable=yes,width=375,height=540');
}

/// Delete the current listing group.
ClientMethod deleteListingGroup() [ Language = javascript ]
{
	if (confirm($$$Text('Do you wish to delete this listing group?'))) {
		zenPage.setRibbonMessage(this.Delete(this.listingGroupName));
		try {
			self.document.location = zenLink('_DeepSee.UI.ListingGroupManager.cls?RELOAD=1');
		}
		catch(ex) {
		}
	}
}

/// save the listing group to its storage class.
ClientMethod saveListingGroup(rename, compile, silent = 0) [ Language = javascript ]
{
	// Load the model
	var json = zen('json');
	var model = zen('json').getContentObject();
	var name = model.name;
	
	// Load the page settings
	var text = zen('listGroupClassName');
	var pClassName = zen('pListingGroupClass');
	
	
	// validate?
	if (rename) {
		try {
			zenLaunchPopupWindow('_DeepSee.UI.Dialog.ListingGroupAdd.cls','ListingGroupRename','status,scrollbars,resizable=yes,width=375,height=540');
		}
		catch(ex) {
		}

		return;
	}
	
	var ok = '';
	if (text.value) {
		pClassName.value = text.value;
		if (compile) {
			ok = json.submitContent('compile');
		} else {
			ok = json.submitContent();
		}

	} else {
		ok=false;
	}
	
	if (!ok) {
		alert(json.getError());
	}
	else {
		this.setModified(false);
		if (rename) {
			// show new item
			try {
				self.document.location = zenLink('_DeepSee.UI.ListingGroupManager.cls' + '?LISTINGGROUP=' + encodeURIComponent(name));
			}
			catch(ex) {
			}
		}
		else if (!silent) {
			if (compile) {
				zenPage.setRibbonMessage($$$Text('Listing group saved and successfully compiled'));
			} else {
				zenPage.setRibbonMessage($$$Text('Listing group saved'));
			}
		}
	}
}

/// Switch to a different listing group.
ClientMethod changeListingGroup() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=listingGroups','ListingGroupChange','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Client side method for loading the json object from the server
ClientMethod loadListingGroup() [ Language = javascript ]
{
	var listGroup = zen('listGroupName');
	var listClass = zen('listGroupClassName');
	var json = zen('json');
	
	var ok = json.reloadContents();
	
	zenPage.updateForm();
}

/// Invoke dialog to edit certain items: RangeExpression, FormatString, SourceProperty, SourceExpression, CubeResource, ListingResource, ListingField.
ClientMethod editItem(what) [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var uiclass = "_DeepSee.UI.Dialog.GetList.cls";
	var spec = "status,scrollbars,resizable=yes,width=640,height=680";
	var cubes = model.targetCubes.split(',');
	
	switch(what) {			
	case 'ListingFieldList':
		var value = zen("areadetailListingFieldList").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.FieldList.cls";
		break;		
	case 'ListingSQL':
		var value = zen("areadetailListingSQL").getValue();
		var element = zen('detailListingName').getValue();
		break;		
	case 'ListingOrderBy':
		var value = zen("areadetailListingOrderBy").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.FieldList.cls";
		break;		
		/*
	case 'ListingField': // JSL4436
		var value = zen("detailListingFieldExpression").getValue();
		var element = zen("detailListingFieldName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'ListingFieldResource': //
		var value = zen("detailListingFieldExpression").getValue();
		var element = zen("detailListingFieldName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;
		*/
	case 'CubeResource':
		var value = zen('detailCubeResource').getValue();
		var element = zen("detailCubeName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;
	case 'ListingResource':
		var value = zen("detailListingName").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
	}

	var parms = {
			CUBE:cubes[0],
			ELEMENT:element,
			DATASOURCE:zenPage.dataSource,
			VALUE:value,
			WHAT:what,
			CONTEXT:'ListingGroupManager'
			};
	zenLaunchPopupWindow(uiclass,what,spec,parms);
}

/// Launch a dialog to select the target cubes for this listing group
ClientMethod selectCubeList() [ Language = javascript ]
{
	var cubeList = zen('listGroupCubes').getValue();
	
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.SelectCubeList.zen?CUBELIST='+cubeList,'CubeListSelect','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Load the dynaTree control's contents from the server.
Method GetListingTree(pRoot As %String, Output pTree, ByRef pParms) [ ZenMethod ]
{
	Set tListingGroupName = $G(pParms("group"))
	Set tIcon = "deepsee/ds2_binoculars_44.png"

	Set tSC = $$$OK
	Try {
		Set tListIdx=0
		Kill pTree

		If tListingGroupName="" {
			// Page loaded without any group
			Set pTree(0,"ch",1) = ""
			Set pTree(1) = $LB($$$Text("No listing group selected"),"no listing group",0,"",0,"deepsee/ds2_x_44.png","","color:gray;font-style:italic")
			Quit
		}

		Set tListingGroupClass = ..LookUpClassName(tListingGroupName)
		Set tModel = ##class(%DeepSee.ListingGroup).%GetModel(tListingGroupClass)
		
		// each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, description, style)
		If pRoot="" {
			Set tListingGroupCaption = tModel.name 		// Only display logical names
			
			Set pTree(0,"ch",1) = ""
			Set pTree(1) = $LB(tListingGroupCaption,tModel.name,1,"",1,"",tModel.description)
		} Else {
			For ii=1:1:tModel.listings.Count() {
				Set tListing = tModel.listings.GetAt(ii)
				
				Set tListName = tListing.name
				//Set tListCaption = tListing.displayName
				Set tListCaption = tListing.name				// Only display logical names
				Set tListDescription = tListing.description
				
				Set:tListCaption="" tListCaption = tListName
				Set pTree($I(tListIdx)) = $LB(tListCaption,tListName,0,"",1,tIcon,tListDescription)
				Set pTree(0,"ch",tListIdx) = ""
			}
			
			If tModel.listings.Count()=0 {
				// Listing group has no listings
				Set pTree($I(tListIdx)) = $LB($$$Text("No listings defined"),"no listings",0,"",0,"deepsee/ds2_x_44.png","","color:gray;font-style:italic")
				Set pTree(0,"ch",tListIdx) = ""
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the class name given a name of a listing group
Method LookUpClassName(pListingGroupName = "") As %String [ ZenMethod ]
{
	Quit ##class(%DeepSee.ListingGroup).%GetClassName(pListingGroupName,0)
}

/// Draw the help panel.
Method DrawHelp(pSeed As %String) As %Status
{
	&html<<div>>
	Write $$$TextHTML("A listing group contains a set of portable listings for a DeepSee cube or subject area.")
	&html<</div>>
	&html<<br>>
	&html<<div>>
	Write $$$TextHTML("Use the Open command to load an existing listing group or New to create a new one.")
	&html<</div>>
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..listingGroupName="":"Listing Group",1:..listingGroupName)
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return zenPage.listingGroupName;
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Listing Group Manager","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

Method ListingGroupExists(pListGroupName As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(%DeepSee.ListingGroup).%ListingGroupExists(pListGroupName)
}

Method GetListingGroupContent(ByRef pParameters, Output pObject As %RegisteredObject) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tClassName = ##class(%DeepSee.ListingGroup).%GetClassName(..listingGroupName,0)
		Set pObject = ##class(%DeepSee.ListingGroup).%GetModel(tClassName)
		
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("listingGroup",pObject.name)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Perfrom the actual work of saving the current listing group definition to the storage class. If called with
/// <var>pCommand</var> = "compile" the class will also be compiled, activating the listings defined in the group.
Method SubmitListingGroupContent(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		// Need to use the parameter since %GetComponentById() is not available in this context
		Set tClassName = pProvider.parameters.GetAt("listingGroupClass").value
		
		Set tSC = pSubmitObject.%SaveToClass(tClassName)
		If $$$ISERR(tSC) Quit
		
		If pCommand = "compile" {
			Set tSC = $system.OBJ.Compile(tClassName,"c/displaylog=0/displayerror=0")
		}
		
		Do ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("listingGroup",pSubmitObject.name)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..sessionCookie = %session.CSPSessionCookie
			
		// check page access privileges and redirect if necessary
		Do CheckListingGroupUseAccess^%qdsUtils()
		
		// Set editing rights based on security
		Set ..canViewSQL = $$CheckListingGroupSQLViewAccess^%qdsUtils()
		Set ..canWritePage = $$CheckListingGroupWriteAccess^%qdsUtils()
		
		If ..listingGroupName="" {
			Quit
		} Else {
			// Load the listing group model if it is saved
			Set tClassName = ..LookUpClassName(..listingGroupName)
			If tClassName="" {
				Set ..listingGroupName = ""
				Quit
			}
			
			Set ..%model = ##class(%DeepSee.ListingGroup).%GetModel(tClassName)
			
			// Modify editing rights based on the listing group's resource
			Set:..%model.resource'="" ..canWrite = ..canWritePage && $System.Security.Check(..%model.resource,"WRITE")
			
			Set tCube = $P(..%model.targetCubes,",",1)
			Set:tCube'="" ..dataSource = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCube),"sourceClass"))
			
			// Un-hide and initialize the editing display
			Set ..%GetComponentById("noListingGroup").hidden = 1
			Set ..%GetComponentById("listingGroupForm").hidden = 0
			Set ..%GetComponentById("listingManage").hidden = 0
			Set ..%GetComponentById("listingDetails").hidden = 0
			
			// Initialize fields in the form
			Set tGroupText = ..%GetComponentById("listGroupName")
			Set tClassText = ..%GetComponentById("listGroupClassName")
			Set tGroupResource = ..%GetComponentById("listGroupResource")
			Set tGroupDefaultResource = ..%GetComponentById("listGroupDefaultResource")
			Set tListingResource = ..%GetComponentById("detailListingResource")
			
			Set tGroupText.value = ..listingGroupName
			Set tClassText.value = tClassName
		
			// Populate resource lists 
			Set tResourceList = ##class(%DeepSee.Utils).GetResourceList()
			Set tGroupResource.valueList = ","_tResourceList
			Set tGroupDefaultResource.valueList = ","_tResourceList
			Set tListingResource.valueList = ","_tResourceList
			
			// Populate the list of available data connectors
			Set ..%GetComponentById("detailListingSourceClass").valueList = ..LoadListingSource()
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	try {
		this.invokeSuper('onloadHandler');		// DTB845
		
		if (this.listingGroupName!='') {
			zenPage.loadListingGroup();
			zenPage.treePrepare();
			zen("listingManage").setProperty('width',document.getElementById('listingTree').offsetWidth+30);
		}
		else if (!this.reload) {
			// on a fresh navigation to this page, prompt for open or a new listing group
			zen('noListingGroup').setHidden(true);
			if (this.canUserModify()) {
				zenPage.newListingGroup();
			} else {
				zenPage.changeListingGroup();
			}
		} 

		this.controlFormAccess();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onloadHandler');
	}
}

ClientMethod controlFormAccess() [ Language = javascript ]
{
	zen('listingGroupForm').setProperty('disabled',!this.canUserModify());
	zen('listingForm').setProperty('disabled',!this.canUserModify());
	
	zen('buttonAddListing').setHidden(!this.canUserModify());
	zen('buttonRemoveListing').setHidden(!this.canUserModify());	
	zen('detailListingUseSQL').setHidden(!zenPage.canViewSQL);
	
	// Class name is always disabled
	zen('listGroupClassName').setProperty('disabled',true);
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var editDiv = zen('editGroup').getEnclosingDiv();
		var propsDiv = zen('propertyGroup').getEnclosingDiv();
		//var grid = this.getGrid();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var fh = winHeight - th - 25;

		propsDiv.style.height = fh + 'px';
		propsDiv.style.width = 320 + 'px';

		editDiv.style.height = fh + 'px';
		editDiv.style.width = winWidth - 320 - 50 + 'px';
		
		// reveal
		editDiv.style.opacity = 1.0;
		propsDiv.style.opacity = 1.0;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Get the json provider component that contains the current listing group.
ClientMethod getListingGroup() [ Language = javascript ]
{
	return zen('json').getContentObject();
}

/// Delete a term list.
Method Delete(pName As %String) As %String [ ZenMethod ]
{
	Set tMsg = $$$Text("Listing group deleted.")
	Set tSC = ##class(%DeepSee.ListingGroup).%DeleteListingGroup(pName)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Do ##class(%DeepSee.UserLibrary.Utils).%RemoveRecentItem(pName)
	Quit tMsg
}

/// Launch the subject area finder.
ClientMethod browseSubjectAreas() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Update the group and listing details forms.
ClientMethod updateForm() [ Language = javascript ]
{
	var model = zenPage.getListingGroup();
	var listTree = zen('listingTree');
	
	// Group form
	if (model) {
		zen('listGroupName').setValue(model.name);
		zen('listGroupDisabled').setValue(model.disabled);
		zen('listGroupDisplayName').setValue(model.displayName);
		zen('listGroupResource').setValue(model.resource);
		zen('listGroupDefaultResource').setValue(model.defaultResource);
		zen('listGroupCubes').setValue(model.targetCubes);
		zen('listGroupDescription').setValue(model.description);
	}
	else {
		zen('listGroupName').setValue('');
		zen('listGroupDisabled').setValue('');
		zen('listGroupDisplayName').setValue('');
		zen('listGroupResource').setValue('');
		zen('listGroupDefaultResource').setValue('');
		zen('listGroupCubes').setValue('');
		zen('listGroupDescription').setValue('');
	}
	
	// Listing form
	var treeIndex = listTree.getSelectedIndex();
	if (model) {
		var treeOffset = listTree.nodeCount - treeIndex;
		var modelIndex = model.listings.length - treeOffset;
		var listing = model.listings[modelIndex];

		if ((treeIndex>0)&&(listing)) {
			zen('listingDetails').setHidden(false);
			zen('listingGroupDetails').setHidden(true);
			
			zen('detailListingName').setValue(listing.name);
			zen('detailListingDisabled').setValue(listing.disabled);
			zen('detailListingDisplayName').setValue(listing.displayName);
			zen('detailListingDescription').setValue(listing.description);
			zen('detailListingType').setValue(listing.listingType);
			zen('detailListingSelectMode').setValue(listing.selectMode);		// DP-414835
			zen('detailListingResource').setValue(listing.resource);
			zen('areadetailListingFieldList').setValue(listing.fieldList);
			zen('areadetailListingOrderBy').setValue(listing.orderBy);
			zen('detailListingSourceClass').setValue(listing.sourceClass);
			zen('areadetailListingSQL').setValue(listing.sql);
			var useSQL = (listing.sql.length > 0);
			zen('detailListingUseSQL').setValue(useSQL);
			
			zen('detailListingDescription').setHidden(false);
			zen('areadetailListingDescription').setHidden(true);
		} else {
			zen('listingDetails').setHidden(true);
			zen('listingGroupDetails').setHidden(false);
			
			zen('detailListingName').setValue('');
			zen('detailListingDisabled').setValue(false);
			zen('detailListingDisplayName').setValue('');
			zen('detailListingDescription').setValue('');
			zen('detailListingType').setValue('');
			zen('detailListingSelectMode').setValue('');		// DP-414835
			zen('detailListingResource').setValue('');
			zen('areadetailListingFieldList').setValue('');
			zen('areadetailListingOrderBy').setValue('');
			zen('detailListingSourceClass').setValue('');
			zen('areadetailListingSQL').setValue('');
			zen('detailListingUseSQL').setValue(false);
		}
	}
	zenPage.changeUseSQL();
	
	zenPage.controlFormAccess();

	// DTB193 - Disable remove button if there is not a removable listing selected
	zenPage.getComponentById('buttonRemoveListing').setDisabled((0==model.listings.length)||(0==treeIndex));
}

/// Change to details form.
ClientMethod formChanged(ctrl) [ Language = javascript ]
{
	// not a change to a control
	if (!ctrl) {
		return;
	}
		
	// copy changes to model
	var model = zenPage.getListingGroup();
	var listTree = zen('listingTree');
	
	// If the Listing Group name changed, update the tree
	listTree.setNodeText(0,zen('listGroupName').value);
	
	if (model) {
		model.name = zen('listGroupName').value;
		model.disabled = zen('listGroupDisabled').value;
		model.displayName = zen('listGroupDisplayName').value;
		model.resource = zen('listGroupResource').value;
		model.defaultResource = zen('listGroupDefaultResource').value;
		model.targetCubes = zen('listGroupCubes').value;
		model.description = zen('listGroupDescription').value;
		
		// Listing form
		var treeIndex = listTree.selectedIndex;
		if (treeIndex>0) {
			var treeOffset = listTree.nodeCount - treeIndex;
			var modelIndex = model.listings.length - treeOffset;
		
			var listing = model.listings[modelIndex];
			listTree.setNodeText(treeIndex,zen('detailListingName').value);
			
			listing.name = zen('detailListingName').value;
			listing.disabled = zen('detailListingDisabled').value;
			listing.displayName = zen('detailListingDisplayName').value;
			listing.description = zen('detailListingDescription').value;
			listing.listingType = zen('detailListingType').value;
			listing.selectMode = zen('detailListingSelectMode').value;		// DP-414835
			listing.resource = zen('detailListingResource').value;
			listing.fieldList = zen('areadetailListingFieldList').value;
			listing.orderBy = zen('areadetailListingOrderBy').value;
			listing.sourceClass = zen('detailListingSourceClass').value;
			listing.sql = zen('areadetailListingSQL').value;
		}
		
		if (zenPage.canWrite) {
			this.setRibbonMessage();
			this.setModified(true);
		}
	}
}

/// Create new listing object. 
ClientMethod createListing() [ Language = javascript ]
{
	var newList = new Object();
	
	newList._class = '%DeepSee.Model.ListingGroup.listing';
	newList.name = 'New Listing';
	newList.description = '';
	newList.displayName = '';
	newList.disabled = 1;		// Start disabled to allow an auto-save
	newList.fieldList = '';
	newList.listingType = 'table';
	newList.orderBy = '';
	newList.resource = '';
	newList.sourceClass = '';
	newList.sql = '';
	return newList;
}

ClientMethod addListing() [ Language = javascript ]
{
	var tree = zen('listingTree');
	var json = zen('json');
	var model = json.getContentObject();
	var newList = zenPage.createListing();
	
	// Generate a name for the new listing
	var newListingCounter = '';
	var nameArray = [];
	for (n=0; n < model.listings.length ; n++) {
		nameArray[n] = model.listings[n].name;
	}
	
	nameArray.sort();
	
	for (n=0; n < model.listings.length ; n++) {
		if (newList.name==nameArray[n]) {
			newListingCounter++;
		}
		newList.name = 'New Listing' + newListingCounter;
	}
	
	
	
	model.listings[model.listings.length] = newList;
	zenPage.saveListingGroup(0,0,1);
	
	tree.refreshContents();
}

ClientMethod deleteListing() [ Language = javascript ]
{
	var tree = zen('listingTree');
	var treeIndex = tree.selectedIndex;
	if (treeIndex<=0) {
		return;
	}
	
	var model = zen('json').getContentObject();
	var treeOffset = tree.nodeCount - treeIndex;
	var modelIndex = model.listings.length - treeOffset;
	var length = model.listings.length;
	
	// DTB199 - Confirm deletion
	var ok = confirm('Are you sure you want to delete this listing?'+'\n'+'Listing: ' + model.listings[modelIndex].name);
	if (!ok) {
		return;
	}
	
	delete model.listings[modelIndex];
	for (var n = modelIndex + 1 ; n < length ; n++) {
		model.listings[n-1] = model.listings[n];
	}
	
	model.listings.length = model.listings.length-1;
	zenPage.saveListingGroup(0,0,1);
	
	tree.refreshContents();
}

/// Set the tree to expanded, no matter what state it is in currently
ClientMethod treeExpand(tree) [ Language = javascript ]
{
	
	if (tree&&!tree.isNodeExpanded(0)) {
		tree.toggleExpanded(0);
	}
}

/// Do any actions necessary for proper presentation when the tree is first loaded
ClientMethod treePrepare() [ Language = javascript ]
{
	// Method added by DTB193
	var tree = zen('listingTree');
	this.treeExpand(tree);
	tree.selectItem(0);
}

/// User checked/unchecked the Use SQL field
ClientMethod changeUseSQL() [ Language = javascript ]
{
	var usesql = zen("detailListingUseSQL").getValue();
	if (usesql&&this.canViewSQL) {
		// query uses custom sql, user can see it
		zen("listingForm").setHidden(false);
		zen("sqlViewMsg").setHidden(true);
		zen("idListingSQL").setHidden(!usesql);
		zen("idListingFieldList").setHidden(usesql);
		zen("idListingOrderBy").setHidden(usesql);
		zen("detailListingSourceClass").setHidden(usesql);
		
		zen("listingForm").setProperty('disabled',!this.canWrite);
	} else if (usesql&&!this.canViewSQL) {
		// query uses custom sql, user is not permitted to view it
		zen("listingForm").setHidden(true);
		zen("sqlViewMsg").setHidden(false);
		zen("buttonRemoveListing").setProperty('disabled',true);
	} else {
		// query doesn't use custom sql
		zen("listingForm").setHidden(false);
		zen("listingForm").setProperty('disabled',!this.canWrite);
		zen("sqlViewMsg").setHidden(true);
		zen("buttonRemoveListing").setProperty('disabled',!this.canWrite);
		zen("idListingSQL").setHidden(!usesql);
		zen("idListingFieldList").setHidden(usesql);
		zen("idListingOrderBy").setHidden(usesql);
	}
}

/// Toggle to show/hide Description textarea; set what's in text into textarea.
ClientMethod editDescription(what) [ Language = javascript ]
{
	var value = zen(what).getValue();
	var id = "area"+what;
	zen(id).setValue(value);
	zen(id).setHidden(!zen(id).getProperty("hidden"));
	zen(what).setHidden(!zen(what).getProperty("hidden"));
}

/// Set textarea description back into the text description field.
ClientMethod applyDescription(what) [ Language = javascript ]
{
	var id = "area"+what;
	var value = zen(id).getValue();
	zen(what).setValue(value);
	zenPage.formChanged(this);
}

/// Return Data Connector list
Method LoadListingSource() As %String
{
	Set valueList = ""	
	// setup Data Connector list for Listings
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("%DeepSee.DataConnector")
	
	While tRS.Next() {
		Set tClass = tRS.GetData(1)
		Set tS = $zobjclassmethod(tClass,"%GetParameter","SUPPORTSIDLIST")
		If tS = 1 Set valueList = valueList _ $S(valueList'="":",",1:"") _ tClass
	}
	Quit valueList
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.ListingGroupManager.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch(ex) {
		}
		break;
	case 'ListingFieldList':
		zen('areadetailListingFieldList').setValue(value);
		zenPage.formChanged(this);
		break;
	case 'ListingOrderBy':
		zen('areadetailListingOrderBy').setValue(value);
		zenPage.formChanged(this);
		break;
	case 'ListingGroupAdd':
		// dialog's  return value is an object
		var name = value.groupName;
		if (name != this.listingGroupName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.ListingGroupManager.cls' + '?LISTINGGROUP=' + encodeURIComponent(name));
			}
			catch(ex) {
			}
		}
		break;
	case 'ListingGroupRename':
		// dialog's return value is an object
		var json = zen('json');
		var newGroupName = value.groupName;
		var newClassName = value.className;
		var model = json.getContentObject();
		var pClassName = zen('pListingGroupClass');
		
		zen('listGroupClassName').setValue(newClassName);
		pClassName.value = newClassName;
		model.name = newGroupName;
		
		var ok = json.submitContent();
				
		if (newGroupName != this.listingGroupName) {
			try {
				if (ok) {
					self.document.location = zenLink('_DeepSee.UI.ListingGroupManager.cls' + '?LISTINGGROUP=' + encodeURIComponent(newGroupName));
				}
			}
			catch(ex) {
			}
		}
 		break;
	case 'ListingGroupChange':
		// strip off extension added by the finderDialog
		var s = value.toString().split('.');
		s.length = s.length-1;
		var name = s.join('.');
		if (name != this.listingGroupName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.ListingGroupManager.cls' + '?LISTINGGROUP=' + encodeURIComponent(name));
			}
			catch(ex) {
			}
		}
		break;
	case 'ListingSQL':
		zen('areadetailListingSQL').setValue(value);
		zenPage.formChanged(this);
		break;
	case 'CubeListSelect':
		zen('listGroupCubes').setValue(value);
		zenPage.formChanged(this);
		break;
	}
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	return zenPage.canWrite
}

ClientMethod notImplemented() [ Language = javascript ]
{
	alert('Not Implemented!');
}

/// This callback is called just after the server-side page 
/// object is created but before its children are created.
Method %OnCreatePage() As %Status
{
	// If this user has a last group stored, load it 
	Do ##class(%DeepSee.UserLibrary.Utils).%GetRecentItemList(.tRecentList,"listingGroup")
	
	Set tTimeStamp = $O(tRecentList(""),-1,tRecentGroup)
	Set:..listingGroupName="" ..listingGroupName = $G(tRecentGroup)
	
	Quit $$$OK
}

/// Register this visit to the recent items list.
Method %Register() As %Status
{
	Set tSC = $$$OK
	#; register visit
	If (..#RECENT) {
		Set tURL = $ZCVT(%request.URL,"O","URL")
		Try {
			// Swallow error if method not defined
			Set tSC = ##class(%CSP.Portal.Utils).%RegisterRecentItem(..%OnGetPageName(),tURL)
		}
		Catch(ex) {
		}
	}
	Quit tSC
}

/// This is called in the middle of rendering the tool ribbon.
/// Subclasses can inject their own content into the ribbon by writing it out in this method.
/// This content is best wrapped within a single td element.
/// It can also consist of multiple td elements.
/// <p>
/// To achieve a fixed position for elements within the ribbon, for a fixed width page you can 
/// use a single enclosing td that contains a table and a single tr, 
/// with td elements inside that single tr that contain your content for the ribbon.
/// <p>
/// To achieve a fixed position for elements within the ribbon, 
/// for a page whose width varies depending on its contents (thereby stretching the ribbon)
/// you can use multiple td elements to contain your content and then a final
/// td element that is empty and has width 40% (or so) to push your contents towards the left
/// and keep them in their proper locations.
Method OnDrawRibbon() As %Status
{
	&html<<td id="ribbonSpacer" width="5%"></td>>
	&html<<td id="ribbonMessage" style="color:red" width="20%"></td>>
	Quit $$$OK
}

/// OCnvenience utility for setting the ribbon message
ClientMethod setRibbonMessage(message) [ Language = javascript ]
{
	if (message == undefined) {
		message = '';
	}
	self.document.getElementById('ribbonMessage').innerHTML=message;
}

}
