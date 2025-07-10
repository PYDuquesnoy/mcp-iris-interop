/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Component.sqlParametersTable Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

Parameter DOMAIN = "Ensemble";

Property params As %String(MAXLEN = "");

Property currParamNum As %Integer [ InitialExpression = 0 ];

Property currParam As %String;

Property inParamInfo As %Boolean [ InitialExpression = 0 ];

Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property querySetting As %String;

Property query As %String;

Property classSettingName As %String;

Property containerClass As %String;

Property prependAsterix As %Integer [ InitialExpression = 0 ];

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
    <vgroup>
        <html id="htmlParams"  seed=""/>
    </vgroup>
</composite>
}

/// Get the contents of the Parameters table
Method GetContents() As %String [ ZenMethod ]
{
	#dim tCount,i As %Integer = 0
	#dim tParams,tOneParam As %String = ""
	#dim tEditable As %Boolean = 0
	#dim tHTML As %String = ""
	#dim tWidth As %Integer = 350
	
	If '..readOnly {
		Set tHTML = "<image id=""addBtn"" style=""vertical-align:middle;padding-top:5px;padding-left:10px;"" src=""deepsee/ds_plus_16.gif"" title="""_$$$Text("Add a parameter")_""" onclick=""zenPage.getComponentById('"_..id_"').addParam();""/>" _
			"<span id=""addParamTxt"" class=""zenLabel settingLabel"" style=""vertical-align:middle;padding-top:5px;padding-left:5px;"">"_$$$Text("Add")_"</span>"
	}
	Set tHTML = tHTML_"<table class=""propListTable"" style=""padding-top:6px;padding-left:2px;max-width:380px;"" border=""0"" cellspacing=""0"">"

	Set tParams = ..params
	If (""'=tParams) {
		Set tCount = $L(tParams,",")
	} ElseIf (..currParamNum = 1) {
		Set tCount = 1
	}

	If (tCount > 0) {
		If '..readOnly {
			#; subtract icon widths from tWidth to get appropriate width for text
			Set tWidth = tWidth ; add icon visible
				- (((..currParamNum > 0) && (tCount > 1)) * 34) ; modify icon visible for some row
				- 18 ; delete icon
		}
		For i=1:1:tCount {
			Set tOneParam = $P(tParams,",",i)
			Set tEditable = ('..readOnly && (..currParamNum = i))
			Set tHTML = tHTML _ 
					"<tr class='"_$Select((i#2):"rowOdd",1:"rowEven")_"'>"
			If '..readOnly {
				Set tHTML = tHTML _ 
					"<td style=""font-size:8pt;font-weight:normal;"" >["_i_"]</td><td nowrap>" _
					"<image id=""delete_"_i_""" title='"_$$$Text("Remove this parameter from the list")_"' src=""deepsee/close_a_16.gif"" alt=""Delete"" onclick=""zenPage.getComponentById('"_..id_"').uiDeleteParam("_i_",'"_..id_"');""/>" _
					"</td>" _
					"<td nowrap>" _
					"<image id=""modify_"_i_""" "_$S(tEditable:"hidden='true'",1:"")_" title='"_$$$Text("Modify this parameter")_"' src=""deepsee/notepad_16.png"" alt=""Edit"" onclick=""zenPage.getComponentById('"_..id_"').switchCurrParam("_i_");""/>" _
					"</td>"
				Set tHTML = tHTML _
					"<td nowrap>" _
					"<image id=""add_"_i_""" "_$S('tEditable:"hidden='true'",1:"")_" title='"_$$$Text("Parameter Helper Popup")_"' alt=""Helper Popup"" src=""deepsee/table_16.gif"" style=""width:20px;height:20px;"" onclick=""zenPage.getComponentById('"_..id_"').showParamInfo('"_$zcvt(tOneParam,"O","HTML")_"','"_i_"');"" />" _
					"</td>"
			}
			Set tHTML = tHTML _
				"<td id=""param_"_i_""" style=""width:"_tWidth_"px;font-size:8pt;font-weight:normal;word-break:break-all;"" "_$S(tEditable:"hidden='true' ",1:"")_">"_$zcvt(tOneParam,"O","HTML")_"</td>"
			If '..readOnly {
				Set tHTML = tHTML _
				"<td id=""txt_param_"_i_""" style=""padding-left:3px;"" "_$S('tEditable:"hidden='true'",1:"")_"><input type=""text"" style=""width:"_tWidth_"px;"" onblur=""zenPage.getComponentById('"_..id_"').switchCurrParam(0,this.value);"" value='"_$zcvt(tOneParam,"O","HTML")_"'/></td>"
			}
			Set tHTML = tHTML_"</tr>"
		}
	} ElseIf ..readOnly {
		Set tHTML = tHTML_"<tr class='rowOdd'><td id=""param"" style=""width:350px;"">&nbsp;</td></tr>"
	}
	Set tHTML = tHTML _ "</table>"

	Quit tHTML
}

ClientMethod uiDeleteParam(paramNum, id) [ Language = javascript ]
{
	var msg = $$$Text("Do you want to delete this parameter?");
	if (!confirm(msg)) return;
	zenPage.getComponentById(id).deleteParam(paramNum);
	zenPage.getComponentById(id).setModified();
	zenPage.getComponentById(id).refreshParams();
}

Method deleteParam(pNumber) As %Boolean [ ZenMethod ]
{
	#dim tParams As %String = ..params
	#dim tLenBefore As %Integer = 0

	If ""'=tParams {
		Set tCount = $L(tParams,",")
		If tCount >= pNumber {
			If pNumber > 1 {
				Set tLenBefore = $L($P(tParams,",",1,pNumber-1))
				Set $P(tParams,",",pNumber)=""
				Set tParams = ($E(tParams,1,tLenBefore)_$S(tCount'=pNumber:$E(tParams,tLenBefore+2,*),1:""))
			} ElseIf tCount > 1 {
				Set tParams = $P(tParams,",",2,*)
			} Else {
				Set tParams = ""
			}

			Set ..params = tParams
		}
	}
	#; may not necessarily be the case
	If (pNumber = ..currParamNum) {
		Set ..currParamNum = 0
	}

	Quit 1
}

ClientMethod addParam() [ Language = javascript ]
{
	var params = this.params;
	if ((""!=params) && (params.slice(-1)!=",")) {
		params = (params + ",")
		this.params = params;
	}
	this.switchCurrParam(params.split(",").length);
}

/// Refresh the table which displays the Parameters to use
ClientMethod refreshParams() [ Language = javascript ]
{
	var html = this.getChildById("htmlParams");
	if (html) {
	} else {
		var html = zenPage.createComponent('html');
		html.setProperty('id',this.id+".htmlParams");
		this.addChild(html);
	}

	var content = this.GetContents();
	html.content = content;
	
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	comp = zenPage.getComponentById(this.id);
	if ((comp != null)) {
		comp.refreshContents();
	}
	return;
}

/// Set a particular parameter to be editable
ClientMethod setCurrParam(switchTo) [ Language = javascript ]
{
	this.currParamNum = switchTo;
	this.refreshParams();
}

/// Call on Production Config page's settingChanged() so that it recognizes this change
ClientMethod setModified() [ Language = javascript ]
{
	var form = this.getForm();
	zenPage.settingChanged(this.index,(form ? form.index : ''));
}

/// If there is a parameter being edited, save that first before making another parameter editable
/// Then set the new parameter to be editable
ClientMethod switchCurrParam(switchTo, value) [ Language = javascript ]
{
	var current = this.currParamNum;
	if (current != switchTo) {
		if ((current > 0) && (value != null)) {
			var x = this.saveParam(current,value);
		}

		this.setModified();
	}
	this.setCurrParam(switchTo);

	return;
}

Method saveParam(pNumber As %Integer, pValue As %String = "") As %Boolean [ ZenMethod ]
{
	#dim tParams As %String = ..params

	If ""'=pValue {
		Set $P(tParams,",",pNumber) = pValue

		Set ..params = tParams	

	} Else {
		Do ..deleteParam(pNumber)
	}

	Quit 1
}

/// User clicked the Browse button.
/// Helper method to wrap the main helper popup() function in the containing page (Production Config).
ClientMethod showParamInfo(param, paramnum) [ Language = javascript ]
{

	var queryId = 'sett'+this.querySetting;
	var relatedQueryCtl = zenPage.getComponentById(queryId);
	if (relatedQueryCtl) {
		this.query = relatedQueryCtl.getValue()
	}
	var containerClassId = 'sett'+this.classSettingName;
	var relatedcontainerClassCtl = zenPage.getComponentById(containerClassId);
	if (relatedcontainerClassCtl) {
		this.containerClass = relatedcontainerClassCtl.getValue()
	}
	var parms = {
		QUERY:this.query,
		CONTAINER:this.containerClass,
		QUERYPARAM:param,
		QUERYPARAMNUM:paramnum,
		PREPENDASTERIX: this.prependAsterix
	};
	if (zenPage && (typeof zenPage.selectParam == 'function')) {
		if ((param != null) && (param != "")) {
			this.currParam = param;
		} else {
			this.currParam = '';
		}
		this.inParamInfo = 1;
		zenPage.selectParam(this.index,parms);
	}
}

ClientMethod getForm() [ Language = javascript ]
{
	var form = null;
	var parent = this.parent;
	while (parent) {
		if (parent.isOfType('form') || parent.isOfType('loginForm')) {
			form = parent;
			break;
		}
		parent = parent.parent;
	}
	return form;
}

ClassMethod GetParamsToDisplay(pParams = "") As %String [ ZenMethod ]
{
	Quit pParams
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
	case 'disabled':
		this.readOnly = value;
		this.refreshParams();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return the value of a named property (i.e. a setting).<br>
/// Returns null if this is not a property of this object.<br>
/// <var>key</var> is an optional argument used for properties
/// (such as collections) that may need a key to find a specific value.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		return this.readOnly;
		break;
	case 'value':
		return this.getValue();
		// no break;
	default:
		// dispatch
		return this.invokeSuper('getProperty',arguments);
	}
}

/// Client-side method to set the value associated with this control.
/// <var>value2</var> is an optional, second parameter used by some controls
/// (such as <class>dataCombo</class>).
ClientMethod setValue(value, value2) [ Final, Language = javascript ]
{
	if (this.currParamNum && (this.currParamNum > 0)) {
		this.saveParam(this.currParamNum,value);
		this.refreshParams();
	} else if (this.params == "") {
		this.params = this.GetParamsToDisplay(value);
		this.refreshParams();
	}
}

ClientMethod getValue() [ Final, Language = javascript ]
{
	if (this.inParamInfo) {
		this.inParamInfo = 0;
		return this.currParam;
	} else {
		return this.params;
	}
}

/// Create children on client side so we can use them immediately. Note that the server may substitute fresh code-generated objects later.
ClientMethod createChildren(form) [ Language = javascript ]
{
	var html = zenPage.createComponent('html');
	html.setProperty('id',this.id+".htmlParams");

	// override refreshContents() to ensure we don't call back to the server
	html.refreshContents = function() {
		var div = this.getEnclosingDiv();
		if (div) div.innerHTML = this.content;
	};

	this.addChild(html);

	this.childrenCreated = true;

	return '';
}

}
