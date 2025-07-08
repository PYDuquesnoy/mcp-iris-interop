/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// fieldSet group. Enclose a set of controls within an
/// HTML FieldSet.
Class %ZEN.Component.fieldSet Extends group [ Deprecated, System = 3 ]
{

Parameter DEFAULTGROUPCLASS = "fieldset";

Parameter DEFAULTLAYOUT = "vertical";

/// Legend of the fieldSet. This is the caption displayed
/// for the field set.
Property legend As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// Title of the fieldSet. This is a popup message displayed
/// for the field set.
Property title As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

XData Style
{
<style type="text/css">
/* @doc="Style for fieldSet." */
.fieldSet {
}

.fieldSet legend {
}

/* @doc=="Style for disabled fieldSet." */
.fieldSetDisabled {
	color: #101010;
	background: #E0E0E0;
}

/* @doc=="Style for disabled fieldSet legend." */
.fieldSetDisabled legend {
	color: #101010;
	background: #E0E0E0;
}

</style>
}

Method %DrawHTML()
{
	Set tTitle = $$$ZENVALHTML(..title)
	Set tLegend = $$$ZENVALHTML(..legend)
	Set cls = $S(..disabled:"fieldSetDisabled",1:"fieldSet")
	&html<<fieldset id="#(..%MakeId("fieldset"))#" class="#(cls)#">>
	If tLegend'="" {
		&html<<legend id="#(..%MakeId("legend"))#" title="#($zcvt(tTitle,"O","HTML"))#">#($zcvt(tLegend,"O","HTML"))#</legend>>
	}

	#; let group handle the details of layout
	Do ..%LayoutChildren(..tuple)

	&html<</fieldset>>
}

/// Notifation that our disabled state has changed.
ClientMethod ondisabledHandler() [ Language = javascript ]
{
	var fs = this.findElement('fieldset');
	
	// IE support greying out;
	fs.disabled = this.disabled;
	fs.className = this.disabled ? 'fieldSetDisabled' : 'fieldSet';
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'legend':
		var lgd = this.findElement('legend');
		this.legend = value;
		if (lgd) {
			lgd.innerHTML = zenEscapeHTMLSafe(value);
		}
		break;
	case 'title':
		var lgd = this.findElement('legend');
		this.title = value;
		if (lgd) {
			lgd.title = value;
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
