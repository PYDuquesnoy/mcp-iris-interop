/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %BigData.ShardingManager

/// This is the property class for properties whose type class is a stream.
Class %Compiler.Type.Stream Extends %Compiler.Type.Object [ NoContext, System = 2 ]
{

/// This is the storage type of the stream - GLOBAL or OTHER.
Parameter STORAGE As STRING [ Constraint = ",GLOBAL,OTHER", Flags = ENUM ];

/// If STORAGE is "GLOBAL", this is the global node reference where the stream data is stored.
/// For file streams this is the directory where the files are stored
Parameter LOCATION;

/// XML element content "MIXED" for mixed="true" and "STRING" or "ESCAPE" for mixed="false".
/// If CONTENT="STRING" (default) XML special characters are put in a CDATA section during XML export.
/// If CONTENT="ESCAPE" XML special characters are escaped during XML export.
/// If CONTENT="ESCAPE-C14N" XML special characters are escaped during XML export using 
/// the translate table, XMLC, specified for XML Canonicalizaton.
/// The main difference is that CR is escaped as &amp;#13; 
Parameter CONTENT [ Constraint = "MIXED,STRING,ESCAPE,ESCAPE-C14N", Flags = ENUM ];

/// Controls the translate table used to escape content when CONTENT="MIXED" is specified.
Parameter ESCAPE [ Constraint = "HTML,XML", Flags = ENUM ] = "XML";

/// Encoding to be used for XML serialization of a binary stream.
Parameter ENCODING [ Constraint = "base64,hex", Flags = ENUM ] = "base64";

/// If MTOM is true, then the property that references this binary stream is available for optimization
/// when using SOAP MTOM (Message Transmission Optimization Mechanism).
/// The default for binary streams is true.
Parameter MTOM As BOOLEAN = 1;

/// returns an oref, performing swizzling if necessary it returns "" ($$$NULLOREF) if there is no oref and the id=""
/// If <var>noswizzle</var> is passed as true then this will just return the current value for the property, so if it
/// has been swizzled already then it will return the oref, if it has not been swizzled it will return "" ($$$NULLOREF).
Method GetSwizzled(noswizzle As %Boolean = 0) As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
		#; Set the returntype from the property definition
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
		#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	Set qprop=$$$QN(%property)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	$$$GENERATE("	If noswizzle { RETURN r%"_qprop_" }" )
	$$$GENERATE("	If i%"_qprop_"=$$$NULLOID Set modstate=$system.CLS.GetSModifiedBits() Set oref=.."_$$$QN(%property_"NewObject")_"("""") Do $system.CLS.SetSModifiedBits(modstate) Set r%"_qprop_"=0,r%"_qprop_"=oref Quit oref")
	Set oid = $Case(%parameter("CLASSNAME"),
					1:	"$$$oidInsertAd1(i%"_qprop_","_location_")",
					2:	"i%"_qprop,
					 :	"$$$oidComposeAd1(i%"_qprop_","""_runtimetype_""","_location_")")
	$$$GENERATE("	Set oref=##class("_runtimetype_").%Open("_oid_",,.sc) If $$$ISERR(sc) $$$THROWSWIZZLEERR Quit $$$NULLOREF")
	$$$GENERATE("	Set modstate=$system.CLS.GetModifiedBits() Set r%"_qprop_"=oref Do $system.CLS.SetModifiedBits(modstate)")
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="" {
		$$$GENERATE("	Set oref.TranslateTable="""_$get(%parameter("TRANSLATETABLE"))_"""")
	}	
	$$$GENERATE("	Quit oref")
	QUIT $$$OK
}

/// This method obtains the state/id of the referenced object if swizzling has not occurred, it simply returns the stored
/// state else it references the specified object force = an optional parameter, if its value is 1 then if the
/// referenced object is an ID object it must return its ID, which may force it to file itself. No code for this method if
/// the property is a datatype.
Method GetObject(force As %Integer = 0) As %ObjectIdentity [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	$$$comMemberKeyGetLO(transient,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtransient)
	If transient {
		#; Transient streams just return $$$NULLOID
		$$$GENERATE("	Quit """"")
		QUIT $$$OK
	}
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype),qprop=$$$QN(%property)
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="",runtimetype="%Library.FileCharacterStream" {
		Set location="$char(0)_$listbuild("_location_",$listbuild(""TranslateTable"","_$get(%parameter("TRANSLATETABLE"))_"))"
	}	
	$$$comMemberKeyGetLO(collection,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcollection)
	If collection="" { Set hasclassname=%parameter("CLASSNAME") } Else { Set hasclassname=0 }
	Set oid = $case(hasclassname,
			1	:	"$$$oidInsertAd1(i%"_qprop_","_location_")",
			2	:	"i%"_qprop,
				:	"$$$oidComposeAd1(i%"_qprop_","_$$$QuoteName(runtimetype)_","_location_")")
	$$$GENERATE("	Quit:r%"_qprop_"=$$$NULLOREF "_oid_" Quit:$$$ISOK(.."_qprop_".%GetSwizzleObject(force,.oid)) oid Quit """"")
	QUIT $$$OK
}

Method NewObject(type As %RawString = "") As %ObjectHandle [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	
	#; if calculated, then don't generate this method
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	
		#; set-up return type
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	Set qprop=$$$QN(%property)
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,runtimetype)
	$$$comClassKeyGetLvar(runtimeabstract,runtimetype,$$$cCLASSabstract)
	$$$GENERATE("	Set $ZTrap = ""CatchError""")
	$$$GENERATE("	Set sc=$$$OK")
	$$$GENERATE("	If type="""" {")
	If 'runtimeabstract {
		$$$GENERATE("		Set type = "_$$$QuoteName(runtimetype))
	} Else {
		$$$GENERATE("		Set sc=$$$ERROR($$$PropertyTypeClassIsAbstract,"_$$$QuoteName(%class)_","_$$$QuoteName(%property)_","_$$$QuoteName(runtimetype)_") Quit $$$NULLOREF")
	}
	$$$GENERATE("	} ElseIf '($classmethod(type,""%IsA"","_$$$QuoteName(runtimetype)_")) {")
	$$$GENERATE("		Set sc=$$$ERROR($$$PropertyValueInvalidType,"_$$$QuoteName(%class)_","_$$$QuoteName(%property)_") Quit $$$NULLOREF")
	$$$GENERATE("	}")
	If location="""""",(runtimetype="%Library.FileCharacterStream")||(runtimetype="%Library.FileBinaryStream")||(runtimetype="%Stream.FileBinary")||(runtimetype="%Stream.FileCharacter") {
		Set location="$char(0)"
	}
	$$$GENERATE("	Set newobject=$classmethod(type,""%New"","_location_") If newobject=$$$NULLOREF Quit $$$NULLOREF")
	If ('$$$comMemberDefined(%class,$$$cCLASSmethod,%property_"Set")) && ($case($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"Set",$$$cMETHorigin),"%Compiler.Type.Stream":1,"%Compiler.Type.StreamLegacy":1,:0)) {
		$$$GENERATE("	Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newobject,i%"_qprop_"=$$$NULLOID")
	} Else {
		$$$GENERATE("	Set .."_qprop_"=newobject")
	}
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="" {
		$$$GENERATE("	Set newobject.TranslateTable="""_$get(%parameter("TRANSLATETABLE"))_"""")
	}
	$$$GENERATE("	Quit newobject")
	$$$GENERATE("CatchError	Set $ZTrap=""""")
	$$$GENERATE("	If $$$ISOK(sc) Set sc = $$$ERROR($$$ObjectScriptError,$ze)")
	$$$GENERATE("	Quit $$$NULLOREF")
	QUIT $$$OK
}

Method Set(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
	#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	#; don't generate any code if the property is calculated or readonly
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	$$$comMemberKeyGetLO(readonly,origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly)
	If readonly QUIT $$$OK
	Set qprop=$$$QN(%property)
	$$$GENERATE("	If newvalue=$$$NULLOREF Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=$$$NULLOREF,i%"_qprop_"=$$$NULLOID Quit $$$OK")
	$$$GENERATE("	If '$$$objExists(newvalue) Quit $$$ERROR($$$OrefInvalid,newvalue)")
	$$$GENERATE("	If newvalue=r%"_qprop_" Quit $$$OK")
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	$$$GENERATE("	If newvalue.%IsA("_$$$QuoteName(runtimetype)_") {")
	$$$GENERATE("		Set r%"_qprop_"=newvalue.%ConstructClone(0,,"_location_"),i%"_qprop_"=1,i%"_qprop_"=$$$NULLOID")
	$$$GENERATE("	} Else {")
	$$$GENERATE("		Do .."_qprop_".Clear()")
	$$$GENERATE("		Quit .."_qprop_".CopyFrom(newvalue)")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// This method is used when loading an object for a sharded class and getting the stream from the shard-local class
/// We need to perform a type of clone from the stream selected from SQL for the shard-local class and be able to use it in the sharded class
Method SetFromShardStream(newvalue As %RawString) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	RETURN:%mode="method" $$$OK
		#; don't generate any code if the property is from a class that is not sharded=1, calculated, or readonly
	$$$comShardedGetLvar(sharded,%class) // JMM1160=
	RETURN:sharded'=1 $$$OK
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	RETURN:calculated $$$OK
	$$$comMemberKeyGetLO(readonly,origin,%class,$$$cCLASSproperty,%property,$$$cPROPreadonly)
	RETURN:readonly $$$OK
	set qprop=$$$QN(%property)
	$$$GENERATE("	if newvalue=$$$NULLOREF { set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=$$$NULLOREF,i%"_qprop_"=$$$NULLOID RETURN $$$OK }")
	$$$GENERATE("	RETURN:'$$$objExists(newvalue) $$$ERROR($$$OrefInvalid,newvalue)")
	$$$GENERATE("	RETURN:newvalue=r%"_qprop_" $$$OK")
	$$$GENERATE("	set r%"_qprop_"=newvalue.%ConstructClone(0,,newvalue.%Location),i%"_qprop_"=1,i%"_qprop_"=$$$NULLOID")
	$$$GENERATE("	RETURN $$$OK")
	QUIT $$$OK
}

ClassMethod Delete(streamvalue) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	$$$comMemberKeyGetLO(tDataType,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="",runtimetype="%Library.FileCharacterStream" {
		Set location="$char(0)_$listbuild("_location_",$listbuild(""TranslateTable"","_$get(%parameter("TRANSLATETABLE"))_"))"
	}	
	$$$GENERATE("	Set $ZTrap = ""CatchError""")
	Set oid = $case(%parameter("CLASSNAME"),
			1	:	"$$$oidInsertAd1(streamvalue,"_location_")",
			2	:	"streamvalue",
				:	"$$$oidComposeAd1(streamvalue,"_$$$QuoteName(tDataType)_","_location_")")
	$$$GENERATE("	Quit $select(streamvalue="""":$$$ERROR($$$NullOid,$classname()),1:##class("_tDataType_").%Delete("_oid_"))")
	$$$GENERATE("CatchError	Set $ZTrap=""""")
	$$$GENERATE("	Quit $$$ERROR($$$ObjectScriptError,$zerror)")
	QUIT $$$OK
}

ClassMethod Open(streamvalue) As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	$$$comMemberKeyGetLO(tDataType,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
		#; Set the returntype from the property definition
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,tDataType)
		#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	If calculated QUIT $$$OK
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	$$$GENERATE("	If $get(streamvalue)="""" {")
	$$$GENERATE("		Set object=##class("_tDataType_").%New("_location_")")
	Set oid = $Case(%parameter("CLASSNAME"),
					1	:	"$$$oidInsertAd1(streamvalue,"_location_")",
					2	:	"streamvalue",
						:	"$$$oidComposeAd1(streamvalue,"_$$$QuoteName(tDataType)_","_location_")")
	$$$GENERATE("	} elseif $isobject(streamvalue)=1 {")
	$$$GENERATE("		set object = streamvalue")
	$$$GENERATE("	} else {")
	$$$GENERATE("		Set object=##class("_tDataType_").%Open("_oid_")")
	$$$GENERATE("		If $isobject(object)=1,object.%IsNull()=1 Quit """"")
	$$$GENERATE("	}")
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="" {
		$$$GENERATE("	If $isobject(object)=1 Set object.TranslateTable="""_$get(%parameter("TRANSLATETABLE"))_"""")
	}
	$$$GENERATE("	Quit object")
	QUIT $$$OK
}

/// &lt;Prop&gt;Oid takes the stored value of a stream reference and returns an externalized stream oid that may be passed to ##class(%Stream.Object).Open().
ClassMethod Oid(streamvalue, external = "") As %ObjectIdentity [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	RETURN:%mode="method" $$$OK
	$$$comMemberKeyGetLO(tDataType,origin,%class,$$$cCLASSproperty,%property,$$$cPROPtype)
		#; Set the returntype from the property definition
	$$$modifySubMemberKeySet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,%method,$$$cMETHreturntype,tDataType)
		#; don't generate any code if the property is calculated
	$$$comMemberKeyGetLO(calculated,origin,%class,$$$cCLASSproperty,%property,$$$cPROPcalculated)
	RETURN:calculated $$$OK
	$$$comMemberKeyGetLO(runtimetype,origin,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	set location=$$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
		#; This will only be present for file character streams
	if $get(%parameter("TRANSLATETABLE"))'="",tDataType="%Library.FileCharacterStream" {
		set location="$char(0)_$listbuild("_location_",$listbuild(""TranslateTable"","""_$get(%parameter("TRANSLATETABLE"))_"""))"
	}	
	set %codemode = $$$cMETHCODEMODEEXPRESSION
	$$$comShardedGetLvar(sharded,%class) // JMM1160=
	if sharded=2,tDataType["%Stream.Global" {
		set oid = $Case(%parameter("CLASSNAME"),
						1	:	"$$$oidInsertAd1Ad2(streamvalue,"_location_",$s(external="""":$g("_$$$SSShardLocalGlobalQuoted_"),1:$g(^|""_external_""|"_$e($$$SSShardLocalGlobalQuoted,2,*)_")))",
						2	:	"$$$oidInsertAd2(streamvalue,$s(external="""":$g("_$$$SSShardLocalGlobalQuoted_"),1:$g(^|external|"_$e($$$SSShardLocalGlobalQuoted,2,*)_")))",
							:	"$$$oidComposeAd1Ad2(streamvalue,"_$$$QuoteName(tDataType)_","_location_",$s(external="""":$g("_$$$SSShardLocalGlobalQuoted_"),1:$g(^|external|"_$e($$$SSShardLocalGlobalQuoted,2,*)_")))")
	} else {
		set oid = $Case(%parameter("CLASSNAME"),
						1	:	"$$$oidInsertAd1(streamvalue,"_location_")",
						2	:	"streamvalue",
							:	"$$$oidComposeAd1(streamvalue,"_$$$QuoteName(tDataType)_","_location_")")
	}
	set %code="$s($isobject(streamvalue):streamvalue.%Oid(),1:"_oid_")"
	RETURN $$$OK
}

}
