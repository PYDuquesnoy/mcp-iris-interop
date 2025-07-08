/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SYSTEM.Error is a generic error container used to return error information reported
/// from various sources. Errors can occur in several different ways. A %Status value can
/// be returned, an ObjectScript error can be trapped and reported as $ZERROR, an SQLCODE error
/// can be reported by an SQL statement, or an error number from an XSQL procedure can
/// be reported. All of these errors must be recognizable and be able to be reported in
/// various forms. xDBC expects an SQLCODE while other systems might want %Status values.
/// 
/// This class provides a mechanism for consistent reporting and detection.
Class %SYSTEM.Error Extends %RegisteredObject [ System = 4 ]
{

/// Create a new error given a %Status or an SQLCODE and %message value. Severity applies to
/// certain XSQL systems (TSQL only for now)
Method %OnNew(pStatus As %Status = "", pSQLCode As %String = "", pMessage As %String = "", pSeverity As %Integer = 0) As %Status
{
	set ..Status = pStatus, ..SQLCode = pSQLCode, ..Message = pMessage, ..Severity = pSeverity
	if ..Status = "" {
		if pSQLCode '= "" { set ..Status = $$$ERROR($$$SQLCode,pSQLCode,pMessage) }
		else { set ..Status = $$$ERROR($$$GeneralError,pMessage) }
	}
	elseif pSQLCode = "" {
		do DecomposeStatus^%apiOBJ(pStatus,.tInfo)
		if $data(tInfo(1)) {
			if (tInfo(1,"code") = $$$ERRORCODE($$$SQLCode)) || (tInfo(1,"code") = $$$ERRORCODE($$$SQLError)) { set ..SQLCode = $Get(tInfo(1,"param",1)), ..Message = $Get(tInfo(1,"param",2)) }
			else {
				set tMessage = $Get(tInfo(1))
				for tPtr = 2:1:tInfo { set tMessage = tMessage _ $$$NL _ tInfo(tPtr) }
				set ..Message = tMessage
				set ..SQLCode = -400
			}
		}
	}
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $zu(115,14) {
		if $Get(%xsqlCall) { set tCallString = %xsqlCall(1) for tPtr = 2:1:%xsqlCall { set tCallString = tCallString _ "->" _ %xsqlCall(tPtr) } }
		else { set tCallString = "" }
		do ##class(%XSQL.Log).traceMessage(tCallString_": destructing error object...",2,1)
		do ##class(%XSQL.Log).traceError($this)
	}
	Quit $$$OK
}

/// The %Status code of this error. An error will ALWAYS have a %Status value
Property Status As %Status;

/// This is computed from the value of Status
Property messageId As %Integer [ SqlComputeCode = { set {*}=$Select({Status}="":0,1:$List($List($Extract({Status},3,$Length({Status}))))) }, SqlComputed, SqlComputeOnChange = Status ];

/// The error code - for CacheError (messageId = 5002) this is the $ZError code ($e($ze,1,$f($ze,1,">"))
/// 	for SQLError (messageId = 5540) this is the SQLCODE value. For most other messageId's, this is 0 (zero).
/// Code simply provides additional detail for a %Status error
Property Code As %String(MAXLEN = 255) [ InitialExpression = "0" ];

/// SQLCode of this error, may be null.
Property SQLCode As %String(MAXLEN = "");

Method SQLCodeSet(newvalue As %String) As %Status
{
	set ..Code = newvalue
	quit $$$OK
}

Method SQLCodeGet() As %String
{
	quit ..Code
}

/// Additional free text information about the error, may be null
Property Message As %String(MAXLEN = "");

/// Severity is an indication as to the severity of the error being reported. The value, 0-25, not
/// only provides information, it is a hint to the error processor as to what action to take. For
/// TSQL this means returning control to the current batch or procedure at the point following the statement
/// reporting the error, exiting the current batch or procedure or terminating the connection.
/// TSQL defines severity of 10-19 as transferring to the CATCH block. InterSystems IRIS will exit the current
/// procedure if severity is > 19.
Property Severity As %Integer(MAXVAL = 25, MINVAL = 0);

/// findXRef - lookup a cross-referenced message in the requested domain
Method findXRef(messageDomain As %String) As %Integer [ CodeMode = expression ]
{
$Get(^%qSQL("mxc",..messageId,$Select(..Code'="":..Code,1:"0"),messageDomain),$Get(^%qSQL("mxc",0,0,messageDomain)))
}

/// asException() - return a new instance of an exception
Method AsException() As %Exception.AbstractException
{
	quit ##class(%Exception.StatusException).CreateFromStatus(..Status)
}

/// fromException() - instantiate a new %SYSTEM.Error object from an exception object.
ClassMethod FromException(pException As %Exception.AbstractException = "") As %SYSTEM.Error
{
		#; TODO: recognize difference exceptions so as to gather more specific SQL error information when available.
	quit ..%New(pException.AsStatus(),pException.AsSQLCODE(),pException.AsSQLMessage())
}

/// fromSQLCode() - instantiate a new %SYSTEM.Error object from an SQLCODE and message.
ClassMethod FromSQLCode(pSQLCODE As %Integer = -400, pMessage As %String(MAXLEN="") = "") As %SYSTEM.Error
{
		#; TODO: recognize difference exceptions so as to gather more specific SQL error information when available.
	quit ..%New($$$ERROR($$$SQLCode,pSQLCODE,pMessage),pSQLCODE,pMessage)
}

/// FromXSQL() - instantiate a new %SYSTEM.Error object from an error code that originates from	and XSQL procedure.
/// This is called from generated code for TSQL RAISERROR (v27) and Informix RAISE EXCEPTION (v25)
ClassMethod FromXSQL(pDomain As %String = "", pXSQLCODE As %Integer = 0, pMessage As %String(MAXLEN="") = "") As %SYSTEM.Error
{
	set tCacheError = ##class(%XSQL.System.CacheMessageXRef).findCache(pDomain,pXSQLCODE)
	if tCacheError = "" { set tCacheError = ##class(%XSQL.System.CacheMessageXRef).findCache(pDomain,0) }
	if tCacheError '= "" {
		set tCacheId = $List(tCacheError,1), tCacheCode = $List(tCacheError,2)
			// Prior to DLP3111, FromXSQL was not called from TSQL RAISERRROR, we simply set the error object's Code, Message, and SQLCode properties directly in the generated TSQL code.
			// The Code property contained the error number specified in the RAISERROR call.
			// After DLP3111, the Code property contained the SQLCODE (most likely -400), which after the TSQL trigger execution ended up in the %msg variable.
			// The %msg variable is composed of Code_","_Message
			// This caused backward incompatibility with customers (PL 134392 and PL 127353).
			// This next line will restore previous behavior.
		set:tCacheCode=-400&&(pXSQLCODE) tCacheCode=pXSQLCODE
		if (tCacheCode '= "") && (tCacheCode '= 0) { set tStatus = $$$ERROR(tCacheId,tCacheCode,pMessage) }
		else { set tStatus = $$$ERROR(tCacheId,pMessage) }
	}
	else { set tStatus = $$$ERROR(5521,-400,pMessage) }
	quit ..%New(tStatus,tCacheCode,pMessage)
}

Method getOdbcError(sqlcode, message)
{
	set message = ..Message_", %Status Code = "_..Code_", %Status Text = "_$$GetErrorText^%apiOBJ(..Status)
	if ..SQLCode { set sqlcode = ..SQLCode }
	else {
		set sqlcode = "", messageId = ..messageId
		if messageId = $$$ERRORCODE($$$SQLCode) || (messageId = $$$ERRORCODE($$$SQLError)) { set sqlcode = ..Code }
		elseif messageId = $$$ERRORCODE($$$ProcedureNotFound) { set sqlcode = -428 }
		if sqlcode = "" { set sqlcode = -400 }
	}
	quit
}

}
