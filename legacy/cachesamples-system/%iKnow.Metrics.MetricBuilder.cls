/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The <package>%iKnow.Metrics</package> infrastructure is deprecated in favour of the
/// more SQL-oriented approach offered through <class>%iKnow.Tables.Utils</class>, where you
/// can add computed fields at different levels and choose whether they need to be persisted or not.</p>
/// <p>Subclasses of this class should implement at least one of the Calculate***Metrics() 
/// methods in this interface to support calculating custom metrics for the corresponding 
/// target and type. Supported metrics should then register this subclass as their "builder
/// class" in their definition (see <class>%iKnow.Metrics.MetricDefinition</class>).</p>
/// <p>Metric Builder implementations are invoked through their <method>Build</method> or
/// <method>BuildAll</method> methods and will then start building all applicable metrics,
/// forwarding the actual metric calculations to the Calculate***Metrics() implementations
/// (for example, <method>CalculateEntUniMetrics</method> for target $$$IKMTRENTITY and type
/// $$$IKMTRTYPEDOMAIN). Instances of these implementations will be running in parallel if
/// <parameter>SUPPORTSMULTIPROCESS</parameter> is set to 1 (default = 1), or will run
/// single-threaded otherwise.</p>
/// <p>Note: When Calculate***Metrics() methods don't return any values for a particular 
/// target element, the existing metric value is retained (if any). Returning "" for a value
/// will overwrite (erase) the existing value.</p>
Class %iKnow.Metrics.MetricBuilder Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// This parameter indicates whether or not this MetricBuilder implementation supports
/// multiple instances running in parallel to optimize performance. By default, it is
/// set to 1 which means different instances will work in parallel. 
Parameter SUPPORTSMULTIPROCESS As BOOLEAN = 1;

/// Indicates how many entries a process will reserve for itself to calculate per batch
Parameter BATCHSIZE As INTEGER = 1024;

Property DomainId As %Integer [ Final, ReadOnly ];

Property ProcNumber As %Integer [ Final, Internal, ReadOnly ];

Property Type As %String [ Final, ReadOnly ];

Property Target As %String [ Final, ReadOnly ];

Property SrcFilter As %iKnow.Filters.Filter [ Final ];

/// If <property>Type</property> = $$$IKMTRTYPESOURCE, this property contains the current
/// Source ID for which metrics are gathered. To be used from within the metrics calculation
/// methods such as <method>CalculateEntityMetrics</method>.
Property CurrentSrcId As %Integer;

/// If <property>Type</property> = $$$IKMTRTYPEGROUP, this property contains the current
/// Metadata Field ID for which metrics are gathered. To be used from within the metrics calculation
/// methods such as <method>CalculateEntityMetrics</method>.
Property CurrentFieldId As %Integer;

/// If <property>Type</property> = $$$IKMTRTYPEGROUP, this property contains the current
/// Metadata Field name for which metrics are gathered. To be used from within the metrics calculation
/// methods such as <method>CalculateEntityMetrics</method>.
Property CurrentFieldName As %String;

/// If <property>Type</property> = $$$IKMTRTYPEGROUP, this property contains the current
/// Metadata Value ID for which metrics are gathered. To be used from within the metrics calculation
/// methods such as <method>CalculateEntityMetrics</method>.
Property CurrentFieldValueId As %Integer;

/// If <property>Type</property> = $$$IKMTRTYPEGROUP, this property contains the current
/// Metadata Value for which metrics are gathered. To be used from within the metrics calculation
/// methods such as <method>CalculateEntityMetrics</method>.
Property CurrentFieldValue As %String;

Method %OnNew(pDomainId As %Integer, pType As %String, pTarget As %String, pProcNumber As %Integer, pSrcFilter As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	
	$$$IKQFILTEROBJECT(pDomainId,pSrcFilter)
	
	set i%DomainId = pDomainId
	set i%Type = pType
	set i%Target = pTarget
	set i%ProcNumber = pProcNumber
	set i%SrcFilter = pSrcFilter
	
	quit $$$OK
}

/// <p>Builds all the metrics referring this class in their BuilderClass property. See also
/// <method>BuildAll</method>.</p>
ClassMethod Build(pDomainId As %String, pSourceFilter As %iKnow.Filters.Filter = "", pVerbose As %Boolean = 1, pAsync As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		
		set tMetricId = "", tMetrics=""
		for {
			set tMetricId = $order(^IRIS.IK.Mtr.MetricId(pDomainId, tMetricId),1,tMetric)
			quit:tMetricId=""
			
			set:$li(tMetric,3)=$classname() tMetrics = tMetrics _ $lb(tMetricId)
		}
		
		set tSC = ..BuildAll(pDomainId, tMetrics, pSourceFilter, pVerbose, pAsync)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method to be invoked to build all the Metrics for a given domain,
/// optionally limited to a number of metrics specified by ID through <var>pMetrics</var>. It
/// will build a list of all MetricBuilder implementations referred by registered metrics
/// and then run through all targets and types. For each
/// target, it will first invoke all MetricBuilder implementations NOT supporting parallel
/// processing (with <parameter>SUPPORTSMULTIPROCESS</parameter>=0) and then spawn a number of
/// jobs to take care of the ones that can run in parallel. These spawned processes will reserve
/// batches of the target element (for example a batch of entities) and then let all MetricBuilder
/// implementations that support metrics for that target run through them and calculate any
/// metric values using the different Calculate***Metrics() methods.</p>
/// <p>Note: metrics can only be calculated in a domain in which they are already registered.
/// See the Register() method in the <class>%iKnow.Metrics.MetricDefinition</class> class for
/// more details.</p>
ClassMethod BuildAll(pDomainId As %String, pMetrics As %List = "", pSrcFilter As %String = "", pVerbose As %Boolean = 1, pAsync As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKTEMPDOMID(pDomainId,tTempId)
		$$$IKENSURELISTSTR(pMetrics)
		
		// check if the filter is valid
		$$$IKQFILTEROBJECTX(pDomainId,pSrcFilter,tSC)
		set:$isobject(pSrcFilter) pSrcFilter = pSrcFilter.ToString()
		
		// BDB572
		$$$IKDisableJournal(pDomainId)
		
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mtr.MetricId,tSC)
		
		// first build a list of all the MetricBuilder implementations that need to be invoked
		// and the targets they are to support
		if (pAsync) {
			$$$SETMAXJOBS(tMaxJobs,pDomainId,"Metrics",$system.Util.NumberOfCPUs(),tMaxJobsLimit)
		} else {
			set tMaxJobs = 1
		}
		kill tSingleProcBuilders, tGroupBuilders
		kill ^IRIS.Temp.IK.Mtr.Builders(tTempId)
		kill ^IRIS.Temp.IK.Mtr.Index(tTempId)
		kill ^IRIS.Temp.IK.Mtr.Map(tTempId)
		set tMetricId = ""
		for {
			set tMetricId = $order(^IRIS.IK.Mtr.MetricId(pDomainId, tMetricId),1,tMetric)
			quit:tMetricId=""
			continue:(pMetrics'="")&&'$lf(pMetrics,tMetricId)
			
			set tBuilderClass = $lg(tMetric,3), tType = $li(tMetric,2), tName = $li(tMetric,1)
			set:(tBuilderClass'="") tMultiProcess = ##class(%Dictionary.CompiledParameter).%OpenId(tBuilderClass_"||SUPPORTSMULTIPROCESS").Default
			set tTarget = ""
			for { 
				set tTarget = $order(^IRIS.IK.Mtr.MetricTarget(pDomainId, tMetricId, tTarget), 1, tOffset)
				quit:tTarget=""
				
				if (tBuilderClass'="") {
					if 'tMultiProcess || (tMaxJobs=1) {
						set tSingleProcBuilders(tTarget, tType, tBuilderClass, tMetricId) = ""
					}
					set ^IRIS.Temp.IK.Mtr.Builders(tTempId, tTarget, tType, tBuilderClass, tMetricId) = tMetric
					set ^IRIS.Temp.IK.Mtr.Map(tTempId, tTarget, tType, tName) = tOffset
				}
				set:(tType'=$$$IKMTRTYPESOURCE)&&$lg(tMetric,6) ^IRIS.Temp.IK.Mtr.Index(tTempId, $i(^IRIS.Temp.IK.Mtr.Index(tTempId))) = $lb(tMetricId, tTarget)
			}
		}
		
		set tOverallStart = $zh
		w:pVerbose !,$zt($p($h,",",2)),":  Building all metrics..."
		
		
		// metrics are built in a strict order!
		set tIdxProcs = 0
		for tTarget = $$$IKMTRENTITY, $$$IKMTRCRC, $$$IKMTRCC, $$$IKMTRPATH, $$$IKMTRSENTENCE, $$$IKMTRSOURCE {
			
			for tType = $$$IKMTRTYPESOURCE, $$$IKMTRTYPEDOMAIN, $$$IKMTRTYPEGROUP {
				
				
				// now launch multiprocess-enabled ones
				continue:'$d(^IRIS.Temp.IK.Mtr.Builders(tTempId, tTarget, tType))&&'$d(tSingleProcBuilders(tTarget,tType))
				
				set tTTStart = $zh
				write:pVerbose !,$zt($p($h,",",2)),":  	Building metrics for target '",tTarget,"' (",tType,")..."
					
				// first treat non-multiprocess builders
				set tBuilderClass = ""
				for {
					set tBuilderClass = $order(tSingleProcBuilders(tTarget, tType, tBuilderClass))
					quit:tBuilderClass=""
					
					set tSC = ..BuildJob(pDomainId, tType, tTarget, 0, pSrcFilter, tBuilderClass)
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				
				// first prepare bookkeeping globals
				kill ^IRIS.Temp.IK.Mtr.Process(tTempId)
				kill ^IRIS.Temp.IK.Mtr.Ids(tTempId)
					
				// launch BuildMetricJob processes
				if (tMaxJobs>1) {
					for i = 1:1:tMaxJobs {
						job ..BuildJob(pDomainId, tType, tTarget, i, pSrcFilter)::10
						if '$test {
							// BDB633 - if we cannot launch any more processes, just do with i-1
							set tMaxJobs = i-1
							quit
						}
					}
					quit:$$$ISERR(tSC)
					
					// wait for processes to finish
					while 1 {
						quit:$bitcount(^IRIS.Temp.IK.Mtr.Process(tTempId),1)=tMaxJobs
						hang 1
					}
					
					// check if they ran fine
					for i = 1:1:tMaxJobs {
						set tSC = $g(^IRIS.Temp.IK.Mtr.Process(tTempId,i))
						quit:$$$ISERR(tSC)
					}
				} else {
					set tSC = ..BuildJob(pDomainId, tType, tTarget, 1, pSrcFilter)
				}
				quit:$$$ISERR(tSC)
				
				$$$IKQDURATION($zh-tTTStart,tDuration)
				write:pVerbose !,$zt($p($h,",",2)),":  	Finished building metrics for target '",tTarget,"' (",tType,") with ",tBuilderClass," in ",tDuration
			
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		$$$IKQDURATION($zh-tOverallStart,tDuration)
		write:pVerbose !,$zt($p($h,",",2)),":  Finished building all metrics in "_tDuration
		
		// now build indices
		quit:'$d(^IRIS.Temp.IK.Mtr.Index(tTempId))
			
		set tIDXStart = $zh
		write:pVerbose !,$zt($p($h,",",2)),":  	Building all indices..."
		
		kill ^IRIS.Temp.IK.Mtr.Process(tTempId)
		if (tMaxJobs <= 1) {
			
			set tSC = ..BuildIndexJob(pDomainId, 0)
			quit:$$$ISERR(tSC)
			
		} else {
				
			// launch BuildIndexJob processes
			for i = 1:1:tMaxJobs {
				job ..BuildIndexJob(pDomainId, i)::10
				if '$test {
					// BDB633 - if we cannot start any more processes, just do with i-1
					set tMaxJobs = i-1
					quit
				}
			}
			quit:$$$ISERR(tSC)
			
			// wait for processes to finish
			while 1 {
				quit:$bitcount(^IRIS.Temp.IK.Mtr.Process(tTempId),1)=tMaxJobs
				hang 1
			}
			
			// check if they ran fine
			for i = 1:1:tMaxJobs {
				set tSC = $g(^IRIS.Temp.IK.Mtr.Process(tTempId,i))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		$$$IKQDURATION($zh-tIDXStart,tDuration)
		write:pVerbose !,$zt($p($h,",",2)),":  	Finished building all indices in "_tDuration
		
		$$$IKQDURATION($zh-tOverallStart,tDuration)
		write:pVerbose !,$zt($p($h,",",2)),":  Finished building all metrics and indices in ",tDuration
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	kill ^IRIS.Temp.IK.Mtr.Process(tTempId)
	kill ^IRIS.Temp.IK.Mtr.Ids(tTempId)
	kill ^IRIS.Temp.IK.Mtr.Map(tTempId)
	kill ^IRIS.Temp.IK.Mtr.Builders(tTempId)
	kill ^IRIS.Temp.IK.Mtr.Index(tTempId)
	
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mtr.MetricId)
	
	$$$IKRestoreJournal // BDB572
	
	quit tSC
}

/// Method called internally to build the metrics for a specific target type.
ClassMethod BuildJob(pDomainId As %String, pType As %String, pTarget As %String, pProcNumber As %Integer, pSrcFilter As %String = "", pBuilderClass As %String = "") As %Status [ Final, Internal ]
{
	#define InvokeBuildersSet(%prop,%val) if (pProcNumber) { for i = 1:1:tBuilder { set tBuilder(i).%prop = %val } } else { set tBuilder.%prop = %val }
	#define InvokeBuilders(%method,%params)	if (pProcNumber) { for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%params)  quit:$$$ISERR(tSC) } } else { set tSC = tBuilder.%method(%params) } quit:$$$ISERR(tSC)
	#define InvokeBuilders2(%method,%p1,%p2)	if (pProcNumber) { for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,%p2)  quit:$$$ISERR(tSC) } } else { set tSC = tBuilder.%method(%p1,%p2) } quit:$$$ISERR(tSC)
	#define CalcMetrics1(%method,%p1)	if (pProcNumber) { kill tValues  for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,.tVal)  quit:$$$ISERR(tSC)  merge tValues = tVal } } else { set tSC = tBuilder.%method(%p1,.tValues) } quit:$$$ISERR(tSC)
	#define CalcMetrics2(%method,%p1,%p2)	if (pProcNumber) { kill tValues  for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,%p2,.tVal)  quit:$$$ISERR(tSC)  merge tValues = tVal } } else { set tSC = tBuilder.%method(%p1,%p2,.tValues) } quit:$$$ISERR(tSC)
	#define CalcMetrics3(%method,%p1,%p2,%p3)	if (pProcNumber) { kill tValues  for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,%p2,%p3,.tVal)  quit:$$$ISERR(tSC)  merge tValues = tVal } } else { set tSC = tBuilder.%method(%p1,%p2,%p3,.tValues) } quit:$$$ISERR(tSC)
	#define CalcMetrics4(%method,%p1,%p2,%p3,%p4)	if (pProcNumber) { kill tValues  for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,%p2,%p3,%p4,.tVal)  quit:$$$ISERR(tSC)  merge tValues = tVal } } else { set tSC = tBuilder.%method(%p1,%p2,%p3,%p4,.tValues) } quit:$$$ISERR(tSC)
	#define CalcMetrics5(%method,%p1,%p2,%p3,%p4,%p5)	if (pProcNumber) { kill tValues  for i = 1:1:tBuilder { set tSC = tBuilder(i).%method(%p1,%p2,%p3,%p4,%p5,.tVal)  quit:$$$ISERR(tSC)  merge tValues = tVal } } else { set tSC = tBuilder.%method(%p1,%p2,%p3,%p4,%p5,.tValues) } quit:$$$ISERR(tSC)
	#define AppendValues(%idx)	set m=""  for {  ##continue
									set m = $order(tValues(m),1,tValue) quit:m="" ##continue
									set o = $g(tMetricMap(m)) continue:'o ##continue
									set $li(@gMetricValues@(%idx),o) = tValue ##continue
								}
	
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(pDomainId,tTempId)
		
		// BDB572 - if this is an async job, make sure we respect journalling settings for this
		// domain. No need to restore them afterwards, as either the process will end (async) or
		// it will be restored appropriately from the calling BuildAll() method.
		if pProcNumber {
			$$$IKDisableJournal(pDomainId)
		}
		
		/// turn the filter into an object again
		$$$IKQFILTEROBJECTX(pDomainId,pSrcFilter,tSC)
		
		// check if we'll have the ^IRIS.IK.PathId global (if required)
		if (pTarget=$$$IKMTRPATH) {
			set tUsePathId = $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONOPTIONALGLOBALS)
			if 'tUsePathId {
				$$$IKBFLAGS(pDomainId,tFlags)
				set tFlag = $a(tFlags,$$$IKBPATH)
				if (tFlag = $$$IKBFALWAYS) || ((tFlag'=$$$IKBFNEVER) && $$$IKBUPTODATE(pDomainId)) { 
					set tUsePathId = 1 
				}
			}
		}
		
		if (pProcNumber=0) {
			
			// if we're in single-process mode, instantiate one builder class
			set tBuilder = $classmethod(pBuilderClass,"%New", pDomainId, pType, pTarget, pProcNumber, pSrcFilter)
			
			if (pType = $$$IKMTRTYPEGROUP) {
				set tMetricId = ""
				for {
					set tMetricId = $order(^IRIS.Temp.IK.Mtr.Builders(tTempId, pTarget, pType, pBuilderClass, tMetricId), 1, tMetric)
					quit:tMetricId=""
					
					set tGroups($li(tMetric,7)) = ""
				}
			}
			
		} else {
			
			// otherwise, instantiate one for every entry in the builder map
			set tBuilderClass = "", tBuilder=0
			for {
				set tBuilderClass = $order(^IRIS.Temp.IK.Mtr.Builders(tTempId, pTarget, pType, tBuilderClass))
				quit:tBuilderClass=""
				
				set tBuilder($i(tBuilder)) = $classmethod(tBuilderClass, "%New", pDomainId, pType, pTarget, pProcNumber, pSrcFilter)
				
				if (pType = $$$IKMTRTYPEGROUP) {
					set tMetricId = ""
					for {
						set tMetricId = $order(^IRIS.Temp.IK.Mtr.Builders(tTempId, pTarget, pType, tBuilderClass, tMetricId), 1, tMetric)
						quit:tMetricId=""
						
						set tGroups($li(tMetric,7)) = ""
					}
				}
			}
		}
		
		$$$InvokeBuilders(OnBeforeBuildMetrics, )
		
		kill tMetricMap
		merge tMetricMap = ^IRIS.Temp.IK.Mtr.Map(tTempId, pTarget, pType)
		
		if (pType = $$$IKMTRTYPEGROUP) {
			
			// loop through all metadata fields for which we have metrics
			set tFieldName = ""
			for {
				set tFieldName = $order(tGroups(tFieldName)) 
				quit:tFieldName=""
				
				set tFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(pDomainId, tFieldName, .tSC)
				quit:$$$ISERR(tSC)
				set tFieldInfo = $g(^IRIS.IK.Mdt.FieldId(pDomainId,tFieldId))
				set tStorage = $li(tFieldInfo,4), tFieldName = $li(tFieldInfo,1)
				$$$InvokeBuildersSet(CurrentFieldId,tFieldId)
				$$$InvokeBuildersSet(CurrentFieldName,tFieldName)
				
				set gSrcByValue = "^IRIS.IK.Mdt.UniValueToSrc"_$s(tStorage=$$$MDSTCOMPRESSBITMAP:"Bit", 1:"")_"("_pDomainId_","_tFieldId_")"
				
				// now consider each unique value ID for that metadata field as an independent batch
				set tUniValueId = ""
				for {
					set tUniValueId = $order(@gSrcByValue@(tUniValueId))
					quit:tUniValueId=""
					
					if (pProcNumber) {
						// check if this value is already booked
						continue:$d(^IRIS.Temp.IK.Mtr.Ids(tTempId,tFieldId,tUniValueId))
						
						// if not, try to lock it
						lock +^IRIS.Temp.IK.Mtr.Ids(tTempId,tFieldId):5
						if '$test {
							set tSC = $$$ERROR($$$IKFailedLockDomain, pDomainId)
							quit
						}
						
						// double-check if not booked in the meantime
						if $d(^IRIS.Temp.IK.Mtr.Ids(tTempId,tFieldId,tUniValueId)) {
							lock -^IRIS.Temp.IK.Mtr.Ids(tTempId,tFieldId)
							continue
						}
					
						set ^IRIS.Temp.IK.Mtr.Ids(tTempId, tFieldId, tUniValueId) = $j
						lock -^IRIS.Temp.IK.Mtr.Ids(tTempId,tFieldId)
					}
					
					// now that we're sure this process is the only one looking at this
					// tFieldId-tUniValueId pair, process all sources within
					$$$InvokeBuildersSet(CurrentFieldValueId,tUniValueId)
					set tUniValue = $g(^IRIS.IK.Mdt.UniValueId(pDomainId,tUniValueId))
					$$$InvokeBuildersSet(CurrentFieldValue,tUniValue)
					
					kill ^||%IK.Mtr.TargetIds
					set gMetricValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId,pType,pTarget,tUniValueId)
					$$$InvokeBuilders(OnBeforeBuildMetricsForGroup, )
					
					if (tStorage = $$$MDSTCOMPRESS) {
						set tSrcId = $s($isobject(pSrcFilter):pSrcFilter.GetFirstFilteredSource()-1, 1:"")
					} else {
						set tSrcOff = $s($isobject(pSrcFilter):pSrcFilter.GetNextSourceFilterOffset("")-1, 1:"")
						set tSrcPos = 0, tSrcBits = ""
					}
					for {
						if (tStorage = $$$MDSTCOMPRESS) {
							set tSrcId = $order(@gSrcByValue@(tUniValueId,tSrcId))
							quit:tSrcId=""
							continue:$isobject(pSrcFilter)&&'pSrcFilter.IsFiltered(tSrcId)
						} else {
							set tSrcPos = $bitfind(tSrcBits, 1, tSrcPos+1)
							if 'tSrcPos {
								set tSrcOff = $order(@gSrcByValue@(tUniValueId,tSrcOff), 1, tSrcBits)
								quit:tSrcOff=""
								set:$isobject(pSrcFilter) tFilterBits = pSrcFilter.GetSourceFilter(tSrcOff), tSrcBits = $bitlogic(tSrcBits & tFilterBits)
								set tSrcPos = 0
								continue
							}
							$$$IKGETIDOFFPOS(tSrcId,tSrcOff,tSrcPos)
						}
						
						// now line up the target IDs we'd have to run through
						if (pTarget = $$$IKMTRENTITY) || (pTarget = $$$IKMTRCRC) || (pTarget = $$$IKMTRCC) {
							
							// for unique elements, first build a bitmap which we'll run
							// through after completing the whole group
							set gTargetIdBit = "^IRIS.IK.SrcTo"_$case(pTarget, $$$IKMTRENTITY:"Ent", $$$IKMTRCRC:"Crc", $$$IKMTRCC:"Cc")_"Bit("_pDomainId_","_tSrcId_")"
							$$$IKMERGEBITSOR(gTargetIdBit,"^||%IK.Mtr.TargetIds")
						
						} elseif (pTarget = $$$IKMTRPATH) {
							
							// paths and sentences can be processed now
							set tSrcInfo = ^IRIS.IK.SrcDetails(pDomainId,tSrcId)
							set tTargetIdFrom = $li(tSrcInfo, 7) + 1
							set tTargetIdTo = tTargetIdFrom + $li(tSrcInfo, 8) - 1
							
							for tPathId = tTargetIdFrom:1:tTargetIdTo {
								kill tValues
								if tUsePathId {
									set tData = ^IRIS.IK.PathId(pDomainId,tPathId)
								} else {
									set tData = ^IRIS.IK.PathToEntOcc(pDomainId, tPathId)
									set l = $ll(tData)
									for ii = 1:1:l {
										set $li(tData,ii) = $lg(^IRIS.IK.EntOccId(pDomainId,$li(tData,ii)),1)
									}
								}
								$$$CalcMetrics1(CalculatePathMetrics,tPathId)
								$$$AppendValues(tPathId)
							}
							
						} elseif (pTarget = $$$IKMTRSENTENCE) {
							
							// paths and sentences can be processed now
							set tSrcInfo = ^IRIS.IK.SrcDetails(pDomainId,tSrcId)
							set tTargetIdFrom = $li(tSrcInfo, 1) + 1
							set tTargetIdTo = tTargetIdFrom + $li(tSrcInfo, 2) - 1
							
							for tSentId = tTargetIdFrom:1:tTargetIdTo {
								kill tValues
								set tData = ^IRIS.IK.SentDetails(pDomainId,tSentId)
								$$$CalcMetrics1(CalculateSentenceMetrics,tSentId)
								$$$AppendValues(tSentId)
							}
							
						} else { // pTarget = $$$IKMTRSOURCE
							
							kill tValues
							$$$CalcMetrics1(CalculateSourceMetrics,tSrcId)
							$$$AppendValues(tSrcId)
							
						}
					}
						
					// loop through target IDs and calculate metrics
					if (pTarget=$$$IKMTRENTITY) || (pTarget=$$$IKMTRCRC) || (pTarget=$$$IKMTRCC) {
						set tOff = ""
						for {
							set tOff = $order(^||%IK.Mtr.TargetIds(tOff), 1, tBits)
							quit:tOff=""
							
							set tPos = 0
							for {
								set tPos = $bitfind(tBits,1,tPos+1)
								quit:tPos=0
								
								$$$IKGETIDOFFPOS(tId,tOff,tPos)
								
								kill tValues
								if (pTarget = $$$IKMTRENTITY) {
									set tData = ^IRIS.IK.EntUniId(pDomainId, tId)
									$$$CalcMetrics2(CalculateEntUniMetrics,tId,tData)
								} elseif (pTarget = $$$IKMTRCRC) {
									set tData = ^IRIS.IK.CrcUniId(pDomainId, tId)
									$$$CalcMetrics4(CalculateCrcUniMetrics,tId,$lg(tData,1),$lg(tData,2),$lg(tData,3))
								} elseif (pTarget = $$$IKMTRCC) {
									set tData = ^IRIS.IK.CcUniId(pDomainId, tId)
									$$$CalcMetrics3(CalculateCcUniMetrics,tId, $lg(tData,1), $lg(tData,2))
								}
								$$$AppendValues(tId)
							}
						}
					}
					
					$$$InvokeBuilders(OnAfterBuildMetricsForGroup, )
					$$$InvokeBuildersSet(CurrentFieldValue,"")
					$$$InvokeBuildersSet(CurrentFieldValueId,"")
				}
				
				quit:$$$ISERR(tSC)
			}
			
		} elseif (pType=$$$IKMTRTYPESOURCE) || (pTarget=$$$IKMTRPATH) || (pTarget=$$$IKMTRSENTENCE) || (pTarget=$$$IKMTRSOURCE) {
			
			set tHasTrueSrcIndex = (pTarget=$$$IKMTRENTITY) || (pTarget=$$$IKMTRCRC) || (pTarget=$$$IKMTRCC)
			if tHasTrueSrcIndex {
				set gTargetInSrc = "^IRIS.IK." _ $case(pTarget, $$$IKMTRENTITY:"Ent", $$$IKMTRCRC:"Crc", $$$IKMTRCC:"Cc") _ "SrcDetails"
			} else {
				set gTargetInSrc = "^IRIS.IK." _ $case(pTarget, $$$IKMTRSENTENCE:"SentDetails", $$$IKMTRPATH:$s(tUsePathId:"PathId", 1:"PathToEntOcc"), $$$IKMTRSOURCE:"SrcId")
			}
			
			set tMaxId = $o(^IRIS.IK.SrcId(pDomainId,""),-1)
			set tBatchSize = $s(..#BATCHSIZE>100:..#BATCHSIZE\10, 1:..#BATCHSIZE)
			
			while 1 {
				// reserve next batch of sources
				set tTo = $i(^IRIS.Temp.IK.Mtr.Ids(tTempId), tBatchSize), tFrom = tTo-..#BATCHSIZE
				quit:tFrom>tMaxId
			
				// loop over entries
				set tSrcId = tFrom-1
				for {
					set tSrcId = $order(^IRIS.IK.SrcDetails(pDomainId,tSrcId),1,tSrcDetails)
					quit:tSrcId=""
					quit:tSrcId>tTo
					
					continue:$isobject(pSrcFilter)&&'pSrcFilter.IsFiltered(tSrcId)
					
					$$$InvokeBuildersSet(CurrentSrcId,tSrcId)
					$$$InvokeBuilders(OnBeforeBuildMetricsForSource,tSrcId)
				
					set gMetricValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId,pType,pTarget,tSrcId)
					
					// treat sources differently
					if (pTarget=$$$IKMTRSOURCE) {
						
						$$$CalcMetrics1(CalculateSourceMetrics,tSrcId)
						$$$AppendValues(tSrcId)
						
						continue
					}
					
					// for the elements within sources, loop through them
					if tHasTrueSrcIndex {
						set tId = ""
					} else {
						set tId = $li(tSrcDetails, $case(pTarget, $$$IKMTRSENTENCE:1, $$$IKMTRPATH:7))
						set tMaxIdForSrc = tId + $li(tSrcDetails, $case(pTarget, $$$IKMTRSENTENCE:2, $$$IKMTRPATH:8))
					}
					for {
						if (tHasTrueSrcIndex) {
							set tId = $order(@gTargetInSrc@(pDomainId, tSrcId, tId))
							quit:tId=""
						} else {
							set tId = $order(@gTargetInSrc@(pDomainId, tId), 1, tData)
							quit:tId=""
							quit:tId>tMaxIdForSrc
						}
						
						kill tValues
						if (pTarget = $$$IKMTRENTITY) {
							set tData = ^IRIS.IK.EntUniId(pDomainId, tId)
							$$$CalcMetrics2(CalculateEntUniMetrics,tId,tData)
						} elseif (pTarget = $$$IKMTRCRC) {
							set tData = ^IRIS.IK.CrcUniId(pDomainId, tId)
							$$$CalcMetrics4(CalculateCrcUniMetrics,tId,$lg(tData,1),$lg(tData,2),$lg(tData,3))
						} elseif (pTarget = $$$IKMTRCC) {
							set tData = ^IRIS.IK.CcUniId(pDomainId, tId)
							$$$CalcMetrics3(CalculateCcUniMetrics,tId, $lg(tData,1), $lg(tData,2))
						} elseif (pTarget = $$$IKMTRPATH) {
							if 'tUsePathId {
								set l = $ll(tData)
								for ii = 1:1:l {
									set $li(tData,ii) = $lg(^IRIS.IK.EntOccId(pDomainId,$li(tData,ii)),1)
								}
							}
							$$$CalcMetrics2(CalculatePathMetrics,tId,tData)
						} elseif (pTarget = $$$IKMTRSENTENCE) {
							$$$CalcMetrics1(CalculateSentenceMetrics,tId)
						}
						quit:$$$ISERR(tSC)
				
						// as there's no other processes working with this tId at the same time,
						// we can write the values straight away
						$$$AppendValues(tId)
					}
					
					$$$InvokeBuilders(OnAfterBuildMetricsForSource,tSrcId)
					$$$InvokeBuildersSet(CurrentSrcId,"")
					quit:tId=tTo
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)

		} else {
			
			set gTargetIds = "^IRIS.IK." _ $case(pTarget, $$$IKMTRENTITY:"Ent", $$$IKMTRCRC:"Crc", $$$IKMTRCC:"Cc") _ "UniId"
			set gMetricValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId,pType,pTarget)
			set tMaxId = $o(@gTargetIds@(pDomainId,""),-1)
		
			while 1 {
				// reserve next batch
				set tTo = $i(^IRIS.Temp.IK.Mtr.Ids(tTempId), ..#BATCHSIZE), tFrom = tTo-..#BATCHSIZE
				quit:tFrom>tMaxId
				
				$$$InvokeBuilders2(OnBeforeBuildMetricsBatch,tFrom,tTo)
				
				// loop over entries
				set tId = tFrom-1
				for {
					set tId = $order(@gTargetIds@(pDomainId,tId),1,tData)
					quit:tId=""
					quit:tId>tTo
				
					kill tValues
					if (pTarget = $$$IKMTRENTITY) {
						$$$CalcMetrics2(CalculateEntUniMetrics,tId,tData)
					} elseif (pTarget = $$$IKMTRCRC) {
						$$$CalcMetrics4(CalculateCrcUniMetrics,tId,$lg(tData,1),$lg(tData,2),$lg(tData,3))
					} elseif (pTarget = $$$IKMTRCC) {
						$$$CalcMetrics3(CalculateCcUniMetrics,tId,$lg(tData,1),$lg(tData,2))
					}
					quit:$$$ISERR(tSC)
				
					// as there's no other processes messing with this tId at the same time,
					// we can write the values straight away
					$$$AppendValues(tId)
				
					quit:tId=tTo
				}
				quit:$$$ISERR(tSC)
				
				$$$InvokeBuilders2(OnAfterBuildMetricsBatch,tFrom, tTo)
			}
			quit:$$$ISERR(tSC)
		}
		
		$$$InvokeBuilders(OnAfterBuildMetrics, )
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if (pProcNumber) {
		set ^IRIS.Temp.IK.Mtr.Process(tTempId,pProcNumber) = tSC
		set $bit(^IRIS.Temp.IK.Mtr.Process(tTempId),pProcNumber) = 1
	}
	quit tSC
}

/// Method called internally to build an index for a specific Metric and target
ClassMethod BuildIndexJob(pDomainId As %Integer, pProcNumber As %Integer) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(pDomainId,tTempId)
		
		for {
			set tIndexId = $i(^IRIS.Temp.IK.Mtr.Index(tTempId),-1)+1
			quit:tIndexId<=0
			
			set tInfo = ^IRIS.Temp.IK.Mtr.Index(tTempId, tIndexId)
			
			set tSC = ..BuildIndex(pDomainId, $li(tInfo,1), $li(tInfo,2))
			quit:$$$ISERR(tSC)
			
			kill ^IRIS.Temp.IK.Mtr.Index(tTempId, tIndexId)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if pProcNumber {
		set ^IRIS.Temp.IK.Mtr.Process(tTempId,pProcNumber) = tSC
		set $bit(^IRIS.Temp.IK.Mtr.Process(tTempId),pProcNumber) = 1
	}
	
	quit tSC
}

/// <p>This method builds an index for a particular Metric and Target.</p>
/// <p>Note: no indices will be built for metrics of type $$$IKMTRTYPESOURCE, as these
/// intra-source entries will be sorted on the fly when calling any applicable sorted queries.</p>
ClassMethod BuildIndex(pDomainId As %Integer, pMetricId As %Integer, pTarget As %String) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		
		$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
		quit:'$d(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, pTarget), tOffset)
		
		set tType = $li(tMetric,2)
		quit:tType=$$$IKMTRTYPESOURCE
			
		set x = $sortbegin(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId))
		set tTarget = $$$IKMTRTARGETID(pTarget)
		
		if (tType = $$$IKMTRTYPEDOMAIN) {
				
			set tId = "", gValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId,tType,pTarget)
			for {
				set tId = $order(@gValues@(tId),1,tData)
				quit:tId=""
				
				set tScore = $lg(tData, tOffset)
				set:tScore'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, -tScore, tTarget, tId) = ""
			}
			
		} else { // tType = $$$IKMTRTYPEGROUP
			
			set tContext = ""	, gValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId,tType,pTarget)
			for {
				set tContext = $order(@gValues@(tContext))
				quit:tContext=""
				
				set tId = ""
				for {
					set tId = $order(@gValues@(tContext, tId),1,tData)
					quit:tId=""
					
					set tScore = $lg(tData, tOffset)
					set:tScore'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, -tScore, tTarget, tId) = tContext
				}
			}
		}
		
		set x = $sortend(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId))
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called before a MetricBuilder instance starts building any metrics, in which
/// custom code can be executed to set up any auxiliary objects or data structures.</p>
/// <p>Note: depending on the value of <parameter>SUPPORTSMULTIPROCESS</parameter>, multiple
/// MetricBuilder instances can be running alongside one another</p>
Method OnBeforeBuildMetrics() As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called after a MetricBuilder instance starts building any metrics, in which
/// custom code can be executed to clean up any auxiliary objects or data structures.</p>
/// <p>Note: depending on the value of <parameter>SUPPORTSMULTIPROCESS</parameter>, multiple
/// MetricBuilder instances can be running alongside one another</p>
Method OnAfterBuildMetrics() As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called before a MetricBuilder instance starts building any metrics for the
/// source identified by <var>pSrcId</var>, for metrics of type $$$IKMTRTYPESOURCE.</p>
Method OnBeforeBuildMetricsForSource(pSrcId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called after a MetricBuilder starts building any metrics for the
/// source identified by <var>pSrcId</var>, for metrics of type $$$IKMTRTYPESOURCE.<p>
Method OnAfterBuildMetricsForSource(pSrcId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called before a MetricBuilder instance starts building any metrics for the
/// group identified by <property>CurrentFieldName</property> and <property>CurrentFieldValue</property>,
/// for metrics of type $$$IKMTRTYPEGROUP.</p>
Method OnBeforeBuildMetricsForGroup() As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called after a MetricBuilder instance finishes building any metrics for the
/// group identified by <property>CurrentFieldName</property> and <property>CurrentFieldValue</property>,
/// for metrics of type $$$IKMTRTYPEGROUP.</p>
Method OnAfterBuildMetricsForGroup() As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called before a MetricBuilder starts building any metrics for a batch
/// of elements, for metrics of type $$$IKMTRTYPEDOMAIN</p>
Method OnBeforeBuildMetricsBatch(pFrom As %Integer, pTo As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Utility method called after a MetricBuilder starts building any metrics for a batch
/// of elements, for metrics of type $$$IKMTRTYPEDOMAIN</p>
Method OnAfterBuildMetricsBatch(pFrom As %Integer, pTo As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting entities. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given unique entity <var>pEntUniId</var>, this method should calculate all metrics
/// it knows about and return them through <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculateEntUniMetrics(pEntUniId As %Integer, pEntUniValue As %String, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting CRCs. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given unique CRC <var>pCrcUniId</var>, this method should calculate all metrics
/// it knows about and return them through <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculateCrcUniMetrics(pCrcUniId As %Integer, pHeadId As %Integer, pRelationId As %Integer, pTailId As %Integer, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting CCs. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given unique CC <var>pCcUniId</var>, this method should calculate all metrics
/// it knows about and return them through <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculateCcUniMetrics(pCcUniId As %Integer, pHeadId As %Integer, pTailId As %Integer, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting Paths. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given path <var>pPathId</var>, this method should calculate all metrics
/// it knows about and return them through <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculatePathMetrics(pPathId As %Integer, pEntities As %List, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting sentences. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given sentence <var>pSentenceId</var>, this method should calculate all metrics
/// it knows about and return them through <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculateSentenceMetrics(pSentenceId As %Integer, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This is the main method a custom MetricBuilder should implement to support metrics
/// targeting sources. Depending on the value of <property>Type</property>, the properties
/// <property>CurrentSrcId</property> (for $$$IKMTRTYPESOURCE), <property>CurrentFieldName</property>
/// and <property>CurrentFieldValue</property> (for $$$IKMTRTYPEGROUP) or neither of these
/// (for $$$IKMTRTYPEDOMAIN) will define the scope for which metrics should be calculated.</p>
/// <p>For a given source <var>pSourceId</var> in the context of a given source <var>pSrcId</var>,
/// this method should calculate all metrics it knows about and return them through
/// <var>pValues</var> in an array indexed by metric name:
/// 			pValues(<i>metricName</i>) = value </p>
Method CalculateSourceMetrics(pSourceId As %Integer, Output pValues) As %Status
{
	set tSC = $$$OK
	try {
		kill pValues
		
		// custom code goes here
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
