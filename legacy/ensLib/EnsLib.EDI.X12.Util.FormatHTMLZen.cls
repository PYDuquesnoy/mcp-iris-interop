/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Util.FormatHTMLZen Extends EnsLib.EDI.IOFormatInterface [ Abstract, System = 4 ]
{

Parameter ChildLinks = 10;

/// Return 1 if we took care of the whole document or got an error. 
/// Returning 0 means the caller will continue doing component segments as usual.
ClassMethod OutputDocument(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String) As %Boolean
{
	Set tSC=$$$OK
	Set tVDoc = $ZCVT($$$Text("X12","EDIDocumentView"),"O","HTML")
	Set tDoc = $ZCVT($$$Text("Document","EDIDocumentView"),"O","HTML")
	Set tId = $ZCVT($$$Text("Id","EDIDocumentView"),"O","HTML")
	Set tType = $ZCVT($$$Text("DocType","EDIDocumentView"),"O","HTML")
	Set tSeg = $ZCVT($$$Text("Segments","EDIDocumentView"),"O","HTML")
	Set tSegNo = $ZCVT($$$Text("No Segments","EDIDocumentView"),"O","HTML")
	Set tBMS = $ZCVT($$$Text("Build Map Status","EDIDocumentView"),"O","HTML")
	Set:""=pSeparators pSeparators=pDocObj.Separators  
	Set:""=pSeparators pSeparators=$$$X12DefSeparators 
	Set:""=$$$SEGTERM(pSeparators) pSeparators=pSeparators_..SegmentTerminator  Set $$$SEGTERM(pSeparators)=$ZStrip($$$SEGTERM(pSeparators),"*CW")
	Do pIOStream.WriteLine(
	"<table border=""0"" cellspacing=""0"" cellpadding=""0"" nowrap width=""1200px""><tr><td align=""left""><div style=""font-size:9pt; margin: 3px;"">",,.pStatus)  Quit:$$$ISERR(pStatus) 1
	If ""'=pDocObj.DocType {
		Do:""=pDocObj.BuildMapStatus||'$D($$$vaMobj(pDocObj,"runtimePath")) pDocObj.BuildMap()
		Set tDesc=##class(EnsLib.EDI.X12.Schema).GetDescription("DS:"_pDocObj.DocTypeCategory_":"_pDocObj.DocTypeName)
		Do pIOStream.WriteLine(
			tVDoc_" <b>"_$ZCVT(pDocObj.Name,"O","HTML")_"</b> "_tDoc_" - "_tId_" = <b>"_pDocObj.%Id()_"</b>,"_
			tType_" = '<a"_$S(""=tDesc:"",1:" title='"_$ZCVT(tDesc,"O","HTML")_"'")_..getDocLink(pDocObj.DocType)_"><b>"_$ZCVT(pDocObj.DocType,"O","HTML")_
			"</b></a>'"_"<br>"_$S(""=tDesc:"", 1:"'<b><i>"_$ZCVT(tDesc,"O","HTML")_"</i></b>', ")_"<b>"_
			pDocObj.SegCount_"</b> "_tSeg_..linkParents(pDocObj),,.pStatus)  Quit:$$$ISERR(pStatus) 1
		If $$$ISERR(pDocObj.BuildMapStatus) {
			Set tErr=$ZCVT($$GetOneErrorText^%apiOBJ(pDocObj.BuildMapStatus),"O","HTML")
			Do pIOStream.WriteLine("<br>"_tBMS_" = '<b>"_tErr_"</b>'",,.pStatus)  Quit:$$$ISERR(pStatus) 1
			For i=2:1 { Set tErr=$$GetOneErrorText^%apiOBJ(pDocObj.BuildMapStatus,i)  Quit:""=tErr
				Do pIOStream.WriteLine("<br>'"_$ZCVT(tErr,"O","HTML")_"'",,.pStatus)  Quit:$$$ISERR(pStatus)
			} Quit:$$$ISERR(pStatus) 1
		}
	} Else {
		Do pIOStream.WriteLine("X12 <b>"_$ZCVT(pDocObj.Name,"O","HTML")_"</b> "_tDoc_" - "_tId_" = <b>"_pDocObj.%Id()_"</b>, DocType = <b>''</b>, <b>"_
			pDocObj.SegCount_"</b> "_tSeg_..linkParents(pDocObj),,.pStatus)  Quit:$$$ISERR(pStatus) 1
	}
	Do pIOStream.WriteLine("</div></td></tr></table>",,.pStatus)  Quit:$$$ISERR(pStatus) 1
	Do:'$D($$$vaMobj(pDocObj,"runtimeIndex"))&&$D($$$vaMobj(pDocObj,"runtimePath")) pDocObj.buildRuntimeIndexFromPath()
	Set tCnt=$G($$$vaMobj(pDocObj,"runtimeIndex"))
	If tCnt<=0 { Do pIOStream.WriteLine("<center>"_tSegNo_"</center>",,.pStatus)  Quit:$$$ISERR(pStatus) 1 }
	Else {
		Do pIOStream.WriteLine("<table class=""EDIDocumentTable"" BORDER=""0"" CELLSPACING=""0"" CELLPADDING=""0"">",,.pStatus)  Quit:$$$ISERR(pStatus) 1
		For i=1:1:tCnt {
			If i>300&&(i<=(tCnt-100)) {
				If i=301 {
					Do pIOStream.WriteLine("<TR CLASS=""EDIDocumentTableRow""><TD CLASS=""EDIDocumentTableExpandor"">&nbsp;</TD>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Do pIOStream.WriteLine("<td class='EDIDocumentTableSegnum'>....&nbsp;</td><td class='EDIDocumentTableSegid' SegID='....'> </td>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Do pIOStream.WriteLine("<td class='EDIDocumentTableSegname'>&nbsp;</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
					Set tCount = $ZCVT($$$FormatText($$$Text("Segments 301 to %1 not shown ...","EDIDocumentView"),(tCnt-100)),"O","HTML")
					Do pIOStream.WriteLine("<td>"_tCount_"</td></TR>",,.pStatus)  Quit:$$$ISERR(pStatus)
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
	Set pSeparators=$E(pSeparators,1,(3+($E(pSeparators,4)'?1C))) ; include the 1st segment terminator if it is printable
	Do pSegObj.decompose()
	Set tName=pSegObj.Name, tES=$ZCVT($$$ELESEP(pSeparators),"O","HTML"), tCS=$ZCVT($$$COMSEP(pSeparators),"O","HTML"), tRS=$ZCVT($$$REPSEP(pSeparators),"O","HTML")
	Set:""=tName tName="x"
	Set tDocType=pSegObj.DocType
	Set pStatus=..outputHTMLStart(pIOStream,pSegNum,pSegPath,pSegObj.ID,tName,tDocType,tFullLen,$S($IsObject(pParentDoc):pParentDoc.DocType,1:""))  Quit:$$$ISERR(pStatus) 1
	Set tReplaceSpec(" ")="&nbsp;"
	Set tReplaceSpec($C(9))="\t"
	Set tReplaceSpec($C(13))="\r"
	Set tReplaceSpec($C(10))="\n"
	Set iCat=$P(tDocType,":"), iSeg=$P(tDocType,":",2)
	If ""=iCat||(""=iSeg) {
		Set iList=""
	} Else {
		Set iList=$G($$$vaSchemaGbl(iCat,"SS",iSeg))
		Set pStatus=##class(EnsLib.EDI.X12.Schema).getFieldsContentArray(.tContents,"source",iCat,iSeg,0)
	}
	Set iCnt=pSegObj.GetValueAt("*")
	If iCnt<1 { Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'>&nbsp</td>",,.pStatus)  Quit:$$$ISERR(pStatus) 1 }
	Else { For i=1:1:iCnt {
		Set iN=$ZCVT($P($E($G(tContents(i,"name"),":"_i),1,*),"("),"O","HTML")
		Set iAttrs=$LG(iList,i), iDT=$LG(iAttrs,1), iMin=$LG(iAttrs,2), iRep=$LG(iAttrs,3), iLen=$LG(iAttrs,4), iReq=$LG(iAttrs,5)
		Set tAttr=$S(iRep>1:iRep,1:"")_$S(iLen:"("_$S(iMin=iLen:iMin,1:iMin_"-"_iLen)_")",1:"")
		If iDT[":" {
			Set cCat=$P(iDT,":"),cTyp=$P(iDT,":",2)
			Set cList=$G($$$vaSchemaGbl(cCat,"CS",cTyp))
		}
		If tName="ISA" && ((i=($$$ISAInterchangeControlStandardsI))||(i=($$$ISAComponentElementSeparator))) {
			Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tES_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
			Do pIOStream.WriteLine("<td nowrap class='EDISegmentsTableValue'><a title='"_$S(i=iN:"",1:i_" / ")_iN_$S(""=tAttr:"",1:" / "_tAttr)_"'"_..getSegLink(tDocType,i)_">"_$ZCVT(pSegObj.GetValueAt(i,pSeparators),"O","HTML")_"</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)
			Continue
		} Else {
			/* Exit For loop if all remaining fields are null so as not to show separators */
			#dim moreFieldsToShow = 0
			#dim stillToShow
			For stillToShow=i:1:iCnt {
				If (pSegObj.GetValueAt(stillToShow)'="") {
					Set moreFieldsToShow = 1
					Quit
				}
			}
			If 'moreFieldsToShow Quit
			Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tES_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus)
		}

		If ""=pSegObj.GetValueAt(i) Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'><a title='"_$S(i=iN:"",1:i_" / ")_iN_$S(""=tAttr:"",1:" / "_tAttr)_"'"_..getSegLink(tDocType,i)_">&nbsp;&middot;</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)  Continue
		Set rCnt=pSegObj.GetValueAt(i_"(*)")
		Set rF=1  For r=1:1:rCnt {
			Set rN=iN,rpN=iN,rAlias=i,rpAlias=i
			If rCnt>1||(iRep>1) { Set rp=r_$S(iList'=""&&(rCnt>iRep)&&(iRep'=1):"*",1:"")
				Set rpN=rN_"("_rp_")", rN=rN_"("_r_")"
				Set rpAlias=rAlias_"("_rp_")", rAlias=rAlias_"("_r_")"
			}
			If rF { Set rF=0 } Else { Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tRS_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus) }

			Set cCnt=pSegObj.GetValueAt(i_"("_r_").*")
			Set cF=1  For c=1:1:cCnt {
				If iDT[":" {
					Set cAttrs=$LG(cList,c), cDT=$LG(cAttrs,1), cMin=$LG(cAttrs,2), cRep=$LG(cAttrs,3), cLen=$LG(cAttrs,4), cReq=$LG(cAttrs,5)
					Set cAttr=$S(cRep>1:cRep,1:"")_$S(cLen:"("_$S(cMin=cLen:cMin,1:cMin_"-"_cLen)_")",1:"")
				} Else {
					Set cDT=iDT, cAttr=""
				}
				Set cN=rN,cpN=rpN,cAlias=rAlias,cpAlias=rpAlias  If iDT[":"||(cCnt>1) {
					Set cN=cN_"."_$ZCVT($P($G(tContents(i,c,"name"),c),"("),"O","HTML")
					Set cpN=cpN_"."_$ZCVT($P($G(tContents(i,c,"name"),c),"("),"O","HTML")
					Set cAlias=cAlias_"."_c
					Set cpAlias=cpAlias_"."_c
				}
				If cF { Set cF=0 } Else { Do pIOStream.WriteLine("<td class='EDISegmentsTableSeparator'>"_tCS_"</td>",,.pStatus)  Quit:$$$ISERR(pStatus) }

				Set tVal=pSegObj.GetValueAt(cAlias,pSeparators)
				If ""=tVal Do pIOStream.WriteLine("<td class='EDISegmentsTableEmptyfield'><a title='"_$S(cpAlias=cpN:"",1:cpAlias_" / ")_cpN_$S(""=cAttr:"",1:" / "_cAttr)_"'"_..getSegLink(tDocType,i)_">&nbsp;&middot;</a></td>",,.pStatus)  Quit:$$$ISERR(pStatus)  Continue
				Do pIOStream.Write("<td nowrap class='EDISegmentsTableValue'><a title='"_$S(cpAlias=cpN:"",1:cpAlias_" / ")_cpN_$S(""=cAttr:"",1:" / "_cAttr)_"'"_..getSegLink(tDocType,i)_">",,.pStatus)  Quit:$$$ISERR(pStatus)
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
	Set tActionURL="EnsPortal.MessageContents.cls"
	Set tParentClass=$classname(pDocsRefParent), tParentId=pDocsRefParent.%Id(), tParentRef=pSegObj.GetValueAt($$$REFSEGFLDINDEX)
	Set color=$S(tNumChildren=pSegObj.GetValueAt(2):"",1:"red")

	Set tFollows = $ZCVT($$$Text("What follows is a list of links to child documents","EDIDocumentView"),"O","HTML")
	Set tIntro = $ZCVT($$$FormatText($$$Text("%1 documents","EDIDocumentView"),tTypeName),"O","HTML")
	Do pIOStream.WriteLine("<td class='EDIDocumentTableSegname' title='"_tFollows_"'>&nbsp;"_tIntro_"&nbsp;:&nbsp;</td>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Set tTitle1 = $ZCVT($$$FormatText($$$Text("X12 %1 Document","EDIDocumentView"),tTypeName),"O","HTML") // use this below

	#; pre-fetch the first 5
	Set tIdVal=tParentId_":"_tParentRef
	&sql(Declare c0 Cursor For Select ID,Name Into :tChildId,:tChildName
		 From EnsLib_EDI_X12.Document
		 Where ParentId = :tIdVal Order By ID)
	&sql(OPEN c0)
	Set pre(0)=0 For f=1:1:..#ChildLinks/2 { &sql(FETCH c0)  If SQLCODE Set f=f-1 Quit
		Set pre(f)=tChildId, pre(f,"name")=tChildName
	} &sql(CLOSE c0)
	If f=(..#ChildLinks/2) {
		#; pre-fetch the last 5
		Set tChild5Id=pre(f)
		&sql(Declare c2 Cursor For Select ID,Name Into :tChildId,:tChildName
			 From EnsLib_EDI_X12.Document
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
		Set tDocLink = "EnsPortal.MessageContents.cls?HeaderClass="_$$$URLENCODE($classname(pDocsRefParent))_"&HeaderId="_pre(i)_"&SchemaCat="_$$$URLENCODE($P(pDocsRefParent.DocType,":"))
		If $IsObject($get(%request)) Set tDocLink = ##class(%CSP.Page).Link(tDocLink)
		Set tTitle2 = $ZCVT($$$FormatText($$$Text("Id = %1","EDIDocumentView"),pre(i)),"O","HTML")
		Set tTitle3 = $ZCVT($$$FormatText($$$Text("Type Name = '%1'","EDIDocumentView"),pre(i,"name")),"O","HTML")
		Do pIOStream.WriteLine("<td><a class='portalTitleLink' title="""_tTitle1_" "_tTitle2_$C(13,10)_tTitle3_""" target=""blank"" method=get href="""_tDocLink_""">&lt;"_pre(i)_"&gt;</a>",,.tSC)  Quit:$$$ISERR(tSC)
	} Quit:$$$ISERR(tSC) tSC
	If e=..#ChildLinks {
		Set tChild5Id=pre(f), tChild6Id=pre(e)
		#; Now do up to 100 more
		&sql(Declare c1 Cursor For Select ID,Name Into :tChildId,:tChildName
			 From EnsLib_EDI_X12.Document
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
			Do pIOStream.WriteLine("<td><form name=""theForm"" method=get action="""_tActionURL_""">",, .tSC)  Quit:$$$ISERR(tSC) tSC
			Do pIOStream.WriteLine(##class(%CSP.Page).InsertHiddenFields(tActionURL),,.tSC)  Quit:$$$ISERR(tSC) tSC
			Do pIOStream.WriteLine("<input TYPE=""integer"" NAME=""HeaderId"" VALUE="""_$P(tTitle," (")_""" SIZE=""6""/>"_
				"<center><input type=""submit"" name=""ViewOther"" title="""_$ZCVT(tTitle,"O","HTML")_""" value=""Other""></center>"_
				"<input type=""hidden"" name=""HeaderClass"" value="""_tParentClass_""">"_
				"</form></td>",, .tSC)  Quit:$$$ISERR(tSC) tSC
		}
	}
	#; if total > ..#ChildLinks/2, Output the trailing direct links
	For i=e:-1:f+1 {
		Set tTitle2 = $ZCVT($$$FormatText($$$Text("Database Id = %1","EDIDocumentView"),pre(i)),"O","HTML")
		Set tTitle3 = $ZCVT($$$FormatText($$$Text("Type Name = %1","EDIDocumentView"),pre(i,"name")),"O","HTML")
		Set tDocLink = ##class(%CSP.Page).Link("EnsPortal.MessageContents.cls?HeaderClass="_$$$URLENCODE($classname(pDocsRefParent))_"&HeaderId="_pre(i)_"&SchemaCat="_$$$URLENCODE($P(pDocsRefParent.DocType,":")))
		Do pIOStream.WriteLine("<td><a class='portalTitleLink' title="""_tTitle1_" "_tTitle2_$C(13,10)_tTitle3_""" method=get target=""blank"" href="""_tDocLink_""">&lt;"_pre(i)_"&gt;</a>",,.tSC)
	}
	Quit tSC
}

ClassMethod outputHTMLStart(pIOStream As %IO.I.CharacterStream, pSegNum, pSegPath, pID, pName, pDocType, pFullLen, pMsgStructure) As %Status [ Internal ]
{
	Set tSegName=pDocType
	Set tKeyFields=$P(pSegPath,"!",2)
	Set tDesc=$S(""=pDocType:"", 1:##class(EnsLib.EDI.X12.Schema).GetDescription("SS:"_pDocType))
	Set len=$S(pFullLen<=2000:"",1:" (len="_pFullLen_")")
	Set nameClass=$S(""=tKeyFields:"EDIDocumentTableSegname",1:"EDIDocumentTableSegnum")
	Do pIOStream.WriteLine(
	"<td class='EDIDocumentTableSegnum'>"_(pSegNum)_"&nbsp;</td><td class='EDIDocumentTableSegid' SegID='"_(pID)_"'>"_($S(""=pID:"*",1:"&nbsp;"))_"</td>"_
	"<td class='"_nameClass_"'>"_
		"<a title='"_$S(pSegNum=pSegPath&&(""'=pDocType):"SS:"_pDocType, 1:$ZCVT(pSegPath_$S(""=tDesc:"", 1:" - "_tDesc)_$S(""=tKeyFields:"",1:" (!"_tKeyFields_")"),"O","HTML"))_len_"'"_..getSegLink(pDocType,,$S(pSegNum=pSegPath&&(""'=pDocType):"", 1:$ZCVT(pSegPath,"O","HTML")),$ZCVT(pMsgStructure,"O","HTML"))_">"_pName_
	"</a></td><td><table class='EDISegmentsTable'><tr>",,.tSC)
	Quit tSC
}

ClassMethod linkParents(pDocObj) As %String
{
	Set tOutStr=""
	Set tChds = $ZCVT($$$Text("child documents","EDIDocumentView"),"O","HTML")
	Set tChd = $ZCVT($$$Text("child document","EDIDocumentView"),"O","HTML")
	Set tPars = $ZCVT($$$Text("parent documents","EDIDocumentView"),"O","HTML")
	Set tPar = $ZCVT($$$Text("parent document","EDIDocumentView"),"O","HTML")
	Set tTitle1 = $ZCVT($$$Text("X12 Document","EDIDocumentView"),"O","HTML")
	Set tTitle2 = $ZCVT($$$Text("Database Id","EDIDocumentView"),"O","HTML")
	Set tTitle3= $ZCVT($$$Text("Type Name","EDIDocumentView"),"O","HTML")
	Set tChildCount=pDocObj.ChildCount
	Set:tChildCount tOutStr=tOutStr_", <b>"_tChildCount_"</b> "_$S(tChildCount>1:tChds, 1:tChd)
	Set tNumParents=$LL(pDocObj.ParentIds)
	If tNumParents {
		Set tOutStr=tOutStr_", "_$S(tNumParents>1:tPars_" ", 1:tPar_" ")
		Set tParent=pDocObj.Parent
		While $IsObject(tParent) {
			Set tDocLink = ##class(%CSP.Page).Link("EnsPortal.MessageContents.cls?HeaderClass="_$$$URLENCODE($classname(tParent))_"&HeaderId="_tParent.%Id()_"&SchemaCat="_$$$URLENCODE($P(pDocObj.DocType,":")))
			Set tOutStr=tOutStr_": <a class='portalTitleLink' title='"_tTitle1_" "_tTitle2_" = "_tParent.%Id()_"', "_tTitle3_" = '"_tParent.Name_"' method=get target=""blank"" href="""_tDocLink_""">&lt;"_tParent.%Id()_"&gt;</a>"
			Set tParent=tParent.Parent
		}
	}
	Quit tOutStr
}

ClassMethod getSegLink(pDocType, pAnchor = "", pPath = "", pDocStructure = "") As %String
{
	Set pDocType=$P(pDocType,"!")
	Quit:""=pDocType||'##class(EnsLib.EDI.X12.Schema).ElementExists("SS:"_pDocType) ""
	Quit " href='"_##class(%CSP.Page).Link("EnsPortal.EDI.X12.SchemaSegmentStructure.cls?SS=SS:"_$$$URLENCODE(pDocType)_$S(""=pPath:"",1:"&PATH="_$$$URLENCODE(pPath))_$S(""=pDocStructure:"",1:"&MS="_$$$URLENCODE(pDocStructure))_$S(""=pAnchor:"",1:"#"_pAnchor))_"' target='_blank'"
}

ClassMethod getDocLink(pDocType) As %String
{
	Set:"+"=$E(pDocType) $E(pDocType,1)=""
	Quit:""=pDocType||'##class(EnsLib.EDI.X12.Schema).ElementExists("DS:"_pDocType) ""
	Quit " href='"_##class(%CSP.Page).Link("EnsPortal.EDI.X12.SchemaDocumentStructure.zen?DS=DS:"_$$$URLENCODE(pDocType))_"' target='_blank'"
}

ClassMethod outputHTMLEnd(pIOStream As %IO.I.CharacterStream) As %Status [ Internal ]
{
	Do pIOStream.WriteLine("</tr></table></td>",,.tSC)
	Quit tSC
}

}
