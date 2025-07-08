/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// API for data archiving <p>
/// Sample script that initiates a connection to an archive server
/// <example>
///    Set SessionOref = ##class(%Archive.Session).%New() 
///    Set SessionOref.Host = 123.45.6.78 // IP address of the archive server 
///    Set SessionOref.AuthFile = AuthFilePath // path of the .pea file (for Centera) 
///    Set Status = SessionOref.Connect() 
/// </example>
/// Once connected, here is a sample script that stores a content (cf. <class>%Archive.Content</class>):
/// <example>
///    // create a content object as source, whose handle is ContentOref (see %Archive.Content)
///    Set Status = SessionOref.Store(ContentOref, .ContentUID) 
/// </example>
/// After Store() returns successfully, you need to save the ContentUID value somewhere (say, in a database) for future retrieval purpose. <br>
/// Here is a sample script to retrieve the file from the archive server, using the ContentUID and open connection above: 
/// <example>
///    // create a content object as target, whose handle is ContentOref (see %Archive.Content)
///    Set Status = SessionOref.Retrieve(ContentOref, ContentUID) 
/// </example>
/// Limitations: <ul><li>
///   Only EMC Centera server is supported as an archive server </li><li>
///   The source of storing and the target of retrieval must be files </li><li>
///   Only one open connection per process. Attempt to open additional connections (whether to the same server as the existing connection or not) would get an error. </li><li>
///   Retrieving selected files from a content containing multiple files ("blobs") is not supported. </li></ul>
Class %Archive.Session Extends %RegisteredObject [ System = 4 ]
{

/// Type of the archive system (EMC Centera)
Parameter TYPE = "Centera";

/// Version of the API
Parameter VERSION = 0.1;

/// Connection information, a comma-delimited list of IP addresses <br>
/// For example, "10.2.3.4,10.6.7.8"
Property Host As %String;

/// The path of a Pool Entry Authorization file (*.pea)
Property AuthFile As %String;

/// An alternative to a PEA file is a pair of UserName and Password
Property UserName As %Library.Username;

Property Password As %String;

/// Name of the application, default to something like "Cache for Windows (x86-32)" (from $zv)
Property ApplicationName As %String;

/// Version of the application, default to something like "2008.2 (Build 366U)" (from $zv)
Property ApplicationVersion As %String;

/// The size of an internal C-Clip buffer in bytes. This value must be greater than 0.
/// The SDK default value is 16KB. The default value we use here is 64KB.
Property BufferSizeInKB As %Integer [ InitialExpression = 64, Private ];

/// The size of the prefetch buffer. This buffer is used to assist in determining the size of the blob. 
/// The SDK default size is 32 KB. The maximum size is 1 MB, which is the default value we use here.
Property PrefetchSizeInKB As %Integer(MAXVAL = 1024) [ InitialExpression = 1024, Private ];

/// The maximum data size, in bytes, for data to be embedded in the CDF instead of being stored as separate blobs.
/// The SDK default value is 0 bytes, meaning data is never embedded in the CDF. 
/// The maximum value is 102400 bytes (100 KB), which is the default value we use here.
/// The value for the embedded data threshold can be set to less than or equal to 102400 bytes.
Property EmbeddedDataThreshold As %Integer(MAXVAL = 102400) [ InitialExpression = 102400, Private ];

/// dllid = DLL ID
/// dllid(FuncName) = DLL Function ID
Property dllid As %Integer [ Internal, MultiDimensional, Private ];

/// Create a string based on AuthFile or UserName and Password.
/// The string will be part of the connection argument for opening the pool.
Method GetAuthorization() As %String [ Private ]
{
	If $g(i%AuthFile) ] "" Quit i%AuthFile
	Quit "name="_i%UserName_",secret="_i%Password
}

/// Connect to the server
Method Connect() As %Status
{
	s rc=..Register() i 'rc q rc
	Set Connection = ..Host_"?"_..GetAuthorization()
	/// Open pool using Connection info
	s funcid=..LookUpDLLFunc("Connect") i 'funcid q funcid ;error
	s rc=$zf(-5,..dllid,funcid,Connection) i rc<0 q $$$ERROR($$$ObjectScriptError, "Connect: "_..GetErrorDetail())
	/// set options based on properties
	s Status1=..SetEmbeddedDataThreshold() ;non-essential
	s Status2=..SetBufferSize() ;non-essential
	Quit $System.Status.AppendStatus(Status1,Status2)
}

/// Disconnect from the server
Method Disconnect() As %Status
{
	/// Close pool to free up resources
	s funcid=..LookUpDLLFunc("Disconnect") i 'funcid q funcid ;error
	s rc=$zf(-5,..dllid,funcid) i rc<0 q $$$ERROR($$$ObjectScriptError, "Connect: "_..GetErrorDetail())
	Quit $$$OK
}

/// Delete a content (C-Clip) by its UID (ContentAddress)
Method DeleteContent(ContentUID As %String) As %Status
{
	s funcid=..LookUpDLLFunc("ContentDelete") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,$g(ContentUID)) i rc<0 q $$$ERROR($$$ObjectScriptError, "Delete Content "_ContentUID_": "_..GetErrorDetail())
	Quit $$$OK
}

/// Test the existence of a content (C-Clip) by its UID (ContentAddress)
Method AccessContent(ContentUID As %String) As %Status
{
	s funcid=..LookUpDLLFunc("ContentAccess") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,$g(ContentUID)) i rc<0 q $$$ERROR($$$ObjectScriptError, "Access Content "_ContentUID_": "_..GetErrorDetail())
	Quit $$$OK
}

/// Load DLL
Method %OnNew() As %Status [ Private ]
{
	s $zt="ErrorOnNew"
	/// ApplicationName and ApplicationVersion are used to register the
	/// application with the archive server
	i $g(..ApplicationName)="" s ..ApplicationName=$System.Version.Format(2)
	i $g(..ApplicationVersion)="" s ..ApplicationVersion=$System.Version.Format(5)
	s dllpath=$zu(12,$g(^%SYS("bindir"))_$zcvt(..#TYPE,"L")_$s($zversion(1)=3:".so",1:".dll"))
	s ..dllid=$zf(-4,1,dllpath)
	i ..dllid'>0 q $$$ERROR($$$ObjectScriptError,"Load DLL "_dllpath) ;@FIXME@
	s Status=..CheckVersion() i Status q $$$OK
ErrorOnNew s $zt="" i $ze]"" d BACK^%ETN s Status=$$$ERROR($$$UnexpectedError, $ze),$ze=""
	d $System.Status.DisplayError(Status) ;@FIXME@ log to cconsole.log??
	q Status
}

/// Unload DLL
Method %OnClose() As %Status [ Private ]
{
	i $zf(-4,2,..dllid)
	q $$$OK
}

/// Store an entire content to server, commit and return a UID by reference
Method Store(ContentOref As %Archive.Content, ByRef ContentUID As %String) As %Status
{
	s Status=..Create(ContentOref) i 'Status q Status
	s $zt="Opened"
	s name="" 
	For  {
		Set value = ContentOref.Attribute.GetNext(.name) i name="" q
		Set Status = ..SetAttribute(name,value) i 'Status q
	}
	i 'Status d ..Close() q Status
	Set DataSourceID = "" 
	For  {
		Set DataSourceID = $Order(ContentOref.DataSource(DataSourceID)) Quit:'DataSourceID
		Set Status = ..Write(ContentOref.DataSource(DataSourceID,"Source"),ContentOref.DataSource(DataSourceID,"TagName")) Quit:$$$ISERR(Status)
	}
	/// if successful so far, commit writes to server here and get ContentUID
	i Status s Status=..Commit(.ContentUID) 
Opened s $zt="" i $ze]"" s Status=$$$ERROR($$$UnexpectedError, $ze),$ze=""
	d ..Close()
	Quit Status
}

/// Retrieve an entire content from server
Method Retrieve(ContentOref As %Archive.Content, ContentUID As %String) As %Status
{
	s Status=..Open(ContentOref, ContentUID) i 'Status q Status
	s $zt="Opened"
	Set DataSinkID = 0, DataSink = ContentOref.DataSink.GetAt(.DataSinkID) 
	For  {
		Set DataSink = ContentOref.DataSink.GetNext(.DataSinkID) Quit:'DataSinkID
		Set Status = ..ReadNext(DataSink) Quit:$$$ISERR(Status)
	}
Opened s $zt="" i $ze]"" s Status=$$$ERROR($$$UnexpectedError, $ze),$ze=""
	d ..Close()
	Quit Status
}

Method LookUpDLLFunc(FuncName) As %Integer [ Private ]
{
	i $g(..dllid(FuncName)) q ..dllid(FuncName)
	s funcid=$zf(-4,3,..dllid,FuncName)
	i funcid>0 s ..dllid(FuncName)=funcid q funcid
	q $$$ERROR($$$ObjectScriptError, "DLL Function "_FuncName)
}

Method CheckVersion() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("Version") i 'funcid q funcid ;error
	s dllver=$zf(-5,..dllid,funcid)
	i dllver\1>..#VERSION q $$$ERROR($$$ObjectScriptError,"DLL Version "_(dllver\1))
	s platform=$p(dllver,",",2),isuni=+platform ;u 0 w !,dllver," ",platform," ",isuni,!
	#; Unicode DLL should work on non-Unicode host, but not the other way around
	i $$$IsUnicode,'isuni q $$$ERROR($$$ObjectScriptError,"non-Unicode DLL on Unicode platform")
	#;i '$$$IsUnicode,isuni q $$$ERROR($$$ObjectScriptError,"Unicode DLL on non-Unicode platform")
	q $$$OK
}

Method Register() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("Register") i 'funcid q funcid ;error
	s rc=$zf(-5,..dllid,funcid,..ApplicationName,..ApplicationVersion) i rc'<0 q $$$OK
	q $$$ERROR($$$ObjectScriptError, "Register: "_..GetErrorDetail())
}

Method SetEmbeddedDataThreshold() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("GetSetEmbeddingThreshold") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,..EmbeddedDataThreshold) i rc'<0 q $$$OK
	q $$$ERROR($$$ObjectScriptError, "SetEmbeddedDataThreshold: "_..GetErrorDetail())
}

Method SetBufferSize() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("GetSetBufferSize") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,..BufferSizeInKB*1024) i rc'<0 q $$$OK
	q $$$ERROR($$$ObjectScriptError, "SetBufferSize: "_..GetErrorDetail())
}

Method GetErrorDetail() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("ErrorFull") q $s(funcid>0:$zf(-5,..dllid,funcid),1:"")
}

/// A name for the data is required and cannot be NULL
Method Write(DataSource As %String, TagName As %String) As %Status [ Private ]
{
	s Status = ..NewTag(TagName) i 'Status q Status
	// If DataSource is a %Stream.Object object, call WriteStream();
	// otherwise, call WriteFile(), assuming DataSource is a file path.
	If '$isobject(DataSource) Quit ..WriteFile(DataSource)
	If DataSource.%IsA("%Stream.Object") Quit ..WriteStream(DataSource)
	Quit 0 ;type of DataSource not supported
}

Method ReadNext(DataSink As %String) As %Status [ Private ]
{
	s Status = ..NextTag(.TagName) i 'Status q Status
	// If DataSink is a %Stream.Object object, call ReadStream();
	// otherwise, call ReadFile(), assuming DataSink is a file path.
	If '$isobject(DataSink) Quit ..ReadFile(DataSink)
	If DataSink.%IsA("%Stream.Object") Quit ..ReadStream(DataSink)
	Quit 0 ;type of DataSink not supported
}

/// Create a tag with a 'TagName' and stream the given file to the blob associated with the tag 
/// Acceptable characters for a TagName are ASCII characters in the Set [a-zA-Z0-9_-.]. [No restriction in Unicode version]
/// The first character must be a letter or an underscore "_".
/// The name must be XML compliant and cannot start with the prefix "xml" or "eclip".
/// May generate <WRITE> error
Method WriteFile(Path As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("TagStoreFile") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,Path) i rc<0 q $$$ERROR($$$ObjectScriptError, "Write File "_Path_": "_..GetErrorDetail())
	Quit $$$OK
}

/// Read the blob associated with the tag by the name 'TagName' to the file given by 'Path'
/// If TagName is not specified, use the current tag (either the first tag or the tag pointed to by GetNextTag())
/// If TagName is not unique in the content, use the first matching tag.
/// May generate <READ> error
Method ReadFile(Path As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("TagRetrieveFile") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,Path) i rc<0 q $$$ERROR($$$ObjectScriptError, "Read File "_Path_": "_..GetErrorDetail())
	Quit $$$OK
}

/// Similar to WriteFile, except that the data source is a %Stream object. NOT IMPLEMENTED.
Method WriteStream(StreamOref As %Stream, TagName As %String = "_") As %Status [ Private ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Similar to ReadFile, except that the data sink is a %Stream object. NOT IMPLEMENTED.
Method ReadStream(StreamOref As %Stream, TagName As %String) As %Status [ Private ]
{
	Quit $$$ERROR($$$NotImplemented)
}

Method Create(ContentOref As %Archive.Content) As %Status [ Private ]
{
	s retspec=ContentOref.RetentionSpec s $zt="ErrorCreate"
	i (retspec="")||(retspec?1.N) s retper=retspec ;retention period in seconds
	e  s retcls=retspec ;retention class name
	s funcid=..LookUpDLLFunc("ContentCreate") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,ContentOref.Name,$g(retper),$g(retcls)) i rc<0 q $$$ERROR($$$ObjectScriptError, "Create Content: "_..GetErrorDetail())
	q $$$OK
ErrorCreate s $zt="" d BACK^%ETN s Status=$$$ERROR($$$UnexpectedError,$ze),$ze="" q Status
}

Method Commit(ByRef ContentUID As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("ContentCommit") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid) i rc<0 q $$$ERROR($$$ObjectScriptError, "Commit Content: "_..GetErrorDetail())
	s ContentUID=$p(rc,",",2,$l(rc))
	q $$$OK
}

Method Open(ContentOref As %Archive.Content, ContentUID As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("ContentOpen") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,$g(ContentUID)) i rc<0 q $$$ERROR($$$ObjectScriptError, "Open Content "_ContentUID_": "_..GetErrorDetail())
	s ContentOref.RetentionSpec=$p(rc,",",2),ContentOref.Name=$p(rc,",",3,$l(rc))
	q $$$OK
}

Method Close() As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("ContentClose") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid) i rc<0 q $$$ERROR($$$ObjectScriptError, "Close Content: "_..GetErrorDetail())
	q $$$OK
}

Method SetAttribute(AttribName As %String, AttribValue As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("SetContentAttrib") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,AttribName,AttribValue) i rc<0 q $$$ERROR($$$ObjectScriptError, "Set Content Attribute "_AttribName_": "_..GetErrorDetail())
	q $$$OK
}

Method NewTag(Name) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("TagNew") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid,Name) i rc<0 q $$$ERROR($$$ObjectScriptError, "New Tag "_Name_": "_..GetErrorDetail())
	q $$$OK
}

Method NextTag(ByRef Name As %String) As %Status [ Private ]
{
	s funcid=..LookUpDLLFunc("TagNext") i funcid'>0 q funcid ;error
	s rc=$zf(-5,..dllid,funcid) i rc<0 q $$$ERROR($$$ObjectScriptError, "Next Tag: "_..GetErrorDetail())
	s Name=$p(rc,",",2,$l(rc))
	q $$$OK
}

}
