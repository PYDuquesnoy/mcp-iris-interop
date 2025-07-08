/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized control that displays a complete set 
/// of radio buttons based on a list of values.<br>
/// The list of values is specified by the <property>valueList</property>. This
/// is a csv-list of values that the user can select. If <property>displayList</property> is
/// provided, it is used to provide the displayed captions for the buttons.<br>
/// If there is an empty value ("") within the items in <property>valueList</property> (e.g., ",A,B,C"),
/// then an additional button will be displayed for the empty value. The caption for this empty
/// value is specified by the <property>emptyCaption</property>.<br>
/// It is assumed that every value within the set of value is distinct;
/// A <property>valueList</property> containing duplicate items (e.g., "A,A,A") will lead to strange
/// beahavior for the user.<br>
/// It is possible to programmatically set the value of the <class>radioSet</class> to any arbitary value
/// using the <method>setValue</method> method. If the value of the <class>radioSet</class> does
/// not correspond to an item in the set of values, then all buttons in the set will be unchecked.
Class %ZEN.Component.radioSet Extends listControl [ Deprecated, System = 3 ]
{

/// Defines set of titles (tooltip text) for each of 
/// the choices of this radioSet as a csv-list.
Property titleList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// This caption is used for any radio buttons within this radioSet
/// that have an empty ("") display value.
Property emptyCaption As %ZEN.Datatype.caption [ InitialExpression = "None" ];

/// CSS class to apply to the control's captions.
Property captionClass As %ZEN.Datatype.cssClass [ InitialExpression = "radioSetCaption" ];

/// Specifies whether the radio buttons appear horizontally (default) or vertically
Property layout As %ZEN.Datatype.string(VALUELIST = ",horizontal,vertical") [ InitialExpression = "horizontal" ];

/// Count of options within this radioSet.
Property optionCount As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Span around radio button and caption." */ 
.radioSetSpan {
	white-space: nowrap;
}

/* @doc="Style for radio captions." */
a.radioSetCaption {
	vertical-align: top;
	text-decoration: none;
	color: black;
}

/* @doc="Style for disabled radio captions." */
a.radioSetCaptionDisabled {
	vertical-align: top;
	text-decoration: none;
	color: gray;
}

a.radioSetCaption:hover {
	color: red;
}

a.radioSetCaption:link, .radioSetCaption:visited, .radioSetCaption:active {
}

a.radioSetCaptionDisabled:link, .radioSetCaptionDisabled:visited, .radioSetCaptionDisabled:active {
}

</style>
}

Method %DrawHTML()
{
	Set tSC = ..%BuildValueLists(.tValueList,.tDisplayList)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}

	#; for "readonly" we have to disable the control
	Set disabled = $S(..disabled||..readOnly:"disabled",1:"")

	#; make sure value is valid:
	If '$ListFind(tValueList,..value) {
		Set ..value = ""
	}
	
	#; create hidden field to hold real value for submit
	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# value="#($ZCVT(..value,"O","HTML"))#"/>>

	Set ..optionCount = 0
	Set tCaptionClass = $S(..disabled:"radioSetCaptionDisabled",1:..captionClass)
	For n=1:1:$LL(tDisplayList) {
		Set ..optionCount = ..optionCount + 1
		Set tValue = $LG(tValueList,n)
		Set tText = $LG(tDisplayList,n)
		Set:tText="" tText=..emptyCaption
		Set tTitle = $P(..titleList,",",n)
		&html<<span class="radioSetSpan"><input #(..%Attr("title",..title))# type="radio" #(disabled)# id="#(..%MakeId("textRadio_"_n))#" #($S(tValue=..value:"checked=""1""",1:""))# #(..%Attr("name","r"_..index_$Case(..tuple,"":"",:"."_..tuple)))# #(..%Attr("tabindex",..tabIndex))# value="#($ZCVT(tValue,"O","HTML"))#" onclick="return #(..%Self())#.clickItem(#(n)#);"/><a class="#(tCaptionClass)#" id="#(..%MakeId("caption_"_n))#" #(..%Attr("title",tTitle))# href="" #(..%Attr("tabindex",..tabIndex))# onclick="#(..%Self())#.clickItem(#(n)#);return false;">#($ZCVT(tText,"O","HTML"))#</a></span>>
		If (..layout="vertical") &html<<br/>>
	}
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..valueList = "Apple,Banana,Cherry"
}

/// User click on radio button or caption for radio button choice; 
/// select associated button and invoke callbacks.
ClientMethod clickItem(choice) [ Language = javascript ]
{
	if (this.disabled) return false;
	if (this.readOnly) return false;

	var changed = false;
	var radio = this.findElement('textRadio_' + choice);
	zenASSERT(radio,'Unable to find radio element.',arguments);
	radio.checked = true;
	this.value = radio.value;
	
	// update hidden field	
	var hidden = this.findElement('hidden');
	zenASSERT(hidden,'Unable to find hidden element.',arguments);
	if (hidden.value != this.value) {
		hidden.value = this.value;
		changed = true;
	}

	// invoke user callback(s), if present
	zenInvokeCallbackMethod(this.onclick,this,'onclick');

	// notify
	if (changed) {
		this.onchangeHandler();
	}

	return true;
}

/// Internal method to set css class used for radio captions.
ClientMethod setCaptionClass(cls) [ Internal, Language = javascript ]
{
	// find each caption and change CSS class
	for (var n = 0; n < this.optionCount; n++) {
		var caption = this.findElement('caption_' + ((parseInt(n,10))+1));
		if (caption) { caption.className = cls; }
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'optionCount':
		if (parseInt(value) != this.optionCount) {
			this.optionCount = value;
			// make sure correct option is selected
			this.setValue(this.value);
		}
		break;

	case 'value':
		this.value = value;
	
		// make sure correct button is selected
		for (var n = 0; n < this.optionCount; n++) {
			var radio = this.findElement('textRadio_' + ((parseInt(n,10))+1));
			if (radio) {
				radio.checked = (radio.value == this.value);
			}
		}
		var hidden = this.findElement('hidden');
		if (hidden) { hidden.value = this.value; }
		break;
	case 'readOnly':
	case 'disabled':
		value = (value) ? true : false;
		if (this[property] != value) {
			this[property] = value;
			// enable/disable each individual element
			for (var n = 0; n < this.optionCount; n++) {
				var radio = this.findElement('textRadio_' + ((n*1)+1));
				if (radio) {radio.disabled = (this.disabled||this.readOnly); }
			}
			if ('disabled' == property) {
				this.setCaptionClass(this.disabled ? 'radioSetCaptionDisabled' : this.captionClass);
			}
		}
		break;
	case 'captionClass':
		this.captionClass = value;
		if (!this.disabled) {
			this.setCaptionClass(this.captionClass);
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
