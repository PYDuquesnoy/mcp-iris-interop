/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.AbstractForeignTable [ Abstract ]
{

/// String of header names for FILE foreign tables to specify column order in the header
Parameter COLUMNS;

/// Types specified in the COLUMNS clause; included for parity with LOAD DATA
Parameter COLUMNSTYPES;

/// Number of columns in the table (IRIS side)
Parameter NUMCOLUMNS;

/// Does this FT support predicated pushdown; taken from SERVER
Parameter PREDICATEPUSHDOWN;

/// Name of the class that projects this foreign table
Parameter PROJECTEDBY;

/// Optional user-specified query to send to the external DB
Parameter QUERY;

/// Name of the server this foreign table belongs to
Parameter SERVER;

/// Name of the table as it exists in the external data source
Parameter TABLE;

/// USING clause at CREATE time
Parameter USING;

/// Comma-delimited string of column names as they exist in the external table
Parameter VALUES;

ClassMethod Execute(query As %String = "", parameters As %List = "") [ Internal ]
{
    set sc = $$$OK, fdwObject = ""
    try {
        set fdwObject = $classmethod($parameter(..#SERVER,"FDWNAME"),"%New")
        set sc = fdwObject.Prepare(..#SERVER, $CLASSNAME(), query)
		set:$$$ISOK(sc) sc = fdwObject.Execute(parameters)
	} catch ex { 
        set sc = ex.AsStatus()
    }

    if $$$ISERR(sc) {
        if '$isobject($g(fdwObject)) { 
            set fdwObject = ##class(%SQL.StatementResult).%New() 
        }
        set fdwObject.%SQLCODE = $system.Status.StatusToSQLCODE(sc)
        set:fdwObject.%SQLCODE=-400 fdwObject.%SQLCODE = -230
        set fdwObject.%Message = $system.Status.GetErrorText(sc)
    }

	RETURN fdwObject
}

}
