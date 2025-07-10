/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsPortal.EDI.X12.SchemaComponentStructure Extends EnsPortal.EDI.X12.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "X12 Composite Structure";

Property docStruct As %String(MAXLEN = "", ZENURL = "DS");

Property segPath As %String(MAXLEN = "", ZENURL = "PATH");

Property segStruct As %String(MAXLEN = "", ZENURL = "SS");

Property segField As %String(MAXLEN = "", ZENURL = "FIELD");

/// Composite Structure
Property cStruct As %String(MAXLEN = "", ZENURL = "CS");

Property dField As %String(MAXLEN = "", ZENURL = "CSFIELD");

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
	set category=$P(..cStruct,":",2)
	set structname=$P(..cStruct,":",3)

	If ((category'="")&&(structname'="")) {
		if '$D($$$vaSchemaGbl(category,"CS",structname)) {
			quit ..DrawError(..cStruct)
		}
		set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"CS",structname)))
		Set catText=$$$Text("Schema Category:")
		Set catLink = ..Link("EnsPortal.EDI.X12.SchemaMain.zen?CAT="_$$$URLENCODE(category))
		Set compText = $$$Text("Composite Structure:")
		
		&html<
			<div>
			<p>
			<i>#(catText)# </i><b><a href="#(catLink)#">#($zconvert(category,"O","HTML"))#</a></b><br/>
		>
		If (..docStruct '= "") {
			set docText = $$$Text("Document Structure (Transaction Set):")
			Set docLink = ..Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS="_$$$URLENCODE(..docStruct))
			&html<
				<i>#(docText)#</i>&nbsp;<b><a href="#(docLink)#">#($zconvert($P(..docStruct,":",3),"O","HTML"))#</a></b><br/>
			>
		}
		If (..segStruct '= "") {
			Set fieldText = $$$Text("Field Number:")
			set segText = $$$Text("Segment Structure:")
			Set segLink = ..Link("EnsPortal.EDI.X12.SchemaSegmentStructure.zen?SS="_$$$URLENCODE(..segStruct))
			&html<
				<i>#(segText)#</i>&nbsp;<b><a href="#(segLink)#">#($zconvert($P(..segStruct,":",3),"O","HTML"))#</a></b><br/>
				<i>#(fieldText)#</i>&nbsp;<b>#($zconvert(..segField,"O","HTML"))#</a></b><br/>
			>
		}
		&html<
			<i>#(compText)#</i>&nbsp;<b>#($zconvert(structname,"O","HTML"))#</b>
			</p>
		>
		If $L(..segPath) {
			set pathText = $$$Text("Path you followed to get to this composite structure:")
			&html<
				<p>
				<i>#(pathText)#</i>&nbsp;<b>#($zconvert(..segPath,"O","HTML"))#</b>
				</p>
			>
		}
		&html<
			<div>
				#($zconvert(category_":"_structname,"O","HTML"))# #($G(description))#
			</div>
			<p/>
			<table class="tpTable" cellpadding=4 cellspacing=2>
				<tr class="headers">
						<th>#($$$Text("Elem"))#</th>
						<th>#($$$Text("Description"))#</th>
						<th>#($$$Text("Property Name"))#</th>
						<th>#($$$Text("Data Type"))#</th>
						<th>#($$$Text("Required"))#</th>
						<th>#($$$Text("Length"))#</th>
						<th>#($$$Text("Max Repeats"))#</th>
						<th class="altDesc">#($$$Text("Alternate Description"))#</th>
				</tr>
		>
		set struct=$$$vaSchemaGbl(category,"CS",structname)
		kill names set name="" for { set name=$O($$$vaSchemaGbl(category,"CS",structname,"names",name))  quit:name=""
			set names($$$vaSchemaGbl(category,"CS",structname,"names",name))=name
		}
		for i=1:1:$LL(struct) { set one=$LI(struct,i)
			set rowClass=$S(i#2=0:"tpEven", 1:"tpOdd")
			&html<<tr class="#(rowClass)#"><td>#(i)#</td>>

			; description
			set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"CS",structname,i)))
			&html<<td>#($s(description="":"&nbsp;",1:description))#</td>>

			; property name
			set tPropPath=$S(""=..segPath||(""=$G(names(i))):"",1:..segPath_"."_$G(names(i)))
			set label = $G(names(i),"&nbsp")
			if (tPropPath="") {
				&html<<td>#(label)#</td>>
			} else {
				set segmentLink = ..Link("EnsPortal.EDI.X12.SchemaPath.zen?PATH="_$$$URLENCODE(tPropPath)_"&CS="_$$$URLENCODE(..cStruct)_"&CSFIELD="_i_"&FIELD="_$$$URLENCODE(..segField)_"&DS="_$$$URLENCODE(..docStruct)_"&SS="_$$$URLENCODE(..segStruct))
				&html<<td><a title='#(tPropPath)#' href='#(segmentLink)#'>#(label)#</a></td>>
			}
			; data structure:
			set value=$LI(one,1) 
			set title=$lg(one,6)  set:""'=title title=" title='"_$$$FormatText($$$Text("X12 Element ID: %1"),title)_"'"
			if (value="") {
				&html<<td#(title)#>&nbsp;</td>>
			} elseif "("=$e(value) {
				&html<<td#(title)#>#(value)#</td>>
			} else {
				set valueLink = ..Link("EnsPortal.EDI.X12.SchemaComponentStructure.zen?CS=CS:"_$$$URLENCODE($S(value[":":"",1:category_":")_value)_"&PATH="_$$$URLENCODE(tPropPath)_"&FIELD="_i_"&DS="_$$$URLENCODE(..docStruct)_"&SS="_$$$URLENCODE(..segStruct))
				&html<<td><a href='#(valueLink)#'>#(value)#</a></td>>
			}
			; required
			set value=$li(one,5)
			if (value ="") {
				&html<<td>&nbsp;</td>>
			} else {
				set title=$lg(one,7)  set:""'=title title=" title='"_$$$FormatText($$$Text("Union of Actual Requirements: %1"),$Case(title,".":"x",:title))_"'"
				&html<<td#(title)#>#(value)#</td>>
			}

			; min/max length
			set max=$li(one,4), min=$li(one,2)
			set value=min_$case(max,"":"+",min:"",:"-"_max) ; min+ if no max, single value if min/max same, range if different
			&html<<td>#($case(value,"":"&nbsp;","0+":"&nbsp;",:value))#</td>>
			
			; max reps
			set value=$li(one,3) &html<<td class="repeatCol">#($s(value="":"&nbsp;",1:value))#</td>>

			; alternate description
			set altdesc=..EscapeHTML($G($$$vaSchemaDescGbl(category,"CS",structname,i,"alt")))
			&html<<td>#($S(altdesc="":"&nbsp;",1:altdesc))#</td>>
		}
	}
	&html<</table>>
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("X12 Composite Structure")
}

}
