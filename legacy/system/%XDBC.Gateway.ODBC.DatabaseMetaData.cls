/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XDBC.Gateway.ODBC.DatabaseMetaData Extends %XDBC.Gateway.DatabaseMetaData [ System = 4 ]
{

Property connection As %XDBC.Gateway.ODBC.Connection;

Method %OnNew(conn As %XDBC.Gateway.ODBC.Connection) As %Status
{
    set ..connection = conn
    return $$$OK
}

/// Retrieves the name and version number of this database
Method GetDatabaseProductNameAndVersion() As %String
{
	set ret = ..connection.connection.GetInfo(7)
	return ret
}

Method GetDriverName() As %String
{
	set ret = ..connection.connection.GetInfo(6)
	return ret
}

/// Retrieves the version number of this driver as a String
Method GetDriverVersion() As %String
{
	set ret = ..connection.connection.GetInfo(77)
	return ret
}

/// Retrieves the catalog names available in this database.
Method GetCatalogs() As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.Tables("","","","")
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the access rights for a table's columns.
Method GetColumnPrivileges(catalog As %String, schema As %String, table As %String, columnNamePattern As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.ColumnPrivileges(catalog,schema,table,"")
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of table columns available in the specified catalog
Method GetColumns(catalog As %String, schemaPattern As %String, tableNamePattern As %String, columnNamePattern As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.Columns(catalog,schemaPattern,tableNamePattern,columnNamePattern)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of all the data types supported by this database.
Method GetTypeInfo() As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.GetTypeInfo(0)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the foreign key columns in the given foreign key table that reference the primary key or the columns representing a unique constraint of the parent table (could be the same or a different table)
Method GetCrossReference(parentCatalog As %String, parentSchema As %String, parentTable As %String, foreignCatalog As %String, foreignSchema As %String, foreignTable As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.ForeignKeys(parentCatalog,parentSchema,parentTable,foreignCatalog,foreignSchema,foreignTable)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the foreign key columns that reference the given table's primary key columns (the foreign keys exported by a table).
Method GetExportedKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.ForeignKeys(catalog,schema,table,"","","")
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves the string used to quote SQL identifiers.
Method GetImportedKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.ForeignKeys("","","",catalog,schema,table)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the given table's primary key columns.
Method GetPrimaryKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.PrimaryKeys(catalog,schema,table)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the given catalog's stored procedure parameter and result columns.
Method GetProcedureColumns(catalog As %String, schemaPattern As %String, procedureNamePattern As %String, columnNamePattern As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.ProcedureColumns("",catalog,schemaPattern,columnNamePattern)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a description of the stored procedures available in the given catalog.
Method GetProcedures(catalog As %String, schemaPattern As %String, procedureNamePattern As %String) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.Procedures(catalog,schemaPattern,procedureNamePattern)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Retrieves a comma-separated list of math functions available with this database.
Method GetNumericFunctions() As %String
{
	;return ..connection.GetInfo(49)
	return "SQL_FN_NUM_ABS,SQL_FN_NUM_PI,SQL_FN_NUM_POWER,SQL_FN_NUM_SIGN,SQL_FN_NUM_SQRT,"_
			"SQL_FN_NUM_ACOS,SQL_FN_NUM_ASIN,SQL_FN_NUM_ATAN,SQL_FN_NUM_CEILING,SQL_FN_NUM_COS,SQL_FN_NUM_COT,"_
			"SQL_FN_NUM_EXP,SQL_FN_NUM_FLOOR,SQL_FN_NUM_LOG,SQL_FN_NUM_LOG10,SQL_FN_NUM_MOD,SQL_FN_NUM_SIN,"_
			"SQL_FN_NUM_TAN,SQL_FN_NUM_TRUNCATE,SQL_FN_NUM_ROUND"
}

/// Retrieves a comma-separated list of string functions available with this database.
Method GetStringFunctions() As %String
{
	;return ..connection.GetInfo(50)
	return "SQL_FN_STR_ASCII,SQL_FN_STR_CHAR,SQL_FN_STR_CONCAT,SQL_FN_STR_LCASE,SQL_FN_STR_LEFT,"_
			"SQL_FN_STR_LENGTH,SQL_FN_STR_LTRIM,SQL_FN_STR_RIGHT,SQL_FN_STR_RTRIM,SQL_FN_STR_UCASE,"_
			"SQL_FN_STR_SUBSTRING,SQL_FN_STR_REPEAT,SQL_FN_STR_SPACE"
}

/// Retrieves a description of the user-defined type (UDT) hierarchies defined in a particular schema in this database.
Method GetSystemFunctions() As %String
{
	;return ..connection.GetInfo(51)
	return "SQL_FN_SYS_IFNULL"
}

/// Retrieves the table types available in this database.
/// Retrieves a comma-separated list of the time and date functions available with this database.
Method GetTimeDateFunctions() As %String
{
	;return ..connection.GetInfo(52)
	return "SQL_FN_TD_CURDATE,SQL_FN_TD_CURTIME,SQL_FN_TD_DAYNAME,SQL_FN_TD_DAYOFMONTH,SQL_FN_TD_DAYOFWEEK,"_
		"SQL_FN_TD_DAYOFYEAR,SQL_FN_TD_HOUR,SQL_FN_TD_MINUTE,SQL_FN_TD_MONTH,SQL_FN_TD_MONTHNAME,"_
		"SQL_FN_TD_NOW,SQL_FN_TD_QUARTER,SQL_FN_TD_SECOND,SQL_FN_TD_WEEK,SQL_FN_TD_YEAR,SQL_FN_TD_TIMESTAMPADD,"_
		"SQL_FN_TD_TIMESTAMPDIFF"
}

/// Retrieves a comma-separated list of all of this database's SQL keywords that are NOT also SQL:2003 keywords.
Method GetSQLKeywords() As %String
{
	return ..connection.GetInfo(89)
}

/// Retrieves a description of the given table's indices and statistics
Method GetIndexInfo(catalog As %String, schema As %String, table As %String, unique As %Boolean, approximate As %Boolean) As ResultSet
{
	set st = ..connection.CreateStatement()
	do st.statement.Statistics(catalog,schema,table,unique,approximate)
	set rs = ##class(%XDBC.Gateway.ODBC.ResultSet).%New(st)
	return rs
}

/// Method Not Supported
Method GetPseudoColumns(catalog As %String, schemaPattern As %String, tableNamePattern As %String, columnNamePattern As %String) As ResultSet
{
	//message "CH"
	
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetFunctionColumns(catalog As %String, schemaPattern As %String, functionNamePattern As %String, columnNamePattern As %String) As ResultSet
{
	//message "FC"
	
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetFunctions(catalog As %String, schemaPattern As %String, functionNamePattern As %String) As ResultSet
{
	//message "FN"
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetSchemas(catalog As %String = "", schemaPattern As %String = "") As ResultSet
{
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetSchemaTerm() As %String
{
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetSuperTables(catalog As %String, schemaPattern As %String, tableNamePattern As %String) As ResultSet
{
	//message "SL"
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Method Not Supported
Method GetSuperTypes(catalog As %String, schemaPattern As %String, typeNamePattern As %String) As ResultSet
{
	//message "SY"
	throw ##class(%Exception.General).%New("Method Not Supported")
}

/// Retrieves tables priviligies.
Method GetTablePrivileges(catalog As %String, schemaPattern As %String, tableNamePattern As %String) As ResultSet
{
	return ..connection.GetTablePriviligies(schemaPattern,tableNamePattern)
}

/// Retrieves a description of the access rights for each table available in a catalog.
Method GetTables(catalog As %String, schemaPattern As %String, tableNamePattern As %String, types As %List) As ResultSet
{
	return ..connection.GetTables(catalog,schemaPattern,tableNamePattern)
}

/// Retrieves a description of the tables available in the given catalog.
Method GetTableTypes() As ResultSet
{
	return ..connection.GetTables("","")
}

}
