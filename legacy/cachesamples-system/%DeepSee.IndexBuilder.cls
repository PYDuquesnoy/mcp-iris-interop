/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.IndexBuilder [ Abstract, System = 3 ]
{

/// <var>BITMAPCHUNKINMEMORY</var> is used during code generation to decide whether or not bitmap chunks can be
/// constructed in memory. It is faster to construct bitmap chunks in memory but if there are a lot of bitmaps,
/// the indexed property or properties have very low selectivity or the index values are large then STORE errors
/// can be encountered. If <var>BITMAPCHUNKINMEMORY</var> is 1 then bitmap chunks are constructed in memory by
/// %ConstructIndices. Otherwise, bitmap chunks are constructed using process-private globals. The default is 0,
/// meaning that bitmap chunks are built using process-private globals.
Parameter BITMAPCHUNKINMEMORY = 0;

/// NextId(pId,pDirection) returns the ID value following pId if pDirection is 1 or the ID value preceding pId if
/// pDirection is -1.
ClassMethod %NextId(pId As %Integer, pDirection As %Integer = 1) As %Integer [ CodeMode = objectgenerator ]
{
	if (%compiledclass.ClassType=$$$cCLASSCLASSTYPEPERSISTENT) && ('%compiledclass.NoExtent) {
		set tClassId = %compiledclass.%Id()
		set tDataAddress = $$$EXTdataaddress($$$pEXT,tClassId)
		set tGLVN = $$$EXTADDRglobal($$$pEXT,tClassId,tDataAddress)
		set tKeysubs = $$$EXTADDRkeysubscripts($$$pEXT,tClassId,tDataAddress)
		set tGLVN = tGLVN _ $select($extract(tGLVN)'="@":"(",1:"@(")
		set tSubscript = $order($$$EXTADDRSUB($$$pEXT,tClassId,tDataAddress,""))
		if $listlength(tKeysubs) = 1 {
			while (tSubscript '= "") && ('$get($$$EXTADDRSUBkeysub($$$pEXT,tClassId,tDataAddress,tSubscript))) {
				set tGLVN = tGLVN _ $$$EXTADDRSUBexpression($$$pEXT,tClassId,tDataAddress,tSubscript) _ ","
				set tSubscript = $order($$$EXTADDRSUB($$$pEXT,tClassId,tDataAddress,tSubscript))
			}
			do %code.WriteLine($Char(9)_"quit $Case(pDirection,1:$Order("_tGLVN_"pId)),:$Order("_tGLVN_"pId),-1))")
		}
		else { do %code.WriteLine($Char(9)_"quit """"") }
	}
	quit $$$OK
}

ClassMethod %ConstructIndicesParallel(pTaskId = "", pStartId As %Integer = 0, pEndId As %Integer = -1, pSortBegin As %Integer = 1, pDroneCount As %Integer = 0) As %Status
{
#define BitMapSize							64000
#define BitMapChunk(%id)					(%id\$$$BitMapSize+1)
#define BitMapOffset(%id)					(%id#$$$BitMapSize+1)
#define BitMapChunkStartingId(%chunk)		((%chunk-1)*$$$BitMapSize)
#define BitMapChunkEndingId(%chunk)			(%chunk*$$$BitMapSize-1)
#define BitMapChunkAtStart(%chunk,%start)	($select(%start=$$$BitMapChunkStartingId(%chunk):1,%start'>..%NextId($$$BitMapChunkStartingId(%chunk)-1):1,1:0))
#define BitMapChunkAtEnd(%chunk,%end)		($select(%end=$$$BitMapChunkEndingId(%chunk):1,%end'<..%NextId($$$BitMapChunkEndingId(%chunk)+1,-1):1,1:0))
#define BitMapChunkComplete(%chunk,%start,%end)	$$$BitMapChunkAtStart(%chunk,%start)&&$$$BitMapChunkAtEnd(%chunk,%end)
#define ChunksPerJob		2
	if pTaskId = "" {
		set tStartTime = $zh
			#; MASTER PROCESS - this section could start background tasks, up to the number of cores + 2.
		set tStatus = ..%LockExtent(0)
		if $$$ISERR(tStatus) { quit tStatus }

		#; Chunk it up
			#; Determine chunk boundaries and how many chunks
		if 'pStartId { set pStartId = 0, tChunkStart = 1, tOffsetStart = 1 }
		else { set tChunkStart = $$$BitMapChunk(pStartId), tOffsetStart = $$$BitMapOffset(pStartId) }
		if pEndId < 1 { set pEndId = ..%NextId("",-1) }
		set tChunkEnd = $$$BitMapChunk(pEndId), tOffsetEnd = $$$BitMapOffset(pEndId)
			#; Determine if the ID range for the chunk is complete
		set tChunkCount = tChunkEnd - tChunkStart + 1
			#; Single chunk - just do it.
		if tChunkCount = 1 {
			write !,"Building single chunk that is ",$s($$$BitMapChunkComplete(tChunkStart,pStartId,pEndId):"",1:"not "),"complete."
			set tStatus = ..%ConstructIndices(pStartId,pEndId,$$$BitMapChunkComplete(tChunkStart,pStartId,pEndId))
		}
			#; Two chunks - just do it.
		elseif tChunkCount = 2 {
			write !,"Building two chunks. First is ",$s($$$BitMapChunkAtStart(tChunkStart,pStartId):"",1:"not "),"complete and second is ",$s($$$BitMapChunkAtEnd(tChunkEnd,pEndId):"",1:"not "),"complete."
			set tStatus = ..%ConstructIndices(pStartId,$$$BitMapChunkEndingId(tChunkStart),$$$BitMapChunkAtStart(tChunkStart,pStartId))
			set tStatus = ..%ConstructIndices($$$BitMapChunkStartingId(tChunkEnd),pEndId,$$$BitMapChunkAtEnd(tChunkEnd,pEndId))
		}
			#; Build the task list
		else {
			set tTaskPtr = $Increment(^IRIS.Temp)
			$$$AddTempNode(^IRIS.Temp(tTaskPtr))
			set ^IRIS.Temp(tTaskPtr) = 1, ^IRIS.Temp(tTaskPtr,1) = $listbuild(pStartId,$$$BitMapChunkEndingId(tChunkStart),$$$BitMapChunkAtStart(tChunkStart,pStartId))
			for tChunk = tChunkStart+1:1:tChunkEnd-1 { set ^IRIS.Temp(tTaskPtr,$increment(^IRIS.Temp(tTaskPtr))) = $listbuild($$$BitMapChunkStartingId(tChunk),$$$BitMapChunkEndingId(tChunk),1) }
			set tendend = $$$BitMapChunkAtEnd(tChunkEnd,pEndId)
			set ^IRIS.Temp(tTaskPtr,$Increment(^IRIS.Temp(tTaskPtr))) = $listbuild($$$BitMapChunkStartingId(tChunkEnd),pEndId,$$$BitMapChunkAtEnd(tChunkEnd,pEndId))
			if 'pDroneCount {
				set tMaxDrones = $system.Util.NumberOfCPUs()
				set:tMaxDrones<1 tMaxDrones = 1
				set:tMaxDrones>128 tMaxDrones = 128
			}
			else { set tMaxDrones = pDroneCount }
			set tDroneCount = $Select(tChunkCount\$$$ChunksPerJob>tMaxDrones:tMaxDrones,1:tChunkCount\$$$ChunksPerJob)
			write !,"Building ",tChunkCount," chunks and will use parallel build algorithm with ",tDroneCount," drone processes."
			if pSortBegin { write !,"SortBegin is requested." }
			set ^IRIS.Temp(tTaskPtr,"shutdown") = 0
			for tPtr = 1:1:tDroneCount {
				set tChild =  ..%ConstructIndicesStartTask(tTaskPtr,pSortBegin)
					if tChild = "" {
						set tSC = $$$ERROR($$$GeneralError,"JOB Command Failure. Unable to start background process to build DeepSeeCubes.DemoCube.Fact indices. Make sure license key is valid!")
						quit
					}
					set ^IRIS.Temp(tTaskPtr,"log",$Increment(^IRIS.Temp(tTaskPtr,"log"))) = "Started drone process: "_$zchild
					write !,"Started drone process: ",$zchild
			}
				#; tChunkTime is the estimate of time to complete building a single chunk (64,000 rows)
				#; This will vary based on the hardware configuration, number and complexity of indices, etc.
			set tChunkTime = 1.1
			set tExpectedTime = (tChunkCount / tDroneCount * tChunkTime) \ 1
			if tExpectedTime > 5 {
				write !,"Expected time to complete is ",tExpectedTime," secs to build ",tChunkCount," chunks of 64,000 objects using ",tDroneCount," processes."
				write !,"Waiting for processes to complete."
				h tExpectedTime/3
			}
			do {
					h .1
					if $increment(tWaitCount) > 10000 { Write !,"This is taking longer than expected..." set tWaitCount = 0 }
			} while ^IRIS.Temp(tTaskPtr,"shutdown") < tDroneCount
			set tEndTime = $zh
			write "...done.",!,"Elapsed time using ",tDroneCount," processes was ",tEndTime-tStartTime,"."
			kill ^IRIS.Temp(tTaskPtr)
			$$$RemoveTempNode(^IRIS.Temp(tTaskPtr))
		}
		do ..%UnlockExtent(0)
	}
	else {
		try {
			set ^IRIS.Temp(pTaskId,"log",$Increment(^IRIS.Temp(pTaskId,"log"))) = "DRONE: ready for work: "_$j
			set tTask = $Increment(^IRIS.Temp(pTaskId,"processing"))
			set ^IRIS.Temp(pTaskId,"log",$Increment(^IRIS.Temp(pTaskId,"log"))) = "DRONE["_$j_"] Entering task loop with task id #"_tTask_$Select(pSortBegin:" with SortBegin/End.",1:"")
			if pSortBegin { do ..%SortBegin() }
			while tTask '> ^IRIS.Temp(pTaskId) {
					set tTime = $zh
					set ^IRIS.Temp(pTaskId,"log",$Increment(^IRIS.Temp(pTaskId,"log"))) = "DRONE["_$j_"] Grabbing task id #"_tTask
					set tTaskData = ^IRIS.Temp(pTaskId,tTask)
					if $List(tTaskData,3) { set tStatus = ..%ConstructIndices($List(tTaskData,1),$List(tTaskData,2)) }
					else  { set tStatus = ..%SaveIndices($List(tTaskData,1),$List(tTaskData,2)) }
					set ^IRIS.Temp(pTaskId,tTask,"processed") = "Processed by "_$j_" in "_($zh-tTime)_". Task finished with "_$Select(tStatus:"SUCCESS",1:"Failure")
					set tTask = $Increment(^IRIS.Temp(pTaskId,"processing"))
			}
		}
		#dim tException as %Exception.AbstractException
		catch tException {
			set tStatus = tException.AsStatus()
		}
		if pSortBegin { do ..%SortEnd() }
		set ^IRIS.Temp(pTaskId,"log",$Increment(^IRIS.Temp(pTaskId,"log"))) = "Shutting down drone process: "_$j_" with status = "_tStatus
			#; Signal the TaskMaster that this worker is going home
		if $Increment(^IRIS.Temp(pTaskId,"shutdown"))
	}
	quit tStatus
}

ClassMethod %ConstructIndicesStartTask(pTaskId, pSortBegin) As %String [ CodeMode = objectgenerator ]
{
	if (%compiledclass.ClassType '= $$$cCLASSCLASSTYPEPERSISTENT) || (%compiledclass.NoExtent) { do %code.WriteLine($char(9)_"QUIT """"") quit $$$OK }
	do %code.WriteLine($Char(9)_"job ##class("_%compiledclass.Name_").%ConstructIndicesParallel(pTaskId,0,-1,pSortBegin,0)::10")
	do %code.WriteLine($Char(9)_"if $Test { set tChild = $zchild } else { set tChild = """" }")
	do %code.WriteLine($Char(9)_"quit tChild")
	quit $$$OK
}

ClassMethod %ConstructIndices(pStartId As %Integer, pEndId As %Integer) As %Status [ CodeMode = objectgenerator ]
{
 Quit $$GenerateConstructIndices^%ocsCache(1)
}

/// Files the indices for all objects whose ID is in the range defined by <var>pStartId</var> and <var>pEndId</var>.
/// If <var>pEndId</var> is null then it defaults to <var>pStartId</var>. If <var>pStartId</var> is null then the
/// range is empty and no filing will occur.
/// 
/// If <var>lockExtent</var> is true then an extent lock will be acquired before the indices
/// are built. If the lock cannot be acquired then an error is returned. The lock is released
/// after the index filing is completed.
/// 
/// 
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SaveIndices(pStartId As %String(MAXLEN="") = "", pEndId As %String(MAXLEN="") = "", lockExtent As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
 Quit $$GenerateIBSaveIndices^%ocsCache(1)
}

}
