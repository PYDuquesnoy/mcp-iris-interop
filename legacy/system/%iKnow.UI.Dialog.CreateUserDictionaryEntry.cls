/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.UI.Dialog.CreateUserDictionaryEntry Extends %CSP.UI.Portal.Dialog.WizardTemplate [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter AUTONS As BOOLEAN = 1;

Parameter DOMAIN = "%iKnow";

/// Security requirement
Parameter RESOURCE = "%Development";

/// DOCBOOK Topic Id that offers help for this page.
Parameter HELPID As STRING;

Property dictionary As %ZEN.Datatype.string(ZENURL = "DIC");

XData Style
{
<style type="text/css">
/* @doc="Style for captions." */
a.multiSelectSetCaption {
	font-size: 12px;
}
/*table, th, td {
    border: 1px solid black;
}*/
/*td
{
    padding:0 15px 0 15px;
}*/
.form-checkbox
{
  float:left;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<hgroup>
<html id="html" OnDrawContent="DrawDictionary" />
</hgroup>
</pane>
}

Method DrawDictionary(pSeed As %String = ":t") As %Status
{
	set tSC = $$$OK
	try {
		set tIterator = ##class(%DynamicObject).%FromJSON(..dictionary).%GetIterator()
		
		
		write !,"<table style=""cellpadding:3px;"">"
		write !,"<tr><th width=""150"">"_$$$Text("String")_"</th><th width=""100"">"_$$$Text("Action")_"</th><th width=""150"">"_$$$Text("Value")_"</th><th>Metadata</th><th>&nbsp;</th></tr>"
		
		while tIterator.%GetNext(,.tEntry) {
			write !,"<tr><td>",$zcvt(tEntry.f,"O","HTML"),"</td>"
			if tEntry.%IsDefined("t") {
				write "<td>",$$$Text("rewrite to"),"</td><td>",$zcvt(tEntry.t,"O","HTML"),"</td>"
			} else {
				write "<td>",$$$Text("assign label"),"</td><td>",$zcvt(tEntry.l,"O","HTML"),"</td><td>",$s(tEntry.m'="":"metadata: "_$zcvt(tEntry.m,"O","HTML"),1:"&nbsp;"),"</td>"
			}
			write "<td><button caption=""",$$$Text("remove"),""" onclick=""zenPage.removeRowClient("_$i(i)_");"">",$$$Text("remove"),"</button></td></tr>"
		}
		
		set tString = $piece(pSeed,":",1,*-1), tAction = $piece(pSeed,":",*)
		
		write !,"<tr><td><input type=""text"" placeholder=""string"" id=""txtString"" value="""_tString_""" /></td>"
		write !,"<td><select id=""selAction"" onchange=""var sc = zen('html').setProperty('seed', document.getElementById('txtString').value+':'+this.value); zen('html').refreshContents();"" ><option value=""t""",$s(tAction'="l":" selected=""selected""", 1:""),">"_$$$Text("rewrite to")_"</option><option value=""l""",$s(tAction="l":" selected=""selected""", 1:""),">"_$$$Text("assign label")_"</option></select></td>"
		if (tAction '= "l") {
			write !,"<td><input type=""text"" placeholder=""new string"" id=""txtValue"" /></td>"
		} else {
			write !,"<td><select id=""txtValue"">",
					"<option value=""UDNegation"">negation</option>",
					"<option value=""UDPosSentiment"">positive sentiment</option>",
					"<option value=""UDNegSentiment"">negative sentiment</option>",
					"<option value=""UDConcept"">concept</option>",
					"<option value=""UDRelation"">relation</option>",
					"<option value=""UDCertainty"">certainty</option>",
					"<option value=""UDNumber"">number (measurements)</option>",
					"<option value=""UDUnit"">unit (measurements)</option>",
					"<option value=""UDTime"">time</option>",
					"<option value=""UDGeneric1"">generic attribute 1</option>",
					"<option value=""UDGeneric2"">generic attribute 2</option>",
					"<option value=""UDGeneric3"">generic attribute 3</option>",
					"<option value=""UDSentenceEnd"">sentence ending</option>",
					"<option value=""UDSentenceNoEnd"">prevent sentence ending</option>",
					"</select></td>"
			write !,"<td><input type=""text"" title=""attribute metadata"" id=""txtMeta"" /></td>"

		}
		write !,"<td><button caption="""_$$$Text("add")_""" onclick=""zenPage.addRowClient();"">"_$$$Text("add")_"</button></td></tr>"
		
		write !,"</table>"
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod addRowClient() [ Language = javascript ]
{
	var action = document.getElementById('selAction').value;
	var string = document.getElementById('txtString').value;
	var value = document.getElementById('txtValue').value;
	var meta = document.getElementById('txtMeta').value;
	var sc = zenPage.AddRow(string, action, value, meta);
	sc = zen('html').setProperty('seed', ':'+action);
	zen('html').refreshContents();
}

Method AddRow(pString, pAction, pValue, pMeta = "") As %Status [ ZenMethod ]
{
	set tDictionary = ##class(%DynamicObject).%FromJSON(..dictionary)
	if (pAction'="l") {
		do tDictionary.%Push({ "f": (pString), "t" : (pValue) })
	} else {
		do tDictionary.%Push({ "f": (pString), "l" : (pValue), "m" : ($g(pMeta)) })
	}
	set ..dictionary = tDictionary.%ToJSON()
	quit $$$OK
}

ClientMethod removeRowClient(index) [ Language = javascript ]
{
	var sc = zenPage.RemoveRow(index);
	zen('html').refreshContents();
}

Method RemoveRow(pIndex As %Integer) As %Status [ ZenMethod ]
{
	set tIterator = ##class(%DynamicObject).%FromJSON(..dictionary).%GetIterator()
	set tNew = []
	while tIterator.%GetNext(,.tEntry) {
		if pIndex '= $i(i) {
			do tNew.%Push(tEntry)
		}
	}
	set ..dictionary = tNew.%ToJSON()
	quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Manage User Dictionary")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(zenPage.getProperty('dictionary'));
}

/// Show definition based on type
/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

}
