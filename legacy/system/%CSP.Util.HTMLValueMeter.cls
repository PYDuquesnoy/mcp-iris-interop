/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Simple HTML-based meter that displays a value.
Class %CSP.Util.HTMLValueMeter Extends %CSP.Util.HTMLMeter [ ServerOnly = 1, System = 4 ]
{

/// Allows override of text alignment for value.
Property Align As %String(MAXLEN = 20, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "right" ];

/// Draw the style section of this HTML meter
ClassMethod OnHTMLStyle()
{
	&html<

.ValueMeterValue {
	font-size: 12px;
	font-weight: bold;
	padding-right:5px;
}

	>
}

/// Draw the script section of this HTML meter
ClassMethod OnHTMLScript()
{
	&js<
function HTMLValueMeter_setProperty(prop, value, status)
{
	if ('level' == prop) {
		var lvl = self.document.getElementById("meterValue_" + this.id);
		if (lvl) {
			if ('' == value) { 
				value = '&nbsp;'
			}
			else {
				// wrap
				value = value.replace(/\n/g,'<br>');
			}
			lvl.innerHTML = value;
		}
		
		var style =	'HTMLMeterStatus' + status;
		var tbl = self.document.getElementById("meter_" + this.id);
		if (tbl) {
			tbl.className = style;
		}

		setMeterStatus(this.id, status);
	}
	
	return true;
}	
	>
}

/// Draw the body of this HTML meter
Method OnHTMLBody()
{
	Set tTitle = $$$Text("Click to show details for this item.")
	Set tLabel = $zconvert(..Label,"O","HTML") _ $S(..Label'="":":",1:"")
	Set:tLabel="" tLabel="&nbsp;" 
	Set tValue = $zconvert(..InitialValue,"O","HTML")
	Set:tValue="" tValue="&nbsp;" 

	&html<<table class="HTMLMeterStatus#(..InitialStatus)#" 
				id="meter_#(..MeterId)#"
				style="border-bottom: 1px solid #cbcbcb; padding: 2px;"
				border="0" 
				cellpadding="0" 
				cellspacing="0" 
				width="#(..Width)#" 
				onclick="selectMeter(#(..MeterId)#);"
				>
		<tr title="#(tTitle)#" height="#(..Height)#">>

	Do ..DrawSelector()
		
	&html<<td class="HTMLMeterLabel" id="label_#(..MeterId)#" nowrap valign="top" align="left"><a href="javascript:selectMeter(#(..MeterId)#);">#(tLabel)#</a></td>
		<td class="ValueMeterValue" valign="top" align="#(..Align)#"><span id="meterValue_#(..MeterId)#">#(tValue)#</span></td>
		</tr></table>>
}

/// Called by Dashboard class to generate code to
/// create an instace of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do:(..Align'="") pCode.WriteLine(" Set tMeter.Align=""" _ ..Align _ """")
	Quit ##super(pCode,pLevel)
}

}
