/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// VDoc Schema classmethods and queries
Class EnsLib.EDI.SEF.Schema [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

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
Query DocStructures(Category As %String = "", IncludeBase As %Boolean = 0, SchemaFamily As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "DocStructure:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod DocStructuresExecute(ByRef qHandle As %Binary, Category As %String = "", IncludeBase As %Boolean = 0, SchemaFamily As %String = "") As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Continue:$Case(SchemaFamily,"":0, $P($G($$$vaSchemaGbl(k)),"|",5):0, :1)
		Set Std=+$G($$$vaSchemaGbl(k,"std"))
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
		Set qHandle=$O($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),qHandle))
		Continue:("std"=qHandle)||(":SEF"=qHandle)
		Quit:""'=qHandle
		Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))
	}
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set tDesc=..GetDescription("DS:"_tCategory_":"_qHandle)
	Set tStd=+$G($$$vaSchemaGbl(tCategory,"std"))
	Set Row=$LB(tCategory_":"_qHandle,tDesc,tStd)
	Quit $$$OK
}

ClassMethod DocStructuresClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DocStructuresFetch ]
{
	Kill qHandle
	Quit $$$OK
}

Query TypeCategories(Standard As %String = "", SchemaFamily As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String")
{
}

ClassMethod TypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "", SchemaFamily As %String = "") As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Continue:$Case(SchemaFamily,"":0, $P($G($$$vaSchemaGbl(k)),"|",5):0, :1)
		Set Std=+$G($$$vaSchemaGbl(k,"std"))
		If $Case(Standard,"0":Std,"+":'Std,"":1,:$ZCVT(Standard,"L")=$E($ZCVT(k,"L"),1,$L(Standard))) {
			Set iVer=$I(qHandle("ver")), qHandle("ver",$S(Std:iVer,1:"u"_iVer))=k ; sort standard ones first
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver",""))
	Quit $$$OK
}

ClassMethod TypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = TypeCategoriesExecute ]
{
	Kill Row Set Row=""
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))
	Set tDesc=$P($G($$$vaSchemaGbl(tCategory)),"|",4)
	Set tStd=+$G($$$vaSchemaGbl(tCategory,"std"))
	Set tBase=$G($$$vaSchemaGbl(tCategory,"base"))
	Set Row=$LB(tCategory,tDesc,tStd,tBase)
	Quit $$$OK
}

ClassMethod TypeCategoriesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = TypeCategoriesFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of schema categories and segment types and segment fields for the corresponding document class. <br/>
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
/// If <var>ExpandedDocType</var> is: <br/>
///  0 - return SegTypes as Category:SegName <br/>
///  1 - return SegTypes as Category:DocStruct:Segment-Ordinal <br/>
Query SegTypes(Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0, SchemaFamily As %String = "", ExpandedDocType As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "SegType:%String,Field:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod SegTypesExecute(ByRef qHandle As %Binary, Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0, SchemaFamily As %String = "", ExpandedDocType As %Boolean = 0) As %Status
{
	Set CatSeg=$P(Category,":",2,$L(Category,":")), Category=$P(Category,":",1)
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Continue:$Case(SchemaFamily,"":0, $P($G($$$vaSchemaGbl(k)),"|",5):0, :1)
		Set Std=+$G($$$vaSchemaGbl(k,"std"))
		If $Case(Category,"0":Std,"+":'Std,"":1,:$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set iVer=$I(qHandle("ver")), qHandle("ver",$S(Std:iVer,1:"u"_iVer))=k ; sort standard ones first
		}
	}
	Set qHandle("ver")=0, qHandle("seg")="", qHandle("fldkey")="", qHandle("Level")=Level, qHandle("CatSeg")=CatSeg, qHandle("doc")="", qHandle("expanded")=ExpandedDocType
	Quit $$$OK
}

ClassMethod SegTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = SegTypesExecute, PublicList = qHandle ]
{
	Kill Row Set Row=""
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK

	For {
		If ""=qHandle("doc") {
			Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Quit:""=qHandle("ver")
		}
		If ""=qHandle("seg") {
			Set qHandle("doc")=$O($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc")))  Continue:(""=qHandle("doc"))||(":SEF"=qHandle("doc"))
		}
		If $Case(qHandle("Level"), 0:1, :""=qHandle("fldkey")) {
			If ""'=qHandle("CatSeg") {
				Set qHandle("seg")=$S(""=qHandle("seg"):qHandle("CatSeg"), 1:"")
				If ""'=qHandle("seg")&&(""=$P(qHandle("seg"),"-",2)) {
					; scan for ordinal in case it wasn't supplied in CatSeg
					Set tOrd=""  For i=1:1 { Quit:'$D($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),"m",i),tSeg)  If qHandle("seg")=$P(tSeg,"|",2)  Set tOrd=$P(tSeg,"|",3) Quit }
					Set:tOrd'="" qHandle("seg")=qHandle("seg")_"-"_tOrd
				}
				Set:((""'=qHandle("seg"))&&('$D($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg"))))) qHandle("seg") = ""
			} Else {
				Do {
					Set qHandle("seg")=$O($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg")))
				} While $ZCVT($E(qHandle("seg")),"U")'=$E(qHandle("seg"))
			}
			Continue:""=qHandle("seg")
			Quit:""'=qHandle("seg")&&(0=qHandle("Level"))
			Set tSC=..getFieldsContentArray(.tSegFields,"source",qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg"),qHandle("Level"))
			#; ignore tSC error - make do with what we got
			Merge qHandle("flds")=tSegFields
			Set qHandle("fldkey")="qHandle(""flds""", qHandle("fld")=""
		}
		Set tFld="" For {
			Set tCnt=$G(@(qHandle("fldkey")_")"),0)
			Set qHandle("fld")=qHandle("fld")+1
			If qHandle("fld") > tCnt { ; pop up a level
				If qHandle("fldkey")="qHandle(""flds""" Set qHandle("fldkey")=""  Quit
				Set tLen=$L(qHandle("fldkey"),",")
				Set qHandle("fld")=$P(qHandle("fldkey"),",",tLen)
				Set qHandle("fldkey")=$P(qHandle("fldkey"),",",1,tLen-1)
			} Else {
				Set qFldDown=qHandle("fldkey")_","_qHandle("fld")
				If $G(@(qFldDown_")"),0) { ; has subfields; push down a level
					Set qHandle("fldkey")=qFldDown, qHandle("fld")=""
				}
				Set tFld=$$fldName(qFldDown) Quit
			}
		}
		Quit:""'=tFld
		Kill qHandle("flds")
	}
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",qHandle("ver"))
	If qHandle("Level")=0 {
		Set tFld="", tDesc=..GetDescription("SS:"_tCategory_":"_qHandle("doc")_":"_qHandle("seg"))
	}
	Set tStd=+$G($$$vaSchemaGbl(tCategory,"std"))
	Set tSegType = tCategory_":"_$S(qHandle("expanded"):qHandle("doc")_":"_$P(qHandle("seg"),"!"),1:$P($P(qHandle("seg"),"!"),"-"))
	Set Row=$LB(tSegType,tFld,tDesc,tStd)
	Quit $$$OK
fldName(qFld)
	Set tName="", tLen=$L(qFld,",")
	For i=2:1:tLen {
		Set tName=tName_"."_@($P(qFld,",",1,i)_",""name"")")
	}
	Set tDesc=..GetDescription("ES:"_qHandle("ver",qHandle("ver"))_":"_qHandle("doc")_":"_qHandle("seg"),$P(qFld,",",2,tLen))
	Quit $E(tName,2,*)
}

ClassMethod SegTypesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = SegTypesFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Get all properties for a given document structure
ClassMethod GetContentArray(Output pContents, pMode As %String, pType As %String = "", pLevel As %Integer, pIncludeBase As %Boolean = 0) As %Status
{
	Quit:$G(pLevel)'=1||($G(pMode)'="source") ..buildContentArray(.pContents,.pMode,pType,.pLevel)
	Set tStructCategory=$P(pType,":"), tStructName=$P(pType,":",2)
	If (tStructCategory="")||(tStructName="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:name'.")
	Set tBaseCat=tStructCategory, tSC=$$$OK
	For {
		If ""=$G($$$vaSchemaGbl(tBaseCat,tStructName)) Set tSC=$$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' not defined.")  Quit
		If '$D($$$vaSchemaGbl(tBaseCat,tStructName,"array")) Set tSC=$$$ERROR($$$EnsErrGeneral,"No content array is built for Document Structure '"_pType_"'.")  Quit
		Quit:$$$ISOK(tSC)||'pIncludeBase
		Set tBaseCat=$G($$$vaSchemaGbl(tBaseCat,"base"))
		Quit:""=tBaseCat
		Set tSC=$$$OK ; go around and try again on base schema
	} Quit:$$$ISERR(tSC) tSC
	Set tRef=$G(pContents)
	If $Case($E($G(pContents)),"%":1,"^":1,:0) { Kill @pContents  Merge @pContents=$$$vaSchemaGbl(tBaseCat,tStructName,"array") }
	Else { Kill pContents  Merge pContents=$$$vaSchemaGbl(tBaseCat,tStructName,"array") }
	Quit $$$OK
}

/// Get all properties for a given document structure
ClassMethod buildContentArray(Output pContents, pMode As %String = "source", pType As %String, pLevel As %Integer = 0) As %Status
{
	Set tStructCategory=$P(pType,":"), tStructName=$P(pType,":",2)
	If (tStructCategory="")||(tStructName="") Quit $$$ERROR($$$EnsEDIInvalidDocType,pType)
	If '$D($$$vaSchemaGbl(tStructCategory)) Quit $$$ERROR($$$EnsEDIUnknownCategoryName,tStructCategory)
	Set tSchema=$G($$$vaSchemaGbl(tStructCategory,tStructName))
	Quit:""=tSchema $$$ERROR($$$EnsEDIUnknownDocumentTypeName,tStructCategory,tStructName)
	Set tSC=$$$OK
	Do ..getSegsContentArray(.pContents,$ZCVT(pMode,"L"),tStructCategory,tStructName,"","",pLevel,.tSC)
	Quit tSC
}

ClassMethod getSegsContentArray(Output pContents, pMode As %String, pCategory As %String, pTransName As %String, pStructItem As %String, pLoopName As %String, pLevel As %Integer, Output pSC As %Status = {$$$OK}) As %Integer
{
	#; Decide where contents should be stored
	Set tRef=$G(pContents)
	If ("%"=$E(tRef)||("^"=$E(tRef))) { Kill @tRef }
	Else {
		Kill pContents  Set tRef="%local"  New %local
	}
	#; Walk through the segment structure of the document
	Set iProp=0
	For { Set pStructItem=$Order($$$vaSchemaGbl(pCategory,pTransName,"m",pStructItem),1,tItemData)  Quit:""=pStructItem

		#; Determine the item category according to ItemType
		Set tItemType=$Piece(tItemData,"|")
		Set tCat=$Case(tItemType,"lb":1,"le":-1,"s":0,:"")
		If 0=tCat {
			#; This is a segment; pick out the name, ordinal, requirement and repetition count
			#; Form the SegmentType from a combination of SegName, match field key, and SegOrdinal
			Set tSegName=$Piece(tItemData,"|",2)
			If tSegName="HL" Set tKey=$P(tItemData,"|",9)  Set:""'=tKey tSegName=tSegName_"!3="_tKey
			Set tSegName=tSegName_"-"_$Piece(tItemData,"|",3)

			#; The Segment is optional if the segment is not marked as mandatory
			Set tOpt=$Piece(tItemData,"|",6)'="M", tReps=$Piece(tItemData,"|",8)

			#; If the number of repeats is 0 then indicate that there are no repeats allowed
			If ($Extract(tReps)'=">")&&(tReps<=1) Set tReps=""

			Set iProp=iProp+1
			If pLevel>1||'pLevel {
				#; Retrieve the fields content array
				Set pSC=..getFieldsContentArray(.tFldContents,pMode,pCategory,pTransName,tSegName,pLevel) 
				If $$$ISERR(pSC) Quit

				#; Merge the field contents with the segment contents structure
				Merge @tRef@(iProp)=tFldContents Kill tFldContents
			}
			#; Else No descendants at this level

			#; Record the name,type and requirement
			Set tSel=$Select(tReps'="":"()",1:"")
			Set @tRef@(iProp,"name")=tSegName_tSel
			Set @tRef@(iProp,"type")="SS:"_pCategory_":"_pTransName_":"_tSegName_tSel
			Set:tOpt @tRef@(iProp,"opt")=1
		} ElseIf tCat>0 {
			#; Pick out the loop name,requirement and repetitions
			Set tLoopName=$Piece(tItemData,"|",2)

			#; The Loop is optional if the Loop is not marked as mandatory
			Set tOpt=($Piece(tItemData,"|",4)'="M"), tReps=$Piece(tItemData,"|",5) 

			#; If the number of repeats is 0 then indicate that there are no repeats allowed
			If ($Extract(tReps)'=">")&&(tReps<=1) Set tReps=""

			Set pStructItem=..getSegsContentArray(.tLoopContents,pMode,pCategory,pTransName,pStructItem,tLoopName,pLevel,.pSC)  
			If $$$ISERR(pSC) Quit

			#; Merge the loop contents into the structure
			Set iProp=iProp+1
			Merge @tRef@(iProp)=tLoopContents Kill tLoopContents

			#; Form a subscripted reference if loop can be repeated
			If tReps'="" Set tLoopName=tLoopName_"()"

			#; Record the name and type, and requirement
			Set @tRef@(iProp,"name")=tLoopName
			Set @tRef@(iProp,"type")="SS:"_pCategory_":"_pTransName_":Loop-"_tLoopName
			Set:tOpt @tRef@(iProp,"opt")=1
		} ElseIf tCat < 0 { 
			$$$ASSERT(pLoopName=$Piece(tItemData,"|",2))
			Quit
		} Else {
			#; Ignore tables
		}
	}
	Set @tRef=iProp
	If tRef="%local" Merge pContents=%local

	#; Return the number of items
	Quit pStructItem
}

/// Given a segment type, extract the content array for the fields (items)
ClassMethod getFieldsContentArray(Output pContents, pMode As %String, pCategory As %String, pTransName As %String, pSegType As %String, pLevel As %Integer) As %Status
{
	Kill pContents Set tSC=$$$OK
	Do {
		If pSegType="" Set tSC=$$$ERROR($$$EnsEDIInvalidSegmentTypeName,pSegType) Quit

		Set tOrd=+$P(pSegType,"-",2) $$$ASSERT(tOrd)

		If '$D($$$vaSchemaGbl(pCategory,pTransName,"o",tOrd))#2 Set tSC=$$$ERROR($$$EnsEDIUnknownSegmentTypeName,pSegType)  Quit

		#; Indices for elements, composites
		Set tItemIndex=0,tI="" For { Set tI=$O($$$vaSchemaGbl(pCategory,pTransName,"o",tOrd,tI),1,tItemData)  Quit:""=tI
			// If $Piece(tItemData,"|",3)="." Continue

			Set tRep=$P(tItemData,"|",7), tItemIndex=tItemIndex+1
			$$$ASSERT(tItemIndex=tI)
			Set pContents(tItemIndex,"name")=":"_$P(tItemData,"|",8)_$S(tRep>1:"()",1:"")
			Set pContents(tItemIndex,"type")=$P(tItemData,"|",4)_$S(tRep>1:"("_tRep_")",1:"")

			If $Extract(tItemData)="C"&&((pLevel>=2)||'pLevel) {
				#; Composite, have to go down one more level
				Set tEleIndex=0,tE="" For { Set tE=$O($$$vaSchemaGbl(pCategory,pTransName,"o",tOrd,tI,tE),1,tEleData)  Quit:""=tE
					// If $Piece(tEleData,"|",3)="." Continue

					Set tEleIndex=tEleIndex+1
					$$$ASSERT(tEleIndex=tE)
					Set pContents(tItemIndex,tEleIndex,"name")=$P(tEleData,"|",8)
					Set pContents(tItemIndex,tEleIndex,"type")=$P(tEleData,"|",4)
				}
				Set pContents(tItemIndex)=tEleIndex Kill tEleIndex
			}
			If $$$ISERR(tSC) Quit
		}
		Set pContents=tItemIndex
	} While 0
	Quit tSC
}

ClassMethod ElementExists(pElementSpec As %String = "") As %Boolean
{
	Set tClass=$ZCVT($P(pElementSpec,":",1),"U"), tCat=$P(pElementSpec,":",2), tTrans=$P(pElementSpec,":",3), tElem=$P(pElementSpec,":",4), tOrd=$P(tElem,"-",2)
	Quit:((""=tClass)||(""=tCat)||(""=tTrans)) 0
 //w "tClass,tCat,tTrans,tElem="_tClass,tCat,tTrans,tElem,"<br>"
	Set tDocInfo=$G($$$vaSchemaGbl(tCat))  Quit:""=tDocInfo 0
	Set tAgency=$Piece(tDocInfo,"|"), tRef=$Piece(tDocInfo,"|",5)

	//w:tClass="SS" $D($$$vaSchemaGbl(tCat,tTrans,"o",$P(tElem,"-",2)),tIndex)
	//w:tClass="SS" $D($$$vaSchemaGbl(tCat,tTrans,"m",tIndex),tDesc)

	Quit $Case(tClass
	,"DS":''$D($$$vaSchemaGbl(tCat,tTrans))
	,"SS": ""'=tOrd
		&& $D($$$vaSchemaGbl(tCat,tTrans,"o",tOrd),tIndex)
		&& $D($$$vaSchemaGbl(tCat,tTrans,"m",tIndex),tDesc)
		&& ($P($P(tElem,"!"),"-")=($P(tDesc,"|",2))
		&& ($P(tElem,"-",2)=$P(tDesc,"|",3)))
	,"ES": 1  ; !!!
	,"CS": 1  ; !!!
	,:0)
}

/// Get the description of an item or an indexed piece of an item
ClassMethod GetDescription(pElementSpec As %String, pItem As %Integer = "") As %String
{
	Set tClass=$ZCVT($P(pElementSpec,":",1),"U"), tCat=$P(pElementSpec,":",2), tElem=$P(pElementSpec,":",3), tElemX=$P(pElementSpec,":",4)
	Quit:((""=tClass)||(""=tCat)||((""=tElem)&&($Case(tClass,"IG":0,"SS":0,:1)))||((""=tElemX)&&($Case(tClass,"SS":1,"ES":1,"CS":1,:0)))) ""

	Set tDocInfo=$G($$$vaSchemaGbl(tCat))  Quit:""=tDocInfo ""
	Set tAgency=$Piece(tDocInfo,"|"), tRef=$Piece(tDocInfo,"|",5)
	Set tGblRef=$Name($$$vaSchemaGbl)_"("""_tCat_""","""_tElem_""",""o"","_$P($P(tElemX,"!"),"-",2)_","_pItem_")"
	Quit $Case(tClass
				,"IG":$P(tDocInfo,"|",4)
				,"DS":$Get($$$vaSchemaGbl(tCat,tElem))
				,"SS":$Get($$$vaSchemaDescGbl(tAgency,tRef,"SEG",$P($P(tElemX,"!"),"-")))
				,"ES":$Get($$$vaSchemaDescGbl(tAgency,tRef,"ELEM",$P($G(@tGblRef,"|-"),"|",2)))
				,"CS":$Get($$$vaSchemaDescGbl(tAgency,tRef,"COMP",$P($G(@tGblRef,"|-"),"|",2)))
				,:"")
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pArrayName As %String, pArrayPos As %String) As %String
{
	Set tSeg=1,tAlias=""  For i=1:1:$L(pArrayPos,",") {
		Set tPiece=@(pArrayName_"("_$P(pArrayPos,",",1,i)_",""name"")")
		If tSeg && ($G(@(pArrayName_"("_$P(pArrayPos,",",1,i)_",""type"")"))["SS:") {
			Set tAlias=tAlias_"."_tPiece
		} else {
			Set tAlias=tAlias_$S(tSeg:":",1:".")_$P(pArrayPos,",",i)_$S(")"=$E(tPiece,$L(tPiece)):"("_$P(tPiece,"(",2),1:"")
			Set:tSeg tSeg=0
		}
	}
	Quit $E(tAlias,2,$L(tAlias))
}

/// Given a Schema Category, DocType, and a Segment name, and possibly a DocType return the corresponding segment structure declared in the schema
ClassMethod ResolveSegNameToStructure(pSchemaCategory As %String = "", pDocType As %String = "", pSegName As %String = "", Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK
	Set tSegmentStructure=""
	If ((pSchemaCategory="")||(pDocType="")||(pSegName="")) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty category '"_pSchemaCategory_"' or document type '"_pDocType_"' or segment name '"_pSegName_"'") quit ""
	Set tCategory=pSchemaCategory
	For {
		Set tPath = ""
		For {
			Set tPath = $O($$$vaSchemaGbl(tCategory,pDocType,"map",tPath))	Quit:(""=tPath)
			Set tSeg = $P(tPath,".",*)
			#; check for exact match or if schema includes keyfield or parens, but input parameter didn't
			If $Case(pSegName,tSeg:1,$P(tSeg,"("):1,$P(tSeg,"!")_"-"_$P(tSeg,"-",2):1,$P(tSeg,"!")_"-"_$P($P(tSeg,"-",2),"("):1,:0) {
				Set tSegmentStructure = tCategory_":"_pDocType_":"_$P(tSeg,"(")
				Quit
			}
		}
		Quit:(""'=tSegmentStructure)
		Set tCategory=$G($$$vaSchemaGbl(tCategory,"base"))  Quit:""=tCategory
	}
	If (""=tSegmentStructure)&&$$$ISOK(pStatus) {
		Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment Structure not found for segment named "_pSegName_" in category '"_pSchemaCategory_"'")
	}
	Quit tSegmentStructure
}

/// Given a Schema category and a Message TypeName string, return the corresponding DocType (document structure)
ClassMethod ResolveSchemaTypeToDocType(pSchemaCategory As %String, pTypeName As %String, Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK
	If ((pSchemaCategory="")||(pTypeName="")) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty category '"_pSchemaCategory_"' or type name '"_pTypeName_"'") quit ""
	Quit pSchemaCategory_":"_pTypeName
}

ClassMethod BuildCategoryMaps(pCategory As %String)
{
	Set tDocStructName="" for { set tDocStructName=$O($$$vaSchemaGbl(pCategory,tDocStructName))  quit:tDocStructName=""
		Do ..buildDocStructureMap(pCategory,tDocStructName)
	}
}

ClassMethod buildDocStructureMap(pCategory As %String, pDocStructName As %String)
{
	Set tContentArrayName=$Name($$$vaSchemaGbl(pCategory,pDocStructName,"array"))
	Set tSC=..buildContentArray(tContentArrayName,,pCategory_":"_pDocStructName,1)
	Do ..buildDocStructureMapLoop(tContentArrayName,.tSchemaPathMap,"","=",pCategory,pDocStructName)
	Set index=$O(@tContentArrayName@(""),-1)
	Set tSchemaPathMap("leftoversegs()")="="_(+index+1)_",*|:Any"
	Kill $$$vaSchemaGbl(pCategory,pDocStructName,"map")
	Merge $$$vaSchemaGbl(pCategory,pDocStructName,"map")=tSchemaPathMap
}

ClassMethod buildDocStructureMapLoop(pArrayName As %String, pSchemaPathMap As %String, pNamePrefix As %String, pValuePrefix As %String, pCategory As %String, pTransactionSet As %String) As %Status
{
	Set padding=$L($O(@pArrayName@("name"),-1))
	Set index="" For { Set index=$O(@pArrayName@(index))  Quit:""=index  Continue:index'=+index
		Set value=$TR($J(index,padding)," ","0")
		If @pArrayName@(index,"name")["()" set value=value_",*"
		If '$G(@pArrayName@(index)) {
			Set segtype=$TR($P(@pArrayName@(index,"type"),":",4,*),"()")
			Do ..buildSegmentStructureMap(pCategory,pTransactionSet,segtype)
			Set:segtype["!" segtype=$P(segtype,"!")_"-"_$P(segtype,"-",2) ; strip 'key fields' declaration
			Set pSchemaPathMap(pNamePrefix_@pArrayName@(index,"name"))=pValuePrefix_value_"|"_segtype
		} Else {
			Set nestedref=$S(pArrayName[")":$E(pArrayName,1,$L(pArrayName)-1)_","_index_")",1:pArrayName_"("_index_")")
			Set nameprefix=pNamePrefix_@pArrayName@(index,"name")
			Do ..buildDocStructureMapLoop(nestedref,.pSchemaPathMap,nameprefix_".",pValuePrefix_value_",",pCategory,pTransactionSet)
		}
	}
}

ClassMethod buildSegmentStructureMap(pCategory As %String, pTransactionSet As %String, pSegment As %String) As %Status
{
	Kill $$$vaSchemaGbl(pCategory,pTransactionSet,pSegment,"map")
	Set tSC=..getFieldsContentArray(.tContents,"source",pCategory,pTransactionSet,pSegment,0)  Quit:$$$ISERR(tSC)
	#; Don't mess with EDIFACT, but for X12 just store one node for each segment name
	If $P($G($$$vaSchemaGbl(pCategory,pTransactionSet)),"|")="X" {
		Set tSegmentName = $P($P(pSegment,"-"),"!")
		Kill $$$vaSchemaGbl(pCategory,pTransactionSet,tSegmentName,"map")
	} Else {
		Set tSegmentName = pSegment
	}
	For i=1:1:$G(tContents,0) { Set xname=tContents(i,"name"), name=$ZCVT($P($E(xname,2,*),"("),"L")
		Set $$$vaSchemaGbl(pCategory,pTransactionSet,tSegmentName,"map",name)=i_$S(")"=$E(xname,$L(xname)):"()",1:"")
		For j=1:1:$G(tContents(i),0) {
			Set xname=tContents(i,j,"name")
			Set $$$vaSchemaGbl(pCategory,pTransactionSet,tSegmentName,"map",name_"."_$ZCVT($P(xname,"("),"L"))=
				$$$vaSchemaGbl(pCategory,pTransactionSet,tSegmentName,"map",name)_"."_j_$S(")"=$E(xname,$L(xname)):"()",1:"")
		}
	}
	Quit $$$OK
}

ClassMethod MergeToX12(pCatList As %String = "", pUseOld As %Boolean = 0) As %Status
{
	If ""=pCatList {
		Set tCat="" For { Set tCat=$O($$$vaSchemaGbl(tCat))  Quit:""=tCat  Set tList(tCat)="" }
	} Else {
		For i=1:1:$L(pCatList,",") { Set tCat=$ZSTRIP($P(pCatList,",",i),"<>W")  Continue:""=tCat  Set tList(tCat)="" }
	}
	#; For each schema category
	Set tSC=$$$OK, tCat="" For { Set tCat=$O(tList(tCat))  Quit:""=tCat
		TStart
		try {
			Kill ^EnsEDI.X12.Schema(tCat), ^EnsEDI.X12.Description(tCat)

			Set ^EnsEDI.X12.Description(tCat)=$P($$$vaSchemaGbl(tCat),"|",4)

			#; For each document structure
			Set tDocStructName=""  For { Set tDocStructName=$O($$$vaSchemaGbl(tCat,tDocStructName))  Quit:tDocStructName=""
				Set tDocStruct=..mergeStructureToX12(tCat,tDocStructName,"",",",0,,,.tSCstruct)
				If $$$ISERR(tSCstruct) Set tSC=$$$ADDSC(tSC,tSCstruct)  Continue
				Set ^EnsEDI.X12.Schema(tCat,"DS",tDocStructName)=$E(tDocStruct,2,*)
				If '($D($$$vaSchemaGbl(tCat,tDocStructName),tDocInfo)#2) || ($E(tDocInfo,1,2)'="X|") {
					Set tDocInfo = $G($$$vaSchemaGbl(tCat))
				}
				Set tAgency=$Piece(tDocInfo,"|"), tStandard=$Piece(tDocInfo,"|",2)
				Set tDocType=$Piece(tDocInfo,"|",3), tTitle=$Piece(tDocInfo,"|",4), tRef=$Piece(tDocInfo,"|",5)
				Set ^EnsEDI.X12.Description(tCat,"DS",tDocStructName)=tTitle

				Set tSCRules = ..mergeRulesToX12(tCat,tDocStructName)
				If $$$ISERR(tSCRules) Set tSC=$$$ADDSC(tSC,tSCRules)
			}
			Do:$$$ISOK(tSC) ##class(EnsLib.EDI.X12.Schema).BuildCategoryMaps(tCat)
			Set:pUseOld ^EnsEDI.X12.Schema(tCat,"useOld")=1
			Set ^EnsEDI.X12.Schema(tCat,"time")=$ZTS
		} catch {
			Set tSC=$$$SystemError
		}
		If $$$ISOK(tSC) { TCommit } Else { TRollback }
	}
	Quit tSC
}

ClassMethod mergeRulesToX12(pCat As %String, pDocStruct As %String) As %Status
{
	Set tSC = $$$OK

	Set tErrs = ""
	Set tOrdinal=""
	For {
		Set tOrdinal=$O(^EnsEDI.Schema(pCat,pDocStruct,"r",tOrdinal)) Quit:(""=tOrdinal)
		Set tIndex = "", tRules=""
		For {
			Set tIndex=$O(^EnsEDI.Schema(pCat,pDocStruct,"r",tOrdinal,tIndex),1,tRule) Quit:(""=tIndex)
			Set tRules($P(tRule,"|",2),$P(tRule,"|",3))="" 
		}
		#; Check for any issues with this set of rules not matching against the same seg name at a different ordinal before merging the rule set into ^EnsEDI.X12.Schema
		Set tSegOrCompName = ""
		For {
			Set tSegOrCompName = $O(tRules(tSegOrCompName))	Quit:(""=tSegOrCompName)
			Continue:$D(tErrs(tSegOrCompName))
			If $D(^EnsEDI.X12.Schema(pCat,"RC",tSegOrCompName)) {
				#; First check for rules in ^EnsEDI.X12.Schema, but not in "r" subnode for this ordinal
				Set tRule = ""
				For {
					Set tRule = $O(^EnsEDI.X12.Schema(pCat,"RC",tSegOrCompName,tRule))	Quit:(""=tRule)
					If '$D(tRules(tSegOrCompName,tRule)) {
						Set tSC = $$$ERROR($$$EnsErrGeneral,"Mismatch in relational conditions for "_pCat_":"_pDocStruct_$S(tSegOrCompName?1C3N:" component ",1:" segment ")_tSegOrCompName)
						Quit
					}
					Kill tRules(tSegOrCompName,tRule)
				}
				Quit:$$$ISERR(tSC)
				#; Then check for rules in "r" subnode for this ordinal but not in ^EnsEDI.X12.Schema - this will be anything left in tRules array
				If (""'=$O(tRules(tSegOrCompName,"")))	{
					Set tSC = $$$ERROR($$$EnsErrGeneral,"Mismatch in relational conditions for "_pCat_":"_pDocStruct_$S(tSegOrCompName?1C3N:" component ",1:" segment ")_tSegOrCompName)
					Quit
				}
				Continue
			}
			Merge ^EnsEDI.X12.Schema(pCat,"RC",tSegOrCompName) = tRules(tSegOrCompName)
		}
		Quit:$$$ISERR(tSC)
		Kill tRules
	}

	If $$$ISOK(tSC) {
		Kill ^EnsEDI.Schema(pCat,pDocStruct,"r")
	}
	Quit tSC
}

ClassMethod mergeStructureToX12(pCat As %String, pDocStruct As %String, pSegItem As %Integer, pParentKeySegs As %String, pParentReps As %String, Output pTriggerKeyPos As %Integer, Output pTriggerKey As %String, Output pStatus As %Status) As %String
{
	Set tDefinition="", (tPrevSeg,tKeySeg)=".", (tTrigger,pStatus)=1, (pTriggerKeyPos,pTriggerKey)=""
	Set (tOpt,tReps,tPrevOpt,tPrevReps)="" ; only initialized to be safe in degerate no-segs case
	#; Walk through the segments in the document structure
	For { Set pSegItem=$O($$$vaSchemaGbl(pCat,pDocStruct,"m",pSegItem),1,tSegAttrs)
		If ""'=pSegItem {
			Set tSegCat=$Case($P(tSegAttrs,"|"),"lb":1,"le":-1,"s":0,:"")
			Set tSegName=$S(0=tSegCat:$P(tSegAttrs,"|",2), 1:"\")
		} Else {
			Set tSegName="-"
		}
		#; add the previous segment reference to the Doc Structure definition if unique, otherwise collapsing
		If $Case(tPrevSeg, "":0, ".":0, "\":0, tSegName:0, :1) {
			Set tSegDef="~"_pCat_":"_tPrevSeg, tPrevSeg=""
			Set:""'=tPrevReps tSegDef="~{"_tSegDef_"~}"
			Set:tPrevOpt tSegDef="~["_tSegDef_"~]"
			Set tDefinition=tDefinition_tSegDef
		}
		Quit:""=pSegItem

		#; Determine the item category according to ItemType
		If tSegCat=0 {
			#; This is a segment; pick out the name, ordinal, requirement and repetition count
			//Set tSegAttrs=type_"2|"_..Name_"3|"_..Ordinal_"4|"_..Position_"5|"_i%UsrRequirement_"6|"_..StdRequirement_"7|"_tActRequirement_"8|"_..RepeatCount
			Set tOrdinal=$P(tSegAttrs,"|",3), tPos=$P(tSegAttrs,"|",4)
			Set tUsrReq=$P(tSegAttrs,"|",5), tStdReq=$P(tSegAttrs,"|",6), tActReq=$P(tSegAttrs,"|",7)
			Set tReps=$P(tSegAttrs,"|",8)

			#; If the number of repeats is 0 or 1 then indicate that there are no repeats allowed
			If ($E(tReps)'=">")&&(tReps<=1) Set tReps=""

			#; Add the  segment; or overwrite / warn if inconsistent
			Set pStatus=..storeSegToX12(pCat,pDocStruct,pSegItem,.tTrigger)  Quit:$$$ISERR(pStatus)

			#; Form the trigger (e.g. HL) segment Type from a combination: SegName!field=valList
			If tTrigger["=" {
				Set pTriggerKeyPos=$L(tDefinition)+$L(pCat)+$L(tSegName)+$S(""=tReps:3,1:8)_"|"_tSegName, pTriggerKey=tTrigger, tTrigger=""
				Set:""'=pParentReps pParentKeySegs=pParentKeySegs_tSegName_","
			}
			#; The Segment is optional if the segment is not marked as mandatory
			Set tOpt=(tActReq'="M")

			If tSegName'=tPrevSeg {
				Set tPrevSeg=tSegName, tPrevOpt=tOpt, tPrevReps=tReps
			} Else {
				Set:'tOpt tPrevOpt=0
				Set tPrevReps=">2+"
			}
			
			Kill tPrevLoop
		} ElseIf tSegCat>0 {
			#; Pick out the loop name,requirement and repetitions
			Set tLoopName=$P(tSegAttrs,"|",2)
			$$$ASSERT(tLoopName'["~")
			//2|"_..Name_"3|"_..Ordinal_"4|"_tLoopRequirement_"5|"_..RepeatCount_"|"_..Position_"|"_..TriggerSegment.Name

			#; The Loop is optional if the Loop is not marked as mandatory
			#; If the number of repeats is 0 or 1 then indicate that there are no repeats allowed
			Set tOpt=($P(tSegAttrs,"|",4)'="M"), tReps=$P(tSegAttrs,"|",5) 
			If ($E(tReps)'=">")&&(tReps<=1) Set tReps=""

			Set tLoopDef=..mergeStructureToX12(pCat,pDocStruct,.pSegItem,pParentKeySegs,tReps,.tKeySeg,.tKeyVal,.pStatus)  Quit:$$$ISERR(pStatus)
			#; See if we need to decorate with a key field spec to disambiguate the current loop from the previous one
			If ""=tKeySeg {
				Set (tKeyPos,tKeySeg)=""
				Kill tPrevLoop
			} Else {
				Set tKeyPos=$P(tKeySeg,"|"), $E(tKeySeg,1,$L(tKeyPos)+1)=""
				
				#; Always add keyfield for hierarchical loops
				If tKeySeg="HL" {
					Set $E(tLoopDef,tKeyPos)="!"_tKeyVal_$E(tLoopDef,tKeyPos)
					Set tKeySeg=""
				} Else {
					Set tPrevPos=$G(tPrevLoop(tKeySeg,"KeyPos"))
					If ""'=tPrevPos {
						If $D(tPrevLoop(tKeySeg)) {
							#; loop ambiguity - use key field trigger
							#; Add key to prev loop key seg if it wasn't already
							#; Don't add key to current loop key seg (prev loop key is sufficient for disambiguation; final loop becomes catch-all for any remaining key values)
							If ""=tPrevLoop(tKeySeg,"KeyVal") Set pStatus=$$$ERROR($$$EnsErrGeneral,"No key value found for trigger segment "_tKeySeg_" in loop before "_tLoopName)  Quit
							Set $E(tDefinition,tPrevPos)="!"_tPrevLoop(tKeySeg,"KeyVal")_$E(tDefinition,tPrevPos)
						}
					}
					Kill tPrevLoop
					Set tPrevLoop(tKeySeg,"KeyPos")=$L(tDefinition)+tKeyPos
					Set tPrevLoop(tKeySeg,"Opt")=tOpt
					Set tPrevLoop(tKeySeg,"Reps")=tReps
					Set tPrevLoop(tKeySeg,"KeyVal")=tKeyVal
				}
			}
			#; Merge the loop contents into the structure
			Set tNamed=0
			Set:""'=tReps tLoopDef="~{"_$S(tOpt:"",1:tLoopName)_tLoopDef_"~}", tNamed='tOpt
			Set:tOpt tLoopDef="~["_$S(tNamed:"",1:tLoopName)_tLoopDef_"~]", tNamed=1
			Set:'tNamed tLoopDef="~("_$S(tNamed:"",1:tLoopName)_tLoopDef_"~)"
			Set tDefinition=tDefinition_tLoopDef
			Set:""'=tKeySeg&&$L($G(tPrevLoop(tKeySeg,"KeyPos"))) tPrevLoop(tKeySeg,"KeyPos")=tPrevLoop(tKeySeg,"KeyPos")+2+(2*(""'=tReps&&tOpt))+$L(tLoopName) ; adjust for new loop brackets
		} ElseIf tSegCat < 0 {
			Quit ; back up a level
		} Else {
			#; tables
			$$$ASSERTNOLOG("t"=$P(tSegAttrs,"|"))
		}
	}
	Quit tDefinition
}

/// Given a segment type, extract the content array for the fields (items)
ClassMethod storeSegToX12(pCat As %String, pDocStruct As %String, pSegItem As %String, ByRef pTriggerKey As %String) As %Status
{
	Set tSC=$$$OK
	$$$ASSERT(""'=pSegItem)
	Set tSegAttrs = $G($$$vaSchemaGbl(pCat,pDocStruct,"m",pSegItem))
	$$$ASSERT(""'=tSegAttrs)

	Set tsSegName=$P(tSegAttrs,"|",2), tsOrdinal=$P(tSegAttrs,"|",3), tsPos=$P(tSegAttrs,"|",4)
	Set tsUsrReq=$P(tSegAttrs,"|",5), tsStdReq=$P(tSegAttrs,"|",6), tsActReq=$P(tSegAttrs,"|",7)
	Set tsReps=$P(tSegAttrs,"|",8)
	Quit:'$D($$$vaSchemaGbl(pCat,pDocStruct,"o",tsOrdinal))#2 $$$ERROR($$$EnsEDIUnknownSegmentTypeName,tsSegName)

	Set tsSegDesc=$G($$$vaSchemaDescGbl("X","X12","SEG",tsSegName))
	Set:""'=tsSegDesc&&'($D(^EnsEDI.X12.Description(pCat,"SS",tsSegName))#2) ^EnsEDI.X12.Description(pCat,"SS",tsSegName)=tsSegDesc

	#; Convert Segment field elements, composites
	Set tSegStruct="", tOldStruct=$G(^EnsEDI.X12.Schema(pCat,"SS",tsSegName))
	Set tEleIndex=0,tI=""  For { Set tI=$O($$$vaSchemaGbl(pCat,pDocStruct,"o",tsOrdinal,tI),1,tEleAttrs)  Quit:""=tI
		Set tEleIndex=tEleIndex+1
		$$$ASSERTNOLOG(tEleIndex=tI)
		//"E2|"_tItemName_"3|"_tActReq_"4|"_..Type_"5|"_tMinLength_"6|"_tMaxLength_"7|"_tRepeatCount_"8|"_tItemDesc_"9|"_tStdReq
		//"C2|"_tItemName_"3|"_tCompReq_"4|"_tItemName_"5|"_tStdReq_"6|"_tStdRpt_"7|"_tComRepeat_"8|"_tItemDesc
		Set tEleID=$P(tEleAttrs,"|",2), tActReq=$P(tEleAttrs,"|",3), tType=$P(tEleAttrs,"|",4), tName=$P(tEleAttrs,"|",8)
		Set:""=tEleID tEleID = "N/A"

		Set ^EnsEDI.X12.Schema(pCat,"SS",tsSegName,"names",tName)=tEleIndex

		If $E(tEleAttrs)="E" {
			Set tMinLen=$P(tEleAttrs,"|",5), tMaxLen=$P(tEleAttrs,"|",6), tMaxUse=$P(tEleAttrs,"|",7), tStdReq=$P(tEleAttrs,"|",9)
			Set tEleDesc=$G($$$vaSchemaDescGbl("X","X12","ELEM",tEleID),tName)
			Set:""'=tType tType="("_tType_")"
			If pTriggerKey=1 && $Case(tEleID,735:1,98:1,:0) && $D($$$vaSchemaGbl(pCat,pDocStruct,"c",tEleID,"l",tsOrdinal,tI),tC) {
				#; If it's a trigger field (Hierarchical Level or Entity Identifier) field, find the value and make the trigger segment remember it
				Set (tTriggerVal,pTriggerKey)=""  For { Set tTriggerVal=$O($$$vaSchemaGbl(pCat,pDocStruct,"c",tEleID,"c",tC,tTriggerVal))  Quit:""=tTriggerVal
					Set pTriggerKey = pTriggerKey_$S(""=pTriggerKey:"", 1:"=")_tTriggerVal
				}
				Set:""'=pTriggerKey pTriggerKey=tI_"="_$TR(pTriggerKey,"~",$C(0)) ; escape our separator in value(s)
			}
		} ElseIf $E(tEleAttrs)="C" {
			Set tMinLen="", tMaxLen="", tMaxUse=$P(tEleAttrs,"|",6), tStdReq=$P(tEleAttrs,"|",5), tComRpt=$P(tEleAttrs,"|",7)
			Set tEleDesc=$G($$$vaSchemaDescGbl("X","X12","COMP",tEleID))
			Set tSC= ..storeCompositeToX12(pCat,pDocStruct,tType,tsOrdinal,tI)  Quit:$$$ISERR(tSC)
			Set tType=pCat_":"_tType
		} Else {
			$$$ASSERTNOLOG("0:Unrecognized Type-not C or E")
			Set (tType,tMinLen,tMaxLen,tMaxUse,tStdReq,tEleDesc)=""
		}
		If ""'=tOldStruct {
			#; check for consistency with previously stored attributes requirements
			Set tOldAttrs=$LG(tOldStruct,tEleIndex)
			Set tOldAct=$LG(tOldAttrs,7)
			If tActReq'=tOldAct {
				Set tActReq=$Select(tActReq="C":"C",tOldAct="C":"C",1:"O")
			}
			Set tOldStdReq=$LG(tOldAttrs,5)
			If tStdReq'=tOldStdReq {
				Set tStdReq=$Select(tStdReq="C":"C",tOldStdReq="C":"C",1:"O")
			}
			Set tOldMin=$LG(tOldAttrs,2)
			If tOldMin<tMinLen {
				Set tMinLen=tOldMin
			}
			Set tOldMaxLen=$LG(tOldAttrs,4)
			If tOldMaxLen>tMaxLen {
				Set tMaxLen=tOldMaxLen
			}
			Set tOldMaxUse=$LG(tOldAttrs,3)
			If tOldMaxUse>tMaxUse {
				Set tMaxUse=tOldMaxUse
			}
			
			$$$ASSERTNOLOG($LB(tType,tEleID)=$LB($LG(tOldAttrs,1),$LG(tOldAttrs,6)))
		}
		Set tEleStruct=$LB($LB(tType,tMinLen,tMaxUse,tMaxLen,tStdReq,tEleID,tActReq))
		Set tSegStruct=tSegStruct_tEleStruct ; list append
		Set:""'=tEleDesc&&'($D(^EnsEDI.X12.Description(pCat,"SS",tsSegName,tEleIndex))#2) ^EnsEDI.X12.Description(pCat,"SS",tsSegName,tEleIndex)=tEleDesc
	}
	Set:$$$ISOK(tSC) ^EnsEDI.X12.Schema(pCat,"SS",tsSegName)=tSegStruct
	Quit tSC
}

ClassMethod storeCompositeToX12(pCat As %String, pDocStruct As %String, pCompositeName As %String, pSegOrdinal, pSegElem) As %Status
{
	Set tSC=$$$OK
	#; Composite, have to go down one more level
	Set tCmpStruct="", tOldStruct=$G(^EnsEDI.X12.Schema(pCat,"CS",pCompositeName))
	Set tEleIndex=0,tI="" For { Set tI=$O($$$vaSchemaGbl(pCat,pDocStruct,"o",pSegOrdinal,pSegElem,tI),1,tEleAttrs)  Quit:""=tI
		Set tEleIndex=tEleIndex+1
		$$$ASSERTNOLOG(tEleIndex=tI)

		//"E2|"_tItemName_"3|"_tActReq_"4|"_..Type_"5|"_tMinLength_"6|"_tMaxLength_"7|"_tRepeatCount_"8|"_tItemDesc_"9|"_tStdReq
		Set tEleID=$P(tEleAttrs,"|",2), tActReq=$P(tEleAttrs,"|",3), tType=$P(tEleAttrs,"|",4), tName=$P(tEleAttrs,"|",8)
		Set tMinLen=$P(tEleAttrs,"|",5), tMaxLen=$P(tEleAttrs,"|",6), tMaxUse=$P(tEleAttrs,"|",7), tStdReq=$P(tEleAttrs,"|",9)
		Set:""'=tType tType = "("_tType_")"

		Set ^EnsEDI.X12.Schema(pCat,"CS",pCompositeName,"names",tName)=tEleIndex
		Set tEleDesc=$G($$$vaSchemaDescGbl("X","X12","ELEM",tEleID))
		Set:""'=tEleDesc&&'($D(^EnsEDI.X12.Description(pCat,"CS",pCompositeName,tEleIndex))#2) ^EnsEDI.X12.Description(pCat,"CS",pCompositeName,tEleIndex)=tEleDesc

		If ""'=tOldStruct {
			#; check for consistency with previously stored attributes requirements
			Set tOldAttrs=$LG(tOldStruct,tEleIndex)
			Set tOldAct=$LG(tOldAttrs,7)
			If tActReq'=tOldAct {
				Set tActReq=$Select(tActReq="C":"C",tOldAct="C":"C",1:"O")
			}
			Set tOldStdReq=$LG(tOldAttrs,5)
			If tStdReq'=tOldStdReq {
				Set tStdReq=$Select(tStdReq="C":"C",tOldStdReq="C":"C",1:"O")
			}
			Set tOldMin=$LG(tOldAttrs,2)
			If tOldMin<tMinLen {
				Set tMinLen=tOldMin
			}
			Set tOldMaxLen=$LG(tOldAttrs,4)
			If tOldMaxLen>tMaxLen {
				Set tMaxLen=tOldMaxLen
			}
			Set tOldMaxUse=$LG(tOldAttrs,3)
			If tOldMaxUse>tMaxUse {
				Set tMaxUse=tOldMaxUse
			}
			
			$$$ASSERTNOLOG($LB(tType,tEleID)=$LB($LG(tOldAttrs,1),$LG(tOldAttrs,6)))
		}
		Set tEleStruct=$LB($LB(tType,tMinLen,tMaxUse,tMaxLen,tStdReq,tEleID,tActReq))
		Set tCmpStruct=tCmpStruct_tEleStruct
	}
	If $$$ISOK(tSC) {
		Set ^EnsEDI.X12.Schema(pCat,"CS",pCompositeName)=tCmpStruct
		Set tCompDesc=$G($$$vaSchemaDescGbl("X","X12","COMP",pCompositeName))
		Set:""'=tCompDesc ^EnsEDI.X12.Description(pCat,"CS",pCompositeName)=tCompDesc
	}
	Quit tSC
}

}
