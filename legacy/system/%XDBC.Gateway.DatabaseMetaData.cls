/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// FOR INTERNAL USE - do not invoke directly
Class %XDBC.Gateway.DatabaseMetaData Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Retrieves the catalog names available in this database.
Method GetCatalogs() As ResultSet
{
}

/// Retrieves a description of the access rights for a table's columns.
Method GetColumnPrivileges(catalog As %String, schema As %String, table As %String, columnNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of table columns available in the specified catalog
Method GetColumns(catalog As %String, schemaPattern As %String, tableNamePattern As %String, columnNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the foreign key columns in the given foreign key table that reference the primary key or the columns representing a unique constraint of the parent table (could be the same or a different table)
Method GetCrossReference(parentCatalog As %String, parentSchema As %String, parentTable As %String, foreignCatalog As %String, foreignSchema As %String, foreignTable As %String) As ResultSet
{
}

/// Retrieves the name and version number of this database
Method GetDatabaseProductNameAndVersion() As %String
{
}

/// Retrieves the name of this JDBC driver.
Method GetDriverName() As %String
{
}

/// Retrieves the version number of this driver as a String
Method GetDriverVersion() As %String
{
}

/// Retrieves a description of the foreign key columns that reference the given table's primary key columns (the foreign keys exported by a table).
Method GetExportedKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
}

/// Retrieves a description of the given catalog's system or user function parameters and return type.
Method GetFunctionColumns(catalog As %String, schemaPattern As %String, functionNamePattern As %String, columnNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the system and user functions available in the given catalog.
Method GetFunctions(catalog As %String, schemaPattern As %String, functionNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the primary key columns that are referenced by the given table's foreign key columns (the primary keys imported by a table).
Method GetImportedKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
}

/// Retrieves a description of the given table's indices and statistics
Method GetIndexInfo(catalog As %String, schema As %String, table As %String, unique As %Boolean, approximate As %Boolean) As ResultSet
{
}

/// Retrieves a comma-separated list of math functions available with this database.
Method GetNumericFunctions() As %String
{
}

/// Retrieves a description of the given table's primary key columns.
Method GetPrimaryKeys(catalog As %String, schema As %String, table As %String) As ResultSet
{
}

/// Retrieves a description of the given catalog's stored procedure parameter and result columns.
Method GetProcedureColumns(catalog As %String, schemaPattern As %String, procedureNamePattern As %String, columnNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the stored procedures available in the given catalog.
Method GetProcedures(catalog As %String, schemaPattern As %String, procedureNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the pseudo or hidden columns available in a given table within the specified catalog and schema.
Method GetPseudoColumns(catalog As %String, schemaPattern As %String, tableNamePattern As %String, columnNamePattern As %String) As ResultSet
{
}

/// Retrieves the schema names available in this database
Method GetSchemas(catalog As %String = "", schemaPattern As %String = "") As ResultSet
{
}

/// Retrieves the preferred term for 'schema' in this database
Method GetSchemaTerm() As %String
{
}

/// Retrieves a comma-separated list of all of this database's SQL keywords that are NOT also SQL:2003 keywords.
Method GetSQLKeywords() As %String
{
}

/// Retrieves a comma-separated list of string functions available with this database.
Method GetStringFunctions() As %String
{
}

/// Retrieves a description of the table hierarchies defined in a particular schema in this database.
Method GetSuperTables(catalog As %String, schemaPattern As %String, tableNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the user-defined type (UDT) hierarchies defined in a particular schema in this database. 
/// Only the immediate super type/ sub type relationship is modeled.
Method GetSuperTypes(catalog As %String, schemaPattern As %String, typeNamePattern As %String) As ResultSet
{
}

/// Retrieves a comma-separated list of system functions available with this database.
Method GetSystemFunctions() As %String
{
}

/// Retrieves a description of the access rights for each table available in a catalog.
Method GetTablePrivileges(catalog As %String, schemaPattern As %String, tableNamePattern As %String) As ResultSet
{
}

/// Retrieves a description of the tables available in the given catalog.
Method GetTables(catalog As %String, schemaPattern As %String, tableNamePattern As %String, types As %List) As ResultSet
{
}

/// Retrieves the table types available in this database. The results are ordered by table type.
Method GetTableTypes() As ResultSet
{
}

/// Retrieves a comma-separated list of the time and date functions available with this database.
Method GetTimeDateFunctions() As %String
{
}

/// Retrieves a description of all the data types supported by this database.
Method GetTypeInfo() As ResultSet
{
}

}
