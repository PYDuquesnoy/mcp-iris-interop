/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsPortal.EDI.X12.SchemaCodeTable Extends EnsPortal.EDI.X12.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "X12 Code Table";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css,ensemble/Ensemble_EDI.css";

Property cTable As %String(MAXLEN = "", ZENURL = "CT");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="20"/>
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
	Set category = $P(..cTable,":",2)
	Set structname = $P(..cTable,":",3)
	If ((category'="")&&(structname'="")) {
		If '$D($$$vaSchemaDescGbl(category,"CT",structname)) {
			Quit ..DrawError(..cTable)
		}
		Set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"CT",structname)))
		Set catLink = ..Link("EnsPortal.EDI.X12.SchemaMain.zen?CAT="_$$$URLENCODE(category))
		&html<
		<div>
		<p>
		<i>#($$$Text("Schema Category:"))# </i><b><a href="#(catLink)#">#($zconvert(category,"O","HTML"))#</a></b><br/>
		<i>#($$$Text("Code Table:"))# </i><b>#($zconvert(structname,"O","HTML"))#</b><br/>
		<i>#($$$Text("Description:"))# </i><b>#($G(description))#</b><br/>
		</p>
		</div>
		<table class="tpTable" cellpadding=4 cellspacing=2>
		<tr><th>#($$$Text("Code"))#</th><th>#($$$Text("Meaning"))#</th></tr>
		>
		Kill indexed
		Set one=""  For { Set one=$O($$$vaSchemaGbl(category,"CT",structname,one))  Quit:one=""
			Set indexed($$$vaSchemaGbl(category,"CT",structname,one))=one
		}
		If '$D(indexed) {
			&html<<tr class="tpEven"><td class="csetName">...</td><td>#($$$Text("No suggested values"))#</td></tr>>
		} Else {
			Set rownum=1
			Set i=""  For { Set i=$O(indexed(i))  Quit:i=""
				set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"CT",structname,indexed(i))))
				set showDesc = $S(description="":"&nbsp;",1:description)

				#; Make sure that the showDesc is not too long; 88 chars is a good length for one line; put in line breaks if it's too long
				Set showDesc = ..putCarriageReturnsIn(showDesc)

				Set rowClass=$S(rownum#2:"tpOdd",1:"tpEven")
				&html<<tr class="#(rowClass)#"><td class="csetName">#(indexed(i))#</td><td>#(showDesc)#</td></tr>>
				Set rownum = rownum + 1
			}
		}
	}
	&html<</table>>
	Quit $$$OK
}

ClassMethod putCarriageReturnsIn(line As %String) As %String
{
	set maxLength = 90
	set lineLength =$l(line)
	set charsLeft = lineLength
	set curPosition = 0

	while (charsLeft > maxLength) {
		set brLocation = $F(line," ",curPosition + maxLength) - 1 //-1 offset because this function returns the char *after* the space
		quit:(brLocation=-1)
		//now, replace that location with a <br>
		set $E(line, brLocation) = "<br>"
		//set the current position to the location of the br, and go through the loop
		//until the line length is less than the maximum number of characters
		set curPosition = brLocation
		set charsLeft = lineLength - curPosition  
	}
	quit line
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("X12 Code Table")
}

}
