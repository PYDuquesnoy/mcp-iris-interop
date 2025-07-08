/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Context.DBMSSession Extends %SystemBase
{

Property context As %RawString [ MultiDimensional ];

Method getContext(context, parameterName) As %String(MAXLEN="") [ CodeMode = expression ]
{
$get(i%context(context,parameterName))
}

Method setContext(context, parameterName, value) As %String(MAXLEN=4096)
{
	set i%context(context,parameterName) = value
	return value
}

ClassMethod "SYS_CONTEXT"(context As %String(MAXLEN=220), parameterName As %String(MAXLEN=220)) As %String(MAXLEN=4096) [ CodeMode = expression, SqlName = SYS_CONTEXT, SqlProc ]
{
$system.Context.DBMSSession().getContext(context,parameterName)
}

/// Clears all context information
ClassMethod "CLEAR_ALL_CONTEXT"() [ SqlName = CLEAR_ALL_CONTEXT, SqlProc ]
{
}

/// Clears the context
ClassMethod "CLEAR_CONTEXT"() [ SqlName = CLEAR_CONTEXT, SqlProc ]
{
}

/// Clears the identifier
ClassMethod "CLEAR_IDENTIFIER"() [ SqlName = CLEAR_IDENTIFIER, SqlProc ]
{
}

/// Closes database link
ClassMethod "CLOSE_DATABASE_LINK"() [ SqlName = CLOSE_DATABASE_LINK, SqlProc ]
{
}

/// Lets you reclaim unused memory after performing operations requiring large amounts of memory
ClassMethod "FREE_UNUSED_USER_MEMORY"() [ SqlName = FREE_UNUSED_USER_MEMORY, SqlProc ]
{
}

/// Determines if the named role is enabled for the session.
ClassMethod "IS_ROLE_ENABLED"() [ SqlName = IS_ROLE_ENABLED, SqlProc ]
{
}

/// Determines if the specified session is active
ClassMethod "IS_SESSION_ALIVE"() [ SqlName = IS_SESSION_ALIVE, SqlProc ]
{
}

/// Returns a list of active namespace and context for the current session
ClassMethod "LIST_CONTEXT"() [ SqlName = LIST_CONTEXT, SqlProc ]
{
}

/// Resets the session-level SQL trace for the session from which it was called.
ClassMethod "SESSION_TRACE_DISABLE"() [ SqlName = SESSION_TRACE_DISABLE, SqlProc ]
{
}

/// Enables session-level SQL trace for the invoking session
ClassMethod "SESSION_TRACE_ENABLE"() [ SqlName = SESSION_TRACE_ENABLE, SqlProc ]
{
}

/// De-instantiates all packages in the session
ClassMethod "RESET_PACKAGE"() [ SqlName = RESET_PACKAGE, SqlProc ]
{
}

/// Sets or resets the value of a context attribute
ClassMethod "SET_CONTEXT"(namespace As %String(MAXLEN=30), attribute As %String(MAXLEN=30), value As %String(MAXLEN=4096)) As %String(MAXLEN=4096) [ CodeMode = expression, SqlName = SET_CONTEXT, SqlProc ]
{
$system.Context.DBMSSession().setContext(namespace,attribute,value)
}

/// Sets the identifier
ClassMethod "SET_IDENTIFIER"() [ SqlName = SET_IDENTIFIER, SqlProc ]
{
}

/// Sets Globalization Support (NLS)
ClassMethod "SET_NLS"() [ SqlName = SET_NLS, SqlProc ]
{
}

/// Sets role
ClassMethod "SET_ROLE"() [ SqlName = SET_ROLE, SqlProc ]
{
}

/// Turns tracing on or off
ClassMethod "SET_SQL_TRACE"() [ SqlName = SET_SQL_TRACE, SqlProc ]
{
}

/// Facilitates changing the current resource consumer group of a user's current session
ClassMethod "SWITCH_CURRENT_CONSUMER_GROUP"() [ SqlName = SWITCH_CURRENT_CONSUMER_GROUP, SqlProc ]
{
}

/// Returns an identifier that is unique for all sessions currently connected to this database
ClassMethod "UNIQUE_SESSION_ID"() [ SqlName = UNIQUE_SESSION_ID, SqlProc ]
{
}

}
