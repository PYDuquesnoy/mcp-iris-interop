/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%SYSTEM.TSQL</class> class provides an interface for managing
/// InterSystems IRIS TSQL configurations.<br>
/// <p>You can use it via the special <b>$SYSTEM</b> object:<br>
/// <example>
/// Do $SYSTEM.TSQL.SetAnsiNulls("Sybase","on")
/// </example>
/// <p>You can call help to get a list of all entry points:<br>
/// <p>
/// Do $SYSTEM.TSQL.Help()
Class %SYSTEM.TSQL Extends Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// This method will return the current setting that are defined for InterSystems TSQL compatibility features.
ClassMethod CurrentSettings()
{
	w !,"Current Dialect:            ", $g(^%SYS("tsql","DIALECT"),"InterSystems SQL")
	w !,"ANSI_NULLS:                 ", $g(^%SYS("tsql","SET","ANSI_NULLS"),"OFF")
	w !,"CaseInsCompare:             ", $g(^%SYS("tsql","SET","CASEINSCOMPARE"),"OFF")
	w !,"Quoted_Identifier:          ", $g(^%SYS("tsql","SET","QUOTED_IDENTIFIER"),"OFF")
	w !,"Equal_Literal_Replacement:  ", $g(^%SYS("tsql","SET","EQUAL_LITERAL_REPLACEMENT"),"ON")
	w !,"Owner_As Schema:            ", $g(^%SYS("tsql","OWNER_AS_SCHEMA"),"OFF")
	w !,"TRACE:                      ", $g(^%SYS("tsql","TRACE"),"OFF")
	RETURN
}

/// This method returns the current default TSQL Dialect for the System.  The two options are Sybase and MSSQL
ClassMethod GetDialect() As %String
{
	RETURN $G(^%SYS("tsql","DIALECT"))
}

/// This method sets the default TSQL Dialect for the System.
/// <br><br>
/// <b>Parameter:</b>
/// <dl>
/// <dt><i>Dialect</i>
/// <dd>Name of the TSQL dialect:  Sybase or MSSQL.  The Default is SQL
/// 
/// </dl>
/// <br><b>Returns:</b>  The previous default TSQL Dialect value or an invalid error message
ClassMethod SetDialect(Dialect) As %String
{
	Set DIALECT=$ZCONVERT(Dialect,"U")
	if ",SYBASE,MSSQL," '[ (","_DIALECT_",") QUIT "Invalid dialect, please enter Sybase or MSSQL"
	Set current=$G(^%SYS("tsql","DIALECT"))
	Set ^%SYS("tsql","DIALECT") = $s(DIALECT="SYBASE":"Sybase",1:"MSSQL")
	RETURN current
}

/// This method returns the current default TSQL dialect and the value for TSQL Ansi Null behavior.
/// 
/// valid values are ON or OFF 
ClassMethod GetAnsiNulls() As %String
{
	RETURN $G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","ANSI_NULLS"),"OFF")
}

/// This method sets the current default TSQL dialect and the value for TSQL Ansi Null behavior.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Dialect</i>
/// <dd>Name of the TSQL dialect:  Sybase or MSSQL
/// <dt><i>flag</i>
/// <dd>Value for TSQL Ansi NULL behavior: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous default TSQL dialect value and Ansi Null behavior
ClassMethod SetAnsiNulls(Dialect, flag) As %String
{
	Set DIALECT=$ZCONVERT(Dialect,"U")
	if ",SYBASE,MSSQL," '[ (","_DIALECT_",") { RETURN "Invalid dialect, please enter Sybase or MSSQL" }
	Set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON or OFF" }
	Set current=$G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","ANSI_NULLS"),"OFF")
	Set ^%SYS("tsql","DIALECT") = $s(DIALECT="SYBASE":"Sybase",1:"MSSQL")
	Set ^%SYS("tsql","SET","ANSI_NULLS") = flag
	RETURN current
}

/// This method returns the current default TSQL dialect and the value for TSQL non-case-sensitive equality comparison behavior.
/// 
/// valid values are ON or OFF
ClassMethod GetCaseInsCompare() As %String
{
	RETURN $G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","CASEINSCOMPARE"),"OFF")
}

/// This method sets the current default TSQL dialect and the value for TSQL non-case-sensitive equality comparison behavior.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Dialect</i>
/// <dd>Name of the TSQL dialect:  Sybase or MSSQL
/// <dt><i>flag</i>
/// <dd>Value for TSQL non-case-sensitive equality comparison behavior: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous default TSQL dialect value and TSQL non-case-sensitive equality comparison behavior.
ClassMethod SetCaseInsCompare(Dialect, flag) As %String
{
	Set DIALECT=$ZCONVERT(Dialect,"U")
	if ",SYBASE,MSSQL," '[ (","_DIALECT_",") { RETURN "Invalid dialect, please enter Sybase or MSSQL" }
	Set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON or OFF" }
	Set current=$G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","CASEINSCOMPARE"),"OFF")
	Set ^%SYS("tsql","DIALECT") = $s(DIALECT="SYBASE":"Sybase",1:"MSSQL")
	Set ^%SYS("tsql","SET","CASEINSCOMPARE") = flag
	RETURN current
}

/// This method returns the current default TSQL dialect and the value for TSQL equal literal replacement ( = conditions and IN clause) behavior.
/// 
/// valid values are ON or OFF
ClassMethod GetEqualLiteralReplacement() As %String
{
	RETURN $G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","EQUAL_LITERAL_REPLACEMENT"),"ON")
}

/// This method sets the current default TSQL dialect and the value for TSQL equal literal replacement ( = conditions and IN clause) behavior.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Dialect</i>
/// <dd>Name of the TSQL dialect:  Sybase or MSSQL
/// <dt><i>flag</i>
/// <dd>Value for TSQL equal literal replacement ( = conditions and IN clause) behavior: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous default TSQL dialect value and TSQL equal literal replacement ( = conditions and IN clause) behavior.
ClassMethod SetEqualLiteralReplacement(Dialect, flag) As %String
{
	Set DIALECT=$ZCONVERT(Dialect,"U")
	if ",SYBASE,MSSQL," '[ (","_DIALECT_",") { RETURN "Invalid dialect, please enter Sybase or MSSQL" }
	Set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON or OFF" }
	Set current=$G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","EQUAL_LITERAL_REPLACEMENT"),"ON")
	Set ^%SYS("tsql","DIALECT") = $s(DIALECT="SYBASE":"Sybase",1:"MSSQL")
	Set ^%SYS("tsql","SET","EQUAL_LITERAL_REPLACEMENT") = flag
	RETURN current
}

/// This method returns the current default TSQL dialect and the value for TSQL Quoted Identifier behavior.
/// 
/// valid values are ON or OFF
ClassMethod GetQuotedIdentifier() As %String
{
	RETURN $G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","QUOTED_IDENTIFIER"),"OFF")
}

/// This method sets the current default TSQL dialect and the value for TSQL Quoted Identifier behavior.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Dialect</i>
/// <dd>Name of the TSQL dialect:  Sybase or MSSQL
/// <dt><i>flag</i>
/// <dd>Value for TSQL Quoted Identifier behavior: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous default TSQL dialect value and TSQL Quoted Identifier behavior.
ClassMethod SetQuotedIdentifier(Dialect, flag) As %String
{
	Set DIALECT=$ZCONVERT(Dialect,"U")
	if ",SYBASE,MSSQL," '[ (","_DIALECT_",") { RETURN "Invalid dialect, please enter Sybase or MSSQL" }
	Set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON or OFF" }
	Set current=$G(^%SYS("tsql","DIALECT"))_", "_$G(^%SYS("tsql","SET","QUOTED_IDENTIFIER"),"OFF")
	Set ^%SYS("tsql","DIALECT") = $s(DIALECT="SYBASE":"Sybase",1:"MSSQL")
	Set ^%SYS("tsql","SET","QUOTED_IDENTIFIER") = flag
	RETURN current
}

/// This method takes no arguments and returns the current setting for TSQL TRACE.
ClassMethod GetTrace() As %String
{
	RETURN $s($g(^%SYS("tsql","TRACE")):"ON",1:"OFF")
}

/// This method sets the TSQL TRACE behavior to ON or OFF.
/// When TRACE=ON, a TSQL procedure will create a log file in the current namespace's directory named "tsql"_$j_".log" that contains the statements executed when the procedure is run.
/// Changing the TRACE setting only takes effect when the class is recompiled or the TSQL procedure is [re]created.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>flag</i>
/// <dd>Value for TSQL TRACE setting: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous TSQL TRACE setting or an error message
ClassMethod SetTrace(flag) As %String
{
	set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF,1,0," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON, 1, OFF, or 0" }
	set current=..GetTrace()
	set ^%SYS("tsql","TRACE")=$case(flag,"ON":1,1:1,:0)
	RETURN current
}

/// This method takes no arguments and returns the current setting for TSQL OWNER_AS_SCHEMA
ClassMethod GetOwnerAsSchema() As %String [ ProcedureBlock = 1 ]
{
	RETURN $s($g(^%SYS("tsql","OWNER_AS_SCHEMA")):"ON",1:"OFF")
}

/// This method sets the TSQL OWNER_AS_SCHEMA behavior to ON or OFF.
/// When OWNER_AS_SCHEMA=ON, TSQL will convert database.owner.table to database_owner.table.
/// If owner is missing, say database..table, $username will be used for the owner resulting in database_$$$LOWER($username).table
/// Changing the OWNER_AS_SCHEMA setting only takes effect when the TSQL procedure class is [re]compiled or cached queries compiled in a TSQL dialect are purged and recreated.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>flag</i>
/// <dd>Value for TSQL OWNER_AS_SCHEMA setting: ON or OFF
/// </dl>
/// <br><b>Returns:</b>  The previous TSQL OWNER_AS_SCHEMA setting or an error message
ClassMethod SetOwnerAsSchema(flag) As %String [ ProcedureBlock = 1 ]
{
	set flag=$ZCONVERT(flag,"U")
	if ",ON,OFF,1,0," '[ (","_flag_",") { RETURN "Invalid flag, please enter ON, 1, OFF, or 0" }
	set current=..GetOwnerAsSchema()
	set ^%SYS("tsql","OWNER_AS_SCHEMA")=$case(flag,"ON":1,1:1,:0)
	RETURN current
}

}
