/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occStream

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.TmpCharacter">Working with Streams</a>.</p>
/// Temporary character stream. Any calls to save this just return without doing any work.
Class %Stream.TmpCharacter Extends %Stream.Object [ ClientDataType = CHARACTERSTREAM, OdbcType = LONGVARCHAR, System = 2 ]
{

Property Mode As %Integer [ InitialExpression = 0, Private ];

/// Number of characters that we are storing in each global node
Parameter BUFFERLEN = 163280;

/// Where we write the temp data to
Property TempGbl As %String [ Private, Transient ];

/// Maximum subscript in data we are reading
Property MaxNodeNo As %Integer [ InitialExpression = 0, Private, Transient ];

/// The current node we are reading from
Property NodeNo As %String(MAXLEN = 5000) [ InitialExpression = 0, Private, Transient ];

/// Buffer we are currently using read from stream global
Property Buffer As %Binary(MAXLEN = "") [ Private, Transient ];

/// Internal - used for sharded streams
Property shardid As %String [ Internal, Private ];

Property rollback As %String [ MultiDimensional, Private ];

/// Where we are currently in the <property>Buffer</property>
Property Position As %Integer [ InitialExpression = 1, Private, Transient ];

/// Internal size of stream
Property IOSize As %Integer [ InitialExpression = 0, Private ];

/// Internal flag to determine if the steam data is compressed
Property Compress As %Integer [ InitialExpression = {..#COMPRESS}, Private, Transient ];

/// Compress behavior of this class.<br>
/// <br><ul>
/// <li>-1 - Do not compress streams, write old stream header format</li>
/// <li>0  - Do not compress new streams</li>
/// <li>1  - Compress new streams</li>
/// <li>2  - Always compress</li>
/// </ul>
Parameter COMPRESS = 0;

/// Type of line terminator we use for this stream, defaults to Cr/Lf. Maximum length is 10 characters.
Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$char(13,10)}, Transient ];

/// If true then remove the permanent global as well as any temp global when this object is closed
/// If you call %Save on a stream where RemoveOnClose is true it will set this to false as if you
/// explicitly save the stream you no longer want it to be removed when the object is closed. In order
/// to make sure %Save always runs the logic to reset the flag setting this to true 
/// causes %IsModified/%ObjectModified to return true.
Property RemoveOnClose As %Boolean [ InitialExpression = 0, Transient ];

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

Property mLastModified As %String [ Private, Transient ];

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
..Mode=$$$modeREADNODATA
}

Method LastModifiedGet() As %TimeStamp [ CodeMode = expression, Final ]
{
$zdt($select(i%mLastModified="":$ZTimeStamp,1:i%mLastModified),3)
}

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	Set i%%Location=$select(initval="":$$$streamGlobal,1:initval)
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	If i%RemoveOnClose,i%Id'="",$data(@i%%Location@(i%Id)) Kill ^(i%Id)
	If i%TempGbl'="" {
		If $data(@i%TempGbl) Kill @i%TempGbl
		If '$$$streamTmpGlobalDefault,i%%Concurrency {
			Set lockref = ..%GetLockReference(i%%Location,i%Id)
			If lockref'="" lock -@(lockref)#"I"
		}
		Set i%TempGbl=""
	}
	If i%%Locked { Do ..%UnlockStream(1) }
	Quit $$$OK
}

Method %LoadData(id As %String) As %Status [ Private ]
{
	Set i%%Location=$$$streamGlobal
	$$$streamInitTmpGlobal
}

Method %OnRollBack() As %Status [ Private ]
{
	If $data(i%rollback) {
		Set i%Buffer=i%rollback("Buffer"),i%Mode=i%rollback("Mode"),i%MaxNodeNo=i%rollback("MaxNodeNo")
		Set batch=$zu(68,25,1),journal=$zu(139,2)
		If i%TempGbl="" {
			$$$streamInitTmpGlobal
		} Else {
			Kill @i%TempGbl
		}
		For i=1:1:i%MaxNodeNo Set @i%TempGbl@(i)=@i%%Location@(i%Id,i)
		Kill i%rollback
		Do $zu(68,25,batch),$zu(139,journal)
	}
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

/// Returns the global reference used to lock the current stream object
/// Throws %Exception.AbstractException
ClassMethod %GetLockReference(pLocation As %String(MAXLEN="") = "", pId As %String(MAXLEN="") = "") As %String(MAXLEN="") [ Private ]
{
	if (pId '= "") && (pLocation '= "") { quit $na(@pLocation@(pId)) }
	quit ""
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private ]
{
	set mode=i%Mode
	if mode=$$$modeREADNODATA { RETURN $$$OK }
	try {
		set i%TempGbl="",i%Id="",i%%Locked=0,concurrency=i%%Concurrency,i%%Concurrency=0
		if ((mode=$$$modeREADNOTCHANGED)||(mode=$$$modeWRITEJUSTSAVED)) {
			set glv=$na(@(object.%Location)@(object.Id))
			if mode=$$$modeWRITEJUSTSAVED { set i%MaxNodeNo=+$get(@glv) }
		} else {
			set glv = object.TempGbl
		}
		if glv'="",i%MaxNodeNo>0 {
			if ($ll(object."%%OID")=4) { set i%shardid=object.Id }
			do ..SetupTmpGbl()
			set batch=$zu(68,25,1),journal=$zu(139,2)
			for i=1:1:i%MaxNodeNo { set @i%TempGbl@(i)=@glv@(i) }
			do $zu(68,25,batch),$zu(139,journal)
		}
		if (mode=$$$modeREADNOTCHANGED)||(mode=$$$modeWRITEJUSTSAVED) { set i%Mode=$$$modeREADCHANGED }
		set tStatus = $$$OK
	} catch tExceptionOuter {
		set tStatus = tExceptionOuter.AsStatus()
	}
	set i%%Concurrency=concurrency
	RETURN tStatus
}

Method Read(ByRef len As %Integer, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK,haslen=$data(len)#10,out=""
	Set mode=i%Mode
	If mode=$$$modeREADNODATA Set i%AtEnd=1,len=-1 Quit ""
	#; Mode $$$modeWRITE: in middle of Write with no rewind; automatically rewind
	If mode=$$$modeWRITE||(mode=$$$modeWRITEJUSTSAVED) Set sc=..Rewind() If $$$ISERR(sc) Quit ""
	If i%AtEnd Set len=-1 Quit ""
	
	If 'haslen||(len>$$$MaxLocalLength) Set len=$$$MaxLocalLength
	try {
		#; try to read from i%Buffer
		Set done=0
		For {
			#; do we need to read another chunk from global
			If i%Position>$length(i%Buffer),..ReadIntoBuffer()=0 Quit
			Set needed=len-$length(out)
			If i%Position=1,needed'<$length(i%Buffer) {
				Set out=out_i%Buffer
			} Else {
				Set out=out_$extract(i%Buffer,i%Position,i%Position+needed-1)
			}
			Set i%Position=i%Position+needed
			If ('haslen&&(out'=""))||($length(out)'<len) Quit
		}
		#; Fill the buffer here so we can set AtEnd flag without another round trip
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
	
		#;if we are at the end with no data return -1
		Set len=$select((i%AtEnd=1)&($length(out)=0):-1,1:$length(out))
	} catch tException {
		set sc = tException.AsStatus()
		RETURN $g(out)	// out may be <UNDEFINED> if the error was <STORE>
	}
	Quit out
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %RawString
{
	Set sc=$$$OK,eol=0
	Set mode=i%Mode
	If mode=$$$modeREADNODATA Set i%AtEnd=1,len=-1 Quit ""
		
	#; Mode $$$modeWRITE: in middle of Write with no rewind; automatically rewind
	If mode=$$$modeWRITE||(mode=$$$modeWRITEJUSTSAVED) Set sc=..Rewind() If $$$ISERR(sc) Quit ""
	If i%AtEnd Set len=-1 Quit ""
	#; try to read from i%Buffer
	Set done=0,out="",terminator=..LineTerminator
	#; Leave space to add the terminator at the end of the buffer
	Set:len>($$$MaxLocalLength-$length(terminator)) len=$$$MaxLocalLength-$length(terminator)
	try {
		For {
			#; do we need to read another chunk from global
			If i%Position>$length(i%Buffer),..ReadIntoBuffer()=0 Quit
			If out="" {
				Set found=$find(i%Buffer,terminator,i%Position)
				If found,found-i%Position'>(len+$length(terminator)) {
					Set out=$extract(i%Buffer,i%Position,found-$length(terminator)-1)
					Set i%Position=found
					Set eol=1
					Quit
				} Else {
					Set out=$extract(i%Buffer,i%Position,i%Position+len-1)
					Set i%Position=i%Position+len
					If $length(out)'<len Quit
				}
			} Else {
				#; Need to allow for the line terminator to be at the end of the current read section
				Set needed=len-$length(out),out=out_$extract(i%Buffer,i%Position,i%Position+needed-1+$length(terminator))
				Set found=$find(out,terminator)
				If found {
					#; Set the current position just after the terminator, set the output to the text just before the terminator
					#; (len-needed) give me the previous length of 'out' before we appended more data to it.
					Set i%Position=i%Position+found-1-(len-needed)
					Set out=$extract(out,1,found-$length(terminator)-1)
					Set eol=1
					Quit
				} Else {
					Set i%Position=i%Position+needed
					If $length(out)'<len Quit
				}
			}
		}
		#; See if we are at the end to avoid a round trip
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
	} catch tException {
		Set sc=tException.AsStatus()
		Return ""
	}
	#;if we are at the end with no data return -1
	If i%AtEnd=1,out="" {
		Set len=-1
		Return ""
	} ElseIf $length(out)>len {
		Return $extract(out,1,len)
	} Else {
		Set len=$length(out)
		Return out
	}
}

/// This reads from the stream until it find the <property>LineTerminator</property> and returns
/// this as a stream. If the stream does not contain the line terminator this can potentially be the
/// entire stream.
Method ReadLineIntoStream(ByRef sc As %Status) As %Stream.Object
{
	Set sc=$$$OK
	If i%AtEnd Quit ""
	Set stream=..%New(),mode=i%Mode
	If mode=$$$modeREADNODATA Set i%AtEnd=1 Quit stream
	
	#; Mode $$$modeWRITE: in middle of Write with no rewind; automatically rewind
	If mode=$$$modeWRITE||(mode=$$$modeWRITEJUSTSAVED) Set sc=..Rewind() If $$$ISERR(sc) Quit ""

	#; try to read from i%Buffer
	Set done=0,out="",terminator=..LineTerminator
	try {
		For  Do  Quit:done
		#; do we need to read another chunk from global
		. If i%Position>$L(i%Buffer),..ReadIntoBuffer()=0 Set done=1 Quit
		#; Need to allow for the line terminator to be at the end of the current read section
		. Set needed=$$$MaxStringLength-$L(out),out=out_$E(i%Buffer,i%Position,i%Position+needed-1+$L(terminator))
		. Set found=$F(out,terminator)
		. If found Do  Quit
		#; Set the current position just after the terminator, set the output to the text just before the terminator
		#; (len-needed) give me the previous length of 'out' before we appended more data to it.
		. . Set i%Position=i%Position+found-1-($$$MaxStringLength-needed)
		. . Set out=$E(out,1,found-$L(terminator)-1)
		. . Set done=1
		. Set i%Position=i%Position+needed
		. Do stream.Write($extract(out,1,*-$length(terminator)+1)) Set out=$extract(out,*-$length(terminator)+2,*)
		#; See if we are at the end to avoid a round trip
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
		Do:out'="" stream.Write(out)
	} catch tException {
		set sc = tException.AsStatus()
	}
	Quit stream
}

Method Write(data As %RawString = "") As %Status
{
	#; Mode = $$$modeREADNODATA,$$$modeREADNOTCHANGED: set up for write, rewind
	Set mode=i%Mode
	If mode'=$$$modeWRITE {
		If mode=$$$modeWRITEJUSTSAVED {
			Set sc=..MoveToEnd() If $$$ISERR(sc) Quit sc
		} Else {
			If mode'=$$$modeREADNODATA,i%TempGbl'="" {
				Set batch=$zu(68,25,1),journal=$zu(139,2)
				Kill @i%TempGbl
				Do $zu(68,25,batch),$zu(139,journal)
			}
			Set i%Mode=$$$modeWRITE,i%IOSize=0,i%MaxNodeNo=0,i%NodeNo=0,i%Buffer="",i%Position=1
		}
	}
	
	#; a write is never at the end
	Set datalen=$length(data),i%AtEnd=0,i%IOSize=i%IOSize+datalen,i%mLastModified=$ZTimeStamp
	
	#; if it fits, append data to Buffer
	Set bufferlen=+..#BUFFERLEN
	Set bufneed=bufferlen-$Length(i%Buffer)
	If bufneed>datalen {
		Set i%Buffer=i%Buffer_data
	} Else {
		#; otherwise store Buffer to global
		If i%TempGbl="" Do ..SetupTmpGbl()
		Set batch=$zu(68,25,1),journal=$zu(139,2)
		#; Optimize for this case where i%Buffer="" and we are writing whole buffer as avoiding $extract on arg stack is faster
		If bufneed=bufferlen,bufneed=datalen {
			#; On first block write see if this is compressible
			If i%MaxNodeNo=0,i%Compress=1,..NotCompressible(.data) Set i%Compress=0
			$$$streamWriteCompressData(data,i%TempGbl)
		} Else {
			#; On first block write see if this is compressible (does not use more than 4k of write so only pass this much
			If i%MaxNodeNo=0,i%Compress=1,..NotCompressible($extract(i%Buffer_$extract(data,1,bufneed),1,4096)) Set i%Compress=0
			$$$streamWriteCompressData(i%Buffer_$extract(data,1,bufneed),i%TempGbl)
			#; Write subsequent blocks
			While datalen-bufneed'<bufferlen {
				Set @i%TempGbl@($increment(i%MaxNodeNo))=$$$streamCompressBuf($extract(data,bufneed+1,bufneed+bufferlen)),bufneed=bufneed+bufferlen
			}
		}
		Set i%Buffer=$extract(data,bufneed+1,*)
		Do $zu(68,25,batch),$zu(139,journal)
	}
	Quit $$$OK
}

/// Setup the TempGbl location of where we will write the temp stream to
Method SetupTmpGbl() [ Private ]
{
	$$$streamInitTmpGlobal
	Set i%%Location="^||%IRIS.StreamTmp"
}

/// Appends the string <var>data</var> along with a line terminator to the stream and advances the 
/// current stream position by the number of characters in <var>data</var> plus the line terminator.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method WriteLine(data As %RawString = "") As %Status
{
	Set term=..LineTerminator
	If $length(data)+$length(term)>$$$MaxLocalLength {
		Set sc=..Write(data)
		If $$$ISOK(sc) Set sc=..Write(term)
	} Else {
		Set sc=..Write(data_term)
	}
	Quit sc
}

Method MoveToEnd() As %Status
{
	#; If no data or in write mode already nothing to do
	Set mode=i%Mode
	If (mode=$$$modeREADNODATA)||(mode=$$$modeWRITE) Quit $$$OK
	
	#; Copy the permanent data into temporary structure ready for appending
	If mode=$$$modeREADNOTCHANGED||(mode=$$$modeWRITEJUSTSAVED) {
		Set batch=$zu(68,25,1),journal=$zu(139,2)
		If i%TempGbl="" $$$streamInitTmpGlobal
		Set tempgbl=i%TempGbl,location=i%%Location,id=i%Id
		If $data(@location) {
			If mode=$$$modeWRITEJUSTSAVED Set i%MaxNodeNo=+$get(@location@(id))
			For i=1:1:i%MaxNodeNo-1 Set @tempgbl@(i)=@location@(id,i)
			If i%MaxNodeNo>0 {
				Set i%Buffer=$$$streamDecompressBuf(@location@(id,i%MaxNodeNo))
				Set i%MaxNodeNo=i%MaxNodeNo-1
			} Else {
				Set i%Buffer=""
			}
		}
		Do $zu(68,25,batch),$zu(139,journal)
	} ElseIf mode'=$$$modeREADBUFFER {
		Set i%Buffer=""
	}
	#; a write is never at the end
	Set i%Mode=$$$modeWRITE,i%AtEnd=0
	
	Quit $$$OK
}

Method Rewind() As %Status
{
	Set mode=i%Mode
	If mode=$$$modeWRITEJUSTSAVED {
		Set i%MaxNodeNo=+$get(@i%%Location@(i%Id))
		Set i%NodeNo=0,i%Buffer="",i%Mode=$$$modeREADNOTCHANGED
	} ElseIf mode=$$$modeWRITE {
		#; If we have not written anything yet we can keep the data in the buffer
		If i%TempGbl'="" {
			If i%Buffer'="" Set sc=..Flush() If $$$ISERR(sc) Quit sc
			Set i%NodeNo=0,i%Buffer="",i%Mode=$$$modeREADCHANGED
		} Else {
			Set i%Mode=$$$modeREADBUFFER
		}
	} ElseIf mode'=$$$modeREADBUFFER {
		Set i%NodeNo=0,i%Buffer=""
	}
	Set i%Position=1,i%AtEnd=$select(i%Mode=$$$modeREADNODATA:1,1:0)
	Quit $$$OK
}

Method Flush() As %Status
{
	If i%Mode'=$$$modeWRITE Quit $$$OK
	If i%Buffer="" Quit $$$OK
	If i%TempGbl="" Do ..SetupTmpGbl()
	#; If we have not written any blocks so far see if it is compressible
	If i%Compress=1,i%MaxNodeNo=0,..NotCompressible() Set i%Compress=0
	#; Turn on batch mode so writing stream does not kill the cache
	Set batch=$zu(68,25,1),journal=$zu(139,2)
	Set chunklen=+..#BUFFERLEN
	While i%Buffer'="" {
		#; Move to next node, write data
		Set buflen=$length(i%Buffer)
		If buflen<=chunklen {
			$$$streamWriteCompressData(i%Buffer,i%TempGbl)
		} Else {
			$$$streamWriteCompressData($extract(i%Buffer,1,chunklen),i%TempGbl)
		}
		Set i%Buffer=$extract(i%Buffer,chunklen+1,*)
	}
	Do $zu(68,25,batch),$zu(139,journal)
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method SizeGet() As %Integer [ CodeMode = expression ]
{
i%IOSize
}

/// Check if we are at the end of the global, but do not read the next buffer
Method CheckAtEnd() [ Private ]
{
	#; Are we at the end
	If i%NodeNo'<i%MaxNodeNo {
		Set i%AtEnd=1,i%NodeNo=0
		Do:i%%Locked ..%UnlockStream(1)
	}
}

/// Reads the next node into Buffer.
/// <p>Returns 0 if there is no more data.
Method ReadIntoBuffer() As %Boolean [ Private ]
{
	#; Are we at the end
	If i%NodeNo'<i%MaxNodeNo {
		Set i%AtEnd=1,i%NodeNo=0
		Do:i%%Locked ..%UnlockStream(1)
		Quit 0
	}
	Set i%Position=1
	#; Turn on batch mode so reading stream does not kill the cache
	Set batch=$zu(68,25,1)
	If i%Mode=$$$modeREADNOTCHANGED {
		If ('i%%Locked) && (i%%Concurrency) { Do ..%LockStream() }
		Set i%Buffer=$$$streamDecompressBuf(@i%%Location@(i%Id,$increment(i%NodeNo)))
	} Else {
		Set i%Buffer=$$$streamDecompressBuf(@i%TempGbl@($increment(i%NodeNo)))
	}
	Do:batch=0 $zu(68,25,0)
	Quit 1
}

Method CopyFrom(source As %Stream.Object) As %Status
{
	Quit:source=$$$NULLOREF $$$ERROR($$$OrefInvalid,"")
	Set sc=$$$OK
	#; Optimise for copy from one global to another
	If $classname(source)=$classname() {
		Set mode=source.Mode
		Set sourceGlvn=$S(mode=$$$modeREADCHANGED||(mode=$$$modeWRITE):source.TempGbl,mode=$$$modeREADNODATA||(mode=$$$modeREADBUFFER):"",1:$na(@(source.%Location)@(source.Id)))
		If mode=$$$modeWRITEJUSTSAVED {
			Set sourcemaxnodeno=+$get(@sourceGlvn)
		} Else {
			Set sourcemaxnodeno=source.MaxNodeNo
		}
		#; Update the last modified timestamp
		Set i%mLastModified=$ZTimeStamp
		If i%Mode=$$$modeWRITEJUSTSAVED {
			Set sc=..MoveToEnd() If $$$ISERR(sc) Quit sc
		}
		If i%Mode'=$$$modeWRITE {
			Set i%Compress=source.Compress  ; As we are replacing data we can copy over source compression flag and directly copy global
			#; Copy the data and setup the properties
			Set i%MaxNodeNo=sourcemaxnodeno
			Set tempgbl=i%TempGbl
			#; clear temp to prepare for write to same location as last write
			If tempgbl="" {
				If sourcemaxnodeno>0 Do ..SetupTmpGbl() Set tempgbl=i%TempGbl
				Set batch=$zu(68,25,1),journal=$zu(139,2)
			} Else {
				Set batch=$zu(68,25,1),journal=$zu(139,2)
				If $data(@tempgbl) Kill @tempgbl
			}
			Try {
				For i=1:1:sourcemaxnodeno Set @tempgbl@(i)=@sourceGlvn@(i)
			} Catch exception {
				Do $zu(68,25,batch),$zu(139,journal)
				Throw exception
			}
			Do $zu(68,25,batch),$zu(139,journal)
			Set i%Mode=$$$modeWRITE,i%IOSize=source.Size
			Set i%Buffer=$select(mode=$$$modeREADNOTCHANGED||(mode=$$$modeREADCHANGED):"",1:source.Buffer)
		} Else {
			#; Else we can blast through the global which is faster than the generic
			#; copy mechanism, and add the new information to the end of the current data.
			Set buffer=i%Buffer,maxnodeno=+i%MaxNodeNo
			Set tempgbl=i%TempGbl
			Set bufferlen=+..#BUFFERLEN,compress=i%Compress,sourcecompress=source.Compress
			Set batch=$zu(68,25,1),journal=$zu(139,2)
			Try {
				For i=1:1:sourcemaxnodeno,0 {
					If i=0 {
						Set data=$select(mode=$$$modeREADNOTCHANGED||(mode=$$$modeREADCHANGED):"",1:source.Buffer)
					} Else {
						Set i%Compress=sourcecompress,data=$$$streamDecompressBuf(@sourceGlvn@(i)),i%Compress=compress
					}
					Set datalen=$length(data)
					If $length(buffer)+datalen<bufferlen {
						Set buffer=buffer_data
					} Else {
						#; otherwise store Buffer to global
						If tempgbl="" {
							Do ..SetupTmpGbl() Set tempgbl=i%TempGbl
						}
						#; If first block write see if this is compressible
						If maxnodeno=0,compress=1,..NotCompressible(.buffer) Set i%Compress=0,compress=0
						#; If buffer big enough on its own to write a chunk output these
						Set currpos=1
						While $length(buffer)-currpos+1>=bufferlen {
							Set @tempgbl@($increment(maxnodeno))=$$$streamCompressBuf($extract(buffer,currpos,currpos+bufferlen-1)),currpos=currpos+bufferlen
						}
						If currpos'=1 Set buffer=$extract(buffer,currpos,*)
						If buffer="" {
							Set currpos=bufferlen
							If datalen=bufferlen {
								Set @tempgbl@($increment(maxnodeno))=$$$streamCompressBuf(data)
							} Else {
								Set @tempgbl@($increment(maxnodeno))=$$$streamCompressBuf($extract(data,1,bufferlen))
							}
						} Else {
							Set currpos=bufferlen-$length(buffer)
							Set @tempgbl@($increment(maxnodeno))=$$$streamCompressBuf(buffer_$extract(data,1,currpos))
						}
						While datalen-currpos>=bufferlen {
							Set @tempgbl@($increment(maxnodeno))=$$$streamCompressBuf($extract(data,currpos+1,currpos+bufferlen)),currpos=currpos+bufferlen
						}
						Set buffer=$extract(data,currpos+1,*)
					}
				}
			} Catch exception {
				Do $zu(68,25,batch),$zu(139,journal)
				Throw exception
			}
			Do $zu(68,25,batch),$zu(139,journal)
			Set i%IOSize=i%IOSize+source.Size,i%Buffer=buffer,i%MaxNodeNo=maxnodeno
		}
	} Else {
		#; Else use the generic copy mechanism
		Set sc=##class(%Stream.Object)$this.CopyFrom(source)
	}

	If $$$ISERR(sc) Quit sc

	#; Now copy the LineTerminator attribute
	If source.%Extends("%Stream.GlobalCharacter") || source.%Extends("%Library.AbstractStream") || source.%Extends("%IO.IParts.LineIO") || (source.%Extends("%CSP.Stream")) {
		Set ..LineTerminator=source.LineTerminator
	}

	Quit sc
}

Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set $Ztrap="OutputError"
	If (i%Mode=$$$modeREADNODATA) Set i%AtEnd=1,len=-1 Quit $$$OK
	If len=0 Quit $$$OK
	Set sc=$$$OK
	try {
		If len=-1||((i%Position=1)&&(i%NodeNo=0)&&(len>=i%IOSize)) {
			#; Note that Rewind turns off WRITE mode so we do not need to test for this
			Do ..Rewind()
			If i%MaxNodeNo {
				#; Turn on batch mode so reading stream does not kill the cache
				Set batch=$zu(68,25,1)
				Set glvn=$S(i%Mode=$$$modeREADCHANGED:i%TempGbl,i%Mode=$$$modeREADNOTCHANGED:$na(@i%%Location@(i%Id)))
				Write $$$streamDecompressBuf(@glvn@(1))
				For i=2:1:i%MaxNodeNo Write $$$streamDecompressBuf(^(i))
				Do:batch=0 $zu(68,25,0)
			}
			If i%Mode=$$$modeREADBUFFER Write i%Buffer
			If len'=-1 Set i%AtEnd=1
			Set len=i%IOSize
	
		#; Else write out just part of the global
		} Else {
			#; Mode $$$modeWRITE: in middle of Write with no rewind; automatically rewind
			If i%Mode=$$$modeWRITE||(i%Mode=$$$modeWRITEJUSTSAVED) Do ..Rewind()
			Set written=0
			#; If they only want less than in the current buffer so give it to them
			If len<($L(i%Buffer)-i%Position+2) {
				Write $E(i%Buffer,i%Position,i%Position+len-1)
				Set i%Position=i%Position+len
				Set written=len
			} ElseIf i%Mode=$$$modeREADBUFFER {
				Write $extract(i%Buffer,i%Position,*)
				Set i%Position=$length(i%Buffer)+1,i%AtEnd=1
			#; Else they want more than in the buffer
			} Else {
				#; Output the buffer to start with
				Write $E(i%Buffer,i%Position,*)
				Set written=written+$L(i%Buffer)-i%Position+1

				Set glvn=$S(i%Mode=$$$modeREADCHANGED:i%TempGbl,i%Mode=$$$modeREADNOTCHANGED:$na(@i%%Location@(i%Id)))
				Set node=i%NodeNo
				#; Turn on batch mode so reading stream does not kill the cache
				Set batch=$zu(68,25,1)
				For  Set node=$O(@glvn@(node),1,data) Quit:node=""  Set data=$$$streamDecompressBuf(data) Quit:written+$L(data)>len  Write data Set written=written+$L(data)
				Do:batch=0 $zu(68,25,0)
				Set i%NodeNo=$S(node="":0,1:node)

				#; End of stream
				If node="" {
					Set i%AtEnd=1,i%Buffer="",i%Position=1
				} Else {
					#; Now write out the final data
					Write $extract(data,1,len-written)
					Set i%Buffer=data
					Set i%Position=len-written+1
					Set written=len
				}
			}
			#; Check if we are at the end
			If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()

			#;if we are at the end with no data return -1
			Set len=$S((i%AtEnd=1)&(written=0):-1,1:written)
		}
	} catch tException {
		set sc = tException.AsStatus()
	}
	Quit sc
OutputError	Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

Method Clear(permanent As %Boolean = 1) As %Status
{
	If i%Mode=$$$modeREADNODATA Quit $$$OK
	Set i%mLastModified=$ZTimeStamp
	Set batch=$zu(68,25,1),journal=$zu(139,2)
	If i%TempGbl'="" {
		If $data(@i%TempGbl) Kill @i%TempGbl
		If '$$$streamTmpGlobalDefault,i%%Concurrency {
			Set tLockRef = ..%GetLockReference(i%%Location,i%Id)
			lock -@(tLockRef)#"I"
		}
		Set i%TempGbl=""
	}
	Do $zu(139,journal)
	If permanent {
		if i%Id'="" {
			If $data(@i%%Location@(i%Id)) Kill ^(i%Id)
			Set i%Id=""
		}
		if $g(i%shardid)'="" {
			if $data(@i%%Location@(i%shardid)) { kill ^(i%shardid) }
			set i%shardid=""
		}
		Set i%Mode=$$$modeREADNODATA,i%MaxNodeNo=0
		Set i%"%%OID"=..%Oid()
	} Else {
		Set i%Mode=$$$modeREADNOTCHANGED,maxnode=0
		If i%Id'="",$data(@i%%Location@(i%Id),maxnode)#10=0 Set maxnode=$order(^(i%Id,""),-1)
		Set i%MaxNodeNo=+maxnode
	}
	Set i%Buffer="",i%Position=1,i%NodeNo=0,i%IOSize=0,i%AtEnd=1
	Do $zu(68,25,batch)
	Quit $$$OK
}

ClassMethod %Exists(soid As %ObjectIdentity) As %Boolean
{
	set location=$$$oidSysAd1(soid)
	set shardnum=$$$oidSysAd2(soid)
	set:$ascii(location)=0 location=$list($extract(location,2,*))
	if location="" { set location=$$$streamGlobal }
	else {
		set:'$d($system.Context.SQL().ShardNumber($namespace)) $system.Context.SQL().ShardNumber($namespace)=$$getNSShardNumber^%SYS.SHARDSRV()
		if shardnum,shardnum'=$system.Context.SQL().ShardNumber($namespace) { set location="^|"""_$$getExtRefEnvFromShardNum^%SYS.SHARDSRV(shardnum)_"""|"_$e(location,2,*) }
	}
	set loctmp=$$$oidPrimary(soid)
	if (location="")||(loctmp="") { RETURN 0 }
	RETURN ''$data(@location@(loctmp))
}

Method %ObjectModified() As %Integer [ ServerOnly = 1 ]
{
	Quit $select(i%RemoveOnClose:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

Method %IsModified() As %Integer
{
	Quit $select(i%RemoveOnClose:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

/// Callback for searchable stream
Method BuildValueArray(ByRef subvalue As %String) As %Status [ Private ]
{
	Quit $$$OK
}

ClassMethod %ObjectIsNull(soid As %ObjectIdentity) As %Boolean
{
	RETURN:soid=$$$NULLOID 1
	RETURN:$isobject(soid)=1 soid.%IsNull()
	set class=$$$oidClassName(soid)
	if class'="" {
		set class=$$$NormalizeClassname(class)
		if $classname()'=class { RETURN $classmethod(class,"%ObjectIsNull",soid) }
	}
	RETURN '..%Exists(soid)
}

/// Return true if this i%Buffer/data looks like it is not compressible.
/// Check for small buffer, known prefixes of compressed data and check a small segment of the buffer for compressibility
Method NotCompressible(data As %String) As %Boolean [ Internal, Private ]
{
	Set len=$select($data(data):$length(data),1:$length(i%Buffer))
	#; Only compress when first block is at least 1k
	If len<1024 RETURN 1
	Set buf=$select($data(data):$extract(data,1,10),1:$extract(i%Buffer,1,10))
	#; Lots of formats at https://www.garykessler.net/library/file_sigs.html
	#; If we wish to add a lot more patterns we can optimize how it searches, for now simple linear scan is fine
	If $extract(buf,1,2)=$c(255,216) RETURN 1 ; jpeg
	If $extract(buf,1,4)=$c(80,75,3,4) RETURN 1  ; zip
	If $extract(buf,1,3)=$c(31,139,8) RETURN 1  ; gzip
	If $extract(buf,1,6)=$c(253,55,122,88,90,0) RETURN 1 ; xz
	If $extract(buf,1,2)=$c(31,157)||($extract(buf,1,2)=$c(31,160)) RETURN 1  ; compressed TAR
	If buf=$c(0,0,0,12,106,80,32,32,13,10) RETURN 1  ; jpeg2000
	If $extract(buf,1,4)=$c(0,0,1,183)||($extract(buf,1,4)=$c(0,0,1,185))||($extract(buf)=$c(255)&&($ascii(buf,2)>=224)) RETURN 1 ; mpeg
	If $extract(buf,1,6)=$c(55,122,188,175,39,28) RETURN 1 ; 7z
	If $extract(buf,1,3)=$c(66,90,104) RETURN 1 ; BZ2
	If $extract(buf,1,6)=$c(71,73,70,56,55,97)||($extract(buf,1,6)=$c(71,73,70,56,57,97)) RETURN 1 ; gif
	If $extract(buf,1,3)=$c(73,68,51) RETURN 1 ; mp3
	If $extract(buf,1,6)=$c(74,65,82,67,83,0)||($extract(buf,1,8)=$c(80,75,3,4,20,0,8,0))||($extract(buf,1,4)=$c(95,39,168,137)) RETURN 1 ; jar
	If $extract(buf,1,4)=$c(80,75,7,8)||($extract(buf,1,4)=$c(80,75,5,6)) RETURN 1 ; pkzip
	If $extract(buf,1,4)=$c(82,73,70,70) RETURN 1 ; avi
	If $extract(buf,1,6)=$c(82,97,114,33,26,7) RETURN 1 ; rar
	If $extract(buf,5,8)=$c(102,116,121,112) RETURN 1 ; mp4
	If $extract(buf,5,10)=$c(102,116,121,112,113,116)||($extract(buf,5,8)=$c(109,111,111,118)) RETURN 1 ; mov
	#; Try compressing first 4k, if this does not get a good compression ratio (85% or less) with zstd skip compression (we switched from lz4 as it was not compressing base64 encoded data)
	If $length($System.Util.Compress($select($data(data):$extract(data,1,4096),1:$extract(i%Buffer,1,4096)),"zstd"))/$select(len>4096:4096,1:len)>0.85 RETURN 1
	RETURN 0
}

}
