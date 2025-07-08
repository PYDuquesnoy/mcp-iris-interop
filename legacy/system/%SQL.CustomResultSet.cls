/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// %SQL.CustomResultSet is the root class for custom result sets. You can extend this class to implement 
/// custom result sets that can be instantiated and returned as dynamic result sets by a stored procedure. 
/// Custom result sets are similar to queries with TYPE = %Library.Query. Subclassing %SQL.CustomResultSet has a few advantages 
/// over custom queries. Result sets are more efficient when interacting with the server. 
/// The metadata for a result set is constructed from the class definition so there is never a need for 
/// ROWSPEC. Also, %SQL.CustomResultSet defines a more object-oriented interface.
/// </p>
/// <p>
/// You can make custom result sets available to dynamic SQL by implementing a class method projected as a stored procedure. 
/// An example of a custom result set is available in the SAMPLES database. There is also an example of creating a stored procedure 
/// that returns an instance of a custom result set to the caller. Such a procedure can be invoked using the embedded 
/// or dynamic CALL statement.
/// </p>
/// <p>
/// When subclassing %SQL.CustomResultSet, there are a few steps that you must follow in order to produce 
/// a working result set.
/// </p>
/// <p>
/// 	1.	Define properties that correspond to each column in the result row. If the property type is swizzleable then 
/// 	any direct access to the property will trigger swizzling. %Get, %GetData and the various %Send methods will not 
/// swizzle the object.<br><br>
/// <u>Note:</u> Properties inherited from a system superclass are not considered to be part of the row.
/// </p>
/// <p>
/// 	2.	Define any private properties needed to maintain the current state of the 
/// 		result set.
/// </p>
/// <p>
/// 	3.	Override and implement %OpenCursor. Code in this method initializes the result 
/// 		iterator and prepares the data for return. It also reports any errors encountered during execution 
/// 		by setting %SQLCODE and %Message.
/// </p>
/// <p>
/// 	4.	Override and implement %Next. Code in this method retrieves the next row and sets the properties corresponding to 
/// 			columns in the row to the appropriate value. If no row is found this method returns 0, otherwise it returns 1. 
/// 			This method must also set value of the %ROWCOUNT property.
/// </p>
/// <p>
/// 	5.	Override and implement %CloseCursor. This is only necessary if you need to perform some 
/// 		clean up. %CloseCursor is called when the object is destructed.
/// </p>
Class %SQL.CustomResultSet Extends %SQL.IResultSet [ Abstract, System = 4 ]
{

Parameter %statementmetadata;

Parameter %statementmetadataext;

Parameter %statementobjects;

Parameter %statementparameters;

Parameter %statementactual;

/// %OnNew is called by the constructor. It supports a variable number of arguments passed by value. The first argument
/// is the runtime SELECTMODE value and it defaults to $system.SQL.GetSelectMode(). This method is generated as final.
/// It invokes the user implemented %OpenCursor method. Any formal arguments defined by the %OpenCursor method will be added
/// to the formal spec of %OnNew. Actual values for these arguments can be specified when calling %New().
/// Errors are reported by setting ..%SQLCODE, ..%Message.
Method %OnNew(pSelectMode As %Integer = {$zu(115,5)}) As %Library.Status [ CodeMode = generator, Final, GenerateAfter = %OpenCursor ]
{
	set %code = 0
	if $$$comClassKeyGet(%class,$$$cCLASSabstract) { quit $$$OK }
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
		#; construct an array of query select properties.
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,""), property = 0, tObjectsMD = ""
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
		If 'private {
			$$$comMemberKeyGetLvar(intSeq,%class,$$$cCLASSproperty,prop,$$$cXXXXsequencenumber)
			set property(intSeq) = prop, property = property + 1
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}
	$$$comClassKeyGetLvar(colSchema,%class,$$$cCLASSsqlschemaname) $$$comClassKeyGetLvar(colTablename,%class,$$$cCLASSsqltablename)
		#; construct metadata by regenerating the $list from literals. Cached queries store the metadata
		#; in the query cache but result sets don't have any persistent storage. We could change that but we will
		#; just use this mechanism for now.
		#; 
	set tMetadataPtr = 0, tMetadata(0) = $lb(property), tObjects = "", tDynamic = ""
		#; bstr is a constant for all properties in a custom result set. This could change...
	set bstr = "$Char(0,0,0,0,0,0,0,0,0,0,0,0)"
	set tPtr2 = $order(property(""))
	while tPtr2 '= "" {
		$$$comMemberKeyGetLvar(colCacheType,%class,$$$cCLASSproperty,property(tPtr2),$$$cPROPtype)
		$$$comMemberKeyGetLvar(colName,%class,$$$cCLASSproperty,property(tPtr2),$$$cPROPsqlfieldname)
		$$$comMemberKeyGetLvar(colRequired,%class,$$$cCLASSproperty,property(tPtr2),$$$cPROPrequired)
		merge colParms = $$$comMemberKeyRaw(%class,$$$cCLASSproperty,property(tPtr2),$$$cPROPparameter)
		do GetODBCColInfo^%ourODBC(colCacheType,.colParms,.colODBCTypeName,.colODBCType,.maxLen,.precision,.scale)
		set tClientTypeEnum = $$$comClassKeyGet(colCacheType,$$$cCLASSclientdatatypeenum)
			#; Extract the column information
		set nullable = 'colRequired
		set radix=$select(";-6;-5;2;3;4;5;6;7;8;"[(";"_colODBCType_";"):10,1:"")

		set:$length(tMetadata(tMetadataPtr))>32000 tMetadata = tMetadata + 1, tMetadata(tMetadataPtr) = ""
		set tMetadata(tMetadataPtr) = tMetadata(tMetadataPtr) _ $listbuild(colName,colODBCType,precision,scale,nullable,colName,colTablename,colSchema,"",bstr)
		set tDynamic = tDynamic _ $listbuild($listbuild("",colCacheType,tClientTypeEnum))
			#; This is an object - add to the list
		if '$$$classIsDataType(colCacheType) {
			$$$comClassKeyGetLvar(tSchema,colCacheType,$$$cCLASSsqlschemaname)
			$$$comClassKeyGetLvar(tTable,colCacheType,$$$cCLASSsqltablename)
			if (tSchema '= "") && (tTable '= "") { set tQuickQuery = $get(^oddSQL(tSchema,tTable,"QQ")) set:tQuickQuery'="" tQuickQuery="##class("_$listget(tQuickQuery)_")."_$listget(tQuickQuery,2)_"(%rowid,%nolock,0,1)" } else { set tQuickQuery = "" }
			if (tSchema '= "") && (tTable '= "") { set tCall = $Get(^oddSQL(tSchema,tTable,"QL")) } else { set tCall = "" }
			set tObjects = tObjects _ $listbuild($listbuild(tColumnName,colCacheType,tCall,tPtr2))
		}
		set tPtr2 = $order(property(tPtr2))
	}
		// Generate parameters to hold statement metadata
	if $get(tMetadata(0)) '= "" {
		set tPtr = 0
		while $data(tMetadata(tPtr)) {
			set parameter = "%statementmetadata" _ tPtr
			$$$comMemberSet(%class,$$$cCLASSparameter,parameter,"")
			$$$comMemberKeySet(%class,$$$cCLASSparameter,parameter,$$$cXXXXorigin,%class)
			$$$comMemberKeySet(%class,$$$cCLASSparameter,parameter,$$$cXXXXinheritsecondary,1)
			$$$comMemberKeySet(%class,$$$cCLASSparameter,parameter,$$$cPARAMdefault,tMetadata(tPtr))
			set tPtr = tPtr + 1
		}
		$$$comMemberSet(%class,$$$cCLASSparameter,"%statementmetadata","")
		$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadata",$$$cXXXXorigin,%class)
		$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadata",$$$cXXXXinheritsecondary,1)
		$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadata",$$$cPARAMdefault,tPtr-1)
	}
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementobjects",$$$cXXXXorigin,%class)
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementobjects",$$$cXXXXinheritsecondary,1)
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementobjects",$$$cPARAMdefault,tObjects)
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadataext",$$$cXXXXorigin,%class)
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadataext",$$$cXXXXinheritsecondary,1)
	$$$comMemberKeySet(%class,$$$cCLASSparameter,"%statementmetadataext",$$$cPARAMdefault,tDynamic)
	$$$GENERATE("	try {")
	$$$GENERATE($Char(9,9)_"set ..%ResultColumnCount = "_property_", ..%SelectMode = pSelectMode" _ tObjectsMD _ ", status = ..%OpenCursor("_callString_")")
	$$$GENERATE($Char(9,9)_"if ..%SQLCODE '< 0 { Set ..%NextColumn="_(property + 1) _ " do ..%GetSerializedMetadata(.tMetadata) merge i%%Metadata = tMetadata }")
	$$$GENERATE($Char(9,9)_"set ..%Objects = ..#%statementobjects")
	$$$GENERATE($Char(9,9)_"set ..%ExtendedMetadata = ..#%statementmetadataext")
	$$$GENERATE($Char(9)_"} catch tException {")
	$$$GENERATE($Char(9,9)_"if tException.%IsA(""%Exception.SQL"") { set ..%SQLCODE = tException.Code, ..%Message = tException.Data }")
	$$$GENERATE($Char(9,9)_"elseif tException.%IsA(""%Exception.StatusException"") { if (tException.Code = "_$$$ERRORCODE($$$SQLCode)_") || (tException.Code = "_$$$ERRORCODE($$$SQLError)_") { set ..%SQLCODE = $Listget(tException.Data,1), ..%Message = $Listget(tException.Data,2) } }")
	$$$GENERATE($Char(9,9)_"else { set ..%SQLCODE = -400, ..%Message = ""Exception caught during result set construction: "" _ tException.Code_"":""_tException.Name }")
	$$$GENERATE($Char(9)_"}")
	$$$GENERATE($Char(9)_"Quit $$$OK")
	quit $$$OK
}

/// Implement code to open the cursor here. You may also define new formal arguments. Any arguments defined
/// will be automatically added to the constructor interface and callers can specify actual arguments in the
/// call to %New().
/// <pre>
/// 		method %OpenCursor(pBeginDate as %Date = "", pEndDate as %Date = "") as %Library.Status [ private ]
/// 		{
/// 			set ..BeginDate = pBeginDate
/// 			set ..EndDate = $Select(pEndDate'="":pEndDate,1:$H)
/// 			quit $$$OK
/// 		}
/// </pre>
/// Given the above example implementation of %OpenCursor, the following is a valid call to instantiate a new instance.
/// <pre>
/// 		set tResult = ##class(MyCustom.ResultSet).%New(,$H-30,$H-10)
/// </pre>
/// To report an error from %OpenCursor just set ..%SQLCODE and %Message to appropriate
/// values. To report no rows found, set %SQLCODE to 100. Errors are indicated by negative
/// ..%SQLCODE values.
Method %OpenCursor() As %Library.Status [ Private ]
{
	set ..%SQLCODE = -400, ..%Message = "The '%OpenCursor' method has not been implemented for the custom result set class '"_$classname()
	quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1, PublicList = SQLCODE, ServerOnly = 1 ]
{
	new SQLCODE
	Quit ..%CloseCursor()
}

/// Implement %CloseCursor to clean up any temporary structures that are used by the custom
/// result such as temporary globals, etc. This method is invoked by the object destructor.
/// <pre>
/// 		method %CloseCursor() as %Library.Status [ private ]
/// 		{
/// 			&sql(close myCursor)
/// 				kill ^||mytempglobal
/// 			quit $$$OK
/// 		}
/// </pre>
Method %CloseCursor() As %Library.Status [ CodeMode = expression, PlaceAfter = %Next, Private ]
{
$$$OK
}

///  Returns the value of the column with the name <var>colname</var> in the current row of the result set.
///  <p>If <var>colname</var> is not a valid column name, this method throws a <PROPERTY DOES NOT EXIST> error.
Method %Get(colname As %String = "") As %Library.String [ CodeMode = generator ]
{
	Set %code=0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
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
/// 		Returns the value of the column referenced by <var>colnbr</var>. Object values are not swizzled automatically.
Method %GetData(colnbr As %Integer = 0) As %Library.String [ CodeMode = generator, ProcedureBlock = 0 ]
{
	Set %code=0, property = 0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
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
		$$$GENERATE("	new returnVal")
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
	new intCol,intSeq,prop,property,ptr,rowvalue
	Set %code=0
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) { Quit $$$OK }
	Set property = 0
		#; construct an array of query select properties.
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,"")
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
		If 'private {
			$$$comMemberKeyGetLvar(intSeq,%class,$$$cCLASSproperty,prop,$$$cXXXXsequencenumber)
			$$$comMemberKeyGetLvar(runtimetype,%class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
			Set property = property + 1
			if $$$classIsDataType(runtimetype) { Set property(intSeq) = prop, property(intSeq,1) = 1 }
			else { Set property(intSeq) = prop, property(intSeq,1) = 0 }
		}
		Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,prop)
	}

	Set ptr = $Order(property("")), rowvalue="$lb("
	While ptr '="" {
		if property(ptr,1) { set rowvalue=rowvalue_"i%"_property(ptr)_"," }
		else { set rowvalue=rowvalue_".."_property(ptr)_"GetObjectId()," }
		Set ptr = $Order(property(ptr))
	}
	if $l(rowvalue)>4 { set $e(rowvalue,*)=")" } else { set rowvalue=rowvalue_")" }
	$$$GENERATE($c(9)_"for {")
	$$$GENERATE($c(9,9)_"if ..%Next(.sc) {")
	$$$GENERATE($c(9,9,9)_"set SQLCODE=0")
		#; Don't need a %protocol check here because there is no way for the values to be <UNDEFINED>, which would snd an 01/null instead of an 0201/null.
		#; Old logic that uses $zobjexport(...,7) would have had the same issue (or maybe gotten an <UNDEFINED> error at runtime.
	$$$GENERATE($c(9,9,9)_"quit:$zobjexport("_rowvalue_",60)")
	$$$GENERATE($c(9,9)_"}")
	$$$GENERATE($c(9,9)_"else {")
	$$$GENERATE($c(9,9,9)_"set SQLCODE=100")
	$$$GENERATE($c(9,9,9)_"if $d(sc)#2,$$$ISERR(sc) { set SQLCODE=-400,%msg=$$GetErrorText^%apiOBJ(sc) }")
	$$$GENERATE($c(9,9,9)_"quit")
	$$$GENERATE($c(9,9)_"}")
	$$$GENERATE($c(9)_"}")
	$$$GENERATE($c(9)_"QUIT SQLCODE")
	QUIT $$$OK
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
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
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
			set tCall = $List(objects(tPtr),3)
			continue:tCall=""
			$$$GENERATE("		set %rowid = i%" _ $List(objects(tPtr),1))
			$$$GENERATE("		if %rowid '= """" { do $classmethod(""" _ $List(tCall) _ """,""" _ $List(tCall,2) _ """,%rowid) if %qrc goto exit }")
		}
		$$$GENERATE("	}")
		$$$GENERATE("exit	quit %qrc")
	}
	else { $$$GENERATE("	quit 0") }
	Quit $$$OK
}

/// <b>DO NOT USE DIRECTLY</b> - use <method>%GetClientMetadata</method> instead
/// Builds the serialized metadata for this result set.
Method %GetSerializedMetadata(ByRef pMetadata As %RawString = "") As %Status [ CodeMode = generator, Internal ]
{
	set %code=0
	if $$$comClassKeyGet(%class,$$$cCLASSabstract) { quit $$$OK }
	$$$GENERATE($Char(9)_"kill pMetadata set tMDC = ..#%statementmetadata if tMDC '= """" { for tPtr = 0:1:tMDC { set pMetadata(tPtr) = $parameter($this,""%statementmetadata""_tPtr) } }") 
	$$$GENERATE($Char(9)_"Quit $$$OK")
	quit $$$OK
}

}
