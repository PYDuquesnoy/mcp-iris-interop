/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This utility is used to compact bitmap/bitslice indices.  
/// Over time in a volatile table (think lots of INSERTs and DELETEs) the storage for a bitmap index may become less efficient. 
/// To a lesser extent index value changes, i.e. UPDATES, can also degrade bitmap performance.
/// 
/// <p>This utility can by run on a live system.  
/// It will loop over all bitmap/bitslice indices in a class or namespace and compact them by either removing a chunk that is all zeros or by using $BITLOGIC() to compact the bits.
/// 
/// <p>The Utility has 2 entry points:
/// 
/// <example>
/// d ##class(%SYS.Maint.Bitmap).Namespace("Samples",1,1,"2014-01-17 09:00:00")
/// </example>
/// <example>
/// d ##class(%SYS.Maint.Bitmap).OneClass("BitMap.Test",1,1)
/// </example>
/// 
Class %SYS.Maint.Bitmap Extends %Persistent [ Final, StorageStrategy = Default, System = 4 ]
{

/// when the last Compact was started
Property StartTime As %TimeStamp [ SqlColumnNumber = 4 ];

/// Passed in Timestamp for when the compact should stop, NULL for no stop time
/// Set to the time the compaction finshed when done.
Property StopTime As %TimeStamp [ SqlColumnNumber = 5 ];

Property ElapseTime As %Integer [ SqlColumnNumber = 6, SqlComputeCode = {s {*}=$SYSTEM.SQL.DATEDIFF("ss",{StartTime},{StopTime})}, SqlComputed, Transient ];

Property Namespace As %String(MAXLEN = 500) [ SqlColumnNumber = 2 ];

/// Namspace that was compacted
/// Last Class Compacted, if NULL then it finished all the classes.
Property ClassName As %String(MAXLEN = 500) [ SqlColumnNumber = 11 ];

/// Last Index Compacted, if NULL then it finished all the indices.
Property IndexName As %String(MAXLEN = 500) [ SqlColumnNumber = 12 ];

/// count of how many indices were compacted
Property NumberCompressed As %Integer [ InitialExpression = 0, SqlColumnNumber = 7 ];

/// current status of the compaction
/// 		Running -  Compaction is underway
/// 		Stopped -  Compaction reached the Duration limit before finishing all Classes or encountered an error
/// 		Finished - Compaction completed.
Property Status As %String [ SqlColumnNumber = 3 ];

/// Message contains error info and lists of global that were skipped because they where not in the local DB
Property Message As array Of %String(MAXLEN = 30000) [ SqlColumnNumber = 13 ];

Property OldSize As %Integer [ InitialExpression = 0, SqlColumnNumber = 9 ];

Property NewSize As %Integer [ InitialExpression = 0, SqlColumnNumber = 10 ];

Property CompressionAmount As %String [ SqlColumnNumber = 8, SqlComputeCode = { s {*}=$s(+{OldSize}=0:0,1:$FN(1-({NewSize}/{OldSize})*100,"",2)_" %")}, SqlComputed, Transient ];

/// <p>Entry point to compact all bitmaps in a namespace.
/// <br>Each run records its' status in this class
/// <br>If the last run did not finish then it will pick up where it stopped
/// <br>This utility will only Compact globals in the default database
/// <p>Parameters:
/// <ul>
/// <li> 		ns - Namespace you want to compact</li>
/// <li>		NoJournal - Stop journaling for this Process</li>
/// <ul>					
/// <li>					1 to Stop Journaling</li>
/// <li> 					0 to continue Journaling default = 0</li>
/// </ul>
/// <li>		Display - write info to the current device </li>
/// <ul>
/// <li>					1 to write to the device</li>
/// <li>					0 to not write to the device default = 0</li>
/// </ul>
/// <li>		StopTime - Timestamp for when the utility should stop.</li>  
/// <ul>
/// 	<li>					The stop time is tested after each index is finished so it could go over.</li>
/// <li>					A value of NULL means not limit</li>
/// </ul>
/// </ul>
ClassMethod Namespace(ns As %String = "", NoJournal As %Boolean = 0, Display As %Boolean = 0, StopTime As %TimeStamp = "") As %Status [ PublicList = (ClassName, status), SqlProc ]
{
	Set sc=$$$OK
	Try {
		n %ErrorCount,ClassName,status
		$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
		s:ns="" ns=$NAMESPACE
		New $namespace Set $namespace=ns
		s BatchFlag=##class(%SYSTEM.Util).SetBatch(1)
		s StatusObj=##class(%SYS.Maint.Bitmap).%New()
		s StatusObj.StartTime=$ZDT($H,3)
		s StatusObj.Status="Running"
		s StatusObj.StopTime=StopTime
		d StatusObj.%Save()
		If NoJournal && '$$CURRENT^%NOJRN() {
			Set tEnableJournal = 1
			Do DISABLE^%NOJRN
		}
		&SQL(SELECT Status, ClassName INTO :status, :ClassName FROM %SYS_Maint.Bitmap WHERE Namespace = :ns ORDER BY ID Desc)
		if SQLCODE'=0 s ClassName="@"
		if SQLCODE=0,(status="Finished") s ClassName="@"
		f  {
			s ClassName=$O($$$comClassRaw(ClassName))
			QUIT:ClassName=""
			s status=..OneClass(ClassName,NoJournal,Display,,StatusObj)
			if StatusObj.Status="Stopped" s sc=0 QUIT
		}
	}
	Catch exception {
		Set sc = exception.AsStatus()
		s StatusObj.Status="Stopped"
		d StatusObj.Message.SetAt("Compaction Error "_exception.DisplayString(),$i(%ErrorCount))
		d StatusObj.%Save()
		w:Display !,exception.DisplayString()
	}
	
	Try {
		if sc=$$$OK {
			s StatusObj.Status="Finished"
			s StatusObj.StopTime=$ZDT($H,3)
			s StatusObj.ClassName=""
			s StatusObj.IndexName=""
			d StatusObj.%Save()
		}
		d ##class(%SYSTEM.Util).SetBatch(BatchFlag)
		If $g(tEnableJournal) && '$$CURRENT^%NOJRN {
			Do ENABLE^%NOJRN
		}
	}
	Catch {
		w:Display !,$ze
	}
	QUIT sc
}

/// <p>Entry point to compact all bitmaps in one class.
/// <br>Each run records its' status in this class
/// <br>This utility will only Compact globals in the default database
/// <p>Parameters:
/// <ul>
/// <li> 		ClassName - Class you want to compact
/// <li>		NoJournal - Stop journaling for this Process
/// <ul>					
/// <li> 						1 to Stop Journaling
/// <li>						0 to continue Journaling default = 0
/// </ul>
/// <li>		Display - 	write info to the current device 
/// <ul>					
/// <li> 						1 to write to the device
/// <li>						0 to not write to the device default = 0
/// </ul>
/// <li>		StopTime - 	Timestamp for when the utility should stop.  The stop time is tested after each index is finished so it could go over.
/// <ul>					
/// <li> 						a value of NULL means not limit
/// </ul>
/// <li>		StatusObj - This is either passed in from the Namespace Method or is defined in this method.
/// <ul>					
/// <li> 						This value should not be passed in if you are calling this method directly
/// </ul>
/// </ul>
ClassMethod OneClass(ClassName As %String, NoJournal As %Boolean = 0, Display As %Boolean = 0, StopTime As %TimeStamp = "", StatusObj As %RegisteredObject = "") As %Status [ PublicList = (ClassName, IndexName, StorageID, StorageType), SqlProc ]
{
	&SQL(DECLARE storage CURSOR FOR
		SELECT ID1, Type
		INTO :StorageID, :StorageType
		FROM %Dictionary.CompiledStorage
		WHERE parent = :ClassName
		AND Type IN ('%Storage.Persistent','%Storage.SQL')
		AND IndexLocation %STARTSWITH '^')


	Set sc=$$$OK
	Try {
		n IndexName,StorageID,StorageType
		s startflag=0
		i '$IsObject(StatusObj) {
			s startflag=1
			n %ErrorCount
			$$$AddAllRoleTemporaryInTry ; verified 9/26/16 STC
			s StatusObj=##Class(%SYS.Maint.Bitmap).%New()
			s StatusObj.StartTime=$ZDT($H,3)
			s StatusObj.Status="Running"
			s StatusObj.StopTime=StopTime
			d StatusObj.%Save()
			s BatchFlag=##class(%SYSTEM.Util).SetBatch(1)
			If NoJournal && '$$CURRENT^%NOJRN() {
				Set EnableJournal = 1
				Do DISABLE^%NOJRN
			}
		}
		&SQL(OPEN storage)
	   if SQLCODE'<0 {
		&SQL(FETCH storage)
		if SQLCODE=0 {
			s start=$ZDT($H,3)
			w:Display !,"Class:  ",ClassName," Start Time:  ",start
			s QuitFlag=0
			while SQLCODE=0&&(QuitFlag=0)  {
				if $$$SQLStorageIsDefault(StorageType) {
					&SQL(DECLARE index1 CURSOR FOR
						SELECT I.SQLName
						INTO :IndexName
						FROM %Dictionary.CompiledIndex I
						WHERE I.Parent = :ClassName
						AND I.Type IN ('bitmap', 'bitslice', 'bitmapextent'))
					&SQL(OPEN index1)
				  if SQLCODE<0 {
					  s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
					  s QuitFlag=1
				  } else {
					f  {
						&SQL(FETCH index1)
						QUIT:SQLCODE'=0
						s sc=..CompactMap(ClassName,IndexName,Display,StatusObj)
					}
					if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg))) s QuitFlag=1
					&SQL(CLOSE index1)
					if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg))) s QuitFlag=1
				  }
				}
				ELSE {
					&SQL(DECLARE index2 CURSOR FOR
						SELECT I.Name
						INTO :IndexName
						FROM %Dictionary.CompiledStorageSQLMap I
						WHERE I.Parent = :StorageID
						AND I.Type IN ('bitmap', 'bitslice', 'bitmapextent'))
					&SQL(OPEN index2)
				  if SQLCODE<0 {
					  s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
					  s QuitFlag=1
				  } else {
					f  {
						&SQL(FETCH index2)
						QUIT:SQLCODE'=0
						s sc=..CompactMap(ClassName,IndexName,Display,StatusObj)
					}
					if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg))) s QuitFlag=1
					&SQL(CLOSE index2)
					if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg))) s QuitFlag=1
				  }
				}
				if StatusObj.Status="Stopped" s sc=0 QUIT
				&SQL(FETCH storage)
			}
			if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
			w:Display !,"Compression time in seconds:  ",$SYSTEM.SQL.DATEDIFF("ss",start,$ZDT($H,3))
		} elseif SQLCODE<0 {
			s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
		}
		&SQL(CLOSE storage)
		if SQLCODE<0 s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
	   } else {
		   s sc=$$$ADDSC(sc,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
	   }
	}

	Catch exception {
		Set rc=exception.AsStatus()
		Set sc=$$$ADDSC(sc,rc) 
		s StatusObj.Status="Stopped"
		d StatusObj.Message.SetAt("Compaction Error "_exception.DisplayString(),$i(%ErrorCount))
		w:Display !,exception.DisplayString()
	}
	
	Try {
		i startflag {
			if sc=$$$OK {
				s StatusObj.Status="Finished"
				s StatusObj.StopTime=$ZDT($H,3)
				s StatusObj.ClassName=""
				s StatusObj.IndexName=""
			}
			d StatusObj.%Save()
			d ##class(%SYSTEM.Util).SetBatch(BatchFlag)
			If $g(EnableJournal) && '$$CURRENT^%NOJRN {
				Do ENABLE^%NOJRN
			}
		}
	}

	Catch exception {
		Set rc=exception.AsStatus()
		Set sc=$$$ADDSC(sc,rc)
		w:Display !,exception.DisplayString()
	}
	
	QUIT sc
}

ClassMethod CompactMap(ClassName As %String, MapName As %String, Display As %Boolean, StatusObj As %RegisteredObject) As %Status [ Private ]
{
	Try  {
		s sc=$$$OK
		n %NewTotal,%OldTotal,%status
		s results=##class(%SYS.Maint.BitmapResults).%New()
		s results.RunID=StatusObj
		// figure out if the index global is in the local DBl
		set tBase = $LG($$$EXTSQLMAPsqlinfo($$$rEXT,ClassName,MapName),1)
		s tBase=$NAME(@tBase)
		Set source=$$GetGlobalSourceDatabase^%SYS.SECURITY(tBase)
		if $piece(source,"^",2)'="" {
			s results.Status="Global:  "_tBase_" is not local, skipping compression"
			w:Display !,?5,results.Status
			d StatusObj.Message.SetAt(" Global "_tBase_" is not local, skipping compression",$i(%ErrorCount)) 
			d StatusObj.%Save() 
			QUIT
		}
		//figure out the constants and subscripts for the index global
		set ilev="",tPrefix = "",tSubNumber = 1
    	for  {
        	set ilev=$o($$$EXTSQLMAPSUB($$$rEXT,ClassName,MapName,ilev)) quit:ilev=""
        	set mapsubsinfo=$$$EXTSQLMAPSUBsqlinfo($$$rEXT,ClassName,MapName,ilev)
        	if $$$SQLLocMapSubFieldName(mapsubsinfo)=""  {  // If TRUE, this subscript level is a Constant
        		set tPrefix = tPrefix _ $LG($$$EXTSQLMAPSUBsqlinfo($$$rEXT,ClassName,MapName,ilev),2) _ "," 
        	}
        	else {
	        	set tSubNumber = $I(tSubNumber)
        	}
        }		
		set:tPrefix'="" tBase = $Select($Extract(tBase,*)'=")":tBase _ "(",1:$Extract(tBase,1,*-1)_",") _ $Extract(tPrefix,1,*-1)
		s (%OldTotal,%NewTotal)=0
		w:Display !,?5,"Global:  ",tBase_$s(tPrefix="":"",1:")")
		s @("%status=$PREFETCHON("_tBase_")"_$s(tPrefix="":"",1:")"))
		s sc=..CompactGlobal(tBase,tSubNumber,1,.v,Display,StatusObj)
		s @("%status=$PREFETCHOFF("_tBase_")"_$s(tPrefix="":"",1:")"))
		s StatusObj.Namespace=$NAMESPACE
		s StatusObj.ClassName=ClassName
		s StatusObj.IndexName=MapName
		s StatusObj.NumberCompressed=StatusObj.NumberCompressed+1
		s StatusObj.OldSize=StatusObj.OldSize+%OldTotal
		s StatusObj.NewSize=StatusObj.NewSize+%NewTotal

		s results.GlobalName=tBase_")"
		s results.ClassName=ClassName
		s results.OldSize=$FN(%OldTotal/1048576,"",3)
		s results.NewSize=$FN(%NewTotal/1048576,"",3)
		s results.LastCompressed=$ZDT($H,3)
		if %OldTotal=0 {
			s results.Compression=0
		}
		ELSE  {
			s results.Compression=$FN(1-(%NewTotal/%OldTotal)*100,"",2)_"%"
		}
		s results.Status="Finished"
		
		i Display {
			 if +%OldTotal=0 w " was empty"
			 else  w "was compressed:  "_results.Compression,!,?10," Old Size: "_results.OldSize_"(MB) New Size: "_results.NewSize_"(MB)"
		}

		//have we gone past the stop time?
		if (StatusObj.StopTime'=""),($ZDT($H,3) ]] StatusObj.StopTime) {
			s StatusObj.Status="Stopped"
		}
		ELSE {
			s StatusObj.Status="Running"
		}
		d StatusObj.%Save()
		}

	Catch exception {
		Set rc=exception.AsStatus()
		Set sc=$$$ADDSC(sc,rc)
		d StatusObj.Message.SetAt("CompactMap Error "_exception.DisplayString(),$i(%ErrorCount))
		w:Display !,exception.DisplayString()
		s results.Status=exception.DisplayString()
	}
	
	d results.%Save()
	QUIT sc
}

/// <p>  This method compacts any global bitmap
/// <br> Called from CompactMap or CompactMapSQL it takes 3 parameters
/// <ul>					
/// <li>    global  - is the root for this index, for example ^Sample.PersonI("NameIndex")
/// <li>    vars    - is the number of subscripts we need to $ORDER() over
/// <li>    current - is the subscript level we are presently on
/// </ul>
/// <p>  Once we get tot he final subscript level we execute the compat code.
/// 
ClassMethod CompactGlobal(global As %String, vars As %Integer, current As %Integer, ByRef v As %String, Display As %Boolean = 0, StatusObj As %RegisteredObject) As %Status [ Private, PublicList = v ]
{
	Try {	
		s sc=$$$OK
		// recursively call this method to $ORDER() over all the subscripts
		// need to loop over N-1 subscript levels, these will be a mix of constants and variables
		if global["(" {
			s GloRef=global_",v("_current_"))"
		}
		else  {
			s GloRef=global_"(v("_current_"))"
		}

		//if this is the first time in we need to have v(current)=""
		s v(current)=$g(v(current))
		//not sure I need v to be an array anymore.
		If vars=current {
			f  {
				s v(current)=$O(@GloRef,1,bits)
				QUIT:v(current)=""
				if global["(" {
					s GloRef=global_","_$$$QuoteName(v(current))_")"
				}
				else  {
					s GloRef=global_"("_$$$QuoteName(v(current))_")"
				}
				s %OldTotal=%OldTotal+$L(bits)
				// if the chunk is changed by another process $zu(185) will not let it be changed
				// Try to compress the chunk twice
				For i=1:1:2 {
					// if the chunk contains any ones compress it
				    If $bitfind(bits,1) {
					    //$bitlogic will compress the bitmap when it is copied to the new variable
				        Set newb=$bitlogic(bits)
						// No change, go to next chunk
						if newb=bits s %NewTotal=%NewTotal+$L(newb) QUIT
						// Was able to change it, go to next chunk
						if $zu(185,GloRef,bits,newb) s %NewTotal=%NewTotal+$L(newb) QUIT
				    } 
				    // If there are only zeros we can set the chunk to null
				    Else {
				        // Was able to remove it, go to next chunk
						if $zu(185,GloRef,bits) s %OldTotal=%OldTotal+$L(GloRef) QUIT
				    }
				    // Move on to next chunk if already removed
				    Quit:$d(@GloRef,bits)#10=0
				}
			}
		} Else {
			f  {
				s v(current)=$O(@GloRef)
				if v(current)="" k v(current) QUIT
				s sc=..CompactGlobal($e($name(@GloRef),1,*-1),vars,(current+1),.v,Display,StatusObj)	
			}
		}
	}

	Catch exception {
		Set rc=exception.AsStatus()
		Set sc=$$$ADDSC(sc,rc)
		d StatusObj.Message.SetAt("CompactGlobal Error "_exception.DisplayString(),$i(%ErrorCount))
		w:Display !,exception.DisplayString()
	}
	
	QUIT sc
}

Storage Default
{
<Data name="BitmapDefaultData">
<Value name="1">
<Value>StartTime</Value>
</Value>
<Value name="2">
<Value>StopTime</Value>
</Value>
<Value name="3">
<Value>Namespace</Value>
</Value>
<Value name="4">
<Value>ClassName</Value>
</Value>
<Value name="5">
<Value>IndexName</Value>
</Value>
<Value name="6">
<Value>NumberCompressed</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>OldSize</Value>
</Value>
<Value name="9">
<Value>NewSize</Value>
</Value>
</Data>
<Data name="Message">
<Attribute>Message</Attribute>
<Structure>subnode</Structure>
<Subscript>"Message"</Subscript>
</Data>
<DataLocation>^%SYS.Maint.BitmapD</DataLocation>
<DefaultData>BitmapDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%SYS.Maint.BitmapD</IdLocation>
<IndexLocation>^%SYS.Maint.BitmapI</IndexLocation>
<StreamLocation>^%SYS.Maint.BitmapS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
