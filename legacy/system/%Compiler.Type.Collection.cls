/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Collection specific property superclass, for internal use only
Class %Compiler.Type.Collection Extends %Compiler.Type.Object [ NoContext, System = 1 ]
{

/// STORAGEDEFAULT is the type of storage used for the collection if it is not already
/// allocated in a DATA definition in the active STORAGE definition. LIST collections
/// default to list storage and ARRAY collections default to array storage (SUBNODE structure).
Parameter STORAGEDEFAULT As STRING [ Constraint = ",array,list", Flags = ENUM ];

/// SQLPROJECTION is the way this collection will be projected to SQL - either as a simple
/// COLUMN or as a child TABLE or both.
Parameter SQLPROJECTION As STRING [ Constraint = ",table,column,table/column", Flags = ENUM ];

/// SQLTABLENAME is the name of the projected child table for this collection. If
/// the collection is not projected as a child table (refer to SQLPROJECTION) then
/// this parameter is ignored.
Parameter SQLTABLENAME As STRING;

Parameter CollectionDisplayDelimiter As STRING = "$C(13,10)";

Parameter CollectionOdbcDelimiter As STRING = """,""";

/// ACCESSPOLICY defines how collection is fetched to the client application.
/// 
/// 	EAGER:	The whole collection is fetched no later than it is first accessed by application in any manner.
/// 				If collection contains object values then objects are opened and instantiated in application memory.
/// 				For applications using POJO mode this means that application can use this collection even if it has
/// 				been disconnected from the server afterwards. Value EAGER is a requirement, meaning that if it is
/// 				specified then EAGER policy always be employed.
/// 
/// 	LAZY: 	Values in collection can be fetched as they are requested by the application, e.g. when methods get()
/// 				or Iterator.next() are invoked. Value LAZY is a hint meaning that if it is specified it tells that LAZY
/// 				policy may be used for this collection but does not guarantee that it is used. In case LAZY fetching is
/// 				used collection may become invalid when application disconnected from the server.
Parameter ACCESSPOLICY As STRING [ Constraint = ",lazy,eager", Flags = ENUM ];

ClassMethod BuildValueArray(value As %Binary, array As %Binary) As %Status [ CodeMode = generator, Final, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) Quit $$$OK
	$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="##class("_type_").BuildValueArray(value,.array)"
	QUIT $$$OK
}

/// Returns an oref, performing swizzling if necessary it returns "" ($$$NULLOREF) if there is no oref and the id=""
/// If <var>noswizzle</var> is passed as true then this will just return the current value for the property, so if it
/// has been swizzled already then it will return the oref, if it has not been swizzled it will return "" ($$$NULLOREF).
Method GetSwizzled(noswizzle As %Boolean = 0) As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	set tMVEnabled = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVENABLED",$$$cPARAMdefault)
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) If calculated Quit $$$OK
	$$$comMemberKeyGetLO(sqlcomputed,origin,%class,$$$cCLASSproperty,%property,$$$cPROPsqlcomputed)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,$$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype))
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$comMemberKeyGetLO(readonly,origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly)
	Set qprop=$$$QN(%property)
	$$$GENERATE("	If noswizzle { RETURN r%"_qprop_" }" )
	$$$GENERATE("	Set oref=##class("_runtimetype_").%New() If oref=$$$NULLOREF Quit $$$NULLOREF")
	$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_qprop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
	$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
	Set propclasstype=$$$getClassType(type)
	If propclasstype=$$$cCLASSCLASSTYPEDATATYPE {
		Set code="	Set oref.ElementType="""_%class_":"_$replace(qprop,"""","""""")_""""
	} ElseIf propclasstype=$$$cCLASSCLASSTYPESTREAM,type'="%Library.GlobalBinaryStream",type'="%Library.GlobalCharacterStream",type'="%Library.FileBinaryStream",type'="%Library.FileCharacterStream" {
		Set code="	Set oref.ElementType="""_type_""",oref.LiteralBehavior=1"
	} Else {
		Set code="	Set oref.ElementType="""_type_""""
	}
	If propclasstype=$$$cCLASSCLASSTYPESTREAM {
		$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
		If initialexpression=""||(initialexpression="""""") Set initialexpression = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
		Set code=code_",oref.StreamLocation="_initialexpression
	}
	$$$GENERATE(code_",oref.ElementClassType="""_propclasstype_""",oref.Owner=+$this,oref.Storage=$this."_$$$QuoteName(%property_"%i")_"(),oref.OrefStorage=oref.Storage+1"_$select(readonly:",oref.ReadOnly=1",1:""))
	If sqlcomputed {
		Set strIDExpr = $Select($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT:"..%Id()",1:"""""")
			#; Construct the Compute() method parameter list using in-memory props as actual args
		$$$comMemberKeyGetLO(lstRefs,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcomputedependency)
		set strComputeParms = "" For ptr = 1:1:$ListLength(lstRefs) {
			set parmProp = $List(lstRefs,ptr)
			Set qparmProp="" For i=1:1:$length(parmProp,".") { Set qparmProp=qparmProp_"."_$$$QN($piece(parmProp,".",i)) } Set qparmProp=$extract(qparmProp,2,*)
			if $$$comMemberDefined(%class,$$$cCLASSproperty,parmProp) {
				$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,parmProp,$$$cPROPruntimetype)
				set classtype=$$$getClassType(type)
				if classtype = $$$cCLASSCLASSTYPEDATATYPE { set parmExpr = ".."_qparmProp }
				else {
					$$$comMemberKeyGetLvar(collection,%class,$$$cCLASSproperty,parmProp,$$$cPROPcollection)
					if collection = "" {
						set classinoid = +$$$comMemberArrayGet(%class,$$$cCLASSproperty,parmProp,$$$cPROPparameter,"CLASSNAME")
						set parmExpr = ".."_$$$QN(parmProp_"GetObject" _ $Select('classinoid:"Id",1:""))_"(0)"
					}
					else {
						$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,parmProp,$$$cPROPtype)
						set classtype=$$$getClassType(type)
						set parmExpr = ".."_qparmProp_".Serialize(" _ $Select(classtype=$$$cCLASSCLASSTYPEDATATYPE:"",1:"0")_")"
					}
				}
			}
			else { set parmExpr = ".." _ qparmProp }
			Set strComputeParms = strComputeParms _ "," _ parmExpr
		}
		$$$GENERATE("	Set serialcol=.."_$$$QN(%property_"Compute")_"(" _ strIDExpr _strComputeParms_")")
		$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)

		If type="cl" {
			quit $$$OK
		}
		elseif type="ca" {
			QUIT $$$OK
		}
		If propclasstype=$$$cCLASSCLASSTYPEDATATYPE {
			If collection=$$$cPROPCOLLECTIONLIST {
				if 'tMVEnabled {
					$$$GENERATE("	Set ptr=0,i=0 While $listnext(serialcol,ptr,item) { Set i%"_qprop_"($increment(i))=item }")
				} else {
					$$$GENERATE("	for i=1:1:$Length(serialcol,$mvv(2)) set i%"_qprop_"(i)=$piece(serialcol,$mvv(2),i)")
				}
			} Else {
				if 'tMVEnabled {
					$$$GENERATE("	Set ptr=0 While $listnext(serialcol,ptr,item) { Set i%"_qprop_"($list(item))=$list(item,2) }")
				} else {
					$$$GENERATE("	for ptr=1:1:$length(serialcol,$mvv(2)) set tmp=$Piece(serialcol,$mvv(2),i),i%"_qprop_"($piece(tmp,$mvv(3)))=$piece(tmp,$mvv(3),2)")
				}
			}
		} Else {
			If collection=$$$cPROPCOLLECTIONLIST {
				if 'tMVEnabled {
					$$$GENERATE("	Set ptr=0,i=0 While $listnext(serialcol,ptr,item) { Set r%"_qprop_"($increment(i))=$$$NULLOREF,i%"_qprop_"(i)=item }")
				} else {
					$$$GENERATE("	for i=1:1:$Length(serialcol,$mvv(2)) set r%"_qprop_"(i)=$$$NULLOREF,i%"_qprop_"(i)=$piece(serialcol,$mvv(2),i)")
				}
			} Else {
				if 'tMVEnabled {
					$$$GENERATE("	Set ptr=0 While $listnext(serialcol,ptr,item) { Set key=$list(item),r%"_qprop_"(key)=$$$NULLOREF,i%"_qprop_"(key)=$list(item,2) }")
				} else {
					$$$GENERATE("	for ptr=1:1:$length(serialcol,$mvv(2)) set tmp=$Piece(serialcol,$mvv(2),i),key=$piece(tmp,$mvv(3)),r%"_qprop_"(key)=$$$NULLOREF,i%"_qprop_"(key)=$piece(tmp,$mvv(3),2)")
				}
			}
		}
	}
	$$$GENERATE("	Do $system.CLS.SetModified(oref,0)")
	$$$GENERATE("	Quit oref")
	QUIT $$$OK
}

Method NewObject() As %ObjectHandle [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; Do not need a New object method for collections
	Quit $$$OK
}

/// Set the property to an oref value if the new oref is different from an old oref, the old object is closed                                                             |
Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated or readonly
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	If $$$comMemberKeyGetO(origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) QUIT $$$OK
	Set qprop=$$$QN(%property)
	#; if newvalue if not a valid oref, quit with 0
	$$$GENERATE("	If '$$$objExists(newvalue),newvalue'="""" Quit $$$ERROR($$$OrefInvalid,newvalue)")
	#; If old and new value are the same do nothing
	$$$GENERATE("	If r%"_qprop_"=newvalue Quit $$$OK")
	#; For a collection copy over the items in the collection rather than copying the oref
	$$$GENERATE("	If newvalue="""" Kill i%"_qprop_",r%"_qprop_" Set i%"_qprop_"="""",r%"_qprop_"="""" Quit $$$OK")
	$$$GENERATE("	Set oref=r%"_qprop_" Kill i%"_qprop_",r%"_qprop_" Set i%"_qprop_"=$$$NULLOID,r%"_qprop_"=oref")
	$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	$$$comMemberKeyGetLO(type,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
	Set propclasstype=$$$getClassType(type)
	If propclasstype=$$$cCLASSCLASSTYPEDATATYPE {
		If collection=$$$cPROPCOLLECTIONLIST {
			$$$GENERATE("	Set key="""" For i=1:1 Set value=newvalue.GetNext(.key) Quit:key=""""  Set i%"_qprop_"(i)=value")
		} Else {
			$$$GENERATE("	Set key="""" For  Set value=newvalue.GetNext(.key) Quit:key=""""  Set i%"_qprop_"(key)=value")
		}
	} ElseIf propclasstype=$$$cCLASSCLASSTYPESTREAM,type'="%Library.GlobalBinaryStream",type'="%Library.GlobalCharacterStream",type'="%Library.FileBinaryStream",type'="%Library.FileCharacterStream" {
		$$$comMemberKeyGetLvar(initialexpression,%class,$$$cCLASSinstancevar,%property,$$$cIVARinitialexpression)
		$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)	
		If initialexpression=""||(initialexpression="""""") Set initialexpression = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
		If collection=$$$cPROPCOLLECTIONLIST {
			$$$GENERATE("	Set key="""" For i=1:1 Set value=newvalue.GetNext(.key) Quit:key=""""  Set i%"_qprop_"(i)=$$$NULLOID If value=$$$NULLOREF { Set r%"_qprop_"(i)=$$$NULLOREF } ElseIf value.%IsA("""_type_""") { Set r%"_qprop_"(i)=value.%ConstructClone(0,,"_initialexpression_") } Else { Set r%"_qprop_"(i)=##class("_type_").%New("_initialexpression_"),r%"_qprop_"(i).%Location="_initialexpression_" Do r%"_qprop_"(i).CopyFrom(value) }")
		} Else {
			$$$GENERATE("	Set key="""" For  Set value=newvalue.GetNext(.key) Quit:key=""""  Set i%"_qprop_"(key)=$$$NULLOID If value=$$$NULLOREF { Set r%"_qprop_"(key)=$$$NULLOREF } ElseIf value.%IsA("""_type_""") { Set r%"_qprop_"(key)=value.%ConstructClone(0,,"_initialexpression_") } Else { Set r%"_qprop_"(key)=##class("_type_").%New("_initialexpression_"),r%"_qprop_"(key).%Location="_initialexpression_" Do r%"_qprop_"(key).CopyFrom(value) }")
		}
	} Else {
		If collection=$$$cPROPCOLLECTIONLIST {
			$$$GENERATE("	Set key="""" For i=1:1 Set value=newvalue.GetNext(.key) Quit:key=""""  Set r%"_qprop_"(i)=value,i%"_qprop_"(i)=$$$NULLOID")
		} Else {
			$$$GENERATE("	Set key="""" For  Set value=newvalue.GetNext(.key) Quit:key=""""  Set r%"_qprop_"(key)=value,i%"_qprop_"(key)=$$$NULLOID")
		}
	}
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

/// Converts the serial state of this list object to a delimited string 
/// using "," as a delimiter.
ClassMethod CollectionToOdbc(val As %String(MAXLEN="") = "") As %String(MAXLEN="") [ CodeMode = generator, ServerOnly = 1 ]
{
	// don't generate any code if it not for a property
	if %mode '= "method" {
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		if ($$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"LogicalToOdbc")) || ($$$comMemberDefined(%class,$$$cCLASSmethod,%property_"LogicalToOdbc")) {
			$$$GENERATE("	Quit ##class("_type_").LogicalToOdbc(val,"_%parameter("CollectionOdbcDelimiter")_",$this,"_$$$QuoteName(%property_"LogicalToOdbc")_")")
		} Else {
			$$$GENERATE("	Quit ##class("_type_").LogicalToOdbc(val,"_%parameter("CollectionOdbcDelimiter")_")")
		}
	}
	quit $$$OK
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using "," as a delimiter.
ClassMethod OdbcToCollection(val As %String(MAXLEN="") = "") As %String(MAXLEN="") [ CodeMode = generator, ServerOnly = 1 ]
{
	// don't generate any code if it not for a property
	if %mode '= "method" {
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		if ($$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"OdbcToLogical")) || ($$$comMemberDefined(%class,$$$cCLASSmethod,%property_"OdbcToLogical")) {
			$$$GENERATE("	Quit ##class("_type_").OdbcToLogical(val,"_%parameter("CollectionOdbcDelimiter")_",$this,"_$$$QuoteName(%property_"OdbcToLogical")_")")
		} Else {
			$$$GENERATE("	Quit ##class("_type_").OdbcToLogical(val,"_%parameter("CollectionOdbcDelimiter")_")")
		}
	}
	quit $$$OK
}

/// Converts the serial state of this list object to a delimited string 
/// using the value of the <var>%delim</var> argument as a delimiter.
ClassMethod CollectionToDisplay(val As %String(MAXLEN="") = "", delim As %String = "") As %String(MAXLEN="") [ CodeMode = generator, ServerOnly = 1 ]
{
	// don't generate any code if it not for a property
	if %mode '= "method" {
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		if ($$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"LogicalToDisplay")) || ($$$comMemberDefined(%class,$$$cCLASSmethod,%property_"LogicalToDisplay")) {
			$$$GENERATE("	Quit ##class("_type_").LogicalToOdbc(val,$select(delim="""":"_%parameter("CollectionDisplayDelimiter")_",1:delim),$this,"_$$$QuoteName(%property_"LogicalToDisplay")_")")
		} Else {
			$$$GENERATE("	Quit ##class("_type_").LogicalToOdbc(val,$select(delim="""":"_%parameter("CollectionDisplayDelimiter")_",1:delim))")
		}
	}
	quit $$$OK
}

/// Converts the value of an incoming delimited string to a serialized state 
/// using the value of the <var>delim</var> argument as a delimiter.
ClassMethod DisplayToCollection(val As %String(MAXLEN="") = "", delim As %String = "") As %String(MAXLEN="") [ CodeMode = generator, ServerOnly = 1 ]
{
	// don't generate any code if it not for a property
	if %mode '= "method" {
		$$$comMemberKeyGetLvar(type,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		if ($$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"DisplayToLogical")) || ($$$comMemberDefined(%class,$$$cCLASSmethod,%property_"DisplayToLogical")) {
			$$$GENERATE("	Quit ##class("_type_").OdbcToLogical(val,$select(delim="""":"_%parameter("CollectionDisplayDelimiter")_",1:delim),$this,"_$$$QuoteName(%property_"DisplayToLogical")_")")
		} Else {
			$$$GENERATE("	Quit ##class("_type_").OdbcToLogical(val,$select(delim="""":"_%parameter("CollectionDisplayDelimiter")_",1:delim))")
		}
	}
	quit $$$OK
}

}
