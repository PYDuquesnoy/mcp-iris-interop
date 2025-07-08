/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ResultSet.MD.Column Extends %SerialObject [ StorageStrategy = resultCol, System = 2 ]
{

Property colName As %String(MAXLEN = 255);

Property ODBCType As %Integer;

Property precision As %Integer;

Property scale As %Integer;

Property isNullable As %Boolean;

Property label As %String(MAXLEN = 255);

Property tableName As %String;

Property schemaName As %String;

Property qualifier As %String;

Property isAutoIncrement As %Boolean;

Property isCaseSensitive As %Boolean;

Property isCurrency As %Boolean;

Property isReadOnly As %Boolean;

Property isRowVersion As %Boolean;

Property isUnique As %Boolean;

Property isAliased As %Boolean;

Property isExpression As %Boolean;

Property isHidden As %Boolean;

Property isIdentity As %Boolean;

Property isKeyColumn As %Boolean;

Property isRowId As %Boolean;

Property propertyId As %String(MAXLEN = 255);

/// Returns the type of column <var>n</var> in the result set where type is an integer associated with
/// the client datatype. If the type cannot be determined, 0 (zero) is returned.
/// <table>
/// <tr><td>1<td><td>BINARY</td></tr>
/// 	<tr><td>2<td><td>DATE</td></tr>
/// 	<tr><td>3<td><td>DOUBLE</td></tr>
/// 	<tr><td>4<td><td>HANDLE</td></tr>
/// 	<tr><td>5<td><td>INTEGER</td></tr>
/// 	<tr><td>6<td><td>LIST</td></tr>
/// 	<tr><td>7<td><td>LONGVARCHAR</td></tr>
/// 	<tr><td>8<td><td>TIME</td></tr>
/// 	<tr><td>9<td><td>TIMESTAMP</td></tr>
/// 	<tr><td>10<td><td>VARCHAR</td></tr>
/// 	<tr><td>11<td><td>STATUS</td></tr>
/// 	<tr><td>12<td><td>BINARYSTREAM</td></tr>
/// 	<tr><td>13<td><td>CHARACTERSTREAM</td></tr>
/// 	<tr><td>14<td><td>NUMERIC</td></tr>
/// 	<tr><td>15<td><td>CURRENCY</td></tr>
/// 	<tr><td>16<td><td>BOOLEAN</td></tr>
/// 	<tr><td>17<td><td>OID</td></tr>
/// 	<tr><td>18<td><td>BIGINT</td></tr>
/// 	<tr><td>19<td><td>FDATE</td></tr>
/// 	<tr><td>20<td><td>FTIMESTAMP</td></tr>
/// </table>
Property clientType As %Integer;

Method IsNumeric() As %Boolean [ CodeMode = expression ]
{
$case(..clientType,3:1,5:1,14:1,15:1,18:1,:0)
}

Storage resultCol
{
<Data name="resultState">
<Value name="1">
<Value>colName</Value>
</Value>
<Value name="2">
<Value>ODBCType</Value>
</Value>
<Value name="3">
<Value>precision</Value>
</Value>
<Value name="4">
<Value>scale</Value>
</Value>
<Value name="5">
<Value>isNullable</Value>
</Value>
<Value name="6">
<Value>label</Value>
</Value>
<Value name="7">
<Value>tableName</Value>
</Value>
<Value name="8">
<Value>schemaName</Value>
</Value>
<Value name="9">
<Value>qualifier</Value>
</Value>
<Value name="10">
<Value>isAutoIncrement</Value>
</Value>
<Value name="11">
<Value>isCaseSensitive</Value>
</Value>
<Value name="12">
<Value>isCurrency</Value>
</Value>
<Value name="13">
<Value>isReadOnly</Value>
</Value>
<Value name="14">
<Value>isRowVersion</Value>
</Value>
<Value name="15">
<Value>isUnique</Value>
</Value>
<Value name="16">
<Value>isAliased</Value>
</Value>
<Value name="17">
<Value>isExpression</Value>
</Value>
<Value name="18">
<Value>isHidden</Value>
</Value>
<Value name="19">
<Value>isIdentity</Value>
</Value>
<Value name="20">
<Value>isKeyColumn</Value>
</Value>
<Value name="21">
<Value>isRowId</Value>
</Value>
<Value name="22">
<Value>propertyId</Value>
</Value>
<Value name="23">
<Value>clientType</Value>
</Value>
</Data>
<State>resultState</State>
<StreamLocation>^%SQL.StatementColumnS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
