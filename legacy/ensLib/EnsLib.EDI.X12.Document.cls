/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// Represents an Interchange or a TransactionSet. FunctionalGroups are represented as Segments within an Interchange.
Class EnsLib.EDI.X12.Document Extends (%Persistent, EnsLib.EDI.BatchDocument, EnsLib.EDI.Segmented, EnsLib.EDI.X12.MsgBodyMethods) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter DOCCLASSNAME = "X12 Document";

Parameter DOCCLASSFULLNAME = "ASC X12 EDI Document";

Parameter DOCSHORTNAME = "X12";

/// Name of the default SearchTable indexing class used in UI choices and MessageBank submissions 
Parameter DEFSEARCHCLASS = "EnsLib.EDI.X12.SearchTable";

/// Name of the associated schema class and after a colon the schema element code that represents a DocType
Parameter SCHEMACLASS = "EnsLib.EDI.X12.Schema:DS";

Parameter EXTENTSIZE = 2000000;

Index Extent [ Extent, Type = bitmap ];

Index ParentId On ParentId;

Index OriginalDocId On OriginalDocId;

/// XML or other 'envelope' for the X12 document message. The X12 document will be inserted in place of the "&lt;!--X12DOC--&gt;"
/// string If present, otherwise after the end of the Envelope.
Property Envelope As %String(MAXLEN = "");

/// All 3 Separators as a String, plus optionally SegmentTerminator: ELESEP_COMSEP_REPSEP
/// Additional characters will be output as the Segment Terminator; may have up to 3 additional chars for output with newlines
Property Separators As %String(MAXLEN = 6, MINLEN = 3) [ Transient ];

/// Data-element separator character
Property ElementSeparator As %String [ Calculated, Transient ];

/// Repetition separator character
Property RepetitionSeparator As %String [ Calculated, Transient ];

/// Sub-element component separator character
Property ComponentSeparator As %String [ Calculated, Transient ];

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

Property HandledIndividually As %Boolean [ InitialExpression = 0, Internal ];

/// The raw text content of the document. Note that this is a truncated version suitable for use in SQL results and visual inspection,
/// but not a complete or definitive representation of the document.
Property RawContent As %String(MAXLEN = 10000) [ Calculated, ReadOnly, SqlComputeCode = { Set {RawContent}=##class({%%CLASSNAME}).getSegsAsString({ID}) }, SqlComputed, Transient ];

/// the category portion of the DocType
Property DocTypeCategory As %String [ ReadOnly, Transient ];

/// Stored raw document type name ; the secondary type name portion of the DocType
Property DocTypeName As %String [ ReadOnly, Transient ];

/// Look up the schema structure referenced by DocType in the old-style 'Validation' schema not the new style schema"
Property useValSchema As %String [ Internal, ReadOnly, Transient ];

/// Size in bytes of the message content.
/// The calculation assumes 1-byte segment terminators and includes any segments that use more than one storage node (> X12MaxSegLen).
Property FullSize As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {FullSize}=##class({%%CLASSNAME}).GetFullSize({ID}) }, SqlComputed, Transient ];

/// Internal property for keeping track of errors encountered while parsing the document which weren't severe enough to prevent us from saving
Property %ParsingError As %Status [ InitialExpression = {$$$OK}, Internal ];

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

Property ParentInterchange As EnsLib.EDI.X12.Document [ Calculated, ReadOnly, Transient ];

Property ParentISA As EnsLib.EDI.X12.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the ISA segment of the Interchange within which this TransactionSet arrived
Property ParentISAId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentISAId}=##class({%%CLASSNAME}).getISAId($P({ParentId},":")) }, SqlComputed, Transient ];

Property ParentIEA As EnsLib.EDI.X12.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the IEA segment of the Interchange within which this TransactionSet arrived
Property ParentIEAId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentIEAId}=##class({%%CLASSNAME}).getIEAId($P({ParentId},":")) }, SqlComputed, Transient ];

Property ParentGS As EnsLib.EDI.X12.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the GS segment of the FunctionalGroup in the Interchange within which this TransactionSet arrived
/// or Id of the ISA segment of the Interchange within which this FunctionGroup arrived
Property ParentGSId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentGSId}=##class({%%CLASSNAME}).getGSId({ParentId}) }, SqlComputed, Transient ];

Property ParentGE As EnsLib.EDI.X12.Segment [ Calculated, ReadOnly, Transient ];

/// Id of the GE segment of the FunctionalGroup in the Interchange within which this TransactionSet arrived
/// or Id of the IEA segment of the Interchange within which this FunctionGroup arrived
Property ParentGEId As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentGEId}=##class({%%CLASSNAME}).getGEId({ParentId}) }, SqlComputed, Transient ];

/// Attachment streams associated with this document
Property Attachments As array Of Ens.StreamContainer;

/// Temporary property used to hold pointers to FunctionalGroup child documents<br>
/// Used in DTL Editor when using the DocType Batch multiple structure<br>
/// Only used if <PROPERTY>Name</Property> is Interchange<br>
/// Setter/Getter methods are overridden<br>
Property FunctionalGroups As EnsLib.EDI.X12.Document [ MultiDimensional, Transient ];

/// Temporary property used to hold pointers to TransactionSet child documents<br>
/// Used in the DTL Editor when using the DocType Batch multiple structure<br>
/// Only used if <PROPERTY>Name</Property> is Group<br>
/// Setter/Getter methods are overridden<br>
Property TransactionSets As EnsLib.EDI.X12.Document [ MultiDimensional, Transient ];

Method ElementSeparatorGet() As %String [ CodeMode = expression ]
{
$$$ELESEP(..Separators)
}

Method RepetitionSeparatorGet() As %String [ CodeMode = expression ]
{
$$$REPSEP(..Separators)
}

Method ComponentSeparatorGet() As %String [ CodeMode = expression ]
{
$$$COMSEP(..Separators)
}

Method SegmentTerminatorGet() As %String
{
	Set tSegTerminator=$$$SEGTERM(..Separators)
	If ""=tSegTerminator { Set tISA=..getSegmentByIndex(1) Set:$IsObject(tISA) tSegTerminator=tISA.ISASegmentTerminator }
	Set:""=tSegTerminator tSegTerminator=$$$X12DefSegTerminator
	Quit tSegTerminator
}

Method NameGet() As %String [ CodeMode = expression ]
{
$Case(..GetValueAt("1:0"), "ISA":"Interchange", "GS":"Group", "TA1":"AckGroup", :..GetValueAt("1:1"))
}

/// Retrieve Source document name from parent, if available
Method SourceGet() As %String
{
	Set tSource = i%Source
	If ($piece(tSource,$c(13)) = "") && (..ParentId'="") {
		Set $piece(tSource,$c(13),1) = $piece(..Parent.Source,$c(13))
	}
	Quit tSource
}

ClassMethod getName(pId As %RawString) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegmentGbl(tSegId))
	Quit $Case($$$vaDataSegName(data), "ISA":"Interchange", "GS":"Group", "TA1":"AckGroup", :$$$vaDataTypeName(data))
}

Method TypeVersionGet() As %String
{
	Set tSegName=..GetValueAt("1:0")
	If "TA1"=tSegName {
		Set tParent=..Parent
		Quit $S($IsObject(tParent):tParent.TypeVersion, 1:"")
	}
	Quit $Case(tSegName, "ISA":..GetValueAt("1:12"), "GS":..GetValueAt("1:8"), :..GetValueAt("1:3"))
}

ClassMethod getTypeVersion(pId As %RawString, pParentId As %String) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegmentGbl(tSegId))
	Quit $Case($$$vaDataSegName(data), "ISA":$$$vaDataISATypeVersion(data), "TA1":..getTypeVersion($P(pParentId,":")), "GS":$$$vaDataGSTypeVersion(data), :$$$vaDataTypeVersion(data))
}

Method IdentifierGet() As %String [ CodeMode = expression ]
{
$Case(..GetValueAt("1:0"), "ISA":..GetValueAt("1:13"), "TA1":"", "GS":..GetValueAt("1:6"), :..GetValueAt("1:2"))
}

ClassMethod getIdentifier(pId As %RawString) As %String
{
	Quit:""=pId ""
	Set tSegId=$G($$$vaExtentGbl(pId,"segs",1))
	Quit:""=tSegId ""
	Set data=$G($$$vaSegmentGbl(tSegId))
	Quit $Case($$$vaDataSegName(data), "ISA":$$$vaDataISAIdentifier(data), "TA1":"", "GS":$$$vaDataGSIdentifier(data), :$$$vaDataIdentifier(data))
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

Method ParentInterchangeGet() As EnsLib.EDI.X12.Document [ CodeMode = expression ]
{
##class(EnsLib.EDI.X12.Document).%OpenId(..ParentInterchangeGetObjectId())
}

/// Required for AutoForm
Method ParentInterchangeGetObjectId(force As %Integer) As %String [ CodeMode = expression ]
{
$P(..TopParentId,":")
}

Method ParentISAGet() As EnsLib.EDI.X12.Segment [ CodeMode = expression ]
{
$S(""=$P(..ParentInterchangeGetObjectId(),":"):$$$NULLOREF, 1:..ParentInterchange.GetSegmentAt(1))
}

Method ParentISAIdGet() As %String [ CodeMode = expression ]
{
$S(""=$P(..ParentInterchangeGetObjectId(),":"):"", 1:..ParentInterchange.GetSegmentIdAt(1))
}

ClassMethod getISAId(pParentId As %RawString) As %String
{
	Set tParentIds=..getParentIds(pParentId,1), tNumParents=$LL(tParentIds)
	Set tInterchangeId=$P($LG(tParentIds,tNumParents),":")
	Quit $S(""=tInterchangeId:"", 1:$G($$$vaExtentGbl(tInterchangeId,"segs",1)))
}

Method ParentIEAGet() As EnsLib.EDI.X12.Segment [ CodeMode = expression ]
{
$S(""=$P(..ParentInterchangeGetObjectId(),":"):$$$NULLOREF, 1:..ParentInterchange.GetSegmentAt(..ParentInterchange.SegCount))
}

Method ParentIEAIdGet() As %String [ CodeMode = expression ]
{
$S(""=..ParentId:"", 1:..ParentInterchange.GetSegmentIdAt(..ParentInterchange.SegCount))
}

ClassMethod getIEAId(pParentId As %RawString) As %String
{
	Set tParentIds=..getParentIds(pParentId,1), tNumParents=$LL(tParentIds)
	Set tInterchangeId=$P($LG(tParentIds,tNumParents),":")
	Quit $S(""=tInterchangeId:"", 1:$G($$$vaExtentGbl(tInterchangeId,"segs",$G($$$vaExtentGbl(tInterchangeId,"segs"),0))))
}

Method ParentGSGet() As EnsLib.EDI.X12.Segment
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) $$$NULLOREF
	Quit tParent.GetSegmentAt(tIndex-1)
}

Method ParentGSIdGet() As %String
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentIdAt(tIndex-1)
}

ClassMethod getGSId(pId As %RawString) As %String [ CodeMode = expression ]
{
$S($Case($F(pId,":"), 0:1 ,2:1, $L(pId)+1:1, :0):"", 1:$G($$$vaExtentGbl($P(pId,":"),"segs",$P(pId,":",2)-1)))
}

Method ParentGEGet() As EnsLib.EDI.X12.Segment
{
	Set tId=..ParentId, tId=$P(tId,":"), tIndex=$P(tId,":",2)  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentAt(tIndex+1)
}

Method ParentGEIdGet() As %String
{
	Set tId=..ParentId, tIndex=$P(tId,":",2), tId=$P(tId,":")  Quit:""=tId ""
	Set tParent=..%OpenId(tId)  Quit:'$IsObject(tParent) ""
	Quit tParent.GetSegmentIdAt(tIndex+1)
}

ClassMethod getGEId(pId As %RawString) As %String [ CodeMode = expression ]
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
		Set segid = $$$vaExtentGbl(pMsgId,"segs",i)
		Set tVal = $$$vaSegmentGbl(segid)
		If tIsBatchParent {
			#; Skip "DocsRef" segments because these are a convenience for us - not part of the real message
			#; Not a concern if the message is not a batch parent
			Continue:"DocsRef"=$E($$$vaDataSegName(tVal),*-$L("DocsRef")+1,*)
		}

		#; Add segment size: - 3 separators + 1 terminator
		Set tLen = tLen + $L(tVal) - 2
		#; Get extra from any segs > 32k
		For j=1:1 {
			Quit:'$D($$$vaSegmentGbl(segid,j),extra)
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
			Set path=tHead
			Set tFirstIteration = 1
			For {
				Set path=$O($$$vaM("runtimePath",path))
				If (path="") || ($E(path,1,tLen)'=tHead) {
					#; May have reached the last segment in the loop, or may not yet have found any segments in the loop
					#; If haven't found any yet, it could be that we are trying to iterate over repetitions of a segment with a keyfield without using the keyfield in the path
					#; Only need to check for old-style schemas because new-style only uses keyfields for first segment in loops, so segment wouldn't be repeating
					If tFirstIteration && ..useValSchema && (tHead["-") && (tHead'["!") {
						Set path = $P(tHead,"-")
						Set tOrdinal = $P($P(tHead,"-",*),"(")
						Set tFoundMatch = 0
						For {
							Set path = $O($$$vaM("runtimePath",path))
							#; Quit if no result or path doesn't contain a keyfield or part of path before the keyfield doesn't match with tHead
							Quit:((path="") || (path'["!") || ($P(path,"!")'=$P(tHead,"-")))
							#; We have only found the loop we are looking for if the ordinals match
							#; Otherwise we will keep looking because could be multiple segments of the same name in the same loop, but with different ordinals
							If $P($P(path,"-",*),"(")=tOrdinal {
								Quit:($P(path,"-",*)'["(")
								#; Need to adjust tHead for use in the outer loop and in $$$vaM
								Set tHead = $P(path,"(",1,*-1)
								Set tLen = $L(tHead)
								#; Note that a match was found so we don't quit out of outer loop. Then quit out of this loop.
								Set tFoundMatch = 1
								Quit
							}
						}
						#; Turned out not to be any segments starting with tHead, even after checking for the possibility tHead is just missing a keyfield
						Quit:'tFoundMatch
					} Else {
						#; path isn't in the loop
						Quit
					}
				}
				Set tFirstIteration = 0
				Set $$$vaM("loopIndex",tHead,$E(path,tLen+1,$F(path,")",tLen)-2))=""
			}
			If '$D($$$vaM("loopIndex",tHead)) Set $$$vaM("loopIndex",tHead)=0
		}
		Quit $O($$$vaM("loopIndex",tHead,pIndex))
	}
}

/// Gets the next path alphabetically within a group.
/// No need to worry about possiblity of a <var>pPath</var> value which is missing its keyfield, since we only ever pass in values which have been the return value from a previous call to this method or are the <var>pGroup</var> itself 
Method GetNextGroupPath(pGroup As %String, pPath As %String, ByRef pStatus As %Status = {$$$OK}) As %String
{
	Quit:$$$vaIsIndex(pGroup) ""
	If pGroup[":"||($L(pPath)<$L(pGroup)) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't iterate in Group '"_pGroup_"' on Path '"_pPath_"'") Quit ""
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set nextpath=$O($$$vaM("runtimePath",pPath))
	Quit:$E(nextpath,1,$L(pGroup))'=pGroup||$Case($E(nextpath,$L(pGroup)+1),"(":0,".":0,:1) ""
	Quit nextpath
}

/// pSegmentPropertyPath is of syntax: [loop-containing-segment [ . nested-loop-containing-segment ] . ] segment-name [ : element [ ( array ) ] [ . component ] ]
/// Set the value at the specified property path.
/// All property path elements must be either name or index.<br>
/// Use of the "append" action to make a field or component's total length more than the maximum string length (approximately 3.6MB) is not supported.
/// Instead, use the method StoreRawDataStream()
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
		Quit tSegObj.SetValueAt(.pValue,tPropPath,pAction,pKey)
	}
}

/// pSegmentPropertyPath is of syntax: [loop-containing-segment [ . nested-loop-containing-segment ] . ] segment-name [ : element [ ( array ) ] [ . component ] ]
/// Returns the value at the specified property path. pSeparators is used to specify the
/// separators to be used when a non-atomic value is returned.
/// All property path elements must be either name or index.<br>
/// When retrieving full segment data any trailing Data Element, Component Element or Repetition Separators will be removed unless the segment is ISA.
/// If the length of the field is greater than the maximum string length on the system, then only the 
/// maximum string length will be retrieved using this method unless <param>pReturnStreamIfLong</param> is set to 1.
/// If <param>pReturnStreamIfLong</param> is set to 0 and the value is longer than the maximum string length,
/// output parameter <param>pIsIncomplete</param> will be set to 1 to indicate that there is more to the value than what is returned.
/// (Note that with long strings enabled the limit is approximately 3.6MB.)
Method GetValueAt(pSegmentPropertyPath As %String, pSeparators As %String, Output pStatus As %Status, pTreatEmptyAsNull As %Boolean = 0, pReturnStreamIfLong As %Boolean = 0, Output pIsIncomplete As %Boolean) As %String
{
	Set pStatus=$$$OK, tSeparators=$G(pSeparators,..Separators), pIsIncomplete=0
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
		Set pStatus = $$$ERROR($$$EnsErrGeneral,"Invalid segment count value path '"_tSegmentPath_"'")
		Quit ""
	}
	Set tSegObj=..GetSegmentAt(tSegmentPath,.pStatus)
	If '$IsObject(tSegObj)||$$$ISERR(pStatus) {
		Quit ""
	} Else {
		Quit tSegObj.GetValueAt(tPropertyPath,tSeparators,.pStatus,pTreatEmptyAsNull,pReturnStreamIfLong,.pIsIncomplete)
	}
}

/// pSegmentPropertyPath is of syntax: [loop-containing-segment [ . nested-loop-containing-segment ] . ] segment-name [ : element [ ( array ) ] [ . component ] ]
/// Returns the value at the specified property path. pSeparators is used to specify the
/// separators to be used when a non-atomic value is returned.
/// All property path elements must be either name or index.<br>
/// When retrieving full segment data any trailing Data Element, Component Element or Repetition Separators will be removed unless the segment is ISA.
/// This method will return the value as a stream even if its length is less than the maximum string length.
Method GetValueAsStream(pSegmentPropertyPath As %String, pSeparators As %String, Output pStatus As %Status, pTreatEmptyAsNull As %Boolean = 0) As %Stream.GlobalCharacter
{
	Set pStatus=$$$OK, tSeparators=$G(pSeparators,..Separators), pIsIncomplete=0
	Set tSegmentPath=$P(pSegmentPropertyPath,":"), tPropertyPath=$P(pSegmentPropertyPath,":",2)
	If ""=tPropertyPath&&(tSegmentPath["*") {
		Set tStream = ##class(%Stream.GlobalCharacter).%New()
		Quit:$Case(tSegmentPath,"*":1,"(*)":1,:0) ..SegCount
		Set tLen=$L(tSegmentPath)
		If $E(tSegmentPath,tLen-2,tLen)="(*)" {
			Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
			Set count=0, (path,path0)=$E(tSegmentPath,1,tLen-2), tLen0=$L(path0), i=0
			For { Set path=$O($$$vaM("runtimePath",path))  Quit:path=""||(path0'=$E(path,1,tLen0))
				Set ti=+$E(path,tLen0+1,*)  Set:ti'=i&&ti count=count+1,i=ti
			}
			Set pStatus = tStream.Write(count)
			Quit tStream
		}
		If $E(tSegmentPath,tLen-1,tLen)=".*" {
			Set count=0,(path,path0)=$E(tSegmentPath,1,tLen-2),tLen0=$L(path0)
			Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
			For { Set path=$O($$$vaM("runtimePath",path))  Quit:path=""||(path0'=$E(path,1,tLen0))  Set count=count+1 }
			Set pStatus = tStream.Write(count)
			Quit tStream
		}
		Set pStatus = $$$ERROR($$$EnsErrGeneral,"Invalid segment count value path '"_tSegmentPath_"'")
		Quit $$$NULLOREF
	}
	Set tSegObj=..GetSegmentAt(tSegmentPath,.pStatus)
	If '$IsObject(tSegObj)||$$$ISERR(pStatus) {
		Quit $$$NULLOREF
	} Else {
		Quit tSegObj.GetValueAsStream(tPropertyPath,tSeparators,.pStatus,pTreatEmptyAsNull)
	}
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
	
	If (tVal="") && (pPath'["!") {
		Set tPathStart = $P(pPath,"-")
		Set tPathEnd = $Select(..useValSchema:"-"_$P(pPath,"-",*),1:"")
		Set tFullPath = tPathStart
		For {
			Set tFullPath = $O($$$vaM("bidirectionalLink",tFullPath),1,tPossibleVal)	Quit:tFullPath=""
			#; Quit if path starts differently, but for validation schema, could have multiple repetitions of an individual segment which does have a keyfield.
			#; New-style won't have this because keyfields are only used for the start of a new loop
			Quit:($P(tFullPath,"!") '= tPathStart)
			If (tPathEnd = $Select(..useValSchema:"-"_$P(tFullPath,"-",*),1:"")) {
				Set tVal = tPossibleVal
				Quit
			}
		}
	}	
	
	Set:(""=tVal)||(tVal'=+tVal) pStatus=$$$ERROR($$$EnsErrGeneral,"Path "_pPath_" not found")
	Quit tVal
}

/// Gets the next segment after index <var>pIndex</var> with name <var>pSegName</var>.
/// Supports <var>pSegName</var> = '*' to match any segment.
Method FindSegment(pSegName As %String, ByRef pIndex As %String = "", Output pStatus As %Status) As EnsLib.EDI.X12.Segment
{
	Set pStatus=$$$OK, tId=..%Id()  Set:'tId tId=..%ClonedId
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set seg=""  For index=+pIndex+1:1:$$$vaM("runtimeIndex") { Set seg=$$$vaSegLookthru(index,tId)  Continue:""=seg
		If $$$vaIsOref(seg) {
			Set tSegObj=..%maps("orefs",index)
			If (pSegName="*")||(tSegObj.Name=pSegName) Set pIndex=index  Quit
		} Else {
			Set segid=$P(seg,"|"), data=$G($$$vaSegmentGbl(segid))
			If (pSegName="*")||(pSegName=$$$vaDataSegName(data)) {
				#; Same code as in getSegmentByIndex
				Set pIndex=index
				Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB(segid,(..IsMutable&&(tId=..%ClonedId)),$P(seg,"|",2)))
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

Method getSegmentByIndex(pIndex As %Integer, Output pStatus As %Status) As EnsLib.EDI.X12.Segment [ Internal ]
{
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath()
	Set pStatus=$$$OK, tId=..%Id()  Set:'tId tId=..%ClonedId
	Set seg=$$$vaSegLookthru(pIndex,tId)
	If seg="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment Index "_pIndex_" is out of bounds") Quit $$$NULLOREF
	Quit:$$$vaIsOref(seg) ..%maps("orefs",pIndex)
	Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB($P(seg,"|"),(..IsMutable&&..CacheSegsGotten&&(tId=..%ClonedId)),$P(seg,"|",2)))
	If ..CacheSegsGotten {
		Set ..%maps("orefs",pIndex)=tSegObj
		Set $$$vaM("runtimeIndex",pIndex)="@"
		Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	}
	Quit tSegObj
}

Method getSegmentByPath(pPath As %String, Output pStatus As %Status) As EnsLib.EDI.X12.Segment [ Internal ]
{
	Set pStatus=$$$OK
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set seg=$G($$$vaM("runtimePath",pPath))
	If (seg="") && (pPath'["!") {
		Set tPathStart = $P(pPath,"-",1)
		Set tPathEnd = $Select(..useValSchema:"-"_$P(pPath,"-",*),1:"")
		Set tFullPath = tPathStart
		For {
			Set tFullPath = $O($$$vaM("runtimePath",tFullPath),1,tPossibleSeg)	Quit:tFullPath=""
			#; Quit if path starts differently, but for validation schema, could have multiple repetitions of an individual segment which does have a keyfield.
			#; New-style won't have this because keyfields are only used for the start of a new loop
			Quit:($P(tFullPath,"!") '= tPathStart)
			If (tPathEnd = $Select(..useValSchema:"-"_$P(tFullPath,"-",*),1:"")) {
				Set seg = tPossibleSeg
				Set pPath = tFullPath
				Quit
			}
		}
	}
	If seg="" {
		Set pStatus=$$$ERROR($$$EnsErrGeneral,"No segment found at path '"_pPath_"'")
		Quit $$$NULLOREF
	}
	Quit:$$$vaIsOref(seg) ..%maps("orefs",$E(seg,2,*))
	Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB($P(seg,"|"),(..IsMutable&&..CacheSegsGotten&&'..%Id()&&..%ClonedId),$P(seg,"|",2)))
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
	If (seg="") && (pPath'["!") {
		Set tPathStart = $P(pPath,"-",1)
		Set tPathEnd = $Select(..useValSchema:"-"_$P(pPath,"-",*),1:"")
		Set tFullPath = tPathStart
		For {
			Set tFullPath = $O($$$vaM("runtimePath",tFullPath),1,tPossibleSeg)	Quit:tFullPath=""
			#; Quit if path starts differently, but for validation schema, could have multiple repetitions of an individual segment which does have a keyfield.
			#; New-style won't have this because keyfields are only used for the start of a new loop
			Quit:($P(tFullPath,"!") '= tPathStart)
			If (tPathEnd = $Select(..useValSchema:"-"_$P(tFullPath,"-",*),1:"")) {
				Set seg = tPossibleSeg
				Quit
			}
		}
	}
	Quit:'$$$vaIsOref(seg) $P(seg,"|")
	Quit ..%maps("orefs",$E(seg,2,*)).ID
}

Method getMutableSegmentByIndex(pIndex As %Integer, Output pStatus As %Status) As EnsLib.EDI.X12.Segment [ Internal ]
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
	Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB($P(seg,"|"),1,$P(seg,"|",2)))
	If '$IsObject(tSegObj)  Set pStatus=%objlasterror  Quit $$$NULLOREF
	Set tSegObj.Separators=..Separators
	Set ..%maps("orefs",pIndex)=tSegObj
	Set $$$vaM("runtimeIndex",pIndex)="@"
	Set path=$G($$$vaM("bidirectionalLink",pIndex)) Set:""'=path $$$vaM("runtimePath",path)="@"_pIndex
	Quit tSegObj
}

Method getMutableSegmentByPath(pPath As %String, Output pStatus As %Status) As EnsLib.EDI.X12.Segment [ Internal ]
{
	If (..DocTypeCategory="")||(..DocTypeName="") Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")  Quit $$$NULLOREF
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set pStatus=$$$OK, i%BuildMapStatus=""
	#; Find whether this path has been set in this document
	Set seg=$G($$$vaM("runtimePath",pPath))
	If (seg="") && (pPath'["!") {
		#; Could be that there is a keyfield for this segment
		Set tPathStart = $P(pPath,"-")
		Set tPathEnd = $Select(..useValSchema:"-"_$P(pPath,"-",*),1:"")
		Set tFullPath = tPathStart
		For {
			Set tFullPath = $O($$$vaM("runtimePath",tFullPath),1,tPossibleSeg)	Quit:tFullPath=""
			#; Quit if path starts differently, but for validation schema, could have multiple repetitions of an individual segment which does have a keyfield.
			#; New-style won't have this because keyfields are only used for the start of a new loop
			Quit:($P(tFullPath,"!") '= tPathStart)
			If (tPathEnd = $Select(..useValSchema:"-"_$P(tFullPath,"-",*),1:"")) {
				Set seg = tPossibleSeg
				Set pPath = tFullPath
				Quit
			}
		}
	}
	If $$$vaIsOref(seg) {
		Set index=$E(seg,2,*)
		Set tSegObj=..%maps("orefs",index)
		If tSegObj.IsMutable Set tSegObj.Separators=..Separators  Quit tSegObj
		Kill ..%maps("orefs",index)
		Set seg=$S(""=tSegObj.ID:"",1:tSegObj.ID_$S(""=tSegObj.DocType:"", 1:"|"_tSegObj.DocType))
	}
	If ""=seg {
		#; Find whether this path is actually a legitimate one for the schema
		Set tSchemaPath = ..convertRuntimePathToSchemaPath(pPath)
		If '..useValSchema {
			Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath))
			If (""=schema) && (pPath'["!") {
				#; Could be that there is a keyfield for this segment
				#; Only need to check next path in schema because the keyfields will only ever be at the start of a loop in new-style schemas
				Set tNextPath = $O($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath),1,tPossibleSchema)
				If $E(tNextPath,1,$L(tSchemaPath)+1) = (tSchemaPath_"!") {
					Set schema=tPossibleSchema
					#; Need to add keyfields to pPath, since pPath will be stored in runtimePath
					Set pPath = pPath_"!"_$P(tNextPath,"!",2,*)
				}
			}
			Set tSegType=$P($P(schema,"|",2),"!"), tSegName=$P(tSegType,":",2)
		} Else {
			Set schema=$G($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tSchemaPath))
			If (""=schema) && (pPath'["!") {
				#; Could be that there is a keyfield for this segment
				#; Need to loop through schema to look for matches because could have multiple same-name segments in a row which differ only in keyfield and ordinal
				Set tNextPath = $P(tSchemaPath,"-")
				For {
					Set tNextPath = $O($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tNextPath),1,tPossibleSchema)	Quit:""=tNextPath
					If ($E(tNextPath,1,$F(tSchemaPath,"-")-1) '= ($P(tSchemaPath,"-")_"!")) {
						#; At this point we have already checked on any paths that could have been a match  
						Quit
					}
					If ($P(tNextPath,"-",*)=$P(tSchemaPath,"-",*)) {
						#; Ordinals match too.  Only difference is that tNextPath has keyfield and tSchemaPath doesn't
						Set schema=tPossibleSchema
						#; Need to add keyfields to pPath, since pPath will be stored in runtimePath
						Set pPath = $P(pPath,"-")_"!"_$P($P(tPossibleSchema,"!",2,*),"-")_"-"_$P(pPath,"-",*)
						Quit
					}
				}
			}
			Set tSegType=..DocTypeCategory_":"_..DocTypeName_":"_$P(schema,"|",2), tSegName=$P($P($P(tSegType,":",3),"-"),"!")
		}
		If (""=schema) {
			Set pStatus = $$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")
			Quit $$$NULLOREF
		}
		If $ZCVT(tSegName,"U")'=tSegName Set pStatus=$$$ERROR($$$EnsErrGeneral,"Cannot instantiate abstract segment type "_tSegType)  Quit $$$NULLOREF
		Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,tSegType,$E(..Separators,1,3)_tSegName))
		If '$IsObject(tSegObj) Set pStatus=%objlasterror  Quit $$$NULLOREF
		Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
		Set index=$O(..%maps("orefs",""))-1, seg="@"_index
	} Else {
		Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB($P(seg,"|"),1,$P(seg,"|",2)))
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

Method setSegmentByIndex(pSegObj As EnsLib.EDI.X12.Segment, pIndex As %Integer, pInsert As %Boolean) As %Status [ Internal ]
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

Method setSegmentByPath(pSegObj As EnsLib.EDI.X12.Segment, pPath As %String) As %Status [ Internal ]
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:(..DocTypeCategory="")||(""=..DocTypeName) $$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")
	Quit:'$$$IsdefObject(pSegObj) $$$ERROR($$$EnsErrGeneral,"Cannot set null segment object at position "_pPath)
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)
	Set tSchemaPath = ..convertRuntimePathToSchemaPath(pPath)

	If '..useValSchema {
		Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath))
		#; If schema path not found and path doesn't contain keyfields, it may be that our path does exist, but has a keyfield in the schema
		If (""=schema) && (tSchemaPath'["!") {
			Set tNextPath = $O($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath),1,tPossibleSchema)
			If $E(tNextPath,1,$L(tSchemaPath)+1) = (tSchemaPath_"!") {
				Set schema=tPossibleSchema
				Set pPath = pPath_"!"_$P(tNextPath,"!",2,*)
			}
		}
		Set tSegType=$P($P(schema,"|",2),"!"), tSegName=$P(tSegType,":",2)
	} Else {
		Set schema=$G($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tSchemaPath))
		If (""=schema) && (tSchemaPath'["!") {
			Set tNextPath = $P(tSchemaPath,"-")
			For {
				Set tNextPath = $O($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tNextPath),1,tPossibleSchema)	Quit:""=tNextPath
				If ($E(tNextPath,1,$F(tSchemaPath,"-")-1) '= ($P(tSchemaPath,"-")_"!")) {
					Quit
				}
				If ($P(tNextPath,"-",2,*)=$P(tSchemaPath,"-",*)) {
					Set schema=tPossibleSchema
					Set pPath = $P(pPath,"-")_"!"_$P($P(tNextPath,"!",2,*),"-")_"-"_$P(pPath,"-",*)
					Quit
				}
			}
		}
		Set tSegType=..DocTypeCategory_":"_..DocTypeName_":"_$P(schema,"|",2), tSegName=$P($P($P(tSegType,":",3),"-"),"!")
	}
	Quit:(""=schema) $$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")
	Quit:(tSegName'=pSegObj.Name) $$$ERROR($$$EnsErrGeneral,"Cannot set segment named '"_pSegObj.Name_"' at position "_pPath)
	Set pSegObj.DocType=tSegType ; setting by path, Set the SegType to match its new position

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
	Set tSchemaPath = ..convertRuntimePathToSchemaPath(pPath)

	If '..useValSchema {
		Set schema=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath))
		#; If schema path not found and path doesn't contain keyfields, it may be that our path does exist, but has a keyfield in the schema
		If (""=schema) && (tSchemaPath'["!") {
			Set tNextPath = $O($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath),1,tPossibleSchema)
			If $E(tNextPath,1,$L(tSchemaPath)+1) = (tSchemaPath_"!") {
				Set schema=tPossibleSchema
				Set pPath = pPath_"!"_$P(tNextPath,"!",2,*)
			}
		}
	} Else {
		Set schema=$G($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tSchemaPath))
		If (""=schema) && (tSchemaPath'["!") {
			Set tNextPath = $P(tSchemaPath,"-")
			For {
				Set tNextPath = $O($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tNextPath),1,tPossibleSchema)	Quit:""=tNextPath
				If ($E(tNextPath,1,$F(tSchemaPath,"-")-1) '= ($P(tSchemaPath,"-")_"!")) {
					Quit
				}
				If ($P(tNextPath,"-",*)=$P(tSchemaPath,"-",*)) {
					Set schema=tPossibleSchema
					Set pPath = $P(pPath,"-")_"!"_$P($P(tNextPath,"!",2,*),"-")_"-"_$P(pPath,"-",*)
					Quit
				}
			}
		}
	}
	Quit:(""=schema) $$$ERROR($$$EnsErrGeneral,"Path '"_pPath_"' is not mapped in schema for DocType '"_..DocType_"'")
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

	For i=pIndex:1:$$$vaM("runtimeIndex")-1 { ; slide all segments down over removed one
		Set $$$vaM("runtimeIndex",i)=$$$vaSegLookthru(i+1,tId)
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
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Quit:(..DocTypeCategory="")||(..DocTypeName="") $$$ERROR($$$EnsErrGeneral,"Cannot recognize path before DocType is set")
	Do:'$D($$$vaM("runtimePath")) ..BuildMap(0)

	Set seg=$G($$$vaM("runtimePath",pPath))
	If (seg="") && (pPath'["!") {
		Set tPathStart = $P(pPath,"-")
		Set tPathEnd = $Select(..useValSchema:"-"_$P(pPath,"-",*),1:"")
		Set tFullPath = tPathStart
		For {
			Set tFullPath = $O($$$vaM("runtimePath",tFullPath),1,tPossibleSeg)	Quit:tFullPath=""
			#; Quit if path starts differently, but for validation schema, could have multiple repetitions of an individual segment which does have a keyfield.
			#; New-style won't have this because keyfields are only used for the start of a new loop
			Quit:($P(tFullPath,"!") '= tPathStart)
			If (tPathEnd = $Select(..useValSchema:"-"_$P(tFullPath,"-",*),1:"")) {
				Set seg = tPossibleSeg
				Set pPath = tFullPath
				Quit
			}
		}
	}	
	Quit:(seg="") $$$ERROR($$$EnsErrGeneral,"No segment found at path '"_pPath_"'")
	If $$$vaIsOref(seg) { Kill ..%maps("orefs",$E(seg,2,*)) }
	Kill $$$vaM("runtimePath",pPath)

	Kill $$$vaM("runtimeIndex"), $$$vaM("bidirectionalLink") ; we are operating only by PathMap now.
	If ..AutoBuildMap { Do ..BuildMap(0) }
	Else {
		Set i%BuildMapStatus=""
		If pPath["(" {
			#; Invalidate relevant loopIndex sub-arrays if any
			Set tPathHead=$P(pPath,"(",1,*-1)
			Set tHead=tPathHead For { Set tHead=$O($$$vaM("loopIndex",tHead))  Quit:tPathHead_"("'=$E(tHead,1,$L(tPathHead)+1)
				Kill $$$vaM("loopIndex",tHead)
			}
		}
	}
	Quit $$$OK
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
		Set f=f+1
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
	If '..useValSchema {
		Set tMapValue=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map",tSchemaPath))  Quit:""=tMapValue ""
	} Else {
		Set tMapValue=$G($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map",tSchemaPath))  Quit:""=tMapValue ""
	}
	Set tKey=$P(tMapValue,"|")
	#; substitute value for corresponding * placeholder in template
	Set f=1 For i=1:1:tRuntimeIndex {
		Set f=$F(tKey,"*",f)  Quit:'f
		Set $E(tKey,f-1)=$$$NUM(tRuntimeIndex(i),8)
	}
	#; If the repetition subscript is not specified for repeats then subsitute default
	Set:"*"=$E(tKey,*) $E(tKey,$L(tKey))=$$$NUM(1,8)

	#; If couldn't find a replacement position or there are remaining unfilled replacement positions then key is invalid
	Quit:tKey["*"||'f ""
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
	Set:""=..Separators ..Separators=$$$X12DefSeparators
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
	If 'cnt { Set ..Separators=$$$X12DefSeparators }
	Else { Set seg1id=$$$vaExtentGbl(tId,"segs",1), ..Separators=$E($$$vaSegmentGbl(seg1id),1,3)_$G($$$vaSegmentGbl(seg1id,"term")) }
	Set i%DocTypeCategory=$P(..DocType,":",1)  Set:$Case($E(..DocType),"+":1,"-":1,:0) i%DocTypeCategory=$E(i%DocTypeCategory,2,*)
	Set i%DocTypeName=$P(..DocType,":",2)
	Set i%useValSchema=$Case($E(..DocType), "+":0, "-":1, "":"", :$D($$$vaVSchemaGbl(..DocTypeCategory))&&('$D($$$vaSchemaGbl(..DocTypeCategory))||$G(^(..DocTypeCategory,"useOld"))))
	#; No automatic BuildMap here - allow cheap instantiation for routing etc; do BuildMap() only when called for
	Quit $$$OK
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	Set tSC=$$$OK, tId=..%Id()
	Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath()
	Set count=+$G($$$vaM("runtimeIndex"))  For index=1:1:count { Set seg=$$$vaSegLookthru(index,..%ClonedId)
		If $$$vaIsOref(seg) {
			Set tSegObj=..%maps("orefs",index)
			#; Make sure we are saving the segment terminator character for all segments.
			Set tSC=tSegObj.SaveData($E(..Separators,1,3)_..SegmentTerminator)  Quit:$$$ISERR(tSC)
			Set segid=tSegObj.ID
		} Else {
			Set segid=$P(seg,"|")
		}
		If segid {
			Set $$$vaExtentGbl(tId,"segs",index)=segid
			Set $$$vaSegmentGbl(segid,0,tId)=""
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
	Set i%DocTypeCategory=$P(pDocType,":",1)  Set:$Case($E(pDocType),"+":1,"-":1,:0) i%DocTypeCategory=$E(i%DocTypeCategory,2,*)
	Set i%DocTypeName=$P(pDocType,":",2)
	Set i%useValSchema=$Case($E(pDocType), "+":0, "-":1, "":"", :$D($$$vaVSchemaGbl(..DocTypeCategory))&&('$D($$$vaSchemaGbl(..DocTypeCategory))||$G(^(..DocTypeCategory,"useOld"))))
	Do:pBuildMap ..BuildMap()
	Quit $$$OK
}

/// pKeepParsingAfterError means keep trying to parse after errors are encountered; returned Status will contain all errors encountered
/// pReportMissingLoopAsFirstSeg means to report the first segment from loop as missing instead of naming the loop if the loop is missing
Method BuildMap(pKeepParsingAfterError As %Boolean = 1, pReportMissingLoopAsFirstSeg As %Boolean = 0) As %Status
{
	If ((""=..DocTypeCategory)||(""=..DocTypeName)) {
		Set i%BuildMapStatus=$S(""=..DocType:"", 1:$$$ERROR($$$EnsEDIErrMapDocType,"X12",..DocType))
	} Else {
		Quit:$D($$$vaM("runtimePath"))&&(""'=..BuildMapStatus) ..BuildMapStatus ; already done
		Set i%BuildMapStatus=""
	}
	Do:'$D($$$vaM("runtimeIndex")) ..buildRuntimeIndexFromPath(1) ; 1 = clear types
	Kill $$$vaM("runtimePath"), $$$vaM("bidirectionalLink"), $$$vaM("loopIndex")

	Quit:""=..DocType $$$OK
	Quit:""'=..BuildMapStatus ..BuildMapStatus

	If '..useValSchema {
		Set tSchema=$G($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName))
	} Else {
		Set tSchema=$G($$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName))
	}
	If tSchema="" {
		Set i%BuildMapStatus=$$$ERROR($$$EnsEDIErrMapDocType,"X12",..DocType)
		Quit ..BuildMapStatus
	}
	Set tId=..%Id()  Set:'tId tId=..%ClonedId
	Set tCurrSeg=1, %seglastmatch=0, %pathlastmatch=""
	If '..useValSchema {
		Set tSC=..buildRuntimePathFromIndex(tId,"",$Name($$$vaSchemaGbl)_"("""_..DocTypeCategory_""",""DS"","""_..DocTypeName_""",""array"")","top",.tCurrSeg,0,$$$OK,pKeepParsingAfterError,pReportMissingLoopAsFirstSeg)
	} Else {
		Set tSC=..buildRuntimePathFromIndex(tId,"",$Name($$$vaVSchemaGbl)_"("""_..DocTypeCategory_""","""_..DocTypeName_""",""array"")","top",.tCurrSeg,0,$$$OK,pKeepParsingAfterError,pReportMissingLoopAsFirstSeg)
	}
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
				Set data=$G($$$vaSegmentGbl($P(seg,"|")))
				Set currsegname=$$$vaDataSegName(data)
			}
			If tCurrSeg=1 { Set lastname="" }
			Else {
				#; Find previous Segment's Type Name
				Set seg=$$$vaSegLookthru(tCurrSeg-1,tId)
				If $$$vaIsOref(seg) {
					Set tSegObj=..%maps("orefs",tCurrSeg-1)
					Set lastname=tSegObj.Name
				} Else {
					Set data=$G($$$vaSegmentGbl($P(seg,"|")))
					Set lastname=$$$vaDataSegName(data)
				}
			}
			Set lastmatch=$S(""'=lastname&&%seglastmatch:%seglastmatch_" ("_%pathlastmatch_")", 1:"0")
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsEDIErrMapSegUnrecog,currsegname,lastmatch))
		}
	}
	Kill %seglastmatch, %pathlastmatch
	Set i%BuildMapStatus=tSC
	Quit tSC
}

/// Build a segment map for the current segment index array based on the document schema<br>
/// If <var>pKeepParsingAfterError</var> is false then stop parsing when first error is encountered<br>
Method buildRuntimePathFromIndex(pId As %String, pPath As %String, pContentArray As %String, pType As %String, ByRef pCurrSeg As %Integer, pParentGrpOpt As %Boolean, pSC As %Status = {$$$OK}, pKeepParsingAfterError As %Boolean, pReportMissingLoopAsFirstSeg As %Boolean = 0) As %Status
{
	#dim tSC As %Status = pSC
	#dim tSegments As %Integer =$$$vaM("runtimeIndex")
	#dim tPrevSegType, tNextLoopName As %String = ""
	#dim keyfields,data,segname,segtype,currsegname As %String
	#dim tFirstSegWType As %Integer = 0
	#dim tLoopNum, tNextLoopNum, tMaxReps, subs As %Integer
	#dim tHasMatched,tStartOver As %Boolean = 0
	#dim tRequired,tMatched As Array of %String  = ""
	#dim type As %String =$P(pType,"(",1,$L(pType,"("))
	#dim len As %Integer = $L(type)
	#dim tIsUnion As %Boolean = ("union"=$E(type,len+1-$L("union"),len))
	#dim tGrpOpt As %Boolean = (pParentGrpOpt||$G(@pContentArray@("opt"),0))
	#dim tGrpSeg As %Integer = pCurrSeg
	#dim tSubSC As %Status
	#dim tSubOpt As %Boolean
	
	#; Find current Segment's Type Name
	If pCurrSeg>tSegments {
		Set currsegname=""
	} Else {
		Set seg=$$$vaSegLookthru(pCurrSeg,pId)
		If $$$vaIsOref(seg) {
			Set tSegObj=..%maps("orefs",pCurrSeg)
			Set data=$E(tSegObj.Separators,1,3)_tSegObj.GetValueAt()
		} Else {
			Set data=$G($$$vaSegmentGbl($P(seg,"|")))
		}
		Set currsegname=$$$vaDataSegName(data)
	}
	
	For i=1:1:$G(@pContentArray) { ; loop over sub-elements of the root schema element at this level
		Set tStartOver = 0
		Set pIContents=$Name(@pContentArray@(i))
		Set opt=$G(@pIContents@("opt"),0)
		Set type=@pIContents@("type")
		If '..useValSchema {
			Set segtype=$S(type[":":$P(type,":",3),1:"-"_type)
		} Else {
			Set segtype=$P(type,":",4)
		}
		Set isrep=$P(segtype,"(",2), tMaxReps=$Case(isrep, ")":0, "":1, :+isrep), isrep=(""'=isrep), tRequiredReps='opt
		Set segtype=$P(segtype,"(")  Set:..useValSchema segtype=$P(segtype,"-") ; strip off parens and ordinal

		Set keyfields=$P(segtype,"!",2), segtype=$P(segtype,"!") ; split off key fields indicator
		Set segname=$P(@pIContents@("name"),"(")
		Set subs=$G(@pIContents,0)
		If subs {
			Set tLoopNum = +$S(..useValSchema:segname,1:$E(segname,5,*)) ; remove initial "Loop" for new-style schemas
			If (tLoopNum'=tPrevSegType) {
				#; check for missing required from previous seg or loop name
				Quit:(..CheckForMissingRequiredReps(.tRequired,.tMatched,pPath,pCurrSeg,currsegname,.tSC,pKeepParsingAfterError) && 'pKeepParsingAfterError)
				#; take note of where first loop with this name occurs, so we can circle back to here later
				Set tFirstSegWType = i
				Set tHasMatched = 0
			} ElseIf tHasMatched && (tLoopNum#100) {
				If $G(@pContentArray@(i,1,"type"),"!")'["!" {
					#; multiple subloops, but this one has no keyfields. check other subloops before falling back to this one
					Set i = (tFirstSegWType - 1) ; so that we will start processing at tFirstSegWType after the For loop increments i
					Set tHasMatched = 0
					Continue
				}
			}
			Set:tRequiredReps tRequired(segname) = tRequiredReps
			Set tPrevSegType = tLoopNum
		} Else {
			If (segtype'=tPrevSegType) {
				#; check for missing required from previous seg or loop name
				Quit:(..CheckForMissingRequiredReps(.tRequired,.tMatched,pPath,pCurrSeg,currsegname,.tSC,pKeepParsingAfterError) && 'pKeepParsingAfterError)
				#; take note of where the first segment with this name occurs, so we can circle back to here later
				Set tFirstSegWType = i
				Set tHasMatched = 0
			} ElseIf (""=keyfields) && tHasMatched {
				#; start over checking for a match from the first segment with this name before falling back to this one
				Set i = (tFirstSegWType - 1) ; so that we will start processing at tFirstSegWType after the For loop increments i
				Set tHasMatched = 0
				Continue
			}
			If tRequiredReps {
				Set tRequired(segname) = tRequiredReps
			} ElseIf (i=1)&&'tIsUnion {
				Set tRequired(segname) = 1
			}
			Set tPrevSegType = segtype
		}
				
		Set tISeg=pCurrSeg
		#; if we have already matched for this same segment, need to take that into account
		Set rep = $S($D(tMatched(segname),tCount)#2:tCount+1,1:1)
		For rep=rep:1 { ; loop for repetitions of the current schema sub-element
			Quit:(tMaxReps && (rep>tMaxReps))
			Set tBaseSeg=pCurrSeg
			Set tIPath=$S(""=pPath:"",1:pPath_".")_segname_$S(isrep:"("_rep_")",1:"")

			If subs {
				Set tSubOpt = (tGrpOpt || (rep>tRequiredReps))
				Set tSubSC=..buildRuntimePathFromIndex(pId,tIPath,pIContents,type,.pCurrSeg,tSubOpt,tSC,pKeepParsingAfterError,pReportMissingLoopAsFirstSeg)
				If (tBaseSeg'=pCurrSeg) {
					Set tSC = tSubSC
					Set tHasMatched = 1
					Set tMatched(segname)=rep
					#; Find new current Segment's Type Name. pCurrSeg has already been incremented before method return
					If pCurrSeg <= tSegments {
						Set seg=$$$vaSegLookthru(pCurrSeg,pId)
						If $$$vaIsOref(seg) {
							Set tSegObj=..%maps("orefs",pCurrSeg)
							Set data=$E(tSegObj.Separators,1,3)_tSegObj.GetValueAt()
						} Else {
							Set data=$G($$$vaSegmentGbl($P(seg,"|")))
						}
						Set currsegname=$$$vaDataSegName(data)
						
					} Else {
						Set currsegname = ""
					}
					#; Check if another repetition of this subloop could follow and rewind to first subloop of this name if we're at the last one
					If (tLoopNum#100) && (tFirstSegWType'=i) {
						Set tNextLoopName = $G(@pContentArray@(i+1,"name"))
						Set tNextLoopNum = +$S(..useValSchema:$P(tNextLoopName,"("),1:$E($P(tNextLoopName,"("),5,*)) ; remove initial "Loop" for new-style schemas
						Set:(tNextLoopNum'=tLoopNum) tStartOver = 1
					}
				} ElseIf ('tSubOpt && pReportMissingLoopAsFirstSeg) {
					Kill tPriorErrCount
					Kill tLoopErrs
					Do $System.Status.DecomposeStatus(tSC,.tPriorErrCount)
					Set tFirstLoopErr = 1 + $G(tPriorErrCount)
					Do $System.Status.DecomposeStatus(tSubSC,.tLoopErrs)
					If $D(tLoopErrs(tFirstLoopErr))&&($G(tLoopErrs(tFirstLoopErr,"code"))="<EnsEDI>ErrMapRequired")&&$D(tLoopErrs(tFirstLoopErr,"param",1),tFirstMissing) {
						Set tRequired(segname,tFirstMissing)=tRequiredReps
					}
				}
			} Else {
				#; Check for segment type match
				If (segtype=currsegname) && ((""=keyfields) || ..KeyfieldsMatch(keyfields,data)) {
					#; Set seg address/schema at path into runtimePath
					Set schema=$P($P(type,":",2,$S(..useValSchema:4,1:3)),"(")
					Set:schema["!" schema=$P(schema,"!")_$S(..useValSchema:"-"_$P(schema,"-",2,*),1:"")
					Set seg=$$$vaSegLookthru(pCurrSeg,pId)
					If $$$vaIsOref(seg) {
						Set $$$vaM("runtimePath",tIPath)="@"_pCurrSeg
						Set ..%maps("orefs",pCurrSeg).DocType=schema
					} Else {
						Set seg=$P(seg,"|")_"|"_schema
						Set $$$vaM("runtimeIndex",pCurrSeg)=seg
						Set $$$vaM("runtimePath",tIPath)=seg
					}
					Set $$$vaM("bidirectionalLink",pCurrSeg)=tIPath, $$$vaM("bidirectionalLink",tIPath)=pCurrSeg
					Set %seglastmatch=pCurrSeg, %pathlastmatch=tIPath
					Set tMatched(segname)=rep
					Set tHasMatched = 1
					
					#; Find new current segment's Type Name
					If pCurrSeg < tSegments {
						Set pCurrSeg = (pCurrSeg + 1)
						Set seg=$$$vaSegLookthru(pCurrSeg,pId)
						If $$$vaIsOref(seg) {
							Set tSegObj=..%maps("orefs",pCurrSeg)
							Set data=$E(tSegObj.Separators,1,3)_tSegObj.GetValueAt()
						} Else {
							Set data=$G($$$vaSegmentGbl($P(seg,"|")))
						}
						Set currsegname=$$$vaDataSegName(data)
						
						#; Don't want to quit out of the repeat loop unless we've hit the end of this segtype in the schema, but the document's next segment is still of this type
						If ((segtype=currsegname) && (""=keyfields) && (tFirstSegWType'=i)) {
							Set tStartOver = 1
							Quit
						}
					} Else {
						If pCurrSeg = tSegments {
							Set pCurrSeg = (pCurrSeg + 1)
						}
						Set currsegname = ""
					}
				}
			}
			If tBaseSeg=pCurrSeg { ; found no match in repeat loop
				Set:((rep<tRequiredReps)&&'tIsUnion&&'tGrpOpt&&(segtype'=currsegname)) tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsEDIErrMapSegCount,tRequiredReps,tIPath,pCurrSeg_$S(""=$G(currsegname):"",1:" ("_currsegname_")")))
				Quit
			} Else {
				Set tGrpOpt=0
				Quit:pCurrSeg>tSegments
			}
		}
		If tStartOver {
			Set i = (tFirstSegWType - 1) ; so that we will start processing at tFirstSegWType
			Set tHasMatched = 0
			Continue
		}
		Quit:$$$ISERR(tSC)&&'pKeepParsingAfterError
		If tISeg=pCurrSeg { ; found no match at element i
			#; if this is the first segment in a loop, then the loop is missing (first seg is always required). otherwise keep parsing
			Quit:('tIsUnion && (i=1))			
		} Else {
			Set tGrpOpt=0
			Quit:tIsUnion
		}
	}

	If 'tGrpOpt {
		If tIsUnion {
			If tGrpSeg=pCurrSeg { ; found no match in any union element
				Set:'tGrpOpt tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsEDIErrMapRequiredUnion,pPath,pCurrSeg_$S(""=$G(currsegname):"",1:" ("_currsegname_")")))
			}
		} Else {
			Do ..CheckForMissingRequiredReps(.tRequired,.tMatched,pPath,pCurrSeg,currsegname,.tSC,pKeepParsingAfterError)
		}
	}

	Quit tSC
}

Method CheckForMissingRequiredReps(ByRef pRequired, ByRef pMatched, pPath As %String, pCurrSeg As %Integer, pCurrSegName As %String = "", pSC As %Status, pKeepParsingAfterError As %Boolean) As %Boolean [ Internal ]
{
	#dim tErrored As %Boolean = 0
	#dim tReqName,tMissing As %String = ""
	#dim tReqCount,tMatchCount As %Integer
	
	If $D(pRequired) {
		For {
			Set tReqName = $O(pRequired(tReqName),1,tReqCount)	Quit:tReqName=""
			If ""'=$O(pRequired(tReqName,"")) {
				Set tMissing = $O(pRequired(tReqName,""),1,tReqCount)
			} Else {
				Set tMissing = $S(""=pPath:"",1:pPath_".")_tReqName
			}
			If $D(pMatched(tReqName),tMatchCount)#2 {
				#; if the required segment/subloop was found, don't error
				If (tReqCount - tMatchCount) < 1 {
					Kill pRequired(tReqName)
					Continue
				}
			}
			Continue:'tReqCount
			Set pSC=$$$ADDSC(pSC,$$$ERROR($$$EnsEDIErrMapRequired,tMissing,pCurrSeg_$S(""'=pCurrSegName:" ("_pCurrSegName_")",1:"")))
			Kill pRequired(tReqName) ; so only report about this segment/subloop once
			Set tErrored = 1
			Quit:'pKeepParsingAfterError
		}
	}
	
	Quit tErrored
}

/// Returns true if any of the keyfield values match the data
Method KeyfieldsMatch(pKeyField, pData) [ Private ]
{
	Set tFld=$P(pKeyField,"=")  Quit:'tFld 0
	Set tComp = +$P(tFld,".",2,*)
	Set tFld = $P(tFld,".")
	Set tMatch=0, nVals=$L(pKeyField,"=")-1, tVals=$P(pKeyField,"=",2,1+nVals), tTarg=$$$SEGELEM(pData,tFld)
	Set:tComp>0 tTarg = $P(tTarg,$$$COMSEP(pData),tComp)
	For iVal=1:1:nVals { Set tVal=$P(tVals,"=",iVal)
		If tVal=tTarg Set tMatch=1  Quit
	}
	Quit tMatch
}

Method DumpMaps() As %Status
{
	Set DocType=..DocType w ! zw DocType
	w !,"DocTypeCategory,DocTypeName="_..DocTypeCategory_","_..DocTypeName
	Set BuildMapStatus=..BuildMapStatus w ! zw BuildMapStatus
	If ""'=..DocTypeCategory&&(""'=..DocTypeName) {
		If '..useValSchema {
			Merge mapSchemaPath=$$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"map") w ! zw mapSchemaPath
			Merge mapContentArray=$$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"array") w ! zw mapContentArray
		} Else {
			Merge mapSchemaPath=$$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"map") w ! zw mapSchemaPath
			Merge mapContentArray=$$$vaVSchemaGbl(..DocTypeCategory,..DocTypeName,"array") w ! zw mapContentArray
		}
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
##class(EnsLib.EDI.X12.Schema).GetContentArray(.pContents,.pMode,.pDocType,.pLevel,.pIncludeBase)
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
Query EnumerateDocTypes(Category As %String = "", IncludeBase As %Boolean = 0, IncludeInterchangeTree As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Type:%String")
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Category As %String, IncludeBase As %Boolean, IncludeInterchangeTree As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.X12.Schema).DocStructuresExecute(.qHandle,.Category,.IncludeBase,.IncludeInterchangeTree)
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	Set tSC=##class(EnsLib.EDI.X12.Schema).DocStructuresFetch(.qHandle,.Row,.AtEnd)
	Set:""'=$G(Row) Row=$LB($LG(Row))
	Quit tSC
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateDocTypesFetch ]
{
##class(EnsLib.EDI.X12.Schema).DocStructuresClose(.qHandle)
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
##class(EnsLib.EDI.X12.Schema).TypeCategoriesExecute(.qHandle,Standard)
}

ClassMethod EnumerateTypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateTypeCategoriesExecute ]
{
	Set tSC=##class(EnsLib.EDI.X12.Schema).TypeCategoriesFetch(.qHandle,.Row,.AtEnd)
	Quit tSC
}

ClassMethod EnumerateTypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateTypeCategoriesFetch ]
{
##class(EnsLib.EDI.X12.Schema).TypeCategoriesClose(.qHandle)
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

ClassMethod EnumerateSegTypesExecute(ByRef qHandle As %Binary, Category As %String, Level As %String, IncludeBase As %Boolean) As %Status [ CodeMode = expression ]
{
##class(EnsLib.EDI.X12.Schema).SegTypesExecute(.qHandle,.Category,.Level,.IncludeBase)
}

ClassMethod EnumerateSegTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer) As %Status [ PlaceAfter = EnumerateSegTypesExecute ]
{
	Set tSC=##class(EnsLib.EDI.X12.Schema).SegTypesFetch(.qHandle,.Row,.AtEnd)
	Quit tSC
}

ClassMethod EnumerateSegTypesClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = EnumerateSegTypesFetch ]
{
##class(EnsLib.EDI.X12.Schema).SegTypesClose(.qHandle)
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pContentArrayName As %String, pArrayPos As %String) As %String [ CodeMode = expression ]
{
##class(EnsLib.EDI.X12.Schema).GetAlias(pContentArrayName,pArrayPos)
}

ClassMethod checkDocType(ByRef pDocType As %String) As %Status
{
	Set tStructCategory=$P(pDocType,":",1), tStructName=$P(pDocType,":",2)
	Set:$Case($E(pDocType),"+":1,"-":1,:0) $E(tStructCategory,1)=""
	If (""'=tStructCategory)&&(""'=tStructName) {
		If $Case($E(pDocType), "+":0, "-":1, :$D($$$vaVSchemaGbl(tStructCategory))&&('$D($$$vaSchemaGbl(tStructCategory))||$G(^(tStructCategory,"useOld")))) {
			Quit:""'=$G($$$vaSchemaGbl(tStructCategory,"DS",tStructName)) $$$OK
		} Else {
			Quit:""'=$G($$$vaVSchemaGbl(tStructCategory,tStructName)) $$$OK
		}
	}
	Quit $$$ERROR($$$EnsEDIErrMapDocType,"X12",pDocType)
}

/// This method is for use from the RawContent property's SQL Compute invocation
ClassMethod getSegsAsString(pId As %String, pMaxLen As %Integer = 10000, pStartOffset As %Integer = 1) As %String
{
	#; Use delimiters from first segment, translate all subsequent delims to those
	Set str=""  For index=1:1:+$G($$$vaExtentGbl(pId,"segs")) { Set data=$$$vaSegmentGbl($$$vaExtentGbl(pId,"segs",index))
		If index=1 {
			Set tSeparators=$E(data,1,3)
			Set tSegTerminator=$G($$$vaSegmentGbl($$$vaExtentGbl(pId,"segs",index),"term"),$$$X12DefSegTerminator)
		}
		Set:tSeparators'=$E(data,1,3) data=##class(EnsLib.EDI.X12.Segment).replaceSeparators(data, tSeparators)
		If pStartOffset>1 {
			If pStartOffset>($L(data)-3+$L(tSegTerminator)) { Set pStartOffset=pStartOffset-($L(data)-3+$L(tSegTerminator))  Continue }
			Else { Set pStartOffset=1, data=$E(data,pStartOffset,*) }
		}
		If pMaxLen-$L(str)>=($L(data)-3+$L(tSegTerminator)) { Set str=str_$E(data,4,*)_tSegTerminator }
		Else { Set str=str_$E(data_tSegTerminator,4,3+pMaxLen-$L(str)) }
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

/// Output the entire document contents to a string.
/// If <param>pSeparators</param> is specified and is different from the original separators for the document, output the document using the new set of separators.
/// Output <param>pIncomplete</param> will be set to 1 if the length of the document is greater than the maximum string length (Note that the limit is approximately 3.6MB.)
Method OutputToString(pSeparators As %String, Output pStatus As %Status, pIOFormatClassname As %String, Output pIsIncomplete As %Boolean) As %String
{
	Set tIOStream=##Class(%IO.StringStream).%New()
	Set pStatus = ..OutputToIOStream(tIOStream, .pSeparators, , .pIOFormatClassname,.pIsIncomplete)
	Do tIOStream.Rewind()
	Quit tIOStream.Read($$$MaxLocalLength)
}

Method OutputToIOStream(pIOStream As %IO.I.CharacterStream, pSeparators As %String, pFlush As %Boolean = 1, pIOFormatClassname As %String = "", pIsIncomplete As %Boolean) As %Status
{
	Set tSC=$$$OK
	Set pIsIncomplete = 0
	Set tSeparators=$S(""=$G(pSeparators):..Separators, 1:pSeparators)  Set:""=tSeparators tSeparators=$$$X12DefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator
	If ""=pIOFormatClassname || '$classmethod(pIOFormatClassname,"OutputDocument",$this,.tSC,pIOStream,tSeparators) {
		Do:'$D($$$vaM("runtimeIndex"))&&$D($$$vaM("runtimePath")) ..buildRuntimeIndexFromPath()
		For i=1:1:$G($$$vaM("runtimeIndex")) { Set tSeg=..getSegmentByIndex(i)
			If 'tSeg.IsChildHolder(.tRef) {
				Set tSC=tSeg.OutputToIOStream(pIOStream, tSeparators, i, $G($$$vaM("bidirectionalLink",i),i), $this, pIOFormatClassname, .tIsIncomplete)
				Set:tIsIncomplete pIsIncomplete=1
			} Else {
				Set tChild=$$$NULLOREF
				For {
					Set tChild=..NextChild(tChild,tRef)  Quit:tChild=$$$NULLOREF
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
	Set tSeparators=..Separators  Set:""=tSeparators tSeparators=$$$X12DefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator  Set $$$SEGTERM(tSeparators)=$ZStrip($$$SEGTERM(tSeparators),"*CW")
	Quit ..OutputToDevice(tSeparators,$S(..useValSchema:"EnsLib.EDI.X12.Util.FormatValHTML",1:"EnsLib.EDI.X12.Util.FormatHTML"))
}

/// Display Segments as HTML, using DocType info if available
Method OutputHTMLZen() As %Status
{
	Set tSC=$$$OK
	Set tSeparators=..Separators  Set:""=tSeparators tSeparators=$$$X12DefSeparators Set:""=$$$SEGTERM(tSeparators) tSeparators=tSeparators_..SegmentTerminator  Set $$$SEGTERM(tSeparators)=$ZStrip($$$SEGTERM(tSeparators),"*CW")
	Quit ..OutputToDevice(tSeparators,$S(..useValSchema:"EnsLib.EDI.X12.Util.FormatValHTMLZen",1:"EnsLib.EDI.X12.Util.FormatHTMLZen"))
}

ClassMethod ImportFromFile(pFilename As %String, pDocNum As %Integer = 1, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As EnsLib.EDI.X12.Document
{
	Set tIOStream=##Class(%IO.FileStream).%New()
	Do tIOStream.Open(pFilename,,5,,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	$$$sysTRACE("Opened file '"_pFilename_"'")
	Set tDoc=$$$NULLOREF  For i=1:1:pDocNum {
		If tIOStream.AtEnd Set pStatus=$$$ERROR($$$EnsErrGeneral,"Fewer than "_pDocNum_" documents in file "_pFilename)  Quit
		Set tDoc=..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)  Quit:$$$ISERR(pStatus)
	}
	Quit:$$$ISERR(pStatus) $$$NULLOREF
	Quit tDoc
}

ClassMethod ImportFromDevice(Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As EnsLib.EDI.X12.Document
{
	Set tDeviceStream=##class(%IO.DeviceStream).AttachNew(,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..ImportFromIOStream(tDeviceStream,.pStatus,.pConfigItem,.pIOFormatClassname,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)
}

ClassMethod ImportFromLibraryStream(pLibStream As %Stream.Object, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As EnsLib.EDI.X12.Document
{
	Set tIOStream=$S(pLibStream.%Extends("%IO.I.CharacterStream"):pLibStream,1:##Class(%IO.MetaCharacterStream).%New(pLibStream))
	Quit ..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)
}

ClassMethod ImportFromString(pString As %String, Output pStatus As %Status, ByRef pConfigItem As %String, pIOFormatClassname As %String, pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As EnsLib.EDI.X12.Document
{
	Set tIOStream=##Class(%IO.StringStream).%New(pString)
	Quit ..ImportFromIOStream(tIOStream,.pStatus,.pConfigItem,.pIOFormatClassname,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)
}

ClassMethod ImportFromIOStream(pIOStream As %IO.I.CharacterStream, Output pStatus As %Status = {$$$OK}, ByRef pConfigItem As %String = "", pIOFormatClassname As %String = "", pDefaultRepSep As %String = "", pDefaultCompSep As %String = "", pDefaultSegTerminator As %String = "") As EnsLib.EDI.X12.Document
{
	Quit:""'=pIOFormatClassname&&$classmethod(pIOFormatClassname,"ImportDocument",.tDoc,.pStatus,pIOStream,pConfigItem) tDoc

	If ""'=pConfigItem {
		If $IsObject(pConfigItem) {
			Set tInst=pConfigItem
		} Else {
			Set tInst=##class(Ens.Host).GetShadowInstance(pConfigItem,.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
		}
		If 'tInst.%Extends("EnsLib.EDI.X12.Service.Standard") Set pStatus=$$$ERROR($$$EnsErrGeneral,"Config Item class "_$classname(tInst)_" found For "_pConfigItem_" is not not an EDI document Service")  Quit $$$NULLOREF
	} Else {
		Set tInst=##class(Ens.Host).GetShadowInstance("class ||EnsLib.EDI.X12.Service.FileService",.pStatus)  Quit:$$$ISERR(pStatus) $$$NULLOREF
	}
	#; Get a new parser based on a Service; OnInit not called for shadow service instances
	Set tInst.%ForwardBatchWhole=2 ; don't let Service process the document; don't save&purge intermediate TransactionSet objects, leave them all in memory in the Document
	If '$IsObject(tInst.%Parser) Set tInst.%Parser=##class(EnsLib.EDI.X12.Parser).%New(tInst)  $$$ASSERT($IsObject(tInst.%Parser))
	Set tInst.%Parser.DefCharEncoding=tInst.DefCharEncoding
	Set:tInst.TolerateNewlines tInst.%Parser.Whitespace=$C(13,10,9,32)
	Set:""=tInst.ReplyMode tInst.ReplyMode="Never"

	If tInst'=pConfigItem { ; override some default properties if we created the shadow instance
		Set tInst.SearchTableClass=""
	}
	#; call the parser
	Set tInst.%Parser.Framing=tInst.Framing
	Set pStatus=tInst.%Parser.ParseFramedIOStream(pIOStream,.tDoc,,,pDefaultRepSep,pDefaultCompSep,pDefaultSegTerminator)
	Set pConfigItem=tInst ; allow repeated calls on the same parser
	Quit tDoc
}

/// Return the DocType of this document
Method resolveChildDocType() As %String
{
	Set tDocType=..DocType
	Set tParent=..Parent
	If (""=tDocType)&&($IsObject(tParent))&&(""'=tParent.DocTypeCategory) {
		#; Match with the DocType specified if any in DocSchemaCategory for the received Document's type name
		Set tNameFound=..Name
		Set tImplGuide=""
		If "ST"=..GetValueAt("1:0") {
			Set tImplGuide=..GetValueAt("1:3")
			Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
			If ""=tImplGuide {
				Set tImplGuide=tParent.GetValueAt("1:8")  // tParent is a Group
				Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				If ""=tImplGuide {
					Set tRef=..FindSegment("REF")
					Set:$IsObject(tRef) tImplGuide=tRef.GetValueAt(2)
					Set tImplGuide=$E(tImplGuide,$F(tImplGuide,"X")-1,*)
				}
			}
		}
		Set tPurpose=$S("BHT"=..GetValueAt("2:0"):..GetValueAt("2:2"),1:"")
		Set tDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(tParent.DocTypeCategory,tNameFound,.tSC,tImplGuide,tPurpose)
		Set:$$$ISERR(tSC) tDocType=""
	}
	Quit tDocType
}

Method CopyValues(pSource As EnsLib.EDI.X12.Document, pSourcePath As %String = "", pTargetPath As %String = "", pAction As %String = "set", pKey As %String = "", pEmptyFieldAsNull As %Boolean = 0, pIgnoreMissingSource As %Boolean = 0, pGenerateEmptySegments As %Boolean = 0) As %Status
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
					Set tSC=..SetValueAt(pSource.GetValueAt(pSourcePath,,.tSC2,pEmptyFieldAsNull,1),pTargetPath,pAction,pKey)
					Set:$$$ISERR(tSC2) tSC=$$$ADDSC(tSC,tSC2)
				} Else {
					Set tSourceValue = pSource.GetValueAt(pSourcePath,,.tSC,pEmptyFieldAsNull,1)	Quit:$$$ISERR(tSC) tSC
					Set tSC=..SetValueAt(tSourceValue,pTargetPath,pAction,pKey)
				}
			} Else { ; create clone segment object for id or oref
				Set tId=pSource.GetSegmentIdAt(pSourcePath,.tSC)  Quit:$$$ISERR(tSC) tSC
				If tId'="" {
					Set tSegObj=##class(EnsLib.EDI.X12.Segment).%New($LB(tId,1,"",1))
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
		Select ID,TimeCreated Into :%tID,:%tTime From EnsLib_EDI_X12.Document Order By ID)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		If $$$timeCmp(%tTime,%tDoNotDeleteDate)<0 {
			&sql(Delete From EnsLib_EDI_X12.Document Where ID=:%tID)
			Set pDeletedCount=pDeletedCount+%ROWCOUNT
		}
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE)
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	New %tID  Set %tID=$$$oidPrimary(oid)
	Set $$$vaDocsInDeletePPG(%tID)=""
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	For index=1:1:+$G($$$vaExtentGbl(%tID,"segs")) {
		Set segid=$$$vaExtentGbl(%tID,"segs",index)
		Kill $$$vaSegmentGbl(segid,0,%tID)
		If '$D($$$vaSegmentGbl(segid,0))&&($G($$$vaOpenSegmentPPG(segid),0)<=0) {
			Kill $$$vaSegmentGbl(segid)
			Kill $$$vaOpenSegmentPPG(segid)
		}
	}
	&sql(Delete From EnsLib_EDI_X12.Document Where OriginalDocId=:%tID)
	If '$D($$$vaDocsInDeletePPG(%tID,"ChildInitiated")) {	; avoid getting stuck in recursive loop
		&sql(Delete From EnsLib_EDI_X12.Document Where ParentId=:%tID Or ParentId %StartsWith :%tID||':')
	}
	#; Check to see if this document is a Transaction Set which was sent with "Individual" Batch Handling
	#; If so, the parent Group and Interchange were persisted, but have no associated Message Header
	#; If this is the last remaining child, then the Group and Interchange should be deleted too
	#; No need to do this if the call to delete this document was triggered by the deletion of the parent
	&sql(Select ParentId, HandledIndividually into :tParentID, :tIndiv From EnsLib_EDI_X12.Document Where ID=:%tID)
	If $G(tIndiv) && ($G(tParentID)'="") && '$D($$$vaDocsInDeletePPG($P(tParentID,":"))) {
		Set tParentID = $P(tParentID,":")
		Set $$$vaDocsInDeletePPG(tParentID,"ChildInitiated")=""
		&sql(Delete From EnsLib_EDI_X12.Document Where %ID=:tParentID AND ChildCount=1)
		Kill $$$vaDocsInDeletePPG(tParentID)
	}
	Kill $$$vaDocsInDeletePPG(%tID)
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New %tID,index,segid,tIndiv,tParentID  Set %tID={%%ID}
	Set $$$vaDocsInDeletePPG(%tID)=""
	Do ##class(Ens.SearchTableBase).RemoveSearchTableEntries($classname(),%tID,1)
	For index=1:1:+$G($$$vaExtentGbl(%tID,"segs")) {
		Set segid=$$$vaExtentGbl(%tID,"segs",index)
		Kill $$$vaSegmentGbl(segid,0,%tID)
		If '$D($$$vaSegmentGbl(segid,0))&&($G($$$vaOpenSegmentPPG(segid),0)<=0) {
			Kill $$$vaSegmentGbl(segid)
			Kill $$$vaOpenSegmentPPG(segid)
		}
	}
	&sql(Delete From EnsLib_EDI_X12.Document Where OriginalDocId=:%tID)
	If '$D($$$vaDocsInDeletePPG(%tID,"ChildInitiated")) {	; avoid getting stuck in recursive loop
		&sql(Delete From EnsLib_EDI_X12.Document Where ParentId=:%tID Or ParentId %StartsWith :%tID||':')
	}
	#; Check to see if this document is a Transaction Set which was sent with "Individual" Batch Handling
	#; If so, the parent Group and Interchange were persisted, but have no associated Message Header
	#; If this is the last remaining child, then the Group and Interchange should be deleted too
	#; No need to do this if the call to delete this document was triggered by the deletion of the parent
	&sql(Select ParentId, HandledIndividually into :tParentID, :tIndiv From EnsLib_EDI_X12.Document Where ID=:%tID)
	If $G(tIndiv) && ($G(tParentID)'="") && '$D($$$vaDocsInDeletePPG($P(tParentID,":"))) {
		Set tParentID = $P(tParentID,":")
		Set $$$vaDocsInDeletePPG(tParentID,"ChildInitiated")=""
		&sql(Delete From EnsLib_EDI_X12.Document Where %ID=:tParentID AND ChildCount=1)
		Kill $$$vaDocsInDeletePPG(tParentID)
	}
	Kill $$$vaDocsInDeletePPG(%tID)
	Quit
}

ClassMethod KillGlobals(Output pDeletedCount, pKeepExtentCount = 0, pDisplayLog = 1)
{
	Set pDeletedCount=..TotalCount()
	Set tExtentCount=$G($$$vaExtentGbl)
	Write:pDisplayLog !,"Killing ",$classname()," extent ("_pDeletedCount_"/"_tExtentCount_")"
	Do ..%KillExtent()
	Set:pKeepExtentCount $$$vaExtentGbl=tExtentCount

	Do ##class(EnsLib.EDI.X12.SearchTable).%KillExtent()

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
	&sql(SELECT COUNT(*) INTO :tCount From EnsLib_EDI_X12.Document)
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
					Set $$$vaOpenSegmentPPG(segid)=($G($$$vaOpenSegmentPPG(segid),0)-1)
					If '$D($$$vaSegmentGbl(segid,0))&&($$$vaOpenSegmentPPG(segid)<=0) {
						Kill $$$vaSegmentGbl(segid)
						Kill $$$vaOpenSegmentPPG(segid)
					}
				}
			}
		} Else {
			Set path="" For { Set path=$O($$$vaM("runtimePath",path),1,seg) Quit:""=path
				If '$$$vaIsOref(seg) { Set segid=$P(seg,"|") }
				Else {
					Set tSegObj=..%maps("orefs",$E(seg,2,*))
					Set segid = tSegObj.ID
				}
				If ""'=segid {
					Set $$$vaOpenSegmentPPG(segid) = ($G($$$vaOpenSegmentPPG(segid),0) - 1)
					If '$D($$$vaSegmentGbl(segid,0))&&($$$vaOpenSegmentPPG(segid)<=0) {
						Kill $$$vaSegmentGbl(segid)
						Kill $$$vaOpenSegmentPPG(segid)
					}
				}
			}
		}
	}
	If 'tId||$D($$$vaExtentGbl(tId)) $$$vaMkill  ; ..%maps can be undefined when aborting %OpenId() of nonexistent Id
	Quit $$$OK
}

/// See <class>Ens.X12.FunctionSet</class> for updated helper class methods
Method AddFunctionalGroup(pGS As EnsLib.EDI.X12.Segment, Output pGroupSegIndex As %Integer = "") As %Status
{
	Quit:"Interchange"'=..Name $$$ERROR($$$EnsErrGeneral,"Can only add FunctionalGroups to an Interchange document, not a "_..Name)
	Set tSC=..AppendSegment(pGS) Quit:$$$ISERR(tSC) tSC
	Set tDataElementSeparator=$$$ELESEP(..Separators)
	Set tPlaceholder=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(..Separators,1,3)_"TransactionSetDocsRef"_tDataElementSeparator_(..SegCount+1)_tDataElementSeparator))
	Set tSC=..AppendSegment(tPlaceholder) Quit:$$$ISERR(tSC) tSC
	Set pGroupSegIndex=..SegCount
	Set tGE=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(..Separators,1,3)_"GE"_tDataElementSeparator_0_tDataElementSeparator_pGS.GetValueAt(6)))
	Set tSC=..AppendSegment(tGE) Quit:$$$ISERR(tSC) tSC
	Quit $$$OK
}

/// Add a TransactionSet to the Interchange. Add it to a group given the segment index of the placeholder segment between GS and GE segments.
/// See <class>Ens.X12.FunctionSet</class> for updated helper class methods<br>
Method AddTransactionSet(pTxnSet As EnsLib.EDI.X12.Document, pGroupSegIndex As %Integer, pAttachment As %Stream.Object = {$$$NULLOREF}) As %Status
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

/// See <class>Ens.X12.FunctionSet</class> for updated helper class methods
Method AddEndSegment() As %Status
{
	Set tDataElementSeparator=$$$ELESEP(..Separators)
	If "Interchange"=..Name {
		Set tNumGroups=..ChildCount
		Set tIEA=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(..Separators,1,3)_"IEA"_tDataElementSeparator_tNumGroups_tDataElementSeparator_..GetValueAt("1:13")))
		Set tSC=..AppendSegment(tIEA) Quit:$$$ISERR(tSC) tSC
	} ElseIf "Group"=..Name {
		Set tNumSets=..ChildCount
		Set tGE=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(..Separators,1,3)_"GE"_tDataElementSeparator_tNumSets_tDataElementSeparator_..GetValueAt("1:6")))
		Set tSC=..AppendSegment(tGE) Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSE=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",$E(..Separators,1,3)_"SE"_tDataElementSeparator_(..SegCount+1)_tDataElementSeparator_..GetValueAt("1:2")))
		Set tSC=..AppendSegment(tSE) Quit:$$$ISERR(tSC) tSC
	}
	Quit $$$OK
}

Method NewReplyDocument(pDocType As %String = "", pLocalApplicationID As %String, Output pSC As %Status) As EnsLib.EDI.X12.Document
{
	Kill %objlasterror
	Set pSC=$$$OK, tReplyDoc=..%New($LB("",..Separators))
	If '$IsObject(tReplyDoc) Set pSC=$$$ERROR($$$EnsErrGeneral,"Failed to instantiate reply document for doc "_..%Id()_"; status = "_$G(%objlasterror,$$$OK))  Quit $$$NULLOREF
	Set:""=pDocType pDocType=..DocType
	If "Interchange"=..Name {
		Set tISA=..GetSegmentAt(1)
		If $IsObject(tISA) {
			Set tReplyISA=..NewReplyHeaderSegs(tISA,pLocalApplicationID,.tReplyIEA,.pSC)
			Do:$IsObject(tReplyISA) tReplyDoc.AppendSegment(tReplyISA)
			Do:$IsObject(tReplyIEA) tReplyDoc.AppendSegment(tReplyIEA)
		}
	} ElseIf "Group"=..Name {
		Set tGS=..GetSegmentAt(1)
		If $IsObject(tGS) {
			Set tReplyGS=..NewReplyGroupSegs(tGS,pLocalApplicationID,,,.tReplyGE,.pSC)
			Do:$IsObject(tReplyGS) tReplyDoc.AppendSegment(tReplyGS)
			Do:$IsObject(tReplyGE) tReplyDoc.AppendSegment(tReplyGE)
		}
	} Else {
		Set tST=..GetSegmentAt(1)
		If $IsObject(tST) {
			Set tReplyAK2=..NewDocumentReply997Segs(tST,,.tReplyAK5,.pSC)
			Do:$IsObject(tReplyAK2) tReplyDoc.AppendSegment(tReplyAK2)
			Do:$IsObject(tReplyAK5) tReplyDoc.AppendSegment(tReplyAK5)
		}
	}
	Do tReplyDoc.PokeDocType(pDocType)
	Quit tReplyDoc
}

/// Create new ISA/IEA interchange segments as a reply corresponding to an original ISA segment
ClassMethod NewReplyHeaderSegs(pOriginalISASeg As EnsLib.EDI.X12.Segment, pLocalApplicationID As %String = "", Output pReplyIEASeg As EnsLib.EDI.X12.Segment, Output pSC As %Status) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK, tTimeH=$H, pReplyIEASeg=$$$NULLOREF
	Do {
		#; Generate a new segment from scratch instead of cloning so that we can make sure we aren't creating a badly formed ISA in response to a badly formed ISA
		Set tReplyISASeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalISASeg.Separators))  If '$IsObject(tReplyISASeg) Set tSC=%objlasterror  Quit
		Set tReplyISASeg.ISASegmentTerminator = pOriginalISASeg.ISASegmentTerminator
		Set tSC=tReplyISASeg.SetValueAt("ISA",0)  Quit:$$$ISERR(tSC)
		
		#; Copy some values from the original
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAAuthorizationInformationQual),2), $$$ISAAuthorizationInformationQual)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAAuthorizationInformation),10), $$$ISAAuthorizationInformation)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISASecurityInformationQualifier),2), $$$ISASecurityInformationQualifier)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISASecurityInformation),10), $$$ISASecurityInformation)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAUsageIndicator),1), $$$ISAUsageIndicator)

		Set tControlVersionNum = pOriginalISASeg.GetValueAt($$$ISAInterchangeControlVersionNum)
		If (tControlVersionNum="") && (pOriginalISASeg.DocTypeCategory'="") {
			Set tControlVersionNum = $E($P($G($$$vaVSchemaGbl(pOriginalISASeg.DocTypeCategory,"Interchange")),"|",2),1,5)
			If (""=tControlVersionNum) || (tControlVersionNum '? 5N) {
				Set tControlVersionNum = $E($P($G($$$vaVSchemaGbl(pOriginalISASeg.DocTypeCategory)),"|",2),1,5)
			}
		}
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(tControlVersionNum,5), $$$ISAInterchangeControlVersionNum)
		
		#; Determine the ID that we should use as Sender in this reply
		#; - support indirection and escaping to allow @ to represent the caller's ID value
		Set tRcvrID=$P(pLocalApplicationID,":",1), tRcvrQual=$P(pLocalApplicationID,":",2)
		If pLocalApplicationID["@" {
			Set pos=1 For { Set pos=$F(tRcvrID,"\",pos)  Quit:'pos  Set c=$E(tRcvrID,pos)
				Set tNew=$Case(c, "@":$C(0), "\":"\", :"\"_c), $E(tRcvrID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrID=$Replace($Replace(tRcvrID,"@",pOriginalISASeg.GetValueAt($$$ISAInterchangeReceiverID)),$C(0),"@")
			Set pos=1 For { Set pos=$F(tRcvrQual,"\",pos)  Quit:'pos  Set c=$E(tRcvrQual,pos)
				Set tNew=$Case(c, "@":$C(0), "\":"\", :"\"_c), $E(tRcvrQual,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrQual=$Replace($Replace(tRcvrQual,"@",pOriginalISASeg.GetValueAt($$$ISAInterchangeIDQualifier2)),$C(0),"@")
		}
		#; Set the Receiver ID for this reply as the Sender ID that came to us
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAInterchangeSenderID),15),$$$ISAInterchangeReceiverID)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAInterchangeIDQualifier),2),$$$ISAInterchangeIDQualifier2)  Quit:$$$ISERR(tSC)
		
		#; Set the Sender ID for this reply as the replyer ID we just determined based on the Receiver ID that came to us
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(tRcvrID,15),$$$ISAInterchangeSenderID)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(tRcvrQual,2),$$$ISAInterchangeIDQualifier)  Quit:$$$ISERR(tSC)
		
		#; Date & Time
		Set tSC=tReplyISASeg.SetValueAt($E($ZDate(tTimeH,8),3,8),$$$ISAInterchangeDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($TR($ZTime($P(tTimeH,",",2),2),":"),$$$ISAInterchangeTime) 
		
		#; Get a new interchange control number for this reply interchange
		Set tInterchangeControlNumber=..NewControlID("I")
		Set tSC=tReplyISASeg.SetValueAt($$$NUM(tInterchangeControlNumber,9),$$$ISAInterchangeControlNumber)  Quit:$$$ISERR(tSC)
		
		#; Request no TA1 response for this reply interchange
		Set tSC=tReplyISASeg.SetValueAt(0,$$$ISAAcknowledgmentRequested)  Quit:$$$ISERR(tSC)
		
		#; Use an appropriate Interchange Control Standards Identifier if control version is such that ISA11 should not be repetition separator
		If (+tControlVersionNum>0) && (tControlVersionNum < 403) {
			Set tControlStandardsI = pOriginalISASeg.GetValueAt($$$ISAInterchangeControlStandardsI)
			Set tSC = tReplyISASeg.SetValueAt($$$PAD(tControlStandardsI,1),$$$ISAInterchangeControlStandardsI)	Quit:$$$ISERR(tSC)
		} Else {
			Set tSC = tReplyISASeg.SetValueAt(pOriginalISASeg.RS,$$$ISARepetitionSeparator)	Quit:$$$ISERR(tSC)
		}
		
		#; Component separator
		Set tSC = tReplyISASeg.SetValueAt(pOriginalISASeg.CS,$$$ISAComponentElementSeparator)	Quit:$$$ISERR(tSC)

		Set pReplyIEASeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalISASeg.Separators))  If '$IsObject(pReplyIEASeg) Set tSC=%objlasterror  Quit
		Set tSC=pReplyIEASeg.SetValueAt("IEA",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyIEASeg.SetValueAt(0,$$$IEANumberofIncludedFunctionalGr)	Quit:$$$ISERR(tSC) ; initialize to 0
		Set tSC=pReplyIEASeg.SetValueAt($$$NUM(tInterchangeControlNumber,9),$$$IEAInterchangeControlNumber)  Quit:$$$ISERR(tSC)
	} While 0
	Set pSC=tSC
	Quit tReplyISASeg
}

/// Create new ISA/IEA interchange segments as a reply corresponding to an original ISA segment, while recognizing that the original segment may be incomplete
ClassMethod NewReplyHeaderSegsFromString(pOriginalISAString, pLocalApplicationID As %String = "", Output pReplyIEASeg As EnsLib.EDI.X12.Segment, Output pSC As %Status, pDefaultSeparators As %String = {$$$X12DefSeparators}, pDocType As %String) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK, tTimeH=$H, pReplyIEASeg=$$$NULLOREF
	Do {
		Set tDataElementSeparator=$E($ZStrip(pOriginalISAString,"<AN"))
		If ""=tDataElementSeparator {
			Set tDataElementSeparator = $$$ELESEP(pDefaultSeparators)
			Set tComponentSeparator = $$$COMSEP(pDefaultSeparators)
			Set tRepetitionSeparator = $$$REPSEP(pDefaultSeparators)
			Set tSeparators = pDefaultSeparators
		} Else {
			Set tComponentSeparator = $P(pOriginalISAString,tDataElementSeparator,$$$ISAComponentElementSeparator + 1)
			If (tComponentSeparator="") || (tComponentSeparator?1(1A,1N)) || (tComponentSeparator=tDataElementSeparator) {
				Set tComponentSeparator = $$$COMSEP(pDefaultSeparators)
				Set:tComponentSeparator=tDataElementSeparator tComponentSeparator = $C(17)
			}
			Set tRepetitionSeparator = $P(pOriginalISAString,tDataElementSeparator,$$$ISARepetitionSeparator + 1)
			If (tRepetitionSeparator="") || (tRepetitionSeparator?1(1A,1N)) || $Case(tRepetitionSeparator,tComponentSeparator:1,tDataElementSeparator:1,:0) {
				Set tRepetitionSeparator = $$$REPSEP(pDefaultSeparators)
				Set:$Case(tRepetitionSeparator,tComponentSeparator:1,tDataElementSeparator:1,:0) tRepetitionSeparator = $C(18)
			}
			Set tSeparators = tDataElementSeparator_tComponentSeparator_tRepetitionSeparator
		}
		Set tReplyISASeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",tSeparators))  If '$IsObject(tReplyISASeg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyISASeg.SetValueAt("ISA",0)  Quit:$$$ISERR(tSC)
		
		#; Copy some values from the original
		Set tSC = tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAAuthorizationInformationQual + 1),2), $$$ISAAuthorizationInformationQual)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAAuthorizationInformation + 1),10), $$$ISAAuthorizationInformation)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISASecurityInformationQualifier + 1),2), $$$ISASecurityInformationQualifier)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISASecurityInformation + 1),10), $$$ISASecurityInformation)
		Set tSC = tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAUsageIndicator + 1),1), $$$ISAUsageIndicator) ; using $$$PAD in this case to make sure not > 1 character
		
		Set tControlVersionNum = $P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeControlVersionNum + 1)
		If (tControlVersionNum="") && (pDocType'="") {
			If (pDocType[":") {
				Set tControlVersionNum = $E($P($G($$$vaVSchemaGbl($P(pDocType,":"),$P(pDocType,":",2))),"|",2),1,5)
			} Else {
				Set tControlVersionNum = $E($P($G($$$vaVSchemaGbl(pDocType)),"|",2),1,5)
			}
		}	
		Set tSC = tReplyISASeg.SetValueAt($$$PAD(tControlVersionNum,5), $$$ISAInterchangeControlVersionNum)

		#; Determine the ID that we should use as Sender in this reply
		#; - support indirection and escaping to allow @ to represent the caller's ID value
		Set tRcvrID=$P(pLocalApplicationID,":",1), tRcvrQual=$P(pLocalApplicationID,":",2)
		If pLocalApplicationID["@" {
			Set pos=1 For { Set pos=$F(tRcvrID,"\",pos)  Quit:'pos  Set c=$E(tRcvrID,pos)
				Set tNew=$Case(c, "@":$C(0), "\":"\", :"\"_c), $E(tRcvrID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrID=$Replace($Replace(tRcvrID,"@",$P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeReceiverID + 1)),$C(0),"@")
			Set pos=1 For { Set pos=$F(tRcvrQual,"\",pos)  Quit:'pos  Set c=$E(tRcvrQual,pos)
				Set tNew=$Case(c, "@":$C(0), "\":"\", :"\"_c), $E(tRcvrQual,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrQual=$Replace($Replace(tRcvrQual,"@",$P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeIDQualifier2 + 1)),$C(0),"@")
		}
		#; Set the Receiver ID for this reply as the Sender ID that came to us
		Set tSC=tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeSenderID + 1),15),$$$ISAInterchangeReceiverID)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeIDQualifier + 1),2),$$$ISAInterchangeIDQualifier2)  Quit:$$$ISERR(tSC)
		
		#; Set the Sender ID for this reply as the replyer ID we just determined based on the Receiver ID that came to us
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(tRcvrID,15),$$$ISAInterchangeSenderID)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($$$PAD(tRcvrQual,2),$$$ISAInterchangeIDQualifier)  Quit:$$$ISERR(tSC)
		
		#; Date & Time
		Set tSC=tReplyISASeg.SetValueAt($E($ZDate(tTimeH,8),3,8),$$$ISAInterchangeDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyISASeg.SetValueAt($TR($ZTime($P(tTimeH,",",2),2),":"),$$$ISAInterchangeTime) 
		
		#; Get a new interchange control number for this reply interchange
		Set tInterchangeControlNumber=..NewControlID("I")
		Set tSC=tReplyISASeg.SetValueAt($$$NUM(tInterchangeControlNumber,9),$$$ISAInterchangeControlNumber)  Quit:$$$ISERR(tSC)
		
		#; Request no TA1 response for this reply interchange
		Set tSC=tReplyISASeg.SetValueAt(0,$$$ISAAcknowledgmentRequested)  Quit:$$$ISERR(tSC)
		
		#; Repetition Character and ComponentSeparator
		#; Use an appropriate Interchange Control Standards Identifier if control version is such that ISA11 should not be repetition separator
		If (+tControlVersionNum>0) && (tControlVersionNum < 403) {
			Set tControlStandardsI = $E($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeControlStandardsI+1))
			Set:tControlStandardsI'?1(1A,1N) tControlStandardsI="U"
			Set tSC = tReplyISASeg.SetValueAt(tControlStandardsI,$$$ISAInterchangeControlStandardsI)	Quit:$$$ISERR(tSC)
		} Else {
			Set tSC = tReplyISASeg.SetValueAt(tRepetitionSeparator,$$$ISARepetitionSeparator)	Quit:$$$ISERR(tSC)
		}
		Set tSC=tReplyISASeg.SetValueAt(tComponentSeparator,$$$ISAComponentElementSeparator)	Quit:$$$ISERR(tSC)

		Set pReplyIEASeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",tSeparators))  If '$IsObject(pReplyIEASeg) Set tSC=%objlasterror  Quit
		Set tSC=pReplyIEASeg.SetValueAt("IEA",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyIEASeg.SetValueAt($$$NUM(tInterchangeControlNumber,9),$$$IEAInterchangeControlNumber)  Quit:$$$ISERR(tSC)
	} While 0
	Set pSC=tSC
	Quit tReplyISASeg
}

/// Create new GS/GE group segment as a reply corresponding to an original GS segment
ClassMethod NewReplyGroupSegs(pOriginalGSSeg As EnsLib.EDI.X12.Segment, pLocalApplicationID As %String = "", pFuncID As %String, pVersion As %String, Output pReplyGESeg As EnsLib.EDI.X12.Segment, Output pSC As %Status) As EnsLib.EDI.X12.Segment
{
	#; Retrieve values from the GS segment
	Set tReplyVersion = ##class(EnsLib.EDI.X12.Document).DetermineReplyVersion(pOriginalGSSeg.GetValueAt($$$GSVersionReleaseIndustryIdenti))
	If tReplyVersion=999 {
		 Set tVersionID = $Case(pOriginalGSSeg.GetValueAt($$$GSVersionReleaseIndustryIdenti),"00602":$$$999ImplementationRef6020,:$$$999ImplementationRef5010)
	} Else {
		Set tVersionID = $S(""'=$G(pVersion):pVersion,1:$P(pOriginalGSSeg.GetValueAt($$$GSVersionReleaseIndustryIdenti),"X")_"X")
	}
	Set tReceiverCode = pOriginalGSSeg.GetValueAt($$$GSApplicationReceiversCode)
	Set tSenderCode = pOriginalGSSeg.GetValueAt($$$GSApplicationSendersCode)
	#; Create GS and GE segments using these values
	Quit ..GetReplyGroupSegs(pLocalApplicationID,tReceiverCode,tSenderCode,tVersionID,.pReplyGESeg,.pSC,pOriginalGSSeg.Separators)
}

/// Create new 997 GS/GE group segment as a reply corresponding to an original ISA segment
ClassMethod New997OuterGroupSegs(pOriginalISASeg As EnsLib.EDI.X12.Segment, pLocalApplicationID As %String = "", pFuncID As %String, pVersion As %String, Output pReplyGESeg As EnsLib.EDI.X12.Segment, Output pSC As %Status) As EnsLib.EDI.X12.Segment
{
	#; Retrieve values from the ISA segment
	Set tVersionID = $S(""'=$G(pVersion):pVersion,1:pOriginalISASeg.GetValueAt($$$ISAInterchangeControlVersionNum)_"0X")
	Set tReceiverID = pOriginalISASeg.GetValueAt($$$ISAInterchangeReceiverID)
	Set tSendersID = pOriginalISASeg.GetValueAt($$$ISAInterchangeSenderID)
	#; Create GS and GE segments using these values
	Quit ..GetReplyGroupSegs(pLocalApplicationID,tReceiverID,tSendersID,tVersionID,.pReplyGESeg,.pSC,pOriginalISASeg.Separators)
}

/// Create new GS/GE group segments as a reply, having been given relevant values from original ISA or GS
ClassMethod GetReplyGroupSegs(pLocalApplicationID As %String = "", pOriginalReceiversCode As %String, pOriginalSendersCode As %String, pVersion As %String, Output pReplyGESeg As EnsLib.EDI.X12.Segment, Output pSC As %Status, pSeparators As %String = {$$$X12DefSeparators}) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK, tTimeH=$H, pReplyGESeg=$$$NULLOREF
	Do {
		Set tReplyGSSeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pSeparators))  If '$IsObject(tReplyGSSeg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyGSSeg.SetValueAt("GS",0)  Quit:$$$ISERR(tSC)
		#; Functional Identifier Code of FA means 'Functional or Implementation Acknowledgment Transaction Sets (997,999)'
		Set tSC=tReplyGSSeg.SetValueAt($G(pFuncID,"FA"),$$$GSFunctionalIdentifierCode)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyGSSeg.SetValueAt(pVersion,$$$GSVersionReleaseIndustryIdenti)  Quit:$$$ISERR(tSC)
		#; responsible agency code of X, meaning ASC X12, is the default
		Set tSC=tReplyGSSeg.SetValueAt("X",$$$GSResponsibleAgencyCode)  Quit:$$$ISERR(tSC)

		#; Determine the ID that we should use as Sender in this reply
		#; - support indirection and escaping to allow @ to represent the caller's ID value
		Set tRcvrID=$P(pLocalApplicationID,":",1)
		If pLocalApplicationID["@" {
			Set pos=1 For { Set pos=$F(tRcvrID,"\",pos)  Quit:'pos  Set c=$E(tRcvrID,pos)
				Set tNew=$Case(c, "@":$C(0), "\":"\", :"\"_c), $E(tRcvrID,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
			} Set tRcvrID=$Replace($Replace(tRcvrID,"@",pOriginalReceiversCode),$C(0),"@")
		}
		#; Set the Receiver ID for this reply as the Sender ID that came to us
		Set tSC=tReplyGSSeg.SetValueAt($ZStrip(pOriginalSendersCode,"<>W"),$$$GSApplicationReceiversCode)  Quit:$$$ISERR(tSC)
		
		#; Set the Sender ID for this reply as the replyer ID we just determined based on the Receiver ID that came to us
		Set tSC=tReplyGSSeg.SetValueAt($ZStrip(tRcvrID,"<>W"),$$$GSApplicationSendersCode)  Quit:$$$ISERR(tSC)

		#; Date & Time
		Set tSC=tReplyGSSeg.SetValueAt($ZDate(tTimeH,8),$$$GSDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyGSSeg.SetValueAt($TR($ZTime($P(tTimeH,",",2),2),":"),$$$GSTime)  Quit:$$$ISERR(tSC)
		
		#; Get a new group control number for this reply group
		Set tGroupControlNumber=..NewControlID("G")
		Set tSC=tReplyGSSeg.SetValueAt(tGroupControlNumber,$$$GSGroupControlNumber)  Quit:$$$ISERR(tSC)

		Set pReplyGESeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pSeparators))  If '$IsObject(pReplyGESeg) Set tSC=%objlasterror  Quit
		Set tSC=pReplyGESeg.SetValueAt("GE",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyGESeg.SetValueAt(tGroupControlNumber,$$$GEGroupControlNumber)  Quit:$$$ISERR(tSC)
	} While 0
	Set pSC=tSC
	Quit tReplyGSSeg
}

/// Determine the reply type to use with the given Implementation Guide reference.  We send a 999 response to HIPAA standard transactions with version 5010 or greater.
/// Otherwise we send a 997 response.
ClassMethod DetermineReplyVersion(pIGRef As %String) As %String
{
	// Search for Version Release Industry Identifier in list of HIPAA standard transactions which support 999 as a response
	Set tHIPAAList = $lb("005010X187","005010X279","005030X209","005040X254","005010X212","005010X214","005010X215","005010X217","005010X218","005010X220","005010X221","005010X222","005010X223","005010X224")
	Set tHIPAAList = tHIPAAList_$lb("006020X314","006020X316")
	Set tIs999 = $listfind(tHIPAAList,$E(pIGRef,1,10))
	Quit $Select(tIs999:"999",1:"997")
}

/// Create new ST(997)/AK1/AK9/SE group reply segments as a reply corresponding to an original GS segment
ClassMethod NewGroupReply997Segs(pOriginalGSSeg As EnsLib.EDI.X12.Segment, pOriginalGESeg As EnsLib.EDI.X12.Segment = {$$$NULLOREF}, pCodes As %String = 0, Output pReplyAK1Seg As EnsLib.EDI.X12.Segment, Output pReplyAK9Seg As EnsLib.EDI.X12.Segment, Output pReplySESeg As EnsLib.EDI.X12.Segment, Output pSC As %Status) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK, tTimeH=$H, (pReplyAK1Seg,pReplyAK9Seg,pReplySESeg)=$$$NULLOREF
	Do {
		Set tOriginalVersion = pOriginalGSSeg.GetValueAt($$$GSVersionReleaseIndustryIdenti)
		Set tReplyVersion = ..DetermineReplyVersion(tOriginalVersion)
		Set tReplyST997Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalGSSeg.Separators))  If '$IsObject(tReplyST997Seg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyST997Seg.SetValueAt("ST",0)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyST997Seg.SetValueAt(tReplyVersion,$$$STTransactionSetIdentifierCode)  Quit:$$$ISERR(tSC)
		Set tTSControlNumber=..NewControlID("T")
		Set:$L(tTSControlNumber)<4 tTSControlNumber=$$$NUM(tTSControlNumber,4)
		Set tSC=tReplyST997Seg.SetValueAt(tTSControlNumber,$$$STTransactionSetControlNumber)  Quit:$$$ISERR(tSC)
		If tReplyVersion>997 {
			Set tImplementationRef = $Case($E(tOriginalVersion,1,5),"00602":$$$999ImplementationRef6020,:$$$999ImplementationRef5010)
			Set tSC=tReplyST997Seg.SetValueAt(tImplementationRef,$$$STImplementationConventionRefe)  Quit:$$$ISERR(tSC)
		}
		Set pReplyAK1Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalGSSeg.Separators))  If '$IsObject(pReplyAK1Seg) Set tSC=%objlasterror  Quit
		Set tSC=pReplyAK1Seg.SetValueAt("AK1",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyAK1Seg.SetValueAt(pOriginalGSSeg.GetValueAt($$$GSFunctionalIdentifierCode),$$$AK1FunctionalIdentifierCode)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyAK1Seg.SetValueAt(pOriginalGSSeg.GetValueAt($$$GSGroupControlNumber),$$$AK1GroupControlNumber)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyAK1Seg.SetValueAt(tOriginalVersion,$$$AK1VersionReleaseIndustryIdenti)  Quit:$$$ISERR(tSC)

		Set pReplyAK9Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalGSSeg.Separators))  If '$IsObject(pReplyAK9Seg) Set tSC=%objlasterror  Quit
		Set tSC=pReplyAK9Seg.SetValueAt("AK9",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyAK9Seg.SetValueAt($Case(pCodes,"":"A",0:"A","00":"A","000":"A",:"R"),$$$AK9FunctionalGroupAcknowledgeCo)  Quit:$$$ISERR(tSC)
		If $IsObject(pOriginalGESeg) {
			Set tSC=pReplyAK9Seg.SetValueAt(pOriginalGESeg.GetValueAt($$$GENumberofTransactionSetsInclu),$$$AK9NumberofReceivedTransactionS)  Quit:$$$ISERR(tSC)
		}
		#; Populate Error Code fields if there are errors to report
		Set tErrCount = 0
		For i=1:1:5 {
			Set tCod=$ZStrip($P(pCodes,",",i),"<>W")
			#; Field 5 only included if Field 1 = E or R
			#; Fields 6-9 only included if Field 1 = E or R, previous field used, and there are (additional) error codes to report
			Continue:$Case(tCod,"":1,0:1,"00":1,"000":1,:0)
			Set tSC=pReplyAK9Seg.SetValueAt(tCod,$$$AK9FunctionalGroupSyntaxErrorCo+tErrCount)  Quit:$$$ISERR(tSC)
			Set tErrCount = $I(tErrCount)
		}
		Set pReplySESeg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalGSSeg.Separators))  If '$IsObject(pReplySESeg) Set tSC=%objlasterror  Quit
		Set tSC=pReplySESeg.SetValueAt("SE",0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplySESeg.SetValueAt(tTSControlNumber,$$$SETransactionSetControlNumber)  Quit:$$$ISERR(tSC)
	} While 0
	Set pSC=tSC
	Quit tReplyST997Seg
}

/// Create new AK2/AK5 acknowledgement segments as a reply corresponding to an original ST Transaction Set
ClassMethod NewDocumentReply997Segs(pOriginalSTSeg As EnsLib.EDI.X12.Segment, pCodes As %String = 0, Output pReplyAK5Seg As EnsLib.EDI.X12.Segment, Output pSC As %Status, pGSGreater As %String = "", pRejectErrors As %Boolean = 1) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK, tTimeH=$H, pReplyAK5Seg=$$$NULLOREF
	Do {
		Set tReplyAK2Seg=pOriginalSTSeg.%ConstructClone()  If '$IsObject(tReplyAK2Seg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyAK2Seg.SetValueAt("AK2",0)  Quit:$$$ISERR(tSC)

		Set pReplyAK5Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalSTSeg.Separators))  If '$IsObject(pReplyAK5Seg) Set tSC=%objlasterror  Quit
		#; Use IK5 segment if GS8 declared version HIPAA standard transaction with version >=5010, otherwise base on ST3
		Set tGSGreater = $S(pGSGreater'="":+pGSGreater,1:(..DetermineReplyVersion(tReplyAK2Seg.GetValueAt($$$STImplementationConventionRefe))>997))
		Set tSC=pReplyAK5Seg.SetValueAt($S(tGSGreater:"IK5",1:"AK5"),0)  Quit:$$$ISERR(tSC)
		Set tSC=pReplyAK5Seg.SetValueAt($Case(pCodes,"":"A",0:"A","00":"A","000":"A",:$Select(pRejectErrors:"R",1:"E")),$$$AK5TransactionSetAcknowledgment)  Quit:$$$ISERR(tSC)
		#; Populate Error Code fields if there are errors to report
		Set tErrCount = 0, tCodeCount=0
		While (tErrCount < 5)&&(tCodeCount<$L(pCodes,","))  {
			Set tCod=$ZStrip($P(pCodes,",",$I(tCodeCount)),"<>W")
			#; Field 2 only included if Field 1 = E or R
			#; Fields 3-5 only included if Field 1 = E or R, previous field used, and there are (additional) error codes to report
			Continue:$Case(tCod,"":1,0:1,"00":1,"000":1,:0)
			Set tSC=pReplyAK5Seg.SetValueAt(tCod,$$$AK5TransactionSetSyntaxErrorCod+tErrCount)  Quit:$$$ISERR(tSC)
			Set tErrCount = $I(tErrCount)
		}
	} While 0
	Set pSC=tSC
	Quit tReplyAK2Seg
}

/// Create a new TA1 acknowledgement segment as a reply corresponding to an original ISA segment
ClassMethod NewReplyTA1Seg(pOriginalISASeg As EnsLib.EDI.X12.Segment, pCode As %String = {$$$CodeTA1I18NoError}, Output pSC As %Status, pRejectErrors As %Boolean = 1) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK
	Do {
		Set tReplyTA1Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",pOriginalISASeg.Separators))  If '$IsObject(tReplyTA1Seg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyTA1Seg.SetValueAt("TA1",0)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAInterchangeControlNumber),9),$$$TA1InterchangeControlNumber)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAInterchangeDate),6),$$$TA1InterchangeDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD(pOriginalISASeg.GetValueAt($$$ISAInterchangeTime),4),$$$TA1InterchangeTime)  Quit:$$$ISERR(tSC)
		Set:$Case(pCode,"":1,0:1,"00":1,:0) pCode=$$$CodeTA1I18NoError
		Set tSC=tReplyTA1Seg.SetValueAt($Case(pCode,$$$CodeTA1I18NoError:$$$CodeTA1I17Accepted,$$$CodeTA1I18InvalidSegmentTerminator:$$$CodeTA1I17Rejected,$$$CodeTA1I18UnexpectedEndOfFile:$$$CodeTA1I17Rejected,:$Select(pRejectErrors:$$$CodeTA1I17Rejected,1:$$$CodeTA1I17AcceptedButErrorsNoted)),$$$TA1InterchangeAcknowledgmentCod)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD(pCode,3),$$$TA1InterchangeNoteCode)
	} While 0
	Set pSC=tSC
	Quit tReplyTA1Seg
}

/// Create a new TA1 acknowledgement segment as a reply corresponding to an original ISA segment
ClassMethod NewReplyTA1SegFromString(pOriginalISAString As %String, pCode As %String = {$$$CodeTA1I18NoError}, Output pSC As %Status, pRejectErrors As %Boolean = 1, pDefaultSeps As %String = {$$$X12DefSeparators}) As EnsLib.EDI.X12.Segment
{
	Set tSC=$$$OK
	Do {
		Set tDataElementSeparator=$E($ZStrip(pOriginalISAString,"<AN"))
		If ""=tDataElementSeparator {
			Set tDataElementSeparator = $$$ELESEP(pDefaultSeps)
			Set tSeparators = pDefaultSeps
		} Else {
			Set tComponentSeparator = $P(pOriginalISAString,tDataElementSeparator,$$$ISAComponentElementSeparator + 1)
			If (tComponentSeparator="") || (tComponentSeparator?1(1A,1N)) || (tComponentSeparator=tDataElementSeparator) {
				Set tComponentSeparator = $$$COMSEP(pDefaultSeps)
				Set:tComponentSeparator=tDataElementSeparator tComponentSeparator = $C(17)
			}
			Set tRepetitionSeparator = $P(pOriginalISAString,tDataElementSeparator,$$$ISARepetitionSeparator + 1)
			If (tRepetitionSeparator="") || (tRepetitionSeparator?1(1A,1N)) || $Case(tRepetitionSeparator,tComponentSeparator:1,tDataElementSeparator:1,:0) {
				Set tRepetitionSeparator = $$$REPSEP(pDefaultSeps)
				Set:$Case(tRepetitionSeparator,tComponentSeparator:1,tDataElementSeparator:1,:0) tRepetitionSeparator = $C(18)
			}
			Set tSeparators = tDataElementSeparator_tComponentSeparator_tRepetitionSeparator
		}
		Set tReplyTA1Seg=##class(EnsLib.EDI.X12.Segment).%New($LB("",1,"",tSeparators))  If '$IsObject(tReplyTA1Seg) Set tSC=%objlasterror  Quit
		Set tSC=tReplyTA1Seg.SetValueAt("TA1",0)  Quit:$$$ISERR(tSC)
		
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeControlNumber+1),9),$$$TA1InterchangeControlNumber)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeDate+1),6),$$$TA1InterchangeDate)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD($P(pOriginalISAString,tDataElementSeparator,$$$ISAInterchangeTime+1),4),$$$TA1InterchangeTime)  Quit:$$$ISERR(tSC)
		
		Set:$Case(pCode,"":1,0:1,"00":1,:0) pCode=$$$CodeTA1I18NoError
		Set tSC=tReplyTA1Seg.SetValueAt($Case(pCode,$$$CodeTA1I18NoError:$$$CodeTA1I17Accepted,$$$CodeTA1I18InvalidSegmentTerminator:$$$CodeTA1I17Rejected,$$$CodeTA1I18UnexpectedEndOfFile:$$$CodeTA1I17Rejected,:$Select(pRejectErrors:$$$CodeTA1I17Rejected,1:$$$CodeTA1I17AcceptedButErrorsNoted)),$$$TA1InterchangeAcknowledgmentCod)  Quit:$$$ISERR(tSC)
		Set tSC=tReplyTA1Seg.SetValueAt($$$PAD(pCode,3),$$$TA1InterchangeNoteCode)
	} While 0
	Set pSC=tSC
	Quit tReplyTA1Seg
}

/// Get a new unique control number. Control number type can be Interchange control numbers "I", group Control numbers "G", TransactionSet control numbers "T".
ClassMethod NewControlID(pType As %String) As %Integer
{
	Set tNum = $Increment($$$EnsStaticAppData("X12",pType))
	If $Length(tNum)>9 {
		Set tNum = 1
		Set $$$EnsStaticAppData("X12",pType)=1
	}
	Quit tNum
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
	Set pColumns(iCol,"page")="http://www.x12.org"
	Set pColumns(iCol,"name")=$$$Text("ASC X12")
	Set pColumns(iCol,"desc")=$$$Text("""Accredited Standards Committee"" X12 EDI Transaction Set documents and Interchange files")
	
	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("SEF/EDISchemaMain.csp?FAMILY=X12")
	Set pColumns(iCol,"name")=$$$Text("Schema Structures")
	Set pColumns(iCol,"desc")=$$$Text("View schema definitions for various types of X12 documents")

	Set iCol=iCol+1
	Set pColumns(iCol,"page")=##class(%CSP.Page).Link("EDIDocumentView.csp?NAME="_$ZCVT("X12 Document","O","URL")_"&CLASS=EnsLib.EDI.X12.Document")
	Set pColumns(iCol,"name")=$$$Text("Document Viewer")
	Set pColumns(iCol,"desc")=$$$Text("View X12 Documents from a variety of sources and test them with various DocType schema definitions and Data Transformations")

	Quit 1
}

/// Used by DTL Editor for nested schemas in Batch document
ClassMethod GetBatchChildDTLInfoArray(pDocType As %String, pSegment As %String, pNodeAddr As %String, ByRef pBatchChildInfoArray As %String) As %Boolean [ Internal ]
{

	Kill pBatchChildInfoArray

	/*
		Supporting manual typing of only 2 DocTypes after category
		but the Schema dialog in DTL Editor only allows picking either 1 or 3:
			HIPAA_5010:834 (or other ST structure)
			HIPAA_5010:Interchange:Group:834
			but allow
			HIPAA_5010:Interchange:Group
			HIPAA_5010:Group:834
	*/

	If $Length(pDocType,":") < 3 Return 0

	#dim mode = $Piece(pSegment,".")
	If (mode'="source") && (mode '= "target") Set mode = "source"

	#; Tell the DTL Editor which actual properties to replace
	Set pBatchChildInfoArray("replaceProperties","GroupDocsRef") = $$$GroupsLabel
	Set pBatchChildInfoArray("replaceProperties","TransactionSetDocsRef") = $$$TransactionsLabel

	#; If more than one replacement label is present which one takes precedence
	Set pBatchChildInfoArray("schemaSearchOrder") = 2
	Set pBatchChildInfoArray("schemaSearchOrder",1) = $$$TransactionsLabel
	Set pBatchChildInfoArray("schemaSearchOrder",2) = $$$GroupsLabel

	#dim docCategory = $Piece(pDocType,":")
	#dim childDocName = $Piece(pDocType,":",3)

	If (childDocName '= "") {

		If ($Piece(pDocType,":",4)="") {

			If $Piece(pDocType,":",2)="Interchange" {

				Set pBatchChildInfoArray("schema",mode,$$$GroupsLabel) = docCategory_":"_childDocName

			} ElseIf $Piece(pDocType,":",2)="Group" {

				Set pBatchChildInfoArray("schema",mode,$$$TransactionsLabel) = docCategory_":"_childDocName

			} Else {

				#; Not supported
				Return 0

			}

		} Else {

			Set pBatchChildInfoArray("schema",mode,$$$GroupsLabel) = docCategory_":"_childDocName
			Set childDocName = $Piece(pDocType,":",4)
			If childDocName '= "" Set pBatchChildInfoArray("schema",mode,$$$TransactionsLabel) = docCategory_":"_childDocName

		}

	}

	#; Calculate replacement nodeArray to be passed to
	If pSegment = "" {

		Set pBatchChildInfoArray("nodeArray") = pNodeAddr

	} Else {

		/*
			recalculate node array if will be calling different DocType than pDocType
			ie pSegment [ "."_substitute("schema",<SubstituteName> or <SubstituteNameProperty>)
			then need to know how far down. If last one then set to -1
			Also Set pSubstitutionsArray("infoschema") if pSegment contains a "schema' 
		*/

		Set pBatchChildInfoArray("infoschema") = pDocType

		#dim c, tSegmentPiece,start,startN

		For c = 1:1:pBatchChildInfoArray("schemaSearchOrder") {

			If pSegment [ pBatchChildInfoArray("schemaSearchOrder",c) {
				Set tSegmentPiece = pBatchChildInfoArray("schemaSearchOrder",c)
				Set pBatchChildInfoArray("infoschema") = pBatchChildInfoArray("schema",mode,tSegmentPiece)
				Set start = $Piece(pSegment,"."_tSegmentPiece)
				Set startN=$l(start,".")
				If $L(pNodeAddr,",") = startN {
					Set pBatchChildInfoArray("nodeAddr") = -1
				} Else {
					Set pBatchChildInfoArray("nodeAddr") = $Piece(pNodeAddr,",",(startN+1),*)
				}
				Quit
			}

		}

	}

	Return 1
}

/// Get method for temporary property used to hold the pointers to FunctionalGroup children
Method FunctionalGroupsGet(key) As EnsLib.EDI.X12.Document [ Internal, ServerOnly = 1 ]
{
	If $Get(key)="" Return ""
	If ..Name'="Interchange" Return ""

	#dim child = $$$NULLOREF
	Set child = $Get(i%FunctionalGroups(key))
	If $IsObject(child) Return child

	#;Look for key number child and store pointer to child if exists
	Set child = ..getNthChild(key)
	If $IsObject(child) Set i%FunctionalGroups(key)=child
	Return child
}

/// Set method for temporary property used to hold the pointers to FunctionalGroup children
/// Does not create actual child relationship
Method FunctionalGroupsSet(x12Doc As EnsLib.EDI.X12.Document, key) As %Status [ Internal, ServerOnly = 1 ]
{
	If x12Doc = "" {
		Kill i%FunctionalGroups(key)
	} ElseIf ..Name="Interchange" {
		Set i%FunctionalGroups(key)=x12Doc
	}
	Quit $$$OK
}

/// Get method for temporary property used to hold the pointers to TransactionSet children
Method TransactionSetsGet(key) As EnsLib.EDI.X12.Document [ Internal, ServerOnly = 1 ]
{
	If $Get(key)="" Return ""
	If ..Name'="Group" Return ""

	#dim child = $$$NULLOREF
	Set child = $Get(i%TransactionSets(key))
	If $IsObject(child) Return child

	#;Look for key number child and store pointer to child if exists
	Set child = ..getNthChild(key)
	If $IsObject(child) Set i%TransactionSets(key)=child
	Return child
}

/// Set method for temporary property used to hold the pointers to TransactionSet children
/// Does not create actual child relationship
Method TransactionSetsSet(x12Doc As EnsLib.EDI.X12.Document, key) As %Status [ Internal, ServerOnly = 1 ]
{
	If x12Doc = "" {
		Kill i%TransactionSets(key)
	} ElseIf ..Name="Group" {
		Set i%TransactionSets(key)=x12Doc
	}
	Quit $$$OK
}

/// Internal method to allow FunctionGroups() and TransactionSets() to return a given child <br>
Method getNthChild(numberToGet As %Integer, segIndex As %Integer) As EnsLib.EDI.X12.Document [ Internal ]
{
	#dim tSC = $$$OK
	#dim child = $$$NULLOREF

	If (+numberToGet=numberToGet)&&(numberToGet>0)&&(numberToGet<=..ChildCount) {

		If '$Data(segIndex)#2{
			#; Determine type from Name
			#dim placeHolderSegment
			If "Interchange"=..Name {
				Set placeHolderSegment = "GroupDocsRef"
			} Else {
				Set placeHolderSegment = "TransactionSetDocsRef"
			}
			Do ..BuildMap()
			Set segIndex = ..GetSegmentIndex(placeHolderSegment,.tSC)
		}

		If $$$ISOK(tSC) && segIndex {

			#dim tNextId=""
			#dim childNumber=0

			For {
				Set tNextId=..getNextChildId(..%Id(),tNextId,segIndex)
				If tNextId="" Quit
				Do $Increment(childNumber)
				If childNumber = numberToGet {
					Set child = ..%OpenId(tNextId)
					Quit
				}
			}
		}

	}

	#;Set doc type and build segment map
	If $IsObject(child) {
		If ""=child.DocType {
			#dim tDocType = child.resolveChildDocType()
			Do child.PokeDocType(tDocType)
		}
		Do child.BuildMap()
	}

	Return child
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
<Value>Envelope</Value>
</Value>
<Value name="9">
<Value>HandledIndividually</Value>
</Value>
<Value name="10">
<Value>%ParsingError</Value>
</Value>
</Data>
<Data name="UserValues">
<Attribute>UserValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"UserValues"</Subscript>
</Data>
<DataLocation>^EnsLib.EDI.X12.DocumentD</DataLocation>
<DefaultData>DocumentDefaultData</DefaultData>
<ExtentSize>2000000</ExtentSize>
<IdLocation>^EnsLib.EDI.X12.DocumentD</IdLocation>
<IndexLocation>^EnsLib.EDI.X12.DocumentI</IndexLocation>
<StreamLocation>^EnsLib.EDI.X12.DocumentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
