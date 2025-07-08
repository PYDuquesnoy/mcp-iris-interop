/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syNLS, SMHEAP)

/// The %SYSTEM.Config.SharedMemoryHeap class provides an interface to return amount of shared memory heap used by InterSystems IRIS instance.<br>
/// It also provides API to get available shared memory heap and recommended shared nemory heap parameter for configuration.
Class %SYSTEM.Config.SharedMemoryHeap Extends %SYSTEM.Help [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// <p>Print out the shared memory heap usage in InterSystems IRIS instance.
ClassMethod DisplayUsage() As %Status [ Final, Internal ]
{
#;SML846+
	s maxcid=..GetMaxConsumerID()
	g:maxcid=0 old
	s skip=13,col=6
	f i=1:1:col s total(i)=0,col(i)=i-1*skip
	s Rset=##class(%ResultSet).%New("%SYSTEM.Config.SharedMemoryHeap:UsageQuery")
 	s Status=Rset.Execute(-1)
 	i $$$ISERR(Status) Q
 	s rc=Rset.Next()
 	q:'rc
 	f i=1:1:col s head(i)=Rset.GetColumnHeader(i+1)
	W !!,$$$Text("Shared Memory Heap Usage in the system"),!
	W !,$$$Text("Legend:")
	W !,$$$Text("Consumer - Subsystem consumed the Shared Memory Heap")
	W !,$$$Text("Alloc SMH/ST - Allocate SMH pages for String Table of specific consumer.")
	W !,$$$Text("SMH/ST Avail - Available space in the allocated SMH pages for String Table.")
	W !,$$$Text("SMH/ST Used - Used space in the allocated SMH pages for String Table.")
	W !,$$$Text("SMT Used - Used space in Static Memory Table by specific consumer.")
	W !,$$$Text("GST Used - Used space in General String Table by specific consumer.")
	W !,$$$Text("All Used - Total used space in SMH/ST, SMT and GST by specific consumer.")
	W !!,$$$Text("Consumer"),":",!
	f i=1:1:col w ?col(i),$j(head(i),skip)
	k x s $p(x,"-",col*skip)="-" w !,x
	s i=1
	do {
		w !,i,") ",Rset.Data("Description"),":",!
		f j=1:1:col s val=Rset.GetData(j+1) w ?col(j),$j(val,skip) s total(j)=total(j)+val
		s i=i+1
	} while (Rset.Next())
	k x s $p(x,"-",col*skip)="-" w !,x
	W !,$$$Text("Grand Total"),!
	f i=1:1:col w ?col(i),$j(head(i),skip)
	w !
	f j=1:1:col w ?col(j),$j(total(j),skip)
	s usage=$system.Config.SharedMemoryHeap.GetUsage($$$CIDInternal)
	f i=1:1:3 s val(i)=$p(usage,",",i)
	w !?col(4),$j($$$Text("SMT Avail"),skip),?col(5),$j($$$Text("GST Avail"),skip),!
	f i=2:1:3 w ?col(i+2),$j(val(i),skip)
	f i=2:1:3 s val(i)=total(i+2)+val(i)
	w !,$j($$$Text("Total SMT&GST Allocated"),skip),?col(4),$j($$$Text("Total SMT"),skip),?col(5),$j($$$Text("Total GST"),skip),!
	w ?col(1),$j(val(1),skip)
	f i=2:1:3 w ?col(i+2),$j(val(i),skip)
	w !,$$$Text("Total SMH pages Allocated"),":",!
	s total=val(1)+total(1)
	w $j(total,skip)," (",total/65536," pages)"
	s totpage=$system.Config.SharedMemoryHeap.MaxCount()
	s avapage=totpage-total
	w !,$$$Text("Total SMH pages Available"),":",!
	w $j(avapage,skip)," (",avapage/65536," pages)"
	w !,$$$Text("Total SMH pages Configured"),":",!
	w $j(totpage,skip)," (",totpage/65536," pages)",!
	q $$$OK
old ;
#;SML846-
	s tot=0
	s audit=$system.Config.SharedMemoryHeap.AuditUsed()
	s class=$system.Config.SharedMemoryHeap.ClassUsed()
	s ddp=$system.Config.SharedMemoryHeap.DDPUsed()
	s gmap=$system.Config.SharedMemoryHeap.GloMapUsed()
	s lic=$system.Config.SharedMemoryHeap.LicenseUsed()
	s misc=$system.Config.SharedMemoryHeap.MiscUsed()
	s nls=$system.Config.SharedMemoryHeap.NLSUsed()
	s perfmon=$system.Config.SharedMemoryHeap.PERFMONUsed()
	s pidtab=$system.Config.SharedMemoryHeap.PIDTableUsed()
	s rtncache=$system.Config.SharedMemoryHeap.RtnCacheUsed()
	s sec=$system.Config.SharedMemoryHeap.SecurityUsed()
	s shdw=$system.Config.SharedMemoryHeap.ShadowUsed()
	s dll=$system.Config.SharedMemoryHeap.SystemDLLUsed()
	s ttyh=$system.Config.SharedMemoryHeap.TTYHashUsed()
	s lock=$system.Config.SharedMemoryHeap.LockUsed()
	s dbext=$system.Config.SharedMemoryHeap.DBEXTUsed()
	s event=$system.Config.SharedMemoryHeap.EVENTUsed()
	s freecnt=$system.Config.SharedMemoryHeap.FreeCount()
	s maxcnt=$system.Config.SharedMemoryHeap.MaxCount()
	
	w !!,$$$Text("Shared Memory Heap used in the system"),":",!
	w !,$$$Text("Audit System"),":",?40,$j(audit,10) s tot=tot+audit
	w !,$$$Text("Classes Instantiated"),":",?40,$j(class,10) s tot=tot+class
	w !,$$$Text("DDP Request Table"),":",?40,$j(ddp,10) s tot=tot+ddp
	w !,$$$Text("Global Mapping"),":"
	s memused=$p(gmap,",",2)+$p(gmap,",",3)+$p(gmap,",",4)
	w !,?5,$$$Text("Memory Used"),"->",?30,$j(memused,10)
	w !,?5,$$$Text("Memory Available"),"->",?30,$j(gmap-memused,10)
	w !,?5,$$$Text("Memory Allocated"),"->",?40,$j(+gmap,10)
	s tot=tot+gmap
	w !,$$$Text("License Upgrade"),":",?40,$j(lic,10) s tot=tot+lic
	w !,$$$Text("Miscellaneous"),":",?40,$j(misc,10) s tot=tot+misc
	w !,$$$Text("National Language Support"),":",?40,$j(nls,10) s tot=tot+nls
	w !,$$$Text("Line By Line Monitor"),":",?40,$j(perfmon,10) s tot=tot+perfmon
	w !,$$$Text("Process Table"),":",?40,$j(+pidtab,10) s tot=tot+pidtab
	w !,$$$Text("Routine Buffer In Use Table"),":"
	s memused=$p(rtncache,",",2)
	w !,?5,$$$Text("Memory Used"),"->",?30,$j(memused,10)
	w !,?5,$$$Text("Memory Available"),"->",?30,$j(rtncache-memused,10)
	w !,?5,$$$Text("Memory Allocated"),"->",?40,$j(+rtncache,10)
	s tot=tot+rtncache
	w !,$$$Text("Security System"),":",?40,$j(sec,10) s tot=tot+sec
	w !,$$$Text("Mirroring"),":",?40,$j(shdw,10) s tot=tot+shdw
	w !,$$$Text("Shared Library"),":",?40,$j(dll,10) s tot=tot+dll
	w !,$$$Text("TTY Hash Table"),":"
	s memused=$p(ttyh,",",2)
	w !,?5,$$$Text("Memory Used"),"->",?30,$j(memused,10)
	w !,?5,$$$Text("Memory Available"),"->",?30,$j(ttyh-memused,10)
	w !,?5,$$$Text("Memory Allocated"),"->",?40,$j(+ttyh,10),!
	s tot=tot+ttyh
	w !,$$$Text("Lock Table"),":"
	s memused=$p(lock,",",2)
	w !,?5,$$$Text("Memory Used"),"->",?30,$j(memused,10)
	w !,?5,$$$Text("Memory Available"),"->",?30,$j(lock-memused,10)
	w !,?5,$$$Text("Memory Allocated"),"->",?40,$j(+lock,10)
	s tot=tot+lock
	w !,$$$Text("General String Table"),":"
	s totg=0
	w !,?5,$$$Text("Multi-Volume Databases Used"),":",?30,$j(dbext,10) s tot=tot+dbext,totg=totg+dbext
	w !,?5,$$$Text("Event system Used"),":",?30,$j(event,10) s tot=tot+event,totg=totg+event
	w !,$$$Text("Total GST Used"),":",?40,$j(totg,10)
	w !,$$$Text("Total Shared Memory Heap Used"),":",?50,$j(tot,10)
	w !!,$$$Text("Shared Memory Heap Available"),":"
	w !,$$$Text("Shared Memory Heap Pages Available"),":",?40,$j($p(freecnt,",",2),10)
	w !,$$$Text("Modify SMT Memory Available"),":",?40,$j($p(freecnt,",",3),10)
	w !,$$$Text("General String Table Memory Available"),":",?40,$j($p(freecnt,",",4),10)
	w !,$$$Text("Total Shared Memory Heap Available"),":",?50,$j(+freecnt,10)
	w !,$$$Text("Total Configured Shared Memory Heap"),":",?50,$j(+maxcnt,10)
	q $$$OK
}

/// <p>Return available shared memory heap in bytes
/// <p>This returns a string in <b>total,pages,smt,genstrtab</b> format.<br>
/// <b>total</b> - total shared memory heap available including <b>pages,smt,genstrtab</b>.<br>
/// <b>pages</b> - total available shared memory heap pages(in bytes).<br>
/// <b>smt</b> - total available memory in SMT table.<br>
/// <b>genstrtab</b> - total available memory in General String Table.<br>
ClassMethod FreeCount() As %String [ CodeMode = expression ]
{
$system.Config.SharedMemoryHeap.FreeCount()
}

/// Return recommended configuration size for specific consumer.
/// The NumProcess argument is for CIDPIDTable consumer to esitmate
/// the memory required for specific maximum number of processes.
ClassMethod GetConfigSize(ConsumerID As %Integer = 0, NumProcess As %Integer = 0) As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetConfigSize(ConsumerID,NumProcess)
}

/// Get description for the specific Consumer.
ClassMethod GetDescription(ConsumerID As %Integer = 0) As %String [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetDescription(ConsumerID)
}

/// Get number of current available SMH pages.
ClassMethod GetFreePage() As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetFreePage()
}

/// Return defined MaxConsumerID value.
ClassMethod GetMaxConsumerID() As %Integer [ Internal ]
{
	s $zt="getMaxConsumerIDErr"
	q $system.Config.SharedMemoryHeap.GetMaxConsumerID()
getMaxConsumerIDErr s $zt="" q 0
}

/// Return number of pages of shared memory heap configured
ClassMethod GetMaxPage() As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetMaxPage()
}

/// Return amount size (in bytes) of each shared memory heap page.
ClassMethod GetPageSize() As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetPageSize()
}

/// Get threshold for specific Surrender stage.
/// The threshold is number of SMH pages.
ClassMethod GetStageThreshold(Stage As %Integer = 1) As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetStageThreshold(Stage)
}

/// Get current Surrender stage.
ClassMethod GetSurrenderStage() As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetSurrenderStage()
}

/// Get/Set threshold for job to coalesce string table.
/// It returns current value before new value is set. If NewValue is not specified threshold is not changed.
ClassMethod JobCoalesceThreshold(NewValue As %Integer) As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.JobCoalesceThreshold(NewValue)
}

/// Get/Set threshold for clean daemon to log coalescing messages.
/// It returns current value before new value is set. If NewValue is not specified threshold is not changed.
ClassMethod DaemonLogThreshold(NewValue As %Integer) As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.DaemonLogThreshold(NewValue)
}

/// Return the current amount of used SMH memory for specific consumer.
/// It returns a string with following information, they are separated by ','.:
/// 	 Total SMH pages allocated.
/// 	 Total SMT memory used.
/// 	 Total GST memory used.
/// 	 Total memory used within the allocated SMH pages.
ClassMethod GetUsage(ConsumerID As %Integer = 0) As %String [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.GetUsage(ConsumerID)
}

/// Return the total SMH memory used, SMH pages allocated and configured SMH memory.
/// It returns a string with following information, they are separated by ',' and all the units are in byte.:<br>
/// 	 Total SMH memory used.<br>
/// 	 Total SMH pages allocated.<br>
/// 	 Total SMH memory configured.
ClassMethod GetUsageSummary() As %String [ Final ]
{
	s Rset=##class(%ResultSet).%New("%SYSTEM.Config.SharedMemoryHeap:UsageQuery")
 	s Status=Rset.Execute(-1)
 	i $$$ISERR(Status) Q ""
 	s rc=Rset.Next()
 	q:'rc ""
 	s smhused=0,smhpageused=0
	do {
		s smhpageused=smhpageused+Rset.Data("Allocated SMH/ST")
		s smhused=smhused+Rset.Data("All Used")
	} while (Rset.Next())
	s usage=$system.Config.SharedMemoryHeap.GetUsage($$$CIDInternal)
	s smhpageused=smhpageused+$p(usage,",",1)
	q smhused_","_smhpageused_","_$system.Config.SharedMemoryHeap.MaxCount()
}

/// Return configured shared memory heap in bytes.
ClassMethod MaxCount() As %Integer [ CodeMode = expression ]
{
$system.Config.SharedMemoryHeap.MaxCount()
}

/// Returns a recommended amount of shared memory heap to be configured in 
/// kilobytes.  This is based on the current utilization of shared memory heap
/// but does not accurately predict future needs. 
ClassMethod RecommendedSize(NumberOfProcess As %Integer = 0) As %Integer [ Deprecated, Final ]
{
#;SML846+
	s maxcid=..GetMaxConsumerID()
	g:maxcid=0 oldSize
	s tot=0
	f i=1:1:maxcid-1 d
	. i i=$$$CIDPIDTable s tot=tot+$system.Config.SharedMemoryHeap.GetConfigSize(i,NumberOfProcess) q
	. s tot=tot+$system.Config.SharedMemoryHeap.GetConfigSize(i)
	s tot=tot+(2*1024*1024*$System.Util.NumberOfCPUs())  ; Add 2 MB per CPU for total growing spaces.
	s tot=tot+65536\65536*64  ; round up to 64 KB boundary and convert to KB unit.
	#;RJF525, no less than 300 MB, which corresponds to the gmheap=0 floor
	s:tot<(300*1204) tot=300*1024
	q tot
oldSize ;
#;SML846-
	s mb=1024*1024
	s maxpid=$G(^|"%SYS"|SYS("LASTMAXPID"))
	if NumberOfProcess=0 s NumberOfProcess=maxpid
	s extra=5*mb
	f i=1:1:$System.Util.NumberOfCPUs()-1 s extra=extra+($s(i>1:2,1:3)*mb)
	s tot=0
	s tot=tot+$system.Config.SharedMemoryHeap.AuditUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.ClassUsed()+mb ;Add 1 MB for growing space.
	s tot=tot+$system.Config.SharedMemoryHeap.DDPUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.GloMapUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.LicenseUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.MiscUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.NLSUsed()
	s perfmon=$system.Config.SharedMemoryHeap.PERFMONUsed()
	s tot=tot+$s(perfmon=0:65536,1:perfmon)
	s tot=tot+$system.Config.SharedMemoryHeap.PIDTableUsed(NumberOfProcess)
	s tot=tot+$system.Config.SharedMemoryHeap.RtnCacheUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.SecurityUsed()
	s shdw=$system.Config.SharedMemoryHeap.ShadowUsed()
	s tot=tot+$s(shdw>extra:shdw-extra,1:0)
	s tot=tot+$system.Config.SharedMemoryHeap.SystemDLLUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.TTYHashUsed()
	s tot=tot+($p($system.Config.SharedMemoryHeap.LockUsed(),",",3)*1.5)
	s tot=tot+$system.Config.SharedMemoryHeap.DBEXTUsed()
	s tot=tot+$system.Config.SharedMemoryHeap.EVENTUsed()
	s tot=tot+(2*mb*$System.Util.NumberOfCPUs())  ; Add 2 MB per CPU for total growing spaces.
	s tot=tot+(mb*$System.Util.NumberOfCPUs())  ; Add 1 MB per CPU for %PARALLEL IPQ space
	s tot=tot+65536\65536*64  ; round up to 64 KB boundary and convert to KB unit.
	q tot
}

/// Set threshold for specific Surrender stage.
/// The threshold is number of SMH pages.
ClassMethod SetStageThreshold(Stage As %Integer = 1, NewVal As %Integer) As %Integer [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.SetStageThreshold(Stage,NewVal)
}

/// This function start Surrender SMH memory for specific or all consumers.
/// ConsumerID = -1 for all consumers. The stage could be 1 or 2.
ClassMethod Surrender(ConsumerID As %Integer = -1, Stage As %Integer = 1) As %Status [ CodeMode = expression, Internal ]
{
$system.Config.SharedMemoryHeap.Surrender(ConsumerID,Stage)
}

/// Return Usage of shared memory heap for each consumer.
Query UsageQuery(ConsumerID As %Integer = -1) As %Query(ROWSPEC = "Description:%String,Allocated SMH/ST:%Integer:Alloc SMH/ST,SMH/ST Available:%Integer:SMH/ST Avail,SMH/ST Used:%Integer,SMT Used:%Integer,GST Used:%Integer,All Used:%Integer")
{
}

ClassMethod UsageQueryExecute(ByRef qHandle As %Binary, ConsumerID As %Integer = -1) As %Status [ Internal ]
{
	s Index=$i($$$ISCQUERYTEMP)
	k $$$ISCQUERYTEMP(Index)
	s maxcid=..GetMaxConsumerID()
	if ConsumerID=-1 {
		s start=$$$CIDMisc,end=maxcid-1
	} elseif (ConsumerID>$$$CIDInternal)&&(ConsumerID<maxcid) {
		s start=ConsumerID,end=ConsumerID
	} else {
		Quit $$$ERROR($$$InvalidArgument)
	}
	for cid=start:1:end {
		s usage=$system.Config.SharedMemoryHeap.GetUsage(cid)
		#;SML1305 ; The usage returned null string means it is deprecated.
		if usage="" continue
		s desc=$system.Config.SharedMemoryHeap.GetDescription(cid)
		s allocsmhst=$p(usage,",")
		s smhstused=$p(usage,",",4)
		s smhstavail=allocsmhst-smhstused
		s smtused=$p(usage,",",2)
		s gstused=$p(usage,",",3)
		s allused=smhstused+smtused+gstused
		s row=$ListBuild(desc,allocsmhst,smhstavail,smhstused,smtused,gstused,allused)
		s $$$ISCQUERYTEMP(Index,cid)=row
	}
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod UsageQueryClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UsageQueryExecute ]
{
	s Index=$p(qHandle,"^",1)
	k $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

ClassMethod UsageQueryFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UsageQueryExecute ]
{
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

/// Return Usage of shared memory heap for each consumer.
Query WebList() As %Query(ROWSPEC = "Description:%String,Allocated SMH/ST:%Integer:Alloc SMH/ST,SMH/ST Available:%Integer:SMH/ST Avail,SMH/ST Used:%Integer,SMT Used:%Integer,GST Used:%Integer,All Used:%Integer")
{
}

ClassMethod WebListExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	s Index=$i($$$ISCQUERYTEMP)
	k $$$ISCQUERYTEMP(Index)
	s maxcid=..GetMaxConsumerID()
	s start=$$$CIDMisc,end=maxcid-1
	for i=1:1:6 s tot(i)=0
	for cid=start:1:end {
		s usage=$system.Config.SharedMemoryHeap.GetUsage(cid)
		#;SML1305 ; The usage returned null string means it is deprecated.
		if usage="" continue
		s desc=$system.Config.SharedMemoryHeap.GetDescription(cid)
		s allocsmhst=$p(usage,","),tot(1)=tot(1)+allocsmhst
		s smhstused=$p(usage,",",4),tot(3)=tot(3)+smhstused
		s smhstavail=allocsmhst-smhstused,tot(2)=tot(2)+smhstavail
		s smtused=$p(usage,",",2),tot(4)=tot(4)+smtused
		s gstused=$p(usage,",",3),tot(5)=tot(5)+gstused
		s allused=smhstused+smtused+gstused,tot(6)=tot(6)+allused
		s row=$ListBuild(desc,allocsmhst,smhstavail,smhstused,smtused,gstused,allused)
		s $$$ISCQUERYTEMP(Index,cid)=row
	}
	s row=$LB("Total") f i=1:1:6 s row=row_$LB(tot(i))
	s $$$ISCQUERYTEMP(Index,cid+1)=row
	s avail=$system.Config.SharedMemoryHeap.GetUsage($$$CIDInternal)
	s row=$LB("Available SMT & GST","","","",$p(avail,",",2),$p(avail,",",3),"")
	s $$$ISCQUERYTEMP(Index,cid+2)=row
	s row=$LB("Total SMT & GST Allocated",$p(avail,","),"","",$p(avail,",",2)+tot(4),$p(avail,",",3)+tot(5),"")
	s $$$ISCQUERYTEMP(Index,cid+3)=row
	s tot=$p(avail,",")+tot(1)
	s row=$LB("Total SMH Pages Allocated",tot_"("_(tot\$system.Config.SharedMemoryHeap.GetPageSize())_")","","","","","")
	s $$$ISCQUERYTEMP(Index,cid+4)=row
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod WebListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = UsageQueryExecute ]
{
	s Index=$p(qHandle,"^",1)
	k $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

ClassMethod WebListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = UsageQueryExecute ]
{
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

}
