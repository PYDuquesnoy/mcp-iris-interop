/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Serial object interface
Class %Storage.Serial Extends %SerialState [ Abstract, System = 2 ]
{

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.Serial";

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = generator, Private, ProcedureBlock = 0 ]
{
 s %code=0
 QUIT:'($$$classIsSerial(%class)) $$$OK
 m %code=$$$tEXTcode("GetSerial")
 QUIT $$$OK
}

Method %IsNull() As %Boolean [ CodeMode = generator, ProcedureBlock = 0 ]
{
 s %code=0
 QUIT:'($$$classIsSerial(%class)) $$$OK
 m %code=$$$tEXTcode("IsNull")
 QUIT $$$OK
}

/// Return true if pOID is a null object and false if the object is not null
ClassMethod %ObjectIsNull(pOID As %ObjectIdentity) As %Boolean
{
	If $isobject(pOID)=1 Set pOID=pOID."%%OID"
	if pOID = $$$NULLOID quit 1
	set class = $$$oidClassName(pOID)
	if class '= "" {
		set class=$$$NormalizeClassname(class) if $classname()'=class quit $classmethod(class,"%ObjectIsNull",pOID)
	}
	quit $$$oidPrimary(pOID)=""
}

/// 	Set Serialized State.
Method %SetSerial(val As %String) As %Status [ CodeMode = generator, Private ]
{
 s %code=0
 QUIT:'($$$classIsSerial(%class)) $$$OK
 m %code=$$$tEXTcode("SetSerial")
 QUIT $$$OK
}

/// 	LogicalToOdbc()
/// 		Construct a string delimited by ODBCDELIMITER from an object's serialized state.
ClassMethod LogicalToOdbc(val As %String = "") As %String [ CodeMode = generator ]
{
	set %code=0
	quit:'($$$classIsSerial(%class)) $$$OK
	if $data($$$CLASSproperty($$$sMGINFO,%class))=0 quit $$$OK
	$$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy) if sdef="" set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="val" quit $$$OK
	set state=$get($$$SDEFstate($$$sMGINFO,%class,sdef))  if state="" set %codemode=$$$cMETHCODEMODEEXPRESSION,%code="val" quit $$$OK
	set odbcdelim = %parameter("ODBCDELIMITER")
	set serialdelimiter = %parameter("SERIALDELIMITER")
		#; Quote the delimiter. If odbcdelimiter was not specified, default to ","
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"ODBCDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION { set odbcdelim = $select(odbcdelim'="":""""_odbcdelim_"""",1:""",""") }
	if (serialdelimiter '= "") && ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION) { set serialdelimiter = """"_serialdelimiter_"""" }
		#; now count the instance variables in the serialized object
		#; and build the result
	set odbc=1,odbc(1)=""
	$$$FOREACHdatavalue($$$sMGINFO,%class,sdef,state,position)  do
	. if serialdelimiter="" set stoken="_"_odbcdelim_"_$listget(val,"_position_")"
	. else  set stoken="_"_odbcdelim_"_$piece(val,"_serialdelimiter_","_position_")"
	. if ($length(odbc(odbc))+$length(stoken))>512 set odbc(odbc)=$extract(odbc(odbc),$length(odbcdelim)+3,*) set odbc=odbc+1,odbc(odbc)=""
	. set odbc(odbc)=odbc(odbc)_stoken
	if odbc(odbc)'="" set odbc(odbc)=$extract(odbc(odbc),$length(odbcdelim)+3,*)
	if odbc=1 set %code=odbc(1),%codemode=$$$cMETHCODEMODEEXPRESSION quit $$$OK
	$$$GENERATE("	Set odbc="_odbc(1))
	for line=2:1:odbc do
	. $$$GENERATE("	Set odbc=odbc_"_odbc(line))
	$$$GENERATE("	Quit odbc")
	quit $$$OK
}

ClassMethod OdbcToLogical(val As %String = "") As %String [ CodeMode = generator ]
{
 s %code=0
 QUIT:'($$$classIsSerial(%class)) $$$OK
 i $d($$$CLASSproperty($$$sMGINFO,%class))=0 QUIT $$$OK
 $$$comClassKeyGetLvar(sdef,%class,$$$cCLASSstoragestrategy) i sdef="" s %codemode=$$$cMETHCODEMODEEXPRESSION,%code="val" QUIT $$$OK
 s state=$g($$$SDEFstate($$$sMGINFO,%class,sdef))  i state="" s %codemode=$$$cMETHCODEMODEEXPRESSION,%code="val" QUIT $$$OK
	set odbcdelim = %parameter("ODBCDELIMITER")
	set serialdelimiter = %parameter("SERIALDELIMITER")
 #; Quote the delimiter. If odbcdelimiter was not specified, default to ","
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"ODBCDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION { set odbcdelim = $select(odbcdelim'="":""""_odbcdelim_"""",1:""",""") }
	if (serialdelimiter '= "") && ($$$comMemberKeyGet(%class,$$$cCLASSparameter,"SERIALDELIMITER",$$$cPARAMtype) '= $$$cPARAMTYPECOSEXPRESSION) { set serialdelimiter = """"_serialdelimiter_"""" }
 #; now count the instance variables in the serialized object
 #; and build the result

 s leader=$s(serialdelimiter="":"$lb(",1:"")
 s logical=1,logical(logical)=leader
 $$$FOREACHdatavalue($$$sMGINFO,%class,sdef,state,position)  DO
 . i serialdelimiter="" s stoken="$piece(val,"_odbcdelim_","_position_"),"
 . e  s stoken="$piece(val,"_odbcdelim_","_position_")_"_serialdelimiter_"_"
 . i ($l(logical(logical))+$l(stoken))>512 s $e(logical(logical),$l(logical(logical)))=$s(serialdelimiter="":")",1:"") s logical=logical+1,logical(logical)=leader
 . s logical(logical)=logical(logical)_stoken
 i logical(logical)'="" s $e(logical(logical),$l(logical(logical)))=$s(serialdelimiter="":")",1:"")
 i logical=1 s %code=logical(1),%codemode=$$$cMETHCODEMODEEXPRESSION Quit $$$OK
 $$$GENERATE("	Set logical="_logical(1))
 f line=2:1:logical d
 . $$$GENERATE("	Set logical=logical_"_logical(line))
 $$$GENERATE("	Quit logical")
 QUIT $$$OK
}

}
