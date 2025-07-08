/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets you select an item (such as a dimension) from base cube and add to a DeepSee subject area definition.<br>
/// Can always add a new Measure;dataDimension;timeDimension<br>
/// But if you want to add a hierarchy, you need to first click a dimension or hierarchy,<br>
/// and if you want to add a new level, you need to first click a hierarchy or level;
Class %DeepSee.UI.Dialog.SubjectAreaAddItem Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter CSSINCLUDES = "/csp/sys/intersystems.css";

Parameter APPLYBUTTON = 0;

/// Cube name.
Property subjectAreaName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Base Cube name.
Property baseCube As %ZEN.Datatype.string(ZENURL = "BASECUBE");

/// Item type. 
Property itemType As %ZEN.Datatype.string;

/// SELECTEDCLASS
Property selectedClass As %ZEN.Datatype.string(ZENURL = "SELECTEDCLASS");

Property numRows As %ZEN.Datatype.integer [ InitialExpression = "0" ];

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
table.DetailTable th {
	padding:2px;
} 
table.DetailTable td {
	padding-left:2px;
	padding-right:2px;
} 

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<label id="subjectAreaName" label="Subject Area Name" value="#(%page.subjectAreaName)#" enclosingStyle="font-size:12px;background:rgb(221,240,174);"/>
<label label="What would you like to select from?"/>
<timer id="timer" ontimeout="zenPage.timeout();" timeout="0"/>
<radioSet id="itemType" valueList="measure,dimension,listing" displayList="Measure,Dimension,Listing" onchange="zenPage.changeType();"/>
<html id="table" OnDrawContent="DrawTable" seed=""/>
<hgroup id="idListing" labelPosition="left" hidden="true">
<text id="newListing" label="To add a new Listing, enter a New Listing Name here:"/>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Add Elements to Subject Area")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Select elements from base cube %1 to override."),..EscapeHTML(%page.baseCube))
}

ClientMethod changeType() [ Language = javascript ]
{
	var type = zen("itemType").getValue();
	var html = zen("table");
	zen('idListing').setHidden(type != "listing");
	html.setProperty("seed",type);
	var timer = zen('timer');
	timer.setProperty('timeout',1000);
	timer.startTimer();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var type = zen("itemType").getValue();
	var cbValues = this.getCBValues();
	var value = type + "^" + cbValues;
	if (type == "listing") {
		var newname = zen("newListing").getValue();
		if (newname != "") {
			if (cbValues == "") value = value + "," + newname + ",";
			else value = value + newname + ",";
		}
	}
	return value;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

ClientMethod timeout() [ Language = javascript ]
{
	if (this.getOpener()) {
		this.checkSelected();
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRadio = ..%GetComponentById("itemType")
		Set ..itemType = $Case(..selectedClass,"%DeepSee.Model.SubjectArea.measure":"measure","%DeepSee.Model.SubjectArea.listing":"listing",:"dimension")
		Set tRadio.value = ..itemType
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.changeType();
}

/// For each item that is already on the Subject Area Architect, make it selected an disable the checkbox<br>
/// This method is called each time changeType is accessed.
ClientMethod checkSelected() [ Language = javascript ]
{
	var opener = this.getOpener();
	var subjectArea = opener.zenPage.getSubjectAreaObject();
	var type = zen("itemType").getValue();
	var item,mlen,dim,hier,level;
	// 
	switch (type) {
	case "measure":
		mlen = subjectArea.measures.length;
		for (var i = 0; i < mlen; i++) {
			item = subjectArea.measures[i].name;
			this.markSelected(item);
		}
		break;
	case "dimension":
		mlen = subjectArea.dimensions.length;
		for (var d = 0; d < mlen; d++) {
			dim = subjectArea.dimensions[d];
			this.markDimSelected(dim.name);
			// next match hier 
			var hlen = dim.hierarchies.length;
			for (var h = 0; h < hlen; h++) {
				hier = dim.hierarchies[h];
				this.markHierSelected(dim.name,hier.name);		
				// next match level
				var llen = hier.levels.length;
				for (var l = 0; l < llen; l++) {
					level = hier.levels[l];
					this.markLevelSelected(dim.name,hier.name,level.name);
				}
			}			
		}
		break;
	case "listing":
		mlen = subjectArea.listings.length;
		for (var i = 0; i < mlen; i++) {
			item = subjectArea.listings[i].name;
			this.markSelected(item);
		}
		break;
	}
}

/// Check measure or listing to see if it is already selected. If yes, make it selected an disable the checkbox
ClientMethod markSelected(item) [ Language = javascript ]
{
	var cb;
	var numRows = this.numRows;
	for (var j = 1; j <= numRows; j++) {
		cb = self.document.getElementById("cb_"+j);
		if (cb) {
			if (cb.value == item) {
				cb.checked = true;
				cb.disabled = true;
				return;
			}			
		}
	}
}

/// Check Dimension to see if it is already selected. If yes, make it selected an disable the checkbox
ClientMethod markDimSelected(dim) [ Language = javascript ]
{
	var cb;
	var numRows = this.numRows;
	var piece,type;
	for (var j = 1; j <= numRows; j++) {
		cb = self.document.getElementById("cb_"+j);
		if (cb) {
			piece = cb.value.split("#");
			type = piece[0];
			//dim = piece[1];
			//hier = piece[2];
			//level = piece[3];
			if ((type == "d") && (dim == piece[1])) {
				cb.checked = true;
				cb.disabled = true;
				return;
			}	
		}
	}
}

/// Check Dimension and Hier to see if it is already selected. If yes, make it selected an disable the checkbox
ClientMethod markHierSelected(dim, hier) [ Language = javascript ]
{
	var cb;
	var numRows = this.numRows;
	var piece,type;
	for (var j = 1; j <= numRows; j++) {
		cb = self.document.getElementById("cb_"+j);
		if (cb) {
			piece = cb.value.split("#");
			type = piece[0];
			//dim = piece[1];
			//hier = piece[2];
			//level = piece[3];
			if ((type == "h") && (dim == piece[1]) && (hier == piece[2])) {
				//alert("matched h!"+dim+" "+hier)
				cb.checked = true;
				cb.disabled = true;
				return;
			}	
		}
	}
}

/// Check Dimension&Hier&Level to see if it is already selected. If yes, make it selected an disable the checkbox
ClientMethod markLevelSelected(dim, hier, level) [ Language = javascript ]
{
	var cb;
	var numRows = this.numRows;
	var piece,type;
	for (var j = 1; j <= numRows; j++) {
		cb = self.document.getElementById("cb_"+j);
		if (cb) {
			piece = cb.value.split("#");
			type = piece[0];
			//dim = piece[1];
			//hier = piece[2];
			//level = piece[3];
			if ((type == "l") && (dim == piece[1]) && (hier == piece[2]) && (level == piece[3])) {
				cb.checked = true;
				cb.disabled = true;
				return;
			}	
		}
	}
}

/// Select/Unselect all checkboxes
ClientMethod toggleCheckboxes() [ Language = javascript ]
{
	var cb;
	var cbState = document.getElementById("ctlCheck").checked;
	var numRows = this.numRows;

	for (var i = 1; i <= numRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		if (cb) {
			if (cb.disabled==false) cb.checked = cbState;
		}
	}
}

ClientMethod getCBValues() [ Language = javascript ]
{
	var state = '';
	var cb;
	var numRows = this.numRows;

	for (var i = 1; i <= numRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		if (cb && cb.checked && !cb.disabled) {
			state += "," + cb.value;
		}
	}
	
	if (state != '') {
		state += ',';
	}

	return state;
}

/// Start action and server method will pump out result.
Method DrawTable(seed As %String) As %Status
{
	If seed = "" Quit 1
	Set baseCube = %page.baseCube
	Set ltoggle = $$$TextJS("Click this checkbox to select/unselect all")
	&html<<form name="form">>
	&html<<table class="DetailTable" border="0" cellpadding="5" cellspacing="2">
	<tr><th onclick="zenPage.toggleCheckboxes();" align="center" style="cursor:pointer;cursor:hand;"><a title="#(ltoggle)#"><input type="checkbox" name="ctlCheck" id="ctlCheck"></a></th>
	>
	If seed = "measure" {
		Set numRows = ..DrawMeasures(baseCube)
	} ElseIf seed = "dimension" {
		Set numRows = ..DrawDimensions(baseCube)
	} ElseIf seed = "listing" {
		Set numRows = ..DrawListings(baseCube)
	}
	Set %page.numRows = numRows
	&html<</table></form>>
	Quit 1
}

Method DrawMeasures(baseCube As %String) As %Integer
{
	//$LB(name,caption,type)
	Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(baseCube,.tItems,1)
	&html<<th nowrap>#($$$TextHTML("Name"))#</th><th nowrap>#($$$TextHTML("Caption"))#</th><th nowrap>#($$$TextHTML("Type"))#</th></tr>>
	Set tRow = "",tTotal = 0
	Set tRow = $O(tItems(tRow))
	While tRow '= "" {
		If $lg(tItems(tRow),1) '= "%COUNT" {
			Set tTotal = tTotal + 1
			Set tId = "cb_"_tTotal
			Set tName = $lg(tItems(tRow),1)
			&html<<tr id='#("row_"_tTotal)#' class="OddRow"><td><input type="checkbox" id="#(tId)#" value="#(tName)#"></td><td nowrap>#(tName)#</td>>
			For i = 2:1:3 &html<<td>#($lg(tItems(tRow),i))#</td>>
			&html<</tr>>
		}
		Set tRow = $O(tItems(tRow))
	}
	&html<<tr><td colspan="10">#($$$TextHTML("Total Measures"))#: #(tTotal)#</td>>
	Quit tTotal
}

Method DrawDimensions(baseCube As %String) As %Integer
{
	//tItems(DimNo,HierNo,LevelNo)
	//$LB(type,DimName,HierName,LevelName)
	Set tSC = ##class(%DeepSee.Utils).%GetDimensionList(baseCube,.tItems)	
	&html<<th nowrap>#($$$TextHTML("Dimension"))#</th><th nowrap>#($$$TextHTML("Hierarchy"))#</th><th nowrap>#($$$TextHTML("Level"))#</th></tr>>
	Set LastDim = "",cls = "EvenRow"
	Set (DimNo,tTotal,tTotalDim) = 0
	Set DimNo = $O(tItems(DimNo))
	While DimNo '= "" {
		If DimNo '= LastDim Set cls = $S(cls="EvenRow":"OddRow",1:"EvenRow"),tTotalDim = tTotalDim + 1 
		Set HierNo = ""
		Set HierNo = $O(tItems(DimNo,HierNo)) 
		While HierNo '= "" {
			Set LevelNo = ""
			Set LevelNo = $O(tItems(DimNo,HierNo,LevelNo))
			While LevelNo '= "" {
				Set type = $lg(tItems(DimNo,HierNo,LevelNo),1)
				If type '= "all" {
					Set tTotal = tTotal + 1
					Set tId = "cb_"_tTotal
					Set tItemType = $lg(tItems(DimNo,HierNo,LevelNo),1)
					Set tDimName = $lg(tItems(DimNo,HierNo,LevelNo),2)
					Set tHierName = $lg(tItems(DimNo,HierNo,LevelNo),3)
					Set tLevelName = $lg(tItems(DimNo,HierNo,LevelNo),4)
					Set tValue = tItemType_"#"_tDimName_"#"_tHierName_"#"_tLevelName
					&html<<tr class="#(cls)#"><td><input type="checkbox" id="#(tId)#" value="#(tValue)#"></td>>
					If type="d" &html<<td nowrap>#(tDimName)#</td>>
					Else  &html<<td>&nbsp;</td>>
					If type="h" &html<<td>#(tHierName)#</td>>
					Else  &html<<td>&nbsp;</td>>
					&html<<td>#(tLevelName)#</td>
					</tr>>
				}
				Set LevelNo=$O(tItems(DimNo,HierNo,LevelNo))
			}
			Set HierNo=$O(tItems(DimNo,HierNo)) 
		}
		Set LastDim = DimNo
		Set DimNo = $O(tItems(DimNo))
	}
	&html<<tr><td colspan="10">#($$$TextHTML("Total Dimensions"))#: #(tTotalDim)#</td>>
	Quit tTotal
}

Method DrawListings(baseCube As %String) As %Integer
{
	//$LB(caption,fields,order)
	Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(baseCube,.tItems)	
	&html<<th nowrap>#($$$TextHTML("Caption"))#</th><th nowrap>#($$$TextHTML("Fields"))#</th><th nowrap>#($$$TextHTML("Order"))#</th></tr>>
	Set tRow = "",tTotal = 0
	Set tRow = $O(tItems(tRow))
	While tRow '= "" {
		Set tTotal = tTotal + 1
		Set tId = "cb_"_tTotal
		Set tName = $lg(tItems(tRow),1)
		&html<<tr class="OddRow"><td><input type="checkbox" id="#(tId)#" value="#(tName)#"></td><td nowrap>#(tName)#</td>>
		For i = 2:1:3 &html<<td>#($lg(tItems(tRow),i))#</td>>
		&html<</tr>>
		Set tRow = $O(tItems(tRow))
	}
	&html<<tr><td colspan="10">#($$$TextHTML("Total Listings"))#: #(tTotal)#</td>>
	Quit tTotal
}

}
