/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using the API provided by this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.FetchMailProtocol">Sending and Receiving Email</a>.</p>
/// <P>Abstract Class that <class>%Net.POP3</class> implements.</P>
/// 
/// <P>Methods are <METHOD>Connect,</Method>,<METHOD>GetMailBoxStatus</METHOD>,
/// <METHOD>GetSizeOfMessages</METHOD>,<METHOD>GetMessageUIDArray</METHOD>,
/// <METHOD>FetchMessage</METHOD>,<METHOD>DeleteMessage</METHOD>,
/// <METHOD>RollbackDeletes</METHOD>,<METHOD>QuitAndCommit</METHOD>,
/// <METHOD>QuitAndRollback</METHOD>,<METHOD>Ping</METHOD>.</P>
/// 
/// <P>Important after <METHOD>Connect</METHOD> is called, you must call
/// before your session ends either <METHOD>QuitAndCommit</METHOD> or
/// <METHOD>QuitAndRollback</METHOD>.</P>
/// 
/// <P>Each of the methods of this class returns a value of type %Status 
/// indicating success or failure.</P>
/// 
/// The charset used for each text mail message part is returned in the 
/// <property>Charset</property> property of the <class>%Net.MailMessagePart</class>
/// class.  The data is automatically translated to the current cache locale's
/// default character set when reading from the TextData text stream.
/// 
/// <P>The following shows an example of getting messages:</P>
/// 
/// <EXAMPLE>
/// #include %occOptions
/// #include %occStatus
/// 
/// ; display mail but don't delete from mailbox
/// testmail6 ;
/// new mailserver,status,err,mailMsg
/// set mailserver=##class(%Net.POP3).%New()
/// set mailserver.AttachDir="d:\attach\"  ; need terminating \
/// set mailserver.StoreAttachToFile=1
/// write !,"Calling Connect"
/// set status=mailserver.Connect("moon.kinich.com","testjsl","jsltest")
/// if $$$ISERR(status) do DecomposeStatus^%apiOBJ(status,.err) write !,err(err),! quit
/// write !,"Calling Fetch to retrieve the oldest message on the server."
/// set status=mailserver.Fetch(1,.mailMsg,0)
/// if $$$ISERR(status) do DecomposeStatus^%apiOBJ(status,.err) write !,err(err),! quit
/// write !,"from="_mailMsg.From
/// write !,"to="_mailMsg.Headers.GetAt("to")
/// write !,"date="_mailMsg.Date
/// write !,"subject="_mailMsg.Subject
/// write !,"messagesize="_mailMsg.MessageSize
/// do DumpMessage(mailMsg)
/// quit
/// 
/// DumpMessage(msg) 
/// new i,index,value,len
/// if msg.IsMultiPart {
///     for i=1:1:msg.Parts.Count() write !,"Dumping part "_i do DumpMessage(msg.Parts.GetAt(i))
///     quit
/// }
/// 
/// set index=""  for  set value=msg.Headers.GetNext(.index) quit:index=""  write !,"Headers("_index_")="_value
/// if msg.IsBinary {
///     write !,"msg is binary, filename="_msg.FileName_" filename="_msg.GetAttribute("content-disposition","filename")
/// } else {
///     write !,"Dumping text msg Filename="_msg.FileName_" filename="_msg.GetAttribute("content-disposition","filename"),!
///     set stream=msg.TextData
///     do stream.Rewind()
///     set len=32763
///     while 'stream.AtEnd {
///         write stream.Read(.len)
///     }
/// }
/// quit
/// 
/// </EXAMPLE>
Class %Net.FetchMailProtocol Extends %RegisteredObject [ Abstract, Not ProcedureBlock, System = 3 ]
{

Property Connected As %Boolean;

/// When receiving messages using POP3, the directory where attached files will be stored 
Property AttachDir As %String;

/// We always store attachments as a part in the message.
/// If StoreAttachToFile=true and content-disposition MIME header of attachment part = "attachment",
/// we ALSO store to the directory specified in AttachDir
Property StoreAttachToFile As %Integer [ InitialExpression = 0 ];

/// We always store attachments as a part in the message.
/// If StoreInlineToFile=true and content-disposition MIME header of attachment part = "inline",
/// we ALSO store to the directory specified in AttachDir
Property StoreInlineToFile As %Integer [ InitialExpression = 0 ];

Property Debug As %Integer [ InitialExpression = 0 ];

/// <P>Use to logon to your mail server using the
/// username and password that are the parameters to this routine.</P>
Method Connect(PopServer As %String, UserName As %String, Password As %String) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>Get information about your mail box, the number of bytes it
/// contains, and the number of messages;</P>
Method GetMailBoxStatus(ByRef NumberOfMessages As %Integer, ByRef NumberOfBytes As %Integer) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>If you pass in an empty string "", an array with an element for 
/// each of the messages not marked for deletion is returned.  
/// Each element of the array has the message number as its index 
/// and the size of the message in bytes as its value..</P>
/// 
/// <P>If you pass in a message number, a one element array is returned. The element
/// has the message number as its index and the size of the message 
/// in bytes as its value.  An error status is returned if a message
/// with this message number does not exist or has been marked for deletion.</P>
Method GetSizeOfMessages(MessageNumber As %String = "", ByRef ListOfSizes As %ArrayOfDataTypes) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>If you pass in an empty string "", an array with an element for 
/// each of the messages not marked for deletion is returned.  
/// Each element of the array has the message number as its index 
/// and the unique message identifier (UID) as its value..</P>
/// 
/// <P>If you pass in a message number, a one element array is returned. The element
/// has the message number as its index and unique message identifier (UID)
/// as its value.  An error status is returned if a message
/// with this message number does not exist or has been marked for deletion.</P>
/// 
/// <P>The unique message identifier is at most 70 characters long and
/// each character is ASCII and printable (0x21 to 0x7E).</P>
/// 
/// <P>Each identifier is unique within the mailbox and is persistent.
/// If a given message has a particular unique identifier in one
/// session, it must have the same unique ID in all sessions.  Once
/// used, a given UID can never be reused even if the corresponding
/// message is deleted.</P>
/// 
/// <P>If a specified message (corresponding to MessageNumber) does not
/// exist or is marked for deletion, the function returns an error status.
/// 
/// <P>This command is used to implement a poor man's server-based
/// message store.  Basically, a client does not automatically
/// delete messages, after getting messages, then at the start of
/// each session, it calls GetMessageUIDArray to obtain an
/// array of all messages currently on the server.  Any UIDs not
/// currently known by the client are retrieved.  That of course
/// requires the client to keep track of the UIDs for all retrieved
/// messages.</P>
Method GetMessageUIDArray(MessageNumber As %String = "", ByRef ListOfUniqueIDs As %ArrayOfDataTypes) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>For the message number singled out by MessageNumber, this
/// function returns the corresponding unique id.  The message
/// number must not correspond to a non-existent message or a
/// message already marked for deletion or an error message is
/// returned.</P>
/// 
/// <P>The unique message identifier is at most 70 characters long and
/// each character is ASCII and printable (0x21 to 0x7E).</P>
/// 
/// <P>Each identifier is unique within the mailbox and is persistent.
/// If a given message has a particular unique identifier in one
/// session, it must have the same unique ID in all sessions.  Once
/// used, a given UID can never be reused even if the corresponding
/// message is deleted.</P>
/// 
/// <P>If a specified message (corresponding to MessageNumber) does not
/// exist or is marked for deletion, the function returns an
/// error %Status.</P>
/// 
/// <P>This command is used to implement a poor mans server-based
/// message store.  Basically, a client does not automatically
/// delete messages, after getting messages, then at the start of
/// each session, it calls GetMessageUIDs to obtain a
/// list of all messages currently on the server.  Any UIDs not
/// currently known by the client are retrieved.  That of course
/// requires the client to keep track of the UIDs for all retrieved
/// messages.<P>
Method GetMessageUID(MessageNumber As %Integer, ByRef UniqueID As %String) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <p>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
/// 
/// <P>If Delete is 1, the message is deleted.  If 0, it is not deleted.</P>
/// 
/// <p>If messageStream is specified, then the original message is written to this binary stream.
/// messageStream needs to be a binary stream since mail messages may include binary data
/// and multiple charsets.
Method Fetch(MessageNumber As %Integer, ByRef Msg As %Net.MailMessage, Delete As %Boolean, messageStream As %BinaryStream) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <p>This method retrieves a single eml format message from a binary stream.  
/// messageStream must be a binary stream containing the message.</p>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
Method FetchFromStream(messageStream As %BinaryStream, ByRef Msg As %Net.MailMessage) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
/// 
/// <P>If Delete is 1, the message is deleted.  If 0, it is not deleted.</P>
/// 
/// <P>FetchMessage also returns selected headers in additional by 
/// reference parameters as well as the array of all headers.</P>
Method FetchMessage(MessageNumber As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef Msg As %Net.MailMessage, Delete As %Boolean) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>An upper bound is put on number of lines of message text
/// retrieved by Lines.</P>
/// 
/// <P>The text of the retrieved message is returned in the MessageText argument as a %String.</P>
/// 
/// <P>FetchMessageInfo is typically used to get From, Date, and other
/// header information without actually getting the message text.  This
/// allows one to filter out messages from parties one wishes to exclude
/// or to zero in on messages one particularly wants.  Since getting
/// message text is something that can happen over a slow modem, this
/// is a desirable feature.</P>
Method FetchMessageInfo(MessageNumber As %Integer, Lines As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef MessageText As %String) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This method deletes a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
Method DeleteMessage(MessageNumber As %Integer) As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This method unmarks any messages previously marked for deletion.</P>
Method RollbackDeletes() As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This method ends the session of this Protocl object with the
/// mail server.</P>
/// 
/// <P>Also, as a side-effect, any messages marked for deletion are deleted.</P>
/// 
/// <P>This function (or its companion QuitAndRollback) must be
/// executed before the process that issued a connect ends or havoc
/// could be wreaked upon the mail server.  (Mail servers do not
/// have to bullet proof themselves against connects not followed by
/// a quit.)</P>
Method QuitAndCommit() As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This function calls RollbackDeletes and then quits.</P>
/// 
/// <P>This method ends the session of this Protocl object with the
/// mail server.</P>
/// 
/// <P>This function (or its companion QuitAndCommit) must be
/// executed before the process that issued a connect ends or havoc
/// could be wreaked upon the mail server.  (Mail servers do not
/// have to bullet proof themselves against connects not followed by
/// a quit.)</P>
Method QuitAndRollback() As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>This function is used to prevent an autologout timer from expiring
/// or to determine if the server is still functioning on the connection.</P>
Method Ping() As %Status
{
 quit $$$ERROR($$$UnsupportedError)
}

/// <P>Protect against terminating without doing a quit</P>
Method %OnClose() As %Status
{
 if ..Connected do ..QuitAndRollback() set ..Connected=0
}

Storage Default
{
<Type>%Storage.Serial</Type>
}

}
