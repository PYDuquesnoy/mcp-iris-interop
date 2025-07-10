/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsEDIXML, %occXSLT, %occSAX, %xmlDOM)

/// This class encapsulates an XML document stream and provides methods to interrogate and update it
/// Two types of path strings can be used to identify a document node: a 'Property path' that is based in
/// a particular XML schema definition (xsd), irrespective of any particular document instance, and a 'DOM path' that is based in the structure of a particular
/// document irrespective of any XML schema. The DOM Path uses XPATH conventions; it always starts with '/' while a Property Path never does.
Class EnsLib.EDI.XML.DOM Extends (EnsLib.EDI.Document, EnsLib.EDI.XML.MsgBodyMethods, %XML.SAX.ContentHandler) [ System = 4 ]
{

/// Formatting specifiers for XML output and input: whitespace, canonicalization and default values
Property Format As %String(MAXLEN = "") [ Transient ];

/// The raw text content of the document. Note that this is a truncated version suitable for use in SQL results and visual inspection,
/// but not a complete or definitive representation of the document.
Property RawContent As %String(MAXLEN = "") [ Calculated, ReadOnly ];

/// Reference to persistently stored content which, if we have been %Save'd, has a reference to our ID
Property %storedContentRef As %String(MAXLEN = "") [ Internal, ReadOnly ];

/// Refers to a process private global when object is new, or to a contents global node %storedContentRef when opened from a stored instance or committed
/// If %storedContentRef is not empty but %ContentRef is not the same, then %ContentRef is referring to
/// a process-private global that contains an exact copy of the stored data (except for its reference to our ID).
/// If we modify the private global contents we must remove our reference to the stored content and its reference to our id.
/// This is intended for bulky static data
Property %ContentRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

/// Refers to ..%DOMCache (in memory) if active, storage node "domcache" while dormant
/// If both %PropCache and %DOMCache have contents, %PropCache has precedence
/// If %DOMCache needs to change, %PropCache must first be merged into it
/// This is a local property to avoid shared data storage issues when cloning. If it gets too big it can be merged down to the local contents of %ContentRef
/// This is intended for modest sized mutable data. Use CommitNode() if it gets too big.
Property %DOMCacheRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

Property %DOMCache [ Internal, MultiDimensional, Transient ];

/// Cache calculations to speed up findIndex and GetNextIndex
Property %CalcCacheRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

/// Cache calculations to speed up findIndex and GetNextIndex
Property %CalcCache [ Internal, MultiDimensional, Transient ];

Property %saveParentDOMPath [ Internal, ReadOnly, Transient ];

Property %ParseCache [ Internal, ReadOnly, Transient ];

/// Cache mapping of findIndex arguments to their outputs
Property %FindCacheRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

/// In createNonExistent skip finds and don't kill the calc cache if inserting at end
Property %SkipFind [ Internal, Transient ];

/// Cache mapping of findIndex arguments to their outputs
Property %FindCache [ Internal, MultiDimensional, Transient ];

/// Refers to ..%PropCache (in memory) if active, storage node "propcache" while dormant
/// If both %PropCache and %DOMCache have contents, %PropCache has precedence
/// This is intended for modest sized mutable data. Use CommitNode() if it gets too big.
Property %PropCacheRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

/// If this exists, it supersedes %DOMCache
Property %PropCache [ Internal, MultiDimensional, Transient ];

/// Transient document instance used to build an XML content array from an imported document and hold onto it until we persist it.
Property %XMLDoc As %XML.Document [ Internal, ReadOnly, Transient ];

/// Index used to purge PPG area used to store CalcCache when PPG used to store CalcCache (this is done automatically)
Property %PurgeIndex As %Integer [ ReadOnly, Transient ];

Property %CalcCount As %Integer [ InitialExpression = 0, ReadOnly, Transient ];

Property %MaxCalcCache As %Integer [ InitialExpression = {$$$MAXCALCCACHE}, ReadOnly, Transient ];

/// Raw type name of document as declared in document content
Property Name As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {Name}=$S(""={%storedContentRef}:"",1:$$$xmlGetNodeValue({%storedContentRef},$$$xmlGetDocumentElement({%storedContentRef}))) }, SqlComputed, Transient ];

/// Raw type version of document if declared in document content
Property TypeVersion As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {TypeVersion}=$$$xmlGetAttribute({%storedContentRef},$$$xmlGetDocumentElement({%storedContentRef}),"schemaLocation") }, SqlComputed, Transient ];

/// Unique document identification string found in document content (none defined for a general XML document)
Property Identifier As %String(MAXLEN = "") [ Calculated, ReadOnly, SqlComputeCode = { Set {Identifier}="" }, SqlComputed, Transient ];

/// Overridden as Transient from %XML.SAX.ContentHandler: Parser control block. Used only when HandlerType is set to $$$LocHandler
Property controlblock As %String(MAXLEN = "") [ Internal, Transient ];

/// Used in Document Validate() to pass schema location to DOM
Property schemaLocation As %String(MAXLEN = "") [ Internal, Transient ];

/// Used in Document Validation, whether we use xsi:schemaLocation attribute or xsi:noNamespaceSchemaLocation attribute
Property noNamespaceSchemaLocation As %String(MAXLEN = "") [ Internal, Transient ];

ClassMethod CoverageInit() [ Internal ]
{
	#define COVERAGEINIT(%x) set ^ISC.Coverage(%x)=""
	k ^ISC.Coverage
	;$$$COVERAGEINIT("rule Na tCHit and 'tDHit and only contains text!")
    $$$COVERAGEINIT("rule Na tCHit and 'tDHit but pValue is text!")
    $$$COVERAGEINIT("rule Na tDHit!")
    $$$COVERAGEINIT("rule Na append mixed content tCHit="_0_" tDHit="_0)
    $$$COVERAGEINIT("rule Na append mixed content tCHit="_1_" tDHit="_0)
    $$$COVERAGEINIT("rule Na append mixed content tCHit="_1_" tDHit="_1)
    $$$COVERAGEINIT("rule Na append mixed content tCHit="_0_" tDHit="_1)
    $$$COVERAGEINIT("rule Na append mixed content tCHit and 'tDHit")    
    $$$COVERAGEINIT("rule Na append mixed content 'tCHit or tDHit")
    $$$COVERAGEINIT("rule Ea append tCHit and 'tDHit and content contains only text and pValue is not mixed content")
    $$$COVERAGEINIT("rule Ea append tDHit and content contains only text and pValue is not mixed content")
    $$$COVERAGEINIT("rule Ea append - either not tDHit or DOM contains mixed content and pValue is not mixed content")
    $$$COVERAGEINIT("rule Ea append tCHit and 'tDHit and content contains only text and pValue is MIXED content")
    $$$COVERAGEINIT("rule Ea append tDHit and content contains only text and pValue is MIXED content")
    $$$COVERAGEINIT("rule Ea append - either not tDHit or DOM contains mixed content and pValue is mixed content")
    $$$COVERAGEINIT("rule Ea append - tDHit and DOM contains mixed content and pValue is mixed content")
    $$$COVERAGEINIT("rule Ea append - no tDHit and DOM contains mixed or text-only content and pValue is mixed content")
    $$$COVERAGEINIT("find the last DOM node or Content node if any tElem'=""""")
    $$$COVERAGEINIT("find the last DOM node or Content node if any tElem=""""")
    $$$COVERAGEINIT("instruction(), comment() or text() tDHitPrev=1")
    $$$COVERAGEINIT("instruction(), comment() or text() tCHitPrev=1")
    $$$COVERAGEINIT("element()")
    $$$COVERAGEINIT("instruction(), comment() or text() at numeric index")
    $$$COVERAGEINIT("instruction(), comment() or text() at numeric index tDHitPrev, 'tCHitPrev")
    $$$COVERAGEINIT("instruction(), comment() or text() at numeric index tCHitPrev, 'tDHitPrev")
    $$$COVERAGEINIT("instruction(), comment() or text() at numeric index tCHitPrev, tDHitPrev")
    $$$COVERAGEINIT("findLast tMatchedElemName non-null")
    $$$COVERAGEINIT("findLast tMatchedElemName null")
    $$$COVERAGEINIT("instruction(), comment() or text() in not an element findLast")
    $$$COVERAGEINIT("instruction(), comment() or text() in looking for a non-element")
    $$$COVERAGEINIT("find the last element")
    $$$COVERAGEINIT("overwrite the Content Array Node")
    $$$COVERAGEINIT("found=0 Set kDom2 to kDom")
    $$$COVERAGEINIT("found=1 setting through element() function")
}

ClassMethod CoverageStatistics() [ Internal ]
{
	Set Count=0
	Set Uncovered=0
	Set i="" for { set i=$O(^ISC.Coverage(i),1,coveragepoint) q:i=""
		Set Count=Count+1
		if coveragepoint="" w !,i_" not covered" Set Uncovered=$i(Uncovered)
	}
	w !,"Total coverage points="_Count_" Uncovered="_Uncovered
}

Method domGetValueAt(Output pValue As %String, pDOMPath As %String, pFormat As %String, pIgnoreNamespaces As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK, tFormat=$G(pFormat,..Format)  Set:""=pDOMPath pDOMPath="/"
 ;w:1 !,"<br/>domGetValueAt("_pDOMPath_","_tFormat_","_pIgnoreNamespaces_")"
	if pDOMPath="/full()" {
		Set pDOMPath="/"
	}
	if pDOMPath="/" {
		Set:tFormat'["f" tFormat="f"_tFormat
	}
	;if (pDOMPath="/")||(pDOMPath="/full()") Set pDOMPath="/1/full()",tContentSubs=$$$xmlGetDocumentElement(..%ContentRef)
	Set:'$$$IsdefObject(pValue) pValue=""
	If "/full()"=$E(pDOMPath,*+1-$L("/full()"),*) { Set:tFormat'["f" tFormat=tFormat_"f"  Set pDOMPath=$E(pDOMPath,1,*-$L("/full()")) }
	Set tNamespaces=##class(NamespaceHelper).%New()
	Set:pIgnoreNamespaces tNSContext("ign")=pIgnoreNamespaces
	Set tSC=..domParsePath(pDOMPath,"get",.tContentSubs,.tDOMSubs,.tType,.tIndex,.tValue,.tNSContext,.tAfterCNode,.tFinalSubscript,.tInsertDSubs,.tInsertIndex,.tCHit,.tDHit,.dummy1,.textOrdinal,.textAfterCNode,.textSubscript,.tInsertSubscript,.tContentNamespace,tFormat,.tNamespaces,"","","","","","","")  Quit:$$$ISERR(tSC) tSC
	if pDOMPath="/" {
		if '$D(@$$$vaContentRef(0)),'$D(@$$$vaDOMRef(tDOMSubs)) {
			Quit $$$OK
		}
	}

	if pDOMPath="/" {
		if ($D(@$$$vaContentRef(0))) { ; is ContentArray empty?
			Set tContentSubs=$$$xmlGetDocumentElement(..%ContentRef),tCHit=1
		}
			
	}
	if pDOMPath="/" {
		Set tDOMSubs=",1"
		Set rootPair=$g(@$$$vaDOMRef(tDOMSubs))
		if (rootPair'="") {
			Set root=$P(rootPair,">")
			if (root="/") { ; we have preceding processing instructions or comments
				Set tContentSubs=0 ; magic number
			}
			Set tDOMSubs=","">"_root_""",1",tDHit=1
			Set tDHit=1
		} else {
			Set tDOMSubs="_",tDHit=0
		}
	}
	Set tNodeTypeRoot=0
	If "/node-type()"=pDOMPath Set tNodeTypeRoot=1
	if tNodeTypeRoot=0,tCHit=0,tDHit=0 Quit $$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path, does not exist at DOM Path "_pDOMPath)
	If $Case($E(tType),">":(""'=tValue), "@":1, "":0, :1) {
		If $IsObject(pValue) {
			Do pValue.Write(tValue,,.tSC)
		} Else {
			Set pValue=tValue
		}
		Quit tSC
	}
	if pDOMPath'="/" Set:'$D(@$$$vaDOMRef(tDOMSubs)) tDOMSubs="_" ; not needed for Get
	Set tNSContext("level")=0
	Set tNamespaceFound=1
	Set:(""'=tContentSubs)||("_"'=tDOMSubs) tSC=..domGetSubtree(.pValue,pDOMPath,tContentSubs,tDOMSubs,tFormat,.tNSContext,tCHit,tDHit,tNamespaces,,,,,,,tNamespaceFound,1,.tCachedNamespaces)
	if $g(pFormat)[$$$OUTPUTSCHEMAINFO {
		Set ..schemaLocation=""
		Set ..noNamespaceSchemaLocation=""
	}
	Quit tSC
}

/* 02-23-11

 Values of ">R"

  1 - replace node

  2 - remove node and everything below node

  a - clear attributes

  c - clear content, elements, text, processing instructions and comments, but not element itself or attributes
  
  d - clear sub-elements and text, but not processing instruction, comments, nor element itself nor its attributes (rule *Ec)
*/
Method domSetValueAt(pValue As %String, pDOMPath As %String, pAction As %String = "set", pKey As %String = "") As %Status [ Internal ]
{
	;$$$vaKillCalcCache ; JSL4382
	Set parentDOMPath=$P(pDOMPath,"/",1,$L(pDOMPath,"/")-1)
	If (parentDOMPath'=i%%saveParentDOMPath) {
		Kill:parentDOMPath'="" ^||ISC.XML.VDOC.ParseCache(i%%ParseCache,parentDOMPath)
	}

	Set tWild=..setAllElementToAttribute(pDOMPath,.tTargetDOMPath,.tAttrName)
	If tWild,pAction="set" {
		Set Status=..domGetValueAt(.count,tTargetDOMPath_"[*]","")
		Set i%%saveParentDOMPath=""
		if $$$ISERR(Status) quit Status
		for i=1:1:count {
			Set Status=..domSetValueAt1(pValue, tTargetDOMPath_"["_i_"]/"_tAttrName, pAction, pKey)
			if $$$ISERR(Status) quit
		}
		if $$$ISERR(Status) quit Status
		Quit $$$OK
	} else {
		Quit ..domSetValueAt1(pValue, pDOMPath, pAction, pKey)
	}
	Set parentDOMPath=$P(pDOMPath,"/",1,$L(pDOMPath,"/")-1)
	If (parentDOMPath'=i%%saveParentDOMPath)
 	{
		Kill:parentDOMPath'="" ^||ISC.XML.VDOC.ParseCache(i%%ParseCache,parentDOMPath)
		Set i%%saveParentDOMPath=parentDOMPath
	}
}

Method setAllElementToAttribute(pDOMPath As %String, Output pTargetDOMPath As %String, Output pAttrName As %String, Output tSC) [ Internal ]
{
		Set wildcard = 0
		Set tFinal=0,pos=2,pieceIndex=1  For { Quit:'pos  Set oldpos=pos, pos=$F(pDOMPath,"/",oldpos)

			Set pieceIndex=pieceIndex+1
			If 'pos { Set tElem=$E(pDOMPath,oldpos,*) }
			Else { Set tElem=$E(pDOMPath,oldpos,pos-2) }
			Set tLastElem='pos
			Quit:""=tElem&&tLastElem
			Set (tReplace,tRemove,tCHit,tDHit)=0 
			Set alreadyCalculated=0
			Set prevCNode=""
			if pos {
				Set newpos=$F(pDOMPath,"/",pos)
				If 'newpos { Set tNextElem=$E(pDOMPath,pos,*) }
				Else { Set tNextElem=$E(pDOMPath,pos,newpos-2) }
			} else {
				Set tNextElem=""
			}
			if ($e(tNextElem,*-1,*)="[]") {
				Set wildcard=1
				if $e(tNextElem)="[" {
					Set pTargetDOMPath=$e(pDOMPath,1,pos-1)
				} else {
					Set pTargetDOMPath=$e(pDOMPath,1,newpos-4)
				}
			}
			if $e(tNextElem)="@" {
				Set pAttrName=tNextElem
			}
			//Set tSC=..domParsePathElem(pDOMPath,.tElem,tNextElem,"set",.tIndex,.tNode,.tInsert,.tFinal,.tElemIgnoreNamespaces)  Quit:$$$ISERR(tSC)
			
		}
		Quit wildcard
}

Method domSetValueAt1(pValue As %String, pDOMPath As %String, pAction As %String = "set", pKey As %String = "") As %Status [ Internal ]
{
	#define COVERAGE(%x)
	Set isRemove=0
	Set isReplace=0
	Set isReplaceContent=0
	Set isClear=0
	Set tInsertType=""
	if pDOMPath="/" {
		Set @$$$vaDOMRef(","_1)="/>1"
		Set tSC=..ReadString("<pseudoRoot>"_pValue_"</pseudoRoot>",1,1)
		quit tSC
	}
	If "/full()"=$E(pDOMPath,*+1-$L("/full()"),*) { 
		if (pAction="append") {
			quit $$$ERROR($$$EnsErrGeneral,"/full() not valid when doing an append; the DOM Path is "_pDOMPath)
		}
		if (pValue="") {
			Set isRemove=1 ; we remove node, rule *F
		} else {
			quit $$$ERROR($$$EnsErrGeneral,"/full() not valid on a set unless pValue=""""; the DOM Path is "_pDOMPath)
		}
		Set pDOMPath=$E(pDOMPath,1,*-$L("/full()")) 
	}
	Set tFormat="" ; dummy format
	Set tSC=..domParsePath(pDOMPath,"set",.tContentSubs,.tDOMSubs,.tType,.tIndex,.tValue,.tNSContext,.tAfterCNode,.tFinalSubscript,.tInsertDSubs,.tInsertIndex,.tCHit,.tDHit,.tInsertType,.textOrdinal,.textAfterCNode,.textSubscript,.tInsertSubscript,.tContentNamespace,tFormat,.tNamespaces,pAction,.tPrevNode,.tCurrentNode,.tCNodeTextHit,.tElemSubscript,.tNode,.isElement,.tCHitPrev,.tDHitPrev,pValue)  Quit:$$$ISERR(tSC) tSC

	Set tEndWithAllAttributes=0
	if (tType="@[]") {
		Set tEndWithAllAttributes=1
	}
	if (pValue="")&&((pAction="clear")||(pAction="remove"))&&tEndWithAllAttributes {
		Set clearAttributes=1
	} else {
		Set clearAttributes=0
	}
	if 'clearAttributes {
		if pAction="remove" {
			Set isRemove=1
		}
		if pAction="clear" {
			Set isClear=1 ; same as pValue="" in most cases
		}
	}
	Set tDSubs=","
	if tNode Set isReplace=1
	if (tInsertType="elementattribute") {
		; Here is where we process attributes
		Set sep=""
		if $e(tDOMSubs)="," s tDOMSubs=$e(tDOMSubs,2,*)
		$$$ASSERT(($L(tDOMSubs,",") # 2) = 0)
		for iSub=1:1:($L(tDOMSubs,",")-1) {
			Set tElem=$P(tDOMSubs,",",iSub)
			Set tOrdinal=$P(tDOMSubs,",",iSub+1)
			if tElem=""">@""" {
				Set tAttrName=$e($tr(tOrdinal,"""",""),2,*)
				if $e(tAttrName)="$",tAttrName[":" {
				;if $e(tAttrName,1,$L("xsd_"))="xsd_",tAttrName[":" {
					; 08-02-11 91171: (Dev) Inconsistent XML namespace prefixes with DTL 
					Set prefix=$P(tAttrName,":",1)
					Set uri=$$$vaSchemaGbl(..DocTypeCategory,"ns","list",$e(prefix,2,*),"uri")
					Set level=tNSContext("level")
					set i="" for {  set i=$o(tNSContext(level,"namespaces",i),1,urivalue) q:i=""  
						if i[":" {
							Set iscprefix=$P(i,":",2)
							if $e(iscprefix,1,$L("xsd_"))="xsd_" continue
						}
						q:uri=$g(urivalue)
					}
					if i'="",uri=$g(urivalue) {
						Set iscprefix=$P(i,":",2)
						Set localname=$P(tAttrName,":",2)
						if (iscprefix'="") {
							Set tAttrName=iscprefix_":"_localname
						} else {
							Set tAttrName=localname
						}
					} else {
				
						Set prefix=$P(tAttrName,":")
						if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
							; prefix is of form $number
							Set prefix="xsd_"_$e(prefix,2,*)
							Set localname=$P(tAttrName,":",2)
							Set tAttrName=prefix_":"_localname
						}
					}
				}
				Set tSC=..domGetAttrs(.DummyPrefixes,.Dummy,tContentSubs,$S("_"=tDSubs:"_",1:tDSubs_","">@"""),tFormat,.tNSContext,tCHitPrev,tDHitPrev,.tAttrCount, tAttrName,.tAttrNumber,"","","",1) 
				if '$D(tAttrNumber) Set tAttrNumber=tAttrCount+1 ; not found
			
				Set tAttrSubscript=tElemSubscript_sep_tElem_","_tAttrNumber
				Set @$$$vaDOMRef(tAttrSubscript)=tAttrName
				// 11-01-10
				// 01-31-12a
				if tContentSubs'="",$$$xmlAttributeDefined(..%ContentRef,tContentSubs,tAttrName) {
					if 'isRemove {
						Set @$$$vaDOMRef(tElemSubscript_sep_tElem_","">"_tAttrName_""","">I""")=tAttrName
					}
				} else {
					; give value of ">I" which collates above all other characters
					if 'isRemove {
						Set @$$$vaDOMRef(tElemSubscript_sep_tElem_","">"_tAttrName_""","">I""")=$c(65535)
					}

				}
			}
			Set tDSubs=tDSubs_sep_tElem_","_tOrdinal
			Set iSub=iSub+1
			if tElem=""">@""",'isRemove {
				Set:isClear=1 pValue="" ; rule *Ac
				Set tOldAttrValue="" ; old attribute value only used for an append
				if (pAction="append") { ; rule Aa
					if tCHit,'tDHit {
						// 01-31-12a
						Set tOldAttrValue=$$$xmlGetAttribute(..%ContentRef,tContentSubs,tAttrName)
					}
					if tDHit {
						Set tOldAttrValue=$g(@$$$vaDOMRef(tElemSubscript_sep_tElem_","">"_tAttrName_""""))
					}
				}
				Set @$$$vaDOMRef(tElemSubscript_sep_tElem_","">"_tAttrName_"""")=tOldAttrValue_$zcvt(pValue,"I","XML")
			}
			if isRemove,tElem=""">@""" {
				// rule *Ar
				do ..domRemoveAttribute(tContentSubs,tElemSubscript_sep_tElem,tAttrName,tCHit,tDHit)
			}
			Set sep=","
		}
	}
	if $g(tInsertDSubs)'="",tInsertType="elementattribute" {
		Set tElemName=$P(tInsertIndex,">",1)
		Set tOrdinal=$P(tInsertIndex,">",2)
		if tOrdinal="" Set tOrdinal=1
		Set @$$$vaDOMRef(tInsertDSubs_","_tFinalSubscript)=tElemName_">"_tOrdinal
		if $D(tAfterCNode) Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">I""")=tAfterCNode
		if isReplace {
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")=1
		}
		if (isReplace||clearAttributes)&&(tDHit) {
			Kill @$$$vaDOMRef(tElemSubscript_","">@""")
		} elseif (clearAttributes)&&(tCHit) {
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")="a"
		} elseif tCHit,pDOMPath["~" { ; Prodlog - 106083 01-25-13
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")="c"
		}
		do ..domElementSort(tInsertDSubs,tElemName_">"_tOrdinal)
		;$$$vaKillCalcCache1(tInsertDSubs) ; JSL4383 uncommenting this kill does not fix infinite loop in regression
	} elseif $g(tInsertDSubs)'="",tInsertType="textinsert" {
		Set tOrdinal=tFinalSubscript		
		if 'isRemove,$e($g(tAfterCNode))'="+" Set tAfterCNode="+"_$g(tAfterCNode)
		if 'isRemove||'$g(isElement) if $D(tAfterCNode) Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">I""")=tAfterCNode
		if (pValue'["<") { ;don't parse is not XML, unless we appending
			; process append 03-18-11
			; appending pValue which is text-only
			if pAction="append" {
				if tCHit,'tDHit {
					$$$COVERAGE("rule Na tCHit and 'tDHit but pValue is text!")
					; just append text	
					Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal)=">T"
					Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">V""")=pValue

				}
				elseif tDHit {
					;; we are going to replace content array with DOM array
					$$$COVERAGE("rule Na tDHit!")
					; pValue is text-only but even if DOM contains mixed content will still do append
					Set ..pDSubs=tInsertDSubs_","_tOrdinal
					Set ..pOrdinal=tOrdinal
					Set tSC=..ReadString("<pseudoRoot>"_pValue_"</pseudoRoot>",0)
					$$$vaKillCalcCache1(tInsertDSubs) ; JSL4384 part B ; does not fix regression
					$$$vaKillCalcCache1(tDOMSubs) ; JSL4384 part B ; does not fix regression
					if $$$ISERR(tSC) quit tSC
				}
			}
			if isRemove {
				; 4-22-11
				Set dtyp=$g(@$$$vaDOMRef(tInsertDSubs_","_tOrdinal))
				if dtyp[">",$e(dtyp)'=">" { ; element
					Set tElemName=$P(dtyp,">",1)
					Set tElemIndex=$P(dtyp,">",2)
					Set ISubs=tInsertDSubs_","">"_tElemName_""","_tElemIndex_","">I"""
					Set oldISubscript=$g(@$$$vaDOMRef(ISubs))
				}
				
			}
			if pAction'="append",pAction'="remove" {
				Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal)=">T"
				Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">V""")=pValue
			}
		} else {
			; pValue is mixed content which involves elements, set up pDSub for DOMSaxContentHandler, call Sax parser
			Set ..pDSubs=tInsertDSubs_","_tOrdinal
			
			if pAction="append" {
				$$$COVERAGE("rule Na append mixed content tCHit="_tCHit_" tDHit="_tDHit)
				if tCHit,'tDHit {
					$$$COVERAGE("rule Na append mixed content tCHit and 'tDHit")
					; we are going to replace content array with DOM array
					Set:$D(tInsertDSubs) @$$$vaDOMRef(tInsertDSubs_","">R""")="c" ; this turns on replacement of Content Array by DOM array
					Set pDOMPath=$replace(pDOMPath,"~","")
					Set tSC=..domGetSubtree(.tValue1,pDOMPath,tPrevNode,tDOMSubs,tFormat,.tNSContext,tCHit,tDHit,tNamespaces)
					if $$$ISERR(tSC) quit tSC
					Set pValue=tValue1_pValue ; pValue is mixed content and tValue may be mixed content
				} else {
					$$$COVERAGE("rule Na append mixed content 'tCHit or tDHit")
				}
			}
			Set ..pOrdinal=tOrdinal
			Set ..pAfterCNode=tAfterCNode
			Set tSC=..ReadString("<pseudoRoot>"_pValue_"</pseudoRoot>",0)
			$$$vaKillCalcCache1(tInsertDSubs) ; JSL4384 part B did *not* fix regression
			$$$vaKillCalcCache1(tDOMSubs) ; JSL4384
			if $$$ISERR(tSC) quit tSC
		}
		
		if isRemove {
			; 04-27-11
			if (tDHit) {
				Set dtyp=$g(@$$$vaDOMRef(tInsertDSubs_","_tOrdinal))
				if dtyp'="",$e(dtyp)'=">" {
					Set tElemName=$P(dtyp,">",1)
					Set tElemIndex=$P(dtyp,">",2)
					;05-04-11
					do ..domRemoveElementNodes(tInsertDSubs,tOrdinal,tElemName_">"_tElemIndex)
				} elseif $e(dtyp)=">" {
					// 05-03-11
					Do ..domNodeRemove(tInsertDSubs_","_tOrdinal, tCHit, tDHit,"") 
				}
			} elseif (tCHit) {
				if isRemove {
					// 05-04-11
					if $g(isElement) {
						Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal)=tInsertIndex
						Set @$$$vaDOMRef(tDOMSubs_","">R""")=2
						Set @$$$vaDOMRef(tDOMSubs_","">I""")=tAfterCNode
					} else {
						Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal)=">T"
						Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">R""")=2
						Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">I""")=tAfterCNode
						Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">V""")=""
					}
				}
			}
			; 4-26-11
			if tCHit,'isRemove {
				Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal)=">T"
				Set @$$$vaDOMRef(tInsertDSubs_","_tOrdinal_","">V""")=$zcvt(pValue,"I","XML")
			}

		}
		if isReplace,'isRemove {
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")=1
		}
		if isReplace||clearAttributes {
			Kill @$$$vaDOMRef(tElemSubscript_","">@""")
		}
		if $L(tInsertDSubs,",")>2 {
			Set tElemName=$tr($P($P(tInsertDSubs,",",$L(tInsertDSubs,",")-1),">",2),"""","")
			Set tElemIndex=$P(tInsertDSubs,",",$L(tInsertDSubs,","))
			Set tSortSubs=$P(tInsertDSubs,",",1,$L(tInsertDSubs,",")-2)
			do ..domElementSort(tSortSubs,tElemName_">"_tElemIndex)
		}
	} elseif tInsertType="elementtext" {
		if 'isReplace,'isRemove,'isClear Set isReplaceContent=1
		Set:isClear pValue="" ; rule *Ec
		Set tElemName=$P(tInsertIndex,">",1)
		Set tOrdinal=$P(tInsertIndex,">",2)
		if tOrdinal="" Set tOrdinal=1
		Set textSub=tInsertDSubs_","">"_tElemName_""","_tOrdinal
		if ('isRemove) Set tType="text"
		if $D(tAfterCNode) Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">I""")=tAfterCNode
		if isReplaceContent,pAction="set" {
			; remove text, comment and processing instruction nodes as well as any elements
			Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(tElemSubscript_","""_kDom_""""),1,dtyp) Set:$e(kDom)=">" kDom="" q:kDom=""
				If $D(dtyp),">"'=$E(dtyp),dtyp'="" { ; it's an element node
					Set tElemName1=$P(dtyp,">",1), tElemIndex1=$P(dtyp,">",2)
					kill @$$$vaDOMRef(tElemSubscript_","">"_tElemName1_"""")
				}

				kill @$$$vaDOMRef(tElemSubscript_","""_kDom_"""")
			}
		}
		if isClear,tDHit {  ; rule *Ec
			$$$vaKillCalcCache1(tElemSubscript) ; partA JSL4384 - clear cache here did NOT fix infinite loop in regression 7:50 PM
			; remove text as well as any elements, leave attributes, comments, and processing instructions
			Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(tElemSubscript_","""_kDom_""""),1,dtyp) Set:$e(kDom)=">" kDom="" q:kDom=""
				If $D(dtyp),">"'=$E(dtyp),dtyp'="" { ; it's an element node
					Set tElemName1=$P(dtyp,">",1), tElemIndex1=$P(dtyp,">",2)
					kill @$$$vaDOMRef(tElemSubscript_","">"_tElemName1_"""")
					; 02-24-2011, since below we are killing kDom node do we shift up succeeding kDom?
					kill @$$$vaDOMRef(tElemSubscript_","_kDom)
				}
				if dtyp=">T" { ; rule *Ec, kill text nodes but leave behind comments and processing instructions
					kill @$$$vaDOMRef(tElemSubscript_","""_kDom_"""")
				}
			}
			
		}

		if 'isRemove || tCHit {
			Set finalSubscript=tFinalSubscript
			Set @$$$vaDOMRef(tInsertDSubs_","_finalSubscript)=tElemName_">"_tOrdinal
			; handle content whether mixed or non-mixed here
			if (pValue'="") {
				if (pValue'["<") { ; below is non-mixed content case, plain text, comment or instruction
					; process append 03-18-11
					Set setTextValue=1
					if pAction="append" {
						if tDHit,..DomOnlyContainsText(tDOMSubs) { 
							$$$COVERAGE("rule Ea append tDHit and content contains only text and pValue is not mixed content")
							Set pValue=..GatherDOMValue(tDOMSubs)_$zcvt(pValue,"I","XML")
						} else {
							$$$COVERAGE("rule Ea append - either not tDHit or DOM contains mixed content and pValue is not mixed content")
							if (tCHit||tDHit) {
								Set tSC=..domGetSubtree(.tValue1,pDOMPath,tContentSubs,tDOMSubs,tFormat,.tNSContext,tCHit,tDHit,tNamespaces)
								if $$$ISERR(tSC) quit tSC
							} else {
								Set tValue1=""
							}
							Set pValue=$g(tValue1)_pValue
							Set ..pDSubs=textSub_","_textOrdinal
							Set ..pOrdinal=textOrdinal
							Set tSC=..ReadString("<pseudoRoot>"_pValue_"</pseudoRoot>",1)
							;b:(pValue["mixed")
							if $$$ISERR(tSC) quit tSC
							Set setTextValue=0
						}
					}
					if (setTextValue) {
						Set @$$$vaDOMRef(textSub_","_textOrdinal)=$Case(tType,"text":">T","comment":">C","instruction":">I",:">U")
						Set @$$$vaDOMRef(textSub_","_textOrdinal_","">V""")=$zcvt(pValue,"I","XML")
						Set @$$$vaDOMRef(textSub_","_textOrdinal_","">I""")="+"_$g(textAfterCNode)
					}
				} else {
					; mixed content which involves elements, set up pDSub for DOMSaxContentHandler, call Sax parser
					if pAction="append" {
						; the following will not work if Content array has mixed content (xml) under tContentSubs
						; the below only works if we appending content to plain text
						if tCHit,'tDHit,..ContentOnlyContainsText(tContentSubs),$D(@$$$vaContentRef(0)) {
							$$$COVERAGE("rule Ea append tCHit and 'tDHit and content contains only text and pValue is MIXED content")
							// 01-31-12
							Set cNode="" For { Set cNode=$S(""=tContentSubs:"", 1:$$$domGetNextChild(..%ContentRef,tContentSubs,cNode))  Quit:""=cNode
								Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
								Continue:$$$xmlTEXTNODE'=ctyp ; not a text node
								Set pNodeValue=$$$xmlGetNodeValue(..%ContentRef,cNode)
								Set pValue=pNodeValue_pValue
							}
						}
						if tDHit,..DomOnlyContainsText(tDOMSubs) { 
							$$$COVERAGE("rule Ea append tDHit and content contains only text and pValue is MIXED content")
							Set pValue=..GatherDOMValue(tDOMSubs)_pValue
						} else {
							$$$COVERAGE("rule Ea append - either not tDHit or DOM contains mixed content and pValue is mixed content")
							if (tDHit) {
								$$$COVERAGE("rule Ea append - tDHit and DOM contains mixed content and pValue is mixed content")
								Set tSC=..domGetSubtree(.tValue1,pDOMPath,tContentSubs,tDOMSubs,tFormat,.tNSContext,tCHit,tDHit,tNamespaces)
								if $$$ISERR(tSC) quit tSC
							} else {
								$$$COVERAGE("rule Ea append - no tDHit and DOM contains mixed or text-only content and pValue is mixed content")
							}
							Set pValue=$g(tValue1)_pValue 
						}

					}
					Set ..pDSubs=textSub_","_textOrdinal
					Set ..pOrdinal=textOrdinal
					Set tSC=..ReadString("<pseudoRoot>"_pValue_"</pseudoRoot>",1)
					if $$$ISERR(tSC) quit tSC
				}
			}
		}
		if isRemove {
			do ..domElementRemove($g(tInsertDSubs),$g(tFinalSubscript),tElemSubscript,tCHit,tDHit)
		}
		if isReplace,tCHit {
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")=1
		}
		if isReplaceContent,tCHit {
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")="c"
		}
		if isClear,tCHit { ; rule *Ec
			Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">R""")="d"
		}

		if isReplace||clearAttributes {
			Kill @$$$vaDOMRef(tElemSubscript_","">@""")
		}
		do ..domElementSort(tInsertDSubs,tElemName_">"_tOrdinal)
	} elseif tInsertType="elementfunction" {
		; an element function is a text(), comment() or instruction() function
		; it can't be the function element()
		Set tElemName=$P(tInsertIndex,">",1)
		if (tElemName="") quit $$$ERROR($$$EnsErrGeneral,"Cannot set element function at non-element")
		Set tOrdinal=$P(tInsertIndex,">",2)
		if tOrdinal="" Set tOrdinal=1
		Set textSub=tInsertDSubs_","">"_tElemName_""","_tOrdinal
		if ('isRemove)||tCHit {
			Set @$$$vaDOMRef(tInsertDSubs_","_tFinalSubscript)=tElemName_">"_tOrdinal
			if $D(tAfterCNode) Set:$D(tElemSubscript) @$$$vaDOMRef(tElemSubscript_","">I""")=tAfterCNode
			Set tOldTextValue="" ; used for append
			if (pAction="append") {
				Set oldType=$g(@$$$vaDOMRef(textSub_","_textOrdinal))
				if oldType="",tCNodeTextHit {
					; make sure we are appending after text
					Set oldCNodeType=$$$xmlGetNodeType(..%ContentRef,tCurrentNode)
					if oldCNodeType'=$$$xmlTEXTNODE {
						quit $$$ERROR($$$EnsErrGeneral,"Cannot append at "_pDOMPath_" node because node in original content and is not a text node")
					} else {
						Set oldType=">T"
					}
					
				}
				Set newType=$Case(tType,"text":">T","comment":">C","instruction":">I",:">U")
				Set oldTypeName=$Case(oldType,">T":"text",">C":"comment",">I":"instruction",:"Unknown")
				if oldType'=newType {
					quit $$$ERROR($$$EnsErrGeneral,"Cannot append at "_pDOMPath_" node because node is node of another type, trying to append node of type "_tType_" to node of type "_oldTypeName)
				}
				if tCHit,'tDHit {
					if $e($g(textAfterCNode))'="+" Set textAfterCNode="+"_$g(textAfterCNode)
				}
				if tDHit {
					Set tOldTextValue=$g(@$$$vaDOMRef(textSub_","_textOrdinal_","">V"""))
				}
			}
			Set @$$$vaDOMRef(textSub_","_textOrdinal)=$Case(tType,"text":">T","comment":">C","instruction":">I",:">U")
			Set:pAction="clear" pValue=""
			if $e(pValue,1,$L("<![CDATA["))="<![CDATA[",$e(pValue,$L(pValue)-$L("]]>")+1,*)="]]>" {
				Set tValue=$e(pValue,$L("<![CDATA[")+1,*)
				Set tValue=$e(tValue,1,$L(tValue)-$L("]]>"))
			} else {
				Set tValue=$zcvt(pValue,"I","XML")
			}
			Set @$$$vaDOMRef(textSub_","_textOrdinal_","">V""")=tOldTextValue_tValue
			if 'isRemove,textAfterCNode="" Set textAfterCNode="+"_textAfterCNode
			Set @$$$vaDOMRef(textSub_","_textOrdinal_","">I""")=$g(textAfterCNode)
			// 10-14-11
			if (tElemName="/") {
				Set tCNode=$$$xmlGetDocumentElement(..%ContentRef)
				Set topDSubs=","">/"""
				Set topCSubs=tCNode
				Set byName=1
				Set tNonExistent=0
				Set isTypeElement=1
				Set tCHit=1
				Set tIgnoreNamespaces=0
				Set topCNode=""
				;DOMCache(1)="/>1"
				;*DOMCache(">/",2)="root>1"
				;DOMCache(">/",1,1)=">I"
				;DOMCache(">/",1,1,">I")="+"
				;DOMCache(">/",1,1,">V")="xml-stylesheet type=""text/xsl"" href=""vhitg-cda-v3.xsl"""
				;*DOMCache(">/",">root",1,">I")="+"
				Set @$$$vaDOMRef(textSub_","_textOrdinal_","">I""")="+"
			}
		}
		if isRemove {
			; removing a text node
			Do ..domNodeRemove(textSub_","_textOrdinal, tCHit, tDHit,"") 
		}
		do ..domElementSort(tInsertDSubs,tElemName_">"_tOrdinal)

		do ..domNonElementSort(textSub,textOrdinal)
	}


	Quit:tInsertType="" $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid operation.")
	Quit $$$OK
}

Method domParsePathElem(pDOMPath As %String, ByRef pElem As %String, pNextElem As %String, pMode As %String, ByRef pIndex As %String, Output pIsNodeIndex As %Boolean, Output pIsInsert As %Boolean, Output pFinal As %Boolean, Output pElemIgnoreNamespaces As %Boolean) As %Status [ Internal ]
{
 /*
DOMPaths - subscripts - meaning
 (note - subscripts for element names have '>' prefix for simplified collation vs. node numbers)
  /       - the entire XML document under root node, including open/close tags, attributes, and subtree content
  /full() - ditto - the entire XML document under root node, including open/close tags, attributes, and subtree content
  ""      - "" - ditto, but not allowed where a distinction with PropPaths is needed
  /name() -  - name of root element; does not exist (top element is child of root)
  /node-type() -  - type of root element = 'root'
  /comment() -  - first comment of root
  /comment()[3] -  - third comment of root
  /[1]    -  - content of the first child element of root = top element = ElemA (note any other ordinal is invalid)
  /1      -  - ditto
  /[-]    -  - ditto (because as top the last element =1 as well)
  /-      -  - ditto
  /1/full() -  - the first child element of root = top element = ElemA including open/close tags, attributes, and subtree content
  /1[1]   -  - invalid
  /-[1]   -  - invalid
  /[*]    -  - element position of last child element of root (=1)
  /*      -  - ditto
  /last() -  - ditto (same as count())
  /[$*]        -  - node position of last child node of root
  /$*          -  - ditto
  /node-last() -  - ditto (same as node-count())
  /ElemA        - ">ElemA",1 - content within ElemA
  /ElemA[1]     -  - ditto (because ElemA is top, only 1 is valid; no siblings here)
  /ElemA[-]     -  - ditto (because as top the last instance of ElemA =1 as well)
  /ElemA[*]     -  - position of last ElemA element in root
  /ElemA.*      -  - ditto
  /ElemA.last() -  - ditto (same as .count())
  /ElemA/[1]    - ">ElemA",1,1-> - value at first child element of ElemA
  /ElemA/1      -  - ditto
  /ElemA/[$1]   -  - value at first child node of ElemA
  /ElemA/$1     -  - ditto
  /ElemA[1]/[-]  -  - value at last child element of ElemA
  /ElemA[1]/-    -  - ditto
  /ElemA[1]/[$-] -  - value at last child node of ElemA
  /ElemA[1]/$-   -  - ditto
  /ElemA[1]/[*]    -  - last child element position in ElemA
  /ElemA[1]/*      -  - ditto
  /ElemA[1]/last() -  - ditto (same as count())
  /ElemA[1]/[$*]   -  - count of child nodes of ElemA including elements, comments, text nodes, and processing instructions; not attributes
  /ElemA[1]/$*     -  - ditto
  /ElemA[1]/node-last() -  - ditto (same as node-count())
  /ElemA/comment()     - ">ElemA",1,n(1st type='comment') - first comment in ElemA
  /ElemA/comment()[2]  - ">ElemA",1,n(2nd type='comment') - second comment in ElemA
  /ElemA/comment()[-]  -  - last comment in ElemA
  /ElemA/text()        - ">ElemA",1,n(1st type='text') - first text node in ElemA
  /ElemA/text()[2]     - ">ElemA",1,n(2nd type='text') - second text node in ElemA
  /ElemA/text()[-]     -  - last text node in ElemA
  /ElemA/instruction() - ">ElemA",1,n(1st type='instr') - first processing instruction in ElemA
  /ElemA/element()[3]  -  - third element in ElemA
  /ElemA/[3]           -  - ditto
  /ElemA/element()[$3] -  - element at third node position in ElemA; error if node 3 is not an element
  /ElemA/name()          -  - full name of node (= e.g. tempuri:ElemA)
  /ElemA/local-name()    -  - simple local name of node (= ElemA)
  /ElemA/prefix()        -  - namespace prefix part of node name (= e.g. tempuri)
  /ElemA/namespace-uri() -  - full namespace part of top node name (= e.g. http://tempuri.org)
  /ElemA/prefixes()      -  - a comma-separated list of the namespace prefixes and their corresponding URI's, separated by an = sign, in scope at the context of the given node (ElemA), with the default URI listed first with a blank prefix. E.g. "=http://tempuri.org, ex=http://www.example.com/example"
  /ElemA[n]/position()   -  - element position of n'th ElemA in root
  /ElemA/node-position() -  - node position of ElemA in root
  /ElemA/node-type()  -  - node type of ElemA = 'element'
  /ElemA/ElemB        - ">ElemA",1,">ElemB",1 - content within first instance of ElemB in ElemA
  /ElemA/ElemB[1]     -  - ditto
  /ElemA/ElemB[1]/full() -  - first instance of ElemB in ElemA, with its element open/close tags, attributes, and subtree content
  /ElemA/ElemB[-]     -  - full content within last instance of ElemB in ElemA
  /ElemA/ElemB[*]     -  - count of all ElemB elements in ElemA
  /ElemA/ElemB.last() -  - ditto (same as .count())
  /ElemA/ElemB.*      -  - ditto
  /ElemA/ElemB/[1]    - ">ElemA",1,">ElemB",1,1-> - value at first child element of ElemB
  /ElemA/ElemB/1      -  - ditto
  /ElemA/ElemB/[-]    -  - value at last child element of ElemB
  /ElemA/ElemB/-      -  - ditto
  /ElemA/ElemB/[*]    -  - count of child elements of ElemB (same as count())
  /ElemA/ElemB/*      -  - ditto
  /ElemA/ElemB/last() -  - ditto
  /ElemA/ElemB/[$1]   -  - value at first child node of ElemB
  /ElemA/ElemB/$1     -  - ditto
  /ElemA/ElemB/[$-]   -  - value at last child node of ElemB
  /ElemA/ElemB/$-     -  - ditto
  /ElemA/ElemB/[$*]   -  - count of child nodes of ElemB including elements, comments, text nodes, and processing instructions; not attributes
  /ElemA/ElemB/$*     -  - ditto
  /ElemA/ElemB/node-last() -  - ditto (same as node-count())
  /ElemA/ElemB/@Attr1 -  - value of Attr1 of second ElemB element in ElemA
  /ElemA/ElemB[2]/@Attr1 - ">ElemA",1,">ElemB",2,">@",">Attr1" - value of Attr1 of second ElemB element in ElemA
  /1/ElemB[2]/-/@Attr1   - n(1st type='elem')->">ElemB",2,m(last type='elem')->,">@",">Attr1" - value of Attr1 of last child element of second ElemB element in 1st top element (ElemA)
  /ElemA/[1]/@Attr1 -  - value of Attr1 of first child element of ElemA
  /ElemA/1/@Attr1   -  - ditto
  /ElemA/1/@[1]     - ">ElemA",1,1->,">@",1-> - value of first attribute of first child of ElemA
  /ElemA/1/@1       -  - ditto
  /ElemA/1/@[-]     -  - value of last attribute of first child of ElemA
  /ElemA/1/@-       -  - ditto
  /ElemA/1/@[*]     -  - count of attributes of first child of ElemA
  /ElemA/1/@*       -  - ditto
  /ElemA/1/@.*      -  - ditto
  /ElemA/1/@.last() -  - ditto (same as .count())
  /ElemA/1/@/last() -  - ditto (same as count())
 
 Set's only:
 For assignments to an element the assignment value becomes (or is appended to in the case of 'append' assignments) the full content sub-tree within the referenced existing or newly created element.
  /ElemA/ElemB[]/@Attr1 - implied iteration; set Attr1 for all ElemB elements in ElemA
  /ElemA/[]/@Attr1 - implied iteration; set Attr1 for all elements in ElemA
  /ElemA/ElemB[~]/@Attr1 - append; set Attr1 for a new ElemB element in ElemA
  /ElemA/ElemB[~3]/@Attr1 - insert; set Attr1 for a new ElemB element between existing ElemB element 2 and ElemB element 3 in ElemA
  /ElemA/ElemB[$3]/@Attr1  - set Attr1 for existing ElemB at node position 3. If node at position 3 does not exist, create ElemB. If it exists and is not ElemB, fail.
  /ElemA/ElemB[~$3]/@Attr1  - insert; set Attr1 for a new ElemB element between existing node 2 and node 3 in ElemA
  /ElemA/[~3]/@Attr1        - invalid; no element type specified for new element
  /ElemA/element(ElemB)[~]   - append new ElemB element after last existing element in ElemA and assign its content
  /ElemA/ElemB[~]            - append new ElemB element after last existing ElemB element in ElemA and assign its content (ditto: we always append after the last node)
  /ElemA/element(ElemB)[$~]  - append new ElemB element after last existing node in ElemA and assign its content (ditto: we always append after the last node)
  /ElemA/element(ElemB)[~3]  - insert new ElemB element at third element position in ElemA and assign its content; error if elements 1 and 2 don't exist
  /ElemA/ElemB[~3]           - insert new ElemB element after 2nd ElemB element in ElemA and assign its content. Create 1st and 2nd if needed.
  /ElemA/ElemB[~$3]          - insert new ElemB element at third node position in ElemA and assign its content; error if nodes 1 and 2 don't exist
  /ElemA/element(ElemB)[~$3] - forbidden
  /ElemA/comment()      - set comment text for the first comment node in ElemA
  /ElemA/comment()[-]   - set comment text for the last comment node in ElemA
  /ElemA/comment()[~]   - set comment text for a new final comment node in ElemA
  /ElemA/comment()[$3]  - set comment text for existing comment node position 3. If node at position 3 does not exist, create comment. If it exists and is not a comment, fail.
  /ElemA/comment()[~3]  - insert; set comment text for a new comment node between existing comment 2 and comment 3 in ElemA
  /ElemA/comment()[~$3] - insert; set comment text for a new comment node between existing node 2 and node 3 in ElemA

 Notes about Set's:
 If the element being implicitly created requires parents they are also implicitly created. However no new top node may be created.
 If the element being implicitly created requires earlier siblings they are also implicitly created.
 */
	Set (pIsNodeIndex,pIsInsert,pFinal,pElemIgnoreNamespaces)=0
	if ($e(pDOMPath,1,2)="*:")&&(pMode="set") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because initial '*:' says to ignore namespaces on a set")
	if pElem["][" Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because there are too many brackets in '"_pElem_"'")
	if pElem["," Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because there are commas in '"_pElem_"'")
	Set pIndex=$P(pElem,"[",2), pElem=$P(pElem,"[",1), tIndexBase=$S(""=pIndex:"",1:"["_pIndex)
	;Set pElem=..NormalizeElementNamespacePrefix(pElem)
	If ""'=pIndex && ("]"'=$E(pIndex,*)) Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid index brackets format in '"_tIndexBase_"'")
	Set pIndex=$E(pIndex,1,*-1)
	Set:".*"=$E(pElem,*+1-$L(".*"),*)&&(""=tIndexBase) pIndex="*", tIndexBase=".*", pElem=$E(pElem,1,*-$L(".*")) ; special handling for .*
	Set:".last()"=$E(pElem,*+1-$L(".last()"),*)&&(""=tIndexBase) pIndex="*", tIndexBase=".last()", pElem=$E(pElem,1,*-$L(".last()")) ; special handling for .last()
	Set:".count()"=$E(pElem,*+1-$L(".count()"),*)&&(""=tIndexBase) pIndex="*", tIndexBase=".count()", pElem=$E(pElem,1,*-$L(".count()")) ; special handling for .count()
	If (""=pElem)&&(""=tIndexBase) {
		Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of empty element in '//'")
	}

	Set:(""=pElem)&&(""'=pIndex) pElem=pIndex, pIndex="" ; if only [n] make it a numeric element not an index
	If (pElem="~$")||(pElem="$~") { 
		Set pIndex=""
		Set pElem=""
		Set pIsInsert=1
		Set pIsNodeIndex=1
		quit $$$OK
	} ElseIf pElem?0.1"~"1(0.1"$"1.N,0.1"$"1"-",0.1"$"1"*") {
		#; Element is numeric
		If ""'=pIndex Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid element format in '"_pElem_tIndexBase_"'")
		Set pIndex=pElem, pElem=""
		Set:""=tIndexBase tIndexBase="/"_pIndex_"/"
	} ElseIf "@"=$E(pElem) {
		#; Element is attribute
		Set pElem=$E(pElem,2,*)
		if ($E(pElem)="$")&&($E(pElem,2,*)=+$E(pElem,2,*)) {
			; attribute is of the form $number which means it is a namespace ordinal
			Set pElem="@xmlns:"_pElem
		}
		ElseIf pElem?0.1"~"1(0.1"$"1.N,1"-",1"*") {
			#; Attribute is numeric
			Set pIndex=pElem, pElem="@", tIndexBase="/"_pIndex_"/"
			If ""=pIndex&&(pMode="get") {
				If ""'=tIndexBase Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of implied iteration on attribute '"_pElem_tIndexBase_"'")
				Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of anonymous attribute '"_pElem_tIndexBase_"'")
			}
		} Else {
			#; Attribute is a name
			If ""=pElem&&(""=tIndexBase) Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of empty attribute in '/@/'")
			If ""'=pElem {
				If (""=pIndex)&&(pMode="get") {
					If ""'=tIndexBase Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of implied iteration on attribute '"_pElem_tIndexBase_"'")
					Set pIndex=1
				}
				If pIndex'=1&&(pMode="get") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because index '"_pIndex_"' in '"_pElem_tIndexBase_"' is not 1")
			}
			Set pElem="@"_pElem
		}
	} Else {
		#; Element is a name
		Set:""=pIndex pIndex=1
		; 11-10-10
		if pElem["(","/full()"'=$E(pDOMPath,*+1-$L("/full()"),*),$e(pNextElem)'="@",pNextElem'="name()" set pFinal=1
		if $e(pNextElem)="@",pNextElem'=$E(pDOMPath,*+1-$L(pNextElem),*) Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because attribute '"_pNextElem_"' does not terminate DOM path")
		if ($e(pElem,1,2)="*:")&&(pMode="set") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because element '"_pElem_tIndexBase_"' says to ignore namespaces but we are doing a set")
		if ($e(pElem,1,2)="*:") Set pElem=$e(pElem,3,*),pElemIgnoreNamespaces=1
	}
	Set pIsInsert=0  Set:"~"=$E(pIndex) pIsInsert=1, pIndex=$E(pIndex,2,*)
	#; 08-31-10, following fixes problem of inserting after wrong node JSL
	Set pIsNodeIndex=0  Set:"$"=$E(pIndex) pIsNodeIndex=1, pIndex=$E(pIndex,2,*)
	Set:"~"=$E(pIndex)&&'pIsInsert pIsInsert=1, pIndex=$E(pIndex,2,*) ; support both $~ and ~$n
	If pIsInsert&&(pMode="get") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of ~ in 'get' mode")
	If ""=pIndex&&(pMode="get") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of implied iteration in 'get' mode: '"_pElem_tIndexBase_"'")
	If "*"=pIndex&&(pMode="set") Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate '*' count in DOM path '"_pDOMPath_"' in 'set' mode: '"_pElem_tIndexBase_"'")
	If pIsInsert=1&&((pNextElem'="")&&($e(pNextElem)'="@")) Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because ~ is not in last position which is non-attribute, last position="_pNextElem)
	If $Case(pIndex,"-":0,"*":0,"":0,:1) {
		If pIndex'?1.N || 'pIndex Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid index number format in '"_tIndexBase_"'")
	}
	Set pElem=$tr(pElem,"~",".") // JSL4319 because prop path properties are separated by periods, we need to translate ~ (which is used instead of period in prop paths) to . (period)
	Quit $$$OK
}

/// Parse a DOM path and return a reference into ..%DOMCache for the given node's parent, plus the node index
/// pNodeIndex can be returned as: empty, node position, ~node position (for insert), or count (for count queries).
/// pAfterCNode is only relevant when we are doing an insert and represents the node in the Content Array to the left of the node being inserted
/// in the case where the item to the left is also in the DOM array, the current implementation is incomplete (JSL 08-26-10)
/// In some cases, the current implementation is incomplete (JSL 08-26-10)
Method domParsePath(pDOMPath As %String, pMode As %String, Output pCSubs As %String, Output pDSubs As %String, Output pNodeType As %String, Output pNodeIndex As %String, Output pNodeValue As %String, Output pNSContext As %String, Output pAfterCNode, Output pFinalSubscript, Output pInsertDSubs, Output pInsertIndex, Output pCHit As %Boolean, Output pDHit As %Boolean, Output pInsertType As %String, Output pTextOrdinal As %String = 1, Output pTextAfterCNode, Output pTextSubscript, Output pInsertSubscript, Output pCNamespace As %Integer, pFormat As %String, Output pNamespaces, pAction As %String = "", Output pPrevNode As %String, Output pCurrentNode As %String, Output pCNodeTextHit As %Boolean, Output pElemSubscript, Output tNode, Output isElement, Output tCHitPrev, Output tDHitPrev, pValue As %String) As %Status [ Internal ]
{
	//#define COVERAGE(%x) w !,"COVERAGE",%x,! Set ^ISC.Coverage(%x)=1
	#define COVERAGE(%x)

#define NamespaceSource(%x,%y) $$$xmlParentNode(%x,%y)
#define isNodeElement(%x,%y) ($$$xmlGetNodeType(%x,%y)=$$$xmlELEMENTNODE)

	#dim tIgnoreNamespaces As %Boolean
	#dim tElemIgnoreNamespaces As %Boolean
	#dim tMatchedElemName As %String

	Set (pNodeIndex,pNodeType,pNodeValue,pNSContext,pDSubs)="", pCSubs=0
	Set tSC=$$$OK, (tFinal,tDone,tReplace,tRemove,tCHit,tDHit,pCHit,pDHit)=0
	Set tIgnoreNamespaces=$G(pNSContext("ign"),0)
	if $E(pDOMPath,1,2)="*:" {
		Set tIgnoreNamespaces=1
		Set pDOMPath=$E(pDOMPath,3,*)
	}
	Set pNamespaces=##class(NamespaceHelper).%New()
	If $E(pDOMPath)'="/" Quit $$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid format")
	Set pNSContext("level")=0 ; for namespaces
	Set tNonExistent=0
	if (pMode="set") {
		Set pos=1
		;Set pDSubs=","">/"",1"
	} else {
		Set pDSubs=","">/"",1"
		Set pos=2
	}
	Set PassedPseudoRoot=0
	Set isElement=0
	//+ Prodlog 102581
	Set tLastElem=$P(pDOMPath,"/",$L(pDOMPath,"/"))
	if $e(tLastElem)="@" {
		Set tLastElemIsAttribute=1
	} else {
		Set tLastElemIsAttribute=0
	}
	//- Prodlog 102581
	Set tFinal=0,pieceIndex=1  
	Set parentDOMPath=$P(pDOMPath,"/",1,$L(pDOMPath,"/")-1)
	if parentDOMPath'="",$D(^||ISC.XML.VDOC.ParseCache(i%%ParseCache,parentDOMPath),v),$LG(v,1) {
		Set pos=$LG(v,1)
		Set tGrandFatherPCSubs=$LG(v,2)
		Set tGrandFatherPDSubs=$LG(v,3)
		Set tOldElemPreParse=$LG(v,4)
		Set tOldElem=$LG(v,5)
		Set tOldElemIgnoreNamespaces=$LG(v,6)
		Set tOldIndex=$LG(v,7)
		Set tOldtNode=$LG(v,8)
		Set tOldPCSubs=$LG(v,9)
		Set tOldPDSubs=$LG(v,10)
		Set pDSubs=$LG(v,11)
		Set pCSubs=$LG(v,12)
		Set pieceIndex=$LG(v,13)
		Set tCHit=$LG(v,14)
		Set tDHit=$LG(v,15)
		Set PassedPseudoRoot=$LG(v,16)
		Set alreadyCalculated=$LG(v,17)
		Set pPrevNode=$LG(v,18)
		Set ..%SkipFind=$LG(v,19)
	}
	For { Quit:'pos  Set oldpos=pos, pos=$F(pDOMPath,"/",oldpos)
		Set tPos=pos
		Set ..%SkipFind=0 ; if inserting at end we set to 1
		Set pieceIndex=pieceIndex+1
		Set tPieceIndex=pieceIndex
		If 'pos { 
			Set tElem=..NormalizeElementNamespacePrefix($E(pDOMPath,oldpos,*),.tSC,tIgnoreNamespaces)
			If $$$ISERR(tSC) quit
			Set tDOMPathToPos=..NormalizeNamespacePrefix($E(pDOMPath,1,*),.tSC,tIgnoreNamespaces)
			If $$$ISERR(tSC) quit
		}
		Else { 
			Set tElem=..NormalizeElementNamespacePrefix($E(pDOMPath,oldpos,pos-2),.tSC,tIgnoreNamespaces)
			If $$$ISERR(tSC) quit
			Set tDOMPathToPos=..NormalizeNamespacePrefix($E(pDOMPath,1,pos-2),.tSC,tIgnoreNamespaces)
			If $$$ISERR(tSC) quit
		}
		Set tElemPreParse=tElem
		Set tLastElem='pos
		Quit:""=tElem&&tLastElem
		If (""=tElem) && ("get"=pMode) Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of implied iteration in 'get' mode: '//'")  Quit
		Set tCHitPrev=tCHit
		Set tDHitPrev=tDHit
		Set tIsElementPrev=isElement
		Set (tReplace,tRemove,tCHit,tDHit)=0 
		Set alreadyCalculated=0
		Set prevCNode=""
		kill Count
		if pos {
			Set newpos=$F(pDOMPath,"/",pos)
			If 'newpos { Set tNextElem=$E(pDOMPath,pos,*) }
			Else { Set tNextElem=$E(pDOMPath,pos,newpos-2) }
		} else {
			Set tNextElem=""
		}
		// strip intermediate element() if not a node.  This leg must be done before we use domParsePathElem which will change tElem 
		// strip element(...) in middle
		// in middle if
		// not last element just before a function
		// and
		// not last element
		Set lastElement=0
		Set:tNextElem="" lastElement=1
		Set lastElementBeforeFunction=0
		Set:tNextElem'="" lastElementBeforeFunction=(",element,"[(","_$P(tElem,"(")_","))&&(tNextElem[")")&&(tNextElem'["element(")
		if 'lastElement&&'lastElementBeforeFunction && (tElem["element(") { // strip element in middle JSL4290
			Set tOrig=tElem
			Set tOrig=$P(tOrig,"(",2) // strip off element(
			Set tOrigElementName=$P(tOrig,")",1) // if originally element(A)... pick off the A
			Set tOrigIndex=$P(tOrig,")",2)
			if tOrigElementName'="" || (tOrigIndex'=""),tOrigIndex'["$" { // don't allow expressions with node numbers to have "element" stripped
				Set tElem=tOrigElementName_tOrigIndex
			}
		}
		if (oldpos'=1) {
			Set tSC=..domParsePathElem(pDOMPath,.tElem,tNextElem,pMode,.tIndex,.tNode,.tInsert,.tFinal,.tElemIgnoreNamespaces)  Quit:$$$ISERR(tSC)
			if ($D(@$$$vaContentRef(0))),PassedPseudoRoot=1 { ; is ContentArray empty?
				Set pCSubs=0 ; magic number
				Set PassedPseudoRoot=0
			}
		} else {
			Set tElem="/"
			Set tIndex=1
			Set tInsert=0
			Set pieceIndex=1
			Set pos=2
			Set tFinal=0
			Set PassedPseudoRoot=1
			Set tNode=0
			if ($e(pDOMPath,1,2)="*:") {
				Set tElemIgnoreNamespaces=1
			} else {
				Set tElemIgnoreNamespaces=0				
			}
		}
		; restore this restriction on 04-09-11 because restriction needed and does not reduce functionality
		If tFinal&&'tLastElem Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of extra element after function '"_tElem_"'")  Quit
		Set tFinalBeforeAttribute=0
		if pos'=0,oldpos'=1 if $e($P(pDOMPath,"/",pieceIndex+1))="@" Set tFinalBeforeAttribute=1
		Set tFinalBeforeEnd=0
		if pos=0 Set tFinalBeforeEnd=1
		; check if final operation is a function other than element
		Set pos1=$F(pDOMPath,"/",pos)
		If 'pos1 { Set tElem1=$E(pDOMPath,pos,*) }
		Else { Set tElem1=$E(pDOMPath,pos,pos1-2) }
		Set tOldIsFunction=(",comment,text,instruction,"[(","_$g(tOldElem)_","))&&(tOldElemPreParse["(")
		Set tIsFunction=0
		Set tElem1PreParse=tElem1
		if oldpos'=1,(tElem1'="") {
			Set tSC=..domParsePathElem(pDOMPath,.tElem1,"",pMode,.tIndex1,.tNode1,.tInsert1,.tFinal1,.tElemIgnoreNamespaces1) Quit:$$$ISERR(tSC)
			Set tElem1=$P(tElem1,"(",1)
			Set tIsFunction=(",comment,text,instruction,"[(","_tElem1_","))&&(tElem1PreParse["(")
		}
		Set tOperateOnSet=tFinalBeforeEnd||tFinalBeforeAttribute||tIsFunction
		Set tInsertOrAppend=tInsert||((tOperateOnSet&&(pMode="set")&&(pAction="append")))
		; 04-11-11 below
		if tElem["(",pMode="set",$P(tElem,"(")="element" {
			//if 'tInsert Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because using element requires an insert, i.e., ~ '"_tElem_"'")  Quit
			if tNode Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because element function cannot be used to set at node ordinal, i.e., $n '"_tElem_"'")  Quit
		}
		if $D(pNSContext("level")),'tIsFunction {
			do ..domGetNamespaces(pNamespaces,$g(pCSubs),$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext,$g(pFormat))
		}
		If "@"=$E(tElem) {
			Set tNamespaceSubs = pDSubs // used for namespace-uri() function 10-10-2012

			Set tAttrName=tElem // use in name() function
			If tOldIsFunction Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because a function cannot be combined with an attribute '"_tElem_"'")  Quit
			If tElem="@" && (pMode="set") && (tIndex="") {
				; iteration on attributes
				Set pNodeType="@[]"
				Quit
			}
			Set pNodeType=tElem, tElemBase=tElem, tElem=$E(tElem,2,*)
			Set (tCHit,tDHit,tPlus)=0
			If tIndex="*" {
				; count of attributes
				Set tSC=..domGetAttrs(.tPrefixes,.tAttrs,pCSubs,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),$g(pFormat),.pNSContext,tCHitPrev,tDHitPrev,.tAttrCount)  Quit:$$$ISERR(tSC) 
				Set pNodeValue=tAttrCount
				Set pNodeType="ordinal"
			}
			ElseIf ""=tElem {
				#; Find Attribute by number
				// !!! iterate through both D and C, counting as we go (D index is local but the @ index must count both D and C)
				Set tSC=..domGetAttrs(.tPrefixes,.tAttrs,pCSubs,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),$g(pFormat),.pNSContext,tCHitPrev,tDHitPrev,.tAttrCount)  Quit:$$$ISERR(tSC) 	
				if (tIndex="-") { ; last attribute
					// 11-03-11
					Set tIndex = tAttrCount
				}
				$$$ASSERT(tIndex=+tIndex)
				if (tIndex > tAttrCount) Set tSC=$$$ERROR($$$EnsErrGeneral,tIndex_" is greater than attribute count "_tAttrCount_" so can't evaluate DOM path '"_pDOMPath_"'") Quit

				Set tSC=..domGetAttrs(.DummyPrefixes,.Dummy,pCSubs,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),$g(pFormat),.pNSContext,tCHitPrev,tDHitPrev,.tAttrCount, "","",tIndex,.tName,.tValue,$s(pAction'="get":1,1:0))
				Set tAttrName=tName // used in name() function 10-10-2012
				if (tName'="") {
					Set pNodeValue=tValue
				}
				Set tSaveDSubs=pDSubs
				Set pDSubs=pDSubs_","">@"","">"_tName_""""
				Set tElem=$P($G(@$$$vaDOMRef(pDSubs_","">@"","_tIndex)),">",1)
				Set:""'=tElem pDSubs=pDSubs_","">@"","">"_tElem_""""
			} Else {
				#; Find an Attribute by name
				if pMode="get" $$$ASSERT(tIndex=1)
			}
			If ""'=tElem {
				Set tSaveDSubs=pDSubs
				Set pDSubs=pDSubs_","">@"","">"_tElem_""""

				Set tDone=1
				If $D(@$$$vaDOMRef(pDSubs),pNodeValue) {
					Set tReplace=1 ; not needed; always implied: $G(@$$$vaDOMRef(pDSubs_","">R"""))
				}
				If 'tReplace {
					// 01-31-12a
					if tElem[":" {
						if pCSubs'="" Set pNodeValue=$$$xmlGetAttribute(..%ContentRef,pCSubs,$P(tElem,":",2))
					} else {
						// attribute getting bug 110819 - "o" not applied correctly to XML special characters
						if pCSubs'="" Set pNodeValue=$$$CONDXMLESCAPE($g(pFormat),$$$xmlGetAttribute(..%ContentRef,pCSubs,tElem))
					}
					
				}
			}
		} ElseIf ""=tElem {
			If tNode {
				#; Find a node by number
				#; try first in DOMCache
				Set (tDone)=0, (tCount,tChildCount)=""
				#; find index and child count of the specified DOM node
				If "*"=tIndex {
					Set tNCount=..domGetNodeCounts(pDSubs,pCSubs,"",.pNSContext)
					Set pNodeValue=tNCount
					Set pNodeType="ordinal"
					Set (tDHit,tDone)=1
				} ElseIf "-"=tIndex || (""=tIndex && tInsert) {
					#; find the last DOM node or Content node if any
					If tInsert||((pMode="set")&&(tOperateOnSet=1)) { 
						if 'tInsert,pAction="set",'tIsFunction,'tLastElemIsAttribute set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because one cannot set an element node directly.  One must use a 'remove' followed by an insert using ~ or 'append'")  Quit
						Set pInsertDSubs=pDSubs
						Set isTypeElement=0
						Set Existing=0
						; 05-02-11
						; 11-07-11
						// 11-17-2011
						Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
						Set tReturnElem=""
						if (tOutputType="element") {
							Set:tDHit tReturnElem=tElemName
							Set:tCHit tReturnElem=$$$xmlGetNodeValue(..%ContentRef,tCNode)
						}
						if tNonExistent Set tCNode=""
						if pAction'="remove" Do ..domSlideNodes(pDSubs,kDom,.tHighestIndex)  Quit:$$$ISERR(tSC)  
						Set pInsertType="textinsert"
						; 10-08-10 work in progress
						; 03-24-11 add support for Append
						if pAction'="append",'tInsert {
							Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_kDom)
						} else {
							Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_tHighestIndex)
						}
						if pAction'="append",'tInsert {
							Set pFinalSubscript=kDom
						} else {
							Set pFinalSubscript=tHighestIndex
						}
						if pAction'="append",'tInsert {
							Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_kDom)
						} else {
							Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_tHighestIndex)
						}
						Set tChildCount=tChildCount+1 
					} else {
						Set isTypeElement=0
						Set Existing=1
						Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
						if tNonExistent Set tCNode=""
						Set pCHit=tCHit
						Set pDHit=tDHit
					}
					Set tReturnElem=""
					if (tOutputType="element") {
						Set:tDHit tReturnElem=tElemName
						Set:tCHit tReturnElem=$$$xmlGetNodeValue(..%ContentRef,tCNode)
					}
					Set pCNodeTextHit=0
					if (tReturnElem'="") {
						$$$COVERAGE("find the last DOM node or Content node if any tElem'=""""")
						Set:tInsert=0 pDSubs=pDSubs_","">"_tReturnElem_""""_$S((tElemIndex="_")||(tElemIndex=""):"",1:","_tElemIndex)
					} else {
						$$$COVERAGE("find the last DOM node or Content node if any tElem=""""")
						Set:tInsert=0 pDSubs=pDSubs_$S((kDom="_")||(kDom=""):"",1:","_kDom)
						if (tDHit) {
							// use prefix and suffix for comments and processing instructions 03-17-11
							Set tStringType=$G(@$$$vaDOMRef(pDSubs))
							Set prefix=""
							Set suffix=""
							if tStringType=">C" {
								Set prefix="<!--"
								Set suffix="-->"
							}
							if tStringType=">I" {
								Set prefix="<?"
								Set suffix="?>"
							}
							Set pNodeValue=prefix_$G(@$$$vaDOMRef(pDSubs_","">V"""))_suffix
						}
						Set pCNodeTextHit=tCHit
						if (tCHit) {
							Set pCurrentNode=tCNode
						}
						if (tCNode'="") {
							Set:tCHit pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
						}
						Set pNodeType="text"
					}
					Set:tInsert=0 pCSubs=tCNode
					Set pCurrentNode=tCNode
					Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
					Set:tInsert=1 pAfterCNode=tCNode
				} ElseIf ""=tIndex {
					#; implied iteration
					Set kDom="", tChildCount=""
				} Else {
					#; find the nth DOM node or Content node if any
					#; JSL 8/17/10 commands using $n exercise the logic below for instance
					#; set x=##class(EnsLib.EDI.XML.Document).ImportFromFile("c:\perforce\Users\levinson\TedPeck\ABC.xml")
					#; w x.GetValueAt("/1/$2")

					$$$ASSERT(tIndex=+tIndex)
					If tInsert||((pMode="set")&&(tOperateOnSet=1)) { 
						if 'tInsert,pAction="set",'tIsFunction,'tLastElemIsAttribute set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because one cannot set an element node directly.  One must use a 'remove' followed by an insert using ~ or 'append'")  Quit
						Set pInsertDSubs=pDSubs
						Set isTypeElement=0
						Set tRightType=""
						Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.isElement,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
						if (tInsert || (pAction="append")) {
							Do ..domSlideNodes(pDSubs,kDom,.tHighestIndex)  Quit:$$$ISERR(tSC)  
						}
						Set isTypeElement=0
						Set pInsertType="textinsert"
						if pAction'="append" {
							Set pFinalSubscript=kDom
						} else {
							Set pFinalSubscript=tHighestIndex
						}
						Set tReturnElem=""
						if isElement Set:tDHit tReturnElem=tElemName
						if isElement Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						; count tElem>tElemCount till we get to kDom
						if (tReturnElem '="") {
							Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) Set:$e(kDom1)=">" kDom1="" quit:kDom1=""
								if $D(dtyp) If $P(dtyp,">",1)=tReturnElem Set tElemCount=$i(Count(tReturnElem))
								if kDom1=kDom quit
							}
							if '$D(tElemCount) Set tElemCount=1
							Set dtypElem=$g(@$$$vaDOMRef(pDSubs_","""_kDom_""""))
							if $P(dtypElem,">",1)'=tReturnElem { 
								Set tElemCount=$i(Count(tReturnElem))
							}
						} else {
							Set tElemCount=kDom
						}
						//-104628
						;if isElement {
							;Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_tElemCount,.tSC),tElem_">"_kDom)  Quit:$$$ISERR(tSC)  
						;}
						if pAction'="append" {
							Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_tElemCount)
						} else {
							Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_tHighestIndex)
						}
						if pAction'="append" {
							Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_tElemCount)
						} else {
							Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_tHighestIndex)
						}
						Set pCHit=tCHit
						Set pDHit=tDHit
						Set tChildCount=tChildCount+1 
						if isElement Set:tDHit tReturnElem=tElemName
						// 9-30-10 TBD change to getting qualified name
						;if isElement Set:tCHit tElem=$$$xmlGetNodeValue(..%ContentRef,tCNode)
						// 02-01-12
						if isElement Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
					} else {
						Set isTypeElement=0
						Set tRightType=""
						; 11-03-11
						if $e(pDOMPath)="/",$e(pDOMPath,2,*)'["/" {
							Set tSaveDSubs=pDSubs
							Set pDSubs=",1"
							Set rootPair=$g(@$$$vaDOMRef(pDSubs))
							if (rootPair'="") {
								Set root=$P(rootPair,">")
								if (root="/") { ; we have preceding processing instructions or comments
									Set pCSubs=0 ; magic number
								}
								Set tSaveDSubs=pDSubs
								Set pDSubs=","">"_root_""",1"
							} else {
								Set tSaveDSubs=pDSubs
								Set pDSubs="_"
							}
						}
						
						; 02-24-11, findIndex below needs to process rule "Ec"
						Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.isElement,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
						Set pCHit=tCHit
						Set pDHit=tDHit
						Set alreadyCalculated=1
						; 11-21-11
						if isElement Set:tDHit tReturnElem=tElemName
						// 9-30-10 TBD change to getting qualified name
						;if isElement Set:tCHit tElem=$$$xmlGetNodeValue(..%ContentRef,tCNode)
						// 02-01-12
						if isElement if $D(@$$$vaContentRef(0)) Set:tCHit&(tCNode'="") tReturnElem=$$$domGetQName(..%ContentRef,tCNode)

						Set tElemCount=tElemIndex
					}
					if isElement {
						// 11-21-11
						if '$D(tElemCount) set tElemCount=kDom
					}
					if isElement Set:tInsert=0 pDSubs=pDSubs_","">"_tReturnElem_""""_$S((kDom="_")||(kDom=""):"",1:","_tElemCount)
					Set pCNodeTextHit=0
					if 'isElement||(tElem="/") {
						Set:tInsert=0 pDSubs=pDSubs_$S((kDom="_")||(kDom=""):"",1:","_kDom)
						if (tDHit) {
							// use prefix and suffix for comments and processing instructions 03-17-11
							Set tStringType=$G(@$$$vaDOMRef(pDSubs))
							Set prefix=""
							Set suffix=""
							if tStringType=">C" {
								Set prefix="<!--"
								Set suffix="-->"
							}
							if tStringType=">I" {
								Set prefix="<?"
								Set suffix="?>"
							}

							Set pNodeValue=prefix_$G(@$$$vaDOMRef(pDSubs_","">V"""))_suffix

						}
						Set pCNodeTextHit=tCHit
						if tCHit {
							Set pCurrentNode=tCNode
						}
						Set:tCHit pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
						Set pNodeType="text"
					}
					Set:tInsert=0 pCSubs=tCNode
					Set pCurrentNode=tCNode
					Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
					Set:'tCHit pCSubs=""
					if (tInsert) {
						Set pAfterCNode="+"_prevCNode
					} else {
						if ((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
							Set pAfterCNode=tCNode
						}
					}
				}
			

			} Else {
				#; Find an element by number

				#; try first in DOMCache
				Set (tDone)=0, (tCount,tChildCount)=""
				If tInsert || ((pMode="set")&&(tFinal)),tElem="" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'set' mode index '"_tIndex_"' must be at an element name")  Quit
				#; find index and child count of the specified DOM node
				If "*"=tIndex {
					Set tNCount=..domGetElemCounts(pDSubs,pCSubs,,tIgnoreNamespaces||tElemIgnoreNamespaces,.pNSContext)
					Set pNodeValue=tNCount
					Set pNodeType="ordinal"
					Set (tDHit,tDone)=1
				} ElseIf "-"=tIndex || (""=tIndex && tInsert) {
					#; find the last DOM element node or Content element node if any
					$$$COVERAGE("find the last element")
					If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
						Set ..%SkipFind=1 ; JSL4386
						if tNode,'tInsert,pAction="set",'tIsFunction,'tLastElemIsAttribute set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because one cannot set an element node directly.  One must use a 'remove' followed by an insert using ~ or 'append'")  Quit
						Set pInsertDSubs=pDSubs
						Set isTypeElement=1
						Set Existing=0
						Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
						if (tInsert) {
							Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_kDom,.tSC),tElem_">"_kDom)  Quit:$$$ISERR(tSC)  
						}

						Set:tDHit tReturnElem=tElemName
						Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						if 'tDHit,pMode="set" {
							do ..createNonExistent(pDSubs,pCSubs,tReturnElem,tIndex,tNode,.kDom,tNonExistent,tCHit,0,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
							if 'tCHit Set tNonExistent=1
						}
						
						if tNonExistent Set tCNode=""
						if (tFinalBeforeAttribute=1) {
							Set pInsertType="elementattribute"
						} else {
							Set pInsertType="elementtext"
						}
						Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_kDom)
						Set pFinalSubscript=kDom
						Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_kDom)
						Set tChildCount=tChildCount+1 
					} else {
						Set isTypeElement=1
						Set Existing=1
						Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
						Set:tDHit tReturnElem=tElemName
						Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						if 'tDHit,pMode="set" {
							do ..createNonExistent(pDSubs,pCSubs,tReturnElem,tIndex,tNode,.kDom,tNonExistent,tCHit,0,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
							if 'tCHit Set tNonExistent=1
						}

						if tNonExistent Set tCNode=""
						Set pCHit=tCHit
						Set pDHit=tDHit
					}
					Set:tDHit tReturnElem=tElemName
					// 09-29-10, namespce implmentation
					;Set:tCHit tElem=@$$$vaContentRef(tCNode)
					if (tCNode'="") {
						Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
					}
					Set tSaveDSubs=pDSubs
					Set pDSubs=pDSubs_","">"_tReturnElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
					Set:tInsert=0 pCSubs=tCNode
					Set pCurrentNode=tCNode
					Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
					if (tInsert) {
						Set pAfterCNode="+"_prevCNode
					} else {
						if ((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
							Set pAfterCNode=tCNode
						}
					}

				} ElseIf ""=tIndex {
					#; implied iteration
					Set kDom="", tChildCount=""
				} Else {
					#; find the nth DOM element node or Content element node if any
					$$$ASSERT(tIndex=+tIndex)
					If tInsert || ((pMode="set")&&(tOperateOnSet=1)){ 
						Set pInsertDSubs=pDSubs
						Set isTypeElement=1
						;$$$vaKillCalcCache1(pDSubs) ; JSL4384 uncommenting this clear cache did not fix infinite loop in regression 12/16/2013 9:31 AM
						if $$$DEFINED(..%FindCache($$$GVAL(pDSubs,$c(0)),$$$GVAL(pCSubs,$c(0)),$c(0),$$$GVAL(tIndex,$c(0)),$$$GVAL(tNode,$c(0)),0,$$$GVAL(isTypeElement,$c(0)),$c(0),$$$GVAL(tIgnoreNamespaces,$c(0))),tList) { // JSL4382
							Set kDom=$LG(tList,1)
							Set tSC=$LG(tList,2)
							Set tCHit=$LG(tList,3)
							Set tDHit=$LG(tList,4)
							Set cNode=$LG(tList,5)
							Set prevCNode=$LG(tList,6)
							Set tElemIndex=$LG(tList,7)
							Set tElemName=$LG(tList,8)
							Set nFound=$LG(tList,9)
							Set isElement=$LG(tList,10)
							Set tOutputType=$LG(tList,11)
							Set tMatchedElemName=$LG(tList,13) 
						} else {

							Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.dummy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
						}
						if (tInsert) {
							Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_kDom,.tSC),tElem_">"_kDom)  Quit:$$$ISERR(tSC)  
						}
						
						Set tReturnElem=$S(tDHit:tElemName,1:"")
						Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						if 'tDHit,pMode="set" {
							if tReturnElem="" {
								Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set value at DOM path '"_pDOMPath_"' because there is no element at path character position "_oldpos)  Quit
							}
							do ..createNonExistent(pDSubs,pCSubs,tReturnElem,tIndex,tNode,.kDom,tNonExistent,tCHit,0,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
							if 'tCHit Set tNonExistent=1
						}

						if (tFinalBeforeAttribute=1) {
							Set pInsertType="elementattribute"
						} else {
							Set pInsertType="elementtext"
						}

						Set pInsertIndex=..calcInsertIndex(pDSubs,tReturnElem_">"_kDom)
						Set pFinalSubscript=kDom
						Set pElemSubscript=..calcISubscript(pDSubs,tReturnElem_">"_kDom)
						Set tChildCount=tChildCount+1 
					} Else {
						;if pMode="set" $$$vaKillCalcCache1(pDSubs) ; JSL4384 uncommenting this killcache did not fix infinite loop in regression 12/16/2013 9:43 AM, harmless to speed-up
						Set isTypeElement=1
						if $$$DEFINED(..%FindCache($$$GVAL(pDSubs,$c(0)),$$$GVAL(pCSubs,$c(0)),$$$GVAL("",$c(0)),$$$GVAL(tIndex,$c(0)),$$$GVAL(tNode,$c(0)),0,$$$GVAL(isTypeElement,$c(0)),$c(0),$$$GVAL(tIgnoreNamespaces,$c(0))),tList) { // JSL4382
							Set kDom=$LG(tList,1)
							Set tSC=$LG(tList,2)
							Set tCHit=$LG(tList,3)
							Set tDHit=$LG(tList,4)
							Set cNode=$LG(tList,5)
							Set prevCNode=$LG(tList,6)
							Set tElemIndex=$LG(tList,7)
							Set tElemName=$LG(tList,8)
							Set nFound=$LG(tList,9)
							Set isElement=$LG(tList,10)
							Set tOutputType=$LG(tList,11)
							Set tMatchedElemName=$LG(tList,13) 
						} else {

							Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
						}
						// 11-16-2011
						Set tReturnElem=""
						Set:tDHit tReturnElem=tElemName
						Set:tCHit&&(tCNode'="") tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						if 'tDHit,pMode="set" {
							if tReturnElem="" {
								Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set value at DOM path '"_pDOMPath_"' because there is no element at path character position "_oldpos)  Quit
							}
							do ..createNonExistent(pDSubs,pCSubs,tReturnElem,tIndex,tNode,.kDom,tNonExistent,tCHit,0,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
							if 'tCHit Set tNonExistent=1
						}
						Set pCHit=tCHit
						Set pDHit=tDHit
						Set alreadyCalculated=1
					}
					
					// 09-29-10, namespce implmentation
					;Set:tCHit tReturnElem=@$$$vaContentRef(tCNode)
					Set:tCHit&&(tCNode'="") tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
					Set:tDHit tReturnElem=tElemName
					Set tSaveDSubs=pDSubs
					Set pDSubs=pDSubs_","">"_tReturnElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
					Set:tInsert=0 pCSubs=tCNode
					Set pCurrentNode=tCNode
					Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
					Set:'tCHit pCSubs=""
					if (tInsert) {
						Set pAfterCNode="+"_prevCNode
					} else {
						if ((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
							Set pAfterCNode=tCNode
						}
					}
				}
			}
		} ElseIf tElem'["(" {
			#; Find an element by name
			// 11-15-2011 disallow some insert and append variations
			if pMode="set",tElem="~" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'set' mode insert '~' must be at an element name")  Quit
			Set pNodeType=">"_tElem
			#; try first in DOMCache
			Set (tDone,tDHit)=0, (tCount,tChildCount)=""
			#; find index and child count of the specified DOM node
			If "*"=tIndex {
				Set pNodeValue=$G(@$$$vaDOMRef(pDSubs_","""_tElem_""""))
				Set:""=pNodeValue pNodeValue=..domGetElemCounts(pDSubs,pCSubs,tElem,tIgnoreNamespaces||tElemIgnoreNamespaces,.pNSContext),pNodeType="ordinal"
				Set (tDHit,tDone)=1
			} ElseIf "-"=tIndex || (""=tIndex && tInsert) {
				; find last element by name
				If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
					Set ..%SkipFind=1 ; JSL4386
					if tNode,'tInsert,pAction="set",'tIsFunction,'tLastElemIsAttribute set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because one cannot set an element node directly.  One must use a 'remove' followed by an insert using ~ or 'append'")  Quit
					if 'tNode {
						Set isTypeElement=1
						if tInsert {
							Set bElementFunctionInsert=1
						} else {
							Set bElementFunctionInsert=0
						}
					} else {
						Set isTypeElement=0
						if tInsert {
							Set bElementFunctionInsert=1
						} else {
							Set bElementFunctionInsert=0
						}
					}
					Set Existing=0
					Set kDom=..findLast(pDSubs, pCSubs,tElem,.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,1,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,bElementFunctionInsert)

					Set pInsertDSubs=pDSubs
					if (tInsert) {
						; move in code from processing [~] or [~-] in element case
						kill Count
						Set found=0
						Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp)  Quit:""=kDom1  Quit:kDom1=kDom
							if $D(dtyp) If $P(dtyp,">",1)=tElem Set tElemCount=$i(Count(tElem))
							if $D(dtyp) If $P(dtyp,">",1)=tElem Set found=1 
						}
					
						if found=1 {
							if ..domElemNode(pDSubs,tElem_">"_kDom,.tSC)="" {
								; we aren't going to slide, we have a new tElem to add, we need to increment its count
								Set tElemCount=$i(Count(tElem))
							}
							Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_kDom,.tSC),tElem_">"_kDom)  Quit:$$$ISERR(tSC)  
						} else {
							Set tElemCount=1
							if tCHit,'tDHit {
								; if we are matching the Content Array node, but not the Dom array
								; we want to "overwrite" the Content Array Node
								Set kDom2=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
								Set kDom2=$O(@$$$vaDOMRef(pDSubs_","""_kDom2_""""),-1,dtyp)  
							} else {
								Set kDom2=kDom
							}
							Do ..domSlideElementNodes(pDSubs,kDom2,tElem_">"_kDom2)  Quit:$$$ISERR(tSC)  
						}
					}
					Set:tDHit tElem1=tElemName
					Set:tCHit tElem1=$$$domGetQName(..%ContentRef,tCNode)
					if 'tDHit,pMode="set" {
						if 'tNode {
							Set byName=1
						} else {
							Set byName=0
						}
						if ('tInsert) {
							Set kDom=..findLast(pDSubs, pCSubs,tElem1,.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
							do ..createNonExistent(pDSubs,pCSubs,tElem1,tIndex,tNode,.kDom,tNonExistent,tCHit,byName,,tIgnoreNamespaces,.pNSContext,isTypeElement)
							if 'tCHit Set tNonExistent=1
						}
						
					}

					$$$ASSERT(kDom'="")
					if (tFinalBeforeAttribute=1) {
						Set pInsertType="elementattribute"
					} else {
						Set pInsertType="elementtext"
					}
					if (tInsert) {
						Set index=tElemCount
					} else {
						Set index=kDom
					}
					Set pInsertIndex=..calcInsertIndex(pDSubs,tElem_">"_index)
					Set pFinalSubscript=kDom
					Set pElemSubscript=..calcISubscript(pDSubs,tElem_">"_index)
					Set tChildCount=tChildCount+1 
				} else {
					; find last element by name
					// 12-02-11 handle case of $-
					if 'tNode { ; not a $n node ordinal
						Set isTypeElement=1
						Set tElem1=tElem
					} else {
						Set isTypeElement=0
						Set tElem1=""
					}
					Set Existing=1
					Set kDom=..findLast(pDSubs, pCSubs,tElem1,.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
					if pMode="get",tOutputType'="element" {
						// 12-02-2011 handle error case when asking for $-
						Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because "_tElemPreParse_" in "_tDOMPathToPos_" is not an element, instead this node is a '"_tOutputType_"' node.")  Quit
						
					}
					Set:tDHit tReturnElem=tElemName
					Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
					if 'tDHit,pMode="set" {
						do ..createNonExistent(pDSubs,pCSubs,tReturnElem,tIndex,tNode,.kDom,tNonExistent,tCHit,1,,tIgnoreNamespaces,.pNSContext,isTypeElement)
						if 'tCHit Set tNonExistent=1
					}
							
					if tNonExistent Set tCNode=""
					Set pCHit=tCHit
					Set pDHit=tDHit

				}
				if (pCHit||pDHit)&&($g(tMatchedElemName)'="") {
					$$$COVERAGE("findLast tMatchedElemName non-null")
					Set tSaveDSubs=pDSubs
					Set pDSubs=pDSubs_","">"_tMatchedElemName_""""_$S('tElemIndex:"",1:","_tElemIndex)
				} else {
					$$$COVERAGE("findLast tMatchedElemName null")
					Set tSaveDSubs=pDSubs
					Set pDSubs=pDSubs_","">"_tReturnElem_""""_$S('kDom:"",1:","_kDom)
				}
				Set:(tInsert=0) pCSubs=tCNode
				Set pCurrentNode=tCNode
				Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
				if tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
					Set:""'=tCNode pAfterCNode=$s(tInsert=1:"+",1:"")_tCNode
				}

			} ElseIf ""=tIndex {
				#; implied iteration
				Set kDom="", tChildCount=""
			} Else {
				#; Find an element by name
				$$$ASSERT(tIndex=+tIndex)
				; 10-17-11
				if pDSubs="" {
					; if PDSubs is empty see if there are preceding processing instructions or comments
					Set rootPair=$g(@$$$vaDOMRef(",1"))
					if $P(rootPair,">")="/" { ; preceding processing instructions or comments?
						Set tSaveDSubs=pDSubs
						Set pDSubs=","">/"",1"
					}
					;Set kDom=tIndex, tChildCount=$G(@$$$vaDOMRef(pDSubs_","""_tElem_""","_kDom_""))
					; sort nodes
					; add namespace support
					; exclude trying to replace root
					if pMode="set" && $D(@$$$vaContentRef(0)) { // non-empty
						Set root=$$$domGetQName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))
						;w !,"root="_root ; debug out
						if (tElem'=root)&&(tElem'="/") Set tSC=$$$ERROR($$$EnsErrGeneral,"Cannot modify top element of XML document") Quit
					}
				}
				If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
					Set pInsertDSubs=pDSubs
					if ('tNode) {
						Set isTypeElement=1
						Set tElem1=tElem
					} else {
						Set isTypeElement=0
						Set tElem1=""
					}
					if (tNode) {
						if 'tInsert,pAction="set",'tIsFunction,'tLastElemIsAttribute set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because one cannot set an element node directly.  One must use a 'remove' followed by an insert using ~ or 'append'")  Quit
						Set tSC=..domSetAtIndex(pDOMPath, pMode , .pCSubs, .pDSubs, .pNodeType, .pNodeIndex, .pNodeValue, .pNSContext, .pAfterCNode, .pFinalSubscript, .pInsertDSubs, .pInsertIndex, .pCHit, .pDHit, .pInsertType,.pTextOrdinal, .pTextAfterCNode, .pTextSubscript, .pInsertSubscript, .pCNamespace, $g(pFormat), .pNamespaces, $G(pNSContext("ign"),0), pAction , .pPrevNode, .pCurrentNode, .pCNodeTextHit, .pElemSubscript, tNode, tIndex, tElem, .tCHit, .tDHit, .tCNode,.prevCNode, tIgnoreNamespaces,  tElemIgnoreNamespaces, tInsert, tFinalBeforeAttribute, tChildCount, tOperateOnSet, .tNonExistent)
						if $$$ISERR(tSC) quit
						goto LoopContinue
					} else {
						if $$$DEFINED(..%FindCache($$$GVAL(pDSubs,$c(0)),$$$GVAL(pCSubs,$c(0)),$$$GVAL(tElem1,$c(0)),$$$GVAL(tIndex,$c(0)),$$$GVAL(tNode,$c(0)),0,$$$GVAL(isTypeElement,$c(0)),$c(0),$$$GVAL((tIgnoreNamespaces||tElemIgnoreNamespaces),$c(0))),tList) { // JSL4382
							Set kDom=$LG(tList,1)
							Set tSC=$LG(tList,2)
							Set tCHit=$LG(tList,3)
							Set tDHit=$LG(tList,4)
							Set cNode=$LG(tList,5)
							Set prevCNode=$LG(tList,6)
							Set tElemIndex=$LG(tList,7)
							Set tElemName=$LG(tList,8)
							Set nFound=$LG(tList,9)
							Set isElement=$LG(tList,10)
							Set tOutputType=$LG(tList,11)
							Set tMatchedElemName=$LG(tList,13) 
						} else {
						
							Set kDom=..findIndex(pDSubs, pCSubs, tElem1, tIndex, tNode, .tSC, .tCHit, .tDHit,.cNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext,.kReturn)
						}
						Set skipCreate=0
						if 'tDHit {
							if (tNode) {
								if kReturn'="" {
									Set kDom=kReturn
									Set skipCreate=1
								}
							}
						}
						Set kDom2=""
						if tCHit,'tDHit {
							; if we are matching the Content Array node, but not the Dom array
							; we want to "overwrite" the Content Array Node
							Set kDom2=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
							Set kDom2=$O(@$$$vaDOMRef(pDSubs_","""_kDom2_""""),-1,dtyp)
						

						}
						if (tInsert) {

							if 'tCHit {
								Set lastIndex=">" ; '>' collates higher than numbers
								Set lastIndex=$O(@$$$vaDOMRef($P(pDSubs,",",1,*-1)_","""_lastIndex_""""),-1,dtyp)
								if tIndex >= lastIndex {
									Set ..%SkipFind=1 ; speed-up JSL4386 - we need test for element creation at end, just setting skipfind is a bug
								}
							}
							set tElemCount=1
							Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) 
								if $D(dtyp) If $P(dtyp,">",1)=tElem Set tElemCount=$i(Count(tElem))
								if kDom1="" quit
								if kDom1=kDom quit
							}
							if tDHit {
								Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_tElemIndex,.tSC),tElem_">"_tElemIndex)  Quit:$$$ISERR(tSC)  
							} else {
								if kReturn'="",skipCreate=1 {
									; Use the earlier in value kReturn as the point at which the code slide nodes
									Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_kReturn,.tSC),tElem_">"_kReturn)  Quit:$$$ISERR(tSC)  
								}
								else {
									Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tElem_">"_kDom,.tSC),tElem_">"_kDom)  Quit:$$$ISERR(tSC)  
								}
							}
						} else {
							Set tElemCount=tElemIndex
						}
					}					
					Set pCHit=tCHit
					Set pDHit=tDHit
					if tNode,'tInsert {
						if tCHit||tDHit {
							if tOutputType'="element" Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set element at index "_(tIndex)_" which is of type non-element to node of different type "_tOutputType_" while "_tElem_" is element") quit
							if $g(tMatchedElemName)'="",tMatchedElemName'=tElem Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set element at index "_(tIndex)_" which is of type "_tMatchedElemName_" to node of different type "_tElem) 
						}
					}
					
					if tNode {
						if (nFound < (tIndex-1)) { set tSC=$$$ERROR($$$EnsErrGeneral,"No node exists at index "_(tIndex-1)) quit }
						else {
							if 'tDHit,'skipCreate {
								// 11-09-11
								do ..createNonExistent(pDSubs,pCSubs,tElem,tIndex,tNode,.kDom,tNonExistent,tCHit,0,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
							}

						}
					} elseif 'tDHit {
						if (pAction'="remove")||(tCHit=1) {
							do ..createNonExistent(pDSubs,pCSubs,tElem,tIndex,tNode,.kDom,tNonExistent,tCHit,1,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
						} else {
							set tSC=$$$ERROR($$$EnsErrGeneral,"Removing an element and no element exists at pDOMPath '"_pDOMPath_"'")
						}
						if 'tCHit Set tNonExistent=1
					}
					Set pInsertIndex=..calcInsertIndex(pDSubs,tElem_">"_tElemIndex)
					Set pFinalSubscript=kDom
					Set pElemSubscript=..calcISubscript(pDSubs,tElem_">"_tElemIndex)
					if (tFinalBeforeAttribute=1) {
						Set pInsertType="elementattribute"
					} else {
						Set pInsertType="elementtext"
					}
					Set tChildCount=tChildCount+1 
				} else {
					if 'tNode { ; not a $n node ordinal
						Set isTypeElement=1
						Set tElem1=tElem
					} else {
						Set isTypeElement=0
						Set tElem1=""
					}
					;if pMode="set" $$$vaKillCalcCache1(pDSubs) ; JSL4384 killing cache here does not solve infinite loop problem is regression
					;$$$vaKillCalcCache1(pDSubs) ; part B does not fix regression
					Set kDom=..findIndex(pDSubs, pCSubs, tElem1, tIndex, tNode, .tSC, .tCHit, .tDHit,.cNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
					if pMode="get",tOutputType'="element" {
						// 12-01-2011
						Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because "_tElemPreParse_" in "_tDOMPathToPos_" is not an element, instead this node is a '"_tOutputType_"' node.")  Quit
					}
					if pMode="get",tNode,tElem'=$g(tMatchedElemName) {
						Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because "_tElem_" in "_tElemPreParse_" in "_tDOMPathToPos_" is not an element, instead this node is a '"_tMatchedElemName_"' node.")  Quit
					}
					Set pCHit=tCHit
					Set pDHit=tDHit
					if 'pDHit,pMode="set" {
						if 'tCHit {
							
							Set lastIndex=">" ; '>' collates higher than numbers
							Set lastIndex=$O(@$$$vaDOMRef($P(pDSubs,",",1,*-1)_","""_lastIndex_""""),-1,dtyp)
							if tIndex >= lastIndex {
								Set ..%SkipFind=1 ; partA JSL4384 - we need test for element creation at end, just setting skipfind is a bug
							}
						}
						do ..createNonExistent(pDSubs,pCSubs,tElem,tIndex,tNode,.kDom,tNonExistent,tCHit,1,.tElemIndex,tIgnoreNamespaces,.pNSContext,isTypeElement)
						if 'pCHit,tElem'="/" Set tNonExistent=1
					}
					Set:tElem'="/" alreadyCalculated=1
				}
				#; 10-31-10 we needed createNonExistent to update tElemIndex
				Set tSaveDSubs=pDSubs
				if (pCHit||pDHit)&&($g(tMatchedElemName)'="")&&(pMode="get") {
					Set pDSubs=pDSubs_","">"_tMatchedElemName_""""_$S('tElemIndex:"",1:","_tElemIndex)
				} else {
					Set pDSubs=pDSubs_","">"_tElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
				}
				Set:(tInsert=0) pCSubs=cNode
				Set pCurrentNode=cNode
				; line added 10-14-10 because pTextOrdinal coming out wrong when annotating DOM node
				Set:'tCHit pCSubs=""
				if tInsert,'tDHit { 
					Set pAfterCNode="+"_prevCNode
				} elseif ((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
					Set:""'=cNode pAfterCNode=cNode
				}
				Set cNode1=cNode
				Set tCNode=cNode
				Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
			}
		} Else {
			// add processing of nodes
			Set tChildCount=""
			#; Return a function value or find a node value indicated via function syntax
			Set tFinal=1, tElemBase=tElem
			Set tParam=$P(tElem,"(",2)
			Set tElem=$P(tElem,"(")
			If ")"'=tParam && ("element"'=tElem )&&(tElem'="position")  Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid function invocation in '"_tElemBase_"'")  Quit
			Set:"fn:"=$E(tElem,1,3) tElem=$E(tElem,4,*)
			Set tIsNodeFunction=(",comment,text,instruction,element,"[(","_tElem_","))
			If tIsNodeFunction {
				; processing node function or element()
				if tElem'="element" Set pNodeType=tElem
				#; loop through nodes to find the one indicated or indicate the one to create
				Set:"element"=tElem pFinal=0, tParam=$E(tParam,1,*-1) ; elements can have more children
				#; error checking - i.e. non-existence of an element or node still unimplemented
				if (tIndex="")||(tIndex="-") {
					// looking for last
					
					if tElem="element" {
						//if pMode="get",tParam'="" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'get' mode element cannot take a parameter: '"_tParam_"'")  Quit
						if pMode="set",tParam="" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'set' mode element must take a parameter.")  Quit
						; element()
						If tInsert || ((pMode="set")&&((tOperateOnSet=1))) { 
							;w !,"inserting element at end "_pDOMPath
							Set ..%SkipFind=1 ; JSL4386

							Set pInsertDSubs=pDSubs
							if (tNode) {
								Set isTypeElement=0
							} else {
								Set isTypeElement=1
							}
							Set Existing=0
							Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,.pNSContext,1)
							if (tInsert) {
								kill Count
								Set found=0
								Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp)  Quit:""=kDom1  Quit:kDom1=kDom
									if $D(dtyp) If $P(dtyp,">",1)=tParam Set tElemCount=$i(Count(tParam))
									if $D(dtyp) If $P(dtyp,">",1)=tParam Set found=1 
								}
								if found=1 {
									if ..domElemNode(pDSubs,tParam_">"_kDom,.tSC)="" {
										; we aren't going to slide, we have a new tParam to add, we need to increment its count
										Set tElemCount=$i(Count(tParam))
									}
									Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,tParam_">"_kDom,.tSC),tParam_">"_kDom)  Quit:$$$ISERR(tSC)  
								} else {
									Set tElemCount=1
									if tCHit,'tDHit {
										; if we are matching the Content Array node, but not the Dom array
										; we want to "overwrite" the Content Array Node
										Set kDom2=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
										Set kDom2=$O(@$$$vaDOMRef(pDSubs_","""_kDom2_""""),-1,dtyp)  

									} else {
										Set kDom2=kDom
									}
									Do ..domSlideElementNodes(pDSubs,kDom2,tParam_">"_kDom2)  Quit:$$$ISERR(tSC)  
								}
								; 04-08-11 comment out this ..domSlideElementNodes
							}
							
							if tNonExistent Set tCNode=""
							if (tFinalBeforeAttribute=1) {
								Set pInsertType="elementattribute"
							} else {
								Set pInsertType="elementtext"
							}
							Set pInsertIndex=..calcInsertIndex(pDSubs,tParam_">"_tElemCount)
							Set pFinalSubscript=kDom
							Set pElemSubscript=..calcISubscript(pDSubs,tParam_">"_tElemCount)
							Set tChildCount=tChildCount+1 
						} else {
							// 05-19-11
							if 'tNode {
								Set isTypeElement=1
							} else {
								Set isTypeElement=0
							}
							Set Existing=1
							Set kDom=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,"",.tOutputType,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
							if (tOutputType'="element") {
								Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because requesting element at non-element node $-")  Quit
							}
							if tNonExistent Set tCNode=""
							Set pCHit=tCHit
							Set pDHit=tDHit
						}
						Set:tParam'="" tReturnElem=tParam
						Set:tDHit tReturnElem=tElemName
						// 09-29-10, namespce implmentation
						Set:tCHit tReturnElem=$$$domGetQName(..%ContentRef,tCNode)
						Set tSaveDSubs=pDSubs
						Set pDSubs=pDSubs_","">"_tReturnElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
						Set:(tInsert=0) pCSubs=tCNode
						Set pCurrentNode=tCNode
						Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
						if (tInsert) {
							Set pAfterCNode="+"_tCNode
						} else {
							Set pAfterCNode=tCNode
						}
					} else { // looking for a non-element, e.g., text(), comment(), instruction()
						; we back up to parent to create or refer to a tElemName Domain array node that will contain the text
						; looking for last
						$$$COVERAGE("instruction(), comment() or text() in looking for a non-element")
						if tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
							Set tDSubsParent=$P(pDSubs,",",1,$L(pDSubs,",")-2)
							Set tElemName=$E($TR($P(pDSubs,",",$L(pDSubs,",")-1),"""",""),2,*)
							Set tElemIndex=$P(pDSubs,",",$L(pDSubs,","))
							Set isTypeElement=1
							Set tRightType=""
							// 11-10-11
							// new calculation for pFinalSubscript
							;$$$vaKillCalcCache1(pDSubs) ; partA JSL4382 puttting in kill here did NOT fix infinite loop in regression 7:54 PM
							Set pFinalSubscript=..findIndex(tDSubsParent, pCSubs, tElemName, tElemIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex1,.tElemName1,isTypeElement,tRightType,.nFound,.dummy,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
							// 11-09-11
							Set Existing=1
							Set isTypeElement=0
							Set tSlidePoint=""
							Set kDom="" for  { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_"""")) quit:kDom=""  quit:$e(kDom)=">"
								Set tSlidePoint=kDom
							}
							
							Set isTypeElement=1
							Set isTypeElement=0
							Set Existing=0
							if 'tNode{
								Set tRightType=tElem
							} else {
								Set tRightType=""
							}

							if (tInsert) {
								Do ..domSlideNodes(pDSubs,tSlidePoint,.tHighestIndex)
							}
							if 'tInsert {
								Set Existing=1
								Set pTextOrdinal=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex1,.tElemName,isTypeElement,tRightType,.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
							} else {
								if tHighestIndex="" Set tHighestIndex=1
								Set pTextOrdinal=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.tCNode,.prevCNode,Existing,.tElemIndex1,.tElemName,isTypeElement,tRightType,.tOutputType,tIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
								Set pTextOrdinal=tHighestIndex
							}

							if tNonExistent Set tCNode=""
							Set kDom=tElemIndex1 ; may be actual index not index in DOM array
							Set tDSubsChild=tDSubsParent_","">"_tElemName_""""
							Set pCHit=tCHitPrev
							Set pDHit=tDHitPrev
							Set pDSubsSave=pDSubs
							Set pDSubs=tDSubsParent
							Set pInsertDSubs=tDSubsParent
						}
						If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 

							Set pInsertType="elementfunction"
							set pInsertSubscript=tElemIndex
							Set pInsertIndex=..calcInsertIndex(pDSubs,tElemName_">"_tElemIndex)
							// 11-10-11, problem with calcualting final subscript
							Set pElemSubscript=..calcISubscript(pDSubs,tElemName_">"_tElemIndex)
							if (tInsert) {
								Set pTextAfterCNode=$s(tCNode'="":"+",1:"")_tCNode
							} else {
								Set pTextAfterCNode=tCNode
							}
							Set tChildCount=tChildCount+1 
							Set pCHit=tCHit
							Set pDHit=tDHit
						} else {
							// 11-15-11
							; not an element findLast
							; instruction(), comment() or text()
							$$$COVERAGE("instruction(), comment() or text() in not an element findLast")
							Set dtyp=""
							Set isTypeElement=0
							Set Existing=1
							Set kDom=$S("_"=pDSubs:"",1:">"), cNode=">" ; '>' collates higher than numbers
							if tDHitPrev { 
								$$$COVERAGE("instruction(), comment() or text() tDHitPrev=1")
								; n not an element"
								Set nFound=0
								Set kDom=1
								; add use of index 10-28-10
								kill Index
								do ..createIndex(pDSubs,.Index)
								Set (iIndex,jIndex)=""
								Set iIndex=$O(Index(iIndex),-1)

								Set kDom="" For { 
									if '$D(Index) {
										Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  Quit:""=kDom
									} else {
										if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex),-1)
										if iIndex'="",jIndex'="" {
											Set dtyp=$LI(Index(iIndex,jIndex),1)
											Set kDom=+$LI(Index(iIndex,jIndex),2)
											Set IJSeen(iIndex,jIndex)=""
										}
										if (jIndex="") {
											if iIndex'="" Set iIndex=$O(Index(iIndex),-1)
											if (iIndex="") {
												Set kDom=""
											} else {
												continue
											}
										}
										Quit:kDom=""
									}

									Continue:">"'=$E(dtyp) ; not a non-element type
									Set tDType=$P(dtyp,">",2)
									if 'tNode {
										Set isRightType=$Case(tElem,"text":$P(dtyp,">",2)="T","comment":$P(dtyp,">",2)="C","instruction":$P(dtyp,">",2)="I",:0)
										if dtyp=">Z" continue ; dummy node
										if dtyp="/>1" continue
										if 'isRightType continue ; not a node of type we are looking for, though searching for one
									}
									Set tDHit=1
									quit
								}
							}
							if tCHitPrev {
								$$$COVERAGE("instruction(), comment() or text() tCHitPrev=1")
								Set nFound=0
								Set ctyp=""
								Set cNode=""
								// 01-31-12
								For { Set cNode=$S(""=pCSubs:"", 1:$$$domGetPreviousChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
									Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
									if tElem="text" Continue:$$$xmlTEXTNODE'=ctyp ; not a text node
									Set tCNode=cNode
									Set tCHit=1
									quit
								}
							}
							Set pCNodeTextHit=tCHit
							if (tCHit) {
								Set isRightType=$Case(tElem,"text":$$$xmlTEXTNODE=ctyp,:0)
								if (isRightType) {
									Set pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
								} else {
									Set pNodeValue=""
								}
								Set pCurrentNode=tCNode
								Set pNodeType=tElem	
							}
							if (tDHit) {
								// use prefix and suffix for comments and processing instructions 03-17-11
								Set tStringType=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""""))
								Set prefix=""
								Set suffix=""
								if tStringType=">C" {
									Set prefix="<!--"
									Set suffix="-->"
								}
								if tStringType=">I" {
									Set prefix="<?"
									Set suffix="?>"
								}
								; 05-13-2011 just return value, not comment or instruction introducers
								; 05-13-2011 don't concatenate with pNodeValue from tCHit
								Set isRightType=$Case(tElem,"text":$P(dtyp,">",2)="T","comment":$P(dtyp,">",2)="C","instruction":$P(dtyp,">",2)="I",:0)
								if (isRightType) {
									Set pNodeValue=@$$$vaDOMRef(pDSubs_","""_kDom_""","">V""")
								} else {
									Set pNodeValue=""
								}
								Set pNodeType=tElem	
							}
							
							Set pCHit=tCHit
							Set pDHit=tDHit
						}
					}
				} else {
					// looking for element or node at numeric index
					// 11-15-2011
					if (tIndex="*") {
							Set isTypeElement=1
							Set tRightType=""
							Set tIndex=""
							Set kDom=..findIndex(pDSubs, pCSubs, tParam, tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.dummy,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
							Set pNodeValue=nFound
							Set pNodeType="count"

						if (tElem="element") {
						} else {
							Set isTypeElement=0
							Set tRightType=tElem
							Set tIndex=""
							Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.dummy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
							Set pNodeValue=nFound
							Set pNodeType="count"
						}
					} else {
						$$$ASSERT(tIndex=+tIndex)
						if (tElem="element") { ; first handle case where is element
							; element()
							$$$COVERAGE("element()")
							if pMode="get",tParam'="" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'get' mode element cannot take a parameter: '"_tParam_"'")  Quit
							if pMode="set",tParam="" set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because in 'set' mode element must take a parameter.")  Quit
							If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
								Set tSC=..domSetAtIndex(pDOMPath, pMode , .pCSubs, .pDSubs, .pNodeType, .pNodeIndex, .pNodeValue, .pNSContext, .pAfterCNode, .pFinalSubscript, .pInsertDSubs, .pInsertIndex, .pCHit, .pDHit, .pInsertType,.pTextOrdinal, .pTextAfterCNode, .pTextSubscript, .pInsertSubscript, .pCNamespace, $g(pFormat), .pNamespaces, $G(pNSContext("ign"),0), pAction , .pPrevNode, .pCurrentNode, .pCNodeTextHit, .pElemSubscript, tNode, tIndex, tParam, .tCHit, .tDHit, .tCNode,.prevCNode, tIgnoreNamespaces,  tElemIgnoreNamespaces, tInsert, tFinalBeforeAttribute, .tChildCount, tOperateOnSet, .tNonExistent)
								if $$$ISERR(tSC) quit
								goto LoopContinue
							} else {
								if 'tNode {
									Set isTypeElement=1
								} else {
									Set isTypeElement=0
								}
								; 05-19-11
								Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.dummy,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
								if (tOutputType'="element") {
									Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because requesting element at non-element node $"_tIndex_" pMode="_pMode)  Quit
								}
								Set pCHit=tCHit
								Set pDHit=tDHit
								Set alreadyCalculated=1
							}
							Set:tParam'="" tElem=tParam
							// 09-29-10, namespce implmentation
							Set:tCHit tElem=$$$domGetQName(..%ContentRef,tCNode)
							Set:tDHit tElem=tElemName
							Set tSaveDSubs=pDSubs
							Set pDSubs=pDSubs_","">"_tElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
							Set:tInsert=0 pCSubs=tCNode
							Set pCurrentNode=tCNode
							Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
							Set:tInsert=1 pAfterCNode="+"_prevCNode
							if (tInsert=0)&&((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
								Set pAfterCNode=tCNode
							}
						} else { // not an element, search under current element whether in DOM or in Content Array
							; instruction(), comment() or text()
							$$$COVERAGE("instruction(), comment() or text() at numeric index")

							If $E(pDOMPath,2,*)'["/" {
								Set pDSubs=","">/"",1"
								// 11-03-11
								Set tDHitPrev=1
							}
							if tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
								; looking at numeric index
								Set tDSubsParent=$P(pDSubs,",",1,$L(pDSubs,",")-2)
								Set tElemName=$E($TR($P(pDSubs,",",$L(pDSubs,",")-1),"""",""),2,*)
								Set tElemIndex=$P(pDSubs,",",$L(pDSubs,","))
								Set kDom=tElemIndex ; may be actual index not index in DOM array
								Set tDSubsChild=tDSubsParent_","">"_tElemName_""""
								Set pCHit=tCHitPrev
								Set pDHit=tDHitPrev
								Set pDSubsSave=pDSubs
								Set pDSubs=tDSubsParent
								Set pInsertDSubs=tDSubsParent
							}
							If tInsert || ((pMode="set")&&(tOperateOnSet=1)) { 
								Set isTypeElement=0
								Set Existing=0
								if 'tNode{
									Set tRightType=tElem
								} else {
									Set tRightType=""
								}
								$$$vaKillCalcCache ; JSL4386 commenting this out causes regression to fail
								Set pTextOrdinal=..findIndex(pDSubsSave, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.duumy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)

								if 'tInsertOrAppend,tNode {
									if tCHit||tDHit {
										if tElem'=tOutputType Set tSC=$$$ERROR($$$EnsErrGeneral,"Cannot replace node with node of a different type") quit
									}
								}
								Set createdNonExistent=0
								if tNode {
									if (nFound < (tIndex-1)) set tSC=$$$ERROR($$$EnsErrGeneral,"No node of appropriate type exists at index "_(tIndex-1)) quit
								} else {
									if (nFound < (tIndex-1)) {
										do ..createNonExistentNode(pDSubsSave,pCSubs,tIndex,tNode,tRightType,tIgnoreNamespaces,.pNSContext)
										;$$$vaKillCalcCache ; JSL4386 commenting this out causes regression to fail
										Set pTextOrdinal=..findIndex(pDSubsSave, pCSubs, "", tIndex, tNode,.tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.duumy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
										Set createdNonExistent=1
									}
								}
								// 10-17-11
								If $E(pDOMPath,2,*)'["/" {
								}
								if (tInsert&&('createdNonExistent)) {
									Do ..domSlideNodes(pDSubsSave,pTextOrdinal,.tHighestIndex)  Quit:$$$ISERR(tSC)  
								}
								Set pInsertType="elementfunction"
								Set isTypeElement=1
								Set pInsertSubscript=..findIndex(pDSubs, pCSubs, tElemName, kDom, tNode, .tSC, .tCHit1, .tDHit1,.tCNode1,.prevCNode1,0,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.duumy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext,.kReturnDummy,0,0,.kFinal)
								Set pInsertIndex=..calcInsertIndex(pDSubs,tElemName_">"_kDom)
								// 04-09-2012 setting of pFinalSubscript is wrong, Prodlog 99204
								Set pFinalSubscript=kFinal
								Set pElemSubscript=..calcISubscript(pDSubs,tElemName_">"_kDom)
								if (tInsert) {
									Set pTextAfterCNode=$s((prevCNode'=""):"+",1:"")_prevCNode
								}  else {
									if tCHit||tDHit {
										if tCHit { ;'createdNonExistent {
											Set pTextAfterCNode=tCNode
										} else {
											Set pTextAfterCNode=$s((prevCNode'=""):"+",1:"")_prevCNode
										}
									} else {
										Set pTextAfterCNode=$s((prevCNode'=""):"+",1:"")_prevCNode
									}
								}
								Set pCNodeTextHit=tCHit
								Set pCurrentNode=tCNode
								Set pCHit=tCHit
								Set pDHit=tDHit
								Set tChildCount=tChildCount+1 
							} else {
								Set (tCHit,tDHit)=0
								Set pCNodeTextHit=0

								if tDHitPrev,'tCHitPrev { 
									$$$COVERAGE("instruction(), comment() or text() at numeric index tDHitPrev, 'tCHitPrev")
									Set nFound=0
									Set kDom=1
									; add use of index 10-28-10
									kill Index
									do ..createIndex(pDSubs,.Index)
									Set (iIndex,jIndex)=""
									Set iIndex=$O(Index(iIndex))

									Set kDom="" For { 
								
										if '$D(Index) {
											Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom
										} else {
											if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
											if iIndex'="",jIndex'="" {
												Set dtyp=$LI(Index(iIndex,jIndex),1)
												Set kDom=+$LI(Index(iIndex,jIndex),2)
												Set IJSeen(iIndex,jIndex)=""
											} 
											if (jIndex="") {
												if iIndex'="" Set iIndex=$O(Index(iIndex))
												if (iIndex="") {
													Set kDom=""
												} else {
													continue
												}
											}
											Quit:kDom=""
			
										}

										Set tDType=$P(dtyp,">",2)
										if 'tNode {
											Set isRightType=$Case(tElem,"text":$P(dtyp,">",2)="T","comment":$P(dtyp,">",2)="C","instruction":$P(dtyp,">",2)="I",:0)
											if dtyp=">Z" continue ; dummy node
											if dtyp="/>1" continue
										}
										Set nFound=nFound+1
										if nFound=tIndex {
											Set tDHit=1
											// use prefix and suffix for comments and processing instructions 03-17-11
											Set tStringType=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""""))
											Set prefix=""
											Set suffix=""
											// 11-21-11 do type checking
											if tElem'="element",$e(tStringType)'=">" Set tSC=$$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path "_pDOMPath_" because type requested is "_tElem_" but type found is element") Quit
											if ((tElem="comment") && (tStringType'=">C"))||((tElem="instruction") && (tStringType'=">I"))||((tElem="text") && (tStringType'=">T")) {
												Set tSC=$$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path "_pDOMPath_" because type requested is "_tElem_" but type found is "_$Case($P(dtyp,">",2),"T":"text","C":"comment","I":"instruction","Z":"dummy node",:"unknown node")) Quit
											}
											if tStringType=">C" {
												Set prefix="<!--"
												Set suffix="-->"
											}
											if tStringType=">I" {
												Set prefix="<?"
												Set suffix="?>"
											}
											; 05-13-2011 just return value, not comment or instruction introducers
											Set pNodeValue=@$$$vaDOMRef(pDSubs_","""_kDom_""","">V""")
											Set pNodeType=tElem
											quit
										}
									}
								}
								if tCHitPrev,'tDHitPrev {
									$$$COVERAGE("instruction(), comment() or text() at numeric index tCHitPrev, 'tDHitPrev")
									Set nFound=0
									Set cNode=""
									// 01-31-12
									if $D(@$$$vaContentRef(0)) {
										For { Set cNode=$S(""=pCSubs:"", 1:$$$domGetNextChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
											Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
											// 11-21-11 type checking
											if tElem'="text" Set tSC=$$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path "_pDOMPath_" because type requested is "_tElem_" but node is in content array which only supports text" ) Quit
											Set tCNode=cNode
											if ctyp=$$$xmlTEXTNODE||tNode Set nFound=nFound+1
											if nFound=tIndex {
												if $$$xmlTEXTNODE'=ctyp Set tSC=$$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path "_pDOMPath_" because type requested is "_tElem_" but node is not text" ) Quit
												Set tCHit=1
												Set pCNodeTextHit=tCHit
												Set pCurrentNode=tCNode
												Set pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
												quit
											}
										}
									}
								}
								if (tCHitPrev&&tDHitPrev) {
									$$$COVERAGE("instruction(), comment() or text() at numeric index tCHitPrev, tDHitPrev")
									Set isTypeElement=0
									if 'tNode{
										Set tRightType=tElem
									} else {
										Set tRightType=""
									}
									Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.dummy,.tOutputType,,tIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
									// 11-21-2011 do type checking
									if tElem'=tOutputType set tSC=$$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path "_pDOMPath_" because type requested is "_tElem_" but type found is "_tOutputType) Quit
									Set pCurrentNode=tCNode
									Set pCNodeTextHit=0
									if (tCHit) {
										if tCNode'="" {
											Set pCNodeTextHit=1
											Set pCurrentNode=tCNode
											Set pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
										}
										Set pNodeType=tElem	
									}
									if (tDHit) {
										// use prefix and suffix for comments and processing instructions 03-17-11
										Set tStringType=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""""))
										Set prefix=""
										Set suffix=""
										if tStringType=">C" {
											Set prefix="<!--"
											Set suffix="-->"
										}
										if tStringType=">I" {
											Set prefix="<?"
											Set suffix="?>"
										}
										; 05-13-2011 just return value, not comment or instruction introducers
										if kDom'="" {
											Set pNodeValue=$g(@$$$vaDOMRef(pDSubs_","""_kDom_""","">V"""))
										} else {
											Set pNodeValue=""
										}
										Set pNodeType=tElem	
									}
								}
							}
							Set pNodeType=tElem	
							set pCHit=tCHit
							set pDHit=tDHit
						}

					}
				}									
			} ElseIf "position"=tElem {
				; before calling domSeekPositionOfElement treat root "/" and top element as special case
				; if we are seeking position of top element then grandfather subs is null
				; if we are seeking position of "/" then grandfather subs is not defined
				if ($g(tOldtNode)) {
					Set tSC=$$$ERROR($$$EnsErrGeneral,"position only applies to element expression. DOM Path is '"_pDOMPath_"'")
					Quit
				}
				if '$D(tGrandFatherPDSubs) set tGrandFatherPDSubs=""
				if '$D(tGrandFatherPCSubs) set tGrandFatherPCSubs="" ; if root "/" then element position will be zero.  root is not an element.
				if '$D(tOldElem) set tOldElem="" ; if root "/" there is no tOldElem defined
				if $g(tGrandFatherPDSubs)="",$D(tOldPDSubs) set tGrandFatherPDSubs=""
				if $g(tGrandFatherPCSubs)="",$D(tOldPCSubs) set tGrandFatherPCSubs="0" ; if top element then special subscript of 0
				Set (i,tParam)=$E(tParam,1,*-1)
				if tParam="" Set i=$g(tOldIndex)
				if ($g(tOldIndex)="-") {
					Set i=..domGetElemCounts(tGrandFatherPDSubs, tGrandFatherPCSubs, tOldElem,tIgnoreNamespaces||$g(tOldElemIgnoreNamespaces),.pNSContext)
				}

				Set position=..domSeekPositionOfElement(tGrandFatherPDSubs, tGrandFatherPCSubs, tOldElem, i, tIgnoreNamespaces||$g(tOldElemIgnoreNamespaces),.pNSContext)
				set pNodeValue=position
				Set pNodeType="ordinal"
			} ElseIf "last"=tElem || ("count"=tElem) {
				Set tNCount=..domGetElemCounts(pDSubs,pCSubs,,tIgnoreNamespaces||tElemIgnoreNamespaces,.pNSContext)
				Set pNodeValue=tNCount
				Set pNodeType="ordinal"
			} ElseIf "local-name"=tElem {
				if (tIsElementPrev)||($g(tAttrName)'="") {
					if $g(tAttrName)="" {
						Set:tDHitPrev pNodeValue=$s(tElemName[":":$P(tElemName,":",2),1:tElemName)
						Set:tCHitPrev pNodeValue=$$$xmlGetNodeValue(..%ContentRef,tCNode)
					} else {
						// 10-10-2012
						// processing attribute
						if tAttrName'[":" {
							Set pNodeValue=tAttrName
						} else {
							Set pNodeValue=$P(tAttrName,":",2)
						}
					}
				} else {
					Set pNodeValue=""
				}
				Set pNodeType="localname" 
			} ElseIf "name"=tElem {
				if (tIsElementPrev)||($g(tAttrName)'="") {
					if $g(tAttrName)="" {
						Set:tDHitPrev pNodeValue=tElemName
						Set:tCHitPrev pNodeValue=$$$domGetQName(..%ContentRef,tCNode)
					} else {
						// 10-10-2012
						// processing attribute
						Set pNodeValue=tAttrName
					}
				} else {
					Set pNodeValue=""
				}
				Set pNodeType="name" 
			} ElseIf "prefix"=tElem {
				Set:tDHitPrev pNodeValue=$s(tElemName[":":$P(tElemName,":",1),1:"")
				Set:tCHitPrev pNodeValue=$s($$$domGetQName(..%ContentRef,tCNode)[":":$P($$$domGetQName(..%ContentRef,tCNode),":",1),1:"")
				Set pNodeType="name" 
			} ElseIf "namespace-uri"=tElem {
				if $g(tAttrName)="" {
					Set:tDHitPrev prefix=$s(tElemName[":":$P(tElemName,":",1),1:"xmlns"),pNodeValue=$g(pNSContext(pNSContext("level"),"namespaces",prefix))
					Set:tCHitPrev pNodeValue=$$$domGetNamespaceURI(..%ContentRef,tCNode)
				} else {
					//do ..domGetNamespaces(.pNamespaces,$g(pCSubs),$S("_"=tNamespaceSubs:"_",1:tNamespaceSubs_","">@"""),.pNSContext,$g(pFormat))
					Set prefix=$s(tAttrName[":":"xmlns:"_$P(tAttrName,":",1),1:"xmlns"),pNodeValue=$g(pNSContext(pNSContext("level"),"namespaces",prefix))
				}
				Set pNodeType="name" 
			} ElseIf "prefixes"=tElem {
				Set pNodeValue=""
				Set sep=""
				Set prefix="" for { set prefix=$O(pNSContext(pNSContext("level"),"namespaces",prefix),1,url) q:prefix=""
					Set pNodeValue=pNodeValue_sep_$s(prefix="xmlns":"",1:prefix)_"="_url
					Set sep=","
				}
				Set pNodeType="namespaces"
			} ElseIf "node-last"=tElem || ("node-count"=tElem) {
				Set tNCount=..domGetNodeCounts(pDSubs,pCSubs,"",.pNSContext)
				Set pNodeValue=tNCount
				Set pNodeType="ordinal"
			} ElseIf "node-position"=tElem {
				; before calling domSeekPositionOfNode treat root "/" and top element as special case
				; if we are seeking position of top element then grandfather subs is null
				; if we are seeking position of "/" then grandfather subs is not defined
				; 11-16-11
				if '$D(tGrandFatherPDSubs) set tGrandFatherPDSubs=""
				if '$D(tGrandFatherPCSubs) set tGrandFatherPCSubs="" ; if root "/" then element position will be zero.  root is not an element.
				if '$D(tOldElem) set tOldElem="" ; if root "/" there is no tOldElem defined
				if $g(tGrandFatherPDSubs)="",$D(tOldPDSubs) set tGrandFatherPDSubs=""
				if $g(tGrandFatherPCSubs)="",$D(tOldPCSubs) set tGrandFatherPCSubs="0" ; if top element then special subscript of 0
				Set i=$g(tOldIndex)
				if $g(tOldtNode) {
					if i="-" {
						Set position=..domGetNodeCounts(tGrandFatherPDSubs,tGrandFatherPCSubs,"",.pNSContext)
					} else {
						Set position=i
					}
				} else {
					if i="-" Set i=..domGetElemCounts(tGrandFatherPDSubs, tGrandFatherPCSubs, $g(tOldElem),tIgnoreNamespaces||tOldElemIgnoreNamespaces,.pNSContext)
					Set position=..domSeekPositionOfNode(tGrandFatherPDSubs, tGrandFatherPCSubs, $g(tOldElem), i, tIgnoreNamespaces||$g(tOldElemIgnoreNamespaces),.pNSContext)
				}

				set pNodeValue=position
				Set pNodeType="ordinal"

			} ElseIf "node-type"=tElem {
				; node-type must be terminal function and what preceeds it may be an arbitrary node through $n
				if '$D(tOldPCSubs) {
					Set pNodeValue="root"
				}
				if (tCHitPrev) {
					// 02-01-12
					if $D(@$$$vaContentRef(0)) { // non-empty
						Set tType=$$$xmlGetNodeType(..%ContentRef,tOldPCSubs)
						Set pNodeValue=$case(tType, $$$xmlELEMENTNODE:"element", $$$xmlTEXTNODE:"text", $$$xmlWHITESPACENODE:"white-space",:"unknown")
					}
				}
				if (tDHitPrev) {
					Set pNodeValue=tOutputType
				}
				Set pNodeType="name"
			} ElseIf "full"=tElem {
				#; this space intentionally blank
			} Else {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of unrecognized function '"_tElemBase_"'")  Quit
			}
		}
LoopContinue		
		Quit:$$$ISERR(tSC) 
		if tLastElem,tNode,pNodeType="" {
			Set pNodeValue=tElem
			Set pNodeType="value"
		}
		// below necessary to solve Dale Du Preez problem and Prodlog 89828
		if $D(pNSContext("level")),'$g(tIsFunction) {
			do ..domGetNamespaces(pNamespaces,$g(pCSubs),$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext,$g(pFormat))
		}

		Set tGrandFatherPCSubs=$g(tOldPCSubs)
		Set tGrandFatherPDSubs=$g(tOldPDSubs)
		Set tOldElemPreParse=tElemPreParse
		Set tOldElem=tElem
		Set tOldElemIgnoreNamespaces=tElemIgnoreNamespaces
		Set tOldIndex=tIndex
		Set tOldtNode=tNode
		Set tOldPCSubs=pCSubs
		Set tOldPDSubs=pDSubs
		if (oldpos=1) {
			// 11-07-11
			Set pDSubs=","">/"",1"
		}
		if 'tLastElem Set pPrevNode=pCSubs
		Set currDOMPath=$P(pDOMPath,"/",1,tPieceIndex+1)
		Set tUseParseCache = 0 ;Turn off Caching from JSL4397
		If tUseParseCache,$$$ISOK(tSC),(currDOMPath'=""),currDOMPath'["~",currDOMPath'["-",currDOMPath'["*",pAction'="clear",pAction'="remove",$g(pValue)'=""||pAction'="set" {
			Set ^||ISC.XML.VDOC.ParseCache(i%%ParseCache,currDOMPath)=$LB(tPos,tGrandFatherPCSubs,
						tGrandFatherPDSubs,tOldElemPreParse,
						tOldElem,tOldElemIgnoreNamespaces,tOldIndex,tOldtNode,tOldPCSubs,
						tOldPDSubs,pDSubs,pCSubs,tPieceIndex,tCHit,tDHit,
						PassedPseudoRoot,alreadyCalculated,pPrevNode,i%%SkipFind)
		}
		Quit:tLastElem
	}
	if $$$ISOK(tSC) {
		
		
		//Output pNodeType As %String, 
		//Output pNodeIndex As %String, Output pNodeValue As %String, Output pNSContext As %String, Output pAfterCNode, 
		//Output pFinalSubscript, Output pInsertDSubs, Output pInsertIndex, Output pCHit As %Boolean, 
		//Output pDHit As %Boolean, Output pInsertType As %String, Output pTextOrdinal As %String = 1, Output pTextAfterCNode, Output pTextSubscript, Output pInsertSubscript, Output pCNamespace As %Integer, pFormat As %String, Output pNamespaces, pAction As %String = "", Output pPrevNode As %String, Output pCurrentNode As %String, Output pCNodeTextHit As %Boolean, Output pElemSubscript, Output tNode, Output isElement, Output tCHitPrev, Output tDHitPrev
	}
	Quit tSC
}

/// Get the node index within the given DOM element of the child element given by pElemId = name>item
Method domElemNode(pDSubs As %String, pElemId As %String, Output pStatus As %Status) [ Internal ]
{
	Set tElemName=$P(pElemId,">",1)
	Set tIndex=$P(pElemId,">",2)
	Set tRetValue="" ; skip over domSlideElementNodes if not found
	; don't add use of index 10-28-10
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom 
		if $D(dtyp) If $P(dtyp,">",1)=tElemName,$P(dtyp,">",2)=tIndex Set tRetValue=kDom Quit
	}
	quit tRetValue
}

/// Make space to insert a new node by sliding up by one the given node in the given DOM element and all higher nodes in that element
Method dom2SlideElementNodes(pDSubs As %String, pNodeIndex As %String, pElem As %String) [ Deprecated, Internal ]
{
}

/// Make space to insert a new node by sliding up by one the given node in the given DOM element and all higher nodes in that element
/// following function currently used for debugging by substituting for domSlideElementNodes
Method domSlideElementNodes(pDSubs As %String, pNodeIndex As %String, pElem As %String) [ Internal ]
{
	if pNodeIndex="" quit
	; 04-08-11
	; is pNodeIndex beyound end?  Then quit
	Set kDom=">" ; '>' collates higher than numbers
	Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)
	if pNodeIndex>kDom quit

	; shift ordinals

	; maybe add use of index 10-28-10
	; 04-06-11
	Set tElemName=$P(pElem,">",1)
	; count the number of tElemName to pNodeIndex 04-06-11
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom  
		if $D(dtyp),$e(dtyp)'=">" {
			// element, count how many times it appears
			Set Count($P(dtyp,">",1))=$i(Count($P(dtyp,">",1)))
		}
		if kDom=pNodeIndex Quit
	}
	Set kDom=">" ; '>' collates higher than numbers

	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  Quit:""=kDom
		Set dtyp=@$$$vaDOMRef(pDSubs_","""_kDom_"""")
		if $e(dtyp)'=">" {
			if kDom'=pNodeIndex { ;tElemName="" {
				if $P(dtyp,">",1)=tElemName {
					;increase by one since inserting element
					Set $P(dtyp,">",2)=$P(dtyp,">",2)+1
				} else {
					Set $P(dtyp,">",2)=$P(dtyp,">",2)
				}
			} else {
				Set $P(dtyp,">",2)=$i(Count(tElemName))
			}
			Set @$$$vaDOMRef(pDSubs_","""_(kDom+1)_"""")=dtyp
		} else {
			merge @$$$vaDOMRef(pDSubs_","""_(kDom+1)_"""")=@$$$vaDOMRef(pDSubs_","""_kDom_"""")
		}
		if kDom=pNodeIndex Quit
	}
	; Set DOM node
	Set @$$$vaDOMRef(pDSubs_","""_(pNodeIndex)_"""")=pElem
	; Normalize
	k Count
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom  
		if $D(dtyp),$e(dtyp)'=">",$e(kDom)'=">" {
			// element, count how many times it appears
			Set $P(dtyp,">",2)=$i(Count($P(dtyp,">",1)))
			Set @$$$vaDOMRef(pDSubs_","""_kDom_"""")=dtyp
		}
	}
	; shift elements
	Set tNodeIndex=""
	Set tNodeName=$P(pElem,">",1)
	Set tIndex=$P(pElem,">",2)
	Set subscript=pDSubs_","">"_tNodeName_""","""_tNodeIndex_""""
	For { Set tNodeIndex=$O(@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_tNodeIndex_""""),-1) Quit:""=tNodeIndex
		kill @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1)_"""")
		merge @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1)_"""")=@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_tNodeIndex_"""")
		if tNodeIndex=tIndex quit
	}
	;if '..%SkipFind $$$vaKillCalcCache1(pDSubs) ; JSL4384 - have to test for end,
	;$$$vaKillCalcCache1(pDSubs) ; part A, make unconditional but infinite regress still happens 12/16/2013 1:46 PM
}

/// Make space to insert a new node by sliding up by one the given node in the given DOM element and all higher nodes in that element
/// following function currently used for debugging by substituting for domSlideElementNodes
Method domIncreaseElementNodes(pDSubs As %String, pNodeIndex As %String, pElem As %String) [ Internal ]
{

	if pNodeIndex="" quit
	; 04-08-11
	; is pNodeIndex beyound end?  Then quit
	Set kDom=">" ; '>' collates higher than numbers
	Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)
	if pNodeIndex>kDom quit

	Set tElemName=$P(pElem,">",1)
	; count the number of tElemName to pNodeIndex 04-06-11
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom  
		if $D(dtyp),$e(dtyp)'=">" {
			// element, count how many times it appears
			if $P(dtyp,">",1)=tElemName Set Count($P(dtyp,">",1))=$i(Count($P(dtyp,">",1)))
		}
		if kDom=pNodeIndex Quit
	}
	
	Set kDom=">" ; '>' collates higher than numbers

	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  Quit:""=kDom
		Set dtyp=@$$$vaDOMRef(pDSubs_","""_kDom_"""")
		if $e(dtyp)'=">" {
			if kDom'=pNodeIndex { ;tElemName="" {
				if $P(dtyp,">",1)=tElemName {
					;increase by one since inserting element
					Set $P(dtyp,">",2)=$P(dtyp,">",2)+1
				} 
			} 
			Set @$$$vaDOMRef(pDSubs_","""_(kDom)_"""")=dtyp
		}
		if kDom=pNodeIndex Quit
	}
	; Set DOM node
	//Set @$$$vaDOMRef(pDSubs_","""_(pNodeIndex)_"""")=pElem
	; Normalize
	; shift elements
	Set tNodeIndex=""
	Set tNodeName=$P(pElem,">",1)
	Set tIndex=$P(pElem,">",2)
	Set subscript=pDSubs_","">"_tNodeName_""","""_tNodeIndex_""""
	For { Set tNodeIndex=$O(@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_tNodeIndex_""""),-1) Quit:""=tNodeIndex
		kill @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1)_"""")
		merge @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1)_"""")=@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_tNodeIndex_"""")
		kill @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex)_"""")
		if tNodeIndex=tIndex quit
	}
	if '..%SkipFind $$$vaKillCalcCache1(pDSubs) ; JSL4384
	;$$$vaKillCalcCache1(pDSubs)
}

/// Make space to insert a new node by sliding up by one the given node in the given DOM element and all higher nodes in that element
Method domSlideNodes(pDSubs As %String, pNodeIndex As %String, Output pHighestIndex As %String) [ Internal ]
{
	; shift ordinals
	Set kDom=">" ; '>' collates higher than numbers
	Set tHighestIndex=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1)
	Set pHighestIndex=tHighestIndex
	; shift elements
	Set tNodeIndex=""
	Set tIndex=pNodeIndex
	if (tHighestIndex+1)=pNodeIndex {
		Set pHighestIndex=pNodeIndex
		if $D(@$$$vaContentRef(0))||'..%SkipFind {
			$$$vaKillCalcCache1(pDSubs) ; partA uncommented (this fixes infinite loop in regression) JSL4384
		}
		quit
	}
	Set subscript=pDSubs_","_tNodeIndex
	For { Set tNodeIndex=$O(@$$$vaDOMRef(pDSubs_","""_tNodeIndex_""""),-1) Quit:""=tNodeIndex
		if '(tNodeIndex?0.N) continue ; do not rearrange non-numeric subscripts at this level like ">I"
		merge @$$$vaDOMRef(pDSubs_","""_(tNodeIndex+1)_"""")=@$$$vaDOMRef(pDSubs_","""_tNodeIndex_"""")
		if tNodeIndex=tIndex quit
	}
	//+ 104628
	//if tIndex'="" kill @$$$vaDOMRef(pDSubs_","""_(tIndex)_"""")
	//- 104628
	Set kDom=">" ; '>' collates higher than numbers
	Set pHighestIndex=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1)
	;if '..%SkipFind $$$vaKillCalcCache1(pDSubs) ; JSL4384
	if $D(@$$$vaContentRef(0))||'..%SkipFind {
		$$$vaKillCalcCache1(pDSubs) ; partA uncommented (this FIXES infinite loop in regression)
	}
}

/// Find and cache the DOM and Content-combined counts for the given element name
Method domGetElemCounts(pDSubs As %String, pCSubs As %String, pElem As %String, pIgnoreNamespaces As %Boolean, ByRef pNSContext As %String) As %Integer [ Internal ]
{
	Set isTypeElement=1
	Set tRightType=""
	Set tIndex=""
	Set pNamespaces=##class(NamespaceHelper).%New()
	Set tNode=1
	Set kDom=..findIndex(pDSubs, pCSubs, $g(pElem), tIndex,  tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,1,.tElemIndex,.tElemName,isTypeElement,tRightType,.nFound,.dummy,.tOutputType,,pIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext)
	Quit nFound
}

Method domSeekPositionOfElement(pDSubs As %String, pCSubs As %String, pElem As %String, pElemNumber As %Integer, pIgnoreNamespaces As %Boolean, ByRef pNSContext As %String) As %Integer [ Internal ]
{
	#; return the element position of the pElem (say A1) which is the pElemNumber (say 3)
	#; Let the following be the XML file
	#; <root>
    #; <A1>this is first A1</A1>
	#; <A1>this is second A1</A1>
	#; <X>this is an X element which makes third A1 the 4th element</X>
	#; <A1>this is third A1</A1>
	#; </root>
	#; Then if PElem is A1 and pElemNumber is 3 we return 4.

	set tRemove=0
	Set tIndex=pElemNumber
	Set tCount=0
	Set (tAfterCNode,tParentCNode,tCNode)=""
	Set kDom=$S("_"=pDSubs:"",1:-1), cNode=-1,nFound=0
	Set (tCHit,tDHit)=0
	Set pNamespaces=##class(NamespaceHelper).%New()
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	IF '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	While ((""'=kDom)||(""'=cNode)) {
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ""'=kDom && (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode=""))) {
			Set tElemIndex=1
			; add use of index 10-28-10
			For { 
				if '$D(Index) {
					Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom||(">"=$E(kDom))  Continue:$g(dtyp)=">Z"  Continue:$g(dtyp)="/>1"
				} else {
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						Continue:$g(dtyp)="/>1"
						Set kDom=+$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex))
						if (iIndex="") {
							Set kDom=""
						} else {
							continue
						}
					}
					Quit:kDom=""
			
				}

				Continue:">"=$E(dtyp) ; not an element node
				Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
				Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
				Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
				Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
				Set tReplaceContent=(tReplace="c")
				Quit
			}
		}
		Set doit=1
		if cNode'=-1,cNode'="",'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
			Set tCNode=cNode
			; take a look at it
			;w !,"take a look 1"
			Set doit=0
		}
		// 02-02-12
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if tCNode'=-1,tCNode'="",'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			;w !,"take a look 2"_" tCNode="_tCNode_" cNode="_cNode
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		If ""'=cNode && (doit) && (($$$domGE(tAfterCNodeNoPlus,tCNode))||(kDom="")) {
			// 01-31-12
			For { Set cNode=$S(""=pCSubs:"", 1:$$$domGetNextChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				Continue:$$$xmlELEMENTNODE'=ctyp ; not an element node
				do ..domGetNamespaces(pNamespaces,cNode,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext)
				Set tElemName=$$$domGetQName(..%ContentRef,cNode)
				Set tCNode=cNode
				Quit
			}
		}
		if ((""'=cNode)||(""'=kDom)) {
			if (cNode="")&&(kDom'="") Set tElemName=$P(dtyp,">",1)
			$$$ASSERT('tParentCNode||(tParentCNode=pCSubs))
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				Set tCount=tCount+1
				If ""=tAfterCNode || (kDom="") {
					Set tElemName=$$$domGetQName(..%ContentRef,cNode)
					; 01-10-11
					; ignore namespace processing
					if (pElem="")||..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext) Set nFound=nFound+1
					Set:tCNode'="" SeenCNode(tCNode)=1 
					If nFound=tIndex Set tCHit=1 Quit
				} Else {
					Set tElemName=$P(dtyp,">",1)
					; ignore namespace processing
					if (pElem="")||..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext) Set nFound=nFound+1
					If nFound=tIndex Set tDHit=1  Quit
				}
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				If 'tRemove {
					; ignore namespace processing
					if (pElem="")||..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext) Set nFound=nFound+1
					Set tCount=tCount+1
  					Set:tCNode'="" SeenCNode(tCNode)=1
					If nFound=tIndex Set tDHit=1 Quit
				}
			} Else { ; If tCNode<=tAfterCNode
				Set tCount=tCount+1
				If ""=cNode {
					Set tElemName=$P(dtyp,">",1)
					; ignore namespace processing
					if (pElem="")||..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext) Set nFound=nFound+1
					If nFound=tIndex Set tDHit=1  Quit
				} Else {
					Set tElemName=$$$domGetQName(..%ContentRef,tCNode)
					; ignore namespace processing
					if (pElem="")||..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext) Set nFound=nFound+1
					Set:tCNode'="" SeenCNode(tCNode)=1
					If nFound=tIndex Set tCHit=1 Quit
				}
			}
		}
	}
	if (tCHit||tDHit) {
		Quit tCount
	}
	Else {
		Quit 0
	}
}

/// Find and cache the DOM and Content-combined child node counts for the given node
Method domGetNodeCounts(pDSubs As %String, pCSubs As %String, pElem As %String, ByRef pNSContext As %String) As %Integer [ Internal ]
{
	set tCount=0
	set tRemove=0
	Set (tAfterCNode,tParentCNode,tCNode)=""
	Set kDom=$S("_"=pDSubs:"",1:-1), cNode=-1,nFound=0
	Set pNamespaces=##class(NamespaceHelper).%New()
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	; detect if element is marked with a "c" (replace content) or a "d" (rule Ec)
	; we will be traversing sub-elements, text, comments, and processing instructions
	Set tReplace1=$G(@$$$vaDOMRef(pDSubs_","">R""")), tRemove1=(tReplace1>1)
	Set tReplaceContent=(tReplace1="c")
	set tEc=(tReplace1="d")

	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	While ((""'=kDom)||(""'=cNode)) {
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ""'=kDom && (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode=""))) {
			Set tElemIndex=1
			; add use of index 10-28-10
			For { 
				if '$D(Index) {
					Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom||(">"=$E(kDom))  Continue:$g(dtyp)=">Z"  Continue:$g(dtyp)="/>1"
				} else {
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						Continue:$g(dtyp)="/>1"
						Set kDom=+$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex))
						if (iIndex="") {
							Set kDom=""
						} else {
							continue
						}
					}
					Quit:kDom=""
			
				}
				;Continue:">"=$E(dtyp) ; not an element node
				if $g(dtyp)'="",$E(dtyp)'=">" {
					Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent1=(tReplace="c")
					;if 'tRemove Set tCount=$i(tCount)
				} elseif dtyp'="" {
					; text, comment, or processing instruction
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">I"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")

				}
				Quit
			}
		}
		Set doit=1
		if cNode'=-1,cNode'="",'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
			Set tCNode=cNode
			; take a look at it
			;w !,"take a look 1"
			Set doit=0
		}
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if tCNode'=-1,tCNode'="",'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			;w !,"take a look 2"_" tCNode="_tCNode_" cNode="_cNode
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		
		If doit && (""'=cNode) && (($$$domGE(tAfterCNodeNoPlus,tCNode))||(kDom="")) {
			// 01-31-12
			For { Set cNode=$S(""=pCSubs:"", 1:$$$domGetNextChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				;Continue:"e"'=ctyp ; not an element node
				if tEc||tReplaceContent Continue:$$$xmlTEXTNODE=ctyp ; skip over text nodes
				if tEc||tReplaceContent Continue:$$$xmlELEMENTNODE=ctyp ; skip over element nodes
				if $$$xmlELEMENTNODE=ctyp do ..domGetNamespaces(pNamespaces,cNode,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext)
				Set tCNode=cNode
				;Set tCount=$i(tCount)
				Quit
			}
		}
		$$$ASSERT('tParentCNode||(tParentCNode=pCSubs))
		if ((""'=cNode)||(""'=kDom)) {
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				If ""=tAfterCNode || (kDom="") {
					Set:tCNode'="" SeenCNode(tCNode)=1
				}
				Set tCount=tCount+1
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				If 'tRemove,tCNode'="" {
					Set tCount=tCount+1 
				}
				Set:tCNode'="" SeenCNode(tCNode)=1
			} Else { ; If tCNode<=tAfterCNode
				if cNode'="" {
					Set:tCNode'="" SeenCNode(tCNode)=1
				}
				Set tCount=tCount+1
			}
		}

	}

	Quit tCount
}

Method domSeekPositionOfNode(pDSubs As %String, pCSubs As %String, pElem As %String, pElemNumber As %Integer, pIgnoreNamespaces As %Boolean, ByRef pNSContext As %String) As %Integer [ Internal ]
{
	#; return the element position of the pElem (say A1) which is the pElemNumber (say 3)
	#; Let the following be the XML file
	#; <root>
    #; <A1>this is first A1</A1>
	#; <A1>this is second A1</A1>
	#; <X>this is an X element which makes third A1 the 4th element</X>
	#; <A1>this is third A1</A1>
	#; </root>
	#; Then if PElem is A1 and pElemNumber is 3 we return 4.
	;w !,"pDSubs="_pDSubs_" pCSubs="_pCSubs_" pElem="_pElem_" pElemNumber="_pElemNumber_" pIgnoreNamespaces="_pIgnoreNamespaces ; debug out

	set tRemove=0
	Set tIndex=pElemNumber
	Set tCount=0
	Set (tAfterCNode,tParentCNode,tCNode)=""
	Set kDom=$S("_"=pDSubs:"",1:-1), cNode=-1,nFound=0
	Set (tCHit,tDHit)=0
	Set pNamespaces=##class(NamespaceHelper).%New()
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	While ((""'=kDom)||(""'=cNode)) {
		Set (tElemName,tValue)=""
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ""'=kDom && (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode=""))) {
			Set tElemIndex=1
			; add use of index 10-28-10
			For { 
			
				if '$D(Index) {
					Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom||(">"=$E(kDom))  Continue:$g(dtyp)=">Z"  Continue:$g(dtyp)="/>1" 
				} else {
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						Continue:$g(dtyp)="/>1"
						Set kDom=+$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex))
						if (iIndex="") {
							Set kDom=""
						} else {
							continue
						}
					}
					Quit:kDom=""
			
				}
			

				if dtyp'="",">"'=$E(dtyp) { ; an element node
					Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
				} elseif dtyp'="" {
					; text, comment, or processing instruction
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">I"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")

				}
				Quit
			}
		}
		Set doit=1
		if cNode'=-1,cNode'="",'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if tCNode'=-1,tCNode'="",'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		If ""'=cNode && (doit) && (($$$domGE(tAfterCNodeNoPlus,tCNode))||(kDom="")) {
			// 01-31-12
			For { Set cNode=$S(""=pCSubs:"", 1:$$$domGetNextChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				if (ctyp=$$$xmlELEMENTNODE) { // 03-05-12
					do ..domGetNamespaces(pNamespaces,cNode,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext) 
					Set tElemName=$$$domGetQName(..%ContentRef,cNode)
				} else {
					Set tValue=$$$xmlGetNodeValue(..%ContentRef,cNode)
				}
				Set tCNode=cNode
				Quit
			}
		}
		if ((""'=tCNode)||(""'=kDom)) {
			$$$ASSERT('tParentCNode||(tParentCNode=pCSubs))
			if (cNode="")&&(kDom'="") Set tElemName=$P(dtyp,">",1)
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				Set tCount=tCount+1
				If (""=tAfterCNode)||(kDom="") {
					if $g(ctyp)=$$$xmlELEMENTNODE Set tElemName=$$$domGetQName(..%ContentRef,tCNode)
					; ignore namespace processing
					if ((pElem="")&&(tElemName'=""))||((pElem'="") && ..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext)) Set nFound=nFound+1
					Set:tCNode'="" SeenCNode(tCNode)=1
					If nFound=tIndex Set tCHit=1  Quit
				} Else {
					Set tElemName=$P(dtyp,">",1)
					if ((pElem="")&&(tElemName'=""))||((pElem'="") && ..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext)) Set nFound=nFound+1
					If nFound=tIndex Set tDHit=1  Quit
				}
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				If 'tRemove {
					Set tCount=tCount+1
					Set:tCNode'="" SeenCNode(tCNode)=1 
					if ((pElem="")&&(tElemName'=""))||((pElem'="") && ..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext)) Set nFound=nFound+1

					If nFound=tIndex Set tDHit=1  Quit
				}
			} Else { ; If tCNode<=tAfterCNode
				Set tCount=tCount+1
				If ""=cNode {
					Set tElemName=$P(dtyp,">",1)
					; ignore namespace processing
					if ((pElem="")&&(tElemName'=""))||((pElem'="") && ..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext)) Set nFound=nFound+1
					If nFound=tIndex Set tDHit=1  Quit
				} Else {
					Set tElemName=$$$domGetQName(..%ContentRef,cNode)
					; ignore namespace processing
					if ((pElem="")&&(tElemName'=""))||((pElem'="") && ..equalElement(pIgnoreNamespaces,tElemName,pElem,.pNSContext)) Set nFound=nFound+1
					Set:tCNode'="" SeenCNode(tCNode)=1
					If nFound=tIndex Set tCHit=1 Quit
				}
			}
		}
	}
	if (tCHit||tDHit) {
		Quit tCount
	}
	Else {
		Quit 0
	}
}

/// pValue - return value if return value is a string <br>
/// pDOMPath - input full DOM Path <br>
/// pContentSubs - node in Content Array<br>
/// pDOMSubs - node in DOM array<br>
/// pFormat - format string used to decide things like indentation <br>
/// pNSContext - multidimensional array used to store information, including namespace information, about calculation in progress
/// pCHit - whether hit at Content Array node <br>
/// pDHit -  whether hit at DOM node <br>
/// pNamespaces - namespace string used to output namespaces at node <br>
/// level - what level of XML tree are we on?  Special processing at level 1.  
/// SeenCNode - avoid processing cNode twice
/// cSeen - avoid processing cNode twice
/// pPPGIndex - index into process private global <br>
/// pIsStream - are outputting a stream or a pValue string variable? <br>
/// pWriteIndex - write index into process private global <br>
/// pNamespaceFound - are namespaces used at node or below it in XML tree <br>
/// pCount - number of element amongst sibling nodes (the parent has n children and these are all siblings) <br>
/// pCachedNamespaces - cached namespaces - can include cached namespaces for entire XML tree<br>
Method domGetSubtree(ByRef pValue As %String, pDOMPath As %String, pContentSubs As %String, pDOMSubs As %String, pFormat As %String, ByRef pNSContext As %String, pCHit As %Boolean, pDHit As %Boolean, pNamespaces As NamespaceHelper, ByRef level = 0, ByRef SeenCNode, ByRef cSeen, pPPGIndex As %Integer = 0, pIsStream As %Boolean = 0, ByRef pWriteIndex As %Integer = 0, pNamespaceFound As %Boolean = 1, pCount As %Integer = 0, ByRef pCachedNamespaces) As %Status [ Internal ]
{
	/*
	pFormat flags:
	1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)
	a : attributes alphabetical
	c : canonical ; ignores 'eintw'
	d : when getting subtree include prior namespace declarations
	e : close elements even when empty
	f : full top element not just its contents
	i : indent with 4 spaces unless 't' or 1-9
	l : output schema information, schema uri and schema location, based on property stored in ..schemaLocation
	n : newline (lf) after every text-free element
	o : output unescaped - for instance don't change < to &lt;
	p : suppress output of namespace prefixes
	q : use double quotes to set off attribute values if possible
	s : use stored indentation whitespace (ignores 'it1-9')
	r : use stored returns / newlines (ignores 'nw')
	t : indent with tab
	u : declare prefixes as well as using them
	w : Windows-style cr/lf newline after every text-free element
	x : omit namespaces in output
	*/
	;n IJSeen,Index,SeenKNode,cNode,ctyp,doit,dok,dtyp,iIndex,jIndex,kDom,nFound,nsp,tAfterCNode,tAfterCNodeNoPlus,tAttrCount,tCHit,tCNode,tDHit,tDoLoop,tEc,tElem,tElemIndex,tElemName,tHadContent,tHadText,tIgnoreContentSubs,tIndent,tIsStream,tLevel,tNamespaceDef,tOldElem,tOldIndent,tParentCNode,tRemove,tReplace,tReplaceContent,tRootDone,tSC,tSetFirstC,tTab,tVal,tWasMinusOne,kSeen,tAttrSubs,tAttrs,tCNodeChildList,tCNodeDescriptor,tChildList,tClose,tContentSubsTypeIsElement,tDescriptor,tHasText,tNamespaces,tOpen,tTopArray,tWriteIndex,cNodeDescriptor,prefix,suffix,tOpenVal,tPPGIndex,tReadIndex,tStringType,tStringVal,tTempVal
	// Problem with namespaces in forest
	if level=0 Set pNSContext("pFormat")=pFormat
	
	if '$D(pNamespaces)||'$isObject(pNamespaces) {
		Set pNamespaces=##class(NamespaceHelper).%New()
	}
	if level = 0 { // only do at top, we are setting schema location properties used by this document object
		if pFormat[$$$OUTPUTSCHEMAINFO {
			// set pSchema from schema global, this will be set to noNamespaceSchemaLocation or schemaLocation as appropriate
			if ..DocType'="" {
				Set systemId=$G($$$vaSchemaGbl($P(..DocType,":"),"src",1))
			} else {
				Set systemId=""
			}
			// We are using our global schema to set the schemaLocation or noNamespaceSchemaLocation for validation
			// count the namespaces.  If only one,
			// then in ..OutputToIOStream we are using xsi:noNamespaceSchemaLocation
			Set namespaceCount=0
			if ..DocType'="" {
				Set i="" for {  Set i=$O($$$vaSchemaGbl($P(..DocType,":"),"ns","list",i)) q:i=""
					Set namespaceCount=namespaceCount+1
				}
			}
			if namespaceCount > 1 {
				Set uri=$G($$$vaSchemaGbl($P(..DocType,":"),"ns","targ"))
			} else {
				Set uri=""
			}
			if systemId'="",uri'="" {
				Set tSchema=uri_" "_systemId
				Set tUseNamespaceSchemaLocation=1
			} else {
				Set tSchema=systemId
				Set tUseNamespaceSchemaLocation=0
			}
			if tUseNamespaceSchemaLocation {
				Set ..schemaLocation=tSchema
			} else {
				Set ..noNamespaceSchemaLocation=tSchema
			}

		}
	}

	Set level=$i(level)
	if $D(@$$$vaContentRef(0)) {
		if pContentSubs=0 { // magic number
			Set tTopArray($$$xmlGetDocumentElement(..%ContentRef))=""
		}
		if (pContentSubs'="") {
			Set tContentSubsTypeIsElement=($$$xmlGetNodeType(..%ContentRef,pContentSubs)=$$$xmlELEMENTNODE)
		}
		
	}

	Kill pNSContext(level)  if $D(pNSContext(level-1)) Merge pNSContext(level)=pNSContext(level-1)
	If pDOMSubs'="_" {
		Set nsp=">xmlns" For { Set nsp=$O(@$$$vaDOMRef(pDOMSubs_","">@"","""_nsp_""""),1,uri)  Quit:">xmlns"'=$E(nsp,1,$L(">xmlns"))
			Set:""=$G(uri)&&(nsp?1">xmlns:xsd_"1.N) uri=$G($$$vaSchemaGbl(..DocTypeCategory,"ns","list",$E(nsp,$L(">xmlns:")+1,*),"uri"))
			Set pNSContext(level,"namespaces",$E(nsp,2,*))=uri
		}
	}
	if (pCHit=0)&&(pDHit=0) {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to fetch sub-tree, no hit at "_pDOMPath_" pContentSubs="_pContentSubs_" pDOMSubs="_pDOMSubs) 
		goto quitstatus
	}
	if (pContentSubs=">")||(pContentSubs="-1") set pContentSubs=""
	Set tSC=$$$OK
	Set tIsStream=$$$IsdefObject(pValue)
	If level=1 { // at top level, passed in stream or value, and pPPGIndex is invalid
		Set pIsStream=tIsStream	
	}
	Set:'pIsStream pValue=$G(pValue)

	Set (tRemove,tReplace,tReplaceContent,tEc)=0, tElem=""
	Set tIgnoreContentSubs=0
	Set tSetFirstC=0
	If pDHit&&("_"'=pDOMSubs)&&$D(@$$$vaDOMRef(pDOMSubs)) {
		#; ">R"=2 : Remove entire element, ">R"=1 : =Replace entire element contents(including attributes), ">R"="" : extend contents	
		Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">R""")), tRemove=(tReplace>1)
		Set tReplaceContent=(tReplace="c")
		Set tEc=(tReplace="d")
		Set:tReplace pContentSubs=""  ; ignore content node if so marked
		If 'tRemove {
			Set tElem=$E($TR($P(pDOMSubs,",",$L(pDOMSubs,",")-1),"""",""),2,*)
			Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.tSC)
			if tElem="/",pDOMPath="/" {
				Set tIgnoreContentSubs=1
			}
			if tElem="/",pDOMPath="/",$g(@$$$vaDOMRef(pDOMSubs_",""1"""))'="",$e(@$$$vaDOMRef(pDOMSubs_",""1"""))=">" {
				Set tSetFirstC=1
			}
			Set:"/"=tElem tElem=""
			If $$$ISERR(tSC) goto quitstatus
		}
	}
	#; Get tElem from Content array if not in DOM array
	Set tNamespaceDef=""
	Set tSchemaNamespaceDef=##class(NamespaceHelper).%New()
	// if no namespaces set up xmlns:xsi and xsi:schemaLocation if pFormat says to output schema info and schemaLocation is non-null
	if level=1,pNamespaceFound=0,pFormat [ $$$OUTPUTSCHEMAINFO,(..schemaLocation'="")||(..noNamespaceSchemaLocation'="") {
		Set tLocation=$s(..schemaLocation'="":" xsi:schemaLocation='"_..schemaLocation_"'",1:" xsi:noNamespaceSchemaLocation='"_..noNamespaceSchemaLocation_"'")
		Set tNamespaceDef = " xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'"_tLocation
	}

	if $D(@$$$vaContentRef(0)),pContentSubs'="",tContentSubsTypeIsElement {
		$$$xmlaGetChildList(..%ContentRef,pContentSubs,tChildList,tDescriptor)
		do ##class(EnsLib.EDI.XML.NamespaceHelper).getPrefixes(..%ContentRef,pContentSubs,.tPrefixes) // JSL4301, requires XML underlying architecture in 2013.1 or above		
	}
	
	// questionable area 03-05-2012
	If 'tIgnoreContentSubs,(pCHit),pContentSubs'="",$D(@$$$vaContentRef(0)) {
		if pContentSubs'=0,pContentSubs'=-1 {
			if pNamespaceFound {
				Set tElem=$$$xmlaGetQName(..%ContentRef,tChildList)
			} else {
				Set tElem=$$$xmlaGetLocalName(..%ContentRef,tChildList)
			}
		} else {
			Set tElem=""
		}
		if (pNamespaceFound) {
			Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.tSC)
			Set tElem=..SchematizeNamespace((pFormat["u"),pContentSubs,tElem,tSchemaNamespaceDef,.tSchemaPrefixes,.pNSContext)
			if level=1,pFormat [ $$$OUTPUTSCHEMAINFO,(..schemaLocation'="")||(..noNamespaceSchemaLocation'="") {
				Set tLocation=$s(..schemaLocation'="":" xsi:schemaLocation='"_..schemaLocation_"'",1:" xsi:noNamespaceSchemaLocation='"_..noNamespaceSchemaLocation_"'")
				Set tNamespaceDef = tNamespaceDef_" xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'"_tLocation
			}

		}
		if $$$ISERR(tSC) goto quitstatus
	}

	#; Output the top element if called for
	Set pFormat=$ZStrip(pFormat,"<WC")
	Set tIndent=$ZStrip(pFormat,"<AN"), pFormat=$E(pFormat,1,*-$L(tIndent))
	if pNamespaceFound {
		merge tNamespaceNodes=pNSContext(pNSContext("level"),"namespaces")
	}
	Set tOldElem=tElem

	/*	If this node is an >any node then we do not want
		to output the <any> opening and closing tags.
	*/
	Set tIsanyElement = (tElem="any") && ($Piece(pDOMSubs,",",*-1)=($C(34)_">any"_$C(34)))

 	If ""'=tElem && (pFormat["f") && 'tIsanyElement {
		;if pDOMPath'="/" Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set tAttrs=""
		if (tReplace'="a") {
			// we can tighten pDOMSubs condition to include any pDOMSubs without attributes attached to it 06-14-2012
			if (pDOMSubs'="_")||($$$xmlaGetNumberAttributes(..%ContentRef,tChildList) > 0) {
				do ##class(EnsLib.EDI.XML.NamespaceHelper).getPrefixes(..%ContentRef,pContentSubs,.tPrefixes) // JSL4301, requires XML underlying architecture in 2013.1 or above
				Set tSC=..domGetAttrs(.tPrefixes,.tAttrs,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),$g(pFormat),.pNSContext,pCHit,pDHit,.tAttrCount)  
				if $$$ISERR(tSC) goto quitstatus
			}
		}
		Set tNamespaces=##class(NamespaceHelper).%New()
		Set:$find(tElem,":") tPrefixes($P(tElem,":"))=""
		if (pNamespaces.getString(.tPrefixes)="") { 
			if pNamespaceFound {
				if $D(pCachedNamespaces) {
					// Use cache to set tNamespaces and get namespaces into pNSContext
					Set tNamespaces=$g(pCachedNamespaces(level,pCount,"pNamespaces"))
					merge pNSContext(level,"namespaces")=pCachedNamespaces(level,pCount)
				} else {
					if level=2,pNSContext("pFormat")'["f" {
						// special-case so that when original pFormat was not "f" and we are retrieving forest we give tNamespaces current namespaces rather than
						// tNamespaces = set theorectic difference between current namespaces and pNSContext namespaces
						Set tNSContext1("level")=level
						do ..domGetNamespaces(tNamespaces,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),.tNSContext1,pFormat)
						// For DOM array need extra namespace examination of element and attributes
						If ((pDOMSubs'="")&&(pDOMSubs'="_")) {
							Set tElementNSPName = "xmlns"_$S($Find(tElem,":"):":"_$P(tElem,":"),1:"")
							If '$D(tNamespaces.Namespaces(tElementNSPName))&&$D(pNSContext(2,"namespaces",tElementNSPName),tNSPVal)#2 {
								Do tNamespaces.addNamespace(tElementNSPName,"'"_tNSPVal_"'")
							}
							If $G(tAttrCount)&&$Find(tAttrs,":") {
								Set tNSPChecked(tElementNSPName)=""
								For tAttrPos=1:1:tAttrCount {
									#;leading space add one
									Set tAttrTemp=$P(tAttrs," ",(tAttrPos+1))
									Set tAttrNSPName = "xmlns"_$S($Find(tAttrTemp,":"):":"_$P(tAttrTemp,":"),1:"")
									If '$D(tNSPChecked(tAttrNSPName)),'$D(tNamespaces.Namespaces(tAttrNSPName))&&$D(pNSContext(2,"namespaces",tAttrNSPName),tNSPVal)#2 {
										Do tNamespaces.addNamespace(tAttrNSPName,"'"_tNSPVal_"'")
										Set tNSPChecked(tAttrNSPName)=""
									}
								}
								Kill tNSPChecked
							}
						}
					} else {
						do ..domGetNamespaces(tNamespaces,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),.pNSContext,pFormat)
						#; domGetNamespaces will add to tNamespaces but does not know if not outputted
						If pFormat'["x" Do ..addNamespacesNotYetOutputted(level, .tPrefixes, tNamespaces, tSchemaNamespaceDef, .pNSContext)
					}
				}
			}
		} else {
			Set tNamespaces=pNamespaces
		}
		Set tHasText=$G(pNSContext(pNSContext("level")-1,"opentext"))
		Set tOpen=$G(pNSContext(pNSContext("level")-1,"open"))
		; recognize first-element
		do tNamespaces.Copy(tSchemaNamespaceDef)
		Set p="" For { Set p=$O(tSchemaPrefixes(p)) q:p=""
			Set tPrefixes(p)=""
		}

		#;If outputting namespace declarations include namespace declarations from top of source document
		If (pFormat["d")&&(level=1) {
			/*	Need ensure that we insert prefix definitions that were declared earlier
				By inserting into tPrefixes array we will output declaration if in tNamespaces
			*/
			Set xmlnsP=$Order(pNSContext(1,"namespaces",""))
			While xmlnsP'="" {
				Set p = $Piece(xmlnsP,":",2)
				If p'="" && '$Data(tPrefixes(p))#2 Set tPrefixes(p)=""
				Set xmlnsP=$Order(pNSContext(1,"namespaces",xmlnsP))
			}
		}

		#; If this document has been created from a blank new XML EDI Document and populated with SetValueAt
		#; Then ..%ContentRef will be %null(0) and we need to explicitly specify all prefixes to include.
		#dim tNamespaceDeclaration = $s(pFormat["x":"",1:tNamespaces.getString(.tPrefixes,$D(@..%ContentRef)))
		#; Will use tOpenVal later if suppressing output of empty tags
		Set tOpenVal=$S(tOpen:">",1:"")_
							$S(tHasText:"", pNSContext("elementcount")=1:"",1:$S(pFormat["w":$C(13,10)_tIndent, pFormat["n":$C(10)_tIndent, 1:""))_
							"<"_tElem_tAttrs_tNamespaceDef_tNamespaceDeclaration_$S(pFormat["e":">",1:"")
		If pIsStream {
			If level=1 {
				Do pValue.Write(tOpenVal,,.tSCw)
				If $$$ISERR(tSCw) && $$$ISOK(tSC) Set tSC = tSCw
			} else {
				if $D(^||ppgVal(pPPGIndex,pWriteIndex)),$L(^||ppgVal(pPPGIndex,pWriteIndex))+$L(tOpenVal)<$$$ppgNODESIZE {
					Set ^||ppgVal(pPPGIndex,pWriteIndex)=^||ppgVal(pPPGIndex,pWriteIndex)_tOpenVal
				} else {
					Set ^||ppgVal(pPPGIndex,$i(pWriteIndex))=tOpenVal
				}
			}
		} Else {
			Set pValue=pValue_tOpenVal
		}
		Kill:tOpen pNSContext(pNSContext("level")-1,"open")
		Set:pFormat'["e" pNSContext(pNSContext("level"),"open")=1
		/* 
			Record which namespace declarations have been outputted
			Both tNamespaceDef and tNamespaceDeclaration start with a space if not empty so we can concatenate.
		*/
		Do ..recordNSPDeclarations((tNamespaceDef_tNamespaceDeclaration),.pNSContext)
	} Else { Set tElem = "" }
	Set:tReplaceContent pContentSubs=""  ; ignore content node if so marked after fetching attributes
	#; for all child elements we always want the whole enchilada
	If pFormat'["f" Set pFormat=pFormat_"f"
	If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,pFormat["t":1,1:4))="" }
	Else { Set tTab="" }
	Set tOldIndent=tIndent  Set:'tIsanyElement tIndent=tIndent_tTab

	#; Loop over nodes in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting nodes in order
	Set pNSContext("level")=pNSContext("level")+1
	Set tLevel=pNSContext("level")
	if (tLevel > 0) {
		if pNamespaceFound {
			merge pNSContext(tLevel,"namespaces")=pNSContext(tLevel-1,"namespaces")
		}
	}

	if pDOMSubs'="_" do ..createIndex(pDOMSubs,.Index)
	Set (tAfterCNode,tCNode,tParentCNode,tRemove,tReplace)=""
	Set (dtyp,ctyp)=""
	Set (kDom)=$S("_"=pDOMSubs:"",1:-1), cNode=-1,(tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if (tSetFirstC) {
		Set ctyp=""
		Set cNode=pContentSubs
		if (pContentSubs = 0) { // magic number
			// for case of pContentSubs=0, this is the magic element which used to exist at index 0
			Set ctyp=$$$xmlELEMENTNODE
		} else {
			try {
				// this may fail if Content Array is empty
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
			} catch {
		}
		}
	}
	Set tElemName=""
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	Set tRootDone=0
	if (pIsStream) {
		// initialize process private global indices 
		Set tPPGIndex = $i(^||ppgVal)
	}
	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	Set tDoLoop=0
	Set tWasMinusOne=0
	If cNode=-1 {
		Set tDoLoop=1
		; If cNode is -1 set to null so don't have to process value of -1 in inner loop
		Set cNode=""
		Set tWasMinusOne=1
	}
	Set pCount=0 // start at first and walk forward, change made 10-01-2012, pCount is used in outputting namespaces
	if (((""'=kDom)||(""'=cNode)))||(tDoLoop) { 
	do {
		if (pIsStream) {
			kill ^||ppgVal(tPPGIndex) ;do tVal.Clear()
			Set tWriteIndex=0
		} else {
			Set (tVal)=""
		}
		Set dok=1
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ((""'=kDom) && (dok) && (tDHit || (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode="")))))||tSetFirstC {
			#; Retrieve the next DOM child candidate
			Set tElemIndex=1
			if '$D(Index) {
				Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""  Continue:$g(dtyp)=">Z"
			} else {
				if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
				if iIndex'="",jIndex'="" {
					Set dtyp=$LI(Index(iIndex,jIndex),1)
					Continue:$g(dtyp)=">Z"
					Set kDom=+$LI(Index(iIndex,jIndex),2)
					Set IJSeen(iIndex,jIndex)=""
				} 
				if (jIndex="") {
					if iIndex'="" Set iIndex=$O(Index(iIndex))
					if (iIndex="") {
						Set kDom=""
						Set tSetFirstC=0
					}
					continue
				}
			}
			If kDom="" {
				Set tSetFirstC=0
			}
			If ""'=kDom {
				If ">"'=$E(dtyp),dtyp'="" { ; it's an element node
					Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
					Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
				} Elseif dtyp'="" {
					; text, comment, or processing instruction
					Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">I"""))
					Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
				}
			}
		}

		Set doit=1
		if (cNode'=""),'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
			Set tCNode=cNode
			Set doit=0
		}
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if (tCNode'=""),'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			Set tCNode=cNode
			Set doit=0
		}

		If 'tSetFirstC && (""'=cNode || tWasMinusOne)  && (doit) && (""=kDom || tCHit || (($$$domGE(tAfterCNodeNoPlus,tCNode))&&(tAfterCNode'=""))) {
			#; Retrieve the next Content child candidate
			if $D(tTopArray) {
				Set cNode=$O(tTopArray(cNode))
			} else {
				if (pContentSubs="") {
					Set cNode=""
				} else {
					if (tContentSubsTypeIsElement) {
						if tWasMinusOne {
							$$$xmlaFirstChild(..%ContentRef,pContentSubs,tChildList,cNode,cNodeDescriptor)
						} else {
							$$$xmlaNextChild(..%ContentRef,pContentSubs,tChildList,cNode,cNodeDescriptor)
						}
					} else {
						Set cNode=""
					}
				}
			}
			Set:(cNode'="") ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
			If ""'=cNode {
				Set tCNode=cNode
			} 
		}
		; removed process combined text
		$$$ASSERT('tParentCNode||(tParentCNode=pContentSubs))
		Set (tCHit,tDHit)=0
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		// get child list for tCNode
		if tCNode'="",ctyp=$$$xmlELEMENTNODE {
			$$$xmlaGetChildList(..%ContentRef,tCNode,tCNodeChildList,tCNodeDescriptor)
		}

		If $$$domGT(tCNode,tAfterCNodeNoPlus) {
			If ( (cNode'="" || tWasMinusOne) && (kDom="")) {
				Set tCHit=1
				Set:""'=tCNode SeenCNode(tCNode)=""
			} Else {
				Set tDHit=1
				Set:""'=kDom SeenKNode(kDom)=""
				If $$$xmlELEMENTNODE=ctyp { 
					// 09-29-10, support namespaces
					if pNamespaceFound {
						Set tElemName=$$$xmlaGetQName(..%ContentRef,tCNodeChildList)
					} else {
						Set tElemName=$$$xmlaGetLocalName(..%ContentRef,tCNodeChildList)
					}
				}
			}
		} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
			Set:(""'=tCNode)||(tAfterCNode="") (tCHit,tDHit)=1
			If tRemove {
				set (tCHit,tDHit)=0
			}
			if tReplaceContent {
				Set tCHit=0
			}
			if tEc,$$$xmlTEXTNODE=ctyp {
				Set tCHit=0
			}
			Set:""'=tCNode SeenCNode(tCNode)=""
			Set:""'=kDom SeenKNode(kDom)=""
		} Else { ; If tCNode<=tAfterCNode
			If (cNode="")||(tSetFirstC) {
				Set tDHit=1
				Set:""'=kDom SeenKNode(kDom)=""
			} ElseIf tCNode'=""||tWasMinusOne {
				Set tCHit=1
				Set:""'=tCNode SeenCNode(tCNode)=""

			} Else {

			}
		}
		If tDHit {
			If ">"'=$E(dtyp),dtyp[">" { ; it's an element node
				Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
				Set tAttrSubs=pDOMSubs_","">"_tElemName_""","_tElemIndex
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
				Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
				Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
				Set tReplaceContent=(tReplace="c")
				if (tCHit){
					Set:tCNode'="" cSeen(tCNode)=""
				}
				if kDom'="",'$D(kSeen(kDom)) {
					if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
					Set tSetFirstC=0
					if 'tEc,tElemName'="/" {
						Set pCount=$i(pCount)
						Set tSC=..domGetSubtree(.tVal,$S(""=pDOMPath:"",1:pDOMPath_tElemName),cNode,$S("_"=pDOMSubs:"_",1:tAttrSubs),pFormat_$s(pDOMPath="/":"",1:tIndent),.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,$g(tPPGIndex),pIsStream,.tWriteIndex,pNamespaceFound,pCount,.pCachedNamespaces) 
						Quit:$$$ISERR(tSC)
					}
					if (pIsStream) {
						if tWriteIndex'=0 Set tHadContent=1
					} else {
						if tVal'="" Set tHadContent=1
					}
				}
				if kDom'="" Set kSeen(kDom)=""
			} Else {
				if (pDHit),tOldElem'="/" {
					if kDom'="" Set kSeen(kDom)=""
					if kDom'="" {
						if (pIsStream) {
							Set tStringType=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""))
							Set tStringVal=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">V"""))
							Set prefix=""
							Set suffix=""
							if $e(tStringType)=">" {
								if tStringType=">C" {
									Set prefix="<!--"
									Set suffix="-->"
								}
								elseif tStringType=">I" {
									Set prefix="<?"
									Set suffix="?>"
								} else {
									Set tStringVal=$$$CONDXMLESCAPE(pFormat,tStringVal)
								}
							}
							Set tStringVal=prefix_tStringVal_suffix
							if $D(^||ppgVal(tPPGIndex,tWriteIndex)),$L(^||ppgVal(tPPGIndex,tWriteIndex))+$L(tStringVal)<$$$ppgNODESIZE {
								$$$ASSERT(0)
								Set ^||ppgVal(tPPGIndex,tWriteIndex)=^||ppgVal(tPPGIndex,tWriteIndex)_tStringVal
							} else {
								Set ^||ppgVal(tPPGIndex,$i(tWriteIndex))=tStringVal ; Do tVal.Write(tStringVal)
							}
							if tStringVal'="" Set tHadText=1, pNSContext(pNSContext("level"),"opentext")=1
						} else {
							Set tStringType=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""))
							Set tVal=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">V"""))
							Set prefix=""
							Set suffix=""
							if $e(tStringType)=">" {
								if tStringType=">C" {
									Set prefix="<!--"
									Set suffix="-->"
								}
								elseif tStringType=">I" {
									Set prefix="<?"
									Set suffix="?>"
								} else {
									Set tVal=$$$CONDXMLESCAPE(pFormat,tVal)
								}
							}
							Set tVal=prefix_tVal_suffix
							if tVal'="" Set tHadText=1, pNSContext(pNSContext("level"),"opentext")=1
						}
					}
				}
			}
		} ElseIf tCHit {
			if (tCNode'="") {
				If $$$xmlELEMENTNODE=ctyp { 
					// 09-29-10, support namespaces
					if (tCNode '= 0) { // magic number, when processing "/" - top element
						if (pNamespaceFound) {
							Set tElemName=$$$xmlaGetQName(..%ContentRef,tCNodeChildList)
						} else {
							Set tElemName=$$$xmlaGetLocalName(..%ContentRef,tCNodeChildList)
						}
					} else {
						Set tElemName=""
					}
				}
			}
			If $$$xmlELEMENTNODE=ctyp { ; it's an element node
				if '$D(cSeen(tCNode)) {
					if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
					if 'tEc {
						Set pCount=$i(pCount)
						Set tSC=..domGetSubtree(.tVal,$S(""=pDOMPath:"",1:pDOMPath_tElemName),tCNode,$S("_"=pDOMSubs:"_",kDom="":"_",1:pDOMSubs_","_kDom),pFormat_tIndent,.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,$g(tPPGIndex),pIsStream,.tWriteIndex,pNamespaceFound,pCount,.pCachedNamespaces) 
						Quit:$$$ISERR(tSC)
					}
					if kDom="",tCNode=1 Set tRootDone=1
					Set cSeen(tCNode)=1
					Set SeenCNode(tCNode)=""
					if (pIsStream) {
						;if tVal.Size'=0 Set tHadContent=1
						if tWriteIndex'=0 Set tHadContent=1
					} else {
						if tVal'="" Set tHadContent=1
					}
				} else {
					Set tSC=$$$OK
				}
			} ElseIf $$$xmlTEXTNODE=ctyp{
				if (pCHit&&(tEc'=1)) {
					if '$D(cSeen(tCNode)) {
						Set SeenCNode(tCNode)=""
						Set cSeen(tCNode)=1
						Set tStringVal=$$$xmlGetData(..%ContentRef,tCNode) // 03-01-2012
						Set tStringVal=$$$CONDXMLESCAPE(pFormat,tStringVal)
						if pIsStream {
							if $D(^||ppgVal(tPPGIndex,tWriteIndex)),$L(^||ppgVal(tPPGIndex,tWriteIndex))+$L(tStringVal)<$$$ppgNODESIZE {
								$$$ASSERT(0)
								Set ^||ppgVal(tPPGIndex,tWriteIndex)=^||ppgVal(tPPGIndex,tWriteIndex)_tStringVal
							} else {
								Set ^||ppgVal(tPPGIndex,$i(tWriteIndex))=tStringVal ; Do tVal.Write(tStringVal)
							}

						} else {
							Set tVal=tStringVal
						}
						if tStringVal'="" Set tHadText=1, pNSContext(pNSContext("level"),"opentext")=1
					}
				}
			}
		}
		If pIsStream {
			if tWriteIndex'=0 {				
				Set tOpen=$G(pNSContext(pNSContext("level")-1,"open"))
				If tLevel=1 {
					Do pValue.Write($S(tOpen:">",1:""),,.tSCw)
					If $$$ISERR(tSCw) && $$$ISOK(tSC) Set tSC = tSCw
					Set tReadIndex="" for {  Set tReadIndex=$O(^||ppgVal(tPPGIndex,tReadIndex),1,tNodeVal) q:tReadIndex=""
						Do pValue.Write(tNodeVal,,.tSCw)
						If $$$ISERR(tSCw) && $$$ISOK(tSC) Set tSC = tSCw
					}
				
				} else {
					Set tTempVal=$S(tOpen:">",1:"")
					if $D(^||ppgVal(pPPGIndex,pWriteIndex)),$L(^||ppgVal(pPPGIndex,pWriteIndex))+$L(tTempVal)<$$$ppgNODESIZE {
						Set ^||ppgVal(pPPGIndex,pWriteIndex)=^||ppgVal(pPPGIndex,pWriteIndex)_tTempVal
					} else {
						Set ^||ppgVal(pPPGIndex,$i(pWriteIndex))=tTempVal
					}
				
					Set tReadIndex="" for {  Set tReadIndex=$O(^||ppgVal(tPPGIndex,tReadIndex),1,tTempVal) q:tReadIndex=""
						if $D(^||ppgVal(pPPGIndex,pWriteIndex)),$L(^||ppgVal(pPPGIndex,pWriteIndex))+$L(tTempVal)<$$$ppgNODESIZE {
							Set ^||ppgVal(pPPGIndex,pWriteIndex)=^||ppgVal(pPPGIndex,pWriteIndex)_tTempVal
						} else {
							Set ^||ppgVal(pPPGIndex,$i(pWriteIndex))=tTempVal
						}
					}
				}
				Kill:tOpen pNSContext(pNSContext("level")-1,"open")
			}
		} else {
			If ""'=tVal {
				Set tOpen=$G(pNSContext(pNSContext("level")-1,"open"))
				Set pValue=pValue_$S(tOpen:">",1:"")_tVal
				Kill:tOpen pNSContext(pNSContext("level")-1,"open")
			}
		}
		Set tWasMinusOne=0
	} While (((""'=kDom)||(""'=cNode)))&&'tRootDone
	} // end-if
	Kill:tHadText pNSContext(pNSContext("level"),"opentext")
	Kill pNSContext(pNSContext("level"),"namespaces")
	Set pNSContext("level")=pNSContext("level")-1
	if pNamespaceFound {
		kill pNSContext(pNSContext("level"),"namespaces")
		merge pNSContext(pNSContext("level"),"namespaces")=tNamespaceNodes	
	}

	if $$$ISERR(tSC) goto quitstatus

	#; Output the element close if called for
	If ""'=tElem {
		Set tOpen=$G(pNSContext(pNSContext("level"),"open"))
		; tOpen -> Neither tHadText nor tHadContent
		; tOpen means we close with a "/>" immediately
		$$$ASSERT('tOpen||'(tHadText||tHadContent))
		/*	If we are suppressing empty tags - format g we want
			to maintain standard full tag closure if suppress
			children but leave parent with attribute only.
			This means that if just had attribute and no children
			the full closing tag is given for "g" ($$$OUTPUTIGNORENULL)
			rather than />
			This is in keeping with standard Objects to XML projection.
			If we end up suppressing an open tag we wont show
			tClose.
		*/
		If tOpen && (pFormat'["e") && (pFormat'[$$$OUTPUTIGNORENULL) {
			Set tClose="/>"
		} Else {
			Set tClose="</"_tElem_">"
			Set tClose=$S(tOpen:">",1:"")_$S(('tHadContent||tHadText):"", 1:$S(pFormat["w":$C(13,10)_tOldIndent, pFormat["n":$C(10)_tOldIndent, 1:""))_tClose
			; recognize first-element
		}
		/*	Ensure we do not try to removeOpenTagFrom PPG if
				top level - ie even if empty output top tags
				format does not want to suppress empty tag
				format includes e option which takes precedence if mistakenly also specified g
				attributes or namespace declarations
			Not using tOpen since it may be parent tag with empty child(ren) that have been suppressed
		*/
		#dim tDontTryToSuppressEmptyTag = (pFormat'[$$$OUTPUTIGNORENULL)||(tLevel=1)||(tAttrs'="")||(tNamespaceDef'="")||(tNamespaceDeclaration'="")
		If pIsStream {
			If tLevel=1 {
				Do pValue.Write(tClose,,.tSCw)
				If $$$ISERR(tSCw) && $$$ISOK(tSC) Set tSC = tSCw
			} else {
				If tDontTryToSuppressEmptyTag||'..removeLastOpenTagFromPPG(pPPGIndex,pWriteIndex,tOpenVal,tOpen) {
					Do ..addCloseTagToPPG(pPPGIndex,pWriteIndex,tClose)
				}
			}
		} Else {
			If tDontTryToSuppressEmptyTag||'..removeLastOpenTagFromString(.pValue,tOpenVal,tOpen) {
				Set pValue=pValue_tClose
			}
		}
		Kill:tOpen pNSContext(pNSContext("level")-1,"open")
	}
	#; Clean up record of what was outputted
	If (pNSContext("level")=0) {
		Kill pNSContext("outputted")
	}
quitstatus
	Set level=level-1
	if level = 0 { // only do at top
		if pFormat[$$$OUTPUTSCHEMAINFO {
			Set ..schemaLocation=""
			Set ..noNamespaceSchemaLocation=""
		}
	}
	Quit tSC
}

/// Get the attributes of the given element
Method domGetAttrs(ByRef pPrefixes, ByRef pAttrs As %String = "", pContentSubs As %String, pDOMSubs As %String, pFormat As %String, ByRef pNSContext As %String, pCHit As %Boolean, pDHit As %Boolean, Output pAttrCount, pInputAttr As %String = "", Output pAttrIndex, pInputCount As %String = "", Output pOutputName, Output pOutputValue, pIncludeNamespaces = 0) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set pAttrCount=0
	Set pFormat=$G(pFormat)
	#; Loop over attrs in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting attr nodes in order
	Set kDom=$S("_"=pDOMSubs:"",pFormat["a":">",1:-1), cNode=-1, (tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if 'pDHit Set kDom=""
	if 'pCHit Set cNode=""
	#; We want the Second Index parameter which is ordered by Dom position
	#dim tAlphabeticalIndex
	if (pDOMSubs'="") && (pDOMSubs'="_") do ..createAttrOrNamespaceIndex(pDOMSubs, pFormat,.tAlphabeticalIndex, .Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	Set (tAfterCNode,tCNode,tDAttr,tDVal)=""
	Set (tRemove,tReplace)=0
	#dim tRetrieveNextDOMCandidate = 1
	// Get childList and descriptor from node, note internal API
	if pContentSubs'="",$$$xmlGetNodeType(..%ContentRef,pContentSubs)=$$$xmlELEMENTNODE {
		$$$xmlaGetChildList(..%ContentRef,pContentSubs,tChildList,tDescriptor)
	} else {
		Set tChildList=""
	}

	// we treat tOffset as an attribute handle to make it easier to port this code back to 2012.2
	$$$domInitAttributeHandle(tOffset)
	While (""'=kDom)||(($$$domLoopAttributes(..%ContentRef,tChildList,tOffset))&&(cNode'="")) {
		// From xmlaForEachAttribute(%documentId,%childlist,%offset,%attribute)
		if $$$domLoopAttributes(..%ContentRef,tChildList,tOffset) {
			$$$domNextAttribute(..%ContentRef, tChildList,tOffset,tAttribute) // set tAttribute from attribute handle in tOffset
		} else {
			Set tAttribute=""
		}
		Set (tAttrName,tCAttr,tValue,tCVal)=""
		Set:"+"=$E(tAfterCNode) tAfterCNode=$E(tAfterCNode,2,*),tPlus=1
		#; tAfterCNode could be a Dom modified attribute (tDAttr) that we have not come to yet.
		If pDHit && ((""'=kDom) && (tDHit || ((tAfterCNode']tCNode))&&tRetrieveNextDOMCandidate) || ((cNode="")&&(kDom'=""))) {
			#; Retrieve the next DOM child candidate
			Set tElemIndex=1

			if '$D(Index) {
				Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  
			} else {
				if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
				if iIndex'="",jIndex'="" {
					Set dtyp=$LI(Index(iIndex,jIndex),1)
					Set kDom=$LI(Index(iIndex,jIndex),2)
					Set IJSeen(iIndex,jIndex)=""
				}
				if (jIndex="") {
					if iIndex'="" Set iIndex=$O(Index(iIndex))
					if (iIndex="") {
						Set kDom=""
					}
					continue
				}
			}

			Set:">"=$E(kDom)&&(pFormat'["a") kDom=""
			If ""'=kDom {
				If pFormat["a" {
					if $e(kDom)=">" {
						
						Set tDAttr=$E(kDom,2,*), tDVal=dtyp
						
					}
				} Else {
					Set tDAttr=$P(dtyp,">",1), tDVal=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""""))
				}
				
				// 10-01-2012 - get information to process schema-location
				Set prefix="" // assume no prefix
				if tDAttr[":"{ // has prefix
					Set prefix=$P(tDAttr,":")
				}
				Set tDURI="" ; assume no namespace associated with attribute
				// get namespace associated with attribute, it might remain "" if no namespace associated with attribute
				Set:prefix'="" tDURI=$g(pNSContext(pNSContext("level"),"namespaces",prefix))
				if 'pIncludeNamespaces if ($find(tDAttr,":")&&($P(tDAttr,":")="xmlns"))||(tDAttr="xmlns") continue ; don't process namespaces here
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">I"""))
				Set tRemove=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">R"""))
			}
		}

		If pCHit && (""'=cNode && (""=kDom || tCHit  || (((tAfterCNode]tCNode)||(tAfterCNode=tCNode))&&(tAfterCNode'="")))) {
			#; Retrieve the next Content child candidate
			if tAttribute '= "",$$$domLoopAttributes(..%ContentRef,tChildList,tOffset) {
				// change made 9/28/2012 to support xsi:noNamespaceSchemaLocation='c:/perforce/users/levinson/ValidateSchema/Example5_4.xsd'
				Set cNode=$$$domGetAttributeQName(..%ContentRef,pContentSubs,tAttribute) Quit:""=cNode
			} else {
				 Set cNode=""
			}

			#; Since $$$domGetAttributeValue is a $Get look also to see if value entry defined.
			Set:cNode'="" ctyp=$$$domGetAttributeValue(..%ContentRef,pContentSubs,tAttribute) ; ctyp is the value of the attribute, for example "red" when attribute is color="red"
			if cNode'="" && ($$$domAttributeValueIsDefined(..%ContentRef,pContentSubs,tAttribute)) {
				; 08-02-11 91171: (Dev) Inconsistent XML namespace prefixes with DTL 
				; Don't use attribute if it is already present in DOM array and hence is a duplicate
				; in XML attributes can't be repeated
				Set found=0
				; look for matching DOM Sub based on uri for prefix
				if (cNode'="") {
					Set uri=$$$domGetAttrNamespaceURI(..%ContentRef,pContentSubs,tAttribute)
					// 10-01-2012 get information to process schema-location
					Set tCURI=uri
					Set level=pNSContext("level")
					set i="" for {  set i=$o(pNSContext(level,"namespaces",i),1,urivalue) q:i=""  
						if uri=$g(urivalue) {
							if i[":" {
								; of form xmnls:prefix
								Set prefix=$P(i,":",2)
								Set domSubscript=prefix_":"_cNode
							} else {
								Set domSubscript=cNode
							}
							if pDOMSubs'="_" {
								if $D(@$$$vaDOMRef(pDOMSubs_","">"_domSubscript_"""")) {
									Set found=1 Quit
								}
							}
						}
					}
				}
				If (""'=cNode) && ((pDOMSubs="_")||('found&&(uri'="")) || ((uri=""))) {
					Set tCAttr=cNode, tCVal=ctyp
				}
				Set:cNode'="" tCNode=cNode
			}
		}
		Set (tCHit,tDHit,tPlus)=0
		Set:"+"=$E(tAfterCNode) tAfterCNode=$E(tAfterCNode,2,*),tPlus=1

		/*	If not removing and the content attribute has not been seen
			and not modified by DOM cache (ie not in array tAlphabeticalIndex)
			then use it now.
			Could include xmlns declarations
		*/
		Set tRetrieveNextDOMCandidate = 1
		If (tRemove'>1) && (tCNode'="" ) && ('$Data(tAlphabeticalIndex(tCNode))) && ('$Data(SeenCNode(tCNode))) {
				Set tCHit=1
				Set SeenCNode(tCNode)=1
				If (tDAttr=tAfterCNode) && (tAfterCNode']tCNode) Set tRetrieveNextDOMCandidate = 0
		} ElseIf tCNode]tAfterCNode {
			If ""=tAfterCNode||(kDom="") {
				Set tCHit=1
				Set SeenCNode(tCNode)=1
			} Else {
				Set tDHit=1
			}
		} ElseIf tCNode=tAfterCNode && 'tPlus { ; '+' in tAfterCNode means no match !!!
			Set:""'=tCNode tCHit=1
			Set:""'=tCNode SeenCNode(tCNode)=1
			if kDom'="" Set tDHit=1
			if (tCNode'="" ) && $Data(tAlphabeticalIndex(tCNode)) Set tDHit=1
			if tCNode'="",kDom="",cNode="" set (tCHit,tDHit)=0
			if (tRemove>1) Set (tCHit,tDHit)=0
		} Else { ; If tCNode']tAfterCNode
			If ""=cNode||(tDAttr=cNode) {
				Set tDHit=1
				Set:cNode'="" SeenCNode(cNode)=1
			} Else {
				Set tCHit=1
				Set:cNode'="" SeenCNode(cNode)=1
			}
		}
		If tDHit {
			Set tAttrName=tDAttr, tValue=tDVal 
			; set namespace used in excluding attribute if pFormat [ $$$OUTPUTSCHEMA
			Set tURI=$g(tDURI)
			; is attribute of form $n:name?
			if $e(tAttrName)="$",tAttrName[":" {
				Set prefix=$P(tAttrName,":")
				if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
					; prefix is of form $number
					Set prefix="xsd_"_$e(prefix,2,*)
					Set localname=$P(tAttrName,":",2)
					Set tAttrName=prefix_":"_localname
				}
			}
		} ElseIf tCHit {
			Set tAttrName=tCAttr, tValue=tCVal
			; set namespace used in excluding attribute if pFormat [ $$$OUTPUTSCHEMA
			Set tURI=$g(tCURI)
		} Else {
			Set tURI=""
		}

		if pFormat[$$$OUTPUTSCHEMAINFO {
			// 10-01-2012
			// exclude attributes whose URI is http://www.w3.org/2001/XMLSchema-instance from output
			if (..schemaLocation'="") {
				if $g(tURI)="http://www.w3.org/2001/XMLSchema-instance" {
					Set tNCAttrName = tAttrName
					if tNCAttrName [ ":" {
						Set tNCAttrName = $P(tAttrName,":",2)
						if tNCAttrName="schemaLocation" {
							Set tAttrName="" ; exclude from output attributes
						}
					}
				}
			}
			if (..noNamespaceSchemaLocation'="") {
				if $g(tURI)="http://www.w3.org/2001/XMLSchema-instance" {
					Set tNCAttrName = tAttrName
					if tNCAttrName [ ":" {
						Set tNCAttrName = $P(tAttrName,":",2)
						if tNCAttrName="noNamespaceSchemaLocation" {
							Set tAttrName="" ; exclude from output attributes
						}
					}
				}
				
			}
		}

		If ""'=tAttrName,($P(tAttrName,":",1)'="xmlns")||pIncludeNamespaces {
			Set pAttrCount=pAttrCount+1
			Set tQ=$S(tValue["""":"!'",tValue["'":"!""",pFormat["q":"""",1:"'")
			Set:"!"=$E(tQ) tQ=$E(tQ,2), tValue=$Replace(tValue,tQ,$S("'"=tQ:"&apos;",1:"&quot;"))
			Set tValue=tQ_$$$CONDXMLESCAPE(pFormat,tValue)_tQ
			if '$D(tAttrSeen(tAttrName)) {
				Set:$find(tAttrName,":") pPrefixes($P(tAttrName,":"))=""
				if pFormat'["a" {
					If $IsObject(pAttrs) {
						Do pAttrs.Write(" "_tAttrName_"="_tValue,,.tSC)
					} Else {
						Set pAttrs=pAttrs_" "_tAttrName_"="_tValue
					}
				} else {
					Set tCollated(tAttrName)=tValue
				}
				Set tAttrSeen(tAttrName)=tValue
				if pInputAttr'="",pInputAttr=tAttrName Set pAttrIndex=pAttrCount quit
				if pInputCount'="",pAttrCount=pInputCount Set pOutputName=tAttrName,pOutputValue=$e(tValue,2,*-1) quit
			}
		}
		if (((cNode'="")&&($D(tAttrSeen(cNode))||($P(cNode,":",1)="xmlns")))||(cNode=""))||(tCNode]tAfterCNode)||('tCHit&&'tDHit)||(kDom="") {
			// Reason for blocking getting next: the current cNode may not have been processed yet!
			$$$domNextHandle(..%ContentRef,tChildList,tAttribute,tOffset)
		} 

		Set tCount=$i(tCount) 
	} // end while

	if pFormat["a" {
		Set a="" for { Set a=$O(tCollated(a),1,val) q:a="" 
			If $IsObject(pAttrs) {
				Do pAttrs.Write(" "_a_"="_val,,.tSC)
			} Else {
				Set pAttrs=pAttrs_" "_a_"="_val
			}

		}
	}
	Quit tSC
}

/// Get all namespaces in the subttree determined by pContentSubs and pDOMSubs
/// returns whether any namespaces found
Method domGetAllNamespaces(ByRef pValue As %String, pDOMPath As %String, pContentSubs As %String, pDOMSubs As %String, pFormat As %String, ByRef pNSContext As %String, pCHit As %Boolean, pDHit As %Boolean, pNamespaces As %String, ByRef level = 0, ByRef SeenCNode, ByRef cSeen, ByRef pSC, ByRef pCachedNamespaces, pCount As %Integer = 1) As %Boolean [ Internal ]
{
	/*
	pFormat flags:
	1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)
	a : attributes alphabetical
	c : canonical ; ignores 'eintw'
	e : close elements even when empty
	f : full top element not just its contents
	i : indent with 4 spaces unless 't' or 1-9
	n : newline (lf) after every text-free element
	p : suppress output of namespace prefixes
	q : use double quotes to set off attribute values if possible
	s : use stored indentation whitespace (ignores 'it1-9')
	r : use stored returns / newlines (ignores 'nw')
	t : indent with tab
	u : declare prefixes as well as using them
	w : Windows-style cr/lf newline after every text-free element
	x : omit namespaces in output
	*/
	Set tNamespaceFound=0
	Set level=$i(level)
	Set pNSContext("level")=$i(pNSContext("level"))
	if pContentSubs=0 { // magic number - because domGetNamespaces looks at top element if pContentSubs=0, ruining synchronization of domGetAllNamespaces and domGetSubtree
		Set level=$i(level)
		Set pNSContext("level")=$i(pNSContext("level"))
	}
	Set tLevel=pNSContext("level")

	if (tLevel > 0) {
		merge pNSContext(tLevel,"namespaces")=pNSContext(tLevel-1,"namespaces")
	}

	;merge tNSContextSave=pNSContext

	if (pCHit=0)&&(pDHit=0) Set level=level-1 Set pSC=$$$ERROR($$$EnsErrGeneral,"Unable to fetch sub-tree, no hit at "_pDOMPath_" pContentSubs="_pContentSubs_" pDOMSubs="_pDOMSubs) quit 0
	;kill pNSContext(pNSContext("level"),"namespaces") ; don't use namespaces set at this level
	#; if (pDHit=0) Set pCHit=1
	if (pContentSubs=">")||(pContentSubs="-1") set pContentSubs=""
	Set pSC=$$$OK

	Set (tRemove,tReplace,tReplaceContent,tEc)=0, tElem=""
	Set tIgnoreContentSubs=0
	Set tSetFirstC=0
	#;Set tPrecedingNonElements=0
	;If ("_"'=pDOMSubs)&&(pDOMPath'="/")&&$D(@$$$vaDOMRef(pDOMSubs))&&pDHit {
	If pDHit&&("_"'=pDOMSubs)&&$D(@$$$vaDOMRef(pDOMSubs)) {
		#; ">R"=2 : Remove entire element, ">R"=1 : =Replace entire element contents(including attributes), ">R"="" : extend contents	
		Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">R""")), tRemove=(tReplace>1)
		Set tReplaceContent=(tReplace="c")
		Set tEc=(tReplace="d")
		Set:tReplace pContentSubs=""  ; ignore content node if so marked
		If 'tRemove {
			Set tElem=$E($TR($P(pDOMSubs,",",$L(pDOMSubs,",")-1),"""",""),2,*)
			Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.pSC)
			// 10-13-11
			if tElem="/",pDOMPath="/" {
				Set tIgnoreContentSubs=1
			}
			if tElem="/",pDOMPath="/",$g(@$$$vaDOMRef(pDOMSubs_",""1"""))'="",$e(@$$$vaDOMRef(pDOMSubs_",""1"""))=">" {
				Set tSetFirstC=1
				#;Set tPrecedingNonElements=0
				;Set tIgnoreContentSubs=0
			}
			Set:"/"=tElem tElem=""
			If $$$ISERR(pSC) {
				Set level=level-1
				Quit 0
			}
		}
	}
	#; Get tElem from Content array if not in DOM array
	Set tNamespaceDef=""
	If 'tIgnoreContentSubs,(pCHit),(""'=pContentSubs),$D(@$$$vaContentRef(pContentSubs)) { // syntax-error
		// 09-29-10, support namespaces
		;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
		if pContentSubs'=0 { //  !!!
			Set tElem=$$$xmlGetQName(..%ContentRef,pContentSubs)
		} else {
			Set tElem=$G(@$$$vaContentRef(pContentSubs)) 
		}
		Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.pSC)
		Set tElem=..SchematizeNamespace((pFormat["u"),pContentSubs,tElem,.tNamespaceDef,.pNSContext)
		if $$$ISERR(pSC) {
			Set level=level-1 quit 0
		}
	}

	#; Output the top element if called for
	Set pFormat=$ZStrip(pFormat,"<WC")
	Set tIndent=$ZStrip(pFormat,"<AN"), pFormat=$E(pFormat,1,*-$L(tIndent))
	merge tNamespaceNodes=pNSContext(pNSContext("level"),"namespaces")
	Set tOldElem=tElem
	If 1 { // ""'=tElem && (pFormat["f") {
		;if pDOMPath'="/" Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set tNamespaces=""
		if (pNamespaces="") { 
			// 10-01-2012, replace domGetNamespaceHelper with domGetNamespaces
			//do ..domGetNamespaceHelper(.tNamespaces,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),.pNSContext,.tNamespaceFound1,.pCachedNamespaces,pCount)
			do ..domGetNamespaces(.tNamespaces,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),.pNSContext,pFormat,.tNamespaceFound1,.pCachedNamespaces,pCount)
			;Set pCachedNamespaces(level,pCount,"pNamespaces")=tNamespaces			
			if tNamespaceFound=0 Set tNamespaceFound=tNamespaceFound1
		} else {
			;Set pCachedNamespaces(level,pCount,"pNamespaces")=pNamespaces
			Set tNamespaces=pNamespaces
			Set tNamespaceFound=1
		}
		;Set tHasText=$G(pNSContext(pNSContext("level")-1,"opentext"))
		;Set tOpen=$G(pNSContext(pNSContext("level")-1,"open"))

	} Else { Set tElem = "" }
	Set:tReplaceContent pContentSubs=""  ; ignore content node if so marked after fetching attributes
	#; for all child elements we always want the whole enchilada
	If pFormat'["f" Set pFormat=pFormat_"f"
	If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,pFormat["t":1,1:4))="" }
	Else { Set tTab="" }
	;Set tOldIndent=tIndent  Set:"/"'=$P(pDOMPath,"full()") tIndent=tIndent_tTab

	#; Loop over nodes in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting nodes in order
	//Set pCount=1 ; number of element
	do ..createIndex(pDOMSubs,.Index)
	Set (tAfterCNode,tCNode,tParentCNode,tRemove,tReplace)=""
	Set (dtyp,ctyp)=""
	Set (kDom)=$S("_"=pDOMSubs:"",1:-1), cNode=-1,(tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if (tSetFirstC),$D(@..%ContentRef) {
		Set cNode=pContentSubs
		Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
	}
	Set tElemName=""
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	Set tRootDone=0
	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	Set pCount=0 ; 10-01-2012 does this need to be initialized?
	While (((""'=kDom)||(""'=cNode)))&&'tRootDone {
		;w !,"tAfterCNode="_tAfterCNode_" tCNode="_tCNode
		Set dok=1
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ((""'=kDom) && (dok) && (tDHit || (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode="")))))||tSetFirstC {
			#; Retrieve the next DOM child candidate
			Set tElemIndex=1
			if '$D(Index) {
				Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""  Continue:$g(dtyp)=">Z"
			} else {
				if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
				if iIndex'="",jIndex'="" {
					Set dtyp=$LI(Index(iIndex,jIndex),1)
					Continue:$g(dtyp)=">Z"
					Set kDom=+$LI(Index(iIndex,jIndex),2)
					Set IJSeen(iIndex,jIndex)=""
				} 
				if (jIndex="") {
					if iIndex'="" Set iIndex=$O(Index(iIndex))
					if (iIndex="") {
						Set kDom=""
						Set tSetFirstC=0
					}
					continue
				}
			}
			If kDom="" {
				Set tSetFirstC=0
			}
			If ""'=kDom {
				If ">"'=$E(dtyp),dtyp'="" { ; it's an element node
					Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
					Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
				} Elseif dtyp'="" {
					; text, comment, or processing instruction
					Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">I"""))
					Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
				}
			}
		}

		Set doit=1
		if cNode'=-1,cNode'="",'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if tCNode'=-1,tCNode'="",'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}

		If 'tSetFirstC && (""'=cNode) && (doit) && (""=kDom || tCHit || (($$$domGE(tAfterCNodeNoPlus,tCNode))&&(tAfterCNode'=""))) {
			#; Retrieve the next Content child candidate
			// Set cNode=$$$xmlGetNextChild(..%ContentRef,pContentSubs,c)  Quit:""=cNode
			// 01-31-12
			Set cNode=$S(""=pContentSubs:"", 1:$$$domGetNextChild(..%ContentRef,pContentSubs,cNode))
			Set:cNode'="" ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
			If ""'=cNode {
				Set tCNode=cNode
			} 
		}
		; removed process combined text
		$$$ASSERT('tParentCNode||(tParentCNode=pContentSubs))
		Set (tCHit,tDHit)=0
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If $$$domGT(tCNode,tAfterCNodeNoPlus) {
			;If ""=tAfterCNode||(kDom="") {
			;If (((""=tAfterCNode)&&($e(dtyp)=">"))||(kDom="")) {
			If ((cNode'="") && (kDom="")) {
				Set tCHit=1
				Set:""'=tCNode SeenCNode(tCNode)=""
			} Else {
				Set tDHit=1
				Set:""'=kDom SeenKNode(kDom)=""
				If $$$xmlELEMENTNODE=ctyp {
					// 09-29-10, support namespaces
					;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
					Set tElemName=$$$xmlGetQName(..%ContentRef,tCNode)
				}
			}
		} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
			Set:(""'=tCNode)||(tAfterCNode="") (tCHit,tDHit)=1
			If tRemove {
				set (tCHit,tDHit)=0
			}
			if tReplaceContent {
				Set tCHit=0
			}
			if tEc,$$$xmlTEXTNODE=ctyp {
				Set tCHit=0
			}
			Set:""'=tCNode SeenCNode(tCNode)=""
			Set:""'=kDom SeenKNode(kDom)=""
		} Else { ; If tCNode<=tAfterCNode
			;If ((""=cNode)&&(tElemName'="")) {
			If (cNode="")||(tSetFirstC) {
				Set tDHit=1
				Set:""'=kDom SeenKNode(kDom)=""
			} ElseIf tCNode'="" {
				Set tCHit=1
				Set:""'=tCNode SeenCNode(tCNode)=""
			} Else {

			}
		}
		If tDHit {
			If ">"'=$E(dtyp),dtyp[">" { ; it's an element node
				Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
				Set tAttrSubs=pDOMSubs_","">"_tElemName_""","_tElemIndex
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
				Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
				Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
				Set tReplaceContent=(tReplace="c")
				if (tCHit){
					Set:tCNode'="" cSeen(tCNode)=""
				}
				if kDom'="",'$D(kSeen(kDom)) {
					if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
					// 11-07-11
					Set tSetFirstC=0
					// 11-08-2011
					if 'tEc,tElemName'="/" {
						Set pCount=$i(pCount)
						Set tNamespaceFound1=..domGetAllNamespaces(.tVal,$S(""=pDOMPath:"",1:pDOMPath_tElemName),cNode,$S("_"=pDOMSubs:"_",1:tAttrSubs),pFormat_$s(pDOMPath="/":"",1:tIndent),.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,.pSC,.pCachedNamespaces,pCount) Quit:$$$ISERR(pSC)
						if tNamespaceFound=0 Set tNamespaceFound=tNamespaceFound1
					}
				}
				if kDom'="" Set kSeen(kDom)=""
			} Else {
				if (pDHit),tOldElem'="/" {
					if kDom'="" Set kSeen(kDom)=""
				}
			}
		} ElseIf tCHit {
			if (tCNode'="") {
				If $$$xmlELEMENTNODE=ctyp { 
					// 09-29-10, support namespaces
					;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
					Set tElemName=$$$xmlGetQName(..%ContentRef,tCNode)
				}
			}
			If $$$xmlELEMENTNODE=ctyp { ; it's an element node
				if '$D(cSeen(tCNode)) {
					if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
					if 'tEc {
						Set pCount=$i(pCount)
						Set tNamespaceFound1=..domGetAllNamespaces(.tVal,$S(""=pDOMPath:"",1:pDOMPath_tElemName),tCNode,$S("_"=pDOMSubs:"_",kDom="":"_",1:pDOMSubs_","_kDom),pFormat_tIndent,.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,.pSC,.pCachedNamespaces,pCount) Quit:$$$ISERR(pSC)
						if tNamespaceFound=0 Set tNamespaceFound=tNamespaceFound1
					}
					if kDom="",tCNode=1 Set tRootDone=1
					Set cSeen(tCNode)=1
					Set SeenCNode(tCNode)=""
				} else {
					Set pSC=$$$OK
				}
			} ElseIf $$$xmlTEXTNODE=ctyp{
				if (pCHit&&(tEc'=1)) {
					if '$D(cSeen(tCNode)) {
						Set SeenCNode(tCNode)=""
						Set cSeen(tCNode)=1
					}
				}
			}
		}
	}
	Kill pNSContext(pNSContext("level"),"namespaces")
	Set pNSContext("level")=pNSContext("level")-1
	;merge pNSContext(pNSContext("level")+1,"namespaces")=pNSContext(pNSContext("level"),"namespaces")
	kill pNSContext(pNSContext("level"),"namespaces")
	merge pNSContext(pNSContext("level"),"namespaces")=tNamespaceNodes	
	Set level=level-1

	Quit:$$$ISERR(pSC) 0

	;merge pNSContext=tNSContextSave
	Quit tNamespaceFound
}

/// Get the namespaces of the given element
Method domGetNamespaceHelper(ByRef pNamespaces As %String, pContentSubs As %String, pDOMSubs As %String, ByRef pNSContext As %String, ByRef pNamespaceFound As %Boolean, ByRef pCachedNamespaces, pCount As %Integer) As %Status [ Internal ]
{
	Set pNamespaceFound=0
	if pContentSubs=0 Set pContentSubs=$$$xmlGetDocumentElement(..%ContentRef)
	Set pNamespaces=$G(pNamespaces)
	#; Loop over namespaces in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting namespace nodes in order
	Set kDom=$S("_"=pDOMSubs:"",1:-1), cNode=-1, (tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if ((pDOMSubs'="")&&(pDOMSubs'="_")) {
		do ..createAttrOrNamespaceIndex(pDOMSubs, "", .Index)
	} 
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	;Set level=pNSContext("level")+1
	Set level=pNSContext("level")
	if ((level > 0)&&$D(pNSContext(level-1,"namespaces"))) {
		 merge pNSContext(level,"namespaces")=pNSContext(level-1,"namespaces")
	}
	Set:'$D(@..%ContentRef) cNode=""
	While (""'=kDom)||(""'=cNode) {
loop ;
		Set (tAttrName,tDAttr,tCAttr,tValue,tDVal,tCVal,tAfterCNode,tCNode)="", (tRemove,tReplace)=0
		
		;If ""'=kDom && (tDHit || ((tAfterCNode<=tCNode)&&(($e(tAfterCNode)'="+")||(tAfterCNode<tCNode)||(cNode="")))) {
		If (""'=kDom && (tDHit || ($$$domLE(tAfterCNode,tCNode)))) {
			#; Retrieve the next DOM child candidate
			Set tElemIndex=1

			if '$D(Index) {
				Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""
			} else {
				if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
				if iIndex'="",jIndex'="" {
					Set dtyp=$LI(Index(iIndex,jIndex),1)
					Set kDom=+$LI(Index(iIndex,jIndex),2)
					Set IJSeen(iIndex,jIndex)=""
				}
				if (jIndex="") {
					if iIndex'="" Set iIndex=$O(Index(iIndex))
					if (iIndex="") {
						Set kDom=""
					}
					continue
				}
			}
			If ""'=kDom {
				Set tDAttr=$P(dtyp,">",1), tDVal=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""""))
				if ('$find(tDAttr,":")&&(tDAttr'="xmlns"))||($P(tDAttr,":")'="xmlns") {
					#; only process namespaces here
					Set tDAttr=""
					Set tDVal=""
					goto loop
				}
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">I"""))
				Set tRemove=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">R"""))
				Set prefix=$P(tDAttr,":",2)
				if $D(pNSContext(level,"namespaces","xmlns"_$s(prefix'="":":",1:"")_prefix),uriFromContext) {
					if tDVal=uriFromContext {
						Set tDAttr=""
						Set tDVal=""
						Set tDHit=1
						continue
					}
				}
			}
		}
		#; Set:'$D(@..%ContentRef) cNode=""
		If (""'=cNode && (""=kDom || tCHit)){
			#; Retrieve the next Content child candidate
			;Set cNode=$S(""=pContentSubs:"", 1:$O(@$$$vaContentRef(pContentSubs_",""a"","""_cNode_""""),1,ctyp))
			Set cNode=pContentSubs
			; Don't use namespace if it is already present in DOM array and hence is a duplicate
			; in XML namespaces can't be repeated
			if ""'=cNode,cNode'=-1 {
				; Get prefix of node
				Set qName=$$$domGetQName(..%ContentRef,cNode)
				; Get uri of namespace of node
				if $find(qName,":") {
					Set prefix=$P(qName,":",1)
				} else {
					Set prefix=""
				}
				// 05-09-2012 fix <UNDEFINED> error
				Set uri=$$$domGetNamespaceURI(..%ContentRef,cNode)
				if (uri="") {
					; no match
					Set cNode=""
					goto loop
				}
				if $D(pNSContext(level,"namespaces","xmlns"_$s(prefix'="":":",1:"")_prefix),uriFromContext) {
					if uri=uriFromContext {
						Set cNode=""
						Set tCAttr=""
						Set tCVal=""
						Set tCHit=1
						Set tCNode=cNode
						continue
					}
				}
				; create "property" cAttr=xmlns:prefix, tcVal=uri
				Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
				if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))),uri'="" {
					Set tCAttr="xmlns"_$s(prefix'="":":",1:"")_prefix
					Set tCVal=uri
					Set tCNode=cNode
				}
			}
			Set cNode="" ; only one node to march
		}
		Set (tCHit,tDHit,tPlus)=0
		Set:"+"=$E(tAfterCNode) tAfterCNode=$E(tAfterCNode,2,*),tPlus=1
		If tCNode]tAfterCNode {
			If ""=tAfterCNode||(kDom="") {
				Set tCHit=1
			} Else {
				Set tDHit=1
			}
		} ElseIf tCNode=tAfterCNode && 'tPlus { ; '+' in tAfterCNode means no match !!!
			Set:""'=tCNode tCHit=1
			if kDom'="" Set tDHit=1
			if tCNode'="",kDom="",cNode="" set (tCHit,tDHit)=0
			if (tRemove>1) Set (tCHit,tDHit)=0
		} Else { ; If tCNode']tAfterCNode
			If ""=tCNode {
				Set tDHit=1
			} Else {
				Set tCHit=1
			}
		}
		If tDHit { Set tAttrName=tDAttr, tValue=tDVal }
		ElseIf '('$find(tCAttr,":")&&(tCAttr'="xmlns"))||($P(tCAttr,":")'="xmlns")  { Set tAttrName=tCAttr, tValue=tCVal }
		If ""'=tAttrName,'$D(Seen(level,tAttrName)) {
			Set pNamespaceFound=1
			Set pNSContext(level,"namespaces",tAttrName)=tValue
			Set pCachedNamespaces(level,pCount,tAttrName)=tValue
			Set tQ=$S(tValue["""":"!'",tValue["'":"!""",1:"'")
			Set:"!"=$E(tQ) tQ=$E(tQ,2), tValue=$Replace(tValue,tQ,$S("'"=tQ:"&apos;",1:"&quot;"))
			Set tValue=tQ_tValue_tQ
			Set pNamespaces=pNamespaces_" "_tAttrName_"="_tValue
			Set pCachedNamespaces(level,pCount,"pNamespaces")=$g(pCachedNamespaces(level,pCount,"pNamespaces"))_" "_tAttrName_"="_tValue
			Set Seen(level,tAttrName)=""
		}
	} ; end-loop
}

/// Get the namespaces of the given element
Method domGetNamespaces(pNamespaces As %String, pContentSubs As %String, pDOMSubs As %String, ByRef pNSContext As %String, pFormat As %String = "", ByRef pNamespaceFound As %Boolean, ByRef pCachedNamespaces, pCount As %Integer = "") As %Status [ Internal ]
{
	Set tSC=$$$OK
	// 10-01-2012 inject functionality of domGetNamespaceHelper into domGetNamespaces
	Set pNamespaceFound=0 // passed by domGetAllNamespaces, tell code we haven't found any namespaces yet
	if pContentSubs=0 Set pContentSubs=$$$xmlGetDocumentElement(..%ContentRef)
	Set pNamespaces=$G(pNamespaces)
	#; Loop over namespaces in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting namespace nodes in order
	Set kDom=$S("_"=pDOMSubs:"",1:-1), cNode=-1, (tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if ((pDOMSubs'="")&&(pDOMSubs'="_")) {
		do ..createAttrOrNamespaceIndex(pDOMSubs, "", .Index)
	} 
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	;Set level=pNSContext("level")+1
	Set level=pNSContext("level")
	if pCount'="" { ; only non-empty if called from domGetAllNamespaces
		;Set pCachedNamespaces(level,pCount,"pNamespaces")="" ; init this value
	}
	if ((level > 0)&&$D(pNSContext(level-1,"namespaces"))) {
		 merge pNSContext(level,"namespaces")=pNSContext(level-1,"namespaces")
	}
	if pFormat[$$$OUTPUTSCHEMAINFO {
		if (..schemaLocation'="")||(..noNamespaceSchemaLocation'="") {
			Set pNSContext(level,"namespaces","xmlns:xsi")="http://www.w3.org/2001/XMLSchema-instance"
		}
	}
	Set:'$D(@..%ContentRef) cNode=""
	While (""'=kDom)||(""'=cNode) {
loop ;
		Set (tAttrName,tDAttr,tCAttr,tValue,tDVal,tCVal,tAfterCNode,tCNode)="", (tRemove,tReplace)=0

		// Look for namespace at this node, in our DOM array
		;If ""'=kDom && (tDHit || ((tAfterCNode<=tCNode)&&(($e(tAfterCNode)'="+")||(tAfterCNode<tCNode)||(cNode="")))) {
		If (""'=kDom && (tDHit || ($$$domLE(tAfterCNode,tCNode)))) {
			#; Retrieve the next DOM child candidate
			Set tElemIndex=1

			if '$D(Index) {
				Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""
			} else {
				if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
				if iIndex'="",jIndex'="" {
					Set dtyp=$LI(Index(iIndex,jIndex),1)
					Set kDom=+$LI(Index(iIndex,jIndex),2)
					Set IJSeen(iIndex,jIndex)=""
				}
				if (jIndex="") {
					if iIndex'="" Set iIndex=$O(Index(iIndex))
					if (iIndex="") {
						Set kDom=""
					}
					continue
				}
			}
			If ""'=kDom {
				Set tDAttr=$P(dtyp,">",1), tDVal=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""""))

				if ('$find(tDAttr,":")&&(tDAttr'="xmlns"))||($P(tDAttr,":")'="xmlns") {
					#; only process namespaces here
					Set tDAttr=""
					Set tDVal=""
					goto loop
				}
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">I"""))
				Set tRemove=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">R"""))
				Set prefix=$P(tDAttr,":",2)
				if $D(pNSContext(level,"namespaces","xmlns"_$s(prefix'="":":",1:"")_prefix),uriFromContext) {
					if tDVal=uriFromContext {
						Set tDAttr=""
						Set tDVal=""
						Set tDHit=1
						continue
					}
				}
			}
		}
		#; Set:'$D(@..%ContentRef) cNode=""
		If (""'=cNode && (""=kDom || tCHit)){
			#; Retrieve the next Content child candidate
			;Set cNode=$S(""=pContentSubs:"", 1:$O(@$$$vaContentRef(pContentSubs_",""a"","""_cNode_""""),1,ctyp))
			Set cNode=pContentSubs
			; 03-01-2012 <UNDEFINED> in $$$domGetQName
			; Don't use namespace if it is already present in DOM array and hence is a duplicate
			; in XML namespaces can't be repeated
			if ""'=cNode,cNode'=-1 { // ,$$$xmlELEMENTNODE=$$$xmlGetNodeType(..%ContentRef,cNode) { ; guard against doing on non-element node to avoid an <UNDEFINED> error 03-02-2012
				; Get prefix of node
				Set qName=$$$domGetQName(..%ContentRef,cNode)
				; Get uri of namespace of node
				if $find(qName,":") {
					Set prefix=$P(qName,":",1)
				} else {
					Set prefix=""
				}
				Set uri=$$$domGetNamespaceURI(..%ContentRef,cNode)
				if (uri="") {
					; no match
					;Set cNode="" ; 09/28/2012 removed because we are going to walk cNode attributes
					goto walkAttributes ; check if namespaces introduced in attributes
				}
				if $D(pNSContext(level,"namespaces","xmlns"_$s(prefix'="":":",1:"")_prefix),uriFromContext) {
					if uri=uriFromContext {
						goto walkAttributes ; check if namespaces introduced in attributes
					}
				}
				; create "property" cAttr=xmlns:prefix, tcVal=uri
				Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
				if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))),uri'="" {
					Set tCAttr="xmlns"_$s(prefix'="":":",1:"")_prefix
					Set tCVal=uri
					Set tCNode=cNode
					Set tCNamespaceArray(tCAttr)=uri
				}
			}
walkAttributes ; element may not introduce a namespace but may still have attributes that introduce namespaces			
			// 9/28/2012 walk attributes below cNode and add them a tCNamespaceArray multidimensional variable
			// Get childList and descriptor from node, note internal API
			if cNode'="",cNode'=-1,$$$xmlGetNodeType(..%ContentRef,cNode)=$$$xmlELEMENTNODE {
				$$$xmlaGetChildList(..%ContentRef,cNode,tChildList,tDescriptor)
			} else {
				Set tChildList=""
			}
			if (tChildList'="") {
				$$$xmlaForEachAttribute(..%ContentRef,tChildList,o,attribute)
				
					// look at attributes that have prefixes pointing to namespaces
					Set qName=$$$domGetAttributeQName(..%ContentRef,pContentSubs,attribute)
					if $find(qName,":") {
						Set prefix=$P(qName,":",1)
					} else {
						Set prefix=""
					}
					if qName'="xmlns" && (prefix'="xmlns") {
						Set uri=$$$domGetAttrNamespaceURI(..%ContentRef,pContentSubs,attribute)
						if $D(pNSContext(level,"namespaces","xmlns"_$s(prefix'="":":",1:"")_prefix),uriFromContext) {
							if uri'=uriFromContext {
								; create "property" cAttr=xmlns:prefix, tcVal=uri
								Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
								if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))),uri'="" {
									Set tCAttr="xmlns"_$s(prefix'="":":",1:"")_prefix
									Set tCVal=uri
									Set tCNode=cNode
									Set tCNamespaceArray(tCAttr)=uri
								}
								
							}
						} else {
							; create "property" cAttr=xmlns:prefix, tcVal=uri
							Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
							if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))),uri'="" {
								Set tCAttr="xmlns"_$s(prefix'="":":",1:"")_prefix
								Set tCVal=uri
								Set tCNode=cNode
								Set tCNamespaceArray(tCAttr)=uri
							}
							
						}
					}
#ifdef VERSION31ORABOVE
					// look at attribute that is a namespace xmlns:prefix or xmnlns namespace declarer
					Set qName=$$$domGetAttributeQName(..%ContentRef,pContentSubs,attribute)
					if $find(qName,":") {
						Set prefix=$P(qName,":",1)
					} else {
						Set prefix=""
					}
					if qName="xmlns" || (prefix="xmlns") {
						Set uri=$$$xmlaGetAttribute(..%ContentRef,attribute)
						if $D(pNSContext(level,"namespaces",qName),uriFromContext) {
							if uri'=uriFromContext {
								; create "property" cAttr=xmlns:prefix, tcVal=uri
								Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
								if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))) {
									Set tCAttr=qName
									Set tCVal=uri
									Set tCNode=cNode
									Set tCNamespaceArray(tCAttr)=uri
								}
								
							}
						} else {
							; create "property" cAttr=xmlns:prefix, tcVal=uri
							Set tNameSpaceSubs=pDOMSubs_","">"_"xmlns"_$s(prefix'="":":",1:"")_prefix_""""
							if pDOMSubs="_"||('$D(@$$$vaDOMRef(tNameSpaceSubs))) {
								Set tCAttr=qName
								Set tCVal=uri
								Set tCNode=cNode
								Set tCNamespaceArray(tCAttr)=uri
							}
							
						}
					}
#endif
				$$$xmlaEndForEachAttribute(..%ContentRef,tChildList,o,attribute)
			}
			Set cNode="" ; only one node to march
		}
		Set (tCHit,tDHit,tPlus)=0
		Set:"+"=$E(tAfterCNode) tAfterCNode=$E(tAfterCNode,2,*),tPlus=1
		If tCNode]tAfterCNode {
			If ""=tAfterCNode||(kDom="") {
				Set tCHit=1
			} Else {
				Set tDHit=1
			}
		} ElseIf tCNode=tAfterCNode && 'tPlus { ; '+' in tAfterCNode means no match !!!
			Set:""'=tCNode tCHit=1
			if kDom'="" Set tDHit=1
			if tCNode'="",kDom="",cNode="" set (tCHit,tDHit)=0
			if (tRemove>1) Set (tCHit,tDHit)=0
		} Else { ; If tCNode']tAfterCNode
			If ""=tCNode {
				Set tDHit=1
			} Else {
				Set tCHit=1
			}
		}
		If tDHit {
			Set tAttrName=tDAttr, tValue=tDVal 
			If tAttrName'="",'$D(Seen(level,tAttrName)) {
				Set pNSContext(level,"namespaces",tAttrName)=tValue
				// inject functionalty of domGetNamespaceHelper here
				if pCount'="" {
					Set pNamespaceFound=1
					Set pCachedNamespaces(level,pCount,tAttrName)=tValue
				}
				
				Set tQ=$S(tValue["""":"!'",tValue["'":"!""",1:"'")
				Set:"!"=$E(tQ) tQ=$E(tQ,2), tValue=$Replace(tValue,tQ,$S("'"=tQ:"&apos;",1:"&quot;"))
				Set tValue=tQ_tValue_tQ
				do pNamespaces.addNamespace(tAttrName,tValue)
				Set Seen(level,tAttrName)=""
			}
			
		}
		Else {
			Set tCVal=""
			Set tNsIdx=0
			Set tCAttr="" for {  Set tCAttr=$O(tCNamespaceArray(tCAttr),1,tCVal) q:tCAttr=""
				If '('$find(tCAttr,":")&&(tCAttr'="xmlns"))||($P(tCAttr,":")'="xmlns")  {
					Set tAttrName=tCAttr, tValue=$g(tCVal) 
					If tAttrName'="",'$D(Seen(level,tAttrName)) {
						Set pNSContext(level,"namespaces",tAttrName)=tValue
						// inject functionality of domGetNamespaceHelper here
						if pCount'="" {
							Set pNamespaceFound=1
							Set pCachedNamespaces(level,pCount,tAttrName)=tValue
						}					
						Set tQ=$S(tValue["""":"!'",tValue["'":"!""",1:"'")
						Set:"!"=$E(tQ) tQ=$E(tQ,2), tValue=$Replace(tValue,tQ,$S("'"=tQ:"&apos;",1:"&quot;"))
						Set tValue=tQ_tValue_tQ
						do pNamespaces.addNamespace(tAttrName,tValue)
						if pCount'="" {
							Set pCachedNamespaces(level,pCount,"pNamespaces")=$g(pCachedNamespaces(level,pCount,"pNamespaces"))_" "_tAttrName_"="_tValue
						}
						Set Seen(level,tAttrName)=""
					}
				}
			} // end for over tCNamespaceArray
		} ; end-else
	} // end-while
	Quit tSC
}

Method calcISubscript(pDSubs As %String, pElemAndIndex As %String) [ Internal ]
{
	Set tElem=$p(pElemAndIndex,">",1)
	Set tNodeIndex=$p(pElemAndIndex,">",2)
	; 4-22-11
	;Set pDSubs=pDSubs_$s(tElem'="":","">"_tElem_"""",1:"")_$S('tNodeIndex:"",1:","_tNodeIndex)
	Set pDSubs=pDSubs_","">"_tElem_""""_$S('tNodeIndex:"",1:","_tNodeIndex)
	quit pDSubs
}

Method domLookUpAttrNumber(pDSubs As %String, pAttrName As %String) [ Internal ]
{
	; attribute number lookup
	; TBD JSL 9-13-10, do we have to merge with content array?
	Set pDSubs=pDSubs_","">@"""
	Set kDom=$S("_"=pDSubs:"",1:-1)
	Set count=0
	Set found=0
	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Quit:""=kDom
		Continue:$e(kDom)=">"
		if dtyp=pAttrName Set found=1 quit
		Set count=count+1
	}
	if (kDom="") {
		quit count+1
	} else {
		if (found=1) {
			quit kDom
		} else {
			quit count+1
		}
	}
}

Method calcInsertIndex(pDSubs As %String, pElemAndIndex As %String) [ Internal ]
{
	quit pElemAndIndex
}

/// Set tIndex="" to return count<br/>
/// findIndex - return information about child of XML parent at pDSubs,pCSubs.  findIndex walks children.  The children are all siblings.<br/>
/// Arguments:<br/>
/// input<br/>
/// pDSubs - parent in DOM array - maybe "_" to indicate no DOM array parent<br/>
/// pCSubs - parent in Content Array - maybe "" to indicate no Content Array parent (in which case no Content Array)<br/>
/// pElem - name of element we are looking for in children, else null<br/>
/// pIndex - ordinal of element we are looking for or ordinal of node (in all children, including textual children)<br/>
/// pIsNode - element or node - 0 or 1<br/>
/// Existing - are we looking for existing node or element?<br/>
/// isTypeElement - we are looking for an element = 1, some other node type (text, comment, etc.,) 0<br/>
/// pRightType - the type of what we are looking for, e.g. text /ElemA/text(3) - look for third text node<br/>
/// pIgnoreNamespaces - in looking for match - ignore matching namespaces, if NCNames match it is enough<br/>
/// pNamespaces - object reference containing namespace information<br/>
/// pNSContext - local array containing namespace information<br/>
/// pUnSorted - was control to determine when we need to sort kDOM by tAfterCNode, now always 0<br/>
/// pReturnRemoved - idea was we would return match of removed element, always 0, no longer relevant<br/>
/// OUTPUT<br/>
/// pStatus - a status<br/>
/// pCHit - match in content array<br/>
/// pDHit - match in DOM array (can be match in both content array and DOM array, in which case DOM array wins)<br/>
/// pNode - the child Content Array node which is matched<br/>
/// prevCNode - the child Content Array node "left of" what is matched (in sibling order)<br/>
/// pElemIndex - a decomposed value in matching DOM array node ( pElemName>pElemIndex is value of node)<br/>
/// pElemName - see pElemIndex<br/>
/// nFound - ordinal number of found node<br/>
/// isElementOut - is matched node an element?  if 1 it is.<br/>
/// pOutputType - type of matched element - element,text,comment, etc.,
/// pCount - count of input, for example /root/ElemA[*]
/// pMatchedElemName - when searching for Nth element,e.g., element()[N] - we want to know name that matched<br/>
/// kReturn - variable introduce to solve bug that was another problem, needs to be removed at some point<br/>
/// kFinal - this looks like another variable, which is no longer used<br/>
/// Note there are 13 input arguments and 14 output arguments<br/>
Method findIndex(pDSubs As %String, pCSubs As %String, pElem As %String, pIndex As %String, pIsNode As %Boolean, ByRef pStatus As %Status, ByRef pCHit As %Boolean, ByRef pDHit As %Boolean, ByRef pNode As %String, ByRef prevCNode As %String, Existing As %Boolean, ByRef pElemIndex As %String, ByRef pElemName As %String, isTypeElement As %Boolean, pRightType As %String, ByRef nFound As %Integer, Output isElementOut As %Boolean, Output pOutputType, Output pCount, pIgnoreNamespaces As %Boolean = 0, Output pMatchedElemName As %String, ByRef pNamespaces, ByRef pNSContext As %String, Output kReturn, pUnSorted As %Boolean = 0, pReturnRemoved As %Boolean = 0, ByRef kFinal As %String) [ Internal ]
{
	; we are inserting at pIndex which may come after node in content array or after node in DOM array
	; we should probably set pStatus to error and return error if there is no element at pIndex-1
	Set pStatus=$$$OK
	Set isElementOut=0
	Set pOutputType="unknown"
	Set p0=i%%PurgeIndex
	Set pd=$s(pDSubs="":$c(0),1:pDSubs)
	#; Make a subscript composed of the 3 arguments delimited by $c(0)
	Set p1=pCSubs_$c(0)_pElem
	#; Make a number 0-63 out of the 6 boolean arguments
	Set p3=(((($g(Existing)*2+$g(isTypeElement))*2+
		 $g(pIgnoreNamespaces))*2+
		 $g(pUnSorted))*2+
		 $g(pReturnRemoved))*2+
		 pIsNode

	if pElem="/",pIndex=1 {
		Set tDOMSubs=",1"
		Set rootPair=$g(@$$$vaDOMRef(tDOMSubs))
		if (rootPair'="") {
			Set root=$P(rootPair,">")
			if (root="/") { ; we have preceding processing instructions or comments
				Set pOutputType="element"
				Set pDHit=1
				Set pCount=1
				Set kReturn=1
				Set kFinal=1
				Set pElemIndex=1
				Set pCHit=0
				Set pNode=""
				Set pStatus=$$$OK
				Set tQuitValue=1
				// Set cacheValue
				goto returnFindIndex
			}
		}
	}

	// initialization
	; detect if element is marked with a "c" (replace content) or a "d" (rule Ec)
	; we will be traversing sub-elements, text, comments, and processing instructions
	Set tReplace1=$G(@$$$vaDOMRef(pDSubs_","">R""")), tRemove1=(tReplace1>1)
	Set tReplaceContent=(tReplace1="c")
	set tEc=(tReplace1="d")
	Set pCount=0
	Set tIndex=pIndex
	$$$ASSERT((tIndex=+tIndex)||(tIndex=""))
	Set (tDHit,tCHit)=0
	Set (tAfterCNode,tParentCNode,tCNode)=""
	Set kDom=$S("_"=pDSubs:"",1:-1), cNode=-1,nFound=0
	Set isRightType=0
	Set foundCNodeOfRightType=0
	if $D(@$$$vaContentRef(0)) if 'pUnSorted do ..createIndex(pDSubs,.Index) ; JSL4382
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	Set kReturn="",outIndex=""
	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
		Set prevCNode=""
	}
	Set kDomLast=kDom,iIndexLast=iIndex,jIndexLast=jIndex
	

	; if cache defined look up loop variables in cache
	If pIndex>1,$S(p0:$D(^||%XML.VDoc.CalcCache(p0,pd,p1)),1:$D(..%CalcCache(pd,p1))) {
	   Set tempIndex=pIndex-1
	   If 'p0 {
		Do {
		   Quit:$D(..%CalcCache(pd,p1,tempIndex,p3),tOutputVector)
		   Set tempIndex=tempIndex-1
		} While tempIndex
	   } Else {
		Do {
		   Quit:$D(^||%XML.VDoc.CalcCache(p0,pd,p1,tempIndex,p3),tOutputVector)
		   Set tempIndex=tempIndex-1
		} While tempIndex
	   }
	}
	If $D(tOutputVector) {
		#; Ignore tOutputVector if possibly incomplete - immediate sibling only had one child
		Set tAfterCNode=$LG(tOutputVector,8)
		Set dtyp=$LG(tOutputVector,11)

		If Existing && (dtyp="+") && ((tAfterCNode="+")||(tAfterCNode="")) && (pDSubs'="") && $Data(@$$$vaDOMRef(pDSubs)) {
			#; Ignore tOuputVector
			Kill dtyp
			Set tAfterCNode=""
		} Else {
			; pIsNode is used as an index to the cache with fix to Prodlog 107084
			Set pStatus=$LG(tOutputVector,1)
			Set prevCNode=$LG(tOutputVector,2)	
			Set pElemIndex=$LG(tOutputVector,3)
			Set pElemName=$LG(tOutputVector,4)
			Set nFound=$LG(tOutputVector,5)
			Set pMatchedElemName=$LG(tOutputVector,6)
			Set kReturn=$LG(tOutputVector,7)
			/* tAfterCNode #8 already set */
			Set kisElementOut=$LG(tOutputVector,9)
			Set cisElementOut=$LG(tOutputVector,10)
			/* dtyp #11 already set */
			Set ctyp=$LG(tOutputVector,12)
			Set tAfterCNodeNoPlus=$LG(tOutputVector,13)
			Set tCNode=$LG(tOutputVector,14)
			Set cNode=$LG(tOutputVector,15)
			Set kDom=$LG(tOutputVector,16)
			Set iIndex=$LG(tOutputVector,17)
			Set jIndex=$LG(tOutputVector,18)
			Set tReplace=$LG(tOutputVector,19)
			Set tReplaceContent1=$LG(tOutputVector,20)
			Do ..listToNodes($LG(tOutputVector,21),.SeenCNode)
			Set tRemove=$LG(tOutputVector,22)
			Set isRightType=$LG(tOutputVector,23)
			Set tParentCNode=$LG(tOutputVector,24)
			Set tEc=$LG(tOutputVector,25)
			Set foundCNodeOfRightType=$LG(tOutputVector,26)
		}
	}
	

	While ((""'=kDom)||(""'=cNode)) {
		Set tReplace=0
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ""'=kDom && (($$$domLE(tAfterCNodeNoPlus,tCNode))&&((($e(tAfterCNode)'="+"))||($$$domLT(tAfterCNodeNoPlus,tCNode)))||(cNode="")) {
			Set pElemIndex=1
			For { 
				if '$D(Index) {
					Set kDomLast=kDom
					Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:(">"=$E(kDom)) kDom="" 
					Quit:""=kDom||(">"=$E(kDom))
					Continue:$g(dtyp)=">Z" 
					if pElem="" Continue:$g(dtyp)="/>1"
				} else {
					Set iIndexLast=iIndex,jIndexLast=jIndex,kDomLast=kDom
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						if pElem="" Continue:$g(dtyp)="/>1"
						if ($D(dtyp)&&(">"'=$E(dtyp))) {
							Set pElemName=$P(dtyp,">",1), pElemIndex=$P(dtyp,">",2)
						}
						Set kDom=$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex))
						if (iIndex="") {
							Set kDom=""
						} else {
							continue
						}
					}
					Quit:kDom=""

				}
				Set kisElementOut=(">"'=$E($g(dtyp)))
				if isTypeElement Continue:">"=$E($g(dtyp)) ; not an element node
				if 'isTypeElement,pRightType'="" {
					Set isRightType=$Case(pRightType,"text":$P($g(dtyp),">",2)="T","comment":$P($g(dtyp),">",2)="C","instruction":$P($g(dtyp),">",2)="I",:0)
					if 'isRightType,'pIsNode continue ; not a node of type we are looking for, though searching for one ,Prodlog 107084

				}
				if ($D(dtyp)&&(">"'=$E(dtyp))) {
					Set pElemName=$P(dtyp,">",1), pElemIndex=$P(dtyp,">",2)
					if pElem'="" Continue:'..equalElement(pIgnoreNamespaces,pElemName,pElem,.pNSContext)
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent1=(tReplace="c")
				} else {
					; text, comment, or processing instruction
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">I"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent1=(tReplace="c")
				}
				Quit ; this quit is important since we are processing at most one DOM node
			}
		}
		Set doit=1
		// In next conditionals set doit to 0 when appropriate which can block our moving forward with getting a next cNode
		// Reason for blocking getting next: the current cNode may not have been processed yet!
		if cNode'=-1,cNode'="",kDom="",tAfterCNode'="" {
			if '$D(SeenCNode(cNode)) {
				Set tCNode=cNode
				Set doit=0
			}
			; take a look at it
		}
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		if tCNode'=-1,tCNode'="",'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
			Set tCNode=cNode
			; take a look at it
			Set doit=0
		}
		Set saveCNode=cNode ; capture cNode's value before we advance cNode
		merge pNSContext1=pNSContext
		If ""'=cNode && (doit) && ((tAfterCNode'="")&&($$$domGE(tAfterCNodeNoPlus,tCNode))||(kDom="")) {
			For { Set prevCNode=cNode Set cNode=$S(""=pCSubs:"", 1:$$$domGetNextChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				Set cisElementOut=($$$xmlELEMENTNODE=ctyp)
				if isTypeElement Continue:$$$xmlELEMENTNODE'=ctyp ; not an element node
				if tEc||tReplaceContent Continue:$$$xmlTEXTNODE=ctyp ; skip over text nodes
				if tEc||tReplaceContent Continue:$$$xmlELEMENTNODE=ctyp ; skip over element nodes
				if 'isTypeElement,pRightType'="" {
					Set isRightType=$Case(pRightType,"text":ctyp=$$$xmlTEXTNODE,:0)
					if 'isRightType {
						if 'pIsNode continue ; not a node of type we are looking for, though searching for, 107084
					} else {
						Set foundCNodeOfRightType=1
					}
				}
				if pElem'="" Continue:'..equalElement(pIgnoreNamespaces,$$$domGetQName(..%ContentRef,cNode),pElem,.pNSContext)
				Set tCNode=cNode
				Quit  ; this quit is important since we are processing at most one Content node
			}
		}
		// Prevent SeenCNode from getting to big since we have too save and restore it from cache and this is time-consuming (grows linearly)
		if saveCNode'="" {
			Kill SeenCNode(saveCNode)
		}
		$$$ASSERT('tParentCNode||(tParentCNode=pCSubs))
		if ((""'=cNode)||(""'=kDom)) {
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				Set nFound=nFound+1
				If nFound>=pIndex,kReturn="" Set kReturn=kDom
				If ""=tAfterCNode||(kDom="") {
					Set:tCNode'="" SeenCNode(tCNode)=1
					If tIndex'="" If nFound=tIndex Set tCHit=1 Set isElementOut=cisElementOut Quit
				} Else {
					if $g(SeenCNode(tAfterCNode)) Set nFound=nFound-1
					If tIndex'="" {
						If nFound=tIndex {
							if ('tRemove) {
								Set tDHit=1 Set isElementOut=kisElementOut Quit
							} else {
								Set tCHit=1 Set isElementOut=cisElementOut Quit
							}
						}
					}
				}
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				Set:tCNode'="" SeenCNode(tCNode)=1
				If 'tRemove||pReturnRemoved {

					Set nFound=nFound+1 ; JSL 08-17-10
					If nFound>=pIndex,kReturn="" Set kReturn=kDom
					If tIndex'="",nFound=tIndex {
						Set tDHit=1  Set isElementOut=kisElementOut
						if tDHit=1,+tReplace=0,cNode'=-1 Set tCHit=1 
						Quit
					}
				}
				
			} Else { ; If tCNode<=tAfterCNode
					Set nFound=nFound+1
					If nFound>=pIndex,kReturn="" Set kReturn=kDom
					
					If ""=cNode { ;||(('Existing)&&(kDom'="")) {
						If tIndex'="" If nFound=tIndex Set tDHit=1  Set isElementOut=kisElementOut Quit
					} Else {
						Set:tCNode'="" SeenCNode(tCNode)=1
						If tIndex'="" If nFound=tIndex Set tCHit=1  Set isElementOut=cisElementOut Quit
					}
			}
		}
	}
	Set pCHit=tCHit
	Set pDHit=tDHit
	Set pNode=cNode
	if $g(prevCNode)=-1 Set prevCNode=""
	if foundCNodeOfRightType=0,pRightType'="",'isTypeElement Set prevCNode=""
	if cNode'="",cNode'=-1 do ..domGetNamespaces(pNamespaces,cNode,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext)
	if (pDHit) {
		if $e($g(dtyp))=">" {
			Set pOutputType=$CASE(dtyp,">T":"text",">C":"comment",">I":"instruction",:"unknown")
		} elseif $g(dtyp)[">" {
			Set pOutputType="element"
		} else {
			Set pOutputType="unknown"
		}
		Set pMatchedElemName=$g(pElemName)
	} elseif (pCHit) {
		if ctyp=$$$xmlELEMENTNODE {
			Set pOutputType="element"
		} elseif ctyp=$$$xmlTEXTNODE {
			Set pOutputType="text"
		} else {
			Set pOutputType="unknown"
		}
		Set:cNode'="" pMatchedElemName=$$$domGetQName(..%ContentRef,cNode)
	}
	if ('tDHit) { ; no DOM node
		if (Existing) {
			Set kFinal=pIndex
			Set tQuitValue=pIndex ; looking for existing DOM node and there was none, don't change pIndex 
		} else {
			Set kDom=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
			Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  
			if (kDom="") {
				Set tIndex=1
				Set kFinal=1
			} else {
				set tIndex=kDom+1
				Set kFinal=kDom
			}
			Set tQuitValue=tIndex
		}
	} else { ; found DOM node
		Set kFinal=kDom
		Set tQuitValue=kDom
	}
	// Set node of cache
returnFindIndex	
	Set tOutputVector=$LB(pStatus,prevCNode,pElemIndex,pElemName,nFound,pMatchedElemName,kReturn,tAfterCNode,kisElementOut,cisElementOut,dtyp,ctyp,tAfterCNodeNoPlus,tCNode,cNode,kDom,iIndex,jIndex,tReplace,tReplaceContent1,..nodesToList(.SeenCNode),tRemove,isRightType,tParentCNode,tEc,foundCNodeOfRightType,pIsNode)
	Set p0=i%%PurgeIndex
	Set pi=$s(pIndex="":$c(0),1:pIndex)
	If i%%CalcCount<i%%MaxCalcCache {
	   Set i%%CalcCache(pd,p1,pi,p3)=tOutputVector
	   Set i%%CalcCount=i%%CalcCount+1
	} Else {
	   If 'p0 {	// Allocate PPG for this document
	       Set p0=$i(^||%XML.VDoc.CalcCache),i%%PurgeIndex=p0
			Merge ^||%XML.VDoc.CalcCache(p0)=i%%CalcCache
			Kill i%%CalcCache
	   }
	   Set ^||%XML.VDoc.CalcCache(p0,pd,p1,pi,p3)=tOutputVector
	}
	quit tQuitValue
}

Method findLast(pDSubs As %String, pCSubs As %String, pElem As %String, ByRef pCHit As %Boolean, ByRef pDHit As %Boolean, ByRef pNode As %String, ByRef prevCNode As %String, Existing As %Boolean, ByRef pElemIndex As %String, ByRef pElemName As %String, isTypeElement As %Boolean, pRightType As %String, Output pOutputType, pIgnoreNamespaces As %Boolean, Output pMatchedElemName As %String, ByRef pNSContext As %String, pElementFunctionInsert As %Boolean = 0) [ Internal ]
{

	Set (tAfterCNode,tParentCNode,tCNode)=""
	Set (tDHit,tCHit,tRemove,tRemoved)=0
	Set kDom=$S("_"=pDSubs:"",1:">"), cNode=">" ; '>' collates higher than numbers
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex),-1)
	Set tReplace1=$G(@$$$vaDOMRef(pDSubs_","">R""")), tRemove1=(tReplace1>1)
	Set tReplaceContent=(tReplace1="c")
	set tEc=(tReplace1="d")

	While ((""'=kDom)||(""'=cNode)) {
		Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
		If ""'=kDom && (($$$domGE(tAfterCNodeNoPlus,tCNode))||tRemoved) {
			Set tRemoved=0
			Set pElemIndex=1
			For { 
			
				if '$D(Index) {
					Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  Quit:""=kDom  Continue:$g(dtyp)=">Z"  ;Continue:($g(dtyp)="/>1")
				} else {
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex),-1)
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						;Continue:$g(dtyp)="/>1"
						Set kDom=+$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex),-1)
						if (iIndex="") {
							Set kDom=""
						} else {
							continue
						}
					}
					Quit:kDom=""
			
				}

				$$$ASSERT($D(dtyp))
				if isTypeElement Continue:">"=$E(dtyp) ; not an element node
				if 'isTypeElement,pRightType'="" {
					Set isRightType=$Case(pRightType,"text":$P(dtyp,">",2)="T","comment":$P(dtyp,">",2)="C","instruction":$P(dtyp,">",2)="I",:0)
					if 'isRightType continue ; not a node of type we are looking for, though searching for one

				}
				if (isTypeElement) {
					Set pElemName=$P(dtyp,">",1), pElemIndex=$P(dtyp,">",2)
					if pElem'="" if '..equalElement(pIgnoreNamespaces,pElemName,pElem,.pNSContext) continue
					if pElementFunctionInsert continue
					Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">I"""),"+")
					Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent1=(tReplace="c")
				} else {
					If ">"'=$E(dtyp),dtyp'="" { ; it's an element node
						Set pElemName=$P(dtyp,">",1), pElemIndex=$P(dtyp,">",2)
						Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">I"""))
						Set tParentCNode=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">P"""))
						Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_pElemName_""","_pElemIndex_","">R""")), tRemove=(tReplace>1)
						Set tReplaceContent1=(tReplace="c")
					} Else {
						; text, comment, or processing instruction
						Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">I"""))
						Set tReplace=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
						Set tReplaceContent1=(tReplace="c")
					}
				}
				Quit
			}
		}
		If ""'=cNode && (($$$domLE(tAfterCNode,tCNode))||(tCNode="")) {
			Set pNamespaces=##class(NamespaceHelper).%New()
			For { Set prevCNode=cNode Set cNode=$S(""=pCSubs:"", 1:$$$domGetPreviousChild(..%ContentRef,pCSubs,cNode))  Quit:""=cNode
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				if isTypeElement Continue:$$$xmlELEMENTNODE'=ctyp ; not an element node
				if tEc||tReplaceContent Continue:$$$xmlTEXTNODE=ctyp ; skip over text nodes
				if tEc||tReplaceContent Continue:$$$xmlELEMENTNODE=ctyp ; skip over element nodes
				do ..domGetNamespaces(pNamespaces,cNode,$S("_"=pDSubs:"_",1:pDSubs_","">@"""),.pNSContext)
				if pElem'="" continue:'..equalElement(pIgnoreNamespaces,$$$domGetQName(..%ContentRef,cNode),pElem,.pNSContext)
				if pElementFunctionInsert continue
				Set tCNode=cNode
				Quit
			}
		}
		$$$ASSERT('tParentCNode||(tParentCNode=pCSubs))
		if ((""'=cNode)||(""'=kDom)) {
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				Set tCHit=1
				Quit
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				If 'tRemove {
					Set tDHit=1
					if +$g(tReplace)=0,tAfterCNode'="" Set tCHit=1
					Quit
				} else {
					Set tRemoved=1
					continue
				}
			} Else { ; tCNode<=tAfterCNode
				if (kDom'="") {
					Set tDHit=1
				} else {
					Set tCHit=1
				}
				Quit
			}
		}
	}
	Set pCHit=tCHit
	Set pDHit=tDHit
	if (tCHit) {
		Set pNode=cNode
	} else {
		Set cNode=""
		Set pNode=$S(""=pCSubs:"", 1:$$$domGetPreviousChild(..%ContentRef,pCSubs,cNode))
		Set:cNode'="" ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
	}
	if (pDHit) {
		if $e(dtyp)=">" {
			Set pOutputType=$CASE(dtyp,">T":"text",">C":"comment",">I":"instruction",:"unknown")
		} elseif dtyp[">" {
			Set pOutputType="element"
		} else {
			Set pOutputType="unknown"
		}
		Set pMatchedElemName=$g(pElemName)
	} elseif (pCHit) {
		if ctyp=$$$xmlELEMENTNODE {
			Set pOutputType="element"
		} elseif ctyp=$$$xmlTEXTNODE {
			Set pOutputType="text"
		} else {
			Set pOutputType="unknown"
		}
		Set pMatchedElemName=$$$domGetQName(..%ContentRef,cNode)
	}
	if ('tDHit) { ; no DOM node
		if (Existing) {
			Set tQuitValue=..domGetNodeCounts(pDSubs,pCSubs,"",.pNSContext)  ; looking for existing DOM node and there was none, return count
		} else {
			Set kDom=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
			Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),-1,dtyp)  
			if (kDom="") {
				Set tIndex=1
			} else {
				Set tIndex=kDom+1
			}
			Set tQuitValue=tIndex
		}
	} else { ; found DOM node
		Set tQuitValue=kDom
		
	}
	// set cache node
	
	Quit tQuitValue
}

Method createNonExistent(pDSubs As %String, pCSubs As %String, pElem As %String, pIndex As %Integer, pIsNode As %Boolean, ByRef pDom As %Integer, pNonExistent As %Boolean, pCHit As %Boolean, byName As %Boolean, Output pElemIndex As %Integer, pIgnoreNamespaces As %Boolean, ByRef pNSContext As %String, isTypeElement As %Boolean) [ Internal ]
{
	; operating this with a CalcCache that survive regression errors *caused* regression failures
	;$$$vaKillCalcCache JSL4382
	Set tSkipFind=..%SkipFind
	Set tElem=pElem
	Set pNamespaces=##class(NamespaceHelper).%New()
	if ('byName) {
		if (pIndex="")||(pIndex="-") Set pIndex=..domGetElemCounts(pDSubs,pCSubs,,pIgnoreNamespaces,.pNSContext)
		Set tElem=""
	} else {
		if (pIndex="")||(pIndex="-") Set pIndex=..domGetElemCounts(pDSubs,pCSubs,pElem,pIgnoreNamespaces,.pNSContext)
		
	}
	; find first existent
	Set tFirstIndex=pIndex
	do {
		Set tFirstIndex=tFirstIndex-1
		; seeking first
		if 'tSkipFind $$$vaKillCalcCache ; JSL4382 JSL4384 part B
		Set kDom=..findIndex(pDSubs, pCSubs, tElem, tFirstIndex, pIsNode, .tSC, .tCHit, .tDHit,.cNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,pIgnoreNamespaces,.tMatchedElementName,pNamespaces,.pNSContext)		
	} while (('tCHit)&&('tDHit))&&(tFirstIndex>0) 
	; from first existent to pIndex create elements
	for i=tFirstIndex+1:1:pIndex {
		if '..%SkipFind $$$vaKillCalcCache ; JSL4382 JSL4384 part B did not fix regression
		Set kDom=..findIndex(pDSubs, pCSubs, tElem, i, pIsNode, .tSC, .tCHit, .tDHit,.cNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,pIgnoreNamespaces,.tMatchedElementName,pNamespaces,.pNSContext)
		Set pElemIndex=$g(tElemIndex)
		Set pDom=kDom
		Set pNode=cNode
		Set tInsertDSubs=pDSubs
		Set tElemName=pElem
		; new calculation for tOrdinal 10-29-10
		if ('byName) {
			Set tOrdinal=kDom
		} else {
			Set tOrdinal=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
			Set tOrdinal=$O(@$$$vaDOMRef(pDSubs_","">"_pElem_""""_","""_tOrdinal_""""),-1,dtyp)  
			Set tOrdinal=tOrdinal+1
		}
		if ('tCHit){
			Set tAfterCNode="+"_prevCNode
		} else {
			Set tAfterCNode=cNode
		}
		Set ISubscript=..calcISubscript(pDSubs,pElem_">"_tOrdinal)
		Set @$$$vaDOMRef(tInsertDSubs_","_kDom)=tElemName_">"_tOrdinal
		if $D(tAfterCNode) Set:$D(ISubscript) @$$$vaDOMRef(ISubscript_","">I""")=tAfterCNode
		if 'tSkipFind || (pCSubs'="") {
			$$$vaKillCalcCache2(pDSubs,pCSubs)			
		}

		Set pDom=..findIndex(pDSubs, pCSubs, tElem, i, pIsNode, .tSC, .tCHit, .tDHit,.cNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.isElement,.tOutputType,,pIgnoreNamespaces,.tMatchedElementName,pNamespaces,.pNSContext)
		$$$ASSERT((pCSubs="") || (pCSubs=0) || (pIndex=0)||tDHit) ; 03-02-2012, add pCSubs="" || pCSubs=0 to ASSERT list
		Set pElemIndex=$g(tElemIndex)
		if tSkipFind { // JSL4383
		} else {
			$$$vaKillCalcCache2(pDSubs,pCSubs)
		}
	}
}

Method createNonExistentNode(pDSubs As %String, pCSubs As %String, pIndex As %Integer, pIsNode As %Boolean, pRightType As %String, pIgnoreNamespaces As %Boolean, ByRef pNSContext As %String) [ Internal ]
{
	$$$vaKillCalcCache1(pDSubs) ; JSL4384 part B
	Set pNamespaces=##class(NamespaceHelper).%New()
	Set isTypeElement=0
	; find first existent
	Set tFirstIndex=(pIndex-1)
	do {
		Set tFirstIndex=tFirstIndex-1
		$$$vaKillCalcCache1(pDSubs) ; JSL4384 partB
		Set textOrdinal=..findIndex(pDSubs, pCSubs, "", tFirstIndex,  pIsNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,pRightType,.nFound,.duumy,.tOutputType,,pIgnoreNamespaces,.tMatchedElementName,pNamespaces,.pNSContext)
		;$$$vaKillCalcCache
	} while (('tCHit)&&('tDHit))&&(tFirstIndex>0) 
	; from first existent to pIndex create elements
	Set textSub=pDSubs
	for i=tFirstIndex+1:1:(pIndex-1) {
		$$$vaKillCalcCache
		Set textOrdinal=..findIndex(pDSubs, pCSubs, "", i,  pIsNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,pRightType,.nFound,.duumy,.tOutputType,,pIgnoreNamespaces,.tMatchedElementName,pNamespaces,.pNSContext)
		$$$vaKillCalcCache1(pDSubs) ; JSL4384 part B
		if textOrdinal="" Set tOrdinal=1
		Set textAfterCNode=prevCNode
		Set @$$$vaDOMRef(textSub_","_textOrdinal)=$Case(pRightType,"text":">T","comment":">C","instruction":">I",:">U")
		Set @$$$vaDOMRef(textSub_","_textOrdinal_","">V""")=""
		Set @$$$vaDOMRef(textSub_","_textOrdinal_","">I""")="+"_$g(textAfterCNode)
	}
	;if '..%SkipFind $$$vaKillCalcCache1(pDSubs) ; JSL4384
	$$$vaKillCalcCache1(pDSubs) ; JSL4384 part B does not fix regression
}

// following method may be headed for obsolesence

Method domElementSort(pDSubs As %String, pElem As %String) [ Internal ]
{
	quit ; no longer used
}

// following method may be headed for obsolescence

Method domNonElementSort(pDSubs As %String, pOrdinal As %String) [ Internal ]
{
	quit ; no longer used
}

/// Remove node by sliding down by one the given node in the given DOM element and all higher nodes in that element
Method domRemoveElementNodes(pDSubs As %String, pNodeIndex As %String, pElem As %String) [ Internal ]
{
	;w !,"In domRemoveElementNodes begin pNodeIndex="_pNodeIndex_" pElem="_pElem

	; shift ordinals

	Set kDom=pNodeIndex
	Set lastKDom=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
	Set lastKDom=$O(@$$$vaDOMRef(pDSubs_","""_lastKDom_""""),-1)
	For { 
		if (kDom+1)<=lastKDom {
			Set dtyp=$g(@$$$vaDOMRef(pDSubs_","""_(kDom+1)_""""))
			if dtyp'="",$e(dtyp)'=">",$P(dtyp,">",1)=$P(pElem,">",1) {
				// element, decrease by one since deleting element
				Set $P(dtyp,">",2)=$P(dtyp,">",2)-1
				Set @$$$vaDOMRef(pDSubs_","""_(kDom+1)_"""")=dtyp
			}
		}
		; 04-27-11
		Set dtyp1=@$$$vaDOMRef(pDSubs_","""_(kDom)_"""")
		;if dtyp'="",$e(dtyp1)'=">",$P(dtyp1,">",1)=$P(pElem,">",1) Set @$$$vaDOMRef(pDSubs_","""_(kDom)_"""")=olddtyp
		if dtyp1'="",$e(dtyp1)'=">",$P(dtyp1,">",1)=$P(pElem,">",1) {
			// 05-04-11
			Set tElemName=$P(dtyp1,">",1), tElemIndex=$P(dtyp1,">",2)
			Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
			if 'tRemove {
				;Set kDomPrev=kDom
			}
			Set kDomPrev=kDom
		}
		Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom=""  Quit:""=kDom
	}
	; 04-28-11
	Kill @$$$vaDOMRef(pDSubs_","""_(pNodeIndex)_"""")
	; shift elements
	; 04-27-11
	Set tNodeIndex=pNodeIndex
	Set tNodeIndex=$P(pElem,">",2)
	Set tNodeName=$P(pElem,">",1)
	Set subscript=pDSubs_","">"_tNodeName_""","""_tNodeIndex_""""
	For { 
		// 05-04-11
		Set replaceCount=0

		kill @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+replaceCount)_"""")
		if $D(@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1+replaceCount)_"""")) merge @$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+replaceCount)_"""")=@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+1)_"""")
		Set tNodeIndex=$O(@$$$vaDOMRef(pDSubs_","">"_tNodeName_""","""_(tNodeIndex+replaceCount)_""""),1) Quit:""=tNodeIndex
	}
	; reindex elements/ordinals
	#define SaveRef(%S,%subs) $S(")"=$E(%S,*):$E(%S,1,*-1)_(%subs)_")", ""=(%subs):%S, 1:%S_"("_$E(%subs,2,*)_")")
	Set DomSaveName="%DomSave"
	kill @DomSaveName

	Set kDom=""
	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom=""  Quit:""=kDom
		merge @$$$SaveRef(DomSaveName,pDSubs_","""_kDom_"""")=@$$$vaDOMRef(pDSubs_","""_kDom_"""")
	}	
	Set kDom="" Set index=1
	For { Set kDom=$O(@$$$SaveRef(DomSaveName,pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom=""  Quit:""=kDom
		kill @$$$vaDOMRef(pDSubs_","""_kDom_"""")
		merge @$$$vaDOMRef(pDSubs_","""_index_"""")=@$$$SaveRef(DomSaveName,pDSubs_","""_kDom_"""")
		Set index=index+1
	}
	kill @DomSaveName
	if '..%SkipFind $$$vaKillCalcCache1(pDSubs) ; JSL4384 killing cache unconditionally did NOT fix infinite loop in regression 8:03 PM
	$$$vaKillCalcCache1(pDSubs) ; JSL4384 part B, FIXES first four errors in regression
}

// we remove a node whether it is content, a DOM annotation of content, or a DOM node

// that has been inserted into Content Array

Method domElementRemove(pInsertDSubs As %String, pFinalSubscript As %String, pDSubs As %String, pCHit As %Boolean, pDHit As %Boolean) [ Internal ]
{
	;w !,"domElementRemove pDSubs="_pDSubs_" pCHit="_pCHit_" pDHit="_pDHit
	; Note can have both a PCHit and a PDHit with an annotation DOM node
	$$$vaKillCalcCache1(pDSubs) ; JSL4382
	$$$vaKillCalcCache1(pInsertDSubs) ; JSL4382
	if pCHit {
		Set @$$$vaDOMRef(pDSubs_","">V""")=""
		;Set @$$$vaDOMRef(pDSubs)=">T"
		Set @$$$vaDOMRef(pDSubs_","">R""")=2
	} 
	if pDHit,'pCHit {
		Set dtyp=$g(@$$$vaDOMRef(pInsertDSubs_","_pFinalSubscript))
		do ..domRemoveElementNodes(pInsertDSubs,pFinalSubscript,dtyp)
	} elseif pDHit,pCHit {

		Set tDSubsParent=$P(pDSubs,",",1,$L(pDSubs,",")-2)
		Set tElemName=$E($TR($P(pDSubs,",",$L(pDSubs,",")-1),"""",""),2,*)
		;if tElemName="" quit
		Set tElemIndex=$P(pDSubs,",",$L(pDSubs,","))
		Set tAfterCNode=$g(@$$$vaDOMRef(pDSubs_","">I"""))
		if $e(tAfterCNode)="+" {
			do ..domRemoveElementNodes(tDSubsParent,tElemIndex,tElemName_">"_tElemIndex)
		} else {
			; walk Node we are removing and kill content and element nodes and attributes
			Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom="" Quit:""=kDom||(">"=$E(kDom)) 
				kill @$$$vaDOMRef(pDSubs_","""_kDom_"""")
			}
			Kill @$$$vaDOMRef(pDSubs_","">@""")
			
			; Set node as being removed
			;Set @$$$vaDOMRef(pDSubs_","">R""")=2
		}
	}
	$$$vaKillCalcCache1(pDSubs) ; JSL4384
}

/// Remove node by sliding down by one the given node in the given DOM element and all higher nodes in that element
Method domRemoveNonElementNodes(pDSubs As %String, pNodeIndex As %String) [ Internal ]
{

	; shift ordinals

	; shift elements
	$$$vaKillCalcCache1(pDSubs) ; JSL4382
	Set tNodeIndex=pNodeIndex
	Set subscript=pDSubs_","""_tNodeIndex_""""
	For { 
		kill @$$$vaDOMRef(pDSubs_","""_tNodeIndex_"""")
		if $D(@$$$vaDOMRef(pDSubs_","""_(tNodeIndex+1)_"""")) merge @$$$vaDOMRef(pDSubs_","""_tNodeIndex_"""")=@$$$vaDOMRef(pDSubs_","""_(tNodeIndex+1)_"""")
		Set tNodeIndex=$O(@$$$vaDOMRef(pDSubs_","""_tNodeIndex_""""),1) Set:$e(tNodeIndex)=">" tNodeIndex="" Quit:""=tNodeIndex
	}
	$$$vaKillCalcCache1(pDSubs) ; JSL4384
}

/// we remove a node whether it is textual content, a DOM annotation of textual content, or a DOM node
/// that has been inserted into the array of values beneath a DOM node
Method domNodeRemove(pDSubs As %String, pCHit As %Boolean, pDHit As %Boolean, pCSubs) [ Internal ]
{
	;w !,"in domNodeRemove pDSubs="_pDSubs_" pCHit="_pCHit_" pDHit="_pDHit_" pCSubs="_pCSubs_" >I="_$g(@$$$vaDOMRef(pDSubs_","">I"""))

	$$$vaKillCalcCache1(pDSubs) ; JSL4382
	; Note can have both a PCHit and a PDHit with an annotation DOM node
	if pCHit {
		Set @$$$vaDOMRef(pDSubs_","">R""")=2
	} 
	if pDHit {
		Set tDSubsParent=$P(pDSubs,",",1,$L(pDSubs,",")-1)
		Set tElemIndex=$P(pDSubs,",",$L(pDSubs,","))
		Set tAfterCNode=$G(@$$$vaDOMRef(pDSubs_","">I"""))
		Set doit=1
		if $e(tAfterCNode)="+" {
			do ..domRemoveNonElementNodes(tDSubsParent,tElemIndex)
			Set doit=0
		}
		if $e(tAfterCNode)="+"||(tAfterCNode="") {
			if pCSubs'="",$e(pCSubs)'="+" {
				; replacing an element that overwrote a member of Content Aray
				Set @$$$vaDOMRef(pDSubs_","">I""")=pCSubs
				Set @$$$vaDOMRef(pDSubs_","">R""")=2
			}
		}
		if 'doit {
			; Set node as being remove
			Set @$$$vaDOMRef(pDSubs_","">R""")=2
		}
		
	}
	$$$vaKillCalcCache1(pDSubs) ; JSL4383
}

Method domRemoveAttributeNode(pDSubs As %String, pAttrName As %String, pDom As %String) [ Internal ]
{
	kill @$$$vaDOMRef(pDSubs_","">"_pAttrName_"""")
	;kill @$$$vaDOMRef(pDSubs_","_pDom)
	Set kDom=pDom For { Set prevDom=kDom 	
		if $D(@$$$vaDOMRef(pDSubs_","_(kDom+1))) Set @$$$vaDOMRef(pDSubs_","_kDom)=@$$$vaDOMRef(pDSubs_","_(kDom+1))
		Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,tAttrName)  Quit:""=kDom||(">"=$E(kDom))
	}
	kill @$$$vaDOMRef(pDSubs_","_prevDom)
}

Method domRemoveAttribute(pContentSubs, pDSubs As %String, pAttrName As %String, pCHit As %Boolean, pDHit As %Boolean) [ Internal ]
{
	Set (tCHit,tDHit)=0
	if pCHit {
		; search for attribute in Content Array
		// 01-31-12a
		Set cNode="" for { Set cNode=$$$xmlNextAttributeName(..%ContentRef,pContentSubs,cNode) quit:cNode=""
			if (cNode=pAttrName) {
				Set tCHit=1
				quit
			}
		}
	}
	if pDHit {
		; search for attribute in DOM array
		Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,tAttrName)  Quit:""=kDom||(">"=$E(kDom))
			if tAttrName=pAttrName {
				Set tDHit=1
				quit
			}
		}
		if tDHit,'tCHit {
			Do ..domRemoveAttributeNode(pDSubs, pAttrName, kDom)
		}
	}
	if tCHit {
		Set @$$$vaDOMRef(pDSubs_","">"_pAttrName_""","">R""")=2
	}
}

Method lookupAttributeNumber(pDSubs As %String, pAttrName As %String) [ Internal ]
{
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,tAttrName)  Quit:""=kDom||(">"=$E(kDom))
		if tAttrName=pAttrName quit
	}
	quit kDom
}

Method createIndex(pDSubs As %String, ByRef Index) [ Internal ]
{
	if pDSubs=""||(pDSubs="_") quit
	Set kDom="" 
	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom="" Quit:""=kDom
		;Set dtyp=@$$$vaDOMRef(pDSubs_","""_kDom_"""")
		if $D(dtyp) {
			if $e(dtyp)'=">" {
				Set tElemName=$P(dtyp,">",1)
				Set tElemOrdinal=$P(dtyp,">",2)
				// element, increase by one since inserting element
				Set WholeSubscript=$g(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemOrdinal_","">I"""),"+")
				// TBD - the following code depends on internal structure of what should be an opaque node
				// We limit dependence to a macro domGetOffset
				Set ISubscript=$$$domGetOffset(WholeSubscript)
				if ISubscript="" Set ISubscript=0
				; "+8" will be after 8 but before 9
				if $e(WholeSubscript)="+" Set ISubscript=ISubscript+.5
				;if WholeSubscript="+" Set ISubscript=0 ; JSL4382
				Set:ISubscript'="" Count(ISubscript)=$i(Count(ISubscript))
				Set:ISubscript'="" Index(ISubscript,Count(ISubscript))=$LB(dtyp,kDom)
			} else {
				Set WholeSubscript=$G(@$$$vaDOMRef(pDSubs_","""_kDom_""","">I"""),"+")
				Set ISubscript=$$$domGetOffset(WholeSubscript)
				if ISubscript="" Set ISubscript=0
				; "+8" will be after 8 but before 9
				if $e(WholeSubscript)="+" Set ISubscript=ISubscript+.5
				Set:ISubscript'="" Count(ISubscript)=$i(Count(ISubscript))
				Set:ISubscript'="" Index(ISubscript,Count(ISubscript))=$LB(dtyp,kDom)
			
			}
		}
	}
}

Method createAttrOrNamespaceIndex(pDOMSubs As %String, pFormat As %String, ByRef Index, ByRef pDomOrderedIndex) [ Internal ]
{
	if pDOMSubs=""||(pDOMSubs="_") quit
	#dim kDom=""
	#dim tDVal, tDAttr, dtyp
	#; Using kDomISubscript for order by Dom since might not be alphabetical
	#dim ISubscript, kDomISubscript As %String
	#Dim Count, kDomCount As %Integer
	#define LeadingZeros "00000000000000000000"
	For { Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom)&&(pFormat'["a") kDom="" Quit:kDom=""

			If pFormat["a" {
				Set tDAttr=$E(kDom,2,*), tDVal=dtyp
			} Else {
				Set tDAttr=$P(dtyp,">",1), tDVal=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""""))
			}
			Set ISubscript=$G(@$$$vaDOMRef(pDOMSubs_","">"_tDAttr_""","">I"""))
			If ISubscript="" {
				Set ISubscript=$c(0)
				Set kDomISubscript = ISubscript
			} ElseIf ($E(ISubscript) '="+") &&(kDom = +kDom) && ($E(ISubscript)'=+$E(ISubscript)) {
				#; Make sure we keep same order as DOMCache even if more than 9 attributes
				Set kDomISubscript = $Extract($$$LeadingZeros,1,(20-$L(kDom)))_kDom_" "_ISubscript
			} Else {
				Set kDomISubscript = ISubscript
			}
			Set Count(ISubscript)=$i(Count(ISubscript))
			Set Index(ISubscript,Count(ISubscript))=$LB($g(dtyp),kDom)
			Set kDomCount(kDomISubscript)=$i(kDomCount(kDomISubscript))
			Set pDomOrderedIndex(kDomISubscript,kDomCount(kDomISubscript))=Index(ISubscript,Count(ISubscript))
	}
}

Method equalElement(pIgnoreNamespaces As %Boolean = 0, pElem1 As %String, pElem2 As %String, ByRef pNSContext As %String) [ Internal ]
{
	quit ..ConditionallyGetElementOrLocal(pIgnoreNamespaces, pElem1,.pNSContext)=..ConditionallyGetElementOrLocal(pIgnoreNamespaces, pElem2,.pNSContext)
}

Method ConditionallyGetElementOrLocal(pIgnoreNamespaces As %Boolean, pElem As %String, ByRef pNSContext As %String) As %String [ Internal ]
{
	//ConditionallyRemoveNSPrefix(%ignore,%elemname,%pnscontext) $s(%ignore=1:$s(%elemname[":":$P(%elemname,":",2),1:%elemname),1:$s(%elemname[":":$g(%pnscontext($P(%elemname,1))),1:$g(%pnscontext("xmlns"))))
	quit:pIgnoreNamespaces=1 $S(pElem[":":$P(pElem,":",2), 1:pElem)

	if pElem[":" {
		Set prefix=$P(pElem,":",1)
		if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) { // prefix from Prop path, so maps to namespace URI
			Set uri=$g($$$vaSchemaGbl(..DocTypeCategory,"ns","list",$e(prefix,2,*),"uri"))
		} elseif $e(prefix,1,$L("xsd_"))="xsd_",$e(prefix,$L("xsd_")+1,*)=+$e(prefix,$L("xsd_")+1,*) { // prefix from Prop path, so maps to namespace URI
			Set index=$e(prefix,$L("xsd_")+1,*)
			if ..DocTypeCategory'="",index'="" { // JSL4284
				Set uri=$g(pNSContext(pNSContext("level"),"namespaces","xmlns:"_prefix))
				if (uri="") {
					Set uri=$g($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index,"uri"))
				}
			} else {
				Set uri=$g(pNSContext(pNSContext("level"),"namespaces","xmlns:"_prefix))
			}
		} else {
			Set uri=$g(pNSContext(pNSContext("level"),"namespaces","xmlns:"_prefix))
		}
		quit uri_"~"_$P(pElem,":",2)
	} else {
		Set uri=$g(pNSContext(pNSContext("level"),"namespaces","xmlns"),pElem)
		Set elem=$P(pElem,":",1)
		quit uri_"~"_elem
	}
}

Method ConditionallyRemoveNSPrefix(pIgnoreNamespaces As %Boolean, pElem As %String, ByRef pNSContext As %String, Output pStatus As %Status) As %String [ Internal ]
{
	//ConditionallyRemoveNSPrefix(%ignore,%elemname,%pnscontext) $s(%ignore=1:$s(%elemname[":":$P(%elemname,":",2),1:%elemname),1:$s(%elemname[":":$g(%pnscontext($P(%elemname,1))),1:$g(%pnscontext("xmlns"))))
	Set pStatus=$$$OK
	quit:pIgnoreNamespaces=1 $S(pElem[":":$P(pElem,":",2), 1:pElem)

	quit:'$find(pElem,":") pElem
	Set prefix=$P(pElem,":",1)
	if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
		if ..DocTypeCategory="" {
			Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't use namespace prefix that starts with $ unless DocTypeCategory is non-null "_pElem)
			quit ""
		}
	}
	If ..DocTypeCategory="" {
		quit pElem ; no DocTypeCategory so need need to transform prefix from $n or xsd_n to perfix found in namespaces
	}
	;w:1 !,"pElem="_pElem
	;quit:$e(prefix)'="$" pElem
	; In the schema default prefixes live as $n prefixes, in the DOM they live as xsd_n prefixes.
	; For such prefixes we want to map them if possible to prefixes actually in the namespace
	; this requires look up of URI from schema global and see if it maches uri in the namespaces and then code prefers uri in namespaces
	; this is made more complex by the fact that DOM and schema have different representations of default prefixes
	if ($e(prefix,1,$L("xsd_"))'="xsd_")||($e(prefix,$L("xsd_")+1,*)'=+$e(prefix,$L("xsd_")+1,*)),($e(prefix)'="$"||($e(prefix,2,*)'=+$e(prefix,2,*))) {
		quit pElem
	}
	Set schemaPrefix=prefix
	if $e(prefix,1,$L("xsd_"))="xsd_" {
		Set schemaPrefix="$"_$e(schemaPrefix,$L("xsd_")+1,*)
	}
	Set localname=$P(pElem,":",2)
	Set returnPrefix=""
	Set level=pNSContext("level")+1
	Set uri=""
	if $e(prefix,1,$L("xsd_"))="xsd_" { // JSL4284
		Set uri=$g(pNSContext(level,"namespaces","xmlns:"_prefix))
	}
	Set:(..DocTypeCategory'="")&&(uri="") uri=$g($$$vaSchemaGbl(..DocTypeCategory,"ns","list",$e(schemaPrefix,2,*),"uri"))	// guard with uri="" JSL4284
	set i="" for { set i=$o(pNSContext(level,"namespaces",i),1,urivalue) q:i=""  
		if i[":" {
			Set iscprefix=$P(i,":",2)
			if $e(iscprefix,1,$L("xsd_"))="xsd_" {
				Set index=$e(iscprefix,$L("xsd_")+1,*)
				if ..DocTypeCategory'="",index'="" {
					if $g($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index,"uri"))'="" continue
				}
			}
		}
		q:uri=$g(urivalue)
	}
	if (i'="") {
		if $D(urivalue),uri=urivalue {
			set returnPrefix=$P(i,":",2)
			if (returnPrefix'="") {
				if $e(returnPrefix)="$",$e(returnPrefix,2,*)=+$e(returnPrefix,2,*) {
					Set returnPrefix="xsd_"_$e(returnPrefix,2,*)
				}
				quit returnPrefix_":"_localname
			} else {
				quit localname
			}
		}
	}
	set i="" for { set i=$o(pNSContext(level,"namespaces",i),1,urivalue)  q:i=""  q:uri=$g(urivalue) }
	if $D(urivalue),uri=urivalue {
		set returnPrefix=$P(i,":",2)
		if $e(returnPrefix)="$",$e(returnPrefix,2,*)=+$e(returnPrefix,2,*) {
			Set returnPrefix="xsd_"_$e(returnPrefix,2,*)
		}
		
		if (returnPrefix'="") {
			quit returnPrefix_":"_localname
		} else {
			quit localname
		}
	} else {
		//Set pStatus=$$$ERROR($$$EnsErrGeneral,"Unable to find matching namespace for element "_pElem)
		quit pElem ; couldn't find a later uri that allows us to change prefix to non-canonical prefix just return element itself
	}
}

// Sax Content Handler

Property DOMCacheSave [ Internal, MultiDimensional, Transient ];

Property DOMSaveName As %String(MAXLEN = "") [ Internal, Transient ];

Property pDSubs As %String(MAXLEN = "") [ Internal, Transient ];

Property pOrdinal As %String(MAXLEN = "") [ Internal, Transient ];

Property pAfterCNode As %String(MAXLEN = "") [ Internal, Transient ];

Property currentElement As %String(MAXLEN = "") [ Internal, Transient ];

Property prevElem [ MultiDimensional ];

Property pDSubsList [ MultiDimensional ];

Property attributeCount [ MultiDimensional ];

Property attributeSub [ MultiDimensional ];

Property namespaceMapping [ MultiDimensional ];

Property Level As %Integer [ InitialExpression = 0, Internal, Transient ];

/// skip domSlideElementNodes since done by domParsePath
Property skipSlide As %Boolean [ InitialExpression = 1, Internal, Transient ];

/// replace nodes since in append
Property replace As %Boolean [ InitialExpression = 0, Internal, Transient ];

Property buildRoot As %Boolean [ InitialExpression = 0, Internal, Transient ];

Property %ContentHandlerStatus As %Status [ Internal, Transient ];

Method ReadString(pValue As %String, pReplace As %Boolean = 0, pBuildRoot As %Boolean = 0) As %Status [ Internal ]
{
	$$$vaKillCalcCache
	;$$$DEBUGPARSER("ReadString pValue="_pValue)
	Set ..%ContentHandlerStatus=$$$OK
	Set tSC=##class(%XML.SAX.Parser).ParseString(pValue,$this,,,$$$SAXFATALERROR) ; mask to only get errors
	Set:$$$ISERR(..%ContentHandlerStatus) tSC=$$$ADDSC(tSC,..%ContentHandlerStatus)
	Quit:$$$ISERR(tSC) tSC
	Set ..%ContentHandlerStatus=$$$OK

	Set ..replace=pReplace
	Set ..buildRoot=pBuildRoot
	Set tSC=##class(%XML.SAX.Parser).ParseString(pValue,$this)
	Set:$$$ISERR(..%ContentHandlerStatus) tSC=$$$ADDSC(tSC,..%ContentHandlerStatus)
	;$$$vaKillCalcCache ; part B of JSL4384 - fix regression DID not fix
	Quit tSC
}

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List) [ Internal ]
{
	#define SaveRef2(%S,%subs) $S(")"=$E(%S,*):$E(%S,1,*-1)_(%subs)_")", ""=(%subs):%S, 1:%S_"("_$E(%subs,2,*)_")")

	try {
		$$$DEBUGPARSER("starting element "_localname)
		Set ..currentElement=qname_"~"_..Level
		if (..Level=0) { ; processing pseudo element, save pDSubs
			//+ 104628
			kill ..prevElem
			kill ..pDSubsList
			kill ..attributeCount
			kill ..attributeSub
			kill ..namespaceMapping
			//- 104628
			Set ..pDSubsList(0) = ..pDSubs
			$$$DEBUGPARSER("in Level 0 ..pDSubs="_..pDSubs)
			//+ 104628			
			Set ..prevElem(0)=$e($P(..pDSubs,",",$L(..pDSubs,",")-2),3,*-1)_"~"_..Level
			//Set ..prevElem(0)=$e($P(..pDSubs,",",$L(..pDSubs,",")-2),3,*-1)
			//- 104628
			Set ..currentElement=..prevElem(0)
			$$$DEBUGPARSER("in Level 0 prevElem(0)="_..prevElem(0))
			Set ..skipSlide=1
			Set ..DOMSaveName="..DOMCacheSave"
			;kill @..DOMSaveName
			;merge @$$$SaveRef(..DOMSaveName,..pDSubs)=@$$$vaDOMRef(..pDSubs)

		}
		if (..Level=1 && (..buildRoot=1)) {
			// build root
			Set ..pOrdinal=1
			Set @$$$vaDOMRef(","_1)="/>1"
			Set @$$$vaDOMRef(","">/"",1,1")=qname_">1"
			Set ..pDSubsList(0)=","">/"",1,1"
			Set ..pDSubs=..pDSubsList(0)
			Set ..prevElem(0)=$e($P(..pDSubs,",",$L(..pDSubs,",")-2),3,*-1)_"~"_(..Level-1)
			Set ..currentElement=..prevElem(0)
			Set ..buildRoot=0
		}
		if (..Level '=0) { ; Level 0 is where "pseudo-root" is kept, where mixed content is wrapped
			$$$DEBUGPARSER("Enter level'=0"_" ..Level="_..Level)
			$$$DEBUGPARSER("prevElem("_(..Level-1)_")="_$g(..prevElem(..Level-1)))
			$$$DEBUGPARSER("prevElem("_(..Level)_")="_$g(..prevElem(..Level)))
			$$$DEBUGPARSER("..pDSubsList("_(..Level-1)_")="_..pDSubsList(..Level-1))
			; 05-20-11
			Set pDSubs=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)
			Set kDom=$P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))
			$$$DEBUGPARSER("!!!!!!!!!!!!!!!!!!!!!!!!pDSubs="_pDSubs_" kDom="_kDom)
			//+ Prodlog 104484
			// are there elements to right of this element?
			$$$DEBUGPARSER("CountToRight pDSubs="_pDSubs_" kDom="_kDom)

			Set CountToRight=0
			//Set kDom1=kDom For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) Set:$e(kDom1)=">" kDom1="" quit:kDom1=""
			Set kDom1=kDom For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) quit:kDom1=""

				if $D(dtyp) {
					If $i(CountToRight)
				}
			}

			if '..replace,..Level=1,'..skipSlide,CountToRight>0 {
				//Do ..domSlideElementNodes(pDSubs,kDom2,tElem_">"_kDom2)
				//Do ..domSlideElementNodes(pDSubs,..domElemNode(pDSubs,qname_">"_kDom,.tSC),qname_">"_kDom,1) // we slide nodes right if we need to because more than one element being inserted
				Do ..domSlideNodes(pDSubs,kDom,.tHighestIndex) // we slide nodes right if we need to because more than one element being inserted
			}

			Set ..skipSlide=0
			//- Prodlog 104484
			$$$DEBUGPARSER("pDSubs="_pDSubs_" kDom="_kDom)
			kill Count
			Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) Set:$e(kDom1)=">" kDom1="" quit:kDom1=""  quit:kDom1=kDom
				if $D(dtyp) If $P(dtyp,">",1)=qname Set tElemCount=$i(Count(qname))
				if kDom1=kDom quit
			}
			//Set ..ordinalNum(..prevElem((..Level-1)),..Level)=$i(..ordinalNum(..prevElem(..Level-1),..Level))
			$$$DEBUGPARSER("tElemCount="_$g(tElemCount))
			//+ 104628
			//Set elementNum=$i(..elementNumber(..Level-1,qname))+$g(tElemCount)
			Set elementNum=1+$g(tElemCount)
			//Set elementNum=$i(..elementNumber(pDSubs,..parentList))+$g(tElemCount)
			//- 104628
			//$$$DEBUGPARSER("..elementNumber("_(..Level-1)_","_..parentList_")="_..elementNumber(..parentList))
			//$$$DEBUGPARSER("..elementNumber("_(..Level-1)_","_qname_"~"_(..Level-1)_")="_..elementNumber(..Level-1,qname_"~"_(..Level-1)))
			//+ Prodlog 102211 - 10-11-2012
			//Set ordinalNum=$i(..ordinalNum(qname_"~"_..Level,..Level))+$g(tElemCount) 
			//Set ordinalNum=$i(..ordinalNum(qname_"~"_(..Level-1),..Level-1)) ;+$g(tElemCount) 
			//- Prodlog 102211 - 10-11-2012
			//+ 104628
			//Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=..ordinalNum(..prevElem(..Level-1),..Level)
			//Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=kDom+1
			//Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=kDom+1
			//- 104628
			//Set tPDSubsRoot=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)
			//Set tPDSubs=tPDSubsRoot_","_ordinalNum
			//$$$DEBUGPARSER("******************* tPDSubs="_tPDSubs)
			//$$$DEBUGPARSER("******************* ordinalNum="_ordinalNum)
			$$$DEBUGPARSER("******************* elementNum="_elementNum)
			//$$$DEBUGPARSER("******************* ..ordinalNum(..prevElem(..Level-1),..Level)="_..ordinalNum(..prevElem(..Level-1),..Level))
			$$$DEBUGPARSER("******************* ..pDSubsList(..Level-1))="_..pDSubsList(..Level-1))
			if ..Level=1,CountToRight>0,'..replace {
				if 1 { ;..Level=1,'..skipSlide,CountToRight>0 {
					//Set newkDom=..ordinalNum(..prevElem(..Level-1),..Level)
					//Set newkDom=ordinalNum
					//Do ..domIncreaseElementNodes(pDSubs,..domElemNode(pDSubs,qname_">"_newkDom,.tSC),qname_">"_newkDom) // we increase count of matching elements 
					; TBD - use calculate element num and calculate ordinaly num to define locus of increasing element nodes
					Do ..domIncreaseElementNodes(pDSubs,..domElemNode(pDSubs,qname_">"_kDom,.tSC),qname_">"_elementNum) // we increase count of matching elements 
				} else {
					Do ..domIncreaseElementNodes(pDSubs,..domElemNode(pDSubs,qname_">"_kDom,.tSC),qname_">"_kDom) // we increase count of matching elements 
				}
				//Do ..domIncreaseElementNodes(pDSubs,kDom,qname_">"_kDom) // we increase count of matching elements 
			}

			//+ Prodlog 104484
			Set @$$$vaDOMRef(..pDSubsList(..Level-1))=qname_">"_elementNum
			//Set @$$$vaDOMRef(tPDSubsRoot_","_..ordinalNum(..prevElem(..Level-1),..Level))=qname_">"_elementNum
			//- Prodlog 104484
			//Set @$$$vaDOMRef(tPDSubs)=qname_">"_elementNum
			if ..Level=1 {
				Set ISubscript=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)_","">"_qname_""","_elementNum_","">I"""
				if ..pAfterCNode'="" Set @$$$vaDOMRef(ISubscript)=..pAfterCNode
			}
			kill @$$$vaDOMRef(..pDSubsList(..Level-1)_","">V""") ; kill any text nodes that were created by domSlideNodes
			$$$vaKillCalcCache1(pDSubs) ; JSL4382
			;Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),",")-1)=..ordinalNum(..Level-1)
			Set ..pDSubsList(..Level)=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)_","">"_qname_""","_elementNum_",1"
			// start Prodlog 100690, problem with append
			Set RLoc=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)_","">R"""
			$$$DEBUGPARSER(" R location="_RLoc_" defined="_$D(@$$$vaDOMRef(RLoc)))
			if $D(@$$$vaDOMRef(RLoc)) Set @$$$vaDOMRef(RLoc)=1 ; if node has ">R" value by previous Sets then set the ">R" value to 1 (don't remove and don't replace content)
			// end Prodlog 100690
			Set attrsub=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)_","">"_qname_""","_elementNum
			Set RepGroupLength=5
			for i=1:1:($LL(attrs)\RepGroupLength) {
				Set attrName=$LI(attrs,(i-1)*RepGroupLength+2)
				$$$DEBUGPARSER("attrName="_attrName)
				Set @$$$vaDOMRef(attrsub_","">@"","_i)=attrName
				Set @$$$vaDOMRef(attrsub_","">@"","">"_attrName_"""")=$LI(attrs,(i-1)*RepGroupLength+5)
			}
			Set ..attributeSub(..Level)=attrsub
			Set ..attributeCount(..Level)=$LL(attrs)
			;Set ..ordinalNum(..Level-1)=$i(ordinalNum(..Level-1))
			$$$DEBUGPARSER("after set vaDOMRef")
			//+ 104628
			Set ..prevElem((..Level))=..currentElement
			//- 104628


		}
		Set ..Level=..Level+1
		if ..Level'= 1 {
			do ..value("",0,">Z") ; an element must at least have an empty string, >Z type of dummy string 
		}
	}
	catch ExceptionVar {
		w !,"$ZError="_$ZError
	}
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String) [ Internal ]
{
	try {
		$$$DEBUGPARSER("begin ending element "_localname_" ..Level="_..Level)
		//Set ..ordinalNum(qname_"~"_..Level,..Level)=0
		Set ..currentElement=$g(..prevElem(..Level-2))
		$$$DEBUGPARSER("After set of currentElement")
		Set ..Level=..Level-1
		if (..Level>=1) {
			; process namespaces
			Set namespaceIndex=..attributeCount(..Level)
			Set attrsub=..attributeSub(..Level)
			$$$DEBUGPARSER("ending element "_qname_" level="_..Level_" attrsub="_attrsub)
			for i=1:1:$g(..namespaceMapping(..Level)) {
				Set namespaceIndex=namespaceIndex+1
				Set map=..namespaceMapping(..Level,i)
				Set prefixName=$P(map,",")
				Set tUri=$P(map,",",2)
				Set @$$$vaDOMRef(attrsub_","">@"","_namespaceIndex)=prefixName
				Set @$$$vaDOMRef(attrsub_","">@"","">"_prefixName_"""")=tUri
			}
			k ..namespaceMapping(..Level)

		}
		if (..Level >= 1) {
			Set finalIndex=$P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))
			$$$DEBUGPARSER("..Level-1="_(..Level-1)_" ..pDSubsList(..Level-1)="_..pDSubsList(..Level-1))
			$$$DEBUGPARSER("finalIndex="_finalIndex)
			Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=$i(finalIndex)
			//+ 104628
			//- 104628
			//+ 104628
			if (..Level > 0) {
				$$$DEBUGPARSER("..pDSubsList(..Level-1)"_..pDSubsList(..Level-1)_" ..Level="_..Level_" qname="_qname)
				//do ..domElementNormalize($P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1),qname)
			}
			//- 104628

		}
		Set pDSubs=$P(..pDSubsList(..Level),",",1,$L(..pDSubsList(..Level),",")-1)
		if (..Level '=0) {
			$$$DEBUGPARSER("at last ending element "_localname_" level="_..Level)
		} else {
			$$$DEBUGPARSER("at last ending element "_localname_" level="_..Level)
		}
		$$$vaKillCalcCache1(pDSubs)
	}
	catch ExceptionVar {
		w !,"$ZError="_$ZError
	}
}

Method characters(chars As %Library.String, length As %Library.Integer) [ Internal ]
{
	Do ..value(chars, length, ">T")
}

Method comment(chars As %Library.String, length As %Library.Integer) [ Internal ]
{
	Do ..value(chars, length, ">C")
}

Method value(chars As %Library.String, length As %Library.Integer, valueType As %String) [ Internal ]
{
	try {
		$$$DEBUGPARSER("value Level="_..Level_" pDSubs="_..pDSubsList(..Level-1)_" ..currentElement="_..currentElement_" chars="_$e(chars,1,length))
		//Set ordinalNum=$i(..ordinalNum(..currentElement,..Level)) 
		Set valueSubscript=..pDSubsList(..Level-1)
		Set finalIndex=$P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))
		$$$DEBUGPARSER("before valueSubscript="_valueSubscript)
		Set $P(valueSubscript,",",$L(valueSubscript,","))=+finalIndex
		$$$DEBUGPARSER("in characters finalIndex="_finalIndex)
		//+ 10-24-2012 10:02 PM experimental change
		//Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=$i(finalIndex)
		Set $P(..pDSubsList(..Level-1),",",$L(..pDSubsList(..Level-1),","))=$i(finalIndex)
		//- 10-24-2012 10:02 PM experimental change
		$$$DEBUGPARSER("valueSubscript="_valueSubscript)
		Set @$$$vaDOMRef(valueSubscript)=valueType
		if ..Level=1 {
			if ..pAfterCNode'="" {
				Set @$$$vaDOMRef(valueSubscript_","">I""")=..pAfterCNode
			} else {
				Set @$$$vaDOMRef(valueSubscript_","">I""")="+"
			}
		} else {
			Set @$$$vaDOMRef(valueSubscript_","">I""")="+"
		}
		Set @$$$vaDOMRef(valueSubscript_","">V""")=$e(chars,1,length)
		Set pDSubs=$P(..pDSubsList(..Level-1),",",1,$L(..pDSubsList(..Level-1),",")-1)
		$$$vaKillCalcCache1(pDSubs)
	}
	catch ExceptionVar {
		w !,"$ZError="_$ZError
	}
}

Method ignorableWhitespace(chars As %Library.String, length As %Library.Integer) [ Internal ]
{
	do ..characters(chars,length)
}

Method processingInstruction(target As %Library.String, data As %Library.String) [ Internal ]
{
	do ..value(target_" "_data,$L(target_" "_data),">I")
}

Method startPrefixMapping(prefix As %Library.String, uri As %Library.String) [ Internal ]
{
	try {
		$$$DEBUGPARSER("startPrefixMapping prefix="_prefix_" uri="_uri)

		if prefix="" && (uri '="") {
			Set prefix="xmlns"
		}
		Set namespaceIndex=$i(..namespaceMapping(..Level))
		Set prefixName="xmlns"_$s(prefix'="xmlns":":",1:"")_prefix
		Set ..namespaceMapping(..Level,namespaceIndex)=prefixName_","_uri
	}
	catch ExceptionVar {
		w !,"$ZError="_$ZError
	}
}

Method endPrefixMapping(prefix As %Library.String) [ Internal ]
{
 	$$$DEBUGPARSER("endPrefixMapping prefix="_prefix)
}

Method fatalError(fatalerror As %Library.String) [ Internal ]
{
  Set ..%ContentHandlerStatus=$$$ERROR($$$EnsErrGeneral, "Parsing Error: "_fatalerror)
}

Method findTextAfterCNode(pDSubs As %String, pCSubs As %String, pIgnoreNamespaces As %Boolean, Existing As %Boolean, ByRef pNSContext As %String, ByRef pTextAfterCNode As %String) [ Internal ]
{
	Set isTypeElement=0
	Set tRightType="text"
	Set pTextOrdinal=..findLast(pDSubs, pCSubs,"",.tCHit,.tDHit,.pTextAfterCNode,.prevCNode,Existing,.tElemIndex,.tElemName,isTypeElement,tRightType,.tOutputType,pIgnoreNamespaces,.tMatchedElemName,.pNSContext,0)
}

Method AppendToDom(pDOMSubs As %String, pInsertDSubs As %String, pOrdinal As %Integer) As %Integer [ Internal ]
{
}

Method ContentOnlyContainsText(pContentSubs As %String) [ Internal ]
{
	Set isTextOnly=1
	// 01-31-12
	if $D(@$$$vaContentRef(0)) {
		Set cNode="" For { Set cNode=$S(""=pContentSubs:"", 1:$$$domGetNextChild(..%ContentRef,pContentSubs,cNode))  Quit:""=cNode
			Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
			if $$$xmlELEMENTNODE=ctyp {
				Set isTextOnly=0 
				Quit
			}
		}
	}
	Quit isTextOnly
}

Method DomOnlyContainsText(pDSubs As %String) [ Internal ]
{
	Set isTextOnly=1
	kill Index
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))

	Set kDom="" For { 

		if '$D(Index) {
			Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom
		} else {
			if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
			if iIndex'="",jIndex'="" {
				Set dtyp=$LI(Index(iIndex,jIndex),1)
				Set kDom=+$LI(Index(iIndex,jIndex),2)
				Set IJSeen(iIndex,jIndex)=""
			} 
			if (jIndex="") {
				if iIndex'="" Set iIndex=$O(Index(iIndex))
				if (iIndex="") {
					Set kDom=""
				} else {
					continue
				}
			}
			Quit:kDom=""
		}

		if ">T"'=dtyp {
			Set isTextOnly=0
			Quit
		}
	}
	Quit isTextOnly
}

Method GatherDOMValue(pDSubs As %String) [ Internal ]
{
	Set isTextOnly=1
	kill Index
	do ..createIndex(pDSubs,.Index)
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))

	Set retValue=""
	Set kDom="" For { 

		if '$D(Index) {
			Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp)  Quit:""=kDom
		} else {
			if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
			if iIndex'="",jIndex'="" {
				Set dtyp=$LI(Index(iIndex,jIndex),1)
				Set kDom=+$LI(Index(iIndex,jIndex),2)
				Set IJSeen(iIndex,jIndex)=""
			} 
			if (jIndex="") {
				if iIndex'="" Set iIndex=$O(Index(iIndex))
				if (iIndex="") {
					Set kDom=""
				} else {
					continue
				}
			}
			Quit:kDom=""

		}
		if ">T"=dtyp {
			Set retValue=retValue_@$$$vaDOMRef(pDSubs_","""_kDom_""","">V""")
			Quit
		}
	}
	Quit retValue
}

// Set tSC = ..domSetAtIndex(pDOMPath ,   pMode ,                 .pCSubs,                  .pDSubs,                  .pNodeType,                  .pNodeIndex,                  .pNodeValue,                  .pNSContext,                  .pAfterCNode,       .pFinalSubscript,       .pInsertDSubs,       .pInsertIndex,       .pCHit,                   .pDHit,                   .pInsertType,                  .pTextOrdinal,                      .pTextAfterCNode,       .pTextSubscript,       .pInsertSubscript,       .pCNamespace,            pFormat,                   .pNamespaces, pIgnoreNamespaces,                pAction ,                       .pPrevNode,                  .pCurrentNode,                  .pCNodeTextHit,                   .pElemSubscript, tNode, tIndex, tParam,       .tCHit,       .tDHit,       .tCNode,       .prevCNode, tIgnoreNamespaces, tElemIgnoreNamespaces, tInsert, tFinalBeforeAttribute,.tChildCount, tOperateOnSet,       .tNonExistent)

Method domSetAtIndex(pDOMPath As %String, pMode As %String, Output pCSubs As %String, Output pDSubs As %String, Output pNodeType As %String, Output pNodeIndex As %String, Output pNodeValue As %String, Output pNSContext As %String, Output pAfterCNode, Output pFinalSubscript, Output pInsertDSubs, Output pInsertIndex, Output pCHit As %Boolean, Output pDHit As %Boolean, Output pInsertType As %String, Output pTextOrdinal As %String = 1, Output pTextAfterCNode, Output pTextSubscript, Output pInsertSubscript, Output pCNamespace As %Integer, pFormat As %String, Output pNamespaces, pIgnoreNamespaces As %Boolean = 0, pAction As %String = "", Output pPrevNode As %String, Output pCurrentNode As %String, Output pCNodeTextHit As %Boolean, Output pElemSubscript, tNode, tIndex, tParam, Output tCHit, Output tDHit, Output tCNode, Output prevCNode, tIgnoreNamespaces, tElemIgnoreNamespaces, tInsert, tFinalBeforeAttribute, tChildCount, tOperateOnSet, Output tNonExistent) As %Status [ Internal ]
{
	;w !,"domSetAtIndex pDOMPath="_pDOMPath
	Set tSC=$$$OK
	Set pInsertDSubs=pDSubs
	if (tNode) {
		Set isTypeElement=0
	} else {
		Set isTypeElement=1
	}
	set unsorted=0
	Set nFound=0
	; 04-15-11
	; 04-16-11
	; 04-18-11
	; 04-19-11
	; 04-13-11
	; 04-21-11
	Set ignoreremove=1
	;w !,"in domSetAtIndex pDSubs="_pDSubs
	;b:pDOMPath["/root/element(domBefore2)[~3]" 
	$$$vaKillCalcCache1(pDSubs) ; JSL4382 part B - fix regression JSL4384, uncommenting did not fix regression
	;$$$vaKillCalcCache ; putting killcalccache here did not fix infinite loop in regression 8:06 PM 
	Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex,  tNode, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.dummy,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,pNamespaces,.pNSContext,.kReturn,unsorted,0)
	$$$vaKillCalcCache ; JSL4382 partB - uncommenting did not fix regression
	;w !,"pDSubs="_pDSubs_" pCSubs="_pCSubs_" kDom="_kDom_" tIndex="_tIndex
	if tNode,'tInsert {
		if tCHit||tDHit {
			if tOutputType'="element" Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set element at index "_(tIndex)_" which is of type non-element to node of different type "_tOutputType_" while "_tParam_" is element") quit tSC
			if $g(tMatchedElemName)'="",tMatchedElemName'=tParam Set tSC=$$$ERROR($$$EnsErrGeneral,"Can't set element at index "_(tIndex)_" which is of type "_tMatchedElemName_" to node of different type "_tParam) quit tSC
		}
	}

	; find highest index of tParam in DOM array
	Set tHighestIndex=1,tHighestParamIndex=0
	Set tEIndex=1
	Set kFound=0
	kill Count1
	Set skipSlide=0
	do {
		$$$vaKillCalcCache ; JSL4832
		Set kDom1=..findIndex(pDSubs, pCSubs, "", tHighestIndex, tNode, .tSC1, .tCHit1, .tDHit1,.tCNode1,.prevCNode1,0,.tElemIndex1,.tElemName1,isTypeElement,"",.nFound1,.dummy1,.tOutputType1,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName1,pNamespaces,.pNSContext,.kReturn1,unsorted,0)
		$$$vaKillCalcCache ; JSL4382
		if kFound=0 if $g(tElemName1)=tParam,tDHit1 set tHighestParamIndex=tHighestIndex,tEIndex=tElemIndex,tEIndex1=$i(Count1(tParam))
		; if we have a tDHit1 at index we skip domSlideNodes, we will kill the old node at this point
		; and we save killName and killIndex to allow us to kill old node
		if kFound=0 if tDHit1 if tIndex=tHighestIndex Set skipSlide=1,killName=$g(tElemName1),killIndex=tElemIndex1
		Set tReplace=$G(@$$$vaDOMRef(pDSubs_","">"_$g(tElemName1)_""","_tElemIndex1_","">R""")), tRemove=(tReplace>1)
		;w !,"tElemName1="_$g(tElemName1)_" tElemIndex1="_tElemIndex1_" tReplace="_tReplace
		if kFound=0 if tDHit1 if tIndex<=tHighestIndex Set kSubscript=kDom1,kFound=1 i $g(tElemName1)'=tParam Set tEIndex1=$i(Count1(tParam))
		;if tIndex=tHighestIndex Set kSubscript=kDom1
		;w !,"tElemName1="_$g(tElemName1)_" tParam="_tParam_" tDHit1="_tDHit1_" tHighestIndex="_tHighestIndex_" kSubscript="_$g(kSubscript)_" kReturn="_kReturn_" tEIndex1="_$g(tEIndex1)_" kFound="_kFound
		Set tHighestIndex=$i(tHighestIndex)

	} while tDHit1||tCHit1
	if '$D(kSubscript) {
		Set kLast=kDom
	} else {
		Set kLast=kSubscript
	}
	;w !,"tHighestIndex="_tHighestIndex_" tIndex="_tIndex_" tHighestParamIndex="_tHighestParamIndex_" tEIndex="_tEIndex_" pDSubs="_pDSubs
	Set kIndex=..domElemNode(pDSubs,$g(tElemName)_">"_tElemIndex,.tSC)
	Set tElemIndexSave=tElemIndex
	;w !,"tElemName="_$g(tElemName)_" tElemIndex="_tElemIndex_" kIndex="_kIndex
	if tNode {
		if (nFound < (tIndex-1)) set tSC=$$$ERROR($$$EnsErrGeneral,"No node exists at index "_(tIndex-1)) quit tSC
	} else {
		if (nFound < (tIndex-1)) set tSC=$$$ERROR($$$EnsErrGeneral,"No element exists at index "_(tIndex-1)) quit tSC
	}
	Set found=0
	; 04-07-11
	kill Count
	Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) quit:kDom1=$g(kSubscript)  quit:kDom1=""
		;if $D(dtyp) If $P(dtyp,">",1)=tParam Set tElemCount=$i(Count(tParam))
		if $D(dtyp) If $P(dtyp,">",1)=tParam Set:(kDom1'="") found=1 
	}
	; 5/2/11
	Set kDom1="" For { kill dtyp Set kDom1=$O(@$$$vaDOMRef(pDSubs_","""_kDom1_""""),1,dtyp) Set:$e(kDom1)=">" kDom1="" quit:kDom1=""
		if $D(dtyp) If $P(dtyp,">",1)=tParam Set tElemCount=$i(Count(tParam))
		;if kDom1="" quit
		;if kDom1=kDom quit
		;if kDom1=$g(kSubscript) quit
		if kDom1=$g(kLast) quit
	}
	if '$D(tElemCount) Set tElemCount=1
	Set dtypElem=$g(@$$$vaDOMRef(pDSubs_","""_kLast_""""))
	; 05-02-11
	;w !,"kFound="_kFound_" tElemCount="_$g(tElemCount)_" kDom="_kDom_" kLast="_kLast_" dtypElem="_dtypElem_" tParam="_tParam
	if $P(dtypElem,">",1)'=tParam { ; tHighestIndex >= tIndex {
		Set tElemCount=$i(Count(tParam))
	}
	;if '$D(tElemCount) Set tElemCount=1
	; 04-19-11 skip slide when not doing an insert under some circumstances
	if (tInsert||((pMode="set")&&(tOperateOnSet=1))) {	
		; Calculate end of kDom
		Set kDom2=$S("_"=pDSubs:"",1:">") ; '>' collates higher than numbers
		Set kDom2=$O(@$$$vaDOMRef(pDSubs_","""_kDom2_""""),-1,dtyp)  
		;w !,"pDOMPath="_pDOMPath_" tDHit="_tDHit_" tCHit="_tCHit_" kReturn="_kReturn_" kDom="_kDom_" kDom2="_kDom2_" tIndex="_tIndex_" nFound="_nFound_" tHighestParamIndex="_tHighestParamIndex
		;if (tHighestParamIndex >= tIndex) {
		;if (tHighestIndex >= tIndex) {
		if kFound {
			;Do ..domSlideElementNodes(pDSubs,kIndex,tParam_">"_kDom)  Quit:$$$ISERR(tSC)  
			if $D(kSubscript) {
				;Do ..domSlideElementNodes(pDSubs,kSubscript,tParam_">"_kDom2)  Quit:$$$ISERR(tSC)  
				if (tInsert || 'skipSlide) {
					; 04-20-11
					Do ..domSlideElementNodes(pDSubs,kSubscript,tParam_">"_tEIndex1)  Quit:$$$ISERR(tSC)  
				}
			} else {
				Set kIndex=kDom
				Set kSubscript=kDom
				;Set tEIndex=$i(tElemCount)

			}
		} else {
			Set kIndex=kDom
			Set kSubscript=kDom
			;Set tEIndex=$i(tElemCount)
		}
	}
	if (tFinalBeforeAttribute=1) {
		Set pInsertType="elementattribute"
	} else {
		Set pInsertType="elementtext"
	}
	;Set kDom=..findIndex(pDSubs, pCSubs, "", tIndex, .tSC, .tCHit, .tDHit,.tCNode,.prevCNode,0,.tElemIndex,.tElemName,isTypeElement,"",.nFound,.dummy,.tOutputType,,tIgnoreNamespaces||tElemIgnoreNamespaces,.tMatchedElemName,.pNSContext,.kReturn)
	if '$D(tEIndex1) {
		set tEIndex1=1
	}
	elseif ('kFound) {
		Set tEIndex1=tElemCount+1
	}
	Set pInsertIndex=..calcInsertIndex(pDSubs,tParam_">"_tElemCount)
	;Set pInsertIndex=..calcInsertIndex(pDSubs,tParam_">"_tEIndex1)
	Set kDom3=$S("_"=pInsertDSubs:"",1:">") ; '>' collates higher than numbers
	Set kDom3=$O(@$$$vaDOMRef(pInsertDSubs_","""_kDom3_""""),-1,dtyp)  
	if (kFound) {
		;Set kDom3=..domElemNode(pDSubs,tElemName_">"_tElemIndex,.tSC) ;?
		;Set kDom3=kIndex
		;Set kDom3=..domElemNode(pDSubs,tParam_">"_tIndex,.tSC) ;?
		Set kDom3=kSubscript
	} else {
		Set kDom3=kDom3+1
	}
	Set pFinalSubscript=kDom3
	Set pElemSubscript=..calcISubscript(pDSubs,tParam_">"_tElemCount)
	;Set pElemSubscript=..calcISubscript(pDSubs,tParam_">"_tEIndex1)
	;w !,"pElemSubscript="_pElemSubscript
	Set tChildCount=tChildCount+1 
	Set:tParam'="" tElem=tParam
	Set:tDHit tElem=tElemName
	// 09-29-10, namespce implmentation
	;Set:tCHit tElem=@$$$vaContentRef(tCNode)
	if tCNode'="" {
		Set:tCHit tElem=$$$domGetQName(..%ContentRef,tCNode)
	}
	if tNode,tInsert=0,skipSlide=1,killIndex'="" { ; we aren't inserting so kill old node
		Set pKillSubs=pDSubs_","">"_killName_""""_","_killIndex
		; pAfterCNode won't be set so we need to save and restore old I, remove from old Node and restore in new Node
		Set ISave=$g(@$$$vaDOMRef(pKillSubs_","">I"""))
		;w !,"pDOMPath="_pDOMPath_" killing "_pKillSubs
		kill @$$$vaDOMRef(pKillSubs)
		;Set @$$$vaDOMRef(pKillSubs_","">I""")=ISave
		Set @$$$vaDOMRef(pElemSubscript_","">I""")=ISave
	}

	$$$vaKillCalcCache1(pDSubs) ; JSL4382
	$$$vaKillCalcCache1(pElemSubscript)
	Set pDSubs=pDSubs_","">"_tElem_""""_$S('tElemIndex:"",1:","_tElemIndex)
	Set:tInsert=0 pCSubs=tCNode
	Set pCurrentNode=tCNode
	Set:tCNode'="" pCNamespace=$s(tCHit&&'tInsert&&$$$isNodeElement(..%ContentRef,tCNode):tCNode,1:$$$NamespaceSource(..%ContentRef,tCNode))
	Set:tInsert=1 pAfterCNode="+"_prevCNode
	if (tInsert=0)&&((pMode="set")&&(tOperateOnSet=1)&&('tDHit)) {
		Set pAfterCNode=tCNode
	}

	quit tSC
}

Method domElementNormalize(pDSubs, pElemName) [ Internal ]
{
	//+ 104628
	quit
	// use in textinsert
	//- 104628

#define SaveRef(%S,%subs) $S(")"=$E(%S,*):$E(%S,1,*-1)_(%subs)_")", ""=(%subs):%S, 1:%S_"("_$E(%subs,2,*)_")")
	; get >I index
	; 9-28-10, how do we handle the proble of null ">I" index superceding everything
	Set DomSaveName="%DomSave"
	kill @DomSaveName
	Set kDom="" 
	For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:">"=$E(kDom) kDom="" Quit:""=kDom
		Set dtyp=$g(@$$$vaDOMRef(pDSubs_","""_kDom_""""))
		;w !,"In Normalize dtyp="_dtyp
		if dtyp'="",$e(dtyp)'=">" {
			Set seen(dtyp)=""
			Set tElemName=$P(dtyp,">",1)
			Set tElemOrdinal=$P(dtyp,">",2)
			//+ 104628
			//- 104628
			merge @$$$SaveRef(DomSaveName,pDSubs_","">"_tElemName_""","_tElemOrdinal)=@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemOrdinal)
			Set Subscript(pDSubs_","">"_tElemName_""","_tElemOrdinal)=""
		}
		
	}

	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:$e(kDom)=">" kDom=""  Quit:""=kDom  
		if $D(dtyp) {
			// element, count how many times it appears
			if 1 { ; $P(dtyp,">",1)=pElemName 
				Set tElemName=$P(dtyp,">",1)
				if tElemName="" continue
				Set tElemOrdinal=$P(dtyp,">",2)
				kill @$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tElemOrdinal)
			}
		}
	}

	;w !,"pDSubs="_pDSubs_" pElemName="_pElemName
	kill Count
	Set kDom="" For { Set kDom=$O(@$$$vaDOMRef(pDSubs_","""_kDom_""""),1,dtyp) Set:$e(kDom)=">" kDom=""  Quit:""=kDom  
		if $D(dtyp) {
			// element, count how many times it appears
			if 1 { ; $P(dtyp,">",1)=pElemName 
				Set tElemName=$P(dtyp,">",1)
				if tElemName="" continue
				Set tElemOrdinal=$P(dtyp,">",2)
				Set Count($P(dtyp,">",1))=$i(Count($P(dtyp,">",1)))
				Set tNewElemOrdinal=Count($P(dtyp,">",1))
				;if tNewElemOrdinal="" Set tNewElemOrdinal=1
				Set $P(@$$$vaDOMRef(pDSubs_","""_kDom_""""),">",2)=tNewElemOrdinal
				// 05-04-11
				;if tElemOrdinal'="" if $G(@$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tNewElemOrdinal_","">R"""))'=2 merge @$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tNewElemOrdinal)=@$$$SaveRef(DomSaveName,pDSubs_","">"_tElemName_""","_tElemOrdinal)
				merge @$$$vaDOMRef(pDSubs_","">"_tElemName_""","_tNewElemOrdinal)=@$$$SaveRef(DomSaveName,pDSubs_","">"_tElemName_""","_tElemOrdinal)
			}
		}
	}
	kill @DomSaveName
#if 2
	w !,"In domElementNormalize end",!
	merge temp2=..%DOMCache
	w !
	zw temp2
#endif
}

Method SchematizeNamespace(pFlag As %Boolean, pContentSubs As %Integer, pElem As %String, pNamespaceDef As NamespaceHelper, ByRef pSchemaPrefixes, ByRef pNSContext As %String) [ Internal ]
{
	if 'pFlag quit pElem
	Set tContentUri=$$$domGetNamespaceURI(..%ContentRef,pContentSubs)
	; first look up URI in pNSContext
	Set level=pNSContext("level")
	set i="" for {  set i=$o(pNSContext(level,"namespaces",i),1,urivalue) q:i=""  
		if i[":" {
			Set iscprefix=$P(i,":",2)
			if $e(iscprefix,1,$L("xsd_"))="xsd_" continue
		}
		q:tContentUri=$g(urivalue)
	}
	if i'="",$D(urivalue),tContentUri=urivalue {
		Set found=1
		if pElem[":" {
			Set localname=$P(pElem,":",2)
		} else {
			Set localname=pElem
		}
		;Set localname=$P(pElem,":",2)
		set returnPrefix=$P(i,":",2)
		if (returnPrefix'="") {
			Set pElem=returnPrefix_":"_localname
		} else {
			Set pElem=localname
		}
		if (returnPrefix'="") {
			do pNamespaceDef.addNamespace("xmlns:"_returnPrefix,"'"_tContentUri_"'")
			Set pSchemaPrefixes(returnPrefix)=""
		} else {
			do pNamespaceDef.addNamespace("xmlns","'"_tContentUri_"'")
			Set pSchemaPrefixes("xmlns")=""
		}
		quit pElem
	}
	; look up URI in schema
	Set tPrefix=""
	if ..DocTypeCategory="" quit pElem
	Set index="" for {  Set index=$O($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index)) q:index=""
		Set tSchemaUri=$g($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index,"uri"))
		if tSchemaUri=tContentUri Set tPrefix="xsd_"_index quit
	}
	if (tPrefix'="") {
		if pElem[":" {
			Set $P(pElem,":")=tPrefix
		} else {
			Set pElem=tPrefix_":"_pElem
		}
		#; leading space removed
		do pNamespaceDef.addNamespace("xmlns:"_tPrefix,"'"_tSchemaUri_"'")
		Set pSchemaPrefixes(tPrefix)=""
	}
	quit pElem
}

Method domGT(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	Set %c1=c1
	Set %c2=c2
	quit $s((%c1="")||(%c2=""):($$$domDiffNull(%c1,%c2))>0,1:($$$xmliChildOrder(..%ContentRef,$$$xmlParentNode(..%ContentRef,%c1),%c1,%c2))>0)
	$$$DEBUGC1C2("GT",c1,c2)
	$$$domStripPlus(c1)
	$$$domStripPlus(c2)
	do ..AssertSameParent(c1,c2)
	if (c1="")||(c2="") {
		Set diff=$$$domDiffNull(c1,c2)
	} else {
		Set diff = $$$xmliChildOrder(..%ContentRef,$$$xmlParentNode(..%ContentRef,c1),c1,c2)
	}
	$$$DEBUGDIFF(diff)
	quit diff>0
}

Method domGE(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	$$$DEBUGC1C2("GE",c1,c2)
	$$$domStripPlus(c1)
	$$$domStripPlus(c2)
	do ..AssertSameParent(c1,c2)
	if (c1="")||(c2="") {
		Set diff=$$$domDiffNull(c1,c2)
	} else {
		Set diff = $$$xmliChildOrder(..%ContentRef,$$$xmlParentNode(..%ContentRef,c1),c1,c2)
	}
	$$$DEBUGDIFF(diff)
	quit diff>=0
}

Method domLT(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	$$$DEBUGC1C2("LT",c1,c2)
	$$$domStripPlus(c1)
	$$$domStripPlus(c2)
	do ..AssertSameParent(c1,c2)
	if (c1="")||(c2="") {
		Set diff=$$$domDiffNull(c1,c2)
	} else {
		Set diff = $$$xmliChildOrder(..%ContentRef,$$$xmlParentNode(..%ContentRef,c1),c1,c2)
	}
	$$$DEBUGDIFF(diff)
	quit diff<0
}

Method domLE(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	$$$DEBUGC1C2("LE",c1,c2)
	$$$domStripPlus(c1)
	$$$domStripPlus(c2)
	do ..AssertSameParent(c1,c2)
	if (c1="")||(c2="") {
		Set diff=$$$domDiffNull(c1,c2)
	} else {
		Set diff = $$$xmliChildOrder(..%ContentRef,$$$xmlParentNode(..%ContentRef,c1),c1,c2)
	}
	$$$DEBUGDIFF(diff)
	quit diff<=0
}

Method domEQ(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	//do ..AssertSameParent(c1,c2)
	$$$DEBUGC1C2("EQ",c1,c2)
	$$$DEBUGDIFF(c1=c2)
	q c1=c2 ; + in front means exactly equal
}

Method AssertSameParent(c1 As %Integer, c2 As %Integer) [ Internal ]
{
	if (c1'=""),(c2'="") {
		if $e(c1)="+" Set c1=$e(c1,2,*)
		if $e(c2)="+" Set c2=$e(c2,2,*)
		if (c1'=""),(c2'="") {
			if $$$xmlParentNode(..%ContentRef,c1)'=$$$xmlParentNode(..%ContentRef,c2) {
				w !,"c1="_c1_" c2="_c2
				k temp  merge temp=..%ContentRef
				w !
				zw temp
				w !
				$$$ASSERT(0)
			}
		}
	}
}

Method domGetNextChild(documentId, nodeId, childId) As %String [ Internal ]
{
	//Set retval=$s('$D(@$$$vaContentRef(0)):"",1:$s((nodeId=0)&&(childId'="")&&(childId'=-1):"",1:$s((nodeId=0)&&((childId="")||(childId=-1)):$$$xmlGetDocumentElement(..%ContentRef),1:$s(childId=-1:$s($$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE:$$$xmlGetFirstChild(documentId,nodeId),1:""),1:$s($$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE:$$$xmlGetNextChild(documentId,nodeId,childId),1:""),1:""),1:""),1:""),1:"")
	//quit retval
	Set retval=""
	try {
		;s retval=$s((nodeId=0)&&(childId'="")&&(childId'=-1):"",1:$s((nodeId=0)&&((childId="")||(childId=-1)):$$$xmlGetDocumentElement(..%ContentRef),1:$s((childId)=-1:$$$xmlGetFirstChild(documentId,nodeId),1:$$$xmlGetNextChild(documentId,nodeId,childId))))
		if '$D(@$$$vaContentRef(0)) {
			Set retval="" ; empty DOM return ""
		} elseif nodeId=0,childId'="",childId'=-1 {
			Set retval=""
		} elseif nodeId=0,childId=""||(childId=-1) {
			Set retval=$$$xmlGetDocumentElement(..%ContentRef)
		} elseif childId=-1||(childId="") {
			if $$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE {
				Set retval = $$$xmlGetFirstChild(documentId,nodeId)
			}
		} else {
			if $$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE {
				Set retval = $$$xmlGetNextChild(documentId,nodeId,childId)
			}
		}
	} catch {
	}
	quit retval
}

Method domGetQName(documentId, nodeId) [ Internal ]
{
	Set retval=""
	try {
		if $$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE {
			Set retval=$$$xmlGetQName(documentId,nodeId)
		}
	}
	catch {
	}
	quit retval
}

Method domGetNamespaceURI(documentId, nodeId) [ Internal ]
{
	Set retval=""
	try {
		if $$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE {
			Set retval=$$$xmlGetNamespaceURI(documentId,nodeId)
		}
	}
	catch {
	}
	quit retval
}

Method domGetLocalName(documentId, nodeId) [ Internal ]
{
	Set retval=""
	try {
		if $$$xmlGetNodeType(documentId,nodeId)=$$$xmlELEMENTNODE {
			Set retval=$$$xmlGetLocalName(documentId,nodeId)
		}
	}
	catch {
	}
	quit retval
}

ClassMethod nodesToList(ByRef array) [ Internal ]
{
	Set list=""
	Set node="" For {  Set node=$O(array(node)) q:node=""
		Set list=list_$LB(node)
	}
	quit list
}

ClassMethod listToNodes(pList, Output pArray) [ Internal ]
{
	for i=1:1:$LL(pList) {
		Set item=$LI(pList,i)
		Set pArray(item)=""
	}
}

/// pDOMPath - input full DOM Path <br>
/// pContentSubs - node in Content Array<br>
/// pDOMSubs - node in DOM array<br>
/// pFormat - format string used to decide things like indentation <br>
/// pNSContext - multidimensional array used to store information, including namespace information, about calculation in progress
/// pCHit - whether hit at Content Array node <br>
/// pDHit -  whether hit at DOM node <br>
/// pNamespaces - namespace string used to output namespaces at node <br>
/// level - what level of XML tree are we on?  Special processing at level 1.  
/// SeenCNode - avoid processing cNode twice
/// cSeen - avoid processing cNode twice
/// pPPGIndex - index into process private global <br>
/// pWriteIndex - write index into process private global <br>
/// pNamespaceFound - are namespaces used at node or below it in XML tree <br>
/// pCount - number of element amongst sibling nodes (the parent has n children and these are all siblings) <br>
/// pCachedNamespaces - cached namespaces - can include cached namespaces for entire XML tree<br>
Method domValidate(pDOMPath As %String, pContentSubs As %String, pDOMSubs As %String, pFormat As %String, ByRef pNSContext As %String, pCHit As %Boolean, pDHit As %Boolean, pNamespaces As %String, ByRef level = 0, ByRef SeenCNode, ByRef cSeen, pNamespaceFound As %Boolean = 1, pCount As %Integer = 0, ByRef pCachedNamespaces) As %Status [ Internal ]
{
	/*
	pFormat flags:
	1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)
	a : attributes alphabetical
	c : canonical ; ignores 'eintw'
	e : close elements even when empty
	f : full top element not just its contents
	i : indent with 4 spaces unless 't' or 1-9
	l : output schema information, schema uri and schema location, based on property stored in ..schemaLocation
	n : newline (lf) after every text-free element
	o : output unescaped - for instance don't change < to &lt;
	p : suppress output of namespace prefixes
	q : use double quotes to set off attribute values if possible
	s : use stored indentation whitespace (ignores 'it1-9')
	r : use stored returns / newlines (ignores 'nw')
	t : indent with tab
	u : declare prefixes as well as using them
	w : Windows-style cr/lf newline after every text-free element
	x : omit namespaces in output
	*/
	;n IJSeen,Index,SeenKNode,cNode,ctyp,doit,dok,dtyp,iIndex,jIndex,kDom,nFound,nsp,tAfterCNode,tAfterCNodeNoPlus,tAttrCount,tCHit,tCNode,tDHit,tDoLoop,tEc,tElem,tElemIndex,tElemName,tHadContent,tHadText,tIgnoreContentSubs,tIndent,tIsStream,tLevel,tNamespaceDef,tOldElem,tOldIndent,tParentCNode,tRemove,tReplace,tReplaceContent,tRootDone,tSC,tSetFirstC,tTab,tVal,tWasMinusOne,kSeen,tAttrSubs,tAttrs,tCNodeChildList,tCNodeDescriptor,tChildList,tClose,tContentSubsTypeIsElement,tDescriptor,tHasText,tNamespaces,tOpen,tTopArray,tWriteIndex,cNodeDescriptor,prefix,suffix,tOpenVal,tPPGIndex,tReadIndex,tStringType,tStringVal,tTempVal
	if level = 0 { // only do at top, we are setting schema location properties used by this document object
		if pFormat[$$$OUTPUTSCHEMAINFO {
			// set pSchema from schema global, this will be set to noNamespaceSchemaLocation or schemaLocation as appropriate
			if ..DocType'="" {
				Set systemId=$G($$$vaSchemaGbl($P(..DocType,":"),"src",1))
			} else {
				Set systemId=""
			}
			// We are using our global schema to set the schemaLocation or noNamespaceSchemaLocation for validation
			// count the namespaces.  If only one,
			// then in ..OutputToIOStream we are using xsi:noNamespaceSchemaLocation
			Set namespaceCount=0
			if ..DocType'="" {
				Set i="" for {  Set i=$O($$$vaSchemaGbl($P(..DocType,":"),"ns","list",i)) q:i=""
					Set namespaceCount=namespaceCount+1
				}
			}
			if namespaceCount > 1 {
				Set uri=$G($$$vaSchemaGbl($P(..DocType,":"),"ns","targ"))
			} else {
				Set uri=""
			}
			if systemId'="",uri'="" {
				Set tSchema=uri_" "_systemId
				Set tUseNamespaceSchemaLocation=1
			} else {
				Set tSchema=systemId
				Set tUseNamespaceSchemaLocation=0
			}
			if tUseNamespaceSchemaLocation {
				Set ..schemaLocation=tSchema
			} else {
				Set ..noNamespaceSchemaLocation=tSchema
			}

		}
	}

	Set level=$i(level)
	if $D(@$$$vaContentRef(0)) {
		if pContentSubs=0 { // magic number
			Set tTopArray($$$xmlGetDocumentElement(..%ContentRef))=""
		}
		if (pContentSubs'="") {
			Set tContentSubsTypeIsElement=($$$xmlGetNodeType(..%ContentRef,pContentSubs)=$$$xmlELEMENTNODE)
		}
		
	}
	;merge tNSContextSave=pNSContext

	Kill pNSContext(level)  if $D(pNSContext(level-1)) Merge pNSContext(level)=pNSContext(level-1)
	If pDOMSubs'="_" {
		Set nsp=">xmlns" For { Set nsp=$O(@$$$vaDOMRef(pDOMSubs_","">@"","""_nsp_""""),1,uri)  Quit:">xmlns"'=$E(nsp,1,$L(">xmlns"))
			Set:""=$G(uri)&&(nsp?1">xmlns:xsd_"1.N) uri=$G($$$vaSchemaGbl(..DocTypeCategory,"ns","list",$E(nsp,$L(">xmlns:")+1,*),"uri"))
			Set pNSContext(level,"namespaces",$E(nsp,2,*))=uri
		}
	}
	if (pCHit=0)&&(pDHit=0) {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to fetch sub-tree, no hit at "_pDOMPath_" pContentSubs="_pContentSubs_" pDOMSubs="_pDOMSubs) 
		goto quitstatus
	}
	;kill pNSContext(pNSContext("level"),"namespaces") ; don't use namespaces set at this level
	#; if (pDHit=0) Set pCHit=1
	if (pContentSubs=">")||(pContentSubs="-1") set pContentSubs=""
	Set tSC=$$$OK

	Set (tRemove,tReplace,tReplaceContent,tEc)=0, tElem=""
	Set tIgnoreContentSubs=0
	Set tSetFirstC=0
	#;Set tPrecedingNonElements=0
	;If ("_"'=pDOMSubs)&&(pDOMPath'="/")&&$D(@$$$vaDOMRef(pDOMSubs))&&pDHit {
	If pDHit&&("_"'=pDOMSubs)&&$D(@$$$vaDOMRef(pDOMSubs)) {
		#; ">R"=2 : Remove entire element, ">R"=1 : =Replace entire element contents(including attributes), ">R"="" : extend contents	
		Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">R""")), tRemove=(tReplace>1)
		Set tReplaceContent=(tReplace="c")
		Set tEc=(tReplace="d")
		Set:tReplace pContentSubs=""  ; ignore content node if so marked
		If 'tRemove {
			Set tElem=$E($TR($P(pDOMSubs,",",$L(pDOMSubs,",")-1),"""",""),2,*)
			if tElem[":" {
				// colonized name
				Set prefix=$P(tElem,":",1)
				If $e(prefix)="$" {
					Set tSC=$$$ERROR($$$EnsErrGeneral, "DOM must not have element name whose prefix starts with '$' pDOMPath="_pDOMPath_" pDOMSubs="_pDOMSubs_" tElem="_tElem_" prefix="_prefix) 
					goto quitstatus
				}
			}

			Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.tSC)
			// 10-13-11
			if tElem="/",pDOMPath="/" {
				Set tIgnoreContentSubs=1
			}
			if tElem="/",pDOMPath="/",$g(@$$$vaDOMRef(pDOMSubs_",""1"""))'="",$e(@$$$vaDOMRef(pDOMSubs_",""1"""))=">" {
				Set tSetFirstC=1
				#;Set tPrecedingNonElements=0
				;Set tIgnoreContentSubs=0
			}
			Set:"/"=tElem tElem=""
			If $$$ISERR(tSC) goto quitstatus
		}
	}
	#; Get tElem from Content array if not in DOM array
	Set tNamespaceDef=""
	// if no namespaces set up xmlns:xsi and xsi:schemaLocation if pFormat says to output schema info and schemaLocation is non-null
	if level=1,pNamespaceFound=0,pFormat [ $$$OUTPUTSCHEMAINFO,(..schemaLocation'="")||(..noNamespaceSchemaLocation'="") {
		Set tLocation=$s(..schemaLocation'="":" xsi:schemaLocation='"_..schemaLocation_"'",1:" xsi:noNamespaceSchemaLocation='"_..noNamespaceSchemaLocation_"'")
		Set tNamespaceDef = " xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'"_tLocation
	}

	if $D(@$$$vaContentRef(0)),pContentSubs'="",tContentSubsTypeIsElement {
		$$$xmlaGetChildList(..%ContentRef,pContentSubs,tChildList,tDescriptor)
	}

	// questionable area 03-05-2012
	If 'tIgnoreContentSubs,(pCHit),pContentSubs'="",$D(@$$$vaContentRef(0)) {
		// 09-29-10, support namespaces
		;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
		if pContentSubs'=0,pContentSubs'=-1 {
			if pNamespaceFound {
				Set tElem=$$$xmlaGetQName(..%ContentRef,tChildList)
			} else {
				Set tElem=$$$xmlaGetLocalName(..%ContentRef,tChildList)
			}
		} else {
			// magic number in pContentSubs
			// Set tElem=$G(@$$$vaContentRef(pContentSubs)) 
			//Set tElem=$$$domGetQName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))
			Set tElem=""
		}
		if (pNamespaceFound) {
			Set tElem=..ConditionallyRemoveNSPrefix((pFormat["p"),tElem,.pNSContext,.tSC)
			;Set tElem=..SchematizeNamespace((pFormat["u"),pContentSubs,tElem,.tNamespaceDef,.pNSContext)
			if level=1,pFormat [ $$$OUTPUTSCHEMAINFO,(..schemaLocation'="")||(..noNamespaceSchemaLocation'="") {
				Set tLocation=$s(..schemaLocation'="":" xsi:schemaLocation='"_..schemaLocation_"'",1:" xsi:noNamespaceSchemaLocation='"_..noNamespaceSchemaLocation_"'")
				Set tNamespaceDef = tNamespaceDef_" xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'"_tLocation
			}

		}
		if $$$ISERR(tSC) goto quitstatus
	}

	#; Output the top element if called for
	Set pFormat=$ZStrip(pFormat,"<WC")
	Set tIndent=$ZStrip(pFormat,"<AN"), pFormat=$E(pFormat,1,*-$L(tIndent))
	if pNamespaceFound {
		merge tNamespaceNodes=pNSContext(pNSContext("level"),"namespaces")
	}
	Set tOldElem=tElem
	;w !,"tElem="_tElem ; debugout
	If ""'=tElem && (pFormat["f") {
		;if pDOMPath'="/" Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set pNSContext("elementcount")=$g(pNSContext("elementcount"))+1
		Set tAttrs=""
		if (tReplace'="a") {
			// we can tighten pDOMSubs condition to include any pDOMSubs without attributes attached to it 06-14-2012
			if (pDOMSubs'="_")||($$$xmlaGetNumberAttributes(..%ContentRef,tChildList) > 0) {
				do ##class(EnsLib.EDI.XML.NamespaceHelper).getPrefixes(..%ContentRef,pContentSubs,.tPrefixes) // JSL4301, requires XML underlying architecture in 2013.1 or above
				Set tSC=..domGetAttrs(.tPrefixes,.tAttrs,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),$g(pFormat),.pNSContext,pCHit,pDHit,.tAttrCount)  
				if $$$ISERR(tSC) goto quitstatus
			}
		}
		Set tNamespaces=""
		if (pNamespaces="") { 
			if pNamespaceFound {
				Set tNamespaces=##class(NamespaceHelper).%New()
				if $D(pCachedNamespaces) {
					// Use cache to set tNamespaces and get namespaces into pNSContext
					//$$$ASSERT($D(pCachedNamespaces(level,pCount,"pNamespaces")))
					Set tNamespaces=$g(pCachedNamespaces(level,pCount,"pNamespaces"))
					merge pNSContext(level,"namespaces")=pCachedNamespaces(level,pCount)
				} else {
					do ..domGetNamespaces(tNamespaces,pContentSubs,$S("_"=pDOMSubs:"_",1:pDOMSubs_","">@"""),.pNSContext,pFormat)
				}
			}
		} else {
			Set tNamespaces=pNamespaces
		}
		Set tHasText=$G(pNSContext(pNSContext("level")-1,"opentext"))
		Set tOpen=$G(pNSContext(pNSContext("level")-1,"open"))
		Kill:tOpen pNSContext(pNSContext("level")-1,"open")
		Set:pFormat'["e" pNSContext(pNSContext("level"),"open")=1
	} Else { Set tElem = "" }
	Set:tReplaceContent pContentSubs=""  ; ignore content node if so marked after fetching attributes
	#; for all child elements we always want the whole enchilada
	If pFormat'["f" Set pFormat=pFormat_"f"
	If pFormat'=$TR(pFormat,"it123456789") { Set tN=+$ZStrip(pFormat,"<E'N"), $P(tTab,$S(pFormat["t":$C(9),1:" "),1+$S(tN:tN,1:4))="" }
	Else { Set tTab="" }
	;Set tOldIndent=tIndent  Set:"/"'=$P(pDOMPath,"full()") tIndent=tIndent_tTab
	Set tOldIndent=tIndent  Set tIndent=tIndent_tTab

	#; Loop over nodes in DOMcache and Content arrays at the subtree root given by pContentSubs and/or pDOMSubs, outputting nodes in order
	Set pNSContext("level")=pNSContext("level")+1
	Set tLevel=pNSContext("level")
	if (tLevel > 0) {
		if pNamespaceFound {
			merge pNSContext(tLevel,"namespaces")=pNSContext(tLevel-1,"namespaces")
		}
	}

	if pDOMSubs'="_" {
		do ..createIndex(pDOMSubs,.Index)
		Set tSC=..domValidateDOMSubs(pDOMPath, pDOMSubs, .Index)
		if $$$ISERR(tSC) goto quitstatus
	}
	Set (tAfterCNode,tCNode,tParentCNode,tRemove,tReplace)=""
	Set (dtyp,ctyp)=""
	Set (kDom)=$S("_"=pDOMSubs:"",1:-1), cNode=-1,(tCHit,tDHit,nFound,tHadContent,tHadText)=0
	if (tSetFirstC) {
		Set ctyp=""
		Set cNode=pContentSubs
		if (pContentSubs = 0) { // magic number
			// for case of pContentSubs=0, this is the magic element which used to exist at index 0
			Set ctyp=$$$xmlELEMENTNODE
		} else {
			try {
				// this may fail if Content Array is empty
				Set ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
			} catch {
			}
		}
	}
	Set tElemName=""
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))
	Set tRootDone=0
	if '$D(@$$$vaContentRef(0)) {
		Set cNode=""
	}
	Set tDoLoop=0
	Set tWasMinusOne=0
	If cNode=-1 {
		Set tDoLoop=1
		; If cNode is -1 set to null so don't have to process value of -1 in inner loop
		Set cNode=""
		Set tWasMinusOne=1
	}
	Set pCount=0 // start at first and walk forward, change made 10-01-2012, pCount is used in outputting namespaces
	kill Count
	if (((""'=kDom)||(""'=cNode)))||(tDoLoop) { 
		do {
			;w !,"tAfterCNode="_tAfterCNode_" tCNode="_tCNode
			Set dok=1
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			// foobar 11-05-2012
			If ((""'=kDom) && (dok) && (tDHit || (($$$domLE(tAfterCNodeNoPlus,tCNode))&&(($e(tAfterCNode)'="+")||($$$domLT(tAfterCNodeNoPlus,tCNode))||(cNode="")))))||tSetFirstC {
				#; Retrieve the next DOM child candidate
				Set tElemIndex=1
				if '$D(Index) {
					Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""  Continue:$g(dtyp)=">Z"
				} else {
					if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
					if iIndex'="",jIndex'="" {
						Set dtyp=$LI(Index(iIndex,jIndex),1)
						Continue:$g(dtyp)=">Z"
						Set kDom=+$LI(Index(iIndex,jIndex),2)
						Set IJSeen(iIndex,jIndex)=""
					} 
					if (jIndex="") {
						if iIndex'="" Set iIndex=$O(Index(iIndex))
						if (iIndex="") {
							Set kDom=""
							Set tSetFirstC=0
						}
						continue
					}
				}
				If kDom="" {
					Set tSetFirstC=0
				}
				If ""'=kDom {
					If ">"'=$E(dtyp),dtyp'="" { ; it's an element node
						Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
						;If $i(Count(tElemName)) ; increment count
						;If tElemIndex'=Count(tElemName) Set tSC=$$$ERROR($$$EnsErrGeneral, "Corrupt DOM pDOMPath="_pDOMPath_" pDOMSubs="_pDOMSubs_" tElemName="_tElemName_" tElemIndex="_tElemIndex_" kDom="_kDom_" Count="_Count(tElemName)) GoTo quitstatus
						Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
						Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
						Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
						Set tReplaceContent=(tReplace="c")
					} Elseif dtyp'="" {
						; text, comment, or processing instruction
						Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">I"""))
						Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","""_kDom_""","">R""")), tRemove=(tReplace>1)
						Set tReplaceContent=(tReplace="c")
					}
				}
			}

			Set doit=1
			if (cNode'=""),'$D(SeenCNode(cNode)),kDom="",tAfterCNode'="" {
				Set tCNode=cNode
				; take a look at it
				Set doit=0
			}
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			if (tCNode'=""),'$D(SeenCNode(tCNode)),tAfterCNode'="",$$$domGE(tAfterCNodeNoPlus,tCNode) {
				Set tCNode=cNode
				; take a look at it
				Set doit=0
			}

			If 'tSetFirstC && (""'=cNode || tWasMinusOne)  && (doit) && (""=kDom || tCHit || (($$$domGE(tAfterCNodeNoPlus,tCNode))&&(tAfterCNode'=""))) {
				#; Retrieve the next Content child candidate
				// Set cNode=$$$domGetNextChild(..%ContentRef,pContentSubs,c)  Quit:""=cNode
				// 01-31-12
				// .8 seconds belw - would be good to speed up 6/11/2012
				//Set cNode=$S(""=pContentSubs:"", 1:$$$domGetNextChild4(..%ContentRef,pContentSubs,cNode))
				if $D(tTopArray) {
					Set cNode=$O(tTopArray(cNode))
				} else {
					//Set cNode=$S(""=pContentSubs:"", 1:$$$domGetNextChild4(..%ContentRef,pContentSubs,cNode))
					if (pContentSubs="") {
						Set cNode=""
					} else {
						if (tContentSubsTypeIsElement) {
							if tWasMinusOne {
								$$$xmlaFirstChild(..%ContentRef,pContentSubs,tChildList,cNode,cNodeDescriptor)
							} else {
								$$$xmlaNextChild(..%ContentRef,pContentSubs,tChildList,cNode,cNodeDescriptor)
							}
						} else {
							Set cNode=""
						}
					}
				}
				Set:(cNode'="") ctyp=$$$xmlGetNodeType(..%ContentRef,cNode)
				If ""'=cNode {
					Set tCNode=cNode
				} 
			}
			; removed process combined text
			$$$ASSERT('tParentCNode||(tParentCNode=pContentSubs))
			Set (tCHit,tDHit)=0
			Set tAfterCNodeNoPlus=$$$domStripPlus1(tAfterCNode)
			// get child list for tCNode
			if tCNode'="",ctyp=$$$xmlELEMENTNODE {
				$$$xmlaGetChildList(..%ContentRef,tCNode,tCNodeChildList,tCNodeDescriptor)
			}

			If $$$domGT(tCNode,tAfterCNodeNoPlus) {
				;If ""=tAfterCNode||(kDom="") {
				;If (((""=tAfterCNode)&&($e(dtyp)=">"))||(kDom="")) {
				If ( (cNode'="" || tWasMinusOne) && (kDom="")) {
					Set tCHit=1
					Set:""'=tCNode SeenCNode(tCNode)=""
				} Else {
					Set tDHit=1
					Set:""'=kDom SeenKNode(kDom)=""
					If $$$xmlELEMENTNODE=ctyp { 
						// 09-29-10, support namespaces
						;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
						if pNamespaceFound {
							Set tElemName=$$$xmlaGetQName(..%ContentRef,tCNodeChildList)
						} else {
							Set tElemName=$$$xmlaGetLocalName(..%ContentRef,tCNodeChildList)
						}
					}
				}
			} ElseIf $$$domEQ(tCNode,tAfterCNode) { ; '+' in tAfterCNode means no match
				Set:(""'=tCNode)||(tAfterCNode="") (tCHit,tDHit)=1
				If tRemove {
					set (tCHit,tDHit)=0
				}
				if tReplaceContent {
					Set tCHit=0
				}
				if tEc,$$$xmlTEXTNODE=ctyp {
					Set tCHit=0
				}
				Set:""'=tCNode SeenCNode(tCNode)=""
				Set:""'=kDom SeenKNode(kDom)=""
			} Else { ; If tCNode<=tAfterCNode
				;If ((""=cNode)&&(tElemName'="")) {
				If (cNode="")||(tSetFirstC) {
					Set tDHit=1
					Set:""'=kDom SeenKNode(kDom)=""
				} ElseIf tCNode'=""||tWasMinusOne {
					Set tCHit=1
					Set:""'=tCNode SeenCNode(tCNode)=""

				} Else {

				}
			}
			If tDHit {
				If ">"'=$E(dtyp),dtyp[">" { ; it's an element node
					Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
					Set tAttrSubs=pDOMSubs_","">"_tElemName_""","_tElemIndex
					Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
					Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
					Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
					Set tReplaceContent=(tReplace="c")
					if (tCHit){
						Set:tCNode'="" cSeen(tCNode)=""
					}
					if kDom'="",'$D(kSeen(kDom)) {
						if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
						// 11-07-11
						Set tSetFirstC=0
						// 11-08-2011
						if 'tEc,tElemName'="/" {
							Set pCount=$i(pCount)
							Set tSC=..domValidate($S(""=pDOMPath:"",1:pDOMPath_tElemName),cNode,$S("_"=pDOMSubs:"_",1:tAttrSubs),pFormat_$s(pDOMPath="/":"",1:tIndent),.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,pNamespaceFound,pCount,.pCachedNamespaces) 
							Quit:$$$ISERR(tSC)
						}
					}
					if kDom'="" Set kSeen(kDom)=""
				} Else {
					if (pDHit),tOldElem'="/" {
						if kDom'="" Set kSeen(kDom)=""
						if kDom'="" {
						}
					}
				}
			} ElseIf tCHit {
				if (tCNode'="") {
					If $$$xmlELEMENTNODE=ctyp { 
						// 09-29-10, support namespaces
						;Set tElemName=$G(@$$$vaContentRef(tCNode)) 
						if (tCNode '= 0) { // magic number, when processing "/" - top element
							if (pNamespaceFound) {
								Set tElemName=$$$xmlaGetQName(..%ContentRef,tCNodeChildList)
							} else {
								Set tElemName=$$$xmlaGetLocalName(..%ContentRef,tCNodeChildList)
							}
						} else {
							Set tElemName=""
						}
					}
				}
				If $$$xmlELEMENTNODE=ctyp { ; it's an element node
					if '$D(cSeen(tCNode)) {
						if $e(pDOMPath,*)'="/" Set pDOMPath=pDOMPath_"/"
						if 'tEc {
							Set pCount=$i(pCount)

							Set tSC=..domValidate($S(""=pDOMPath:"",1:pDOMPath_tElemName),tCNode,$S("_"=pDOMSubs:"_",kDom="":"_",1:pDOMSubs_","_kDom),pFormat_tIndent,.pNSContext,tCHit,tDHit,"",.level,.SeenCNode,.cSeen,pNamespaceFound,pCount,.pCachedNamespaces) 
							Quit:$$$ISERR(tSC)
						}
						if kDom="",tCNode=1 Set tRootDone=1
						Set cSeen(tCNode)=1
						Set SeenCNode(tCNode)=""
					} else {
						Set tSC=$$$OK
					}
				} ElseIf $$$xmlTEXTNODE=ctyp{

				}
			}
			Set tWasMinusOne=0
		} While (((""'=kDom)||(""'=cNode)))&&'tRootDone
	} // end-if
	Kill:tHadText pNSContext(pNSContext("level"),"opentext")
	Kill pNSContext(pNSContext("level"),"namespaces")
	Set pNSContext("level")=pNSContext("level")-1
	;merge pNSContext(pNSContext("level")+1,"namespaces")=pNSContext(pNSContext("level"),"namespaces")
	if pNamespaceFound {
		kill pNSContext(pNSContext("level"),"namespaces")
		merge pNSContext(pNSContext("level"),"namespaces")=tNamespaceNodes	
	}

	if $$$ISERR(tSC) goto quitstatus

	#; Output the element close if called for
	If ""'=tElem {
		Set tOpen=$G(pNSContext(pNSContext("level"),"open"))
		; tOpen -> Neither tHadText nor tHadContent
		; tOpen means we close with a "/>" immediately
		$$$ASSERT('tOpen||'(tHadText||tHadContent))
		If tOpen && (pFormat'["e") {
			Set tClose="/>"
		} Else {
			Set tClose="</"_tElem_">"
			Set tClose=$S(tOpen:">",1:"")_$S('tHadContent||tHadText:"", 1:$S(pFormat["w":$C(13,10)_tOldIndent, pFormat["n":$C(10)_tOldIndent, 1:""))_tClose
			; recognize first-element
		}
		Kill:tOpen pNSContext(pNSContext("level")-1,"open")
	}
quitstatus
	Set level=level-1
	;merge pNSContext=tNSContextSave
	if level = 0 { // only do at top
		if pFormat[$$$OUTPUTSCHEMAINFO {
			Set ..schemaLocation=""
			Set ..noNamespaceSchemaLocation=""
		}
	}
	Quit tSC
}

Method validateDOM(pDOMPath As %String) As %Status [ Internal ]
{
	Set tSC=$$$OK, tFormat=$G(pFormat,..Format)  Set:""=pDOMPath pDOMPath="/"
	Set pIgnoreNamespaces=0
 ;w:1 !,"<br/>domGetValueAt("_pDOMPath_","_tFormat_","_pIgnoreNamespaces_")"
	if pDOMPath="/full()" {
		Set pDOMPath="/"
	}
	if pDOMPath="/" {
		Set:tFormat'["f" tFormat=tFormat_"f"
	}
	;if (pDOMPath="/")||(pDOMPath="/full()") Set pDOMPath="/1/full()",tContentSubs=$$$xmlGetDocumentElement(..%ContentRef)
	If "/full()"=$E(pDOMPath,*+1-$L("/full()"),*) { Set:tFormat'["f" tFormat=tFormat_"f"  Set pDOMPath=$E(pDOMPath,1,*-$L("/full()")) }
	Set tNamespaces=""
	Set:pIgnoreNamespaces tNSContext("ign")=pIgnoreNamespaces
	Set tNamespaces=##class(NamespaceHelper).%New()
	Set tSC=..domParsePath(pDOMPath,"get",.tContentSubs,.tDOMSubs,.tType,.tIndex,.tValue,.tNSContext,.tAfterCNode,.tFinalSubscript,.tInsertDSubs,.tInsertIndex,.tCHit,.tDHit,.dummy1,.textOrdinal,.textAfterCNode,.textSubscript,.tInsertSubscript,.tContentNamespace,tFormat,.tNamespaces,"","","","","","","")  Quit:$$$ISERR(tSC) tSC
	if pDOMPath="/" {
		if ($D(@$$$vaContentRef(0))) { ; is ContentArray empty?
			Set tContentSubs=$$$xmlGetDocumentElement(..%ContentRef),tCHit=1
		}
			
	}
	if pDOMPath="/" {
		Set tDOMSubs=",1"
		Set rootPair=$g(@$$$vaDOMRef(tDOMSubs))
		if (rootPair'="") {
			Set root=$P(rootPair,">")
			if (root="/") { ; we have preceding processing instructions or comments
				Set tContentSubs=0 ; magic number
			}
			Set tDOMSubs=","">"_root_""",1",tDHit=1
			Set tDHit=1
		} else {
			Set tDOMSubs="_",tDHit=0
		}
	}
	Set tNodeTypeRoot=0
	If "/node-type()"=pDOMPath Set tNodeTypeRoot=1
	if tNodeTypeRoot=0,tCHit=0,tDHit=0 Quit $$$ERROR($$$EnsErrGeneral, " Unable to get value from DOM Path, does not exist at DOM Path "_pDOMPath)
	If $Case($E(tType),">":(""'=tValue), "@":1, "":0, :1) {
		Quit tSC
	}
	if pDOMPath'="/" Set:'$D(@$$$vaDOMRef(tDOMSubs)) tDOMSubs="_" ; not needed for Get
	Set tNSContext("level")=0
	Set tNamespaceFound=1
	Set:(""'=tContentSubs)||("_"'=tDOMSubs) tSC=..domValidate(pDOMPath,tContentSubs,tDOMSubs,tFormat,.tNSContext,tCHit,tDHit,tNamespaces,0,,,1,0,.tCachedNamespaces)
	if $g(pFormat)[$$$OUTPUTSCHEMAINFO {
		Set ..schemaLocation=""
		Set ..noNamespaceSchemaLocation=""
	}
	Quit tSC
}

Method domValidateDOMSubs(pDOMPath, pDOMSubs, ByRef Index) As %Status [ Internal ]
{
	Set tSC=$$$OK
	Set (kDom)=$S("_"=pDOMSubs:"",1:-1)	
	Set (iIndex,jIndex)=""
	Set iIndex=$O(Index(iIndex))

	while (kDom'="") {	
		#; Retrieve the next DOM child candidate
		Set tElemIndex=1
		if 1 { ;'$D(Index) {
			Set kDom=$O(@$$$vaDOMRef(pDOMSubs_","""_kDom_""""),1,dtyp)  Set:">"=$E(kDom) kDom=""  Continue:$g(dtyp)=">Z"
		} else {
			if iIndex'="" Set jIndex=$O(Index(iIndex,jIndex))
			if iIndex'="",jIndex'="" {
				Set dtyp=$LI(Index(iIndex,jIndex),1)
				Continue:$g(dtyp)=">Z"
				Set kDom=+$LI(Index(iIndex,jIndex),2)
				Set IJSeen(iIndex,jIndex)=""
			} 
			if (jIndex="") {
				if iIndex'="" Set iIndex=$O(Index(iIndex))
				if (iIndex="") {
					Set kDom=""
					Set tSetFirstC=0
				}
				continue
			}
		}
		If ""'=kDom {
			If ">"'=$E(dtyp),dtyp'="" { ; it's an element node
				Set tElemName=$P(dtyp,">",1), tElemIndex=$P(dtyp,">",2)
				if tElemName[":" {
					// colonized name
					Set prefix=$P(tElemName,":",1)
					If $e(prefix)="$" {
						Set tSC=$$$ERROR($$$EnsErrGeneral, "DOM must not have element name whose prefix starts with '$' pDOMPath="_pDOMPath_" pDOMSubs="_pDOMSubs_" tElemName="_tElemName_" tElemIndex="_tElemIndex_" kDom="_kDom_" prefix="_prefix) Quit
					}
				}
				If $i(Count(tElemName)) ; increment count
				If tElemIndex'=Count(tElemName) Set tSC=$$$ERROR($$$EnsErrGeneral, "Corrupt DOM pDOMPath="_pDOMPath_" pDOMSubs="_pDOMSubs_" tElemName="_tElemName_" tElemIndex="_tElemIndex_" kDom="_kDom_" Count="_Count(tElemName)) Quit
				Set tAfterCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">I"""))
				Set tParentCNode=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">P"""))
				Set tReplace=$G(@$$$vaDOMRef(pDOMSubs_","">"_tElemName_""","_tElemIndex_","">R""")), tRemove=(tReplace>1)
				Set tReplaceContent=(tReplace="c")
			}
		}
	
	}
	quit tSC
}

Method NormalizeElementNamespacePrefix(pElem As %String, ByRef pStatus, pIgnoreNamespaces)
{
	Set pStatus = $$$OK
	Set preParen = $P(pElem,"element(")
	Set postParen = $zstrip($P(pElem,"element(",2),"<>W")
	if postParen'="" {
		Set pElem=postParen
		Set prefix=$P(pElem,":")
		if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
			; prefix is of form $number
			Set prefix="xsd_"_$e(prefix,2,*)
			Set $P(pElem,":")=prefix
		}
		Set pElem=preParen_"element("_pElem
	} elseif pElem[":" {
		Set prefix=$P(pElem,":")
		if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
			if ..DocTypeCategory="",'pIgnoreNamespaces Set pStatus=$$$ERROR($$$EnsErrGeneral, "Namespace prefix cannot be of form $number when DocTypeCategory is null")
			; prefix is of form $number
			Set prefix="xsd_"_$e(prefix,2,*)
			Set $P(pElem,":")=prefix
		}
	}
	;if pElem["$" b:1
	quit pElem
}

Method NormalizeNamespacePrefix(pDOMPath As %String, ByRef pStatus, pIgnoreNamespaces)
{
	Set retDOMPath=""
	Set pStatus=$$$OK
	Set pos=2 For { Quit:'pos  Set oldpos=pos, pos=$F(pDOMPath,"/",oldpos)

		If 'pos { Set tElem=$E(pDOMPath,oldpos,*) }
		Else { Set tElem=$E(pDOMPath,oldpos,pos-2) }
		
		Set preParen = $P(tElem,"(")
		Set postParen = $zstrip($P(tElem,"(",2),"<>W")
		if postParen'="" {
			Set tElem=postParen
			Set prefix=$P(tElem,":")
			if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
				; prefix is of form $number
				Set prefix="xsd_"_$e(prefix,2,*)
				Set $P(tElem,":")=prefix
				Set tElem=preParen_"("_tElem
			}
			
		} elseif tElem[":" {
			Set prefix=$P(tElem,":")
			if $e(prefix)="$",$e(prefix,2,*)=+$e(prefix,2,*) {
				; prefix is of form $number
				Set prefix="xsd_"_$e(prefix,2,*)
				Set $P(tElem,":")=prefix
			}
		}
		Set retDOMPath=retDOMPath_"/"_tElem
	}
	;w !,"pDOMPath="_pDOMPath_" retDOMPath="_retDOMPath
	quit retDOMPath
}

/// Record what namespace declarations have been outputted
Method recordNSPDeclarations(pDeclarations As %String, ByRef pNSContext) [ Internal ]
{
	If pDeclarations'=""{
		#dim oneNSPDefinition
		#dim nspPosition
		#dim nspNamePrefix, nspValue
		For nspPosition = 1:1:$Length(pDeclarations," ") {
			Set oneNSPDefinition = $Piece(pDeclarations," ",nspPosition)
			Set nspNamePrefix=$Piece(oneNSPDefinition,"=")
			If nspNamePrefix'="" {
				Set nspValue=$Piece(oneNSPDefinition,"=",2)
				#; Store without '' wrap
				If $Extract(nspValue)="'" Set nspValue=$Extract(nspValue,2,*-1)
				Set pNSContext("outputted",nspNamePrefix)=nspValue
			}
		}
	}
}

/// For prefixes used at this level check what namespaces have been outputted and create entries if not already outputted
/// pPrefixes tell us prefixes in current level
/// Check if not in the namespace helper objects and not
/// already outputted. Also account for outputting a different value.
/// Build required entries based on pNSContext.
Method addNamespacesNotYetOutputted(pLevel As %Integer, ByRef pPrefixes, pNamespaces As EnsLib.EDI.XML.NamespaceHelper, pSchemaNamespaceDef As EnsLib.EDI.XML.NamespaceHelper, ByRef pNSContext) [ Internal ]
{
	#dim tAlreadyOutputted,tAlreadyOutputtedValue
	#dim tElementNSPName, prefix
	#dim tNSPContextVal = ""
	Set prefix="" For { Set prefix=$O(pPrefixes(prefix)) Quit:prefix=""
		Set tElementNSPName = "xmlns:"_prefix
		If '$Data(pNamespaces.Namespaces(tElementNSPName))&&'$Data(pSchemaNamespaceDef.Namespaces(tElementNSPName)) {
			If $Data(pNSContext(pLevel,"namespaces",tElementNSPName),tNSPContextVal)#2 {
				If '$Data(pNSContext("outputted",tElementNSPName),tAlreadyOutputtedValue)#2 || (tAlreadyOutputtedValue'=tNSPContextVal) {
					Do pNamespaces.addNamespace(tElementNSPName,"'"_tNSPContextVal_"'")
				}
			}
		}
	}
}

Method addCloseTagToPPG(pPPGIndex, pWriteIndex, pCloseTag) [ Internal, Private ]
{
	If $Data(^||ppgVal(pPPGIndex,pWriteIndex)),$L(^||ppgVal(pPPGIndex,pWriteIndex))+$L(pCloseTag)<$$$ppgNODESIZE {
		Set ^||ppgVal(pPPGIndex,pWriteIndex)=^||ppgVal(pPPGIndex,pWriteIndex)_pCloseTag
	} Else {
		Set ^||ppgVal(pPPGIndex,$I(pWriteIndex))=pCloseTag
	}
}

Method removeLastOpenTagFromPPG(pPPGIndex, pWriteIndex, pOpenTagWithPre, pIsCurrentlyOpen) As %Boolean [ Internal, Private ]
{
	#Dim tRemovedOpenTag = 0
	#Dim tTempVal = ""
	#Dim tRemoveOpenWriteIndex = pWriteIndex
	#Dim tRemoveOpenPPGIndex = pPPGIndex
	If '$Data(^||ppgVal(pPPGIndex,pWriteIndex),tTempVal) {
		If (tRemoveOpenWriteIndex=1) {
			Set tRemoveOpenPPGIndex = tRemoveOpenPPGIndex - 1
		} Else {
			Set tRemoveOpenWriteIndex = tRemoveOpenWriteIndex - 1
		}
		Set tTempVal = $Get(^||ppgVal(tRemoveOpenPPGIndex,tRemoveOpenWriteIndex))
	}
	If tTempVal'="" {
		Set tRemovedOpenTag = ..removeLastOpenTagFromString(.tTempVal,pOpenTagWithPre, pIsCurrentlyOpen)
		Set:tRemovedOpenTag ^||ppgVal(tRemoveOpenPPGIndex,tRemoveOpenWriteIndex)=tTempVal
	}
	Quit tRemovedOpenTag
}

Method removeLastOpenTagFromString(ByRef pValue, pOpenTagWithPre, pIsCurrentlyOpen) As %Boolean [ Internal, Private ]
{
	#Dim tRemovedOpenTag = 0
	If $Get(pValue)'="" {
		#Dim tLenOpenVal = $L(pOpenTagWithPre)
		If (pIsCurrentlyOpen&&($E(pValue,*-tLenOpenVal+1,*)=pOpenTagWithPre)) {
			Set $E(pValue,*-tLenOpenVal+1+($E(pOpenTagWithPre,1)=">"),*)=""
			Set tRemovedOpenTag = 1
		} ElseIf ($E(pValue,*-tLenOpenVal,*)=(pOpenTagWithPre_">")) {
			Set $E(pValue,*-tLenOpenVal,*)=""
			Set tRemovedOpenTag = 1
		}
	}
	Quit tRemovedOpenTag
}

}
