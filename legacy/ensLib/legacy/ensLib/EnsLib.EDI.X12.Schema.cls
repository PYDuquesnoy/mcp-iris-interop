/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// VDoc Schema classmethods and queries
Class EnsLib.EDI.X12.Schema [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
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
Query DocStructures(Category As %String = "", IncludeBase As %Boolean = 0, IncludeInterchangeTree As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "DocStructure:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod DocStructuresExecute(ByRef qHandle As %Binary, Category As %String = "", IncludeBase As %Boolean = 0, IncludeInterchangeTree As %Boolean = 0) As %Status
{
	Set tOld=0
	Set k="" For {
		if 'tOld { Set k=$O($$$vaSchemaGbl(k))  Set:""=k tOld=1 }
		If tOld  { Set k=$O($$$vaVSchemaGbl(k),1,tInfo)  Quit:""=k  Continue:"X"'=$P($G(tInfo),"|")||$D(qHandle("ver","s"_k))||$D(qHandle("ver","u"_k)) } ; skip old if new already found, skip non-X12
		If 'tOld { Set Std=+$G($$$vaSchemaDescGbl(k,"std")) } Else { Set Std=+$G($$$vaVSchemaGbl(k,"std")) }
		If $Case(Category,"0":Std,"+":'Std,"":1,:$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set qHandle("ver",$S(tOld:"x"_k,Std:"s"_k, 'tOld:"u"_k, 1:"x"_k))=k ; sort standard ones first, old-only ones last
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver","")), qHandle("IncludeBase")=IncludeBase  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))
	Set qHandle("IncludeInterchangeTree")=IncludeInterchangeTree
	Quit $$$OK
}

ClassMethod DocStructuresFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DocStructuresExecute ]
{
	Kill Row Set Row=""
	#dim tOld, tCategory,tDesc,tStd
	Set tOld = '$D($$$vaSchemaGbl(qHandle("base")))
	While ""'=$G(qHandle("ver")) {
		While ""'=$G(qHandle("base")) {
			While 1 {
				If 'tOld {
					Set qHandle=$O($$$vaSchemaGbl(qHandle("base"),"DS",qHandle))
				} Else {
					Set qHandle=$O($$$vaVSchemaGbl(qHandle("base"),qHandle))
					Continue:("std"=qHandle)||(":SEF"=qHandle)
				}
				Quit:""=qHandle||'$D(qHandle("seen",qHandle))
			}
			Quit:""'=qHandle
			Quit:'qHandle("IncludeBase")
			Set qHandle("base")=$G($$$vaSchemaGbl(qHandle("base"),"base"))
			Quit:""=qHandle("base")
		}
		Quit:""'=qHandle
		Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))  Kill qHandle("seen")
		Set tOld = '$D($$$vaSchemaGbl(qHandle("base")))
	}

	If ""=$G(qHandle("ver")) {
		If qHandle("IncludeInterchangeTree") {
			#dim tTreeCategory,tGroupName,tTransactionSet,tDescStd
			Set tTreeCategory = $Order(qHandle("InterchangeTree","Interchange",""))
			While tTreeCategory'="" {
				Set tTransactionSet = $order(qHandle("InterchangeTree","TransactionSet",tTreeCategory,""),1,tDescStd)
				If tTransactionSet'="" {
					Kill qHandle("InterchangeTree","TransactionSet",tTreeCategory,tTransactionSet)
					If $Data(qHandle("InterchangeTree","GroupName",tTreeCategory),tGroupName)#2 {
						Set Row=$LB(tTreeCategory_":Interchange:"_tGroupName_":"_tTransactionSet,$LG(tDescStd,1),$LG(tDescStd,2))
						Return $$$OK
					}
				} Else {
					Kill qHandle("InterchangeTree","Interchange",tTreeCategory)
					Kill qHandle("InterchangeTree","GroupName",tTreeCategory)
				}
				Set tTreeCategory = $Order(qHandle("InterchangeTree","Interchange",tTreeCategory))
			}
		}
		Set AtEnd=1
		Quit $$$OK
	}

	Set:qHandle("IncludeBase") qHandle("seen",qHandle)=""
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set tDesc=..GetDescription("DS:"_tCategory_":"_qHandle)
	If 'tOld {
		Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
	} Else {
		Set tStd=+$G($$$vaVSchemaGbl(qHandle("base"),"std"))
	}
	Set Row=$LB(tCategory_":"_qHandle,tDesc,tStd)

	If qHandle("IncludeInterchangeTree") {
		If (qHandle= "Interchange") {
			Set qHandle("InterchangeTree","Interchange",tCategory)=""
		} ElseIf ((qHandle="FunctionalGroup")||(qHandle="Group")) {
			Set qHandle("InterchangeTree","GroupName",tCategory)=qHandle
		} Else {
			Set qHandle("InterchangeTree","TransactionSet",tCategory,qHandle)=$LB(tDesc,tStd)
		}
	}
	Quit $$$OK
}

ClassMethod DocStructuresClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DocStructuresFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of document type schema categories for the document class.<br>
/// The Standard parameter can be used to restrict the list.<br>
/// If Standard is:
///  0 - return only standard categories
///  + - return only user-defined categories
///  empty - return all categories
///  a partial category name - return only categories starting with the given category name part<br/>
///  other - return nothing<br>
/// OldStyle=-1 if only old is available, 0 if only new is available, 1 if both are available but old is preferred, empty if both are available and new is preferred
Query TypeCategories(Standard As %String = "") As %Query(CONTAINID = 0, ROWSPEC = "Category:%String,Description:%String,IsStandard:%Boolean,Base:%String,OldStyle:%Integer")
{
}

ClassMethod TypeCategoriesExecute(ByRef qHandle As %Binary, Standard As %String = "") As %Status
{
	Set tOld=0
	Set k="" For {
		if 'tOld { Set k=$O($$$vaSchemaGbl(k))  Set:""=k tOld=1 }
		If tOld  { Set k=$O($$$vaVSchemaGbl(k),1,tInfo)  Quit:""=k  Continue:"X"'=$P($G(tInfo),"|")||$D(qHandle("ver","s"_k))||$D(qHandle("ver","u"_k)) } ; skip old if new already found, skip non-X12
		If 'tOld { Set Std=+$G($$$vaSchemaDescGbl(k,"std")) } Else { Set Std=+$G($$$vaVSchemaGbl(k,"std")) }
		If $Case(Standard,"0":Std,"+":'Std,"":1,:$ZCVT(Standard,"L")=$E($ZCVT(k,"L"),1,$L(Standard))) {
			Set qHandle("ver",$S(tOld:"x"_k,Std:"s"_k, 'tOld:"u"_k, 1:"x"_k))=k ; sort standard ones first, old-only ones last
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver",""))
	Quit $$$OK
}

ClassMethod TypeCategoriesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = TypeCategoriesExecute ]
{
	Kill Row Set Row="", k=$G(qHandle("ver"))
	If ""=k Set AtEnd=1  Quit $$$OK
	Set tCategory=qHandle("ver",k)
	Set qHandle("ver")=$O(qHandle("ver",k))
	Set tOld=("x"=$E(k))
	If 'tOld {
		Set tDesc=$G($$$vaSchemaDescGbl(tCategory))
		Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
		Set tBase=$G($$$vaSchemaGbl(tCategory,"base"))
		Set tUseOld=$S($D($$$vaVSchemaGbl(tCategory)):$G($$$vaSchemaGbl(tCategory,"useOld")), 1:0) ; is it Force or both, or new only?
	} Else {
		Set tInfo=$G($$$vaVSchemaGbl(tCategory))
		Set tDesc=$P(tInfo,"|",4)
		Set tStd=$G($$$vaVSchemaGbl(tCategory,"std"))
		Set tBase=""
		Set tUseOld=-1 ; old only
	}
	Set Row=$LB(tCategory,tDesc,tStd,tBase,tUseOld)
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
///  0 - return all SegTypes as Category:SegName <br/>
///  1 - return old-style SegTypes as Category:DocStruct:Segment-Ordinal <br/>
Query SegTypes(Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0, ExpandedDocType As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "SegType:%String,Field:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod SegTypesExecute(ByRef qHandle As %Binary, Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0, ExpandedDocType As %Boolean = 0) As %Status
{
	Set CatSeg=$P(Category,":",2,$L(Category,":")), Category=$P(Category,":",1)
	Set tOld=0
	Set k="" For {
		if 'tOld { Set k=$O($$$vaSchemaGbl(k))  Set:""=k tOld=1 }
		If tOld  { Set k=$O($$$vaVSchemaGbl(k),1,tInfo)  Quit:""=k  Continue:"X"'=$P($G(tInfo),"|")||$D(qHandle("ver","s"_k))||$D(qHandle("ver","u"_k)) } ; skip old if new already found, skip non-X12
		If 'tOld { Set Std=+$G($$$vaSchemaDescGbl(k,"std")) } Else { Set Std=+$G($$$vaVSchemaGbl(k,"std")) }
		If $Case(Category,"0":Std,"+":'Std,"":1,:$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set qHandle("ver",$S(tOld:"x"_k,Std:"s"_k, 'tOld:"u"_k, 1:"x"_k))=k ; sort standard ones first, old-only ones last
		}
	}
	Set qHandle("ver")=0, qHandle("seg")="", qHandle("IncludeBase")=IncludeBase, qHandle("fldkey")="", qHandle("Level")=Level, qHandle("CatSeg")=CatSeg, qHandle("old")=0, qHandle("expanded")=ExpandedDocType
	Quit $$$OK
}

ClassMethod SegTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = SegTypesExecute, PublicList = qHandle ]
{
	Kill Row Set Row=""
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	
	For {
		If ""=qHandle("seg")&&'qHandle("old") {
			Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Quit:""=qHandle("ver")
			If '$D($$$vaSchemaGbl(qHandle("ver",qHandle("ver")))) {
				Set qHandle("old") = 1, qHandle("doc") = ""
				Set qHandle("doc")=$O($$$vaVSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc")))  Continue:""=qHandle("doc")
			}
		}
		Elseif qHandle("old") {
			If ""=qHandle("doc") {
				Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Quit:""=qHandle("ver")
			}
			If ""=qHandle("seg") {
				Set qHandle("doc")=$O($$$vaVSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc")))  Continue:(""=qHandle("doc"))||(":SEF"=qHandle("doc"))
			}
		}
		If $Case(qHandle("Level"), 0:1, :""=qHandle("fldkey")) {
			If ""'=qHandle("CatSeg") {
				Set qHandle("seg")=$S(qHandle("seg")="":qHandle("CatSeg"), 1:"")
				If (qHandle("old")&&(""'=qHandle("seg"))&&(""=$P(qHandle("seg"),"-",2))) {
					; scan for ordinal in case it wasn't supplied in CatSeg
					Set tOrd=""  For i=1:1 { Quit:'$D($$$vaVSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),"m",i),tSeg)  If qHandle("seg")=$P(tSeg,"|",2)  Set tOrd=$P(tSeg,"|",3) Quit }
					Set:tOrd'="" qHandle("seg")=qHandle("seg")_"-"_tOrd
				}
				Set:((qHandle("old"))&&(""'=qHandle("seg"))&&('$D($$$vaVSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg"))))) qHandle("seg") = ""
			} Else {
				If 'qHandle("old") { Set qHandle("seg")=$O($$$vaSchemaGbl(qHandle("ver",qHandle("ver")),"SS",qHandle("seg"))) }
				Else {
					Do {
						Set qHandle("seg")=$O($$$vaVSchemaGbl(qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg")))
					} While $ZCVT($E(qHandle("seg")),"U")'=$E(qHandle("seg"))
				}
			}
			Continue:""=qHandle("seg")
			Quit:""'=qHandle("seg")&&(0=qHandle("Level"))
			If 'qHandle("old") {
				Set tSC=..getFieldsContentArray(.tSegFields,"source",qHandle("ver",qHandle("ver")),qHandle("seg"),qHandle("Level"))
			} Else {
				Set tSC=##class(EnsLib.EDI.SEF.Schema).getFieldsContentArray(.tSegFields,"source",qHandle("ver",qHandle("ver")),qHandle("doc"),qHandle("seg"),qHandle("Level"))
			}
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
		Set tFld="", tDesc=..GetDescription("SS:"_tCategory_":"_$S(qHandle("old"):qHandle("doc")_":",1:"")_qHandle("seg"))
	}
	If 'qHandle("old") { Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std")) }
	Else { Set tStd=+$G($$$vaVSchemaGbl(tCategory,"std")) }
	Set tSegType = tCategory_":"_$S(qHandle("old")&&qHandle("expanded"):qHandle("doc")_":",1:"")_qHandle("seg")
	Set Row=$LB(tSegType,tFld,tDesc,tStd)
	Quit $$$OK
fldName(qFld)
	Set tName="", tLen=$L(qFld,",")
	For i=2:1:tLen {
		Set tName=tName_"."_@($P(qFld,",",1,i)_",""name"")")
	}
	If 'qHandle("old") { Set tDesc=$S(tLen=2:..GetDescription("SS:"_qHandle("ver",qHandle("ver"))_":"_qHandle("seg"),$P(qFld,",",tLen))
			, 1:..GetDescription(@($P(qFld,",",1,tLen-1)_",""type"")"),$P(qFld,",",tLen)))
	} Else {
		Set tDesc=..GetDescription($S($G(@(qFld_")"),0):"CS:",1:"ES:")_qHandle("ver",qHandle("ver"))_":"_qHandle("doc")_":"_qHandle("seg"),$P(qFld,",",2,tLen))
	}
	Quit $E(tName,2,*)
}

ClassMethod SegTypesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = SegTypesFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of available Composite Data Structures for the corresponding document class. <br/>
/// The Data Structure is returned as the first column in the result set. <br/>
/// The <var>Category</var> parameter can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only Data Structures in standard categories <br/>
///  + - return only Data Structures in user-defined categories <br/>
///  empty - return Data Structures from all categories <br/>
///  a category name - return only Data Structures in the named category <br/>
///  a partial name suffixed with '%' - return only Data Structures in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only Data Structure defined in the current schema category itself <br/>
///  1 - return all Data Structure in the current schema category's base category in addition to those defined in the current category itself <br/>
Query DataStructures(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "DataStruct:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod DataStructuresExecute(ByRef qHandle As %Binary, Category As %String = "", IncludeBase As %Boolean = 0) As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Set Std=+$G($$$vaSchemaDescGbl(k,"std"))
		If $Case(Category, "0":Std, "+":'Std, "":1, :$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set qHandle("ver",$S(Std:"s"_k,1:"u"_k))=k ; sort standard ones first
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver","")), qHandle("IncludeBase")=IncludeBase  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))
	Quit $$$OK
}

ClassMethod DataStructuresFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DataStructuresExecute ]
{
	Kill Row Set Row=""
	While ""'=$G(qHandle("ver")) {
		While ""'=$G(qHandle("base")) {
			While 1 {
				Set qHandle=$O($$$vaSchemaGbl(qHandle("base"),"CS",qHandle))
				Quit:""=qHandle||'$D(qHandle("seen",qHandle))
			}
			Quit:""'=qHandle
			Quit:'qHandle("IncludeBase")
			Set qHandle("base")=$G($$$vaSchemaGbl(qHandle("base"),"base"))
			Quit:""=qHandle("base")
		}
		Quit:""'=qHandle
		Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))  Kill qHandle("seen")
	}
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set:qHandle("IncludeBase") qHandle("seen",qHandle)=""
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set tDesc=..GetDescription("CS:"_tCategory_":"_qHandle)
	Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
	Set Row=$LB(tCategory_":"_qHandle,tDesc,tStd)
	Quit $$$OK
}

ClassMethod DataStructuresClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DataStructuresFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of available Code Tables for the corresponding document class. <br/>
/// The Code Table is returned as the first column in the result set. <br/>
/// The <var>Category</var> parameter can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only Code Tables in standard categories <br/>
///  + - return only Code Tables in user-defined categories <br/>
///  empty - return Code Tables from all categories <br/>
///  a category name - return only Code Tables in the named category <br/>
///  a partial name suffixed with '%' - return only Code Tables in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only Code Table defined in the current schema category itself <br/>
///  1 - return all Code Table in the current schema category's base category in addition to those defined in the current category itself <br/>
Query CodeTables(Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "CodeTable:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod CodeTablesExecute(ByRef qHandle As %Binary, Category As %String = "", IncludeBase As %Boolean = 0) As %Status
{
	Set k="" For { Set k=$O($$$vaSchemaGbl(k)) Quit:""=k
		Set Std=+$G($$$vaSchemaDescGbl(k,"std"))
		If $Case(Category, "0":Std, "+":'Std, "":1, :$S("%"=$E(Category,$L(Category)):$ZCVT($E(Category,1,$L(Category)-1),"L")=$E($ZCVT(k,"L"),1,$L(Category)-1), 1:$ZCVT(Category,"L")=$ZCVT(k,"L"))) {
			Set qHandle("ver",$S(Std:"s"_k,1:"u"_k))=k ; sort standard ones first
		}
	}
	Set qHandle="", qHandle("ver")=$O(qHandle("ver","")), qHandle("IncludeBase")=IncludeBase  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))
	Quit $$$OK
}

ClassMethod CodeTablesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = CodeTablesExecute ]
{
	Kill Row Set Row=""
	While ""'=$G(qHandle("ver")) {
		While ""'=$G(qHandle("base")) {
			While 1 {
				Set qHandle=$O($$$vaSchemaGbl(qHandle("base"),"CT",qHandle))
				Quit:""=qHandle||'$D(qHandle("seen",qHandle))
			}
			Quit:""'=qHandle
			Quit:'qHandle("IncludeBase")
			Set qHandle("base")=$G($$$vaSchemaGbl(qHandle("base"),"base"))
			Quit:""=qHandle("base")
		}
		Quit:""'=qHandle
		Set qHandle("ver")=$O(qHandle("ver",qHandle("ver")))  Set:""'=qHandle("ver") qHandle("base")=qHandle("ver",qHandle("ver"))  Kill qHandle("seen")
	}
	If ""=$G(qHandle("ver")) Set AtEnd=1  Quit $$$OK
	Set:qHandle("IncludeBase") qHandle("seen",qHandle)=""
	Set tCategory=qHandle("ver",qHandle("ver"))
	Set tDesc=..GetDescription("CT:"_tCategory_":"_qHandle)
	Set tStd=+$G($$$vaSchemaDescGbl(tCategory,"std"))
	Set Row=$LB(tCategory_":"_qHandle,tDesc,tStd)
	Quit $$$OK
}

ClassMethod CodeTablesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = CodeTablesFetch ]
{
	Kill qHandle
	Quit $$$OK
}

/// Get all properties for a given document structure
ClassMethod GetContentArray(Output pContents, pMode As %String, pType As %String = "", pLevel As %Integer, pIncludeBase As %Boolean = 0) As %Status
{
	Set tStructCategory=$P(pType,":"), tStructName=$P(pType,":",2)
	Set:$Case($E(pType),"+":1,"-":1,:0) $E(tStructCategory,1)=""
	If (tStructCategory="")||(tStructName="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:name'.")
	If $Case($E(pType), "+":0, "-":1, :$D($$$vaVSchemaGbl(tStructCategory))&&('$D($$$vaSchemaGbl(tStructCategory))||$G(^(tStructCategory,"useOld")))) {
		Quit:$G(pLevel)'=1||($G(pMode)'="source") ##class(EnsLib.EDI.SEF.Schema).buildContentArray(.pContents,.pMode,$S("-"=$E(pType):$E(pType,2,*),1:pType),.pLevel)
		Quit ##class(EnsLib.EDI.SEF.Schema).GetContentArray(.pContents,.pMode,$S("-"=$E(pType):$E(pType,2,*),1:pType),.pLevel,.pIncludeBase)
	}
	Quit:$G(pLevel)'=1||($G(pMode)'="source") ..buildContentArray(.pContents,.pMode,$S("+"=$E(pType):$E(pType,2,*),1:pType),.pLevel)
	Set tBaseCat=tStructCategory, tSC=$$$OK
	For {
		If ""=$G($$$vaSchemaGbl(tBaseCat,"DS",tStructName)) Set tSC=$$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' not defined.")  Quit
		If '$D($$$vaSchemaGbl(tBaseCat,"DS",tStructName,"array")) Set tSC=$$$ERROR($$$EnsErrGeneral,"No content array is built for Document Structure '"_pType_"'.")  Quit
		Quit:$$$ISOK(tSC)||'pIncludeBase
		Set tBaseCat=$G($$$vaSchemaGbl(tBaseCat,"base"))
		Quit:""=tBaseCat
		Set tSC=$$$OK ; go around and try again on base schema
	} Quit:$$$ISERR(tSC) tSC
	Set tRef=$G(pContents)
	If $Case($E($G(pContents)),"%":1,"^":1,:0) { Kill @pContents  Merge @pContents=$$$vaSchemaGbl(tBaseCat,"DS",tStructName,"array") }
	Else { Kill pContents  Merge pContents=$$$vaSchemaGbl(tBaseCat,"DS",tStructName,"array") }
	Quit $$$OK
}

/// Get all properties for a given document structure
ClassMethod buildContentArray(Output pContents, pMode As %String = "source", pType As %String, pLevel As %Integer = 0) As %Status
{
	Set tStructCategory=$P(pType,":"), tStructName=$P(pType,":",2)
	If (tStructCategory="")||(tStructName="") Quit $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' must have form 'category:name'.")
	Set tSchema=$G($$$vaSchemaGbl(tStructCategory,"DS",tStructName))
	Quit:""=tSchema $$$ERROR($$$EnsErrGeneral,"Document Structure '"_pType_"' not defined.")
	Set tSC=$$$OK
	Do ..getSegsContentArray(.pContents,$ZCVT(pMode,"L"),tStructCategory,tSchema,"",pLevel,.tSC)
	Quit tSC
}

ClassMethod getSegsContentArray(Output pContents, pMode As %String, pCategory As %String, pSchema As %String, pPrevSeg As %String, pLevel As %Integer, Output pSC As %Status = {$$$OK}) As %Integer
{
	Set tRef=$G(pContents)
	If ("%"=$E(tRef)||("^"=$E(tRef))) { Kill @tRef }
	Else {
		Kill pContents  Set tRef="%local"  New %local
	}
	#; Walk through the segment structure of the document
	Set iProp=0
	For iSeg=1:1:$L(pSchema,"~") { Set tSeg=$P(pSchema,"~",iSeg)  Continue:""=tSeg
		If tSeg[":" { Set tSegCategory=$P(tSeg,":"), tSeg=$P(tSeg,":",2) } Else { Set tSegCategory="" }
		Set tCat=$Case($E(tSeg),"[":1,"{":1,"(":1,"<":3,"]":-1,"}":-1,")":-1,"|":-3,">":-3,:0)
		If 0=tCat {
			Set tName=tSeg, tSegNames(tName)=$G(tSegNames(tName))+1 ; count duplicate seg names at this level
			Set:+$G(tSegNames(tName))>1 tName=tName_"i"_tSegNames(tName) ; append i<n> if needed
			Set iProp=iProp+1
			If pLevel>1||'pLevel {
				Set tSC1=..getFieldsContentArray(.tFldContents,pMode,tSegCategory,$P(tSeg,"!"),pLevel)  Set:pSC'=tSC1 pSC=$$$ADDSC(pSC,tSC1)
				Merge @tRef@(iProp)=tFldContents  Kill tFldContents
			}
			Set @tRef@(iProp,"name")=tName
			Set @tRef@(iProp,"type")="SS:"_tSegCategory_":"_tSeg
		} Else { ; 0'=tCat
			// Tweak stuff for artificial Choice List schema #<~||~||~>>
			If ("#"=pPrevSeg) {
				If -3=tCat {
					Set tCat=$Case(tSeg,">":-2,"|":+3,:tCat)
				}
			} Else {
				If "<"=tSeg { Set tSeg="#", tCat=2, iSeg=iSeg-1 } ; Artificially descend an extra level "#" before "<"
				ElseIf -3=tCat {
					Set iSeg=iSeg-$Case(tSeg,">":1,"|":1,:0) ; Ascend from bottom level, double up each "|" or ">" - to extra-exit, or to enter a new branch
				}
			}
			If tCat>0 {
				Set iSeg=iSeg+..getSegsContentArray(.tGrpContents,pMode,pCategory,$P(pSchema,"~",iSeg+1,$L(pSchema,"~")),tSeg,pLevel,.pSC)
				If tGrpContents {
					Set iProp=iProp+1
					If tGrpContents=1&&($L(tSeg)=1) {
						Set tName=tGrpContents(1,"name")
						Set tType=tGrpContents(1,"type")
						Merge @tRef@(iProp)=tGrpContents(1)
					} Else { ; > 1 - repeating, optional or named loop
						Set tExt=$S(tCat>1:"union",1:"loop")
						If $L(tSeg)>1 {
							Set tName=tExt_$E(tSeg,2,*)
							Set tType=tExt_$E(tSeg,2,*)
						} Else {
							Set tName=$P(tGrpContents(1,"name"),"(")_tExt
							Set tType=$P($P(tGrpContents(1,"type"),":",3),"(")_tExt
						}
						If tGrpContents=1&&($L(tSeg)=1||(tGrpContents(1,"type")'[":")) {
							Merge @tRef@(iProp)=tGrpContents(1)
							Set:")"=$E(tGrpContents(1,"name"),*) tName=tName_"()", tType=tType_"()"
						} Else {
							Merge @tRef@(iProp)=tGrpContents
						}
					}
				}
				Kill tGrpContents
				Set tOptArr=(")"=$E(tName,*))  Set:tOptArr tName=$P(tName,"(",1,$L(tName,"(")-1) ; unwind returned optional array
				Set tSegNames(tName)=$G(tSegNames(tName))+1 ; count duplicate seg names at this level
				Set:+$G(tSegNames(tName))>1 tName=tName_"i"_tSegNames(tName) ; append i<n> if needed
				Set:"{"=$E(tSeg)||tOptArr tName=tName_"()"
				Set:"{"=$E(tSeg) tType=tType_"()"
				Set @tRef@(iProp,"name")=tName
				Set @tRef@(iProp,"type")=tType
				Set:"["=$E(tSeg) @tRef@(iProp,"opt")=1
			} Else { ; tCat < 0
				Quit
			}
		}
	}
	Set @tRef=iProp
	Merge:tRef="%local" pContents=%local
	Quit iSeg
}

/// Given a segment type, extract the content array for the fields (items)
ClassMethod getFieldsContentArray(Output pContents, pMode As %String, pCategory As %String, pSeg As %String, pLevel As %Integer) As %Status
{
	Kill pContents  Set tSC=$$$OK
	Set tSegType=$P(pSeg,"i")
	If $D($$$vaSchemaGbl(pCategory,"SS",tSegType))#2=0 {
		If "DocsRef"=$E(pSeg,*-$L("DocsRef")+1,*) {
			If $D($$$vaSchemaGbl(pCategory,"SS",pSeg))#2=0 {
				Set pContents=0  Quit $$$OK
			} Else {
				Set tSegType = pSeg
			}
		} Else {
			Quit $$$ERROR($$$EnsErrGeneral,"Unknown segment type '"_pCategory_":"_tSegType_"'")
		}
	}
	Set tSchema=$$$vaSchemaGbl(pCategory,"SS",tSegType)

	For iFld=1:1:$LL(tSchema) { Set tFld=$LG(tSchema,iFld)  Continue:""=tFld
		Set tType=$LI(tFld,1)
		Set tTypeCategory=$P(tType,":"), tType=$P(tType,":",2)
		Set tRep=$Case($LI(tFld,2),"+":1,"*":1,"&":1,:0)
		Set tRepCount=$LI(tFld,3)
		Set tRepCount=$S('tRep:"", 1:"("_tRepCount_")")
		Set tName="" For  Set tName=$O($$$vaSchemaGbl(pCategory,"SS",tSegType,"names",tName))  Quit:""=tName||(iFld=$$$vaSchemaGbl(pCategory,"SS",tSegType,"names",tName))
		Set pContents(iFld,"name")=":"_tName_$S('tRep:"", 1:"()")
		If ""=tType {
			Set:""'=tRepCount pContents(iFld,"type")=tRepCount
		} Else {
			Set pContents(iFld,"type")="CS:"_tTypeCategory_":"_tType_tRepCount
			If pLevel>=2||'pLevel {
				Set tSC1=..getCompositesContentArray(.tFldContents, pMode, tTypeCategory, tType, pLevel)  Set:tSC'=tSC1 tSC=$$$ADDSC(tSC,tSC1)
				Merge pContents(iFld)=tFldContents  Kill tFldContents
			}
		}
	}
	Set pContents=iFld
	Quit tSC
}

/// Get the components of a CompositeStructure / Type
ClassMethod getCompositesContentArray(Output pContents, pMode As %String, pCategory As %String, pCompositeStructType As %String, pLevel As %Integer = 0) As %Status
{
	Kill pContents  Set tSC=$$$OK
	Set tSchema=$S(""=pCategory:"",1:$G($$$vaSchemaGbl(pCategory,"CS",pCompositeStructType)))
	Quit:""=tSchema $$$ERROR($$$EnsErrGeneral,"Unknown composite structure type '"_pCategory_":"_pCompositeStructType)

	For iComp=1:1:$LL(tSchema) { Continue:'$LD(tSchema,iComp)  Set tType=$LI(tSchema,iComp)
		Set tTypeCategory=$P(tType,":"), tType=$P(tType,":",2)
		Set tName="" For  Set tName=$O($$$vaSchemaGbl(pCategory,"CS",pCompositeStructType,"names",tName))  Quit:""=tName||(iComp=$$$vaSchemaGbl(pCategory,"CS",pCompositeStructType,"names",tName))
		Set pContents(iComp,"name")=tName
		If ""'=tType {
			Set pContents(iComp,"type")="CS:"_tTypeCategory_":"_tType
			If pLevel>=3||'pLevel {
				Set tSC1=..getCompositesContentArray(.tCompContents, pMode, tTypeCategory, tType)  Set:tSC'=tSC1 tSC=$$$ADDSC(tSC,tSC1)
				Merge pContents(iComp)=tCompContents   Kill tCompContents
			}
		}
	}
	Set pContents=iComp
	Quit tSC
}

ClassMethod ElementExists(pElementSpec As %String = "") As %Boolean
{
	Set tClass=$ZCVT($P(pElementSpec,":",1),"U"), tCat=$P(pElementSpec,":",2), tElem=$P(pElementSpec,":",3)
	Quit:((""=tClass)||(""=tCat)||(""=tElem)) 0
	Quit ($D($$$vaSchemaGbl(tCat,tClass,tElem))#2'=0)
}

/// Get the description of an item or an indexed piece of an item
ClassMethod GetDescription(pElementSpec As %String, pItem As %Integer = "", pVerbose As %Boolean = 0) As %String
{
	Set tClass=$ZCVT($P(pElementSpec,":",1),"U")
	Set tCategory=$P(pElementSpec,":",2)  Set:""=tCategory tCategory="ISC_00405"
	If $D($$$vaSchemaDescGbl(tCategory)) {
		Set tElem=$P($P(pElementSpec,":",3),"!")
		Quit:(""=tClass)||(""=tElem) "" ; Must specify ""Class:Category:Element""
		Set tDesc=$S(""=pItem:$G($$$vaSchemaDescGbl(tCategory,tClass,tElem)), 1:$G($$$vaSchemaDescGbl(tCategory,tClass,tElem,pItem)))
		If ""=tDesc {
			Set tBaseCat=$G($$$vaSchemaGbl(tCategory,"base"))
			Set pItem(tCategory)=""
			Set:""'=tBaseCat&&'$D(pItem(tBaseCat)) tDesc=..GetDescription(tClass_":"_tBaseCat_":"_$P(pElementSpec,":",3,$L(pElementSpec,":")),.pItem)
		} ElseIf pVerbose && (((""=pItem) && $D($$$vaSchemaDescGbl(tCategory,tClass,tElem,"verbose"),tVerboseDesc)) || ((""'=pItem) && $D($$$vaSchemaDescGbl(tCategory,tClass,tElem,pItem,"verbose"),tVerboseDesc))) {
			Set tDesc = tVerboseDesc
		}
	} Else {
		Set tDesc = ##class(EnsLib.EDI.SEF.Schema).GetDescription(pElementSpec,pItem)
		If (""=tDesc)&&("SS"=tClass) {
			Set tElem=$P($P(pElementSpec,":",3),"!")
			Set tElementSpec = tClass_":"_tCategory_"::"_tElem
			Set tDesc = ##class(EnsLib.EDI.SEF.Schema).GetDescription(tElementSpec,pItem)
		}
	}
	Quit tDesc
}

/// This method computes the Alias string for a property name, given the property's node in the Content Array.
ClassMethod GetAlias(pContentArrayName As %String, pArrayPos As %String) As %String
{
	Set tSeg=1,tAlias=""  For i=1:1:$L(pArrayPos,",") {
		Set tPiece=@(pContentArrayName_"("_$P(pArrayPos,",",1,i)_",""name"")")
		If tSeg && ($G(@(pContentArrayName_"("_$P(pArrayPos,",",1,i)_",""type"")"))["SS:") {
			Set tAlias=tAlias_"."_tPiece
		} else {
			Set tAlias=tAlias_$S(tSeg:":",1:".")_$P(pArrayPos,",",i)_$S(")"=$E(tPiece,$L(tPiece)):"("_$P(tPiece,"(",2),1:"")
			Set:tSeg tSeg=0
		}
	}
	Quit $E(tAlias,2,$L(tAlias))
}

/// Given a Schema Category and a Segment name, and possibly a DocType (required for old-style schemas) return the corresponding segment structure declared in the schema
ClassMethod ResolveSegNameToStructure(pSchemaCategory As %String = "", pDocType As %String = "", pSegName As %String = "", Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK
	Set tSegmentStructure=""
	If ((pSchemaCategory="")||(pSegName="")) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty category '"_pSchemaCategory_"' or segment name '"_pSegName_"'") quit ""
	Set tCategory=pSchemaCategory
	Set:$Case($E(tCategory),"+":1,"-":1,:0) $E(tCategory,1)=""
	For {
		#; Determine if we will use the new or old schema global and DocType format
		If $Case($E(pSchemaCategory), "+":0, "-":1, :$D($$$vaVSchemaGbl(tCategory))&&('$D($$$vaSchemaGbl(tCategory))||$G(^(tCategory,"useOld")))) {
			#; old style schema definition
			#; first make sure a docType was included, since this is necessary for old-style
			If (pDocType="") {
				Set pStatus=$$$ERROR($$$EnsErrGeneral,"DocType required to find old-style segment structure")
				Quit
			}
			Set tPath = ""
			For {
				Set tPath = $O($$$vaVSchemaGbl(tCategory,pDocType,"map",tPath))	Quit:(""=tPath)
				Set tSeg = $P(tPath,".",*)
				#; check for exact match or if schema includes keyfield or parens, but input parameter didn't
				If $Case(pSegName,tSeg:1,$P(tSeg,"("):1,$P(tSeg,"!")_"-"_$P(tSeg,"-",2):1,$P(tSeg,"!")_"-"_$P($P(tSeg,"-",2),"("):1,:0) {
					Set tSegmentStructure = tCategory_":"_pDocType_":"_$P(tSeg,"(")
					Quit
				}
			}
		} Else {
			If $D($$$vaSchemaGbl(tCategory,"SS",pSegName)) {
				Set tSegmentStructure=tCategory_":"_pSegName
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

/// Given a Schema category and a Document TypeName string, return the corresponding DocType (document structure)
/// The <var>pImplementationGuide</var> argument, if given, is used to disambiguate when a schema category contains multiple versions of a given type of document, e.g. the three types of HIPAA 837.
ClassMethod ResolveSchemaTypeToDocType(pSchemaCategory As %String, pTypeName As %String, Output pStatus As %Status, pImplementationGuide As %String = "", pPurpose As %String = "") As %String
{
	Set pStatus=$$$OK
	Set tCategory=pSchemaCategory  Set:$Case($E(tCategory),"+":1,"-":1,:0) $E(tCategory,1)=""
	If (tCategory="") Set pStatus=$$$ERROR($$$EnsErrGeneral,"Empty category")  Quit ""
	For {
		#; Determine if we will use the new or old schema global and DocType format
		If $Case($E(pSchemaCategory), "+":0, "-":1, :$D($$$vaVSchemaGbl(tCategory))&&('$D($$$vaSchemaGbl(tCategory))||$G(^(tCategory,"useOld")))) {
			#; old style schema definition
			If ""'=pTypeName && ($D($$$vaVSchemaGbl(tCategory,pTypeName))) {
				Set tDocStructure=$S(tCategory=pSchemaCategory:"", 1:"-")_tCategory_":"_pTypeName
				Quit
			} ElseIf (("Group"=pTypeName) && $D($$$vaVSchemaGbl(tCategory,"FunctionalGroup"))) {
				Set tDocStructure=$S(tCategory=pSchemaCategory:"", 1:"-")_tCategory_":FunctionalGroup"
				Quit
			} Else { Set tDocStructure="" }
			Set tCategory=$G($$$vaVSchemaGbl(tCategory,"base"))  Quit:""=tCategory
		} Else {
			#; new style schema definition
			Set tDocStructure=""
			If ""'=pImplementationGuide {
				Set tSchemaType=pTypeName_"."
				For {
					Set tSchemaType=$O($$$vaSchemaGbl(tCategory,"DS",tSchemaType))  Quit:(($E(tSchemaType,1,$L(pTypeName))'=pTypeName) && (("Group"'=pTypeName)||(tSchemaType'="FunctionalGroup")))
					Set tImplGuide=$G($$$vaSchemaDescGbl(tCategory,"DS",tSchemaType,"alt"))
					If (tImplGuide=pImplementationGuide) || (($E(tImplGuide)="X") && ($E(pImplementationGuide)="X") && (+$E(tImplGuide,2,*)=+$E(pImplementationGuide,2,*))) {
						Set tPurpose=$G($$$vaSchemaDescGbl(tCategory,"DS",tSchemaType,"purpose"))
						If tPurpose'="" {
							Set tMatchedPurpose = 0
							For i=1:1:$l(tPurpose,",") { Set:$ZStrip($p(tPurpose,",",i),"<>W")=pPurpose tMatchedPurpose=1 }
							CONTINUE:'tMatchedPurpose 
						}
						Set tDocStructure=$S(tCategory=pSchemaCategory:"", 1:"+")_tCategory_":"_tSchemaType
						Quit
					}
				}
				Quit:""'=tDocStructure
			}
			If ""'=pTypeName {
				If $D($$$vaSchemaGbl(tCategory,"DS",pTypeName)) {
					Set tDocStructure=$S(tCategory=pSchemaCategory:"", 1:"+")_tCategory_":"_pTypeName
					Quit
				} ElseIf (("Group"=pTypeName) && $D($$$vaSchemaGbl(tCategory,"DS","FunctionalGroup"))) {
					Set tDocStructure=$S(tCategory=pSchemaCategory:"", 1:"+")_tCategory_":FunctionalGroup"
					Quit
				}
			}
			Set tCategory=$G($$$vaSchemaGbl(tCategory,"base"))  Quit:""=tCategory
		}
	}
	If ""=tDocStructure {
		Set pStatus=$$$ERROR($$$EnsErrGeneral,"DocType not found for message type "_pSchemaCategory_":"_pTypeName)
	}
	Quit tDocStructure
}

ClassMethod BuildCategoryMaps(pCategory As %String) As %Status
{
	Set tSC=$$$OK, tDocStructName="" For { Set tDocStructName=$O($$$vaSchemaGbl(pCategory,"DS",tDocStructName))  Quit:""=tDocStructName
		Continue:tDocStructName=":SEF"
		Set tSC=..buildDocStructureMap(pCategory,tDocStructName)  Quit:$$$ISERR(tSC)
	}
	Set tSegment="" For { Set tSegment=$O($$$vaSchemaGbl(pCategory,"SS",tSegment))  Quit:tSegment=""
		Set tSC=..buildSegmentStructureMap(pCategory,tSegment)  Quit:$$$ISERR(tSC)
	}
	Quit tSC
}

ClassMethod buildDocStructureMap(pCategory As %String, pDocStructName As %String) As %Status
{
	Set tContentArrayName=$Name($$$vaSchemaGbl(pCategory,"DS",pDocStructName,"array"))
	Set tSC=..buildContentArray(tContentArrayName,,pCategory_":"_pDocStructName,1)
	Do ..buildDocStructureMapLoop(tContentArrayName,.tSchemaPathMap,"","=")
	Set index=$O(@tContentArrayName@(""),-1)
	Set tSchemaPathMap("leftoversegs()")="="_(+index+1)_",*|:Any"
	Kill $$$vaSchemaGbl(pCategory,"DS",pDocStructName,"map")
	Merge $$$vaSchemaGbl(pCategory,"DS",pDocStructName,"map")=tSchemaPathMap
	Quit tSC
}

ClassMethod buildDocStructureMapLoop(pContentArrayName As %String, pSchemaPathMap As %String, pNamePrefix As %String, pValuePrefix As %String)
{
	Set padding=$L($O(@pContentArrayName@("name"),-1))
	Set index="" For { Set index=$O(@pContentArrayName@(index))  Quit:""=index  Continue:index'=+index
		Set value=$TR($J(index,padding)," ","0")
		If @pContentArrayName@(index,"name")["()" set value=value_",*"
		If '$G(@pContentArrayName@(index)) {
			Set segtype=$TR($P(@pContentArrayName@(index,"type"),":",2,99),"()")
			Set pSchemaPathMap(pNamePrefix_@pContentArrayName@(index,"name"))=pValuePrefix_value_"|"_segtype
		} Else {
			Set nestedref=$S(pContentArrayName[")":$E(pContentArrayName,1,$L(pContentArrayName)-1)_","_index_")",1:pContentArrayName_"("_index_")")
			Set nameprefix=pNamePrefix_@pContentArrayName@(index,"name")
			Do ..buildDocStructureMapLoop(nestedref,.pSchemaPathMap,nameprefix_".",pValuePrefix_value_",")
		}
	}
}

ClassMethod buildSegmentStructureMap(pCategory As %String, pSegmentType As %String) As %Status
{
	Kill $$$vaSchemaGbl(pCategory,"SS",pSegmentType,"map")
	Set struct=$G($$$vaSchemaGbl(pCategory,"SS",pSegmentType))
	Quit:""=struct $$$OK
	Kill names Set name="" For { Set name=$O($$$vaSchemaGbl(pCategory,"SS",pSegmentType,"names",name))  quit:name=""
		Set names($$$vaSchemaGbl(pCategory,"SS",pSegmentType,"names",name))=name
	}
	Set tSC=$$$OK
	For i=1:1:$LL(struct) {
		Continue:'$D(names(i))
		Set ifrepeating=$LI($LI(struct,i),6)
		Set tSSMap($ZCVT(names(i),"L"))=i_$s(ifrepeating:"()",1:"")
		Set cs=$LG($LI(struct,i),1)
		If cs'=""&&($E(cs)'="(") {
			Kill subarray
			Set tSC=..buildCompositeStructMap($p(cs,":",1),$p(cs,":",2),.subarray) Quit:$$$ISERR(tSC)
			Set name="" For { Set name=$O(subarray(name))  Quit:name=""
				Set tSSMap($ZCVT(names(i)_"."_name,"L"))=tSSMap($ZCVT(names(i),"L"))_"."_subarray(name)
			}
		}
	}
	Merge:$$$ISOK(tSC) $$$vaSchemaGbl(pCategory,"SS",pSegmentType,"map")=tSSMap
	Quit tSC
}

ClassMethod buildCompositeStructMap(pDocTypeCategory, pTypeName, pCSMap) As %Status
{
	Set struct=$G($$$vaSchemaGbl(pDocTypeCategory,"CS",pTypeName))
	Quit:""=struct $$$OK
	Kill names Set name="" For { Set name=$O($$$vaSchemaGbl(pDocTypeCategory,"CS",pTypeName,"names",name))  Quit:""=name
		Set names($$$vaSchemaGbl(pDocTypeCategory,"CS",pTypeName,"names",name))=name
	}
	Set tSC=$$$OK
	For i=1:1:$LL(struct) {
		Continue:'$D(names(i))
		Set pCSMap(names(i))=i
		Set cs=$LG($LI(struct,i),1)
		If cs'=""&&($E(cs)'="(") {
			Kill subarray
			Set tSC=..buildCompositeStructMap($P(cs,":",1),$p(cs,":",2),.subarray)  Quit:$$$ISERR(tSC)
			Set name="" For { Set name=$O(subarray(name))  Quit:name=""
				Set pCSMap(names(i)_"."_name)=pCSMap(names(i))_"."_subarray(name)
			}
		}
	}
	Quit tSC
}

}
