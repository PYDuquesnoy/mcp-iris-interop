/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occDynamicDispatch

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.ResultSet Extends %RegisteredObject [ Abstract, System = 4 ]
{

Method Close() As %Status [ Abstract ]
{
}

/// Retrieves the fetch size for this ResultSet object.
Method GetFetchSize() As %Integer [ Abstract ]
{
}

/// Gets the value of the designated column in the current row of this ResultSet object as %ObjectHandle
Method GetObject(columnIndex As %Integer) As %ObjectHandle [ Abstract ]
{
}

/// Gives the driver a hint as to the number of rows that should be fetched from the database when more rows 
/// are needed for this ResultSet object.
Method SetFetchSize(rows As %Integer) [ Abstract ]
{
}

/// Reports whether the last column read had a value of SQL NULL.
Method WasNull() As %Boolean [ Abstract ]
{
}

/// Advance to the next row in the result referenced by <property>%ProcCursor</property>. Returns 0 if the cursor is at the end of the 
/// result set. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the %Next call. <property>%SQLCODE</property> is also set by %Next.
/// This implementation is overridden by classes that implement the result set interface.
Method Next() As %Library.Boolean [ Abstract ]
{
}

/// Advance to the next row in the result referenced by <property>%ProcCursor</property>. Returns 0 if the cursor is at the end of the 
/// result set. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the <method>%GetRow</method> call. <property>%SQLCODE</property> is also set by <method>%GetRow</method>.
/// The row is returned in $List format by reference in the <parameter>Row</parameter> argument.  If %SQLCODE'=0, Row will be null ("").
/// This implementation is overridden by classes that implement the result set interface.
Method GetRow() As %Library.List [ Abstract ]
{
}

/// Advance the next <parameter>rowCount</parameter> rows in the result referenced by <property>%ProcCursor</property>.  Returns 0 if the cursor is at the end of the 
/// result set. Note, when 0 is returned, it is likely there are rows returned in the <parameter>Rows</parameter> array.  An optional argument contains a <class>%Library.Status</class> value on return.  This %Status value
/// indicates success or failure of the <method>%GetRows</method> call. <property>%SQLCODE</property> is also set by %GetRows.
/// The rows are returned in an array of $List values in the <parameter>Row</parameter> array argument.  If %SQLCODE'=0 for a row, that will be the end of the results.
/// <p>For example, suppose rset.%GetRows(10,.tenrows,.sc) is called:
/// <br>- If there are more then 10 rows remaining to be fetched from the result set, tenrows=10, tenrows(1)=$lb(first row's contents), ..., tenrows(10)=$lb(tenth row's contents), and <method>%GetRows</method> will return 1.
/// <br>- If there are 5 rows remaining to be fetched from the result set, tenrows=5, tenrows(1)=$lb(first row's contents), ..., tenrows(5)=$lb(fifth row's contents), and <method>%GetRows</method> will return 0.
/// <br>- If there are 0 rows remaining to be fetched from the result set, tenrows=0 and <method>%GetRows</method> will return 0.
/// <br><br>This implementation is overridden by classes that implement the result set interface.
Method GetRows(rowCount As %Library.Integer) As %Library.Integer [ Abstract ]
{
}

/// Returns the current row buffer to the caller
/// This method will refuse to return the buffer if there result set is already
/// being iterated over by cursor (if the cursor is not before the start of the result set)
Method GetBuffer(ByRef moreBuffers As %Boolean) As %Library.List [ Abstract ]
{
}

///  Returns the value of the column with the name <var>colname</var> in the current row of the result set.
///  <p>If <var>colname</var> is not a valid column name, this method throws a <PROPERTY DOES NOT EXIST> error.
Method Get(colname As %RawString = "") As %Library.RawString [ Abstract ]
{
}

/// Return the result set metadata as a <class>%XDBC.Gateway.ResultSetMetadata</class> instance.
Method GetMetaData() As %XDBC.Gateway.ResultSetMetaData
{
	quit ..%rsmd
}

/// Dynamic property Get method dispatcher. This method is invoked whenever a property cannot
/// be resolved from the class descriptor.
Method %DispatchGetProperty(pProperty As %Library.String(MAXLEN=255)) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") { quit i%%SQLCODE }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %Library.String, pValue As %Library.String) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") { set i%%SQLCODE = pValue }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
}

/// %StatementType is the dynamic statement type number as assigned by SQL. Refer to %StatementTypeName for
/// statement type values.
Property %StatementType As %Library.Integer;

/// <p>%StatementTypeName is the statement type name.</p>
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
/// 	<tr><td>67</td><td>LOAD</td></tr>
/// 	<tr><td>""</td><td>Anything not list above</td></tr>
/// </table>
Property %StatementTypeName As %Library.String [ Calculated, SqlComputeCode = { set {*}=$$GetTypen^%SYS.SQLSRV({%StatementType}) }, SqlComputed ];

/// %Message contains additional information about an error reported as a negative value in <property>%SQLCODE</property>. Additional information is
/// not always available.
Property %Message As %Library.String(MAXLEN = 256);

/// Contains the number of rows affected by executing the statement.<br>
/// It is the responsibility of the stored procedure author to explicitly set %ROWCOUNT.<br><br>
/// For example:
/// <br>
/// <p>
/// &amp;sql(UPDATE Person Set Name="Mo" WHERE Age &gt; :number)<br>
/// Set result.%SQLCODE=SQLCODE<br>
/// Set <b>result.%ROWCOUNT</b>=%ROWCOUNT
/// <br>
Property %ROWCOUNT As %Library.Integer;

/// The value of the %ROWID. This may or may not be relevant. It is primarily used when a dynamic INSERT statement has
/// been executed. In that case, %ROWID contains the rowid of the last row inserted into the database by executing the statement.
Property %ROWID As %Library.String(MAXLEN = "");

/// <p>
/// %SQLCODE indicates whether or not the statement was executed successfully. If %SQLCODE is not negative (greater than or equal to zero)
/// then the statement was successfully executed. Otherwise, the value of %SQLCODE contains the error code and
/// the %Message property might contain more information about the error.
/// </p>
Property %SQLCODE As %Library.Integer [ InitialExpression = 0 ];

/// Holds oref of the most recently bound result set. This property is set automatically by <method>%NextResult</method>.
/// Note that <method>%NextResult</method> is also invoked by <method>%MoreResults</method>.  Users should not ever set this property. 
/// This property is public for backward compatibility reasons.
Property %CurrentResult As %RawString;

/// %OutputColumnCount is the number of columns defined as RETURNVALUE, INPUT-OUTPUT or OUTPUT (method return value, byref and output parameters) by an
/// SQL invoked routine. This value is always zero unless the DYNAMIC_FUNCTION is CALL (<property>%StatementType</property> = 45).
Property %OutputColumnCount As %Library.Integer [ InitialExpression = 0 ];

/// %OutputValues is a multidimensional property that contains the most recent values returned by a procedure call.
/// This property is not meant to be a replacement for the standard procedure formal argument interface but handles
/// situations where the return values are not conveniently returned to the caller using the various argument binding
/// algorithms (positional and by name). The values are placed in the %OutputValues array subscripted by the argument
/// position as defined by the SQL invoked routine. If the statement does not allocate a parameter to be bound to the
/// arguments defined by the SQL invoked routine then there is no value present in %OutputValues. The output value
/// iterator only returns values defined.
Property %OutputValues As %RawString [ Internal, MultiDimensional ];

/// %ResultColumnCount is the number of columns in the result set. This value is
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

/// %ProcCursor is the cursor that is bound to a result set from
/// the result set sequence (RSS) returned by a dynamic CALL statement. For all statement
/// types other than CALL, this value is always the null oref. This property is set automatically
/// on first access and by calling <method>%MoreResults</method> and <method>%NextResult</method>.
Property %ProcCursor As %SQL.IResultSet [ Private ];

/// This property holds a generic xDBC representation of the result set's metadata.
Property %rsmd As %XDBC.Gateway.ResultSetMetaData [ Internal, Private ];

/// DO NOT USE DIRECTLY -- serialized version of <property>%rsmd</property>
/// For compatibility with %SQL.IResultSet only
Property %Metadata As %Library.String(MAXLEN = "") [ Internal, MultiDimensional ];

Method %InitializeMetadata(rsmd As %XDBC.Gateway.ResultSetMetaData) As %Status [ Internal, Private ]
{
	set ..%rsmd = rsmd,
		..%ResultColumnCount = rsmd.GetColumnCount()
	quit $$$OK
}

/// See <method>Get</method>
Method %Get(colName As %String) As %Boolean [ Internal ]
{
	quit ..Get(colName)
}

/// See <method>GetData</method>
Method %GetData(colindex As %String) As %Boolean [ Internal ]
{
	quit ..GetData(colindex)
}

/// See <method>Next</method>
Method %Next(Output status As %Status) As %Boolean [ Internal ]
{
	set status = $$$OK
	quit ..Next()
}

/// Formated display all data 
Method %Display(pDelimiter As %String = {$Char(9)}, colAlign As %Integer = 0) [ Internal ]
{
#DEFINE SQLColLengthDefault 20
#DEFINE SQLColLengthMaxDisplay 128
	set rsmd = ..GetMetaData()
	set columns = rsmd.GetColumnCount()
	for i=1:1:columns {
		set colHead = rsmd.GetColumnName(i)
		if colAlign>0 {	// --- Collect Metadata Information & Align Column Headers ---
			set colHeadLen=$l(colHead)
			if colAlign=1 {
                set colDispLen=colHeadLen
            } elseif colAlign=2 {
                set colDispLen=rsmd.GetPrecision(i)
                set:colDispLen="" colDispLen=$$$SQLColLengthDefault
                set:colDispLen>$$$SQLColLengthMaxDisplay colDispLen=$$$SQLColLengthMaxDisplay
                set:colHeadLen>colDispLen colDispLen=colHeadLen
            } else {
                 set colDispLen=colHeadLen
            }
			set $LIST(metadata(0,i),1,4)=$LB(colHead,colHead,colHeadLen,colDispLen)
			set colHeadPadding=$j("",colDispLen-colHeadLen)
			write colHead,colHeadPadding
		} else {
            write colHead
        }
		write:i'=columns pDelimiter	// Don't write out extra delimiter after last column name
 	}
	if columns { write ! }
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]" }
	}
	else {
		while ..%Next() { do ..%Print(pDelimiter,colAlign,.metadata) }
		if ..%SQLCODE < 0 {
			write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
			if ..%Message'="" { write "[%msg: <",..%Message,">]" }
		}
	}
	write !,+(..%ROWCOUNT)," Rows(s) Affected"
}

///  <p>Write the current row to the current device. An optional column delimiter can be
///  specified. No formatting is applied other than writing <var>pDelimiter</var> between
///  column values. This can be useful for exporting result set data to tab delimited files.</p>
///  <p>For example:</p><p></p>
///  <example>
///  set sql = "select name,home_street,home_city,home_state,home_zip from sample.person"
///  set rset = ##class(%ResultSet.SQL).%Prepare(.sql,.err,"")
///  if '$Isobject(err) {
///  	set file="c:\temp\names.asv"
///  	open file:"WNS"
///  	use file while rset.%Next() { do rset.%Print($char(9)) } 
///  	close file
///  }
///  </example>
///  <p><p>
///  Example data:
///  <table>
///  <tr><td>Cornell,Ezra M.</td><td>340 Franklin Court</td><td>Sarasota</td><td>NY</td><td>12866</td></tr>
///  <tr><td>Huff,Stephen A.</td><td>548 Washington Blvd</td><td>Brownfield Center</td><td>MD</td><td>53436</td></tr>
///  <tr><td>Sands,Jeep Q.</td><td>7298 Washington Drive</td><td>Xavier</td><td>WY</td><td>23685</td></tr>
///  </table>
Method %Print(pDelimiter As %String = " ", colAlign As %Integer = 0, ByRef metadata As %ArrayOfObjects) As %Status [ Internal ]
{
    #dim rsmd as %XDBC.Gateway.ResultSetMetaData
	set rsmd = ..GetMetaData()
	set columns = rsmd.GetColumnCount()
	if columns {
		set tValue = ..%GetData(1)
		if (tValue [ pDelimiter)  || (tValue [ $Char(10)) { set tValue = $zu(144,1,tValue) }
		try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
		if colAlign>0 {	// --- Align Column Data ---
			set colDispLen=$LG(metadata(0,1),4)
			write tValue,$j("",colDispLen-$l(tValue))
		}
		else { write tValue }
		for tPtr = 2:1:columns {
			set tValue = ..%GetData(tPtr)
			if (tValue [ pDelimiter)  || (tValue [ $Char(10)) { set tValue = $zu(144,1,tValue) }
			try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
			if colAlign>0 {	// --- Align Column Data ---
				set colDispLen=$LG(metadata(0,tPtr),4)
				write pDelimiter,tValue,$j("",colDispLen-$l(tValue))
			}
			else { write pDelimiter,tValue }
		}
		write !
	}
	quit $$$OK
}

/// Return metadata as a <class>%SQL.StatementMetadata</class> object
Method %GetMetadata() As %SQL.StatementMetadata
{
	do ..%GetClientMetadata(.md)
	quit ##class(%SQL.StatementMetadata).%New(1, .md)
}

///  This method returns the rowtype metadata, serialized for transport to clients. Its structure is based
///  on the value of the public variable '%protocol' at the time the result set is instantiated.
Method %GetClientMetadata(ByRef pMetadata As %RawString = "") As %Status [ Final ]
{
	kill pMetadata
	if '$d(..%Metadata) {
		set status = ..%rsmd.ToSQLMetadata(.pMetadata)
		quit:$$$ISERR(status) status
		merge ..%Metadata = pMetadata
	} else {
		merge pMetadata = ..%Metadata
	}
	quit $$$OK
}

///  Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer [ Internal ]
{
	// DP-427293 - basic implementation
	for {
		if ..%Next() {
			set SQLCODE=0
				#; Don't need a %protocol check here because there is no way for the values to be <UNDEFINED>, which would snd an 01/null instead of an 0201/null.
				#; Old logic that uses $zobjexport(...,7) would have had the same issue (or maybe gotten an <UNDEFINED> error at runtime.
			quit:$zobjexport(..GetRow(),60)
		}
		else {
			set SQLCODE=100
			if $d(sc)#2,$$$ISERR(sc) { set SQLCODE=-400,%msg=$$GetErrorText^%apiOBJ(sc) }
			quit
		}
	}
	QUIT SQLCODE
}

///  Fetch and send all row's data to the ^IRIS.Temp.IRIS.Sql() global, used by %PARALLEL union queries. For internal use only.
Method %FetchIntoTemp() As %Library.Integer [ Abstract, Internal ]
{
}

///  Fetch and send a series of rows for continuous query client. For internal use only.
Method %SendDelimitedRows(pMaxRows As %Integer = 0, pDelimiter As %String = "", ByRef pReturnCount As %Integer = 0) As %Status [ Abstract, Internal ]
{
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
