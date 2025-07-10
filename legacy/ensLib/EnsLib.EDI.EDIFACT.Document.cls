/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

/// Represents an Interchange or a TransactionSet. FunctionalGroups are represented as Segments within an Interchange.
Class EnsLib.EDI.EDIFACT.Document Extends (%Persistent, EnsLib.EDI.BatchDocument, EnsLib.EDI.Segmented, EnsLib.EDI.EDIFACT.MsgBodyMethods) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter DOCCLASSNAME = "EDIFACT Document";

Parameter DOCCLASSFULLNAME = "UN EDIFACT EDI Document";

Parameter DOCSHORTNAME = "EDIFACT";

/// Name of the default SearchTable indexing class used in UI choices and MessageBank submissions 
Parameter DEFSEARCHCLASS = "EnsLib.EDI.EDIFACT.SearchTable";

/// Name of the associated schema class and after a colon the schema element code that represents a DocType
Parameter SCHEMACLASS = "EnsLib.EDI.SEF.Schema:DS:EDIFACT";

Parameter EXTENTSIZE = 2000000;

Index Extent [ Extent, Type = bitmap ];

Index ParentId On ParentId;

Index OriginalDocId On OriginalDocId;

/// All 4 Separators as a String, plus optionally SegmentTerminator: COMSEP_ELESEP_ESCSEP_REPSEP
/// Additional characters will be output as the Segment Terminator; may be up to 3 chars for output with newlines
Property Separators As %String(MAXLEN = 7, MINLEN = 4) [ Transient ];

/// Sub-element component separator character
Property ComponentSeparator As %String [ Calculated, Transient ];

/// Data-element separator character
Property ElementSeparator As %String [ Calculated, Transient ];

/// Release / Escape character
Property EscapeSeparator As %String [ Calculated, Transient ];

/// Repetition separator character
Property RepetitionSeparator As %String [ Calculated, Transient ];

/// Segment Terminator character(s)
Property SegmentTerminator As %String [ Calculated, Transient ];

/// Raw type name of document
Property Name As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Name}=##class({%%CLASSNAME}).getName({ID}) }, SqlComputed, Transient ];

/// Raw type version name of message found at MSH:12 in message content
Property TypeVersion As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {TypeVersion}=##class({%%CLASSNAME}).getTypeVersion({ID},{ParentId}) }, SqlComputed, Transient ];

/// Unique document identification string found in document content
Property Identifier As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {Identifier}=##class({%%CLASSNAME}).getIdentifier({ID}) }, SqlComputed, Transient ];

/// Count of segments composing this document
Property SegCount As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {SegCount}=$G($$$vaExtentGbl({ID},"segs"),0) }, SqlComputed, Transient ];

/// Number of Children
Property ChildCount As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ChildCount}=##class({%%CLASSNAME}).getChildCount({ID}) }, SqlComputed, Transient ];

/// A $List of the Ids of all the enclosing parent documents of this nested document, if nested,
/// in order from from immediate to outermost
/// E.g. for Id of enclosing EncounterBatch if we are an Encounter
Property ParentIds As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentIds}=##class({%%CLASSNAME}).getParentIds({ParentId},1) }, SqlComputed, Transient ];

/// The raw text content of the document. Note that this is a truncated version suitable for use in SQL results and visual inspection,
/// but not a complete or definitive representation of the document.
Property RawContent As %String(MAXLEN = 10000) [ Calculated, ReadOnly, SqlComputeCode = { Set {RawContent}=##class({%%CLASSNAME}).getSegsAsString({ID}) }, SqlComputed, Transient ];

/// the category portion of the DocType
Property DocTypeCategory As %String [ ReadOnly, Transient ];

/// Stored raw document type name ; the secondary type name portion of the DocType
Property DocTypeName As %String [ ReadOnly, Transient ];

/// Size in bytes of the message content.
/// The calculation assumes 1-byte segment terminators and includes any segments that use more than one storage node.
Property FullSize As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {FullSize}=##class({%%CLASSNAME}).GetFullSize({ID}) }, SqlComputed, Transient ];

/// A local array of orefs
/// "orefs" - a local map of integer ids to segment objects
/// And either a subscript into ^IRIS.Temp for this object's LVD maps (for notes on LVD implementation see EnsEDI.inc)
/// or local storage for these additional maps:
/// "runtimeIndex" - array for runtime index to segment; will always be defined unless mapRuntimePath is defined
/// "runtimePath" - array for runtime path to segment
/// "bidirectionalLink" - array for runtime path and index linkage
Property %maps [ MultiDimensional, Transient ];

/// Id of original object if we are a mutable clone (also used as a legal subscript that will result in $G(xxx(..%ClonedId))="" instead of a <SUBSCRIPT> error)
Property %ClonedId As %RawString [ InitialExpression = 0, Internal, ReadOnly, Transient ];

Property ParentInterchange As EnsLib.EDI.EDIFACT.Document [ Calculated, ReadOnly, Transient ];

Property ParentHeaderSeg As EnsLib.EDI.EDIFACT.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the header segment of the Interchange within which this TransactionSet arrived
Property ParentHeaderSegId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentHeaderSegId}=##class({%%CLASSNAME}).getHeaderSegId($P({ParentId},":")) }, SqlComputed, Transient ];

Property ParentTrailerSeg As EnsLib.EDI.EDIFACT.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the end segment of the Interchange within which this TransactionSet arrived
Property ParentTrailerSegId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentTrailerSegId}=##class({%%CLASSNAME}).getTrailerSegId($P({ParentId},":")) }, SqlComputed, Transient ];

Property ParentGroupSeg As EnsLib.EDI.EDIFACT.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the group start segment of the FunctionalGroup in the Interchange within which this TransactionSet arrived
Property ParentGroupSegId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentGroupSegId}=##class({%%CLASSNAME}).getGroupSegId({ParentId}) }, SqlComputed, Transient ];

Property ParentGroupEndSeg As EnsLib.EDI.EDIFACT.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the group end segment of the FunctionalGroup in the Interchange within which this TransactionSet arrived
Property ParentGroupEndSegId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentGroupEndSegId}=##class({%%CLASSNAME}).getGroupEndSegId({ParentId}) }, SqlComputed, Transient ];

/// Attachment streams associated with this document
Property Attachments As array Of Ens.StreamContainer;

/// Boolean telling whether explicit indication of repetition is used in this document
Property ExpRepeat As %Boolean [ InitialExpression = 0 ];

Method SeparatorsSet(newvalue As %String) As %Status
{
	Set tSeps = $S(""=newvalue:$$$EDIFACTDefSeparators, 1:$E(newvalue_$E($C(17,19,20),$L(newvalue),3),1,4))
	Set:" "=$$$ESCSEP(tSeps) $$$ESCSEP(tSeps)=$C(19)
	Set:" "=$$$REPSEP(tSeps) $$$REPSEP(tSeps)=$C(20)
	
	Set i%Separators=tSeps_$E(newvalue,5,*)
	Quit $$$OK
}

Method ComponentSeparatorGet() As %String [ CodeMode = expression ]
{
$$$COMSEP(..Separators)
}

Method ElementSeparatorGet() As %String [ CodeMode = expression ]
{
$$$ELESEP(..Separators)
}

Method EscapeSeparatorGet() As %String [ CodeMode = expression ]
{
$$$ESCSEP(..Separators)
}

Method RepetitionSeparatorGet() As %String [ CodeMode = expression ]
{
$$$REPSEP(..Separators)
}

Method SegmentTerminatorGet() As %String
{
	Set tSegTerminator=$$$SEGTERM(..Separators)
	If ""=tSegTerminator { Set tUNA=..getSegmentByIndex(1) Set:$IsObject(tUNA) tSegTerminator=tUNA.UNASegmentTerminator }
	Set:""=tSegTerminator tSegTerminator=$$$EDIFACTDefSegTerminator
	Quit tSegTerminator
}

Method NameGet() As %String [ CodeMode = expression ]
{
$Case(..GetValueAt("1:0"), "UNA":"Interchange", "UNB":"Interchange", "UNG":"Group", "UNO":"Object", "UIH":..GetValueAt("1:1.1"), :..GetValueAt("1:2.1"))
}

ClassMethod getName(pId As %RawString) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegment(tSegId))
	Quit $Case($$$vaDataSegName(data)
			, "UNA":"Interchange"
			, "UNB":"Interchange"
			, "UIB":"Interchange"
			, "UNG":"Group"
			, "UNO":"Object"
			, "UIH":$$$vaDataUIHTypeName(data)
			, :$$$vaDataTypeName(data))
}

Method TypeVersionGet() As %String
{
	Set tSegName=..GetValueAt("1:0")
	Quit $Case(tSegName
		, "UNA":$TR($P(..GetValueAt("2:1",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,1,2),$$$EDIFACTDefComponentSeparator)
		, "UNB":$TR($P(..GetValueAt("1:1",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,1,2),$$$EDIFACTDefComponentSeparator)
		, "UIB":$TR($P(..GetValueAt("1:1",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,1,2),$$$EDIFACTDefComponentSeparator)
		, "UNG":$TR($P(..GetValueAt("1:7",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,1,2),$$$EDIFACTDefComponentSeparator)
		, "UNO":"OBJECT"
		, "UIH":$TR($P(..GetValueAt("1:1",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,2,3),$$$EDIFACTDefComponentSeparator)
		, :$TR($P(..GetValueAt("1:2",$$$EDIFACTDefSeparators),$$$EDIFACTDefComponentSeparator,2,3),$$$EDIFACTDefComponentSeparator))
}

ClassMethod getTypeVersion(pId As %RawString, pParentId As %String) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegment(tSegId))
	Quit $Case($$$vaDataSegName(data)
			, "UNA":$$$vaDataUNBTypeVersion($G($$$vaSegment($G($$$vaExtentGbl(pId,"segs",2)))))
			, "UNB":$$$vaDataUNBTypeVersion(data)
			, "UIB":$$$vaDataUIBTypeVersion(data)
			, "UNG":$$$vaDataUNGTypeVersion(data)
			, "UNO":"OBJECT"
			, "UIH":$$$vaDataUIHTypeVersion(data)
			, :$$$vaDataTypeVersion(data))
}

Method IdentifierGet() As %String [ CodeMode = expression ]
{
$Case(..GetValueAt("1:0"), "UNA":..GetValueAt("2:5"), "UNB":..GetValueAt("1:5"), "UIB":..GetValueAt("1:3.1"), "UNG":..GetValueAt("1:5"), "UNO":..GetValueAt("1:1"), "UIH":..GetValueAt("1:3,$$$EDIFACTDefSeparators"), :..GetValueAt("1:1"))
}

ClassMethod getIdentifier(pId As %RawString) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegment(tSegId))
	Quit $Case($$$vaDataSegName(data)
			, "UNA":$$$vaDataUNBIdentifier($G($$$vaSegment($G($$$vaExtentGbl(pId,"segs",2)))))
			, "UNB":$$$vaDataUNBIdentifier(data)
			, "UIB":$$$vaDataUIBIdentifier(data)
			, "UNG":$$$vaDataUNGIdentifier(data)
			, "UNO":$$$vaDataUNOIdentifier(data)
			, :$$$vaDataIdentifier(data))
}

Method SegCountGet() As %Integer
{
	If $D($$$vaM("runtimeIndex")) Quit $$$vaM("runtimeIndex")
	Set count=0,path="" For  Set path=$O($$$vaM("runtimePath",path)) Quit:path=""  Set count=count+1
	Quit count
}

Method RawContentGet() As %String
{
	Quit ..OutputToString()
}

Method ParentInterchangeGet() As EnsLib.EDI.EDIFACT.Document [ CodeMode = expression ]
{
##class(EnsLib.EDI.EDIFACT.Document).%OpenId(..ParentInterchangeGetObjectId())
}

/// Required for AutoForm
Method ParentInterchangeGetObjectId(force As %Integer) As %String [ CodeMode = expression ]
{
$P(..TopParentId,":")
}

Method ParentHeaderSegGet() As EnsLib.EDI.EDIFACT.Segment
{
	Quit:""=$P(..ParentInterchangeGetObjectId(),":") $$$NULLOREF
	Set tInterchange=..ParentInterchange
	Set tSeg=tInterchange.GetSegmentAt(1)
	Set:"UNA"=tSeg.GetValueAt(0) tSeg=tInterchange.GetSegmentAt(2)
	Quit tSeg
}

Method ParentHeaderSegIdGet() As %String
{
	Quit:""=$P(..ParentInterchangeGetObjectId(),":") ""
	Set tInterchange=..ParentInterchange
	Set tSegId=tInterchange.GetSegmentIdAt(1)
	Set:"UNA"=tInterchange.GetValueAt("1:0") tSegId=tInterchange.GetSegmentIdAt(2)
	Quit tSegId
}

ClassMethod getHeaderSegId(pParentId As %RawString) As %String
{
	Set tParentIds=..getParentIds(pParentId,1), tNumParents=$LL(tParentIds)
	Set tInterchangeId=$P($LG(tParentIds,tNumParents),":")
	Quit $S(""=tInterchangeId:"", 1:$G($$$vaExtentGbl(tInterchangeId,"segs",1)))
}

Method ParentTrailerSegGet() As EnsLib.EDI.EDIFACT.Segment [ CodeMode = expression ]
{
$S(""=$P(..ParentInterchangeGetObjectId(),":"):$$$NULLOREF, 1:..ParentInterchange.GetSegmentAt(..ParentInterchange.SegCount))
}

Method ParentTrailerSegIdGet() As %String [ CodeMode = expression ]
{
$S(""=..ParentId:"", 1:..ParentInterchange.GetSegmentIdAt(..ParentInterchange.SegCount))
}

ClassMethod getTrailerSegId(pParentId As %RawString) As %String
{
	Set tParentIds=..getParentIds(pParentId,1), tNumParents=$LL(tParentIds)
	Set tInterchangeId=$P($LG(tParentIds,tNumParents),":")
	Quit $S(""=tInterchangeId:"", 1:$G($$$vaExtentGbl(tInterchangeId,"segs",$G($$$vaExtentGbl(tInterchangeId,"segs"),0))))
}

Method ParentGroupSegGet() As EnsLib.EDI.EDIFACT.Segment
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) $$$NULLOREF
	Quit tParent.GetSegmentAt(tIndex-1)
}

Method ParentGroupSegIdGet() As %String
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentIdAt(tIndex-1)
}

ClassMethod getGroupSegId(pId As %RawString) As %String [ CodeMode = expression ]
{
$S($Case($F(pId,":"), 0:1 ,2:1, $L(pId)+1:1, :0):"", 1:$G($$$vaExtentGbl($P(pId,":"),"segs",$P(pId,":",2)-1)))
}

Method ParentGroupEndSegGet() As EnsLib.EDI.EDIFACT.Segment
{
	Set tId=..ParentId, tId=$P(tId,":"), tIndex=$P(tId,":",2)  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentAt(tIndex+1)
}

Method ParentGroupEndSegIdGet() As %String
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentIdAt(tIndex+1)
}

ClassMethod getGroupEndSegId(pId As %RawString) As %String [ CodeMode = expression ]
{
$S($Case($F(pId,":"), 0:1, 2:1, $L(pId)+1:1, :0):"", 1:$G($$$vaExtentGbl($P(pId,":"),"segs",$P(pId,":",2)+1)))
}

Method FullSizeGet() As %Integer
{
	Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath()
	Set tLen=0 For i=1:1:$G($$$vaM("runtimeIndex")) { Set tSeg=..getSegmentByIndex(i)
		If 'tSeg.IsChildHolder(.tRef) { Set tLen=tLen+tSeg.FullSize+1 }
		Do ..commitSegmentByIndex(i)
	}
	Quit tLen
}

ClassMethod GetFullSize(pMsgId) As %Integer
{
	#dim tIsBatchParent As %Boolean = 0
	#dim tLen,segid As %Integer = 0
	#dim tVal,extra As %String
	
	#; Check to see if the document is a batch parent - in which case we will want to be sure to skip "DocsRef" segments	
	Set tIsBatchParent = $Case(..getName(pMsgId),"Interchange":1,"Group":1,:0)
	
	For i=1:1:$$$vaExtentGbl(pMsgId,"segs") {
		Set segid=$$$vaExtentGbl(pMsgId,"segs",i)
		Set tVal = $$$vaSegment(segid)
		If tIsBatchParent {
			#; Skip "DocsRef" segments because these are a convenience for us - not part of the real message
			#; Not a concern if the message is not a batch parent
			Continue:"DocsRef"=$E($$$vaDataSegName(tVal),*-$L("DocsRef")+1,*)
		}
		#; Add segment size: - 4 separators + 1 terminator
		Set tLen = tLen + $L(tVal) - 3
		#; Get extra from any segs > 32k
		For j=1:1 {
			Quit:'$D($$$vaSegmentExt(segid,j),extra)
			Set tLen = tLen + $L(extra)
		}
	}
	Quit tLen
}

/// Gets the next index in an array
Method GetNextIndex(pPath As %String, pIndex As %String, ByRef pStatus As %Status = {$$$OK}) As %String
{
	Set f=$F(pPath,"()")  If 'f Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't iterate on SegmentPath '"_pPath_"'") Quit ""
	Set tSegmentPath=$P(pPath,":",1)
	If f-1>$L(tSegmentPath) { ; '()' was found in PropertyPath not SegmentPath
		Set tPropertyPath=$P(pPath,":",2)
		Set tSegObj=..GetSegmentAt(tSegmentPath,.pStatus) Quit:$$$ISERR(pStatus) ""
		Quit tSegObj.GetNextIndex(tPropertyPath,pIndex,.pStatus)
	} Else {
		Set tHead=$E(pPath,1,f-2), tLen=$L(tHead)
		Quit:"("=tHead $S(+pIndex<..SegCount:pIndex+1,1:"") ; iterate by index if path is just "()"
		Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
		If '$D($$$vaM("loopIndex",tHead)) {
			#; Build LoopIndex node
			Set path=tHead For { Set path=$O($$$vaM("runtimePath",path))  Quit:path=""
				Quit:$E(path,1,tLen)'=tHead
				Set $$$vaM("loopIndex",tHead,$E(path,tLen+1,$F(path,")",tLen)-2))=""
			}
			If '$D($$$vaM("loopIndex",tHead)) Set $$$vaM("loopIndex",tHead)=0
		}
		Quit $O($$$vaM("loopIndex",tHead,pIndex))
	}
}

/// Gets the next path in a group
Method GetNextGroupPath(pGroup As %String, pPath As %String, ByRef pStatus As %Status = {$$$OK}) As %String
{
	Quit:$$$vaIsIndex(pGroup) ""
	If pGroup[":"||($L(pPath)<$L(pGroup)) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't iterate in Group '"_pGroup_"' on Path '"_pPath_"'") Quit ""
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set nextpath=$O($$$vaM("runtimePath",pPath))
	Quit:$E(nextpath,1,$L(pGroup))'=pGroup||$Case($E(nextpath,$L(pGroup)+1),"(":0,".":0,:1) ""
	Quit nextpath
}

Method SetValueAt(pValue As %String, pSegmentPropertyPath As %String, pAction As %String = "set", pKey As %String = "") As %Status
{
	If pSegmentPropertyPath["()" {
		Set tSC=$$$OK
		Set tFind=$F(pSegmentPropertyPath,"()")
		Set tHead=$E(pSegmentPropertyPath,1,tFind-3), tTail=$E(pSegmentPropertyPath,tFind,*)
		Set k=$P(pKey,","), pKey=$P(pKey,",",2,$L(pKey,","))
		If k { Set tSC=..SetValueAt(.pValue,tHead_"("_(k)_")"_tTail,pAction,pKey) Quit:$$$ISERR(tSC) }
		Else {
			Set i="" For { Set i=..GetNextIndex(tHead_"()",i) Quit:i=""
				Set tNewPath=tHead_"("_(i)_")"_tTail
				Set tSC=..SetValueAt(.pValue,tNewPath,pAction,pKey) Quit:$$$ISERR(tSC)
			}
		}
		Quit tSC
	}
	Set tGrpPath=$P(pSegmentPropertyPath,":"), tPropPath=$P(pSegmentPropertyPath,":",2)
	Set tSegPath=..GetNextGroupPath(tGrpPath,tGrpPath)
	If ""'=tSegPath { ; if there are group sub-elements
		For {
			Set tNewPath=tSegPath_$S(""=tPropPath:"",1:":"_tPropPath)
			Set tSC=..SetValueAt(.pValue,tNewPath,pAction,pKey) Quit:$$$ISERR(tSC)
			Set tSegPath=..GetNextGroupPath(tGrpPath,tSegPath,.tSC) Quit:$$$ISERR(tSC)
			Quit:""=tSegPath
		}
		Quit tSC
	} Else {
		Quit:(pAction="remove")&&(""=tPropPath) ..RemoveSegmentAt(tGrpPath)
		Set tSegObj=..GetMutableSegmentAt(tGrpPath,.tSC)  Quit:$$$ISERR(tSC) tSC  $$$ASSERT($IsObject(tSegObj))
		If "UNA" = tSegObj.Name {
			Set tSC = tSegObj.SetValueAt(.pValue,tPropPath,pAction,pKey)
			Set ..Separators = tSegObj.Separators_tSegObj.UNASegmentTerminator
			Quit tSC
		} Else { 
			Quit tSegObj.SetValueAt(.pValue,tPropPath,pAction,pKey)
		}
	}
}

Method GetValueAt(pSegmentPropertyPath As %String, pSeparators As %String, Output pStatus As %Status, pTreatEmptyAsNull As %Boolean = 0) As %String
{
	Set pStatus=$$$OK, tSeparators=$G(pSeparators,..Separators)
	Set tSegmentPath=$P(pSegmentPropertyPath,":"), tPropertyPath=$P(pSegmentPropertyPath,":",2)
	If ""=tPropertyPath&&(tSegmentPath["*") {
		Quit:$Case(tSegmentPath,"*":1,"(*)":1,:0) ..SegCount
		Set tLen=$L(tSegmentPath)
		If $E(tSegmentPath,tLen-2,tLen)="(*)" {
			Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
			Set count=0, (path,path0)=$E(tSegmentPath,1,tLen-2), tLen0=$L(path0), i=0
			For { Set path=$O($$$vaM("runtimePath",path))  Quit:path=""||(path0'=$E(path,1,tLen0))
				Set ti=+$E(path,tLen0+1,*)  Set:ti'=i&&ti count=count+1,i=ti
			}
			Quit count
		}
		If $E(tSegmentPath,tLen-1,tLen)=".*" {
			Set count=0,(path,path0)=$E(tSegmentPath,1,tLen-2),tLen0=$L(path0)
			Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
			For { Set path=$O($$$vaM("runtimePath",path))  Quit:path=""||(path0'=$E(path,1,tLen0))  Set count=count+1 }
			Quit count
		}
		Quit $$$ERROR($$$EnsErrGeneral,"Invalid segment count value path '"_tSegmentPath_"'")
	}
	Set tSegObj=..GetSegmentAt(tSegmentPath,.pStatus)  Quit:'$IsObject(tSegObj) ""  $$$ASSERT($$$ISOK(pStatus))
	Quit tSegObj.GetValueAt(tPropertyPath,tSeparators,.pStatus,pTreatEmptyAsNull)
}

/// Given a segment index, find the corresponding segment path
Method GetSegmentPath(pIndex As %Integer, Output pStatus As %Status) As %String
{
	If '$D($$$vaM("bidirectionalLink")) {
		If '$D($$$vaM("runtimePath")) { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Document is in index-only mode")  Quit "" }
		Else { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Document is in path-only mode")  Quit "" }
	}
	Set pStatus=$$$OK
	Set tVal=$G($$$vaM("bidirectionalLink",+pIndex))
	Set:""=tVal pStatus=$$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")
	Quit tVal
}

/// Given a segment path, find the corresponding segment index
Method GetSegmentIndex(pPath As %String, Output pStatus As %Status) As %Integer
{
	If '$D($$$vaM("bidirectionalLink")) {
		If '$D($$$vaM("runtimePath")) { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Document is in index-only mode")  Quit "" }
		Else { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Document is in path-only mode")  Quit "" }
	}
	Set pStatus=$$$OK
	Set tVal=$G($$$vaM("bidirectionalLink",pPath))
	Set:""=tVal||(tVal'=+tVal) pStatus=$$$ERROR($$$EnsErrGeneral,"Path "_pPath_" not found")
	Quit tVal
}

/// Gets the next segment after index <var>pIndex</var> with name <var>pSegName</var>.
/// Supports <var>pSegName</var> = '*' to match any segment.
Method FindSegment(pSegName As %String, ByRef pIndex As %String = "", Output pStatus As %Status) As EnsLib.EDI.EDIFACT.Segment
{
	Set pStatus=$$$OK, tId=..%Id()  Set:'tId tId=..%ClonedId
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set seg=""  For index=+pIndex+1:1:$$$vaM("runtimeIndex") { Set seg=$$$vaSegLookthru(index,tId)  Continue:""=seg
		If $$$vaIsOref(seg) {
			Set tSegObj=..%maps("orefs",index)
			If (pSegName="*")||(tSegObj.Name=pSegName) Set pIndex=index  Quit
		} Else {
			Set segid=$P(seg,"|"), data=$G($$$vaSegment(segid))
			If (pSegName="*")||(pSegName=$$$vaDataSegName(data)) {
				#; Same code as in getSegmentByIndex
				Set pIndex=index
				Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB(segid,(..IsMutable&&(tId=..%ClonedId)),$P(seg,"|",2)))
				Set ..%maps("orefs",pIndex)=tSegObj
				Set $$$vaM("runtimeIndex",pIndex)="@"
				Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
				Quit
			}
		}
	}
	If +pIndex<index Set pIndex=""  Quit $$$NULLOREF
	Quit tSegObj
}

Method getSegmentByIndex(pIndex As %Integer, Output pStatus As %Status) As EnsLib.EDI.EDIFACT.Segment [ Internal ]
{
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set pStatus=$$$OK, tId=..%Id()  Set:'tId tId=..%ClonedId
	Set seg=$$$vaSegLookthru(pIndex,tId)
	If seg="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment Index "_pIndex_" is out of bounds") Quit $$$NULLOREF
	Quit:$$$vaIsOref(seg) ..%maps("orefs",pIndex)
	Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB($P(seg,"|"),(..IsMutable&&..CacheSegsGotten&&(tId=..%ClonedId)),$P(seg,"|",2)))
	If ..CacheSegsGotten {
		Set ..%maps("orefs",pIndex)=tSegObj
		Set $$$vaM("runtimeIndex",pIndex)="@"
		Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	}
	Quit tSegObj
}

Method getSegmentByPath(pPath As %String, Output pStatus As %Status) As EnsLib.EDI.EDIFACT.Segment [ Internal ]
{
	Set pStatus=$$$OK
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set seg=$G($$$vaM("runtimePath",pPath))
	If seg="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"No segment found at path '"_pPath_"'") Quit $$$NULLOREF
	Quit:$$$vaIsOref(seg) ..%maps("orefs",$E(seg,2,*))
	Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB($P(seg,"|"),(..IsMutable&&..CacheSegsGotten&&'..%Id()&&..%ClonedId),$P(seg,"|",2)))
	If ..CacheSegsGotten {
		Set index=$G($$$vaM("bidirectionalLink",pPath))
		If index { Set seg="@"_index, $$$vaM("runtimeIndex",index)="@" }
		Else { Set index=$O(..%maps("orefs",""))-1, seg="@"_index}
		Set ..%maps("orefs",index)=tSegObj
		Set $$$vaM("runtimePath",pPath)=seg
	}
	Quit tSegObj
}

Method getSegmentIdByIndex(pIndex As %Integer, Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK, tId=..%Id()  Set:'tId tId=..%ClonedId
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set seg=$$$vaSegLookthru(pIndex,tId)
	If seg="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds") Quit ""
	Quit:'$$$vaIsOref(seg) $P(seg,"|")
	Quit ..%maps("orefs",pIndex).ID
}

Method getSegmentIdByPath(pPath As %String, Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set seg=$G($$$vaM("runtimePath",pPath))
	Quit:'$$$vaIsOref(seg) $P(seg,"|")
	Quit ..%maps("orefs",$E(seg,2,*)).ID
}

Method getMutableSegmentByIndex(pIndex As %Integer, Output pStatus As %Status) As EnsLib.EDI.EDIFACT.Segment [ Internal ]
{
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set pStatus=$$$OK, i%BuildMapStatus="", tId=..%Id()  Set:'tId tId=..%ClonedId
	Set seg=$$$vaSegLookthru(pIndex,tId)
	If seg="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")  Quit $$$NULLOREF
	If $$$vaIsOref(seg) {
		Set tSegObj=..%maps("orefs",pIndex)
		If tSegObj.IsMutable Set tSegObj.Separators=..Separators  Quit tSegObj
		Kill ..%maps("orefs",pIndex)
		Set seg=tSegObj.ID_"|"_tSegObj.DocType
	}
	;Set tSegObj=..NewSegment(pPath)
	Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB($P(seg,"|"),1,$P(seg,"|",2)))
	If '$IsObject(tSegObj)  Set pStatus=%objlasterror  Quit $$$NULLOREF
	Set tSegObj.Separators=..Separators
	Set ..%maps("orefs",pIndex)=tSegObj
	Set $$$vaM("runtimeIndex",pIndex)="@"
	Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	Quit tSegObj
}

Method getMutableSegmentByPath(pPath As %String, Output pStatus As %Status) As EnsLib.EDI.EDIFACT.Segment [ Internal ]
{
	If (..DocTypeCategory="")||(..DocTypeName="") Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")  Quit $$$NULLOREF
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set pStatus=$$$OK, i%BuildMapStatus=""
	Set seg=$G($$$vaM("runtimePath",pPath))
	If $$$vaIsOref(seg) {
		Set index=$E(seg,2,*)
		Set tSegObj=..%maps("orefs",index)
		If tSegObj.IsMutable Set tSegObj.Separators=..Separators  Quit tSegObj
		Kill ..%maps("orefs",index)
		Set seg=$S(""=tSegObj.ID:"",1:tSegObj.ID_$S(""=tSegObj.DocType:"", 1:"|"_tSegObj.DocType))
	}
	If ""=seg {
		;Set tSegObj=..NewSegment(pPath)
		Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"map",..convertRuntimePathToSchemaPath(pPath)))
		If schema="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")  Quit $$$NULLOREF
		Set tSegType=..DocTypeCategory_":"_..DocTypeName_":"_$P(schema,"|",2), tSegName=$P($P($P(tSegType,":",3),"-"),"!")
		If $ZCVT(tSegName,"U")'=tSegName Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot instantiate abstract segment type "_tSegType)  Quit $$$NULLOREF
		If ..ExpRepeat { ; set control number to match path
			Set tControlNums = ""
		 	For k=2:1:$l(pPath,"(") {
			 	Set tPathNum=$P($P(pPath,"(",k),")")
			 	Set tControlNums = tControlNums_..ComponentSeparator_tPathNum
		 	}
		}
		Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,tSegType,$E(..Separators,1,4)_tSegName_$S(..ExpRepeat:tControlNums,1:"")))
		If '$IsObject(tSegObj) Set pStatus=%objlasterror  Quit $$$NULLOREF
		Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
		Set index=$O(..%maps("orefs",""))-1, seg="@"_index
	} Else {
		Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB($P(seg,"|"),1,$P(seg,"|",2)))
		If '$IsObject(tSegObj) Set pStatus=%objlasterror  Quit $$$NULLOREF
		Set index=$G($$$vaM("bidirectionalLink",pPath))
		If index { Set seg="@"_index, $$$vaM("runtimeIndex",index)="@" }
		Else { Set index=$O(..%maps("orefs",""))-1, seg="@"_index }
	}
	Set tSegObj.Separators=..Separators
	Set ..%maps("orefs",index)=tSegObj
	Set $$$vaM("runtimePath",pPath)=seg
	If ..AutoBuildMap { Do ..BuildMap(0) }
	Else {
		Set i%BuildMapStatus=""
		#; Add relevant loopIndex node(s) if any
		Set pcs=$L(pPath,"(")-1, tHead=$P(pPath,"(",1,pcs)_"("
		For { Set tHead=$O($$$vaM("loopIndex",tHead_")"),-1), tLen=$L(tHead)  Quit:""=tHead
			If tHead=$E(pPath,1,tLen) { Set $$$vaM("loopIndex",tHead,$E(pPath,tLen+1,$F(pPath,")",tLen)-2))="", pcs=pcs-1, tHead=$P(pPath,"(",1,pcs)_"(" }
			Else {
				Set tPart="" For pcs=1:1 { Set tPrevPart=tPart, tPart=$P(pPath,"(",1,pcs)_"(", tLen=$L(tPart)
					If tPart'=$E(tHead,1,tLen) { Set tHead=tPrevPart  Quit }
				}
			}
			Quit:""=tHead||'pcs
		}
	}
	Quit tSegObj
}

Method setSegmentByIndex(pSegObj As EnsLib.EDI.EDIFACT.Segment, pIndex As %Integer, pInsert As %Boolean) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:'$$$IsdefObject(pSegObj) $$$ERROR($$$EnsErrGeneral,"Cannot set null segment object at index "_pIndex)
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Quit:(pIndex\1'=pIndex)||(pIndex<1)||(pIndex>($$$vaM("runtimeIndex")+1)) $$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")

	If pInsert {
		Set tId=..%Id()  Set:'tId tId=..%ClonedId  For i=$$$vaM("runtimeIndex"):-1:pIndex { ; slide up all segments to make room for inserted one
			Set $$$vaM("runtimeIndex",i+1)=$$$vaSegLookthru(i,tId)
			If $D(..%maps("orefs",i)) Set ..%maps("orefs",i+1)=..%maps("orefs",i)  Kill ..%maps("orefs",i)
		}
		Set path=""
	} Else {
		Set path=$G($$$vaM("bidirectionalLink",pIndex))  Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	}
	If pInsert||(pIndex=($$$vaM("runtimeIndex")+1)) Set $$$vaM("runtimeIndex")=$$$vaM("runtimeIndex")+1

	Set $$$vaM("runtimeIndex",pIndex)="@"
	Set pSegObj.DocType="" ; setting by index, the SegType might not match its new position
	Set ..%maps("orefs",pIndex)=pSegObj

	Kill:""=path $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex") ; we are operating only by IndexMap now.
	If ..AutoBuildMap { Do ..BuildMap(0) } Else { Set i%BuildMapStatus="" }
	Quit $$$OK
}

Method setSegmentByPath(pSegObj As EnsLib.EDI.EDIFACT.Segment, pPath As %String) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:(..DocTypeCategory="")||(""=..DocTypeName) $$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")
	Quit:'$$$IsdefObject(pSegObj) $$$ERROR($$$EnsErrGeneral,"Cannot set null segment object at position "_pPath)
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)

	Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"map",..convertRuntimePathToSchemaPath(pPath)))
	Quit:""=schema $$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")
	Set tSegType=..DocTypeCategory_":"_..DocTypeName_":"_$P(schema,"|",2), tSegName=$P($P($P(tSegType,":",3),"-"),"!")
	Quit:tSegName'=pSegObj.Name $$$ERROR($$$EnsErrGeneral,"Cannot set segment named '"_pSegObj.Name_"' at position "_pPath)
	Set pSegObj.DocType=tSegType ; setting by path, Set the SegType to match its new position

	If ..ExpRepeat { ; set control number to match path
		Set tSegZero = tSegName
	 	For k=2:1:$l(pPath,"(") {
		 	Set tPathNum=$P($P(pPath,"(",k),")")
		 	Set tSegZero = tSegZero_..ComponentSeparator_tPathNum
	 	}
	 	If pSegObj.Header '= tSegZero {
		 	Set pSegObj = pSegObj.%ConstructClone()
		 	Do pSegObj.SetValueAt(tSegZero,0)
	 	}
	}
	Set index=$G($$$vaM("bidirectionalLink",pPath))
	If index { Set seg="@"_index, $$$vaM("runtimeIndex",index)="@" }
	Else {
		Set seg=$G($$$vaM("runtimePath",pPath))
		If $$$vaIsOref(seg) { Set index=$E(seg,2,*) }
		Else {
			Set index=$O(..%maps("orefs",""))-1, seg="@"_index
			Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
		}
	}
	Set ..%maps("orefs",index)=pSegObj
	Set $$$vaM("runtimePath",pPath)=seg
	If ..AutoBuildMap { Do ..BuildMap(0) }
	Else {
		Set i%BuildMapStatus=""
		#; Add relevant loopIndex node(s) if any
		Set pcs=$L(pPath,"(")-1, tHead=$P(pPath,"(",1,pcs)_"("
		For { Set tHead=$O($$$vaM("loopIndex",tHead_")"),-1), tLen=$L(tHead)  Quit:""=tHead
			If tHead=$E(pPath,1,tLen) { Set $$$vaM("loopIndex",tHead,$E(pPath,tLen+1,$F(pPath,")",tLen)-2))="", pcs=pcs-1, tHead=$P(pPath,"(",1,pcs)_"(" }
			Else {
				Set tPart="" For pcs=1:1 { Set tPrevPart=tPart, tPart=$P(pPath,"(",1,pcs)_"(", tLen=$L(tPart)
					If tPart'=$E(tHead,1,tLen) { Set tHead=tPrevPart  Quit }
				}
			}
			Quit:""=tHead||'pcs
		}
	}
	Quit $$$OK
}

Method setSegmentIdByIndex(pSegId As %String, pIndex As %Integer, pInsert As %Boolean) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Quit:(pIndex\1'=pIndex)||(pIndex<1)||(pIndex>($$$vaM("runtimeIndex")+1)) $$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")

	If pInsert {
		Set tId=..%Id()  Set:'tId tId=..%ClonedId  For i=$$$vaM("runtimeIndex"):-1:pIndex { ; slide up all segments to make room for inserted one
			Set $$$vaM("runtimeIndex",i+1)=$$$vaSegLookthru(i,tId)
			If $D(..%maps("orefs",i)) Set ..%maps("orefs",i+1)=..%maps("orefs",i)  Kill ..%maps("orefs",i)
		}
		Set path=""
	} Else {
		Set path=$G($$$vaM("bidirectionalLink",pIndex))  Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	}
	If pInsert||(pIndex=($$$vaM("runtimeIndex")+1)) Set $$$vaM("runtimeIndex")=$$$vaM("runtimeIndex")+1

	Set $$$vaM("runtimeIndex",pIndex)=pSegId

	Kill:""=path $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex") ; we are operating only by IndexMap now.
	If ..AutoBuildMap { Do ..BuildMap(0) } Else { Set i%BuildMapStatus="" }
	Quit $$$OK
}

Method setSegmentIdByPath(pSegId As %String, pPath As %String) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:(..DocTypeCategory="")||(..DocTypeName="") $$$ERROR($$$EnsErrGeneral,"Cannot recognize path unless DocType is set")
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)

	Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"map",..convertRuntimePathToSchemaPath(pPath)))
	Quit:""=schema $$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")
	Set newseg=pSegId_"|"_..DocTypeCategory_":"_..DocTypeName_":"_$P(schema,"|",2)

	Set index=$G($$$vaM("bidirectionalLink",pPath))
	If index { Kill ..%maps("orefs",index)  Set $$$vaM("runtimeIndex",index)=newseg }
	Else {
		Set seg=$G($$$vaM("runtimePath",pPath))
		If $$$vaIsOref(seg) { Kill ..%maps("orefs",$E(seg,2,*)) }
		Else {
			Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
		}
	}
	Set $$$vaM("runtimePath",pPath)=newseg
	If ..AutoBuildMap { Do ..BuildMap(0) } Else { Set i%BuildMapStatus="" }
	Quit $$$OK
}

Method removeSegmentByIndex(pIndex As %Integer) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set tId=..%Id()  Set:'tId tId=..%ClonedId
	Set seg=$$$vaSegLookthru(pIndex,tId)

	Quit:""=seg $$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")
	
	#; figure out if removed segment uses control numbers for explicit repetition
	Set segTag = $P($P(..GetValueAt(pIndex),..ElementSeparator),..ComponentSeparator,2,*)
	Set segHasExpRep = (""'=segTag)
	If segHasExpRep {
		Set prevTag = $P($P(..GetValueAt(pIndex-1),..ElementSeparator),..ComponentSeparator,2,*)
		#; only need to adjust control numbers of following segments if this segment is the only one at this repetition of the loop  
		#; if either the preceding or following segment has the same tag, no adjustments need to be made
		If prevTag '= segTag {
			Set segLevel = $L(segTag,..ComponentSeparator)
			Set segControlNum = $P(segTag,..ComponentSeparator,*)
			Set tDone = 0
		} Else { ; no adjustments need to be made to the control numbers
			Set tDone = 1
		}
	}
			
	For i=pIndex:1:$$$vaM("runtimeIndex")-1 { ; slide all segments down over removed one
		Set index=$$$vaSegLookthru(i+1,tId)
		If segHasExpRep&&'tDone {
			Set tVal = ..GetValueAt(i+1)
			Set tHeader = $P(tVal,..ElementSeparator)
			#; this segment uses control numbers & is at the same level or deeper than the removed segment, but not the same repetition of the loop
			If ($L(tHeader,..ComponentSeparator)>segLevel) && ($P(tHeader,..ComponentSeparator,2,segLevel)=$P(segTag,..ComponentSeparator,1,*-1)) && ($P(tHeader,..ComponentSeparator,2,*)'=segTag){
				Set tControlNum = $P(tHeader,..ComponentSeparator,segLevel+1)
				Set $P(tHeader,..ComponentSeparator,segLevel+1) = (tControlNum-1)
				Set $P(tVal,..ElementSeparator) = tHeader
				Set tSC = ..SetValueAt(tVal,i+1)  Quit:$$$ISERR(tSC)
			} Else {
				Set tDone = 1
				Set $$$vaM("runtimeIndex",i)=index
			}
		}
		Else {
			Set $$$vaM("runtimeIndex",i)=index
		}
		If $D(..%maps("orefs",i+1)) Set ..%maps("orefs",i)=..%maps("orefs",i+1)  Kill ..%maps("orefs",i+1)
	}
	Kill $$$vaM("runtimeIndex",$$$vaM("runtimeIndex")), ..%maps("orefs",$$$vaM("runtimeIndex"))
	Set $$$vaM("runtimeIndex")=$$$vaM("runtimeIndex")-1

	Kill $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex") ; we are operating only by IndexMap now.
	If ..AutoBuildMap { Do ..BuildMap(0) } Else { Set i%BuildMapStatus="" }
	Quit $$$OK
}

Method removeSegmentByPath(pPath As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:(..DocTypeCategory="")||(..DocTypeName="") $$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)

	Set seg=$G($$$vaM("runtimePath",pPath))  If seg="" Quit $$$ERROR($$$EnsErrGeneral,"No segment found at path '"_pPath_"'")
	If $$$vaIsOref(seg) { Kill ..%maps("orefs",$E(seg,2,*)) }
	Kill $$$vaM("runtimePath",pPath)

	Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
	If ..AutoBuildMap {
		#; Fix control numbers for segments that follow if relevant
		If ..ExpRepeat&&(pPath["(") {
			Set tPathHead=$P(pPath,"(",1,*-1)
			Set index = $E(pPath,$L(tPathHead)+2,$F(pPath,")",$L(tPathHead))-2)
			Set tPathHead2 = tPathHead_"("_index_")"
			Set tNextPath = $O($$$vaM("runtimePath",pPath))
			Set tPrevPath = $O($$$vaM("runtimePath",pPath),-1)
			If ($E(tNextPath,1,$L(tPathHead))=tPathHead) && ($E(tPrevPath,1,$L(tPathHead2))'=tPathHead2) && (($E(tNextPath,1,$L(tPathHead2))'=tPathHead2)||($l(tNextPath,"(")>$l(pPath,"("))) { ; no other segments in same repetition of this loop, but there are other segments at same level
				Set level = $l(pPath,"(")
				Set tSC = ..adjustControlNumsByPath(tPathHead,index,level)
			}
		}
		Do ..BuildMap(0)
	}
	Else {
		Set i%BuildMapStatus=""
		If pPath["(" {
			#; Invalidate relevant loopIndex sub-arrays if any
			Set tPathHead=$P(pPath,"(",1,*-1)
			Set tHead=tPathHead
			For {
				Set tHead=$O($$$vaM("loopIndex",tHead))
				Quit:tPathHead_"("'=$E(tHead,1,$L(tPathHead)+1)
				Kill $$$vaM("loopIndex",tHead)
			}
			
			#; Fix control numbers for segments that follow if relevant
			If ..ExpRepeat {
				Set index = $E(pPath,$L(tPathHead)+2,$F(pPath,")",$L(tPathHead))-2)
				Set tPathHead2 = tPathHead_"("_index_")"
				Set tNextPath = $O($$$vaM("runtimePath",pPath))
				Set tPrevPath = $O($$$vaM("runtimePath",pPath),-1)
				If ($E(tNextPath,1,$L(tPathHead))=tPathHead) && ($E(tPrevPath,1,$L(tPathHead2))'=tPathHead2) && (($E(tNextPath,1,$L(tPathHead2))'=tPathHead2)||($l(tNextPath,"(")>$l(pPath,"("))) { ; no other segments in same repetition of this loop, but there are other segments at same level
					Set level = $l(pPath,"(")
					Set tSC = ..adjustControlNumsByPath(tPathHead,index,level)
				}
			}
		}
	}
	Quit tSC
}

Method adjustControlNumsByPath(pPathHead As %String, pIndex As %Integer, pLevel As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tNextPath = $O($$$vaM("runtimePath",pPathHead_"("))
	For {
		Set tPathIndex = $E(tNextPath,$L(pPathHead)+2,$F(tNextPath,")",$L(pPathHead))-2)
		If tPathIndex>=pIndex {
			Set tVal = ..GetValueAt(tNextPath)
			Set tHeader = $P(tVal,..ElementSeparator)
			Set tControlNum = $P(tHeader,..ComponentSeparator,pLevel)
			If ""=tControlNum {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"Missing control numbers for segment at path '"_tNextPath_"' with header '"_tHeader_"'.  Expected control number at level "_pLevel)
				Quit
			}
			Set $P(tHeader,..ComponentSeparator,pLevel) = (tControlNum-1)
			Set $P(tVal,..ElementSeparator) = tHeader
			Set tSC = ..SetValueAt(tVal,tNextPath)  Quit:$$$ISERR(tSC)
		}
		Set tNextPath = $O($$$vaM("runtimePath",tNextPath))
		Quit:$E(tNextPath,1,$L(pPathHead))'=pPathHead
	}
	Quit tSC
}

/// collapse segment object into just ID; Save if necessary
Method commitSegmentByIndex(pIndex As %Integer) As %Status
{
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Quit:(pIndex<1)||(pIndex>$$$vaM("runtimeIndex")) $$$ERROR($$$EnsErrGeneral,"Index "_pIndex_" is out of bounds")
	Set seg=$G($$$vaM("runtimeIndex",pIndex))
	Quit:'$$$vaIsOref(seg) $$$OK
	Set tSegObj=..%maps("orefs",pIndex)
	If tSegObj.IsMutable Set tSC=tSegObj.SaveData(..Separators) Quit:$$$ISERR(tSC) tSC
	Set newseg=tSegObj.ID_$S(""=tSegObj.DocType:"", 1:"|"_tSegObj.DocType)
	Set $$$vaM("runtimeIndex",pIndex)=newseg
	Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)=newseg
	Kill ..%maps("orefs",pIndex)
	Quit $$$OK
}

/// collapse segment object into just Id; Save if necessary
Method commitSegmentByPath(pPath As %String) As %Status
{
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set seg=$G($$$vaM("runtimePath",pPath))
	If seg="" Quit $$$ERROR($$$EnsErrGeneral,"No segment found at path '"_pPath_"'")
	If '$$$vaIsOref(seg) Quit $$$OK
	Set index=$E(seg,2,*)
	Set tSegObj=..%maps("orefs",index)
	If tSegObj.IsMutable Set tSC=tSegObj.SaveData(..Separators) Quit:$$$ISERR(tSC) tSC
	Set newseg=tSegObj.ID_$S(""=tSegObj.DocType:"", 1:"|"_tSegObj.DocType)
	Set $$$vaM("runtimePath",pPath)=newseg
	Kill ..%maps("orefs",index)
	Set index=$G($$$vaM("bidirectionalLink",pPath)) Set:""'=index $$$vaM("runtimeIndex",index)=newseg
	Quit $$$OK
}

/// collapse segment objects within the collectionPath into just Id; Save if necessary
Method commitCollectionOpenSegments(pCollectionPath As %String) As %Status
{
	If $Get(pCollectionPath)="" Return $$$OK
	#dim tCollectionPath = pCollectionPath_"."
	#dim seg
	#dim lengthCollectionPath = $Length(tCollectionPath)
	#dim tPath = $Order($$$vaM("runtimePath",tCollectionPath),1,seg)
	While ((tPath'="")&&($E(tPath,1,lengthCollectionPath)=tCollectionPath)) {
		#;Path will exist so no need to get return
		If $$$vaIsOref(seg) Do ..commitSegmentByPath(tPath)
		Set tPath = $Order($$$vaM("runtimePath",tPath),1,seg)
	}
	#; Return status so that can be called from DTL set
	Return $$$OK
}

Method convertRuntimePathToSchemaPath(pPath As %String) As %String
{
	Set tOutput=pPath
	Set f=0 For {
		Set f=$F(tOutput,"(",f) Quit:f=0
		Set g=$F(tOutput,")",f) If g=0 Set tOutput="" quit
		Set tOutput=$E(tOutput,1,f-1)_$E(tOutput,g-1,*)
		Set f=g
	}
	Quit tOutput
}

/// Given a runtime path, this method generates the key used for collation
Method getOrderKeyFromRuntimePath(pRuntimePath As %String) As %String [ Internal ]
{
	#; Parse the path to get the schema path and the subscript values
	Set tLen=$Length(pRuntimePath,"."), (tSchemaPath,tDummy)="", tRuntimeIndex=0
	For tI=1:1:tLen {
		#; Pick out each piece
		Set tPiece=$P(pRuntimePath,".",tI), tPos=1, tChar=$E(tPiece,tPos), (tID,tOrd)=""

		#; Extract the ID (including !'key field' spec if present)
		While tChar?1(1A,1N,1"!",1"=") {
			Set tID=tID_tChar, tPos=tPos+1, tChar=$E(tPiece,tPos)
		}
		#; Must have ID
		If tID="" Set tSchemaPath=""  Quit ; invalid pRuntimePath

		If tChar="-" {
			Set tID=tID_tChar, tPos=tPos+1, tChar=$E(tPiece,tPos)
			While tChar?1N {
				Set tOrd=tOrd_tChar, tPos=tPos+1, tChar=$E(tPiece,tPos)
			}
			#; Must have ordinal
			If tOrd="" Set tSchemaPath=""  Quit ; invalid pRuntimePath
			Set tID=tID_tOrd
		}
		#; If subscripted, extract the subscripts
		Set tNum="" If tChar="(" {
			Set tPos=tPos+1, tChar=$E(tPiece,tPos)
			While tChar?1N {
				Set tNum=tNum_tChar,tPos=tPos+1,tChar=$E(tPiece,tPos)
			}
			If tChar'=")" Set tSchemaPath=""  Quit ; invalid pRuntimePath
			Set tPos=tPos+1, tChar=$E(tPiece,tPos)
			
			#; Can't be any characters beyond the subscript
			If tChar'="" Set tSchemaPath=""  Quit ; invalid pRuntimePath
			
			Set tRuntimeIndex($I(tRuntimeIndex))=tNum
		}
		If tI=tLen {
			If tNum {
				Set tSchemaPath=tSchemaPath_tID_"()", tDummy=tDummy_tID_"("_tNum_")"
			} Else {
				Set tSchemaPath=tSchemaPath_tID, tDummy=tDummy_tID
			}
		} Else {
			If tNum {
				Set tSchemaPath=tSchemaPath_tID_"().", tDummy=tDummy_tID_"("_tNum_")."
			} Else {
				Set tSchemaPath=tSchemaPath_tID_".", tDummy=tDummy_tID_"."
			}
		}
	}
	#; Pick out the template if we have one
	Quit:""=tSchemaPath ""
	Set tKey=$P($G($$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tSchemaPath)),"|")  Quit:""=tKey ""

	#; substitute value for corresponding * placeholder in template
	Set tPos=1 For tI=1:1:tRuntimeIndex {
		Set tPos=$F(tKey,"*",tPos) Quit:'tPos
		Set $E(tKey,tPos-1)=$$$NUM(tRuntimeIndex(tI),8)
	}
	#; If couldn't find a replacement position then path is invalid
	If tPos=0 Quit ""

	#; If the repetition subscript is not specified for repeats then subsitute default
	If $E(tKey,*)="*" {
		Set tKey=$P(tKey,"*")_$$$NUM(1,8)
	}
	#; If there are remaining unfilled substitution parameters then key is invalid
	If tKey["*" Quit ""
	Quit tKey
}

Method buildRuntimeIndexFromPath(pClearSegTypes As %Boolean = 0) As %Status [ Internal ]
{
	$$$ASSERT('$D($$$vaM("runtimeIndex"))&&'$D($$$vaM("bidirectionalLink")))
	Set tPath="" For { Set tPath=$O($$$vaM("runtimePath",tPath))  Quit:""=tPath
		Set tOrderKey=..getOrderKeyFromRuntimePath(tPath)  Continue:""=tOrderKey
		Set $$$vaM("OrderKeyToRuntimePath",tOrderKey)=tPath
	}
	#; Re-Order mapOrefs according to new index sequence.
	Set key="",index=0 For { Set key=$O($$$vaM("OrderKeyToRuntimePath",key),1,tPath)  Quit:key=""
		Set seg=$$$vaM("runtimePath",tPath)
		Set index=index+1
		If $$$vaIsOref(seg) {
			Set oldindex=$E(seg,2,*)
			Set tSegObj=..%maps("orefs",oldindex)
			Set:pClearSegTypes tSegObj.DocType=""
			If oldindex'=index {
				Set $$$vaM("runtimePath",tPath)="@"_index  Kill ..%maps("orefs",oldindex)
				#; Migrate ..mapOrefs if needed rather than doing it in place, because re-ordering in Path mode may have occurred after runtimeIndex map was killed
				If $D(..%maps("orefs",index)) { Set tMapOrefs(index)=tSegObj } Else { Set ..%maps("orefs",index)=tSegObj }
			}
			Set $$$vaM("runtimeIndex",index)="@"
		} Else {
			Set:pClearSegTypes seg=$P(seg,"|")
			Set $$$vaM("runtimeIndex",index)=seg
		}
		Set $$$vaM("bidirectionalLink",index)=tPath, $$$vaM("bidirectionalLink",tPath)=index
	}
	Kill $$$vaM("OrderKeyToRuntimePath")
	Merge ..%maps("orefs")=tMapOrefs
	Set $$$vaM("runtimeIndex")=index, $$$vaM("runtimeIndex",0)="" ; set a marker for negative path indices
	Quit $$$OK
}

/// Clone the current document object to a new object and return the new cloned object. 
/// By default references to parent documents are not preserved and child documents are not copied. 
/// If <var>deep</var> is 1 then this does a deep copy which will also construct clones of any child documents.
Method %ConstructClone(deep As %Integer = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ ServerOnly = 0 ]
{
	Quit ##super(deep,.cloned,.location)
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	#dim tSC As %Status = $$$OK
	$$$vaMgetIndex

#ifndef LOCALMAPS
	#; copy runtime maps from old instance
	Merge $$$vaM("runtimePath")=$$$vaMobj(object,"runtimePath")
	Merge $$$vaM("bidirectionalLink")=$$$vaMobj(object,"bidirectionalLink")
	Set tId=object.%Id()  Merge:tId $$$vaM("runtimeIndex")=$$$vaExtentGbl(tId,"segs") ; no lookthru to other guy's Id
	Merge $$$vaM("runtimeIndex")=$$$vaMobj(object,"runtimeIndex")
#endif	
	#; Clone segment objects so the clone can continue to use them without changing the original's data or properties
	Set index="" For { Set index=$O(object.%maps("orefs",index),1,tSegObj)  Quit:""=index
		Set ..%maps("orefs",index)=tSegObj.%ConstructClone()
	}
	Set i%IsMutable=1, ..ParentId="" ; mark it mutable, don't keep parent relationships
	Set i%%ClonedId=object.%ClonedId  Set:'..%ClonedId i%%ClonedId=object.%Id()  Set:'..%ClonedId i%%ClonedId=0

	#; If deep cloning and the Document is a batch parent, also clone its children
	If (deep && (object.ChildCount > 0)) {
		#; Get a list of DocsRef segments
		Set idxList = ""
		For index=1:1:..SegCount {
			Set tSeg = ..GetSegmentAt(index,.tSC)	Quit:$$$ISERR(tSC)
			If tSeg.Name [ "DocsRef" {
				Set idxList = idxList_$lb(index)
			}
		}
		#; Find each child document for each DocsRef segment and add a clone of it to the new clone
		Set i = 0
		While $LISTNEXT(idxList,i,index) {
			Set tChild = $$$NULLOREF, tCount = 0
			For {
				Set tChild = object.NextChild(tChild,index)	Quit:'$IsObject(tChild)
				Set tSC = ..AddChild(index,tChild.%ConstructClone(1))	Quit:$$$ISERR(tSC)
				Do $I(tCount)
			}
			Quit:$$$ISERR(tSC)
			#; Adjust DocsRef segment child count value to be accurate
			Set tSC = ..SetValueAt(tCount,index_":"_$$$REFSEGFLDCOUNT)	Quit:$$$ISERR(tSC)
		}
		Quit:$$$ISERR(tSC) tSC
		#; Child docs are saved when they are added to the parent. Save the parent so that the whole batch can be deleted together instead of getting orphan children
		Set tSC = ..%Save()
	}

	Quit tSC
}

/// create an object based on id=initvalue but editable
Method %OnNew(initvalue As %RawString = "") As %Status [ Private ]
{
	Set tSegmentIds=$LG(initvalue,1), ..Separators=$LG(initvalue,2), i%Source=$LG(initvalue,3), i%ParentId=$LG(initvalue,4)
	Set:""=..Separators ..Separators=$$$EDIFACTDefSeparators
	$$$vaMgetIndex
	Set $$$vaM("runtimeIndex")=$LL(tSegmentIds), $$$vaM("runtimeIndex",0)="" ; set a marker for negative path indices
	For i=1:1:$$$vaM("runtimeIndex") { Set $$$vaM("runtimeIndex",i)=$LI(tSegmentIds,i) }
	Quit $$$OK
}

Method %OnOpen() As %Status [ Private ]
{
	Set tId=..%Id()
	Set:+..ParentId'=$P(..ParentId,":") ..ParentId=$LG(..ParentId) // change from 4.0 %parentIds format
	$$$vaMgetIndex
	Set cnt=$G($$$vaExtentGbl(tId,"segs")), $$$vaM("runtimeIndex")=cnt, $$$vaM("runtimeIndex",0)="" ; set a marker for negative path indices
	If 'cnt { Set ..Separators=$$$EDIFACTDefSeparators }
	Else { Set seg1id=$$$vaExtentGbl(tId,"segs",1), ..Separators=$E($$$vaSegment(seg1id),1,4)_$G($$$vaSegmentExt(seg1id,"term")) }
	Set i%DocTypeCategory=$P(..DocType,":",1)
	Set i%DocTypeName=$P(..DocType,":",2)
	#; No automatic BuildMap here - allow cheap instantiation for portal etc; do BuildMap() only when called for
	Quit $$$OK
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	Set tSC=$$$OK, tId=..%Id()
	Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath()
	Set count=+$G($$$vaM("runtimeIndex"))  For index=1:1:count { Set seg=$$$vaSegLookthru(index,..%ClonedId)
		If $$$vaIsOref(seg) {
			Set tSegObj=..%maps("orefs",index)
			#; Make certain that Segment Terminator is saved even if not included in ..Separators - this is important for unescaping
			Set tSC=tSegObj.SaveData($E(..Separators,1,4)_..SegmentTerminator)  Quit:$$$ISERR(tSC)
			Set segid=tSegObj.ID
		} Else {
			Set segid=$P(seg,"|")
		}
		If segid {
			Set $$$vaExtentGbl(tId,"segs",index)=segid
			Set $$$vaSegmentRef(segid,tId)=""
			Kill $$$vaOpenSegmentPPG(segid)
		}
	}
	For index=count+1:1:+$G($$$vaExtentGbl(tId,"segs")) { Kill $$$vaExtentGbl(tId,"segs",index) } ; Kill leftovers if we shrank
	Set $$$vaExtentGbl(tId,"segs")=count
	Set i%%ClonedId=0
	Quit tSC
}

Method PokeDocType(pDocType As %String) As %Status [ CodeMode = expression ]
{
..DocTypeSet(pDocType,0)
}

Method DocTypeSet(pDocType As %String, pBuildMap As %Boolean = 1) As %Status
{
	Quit:pDocType=..DocType&&$D($$$vaM("runtimePath")) $$$OK ; nothing is changed

	#; convert runtimePath to runtimeIndex and then Kill runtimePath
	Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath(1) ; 1 = clear types
	Kill $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex")
	Set i%DocType=pDocType
	Set i%DocTypeCategory=$P(pDocType,":",1)
	Set i%DocTypeName=$P(pDocType,":",2)
	Do:pBuildMap ..BuildMap()
	Quit $$$OK
}

/// pKeepParsingAfterError means keep trying to parse after errors are encountered; returned Status will contain all errors encountered
Method BuildMap(pKeepParsingAfterError As %Boolean = 1, pCreateExplicitRep As %Boolean = 0) As %Status
{
	If ((""=..DocTypeCategory)||(""=..DocTypeName)) {
		Set i%BuildMapStatus=$S(""=..DocType:"", 1:$$$ERROR($$$EnsEDIErrMapDocType,"EDIFACT",..DocType))
	} Else {
		Quit:$D($$$vaM("runtimePath"))&&(""'=..BuildMapStatus)&&'pCreateExplicitRep ..BuildMapStatus ; already done
		Set i%BuildMapStatus=""
	}
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath(1) ; 1 = clear types
	Kill $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex")

	Quit:""=..DocType $$$OK
	Quit:""'=..BuildMapStatus&&($$$ISERR(..BuildMapStatus)||'pCreateExplicitRep) ..BuildMapStatus

	Set tSchema=$G($$$vaSchemaGbl(..DocTypeCategory,..DocTypeName))
	If tSchema="" {
		Set i%BuildMapStatus=$$$ERROR($$$EnsEDIErrMapDocType,"EDIFACT",..DocType)
		Quit ..BuildMapStatus
	}
	Set tId=..%Id()  Set:'tId tId=..%ClonedId
	Set tCurrSeg=1, %seglastmatch=0, %pathlastmatch=""
	Set tSC=..buildRuntimePathFromIndex(tId,"",$Name($$$vaSchemaGbl)_"("""_..DocTypeCategory_""","""_..DocTypeName_""",""array"")","top",.tCurrSeg,0,"|",$$$OK,pKeepParsingAfterError,0,pCreateExplicitRep)
	$$$ASSERT(%seglastmatch=(tCurrSeg-1))
	#; Map leftover segments
	Set tSegments=$$$vaM("runtimeIndex")
	If tCurrSeg<=tSegments {
		For i=tCurrSeg:1:tSegments {
			Set seg=$$$vaSegLookthru(i,tId)
			If $$$vaIsOref(seg) {
				Set $$$vaM("runtimePath","leftoversegs("_(i+1-tCurrSeg)_")")="@"_i
			} Else {
				Set segid=$P(seg,"|")
				Set $$$vaM("runtimePath","leftoversegs("_(i+1-tCurrSeg)_")")=segid
			}	
		}
		If pKeepParsingAfterError||$$$ISOK(tSC) {
			#; Find current Segment's Type Name
			Set seg=$$$vaSegLookthru(tCurrSeg,tId)
			If $$$vaIsOref(seg) {
				Set tSegObj=..%maps("orefs",tCurrSeg)
				Set currsegname=tSegObj.Name
			} Else {
				Set data=$G($$$vaSegment($P(seg,"|")))
				Set currsegname=$$$vaDataSegName(data)
				Set currseghead=$$$vaDataSegHeader(data)
			}
			If tCurrSeg=1 { Set lastname="" }
			Else {
				#; Find previous Segment's Type Name
				Set seg=$$$vaSegLookthru(tCurrSeg-1,tId)
				If $$$vaIsOref(seg) {
					Set tSegObj=..%maps("orefs",tCurrSeg-1)
					Set lastname=tSegObj.Name
				} Else {
					Set data=$G($$$vaSegment($P(seg,"|")))
					Set lastname=$$$vaDataSegName(data)
				}
			}
			Set lastmatch=$S(""'=lastname&&%seglastmatch:%seglastmatch_" ("_%pathlastmatch_")", 1:"0")
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsEDIErrMapSegUnrecog,$Case($G(currseghead),"":currsegname,:currseghead),lastmatch))
		}
	}
	Kill %seglastmatch, %pathlastmatch
	Set i%BuildMapStatus=tSC
	Quit tSC
}

/// Build a segment map for the current segment index array based on the document schema<br>
/// If <var>pKeepParsingAfterError</var> is false then stop parsing when first error is encountered<br>
Method buildRuntimePathFromIndex(pId As %String, pPath As %String, pContentArray As %String, pType As %String, ByRef pCurrSeg As %Integer, pParentGrpOpt As %Boolean, pLoopNames As %String, pSC As %Status, pKeepParsingAfterError As %Boolean, pFirstRep As %Boolean = 0, pCreateExplicitRep As %Boolean = 0) As %Status
{
	Set tSegments=$$$vaM("runtimeIndex"), currsegname=""
	Set type=$P(pType,"(",1,$L(pType,"(")), len=$L(type), tIsUnion="union"=$E(type,len+1-$L("union"),len)
	Set tGrpOpt=(pParentGrpOpt||$G(@pContentArray@("opt"),0)), tFirstReq="", tGrpSeg=pCurrSeg
	For i=1:1:$G(@pContentArray) { ; loop over sub-elements of the root element at this level
		Set pIContents=$Name(@pContentArray@(i))
		Set opt=$G(@pIContents@("opt"),0), tFirstReq=$S(""=tFirstReq&&'opt:1, ""=tFirstReq:"", 1:0)
		Set type=@pIContents@("type")
		Set segtype=$P(type,":",4)
		Set isrep=$P(segtype,"(",2), tMaxReps=$Case(isrep, ")":0, "":1, :+isrep), isrep=(""'=isrep), tRequiredReps='opt
		Set segtype=$P($P(segtype,"("),"-") ; strip off ordinal and parens
		Set keyfields=$P(segtype,"!",2), segtype=$P(segtype,"!") ; split off key fields indicator
		Set segname=$P(@pIContents@("name"),"(")
		Set subs=$G(@pIContents,0)
		Set tISeg=pCurrSeg
		For rep=1:1 { Quit:rep>tMaxReps&&tMaxReps ; loop for repetitions of the current sub-element
			Set tBaseSeg=pCurrSeg
			Set tIPath=$S(""=pPath:"",1:pPath_".")_segname_$S(isrep:"("_rep_")",1:"")
			#;If isrep&&(rep=1)&&(i=1)&&opt Set pSC=$$$ADDSC(pSC,$$$ERROR($$$EnsEDIErrMapGeneral,"Schema error at "_tIPath_" - the first element in a repeating group must not be optional"))  Quit

			If subs {
				Set pSC=..buildRuntimePathFromIndex(pId,tIPath,pIContents,type,.pCurrSeg,tGrpOpt||(rep>tRequiredReps),pLoopNames,pSC,pKeepParsingAfterError,pFirstRep,pCreateExplicitRep)
				Set (currsegname,currseghead)="" ; avoid reporting error with wrong currsegname 
			} Else {
				#; Find current Segment's Type Name
				If pCurrSeg>tSegments {
					Set (currsegname,currseghead) = ""
				} Else {
					Set seg=$$$vaSegLookthru(pCurrSeg,pId)
					If $$$vaIsOref(seg) {
						Set tSegObj=..%maps("orefs",pCurrSeg)
						Set data=$E(tSegObj.Separators,1,4)_tSegObj.GetValueAt()
					} Else {
						Set data=$G($$$vaSegment($P(seg,"|")))
					}
					Set currsegname=$$$vaDataSegName(data)
					Set currseghead=$$$vaDataSegHeader(data)
					Set currreplev=$P(currseghead,$$$COMSEP(data),2,*) ; repetition info
					#; Check for explicit expression of level of repetition
					If ""'=currreplev {
						If pFirstRep&&'..ExpRepeat {
							Set pSC = $$$ERROR($$$EnsErrGeneral,"Detected use of both implicit and explicit level of repetition.  Unable to parse the remainder of the document.")
							Quit
						}
						Set:'pFirstRep (..ExpRepeat,pFirstRep) = 1
					}
					Set pLoopNames=$Case(currsegname,
						"LS":pLoopNames_$$$SEGELEM(data,1)_"|", ; add the Loop name
						"LE":$P(pLoopNames,"|",1,$L(pLoopNames,"|")-2)_"|", ; subtract the Loop name ; // check if valid
						 :pLoopNames)
				}
				#; Check for segment type match
				If segtype=currsegname &&(""=keyfields || $$keyfieldsMatch(keyfields,data))&&(('..ExpRepeat)||(""=currreplev&&((tIPath'["(")||pCreateExplicitRep)) || ($$repsMatch(currreplev,$$$COMSEP(data),tIPath))) {
					#; Set seg address/schema at path into runtimePath
					Set schema=$P($P(type,":",2,4),"(")
					Set seg=$$$vaSegLookthru(pCurrSeg,pId)
					
					Set tHead = ""
					If pCreateExplicitRep&&(tIPath["(")&&(""=currreplev) {
						Set:'..ExpRepeat ..ExpRepeat=1
					 	For k=2:1:$l(tIPath,"(") {
						 	Set tPathNum=$P($P(tIPath,"(",k),")")
						 	Set tHead = tHead_$$$COMSEP(data)_tPathNum
					 	}
						If '$$$vaIsOref(seg) {
							Set tSegObj = ##class(EnsLib.EDI.EDIFACT.Segment).%New($LB($P(seg,"|"),..IsMutable,$P(seg,"|",2)))
							Set $$$vaM("runtimeIndex",pCurrSeg) = "@"
						}
						Set tSegData = currsegname_tHead_$$$ELESEP(data)_$P(data,$$$ELESEP(data),3,*)
						Set tSegCopy = tSegObj.%ConstructClone()
						Set tSC = tSegCopy.SetValueAt(tSegData)
						Set tSC = tSegCopy.SaveData()
						Set ..%maps("orefs",pCurrSeg) = tSegCopy
						Set $$$vaM("runtimePath",tIPath)="@"_pCurrSeg
						Set ..%maps("orefs",pCurrSeg).DocType=schema
					}
					ElseIf $$$vaIsOref(seg) {
						Set $$$vaM("runtimePath",tIPath)="@"_pCurrSeg
						Set ..%maps("orefs",pCurrSeg).DocType=schema
					} Else {
						Set seg=$P(seg,"|")_"|"_schema
						Set $$$vaM("runtimeIndex",pCurrSeg)=seg
						Set $$$vaM("runtimePath",tIPath)=seg
					}
					Set $$$vaM("bidirectionalLink",pCurrSeg)=tIPath, $$$vaM("bidirectionalLink",tIPath)=pCurrSeg

					Set %seglastmatch=pCurrSeg, %pathlastmatch=tIPath
					Set:pCurrSeg<=tSegments pCurrSeg=pCurrSeg+1, currsegname=""
					Set:(""'=pPath)||isrep pFirstRep=1
				}
			}
			If tBaseSeg=pCurrSeg { ; found no match in repeat loop
				Set:rep<tRequiredReps&&'tIsUnion&&'tGrpOpt pSC=$$$ADDSC(pSC,$$$ERROR($$$EnsEDIErrMapSegCount,tRequiredReps,tIPath,pCurrSeg_$S(""=$G(currseghead):"",1:" ("_currseghead_")")))
				Quit
			} Else {
				Set tGrpOpt=0
				Quit:pCurrSeg>tSegments
			}
		}
		Quit:$$$ISERR(pSC)&&'pKeepParsingAfterError
		If tISeg=pCurrSeg { ; found no match at element i
			If 'opt&&'tIsUnion {
				Quit:i=1
				Set:'tGrpOpt pSC=$$$ADDSC(pSC,$$$ERROR($$$EnsEDIErrMapRequired,tIPath,pCurrSeg_$S(""=$G(currseghead):"",1:" ("_currseghead_")")))
				Quit:tFirstReq||'pKeepParsingAfterError
			}
		} Else {
			Set tGrpOpt=0
			Quit:tIsUnion
		}
	}
	If tIsUnion {
		If tGrpSeg=pCurrSeg { ; found no match in any union element
			Set:'tGrpOpt pSC=$$$ADDSC(pSC,$$$ERROR($$$EnsEDIErrMapRequiredUnion,pPath,pCurrSeg_$S(""=$G(currseghead):"",1:" ("_currseghead_")")))
		}
	}
	Quit pSC
keyfieldsMatch(pKeyFields,pData) ; local routine that returns true if all keyfields match the data
	Set tMatch=1, nFlds=$L(pKeyFields,"&") For iFld=1:1:nFlds { Set tKey=$P(pKeyFields,"&",iFld)  Continue:""=tKey
		Set tFld=$P(tKey,"="), tVal=$P(tKey,"=",2)
		If ""=tVal||'tFld||(tVal'=$$$SEGELEM(pData,tFld)) Set tMatch=0  Quit
	}
	Quit tMatch
repsMatch(pCurrRep,pComSep,pWholePath) ; local routine that returns true if the explicit repetition info matches the path
	Set tMatch = 1
	Set:$l(pCurrRep,pComSep)'=$l(pWholePath,"(")-1 tMatch=0
 	If tMatch {
	 	For k=2:1:$l(pWholePath,"(") {
		 	Set tRepNum = $p(pCurrRep,pComSep,k-1) ;number in explicit representation
		 	Set tPathNum=$P($P(pWholePath,"(",k),")") ;number in path
		 	If tPathNum'=tRepNum Set tMatch=0 Quit
	 	}
 	}
 	Quit tMatch
}

Method DumpMaps() As %Status
{
	Set DocType=..DocType w ! zw DocType
	w !,"DocTypeCategory,DocTypeName="_..DocTypeCategory_","_..DocTypeName
	Set BuildMapStatus=..BuildMapStatus w ! zw BuildMapStatus
	If ""'=..DocTypeCategory&&(""'=..DocTypeName) {
		Merge mapSchemaPath=$$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"map") w ! zw mapSchemaPath
		Merge mapContentArray=$$$vaSchemaGbl(..DocTypeCategory,..DocTypeName,"array") w ! zw mapContentArray
	}
	Merge mapRuntimeIndex=$$$vaM("runtimeIndex") w ! zw mapRuntimeIndex
	Merge mapRuntimePath=$$$vaM("runtimePath") w ! zw mapRuntimePath
	Merge mapBidirectionalLink=$$$vaM("bidirectionalLink") w ! zw mapBidirectionalLink
	Merge mapLoopIndex=$$$vaM("loopIndex") w ! zw mapLoopIndex
 	Merge mapOrefs=..%maps("orefs") w ! zw mapOrefs
	Quit $$$OK
}

ClassMethod GetContentArray(Output pContents, pMode As %String, pDocType As %String, pLevel As %Integer, pIncludeBase As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.SEF.Schema).GetContentArray(.pContents,.pMode,.pDocType,.pLevel,.pIncludeBase)
}

/// Returns a list of available DocTypes for this document class. <br/>
/// The DocType is returned as the first column in the result set. <br/>
/// The <var>Category</var> parameter can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only DocTypes in standard categories <br/>
///  + - return only DocTypes in user-defined categories <br/>
///  empty - return DocTypes from all categories <br/>
///  a category name - return only DocTypes in the named category <br/>
///  a partial name suffixed with '%' - return only DocTypes in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only DocTypes defined in the current schema category itself <br/>
///  1 - return all DocTypes in the current schema category's base category in addition to those defined in the current category itself <br/>
Query EnumerateDocTypes(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Type:%String")
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Category As %String, IncludeBase As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.SEF.Schema).DocStructuresExecute(.qHandle,.Category,.IncludeBase,"EDIFACT")
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	Set tSC=##class(EnsLib.EDI.SEF.Schema).DocStructuresFetch(.qHandle,.Row,.AtEnd)
	Set:""'=$G(Row) Row=$LB($LG(Row))
	Quit tSC
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocTypesExecute ]
{
##class(EnsLib.EDI.SEF.Schema).DocStructuresClose(.qHandle)
}

/// Returns a list of document type schema categories for the document class.<br>
/// The Standard parameter can be used to restrict the list.<br>
/// If Standard is:
///  0 - return only standard categories
///  + - return only user-defined categories
///  empty - return all categories
///  a partial category name - return only categories starting with the given category name part<br/>
///  other - return nothing
Query EnumerateTypeCategories(Standard As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String")
{
}

ClassMethod EnumerateTypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "") As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.SEF.Schema).TypeCategoriesExecute(.qHandle, Standard, "EDIFACT")
}

ClassMethod EnumerateTypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateTypeCategoriesExecute ]
{
	Set tSC=##class(EnsLib.EDI.SEF.Schema).TypeCategoriesFetch(.qHandle,.Row,.AtEnd)
	Quit tSC
}

ClassMethod EnumerateTypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateTypeCategoriesExecute ]
{
##class(EnsLib.EDI.SEF.Schema).TypeCategoriesClose(.qHandle)
}

/// Returns a list of schema categories and segment types and segment fields for this document class. <br/>
/// The <var>Category</var> and <var>Level</var> parameters can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only standard categories <br/>
///  + - return only user-defined categories <br/>
///  empty - return all categories <br/>
///  a category name - return only SegTypes in the named category <br/>
///  a category name:segment type name - return only information about the named SegType <br/>
///  a partial name suffixed with '%' - return only SegTypes in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>Level</var> is: <br/>
///  0 - return all segment names <br/>
///  n - return the given number of levels of nested field names within each segment <br/>
///  empty - return all levels of nested field names within each segment <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only segment names defined in the current schema category itself <br/>
///  1 - return all segment names in the current schema category's base category in addition to those defined in the current category itself <br/>
Query EnumerateSegTypes(Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "SegType:%String,Field:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod EnumerateSegTypesExecute(ByRef qHandle As %Binary, Category As %String = "", Level As %String, IncludeBase As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.SEF.Schema).SegTypesExecute(.qHandle,.Category,.Level,.IncludeBase,"EDIFACT")
}

ClassMethod EnumerateSegTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateSegTypesExecute ]
{
	Set tSC=##class(EnsLib.EDI.SEF.Schema).SegTypesFetch(.qHandle,.Row,.AtEnd)
	Quit tSC
}

ClassMethod EnumerateSegTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateSegTypesExecute ]
{
##class(EnsLib.EDI.SEF.Schema).SegTypesClose(.qHandle)
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pContentArrayName As %String, pArrayPos As %String) As %String [ CodeMode = expression ]
{
##class(EnsLib.EDI.SEF.Schema).GetAlias(pContentArrayName,pArrayPos)
}

ClassMethod checkDocType(ByRef pDocType As %String) As %Status
{
	Set tSC=$$$OK
	Set category=$P(pDocType,":",1)
	Set secondary=$P(pDocType,":",2)
	If (""=category)||(""=secondary)||(""=$G($$$vaSchemaGbl(category,secondary))) {
		Set tSC=$$$ERROR($$$EnsEDIErrMapDocType,"EDIFACT",pDocType)
	}
	Quit tSC
}

/// This method is for use from the RawContent property's SQL Compute invocation
ClassMethod getSegsAsString(pId As %String, pMaxLen As %Integer = 10000, pStartOffset As %Integer = 1) As %String
{
	#; Use delimiters from first segment, translate all subsequent delims to those
	Set str=""  For index=1:1:+$G($$$vaExtentGbl(pId,"segs")) { Set data=$$$vaSegment($$$vaExtentGbl(pId,"segs",index))
		If index=1 {
			Set tSeparators=$E(data,1,4)
			Set tSegTerminator=$G($$$vaSegmentExt($$$vaExtentGbl(pId,"segs",index),"term"),$$$EDIFACTDefSegTerminator)
		}
		Set:tSeparators'=$E(data,1,4) data=##class(EnsLib.EDI.EDIFACT.Segment).replaceSeparators(data, tSeparators)
		If pStartOffset>1 {
			If pStartOffset>($L(data)-4+$L(tSegTerminator)) { Set pStartOffset=pStartOffset-($L(data)-4+$L(tSegTerminator))  Continue }
			Else { Set pStartOffset=1, data=$E(data,pStartOffset,*) }
		}
		If pMaxLen-$L(str)>=($L(data)-4+$L(tSegTerminator)) { Set str=str_$E(data,4,*)_tSegTerminator }
		Else { Set str=str_$E(data_tSegTerminator,5,4+pMaxLen-$L(str)) }
		Quit:$L(str)>=pMaxLen
	}
	Quit str
}

Method OutputToFile(pFilename As %String, pOverwrite As %Boolean, pSeparators As %String, pIOFormatClassname As %String) As %Status
{
	Set tIOStream=##Class(%IO.FileStream).%New()
	Do tIOStream.Open(pFilename,$S($G(pOverwrite):"NEW",1:"AEW"),5,,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..OutputToIOStream(tIOStream, .pSeparators, , .pIOFormatClassname)
}

Method OutputToDevice(pSeparators As %String, pIOFormatClassname As %String) As %Status
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..OutputToIOStream(tDeviceStream, .pSeparators, , .pIOFormatClassname)
}

Method OutputToLibraryStream(pLibStream As %Stream.Object, pSeparators As %String, pIOFormatClassname As %String) As %Status
{
	Set tIOStream=$S(pLibStream.%Extends("%IO.I.CharacterStream"):pLibStream, 1:##Class(%IO.MetaCharacterStream).%New(pLibStream))
	Quit ..OutputToIOStream(tIOStream, .pSeparators, , .pIOFormatClassname)
}

Method OutputToString(pSeparators As %String, Output pStatus As %Status, pIOFormatClassname As %String) As %String
{
	Set tIOStream=##Class(%IO.StringStream).%New()
	Set pStatus = ..OutputToIOStream(tIOStream, .pSeparators, , .pIOFormatClassname)
	Do tIOStream.Rewind()
	Quit tIOStream.Read()
}

Method OutputToIOStream(pIOStream As %IO.I.CharacterStream, pSeparators As %String, pFlush As %Boolean = 1, pIOFormatClassname As %String = "") As %Status
{
	Set tSC=$$$OK
	Set tSeparators=$S(""=$G(pSeparators):..Separators, 1:pSeparators)  Set:""=tSeparators tSeparators=$$$EDIFACTDefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator
	If ""=pIOFormatClassname || '$classmethod(pIOFormatClassname,"OutputDocument",$this,.tSC,pIOStream,tSeparators) {
		Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath()
		For i=1:1:$G($$$vaM("runtimeIndex")) { Set tSeg=..getSegmentByIndex(i)
			If 'tSeg.IsChildHolder(.tRef) { Set tSC=tSeg.OutputToIOStream(pIOStream, tSeparators, i, $G($$$vaM("bidirectionalLink",i),i), $this, pIOFormatClassname) }
			Else {
				Set tChild=$$$NULLOREF For { Set tChild=..NextChild(tChild,tRef)  Quit:tChild=$$$NULLOREF
					Set tSC=tChild.OutputToIOStream(pIOStream, tSeparators, 0)  Quit:$$$ISERR(tSC)
				}
			}
			Do ..commitSegmentByIndex(i)
		}
		Do:""'=pIOFormatClassname $classmethod(pIOFormatClassname,"OutputDocumentEnd",$this,.tSC,pIOStream,tSeparators)
	}
	If pFlush Do pIOStream.Flush(.tSC1)  Set:$$$ISOK(tSC) tSC=tSC1
	Quit tSC
}

/// Display Segments as HTML, using DocType info if available
Method OutputHTML() As %Status
{
	Set tSC=$$$OK
	Set tSeparators=..Separators  Set:""=tSeparators tSeparators=$$$EDIFACTDefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator  Set $$$SEGTERM(tSeparators)=$ZStrip($$$SEGTERM(tSeparators),"*CW")
	Quit ..OutputToDevice(tSeparators,"EnsLib.EDI.EDIFACT.Util.FormatHTML")
}

/// Display Segments as HTML, using DocType info if available
Method OutputHTMLZen() As %Status
{
	Set tSC=$$$OK
	Set tSeparators=..Separators  Set:""=tSeparators tSeparators=$$$EDIFACTDefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator  Set $$$SEGTERM(tSeparators)=$ZStrip($$$SEGTERM(tSeparators),"*CW")
	Quit ..OutputToDevice(tSeparators,"EnsLib.EDI.EDIFACT.Util.FormatHTMLZen")
}

ClassMethod ImportFromFile(pFilename As %String, pDocNum As %Integer = 1, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String) As EnsLib.EDI.EDIFACT.Document
{
	Set tIOStream=##Class(%IO.FileStream).%New()
	Do tIOStream.Open(pFilename,,5,,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	$$$sysTRACE("Opened file '"_pFilename_"'")
	Set tDoc=$$$NULLOREF  For i=1:1:pDocNum {
		If tIOStream.AtEnd Set pStatus=$$$ERROR($$$EnsErrGeneral,"Fewer than "_pDocNum_" documents in file "_pFilename)  Quit
		Set tDoc=..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname)  Quit:$$$ISERR(pStatus)
	}
	Quit:$$$ISERR(pStatus) $$$NULLOREF
	Quit tDoc
}

ClassMethod ImportFromDevice(Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String) As EnsLib.EDI.EDIFACT.Document
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..ImportFromIOStream(tDeviceStream,.pStatus,.pConfigItem,.pIOFormatClassname)
}

ClassMethod ImportFromLibraryStream(pLibStream As %Stream.Object, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String) As EnsLib.EDI.EDIFACT.Document
{
	Set tIOStream=$S(pLibStream.%Extends("%IO.I.CharacterStream"):pLibStream,1:##Class(%IO.MetaCharacterStream).%New(pLibStream))
	Quit ..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname)
}

ClassMethod ImportFromString(pString As %String, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String) As EnsLib.EDI.EDIFACT.Document
{
	Set tIOStream=##Class(%IO.StringStream).%New(pString)
	Quit ..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname)
}

ClassMethod ImportFromIOStream(pIOStream As %IO.I.CharacterStream, Output pStatus As %Status = {$$$OK}, ByRef pConfigItem As %String = "", pIOFormatClassname As %String = "") As EnsLib.EDI.EDIFACT.Document
{
	Quit:""'=pIOFormatClassname&&$classmethod(pIOFormatClassname,"ImportDocument",.tDoc,.pStatus,pIOStream,pConfigItem) tDoc

	If ""'=pConfigItem {
		If $IsObject(pConfigItem) {
			Set tInst=pConfigItem
		} Else {
			Set tInst=##class(Ens.Host).GetShadowInstance(pConfigItem,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
		}
		If 'tInst.%Extends("EnsLib.EDI.EDIFACT.Service.Standard") Set pStatus=$$$ERROR($$$EnsErrGeneral,"Config Item class "_$classname(tInst)_" found For "_pConfigItem_" is not not an EDI document Service")  Quit $$$NULLOREF
	} Else {
		Set tInst=##class(Ens.Host).GetShadowInstance("class ||EnsLib.EDI.EDIFACT.Service.FileService",.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	}
	#; Get a new parser based on a Service; OnInit not called for shadow service instances
	Set tInst.%ForwardBatchWhole=2 ; don't let Service process the document; don't save&purge intermediate TransactionSet objects, leave them all in memory in the Document
	If '$IsObject(tInst.%Parser) Set tInst.%Parser=##class(EnsLib.EDI.EDIFACT.Parser).%New(tInst)  $$$ASSERT($IsObject(tInst.%Parser))
	//Set tInst.%Parser.DefCharEncoding=tInst.DefCharEncoding
	Set:tInst.TolerateNewlines tInst.%Parser.Whitespace=$C(13,10)
	Set:""=tInst.ReplyMode tInst.ReplyMode="Never"

	If tInst'=pConfigItem { ; override some default properties if we created the shadow instance
		Set tInst.SearchTableClass=""
	}
	#; call the parser
	Set pStatus=tInst.%Parser.ParseIOStream(pIOStream,.tDoc)
	Set pConfigItem=tInst ; allow repeated calls on the same parser
	Quit tDoc
}

Method ConstructExplicitClone(ByRef pStatus As %Status) As EnsLib.EDI.EDIFACT.Document
{
	Set pStatus = $$$OK
	Set clone = ##class(EnsLib.EDI.EDIFACT.Document).%New($LB("",..Separators))
	Set pStatus = clone.PokeDocType(..DocType)
	Set clone.ExpRepeat=1
	For i=1:1:..SegCount {
		Set tSeg = ..getSegmentByIndex(i,.pStatus)
		Quit:$$$ISERR(pStatus)
		Set newSeg = tSeg.%ConstructClone()
		Set pStatus = clone.SetSegmentAt(newSeg,i)
	}
	Quit:$$$ISERR(pStatus) $$$NULLOREF
	Set pStatus = clone.BuildMap(1,1)
	Quit clone
}

Method ConstructImplicitClone(ByRef pStatus As %Status) As EnsLib.EDI.EDIFACT.Document
{
	Set pStatus = $$$OK
	Set clone = ##class(EnsLib.EDI.EDIFACT.Document).%New($LB("",..Separators))
	Set pStatus = clone.PokeDocType(..DocType)
	For i=1:1:..SegCount {
		Set tSeg = ..getSegmentByIndex(i,.pStatus)
		Quit:$$$ISERR(pStatus)
		Set newSeg = tSeg.%ConstructClone()
		Set pStatus = newSeg.SetValueAt(newSeg.Name,0)
		Set pStatus = clone.SetSegmentAt(newSeg,i)
	}
	Quit $S($$$ISERR(pStatus):$$$NULLOREF, 1:clone)
}

Method CopyValues(pSource As EnsLib.EDI.EDIFACT.Document, pSourcePath As %String, pTargetPath As %String, pAction As %String, pKey As %String, pEmptyFieldAsNull As %Boolean = 0, pIgnoreMissingSource As %Boolean = 0, pGenerateEmptySegments As %Boolean = 0) As %Status
{
	Set tSC=$$$OK
	Set tSourceWild=$F(pSourcePath,"()"), tTargetWild=$F(pTargetPath,"()")
	If tSourceWild||tTargetWild {
		Set tSourceHead=$E(pSourcePath,1,tSourceWild-3), tSourceTail=$E(pSourcePath,tSourceWild,*)
		Set tTargetHead=$E(pTargetPath,1,tTargetWild-3), tTargetTail=$E(pTargetPath,tTargetWild,*)
		If tSourceWild {
			If pEmptyFieldAsNull {
				If (tTargetWild)&&(tSourceHead [ ":")&&(tTargetHead [ ":") {
					Quit:(pSource.GetValueAt(tSourceHead)="") $$$OK
				}
			}
			Set i="" For { Set i=pSource.GetNextIndex(tSourceHead_"()",i,.tSC) Quit:i=""
				Set tSourceNewPath=tSourceHead_"("_(i)_")"_tSourceTail
				Set tTargetNewPath=$S(tTargetWild:tTargetHead_"("_(i)_")"_tTargetTail,1:pTargetPath)
				Set tSC2=..CopyValues(pSource,tSourceNewPath,tTargetNewPath,pAction,pKey,pEmptyFieldAsNull,pIgnoreMissingSource)
				If $$$ISERR(tSC2)&&('pIgnoreMissingSource||(($$$StatusText(tSC2)'["No segment found")&&($$$StatusText(tSC2)'["is not an element, instead this node"))) {
					Set tSC=tSC2
					Quit
				}
			}
		} Else {
			Set i="" For { Set i=..GetNextIndex(tTargetHead_"()",i,.tSC) Quit:i=""
				Set tTargetNewPath=tTargetHead_"("_(i)_")"_tTargetTail
				Set tSC=..CopyValues(pSource,pSourcePath,tTargetNewPath,pAction,pKey,pEmptyFieldAsNull,pIgnoreMissingSource) Quit:$$$ISERR(tSC)
			}
		}
	} Else {
		Set tSourceGrpPath=$P(pSourcePath,":"), tSourcePropPath=$P(pSourcePath,":",2)
		Set tTargetGrpPath=$P(pTargetPath,":"), tTargetPropPath=$P(pTargetPath,":",2)
		Set tSrcSegPath=pSource.GetNextGroupPath(tSourceGrpPath,tSourceGrpPath)
		Set tTrgSegPath=..GetNextGroupPath(tTargetGrpPath,tTargetGrpPath)
		If (""'=tSrcSegPath)||(""'=tTrgSegPath) { ; if there are group sub-elements
			If (""'=tSrcSegPath) {
				For {
					Set tSourceNewPath=tSrcSegPath_$S(""=tSourcePropPath:"",1:":"_tSourcePropPath)
					Set tTargetNewPath=tTargetGrpPath_$E(tSrcSegPath,1+$L(tSourceGrpPath),$L(tSrcSegPath))_$S(""=tSourcePropPath:"",1:":"_tSourcePropPath)
					Set tSC=..CopyValues(pSource,tSourceNewPath,tTargetNewPath,pAction,pKey,pEmptyFieldAsNull,pIgnoreMissingSource) Quit:$$$ISERR(tSC)
					Set tSrcSegPath=pSource.GetNextGroupPath(tSourceGrpPath,tSrcSegPath,.tSC) Quit:$$$ISERR(tSC)
					Quit:""=tSrcSegPath
				}
			} Else {
				For {
					Set tTargetNewPath=tTrgSegPath_$S(""=tTargetPropPath:"",1:":"_tTargetPropPath)
					Set tSC=..CopyValues(pSource,pSourcePath,tTargetNewPath,pAction,pKey,pEmptyFieldAsNull,pIgnoreMissingSource) Quit:$$$ISERR(tSC)
					Set tTrgSegPath=..GetNextGroupPath(tTargetGrpPath,tTrgSegPath,.tSC) Quit:$$$ISERR(tSC)
					Quit:""=tTrgSegPath
				}
			}
		} Else {
			If ""'=tSourcePropPath||("*"=pSourcePath)||($E(pSourcePath,*-2,*)="(*)") {
				If pGenerateEmptySegments {
					Set tSC=..SetValueAt(pSource.GetValueAt(pSourcePath,,.tSC2,pEmptyFieldAsNull),pTargetPath,pAction,pKey)
					Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)
				} Else {
					Set tSourceValue = pSource.GetValueAt(pSourcePath,,.tSC,pEmptyFieldAsNull)	Quit:$$$ISERR(tSC) tSC
					Set tSC=..SetValueAt(tSourceValue,pTargetPath,pAction,pKey)
				}
				
			} Else { ; create clone segment object for id or oref
				Set tId=pSource.GetSegmentIdAt(pSourcePath,.tSC)  Quit:$$$ISERR(tSC) tSC
				If tId'="" {
					Set tSegObj=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB(tId,1,"",1))
					Set:$IsObject(tSegObj) tSC=..SetSegmentAt(tSegObj,pTargetPath)
				} Else {
					Set tSegObj=pSource.GetSegmentAt(pSourcePath,.tSC)  Quit:$$$ISERR(tSC) tSC
					Set:$IsObject(tSegObj) tSC=..SetSegmentAt(tSegObj.%ConstructClone(),pTargetPath)
				}
			}
		}
	}
	Quit tSC
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean = 0) As %Status
{
	If 0=pDaysToKeep Do ..KillGlobals(.pDeletedCount,1,0)  Quit $$$OK

	New %tDoNotDeleteDate,%tID,%tTime  Set %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(Declare C1 Cursor for
		Select ID,TimeCreated Into :%tID,:%tTime From EnsLib_EDI_EDIFACT.Document Order By ID)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		If $$$timeCmp(%tTime,%tDoNotDeleteDate)<0 {
			&sql(Delete From EnsLib_EDI_EDIFACT.Document Where ID=:%tID)
			Set pDeletedCount=pDeletedCount+%ROWCOUNT
		}
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE)
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	For index=1:1:+$G($$$vaExtentGbl(%tID,"segs")) {
		Set segid=$$$vaExtentGbl(%tID,"segs",index)
		Kill $$$vaSegmentRef(segid,%tID)
		If '$D($$$vaSegmentRefs(segid))&&($G($$$vaOpenSegmentPPG(segid),0)<=0) {
			Kill $$$vaSegment(segid)
			Kill $$$vaOpenSegmentPPG(segid)
		}
	}
	&sql(Delete From EnsLib_EDI_EDIFACT.Document Where OriginalDocId=:%tID)
	&sql(Delete From EnsLib_EDI_EDIFACT.Document Where ParentId=:%tID Or ParentId %StartsWith :%tID||':')
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID,index,segid  Set %tID={%%ID}
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	For index=1:1:+$G($$$vaExtentGbl(%tID,"segs")) {
		Set segid=$$$vaExtentGbl(%tID,"segs",index)
		Kill $$$vaSegmentRef(segid,%tID)
		If '$D($$$vaSegmentRefs(segid))&&($G($$$vaOpenSegmentPPG(segid),0)<=0) {
			Kill $$$vaSegment(segid)
			Kill $$$vaOpenSegmentPPG(segid)
		}
	}
	&sql(Delete From EnsLib_EDI_EDIFACT.Document Where OriginalDocId=:%tID)
	&sql(Delete From EnsLib_EDI_EDIFACT.Document Where ParentId=:%tID Or ParentId %StartsWith :%tID||':')
	Quit
}

ClassMethod KillGlobals(Output pDeletedCount, pKeepExtentCount = 0, pDisplayLog = 1)
{
	Set pDeletedCount=..TotalCount()
	Set tExtentCount=$G($$$vaExtentGbl)
	Write:pDisplayLog !,"Killing ",$classname()," extent ("_pDeletedCount_"/"_tExtentCount_")"
	Do ..%KillExtent()
	Set:pKeepExtentCount $$$vaExtentGbl=tExtentCount

	Do ##class(EnsLib.EDI.EDIFACT.SearchTable).%KillExtent()

	Set globals($Name($$$vaSegmentGbl))=""

	Set global="" For { Set global=$O(globals(global))  Quit:""=global
		Kill tExtentCount  Set:pKeepExtentCount tExtentCount=$S($D(@global)#2:@global,1:$$topNodesSum(global))
		Write:pDisplayLog !,"Killing ",global,"("_$G(tExtentCount)_")"
		Kill @global
		If $D(tExtentCount) Set @global=tExtentCount
	}
	Quit
topNodesSum(global)
	Set tSum=0,cnt=0,sub="" For { Set sub=$O(@global@(sub),1,cnt) Quit:""=sub  Set tSum=tSum+cnt }
	Quit tSum
}

ClassMethod TotalCount() As %Integer
{
	&sql(SELECT COUNT(*) INTO :tCount From EnsLib_EDI_EDIFACT.Document)
	Quit tCount
}

Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	#; Kill Segment storage if not %Save'd and segment not used by other Documents
	Set tId=..%Id()
	If ""=tId {
		If $D($$$vaM("runtimeIndex")) {
			For index=1:1:$$$vaM("runtimeIndex") { Set seg=$G($$$vaM("runtimeIndex",index))
				If '$$$vaIsOref(seg) { Set segid=$P(seg,"|") }
				Else {
					Set tSegObj=..%maps("orefs",index)
					Set segid=tSegObj.ID
				}
				If ""'=segid {
					Set $$$vaOpenSegmentPPG(segid) = ($G($$$vaOpenSegmentPPG(segid),0) - 1)
					If '$D($$$vaSegmentRefs(segid))&&($$$vaOpenSegmentPPG(segid)<=0) {
						Kill $$$vaSegment(segid)
						Kill $$$vaOpenSegmentPPG(segid)
					}
				}
			}
		} Else {
			Set path="" For { Set path=$O($$$vaM("runtimePath",path),1,seg) Quit:""=path
				If '$$$vaIsOref(seg) { Set segid=$P(seg,"|") }
				Else {
					Set tSegObj=..%maps("orefs",$E(seg,2,*))
					Set segid=$S(tSegObj.%Cloned:"", 1:tSegObj.ID) ; don't delete ID from cloned segs because the ID does not really belong to them
				}
				If ""'=segid {
					Set $$$vaOpenSegmentPPG(segid) = ($G($$$vaOpenSegmentPPG(segid),0) - 1)
					If '$D($$$vaSegmentRefs(segid))&&($$$vaOpenSegmentPPG(segid)<=0) {
						Kill $$$vaSegment(segid)
						Kill $$$vaOpenSegmentPPG(segid)
					}
				}
			}
		}
	}
	If 'tId||$D($$$vaExtentGbl(tId)) $$$vaMkill  ; ..%maps can be undefined when aborting %OpenId() of nonexistent Id
	Quit $$$OK
}

Method AddFunctionalGroup(pGS As EnsLib.EDI.EDIFACT.Segment, Output pGroupSegIndex As %Integer = "") As %Status
{
	Quit:"Interchange"'=..Name $$$ERROR($$$EnsErrGeneral,"Can only add FunctionalGroups to an Interchange document, not a "_..Name)
	Set tSC=..AppendSegment(pGS) Quit:$$$ISERR(tSC) tSC
	Set tDataElementSeparator=$$$ELESEP(..Separators)
	Set tPlaceholder=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",$E(..Separators,1,4)_"TransactionSetDocsRef"_tDataElementSeparator_(..SegCount+1)_tDataElementSeparator))
	Set tSC=..AppendSegment(tPlaceholder) Quit:$$$ISERR(tSC) tSC
	Set pGroupSegIndex=..SegCount
	Set tGE=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",$E(..Separators,1,4)_"GE"_tDataElementSeparator_0_tDataElementSeparator_pGS.GetValueAt(6)))
	Set tSC=..AppendSegment(tGE) Quit:$$$ISERR(tSC) tSC
	Quit $$$OK
}

/// Add a TransactionSet to the Interchange. Add it to a group given the segment index of the placeholder segment between GS and GE segments.
Method AddTransactionSet(pTxnSet As EnsLib.EDI.EDIFACT.Document, pGroupSegIndex As %Integer, pAttachment As %Stream.Object = {$$$NULLOREF}) As %Status
{
	Quit:"Interchange"'=..Name $$$ERROR($$$EnsErrGeneral,"Can only add TransactionSets to an Interchange document, not a "_..Name)
	Set pTxnSet.ParentId=..getId()_":"_pGroupSegIndex
	Set pTxnSet.IsMutable=0
	Set tSC=pTxnSet.%Save()

	#; Add to count of children in the group placeholder segment and the GE segment
	Set tSC=..SetValueAt(1+..GetValueAt(pGroupSegIndex_":2"),pGroupSegIndex_":2") Quit:$$$ISERR(tSC) tSC
	Set tSC=..SetValueAt(1+..GetValueAt((pGroupSegIndex+1)_":1"),(pGroupSegIndex+1)_":1") Quit:$$$ISERR(tSC) tSC

	#; Add attachments if any into the Interchange
	If $IsObject(pAttachment) {
		If pAttachment.%Extends("%Collection.AbstractListOfObj") {
			For i=1:1:pAttachment.Count() {
				Set tSC=..AddAttachment(pAttachment.GetAt(i))  Quit:$$$ISERR(tSC)
			}
		} Else { Set tSC=..AddAttachment(pAttachment)  Quit:$$$ISERR(tSC) tSC }
	}
	Quit tSC
}

Method AddEndSegment() As %Status
{
	Set tDataElementSeparator=$$$ELESEP(..Separators)
	If "Interchange"=..Name {
		Set tNumGroups=0 For i=1:1:..SegCount { Set:"GS"=..GetValueAt(i_":0") tNumGroups=tNumGroups+1 }
		Set tIEA=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",$E(..Separators,1,4)_"IEA"_tDataElementSeparator_tNumGroups_tDataElementSeparator_..GetValueAt("1:13")))
		Set tSC=..AppendSegment(tIEA) Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSE=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",$E(..Separators,1,4)_"SE"_tDataElementSeparator_(..SegCount+1)_tDataElementSeparator_..GetValueAt("1:2")))
		Set tSC=..AppendSegment(tSE) Quit:$$$ISERR(tSC) tSC
	}
	Quit $$$OK
}

Method NewReplyDocument(pDocType As %String = "", pLocalApplicationID As %String, Output pSC As %Status) As EnsLib.EDI.EDIFACT.Document
{
	Kill %objlasterror
	Set pSC=$$$OK, tReplyDoc=..%New($LB("",..Separators))
	If '$IsObject(tReplyDoc) Set pSC=$$$ERROR($$$EnsErrGeneral,"Failed to instantiate reply document for doc "_..%Id()_"; status = "_$G(%objlasterror,$$$OK))  Quit $$$NULLOREF
	Set:""=pDocType pDocType=..DocType
	If "Interchange"=..Name {
		Set tISA=..GetSegmentAt(1)
		If $IsObject(tISA) {
			Set:"UNA"=tISA.Name tISA=..GetSegmentAt(2)
			If $IsObject(tISA) {
				Set tReplyHeaderSeg=..NewReplyHeaderSeg(tISA,pLocalApplicationID,.pSC)
				Do:$IsObject(tReplyHeaderSeg) tReplyDoc.AppendSegment(tReplyHeaderSeg)
			}
		}
	} Else {
		If ""=pDocType {
			Set tParentISA=..ParentHeaderSeg
			Set:$IsObject(tParentISA) pDocType=$P(tParentISA.DocType,":")_":997"
		}
		Set tST=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",$E(..Separators,1,4)_"ST"_$$$ELESEP(..Separators)_"997"))
		Do:$IsObject(tST) tReplyDoc.AppendSegment(tST)
	}
	Set tReplyDoc.DocType=pDocType
	Quit tReplyDoc
}

ClassMethod NewReplyHeaderSeg(pOriginalHeaderSeg As EnsLib.EDI.EDIFACT.Segment, pLocalApplicationID As %String = "", Output pSC) As EnsLib.EDI.EDIFACT.Segment
{
	Set tSC=$$$OK
	Do {
		Set tReplyHeaderSeg=pOriginalHeaderSeg.%ConstructClone()  If '$IsObject(tReplyHeaderSeg) Set tSC=%objlasterror  Quit

		If "UIB"=pOriginalHeaderSeg.Name {
			Set tSenderField=6
			Set tDateField=8
			Set tMsgIdField="3.1"
			Set tReplyField=""
		} Else {
			Set tSenderField=2
			Set tDateField=4
			Set tMsgIdField=5
			Set tReplyField=9
		}
		Set tRcvrField=tSenderField+1, tTimeH=$H
			
		#; Determine the ID that we should use as Sender in this reply
		#; - support indirection and escaping to allow @ to represent the caller's ID value
		Set tRcvrID=$P(pLocalApplicationID,":",1), tRcvrQual=$P(pLocalApplicationID,":",2), tRcvrIntID=$P(pLocalApplicationID,":",3), tRcvrIntSID=$P(pLocalApplicationID,":",4)
		If pLocalApplicationID["@" {
			Set pos=1 For { Set pos=$F(tRcvrID,"\",pos)  Quit:'pos  Set c=$E(tRcvrID,pos)
				Set tNew=$Case(c, "@":-1, "\":"\", :"\"_c), $E(tRcvrID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrID=$Replace($Replace(tRcvrID,"@",pOriginalHeaderSeg.GetValueAt(tRcvrField_".1")),-1,"@")
			Set pos=1 For { Set pos=$F(tRcvrQual,"\",pos)  Quit:'pos  Set c=$E(tRcvrQual,pos)
				Set tNew=$Case(c, "@":-1, "\":"\", :"\"_c), $E(tRcvrQual,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrQual=$Replace($Replace(tRcvrQual,"@",pOriginalHeaderSeg.GetValueAt(tRcvrField_".2")),-1,"@")
			Set pos=1 For { Set pos=$F(tRcvrIntID,"\",pos)  Quit:'pos  Set c=$E(tRcvrIntID,pos)
				Set tNew=$Case(c, "@":-1, "\":"\", :"\"_c), $E(tRcvrIntID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrIntID=$Replace($Replace(tRcvrIntID,"@",pOriginalHeaderSeg.GetValueAt(tRcvrField_".3")),-1,"@")
			Set pos=1 For { Set pos=$F(tRcvrIntSID,"\",pos)  Quit:'pos  Set c=$E(tRcvrIntSID,pos)
				Set tNew=$Case(c, "@":-1, "\":"\", :"\"_c), $E(tRcvrIntSID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrIntSID=$Replace($Replace(tRcvrIntSID,"@",pOriginalHeaderSeg.GetValueAt(tRcvrField_".4")),-1,"@")
		}
		Set tCS=tReplyHeaderSeg.CS, tReplyerID=tRcvrID_tCS_tRcvrQual_tCS_tRcvrIntID_tCS_tRcvrIntSID

		#; Set the Receiver ID for this reply as the Sender ID that came to us
		Set tOriginalSenderID=pOriginalHeaderSeg.GetValueAt(tSenderField,,.tSC)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyHeaderSeg.SetValueAt(tOriginalSenderID,tRcvrField)  Quit:$$$ISERR(tSC)
		
		#; Set the Sender ID for this reply as the replyer ID we just determined based on the Receiver ID that came to us
		While tCS=$E(tReplyerID,*) { Set tReplyerID=$E(tReplyerID,1,*-1) }
		Set tSC=tReplyHeaderSeg.SetValueAt(tReplyerID,tSenderField)  Quit:$$$ISERR(tSC)
		
		#; Date & Time
		Set tSC=tReplyHeaderSeg.SetValueAt($E($ZDate(tTimeH,8),3,8),tDateField_".1")  Quit:$$$ISERR(tSC)
		Set tSC=tReplyHeaderSeg.SetValueAt($TR($ZTime($P(tTimeH,",",2),2),":"),tDateField_".2")  Quit:$$$ISERR(tSC)
		
		#; Get a new interchange control number for this interchange
		Set tInterchangeControlNumber=..NewControlID(0,tOriginalSenderID,tReplyerID,"I")
		Set tSC=tReplyHeaderSeg.SetValueAt(tInterchangeControlNumber,tMsgIdField)  Quit:$$$ISERR(tSC)
		
		#; Set whether ACK is required for this message
		Set tSC=tReplyHeaderSeg.SetValueAt(0,tReplyField)  Quit:$$$ISERR(tSC)
	} While 0
	Set pSC=tSC
	Quit tReplyHeaderSeg
}

/// Create a new group segment as a reply corresponding to an original GS segment
ClassMethod NewReplyGroupSeg(pOriginalGS As EnsLib.EDI.EDIFACT.Segment, Output pSC As %Status) As EnsLib.EDI.EDIFACT.Segment
{
	Set tSC=$$$OK, tTimeH=$H
	do {
		Set tReplyGS=pOriginalGS.%ConstructClone()  If '$IsObject(tReplyGS) Set tSC=%objlasterror  Quit

		#; Swap Sender/Receiver Code (TO DO: May have to consult BusinessService)
		Set tSC=tReplyGS.SetValueAt($E($ZDate(tTimeH,8),3,8),$$$GSDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyGS.SetValueAt($Translate($ZTime($P(tTimeH,",",2),2),":"),$$$GSTime)  Quit:$$$ISERR(tSC)
		
		Set tOriginalSender=pOriginalGS.GetValueAt($$$GSApplicationSendersCode)
		Set tOriginalReceiver=pOriginalGS.GetValueAt($$$GSApplicationReceiversCode)

		Set tSC=tReplyGS.SetValueAt(..NewControlID(0,tOriginalSender,tOriginalReceiver,"G"),$$$GSGroupControlNumber)  Quit:$$$ISERR(tSC)

		Set tSC=tReplyGS.SetValueAt(tOriginalReceiver,$$$GSApplicationSendersCode)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyGS.SetValueAt(tOriginalSender,$$$GSApplicationReceiversCode)  Quit:$$$ISERR(tSC)
	} while (0)
	Set pSC=tSC
	Quit tReplyGS
}

/// Get an new unique control number. Control numbers are classified into interchange control numbers "I" and
/// group control numbers "G".
ClassMethod NewControlID(pInbound As %Boolean = 0, pReceiverID As %String, pSenderID As %String, pType As %String = "H") As %Integer
{
	; $$$NUM($TR($ZH,"."),12)
	Set pReceiverID=$ZStrip(pReceiverID,"<>W"), pSenderID=$ZStrip(pSenderID,"<>W")
	Set:""=pReceiverID pReceiverID="0"
	Set:""=pSenderID pSenderID="0"
	Set tControlNumber=$Increment(^EnsEDI.ControlNumber(pInbound,pReceiverID,pSenderID,pType))
	Set ^EnsEDI.ControlNumber(pInbound,pReceiverID,pSenderID,pType,tControlNumber)=$Piece($Horolog,",")_"|"_$ZHorolog
	Quit tControlNumber
}

Method AddAttachment(pStream As %Stream.Object) As %Status
{
	Set:'pStream.%IsA("Ens.StreamContainer") pStream=##class(Ens.StreamContainer).%New(pStream)
	Set tFilename=$G(pStream.Stream.Attributes("Filename"))
	Set:""=tFilename&&pStream.Stream.%Extends("%Library.FileStreamAdaptor") tFilename=pStream.Filename, pStream.Stream.Attributes("Filename")=tFilename
	Quit:""=tFilename $$$ERROR($$$EnsErrGeneral,"Attachment stream must contain 'Filename' Attribute")
	Set tOld=..Attachments.GetObjectIdAt(tFilename)
	If ""'=tOld $$$LOGWARNING("Overwriting attachment "_tOld.%Id()_" with same filename '"_tFilename_"' as new attachment "_pStream.%Id()_" in Interchange "_$this_"/"_..%Id())
	Quit ..Attachments.SetAt(pStream,tFilename)
}

/// Delete All Content and reset all properties
Method Clear() As %Status
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Set tSC=..%OnClose()  Quit:$$$ISERR(tSC) tSC
	Kill $$$vaM("runtimeIndex"), $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex")
	Set $$$vaM("runtimeIndex")=0
	Set i%BuildMapStatus=""
	Set ..Source=""
	Quit $$$OK
}

/// The same as %Id(), but allocates the Id even if the object hasn't been saved already
Method getId() As %String [ CodeMode = generator ]
{
	$$$GENERATE(" If ..%Id()="""" Do ..%IdSet($increment("_$$$EXTidlocation($$$pEXT,%class)_"))")
	$$$GENERATE(" Quit ..%Id()")
	Quit $$$OK
}

/// Returns an array of links to manager pages for this type of VDoc; item 0 is the family description
ClassMethod GetManagerLinks(Output pColumns) As %Boolean
{
	Set iCol=0
	Set pColumns(iCol,"page")="http://www.unece.org/trade/untdid/welcome.htm"
	Set pColumns(iCol,"name")=$$$Text("UN/EDIFACT")
	Set pColumns(iCol,"desc")=$$$Text("United Nations Directories for Electronic Data Interchange for Administration, Commerce and Transport ")
	
	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("SEF/EDISchemaMain.csp?FAMILY=EDIFACT")
	Set pColumns(iCol,"name")=$$$Text("Schema Structures")
	Set pColumns(iCol,"desc")=$$$Text("View schema definitions for various types of EDIFACT documents")

	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("EDIDocumentView.csp?NAME="_$ZCVT("EDIFACT Document","O","URL")_"&CLASS=EnsLib.EDI.EDIFACT.Document")
	Set pColumns(iCol,"name")=$$$Text("Document Viewer")
	Set pColumns(iCol,"desc")=$$$Text("View EDIFACT Documents from a variety of sources and test them with various DocType schema definitions and Data Transformations")

	Quit 1
}

Storage Default
{
<Data name="Attachments">
<Attribute>Attachments</Attribute>
<Structure>subnode</Structure>
<Subscript>"Attachments"</Subscript>
</Data>
<Data name="DocumentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ParentId</Value>
</Value>
<Value name="3">
<Value>DocType</Value>
</Value>
<Value name="4">
<Value>IsMutable</Value>
</Value>
<Value name="5">
<Value>TimeCreated</Value>
</Value>
<Value name="6">
<Value>Source</Value>
</Value>
<Value name="7">
<Value>OriginalDocId</Value>
</Value>
<Value name="8">
<Value>ExpRepeat</Value>
</Value>
</Data>
<Data name="UserValues">
<Attribute>UserValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"UserValues"</Subscript>
</Data>
<DataLocation>^EnsLib.EDI.EDIFACT.DocumentD</DataLocation>
<DefaultData>DocumentDefaultData</DefaultData>
<ExtentSize>2000000</ExtentSize>
<IdLocation>^EnsLib.EDI.EDIFACT.DocumentD</IdLocation>
<IndexLocation>^EnsLib.EDI.EDIFACT.DocumentI</IndexLocation>
<StreamLocation>^EnsLib.EDI.EDIFACT.DocumentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
