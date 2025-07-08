/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardingManager

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.GlobalCharacter">Working with Streams</a>.</p>
/// Stream class that stores character data in global nodes.
Class %Stream.GlobalCharacter Extends TmpCharacter [ System = 2 ]
{

Parameter COMPRESS = 1;

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	set i%%Location=$select(initval="":$$$streamGlobal,$$$UPPER(initval)="SHARD":"^IRIS.Stream.Shard",1:initval)
	RETURN $$$OK
}

Method %LoadData(id As %String) As %Status [ Private ]
{
	Set i%Id=id,i%NodeNo=0
	If i%%Location="" Set i%%Location=$$$streamGlobal

	If id="" {
		Set i%Mode=$$$modeREADNODATA,i%AtEnd=1,i%IOSize=0,i%MaxNodeNo=0,i%Compress=..#COMPRESS
	} Else {
		If ('i%%Locked) && (i%%Concurrency) { Do ..%LockStream() }
		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25,1)
		Set maxnode="",size=0,location=i%%Location
		Set header=$get(@location@(id))
		If header["," {
			#; New header format
			Set maxnode=$piece(header,","),size=+$piece(header,",",2),i%Compress=+$piece(header,",",3)
		} Else {
			#; Old header format has just maxnode in it
			#; For compression specific subclasses ..#COMPRESS=2 we always use compression even for old header format
			Set i%Compress=$select(..#COMPRESS=2:2,1:-1)
			Set maxnode=$select(header="":+$order(@location@(id,""),-1),1:header)
			#; read size from "0" node, if present, if not calculate it
			If maxnode'="",'$data(@location@(id,0),size) {
				Set size=0 For i=1:1:maxnode Set size=size+$length($$$streamDecompressBuf(^(i)))
			}
		}
		Set i%IOSize=size,i%AtEnd='size,i%Mode=$select(maxnode="":$$$modeREADNODATA,1:$$$modeREADNOTCHANGED),i%MaxNodeNo=+maxnode
		Do $zu(68,25,batch)
	}
	Quit $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private ]
{
	set tStatus = $$$OK, tLocked = 0
	#; save the stream;
	Set mode=i%Mode
	If mode=$$$modeREADNODATA||(mode=$$$modeREADNOTCHANGED)||(mode=$$$modeWRITEJUSTSAVED) Quit $$$OK
	try {
		#; Before changing anything we need to remember what the current state is in case of a rollback
		Kill i%rollback If $tlevel Set i%rollback("Buffer")=i%Buffer,i%rollback("Mode")=mode,i%rollback("MaxNodeNo")=i%MaxNodeNo
	
		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25,1)
		If mode=$$$modeWRITE||(mode=$$$modeREADBUFFER) { Set buffer=i%Buffer } Else { Set buffer="" }
		If i%%Location="" Set i%%Location=$$$streamGlobal
		Set location=i%%Location
		#; kill original data and save size in "0" node
		Set bufferlen=+..#BUFFERLEN
		Set maxnodeno=i%MaxNodeNo+($length(buffer)+bufferlen-1\bufferlen),killdest=0
		#; If we have not written any blocks so far check if we should compress
		If i%Compress=1,i%MaxNodeNo=0,..NotCompressible(.buffer) Set i%Compress=0
		#; allocate new stream no if needed
		If $$$streamTmpGlobalDefault {
			If i%Id="" {
				Set i%Id=$sequence(@location)
			} Else {
				Set killdest=1
			}
			if i%%Concurrency {
				set tLockRef = ..%GetLockReference(location,i%Id)
				if tLockRef '= "" {
					lock +@(tLockRef):$$$LockTimeout if $test { set tLocked = 1 } else { set tLocked = 0 throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$LockFailedToAcquireExclusive,tLockRef)) }
				}
			}
			If killdest Do ..BuildValueArray(.subvalue)
		} ElseIf i%%Concurrency {
			#; Make sure we unlock when we are done, lock originally taken out in Write method
			set tLockRef = ..%GetLockReference(location,i%Id)
			If tLockRef'="" Set tLocked=1
		}
		Set sid=i%Id
		If killdest,$data(@location@(sid)) Kill ^(sid)
		If i%Compress=-1||(i%Compress=2) {
			Set @location@(sid)=maxnodeno,^(sid,0)=i%IOSize
		} Else {
			Set @location@(sid)=maxnodeno_","_i%IOSize_$select(i%Compress=0:"",1:","_i%Compress)
		}
		Set maxnodeno=i%MaxNodeNo
		Set movedata=0
		If i%TempGbl'="",$$$streamTmpGlobalDefault {
			Set tmpgbl=i%TempGbl,movedata=1
			For i=1:1:maxnodeno Set @location@(sid,i)=@tmpgbl@(i)
		}
		
		#; If in WRITE mode have to write out buffer, do not update i%MaxNodeNo here as we keep the temporary stream
		While buffer'="" {
			If $length(buffer)<=bufferlen {
				Set @location@(sid,$increment(maxnodeno))=$$$streamCompressBuf(buffer)
				QUIT
			} Else {
				Set @location@(sid,$increment(maxnodeno))=$$$streamCompressBuf($extract(buffer,1,bufferlen))
				Set buffer=$extract(buffer,bufferlen+1,*)
			}
		}

		#; If we did not move the temp data we have to setup so next write will copy the permanent data to temp storage
		If 'movedata {
			#; Clear i%TempGbl so permanent location is not removed on stream close
			Set i%TempGbl=""
			If mode=$$$modeWRITE {
				Set i%Mode=$$$modeWRITEJUSTSAVED
				Set i%NodeNo=0,i%Position=1,i%Buffer="",i%AtEnd=0
			} ElseIf mode'=$$$modeREADBUFFER {  ; READBUFFER can leave all settings the same
				#; As data did not move we must update i%MaxNodeNo as this is the max on disk
				Set i%MaxNodeNo=maxnodeno
				Set i%Mode=$$$modeREADNOTCHANGED
			}
		} Else {
			Set i%Mode=$$$modeWRITEJUSTSAVED
		}

		#; Save the subvalue array for index updates
		If $data(subvalue) Merge ^||%isc.strv(..%Oid())=subvalue

		if tLocked { lock -@(tLockRef)#"I" }
		Do $zu(68,25,batch)
	}
	catch tException {
		if $Get(tLocked) { lock -@(tLockRef)#"I" }
		set tStatus = tException.AsStatus()
	}
	Quit tStatus
}

ClassMethod %DeleteData(streamvalue As %String, concurrency As %Integer) As %Status [ Private ]
{
	try {
		set tStatus=$$$OK
		set tLocked=0
		set root=$$$oidSysAd1(streamvalue)
		set shardnum=$$$oidSysAd2(streamvalue)
		if root="" { set root=$$$streamGlobal }
		else {
			set:'$d($system.Context.SQL().ShardNumber($namespace)) $system.Context.SQL().ShardNumber($namespace)=$$getNSShardNumber^%SYS.SHARDSRV()
			if shardnum,shardnum'=$system.Context.SQL().ShardNumber($namespace) { set root="^|"""_$$getExtRefEnvFromShardNum^%SYS.SHARDSRV(shardnum)_"""|"_$e(root,2,*) }
		}
		set node=$$$oidPrimary(streamvalue)
		quit:(root="")||(node="")
		if concurrency {
			set tLockRef = ..%GetLockReference(root,node)
			if tLockRef '= "" {
				lock +@(tLockRef):$$$LockTimeout if $test { set tLocked = 1 } else { set tStatus=$$$ERROR($$$LockFailedToAcquireExclusive,tLockRef) quit }
			}
		}
		kill @root@(node)
	} catch tException {
		set tStatus = tException.AsStatus()
	}
	lock:tLocked -@(tLockRef)#"I"
	RETURN tStatus
}

/// Setup the TempGbl location of where we will write the temp stream to
Method SetupTmpGbl() [ Private ]
{
	If i%%Location="" Set i%%Location=$$$streamGlobal
	#; Optimistically write temp stream to permanent destination if location of stream is not the default and this is a new stream
	If i%%Location=$$$streamGlobal||(i%Id'="") {
		$$$streamInitTmpGlobal
	} Else {
		Set batch=$zu(68,25,1)
		Set i%Id=$sequence(@i%%Location),tLocked=1
		if i%%Concurrency {
			set tLockRef = ..%GetLockReference(i%%Location,i%Id)
			if tLockRef '= "" {
				lock +@(tLockRef):$$$LockTimeout Set tLocked=$test
			}
		}
		If 'tLocked {
			$$$streamInitTmpGlobal
		} Else {
			Set i%TempGbl=$name(@i%%Location@(i%Id))
		}
		Do $zu(68,25,batch)
	}
}

Method CopyFromAndSave(source As %Stream.Object) As %Status
{
	Set sc=$$$OK
	#; Optimise for copy from one global to another
	If $classname(source)=$classname() {
		Set mode=source.Mode
		Set sourceGlvn=$S(mode=$$$modeREADCHANGED||(mode=$$$modeWRITE):source.TempGbl,mode=$$$modeREADNODATA||(mode=$$$modeREADBUFFER):"",1:$na(@(source.%Location)@(source.Id)))
		If mode=$$$modeWRITEJUSTSAVED {
			Set maxnodeno=+$get(@sourceGlvn)
		} Else {
			Set maxnodeno=source.MaxNodeNo
		}
		Set i%Compress=source.Compress
		#; Update the last modified timestamp
		Set i%mLastModified=$ZTimeStamp

		#; Turn on batch mode so reading stream does not kill the cache
		Set batch=$zu(68,25,1)
		If i%TempGbl'="" {
			Set journal=$zu(139,2)
			Kill @i%TempGbl
			Do $zu(139,journal)
			If '$$$streamTmpGlobalDefault,i%%Concurrency {
				Set lockref = ..%GetLockReference(i%%Location,i%Id)
				If lockref'="" lock -@(lockref)#"I"
			}
			Set i%TempGbl=""
		}
		#; allocate new stream no if needed
		Set location=i%%Location,id=i%Id
		If id="" {
			Set i%Id=$sequence(@i%%Location),id=i%Id
		} Else {
			If $data(@location@(id)) Kill ^(id)
		}
		Set writelocation=$name(@location@(id))
		For i=1:1:maxnodeno Set @writelocation@(i)=@sourceGlvn@(i)
		Set i%MaxNodeNo=maxnodeno,i%IOSize=source.Size,buffer=$select(mode=$$$modeWRITE||(mode=$$$modeREADBUFFER):source.Buffer,1:"")
		#; If we have not written any blocks so far see if it is worth compressing
		If i%Compress=1,i%MaxNodeNo=0,..NotCompressible(.buffer) Set i%Compress=0
		If buffer'="" {
			Set bufferlen=+..#BUFFERLEN
			If $length(buffer)<=bufferlen {
				$$$streamWriteCompressData(buffer,writelocation)
			} Else {
				$$$streamWriteCompressData($extract(buffer,1,bufferlen),writelocation)
				Set buffer=$extract(buffer,bufferlen+1,*)
				While buffer'="" {
					Set @writelocation@($increment(i%MaxNodeNo))=$$$streamCompressBuf($extract(buffer,1,bufferlen))
					Set buffer=$extract(buffer,bufferlen+1,*)
				}
			}
		}
		If i%Compress=-1||(i%Compress=2) {
			Set @writelocation=i%MaxNodeNo,^(id,0)=source.Size
		} Else {
			Set @writelocation=i%MaxNodeNo_","_(source.Size)_$select(i%Compress=0:"",1:","_i%Compress)
		}
		Do $zu(68,25,batch)
		Set i%Mode=$$$modeREADNOTCHANGED,i%Buffer=""
		#; Now copy the LineTerminator attribute
		Set ..LineTerminator=source.LineTerminator
		Set i%"%%OID"=..%Oid()
	} Else {
		Set sc=..Rewind() Quit:$$$ISERR(sc) sc
		Set sc=..CopyFrom(source) Quit:$$$ISERR(sc) sc
		Set sc=..%Save()
	}
	Quit sc
}

/// Return the size of the stream pointed to by soid
ClassMethod %ObjectSizeInternal(soid As %ObjectIdentity) As %Integer [ Private ]
{
	set size=0
	set location=$$$oidSysAd1(soid)
	set:location="" location=$$$streamGlobal
	set shardnum=$$$oidSysAd2(soid)
	Set loctmp=$$$oidPrimary(soid)
	RETURN:location=""||(loctmp="") 0
	set:'$d($system.Context.SQL().ShardNumber($namespace)) $system.Context.SQL().ShardNumber($namespace)=$$getNSShardNumber^%SYS.SHARDSRV()
	if shardnum,shardnum'=$system.Context.SQL().ShardNumber($namespace) { set location="^|"""_$$getExtRefEnvFromShardNum^%SYS.SHARDSRV(shardnum)_"""|"_$e(location,2,*) }
	set rootnode=$get(@location@(loctmp))
	If rootnode["," {
		Set size=$piece(rootnode,",",2)
	} Else {
		#; read size from "0" node, if present
		set:$data(@location@(loctmp,0),size)#10=0 size=##class(%Stream.Object)$this.%ObjectSizeInternal(soid)
	}
	RETURN size
}

ClassMethod %LOBPrefetchInternal(soid As %ObjectIdentity, prefetchsize As %Integer, ByRef data As %String) As %Integer [ Private ]
{
	set location=$$$oidSysAd1(soid)
	set:location="" location=$$$streamGlobal
	set shardnum=$$$oidSysAd2(soid)
	set loctmp=$$$oidPrimary(soid)
	RETURN:location=""||(loctmp="") 0
	set:'$d($system.Context.SQL().ShardNumber($namespace)) $system.Context.SQL().ShardNumber($namespace)=$$getNSShardNumber^%SYS.SHARDSRV()
	if shardnum,shardnum'=$system.Context.SQL().ShardNumber($namespace) { set location="^|"""_$$getExtRefEnvFromShardNum^%SYS.SHARDSRV(shardnum)_"""|"_$e(location,2,*) }
	set rootnode=$get(@location@(loctmp))
	if rootnode["," {
		Set size=$piece(rootnode,",",2),maxnode=+rootnode
	} Else {
		#; read size from "0" node, if present
		RETURN:$data(@location@(loctmp,0),size)#10=0 ##class(%Stream.Object)$this.%LOBPrefetchInternal(soid,prefetchsize,.data)
		set maxnode=$select(rootnode="":+$order(@location@(loctmp,""),-1),1:+rootnode)
	}
	RETURN:size>prefetchsize 0
	#; Read compression state from header or from class parameter
	Set compress=$select(rootnode[",":$piece(rootnode,",",3),1:..#COMPRESS)
	for i=1:1:maxnode {
		set data=data_$$$streamDecompressBufFlag(@location@(loctmp,i),compress)
	}
	RETURN $select(size=0:3,..IsCharacter():1,1:2)
}

}
