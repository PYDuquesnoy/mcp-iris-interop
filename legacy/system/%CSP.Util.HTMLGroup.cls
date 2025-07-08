/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
Class %CSP.Util.HTMLGroup Extends %CSP.Util.HTMLMeter [ ServerOnly = 1, System = 4 ]
{

/// Meters belonging to this group
Property Meters As list Of HTMLMeter(XMLNAME = "Meters", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Direction in which to layout meters within this group.
Property Orientation As %String(MAXLEN = 10, VALUELIST = ",horizontal,vertical", XMLPROJECTION = "attribute") [ InitialExpression = "horizontal" ];

/// Style to use for Group
Property Style As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Insert a meter into this group
Method InsertMeter(pMeter As HTMLMeter)
{
	Do ..Meters.Insert(pMeter)
	Set pMeter.Parent = $this
}

/// Draw the style section of this HTML meter
ClassMethod OnHTMLStyle()
{
	&html<
table.HTMLGroup {
	
}

.HTMLGroupLabel {
	background: #F7F7F7;
	border-bottom: #cbcbcb solid 1px; 
	color: #000000;
	font-weight: 600;
	font-size: 14px;
	padding: 2px;
	text-align: left;
	padding-left: 20px;
	text-transform: uppercase;
}
.HTMLGroupInit {
	width: 100%;
	font-size: 12px;
}
	>
}

Method OnHTMLBody()
{
	Set style = ..Style
	If style = "Standard" {
		Set style = "border: 1px #cbcbcb solid; border-radius:5px;"	
	}
	&html<<table class="HTMLGroup" style="#(style)#" border="0" cellspacing="0" cellpadding="0" width="#(..Width)#">>
	If (..Orientation = "horizontal") {
		&html<<tr valign="top">>
		If (..Label '= "") {
			&html<<td class="HTMLGroupLabel" nowrap>#($ZCVT(..Label,"O","HTML"))#</td>>
		}
				
		// Draw meter horizontally
		For i = 1:1:..Meters.Count() {
			Set tMeter = ..Meters.GetAt(i)
			&html<<td width="#(tMeter.Width)#">>
			Do tMeter.OnHTMLBody()
			&html<</td>>
		}
		&html<</tr>>
	}
	Else {
		If (..Label '= "") {
			&html<<tr><td width="100%" nowrap class="HTMLGroupLabel">#($ZCVT(..Label,"O","HTML"))#</td></tr>>
		}
		// Draw meters vertically
		For i = 1:1:..Meters.Count() {
			Set tMeter = ..Meters.GetAt(i)
			&html<<tr><td class="HTMLGroupInit">>
			Do tMeter.OnHTMLBody()
			&html<</td></tr>>
		}
	}

	&html<</table>>
}

Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Set %code = pCode

	Set tVar = "tGroup" _ pLevel
	Do %code.WriteLine(" Set "_tVar_" = tMeter")
	Do:(..Label'="") pCode.WriteLine(" Set "_tVar_".Label=$$$Text(""" _ ..Label _ """)")
	Do:(..Property'="") pCode.WriteLine(" Set "_tVar_".Property=""" _ ..Property _ """")
	Do:(..Orientation'="") pCode.WriteLine(" Set "_tVar_".Orientation=""" _ ..Orientation _ """")
	Do:(..Width'="") pCode.WriteLine(" Set "_tVar_".Width=" _ ..Width)
	Do:(..Height'="") pCode.WriteLine(" Set "_tVar_".Height=" _ ..Height)
	Do:(..Style'="") pCode.WriteLine(" Set "_tVar_".Style=""" _ ..Style _ """")

	#; Generate code for each Meter within this group
	For i=1:1:..Meters.Count() {
		Set tMeter = ..Meters.GetAt(i)
		Do %code.WriteLine(" // " _ tMeter.%ClassName(1))
		Do %code.WriteLine(" Set tMeter = ##class(" _ tMeter.%ClassName(1) _ ").%New()")
		Do %code.WriteLine(" Do "_tVar_".InsertMeter(tMeter)")
		Do %code.WriteLine(" Set tMeter.Dashboard = "_tVar_".Dashboard")
		
		// default value of label		
		If (tMeter.Label = "") {
			Set tMeter.Label = tMeter.Property
		}

		Set tSC = tMeter.GenerateCode(%code, pLevel + 1)
		If $$$ISERR(tSC) Quit
	}

	Quit $$$OK
}

}
