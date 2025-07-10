/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

Class EnsLib.EDI.EDIFACT.Util.FormatHTML Extends EnsLib.EDI.IOFormatInterface [ Abstract, System = 4 ]
{

Parameter ChildLinks = 10;

/// Return 1 if we took care of the whole document or got an error. Returning 0 means the caller will continue doing component segments as usual.
ClassMethod OutputDocument(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String) As %Boolean
{
	Set tSC=$$$OK
	Set:""=pSeparators pSeparators=pDocObj.Separators  
	Set:""=pSeparators pSeparators=$$$EDIFACTDefSeparators 
	Set:""=$$$SEGTERM(pSeparators) pSeparators=pSeparators_pDocObj.SegmentTerminator Set $$$SEGTERM(pSeparators)=$ZStrip($$$SEGTERM(pSeparators),"*CW")
	Do pIOStream.WriteLine(
	"<table border=""0"" cellspacing=""0"" cellpadding=""0"" cols=""2"" width=""100%""><tr><td align=""center""><div class=""Text"" style=""margin: 3px;"">",,.pStatus)  Quit:$$$ISERR(pStatus) 1
	If ""'=pDocObj.DocType {
		Do:""=pDocObj.BuildMapStatus||'$D($$$vaMobj(pDocObj,"runtimePath")) pDocObj.BuildMap()
		Set tDesc=##class(EnsLib.EDI.SEF.Schema).GetDescription("DS:"_pDocObj.DocType)
		Do pIOStream.WriteLine("EDIFACT <b>"_$ZCVT(pDocObj.Name,"O","HTML")_"</b> document - Id = <b>"_pDocObj.%Id()_"</b>, DocType = '<a"_$S(""=tDesc:"",1:" title='"_$ZCVT(tDesc,"O","HTML")_"'")_..getDocLink(pDocObj.DocType)_"><b>"_$ZCVT(pDocObj.DocType,"O","HTML")_"</b></a>'"_
			"<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"_$S(""=tDesc:"", 1:"'<b><i>"_$ZCVT(tDesc,"O","HTML")_"</i></b>', ")_"<b>"_pDocObj.SegCount_"</b> Segments"_..linkParents(pDocObj),,.pStatus)  Quit:$$$ISERR(pStatus) 1
		If $$$ISERR(pDocObj.BuildMapStatus) {
			Set tErr=$ZCVT($$GetOneErrorText^%apiOBJ(pDocObj.BuildMapStatus),"O","HTML")
			Do pIOStream.WriteLine("<br>&nbsp;&nbsp;&nbsp;BuildMapStatus = '<b>"_tErr_"</b>'",,.pStatus)  Quit:$$$ISERR(pStatus) 1
			For i=2:1 { Set tErr=$$GetOneErrorText^%apiOBJ(pDocObj.BuildMapStatus,i)  Quit:""=tErr
				Do pIOStream.WriteLine("<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'"_$ZCVT(tErr,"O","HTML")_"'",,.pStatus)  Quit:$$$ISERR(pStatus)
			} Quit:$$$ISERR(pStatus) 1
		}
	} Else {
		Do pIOStream.WriteLine("EDIFACT <b>"_$ZCVT(pDocObj.Name,"O","HTML")_"</b> document - Id = <b>"_pDocObj.%Id()_"</b>, DocType = <b>''</b>, <b>"_pDocObj.SegCount_"</b> Segments"_..linkParents(pDocObj),,.pStatus)  Quit:$$$ISERR(pStatus) 1
	}
	Do pIOStream.WriteLine("</div></td></tr></table>",,.pStatus)  Quit:$$$ISERR(pStatus) 1
	Do:'$D($$$vaMobj(pDocObj,"runtimeIndex"))&&$D($$$vaMobj(pDocObj,"runtimePath")) pDocObj.buildRuntimeIndexFromPath()
	Set tCnt=$G($$$vaMobj(pDocObj,"runtimeIndex"))
	If tCnt<=0 { Do pIOStream.WriteLine("<center>No Segments</center>",,.pStatus)  Quit:$$$ISERR(pStatus) 1 }
	Else {
		Do pIOStream.WriteLine("<table class=""EDIDocumentTable"" BORDER=""0"" CELLSPACING=""0"" CELLPADDING=""0"">",,.pStatus)  Quit:$$$ISERR(pStatus) 1
		For i=1:1:tCnt {
			If i>300&&(i<=(tCnt-100)) {
				If i=301 {
					Do pIOStream.WriteLine("<TR CLASS=""EDIDocumentTableRow""><TD CLASS=""EDIDocumentTableExpandor"">&nbsp;</TD>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Do pIOStream.WriteLine("<td class='EDIDocumentTableSegnum'>....&nbsp;</td><td class='EDIDocumentTableSegid' SegID='....'> </td>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Do pIOStream.WriteLine("<td class='EDIDocumentTableSegname'>&nbsp;</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Do pIOStream.WriteLine("<td>Segments 301 to "_(tCnt-100)_" not shown ...</td></TR>",,.pStatus)  Quit:$$$ISERR(pStatus)
				}
				Continue
			}
			Set tPath=$G($$$vaMobja(pDocObj,"bidirectionalLink",i),i)
			Set seg=pDocObj.getSegmentByIndex(i)
			Do pIOStream.WriteLine("<TR CLASS=""EDIDocumentTableRow""><TD CLASS=""EDIDocumentTableExpandor"">&nbsp;</TD>",,.pStatus)  Quit:$$$ISERR(pStatus)
			Do ..OutputSegment(seg,.tSC,pIOStream,pSeparators,i,tPath,pDocObj)  Quit:$$$ISERR(tSC)
			Do pIOStream.WriteLine("</TR>",,.pStatus)  Quit:$$$ISERR(pStatus)
			Do pDocObj.commitSegmentByIndex(i)
		}
		Do pIOStream.WriteLine("</table>",,.pStatus)  Quit:$$$ISERR(pStatus) 1
	}
	If $$$ISERR(tSC) Do pIOStream.WriteLine($ZCVT($$$StatusDisplayString(tSC),"O","HTML"),,.pStatus)  Set pStatus=$$$ADDSC(tSC,pStatus)
	Quit 1
}

ClassMethod OutputDocumentEnd(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String)
{
	Set pStatus=$$$OK
	Quit ; no return value
}

/// Return 1 if we took care of the segment or got an error. Returning 0 means the caller will output the segment as usual.
ClassMethod OutputSegment(pSegObj As EnsLib.EDI.Segment, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSegNum As %String, pSegPath As %String, pParentDoc As EnsLib.EDI.Document) As %Boolean
{
	Set:""=$G(pSeparators) pSeparators=pSegObj.Separators
	Set tFullLen=pSegObj.FullSize
	Set pSeparators=$E(pSeparators,1,(4+($E(pSeparators,5)'?1C))) ; include the 1st segment terminator if it is printable
	Do pSegObj.decompose()
	Set tName=pSegObj.Header, tES=$ZCVT($$$ELESEP(pSeparators),"O","HTML"), tCS=$ZCVT($$$COMSEP(pSeparators),"O","HTML"), tRS=$ZCVT($$$REPSEP(pSeparators),"O","HTML")
	Set:""=tName tName="x"
	Set tDocType=pSegObj.DocType
	Set pStatus=..outputHTMLStart(pIOStream,pSegNum,pSegPath,pSegObj.ID,tName,tDocType,tFullLen,$S($IsObject(pParentDoc):pParentDoc.DocType,1:""))  Quit:$$$ISERR(pStatus) 1
	Set tReplaceSpec(" ")="&nbsp;"
	Set tReplaceSpec($C(9))="\t"
	Set tReplaceSpec($C(13))="\r"
	Set tReplaceSpec($C(10))="\n"
	Set iCat=$P(tDocType,":"), iTrans=$P(tDocType,":",2), iSeg=$P(tDocType,":",3), iOrd=+$P(iSeg,"-",2)
	If ""=iCat||(""=iTrans)||(""=iSeg)||'iOrd {
		Set (iCat,iTrans,iSeg)=0
	} Else {
		Set tSC=##class(EnsLib.EDI.SEF.Schema).getFieldsContentArray(.tContents,"source",iCat,iTrans,iSeg,0)
	}
	Set iCnt=pSegObj.GetValueAt("*")
	If iCnt<1 { Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'>&nbsp</td>",,.pStatus)  Quit:$$$ISERR(pStatus) 1 }
	Else { For i=1:1:iCnt {
		Set iN=$ZCVT($P($E($G(tContents(i,"name"),":"_i),1,*),"("),"O","HTML")
		Set tEleDesc=$G($$$vaSchemaGbl(iCat,iTrans,"o",iOrd,i))
		Set tIsComp=$P(tEleDesc,"|")
		If tIsComp'="C" {
			Set tEleID=$P(tEleDesc,"|",2),tActReq=$P(tEleDesc,"|",3),tType=$P(tEleDesc,"|",4)
			Set tMinLen=$P(tEleDesc,"|",5),tMaxLen=$P(tEleDesc,"|",6),tMaxUse=$P(tEleDesc,"|",7)
			Set tAttr=$S(tMaxUse>1:tMaxUse,1:"")_tActReq_"("_$S(tMinLen=tMaxLen:tMinLen,1:tMinLen_"-"_tMaxLen)_")"
		} Else { Set tMaxUse=$P(tEleDesc,"|",6), tAttr="" }

		If tName="UNA" && (i=1) {
			Do pIOStream.WriteLine("<td nowrap class='EDISegmentsTableSeparator'><a title='"_$S(i=iN:"",1:i_" / ")_iN_$S(""=tAttr:"",1:" / "_tAttr)_"'"_..getSegLink(tDocType,i)_">"_$Replace($ZCVT(pSegObj.GetValueAt(i,pSeparators),"O","HTML")," ","&nbsp;")_"</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)
			Continue
		} Else {
			Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tES_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
		}
		If ""=pSegObj.GetValueAt(i) Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'><a title='"_$S(i=iN:"",1:i_" / ")_iN_$S(""=tAttr:"",1:" / "_tAttr)_"'"_..getSegLink(tDocType,i)_">&nbsp;&middot;</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)  Continue
		Set rCnt=pSegObj.GetValueAt(i_"(*)")
		Set rF=1  For r=1:1:rCnt {
			Set rN=iN,rpN=iN,rAlias=i,rpAlias=i
			If rCnt>1||(tMaxUse>1) { Set rp=r_$S(iSeg'=0&&(rCnt>tMaxUse)&&(tMaxUse'=1):"*",1:"")
				Set rpN=rN_"("_rp_")", rN=rN_"("_r_")"
				Set rpAlias=rAlias_"("_rp_")", rAlias=rAlias_"("_r_")"
			}
			If rF { Set rF=0 } Else { Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tRS_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus) }

			Set cCnt=pSegObj.GetValueAt(i_"("_r_").*")
			Set cF=1  For c=1:1:cCnt {
				Set cN=rN,cpN=rpN,cAlias=rAlias,cpAlias=rpAlias  If tIsComp="C"||(cCnt>1) {
					Set cN=cN_"."_$ZCVT($P($G(tContents(i,c,"name"),c),"("),"O","HTML")
					Set cpN=cpN_"."_$ZCVT($P($G(tContents(i,c,"name"),c),"("),"O","HTML")
					Set cAlias=cAlias_"."_c
					Set cpAlias=cpAlias_"."_c
				}
 				if tIsComp="C" {
					Set cEleDesc=$G($$$vaSchemaGbl(iCat,iTrans,"o",iOrd,i,c))
					Set cEleID=$P(cEleDesc,"|",2),cActReq=$P(cEleDesc,"|",3),cType=$P(cEleDesc,"|",4)
					Set cMinLen=$P(cEleDesc,"|",5),cMaxLen=$P(cEleDesc,"|",6),cMaxUse=$P(cEleDesc,"|",7)
					Set cAttr=$S(cMaxUse>1:cMaxUse,1:"")_cActReq_"("_$S(cMinLen=cMaxLen:cMinLen,1:cMinLen_"-"_cMaxLen)_")"
 				} Else { Set cAttr=tAttr }
				If cF { Set cF=0 } Else { Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tCS_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus) }

				Set tVal=pSegObj.GetValueAt(cAlias,pSeparators)
				set tElemname=$P($P(cN,":",2),".",$L(cN,"."))
				set tElemDesc=$G($$$vaSchemaDescGbl("UN","EDIFACT","ELEM",$G(tElemname,"-1")))
				
				If ""=tVal Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'><a title='"_$S(cpAlias=cpN:"",1:cpAlias_" / ")_cpN_$S(""=cAttr:"",1:" / "_cAttr)_"'"_..getSegLink(tDocType,i)_">&nbsp;&middot;</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)  Continue
				Do pIOStream.Write("<td nowrap class='EDISegmentsTableValue'><a title='"_tElemDesc_" / "_$S(cpAlias=cpN:"",1:cpAlias_" / ")_cpN_$S(""=cAttr:"",1:" / "_cAttr)_"'"_..getSegLink(tDocType,i)_">",,.pStatus)  Quit:$$$ISERR(pStatus)
				Set:$L(tVal)>2000 tVal=$E(tVal,1,2000)_" ..."
				While ""'=tVal { Set tPiece=$E(tVal,1,1000), tVal=$E(tVal,1001,*) Do pIOStream.Write($$replaceArray^EnsUtil($ZCVT(tPiece,"O","HTML"),.tReplaceSpec),,.pStatus)  Quit:$$$ISERR(pStatus) }
				Do pIOStream.WriteLine("</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)
			} Quit:$$$ISERR(pStatus)
		} Quit:$$$ISERR(pStatus)
	} Quit:$$$ISERR(pStatus) 1 }
	If $IsObject(pParentDoc)&&("DocsRef"=$E(tName,*-$L("DocsRef")+1,*)) {
		Set pStatus=..outputChildLinks(pIOStream, pSegObj, pParentDoc,$E(tName,1,*-$L("DocsRef")))  Quit:$$$ISERR(pStatus) 1
	}
	Do pIOStream.WriteLine("<td class='EDIDocumentTableSegname'>"_$ZCVT($$$SEGTERM(pSeparators),"O","HTML")_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
	Set pStatus=..outputHTMLEnd(pIOStream)
	Quit 1
}

ClassMethod outputChildLinks(pIOStream As %IO.I.CharacterStream, pSegObj As EnsLib.EDI.Segment, pDocsRefParent, tTypeName) As %Status
{
	Set tNumChildren=pDocsRefParent.ChildCount
	Set tActionURL="EDIDocumentView.csp"
	Set tParentClass=$classname(pDocsRefParent), tParentId=pDocsRefParent.%Id(), tParentRef=pSegObj.GetValueAt($$$REFSEGFLDINDEX)
	Set color=$S(tNumChildren=pSegObj.GetValueAt(2):"",1:"red")

	Do pIOStream.WriteLine("<td class='EDIDocumentTableSegname' title='What follows is a list of links to child documents'>&nbsp;"_tTypeName_" documents&nbsp;:&nbsp;</td>",,.tSC)  Quit:$$$ISERR(tSC) tSC

	#; pre-fetch the first 5
	Set tIdVal=tParentId_":"_tParentRef
	&sql(Declare c0 Cursor For Select ID,Name Into :tChildId,:tChildName
		 From EnsLib_EDI_EDIFACT.Document
		 Where ParentId = :tIdVal Order By ID)
	&sql(OPEN c0)
	Set pre(0)=0 For f=1:1:..#ChildLinks/2 { &sql(FETCH c0)  If SQLCODE Set f=f-1 Quit
		Set pre(f)=tChildId, pre(f,"name")=tChildName
	} &sql(CLOSE c0)
	If f=(..#ChildLinks/2) {
		#; pre-fetch the last 5
		Set tChild5Id=pre(f)
		&sql(Declare c2 Cursor For Select ID,Name Into :tChildId,:tChildName
			 From EnsLib_EDI_EDIFACT.Document
			 Where ParentId = :tIdVal
			 And ID>:tChild5Id Order By ID desc)
		&sql(OPEN c2)
		#; put the last one at position f+1, counting down from there as 'i' goes up
		For e=f+1:1:..#ChildLinks { &sql(FETCH c2)  If SQLCODE Set e=e-1 Quit
			Set pre(e)=tChildId, pre(e,"name")=tChildName
		} &sql(CLOSE c2)
	} Else { Set e=f }
	#; Output the first 5 or all if fewer than 5 (assuming ..#ChildLinks/2 = 5)
	For i=1:1:f {
		Set tDocLink = "EDIDocumentView.csp?CLASS="_$$$URLENCODE($classname(pDocsRefParent))_"&NAME="_$ZCVT("EDIFACT Document","O","URL")_"&ORIGIN=EDIDoc&EDIDOCID="_pre(i)_"&DOCSPEC=Stored#doc_content"
		If $IsObject($get(%request)) Set tDocLink = ##class(%CSP.Page).Link(tDocLink)
		Do pIOStream.WriteLine("<td><a target=_blank title=""EDIFACT "_tTypeName_" Document Database Id = "_pre(i)_$C(13,10)_"type Name = '"_pre(i,"name")_"'"" method=get href="_tDocLink_">&lt;"_pre(i)_"&gt;</a>",,.tSC)  Quit:$$$ISERR(tSC)
	} Quit:$$$ISERR(tSC) tSC
	If e=..#ChildLinks {
		Set tChild5Id=pre(f), tChild6Id=pre(e)
		#; Now do up to 100 more
		&sql(Declare c1 Cursor For Select ID,Name Into :tChildId,:tChildName
			 From EnsLib_EDI_EDIFACT.Document
			 Where ParentId = :tIdVal
			 And ID>:tChild5Id And ID<:tChild6Id Order By ID)
		&sql(OPEN c1)
	
		Set tTitle="" For i=1:1:100 { &sql(FETCH c1)  If SQLCODE Set i=i-1 Quit
			Set tTitle=tTitle_tChildId_" ("_tChildName_"), "
		}
		#; Check for any more left after 100
		Set tChildId=""
		If 'SQLCODE { &sql(FETCH c1) }
		&sql(CLOSE c1)
		Set tTitle=$S(""'=tChildId:tTitle_"...", 1:$E(tTitle,1,*-2))
		If i {
			Do pIOStream.WriteLine("<td><form name=""theForm"" target=_blank method=get action="_tActionURL_"#doc_content>",, .tSC)  Quit:$$$ISERR(tSC) tSC
			Do pIOStream.WriteLine(##class(%CSP.Page).InsertHiddenFields(tActionURL_"#doc_content"),,.tSC)  Quit:$$$ISERR(tSC) tSC
			Do pIOStream.WriteLine("<input TYPE=""integer"" NAME=""EDIDOCID"" VALUE="""_$P(tTitle," (")_""" SIZE=""6""/>"_
				"<center><input type=""submit"" name=""ViewOther"" title="""_$ZCVT(tTitle,"O","HTML")_""" value=""Other""></center>"_
				"<input type=""hidden"" name=""CLASS"" value="""_tParentClass_""">"_
				"<input type=""hidden"" name=""NAME"" value=""EDIFACT Document"">"_
				"<input type=""hidden"" name=""ORIGIN"" value=""EDIDoc"">"_
				"<input type=""hidden"" name=""DOCSPEC"" value=""Stored"">"_
			"</form></td>",, .tSC)  Quit:$$$ISERR(tSC) tSC
		}
	}
	#; if total > ..#ChildLinks/2, Output the trailing direct links
	For i=e:-1:f+1 {
		Do pIOStream.WriteLine("<td><a target=_blank title=""EDIFACT "_tTypeName_" Database Id = "_pre(i)_$C(13,10)_"type Name = '"_pre(i,"name")_"'"" method=get href="_##class(%CSP.Page).Link("EDIDocumentView.csp?CLASS="_$$$URLENCODE($classname(pDocsRefParent))_"&NAME="_$ZCVT("EDIFACT Document","O","URL")_"&ORIGIN=EDIDoc&EDIDOCID="_pre(i)_"&DOCSPEC=Stored#doc_content")_">&lt;"_pre(i)_"&gt;</a>",,.tSC)
	}
	Quit tSC
}

ClassMethod outputHTMLStart(pIOStream As %IO.I.CharacterStream, pSegNum, pSegPath, pID, pName, pDocType, pFullLen, pMsgStructure) As %Status [ Internal ]
{
	Set tSegName=$P($P(pDocType,"!"),"-")_"-"_$P(pDocType,"-",2)
	Set tKeyFields=$P($P(pDocType,"-"),"!",2)
	Set tDesc=$S(""=pDocType:"", 1:##class(EnsLib.EDI.SEF.Schema).GetDescription("SS:"_pDocType))
	Set len=$S(pFullLen<=2000:"",1:" (len="_pFullLen_")")
	Do pIOStream.WriteLine(
	"<td class='EDIDocumentTableSegnum'>"_(pSegNum)_"&nbsp;</td><td class='EDIDocumentTableSegid' SegID='"_(pID)_"'>"_($S(""=pID:"*",1:"&nbsp;"))_"</td>"_
	"<td class='EDIDocumentTableSegname'>"_
		"<a title='"_$S(pSegNum=pSegPath&&(""'=pDocType):"SS:"_pDocType, 1:$ZCVT(pSegPath_$S(""=tDesc:"", 1:" - "_tDesc)_$S(""=tKeyFields:"",1:" (!"_tKeyFields_")"),"O","HTML"))_len_"'"_..getSegLink(pDocType,,$S(pSegNum=pSegPath&&(""'=pDocType):"", 1:$ZCVT(pSegPath,"O","HTML")),$ZCVT(pMsgStructure,"O","HTML"))_">"_pName_
	"</a></td><td><table class='EDISegmentsTable'><tr>",,.tSC)
	Quit tSC
}

ClassMethod linkParents(pDocObj) As %String [ Internal ]
{
	Set tOutStr=""
	Set tChildCount=pDocObj.ChildCount
	Set:tChildCount tOutStr=tOutStr_", <b>"_tChildCount_"</b> "_$S(tChildCount>1:"child documents", 1:"child document")
	Set tNumParents=$LL(pDocObj.ParentIds)
	If tNumParents {
		Set tOutStr=tOutStr_", "_$S(tNumParents>1:"parent documents ", 1:"parent document ")
		Set tParent=pDocObj.Parent
		While $IsObject(tParent) {
			Set tOutStr=tOutStr_": <a target='_blank' title='EDIFACT Document Database Id = "_tParent.%Id()_"', Type Name = '"_tParent.Name_"' method=get href="_##class(%CSP.Page).Link("EDIDocumentView.csp?CLASS="_$$$URLENCODE($classname(tParent))_"&NAME="_$ZCVT("EDIFACT Document","O","URL")_"&ORIGIN=EDIDoc&EDIDOCID="_tParent.%Id()_"&DOCSPEC=Stored#doc_content")_">&lt;"_tParent.%Id()_"&gt;</a>"
			Set tParent=tParent.Parent
		}
	}
	Quit tOutStr
}

ClassMethod getSegLink(pDocType, pAnchor = "", pPath = "", pMsgStructure = "") As %String [ Internal ]
{
	Set:pDocType["!" pDocType=$P(pDocType,"!")_"-"_$P(pDocType,"-",2)
	Quit:""=pDocType||'##class(EnsLib.EDI.SEF.Schema).ElementExists("SS:"_pDocType) ""
	Quit " href='"_##class(%CSP.Page).Link("EnsPortal.EDI.ValidationStructure.zen?DocType="_$$$URLENCODE($P(pDocType,":",1,2))_"&SegType="_$$$URLENCODE($P(pDocType,":",3))_$S(""=pPath:"",1:"&PATH="_$$$URLENCODE(pPath))_$S(""=pMsgStructure:"",1:"&MS="_$$$URLENCODE(pMsgStructure))_$S(""=pAnchor:"",1:"#"_pAnchor))_"' target='_blank'"
}

ClassMethod getDocLink(pDocType) As %String [ Internal ]
{
	Quit:""=pDocType||'##class(EnsLib.EDI.SEF.Schema).ElementExists("DS:"_pDocType) ""
	Quit " href='"_##class(%CSP.Page).Link("EnsPortal.EDI.ValidationStructure.zen?DocType="_$$$URLENCODE(pDocType))_"' target='_blank'"
}

ClassMethod outputHTMLEnd(pIOStream As %IO.I.CharacterStream) As %Status [ Internal ]
{
	Do pIOStream.WriteLine("</tr></table></td>",,.tSC)
	Quit tSC
}

}
