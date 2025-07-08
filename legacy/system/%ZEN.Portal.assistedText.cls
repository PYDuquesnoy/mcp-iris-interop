/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Portal.assistedText Extends %ZEN.Component.control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "assistedText";

/// Comma-separated list of additional JS include files for the page.
Parameter INCLUDEFILES As STRING = "zenCSLM.js";

/// Specify the type of the control, it accepts 3 formats:
///   classname            - use build in assist for classname
///   property:<classname> - use build in assist for property names with the top level context class being <classname>
///   custom               - this is default, the control calls onUpdateDataClient to populate the selector control
Property controlType As %ZEN.Datatype.string [ InitialExpression = "custom" ];

/// When controlType is custom, this is the client method to call to get data to populate the selector control
/// The format of this attribute is "zenPage.<client_method_name>(base);"
/// The client method takes one argument that is the base text. The base text is either empty string or it ends with the trigger character.
/// The return value is a single-character delimited list with the delimiter character as the first character.
Property onUpdateDataClient As %ZEN.Datatype.eventHandler;

/// This property has been deprecated. Please use onUpdateDataClient instead.
Property OnUpdateDataServer As %ZEN.Datatype.delegator(FORMALSPEC = "pBase:%String", RETURNTYPE = "%String");

/// list of characters that triggers the calls to update data.
/// When controlType is either classname or property, triggerChars is ignored. It is assumed to be the dot character.
Property triggerChars As %ZEN.Datatype.string [ InitialExpression = "." ];

/// Internally used to store the data separator character.
Property separator As %ZEN.Datatype.string [ InitialExpression = ",", Private ];

/// The size (number of lines) of the drop-down area for this assistedText control.
Property listSize As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 5 ];

/// This property is obsolete. Please use controlStyle to set width
/// The width of the control, must end in a unit, i.e. 100px or 30%
Property controlWidth As %ZEN.Datatype.string;

/// When isSuggestedDataComplete is false, it indicates the string list returned by update data callbacks are partial strings
/// and they are to be appended to the original base string to be used as suggested text.
/// When isSuggestedDataComplete is true, it indicates the string list returned by update data callbacks are complete strings
/// and they do not need to be appended to the original base string.
/// When controlType is either classname or property, isSuggestedDataComplete is ignored. It is assumed to be false.
Property isSuggestedDataComplete As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// This property is obsolete. We do not display ghost text anymore.
Property hideGhost As %ZEN.Datatype.boolean;

/// The placeholder attribute specifies a short hint that describes the expected value of an input field
/// (e.g. a sample value or a short description of the expected format).
/// The hint is displayed in the input field when it is empty.
Property placeholder As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
/* @doc="Style for assisted-Text control." */
.assistedText {
}
</style>
}

/// Draw content of control.
Method %DrawHTML()
{
	set tIgnore("onblur")=""
	set tIgnore("onkeydown")=""
	set tIgnore("onchange")=""
	set tDisabled = $S(..disabled:"disabled=""true""",1:"")

	if ..controlWidth '="" {
		set ..controlStyle = ..controlStyle_" width:"_..controlWidth_";"
	}

	&html<
		<div style="overflow:visible;">
			<div id="#(..%MakeId("selectorParent"))#" style="position:relative; top:0px; left:0px; width:0px;">
				<select id="#(..%MakeId("selector"))#"
					#(..%Attr("size",..listSize))#
					style="position:absolute; display:none; top:23px; left:0px;"
					onchange="zenPage.getComponent(#(..index)#).selectorChanged()"
					onfocus="zenPage.getComponent(#(..index)#).selectorGotFocus();"
					ondblclick="zenPage.getComponent(#(..index)#).selectorDblClicked();">
				</select>
			</div>
			<input type="text" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Name())# #(tDisabled)# #(..%Attr("value",..value))# #(..%Attr("tabindex",..tabIndex))# #(..%Attr("placeholder",..placeholder))#
				#(..%GetEventHandlers(.tIgnore))#
				style="border:1px solid #7F9DB9; #(..controlStyle)#"
				onfocus="zenPage.getComponent(#(..index)#).controlGotFocus();"
				onblur="zenPage.getComponent(#(..index)#).controlOnBlur(event);"
				onkeydown="zenPage.getComponent(#(..index)#).controlKeyPressed(event);"
				onclick="zenPage.getComponent(#(..index)#).controlClicked();"
				>
			</input>
		</div>
	>
	quit
}

/// client-side initialization for this object.<br>
ClientMethod onCreate() [ Language = javascript ]
{
	this.originalTextValue = this.value;
	return;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'disabled':
		this.findElement('control').disabled = value;
		break;
	case 'controlWidth':
		this.findElement('control').style.width = value;
		break;
	case 'controlType':
		this.controlType = value;
		this.updateData(this.base)
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

ClientMethod selectorChanged() [ Language = javascript ]
{
	var select = this.findElement("selector")
	if ( this.findElement("selector").selectedIndex == -1 ) {
		this.findElement("control").value = this.currentTextValue;
	} else {
		this.findElement("control").value = select.options[select.selectedIndex].text;
	}
	return;
}

ClientMethod selectorGotFocus() [ Language = javascript ]
{
	this.controlHasFocus = true;
	this.findElement("control").focus();
	return;
}

ClientMethod selectorDblClicked() [ Language = javascript ]
{
	this.doAction();
	this.controlHasFocus = true;
	this.findElement("control").focus();
	return;
}

ClientMethod controlGotFocus() [ Language = javascript ]
{
	if ( this.controlHasFocus != true ) {
		this.originalValue = this.findElement("control").value;
	}
	this.controlHasFocus = true;
	return;
}

ClientMethod controlOnBlur(event) [ Language = javascript ]
{
	this.controlHasFocus = false;
	this.blurHandler = setTimeout("zenPage.getComponent("+this.index+").deferredLostFocus();",0);
	return;
}

ClientMethod deferredLostFocus() [ Language = javascript ]
{
	// group has not lost focus
	if ( this.controlHasFocus == true ) {
		return;
	}

	if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
	this.findElement("selector").style.display = "none";
	if ( this.findElement("control").value != this.originalValue ) {
		//this.onchangehandler();
		this.value = this.findElement("control").value;
		var onchangeHandler = this.onchange;
		if ( onchangeHandler.substr(0,7) != "return " ) { onchangeHandler = "return " + onchangeHandler; }
		data = zenInvokeCallbackMethod(onchangeHandler,this,'onchange');
	}
	this.originalValue = "";
	this.controlHasFocus = false;
	return;
}

ClientMethod controlClicked() [ Language = javascript ]
{
	this.doAction(1);
	return;
}

ClientMethod controlKeyPressed(event) [ Language = javascript ]
{
	var doAction = true;
	
	// right arrow on the last character does auto-complete
	if ( event.keyCode==39 ) {
		if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none;"; }
		this.findElement("selector").style.display = "none";
	}
	// TAB key does auto-complete
	if ( event.keyCode==9 ) {
		if ( this.findElement("selector").style.display == "block") {
			if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
			this.findElement("selector").style.display = "none";
			ZLM.killEvent(event);
		}
	}
	// RETURN key does auto-complete
	if ( event.keyCode==13 ) {
		if ( this.findElement("selector").style.display == "block") {
			if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
			this.findElement("selector").style.display = "none";
		} else {
			if ( this.originalTextValue != this.findElement("control").value ) {
				this.onchangeHandler();
				this.originalTextValue = this.findElement("control").value;
			}
		}
	}
	// ESCAPE key means all done
	if ( event.keyCode==27 ) {
		// On FireFox, under ESC, the value of control is somehow rolled back if the previous action was the TAB key.
		// To reproduce this, do the following key sequence: %, TAB, ESC.
		// This probably is caused by the ZLM.killEvent(event) call in the TAB handling,
		// but we have no control over this rolling back.
		// We work around this problem by deferring the ESC action until after the rolling back has occured.
		setTimeout("zenPage.getComponent("+this.index+").deferredEscapeAction()",1);
		return;
	}
	// up arrow changes the selection in the selector
	if ( event.keyCode==38 ) {
		if ( this.findElement("selector").style.display != "none" ) {
			if ( this.findElement("selector").selectedIndex < 0 ) {
				this.findElement("selector").selectedIndex = this.findElement("selector").options.length-1;
			} else {
				this.findElement("selector").selectedIndex--; 
			}
			this.selectorChanged();
			doAction = false;
		}
	}
	// down arrow changes the selection in the selector
	if ( event.keyCode==40 ) {
		if ( this.findElement("selector").style.display != "none" ) {
			if ( this.findElement("selector").selectedIndex < (this.findElement("selector").options.length-1) ) {
				this.findElement("selector").selectedIndex++;
			}
			this.selectorChanged();
			doAction = false;
		}
	}
	
	if ( doAction ) {
		window.setTimeout("zenPage.getComponent("+this.index+").doAction()",1);
		window.setTimeout("zenPage.getComponent("+this.index+").deferredSaveCurrentTextValue('"+event.keyCode+"')",1);
	}

	return;
}

ClientMethod deferredSaveCurrentTextValue(keyCode) [ Language = javascript ]
{
	this.currentTextValue = this.findElement("control").value;
	return;
}

ClientMethod deferredEscapeAction() [ Language = javascript ]
{
	this.findElement("control").value = this.currentTextValue;
	if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
	this.findElement("selector").style.display = "none";
	return;
}

ClientMethod doAction(skipModifiedCheck) [ Language = javascript ]
{
	var textValue = this.findElement("control").value;
	if ( !skipModifiedCheck ) {
		if ( textValue == this.currentTextValue ) return;
	}

	// check to see if we need to reload data
	var lastIndex = -1;
	if ( (this.controlType=="custom")&&(this.triggerChars=="") ) {
		lastIndex = textValue.length-1;
	} else {
		var triggerChars = this.controlType=="custom" ? this.triggerChars : ".";
		for ( var i=0 ; i<triggerChars.length ; i++ ) {
			lastIndex = Math.max(lastIndex,textValue.lastIndexOf(triggerChars.charAt(i)));
		}
	}
	var base = textValue.substr(0,lastIndex+1);

	if ( base != this.base ) {
		this.updateData(base);
		var updatedData = true;
	} else {
		var updatedData = false;
	}
	
	var textProperty = textValue.substr(lastIndex+1);
	var textPropertyLength = textProperty.length;
	var propertyFound = "";
	var propertyListFiltered = new Array();

	if ( this.isSuggestedDataComplete ) {
		propertyListFiltered = this.propertyListComplete;	
	}
	// search to see if partial match exists
	var extactMatchFound = false;
	for ( var i=0 ; i<this.propertyListComplete.length ; i++ ) {
		if ( this.propertyListComplete[i].substr(0,textPropertyLength) == textProperty ) {
			if ( !this.isSuggestedDataComplete ) {
				propertyListFiltered[propertyListFiltered.length] = base + this.propertyListComplete[i];
			}
			if ( propertyFound == "" ) {
				propertyFound = (this.isSuggestedDataComplete?"":base) + this.propertyListComplete[i];
				exactMatchFound = (propertyFound == textValue);
			}
		}
	}

	// update the selector
	if ( propertyListFiltered.length < 1 ) {
		if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
		this.findElement("selector").style.display = "none";
	} else if ( (propertyListFiltered.length==1) && (exactMatchFound==true) ) {
		if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
		this.findElement("selector").style.display = "none";
	} else if ( (updatedData==false) && (exactMatchFound==true) ) {
		if ( this.iFrameCreated ) { this.findElement("selectorIFrame").style.display = "none"; }
		this.findElement("selector").style.display = "none";
	} else {
		if ((!this.iFrameCreated)) { //SAM055
			var div = this.findElement("selectorParent");
			var iFrame = document.createElement("iframe");
			iFrame.id = this.makeId('selectorIFrame');
			iFrame.src = '';
			iFrame.frameBorder = '0';
			var s = iFrame.style;
			s.filter = 'alpha(opacity=0)';
			s.zIndex = '0';
			s.position = 'absolute'; 
			s.top = '0px'; 
			s.left = '0px'; 
			s.width = '100%'; 
			s.height = '100%'; 
			s.border = '0px solid black';
			s.background = 'transparent';
			div._iFrame = iFrame;
			div.insertBefore(div._iFrame,div.firstChild);
			this.iFrameCreated = true;
		}
		this.findElement("selectorIFrame").style.display = "block";
		this.setSelectorStyle();
		this.findElement("selector").style.display = "block";
		// update the Combo has to be done after the stack is cleared so the screen can be painted correctly
		this.propertyListFiltered = propertyListFiltered;
		setTimeout("zenPage.getComponent("+this.index+").deferredComboUpdate()",0);

	}
	return;
}

ClientMethod deferredComboUpdate() [ Language = javascript ]
{
	this.setComboOptions(this.findElement("selector"),this.propertyListFiltered.join(this.separator),false);
	this.findElement("selector").selectedIndex = -1;
	return;
}

ClientMethod updateData(base) [ Language = javascript ]
{
	this.base = base;
	var data = "";
	if ( this.controlType != "custom" ) {
		if ( this.controlType == "classname" ) {
			data = this.ServerGetClassPackageList(base);
		} else if ( this.controlType.substr(0,9) == "property:" ) {
			data = this.ServerGetPropertyList(base,this.controlType.substr(9));
		}
	} else if ( this.onUpdateDataClient != "" ) {
		var onUpdateDataClient = this.onUpdateDataClient;
		if ( onUpdateDataClient.substr(0,7) != "return " ) { onUpdateDataClient = "return " + onUpdateDataClient; }
		data = zenInvokeCallbackMethod(onUpdateDataClient,this,'onUpdateDataClient',"base",base);
	}
	this.propertyListComplete = new Array();
	this.separator=data.charAt(0);
	this.propertyListComplete = data.substr(1).split(this.separator);
	return;
}

ClassMethod ServerGetClassPackageList(pBase As %String) As %String [ ZenMethod ]
{
	If '$system.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$DevelopmentResourceName":"_$$$PermUseName)
	}
	set tList=""
	try {
		set tBASE = $zcvt(pBase,"u"), len = $l(tBASE)
		set tCLASS = tBASE for  {
			set tCLASS = $o(^rINDEXCLASS(tCLASS)) quit:tCLASS=""
			quit:$e(tCLASS,1,len)'=tBASE
			set tClassname = $li(^rINDEXCLASS(tCLASS),2)
			set tRest = $e(tClassname,len+1,*)
			if $f(tRest,".") {
				set tArray($p(tRest,".",1)_".")=""
			} else {
				set tArray(tRest)=""
			}
		}
		set tList=""
		set tPackage="" for  {
			set tPackage = $o(tArray(tPackage)) quit:tPackage=""
			set tList = tList _ "," _ tPackage
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tList
}

ClassMethod ServerGetPropertyList(pBase As %String, pClassname As %String) As %String [ ZenMethod ]
{
	If '$system.Security.Check($$$DevelopmentResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$DevelopmentResourceName":"_$$$PermUseName)
	}
	set tList=""
	try {
		set tClassObj = ##class(%Dictionary.CompiledClass).%OpenId(pClassname)
		if '$isObject(tClassObj) {
			set tClassObj = ##class(%Dictionary.ClassDefinition).%OpenId(pClassname)
		}
		if ( '$isObject(tClassObj) ) quit
		set tProperty = $p(pBase,".",1)
		;
		for i=1:1:tClassObj.Properties.Count() {
			if ( pBase="" ) {
				if tClassObj.Properties.GetAt(i).Private continue
				if tClassObj.Properties.GetAt(i).Internal continue
				set tTypeClass = tClassObj.Properties.GetAt(i).Type
				set tTypeObj = ##class(%Dictionary.CompiledClass).%OpenId(tTypeClass)
				if ( $isObject(tTypeObj)&&(tTypeObj.ClassType'="datatype") ) {
					set tList=tList_","_tClassObj.Properties.GetAt(i).Name_"."
				} else {
					set tList=tList_","_tClassObj.Properties.GetAt(i).Name
				}
			} else {
				if ( tProperty '= tClassObj.Properties.GetAt(i).Name ) continue
				set tList = ..ServerGetPropertyList($p(pBase,".",2,999),tClassObj.Properties.GetAt(i).Type)
				quit
			}
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tList
}

ClientMethod setComboOptions(combo, options, insertBlank) [ Language = javascript ]
{
	if ( zenIsIE ) {
		while ( combo.options.length > 0 ) { combo.options.remove(0); }
		if ( insertBlank ) { combo.options.add(new Option("")); }
		var optionsArray = options.split(this.separator)
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			var opt = new Option(optionsArray[i]);
			combo.options.add(opt);
		}
	} else {
		var optionsArray = options.split(this.separator)
		var innerHTML = "";
		if ( insertBlank ) { innerHTML = "<option></option>"; }
		for ( i=0 ; i<optionsArray.length ; i++ ) {
			innerHTML = innerHTML + "<option>" + optionsArray[i] + "</option>"
		}
		combo.innerHTML = innerHTML;
	}
	return;
}

ClientMethod getSelection(ctrl) [ Language = javascript ]
{
	var selectionObject = {};
	if (document.selection) {
		// IE support
		ctrl.focus ();
		var Sel = document.selection.createRange();
		selectionObject.text = Sel.text;
		Sel.moveStart ('character', -ctrl.value.length);
		selectionObject.end = Sel.text.length;
		selectionObject.start = selectionObject.end - selectionObject.text.length;
	} else if (ctrl.selectionStart || ctrl.selectionStart == '0') {
		// Firefox support
		selectionObject.start = ctrl.selectionStart;
		selectionObject.end = ctrl.selectionEnd;
		selectionObject.text = ctrl.value.substring(selectionObject.start,selectionObject.end);
	}
	return selectionObject;
}

ClientMethod setSelection(ctrl, pos1, pos2) [ Language = javascript ]
{
	if(ctrl.setSelectionRange) {
		ctrl.focus();
		ctrl.setSelectionRange(pos1,pos2);
	} else if (ctrl.createTextRange) {
		var range = ctrl.createTextRange();
		range.collapse(true);
		range.moveEnd('character', pos2);
		range.moveStart('character', pos1);
		range.select();
	}
}

ClientMethod setSelectorStyle() [ Language = javascript ]
{
	var control = this.findElement("control");
	var selector = this.findElement("selector");
	selector.style.top = (control.offsetHeight+4) + "px";
	selector.style.width = control.offsetWidth + "px";
	selector.style.fontFamily = ZLM.getComputedNodeStyle(control,"fontFamily");
	selector.style.fontSize = ZLM.getComputedNodeStyle(control,"fontSize");
	selector.style.zIndex = 32765;
	return;
}

}
