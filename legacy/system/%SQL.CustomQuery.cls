/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// %SQL.CustomQuery is the root class for custom query function classes. You can extend this class to implement
/// SQL Table-Valued Functions that can be used in SQL statements. 
/// Custom query functions are similar to queries with TYPE = %Library.Query. Subclassing %SQL.CustomQuery has a few advantages
/// over custom class queries. The result set returned by executing, either directly or as a function in an SQL statement, is more efficient
/// when interacting with the server. The metadata for a result set is constructed from the class definition so there is never a need to explicitly define a 
/// ROWSPEC. 
/// </p>
/// <p>
/// </p>
/// <p>
/// When subclassing %SQL.CustomQuery, there are a few steps that you must follow in order to produce
/// a working table-valued function.
/// </p>
/// <p>
/// 	1.	Override the SQLNAME parameter to assign a name to the custom function;
///     2.	Define properties that correspond to each column in the result row. These properties correspond to the columns that form the ROWTYPE of the 
/// 		table function. Column numbers are assigned in the order in which the properties appear in the class definition. If the property type is swizzleable then 
/// 	any direct access to the property will trigger swizzling. %Get, %GetData and the various %Send methods will not 
/// swizzle the object.<br>
/// <u>Note:</u> Properties inherited from a system superclass are not considered to be part of the row.
/// </p>
/// <p>
/// 	3.	Define any private properties needed to maintain the current state of the
/// 		cursor. Any property defined as PRIVATE is automatically excluded from the ROWTYPE. 
/// </p>
/// <p>
/// 	4.	Override and implement <method>%OpenCursor</method>. Formal arguments defined by %OpenCursor become the formal arguments for the projected table-value function. 
/// 		Code in this method initializes the cursor and prepares the data to be fetched. 
/// </p>
/// <p>
/// 	5.	Override and implement <method>%FetchCursor</method>. Code in this method retrieves the next row and sets the properties corresponding to
/// 		columns in the row to the appropriate value. If no row is found this method returns 0, otherwise it returns 1.
/// 		This method must also maintain the value of the <property>%ROWCOUNT</property> property.
/// </p>
/// <p>
/// 	5.	Override and implement <method>%CloseCursor</method>. This is only necessary if you need to perform some
/// 		clean up. %CloseCursor is called when the object is destructed.
/// </p>
/// <p>
/// The following class definition is an example of a simple custom query. This example accepts a JSON array and presents the name and city 
/// properties from each element of the array as a row. 
/// <pre>
/// 	Class User.TVF Extends %SQL.CustomQuery
/// 	{
/// 
/// 	Parameter SQLNAME = "custom_tvf";
/// 
/// 	Property name As %String;
/// 
/// 	Property city As %String;
/// 
/// 	Property sourceData As %Library.DynamicArray [ Private ];
/// 
/// 	Property iterator As %Iterator.Array [ Private ];
/// 
/// 	Method %OpenCursor(sourceData As %String(MAXLEN="")) [ Private ]
/// 	{
/// 		if ('$isObject(sourceData)) || ('sourceData.%IsA("%Library.DynamicAbstractObject")) {
/// 			set ..sourceData = ##class(%Library.DynamicAbstractObject).%FromJSON(sourceData)
/// 		} else {
/// 			set ..sourceData = sourceData
/// 		}
/// 		set ..iterator = ..sourceData.%GetIterator()
/// 	}
/// 
/// 	Method %CloseCursor() [ PlaceAfter = %Next, Private ]
/// 	{
/// 		set ..iterator = ""
/// 		set ..sourceData = ""
/// 	}
/// 
/// 	Method %FetchCursor(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer
/// 	{
/// 		if ($isObject(..iterator)) && (..iterator.%GetNext(.key,.value)) {
/// 			set ..name = value.name
/// 			set ..city = value.city
/// 		} else {
/// 			set ..iterator = ""
/// 			return 0
/// 		}
/// 		return 1
/// 	}
/// 
/// 	}
/// </pre>
/// </p>
/// <p>
/// The above example can be referenced in the from clause of a SELECT statement. 
/// <pre>
/// select * from custom_tvf('[{"name":"Hermann, George","city":"New York, NY"},{"name":"Orr, Bobby","city":"Boston, MA"}]') order by city
/// </pre>
/// <table>
/// <tr>
/// </tr>
/// 	<th align="left">name</th><th align="left">city</th>
/// </tr>
/// <tr>
/// 	<td>Orr, Bobby</td><td>Boston, MA</td>
/// </tr>
/// <tr>
/// 	<td>Hermann, George</td><td>New York, NY</td>
/// </tr>
/// <tr></tr>
/// <tr>
/// 	<td>2 Rows(s) Affected</td>
/// </tr>
/// </table>
/// </pre>
/// </p>
/// <p>
/// A custom query function can also be instantiated directly and iterated over using the result set interface. The first argument passed to %New() is 
/// SELECTMODE, as is defined by the <class>%SQL.IResultSet</class> interface. Subsequent arguments are as defined by the <method>%OpenCursor</method>. 
/// <pre>
/// 	USER>set cursor = ##class(TVF).%New(,[{"name":"Hermann, George","city":"New York, NY"},{"name":"Orr, Bobby","city":"Boston, MA"}])
/// 
/// 	USER>write cursor.%Next()
/// 	1                                               
/// 	USER>write cursor.name
/// 	Hermann, George
/// 	USER>write cursor.city
/// 	New York, NY
/// 	USER>write cursor.%SQLCODE
/// 	0
/// 	USER>write cursor.%Next()
/// 	1                                               
/// 	USER>write cursor.name    
/// 	Orr, Bobby
/// 	USER>write cursor.%Next()
/// 	0
/// 	USER>write cursor.%SQLCODE
/// 	100
/// </pre>
/// </p>
Class %SQL.CustomQuery Extends %SQL.IResultSet [ Abstract, System = 4 ]
{

Query CQ() As %SQL.DICT.QueryTypeCustom(ROWSPEC = "{..#statementmetadata}") [ Internal, SqlName = "{..#SQLNAME}", SqlProc ]
{
}

/// Override this parameter to define the SQLNAME of the query procedure. If this value is not
/// specified then a default procedure name will be generated using the standard procedure naming
/// convention.
Parameter SQLNAME As String = "{..#SQLNAME}";

/// <p>
/// Implement code to open the cursor here. You may also define new formal arguments. Any arguments defined
/// will be automatically added to the table-valued function project to SQL and to the constructor interface. 
/// Callers can specify actual arguments in the call to %New() when invoking the function from an SQL statement. 
/// <pre>
/// 		method %OpenCursor(pBeginDate as %Date = "", pEndDate as %Date = "") as %Library.Status [ private ]
/// 		{
/// 			set ..BeginDate = pBeginDate
/// 			set ..EndDate = $Select(pEndDate'="":pEndDate,1:$H)
/// 		}
/// </pre>
/// </p>
/// <p>
/// Given the above example implementation of %OpenCursor, the following is a valid call to instantiate a new instance.
/// <pre>
/// 		set tResult = ##class(MyCustom.Query).%New(,$H-30,$H-10)
/// </pre>
/// </p>
/// <p>
/// To report an error set <property>%SQLCODE</property> and <property>%Message</property> to appropriate values. To report no rows found, 
/// set <property>%SQLCODE</property> to 100. Errors are indicated by negative ..%SQLCODE values. It is also acceptable to simply throw 
/// an exception and the system will assign appropriate values to <property>%SQLCODE</property> and <property>%Message</property>. 
/// </p>
Method %OpenCursor() [ Private ]
{
	throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"The '%OpenCursor' method has not been implemented for the custom query class '"_$classname())
}

/// <p>
/// Advance the cursor to the next row. If the cursor is found to be at the end of the data then return 0, otherwise populate the row properties and return 1. 
/// </p>
/// <p>
/// To report an error set <property>%SQLCODE</property> and <property>%Message</property> to appropriate values. It is also acceptable to simply throw 
/// an exception and the system will assign appropriate values to <property>%SQLCODE</property> and <property>%Message</property>. 
/// </p>
Method %FetchCursor() As %Library.Integer
{
	throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"The '%FetchCursor' method has not been implemented for the custom query class '"_$classname())
}

/// <p>
/// Implement %CloseCursor to clean up any temporary structures that are used by the custom
/// query such as temporary globals, etc. This method is invoked by the object destructor.
/// <pre>
/// 		method %CloseCursor() [ private ]
/// 		{
/// 			&sql(close myCursor)
/// 				kill ^||mytempglobal
/// 			quit $$$OK
/// 		}
/// </pre>
/// </p>
Method %CloseCursor() [ PlaceAfter = %Next, Private ]
{
	if 1
}

/// %OnNew is called by the constructor. It supports a variable number of arguments passed by value. The first argument
/// is the runtime SELECTMODE value and it defaults to $system.SQL.GetSelectMode(). This method is generated as final.
/// It invokes the user implemented <method>%OpenCursor</method> method. Any formal arguments defined by the %OpenCursor method will be added
/// to the formal spec of %OnNew. Actual values for these arguments can be specified when calling %New().
/// Errors are reported by setting ..%SQLCODE, ..%Message. Do not override this method. 
Method %OnNew(pSelectMode As %Integer = {$zu(115,5)}) As %Library.Status [ CodeMode = generator, GenerateAfter = %OpenCursor, Internal ]
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
		#; count the number of RESULTCOL properties
	Set prop = $$$comMemberNext(%class,$$$cCLASSproperty,""), property = "", tObjectsMD = ""
	While prop '= "" {
		$$$comMemberKeyGetLvar(private,%class,$$$cCLASSproperty,prop,$$$cPROPprivate)
		$$$comMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,prop,$$$cPROPorigin)
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
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
	$$$GENERATE("	try {")
	$$$GENERATE("		set ..%ResultColumnCount = "_(+property)_", ..%SelectMode = pSelectMode" _ tObjectsMD)
	$$$GENERATE("		do ..%OpenCursor("_callString_")")
	$$$GENERATE("		if ..%SQLCODE '< 0 { Set ..%NextColumn="_(property + 1) _ " do ..%GetSerializedMetadata(.tMetadata) merge i%%Metadata = tMetadata }")
	$$$GENERATE("	} catch tException {")
	$$$GENERATE("		if tException.%IsA(""%Exception.SQL"") { set ..%SQLCODE = tException.Code, ..%Message = tException.Data }")
	$$$GENERATE("		elseif tException.%IsA(""%Exception.StatusException"") { if (tException.Code = "_$$$ERRORCODE($$$SQLCode)_") || (tException.Code = "_$$$ERRORCODE($$$SQLError)_") { set ..%SQLCODE = $Listget(tException.Data,1), ..%Message = $Listget(tException.Data,2) } }")
	$$$GENERATE("		else { set ..%SQLCODE = -400, ..%Message = ""Exception caught during result set construction: "" _ tException.Code_"":""_tException.Name }")
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	quit $$$OK
}

/// Advance the cursor to the next row. Returns 0 if the cursor is at the end of the 
/// data. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the %Next call. <property>%SQLCODE</property> is also set by %Next.
/// This implementation is overridden by classes that implement the result set interface. Do not override this method. 
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer [ Final, Internal ]
{
	try {
		set tReturn = ..%FetchCursor()
		if tReturn {
			set ..%ROWCOUNT = ..%ROWCOUNT + 1
			set ..%SQLCODE = 0, ..%Message = ""
		} else {
			set ..%SQLCODE = 100
		}
	} catch tException {
		set sc = tException.AsStatus()
		set ..%SQLCODE = tException.AsSQLCODE()
		set ..%Message = tException.AsSQLMessage()
		set tReturn = 0
	}
	quit tReturn
}

/// This method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed. It is invoked automatically 
/// when the instance is destructed. 
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Library.Status [ Final, Internal, Private, ProcedureBlock = 1, PublicList = SQLCODE, ServerOnly = 1 ]
{
	new SQLCODE
	try {
		do ..%CloseCursor()
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	quit tStatus
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
			If $Length(case(case)) > 500 { Set case = case + 1, case(case) = "		,"""_$$$ucase(column)_""":.." _ $Select(property(column,1):$$$QN(property(column)),1:$$$QN(property(column)_"GetObjectId")_"()") }
			Else { set case(case) = case(case) _ ","""_$$$ucase(column)_""":.." _ $Select(property(column,1):$$$QN(property(column)),1:$$$QN(property(column)_"GetObjectId")_"()") }
			Set column = $Order(property(column))
		}
		if case = 1 {
			$$$GENERATE("		set returnVal = "_case(1) _ ")")
		} else {
			$$$GENERATE("		set returnVal = "_case(1))
			for ptr = 2:1:case-1 { $$$GENERATE(case(ptr)) }
			$$$GENERATE(case(case)_")")
		}
		$$$GENERATE("	} catch {")
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
			if $Length(case(case)) > 500 { set case = case + 1, case(case) = $Char(9)_"," _ intCol _ ":.." _ $Select(property(ptr,1):$$$QN(property(ptr)),1:$$$QN(property(ptr)_"GetObjectId") _"()") }
			else { set case(case) = case(case) _ "," _ intCol _":.." _ $Select(property(ptr,1):$$$QN(property(ptr)),1:$$$QN(property(ptr)_"GetObjectId") _ "()") }


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
	$$$GENERATE($c(9,9,9)_"if $d(sc)#2,$$$ISERR(sc) { set:SQLCODE>=0 SQLCODE=-400 set %msg=$$GetErrorText^%apiOBJ(sc) }")
	$$$GENERATE($c(9,9,9)_"quit")
	$$$GENERATE($c(9,9)_"}")
	$$$GENERATE($c(9)_"}")
	$$$GENERATE($c(9)_"QUIT SQLCODE")
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
		If (origin = "%SQL.IResultSet") || (origin = "%SQL.StatementResult") { Set private=1 }
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
	set tLineCount = 0
	set tLine = "	set pMetadata(0) = $lb(" _ property _ ","
		#; bstr is a constant for all properties in a custom result set. This could change...
	set bstr = "$Char(0,0,0,0,0,0,0,0,0,0,0,0)"
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
		if $Length(tLine) > 200 {
			$$$GENERATE($Extract(tLine,1,*-1) _ ")")
			set tLineCount = tLineCount + 1, tLine = "	set pMetadata("_tLineCount_") = $lb("
		}
		Set tLine = tLine _ colName_","_colODBCType_","_precision_","_scale_","_nullable_","_colName_","_colTablename_"," _ colSchema _",""""," _ bstr_","
		Set ptr = $Order(property(ptr))
	}
	$$$GENERATE($Extract(tLine,1,*-1) _ ")")
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

}
