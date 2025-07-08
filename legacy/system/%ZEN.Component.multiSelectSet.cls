/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized control that displays a set 
/// of checkBoxes based on a list of values.<br>
/// The list of values is specified by the <property>valueList</property>. This
/// is a csv-list of values that the user can select. If <property>displayList</property> is
/// provided, it is used to provide the displayed captions for the buttons.<br>
/// If there is an empty value ("") within the items in <property>valueList</property> (e.g., ",A,B,C"),
/// then an additional button will be displayed for the empty value. The caption for this empty
/// value is specified by the <property>emptyCaption</property>.<br>
/// It is assumed that every value within the set of value is distinct;
/// A <property>valueList</property> containing duplicate items (e.g., "A,A,A") will lead to strange
/// beahavior for the user.<br>
/// The nominal value of the <class>multiSelectSet</class> is a csv-list of all options currently
/// checked.  The order of items appearing in this list will be the same as their listings in the
/// original valueList provided.<br>
/// It is possible to programmatically set the value of the <class>multiSelectSet</class> to any arbitary value
/// using the <method>setValue</method> method and providing either a single value or a csv-list
/// of values. If no values in the list provided to the <class>multiSelectSet</class> 
/// corresponds to an item in the set of values, then all buttons in the set will be unchecked.
Class %ZEN.Component.multiSelectSet Extends listControl [ Deprecated, System = 3 ]
{

/// Subclasses can set this to change the the default orientation of the options
Parameter DEFAULTLAYOUT As STRING = "vertical";

/// Defines set of titles (tooltip text) for each of 
/// the choices of this multiSelectSet as a csv-list.
Property titleList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// This caption is used for any radio buttons within this multiSelectSet
/// that have an empty ("") display value.
Property emptyCaption As %ZEN.Datatype.caption [ InitialExpression = "None" ];

/// CSS class to apply to the control's captions.
Property captionClass As %ZEN.Datatype.cssClass [ InitialExpression = "multiSelectSetCaption" ];

/// Count of options within this multiSelectSet.
Property optionCount As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Specifies how options within this group should be layed out.  Valid values are "horizontal"
/// and "vertical"
Property layout As %ZEN.Datatype.string(MAXLEN = 12, VALUELIST = ",horizontal,vertical") [ InitialExpression = {..#DEFAULTLAYOUT} ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Span around radio button and caption." */ 
.multiSelectSetSpan {
	white-space: nowrap;
}

/* @doc="Style for radio captions." */
a.multiSelectSetCaption {
	vertical-align: top;
	text-decoration: none;
	color: black;
}

/* @doc="Style for disabled radio captions." */
a.multiSelectSetCaptionDisabled {
	vertical-align: top;
	text-decoration: none;
	color: gray;
}

a.multiSelectSetCaption:link, .multiSelectSetCaption:visited, .multiSelectSetCaption:active {
}

a.multiSelectSetCaptionDisabled:link, .multiSelectSetCaptionDisabled:visited, .multiSelectSetCaptionDisabled:active {
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

	#; create hidden field to hold real value for submit
	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# value="#($zconvert(..value,"O","HTML"))#"/>>

	Set ..optionCount = 0
	Set tCaptionClass = $S(..disabled:"multiSelectSetCaptionDisabled",1:..captionClass)
	For n=1:1:$LL(tDisplayList) {
		Set ..optionCount = ..optionCount + 1
		Set tValue = $LG(tValueList,n)
		Set tText = $LG(tDisplayList,n)
		Set:tText="" tText=..emptyCaption
		Set tTitle = $P(..titleList,",",n)
		If (..layout = "vertical" ) {
			&html<<div class="multiSelectSetSpan">>
		}
		else {
			&html<<span class="multiSelectSetSpan">>
		}
		&html<<input #(..%Attr("title",..title))# type="checkbox" #(disabled)# id="#(..%MakeId("textCheckbox_"_n))#" #($S(tValue=..value:"checked=""1""",1:""))# #(..%Attr("name","r"_..index_$Case(..tuple,"":"",:"."_..tuple)))# value="#($ZCVT(tValue,"O","HTML"))#" onclick="return #(..%Self())#.clickItem(#(n)#);"/><a class="#(tCaptionClass)#" id="#(..%MakeId("caption_"_n))#" #(..%Attr("title",tTitle))# href="" onclick="#(..%Self())#.clickItem(#(n)#);return false;">#($ZCVT(tText,"O","HTML"))#</a>&nbsp;>
		If (..layout = "vertical" ) {
			&html<</div>>
		}
		else {
			&html<</span>>
		}
	}
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..valueList = "Apple,Banana,Cherry"
}

/// User click on checkbox or caption for choice; 
/// select associated button and invoke callbacks.
ClientMethod clickItem(choice) [ Language = javascript ]
{
	if (this.disabled) return false;
	if (this.readOnly) return false;

	var checkBox = this.findElement('textCheckbox_' + choice);
	zenASSERT(checkBox,'Unable to find checkbox element.',arguments);

	this.updateValue();

	// invoke user callback(s), if present
	zenInvokeCallbackMethod(this.onclick,this,'onclick');

	// notify
	this.onchangeHandler();

	return true;
}

/// Internal method to set css class used for checkbox captions.
ClientMethod setCaptionClass(cls) [ Internal, Language = javascript ]
{
	// find each caption and change CSS class
	for (var n = 0; n < this.optionCount; n++) {
		var caption = this.findElement('caption_' + ((parseInt(n,10))+1));
		if (caption) { caption.className = cls; }
	}
}

/// Internal method to compute the list of all selected options in the valueList.
/// This string is the nominal 'value' of the widget itself
ClientMethod updateValue() [ Internal, Language = javascript ]
{
	var v=[];
	var n=1;
	var checkBox = null;
	while ((checkBox = this.findElement('textCheckbox_'+n))!=null) {
		if (checkBox.checked==true) v.push(checkBox.value);
		n++;
	}
	this.value = v.join(',');
	// update hidden field	
	var hidden = this.findElement('hidden');
	zenASSERT(hidden,'Unable to find hidden element.',arguments);
	if (hidden.value != this.value) {
		hidden.value = this.value;
	}
}

/// Internal method to select or unslection all options uniformly.
ClientMethod selectUniform(flag) [ Internal, Language = javascript ]
{
	for (var n = 0; n < this.optionCount; n++) {
		var checkBox = this.findElement('textCheckbox_' + ((parseInt(n,10))+1));
		if (checkBox) {
			checkBox.checked = flag;
		}
	}
	this.updateValue();
}

/// Selects all options in the set
ClientMethod selectAll() [ Language = javascript ]
{
	this.selectUniform(true);
}

/// Deselects all options in the set
ClientMethod selectNone() [ Language = javascript ]
{
	this.selectUniform(false);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		this.value = value;
		this.selectUniform(false);
		var a=value.split(",");
		var len=a.length;
		// make sure correct buttons are selected
		var n=1;
		var checkBox = null;
		while ((checkBox = this.findElement('textCheckbox_'+n))!=null) {
			for (var i=0;i<len;i++) {
				if (checkBox.value==a[i]) {
					checkBox.checked=true;
					i=len;
				}
			}
			n++;
		}
		this.updateValue();
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
				var checkBox = this.findElement('textCheckbox_' + ((n*1)+1));
				if (checkBox) {checkBox.disabled = (this.disabled||this.readOnly); }
			}
	 		if ('disabled' == property) {
				this.setCaptionClass(this.disabled ? 'multiSelectSetCaptionDisabled' : this.captionClass);
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

ClientMethod onupdateHandler() [ Language = javascript ]
{
	if (this.value && this.value.indexOf(',')>0) this.setValue(this.value);
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.value && this.value.indexOf(',')>0) this.setValue(this.value);
}

}
