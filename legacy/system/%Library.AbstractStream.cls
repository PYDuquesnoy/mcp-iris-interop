/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated class, the base stream class is <class>%Stream.Object</class>. This is kept for legacy reasons.
/// <p>A stream represents an arbitrary array of characters (or bytes) and 
/// a current position. The basic stream interface provides the ability to 
/// read data from a stream, write data to the stream, and rewind the 
/// current position to the beginning of the stream.
/// 
/// <p>Within InterSystems IRIS streams are used to create large (greater than 32K)
/// object attributes.
Class %Library.AbstractStream Extends %Stream.Object [ Abstract, ClientDataType = CHARACTERSTREAM, Deprecated, MemberSuper = %Compiler.Type.StreamLegacy, System = 2 ]
{

/// The maximum number of characters (or bytes) allowed in a stream.
Parameter MAXLEN = 2147483647;

/// Turns off property validation.
Parameter PROPERTYVALIDATION As INTEGER [ Constraint = "0,1,2", Flags = ENUM ] = 0;

Parameter MAXLOCALSIZE = 32000;

Parameter READNODATA [ Final ] = 0;

Parameter READNOTCHANGED [ Final ] = 1;

Parameter READCHANGED [ Final ] = 2;

Parameter WRITE [ Final ] = 3;

/// An array of strings containing any attribute values associated with this stream.
Property Attributes As %String [ MultiDimensional ];

Property Mode As %Integer [ InitialExpression = 0, Private ];

/// Retrieves the named attribute value
Method GetAttribute(name As %String, default As %String = "") As %String [ CodeMode = expression, Final ]
{
$get(i%Attributes(name),default)
}

/// Inserts an attribute variable by name into the collection
Method SetAttribute(name As %String, value As %String) [ Final ]
{
	Set i%Attributes(name)=value
	If name="LineTerminator" Set i%LineTerminator=value
	Quit
}

/// Returns true if the named attribute variable exists in the collection, false otherwise
Method IsDefinedAttribute(name As %String) As %Boolean [ CodeMode = expression, Final ]
{
$data(i%Attributes(name))
}

/// Retrieves the next attribute variable name in the sequence, skip any '%' names
Method NextAttribute(name As %String) As %String [ Final ]
{
	Do {
		Set name=$order(i%Attributes(name))
	} While $extract(name)="%"
	Quit name
}

/// Removes this attribute variable from the collection. Returns true is it existed and false if it
/// did not exist.
Method DeleteAttribute(name As %String) As %Boolean [ Final ]
{
	If $data(i%Attributes(name)) Kill i%Attributes(name) Quit 1
	Quit 0
}

Method GetAttributeList() As %String
{
	Set name="",out=""
	For  Set name=$order(i%Attributes(name),1,data) Quit:name=""  If $extract(name)'="%" Set out=out_$listbuild($listbuild(name,data))
	Quit out
}

Method SetAttributeList(attr As %String)
{
	#; Get rid of any attributes we already have
	Kill i%Attributes
	Set ptr=0
	While $listnext(attr,ptr,val) {
		Set name=$listget(val),value=$listget(val,2)
		Set i%Attributes(name)=value
		If name="LineTerminator" Set i%LineTerminator=value
	}
}

/// Copies the contents of <i>source</i> into this Stream.
/// <p>For example, you can copy <var>oldstream</var> into a new stream:
/// <EXAMPLE>
/// Set newstream=##class(%GlobalCharacterStream).%New()
/// Do newstream.CopyFrom(oldstream)
/// </EXAMPLE>
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method CopyFrom(source As %Stream.Object) As %Status
{
	Quit:source=$$$NULLOREF $$$ERROR($$$OrefInvalid,"")
	
	Do source.Rewind()
	Set sc1=$$$OK,sc2=$$$OK
	If source.%Extends("%IO.I.Stream") {
		For  Quit:(source.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  Set sc1=..Write(source.Read(32656,,.sc2))
	} Else {
		For  Quit:(source.AtEnd)||($$$ISERR(sc1)||($$$ISERR(sc2)))  Set sc1=..Write(source.Read(32656,.sc2))
	}
	If $$$ISERR(sc1) Quit sc1
	If $$$ISERR(sc2) Quit sc2
	
	#; Now copy the attributes if this is a legacy stream type
	If source.%Extends("%Library.AbstractStream")||(source.%Extends("%CSP.Stream")) {
		Do ..SetAttributeList(source.GetAttributeList())
	}
	
	Quit $$$OK
}

/// Perform any initialization required by the StreamAdaptor. 
/// This is called by the containing stream's <b>%OnNew</b> method.
Method IOOnNew(initval As %String = "") As %Status [ Private ]
{
	Quit $$$OK
}

/// Initialize member variable used by the StreamAdaptor. This
/// This is called when the containing stream is opened via <b>%SetSerial</b>.
Method IOInit() [ Private ]
{
	Quit
}

/// Perform any clean up required by the StreamAdaptor. 
/// This is called by the containing stream's <b>%OnClose</b> method.
Method IOOnClose() As %Status [ Private ]
{
	if ..%Locked { do ..%UnlockStream(1) }
	Quit $$$OK
}

Method IORewind() As %Status [ Private ]
{
	Quit $$$OK
}

Method IOFlush() As %Status [ Private ]
{
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method IOGetSize() As %Integer [ Private ]
{
	Quit -1
}

/// Return the <i>id</i> for a stream; that is, an identifier that can later be used 
/// to open the same stream.
Method IOGetStreamId() As %String [ Private ]
{
	Quit ""
}

/// Open the stream identified by <var>sid</var>.
Method IOOpenStream(sid As %String) As %Status [ Private ]
{
	QUIT $$$ERROR($$$NotImplemented)
}

/// Write the stream to storage.
Method IOSaveStream() As %Status [ Private ]
{
	QUIT $$$ERROR($$$NotImplemented)
}

/// Delete the storage for the stream identified by <var>sid</var>.
ClassMethod IODeleteStream(sid As %String, concurrency As %Integer = 0) As %Status [ Private ]
{
	QUIT $$$ERROR($$$NotImplemented)
}

/// Reads up to <var>len</var> characters from the current position 
/// in the stream. The current position is advanced by the number of 
/// characers read. Upon exit, <var>len</var> is set to the actual 
/// number of characters read. If a read occurs when the stream position 
/// is at the end of the stream, <var>len</var> will be set to 0 and 
/// <METHOD>IOReadData</METHOD> will return a null string ("").
/// 
/// <p>Returns a string up to <var>len</var> characters long.
Method IOReadData(ByRef len As %Integer, ByRef sc As %Status) As %String [ Private ]
{
	Set len=0,sc=$$$OK
	Quit ""
}

/// Writes <var>data</var> to the stream at the current location.
Method IOWriteData(data As %String) As %Status [ Private ]
{
	QUIT $$$ERROR($$$NotImplemented)
}

/// Move to the end of the stream and set ourselves to #WRITE mode so the
/// next <METHOD>IOWriteData</METHOD> will append data to the stream.
Method IOMoveToEnd() As %Status [ Private ]
{
	QUIT $$$ERROR($$$NotImplemented)
}

Method %Load(sid As %String) As %Status [ CodeMode = call, Private ]
{
..%SetSerial(sid)
}

ClassMethod %DeleteData(soid As %String, concurrency As %Integer) As %Status [ CodeMode = call, Private ]
{
..DeleteStream(soid,concurrency)
}

Method %SaveData(ByRef sid As %String) As %Status [ Private ]
{
	Set status = ..SaveStream()
	Set sid = ..%Id()
	Quit status
}

Method %OnNew(initval As %String = "") As %Status [ CodeMode = call, Private ]
{
..IOOnNew(initval)
}

Method %OnClose() As %Status [ CodeMode = call, Private ]
{
..IOOnClose()
}

Method Rewind() As %Status [ CodeMode = call ]
{
..IORewind()
}

Method Flush() As %Status [ CodeMode = call ]
{
..IOFlush()
}

/// Returns an full id value (including class name) with which the Stream implementation has stored 
/// the stream.
Method GetStreamId() As %String
{
	Set id=..%GetSerial()
	Quit:(id="") ""
	Quit $LB(id,$select($extract($classname(),1,8)="%Library":"%"_$extract($classname(),10,*),1:$classname()))
}

Method OpenStream(sid As %String) As %Status [ CodeMode = call ]
{
..IOOpenStream(sid)
}

/// Returns true if this is a "NULL" stream; that is, a stream which has never 
/// been written to and saved. This is used by the InterSystems IRIS ODBC server.
Method IsNull() As %Boolean [ CodeMode = call ]
{
..%IsNull()
}

/// Returns true if this is a "NULL" stream; that is, a stream which has never 
/// been written to and saved. This is used by the InterSystems IRIS ODBC server.
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
(i%Mode=..#READNODATA&&('$data(i%Attributes)||(..NextAttribute("")="")))
}

/// Deprecated method, use <method>%Save</method> instead.
/// Saves the temporary copy of the stream data to a persistent location. Note that
/// any locking or transaction handling must be done by the caller.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method SaveStream() As %Status [ CodeMode = call, Deprecated ]
{
..IOSaveStream()
}

/// Deprecated method, use <method>%Delete</method> instead.
/// Deletes the stored stream identified by <var>oid</var>. This will not remove the stream attributes of any
/// saved streams, it will just remove the stream data. If you need to clear the attributes as well you will
/// have to call <METHOD>Clear</METHOD> on the stream object.
ClassMethod DeleteStream(oid As %ObjectIdentity, concurrency As %Integer = 0) As %Status [ CodeMode = generator, Deprecated ]
{
	Set %code=0
	
	#; Generate the method...
	$$$GENERATE(" QUIT:$g(oid)="""" $$$ERROR($$$NullOid,$classname()) Set id=$$$oidPrimary(oid) QUIT:id="""" $$$ERROR($$$NullId,$classname())")
	#; Handle new serialised format.
	$$$GENERATE(" If $A(id)=0 Set id=$LI($E(id,2,32760))")
	
	#; get class name; we assume that class name is present in oid
	$$$GENERATE(" Set class=$$$oidClassName(oid)")
	
	#; Must normalise the class name now we have packages
	$$$GENERATE(" If class'="""" s class=$$$NormalizeClassname(class)")
	
	#; See if we are the correct class. If not, dispatch polymorphically to correct DeleteStream()
	$$$GENERATE(" If class'="""",class'="""_%class_""" QUIT $classmethod(class,""DeleteStream"",oid)")
	
	$$$GENERATE(" QUIT ..IODeleteStream(id,concurrency)")
	
	QUIT $$$OK
}

Method %GetSerial(force As %Integer = 0) As %String [ CodeMode = call, Private ]
{
..%Id()
}

Method %SetSerial(serialized As %String) As %Status [ CodeMode = call, Private ]
{
..%LoadData(.serialized)
}

/// Returns the persistent object Id, if there is one, of this object. 
/// <p>Returns a null string if there is no object Id.
Method %Id() As %String
{
	#; If the stream is null return a null id
	Set attributes=$s('$d(i%Attributes):"",1:..GetAttributeList())
	If attributes="",i%Mode=..#READNODATA Quit ""
	Set streamid=..IOGetStreamId()
	If streamid="",attributes="" Quit ""
	#; Add the $C(0) so we can tell the difference between old and new serialised forms
	Quit $C(0)_$LB(streamid,attributes)
}

Method %LoadData(serialized As %String) As %Status [ Private ]
{
	#; intialize member variables
	Do ..IOInit()
	Set ..Id = "",sc=$$$OK
	#; New format of serialised state
	If serialized="" {
		Quit $$$ERROR($$$NullOid,$classname())
	} ElseIf $ascii(serialized)=0 {
		Set serialized=$E(serialized,2,*)
		If serialized '= "" {
			Set ..Id = $list(serialized)
			Do:$list(serialized,2)'="" ..SetAttributeList($list(serialized,2))
		}
	} ElseIf serialized '= "" {
		Set ..Id = serialized
	}
	Quit ..OpenStream(..Id)
}

Method SizeGet() As %Integer [ CodeMode = call ]
{
..IOGetSize()
}

/// Type of line terminator we use for this stream, defaults to Cr/Lf. Maximum length is 10 characters.
/// This is stored as an attribute of the stream called 'LineTerminator'.
Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$char(13,10)} ];

Method LineTerminatorSet(terminator As %String) As %Status
{
	Set i%Attributes("LineTerminator")=terminator,i%LineTerminator=terminator
	Quit $$$OK
}

Method Read(ByRef len As %Integer = 32656, ByRef sc As %Status) As %RawString [ CodeMode = call ]
{
..IOReadData(.len,.sc)
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %RawString
{
	Set sc=$$$OK,eol=0
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	Set data="",term=..LineTerminator
	Set getlen=$L(term)
	Set done=0
	For  Do  Quit:done
	#; Make sure we do not read too much
	. If $L(data)+getlen>len Set getlen=len-$L(data)
	. Set readlen=getlen
	. Set data=data_..Read(.getlen)
	#; Reached the end of the stream so report what we have, we have not found terminator as this
	#; would require reading in readlen characters
	. If readlen'=getlen Set done=1 Quit
	
	. For charno=$L(term):-1:0 If $E(term,1,charno)=$E(data,$L(data)-charno+1,$L(data)) Quit
	
	#; We have found the terminator, return the string minus this terminator
	. If charno=$L(term) Set data=$E(data,1,$L(data)-charno),done=1,eol=1 Quit
	
	#; If we have read all the character the user wants us to so exit
	. If $L(data)=len Set done=1 Quit
	
	. Set getlen=$L(term)-charno
	Set len=$S((..AtEnd=1)&($L(data)=0):-1,1:$L(data))
	Quit data
}

/// This reads from the stream until it find the <property>LineTerminator</property> and returns
/// this as a stream. If the stream does not contain the line terminator this can potentially be the
/// entire stream.
Method ReadLineIntoStream() As %AbstractStream
{
	Set stream=..%New()
	Set data="",term=..LineTerminator
	Set getlen=$length(term)
	Set done=0
	For  Do  Quit:done
	. Set readlen=getlen
	. Set data=data_..Read(.getlen)
	#; Reached the end of the stream so report what we have, we have not found terminator as this
	#; would require reading in readlen characters
	. If readlen'=getlen Set done=1 Quit
	
	. For charno=$L(term):-1:0 If $E(term,1,charno)=$E(data,$L(data)-charno+1,$L(data)) Quit
	
	#; We have found the terminator, return the string minus this terminator
	. If charno=$L(term) Set data=$E(data,1,$L(data)-charno),done=1 Quit
	. Set getlen=$L(term)-charno
	. If $length(data)+$length(term)>32000 Do stream.Write($extract(data,1,$length(data)-$length(term)+1)) Set data=$extract(data,$length(data)-$length(term)+2,*)
	Do:data'="" stream.Write(data)
	Quit stream
}

Method Write(data As %RawString = "") As %Status [ CodeMode = call ]
{
..IOWriteData(data)
}

/// Appends the string <var>data</var> along with a line terminator to the stream and advances the 
/// current stream position by the number of characters in <var>data</var> plus the line terminator.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method WriteLine(data As %RawString = "") As %Status
{
	If $length(data)+$length(..LineTerminator)>$$$MaxLocalLength {
		Set sc=..Write(data)
		If $$$ISOK(sc) Set sc=..Write(..LineTerminator)
	} Else {
		Set sc=..Write(data_..LineTerminator)
	}
	Quit sc
}

Method MoveToEnd() As %Status [ CodeMode = call ]
{
..IOMoveToEnd()
}

Method %IsModified() As %Integer
{
	Quit $select(m%Attributes:1,1:$case(i%Mode,..#READNOTCHANGED:0,..#READNODATA:0,:1))
}

Method %ObjectModified() As %Integer
{
	Quit $select(m%Attributes:1,1:$case(i%Mode,..#READNOTCHANGED:0,..#READNODATA:0,:1))
}

}
