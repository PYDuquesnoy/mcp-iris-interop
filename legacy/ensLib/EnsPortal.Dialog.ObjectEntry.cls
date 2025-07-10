/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page is used to enter a context or Document object for Rule Testing UI
Class EnsPortal.Dialog.ObjectEntry Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// JavaScript debug library
/// Usage: ZLM.dumpObj(object);
Parameter JSINCLUDES = "zenCSLM.js";

/// User needs USE permissions on the %Ens_TestingService resource to view this page.
Parameter RESOURCE = "%Ens_TestingService:USE";

Parameter PAGENAME = "Rule Testing - Context Entry";

Parameter APPLYBUTTON = 0;

Parameter PRIVATE = 1;

Property Context As %String(MAXLEN = 128, ZENURL = "CONTEXT");

XData Style
{
<style type="text/css">
td.AutoFormCaption, td.AutoFormControl, td.AutoFormValue {
	font-size: 10pt;
	padding-right: 5px;
	font-weight: normal;
	color: black;
}

.labelText, .zenLabel, .expandoNode, .expandoNode a, .expandoNode a:hover {
	font-size: 10pt;
	font-weight: bold;
	color: black;
	padding: 0px;
	padding-right: 5px;
	border: 0px;
}

#topMessages {
	font-size: 10pt;
}

.boxedArea {
	font-size: 10pt;
	border: 1px solid black;
}

.ribbonSortOption {
	color: #3B84BC;
	text-decoration: none;
}

.ribbonSortOption:hover {
	color: darkred;
}

.errorMessage {
	color: red;
	font-weight: bold;
}

table.StatusBar {
	font-size: 12pt;
	font-weight: normal;
	border: 0;
	background: grey;
	border-collapse: collapse;
	border-spacing: 0;
}

td.StatusOn {
	background: blue;
}

td.StatusOff {
	background: grey;
}

table.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 10pt;
}

table td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

table td.AutoFormTableValue {
	font-weight: normal;
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

.AutoFormButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	margin-top: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.AutoFormButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
</style>
}

/// Contents of this page:
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup>
<spacer width="20" />
<group>
<vgroup>
<spacer height="20" />
<hgroup>
<label label="Class:" id="classLabel"/>
<combobox id="cmbContextType" name="cmbContextType" size="80" hzScroll="true" editable="false" onchange="zenPage.changeContextType();" valign="top">
</combobox>
</hgroup>
</vgroup>
<vgroup id="testingGroup" hidden="true">
<expando id="id_Context" caption="Context Details" animate="true" framed="false" groupClass="boxedArea" imageContracted="images/treeplus.gif" imageExpanded="images/treeminus.gif">
<html id="id_DrawContextForm" enclosingStyle="margin-left:5px; margin-right:5px;" OnDrawContent="DrawContextForm" onrefresh="zenPage.formRefreshed();"/>
</expando>
<spacer height="15" />
</vgroup>
</group>
</hgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	If $zname(..Context,4) && ##class(%Dictionary.ClassDefinition).%ExistsId(..Context) 
			&& $classmethod(..Context,"%Extends","%Library.Persistent") {
		Do ..PopulateListOfContextTypes()
		Quit ##super()
	} Else {
		#dim tCombo = %page.%GetComponentById("cmbContextType")
		Set tCombo.hidden = 1
		#dim tBtn = %page.%GetComponentById("btnOK")
		Set tBtn.hidden = 1
		#dim tLabel = %page.%GetComponentById("classLabel")
		Set tLabel.label = $$$TextHTML("Invalid Classname Provided")
		Quit $$$OK
	}
}

/// Populate control with the list of context types for this Rule.
Method PopulateListOfContextTypes()
{
	If ..Context = "" Quit

	#dim tCombo = %page.%GetComponentById("cmbContextType")
	#dim tRequests = ""
	#; Find subclasses as well

	#dim tParams
	Set tParams("class") =..Context
	Do ##class(Ens.ContextSearch).SubclassOf(,,.tRequests,.tParams)
	Set tRequests(0) = ..Context
	#; Add to UI control
	#dim tName=""
	#dim tIndex = ""
	For {
		Set tIndex = $O(tRequests(tIndex),1,tName)
		Quit:tIndex=""
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do tCombo.options.Insert(tOption)
		Do ..%AddComponent(tOption)
		Set tOption.text = tName
		Set tOption.value = tName
		}
	#; If there is only one option, select it
	If tCombo.options.Count()=1 {
		#dim tDefChoice = tCombo.options.GetAt(1).value
		Set tCombo.value = tDefChoice
		Set %page.Context = tDefChoice
		Set %page.%GetComponentById("testingGroup").hidden = 0
	}
	Quit
}

/// User selected a request type.
ClientMethod changeContextType() [ Language = javascript ]
{
	var req = zen('cmbContextType').getValue();
	zenPage.Context = req;
	var tControl = zen('id_DrawContextForm');
	tControl.ReallyRefreshContents();
	zenSetProp("testingGroup","hidden",false);
}

/// Draw input data form for selected Context type.
Method DrawContextForm(pSeed As %String) As %Status
{
	#dim tReqClass = %page.Context
	#dim tObj = ""

	If ((tReqClass'="")&&(tReqClass'="%Library.Persistent")) {

		Try {
			If $classmethod(tReqClass,"%Extends","EnsLib.MsgRouter.RoutingEngine") {
				Set tObj=##class(Ens.Host).GetShadowInstance("class ||"_tReqClass,.tSC)
			} ElseIf $classmethod(tReqClass,"%Extends","Ens.BP.Context") {
				Set tObj = $classmethod(tReqClass,"%New","")  // Null BP
			} Else {
				Set tObj = $classmethod(tReqClass,"%New")
			}
		} Catch {}

		If $IsObject(tObj) {

			#dim tID
			#dim tButtons = "" // No Save/Cancel Buttons

			If $classmethod(tReqClass,"%Extends","Ens.Util.MessageBodyMethods") {

				Do $classmethod(tReqClass, "%DrawHTMLForm", tObj, .tID, "", tButtons)

			} Else {

				Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLForm(tObj, .tID, "", tButtons)

			}

		}
	}

	Return $$$OK
}

/// This can happen if the Class is changed or re-selected in the drop down.
ClientMethod formRefreshed() [ Internal, Language = javascript ]
{
	if (zenPage.Context === 'EnsLib.HL7.Message') { try {var sync = this.amendDocFormForHL7();} catch (ex) {} }
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Rule Testing","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $zconvert(%page.Context,"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	if (!self.document.theForm) {return '';}
	var data = "";
	var contextData = {
		"%clsname" : this.Context,
	};
	var contentCtrlList = self.document.getElementsByName('%XCONT');
	if (contentCtrlList && (contentCtrlList.length == 1)) {
		var theForm = self.document.theForm;
		var contentCtrl = contentCtrlList[0];
		if (contentCtrl) {
			var formCtrlList = self.document.getElementsByName('$IDXCONT');
			if (formCtrlList) {
				for (var i=0; i < formCtrlList.length; i++) {
					var formCtrl = formCtrlList[i];
					if (formCtrl && (formCtrl.form == theForm)) {
						contextData['%IDXCONT']=contentCtrl.value;
						break;
					}
				}
			}
		}
	}
	for (var n = 0; n < self.document.theForm.length; n++) {
		var elemName = self.document.theForm[n].name;
		if (elemName.charAt(0) == '$') continue;
		var elemType = self.document.theForm[n].type;
		var elemValue = self.document.theForm[n].value;
		if (elemType=='checkbox') {
			if (self.document.theForm[n].checked) {
				elemValue = 1;
			}
			else {
				elemValue = 0;
			}
		}
		contextData[elemName]=elemValue;
	}
	data = JSON.stringify(contextData);
	return encodeURIComponent(data);
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the dialog stays open.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
if (!self.document.theForm) {return true;}
var opener = this.getOpener();
if ( opener ) {
	var openerContextSerialized = opener.zenPage.getComponentById('testContextSerialized');
	if (openerContextSerialized) {
		var json = openerContextSerialized.getValue();
		if (json !="") {
			try {
				var contextData = JSON.parse(json);
		 		this.Context = contextData["%clsname"];
				var contentCtrlList = self.document.getElementsByName('%XCONT');
				if (contentCtrlList && (contentCtrlList.length == 1)) {
					var theForm = self.document.theForm;
					var contentCtrl = contentCtrlList[0];
					if (contentCtrl) {
						var formCtrlList = self.document.getElementsByName('$IDXCONT');
						if (formCtrlList) {
							for (var i=0; i < formCtrlList.length; i++) {
								var formCtrl = formCtrlList[i];
								if (formCtrl && (formCtrl.form == theForm)) {
									contentCtrl.value = contextData['%IDXCONT'];
									break;
								}
							}
						}
					}
				}
				for (var n = 0; n < self.document.theForm.length; n++) {
					var elemName = self.document.theForm[n].name;
					if (elemName.charAt(0) == '$') continue;
					var elemType = self.document.theForm[n].type;
					var elemValue = self.document.theForm[n].value;
					if (elemType=='checkbox') {
						self.document.theForm[n].checked = contextData[elemName];
					} else {
						self.document.theForm[n].value = contextData[elemName];
					}
				}

			} catch (ex) {alert(ex);}
		}
	}
	this.formRefreshed();
}
return true;
}

/// Add the Schema and Structure drops downs and add tool tip.
ClientMethod amendDocFormForHL7() [ Internal, Language = javascript ]
{
	if (this.Context!='EnsLib.HL7.Message') return false;

	var docTypeInput = this.dataEntryDocType();

	var sync = this.insertDocTypeDropDowns();
	if (!sync) return false;

	var docCategorySelect = document.getElementById('select-docCategory');
	if (!docCategorySelect) return false;

	var optionList = this.ServerGetQueryData('docCategory');
	this.setComboOptions(docCategorySelect,optionList);

	if (docTypeInput.category !='') {
		this.setComboValue(docCategorySelect,docTypeInput.category);
	}

	this.comboSelectChanged(docCategorySelect);

	if (docTypeInput.structure!='') {
		var docTypeNameSelect = document.getElementById('select-docTypeName');
		if (docTypeNameSelect) this.setComboValue(docTypeNameSelect,docTypeInput.structure);
	}

	/* reset DocType field to empty if empty at form load */
	if (docTypeInput.category == '') {
		var docTypeInput = document.getElementsByName('DocType');
		if (docTypeInput) {
			docTypeInput[0].value ='';
		}
	}

	var sync = this.addOnChangeToDocText();
	/* reveal helper row after any changes made to prevent flashes */
	var helperRow =  document.getElementById('hl7DocTypeHelperRow');
	if (helperRow) helperRow.style.display = '';
}

ClientMethod insertDocTypeDropDowns() [ Internal, Language = javascript ]
{
	var docTypeInput = document.getElementsByName('DocType');
	if (docTypeInput) {

		var enclosingTD = docTypeInput[0].parentNode;
		if (enclosingTD) {
			/* build row to insert */
			var rowToInsert = document.createElement('tr');
			rowToInsert.setAttribute('id','hl7DocTypeHelperRow');
			/* hide helper row until finish any changes to prevent flashes */
			rowToInsert.setAttribute('style','display:none');
			rowToInsert.setAttribute('class','AutoForm');
			rowToInsert.setAttribute('valign','CENTER');

				var blankCaptionCell = document.createElement('td');
				blankCaptionCell.setAttribute('class','AutoFormCaption');
				rowToInsert.appendChild(blankCaptionCell);

				var cellWithARow = document.createElement('td');
				cellWithARow.setAttribute('class','AutoFormControl');

					var rowInACell = document.createElement('tr');

						var docCategoryCell = document.createElement('td');
						docCategoryCell.setAttribute('class','AutoFormControl');
							var docCategoryDiv = this.createComboDiv('docCategory');
							docCategoryCell.appendChild(docCategoryDiv);
						rowInACell.appendChild(docCategoryCell);

						var spacerCell = document.createElement('td');
							var spacerText = document.createTextNode('\u00A0\u00A0\u00A0\u00A0');
							spacerCell.appendChild(spacerText);
						rowInACell.appendChild(spacerCell);

						var docCategoryCell = document.createElement('td');
						docCategoryCell.setAttribute('class','AutoFormControl');
							var docTypeNameDiv = this.createComboDiv('docTypeName');
							docCategoryCell.appendChild(docTypeNameDiv);
						rowInACell.appendChild(docCategoryCell);

					cellWithARow.appendChild(rowInACell);

				rowToInsert.appendChild(cellWithARow);

			var enclosingTR = enclosingTD.parentNode;
			if (enclosingTR) {
				enclosingTR.insertAdjacentElement("afterend",rowToInsert);
				/* add tool tip to DocType: caption */
				var captionTD = enclosingTR.getElementsByTagName("td")[0];
				if (captionTD) {
					var info = $$$Text('Enter DocType or select both category and structure to populate. The MessageType from the HL7 test message is also examined to aid in entry.');
					captionTD.setAttribute('title',info);
				}
			}

		}
	}
	return true;
}

ClientMethod createComboDiv(name) [ Internal, Language = javascript ]
{
	var div = document.createElement('div');
	div.setAttribute('style','position:relative; top:0px; left:0px;');
		var select = document.createElement('select');
		select.setAttribute('id','select-'+name);
		select.setAttribute('class','comboSelect');
		select.setAttribute('onchange','zenPage.comboSelectChanged(this);');
			var input = document.createElement('input');
			input.setAttribute('id','text-'+name);
			input.setAttribute('type','text');
			input.setAttribute('class','comboText');
			select.appendChild(input);
		div.appendChild(select);
	return div;
}

ClientMethod setComboOptions(combo, options) [ Internal, Language = javascript ]
{
	if ( zenIsIE ) {
		while ( combo.options.length > 0 ) { combo.options.remove(0); }
		var optionsArray = options.split(",");
		for ( i=0 ; i<optionsArray.length ; i++ ) {
			var opt = new Option(optionsArray[i]);
			combo.options.add(opt);
		}
	} else {
		var optionsArray = options.split(",");
		var innerHTML = "";
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			innerHTML = innerHTML + "<option>" + zenEscapeHTML(optionsArray[i]) + "</option>";
		}
		combo.innerHTML = innerHTML;
	}
	return;
}

ClientMethod setComboValue(combo, value) [ Internal, Language = javascript ]
{
	combo.selectedIndex = -1;
	if ( zenIsIE ) {
		for ( var i=0 ; i<combo.options.length ; i++ ) {
			if ( combo.options[i].text == value ) {
				combo.selectedIndex = i;
			}
		}
	} else {
		combo.value = value;
	}

	var name = combo.id.split("-")[1];
	if (name === 'docTypeName') {
		this.setDocTypeFieldFromDropDowns();
	}

	return;
}

ClientMethod comboSelectChanged(object) [ Internal, Language = javascript ]
{
	var name = object.id.split("-")[1];
	if (name === 'docCategory') {
		var select = document.getElementById('select-docTypeName');
		if (select) {
			var optionList = this.ServerGetQueryData('docTypeName',object.value);
			this.setComboOptions(select,optionList);
			this.updateStructureFromHL7Text();
		}
	} else if (name === 'docTypeName') {
		this.setDocTypeFieldFromDropDowns();
	}
	return;
}

ClientMethod setDocTypeFieldFromDropDowns() [ Internal, Language = javascript ]
{
	var docTypeNameSelect = document.getElementById('select-docTypeName');
	if (docTypeNameSelect) {
		var structure = docTypeNameSelect.value;
		var docCategorySelect = document.getElementById('select-docCategory');
		if (docCategorySelect) {
			var category = docCategorySelect.value;
			var docTypeInput = document.getElementsByName('DocType');
			if (docTypeInput) {
				docTypeInput[0].value = category+':'+structure;
			}
		}
	}
}

ClientMethod addOnChangeToDocText() [ Internal, Language = javascript ]
{

	var hl7TextBoxes = document.getElementsByName('%XCONT');
	if (!hl7TextBoxes) return false;

	var hl7TextBox = hl7TextBoxes[0];
	hl7TextBox.setAttribute('onchange','zenPage.updateStructureFromHL7Text()');

	return true;
}

ClientMethod updateStructureFromHL7Text() [ Internal, Language = javascript ]
{
	var messageType = this.findmessageTypeFromHL7Message();
	if (messageType === '') return;

	var docCategorySelect = document.getElementById('select-docCategory');
	if (docCategorySelect) {
		var category = docCategorySelect.value;
		if (category!='') {
			var structure = this.ServerGetHL7DocStructure(category,messageType);
			if (structure!='') {
				var docTypeNameSelect = document.getElementById('select-docTypeName');
				if (docTypeNameSelect) this.setComboValue(docTypeNameSelect,structure);
			}
		}
	}
}

ClientMethod findmessageTypeFromHL7Message() [ Internal, Language = javascript ]
{
	try {

		var messageType = '';

		var hl7TextBoxes = document.getElementsByName('%XCONT');
		if (!hl7TextBoxes) return '';

		var hl7TextBox = hl7TextBoxes[0];

		var hl7Message = hl7TextBox.value;
		if ((hl7Message === '')||(hl7Message.length < 5))return '';
		if (hl7Message.substring(0,3) != 'MSH') return '';

		var fieldDelimiter = hl7Message.charAt(3);
		var hl7Fields = hl7Message.split(fieldDelimiter);
		if (hl7Fields.length<8) return '';

		messageType = hl7Fields[8];
		var componentSep = hl7Message.charAt(4);
		messageType = messageType.replace(componentSep,"_");

	} catch (ex) { messageType = ''; }

	return messageType;
}

/// Return as an object the value from the DocType field split into category and structure
ClientMethod dataEntryDocType() [ Internal, Language = javascript ]
{
	var docTypeInputCtl = document.getElementsByName('DocType');
	var docTypeInput = {};
	docTypeInput.category = '';
	docTypeInput.structure = '';
	if (docTypeInputCtl) {
		categoryAndStructure = docTypeInputCtl[0].value;
		if (categoryAndStructure != '') {
			var categoryAndStructureArray = categoryAndStructure.split(":");
			if ((categoryAndStructureArray.length)===2) {
				docTypeInput.category = categoryAndStructureArray[0];
				docTypeInput.structure = categoryAndStructureArray[1];
			}
		}
	}
	return docTypeInput;
}

/// Internal server side method to retrieve list of Schema categories or structures.
/// This is only called if the context is EnsLib.HL7.Message and hence EnsLib.HL7.MsgRouter.RuleAssist
/// will exist in this namespace.
ClassMethod ServerGetQueryData(pParam As %String = "", pValue As %String = "") As %String [ Internal, ZenMethod ]
{
	#; Validate Input from web page
	If (pParam'="docCategory") && (pParam'="docTypeName") Return ""
	#dim tArray
	If (pParam="docTypeName") Set tArray("docCategory") = pValue
	Try {
		#dim queryData = ##class("EnsLib.HL7.MsgRouter.RuleAssist").GetQueryData(.tArray,pParam)
	} Catch {Set queryData = ""}
	Return queryData
}

/// Internal server side method to resolve doc type structure for HL7 rule testing
ClassMethod ServerGetHL7DocStructure(pCategory As %String = "", pMessageType As %String = "") As %String [ Internal, ZenMethod ]
{
	Try {
		#dim tDocStructure = ""
		#dim tDocType=##class(EnsLib.HL7.Schema).ResolveSchemaTypeToDocType(pCategory,pMessageType)
	} Catch {Set tDocType = ""}
	Return $Piece(tDocType,":",2)
}

}
