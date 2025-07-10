/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsPortal.EDI.X12.SchemaPath Extends EnsPortal.EDI.X12.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "X12 Schema Path";

Property segPath As %String(MAXLEN = "", ZENURL = "PATH");

Property docStruct As %String(MAXLEN = "", ZENURL = "DS");

Property segStruct As %String(MAXLEN = "", ZENURL = "SS");

Property segField As %String(MAXLEN = "", ZENURL = "FIELD");

Property cStruct As %String(MAXLEN = "", ZENURL = "CS");

Property cStructField As %String(MAXLEN = "", ZENURL = "CSFIELD");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top">
<spacer width="20"/>
<html id="content" OnDrawContent="DrawContent"/>
<spacer width="20"/>
</hgroup>
</pane>
}

/// Draw main HTML content for this page.
Method DrawContent(pSeed As %String) As %Status
{
	set category = $p(..docStruct,":",2)
	set structname = $p(..docStruct,":",3)

	if ((category'="")&&(structname'="")) {
		if '$data($$$vaSchemaGbl(category,"DS",structname)) {
			quit ..DrawError(..docStruct)
		}
		set description=..EscapeHTML(##class(EnsLib.EDI.X12.Schema).GetDescription(..docStruct))
	}

	set pathText = $$$Text("Path you followed to get to this field:")
	set compText = $$$Text("of Composite Structure")
	set fieldText = $$$Text("at Field")
 	set segText = $$$Text("of Segment Structure")
	set docText = $$$Text("of Document Structure")
	if $L(..segPath) {
		&html<<div>
			<i>#(pathText)#</i>&nbsp;<b>#($zconvert(..segPath,"O","HTML"))#</b><br/>
		>
		If $L(..cStruct) {
			&html<
				<i>#(fieldText)#</i>&nbsp;<b>#($zconvert(..cStructField,"O","HTML"))#</b><br/>
				<i>#(compText)#</i>&nbsp;<b>#($zconvert($P(..cStruct,":",2,3),"O","HTML"))#</b><br/>
			>
		}
		If $L(..segStruct) {
			&html<
				<i>#(fieldText)#</i>&nbsp;<b>#($zconvert(..segField,"O","HTML"))#</b><br/>
				<i>#(segText)#</i>&nbsp;<b>#($zconvert($P(..segStruct,":",2,3),"O","HTML"))#</b><br/>
			>
		}
		If $L(..docStruct) {
			&html<
				<i>#(docText)#</i>&nbsp;<b>#($zconvert($P(..docStruct,":",2,3),"O","HTML"))#</b><br/>
			>
		}
		&html<
			</div>
		>
	}

	&html<<br/>>
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("X12 Schema Path")
}

}
