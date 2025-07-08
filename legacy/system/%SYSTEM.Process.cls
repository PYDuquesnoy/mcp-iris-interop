/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySite, %syPidtab, %sySystem)

/// The %SYSTEM.Process class allows manipulation and display of the current process.
/// Some of the class methods defined here have restrictions on where they may be
/// called.  Read the descriptions carefully.
/// <p>
/// There are two different syntaxes that can be used to call the class methods in
/// this package:  one uses the usual ##class syntax and the other uses $system.  Here
/// are two examples of calling ThrowError to signal the &lt;UNIMPLEMENTED&GT; error.
/// <EXAMPLE>
/// do $system.Process.ThrowError(22)
/// do ##class(%SYSTEM.Process).ThrowError(22)
/// </EXAMPLE>
/// 
Class %SYSTEM.Process Extends %SYSTEM.Help [ System = 4 ]
{

/// The <b>ThrowError(errnum)</b> class method signals the error message that
/// corresponds to the value of <b>errnum</b>. The error message occurs at
/// the first stack
/// level above the level that was pushed onto the stack by the invocation of a
/// user-defined command. Refer to %ZLANG for further information on user-defined
/// commands in ObjectScript. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>errnum</b> -- A system error number, specified as an
/// expression that resolves to a positive integer.  This parameter is optional
/// and if the parameter is missing then the most recently thrown system error
/// number is thrown again.
/// 
ClassMethod ThrowError(errnum As %Integer) As %String
{
}

/// The <b>CallingRoutine()</b> class method returns the name of the routine
/// that made the last DO or user-defined call to the current routine
/// invoking this function.<br>
/// If no calling routine exists, CallingRoutine() returns the null string.
/// 
ClassMethod CallingRoutine() As %String
{
}

/// The <b>CallingDatabase()</b> class method returns the directory name of the
/// database that contains the routine that made the last DO or user-defined
/// call to the current routine invoking this function.<br>
/// If no calling routine exists, CallingDatabase() returns the null string.
/// 
ClassMethod CallingDatabase() As %String
{
}

/// The <b>ParentRoutine()</b> class method returns the name of the routine
/// that issued the JOB command to start this process.<br>
/// If no parent routine exists, ParentRoutine() returns the null string.<br>
/// The routine name must be retrieved before the process throws an error. It
/// will be the null string if there has been an error.
/// 
ClassMethod ParentRoutine() As %String
{
}

/// The <b>ParentDatabase()</b> class method returns the directory name of the
/// database that contains the routine that issued the JOB command to start
/// this process.<br>
/// If no parent routine exists, ParentDatabase() returns the null string.<br>
/// The database name must be retrieved before the process throws an error. It
/// will be the null string if there has been an error.
/// 
ClassMethod ParentDatabase() As %String
{
}

/// The <b>RandomSeed(seed)</b> class method provides a way to modify the
/// current random seed value of $Random.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>seed</b> -- the new random seed value for $Random. Legal values are any
/// 64-bit signed integer (-9223372036854775808 to 9223372036854775807)<br>
/// <p>
/// Invoking RandomSeed() without specifying the seed parameter returns the
/// current random seed value of $Random.
/// <p>
/// <b>Return value</b> -- the previous random seed value prior to calling 
/// the RandomSeed method.
/// 
ClassMethod RandomSeed(seed As %Integer) As %Integer
{
}

/// The <b>StepInfo()</b> class method is invoked during debugging and
/// returns information about the location of the last single step
/// entered.
/// <p>
/// <b>Return Values</b>
/// <p>
/// This function returns the following information about the last
/// single step entered:<br>
/// &lt;stacklevel&gt;&lt;xeclevel&gt;&lt;lineref&gt;&lt;srcoffset&gt;&lt;src&gt;<br>
/// where:
/// <p>
/// stacklevel -- $STACK level of the breakpoint.<br>
/// xeclevel -- XECUTE level of the breakpoint.<br>
/// lineref -- Line reference of the breakpoint.<br>
/// srcoffset -- 0-based offset to the location in the source line
/// where the break has occurred.<br>
/// src -- Source line of the breakpoint.
/// <p>
/// This function is a useful primitive in the development of trace
/// capabilities beyond what is offered by the "T" action.
/// <p>
/// You can invoke StepInfo() only in the condition expression or
/// the execute code associated with a<br>
/// ZBREAK $::condition:execute<br>
/// breakpoint, or in routines and functions invoked from these
/// contexts.
/// <p>
/// You must have the %Development:Use privilege to execute the
/// StepInfo function.  
/// 
ClassMethod StepInfo() As %String
{
}

/// The <b>LanguageMode(mode)</b> class method returns or changes the current language mode.
/// <p>
/// You can use LanguageMode to change the language mode at the programmer prompt.
/// <p>
/// When the system executes a routine, it automatically changes the language mode to the routine's
/// language mode. A DO command or a $$ extrinsic function temporarily changes the language mode
/// to that of the called routine. The system then restores the previous language mode when the
/// routine terminates. Therefore, you need not (and cannot) change the language mode during
/// runtime execution of a routine.
/// <p>
/// The ZLOAD command changes the language mode to the loaded routine's language mode. However,
/// ZLOAD does not restore the previous language mode upon termination of the routine. One use
/// of LanguageMode is to set the language mode following a ZLOAD operation.
/// <p>
/// LanguageMode can change the process' language mode at any time. However, when executing a
/// routine you should only do this under XECUTE, and restore before leaving the XECUTE
/// operation. This technique is commonly used to set language mode when compiling a routine.
/// <p>
/// The object code (tokens, mcode, and so on) for a routine is generated at compile time
/// according to the language mode in effect at that time. This language mode determines the
/// routine's runtime behavior, except for a few cases where language mode is tested at runtime.
/// <p>
/// Any form of indirection (for example, an XECUTE command, or the @ indirection operator)
/// is evaluated at runtime according to the current language mode. This language mode may
/// not be the same as the language mode of the running routine.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>mode</b> -- Optional -- A numeric code specifying what language mode to set.
/// <p>
/// <b>Language Mode Codes</b>
/// <p>
/// 0 -- Set language mode to ObjectScript. (0 is the usual default)<br>
/// 1 -- Set language mode to DSM-11.<br>
/// 2 -- Set language mode to Open M [DTM].<br>
/// 5 -- Set language mode to DSM for OpenVMS.<br>
/// 6 -- Set language mode to DSM-J (Japanese) for OpenVMS.<br>
/// 7 -- Set language mode to DTM-J (Japanese) for OpenVMS.<br>
/// 8 -- Set language mode to MSM. MSM mode changes the use of the $ZC ($ZCHILD) special variable. 
/// <p>
/// <b>Notes:</b>
/// <p>
/// If you change the language mode with the LanguageMode class method so that it does not
/// match that of the loaded routine, and then attempt to do a ZINSERT, you will get a
/// &lt;LANGUAGE MISMATCH&gt; error message.
/// <p>
/// In language modes 1 (DSM-11) and 8 (MSM) five-character error codes are used: &lt;FUNCT&gt;,
/// &lt;UNDEF&gt;, &lt;SYNTX&gt;, &lt;DIVER&gt; (division error), and so forth.
/// <p>
/// Invoking LanguageMode() without specifying any parameter codes returns the
/// language mode code as an integer.
/// <p>
/// <b>Return value</b> -- the language mode integer code prior to calling the
/// LanguageMode method.
/// 
ClassMethod LanguageMode(mode As %Integer) As %Integer
{
}

/// Sets the current namespace to the given namespace.
/// 
ClassMethod SetNamespace(namespace As %String = "") As %String
{
	
 s $Namespace=namespace
 q namespace
}

/// The <b>MemoryAutoExpandStatus()</b> class method returns a value that
/// allows the caller to determine the reason for the last &LT;STORE&GT; 
/// error that has been thrown.
/// <p>
/// <b>Return value</b> -- one of the following values can be returned:<p>
/// 0 -- The job has never had a &LT;STORE&GT; error thrown.<br>
/// 1 -- The &LT;STORE&GT; error was thrown because the process exceeded the $ZSTORAGE value. An additional 1M was temporarily allocated for recovery.<br>
/// 2 -- The &LT;STORE&GT; error was thrown because the process exceeded the the extra 1M. The process will likely be terminated before this status can be seen.<br>
/// 3 -- The &LT;STORE&GT; error was thrown because of reasons other than exceeding the $ZSTORAGE value.
/// <p>
/// Return value 3 is typically returned when the operating system refuses to give
/// more memory to the process. Typical reasons (but not an exhaustive list) can be because the operating system
/// has run out of swap space. On Unix based systems it could be because you have exceeded a system enforced limit
/// (for example 'ulimit -v' on some platforms sets a limit on the maximum virtual memory size).
ClassMethod MemoryAutoExpandStatus() As %Integer
{
}

/// The <b>IODollarTest(flag)</b> class method specifies how to handle the $TEST special
/// variable on return from I/O redirection by issuing this function. By default, the
/// value of $TEST is preserved (stored and restored) across a call to extrinsic code,
/// such as I/O redirection code. However, you may wish to return the setting of $TEST
/// from I/O redirection code. For example, if application code invokes a READ command
/// with I/O redirection, and the READ times out, this timeout sets $TEST in your
/// application. To preserve this setting of $TEST upon returning from I/O redirection
/// code, you must invoke LanguageMode within the I/O redirection code.
/// <p>
/// Note: LanguageMode can only be invoked from extrinsic code. It cannot be called
/// directly from the terminal. Attempting to do so results in a &lt;FUNCTION&gt; error. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>flag</b> -- boolean value used to set the $TEST special variable upon return
/// from I/O redirection code.<br>
/// 0 -- Clears $TEST (sets to 0) on return from the redirected READ.<br>
/// 1 -- Sets $TEST (sets to 1) on return from the redirected READ. 
/// 
ClassMethod IODollarTest(flag As %Boolean) As %String
{
}

/// Get CPU time used for current process.<br>
/// <br>
/// Returns two comma-delimited pieces, "system" CPU time and "user" CPU time 
/// (except on VMS where no separate times are available). Time is returned
/// as milliseconds of CPU time.
ClassMethod GetCPUTime() As %String
{
	q $ZU(171,1)
}

/// Returns the possible reasons for the last &lt;STORE&gt; error as follows.<br>
/// <br>
/// 0 - No &lt;STORE&gt; error has yet occurred for this proces.<br>
/// 1 - The value of $STORAGE went negative.<br>
/// 2 - The value of $STORAGE went below its emergency margin of -1048576 (-1MB).<br>
/// 3 - The OS refused to give any more memory resources to the process.<br>
/// 4 - Attempt to set $ZSTORAGE to a value that would cause $STORAGE to become negative.<br>
/// 
ClassMethod StoreErrorReason() As %Integer
{
}

/// Kill all process private globals for the calling process.<br>
ClassMethod KillAllPrivateGlobals() As %Status
{
 s $zt="Error"
 d $zu(21,2)
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// <b>Undefined(switch)</b> is a class method used to specify the default
/// behavior for the current process when handling undefined
/// variables. Setting the Undefined switch changes this behavior for
/// local variables, process-private globals, and global variables system-wide;
/// it has no effect on special variables. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a numeric code that specifies how ObjectScript
/// treats an undefined variable. It takes on the following values:<br>
/// 0 -- Issues the &lt;UNDEFINED&gt; error for any undefined variable.
/// (0 is the usual default)<br> 
/// 1 -- Returns a null string for a reference to an undefined variable with subscripts,
/// and issues the &lt;UNDEFINED&gt; error for undefined variables without subscripts.<br>
/// 2 -- Returns a null string (instead of issuing an &lt;UNDEFINED&gt; error) for any
/// undefined variable.
/// <p>
/// Invoking Undefined() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the Undefined method.
/// 
ClassMethod Undefined(switch As %Integer) As %Integer
{
	quit:'$d(switch) $zu(18)
	quit $zu(18,switch)
}

/// The <b>NullSubscripts(switch)</b> class method allows setting and referencing
/// globals with null subscripts within the current process.
///  <p>
/// If null subscripted globals are not enabled (switch=0), attempting to set a null
/// subscripted variable, such as SET ^x("")=99, or to reference a null subscript,
/// such as WRITE ^x(""), results in a &lt;SUBSCRIPT&gt; error.
/// <p>
/// If null subscripted globals are enabled (switch=1), you can set a null subscripted
/// variable, such as SET ^x("")=99, just like any other variable. Referencing an
/// undefined null subscripted variable results in a &lt;UNDEFINED&gt; error.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the null subscript mode setting
/// for the current process:<br>
/// 0 -- Disables setting/referencing null subscripted globals.
/// (0 is the usual default)<br>
/// 1 -- Enables setting/referencing null subscripted globals. 
/// <p>
/// Invoking NullSubscripts() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// NullSubscripts method.
/// 
ClassMethod NullSubscripts(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,1)
	quit $zu(68,1,switch)
}

/// <b>OpenMode(switch)</b> is a class method that specifies the open mode for sequential
/// files opened by the current process. When the current process issues an OPEN
/// command for a sequential file, that file is opened either in read-only
/// mode (R) or read/write mode (RW). Calling OpenMode(switch) specifies this open
/// mode for the current process, overriding the system-wide default setting. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the default mode for
/// sequential files on OPEN for the current process:<br>
/// 0 -- read-only (R) is the OPEN default. (0 is the usual default)<br>
/// 1 -- read and write (RW) is the OPEN default. 
/// <p>
/// Invoking OpenMode() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// OpenMode method.
/// 
ClassMethod OpenMode(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,2)
	quit $zu(68,2,switch)
}

/// The <b>FileMode(switch)</b> class method specifies if a sequential file is created
/// automatically in response to an OPEN command that specifies a file that does not
/// already exist. If you attempt to open a file in "W" or "RW" mode, but that file
/// does not yet exist, the default behavior is platform-dependent. On Windows and Unix
/// systems, the default is for the process to hang until the file is actually
/// created, or until the process is resolved by a timeout expiration or by calling
/// the RESJOB utility. On OpenVMS systems, the default is to create a new sequential
/// file.
/// <p> 
/// Calling FileMode(switch) can override the default. Calling FileMode(1)
/// causes the system to create a sequential file automatically
/// when you issue the OPEN command in "W" or "RW" mode for a file that does not
/// already exist; calling FileMode(0) prevents the OPEN command from automatically
/// creating a sequential file when the file does not already exist.
/// This FileMode setting governs all sequential file opens in the
/// current process. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not a file is created
/// when the process attempts to open a nonexistent file for writing:<br>
/// 0 -- automatic new file creation is disabled.
/// (0 is the usual default for Unix and Windows systems)<br>
/// 1 -- automatic new file creation is enabled.
/// (1 is the usual default for VMS systems)
/// <p>
/// Invoking FileMode() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// FileMode method.
/// 
ClassMethod FileMode(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,3)
	quit $zu(68,3,switch)
}

/// The <b>BreakMode(switch)</b> class method enables or disables the processing
/// of argumentless <b>BREAK</b> commands by the current process.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the default behavior of
/// argumentless <b>BREAK</b>:<br>
/// 0 -- Treats an argumentless <b>BREAK</b> as a no-op.<br>
/// 1 -- Executes <b>BREAK</b> on an argumentless <b>BREAK</b>.  (1 is the usual
/// default) 
/// <p>
/// Invoking BreakMode() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// BreakMode method.
/// 
ClassMethod BreakMode(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,5)
	quit $zu(68,5,switch)
}

/// The RefInKind(switch) class method specifies whether $QUERY and $NAME
/// return an extended global reference when the first argument of $QUERY or $NAME
/// contains an extended global reference. A switch value of 0 returns the extended
/// global reference. A switch value of 1 strips the extended global reference
/// before returning the global. Invoking the ZWRITE command returns the extended
/// global reference regardless of the RefInKind setting.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether $QUERY or $NAME return an
/// extended global reference:<br>
/// 0 -- Retains the extended global reference; this enables reference-in-kind.
/// (0 is the usual default)<br>
/// 1 -- Strips the extended global reference and returns just
/// the global; this disables reference-in-kind.
/// <p>
/// The 1 value for the switch is provided for backward compatibility.
/// <p>
/// Invoking RefInKind() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// RefInKind method.
/// 
ClassMethod RefInKind(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,7)
	quit $zu(68,7,switch)
}

/// The <b>LineRecall(switch)</b> class method enables or disables read line recall
/// for terminal devices opened by the current process. Read line recall is only
/// used by terminal devices. The current LineRecall setting is only applied when
/// a terminal device is explicitly opened using the OPEN command.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that controls read line recall mode:<br>
/// 0 -- Disables read line recall mode.<br>
/// 1 -- Enables read line recall mode.  (1 is the usual default)
/// <p>
/// Invoking LineRecall() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the LineRecall method.
/// 
ClassMethod LineRecall(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,11)
	quit $zu(68,11,switch)
}

/// The <b>DisconnectErr(switch)</b> class method determines how the system responds to
/// the disconnection of the principal I/O device being accessed from the current
/// process. When set to 1, the process receives a &lt;DSCON&gt; error when a disconnect
/// is detected during an ObjectScript READ or WRITE command to the device. This
/// is known as "error on disconnect." When set to 0, the process exits without
/// reporting an error to the application when a disconnect is detected.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether the system detects I/O
/// device disconnection:<br>
/// 0 -- Disables disconnection detection.  (0 is the usual default)<br>
/// 1 -- Enables disconnection detection. 
/// <p>
/// Invoking DisconnectErr() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- The switch state prior to calling the DisconnectErr method.
/// 
ClassMethod DisconnectErr(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,15)
	quit $zu(68,15,switch)
}

/// The <b>SynchCommit(switch)</b> class method sets the synchronous transaction
/// commit mode for the current process. This enables or disables synchronizing
/// TCOMMIT with the corresponding journal write operation. Every TCOMMIT command
/// requests a flush of the journal data involved in that transaction to disk.
/// When SynchCommit is enabled (set to 1) a TCOMMIT does not complete until the
/// journal data write operation completes. When set to 0, TCOMMIT does not wait
/// for the write operation to complete.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the default mode for
/// synchronous transaction commit:<br>
/// 0 -- TCOMMIT completion does not wait for journal file write completion.
/// (0 is the usual default)<br>
/// 1 -- TCOMMIT completion waits for the journal file write operation to complete.
/// <p>
/// Invoking SynchCommit() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the SynchCommit method.
/// 
ClassMethod SynchCommit(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,21)
	quit $zu(68,21,switch)
}

/// The <b>DX(switch)</b> class method specifies how the current process handles escape
/// sequences when updating the $X special variable. When reading a string containing
/// an escape sequence, various InterSystems products handle updating the $X special
/// variable differently. You can control the way the system updates $X when writing
/// a string containing an escape sequence. Default behaviors for various implementations
/// are:
/// <p>
/// Unix parses the ANSI-standard escape sequence and counts the rest of the
/// non-escape characters in the string against $X.
/// <p>
/// Open M [DSM] counts all characters in a string, including the escape character,
/// against $X.
/// <p>
/// MSM counts all characters in the string, except for the escape character,
/// against $X. 
/// <p>
/// Alpha OpenVMS does not count any more characters in the string against $X after
/// encountering an escape character ($CHAR(27)).
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- an integer that specifies the method of updating $X for an
/// individual process:<br>
/// 0 -- Specifies Unix and Windows default behavior.<br>
/// 1 -- Specifies Open M [DSM] default behavior.<br>
/// 2 -- Specifies MSM default behavior.<br>
/// 3 -- Specifies Alpha/VAX default behavior.
/// <p>
/// Invoking DX() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the DX method.
/// 
ClassMethod DX(switch As %Integer) As %Integer
{
	quit:'$d(switch) $zu(68,22)
	quit $zu(68,22,switch)
}

/// The <b>BatchFlag(switch)</b> class function specifies either batch or interactive status
/// for the current process. This allows you to balance resources more effectively. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that controls the status of the issuing process:<br>
/// 0 -- Clears batch status and gives the process interactive status.
/// (0 is the usual default)<br>
/// 1 -- Gives the process batch status.
/// <p>
/// Invoking BatchFlag() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the BatchFlag method.
/// 
ClassMethod BatchFlag(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,25)
	quit $zu(68,25,switch)
}

/// The <b>GlobalKillDisabled(switch)</b> class function specifies whether a
/// Kill of a root-level global node is disabled as a command to an interactive
/// terminal session. This switch does not affect the Kill command applied
/// interactively to a subscripted global nor does it affect any Kill used
/// as a command within a routine.
/// <p>
/// Setting the <b>GlobalKillDisabled()</b> switch provides some minimal protection
/// against certain typing errors involving the KILL command while directly
/// entering interactive commands to a InterSystems IRIS terminal session.  It does not
/// prevent a user from entering the XECUTE "KILL ^a" command to kill all of
/// global variable ^a.  The switch also has no effect on commands typed
/// interactively to other command shells, such as the MV (MultiValue) shell.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a Boolean value that specifies whether the current
/// process allows a Kill of a root-level global node as an interactive
/// terminal command:<br>
/// 0 -- Root-level global node kills are allowed.  (0 is the default)<br>
/// 1 -- Root-level global node kills are not allowed from the command line, but
/// are allowed from routines.
/// <p>
/// Invoking GlobalKillDisabled() without specifying the switch parameter returns
/// the current switch setting.
/// <p>
/// <b>Return Value</b> -- the switch state prior to calling the GlobalKillDisabled
/// method.
/// 
ClassMethod GlobalKillDisabled(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) ''$zu(68,28)
	quit ''$zu(68,28,$s(switch:2,1:0))
}

/// The <b>PopError(switch)</b> class function specifies whether a process uses
/// InterSystems IRIS-style error handling (the default) or legacy (DSM) error handling.
/// <p>
/// When a InterSystems IRIS-style error handler is invoked, that error handler remains on the
/// stack of established error handlers. Therefore, if an error occurs while the
/// InterSystems IRIS-style error handler is executing, that error handler attempts to invoke itself,
/// receives the same error again and enters an infinite loop, unless that error handler
/// explicitly sets the $ZTRAP special variable to a new value.
/// <p>
/// When an error handler is invoked in DSM, the DSM-style error handler is unwound
/// from the stack. Therefore, if an error occurs while the DSM-style error handler
/// is executing, that error is handled by the previous error handler on the stack.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not a process uses
/// InterSystems IRIS-style error handling:<br>
/// 0 -- specifies InterSystems IRIS-style behavior.  (0 is the usual default)<br>
/// 1 -- specifies DSM-style behavior.
/// <p>
/// Invoking PopError() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the PopError method.
/// 
ClassMethod PopError(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,30)
	quit $zu(68,30,switch)
}

/// The <b>ZDateNull</b> class method performs two process-specific operations:
/// <p>
/// It specifies how the $ZDATE function behaves when it receives invalid input.
/// <p>
/// It specifies the default range of valid dates for $ZDATE. (This provides
/// backward-compatibility with ISM.)
/// <p>
/// <b>Setting the Behavior for Invalid Dates</b>
/// <p>
/// An invalid date is either not a positive integer, or is not a value within the
/// range of valid dates.
/// <p>
/// ZDateNull(0) causes $ZDATE to issue the error message &lt;ILLEGAL VALUE&gt; or
/// &lt;VALUE OUT OF RANGE&gt; if you submit an invalid date. The behavior can be
/// overridden by supplying an erropt parameter to the $ZDATE call.
/// <p>
/// ZDateNull(1) causes $ZDATE to return the null string if you submit an invalid
/// date. This behavior is set for any $ZDATE function call, regardless of the
/// number of parameters.
/// <p>
/// <b>Setting the Range of Valid Dates</b>
/// <p>
/// ZDateNull(0) sets the default range of valid dates to be the default. This
/// range is from 0 through 2980013, inclusive, which corresponds to dates from
/// 12/31/1840 through 12/31/9999. This range can be restricted by setting the
/// $ZDATE mindate and maxdate parameters.
/// <p>
/// ZDateNull(1) sets the default range of valid dates for ISM compatibility. This
/// range is from 1 through 94232, inclusive, which corresponds to dates from
/// 01/01/1841 through 12/30/2098. This date range is set for any $ZDATE function
/// call which has three or fewer parameters. If a $ZDATE function call has more
/// than three parameters, the valid date range is taken either from the $ZDATE
/// mindate and maxdate parameters (if specified) or from the date range established
/// for the current locale.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> a boolean value that specifies $ZDATE behavior:<br>
/// 0 -- specifies InterSystems IRIS-style behavior. (0 is the usual default)<br>
/// 1 -- specifies ISM-style behavior.
/// <p>
/// Invoking ZDateNull() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the ZDateNull method.
/// 
ClassMethod ZDateNull(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,32)
	quit $zu(68,32,switch)
}

/// The <b>AsynchError(switch)</b> class method specifies whether asynchronous errors
/// can interrupt the current process.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the process
/// behavior in response to asynchronous errors:<br>
/// 0 -- disables the reception of asynchronous errors.<br>
/// 1 -- enables the reception of asynchronous errors. (1 is the usual default)
/// <p>
/// Invoking AsynchError() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the AsynchError method.
/// 
ClassMethod AsynchError(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,34)
	quit $zu(68,34,switch)
}

/// The <b>SetZEOF(switch)</b> class method specifies end-of-file flagging format.
/// This function is provided to support interoperability, and the
/// porting of MSM routines that use the MSM $ZC function to check for end of file
/// on sequential file reads. This MSM function should not be confused with the
/// ObjectScript $ZC function (which is an abbreviation for $ZCHILD).
/// <p>
/// A switch value of 1 eliminates the &lt;ENDOFFILE&gt; error for sequential files for
/// the current process. Instead, when the end of a file is reached, the READ
/// command returns a null string, the $ZPOS special variable is set
/// to "" (the null string), and the $ZEOF special variable is set to -1. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies end-of-file handling for the current
/// process:<br>
/// 0 -- default format.<br>
/// 1 -- end-of-file flagging format.
/// <p>
/// Invoking SetZEOF() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the SetZEOF method.
/// 
ClassMethod SetZEOF(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,40)
	quit $zu(68,40,switch)
}

/// The <b>NodeNameInPid(switch)</b> class method specifies the format that the $JOB
/// special variable returns for the current process.
/// <p>
/// This function provides for a unique value for $JOB on networked systems. This
/// is useful when using $JOB to index globals accessed by more than one networked
/// system. In the form NodeNameInPid(1), the $JOB special variable returns a string
/// of the format processid:nodename.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the string format that $JOB returns:<br>
/// 0 -- specifies the standard $JOB format. (0 is the usual default)<br>
/// 1 -- specifies the format as processid:nodename. 
/// <p>
/// Invoking NodeNameInPid() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the NodeNameInPid method.
/// 
ClassMethod NodeNameInPid(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,42)
	quit $zu(68,42,switch)
}

/// The <b>OldZU5(switch)</b> class method specifies whether or not issuing the
/// $namespace function with the current namespace clears global vectors for the
/// current process.
/// <p>
/// OldZU5(1) provides compatibility with $namespace behavior before Cache version 3.1;
/// this call enables the clearing of global vectors for the current process when
/// $namespace is issued with the current namespace. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not there is global vector
/// clearing:<br>
/// 0 -- (default behavior) disables global vector clearing. (0 is the usual default)<br>
/// 1 -- (legacy behavior) clears global vectors.  
/// <p>
/// Invoking OldZU5() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the OldZU5 method.
/// 
ClassMethod OldZU5(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,43)
	quit $zu(68,43,switch)
}

/// The <b>TruncateOverflow(switch)</b> class method specifies whether or not the
/// current process truncates very large numbers. The default behavior is not to
/// truncate numbers.
/// <p>
/// Normally, when the system encounters a numeric string larger than
/// 9223372036854775807E127
/// it converts the number to an IEEE double-precision number. This conversion only
/// occurs during string-to-number conversions. A &lt;MAXNUMBER&gt; error can still occur
/// during arithmetic operations. This conversion extends the numeric range available
/// to literal numbers, but reduces the numeric precision by roughly 3 decimal digits.
/// When the system encounters a number too large to be represented by an IEEE
/// double-precision number, it either issues a &lt;MAXNUMBER&gt; error or returns INF,
/// depending on the setting of ##class(%SYSTEM.Process).IEEEError().
/// <p>
/// When the TruncateOverflow switch is set, this automatic conversion of large numeric
/// strings to the $DOUBLE type does not occur nor does an error occur.  Instead, the
/// largest positive decimal value, 9223372036854775807E127, or the largest negative
/// decimal, -9223372036854775808E127, as appropriate, is returned.
///  In addition, setting the
/// TruncateOverflow switch will cause an overflow that occurs during decimal arithmetic
/// operations to return these largest values rather than issuing a &lt;MAXNUMBER&gt; error.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether number truncation occurs:<br>
/// 0 -- preserves large numbers and performs IEEE double-precision conversion on
/// these numbers when necessary. (0 is the usual default)<br>
/// 1 -- truncates large numbers during the string-to-number conversion and suppresses
/// IEEE conversion and &lt;MAXNUMBER&gt; errors. 
/// <p>
/// Invoking TruncateOverflow() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the TruncateOverflow method.
/// 
ClassMethod TruncateOverflow(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,45)
	quit $zu(68,45,switch)
}

/// The <b>SwitchOSdir(switch)</b> class method specifies whether changing the
/// namespace also changes the default directory. By default, changing
/// to a new namespace causes InterSystems IRIS to change the directory at the operating
/// system level to the default directory for that namespace. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the default behavior when changing
/// namespaces:<br>
/// 0 -- Changing the namespace automatically changes the default
/// directory to the directory for that namespace. (0 is the usual default)<br>
/// 1 -- Changing the namespace does not change the default directory.
/// <p>
/// Invoking SwitchOSdir() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the SwitchOSdir
/// method.
/// 
ClassMethod SwitchOSdir(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,51)
	quit $zu(68,51,switch)
}

/// The <b>AsyncDisconnectErr(switch)</b> class method specifies the
/// asynchronous disconnect error handling for the current process.
/// AsyncDisconnectErr is only applicable to Telnet connections
/// on Windows. It has no effect on any other device type or
/// operating system.
/// <p>
/// For the asynchronous disconnect error switch to be operational, the
/// DisconnectErr() class method must set disconnect error switch to 1 for
/// the current process. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the default mode for
/// asynchronous disconnect errors:<br>
/// 0 -- the process receives a &lt;DSCON&gt; error at the next READ or
/// WRITE command.<br>
/// 1 -- The process receives an asynchronous &lt;DSCON&gt; error immediately
/// when a disconnect occurs on the device. This error occurs at the
/// next command executed. HANG commands will be interrupted.
/// <p>
/// Invoking AsyncDisconnectErr() without specifying the switch parameter
/// returns the current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// AsyncDisconnectErr method.
/// 
ClassMethod AsyncDisconnectErr(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,60)
	quit $zu(68,60,switch)
}

/// The <b>ScientificNotation(switch)</b> class method specifies
/// the evaluation of the lowercase letter "e" as a scientific notation
/// exponent symbol for the current process. ScientificNotation has
/// no effect on the evaluation of uppercase "E" as an exponent symbol.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not a
/// process should treat lowercase "e" as a scientific notation
/// base-10 exponent symbol:<br>
/// 0 -- do not evaluate "e" as an exponent symbol.<br>
/// 1 -- evaluate "e" as an exponent symbol. (1 is the usual default)
/// <p>
/// Invoking ScientificNotation() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// ScientificNotation method.
/// 
ClassMethod ScientificNotation(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,63)
	quit $zu(68,63,switch)
}

/// The <b>TelnetNUL(switch)</b> class method specifies the issuance
/// of a NUL character (ASCII 0) following a CR character (ASCII 13)
/// at end-of-line during Telnet transmission. On output, a Telnet
/// network virtual terminal (NVT) performs the following default
/// end-of-line behavior: either issues a CR (carriage return character)
/// followed by a LF (linefeed character), or issues a CR (carriage
/// return character) followed by a NUL character (if no LF is issued).
/// TelnetNUL(switch) affects the issuance of the NUL character in this
/// second case.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not
/// the system should suppress NUL following a CR at end-of-line:<br>
/// 0 -- do not suppress NUL. (0 is the usual default)<br>
/// 1 -- suppress NUL.
/// <p>
/// Invoking TelnetNUL() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// TelnetNUL method.
/// 
ClassMethod TelnetNUL(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,66)
	quit $zu(68,66,switch)
}

/// The <b>ExceptionLog(switch)</b> class method specifies the display
/// of a Windows message box. When enabled, this box displays stack
/// and register usage information when a cache.exe process encounters
/// an exception. Because processing cannot proceed until the user
/// responds to this message box, ExceptionLog(switch) provides the
/// option to suppress the display of this message box to facilitate
/// unattended system operation, such as scripted shutdown and restart.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not the
/// system should display or suppress the Windows stack and register
/// usage box for the current process when it encounters an
/// exception:<br>
/// 0 -- suppress display of the message box. (0 is the usual default)<br>
/// 1 -- enable display of the message box.
/// <p>
/// Invoking ExceptionLog() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// ExceptionLog method.
/// 
ClassMethod ExceptionLog(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,67)
	quit $zu(68,67,switch)
}

/// The <b>IEEEError(switch)</b> class method specifies the issuing of
/// INF, -INF, and NAN when a $DOUBLE numeric operation encounters an
/// overflow, divide-by-zero or invalid-operation exception.
/// It does not control the issuing of INF, -INF, and NAN in all cases.
/// Regardless of the ExceptionLog() setting, $DOUBLE operations return
/// INF, -INF, or NAN when you supply
/// one of these values as an operand and an overflow,
/// divide-by-zero or invalid-operation exception does not occur.
/// Operations that can generate IEEE Exceptions when encountering
/// $DOUBLE values include conversions from a numeric string, arithmetic
/// operations, exponentiation, and logarithmic and trigonometric
/// functions. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies the $DOUBLE exception
/// mode setting for the current process:<br>
/// 0 -- $DOUBLE operations return INF, -INF, or NAN when encountering
/// an IEEE exception.<br>
/// 1 -- $DOUBLE operations generate &lt;MAXNUMBER&gt;, &lt;ILLEGAL VALUE&gt;,
/// 
/// and &lt;DIVIDE&gt; errors when encountering an IEEE exception.  (1 is the
/// usual default)
/// <p>
/// Invoking IEEEError() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// IEEEError method.
/// 
ClassMethod IEEEError(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,70)
	quit $zu(68,70,switch)
}

/// The <b>IPv6Format(switch)</b> class method specifies the types of
/// IP address formats supported by the current process.  When IPv6 is
/// enabled, the system accepts an IP address on the OPEN command in
/// either IPv6 or IPv4 format, or as a host name, with or without
/// domain qualifiers. The system first checks for an IPv4 format
/// address, then for an IPv6 format address; it accepts the first
/// successful connection.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies IP address format:<br>
/// 0 -- IPv6 format disabled--IPv4 only.  (0 is the usual default)<br>
/// 1 -- IPv6 format enabled--both IPv4 and IPv6 supported.
/// <p>
/// Invoking IPv6Format() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// IPv6Format method.
/// 
ClassMethod IPv6Format(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,71)
	quit $zu(68,71,switch)
}

/// The <b>MVUndefined(switch)</b> class method specifies MVBasic
/// behavior for the current process when it encounters a reference
/// to an undefined variable. By default, if the current MVBasic
/// routine references an undefined variable, the system generates
/// an &lt;UNDEFINED&gt; error. You can change this default behavior to
/// have the system substitute an empty string for an undefined
/// variable, without signaling an error. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether or not the
/// system should issue an error when the current MVBasic routine
/// references an undefined variable:<br>
/// 0 -- issue an &lt;UNDEFINED&gt; error for an undefined variable. (0 is
/// the usual default)<br>
/// 1 -- substitute the empty string for an undefined variable.
/// <p>
/// Invoking MVUndefined() without specifying the switch parameter returns the
/// current switch setting.
/// <p>
/// <b>Return value</b> -- the switch state prior to calling the
/// MVUndefined method.
/// 
ClassMethod MVUndefined(switch As %Boolean) As %Boolean
{
	quit:'$d(switch) $zu(68,72)
	quit $zu(68,72,switch)
}

/// The <b>PrivateGlobalLocation()</b> class method returns the location of the
/// process-private globals database in the form sfn^dir. If no process-private
/// globals are defined, this defaults to 15999^0. 
/// 
ClassMethod PrivateGlobalLocation() As %String
{
	quit $zu(21)
}

/// The <b>KillPrivateGlobals()</b> class method deletes all process-private globals
/// defined for the current process. It returns 1 upon successful completion,
/// 0 upon error. KillPrivateGlobals returns 1 even if no process-private globals
/// were defined.
/// <p>
/// KillPrivateGlobals() is a legacy function that should no longer be
/// used by customers.  The function KillAllPrivateGlobals() is the preferred
/// way to do this and KillPrivateGlobals() has been redfined to be identical
/// to KillAllPrivateGlobals().
/// 
ClassMethod KillPrivateGlobals() As %Status [ Internal ]
{
 s $zt="Error"
 d $zu(21,2)
 q $$$OK
Error s $zt=""
 q $$$ERROR($$$ObjectScriptError,$ze)
}

/// The <b>FixedDate(date)</b> class method sets the date internally stored
/// in the $HOROLOG special variable to a specified fixed value for the current
/// process. Calling FixedDate(0) turns off this function, restoring $HOROLOG to
/// the current local date.
/// <p>
/// Using this function to set a fixed value for the date causes all subsequent
/// calls to $HOROLOG from that process to return that fixed value as the date.
/// A date set using FixedDate(date) is a fixed date; it does not increment at
/// midnight.
/// <p>
/// FixedDate(date) has no effect on the time portion of $HOROLOG, which continues
/// to represent the current time.
/// <p>
/// To restore $HOROLOG to the current date, issue FixedDate(0). This call reverts
/// $HOROLOG to the current date. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>date</b> -- A positive integer that represents a date in $HOROLOG format.
/// An integer that falls between 1 (January 1, 1841) and 2980013
/// (December 31, 9999) inclusive fixes that date.  A date parameter of 0
/// turns off this function.
/// <p>
/// Invoking FixedDate() without specifying the date parameter returns the
/// current FixedDate value with no effect on $HOROLOG.  FixedDate() returns
/// zero if $HOROLOG is not set to a fixed value
/// <p>
/// <b>Return value</b> -- the FixedDate value prior to calling the
/// FixedDate method.
/// 
ClassMethod FixedDate(date As %Integer) As %Integer
{
	quit:'$d(date) $zu(71)
	quit $zu(71,date)
}

/// The <b>Broadcast(pid,message,timeout,noxy)</b> class method sends a message
/// to the principal device of the process you indicate.
/// <p>
/// Broadcast passes the message to the target process. The target process then
/// writes the message to its principal output device. The target process must
/// be running the InterSystems IRIS kernel. If you send a message to your own process, you
/// do not see the message on the screen of your principal device.
/// <p>
/// Broadcast does not add any carriage controls to the message it sends. To
/// include any carriage control (carriage returns or line feeds), you must
/// include them in the message, using $CHAR(13) and $CHAR(10).
/// <p>
/// %SYSTEM.Process.Broadcast complements %Library.Device.Broadcast.
/// %Library.Device.Broadcast sends a message to a specified device
/// while %SYSTEM.Process.Broadcast sends a message to the principal device of a
/// specified process. Be sure that you use the right function for the right
/// purpose.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>pid</b> -- The Process ID of the target process. The System Management
/// Portal provides a Processes option, which list the pids of all running
/// processes. Select [Home] > [Processes].<br>
/// <b>message</b> -- The message to send, specified as a string.<br>
/// <b>timeout</b> -- Optional -- An integer specifying the number of seconds
/// to wait before timeout. If omitted, no timeout occurs.<br>
/// <b>noxy</b> -- Optional -- If 0, $X and $Y are updated in the receiving
/// process to indicate the location of the end of the broadcast message.
/// If 1, $X and $Y are not updated. The default is 0. This parameter does
/// not apply to OpenVMS systems, which do not update $X and $Y following
/// a broadcast message. 
/// <p>
/// <b>Return value</b> -- 1 if pid belongs to an InterSystems IRIS process and the message was
/// sent to that process; 0 otherwise.
/// 
ClassMethod Broadcast(pid As %Integer, message As %String, timeout As %Integer, noxy As %Boolean) As %Boolean
{
	set:'$d(timeout) timeout=-1
	set:'$d(noxy) noxy=0
	quit $ZU(94,pid,message,timeout,noxy)
}

/// The <b>CurrentDirectory(dir)</b> class method sets your current working
/// directory for sequential file output to the directory named by the parameter. If the
/// directory cannot be set as the current working directory, CurrentDirectory
/// issues a &lt;DIRECTORY&gt; error, and ^SYSLOG will show the cause of the
/// error. This directory should not be confused with the default directory
/// for globals in the current namespace. 
/// <p>
/// Note: On Windows systems, CurrentDirectory(dir) sets as the current
/// directory a directory name entirely in lowercase letters, regardless of the
/// case of dir. Because Windows and ObjectScript are not case-sensitive,
/// this is usually irrelevant. However, this may affect some Windows
/// applications (such as Java) which are case-sensitive. 
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>dir</b> -- Name of directory to set as working directory for sequential file output.
/// <p>
/// Invoking CurrentDirectory() without specifying the dir parameter returns the
/// current working directory setting.
/// <p>
/// <b>Return value</b> -- the working directory prior to calling the
/// CurrentDirectory method.
/// 
ClassMethod CurrentDirectory(dir As %String) As %String
{
	quit:'$d(dir) $zu(168)
	quit $zu(168,dir)
}

/// The <b>TerminalPrompt(p1,p2,...)</b> class method specifies what information
/// should appear in the programmer-mode prompt for InterSystems IRIS Terminal. 
/// <p>
/// Issuing TerminalPrompt() (with no arguments) does not change the terminal
/// prompt but it does return the current state of the
/// prompt setting as a comma-separated list of integer codes.
/// <p>
/// Issuing TerminalPrompt(0) clears the setting, so that no prompt information is displayed.
/// <p>
/// Issuing TerminalPrompt(p1,...), where none of the parameters are 0, sets the prompt to
/// include the information specified by the parameter codes.  The order of the
/// parameter codes is the order the information appears in the prompt.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>p1</b> -- Optional -- Code for the 1st field of the terminal prompt.<br>
/// <b>p2</b> -- Optional -- Code for the 2nd field of the terminal prompt.<br>
/// ...<br>
/// <b>p8</b> -- Optional -- Code for the 8th field of the terminal prompt.
/// <p>
/// <b>Prompt Codes</b>
/// <p>
/// 0 -- Reset the prompt.<br>
/// 1 -- Host name, also known as the current system name. The name assigned to your
/// computer. For example, LABLAPTOP&gt;. This is the same for all of your terminal
/// processes.<br>
/// 2 -- Namespace name. For example, %SYS&gt;. The current namespace name is contained
/// in the $NAMESPACE special variable. It can be an explicit namespace name or an
/// implied namespace name.<br>
/// 3 -- Config name. The name of your system installation. For example, DEVELOPMENT&gt;.
/// This is the same for all of your terminal processes.<br>
/// 4 -- Current time, expressed as local time in 24-hour format with whole seconds.
/// For example, 15:59:36&gt;. This is the static time value for when the prompt was
/// returned. This value changes for each prompt.<br>
/// 5 -- pid. The Process ID for your terminal. For example, 2336&gt;. This is different
/// for each terminal process. This value can also be returned from the $JOB special
/// variable.<br>
/// 6 -- Username. For example, fred&gr;. This is the same for all of your terminal
/// processes.<br>
/// 7 -- Elapsed time executing the last command, in seconds.milliseconds. For example,
/// .000495&gt;. Leading and trailing zeros are suppressed. This changes for each prompt.<br>
/// 8 -- Transaction Level. For example, TL1&gt;.
/// <p>
/// Invoking TerminalPrompt() without specifying any parameter codes returns the
/// current prompt codes.
/// <p>
/// <b>Return value</b> -- the prompt codes prior to calling the
/// TerminalPrompt method.  This return value is a list of comma separated integers.
/// It consists of the single integer 0 if no prompt codes are set.
/// 
ClassMethod TerminalPrompt(p1 As %Integer, p2 As %Integer, p3 As %Integer, p4 As %Integer, p5 As %Integer, p6 As %Integer, p7 As %Integer, p8 As %Integer) As %String
{
	quit:'$d(p1) $zu(186)
	quit:'$d(p2) $zu(186,p1)
	quit:'$d(p3) $zu(186,p1,p2)
	quit:'$d(p4) $zu(186,p1,p2,p3)
	quit:'$d(p5) $zu(186,p1,p2,p3,p4)
	quit:'$d(p6) $zu(186,p1,p2,p3,p4,p5)
	quit:'$d(p7) $zu(186,p1,p2,p3,p4,p5,p6)
	quit:'$d(p8) $zu(186,p1,p2,p3,p4,p5,p6,p7)
	quit $zu(186,p1,p2,p3,p4,p5,p6,p7,p8)
}

/// The <b>ErrorLine()</b> class method returns source file and line of code for last
/// ObjectScript error.  The source file and line number usually refer to the
/// kernel code that was written by InterSystems.  This information is useful when
/// requesting InterSystems support for help recovering from an error.  
/// <p>
/// The name of the last ObjectScript error that occurred is contained in the
/// $ZERROR special variable.
/// 
ClassMethod ErrorLine() As %String
{
	quit $ZUTIL(56,2)
}

/// The <b>OSError()</b> class method returns the operating system error code for a
/// sequential file error.
/// <p>
/// When a sequential file I/O operation fails, the operating system returns an error
/// code to InterSystems IRIS. InterSystems IRIS, in turn, issues its own corresponding error code. OSError()
/// returns the operating system error code number (in angle brackets) followed by the
/// operating system error message. These operating system errors are specific to the
/// operating system being used. 
ClassMethod OSError() As %String
{
	quit $ZUTIL(56,6)
}

/// The <b>UserRoutinePath()</b> class method specifies the namespace(s) that contains
/// the routine dataset.
/// <p>
/// To change the source from which you want to draw routines, use UserRoutinePath to
/// specify the namespace that contains the routine dataset in which the routines you
/// want to use are located.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>primary</b> -- Optional -- Specify the primary namespace that contains the
/// routine dataset. If used alone, this is the namespace that will be searched
/// for all routines. If used in conjunction with second and third, primary will be
/// the first namespace searched for routines.<br>
/// <b>second</b> -- Optional -- Specify the second namespace to search for
/// routines. If InterSystems IRIS does not find a routine in primary, it will search for it
/// in second.<br>
/// <b>third</b> -- Optional -- Specify the third namespace to search for
/// routines.  If InterSystems IRIS does not find a routine in primary or second, it will search
/// for it in third.
/// <p>
/// If there are no parameters passed to UserRoutinePath() then the method returns
/// the current primary namespace as a string and the User Routine Path is unchanged.
/// If there are parameters then the entire User Routine Path is replaced with the
/// newly specified path.
/// <p>
/// Calling UserRoutinePath("") with a null string as a parameter resets the current
/// namespace for routine access to the default namespace.
/// <p>
/// The namespace strings you specify can be either an explicit namespace or an
/// implied namespace (a directory path or OpenVMS file specification preceded by two
/// caret characters (^^)).
/// <p>
/// To understand UserRoutinePath, you need to keep the following in mind. When a
/// process starts, it uses routines in the current namespace. After you issue
/// $system.Process.UserRoutinePath(new), all subsequent routines come from new.
/// <p>
/// If you issue $system.Process.UserRoutinePath(new,second,third), all subsequent
/// routines located in namespace new will come from new. If the system does not find a routine
/// in new, the system looks for the routine in namespace second. If the system does not find
/// the routine in second, the system looks for the routine in namespace third.
/// <p>
/// Note: Using routines in second is VERY slow! You should use second as an aid to
/// program development, not as a normal running procedure.
/// <p>
/// To use UserRoutinePath as a development aid, make new your development area and use
/// second as a storage area of routines that work.  When you issue ZSAVE, the routine
/// you save always goes into new, even if you loaded it from second. As you edit and
/// file routines, they appear in new without affecting the library in second, and
/// subsequent calls for the routines get the new version from new.
/// <p>
/// The method does not affect globals; the original namespace still defines access
/// privileges for globals. Your process uses globals in the current namespace unless
/// you make explicit or implicit references to globals in other namespaces. In other
/// words, the routines come from primary (or from second or third), while the
/// globals come from the process's current namespace.
/// <p>
/// This method does not affect system routines whose names begin with a per cent (%).
/// For % routines see the SysRoutinePath method.
/// <p>
/// <b>Return value</b> -- the primary namespace for user routine access
/// that was set before you called UserRoutinePath.
/// 
ClassMethod UserRoutinePath(primary As %String, second As %String, third As %String) As %String
{
	quit:'$d(primary) $zu(20)
	quit:'$d(second) $zu(20,primary)
	quit:'$d(third) $zu(20,primary,second)
	quit $zu(20,primary,second,third)
}

/// The <b>SysRoutinePath()</b> class method specifies the namespace(s) that contains
/// the routine dataset for system routines that begin with per cent (%).
/// <p>
/// To change the source from which you want to draw system routines, use SysRoutinePath to
/// specify the namespace that contains the routine dataset in which the system routines
/// you want to use are located.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>primary</b> -- Optional -- Specify the primary namespace that contains the system
/// routine dataset. If used alone, this is the namespace that will be searched
/// for all system routines. If used in conjunction with second and third, primary will be
/// the first namespace searched for system routines.<br>
/// <b>second</b> -- Optional -- Specify the second namespace to search for system
/// routines. If the system does not find a system routine in primary, it will search for it
/// in second.<br>
/// <b>third</b> -- Optional -- Specify the third namespace to search for system
/// routines.  If the system does not find a system routine in primary or second,
/// it will search for it in third.
/// <p>
/// If there are no parameters passed to SysRoutinePath() then the method returns
/// the current primary namespace as a string and the System Routine Path is unchanged.
/// If there are parameters then the entire System Routine Path is replaced with the
/// newly specified path.
/// <p>
/// Calling SysRoutinePath("") with a null string as a parameter resets the current
/// namespace for system routine access to the default namespace.
/// <p>
/// The namespace strings you specify can be either an explicit namespace or an
/// implied namespace (a directory path or OpenVMS file specification preceded by two
/// caret characters (^^)).
/// <p>
/// To understand SysRoutinePath, you need to keep the following in mind. When a
/// process starts, it uses routines in the current namespace. After you issue
/// $system.Process.SysRoutinePath(new), all subsequent system routines come from new.
/// <p>
/// If you issue $system.Process.SysRoutinePath(new,second,third), all subsequent system
/// routines located in namespace new will come from new. If the system does not find
/// a system routine in new, the system looks for the routine in namespace second. If the
/// system does not find the system routine in second, the system looks for the routine
/// in namespace third.
/// <p>
/// Note: Using routines in second is VERY slow! You should use second as an aid to
/// program development, not as a normal running procedure.
/// <p>
/// To use SysRoutinePath as a development aid, make new your development area and use
/// second as a storage area of routines that work.  When you issue ZSAVE, the system routine
/// you save always goes into new, even if you loaded it from second. As you edit and
/// file system routines, they appear in new without affecting the library in second, and
/// subsequent calls for the system routines get the new version from new.
/// <p>
/// The method does not affect globals; the original namespace still defines access
/// privileges for globals. Your process uses globals in the current namespace unless
/// you make explicit or implicit references to globals in other namespaces. In other
/// words, the system routines come from primary (or from second or third), while the
/// globals come from the process's current namespace.
/// <p>
/// This method does not affect user routines whose names do not begin with a per cent (%).
/// For user routines see the UserRoutinePath method.
/// <p>
/// <b>Return value</b> -- the primary namespace for system routine access
/// that was set before you called SysRoutinePath.
/// 
ClassMethod SysRoutinePath(primary As %String, second As %String, third As %String) As %String
{
	quit:'$d(primary) $zu(39)
	quit:'$d(second) $zu(39,primary)
	quit:'$d(third) $zu(39,primary,second)
	quit $zu(39,primary,second,third)
}

/// The <b>IsGhost(pid)</b> class method returns 1 if a specified process
/// has been killed at the O/S level and has not yet been cleaned by the
/// CLNDMN process.  Until the process is cleaned, their may be
/// outstanding locks or resources which may be unavailable to
/// other processes.  Otherwise, this method returns 0.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried
/// <p>
/// <b>Return value</b> -- 1 if the specified process is a Ghost process;<br>
///                        0 otherwise
/// 
ClassMethod IsGhost(pid As %Integer) As %Boolean
{
 quit $ZU(67,0,pid)=1
}

/// The <b>IsProgrammerMode()</b> class method returns 1 if the current process started in programmer mode, zero otherwise.
/// Equivalent to $zjob#2.
ClassMethod IsProgrammerMode() As %Boolean
{
 quit $zjob#2
}

/// The <b>State(pid)</b> class method returns the current state of a
/// specified process.
/// <p>
/// The current state of a process is determined by the processes state bits.<br>
/// The following are all the different states a process can be in. The
/// process may also have a number of different flags within these states
/// which are appended to the end of the state name:<br>
/// LOCK - Executing a Lock command<br>
/// OPEN - Opening a device<br>
/// CLOS - Closing a device<br>
/// USE  - Using a device<br>
/// READ - Read command<br>
/// WRT  - Write command<br>
/// GGET - Executing a $Get on a global<br>
/// GSET - Setting a global<br>
/// GKLL - Killing a global<br>
/// GORD - $Order on a global<br>
/// GQRY - $Query on a global<br>
/// GDEF - $Data on a global<br>
/// ZF   - Executing a $ZF command<br>
/// HANG - Executing a Hang command<br>
/// JOB  - Executing a Job command<br>
/// EXAM - Executing a variable exam<br>
/// BRD  - Executing a broadcast<br>
/// SUSP - Process is suspended<br>
/// INCR - Executing a $Increment<br>
/// BSET - Global Set $Bit<br>
/// BGET - Global $Bit<br>
/// EVT  - Waiting on event<br>
/// SLCT - Waiting on Socket Select<br>
/// SEM  - Waiting on Semaphore<br>
/// IPQ  - Waiting on IPQ<br>
/// DEQ  - Waiting on De-queue or Queue Move<br>
/// RUN  - Process is running<br><br>
/// Here are the flags which can be appended to the state:<br><br>
/// CS - cluster slave job waiting for net answer<br>
/// NL - Net lock waiting<br>
/// DT - The dead job has open transaction<br>
/// S  - Suspension requested<br>
/// GW - Global Wait<br>
/// NR - Net Read<br>
/// D  - Dead<br>
/// H  - Halting<br>
/// NH - Netharden<br>
/// N  - Remote network<br>
/// W  - Hibernating<br>
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried
/// <p>
/// <b>Return value</b> -- the process state string described above
/// 
ClassMethod State(pid As %Integer) As %String
{
	Quit ##class(%SYS.ProcessQuery).StateLogicalToDisplay($ZU(67,4,pid))
}

/// The <b>Routine(pid)</b> class method returns the routine name of a
/// specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the routine name of the specified process.
/// 
ClassMethod Routine(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,5,pid)
}

/// The <b>NameSpace(pid)</b> class method returns the namespace name of a
/// specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the namespace name of the specified process.
/// 
ClassMethod NameSpace(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,6,pid)
}

/// The <b>CurrentDevice(pid)</b> class method returns the device name of a
/// specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the device name of the specified process.
/// 
ClassMethod CurrentDevice(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,7,pid)
}

/// The <b>LinesExecuted(pid)</b> class method returns the number of lines
/// executed by a specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the number of lines executed by the specified
/// process.
/// 
ClassMethod LinesExecuted(pid As %Integer = "") As %Integer
{
	Set:pid="" pid=$Job
	Quit $ZU(67,8,pid)
}

/// The <b>GlobalReferences(pid)</b> class method returns the number of
/// global references made by a specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <p>
/// <b>exrtns</b> -- When invoked by the current job, and the passed exclude param
/// 	         is non zero, it will not include global refcounts associated
/// 		 with routines and classes.
/// <p>
/// <b>Return value</b> -- the number of global references made by the
/// specified process.
/// 
ClassMethod GlobalReferences(pid As %Integer = "", exrtns As %Integer = 0) As %Integer
{
	Set:pid="" pid=$Job
	Quit:((pid=$Job) && (exrtns)) $zu(67,43,$job)
	Quit $ZU(67,9,pid)
}

/// The <b>EnableDiskReadTiming</b> class method 
/// enables timing of disk reads for the current process.
/// <p>
/// <b>Return value</b> -- none
ClassMethod EnableDiskReadTiming()
{
}

/// The <b>DisableDiskReadTiming</b> class method 
/// disables timing of disk reads for the current process.
/// <p>
/// <b>Return value</b> -- none
ClassMethod DisableDiskReadTiming()
{
}

/// The <b>ResetDiskReadTiming</b> class method 
/// resets the recorded time of disk reads for the current process to 0.
/// <p>
/// <b>Return value</b> -- none
ClassMethod ResetDiskReadTiming()
{
}

/// The <b>DiskReadMilliseconds</b> class method 
/// returns the total recorded time spent in disk reads for a given process ID.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the total recorded time spent in disk reads for that process, in milliseconds
ClassMethod DiskReadMilliseconds(pid As %Integer = "") As %Integer
{
	#;RJF329, use $zu(61) not $zu(67) for returning this process's count
	Quit:pid="" $ZU(61,41,$ZU(61))
	Quit $ZU(67,41,pid)
}

/// The <b>JobType(pid)</b> class method returns the job type
/// of a specified process.  The job type is a number which tells what
/// type of process it is.  See the %syPidtab.inc include file for
/// a definition of macros for these fields. Only use the defined
/// macros in %syPidtab when referencing these fields. For example:
/// <pre>
/// If $SYSTEM.Process.JobType(pid)=$$$WDTYPE {
///    w !,"Process ",pid," is the write daemon"
/// }</pre>
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the job type of the specified process.
/// 
ClassMethod JobType(pid As %Integer = "") As %Integer
{
	Set:pid="" pid=$Job
	Quit $ZU(67,10,pid)
}

/// The <b>UserName(pid)</b> class method returns the user name of
/// a specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the user name of the specified process.
/// 
ClassMethod UserName(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,11,pid)
}

/// The <b>ClientNodeName(pid)</b> class method returns the name
/// of the client system that connected to, or initiated the connection
/// to, a process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the system name for the client that connected
/// to, or initiated the connection to, the specified process
/// 
ClassMethod ClientNodeName(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,12,pid)
}

/// The <b>ClientExecutableName(pid)</b> class method returns the name
/// of the executable that called a process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the executable name of the client that
/// initiated the connection to the specified process
/// 
ClassMethod ClientExecutableName(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,13,pid)
}

/// The <b>CSPSessionID(pid)</b> class method returns the CSP session
/// ID of the client that initiated the connection to a process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the CSP session ID of the client that
/// initiated the connection to the specified process.
/// 
ClassMethod CSPSessionID(pid As %Integer = "") As %String
{
	// result type ?????
	Set:pid="" pid=$Job
	Quit $ZU(67,14,pid)
}

/// The <b>ClientIPAddress(pid)</b> class method returns the IP address
/// of the system that initiated the connection a specified process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- Process id of the process being queried<br>
///               Current process, $JOB, if parameter is missing
/// <p>
/// <b>Return value</b> -- the IP Address of the system that
/// initiated the connection to the specified process.
/// 
ClassMethod ClientIPAddress(pid As %Integer = "") As %String
{
	Set:pid="" pid=$Job
	Quit $ZU(67,15,pid)
}

/// The <b>Terminate(pid, ExitStatus)</b> class method terminates a specified
/// process and causes it to return a specified exit status to the O/S.
/// <p>
/// <b>Parameters</b>
/// <ul type=disc>
/// <li><b>pid</b> -- Process id of the process being terminated<br>
///               Defaults to current process, $JOB, if parameter is missing
/// <p>
/// <li><b>ExitStatus</b> A nonnegative parameter value is the exit status
/// returned to the O/S by the terminated process.  Negative values are
/// reserved to InterSystems except that -65 can be used to terminate a
/// InterSystems IRIS instance daemon or a process in an unresolved transaction state.<br>
/// Defaults to 1 if the ExitStatus parameter is missing.
/// </ul>
/// <p>
/// <b>Return values</b><br>
/// <ul type=disc>
/// <li> 1 -- Success
/// <li> 0 -- Failure - Process exempt from termination (eg. GARCOL/DAEMON).  It
/// can only be terminated if you specify an ExitStatus parameter value of -65.
/// <li>-1 -- Failure - Process is non-responsive
/// <li>-2 -- Failure - Process is inactive, a ghost or a "dead" process
/// <li>-3 -- Failure - Process pid does not reference an InterSystems IRIS process
/// <li>-4 -- Failure -- The process has an open transaction that is currently
/// in a halt or rollback state.  The process cannot be terminated unless
/// you specify an ExitStatus parameter value of -65.
/// </ul>
/// 
ClassMethod Terminate(pid As %Integer = "", ExitStatus As %Integer = 1) As %Integer
{
	Set:pid="" pid=$Job
	Quit $ZU(4,pid,ExitStatus)
}

/// Returns the frame stack size, in bytes, for the current process.
ClassMethod FrameStackSize() As %Integer
{
}

/// Indicates whether the frame stack has been expanded following a &lt;FRAMESTACK&gt; error.<br>
/// If it is 1, another &lt;FRAMESTACK&gt; will terminate the process without running any error trap.<br>
/// It will automatically return to 0 after enough stack entries are popped to return to normal operation.
ClassMethod FrameStackExpanded() As %Boolean
{
}

/// Sets the Application Metadata Information string for the current execution level.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>info</b> -- the text describing the current level.<br>
/// If not specified, any existing Metadata for the current level is removed.
/// <p>
/// <b>enable</b> -- whether to enable external interrupts.<br>
/// 0 - the state of external interrupts will not be changed (the default).<br>
/// 1 - external interrupts will be enabled. When this Metadata is removed,
///     the interrupt status will be restored to its previous value.
/// <p>
/// <b>Return value</b> -- the previous value, if any, of Meadata for the current execution level.
/// <p>
ClassMethod AppFrameInfo(info As %String, enable As %Integer) As %String
{
}

/// Returns the entire Application Metadata Information for the specified process.<br>
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>pid</b> -- The Process ID of the process to inspect.
/// <p>
/// <b>Return value</b> -- The application frame information in $LIST form.
/// <p>
ClassMethod GetAppFrameInfo(pid As %Integer) As %List
{
}

/// The <b>TimeZone(newTZ)</b> class method changes the time zone for the process.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>newTZ</b> -- string specifying the time zone that will be
/// assigned to the environment variable TZ. The time zone is usually
/// specified in POSIX or Olson format. Check the OS manuals to see
/// the appropriate syntax.<br>
/// <p>
/// Invoking TimeZone() without an argument just returns the previous
/// value of TZ.
/// <p>
/// <b>Return value</b> -- the previous value of the TZ environment variable
/// or -1 if it was undefined.
/// 
ClassMethod TimeZone(newTZ As %String) As %String
{
}

/// The <b>ListFormat</b> class method returns the current value of the
/// switch that determines whether new $LIST values are compressed or not,
/// and it can specify a new value for the switch.
/// <p>
/// Existing lists, whether compressed or not, can be read regardless of
/// the switch value.
/// <p>
/// The switch consists of two bit values which may be specified separately or combined.<br>
/// 1 - IEEE ($DOUBLE(nn)) values should be compressed.<br>
/// 2 - Unicode strings should be compressed.<br>
/// 3 - Both IEEE and Unicode values should be compressed.
/// <p>
/// <b>Parameter</b>
/// <p>
/// <b>newFormat</b> -- integer specifying the new value for the switch.
/// If it is omitted, the current value is not changed.
/// <p>
/// <b>Return value</b> -- the switch value prior to calling this method.
/// 
ClassMethod ListFormat(newFormat As %Integer) As %Integer
{
}

/// The <b>TransactionsSuspended(switch)</b> class method controls a switch
/// that will allow a process to temporarily suspend transactions.
/// <p>
/// <b>Warning:</b>  Changing a global variable during a transaction, then changing
/// that same global while the transaction is suspended, can result in an
/// error being logged if the transaction is ultimately rolled back.
/// A global variable modification during the transaction suspension is not rolled
/// back.  This may prevent rolling back an earlier modification of that
/// same variable that occured while the transaction was not suspended.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>switch</b> -- a boolean value that specifies whether transactions
/// are to be suspended or are to be resumed<br>
/// 1 -- Transactions are to be suspended.<br>
/// 0 -- Transactions are to be resumed.<br>
/// <p>
/// Invoking TransactionsSuspended() without specifying the switch parameter
/// returns the current switch setting without changing that setting.
/// <p>
/// <b>Return value</b> -- the TransactionsSuspended switch state prior to
/// calling the TransactionsSuspended method.
/// 
ClassMethod TransactionsSuspended(switch As %Boolean) As %Boolean
{
	Set oldflag=$ZU(139)
	quit:'$d(switch) oldflag
	if 'switch { do $zu(139,4)  quit oldflag }
	do $zu(139,2)  quit oldflag
}

/// The <b>PipeExitCode(device,.status)</b> class method returns the process
/// exit code for a CPIPE device.
/// <p>
/// <b>Parameters</b>
/// <p>
/// <b>device</b> -- the command pipe device name, such as "|CPIPE|".
/// <p>
/// <b>status</b> -- Optional -- a variable to receive a %Status value if
/// the exit code can not be obtained.
/// <p>
/// <b>Return value</b> -- the integer exit code of the process started by
/// the CPIPE device, or "" if the exit code is not available.
/// 
ClassMethod PipeExitCode(device As %String, ByRef status As %Status)
{
	new %objlasterror
	try {
		if $E(device,1,7)'="|CPIPE|" {
			set status=$$$ERROR($$$GeneralError,"Not a CPIPE device")
			set rc=""
			quit
		}
		set status=$$$OK
		set oldio=$IO
		use device
		set rc=$ZU(214)
		if $E(rc)="E" {
			set rc=+$E(rc,2,*)
			set status=$$$ERROR($$$GeneralError,$case(rc,-1:"Process Still Running",-2:"Device error",:"System error "_rc))
			set rc=""
		}
	} catch e {
		set status=e.AsStatus()
		set rc=""
	}
	if $d(oldio) use oldio
	quit rc
}

}
