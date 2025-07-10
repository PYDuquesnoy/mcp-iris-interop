/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsPortal.EDI.X12.SchemaDocumentStructure Extends EnsPortal.EDI.X12.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "X12 Document Structure";

Property docStruct As %String(MAXLEN = "", ZENURL = "DS");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top">
<spacer width="20"/>
<vgroup valign="top">
<html id="content" OnDrawContent="DrawContent"/>
</vgroup>
<spacer width="20"/>
</hgroup>
</pane>
}

/// Draw main HTML content for this page.
Method DrawContent(pSeed As %String) As %Status
{
	Set category=$P(..docStruct,":",2)
	Set structname=$P(..docStruct,":",3)
	If ((category'="")&&(structname'="")) {
		Quit:'$D($$$vaSchemaGbl(category,"DS",structname)) ..DrawError(..docStruct)
		Set description=..EscapeHTML(##class(EnsLib.EDI.X12.Schema).GetDescription(..docStruct,,1))
		Set impGuide=$G($$$vaSchemaDescGbl(category,"DS",structname,"alt"),category)
	} Else {
		Set description=$$$TextHTML("Category and structure name missing. Unable to display definition.")
		Set impGuide=""
	}
	Set tCat=$$$Text("Schema Category")
	Set tDS=$$$Text("Document Structure (TransactionSet)")
	Set tIG=$$$Text("Implementation Guide")
	Set catLink = ..Link("EnsPortal.EDI.X12.SchemaMain.zen?CAT="_$$$URLENCODE(category))

	&html<
		<div>
		<p>
		<I>#(tCat)# : </I><b><a href="#(catLink)#">#($zconvert(category,"O","HTML"))#</a></b><br/>
		<I>#(tDS)# : </I><b>#($zconvert(structname,"O","HTML"))#</b><br/>
		<I>#(tIG)# : </I><b>#(impGuide)#</b>
		</p>
		<p>#(description)#</p>
		</div>
	>
	Quit:((category="")||(structname="")) $$$OK

	&html<<div><hr/><table><tr>>

	#; Draw segments table
	&html<<td><table cellpadding=2 cellspacing=2><tbody align=center><tr>>
	New %iSeg,%hadUnion,%hadGroup  Set (%iSeg,%hadUnion,%hadGroup)=0
	Do ..drawArray(category,$Name($$$vaSchemaGbl(category,"DS",structname,"array")),"")
	&html<</table></td>>

	#; Draw legend
	Set tOpt = $$$Text("optional")
	Set tRep = $$$Text("repeating")
	Set tKey = $$$Text("Key")
	&html<<td valign='top'><div style="padding-left:50px;"><b>#(tKey)#</b><table cellpadding=4 cellspacing=2>>
	If %hadGroup {
		Set tGroup= $$$Text("group")
		&html<<tr><td style="border: 2px solid #ead960; border-right: none;" cellpadding=2 cellspacing=2>#(tGroup)#</td></tr>>
	}
	&html<<tr><td style="border: 2px dotted #3b9c3d; border-right: none;" cellpadding=2 cellspacing=2>#(tOpt)#</td></tr>>
	&html<<tr><td style="border: 2px solid #703838; border-right: none;" cellpadding=2 cellspacing=2>#(tRep)#</td></tr>>

	If %hadUnion {
		Set tUnion = $$$Text("choice")
		&html<<tr><td style="border: 2px dotted #ead960; border-right: none;" cellpadding=2 cellspacing=2>#(tUnion)#</td></tr>>
	}
	&html<</table></div>>

	#; Draw links
	&html<<td valign='top'><div class="footlinks">
	<span><img src="images/spacer.gif" width="30" height="2"><img src="images/disclosure-contracted.gif" alt="*" width="8" height="11" border="0">
	<span onclick="zenPage.showRaw();"><a href="#" onclick="return false;" title='#($$$TextHTML("Show the text string that defines the nested looping structure of this document type"))#'>#($$$TextHTML("Show Raw Definition Text"))#</a></span></span><br/>
	<img src="images/spacer.gif" width="30" height="2"><img src="images/disclosure-contracted.gif" alt="*" width="8" height="11" border="0">>
	if ..isOnlyNew(..docStruct) {
		&html<
		<span onclick="alert('No SEF Validation Structures are loaded for this schema category');">
		<a href="#" onclick="return false;" title='#($$$TextHTML("No SEF Validation Structures are loaded for this schema category"))#'>#($$$TextHTML("Go to Validation Structure"))#</a>
		</span><br>
		</div>>
	}
	else {
		&html<
		<a href="#(..Link("EnsPortal.EDI.ValidationStructure.zen?DocType="_..EscapeURL(category_":"_structname)))#" title='#($$$TextHTML("View the SEF Validation Structure for this document type"))#'>#($$$TextHTML("Go to Validation Structure"))#</a><br>
		</div>>
	}

	#; Draw raw content (initially hidden)
	Set tRaw = $$$Text("Raw Definition")
	Set struct=##class(EnsLib.EDI.X12.SchemaXML).stripDefCategory($$$vaSchemaGbl(category,"DS",structname),category,$G($$$vaSchemaGbl(category,"base")))
	&html<<div id="rawContent" style="padding:20px 0px 0px 50px;display:none;">
	<b>#(tRaw)#</b>
	<table cellspacing="0" cellpadding="2">
	<tr><td>#(struct)#</td></tr>
	</table>
	</div></td>
	</tr></table><hr/><br/></div>>
	Quit $$$OK
}

Method drawArray(category, gname, path) [ Internal ]
{
	For ch=1:1:@gname {
		Set chName=@gname@(ch,"name"), chPath=$E(path_"."_chName,2,*), chName=$P(chName,"(")
		Set tOpt=$G(@gname@(ch,"opt"))
		Set tRep=($E(chPath,*)=")")
		Set tUnion=("union"=$E(chName,*+1-$L("union"),*))  Set:tUnion %hadUnion=1
		Set chLoop=$S($G(@gname@(ch)):chName,1:"")
		If tOpt {
			Set tBorder="2px dotted #60a060"  // green: similar to the box containing system name in title bar
			Write "<tr>"_$S(""=chLoop:"",1:"<td align='right' valign='top' style='font-style:italic;'>"_chLoop_"</td>")_"<td align='left' valign='top'><table cellpadding=2 cellspacing=2 align='left' style='border: "_tBorder_"; border-right: none;'><tr>",!
			Set chLoop=""
		}
		If tRep {
			Set tBorder="2px solid  #703838"  // red: similar to the highlight for icons in ribbon bar
			Write "<tr>"_$S(""=chLoop:"",1:"<td align='right' valign='top' style='font-style:italic;'>"_chLoop_"</td>")_"<td align='left' valign='top'><table cellpadding=2 cellspacing=2 align='left' style='border: "_tBorder_"; border-right: none;'><tr>",!
			Set chLoop=""
		}
		If $G(@gname@(ch)) {
			#; Group/loop/union
			If (""'=chLoop&&'tOpt&&'tRep)||tUnion {
				Set:'tUnion %hadGroup=1
				Set tBorder=$S(tUnion:"2px dotted #ead960;", 1:"2px solid  #ead960") // orange: similar to highlight used in tablePane rows when selected
				Write "<tr>"_$S(""=chLoop:"",1:"<td align='right' valign='top' style='font-style:italic;'>"_chLoop_"</td>")_"<td align='left' valign='top'><table cellpadding=2 cellspacing=2 align='left' style='border: "_tBorder_"; border-right: none;'><tr>",!
			}
			Do ..drawArray(category,$Name(@gname@(ch)),"."_chPath)
			
			If (""'=chLoop&&'tOpt&&'tRep)||tUnion {
				Write "</tr></table></td></tr>",!
			}
		} Else {
			#; ordinary segment
			Set %iSeg=%iSeg+1, chType=$P(@gname@(ch,"type"),"(")
			If "DocsRef"=$E(chName,*-$L("DocsRef")+1,*) {
				Set tDocsRefType = $E(chName,1,*-$L("DocsRef"))
				If tDocsRefType="TransactionSet" {
					Set tCat = $S($Case($P(chType,":",2),".":1,"base":1,:0):$G($$$vaSchemaGbl(category,"base"),category),1:$P(chType,":",2))
					Set link = ..Link("EnsPortal.EDI.X12.SchemaMain.zen?CAT="_$$$URLENCODE(tCat))
				} ElseIf tDocsRefType="Group" {
					If $D($$$vaSchemaGbl(category,"DS","FunctionalGroup")) {
						Set link = ..Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS=DS:"_$P(chType,":",2)_":FunctionalGroup")
					} Else {
						Set link = ..Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS=DS:"_$P(chType,":",2)_":Group")
					} 
				} Else {
					Set link = ..Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS=DS:"_$P(chType,":",2)_":"_tDocsRefType)
				}
				Set tooltip = %iSeg_":"_$$$FormatText($$$Text("Zero or more &#39;%1&#39; documents appear here"),tDocsRefType)
			} Else {
				$$$ASSERTNOLOG("SS"=$P(chType,":"))
				Set tDesc=..EscapeHTML(##class(EnsLib.EDI.X12.Schema).GetDescription(chType))
				Set tooltip = %iSeg_":"_$S(""'=chPath:chPath, 1:chName)_$S(""=tDesc:"",1:" - "_tDesc)
				Set link = ..Link("EnsPortal.EDI.X12.SchemaSegmentStructure.zen?SS="_$$$URLENCODE($P(chType,"!"))_"&PATH="_$S(""=chPath:"",1:chPath)_"&DS="_$$$URLENCODE(..docStruct))
			}
			&html<<tr><td align='left' style='padding:0px 4px 0px 4px;'><a title='#(tooltip)#' href='#(link)#'>#(chName)#</a></td></tr>>
		}
		Write:tRep "</tr></table></td></tr>",!
		Write:tOpt "</tr></table></td></tr>",!
	}
	Quit
}

ClassMethod isOnlyNew(category) As %Boolean [ ZenMethod ]
{
	set cat = $p(category,":",2)
	Quit (('$D($$$vaVSchemaGbl(cat))) && ($D($$$vaSchemaGbl(cat))))
}

/// What to do when the user asks to view the raw definition.
ClientMethod showRaw() [ Language = javascript ]
{
	var rawdiv = document.getElementById('rawContent');
	if (rawdiv.style.display == 'block') {
		rawdiv.style.display = 'none';
	}
	else {
		rawdiv.style.display = 'block';
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("X12 Document Structure")
}

}
