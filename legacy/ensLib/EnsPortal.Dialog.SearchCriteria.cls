/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.SearchCriteria Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MessageHeader:USE";

Parameter APPLYBUTTON = 0;

Property propType As %ZEN.Datatype.string(VALUELIST = ",Header,Body,SearchTable,VDocSegment,VDocPath,OR", ZENURL = "PROPTYPE") [ InitialExpression = "Header" ];

Property propClass As %ZEN.Datatype.className(ZENURL = "PROPCLASS");

Property headerClass As %ZEN.Datatype.className [ InitialExpression = "Ens.MessageHeader" ];

Property critDisabled As %ZEN.Datatype.boolean(ZENURL = "DISABLED") [ InitialExpression = 0 ];

Property tipRemoveCondition As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Remove this condition")} ];

Property tipAddCondition As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Add a condition")} ];

Property tipRemoveValue As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Remove this value")} ];

Property tipAddValue As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Add a display value")} ];

Property tipHelp As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Display message search help")} ];

XData Style
{
<style type="text/css">
.joinDiv {
	min-width: 70px;
	text-align: center;
}
.conditionLabel {
	color: #404040;
	font-size: 0.95em;
	font-weight: bold;
}
.conditionRow {
	background: #FFFFEE;
	border: 1px solid gray;
	padding: 1px;
	border-radius: 6px;
}
.selectorImageDiv {
	background: lightgray;
	display: inline;
	border: 1px solid gray;
	border-radius: 4px;
	vertical-align: text-top;
}
.selectorIcon {
	vertical-align: text-top;
	margin-top: 1px;
	width: 18px;
	height: 18px;
}
.selectorItem {
	display: block;
	color: #404040;
	text-decoration: none;
	font-size: 0.8em;
	padding: 2px;
	cursor: default;
}
.selectorItem:hover {
	color: white;
	background: #316AC5;
}
.selectorItem.noResults {
	color: #999999;
	font-style: italic;
}
.selectorModalDiv {
	background: white;
	overflow: hidden;
	overflow-y: auto;
	border: 1px solid gray;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" labelPosition="left" align="center">
<hgroup width="100%">
<checkbox label="Enable Criterion" labelClass="zenLabel" id="critEnabled" onchange="zenPage.changeEnabled(zenThis.value);" title="Enable or disable this criterion and all of the following conditions" />
<spacer width="10" />
<select label="Criterion Type" labelClass="zenLabel" id="typeSelect" showEmpty="false" onchange="zenPage.changePropType(zenThis.value);"
valueList="Header,Body,SearchTable,VDocSegment,VDocPath,OR" 
displayList="Header Field,Body Property,SearchTable Field,VDoc Segment Field,VDoc Property Path,OR" title="Select the criterion type" />
<spacer width="10" />
<html id="classSelectorDiv" label="Class" labelClass="zenLabel" title="Select the class to use in conditions" />
</hgroup>
<spacer height="10" />
<vgroup id="conditionPane">
<hgroup>
<label label="Conditions" controlClass="conditionLabel" />
<spacer width="20" />
<html id="imgDiv"><a href="#" onclick="zenPage.addCondition(true); return false;"><img src="deepsee/add_24.png" height="24px" width="24px" title="#(%page.tipAddCondition)#" /></a></html>
<spacer width="10" />
<html id="imgHelp"><a href="#" onclick="zenPage.showHelp(); return false;"><img src="deepsee/help_24.png" height="24px" width="24px" title="#(%page.tipHelp)#" /></a></html>
</hgroup>
<html id="conditionsGroup" />
</vgroup>
<spacer height="30" />
<vgroup id="displayPane">
<hgroup>
<label label="Display Values" controlClass="conditionLabel" />
<spacer width="20" />
<html id="imgDisplayDiv"><a href="#" onclick="zenPage.addCondition(true,true); return false;"><img src="deepsee/add_24.png" height="24px" width="24px" title="#(%page.tipAddValue)#" /></a></html>
<spacer width="10" />
<html id="imgDisplayHelp"><a href="#" onclick="zenPage.showHelp(); return false;"><img src="deepsee/help_24.png" height="24px" width="24px" title="#(%page.tipHelp)#" /></a></html>
</hgroup>
<html id="displayGroup" />
</vgroup>
</pane>
}

/// Insert the criteria into the parent's Filter object.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var filter = this.getOpener().zenPage.getFilter();
	var term = filter.Terms[filter._currentCriterion];
	term.Type = zenPage.propType;
	term.SourceClass = zenPage.propClass;
	term.Conditions = zenPage._conditions;
	term.Disabled = zenPage.critDisabled;
	return !!this._changed;
}

/// Open the search filter documentation in a new window .
ClientMethod showHelp() [ Language = javascript ]
{
	var helpURL = this.GetHelpURL();
	window.open(helpURL);
}

/// Return a link to the search filter documentation.
/// We use <method>Link</method> to ensure we include the server prefix.
ClassMethod GetHelpURL() As %String [ ZenMethod ]
{
	Quit ..Link("/csp/docbook/DocBook.UI.Page.zen?KEY=EMONITOR_message#EMONITOR_message_filter")
}

/// Add a Condition to the current Term.
/// <var>draw</var> indicates whether the conditions should be redrawn.
ClientMethod addCondition(draw, displayOnly) [ Language = javascript ]
{
	this._changed = true;
	if (zenPage.propType == 'OR') {
		alert($$$Text('An OR criterion may not contain conditions'));
	}
	else {
		var condition = this.getOpener().zenPage.createCondition(null,null,null,null,displayOnly);
		zenPage._conditions.push(condition);
	}
	if (draw) {
		zenPage.drawConditions();
	}
}

/// Remove a condition from the local conditions list.
ClientMethod removeCondition(index) [ Language = javascript ]
{
	if (zenPage._conditions[index]) {
		this._changed = true;
		var old = zenPage._conditions.splice(index, 1);
		zenPage.drawConditions();
	}
}

/// Helper method to load a finder dialog for picking VDoc information.
/// <var>type</var> specifies the property type, which should be either 'VDocPath' or 'VDocSegment'.
/// <var>position</var> indicates whether it is the first or second part of the property.
/// <var>condition</var> is the index of the condition being changed.
ClientMethod showFinder(type, position, condition) [ Language = javascript ]
{
	if (zenPage.propClass == '') {
		alert($$$Text('Please select a Virtual Document class.'));
		return;
	}
	var mode = '';
	switch (type) {
		case 'VDocSegment':
			mode = (position == 1 ? 'vdocsegtype' : 'vdocsegcontents');
			break;
		case 'VDocPath':
			mode = (position == 1 ? 'vdoctype' : 'vdoccontents');
			break;
	}
	
	var parms = {
		MODE: mode,
		CATEGORY: zenPage.propClass
	};
	if ((mode == 'vdoccontents') || (mode == 'vdocsegcontents')) {
		var currEl = document.getElementById('cond_'+condition+'_Val_1');
		var currVal = (currEl ? currEl.value : '');
		if ((position == 2) && ((currVal == '') || (currVal == ':'))) {
			var msg = '';
			if (mode == 'vdocsegcontents') {
				msg = $$$Text('Please select a Segment Type first');
			}
			else if (mode == 'vdoccontents') {
				msg = $$$Text('Please select a DocType first');
			}
			if (msg != '') {
				alert(msg);
				return;
			}
		}
		parms.CATEGORY = parms.CATEGORY + '|' + currVal;
	}
	zenPage._current = {
		index: condition, 
		position: position
	};
	
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix(type),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Render the current list of conditions on the client.
ClientMethod drawConditions() [ Language = javascript ]
{
	var condHTML = [];
	var displayHTML = [];
	
	var displayCount = 0;
	var condCount = 0;

	condHTML.push('<table>');
	displayHTML.push('<table>');
	for (var index = 0; index < zenPage._conditions.length; index++) {
		var condition = zenPage._conditions[index];
		
		var targetArray = null;
		if (condition.DisplayOnly) {
			targetArray = displayHTML;
		}
		else {
			targetArray = condHTML;
		}
		
		targetArray.push('<tr><td>');
		targetArray.push('<div id="cond_'+index+'" class="conditionRow">');
		targetArray.push('<table><tr>');
		
		if (condition.DisplayOnly) {
			displayCount++;
		}
		else {
			condCount++;
			
			targetArray.push('<td id="join_'+index+'" class="joinDiv">')
			if (condCount == 1) {
				condition.JoinOp = 'IF';
				targetArray.push('<span class="zenLabel">IF</span>');
			}
			else {
				if (condition.JoinOp == 'IF') {
					condition.JoinOp = 'AND';
				}
				targetArray.push('<select id="joinSelect_'+index+'" onchange="zenPage.changeCondition('+index+',\'JoinOp\',this.value);" title="'+$$$Text('Select a join type')+'">' + zenPage.getJoins(true, condition.JoinOp) + '</select>');
			}
			targetArray.push('</td>');
		}
		
		if ((this.propType == 'VDocSegment') || (this.propType == 'VDocPath')) {
			targetArray.push('<td class="group">');
			targetArray.push('<div class="conditionRow">');
			targetArray.push('<table>');
			targetArray.push('<tr>');
			var braces = (this.propType == 'VDocSegment' ? { open: '[', close: ']' } : { open: '{', close: '}' });
			
			var firstBrace = condition.Prop.indexOf(braces.open);
			var secondBrace = condition.Prop.indexOf(braces.close);
			var value1 = condition.Prop.substring(0, firstBrace - 1);
			var value2 = condition.Prop.substring(firstBrace + 1, secondBrace);

			if (this.propType == 'VDocSegment') {
				// Segment path uses <schema>:[<seg_name>:<field_path>] format, 
				// but the user picks <schema>:<seg_name> first
				if (value2 != '') {
					var valarray = value2.split(':');
					value1 += ':' + valarray.splice(0,1);
					value2 = valarray.join(':');
				}
			}
			
			var propLabel1 = '';
			switch (this.propType) {
				case 'VDocSegment':
					propLabel1 = $$$Text('Segment Type');
					break;
				case 'VDocPath':
					propLabel1 = $$$Text('DocType');
					break;
			}
			targetArray.push('<td><span class="zenLabel">'+propLabel1+'</span></td>');
			targetArray.push('<td><input type="text" id="cond_'+index+'_Val_1" onchange="zenPage.updateVDocValues('+index+');" value="'+value1+'"></input></td>');
			targetArray.push('<td><img src="deepsee/zoom_16.png" onclick="zenPage.showFinder(\''+this.propType+'\',1,'+index+');" style="cursor: pointer;"></img></td>');
			targetArray.push('</tr><tr>');

			var propLabel2 = '';
			switch (this.propType) {
				case 'VDocSegment':
					propLabel2 = $$$Text('Field Name');
					break;
				case 'VDocPath':
					propLabel2 = $$$Text('Property Path');
					break;
			}
			targetArray.push('<td><span class="zenLabel">'+propLabel2+'</span></td>');
			targetArray.push('<td><input type="text" id="cond_'+index+'_Val_2" onchange="zenPage.updateVDocValues('+index+');" value="'+value2+'"></input></td>');

			targetArray.push('<td><img src="deepsee/zoom_16.png" onclick="zenPage.showFinder(\''+this.propType+'\',2,'+index+');" style="cursor: pointer;"></img></td>');
			targetArray.push('</tr>');
			targetArray.push('</table>');
			targetArray.push('</div>');
			targetArray.push('</td>');
		}
		else { // draw a selector
			targetArray.push('<td>');
			this.drawSelector(targetArray,'prop_'+index,condition.Prop,'zenPage.changeCondition('+index+',\'Prop\',this.value);',30,$$$Text('Select a property'));
			targetArray.push('</td>');
		}
		if (!condition.DisplayOnly) {
			targetArray.push('<td>');
			targetArray.push('<select id="opSelect_'+index+'" onchange="zenPage.changeCondition('+index+',\'Op\',this.value);" title="'+$$$Text('Select an operator')+'">' + zenPage.getOperators(true, condition.Op) + '</select>');
			targetArray.push('</td>');
	
			targetArray.push('<td>');
			targetArray.push('<input type="text" id="val_'+index+'" onchange="zenPage.changeCondition('+index+',\'OpVal\',this.value);" title="'+$$$Text('Type in a value')+'" value="'+condition.OpVal+'"/>')
			targetArray.push('</td>');
		}
		targetArray.push('<td>');
		targetArray.push('<img width="16px" src="deepsee/close_a_16.png" title="'+ this.tipRemoveCondition + '" onclick="zenPage.removeCondition('+index+');" />');
		targetArray.push('</td>');
		targetArray.push('</tr></table>');
		targetArray.push('</div>');
		targetArray.push('</td></tr>');
	}
	condHTML.push('</table>');
	displayHTML.push('</table>');
	zen('conditionsGroup').setProperty('content',condHTML.join(''));
	zen('displayGroup').setProperty('content',displayHTML.join(''));
}

/// Wrapper method around %ZEN.Portal.ContextSearch which ensures that we avoid using
/// search keys. It returns the results to the client in <class>%ZEN.proxyObject</class> instances.
ClassMethod GetOptions(pContextSearch As %String, pParms As %ZEN.proxyObject, pTopOptions As %ZEN.proxyObject, pOptions As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tContext = pContextSearch
	Do pTopOptions.%Clear()
	Do pOptions.%Clear()
	Do pParms.%CopyToArray(.tParms)
	Set tParmCount = 0
	Set tParm = ""
	For {
		Set tParm = $order(tParms(tParm))
		Quit:(tParm = "")
		Set tParmCount = tParmCount + 1
		Set tContext = tContext _ $select(tParmCount = 1: "?", 1: "&") _ tParm _ "=" _ $get(tParms(tParm))
	}
	
	Set tSC = ##class(%ZEN.Portal.ContextSearch).%Search(,.tTopResults,.tResults,tContext,"")
	If $$$ISERR(tSC) Quit $system.Status.GetErrorText(tSC)
	Set tTopCount = 0
	Set tKey = ""
	For {
		Set tKey = $order(tTopResults(tKey))
		Quit:(tKey = "")
		Set tTopCount = tTopCount + 1
		Set $property(pTopOptions,"result"_tTopCount) = $zcvt($get(tTopResults(tKey)),"O","HTML")
	}
	Set pTopOptions.resultCount = tTopCount
	Set tCount = 0
	Set tKey = ""
	For {
		Set tKey = $order(tResults(tKey))
		Quit:(tKey = "")
		Set tCount = tCount + 1
		Set $property(pOptions,"result"_tCount) = $zcvt($get(tResults(tKey)),"O","HTML")
	}
	Set pOptions.resultCount = tCount
	Quit ""
}

/// Utility method to change properties of the local conditions.
/// <var>index</var> is the index of the condition;
/// <var>property</var> is the name of the property;
/// <var>newVal</var> is the new value.
ClientMethod changeCondition(index, property, newVal) [ Language = javascript ]
{
	var condition = zenPage._conditions[index];
	if (condition) {
		condition[property] = newVal;
		this._changed = true;
	}
	return true;
}

/// Method to reinitialize the local conditions list and display when the
/// property type is changed.
/// <var>newVal</var> is the new property type.
ClientMethod changePropType(newVal) [ Language = javascript ]
{
	this._changed = true;
	this.propType = newVal;
	this.propClass = (this.propType == 'Header' ? this.headerClass : '');
	this.drawClassSelector();
	
	this._conditions = this.getOpener().zenPage.createArray();
	this.addCondition(true);
}

/// Method to reinitialise the conditions when the class type is changed.
/// <var>newVal</var> is the new class name.
ClientMethod changeClass(newVal) [ Language = javascript ]
{
	this._changed = true;
	this.propClass = newVal;
	if ((this.propType != 'VDocSegment') && (this.propType != 'VDocPath')) {
		this.drawConditions();
	}
}

ClientMethod changeEnabled(newVal) [ Language = javascript ]
{
	this._changed = true;
	this.critDisabled = !newVal;
}

/// Rebuild the local Condition array based on the Conditions in the Message Viewer window.
/// Note that the local array contains clones of the parent data to ensure that discarded changes
/// don't affect the original values.
ClientMethod buildConditionArray() [ Language = javascript ]
{
	zenPage._conditions = new Array();
	
	if (zenPage.propType == 'OR') { // no conditions
		return;
	}
	
	var criterion = null;
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage.getFilter) {
	 	var filter = opener.zenPage.getFilter();
	 	var index = filter._currentCriterion;
	 	criterion = filter.Terms[index];
	 	criterion = filter._zenRoot.clone(criterion);
	 	if (criterion) {
		 	zenPage._conditions = criterion.Conditions;
		}
	}
}

/// Helper method to create an HTML-based selector component which behaves much like
/// the core <class>%ZEN.Portal.selector</class> component.
ClientMethod drawSelector(htmlArray, inputId, value, onchange, size, title) [ Language = javascript ]
{
	size = (!size ? 30 : size);
	title = (!title ? '' : title);
	var style = (zenIsIE ? ' style="vertical-align: top;"' : '');
	htmlArray.push('<div class="selectorDiv" title="'+title+'">');
	htmlArray.push('<input type="text" id="'+inputId+'" size="'+size+'" value="'+value+'" onchange="'+onchange+'" title="'+title+'" />');
	htmlArray.push('<div class="selectorImageDiv"' + style + '><img class="selectorIcon"' + style + ' src="portal/disc_down.gif" onclick="zenPage.showOptions(\''+inputId+'\');" /></div>');
	htmlArray.push('<div id="'+inputId+'Options" class="selectorModalDiv" style="display: none;" />');
	htmlArray.push('</div>');
}

/// Helper method to draw the class selection component, which is generally an
/// "HTML-selector", but may also be a disabled text box when we are performing a Header search.
ClientMethod drawClassSelector() [ Language = javascript ]
{
	var selectDiv = zen('classSelectorDiv');
	var selectHTML = [];
	if ((this.propType == 'Header') || (this.propType == 'OR')) {
		var val = (this.propClass == '' ? '&nbsp;' : this.propClass);
		selectHTML.push('<input type="text" id="classSelector" disabled="1" value="'+this.propClass+'" />');
	}
	else if (this.propType != '') {
		this.drawSelector(selectHTML,'classSelector',this.propClass,'zenPage.changeClass(this.value);',40,$$$Text('Select the class to use in conditions'));
	}
	selectDiv.setProperty('content', selectHTML.join(''));
}

/// Helper method to ensure that all selector modals are hidden.
ClientMethod hideAllOptions(checkVisible) [ Language = javascript ]
{
	if (!this._visibleOptions) this._visibleOptions = { "counter": 0 };
	var wasVisible = false;
	if (this._visibleOptions.counter > 0) {
		for (var optName in this._visibleOptions) {
			if ((optName != 'counter') && this._visibleOptions[optName]) {
				if (optName == checkVisible) wasVisible = true;
				this.hideOptions(optName);
			}
		}
	}
	return wasVisible;
}

/// Display the options for a selector based on the name of the input
/// control passed in <var>inputName</var>. This also hides all other
/// visible selector modals, and will hide this control if it was already visible.
/// The method will also check whether we have enough information to
/// fetch the contents. If not, we report an error and return.
ClientMethod showOptions(inputName) [ Language = javascript ]
{
	if (!this._visibleOptions) this._visibleOptions = { "counter": 0 };
	var wasVisible = false;
	if (this.hideAllOptions(inputName)) { return; }
	// block resize events when we are in IE8
	this._preventResize = zenIsIE && !zenIsHTML5;
	
	var search = null;
	var searchParms = new zenProxy();
	if (inputName == 'classSelector') {
		switch (this.propType) {
			case 'Body':
				search = 'Ens/Classes';
				searchParms.system = 1;
				searchParms["super"] = 'Ens.Util.MessageBodyMethods';
				searchParms.hideAbstract = 1;
				searchParms.classtype = 'persistent';
				break;
			case 'SearchTable':
				search = 'Ens/Classes';
				searchParms.system = 1;
				searchParms["super"] = 'Ens.SearchTableBase';
				searchParms.hideAbstract = 1;
				break;
			case 'VDocSegment':
				searchParms.segmented = 1; // note that VDocSegment also uses VDocClasses
			case 'VDocPath':
				search = 'Ens/VDocClasses';
				break;
		}
	}
	else if (inputName.substring(0,4) == 'prop') {
		if (this.propClass != '') {
			switch (this.propType) {
				case 'Header':
				case 'Body':
					search = 'Ens/MessageProperties';
					searchParms.sqlFields = 1;
					searchParms["class"] = this.propClass;
					break;
				case 'SearchTable':
					search = 'Ens/SearchTableProperties';
					searchParms.searchTable = this.propClass;
					break;
			}
		}
		else {
			alert($$$Text('Please select a class first.'));
			return;
		}
	}
	
	if (search && (inputName.length > 0)) {
		// set up mouse trap
		var mouseTrap = document.getElementById('zenMouseTrap');
		
		mouseTrap.onmouseup = function() { zenPage.hideAllOptions(); };
		mouseTrap.style.zIndex = 100;
		mouseTrap.style.width = document.body.clientWidth + 'px';
		mouseTrap.style.height = document.body.clientHeight + 'px';
		mouseTrap.style.position = 'absolute';
		mouseTrap.style.top = '0px';
		mouseTrap.style.left = '0px';
		mouseTrap.style.background = '';
		
		var modalDiv = document.getElementById('zenModalDiv');
		var inputCtrl = document.getElementById(inputName);
		var currValue = inputCtrl.value;
		if (currValue == null) currValue = '';
		currValue = zenEscapeHTML(currValue);
		
		var top = zenGetTop(inputCtrl) + inputCtrl.offsetHeight - zenGetTopScroll(inputCtrl);
		var left = zenGetLeft(inputCtrl) - zenGetLeftScroll(inputCtrl);
	
		modalDiv.style.position = 'absolute';
		modalDiv.style.top = top + 'px';
		modalDiv.style.left = left + 'px';
		mouseTrap.style.display = '';
		
		var modalHTML = [];
		modalHTML.push('<div id="selectorModalDiv" class="selectorModalDiv" title="'+inputCtrl.title+'">');
		
		var topOptions = new zenProxy();
		var options = new zenProxy();
		var ok = this.GetOptions(search,searchParms,topOptions,options);
		if (ok != '') {
			modalHTML.push('<a class="selectorItem" href="#" onclick="zenPage.pickOption(\''+inputName+'\',-1); return false;">' + $$$Text('Error retrieving options from server.') + '<br/>' + ok + '</a>');
		}
		else {
			var topCount = parseInt(topOptions.resultCount,10);
			var count = parseInt(options.resultCount,10);
			if ((count + topCount) == 0) {
				var errText = '&nbsp;--' + (inputName == 'classSelector' ? $$$Text('No available classes') : $$$Text('No available properties')) + '--&nbsp;';
				modalHTML.push('<a class="selectorItem noResults" href="#" onclick="zenPage.pickOption(\''+inputName+'\',\'\');return false;">'+errText+'</a>');
			}
			else {
				for (var i=1; i <= topCount; i++) {
					if (topOptions['result'+i]) {
						modalHTML.push('<a class="selectorItem" href="#" onclick="zenPage.pickOption(\''+inputName+'\',\''+topOptions['result'+i]+'\');return false;">'+topOptions['result'+i]+'</a>');
					}
				}
				if (topCount > 0) {
					modalHTML.push('<div style="margin-bottom:1px; height:2px; border-bottom:1px solid gray;">&nbsp;</div>');
				}
				for (var i=1; i <= count; i++) {
					if (options['result'+i]) {
						modalHTML.push('<a class="selectorItem" href="#" onclick="zenPage.pickOption(\''+inputName+'\',\''+options['result'+i]+'\');return false;">'+options['result'+i]+'</a>');
					}
				}
			}
		}
		modalHTML.push('</div>');
		modalDiv.innerHTML = modalHTML.join('');
		
		modalDiv.scrollTop = 0;
		modalDiv.style.zIndex = 101;
		modalDiv.style.display = '';
		// resize modal - widen it if possible to avoid being hidden by a vertical scrollbar,
		// but also ensure we don't extend past the currently visible window.
		// For height, limit the size to 250px with scrolling if taller, but leave it if shorter.
		var modalWidth = modalDiv.offsetWidth + 30;
		if (modalWidth < inputCtrl.offsetWidth) modalWidth = inputCtrl.offsetWidth;
		if ((left + modalWidth) > zenGetWindowWidth()) {
			modalWidth = zenGetWindowWidth() - left;
		}
		modalDiv.style.width =  modalWidth + 'px';
		var innerModal = document.getElementById('selectorModalDiv');
		if (innerModal) {
			var modalHeight = innerModal.offsetHeight;
			if (modalHeight > 250) modalHeight = 250;
			innerModal.style.height = modalHeight + 'px';
		}
		this._visibleOptions[inputName] = true;
		this._visibleOptions.counter++;
	}
	setTimeout(function() { zenPage._preventResize = false; }, 100);
}

/// Callback to ensure that we pick up the chosen value and
/// hide the modal div containing the options.
ClientMethod pickOption(inputName, pickedValue) [ Language = javascript ]
{
	var inputCtrl = document.getElementById(inputName);
	if (inputCtrl) {
		inputCtrl.value = pickedValue;
		if (inputCtrl.onchange) {
			inputCtrl.onchange(pickedValue);
		}
	}
	this.hideOptions(inputName);
}

/// Hide the selector modal for a specified input control.
ClientMethod hideOptions(inputName) [ Language = javascript ]
{
	if (!this._visibleOptions) this._visibleOptions = { "counter": 0 };
	var modalDiv = document.getElementById('zenModalDiv');
	if (modalDiv) {
		modalDiv.innerHTML = '';
		modalDiv.style.display = 'none';
		modalDiv.style.width = '';
		modalDiv.style.position = '';
		modalDiv.style.zIndex = '';
		modalDiv.style.top = '0px';
		modalDiv.style.left = '0px';
		modalDiv.title = '';
	}
	var mouseTrap = document.getElementById('zenMouseTrap');
	if (mouseTrap) {
		mouseTrap.style.display = 'none';
		mouseTrap.style.zIndex = 0;
		mouseTrap.style.width = '';
		mouseTrap.style.height = '';
		mouseTrap.style.position = '';
		mouseTrap.style.top = '';
		mouseTrap.style.left = '';
	}
	this._visibleOptions[inputName] = false;
	this._visibleOptions.counter--;
}

/// Ensure that we hide any modal divs to avoid nasty geometry problems.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	// Ensure that we don't call hideAllOptions() when the resize is triggered from showOptions() (even if indirectly)
	if (!this._preventResize) this.hideAllOptions();
}

/// Ensure that we have been opened from the Message Viewer.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var opener = this.getOpener();
	var stop = false;
	if (!(opener && opener.zenPage && opener.zenPage.Filter)) {
		alert($$$Text('Window must be opened from a message viewer'));
		stop = true;
	}
	if (!stop && !(opener && opener.zenPage && opener.zenPage.headerClass && (opener.zenPage.headerClass == this.headerClass))) {
		alert($$$Text('Window must be opened from the related message viewer'));
		stop = true;
	}
	if (stop) {
		if (this.isSoftModal) {
			if (window.top && window.top.zenPage) window.top.zenPage.endModal();
		}
		else {
			window.close();
		}
		return;
	}
	this.drawClassSelector();
	zenPage.buildConditionArray();
	if ((zenPage._conditions.length == 0) && (zenPage.propType != 'OR')) {
		zenPage.addCondition(false);
	}
	zenPage.drawConditions();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
/// Set a flag to indicate that the changes should be applied.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	if ((action.toUpperCase() == 'OK') || (action.toUpperCase() == 'APPLY')) {
		zenPage._applyChanges = true;
	}
	return true;
}

/// This client method, if defined and the AUTOLOGOUT parameter for this
/// page is true, is invoked when the logout timer for this
/// page fires.<br/>
/// If this method return true then the normal page logout behavior will fire.
/// That is, the page will be reloaded causing a login page to appear if the
/// current session has ended.
ClientMethod onlogoutHandler() [ Language = javascript ]
{
	// Set flag here so that onunloadHandler knows to logout from the parent page too
	zenPage._inAutoLogout = true;
	return true;
}

/// This client event, if present, is fired when the page is unloaded.
/// If this method returns a string value, then that is used as the
/// return value of the HTML page's onbeforeunload handler (if more than
/// one component returns a string, the first one encountered is used).
ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (zenPage._inAutoLogout) {
		var opener = this.getOpener();
		if (opener && opener.zenPage) {
			opener.zenPage.zenAutoLogout();
		}
	}
	else if (!zenPage._applyChanges) {
		var opener = this.getOpener();
		if (opener && opener.zenPage && opener.zenPage.getFilter) {
			var filter = opener.zenPage.getFilter();
			if (filter && filter._newCriterion) {
				filter.Terms.splice(filter._currentCriterion, 1);
			}
		}
	}
}

/// This client event, if present, is fired when a popup page has specified
/// this component as its parent and fires an action.<br>
/// <var>popupName</var> is the name of the popup window sending the action.<br>
/// <var>action</var> is the name of the action.<br>
/// <var>value</var> is the value associated with the action.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	
	var targetId = 'cond_'+this._current.index+'_Val_'+this._current.position;
	var target = document.getElementById(targetId);
	switch (popupName) {
		case 'VDocSegment':
			target.value = value;
			break;
		case 'VDocPath':
			if (value.indexOf('.vdoc') > 0) {
				value = value.split('.vdoc');
				value = value[0];
			}
			target.value = value;
			break;
	};
	zenPage.updateVDocValues(zenPage._current.index);
}

ClientMethod updateVDocValues(index) [ Language = javascript ]
{
	var condition = zenPage._conditions[index];
	var val1 = ''
	var val2 = '';
	var el1 = document.getElementById('cond_'+index+'_Val_1');
	var el2 = document.getElementById('cond_'+index+'_Val_2');
	if (el1) val1 = el1.value;
	if (el2) val2 = el2.value;
	var braces = ['{','}'];
	if (zenPage.propType == 'VDocSegment') {
		braces = ['[',']'];
		var segVal = val1.split(':');
		val1 = segVal[0];
		if (segVal.length > 1) {
			if (val2 != '') {
				val2 = segVal[1] + ':' + val2;
			}
			else {
				val2 = segVal[1];
			}
		}
	}
	var initValue = condition.Prop;
	condition.Prop =  val1 + ':' + braces[0];
	condition.Prop += val2 + braces[1];
	if (initValue != condition.Prop) this._changed = true;
}

/// Return the supported operators in an array.
/// The <var>htmlFormat</var> flag indicates whether the values should
/// be returned as an array of &lt;option&gt; elements.
/// <var>selected</var> contains the value of the currently selected value, if any.
ClientMethod getOperators(htmlFormat, selected) [ Language = javascript ]
{
	var operators = [
		'=', '!=',
		(htmlFormat ? '&gt;' : '>'), (htmlFormat ? '&gt;=' : '>='),
		(htmlFormat ? '&lt;' : '<'), (htmlFormat ? '&lt;=' : '<='),
		'Contains', 'DoesNotContain',
		'In', 'NotIn',
		'StartsWith', 'DoesNotStartWith',
		'Like', 'NotLike',
		'Matches', 'DoesNotMatch',
		'InFile', 'NotInFile'
	];
	if (!htmlFormat) {
		return operators;
	}
	var html = '';
	selected = (selected != null ? zenEscapeHTML(selected) : '');
	var selText = '';
	for (var i = 0; i < operators.length; i++) {
		selText = (selected == operators[i] ? ' selected' : '');
		html += '<option value="' + operators[i] + '"' + selText + '>' + operators[i] + '</option>';
	}
	return html;
}

/// Return the supported joins in an array.
/// The <var>htmlFormat</var> flag indicates whether the values should
/// be returned as an array of &lt;option&gt; elements.
/// <var>selected</var> contains the value of the currently selected value, if any.
ClientMethod getJoins(htmlFormat, selected) [ Language = javascript ]
{
	var joins = [ 'AND', 'OR' ];
	if (!htmlFormat) {
		return joins;
	}
	var html = '';
	selected = (selected != null ? selected : '');
	var selText = '';
	for (var i = 0; i < joins.length; i++) {
		selText = (selected == joins[i] ? ' selected' : '');
		html += '<option value="' + joins[i] + '"' + selText +'>' + joins[i] + '</option>';
	}
	return html;
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Search Criteria")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Create and edit advanced message search criteria")
}

Method %OnAfterCreatePage() As %Status
{
	If (..propType = "Header") {
		Set ..propClass = ..headerClass
	}
	ElseIf (..propType = "OR") {
		Set tConditions = ..%GetComponentById("conditionPane")
		Set tConditions.disabled = 1
	}
	
	Set tTypeSelect = ..%GetComponentById("typeSelect")
	If $IsObject(tTypeSelect) {
		Set tTypeSelect.value = ..propType
	}
	
	Do ..%SetValueById("critEnabled",'..critDisabled)
	Quit ##super()
}

/// Adjust size and position of components on this page, provided resize handling is not disabled.
ClientMethod adjustSize() [ Language = javascript ]
{
	if (!this._preventResize) this.invokeSuper('adjustSize',arguments);
}

}
