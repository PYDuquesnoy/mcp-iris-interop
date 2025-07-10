/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.ConstraintEditor Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

Parameter APPLYBUTTON = 0;

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter RESOURCE = "%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ,%Ens_Code:READ";

/// User needs WRITE permissions on one of the following resources to make changes on this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter EDITRESOURCE = "%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE,%Ens_Code:WRITE";

/// the assist class name
Property ASSIST As %String(MAXLEN = "", ZENURL = "ASSIST");

/// The name of the default production name
Property PROD As %String(ZENURL = "PROD");

/// Flag to indicate whether the main rule is open in ReadOnly mode, which should also apply here.
Property readOnly As %ZEN.Datatype.boolean(ZENURL = "READONLY") [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
.selectDiv {
	overflow-y: auto;
	text-align: left;
	vertical-align: middle;
	font-size: 0.75em;
	height: 200px;
	min-width: 130px;
	background-color: white;
	border: 1px solid gray;
	padding: 1px;
	border-radius: 5px;
}
.selectText {
	height: 200px;
	margin: 0px;
	padding: 1px;
	padding-left: 3px;
	border: 1px solid gray;
	background-color: white;
	overflow-y: auto;
	border-radius: 5px;
}
.selectCheckBox {
	vertical-align: bottom;
}
.selectCheckBoxLabel {
	display: inline;
	cursor: default;
}
.selectOption {
	display: block;
}
.selectOption.selectHover {
	border-radius: 2px;
	background-color: #F3E799;
	padding: 0px;
}
.comboText {
	margin: 0px;
	position: absolute;
	top: 0px;
	left: 0px;
	z-index: 1;
}
.comboSelect {
	position: relative;
	top: 0px;
	left: 0px;
	margin: 0px;
}
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" enclosingStyle="position: relative; top: 0px; left: 0px;">
<spacer height="20"/>
<hgroup containerStyle="padding:150px;" cellStyle="padding-left:10px;">
<spacer width="20"/>
<html id="htmlPanel"/>
<vgroup id="holder">
</vgroup>
</hgroup>
</pane>
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	var html = new Array();

	this.getMetaData();
	this.getRuntimeData();
	html.push("<table cellspacing='10' cellpadding='10'>");
	for ( i=0 ; i<this.metaData.length ; i++ ) {
		if ( this.metaData[i].control == "list" ) {
			this.createListControl(html,this.metaData[i].name,this.metaData[i].caption,this.metaData[i].type,this.metaData[i].param);
		} else if ( this.metaData[i].control == "combo" ) {
			this.createComboControl(html,this.metaData[i].name,this.metaData[i].caption,this.metaData[i].param);
		} else {
			this.createTextControl(html,this.metaData[i].name,this.metaData[i].caption);
		}
	}
	html.push("</table>");
	if (zenIsIE && !zenIsHTML5) { // do this asynchronously to stop IE7/8 from not rendering the div
		setTimeout('zenPage.renderControls(\''+html.join('').replace(/[\\"']/g,'\\$&')+'\');',100);
	}
	else {
		this.renderControls(html.join(''));
	}
}

ClientMethod renderControls(htmlContent) [ Language = javascript ]
{
	zen("htmlPanel").setContent(htmlContent);

	for ( i=0 ; i<this.metaData.length ; i++ ) {
		this.setControlValue(this.metaData[i].name,this.runtimeData[this.metaData[i].name]);
	}

	this.updateAssistData();
	this._controlsRendered = true;
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	if (this._controlsRendered) {
		for ( i=0 ; i<this.metaData.length ; i++ ) {
			if ( this.metaData[i].control == "list" ) {
				document.getElementById("textarea-"+this.metaData[i].name).style.width = zenGetWindowWidth()/3+"px";
			} else if ( this.metaData[i].control == "combo" ) {
				document.getElementById("select-"+this.metaData[i].name).style.width = zenGetWindowWidth()/3+"px";
				document.getElementById("text-"+this.metaData[i].name).style.width = (zenGetWindowWidth()/3-(24-(zenIsChrome*2)-((zenIsIE && !zenIsHTML5)*6)))+"px";
			} else {
				document.getElementById("text-"+this.metaData[i].name).style.width = zenGetWindowWidth()/3+"px";
			}
		}
	}
	return;
}

ClientMethod getRuntimeData() [ Language = javascript ]
{
	this.runtimeData = {};
	for ( var i=0 ; i<this.metaData.length ; i++ ) {
		this.runtimeData[this.metaData[i].name] = "";
	}
	var opener = this.getOpener();
	if ( opener ) {
		var jsonObject = opener.zenPage.moMainMap[opener.zenPage.moFocusedIndex].jsonObject;
		for ( var i=0 ; i<jsonObject.constraints.length ; i++ ) { // force string values
			this.runtimeData[jsonObject.constraints[i].name] = ''+jsonObject.constraints[i].value;
		}
	}
	return;
}

ClientMethod updateAssistData() [ Language = javascript ]
{
	for ( i=0 ; i<this.metaData.length ; i++ ) {
		if ( this.metaData[i].type == "query" ) {
			var optionList = this.getQueryData(this.metaData[i].param);
			var select = document.getElementById("select-"+this.metaData[i].name);
			if ( optionList == "" ) {
				if (select) {
					if ( this.metaData[i].control == 'list' ) {
						select.style.display = 'none';
					}
					else {
						select.disabled = true;
					}
				}
			} else if (select) {
				if ( this.metaData[i].control == "list" ) {
					if (this.readOnly || !this.canEdit) { select.style.display = 'none'; }
					else {
						select.style.display = '';
						this.setCheckListOptions(select,optionList);
					}
				} else {
					if (!(this.readOnly || !this.canEdit)) select.disabled = false;
					this.setComboOptions(select,optionList);
					this.setComboValue(select,this.getControlValue(this.metaData[i].name));
				}
			}
		}
	}
	return;
}

ClientMethod updateCheckBoxes(name, newValue) [ Language = javascript ]
{
	var selectDiv = document.getElementById('select-'+name);
	if (selectDiv) {
		var newValues = newValue.toString().split(',').join('\n').split('\n');
		var checked = {};
		var cleanValues = [];
		for (var i = newValues.length-1; i>=0; i--) {
			var val = newValues[i];
			if (val != '') {
				checked[val] = true;
				cleanValues.splice(0,0,val);
			}
		}
		if (selectDiv.childNodes) {
			for (var i=selectDiv.childNodes.length - 1; i >= 0; i--) {
				var div = selectDiv.childNodes.item(i);
				if (!!div) {
					var checkBox = div.firstChild;
					if (!!checkBox) checkBox.checked = !!checked[checkBox.value];
				}
			}
		}
		var textArea = document.getElementById('textarea-'+name);
		if (textArea) {
			textArea.value = cleanValues.join('\n');
		}
	}
}

ClientMethod toggleCheckBox(checkboxID, name, evt, isDoubleClick) [ Language = javascript ]
{
	if (evt && isDoubleClick) return true;
	var checkbox = document.getElementById(checkboxID);
	if (checkbox) {
		if (evt) {
			// if the event target is checkbox, we should already have handled the onclick in updateCheckListItem()
			// note that we need to use srcElement for IE8 and older
			var eventTarget = evt.target ? evt.target : evt.srcElement;
			if (eventTarget == checkbox) return true;
		}
		checkbox.checked = !checkbox.checked;
		this.updateCheckListItem(name,checkbox.value,checkbox.checked);
	}
}

ClientMethod updateCheckListItem(name, value, checked, evt, isDoubleClick) [ Language = javascript ]
{
	if (evt) {
		// ignore double-click
		if (isDoubleClick) return false;
	}
	var inputDiv = document.getElementById('textarea-'+name);
	var startValue = inputDiv.value.toString();
	startValue = startValue.replace(/\r/g,'');
	var currValues = [];
	if (startValue != '') currValues = startValue.split('\n');
	var index = {};
	var found = false;
	var newValues = [];
	for (var i=0; i<currValues.length; i++) {
		if (currValues[i] == value) {
			if (checked) newValues.push(value);
			found = true;
		}
		else if (currValues[i] != '') {
			newValues.push(currValues[i]);
		}
	}
	// add value if not seen already
	if (!found) newValues.push(value);
	inputDiv.value = newValues.join('\n');
	return true;
}

ClientMethod setCheckListOptions(div, options) [ Language = javascript ]
{
	while (div.firstChild) {
		div.removeChild(div.firstChild);
	}
	var idPrefix = div.getAttribute('id');
	var name = idPrefix.split('-').pop();
	var checked = {};
	var textArea = document.getElementById('textarea-'+name);
	if (textArea) {
		var currValue = textArea.value.toString().replace(/\r/g,'').split('\n');
		for (var i = currValue.length - 1; i >= 0; i--) {
			var value = currValue[i];
			if (value != '') checked[value] = true;
		}
	}
	var optionsArray = options.split(',');
	var html = [];
	for ( var i=0; i<optionsArray.length; i++) {
		var checkedAttrib = (checked[optionsArray[i]] ? 'checked="checked" ' : '');
		html.push('<div class="selectOption" title="'+optionsArray[i]+'" onclick="zenPage.toggleCheckBox(\''+idPrefix+'_'+optionsArray[i]+'\',\''+name+'\',event,false);" ondblclick="zenPage.toggleCheckBox(\''+idPrefix+'_'+optionsArray[i]+'\',\''+name+'\',event,true);" onmouseover="this.className=\'selectOption selectHover\';" onmouseout="this.className=\'selectOption\';">');
		html.push('<input type="checkbox" id="'+idPrefix+'_'+optionsArray[i]+'" class="selectCheckBox" '+checkedAttrib+'onclick="zenPage.updateCheckListItem(\''+name+'\',this.value,this.checked,event,false);" ondblclick="return zenPage.updateCheckListItem(\''+name+'\',this.value,this.checked,event,true);" value="'+optionsArray[i]+'"/>');
		html.push('<div class="selectCheckBoxLabel">'+optionsArray[i]+'</div>');
		html.push('</div>');
	}
	div.innerHTML = html.join('');
}

ClientMethod setComboOptions(combo, options) [ Language = javascript ]
{
	if ( zenIsIE ) {
		while ( combo.options.length > 0 ) { combo.options.remove(0); }
		var optionsArray = options.split(",")
		for ( i=0 ; i<optionsArray.length ; i++ ) {
			var opt = new Option(optionsArray[i]);
			combo.options.add(opt);
		}
	} else {
		var optionsArray = options.split(",")
		var innerHTML = "";
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			innerHTML = innerHTML + "<option>" + optionsArray[i] + "</option>"
		}
		combo.innerHTML = innerHTML;
	}
	return;
}

ClientMethod setComboValue(combo, value) [ Language = javascript ]
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
	return;
}

ClientMethod createTextControl(html, name, label) [ Language = javascript ]
{
	var disabled = (this.readOnly || !this.canEdit ? 'disabled="disabled" ' : '');
	html.push("<tr>");
	html.push("<td align=right valign=top><nobr>" + label + ": </nobr></td>");
	html.push("<td><input id='text-"+name+"' type='text' "+disabled+"onchange='zenPage.textChanged(this);'/></td>");
	html.push("<td><input id='button-"+name+"' type='button' "+disabled+" onclick=zenPage.buttonClicked(this); value=' ... '/></td>");
	html.push("</tr>");
	return;
}

ClientMethod createComboControl(html, name, label, queryParam) [ Language = javascript ]
{
	var height = zenIsIE&&(!zenIsHTML5) ? '22px' : '1.1em';
	var disabled = (this.readOnly || !this.canEdit ? 'disabled="disabled" ' : '');

	html.push("<tr>");
	html.push("<td align=right valign=top><nobr>" + label + ": </nobr></td>");
	html.push("<td>");
	html.push("<div style='position:relative; top:0px; left:0px;'>");
	html.push('<select id="select-'+name+'" class="comboSelect" '+disabled+'onchange="zenPage.comboSelectChanged(this);">');
	html.push("</select>");
	html.push('<input id="text-'+name+'" type="text" class="comboText" '+disabled+'onchange="zenPage.comboTextChanged(this);" style="height:'+height+';" />');
	html.push("</div>");
	html.push("</td>");
	html.push("<td></td>");
	html.push("</tr>");
	return;
}

ClientMethod createListControl(html, name, label, queryType, queryParam) [ Language = javascript ]
{
	var disabled = (this.readOnly || !this.canEdit ? 'disabled="disabled" ' : '');
	html.push("<tr>");
	html.push('<td align="right" valign="top"><nobr>' + label + ': </nobr></td>');
	if ( queryType=="query" ) {
		html.push('<td><textarea id="textarea-'+name+'" '+disabled+'class="selectText" onchange="zenPage.updateCheckBoxes(\''+name+'\',this.value); return true;"></textarea></td>');
		html.push('<td align="right" valign="top"><div id="select-'+name+'" class="selectDiv" '+disabled+' /></td>');
	} else {
		html.push('<td><textarea id="textarea-'+name+'" '+disabled+'rows="8"></textarea></td>');
		html.push('<td><input id="button-'+name+'" type="button" '+disabled+'onclick="zenPage.buttonClicked(this);" value=" ... "/></td>');
	}
	html.push("</tr>");
	return;
}

ClientMethod setControlValue(name, value) [ Language = javascript ]
{
	var control = this.metaData[this.metaDataIndex[name]].control;
	if ( control == "list" ) {
		// accept comma as a separator; make all separators be carriage returns
		document.getElementById("textarea-"+name).value = value.split(",").join("\n");
	} else if ( control == "combo" ) {
		document.getElementById("text-"+name).value = value;
	} else if ( control == "text" ) {
		document.getElementById("text-"+name).value = value;
	}
	return;
}

ClientMethod getControlValue(name) [ Language = javascript ]
{
	var controlType = this.metaData[this.metaDataIndex[name]].control == "list" ? "textarea" : "text";
	var value = "";
	if ( document.getElementById(controlType+"-"+name) != null ) {
		value = document.getElementById(controlType+"-"+name).value 
	} else {
		value = this.runtimeData[name];
	}
	var control = this.metaData[this.metaDataIndex[name]].control;
	if ( control == "list" ) {
		// make all separators be commas; remove consecutive separators; remove spaces and trailing comma, if any
		value = value.split("\n").join(",").replace(/\s+/g,"").replace(/,+/g,",").replace(/,$/g,"");
	}
	return value;
}

ClientMethod textChanged(object) [ Language = javascript ]
{
	this.updateAssistData();
	return;
}

ClientMethod comboSelectChanged(object) [ Language = javascript ]
{
	var name = object.id.split("-")[1];
	var text = document.getElementById("text-"+name);

	if ( text.value != object.options[object.selectedIndex].text ) {
		text.value = object.options[object.selectedIndex].text;
		this.comboTextChanged(text);
	}
	return;
}

ClientMethod comboTextChanged(object) [ Language = javascript ]
{
	this.updateAssistData();
	return;
}

ClientMethod buttonClicked(object) [ Language = javascript ]
{
	var name = object.id.split("-")[1];
	var metadataObj = this.metaData[this.metaDataIndex[name]];
	if ( metadataObj.type == "class" ) {
		var parms = { MODE: metadataObj.param };
		zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen'),this.addPopupSuffix(name),'status,scrollbars,resizable=yes,width=800,height=600',parms);
	} else if ( metadataObj.type == "configname" ) {
		var ctrlId = metadataObj.control + '-' + name;
		var ctrlVal = '';
		var ctrl = document.getElementById(ctrlId)
		if (ctrl && ctrl.value) {
			ctrlVal = ctrl.value;
		}
		var parms = { PROD: this.PROD, TYPE: 'source', MULTI:0, VALUE: ctrlVal };
		zenLaunchPopupWindow(zenLink('EnsPortal.ConfigItemSelector.zen'),this.addPopupSuffix(name),'status,scrollbars,resizable=yes,width=600,height=480',parms);		
	} else {
		alert(metadataObj.type);
	}
}

ClientMethod selectChoiceSelected(object) [ Language = javascript ]
{
	var name = object.id.split("-")[1];
	var textarea = document.getElementById("textarea-"+name);
	this.addLineToTextarea(textarea,object.options[object.selectedIndex].text);
	object.selectedIndex = 0;
}

ClientMethod addLineToTextarea(object, line) [ Language = javascript ]
{
	if ( (object.value!="")&&(object.value.substr(object.value.length-1)!="\n") ) {
		object.value = object.value + "\n";
	}
	object.value = object.value + line;
	return;
}

Method %OnGetTitle() As %String
{
	Set description = $Classmethod(..ASSIST,"GetDescription")
	Set:description="" description=$$$Text("Rule")
	Quit $$$FormatText($$$Text("%1 Constraint Editor"),description)
}

Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var data = "";
	for ( var i=0 ; i<this.metaData.length ; i++ ) {
		data = (i==0?"":(data+"~")) + this.metaData[i].name + "~" + this.getControlValue(this.metaData[i].name);
	}
	return encodeURIComponent(data);
}

ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var opener = this.getOpener();
	if ( opener ) {
		var jsonObject = opener.zenPage.moMainMap[opener.zenPage.moFocusedIndex].jsonObject;
		jsonObject.constraints.length = 0;
		for ( var i=0 ; i<this.metaData.length ; i++ ) {
			var name = this.metaData[i].name;
			var value = this.getControlValue(name);
			if ( value == "" ) continue;
			// create object in parent window scope to ensure it survives this 
			// window being closed, especially on IE
			var jsonNewObject = opener.zenPage.newObject('Object');
			jsonNewObject._class = "Ens.Rule.Model.constraint";
			jsonNewObject.type = "constraint";
			jsonNewObject.name = name;
			jsonNewObject.value = value;
			jsonObject.constraints.push(jsonNewObject);
		}
		opener.zenPage.PROD = this.PROD;
	}
	return true;
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	popupName = this.removePopupSuffix(popupName);
	if ( this.metaData[this.metaDataIndex[popupName]].type == "class" ) {
		value = value.substr(0,value.length-4);
	}
	var text = document.getElementById("text-"+popupName);
	text.value = value;
	this.textChanged(text);
	return;
}

ClientMethod getMetaData() [ Language = javascript ]
{
	var metaString = this.ServerGetMetaData(this.ASSIST);
	var metaArray = metaString.split(",");
	this.metaData = new Array();
	this.metaDataIndex = new Object;
	for ( var i=0 ; i<metaArray.length ; i++ ) {
		var array = metaArray[i].split(":");
		this.metaData[i] = new Object;
		this.metaData[i].name = array[0];
		this.metaData[i].caption = array[1];
		var type = array[2].split("#");
		this.metaData[i].repeat = type[0];
		this.metaData[i].type = type[1];
		this.metaData[i].param = type[2]==undefined?this.metaData[i].name:type[2];
		if ( this.metaData[i].repeat == "commalist" ) {
			this.metaData[i].control = "list";
		} else if ( this.metaData[i].type == "query" ) {
			this.metaData[i].control = "combo";
		} else {
			this.metaData[i].control = "text";
		}
		this.metaDataIndex[this.metaData[i].name]=i;
	}
	return;
}

ClassMethod ServerGetMetaData(pClassname As %String) As %String [ ZenMethod ]
{
	quit $classmethod(pClassname,"GetMetaData")
}

ClientMethod getQueryData(param) [ Language = javascript ]
{
	var proxy = new zenProxy();
	for ( var i=0 ; i<this.metaData.length ; i++ ) {
		proxy[this.metaData[i].name] = this.getControlValue(this.metaData[i].name);
	}
	return this.ServerGetQueryData(this.ASSIST, proxy, param);
}

ClassMethod ServerGetQueryData(pClassname As %String, pProxy As %ZEN.proxyObject, pParam As %String) As %String [ ZenMethod ]
{
	do pProxy.%CopyToArray(.tArray)
	quit $classmethod(pClassname,"GetQueryData",.tArray,$g(pParam))
}

}
