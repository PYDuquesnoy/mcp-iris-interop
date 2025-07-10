/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDI

/// Page to invoke the HTML renderer.
/// Converted (with very few changes) from a CSP page to a Zen page.
Class EnsPortal.EDI.ValidationStructure Extends EnsPortal.EDI.Template [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Validation Structure";

Property DocType As %String(ZENURL = "DocType");

Property SegType As %String(ZENURL = "SegType");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
	.first {
		vertical-align:   middle;
		text-align:       center;
		border:       	  1px solid lightgray;
		font-size:		  0.93em;
	}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="20"/>
<hgroup valign="top">
<spacer width="20"/>
<html id="content" OnDrawContent="DrawContent" valign="top" />
<spacer width="20"/>
</hgroup>
</pane>
}

/// Draw main HTML content for this page.
Method DrawContent(pSeed As %String) As %Status
{
	If ..SegType="" {
		Quit ..RenderTransactionSet($Piece(..DocType,":"),$Piece(..DocType,":",2))
	} Else {
		Quit ..RenderSegment($Piece(..DocType,":"),$Piece(..DocType,":",2),$Piece(..SegType,"-",2))
	}
}

/// Convert the cryptic requirement symbol into something more user-friendly
ClassMethod UserReq(pRequirement As %String) As %String
{
	Quit $Case(pRequirement,".":"Not used","!":"Mandatory","$":"Recommended","-":"Not recommended","&":"Dependent","":"N/A",:pRequirement)
}

/// Given a specific set and segment index, render that segment's information
ClassMethod RenderSegment(pCategory As %String, pSet As %String, pOrdinal As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
	
		If '$Data(^EnsEDI.Schema(pCategory,pSet,"o",pOrdinal),tIndex) {
			&HTML<<HTML><H3>Error - Segment Not Found</H3>>
			Quit
		}
		Set tDesc=^EnsEDI.Schema(pCategory,pSet,"m",tIndex)
		
		#; Split the Segment Descriptor
		$$$ASSERTNOLOG(pOrdinal=$Piece(tDesc,"|",3))
		Set tSegID=$Piece(tDesc,"|",2),tPos=$Piece(tDesc,"|",4)
		Set tUsrReq=..UserReq($Piece(tDesc,"|",5)),tStdReq=$Piece(tDesc,"|",6),tActReq=$Piece(tDesc,"|",7)
		Set tMaxUse=$Piece(tDesc,"|",8)
				
		#; Get the DocInfo
		i $Case(pCategory,"HIPAA_5010":1,"HIPAA_4010":1,"HIPAA_6020":1,:0) && ((pSet'="Group") && (pSet'="Interchange")) {
			Set doc = ^EnsEDI.Schema(pCategory,pSet)
			Set ImpGuide = $p(doc,"*",2)
			Set TxName = $p(ImpGuide,"_")
			Set tDocInfo = $p(doc,"*")
		} else {
			If '($D(^EnsEDI.Schema(pCategory,pSet),tDocInfo)#2)||($E(tDocInfo,1,2)'="X|") {
				Set tDocInfo=$G(^EnsEDI.Schema(pCategory),"_")
			}
			Set ImpGuide = $S(tDocInfo["*":$P(tDocInfo,"*",2),1:pCategory)
			Set TxName = pSet
			Set tDocInfo = $P(tDocInfo,"*")
		}
		Set tAgency=$Piece(tDocInfo,"|"),tStandard=$Piece(tDocInfo,"|",2)
		Set tDocType=$Piece(tDocInfo,"|",3),tTitle=$Piece(tDocInfo,"|",4)
		Set tRef=$Piece(tDocInfo,"|",5)
		
		#; Expand the Agency
		Set tFamily=$Case(tAgency,"UN":"EDIFACT","X":"X12",:tAgency)

		If tFamily = "X12" && $D(^EnsEDI.X12.Schema(pCategory)) {
			Set tElementSpec = "SS:"_pCategory_":"_tSegID
			Set tDesc=$classmethod("EnsLib.EDI.X12.Schema","GetDescription",tElementSpec)
		} Else {
			Set tElementSpec = "SS:"_pCategory_":"_pSet_":"_tSegID_"-"_pOrdinal
			Set tDesc=$classmethod("EnsLib.EDI.SEF.Schema","GetDescription",tElementSpec)
		}
		
		#; Write the header
		&HTML<<U>#($ZCVT(tFamily,"O","HTML"))# . #($ZCVT(tDocType,"O","HTML"))# . #($ZCVT(tStandard,"O","HTML"))# Transaction Set #($ZCVT(TxName,"O","HTML"))#</U>>

		&HTML<<P><TABLE CLASS='first'>
		<TR><TD CLASS='first' colspan=2><B>#($ZCVT(tDesc,"O","HTML"))#</TD></TR>
		<TR><TD CLASS='first'><B>Segment:</B></TD><TD CLASS='first'>#($ZCVT(tSegID_"-"_pOrdinal,"O","HTML"))#</TD></TR>
		<TR><TD CLASS='first'><B>User Requirement:</B></TD><TD CLASS='first'>#($S(tUsrReq="":"&nbsp;",1:$ZCVT(tUsrReq,"O","HTML")))#</TD></TR>
		<TR><TD CLASS='first'><B>Standard Requirement:</B></TD><TD CLASS='first'>#($ZCVT(tStdReq,"O","HTML"))#</TD></TR>
		<TR><TD CLASS='first'><B>Actual Requirement:</B></TD><TD CLASS='first'>#($ZCVT(tActReq,"O","HTML"))#</TD></TR>
		<TR><TD CLASS='first'><B>Position:</B></TD><TD CLASS='first'>#($ZCVT(tPos,"O","HTML"))#</TD></TR>
		<TR><TD CLASS='first'><B>Max Use:</B></TD><TD CLASS='first'>#($ZCVT(tMaxUse,"O","HTML"))#</TD></TR>
		</TABLE></P>>
		
		&HTML<<P>Data Element Summary</P><TABLE CLASS='first'><TR>
		<TH CLASS='first' ALIGN='LEFT'>Act</TH>
		<TH CLASS='first' ALIGN='LEFT'>Ordinal</TH>
		<TH CLASS='first' ALIGN='LEFT'>Data</TH>
		<TH CLASS='first' ALIGN='LEFT'>Element</TH>
		<TH CLASS='first' ALIGN='LEFT'>Data</TH>
		<TH CLASS='first' ALIGN='LEFT'>Min</TH>
		<TH CLASS='first' ALIGN='LEFT'>Max</TH>
		<TH CLASS='first' ALIGN='LEFT'>Max</TH>
		<TH CLASS='first' ALIGN='LEFT'>Element</TH>
		</TR><TR>
		<TH CLASS='first' ALIGN='LEFT'>Req.</TH>
		<TH CLASS='first' ALIGN='LEFT'>Ref</TH>
		<TH CLASS='first' ALIGN='LEFT'>Element</TH>
		<TH CLASS='first' ALIGN='LEFT'>Description</TH>
		<TH CLASS='first' ALIGN='LEFT'>Type</TH>
		<TH CLASS='first' ALIGN='LEFT'>Len</TH>
		<TH CLASS='first' ALIGN='LEFT'>Len</TH>
		<TH CLASS='first' ALIGN='LEFT'>Use</TH>
		<TH CLASS='first' ALIGN='LEFT'>PropPath</TH></TR>
		</THEAD>>
	
		Set tSE="" For { Set tSE=$O(^EnsEDI.Schema(pCategory,pSet,"o",pOrdinal,tSE),1,tEleDesc)  Quit:""=tSE
			Set tType=$Piece(tEleDesc,"|") If tType="E" {
				#; Render a segment element
				Do ..RenderElement(pCategory,tAgency,tRef,pSet,pOrdinal,tSegID,tSE,tEleDesc)
			} ElseIf tType="C" {
				If $D(^EnsEDI.X12.Schema(pCategory,"RC",$P(tEleDesc,"|",2))) {
					Set tCompName = $P(tEleDesc,"|",2)
					Set tRule = ""
					For {
						Set tRule = $O(^EnsEDI.X12.Schema(pCategory,"RC",tCompName,tRule))	Quit:""=tRule
						Set tCompRules("r|"_tCompName_"|"_tRule)=""
					}
				}
				#; Have to go one level further down for composites
				If (("."'=$Piece(tEleDesc,"|",3)) && (""'=$O(^EnsEDI.Schema(pCategory,pSet,"o",pOrdinal,tSE,"")))) {
					Set tCompDesc=tEleDesc
					Set tCE=""
					For {
						Set tCE=$O(^EnsEDI.Schema(pCategory,pSet,"o",pOrdinal,tSE,tCE),1,tEleDesc)  Quit:""=tCE
						#; Render a composite element
						Do ..RenderElement(pCategory,tAgency,tRef,pSet,pOrdinal,tSegID,tSE,tEleDesc,tCE,tCompDesc)
					}
				} Else {
					Do ..RenderUnusedComp(pCategory,tAgency,tRef,pSet,pOrdinal,tSegID,tSE,tEleDesc)
				}
			} Else {
				$$$ASSERTNOLOG("0:Unrecognized Type-not C or E")
			}
		}
		&HTML<</TABLE>>
		
		If $D(tCompRules) || $Data(^EnsEDI.X12.Schema(pCategory,"RC",tSegID)) {
			&HTML<<P><H3>Syntax Notes:</P></H3>>
			Set tRule = ""
			For {
				Set tRule = $O(tCompRules(tRule))	Quit:""=tRule
				Do ..RenderSyntaxRule(tRule)
			}
			Set tRule=""
			For {
				Set tRule=$O(^EnsEDI.X12.Schema(pCategory,"RC",tSegID,tRule))  Quit:""=tRule
				Do ..RenderSyntaxRule("r|"_tSegID_"|"_tRule)
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Given an element description and optional composite description, render the element
ClassMethod RenderElement(pCategory, pAgency, pRef, pSet As %String, pSegIDX As %Integer, pSegID As %String, pEleIDX As %Integer, pEleDesc As %String, pComIDX As %Integer = 0, pComDesc As %String = "")
{
	#; Pick out the descriptor info
	Set tEleID=$Piece(pEleDesc,"|",2),tActReq=$Piece(pEleDesc,"|",3),tType=$Piece(pEleDesc,"|",4)
	Set tMinLen=$Piece(pEleDesc,"|",5),tMaxLen=$Piece(pEleDesc,"|",6),tMaxUse=$Piece(pEleDesc,"|",7)
	Set:(""=tEleID) tEleID="N/A"
	If tActReq="." {
		Set tPropPath="NOT USED"
	} Else {
		Set tPropPath=$Piece(pEleDesc,"|",8)
	}
	
	Set tCodeIndex=$Piece(pEleDesc,"|",9)

	If pComIDX=0 {
		Set tEleName=tEleID
	} Else {
		Set tEleName=$Piece(pComDesc,"|",2)_" / "_tEleID
		Set:tActReq'="." tPropPath=$Piece(pComDesc,"|",8)_"."_tPropPath
		Set tActReq = $P(pComDesc,"|",3)_" / "_tActReq
	}
	
	#; Expand the element full name
	Set tEleExp=$G(^EnsEDI.Description(pAgency,pRef,"ELEM",tEleID),"(No Description)")
	
	#; Formulate the ordinal reference from the element index and the segment ID
	Set tOrdRef=pSegID_"#"_$$$NUM(pEleIDX,2)
	
	Set:pComIDX tOrdRef=tOrdRef_"-"_$$$NUM(pComIDX,2)
	
	&HTML<<TR>
	<TD CLASS='first'>#($ZCVT(tActReq,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tOrdRef,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tEleName,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tEleExp,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tType,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tMinLen,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tMaxLen,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tMaxUse,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tPropPath,"O","HTML"))#</TD></TR>>
	
	If pComIDX=0 {
		Set tCodeIndex=$G(^EnsEDI.Schema(pCategory,pSet,"c",tEleID,"l",pSegIDX,pEleIDX))
	} Else {
		Set tCodeIndex=$G(^EnsEDI.Schema(pCategory,pSet,"c",tEleID,"l",pSegIDX,pEleIDX,pComIDX))
	}
	If (tActReq'[".") && (tCodeIndex'="") {
		&HTML<<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>
		<TABLE CLASS='first'>>

		Set tCode="" For { Set tCode=$O(^EnsEDI.Schema(pCategory,pSet,"c",tEleID,"c",tCodeIndex,tCode))  Quit:""=tCode
			&HTML<<TR>
			<TD CLASS='first'>#($ZCVT(tCode,"O","HTML"))#</TD>
			<TD CLASS='first'>#($ZCVT($G(^EnsEDI.Description(pAgency,pRef,"CODES",tEleID,tCode),"(No description)"),"O","HTML"))#</TD>
			</TR>>
		}
		&HTML<</TABLE></TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>
		<TD CLASS='first'>&nbsp;</TD>>
	}
}

/// Given a composite description for an unused composite, render the element
ClassMethod RenderUnusedComp(pCategory, pAgency, pRef, pSet As %String, pSegIDX As %Integer, pSegID As %String, pComIDX As %Integer = 0, pComDesc As %String = "")
{
	#; Pick out the descriptor info
	Set tEleID=$Piece(pComDesc,"|",2)
	Set:(""=tEleID) tEleID="N/A"
	Set tActReq = "."
	Set tPropPath="NOT USED"
	Set tEleName=tEleID
	
	#; Expand the element full name
	Set tEleExp=$G(^EnsEDI.Description(pAgency,pRef,"COMP",tEleID),"(No Description)")
	
	#; Formulate the ordinal reference from the element index and the segment ID
	Set tOrdRef=pSegID_"#"_$$$NUM(pComIDX,2)
		
	&HTML<<TR>
	<TD CLASS='first'>#($ZCVT(tActReq,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tOrdRef,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tEleName,"O","HTML"))#</TD>
	<TD CLASS='first'>#($ZCVT(tEleExp,"O","HTML"))#</TD>
	<TD CLASS='first'>&nbsp;</TD>
	<TD CLASS='first'>&nbsp;</TD>
	<TD CLASS='first'>&nbsp;</TD>
	<TD CLASS='first'>&nbsp;</TD>
	<TD CLASS='first'>#($ZCVT(tPropPath,"O","HTML"))#</TD></TR>>
}

ClassMethod RenderSyntaxRule(pRule As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tName=$Piece(pRule,"|",2),pRule=$Piece(pRule,"|",3)
		If $Extract(pRule)="C" {
			Write !,"<P>If ",$ZCVT(tName_$Extract(pRule,2,3),"O","HTML")," is present, then "
			Set tC=($Length(pRule)-1)\2-1  
			For tI=4:2:$Length(pRule) {
				Write $ZCVT(tName_$Extract(pRule,tI,tI+1),"O","HTML")," "
			}
			If tC>1 { 
				Write " are required"
			} Else {
				Write " is required"
			}
			Write "</P>"
			
		} ElseIf $Extract(pRule)="P" {
			
			Write "<P>"
			Set tC=($Length(pRule)-1)\2
			If tC>1 { 
				Write "If any of "
			} Else {
				Write "If "
			}
			Set tC=($Length(pRule)-1)\2
			For tI=2:2:$Length(pRule) {
				Write $ZCVT(tName_$Extract(pRule,tI,tI+1),"O","HTML")," "
			}
			If tC>1 { 
				Write " are present, then all are required"
			} Else {
				Write " is present, then all are required"
			}
			Write "</P>"
			
		} ElseIf $Extract(pRule)="R" {
			
			Write "<P>At least one of "
			Set tC=($Length(pRule)-1)\2
			For tI=2:2:$Length(pRule) {
				Write $ZCVT(tName_$Extract(pRule,tI,tI+1),"O","HTML")," "
			}
			If tC>1 { 
				Write " are required"
			} Else {
				Write " is required"
			}
			Write "</P>"
			
		} ElseIf $Extract(pRule)="E" {
			
			Write "<P>Only one of "
			For tI=2:2:$Length(pRule) {
				Write $ZCVT(tName_$Extract(pRule,tI,tI+1),"O","HTML")," "
			}
			Write " may be present</P>"
			
		} ElseIf $Extract(pRule)="L" {
			
			Write !,"<P>If ",$ZCVT(tName_$Extract(pRule,2,3),"O","HTML")," is present, then at least one of"
			Set tC=($Length(pRule)-1)\2-1  
			For tI=4:2:$Length(pRule) {
				Write $ZCVT(tName_$Extract(pRule,tI,tI+1),"O","HTML")," "
			}
			If tC>1 { 
				Write " are required"
			} Else {
				Write " is required"
			}
			Write "</P>"
		} ElseIf $Extract(pRule)="D" {
			Write "Edifact Rule Not Yet Implemented - "_$ZCVT(pRule,"O","HTML")
		}
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod RenderCategory(pCategory) As %Status
{
	Set tSC=$$$OK
	#; Iterate through the Sets and output each one
	Set tSet="" For { Set tSet=$O(^EnsEDI.Schema(pCategory,tSet))  Quit:""=tSet
		Set tSC=..RenderTransactionSet(pCategory, tSet) If $$$ISERR(tSC) Quit
	}
	Quit tSC
}

ClassMethod RenderTransactionSet(pCategory As %String, pSet As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
	
		#; Get the DocInfo "X|005010|005 010 X231A1|Implementation Acknowledgment|X12"
		i $Case(pCategory,"HIPAA_5010":1,"HIPAA_4010":1,"HIPAA_6020":1,:0) {
			Set doc = ^EnsEDI.Schema(pCategory,pSet)
			Set ImpGuide = $p(doc,"*",2)
			i (pSet="Group") || (pSet="Interchange") {
				Set TxName = pSet
			} else {
				Set TxName = $p(ImpGuide,"_")
			}
			Set tDocInfo = $p(doc,"*")
		} else {
			If '($D(^EnsEDI.Schema(pCategory,pSet),tDocInfo)#2)||($E(tDocInfo,1,2)'="X|") {
				Set tDocInfo=$G(^EnsEDI.Schema(pCategory),"_")
			}
			Set ImpGuide = $S(tDocInfo["*":$P(tDocInfo,"*",2),1:pCategory)
			Set TxName = pSet
			Set tDocInfo = $P(tDocInfo,"*")
		}
		Set tAgency=$Piece(tDocInfo,"|"), tStandard=$Piece(tDocInfo,"|",2)
		Set tDocType=$Piece(tDocInfo,"|",3), tTitle=$Piece(tDocInfo,"|",4), tRef=$Piece(tDocInfo,"|",5)
		
		#; Expand the Agency
		Set tFamily=$Case(tAgency,"UN":"EDIFACT","X":"X12",:tAgency)
		
		#; Write the header
		&HTML<<U>#($ZCVT(tFamily,"O","HTML"))# . #($ZCVT(tDocType,"O","HTML"))# . #($ZCVT(tStandard,"O","HTML"))#</U><H3><I>Implementation Guide '#($ZCVT(ImpGuide,"O","HTML"))#' for TransactionSet name '#($ZCVT(TxName,"O","HTML"))#'</I></H3>>
		&HTML<<H2>#($ZCVT(tTitle,"O","HTML"))#</H2>>
		
		&HTML<<H1>#($ZCVT(TxName,"O","HTML"))#</H1><TABLE CLASS='first'>
		<TH CLASS='first' ALIGN='LEFT'>USER REQ</TH>
		<TH CLASS='first' ALIGN='LEFT'>STD. REQ</TH>
		<TH CLASS='first' ALIGN='LEFT'>ACT REQ</TH>
		<TH CLASS='first' ALIGN='LEFT'>MAX USE.</TH>
		<TH CLASS='first' ALIGN='LEFT'>POSITION</TH>
		<TH CLASS='first' ALIGN='LEFT'>SEG ID</TH>
		<TH CLASS='first' ALIGN='LEFT'>SEG NAME</TH></TR></THEAD>>

		#; Build segment paths list
		Set rs=##class(%ResultSet).%New("Ens.VDoc.Utils:EnumerateDocContents")
		If "X12"=tFamily {
			Set sc=rs.Execute("EnsLib.EDI.X12.Document",,"-"_pCategory_":"_pSet,1)
		} Else {
			Set sc=rs.Execute("EnsLib.EDI.EDIFACT.Document",,pCategory_":"_pSet,1)
		}
		If $$$ISOK(sc) {
			Set iSeg=0,depth=0,fullpath=""
			For iRow=1:1 { quit:'rs.Next()
				set path=rs.Data("Property"), type=rs.Data("Type")
				if $E(path,depth+1)="." { Set depth=depth+1 }
				else {
					while depth&&($E(path,depth)'=".") { set depth=depth-1 }
				}
				set fullpath=$S(depth:$p(fullpath,".",1,depth)_".",1:"")_$E(path,depth+1,$L(path))
				If "X12"=tFamily {
					set seg=$p($p(type,":",4),"(")
					If seg'=""&&(seg'["union")&&(seg'["grp")&&(seg'["Loop") {
						set tOrd = $P(seg,"-",2)
						set segs(tOrd)=fullpath, segs(tOrd,"type")=$P($P(seg,"-"),"!")
					}
				} Else {
					set seg=$p($p(type,":",3),"(")
					If seg'=""&&(seg'["union")&&(seg'["grp") {
						set iSeg=iSeg+1, segs(iSeg)=fullpath, segs(iSeg,"type")=seg
					}
				}
			}
		}
		#; loop over items in TransactionSet structure
		Set tLoopIndent=0
		Set tI="" For { Set tI=$O(^EnsEDI.Schema(pCategory,pSet,"m",tI),1,tDesc)  Quit:""=tI
			
			Set tDescType=$Piece(tDesc,"|") 
			If tDescType="t" {
				
				#; Update the current table number
				&HTML<<TR CLASS='first'/><TR><TD CLASS='first'>Table#(+$Piece(tDesc,"|",2))#</TD></TR><TR/>>
				
			} ElseIf tDescType="s" {
				
				#; Segment
				Set tSegID=$Piece(tDesc,"|",2),tOrdinal=$Piece(tDesc,"|",3),tPos=$Piece(tDesc,"|",4)
				Set tUsrReq=..UserReq($Piece(tDesc,"|",5)),tStdReq=$Piece(tDesc,"|",6),tActReq=$Piece(tDesc,"|",7)
				Set tMaxUse=$Piece(tDesc,"|",8),tSegExp=$G(^EnsEDI.Description(tAgency,tRef,"SEG",tSegID),"(No Description)")
				
					
				#; Transaction Segments
				&HTML<<TR>
				<TD CLASS='first'>#($S(tUsrReq="":"&nbsp;",1:$ZCVT(tUsrReq,"O","HTML")))#</TD>
				<TD CLASS='first'>#($ZCVT(tStdReq,"O","HTML"))#</TD>
				<TD CLASS='first'>#($ZCVT(tActReq,"O","HTML"))#</TD>
				<TD CLASS='first'>#($ZCVT(tMaxUse,"O","HTML"))#</TD>
				<TD CLASS='first'>#($ZCVT(tPos,"O","HTML"))#</TD>
				>
				For tIndent=1:1:tLoopIndent &HTML<<TD CLASS='first'>&nbsp;</TD>>
				&HTML<<TD CLASS='first'><A TITLE='#($ZCVT($S($G(segs(tOrdinal,"type"))=tSegID:segs(tOrdinal),1:"SS:"_pCategory_":"_pSet_":"_tSegID_"-"_tOrdinal),"O","HTML"))#' HREF='#($classname())#.cls?DocType=#($ZCVT(pCategory_":"_pSet,"O","URL"))#&SegType=#($ZCVT(tSegID_"-"_tOrdinal,"O","URL"))#'>#($ZCVT(tSegID_"-"_tOrdinal,"O","HTML"))#</A></TD><TD CLASS='first'>#($ZCVT(tSegExp,"O","HTML"))#</TD></TR>>
				
			} ElseIf tDescType="lb" {
				
				Set tLoopIndent=tLoopIndent+1
				
				#; Loop Begin
				Set tLoopID=$Piece(tDesc,"|",2),tActReq=$Piece(tDesc,"|",4),tMaxUse=$Piece(tDesc,"|",5)
				&HTML<<TR>>	
				For tIndent=1:1:tLoopIndent+5 &HTML<<TD CLASS='first'>&nbsp;</TD>>
				&HTML<
				<TD CLASS='first'>LOOP ID - #($ZCVT(tLoopID,"O","HTML"))#</TD>
				<TD CLASS='first'>REQ: #($ZCVT(tActReq,"O","HTML"))#</TD>
				<TD CLASS='first'>MAX: #($ZCVT(tMaxUse,"O","HTML"))#</TD>
				</TR>
				>
				For tIndent=1:1:tLoopIndent+5 &HTML<<TD CLASS='first'>&nbsp;</TD>>
				&HTML<<TD CLASS='first'><B>SEG ID</B></TD><TD CLASS='first'><B>SEG NAME</B></TD></TR>>
				
			} ElseIf tDescType="le" {
				
				#; Loop End
				Set tLoopIndent=tLoopIndent-1
			}
		}
		&HTML<</TABLE>>
		
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	
	#; Get the expanded Agency name
	Set tDocInfo=$G(^EnsEDI.Schema($Piece(..DocType,":")),"_")
	Set tAgency=$Piece(tDocInfo,"|")
	Set tFamily=$Case(tAgency,"UN":"EDIFACT","X":"X12",:tAgency)
		
	#; Use the expanded Agency name
	Set tPageName = $$$FormatText($$$Text("%1 Schemas","Ensemble"),tFamily)
	Set pLink(2)=$LB(tPageName,"EnsPortal.EDI."_$S(tFamily="EDIFACT":"SEF",1:$zconvert(tFamily,"O","URL"))_".SchemaMain.zen?FAMILY="_$zconvert(tFamily,"O","URL"))
	Set tPageName = $$$FormatText($$$Text("%1 Validation Structure","Ensemble"),tFamily)
	Set pLink(3)=$LB(tPageName,"EnsPortal.EDI.ValidationStructure.zen?DocType="_$zconvert(..DocType,"O","URL"))
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Validation Structure","Ensemble")
}

}
