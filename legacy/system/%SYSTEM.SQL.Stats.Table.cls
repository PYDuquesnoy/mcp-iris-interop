/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.SQL.Stats.Table Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// Export extentsize and selectivity for tables/fields to an XML file.  
/// Generated file can be loaded using $SYSTEM.SQL.Stats.Table.Import().
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>pFilename</i>
/// <dd>Name of the file to output the table(s) tuning statistics to.
/// <dt><i>pSchemaFilter</i>
/// <dd>Filter to limit the schemas output.  The default is "", which means there is no filter applied and all schemas in the namespace are exported.
/// pSchemaFilter uses '_' to signify any single character, '*' to signify 0 through N characters, and ' to signify NOT.
/// <dt><i>pTableFilter</i>
/// <dd>Filter to limit the tables output.  The default is "", which means there is no filter applied and all tables in the specified schemas are exported.
/// pTableFilter uses '_' to signify any single character, '*' to signify 0 through N characters, and ' to signify NOT.
/// <dt><i>pDisplay</i>
/// <dd>TRUE(1)/FALSE(0) flag. Displays progress messages to the current device if TRUE. The default is TRUE (1).
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.Export("C:\AllStats.xml") // Exports TuneTable Statistics for all schemas/tables in the current namespace</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.Export("C:\SampleStats.xml","Sample") // Exports TuneTable Statistics for all Sample.* tables in the current namespace</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.Export("C:\SamplePStats.xml","Sample","P*") // Exports TuneTable Statistics for all Sample.P* in the current namespace</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.Export("C:\SamplePersonStats.xml","Sample","Person") // Exports TuneTable Statistics for table Sample.Person in the current namespace</li>
/// </ul>
ClassMethod Export(pFilename As %Library.String, pSchemaFilter As %Library.String = "", pTableFilter As %Library.String = "", pDisplay As %Library.Boolean = 1) As %Library.Status [ ProcedureBlock = 1 ]
{
	set tSC=$$$OK
	set tSC=$$ExportTuneStats^%qarTune($g(pFilename),pSchemaFilter,pTableFilter,pDisplay)
	RETURN tSC
}

/// Import extentsize, selectivity, blockcount for a table and its fields from a file created by $SYSTEM.SQL.Stats.Table.Export().
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>pFilename</i>
/// <dd>Name of the file to output the table(s) tuning statistics to.
/// <dt><i>pDisplay</i>
/// <dd>TRUE(1)/FALSE(0) flag. Displays progress messages to the current device if TRUE. The default is TRUE (1).
/// <dt><i>pClearCurrentStats</i>
/// <dd>TRUE(1)/FALSE(0) flag. If TRUE(1), any EXTENTSIZE, SELECTIVITY, BLOCKCOUNT, etc. will be cleared from the existing table prior to importing the stats.  
/// This can be used if you want to completely clear stats that are not specified in the import file instead of leaving them defined in class/table.  The default is FALSE (0)
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.Import("C:\AllStats.xml") // Import TuneTable Statistics for all schemas/tables that were exported with the $SYSTEM.SQL.Stats.Table.Export() to the AllStats.xml file</li>
/// </ul>
ClassMethod Import(pFilename As %Library.String, pDisplay As %Library.Boolean = 1, pClearCurrentStats As %Library.Boolean = 0) As %Library.Status [ ProcedureBlock = 1 ]
{
	set tSC=$$$OK
	set tSC=$$ImportTuneStats^%qarTune($g(pFilename),pDisplay,1,pClearCurrentStats)
	RETURN tSC
}

/// Calculate and update extentsize and selectivity for all classes/tables and their properties/fields within a schema. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>schema</i>
/// <dd>Name of a schema to tune tables.
/// If the schema name is omitted, the default schema is used.
/// <dt><i>logFile</i>
/// <dd>Optional name of a file to log the output of the TuneTable utility to. If <i>logFile</i> isn't supplied, the output will go to the current device.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherSchemaStats("MedLab","TuneLog.txt")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherSchemaStats("""Medical Lab""")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherSchemaStats("") ; Tunes SQLUser schema</li>
/// </ul>
ClassMethod GatherSchemaStats(schema As %Library.String, logFile As %Library.String = "") As %Status
{
	new msg
	set msg=""
	do TuneSchema^%apiSQL($g(schema),1,$s(logFile="":1,1:0),.msg,0,0,logFile,0,"")
	RETURN:msg="" $$$OK
	RETURN $$$ERROR($$$GeneralError,msg)
}

/// Calculate and update extentsize and selectivity for a class/table and its properties/fields.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>table</i>
/// <dd>Name of a table or "*" to tune all tables in the current namespace.
/// The name may be qualified with a schema name:
/// <i>Medical.Patient</i>
/// If the schema name is omitted, the default schema is used.
/// <dt><i>logFile</i>
/// <dd>Optional name of a file to log the output of the TuneTable utility to. If <i>logFile</i> isn't supplied, the output will go to the current device.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherTableStats("MedLab.Patient","Tune.log")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherTableStats("""Medical Lab"".Patient")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.GatherTableStats("IscPerson") ; Tunes SQLUser.IscPerson</li>
/// </ul>
ClassMethod GatherTableStats(table As %Library.String, logFile As %Library.String = "") As %Status
{
	new msg
	set msg=""
	do TuneTable^%apiSQL($g(table),1,$s(logFile="":1,1:0),.msg,0,0,logFile,"",0,"")
	RETURN:msg="" $$$OK
	RETURN $$$ERROR($$$GeneralError,msg)
}

/// Set the SELECTIVITY of a field and property to the value of the given selectivity
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>schema</i>
/// <dd>Name of the table's schema.  Default is the default schema.
/// <dt><i>tablename</i>
/// <dd>Name of the table the field is in (required).
/// <dt><i>fieldname</i>
/// <dd>Name of the field to set the SELECTIVITY for (required).
/// <dt><i>selectivity</i>
/// <dd>New selectivity value for the field (required).  The selectivity of a property specifies the approximate frequency of specific values within the entire distribution of values.
/// The Selectivity value for a column is generally the percentage of rows within a table that would be returned as a result of query searching for a typical value of the column.
/// For example, suppose a table contains a Gender column whose value is evenly distributed between "M" and "F". The Selectivity value for the Gender column would be 50%, as a 
/// typical query based on Gender would find 50% of the rows within the table. The Selectivity value for a more unique property, such as TaxID, is typically a small percentage 
/// that varies according to the size of the table.
/// Examples of values you can specify here are:
/// <li>"10%" - Means that typical values for this column will return 10% of the rows in the table</li>
/// <li>"1" - Means this field is unique.  For any given value, it will return 1 row from the table.</li>
/// <li><number> - A pure number will calculate the selectivity as EXTENTSIZE/<i>selectivity</i>.  For example, if EXTENTSIZE is 100000 and <i>selectivity</i> is 1000, this will set the selectivity to 1%.</li>
/// <li>"NUMROWS" - This is the same as specifying "1", it means the field is unique.  This is allowed for legacy support of M/SQL tables that have been converted to class definitions.</li>
/// <li>NUMROWS/positive_integer - This will calculate the SQL SELECTIVITY as EXTENTSIZE/positive_integer.  For example if EXTENTSIZE is 100000 and you specify NUMROWS/5000, this will set the SQL SELECTIVITY to 20, which means for a typical value for the field, 20 rows of the table will be returned.  This is allowed for legacy support of M/SQL tables that have been converted to class definitions.</li>
/// <dd>There is no validation of the value you enter for the SELECTIVITY.  If you enter something not recognized as a valid SELECTIVITY, such as the string "nonsense", it will be turned into a value of 0.  If the SQL query processor sees a SELECTIVITY of 0, it will attempt to come up with a typical SELECTIVITY value for the field based on how many rows are in the table and whether or not the field is a reference column, is part of the IDKEY field, has a VALUELIST specification, etc.
/// </dl>
/// <p>
/// <b>Returns:</b>
/// <p>
/// <dd>Status Code
/// <p>
/// <p><b>Example</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.SetFieldSelectivity("MedLab","Patient","Home_Phone","2.5%")</li>
/// </ul>
ClassMethod SetFieldSelectivity(schema As %Library.String, tablename As %Library.String, fieldname As %Library.String, selectivity As %Library.String) As %Library.Status [ ProcedureBlock = 1 ]
{
	set:$g(schema)="" schema=$SYSTEM.SQL.Schema.Default()
	RETURN:$g(tablename)="" $$$ERROR($$$InvalidParameter,"tablename","tablename parameter is required")
	RETURN:$g(fieldname)="" $$$ERROR($$$InvalidParameter,"fieldname","fieldname parameter is required")
	RETURN:$g(selectivity)="" $$$ERROR($$$InvalidParameter,"selectivity","selectivity parameter is required")
	set extent=$$$GetExtentNameFromTableName(schema,tablename) RETURN:extent="" $$$ERROR($$$TableDoesNotExist,$$$UPPER(schema_"."_tablename))
	set fldinfo=$g($$$EXTSQLCOLsqlinfo($$$rEXT,extent,fieldname)) RETURN:fldinfo="" $$$ERROR($$$FieldNameInvalid,fieldname_" - no such field")
	set tabinfo=$$$EXTsqlinfo($$$rEXT,extent)
	set classname=$$$SetSQLLocTableClassname(tabinfo)
	set extentsize=$$$SQLLocTableExtentSize(tabinfo)
	set sc=$$SetSelectivity^%qarTune(extent,fieldname,fldinfo,classname,extentsize,selectivity,$$ConvertSelectivity^%ocsExtent(selectivity,extentsize),,,,)
	RETURN:$$$ISERR(sc) sc
	do PostTune^%qarTune(extent,schema,tablename,"",,0,)
	do DeleteExtentCQ^%SYS.SQLSRV(extent)
	RETURN $$$OK
}

/// Set the EXTENTSIZE of a table to the value of the given extentsize
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>schema</i>
/// <dd>Name of the table's schema.  Default is the default schema.
/// <dt><i>tablename</i>
/// <dd>Name of the table the field is in (required).
/// <dt><i>newextentsize</i>
/// <dd>New extent size value for the field (required).  The extent size of a table is the number of rows. Must be a positive number.
/// <b>Returns:</b>
/// <p>
/// <dd>Status Code
/// <p>
/// <p><b>Example</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.SetExtentSize("Sample","Person",135)</li>
/// </ul>
ClassMethod SetExtentSize(schema As %Library.String, tablename As %Library.String, newextentsize As %Library.String) As %Library.Status [ ProcedureBlock = 1 ]
{
	set:$g(schema)="" schema=$SYSTEM.SQL.Schema.Default()
	RETURN:$g(tablename)="" $$$ERROR($$$InvalidParameter,"tablename","tablename parameter is required")
	RETURN:$g(newextentsize)="" $$$ERROR($$$InvalidParameter,"newextentsize","newextentsize parameter is required")
	RETURN:('$isvalidnum($g(newextentsize)))||($g(newextentsize)<0) $$$ERROR($$$InvalidParameter,"newextentsize","newextentsize must be a non-negative number")
	set extent=$$$GetExtentNameFromTableName(schema,tablename) RETURN:extent="" $$$ERROR($$$TableDoesNotExist,$$$UPPER(schema_"."_tablename))
	set tabinfo=$$$EXTsqlinfo($$$rEXT,extent)
	set classname=$$$SetSQLLocTableClassname(tabinfo)
	set oldextentsize=$$$SQLLocTableExtentSize(tabinfo)
	set sc=$$SetExtentSize^%qarTune(extent,tabinfo,classname,oldextentsize,newextentsize)
	do PostTune^%qarTune(extent,schema,tablename,"",,0,)
	do DeleteExtentCQ^%SYS.SQLSRV(extent)
	RETURN $$$OK
}

/// Clear the table stats (selectivity, histogram info, extent size, etc.) for all classes/tables and their properties/fields within a schema. 
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>schema</i>
/// <dd>Name of a schema to tune tables.
/// If the schema name is omitted, the default schema is used.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.ClearSchemaStats("MedLab")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.ClearSchemaStats("") ; Clear the table stats for SQLUser schema</li>
/// </ul>
ClassMethod ClearSchemaStats(schema As %Library.String) As %Status
{
	new msg
	set msg=""
	do TuneSchema^%apiSQL($g(schema),1,0,.msg,0,1,,0,"")
	RETURN:msg="" $$$OK
	RETURN $$$ERROR($$$GeneralError,msg)
}

/// Clear the table stats (selectivity, histogram info, extent size, etc.) for a class/table and its properties/fields.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>table</i>
/// <dd>Name of a table or "*" to Clear the table stats for all tables in the current namespace.
/// The name may be qualified with a schema name:
/// <i>Medical.Patient</i>
/// If the schema name is omitted, the default schema is used.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Stats.Table.ClearTableStats("MedLab.Patient")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.ClearTableStats("""Medical Lab"".Patient")</li>
/// <li>Do $SYSTEM.SQL.Stats.Table.ClearTableStats("IscPerson") ; Clear the table stats for SQLUser.IscPerson</li>
/// </ul>
ClassMethod ClearTableStats(table As %Library.String) As %Status
{
	new msg
	set msg=""
	do TuneTable^%apiSQL($g(table),1,0,.msg,0,1,,"",0,"")
	RETURN:msg="" $$$OK
	RETURN $$$ERROR($$$GeneralError,msg)
}

}
