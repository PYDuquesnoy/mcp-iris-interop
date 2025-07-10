/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

/// This class encapsulates an XML document stream and provides methods to interrogate and update it
/// Two types of path strings can be used to identify a document node: a 'Property path' that is based in
/// a particular XML schema definition (xsd), irrespective of any particular document instance, or a 'DOM path' that is based in the structure of a particular
/// document irrespective of any XML schema. The DOM Path uses XPATH conventions; it always starts with '/' while a Property Path never does.
Class EnsLib.EDI.XML.Prop Extends EnsLib.EDI.XML.DOM [ System = 4 ]
{

/// The status of attempt to validate document contents against the document structure currently specified in the DocType property, or
/// empty if the document gets updated later or the schema is discarded.
/// Note that the schema validation is not done automatically when a saved document gets opened.
Property SchemaStatus As %Status [ ReadOnly, Transient ];

Property %DocTypeRef As %String(MAXLEN = "") [ Internal, ReadOnly, Transient ];

/* Override as transient from %XML.SAX.EntityResolver */
Property Timeout As %Integer [ Internal, Transient ];

/* Override as transient from %XML.SAX.EntityResolver */
Property SSLConfiguration As %String(MAXLEN = "") [ Internal, Transient ];

/* Internal property set based on CommittedMode() method */
Property InCommittedMode As %Boolean [ InitialExpression = 0, Internal, Transient ];

Method PokeDocType(pDocType As %String) As %Status [ CodeMode = expression ]
{
..DocTypeSet(pDocType)
}

Method DocTypeSet(pDocType As %String) As %Status
{
	Quit:pDocType=..DocType&&$$$ISOK(..SchemaStatus) $$$OK ; nothing is changed
	Set i%DocType=pDocType
	Set i%DocTypeCategory=$P(pDocType,":",1)
	Set i%DocTypeName=$P(pDocType,":",2)
	If ""=pDocType {
		Set i%SchemaStatus="", i%%DocTypeRef=""
	} ElseIf (""=..DocTypeCategory)||(""=..DocTypeName) {
		Set i%%DocTypeRef="", i%SchemaStatus=$$$ERROR($$$EnsErrGeneral,"Badly formed DocType '"_pDocType_"'")
	} Else {
		Set i%SchemaStatus=$$$OK, i%%DocTypeRef=$Name($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"meta"))
		Set:'$D(@..%DocTypeRef) i%%DocTypeRef="", i%SchemaStatus=$$$ERROR($$$EnsErrGeneral,"No document structure found for DocType '"_pDocType_"'")
	}
	/*Set tType=$G($$$vaSchemaGbl(..DocTypeCategory,"<types>",..DocTypeName))
	Set i%%DocTypeRef=$S(""=tType:"",1:$Name($$$vaSchemaGbl(..DocTypeCategory,$P(tType,":",1),$P(tType,":",2),"meta")))
	Set:""=..%DocTypeRef i%SchemaStatus=$$$ERROR($$$EnsErrGeneral,"No document structure found for DocType '"_pDocType_"'")
	*/
	Quit $$$OK
}

/*
	We maintain 3 layers of content: Stored Content, extra DOMCache that modifies it, and PropCache that modifies that.
	DOMCache and PropCache can coexist so long as they are in sync or one of them has priority.
	- DOM  Get : first convert PropCache to DOMCache so they are in sync, then get from DOMCache looking through to stored Content
	- DOM  Set : first convert PropCache to DOMCache and kill PropCache, then set to DOMCache looking through to stored Content
	- Prop Get : get from PropCache if available, otherwise converting to DOMCache and get from DOMCache looking through to stored Content
	- Prop Set : set into PropCache; no need to convert because PropPath is content-independent
	- DocType Set : first convert PropCache to DOMCache, kill PropCache
	Note that a Set with action=Append means an implied Get must be done first.

	Also note that each of these 3 content layers may be either process-local or stored persistently

	For DOM path syntax we offer access to every possible order and content combination of text, elements, attributes, mixed content, etc.
	For Property path syntax it is only possible to get the full content value of any given element. Elements and Attributes are by name only, not
	by order. In the case of multiple sibling elements of the same name, we offer an array syntax to distinguish them but don't control how
	they are intermingled with other elements. Mixed content is supported only for GetValueAt(). For SetValueAt() it is supported in a restricted fashion.
	Action="set"    - replaces all child elements and mixed text content with a single text value. If the type of the element is XML "Any" then the text may contain XML markup that is well formed but not validated against any schema.
	Action="append" - appends the new text to any existing text, ignoring child elements. [Implementation Note: we use a special flag in appended text nodes so that we can ignore DOM content until a later GetValueAt()]
	Action="clear" - clears the local text content but keeps the attribute or element itself and any children of the element
	Action="remove" - removes the given element or attribute completely

	A special provision is offered for XML comments: the # character refers to an array of comment children of the given element.

	Examples:

	PropertyPath:
	  PropA.PropB(4).PropC.Attr1
	DOMPath:
	  /ElemA/ElemB[4]/ElemC/@Attr1

	PropertyPath:
	  PropA.PropB(-).PropC.Attr1
	DOMPath:
	  /ElemA/ElemB[-]/ElemC/@Attr1

	PropertyPath:
	  PropA.PropB(4).type_123.PropC.Attr1  ; contains an artificial 'type' element to disambiguate same-named peer branches with different structures.
	DOMPath:
	  /ElemA/Single/ElemB[4]/ElemC/@Attr1  ; contains a 'Single' element that the schema parser removed because not structurally significant
 
	PropertyPath:
	  PropA.PropB(4).PropC.#
	or
	  PropA.PropB(4).PropC.#(1)

	DOMPath:
	  /ElemA/ElemB[4]/ElemC/comment()
	or
	  /ElemA/ElemB[4]/ElemC/comment()[1]

*/
Method propGetValueAt(Output pValue As %String, pPropPath As %String, pFormat As %String) As %Status [ Internal ]
{
	#; Prop Get : get from PropCache looking through to DOMCache looking through to stored Content array
	Set tSC=$$$OK, pValue=""
	Set tFormat=$G(pFormat,..Format)
	Set tSC=..propParsePath(pPropPath,"get",.tDOMPath,.tCSubs,.tDSubs,.tPSubs,.tRef,.tType,.tIndex,.pValue,.tNSContext,.tDone,tFormat)  Quit:$$$ISERR(tSC) tSC
 	Quit:tFormat'["f"&&tDone||$$$ISERR(tSC) tSC
	Set tNSContext("level")=0, pValue=""
	If ($D(tDOMPath) >= 10) {
		Set:tFormat'["f" tFormat="f"_tFormat
		#; If we have set some value within the sequence, sync before retrieving values
		If ''$D(@$$$vaPropsRef(tPSubs)) {
			Set tSC = ..syncToDOMCache(0,$P(pPropPath,".",1,*-1),,,,,.tNSContext)	Quit:$$$ISERR(tSC)
		}
		Set i = ""
		For {
			Set i = $O(tDOMPath(i),1,tCurrPath)	Quit:(""=i)
			Set tSC = ..domGetValueAt(.tValue,tCurrPath,tFormat)	Quit:$$$ISERR(tSC)
			Set pValue = pValue_tValue
			
		}
		Quit tSC
	}
	Set tData=$D(@$$$vaPropsRef(tPSubs),pValue)
	Set tCHit=$D(@..%ContentRef)&&(""'=tCSubs)&&$$$xmlHasChildNodes(..%ContentRef,tCSubs)
	Set tDHit=($D(@$$$vaDOMRef(tDSubs))>1)
	if tFormat'["f"&&(1=tData)&&'(tDHit||tCHit) {
		Set pValue=$$$CONDXMLESCAPE(tFormat,pValue)
		Quit tSC
	}
	If tData { Set tSC=..syncToDOMCache(0,pPropPath,tDOMPath,tDSubs,tPSubs,tRef,.tNSContext)  Quit:$$$ISERR(tSC) tSC }
	Set:'$D(@$$$vaDOMRef(tDSubs)) tDSubs="_" ; not needed for Get
	#;Add test for choice as first in property path. This is to account for prior to syncToDOMCache
	Quit:(""=tCSubs)&&("_"=tDSubs)&&((",""choice"",")'=$E(tPSubs,1,10)) tSC
	Quit ..domGetValueAt(.pValue,tDOMPath,tFormat)
}

Method propSetValueAt(pValue As %String, pPropPath As %String, pAction As %String = "set", pKey As %String = "") As %Status [ Internal ]
{
	// If index is ~ then get the * count and set index to that plus one.
	#; Prop Set : set into PropCache; no need to convert because PropPath is content-independent
	If pPropPath["()" {
		#; implied iteration
		Set tSC=$$$OK
		Set tFind=$F(pPropPath,"()")
		Set tHead=$E(pPropPath,1,tFind-3), tTail=$E(pPropPath,tFind,*)
		Set k=$P(pKey,","), pKey=$P(pKey,",",2,$L(pKey,","))
		If k { Set tSC=..propSetValueAt(.pValue,tHead_"("_(k)_")"_tTail,pAction,pKey) Quit:$$$ISERR(tSC) }
		Else {
			Set i="" For { Set i=..GetNextIndex(tHead_"()",i)  Quit:""=i
				Set tNewPath=tHead_"("_(i)_")"_tTail
				Set tSC=..propSetValueAt(.pValue,tNewPath,pAction,pKey) Quit:$$$ISERR(tSC)
			}
		}
		Quit tSC
	}
	#; Prop Set : set into PropCache; no need to convert to DOM because PropPath is content-independent
	/*	If InCommittedMode we ought to be using disk but
		defer to any data in local %PropCache property 
		array for safety check 
	*/
	If ('..InCommittedMode || $Data(..%PropCache)) {
		$$$vaInitPropCache
	}
	Set tSC=..propParsePath(pPropPath,"set",.tDOMPath,,,.tPSubs,,,,,.tNSContext)  Quit:$$$ISERR(tSC) tSC
	If $Case(pAction,"setany":1,"appendany":1,:0) { ; insert 'any' raw xml
		Set pAction=$E(pAction,1,*-3)
		Set tSC=..validateAnyXML(pValue)  Quit:$$$ISERR(tSC) tSC
		Set @$$$vaPropsRef(tPSubs_","">Any""")=1 ; mark the content as 'Any' XML
		Set tVal=pValue
	} ElseIf $Case(pAction, "remove":0, "clear":0, :1) {
		#; If value is an XML tree, merge the resulting array structure into the Props array
		Set tSC=..parseValueTree(pValue,.tVal,.tPSubs,.tNSContext)  Quit:$$$ISERR(tSC) tSC
	} Else { Set tVal=pValue }
	If pAction="remove" { Kill @$$$vaPropsRef(tPSubs)  Set @$$$vaPropsRef(tPSubs_","">x""")="r" } ; remove the element or attribute completely
	ElseIf pAction="clear" { Set @$$$vaPropsRef(tPSubs)="",  @$$$vaPropsRef(tPSubs_","">x""")="t" } ; clear the local text content but keep the element or attribute itself and any children
	Else {
		If $D(tVal)>1 {
			If pAction="set" { Kill @$$$vaPropsRef(tPSubs)  Merge @$$$vaPropsRef(tPSubs)=tVal  Set @$$$vaPropsRef(tPSubs_","">x""")="c" } ; set the local content and remove any children
			Else { Quit $$$ERROR($$$EnsErrGeneral,"Unsupported tree-valued SetValueAt() action: '"_pAction_"'") }
		} Else {
			#; If appending, append a text value. Mixed content not supported for append
			Set @$$$vaPropsRef(tPSubs)=tVal
			Set:pAction="append" @$$$vaPropsRef(tPSubs_","">x""")="a"
			Quit:$Case(pAction,"set":0,"append":0,:1) $$$ERROR($$$EnsErrGeneral,"Unsupported SetValueAt() action: '"_pAction_"'")
		}
	}
	Do killsync(tPSubs)
	Quit $$$OK

#; scan up the tree and remove any sync markers that pertain to us. Also put them in on siblings if appropriate.
killsync(subs)
	Set sync=0, nparts=$L(subs,",")  For ipart=0:1:nparts { Set tSub=$P(subs,",",1,ipart)
		Set tSub1=tSub_","">s"""
		If $G(@$$$vaPropsRef(tSub1)) {
			Set sync=1
			Kill @$$$vaPropsRef(tSub1)
			If ipart<nparts {
				#; Set other children now that we've cleared the parent
				Set nextSub=$P(subs,",",ipart+1)
				// JSL4290 - remove subscript indirection
				Set kS="" For { Set kSub=tSub_","""_kS_"""" Set kS=$O(@$$$vaPropsRef(kSub))  Quit:""=kS  Continue:kS=nextSub
					Set kSubSynch=tSub_","""_kS_""","">s"""
					Set @$$$vaPropsRef(kSubSynch)=1
				}
			}
		}
	}
	Quit sync
}

/// Parse a 'Prop' (schema-based) path, constructing both DOM and Property subscript lists that correspond to it, as well as a corresponding DOM path
Method propParsePath(pPropPath As %String, pMode As %String, Output pDOMPath As %String, Output pCSubs As %String = "", Output pDSubs As %String = "", Output pPSubs As %String, Output pRef As %String, Output pNodeType As %String, Output pNodeIndex As %String, Output pNodeValue As %String, Output pNSContext As %String, Output pDone As %Boolean, pFormat As %String = "") As %Status [ Internal ]
{
	#; This method returns pDone=1 unless there is complex content under the specified node
	#; It looks all the way through for count and local text or attribute values
 	Set (pCSubs,pPSubs,pDSubs,pDOMPath,pNodeType,pNodeIndex,pNodeValue)="", pDone=0
	Quit:..DocType'[":" $$$ERROR($$$EnsErrGeneral,"Can't evaluate property path because DocType "_..DocType_" is not set")
	Quit:""=..%DocTypeRef $$$ERROR($$$EnsErrGeneral,"Can't evaluate property path because no schema structure is loaded for DocType '"_..DocType_"'")

 	Set tSC=$$$OK
	Set tRef=$Name($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"meta"))

	Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tRef)
	#; look in DOM for top element name
	#; Set tTopName=$O(@$$$vaDOMRef(","">"""))
	#; the top is now always "/"
	Set tTopName=""
	; '>' collates higher than numbers
	Set kDom=">"  For { Set kDom=$O(@$$$vaDOMRef(","">/"",1,"_""""_kDom_""""),-1,dtyp)  Quit:""=kDom
		Set:$D(dtyp)&&($E(dtyp)'=">") tTopName=">"_$P(dtyp,">")
	}
	
	#; if not found in DOM - must look to Content
	If ">"'=$E(tTopName) {
		Set tPrefixTopName=""
		If $$$domGetLocalName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))'="",$$$domGetQName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))[":" {
			Set tContentUri=$$$xmlGetNamespaceURI(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))
			; look up URI in schema
			Set index="" For {  Set index=$O($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index))  Quit:""=index
				Set tSchemaUri=$G($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index,"uri"))
				Set:tSchemaUri=tContentUri tPrefixTopName="$"_index_":"
			}
		}
	}
	Set:">"'=$E(tTopName) tTopName=">"_tPrefixTopName_$$$domGetLocalName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))
	#; if found in DOM or Content - use it, otherwise stick with schema name
	Set:">"'=tTopName $P(tDName,"/")=$E(tTopName,2,*)
	Set pDOMPath="/"_tDName
	Set pDSubs=","">/"",1,"">"_$$replace^EnsUtil(tDName,"/",""",1,"">", "[~]","")_""",1"
	Set ttRef=$S($G(@tRef)||'($D(@tRef@("type"),tType)#2):"", 1:##class(EnsLib.EDI.XML.Schema).getTypeRef($P(..DocType,":"),tType,.tSC1))

	Set (tRep,tSubs,tName,tIsAttr,tIsParent)=""
	For i=1:1 {
		Quit:$L(pPropPath,".")<i
		Kill tChoiceIndex
		Set tName = $P(pPropPath,".",i)
		If ""=tName {
			Set:""'=pPropPath tSC=$$$ERROR($$$EnsErrGeneral,"Incomplete property path '"_pPropPath_"'")
			Quit
		}
		Set tIndex=$P(tName,"(",2,*)
		If ""'=tIndex {
			Set tName=$E(tName,1,*-1-$L(tIndex))
			If ")"'=$E(tIndex,*) Set tSC=$$$ERROR($$$EnsErrGeneral,"Unbalanced parentheses in component '"_tName_tIndex_"' of property path '"_pPropPath_"'")  Quit
			Set tIndex=$E(tIndex,1,*-1)
		}

		Set:""'=ttRef tRef=ttRef
		Set tParentIsRepeatingSequence = $G(tIsRepeatingSequence)
		Set tIsRepeatingSequence=0
		If tName="*" {
			Set tSC=..propGetCount(.pNodeValue,pPropPath,pDOMPath,pDSubs,pPSubs,tRef,.pNSContext)  Quit:$$$ISERR(tSC)
			Set pNodeType="ordinal", pDone=1
			Quit
		} ElseIf tName="#" {
			Set pNodeType="comment", tPropName="#()", tDName="comment()["_tIndex_"]"
			Set tRep=1, tIsAttr=0, tIsElem=0, tRef="_"
		} Else {
			If (tName = "") Set tSC=$$$ERROR($$$EnsErrGeneral,"Invalid property path syntax '"_$P(pPropPath,".",1,i)_"'")  Quit
			If '$D(@tRef@("pnames",tName),iProp) Set tSC=$$$ERROR($$$EnsErrGeneral,"Property path name '"_$P(pPropPath,".",1,i)_"' not found in XML schema '"_..DocType_"'")  Quit
			Set tRef=$Name(@tRef@(iProp))
			If '$D(@tRef@("name"),tPropName) Set tSC=$$$ERROR($$$EnsErrGeneral,"Property path '"_$P(pPropPath,".",1,i)_"' not found in XML schema '"_..DocType_"'")  Quit
			Set ttRef=$S('($D(@tRef@("type"),tType)#2)||$G(@tRef):"", 1:##class(EnsLib.EDI.XML.Schema).getTypeRef($P(..DocType,":"),tType,.tSC1))
			Set tRep=("()"=$E(tPropName,*-1,*))||(""'=$G(tParentIndex))
			Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tRef)
			Set tIsSequence = "sequence"=$P(@tRef@("xtype"),":",*)
			
			/*
				Account for schema definition where we remove top DOM name from each choice element
				because we are using an anonymous repeating element designator.
				Schema information in d+ node.
				If in repeating choice and tDName is empty then tDName will be updated
				in the last $Data operation examing d+ node.
			*/
			If $G(tIsRepeatingChoice) && (tDName="") && $Data(@tRef@("d+"),tDName)#2 {
				Set tAnonymousRepeating = 1
			} ElseIf (tDName="") && (tIndex'="") && tIsSequence && $D(@tRef@("d"),tDName)#2 {
				Set tAnonymousRepeating = 1
				Set tIsRepeatingSequence = 1
			} Else {
				Set tAnonymousRepeating = 0
			}
			
			Set tIsAttr=$D(@tRef@("a"))
			Set tIsElem=(""'=tDName&&'tIsAttr)
			Set tIsContent=$G(@tRef@("c"))
			Set:tDName["["&&($P(tDName,"[")="") tDName="" ; when no tDName except [n] - make it null
			If ""'=$G(tParentIndex) {
				Set tIndex = tParentIndex
				Set tIsParent=0
				If $Case(tPropName,"choice":1,"choice()":1,:0) {
					Set tPropName = "choice()"
				} Elseif tPropName=$G(tChildName) {
					Set tDName = "[]"
				} Elseif 'tAnonymousRepeating && 'tParentIsRepeatingSequence {
					#;Anonymous repeating: Accept as is.
					Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Element '%1' not found at path '%2'."),tPropName,$P(pPropPath,".",1,i-1)))
					Quit
				}
			}
			Set tIsGroup = ("CG"=$P($G(tType),":"))&&("group"=$P($G(@tRef@("xtype")),":",*))
			#; group name not included in DOM path
			Set:(("CG"=$P($G(tType),":"))&&(tIsGroup||("attributeGroup"=$P($G(@tRef@("xtype")),":",*)))) tDName=""
			Set:""=tIsContent&&$L(ttRef) tIsContent=$G(@ttRef@("c"))
			If tIsContent&&(i<$L(pPropPath,"."))&&($G(@$S($L(ttRef):ttRef,1:tRef)@(tIsContent,"name"))=$P(pPropPath,".",i+1)) {
				#; Remove simpleContent Value or mixed Content MixedValue property from the path if present
				Set pPropPath = $P(pPropPath,".",1,i)_$S(($L(pPropPath,".")>(i+1)):"."_$P(pPropPath,".",i+2,*),1:"")
			}
			#;Anonymous repeating: Record whether preceding was a repeating choice before tIsRepeatingChoice is overwritten 
			Set tPrecedingWasRepeatingChoice=$G(tIsRepeatingChoice,0)
			
			Set tIsRepeatingChoice=(tDName="") && ((tPropName="choice()")||(tPropName?1"choice_"1.N0.1(1"("0.N1")")))
			$$$ASSERTNOLOG('(tRep&&((""=tDName) && ('(tIsSequence||tIsRepeatingChoice)&&'tIsGroup)))) ; choice() has rep but no DName. Rep data can come from attribute
			
			/*
				Anonymous repeating:
				Need to calculate index to insert and record in tChoiceIndex to use later. E.G.
				
				pPSubs=","messages","choice","1""
				pPropPath=messages.choice(1).SC.creditor.principal
				i=3
				$Piece(pPropPath,".",i-1) =choice(1)
				So tChoiceIndex becomes 1
				or
				pPSubs=","messages","choice","2""
				pPropPath=messages.choice(2).SC.creditor.principal
				i=3
				$Piece(pPropPath,".",i-1) =choice(2)
				So tChoiceIndex becomes 2
			*/
			If tPrecedingWasRepeatingChoice && (i>1) && 'tIsRepeatingChoice && (tDName["[]")  {
				Set tPrecedingName=$Piece(pPropPath,".",(i-1))
				If tPrecedingName["choice(" {
					Set tChoiceIndex = $Piece($Piece(tPrecedingName,"(",2),")",1)
					If +tChoiceIndex'=tChoiceIndex Kill tChoiceIndex
				}
			}
			
		}
		If (""'=tIndex) {
			If 'tRep Set tSC=$$$ERROR($$$EnsErrGeneral,"Collection path '"_$P(pPropPath,".",1,i)_"' given for non-collection property '"_tPropName_"' in XML schema '"_..DocType_"'")  Quit
			If 'tIsGroup {
				If (tIndex="*") || (tIndex="""*""") || ($E(tIndex)="-") {
					#; Special handling required for sequence, groups and repeating choice because ^EnsEDI.XML.Content knowns nothing about them - only their children
					If tIsRepeatingChoice {
						Set tSC=..choiceGetCount(.tCount,pDOMPath,tRef)  Quit:$$$ISERR(tSC)
					} ElseIf tIsRepeatingSequence {
						Set tSC=..sequenceGetCount(.tCount,pDOMPath,tRef,pPSubs)	Quit:$$$ISERR(tSC)
					} Else {
						Set tSC=..propGetCount(.tCount,$E(pPropPath,1,*-2-$L(tIndex)),pDOMPath_"/"_tDName,pDSubs,pPSubs_","""_tName_"""",tRef,.pNSContext)  Quit:$$$ISERR(tSC)
					}
					If (tIndex="*") || (tIndex="""*""") {
						Set pNodeValue=tCount, pNodeType="ordinal", pDone=1
						Quit
					}
					#; substitute literal count into index expression
					Set tIndex=$Replace(tIndex,"--",tCount_"@")
					Set tIndex=$Replace(tIndex,"- -",tCount_" @")
					Set tIndex=$Replace(tIndex,"-",tCount)
					Set tIndex=$Tr(tIndex,"@","-")
				} Else { Set tCount="" }
				#; Evaluate index expression
				Try {
					New %i
					X "Set %i="_tIndex
					Set tIndex=%i  Kill %i
				} Catch errobj { Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to evaluate index expression '"_tIndex_"' in property path '"_pPropPath_"' : "_errobj.AsSystemError())  Quit }
				If tIsRepeatingChoice&&("get"=pMode) {
					// add number of children before choice() to index as parentIndex
					Set:'$D(tParentIndex) tIsParent=1
					Set tSC = ..choiceGetIndex(tIndex,pPropPath,pDOMPath,tRef,.tParentIndex,.tChildName)
					if $L(pPropPath,".")=i {
						Set pPropPath = pPropPath_"."_tChildName
						Set pFormat=pFormat_"f"
					}
					Quit:$$$ISERR(tSC)
				} ElseIf (tIsSequence) {
					If tIsRepeatingSequence {
						Set tParentIndex=tIndex
					}
					Set tIsParent=1
					If $L(pPropPath,".")=i {
						#; Last element in the Property Path is 'sequence' - this doesn't have a corresponding DOM path
						If ("get"=pMode) {
							Set pFormat=pFormat_"f"
							#; If only one child element, just add it to property path and continue
							#; Otherwise we need to find each child separately and put the pieces back together
							If (0=+$O(@tRef@(1))) {
								Set pFormat=pFormat_"f"
								Set tChildName = $O(@tRef@("pnames",""))
								Set pPropPath = pPropPath_"."_tChildName
							} Else {
 								Set (pCSubs,pDSubs,pNodeType,pNodeIndex,pNodeValue)=""
 								Set pDone=0
 								Set tChildCount = 0
								Set tChildName = ""
								For {
									Set tChildName = $O(@tRef@("pnames",tChildName))	Quit:tChildName=""
									Set tSC = ..propParsePath(pPropPath_"."_tChildName,pMode,.tChildDOM)
									Quit:$$$ISERR(tSC)
									Set pDOMPath($I(tChildCount))=tChildDOM
								}
								Quit
							}
						} Else {
							Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to set a value into a sequence.  Try setting each individual child element instead.") 
						}
					}
					
				}
			} ElseIf ("get"=pMode) {
				Set:'$D(tParentIndex) tIsParent=1
				Set tParentIndex=tIndex
				If $L(pPropPath,".")=i {
					#; This is the end of the Property Path
					If $D(@tRef@(1,"xtype"),tChildXType) && (0=+$O(@tRef@(1))) {  ; The group only has one child
						If ("choice"=tChildXType) { ; The group's child is choice
							Set pPropPath = pPropPath_".choice"
						} ElseIf tIsSequence {
							#; Add the child to the property path and continue - there should be a corresponding DOM path for this new Property Path
							Set pFormat=pFormat_"f"
							Set tChildName = $O(@tRef@("pnames",""))
							Set pPropPath = pPropPath_"."_tChildName
						}
					} ElseIf tIsSequence {
						#; Find each child separately - we will put the pieces back together after returning to propGetValueAt
 						Set (pCSubs,pDSubs,pNodeType,pNodeIndex,pNodeValue)="", pDone=0
						Set tChildCount = 0
						Set tChildName = ""
						For {
							Set tChildName = $O(@tRef@("pnames",tChildName))	Quit:tChildName=""
							Set tSC = ..propParsePath(pPropPath_"."_tChildName,pMode,.tChildDOM)
							Quit:$$$ISERR(tSC)
							Set pDOMPath($I(tChildCount))=tChildDOM
						}
						Quit						
					} 
				}
			}
		} Else {
			Set:tRep tIndex=1, tCount=""
		}
		$$$ASSERTNOLOG(tName=$P(tPropName,"("))
		If tIndex>0&&(""=tCount) {
			set tIndex=$$indexPastRemoved(tIndex,$$$vaPropsRef(pPSubs_","""_tName_""","))
			#; Anonymous repeating: Remove since not valid
			Kill tChoiceIndex
		}
		#; Construct pPSubs and pDOMPath
		Set pPSubs=pPSubs_","""_tName_$S(""=tIndex||((""'=$G(tParentIndex))&&('tIsParent)):"",1:""","""_tIndex)_""""
		If ""'=tDName {
			#; Anonymous repeating: If we have tChoiceIndex defined then we use that 
			if $Data(tChoiceIndex)#2 {
				Set pDOMPath=pDOMPath_"/"_..insertIndex(tDName,tChoiceIndex)
			} Else {
				Set pDOMPath=pDOMPath_"/"_..insertIndex(tDName,tIndex)
			}
			Kill tParentIndex
			Set pNodeType=">"_$P(tDName,"/",$L(tDName,"/"))
			Quit:tIsAttr ; attribute must be leaf
		}
	} ; end path pieces loop
	Set pRef=tRef
 	Set:$$$ISERR(tSC) pPSubs=""

	Quit:$$$ISERR(tSC)||pDone||("set"=pMode)||($D(pDOMPath)>=10) tSC ; for 'set's we never need the DOM stuff, for multiple DOM paths it is not useful
	$$$ASSERTNOLOG('tIsAttr||'$G(@tRef)) ; attribute must be leaf
	Set tNoElemChildren=((tRef="_")||'$G(@tRef))&&((ttRef="")||'$G(@ttRef))
	If 'tNoElemChildren {
		#; check tRef and ttRef to see if we can find any child elements before assuming there are none
		Set tFound=0  For iChild=@tRef:-1:1 {
			If $G(@tRef@(iChild,"e"))||$G(@tRef@(iChild)) Set tFound=1  Quit
		}
		If 'tFound && (ttRef'="") {
			For iChild=@ttRef:-1:1 {
				If $G(@ttRef@(iChild,"e"))||$G(@ttRef@(iChild)) Set tFound=1  Quit		}
		}
		Set:'tFound tNoElemChildren=1
	}
	If tNoElemChildren||'$D(@$$$vaPropsRef(pPSubs),pNodeValue) {
		#; no non-attribute children, or comment, or no PropsRef value, so it's a simple value or a DOM value and if it's not defined in PropsRef we must try to get it from DOMPath
		If '$D(@$$$vaPropsRef(pPSubs),pNodeValue) {
			Set tSC=..domParsePath(pDOMPath,"get",.pCSubs,.pDSubs,.pNodeType,.pNodeIndex,.pNodeValue,.pNSContext,.tAfterCNode,.ISubscript,.tInsertDSubs,,.tCHit,.tDHit,.dummy1,.textOrdinal,.textAfterCNode,.textSubscript,,,pFormat)  Quit:$$$ISERR(tSC) tSC
			Quit:'tCHit&&'tDHit $$$ERROR($$$EnsErrGeneral, "No value found at Prop Path '"_pPropPath_"' / DOM Path '"_pDOMPath_"'")
			//Set:$Case($E(pNodeType),">":(""'=pNodeValue), "@":1, "":0, :1) pDone=1
			If $Case($E(pNodeType),">":(""'=pNodeValue), "@":1, "":0, :1) Set pDone=1  Quit tSC
			Set pNSContext("level")=0
			; we have a schema, and we are dealing with properties, so we want prefixes to be declared
			; hence the "u" format flag
			; if no property array then we need to get value from domGetSubtree
			Set:(""'=pCSubs)||$D(@$$$vaDOMRef(pDSubs)) tSC=..domGetSubtree(.pNodeValue,pDOMPath,pCSubs,pDSubs,"u"_pFormat,.pNSContext,tCHit,tDHit)
		} else {
			Set pNodeValue=$$$CONDXMLESCAPE(pFormat,pNodeValue)
		}
		Set pDone=1
	}
	Quit tSC

 #; linear scan for removed indices before the given index, bumping up the given index to skip over them
indexPastRemoved(idx,ref)
	Set oidx="",rcnt=0  For { Set oidx=$O(@($E(ref,1,*-1)_""""_oidx_""")"))  Quit:""=oidx
		If "r"'=$G(@($E(ref,1,*-1)_""""_oidx_""","">x"")")) { Quit:idx+rcnt>=oidx }
		Else { Set rcnt=rcnt+1 }
	}
	Quit idx+rcnt
}

/// Drill from the start to the end of pDSubs path, accumulating the Namespace context to the end level
Method initNSContext(pDSubs As %String, ByRef pNSContext) As %Status [ Internal ]
{
	Set tSC=$$$OK, pNSContext="", tLevel=0, pNSContext("level")=tLevel
	Set pos=2 For { Set pos=$F(pDSubs,",",pos)  Set:pos pos=$F(pDSubs,",",pos)
		Set pDPart=$S(pos:$E(pDSubs,1,pos-2),1:$E(pDSubs,1,*))
		Set tNamespaces=##class(NamespaceHelper).%New()
		Set tSC=..domGetNamespaces(tNamespaces,0,pDPart_","">@""",.pNSContext)  Quit:$$$ISERR(tSC)
		Quit:'pos
		Set pNSContext("level")=$I(tLevel)
		Merge pNSContext(tLevel,"namespaces")=pNSContext(tLevel-1,"namespaces")
	}
	Quit tSC
}

Method propGetCount(Output pCount, pPropPath As %String, pDOMPath As %String, pDSubs As %String, pPSubs As %String, pRef As %String, ByRef pNSContext) As %Status [ Internal ]
{
	If $Data(@$$$vaPropsRef(pPSubs)) {
			#; Use pDSubs and not ","">/"",1"
			Set tSC=..initNSContext(pDSubs,.tNSContext)
			If $$$ISERR(tSC) Quit tSC
	}
	Set tSC=..syncToDOMCache(0,pPropPath,pDOMPath,pDSubs,pPSubs,pRef,.tNSContext)  Quit:$$$ISERR(tSC) tSC
	Set tPath=$E(pDOMPath,1,*+1-$F($Reverse(pDOMPath),"["))
	Set pCount=0
	Set tSC=..domGetValueAt(.pCount,tPath_".*")
	Set:'+pCount pCount=0 ; if not found, count is 0
	; ignore a bad Status
	Quit $$$OK
}

Method sequenceGetCount(Output pCount, pDOMPath As %String, pRef As %String, pPSubs As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	Set pCount = 0
	#dim tElemList As %String = ""
	#dim tElem,tElemName,cNode,tCSubs,tSub As %String = ""
	#dim tPSubs As %String = pPSubs
	#dim tPos, tNewPos As %Integer = 0 ; Keep track of where we are within the sequence
	#dim tFound As %Boolean = 0 ; Have we found the repeating sequence?
	

	Set tSC=..domParsePath(pDOMPath,"get",.tCSubs) Quit:$$$ISERR(tSC)
	If (""'=tCSubs) {
		#; First get a list of the elements within the sequence
		For {
			Set tElem = $O(@pRef@("pnames",tElem),1,tPos)  Quit:tElem=""
			Set tElemList = tElemList_$lb(tElem)
		}
		#; Count occurrences of the sequence
		For {
			Set cNode=$$$domGetNextChild(..%ContentRef,tCSubs,cNode)  Quit:""=cNode
			Set tElemName=$$$domGetQName(..%ContentRef,cNode)
			Set:(tElemName[":") tElemName = $P(tElemName,":",2)
			#; Start looking where we left off - if later in this list and tPos not 0, then we're in the same sequence as before
			Set tNewPos = $LF(tElemList,tElemName,tPos)
			If tNewPos {
				If 'tFound {
					#; Start of the sequence
					Set pCount = 1
					Set tFound = 1
				}
				#; Adjust tPos to look after this element next time
				Set tPos = tNewPos
			} Else {
				#; Start over from the beginning of the sequence to see if we're in a new repetition or have exited the sequence
				Set tPos = $LF(tElemList,tElemName,0)
				If tPos {
					Do $I(pCount)
				} ElseIf tFound {
					#; We've found a child that appears after sequence()
					Quit
				}
			}
		}
	} ElseIf ''$D(@$$$vaPropsRef(tPSubs)) {
		If ($P(tPSubs,",",*)'="""sequence""") {
			Set tPSubs = tPSubs_",""sequence"""
		}
		Set pCount = $O(@$$$vaPropsRef(tPSubs_","""""),-1)
	}
	Quit tSC
}

/// Get count of the elements inside a repeating choice() element.
/// This is more tricky than for normal elements because choice excluded from DOM path
Method choiceGetCount(Output pCount, pDOMPath As %String, pRef As %String) As %Status
{
	Set tSC = $$$OK
	Set tElemList = ""
	Set tElem = ""
	For {
		Set tElem = $O(@pRef@("pnames",tElem))  Quit:tElem=""
		Set tElemList = tElemList_$lb(tElem)
	}
	Set tSC=..domParsePath(pDOMPath,"get",.tCSubs) Quit:$$$ISERR(tSC)
	Set pCount = 0
	Set tFound = 0 ; are we in the repeating choice?
	Set cNode=""
	For {
		Set cNode=$S(""=tCSubs:"", 1:$$$domGetNextChild(..%ContentRef,tCSubs,cNode))  Quit:""=cNode
		Set tElemName=$$$domGetQName(..%ContentRef,cNode)
		Set:(tElemName[":") tElemName = $P(tElemName,":",2)
		If $LF(tElemList,tElemName) {
			Set tFound=1
			Set pCount = pCount+1
		} Else {
			Quit:tFound ; we've found a child that appears after choice()
		}
	}
	Quit tSC
}

/// Since choice() does not appear in the DOM path we must figure out which index <var>pDOMIndex</var> within the parent of choice()
/// corresponds to the index <var>pGrpIndex</var> within choice().  We find the name <var>pElemName</var> of the element at this
/// index so that we will know whether the name at this index matches that used in the property path <var>pPropPath</var> 
Method choiceGetIndex(pGrpIndex As %Integer, pPropPath As %String, pDOMPath As %String, pRef As %String, Output pDOMIndex As %Integer, Output pElemName As %String) As %Status
{
	Set tSC = $$$OK
	Set pDOMIndex = 0 ; index within the DOM

	Set tElemList = ""
	Set tElem = ""
	For {
		Set tElem = $O(@pRef@("pnames",tElem))  Quit:tElem=""
		Set tElemList = tElemList_$lb(tElem)
	}

	Set tSC=..domParsePath(pDOMPath,"get",.tCSubs)
	/*
		choice() is at the start of the pPropPath it is possible that reported as unknown.
		Similar check as in setDOMNode()
	*/
	If $$$ISERR(tSC) && ($E(pPropPath,1,7)="choice(") {
		#dim tSCErrorText = $system.Status.GetErrorText(tSC)
		If (tSCErrorText["is a 'unknown' node") || (tSCErrorText["requesting element at non-") {
			Set tSC=$$$OK
		} Else {
			Quit tSC
		}
	}
	Set tGrpIndex = 0 ; index within the repeating choice
	Set tFound = 0 ; are we in the repeating choice?
	Set cNode=""
	For {
		Set cNode=$S(""=tCSubs:"", 1:$$$domGetNextChild(..%ContentRef,tCSubs,cNode))
		If ""=cNode {
			If tFound { ; We never hit the index, but did find children in choice
				Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Index %1 out of range for property path %2"),pGrpIndex,pPropPath))
				Quit
			} Else {
				#; Only report an error if the document created from an XML string/stream
				If ..%ContentRef'="%null(0)" Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("No element found at property path %2"),pGrpIndex,pPropPath))
				Quit
			}
		}
		Set tElemName=$$$domGetQName(..%ContentRef,cNode)
		Set:(tElemName[":") tElemName = $P(tElemName,":",2)
		Set pDOMIndex = pDOMIndex + 1
		If $LF(tElemList,tElemName) {
			Set tFound=1
			Set tGrpIndex = tGrpIndex+1
			Quit:(tGrpIndex=pGrpIndex)
		} Else {
			If tFound { ; We haven't hit the index yet, but we've found a child that appears after choice()
				Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Index %1 out of range for property path %2"),pGrpIndex,pPropPath))
				Quit
			}
		}
	}
	Set pElemName = $G(tElemName)
	Quit tSC
}

/// Gets the next index in a collection
Method GetNextIndex(pPath As %String, pIndex As %String, ByRef pStatus As %Status = {$$$OK}) As %String [ Internal ]
{
	Set pStatus=$$$OK
	Set f=$F(pPath,"()")  If 'f Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't iterate on Property Path '"_pPath_"'") Quit ""
	If '$D(..%CalcCache(pPath)) {
		Set tCount=..GetValueAt($E(pPath,1,f-3)_"(*)","",.pStatus)
		If $$$ISOK(pStatus) {
			Set ..%CalcCache(pPath)=tCount
		} 
	} Else {
		Set tCount=..%CalcCache(pPath)
	}
	Quit $S(+pIndex<tCount:pIndex+1, 1:"")
}

Method validateAnyXML(pXMLVal As %String) As %Status [ Internal ]
{
	#; Based on ReadString()
	Quit ##class(%XML.SAX.Parser).ParseString("<pseudoRoot>"_pXMLVal_"</pseudoRoot>",$this,,,$$$SAXFATALERROR) ; mask to only get errors
}

/// Validate the input pValue, and if it contains XML elements parse them into a PropsArray style array structure rooted at pPropSubs in the Props array
Method parseValueTree(pValue As %String, Output tVal, pPropSubs As %String, ByRef pNSContext) As %Status [ Internal ]
{
	Kill tVal  Set tVal=pValue
	Quit $$$OK
}

/// Get Props array value based on given DOM path if possible. If not then return the subscripts for the most specific property path within which the given DOM path is encompassed and syncing is required
Method propGetDOMPathValue(ByRef pDOMPath, Output pPropPath, Output pValue, Output pDSubs, Output pPSubs, ByRef pSchemaRef As %String = "", ByRef pNSContext, Output pStatus As %Status) As %Boolean [ Internal ]
{
	Set (pPropPath,pPSubs,pDSubs,pSchemaRef)="", pStatus=$$$OK
	If $E(pDOMPath)'="/" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of invalid format")  Quit 0
	If ((""=..DocTypeCategory)||(""=..DocTypeName)) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't convert DOM path '"_pDOMPath_"' to property path because of invalid DocType:'"_..DocType_"'")  Quit 0
	Set tRef=$Name($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"meta"))
	If '$D(@tRef) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't convert DOM path '"_pDOMPath_"' to property path because Schema:'"_..DocType_"' is not loaded")  Quit 0

	Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tRef)
	#; look in DOM for top element name
	Set tTopName=">"_$P($G(@$$$vaDOMRef(","">/"",1,1")),">")
	#; if not found in DOM - must look to Content
	Set:">"=tTopName tTopName=">"_$Case($E(..%ContentRef,1,$L("%null(0")), "":"", "%null(0":"", :$$$xmlGetQName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef)))
	#; if found in DOM or Content - use it, otherwise stick with schema name
	Set:">"'=tTopName $P(tDName,"/")=$E(tTopName,2,*)
	Set tDPath="/"_tDName
	Set pDSubs=","">/"",1,"">"_$Replace(tDName,"/",""",1,"">")_""",1"

	Set tSC=..initNSContext(pDSubs,.pNSContext)
	
	Set (tElem,tDOMElem)=""
	Set tFinal=0,pos=2,pieceIndex=0,tLastElem=0
	For {
		Quit:'pos||tLastElem
		Set oldpos=pos, pos=$F(pDOMPath,"/",oldpos)
		Set pieceIndex=pieceIndex+1
		Continue:pieceIndex=1 ; first piece of DOM path is irrelevant
		
		#; Find the proper element and index from the current piece of the DOM path
		If 'pos { Set tElem=$E(pDOMPath,oldpos,$L(pDOMPath)) }
		Else { Set tElem=$E(pDOMPath,oldpos,pos-2) }
		Set tLastElem='pos

		If (""=tElem) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of implied iteration in 'get' mode: '//'")  Quit
		
		Set tIndexed=(tElem["[")||(tElem=1)
		If pos {
			Set newpos=$F(pDOMPath,"/",pos)
			If 'newpos { Set tNextElem=$E(pDOMPath,pos,*) }
			Else { Set tNextElem=$E(pDOMPath,pos,newpos-2) }
		} Else {
			Set tNextElem=""
		}
		Set pStatus=..domParsePathElem(pDOMPath,.tElem,tNextElem,"get",.tIndex,.tNode,.tInsert,.tFinal)  Quit:$$$ISERR(pStatus)
		Set:'tIndexed tIndexed=(tIndex'=1)
		If tFinal&&'tLastElem Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of extra element after function '"_tElem_"'")  Quit
		Set tIsAttr=0
		Set:"@"=$E(tElem) tIsAttr=1, tElem=$E(tElem,2,*)
		If tIsAttr&&tFinal&&'tLastElem Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't evaluate DOM path '"_pDOMPath_"' because of extra element after function '"_tElem_"'")  Quit
		Set tDOMElem=tDOMElem_tElem

		#; Look for schema property matching this piece of DOM path
		If '$G(@tRef)&&($D(@tRef@("type"),tType)#2) {
			Set ttRef=##class(EnsLib.EDI.XML.Schema).getTypeRef($P(..DocType,":"),tType,.tSC1)
			Set:""'=ttRef tRef=ttRef
		}
		Set tPartial=0
		If ""'=tDOMElem {
			Set iProp=$G(@tRef@("dnames",tDOMElem),$S(tIndex:$G(@tRef@("dnames",tDOMElem_"[]")),1:""))
			If 'iProp {
				// give preference to partial dname over pnames if element not last element
				Set:(pos&&'tLastElem) tPartial=(""'=$O(@tRef@("dnames",tDOMElem)))
				If 'tPartial {
					Set iProp = $G(@tRef@("pnames",tDOMElem))
					Quit:""=iProp
				}
				Else {
					Set tDOMElem=tDOMElem_"/"
				}
			}
			If iProp {
				#; Got a hit
				Set tRef=$Name(@tRef@(iProp))
				If '$D(@tRef@("name"),tPropName) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Property path '"_pPropPath_"' not found in XML schema '"_..DocType_"'")  Quit
				Set tRep=("()"=$E(tPropName,*-1,*))
				Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tRef)
				Set tIsAttr=$D(@tRef@("a"))
				Set tIsElem=(""'=tDName&&'tIsAttr)
				$$$ASSERTNOLOG('(tRep&&(""=tDName||tIsAttr)))
				Set tName=$P(tPropName,"(")
				Set pPropPath=pPropPath_$S(""=pPropPath:"",1:".")_tName

				If tIndexed {
					If 'tRep Set pStatus=$$$ERROR($$$EnsErrGeneral,"Collection path '"_pPropPath_"' given for non-collection property '"_tPropName_"' in XML schema '"_..DocType_"'")  Quit
					#; Evaluate index expression
					If (tIndex'="*") && ($E(tIndex)'="-") {
						Try {
							New %i
							X "Set %i="_tIndex
							Set tIndex=%i  Kill %i
						} Catch errobj { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Unable to evaluate index expression '"_tIndex_"' in property path '"_pPropPath_"' : "_errobj.AsSystemError())  Quit }
					}
				}
				If tRep { Set pPropPath=pPropPath_"("_tIndex_")" }
				Else { Set tIndex="" }
				Set pPSubs=pPSubs_","""_tName_$S('tRep:"",1:""","""_tIndex)_""""
				If ""'=tDName {
					#; Construct pDOMPath and pDSubs
					Set tDPath=tDPath_"/"_$S('tRep:tDName,"[]"=$E(tDName,*-1,*):$E(tDName,1,*-1)_tIndex_"]",1:tDName_"["_tIndex_"]")
					Set pNodeType=$P(tDName,"/",$L(tDName,"/"))
				}
				$$$ASSERTNOLOG('tIsAttr||tLastElem) ; attribute must be leaf
				Set tDOMElem=""
			}
		}
		If ("_"'=pDSubs) {
			If tIsAttr { Set pDSubs=pDSubs_","">@"","">"_tElem_"""" }
			Else { Set pDSubs=pDSubs_","">"_tElem_""","_$S($E(tIndex)="-"||(tIndex="*"):""""_tIndex_"""",+tIndex:tIndex,1:1) }
		}
	}
	Set pSchemaRef=tRef, pDOMPath=tDPath
	Quit:$$$ISOK(pStatus)&&(""'=tElem)&&(""=tDOMElem)&&tLastElem&&($D(@$$$vaPropsRef(pPSubs),pValue)#2) 1
	Quit 0
}

/// Migrate the %PropCache contents to %DOMCache so they are in sync
/// Start from given PropPath or DOMPath, use subscripts if given, otherwise compute them as needed
/// Must clean >x=r Prop subscripts and renumber after sync removes the corresponding DOM elements
Method syncToDOMCache(pKillAfter As %Boolean = 0, pPropPath As %String = "", ByRef pDOMPath As %String = "", ByRef pDSubs As %String = "_", ByRef pPSubs As %String = "_", ByRef pSchemaRef As %String = "", ByRef pNSContext) As %Status [ Internal ]
{
	If (""=pPropPath) {
		Quit:((""=..DocTypeCategory)||(""=..DocTypeName)) $$$ERROR($$$EnsErrGeneral,"Can't sync from Prop to DOM array because of invalid DocType:'"_..DocType_"'")
		Set pPSubs="", pSchemaRef=$Name($$$vaSchemaGbl(..DocTypeCategory,"DS",..DocTypeName,"meta"))
		Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(pSchemaRef)
		#; look in DOM for top element name
		#; 	Set tTopName=$O(@$$$vaDOMRef(","">"""))
		#; the top is now always "/" 11-07-2011
		Set tTopName=""
		; '>' collates higher than numbers
		Set kDom=">" for { Set kDom=$O(@$$$vaDOMRef(","">/"",1,"_""""_kDom_""""),-1,dtyp) q:kDom=""
			If $D(dtyp),$e(dtyp)'=">" Set tTopName=">"_$P(dtyp,">")
		}
		#; if not found in DOM - must look to Content
		Set:">"'=$E(tTopName) tTopName=">"_$$$domGetQName(..%ContentRef,$$$xmlGetDocumentElement(..%ContentRef))
		#; if found in DOM or Content - use it, otherwise stick with schema name
		Set:">"'=tTopName $P(tDName,"/")=$E(tTopName,2,*)
		Set pDOMPath="/"_tDName
		Set pDSubs=","">"_$Replace(tDName,"/",""",1,"">")_""",1"
	} Else {
		#; We are doing a subtree, make sure we have the subscripts we need
		If (""=pDOMPath)||("_"=pPSubs) {
			#; We got only the Prop path - compute the DOMPath and subscripts
			Set tSC=..propParsePath(pPropPath,"get",.pDOMPath,.tCSubs,.pDSubs,.pPSubs,.pSchemaRef,.tType,.tIndex,.tVal,.tNSContext,.tDone)  Quit:$$$ISERR(tSC) tSC
		} ElseIf (pDSubs["""-") || (pDSubs["""*""") {
			#; clean up the ones we inherited to remove indefinite collection parts so that whole array will be sync'ed
			Set nParts=$L(pDSubs,",")
			For i=1:1:nParts { Set iPart=$P(pDSubs,",",i)
				If ($E(iPart,1,2)="""-")||(iPart="""*""") { Set pDSubs=$P(pDSubs,",",1,i-1)  Quit }
			}
			Set nParts=$L(pPSubs,",")
			For i=1:1:nParts { Set iPart=$P(pPSubs,",",i)
				If ($E(iPart,1,2)="""-")||(iPart="""*""") { Set pPSubs=$P(pPSubs,",",1,i-1)  Quit }
			}
			Set pDOMPath=$P($P(pDOMPath,"[-"),"[*]")  Set:$Case($E(pDOMPath,*),".":1,"/":1,:0) pDOMPath=$E(pDOMPath,1,*-1)
			Set pPropPath=$P($P(pDOMPath,"(-"),"(*)")
		}
	}
	Set tSC=..syncDOMChild(pKillAfter,pPropPath,pDOMPath,pDSubs,pPSubs,pSchemaRef,.pNSContext)  Quit:$$$ISERR(tSC) tSC
	// Set namespaces needed by generated XML
	Set index="" For {  Set index=$O($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index)) q:index=""
		Set uri=$G($$$vaSchemaGbl(..DocTypeCategory,"ns","list",index,"uri"))
		; we don't know if xsd_<number> is unique amongst the namespace prefixes in the XML document
		; so there is a flaw in this algorithm in that non-uniqueness is possible
		If uri="http://www.w3.org/2001/XMLSchema",index=1 continue ; skip over schema uri used in schema
		Set tSC=..domSetValueAt(uri,$P(pDOMPath,"/",1,2)_"/@xmlns:xsd_"_index)  Quit:$$$ISERR(tSC) 
	}
	Quit tSC
}

/// Migrate the %PropCache contents to %DOMCache so they are in sync
/// Start from given PropPath or DOMPath, use subscripts if given, otherwise compute them as needed
Method syncDOMChild(pKillAfter As %Boolean, pPropPath As %String, ByRef pDOMPath As %String, ByRef pDSubs As %String, ByRef pPSubs As %String, ByRef pSchemaRef As %String, ByRef pNSContext) As %Status [ Internal ]
{
	Kill ^||isc.xml.vdoc.temp
 	Set tPropRef=$Name(@$$$vaPropsRef(pPSubs))
	merge ^||isc.xml.vdoc.temp=@tPropRef
	Set tDef=$D(@tPropRef,tValue)
	Quit:'tDef||$$checksync(pPSubs,.nSubs) $$$OK

	Set tIn=$G(pNSContext(">s"))  Set:'tIn pNSContext(">s")=1

	#; Merge the current property to the DOM
	Set tName=$G(@pSchemaRef@("name"))
	Set tRep=("()"=$E(tName,*-1,*)), tIsAttr=$D(@pSchemaRef@("a"))

	#; Set the literal element name explicitly if the content does not already contain one.
	Set tSC=$$$OK
	Set tFlag=$G(^||isc.xml.vdoc.temp(">x"))
	If "r"=tFlag {
		Set tSC=..domSetValueAt("",pDOMPath,"remove")  Quit:$$$ISERR(tSC) tSC
	}
	If tIsAttr {
		Set tAction=$Case(tFlag, "a":"append","c":"clear", "r":"remove",:$S($D(tValue):"set",1:""))
		If ""'=tAction {
			Set tSC=..domSetValueAt(tValue,pDOMPath,tAction)  Quit:$$$ISERR(tSC) tSC
			$$$ASSERTNOLOG(tDef=1)
		}
	} Else {
		#; Do comments first
		// JSL4290
		Set iComment="" For { Set iComment=$O(^||isc.xml.vdoc.temp(">c",iComment))  Quit:""=iComment
			Set iCommentSub=""">c"","_iComment
			Set ixCommentSub=iCommentSub_","">x"""
			Set tFlag=$G(@tPropRef(ixCommentSub))
			Set tText=""  If $D(@tPropRef(iCommentSub),tText) {
				Set tAction=$Case(tFlag, "a":"append","c":"clear", "r":"remove",:"set")
				Set tSC=..domSetValueAt(tText,pDOMPath_"/comment()["_iComment_"]",tAction)
			}
		}
		#; clear away old text before assigning new text
		If pDOMPath'["~" {
			If "t"=tFlag { Set tSC=..domSetValueAt("",pDOMPath_"/text()[]","clear")  Quit:$$$ISERR(tSC) tSC }
			ElseIf "c"=tFlag { Set tSC=..domSetValueAt("",pDOMPath,"clear")  Quit:$$$ISERR(tSC) tSC } ; remove old text and elements (but not comments or instructions)
		}
		#; handle content properties
		If $D(tValue) {
			If tFlag="a" { Set tSC=..domSetValueAt(tValue,pDOMPath,"append")  Quit:$$$ISERR(tSC) tSC }
			Else { Set tSC=..domSetValueAt(tValue,pDOMPath)  Quit:$$$ISERR(tSC) tSC }
		}
	}
	Quit:tDef=1 $$$OK ; no child props to sync
	
	#; Resolve type reference if needed
	If '$G(@pSchemaRef)&&($D(@pSchemaRef@("type"),tType)#2) {
		Set ttRef=##class(EnsLib.EDI.XML.Schema).getTypeRef($P(..DocType,":"),tType,.tSC1)
		Set:""'=ttRef pSchemaRef=ttRef
	}
	Set tIndex="" For { Set tIndex=$O(^||isc.xml.vdoc.temp(tIndex))  Quit:""=tIndex  Continue:">"=$E(tIndex)
		; are we an anonymous type not projected into properties so that higher level has repetition marker if there is a repetition
		if tIndex'=+tIndex { ; we are subscripting by property names, so this is not a true repetition
			Set tRep=0
		}
	}
	#; Merge all sub-elements to DOM
	If tRep {
		Set tIndex="" For { Set tIndex=$O(@tPropRef@(tIndex))  Quit:""=tIndex  Continue:">"=$E(tIndex)
			$$$ASSERTNOLOG(+tIndex=tIndex && (pDOMPath["]"))
			#; Get new DOM subscripts and path
			If pDSubs[","">[" {
				#; Anonymous choice array element sub-type
				Kill tValue  Set tSubProp=$O(@tPropRef@(tIndex,""),-1,tValue), tSubProp=$P(tSubProp,"(")
				$$$ASSERTNOLOG($L(tSubProp))
				Set iSubProperty=$G(@pSchemaRef@("pnames",tSubProp))
				$$$ASSERTNOLOG(iSubProperty)
				Set tNewRef=$Name(@pSchemaRef@(iSubProperty))
				Set tNewPPath=pPropPath_"("_tIndex_")."_tSubProp
				Set tNewElem=$G(@tNewRef@("d+")), tNewChildElems=$G(@tNewRef@("d"))
				Set tNewDOMPath=..insertIndex(pDOMPath,tIndex,tNewElem,tNewChildElems)
				Set tNewPSubs=pPSubs_","_tIndex_","""_tSubProp_""""
				Set tNewDSubs="_"
			} Else {
				Set tNewRef=pSchemaRef
				Set tNewPPath=pPropPath_"("_tIndex_")"
				Set tNewDOMPath=..insertIndex(pDOMPath,tIndex)
				Set tNewPSubs=pPSubs_","_tIndex
				Set tNewDSubs=pDSubs_$S("_"=pDSubs:"",1:","_tIndex)
			}
			Set tSC=..syncDOMChild(pKillAfter,tNewPPath,tNewDOMPath,tNewDSubs,tNewPSubs,tNewRef,.pNSContext)  Quit:$$$ISERR(tSC)
			If "r"=$G(@tPropRef@(tIndex,">x")) {
				#; clean >x=r Prop subscripts and renumber after sync removes the corresponding DOM elements
				Kill @tPropRef@(tIndex)
				Set iidx=tIndex, tIndex=tIndex-1
				For { Set iidx=$O(@tPropRef@(iidx))  Quit:""=iidx
					Merge @tPropRef@(iidx-1)=@tPropRef@(iidx)  Kill @tPropRef@(iidx) ; slide down to fill gap of removed index
				}
			}
		}
	} Else { // not in an array
		#; Loop over child props in schema order
		Set tDupYet=0, tDups=$G(@pSchemaRef@("dups")) ; DOM names of elements that have multiple schema children at this level that share the same DOM element name
		Set tPropName="", (iPrevProp,tPrevNode)=0
		Set nProps=$G(@pSchemaRef)  For iProp=1:1:nProps {
			Set tNewRef=$Name(@pSchemaRef@(iProp))
			Set tPropName=@tNewRef@("name"), tNewRep=("()"=$E(tPropName,*-1,*)), tPropName=$P(tPropName,"(")
			$$$ASSERTNOLOG(""'=tPropName&&(+tPropName'=tPropName)&&(iProp=$G(@pSchemaRef@("pnames",tPropName))))
			Set tNewPSubs=pPSubs_","""_tPropName_""""
			Set tNewPropRef=$Name(@$$$vaPropsRef(tNewPSubs))
			Kill tPropVal  Set tPropDef=$D(@tNewPropRef,tPropVal)
			Continue:'tPropDef

			Set tNewPPath=$S(""=pPropPath:"",1:pPropPath_".")_tPropName

			#; Find the DOM path and DOM subscripts for our prop
			Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tNewRef)
			Set nParts=$L(tDName,"/")
			Set tIsAttr=$D(@tNewRef@("a")), tIsElem=(""'=tDName&&'tIsAttr)
			$$$ASSERTNOLOG('("["=$E(tDName)||(tDName["\[")) || (tPropDef'=1 && tNewRep)) ; Anonymous array of various types
			If (tNewRep && (""=tDName)) {
				#; repeating sequence - move along to next child so we don't put the index in the wrong place
				Set tSC = ..syncSequence(tNewRef,tNewPSubs,tNewPPath,pDSubs,pDOMPath,pKillAfter,.pNSContext)	Quit:$$$ISERR(tSC)
			}

			/*	If not a subtree then do not rely on tPrevNode if not 0
				since based on schema element position and does not account
				for prior sibling multi entry arrays. Therefore treat as a subtree
				to allow for recalculation of position in sequence.
			*/
			 ElseIf ((tPropDef=1) && ('$Get(tPrevNode))) {
				Set tSC=..setDOMNode(tPropVal,.tDupYet,iProp,.iPrevProp,pSchemaRef,.tPrevNode,pDOMPath,pDSubs,,.pNSContext)  Quit:$$$ISERR(tSC)
			} Else {
				#; If we have a subtree, put it to the DOM
				Set tNewDOMPath=pDOMPath_$s(tDName'="":"/",1:"")_tDName
				Set tNewDSubs=pDSubs
				Set:"_"'=pDSubs&&(""'=tDName) tNewDSubs=pDSubs_","">"_$Replace(tDName,"/",""",1,"">")_""""_$S(tNewRep:"",1:",1")
				Set tSC=..syncDOMChild(pKillAfter,tNewPPath,tNewDOMPath,tNewDSubs,tNewPSubs,tNewRef,.pNSContext)  Quit:$$$ISERR(tSC)
				Set tPrevNode=tPrevNode+1
			}
			Set iPrevProp=iProp
		}
	}
	Kill:'tIn pNSContext(">s")
	Quit:$$$ISERR(tSC) tSC

	If 'tIn {
		If pKillAfter {
			Set:'$$$vaIsPropRef(..%PropCacheRef) i%%PropCacheRef="..%PropCache"
			Kill @tPropRef
		} Else {
			Set @tPropRef@(">s")=1
		}
	}
	Quit $$$OK

#; scan up the tree to see if we have been synced from any level above us
checksync(subs,nparts)
	Set sync=0, nparts=$L(subs,",")  For ipart=nparts:-1:0 { Set tSub=$P(subs,",",1,ipart)
		Set tSubIndex=tSub_","">s"""
		If $G(@$$$vaPropsRef(tSubIndex)) Set sync=1  Quit
	}
	Quit sync
}

Method insertIndex(path, idx, ele = "", chele = "") As %String
{
	Set pathr=$Reverse(path), len=$L(path)
	Set pos=0 For { Set pos=$F(pathr,"]",pos)  Quit:'pos
		Set pos2=pos, pos=$F(pathr,"[",pos) Quit:'pos
		Set:pos2+1=pos||$L(idx) $E(path,len+2-pos,len+2-pos2)=$S(""=ele:"",1:"element("_$P(ele,"[")_")")_"["_$S($L(idx):idx,1:1)_"]"_$S(""=chele:"",1:"/"_chele), (idx,ele,chele)=""
	}
	Quit path
}

Method syncSequence(pSchemaRef, pPSubs, pPropPath, pDSubs, pDOMPath, pKillAfter, pNSContext) As %Status
{
	#dim tSC As %Status = $$$OK
	
	#dim tIndex As %Integer = ""
	#dim tPropRef As %String = $Name(@$$$vaPropsRef(pPSubs))
	
	For {
		Set tIndex = $O(@tPropRef@(tIndex))	Quit:(tIndex="")||(tIndex'=+tIndex)
				
		Set tPropName=""
		For iProp=1:1:+$G(@pSchemaRef) {
			Set tNewRef=$Name(@pSchemaRef@(iProp))
			Set tPropName=@tNewRef@("name"), tPropName=$P(tPropName,"(")
			Set tNewPSubs=pPSubs_","_tIndex_","""_tPropName_""""
			Set tNewPropRef=$Name(@$$$vaPropsRef(tNewPSubs))
			Kill tPropVal  Set tPropDef=$D(@tNewPropRef,tPropVal)
			Continue:'tPropDef

			Set tNewPPath=$S(""=pPropPath:"",1:pPropPath_"("_tIndex_").")_tPropName

			#; Find the DOM path and DOM subscripts for our prop
			Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tNewRef)

			Set tNewDOMPath=..insertIndex(pDOMPath_$s(tDName'="":"/",1:"")_tDName,tIndex)
			If "_"'=pDSubs&&(""'=tDName) {
				Set tNewDSubs=pDSubs_","">"_$Replace(tDName,"/",""",1,"">")_""""_","_tIndex
			} Else {
				Set tNewDSubs=pDSubs
			}
			Set tSC=..syncDOMChild(pKillAfter,tNewPPath,tNewDOMPath,tNewDSubs,tNewPSubs,tNewRef,.pNSContext)  Quit:$$$ISERR(tSC)
		}
	}
	Quit tSC
}

/// Find the DOM spot where we should insert this new property
Method setDOMNode(pValue, ByRef pDupYet As %Boolean, iCurrProp As %Integer, ByRef iPrevProp As %Integer, pSchemaRef As %String, ByRef pPrevDElem As %Integer, pDOMPath As %String, pDSubs As %String, pDummy As %Integer, ByRef pNSContext) As %Status [ Internal ]
{
	#; walk up the schema checking each prop DName against the next DOM element until we match it or we get to our current prop
	#; if we match the DOM element and we're not at the current prop yet, pass over it and move on to the next DOM node
	#; if none of the interim schema props matches a DOM node then drop the prop into the DOM before the non-matching DOM element
	Set tSC=$$$OK, iProp=iPrevProp, tMatch=0
	#dim tIsAnonymous As %Boolean = ($G(@pSchemaRef@("name"))="choice") || ($P($G(@pSchemaRef@("xtype")),":",*)="sequence") ; choice or sequence

	// determine if current property is an array - JSL5244
	if $D(@pSchemaRef@(iPrevProp)) {
		Set tNewRef=$Name(@pSchemaRef@(iPrevProp))
		Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tNewRef)
		Set tRep=(tDName["[")
	} else {
		Set tRep=0
	}

	For pPrevDElem=pPrevDElem+1:1 {
		#; get the next DOM element
		Set tSC=..domGetValueAt(.tElemName,pDOMPath_"/element()["_$P(pPrevDElem,"[")_"]/name()")
		If (tSC["is a 'unknown' node") || (tSC["requesting element at non-") Set tSC=$$$OK
		Quit:$$$ISERR(tSC) 
		Quit:""=tElemName ; no more elements; append the current prop after the previous element
		#; walk up the schema until we match the current DOM element or we get to our current prop
		#; If choice then reset iProp since if we are a choice then iCurrProp is # within the choice not within the current dom level. 
		If tIsAnonymous Set iProp=iPrevProp
		For iProp=iProp+1:1:iCurrProp {
			Set tNewRef=$Name(@pSchemaRef@(iProp))
			Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tNewRef)
			Set tSaveRep=tRep
			Set tRep=(tDName["[")
			Set tDName=$P($P(tDName,"/"),"[") ; just get the first piece
			
			#; if the DOM element matched an interim schema element, move on to the next DOM element
			#; if the DOM element is us, replace it
			#; if tDName is "" then no dom alias.......
			//Set tMatch=$$nsMatch(tDName,tElemName)
			#;If we are not anonymous (choice or sequence) and the tDName found is blank lets go look for next one
			If 'tIsAnonymous,(tDName="") Quit
			Set tMatch=..equalElement($G(pNSContext("ign"),0),tDName,tElemName,.pNSContext)
			Quit:tMatch
		}
		Quit:$$$ISERR(tSC) 
		#; If we didn't match it and we're done, drop in after all the DOM elements we passed
		#; For choice we will quit when tElemName is ""
		Quit:((iProp=iCurrProp)&&('tIsAnonymous||tMatch))
	}
	Quit:$$$ISERR(tSC) tSC
	Set iPrevProp=iCurrProp

	#;If choice then iProp=iCurrProp and tElemName could be ""
	If iProp=iCurrProp,('tIsAnonymous||(""'=tElemName)) {
		$$$ASSERTNOLOG(""'=tElemName)
		If tMatch {
			#; the element is us; replace it
			Quit ..domSetValueAt($G(pValue),pDOMPath_"/"_tDName)
		} Else {
			// skip over elements of array - JSL5244
			// if the property corresponds to a schema element, which has minOccurs or maxOccurs set, then skip over corresponding DOM elements
			// that have the same name as the element name that corresponds to the property
			Set tNextElemName=tElemName
			if $g(tSaveRep),tNextElemName'="" {
				while tElemName=tNextElemName {
					Set:(tElemName=tNextElemName) pPrevDElem=pPrevDElem+1					
					Set tSC=..domGetValueAt(.tNextElemName,pDOMPath_"/element()["_pPrevDElem_"]/name()")
					
				}
			}
			#; we got to the current prop with no DOM match ; insert before the current DOM element
			Quit ..domSetValueAt($G(pValue),pDOMPath_"/"_$s($e(tDName)="@":tDName,1:"element("_$P(tDName,"[")_")[~"_pPrevDElem_"]"))
		}
	} Else {
		$$$ASSERTNOLOG(""=tElemName)
		#; no more elements; append the current prop at the current [empty) DOM element (after all the existing ones)
		Set tNewRef=$Name(@pSchemaRef@(iCurrProp))
		Set tDName=##class(EnsLib.EDI.XML.Schema).getDName(tNewRef)
		Set tRep=(tDName["[")
		#; loop over pieces of DName
		Set (f)=""  For i=1:1 { Set fp=f  Quit:0=fp  Set f=$F(tDName,"/",fp), tDPiece=$S(f:$E(tDName,fp,f-2),1:$E(tDName,fp,*))
			Quit:""=tDPiece||'f
			Set pDOMPath=pDOMPath_"/"_tDPiece
			Set tSC=..domSetValueAt("",pDOMPath,"append")  Quit:$$$ISERR(tSC)
		} Quit:$$$ISERR(tSC) tSC
		Set tDPiece=$P(tDPiece,"[")
		Quit:""=tDPiece $$$ERROR($$$EnsErrGeneral,"Property DOM name '"_tDName_"' at path '"_pDOMPath_"' contains empty piece; ref='"_tNewRef_"'")
		#; for attributes, don't use /element()
		Quit:$E(tDPiece)="@" ..domSetValueAt($G(pValue),pDOMPath_"/"_tDPiece)
		Quit ..domSetValueAt($G(pValue),pDOMPath_"/element("_tDPiece_")[~]")
	}
}

}
