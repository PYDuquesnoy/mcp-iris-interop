/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Abstract version of the resultset which specific implementations of result sets inherit from.</p>
/// <p>
/// A result set is a type of result returned by executing either a SELECT statement or a CALL statement. 
/// Please refer to <class>%SQL.Statement</class> and <class>%SQL.StatementResult</class> for more 
/// information on how to prepare dynamic SQL statements and how to process the results the 
/// of executing them. 
/// </p>
Class %Library.AbstractResultSet Extends %IResultSet [ Abstract, System = 2 ]
{

/// Use this method to set the SQL runtime mode for the query to be
/// executed.  Setting the runtime mode for this ResultSet does not
/// permanently change the $zu(115,5) value.  Possible values mode are:
/// <ul>
/// <li> 0 for LOGICAL mode.
/// <li> 1 for ODBC mode.
/// <li> 2 for DISPLAY mode.
/// <li> "" to use the process wide $zu(115,5) value.
/// </ul>
Property RuntimeMode As %String;

/// Used to store the data returned from the resultset by column name. This can
/// be accessed directly for more performance than the <method>Get</method> and
/// <method>GetDataByName</method> as it avoids a method call. For example code
/// that said:
/// <example>
/// While result.Next() {
/// 	Write result.Get("Name"),result.Get("Salary"),!
/// }
/// 
/// ; Becomes this faster code
/// 
/// While result.Next() {
/// 	Write $get(result.Data("Name")),$get(result.Data("Salary")),!
/// }
/// </example>
/// Note that as this 'Data' property is multidimensional if there
/// is no such column name as 'Salary' you will get an UNDEFINED error without
/// the $get around it. If
/// there are two columns with the same name in the result set then the second
/// one will be the one referenced by the 'Data' property. If you need to refer
/// to both of them use the <method>GetData</method> and give the position
/// of the column you want.
Property Data As %String [ MultiDimensional ];

/// Use this method with <b>dynamic</b> queries to provide the query to be 
/// executed. In the case of the <nobr><var>%DynamicQuery:SQL</var></nobr> query, <var>p1</var> 
/// is a string containing an SQL query. The query may contain parameters represented 
/// by <b>?</b> characters within the query. The values of any parameters are 
/// supplied via the <method>Execute</method> method. For example:
/// <example>
/// Set result=##class(%ResultSet).%New("%DynamicQuery:SQL")
/// 
/// Do result.Prepare("SELECT Name,City FROM Person WHERE Name %STARTSWITH ? AND City = ?")
/// 
/// Do result.Execute("A","Boston")
/// While result.Next() {
/// Write result.Data("Name"),result.Data("City"),!
/// }
/// </example>
Method Prepare(args...) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Executes the current query.
/// <p>The arguments <var>p1...</var> supply the value of any parameters the 
/// query may have.
Method Execute(args...) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// alias for new result set interface
Method %Execute(args...) As %Library.Status [ CodeMode = call ]
{
..Execute(args...)
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.
Method Next(ByRef sc As %Status) As %Integer
{
	Quit 0
}

Method %Next(ByRef sc As %Status) As %Integer [ CodeMode = call ]
{
..Next(.sc)
}

/// Returns the value of column <var>n</var> in the current row of the result set.
Method GetData(n As %Integer) As %String [ Abstract ]
{
	Quit ""
}

Method %GetData(n As %Integer) As %String [ CodeMode = call ]
{
..GetData(.n)
}

/// Returns the value of the column with the name <var>name</var> in the current row of the result set.
/// <p>If <var>name</var> is not a valid column name, this method returns an empty string.
/// Look at updating the code to use the <property>Data</property> multidimensional property to
/// access the fields faster than using this method call.
Method Get(name As %String) As %String [ Abstract ]
{
	Quit ""
}

Method %Get(name As %String) As %String [ CodeMode = call ]
{
..Get(.name)
}

/// Returns the value of the column with the name <var>name</var> in the current row of the result set.
/// <p>If <var>name</var> is not a valid column name, this method returns an empty string.
/// <p>Note: this method has been superceded by the equivalent <method>Get</method> method.
Method GetDataByName(name As %String) As %String [ Abstract ]
{
	Quit ""
}

/// If this query returns the object Id then return the oref you get from
/// opening an object with this id.
Method GetObject() As %RegisteredObject [ Abstract ]
{
	Quit $$$NULLOREF
}

/// Closes the current result set cursor.
Method Close() As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Returns the number of columns in the result set.
Method GetColumnCount() As %Integer [ Abstract ]
{
0
}

/// Returns the name of column <var>n</var> in the result set.
Method GetColumnName(n As %Integer) As %String [ Abstract ]
{
	Quit ""
}

/// Returns the column header for column <var>n</var> in the result set.
Method GetColumnHeader(n As %Integer) As %String [ Abstract ]
{
	Quit ""
}

/// Returns the number of input parameters for the current query.
Method GetParamCount() As %Integer [ Abstract, CodeMode = expression ]
{
0
}

/// Returns the name of input parameter <var>n</var> for the current query.
Method GetParamName(n As %Integer) As %String [ Abstract, CodeMode = expression, ProcedureBlock = 1 ]
{
""
}

/// Returns true (1) if the ClassName and QueryName properties of this 
/// <nobr><b>%ResultSet</b></nobr> object refer to a valid class query. 
/// Otherwise it returns false (0).
Method QueryIsValid() As %Integer [ Abstract, CodeMode = expression ]
{
0
}

/// If the current query contains an object Id (based on the CONTAINSID parameter
/// being set), return the column position of the object Id.  
/// Otherwise return 0.
Method ContainsId() As %Integer [ Abstract, CodeMode = expression ]
{
0
}

/// The name of the extent that this query will return Id values from (based on the EXTENT parameter
/// being set). Only returns a value if the query contains Id values.
Method GetExtent() As %String [ Abstract, CodeMode = expression ]
{
""
}

/// This is a diagnostic function; it runs the specified query and prints the output to the console.
ClassMethod RunQuery(ClassName As %String, QueryName As %String, args...)
{
	If $get(ClassName)="" Read !,"Class >",ClassName If ClassName="" Quit
	If $get(QueryName)="" Read !,"Query >",QueryName If QueryName="" Quit
	
	Set rs=##class(%ResultSet).%New(ClassName_":"_QueryName)
	Set sc=rs.Execute(args...)
	If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit
	
	Set columns=rs.GetColumnCount()
	Write ! For i=1:1:columns Write rs.GetColumnHeader(i),":"
	For  Quit:rs.Next(.sc)=0  if $$$ISOK(sc) { Write ! For i=1:1:columns Write rs.GetData(i),":" } else { quit }
	if $$$ISERR(sc) do $system.OBJ.DisplayError(sc)
}

}
