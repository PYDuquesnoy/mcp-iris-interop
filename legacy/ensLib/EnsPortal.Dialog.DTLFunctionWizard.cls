/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.DTLFunctionWizard Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Data Transform Function Wizard";

/// User needs READ permissions on either the %Ens_Code or the %Ens_DTL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_DTL:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_DTL resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_DTL:WRITE";

Parameter APPLYBUTTON = 0;

Property isReplace As %ZEN.Datatype.boolean(ZENURL = "EDIT");

XData Style
{
<style type="text/css">
.funcDesc {
	border: 1px solid gray;
	padding-right: 2px;
	background: #F0F0F0;
}
.descriptionText {
	font-size: 0.9em;
	display: inline-block;
	padding: 3px;
	color: #404080;
}
.descriptionText var {
	font-weight: bold;
}
.expression {
	border: 1px solid gray;
	padding-right: 2px;
	background: #F0F0F0;
}
.expressionText {
	color: #404080;
	font-size: 0.8em;
	display: inline-block;
	word-wrap: break-word;
	padding: 3px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<jsonProvider id="functionList" OnRenderJSON="GetFunctions" />

<hgroup cellVAlign="top">
<select label="Function" id="functionSelect" onchange="zenPage.drawArguments(zenThis.getValue());" />
<spacer width="30" />
<checkbox id="isReplace" label="Replace Function" title="Replace outermost function" enclosingStyle="padding-right: 10px;" onchange="zenPage.replaceChanged(zenThis.getValue());" />
</hgroup>
<spacer height="5"/>
<vgroup>
<label id="currExpressionLbl" label="Current Expression" enclosingStyle="padding: 1px;"/>
<label id="currExpression" enclosingClass="expression" controlClass="expressionText" />
<label id="functionHint" enclosingClass="zenHint" value="Select a function for more information" />
</vgroup>
<vgroup id="lookupGroup" cellStyle="padding-top: 5px;" hidden="true">
<select id="lookupTables" label="table" onchange="zenPage.argChanged(0,true);" />
</vgroup>
<vgroup id="argGroup" cellStyle="padding-top: 5px;" >
</vgroup>
<spacer height="5"/>
<vgroup id="functionDescGroup" hidden="true">
<label id="functionDescLbl" label="Function Description" enclosingStyle="padding: 1px;"/>
<html id="functionDescription" enclosingClass="funcDesc descriptionText"/>
</vgroup>

</pane>
}

/// Helper method to get the object tree of defined functions.
ClientMethod getFunctionList() [ Language = javascript ]
{
	return zen('functionList').getContentObject();
}

/// Draw the controls for the arguments of the function named in <var>functionDesc</var>.
/// This method is called as an event handler when a new function is chosen and from <method>ondialogStart</method>,
/// where the <var>noExpressionUpdate</var> argument is used to ensure we only update the expression once.
ClientMethod drawArguments(functionDesc, noExpressionUpdate) [ Language = javascript ]
{
	if (functionDesc == "Repeat Current Function") functionDesc = this._allExpressions.currEx;
	if ((!functionDesc) ||(functionDesc == '')||(functionDesc == '.')) {
		zen('functionHint').setHidden(false);
		zen('functionDescGroup').setHidden(true);
		zen('lookupGroup').setHidden(true);
		zen('argGroup').setHidden(true);
		this._allExpressions.currEx = '.';
		if (this.isReplace) {
			var oldArgLength = this._currentExpression.argList.length;
			var valuePos = (this._allExpressions.valPos!='undefined') ? this._allExpressions.valPos : 0;
			
			for (var i = 0; i < oldArgLength; i++) {
				if (i+5-valuePos >= 0) {
					this._allExpressions.argList[i+5-valuePos] = this._currentExpression.argList[i];
				}
			}

			var fullEx = (this._currentExpression.argList && this._currentExpression.argList[valuePos]!='undefined') ? this._currentExpression.argList[valuePos] :'';
			this._currentExpression.fullExpression = fullEx?fullEx : '';
			zen('currExpression').setValue(fullEx?fullEx:'');
			
			if (fullEx && fullEx != '') {
				this._currentExpression = this.parseExpression(this._currentExpression.fullExpression,true);
				
				if (this._currentExpression) {
					var fullFunction = this._currentExpression.functionClass + '.' + this._currentExpression.functionName;
					this._allExpressions.currEx = fullFunction;
					var valPos = 0;
					if (this._currentExpression.functionClass !='') {
						var functionList = this.getFunctionList();
						var funcData = functionList[fullFunction];
						if (funcData && (typeof funcData.valuePos != 'undefined') && (funcData.valuePos >= 0)) {
							valPos = funcData.valuePos;
						}
					}
					this._allExpressions.valPos = valPos;
					if (funcData) zen('functionSelect').setValue(fullFunction);
					this.drawArguments(fullFunction,true);
				}
			}
		}
	}
	else {
		zen('argGroup').setHidden(false);
		var functionList = this.getFunctionList();
		var delayed = [];
		if (functionList && functionList[functionDesc]) {
			var nameArray = functionDesc.split('.');
			var functionName = nameArray.pop();
			var functionClass = nameArray.join('.');
			if (!noExpressionUpdate) {
				// if no expression update should happen, don't redraw
				if (!this.updateExpression(functionClass, functionName)) {
					return;
				}
			}
			var argGroup = zen('argGroup');
			var tableGroup = zen('lookupGroup');
			tableGroup.setHidden(true);
			var table = zen('lookupTables');
			table.setValue('');
			while (argGroup.children.length > 0) {
				var child = argGroup.children[0];
				if (child) {
					var sync = zenPage.deleteComponent(child, false, true);
					argGroup.children.splice(0,1);
				}
			}
			
			var functionObj = functionList[functionDesc];
			zen('functionDescription').setProperty('content',functionObj.description);
			var argCount = functionObj.argSpec.length;
			for (var i=0; i<argCount; i++) {
				var argDef = functionObj.argSpec[i];
				if (argDef.isLookup) {
					tableGroup.setHidden(false);
					if (this._currentExpression && this._currentExpression.argList && (this._currentExpression.argList.length > 0)) {
						table.setValue(this._currentExpression.argList[0]);
					}
				}
				else {
					var control = this.createComponent(argDef.controlType);
					control.setProperty('id','arg'+(i+1));
					if (argDef.controlType == 'text') {
						control.setProperty('size', 40);
					}
					if (argDef.defaultValue != '') {
						control.setProperty('hint', $$$FormatText('Default value: %1', argDef.defaultValue));
					}
					var label = argDef.name + ' ' + (argDef.optional ? '['+$$$Text('Optional')+']' : '');
					control.setProperty('label', label);
					if (this._currentExpression && this._currentExpression.argList && (this._currentExpression.argList.length > i)) {
						control.setValue(this._currentExpression.argList[i]);
					}
					control.setProperty('onchange', 'zenPage.argChanged('+(i+1)+');');
					argGroup.addChild(control, false);
				}
			}
			var sync = argGroup.refreshContents(true);
		}
		zen('functionHint').setHidden(true);
		if (zen('functionDescription').getProperty('content') != '') {
			zen('functionDescGroup').setHidden(false);
		}
		else {
			zen('functionDescGroup').setHidden(true);
		}
	}
	this.resizeTextControls();
}

/// Update the isReplace variable when the control is changed.
ClientMethod replaceChanged(newValue) [ Language = javascript ]
{
	zenPage.isReplace = newValue;
}

/// Event handler to update the current expression whenever an argument is changed.
ClientMethod argChanged(index, isLookup) [ Language = javascript ]
{
	if (!(this._currentExpression && this._currentExpression.argList && (this._currentExpression.argList.length > 0))) { return; }
	if (isLookup) {
		this._currentExpression.argList[0] = zen('lookupTables').getValue();
	}
	else if (this._currentExpression.argList.length >= index) {
		var newValue = zen('arg'+index).getValue();
		this._currentExpression.argList[index - 1] = newValue;
	}
	this.updateExpression();
}

ClassMethod GetFunctions(ByRef pParameters) As %Status
{
	Set tStatus = ##class(Ens.Rule.Utils).GetFunctionSet(.tFuncs)
	If $$$ISERR(tStatus) Quit tStatus
	
	Write "{",!
	
	Set tIsFirst = 1
	Set tUpName = ""
	For {
		Set tUpName = $order(tFuncs(tUpName))
		Quit:(tUpName = "")
		Set tClassName = $listget(tFuncs(tUpName), 1)
		Set tFunctionName = $listget(tFuncs(tUpName), 2)
		Set tSpec = $listget(tFuncs(tUpName), 3)
		
		If tIsFirst { Set tIsFirst = 0 }
		Else { Write ",",! }
		Write "'"_tClassName_"."_tFunctionName_"': { "
		Write !,"description:'"_$zconvert($$$comMemberKeyGet(tClassName,$$$cCLASSmethod,tFunctionName,$$$cMETHdescription),"O","JS")_"'"
		Write !,",argSpec: ["
		Set tValuePos = 0
		For i=1:1:$listlength(tSpec) {
			Set tCurrSpec = $listget(tSpec, i)
			If i>1 {
				Write ","
			}
			#Define CurrName	$listget(tCurrSpec, 1)
			#Define CurrType	$listget(tCurrSpec, 2)
			#Define CurrDefVal	$listget(tCurrSpec, 4)
			
			Set tJSType = "text"
			Set tIsLookup = ((tClassName = "Ens.Rule.FunctionSet") || (tClassName = "Ens.Util.FunctionSet")) && ((tFunctionName = "Lookup") || (tFunctionName = "Exists"))
			Set tIsLookup = tIsLookup && ($$$CurrName = "table")
			If tIsLookup && (tJSType = "text") {
				Set tJSType = "select"
			}
			If ($$$CurrName = "value") && 'tValuePos {
				Set tValuePos = i
			}
			
			Write "{"
			Write "name:'"_$zconvert($$$CurrName,"O","JS")_"'"
			Write ",controlType:'"_$zconvert(tJSType,"O","JS")_"'"
			Write ",defaultValue:'"_$zconvert($$$CurrDefVal,"O","JS")_"'"
			Write ",optional:"_$select(($$$CurrName '= "value") && ($$$CurrDefVal '= "") && 'tIsLookup : "true", 1: "false")
			Write ",isLookup:"_$select(tIsLookup: "true", 1: "false")
			Write "}"
		}
		Write "]"
		Write !,",valuePos:"_(tValuePos - 1)_"}"
	}
	Write "};",!
	
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tFuncSel = ..%GetComponentById("functionSelect")
	
	Set tStatus = ##class(Ens.Rule.Utils).GetFunctionSet(.tFuncs)
	If $$$ISERR(tStatus) Quit tStatus
	Set tUpName = ""
	For {
		Set tUpName = $order(tFuncs(tUpName))
		Quit:(tUpName = "")
		Set tClassName = $listget(tFuncs(tUpName), 1)
		Set tFunctionName = $listget(tFuncs(tUpName), 2)
		
		Set tFuncSel.valueList = tFuncSel.valueList _ ","_tClassName _"."_ tFunctionName
		Set tFuncSel.displayList = tFuncSel.displayList _ ","_tFunctionName_"()"
	}
	Set tFuncSel.valueList = "Repeat Current Function,"_$extract(tFuncSel.valueList, 2, *)
	Set tFuncSel.displayList = "Repeat Current Function,"_$extract(tFuncSel.displayList, 2, *)
	
	Set tTableDisplay = ""
	Set tTableList = ""
	Set tTable = ""
	For {
		Set tTable = $order(^Ens.LookupTable(tTable))
		Quit:(tTable = "")
		Set tTableList = tTableList _ ",""" _ tTable _ """"
		Set tTableDisplay = tTableDisplay _ "," _ tTable
	}
	Set tLookupTables = ..%GetComponentById("lookupTables")
	Set tLookupTables.displayList = $extract(tTableDisplay, 2, *)
	Set tLookupTables.valueList = $extract(tTableList, 2, *)
	
	If ..isReplace {
		Set tReplace = ..%GetComponentById("isReplace")
		Set tReplace.value = ..isReplace
		Set tReplace.hidden = 0
	}
	Quit $$$OK
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$Text("Add functions to a DTL expression")
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Data Transform Function Wizard")
}

/// Update the expression text displayed at the top of the page.
/// If <var>newClass</var> and <var>newProp</var> are defined, then we initialise the expression as needed.
/// The function should return a boolean to indicate whether the requested update should be processed.
/// The return value will be true in almost all cases, except for a specific case involving function replacement described shortly.
/// If <property>isReplace</property> is true, we replace the current function. As part of the function replacement,
/// we ensure that the expression has the correct number of arguments specified. If the new function has fewer arguments
/// than the user had previously defined, we prompt the user to confirm that they are willing to discard the extra argument(s).
/// If the user indicates that the argument(s) can be discarded, we continue as before. If not, we reset the dropdown and return
/// false, leaving the expression exactly as it is.
ClientMethod updateExpression(newClass, newName) [ Language = javascript ]
{
	if (!this._currentExpression) { return true; }
	var functionList = this.getFunctionList();
	if (newClass && newName) {
		var newFuncData = functionList[newClass +'.'+ newName];
		var newArgCount = (newFuncData && newFuncData.argSpec) ? newFuncData.argSpec.length : 0;
		if (this.isReplace) {
			var oldArgLength = this._currentExpression.argList.length;
			
			// if '...' syntax for final argument of previous function, need to separate out any arguments that got combined into that one argument
			var oldFuncData = functionList[this._currentExpression.functionClass + '.' + this._currentExpression.functionName];
			if (oldFuncData  && oldFuncData.argSpec && (oldFuncData.argSpec.length>0)) {
				var oldLastArgName = oldFuncData.argSpec[oldFuncData.argSpec.length - 1].name;
				if (oldLastArgName.substr(oldLastArgName.length-3,3) === "...") {
					this._currentExpression = zenPage.parseExpression(this._currentExpression.fullExpression);
					oldArgLength = this._currentExpression.argList.length;
				}
			}
			
			var newValPos = 0;
			if (newFuncData && (typeof newFuncData.valuePos != 'undefined') && (newFuncData.valuePos >= 0)) {
				newValPos = newFuncData.valuePos;
			}
			var oldValPos = (this._allExpressions.valPos!='undefined') ? this._allExpressions.valPos : 0;
			
			for (var i = 0; i < oldArgLength; i++) {
				if (i+5-oldValPos >= 0) {
					// keep old arg data in this._allExpressions with args shifted so that subscript 5 contains the value arg
					this._allExpressions.argList[i+5-oldValPos] = this._currentExpression.argList[i];
				}
			}
			
			// if '...' syntax for final argument, don't throw away extra argument values
			if (((newArgCount-newValPos) < (this._allExpressions.argList.length-5)) && newFuncData && newFuncData.argSpec && (newFuncData.argSpec.length>0)) {
				var lastArgName = newFuncData.argSpec[newArgCount-1].name;
				if (lastArgName.substr(lastArgName.length-3,3) === "...") {
					var dotDotDotVal = ""
					// cycle through all arguments starting with position of '...' argument
					for (var i = 5-newValPos + newArgCount-1; i < (this._allExpressions.argList.length); i++) {
						if (this._allExpressions.argList[i]||(this._allExpressions.argList[i]==="")) {
							dotDotDotVal = dotDotDotVal + "," + this._allExpressions.argList[i];
						}
					}
					dotDotDotVal = dotDotDotVal.substring(1);
					// remove empty args from end
					while (dotDotDotVal.charAt(dotDotDotVal.length-1)===",") {
						dotDotDotVal = dotDotDotVal.substring(0,dotDotDotVal.length-1);
					}
					this._allExpressions.argList[5-newValPos + newArgCount-1] = dotDotDotVal;
					var allListLen = this._allExpressions.argList.length;
					// remove the extra arguments
					for (var i = 5-newValPos+ newArgCount; i < allListLen; i ++ ) {
						this._allExpressions.argList.pop();
					}
				}
			}
			
			if (oldArgLength > newArgCount) { // remove extra argument values/slots
				for (var i = newArgCount; i < oldArgLength; i++) {
					this._currentExpression.argList.pop();
				}
			}
			for (var i = 0; i < newArgCount; i++) {
				this._currentExpression.argList[i] = '';
				if ((i + 5 - newValPos >= 0) &&  (i + 5 - newValPos < this._allExpressions.argList.length)) {
					this._currentExpression.argList[i] = this._allExpressions.argList[i + 5 - newValPos];
				}
			}
			this._allExpressions.valPos = newValPos;
		}
		else {
			this._currentExpression.argList = [];
			this._currentExpression.remaining = '';
			this._currentExpression.innerExpression = '';
			this._allExpressions.argList = [];
			for (var i = 0; i < newArgCount; i++) {
				this._currentExpression.argList[i] = '';
			}
			var valuePos = 0;
			if (newFuncData && (typeof newFuncData.valuePos != 'undefined') && (newFuncData.valuePos >= 0)) {
				valuePos = newFuncData.valuePos;
			}
			this._allExpressions.valPos = valuePos;
			if (newArgCount) {
				this._currentExpression.argList[valuePos] = this._currentExpression.fullExpression;
			}
		}
		this._currentExpression.functionClass = newClass;
		this._currentExpression.functionName = newName;
		this._allExpressions.currEx = newClass+'.'+newName;
	}
	
	var functionText = '';
	var open = '';
	var close = '';
	if (this._currentExpression.functionClass != '') {
		var classText = '##class('+this._currentExpression.functionClass+').';
		if (this._currentExpression.functionClass == 'Ens.Rule.FunctionSet') {
			classText = '..';
		}
		functionText = classText + this._currentExpression.functionName;
		open = '(';
		close = ')';
		var lastArg = 0;
		for (var i = 0; i < this._currentExpression.argList.length; i++) {
			if (this._currentExpression.argList[i] != '') {
				lastArg = i;
			}
		}
		var displayArray = this._currentExpression.argList.slice(0, lastArg+1);
		this._currentExpression.fullExpression = functionText + open + displayArray.join(',') + close + this._currentExpression.remaining;
	}
	else {
		this._currentExpression.fullExpression = this._currentExpression.innerExpression;
	}
	
	zen('currExpression').setValue(this._currentExpression.fullExpression);
	return true;
}

ClientMethod parseExpression(expr, combineDotDotDot) [ Language = javascript ]
{
	var functionClass = '';
	var functionName = '';
	var argList = [ ];
	var innerExpression = expr;
	var remText = '';
	if (expr.substring(0,2) == '..') {
		functionClass = 'Ens.Rule.FunctionSet';
		var methodEnd = expr.indexOf('(');
		if (methodEnd > 2) {
			functionName = expr.substring(2,methodEnd);
			// check function is known to us
			var funcList = this.getFunctionList();
			var currFunction = funcList[functionClass + '.' + functionName];
			if (currFunction) {
				var temp = this.getExpression(expr.substring(methodEnd+1, expr.length));
				argList = temp.argList;
				innerExpression = temp.innerExpression;
				remText = temp.remaining;
				
				// if '...' syntax for final argument, all extra arguments are actually part of that one
				if (combineDotDotDot && currFunction.argSpec && (currFunction.argSpec.length>0)) {
					var lastArgName = currFunction.argSpec[currFunction.argSpec.length-1].name;
					if ((argList.length > currFunction.argSpec.length) && (lastArgName.substr(lastArgName.length-3,3)==="..."))
					{
						var dotDotDotVal = "";
						var listLen = argList.length;
						var specLen = currFunction.argSpec.length;
						for (var i=specLen;i<=listLen;i++) {
							dotDotDotVal = dotDotDotVal + "," + argList[specLen-1]; // add extra argument to final argument
							argList.splice(specLen-1,1); // remove extra argument
						}
						dotDotDotVal = dotDotDotVal.substring(1);
						argList.push(dotDotDotVal);
					}
				}
				
				for (var i = argList.length; i < currFunction.argSpec.length; i++) {
					argList[i] = '';
				}
			}
			else {
				functionClass = '';
				functionName = '';
			}
		}
		else { // Not function call
			functionClass = '';
		}
	}
	else if (expr.substring(0,8).toLowerCase() == '##class(') {
		var nameEnd = expr.indexOf(')');
		if ((nameEnd > 8) && (expr.substring(nameEnd + 1, nameEnd + 2) == '.')) {
			functionClass = expr.substring(8,nameEnd);
			var methodEnd = expr.indexOf('(',nameEnd+2);
			if (methodEnd > (nameEnd + 2)) {
				functionName = expr.substring(nameEnd + 2, methodEnd);
				var funcList = this.getFunctionList();
				var currFunction = funcList[functionClass + '.' + functionName];
				if (currFunction) {
					var temp = this.getExpression(expr.substring(methodEnd+1, expr.length));
					argList = temp.argList;
					innerExpression = temp.innerExpression;
					remText = temp.remaining;

					// if '...' syntax for final argument, all extra arguments are actually part of that one
					if (combineDotDotDot && currFunction.argSpec && (currFunction.argSpec.length>0)) {
						var lastArgName = currFunction.argSpec[currFunction.argSpec.length-1].name;
						if ((argList.length > currFunction.argSpec.length) && (lastArgName.substr(lastArgName.length-3,3)==="..."))
						{
							var dotDotDotVal = "";
							var listLen = argList.length;
							var specLen = currFunction.argSpec.length;
							for (var i=specLen;i<=listLen;i++) {
								dotDotDotVal = dotDotDotVal + "," + argList[specLen-1]; // add extra argument to final argument
								argList.splice(specLen-1,1); // remove extra argument
							}
							dotDotDotVal = dotDotDotVal.substring(1);
							argList.push(dotDotDotVal);
						}
					}
					
					for (var i = argList.length; i < currFunction.argSpec.length; i++) {
						argList[i] = '';
					}
				}
				else {
					functionClass = '';
					functionName = '';
				}
			}
			else {
				functionClass = '';
			}
		}	
	}
	if (functionClass == '') { // handle case where DTL Editor assumes a "##class(" or ".." prefix indicates a function
		this.isReplace = false;
		zen('isReplace').setValue(false);
	}
	var retObj = {
		fullExpression: expr,
		functionClass: functionClass,
		functionName: functionName,
		argList: argList,
		innerExpression: innerExpression,
		remaining: remText
	};
	return retObj;
}

ClientMethod getExpression(expr, includesOpen) [ Language = javascript ]
{
	if (includesOpen) {
		expr = expr.substring(1, expr.length -1);
	}

	var isBad = false;
	var nextPos = 0;
	var level = 1;
	var openChar = { '(': 0, '{': 1, '[': 2 };
	var closeChar = { ')': 0, '}': 1, ']': 2 };
	var counters = [ 1, 0, 0 ];
	var quoteChar = { '\'': true, '"': true };
	var commaPos = [];
	var lastBracePos = expr.length;
	var mainExpression = true;
	var argList = [];

	while ((!isBad) && (nextPos < expr.length)) {
		var currChar = expr.substring(nextPos, nextPos+1);
		nextPos++;
		if (openChar[currChar] != null) {
			counters[openChar[currChar]]++;
		}
		else if (closeChar[currChar] != null) {
			counters[closeChar[currChar]]--;
		}
		else if (quoteChar[currChar]) {
			var nextQuote = expr.indexOf(currChar,nextPos);
			if (nextQuote == -1) {
				isBad = true;
			}
			else {
				nextPos = nextQuote + 1;
			}
		}
		else if (mainExpression && (currChar == ',')) {
			if (counters[0] == 1) {
				var addComma = true;
				for (var i = 1; i < counters.length; i++) {
					if (counters[i] > 0) {
						addComma = false;
					}
				}
				if (addComma) {
					commaPos[commaPos.length] = nextPos - 1;
				}
			}	
		}
		
		var balanced = true;
		for (var i = 0; i < counters.length; i++) {
			if (counters[i] != 0) {
				balanced = false;
			}
		}
		if (balanced && mainExpression) {
			mainExpression = false;
			lastBracePos = nextPos;
		}
	}
	if (isBad || !balanced) {
		argList = [ expr ];
		remText = '';
	}
	else {
		var innerExpr = expr.substring(0, lastBracePos - 1);
		remText = expr.substring(lastBracePos + 1, expr.length);
		if (commaPos.length == 0) {
			argList = [ innerExpr ];
		}
		else {
			var lastPos = 0;
			for (var i = 0; i < commaPos.length; i++) {
				var current = expr.substring(lastPos, commaPos[i]);
				argList[argList.length] = current;
				lastPos = commaPos[i]+1;
			}
			argList[argList.length] = expr.substring(lastPos, lastBracePos-1);
		}
	}
	return { argList: argList, remaining: remText, innerExpression: '' }
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var initialExpression = '';
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage.getCurrentExpression) {
		initialExpression = opener.zenPage.getCurrentExpression();
	}
	this._currentExpression = this.parseExpression(initialExpression,true);
	this._allExpressions = new Object();
	this._allExpressions.argList = [];
	this._allExpressions.valPos = 0;
	if (this._currentExpression) {
		var fullFunction = this._currentExpression.functionClass + '.'+ this._currentExpression.functionName;
		this._allExpressions.currEx = fullFunction;
		if (this._currentExpression.argList) {
			var valPos = 0;
			if (this._currentExpression.functionClass !='') {
				var functionList = this.getFunctionList();
				var funcData = functionList[this._currentExpression.functionClass + '.' + this._currentExpression.functionName];
				if (funcData && (typeof funcData.valuePos != 'undefined') && (funcData.valuePos >= 0)) {
					valPos = funcData.valuePos;
					this._allExpressions.valPos = valPos;
				}
			} else {
				this._allExpressions.argList[5] = initialExpression;
			}
			for (var i = 0; i < 5-valPos; i++) {
				this._allExpressions.argList[i] = '';
			}
			for (var i = 0; i < this._currentExpression.argList.length; i++) {
				if (i+5-valPos >=0) {
					this._allExpressions.argList[i+5-valPos] = this._currentExpression.argList[i];
				}
			}
		}
		if (this._currentExpression.functionClass != '') {
			zen('functionSelect').setValue(fullFunction);
			this.drawArguments(fullFunction, true);
		}
	}
	this.updateExpression();
}

/// Get the value that will be applied when the user presses the OK button.
ClientMethod getDialogValue() [ Language = javascript ]
{
	if (!this._currentExpression) {
		return '';
	}
	return encodeURIComponent(this._currentExpression.fullExpression);
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);
	this.resizeTextControls();
}

/// Ensure that the text controls and the description field expand to fit the width of the window.
ClientMethod resizeTextControls() [ Language = javascript ]
{
	var bodyDiv = zen('body').getEnclosingDiv();
	if (bodyDiv) {
		// note that we rely on the style set by adjustSize() in the super class
		var bodyWidth = parseInt(bodyDiv.style.width,10) - 40;
		var textWidth = (bodyWidth > 0) ? (bodyWidth + 'px') : '';
		var textInputs = body.getElementsByTagName('input');
		for (var i = 0; i < textInputs.length; i++) {
			var input = textInputs.item(i);
			if (input && (input.type == 'text')) {
				input.style.width = textWidth;
			}
		}
		var expressionDiv = zen('currExpression').getEnclosingDiv();
		expressionDiv.style.width = textWidth;
		var descriptionDiv = zen('functionDescription').getEnclosingDiv();
		if (descriptionDiv) {
			descriptionDiv.style.width = textWidth;
		}
	}
}

}
