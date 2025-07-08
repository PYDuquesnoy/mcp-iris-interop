/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syINET

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.FtpSession">Using FTP</a>.</p>
/// The %Net.FtpSession class provides a way of interacting with a FTP server so you can
/// send/receive files, get a list of the files on the server, rename files, delete
/// files, etc.<br>
/// <br>
/// All the methods will return a boolean that is true if the
/// method succeeded and false if it failed. They will also set the two properties
/// <PROPERTY>ReturnCode</PROPERTY> and <PROPERTY>ReturnMessage</PROPERTY> with information
/// from the ftp server you are connected to. This often contains useful information if
/// a method fails. You should at the very least check the return value from each of the
/// methods after every call.<br>
/// <br>
/// Once you have created an object of this class you need to login to the server
/// you wish to communicate with before you can do anything else, this is done with the
/// <METHOD>Connect</METHOD> method. You can tell if you are connected to a server by
/// looking at the property <PROPERTY>Connected</PROPERTY>.<br>
/// <br>
/// If an ftp server at 'TestMachine' had a binary file called 'test.exe' in the root
/// ftp directory then the following example will pull this file into InterSystems IRIS.<br>
/// <EXAMPLE>
/// Set ftp=##class(%Net.FtpSession).%New()
/// If 'ftp.Connect("TestMachine","ftp","username@domain.com") Write "Not connected",! Quit
/// Write "Ftp server messsage:",!,ftp.ReturnMessage,!
/// Set stream=##class(%GlobalCharacterStream).%New()
/// If 'ftp.Binary() Write "Can not swap to binary mode",! Quit
/// Write "Mode now: ",ftp.Type,!
/// If 'ftp.Retrieve("test.exe",stream) Write "Failed to get file",! Quit
/// Write "Length of file received: ",stream.Size,!
/// If 'ftp.Logout() Write "Failed to logout",!
/// Quit
/// </EXAMPLE>
Class %Net.FtpSession Extends %RegisteredObject [ System = 3 ]
{

/// The Callback property is designed to allow user code in the class
/// <CLASS>%Net.FtpCallback</CLASS> to be called at regular intervals during
/// an ftp <METHOD>Store</METHOD> or <METHOD>Retrieve</METHOD>. This can
/// display the progress of the ftp operation to the user and could allow
/// the user to abort the transfer.
Property Callback As %Net.FtpCallback;

/// True if we are currently connected to an ftp server and false if not.
Property Connected As %Boolean [ InitialExpression = 0 ];

/// True if the connection is IPV6 protocol.
Property IsIPV6 As %Boolean [ InitialExpression = 0 ];

/// Server's IP address to be used in EPSV mode with IPV6 protocol.
Property ServerAddr As %String;

/// ReturnCode is a the three digit number that the ftp server reponds to commands
/// with. This can be used to determine if the command completed or if there
/// were problems. See the rfc on ftp for more information on these codes.
Property ReturnCode As %Integer [ InitialExpression = 0 ];

/// ReturnMessage is set to the text message
/// that the ftp server responds with, this often contains useful information if
/// a method failed, or useful information such as the text banner you get when
/// you first login to an ftp server.
Property ReturnMessage As %String;

/// The name of the activated TLS configuration to use for ftp requests.
/// If specified then we use TLS on the FTP connection as specified in RFC4217.
/// Both the data and the command channel will be secured with TLS after the initial
/// connect on the command channel tells the remote server to switch to TLS mode.
Property SSLConfiguration As %String;

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being off and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 0 ];

/// If true and you specify a <property>SSLConfiguration</property> then this class
/// will use non-standard implied SSL on the data and command channel rather than
/// using RFC4217. Depending on the configuration of the server you are talking to
/// it may be needed to also send 'PBSZ 0' and 'PROT P' before you can communicate, this
/// can be done with 'Set rc=ftp.sendCommand("PBSZ 0"),rc2=ftp.sendCommand("PROT P")'.
Property LegacySSL As %Boolean [ InitialExpression = 0 ];

/// When making the SSL connection for the data channel, reuse session parameters from the command channel.
/// This feature requires OpenSSL v1.1.x+.
Property SSLUseSessionResumption As %Boolean [ InitialExpression = 0 ];

/// Timeout is the amount of time to wait for a response from the ftp server before
/// assuming that the server is not responding or the network connection is not
/// working. The default value is 10 seconds.
Property Timeout As %Integer [ InitialExpression = 10 ];

/// Type returns the transfer mode the ftp server is currently set to. This can be
/// either Ascii or Binary. The methods <METHOD>Ascii</METHOD> and
/// <METHOD>Binary</METHOD> change the mode the server is currently set to.
Property Type As %String [ Calculated ];

/// Ftp connections are formed from two TCP/IP connections to the remote server,
/// a command channel where the ftp commands are sent down and command responses
/// are retrieved and a data channel for streaming large pieces of data. The way the
/// data channel is connected is determined by this property. In PASV mode, the default,
/// this ftp client asks the server where to connect for the data channel and it then
/// initiates this connection to the remote server. If PASV mode is not used then the
/// client tells the remote server where to connect to and the remote server initiates
/// the data connection to this client machine. PASV mode is turned on by default because
/// when going through a firewall having the remote ftp server initiate the data channel
/// often does not work, but PASV mode will work in this case.
Property UsePASV As %Boolean [ InitialExpression = 1 ];

/// When using PASV mode (see <property>UsePASV</property>) the remote server supplies the
/// IP address and port to connect to. On misconfigured servers it is possible this may report
/// a private IP address when we are connecting to it from a public IP address so the PASV
/// connection fails. We automatically detect this and use the initial IP address we had connected
/// to in this case, but if you set this property =0 it turns this detection off.
/// If this property is 2 then we never use the PASV supplied server IP and always use the original server
/// address.
Property AutoDetectPrivate As %Integer [ InitialExpression = 1 ];

/// Internal name of the ftp server we connected to
Property ServerName As %String [ Internal, Private ];

/// Indicates whether to use FTP Extensions for IPv6 and NATs.  When set, the extension commands EPRT and EPSV
/// will be used in place of the PORT and PASV commands.  The default value is 0,
/// but UseExtentions is automatically set to 1 when an IPV6 address is used.
/// The FTP Extension commmands are useful to avoid problems using FTPS with 
/// Network Address Translation (NAT) as when traversing firewalls.
Property UseExtensions As %Boolean [ InitialExpression = 0 ];

/// The translate table to be used when reading or writing files.
/// See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.
Property TranslateTable As %String;

/// The translate table to use for the command channel, specifically for the filename/pathnames.
/// See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.
/// <br>Normally this should not be specified in which case if the ftp server supports UTF-8 then
/// we will use that for the filename/pathnames, if the server does not support UTF-8 then we
/// will use RAW mode and just read the bytes as sent.
Property CommandTranslateTable As %String;

Method CommandTranslateTableSet(table As %String) As %Status
{
	Set i%CommandTranslateTable=table
	If ..Connected {
		If table="" {
			#; Check if server supports UTF8
			If ..Features(),..ReturnCode=211 {
				If ..ReturnMessage[(" UTF8"_$char(13,10)) {
					Set table="UTF8",i%CommandTranslateTable="UTF8"
				}
			}
		}
		Set io=$IO
		Use ..device
		Do SetIO^%SYS.NLS($select(table="":"RAW",1:table))
		Use io
	}
	Quit $$$OK
}

Property device As %String [ Private ];

Property transferType As %Integer [ InitialExpression = 1, Private ];

Property serverIP As %String [ Private ];

Method %OnClose() As %Status [ Private ]
{
	If ..Connected Close ..device
	Quit $$$OK
}

/// Append the data contained in <var>Stream</var> to the file named in <var>Filename</var>.
Method Append(Filename As %String, Stream As %AbstractStream) As %Boolean [ CodeMode = expression ]
{
..genericStore("APPE "_Filename,Stream,..TranslateTable)
}

/// Switch the ftp server transfer type to Ascii. This will for example convert Cr/Lf
/// to Lf for Unix systems. When transfering text files you should use this mode. The
/// current mode can be found by looking at the property <PROPERTY>Type</PROPERTY>.
Method Ascii() As %Boolean
{
	If ..sendCommand("TYPE A") Set ..transferType=1
	Quit ..returnStatus()
}

/// Switch the ftp server transfer type to Binary. This will store the data in exactly
/// the same format it is sent in. When transfering any binary files you should use
/// this mode. The current mode can be found by looking at the property <PROPERTY>Type</PROPERTY>.
Method Binary() As %Boolean
{
	If ..sendCommand("TYPE I") Set ..transferType=2
	Quit ..returnStatus()
}

/// Connect to an Ftp server. You should supply the server IP address or domain name
/// to connect to as the <var>Server</var> parameter. Also most Ftp server will require
/// a <var>Username</var> and a <var>Password</var> in order to allow you to login. To login to
/// an anonymous Ftp server	use the Username="anonymous" and the Password is your email address.<br>
/// <var>Port</var> is an optional parameter that specifies the IP port number to connect
/// on if it is not the standard port of 21.
Method Connect(Server As %String, Username As %String, Password As %String, Port As %Integer = 21) As %Boolean
{
	Set ..ReturnCode=0,..ReturnMessage=""
	If ..Connected Quit ..error(503,"Already connected to a server; disconnect first")
	Set ..device=..GetDevice()
	If ..LegacySSL,..SSLConfiguration'="" {
		Open ..device:(Server:Port:"CST"::8192:8192:/TCPNOXY:/TLS=$select(..SSLCheckServerIdentity:..SSLConfiguration_"||"_Server,1:..SSLConfiguration)):..Timeout Else  Quit ..error(530,"Unable to open connection to "_Server_" on port "_Port_" SSLConfiguration "_..SSLConfiguration)
	} Else {
		Open ..device:(Server:Port:"CST"::8192:8192:/TCPNOXY):..Timeout Else  Quit ..error(530,"Unable to open connection to "_Server_" on port "_Port)
	}
	If '..setupIPV6() Quit ..error(530,"Unable to setup IPV6 flag "_Server_" on port "_Port)
	Set ..Connected=1, ok=0
	If '..readResponse() Quit ..returnStatus()
	
	If ..SSLConfiguration'="",'..LegacySSL {
		If '..sendCommand("AUTH TLS")||(..ReturnCode'=234) Quit ..returnStatus()
		Set io=$io Use ..device:(/TLS=$select(..SSLCheckServerIdentity:..SSLConfiguration_"||"_Server,1:..SSLConfiguration)) Use io
	}
	Set ok=..ChangeUser(Username,Password)
	If 'ok,..Connected {
		Set code=..ReturnCode,message=..ReturnMessage
		Do ..Logout()
		Set ..ReturnCode=code,..ReturnMessage=message
	}
	#; At this point we will have connected with TLS and sent one message and so will have the certificate to validate server identity
	If ..Connected,..SSLConfiguration'="",..SSLCheckServerIdentity {
		Set io=$io Use ..device
		Set sc=##class(%Net.HttpRequest).CheckSSLCN(Server)
		Use io
		If $$$ISERR(sc) {
			Set return=..error(534,"Failed to validate TLS server host name certificate '"_Server_"'")
			Do ..Logout()
			Quit ..error(534,"Failed to validate TLS server host name certificate '"_Server_"'")
		}
	}
	If ..SSLConfiguration'="",'..LegacySSL {
		If '..sendCommand("PBSZ 0")||(..ReturnCode'=200) Quit ..returnStatus()
		If '..sendCommand("PROT P")||(..ReturnCode'=200) Quit ..returnStatus()
	}
	Set ..CommandTranslateTable=..CommandTranslateTable
	Set ..ServerName=Server
	Quit ok
}

/// See which features the ftp server supports
Method Features() As %Boolean
{
	Quit ..sendCommand("FEAT")
}

/// Change the user that we are logged in as. This assumes you are already connected
/// to the ftp server at this point.
Method ChangeUser(Username As %String, Password As %String) As %Boolean
{
	#; Now send username, if this fails or it does not need a password we are done
	If '..sendCommand("USER "_Username,1)||(..ReturnCode'=331) Quit ..returnStatus()
	Quit ..sendCommand("PASS "_Password)
}

/// Delete the file <var>Filename</var> on the Ftp server.
Method Delete(Filename As %String) As %Boolean [ CodeMode = expression ]
{
..sendCommand("DELE "_Filename)
}

/// Return the current directory the Ftp server is in the parameter <var>Path</var> that
/// is passed by reference.
Method GetDirectory(ByRef Path As %String) As %Boolean
{
	Do ..sendCommand("PWD")
	If $E(..ReturnCode)'=2 Set Path="" Quit 0
	Set Path=..getPath(..ReturnMessage)
	Quit 1
}

/// Read in the files that match the <var>Pattern</var> in a human readable format
/// into <var>Stream</var>. The <var>Pattern</var> can include a path as well pattern to
/// search for, and if no pattern is specified then it will list all the files
/// in this directory. The information returned contains server information like the file
/// size, permissions modification time as well as the filename. The format of this is
/// server specific.
Method List(Pattern As %String, ByRef Stream As %AbstractStream) As %Boolean
{
	#; We must transfer listing information in ASCII, so we may need to switch types
	Set type=..transferType
	If type'=1,'..Ascii() Quit 0
	Set return=..genericRetrieve("LIST"_$select(Pattern="":"",1:" "_Pattern),.Stream,..CommandTranslateTable)
	If type'=1 {
		Set code=..ReturnCode,message=..ReturnMessage
		If type=2 Do ..Binary()
		Set ..ReturnCode=code,..ReturnMessage=message
	}
	Quit return
}

/// Logoff and disconnect from the Ftp server.
Method Logout() As %Boolean
{
	Set status=..sendCommand("QUIT")
	Set ..Connected=0,..ServerName=""
	Close ..device
	Quit status
}

/// Create a new directory on the Ftp server. <var>Path</var> should be passed by
/// reference and it will return the name of the directory created. The Ftp server
/// will translate the path you give it into its own format (which may be different)
/// and is the value returned by in <var>Path</var>.
Method MakeDirectory(ByRef Path As %String) As %Boolean
{
	Do ..sendCommand("MKD "_Path)
	If $E(..ReturnCode)'=2 Quit 0
	Set Path=..getPath(..ReturnMessage)
	Quit 1
}

/// Given a <var>Path</var> this will return an array of filenames including their path in the parameter
/// <var>FileArray</var>, this parameter should be passed by reference and if not already
/// created it will create a new <CLASS>%ArrayOfDataTypes</CLASS>. An example of its
/// use assuming is:
/// <EXAMPLE>
/// New fileArray,key
/// If 'ftp.NameList("",.fileArray) Write "Failed to get name list",!
/// Set key=""
/// Write "List of Files:",!
/// For  Write fileArray.GetNext(.key),! Quit:(key="")
/// </EXAMPLE>
Method NameList(Path As %String, ByRef FileArray As %ArrayOfDataTypes) As %Boolean
{
	Set io=$IO,zerror=$zerror
	Set ..ReturnCode=0,..ReturnMessage=""
	If $isobject($get(FileArray)) {
		Do FileArray.Clear()
	} Else {
		Set FileArray=##class(%ArrayOfDataTypes).%New()
	}
	Set return=1
	#; We must transfer listing information in ASCII, so we may need to switch types
	Set type=..transferType
	If type'=1,'..Ascii() Quit 0
	
	For {
		If ..UsePASV {
			If '..setupPASV(.device,.server) Set return=0
		} Else {
			If '..setupPORT(.device,.server) Set return=0
		}
		If return=0 Quit	

		If '..sendCommand("NLST"_$select(Path="":"",1:" "_Path))||($E(..ReturnCode)'=1) Set return=0 Quit
	
		#; Read this line by line and insert values into the array
		Set timeout=0,exit=0
		Use device:(::"CST")
		Set $zerror=""
		Try {
			If ..CommandTranslateTable'="" Do SetIO^%SYS.NLS(..CommandTranslateTable)
			For i=1:1 {
				Read data:..Timeout
				Set exit='$test,timeout=$za#4\2
				If data'="" {
					If i=1,..SSLCheckServerIdentity,..SSLConfiguration'="" {
						#; First read so we can now check server identity on this socket
						Set sc=##class(%Net.HttpRequest).CheckSSLCN(server)
						If $$$ISERR(sc) Set return=..error(534,"Failed to validate TLS server host name certificate '"_server_"'"),timeout=1 Quit
					}
					Do FileArray.SetAt(data,$increment(j))
				}
				If exit Quit
			}
		} Catch {
			#; Will look at $zerror below
		}
		If timeout Set return=..error(529,"Timeout waiting for response") Quit
		If $ZE'["<READ>" Set ..ReturnMessage=$ZE,..ReturnCode=426,return=0 Quit
		If '..readResponse() Set return=0 Quit
		Quit
	}
	If $get(device)'="" Close device
	Set $zerror=zerror
	
	If type'=1 {
		Set code=..ReturnCode,message=..ReturnMessage
		If type=2 Do ..Binary()
		Set ..ReturnCode=code,..ReturnMessage=message
	}
	Use io
	Quit return
}

/// Delete the directory passed in <var>Path</var> from the Ftp server.
Method RemoveDirectory(Path As %String) As %Boolean [ CodeMode = expression ]
{
..sendCommand("RMD"_$select(Path="":"",1:" "_Path))
}

/// Rename a file from <var>OldFilename</var> to <var>NewFilename</var>.
Method Rename(OldFilename As %String, NewFilename As %String) As %Boolean
{
	If '..sendCommand("RNFR "_OldFilename) Quit 0
	If '..sendCommand("RNTO "_NewFilename) Quit 0
	Quit 1
}

/// Retrieve the file specified by <var>Filename</var> into <var>Stream</var>.
/// If <var>Stream</var> is not specified it will be created, in which case you
/// should pass it by reference so it can be returned to the caller.
Method Retrieve(Filename As %String, ByRef Stream As %AbstractStream) As %Integer [ CodeMode = expression ]
{
..genericRetrieve("RETR "_Filename,.Stream,..TranslateTable,0)
}

/// If a <METHOD>Retrieve</METHOD> failed because the connection was lost this allows
/// you to retry getting the file. So if you have got 1/2 of the original file in
/// the first attempt for <var>Filename</var> you pass the <var>Stream</var> with this half
/// into this method and it will start where the other transfer left off.
Method RetryRetrieve(Filename As %String, Stream As %AbstractStream) As %Integer [ CodeMode = expression ]
{
..genericRetrieve("RETR "_Filename,.Stream,..TranslateTable,1)
}

/// Set the directory on the Ftp server to <var>Path</var>.
Method SetDirectory(Path As %String) As %Boolean [ CodeMode = expression ]
{
..sendCommand("CWD"_$select(Path="":"",1:" "_Path))
}

/// Move to parent directory on the Ftp server.
Method SetToParentDirectory() As %Boolean [ CodeMode = expression ]
{
..sendCommand("CDUP")
}

/// If the FTP server supports it then this will return a files size based on the current
/// transfer type in the <var>Size</var> output argument. Returns true if it completed correctly.
Method Size(Filename As %String, ByRef Size As %Integer) As %Boolean
{
	Set Size=0
	If '..sendCommand("SIZE "_Filename) Quit 0
	Set Size=..ReturnMessage
	Quit 1
}

/// If the FTP server supports it then this will return a files modification time based on GMT
/// as a float value in the <var>Time</var> output argument. Returns true if it completed correctly.
Method MDTM(Filename As %String, ByRef Time As %Float) As %Boolean
{
	Set Time=0
	If '..sendCommand("MDTM "_Filename) Quit 0
	Set Time=..ReturnMessage
	Quit 1
}

/// Return the status of the Ftp server in the <var>Status</var> parameter which should
/// be passed by reference.
Method Status(ByRef Status As %String) As %Boolean
{
	Set Status=""
	If '..sendCommand("STAT") Quit 0
	Set Status=..ReturnMessage
	Quit 1
}

/// Store the data in <var>Stream</var> in the <var>Filename</var> on the Ftp server.
Method Store(Filename As %String, Stream As %AbstractStream) As %Boolean [ CodeMode = expression ]
{
..genericStore("STOR "_Filename,Stream,..TranslateTable)
}

/// Upload the files in <var>Directory</var> matching the set of <var>Wildcards</var> to the Server.
/// Multiple <var>Wildcards</var> can be passed. In this case, each wildcard must be separated by 
/// the <var>Delimiter</var>. The default <var>Delimiter</var> is ";". 
/// <method>StoreFiles</method> ignores subdirectories. 
/// All files will be uploaded using the current transfer mode (<property>Type</property>). This means
/// that binary and ASCII files cannot be uploaded together in a single call. If mixed file types are needed,
/// separate the upload into batches, for example:
/// <example>
/// If 'ftp.Ascii() Write "Can not swap to Ascii mode",! Quit
/// If 'ftp.StoreFiles("/myfiles","*.txt;*.csv") Write "Failed to store text files",! Quit
/// If 'ftp.Binary() Write "Failed to swap to Binary mode",! Quit
/// If 'ftp.StoreFiles("/myfiles","*.bin") Write "Failed to store binary files",! Quit
/// </example>
Method StoreFiles(Directory As %String, Wildcards As %String, Delimiter As %String = ";") As %Boolean
{
	Set FileSetStmt=##class(%SQL.Statement).%New()
	Set tSC = FileSetStmt.%PrepareClassQuery("%File","FileSet")
	If $$$ISERR(tSC) Quit 0
	
	Set FileSetRS = FileSetStmt.%Execute(Directory,Wildcards,,,Delimiter)
	If FileSetRS.%SQLCODE Quit 0 //No rows, or error
	
	While FileSetRS.%Next() {
		If FileSetRS.%Get("Type")'="F" Continue
		
		Set FullName = FileSetRS.%Get("Name")
		Set Name = ##class(%File).GetFilename(FullName)
		
		Set FileStream = ##class(%Stream.FileCharacter).%New()
		set FileStream.Filename = FullName
		set tSC = ..genericStore("STOR "_Name,FileStream,..TranslateTable)
		if 'tSC Return 0
	}
	Quit 1
}

/// Return information about the type of computer you are connected to in the
/// by reference parameter <var>System</var>.
Method System(ByRef System As %String) As %Boolean
{
	Do ..sendCommand("SYST")
	If $E(..ReturnCode)'=2 Set System="Unknown" Quit 0
	Set System=..ReturnMessage
	Quit 1
}

Method TypeGet() As %String [ CodeMode = expression ]
{
$S(..transferType=1:"Ascii",..transferType=2:"Binary",1:"Unknown")
}

Method error(ReturnCode As %Integer, ReturnMessage As %String) As %Integer [ Private ]
{
	If ..returnStatus() {
		Set ..ReturnCode=ReturnCode
		Set ..ReturnMessage=ReturnMessage
	}
	Quit ..returnStatus()
}

Method genericRetrieve(Command As %String, ByRef Stream As %AbstractStream, Table As %String = "", Retry As %Boolean = 0) As %Boolean [ Private ]
{
	Set ..ReturnCode=0,..ReturnMessage="",zerror=$zerror,sc=$$$OK,io=$IO
	Set first=1,errorcode=426,readtimeout=i%Timeout,transfertype=i%transferType,callback=..Callback,extra=""
	If '$isobject($get(Stream)) {
		If transfertype=1 { Set Stream=##class(%Stream.GlobalCharacter).%New() } Else { Set Stream=##class(%Stream.GlobalBinary).%New() }
	}
	
	If ..UsePASV {
		If '..setupPASV(.device,.server) Quit 0
	} Else {
		If '..setupPORT(.device,.server) Quit 0
	}
	
	#; Try to reset the transfer from where we left off
	If Retry {
		Set size=Stream.Size
		If size=-1 {
			#; Count the size of the stream on the basis that it is faster to do this than
			#; reget the whole thing
			Set size=0
			Do Stream.Rewind()
			For  Quit:Stream.AtEnd  Set size=size+$L(Stream.Read(,.sc)) If $$$ISERR(sc) Goto EndRetrieve
		}
		If '..sendCommand("REST "_size) {
			#; If server does not support this just read in the whole file again
			Set sc=Stream.Clear()
		} Else {
			#; Skip to the end of the stream ready to append data
			Set sc=Stream.MoveToEnd()
		}
	} Else {
		Set sc=Stream.Clear()
	}
	If $$$ISERR(sc) Goto EndRetrieve
	
	#; Request the transfer
	If '..sendCommand(Command)!($E(..ReturnCode)'=1) Close device Quit 0
	Use device
	If Table'="" Set oldtab = $$GetIO^%SYS.NLS()  Do SetIO^%SYS.NLS(Table)
	Set $ZTrap="EndRetrieve",$zerror=""
	If '..UsePASV Read dummy:readtimeout Else  Do:Table'="" SetIO^%SYS.NLS(oldtab) Close device Use io Set $zerror=zerror Quit ..error(529,"Timeout waiting for response")
	Do {
		Read data#1044992:readtimeout Set exit='$test,timeout=$za#4\2
		If first,data'="" {
			Set first=0
			If ..SSLCheckServerIdentity {
				Set sc=##class(%Net.HttpRequest).CheckSSLCN(server)
				If $$$ISERR(sc) Set errorcode=534 Goto EndRetrieve
			}
		}
		If transfertype=1,$$$isUNIX {
			If extra'="" Set data=extra_data,extra=""
			If $extract(data,*)=$char(13),'exit {
				Set tmp=$zstrip(data,">",$char(13)),extra=$extract(data,$length(tmp)+1,*),data=tmp
			}
			Set sc=Stream.Write($replace(data,$char(13,10),$char(10))) If $$$ISERR(sc) Goto EndRetrieve
		} Else {		
			Set sc=Stream.Write(data) If $$$ISERR(sc) Goto EndRetrieve
		}
		Do:$isobject(callback) callback.RetrieveCallback(Command)
	} While 'exit
	Set $ZTrap=""
	Do:Table'="" SetIO^%SYS.NLS(oldtab)
	Close device
	Use io
	Set $zerror=zerror
	Quit $select(timeout:..error(529,"Timeout waiting for response"),1:..readResponse())
EndRetrieve Set $ZTrap=""
	If Table'="",$get(oldtab)'="" Do SetIO^%SYS.NLS(oldtab)
	Close device
	Use io
	If $$$ISERR(sc) Set $zerror=zerror Quit ..error(errorcode,$$GetErrorText^%apiOBJ(sc))
	If $ZE'["<READ>" Set ..ReturnMessage="Caught error in 'genericRetrieve': "_$ZE,..ReturnCode=errorcode,$zerror=zerror Quit 0
	Set $zerror=zerror
	#; Make sure we write "" into the stream even if the file is zero sized
	If '$data(data) Set sc=Stream.Write("") If $$$ISERR(sc) Quit ..error(errorcode,$$GetErrorText^%apiOBJ(sc))
	Quit ..readResponse()
}

Method genericStore(Command As %String, Stream As %AbstractStream, Table As %String = "") As %Boolean [ Private ]
{
	Set ..ReturnCode=0,..ReturnMessage="",io=$IO,sc=$$$OK,zerror=$zerror
	Set first=1,errorcode=426,callback=..Callback,extra="",transfertype=i%transferType
	If ..UsePASV {
		If '..setupPASV(.device,.server) Quit 0
	} Else {
		If '..setupPORT(.device,.server) Quit 0
	}
	If '..sendCommand(Command)!($extract(..ReturnCode)'=1) Close device Quit 0
	Use device
	if Table'="" Set oldtab = $$GetIO^%SYS.NLS()  Do SetIO^%SYS.NLS(Table)
	Set $ZTrap="EndStore",$zerror=""
	Set sc=Stream.Rewind() If $$$ISERR(sc) Goto EndStore
	If '..UsePASV Read dummy:..Timeout Else  Do:Table'="" SetIO^%SYS.NLS(oldtab) Close device Use io Set $zerror=zerror Quit ..error(529,"Timeout waiting for response")
	While 'Stream.AtEnd {
		Set data=Stream.Read(1044992,.sc) If $$$ISERR(sc) Goto EndStore
		If transfertype=1,$$$isUNIX {
			If extra'="" Set data=extra_data,extra=""
			If $extract(data,*)=$char(13),'Stream.AtEnd {
				Set extra=$char(13),data=$extract(data,1,*-1)
			}
			Write $replace($replace(data,$char(13,10),$char(10)),$char(10),$char(13,10))
		} Else {
			Write data
		}
		If first {
			Set first=0
			If ..SSLCheckServerIdentity {
				Set sc=##class(%Net.HttpRequest).CheckSSLCN(server)
				If $$$ISERR(sc) Set errorcode=534 Goto EndStore
			}
		}
		Do:$isobject(callback) callback.StoreCallback(Command)
	}
	Set $ZTrap=""
	Do:Table'="" SetIO^%SYS.NLS(oldtab)
	Close device
	Use io
	Set $zerror=zerror
	Quit ..readResponse()
EndStore Set $ZTrap=""
	If Table'="",$get(oldtab)'="" Do SetIO^%SYS.NLS(oldtab)
	Close device
	Use io
	If $$$ISERR(sc) Set $zerror=zerror Quit ..error(errorcode,$$GetErrorText^%apiOBJ(sc))
	If $ZE'["<WRITE>" Set ..ReturnMessage="Caught error in 'genericStore': "_$ZE,..ReturnCode=errorcode,$zerror=zerror Quit 0
	Set $zerror=zerror
	Quit ..readResponse()
}

ClassMethod getPath(Path As %String) As %String [ Private ]
{
	If $extract(Path)="""" {
		Set output=""
		For i=2:1:$length(Path) {
			Set tmp=$extract(Path,i)
			If tmp="""" {
				If $extract(Path,i+1)'="""" Quit
				Set i=i+1,output=output_"""" Continue
			} Else {
				Set output=output_tmp
			}
		}
		Quit output
	} Else {
		Quit $piece(Path," ")
	}
}

Method readResponse(Quick As %Boolean = 0) As %Boolean [ Private ]
{
	Set io=$IO,timeout=$S(Quick:0,1:..Timeout),zerror=$zerror
	Set $Ztrap="ErrorResponse",$zerror=""
	Use ..device
	Read result:timeout Else  Use io Set $zerror=zerror If Quick { Quit 1 } Else { Quit ..error(529,"Timeout waiting for response") }
	Set returncode=$E(result,1,3)
	Set message=$E(result,5,*)
	#; Handle multiple line message, search for result code followed by space
	Set error=""
	If timeout=0 Set timeout=..Timeout
	If $E(result,4)="-" Do  If error'="" Use io Set $zerror=zerror Quit error
	. For  Do  Quit:$E(result,1,4)=(returncode_" ")  Quit:error'=""  Set message=message_$C(13,10)_$select($extract(result,1,4)=(returncode_"-"):$extract(result,5,*),1:result)
	. . Read result:timeout Else  Set error=..error(529,"Timeout waiting for response")
	. Set message=message_$C(13,10)_$E(result,5,*)
	Use io
	If returncode=421 Set ..Connected=0,..ServerName="" Close ..device
	Quit ..error(returncode,message)
ErrorResponse	Set $ztrap=""
	Set ..ReturnMessage="Caught error in 'readResponse': "_$ZE,..ReturnCode=426
	If $zerror["<READ>" Set ..Connected=0,..ServerName="" Close ..device
	Use io
	Set $zerror=zerror
	Quit 0
}

Method returnStatus() As %Boolean [ CodeMode = expression, Private ]
{
$extract(..ReturnCode)<4
}

/// Generic method to send a command to the ftp server and read the response. It returns true if the command
/// worked and false if there was an error status returned. See <property>ReturnStatus</property> for the returned
/// status and <property>ReturnMessage</property> for the returned message.
Method sendCommand(Command As %String, noread As %Boolean = 0) As %Boolean
{
	If '..Connected Quit ..error(530,"Not logged in, connect first")
	Set io=$IO
	Set $ztrap="errorCommand"
	
	Set ..ReturnCode=0,..ReturnMessage=""
	If 'noread {
		#; Check if there are any other messages waiting for us
		Do ..readResponse(1)
		#; If they are critical then stop here and report them
		If $extract(..ReturnCode)'=5,'..returnStatus() Quit 0
	}
	Use ..device
	Write $replace(Command,$char(13),$char(13,0)),!
	Use io
	Quit ..readResponse()
errorCommand	Set $ztrap=""
	Set ..ReturnMessage="Caught error in 'sendCommand': "_$ZE,..ReturnCode=426
	If $zerror["<WRITE>" Set ..Connected=0,..ServerName="" Close ..device
	Use io
	Quit 1
}

Method setupPASV(ByRef Device As %String, Output ServerName As %String) As %Boolean [ Private ]
{
	If '..Connected Quit ..error(530,"Not logged in, connect first")
	#; Switch to PASV mode and setup the connection
#;SML994+ ; send EPSV command for IPV6.
	If ..UseExtensions {
	    If '..sendCommand("EPSV") Quit 0
	    If ..ReturnCode'=229 Quit 0
	    #; Calculate the port and server from the returned message
	    Set port=$P($P(..ReturnMessage,"(",2),")")
	    Set Server=..ServerAddr
	    Set port=$P(port,"|",4)
	} Else {
	    If '..sendCommand("PASV") Quit 0
	    If ..ReturnCode'=227 Quit 0
	    #; Calculate the port and server from the returned message
	    Set port=$P($P(..ReturnMessage,"(",2),")")
	    Set Server=$TR($P(port,",",1,4),",",".")
	    Set port=$P(port,",",5)*256+$P(port,",",6)
	    If ..AutoDetectPrivate {
		    If ..AutoDetectPrivate=2||(..isPrivate(Server)&&('..isPrivate(..ServerAddr))) Set Server=..ServerName
	    }
	}
	Set ServerName=$select(Server=..ServerAddr:..ServerName,1:Server)
	Set Device=..GetDevice()
	If ..SSLConfiguration'="" {
		if (..SSLUseSessionResumption)&&('$$$IsOpenSSL10) {
			Set io=$io Use ..device
			Set sess=$System.Security.Users.SSLGetSession()
			Use io
		} Else {
			Set sess=""
		}
		Open Device:(Server:port:"S"::32768:32768:/TCPNOXY:/TLS=$select(..SSLCheckServerIdentity:..SSLConfiguration_"||"_ServerName_"|"_sess,1:..SSLConfiguration_"|||"_sess):/TCPSNDBUF=65536:/TCPRCVBUF=98304):..Timeout Else  Quit ..error(425,"Unable to open data connection to "_Server_" on port "_port_" SSLConfiguration "_..SSLConfiguration)
	} Else {
		Open Device:(Server:port:"S"::32768:32768:/TCPNOXY:/TCPSNDBUF=65536:/TCPRCVBUF=98304):..Timeout Else  Quit ..error(425,"Unable to open data connection to "_Server_" on port "_port)
	}
	Quit 1
}

/// Return true if this IPv4 address is a private address
ClassMethod isPrivate(address As %String) As %Boolean
{
	Set first=$piece(address,".")
	If first=10 Quit 1
	If first=172 {
		Set second=$piece(address,".",2)
		If second>15,second<32 Quit 1
	} ElseIf first=192,$piece(address,".",2)=168 {
		Quit 1
	}
	Quit 0
}

Method setupPORT(ByRef Device As %String, Output ServerName As %String) As %Boolean [ Private ]
{
	If '..Connected Quit ..error(530,"Not logged in, connect first")
	#; Switch to PORT mode and setup the connection
	Set Device=..GetDevice(),ServerName=..ServerName
	#; Open with port 0 which means OS assigns a port number and then lookup what OS assigned.
	If ..SSLConfiguration'="" {
		if (..SSLUseSessionResumption)&&('$$$IsOpenSSL10){
			Set io=$io Use ..device
			Set sess=$System.Security.Users.SSLGetSession()
			Use io
		} Else {
			Set sess=""
		}
		Open Device:(:0:"SA"::8192:8192:/TCPNOXY:/TLS=$select(..SSLCheckServerIdentity:..SSLConfiguration_"||"_ServerName_"|"_sess,1:..SSLConfiguration_"|||"_sess):/TCPSNDBUF=65536:/TCPRCVBUF=98304):0 Else  Quit ..error(425,"Unable to open listening data connection SSLConfiguration "_..SSLConfiguration)
	} Else {
		Open Device:(:0:"SA"::8192:8192:/TCPNOXY:/TCPSNDBUF=65536:/TCPRCVBUF=98304):0 Else  Quit ..error(425,"Unable to open listening data connection")
	}
	Set io=$IO
	Use ..device Set server=$$$GetTCPLocalIP(0) Use Device Set port=$system.TCPDevice.LocalPort() Use io
	If server[":"||..UseExtensions {
	    Set ftpPort="EPRT |2|"_server_"|"_port_"|"
	} Else {
	    Set ftpPort="PORT "_$translate(server,".",",")_","_(port\256)_","_(port#256)
	}
	If '..sendCommand(ftpPort) Quit 0
	Quit 1
}

Method setupIPV6() As %Boolean [ Private ]
{
	Set io=$IO
	Use ..device Set server=$$$GetTCPPeerIPText Use io
	Quit:server="" 0
	#; get Server IP so we could use it when sending EPSV command.
	Set ..ServerAddr=server
	#; When server IP address contains ":" then it must be an IPV6 address.
	Set ..IsIPV6=(server[":")
	If ..IsIPV6 Set ..UseExtensions=1
	Quit 1
}

ClassMethod GetDevice() As %String
{
	Set devices=","_$piece($view(-1,$job),"^",3)_","
	For  { Set dev="|TCP|"_($random(99999999)+1) If devices'[(","_dev_","),devices'[(","_dev_"*,") Quit }
	Quit dev
}

}
