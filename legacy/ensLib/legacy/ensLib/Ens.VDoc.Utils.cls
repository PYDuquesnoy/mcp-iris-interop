/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %systemInclude)

/// This class contains a number of utility methods used to expose metadata of virtual document classes
Class Ens.VDoc.Utils Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Find out if a given class is a Virtual Document (i.e., supports the Ens.VDoc.Interface)
ClassMethod IsVirtualDocument(pClass As %String) As %Boolean
{
	// see if the class supports the virtual document interface
	Set $ZT = "Trap"
	Quit $classmethod(pClass,"%Extends","Ens.VDoc.Interface")
Trap
	Quit 0
}

/// This query returns information for the DTL editor.<br>
/// For a given class and <i>document type</i>, it returns a list
/// of properties.<br>
/// <var>Mode</var> is either "target" or "source".
Query EnumerateDocContents(Class As %String, Mode As %String = "source", DocType As %String = "", Level As %Integer = 0, DotAbbrevs As %Boolean = 1, ForceObjectProps As %Boolean = 0, pIncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Property:%String:Specification of the path to a property in the object,Type:%String:Datatype of the property") [ SqlProc ]
{
}

ClassMethod EnumerateDocContentsExecute(ByRef qHandle As %Binary, Class As %String, Mode As %String, DocType As %String, Level As %Integer, DotAbbrevs As %Boolean = 1, ForceObjectProps As %Boolean, pIncludeBase As %Boolean) As %Status
{
	// HCR010 changes this query to ignore any errors and always return $$$OK,
	// because there are known structure problems in the HL7 schema definitions.
	Kill qHandle  Set qHandle=$I(^IRIS.Temp.Ens.EnumProps)
	Set tSC = ..GetInfoArray($Name(^IRIS.Temp.Ens.EnumProps(qHandle)),.Class,.Mode,.DocType,.Level,.ForceObjectProps,,.pIncludeBase)
	Set qHandle("pos")=0, qHandle("DotAbbrevs")=DotAbbrevs
	Quit $$$OK // Always return $$$OK
}

ClassMethod EnumerateDocContentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateDocContentsExecute ]
{
	Kill Row Set Row=""
	Set pos=$$posincr($G(qHandle("pos"),0)), qHandle("pos")=pos
	If ""=pos Set AtEnd=1 Quit $$$OK
	Set propname=$$propname(pos)
	Set Row=$LB(propname,$G(@("^IRIS.Temp.Ens.EnumProps("_qHandle_","_pos_",""type"")")))
	Quit $$$OK
posincr(pos) ; find the next position - deep first if possible
	Set val=$G(@("^IRIS.Temp.Ens.EnumProps("_qHandle_","_pos_")"))
	Quit:+val>0 $$posincr(pos_",0") ; down one level
	Quit $$posnext(pos) ; next item
posnext(pos) ; do the next position at the current level
	Quit:""=pos ""
	Set c=$L(pos,",")
	Do { Set npos=$O(@("^IRIS.Temp.Ens.EnumProps("_qHandle_","_pos_")"))  Set $P(pos,",",c)=""""_npos_"""" } While +npos'=npos&&(npos'="")
	Quit $S(""'=npos:pos, ""=pos:"", 1:$$posnext($P(pos,",",1,c-1))) ; back up one level (and next item)
propname(pos)
	Set propname=""
	For i=1:1:$L(pos,",")-1 Set proppc=@("^IRIS.Temp.Ens.EnumProps("_qHandle_","_$P(pos,",",1,i)_",""name"")"), propname=propname_$S('qHandle("DotAbbrevs"):$S(":"=$E(proppc):"",1:".")_proppc, ":"=$E(proppc):":", 1:".")
	Set i=i+1, proppc=@("^IRIS.Temp.Ens.EnumProps("_qHandle_","_$P(pos,",",1,i)_",""name"")"), propname=propname_$S(":"=$E(proppc):"",1:".")_proppc
	Quit $E(propname,2,*)
}

ClassMethod EnumerateDocContentsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateDocContentsExecute ]
{
	Kill:""'=$G(qHandle) ^IRIS.Temp.Ens.EnumProps(qHandle)
	Kill qHandle
	Quit $$$OK
}

/// This query returns information for the DTL editor.<br>
/// For the given class, it returns a set of document types.<br>
Query EnumerateDocTypes(Class As %String, Category As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "Type:%String") [ SqlProc ]
{
}

ClassMethod EnumerateDocTypesExecute(ByRef qHandle As %Binary, Class As %String, Category As %String, IncludeBase As %Boolean) As %Status
{
 	Set tSC=$$$OK, qHandle="", $ZT="Trap"
	Do {
		// dispatch to EnumerateDocTypes query in document class if the class supports the virtual document interface
		If ..IsVirtualDocument(Class) {
			Set tSC = $classmethod(Class,"EnumerateDocTypesExecute",.qHandle,.Category,.IncludeBase)
			Set qHandle("class")=Class
		}
	} While(0)
	Quit tSC
Trap
	Set $ZT=""  Kill qHandle  Set qHandle=""
	Quit $$$OK
}

ClassMethod EnumerateDocTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	// dispatch to EnumerateDocTypes query in document class if the class supports the virtual document interface
	Quit:""'=$G(qHandle("class")) $zobjclassmethod(qHandle("class"),"EnumerateDocTypesFetch",.qHandle,.Row,.AtEnd)

	// default behavior
	If ""=qHandle {
		Set Row=$LB(""), AtEnd=1, qHandle = 0
	} Else {
		Set Row="", AtEnd=1
	}
	Quit $$$OK
}

ClassMethod EnumerateDocTypesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateDocTypesExecute ]
{
	// dispatch to EnumerateDocTypes query in document class if the class supports the virtual document interface
	Quit:""'=$G(qHandle("class")) $zobjclassmethod(qHandle("class"),"EnumerateDocTypesClose",.qHandle)

	// default behavior
	Kill qHandle
	Quit $$$OK
}

/// Returns a list of document type schema categories for the given virtual document class, or for all virtual document classes that have associated schemas.<br>
/// The Std parameter can be used to restrict the list.<br>
/// If Std is:
///  0 - return only standard categories
///  + - return only user-defined categories
///  empty - return all categories
///  a partial category name - return only categories starting with the given category name part<br/>
///  other - return nothing
Query EnumerateVDocSchemas(VDocClass As %String = "", Std As %String = "") As %Query(ROWSPEC = "VDocClass:%String,Category:%String,IsStd:%Boolean,Family:%String,SchemaDocExt:%String,Base:%String")
{
}

ClassMethod EnumerateVDocSchemasExecute(ByRef qHandle As %Binary, VDocClass As %String = "", Std As %String = "") As %Status
{
	Kill qHandle  Set qHandle=""
	Kill %objlasterror
	If ""'=VDocClass {
		Set tSchemaClass = $$$GetClassParameter(VDocClass,"SCHEMACLASS")
		Set:""'=tSchemaClass qHandle("vdsc",tSchemaClass)=VDocClass
	}
	Else {
		Set tRS=##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")  Quit:'$IsObject(tRS) $G(%objlasterror)
		Do tRS.Execute("Ens.VDoc.Interface")
		While tRS.Next(.tSC) && $$$ISOK(tSC) {
			Set tClassname=tRS.Data("Name")  Continue:'##class(%Dictionary.CompiledClass).%ExistsId(tClassname)
			Set tSchemaClass = $$$GetClassParameter(tClassname,"SCHEMACLASS")
			If ""'=tSchemaClass && '$D(qHandle("vdsc",tSchemaClass)) {
				Set qHandle("vdsc",tSchemaClass)=tClassname
			}
		}
	}
	Set qHandle=$I(%EnsEnumVDSchema), qHandle("Std")=$G(Std), qHandle("sCls")=""
 	Quit $$$OK
}

ClassMethod EnumerateVDocSchemasFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateVDocSchemasExecute ]
{
	Set $ZT="Trap",tSC=$$$OK, Row="", AtEnd=0
	Do {
		Set tQ=qHandle
		For { ; go until we get a category
			Set tRS=$G(%EnsEnumVDSchema(tQ,"RS"))
			If '$IsObject(tRS) {
				#; move to next schema class
				Set qHandle("sCls")=$O(qHandle("vdsc",$G(qHandle("sCls"))),1,tClassname)
				If ""=qHandle("sCls") Set AtEnd=1  Quit
				Set tSchemaClass=qHandle("sCls")
				Set tSubType=$P(tSchemaClass,":",3)
				Set tSubscript=$P(tSchemaClass,":",2)
				Set tSchemaClass=$P(tSchemaClass,":",1)
				Set tSchemaDocClass=$P(tSchemaClass,".",1,$L(tSchemaClass,".")-1)_".SchemaDocument"
				Set tSchemaDocExt=$E($$$GetClassParameter(tSchemaDocClass,"EXTENSION"),2,*)
				Continue:""=tSchemaDocExt

				#; re-construct typeCategories result set for new schema class / subType
				Kill %objlasterror
				Set tRS=##class(%ResultSet).%New(tSchemaClass_":TypeCategories")  If '$IsObject(tRS) Set tSC=$G(%objlasterror)  Quit
				If ""=tSubType { Set tSC=tRS.Execute(qHandle("Std"))  Quit:$$$ISERR(tSC) }
				Else { Set tSC=tRS.Execute(qHandle("Std"),tSubType)  Quit:$$$ISERR(tSC) }
				Set %EnsEnumVDSchema(tQ,"RS")=tRS
			} Else {
				Set tClassname=$G(qHandle("vdsc",$G(qHandle("sCls"))))
				Set tSchemaClass=qHandle("sCls")
				Set tSchemaDocClass=$P(tSchemaClass,".",1,$L(tSchemaClass,".")-1)_".SchemaDocument"
				Set tSchemaDocExt=$E($$$GetClassParameter(tSchemaDocClass,"EXTENSION"),2,*)
			}
			If 'tRS.Next(.tSC) || '$$$ISOK(tSC) { ; move to next schema category for current schema class
				Set %EnsEnumVDSchema(tQ,"RS")=$$$NULLOREF
			} Else {
				Quit
			}
		}
		If 'AtEnd {
			Set tFamily = $$$GetClassParameter(tClassname,"DOCSHORTNAME")
			Set Row=$LB(tClassname,tRS.Data("Category"),tRS.Data("IsStandard"),tFamily,tSchemaDocExt,tRS.Data("Base"))
		}
	} While 0
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

ClassMethod EnumerateVDocSchemasClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateVDocSchemasFetch ]
{
	Set tQ=$G(qHandle)
	Kill:tQ %EnsEnumVDSchema(tQ)  Kill:tQ=1 %EnsEnumVDSchema ; in-proc so no concurrency issues
	Kill qHandle
	Quit $$$OK
}

/// Get one node from a (virtual) array of property information for the given target/source class.<br>
/// This node is addressed by a comma-separated list of descending ordinal positions.
ClassMethod GetInfoArray(Output pArray, pClass As %String = "", pMode As %String = "source", pDocType As %String = "", pMaxLevel As %Integer = 0, pForceObjectProps As %Boolean = 0, pNodeAddr As %String = "", pIncludeBase As %Boolean) As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	Quit:'##class(%Dictionary.ClassDefinition).%ExistsId(pClass) $$$ERROR($$$EnsErrGeneral,"Class '"_pClass_"' does not Exist")

	// see if the class supports the virtual document interface
	If ..IsVirtualDocument(pClass) && 'pForceObjectProps {
		Set tIsXMLVDoc = 0
		Try {
			Set tIsXMLVDoc = $classmethod(pClass,"%Extends","EnsLib.EDI.XML.Document")
		}
		Catch {}
		#; At present, only XML VDocs support pNodeAddr
		If tIsXMLVDoc {
			Quit $classmethod(pClass,"GetContentArray",.pArray,pMode,pDocType,pMaxLevel,.pIncludeBase,,pNodeAddr)
		}
		Else {
			Quit $classmethod(pClass,"GetContentArray",.pArray,pMode,pDocType,pMaxLevel,.pIncludeBase)
		}
	}
	Set tRef=$G(pArray)
	If ("%"=$E(tRef)||("^"=$E(tRef))) {
		$$$KillRootNode(@tRef)
		New %ptree
	} Else {
		Kill pArray
		Set tRef="%local"
		New %local,%ptree
	}
	// by default, return list of properties for class
	Set:pMaxLevel tLev=pMaxLevel ; otherwise leave tLev as Undefined so as to pick up default level
	Set tSC = ##class(Ens.Rule.Utils).GetPropertyTree(.%ptree,pClass,,.tLev,pNodeAddr)  Quit:$$$ISERR(tSC) tSC
	Do addprops("","")
	merge:tRef="%local" pArray=%local
	Quit tSC
addprops(rpos,tpos)
	New %rpos,%tpos,%k,%i,%tTreeRef,%ttRef,%info,%seq,%type  Set %rpos=rpos, %tpos=tpos
	Set %tTreeRef=$S(""=%tpos:"%ptree",1:"%ptree("_%tpos_")")
	Set %ttRef=$S(""=%rpos:tRef, ")"=$E(tRef,*):$E(tRef,1,*-1)_","_%rpos_")", 1:tRef_"("_%rpos_")")
	Set %k="" For %i=1:1  { Set %k=$O(@%tTreeRef@(%k),1,%info) Quit:""=%k
		#; tree(pdef.Name) = $LB(type,..GetClassType(type),pdef.Collection,pdef.Description,pdef.SequenceNumber)
		Set %seq=+$LI(%info,5), @%ttRef@(%seq,"name")=%k_$S(""=$LI(%info,3):"",1:"()"), %type=$LI(%info,1)  Set:$Case(%type,"%Library.String":0,"%Library.RawString":0,"%Library.CacheString":0,:1) @%ttRef@(%seq,"type")=%type
		Do addprops($S(""=%rpos:"",1:%rpos_",")_%seq, $S(""=%tpos:"",1:%tpos_",")_""""_%k_"""")
		#; If ..IsVirtualDocument(@%ttRef@(%seq,"type")) {	}
	}
	Set:%i>1 @%ttRef=%i-1
	Quit
Trap
	Set $ZT="",tZE=$ZE
	Quit $$$ERROR($$$EnsErrGeneral,"Exception in GetInfoArray("_$G(pClass)_","_$G(pMode)_","_$G(pDocType)_") : "_$g(tZE))
}

/// Get the array of property information for the given virtual document target/source class.<br>
/// This array is indexed by property name.
ClassMethod GetIndexedInfoArray(Output pArray, pClass As %String, pMode As %String, pDocType As %String, pMaxLevel As %Integer) As %Status
{
	// first get unindexed array
	Kill pArray  New %tArray
	Set tSC = ..GetInfoArray(.%tArray, .pClass, .pMode, .pDocType, .pMaxLevel) Quit:$$$ISERR(tSC) tSC
	Set (n,pos)=0 For { Set pos=$$posincr(pos)  Quit:""=pos  Set n=n+1
		Set tProp=$$propname(pos)
		Set pArray(tProp)=$G(@("%tArray("_pos_",""alias"")"),$S(""=pDocType:"",1:$zobjclassmethod(pClass,"GetAlias","%tArray",pos)))
		#;- "type" not used so far
		#;Set tType=$G(@("%tArray("_pos_",""type"")"))
		#;Set:""'=tType pArray(tProp,"type")=tType
	}
	Set:n>0 pArray=n
	Quit $$$OK
posincr(pos) ; find the next position - deep first if possible
	Set val=$G(@("%tArray("_pos_")"))
	Quit:+val>0 $$posincr(pos_",0") ; down one level
	Quit $$posnext(pos) ; next item
posnext(pos) ; do the next position at the current level
	Quit:""=pos ""
	Set c=$L(pos,",")
	Do { Set npos=$O(@("%tArray("_pos_")"))  Set $P(pos,",",c)=""""_npos_"""" } While +npos'=npos&&(npos'="")
	Quit $S(""'=npos:pos, ""=pos:"", 1:$$posnext($P(pos,",",1,c-1))) ; back up one level (and next item)
propname(pos)
	Set propname=""
	For i=1:1:$L(pos,",") Set propname=propname_"."_@("%tArray("_$P(pos,",",1,i)_",""name"")")
	Quit $E(propname,2,*)
}

/// Return the document interface expression for an expression
/// For virtual documents using GetValueAt() the default is to set a status output variable named tSCGet, 
/// but if <param>pSC</param> is null, no status output variable will be included
ClassMethod GetGetCode(pCode As %String, pLanguage As %String, pCheckEmptyAsNull As %Boolean = 0, pSC As %String = "tSCGet") As %String
{
	for {
		set f=$f(pCode,"{") if f=0 quit
		set g=$f(pCode,"}",f) if g=0 quit
		if $e(pCode,f-2)'="." quit
		set path=$e(pCode,f,g-2)
		if $f(path,"{") quit
		if pLanguage=$$$objectscript {
			set pCode=$e(pCode,1,f-2)_"GetValueAt("_..quoteDocumentPath(path)_",,"_$S(pSC'="":"."_pSC,1:"")_$S(pCheckEmptyAsNull:",..#TREATEMPTYREPEATINGFIELDASNULL",1:"")_")"_$e(pCode,g,*)
		} else {
			set pCode=$e(pCode,1,f-2)_"GetValueAt("_..quoteDocumentPath(path,1)_",,"_pSC_$S(pCheckEmptyAsNull:",Me.%GetParameter(""TREATEMPTYREPEATINGFIELDASNULL"")",1:"")_")"_$e(pCode,g,*)
		}
	}
	quit pCode
}

/// Return the document interface iterator next code
ClassMethod GetNextCode(Output pCode, Output pComplete As %Boolean, pProperty As %String, pKey As %String, pLanguage As %String, pSC As %String = "tSCTrans") As %Status
{
	set pComplete=1
	set f=$f(pProperty,"{") if f=0 set pComplete=0 Quit $$$OK
	if $e(pProperty,f-2)'="." set pComplete=0 Quit $$$OK
	if $e(pProperty,*)'="}" set pComplete=0 Quit $$$OK
	set path=$e(pProperty,f,*-1)
	set pCode=$e(pProperty,1,f-2)_"GetNextIndex("_..quoteDocumentPath(path,(pLanguage'=$$$objectscript))_","_pKey_","_$select(pLanguage=$$$objectscript: ".", 1: "")_pSC_")"
	quit $$$OK
}

/// Return the Set code expression for an assign element
ClassMethod GetSetCode(Output pCode As %String, Output pComplete As %Boolean, pProperty As %String, pValue As %String, pAction As %String, pKey As %String, pLanguage As %String, pSameClass As %Boolean = 1, pAddDTLParams As %Boolean = 0) As %Status
{
	if '..isSingleVirtualProperty(pProperty,.tPropertyObject,.tPropertyPath) set pComplete=0 quit $$$OK
	set pComplete=1
	if pSameClass && ..isSingleVirtualProperty(pValue,.tValueObject,.tValuePath) {
		if pLanguage=$$$objectscript {
			set pCode=" Set tSC1="_tPropertyObject_".CopyValues("_tValueObject_","_..quoteDocumentPath(tValuePath)_","_..quoteDocumentPath(tPropertyPath)_","""_pAction_""","_pKey_$S(pAddDTLParams:",..#TREATEMPTYREPEATINGFIELDASNULL,..#IGNOREMISSINGSOURCE,..#GENERATEEMPTYSEGMENTS",1:"")_")"
		} else {
			set pCode="   tSC1="_tPropertyObject_".CopyValues("_tValueObject_","_..quoteDocumentPath(tValuePath,1)_","_..quoteDocumentPath(tPropertyPath,1)_","""_pAction_""","_pKey_$S(pAddDTLParams:",Me.%GetParameter(""TREATEMPTYREPEATINGFIELDASNULL""),Me.%GetParameter(""IGNOREMISSINGSOURCE""),Me.%GetParameter(""GENERATEEMPTYSEGMENTS"")",1:"")_")"
		}
	} else {
		set pValue=..GetGetCode(pValue,pLanguage,pAddDTLParams,"tSCGet")
		if pLanguage=$$$objectscript {
			set pCode=" Try { Set tSC1="_tPropertyObject_".SetValueAt("_pValue_","_..quoteDocumentPath(tPropertyPath)_","""_pAction_""","_pKey_")  "_$Select(pValue["tSCGet":"If $$$ISERR(tSCGet) { Set tSC1=$$$ADDSC(tSC1,tSCGet)  Set tSCGet=$$$OK }",1:"")_" } Catch ex { Set tSC1 = ex.AsStatus() }"
		} else {
			set pCode="   Try tSC1="_tPropertyObject_".SetValueAt("_pValue_","_..quoteDocumentPath(tPropertyPath,1)_","""_pAction_""","_pKey_") "_$Select(pValue["tSCGet":": If System.Status.IsError(tSCGet) Then tSC1=System.Status.AppendStatus(tSC1,tSCGet) : tSCGet=System.Status.OK() : End If ",1:"")_": Catch ex tSC1=ex.AsStatus() : End Try"
		}
	}
	quit $$$OK
}

ClassMethod isSingleVirtualProperty(pExpression, pObject, pProperty) As %Boolean
{
	set (pObject,pProperty)=""
	set f=$F(pExpression,"{") quit:'f 0
	quit:$E(pExpression,f-2)'="." 0
	quit:$F(pExpression,"{",f) 0
	quit:$F(pExpression,"}")'=($L(pExpression)+1) 0
	set pObject=$E(pExpression,1,f-3)
	If '..isPseudoVDocBatchProperty(pObject) {
		 quit:'$ZName(pObject)&&'##class(Ens.BPL.Transform).isProperty(pObject) 0
	}
	set pProperty=$E(pExpression,f,*-1)
	quit 1
}

ClassMethod isPseudoVDocBatchProperty(pObject) As %Boolean
{
	/*
		pObject has had .{xyz} removed
		These pseudo vdoc batch properties point to VDoc Documents so for example from:
		<assign value='"ICode10"' property='target.FunctionalGroups(1).{GS:FunctionalIdentifierCode}' action='set' />
		we want to generate:
		Set tSC1=target.FunctionalGroups(1).SetValueAt("ICode10","GS:FunctionalIdentifierCode","set","") 
		rather than invalid
		Set target.FunctionalGroups(1).GetValueAt("GS:FunctionalIdentifierCode")="ICode10" 
		We intercept here rather than adding to Ens.BPL.Transform::isProperty
	*/
	#dim isPseudoVDocBatchProperty = 0
	If $E(pObject,*)=")" {
		#dim lastPiece = $Piece($Piece(pObject,".",*),"(")
		#dim pseudoProperty
		For pseudoProperty= "FunctionalGroups","TransactionSets" {
			If lastPiece = pseudoProperty {
				Set isPseudoVDocBatchProperty = 1
				Quit
			}
		}
	}
	Return isPseudoVDocBatchProperty
}

ClassMethod quoteDocumentPath(pCode As %String, pLangBasic As %Boolean = 0) As %String
{
	set inquote=0,inparen=0
	set concat=$S(pLangBasic:"&",1:"_")
	set tOutput=""""
	for i=1:1 {
		if i>$l(pCode) quit
		set c=$e(pCode,i),n=$e(pCode,i+1)
		if c="""" set inquote='inquote set tOutput=tOutput_c continue
		if inquote set tOutput=tOutput_c continue

		if c'="(",c'=")" set tOutput=tOutput_c continue

		if inparen=0,c="(",n=")" set tOutput=tOutput_c_n,i=i+1 continue
		if inparen=0,c="(",n="*",")"=$e(pCode,i+2) set tOutput=tOutput_"(*)",i=i+2 continue

		if c="(" set inparen=inparen+1 if inparen=1 set tOutput=tOutput_c_""""_concat_"(" continue
		if c=")" set inparen=inparen-1 if inparen=0 set tOutput=tOutput_")"_concat_""""_c continue

		set tOutput=tOutput_c continue
	}
	if inparen quit $$$quote(pCode)
	set tOutput=tOutput_""""
	quit tOutput
}

}
