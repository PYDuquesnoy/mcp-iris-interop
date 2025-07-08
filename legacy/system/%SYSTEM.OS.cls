/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Output Stream
/// <br><br>
/// This class contains methods to send items framed in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format to a TCP stream.
/// It is part of the InterSystems IRIS Native API.
/// The other endpoint is usually an IRIS server.
/// For input stream methods see <class>%SYSTEM.IS</class>.
Class %SYSTEM.OS Extends %SYSTEM.Help [ System = 4 ]
{

/// Send items to the output stream.
/// <br><br>
/// Each argument of this method is evaluated as an expression and the resulting value is framed (i.e. as a $List item) and added to the device buffer.
/// When adding a framed item to the buffer, if there's not enough space, the previous contents of the buffer are flushed and the operation continues.
/// If any individual item is longer than the buffer size, its frame will be sent with as many intermediate flushes as necessary.
/// In the end, one or more items can remain in the buffer. To have them sent will require an extra flush.<br>
/// <br>
/// <b>Parameters:</b> one or more ObjectScript expressions<br><br>
/// <b>Return:</b><ul><li>0 if there was no intermediate flush</li>
///                   <li>1 otherwise</li></ul>
ClassMethod Send(item As %String) As %Integer
{
}

/// Send a Native DB request to the output stream.
/// <br><br>
/// Send a message to the server requesting the execution of the given opcode.
/// The first two arguments, msgid and contxt, are integers that identify the message and the context.
/// The method puts these two integers unchanged in the header.
/// The third argument is an integer that identifies the request (the opcode).<br>
/// <br>
/// The following arguments, item1, item2, ..., are optional and depend on the opcode.
/// If present they are wrapped as regular $List() items and sent to the server as if by $System.OS.Send(item1, item2, ...).
/// However, in this case, the length field of the header contains the number of bytes that the arguments occupy. If length is zero it means that no arguments were sent and the header contains all the information that the opcode needs.<br>
/// <br>
/// <b>Parameters:</b><br>
/// <b>msgid</b> - message id (val1 in header).<br>
/// <b>contxt</b> - context (val2 in header).<br>
/// <b>code</b> - op code.<br>
/// <b>item...</b> - zero or more ObjectScript expressions<br>
/// <br>
/// <b>Return:</b> 0
ClassMethod SendRequest(msgid As %Integer, contxt As %Integer, opcode As %Integer, item As %String) As %Integer
{
}

/// Send items to the output stream and flush the buffer.
/// <br><br>
/// This method is like Send() followed by a buffer flush.
/// Calling it without arguments just causes the flush.<br>
/// <br>
/// <b>Parameters:</b> zero or more ObjectScript expressions<br><br>
/// <b>Return:</b> 1
ClassMethod SendFlush(item As %String) As %Integer
{
}

/// Remove any data remaining in the output stream buffer.
/// <br><br>
/// <b>Return:</b> 0
ClassMethod Clear() As %Integer
{
}

/// Start logging to file "sysio_pid.log".
/// <br><br>
/// <b>Parameters:</b><br>
/// <b>flags</b> Optional initial log flags (bit values can be added):<br>
/// <ul><li>1 - Raw input</li>
///     <li>2 - Raw output</li>
///     <li>4 - IS.Execute() received opcodes</li></ul>
/// 
/// The default is 3 (raw input + raw output).<br>
/// <br>
/// <b>Return:</b><ul>
///     <li> 0 - success</li>
///     <li>-1 - logging was already enabled</li>
///     <li>-2 - could not open log file</li>
ClassMethod StartLog(flags As %Integer) As %Integer
{
}

/// Stop logging and close file "sysio_pid.log".
/// <br><br>
/// <b>Return:</b> 0
ClassMethod StopLog() As %Integer
{
}

/// Get and optionally set logging flags.
/// <br><br>
/// <b>Parameters:</b><br>
/// <b>flags</b> Optional new flags (bit values can be added):<br>
/// <ul><li>1 - Raw input</li>
///     <li>2 - Raw output</li>
///     <li>4 - IS.Execute() received opcodes</li></ul>
/// <b>Return:</b><ul><li>current flags if no value was passed</li>
///                   <li>previous flags if a new value was passed</li>
ClassMethod LogFlags(flags As %Integer) As %Integer
{
}

}
