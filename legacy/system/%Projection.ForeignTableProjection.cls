/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Projection.ForeignTableProjection Extends %Projection.AbstractProjection
{

/// String of header names for FILE foreign tables to specify column order in the header
Parameter COLUMNS;

/// Types specified in the COLUMNS clause; included for parity with LOAD DATA
Parameter COLUMNSTYPES;

/// Number of columns in the table (IRIS side)
Parameter NUMFIELDS;

/// Does this FT support predicated pushdown; taken from SERVER
Parameter PREDICATEPUSHDOWN;

/// Fully qualified SQL name of the foreign table this projection projects
Parameter PROJECTS;

/// Optional user-specified query to send to the external DB
Parameter QUERY;

/// Name of the server this foreign table belongs to
Parameter SERVER;

/// SQL name given to the FT class query
Parameter SQLQUERYNAME [ Deprecated ];

/// Name of the table as it exists in the external data source
Parameter TABLE;

/// USING clause at CREATE time
Parameter USING;

/// Comma-delimited string of column names as they exist in the external table
Parameter VALUES;

/// Recreate the associated FT
ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
    merge ftClassParams = parameters
    // kill the parameters that are for the projector class and thus not going on the FT class, the rest we can merge in to become FT class params
    set param = ""
    for {
        set param = $o(ftClassParams(param))
        QUIT:param=""
        if $$$FTParameters'[(" " _ param _ " ") {
            kill ftClassParams(param)
        }
    }
    set ftClassParams("PROJECTEDBY") = classname // classname is the FT projector class that has the Projection element for which this CreateProjection() is being called
    set sc = $$CreateForeignTable^%apiDDL2(
        parameters("PROJECTS"),
        $$$defClassKeyGet(classname, $$$cCLASSowner),
        .ftClassName,
        parameters("SERVER"),
        .ftClassParams,
        .SQLCODE
    )
    // utilize the infrastructure provided by projections to compile this
    do:$$$ISOK(sc) ..QueueClass(ftClassName)
    RETURN sc
}

/// Drop the associated FT
ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
    // The recompile parameter is true if RemoveProjection() is being called as part of an uncompile->recompile chain. In that case we want to
    // set the FT class definition back to a 'blank slate' so that CreateProjection() can be called and the entire class def of the FT will be
    // redefined based on the latest information in the projector class
    if recompile {
        set sc = $$PrepareFTForRecompile^%apiDDL2(
            parameters("PROJECTS"),
            .ftClassName,
            .SQLCODE
        )
        do:$$$ISOK(sc) ..QueueClass(ftClassName)
    } else { // this is the real deal, delete the FT projection permanently
        set sc = $$DropForeignTable^%apiDDL2(parameters("PROJECTS"), .SQLCODE)
    }
	RETURN sc
}

}
