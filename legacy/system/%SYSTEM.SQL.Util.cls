/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.SQL.Util Extends %SYSTEM.Help [ Abstract, Owner = {_PUBLIC}, Not ProcedureBlock, System = 4 ]
{

/// This method closes all the open ODBC/JDBC Gateway connections and unloads the SQL Gateway shared library.
ClassMethod CloseAllGateways() As %Integer
{
	return $$DropAll^%apiGTW()
}

/// This entrypoint is used to determine if an SQL Map definition is selectable by the SQL Query Optimizer or not
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>pTablename</i>
/// <dd>Name of the table to check.<br>
/// <i>pTablename</i> can be qualified or unqualified.  If unqualified, the default schema is applied.
/// <dt><i>pMapname</i>
/// <dd>Name of the SQL Map in the table to check the selectable for.<br>
/// </dl>
/// <p><b>Returns:</b>
/// 1 if the map is selectable, 0 if the map is not selectable.
/// If the table or map does not exist, or there is an invalid input paramater, 0,<i>message</i> will be returned as the map is not selectable or the selectability cannot be determined.
/// <p><b>Notes:</b><ul>A return of 1 by this function does not necessarily mean the table and map exist, just that the map's selectability has not been set to 0.</ul>
/// <ul>This function checks the selectability for the map in the current namespace only.
/// If this table is mapped to multiple namespaces, and the index needs to be built in each namespace, SetMapSelectability should be called in each namespace the index is to be built in.  GetMapSelectability should be checked in each namespace the table is mapped to.</ul>
/// </dl>
/// <p><b>Example</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Util.GetMapSelectability("Sample.Person","NameIdx")
/// </ul>
/// <p>Sample.Person is part of <a target="_top" href="https://github.com/intersystems/Samples-Data">https://github.com/intersystems/Samples-Data.</a>
/// See <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=landing+githubsamples">Downloading Samples</a>.</p>
ClassMethod GetMapSelectability(pTablename As %Library.String = "", pMapname As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	#dim classname,map,tSchema,tTable,tTablename As %String
	
	RETURN:pTablename="" "0,"_$$$FormatText($$$Text("Missing argument value for parameter: %1","%SQL.Function"),"pTablename")
	RETURN:pMapname="" "0,"_$$$FormatText($$$Text("Missing argument value for parameter: %1","%SQL.Function"),"pMapname")
	set tTablename=$$IntQualifiedName^%apiSQL(pTablename)
	RETURN:tTablename="" "0,"_$$$FormatText($$$Text("Unable to determine Schema.Table from given pTablename value: %1","%SQL.Function"),pTablename)
	set tSchema=$$$SchemaFromIQN(tTablename)
	RETURN:tSchema="" "0,"_$$$FormatText($$$Text("Unable to determine Schema name from given pTablename value: %1","%SQL.Function"),pTablename)
	set tTable=$$$TableFromIQN(tTablename)
	RETURN:tTable="" "0,"_"0,"_$$$FormatText($$$Text("Unable to determine Table name from given pTablename value: %1","%SQL.Function"),pTablename)
	set selectable=1
	set tMapname=$$$UPPER(pMapname)
	if $data(^rINDEXEXT("MS",tSchema,tTable,tMapname)) || 		 // new/currect setting location
	   $data(^oddSQL(tSchema,tTable,"MS",tMapname,$namespace)) { // if original global is not defined, map is selectable
	   set selectable=0
	}
	set irn=$$smdLoadGetIrn^%qTable(tTablename,,,.SQLCODE)
	if 'irn {	// table not defined
		if selectable { RETURN "0,"_$$$FormatText($$$Text("Map %1 is not selectable because table %2 does not exist","%SQL.Function"),pMapname,pTablename) }
		else          { RETURN "0,"_$$$FormatText($$$Text("Map %1 is defined as not selectable, but table %2 does not exist","%SQL.Function"),pMapname,pTablename) }
	} else {	// Table exists, see if the map exists
			#; check in $$$smd first...
		if $d($$$smd(1,irn,"map",tMapname)) { RETURN selectable }	// a Map exists, return if it is selectable or not
			#; Functional Index maps are not defined in $$$smd, so we check here that the map is defined in ^oddEXTR(classname,"S",mapname)
		set classname=$$$smdClassname(1,irn)
		set defined=0,map=""
		for  {
			set map=$o($$$EXTSQLMAP($$$rEXT,classname,map)) quit:map=""
			if $$$UPPER(map)=tMapname { set defined=1 quit }
		}
		if defined { RETURN selectable }	// a Map exists, return if it is selectable or not
		if selectable { RETURN "0,"_$$$FormatText($$$Text("Map %1 is not defined in table %2","%SQL.Function"),pMapname,pTablename) }
		RETURN "0,"_$$$FormatText($$$Text("Map %1 is not defined in table %2, but it is defined as not selectable","%SQL.Function"),pMapname,pTablename)
	}
}

/// Given one of the following valid, case-insensitive values for <i>pOption</i>, return the current value for that option.<br><br> 
/// <b><i>AdaptiveMode</i></b> - Returns the configuration setting which determines if adaptive mode is applied.
/// <ul>
/// <li>0 = Do not apply adaptive mode.</li>
/// <li>1 = Apply Adaptive Mode (this covers Run Time Plan Choice, automatic parallelized query execution, automatic tuning of untuned tables, Frozen/Upgrade query plans, and more. Please see the product documentation for a complete overview; 1 = Default).</li>
/// </ul>
/// 
/// <b><i>AllowExtrinsicFunctions</i></b> - Returns if extrinsic functions are allowed to be used in SQL statements through ODBC, JDBC, and Dynamic SQL.
/// <ul>
/// <li>0 = Do not allow extrinsic functions in SQL statements through ODBC, JDBC, or Dynamic SQL (Default).</li>
/// <li>1 = Allow extrinsic functions in SQL statements through ODBC, JDBC, or Dynamic SQL.</li>
/// </ul>
/// 
/// <b><i>ANSIPrecedence</i></b> - Returns if ANSI operator precedence is applied.
/// <ul>
/// <li>0 = Do not apply ANSI precedence in SQL statements.</li>
/// <li>1 = Apply ANSI precedence in SQL statements (Default).</li>
/// </ul>
/// 
/// <b><i>AutoCommit</i></b> - Returns the current process's Transaction Commit Mode value. Possible values are:
/// <ul>
/// <li>0 = NO AUTO TRANSACTION</li>
/// <li>1 = AUTO COMMIT ON (Default)</li>
/// <li>2 = AUTO COMMIT OFF</li>
/// </ul>
/// 
/// <b><i>AutoParallel</i></b> - Returns the configuration setting which determines if auto hinting %PARALLEL is applied. The default is use of auto hinting %PARALLEL is applied.
/// <ul>
/// <li>0 = Do not apply auto hinting for %PARALLEL in SQL statements</li>
/// <li>1 = Apply auto hinting for %PARALLEL in SQL (Default)</li>
/// </ul>
/// 
/// <b><i>AutoParallelThreshold</i></b> - Returns the configuration setting which determines the threshold of auto hinting %PARALLEL.
/// The default value is 3200. This value could be roughly thought of as how many rows in the visited map
/// 
/// <p></p><b><i>BitmapFriendlyCheck</i></b> - Returns the current system-wide setting of the BitmapFriendlyCheck flag, a boolean value. 
/// <ul>
/// <li>0 = The class compiler will not perform this check and no error will be returned if the class contains a bitmap index and does not have a positive integer ID type (Default).</li>
/// <li>1 = The class compiler will check to make sure the type of ID of the class is a positive integer if there is a bitmap index defined for the class and the class uses %Storage.SQL.</li>
/// </ul>
/// 
/// <p><b><i>CachedQueryLockTimeout</i></b> - Returns the configuration setting for lock timeout length, in seconds, used for Cached Queries when a lock needs to be acquired on Cached Query metadata.
/// 
/// <p><b><i>CachedQuerySaveSource</i></b> - Returns the configuration setting for cached queries source code retention. The default is no source is saved. The setting is on a per-system basis.
/// <ul>
/// <li>0 - Source is deleted after the cached query has compiled (Default)</li>
/// <li>1 - Source is retained for cached query classes.</li>
/// </ul>
/// 
/// <p><b><i>ClientMaxIdleTime</i></b> - The maximum time (in seconds) that a client may stay idly connected to the server before the server will close the connection.
/// 
/// <p></p><b><i>CollectionProjection</i></b> - Returns the configuration setting for collection projection. Possible values are: 
/// <ul>
/// <li>0 = Do not project collections as columns if also projected as child table (Default).</li>
/// <li>1 = Project all collections as columns.</li>
/// </ul>
/// 
/// <p></p><b><i>CompileMode</i></b> - Returns the current Compile Mode namespace setting, either Deferred or Immediate.
/// 
/// <p><b><i>DDLDefineBitmapExtent</i></b> - Returns the configuration setting flag which determines if a class created by a DDL CREATE TABLE statement defines a bitmap extent index for the class.
/// <ul>
/// <li>0 = Do not define a Bitmap Extent index for a table created through DDL.</li>
/// <li>1 = Automatically define a Bitmap Extent index for tables created through DDL (Default)</li>
/// </ul>
/// 
/// <p><b><i>DDLDropTabDelData</i></b> - Returns the configuration setting flag which determines if a DDL DROP TABLE statement deletes the table's data.
/// <ul>
/// <li>0 = DROP TABLE will not delete the table's data when the table is dropped</li>
/// <li>1 = DROP TABLE will delete the table's data when the table is dropped (Default).</li>
/// </ul>
/// 
/// <p><b><i>DDLFinal</i></b> - Returns the configuration setting flag which determines if a class created by a DDL CREATE TABLE statement is Final.
/// <ul>
/// <li>0 = CREATE TABLE will not define a class as Final</li>
/// <li>1 = CREATE TABLE will define a class as Final (Default)</li>
/// </ul>
/// 
/// <p><b><i>DDLPKeyNotIDKey</i></b> - Returns the configuration setting for PRIMARY KEY in DDL also being the IDKey index.
/// <ul>
/// <li>0 = Primary Key constraints will also become IDKey indices</li>
/// <li>1 = Primary Key constraints will NOT become IDKey indices (Default)</li>
/// </ul>
/// 
/// <p><b><i>DDLUseExtentSet</i></b> - Returns the configuration setting flag which determines if a class created by a DDL CREATE TABLE statement defines the USEEXTENTSET class parameter to a value of 1.
/// <ul>
/// <li>0 = CREATE TABLE will define the USEEXTENTSET class parameter with a value of 0</li>
/// <li>1 = CREATE TABLE will define the USEEXTENTSET class parameter with a value of 1 (Default)</li>
/// </ul>
/// 
/// <p><b><i>DDLUseSequence</i></b> - Returns the configuration setting flag which determines if a class created by a DDL CREATE TABLE statement uses $Sequence for ID assignment.
/// <ul>
/// <li>0 = CREATE TABLE uses $Increment for ID assignment</li>
/// <li>1 = CREATE TABLE uses $Sequence for ID assignment (Default)</li>
/// </ul>
/// 
/// <p><b><i>DefaultTimePrecision</i></b> - Returns the configuration setting for default precision for the Time component of the value returned by the GETDATE(), CURRENT_TIME, and CURRENT_TIMESTAMP SQL Scalar functions.
/// 
/// <p><b><i>DelimitedIdentifiers</i></b> - Returns the configuration setting which determines if double quote ("") in an SQL statement is used for delimited (quoted) identifiers or string constants.
/// <ul>
/// <li>0 = In an SQL statement, "..." is treated as a string literal</li>
/// <li>1 = In an SQL statement, "..." is treated as an identifier (Default)</li>
/// </ul>
/// 
/// <p><b><i>ECPSync</i></b> - Returns whether or not SQL SELECT statements perform a $SYSTEM.ECP.Sync() call in the OPEN code.
/// <ul>
/// <li>0 = Do not perform ECP Syncs for Select queries (Default)</li>
/// <li>1 = Perform ECP Syncs for Select queries</li>
/// </ul>
/// 
/// <p><b><i>FastDistinct</i></b> - Returnss whether or not SQL DISTINCT is optimized to use indexes.
/// <ul>
/// <li>0 = DISTINCT optimization is turned OFF</li>
/// <li>1 = DISTINCT optimization is turned ON (Default)</li>
/// </ul>
/// 
/// <p><b><i>FilerRefIntegrity</i></b> - Returnss the configuration setting which determines if Foreign Key Referential Integrity checks are performed in the SQL Filer. Turning off SQL Filer Referential Integrity checking will suppress any SQLCODE -121, -122, -123, and -124 errors.
/// <ul>
/// <li>0 = Foreign Key Referential Integrity checks are not performed</li>
/// <li>1 = Foreign Key Referential Integrity checks are performed (Default)</li>
/// </ul>
/// 
/// <p></p><i><b>IdentityInsert</i></b> - Returns the current IDENTITY_INSERT option value. Possible values are:
/// <ul>
/// <li>0 = IDENTITY cannot be set (Default).</li>
/// <li>1 = IDENTITY can be set.</li>
/// </ul>
/// 
/// <p></p><b><i>IsolationMode</i></b> - Returns current process's Transaction Isolation Mode value. Possible values are: 
/// <ul>
/// <li>0 = READ UNCOMMITTED (Default).</li>
/// <li>1 = READ COMMITTED</li>
/// <li>3 = READ VERIFIED</li>
/// </ul>
/// 
/// <p></p><b><i>LockThreshold</i></b> - Returns the current Lock Threshold setting.
/// The value returned is an integer that is the number of row locks to acquire before escalating to a table lock.
/// This is a system wide setting that is in effect for all processes.
/// 
/// <p></p><b><i>LockTimeout</i></b> - Return the current system Lock Timeout value as defined in the configuration settings.  Note, this may be different than the lock timeout for the current process.
/// 
/// <p><b><i>ParameterSampling</i></b> - Returns the configuration setting which determines if parameter sampling is enabled
/// <ul>
/// <li>0 = Parameter sampling is disabled (Default).</li>
/// <li>1 = Parameter sampling is enabled.</li>
/// </ul>
/// </ul>
/// 
/// <p></p><b><i>ProcessLockTimeout</i></b> - Returns the Lock Timeout value for the current process.
/// 
/// <p><b><i>RetainSQL</i></b> - Gets the configuration setting which determines if embedded SQL statements are retained as comments in the .INT code version of the routine.
/// <ul>
/// <li>0 = SQL text will be not retained as comments in the .INT code.</li>
/// <li>1 = SQL text will be retained as comments in the INT code (Default).</li>
/// </ul>
/// 
/// <p></p><b><i>RTPC</i></b> - Returns the configuration setting flag that determines if Run Time Plan Choice is applied.
/// <ul>
/// <li>0 = Do not apply Run Time Plan Choice in SQL statements.</li>
/// <li>1 = Apply Run Time Plan Choice in SQL statements (Default).</li>
/// </ul>
/// 
/// <p></p><b><i>SQLFunctionArgConversion</i></b> - Return the current setting of the system wide flag for controlling if SQL Functions perform ODBCToLogical/DisplayToLogical on SQL Function input arguments.
/// 
/// <p><b><i>SQLSecurity</i></b> - Returns the configuration setting which determines if SQL security is enabled. 
/// <ul>
/// <li>0 = SQL security is OFF.</li>
/// <li>1 = SQL security is ON (Default).</li>
/// </ul>
/// 
/// <p></p><b><i>SelectMode</i></b> - Returns the select mode value for the current process. Possible values are: 
/// <ul>
/// <li>0 = Logical (Default).</li>
/// <li>1 = ODBC</li>
/// <li>2 = Display</li>
/// </ul>
/// The select mode returned by this API is used when:<br>
///     #SQLCompile Select = Runtime<br>
/// is specified for the compiled SQL code.<br>
/// When the SQL statement is compiled in Runtime mode, the mode returned by GetSelectMode will be used at runtime
/// to determine whether Logical(0), ODBC(1), or Display(2) mode is used for the statement. 
/// See the documentation for <i>#SQLCompile Select</i> for more information.
/// 
/// <p></p><i><b>ServerDisconnectCode</i></b> - Returns ODBC/JDBC disconnect code.
/// Upon disconnect any ObjectScript code defined in this setting will be executed immediately before 
/// the server process Halts.  This code will also attempt to be executed anytime the server process 
/// encounters an unrecoverable error that causes the server process to Halt.  
/// It will not be executed if the server process encounters a Halt in other user defined code, 
/// if the process crashes, if the process is stopped, or InterSystems IRIS is stopped or forced down.
/// If no disconnect code is defined for this namespace, "" is returned.
/// The disconnect code is defined on a per-namespace basis.
/// 
/// <p></p><i><b>ServerInitCode</b></i> - Returns ODBC/JDBC/SQL Manager initialization code.
/// This Initialization code is executed at login time when connecting to
/// SQL through ODBC, JDBC, or the SQL Manager. 
/// If no initialization code is defined for this namespace, "" is returned.
/// Initialization code is defined on a per-namespace basis.
/// 
/// <p><b><i>TCPKeepAlive</i></b> - Returns the TCP Keep Alive interval (in seconds) for xDBC connections.
/// 
/// <p><b><i>ToDateDefaultFormat</i></b> - Returns the default format for the SQL TO_DATE() function.
/// 
/// <p><b>Example</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Util.GetOption("AutoCommit")
/// </ul>
ClassMethod GetOption(pOption As %String = "") As %String [ ProcedureBlock = 1, SqlProc ]
{
	s option=$$$UPPER(pOption)
	if option="ADAPTIVEMODE" { return $$$AdaptiveMode }
	if option="ALLOWEXTRINSICFUNCTIONS" { return $$$AllowExtrinsicFunctions }
	if option="ANSIPRECEDENCE" { return ''$g(^%SYS("sql","sys","ansi operator precedence")) }
	if option="AUTOCOMMIT" { return $zu(115,1) }
	if option="AUTOPARALLEL" { return $$$AutoParallel }
	if option="AUTOPARALLELTHRESHOLD" { return $$$AutoParallelThreshold }
	if option="BITMAPFRIENDLYCHECK" { return $$$SQLCheckBitmapFriendly }
	if option="CACHEDQUERYLOCKTIMEOUT" { return $$$RawCQGetLockTO }
	if option="CACHEDQUERYSAVESOURCE" { return $$$CQSaveMAC }
	if option="COLLECTIONPROJECTION" { return $$$CollectionProjectionGet }
	if option="COMPILEMODE" { return $$GetCompileMode^%apiSQL() }
	if option="DDLDEFINEBITMAPEXTENT" { return $g(^%SYS("sql","sys","ddl","define bitmap extent"),1) }
	if option="DDLDROPTABDELDATA" { return $g(^%SYS("sql","sys","ddl","drop table delete data"),0) }
	if option="DDLFINAL" { return $g(^%SYS("sql","sys","ddl","class final"),1) }
	if option="DDLPKEYNOTIDKEY" { return $g(^%SYS("sql","sys","ddl","pkey is not idkey"),1) }
	if option="DDLUSEEXTENTSET" { return $g(^%SYS("sql","sys","ddl","useextentset"),1) }
	if option="DDLUSESEQUENCE" { return $g(^%SYS("sql","sys","ddl","use $sequence"),1) }
	if option="DEFAULTTIMEPRECISION" { return $$$TimePrecision }
	if option="DELIMITEDIDENTIFIERS" { return $g(^%SYS("sql","sys","delimited identifiers"),1) }
	if option="ECPSYNC" { return $$$ECPSync }
	if option="FASTDISTINCT" { return $$$FastDistinct }
	if option="FILERREFINTEGRITY" { return $$$GetReferentialChecks }
	if option="IDENTITYINSERT" { return $zu(115,11) }
	if option="ISOLATIONMODE" { return $zu(115,2) }
	if option="LOCKTHRESHOLD" { return $zu(156,50,1) }
	if option="LOCKTIMEOUT" { return $$$GetLockTimeout }
	if option="PARAMETERSAMPLING" { return $$$GetParameterSampling }
	if option="PROCESSLOCKTIMEOUT" { return $zu(115,4) }
	if option="RETAINSQL" { return $$$RetainSQLTextAsComments }
	if option="RTPC" { return $$$RTPCGLOBSETTING }
	if option="SQLFUNCTIONARGCONVERSION" { return $$$SQLFunctionArgConversionG }
	if option="SQLSECURITY" {return $$$GetDBMSSecurity }
	if option="SELECTMODE" { return $zu(115,5) }
	if option="SERVERDISCONNECTCODE" { return $$GetServerDisconnectCode^%apiSQL() }
	if option="SERVERINITCODE" { return $$GetServerInitCode^%apiSQL() }
	if option="TCPKEEPALIVE" { return $$$TCPKeepAlive }
	if option="TODATEDEFAULTFORMAT" { return $$$GetTODATEDefaultFormat }
	if option="CLIENTMAXIDLETIME" { return $$$GetClientMaxIdleTime }
	return $$$ERROR($$$GeneralError, "Error: Invalid option "_pOption)
}

/// Given one of the following valid, case-insensitive values in <i>pOption</i>, update the option to <i>pValue</i>, store the previous value in <i>oldValue</i> 
/// if applicable, and return a status object reflecting whether the update was successful.<br><br>
/// <p><b><i>AdaptiveMode</i></b> - Set the configuration setting which determines if adaptive mode is applied.
/// <ul>
/// <li><i>pValue</i> = 0, do not apply adaptive mode.</li>
/// <li><i>pValue</i> = 1, apply Adaptive Mode (this covers Run Time Plan Choice, automatic parallelized query execution, automatic tuning of untuned tables, Frozen/Upgrade query plans, and more. Please see the product documentation for a complete overview; 1 = Default).</li>
/// </ul>
/// <i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <p><b><i>AllowExtrinsicFunctions</i></b> - determines if extrinsic functions are allowed to be used in SQL statements through ODBC, JDBC, and Dynamic SQL.
/// <ul>
/// <li><i>pValue</i> = 0,  do not allow extrinsic functions in SQL statements through ODBC, JDBC, or Dynamic SQL (Default).</li>
/// <li><i>pValue</i> = 1,  allow extrinsic functions in SQL statements through ODBC, JDBC, or Dynamic SQL.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <p><b><i>ANSIPrecedence</i></b> - determines if ANSI operator precedence is applied.
/// <ul>
/// <li><i>pValue</i> = 0, do not apply ANSI precedence in SQL statements.</li>
/// <li><i>pValue</i> = 1,  apply ANSI precedence in SQL statements (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li>Changing this configuration setting will affect all processes immediately.</li>
/// <li>This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>AutoCommit</i></b> - Sets the AUTO_COMMIT mode for this process.
/// <ul>
/// <li><i>pValue</i> = 0,  No AutoCommit</li>
/// <li><i>pValue</i> = 1,  AutoCommit ON (Default).</li>
/// <li><i>pValue</i> = 2,  AutoCommit OFF.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately and lasts for the duration of the process or until $SYSTEM.SQL.Util.SetOption("AutoCommit",pValue) is called again.</li>
/// <li> This is a per-process setting.</li>
/// </ul></i>
/// <b><i>AutoParallel</i></b> - Sets the configuration setting which determines if auto hinting %PARALLEL is applied. The default is use of auto hinting %PARALLEL is applied.
/// <ul>
/// <li><i>pValue</i> = 0,  do not apply auto hinting for %PARALLEL in SQL statements</li>
/// <li><i>pValue</i> = 1,  apply auto hinting for %PARALLEL in SQL (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>AutoParallelThreshold</i></b> - Sets the configuration setting which determines the threshold of auto hinting %PARALLEL.
/// Once <i>AutoParallel</i> is enabled, use this function to set the threshold for this feature.  Increasing the threshold means it would lower the chance for the auto hinting for %PARALLEL to happen
/// The default value is 3200. This value could be roughly thought of as how many rows in the visited map
/// <ul>
/// <li><i>pValue</i> = Auto parallel threshold value (integer).  Default is 3200.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>BitmapFriendlyCheck</i></b> - determine if the compiler should check if the bitmap index is allowed in a %Storage.SQL class.<br>
/// This setting only applies to classes using %Storage.SQL.
/// <ul>
/// <li><i>pValue</i> = 0,  If a %Storage.SQL class is defined with an ID that is not a positive integer, it is up to the developer of the class to make sure the index is data is properly stored and retrieved from the global. 
///                         An INTEGER type means the class must have either no IDKey index, or a single field IDKey index.
///                         If the class has a single field IDKey index, the type of the IDKey property must be of SqlCategory="INTEGER" or SqlCategory="NUMERIC" with a SCALE=0 and MINVAL=1 or higher.  (Default)</li>
/// <li><i>pValue</i> = 1,  During class compilation the compiler will check to make sure the ID of the table is an INTEGER type if there are any bitmap or bitmap extent indices defined</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li>Changing this configuration setting will affect all processes immediately.</li>
/// <li>This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>CachedQueryLockTimeout</i></b> - Defines the lock timeout length, in seconds, used for Cached Queries when a lock needs to be acquired on Cached Query metadata.
/// - The setting is on a per system basis.<br>
/// <ul>
/// <li><i>pValue</i> = the number of seconds to use for the lock timeout of Cached Query metadata.  The default is 120 seconds.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li>Changing this configuration setting will affect new processes, not existing processes.</li>
/// <li>This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>CachedQuerySaveSource</i></b> - Defines whether or not the source code for cached queries is retained. The default is no source is saved. The setting is on a per-system basis.
/// <ul>
/// <li><i>pValue</i> = 0,  Source is deleted after the cached query has compiled (Default)</li>
/// <li><i>pValue</i> = 1,  Source is retained for cached query classes.  Any new cached queries created by any process will immediately begin saving (or not saving) cached query source. Any existing cached queries will only have source saved if the system was configured to save source at the time the statement was prepared.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li>You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting..</li>
/// <li>Changing this configuration setting will take effect immediately for all processes in InterSystems IRIS after this function is called.</li>
/// <li>This is a system-wide setting.</li>
/// </ul></i>
/// <p><b><i>ClientMaxIdleTime</i></b> - The maximum time (in seconds) that a client may stay idly connected to the server before the server will close the connection.
/// <ul>
/// <li><i>pValue</i> = an integer specifying the time, in seconds, that a client connecton may sit idle. 0 indicates no time limit.</li>
/// </ul>
/// <i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>CollectionProjection</i></b> - Sets the collection projection option. Setting takes effect when classes are recompiled.
/// <ul>
/// <li><i>pValue</i> = 0,  Do not project collections as a column if the collection is projected as a child table. (Default)</li>
/// <li><i>pValue</i> = 1,  Project all collections as columns.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li>Changing this configuration setting will take effect immediately for all future class compilations.</li>
/// <li>This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>CompileModeDeferred</i></b> - 
/// Set the namespace wide flag which turns on Deferred Compilation mode.
/// 'Deferred Compilation Mode' can be used to improve the performance of 'installation-type' activities.  Deferred Compilation Mode will, in most cases, reduce the number of class compilations
/// that take place during the loading of tables through DDL scripts.  When Deferred Compilation Mode is on, classes are not immediately compiled, but put in a compilation queue which will be compiled at a later time when needed.
/// This is very useful during loading of DDL scripts of the following format:<br>
///   - CREATE TABLE MyTable ...<br>
///   - CREATE INDEX MyIndex1 ON MyTable ...<br>
///   - CREATE INDEX MyIndex2 ON MyTable ...<br>
///   - CREATE INDEX MyIndex3 ON MyTable ...<br>
///   - CREATE INDEX MyIndex4 ON MyTable ...<br>
///   - CREATE INDEX MyIndex5 ON MyTable ...<br>
///   - CREATE TABLE MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex1 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex2 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex3 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex4 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex5 ON MyOtherTable ...<br>
///   - ALTER TABLE MyOtherTable ADD FOREIGN KEY MyFKey (MyField) REFERENCES MyTable(MyField)<br>
///   - INSERT INTO MyTable ...<br>
/// Running with Deferred Compilation Mode off would require 13 class compilations for the sequence above.  
/// With Deferred Compilation Mode on, only two class compilations are required.  
/// Classes MyTable and MyOtherTable are compiled when the INSERT statement is encountered. <br>
/// Changing from Deferred to Immediate Compilation Mode will cause any classes in the Deferred Compile Queue to be compiled immediately.  
/// If all class compilations were successful, SQLCODE will return 0.  If there were any errors, SQLCODE will equal -400.  
/// Class compilation errors are logged in the ^mtemp2($namespace,"Deferred Compile Mode","Error").  
/// If SQLCODE=-400 you should view this global structure for more precise error messages.<br>
/// When in Deferred Compilation Mode, any of the following actions will trigger the classes in the Deferred Compilation Queue to be immediately compiled:
/// <ul>
/// <li> Switch back to immediate compile mode. </li>
/// <li> An xDBC Catalog query is called. </li>
/// <li> A DML statement is issued (INSERT, SELECT, GRANT, etc) </li>
/// <li> CREATE INDEX statement is executed. </li>
/// <li> DROP INDEX statement is executed. </li>
/// <li> ALTER TABLE to add a required field to a table with a default value.   </li>
/// <li> ALTER TABLE to modify a field to be required.</li>
/// </ul>
/// Deferred Compilation Mode should only be used in an installation-type setting where only a single process is working on the namespace at the time.
/// <p><i>Notes
/// <ul>
/// <li>Changing this setting will take effect immediately for all processes in this namespace.</li>
/// <li>This setting is not related to the macro compiler directive #SQLCompile Mode = { deferred | embedded | immediate }</li>
/// </ul></i>
/// <b><i>CompileModeImmediate</i></b> - Set the namespace wide flag which turns on Immediate Compilation mode. Immediate Compile Mode is the default compilation mode. If there are
/// pending compilations when switching from Deferred/Install Compile Mode, they will be compiled immediately.
/// <p><i>Notes
/// <ul>
/// <li>Changing this setting will take effect immediately for all processes in this namespace.</li>
/// <li>This setting is not related to the macro compiler directive #SQLCompile Mode = { deferred | embedded | immediate }</li>
/// </ul></i>
/// <b><i>CompileModeInstall</i></b> - Set the namespace wide flag which turns on Install Compilation mode. This mode should only be used for installation procedures where no data
/// exists for any of the tables being created. If data exists for the tables definitions being manipulated through DDL statement, use
/// Deferred Compile Mode instead.
/// This is very useful during loading of DDL scripts of the following format:<br>
///   - CREATE TABLE MyTable ...<br>
///   - CREATE INDEX MyIndex1 ON MyTable ...<br>
///   - CREATE INDEX MyIndex2 ON MyTable ...<br>
///   - CREATE INDEX MyIndex3 ON MyTable ...<br>
///   - CREATE INDEX MyIndex4 ON MyTable ...<br>
///   - CREATE INDEX MyIndex5 ON MyTable ...<br>
///   - CREATE TABLE MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex1 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex2 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex3 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex4 ON MyOtherTable ...<br>
///   - CREATE INDEX MyOtherIndex5 ON MyOtherTable ...<br>
///   - ALTER TABLE MyOtherTable ADD FOREIGN KEY MyFKey (MyField) REFERENCES MyTable(MyField)<br>
///   - INSERT INTO MyTable ...<br>
/// Running with Install Compilation Mode off would require 13 class compilations for the sequence above.  
/// With Install Compilation Mode on, only one class compilation is required.  
/// Classes MyTable and MyOtherTable are compiled when the INSERT statement is encountered.
/// Changing from Install to Immediate Compilation Mode will cause any classes in the Deferred Compile Queue to be compiled immediately.  
/// If all class compilations were successful, SQLCODE will return 0.  If there were any errors, SQLCODE will equal -400.  
/// Class compilation errors are logged in the ^mtemp2($namespace,"Deferred Compile Mode","Error").  
/// If SQLCODE=-400 you should view this global structure for more precise error messages.
/// When in Install Compilation Mode, any of the following actions will trigger the classes in the Deferred Compilation Queue to be immediately compiled:
/// <ul>
/// <li> Switch back to immediate compile mode. </li>
/// <li> An xDBC Catalog query is called. </li>
/// <li> A DML statement is issued (INSERT, SELECT, GRANT, etc) </li>
/// </ul>
/// Install Compilation Mode should only be used in an installation-type setting where only a single process is working on the namespace at the time and there is no data in the tables.
/// <p><i>Notes
/// <ul>
/// <li>Changing this setting will take effect immediately for all processes in this namespace.</li>
/// <li>This setting is not related to the macro compiler directive #SQLCompile Mode = { deferred | embedded | immediate }</li>
/// </ul></i>
/// <b><i>CompileModeNocheck</i></b> - Set the namespace wide flag which turns on Nocheck Compilation mode. This mode is the same as immediate mode except that existing data is not
/// validated against new constraints. For example, if you add a unique constraint to a table that already has data, Nocheck mode will not validate that
/// the constraint is valid. This compile mode must be used with extreme caution. You could end up with data integrity problems in your application.
/// In NOCHECK compile mode, the following constraints are not checked when executing DDL statements:
/// <ul>
/// <li>If a table is dropped, there are no checks to see if any foreign key constraints in other tables reference this table.</li>
/// <li>If a foreign key constraint is added, there are no checks to see if any existing data in the table is valid for the foreign key.</li>
/// <li>If a NOT NULL constraint is added to a table with existing data, there is no validation that any existing rows are NOT NULL, nor is there an update of existing rows to assign the field's default value if there is one.</li>
/// <li>If a UNIQUE or Primary key constraint is deleted, there is no check to see if a foreign key in this or another table had referenced the key.</li>
/// </ul>
/// Otherwise, the mode behaves the same as immediate.  There is no deferring of class compilations and indices are built when created.
/// - Changing this setting will take effect immediately for all processes in this namespace.</i>
/// - This setting is not related to the macro compiler directive #SQLCompile Mode = { deferred | embedded | immediate }<br>
/// <p><i>Notes
/// <ul>
/// <li>Changing this setting will take effect immediately for all processes in this namespace.</li>
/// <li>This setting is not related to the macro compiler directive #SQLCompile Mode = { deferred | embedded | immediate }</li>
/// </ul></i>
/// <b><i>DDLDefineBitmapExtent</i></b> - Sets the flag which determines if a class created by a DDL CREATE TABLE statement defines a bitmap extent index for the class.  This setting only applies to classes created through DDL that do not also define an explicit IDKey index.
/// <ul>
/// <li><i>pValue</i> = 0,  Do not define a Bitmap Extent index for a table created through DDL.</li>
/// <li><i>pValue</i> = 1,  Automatically define a Bitmap Extent index for tables created through DDL (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>DDLDropTabDelData</i></b> - Sets the flag which determines if a DDL DROP TABLE statement deletes the table's data.
/// <ul>
/// <li><i>pValue</i> = 0,  DROP TABLE will not delete the table's data when the table is dropped</li>
/// <li><i>pValue</i> = 1,  DROP TABLE will delete the table's data when the table is dropped (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>DDLFinal</i></b> - Sets the flag which determines if a class created by a DDL CREATE TABLE statement is Final.
/// <ul>
/// <li><i>pValue</i> = 0,  CREATE TABLE will not define a class as Final</li>
/// <li><i>pValue</i> = 1,  CREATE TABLE will define a class as Final (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// <li> Temporary tables are always defined as Final, regardless of this setting.</li>
/// </ul></i>
/// <b><i>DDLPKeyNotIDKey</i></b> - Set configuration setting for PRIMARY KEY in DDL also being the IDKey index. This configuration setting determines if a primary key constraint, specified through DDL, also becomes
/// the IDKey index in the class definition.  Having the primary key index also be an IDKey index generally gives better performance, but it means the Primary key fields cannot be updated.
/// <ul>
/// <li><i>pValue</i> = 0,  Primary Key constraints will also become IDKey indices</li>
/// <li><i>pValue</i> = 1,  Primary Key constraints will NOT become IDKey indices (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul></i>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul>
/// <b><i>DDLUseExtentSet</i></b> - Sets the flag which determines if a class created by a DDL CREATE TABLE statement defines the USEEXTENTSET class parameter to a value of 1.
/// USEEXTENTSET=1 will generally bind the table to global names that allow for better performance when running queries against the table, especially when the index globals are used.  It does mean the global names the class is mapped to are not names that attempt to match the classname.
/// See documentation for USEEXTENTSET parameter for more information.
/// <ul>
/// <li><i>pValue</i> = 0,  CREATE TABLE will define the USEEXTENTSET class parameter with a value of 0</li>
/// <li><i>pValue</i> = 1,  CREATE TABLE will define the USEEXTENTSET class parameter with a value of 1 (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>DDLUseSequence</i></b> - Sets the flag which determines if a class created by a DDL CREATE TABLE statement uses $Sequence for ID assignment.
/// The storage keyword IDFUNCTION can be defined as INCREMENT or SEQUENCE. This keyword value is used by the class compiler to determine 
/// which system function - $increment or $sequence - is to be used for assigning new ID values for a persistent class using default storage.
/// The default value for IDFUNCTION is INCREMENT, however, the default behavior for classes defined through DDL is to define IDFUNCTION as SEQUENCE.
/// <ul>
/// <li><i>pValue</i> = 0,  CREATE TABLE uses $Increment for ID assignment</li>
/// <li><i>pValue</i> = 1,  CREATE TABLE uses $Sequence for ID assignment (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>DefaultTimePrecision</i></b> - Set the Default precision for the Time component of the value returned by the GETDATE(), CURRENT_TIME, and CURRENT_TIMESTAMP SQL Scalar functions.
/// Input precision to <i>pValue</i>, the number of decimal places for the millisecond portion of the time value. The default is 0, milliseconds are not returned in the values returned by the GETDATE(), CURRENT_TIME, and CURRENT_TIMESTAMP functions.
/// <p>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul>
/// <b><i>DelimitedIdentifiers</i></b> - Set the configuration setting which determines if double quote ("") in an SQL statement is used for delimited
/// (quoted) identifiers or string constants.
/// <ul>
/// <li><i>pValue</i> = 0,  In an SQL statement, "..." is treated as a string literal</li>
/// <li><i>pValue</i> = 1,  In an SQL statement, "..." is treated as an identifier (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>ECPSync</i></b> - Defines whether or not SQL SELECT statements perform a $SYSTEM.ECP.Sync() call in the OPEN code.
/// <ul>
/// <li><i>pValue</i> = 0,  Do not perform ECP Syncs for Select queries (Default)</li>
/// <li><i>pValue</i> = 1,  Perform ECP Syncs for Select queries</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>FastDistinct</i></b> - Defines whether or not SQL DISTINCT is optimized to use indexes.
/// If true (the default) many SQL queries involving DISTINCT (and GROUP BY) will run much more efficiently by making better use of indices (if available). 
/// The downside of this is that the values returned by such queries will be collated in the same way they are stored within the index (i.e., results may be in uppercase). Some applications care about the case of values returned by such queries. If "Fast DISTINCT" is set to false (0), the 
/// SQL will revert to the use of uncollated values with regards to DISTINCT behavior.
/// <ul>
/// <li><i>pValue</i> = 0,  DISTINCT optimization is turned OFF</li>
/// <li><i>pValue</i> = 1,  DISTINCT optimization is turned ON (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>FilerRefIntegrity</i></b> - Set the configuration setting which determines if Foreign Key Referential Integrity checks are performed in the SQL Filer. Turning off SQL Filer Referential Integrity checking will suppress any SQLCODE -121, -122, -123, and -124 errors.
/// <ul>
/// <li><i>pValue</i> = 0,  Foreign Key Referential Integrity checks are not performed</li>
/// <li><i>pValue</i> = 1,  Foreign Key Referential Integrity checks are performed (Default)</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>IdentityInsert</i></b> - Set the IDENTITY_INSERT option for this process. IDENTITY_INSERT controls the ability of the user to specify a value for the IDENTITY property when saving a new object, 
/// a value for the IDENTITY column, or an explicit ROWID value in an SQL INSERT. If IDENTITY_INSERT is false and the user specifies an explicit IDENTITY or ROWID value when saving a new object (ObjectScript)
/// or inserting a new ROW (SQL) then an error condition is reported.
/// <ul>
/// <li><i>pValue</i> = 0,  Insert/%Save of Identity field/property is not permitted (Default)</li>
/// <li><i>pValue</i> = 1,  Insert/%Save of Identity field/property is permitted</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately and lasts for the duration of the process or until $SYSTEM.SQL.Util.SetOption("IdentityInsert",pValue) is called again.</li>
/// <li> This is a per-process setting.</li>
/// </ul></i>
/// <b><i>IsolationMode</i></b> - Set the Transaction Isolation Mode for this process. 
/// The ISOLATION MODE options permit you to specify whether or not uncommitted changes to the database should be available for read access by a SELECT query. 
/// The READ COMMITTED option states that only those changes that have been committed are available for query access. If requested data has been changed, 
/// but the changes have not been committed (or rolled back), the query waits for transaction completion. 
/// If a lock timeout occurs while waiting for this data to be available, an SQLCODE error is issued. 
/// The READ UNCOMMITTED option states that all changes are immediately available for query access.
/// The READ VERIFIED option states that all changes are immediately available for query access, but with additional checks to skip rows containing
/// changed data that no longer match the conditions specified in the query.
/// <ul>
/// <li><i>pValue</i> = 0,  Read uncommitted (Default)</li>
/// <li><i>pValue</i> = 1,  Read committed</li>
/// <li><i>pValue</i> = 3,  Read verified</li>
/// </ul>
/// <p><i>Notes</i>
/// <ul>
/// <li> Changing this configuration setting takes effect immediately and lasts for the duration of the process or until $SYSTEM.SQL.Util.SetOption("IsolationMode",pValue) is called again.</li>
/// <li> This is a per-process setting.</li>
/// </ul></i>
/// <b><i>LockThreshold</i></b> - Set the Lock Threshold for locks acquired during filing of rows within a single transaction.
/// <ul>
/// <li><i>pValue</i> = the number of row locks to acquire before escalating to a table lock. The default is 1000</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>LockTimeout</i></b> - Set the Lock timeout for locks acquired during the execution of SQL statements.
/// <ul>
/// <li><i>pValue</i> = the number of seconds to set the lock timeout to. The default is 10 seconds.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>ProcessLockTimeout</i></b> - Set the Lock Timeout for locks made during the execution of SQL statements for this process.
/// <ul>
/// <li><i>pValue</i> = the number of seconds to set the lock timeout to. The default is 10 seconds.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately and lasts for the duration of the process or until $SYSTEM.SQL.Util.SetOption("ProcessLockTimeout",pValue) is called again.</li>
/// <li> This is a per-process setting.</li>
/// </ul></i>
/// <b><i>ParameterSampling</i></b> - Set the configuration setting which determines if parameter sampling is enabled
/// <ul></i>
/// <li><i>pValue</i> = 0, disable parameter sampling.</li>
/// <li><i>pValue</i> = 1, enable parameter sampling.</li>
/// </ul>
/// <p>Notes<i>
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>QueryProcedures</i></b> - Defines whether or not all class queries project as SQL Stored Procedures regardless of the query's SQLProc value.
/// <ul>
/// <li><i>pValue</i> = 0, only class queries with SQLProc = TRUE are projected as stored procedures (Default).</li>
/// <li><i>pValue</i> = 1, all class queries are projected as stored procedures.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>RetainSQL</i></b> - Set the configuration setting which determines if embedded SQL statements are retained as comments in the .INT
/// code version of the routine.
/// <ul></i>
/// <li><i>pValue</i> = 0, SQL text will be not retained as comments in the .INT code.</li>
/// <li><i>pValue</i> = 1, SQL text will be retained as comments in the INT code (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>RTPC</i></b> - Set the configuration setting which determines if Run Time Plan Choice is applied.
/// <ul>
/// <li><i>pValue</i> = 0, do not apply Run Time Plan Choice in SQL statements.</li>
/// <li><i>pValue</i> = 1, apply Run Time Plan Choice in SQL statements (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will affect all processes immediately.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>SQLFunctionArgConversion</i></b> - Set the system wide flag for controlling if SQL Functions perform ODBCToLogical/DisplayToLogical on SQL Function input arguments.
/// <ul>
/// <li><i>pValue</i> = 0, SQL will not convert input arguments for SQL Functions from ODBC/Display to Logical format (Default).</li>
/// <li><i>pValue</i> = 1, SQL will convert input arguments for SQL Functions from ODBC/Display to Logical format if needed.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately for all new compilations/prepares of SQL statements.</li>
/// <li> Change does not affect already compiled statements or cached dynamic statements compiled with the previous value.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>SQLSecurity</i></b> - Set the configuration setting which determines if SQL security is enabled. 
/// If SQL security is ON, all SQL security is active. This means privilege-based table/view security is active. A user may only perform actions on a table or view they have been granted privilege for.
/// If SQL security is OFF, SQL security is inactive. This means privilege-based table/view security is suppressed. A user may perform actions on a table or view even if they have not been granted privileges to do so.
/// <ul>
/// <li><i>pValue</i> = 0, SQL security is OFF.</li>
/// <li><i>pValue</i> = 1, SQL security is ON (Default).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>SelectMode</i></b> - Set the select mode for this process.<br>
/// The select mode set by this API is used when <b><i>#SQLCompile Select = Runtime</i></b> is specified for the compiled SQL code.
/// When the SQL statement is compiled in Runtime mode, the mode specified by <i>SetSelectMode</i> will be used at runtime to determine whether Logical(0), ODBC(1), or Display(2) mode is used for the statement. 
/// See the documentation for <i>#SQLCompile Select</i> for more information.<br>
/// <ul>
/// <li><i>pValue</i> = 0, Logical mode.</li>
/// <li><i>pValue</i> = 1, ODBC mode.</li>
/// <li><i>pValue</i> = 2, Display mode.</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately and lasts for the duration of the process or until $SYSTEM.SQL.Util.SetOption("SelectMode",pValue) is called again.</li>
/// <li> This is a per-process setting.</li>
/// </ul></i>
/// <b><i>ServerDisconnectCode</i></b> - Define ODBC/JDBC disconnect code.
/// Upon disconnect, any ObjectScript code defined in this setting will be executed immediately before the server process Halts.  This code will also attempt to be executed anytime the server process 
/// encounters an unrecoverable error that causes the server process to Halt. It will not be executed if the server process encounters a Halt in other user defined code, 
/// if the process crashes, if the process is stopped, or InterSystems IRIS is stopped or forced down.
/// <ul>
/// <li><i>pValue</i> = a single line of ObjectScript to be executed. Call with <i>pValue</i>="" or <i>undefined</i> to delete the disconnect code for this namespace</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately for all server processes in InterSystems IRIS after this function is called.</li>
/// <li> Any existing processes will execute the server disconnect code disconnection.</li>
/// <li> The disconnect code is defined on a per-namespace basis.</li>
/// </ul></i>
/// <b><i>ServerInitCode</i></b> - Returns ODBC/JDBC/SQL Manager initialization code.
/// This Initialization code is executed at login time when connecting to SQL through ODBC, JDBC, or the SQL Manager. 
/// <ul>
/// <li><i>pValue</i> = a single line of ObjectScript to be executed when connecting to this namespace. Call with <i>pValue</i>="" or <i>undefined</i> to delete connect code for this namespace</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> Changing this configuration setting takes effect immediately for all new connections.</li>
/// <li> The connect code is defined on a per-namespace basis.</li>
/// </ul></i>
/// <b><i>TCPKeepAlive</i></b> - Set the TCP Keep Alive interval for xDBC connections.
/// <ul>
/// <li><i>pValue</i> = the number of seconds to set the TCP Keep Alive interval to.  The default is 300 seconds (5 minutes).</li>
/// </ul>
/// <p><i>Notes
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
/// <b><i>ToDateDefaultFormat</i></b> - Gets the default format for the SQL TO_DATE() function.
/// <ul>
/// <li><i>pValue</i> = a string value with the default format the TO_DATE function will return.</li>
/// </ul>
/// <p>Notes<i>
/// <ul>
/// <li> You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.</li>
/// <li> Changing this configuration setting will only take effect for this process and new processes starting in InterSystems IRIS after this function is called. Any existing processes will still use the old setting.</li>
/// <li> This is a system-wide setting.</li>
/// </ul></i>
ClassMethod SetOption(pOption As %String, pValue As %String = "", ByRef oldValue As %String) As %Status [ ProcedureBlock = 1, SqlProc ]
{
	set st=$$$OK,oldValue=""
	set option=$$$UPPER(pOption)
	if option="ADAPTIVEMODE" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetAdaptiveMode^%apiSQL(''pValue,.oldValue)
	}
	elseif option="ALLOWEXTRINSICFUNCTIONS" { 
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set:pValue="" pValue=1
		return $$SetAllowExtrinsicFunctions^%apiSQL(''pValue,.oldValue) 
	}
	elseif option="ANSIPRECEDENCE" { 
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set:pValue="" pValue=1
		return $$SetANSIPrecedence^%apiSQL(''pValue,.oldValue) 
	} 
	elseif option="AUTOCOMMIT" { 
		set:pValue="" pValue=0
		if '$Find("|0|1|2",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1|2") }
		set oldValue=$zu(115,1)
		do SetAutoCommit^%apiSQL(pValue)
	}
	elseif option="AUTOPARALLEL" { 
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set:pValue="" pValue=1
		return $$SetAutoParallel^%apiSQL(''pValue,.oldValue) 
	} 
	elseif option="AUTOPARALLELTHRESHOLD" { 
		set:pValue="" pValue=3200
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetAutoParallelThreshold^%apiSQL(pValue,.oldValue) 
	} 
	elseif option="BITMAPFRIENDLYCHECK" { 
		set:pValue="" pValue=0
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetBitmapFriendlyCheck^%apiSQL(pValue,.oldValue) 
	} 
	elseif option="CACHEDQUERYLOCKTIMEOUT" {
		set:pValue="" pValue=120
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetCachedQueryLockTimeout^%apiSQL(pValue,.oldValue) 
	} 
	elseif option="CACHEDQUERYSAVESOURCE" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set:pValue="" pValue=0
		return $$SetCachedQuerySaveSource^%apiSQL(''$g(pValue),.oldValue)
	}
	elseif option="COLLECTIONPROJECTION" { 
		set:pValue="" pValue=0
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set oldValue = $$$CollectionProjectionGet
		$$$CollectionProjectionSet(pValue)
		return st
	}
	elseif option="COMPILEMODEDEFERRED" { do SetCompileModeDeferred^%apiSQL }
	elseif option="COMPILEMODEIMMEDIATE" { do SetCompileModeImmediate^%apiSQL }
	elseif option="COMPILEMODEINSTALL" { do SetCompileModeInstall^%apiSQL }
	elseif option="COMPILEMODENOCHECK" { do SetCompileModeNocheck^%apiSQL }
	elseif option="DDLDEFINEBITMAPEXTENT" { 
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		try {
			set oldValue=$$$GetDDLDefineBitmapExtent
			s st=$$$SetDDLDefineBitmapExtent(''pValue)
			if $$$ISERR(st) { return st }
		}
		catch {
			return $$$ERROR($$$GeneralError,"Error encountered in ##class(%SQL.Util).SetOption for DDLDefineBitmapExtent: "_$ze)
		}
	}
	elseif option="DDLDROPTABDELDATA" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetDDLDropTabDelData^%apiSQL(''pValue,.oldValue)
	}
	elseif option="DDLFINAL" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		try {
			set oldValue=$$$GetDDLFinal
			set st=$$$SetDDLFinal(''$g(pValue))
			if $$$ISERR(st) { return st }
		}
		catch {
			return $$$ERROR($$$GeneralError,"Error encountered in ##class(%SQL.Util).SetOption for DDLFinal: "_$ze)
		}
	}
	elseif option="DDLPKEYNOTIDKEY" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetDDLPKeyNotIDKey^%apiSQL(''pValue,.oldValue)
	}
	elseif option="DDLUSEEXTENTSET" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		try {
			set oldValue=$$$GetDDLUseExtentSet
			set st=$$$SetDDLUseExtentSet(''pValue)
			if $$$ISERR(st) { return st }
		}
		catch {
			return $$$ERROR($$$GeneralError,"Error encountered in ##class(%SQL.Util).SetOption for DDLUseExtentSet: "_$ze)
		}
	}
	elseif option="DDLUSESEQUENCE" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		try {
			set oldValue=$$$GetDDLUseSequence
			set st=$$$SetDDLUseSequence(''pValue)
			if $$$ISERR(st) { return st }
		}
		catch {
			return $$$ERROR($$$GeneralError,"Error encountered in ##class(%SQL.Util).SetOption for DDLUseSequence: "_$ze)
		}
	}
	elseif option="DEFAULTTIMEPRECISION" {
		set:pValue="" pValue=0
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetDefaultTimePrecision^%apiSQL(pValue,.oldValue)
	}
	elseif option="DELIMITEDIDENTIFIERS" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetDelimitedIdentifiers^%apiSQL(''pValue,.oldValue)
	}
	elseif option="ECPSYNC" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetECPSync^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="FASTDISTINCT" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetFastDistinct^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="FILERREFINTEGRITY" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetFilerRefIntegrity^%apiSQL(''pValue,.oldValue)
	}
	elseif option="IDENTITYINSERT" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		set oldValue = $zu(115,11,pValue)
		return st
	}
	elseif option="ISOLATIONMODE" {
		if '$Find("|0|1|3",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1|3") }
		set oldValue = $zu(115,2,pValue)
		return st
	}
	elseif option="LOCKTHRESHOLD" {
		set:pValue="" pValue=$$$DefaultLockThreshold
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetLockThreshold^%apiSQL(pValue,.oldValue)
	}
	elseif option="LOCKTIMEOUT" {
		set:pValue="" pValue=10
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetLockTimeout^%apiSQL(pValue,.oldValue)
	}
	elseif option="PROCESSLOCKTIMEOUT" {
		set:pValue="" pValue=10
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		set oldValue = $zu(115,4,pValue)
		return st
	}
	elseif option="PARAMETERSAMPLING" {
		set:pValue="" pValue=0
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetParameterSampling^%apiSQL(''pValue,.oldValue)
	}
	elseif option="QUERYPROCEDURES" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetQueryProcedures^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="RTPC" { 
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetRTPC^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="RETAINSQL" {
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetRetainSQL^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="SQLFUNCTIONARGCONVERSION" {
		set:pValue="" pValue=1
		try {
			set oldValue=$$$SQLFunctionArgConversionG
			if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
			set $$$SQLFunctionArgConversion=pValue
		} catch {
			return $$$ERROR($$$GeneralError,"Error encountered in ##class(%SQL.Util).SetOption for SQLFunctionArgConversion: "_$ze)
		}
	}
	elseif option="SQLSECURITY" {
		set:pValue="" pValue=1
		if '$Find("|0|1",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1") }
		return $$SetSQLSecurity^%apiSQL(''$get(pValue),.oldValue)
	}
	elseif option="SELECTMODE" { 
		set:pValue="" pValue=1
		if '$Find("|0|1|2",pValue) { return $$$ERROR($$$DTValueList,pValue,"0|1|2") }
		set oldValue = $zu(115,5,pValue)
		return st
	}
	elseif option="SERVERDISCONNECTCODE" {
		do SetServerDisconnectCode^%apiSQL($get(pValue))
	}
	elseif option="SERVERINITCODE" { 
		do SetServerInitCode^%apiSQL($get(pValue))
	}
	elseif option="TCPKEEPALIVE" {
		set:pValue="" pValue=300
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetTCPKeepAlive^%apiSQL(pValue,.oldValue)
	}
	elseif option="TODATEDEFAULTFORMAT" {
		return $$SetToDateDefaultFormat^%apiSQL($get(pValue),.oldValue)
	}
	elseif option="CLIENTMAXIDLETIME" {
		set:pValue="" pValue=0
		if '$isvalidnum(pValue) { return $$$ERROR($$$DTNotNum,pValue) }
		if '$isvalidnum(pValue,,0) { return $$$ERROR($$$DTMinVal,pValue,0) }
		return $$SetClientMaxIdleTime^%apiSQL($get(pValue),.oldValue)
	}
	else { return $$$ERROR($$$GeneralError, "Error: Invalid option name: "_pOption) }
	return $$$OK
}

/// Sets the DDL Identifier Translation mappings configuration settings.<br>
/// This is for filtering/modifying valid SQL identifier characters when translating SQL identifiers into Objects identifiers.
/// When converting an SQL identifier to an Objects Identifier at DDL run time, the characters in the 'from' list will be converted
/// to the characters in the 'to' list. This is done through the ObjectScript $Translate function.<br>
/// For example:<br>
/// <dd>SQL Table name = "My Table!"<br>
/// <dd>from = '"! '<br>
/// <dd>to = ''<br>
/// <dd>Class name = $Translate("My Table!",from,to) = MyTable<br>
/// <br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>from</i>
/// <dd>A string of characters to translate from
/// <dt><i>to</i>
/// <dd>A string of characters to translate to (by position in the string) Optional. Default is "".
/// <dt><i>oldfrom</i>
/// <dd>Passed By Reference. Contains the previous value of the 'from' setting
/// <dt><i>oldto</i>
/// <dd>Passed By Reference. Contains the previous value of the 'to' setting
/// </dl>
/// <b>Returns:</b>
/// <dl>
/// <dd>%Status
/// </dl>
/// <i><b>NOTES:</b><dd> - You must have the "USE" permission on the %Admin_Manage Resource in order to change this configuration setting.
/// <dd> - Changing this configuration setting will affect all processes immediately.
/// <dd> - This is a system-wide setting.</i>
ClassMethod SetDDLIdentifierTranslations(from As %Library.String, to As %Library.String = "", ByRef oldfrom As %Library.String, ByRef oldto As %Library.String) As %Status
{
	QUIT $$SetDDLIdentifierTranslations^%apiSQL(from,to,.oldfrom,.oldto)
}

/// This entrypoint is used to make an SQL Map definition [not] selectable to the SQL Query Optimizer
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>pTablename</i>
/// <dd>Name of the table to check.<br>
/// <i>pTablename</i> can be qualified or unqualified.  If unqualified, the default schema is applied.
/// <dt><i>pMapname</i>
/// <dd>Name of the SQL Map(s) in the table to make selectable or not selectable. This can be a comma delimited string list of maps (e.g. "map1" or "map1,map2,map3" or $listtostring($lb("map1","map2"))) or a list of maps (e.g. $lb("map1") or $lb("map1","map2") or $listfromstring("map1,map2,map3")).<br>
/// <dt><i>pValue</i>
/// <dd>1/0 flag.  1 means make this map Selectable - the SQL Query Optimizer will be able to choose this map.  0 means make this map Not Selectable - the SQL Query Optimizer will NOT be able to consider this map<br>
/// </dl>
/// <p><b>Returns:</b>
/// <ul>A %Status indicating whether the operation was successful</ul>
/// <p><b>Notes:</b><ul>This feature is not useful for extent indices (non bitmap).  When a non-bitmap extent index is defined, the data map projected to SQL will use both the extent index global and the data map global.  
/// When a non-bitmap extent index is added to a table with existing data, the index must be populated before any queries are run against the table.  If not, any queries plans that loop over the data map will return no data.</ul>
/// <ul>There is no check to see if the table and/or map exists.  This is so the selectability of the map can be defined for a table/map that does not yet exist.</ul>
/// <ul>This feature sets the selectability for the map in the current namespace only.  If this table is mapped to multiple namespaces, and the index needs to be built in each namespace, SetMapSelectability should be called in each namespace the index is to be built in.</ul>
/// <ul>Also, this feature sets the selectability for the map in the current table only.  If there is a subclass that inherits the index map, and the index is being rebuilt for the entire extent, SetMapSelectability should be called for each table/map in the extent.</ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Util.SetMapSelectability("Sample.Person","NameIdx",1) // SQL Query Optimizer WILL consider map NameIdx</li>
/// <li>Write $SYSTEM.SQL.Util.SetMapSelectability("Sample.Person","NameIdx",0) // SQL Query Optimizer WILL NOT consider map NameIdx</li>
/// <li>Write $SYSTEM.SQL.Util.SetMapSelectability("Sample.Person",$lb("NameIdx","SSNKey"),1) // SQL Query Optimizer WILL consider maps NameIdx or SSNKey</li>
/// <li>Write $SYSTEM.SQL.Util.SetMapSelectability("Sample.Person","NameIdx,SSNKey",0) // SQL Query Optimizer WILL NOT consider maps NameIdx or SSNKey</li>
/// </ul>
ClassMethod SetMapSelectability(pTablename As %Library.String = "", pMapname As %Library.String = "", pValue As %Boolean = "") As %Status [ ProcedureBlock = 1 ]
{
	QUIT:pTablename="" $$$ERROR($$$GeneralError,"pTablename argument missing")
	QUIT:pMapname="" $$$ERROR($$$GeneralError,"pMapname argument missing")
	set tTablename=$$IntQualifiedName^%apiSQL(pTablename)
	QUIT:tTablename="" $$$ERROR($$$GeneralError,"Unable to determine Schema.Table from given pTablename value ("_pTablename_")")
	set tSchema=$$$SchemaFromIQN(tTablename)
	QUIT:tSchema="" $$$ERROR($$$GeneralError,"Unable to determine Schema name from given pTablename value ("_pTablename_")")
	set tTable=$$$TableFromIQN(tTablename)
	QUIT:tTable="" $$$ERROR($$$GeneralError,"Unable to determine Table name from given pTablename value ("_pTablename_")")
	do PurgeForTable^%apiSQL(tTablename) //purge all cached queries when the selectability is updated
	set mapList=$$$UPPER(pMapname)
	set:'$listvalid(mapList) mapList=$listfromstring(mapList)
	set ptr=0
	while $listnext(mapList,ptr,map) {
		continue:$get(map)=""
		if pValue=0 { set ^rINDEXEXT("MS",tSchema,tTable,map)="" }
		if pValue=1 {
			kill ^rINDEXEXT("MS",tSchema,tTable,map)
			if $d(^oddSQL(tSchema,tTable,"MS",map,$namespace)) kill ^oddSQL(tSchema,tTable,"MS",map,$namespace)
		}
	}
	QUIT $$$OK
}

/// This entrypoint is used define an xDBC Server process connection limit
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>limit</i>
/// <dd>An integer value for the number of xDBC connections to allow for this instance.<br>
/// <p><b>Returns:</b>
/// <ul>A %Status indicating whether the operation was successful</ul>
/// <p><b>Notes:</b><ul>This feature allows a system administrator to limit the number of xDBC connections for this instance.
/// When set to a value greater than -1, the value will determine how many xDBC connections can be made.
/// Setting the value to -1 allows as many collections supported by the license.
/// Connections for users holding the %Admin_Operate:"U" resource are never restricted from connection, but they do count against the limit.</ul>
/// Users must have the %Admin_Operator:"U" resource in order to call this API
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set status=$SYSTEM.SQL.Util.SetXDBCConnectionLimit(50) // Allow 50 simultaneous xDBC connections to instance</li>
/// <li>Set status=$SYSTEM.SQL.Util.SetXDBCConnectionLimit(-1) // No restrictions for simultaneous xDBC connections to instance</li>
/// </ul>
ClassMethod SetXDBCConnectionLimit(limit As %Library.Integer = "") As %Status [ ProcedureBlock = 1 ]
{
	if '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) { RETURN $$$ERROR($$$GeneralError,"User is not privileged for this API") }
	RETURN:limit="" $$$ERROR($$$GeneralError,"limit argument missing")
	if '$isvalidnum(limit) || (limit<-1) || (limit>2147483647) { RETURN $$$ERROR($$$GeneralError,"limit must be a value between -1 and 2147483647") }
	set ^%SYS("sql","server","connection limit")=limit
	RETURN $$$OK
}

/// This entrypoint returns the current setting for xDBC Server process connection limit.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <p><b>Returns:</b>
/// <ul>An %Integer value of the current xDBC connection limit setting for this instance</ul>
/// <p><b>Notes:</b><ul>A value of -1 or "" means no connection limit is currently defined for this instance.
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set limit=$SYSTEM.SQL.Util.GetXDBCConnectionLimit()
/// </ul>
ClassMethod GetXDBCConnectionLimit() As %Integer [ ProcedureBlock = 1 ]
{
	RETURN $g(^%SYS("sql","server","connection limit"))
}

/// This entrypoint returns the current default collation name for %Library.String datatype in current namespace
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <p><b>Returns:</b>
/// <ul>the current default collation name for %Library.String datatype</ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set coll=$SYSTEM.SQL.Util.GetDefaultCollation() // get current default collation name for %Library.String datatype in current namespace
/// </ul>
ClassMethod GetDefaultCollation() As %String [ ProcedureBlock = 1 ]
{
 	set collation=""
	d GetEnvironment^%apiOBJ($$$cENVcollation,"%Library.String",.collation)
	RETURN collation
}

/// This entrypoint is used set the default collation for %Library.String datatype
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>newValue</i>
/// <dd>new default collation name, such as "SQLUPPER"<br>
/// <dt><i>systemWide</i>
/// <dd>1/0 flag.  1 means set this default collation for %Library.String datatype system wide.  0 means set this default collation for %Library.String datatype for current namespace.<br>
/// </dl>
/// <b>Output:</b>
/// <dl>
/// <dt><i>outValue</i>
/// <dd>the current (before change to newValue) default collation name for %Library.String datatype<br>
/// </dl>
/// <p><b>Returns:</b>
/// <ul>A %Status indicating whether the operation was successful</ul>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Set status=$SYSTEM.SQL.Util.SetDefaultCollation("SQLSTRING",1,.oldValue) // set default collation for %Library.String datatype to SQLSTRING systemwide</li>
/// </ul>
ClassMethod SetDefaultCollation(newValue As %String = "", systemWide As %Boolean = 0, Output oldValue As %String = "") As %Status [ ProcedureBlock = 1 ]
{
 	d GetEnvironment^%apiOBJ($$$cENVcollation,"%Library.String",.oldValue)
	if systemWide{
		RETURN $$SetAllEnvironment^%apiOBJ($$$cENVcollation,"%Library.String",newValue)
	} else{
		RETURN $$SetEnvironment^%apiOBJ($$$cENVcollation,"%Library.String",newValue)
	}
	RETURN $$$OK
}

}
