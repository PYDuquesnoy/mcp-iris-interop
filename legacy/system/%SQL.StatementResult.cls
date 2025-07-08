/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occDynamicDispatch

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25SQL.Statement">Using Dynamic SQL</a>.</p>
/// <p><class>%SQL.StatementResult</class> is the result descriptor class, returned by the 
/// %Execute() and %ExecDirect() methods of <class>%SQL.Statement</class>. Use this class to 
/// examine the results of the query.
/// </p>
/// <p>
/// The content of a statement result object varies depending on the statement type and whether or not
/// the statement was successfully executed. The interface to the result object is the same for all statement
/// types but the content of the result object varies.
/// </p>
/// <p>
/// When retrieving results, first check for successful execution by examining <property>%SQLCODE</property>. 
/// If %SQLCODE is greater than or equal to zero, then the statement was successfully executed. 
/// Otherwise, the value of %SQLCODE contains the error code and
/// the <property>%Message</property> property might contain more information about the error. 
/// See <property>%SQLCODE</property> for additional comments.
/// <p>Many statements affect some number of rows.
/// The number of rows affected by the statement execution is contained in the <property>%ROWCOUNT</property> property.
/// For a SELECT statement, if the cursor is positioned after the last row, the value of <property>%ROWCOUNT</property> indicates the number of rows 
/// contained in the result set. At any other time, <property>%ROWCOUNT</property> contains the number of rows retrieved thus far. 
/// <property>%ROWID</property> is set to the RowID of the last record modified by the most recent INSERT, UPDATE, INSERT OR UPDATE, DELETE, 
/// or TRUNCATE TABLE operation. After an INSERT statement, the <property>%ROWID</property> property contains the system-assigned value of 
/// the RowID (Object ID) assigned to the new record. 
/// </p>
/// <p>
/// A successfully executed SELECT statement returns a single result set. The number of columns in the result
/// set is contained in <property>%ResultColumnCount</property>. A cursor (iterator) is available to retrieve rows from the result set.
/// To advance the cursor to the next row, call <method>%Next</method>. The initial position of the cursor is before the
/// first row. %Next() returns 1 to indicate that it is positioned on a row or 0 to indicate that it is positioned
/// after the last row (at the end of the result set). If the cursor is positioned after the last row, the value of %ROWCOUNT
/// indicates the number of rows contained in the result set. At any other time, %ROWCOUNT contains the number
/// of rows retrieved thus far. For more information on the result set interface refer to the <class>%SQL.IResultSet</class> class.
/// </p>
/// <p>
/// A CALL statement result might contain output values, including a return value and any parameters defined as INPUT-OUTPUT
/// or OUTPUT, as well as a collection of dynamic result sets. The <property>%OutputColumnCount</property> property indicates the number
/// of output values. You can retrieve individual output values by using the output value iterator - <method>%NextOutputValue</method>.
/// </p>
/// <p>
/// The following is an example of retrieving all of the output values returned by a procedure:
/// </p>
/// <example>
/// if result.%OutputColumnCount > 0 {
///    set tPosition = ""
///    set tValue = result.%NextOutputValue(.tPosition)
///    while tPosition '= "" {
///        write !,tPosition," = ",tValue
///        set tValue = result.%NextOutputValue(.tPosition)
///    }
/// } else { 
///    write !,"No output values returned."
/// }
/// </example>
/// <br><br>
/// <p>
/// In the above example, the value of <var>tPosition</var> is the position of the formal parameter whose value is returned
/// in <var>tValue</var>. If the procedure declares a return value then the return value is always at position <var>0</var>
/// (zero). Input parameters are not contained in the output values but the presence of an input parameter is reflected as
/// a gap in the output value position.
/// <p>
/// A CALL statement can also return dynamic result sets as a collection referred to as a <i>result set sequence</i>.
/// There are two mechanisms for accessing result sets - serial binding and parallel binding. Serial binding is automatically
/// used whenever any part of its interface is invoked. The serial binding interface consists of the
/// <property>%ResultColumnCount</property> property, a private property <property>%ProcCursor</property>, and the methods <method>%Next</method>, <method>%GetRow</method>, <method>%GetRows</method>, <method>%MoreResults</method>, <method>%GetMetadata</method>, <method>%Get</method>,
/// <method>%GetData</method>, <method>%Print</method> and several internal methods. The first reference to any of the serial binding interface members triggers
/// the first result set from the result set sequence to be bound to the <var>%ProcCursor</var> property and also to the <var>%CurrentResult</var> property.
/// Subsequent references to the serial binding interface operate on that result set. When the currently bound result set is completely
/// processed, you can invoke <method>%MoreResults</method> to retrieve the next result set from the result set sequence by calling <method>%NextResult</method> and then binding
/// that result to <property>%ProcCursor</property>.
/// </p>
/// <p>
/// The parallel binding interface is implemented as the <method>%NextResult</method> method and the <property>%CurrentResult</property> property. 
/// Each call to <method>%NextResult</method> returns an OREF to the next result set in the collection of dynamic
/// resultsets returned by the procedure. When all result sets have been returned then <method>%NextResult</method>
/// returns NULL (value = "" in COS). The result returned by <method>%NextResult</method> is also bound to the <property>%CurrentResult</property> property.
/// </p>
/// <p>
/// <property>%CurrentResult</property> always references the most recently bound result set and it can be used for direct access to that result set, bypassing the serial
/// binding interface. The user must be careful since both parallel binding (<method>%NextResult</method>) and serial binding (automatic and <method>%MoreResults</method>) affects
/// the value of <property>%CurrentResult</property>.
/// </p>
Class %SQL.StatementResult Extends %Library.RegisteredObject [ System = 2 ]
{

Parameter %statementmetadata;

Parameter %statementmetadataext;

Parameter %statementobjects;

Parameter %statementparameters;

Parameter %statementactual;

/// The dynamic statement type number as assigned by SQL. See <property>%StatementTypeName</property> for
/// statement type values.
Property %StatementType As %Library.Integer;

/// The statement type name, one of the following:
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
/// 	<tr><td>52</td><td>TUNE TABLE</td></tr>
/// 	<tr><td>53</td><td>DECLARE</td></tr>
/// 	<tr><td>54</td><td>CREATE MODEL</td></tr>
/// 	<tr><td>55</td><td>DROP MODEL</td></tr>
/// 	<tr><td>56</td><td>TRAIN MODEL</td></tr>
/// 	<tr><td>57</td><td>ALTER MODEL</td></tr>
/// 	<tr><td>58</td><td>VALIDATE MODEL</td></tr>
/// 	<tr><td>59</td><td>SET ML CONFIGURATION</td></tr>
/// 	<tr><td>60</td><td>CREATE ML CONFIGURATION</td></tr>
/// 	<tr><td>61</td><td>ALTER ML CONFIGURATION</td></tr>
/// 	<tr><td>62</td><td>DROP ML CONFIGURATION</td></tr>
/// 	<tr><td>63</td><td>FREEZE PLANS</td></tr>
/// 	<tr><td>64</td><td>UNFREEZE PLANS</td></tr>
/// 	<tr><td>65</td><td>PURGE</td></tr>
/// 	<tr><td>66</td><td>BUILD INDEX</td></tr>
/// 	<tr><td>67</td><td>CREATE AGGREGATE</td></tr>
/// 	<tr><td>68</td><td>DROP AGGREGATE</td></tr>
/// 	<tr><td>69</td><td>LOAD</td></tr>
/// 	<tr><td>70</td><td>CREATE SCHEMA</td></tr>
/// 	<tr><td>71</td><td>DROP SCHEMA</td></tr>
/// 	<tr><td>72</td><td>CREATE SERVER</td></tr>
/// 	<tr><td>73</td><td>ALTER SERVER</td></tr>
/// 	<tr><td>74</td><td>DROP SERVER</td></tr>
/// 	<tr><td>75</td><td>CREATE FOREIGN TABLE</td></tr>
/// 	<tr><td>76</td><td>ALTER FOREIGN TABLE</td></tr>
/// 	<tr><td>77</td><td>DROP FOREIGN TABLE</td></tr>
/// 	<tr><td>78</td><td>CANCEL QUERY</td></tr>
/// 	<tr><td>79</td><td>EXPLAIN</td></tr>
/// 	<tr><td>80</td><td>THROUGH</td></tr>
/// 	<tr><td>""</td><td>Anything not listed above</td></tr>
/// </table>
Property %StatementTypeName As %Library.String [ Calculated, SqlComputeCode = { set {*}=$$GetTypen^%SYS.SQLSRV({%StatementType}) }, SqlComputed ];

/// Contains additional information about an error reported as a negative value in <property>%SQLCODE</property>. Additional information is
/// not always available.
Property %Message As %Library.String(MAXLEN = 256);

/// Contains the number of rows affected by executing the statement. 
/// It is the responsibility of the stored procedure author to explicitly set %ROWCOUNT.<br><br>
/// For example:
/// <example>
/// &sql(UPDATE Person Set Name="Mo" WHERE Age > :number)
/// Set result.%SQLCODE=SQLCODE
/// Set result.%ROWCOUNT=%ROWCOUNT
/// </example>
Property %ROWCOUNT As %Library.Integer;

/// The value of the %ROWID. This may or may not be relevant. It is primarily used when a dynamic INSERT statement has
/// been executed. In that case, %ROWID contains the rowid of the last row inserted into the database by executing the statement.
Property %ROWID As %Library.String(MAXLEN = "");

/// Indicates whether or not the statement was executed successfully. If %SQLCODE is not negative, 
/// then the statement was successfully executed. Specifically, the successful completion values 
/// are 0 (successful completion) and 100 (the operation has either found no data or reached the 
/// end of the data). 
/// Otherwise, the value of %SQLCODE contains the error code (a negative number) and
/// the <property>%Message</property> property might contain more information about the error.
/// <p>Note that, in successful cases, the methods <method>%Execute</method> and <method>%ExecDirect</method> 
/// set the %SQLCODE property to 0, but there is no information yet to indicate the number of rows (which could be 0).
/// To know how many rows there are, it is necessary to call <method>%Next</method> to examine the results. 
/// If your application needs to test for the case where the query has no results, be sure to call %Next
/// at least once, even if you don't otherwise need to iterate through the results; <b>then</b> check
/// to see whether %SQLCODE is 100.</p>
Property %SQLCODE As %Library.Integer [ InitialExpression = 0 ];

/// Holds the OREF of the most recently bound result set. This property is set automatically by <method>%NextResult</method>.
/// Note that <method>%NextResult</method> is also invoked by <method>%MoreResults</method>.  Users should not ever set this property. 
/// This property is public for backward compatibility reasons.
Property %CurrentResult As %RawString;

/// The number of columns defined as RETURNVALUE, INPUT-OUTPUT or OUTPUT (method return value, byref and output parameters) by an
/// SQL invoked routine. This value is always zero unless the DYNAMIC_FUNCTION is CALL (<property>%StatementType</property> = 45).
Property %OutputColumnCount As %Library.Integer [ InitialExpression = 0 ];

/// A multidimensional property that contains the most recent values returned by a procedure call.
/// This property is not meant to be a replacement for the standard procedure formal argument interface but handles
/// situations where the return values are not conveniently returned to the caller using the various argument binding
/// algorithms (positional and by name). The values are placed in the %OutputValues array subscripted by the argument
/// position as defined by the SQL invoked routine. If the statement does not allocate a parameter to be bound to the
/// arguments defined by the SQL invoked routine then there is no value present in %OutputValues. The output value
/// iterator only returns values defined.
Property %OutputValues As %RawString [ Internal, MultiDimensional ];

/// The number of columns in the result set. This value is
/// always zero unless the current result is a RESULTSET object (instance of <class>%SQL.IResultSet</class>)
/// or a procedure context object (instance of <class>%Library.IProcedureContext</class>). For a CALL
/// statement result, this value represents the column count of the result set currently
/// bound using serial binding.
Property %ResultColumnCount As %Library.Integer [ InitialExpression = 0 ];

/// This is the link to the SQL-Invoked-Routine that produced this result. This property is for
/// internal use only and its use or continued presence is not guaranteed and cannot be assumed.
/// The %routine value is the ID of the SIR that produced this result and it is useful for retrieving
/// metadata, specifically the statement metadata that describes a virtual result set of the output
/// directed parameters defined by the routine.
Property %routine As %Library.String(MAXLEN = "") [ Internal ];

/// The cursor that is bound to a result set from
/// the result set sequence (RSS) returned by a dynamic CALL statement. For all statement
/// types other than CALL, this value is always the null OREF. This property is set automatically
/// on first access and by calling <method>%MoreResults</method> and <method>%NextResult</method>.
Property %ProcCursor As %SQL.IResultSet [ Private ];

/// Invokes <method>%NextResult</method> to return the next result object from a statement result object (aka 'context object') and
/// updates <property>%ProcCursor</property> with that value. This is called "serial binding". <property>%ResultColumnCount</property> is updated to reflect the number of columns
/// contained in the newly bound result. If a <property>%ProcCursor</property> was previously set to a result object then the reference to that result object was
/// removed. Under normal circumstances the previously bound result set is destructed.</p>
/// <p>If the new value of <property>%ProcCursor</property> is a valid result object,
/// then this method returns 1; otherwise it returns 0 to indicate that no more results are available.
Method %MoreResults() As %Integer [ CodeMode = expression ]
{
0
}

/// Advances to the next row in the result referenced by <property>%ProcCursor</property>. Returns 0 if the cursor is at the end of the 
/// result set. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the %Next call. <property>%SQLCODE</property> is also set by %Next.
/// This implementation is overridden by classes that implement the result set interface.
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer [ CodeMode = expression ]
{
0
}

/// Advances to the next row in the result referenced by <property>%ProcCursor</property>. Returns 0 if the cursor is at the end of the 
/// result set. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the <method>%GetRow</method> call. <property>%SQLCODE</property> is also set by <method>%GetRow</method>.
/// The row is returned in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> format by reference in the <parameter>Row</parameter> argument.  If %SQLCODE'=0, Row will be null ("").
/// This implementation is overridden by classes that implement the result set interface.
Method %GetRow(ByRef Row As %Library.List, ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer [ CodeMode = expression ]
{
0
}

/// Advances the next <parameter>Cnt</parameter> rows in the result referenced by <property>%ProcCursor</property>.  Returns 0 if the cursor is at the end of the 
/// result set. Note, when 0 is returned, it is likely there are rows returned in the <parameter>Rows</parameter> array.  An optional argument contains a <class>%Library.Status</class> value on return.  This %Status value
/// indicates success or failure of the <method>%GetRows</method> call. <property>%SQLCODE</property> is also set by %GetRows.
/// The rows are returned in an array of <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> values in the <parameter>Row</parameter> array argument.  If %SQLCODE'=0 for a row, that will be the end of the results.
/// <p>For example, suppose rset.%GetRows(10,.tenrows,.sc) is called:
/// <br>- If there are more then 10 rows remaining to be fetched from the result set, tenrows=10, tenrows(1)=$lb(first row's contents), ..., tenrows(10)=$lb(tenth row's contents), and <method>%GetRows</method> will return 1.
/// <br>- If there are 5 rows remaining to be fetched from the result set, tenrows=5, tenrows(1)=$lb(first row's contents), ..., tenrows(5)=$lb(fifth row's contents), and <method>%GetRows</method> will return 0.
/// <br>- If there are 0 rows remaining to be fetched from the result set, tenrows=0 and <method>%GetRows</method> will return 0.
/// <br><br>This implementation is overridden by classes that implement the result set interface.
Method %GetRows(Cnt As %Library.Integer, ByRef Rows As %Library.List, ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer [ CodeMode = expression ]
{
0
}

/// Returns the output value from the position following <var>pPosition</var>. If the caller
/// passed <var>pPosition</var> by reference then it will contain the position corresponding
/// to the output value returned. If the <var>pPosition</var> argument is NULL, then no values exist
/// beyond the value passed by the caller and the value returned is also NULL.
/// <p>The output value at position 0 is always the called routine's return value.</p>
Method %NextOutputValue(ByRef pPosition As %Integer = "") As %RawString
{
	set pPosition = $Order(..%OutputValues(pPosition))
	if pPosition '= "" { set tReturn = ..%OutputValues(pPosition) } else { set tReturn = "" }
	quit tReturn
}

/// Returns the next result object from a statement descriptor (aka 'context object'). Typically,
/// multiple results are only returned from an SQL invoked procedure. Such results are dynamic result sets whose
/// metadata is not available until retrieval time. %NextResult() for non-CALL statements simply returns NULL, indicating
/// that no more results are available. For an SQL invoked procedure that returns a single preplanned result set and
/// for SELECT statements (which return a single result set when successfully executed) this method returns the
/// current result set object when called for the first time. Subsequent calls return a null OREF.
Method %NextResult() As %Library.RegisteredObject
{
	set ..%CurrentResult = ""
	quit $$$NULLOREF
}

/// Returns the value of the column with the name <var>colname</var> in the current row of the result set.
/// <p>If <var>colname</var> is not a valid column name, this method throws a <PROPERTY DOES NOT EXIST> error.
Method %Get(colname As %String = "") As %Library.String [ Abstract ]
{
}

/// Returns the value of column <var>colnbr</var> in the current row of the result set.
Method %GetData(colnbr As %Integer = 0) As %Library.String [ Abstract ]
{
}

/// Returns the result set metadata as a %SQL.StatementMetadata instance.
Method %GetMetadata() As %SQL.StatementMetadata
{
	quit $$$NULLOREF
}

/// Dynamic property Get method dispatcher. This method is invoked whenever a property cannot
/// be resolved from the class descriptor.
Method %DispatchGetProperty(pProperty As %Library.String(MAXLEN=255)) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") || (tPROPERTY = "%SQLCODE") { quit ..%SQLCODE }
	elseif (tPROPERTY = "%ROWID") { quit ..%ROWID }
	elseif (tPROPERTY = "%ROWCOUNT") { quit ..%ROWCOUNT }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

Method %DispatchMethod(pMethod As %String, Args...)
{
	if $$$ucase(pMethod) = "%GETMETADATA" { quit ..%GetMetadata() }
	$$$ThrowMethodDoesNotExistError(pMethod)
}

/// Property dispatch method to catch references to 
/// virtual properties.
/// <p>This should not be called directly.</p>
Method %DispatchSetProperty(pProperty As %Library.String, pValue As %Library.String) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") || (tPROPERTY = "%SQLCODE") { set ..%SQLCODE = pValue }
	elseif (tPROPERTY = "%ROWID") { set ..%ROWID = pValue }
	elseif (tPROPERTY = "%ROWCOUNT") { set ..%ROWCOUNT = pValue }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

/// Displays the contents of the result object. If formatted display is available, then this method formats the results
/// using the requested format and, if appropriate, opens the formatted results using the host OS. The output
/// is directed to one or more files and messages are placed in a result set object. All file names used
/// are returned in an array. The arguments are as follows:
/// <ul>
/// <li><var>pFormat</var> - 
/// The format applied to the result content. This parameter is also used to determine the file name extension.</p>
/// The supported formats are:
///     <ul>
/// 	  <li>-1 = %Display() format</li>
/// 	  <li>0 = XML</li>
/// 	  <li>1 = HTML</li>
/// 	  <li>2 = PDF (requires a renderer such as FOP)</li>
/// 	  <li>99 = TXT</li>
/// 	  <li>100 = CSV (actually TAB-separated)</li>
///     </ul>
///     <p>If <var>pFormat</var> is specified as any number not listed above then it will default to TXT.</p>
///    	<p><var>pFormat</var> can also be specified as XML, HTML, PDF, TXT or CSV.</p>
/// 	<p><i>NOTE: <var>pFormat</var> of CSV/100 is not a true comma-separated value, but instead uses TAB separated values.</i></p>
/// </li>
/// <li><var>pFileName</var> - 
/// The base file name to be used to generate actual file names used for output. If no value is specified
/// then a file name will be generated, using the TEMP folder defined for the InterSystems IRIS instance.
/// This value is not expected to include an extension. An extension is added to this value to form the actual
/// file used. Also, if nested results exist then a number is appended to the file name specified to produce a unique
/// name for each result.</li>
/// <li><var>pMessages</var> - 
/// Instance of a system result set class. If no value is passed then the system message result class is instantiated.
/// This parameter is passed by reference. It is up to the caller to process the result set OREF that is returned.
/// pMessages.Count() returns the number of messages contained in the result set. pMessages.%Display() will display the
/// messages on the current device. pMessages.%DisplayFormatted() is also implemented and can be used to display the
/// messages using the selected format.</li>
/// <li><var>pFilesUsed</var> - 
/// This pass-by-reference parameter will contain the number of files used to display the result content and the name of
/// each file. pFilesUsed is the number of files and pFilesUsed(<var>file_number</var>) is the name of the file. The
/// sequence of the files is the same sequence as the results are processed. For simple result objects, there is a single
/// file. For context objects that can contain result set sequences, the results are output in the order they are returned
/// and the files used are present in pFilesUsed in that same order. </li>
/// <li><var>pTranslateTable</var> - 
/// This is the translate table used for the output files when the format is CSV or TXT. This parameter is optional. </li>
/// <li><var>pDelimiter</var> -
/// The delimiter to use between columns in the export file. This parameter is optional and defaults to tab character if not specified. </li>
/// </ul>
Method %DisplayFormatted(pFormat As %String = -1, pFileName As %String(MAXLEN="") = "", ByRef pMessages As %SQL.Manager.Messages = "", ByRef pFilesUsed As %String(MAXLEN="") = 0, pTranslateTable As %String(MAXLEN="") = "", pDelimiter As %String = {$c(9)})
{
#define NewFileRoot					$translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")
#define TempFilePath				##class(%File).NormalizeDirectory(##class(%ZEN.Report.reportPage).%GetTempDir())
	if '$IsObject(pMessages) { set pMessages = ##class(%SQL.Manager.Messages).%New() }
		// Convert a text pFormat to integer
	if +pFormat '= pFormat { set pFormat = $Case($$$ucase(pFormat),"XML":0,"HTML":1,"PDF":2,"CSV":100,:99) }
		// Get the OS. If the OS is not Windows or Unix then deliver the message that the file cannot
		// be automatically displayed.
	new %context,%count,%filter,%report
	try {
		if '(..%SQLCODE) { do pMessages.Insert(+(..%ROWCOUNT) _ " row(s) affected.") }
		else {
			do pMessages.Insert("[SQLCODE: <"_..%SQLCODE_">:<"_$$sqlcode^%apiSQL(..%SQLCODE)_">]")
			if ..%Message'="" {do pMessages.Insert("[%msg: <" _ ..%Message _ ">]") }
		}
	}
	catch tException {
		set tSQLCODE = tException.AsSQLCODE()
		set tSQLMessage = tException.AsSQLMessage()
		if '$IsObject($Get(pMessages)) {
			write !!,"[SQLCODE: <",tSQLCODE,">:<",$$sqlcode^%apiSQL(tSQLCODE),">]",!
			if tSQLMessage'="" { write "[%msg: <",tSQLMessage,">]",! }
		}
		else {
			do pMessages.Insert("[SQLCODE: <"_..%SQLCODE_">:<"_$$sqlcode^%apiSQL(..%SQLCODE)_">]")
			if ..%Message'="" {do pMessages.Insert("[%msg: <" _ ..%Message _ ">]") }
		}
	}
}

/// This is an abstract method. Refer to <class>%SQL.IResultSet</class> for the 
/// concrete method implemented for result set results.
Method %Print(pDelimiter As %String = " ") As %Status [ Abstract ]
{
	quit $$$OK
}

/// Displays the contents of this object on the current device.
Method %Display(pDelimiter As %String = {$Char(9)})
{
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]",! }
	}
	if ..%StatementType=69 { write "[LOAD DATA's %SQL_Diag.Result.ID: <"_..%ROWID_">]",! }
	write +(..%ROWCOUNT)," Row"_$Select(..%ROWCOUNT'=1:"s",1:"")_" Affected"
}

Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0, norecurseon As %String = "") As %Status [ CodeMode = expression, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ CodeMode = expression, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %RemoveFromSaveSet() As %Status [ CodeMode = expression, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

Method %SerializeObject(ByRef serial As %Binary, partial As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

}
