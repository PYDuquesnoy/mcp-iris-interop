/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occStream

/// Stream adaptor for streams that store data in global nodes. Not to be used directly.
Class %Library.GlobalStreamAdaptor Extends %AbstractStream [ Abstract, System = 2 ]
{

Parameter STORAGE = "GLOBAL";

/// Number of characters that we are storing in each global node
Parameter BUFFERLEN = 163280;

/// Default location: can be overridden at run-time
Parameter STOREGLOBALNAME = "^CacheStream";

/// Root is Global Location (name and top subscripts)
Property StoreRoot As %String(MAXLEN = 5000) [ InitialExpression = {..#STOREGLOBALNAME}, Private ];

Property rollback As %String [ MultiDimensional, Private ];

Method %LocationSet(value As %String) As %Status
{
	Do ..Clear()
	Set i%StoreRoot=value,i%%Location=value
	Quit $$$OK
}

Method %LocationGet() As %String [ CodeMode = expression ]
{
i%StoreRoot
}

Property StoreNode As %String(MAXLEN = 5000) [ Private ];

Property TempNode As %String(MAXLEN = 5000) [ Private ];

/// Maximum subscript in data we are reading
Property MaxNodeNo As %Integer [ InitialExpression = 0, Private, Transient ];

/// The current node we are reading from.
Property NodeNo As %String(MAXLEN = 5000) [ InitialExpression = 0, Private ];

/// StoreGlvn is actual location where data is stored: StoreRoot + StoreNode
Property StoreGlvn As %String(MAXLEN = 5000) [ Calculated, Private ];

Method StoreGlvnGet() As %String [ CodeMode = expression, Private ]
{
$name(@(i%StoreRoot)@(i%StoreNode))
}

/// TempGlvn is actual temp location: TEMPGLOBALNAME + TempNode
Property TempGlvn As %String(MAXLEN = 5000) [ Calculated, Private ];

Method TempGlvnGet() As %String [ CodeMode = expression, Private ]
{
$name(^||%IRIS.Stream(i%TempNode))
}

Property Buffer As %Binary(MAXLEN = "") [ Private ];

Property Position As %Integer [ InitialExpression = 1, Private ];

Property IOSize As %Integer [ InitialExpression = 0, Private ];

Property %LastModified As %String [ Private, Transient ];

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	Set i%AtEnd=0
	#; pass storeroot via %New()
	Set:initval'="" i%StoreRoot=initval
	Do ..AttributesSetModified(0)
	Quit $$$OK
}

Method IOInit() [ Private ]
{
	Set i%AtEnd=0,i%Mode=0,i%StoreNode="",i%TempNode="",i%NodeNo=0,i%MaxNodeNo=0,i%Buffer="",i%Position=1,i%StoreRoot=..#STOREGLOBALNAME,i%IOSize=0,i%LineTerminator=$c(13,10)
	Quit
}

Method %OnClose() As %Status [ Private ]
{
	#; Mode = ..#READCHANGED or ..#WRITE: Kill new data
	If (i%Mode=..#READCHANGED)||(i%Mode=..#WRITE),i%TempNode'="" Kill ^||%IRIS.Stream(i%TempNode)
	if i%%Locked { do ..%UnlockStream(1) }
	Quit $$$OK
}

/// Returns the global reference used to lock the current stream object
/// Throws %Exception.AbstractException
ClassMethod %GetLockReference(pLocation As %String(MAXLEN="") = "", pId As %String(MAXLEN="") = "") As %String(MAXLEN="") [ Private ]
{
	if (pId '= "") && (pLocation '= "") { quit $na(@(pLocation)@(pId)) }
	quit ""
}

/// %LockStream()
/// 	Obtain a shared lock on the current stream object. The return value is 1 if
/// 		the stream was already locked or if it was successfully locked. If the stream
/// 		cannot be locked the return value is 0.
/// 		This version of %LockStream differs from %Stream.Object only in the arguments passed
/// 		to %GetLockReference.
Method %LockStream() [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	if ('i%%Locked) {
		try {
			set tLockRef = ..%GetLockReference(i%StoreRoot,i%StoreNode)
			if tLockRef '= "" {
				lock +@(tLockRef)#"S":$$$LockTimeout if $test { set i%%Locked = 1, i%%LockRef = tLockRef } else { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LockFailedToAcquireRead)) }
			}
		}
		catch tException {
			do ..%UnlockStream(1)
			throw tException
		}
	}
	quit
}

Method Rewind() As %Status
{
	If i%Mode=..#WRITE Do ..WriteBuffer() Set i%Mode=..#READCHANGED
	Set i%NodeNo=0,i%Position=1,i%Buffer="",i%AtEnd=0
	Set:i%Mode=..#READNODATA i%AtEnd=1
	Quit $$$OK
}

Method Flush() As %Status
{
	#; If i%Mode=..#WRITE Save Data in i%Buffer; don't change mode
	If i%Mode=..#WRITE Do ..WriteBuffer()
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method SizeGet() As %Integer [ CodeMode = expression ]
{
i%IOSize
}

Method IOGetStreamId() As %String [ CodeMode = expression, Private ]
{
$select(..Mode=..#READNODATA:"",i%StoreNode="":"",1:$listbuild(i%StoreRoot,i%StoreNode))
}

Method OpenStream(sid As %String) As %Status
{
	#; Mode = ..#READCHANGED or ..#WRITE: Kill new data
	If (i%Mode=..#READCHANGED)||(i%Mode=..#WRITE) Kill ^||%IRIS.Stream(i%TempNode)
	
	#; sid contains stream id to open
	#; stream id is $LB(location,node)
	
	Set i%StoreRoot=$LG(sid,1),i%StoreNode=$LG(sid,2)
	If i%StoreRoot="" Set i%StoreRoot=..#STOREGLOBALNAME
	Set i%Buffer="",i%Position=1
	
	If i%StoreNode="" {
		Set i%Mode=..#READNODATA,i%AtEnd=1,i%IOSize=0,i%MaxNodeNo=0
	} Else {
		if ('i%%Locked) && (i%%Concurrency) { do ..%LockStream() }
		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25) Do:batch=0 $zu(68,25,1)
		Set maxnode="",size=0
		If $data(@(i%StoreRoot)@(i%StoreNode),maxnode)=10 Set maxnode=$order(^(i%StoreNode,""),-1)
		#; read size from "0" node, if present, if not calculate it
		If maxnode'="",'$data(@(i%StoreRoot)@(i%StoreNode,0),size) {
			Set size=0 For i=1:1:maxnode Set size=size+$length(^(i))
		}
		Set i%IOSize=size,i%AtEnd='size,i%Mode=$select(maxnode="":..#READNODATA,1:..#READNOTCHANGED),i%MaxNodeNo=+maxnode
		Do:batch=0 $zu(68,25,0)
	}
	Quit $$$OK
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set location=..%Location
	Set i%%Locked=0,concurrency=i%%Concurrency,i%%Concurrency=0
	Do ..IOInit()
	If location'="" Set i%StoreRoot=location,i%%Location=location
	Do:'object.%IsNull() ..CopyFrom(object)
	Set i%%Concurrency=concurrency
	Quit $$$OK
}

Method %OnRollBack() As %Status [ Private ]
{
	If $data(i%rollback) {
		Set i%Buffer=i%rollback("Buffer"),i%Mode=i%rollback("Mode"),i%TempNode=i%rollback("TempNode"),i%MaxNodeNo=i%rollback("MaxNodeNo")
		If i%TempNode="" {
			Set i%TempNode=$Increment(^||%IRIS.Stream)
		} Else {
			Kill ^||%IRIS.Stream(i%TempNode)
		}
		For i=1:1:i%MaxNodeNo Set ^||%IRIS.Stream(i%TempNode,i)=@(i%StoreRoot)@(i%StoreNode,i)
		Kill i%rollback
	}
	Quit $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set status = ..SaveStream()
	Set sid = ..IOGetStreamId()
	Quit status
}

Method SaveStream() As %Status
{
	#; save the stream;
	If i%Mode=..#READNODATA||(i%Mode=..#READNOTCHANGED) Quit $$$OK
	
	try {
		#; Before changing anything we need to remember what the current state is in case of a rollback
		Kill i%rollback Set i%rollback("Buffer")=i%Buffer,i%rollback("Mode")=i%Mode,i%rollback("TempNode")=i%TempNode,i%rollback("MaxNodeNo")=i%MaxNodeNo
		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25) Do:batch=0 $zu(68,25,1)
		set tLocked = 0
		#; allocate new stream no if needed
		If i%StoreNode="" Set i%StoreNode=$increment(@(i%StoreRoot))
		if i%%Concurrency {
			set tLockRef = ..%GetLockReference(i%StoreRoot,i%StoreNode)
			if tLockRef '= "" {
				lock +@(tLockRef):$$$LockTimeout if $test { set tLocked = 1, i%%LockRef = tLockRef } else { set tLocked = 0 throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LockFailedToAcquireExclusive,tLockRef)) }
			}
		}
		If i%Mode=..#WRITE { Set buffer=i%Buffer } Else { Set buffer="" }
		Set bufferlen=..#BUFFERLEN
		If bufferlen["," Set bufferlen=+$piece(bufferlen,",",2)
		#; kill original data and save size in "0" node
		Set oldmaxnode=i%MaxNodeNo,maxnodeno=i%MaxNodeNo+($length(buffer)+bufferlen-1\bufferlen)
		Kill @(i%StoreRoot)@(i%StoreNode) Set ^(i%StoreNode)=maxnodeno,^(i%StoreNode,0)=i%IOSize
		For i=1:1:i%MaxNodeNo Set @(i%StoreRoot)@(i%StoreNode,i)=^||%IRIS.Stream(i%TempNode,i)
		
		#; If in WRITE mode have to write out buffer
		While buffer'="" {
			#; Do not want to update i%MaxNodeNo as for this stream type we keep the temp stream location even after a %Save
			Set @(i%StoreRoot)@(i%StoreNode,$increment(oldmaxnode))=$extract(buffer,1,bufferlen)
			Set buffer=$extract(buffer,bufferlen+1,*)
		}

		if tLocked { lock -@(tLockRef)#"I" }
		Do:batch=0 $zu(68,25,0)
		set tStatus = $$$OK
	}
	catch tException {
		if $Get(tLocked) { lock -@(tLockRef)#"I" }
		set tStatus = tException.AsStatus()
	}
	Quit tStatus
}

ClassMethod IODeleteStream(sid As %String, concurrency As %Integer = 0) As %Status [ Private ]
{
	#; kill the stream object in store global
	#; recreate glvn for stream
	Set root=$LG(sid,1) If root="" Set root=..#STOREGLOBALNAME
	Set node=$LG(sid,2) If node="" Quit $$$OK
	set tLocked = 0
	if concurrency {
		set tLockRef = ..%GetLockReference(root,node)
		if tLockRef '= "" {
			lock +@(tLockRef):$$$LockTimeout if $test { set tLocked = 1 } else { quit $$$ERROR($$$LockFailedToAcquireExclusive,tLockRef) }
		}
	} else {
		set tLocked = 0
	}
	Kill @root@(node)
	if tLocked { lock -@(tLockRef)#"I" }

	Quit $$$OK
}

Method Read(ByRef len As %Integer, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK,haslen=$data(len)#10
	#; Mode ..#READNODATA: no data 
	If (i%Mode=..#READNODATA)||(i%AtEnd=1),i%Mode'=..#WRITE Set i%AtEnd=1,len=-1 Quit ""
	try {
		Set done=0,out=""
		If 'haslen||(len>$$$MaxLocalLength) Set len=$$$MaxLocalLength
	
		#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
		If i%Mode=..#WRITE Do ..Rewind()

		#; try to read from i%Buffer
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
			#; see if we're done
			If ('haslen&&(out'=""))||($length(out)'<len) Quit
		}
		#; Check if we are at the end of the buffer
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
	
		#; If we are at the end with no data return -1
		Set len=$S((i%AtEnd=1)&($L(out)=0):-1,1:$L(out))
	} catch tException {
		Set sc = tException.AsStatus()
	}
	Quit out
}

Method Write(data As %RawString = "") As %Status
{
	#; Mode = ..#READNODATA,..#READNOTCHANGED: set up for write, rewind--JMD008
	If i%Mode'=..#WRITE {
		Do ..Rewind()
		#; Mode = ..#READCHANGED; clear TempGlvn; prepare for write (to same location as last write)
		If i%Mode=..#READCHANGED Kill ^||%IRIS.Stream(i%TempNode)
		Set i%Mode=..#WRITE,i%IOSize=0,i%MaxNodeNo=0
	}
	
	#; a write is never at the end
	Set i%AtEnd=0
	
	#; update size
	Set datalen=$length(data),i%IOSize=i%IOSize+datalen
	
	#; update timestamp on last changed
	Set i%%LastModified=$ZTimeStamp
	
	#; if it fits, append data to Buffer
	Set bufferlen=..#BUFFERLEN
	If bufferlen["," Set bufferlen=+$piece(bufferlen,",",2)
	Set bufneed=bufferlen-$Length(i%Buffer)
	If bufneed>datalen Set i%Buffer=i%Buffer_data Quit $$$OK

	#; otherwise store Buffer to global
	Set batch=$zu(68,25,1)
	Try {
		If i%TempNode="" Set i%TempNode=$Increment(^||%IRIS.Stream)
		If i%Buffer="" {
			If $length(data)=bufneed {
				Set ^||%IRIS.Stream(i%TempNode,$increment(i%MaxNodeNo))=data
			} Else {
				Set ^||%IRIS.Stream(i%TempNode,$increment(i%MaxNodeNo))=$extract(data,1,bufneed)
			}
		} Else {
			Set ^||%IRIS.Stream(i%TempNode,$increment(i%MaxNodeNo))=i%Buffer_$extract(data,1,bufneed)
		}
		While datalen-bufneed'<bufferlen {
			Set ^($increment(i%MaxNodeNo))=$extract(data,bufneed+1,bufneed+bufferlen),bufneed=bufneed+bufferlen
		}
	} Catch exception {
		Do:batch=0 $zu(68,25,0)
		Throw exception
	}
	Do:batch=0 $zu(68,25,0)
	Set i%Buffer=$extract(data,bufneed+1,*)
	Quit $$$OK
}

/// Check if we are at the end of the global, but do not read the next buffer
Method CheckAtEnd() [ Private ]
{
	Set i%Position=1,i%Buffer=""
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
	Set i%Position=1
	#; Are we at the end
	If i%NodeNo'<i%MaxNodeNo {
		Set i%AtEnd=1,i%NodeNo=0,i%Buffer=""
		Do:i%%Locked ..%UnlockStream(1)
		Quit 0
	}
	If i%Mode=..#READNOTCHANGED {
		if ('i%%Locked) && (i%%Concurrency) { do ..%LockStream() }
		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25,1)
		Set i%Buffer=@(i%StoreRoot)@(i%StoreNode,$increment(i%NodeNo))
		Do:batch=0 $zu(68,25,0)
	} Else {
		Set i%Buffer=^||%IRIS.Stream(i%TempNode,$increment(i%NodeNo))
	}
	Quit 1
}

Method WriteBuffer() As %Status [ Private ]
{
	#; store Buffer to temp global
	#; Turn on batch mode so reading stream does not kill the cache
	Set batch=$zu(68,25) Do:batch=0 $zu(68,25,1)
	
	If i%TempNode="" Set i%TempNode=$Increment(^||%IRIS.Stream)
	Set bufferlen=..#BUFFERLEN
	If bufferlen["," Set bufferlen=+$piece(bufferlen,",",2)

	While i%Buffer'="" {
		#; Move to next node, write data
		Set ^||%IRIS.Stream(i%TempNode,$increment(i%MaxNodeNo))=$extract(i%Buffer,1,bufferlen)
		Set i%Buffer=$extract(i%Buffer,bufferlen+1,*)
	}
	Do:batch=0 $zu(68,25,0)
	Quit $$$OK
}

Method MoveToEnd() As %Status
{
	#; If no data or in write mode already nothing to do
	If (i%Mode=..#READNODATA)||(i%Mode=..#WRITE) Quit $$$OK
	
	#; Copy the permanent data into temporary structure ready for appending
	If i%Mode=..#READNOTCHANGED {
		If i%TempNode="" Set i%TempNode=$Increment(^||%IRIS.Stream)
		For i=1:1:i%MaxNodeNo Set ^||%IRIS.Stream(i%TempNode,i)=@(i%StoreRoot)@(i%StoreNode,i)
	}
	Set i%Mode=..#WRITE,i%Buffer="",i%Position=1
	
	#; a write is never at the end
	Set i%AtEnd=0
	
	Quit $$$OK
}

Method CopyFrom(source As %AbstractStream) As %Status
{
	Quit:source=$$$NULLOREF $$$ERROR($$$OrefInvalid,"")
	
	Set sc=$$$OK
	
	#; Optimise for copy from one global to another
	If $classname(source)=$classname() {
		Set sourceGlvn=$S(source.Mode=..#READCHANGED:source.TempGlvn,source.Mode=..#WRITE:$S(source.TempNode="":"",1:source.TempGlvn),source.Mode=..#READNODATA:"",1:source.StoreGlvn)
		Set tempnode=i%TempNode,sourcemaxnodeno=source.MaxNodeNo
		If tempnode="",sourceGlvn'="" Set tempnode=$Increment(^||%IRIS.Stream),i%TempNode=tempnode
	
		#; Update the last modified timestamp
		Set i%%LastModified=$ZTimeStamp
	
		#; If this is replacing the old data we can use a merge
		If i%Mode'=..#WRITE {
			#; clear TempGlvn to prepare for write to same location as last write
			If i%Mode=..#READCHANGED Kill ^||%IRIS.Stream(tempnode)
			#; Turn on batch mode so reading stream does not kill the cache
			Set batch=$zu(68,25,1)
			Try {
				#; Copy the data and setup the properties
				Set i%MaxNodeNo=sourcemaxnodeno
				For i=1:1:sourcemaxnodeno Set ^||%IRIS.Stream(tempnode,i)=@sourceGlvn@(i)
			} Catch exception {
				Do:batch=0 $zu(68,25,0)
				Throw exception
			}
			Do:batch=0 $zu(68,25,0)
			Set i%Mode=..#WRITE
			Set i%IOSize=source.Size
			Set i%Buffer=$select(source.Mode=..#WRITE:source.Buffer,1:"")
		} Else {
			#; Else we can $O through the global using the three parameter loop which is faster than the generic
			#; copy mechanism, and add the new information to the end of the current data.
			Set buffer=i%Buffer,maxnodeno=i%MaxNodeNo
			Set bufferlen=..#BUFFERLEN
			If bufferlen["," Set bufferlen=+$piece(bufferlen,",",2)
			For i=1:1:sourcemaxnodeno,0 {
				If i=0 {
					Set data=$select(source.Mode=..#WRITE:source.Buffer,1:"")
				} Else {
					Set data=@sourceGlvn@(i)
				}
				Set datalen=$length(data)
				If $length(buffer)+datalen<bufferlen Set buffer=buffer_data Continue

				#; otherwise store Buffer to global
				Set batch=$zu(68,25,1)
				Try {
					If tempnode="" Set tempnode=$Increment(^||%IRIS.Stream),i%TempNode=tempnode
					#; If buffer big enough on its own to write a chunk output these
					Set currpos=1
					While $length(buffer)-currpos+1>=bufferlen {
						Set ^||%IRIS.Stream(tempnode,$increment(maxnodeno))=$extract(buffer,currpos,currpos+bufferlen-1),currpos=currpos+bufferlen
					}
					If currpos'=1 Set buffer=$extract(buffer,currpos,*)

					If buffer="" {
						Set currpos=bufferlen
						If datalen=bufferlen {
							Set ^||%IRIS.Stream(tempnode,$increment(maxnodeno))=data
						} Else {
							Set ^||%IRIS.Stream(tempnode,$increment(maxnodeno))=$extract(data,1,bufferlen)
						}
					} Else {
						Set currpos=bufferlen-$length(buffer)
						Set ^||%IRIS.Stream(tempnode,$increment(maxnodeno))=buffer_$extract(data,1,currpos)
					}
					While datalen-currpos>=bufferlen {
						Set ^||%IRIS.Stream(tempnode,$increment(maxnodeno))=$extract(data,currpos+1,currpos+bufferlen),currpos=currpos+bufferlen
					}
					Set buffer=$extract(data,currpos+1,*)
				} Catch exception {
					Do:batch=0 $zu(68,25,0)
					Throw exception
				}
				Do:batch=0 $zu(68,25,0)
			}
			Set i%IOSize=i%IOSize+source.Size,i%MaxNodeNo=maxnodeno
			Set i%Buffer=buffer
		}
	
	#; Else use the generic copy mechanism
	} Else {
		Set sc=##class(%Stream.Object)$this.CopyFrom(source)
	}

	If $$$ISERR(sc) Quit sc
	
	#; Now copy the attributes
	If source.%Extends("%Library.AbstractStream")||(source.%Extends("%CSP.Stream")) {
		Set name="" For  Set name=source.NextAttribute(name) Quit:name=""  Do ..SetAttribute(name,source.GetAttribute(name))
	}
	
	Quit sc
}

Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set $Ztrap="OutputError"
	If (i%Mode=..#READNODATA) Set i%AtEnd=1,len=-1 Quit $$$OK
	If len=0 Quit $$$OK
	If i%Position=1,i%NodeNo=0,len=..Size Set len=-1
	#; Turn on batch mode so reading stream does not kill the cache
	Set batch=$zu(68,25) Do:batch=0 $zu(68,25,1)
	Set sc=$$$OK
	If len=-1 {
		#; Note that Rewind turns off WRITE mode so we do not need to test for this
		Do ..Rewind()
		Set glvn=$S(i%Mode=..#READCHANGED:$name(^||%IRIS.Stream(i%TempNode)),i%Mode=..#READNOTCHANGED:$name(@(i%StoreRoot)@(i%StoreNode)))
		Set node=0
		For i=1:1:i%MaxNodeNo Write @glvn@(i)
		Set len=..Size
	#; Else write out just part of the global
	} Else {
		#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
		If i%Mode=..#WRITE Do ..Rewind()

		Set written=0

		#; If they only want less than in the current buffer so give it to them
		If len<($L(i%Buffer)-i%Position+2) {
			Write $E(i%Buffer,i%Position,i%Position+len-1)
			Set i%Position=i%Position+len
			Set written=len
		#; Else they want more than in the buffer
		} Else {
			#; Output the buffer to start with
			Write $E(i%Buffer,i%Position,$L(i%Buffer))
			Set written=written+$L(i%Buffer)-i%Position+1

			Set glvn=$S(i%Mode=..#READCHANGED:$name(^||%IRIS.Stream(i%TempNode)),i%Mode=..#READNOTCHANGED:$name(@(i%StoreRoot)@(i%StoreNode)))
			Set node=i%NodeNo
			For  Set node=$O(@glvn@(node),1,data) Quit:node=""  Quit:written+$L(data)>len  Write data Set written=written+$L(data)
			Set i%NodeNo=$S(node="":0,1:node)

			#; End of stream
			If node="" {
				Set i%AtEnd=1,i%Buffer="",i%Position=1
			} Else {
				#; Now write out the final data
				Write $E(data,1,len-written)
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
	Do:batch=0 $zu(68,25,0)
	Quit sc
OutputError	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

Method Clear(permanent As %Boolean = 1) As %Status
{
	#; Get rid of the attributes first
	Merge lt=i%Attributes("LineTerminator") Kill i%Attributes Merge i%Attributes("LineTerminator")=lt
	Set i%%LastModified=$ZTimeStamp
	If i%Mode=..#READNODATA Quit $$$OK
	If i%Mode=..#WRITE Do ..Rewind()
	If i%Mode=..#READCHANGED Kill ^||%IRIS.Stream(i%TempNode)
	If permanent {
		If i%StoreNode'="" Kill @(i%StoreRoot)@(i%StoreNode)
		Set i%Mode=..#READNODATA,i%MaxNodeNo=0
	} Else {
		Set i%Mode=..#READNOTCHANGED,maxnode=0
		If i%StoreNode'="",$data(@(i%StoreRoot)@(i%StoreNode),maxnode)#10=0 Set maxnode=+$order(^(i%StoreNode,""),-1)
		Set i%MaxNodeNo=maxnode
	}
	Set i%Buffer="",i%Position=1,i%NodeNo=0,i%IOSize=0,i%AtEnd=1
	Quit $$$OK
}

Method LastModifiedGet() As %TimeStamp [ CodeMode = expression ]
{
$zdt($select(i%%LastModified="":$ZTimeStamp,1:i%%LastModified),3)
}

Method ReadLine(ByRef len As %Integer = 32656, ByRef sc As %Status, ByRef eol As %Boolean) As %RawString
{
	Set sc=$$$OK,eol=0
	#; Mode ..#READNODATA: no data 
	If (i%Mode=..#READNODATA)||(i%AtEnd=1) Set i%AtEnd=1,len=-1 Quit ""
	
	try {
		#; try to read from i%Buffer
		Set done=0,out="",terminator=..LineTerminator
		Set:len>($$$MaxLocalLength-$length(terminator)) len=$$$MaxLocalLength-$length(terminator)
		#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
		Do:i%Mode=..#WRITE ..Rewind()
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
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
	
		#;if we are at the end with no data return -1
		Set len=$S((i%AtEnd=1)&&(out=""):-1,$L(out)>len:len,1:$L(out))
	} catch tException {
		set sc = tException.AsStatus()
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
Method ReadLineIntoStream() As %AbstractStream
{
	Set stream=..%New()
	#; Mode ..#READNODATA: no data 
	If (i%Mode=..#READNODATA)||(i%AtEnd=1) Set i%AtEnd=1 Quit stream
	try {
		#; Mode ..#WRITE: in middle of Write with no rewind; automatically rewind
		Do:i%Mode=..#WRITE ..Rewind()
	
		#; try to read from i%Buffer
		Set done=0,out="",terminator=..LineTerminator
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
		. Do stream.Write($extract(out,1,$length(out)-$length(terminator)+1)) Set out=$extract(out,$length(out)-$length(terminator)+2,*)
		#; See if we are at the end of the stream
		If 'i%AtEnd,i%Position>$length(i%Buffer) Do ..CheckAtEnd()
		Do:out'="" stream.Write(out)
	}
	catch tException { set sc = tException.AsStatus() }
	Quit stream
}

/// Given a stream id this returns the root global node where this stream is stored
ClassMethod GlobalFromSid(sid As %String) As %String
{
	Set id=$listget($extract($listget(sid),2,*))
	Quit $name(@$lg(id)@($lg(id,2)))
}

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

ClassMethod %Exists(soid As %ObjectIdentity) As %Boolean
{
	Set id=$list($extract($$$oidPrimary(soid),2,*))
	Set location=$list(id,1),loctmp=$list(id,2)
	If location="" Set location=..#STOREGLOBALNAME
	If location=""||(loctmp="") Quit 0
	Quit ''$data(@location@(loctmp))
}

/// Return true if this stream oid is a null stream and false if the stream is not null
ClassMethod %ObjectIsNull(soid As %ObjectIdentity) As %Boolean
{
	If soid=$$$NULLOID Quit 1
	If $isobject(soid)=1 Quit soid.%IsNull()
	Set class=$$$oidClassName(soid)
	If class'="" {
		Set class=$$$NormalizeClassname(class) If $classname()'=class Quit $classmethod(class,"%ObjectIsNull",soid)
	}
	Set serialized=$$$oidPrimary(soid)
	If $ascii(serialized)=0,$listget($extract(serialized,2,*),2)'="" Quit 0
	Quit '..%Exists(soid)
}

/// Return true if this stream oid is a null stream and false if the stream is not null
ClassMethod StreamOIDIsNull(soid As %ObjectIdentity) As %Boolean [ CodeMode = call ]
{
..%ObjectIsNull(.soid)
}

/// Return the size of the stream pointed to by soid
ClassMethod %ObjectSizeInternal(soid As %ObjectIdentity) As %Integer [ Private ]
{
	Set id=$list($extract($$$oidPrimary(soid),2,*))
	Set location=$list(id,1),loctmp=$list(id,2)
	Set:location="" location=..#STOREGLOBALNAME
	Quit:location=""||(loctmp="") 0
		#; read size from "0" node, if present, if not calculate it
	If $data(@(location)@(loctmp,0),size)#10=0 {
		Set size=##class(%Stream.Object)$this.%ObjectSizeInternal(soid)
	}
	Quit size
}

ClassMethod %LOBPrefetchInternal(soid As %ObjectIdentity, prefetchsize As %Integer, ByRef data As %String) As %Integer [ Private ]
{
	Set id=$list($extract($$$oidPrimary(soid),2,*))
	Set location=$list(id,1),loctmp=$list(id,2)
	Set:location="" location=..#STOREGLOBALNAME
	Quit:location=""||(loctmp="") 0
		#; read size from "0" node, if present
	If $data(@(location)@(loctmp,0),size)#10=0 {
		Quit ##class(%Stream.Object)$this.%LOBPrefetchInternal(soid,prefetchsize,.data)
	}
	Quit:size>prefetchsize 0
	Set:$data(@(location)@(loctmp),maxnode)#10=0 maxnode=+$order(^(loctmp,""),-1)
	For i=1:1:maxnode {
		Set data=data_@(location)@(loctmp,i)
	}
	Quit $select(size=0:3,..IsCharacter():1,1:2)
}

Storage Custom
{
<Type>%Library.CompleteCustomStorage</Type>
}

}
