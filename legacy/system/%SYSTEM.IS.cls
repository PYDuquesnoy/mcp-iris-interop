/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Input Stream
/// <br><br>
/// This class contains methods to receive items framed in $LIST format from a TCP stream.
/// It is part of the InterSystems IRIS Native API.
/// The other endpoint is usually a client written in a language other than ObjectScript.
/// For clients in ObjectScript see <class>%SYSTEM.OS</class>.
Class %SYSTEM.IS Extends %SYSTEM.Help [ System = 4 ]
{

/// Read a single $LIST() item from the input stream.
/// <br><br>
/// Consumes a framed item from the input stream and returns the corresponding ObjectScript data value.
/// If there are not enough bytes to form a complete item, the method will wait until the device driver produces the necessary number of bytes.
/// A timeout argument is optional and if present overrides the default timeout. See the Timeout() method below for details.<br>
/// <br>
/// <b>Parameter:</b><br>
/// <b>to</b> - Optional - New timeout in seconds (default = 300).<br><br>
/// <b>Return:</b> the value read from the stream.
ClassMethod Receive(to As %Integer) As %String
{
}

/// Read a new message from the input stream and return its header as a $LB(type,msgid,contxt,code).
/// <br><br>
/// Retrieve the msgid, the contxt and the code from the input stream.
/// In most situations the msgid and the contxt will be the same as the ones sent with a SendRequest(msgid,...) and the code will be an error code for that operation.<br><br>
/// Depending on the opcode that was requested, one of more response items can be available in the input stream. These can be read with further calls to Receive().
/// In less common situations, msgid will be a new identifier sent by the other end as the beginning of a new (reentrant) request. In this case the code will be the corresponding opcode.<br><br>
/// The type is a small integer that quickly characterizes the header.
/// Strictly speaking this information is not necessary because just by looking at the integer value of the code one can determine the type of the message. But the 'type' field is included as a convenience.
/// Besides, depending on the type, the code field has been changed to be in a more suitable format:<br>
/// <br>
/// <b>type:</b><ul><li>= 0 -> Return code (number starting from 0)</li>
///                <li>= 1 -> Native DB request code (number starting from 0)</li>
///                <li>= 2 -> DBSRV code (2-character string)</li></ul>
/// 
/// Normally, following a SendRequest() you will get a header with a return code (type = 0), but the format is more generic and also used by Execute().
/// A timeout argument is optional and if present overrides the default timeout. See the Timeout section below for details.<br>
/// <br>
/// <b>Parameter:</b><br>
/// <b>to</b> - Optional - New timeout in seconds (default = 300).<br><br>
/// <b>Return:</b>The header of the message as $LB(type,msgid,contxt,code)
ClassMethod ReceiveReply(to As %Integer) As %String
{
}

/// Execute a client request.
/// <br><br>
/// <b>Parameters:</b><br>
/// <b>loop</b>
/// <ul><li>True: execute requests until a STOP command is received</li>
///     <li>False: execute one request and return</li></ul><br>
/// <b>msgid</b> - Optional - Message id (val1 in header).<br>
/// <b>contxt</b> - Optional - Context (val2 in header).<br>
/// <b>code</b> - Optional - Op code or reply code.<br>
/// <b>to</b> - to - Optional - Timeout in seconds.<br><br>
/// <b>Return:</b>
/// <ul><li>0 - Single opcode was executed</li>
///    <li>-1 - STOP opcode was received</li>
///    <li>$LB(type, msgid, contxt, code) - this code is not handled by the kernel</li></ul>
ClassMethod Execute(loop As %Boolean, msgid As %Integer, contxt As %Integer, code As %Integer, to As %Integer) As %Integer
{
}

/// Get and optionally set the default timeout for the input stream methods.
/// <br><br>
/// All input methods (IS.Receive(), IS.ReceiveReply() and IS.Execute()) are subject to a timeout.
/// If no data arrives within the established period, the method throws a &lt;TIMEOUT&gt; error.
/// The timeout value can be passed as the last argument to these methods but, if omitted, a default value is used.
/// Timeouts are expressed in seconds and -1 means infinite timeout (no timeout).<br>
/// <br>
/// <b>Parameter:</b><br>
/// <b>to</b> - Optional - New timeout in seconds (default = 300).<br><br>
/// <b>Return:</b>
/// <ul><li>Current timeout if no argument was passed</li>
///     <li>Previous timeout if a new value was passed</li></ul>
ClassMethod DefaultTimeout(to As %Integer) As %Integer
{
}

/// Remove any data remaining in the input stream buffer.
/// <br><br>
/// <b>Return:</b> 0
ClassMethod Clear() As %Integer
{
}

}
