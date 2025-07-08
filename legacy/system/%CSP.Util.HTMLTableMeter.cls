/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Simple HTML-based meter that displays a table.
Class %CSP.Util.HTMLTableMeter Extends %CSP.Util.HTMLMeter [ ServerOnly = 1, System = 4 ]
{

/// Number of rows in table
Property Rows As %Integer(MINVAL = 1, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// Names of columns (csv string)
Property ColumnNames As %String(MAXLEN = 200, XMLPROJECTION = "ATTRIBUTE");

/// Draw the style section of this HTML meter
ClassMethod OnHTMLStyle()
{
	&html<
	
table.HTMLTableMeter {
	border-top: 1px solid #cbcbcb;
	border-left: 1px solid #cbcbcb;
	font-size: 1.0em;
}

table.HTMLTableMeter th {
	padding-left: 2px;
	border-bottom: 1px solid #cbcbcb;
	border-right: 1px solid #cbcbcb;
	font-weight: bold;
	text-align: left;
}

table.HTMLTableMeter td {
	padding-left: 2px;
	border-bottom: 1px solid #cbcbcb;
	border-right: 1px solid #cbcbcb;
}

	>
}

/// Draw the script section of this HTML meter
ClassMethod OnHTMLScript()
{
	&js<
function HTMLTableMeter_setProperty(prop, value, status)
{
	if ('level' == prop) {
		// split value into rows and cols
		var rvals = value.split('^');
		for (var r = 0; r != rvals.length; r++) {
			var cvals = rvals[r].split(';');
			for (var c = 0; c != cvals.length; c++) {
				var td = self.document.getElementById("cell_" + this.id + "_" + (r+1) + "_" + (c+1));
				if (td) {
					td.innerHTML = cvals[c] + '&nbsp;';
				}
			}
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
	Set tLabel = ..Label _ $S(..Label'="":":",1:"")
	Set:tLabel="" tLabel="&nbsp;" 
	Set tValue = ..InitialValue
	Set:tValue="" tValue="&nbsp;" 

	&html<<table class="HTMLMeterStatus#(..InitialStatus)#" 
				id="meter_#(..MeterId)#"
				style="border-top: 1px solid #cbcbcb; padding: 0px;"
				border="0" 
				cellpadding="0" 
				cellspacing="0" 
				width="#(..Width)#" 
				onclick="selectMeter(#(..MeterId)#);"
				>
		<tr title="#(tTitle)#" xheight="#(..Height)#">>

	Do ..DrawSelector()
	
	&html<<td valign="top" class="HTMLMeterLabel" id="label_#(..MeterId)#" nowrap valign="top" align="left"><a href="javascript:selectMeter(#(..MeterId)#);">#($ZCVT(tLabel,"O","HTML"))#</a><br>
		<table class="HTMLTableMeter" border="0" cellspacing="0" cellpadding="0" width="100%">>
	&html<<tr>>
		For c = 1:1:$L(..ColumnNames,",") {
			&html<<th>#($ZCVT($P(..ColumnNames,",",c),"O","HTML"))#</th>>
		}
	&html<</tr>>

	For r = 1:1:..Rows {
		&html<<tr>>
		Set rVal = $P(tValue,"^",r)
		For c = 1:1:$L(..ColumnNames,",") {
			Set cVal = $P(rVal,";",c)
			Set align = $S(c=1:"left",1:"right")
			&html<<td align="#(align)#" style="color: darkblue;" id="cell_#(..MeterId)#_#(r)#_#(c)#">#(cVal)#&nbsp;</td>>
		}
		&html<</tr>>
	}

	&html<</table></td>>
	&html<</tr></table>>
}

/// Called by Dashboard class to generate code to
/// create an instace of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do pCode.WriteLine(" Set tMeter.Rows=" _ ..Rows)
	Do pCode.WriteLine(" Set tMeter.ColumnNames=$$$Text(""" _ ..ColumnNames _ """)")
	Quit ##super(pCode,pLevel)
}

}
