/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsPortal.EDI.X12.SchemaSegmentStructure Extends EnsPortal.EDI.X12.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "X12 Segment Structure";

Property segStruct As %String(MAXLEN = "", ZENURL = "SS");

Property docStruct As %String(MAXLEN = "", ZENURL = "DS");

Property segPath As %String(MAXLEN = "", ZENURL = "PATH");

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
	set category=$p(..segStruct,":",2)
	set structname=$p(..segStruct,":",3)

	If ((category'="")&&(structname'="")) {
		if '$D($$$vaSchemaGbl(category,"SS",structname)) {
			quit ..DrawError(..segStruct)
		}
		set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"SS",structname)))
		Set catLink = ..Link("EnsPortal.EDI.X12.SchemaMain.zen?CAT="_$$$URLENCODE(category))
		Set docLink = ..Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS="_$$$URLENCODE(..docStruct))
		&html<
			<div>
			<p>
			<i>#($$$Text("Schema Category:"))# </i><b><a href="#(catLink)#">#($zconvert(category,"O","HTML"))#</a></b><br/>
		>
		If (..docStruct '= "") {
			&html<
				<i>#($$$Text("Document Structure (Transaction Set):"))#</i>&nbsp;<b><a href="#(docLink)#">#($zconvert($P(..docStruct,":",3),"O","HTML"))#</a></b><br/>
			>
		}
		&html<
			<i>#($$$Text("Segment Structure:"))# </i><b>#($zconvert(structname,"O","HTML"))#</b><br/>
		>
		
		If $L(..segPath) {
			set pathText = $$$Text("Path you followed to get to this segment structure:")
			&html<
				<div>
					<i>#(pathText)#</i>&nbsp;<b>#($zconvert(..segPath,"O","HTML"))#</b><br/>
				</div>
				<p/>
			>
		}
		&html<
			<div>
				#($zconvert(category_":"_structname,"O","HTML"))# #($G(description))#
			</div>
			<p/>
			<table class="tpTable" cellpadding=4 cellspacing=2>
				<tr class="headers"><th>#($$$Text("Elem"))#</th>
						<th>#($$$Text("Description"))#</th>
						<th>#($$$Text("Property Name"))#</th>
						<th>#($$$Text("Data Type"))#</th>
						<th>#($$$Text("Required"))#</th>
						<th>#($$$Text("Length"))#</th>
						<th>#($$$Text("Max Repeats"))#</th>
						<th class="altDesc">#($$$Text("Alternate Description"))#</th>
				</tr>
		>

		set struct=$$$vaSchemaGbl(category,"SS",structname)
		kill names set name="" for { set name=$o($$$vaSchemaGbl(category,"SS",structname,"names",name))  quit:name=""
			set names($$$vaSchemaGbl(category,"SS",structname,"names",name))=name
		}
		for i=1:1:$LL(struct) { set one=$LI(struct,i)
			set rowClass=$S(i#2=0:"tpEven", 1:"tpOdd")
			&html<<tr class="#(rowClass)#"><td>#(i)#</td>>

			; description
			set description=..EscapeHTML($G($$$vaSchemaDescGbl(category,"SS",structname,i)))
			&html<<td>#($s(description="":"&nbsp;",1:description))#</td>>

			; property name
			set tPropPath=$S(""=$G(names(i)):"",1:..segPath_":"_$G(names(i)))_$S($li(one,6):"()",1:"")

			set label = $G(names(i),"&nbsp")
			if (..segPath="") {
				&html<<td>#(label)#</td>>
			} else {
				set segmentLink = ..Link("EnsPortal.EDI.X12.SchemaPath.zen?PATH="_$$$URLENCODE(tPropPath)_"&FIELD="_i_"&DS="_$$$URLENCODE(..docStruct)_"&SS="_$$$URLENCODE(..segStruct))
				&html<<td><a title='#(tPropPath)#' href='#(segmentLink)#'>#(label)#</a></td>>
			}

			; data type
			set value=$li(one,1)
			set title=$lg(one,6)  set:""'=title title=" title='"_$$$FormatText($$$Text("X12 Element ID: %1"),title)_"'"
			if (value="") {
				&html<<td#(title)#>&nbsp;</td>>
			} elseif "("=$e(value) {
				&html<<td#(title)#>#(value)#</td>>
			} else {
				set valueLink = ..Link("EnsPortal.EDI.X12.SchemaComponentStructure.zen?CS=CS:"_$$$URLENCODE($S(value[":":"",1:category_":")_value)_"&PATH="_$$$URLENCODE(tPropPath)_"&FIELD="_i_"&DS="_$$$URLENCODE(..docStruct)_"&SS="_$$$URLENCODE(..segStruct))
				&html<<td><a href='#(valueLink)#'>#(value)#</a></td>>
			}

			//tType,2tStdReq,3tMinLen,4tMaxLen,5tMaxUse,tActReq,tEleID
			//tType,2tMinLen,3tMaxUse,4tMaxLen,5tStdReq,tEleID,tActReq
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
			set altdesc=..EscapeHTML($G($$$vaSchemaDescGbl(category,"SS",structname,i,"alt")))
			&html<<td>#($s(altdesc="":"&nbsp;",1:altdesc))#</td>>
		}
	}
	&html<</table>>
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("X12 Segment Structure")
}

}
