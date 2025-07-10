/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

/// VDoc Schema classmethods and queries
/// also instance of local parser state<br><br>
/// Data structure built in $$$vaSchemaGbl(category) for schema associatedc with category.
/// <pre>
/// Source documents for this schema and imported/inlcuded schemas.
///    $$$vaSchemaGbl(category,"src")=srcCount
///    $$$vaSchemaGbl(category,"src",srcIndex)=[[ source schema document path ]]
/// Namespace defined by this schema and its inported and inlcuded schemas.
///    $$$vaSchemaGbl(category,"ns","targ")=targetNamespace
///    $$$vaSchemaGbl(category,"ns","index",namespaceURI)=nsIndex
///    $$$vaSchemaGbl(category,"ns","list",nsIndex,"AttributeQualified")=attributeFormDefault
///    $$$vaSchemaGbl(category,"ns","list",nsIndex,"ElementQualified")=elementFormDefault
///    $$$vaSchemaGbl(category,"ns","list",nsIndex,"Package")=packageName
///    $$$vaSchemaGbl(category,"ns","list",nsIndex,"Prefix")=prefix
///    $$$vaSchemaGbl(category,"ns","list",nsIndex,"uri")=namespaceURI
/// Document Property Structure by type used to show content array
///    $$$vaSchemaGbl(category,"p","Element:Structure)=# of children
///    $$$vaSchemaGbl(category,"p","Element:Structure,1..n,"name")=Name of child
///    $$$vaSchemaGbl(category,"p","Element:Structure,1..n,"type")=Type (Element:Structure) of child
/// Documentation nodes contained in top level annotation node.
///    $$$vaSchemaGbl(category,"desc")=elIndex,...  (may have multiple documentation nodes.
/// Raw schema document elements.
/// $$$vaSchemaGbl(category,elIndex,...) describes an element from the schema document.
///    $$$vaSchemaGbl(category,elIndex,"ch")=childElIndex ; element index of each child element
///    $$$vaSchemaGbl(category,elIndex,"chars")=text associated with node
/// If the schema element
///    $$$vaSchemaGbl(category,elIndex)=$lb("schema")
/// An element node of the schema
///    $$$vaSchemaGbl(category,elIndex,"local")=element ("element", "attribute", etc)
///    $$$vaSchemaGbl(category,elIndex,"src")=srcIndex  (see source list above)
///    $$$vaSchemaGbl(category,elIndex,"attrs",attrName)=value  (for each attribute of the schema element.)
/// General information for top level schema elements
///  elType="DS": element (DocType) 
///  elType="CT": complexType
///  elType="ST": simpleType or attribute
///  elType="CG": group or attributeGroup
///    $$$vaSchemaGbl(category,elIndex,"<types>")=elIndex,...  (multiple elIndex allowed (e.g. for elewment and complexType)
///    $$$vaSchemaGbl(category,elIndex,"<types>",elIndex)=elType
///    $$$vaSchemaGbl(category,elIndex,elType,name)=elIndex 
///    $$$vaSchemaGbl(category,elIndex,elType,name,"ns")=nsIndex 
///            if name appears in more than one namespace, then name$nsIndex
/// 
///    $$$vaSchemaGbl(category,elIndex,elType,name,"meta",... for meta information
///      "ns")=$$$vaSchemaGbl(category,elIndex,elType,name,"ns")
/// </pre>
Class EnsLib.EDI.XML.Schema Extends %RegisteredObject [ System = 3 ]
{

/// limit depth of recursion building ContentArray "array" subscript to avoid size and time overflows
Parameter MAXCONTENTARRAYDEPTH = 20;

/// Returns a list of available DocTypes for the corresponding document class. <br/>
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
Query DocStructures(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "DocStructure:%String,Description:%String")
{
}

ClassMethod DocStructuresExecute(ByRef qHandle As %Binary, Category As %String = "", IncludeBase As %Boolean = 0) As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Set Std=+$G($$$vaSchemaDescGbl(k,"std"))
		If $Case(Category,"0":Std,"+":'Std,"":1,:$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set iVer=$I(qHandle("ver")), qHandle("ver",$S(Std:iVer,1:"u"_iVer))=k ; sort standard ones first
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver",""))
	Quit $$$OK
}

ClassMethod DocStructuresFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DocStructuresExecute ]
{
	Kill Row Set Row=""
	While ""'=$G(qHandle("ver")) {
		Set qHandle=$O($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),"DS",qHandle))
		Quit:""'=qHandle
		Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))
	}
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set tDesc=..GetDescription("DS:"_tCategory_":"_qHandle)
	Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
	Set Row=$LB(tCategory_":"_qHandle,tDesc,tStd)
	Quit $$$OK
}

ClassMethod DocStructuresClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DocStructuresFetch ]
{
	Kill qHandle
	Quit $$$OK
}

Query TypeCategories(Standard As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String")
{
}

ClassMethod TypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "") As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Set Std=+$G($$$vaSchemaDescGbl(k,"std"))
		If $Case(Standard,"0":Std,"+":'Std,"":1,:$ZCVT(Standard,"L")=$E($ZCVT(k,"L"),1,$L(Standard))) {
			Set iVer=$I(qHandle("ver")), qHandle("ver",$S(Std:iVer,1:"u"_iVer))=k ; sort standard ones first
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver",""))
	Quit $$$OK
}

ClassMethod TypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = TypeCategoriesExecute ]
{
	Kill Row Set Row="", tDesc = ""
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))
	Set tDescNode=$P($G($$$vaSchemaGbl(tCategory,"desc")),",")
	Try {Set tDesc=$S(""=tDescNode:"",1:$Replace($G($$$vaSchemaGbl(tCategory,tDescNode,"chars")),$C(13,10),$C(10)))} Catch {}
	Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
	Set tBase=$G($$$vaSchemaGbl(tCategory,"base"))
	Set Row=$LB(tCategory,tDesc,tStd,tBase)
	Quit $$$OK
}

ClassMethod TypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = TypeCategoriesFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Get all properties for a given document structure
ClassMethod GetContentArray(Output pContents, pMode As %String = "source", pType As %String = "", pLevel As %Integer = "", pIncludeBase As %Boolean = 0, pElem As %String = "DS", pNodeAddr = "-1") As %Status
{
	Set tCat=$P(pType,":"), tStruct=$P(pType,":",2)
	If (tCat="")||(tStruct="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:name'.")
	if ((pLevel>0)&&(pNodeAddr'[",")&&(pNodeAddr'>0)) {
		Quit ..buildContentArray(.pContents,pMode,tCat_":"_pElem_":"_tStruct,pLevel+1)
	} else {
		Quit ..mergeArray(.pContents,pMode,pType,pElem,pNodeAddr,pLevel)
	}
}

ClassMethod mergeArray(Output pContents, pMode As %String, pType, pElem, pNodeAddr, pMaxLevels As %Integer = 0) As %Status
{
	
	#Dim tSC As %Status = $$$OK
	#Dim e As %Exception.AbstractException
	#Dim tReturnArray As %String = ""
	#Dim tElemStructure As %String
	#Dim tCat, tStruct, tRef As %String
	#Dim tCnt As %Integer
	#Dim tLenNodeAddr As %String
	#Dim tLevel, tPropNum As %Integer
	#Dim tMaxLevels As %Integer
	
	Try {
		Set tCat=$P(pType,":"), tStruct=$P(pType,":",2)
		Set tCnt=$G($$$vaSchemaGbl(tCat,pElem,tStruct,"meta"))

		If $Case($E($G(pContents)),"%":1,"^":1,:0) { 
			Set tReturnArray=pContents
			Kill @tReturnArray
		} Else {
			Kill pContents
			Set tReturnArray="%local"
			New %local
		}
		/* Use previous array structure if exists and copy all as before */
		If $D($$$vaSchemaGbl(tCat,pElem,tStruct,"array")) {
			Set tRef=$name($$$vaSchemaGbl(tCat,pElem,tStruct,"array"))
			If pNodeAddr[","||(pNodeAddr>0) {
				Set tRef=$e(tRef,1,$L(tRef)-1)_","_pNodeAddr_")"
			}
			Merge @tReturnArray = @tRef
		} Else{
			Set tElemStructure = pElem_":"_tStruct
			If '$D($$$vaSchemaGbl(tCat,"p",tElemStructure)) {
				Set tSC = $$$ERROR($$$EnsErrGeneral,"No content array is built for Document Structure '"_pType_"'.")
				Quit
			}
			If pNodeAddr[","||(pNodeAddr>0) {
				Set tLenNodeAddr = $L(pNodeAddr,",")
				For tLevel = 1:1:tLenNodeAddr {
					Set tPropNum = +$P(pNodeAddr,",",tLevel)
					If '$D($$$vaSchemaGbl(tCat,"p",tElemStructure,tPropNum,"type"),tElemStructure)#2 {
						Set tSC = $$$ERROR($$$EnsErrGeneral,"Content type missing for this structure/node address '"_pType_"/"_pNodeAddr_"'.")
						Quit	
					} 
				}
				If $$$ISERR(tSC) Quit
				Set tMaxLevels = $S(+pMaxLevels=0:1,1:pMaxLevels)
			} Else {
				Set tMaxLevels = $S(+pMaxLevels=0:..#MAXCONTENTARRAYDEPTH,1:pMaxLevels)
			}
			Set tSC = ..populateArray(tReturnArray,tCat,tElemStructure,tMaxLevels)
		}
	} Catch e {Set tSC = e.AsStatus()}
	
	If $$$ISOK(tSC)&&(tReturnArray="%local") {
		Try {Merge pContents = @tReturnArray} Catch e { Kill pContents  Set tSC = e.AsStatus() } /*Trap for possible STORE */
	}
	Quit tSC
}

/// Get all properties for a given document structure
ClassMethod buildContentArray(Output pContents, pMode As %String = "source", pType As %String, ByRef pLevel As %Integer, pNodeAddr = "") As %Status [ Internal ]
{
	Set tL=$G(pLevel)  Kill pLevel  S pLevel=tL, pLevel("curr")=0, pLevel("max")=0
	Set tCat=$P(pType,":"), tElem=$P(pType,":",2), tStruct=$P(pType,":",3)
	If (tCat="")||(tElem="")||(tStruct="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:elem:name'.")

	#; Prepare the output array reference
	Set tRef=$G(pContents)
	If ("%"=$E(tRef)||("^"=$E(tRef))) { Kill @tRef }
	Else { Kill pContents  Set tRef="%local"  New %local }
	
	Set mRef=$Name($$$vaSchemaGbl(tCat,tElem,tStruct,"meta"))
	if pNodeAddr[","||(pNodeAddr>0) {
		Set mRef=$e(mRef,1,$L(mRef)-1)_","_pNodeAddr_")"
	} 
	
	#; Walk the meta array to build a content array
	Set tSC=..buildContentArrayLevel(tRef,.pMode,mRef,tCat,tElem_$S((""'=tElem)&&(""'=tStruct):":",1:"")_tStruct,.pLevel)
	Merge:tRef="%local" pContents=%local
	Quit tSC
}

ClassMethod buildContentArrayLevel(ByRef pRef, pMode As %String, pMetaRef As %String, pCat As %String, pElStruct As %String, ByRef pLevel As %Integer) As %Status [ Internal ]
{
 	Quit:""'=pElStruct&&$G(pLevel("seen",pElStruct)) $$$OK ; no recursive drilling into types already drilled
	If pLevel Quit:pLevel("curr")>=pLevel $$$OK
	Set pLevel("curr")=pLevel("curr")+1  Set:pLevel("max")<pLevel("curr") pLevel("max")=pLevel("curr")

	#; Drill down recursive inheritance until we find something real
	Set tElStruct=pElStruct, tMetaRef=pMetaRef
	If ""=tElStruct {
		Set tCnt=$G(@tMetaRef)
	} Else {
		While 1 {
			Set tCnt=$G(@tMetaRef), tCnt(tElStruct)="" ; avoid circular inheritance
			Quit:tCnt
			Set tElStruct=$P($G(@tMetaRef@("type")),"/")
			Quit:""=tElStruct||$D(tCnt(tElStruct))
			Set tMetaRef=$Name($$$vaSchemaGbl(pCat,$P(tElStruct,":"),$P($P(tElStruct,":",2),"("),"meta"))
		}
	}
	Set tSC=$$$OK
	Set:tCnt @pRef=tCnt
	Set:""'=tElStruct pLevel("seen",tElStruct)=1
	For i=1:1:tCnt {
		Set tType=$G(@tMetaRef@(i,"type"))
		Set tElem=$P(tType,":",1), tStruct=$P($P(tType,":",2),"(")
		If tElem?2U {
			Set tSC=..buildContentArrayLevel($Name(@pRef@(i)),.pMode,$Name($$$vaSchemaGbl(pCat,tElem,tStruct,"meta")),pCat,$S(""'=tStruct:tElem_":"_tStruct,1:""),.pLevel)
		} ElseIf $G(@tMetaRef@(i)) {
			Set tSC=..buildContentArrayLevel($Name(@pRef@(i)),.pMode,$Name(@tMetaRef@(i)),pCat,"",.pLevel)
		} Quit:$$$ISERR(tSC)
		Set @pRef@(i,"name")=@tMetaRef@(i,"name")
		Set:""'=tType @pRef@(i,"type")=tType
	}
	Kill:""'=tElStruct pLevel("seen",tElStruct)  Set pLevel("curr")=pLevel("curr")-1
	Quit tSC
}

/// Store all meta properties for a given document structure
/// target array must be clean already
ClassMethod buildMetaArray(pBaseGbl As %String, pType As %String, pVerbose As %Integer) As %Status [ Internal ]
{
	Set tCat=$P(pType,":"), tElem=$P(pType,":",2), tStruct=$P(pType,":",3)
	If (tCat="")||(tElem="")||(tStruct="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:elem:name'.")
	Set tStructNode=$G($$$vaSchemaGbl(tCat,tElem,tStruct))
	Quit:""=tStructNode $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' not defined.")

	Set tLocalType=$G($$$vaSchemaGbl(tCat,tStructNode,"local"))
	Quit:$Case(tLocalType,"element":0,"simpleType":0,"complexType":0,"group":0,"attributeGroup":0,:1) $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' has unrecognized local type '"_tLocalType_"'")

	Set (tLevelM("curr"),tLevelM("raw"),tLevelM("max"),tLevelM("maxraw"))=0
	Set tLevelM("base")=pBaseGbl, tLevelM("Verbose")=pVerbose, tLevelM=10000
	Set tRef=$Name(@pBaseGbl@(tCat,tElem,tStruct,"meta"))
	Set:'$G(tLevelM("key")) tLevelM("key")=$I(^IRIS.Temp.XMLVDoc)
	Do ..initMeta(tLevelM("key"))
	Do ..getElementsMetaArray(.tRef,tCat,tElem_":"_tStruct,tStructNode,"",.tLevelM,.tSC)
	Merge @tRef@("ns")=@pBaseGbl@(tCat,tElem,tStruct,"ns")
	Kill:""'=$G(tLevelM("key")) ^IRIS.Temp.XMLVDoc(tLevelM("key"))
	Quit $$$OK
}

/// target array must be clean already<br>
/// <pre>
/// Temporary storage for each call.
/// tLevelM(
///    "key" - key for this call.  Indexes ^IRIS.Temp.XMLVDoc
///    "curr" - elIndex for node being processed
///    "raw"
///    "max"
///    "maxraw"
///    "seen",elIndex)'="" if already node already processed.
///    "base")=$$$vaSchemaGbl as string, i.e. "^EnsEDI.XML.Schema"
///    "Verbose")=pVerbose   is verbose flag
/// 
/// ^IRIS.Temp.XMLVDoc(tLevelM("key",...
///    "xsBuiltin",t)="" for recognizing builtin types
/// 	      where t = "string","boolean","float","double","decimal","dateTime","duration","hexBinary","base64Binary","anyURI","ID","IDREF","ENTITY","NOTATION","normalizedString","token","language","IDREFS","ENTITIES","NMTOKEN","NMTOKENS","Name","QName","NCName","integer","nonNegativeInteger","positiveInteger","nonPositiveInteger","negativeInteger","byte","int","long","short","unsignedByte","unsignedInt","unsignedLong","unsignedShort","date","time","gYearMonth","gYear","gMonthDay","gDay","gMonth"
/// <pre>
ClassMethod getElementsMetaArray(ByRef pRef As %String, pCategory As %String, pStruct As %String, pNode As %String, pParentRep As %String, ByRef pLevelM As %Integer, Output pSC As %Status = {$$$OK}) As %Boolean [ Internal ]
{
 	#; If we already saved this node just return it, possibly changing the output array reference
	Set doXType=1, doNode=1, doVerbose=$G(pLevelM("Verbose"))
	Set tCurrNode=$P(pNode,",")
	If ""'=pStruct {
		Set tpRef=$Name(@pLevelM("base")@(pCategory,$P(pStruct,":"),$P(pStruct,":",2),"meta"))
		If $D(@tpRef) {
			Set pRef=tpRef
			If (""'=$G(@pRef@("name"))) {
				w:doVerbose !,"Found existing type ** "_pStruct_" ** at level "_pLevelM("curr")
 				If pParentRep="()" {
	 				#;Need to check if we now know ought to have [] at end of tDOMName	
	 				Set tLocalType = $G($$$vaSchemaGbl(pCategory,tCurrNode,"local"))
	 				If $Case(tLocalType,"attribute":1,"anyAttribute":1,"any":1,"element":1,:0) {
		 				Set tDOMName=$G(@pRef@("d"))
						#; Could be trailing [n] and not just []
		 				If (tDOMName'=""),($E(tDOMName,*)'="]") Set @pRef@("d") = tDOMName_"[]"
	 				}
	 			}
			} Else {
				Set @pRef@("type")=pStruct, @pRef@("name")=$P(pStruct,":",2)
				w:doVerbose !,"Recursive reference to in-progress type ** "_pStruct_" ** at level "_pLevelM("curr")
			}
			Quit 1
		} ElseIf ""'=$G(pLevelM("seen",tCurrNode)) {
			Set @pRef@("type")=pStruct, @pRef@("name")=$P(pStruct,":",2)
			w:doVerbose !,"Recursive reference to in-progress type ** "_pStruct_" ** at node "_tCurrNode_", level "_pLevelM("curr")
			Quit 1
		}
		w:doVerbose !,"Starting type ** "_pStruct_" ** at level "_pLevelM("curr")
		Set pRef=tpRef, pNode=tCurrNode
	} Else {
		w:doVerbose !,"Continuing at level "_pLevelM("curr")_", node="_$G(pNode)
	}
	$$$ASSERTNOLOG('$D(@pRef))

	Quit:'$D($$$vaSchemaGbl(pCategory,tCurrNode)) 0
	Quit:pLevelM("curr")>pLevelM||(""'=$G(pLevelM("seen",tCurrNode))) 0

	#; Get schema values for current level
	Set n=..%New($LB(pLevelM("key"),pCategory,tCurrNode,pStruct,doXType,doNode,doVerbose))
	Set pLevelM("seen",tCurrNode)=1, pLevelM("raw")=pLevelM("raw")+1  Set:pLevelM("maxraw")<pLevelM("raw") pLevelM("maxraw")=pLevelM("raw")
	If ""'=n.OriginalName Set pLevelM("curr")=pLevelM("curr")+1 Set:pLevelM("max")<pLevelM("curr") pLevelM("max")=pLevelM("curr")

	Set:""=pParentRep pParentRep=n.Rep
 	Set:n.LocalType="choice" tDOMName=$S(""=pParentRep:"", 1:$TR(pParentRep,"()","[]"))
	;Set:n.LocalType="choice" pParentRep="" commented out by JSL4406
	Set:$Case(n.LocalType,"attribute":1,"anyAttribute":1,"any":1,"element":1,:0) tDOMName=n.OriginalName_$TR(pParentRep,"()","[]"), pParentRep=""
	w:doVerbose&&(pLevelM("max")=pLevelM("curr")||(pLevelM("maxraw")=pLevelM("raw"))) !," level="_pLevelM("curr")_", raw="_pLevelM("raw")_", node=("_pNode_"), local="_n.LocalType

	Set xLocalType=$S(""'=n.Base:n.LocalType_"("_n.Base_")",1:n.LocalType)
	Set xLocalType=$S(""'=n.LocalVal:xLocalType_"("_n.LocalVal_")",1:xLocalType)

	#; Pull in inherited tree if any
	Set (iProp,tRestriction)=0
	If $Case(n.LocalType,"extension":1,"restriction":1,"element":1,"elementRef":1,"attribute":1,"attributeRef":1,"anyAttribute":1,"any":1,"group":1,"attributeGroup":1,:0) && (""'=n.StructNode) && (n.StructNode'=tCurrNode) {
		Set txRef=pRef, tStructType=$S(n.Type[":"&&($P(n.Type,":")'=n.TypeNSIndex):n.Type, 1:"")
		Do ..getElementsMetaArray(.txRef,pCategory,tStructType,n.StructNode_","_pNode,pParentRep,.pLevelM,.tSC1)  If pSC'=tSC1 Set pSC=$$$ADDSC(pSC,tSC1) Quit 0
		If txRef'=pRef {
			$$$ASSERTNOLOG('$D(@pRef)&&("#"=$E($G(@txRef@("type")))||(($G(@txRef@("type"))[":")&&($L($P(@txRef@("type"),":"))>1))))
			If $Case(n.LocalType,"element":1,"elementRef":1,"attribute":1,"attributeRef":1,:0) {
				#; just use the referenced type; copy the top level values from it and discard it
				Set k=""  For { Kill tVal  Set k=$O(@txRef@(k),1,tVal)  Quit:""=k  Continue:+k=k||'$D(tVal)  Set @pRef@(k)=tVal }
				Set txRef=pRef
			} Else { ; extension or restriction or group
				#; use all the props of the named type
				Set txType=$P($G(@txRef@("type")),"(")
				//$$$ASSERTNOLOG(txType=tStructType||..isDerived(pCategory,tStructType,txType)) ; needs fancier logic for e.g. DATEXIISchema_1_0_1_0 CT:ExtensionType
				If '$G(@txRef)&&(txType'="")&&(txType'=n.Type) {
					#; Drill down for next level type
					Set txRef=pRef, txNode=n.findTypeNode(txType,.tSC1)
					Do:$$$ISOK(tSC1) ..getElementsMetaArray(.txRef,pCategory,txType,txNode_","_n.StructNode_","_pNode,pParentRep,.pLevelM,.tSC1)  If pSC'=tSC1 Set pSC=$$$ADDSC(pSC,tSC1) Quit 0
					If txRef'=pRef {
						Merge @pRef=@txRef ; need real properties to extend or restrict
						Set:doNode @pRef@("n")=tCurrNode_$S(""=$G(@pRef@("n")):"",1:","_@pRef@("n"))
						Set:doXType @pRef@("xtype")=$S(""=$G(@pRef@("xtype")):xLocalType,1:xLocalType_":"_@pRef@("xtype"))
					}
				} ElseIf '$G(@txRef) {
					If $D(@txRef@(1)) {
						#; just use the named type: take only the non-numeric nodes from the top level
						w:doVerbose !,"!! Using only type name; Has no prop count but has prop 1 - Recursive type definition, probably"
						Set k=""  For { Kill tVal  Set k=$O(@txRef@(k),1,tVal)  Quit:""=k  Continue:+k=k||'$D(tVal)  Set @pRef@(k)=tVal }
						Set txRef=pRef
					} ElseIf $D(@txRef@("a")) || $D(@txRef@("e")) {
						#; Propertyless type: attribute or childless element
						#; Put it in as the first property
						Merge @pRef@(1)=@txRef ;  ZKill @pRef@(1)
						Set @pRef=1, tPropType=txType
						Set @pRef@("pnames",@txRef@("name"))=1
						Set txRef=pRef
					} Else {
						Merge @pRef=@txRef ; inherit from abstract type
					}
				} Else {
					Merge @pRef=@txRef ; have real properties to extend or restrict
				}
			}
		}
		Set:"restriction"=n.LocalType tRestriction=1
		Set iProp=+$G(@pRef)
		Set:""'=tStructType @pRef@(n.LocalType)=tStructType
	} ElseIf "union"=n.LocalType && (""'=$ZStrip(n.MemberTypes,"*WC")) {
		#; Do union member type drilldowns if there were no other children
		$$$ASSERTNOLOG(""=n.StructNode)
		Set nTypes=$L(n.MemberTypes," "), tAnyProps=0
		For i=1:1:nTypes { Set tUType=$P(n.MemberTypes," ",i)  Continue:""=tUType
			Set n.StructNode=$G($$$vaSchemaGbl(pCategory,"<types>",tUType))
			$$$ASSERTNOLOG(n.StructNode'[",")
			Set n.StructNode=$P(n.StructNode,",")
			If '$D(utypes(tUType)) {
				Set utypes(tUType)=i
				If ""'=n.StructNode {
			//w "<br/>u",!,n.StructNode_","_pNode
					#; existence of tUTypeElem is certain because structNode exists
					Set tUTypeElem=$$$vaSchemaGbl(pCategory,"<types>",tUType,n.StructNode)
					Set tHasName=..getElementsMetaArray(.tStructRef,pCategory,tUTypeElem_":"_tUType,n.StructNode,pParentRep,.pLevelM,.tSC1)  If pSC'=tSC1 Set pSC=$$$ADDSC(pSC,tSC1) Quit
					Set tCnt=0 If $D(@tStructRef,tCnt)#2 {
						Set iProp = $I(@pRef)
						Set:tCnt tAnyProps=1
						Set @pRef@(iProp,"name")=$TR(tUType,".","_"), @pRef@(iProp,"type")=tUTypeElem_":"_tUType
						Kill tStructRef
					}
				} Else {
					Set iProp = $I(@pRef)
					If tUType[":" {
						Set @pRef@(iProp,"name")=$P($TR(tUType,".","_"),":",2), @pRef@(iProp,"type")=":"_tUType
					} Else {
						Set @pRef@(iProp,"name")=$TR(tUType,".","_"), @pRef@(iProp,"type")="?:"_tUType
					}
				}
			}
		}
		#; don't bother doing a Union if no members have any sub-properties
		If 'tAnyProps For i=1:1:iProp { Kill @pRef@(i) } Set iProp=0  ZKill @pRef
		Kill utypes
	} ElseIf "list"'=n.LocalType {
		$$$ASSERTNOLOG(""=n.StructNode)
		//w:iProp=1 !,pNode_" / "_n.Name_" / "_n.Type_" / "_@pRef@(iProp,"name")_" / "_@pRef@(iProp,"type")
	} Quit:$$$ISERR(pSC) 0

	#; finish inheritance pull-in
	Set:""'=pStruct @pRef@("type")=pStruct
	Set:doNode @pRef@("n")=tCurrNode_$S(""=$G(@pRef@("n")):"",1:","_@pRef@("n"))
	Set:doXType @pRef@("xtype")=$S(""=$G(@pRef@("xtype")):xLocalType,1:xLocalType_":"_@pRef@("xtype"))

	#; Incorporate the child nodes from the current node structure
	$$$ASSERTNOLOG(iProp=+$G(@pRef))
	Set tNumInherited=iProp
	Set (iChild,iDocChild,nEnums)=0, elno=""
	If "appinfo"'=n.LocalType {
		Set selno="", sdone=0
		For { Set pelno=elno, elno=$O($$$vaSchemaGbl(pCategory,tCurrNode,"ch",elno))  Quit:""=elno
			If $Case(n.StructNode,"":0,tCurrNode:0,:1) {
				#; skip child if struct duplicates it
				#; scan forward to sync up selno with elno
				While elno'=selno&&'sdone { Set pselno=selno, selno=$O($$$vaSchemaGbl(pCategory,n.StructNode,"ch",selno))  Quit:""=selno }
				Set sdone='selno
				Continue:elno=selno
			}
			Do n.newChild(elno)
			Set iChild=iChild+1, iProp=iProp+1
			Set txRef=$Name(@pRef@(iProp))
			Set tHasName=..getElementsMetaArray(.txRef,pCategory,"",elno_","_pNode,pParentRep,.pLevelM,.tSC1)  If pSC'=tSC1 Set pSC=$$$ADDSC(pSC,tSC1) Quit
			Continue:$$$ISERR(tSC1)
			Set tPropType=$G(@pRef@(iProp,"type"))
			If '$G(@txRef)&&'tHasName {
				#; Merge non-prop facets up to current level
				Do n.mergeFacets(pRef,txRef,iProp,iChild,.iDocChild,.nEnums)
				Set iProp=iProp-1
			} Else { ; has props or name
				If txRef'=$Name(@pRef@(iProp)) {
					#; Use just the structure reference if the property has a known type
					$$$ASSERTNOLOG('$D(@pRef@(iProp)))
					Set k=""  For { Kill tVal  Set k=$O(@txRef@(k),1,tVal)  Quit:""=k  Continue:+k=k||'$D(tVal)  Set @pRef@(iProp,k)=tVal }
					Set txRef=$Name(@pRef@(iProp))
				}
				Set tPropName=$G(@txRef@("name"))
				Set tInline=("union"'=n.LocalType) ; no merge-up for children in a union even if the child has only a single property
				Set:tInline tInline='tHasName||((tPropName?1(1"sequence",1"group",1"attributeGroup",1"all")1"_"1.N) && '(""'=$G(@txRef@("rep")) || '$G(@txRef@("req"))))
				If tInline {
					#; Merge the properties inline at the current level if they are a group and it's not repeating or optional
					If tRestriction {
						Set iProp=n.mergeRestrictions(pRef,txRef,iProp)
					} Else {
						Set:$G(@txRef) iProp=n.mergeFollowing(pRef,txRef,iProp)
					}
				} Else {
					#; Not inline - leave as a sub-property (replace corresponding existing property if this one is a restriction of the existing one)
					If tRestriction
						&& $D(@pRef@("pnames",$P(tPropName,"(")),irProp)
						 && ($G(@pRef@(irProp,"a"))=$G(@txRef@("a"))) {
						Kill @pRef@(irProp)
						Set tRemove=$G(@txRef@("prohibited"))
						If tRemove {
							#; If the 'restrict' subclass prop prohibits use of an existing name, remove the existing prop
							Set iProp=iProp-2
							Set tN=$P(tPropName,"(")
							#; Slide props down to fill the vacated slot of the prohibited property
							w:doVerbose !,"Removing prop '"_tN_"' at node "_tCurrNode_" due to 'use=prohibited' restriction"
							For iP=irProp:1:iProp { Merge @pRef@(iP)=@pRef@(iP+1)  Kill @pRef@(iP+1) }
							Set kN="" For { Set kN=$O(@pRef@("pnames",kN),1,iN)  Quit:""=kN  If tN=kN { Kill @pRef@("pnames",kN) } Else { Set @pRef@("pnames",kN)=iN-1 }}
							Set tNumInherited=tNumInherited-1
						} Else {
							#; If the 'restrict' subclass prop matches an existing name, replace the existing prop with the restricted definition
							Merge @pRef@(irProp)=@txRef
							Set iProp=iProp-1
						}
						Kill @txRef
					} Else {
						#; Leave named prop in place
						Set tRemove=0
					}
					Set @pRef=iProp
					#; 'req' default val is 'required' but now it's time to materialize it because we know we have a real property here
					Set:$Case(n.LocalType,"choice":0,"union":0,:""=$G(@pRef@(iProp,"req"))&&'tRemove) @pRef@(iProp,"req")=1
				}
			}
		} ; end 'elno' child loop
	} Quit:$$$ISERR(pSC) 0 ; else "appinfo"=n.LocalType
	$$$ASSERTNOLOG(iProp=+$G(@pRef))
	$$$ASSERTNOLOG(iProp=tNumInherited||'tNumInherited||$Case(n.LocalType,"extension":1,"restriction":1,:0))

	// Insert virtual prop 'Value' at position 1 for simpleContent if needed
	If "simpleContent"=n.LocalType && (iProp>1||$G(@pRef@(1,"a"))) {
		For i=iProp:-1:1 { Merge @pRef@(i+1)=@pRef@(i)  Kill @pRef@(i) }
		Set @pRef@(1,"name")="Value"
		Set @pRef@(1,"d")=""
		Set @pRef@("c")=1
		Set:doNode @pRef@(1,"n")=$P(@pRef@(2,"n"),":",$L(@pRef@(2,"n"),":"))
		Set:doXType @pRef@(1,"xtype")=$P(@pRef@(2,"xtype"),":")
		Set iProp=iProp+1, @pRef=iProp
	}
	/* A pull up candidate is one that is a single child.
	   If all parents have been pulled up check if last in line
	   and is a single element.
	   If a complex type we will correct pull up later in
	   BuildCategoryMaps()
	*/
	If (iProp=1) {
		Set tPullUp = 1
		/*	If no children and the youngest (simple element - tPropType="" and n.LocalType="element" )
			 look to see if all parents pulled up.
				() in sequence around name indicates pulled up.
				() without characters inbetween is repetition indicator so remove.
				E.G.  "meta",1,"n")="15:14(element1of1):13(element1of1)"
				OR [shows need to remove () repetition indicator before count]
					"8:7(grandparentname()):6(grandparentname()):5(grandparentname())"
				
		*/
		If ($G(@pRef@(1),0)=0)&&(tPropType="") {
			set nSequence=$Get(@pRef@(1,"n"))
			set nSequence=$Replace(nSequence,"()","")
			set nSequenceDepth=$Length(nSequence,":")
			if nSequenceDepth>1 && (nSequenceDepth=$Length(nSequence,"(")) {
				if n.LocalType="element" Set tPullUp = 0
			}
		}
		/*	A pull up candidate is not a union or choice or repeating or optional sequence

			Note if we do pull up repeating sequence then in getElementsMetaArray() when
			iProp>1 we set type to #sequence and this leads to a SUBSCRIPT error
			snippet example of @pRef@(1) when maxOccurs = 2 :
				^EnsEDI.XML.Schema("jgmOccurs","CT","occurs_Once","meta",1,"name")="sequence()"
				^EnsEDI.XML.Schema("jgmOccurs","CT","occurs_Once","meta",1,"rep")="(2)"
				^EnsEDI.XML.Schema("jgmOccurs","CT","occurs_Once","meta",1,"req")=1
				^EnsEDI.XML.Schema("jgmOccurs","CT","occurs_Once","meta",1,"type")="#sequence(2)"
				^EnsEDI.XML.Schema("jgmOccurs","CT","occurs_Once","meta",1,"xtype")="sequence"
		*/
		Set tPullUp=(tPullUp &&
			("#choice"'=$P($G(@pRef@(1,"type")),"(")) && 
			'(1=pLevelM("curr")&&(""'=$G(@pRef@(1,"rep")))&&$G(@pRef@(1))&&($P(pStruct,":")="DS")) &&
			'(("()"=$G(@pRef@(1,"rep")))  && (("()"=n.Rep)||(1=tCurrNode))) &&
			'("sequence()"=$G(@pRef@(1,"name")))
		)
	} Else {
		Set tPullUp = 0
	}

	#; Pull up contents to current level
	If tPullUp {
		Set tName0=n.Name
		Set a0=$D(@pRef@("a")), e0=$D(@pRef@("e")), d0=$G(@pRef@("d"))  Set:doNode n0=@pRef@("n")  Set:doXType x0=$G(@pRef@("xtype"))
		Set tcRef=$Name(@pRef@(1))

		#; If single prop is a struct, non-repeating: re-get with props
		If ""'=tPropType && (""=$G(@tcRef)) {
			Set elno=$G(@tcRef@("n"))
			$$$ASSERTNOLOG(""'=elno)
			Set a0=a0||$D(@tcRef@("a")), e0=e0||$D(@tcRef@("e"))
			Set d0a=$G(@tcRef@("d"))  Set:(""'=d0a) d0=d0_$S(""=d0:"",1:d0_"/")_d0a
			Set:doNode n0=@tcRef@("n")_":"_n0  Set:doXType x0=x0_":"_$G(@tcRef@("xtype"))
			Set tName0=$G(@tcRef@("name"),n.Name)
			Set:""=n.Name||$D(@tcRef@("a"))||$D(@tcRef@("e")) n.Name=tName0 ; preserve the name of a reference to a type
			Kill @tcRef
			Do ..getElementsMetaArray(.tcRef,pCategory,$P(tPropType,"("),elno_","_pNode,pParentRep,.pLevelM,.tSC1)  Set:pSC'=tSC1 pSC=$$$ADDSC(pSC,tSC1)
		} ElseIf 0=$G(@tcRef) { ZKill @tcRef }

		#; Do the pull-up
		Set tLwrElAttr=($D(@tcRef@("a")) || $D(@tcRef@("e")))
		Set tLwrD=$G(@tcRef@("d"))
		Set tChild1=$Name(^IRIS.Temp.XMLVDoc(pLevelM("key"),tCurrNode,pLevelM("raw")))
		Merge @tChild1=@tcRef@(1)  Kill:tcRef=$Name(@pRef@(1)) @tcRef@(1)
		ZKill @pRef  Set tCnt=$G(@tcRef) Set:tCnt @pRef=tCnt
		Kill @pRef@("pnames")
		Set k=""  For { Set k=$O(@tcRef@(k)) Quit:""=k  Continue:1=k  Continue:(("desc"=k)&&($D(@pRef@(k))#2))  Merge @pRef@(k)=@tcRef@(k) }
		Kill @pRef@(1)  Merge @pRef@(1)=@tChild1
		Kill @tChild1

		#; higher level Name always supersedes, except top struct name or element/attribute names from lower level
		Set:""=n.Name||tLwrElAttr n.Name=$G(@pRef@("name"))
		If doVerbose&&(""'=n.Name)&&((n.Name'=tName0)||(n.Name'=n.OriginalName)) {
			w:doVerbose !,"Overriding name at node "_tCurrNode_" from '"_n.OriginalName_"'/'"_tName0_"' to '"_n.Name_"'"
		}
		#; higher level Type supersedes except for collection types
		Set:$G(@pRef@("type"))["("&&(n.Type'["(") n.Type=@pRef@("type")

		#; if parent is optional then all pulled-up children are optional
		If 0=n.Min { For i=1:1:$G(@pRef) { Set @pRef@(i,"req")=0 } }

		Set:a0 @pRef@("a")=1  Set:e0 @pRef@("e")=1
		Set:(""'=d0) @pRef@("d")=$S(""=tLwrD:"",1:tLwrD_"/")_d0
		Set:doNode @pRef@("n")=@pRef@("n")_":"_n0_$S(""=n.Name:"",1:"("_n.Name_")")
		Set:doXType @pRef@("xtype")=x0_":"_@pRef@("xtype")
		Set iProp=$G(@pRef,0)
		$$$ASSERTNOLOG('iProp||$D(@pRef@("pnames")))
		If "choice"=n.LocalType && $L(tDOMName) {
			#; In the case of a single choice child, no need for anonymous repeater
			Set tDOMName=""
			Set:@pRef@("d")'["[" $P(@pRef@("d"),"/")=$P(@pRef@("d"),"/")_tDOMName, tDOMName=""
		}
	}
	// Insert virtual prop 'MixedValue' at position 1 for Mixed content if needed
	Set tDoMixed=(n.Mixed && iProp && ("MixedValue"'=$G(@pRef@(1,"name"))))
	If tDoMixed {
		For i=iProp:-1:1 { Merge @pRef@(i+1)=@pRef@(i)  Kill @pRef@(i) }
		Set @pRef@(1,"name")="MixedValue"
		Set @pRef@(1,"d")=""
		Set @pRef@("c")=1
		Set:doNode @pRef@(1,"n")=$P(@pRef@(2,"n"),":",$L(@pRef@(2,"n"),":"))
		Set:doXType @pRef@(1,"xtype")=$P(@pRef@(2,"xtype"),":")
		Set iProp=iProp+1, @pRef=iProp
	}
	If 'tPullUp || tDoMixed {
		#; Disambiguate names and rebuild prop names index
		$$$ASSERTNOLOG("simpleType"'=n.LocalType || 'iProp)
		Kill @pRef@("pnames")
		For tiProp=1:1:iProp { Set tPropName=$G(@pRef@(tiProp,"name"))
			Set tRep=$P(tPropName,"(",2), (tPropName,tBaseName)=$P(tPropName,"(")
			//$$$ASSERTNOLOG('$G(@pRef@(i))) ; no children with children allowed
			$$$ASSERTNOLOG(""'=tPropName&&($L(tRep)<=1))
			While $D(tNames(tPropName)) {
				If tPropName?1.E1"_"1.3N {
					Set tPrefix=$S(+tNames(tPropName):tPropName, 1:$P(tPropName,"_",1,$L(tPropName,"_")-1))
					If +$G(tNames(tPrefix)) { Set tPropName=tPrefix_"_"_$I(tNames(tPrefix)) }
					Else { Set tNames(tPropName)=2, tPropName=tPropName_"_"_2 }
				} Else { Set tNames(tPropName)=2, tPropName=tPropName_"_"_2 }
			}
			$$$ASSERTNOLOG($L(tPropName)>=$L(tBaseName))
			Set tNames(tPropName)=""
			Set @pRef@(tiProp,"name")=tPropName_$S(""'=tRep:"()",1:"")
			Set @pRef@("pnames",tPropName)=tiProp
		}
	}
	Kill pLevelM("seen",tCurrNode)  Set pLevelM("raw")=pLevelM("raw")-1  Set:""'=n.OriginalName pLevelM("curr")=pLevelM("curr")-1

	#; finalize node values
	#; Fill the current level contents array
	If ""'=n.Name { Set @pRef@("name")=n.Name  Set:n.IsQual @pRef@("ns")=n.NameNSIndex }
	Else { Set n.Name=$G(@pRef@("name")) }

	#; pull up child type if inherited - esp. if parent is a pure-collection or element/reference type
	#; higher level type supersedes except for collection types
	If ""=n.Type||($G(@pRef@("type"))["("&&(n.Type'["(")) { Set n.Type=$G(@pRef@("type")) }
	Else { Set @pRef@("type")=n.Type } ; &&("element"=n.LocalType&&'pLevelM("curr")||(iProp||(""=$G(@pRef@("type")))))

	If ""'=n.Base { Set @pRef@("base")=n.Base }
	Else { Set n.Base=$G(@pRef@("base")) }

	If ""'=n.Rep { Set @pRef@("rep")=n.Rep }
	Else { Set n.Rep=$G(@pRef@("rep")) }

	Set:0=n.Min @pRef@("req")=0 ; optional supersedes not-optional
	Set:""=$G(@pRef@("req"))&&(""'=n.Min) @pRef@("req")=n.Min

	$$$ASSERTNOLOG('iProp||(iProp>1)||((iProp=1)&&'tPullUp)||$Case($P($G(@pRef@(1,"name")),"("),"choice":1,"union":1,:((1>=pLevelM("curr")&&(""'=$G(@pRef@(1,"rep"))))||(("()"=$G(@pRef@(1,"rep")))  && (("()"=n.Rep)||(1=tCurrNode))))))
	$$$ASSERTNOLOG(iProp=+$G(@pRef))
	Set tStructRef=""
	If iProp>1 {
		Set:""=n.Name&&((""'=n.Rep)||(0=n.Min)||$Case(n.LocalType,"choice":1,"union":1,:0)) (n.Name,@pRef@("name"))=n.LocalType, (n.Type,@pRef@("type"))="#"_n.LocalType, @pRef@("d")=""
		Set:""=n.Type&&((""'=n.Rep)||(0=n.Min)||$Case(n.LocalType,"choice":1,"union":1,:0)) n.Type=pStruct
	} ElseIf iProp=0 {
		Set @pRef=0 ; marker to distinguish references from childless actual types (e.g. Attribute types)
	}
	Set:""'=n.Name&&(""'=n.Rep)&&(n.Name'["(") @pRef@("name")=n.Name_"()"
	Set:""'=n.Type&&(""'=n.Rep)&&(n.Type'["(") @pRef@("type")=n.Type_n.Rep
	Set:""'=n.Default @pRef@("default")=n.Default
	Set:"prohibited"=n.Use @pRef@("prohibited")=1

	Set:""'=n.LocalVal&&(n.LocalType="restriction") @pRef@("restriction")=n.LocalVal
	Set:n.LocalType="documentation"&&(""'=$TR($G($$$vaSchemaGbl(pCategory,tCurrNode,"chars")),$C(13,10,9))) @pRef@("desc")=tCurrNode
	Set:$Case(n.LocalType,"report":1,"p":1,:0)&&(""'=$TR($G($$$vaSchemaGbl(pCategory,tCurrNode,"chars")),$C(13,10,9))) @pRef@("app")=tCurrNode
	$$$ASSERTNOLOG('$Case(n.LocalType,"attribute":1,"anyAttribute":1,:0)||(/*'$D(@pRef@("d"))&&'$D(@pRef@("a"))&&*/'$D(@pRef@("e")))) // attrs can't contain elements ; x or attrs
	Set:$Case(n.LocalType,"attribute":1,"anyAttribute":1,:0) @pRef@("a")=1, @pRef@("d")="@"_$S(""=n.NameNSIndex||'n.IsQual:"",1:"$"_n.NameNSIndex_":")_tDOMName
	Set:$Case(n.LocalType,"element":1,"any":1,:0) @pRef@("e")=1, d0=$G(@pRef@("d")), @pRef@("d")=$S(""=n.NameNSIndex||'n.IsQual:"",1:"$"_n.NameNSIndex_":")_tDOMName_$S(""=d0:"",1:"/"_d0)
	If "choice"=n.LocalType&&$L(tDOMName) {
		Set @pRef@("e")=1
		Set d0=$G(@pRef@("d"))
		If $L(d0) {
			Set @pRef@("d")=tDOMName_"/"_$P(d0,"/",2,$L(d0,"/")), @pRef@("d+")=$P(d0,"/")
		} Else {
			Set @pRef@("d")=tDOMName
			#; remove top DOM name from each choice element
			#; (because we are using an anonymous repeating element designator)
			For tiProp=1:1:iProp {
				Set tPropD=$G(@pRef@(tiProp,"d"))
				$$$ASSERTNOLOG(tPropD'="")
				Set @pRef@(tiProp,"d+")=$P(tPropD,"/"), @pRef@(tiProp,"d")=$P(tPropD,"/",2,$L(tPropD,"/"))
			}
		}
	}
	$$$ASSERTNOLOG($P($G(@pRef@("d")),"@")<=2)
	Set:""'=n.MinLen&&(""=$G(@pRef@("minLength"))) @pRef@("minLength")=n.MinLen

	$$$ASSERTNOLOG(""'=$G(@pRef@("name"))||'$G(@pRef)||(1=@pRef&&("choice"=$G(@pRef@(1,"name"))))||$Case(n.LocalType,"complexType":1,"complexContent":1,"extension":1,"sequence":1,"all":1,"group":1,"attributeGroup":1,"simpleContent":1,:0))
	$$$ASSERTNOLOG($G(@pRef)||'$D(@pRef@(1)))
	//JSL4245 -remove deadly assert $$$ASSERTNOLOG(""'=n.Name||'$Case(n.LocalType,"attribute":1,"anyAttribute":1,"any":1,"element":1,:0))

	#; Store current obj as named struct (if new)
	If ""'=pStruct,n.Name'="" { // JSL4245
		Set tElem=$P(pStruct,":"), tStruct=$P(pStruct,":",2)
		Set tStructRef=$Name(@pLevelM("base")@(pCategory,tElem,tStruct,"meta"))
		If tStructRef'=pRef {
			$$$ASSERTNOLOG('$D(@tStructRef)&&(tStruct'["("))
			w:doVerbose !,"Adding struct "_pStruct_" with "_iProp_" properties"
			Set @pLevelM("base")@(pCategory,tElem,tStruct)=tCurrNode
			Set @pLevelM("base")@(pCategory,"<types>",tStruct)=tCurrNode
			Set @pLevelM("base")@(pCategory,"<types>",tStruct,tCurrNode)=tElem
			Merge @tStructRef=@pRef  Set:'$D(@tStructRef) @tStructRef=0
			For i=1:1:@pRef { Kill @pRef@(i) }  ZKill @pRef  Kill @pRef@("pnames")
		}
		$$$ASSERTNOLOG('$D(@pLevelM("base")@(pCategory,"<types>","+"_tCurrNode)) || (@pLevelM("base")@(pCategory,"<types>","+"_tCurrNode)=pStruct))
		Set:'$D(@pLevelM("base")@(pCategory,"<types>","+"_tCurrNode)) @pLevelM("base")@(pCategory,"<types>","+"_tCurrNode)=pStruct
		Set:""'=n.Type @pRef@("type")=n.Type
	}
	Kill:"appinfo"=n.LocalType @pRef@("name"),@pRef@("pnames") ; appinfo nodes only survive as a reference to an "app" node
	Quit (""'=n.Name)
}

ClassMethod initMeta(pKey As %Integer) [ Internal ]
{
	For t = "string","boolean","float","double","decimal","dateTime","duration","hexBinary","base64Binary","anyType","anyURI","ID","IDREF","ENTITY","NOTATION","normalizedString","token","language","IDREFS","ENTITIES","NMTOKEN","NMTOKENS","Name","QName","NCName","integer","nonNegativeInteger","positiveInteger","nonPositiveInteger","negativeInteger","byte","int","long","short","unsignedByte","unsignedInt","unsignedLong","unsignedShort","date","time","gYearMonth","gYear","gMonthDay","gDay","gMonth" {
		Set ^IRIS.Temp.XMLVDoc(pKey,"xsBuiltin",t)=""
	}
}

/* Properties of the current schema */
Property doXType As %Boolean;

Property doNode As %Boolean;

Property doVerbose As %Boolean;

Property Category As %String;

/* Properties of the current node */
Property CurrNode As %String;

Property LocalType As %String;

Property LocalVal As %String;

Property Name As %String;

Property NameNSIndex As %String;

Property OriginalName As %String;

Property MemberTypes As %String;

Property ItemType As %String;

Property RefNo As %String;

Property Req As %String;

Property Base As %String;

Property BaseNSIndex As %Integer;

Property Min As %String;

Property Max As %String;

Property Default As %String;

Property Rep As %String;

Property MinLen As %String;

/* Properties of the current node's superclass (if any) */
Property Type As %String;

Property Use As %String;

Property IsQual As %String;

Property TypeNSIndex As %Integer;

Property StructNode As %String;

Property Mixed As %Boolean;

/* Properties of the current child/iProp node */
Property elno As %String;

Property n0 As %String;

Property x0 As %String;

Method mergeRestrictions(pRef, txRef, iProp) As %Integer [ Internal ]
{
	#; Merge up all sub-properties except the first, and under-merging ones from a "restriction" inheritance
	Set:..doNode ..n0=@pRef@(iProp,"n")  Set:..doXType ..x0=@pRef@(iProp,"xtype")
	Set iBaseProp=iProp, tDo1=0
	For iStructProp=1:1:@txRef { Set tSubName=$G(@txRef@(iStructProp,"name"))
		Set:tSubName?1(1"any_",1"anyAttr_",1"choice_")1.N0.1(1"("0.N1")") tSubName=$P(tSubName,"_")_$S(tSubName["(":$E(tSubName,$F(tSubName,"(")-1,*),1:"")
		If $D(@pRef@("pnames",$P(tSubName,"(")),irProp)
		 && ($G(@pRef@(irProp,"a"))=$G(@txRef@(iStructProp,"a"))) {
			#; If the 'restrict' subclass prop matches an existing name, replace the existing prop with the restricted definition
			; JSL5245 - $$$ASSERTNOLOG(($E($G(@pRef@(irProp,"rep")),2,*)<=$E($G(@txRef@(iStructProp,"rep")),2,*))||("()"=$G(@pRef@(irProp,"rep")))) ; asserting the schema is not bogus
			If ($E($G(@pRef@(irProp,"rep")),2,*)<=$E($G(@txRef@(iStructProp,"rep")),2,*))||("()"=$G(@pRef@(irProp,"rep"))) { // JSL5245
				Do ..restrictSub(pRef,txRef,irProp,iBaseProp,iStructProp)
			}
		} Else {
			#; Otherwise, add the subclass prop to the subclass
			If iBaseProp'=1 {
				$$$ASSERTNOLOG(0_"Restrictions should not add properties") ; asserting the schema is not bogus - but can happen when recursive type definitions prevent the base props from appearing
			}
			w:..doVerbose !,"!! Adding property "_iStructProp_" from restriction node '"_$G(@txRef@("n"))_"' into struct node "_$G(@pRef@("n"))_" property "_iProp
			If iProp=iBaseProp Set tDo1=iStructProp, iProp=iProp+1  Continue ; save it for the end
			Set iProp=..mergeSub(pRef,txRef,iBaseProp,iProp,iStructProp)
		}
	}
	#; Finally (if it wasn't a "restriction") merge up StructProp #1 to the iBaseProp position
	If tDo1 {
		Do ..mergeSub1(pRef,txRef,iBaseProp,tDo1)
		Set:iProp=(iBaseProp+1) @pRef=iBaseProp ; update count if this was the only one
	} Else {
		Kill:txRef=$Name(@pRef@(iBaseProp)) @pRef@(iBaseProp)
	}
	Quit iProp-1
}

/// Merge the properties of the txRef structure into pRef positioned after the existing properties of pRef as given by iProp
Method mergeFollowing(pRef, txRef, iProp) As %Integer [ Internal ]
{
	#; Merge up all sub-properties except the first
	Set:$D(@txRef@("c"),c) @pRef@("c")=iProp+c-1 
	Set:..doNode ..n0=@pRef@(iProp,"n")  Set:..doXType ..x0=@pRef@(iProp,"xtype")
	Set iBaseProp=iProp, tDo1=0
	For iStructProp=1:1:@txRef {
		If iProp=iBaseProp Set tDo1=iStructProp, iProp=iProp+1  Continue ; save it for the end
		Set iProp=..mergeSub(pRef,txRef,iBaseProp,iProp,iStructProp)
	}
	#; Merge up the first sub-property
	Do ..mergeSub1(pRef,txRef,iBaseProp,tDo1)
	Set:iProp=(iBaseProp+1) @pRef=iBaseProp ; update count if this was the only one
	Quit iProp-1
}

Method restrictSub(pRef, txRef, iRestrictProp, iBaseProp, iStructProp) [ Internal ]
{
	Set:..doNode n0=@pRef@(iRestrictProp,"n")  Set:..doXType x0=@pRef@(iRestrictProp,"xtype")
	Kill @pRef@(iRestrictProp,"rep") ; restriction can diminish maxOccurs (can also increase minOccurs which means "req")
	Merge @pRef@(iRestrictProp)=@txRef@(iStructProp)  Kill:txRef=$Name(@pRef@(iBaseProp)) @txRef@(iStructProp)
	Set:..doNode @pRef@(iRestrictProp,"n")=@pRef@(iRestrictProp,"n")_":"_n0_"(restrict)"
	Set:..doXType @pRef@(iRestrictProp,"xtype")=x0_":"_@pRef@(iRestrictProp,"xtype")
}

Method mergeSub(pRef, txRef, iBaseProp, iProp, iStructProp) As %Integer [ Internal ]
{
	Set tPropName=$G(@txRef@("name"))
	Merge @pRef@(iProp)=@txRef@(iStructProp)  Kill:txRef=$Name(@pRef@(iBaseProp)) @txRef@(iStructProp)
	Set:..doNode @pRef@(iProp,"n")=@pRef@(iProp,"n")_":"_..n0_$S(""=tPropName:"",1:"("_tPropName_")")
	Set:..doXType @pRef@(iProp,"xtype")=..x0_":"_@pRef@(iProp,"xtype")
	Set @pRef=iProp
	Quit iProp+1
}

Method mergeSub1(pRef, txRef, iBaseProp, iStructProp) [ Internal ]
{
	#; Finally (if not a "restriction") merge up StructProp #1 to the iBaseProp position
	#; (we could recurse but for now we'll just do one level and hope tSub1 fits in memory)
	Set tPropName=$G(@txRef@("name"))
	ZKill @txRef  Set:$D(@txRef@(iStructProp))#2 @pRef@(iBaseProp)=@txRef@(iStructProp)
	Merge tSub1=@txRef@(iStructProp,iStructProp)
	#; clean out the previous contents at the target level
	Set k=""  For { Set k=$O(@pRef@(iBaseProp,k)) Quit:""=k  Continue:k=iStructProp
		Kill @pRef@(iBaseProp,k)
	}
	#; move the new contents up
	Set k=""  For { Set k=$O(@txRef@(iStructProp,k)) Quit:""=k  Continue:k=iStructProp
		Merge @pRef@(iBaseProp,k)=@txRef@(iStructProp,k)  Kill:txRef=$Name(@pRef@(iBaseProp)) @txRef@(iStructProp,k)
	}
	#; Finally  merge up sub-StructProp #1 to the iBaseProp,1 position
	Kill @pRef@(iBaseProp,iStructProp)  Merge @pRef@(iBaseProp,iStructProp)=tSub1
	Set:..doNode @pRef@(iBaseProp,"n")=@pRef@(iBaseProp,"n")_":"_..n0_$S(""=tPropName:"",1:"("_tPropName_")")
	Set:..doXType @pRef@(iBaseProp,"xtype")=..x0_":"_@pRef@(iBaseProp,"xtype")
}

/// Drill down until we find a type that has properties, return a schema refrerence to it
ClassMethod getTypeRef(pCategory, pStructType, Output pStatus = {$$$OK}) As %String
{
	If pStructType[":" {
		Set tType=$P($P(pStructType,":",2),"("), tElem=$P(pStructType,":")
	} Else { 
		Set tType=$P(pStructType,"("), tElem="CT"
	}
	Set tRef=$Name($$$vaSchemaGbl(pCategory,tElem,tType,"meta"))
	Quit:$G(@tRef) tRef
	If $D(@tRef@("type"),tNextType)#2 && (tNextType'=pStructType) && ("ST"'=tElem) {
		Quit ..getTypeRef(pCategory,tNextType,.pStatus)
	} Else {
		If $D(@tRef) { Set pStatus=$$$ERROR($$$EnsErrGeneral,tElem_" type '"_tType_"' has no properties in category "_pCategory) }
		Else { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Unable to find referenced type "_tElem_":"_tType_" in category "_pCategory) }
		Quit ""
	}
}

ClassMethod getDName(pRef As %String) As %String [ Internal ]
{
	Set tD = $D(@pRef@("d"),tDName)
	If ('tD#2){
		Set tDName = $S($D(@pRef@("a")):"@",1:"")_$S(""=$G(@pRef@("ns")):"",1:"$"_@pRef@("ns")_":")_$P(@pRef@("name"),"(")
	}
	Quit tDName
}

Method findTypeNode(pStructType, Output pStatus) As %Integer
{
	Set pStatus=$$$OK, tType=$P(pStructType,":",2), tElem=$P(pStructType,":")
	$$$ASSERTNOLOG('(""=tType||($L(tElem)<=1)))
	If ""=tType||($L(tElem)<=1) {
		w:..doVerbose !,"Invalid type "_pStructType
		Quit ""
	}
	Set tStructNode=$G($$$vaSchemaGbl(..Category,"<types>",tType))
	If tStructNode["," {
		#; In case of duplicates, pick the first "element" type in the list, if it's not us
		Set tListLen=$L(tStructNode,",")  For i=1:1:tListLen { Set tSN=$P(tStructNode,",",i)
			Quit:""'=tSN&&(tElem=$G($$$vaSchemaGbl(..Category,"<types>",tType,tSN)))
		}
		Set tStructNode=tSN
	}
	If ""=tStructNode { Set pStatus=$$$ERROR($$$EnsErrGeneral,"Found no node for type "_pStructType)  w:..doVerbose !,"Found no node for type "_pStructType }
	Quit tStructNode
}

Method %OnNew(catnode) As %Status
{
	#; new node state obj
	Set tKey=$LI(catnode,1)
	Set ..Category=$LI(catnode,2)
	Set ..CurrNode=$LI(catnode,3)
	Set tStruct=$LI(catnode,4)
	Set ..doXType=$LI(catnode,5)
	Set ..doNode=$LI(catnode,6)
	Set ..doVerbose=$LI(catnode,7)

	Set ..LocalType=$G($$$vaSchemaGbl(..Category,..CurrNode,"local"))
	Set ..LocalVal=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","value"))
	Set type=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","type"))
	Set ref=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","ref"))
	
	/* ref can be xml:....*/
	If (ref[":"),($piece(ref,":",1)="xml") {
		Set tRefType=""
		Set tRefTypeNSIndex=""
	} Else {
		Set tRefType=$P(ref,"^",2)
		Set tRefTypeNSIndex=$P(ref,"^")
	}
	/*	If ref is present then type and name cannot be present in the schema
		%XML.Utils.SchemaReader::FixReferences() sets type=ref if ref starts with xml: or includes a known namespace
	*/
	If type'["^" {
		Set ..Type=$select(type="xml:lang":"string",1:type)
		If (type[":") && ($piece(type,":",1)="xml") {
			Set ..TypeNSIndex = ""
		} Else {
			Set ..TypeNSIndex=1  ;; xs: namespace
		}
	} Else {
		Set ..Type=$P(type,"^",2)
		Set ..TypeNSIndex=$P(type,"^")
	}
	Set tName=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","name"))
	If tName="",..LocalType="attribute",type="xml:lang" {
		// If no name for xml:lang since implicit ref to xml:lang, then make up a name
		Set ..Name="xmllang"
		Set ..NameNSIndex=""
	} ElseIf tName="",..LocalType="attribute",(type[":"),($piece(type,":",1)="xml") {
		// Type is a ref to xml:space, xml:id or xml:base
		Set ..Name=type
		Set ..NameNSIndex=""
	} ElseIf tName="",..LocalType="attribute",(ref'="") {
		// Type is a ref to a namespace defined 
		Set ..Name=$TR(tRefType,".","~")
		Set ..NameNSIndex=tRefTypeNSIndex
	} Else {
		Set ..Name=$TR($P(tName,"^",2),".","~")
		Set ..NameNSIndex=$P(tName,"^",1)
	}
	Set ..OriginalName=..Name
	Set ..MemberTypes=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","memberTypes"))
	Set ..ItemType=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","itemType"))
	Set ..RefNo=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","ref#"))
	Set ..Req=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","req"))
	Set ..Base=$P($G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","base")),"^",2)
	Set ..BaseNSIndex=$P($G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","base")),"^")
	Set ..Min=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","minOccurs"))
	Set ..Max=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","maxOccurs"))
	Set ..Default=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","default"))
	Set ..Use=$G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","use"))
	Set ..Mixed=$Case($G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","mixed")),"true":1,1:1,:0)
	Set tFormQual=$Case($G($$$vaSchemaGbl(..Category,..CurrNode,"attrs","form")),"qualified":1,"unqualified":0,:"")

	If "list"=..LocalType {
		If ""=..Type {
			Set tNSIndex="$" ; illegal value
			If ..ItemType[":" {
				Set tPrefix=$P(..ItemType,":")
				Set tNSIndex=$S(""=tPrefix:"",1:..findNSIndex(tPrefix))
			}
			If "$"'=tNSIndex {
				Set ..Type=$P(..ItemType,":",2), ..TypeNSIndex=tNSIndex
			} Else {
				Set ..Type=..ItemType, ..TypeNSIndex=""
			}
		}
		// Set:""=..Max ..Max="*" don't let a list "repeat" by commenting out this line JSL4403
	} ElseIf "extension"=..LocalType {
		Set:""=tRefType tRefType=..Base,tRefTypeNSIndex=..BaseNSIndex
	} ElseIf "restriction"=..LocalType {
		Set:""=tRefType tRefType=..Base,tRefTypeNSIndex=..BaseNSIndex
	} ElseIf "any"=..LocalType {
		Set ..Name="any"
		Set ..OriginalName="any"
	} ElseIf "anyAttribute"=..LocalType {
		Set ..Name="anyAttr"
	} ElseIf ""'=tRefType && $Case(..LocalType,"element":1,"attribute":1,:0) {
		Set ..LocalType=..LocalType_"Ref"
	} Else {
		Set:""=..Type ..Type=..Base, ..TypeNSIndex=..BaseNSIndex
		$$$ASSERTNOLOG(""=..MemberTypes||("union"=..LocalType)&&(""=..ItemType))
	}
	Set tOpt=$Case(..LocalType,"attribute":("required"'=..Use), :("optional"=..Req)||(..Min=0))
	Set:""=..Min&&tOpt ..Min=0

	Set ..Max=$S("prohibited"=..Use:0, "unbounded"=..Max:"*", 1:..Max)
	Set ..Rep=$S(..Max="*":"()",..Max>0&&(..Min=1):"("_..Max_")",..Max>1:"("_..Max_")",1:"") // JSL5245, make ..Rep consistent with Min, Max attributes
	Set ..MinLen=""

	Set ..IsQual=$S(""'=tFormQual:tFormQual,1:"+"_..isDefQual())

	#; Prepare struct node in case there might be no children, fix struct type
	If ""'=tRefType {
		//$$$ASSERTNOLOG(..Type=""||(..Type=tRefType&&(..TypeNSIndex=tRefTypeNSIndex))) ; happened in kmehr.xsd
		Set ..Type=tRefType, ..TypeNSIndex=tRefTypeNSIndex
	}
	If ""'=..RefNo {
		#; Set up structNode and type elem based on referenced schema node id
		Set ..StructNode=..RefNo, tRefNoType=$P($G($$$vaSchemaGbl(..Category,..RefNo,"attrs","name")),"^",2), tRefNoTypeNSIndex=$P($G($$$vaSchemaGbl(..Category,..RefNo,"attrs","name")),"^")
		$$$ASSERTNOLOG((tRefType=""||(tRefNoType="")||(tRefType=tRefNoType)&&(tRefTypeNSIndex=tRefNoTypeNSIndex))&&(..Type=""||(tRefNoType="")||(..Type=tRefNoType&&(..TypeNSIndex=tRefNoTypeNSIndex))))
		Set:""'=tRefNoType tRefType=tRefNoType,tRefTypeNSIndex=tRefNoTypeNSIndex, ..Type=tRefNoType,..TypeNSIndex=tRefNoTypeNSIndex
		#dim tTypeElem As %String = ""
		$$$ASSERTNOLOG(..Type=""||($D($$$vaSchemaGbl(..Category,"<types>",..Type,..StructNode),tTypeElem)#2))
		If ""=..Type||(""=tTypeElem) {
			Set tTypeElem="CT"
			$$$ASSERTNOLOG(0_"Remove this code - it must never be used? !!!")
			Set ..Type=..LocalType_"/"_..CurrNode, tRefType=..Type,tRefTypeNSIndex=..TypeNSIndex
			Set $$$vaSchemaGbl(..Category,"<types>",..Type)=..StructNode, $$$vaSchemaGbl(..Category,"<types>",..Type,..StructNode)=tTypeElem, ..Type=tTypeElem_":"_..Type
		} Else {
			$$$ASSERTNOLOG(..Type'[":")
			Set ..Type=tTypeElem_":"_..Type, tRefType=..Type
		}
		// Eliminate duplicate reference to group via child and RefNo
		If $Case(..LocalType,"group":1,"attributeGroup":1,:0) && (""'=..StructNode) {
			Set tGrpRef=$O($$$vaSchemaGbl(..Category,..StructNode,"ch",""))
			If ""'=tGrpRef {
				Set tGrpCh=$O($$$vaSchemaGbl(..Category,..CurrNode,"ch",""))
				Set:tGrpRef=tGrpCh ..StructNode=""
			}
		}
	} ElseIf ""'=..Type {
		Set tBuiltin=$S(((..LocalType="attribute")&&(type[":") && ($piece(type,":",1)="xml")):1,1:..isXSDatatype(tKey,..Category,..Type,..TypeNSIndex))
		If 'tBuiltin {
			#; Set up structNode and type elem based on referenced type name
			Set ..StructNode=$G($$$vaSchemaGbl(..Category,"<types>",..Type_"$"_..TypeNSIndex))
			If ""'=..StructNode { Set ..Type=..Type_"$"_..TypeNSIndex }
			Else { Set ..StructNode=$G($$$vaSchemaGbl(..Category,"<types>",..Type)) }
			$$$ASSERTNOLOG(..Type'[":")
			If ..StructNode["," {
				#; In case of duplicates, pick the first "element" type in the list, if it's not us
				Set tListLen=$L(..StructNode,","), tSNode="", tFirstDSNode="", tEl=""
				For i=1:1:tListLen { Set tSN=$P(..StructNode,",",i)
					Continue:""=tSN||(tSN=..CurrNode)
					Set tSNode=tSN, tEl=$G($$$vaSchemaGbl(..Category,"<types>",..Type,tSNode))
					Quit:"CT"=tEl
					If ("DS"=tEl)&&(tFirstDSNode="") Set tFirstDSNode = tSNode					
				}
				#; If there was not a CT and there had been a DS use the first DS else use tSNode (either first CT or last tSNode
				If ((tEl'="CT")&&(tFirstDSNode'="")) {Set ..StructNode=tFirstDSNode} Else {Set ..StructNode=tSNode}
			}
			If ""=..StructNode {
				Set ..Type=$S(..Type[":":"", ""'=..TypeNSIndex:..TypeNSIndex, 1:"?")_":"_..Type
			} Else {
				#; existence of typeElem is certain because structNode exists
				Set tTypeElem=$$$vaSchemaGbl(..Category,"<types>",..Type,..StructNode)
				Set ..Type=tTypeElem_":"_..Type
			}
		} ElseIf "string"=..Type {
			Set ..Type=""
		} ElseIf ..Type'[":" {
			Set ..Type="xs:"_..Type
		}
	} Else {
		#; No type reference or builtin datatype
	}
	If ..Type="string"&&..isXSDatatype(tKey,..Category,"string",..TypeNSIndex) { Set ..Type="" }
	ElseIf ""=..Type { Set ..Type=tStruct }
	Quit $$$OK
}

ClassMethod isXSDatatype(pKey As %Integer, pSchemaCategory As %String, pType As %String, pTypeNSIndex As %String) As %Boolean
{
	Set tURI=$S('$L(pTypeNSIndex)||'$L(pType):"", 1:$G($$$vaSchemaGbl(pSchemaCategory,"ns","list",pTypeNSIndex,"uri")))
	Quit $Case($ZCVT(tURI,"L")
			,"http://www.w3.org/2001/xmlschema-datatypes":1
			,"http://www.w3.org/2001/xmlschema":1
			,:0)
	 	&& $D(^IRIS.Temp.XMLVDoc(pKey,"xsBuiltin",pType))
}

Method findNSIndex(pPrefix) As %String [ Internal ]
{
	Quit:""=pPrefix "$"
	Set tNSIndex="" For { Set tNSIndex=$O($$$vaSchemaGbl(..Category,"ns","list",tNSIndex))  Quit:""=tNSIndex
		Quit:$G($$$vaSchemaGbl(..Category,"ns","list",tNSIndex,"Prefix"))=pPrefix
	}
	Set:""=tNSIndex tNSIndex="$" ; illegal value
	Quit tNSIndex
}

Method isDefQual() As %String [ Internal ]
{
	Quit:""=..NameNSIndex ""
	Set tSub=$Case(..LocalType, "element":"ElementQualified", "attribute":"AttributeQualified", :"")  Quit:""=tSub "" ; yes if default for this type
	Quit:""'=$G($$$vaSchemaGbl(..Category,"ns","targ"))&&$D($$$vaSchemaGbl(..Category,0,"ch",..CurrNode)) 1+..CurrNode ; yes if top level w/TargetNamespace
	Quit $G($$$vaSchemaGbl(..Category,"ns","list",..NameNSIndex,tSub))
}

ClassMethod isDerived(pCategory, pStructType, pActualType) As %Boolean [ Internal ]
{
	Quit:pStructType=pActualType 1
	Set tStructNode=$G($$$vaSchemaGbl(pCategory,$P(pStructType,":"),$P(pStructType,":",2)))
	Quit:(pActualType="CT:"_$P($G($$$vaSchemaGbl(pCategory,tStructNode,"attrs","type")),"^")) 1
	Quit:(pActualType=$G($$$vaSchemaGbl(pCategory,$P(pStructType,":"),$P(pStructType,":",2),"meta","type"))) 1
	; Also allow the type of a single-property child property
	Quit 0
}

Method newChild(elno) [ Internal ]
{
	Set ..elno=elno
}

/// Merge non-prop facets up to current level
Method mergeFacets(pRef, txRef, iProp, iChild, ByRef iDocChild, ByRef nEnums) [ Internal ]
{
	//Set tHasDoc=($G(@txRef@("xtype"))["annotation")
	Set tLocalType=$G($$$vaSchemaGbl(..Category,..elno,"local"))
	If $Case(tLocalType,"sequence":0,"all":0,:1) {
		Set tHasDoc=tLocalType["annotation"
		// JSL5245 $$$ASSERTNOLOG((iProp=1)||(tHasDoc&&'iDocChild)) //||("skip"=$G($$$vaSchemaGbl(..Category,elno,"attrs","processContents"))))
		Set:tHasDoc iDocChild=iChild
		//Set tHasEnum=$G(@txRef@("xtype"))["enumeration"
		Set tHasEnum=tLocalType["enumeration"
		Set:tHasEnum nEnums=nEnums+1

		#; Save selected new top nodes, kill the rest, merge the children
		If tHasDoc||tHasEnum { ; don't record these xsd elements
			Kill:..doNode @txRef@("n")
			Kill:..doXType @txRef@("xtype")
		} Else {
			If ..doNode&&$D(@pRef@("n"),tN)&&$D(@txRef@("n"),tSN) Set @pRef@("n")=tN_","_tSN  Kill:txRef=$Name(@pRef@(iProp)) @txRef@("n")
			If ..doXType&&$D(@pRef@("xtype"),tXType)&&$D(@txRef@("xtype"),tSXT) Set @pRef@("xtype")=tXType_":"_tSXT  Kill:txRef=$Name(@pRef@(iProp)) @txRef@("xtype")
		}
		#; Merge non-prop facets of unnamed sub-trees up to current level
		$$$ASSERTNOLOG(tHasDoc||tHasEnum||$Case(..LocalType,"simpleType":1,"restriction":1,"annotation":1,"appinfo":1,:0)||$Case(tLocalType,"simpleType":1,"list":1,"documentation":1,"pattern":1,"rule":1,"report":1,"p":1,:'$G(@txRef))) ; ,"attribute":1,"element":1  "appinfo":1,
		$$$ASSERTNOLOG((""=$G(@txRef@("name")))&&'$D(@txRef@(iProp)))
		Set k=""  For { Set k=$O(@txRef@(k),1,txval) Quit:""=k
			Set kval="" If $D(@pRef@(k),kval)&&(kval'=txval)&&$Case(k, "desc":0, "app":0, "type":$P(kval,":")'?1(1"?",1.N), :1) {
				w:..doVerbose !,"!! Not merging pre-existing facet '"_k_"' with value '"_kval_"' of non-prop '"_tLocalType_"' child "_iProp_" with value '"_txval_"' into node "_..CurrNode
				Continue
			}
			Merge @pRef@(k)=@txRef@(k)
		}
	} Else {
		w:..doVerbose !,"!! Not merging pre-existing facet of non-prop '"_tLocalType_"' child "_iProp_" (node "_..elno_") into node "_..CurrNode
	}
	Kill:txRef=$Name(@pRef@(iProp)) @txRef
}

ClassMethod ElementExists(pElementSpec As %String = "") As %Boolean
{
	Set tClass=$ZCVT($P(pElementSpec,":",1),"U"), tCat=$P(pElementSpec,":",2), tElem=$P(pElementSpec,":",3)
	Quit:((""=tClass)||(""=tCat)||(""=tElem)) 0
	Quit ($D($$$vaSchemaGbl(tCat,tClass,tElem))#2'=0)
}

/// Get the description of an item or an indexed piece of an item
ClassMethod GetDescription(pElementSpec As %String, pItem As %Integer = "") As %String
{
	Set tElem=$ZCVT($P(pElementSpec,":",1),"U")
	Set tCategory=$P(pElementSpec,":",2)
	Set tStruct=$P(pElementSpec,":",3)
	Quit:(""=tElem)||(""=tCategory)||(""=tStruct) "" ; Must specify Class:Category:Struct
	Set tDesc=""
	Set tNode=$S(""=pItem:$G($$$vaSchemaGbl(tCategory,tElem,tStruct,"meta","desc")),1:$G($$$vaSchemaGbl(tCategory,tElem,tStruct,"meta",pItem,"desc")))
	S:""'=tNode tDesc=$G($$$vaSchemaGbl(tCategory,tNode,"chars"))
	If ""=tDesc {
		Set tBaseCat=$G($$$vaSchemaGbl(tCategory,"base"))
		Set:""'=tBaseCat tDesc=..GetDescription(tElem_":"_tBaseCat_":"_$P(pElementSpec,":",3,$L(pElementSpec,":")),pItem)
	}
	Quit tDesc
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pContentArrayName As %String, pArrayPos As %String) As %String
{
	Quit ""
}

/// Given a Schema category and a Document TypeName string, return the corresponding DocType (document structure)
ClassMethod ResolveSchemaTypeToDocType(pSchemaCategory As %String, pTypeName As %String, Output pStatus As %Status, pDoc As EnsLib.EDI.XML.Document = {$$$NULLOREF}) As %String
{
	Set pStatus=$$$OK, tPrefix=""
	Set:pTypeName[":" tPrefix=$P(pTypeName,":",1), pTypeName=$P(pTypeName,":",2,99)
	#; Ignore the NS prefix if any; it's no good here but it could have been used in the document to find the applicable NS URI
	If ((pSchemaCategory="")||(pTypeName="")) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty category '"_pSchemaCategory_"' or type name '"_pTypeName_"'")  Quit ""
		#; Find the root element namespace URI from the document
	Set tURI=$S('$IsObject(pDoc):"", '$D($$$vaSchemaGbl(pSchemaCategory)):"", 1:pDoc.GetValueAt("/1/namespace-uri()"))
	If tPrefix?1"$"1.N {
		#; Find the DS element in the schema that has the same name and namespace index
		Set tCnt=0, tDS=$E(pTypeName,1,*-1) For { Set tDS=$O($$$vaSchemaGbl(pSchemaCategory,"DS",tDS)) Quit:""=tDS||($P(tDS,"$")'=pTypeName)  Set tCnt=tCnt+1
			Set tNSnum=$G($$$vaSchemaGbl(pSchemaCategory,"DS",tDS,"ns"))
			If ""'=tNSnum&&($E(tPrefix,2,*)=tNSnum) { Set tCnt=0  Quit }
		}
		#; If there is only one matching name then use it even if the namespace doesn't match.
		Set:tCnt=1 tDS=pTypeName
	} ElseIf ""=tURI {
		Set tDS=pTypeName
	} Else {
		#; Find the DS element in the schema that has the same name and namespace URI
		Set tCnt=0, tDS=$E(pTypeName,1,*-1) For { Set tDS=$O($$$vaSchemaGbl(pSchemaCategory,"DS",tDS)) Quit:""=tDS||($P(tDS,"$")'=pTypeName)  Set tCnt=tCnt+1
			Set tNSnum=$G($$$vaSchemaGbl(pSchemaCategory,"DS",tDS,"ns"))
			If ""'=tNSnum&&($G($$$vaSchemaGbl(pSchemaCategory,"ns","list",tNSnum,"uri"))=tURI) { Set tCnt=0  Quit }
		}
		#; If there is only one matching name then use it even if the namespace doesn't match.
		Set:tCnt=1 tDS=pTypeName
	}
	Quit:""=tDS||'$D($$$vaSchemaGbl(pSchemaCategory,"DS",tDS)) ""
	Quit pSchemaCategory_":"_tDS
}

ClassMethod BuildCategoryMaps(pCategory As %String, pVerbose As %Integer = 0) As %Status [ Internal ]
{
	#; First clean out
	Set tSC=$$$OK,tElem=$O($$$vaSchemaGbl(pCategory,$C(0)),-1)  
	Kill $$$vaSchemaGbl(pCategory,"p")
	For {
		Set tElem=$O($$$vaSchemaGbl(pCategory,tElem))
		Quit:""=tElem
		Continue:tElem=+tElem ; skip raw nodes
		Set tDocStructName=""
		For {
			Set tDocStructName=$O($$$vaSchemaGbl(pCategory,tElem,tDocStructName))
			Quit:""=tDocStructName
			Kill $$$vaSchemaGbl(pCategory,tElem,tDocStructName,"meta")
			Kill $$$vaSchemaGbl(pCategory,tElem,tDocStructName,"array")
		}
	}
	#; Then refill
	Set tElem=$O($$$vaSchemaGbl(pCategory,$C(0)),-1)
	For {
		Set tElem=$O($$$vaSchemaGbl(pCategory,tElem))
		Quit:""=tElem
		#; skip everything but DS, CT and CG
		Continue:tElem=+tElem||$Case(tElem,"<types>":1,"src":1,"ns":1,"p":1,"ST":1,:0)
		Set tDocStructName=""
		For {
			Set tDocStructName=$O($$$vaSchemaGbl(pCategory,tElem,tDocStructName))
			Quit:""=tDocStructName
			Write:pVerbose !,"CALLING for "_tElem_" : "_tDocStructName
			Set tSC=..buildDocStructureMap(pCategory_":"_tElem_":"_tDocStructName,pVerbose)
			Quit:$$$ISERR(tSC)
			/* Check for DS total pull up due to complex types up e.g. no properties shown:

				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne")=1
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta")=0
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","d")="TheOne/MyP"
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","e")=1
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","element")="CT:Person"
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","n")="3,19:2(MyP):1(MyP)"
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","name")="MyP"
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","req")=1
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","type")="DS:TheOne"
				^EnsEDI.XML.Schema("Sample.EmployeeOne","DS","TheOne","meta","xtype")="element:sequence:element:complexType"

				Or

				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B")	= 	17
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta")	= 	0
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","d")	= 	"$1:Loop_1000B/$1:NM1_ReceiverName_1000B"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","desc")	= 	19
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","e")	= 	1
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","elementRef")	= 	"DS:NM1_ReceiverName_1000B"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","n")	= 	"22,806:21(NM1_ReceiverName_1000B):20(NM1_ReceiverName_1000B):17(NM1_ReceiverName_1000B)"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","name")	= 	"NM1_ReceiverName_1000B"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","ns")	= 	1
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","req")	= 	1
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","type")	= 	"DS:Loop_1000B"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","meta","xtype")	= 	"element:complexType:sequence:elementRef:element"
				^EnsEDI.XML.Schema("InterSystems_837P-1","DS","Loop_1000B","ns")	= 	1

				If so use the CT
			*/
			If (tElem="DS") {
				/* no reported properties */
				If $Get($$$vaSchemaGbl(pCategory,"DS",tDocStructName,"meta"),0)=0 {
					/* subject of a pull up */
					If ($Length($Get($$$vaSchemaGbl(pCategory,"DS",tDocStructName,"meta","xtype")),":")>2) {
						/* look to see if element=xxx or elementRef=xxxx */
						Write:pVerbose !,"LOOKING if need to pull back child structure for DS:"_tDocStructName
						Set tStructType="DS"
						Set tStructure=tDocStructName
						Set tPullbackStructPropertyCount = ..findTypeAndStructureToPullBack(pCategory,.tStructType,.tStructure)
						If tPullbackStructPropertyCount>0 {
							Write:pVerbose !,"PULLING back "_tStructType_":"_tStructure_" structure into "_tElem_" : "_tDocStructName
							Set $$$vaSchemaGbl(pCategory,"DS",tDocStructName,"meta")=tPullbackStructPropertyCount
							For prop=1:1:tPullbackStructPropertyCount {
								Merge $$$vaSchemaGbl(pCategory,"DS",tDocStructName,"meta",prop)=$$$vaSchemaGbl(pCategory,tStructType,tStructure,"meta",prop)
							}
							Merge $$$vaSchemaGbl(pCategory,"DS",tDocStructName,"meta","pnames")=$$$vaSchemaGbl(pCategory,tStructType,tStructure,"meta","pnames")
							/* Rebuild "p" Content Array if no entries */
							If $Get($$$vaSchemaGbl(pCategory,"p","DS:"_tDocStructName),0) = 0 {
								/* Need to remove the "p" array entry if exists before calling recordStructure */
								Kill $$$vaSchemaGbl(pCategory,"p","DS:"_tDocStructName)
								Set tSC = ..recordStructure(pCategory_":DS:"_tDocStructName)
								Quit:$$$ISERR(tSC)
							}
						}
					}
				}
			}
		}
	}
	If $$$ISERR(tSC) Quit tSC
	#; Then preen and enrich
	Set tElem=$O($$$vaSchemaGbl(pCategory,$C(0)),-1)
	For {
		Set tElem=$O($$$vaSchemaGbl(pCategory,tElem))
		Quit:""=tElem
		#; skip everything but DS, CT and CG
		Continue:tElem=+tElem||$Case(tElem,"<types>":1,"src":1,"ns":1,"p":1,"ST":1,:0)
		Set tDocStructName=""
		For {
			Set tDocStructName=$O($$$vaSchemaGbl(pCategory,tElem,tDocStructName))
			Quit:""=tDocStructName
			Write:pVerbose !,"Enriching for "_tElem_" : "_tDocStructName
			Set tSC=..enrichDocStructureMap($Name($$$vaSchemaGbl(pCategory,tElem,tDocStructName,"meta")))
			Quit:$$$ISERR(tSC)
		}
	}
	Quit tSC
}

ClassMethod buildDocStructureMap(pType As %String, pVerbose As %Integer) As %Status [ Internal ]
{
	Set tMetaArrayName=$Name($$$vaSchemaGbl)
	Set tSC=..buildMetaArray(tMetaArrayName,pType,.pVerbose)  Quit:$$$ISERR(tSC) tSC
	Quit:$P(pType,":",2)'="DS" $$$OK
 	Set tRef=$Name($$$vaSchemaGbl)_"("""_$replace(pType,":",""",""")_""")"
	Set tSC = ..recordStructure(pType,$Name($$$vaSchemaGbl))  Quit:$$$ISERR(tSC) tSC
	Do ..buildDocStructureMapLoop(tMetaArrayName,.tSchemaPathMap,"","=")
	Kill @tRef@("map")
	Merge @tRef@("map")=tSchemaPathMap
	Quit tSC
}

ClassMethod buildDocStructureMapLoop(pMetaArrayName As %String, ByRef pSchemaPathMap As %String, pNamePrefix As %String, pValuePrefix As %String) [ Internal ]
{
	Set padding=$L($O(@pMetaArrayName@("name"),-1))
	Set index="" For { Set index=$O(@pMetaArrayName@(index))  Quit:""=index  Continue:index'=+index
		Set value=$TR($J(index,padding)," ","0")
		If @pMetaArrayName@(index,"name")["()" set value=value_",*"
		If '$G(@pMetaArrayName@(index)) {
			Set type=$P($P(@pMetaArrayName@(index,"type"),":",2,99),"(")
			Set pSchemaPathMap(pNamePrefix_@pMetaArrayName@(index,"name"))=pValuePrefix_value_"|"_type
		} Else {
			Set nestedref=$S(pMetaArrayName[")":$E(pMetaArrayName,1,*-1)_","_index_")",1:pMetaArrayName_"("_index_")")
			Set nameprefix=pNamePrefix_@pMetaArrayName@(index,"name")
			Do ..buildDocStructureMapLoop(nestedref,.pSchemaPathMap,nameprefix_".",pValuePrefix_value_",")
		}
	}
}

ClassMethod enrichDocStructureMap(pMetaArrayName As %String) [ Internal ]
{
	#; Build the "dnames" DOM alias index for every property of the given structure
	#; if the "dnames" index is absent it means it's identical to the "pnames" index
	#; If a "d" entry is absent it means it's identical to the "name" entry
	#; If a "d" entry is set to "" it means there is no DOM alias
	#; if the "dnames" index contains an entry ">" its value is a list of  ids of properties that have no DOM alias
	Set tSC=$$$OK, tNoDOMs="", tAnyProp=0
	Set index="" For { Set index=$O(@pMetaArrayName@(index))  Quit:""=index  Continue:index'=+index||'index
		Set tMetaPropRef=$Name(@pMetaArrayName@(index))
		If '$D(@tMetaPropRef@("d"),tDOMName) {
			Set tDOMName=..getDName(tMetaPropRef)
			$$$ASSERT(""'=tDOMName)
		} ElseIf ""=tDOMName { Set tNoDOMs=tNoDOMs_","_index }
		ElseIf tDOMName=($S($D(@tMetaPropRef@("a")):"@",1:"")_$S(""=$G(@tMetaPropRef@("ns")):"",1:"$"_@tMetaPropRef@("ns")_":")_$P(@tMetaPropRef@("name"),"(")) { Kill @tMetaPropRef@("d") }
		Else { Set tAnyProp=1 }

		If ""'=tDOMName { Set dnames(tDOMName)=index }
		If $G(@tMetaPropRef) {
			Do ..enrichDocStructureMap(tMetaPropRef)
		}
		#;  Else { Set type=$P($P(@pMetaArrayName@(index,"type"),":",2,99),"(")  - don't drill down; we'll hit the 'type' structure when we come to it from the top
	}
	Merge:""'=tNoDOMs||tAnyProp @pMetaArrayName@("dnames")=dnames
	Set:""'=tNoDOMs @pMetaArrayName@("dnames",">")=$E(tNoDOMs,2,*)
	Quit tSC
}

ClassMethod recordStructure(pDocStruct As %String = "", pArrayName As %String = {$Name($$$vaSchemaGbl)}) As %Status [ Internal ]
{
	#Dim tSC As %Status = $$$OK
	#Dim e As %Exception.AbstractException
	
	#Dim tCategory, tElement, tStructure, tDocStructNoCat As %String
	#Dim tPiece, tName As %String
	#Dim tMetaGblRef, tMetaGblRef2 As %String
	#Dim tTopType As %String
	#Dim tPreviousType As %String
	#Dim tXProp As %String 
	#Dim tCount As %Integer
	#Dim i, iRow As %Integer
	
	Try {
		Set tCategory=$P(pDocStruct,":",1)
		Set tElement=$P(pDocStruct,":",2)
		Set tStructure=$P(pDocStruct,":",3)
		Set tDocStructNoCat = $P(pDocStruct,":",2)_":"_$P(pDocStruct,":",3)

		If ((tCategory'="")&&(tElement'="")&&(tStructure'="")&&('($D(@pArrayName@(tCategory,"p",tDocStructNoCat))#2))) {
			Set tXProp=$P(tStructure,"#",2,$L(tStructure,"#")), tStructure=$P(tStructure,"#")
			Set tMetaGblRef=$Name(@pArrayName@(tCategory,tElement,tStructure,"meta"))
			For i=1:1:$L(tXProp,"#") { Set tPiece=$P(tXProp,"#",i)  Continue:""=tPiece
				Set $E(tMetaGblRef,$L(tMetaGblRef))=","_tPiece_")"
				Set tName=$G(@tMetaGblRef@("name"))
				Set tStructure=tStructure_"#"_tPiece
			}
			If $D(@tMetaGblRef) {
				Set tTopType=""
				For {
					Set tCount=$G(@tMetaGblRef)
					Set tPreviousType=tTopType, tTopType=$G(@tMetaGblRef@("type"))
					Quit:tPreviousType=tTopType
					Quit:""=tTopType||tCount
					Set tElement=$P(tTopType,":",1)
					Set tStructure=$P(tTopType,":",2)
					Set tMetaGblRef2=$Name(@pArrayName@(tCategory,tElement,$P(tStructure,"("),"meta"))
					Quit:'$D(@tMetaGblRef2)
					Set tMetaGblRef=tMetaGblRef2
				}
			}
			If $D(@tMetaGblRef) {
				Set @pArrayName@(tCategory,"p",tDocStructNoCat)=tCount
				If (tCount>0) {
					For iRow=1:1:tCount {
						Set tSC = ..recordProperty(pDocStruct,pArrayName,iRow,$Name(@tMetaGblRef@(iRow)),tCategory,tElement,tStructure)
						If $$$ISERR(tSC) Quit
					}
				}				
			}
		}
	} Catch e {Set tSC = e.AsStatus()}

	Quit tSC
}

ClassMethod recordProperty(pDocStruct As %String, pArrayName As %String, pRow As %String, pMetaGblRefRow As %String, pCategory As %String, pParentElement As %String, pParentStructure As %String) As %Status [ Internal, Private ]
{
	#Dim tPropName, tPropType, tElem, tDocStructNoCat As %String
	#Dim tNextDocStruct, tTypeToRecord As %String
	#Dim tNum As %Integer
	#Dim tSC As %Status = $$$OK
	#Dim e As %Exception.AbstractException
	
	Try {
		Set tPropName=$G(@pMetaGblRefRow@("name")), tPropType=$G(@pMetaGblRefRow@("type"))
		Set tElem=$P(tPropType,":") Set:$Case($E(tElem),"?":1,"#":1,:0) tElem="" Set:""'=tElem tPropType=$P(tPropType,":",2,$L(tPropType,":"))
		Set tNum=+$P(pMetaGblRefRow,",",$L(pMetaGblRefRow,","))
		If $G(@pMetaGblRefRow) {
			Set tNextDocStruct = pCategory_":"_pParentElement_":"_$P(pParentStructure,"(")_"#"_pRow
			Set tTypeToRecord = pParentElement_":"_$P(pParentStructure,"(")_"#"_pRow
		} Else {
			Set tPropType=$P(tPropType,"(")
			Set:tElem_tPropType="" tElem="xs", tPropType="string"
			Set tNextDocStruct = pCategory_":"_tElem_":"_tPropType
			Set tTypeToRecord = tElem_":"_tPropType
		}

		Set tDocStructNoCat = $P(pDocStruct,":",2)_":"_$P(pDocStruct,":",3)
		If '($D(@pArrayName@(pCategory,"p",tDocStructNoCat,tNum,"name"))#2) {
			Set @pArrayName@(pCategory,"p",tDocStructNoCat,tNum,"name")=tPropName
			Set @pArrayName@(pCategory,"p",tDocStructNoCat,tNum,"type")=tTypeToRecord
			Set tSC = ..recordStructure(tNextDocStruct,pArrayName)
			If $$$ISERR(tSC) Quit
		}
	} Catch e {Set tSC = e.AsStatus()}
	
	Quit tSC
}

ClassMethod populateArray(pReturnArray As %String, pCategory As %String, pElementStructure As %String, pMaxLevels As %Integer = {..#MAXCONTENTARRAYDEPTH}, pThisLevel As %Integer = 0) As %Status [ Internal ]
{
	#Dim tSC As %Status = $$$OK
	#Dim e As %Exception.AbstractException
	#Dim tCnt,tPropPos As %Integer
	#Dim tNextReturnArray As %String

	Try {
		Set pThisLevel= pThisLevel+1
		Set tCnt = $G($$$vaSchemaGbl(pCategory,"p",pElementStructure),0)
		Set @pReturnArray=tCnt
		For tPropPos=1:1:tCnt {
			Set @pReturnArray@(tPropPos)=$G($$$vaSchemaGbl(pCategory,"p",$G($$$vaSchemaGbl(pCategory,"p",pElementStructure,tPropPos,"type"),"x")),0)
			Set @pReturnArray@(tPropPos,"name")=$G($$$vaSchemaGbl(pCategory,"p",pElementStructure,tPropPos,"name"))
			Set @pReturnArray@(tPropPos,"type")=$G($$$vaSchemaGbl(pCategory,"p",pElementStructure,tPropPos,"type"))
			If (pThisLevel<pMaxLevels)&&@pReturnArray@(tPropPos) {
				Set tNextReturnArray=$Name(@pReturnArray@(tPropPos))
				Set tSC = ..populateArray(tNextReturnArray,pCategory,@pReturnArray@(tPropPos,"type"),pMaxLevels,pThisLevel)
				If $$$ISERR(tSC) Quit
			}
		}
	} Catch e {Set tSC = e.AsStatus()}
	
	Quit tSC
}

/// Recurse drilling for a structure that has been pulled all the way up to find child structure to pull back.
ClassMethod findTypeAndStructureToPullBack(pCategory As %String, ByRef pStructType As %String, ByRef pStructure As %String) As %Integer [ Internal ]
{
	/* Default to No element or elementRef type */
	#Dim tStructPropCount = -1
	If ($Data($$$vaSchemaGbl(pCategory,pStructType,pStructure,"meta","element"),elementEntry)#2)||($Data($$$vaSchemaGbl(pCategory,pStructType,pStructure,"meta","elementRef"),elementEntry)#2) {
		Set pStructType=$Piece(elementEntry,":",1)
		Set pStructure=$Piece(elementEntry,":",2)
		If (pStructure'="") {
			Set tStructPropCount = $Get($$$vaSchemaGbl(pCategory,pStructType,pStructure,"meta"),0)
			/* need to drill down to first CT/DS element/elementRef with more than one prop but quit if there aren't any*/
			While (+tStructPropCount=0) && (pStructure'="") {
				Set tStructPropCount = ..findTypeAndStructureToPullBack(pCategory, .pStructType, .pStructure)
			}
		}
	}
	Return tStructPropCount
}

}
