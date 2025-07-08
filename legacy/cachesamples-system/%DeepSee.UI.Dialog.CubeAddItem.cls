/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog adds a new item (such as a dimension) to a DeepSee cube definition.<br>
/// Can always add a new Measure;dataDimension;timeDimension<br>
/// But if you want to add a hierarchy, you need to first click a dimension or hierarchy,<br>
/// and if you want to add a new level, you need to first click a hierarchy or level;
Class %DeepSee.UI.Dialog.CubeAddItem Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Item type. 
Property itemType As %ZEN.Datatype.string(ZENURL = "TYPE") [ InitialExpression = "measure" ];

/// SELECTEDCLASS
Property selectedClass As %ZEN.Datatype.string(ZENURL = "SELECTEDCLASS");

Property newItemCounter As %ZEN.Datatype.string(ZENURL = "NEWITEMCOUNTER");

Property userChangedName As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

XData Style
{
<style type="text/css">
.zenHint {
	padding-left:20px;
	font-size: 12px;	
}
.radioButtonCaption {
	font-size: 12px;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<label id="cubeName" label="Cube Name" value="#(%page.cubeName)#" enclosingStyle="font-size:12px;background:rgb(221,240,174);"/>
<text id="newName" label="Enter New Element Name" size="30" onchange="zenPage.userChangedName=1;" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<label label="Select an element to add to this cube definition:"/>

<!-- get additional hint text from lexi!!! -->
<radioButton id="itemTypeMsr" caption="Measure" name="itemType" onchange="zenPage.changeType();" 
optionValue="measure"/>
<hgroup><radioButton id="itemTypeDimD" caption="Data Dimension" name="itemType" onchange="zenPage.changeType();" 
optionValue="dataDimension"/>
<radioButton id="itemTypeDimT" caption="Time Dimension" name="itemType" onchange="zenPage.changeType();" 
optionValue="timeDimension"/>
<radioButton id="itemTypeDimA" caption="Age Dimension" name="itemType" onchange="zenPage.changeType();" 
optionValue="ageDimension"/>
<radioButton id="itemTypeDimI" caption="iKnow Dimension" name="itemType" onchange="zenPage.changeType();" 
optionValue="iKnowDimension"/>
</hgroup>

<radioButton id="itemTypeDimS" caption="Shared Dimension" name="itemType" onchange="zenPage.changeType();" 
optionValue="sharedDimension"/>
<hgroup id="idShared" hidden="true" labelPosition="left" containerStyle="padding-left:20px;">
<select id="selSharedCube" label="Select a cube to share from" labelClass="radioButtonCaption" showEmpty="true"
title="select a cube first then a dimension" onchange="zenPage.loadDimension();"/>
<selector id="selSharedDim" label="Select a dimension" labelClass="radioButtonCaption"
context="%DeepSee.Component.ContextSearch/Dimensions?subject="
title="select a cube first then a dimension" onchange="zenPage.selectedDim(zenThis);"/>
</hgroup>

<hgroup>
<radioButton id="itemTypeHier" caption="Hierarchy" name="itemType" onchange="zenPage.changeType();" 
optionValue="hierarchy"/>
<radioButton id="itemTypeLvl" caption="Level" name="itemType" onchange="zenPage.changeType();" 
optionValue="level"/>
<radioButton id="itemTypeProp" caption="Property" name="itemType" onchange="zenPage.changeType();" 
optionValue="property"/>
</hgroup>
<radioButton id="itemTypeList" caption="Listing" name="itemType" onchange="zenPage.changeType();" 
optionValue="listing"/>
<radioButton id="itemTypeListField" caption="ListingField" name="itemType" onchange="zenPage.changeType();" 
optionValue="listingField"/>
<hgroup>
<radioButton id="itemTypeCalMemberM" caption="Calculated Member (Measure)" name="itemType" onchange="zenPage.changeType();" 
optionValue="memberMeasure"/>
<radioButton id="itemTypeCalMemberD" caption="Calculated Member (Dimension)" name="itemType" onchange="zenPage.changeType();" 
optionValue="memberDimension"/>
</hgroup>
<radioButton id="itemTypeNamedset" caption="Named Set" name="itemType" onchange="zenPage.changeType();" 
optionValue="namedSet"/>
<radioButton id="itemTypeRelationship" caption="Relationship" name="itemType" onchange="zenPage.changeType();" 
optionValue="relationship"/>
<radioButton id="itemTypeExpression" caption="Expression" name="itemType" onchange="zenPage.changeType();" 
optionValue="expression"/>
<fieldSet id="fldHint">
<label id="idHint" enclosingClass="radioButtonCaption" />
</fieldSet>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Add Element to Cube")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add an element to this cube.")
}

ClientMethod changeType() [ Language = javascript ]
{
	var selection = zen('itemTypeMsr').getValue();
	var newname = selection;
	/// if user has not changed new field name, we provide default. OW, leave it alone.
	if (!this.userChangedName) {
		if (newname == "hierarchy") newname = "H";
		var value = 'New_' + newname + this.newItemCounter;
		zen('newName').setValue(value);
	}
	zen("fldHint").setProperty("legend",selection);
	var hint;
	switch(selection) {
		case 'measure':
			hint = $$$Text("Measures supply the values that your cube can aggregate.");
			break;
		case 'dataDimension':
			hint = $$$Text("Data dimensions specify how to group data by values other than time values.");
			break;
		case 'timeDimension':
			hint = $$$Text("Time dimensions specify how to group data by time values.");
			break;
		case 'ageDimension':
			hint = $$$Text("Age dimensions specify how to group data by current age.");
			break;
		case 'iKnowDimension':
			hint = $$$Text("iKnow dimensions specify how to group data based on the unstructured content of an iKnow measure.");
			break;
		case 'hierarchy':
			hint = $$$Text("Hierarchies control relationships between levels. Each hierarchy belongs to a dimension.");
			break;
		case 'level':
			hint = $$$Text("Levels specify how to group data. Each level belongs to a hierarchy.");
			break;
		case 'property':
			hint = $$$Text("Properties specify additional information for level members.");
			break;
		case 'listing':
			hint = $$$Text("Listings specify the source fields to display when the user performs a drillthrough action.");
			break;
		case 'listingField':
			hint = $$$Text("Listing fields specify fields the user can use to define listings.");
			break;
		case 'memberMeasure':
			hint = $$$Text("This type of calculated member is a member in the MEASURES dimension.");
			break;
		case 'memberDimension':
			hint = $$$Text("This type of calculated member is a member in some dimension other than MEASURES.");
			break;
		case 'namedSet':
			hint = $$$Text("Named sets are reusable MDX sets that can be used on query axes.");
			break;
		case 'relationship':
			hint = $$$Text("A relationship to another cube lets this cube use dimensions of the other cube.");
			break;
		case 'expression':
			hint = $$$Text("A cube expression is calculated once and can be reused in multiple cube elements.");		// DTB390
			break;
		case 'sharedDimension':
			hint = $$$Text("A shared dimension uses an existing dimension of any cube.");
			var dim = zen('selSharedDim').getValue();
			if (dim != "") zen('newName').setValue(dim);
			break;
		
	}
	zen("idHint").setValue(hint);
	zen('idShared').setHidden(selection!="sharedDimension");
	zen('newName').setDisabled(selection=="sharedDimension");
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var type = zen('itemTypeMsr').getValue();
	var value = type + "^" + zen('newName').getValue();
	if (type == "sharedDimension") value += "^" + zen('selSharedCube').getValue();
	return encodeURIComponent(value);		// DTB583 - Add encoding
}

ClientMethod loadDimension() [ Language = javascript ]
{
	var cube = zen('selSharedCube').getValue();
	if (cube == "") return;
	var dim = zen('selSharedDim');
	dim.setProperty("context","%DeepSee.Component.ContextSearch/Dimensions?subject="+cube+"&excludeMeasures=1");
	return;
}

ClientMethod selectedDim(ctrl) [ Language = javascript ]
{
	zen('newName').setValue(ctrl.getValue());
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	var ok = true;
	try {
		if (zen('newName').getValue() == "") {
			alert($$$Text("Please enter a name for the new element."));
			zen('newName').focus();
			ok = false;	
		}
		var selection = zen('itemTypeMsr').getValue();
		if (selection == 'sharedDimension') {
			var cube = zen('selSharedCube').getValue();
			var dim = zen('selSharedDim').getValue();
			if ((cube == "") || (dim == "")) {
				alert($$$Text("For a Shared Dimension, you must select both a cube and a dimension."));
				ok = false;
				if (cube == "") zen('selSharedCube').focus();
				else zen('selSharedDim').focus();
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return ok;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRadio = ..%GetComponentById("itemTypeMsr")
		Set ..itemType = $Case(..selectedClass,"%DeepSee.Model.measure":"measure","%DeepSee.Model.hierarchy":"hierarchy","%DeepSee.Model.level":"level","%DeepSee.Model.property":"property","%DeepSee.Model.listing":"listing","%DeepSee.Model.listingField":"listingField","%DeepSee.Model.calculatedMember":"memberMeasure","%DeepSee.Model.namedSets":"namedSet","%DeepSee.Model.relationship":"relationship",:"dataDimension")
		Set tRadio.value = ..itemType
		Set ..%GetComponentById("selSharedCube").valueList = ..LoadSharesFromCubes()

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return cube list for SharesFrom cube drop-down
Method LoadSharesFromCubes() As %String
{
	Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"cubes")
	If $$$ISERR(tSC) Quit ""
	
	// DTB321 - Use recursive node processing to capture all cubes in folders
	Set tSC = ##class(%DeepSee.Utils).%ProcessCubeListArrayNode(.pData,,.valueList)
	If $$$ISERR(tSC) Quit ""
	
	Quit valueList
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	var selectedClass = this.selectedClass;
	if (!selectedClass || ('%DeepSee.Model.dimension' != selectedClass && '%DeepSee.Model.hierarchy' != selectedClass)) {
		zen('itemTypeHier').setDisabled(true);
	}
	if (!selectedClass || ('%DeepSee.Model.hierarchy' != selectedClass && '%DeepSee.Model.level' != selectedClass)) {
		zen('itemTypeLvl').setDisabled(true);
	}
	if (!selectedClass || ('%DeepSee.Model.level' != selectedClass && '%DeepSee.Model.property' != selectedClass)) {
		zen('itemTypeProp').setDisabled(true);
	}
	this.changeType();
	zen("newName").focus();
}

}
