/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// 	<b>This class has been superseded.</b> It will remain for compatibility with existing code and samples.
/// 	We recommend using <class>%SQL.Statement</class>.
/// </p>
/// <p>Cached ResultSet based on an SQL statement. This class only supports the SELECT statement.
/// </p>
Class %ResultSet.SQL Extends (%Library.IResultSet, %ResultSet.QuerySuper) [ System = 4 ]
{

/// %Prepare()
/// 
/// This method is different for each type of result set class. This method has two tasks. First, instantiate the correct
/// concrete result set class. For %ResultSet.SQL that means accepting the sql query text in the first parameter and
/// looking up the query implementation in the query cache. The second task is to prepare the resulting object for data
/// retrieval by the caller which is done in %OnNew. The assumption is that if the query requires any parameters
/// then the actual arguments are all literal or public variables.</p>
/// 
/// <p>For %ResultSet.SQL, the arguments are:
/// <table cols=2>
/// <tr><td width="20%" valign="top"><var>sqlStatement (byref)</var></td><td width="50%" valign="top">the SQL Select statement, either as a counted array or as a $$$NL delimited string;</td></tr>
/// <tr><td width="20%" valign="top"><var>returnError (byref)</var></td><td width="20%" valign="top">if an error occurs, this will be an oref of an instance of %SYSTEM.Error. That object has
/// a Status property as well as methods to convert that status value into message id's and text
/// from other error domains. If no error is detected during %Prepare then returnError is $$$NULLOREF;</td>
/// <tr><td width="20%" valign="top"><var>%importPackages</var></td><td width="20%" valign="top">this is a $list of package names to be used to resolve any unqualified names in the SELECT statement.<br>
/// For example, SELECT %ID from MyTable<br>If %importPackages contains "Sample" then the schema associated with the Sample package would be used
/// to qualify MyTable.</td></tr>
/// <tr><td width="20%" valign="top"><var>%args...</var></td><td width="20%" valign="top">variable number of argument values that correspond to '?' parameters contained in the sqlStatement.</td></tr>
/// </table></p>
/// <p>This method returns an instance of %Library.IResultSet in the generic case. In the case of %ResultSet.SQL, an instance of %ResultSet.SQL is returned.
/// <p>This method constructs a SaveSet containing objects that are part of the current %Save() for
/// persistent classes or %GetSwizzleObject for serial classes. A queue of objects to be saved or
/// serialized is also constructed. Only modified objects are included in the save queue. The value
/// (OID or serial value in OID form) of each object is also placed in the SaveSet.</p>
/// 
ClassMethod %Prepare(ByRef sqlStatement As %String(MAXLEN=""), ByRef returnError As %SYSTEM.Error, %importPackages As %RawString = "", %args...) As %ResultSet.SQL [ PublicList = (SQLCODE, resultSet, returnStatus) ]
{
	Quit $$%Prepare^%SYS.ResultSet(.sqlStatement,.returnError,%importPackages,%args...)
}

/// <p>%PrepareMetaData is similar to %Prepare except that no result set is instantiated. This
/// method returns a %ResultSet.MetaData object. Be aware that the implementation of this
/// method might cause the result set to be instantiated but that is up to the result set
/// class itself and no result set is actually returned by this method - only metadata.</p><br>
/// <table cols=2>
/// <tr><td width="20%" valign="top"><var>query</var></td><td width="50%" valign="top">This is the SQL SELECT statement</td></tr>
/// <tr><td width="20%" valign="top"><var>returnError</var></td><td width="50%" valign="top">If an error occurs this is returned by reference and is a %SYSTEM.Error object
/// with properties set to describe information about the error. %returnError.Status contains the %Status value.</td></tr>
/// <tr><td width="20%" valign="top"><var>importPackages</var></td><td width="50%" valign="top">This is a comma delimited list of packages to import. This is only relevant if the result set implementation is
/// generated and the query source might include unqualified names. The import packages list is used to resolve package/schema names for
/// unqualified names.</td></tr></table>
ClassMethod %PrepareMetaData(ByRef txtSQL As %String(MAXLEN=""), ByRef returnError As %SYSTEM.Error = "", importPackages As %RawString = "") As %ResultSet.MetaData
{
	set clsRS = $$Prepare^%SYS.ResultSet(.txtSQL,.returnError,importPackages,"","",.execute,,,1)
	If $isobject(clsRS)=1,'$isobject($get(returnError)) { set rsmd = clsRS.%PrepareMetaData("",.returnError,.importPackages) } else { set rsmd = $$$NULLOREF }
	quit rsmd
}

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %SerializeObject(ByRef serial As %Binary, partial As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ CodeMode = expression, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

Method %AddToSaveSet(depth As %Integer = 3, refresh As %Integer = 0, norecurseon As %String = "") As %Status [ CodeMode = expression, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

Method %RemoveFromSaveSet() As %Status [ CodeMode = expression, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
$$$OK
}

}
