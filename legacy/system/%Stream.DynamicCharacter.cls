/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syGluedef, %occStream, %PVA)

/// <class>%Stream.DynamicCharacter</class> character stream containing
/// the textual value of
/// an element of a <class>%DynamicAbstractObject</class>. It is
/// particularly useful for
/// holding the value of a <class>%DynamicAbstractObject</class> element
/// with a textual
/// value that would exceed the capacity of an ObjectScript string variable.
/// A <class>%Stream.DynamicCharacter</class> object is readonly and it
/// cannot be modified or saved.
/// But it can be copied to any other %Stream class object that does support
/// modification and saving.
/// <p>
/// One way to create a <class>%Stream.DynamicCharacter</class>
/// is by making a method call that
/// looks like dao.%Get(key,default,"stream") where <var>dao</var> is 
/// an object reference
/// to a subclass of <class>%DynamicAbstractObject</class>, and
/// where <var>key</var> is the key name
/// value of an element of a <class>%DynamicObject</class> or the index value of an
/// element of a <class>%DynamicArray</class>.  You can also get a
/// <class>%Stream.DynamicCharacter</class> object by calling the
/// %GetNext(.key,.value,.type) 
/// method in one of subclasses of the
/// <class>%Iterator.AbstractIterator</class> class.
/// 
Class %Stream.DynamicCharacter Extends %Stream.Object [ ClientDataType = CHARACTERSTREAM, OdbcType = LONGVARCHAR, System = 2 ]
{

/// Default length for a Read.
Parameter READLEN = 32000;

/// Default read length when buffering
Parameter BUFLEN = 32000;

Property DAOData [ Internal, ReadOnly ];

Property DAOPos As %Integer [ InitialExpression = 1, Private ];

Property DAOSize As %Integer [ Private ];

/// The line terminator we use for this stream.  It defaults to $CHAR(13,10),
/// CR/LF.  Maximum length is 10 characters.
Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$char(13,10)}, Transient ];

/// <property>Position</property> is a read-only property containing the
/// current character
/// position of the <class>%Stream.DynamicCharacter</class>.  The next
/// <method>Read</method> method call will
/// start reading at this character position.  Character position 1 is the
/// position of the first character in the stream.  When <var>Position</var>
/// contains the value 1 then the first <method>Read</method> (after
/// creation of the stream or
/// after execution of the <method>Rewind</method> method) has not yet
/// been executed.  After
/// the last character has been read then <var>Position</var> will again contain
/// the value 1.
/// 
Property Position As %Integer [ Calculated ];

/// <property>Size</property> is a read-only property containing the
/// current size of the <class>%Stream.DynamicCharacter</class> in characters
/// 
Property Size As %Integer [ Calculated ];

/// Implements Property <property>Position</property>
/// which contains
/// the current position within the data stream.
Method PositionGet() As %Integer [ CodeMode = expression ]
{
i%DAOPos
}

/// Implements Property <property>Size</property>
/// which contains
/// the current size of the data stream.
Method SizeGet() As %Integer [ CodeMode = expression ]
{
i%DAOSize
}

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Returns true if this is a "NULL" stream; that is, a stream which has never 
/// been written to and saved. This is used by the InterSystems IRIS ODBC
/// server.  But a <class>%Stream.DynamicCharacter</class> is never NULL, even if it only contains the
/// empty string.
Method IsNull() As %Boolean [ CodeMode = expression ]
{
..%IsNull()
}

/// Returns true if this is a "NULL" stream; that is, a stream which has never 
/// been written to and saved. This is used by the InterSystems IRIS ODBC
/// server.  But a <class>%Stream.DynamicCharacter</class> is never NULL,
/// even if it only contains the
/// empty string.
Method %IsNull() As %Boolean [ CodeMode = expression ]
{
0
}

Method %OnNew(initval) As %Status [ Private ]
{
	Set i%DAOData=initval
	Set i%DAOSize=initval.%Size()
	Do ..Rewind()
	Quit $$$OK
}

Method %LoadData(id As %String) As %Status [ Private ]
{
	#; Nothing to do with READONLY stream
	Quit $$$OK
}

Method %OnRollBack() As %Status [ Private ]
{
	#; Nothing to do with READONLY stream
	Quit $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private ]
{
	Quit $$$OK
}

ClassMethod %DeleteData(streamvalue As %String, concurrency As %Integer) As %Status [ Private ]
{
	Quit $$$OK
}

/// Returns the global reference used to lock the current stream object.
/// 
ClassMethod %GetLockReference(pLocation As %String(MAXLEN="") = "", pId As %String(MAXLEN="") = "") As %String(MAXLEN="") [ Private ]
{
	quit ""
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private ]
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

Method Read(ByRef len As %Integer = {..#READLEN}, ByRef sc As %Status) As %String
{
	Set sc=$$$OK
	If i%AtEnd { Set len=-1 Return "" }
	Set pos=i%DAOPos,size=i%DAOSize,maxlen=size-pos+1
	Try {
	    #; Special case read-off-end or zero-length-read or read-too-long
	    Set:len>maxlen len=maxlen
	    If len>0 {
		Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
		Set endpos=pos+len
		If endpos>size { Set i%AtEnd=1,len=size-pos+1,endpos=1 }
		Set i%DAOPos=endpos
		Return $zu(210,$$$PVSReadBuf,..DAOData,pos,len)
	    }
	    #; Zero length Read(); Do following assignments if we are at EOF
	    Set:pos>size i%AtEnd=1,i%DAOPos=1,len=-1
	    Return ""
	} Catch tException {
	    Set sc=tException.AsStatus(),i%DAOPos=pos,len=0,i%AtEnd=0
	    Return ""
	}
}

Method ReadLine(ByRef len As %Integer = {..#READLEN}, ByRef sc As %Status, ByRef eol As %Boolean) As %String
{
	Set sc=$$$OK,eol=0
	If i%AtEnd { Set len=-1 Return "" }
	#; Save DAOString Position for rollback after error signal
	Set pos=i%DAOPos,size=i%DAOSize,maxlen=size-pos+1
	Try {
	    Set terminator=i%LineTerminator,tlen=$Length(terminator)
	    #; Special case read-off-end or zero-length-read or read-too-long
	    Set:len>maxlen len=maxlen
	    if len>0 {
		Set:len>($$$MaxLocalLength-tlen) len=$$$MaxLocalLength-tlen
		Set found=$find($zu(210,$$$PVSReadBuf,..DAOData,pos,len+tlen),
				terminator)
		#; if found, skip the terminator characters
		If found {
		    Set eol=1
		    #; Position len just before terminator characters
		    Set len=found-tlen-1
		    #; Position stream just after terminator characters.
		    Set endpos=pos+found-1
		    #; If not at end of stream then done
		    If endpos'>size goto done
		} Else {
		    #; Not found--position stream just after block to be read
		    Set endpos=pos+len
		    #; If not at end of stream then done
		    If endpos'>size goto done
		    #; We are off the end of stream, reset len
		    Set len=size-pos+1
		}
		#; We are at end of stream
		Set endpos=1,i%AtEnd=1
done		Set i%DAOPos=endpos
		#; return ptr into string buf--no string move needed
		Return $zu(210,$$$PVSReadBuf,..DAOData,pos,len)
	    }
	    #; Zero length Read(); Do assignments if we are at EOF
	    Set:pos>size i%AtEnd=1,i%DAOPos=1,len=-1
	    Return ""
	} catch tException {
		Set sc=tException.AsStatus(),i%DAOPos=pos,len=0,i%AtEnd=0,eol=0
		Return ""
	}
}

/// This reads from the stream until it finds the
/// <property>LineTerminator</property> and returns a new 
/// <class>%Stream.TmpCharacter</class>
/// stream containing the characters in the line. If the stream does not contain
/// the line terminator then this can potentially be the
/// entire stream.
Method ReadLineIntoStream(ByRef sc As %Status) As %Stream.Object
{
	Set sc=$$$OK
	If i%AtEnd Quit ""
	Set stream=##class(%Stream.TmpCharacter).%New()
	#; Save DAOString Position for rollback after error signal
	Set pos=i%DAOPos,size=i%DAOSize,len=size-pos+1
	Try {
	    Set terminator=i%LineTerminator,tlen=$Length(terminator)
	    Set pos2=pos
	    #; Special case zero-length-read
	    If len>0 { For {
	        #; Loop filling buffers in 'stream' object
		#; See if we found terminator in/adjacent-to next buffer
		Set found=$find($zu(210,$$$PVSReadBuf,..DAOData,
				pos2,..#BUFLEN+tlen),
				    terminator)
		#; if found, skip the terminator characters and done
		If found {
		    #; Position len just before terminator characters
		    Set len=found-tlen-1
		    Set found=found+pos2-1
		    #; Position i%DAOPos just after terminator characters
		    If found>size { Set i%AtEnd=1,found=1 }
		    Set i%DAOPos=found
		    Do stream.Write($ZU(210,$$$PVSReadBuf,..DAOData,pos2,len))
		    Return stream
		}
		Do stream.Write($ZU(210,$$$PVSReadBuf,..DAOData,pos2,..#BUFLEN))
		Set len=len-..#BUFLEN
		If len'>0 {
		    #; If we read off end then we are done at EOF
		    Set i%AtEnd=1,i%DAOPos=1
		    Return stream
		}
		#; position to fill next buffer in 'stream' object
		Set pos2=pos2+..#BUFLEN
	    }}
	    #; There were no characters; Do assignments if we are at EOF
	    Set:pos>size i%AtEnd=1,i%DAOPos=1
	    #; Return empty stream
	    Return stream
	} catch tException {
		Set sc=tException.AsStatus(),i%DAOPos=pos,i%AtEnd=0
		Kill stream
		Return ""
	}
}

Method %LocationSet(val As %String) As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

/// <p>Not supported.  <class>%Stream.DynamicCharacter</class>
/// is readonly.
Method Write(data As %String = "") As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

/// <p>Not supported.  <class>%Stream.DynamicCharacter</class>
/// is readonly.
Method WriteLine(data As %String = "") As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

/// <p>Not supported.  <class>%Stream.DynamicCharacter</class>
/// is readonly.
Method MoveToEnd() As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

/// Move to this <var>position</var> in the stream. If this succeeds then return
/// true, else return false.
/// <p>
/// <method>MoveTo</method> with argument 1 is equivalent to a <method>Rewind</method>.
/// <method>MoveTo</method> with argument 1 will always succeed
/// and it will position the <class>%Stream.DynamicCharacter</class> at 
/// character position 1 even if the
/// <class>%Stream.DynamicCharacter</class> contains no characters.
/// Moving to position 1 (or earlier)
/// will be at the first character of the stream; position 2 will be at the
/// second character of the stream, etc.
Method MoveTo(position As %Integer) As %Boolean
{
	#; The position\1 truncates fractional part & removes negative exponent
	#; The position+1-1 forces positive decimal exponent to 0
	SET pos=+position\1+1-1
	If pos'>1 {
	    #; Even an empty DynamicCharacter can be positioned at the beginning
	    Set i%DAOPos=1,i%AtEnd=0
	    Return 1
	}
	If pos>i%DAOSize {
	    #; Fail if we position beyond EOF
	    Set i%DAOPos=1,i%AtEnd=1
	    Return 0
	}
	Set i%DAOPos=pos,i%AtEnd=0
	Return 1
}

Method Rewind() As %Status
{
	Set i%DAOPos=1,i%AtEnd=0
	Quit $$$OK
}

Method Flush() As %Status
{
	#; Nothing to do with READONLY stream
	Quit $$$OK
}

/// <p>Not supported.  <class>%Stream.DynamicCharacter</class>
/// is readonly.
Method CopyFrom(source As %Stream.Object) As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

/// Write out <var>len</var> characters of the stream to the current device
/// starting from the current position. If <var>len</var> is omitted
/// or set to -1 then the <method>OutputToDevice</method> method
/// will write out the entire stream starting at the beginning and then
/// rewind back to the beginning.  If <var>len</var>&gt0 and we are unable to
/// write <var>len</var>
/// characters because we reach the end of the stream then we will stop writing
/// and set the <property>AtEnd</property> property to 1.  Otherwise, we will leave
/// the stream positioned after the last character written to the device.
/// If parameter <var>len</var>
/// is passed by reference and if no error occurs then the number of
/// characters actually written to the output device will be assigned
/// to <var>len</var>.
/// If zero characters are written because we are already positioned at the end
/// of the stream then <var>len</var> will be assigned to -1.
/// If an error occurs while writing the device then <var>len</var> will be assigned
/// to -2, an error <type>%Status</type> value will be returned and the stream
/// will rollback to its original position.
Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set size=i%DAOSize,atend=i%AtEnd
	If len=0,'atend,size>0  Return $$$OK
	#; Save DAOString Position for rollback after error signal
	Set pos=i%DAOPos,maxlen=size-pos+1
	Try {
	    If len=-1 {
		#; Write out all of the DAOString
		For i=1:..#BUFLEN:size {
		    Write $ZU(210,$$$PVSReadBuf,..DAOData,i,..#BUFLEN)
		}
		// Return length of Write and Rewind stream
		Set len=size,i%DAOPos=1,i%AtEnd=0
		Return $$$OK
	    }
	    If atend {
		Set len=-1
		Return $$$OK
	    }
	    Set:len>maxlen len=maxlen
	    Set len2=len,pos2=pos
	    #; Special case zero-length-read
	    If len>0 { For {
	        #; Loop sending pointer to chars to Write command
		Write $ZU(210,$$$PVSReadBuf,..DAOData,pos2,
			  $Select(len2>..#BUFLEN:..#BUFLEN,1:len2))
		#; position to fill next buffer in 'stream' object
		Set pos2=pos2+..#BUFLEN
		Set len2=len2-..#BUFLEN
		If len2'>0 {
		    Set pos2=pos2+len2
		    Set:pos2>size i%AtEnd=1,pos2=1
		    Set i%DAOPos=pos2
		    Return $$$OK
		}
	    }}
	    #; There were no characters; Do assignments if we are at EOF
	    Set:pos>size i%AtEnd=1,i%DAOPos=1,len=-1
	    Return $$$OK
	} catch tException {
		Set sc=tException.AsStatus(),i%DAOPos=pos,i%AtEnd=atend,len=-2
		Return sc
	}
}

/// <p>Not supported.  <class>%Stream.DynamicCharacter</class>
/// is readonly.
Method Clear(permanent As %Boolean = 1) As %Status
{
	QUIT $$$ERROR($$$ClassIsReadOnly,..%ClassName(1))
}

Method %ObjectModified() As %Integer [ ServerOnly = 1 ]
{
	Quit 0
}

Method %IsModified() As %Integer
{
	Quit 0
}

ClassMethod %LogicalToStorage(val As %String) As %String [ Private ]
{
	Quit val
}

ClassMethod %StorageToLogical(val As %String) As %String [ Private ]
{
	Quit val
}

/// Callback for searchable stream
Method BuildValueArray(ByRef subvalue As %String) As %Status [ Private ]
{
	Quit $$$OK
}

}
