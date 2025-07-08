/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syskio

/// <p>
/// This class implements the primary set of functions IRIS Native API for Object Script. The only other members 
/// of the IRIS Native API that are not implemented by this class are implemented by <class>%Net.DB.DataSource</class> and 
/// <class>%Net.DB.Connection</class>. This class should never be instantiated directly. The proper way to instantiate this class 
/// is to invoke the CreateIris() method using an instance of <class>%Net.DB.Connection</class>. 
/// </p>
/// <p>
/// </p>
Class %Net.DB.Iris Extends %RegisteredObject [ Final ]
{

/// <p>
/// Return the value of a global array node. The global array node reference is defined by a <var>globalName</var> and a variable number of <var>subscripts</var>. 
/// </p>
/// <p>
/// This method throws an exception if the global array node is not defined. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The value of the global array node. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Get(globalName As %String(MAXLEN=220), subscripts...) As %RawString
{
	try {
		set io = $IO
		set tSC = $$$OK
		set numSubscripts = $get(subscripts,0)
		do ..SendRequest($$$REXGETNODE,globalName,numSubscripts,subscripts...)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Return the boolean value of a global array node. The global array node reference is defined by a <var>globalName</var> and a variable number of <var>subscripts</var>. 
/// </p>
/// <p>
/// This method throws an exception if the global array node is not defined. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The value of the global array node. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method GetBoolean(globalName As %String(MAXLEN=220), subscripts...) As %Boolean [ CodeMode = expression ]
{
''..Get(.globalName,subscripts...)
}

/// <p>
/// Iterates to the next subscript in the $ORDER sense and returns the subscript, the value or both based on returnSubscript and returnValue flags.
/// The global array node reference is defined by a <var>globalName</var> and a variable number of <var>subscripts</var>. 
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>returnSubscript</td>
/// 			<td>input</td>
/// 			<td>If true, the value of the subscript is returned, defaults to 1 (true). </td>
/// 		</tr>
/// 		<tr>
/// 			<td>returnValue</td>
/// 			<td>input</td>
/// 			<td>If true, the value of the global array node at the position defined by <var>subscripts...</var> is returned, defaults to 0 (false). </td>
/// 		</tr>
/// 		<tr>
/// 			<td>isReveresed</td>
/// 			<td>input</td>
/// 			<td>If true, the iteration is in reverse order, defaults to 0 (forward). </td>
/// 		</tr>
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>
/// 				The subscript and/or value of the global array node at the position defined by $order of the <var>subscripts...</var>. If both the 
/// 				value and the subscript are returned then a $list with the subscript in element position 1 and the value in element position 2 is returned. 
/// 				If the $order advances to the end and there are no further subscripts defined then the return value is null. 
/// 		 	</td>
/// 		</tr>
/// 	</table>
/// </p>
Method GetNext(returnSubscript As %Boolean = 1, returnValue As %Boolean = 0, isReversed As %Boolean = 0, globalName As %String(MAXLEN=220), subscripts...) As %RawString
{
	set reply = ""
	try {
		set io = $IO
		if '$get(subscripts) {
			set subscripts = 1, subscripts(1) = ""
		}
		set numSubscripts = subscripts
		set subscripts = $increment(subscripts)
		set flags = (isReversed * 4) + (returnSubscript * 2) + returnValue
		set subscripts(subscripts) = flags
		do ..SendRequest($$$REXORDER,globalName,numSubscripts,subscripts...)
		set reply = $system.IS.Receive()
		if $zb=$char(255) {
			set reply = ""
		} elseif (flags > 2) && (reply '= "") {
			set reply = $listbuild(reply,$system.IS.Receive())
		}
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Set the value of a global array node. The global array node reference is defined by a <var>globalName</var> and a variable number of <var>subscripts</var>. 
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>value</td>
/// 			<td>input</td>
/// 			<td>The value to be stored. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Set(value As %RawString, globalName As %String(MAXLEN=220), subscripts...) As %RawString
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts)
		set subscripts(subscripts) = value
		do ..SendRequest($$$REXSETNODE,globalName,numSubscripts,subscripts...)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Kill the value of a global array node, including any descendants.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Kill(globalName As %String(MAXLEN=220), subscripts...)
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		do ..SendRequest($$$REXKILLNODE,globalName,numSubscripts,subscripts...)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Increments a global node by the given integer value. Returns the new value of the node.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>value</td>
/// 			<td>input</td>
/// 			<td>The value by which to increment the global array node. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The value of the global array node after incremented it by <var>value</var>. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Increment(value, globalName As %String(MAXLEN=220), subscripts...) As %Integer
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts)
		set subscripts(subscripts) = value
		do ..SendRequest($$$REXINCREMENT,globalName,numSubscripts,subscripts...)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Checks if a a global contains data ($DATA).
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>0 if the node is undefined, 1 if the global node exists and contains data, 10 if it's an array element that has descendants, 11 has data and descendants. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method IsDefined(globalName As %String(MAXLEN=220), subscripts...) As %Integer
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts)
		set subscripts(subscripts) = 0 // flags = GFL_VALUE 0
		do ..SendRequest($$$REXDATA,globalName,numSubscripts,subscripts...)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Calls a class method, passing zero or more arguments and returning the method's return value.
/// Trailing arguments may be omitted, causing default values to be used for those arguments.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>className</td>
/// 			<td>input</td>
/// 			<td>The name of the class that implements the method to be called. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>methodName</td>
/// 			<td>input</td>
/// 			<td>The name of the method to be called. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>args</td>
/// 			<td>input...</td>
/// 			<td>The arguments to be passed to the method. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The value returned by the <var>methodName</var> method. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method ClassMethodValue(className, methodName, args...) As %RawString
{
	set io = $IO
	try {
		set numArgs = $get(args,0)
		do ..SendRequest($$$REXVALUECLASSMETHOD,className,methodName,numArgs,args...)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Calls a class method with no return value, passing zero or more arguments.
/// Trailing arguments may be omitted, causing default values to be used for those arguments.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>className</td>
/// 			<td>input</td>
/// 			<td>The name of the class that implements the method to be called. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>methodName</td>
/// 			<td>input</td>
/// 			<td>The name of the method to be called. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>args</td>
/// 			<td>input...</td>
/// 			<td>The arguments to be passed to the method. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method ClassMethodVoid(className, methodName, args...)
{
	set io = $IO
	try {
		set numArgs = $get(args,0)
		do ..SendRequest($$$REXVOIDCLASSMETHOD,className,methodName,numArgs,args...)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Calls a function (label^routine), passing zero or more arguments and returning the function's return value.
/// Trailing arguments may be omitted, causing default values to be used for those arguments.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>routineName</td>
/// 			<td>input</td>
/// 			<td>The name of the routine that implements the function to be called. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>functionName</td>
/// 			<td>input</td>
/// 			<td>The name of the function to be invoked. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>args</td>
/// 			<td>input...</td>
/// 			<td>The arguments to be passed to the method. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>The value returned by the <var>functionName</var> function. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Function(routineName, functionName, args...) As %RawString
{
	try {
		set io = $IO
		set numArgs = $get(args,0)
		do ..SendRequest($$$REXVALUEFUNCTION,functionName,routineName,numArgs,args...)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// <p>
/// Calls a procedure (label^routine) with no return value, passing zero or more arguments.
/// Trailing arguments may be omitted, causing default values to be used for those arguments.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 		<tr>
/// 			<td>routineName</td>
/// 			<td>input</td>
/// 			<td>The name of the routine that implements the function to be called. </td>
/// 		</tr>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>functionName</td>
/// 			<td>input</td>
/// 			<td>The name of the function to be invoked. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>args</td>
/// 			<td>input...</td>
/// 			<td>The arguments to be passed to the method. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Procedure(routineName, procedureName, args...)
{
	try {
		set io = $IO
		set numArgs = $get(args,0)
		do ..SendRequest($$$REXVOIDPROCEDURE,procedureName,routineName,numArgs,args...)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Lock the global node, returns true on success.
/// Note that this method performs an incremental lock and not the implicit unlock before lock feature that is also offered in COS.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>lockMode</td>
/// 			<td>input</td>
/// 			<td>A combination of the following chars, S for shared lock, E for escalating lock, default is empty string (exclusive and non-escalating). </td>
/// 		</tr>
/// 		<tr>
/// 			<td>timeout</td>
/// 			<td>input</td>
/// 			<td>The number of seconds to wait to acquire the lock. -1 means infinite (no) timeout. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>1 (true) if the lock is successfully acquired. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Lock(lockMode, timeout, globalName As %String(MAXLEN=220), subscripts...) As %Boolean
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts,2)
		set subscripts(subscripts-1) = lockMode
		set subscripts(subscripts) = timeout
		do ..SendRequest($$$REXLOCK,globalName,numSubscripts,subscripts...)
	} catch ex {
		use io
		throw ex
	}
	use io
	return 1
}

/// <p>
/// Unlock the global node.
/// Note that this method performs an incremental unlock and not the implicit unlock before lock feature that is also offered in COS.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>lockMode</td>
/// 			<td>input</td>
/// 			<td>
/// 				A combination of the following chars, S for shared lock, E for escalating lock, I for immediate unlock, D for deferred unlock. 
/// 				default is empty string (exclusive and non-escalating). 
/// 			</td>
/// 		</tr>
/// 		<tr>
/// 			<td>globalName</td>
/// 			<td>input</td>
/// 			<td>The name of the global array. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>subscripts</td>
/// 			<td>input...</td>
/// 			<td>The subscripts to the global named by the first parameter. Together with the global name they form the full global reference. </td>
/// 		</tr>
/// 	</table>
/// </p>
Method Unlock(lockMode, globalName As %String(MAXLEN=220), subscripts...)
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts)
		set subscripts(subscripts) = lockMode
		do ..SendRequest($$$REXUNLOCK,globalName,numSubscripts,subscripts...)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Release all locks associated with the session.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method ReleaseAllLocks() As %Status
{
	try {
		set io = $IO
		do ..SendRequest($$$REXUNLOCKALL)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Start/open a transaction.
/// This is equivalent to executing TSTART in a InterSystems IRIS terminal.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method TStart()
{
	try {
		set io = $IO
		do ..SendRequest($$$REXTSTART)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Commit the current transaction.
/// This is equivalent to executing TCOMMIT in a InterSystems IRIS terminal.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method TCommit() As %Status
{
	try {
		set io = $IO
		do ..SendRequest($$$REXTCOMMIT)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Roll back all open transactions in the session.
/// This is equivalent to executing TROLLBACK in a InterSystems IRIS terminal.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method TRollback()
{
	try {
		set io = $IO
		do ..SendRequest($$$REXTROLLBACK)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Roll back the current level transaction only.
/// If this is a nested transaction, any higher-level transactions will not be rolled back.
/// This is equivalent to executing TROLLBACK 1 in a InterSystems IRIS terminal.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method TRollbackOne()
{
	try {
		set io = $IO
		do ..SendRequest($$$REXTROLLBACKONE)
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// <p>
/// Get the level of the current nested transaction.
/// Returns 1 if there is only a single transaction open. Returns 0 if there are no transactions open.
/// This is equivalent to fetching the value of the $TLEVEL special variable.
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method GetTLevel() As %Integer
{
	try {
		set io = $IO
		do ..SendRequest($$$REXGETTLEVEL)
		set reply = $system.IS.Receive()
	} catch ex {
		use io
		throw ex
	}
	use io
	return reply
}

/// </p>
/// GetObject returns an object from the connected data source. This method accepts the name of the persistent 
/// class in the remote IRIS namespace and the ID of the requested object. The return value is an instance 
/// of <class>%Library.DynamicAbstractObject</class>. All properties defined in the requested class will be 
/// present in the result object except streams and relationships are not yet supported. The remote class must have 
/// a unified schema defined. Any properties whose type class is a subclass of <class>%Library.SerialObject</class> 
/// must also have a defined unified schema. Unified schemas are instances of <class>%FOI.Schema</class>. 
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method GetObject(className As %String(MAXLEN=220) = "", id) As %Library.DynamicAbstractObject
{
	try {
		set response = $$$NULLOREF
		set schema = ..GetSchema(className)
		if $isObject(schema) {
			do ..pushContext(className)
			set recordmd = ..schemas(className,0)
			set global = recordmd.global
			if $isObject(recordmd.subscripts) {
				set subscriptCount = recordmd.subscripts.%Size()
				if subscriptCount = 1 {
					set subscripts(1) = id
				} elseif subscriptCount {
					set sit = recordmd.subscripts.%GetIterator()
					while sit.%GetNext(.key,.subscript) {
						// implement composite ID's later - we will need to know about ID component values that are also composite ID's.
					}
				} else {
						// no subscripts?
				}
				set subscripts = subscriptCount
			}
			if $isObject(recordmd.type) {
				set response = ..deserializeObject(recordmd,global,.subscripts)
			} elseif schema.type '= "" {
					// simple literal must be or a named type?
				do ..GetRows(.response,1,1,global,subscripts...) // $$$GFLVALUE + $$$REXGFLSUBS
			} else {
				set response = ""
			}
			do ..popContext()
		}
	} catch exception {
		set response = $$$NULLOREF
		throw exception
	}
	return response
}

/// <p>
/// %FOI.Schema instances are specific to a connection - url, port, and namespace. Remote schemas are cached by the Connection instance (client? or is that a bad word?). 
/// The cache only lasts as long as the Connection instance. 
/// </p>
/// <p>
/// There are no checks for stale cache entries at this time.
/// </p>
/// <p>
/// If a schema for the requested class or any of the embedded properties defined by that class does not exist then an exception is thrown. There is no database first 
/// feature implemented yet. 
/// </p>
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method GetSchema(schemaName As %String(MAXLEN=220)) As %Library.DynamicAbstractObject
{
#dim response as %Library.DynamicAbstractObject
	try {
			// so here we are, getting schema metadata. We need to get this through the connection (using the DB Native API) but we might have it 
			// cached. We also might be dealing with a primitive so we can bypass a server call in those cases.
		if '$data(..schemas(schemaName),schema) {
			set schemaString = ..ClassMethodValue("%FOI.Schema","getSchema", schemaName)
			set schema = ##class(%DynamicAbstractObject).%FromJSON(schemaString)
			set ..schemas(schemaName) = schema
			do ..GetRecordMetadata(schemaName)
		}
	} catch exception {
		set schema = ""
		throw exception
	}
	return schema
}

/// %FOI.Schema instances are specific to a connection - url, port, and namespace. Remote schemas are cached by the Native instance (client? or is that a bad word?). 
/// The cache only lasts as long as the Native instance. 
/// </p>
/// <p>
/// This method throws an exception when an error condition is encountered. 
/// </p>
Method GetRecordMetadata(schemaName As %String(MAXLEN=220)) As %Library.DynamicAbstractObject
{
#dim response as %Library.DynamicAbstractObject
	try {
		if '$data(..schemas(schemaName,0),recordmd) {
			set recordmdstring  = ..ClassMethodValue("%FOI.Schema","getRecordDefinition", schemaName)
			set recordmd = ##class(%DynamicAbstractObject).%FromJSON(recordmdstring)
			set ..schemas(schemaName,0) = recordmd
		}
	} catch exception {
		set recordmd = ""
		throw exception
	}
	return recordmd
}

/// ---- internal schema cache - used by GetObject
Property schemas As %Library.RawString [ Internal, MultiDimensional ];

/// ---- internal context stack - used by GetObject
Property context As %RawString [ Internal, MultiDimensional ];

Property Connection As %Net.DB.Connection [ Internal ];

/// ------------- Constructor, Destructor --------------
/// Note that there is no connect when this instance is created.
/// You have to call Connect on the connection object, not via this class.
Method %OnNew(connection) As %Status [ Internal ]
{
	set ..Connection = connection
	quit $$$OK
}

/// Note that there is no disconnect when this instance is killed.
/// You have to call Disconnect on the connection object, not via this class.
Method %OnClose() As %Status [ Internal ]
{
	quit $$$OK
}

/// Iterates over all subscripts in the $ORDER sense and produces a $List of rows.
Method GetRows(Output reply, returnSubscripts As %Boolean = 0, returnValues As %Boolean = 1, globalName As %String(MAXLEN=220), subscripts...) As %Status [ Internal ]
{
	try {
		set io = $IO
		set numSubscripts = $get(subscripts,0)
		set subscripts = $increment(subscripts)
		set subscripts(subscripts) = (returnSubscripts * 2) + returnValues
		do ..SendRequest($$$REXGETSUBNODES,globalName,numSubscripts,subscripts...)
		set reply = ""
		for  {
			set x = $system.IS.Receive()
			if x="",$zb=$char(255) quit // check for end of sequence
			set reply = reply_$listbuild(x)
		}
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// Copies an entire global and resurrects it as a local or global variable.
/// The globalName argument is required. It's name of the global on the remote server that you want to copy. It can include the "^" or not.
/// The rootName argument is optional. It's the name of the local or global variable that you want to copy to.
/// 	It must include the "^" to save it in a global, otherwise it will save it in a local variable.
/// 	If you don't pass this argument or pass the empty string, then the global is copied into a global of the same name.
Method CopyGlobal(globalName As %String(MAXLEN=220), rootName = "") As %Status [ Internal ]
{
	try {
		set io = $IO
		do ..SendRequest($$$REXGETGLOBAL,globalName)
		for {
			set nodeName = $system.IS.Receive()
			set nodeValue = $system.IS.Receive()
			quit:nodeName=""
			
			if (rootName'="") {
				set nodeName = $piece(nodeName,"(",2)
				set nodeName = rootName_$case(nodeName,"":"",:"("_nodeName)
			}
			set @nodeName = nodeValue
		}
	} catch ex {
		use io
		throw ex
	}
	use io
}

/// ------------- Debug Methods -------------
/// The new $system.IO protocol now uses the same 14-byte header as the old $zobjexport protocol.
/// So the DBSRV routine will delegate to $system.IS.Execute accordingly depending on the opcode value,
/// and we no longer need a separate message just to stop/exit the $system.IO kernel-level loop.
/// The method is left here just in case it becomes useful in future debugging to be able to explicitly break out of the kernel-level loop.
Method StopSYSIO() As %Status [ Internal, Private ]
{
	if '..Connection.IsConnected {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Not connected to remote process"))
	}
	try {
		set io = $IO
		use ..Connection.Device
		set x = $System.OS.SendRequest(..Connection.NextMessageId(),1,$$$REXSTOP)
	} catch ex {
		use io
		throw ex
	}
	use io
}

Method flushContext() [ Internal, Private ]
{
	kill i%context
	set i%context = ""
}

Method pushContext(schemaname) [ Internal, Private ]
{
	set i%context($increment(i%context)) = schemaname
	return i%context
}

Method popContext() As %RawString [ Internal, Private ]
{
	set context = i%context(i%context)
	kill i%context(i%context)
	set i%context = i%context - 1
	return context
}

/// outermost deserializer for an IRIS Object. Accepts global reference and subscripts. This method iterates over fields and 
/// retrieves data from the connection as indicated by the fields in the record metadata. From that point on, all values are 
/// extracted from the object's data and dispatched to value deserializers. 
/// <var>schema</var> is the record metadata object and it is needed to retrieve named types. 
/// Sample test commands:
/// 	set native = ##class(%Net.DB.DataSource).GetConnection(,51774,"DEV","danp","SYS")
/// 	set obj = native.GetObject("Sample.Person",1) 
Method deserializeObject(recordmd As %Library.DynamicObject, global As %Library.RawString, ByRef subscripts) As %Library.RawString [ Internal, Private ]
{
	set type = recordmd.type
	if $isObject(type) {
		set object = {}
			// This record deserializer is different from others in that it retrieves the serialized record from a global. 
			// Once the data is retrieved, normal deserialization occurs using recursive deserializeValue calls. However, 
			// since a majority of objects are serialized as list nodes and there is a limited number of "structure"s, 
			// we will test for structure here and dispatch directly to the node deserializers. 
		if type.type = "record" {
				// A record has an array of fields and it has structure and a subscript. Retrieve the data node and dispatch to the 
				// deserializer for the specified structure.
			set fit = type.fields.%GetIterator()
			while fit.%GetNext(.key,.field) {
				kill data
				if field.structure = "list" {
						// data retrieval and deserialization should be separated, structure impacts retrieval 
						// but deserializer should be based on type 
					try {
						if field.subscript = "" {
							set data = ..Get(global,subscripts...)
						} else {
							set subscripts = subscripts + 1
							set subscripts(subscripts) = field.subscript
							set data = ..Get(global,subscripts...)
							kill subscripts(subscripts)
							set subscripts = subscripts - 1
						}
						if data '= "" {
							set object = ..deserializeRecordList(field.type,object,.data)
						}
					} catch fetchException {
							// data wasn't defined but we can populate with nulls?
					}
				} elseif field.structure = "node" {
					set subscripts = subscripts + 1
					set subscripts(subscripts) = field.subscript
					set data = ..Get(global,subscripts...)
					kill subscripts(subscripts)
					set subscripts = subscripts - 1
					do object.%Set(field.name,..deserializeValue(field.type,.data))
				} elseif field.structure = "subnode" {
					if field.subscript = "" {
						do ..GetRows(.data,1,1,global,subscripts...) // $$$GFLVALUE + $$$REXGFLSUBS
					} else {
						set subscripts = subscripts + 1
						set subscripts(subscripts) = field.subscript
						do ..GetRows(.data,1,1,global,subscripts...) // $$$GFLVALUE + $$$REXGFLSUBS
						kill subscripts(subscripts)
						set subscripts = subscripts - 1
					}
					do object.%Set(field.name,..deserializeValue(field.type,.data))
				}
			}
		} elseif type.type = "" {
		} else {
		}
	} else {
		set object = ""
	}
	return object
}

Method deserializeValue(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
	set deserializer = ..getTypeCategory(type)
	return $case(deserializer.category,
			"primitive"		: value,
			"logical"		: ..deserializeLogical(deserializer.type,.value),
			"record"		: ..deserializeRecord(type,.value),
			"enum"			: ..deserializeEnum(deserializer.symbols,.value),
			"array"			: ..deserializeArray(type.items,.value),
			"map"			: ..deserializeMap(type.values,.value),
			"fixed"			: value,
			"named"			: ..deserializeNamed(deserializer.type,.value),
			"embedded"		: ..deserializeRecord(type.type,.value),
			"persistent"	: "",
							: value
			)
}

Method deserializeLogical(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
	if type.logicalType = "date" {
		if type.type = "int" {
			if type.epoch = "1840-12-31" {
				return $select(type.format="":$zdate(value),1:$zdate(value,type.format))
			}
		}
	} elseif type.logicalType = "%OID" {
		set oid = ..deserializeValue(type.type,value)
		if type.classname {
			return oid
		} else {
			return oid.id
		}
	}
	return ..deserializeValue(type.type,.value)
}

Method deserializeArray(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
	set array = []
	set ptr = 0
	while $listnext(value,ptr,element) {
		do array.%Push(..deserializeValue(type,element))
	}
	return array
}

Method deserializeMap(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
		// This model won't support nested subnode structures, we would need to know about the subscripts array in order to continue this descent
		// A map ($list serialized %Collection.AbstractArray) is $lb(elements) where each element is $lb(sub,value).
	try {
		set response = {}
		set ptr = 0
		while $listnext(value,ptr,entry) {
			if entry '= "" {
				set subscript = $listget(entry,1)
				if subscript '= "" {
					set element = $listget(entry,2)
					do response.%Set(subscript,..deserializeValue(.type,element))
				}
			}
		}
	} catch exception {
		throw exception
	}
	return response
}

Method deserializeEnum(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
}

/// type here is not record metadata, it is the type category with category = 'named' and name = type name. 
/// this method is only ever called with type = {"category":"named","name":<typename>,"namespace":<typenamespace>}. 
/// "namespace" is optional but "name" is not. 
/// But, just for completeness, type can be passed as a literal string that is a name. 
Method deserializeNamed(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.RawString [ Internal, Private ]
{
	if $isobject(type) {
		if '$isobject(type.type) {
			set typeName = type.type
			set typeNamespace = ""
		} elseif type.name '= "" {
			set typeName = type.name
			set typeNamespace = type.namespace
		}
	} else {
		set typeName = type
		set typeNamespace = ""
	}
	set schema = ..schemas(..context(..context))
	set fullname = $select(typeName[".":"",typeNamespace'="": typeNamespace _ ".",schema.namespace'="":schema.namespace _ ".",1:"") _ typeName
	if $isobject(schema.namedTypes) {
		set namedType = schema.namedTypes.%Get(typeName)
		if namedType '= "" {
			return ..deserializeValue(namedType,.value)
		}
		set namedType = schema.namedTypes.%Get(fullname)
			// and try the local named type once again
		if namedType '= "" {
			return ..deserializeValue(namedType,.value)
		}
	}
		// must be a referenced schema
	set schema = ..GetSchema(fullname)
	if $isobject(schema) {
		set recordmd = ..GetRecordMetadata(fullname)
		do ..pushContext(fullname)
		set response = ..deserializeValue(recordmd,.value)
		do ..popContext()
	}
	return response
}

Method deserializeRecord(type As %Library.RawString = "", ByRef value As %Library.RawString) As %Library.DynamicAbstractObject [ Internal, Private ]
{
	set response = ""
	if $isobject(type) {
		if type.structure = "list" {
			return ..deserializeRecordList(type,{},.value)
		} else {
				// implement elseif's for each supported structure
		}
	} else {
	}
	return response
}

Method deserializeRecordList(type As %Library.RawString = "", target As %Library.DynamicAbstractObject, list As %Library.RawString) As %Library.DynamicAbstractObject [ Internal, Private ]
{
	if $isobject(type) {
		if type.type = "record" {
			set response = target
			set fit = type.fields.%GetIterator()
			while fit.%GetNext(.ptr,.field) {
					// we need to recognize the type - primitive, logical, complex, named.
				do target.%Set(field.name,..deserializeValue(field.type,$listget(list,ptr + 1)))
			}
			set response = target
		} else {
		}
	} else {
	}
	/*
			} catch deserializationException {
				set response.error = deserializationException.AsStatus()
				set response.elementName = $get(elementName,"unknown")
				set response.elementValue = $get(elementValue,"unknown")
				set response.elementType = $get(elementType,"unknown")
			}

	*/
	return response
}

Method getTypeCategory(type As %Library.DynamicAbstractObject) As %Library.DynamicAbstractObject [ Internal, Private ]
{
#dim exception as %Exception.AbstractException
	try {
			// first, check for a valid type and then a primitive.
			// logicaltype
			// then check for named types - record, num, fixed
			// array and map
			// and, finally, check for a referenced named type ( btw - primitive check does this also when type = name)
		if '$isobject(type) {
				// check for primitives
			if ..isPrimitive(type) {
				return {"category":"primitive", "type":(type)}
			} else {
					// type is not an object, the only other thing it can be is a named type
				return {"category":"named","type":(type)}
			}
		} elseif type.category '= "" {
			return type
		} elseif type.%IsA("%Library.DynamicArray") {
			// union
		} elseif ..isLogicalType(type) {
			return {"category":"logical","type":(type)}
		} elseif ..isPrimitive(type.type) {
			return {"category":"primitive", "type":(type)}
		} elseif type.type = "record" {
			return {"category":"record","type":(type)}
		} elseif type.type = "enum" {
			return {"category":"enum","symbols":(type.symbols)}
		} elseif type.type = "array" {
			return {"category":"array","items":(type.items)}
		} elseif type.type = "map" {
			return {"category":"map","values":(type.values)}
		} elseif type.type = "fixed" {
			return {"category":"fixed"}
		} elseif type.name '= "" {
				// named type - look it up
			return {"category":"named","name":(type.name), "namespace":(type.namespace)}
		} else {
				// don't really know what we have...an error, perhaps?
		}
	} catch exception {
		throw exception
	}
	return {"category":"unknown","type":(type)}
}

ClassMethod isPrimitive(type As %String) As %Boolean [ CodeMode = expression, Internal, Private ]
{
$case(type,
			"string"	: 1,
			"int"		: 1,
			"long"		: 1,
			"boolean"	: 1,
			"double"	: 1,
			"float"		: 1,
			"bytes"		: 1,
			"null"		: 0,
						: 0)
}

Method isLogicalType(type As %Library.DynamicObject) As %Boolean [ Internal, Private ]
{
	set response = 
	$case($$$lcase(type.logicalType),
		"decimal"			: 1,
		"date"				: 1,
		"time-millis"		: 1,
		"time-micros"		: 1,
		"timestamp-millis"	: 1,
		"timestamp-micros"	: 1,
		"%oid"				: 1,
							: 0
	)
	return response
}

/// ------------- Low-level Send, Receive Methods -------------
/// Sends the request and reads the reply header.
/// This method uses the connection device and leaves it as the current device.
/// That is, the calling device is Not preserved.
/// Throws exception on error
Method SendRequest(arguments...) [ Internal, Private ]
{
	if '..Connection.IsConnected {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Not connected to remote process"))
	}
	use ..Connection.Device
	set msgid = ..Connection.NextMessageId()
	do $system.OS.SendRequest(msgid,1,arguments...)

	// regular reply: $lb(0,msgid,context,ercode)
	// reentrant $sys.IO request: $lb(1,msgid,context,opcode)
	// reentrant DBSRV request: $lb(2,msgid,context,opcode)
	set header = $system.IS.ReceiveReply()
	if ($list(header,1)'=0) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Reentrant request"))
	}
	if (msgid'=$list(header,2)) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Reply message id does not match request"))
	}
	set ercode = $list(header,4)
	if (ercode'=0) {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Exception returned: "_$zu(96,1,(ercode-1000))))
		// Ztrap $ZUTIL(96,3,$zu(96,1,(ercode-1000)))  ; Throws error to caller
	}
}

}
