/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSearchTableErrors)

Class Ens.VDoc.SearchTableGenerator Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 2 ]
{

/// This API allows for the (re)generation of <class>Ens.Config.SearchTableProp</class> entries
/// for a specific SearchTable class without requiring a recompile of the class. The class must have
/// been compiled at some point, but a recompilation is not needed for the purposes of validating
/// the SearchSpec XData and ensuring that the corresponding <class>Ens.Config.SearchTableProp</class>
/// objects are present and correctly defined.
ClassMethod ValidateSearchTableProperties(pClassname As %String = "", Output pSearchTableProperties, Output pSearchTableItems) As %Status
{
#define PropCheckList(%template)	$lb(%template.IsImplicit, %template.IndexType, %template.PropType, %template.StoreNulls, %template.Unselective)

	Set tStatus = $$$OK
	Try {
		Kill pSearchTableProperties
		Kill pSearchTableItems
		#; Load compiled class using classname -- we'll re-use %compiledclass if it's already in memory
		Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(pClassname,,.tStatus)
		If $$$ISERR(tStatus) Quit

		#; build arrays of property templates and all items
		#; The least-derived property of a given name has precedence
		Set tDepth = 0
		Set tDerivation = ""
		For {
			Set tClassname = tClassDef.Name
			Set tDerivation = tDerivation _ "~"_tClassname
			Set tDepth = tDepth + 1
			#; Determine when each item gets added to the list
			Kill tItemsList
			Set tStatus = ##class(Ens.Util.XML.Reader).ObjectsFromXData(.tItemsList,tClassDef,"SearchSpec","Ens.Config.SearchTableItem")
			If $$$StatusEquals(tStatus,$$$EnsErrNoObjFromStream) Set tStatus = $$$OK
			If $$$ISERR(tStatus) Quit
			Set tStatus = ##class(Ens.Util.XML.Reader).ObjectsFromXData(.tPropsList,tClassDef,"SearchSpec","Ens.Config.SearchTableProp")
			If $$$StatusEquals(tStatus,$$$EnsErrNoObjFromStream) Set tStatus = $$$OK
			If $$$ISERR(tStatus) Quit

			#; Build templates of all Props referenced in items, if not previously implied (count backwards so first overrides last)
			If $IsObject($get(tItemsList)) {
				For i=tItemsList.Count():-1:1 {
					Set tItem = tItemsList.GetAt(i)
					Set tTemplate = ##class(Ens.Config.SearchTableProp).%New()
					Set tTemplate.Name = tItem.PropName
					Set tTemplate.IsImplicit = 1
					#; Set ClassDerivation to base class which generated the template
					Set tTemplate.ClassDerivation = tClassname
					#; PropAttrs
					Set tTemplate.PropType = tItem.PropType
					Set tTemplate.IndexType = tItem.IndexType
					Set tTemplate.StoreNulls = tItem.StoreNulls
					Set tTemplate.Unselective = tItem.Unselective
					If (tTemplate.IndexType = "") {
						Set tTemplate.IndexType = "None"
					}
					If $data(tCheckProps(tTemplate.Name)) {
						Set tPrevDerivation = $listget(tCheckProps(tTemplate.Name), 1)
						Set tCurrProps = $$$PropCheckList(tTemplate)
						Set tPrevProps = $listget(tCheckProps(tTemplate.Name), 2)
						Set tPrevDepth = $listget(tCheckProps(tTemplate.Name), 3)

						#; Assume the property is having the derivation amended, but check for multiple definitions in the same SearchSpec
						Set tSameClass = 0
						If (tDepth = tPrevDepth) {
							Set tSameClass = 1
						}

						If '$listsame(tCurrProps, tPrevProps) {
							For i=1:1:$ll(tCurrProps) {
								Set tCurrProp = $lg(tCurrProps, i)
								Set tPrevProp = $lg(tPrevProps, i)
								If (""_tCurrProp) '= (""_tPrevProp) {
									Set tAttr = $case(i, 1: "IsImplicit", 2: "IndexType", 3: "PropType", 4: "StoreNulls", 5: "Unselective", : "Unknown")
									If tSameClass {
										Set tStatus = $$$ERROR($$$EnsSearchTableInvalidLocalOverride, tTemplate.Name, tAttr, tTemplate.SourceClass, tPrevProp, tCurrProp)
									}
									Else {
										Set tStatus = $$$ERROR($$$EnsSearchTableInvalidInheritedOverride, tTemplate.Name, tAttr, $piece(tPrevDerivation,"~",*), tPrevProp, tTemplate.SourceClass, tCurrProp)
									}
									Quit
								}
							}
							If $$$ISERR(tStatus) Quit
						}
						ElseIf tSameClass { // Use the same location as was calculated for the sibling
							Set tTemplate.ClassDerivation = tPrevDerivation
						}
					}
					Else { // First time we are encountering the property, cache information
						Set tCheckProps(tTemplate.Name) = $lb(tTemplate.ClassDerivation, $$$PropCheckList(tTemplate), tDepth)
					}
					Set pSearchTableProperties(tTemplate.Name) = tTemplate
					Set tDocTypeSub = $select(tItem.DocType[":": tItem.DocType, 1: ":"_tItem.DocType)
					Set pSearchTableItems(tDocTypeSub,tItem.PropName,$tr(tItem.ValueGetExpression,$C(10,13),"")) = tItem
					Set tItemProps(tItem.PropName) = ""
				}
				If $$$ISERR(tStatus) Quit
			}
			If $$$ISERR(tStatus) Quit
			#; build an array of all props; props for a class override implicit props for it
			If $IsObject(tPropsList) {
				For i=tPropsList.Count():-1:1 {
					Set tTemplate = tPropsList.GetAt(i)
					Set tTemplate.ClassDerivation = tDerivation
					Set pSearchTableProperties(tTemplate.Name) = tTemplate
				}
			}
			Set tSuperComparison = ","_tClassDef.Super_","
			If (tSuperComparison [ ",Ens.VDoc.SearchTable,") || (tSuperComparison [ ",Ens.VDoc.XMLSearchTable,") {
				Quit
			}
			Set tSuper = $piece(tClassDef.Super,",",1)
			If (tSuper = "%Library.Persistent") || (tSuper = "%Persistent") {
				Set tSuper = $piece(tClassDef.Super,",",2)
			}
			Set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(tSuper)
		}
		If $$$ISERR(tStatus) Quit

		Set tThisDerivation = $extract(tDerivation,2,*)
		#; Correct derivation for each discovered property
		Set tPropKey = ""
		For {
			Set tPropKey = $order(pSearchTableProperties(tPropKey),1,tTemplate)
			Quit:(tPropKey = "")
			Set tDerivStart = "~"_tTemplate.ClassDerivation
			Set tTemplate.ClassDerivation = tTemplate.ClassDerivation _ $piece(tDerivation,tDerivStart,2,*)
		}

		#; Changed property definitions will update the saved ones
		#; For all Items, find or create the real Prop and its Id
		#; Then build the method
		Set tInitTLevel = $TLevel
		Try {
			TStart
			Set tPropName = ""
			For {
				Set tPropName = $order(tItemProps(tPropName))
				Quit:("" = tPropName)
				Set tXDataProp = pSearchTableProperties(tPropName)
				Set tStatus = ##class(Ens.Config.SearchTableProp).UpdateOrCreate(tXDataProp,.tProp,tClassname)
				If $$$ISERR(tStatus) Quit
				Set tDerivation = tXDataProp.ClassDerivation
				Set tStoredDerivation = tProp.ClassDerivation
				If ("~"_tThisDerivation_"~") '[ ("~"_$piece(tStoredDerivation,"~")_"~") {
					Set tProp.ClassDerivation = tDerivation ; preserve our ClassDerivation in case of conflict between peer subclasses
				}
				Set pSearchTableProperties(tPropName) = tProp ;replace the template with the real thing; now it has a PropId
			}
			If $$$ISERR(tStatus) Quit
			TCommit
		}
		Catch {
			Set tStatus = $$$EnsSystemError
		}
		While ($TLevel > tInitTLevel) {
			TRollback 1
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

ClassMethod getMethods(pDocClassname As %String, Output pProps, Output pItems, Output pTypeMethods) As %Status
{
	Set pTypeMethods = 0
	Set tSC = ..ValidateSearchTableProperties(%compiledclass.Name,.pProps,.pItems)
	If $$$ISERR(tSC) Quit tSC

	#; Build the types array of method name for each docType
	Set (n,nt,nn,tStoreFound)=0
	Set tiType="" For { Set tiType=$O(pItems(tiType))  Quit:""=tiType
		Set tType=$S(":"=tiType:"", 1:tiType)
		Set n=n+1
		If ""=tType { Set tStoreFound=1  Continue } ; the empty Type is implicit in this list, so skip it
		Set pTypeMethods(tType)=..getpropsmethodname(tType)
		If ""'=$P(tType,":") { Set nt=nt+1 }
		Else { Set nn=nn+1 }
	}
	Set pTypeMethods=n_","_nt_","_nn_","_tStoreFound
	Quit tSC
}

ClassMethod genMethods(pDocClassname As %String, ByRef pProps, ByRef pItems, ByRef pTypeMethods, pSearchTableSuper, ByRef pInsertLabels) As %Status
{
#define AnyMethods(%p)     $P(%p,",",1)
#define AnyTypeMethods(%p) $P(%p,",",2)
#define AnyNameMethods(%p) $P(%p,",",3)
#define AnyStoreMethod(%p) $P(%p,",",4)

	#; Build the method for each docType
	Set tSC=$$$OK
	Set pSearchTableSuper=$P(pSearchTableSuper,",",$L(pSearchTableSuper,","))
	Set tiType="" For { Set tiType=$O(pItems(tiType))  Quit:""=tiType  Set tType=$S(":"=tiType:"", 1:tiType)
		Set tMethodName=..getpropsmethodname(tType)
		Do %code.WriteLine(tMethodName_" ; Set values for type '"_tType_"'")
		Set tPropName="" For { Set tPropName=$O(pItems(tiType,tPropName))  Quit:""=tPropName  Set tProp=pProps(tPropName)
			Set tPropTable=$$$ClassSQLTable($P(tProp.ClassDerivation,"~"))
			Do %code.WriteLine(" ; Set "_tPropName_" for Type '"_tType_"'")
			Do %code.WriteLine(" Set tPropId = ..getPropId("""_tProp.ClassExtent_""","""_tPropName_""")")
			Do %code.WriteLine(" If tPropId { Set tCurrPropFound = 1 }")
			Do %code.WriteLine(" Else { Set tCurrPropFound = 0, tSCFindProp = $$$ADDSC($get(tSCFindProp,1), $$$ERROR($$$EnsErrGeneral, ""Unable to find metadata for SearchTable property '"_tProp.Name_"' in class '"_$piece(tProp.ClassDerivation,"~")_"'"")) }")
			If ""'=$P(tType,":") { Do %code.WriteLine(" Set tDocTypeCalled(tPropId)=1") }
			Elseif ""'=tType { Do %code.WriteLine(" Set tDocNameCalled(tPropId)=1") }
			Set tGetVal="" For { Set tGetVal=$O(pItems(tiType,tPropName,tGetVal),1,tItem)  Quit:""=tGetVal
				If ""=$P(tType,":") && tItem.Supersedable {
					If ""'=tType {
						Do %code.Write(" If 'tDocTypeCalled(tPropId) {")
					} Else {
						Do %code.Write(" If 'tDocTypeCalled(tPropId)&&'tDocNameCalled(tPropId) {")
					}
				}
				If '$data(pInsertLabels(tPropTable)) Set pInsertLabels(tPropTable) = $i(pInsertLabels)
				If '$classmethod(pSearchTableSuper,"IsListExpression",tGetVal) {
					Set tGetLine=$classmethod(pSearchTableSuper,"genGetCode",tGetVal)
					Set tGetLine=$Case(tProp.PropType
						,"Boolean":"("_tGetLine_"), tVal=$Case($ZCVT(tVal,""L""),""true"":1,""yes"":1,""on"":1,:''tVal)"
						,"Integer":"+("_tGetLine_")\1"
						,"Numeric":"+("_tGetLine_")"
						,"String:CaseInsensitive":"$ZCVT("_tGetLine_",""L"")"
						,:tGetLine)
					Do %code.WriteLine("  Set tSCGet=$$$OK, tVal="_tGetLine)
					Do:tItem.StoreNulls %code.WriteLine("  Set:tVal=""""&&$$$ISOK(tSCGet) tVal=$C(0)")
					Do %code.WriteLine("  If tCurrPropFound&&(""""'=tVal) {")
					Do %code.WriteLine("    Set tNormVal=$Replace(tVal,""|"",""+"")")
					Do %code.WriteLine("    Do SearchTableInsert"_pInsertLabels(tPropTable))
					Do %code.WriteLine("    If SQLCODE&&(-119'=SQLCODE) Set tProp="""_tPropName_""",tType="""_tType_""" Goto PropStoreError")
					Do %code.WriteLine("  } Set:$$$ISERR(tSCGet) tSC=$$$ADDSC(tSC,tSCGet)")
				} Else {
					Set tGetLine=$classmethod(pSearchTableSuper,"genGetCodeList",tGetVal,.tPreVal,.tPostVal) ; note: StoreNulls is ignored for list expressions
					Do %code.WriteLine("  Kill tList  Set tSCGet=$$$OK  Do "_tGetLine)
					Do %code.WriteLine("  If tCurrPropFound {")
					Do %code.WriteLine("    Set tVal="""" For { Set tVal=$O(tList(tVal))  Quit:""""=tVal")
					Set tValExpr=$G(tPreVal)_"tVal"_$G(tPostVal)
					Set tValExpr=$Case(tProp.PropType
						,"Boolean":"$Case($ZCVT("_tValExpr_",""L""),""true"":1,""yes"":1,""on"":1,:''"_tValExpr_")"
						,"Integer":"+("_tValExpr_")\1"
						,"Numeric":"+("_tValExpr_")"
						,"String:CaseInsensitive":"$ZCVT("_tValExpr_",""L"")"
						,:tValExpr)
					Do %code.WriteLine("      Set tNormVal=$Replace(("_tValExpr_"),""|"",""+"")")
					Do %code.WriteLine("      Do SearchTableInsert"_pInsertLabels(tPropTable))
					Do %code.WriteLine("      If SQLCODE&&(-119'=SQLCODE) Set tProp="""_tPropName_""",tType="""_tType_""" Goto PropStoreError")
					Do %code.WriteLine("    } Set:$$$ISERR(tSCGet) tSC=$$$ADDSC(tSC,tSCGet)")
					Do %code.WriteLine("  }")
				}
				If ""=$P(tType,":") && tItem.Supersedable {
					Do %code.Write(" }")
				}
			}
		}
		#; Goto the doc.Name method next
		If ""'=$P(tType,":") {
			Do %code.WriteLine(" Goto "_$S($$$AnyNameMethods(pTypeMethods):"DocNameSwitch", $$$AnyStoreMethod(pTypeMethods):"Store", 1:"DoneStore"))
		} ElseIf ""'=tType {
			Do %code.WriteLine(" Goto "_$S($$$AnyStoreMethod(pTypeMethods):"Store", 1:"DoneStore"))
		} Else {
			Do %code.WriteLine(" Goto DoneStore")
		}
	}
	Quit tSC
}

/// For a given SearchTable class, it returns a list
/// of the virtual search properties defined by that class and its superclasses.<br>
Query EnumerateSearchProps(Class As %String) As %Query(CONTAINID = 0, ROWSPEC = "Name:%String:Name of the virtual SearchTable property,PropId:%String:Compiler-generated ID value for this property name within this class's storage extent,PropType:%String:Datatype for values indexed under this property name,IndexType:%String:What type of indexing is used for this property")
{
}

ClassMethod EnumerateSearchPropsExecute(ByRef qHandle As %Binary, Class As %String) As %Status
{
	// get info
	Kill qHandle  Set qHandle=""
	Set tSC = ..getPropsList(.Class,.tProps) Quit:$$$ISERR(tSC) tSC
	Merge qHandle("props")=tProps
	Set qHandle("pos")=0
	Quit tSC
}

ClassMethod EnumerateSearchPropsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateSearchPropsExecute ]
{
	Kill Row Set Row="", pos=$G(qHandle("pos"))
	If ""'=pos {
		Set pos=pos+1  Set:pos>$G(qHandle("props")) pos=""  Set qHandle("pos")=pos
	}
	If ""=pos Set AtEnd=1 Quit $$$OK
	Set Row=$LB(qHandle("props",pos),qHandle("props",pos,"PropId"),qHandle("props",pos,"PropType"),qHandle("props",pos,"IndexType"))
	Quit $$$OK
}

ClassMethod EnumerateSearchPropsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateSearchPropsExecute ]
{
	Kill qHandle
	Quit $$$OK
}

/// Build an array of property definitions given a SearchTable class
ClassMethod getPropsList(pSearchTableClass As %String, Output pProps) As %Status
{
	Kill pProps  Set pProps=0, tSC=$$$OK

	If '($IsObject(pSearchTableClass) && (pSearchTableClass.%IsA("%Dictionary.CompiledClass") || pSearchTableClass.%IsA("%Dictionary.ClassDefinition"))) {
		Set pSearchTableClass=##class(%Dictionary.CompiledClass).%OpenId(pSearchTableClass,0,.tSC)  Quit:$$$ISERR(tSC) tSC
		$$$ASSERTNOLOG($IsObject(pSearchTableClass))
	}
	#; Generate Property population methods	
	Set tDerivation=""  For {
		Set tDerivation=tDerivation_"~"_pSearchTableClass.Name
		Quit:(","_pSearchTableClass.Super[",Ens.VDoc.SearchTable")||(","_pSearchTableClass.Super[",Ens.VDoc.XMLSearchTable")
		Set pSearchTableClass = ##class(%Dictionary.ClassDefinition).%OpenId(pSearchTableClass.Super,0,.tSC) Quit:$$$ISERR(tSC)
	} Set tDerivation=$E(tDerivation,2,*)
	Quit:$$$ISERR(tSC) tSC
	Set tLevels=$L(tDerivation,"~") For i=1:1:tLevels { Set tPartial=$P(tDerivation,"~",i,tLevels)
		&sql(Declare P1 Cursor for
			Select Name,PropId,PropType,IndexType into :tName,:tPropId,:tPropType,:tIndexType from Ens_Config.SearchTableProp Where ClassDerivation = :tPartial)
		&sql(OPEN P1) For { &sql(FETCH P1) Quit:SQLCODE
			Continue:$D(tIds(tPropId))
			Set tIds(tPropId)=""
			Set pProps($I(pProps))=tName
			Set pProps(pProps,"PropId")=tPropId
			Set pProps(pProps,"PropType")=tPropType
			Set pProps(pProps,"IndexType")=tIndexType
		} &sql(CLOSE P1)
	}
	Quit $$$OK
}

/// Get the PropId for a given property name in given a SearchTable class
ClassMethod getPropId(pSearchTableClass As %String, pPropName As %String, Output pPropType, Output pStoreNulls, Output pUnselective) As %Integer
{
	Set tSC=$$$OK, (pPropType,pStoreNulls,pUnselective)=""
	Kill pProps  Set pProps=0

	If '($IsObject(pSearchTableClass) && (pSearchTableClass.%IsA("%Dictionary.CompiledClass") || pSearchTableClass.%IsA("%Dictionary.ClassDefinition"))) {
		Set pSearchTableClass=##class(%Dictionary.CompiledClass).%OpenId(pSearchTableClass,0,.tSC)  Quit:$$$ISERR(tSC) tSC
		$$$ASSERTNOLOG($IsObject(pSearchTableClass))
	}
	#; Generate Property population methods	
	Set tDerivation=""  For {
		Set tDerivation=tDerivation_"~"_pSearchTableClass.Name
		Quit:(","_pSearchTableClass.Super[",Ens.VDoc.SearchTable")||(","_pSearchTableClass.Super[",Ens.VDoc.XMLSearchTable")
		Set pSearchTableClass = ##class(%Dictionary.ClassDefinition).%OpenId(pSearchTableClass.Super,0,.tSC) Quit:$$$ISERR(tSC)
	} Set tDerivation=$E(tDerivation,2,*)
	Quit:$$$ISERR(tSC) tSC

	Set tBaseExtent = $piece(tDerivation, "~", $length(tDerivation, "~"))
	Set tProp = ##class(Ens.Config.SearchTableProp).indexClassPropOpen(tBaseExtent, pPropName,,.tSC)
	If $IsObject(tProp) {
		Set tPropId = tProp.PropId
		Set pPropType = tProp.PropType
		Set pStoreNulls = tProp.StoreNulls
		Set pUnselective = tProp.Unselective
	}
	Else {
		Set tPropId = ""
	}
	Quit tPropId
}

ClassMethod getpropsmethodname(pType As %String) As %String [ CodeMode = expression ]
{
"Store"_$TR(pType,":. \/-'_?&()+#*,';<>[]{}""","zx")
}

/// Helper method for code generators
ClassMethod FindClassDefParameterVal(pClassDef As %Dictionary.CompiledClass, pParamName As %String) As %String
{
	If '($IsObject(pClassDef) && (pClassDef.%IsA("%Dictionary.CompiledClass") || pClassDef.%IsA("%Dictionary.ClassDefinition"))) {
		Set pClassDef=##class(%Dictionary.CompiledClass).%OpenId(pClassDef,0,.tSC)  Quit:$$$ISERR(tSC) ""
		$$$ASSERTNOLOG($IsObject(pClassDef))
	}
	Set tParmVal="" For iParm=1:1:pClassDef.Parameters.Count() { Set tParm=pClassDef.Parameters.GetAt(iParm)
		If tParm.Name=pParamName Set tParmVal=tParm.Default  Quit
	}
	Quit tParmVal
}

ClassMethod FindClassDefMethod(pClassDef As %Dictionary.CompiledClass, pMethodName As %String) As %Dictionary.CompiledMethod
{
	If '($IsObject(pClassDef) && (pClassDef.%IsA("%Dictionary.CompiledClass") || pClassDef.%IsA("%Dictionary.ClassDefinition"))) {
		Set pClassDef=##class(%Dictionary.CompiledClass).%OpenId(pClassDef,0,.tSC)  Quit:$$$ISERR(tSC) $$$NULLOREF
		$$$ASSERTNOLOG($IsObject(pClassDef))
	}
	Set tIndex = pClassDef.Methods.FindObjectId(pClassDef.Name_"||"_pMethodName)
	Quit:""=tIndex $$$NULLOREF
	Quit pClassDef.Methods.GetAt(tIndex)
}

ClassMethod FindClassDefProperty(pClassDef As %Dictionary.CompiledClass, pPropName As %String) As %Dictionary.CompiledProperty
{
	If '($IsObject(pClassDef) && (pClassDef.%IsA("%Dictionary.CompiledClass") || pClassDef.%IsA("%Dictionary.ClassDefinition"))) {
		Set pClassDef=##class(%Dictionary.CompiledClass).%OpenId(pClassDef,0,.tSC)  Quit:$$$ISERR(tSC) $$$NULLOREF
		$$$ASSERTNOLOG($IsObject(pClassDef))
	}
	Set tIndex = pClassDef.Properties.FindObjectId(pClassDef.Name_"||"_pPropName)
	Quit:""=tIndex $$$NULLOREF
	Quit pClassDef.Properties.GetAt(tIndex)
}

ClassMethod GetExtentSuperclass(pDerivedClass As %String) As %String
{
	If $IsObject(pDerivedClass) {
		If pDerivedClass.%IsA("%Dictionary.ClassDefinition") || pDerivedClass.%IsA("%Dictionary.CompiledClass") {
			Set tClass=pDerivedClass.Name
		} Else {
			Set tClass=$classname(pDerivedClass)
		}
	} Else {
		Quit:'##class(%Dictionary.CompiledClass).%ExistsId(pDerivedClass) ""
		Set tClass=pDerivedClass
	}
	Quit:$$$cCLASSCLASSTYPEPERSISTENT'=$$$comClassKeyGet(tClass,$$$cCLASSclasstype) ""
	Quit:$$$comClassKeyGet(tClass,$$$cCLASSnoextent) ""

	If $get($$$EXTrootclass($$$pEXT,tClass)) Quit tClass
	Set tExtent = $get($$$EXTroot($$$pEXT,tClass))
	While (tExtent '= "") && ('$get($$$EXTrootclass($$$pEXT,tExtent))) {
		Set tExtent = $get($$$EXTroot($$$pEXT,tExtent))
	}
	Quit tExtent
}

ClassMethod GetExtentSupertable(pDerivedClass As %String) As %String
{
	Set tExtentSuperclass=..GetExtentSuperclass(pDerivedClass)  Quit:""=tExtentSuperclass ""
	Quit $$$ClassSQLTable(tExtentSuperclass)
}

ClassMethod DeleteProps(pSearchTableExtentSuperclass As %String) As %Status
{
	&sql(DELETE from Ens_Config.SearchTableProp where ClassExtent=:pSearchTableExtentSuperclass)
	Quit $Case(SQLCODE, 0:$$$OK, 100:$$$OK, :$$$ERROR($$$EnsErrGeneral,"Error while attempting to delete props for SearchTable Extent Superclass "_pSearchTableExtentSuperclass_"; SQLCODE="_SQLCODE))
}

}
