/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Stream property class for streams that cannot be independent entities as instances of such stream
/// classes can only exist within a container object.
Class %Compiler.Type.StreamEmbedded Extends %Compiler.Type.Stream [ NoContext, System = 2 ]
{

Method NewObject(type As %RawString = "") As %ObjectHandle [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %code=0
		#; don't generate any code if it not for a property
	If %mode="method" QUIT $$$OK
	
		#; if calculated, then don't generate this method
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	
		#; set-up return type
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
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
	If ('$$$comMemberDefined(%class,$$$cCLASSmethod,%property_"Set")) && ($$$comSubMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"Set",$$$cMETHorigin) = "%Compiler.Type.StreamEmbedded") {
		$$$GENERATE("	Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newobject,i%"_qprop_"=$$$NULLOID")
		$$$GENERATE("	set r%"_qprop_".container=$this,r%"_qprop_".containerProperty="_$$$QuoteName(%property))
	} Else {
		$$$GENERATE("	Set .."_qprop_"=newobject")
	}
	#; This will only be present for file character streams
	If $get(%parameter("TRANSLATETABLE"))'="" {
		$$$GENERATE("	Set r%"_qprop_".TranslateTable="""_$get(%parameter("TRANSLATETABLE"))_"""")
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
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) QUIT $$$OK
	If $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPreadonly) QUIT $$$OK
	Set qprop=$$$QN(%property)
	$$$GENERATE("	If newvalue=$$$NULLOREF Set r%"_qprop_"=$$$NULLOREF,i%"_qprop_"=1,i%"_qprop_"=$$$NULLOID Quit $$$OK")
	$$$GENERATE("	If '$$$objExists(newvalue) Quit $$$ERROR($$$OrefInvalid,newvalue)")
	$$$GENERATE("	If newvalue=r%"_qprop_" Quit $$$OK")
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	Set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	$$$GENERATE("	If newvalue.%IsA("_$$$QuoteName(runtimetype)_") {")
	$$$GENERATE("		Set r%"_qprop_"=0,i%"_qprop_"=0,r%"_qprop_"=newvalue.%ConstructClone(0,,"_location_"),i%"_qprop_"=$$$NULLOID")
	$$$GENERATE("	} Else {")
	$$$GENERATE("		Do .."_qprop_".Rewind()")
	$$$GENERATE("		Quit .."_qprop_".CopyFrom(newvalue)")
	$$$GENERATE("	}")
	$$$GENERATE("	set r%"_qprop_".container=$this,r%"_qprop_".containerProperty="_$$$QuoteName(%property))
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

ClassMethod SVAExists(pStream As %Binary = "") As %Boolean [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	if %mode="method" quit $$$OK
		#; don't generate any code if the property is calculated
	if $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) quit $$$OK
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	#; This will only be present for file character streams
	if $get(%parameter("TRANSLATETABLE"))'="",runtimetype="%Library.FileCharacterStream" { set location="$char(0)_$listbuild("_location_",$listbuild(""TranslateTable"","""_$get(%parameter("TRANSLATETABLE"))_"""))" }
	set oid = $case(%parameter("CLASSNAME"),
					1	:	"$$$oidInsertAd1(pStream,"_location_")",
					2	:	"pStream",
						:	"$$$oidComposeAd1(pStream,"_$$$QuoteName(runtimetype)_","_location_")")
	$$$GENERATE("	i pStream '="""" { s tReturn=##class("_runtimetype_").%SVAExists("_oid_") } else { set tReturn = 0 }")
	$$$GENERATE("	q tReturn")
	quit $$$OK
}

ClassMethod GetValueArray(pStream As %Binary = "", ByRef pValueArray As %Binary) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
	set %code=0
		#; don't generate any code if it not for a property
	if %mode="method" quit $$$OK
		#; don't generate any code if the property is calculated
	if $$$comMemberKeyGet(%class,$$$cCLASSproperty,%property,$$$cPROPcalculated) quit $$$OK
	$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,%property,$$$cPROPruntimetype)
	set location = $$StreamInit^%occStorageCompiler(%class,%property,runtimetype)
	#; This will only be present for file character streams
	if $get(%parameter("TRANSLATETABLE"))'="",runtimetype="%Library.FileCharacterStream" { set location="$char(0)_$listbuild("_location_",$listbuild(""TranslateTable"","""_$get(%parameter("TRANSLATETABLE"))_"""))" }
	set oid = $case(%parameter("CLASSNAME"),
					1	:	"$$$oidInsertAd1(pStream,"_location_")",
					2	:	"pStream",
						:	"$$$oidComposeAd1(pStream,"_$$$QuoteName(runtimetype)_","_location_")")
	$$$GENERATE("	i pStream '="""" { s tReturn=##class("_runtimetype_").%GetValueArray("_oid_","_$$$QuoteName(%class)_","_$$$QuoteName(%property)_",.pValueArray) } else { set tReturn = 0 }")
	$$$GENERATE("	q tReturn")
	QUIT $$$OK
}

}
