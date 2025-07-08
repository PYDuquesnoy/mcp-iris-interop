/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// <b>This class has been superseded.</b> It will remain for compatibility with existing code and samples. 
/// We recommend using <class>%SQL.CustomResultSet</class>.
/// </p>
Class %ResultSet.Custom Extends %Library.IResultSet [ Abstract, System = 4 ]
{

Method %OnNew(ByRef returnError As %SYSTEM.Error, pRuntimeMode As %Integer = {$zu(115,5)}) As %Library.Status [ CodeMode = generator, Final, GenerateAfter = %OpenCursor ]
{
	set %code = 0
	if '$$$comMemberKeyGet(%class,$$$cCLASSmethod,"%OpenCursor",$$$cMETHrunnable) { set %codemode = $$$cMETHCODEMODEEXPRESSION, %code = "$$$ERROR($$$MethodNotImplemented,"""_%class_":%OpenCursor"")" quit $$$OK }
	set callString = ""
	$$$comMemberKeyGetLvar(ocformal,%class,$$$cCLASSmethod,"%OpenCursor",$$$cMETHformalspecparsed)
	If $ListLength(ocformal) {
		For argptr = 1:1:$ListLength(ocformal) {
			Set formalarg = $List(ocformal,argptr), argname = $List(formalarg,1), type = $List(formalarg,2), byref = $Case($List(formalarg,3), "":0, "&":1, "*":2, ".":1, :0)
			Set callString = callString_","_$Select('byref:"",1:".")_argname
		}
		set callString = $Extract(callString,2,$Length(callString))
	}
		#; Reset the formal list to the query declaration:
	$$$comMemberKeyGetLvar(formal,%class,$$$cCLASSmethod,%method,$$$cMETHformalspecparsed)
	set exformal = formal_ocformal
	$$$comMemberKeySet(%class,$$$cCLASSmethod,%method,$$$cMETHformalspecparsed,exformal)
	Set sc=$$rebuildFormal^%occName(exformal,.formalspec) If $$$ISERR(sc) Quit sc
	$$$comMemberKeySet(%class,$$$cCLASSmethod,%method,$$$cMETHformalspec,formalspec)
	$$$comMemberKeySet(%class,$$$cCLASSmethod,%method,$$$cMETHdefaultargs,$$ArgumentDefaultValues^%occName(exformal))
	$$$comMemberKeySet(%class,$$$cCLASSmethod,%method,$$$cMETHuseractualtype,$$$normalize($$QueryMethodUserActualtype^%occName(exformal,%class)))
		#; count the number of RESULTCOL properties
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,""), property = "", tObjectsMD = ""
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If origin="%Library.IResultSet" Set private=1
		If 'private set property = property + 1
		If 'private {
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			if '$$$classIsDataType(runtimetype) {
				$$$comClassKeyGetLvar(tSchema,runtimetype,$$$cCLASSsqlschemaname)
				$$$comClassKeyGetLvar(tTable,runtimetype,$$$cCLASSsqltablename)
				if (tSchema '= "") && (tTable '= "") { set tCall = $Get(^oddSQL(tSchema,tTable,"QL")) } else { set tCall = "" }
				set tObjectsMD = tObjectsMD _ ",$lb(""" _ prop _ """,""" _ runtimetype _ """,""" _ tCall _ """)"
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	if tObjectsMD '= "" { set tObjectsMD = ", i%%Objects = $lb("_ $Extract(tObjectsMD,2,*) _ ")" }
	$$$GENERATE("	set ..%RuntimeMode = pRuntimeMode" _ tObjectsMD _ ", status = ..%OpenCursor("_callString_")")
	$$$GENERATE("	if $$$ISOK(status) { Set ..%NextColumn="_(property + 1) _ " } Else { Set returnError=##class(%SYSTEM.Error).%New(status,"""","""") }")
	$$$GENERATE("	Quit status")
	quit $$$OK
}

/// %Get(colname)
/// 	Get the value of the property whose column name is colname.
Method %Get(colname As %String = "") As %Library.String [ CodeMode = generator, ProcedureBlock = 1 ]
{
	Set %code=0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If origin="%Library.IResultSet" Set private=1
		If 'private {
			$$$comMemberKeyGetLvar(sqlname,%class,$$$cCLASSproperty,prop,$$$cPROPsqlfieldname)
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			if $$$classIsDataType(runtimetype) { Set property(sqlname) = prop, property(sqlname,1) = 1 }
			else { Set property(sqlname) = prop, property(sqlname,1) = 0 }
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
		#; construct the column value return lines
	If $Data(property) {
		$$$GENERATE("	try {")
		Set case = 1, case(1) = "$Case($$$ucase(colname)",column = $Order(property(""))
		While column '= "" {
			If $Length(case(case)) > 500 { Set case = case + 1, case(case) = "		,"""_$$$ucase(column)_""":.."_property(column) _ $Select(property(column,1):"",1:"GetObjectId()") }
			Else { set case(case) = case(case) _ ","""_$$$ucase(column)_""":.."_property(column) _ $Select(property(column,1):"",1:"GetObjectId()") }
			Set column = $Order(property(column))
		}
		if case = 1 { $$$GENERATE("		set returnVal = "_case(1) _ ")") }
		else {
			$$$GENERATE("		set returnVal = "_case(1))
			for ptr = 2:1:case-1 { $$$GENERATE(case(ptr)) }
			$$$GENERATE(case(case)_")")
		}
		$$$GENERATE("	}")
		$$$GENERATE("	catch {")
		$$$GENERATE("		$$$ThrowPropertyDoesNotExistError(colname)")
		$$$GENERATE("	}")
		$$$GENERATE("	quit returnVal")
	}
	QUIT $$$OK
}

/// %GetData(<column number>)
/// 
/// 		Returns the value of the column referenced by colnbr. Object values are not swizzled automatically.
Method %GetData(colnbr As %Integer = 0) As %Library.String [ CodeMode = generator ]
{
	Set %code=0, property = 0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If origin="%Library.IResultSet" Set private=1
		If 'private {
			$$$comMemberKeyGetLvar(sqlname,%class,$$$cCLASSproperty,prop,$$$cPROPsqlfieldname)
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			$$$comMemberKeyGetLvar(intSeq,%class,$$$cCLASSproperty,prop,$$$cXXXXsequencenumber)
			set property = property + 1
			if $$$classIsDataType(runtimetype) { Set property(intSeq) = prop, property(intSeq,1) = 1 }
			else { Set property(intSeq) = prop, property(intSeq,1) = 0 }
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"COLUMNCOUNT",$$$cPARAMdefault,property)
		#; construct the column value return lines
	If property {
		$$$GENERATE("	try {")
		set intCol = 0, case = 1, case(1) = "$case(colnbr", ptr = $Order(property(""))
		while ptr '= "" {
			set intCol = intCol + 1
			if $Length(case(case)) > 500 { set case = case + 1, case(case) = "	," _ intCol _ ":.."_property(ptr) _ $Select(property(ptr,1):"",1:"GetObjectId()") }
			else { set case(case) = case(case) _ "," _ intCol _":.."_property(ptr) _ $Select(property(ptr,1):"",1:"GetObjectId()") }
			Set ptr = $Order(property(ptr))
		}
		if case = 1 { $$$GENERATE("		set returnVal = "_case(1) _ ")") }
		else {
			$$$GENERATE("		set returnVal = "_case(1))
			for ptr = 2:1:case-1 { $$$GENERATE(case(ptr)) }
			$$$GENERATE(case(case)_")")
		}
		$$$GENERATE("	}")
		$$$GENERATE("	catch {")
		$$$GENERATE("		$$$ThrowPropertyDoesNotExistError(""Column #: ""_colnbr)")
		$$$GENERATE("	}")
		$$$GENERATE("	quit returnVal")
	}
	QUIT $$$OK
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer [ CodeMode = generator, ProcedureBlock = 0 ]
{
	// GenerateSendODBC(class,qinfo,columns,rsstateprops) public {
	new intCol,intSeq,prop,property,ptr,private,origin,runtimetype
	Set %code=0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set property = 0
		#; construct an array of query select properties.
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin="%Library.IResultSet") || (origin="%SQL.StatementResult") { Set private=1 }
		If 'private {
			$$$comMemberKeyGetLvar(intSeq,%class,$$$cCLASSproperty,prop,$$$cXXXXsequencenumber)
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			Set property = property + 1
			if $$$classIsDataType(runtimetype) { Set property(intSeq) = prop, property(intSeq,1) = 1 }
			else { Set property(intSeq) = prop, property(intSeq,1) = 0 }
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	$$$GENERATE("	New tag Set tag = ""%t""_i%%NextColumn Goto @tag")
	Set ptr = $Order(property("")), intCol = 0
	While ptr '="" {
		set intCol = intCol + 1
		if property(ptr,1) { $$$GENERATE("%t"_intCol_"	If $zobjexport(i%"_property(ptr)_",7) { Set i%%NextColumn = "_intCol_" QUIT 0 }") }
		else { $$$GENERATE("%t"_intCol_"	If $zobjexport(.." _ property(ptr)_"GetObjectId(),7) { Set i%%NextColumn = "_intCol_" QUIT 0 }") }
		Set ptr = $Order(property(ptr))
	}
	$$$GENERATE("%t"_(intCol+1)_"	Set i%%NextColumn = 1")
	$$$GENERATE("	If (..%Next(.sc)) Goto %t1")
	$$$GENERATE("	Quit 100")
	Quit $$$OK
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendObjects() As %Library.Integer [ CodeMode = generator, Internal ]
{
	Set %code=0, objects = 0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
		#; construct an array of query select properties that are swizzlable objects
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If origin="%Library.IResultSet" Set private=1
		If 'private {
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			if '$$$classIsDataType(runtimetype) {
				$$$comClassKeyGetLvar(tSchema,runtimetype,$$$cCLASSsqlschemaname)
				$$$comClassKeyGetLvar(tTable,runtimetype,$$$cCLASSsqltablename)
				if (tSchema '= "") && (tTable '= "") { set tCall = $Get(^oddSQL(tSchema,tTable,"QL")) } else { set tCall = "" }
				set objects($i(objects)) = $ListBuild(prop,runtimetype,tCall)
			}
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}

	if objects {
		Set code=0
		$$$GENERATE("	new %rowid,%nolock,%qrc")
		$$$GENERATE("	set %qrc = 0, %nolock = 0")
		$$$GENERATE("	while (..%Next()) && ('%qrc) {")
		for tPtr = 1:1:objects {
			set t3=$List(objects(tPtr),3)
			$$$GENERATE("		set %rowid = i%" _ $List(objects(tPtr),1))
			if t3'="" $$$GENERATE("		if %rowid '= """" { do $classmethod(""" _ $List(t3) _ """,""" _ $List(t3,2) _ """,%rowid) if %qrc goto exit }")
		}
		$$$GENERATE("	}")
		$$$GENERATE("exit	quit %qrc")
	}
	else { $$$GENERATE("	quit 0") }
	Quit $$$OK
}

Method %ExecuteParametersGet() [ CodeMode = generator, GenerateAfter = %Execute ]
{
		#; %ExecuteParameters is a comma delimited list of actual arguments. For a custom result set this list
		#; is just %qpar1,%qpar2,...%qparn
	set calllist = ""
	$$$comMemberKeyGetLvar(formalspec,%class,$$$cCLASSmethod,"%Execute",$$$cMETHformalspecparsed)
	If $ListLength(formalspec) {
		For argptr = 1:1:$ListLength(formalspec) {
			Set formalarg = $List(formalspec,argptr), argname = $List(formalarg,1), type = $List(formalarg,2), byref = $Case($List(formalarg,3), "":0, "&":1, "*":2, ".":1, :0)
			Set calllist = calllist_","_$Select('byref:"",1:".")_"%qpar"_(argptr)
		}
		set %codemode = $$$cMETHCODEMODEEXPRESSION, %code = """"_$Extract(calllist,2,$Length(calllist))_""""
	}
	else { set %codemode = $$$cMETHCODEMODEEXPRESSION, %code = """""" }
	quit $$$OK
}

/// Override the %Metadata property's Get() method.
Method %MetadataGet()
{
	quit ..%GetSerializedMetaData()
}

/// Get the serialized %Metadata property value. Used by both the instance method %MetadataGet and the %PrepareMetaData class method.
ClassMethod %GetSerializedMetaData() [ CodeMode = generator ]
{
	Set %code=0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set property = 0
		#; We might consider some other mechanism for reporting the schema and table associated with the property. Hand-crafted queries
		#; might have a difficult time with this.
	$$$comClassKeyGetLvar(colSchema,%class,$$$cCLASSsqlschemaname) $$$comClassKeyGetLvar(colTablename,%class,$$$cCLASSsqltablename)
	set colSchema = $$quoter^%occClass(colSchema), colTablename = $$quoter^%occClass(colTablename)
		#; construct an array of query select properties.
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If origin="%Library.IResultSet" Set private=1
		If 'private {
			$$$comMemberKeyGetLvar(intSeq,%class,$$$cCLASSproperty,prop,$$$cXXXXsequencenumber)
			Set property(intSeq) = prop, property = property + 1
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
		#; construct metadata by regenerating the $list from literals. Cached queries store the metadata
		#; in the query cache but result sets don't have any persistent storage. We could change that but we will
		#; just use this mechanism for now.
		#; 
		#; Metadata versions are currently as follows:
		#;     DPV2695 (07/11/2006) - %protocol cleanup - remove all %protocol < 39 code
		#; 		Version 1: %protocol <15 <colmetadata> = $lb(colName,colODBCType,precision,scale,nullable,colName,colTablename)
		#; 		Version 2: %protocol >14, <41 <colmetadata> = $lb(colName,colODBCType,precision,scale,nullable,colName,colTablename,colSchema,"")
		#; 		Version 3: %protocol >40 <colmetadata> = $lb(colName,colODBCType,precision,scale,nullable,colName,colTablename,colSchema,"",bstr)	Set ptr = $Order(property(""))
	Set metadata(1) = "$lb("_property_",", metadata(2) = metadata(1), metadata(3) = metadata(1)
	set ptr = $Order(property(""))
	While ptr '= "" {
		$$$comMemberKeyGetLvar(colCacheType,%class,$$$cCLASSproperty,property(ptr),$$$cPROPtype)
		$$$comMemberKeyGetLvar(colName,%class,$$$cCLASSproperty,property(ptr),$$$cPROPsqlfieldname)
		$$$comMemberKeyGetLvar(colRequired,%class,$$$cCLASSproperty,property(ptr),$$$cPROPrequired)
		Merge colParms = $$$comMemberKeyRaw(%class,$$$cCLASSproperty,property(ptr),$$$cPROPparameter)
		set colName = $$quoter^%occClass(colName)
		Do GetODBCColInfo^%ourODBC(colCacheType,.colParms,.colODBCTypeName,.colODBCType,.maxLen,.precision,.scale)
			#; Extract the column information
		Set nullable = 'colRequired
		Set radix=$Select(";-6;-5;2;3;4;5;6;7;8;"[(";"_colODBCType_";"):10,1:"")
		#;  Set metadata(1) = metadata(1) _ colName_","_colODBCType_","_precision_","_scale_","_nullable_","_colName_","_colTablename_","
		Set metadata(2) = metadata(2) _ colName_","_colODBCType_","_precision_","_scale_","_nullable_","_colName_","_colTablename_"," _ colSchema _","""","
			#; bstr = nullable|autoincrement|casesensitive|currency|readonly|rowversion|unique|aliased|expression|hidden|identity|keycolumn
		set bstr = "$Char(0,0,0,0,0,0,0,0,0,0,0,0)"
		Set metadata(3) = metadata(3) _ colName_","_colODBCType_","_precision_","_scale_","_nullable_","_colName_","_colTablename_"," _ colSchema _",""""," _ bstr_","
		Set ptr = $Order(property(ptr))
	}
	#; set $Extract(metadata(1),$Length(metadata(1))) = ")"
	set $Extract(metadata(2),$Length(metadata(2))) = ")"
	set $Extract(metadata(3),$Length(metadata(3))) = ")"
	$$$GENERATE("	if $Get(%protocol,41) > 40 { Set metadata = "_metadata(3) _ "}")
	$$$GENERATE("	else { Set metadata = "_metadata(2)_"}")
	$$$GENERATE("	Quit metadata")
	Quit $$$OK
}

/// User written code to open the cursor here, you may also add arguments to the method
Method %OpenCursor() As %Library.Status [ Private ]
{
	quit $$$OK
}

/// %Prepare()
/// 
/// This method is different for each type of result set class. This method has two tasks. First, instantiate the correct
/// concrete result set class. Think of the first parameter, queryId, as being an "index key value" that is used to lookup
/// the correct query implementation. For non-cached (static) queries this is simply the name of the class that implements
/// the query, i.e. the %IResultSet interface. The second task is to prepare the resulting object for data
/// retrieval by the caller which is done in %OnNew. The assumption is that if the query requires any parameters
/// then the actual arguments are all literal or public variables.
/// 
/// queryId		the concrete subclass of %IResultSet that implements the desired query. For dynamic cached results this value
/// 			is generally the query text that can be parsed, a hashed value computed and the cached result implementation class
/// 			looked up in the query cache index.
/// %returnError	If an error occurs this is returned by reference and is a %SYSTEM.Error object
///                 with properties set to describe information about the error
/// %importPackages	This is a comma delimited list of packages to import. This is only relevant if the result set implementation is
/// 				generated and the query source might include unqualified names. The import packages list is used to resolve package/schema names for
/// 				unqualified names.
ClassMethod %Prepare(queryId As %String(MAXLEN=""), ByRef %returnError As %SYSTEM.Error, %importPackages As %RawString = "", %args...) As %Library.IResultSet [ CodeMode = generator, ServerOnly = 1 ]
{
	if $$$comClassKeyGet(%class,$$$cCLASSabstract) {
		$$$GENERATE("	New %resultSet Set %returnError=$$$NULLOREF")
		$$$GENERATE("	Set execute=""Set %resultSet=##class(""_queryId_"").%New(.%returnError,,""")
		$$$GENERATE("	For i=1:1:$get(%args) { Set execute=execute_$Select($Data(%args(i)):""%args(""_i_""),"",1:"""") }")
		$$$GENERATE("	Set execute=$extract(execute,1,$length(execute)-1)_"")""")
		$$$GENERATE("	Xecute execute")
		$$$GENERATE("	Quit %resultSet")
	}
	else {
		$$$GENERATE("	New %resultSet Set %returnError=$$$NULLOREF")
		$$$GENERATE("	Set execute=""Set %resultSet=##class("_%class_").%New(.%returnError,,""")
		$$$GENERATE("	For i=1:1:$get(%args) { Set execute=execute_$Select($Data(%args(i)):""%args(""_i_""),"",1:"""") }")
		$$$GENERATE("	Set execute=$extract(execute,1,$length(execute)-1)_"")""")
		$$$GENERATE("	Xecute execute")
		$$$GENERATE("	Quit %resultSet")
	}
	quit $$$OK
}

/// %PrepareMetaData is similar to %Prepare except that no result set is instantiated. This
/// method returns a %ResultSet.MetaData object. Be aware that the implementation of this
/// method might cause the result set to be instantiated but that is up to the result set
/// class itself and no result set is actually returned by this method - only metadata.
/// 
/// class			This is the custom result set class
/// 
/// returnError		If an error occurs this is returned by reference and is a %SYSTEM.Error object
///                 with properties set to describe information about the error. %returnError.Status contains the %Status value.
/// importPackages	This is a comma delimited list of packages to import. This is only relevant if the result set implementation is
/// 				generated and the query source might include unqualified names. The import packages list is used to resolve package/schema names for
/// 				unqualified names.
ClassMethod %PrepareMetaData(class As %String(MAXLEN=""), ByRef returnError As %SYSTEM.Error = "", importPackages As %RawString = "") As %ResultSet.MetaData [ CodeMode = generator, GenerateAfter = %MetadataGet ]
{
	if %class = "%ResultSet.Custom" { $$$GENERATE("	quit $classmethod(class,""%PrepareMetaData"","""",.returnError,.importPackages)") }
	else {
		$$$GENERATE("	quit ##class(%ResultSet.MetaData).%New(..%GetSerializedMetaData())")
	}
	quit $$$OK
}

}
