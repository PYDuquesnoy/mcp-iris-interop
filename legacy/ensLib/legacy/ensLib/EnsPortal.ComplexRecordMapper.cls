/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.ComplexRecordMapper Extends EnsPortal.Template.devPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Complex Record Mapper";

/// User needs READ permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_RecordMap:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

/// Include zenCSLM.
Parameter JSINCLUDES = "zenCSLM.js";

/// Name of ComplexMap being viewed.
Property complexMap As %ZEN.Datatype.string(ZENURL = "COMPLEXMAP");

Property complexMapAsName As %ZEN.Datatype.string;

/// ID (index number, 0-based) of current selected item.
Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// CSV-string used to remember last location across page redraws, especially involving popups.
Property lastLoc As %ZEN.Datatype.string(ZENURL = "LOC");

Property %tempMap As EnsLib.RecordMap.Model.ComplexBatch;

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This complex record map is read only.")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Open a saved Complex RecordMap")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new Complex RecordMap")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Complex RecordMap")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Complex RecordMap with a new name")} ];

Property tipGen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Complex RecordMap and generate classes")} ];

Property tipDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete the current Complex RecordMap")} ];

XData Style
{
<style type="text/css">
#complexMapTable {
	border-top: 1px solid rgb(156,154,141);
	border-bottom: 1px solid rgb(156,154,141); 
	overflow: auto;
	background: white;
}
#complexMapBodyDiv {
	overflow: auto;
}

span.selector {
	visibility: hidden;
}

table.mapTable {
	background: white;
	width: 100%;
}

table.mapTable td {
	padding: 2px;
	border-bottom: 1px solid darkgray;
}

.modelRecordMapSelected span.selector,
.modelRecordFieldSelected span.selector {
	visibility: visible;
}

.complexMapTitle {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
	height: 1.4em;
}

.complexReference {
	color: rgb(67,67,67);
}

.complexSequence {
	font-style: italic;
	color: rgb(67,67,67);
}
.complexHeaderTrailer {
	font-weight: bold;
	color: rgb(67,67,67);
}
.complexHeaderTrailerEmpty {
	color: rgb(67,67,67);
	font-style: italic;
	background-color: #EDECE4;
}
.complexHeaderTrailerEmpty.complexMapSelected {
	color: rgb(67,67,67);
	font-style: italic;
}
.complexMapSelected {
	color: black;
	background: #FFEEAA;
}
.complexMapMouseOver {
	color: black;
}
.complexMapError {
	color: red;
	font-weight: bold;
}
.complexMapError td:first-child {
	/*background-color: red;*/
}
#errorHTML {
	padding-left: 5px;
}
.complexErrorTitle {
	background: #F04040;
	background: -moz-linear-gradient(center top , #F04040, #800000) repeat scroll 0 0 transparent;
	background: -webkit-linear-gradient(top, #F04040, #800000);
	background: linear-gradient(top, #F04040, #800000);
	border: 1px solid #D04040;
	border-radius: 4px;
	color: white;
	margin: 5px 5px 0px;
	padding: 2px;
}
ol.complexErrorList {
	color: #404040;
	font-size: 12px;
}
ol.complexErrorList li {
	margin-bottom: 4px;
}
.modelButton {
	width: 5%;
}
.modelSpacerCell {
	width: 25%;
}
.modelRowDetail {
	opacity: 0.8;
	font-size: 0.75em;
	padding-left: 5px;
}
#propertyLabel {
	height: 1.4em;
	color: white;
	font-size: 1.2em;
	font-weight: bold;
	padding-left:10px;
	background-color: #9c9a8c;
	border: 1px solid #9c9a8c;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<jsonProvider id="complexMap" 
	OnGetTargetObject="GetMapObject"
	OnSubmitContent="SubmitMapObject" targetClass="EnsLib.RecordMap.Model.ComplexBatch">
	<parameter id="MapName" paramName="MapName" value="" />
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">
<html id="complexMapTable" width="70%"></html>

<vgroup id="propertyPane" width="100%">
<label id="propertyLabel" value="ComplexMap" labelClass="propertyLabelText" containerStyle="width: 100%;" />

<vgroup id="controlGroup">
<html id="errorHTML" />
<form id="complexbatchForm" hidden="true">
<text id="complexbatchTargetClassname" label="Target Classname" size="48" title="Classname for generated ComplexBatch message" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<text id="complexbatchCharEncoding" label="Character Encoding" size="48" title="Character encoding to expect for the text data" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<textarea id="complexbatchAnnotation" label="Annotation" cols="42" rows="4" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</form>
<form id="sequenceForm" hidden="true">
<hgroup cellVAlign="bottom">
<text id="sequenceName" label="Sequence Name" size="29" title="Name of the sequence" onchange="if (!zenPage.changeElementName(zenThis.value)) { return false; } zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<spacer width="28"/>
<button id="sequenceMakeRecordButton" controlClass="commandButton" caption="Make Record" title="Click to make this Sequence a reference to a single RecordMap" onclick="zenPage.changeElementType();" />
</hgroup>
<checkbox id="sequenceRequired" label="Required" title="Mark the sequence as Required" onchange="zenPage.applyChanges();" />
<checkbox id="sequenceRepeating" label="Repeating" title="Mark the sequence as repeating" onchange="zenPage.toggleRepeating(zenPage.currItem,true); zenPage.applyChanges();" />
<hgroup id="sequenceRepeatOptions" hidden="true">
<text id="sequenceMinRepeats" size="12" clientType="integer" label="Minimum Repetitions" title="The minimum number of repetitions" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<spacer width="25"/>
<text id="sequenceMaxRepeats" size="12" clientType="integer" label="Maximum Repetitions" title="The maximum number of repetitions" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
</hgroup>
<textarea id="sequenceAnnotation" label="Annotation" cols="42" rows="4" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</form>
<form id="referenceForm" hidden="true">
<hgroup cellVAlign="bottom">
<text id="referenceName" label="Record Name" size="29" title="Name of the record property" onchange="if (!zenPage.changeElementName(zenThis.value)) { return false; } zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<spacer width="20"/>
<button id="referenceMakeSequenceButton" controlClass="commandButton" caption="Make Sequence" title="Click to make this Record a Sequence of records" onclick="zenPage.changeElementType();" />
</hgroup>
<selector id="referenceRecordMap" size="45" label="RecordMap" title="RecordMap to use for this property" context="Ens.ContextSearch/RecordMaps" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<checkbox id="referenceRequired" clientType="boolean" label="Required" title="Mark the record as Required" onchange="zenPage.applyChanges();" />
<checkbox id="referenceRepeating" clientType="boolean" label="Repeating" title="Mark the record as repeating" onchange="zenPage.toggleRepeating(zenPage.currItem,true); zenPage.applyChanges();" />
<hgroup id="referenceRepeatOptions" hidden="true">
<text id="referenceMinRepeats" size="12" clientType="integer" label="Minimum Repetitions" title="The minimum number of repetitions" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<spacer width="25"/>
<text id="referenceMaxRepeats" size="12" clientType="integer" label="Maximum Repetitions" title="The maximum number of repetitions" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
</hgroup>
<textarea id="referenceAnnotation" label="Annotation" cols="42" rows="4" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</form>
<form id="headertrailerForm" hidden="true">
<text id="headertrailerName" label="Name" size="48" title="Name of the Header or Trailer" onchange="if (!zenPage.changeElementName(zenThis.value)) { return false; } zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<selector id="headertrailerRecordMap" size="45" label="RecordMap" title="RecordMap to use for this property" context="Ens.ContextSearch/RecordMaps" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<textarea id="headertrailerAnnotation" label="Annotation" cols="42" rows="4" onchange="zenPage.applyChanges();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</form>
</vgroup>
</vgroup>
</hgroup>
</pane>
}

/// Get ComplexBatch object for the JSON provider.
Method GetMapObject(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ""
	Try {
	 	Set tMapName = $$$NormalizeClassname($get(pParms("MapName")))
	 	Set tComplexMap = ""
	 	
	 	Set tReadOnly = 0
		If (tMapName '= "") {
			If ..isNew {
				Set tComplexMap = ##class(EnsLib.RecordMap.Model.ComplexBatch).%New()
				Set tComplexMap.name = tMapName
				Set tComplexMap.targetClassname = tMapName_".Batch"
			}
			Else {
				Set tSC = ..LoadClassDefinition(tMapName,.tMapDef,.tReadOnly)
				If $$$ISERR(tSC) Quit
				Set tConcurrency = $select(tReadOnly: 0, 1: 4)
				Set tComplexMap = ##class(EnsLib.RecordMap.Model.ComplexBatch).LoadFromClass(tMapName,.tSC,,tConcurrency)
				If $$$ISERR(tSC) Quit
				If $IsObject(tComplexMap) {
					Set tComplexMap.ReadOnly = tReadOnly
					Set tComplexMap.Timestamp = $zdatetime(tMapDef.TimeChanged,3,,6)
				}
			}
		}
		If $$$ISERR(tSC) Quit
		Set pObject = tComplexMap
		If $IsObject(pObject) {
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pObject.ReadOnly = 2
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process submitted JSON content based on the object created
Method SubmitMapObject(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, ByRef pObject As %RegisteredObject, Output pResponse As %RegisteredObject) As %Status
{
    Set tSC = $$$OK
    Try {
	    If ($IsObject(pObject)) {
		    Set tReadOnly = 0
			If ((pCommand = "save") || (pCommand = "forcesave")) && pObject.%IsA("EnsLib.RecordMap.Model.ComplexBatch") {
				If (pCommand = "save") && ##class(%Dictionary.ClassDefinition).%ExistsId(pObject.name) {
					Set tSC = ..LoadClassDefinition(pObject.name,.tMapDef,.tReadOnly,1)
					If $$$ISERR(tSC) Quit
					If $zdatetime(tMapDef.TimeChanged,3,,6) '= pObject.Timestamp {
						Set pProvider.error = "timestamp"
						Quit
					}
				}
				// correct the ReadOnly flag on the response object
				If ..IsSourceControlReadOnly(..GetInternalName()) {
					Set pProvider.error = $$$Text("Your source control framework has marked this document as read only, so you will not be able to modify this document.")
					Quit
				} Else {
					Set pObject.ReadOnly = tReadOnly
				}
				Set tSC = pObject.SaveToClass()
				If $$$ISERR(tSC) Quit
				Set pResponse = pObject
			}
	    }  
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method GetInternalName() As %String
{
	Quit $select(..complexMap = "": "", 1: $$$NormalizeClassname(..complexMap)_".CLS")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	If (..complexMap = "") && '..isNew {
		Set ..complexMap = ..GetLastMap()
		If (..complexMap '= "") && '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(..complexMap) {
			Set ..complexMap = ""
			Do ..SetLastMap(..complexMap)
		}
	}
	ElseIf (..complexMap '= "") {
		Do ..SetLastMap(..complexMap)
	}

	If ..complexMap '= "" {
		If ..isNew {
			Set ..isNew = '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(..complexMap)
		}
		Set tMapName = $$$NormalizeClassname(..complexMap)
		Do ..%SetValueById("MapName",tMapName)
	}
	Quit tSC
}

Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	&html<<script type="text/javascript">
if (!Array.prototype.indexOf) { // ensure we have indexOf() available for arrays
	Array.prototype.indexOf = function Array_indexOf(searchElement,fromIndex) {
		var index = -1;
		if (!fromIndex) fromIndex = 0;
		for (var i = fromIndex; i < this.length; i++) {
			if (this[i] === searchElement) {
				index = i;
				break;
			}
		}
		return index;
	};
}
</script>>
	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $select(..complexMap = "": ..%OnGetPageName(), 1: ..complexMap)
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Complex Record Mapper","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Complex Record Mapper")

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdOpen",$$$Text("Open"),..tipOpen,"zenPage.openMap();")
	If $system.Security.Check("%Ens_RecordMap","WRITE") || $system.Security.Check("%Ens_Code","WRITE") {
		Set pCommands(2) = $LB("cmdNew",$$$Text("New"),..tipNew,"zenPage.newMap();")
		Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),..tipSave,"zenPage.saveMap();")
		Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),..tipSaveAs,"zenPage.saveMapAs();")
		Set pCommands(5) = $LB("cmdGen",$$$Text("Generate"),..tipGen,"zenPage.generateMap();")
		Set pCommands(6) = $LB("cmdDelete",$$$Text("Delete"),..tipDelete,"zenPage.deleteMap();")
	}
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	Set hlpUndo = $$$Text("Undo last action")
	&html<<td style="width:24px; display: block;">&nbsp;</td>
	<td><image id="iconUndo" class="reIconDisabled" title="#(hlpUndo)#" src="portal/loop_24.gif" onclick="zenPage.undo();"/></td>>
	Quit ##super()
}

/// Get the next available "default" Complex RecordMap name.
ClassMethod NextDefaultComplexMap() As %String [ Internal, ZenMethod ]
{
	Quit ##class(EnsLib.RecordMap.Utils).NextDefaultMap("Complex")
}

ClassMethod GetLastMap() As %String [ CodeMode = expression ]
{
$get(^EnsPortal.Settings($username,"ComplexMapper","LastComplexMap"))
}

ClassMethod SetLastMap(pMapName As %String = "") [ ZenMethod ]
{
	If pMapName = "" {
		Kill ^EnsPortal.Settings($username,"ComplexMapper","LastComplexMap")
	}
	Else {
		Set ^EnsPortal.Settings($username,"ComplexMapper","LastComplexMap") = pMapName
	}
}

ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('complexMap');
}

/// Return the current name of the class/object being modified
ClientMethod getCurrentName() [ Language = javascript ]
{
	return this.complexMap;
}

ClientMethod applyChanges() [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	if (this._textMonitor) this._textMonitor.reset();
	this.addUndoAction(true);
	if (this.currItem >= 0) {
		var element = this._rowIndex[this.currItem];
		var elementType = this.getElementType(element);
		if (elementType != '') {
			if (!this._propIndex) this.buildPropIndex();
			if ((elementType == 'headertrailer') && element.placeHolder) {
				var complexMap = this._rowIndex[0];
				var newElement = { "_class": element._class };
				complexMap[element.which] = newElement;
				element = newElement;
				this._rowIndex[this.currItem] = newElement;
			}
			var props = (elementType != '') ? this._propIndex[elementType] : [];
			for (var i = 0; i < props.length; i++) {
				var propName = props[i];
				var controlName = elementType + propName.substring(0,1).toUpperCase() + propName.substring(1);
				element[propName] = zen(controlName).getValue();
			}
			if ((elementType == 'reference') || (elementType == 'sequence')) {
				if (element.repeating && element.required && ((element.minRepeats == '') || (parseInt(element.minRepeats,10) == 0))) {
					element.minRepeats = 1;
				} 
				else if (!element.repeating) {
					element.minRepeats = '';
					element.maxRepeats = '';
				}
			}
		}
	}
	this.drawTable();
}

ClientMethod getComplexMap() [ Language = javascript ]
{
	var jsonProvider = this.getClientModel();
	if (jsonProvider) {
		var map = jsonProvider.getContentObject();
		this.updateJSONSCReadOnly(map);
		return map;
	} else {
		return null;
	}
}

ClientMethod rowMouseOver(evt, row) [ Language = javascript ]
{
	if (!evt) evt = window.event;
	if (row) {
		row.className += ' complexMapMouseOver';
	}
	ZLM.killEvent(evt);
}

ClientMethod rowMouseOut(evt, row) [ Language = javascript ]
{
	if (!evt) evt = window.event;
	var removeClass = false;
	if (row) {
		if (evt) {
			var target = (typeof evt.srcElement != 'undefined' ? evt.srcElement : evt.target);
			if (!target) {
				removeClass = true;
			}
			else {
				if (target.parentElement == row) {
					removeClass = true;
			  	}
				else {
					// check whether the actual trigger element is a descendant of target
					var checkElement = (evt.relatedTarget ? evt.relatedTarget : evt.toElement);
					var nodeName = checkElement ? checkElement.nodeName.toString().toUpperCase() : '';
					while (checkElement && (checkElement != target) && (nodeName != 'HTML') && (nodeName != 'BODY')) {
						checkElement = checkElement.parentNode;
						if (checkElement) nodeName = checkElement.nodeName.toString().toUpperCase();
					}
					// if checkElement != target, then it's not a descendant, so remove the class
					removeClass = (checkElement !== target);
				}
			}
		}
		if (removeClass) {
			row.className = row.className.toString().replace(' complexMapMouseOver','');
		}
	}
	ZLM.killEvent(evt);
}

ClientMethod drawTable() [ Language = javascript ]
{
	var tableDiv = zen('complexMapTable');
	var html = [];
	var complexMap = this.getComplexMap();
	var selectedItem = (this._rowIndex ? this._rowIndex[this.currItem] : null);
	
	var currentWrapper = self.document.getElementById('complexMapBodyDiv');
	var wrapperStyle = (currentWrapper && (currentWrapper.style.height != '')) ? 'height:'+currentWrapper.style.height+';' : '';
	var scrollTop = (currentWrapper && currentWrapper.scrollTop) ? currentWrapper.scrollTop : 0;
	
	this._rowIndex = [];
	this._nameIndex = { "names": {}, "emptyNames": []};
	this._contractedIndex = [];
	this._childIndex = {};
	tableDiv.setContent('');
	if (complexMap) {
		var mapContracted = false;
		if (!this._tableData) {
			this._tableData = {
				"spacerCell": '<td class="modelSpacerCell">&nbsp;</td>',
				"buttonClass": (!(this.readOnly || !this.canEdit)) ? 'imageLink mapImage' : '',
				"cellClass": 'modelButton'
			};
		}
		var currRowIndex = this._rowIndex.push(complexMap) - 1;
		this._contractedIndex.push(mapContracted);
		var add = '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/add_16.png' + '" title="' + $$$Text("Add a new field") + '" onclick="zenPage.addItem(' + currRowIndex + ',event);" />';

		// draw table for main ComplexMap
		html.push('<table id="complexMapHeader" class="mapTable" border="0" cellspacing="0">');
		html.push('<tr class="complexMapTitle" id="row_' + currRowIndex + '" onclick="zenPage.selectItem(' + currRowIndex + ');" onmouseover="zenPage.rowMouseOver(event,this);" onmouseout="zenPage.rowMouseOut(event,this);">');
		html.push('<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>');
		html.push('<td>' + zenEscapeHTML(complexMap.name) + '</td>');
		html.push('<td class="'+this._tableData.cellClass+'">' + add + '&nbsp;</td>');
		html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>'); // Up
		html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>'); // Down
		html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>'); // Delete
		html.push(this._tableData.spacerCell);
		html.push('</tr>');
		html.push('</table>');
		// draw table for all child elements
		html.push('<div id="complexMapBodyDiv" style="'+wrapperStyle+'">');
		html.push('<table class="mapTable" border="0" cellspacing="0">');
		
		this.drawHeaderTrailerHTML(complexMap,'Header',html);
		var elements = complexMap.Elements;
		if (elements) {
			this._childIndex[currRowIndex] = [];
			for (var i = 0; i < elements.length; i++) {
				var element = elements[i];
				this.drawElementHTML(element,complexMap,currRowIndex,mapContracted,html,[i],i==0,i==(elements.length-1),0);
			}
		}
		this.drawHeaderTrailerHTML(complexMap,'Trailer',html);
	}
	tableDiv.setContent(html.join(''));
	this.validateMap(false);
	if (selectedItem || (this.currItem == -1)) {
		var row = (this._currItem == -1) ? -1 : this._rowIndex.indexOf(selectedItem);
		this.selectItem(row,true);
	}
	if (scrollTop > 0) {
		currentWrapper = self.document.getElementById('complexMapBodyDiv');
		if (currentWrapper) currentWrapper.scrollTop = scrollTop;
	}
}

ClientMethod drawHeaderTrailerHTML(complexMap, property, html) [ Language = javascript ]
{
	var rowClass = 'complexHeaderTrailer';
	var staticElement = complexMap[property];
	if (!staticElement) {
		var placeHolderClass = 'EnsLib.RecordMap.Model.' + property + 'Record';
		var placeHolderName = '[' + (property == 'Header' ? $$$Text('Header') : $$$Text('Trailer')) + ']';
		staticElement = { "placeHolder": true, "name": placeHolderName, "recordMap": "", "which": property, "_class": placeHolderClass };
		rowClass += 'Empty';
	}
	var details = '<span class="modelRowDetail">&nbsp;';
	if (staticElement.recordMap) details += zenEscapeHTML(staticElement.recordMap) + '&nbsp;';
	details += '</span>';
	
	var currRowIndex = this._rowIndex.push(staticElement) - 1;
	this._contractedIndex.push(false);
	this.addToNameIndex(staticElement,currRowIndex);
	var remove = '&nbsp;';
	if (!staticElement.placeHolder) remove = '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/close_a_16.png' + '" title="' + $$$Text('Remove this item') + '" onclick="zenPage.removeHeaderTrailer(\'' + property + '\');" />';

	html.push('<tr class="' + rowClass + '" id="row_'+currRowIndex+'" onclick="zenPage.selectItem('+currRowIndex+');" onmouseover="zenPage.rowMouseOver(event,this);" onmouseout="zenPage.rowMouseOut(event,this);">');
	html.push('<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>');
	html.push('<td>&nbsp;' + zenEscapeHTML(staticElement.name) + '&nbsp;' + '</td>');
	
	html.push('<td>' + details + '</td>');
	html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">' + remove + '</td>');
	html.push(this._tableData.spacerCell);
	html.push('</tr>');
}

ClientMethod drawElementHTML(element, parent, parentIndex, parentContracted, html, path, first, last, depth) [ Language = javascript ]
{
	if (!html) html = [];
	var currRowIndex = this._rowIndex.push(element) - 1;
	this._contractedIndex.push(parentContracted);
	if (this._childIndex[parentIndex]) this._childIndex[parentIndex].push(currRowIndex);
	this.addToNameIndex(element,currRowIndex);
	element._parent = parent;
	element._path = path;
	var elementType = this.getElementType(element);
	
	var elementContracted = !!element._contracted;
	depth = ('undefined' == typeof depth) ? 0 : depth;
	var indent = 16 + (16*depth);
	var indentImg = '<img height="1px" width="' + indent + 'px" src="images/spacer.gif"/>';
	this._nameIndex[element.name] = true;
	
	var up = first || parentContracted ? '' : '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/up_16.png' + '" title="' + $$$Text('Move this item up') + '" onclick="zenPage.moveItem('+currRowIndex+',\'up\',event);" />';
	var down = last || parentContracted ? '' : '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/down_16.png' + '" title="' + $$$Text('Move this item down') + '" onclick="zenPage.moveItem('+currRowIndex+',\'down\',event);" />';
	var add = '';
	var remove = '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/close_a_16.png' + '" title="' + $$$Text('Remove this item') + '" onclick="zenPage.removeItem('+currRowIndex+',event);" />';
	var disc = '';
	var rowClass = 'complex' + elementType.substring(0,1).toUpperCase() + elementType.substring(1);
	
	if (elementType == 'sequence') {
		add = '<img width="16px" class="'+this._tableData.buttonClass+'" src="' + 'deepsee/add_16.png' + '" title="' + $$$Text('Add a new record') + '" onclick="zenPage.addItem('+currRowIndex+',event);" />';
		disc = '<img id="expandoImage_'+currRowIndex+'" width="16px" src="' + (!elementContracted ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleExpandingElement(' + currRowIndex + ',event);"/>&nbsp;';
	}
	
	html.push('<tr class="'+rowClass+'" id="row_'+currRowIndex+'" onclick="zenPage.selectItem('+currRowIndex+',false,event);" style="'+(parentContracted ? 'display: none;' : '')+'" onmouseover="zenPage.rowMouseOver(event,this);" onmouseout="zenPage.rowMouseOut(event,this);">');
	html.push('<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>');
	html.push('<td>' + indentImg + disc + zenEscapeHTML(element.name) + '</td>');
	html.push('<td>' + this.getElementDetails(element) + '</td>');
	html.push('<td class="'+this._tableData.cellClass+'">' + add + '&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">' + up + '&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">' + down + '&nbsp;</td>');
	html.push('<td class="'+this._tableData.cellClass+'">' + remove + '&nbsp;</td>');
	html.push(this._tableData.spacerCell);
	html.push('</tr>');

	if (elementType == 'sequence') {
		this._childIndex[currRowIndex] = [];
		if (element.Elements) {
			var childDepth = depth + 1;
			var lastChildPos = element.Elements.length - 1;
			for (var i = 0; i < element.Elements.length; i++) {
				var childElement = element.Elements[i];
				this.drawElementHTML(childElement,element,currRowIndex,elementContracted,html,path.concat([i]),i==0,i==lastChildPos,childDepth);
			}
		}
	}
}

ClientMethod removeHeaderTrailer(which) [ Language = javascript ]
{
	if (!this.canUserModify()) return;
	if ((which != 'Header') && (which != 'Trailer')) return;

	var complexMap = this.getComplexMap();
	if (complexMap) {
		this.addUndoAction(true);
		delete complexMap[which];
		this.drawTable();
	}
}

ClientMethod addToNameIndex(element, index) [ Language = javascript ]
{
	if ((!index) || (!element) || (!this._nameIndex)) return;
	if (element.name == '') {
		this._nameIndex.emptyNames.push(index);
	}
	else {
		if (!this._nameIndex.names[element.name]) this._nameIndex.names[element.name] = [];
		this._nameIndex.names[element.name].push(index);
	}
}

ClientMethod getNextRecordName() [ Language = javascript ]
{
	if ((!this._nameIndex) || (!this._nameIndex.names[$$$Text('Record')])) return $$$Text('Record');
	var counter = 1;
	var recPrefix = $$$Text('Record');
	while (this._nameIndex.names[recPrefix+counter]) {
		counter++;
	}
	return recPrefix + counter;
}

ClientMethod getElementDetails(element) [ Language = javascript ]
{
	var details = '';
	if (element) {
		var min = 0;
		var max = 1
		if (element.required) min = 1;
		if (element.repeating) {
			if (element.minRepeats > min) min = element.minRepeats;
			if (element.maxRepeats == 0) { max = '&#8734;'; }
			else if (element.maxRepeats > max) { max = element.maxRepeats; }
		}
		details = '<span class="modelRowDetail">&nbsp;' + min + '..' + max;
		if (element.recordMap) {
			details += '&nbsp;' + zenEscapeHTML(element.recordMap);
		}
		details += '&nbsp;</span>';
	}
	return details;
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	if (load) {
		this.drawTable();
		this.setReadOnly(this.readOnly || !this.canEdit);
		
		if (zenIsGecko || zenIsIE) {
			var txt = ['complexbatchTargetClassname','complexbatchCharEncoding','headertrailerName'];
			for (var i in txt) {
				var comp = zen(txt[i]);
				if (comp) {
					comp.setProperty('size',54);
				}
			}
			var selectors = ['referenceRecordMap','headertrailerRecordMap'];		
			for (var i in selectors) {
				var comp = zen(selectors[i]);
				if (comp) {
					comp.setProperty('size',51);
				}
			}
		} else { // Chrome
			var txtArea = ['complexbatchAnnotation','sequenceAnnotation','referenceAnnotation','headertrailerAnnotation'];
			for (var i in txtArea) {
				var comp = zen(txtArea[i]);
				if (comp) {
					comp.setProperty('cols',50);
				}
			}
		}

		this._loadComplete = true;
	}
	var tableDiv = zen('complexMapTable').getEnclosingDiv();
	var propertyDiv = zen('propertyPane').getEnclosingDiv();

	var winWidth = zenGetWindowWidth();
	var propertyWidth = propertyDiv.offsetWidth;
	var tableWidth = winWidth - propertyWidth - 10;
	if (tableWidth > 1200) tableWidth = 1200;
	tableDiv.style.width = tableWidth + 'px';

	var winHeight = zenGetWindowHeight();
	var titleHeight = this.getTitleAreaHeight();
	var contentHeight = winHeight - titleHeight - 10;
	tableDiv.style.height = contentHeight + 'px';
	propertyDiv.style.height = contentHeight + 'px';
}

ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	readOnly = !!readOnly;
	this.readOnly = readOnly;
	
	if (!this._propIndex) this.buildPropIndex();
	for (var formName in this._propIndex) {
		var formList = this._propIndex[formName];
		for (var i = 0; i < formList.length; i++) {
			var propName = formList[i];
			var controlName = formName + propName.substring(0,1).toUpperCase() + propName.substring(1);
			var zenControl = zen(controlName);
			if (zenControl) {
				zenControl.setReadOnly(readOnly);
				zenControl.setProperty('disabled',readOnly);
			}
		}
	}
	var buttons = [ 'sequenceMakeRecordButton', 'referenceMakeSequenceButton' ];
	for (var i = 0; i < buttons.length; i++) {
		var button = zen(buttons[i]);
		if (button) {
			button.setProperty('controlClass',readOnly ? 'commandButtonDisabled' : 'commandButton');
			button.setDisabled(readOnly);
		}
	}
	
	if (readOnly) {
		this.grayOutButtons();
		if (!this.canEdit) {
			this.grayOutOneButton('command_cmdNew');
			this.grayOutOneButton('command_cmdSaveAs');
		}
	} else {
		var btnSave = document.getElementById('command_cmdSave');
		if (btnSave) {
			btnSave.className = 'commandButton';
			btnSave.onclick = function() { zenPage.saveMap();return false; }
			btnSave.title = this.tipSave;
		}
		var btnGen = document.getElementById('command_cmdGen');
		if (btnGen) {
			btnGen.className = 'commandButton';
			btnGen.title = this.tipGen;
			btnGen.onclick = function() { zenPage.generateMap();return false; }
		}
		var btnDelete = document.getElementById('command_cmdDelete');
		if (btnDelete) {
			btnDelete.className = 'commandButton';
			btnDelete.title = this.tipDelete;
			btnDelete.onclick = function() { zenPage.deleteMap();return false; }
		}
	}
	this.updateUndoButton()
}

/// Call <method>UpdateSCMenu</method>() first in case the document has been modified elsewhere,
/// then display the source control menu based on the contents of the _sourceControlMenu data
/// created by <method>UpdateSCMenu</method>().
ClientMethod showSCMenu() [ Language = javascript ]
{
	this.UpdateSCMenus();
	this.invokeSuper('showSCMenu',arguments);
}

/// Handle a source control menu selection.
ClientMethod chooseSCMenu(menuName, commandName, saveFlags) [ Language = javascript ]
{
	zenPage.wasReadOnly = zenPage.getIsReadOnly();
	this.invokeSuper('chooseSCMenu',arguments);
	zenPage.toggleReadOnly();
}

ClientMethod selectItem(index, force) [ Language = javascript ]
{
	force = (typeof force == 'undefined') ? false : force;
	if ((this.currItem != index) || force) {
		//un-select
		if (this.currItem >= 0) {
			var oldRow = document.getElementById('row_'+this.currItem);
			if (oldRow) oldRow.className = oldRow.className.toString().replace(' complexMapSelected','');
		}
		if ((index >= 0) && this._contractedIndex[index]) {
			// not a visible index
			index = -1;
		}
		this.currItem = index;
		var newRow = document.getElementById('row_'+index);
		if (newRow) newRow.className += ' complexMapSelected';
		
		var element = this._rowIndex[index];
		// complexbatch or sequence or record or ''
		var elementType = this.getElementType(element);
		
		var errorHTML = zen('errorHTML');
		var errContent = [];
		if (element && element._errors && (element._errors.length > 0)) {
			errContent.push('<div class="complexErrorTitle">' + $$$Text('This item is not valid') + '</div>');
			errContent.push('<ol class="complexErrorList">');
			for (var i = 0; i < element._errors.length; i++) {
				errContent.push('<li>' + element._errors[i] + '</li>');
			}
			errContent.push('</ol>');
			errContent.push('<hr/>');
		}
		errorHTML.setContent(errContent.join(''));
		
		var hideForms = { 'complexbatch': true, 'sequence': true, 'reference': true, 'headertrailer': true };
		if (element) hideForms[elementType] = false;
		for (var formName in hideForms) {
			var form = zen(formName + 'Form');
			form.setHidden(hideForms[formName]);
		}
		
		if (!this._propIndex) this.buildPropIndex();
		var props = (elementType != '') ? this._propIndex[elementType] : [];
		for (var i = 0; i < props.length; i++) {
			var propName = props[i];
			var controlName = elementType + propName.substring(0,1).toUpperCase() + propName.substring(1);
			if (element.placeHolder && ((propName == 'name') || (propName == 'annotation'))) {
				zen(controlName).setValue('');
			}
			else if (zen(controlName)) {
				zen(controlName).setValue(element[propName]);
			}
		}
		this.toggleRepeating(index);

		var elementClass = element ? element._class : '';
		var formTitle = this.getElementUserType(elementType,elementClass);
		
		zen('propertyLabel').setValue(formTitle);
		
	}
}

ClientMethod buildPropIndex() [ Language = javascript ]
{
	this._propIndex = {
		"complexbatch":	[ 'charEncoding', 'targetClassname', 'annotation' ],
		"sequence":		[ 'name', 'required', 'repeating', 'minRepeats', 'maxRepeats', 'annotation' ],
		"reference":	[ 'name', 'required', 'repeating', 'minRepeats', 'maxRepeats', 'recordMap', 'annotation' ],
		"headertrailer": [ 'name', 'recordMap', 'annotation' ]
	};
}

ClientMethod getElementType(element) [ Language = javascript ]
{
	if (element && element._class) {
		var shortName = element._class.toString().split('.').pop().toLowerCase().replace('record','');
		if ((shortName == 'header') || (shortName == 'trailer')) shortName = 'headertrailer';
		return shortName;
	}
	return '';
}

ClientMethod getElementUserType(elementType, elementClass) [ Language = javascript ]
{
	var formTitle = '';
	switch(elementType) {
		case 'complexbatch':
			formTitle = $$$Text('Complex Map');
			break;
		case 'reference':
			formTitle = $$$Text('Record');
			break;
		case 'sequence':
			formTitle = $$$Text('Sequence');
			break;
		case 'headertrailer':
			if (typeof elementClass == 'undefined') elementClass = '';
			if (elementClass.split('.').pop() == 'HeaderRecord') {
				formTitle = $$$Text('Header');
			}
			else {
				formTitle = $$$Text('Trailer');
			}
			break;
	}
	return formTitle;
}

/// Returns the index of the currently selected item and the offsets of the main window in
/// a comma separated list. It returns the empty string "" if no item is selected.
ClientMethod getCurrentLocation() [ Language = javascript ]
{
	if ((this.currItem == -1) || !this.currItem) {
		return '';
	}
	var tableWrapperDiv = document.getElementById('complexMapBodyDiv');
	var scrollTop = tableWrapperDiv ? tableWrapperDiv.scrollTop : 0;
	var scrollLeft = tableWrapperDiv ? tableWrapperDiv.scrollLeft : 0;
	return this.currItem + ',' + scrollTop + ',' + scrollLeft;
}

/// Update the description (annotation) of this record map.
ClientMethod setDescription(desc) [ Language = javascript ]
{
	if (this.canEdit) {
		var model = this.getComplexMap();
		if (model) {
			if (desc != model.annotation) {
				model.annotation = desc;
				this.setModified(true);
			}
		}
	}
}

ClientMethod changeElementName(newName) [ Language = javascript ]
{
	if (!this.canUserModify()) return;
	if (this._rowIndex && this._nameIndex && (newName != '')) {
		var currNames = this._nameIndex.names[newName];
		if (currNames && (currNames.length > 0) && currNames.indexOf && (currNames.indexOf(this.currItem) == -1)) {
			alert($$$FormatText($$$Text("Name '%1' is already in use"),newName));
			return false;
		}
	}
	return true;
}

ClientMethod changeElementType() [ Language = javascript ]
{
	if (!this.canUserModify()) return;
	if (this._rowIndex && (this.currItem != -1)) {
		var element = this._rowIndex[this.currItem];
		var elementType = this.getElementType(element);
		if ((elementType != 'sequence') && (elementType != 'reference')) {
			alert(this.msgNotPermitted);
			return;
		}
		var newType = (elementType == 'sequence' ? 'reference' : 'sequence');
		this.addUndoAction(true);
		var newElement = { "name": element.name, "required": element.required, "repeating": element.repeating, "minRepeats": element.minRepeats, "maxRepeats": element.maxRepeats, "annotation" : element.annotation };
		newElement['_class'] = 'EnsLib.RecordMap.Model.Record' + (newType == 'sequence' ? 'Sequence' : 'Reference');
		if (newType == 'reference') {
			newElement.recordMap = '';
		}
		else if (newType == 'sequence') {
			var newChild = { "name": this.getNextRecordName(), "recordMap": "", "required": false, "repeating": false, "minRepeats": "", "maxRepeats": "", "_class": "EnsLib.RecordMap.Model.RecordReference", "annotation" : "" };
			newElement.Elements = [ newChild ];
		}
		var parent = element._parent;
		var pos = parent.Elements.indexOf(element);
		if (pos == -1) pos = parent.Elements.length;
		parent.Elements[pos] = newElement;
		
		var elementsToAdd = [];
		if (element.Elements && (element.Elements.length > 0)) elementsToAdd = element.Elements;
		var elToAdd = elementsToAdd.pop();
		while (elToAdd) {
			parent.Elements.splice(pos+1,0,elToAdd);
			elToAdd = elementsToAdd.pop();
		}
		this.currItem = -1;
		this.drawTable();
		var newIndex = this._rowIndex.indexOf(newElement);
		if (newIndex != -1) this.selectItem(newIndex);
	}
}

/// Check that the Target Classname is changed along with the ComplexMap name
ClientMethod changeTargetClassname(newMapName) [ Language = javascript ]
{
	if ((newMapName != '') && (newMapName != null)) {
		zen('complexbatchTargetClassname').setValue(newMapName + '.Batch');
	}
}

ClientMethod toggleRepeating(index, getFromForm) [ Language = javascript ]
{
	if (getFromForm && !this.canUserModify()) return false;
	if (this._rowIndex && (this.currItem == index)) {
		var element = this._rowIndex[index];
		var elementType = this.getElementType(element);
		if (elementType != '') {
			var repeatOptions = zen(elementType + 'RepeatOptions');
			if (repeatOptions) {
				var currValue = (getFromForm ? zen(elementType + 'Repeating').getValue() : element.repeating);
				repeatOptions.setHidden(!currValue);
			}
		}
	}
}

ClientMethod toggleExpandingElement(index) [ Language = javascript ]
{
	if (this._childIndex && this._childIndex[index]) {
		var allChildren = this._childIndex[index].concat([]);
		var element = this._rowIndex[index];
		if (element) {
			element._contracted = !element._contracted;
			var childStyle = (element._contracted ? 'none' : '');
			var toggleButton = document.getElementById('expandoImage_'+index);
			if (toggleButton) toggleButton.src = (element._contracted ? 'images/arrow1R.gif' : 'images/arrow1D.gif');
			while (allChildren.length > 0) {
				var currChildId = allChildren.splice(0,1);
				var row = document.getElementById('row_'+currChildId);
				if (row) row.style.display = childStyle;
				if (this._childIndex[currChildId]) allChildren = allChildren.concat(this._childIndex[currChildId]);
			}
		}
	}
}

ClientMethod moveItem(index, direction, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (typeof evt.stopPropagation == 'function') evt.stopPropagation();
	}
	if (!this.canUserModify()) return false;
	if (!this._rowIndex) return false;
	if ((direction != 'up') && (direction != 'down')) return false;
	var element = this._rowIndex[index];
	var elementType = this.getElementType(element);
	if ((elementType != 'sequence') && (elementType != 'reference')) return false;
	if (!element._parent) return false;
	this.addUndoAction(true);
	var parent = element._parent;
	var currPos = element._path[element._path.length - 1];
	var newPos = (direction == 'up') ? currPos-1 : currPos+1;
	var swapElement = parent.Elements[newPos];
	parent.Elements[currPos] = swapElement;
	parent.Elements[newPos] = element;
	// no need to update this.currItem as _rowIndex has not changed
	this.drawTable();
	var newIndex = this._rowIndex.indexOf(element);
	if (newIndex != -1) this.selectItem(newIndex);
}

ClientMethod addItem(parentIndex, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (typeof evt.stopPropagation == 'function') evt.stopPropagation();
	}
	if (!this.canUserModify()) return false;
	if (!this._rowIndex) return false;
	var parent = this._rowIndex[parentIndex];
	var parentType = this.getElementType(parent);
	if ((parentType != 'complexbatch') && (parentType != 'sequence')) return false;
	this.addUndoAction(true);
	var nextRecordName = this.getNextRecordName();
	var newRecord = { "_class": "EnsLib.RecordMap.Model.RecordReference", "name": nextRecordName, "recordMap": "", "repeating": false, "required": false, "minRepeats": "", "maxRepeats": "", "annotation": "" };
	parent.Elements.push(newRecord);
	this.currItem = -1;
	this.drawTable();
	var newIndex = this._rowIndex.indexOf(newRecord);
	if (newIndex != -1) {
		this.selectItem(newIndex,true);
		var nameControl = zen('referenceName');
		if (nameControl) nameControl.focus();
	}
}

ClientMethod removeItem(index, evt) [ Language = javascript ]
{
	if (evt) {
		evt.cancelBubble = true;
		if (typeof evt.stopPropagation == 'function') evt.stopPropagation();
	}
	if (!this.canUserModify()) return false;
	if (this._rowIndex) {
		var element = this._rowIndex[index];
		if (!element) return false;
		var elementType = this.getElementType(element);
		var userType = this.getElementUserType(elementType,element._class);
		var ok = confirm($$$Text('Do you wish to delete this item?') + '\n' + userType + ": " + element.name);
		if (!ok) return false;

		this.addUndoAction(true);
		var parent = element._parent;
		if (parent) {
			if (elementType == 'headertrailer') {
				var propName = (element._class.split('.').pop() == 'HeaderRecord') ? 'Header' : 'Trailer';
				delete parent[propName];
			}
			else if (elementType != '') {
				var pos = element._path ? element._path[element._path.length - 1] : -1;
				parent.Elements.splice(pos,1);
			}
			// force no item to be selected
			this.currItem = -1;
			this.drawTable();
		}
	}
}

/// Remember the current state in the undo buffer.
ClientMethod addUndoAction(setModified) [ Language = javascript ]
{
	if (!this._loadComplete) return;
	if (!this._undoBuffer) this._undoBuffer = [];
	var complexMap = this.getComplexMap();
	if (complexMap) {
		var copy = this.cloneObject(complexMap);
		this._undoBuffer.push( { "map": copy, "currItem": this.currItem } );
		this.updateUndoButton();
		if (setModified) this.setModified(true);
	}
}

/// Return true if it is possible to undo an action
ClientMethod canUndo() [ Language = javascript ]
{
	return (this._undoBuffer && (this._undoBuffer.length > 0) && (this.canEdit && !this.readOnly));
}

/// Undo the most recent change.
ClientMethod undo() [ Language = javascript ]
{
	if (this.canUndo()) {
		var complexMap = this.getComplexMap();
		var oldData = this._undoBuffer.pop();
		var json = this.getClientModel();
		json.setContentObject(oldData.map);
		this.drawTable();

		this.selectItem(oldData.currItem,true);
		this.updateUndoButton();
		if (this._undoBuffer.length == 0) {
			this.setModified(false);
		} else {
			this.setModified(true);
		}
	}
}

/// Clear the undo buffer.
ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	this._undoBuffer = [];
	this.updateUndoButton();
}

ClientMethod updateUndoButton() [ Language = javascript ]
{
	var undo = self.document.getElementById('iconUndo');
	var canUndo = this.canUndo();
	undo.disabled = !canUndo;
	undo.className = 'imageLink' + (!canUndo ? ' reIconDisabled' : '');
}

/// Create a clone of the given object.
ClientMethod cloneObject(obj, clone) [ Language = javascript ]
{
	var clone = clone ? clone : {};
	for (var prop in obj) {
		if (prop == '_parent') {
			// skip back pointers
		}
		else if (null == obj[prop]) {
			clone[prop] = null;
		}
		else if (typeof obj[prop] == 'object') {
			clone[prop] = (obj[prop].constructor === Array) ? []: {};
			this.cloneObject(obj[prop],clone[prop]);
		}
		else {
			clone[prop] = obj[prop];
		}
	}
	return clone;
}

/// Load the page for the specified RecordMap.
ClientMethod loadEditor(complexMapName, location, newMap, renamed) [ Language = javascript ]
{
	var url = "EnsPortal.ComplexRecordMapper.zen?COMPLEXMAP="+encodeURIComponent(complexMapName);
	url = url + (location ? "&LOC="+encodeURIComponent(location) : '');
	url = url + (newMap ? "&NEW=1" : '');
	url = url + (renamed ? "&RENAMED=1" : '');
	this.gotoPage(url);
	return;
}

/// Launch the finder dialog to select a ComplexMap.
ClientMethod openMap() [ Language = javascript ]
{
	this.checkTextControls();

	// check if user has made changes and prompt them to save
	if (this.pageModified) {
		var ok = confirm($$$Text('Changes have not been saved for the current Complex RecordMap. Discard the changes?'));
		if (!ok) return false;	
	}

	var parms = {
		MODE: 'classes',
		SUPER: 'EnsLib.RecordMap.ComplexMap'
	};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen'),this.addPopupSuffix('OpenComplexMap'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Create a new ComplexMap.
ClientMethod newMap() [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	this.checkTextControls();
	if (this.pageModified) {
		var discard = confirm($$$Text('Changes have not been saved for the current Complex RecordMap. Discard the changes?'));
		if (!discard) return false;	
	}
	// show wizard dialog
	var parms = {};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ComplexMapWizard.zen'),this.addPopupSuffix('NewComplexMap'),'status,scrollbars,resizable=yes,width=450,height=400',parms);
}

ClientMethod deleteMap() [ Language = javascript ]
{
	if (!this.canUserModify()) return false;
	if (this.complexMap == '') {
		return '';
	}
	if (zenPage.IsDocReadOnly()) {
		alert($$$Text($$$Text("Your source control framework has marked this document as read only, so you will not be able to delete this document.")));
		// Gray out buttons to indicate the document is read only
		zenPage.grayOutButtons();
		return false;
	}
	
	var parms = {
		COMPLEXMAP:this.complexMap
		};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ComplexMapDelete.zen'),this.addPopupSuffix('DeleteComplexMap'),'status,scrollbars,resizable=yes,width=500,height=400',parms);
}

ClientMethod saveMapAs() [ Language = javascript ]
{
	if (!this.canUserModify(true)) {
		return false;
	}
	var desc = '';
	var map = this.getComplexMap();
	if (map) {
		desc = map.annotation;
	}
	var parms = {
		MAP:this.complexMap,
		DESC:desc
	};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ComplexMapSave.zen'),this.addPopupSuffix('SaveComplexMap'),'status,scrollbars,resizable=yes,width=700,height=700',parms);
}

/// Method to save the Complex RecordMap to disk without generating any classes.
ClientMethod saveMap(force, suppressOKMessage) [ Language = javascript ]
{
	var rename = false;
	if ((zenPage.complexMapAsName != '') && (zenPage.complexMapAsName != zenPage.complexMap)) {
		rename = true;
		var oldComplexMap = this.complexMap;
		this.complexMap = this.complexMapAsName;
		this.complexMapAsName='';
	}
	if (!this.canUserModify(rename)) return false;
	if ((!force) && (!this.pageModified) && (!rename)) {
		alert($$$Text('No changes to save.'));
		return true;
	}
	// Ensure we don't send placeholders back for Header or Trailer
	var complexMap = this.getComplexMap();
	var placeHolder = { "Header": null, "Trailer": null };
	if (complexMap) {
		if (complexMap.Header && complexMap.Header.placeHolder) {
			placeHolder.Header = complexMap.Header;
			delete complexMap.Header;
		}
		if (complexMap.Trailer && complexMap.Trailer.placeHolder) {
			placeHolder.Trailer = complexMap.Trailer;
			delete complexMap.Trailer;
		}
		var isValid = this.validateMap(true);
		if (!isValid) {
			if (rename) {
				// reset old name
				this.complexMap = oldComplexMap;
				// Enable correction of document after failed Save As while readonly
				if (this.readOnly) {
					this.setReadOnly(false);
					zenPage.grayOutOneButton('command_cmdSave');
					zenPage.grayOutOneButton('command_cmdGen');
					zenPage.grayOutOneButton('command_cmdDelete');
				}
			}
			return false;
		}
		if (rename) {
			var oldClassname = complexMap.targetClassname;
			complexMap.name = this.complexMap;
			complexMap.targetClassname = this.complexMap + '.Batch';
		}
	}
	if (rename && this.readOnly) {
		try {
			this.readOnly = false;
			var ok = this.saveDocument();
			this.readOnly = true;
		} catch (ex) {
			this.readOnly = true;
		}
	} else {
		var ok = this.saveDocument();
	}
	// Reinstate placeholders before we do anything else
	if (placeHolder.Header || placeHolder.Trailer) {
		complexMap = this.getComplexMap();
		if (placeHolder.Header && !complexMap.Header) complexMap.Header = placeHolder.Header;
		if (placeHolder.Trailer && !complexMap.Trailer) complexMap.Trailer = placeHolder.Trailer;
	}
	var msg = '';
	if (ok) {
		msg = (suppressOKMessage ? '': $$$Text('Complex RecordMap saved.'));
	}
	else {
		if (rename) {
			// reset old name
			this.complexMap = oldComplexMap;
			complexMap.name = oldComplexMap;
			complexMap.targetClassname = oldClassname;
			// Enable correction of document after failed Save As while readonly, but only if failure is a validation error and not source control/timestamp
			if (this.readOnly && this.pageModified) {
				var json = this.getClientModel();
				if (json.error.substring(0,5)=="ERROR") {
					this.setReadOnly(false);
					zenPage.grayOutOneButton('command_cmdSave');
					zenPage.grayOutOneButton('command_cmdGen');
					zenPage.grayOutOneButton('command_cmdDelete');
					alert($$$Text('Please correct errors before saving.'));
				}
			}
		} else if (zenPage.getIsReadOnly()) {
			// If this document was found to be readOnly, gray out buttons to indicate this
			zenPage.grayOutButtons();
		}
		// reset old description
		complexMap.annotation = zen('complexbatchAnnotation').getValue();
		return false;
	}
	if (msg != '') alert(msg);
	this.clearUndoBuffer();
	this.setModified(false);
	if (rename) {
		var currLoc = this.getCurrentLocation();
		this.loadEditor(this.complexMap,currLoc,false,rename);
	} else {
		return !!ok;
	}
}

ClientMethod validateMap(reportErrors) [ Language = javascript ]
{
	var errors = [];
	if (this._rowIndex) {
		for (var i = 0; i < this._rowIndex.length; i++) {
			var element = this._rowIndex[i];
			this.validateElement(element,i,errors);
		}
	}
	if (reportErrors && (errors.length > 0)) alert($$$Text('There are errors in this Complex RecordMap. Please correct the errors before saving:') + '\n' + errors.join('\n\t '));
	return (errors.length == 0);
}

ClientMethod validateElement(element, rowIndex, errors) [ Language = javascript ]
{
	if (!errors) errors = [];
	var startCount = errors.length;
	if (element) {
		element._errors = [];
		var elementType = this.getElementType(element);
		var userType = this.getElementUserType(elementType,element._class);
		if (element.name.toString() == '') {
			errors.push($$$FormatText($$$Text('%1 must have a name.'),userType));
			element._errors.push($$$FormatText($$$Text('This %1 must have a name.'),userType));
		}
		if (element.Elements && (element.Elements.length == 0)) {
			errors.push($$$FormatText($$$Text("%1 '%2' must contain at least one Record or Sequence."),userType,element.name));
			element._errors.push($$$FormatText($$$Text("This %1 must contain at least one Record or Sequence."),userType));
		}
		if ((elementType == 'reference') && (element.recordMap == '')) {
			errors.push($$$FormatText($$$Text("RecordMap must be specified for Record '%1'."),element.name));
			element._errors.push($$$Text('A RecordMap must be specified.'));
		}
		else if ((elementType == 'headertrailer') && (element.recordMap == '') && (!element.placeHolder)) {
			var errText = (userType == 'Header' ? $$$Text("RecordMap must be specified for Header '%1'.") : $$$Text("RecordMap must be specified for Trailer '%1'."));
			errors.push($$$FormatText(errText,element.name));
			element._errors.push($$$Text('A RecordMap must be specified.'));
		}
	}
	var row = document.getElementById('row_' + rowIndex);
	if (row) {
		row.title = '';
		var currRowClass = row.className.toString();
		var errorClassPos = currRowClass.indexOf(' complexMapError');
		
		if ((errors.length > startCount) && (errorClassPos == -1)) {
			row.className = currRowClass + ' complexMapError';
			row.title = $$$Text('This element is invalid. Click on the row to see more details.');
		}
		else if ((errors.length == startCount) && (errorClassPos > -1)) {
			row.className = currRowClass.replace(' complexMapError','');
		}
	}
	return (errors.length == startCount);
}

/// Ensure we redraw the table if the model was updated.
ClientMethod onDocumentSaveComplete(contentUpdated) [ Language = javascript ]
{
	this.invokeSuper('onDocumentSaveComplete',arguments);
	if (contentUpdated) {
		this.drawTable();
		this.updateUndoButton();
	}
}

/// Ensure we redraw the diagram if the model was updated.
ClientMethod onDocumentReload(reason) [ Language = javascript ]
{
	if (this._inReload) { return; } // avoid recursion
	this._inReload = true;
	this.updateDocumentState(true);
	if (reason == "dataChange") {
		this.drawTable();
		this.updateUndoButton();
		this.setModified(false);
	}
	this._inReload = false;
}

ClientMethod generateMap() [ Language = javascript ]
{
	if (!this.canUserModify()) return false;

	var saveOK = this.saveMap(true,true);
	if (!saveOK) return false;
	
	var parms = { COMPLEXMAP: this.complexMap };
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ComplexMapGenerate.zen'),this.addPopupSuffix('GenerateComplexMap'),'status,scrollbars,resizable=yes,width=720,height=700',parms);
}

/// Returning from popups 
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'switchNamespace': // change namespace but keep the same page
			zenPage.changeURLNamespace(value);
			break;
		case 'OpenComplexMap':
			var newClass = value.split('.');
			// remove .CLS extension
			newClass.pop();
			newClass = newClass.join('.');
			this.loadEditor(newClass,'',false);
			break;
		case 'NewComplexMap':
			if (value != '') {
				this.loadEditor(value,'',true);
			}
			break;
		case 'SaveComplexMap':
			this.saveMap(false,false);
			break;
		case 'DeleteComplexMap':
			this.loadEditor('');
			break;
	}
	return true;
}

}
