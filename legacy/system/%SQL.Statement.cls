/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occCPT, %SYS.DBSRV, %BigData.ShardingManager)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25SQL.Statement">Using Dynamic SQL</a>.</p>
/// <p>The sample class mentioned here (Sample.Person) is part of <a target="_top" href="https://github.com/intersystems/Samples-Data">https://github.com/intersystems/Samples-Data.</a>
/// See <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=landing+githubsamples">Downloading Samples</a>.</p>
/// <p><class>%SQL.Statement</class> implements an interface to prepare and execute dynamic SQL statements. </p>
/// <h2>Dynamic SQL</h2>
/// <p>The %SQL.Statement class implements an interface for managing dynamic SQL statements. The interface consists of the
/// <method>%Prepare</method>, <method>%Execute</method>, <method>%ExecDirect</method> methods and the 
/// <property>%Dialect</property>, <property>%Metadata</property>, <property>%SchemaPath</property>, and <property>%SelectMode</property> properties.
/// </p>
/// <p>To prepare and execute a dynamic SQL statement, use an instance of %SQL.Statement, such as:
/// </p>
/// <example>
///  set tStatement = ##class(%SQL.Statement).%New(2,"Sample")
/// </example>
/// <p><method>%New</method> accepts three optional parameters as follows:</br></br>
/// %New(selectmode,schemapath,dialect) where <i>selectmode</i> is one of the allowed values of the %SelectMode property of this class, <i>schemapath</i> is one of the allowed values of the %SchemaPath property of this class, and <i>dialect</i> is one of the allowed values of the %Dialect property of this class.</br></br>
/// You can explicitly set these properties at any time; the value of each affects subsequent statement preparation and execution.
/// </p>
/// <p>Next, prepare the dynamic statement by invoking the <method>%Prepare</method> method. %Prepare() accepts an SQL statement in the form of a simple value or in an array passed by reference. For an array, the value of the base node is the number of lines in the array and each node&rsquo;s subscript specifies its line number; the value of each subnode is a portion of the SQL statement. An example of preparing an array is:
/// </p>
/// <example>
///  set tSQL = 3
///  set tSQL(1) = "select %ID as id, Name, DOB, Home_State"
///  set tSQL(2) = "from Person where Age > 80"
///  set tSQL(3) = "order by 2"
///  set tStatus = tStatement.%Prepare(.tSQL)
/// </example>
/// <p><method>%Prepare</method> returns a status value that indicates success or failure. If the statement is successfully prepared, the next step is to execute it by invoking the <method>%Execute</method> method.
/// </p>
/// <example>
///  set tResult = tStatement.%Execute()
/// </example>
/// <p>The <method>%Execute</method> method returns an instance of the <class>%SQL.StatementResult</class> class. Refer to that class for more information
/// on the result object interface. All result objects support a %Display() method that is useful for testing.
/// </p>
/// <p>The following example demonstrates the use of the %Prepare(), %Execute, and %Display() methods:
/// </p>
/// <pre>
///  SAMPLES>s tStatus = tStatement.%Prepare(.tSQL)
/// 	
///  SAMPLES>w tStatus
///  1
///  SAMPLES>s tResult = tStatement.%Execute()
/// 	
///  SAMPLES>d tResult.%Display()
///  id    Name                  DOB           Home_State
///  99    Finn,George V.        03/23/1928    MA
///  140   Hanson,James K.       04/02/1928    VT
///  14    Klein,Michael X.      06/17/1923    WV
///  159   Klingman,Brenda U.    07/09/1924    WA
///  49    Paladino,Rhonda H.    06/29/1923    AR
///  63    Vonnegut,Nellie K.    03/24/1926    HI
///  146   Zimmerman,Martin K.   05/25/1924    OH
/// 	
///  7 Rows(s) Affected
/// </pre>
/// <p>Once an SQL statement has been successfully prepared, its <property>%Metadata</property> property is available. %Metadata is an instance of the <class>%SQL.StatementMetadata</class> class. %SQL.Metadata implements a %Display() method that is useful for examining the metadata interactively, such as:
/// </p>
/// <pre>
///  SAMPLES>do tStatement.%Metadata.%Display()
///  Columns (property 'columns'):
///  Column Name  Type Prec Scale Null
///  -----------  ---- ---- ----- ----
///  id              4   10     0    0 id           Person       Sample       0            Y  N  N  Y0    1
///  Name           12   50     0    0 Name         Person       Sample       0            N  N  N  N0    0
///  DOB             9   10     0    1 DOB          Person       Sample       0            N  N  N  N0    0
///  Home_State     12    2     0    1 Home_State   Person       Sample       0            N  N  N  N0    0
/// 
///  Statement Parameters (property 'parameters'):
/// 
///  Nbr. Type precision scale nullable colName      columntype
///  ---- ---- --------- ----- -------- ------------ ----------
///     1    4     10        0     1    %parm(1)        1
///     2   12      2        0     1    %parm(2)        1
/// 
///  Formal Parameters (property 'formalParameters'):
/// 
///  Nbr. Type precision scale nullable colName      columntype
///  ---- ---- --------- ----- -------- ------------ ----------
///     2    4     10        0     1    %parm(1)        1
///     2   12      2        0     1    %parm(2)        1
/// 
///  Objects:
/// 
///  Column Name    Extent    ExportCall
///  -----------    ------    ----------
///  %%ID        Sample.Person    %QuickLoad^Sample.Person.T1(%rowid,%nolock,0,0,1)
///  SAMPLES>
/// </pre>
/// <p>You can execute a successfully prepared statement repeatedly. This is most useful when the statement includes parameters, where a parameter is defined in the SQL statement source by a question mark (&ldquo;?&rdquo;). A statement may include an arbitrary number of parameters. (There are system limitations that limit the number of dynamic parameters; up to 200 are always supported.)
/// </p>
/// <p>The <method>%Execute</method> method accepts parameter values in the order in which they appear in the source statement.  For example:
/// </p>
/// <pre>
///  SAMPLES>set tSQL=3
/// 
///  SAMPLES>set tSQL(1)="select %ID as id,Name,DOB,Home_State"
/// 	
///  SAMPLES>set tSQL(2)="from Person where Age > ? and Home_State = ?"
/// 	
///  SAMPLES>set tSQL(3)="order by 2"
/// 	
///  SAMPLES>set tStatus = tStatement.%Prepare(.tSQL)
/// 	
///  SAMPLES>set tResult = tStatement.%Execute(80,"VT")
/// 	
///  SAMPLES>do tResult.%Display()
///  id     Name                DOB           Home_State
///  140    Hanson,James K.     04/02/1928    VT
/// 
///  1 Rows(s) Affected
///  SAMPLES>set tResult = tStatement.%Execute(50,"VT")
/// 
///  SAMPLES>do tResult.%Display()
///  id     Name                DOB           Home_State
///  3      Eagleman,Emilio N.  09/01/1946    VT
///  140    Hanson,James K.     04/02/1928    VT
///  167    Hertz,Keith O.      01/01/1952    VT
/// 	
///  3 Rows(s) Affected
///  SAMPLES>
/// </pre>
/// <p>You can also use the same statement object for many different statements by simply invoking <method>%Prepare</method> with the new statement. This is because %Prepare() initializes the statement&rsquo;s execution plan and metadata.  Also, an arbitrary number of statement objects can coexist in the same process.
/// </p>
/// <p>You can also prepare and execute dynamic SQL statements by calling <method>%ExecDirect</method>. This method prepares the statement and, if it prepares the statement successfully, executes it with the supplied argument values. An optional by-reference parameter returns an instance of %SQL.Statement; this instance contains the currently prepared statement. You can then execute that statement instance just as if it had been instantiated by invoking %New() followed by a call to %Prepare(). You can also use that statement instance to prepare other dynamic statements just as if it were instantiated by %New().
/// </p>
/// <p>If an error occurs during either statement preparation or execution, then the error is described in the result object properties of %SQLCODE and %Message. Always check the result property %SQLCODE for an error following %Execute() and %ExecDirect().
/// </p>
/// <pre>
///  SAMPLES>set tResult = ##class(%SQL.Statement).%ExecDirect(.tStatement,"select name,age from Sample.Person where age > ? and home_state = ?",50,"VT")
/// 	
///  SAMPLES>write tResult.%SQLCODE
///  0
///  SAMPLES>do tResult.%Display()
///  Name                  Age
///  Eagleman,Emilio N.    62
///  Hanson,James K.       81
///  Hertz,Keith O.        57
/// 
///  3 Rows(s) Affected
/// 
///  SAMPLES>write tStatement
/// 
///  1@%SQL.Statement
/// 
///  SAMPLES>set tResult = tStatement.%Execute(40,"AK")
/// 
///  SAMPLES>do tResult.%Display()
///  Name                  Age
///  Finn,Quentin O.       66
/// 
///  1 Rows(s) Affected
/// 
///  SAMPLES>
/// </pre>
Class %SQL.Statement Extends %Library.RegisteredObject [ ClientDataType = HANDLE, Final, System = 4 ]
{

/// <property>%Dialect</property> defines the SQL dialect used to prepare dynamic SQL statements. Valid values are
/// IRIS, MSSQLSERVER, MSSQL, and SYBASE. The default is IRIS. Support for MSSQLSERVER and SYBASE dialects is limited
/// to a subset of the TSQL grammar supported by the InterSystems IRIS TSQL language mode.
Property %Dialect As %String;

Method %DialectSet(pValue As %String = "") As %Status
{
	if pValue = i%%Dialect quit $$$OK
	set tDialect = $ListFind($$$SQLDIALECTDYNAMICUPPER,$zconvert(pValue,"U"))
	if tDialect { set i%%Dialect = $ListGet($$$SQLDIALECTDYNAMIC,tDialect) quit $$$OK } else { quit $$$ERROR($$$GeneralError,"Invalid dynamic statement Dialect mode: '"_pValue_"'") }
}

/// %ObjectSelectMode allows you to specify how columns whose type class is a swizzleable class
/// will be defined in the result set class generated from a SELECT statement. 
/// <ul>
/// <li>If %ObjectSelectMode
/// is false (the default), then the property corresponding to the swizzleable column will be defined
/// in result sets as a simple literal type corresponding to the SQL table's ROWID type.</li>
/// <li>If %ObjectSelectMode is true, then the property will be defined with the column's declared type. That
/// means that accessing the result set property will trigger swizzling.</li>
/// </ul>
Property %ObjectSelectMode As %Library.Boolean [ InitialExpression = 0 ];

/// <p>%SchemaPath provides a list of schema names for resolving unqualified 
/// names during statement preparation. By default, its value is null; to set 
/// its value, use a comma-delimited list of schema names:</p>
/// 
/// <example>
/// Set %SQL.Statement.%SchemaPath = "My_Schema,Your_Schema,DEFAULT_SCHEMA"
/// </example>
/// 
/// <p>This is equivalent to the macro-preprocessor directive for embedded 
/// SQL:</p>
/// 
/// <example>
/// #sqlcompile PATH = My_Schema,Your_Schema,DEFAULT_SCHEMA
/// </example>
/// 
/// <p>PATH is a search path: if the unqualified name is found in a schema 
/// in the PATH, then this schema is used to qualify the name and no further 
/// searching is performed.<p>
/// 
/// <p>You can set the value of %SchemaPath at any time, but it is only used 
/// by the %Prepare method.</p>
/// 
/// <p>%SchemaPath can contain special schema name tokens that are resolved 
/// by the SQL compiler. Special tokens are:</p>
/// 
/// <ul>
/// <li>CURRENT_SCHEMA is the current default schema. If the <class>%SQL.Statement</class> 
/// call is defined in a class method, CURRENT_SCHEMA is 
/// the  schema mapped to the current class package. If the statement is 
/// defined in a .MAC routine, CURRENT_SCHEMA is the configuration default 
/// schema.</li>
/// <li>CURRENT_PATH is the currently defined schema search path. You can 
/// use this to add an additional schema to the search path while retaining 
/// the current search path.</li>
/// <li>DEFAULT_SCHEMA specifies the use of the system-defined default 
/// schema.</li>
/// </ul>
/// 
/// <p>You can also set %SchemaPath to a PATH value that is constructed from 
/// a given class definition; simply set %SchemaPath to 
/// ##class(%SQL.Statement).%ClassPath(classname).</p>
Property %SchemaPath As %String(MAXLEN = "");

/// This property is set on instantiation to the current select mode as returned by $system.SQL.GetSelectMode();
/// see <class>%SYSTEM.SQL</class>. 
/// You can set this property directly. The statement object uses this property to establish the
/// SQL SELECTMODE value used by dynamic statements.
/// <br>
/// Possible values are:
/// <ul>
/// <li> 0 for LOGICAL mode.</li>
/// <li> 1 for ODBC mode.</li>
/// <li> 2 for DISPLAY mode.</li>
/// </ul>
Property %SelectMode As %Library.String [ InitialExpression = {$zu(115,5)} ];

/// %StatementActualArgs are the actual values bound to formal statement arguments.
/// This value is established during %Prepare from the %StatementArgs value. This value is used
/// to form the actual arguments passed when executing the currently prepared statement. The value
/// of %StatementActualArgs includes and literals and host variables replaced during preparsing
/// as well as the local variables used to hold actual parameter values passed to %Execute. We use
/// two types of locals - %parm(parameter_ordinal_position) for non-CALL statements and
/// parm_parameter_ordinal_position (for example, parm1 for the first '?') for CALL statements.
/// The reason for the difference is that we need to preserve 'undefinedness' of parameters passed
/// to SQL invoked routines.
Property %StatementActualArgs As %String(MAXLEN = "") [ Internal, Private ];

/// This property is used to set %msqlvars during the compilation of the cached query.  
/// If defined, %msqlvars will be placed into the cached query methods as
/// 		#EXECUTE set %msqlvar=<%msqlvar>
Property %msqlvar As %String [ Internal ];

/// This property is for xDBC DialectExecuteParameter to define the sqlBatch method with the proper formalspec
/// This property is for internal use only
Property %DialectParameterMetadata As %String [ Internal ];

/// This property is used to keep track of RTPC runtime cached query name for
/// the query that triggers RTPC
Property %RTPCRuntimeCQName As %String;

Method bindArguments(ByRef pActual As %String(MAXLEN=""), ByRef %CallArgs As %String) As %Integer [ Internal, Private ]
{
	set qcount=0,tArgCount=0,ptr=0
	while $listnext(i%%StatementActualArgs,ptr,argType) {
		if '$listnext(i%%StatementActualArgs,ptr,argVal) { ZT "BADARG" }
		set tArgCount=tArgCount+1
		if argType="?" {
			set qcount=qcount+1
			if i%%StatementType '= 45 {
				if '$data(pActual(qcount),%CallArgs(tArgCount)) { throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Invalid Dynamic Statement Parameter") }
			} else {
				merge %CallArgs(tArgCount)=pActual(qcount)
			}
		} elseif argType="c" {
			set %CallArgs(tArgCount)=argVal
		} elseif argType="v",i%%StatementType '= 45 {
			set %CallArgs(tArgCount)=$get(@argVal)
		}
	}
	if $get(pActual) > qcount { throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Dynamic SQL Execute, more parameter values passed than are specified in the dynamic statement") }
}

/// statementArgs are literals, host variables (not supported here), and parameters (as ?)
/// This value is established during preparsing and is a $list consisting of n*2 elements
/// where 'n' is the number of arguments discovered by the preparser. For a non-empty list,
/// the first element of the list is the argType and the second is the argValue for the first
/// argument discovered. This structure repeats for each argument. Arguments are either constants,
/// (argType = 'C', argValue is a literal), host variables (argType = 'V', argValue
/// is a legal COS identifier), or replacable parameter (argType = '?', argValue = '?').
/// This value is processed during %Prepare to construct the %StatementActualArgs value. This value
/// is retained for metadata reporting as the actual statement prepared might have a different formal
/// argument specification.
Property %StatementArgs As %String(MAXLEN = "") [ Internal, Private ];

Property %StatementArgCount As %Integer [ InitialExpression = 0, Internal, Private ];

Property %PreparedStatement As %ObjectHandle [ Internal, Private ];

Method %PreparedStatementSet(pPS As %ObjectHandle) As %Status [ ServerOnly = 1 ]
{
	try {
		if i%%PreparedStatement'="",i%%PreparedStatement'=pPS {	// if a new prepared statement and the old prepared statement was not NULL
			if (i%%StatementType>6 && (i%%StatementType<20)) || (i%%StatementType>25) {	// AutoPurge statement (same as xDBC cached queries as defined in Compile^%SYS.SQLSRV)
				do PurgeRtn^%SYS.SQLSRV($classname(i%%PreparedStatement))
			}
		}
	}
	catch {}	// Don't care is Purge failed, just continue on
	set i%%PreparedStatement=pPS
	Quit $$$OK
}

Property %StatementGUID As %Binary [ Internal, Private ];

Property %StatementHash As %Binary [ Internal, Private ];

/// %Metadata is the statement descriptor. It is an instance of <class>%SQL.StatementMetadata</class>.
Property %Metadata As %SQL.StatementMetadata;

/// Internal property containing the actual SQL statement submitted to prepare().
Property %StatementText As %String(MAXLEN = "") [ Internal, MultiDimensional, Private ];

/// <p>Integer value indicating the type of statement.</p>
/// <table>
/// 	<tr><td>1</td><td>SELECT</td></tr>
/// 	<tr><td>2</td><td>INSERT (also 'INSERT OR UPDATE')</td></tr>
/// 	<tr><td>3</td><td>UPDATE</td></tr>
/// 	<tr><td>4</td><td>DELETE</td></tr>
/// 	<tr><td>5</td><td>COMMIT</td></tr>
/// 	<tr><td>6</td><td>ROLLBACK</td></tr>
/// 	<tr><td>7</td><td>GRANT</td></tr>
/// 	<tr><td>8</td><td>REVOKE</td></tr>
/// 	<tr><td>9</td><td>CREATE TABLE</td></tr>
/// 	<tr><td>10</td><td>ALTER TABLE</td></tr>
/// 	<tr><td>11</td><td>DROP TABLE</td></tr>
/// 	<tr><td>12</td><td>CREATE VIEW</td></tr>
/// 	<tr><td>13</td><td>ALTER VIEW</td></tr>
/// 	<tr><td>14</td><td>DROP VIEW</td></tr>
/// 	<tr><td>15</td><td>CREATE INDEX</td></tr>
/// 	<tr><td>16</td><td>ALTER INDEX (Not supported)</td></tr>
/// 	<tr><td>17</td><td>DROP INDEX</td></tr>
/// 	<tr><td>18</td><td>CREATE ROLE</td></tr>
/// 	<tr><td>19</td><td>DROP ROLE</td></tr>
/// 	<tr><td>20</td><td>SET TRANSACTION</td></tr>
/// 	<tr><td>21</td><td>START TRANSACTION</td></tr>
/// 	<tr><td>22</td><td>%INTRANSACTION</td></tr>
/// 	<tr><td>23</td><td>%BEGTRANS (Alias for START TRANSACTION)</td></tr>
/// 	<tr><td>24</td><td>%INTRANS (Alias for %INTRANSACTION)</td></tr>
/// 	<tr><td>25</td><td>GET (Not supported)</td></tr>
/// 	<tr><td>26</td><td>SET OPTION</td></tr>
/// 	<tr><td>27</td><td>STATISTICS (UPDATE STATISTICS, not supported))</td></tr>
/// 	<tr><td>28</td><td>%CHECKPRIV</td></tr>
/// 	<tr><td>29</td><td>CREATE USER</td></tr>
/// 	<tr><td>30</td><td>ALTER USER</td></tr>
/// 	<tr><td>31</td><td>DROP USER</td></tr>
/// 	<tr><td>32</td><td>%CHECKPRIV (SQL Admin Privilege)</td></tr>
/// 	<tr><td>33</td><td>GRANT (SQL Admin Privilege)</td></tr>
/// 	<tr><td>34</td><td>REVOKE (SQL Admin Privilege)</td></tr>
/// 	<tr><td>35</td><td>CREATE FUNCTION</td></tr>
/// 	<tr><td>36</td><td>CREATE METHOD</td></tr>
/// 	<tr><td>37</td><td>CREATE PROCEDURE</td></tr>
/// 	<tr><td>38</td><td>CREATE QUERY</td></tr>
/// 	<tr><td>39</td><td>DROP FUNCTION</td></tr>
/// 	<tr><td>40</td><td>DROP METHOD</td></tr>
/// 	<tr><td>41</td><td>DROP PROCEDURE</td></tr>
/// 	<tr><td>42</td><td>DROP QUERY</td></tr>
/// 	<tr><td>43</td><td>CREATE TRIGGER</td></tr>
/// 	<tr><td>44</td><td>DROP TRIGGER</td></tr>
/// 	<tr><td>45</td><td>CALL</td></tr>
/// 	<tr><td>46</td><td>SAVEPOINT</td></tr>
/// 	<tr><td>47</td><td>LOCK TABLE</td></tr>
/// 	<tr><td>48</td><td>UNLOCK TABLE</td></tr>
/// 	<tr><td>49</td><td>CREATE DATABASE</td></tr>
/// 	<tr><td>50</td><td>DROP DATABASE</td></tr>
/// 	<tr><td>51</td><td>USE DATABASE</td></tr>
/// 	<tr><td>99</td><td>Anything not list above</td></tr>
/// </table>
Property %StatementType As %Integer [ Internal, Private ];

/// Prepare and execute an SQL statement. If no statement handle is allocated in pHStatement then a new statement handle will be
/// allocated and returned by reference. That behavior is different from SQLPrepare.
/// Formal Parameters:
/// <ul>
/// <li>pHStatement		-	OPTIONAL (byref) the statement handle. If an actual arg is passed by reference then it will be populated with an OREF to a new
/// 						statement object. </li>
/// <li>pStatementText	-	(byref) SQL statement text. This can be an array of SQL statement lines with the base node set to the number of lines or
/// 					-	it can be a single string. </li>
/// <li>%parm...		-	variable number of arguments that represent the values to be bound to parameters contained in <var>pStatementText</var>.
/// 						Only parameters with input direction (input or input-output) are actually used but a position for each '?' contained in
/// 						<var>pStatementText</var> needs to be represented. In the statement:
/// <pre>
/// 	? = call Sample.PersonSets(?,?)
/// </pre>
/// The %parms... list must contain an empty position for the return value. An example of a call to %ExecDirect for such a
/// statement is:
/// <example>
/// set tRes = ##class(%SQL.Statement).%ExecDirect(.tStmt,"?=call Sample.PersonSets(?,?)",,"A","NY")
/// </example>
/// In this example, the return value is allocated a position in the %parms list (the ,,), "A" is bound to the first argument passed
/// to Sample.PersonSets and "NY" is bound to the second.</li>
/// </ul>
/// This method returns a <class>%SQL.StatementResult</class> object.
ClassMethod %ExecDirect(ByRef pHStatement As %SQL.Statement = {$$$NULLOREF}, ByRef pStatementText As %RawString = "", %parm...) As %SQL.StatementResult [ PublicList = SQLCODE ]
{
	new %tResult, %tStatement,SQLCODE
	if '$isobject(pHStatement) { set pHStatement = ..%New() }
	try {
		do pHStatement.prepare(.pStatementText)
		set tResult = pHStatement.%Execute(%parm...)
	}
	catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code,tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Data }
	}
#; TODO: We continue to have a split error reporting personality and we are losing error info here. Let's standardize error reporting!!
	quit tResult
}

/// 
/// This method returns a %SQL.StatementResult object.
/// This is the same as %ExecDirect but no SQL privileges are checked at Prepare time of the statement.  
/// For example, if the statement is:
/// <example>DELETE FROM T</example>
/// This method will not check that the current user has DELETE privilege for table T.
/// However, for <example>GRANT SELECT ON T TO TERRY</example> SQL will still validate at execution time that the current user has the SELECT privilege on table T and that privilege is grantable.
ClassMethod %ExecDirectNoPriv(ByRef pHStatement As %SQL.Statement = {$$$NULLOREF}, ByRef pStatementText As %RawString = "", %parm...) As %SQL.StatementResult [ PublicList = SQLCODE ]
{
		#; Do not let this method be called directly from application mode.  It may be called indirectly in application mode.
		#; We check this by looking at the number of entries in the stack.  If called directly, the stack will look like:  $lb("^%ExecDirectNoPriv+2^%SQL.Statement.1^2","d^^^0")
	if ($zjob\1#2)=0,$ll($zu(41,-2))<3 { RETURN "" }
	new %tResult, %tStatement,SQLCODE
	if '$isobject(pHStatement) { set pHStatement = ..%New() }
	try {
		do pHStatement.prepare(.pStatementText,0)
		set tResult = pHStatement.%Execute(%parm...)
	}
	catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code,tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Data }
	}
#; TODO: We continue to have a split error reporting personality and we are losing error info here. Let's standardize error reporting!!
	quit tResult
}

/// 
/// This method returns a %SQL.StatementResult object.
/// This is the same as %ExecDirect but the statement is not audited.
ClassMethod %ExecDirectNoAudit(ByRef pHStatement As %SQL.Statement = {$$$NULLOREF}, ByRef pStatementText As %RawString = "", %parm...) As %SQL.StatementResult [ PublicList = SQLCODE ]
{
	new %tResult, %tStatement,SQLCODE
	if '$isobject(pHStatement) { set pHStatement = ..%New() }
	try {
		do pHStatement.prepare(.pStatementText,,1)
		set tResult = pHStatement.%Execute(%parm...)
	}
	catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code,tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Data }
	}
#; TODO: We continue to have a split error reporting personality and we are losing error info here. Let's standardize error reporting!!
	quit tResult
}

/// 
/// This method returns a %SQL.StatementResult object.
/// This is the same as %ExecDirect but no SQL privileges are checked and the statement is not audited.
/// Regarding privilege checking, For example, if the statement is:
/// <example>DELETE FROM T</example>
/// This method will not check that the current user has DELETE privilege for table T.
/// However, for <example>GRANT SELECT ON T TO TERRY</example> SQL will still validate at execution time that the current user has the SELECT privilege on table T and that privilege is grantable.
ClassMethod %ExecDirectNoPrivNoAudit(ByRef pHStatement As %SQL.Statement = {$$$NULLOREF}, ByRef pStatementText As %RawString = "", %parm...) As %SQL.StatementResult [ PublicList = SQLCODE ]
{
		#; Do not let this method be called directly from application mode.  It may be called indirectly in application mode.
		#; We check this by looking at the number of entries in the stack.  If called directly, the stack will look like:  $lb("^%ExecDirectNoPrivNoAudit+2^%SQL.Statement.1^2","d^^^0")
	if ($zjob\1#2)=0,$ll($zu(41,-2))<3 { RETURN "" }
	new %tResult, %tStatement,SQLCODE
	if '$isobject(pHStatement) { set pHStatement = ..%New() }
	try {
		do pHStatement.prepare(.pStatementText,0,1)
		set tResult = pHStatement.%Execute(%parm...)
	}
	catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code,tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Data }
	}
#; TODO: We continue to have a split error reporting personality and we are losing error info here. Let's standardize error reporting!!
	quit tResult
}

/// Prepares an SQL statement and returns a %Status indicating success or failure. 
/// You can pass the statement as a simple string or an array of lines with the root containing the number of lines.
/// If this method returns success, use <method>%Execute</method> to execute the class query and obtain the result set. 
/// <p>The checkPriv argument can be used to not perform SQL privilege checking on the statement 
/// if checkPriv=0. The default is that privileges will be checked.  This does not apply to privileges checked at the time of execution, only to privileges checked at the time of prepare.</p>
/// For example, if the statement is:
/// <example>DELETE FROM T</example>
/// This method will not check that the current user has DELETE privilege for table T.
/// However, for <example>GRANT SELECT ON T TO TERRY</example> SQL will still validate at execution time that the current user has the SELECT privilege on table T and that privilege is grantable.
Method %Prepare(ByRef pStatementText As %RawString, checkPriv As %Boolean = 1, noAudit As %Boolean = 0) As %Status
{
#dim tException as %Exception.AbstractException
	// JMM1152 Retry upon error for up to 1 second, to avoid failing during class compilation. This is needed
	// during sharded / nonsharded table conversions, but may also prevent failure during other cases of class
	// compilation while a referenced class is being queried.
	for ii=1:1:100 { // JMM1152+ 
		s tStatus=$$$OK // JMM1152-
		try { 
			do ..prepare(.pStatementText,checkPriv,noAudit) 
		}
		catch tException {
			set tStatus = tException.AsStatus()
			$$$SNRBDebugTrace("tqdebug %Prepare retrying after error, ii: "_ii_", error:",tStatus) // JMM1152=
		}
		quit:(tStatus=$$$OK || '$$$SSRBCompileInProgress) // JMM1152+ JMM1249=
		hang 0.01 // JMM1152-
	}
	$$$ISINTERRUPTTHROW(tStatus) // JMM1152+
	quit tStatus // JMM1152-
}

/// Generates the appropriate CALL statement for invoking a class query, prepares the 
/// generated statement, and returns a %Status indicating success or failure.
/// For example, the following prepares the FileSet query of the <class>%Library.File</class> class:
/// <example>
/// set status = stmt.%PrepareClassQuery("%Library.File","FileSet")
/// </example>
/// If this method returns success, use <method>%Execute</method> to execute the class query and obtain the result set. 
/// <p>All parameters defined in the formal specification of the query are assigned placeholder '?' in the generated CALL statement.
/// Actual values for those parameters can be passed in the %Execute() call. %Metadata is available after a successful
/// prepare.</p>  
/// <p>Because this method generates a CALL statement, the executed class query must have the 
/// <a href="/csp/docbook/Doc.View.cls?FIND=CLASSDEF+SQLPROC+QUERY">SqlProc</a> keyword set to True.
/// Class queries defined with SqlProc = False cannot be called by %PrepareClassQuery.</p>
/// <p>The checkPriv argument can be used to not perform SQL EXECUTE privilege checking on the class queryes procedure call if checkPriv=0. The default is that privileges will be checked.</p>
Method %PrepareClassQuery(pClassName As %String = "", pQueryName As %String = "", checkPriv As %Boolean = 1) As %Library.Status
{
	set tStatus = $$$OK
	try {
		set pClassName=$$$NormalizeClassname(pClassName)
		if (pClassName = "") || (pQueryName = "") || ('$$$comMemberDefined(pClassName,$$$cCLASSquery,pQueryName)) { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$QueryDoesNotExist,pClassName_":"_pQueryName)) }
		Set tSchemaName=$$$comClassKeyGet(pClassName,$$$cCLASSsqlschemaname)
		$$$comMemberKeyGetLvar(tProcedureName,pClassName,$$$cCLASSquery,pQueryName,$$$cQUERYsqlname)
		set tIsProjected = $$$comMemberKeyGet(pClassName,$$$cCLASSquery,pQueryName,$$$cQUERYsqlproc)
		$$$comMemberKeyGetLvar(tFormalSpec,pClassName,$$$cCLASSquery,pQueryName,$$$cQUERYformalspecparsed)
		if $ListLength(tFormalSpec) {
			set tStatementText = "call " _ tSchemaName _ "." _ tProcedureName _ "(?"
			for tPtr = 2:1:$ListLength(tFormalSpec) { set tStatementText = tStatementText _ ",?" }
			set tStatementText = tStatementText _ ")"
		}
		else { set tStatementText = "call " _ tSchemaName _ "." _ tProcedureName _ "()" }		
		do ..prepare(.tStatementText,checkPriv)
	}
	catch tException {
		set tStatus = tException.AsStatus()
		$$$ISINTERRUPTTHROW(tStatus)
	}
	quit tStatus
}

/// Internal method that does the actual work of preparing a statement.
/// This method throws an exception if any error is encountered.
Method prepare(ByRef pStatementText As %RawString = "", checkPriv As %Boolean = 1, noAudit As %Boolean = 0) [ Internal ]
{
#DEFINE Hash(%a) $system.Encryption.Base64Encode($system.Encryption.SHA1Hash(%a))
#define CachedQueryVersion      8
#define quoter(%val)	$s(%val'=+%val:$s(%val=$char(0):"$c(0)",1:$zu(144,1,%val)),1:""""_%val_"""")

	new %ROWID, %ROWCOUNT, %tResult, %msg
#; 0) Initialize the allocated statement and normalize the input arguments
		#; Set %PreparedStatement first before %StatementType because %PreparedStatement needs to see the value of %StatementType to determine
		#; if we need to auto-Purge the previous cached statement.
	if i%%PreparedStatement'="" { set ..%PreparedStatement="" }
	set i%%StatementActualArgs = "", i%%StatementArgs = "", i%%StatementArgCount = 0, i%%StatementType = "", ..%Metadata = "", i%%StatementHash = ""
	kill i%%StatementText
		// We want a dialect of "" and a dialect of "IRIS" to produce the same hash/cached statement (assuming all else is the same)
	if i%%Dialect=$$$SQLDIALECTDEFAULT || ($$$UPPER(i%%Dialect)=$$$SQLDIALECTCACHE) { set i%%Dialect=$$$SQLDIALECTIRIS }
	merge i%%StatementText = pStatementText
		#; Replace schema tokens with actual values now as they need to be fixed for the prepare. The statement implementation is static with regards to path.
	if ..%SchemaPath '= "" {
		set tCurrentPath = $Select($Data(%sqlSchemaPath):$ListToString(%sqlSchemaPath),1:"")
		set tSchemaPath = $$$UPPER(..%SchemaPath)
		for tPtr = 1:1:$l(tSchemaPath,",") {
			set tSchema=$p(tSchemaPath,",",tPtr)
			if tSchema = "" { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SqlCompileBadMode)) }
			elseif tSchema="CURRENT_PATH" { set $p(tSchemaPath,",",tPtr) = tCurrentPath }
#; TODO: How do we determine the code container? It is either contextless (server based or command line based), in a routine or in a class. We are only interested
#; 		if we are in a class. This code, from the MPP, knows the code container:
			elseif tSchema="CURRENT_SCHEMA" { set $p(tSchemaPath,",",tPtr) = $s($g(%classname)'="":$$$UPPER($$DetermineSchemaName^%qarmac(%classname)),1:$$$DEFAULTSCHEMA) }
			elseif tSchema = "DEFAULT_SCHEMA" { set $p(tSchemaPath,",",tPtr) = $$$DEFAULTSCHEMA }
		}
	}
	else { set tSchemaPath = "" }
	new %sqlSchemaPath set %sqlSchemaPath = $ListFromString(tSchemaPath)
#; 1) Preparse the statement to normalize it, extract literals, identify temporary tables used, and locate parameters.
		#;  We need to convert the query string into an array so SQL comments will work OK.
#; TODO (DLP20091215)	Do we use different preparsers for different dialect settings? Probably but not yet.
	if (i%%Dialect = $$$SQLDIALECTDEFAULT) || (i%%Dialect = $$$SQLDIALECTIRIS) {
		new %sqlHVarTypes2 set %sqlHVarTypes2=1
		set SQLCODE = ..preparse(.pStatementText,.tStatementPreparsed,.tStatementArgs)

		set i%%StatementActualArgs = tStatementArgs
		if $Get(SQLCODE)<0 { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$Get(%msg)) }
		set ..%StatementGUID = $SYSTEM.Util.CreateGUID()
			#; the following call will throw an exception if an error is detected...
		set ..%PreparedStatement = ##class(%SQL.DynamicStatement).Prepare(..%StatementGUID,.tStatementPreparsed,"",.tSchemaPath,.tStatementHash,.tStatementType,..%ObjectSelectMode,..%Dialect,$this,checkPriv,,noAudit)
	}
		// Must be a Dialect other than IRIS and we do not preparse in non-IRIS Dialect mode
	else {
			// tStatementArgs is normally constructed as a result of preparsing. Non-IRIS dialect statements are not preparsed
			// so we have to store this information in the statement cache and return it from Prepare. For now, there is no literal
			// replacement so formal arguments and actual arguments are the same lists.
			// the following call will throw an exception if an error is detected...
		set tStatementArgs = ""
		set ..%StatementGUID = $SYSTEM.Util.CreateGUID()
		set ..%PreparedStatement = ##class(%SQL.DynamicStatement).Prepare(..%StatementGUID,.pStatementText,"",.tSchemaPath,.tStatementHash,.tStatementType,..%ObjectSelectMode,..%Dialect,$this,checkPriv,..%DialectParameterMetadata,noAudit)
		if $IsObject(..%PreparedStatement) { set tParameters = ..%PreparedStatement.#%statementparameters for tPtr = 1:1:$Listget(tParameters,1) { set tStatementArgs = tStatementArgs _ $ListBuild("?","?") } }
		set i%%StatementActualArgs = tStatementArgs

		if ..%StatementType = 45 {
			set tExecuteArgs = "",qcount=0 For ptr=1:2:$ListLength(tStatementArgs) s argType=$li(tStatementArgs,ptr),argVal=$li(tStatementArgs,ptr+1),arg = $Case(argType,"?":".parm"_$Increment(qcount)_"","c":$$$quoter(argVal),"v":"."_argVal,:"") s tExecuteArgs = tExecuteArgs_arg_","
			set ..%StatementArgs = $extract(tExecuteArgs,1,*-1), ..%StatementArgCount = qcount
		}
	}
	set i%%StatementHash = tStatementHash
		#; If this is a statement type not recognized by the simple three character extract of the first token, just set it to 99 - we don't really care
		#; since we only want to know SELECT, CALL, and everything else. If we store the statement type in the implementation class then we can get more
		#; precise info.
	if tStatementType { set ..%StatementType = tStatementType } else { set ..%StatementType = 99 }
	quit
}

/// Internal method that is called by the xDBC server.
/// It constructs metadata specific to the server and populates the server statement object.
/// (%qsc(%qacn) ($$$CQClassname) is where the server "statement object" is kept).
/// **NOTE** THIS METHOD IS INTERNAL, ISC USE ONLY!!
Method prepareForServer(ByRef pServerStatement As %Binary, pStatementHandle As %Integer = 0, ByRef pMetadata As %Binary = "") [ Internal ]
{
	// This is a partial server statement object definition (from %SYS.DBSRV.inc):
#DEFINE RoutineName             pServerStatement(pStatementHandle)
#DEFINE SPClassName             pServerStatement(pStatementHandle,5)
#DEFINE SPName                  pServerStatement(pStatementHandle,6)
#DEFINE SPExecString            pServerStatement(pStatementHandle,7)
#DEFINE RoutineTimestamp        pServerStatement(pStatementHandle,8)
#DEFINE PrivilegeInfo           pServerStatement(pStatementHandle,10)
#DEFINE SPHandle                pServerStatement(pStatementHandle,11)
#DEFINE SPContext               pServerStatement(pStatementHandle,12)
#DEFINE ParameterDirection      pServerStatement(pStatementHandle,18)
#DEFINE ParameterObjectCategory pServerStatement(pStatementHandle,20)
#DEFINE SPPrivilegeParam        pServerStatement(pStatementHandle,23)
#DEFINE StaticCursor            pServerStatement(pStatementHandle,24)
#DEFINE SPInputParmLen          pServerStatement(pStatementHandle,25)

		// We might consider optimizing this later. This method is only called when the server is executing in a "dialect" mode
		// and the metadata is wired to a specific form - interface = -1, parameters only on prepare and so on.
	// set pMetadata = $Listbuild(-1) _ ..%Metadata.getParameterMetadata()
	set pMetadata = ..%Metadata.getParameterMetadata()
	set class0name = $$$nameClassRoutineNameGet($classname(..%PreparedStatement),0)
	set $$$CQClassname = $classname(..%PreparedStatement) 
	set $$$RoutineTimestamp = $Extract($Get(^rOBJ(class0name)),1,16)
	set $$$SPHandle = $this
}

ClassMethod preparse(ByRef pStatementText, ByRef pStatementPreparsed, ByRef pStatementArgs) As %Integer [ PublicList = SQLCODE ]
{
#define NL                 $c(13,10)
#define InSingleQuotes(%s,%p) ($L($E(%s,1,%p-1),"'")+1#2)
#define InDoubleQuotes(%s,%p) ($L($E(%s,1,%p-1),"""")+1#2)
	try {
		if $data(pStatementText) >2 {
			set text=""
			for line=1:1:pStatementText { set text=text_$lb(pStatementText(line)) }
		}
		set tHash=$zcrc($get(text,pStatementText),9)
	} catch {
			#; In case statement too long reparse it always
		if $ZE'["<MAXSTRING>" throw
		set tHash=""
	}
	if tHash'="",$data(^IRIS.Temp.StatementHashPP(tHash),tPreparserResult),$lg(tPreparserResult)=$get(text,pStatementText) {
		set pStatementPreparsed = $Listget(tPreparserResult,2), pStatementArgs = $Listget(tPreparserResult,3)
		RETURN 0
	}

	new SQLCODE
	set SQLCODE = 0
	if $Data(pStatementText) '> 2 {
		// We can't lose any $c(13) or $c(10)'s that are part of a literal value.
		// So we will not replace any $$$NL that are within a '...' or "..."				
		set sqlinput(1)=$select(pStatementText[$c(13):$$StringReplaceSQL^%SYS.DynamicQuery(pStatementText,$c(13)," ",1),1:pStatementText)
		set sqlinput=1
		#; %sqlStatementPreparseNoInto is NEW'd and SET in ShowPlanForOutliers^%apiSQL
		set tPreparserResult = $$preparse^%qaqpreparser(.sqlinput,$g(%sqlStatementPreparseNoInto)=1,$c(10),,.type)
	} else {
		#; %sqlStatementPreparseNoInto is NEW'd and SET in ShowPlanForOutliers^%apiSQL
		set tPreparserResult = $$preparse^%qaqpreparser(.pStatementText,$g(%sqlStatementPreparseNoInto)=1,,,.type)
	}
	if (tPreparserResult '= "") && ('SQLCODE) {
		Set:$find($list(tPreparserResult,1), " /*#OPTIONS {""DynamicSQL"":1} */")=0 $list(tPreparserResult,1)=$list(tPreparserResult,1)_$case(type, "THROUGH":$c(10), :"")_" /*#OPTIONS {""DynamicSQL"":1} */"
		If $random(10000)=42 Kill ^IRIS.Temp.StatementHashPP
		try {
			set ^IRIS.Temp.StatementHashPP(tHash)=$lb($get(text,pStatementText))_tPreparserResult
		} catch {
			#; Ignore an error setting the cache, maybe MAXSTRING
		}
	} else {
		set tPreparserResult = ""
	}
	set pStatementPreparsed = $Listget(tPreparserResult,1), pStatementArgs = $Listget(tPreparserResult,2)
	quit SQLCODE
}

/// <p>Executes the current statement and returns the result as an instance of <class>%SQL.StatementResult</class>. The result of the execute is always the return value.
/// Success/Failure information is reported in the result object as %SQLCODE, %Message, %ROWCOUNT, and/or %ROWID.
/// </p>
/// <p>
/// The %Execute() method accepts parameter values in the order in which they appear in the source statement.  For example:
/// </p>
/// <pre>
///    SAMPLES>set tSQL=3
/// 
///    SAMPLES>set tSQL(1)="select %ID as id,Name,DOB,Home_State"
/// 
///    SAMPLES>set tSQL(2)="from Person where Age > ? and Home_State = ?"
/// 
///    SAMPLES>set tSQL(3)="order by 2"
/// 
///    SAMPLES>set tStatus = tStatement.%Prepare(.tSQL)
/// 
///    SAMPLES>set tResult = tStatement.%Execute(80,"VT")
/// 
///    SAMPLES>do tResult.%Display()
///    id     Name                DOB           Home_State
///    140    Hanson,James K.     04/02/1928    VT
/// 
///    1 Rows(s) Affected
///    SAMPLES>set tResult = tStatement.%Execute(50,"VT")
/// 
///    SAMPLES>do tResult.%Display()
///    id     Name                DOB           Home_State
///    3      Eagleman,Emilio N.  09/01/1946    VT
///    140    Hanson,James K.     04/02/1928    VT
///    167    Hertz,Keith O.      01/01/1952    VT
/// 
///    3 Rows(s) Affected
///    SAMPLES>
///    </pre>
/// <p>
/// You can also use the same statement object for many different statements by simply invoking <method>%Prepare</method> with the new statement. This is because %Prepare() initializes the statement&rsquo;s execution plan and metadata.  Also, an arbitrary number of statement objects can coexist in the same process.
/// </p>
/// <p>The %parm... input parameter represents a variable number of arguments that represent the values to be bound to parameters contained in <var>pStatementText</var>.
/// Only parameters with input direction (input or input-output) are actually used but the position of each '?' contained in
/// the source statement must be maintained.</p>
/// <p>An example of calling %Execute for a prepared statement "? = call Sample.PersonSets(?,?)" is:
/// <example>
/// 	set tStatement = ##class(%SQL.Statement).%New()
/// 	set tStatus = tStatement.%Prepare("?=call Sample.PersonSets(?,?)")
/// 	set tResult = tStatement.%Execute(,"A","NY")
/// </example>
/// In this example, the return value is allocated a position in the %parms list (the ','), "A" is bound to the first argument passed
/// to Sample.PersonSets and "NY" is bound to the second.
Method %Execute(%parm...) As %SQL.StatementResult [ CodeMode = call, PublicList = SQLCODE ]
{
..execute()
}

Method execute(%parm...) As %SQL.StatementResult [ PublicList = SQLCODE ]
{
	new %CallArgs, SQLCODE, %ROWID, %ROWCOUNT, %objlasterror
	try {
		if $Isobject($Get(%sqlcontext)) {
			set tStatementContext = ##class(%ProcedureContext).%New()
			merge tStatementContext.%LTT = %sqlcontext.%LTT, tStatementContext.TTNI = %sqlcontext.TTNI, tStatementContext.PTT = %sqlcontext.PTT
			new %sqlcontext
			set %sqlcontext = tStatementContext
		}
		else { new %sqlcontext }
		if $g($system.Context.SQL().ShardExecIUDArgs)'="" {
			kill %parm 
			merge %parm=$system.Context.SQL().ShardExecIUDArgs
			kill $system.Context.SQL().ShardExecIUDArgs
		}
			// Update the select mode of the prepared statement object
		if ..%StatementType = 1 {
			set %objlasterror = ""
			do ..bindArguments(.%parm,.%CallArgs)
			set tResult = ..%PreparedStatement.%New(..%PreparedStatement,..%SelectMode,.%CallArgs)
			if '$Isobject($Get(tResult)) { throw ##class(%Exception.StatusException).CreateFromStatus($Select($Get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$SQLCode,-400,"Unknown error, possibly related to $ZE: "_$ZE))) }
		} elseif ..%StatementType = 80 {
			set sc = ..%PreparedStatement.Execute()
			if $$$ISERR(sc) {
				throw ##class(%Exception.StatusException).CreateFromStatus(sc)
			} else {
				set tResult = ..%PreparedStatement
			}
		}
		elseif ..%StatementType {
			try {
				set tSelectMode = $Zutil(115,5,..%SelectMode)
				if (..%Dialect = $$$SQLDIALECTDEFAULT) || (..%Dialect = $$$SQLDIALECTIRIS) || (..%Dialect = $$$SQLDIALECTCACHE) || ('$Find("|45|99|",..%StatementType)) {
					if ..%DialectParameterMetadata'="" {
						merge tparm=%parm(1)
						do ..bindArguments(.tparm,.%CallArgs)
					} else {
						do ..bindArguments(.%parm,.%CallArgs)
					}
					set tResult = ..%PreparedStatement.%Execute($this,.%CallArgs)
					set tResult.%StatementType = ..%StatementType
				}
				else {
						// Not IRIS Dialect - EXEC/CALL statement
					if ..%DialectParameterMetadata'="",$case(..%StatementType,45:1,99:1,:0) {
							#; if we get here this is a xDBC DirectParameter call with bound paramaters
							#; The parameters were sent to the server in srvDP^%SYS.DBSRV
							#; Here we will use the parameter metadata to define the parameters to pass to %Execute()
							#; The parameters passed in were in %parm(1) through %parm(n) ans passed to %Execute as (.%parm)
							#; thus they end up in %parm(1,1) through %parm(1,n)
							#; We will then bind back any output parameters back into %parm(1,col)
						set numparams=$lg(..%DialectParameterMetadata,1)
						if numparams {
							set tArgs="",tBindArgs="",tNewArgs="",tBindBack=""
							for tPtr=1:1:numparams {
								set name="parm"_tPtr	//$tr($lg(dialectParameterMetadata,((tPtr-1)*6)+5+1),"@")
								set mode=$lg(..%DialectParameterMetadata,((tPtr-1)*6)+6+1)
								if mode>1 {
									set tArgs=tArgs_$e(",",tArgs'="")_"."_name	
									set tBindBack=tBindBack_$e(",",tBindBack'="")_"%parm(1,"_tPtr_")="_name
								} else {
									set tArgs=tArgs_$e(",",tArgs'="")_name	
								}
								set tBindArgs=tBindArgs_$e(",",tBindArgs'="")_name_"=$g(%parm(1,"_tPtr_"))"
								set tNewArgs=tNewArgs_$e(",",tNewArgs'="")_name
							}
							set tExecute = "new retVal"
							if tNewArgs'="" { set tExecute=tExecute_","_tNewArgs }
							if tBindArgs'="" { set tExecute=tExecute_" set "_tBindArgs }
							set tExecute=tExecute_" set retVal=tPreparedStatement.%Execute("_tArgs_")"
							if tBindBack'="" { set tExecute=tExecute_" set "_tBindBack }
							set tExecute=tExecute_" RETURN retVal"
						} else {
							// we should never get here because if there were no parameters it would have been a DirectDialectExecute!
						}
					} else {
						set tExecute = "RETURN tPreparedStatement.%Execute("_..%StatementArgs_")"
						if $g(%parm) {
							if ..%DialectParameterMetadata'="" { set tExecute = "new parm set parm=%parm merge parm=%parm(1) RETURN tPreparedStatement.%Execute(,.parm)" }	// From DirectParameter in DBSRV
							else { set tExecute = "RETURN tPreparedStatement.%Execute(,.%parm)" }
						}
					}
					set tResult = $Xecute("(tPreparedStatement) "_tExecute,..%PreparedStatement)
					if '$IsObject(tResult) { set tResult = ##class(%SQL.StatementResult).%New() set tResult.%SQLCODE = "-400", tResult.%Message = "Error occurred during SQL routine CALL" }
					set tResult.%StatementType = ..%StatementType
				}
				set tSelectMode = $Zutil(115,5,tSelectMode)
			}
				#; The purpose of this nested try/catch is simply to reset the selectmode $zu switch to the original
			catch tException {
				if $Get(tSelectMode) '= "" { set tSelectMode = $Zutil(115,5,tSelectMode) }
				throw tException
			}
		}
		else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SQLCode,-400,"Statement not prepared"))
		}
		set ..%RTPCRuntimeCQName = $s($classname(tResult)'="%SQL.StatementResult":$classname(tResult),1:"")
	}
	catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		set tResult.%StatementType = ..%StatementType
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code, tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Name_$Select(tException.Data'="":" "_tException.Data,1:"") }
	}
	QUIT tResult
}

/// Shard-specific execute method, identical to regular %Execute except for argument binding.
Method %ShardExecute(parm As %String(MAXLEN="")) As %SQL.StatementResult [ Internal, PublicList = SQLCODE ]
{
	new %CallArgs, SQLCODE, %ROWID, %ROWCOUNT, %objlasterror
	try {
		if $Isobject($Get(%sqlcontext)) {
			set tStatementContext = ##class(%ProcedureContext).%New()
			merge tStatementContext.%LTT = %sqlcontext.%LTT, tStatementContext.TTNI = %sqlcontext.TTNI, tStatementContext.PTT = %sqlcontext.PTT
			new %sqlcontext
			set %sqlcontext = tStatementContext
		} else {
			new %sqlcontext
		}
		if $g($system.Context.SQL().ShardExecIUDArgs)'="" {
			kill parm 
			merge parm=$system.Context.SQL().ShardExecIUDArgs
			kill $system.Context.SQL().ShardExecIUDArgs
			do ..bindArguments(.parm,.%CallArgs)
		} else {
			set argcount=0,ptr=0,ptr2=0
			set tStatementArgs=i%%StatementActualArgs
			while $listnext(tStatementArgs,ptr,argType) {
				if '$listnext(tStatementArgs,ptr,argVal) ZT "BADARG"
				set argcount=argcount+1
				if argType="?" {
					if '$listnext(parm,ptr2,data) { throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Invalid Dynamic Statement Parameter") }
					set %CallArgs(argcount)=data
				} elseif argType="c" {
					set %CallArgs(argcount)=argVal
				} elseif argType="v",i%%StatementType '= 45 {
					set %CallArgs(argcount)=$Get(@argVal)
				}
			}
			#; Check if we were passed too many parameters for this query
			if $listnext(parm,ptr2,data) throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Dynamic SQL Execute, more parameter values passed than are specified in the dynamic statement")
		}
			// Update the select mode of the prepared statement object
		if ..%StatementType = 1 {
			set %objlasterror = ""
			set tResult = ..%PreparedStatement.%New(..%PreparedStatement,..%SelectMode,.%CallArgs)
			if '$Isobject($Get(tResult)) { throw ##class(%Exception.StatusException).CreateFromStatus($Select($Get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$SQLCode,-400,"Unknown error, possibly related to $ZE: "_$ZE))) }
		} else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$SQLCode,-400,"Statement not prepared"))
		}
	} catch tException {
		$$$ISEXCEPTIONINTERRUPTTHROW(tException)
		set tResult = ##class(%SQL.StatementResult).%New()
		set tResult.%StatementType = ..%StatementType
		if tException.%IsA("%Exception.SQL") { set tResult.%SQLCODE = tException.Code, tResult.%Message = tException.Data }
		elseif (tException.Name = "<UNDEFINED>") && (($Extract(tException.Data,1,6) = "%parm(")) { set tResult.%SQLCODE = -400, tResult.%Message = "Invalid Dynamic Statement Parameter" }
		else { set tResult.%SQLCODE = -400, tResult.%Message = "Exception caught during dSQL statement %Execute: "_tException.Name_$Select(tException.Data'="":" "_tException.Data,1:"") }
	}
	QUIT tResult
}

Method %MetadataGet() As %SQL.StatementMetadata [ Internal ]
{
	if (r%%Metadata = "") && ($IsObject(..%PreparedStatement)) {
		if ..%StatementType = 80 {
			set r%%Metadata = ..%PreparedStatement.%GetMetadata()
		} else {
			set tMDC = ..%PreparedStatement.#%statementmetadata
			for tPtr=0:1:tMDC { s tMetadata(tPtr) = $parameter(..%PreparedStatement,"%statementmetadata"_tPtr) }
			set r%%Metadata = ##class(%SQL.StatementMetadata).%New(..%StatementType,.tMetadata,..%PreparedStatement.#%statementparameters,..%PreparedStatement.#%statementobjects,..%StatementActualArgs,..%PreparedStatement.#%statementactual,..%PreparedStatement.#%statementmetadataext)
		}
	}
	quit r%%Metadata
}

/// Purges the just-used cached query for certain statement types, like DDL statements.
Method %OnClose() As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	try {
		if (..%StatementType>6 && (..%StatementType<20)) || ((..%StatementType>25) && (..%StatementType '= 45)) {	// AutoPurge statement (same as xDBC cached queries as defined in Compile^%SYS.SQLSRV)
			do PurgeRtn^%SYS.SQLSRV(..%PreparedStatement.%PackageName()_"."_..%PreparedStatement.%ClassName())
		   }
	}
	catch {}	// Don't care if Purge got an error
	Quit $$$OK
}

/// %OnNew accepts three optional parameters, the values of these three parameters are the initial values of %SelectMode, %SchemaPath and %Dialect.
Method %OnNew(pSelectMode As %RawString, pPath As %RawString, pDialect As %RawString) As %Status [ Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $get(pSelectMode) '= "" { set i%%SelectMode = pSelectMode }
	if $get(pPath) '= "" { set i%%SchemaPath = pPath }
	if $get(pDialect) '= "" { set i%%Dialect = pDialect }
	Quit $$$OK
}

/// Displays the details of the currently prepared statement.
Method %Display()
{
	if $IsObject(..%PreparedStatement) {
		write !,"Implementation class: ",$classname(..%PreparedStatement)
		write !,"           Arguments: "
		if ..%StatementActualArgs '= "" {
			write $List(..%StatementActualArgs,2)
			for tPtr = 4:2:$ListLength(..%StatementActualArgs) { write ",",$List(..%StatementActualArgs,tPtr) }
		}
		else { write "<<none>>" }
		write !,"      Statement Text: "
		if $Get(..%StatementText) = +$Get(..%StatementText) {
			for tPtr = 1:1:..%StatementText { write !,$Char(9),..%StatementText(tPtr) }
		}
		else { write ..%StatementText }
	}
	else { write "No statement currently prepared",! }
	write !
}

/// <p>
/// Returns the details of the currently prepared statement.
/// This method returns the implementation class, the statement text, and the actual arguments bound to
/// formal statement arguments.
/// </p>
/// <ul>
/// <li><var>pClassName</var> contains the name of the current statement's implementation class.</li>
/// <li><var>pStatementText</var> contains the statement text. This variable is either a simple string 
/// or an array of strings where pStatementText is the number of lines and pStatementText(line) 
/// is a line of statement text.</li>
/// <li><var>pArguments</var> is a <a href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$list</a> 
/// containing argument types and argument value in the form 
/// $list(arg1type, arg1value[, arg2type, arg2value...argNtype, argNvalue]).
/// There are three argument types: 'c' = constant, 'v' = host variable and '?' is a parameter. 
/// All three argument types are replaced by ? arguments during statement prepare to improve the 
/// efficiency of the statement cache. Only actual arguments of type '?' require a value
/// to be supplied when executing the statement.</li>
/// <li><var>pStatementType</var> is an integer value corresponding to the internal type number 
/// for the type of statement.  This type number is for internal use and subject to change.</li>
/// </ul>
/// <p>
/// This method returns 1 for success and 0 for failure. This method fails when no statement has been prepared.
/// </p>
Method %GetImplementationDetails(Output pClassName As %Library.String(MAXLEN=300), Output pStatementText As %Library.String(MAXLEN=""), Output pArguments As %Library.List, Output pStatementType As %Integer, Output pRuntimeClassName As %Library.String(MAXLEN=300), Output dpSingleStatementMode As %Boolean) As %Integer
{
	if $IsObject(..%PreparedStatement) {
		set pClassName = $classname(..%PreparedStatement)
		set pRuntimeClassName = $s((..%RTPCRuntimeCQName'=pClassName)&&(..%RTPCRuntimeCQName'=""):..%RTPCRuntimeCQName,1:"")
		set pArguments = ..%StatementActualArgs
		set pStatementType = ..%StatementType
		kill pStatementText
		merge pStatementText = ..%StatementText
		set dpSingleStatementMode=$parameter(..%PreparedStatement,"%dpsinglestatementmode")
		set tReturn = 1
	}
	else { set tReturn = 0 }
	quit tReturn
}

/// Returns the PATH string for a given class name. The PATH string is essentially the same
/// as a default schema that is determined from the compiled class. If no extra IMPORT or inheritance rules
/// are present, the default schema within a class context is determined from the class's package. IMPORT and
/// inheritance add additional items to the PATH.
ClassMethod %ClassPath(pClassName As %Library.String) As %Library.String(MAXLEN="")
{
	set tSchemaPath = $$DetermineSchemaName^%qarmac(pClassName)
	merge tImports = $$$comClassKeyRaw(pClassName,$$$cCLASSimportall)
	set tPackage = $Order(tImports(""))
	while tPackage '= "" {
		set tSchema = $g($$$PACKAGEsqlname(tPackage)) 
		if tSchema = "" {
			if tPackage = "User" { set tSchema="SQLUser" }
			else { set tSchema = $tr(tPackage,".","_") }
		}
		set tSchemaPath = tSchemaPath _ "," _ tSchema
		set tPackage = $Order(tImports(tPackage))
	}
	quit tSchemaPath
}

}
