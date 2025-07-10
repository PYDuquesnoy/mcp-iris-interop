/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

Class EnsPortal.EDI.XML.SchemaDocumentStructure Extends EnsPortal.EDI.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "XML Document Structure";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css,ensemble/Ensemble_EDI.css";

Property path As %String(MAXLEN = "", ZENURL = "PATH");

Property docStruct As %String(MAXLEN = "", ZENURL = "DS");

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top">
<spacer width="20"/>
<vgroup valign="top">
<spacer height="2"/>
<html id="content" OnDrawContent="DrawContent"/>
</vgroup>
<spacer width="20"/>
</hgroup>
</pane>
}

/// Draw main HTML content for this page.
Method DrawContent(pSeed As %String) As %Status
{
	Set elem=$P(..docStruct,":",1)
	Set txtName=$Case(elem, "DS":$$$TextHTML("Document Structure / Document Type"), "CT":$$$TextHTML("Complex Type Structure"), "CG":$$$TextHTML("Component Group"), "ST":$$$TextHTML("Simple Type"), "xs":$$$TextHTML("Builtin Schema Type"), :$$$TextHTML("property"))
	If ""'=..path {
		&html<
		<table><tr valign="top">
			<td style="text-align:right;padding-right:10px;font-size:0.8em;font-weight:bold;">#($$$FormatText($$$Text("Path followed to this %1:"),txtName))#</td>
			<td style="font-size:0.8em">#($ZCVT(..path,"O","HTML"))#</td>
		</tr></table>
		>
	}
	Set cat=$P(..docStruct,":",2)
	Set catHTML = $ZCVT(cat,"O","HTML")
	Set struct=$P(..docStruct,":",3)

	If ((cat'="")&&(elem'="")&&(struct'="")) {
		Set xProp=$P(struct,"#",2,$L(struct,"#")), struct=$P(struct,"#")
		Set ref=$Name($$$vaSchemaGbl(cat,elem,struct,"meta"))
		Set oStruct=struct
		For i=1:1:$L(xProp,"#") { Set tPiece=$P(xProp,"#",i)  Continue:""=tPiece
			Set $E(ref,$L(ref))=","_tPiece_")"
			Set tName=$G(@ref@("name"))
			Set oStruct=oStruct_"#"_$S(""=tName:tPiece,1:tName)
			Set struct=struct_"#"_tPiece
		}
		Set structHTML = $ZCVT(oStruct,"O","HTML")
		Set tDescNode=$G(@ref@("desc"))
		Set tDesc=$S(""=tDescNode:"",1:$Replace($$$vaSchemaGbl(cat,tDescNode,"chars"),$C(13,10),$C(10)))
		Set tDesc=$Replace($Replace(..EscapeHTML($ZStrip(tDesc,"<>C")),$C(13),$C(10)),$C(10),"<br/>"_$C(13,10))
		&html<
		<hr/>
		<div style="font-size:0.95em">XML #(txtName)# Definition</div>
		<div class="Text" style="font-size:2.0em;color:darkgray;">#($S("xs"=elem:"xs",1:catHTML)_":"_structHTML)#</div>
		>
		If $D(@ref) {
			Set xpre="",toptype=""
			For {
				Set cnt=$G(@ref)
				Set prevtype=toptype, toptype=$G(@ref@("type"))
				Quit:prevtype=toptype
				Set xtype=$G(@ref@("xtype"))
				Set tNode=$G(@ref@("n"))
				Set tSrc=$S(""=tNode:"",1:$G($$$vaSchemaGbl(cat,"src",$G($$$vaSchemaGbl(cat,$P($P($P(tNode,":"),","),"("),"src"),0))))
				Set tNode=$ZCVT(tNode,"O","HTML")
				Set tSrc=$ZCVT(tSrc,"O","HTML")
				Set xtypeHTML = $ZCVT(xtype,"O","HTML")
				Set toptypeHTML = $ZCVT(toptype,"O","HTML")
				Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(ref)
				&html<
				<hr/>
				<div class="Text" title="node=#(tNode)#, src=#(tSrc)#">
				<table>
				>
				If ""'=toptypeHTML {
					&html<
					<tr valign="top">
						<td style="text-align:right;padding-right:10px;font-size:0.8em;font-weight:bold;">#($$$Text("Type:"))#</td>
						<td style="font-size:0.8em">#(toptypeHTML)#</td>
					</tr>
					>
				}
				&html<
				<tr valign="top">
					<td style="text-align:right;padding-right:10px;font-size:0.8em;font-weight:bold;">xsd:</td>
					<td style="font-size:0.8em">#($S(""'=xtypeHTML:xtypeHTML,1:$$$Text("not found")))#</td>
				</tr>
				>
				If ""'=tDName&&("DS"=elem)&&("element"=$P(xtype,":")) {
					Set nslist=""
					Set nc=$L(tDName,":")  For i=1:1:nc { Set pc=$P(tDName,":",i)
						Set f=$F(pc,"$")
						If f { Set nsnum=$E(pc,f,*)
							If nsnum?1.N && '$D(donens(nsnum)) {
								Set uri=$G($$$vaSchemaGbl(cat,"ns","list",nsnum,"uri")), donens(nsnum)=""
								Set:""'=uri nslist=$S(""=nslist:"",1:nslist_$C(13,10))_"$"_nsnum_"="_uri
							}
						}
					}
					&html<
					<tr valign="top">
						<td style="text-align:right;padding-right:10px;font-size:0.8em;font-weight:bold;">#($$$Text("Top Element"))#:</td>
						<td#($S(""=nslist:"",1:" title="""_nslist_""""))# style="font-size:0.8em">#(tDName)#</td>
					</tr>
					>
				}
				If ""'=tDesc {
				 	&html<
				 	<tr title="node=#($G(tDescNode))#" valign="top">
				 		<td style="text-align:right;padding-right:10px;font-size:0.8em;font-weight:bold;">#($$$Text("Description:"))#</td>
				 		<td style="font-size:0.8em">#(tDesc)#</td>
				 	</tr>
					>
				}
			 	&html<
				</table></div>
				>
				Quit:""=toptype||cnt
				
				Set tDesc=""
				Set xpre=xpre_xtype_":"
				Set elem=$P(toptype,":",1)
				Set struct=$P(toptype,":",2)
				Set ref2=$Name($$$vaSchemaGbl(cat,elem,$P(struct,"("),"meta"))
				Quit:'$D(@ref2)
				Set ref=ref2
			} ; end For
		}
		If $D(@ref) {
			if (cnt>0) {
				#; Draw properties table
				&html<
				<hr/>
				<div style="margin-left: 20px; margin-right: 20px;">
				<table class="tpTable" cellpadding=2 cellspacing=2>
				<tbody>
				<tr>
				<th></th>
				<th>#($$$Text("Name"))#</th>
				<th>#($$$Text("Type"))#</th>
				<th>#($$$Text("Required"))#</th>
				<th>#($$$Text("Element"))#</th>
				<th>#($$$Text("Default"))#</th>
				<th>#($$$Text("Description"))#</th>
				</tr>
				>
				#; Build properties table contents
				Set iSeg=0,depth=0,fullpath=""
				For iRow=1:1:cnt {
					Do ..showRow(iRow,$Name(@ref@(iRow)),..path,cat,xpre,elem,struct)
				}
				&html<
				</tbody>
				</table>
				</div>
				>
			}
		}
	}
	Quit $$$OK
}

/// Draw main HTML content for this page.
Method showRow(i As %String, ref As %String, path As %String, cat As %String, xpre As %String, dadElem As %String, dadStruct As %String) As %Status
{
	Set iSeg=0,fullpath=""
	//For iTab=1:1:depth-1 { Write "+&nbsp;" }
	Set name=$G(@ref@("name")), type=$G(@ref@("type")), req=$G(@ref@("req")), dname=##class(EnsLib.EDI.XML.Schema).getDName(ref), xtype=$G(@ref@("xtype"))
	Set tElem=$P(type,":") Set:$Case($E(tElem),"?":1,"#":1,:0) tElem="" Set:""'=tElem type=$P(type,":",2,$L(type,":"))
	Set default=$G(@ref@("default"))
	Set targref=$S(""=tElem:"",1:$Name($$$vaSchemaGbl(cat,tElem,$P(type,"("),"meta"))), childCnt=$S(""=targref||$G(@ref):$G(@ref),1:$G(@targref))

	Set tDescNode=$G(@ref@("desc"))
	Set tDesc=$S(""=tDescNode:"",1:$Replace($$$vaSchemaGbl(cat,tDescNode,"chars"),$C(13,10),$C(10)))
	Set tDesc=$Replace($Replace(..EscapeHTML($ZStrip(tDesc,"<>C")),$C(13),$C(10)),$C(10),"<br/>"_$C(13,10))
	Set tNum=+$P(ref,",",$L(ref,","))
	Set npath=path_$S(""=path:"",1:".")_$Replace(name,"()","(1)")
	If $G(@ref) {
		Set type="#"_i
		Set tUrl="EnsPortal.EDI.XML.SchemaDocumentStructure.zen?DS="_$$$URLENCODE(dadElem_":"_cat_":"_$P(dadStruct,"(")_"#"_i)_"&PATH="_$$$URLENCODE(npath)
	} Else {
		Set tType=$P(type,"(")
		Set:tElem_tType="" tElem="xs", tType="string"
		Set tUrl="EnsPortal.EDI.XML.SchemaDocumentStructure.zen?DS="_$$$URLENCODE(tElem_":"_cat_":"_tType)_"&PATH="_$$$URLENCODE(npath)
	}
	Set tNode=$G(@ref@("n"))
	Set tSrc="source="_$G($$$vaSchemaGbl(cat,"src",$G($$$vaSchemaGbl(cat,$P($P($P(tNode,":"),","),"("),"src"),0)))_","_$C(13,10)_"node="_$S(""=tNode:"",1:tNode)
	//Set:'childCnt tSrc=tSrc_", xsd="_$S(""=xtype:"",1:xpre_xtype)

	Set rowClass=$S(i#2=0:"tpEven",1:"tpOdd")
	Set nslist=""
	Set nc=$L(dname,":")  For i=1:1:nc { Set pc=$P(dname,":",i)
		Set f=$F(pc,"$")
		If f { Set nsnum=$E(pc,f,*)
			If nsnum?1.N && '$D(donens(nsnum)) {
				Set uri=$G($$$vaSchemaGbl(cat,"ns","list",nsnum,"uri")), donens(nsnum)=""
				Set:""'=uri nslist=$S(""=nslist:"",1:nslist_$C(13,10))_"$"_nsnum_"="_uri
			}
		}
	}
	&html<<tr valign="top" class="#(rowClass)#">
		<td align="left" title="#(tSrc)#">#(tNum)#</td>
		<td align="left" title="#($ZCVT(npath,"O","HTML"))#">#($S(""=name:"-",1:"<a href="_..Link(tUrl)_">"_name_"</a>"))#</td>
		<td title="#("xsd="_$S(""=xtype:"&nbsp;",1:xpre_xtype))#">#($S(""=type:"<i>string</i>", ""=tElem&&(type'["#"):type, 'childCnt:type, 1:"<a href="_..Link(tUrl)_">"_type_"</a>"))#</td>
		<td>#($S(0=req:$$$Text("No"),1:$$$Text("Yes")))#</td>
		<td#($S(""=nslist:"",1:" title="""_nslist_""""))#>#($S(""=dname:"&nbsp;-&nbsp;",1:dname))#</td>
		<td>#($S(""=default:"&nbsp;",1:default))#</td>
		<td style='text-align:left;'#($S(""=tDescNode:"",1:" title='node="_tDescNode_"'"))#>#($S(""=tDesc:"&nbsp;",1:tDesc))#</td>
		</tr>>
	Quit $$$OK
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2)=$LB($$$Text("XML Schemas","Ensemble"),"EnsPortal.EDI.XML.SchemaMain.zen") 
	Set pLink(3)=$LB(..%OnGetPageName(),"#")
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("XML Document Structure")
}

}
