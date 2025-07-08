/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DocDB.Document

/// The <class>%SYSTEM.DocDB</class> class provides an interface for managing
/// Document Databases.<br>
/// <p>You can use it via the special <b>$SYSTEM</b> object:<br>
/// <p>You can call help to get a list of all entry points:<br>
/// <p>
/// <pre>
/// do $SYSTEM.DocDB.Help()
/// </pre>
/// </p>
Class %SYSTEM.DocDB Extends Help [ Abstract, System = 4 ]
{

/// Create a new Database in the current namespace. If a Database of that name already exists then return an error. 
/// Accepts Database Name, Document Type, and Resource. Return value is an oref referencing the Database definition 
/// object. 
ClassMethod CreateDatabase(databaseName As %String(MAXLEN="") = "", documentType As %String(MAXLEN=200), resource As %String(MAXLEN="")) As %DocDB.Database [ CodeMode = expression ]
{
##class(%DocDB.Database).%CreateDatabase(databaseName,.documentType,.resource)
}

/// Retrieve the Database definition, this includes the Name, Class, Resource and Document Type Class. If the requested Database does not exist then an exception is thrown. 
/// Returns an oref referencing the Database definition object. 
ClassMethod GetDatabase(databaseName As %String(MAXLEN="") = "") As %DocDB.Database [ CodeMode = expression ]
{
##class(%DocDB.Database).%GetDatabase(databaseName)
}

/// Return an array (<class>%Library.DynamicArray</class>) containing the names of all Databases defined in the current namespace. 
ClassMethod GetAllDatabases() As %Library.DynamicArray [ CodeMode = expression ]
{
##class(%DocDB.Database).%GetAllDatabases()
}

/// Delete the definition and currently visible extent of an existing Database. Return true if the Database exists and the drop is successful, 
/// false if the named Database does not exist. If an error is encountered during execution then an exception is thrown. 
ClassMethod DropDatabase(databaseName As %String(MAXLEN="") = "") As %Library.Boolean [ CodeMode = expression ]
{
##class(%DocDB.Database).%DropDatabase(databaseName)
}

/// Delete all Databases defined in the current namespace and their currently visible extent (user data). Returns an array containing 
/// the names of all Databases successfully dropped. 
ClassMethod DropAllDatabases() As %Library.DynamicArray [ CodeMode = expression ]
{
##class(%DocDB.Database).%DropAllDatabases()
}

/// <p>
/// Return 1 (true) if the <var>databaseName</var> database is defined in the current namespace, 0 (false) otherwise. 
/// </p>
ClassMethod Exists(databaseName As %RawString = "") As %Boolean
{
	return ##class(%DocDB.Database).xNExists(databaseName)
}

}
