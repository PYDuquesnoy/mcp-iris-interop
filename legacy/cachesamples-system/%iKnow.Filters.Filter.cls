/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %IKPublic)

///  <p>This is the base class for iKnow Filter objects, restricting the scope of an iKnow Query
///  to a subset of all the sources in a domain through filter criteria based on the properties of
///  a Source. These criteria are expressed through a number of <b>Filter Parameters</b> which should
///  be passed as arguments to the <method>%New</method> method when instantiating a filter object. 
///  Typically, the first Filter Parameter is the Domain ID of the domain of which sources are to
///  be filtered.</p>
///  <p>Filters have a <b>String Representation</b> so they can be passed around in non-object
///  environments such as SQL and SOAP. Subclasses should therefore provide an unambiguous
///  implementation for <method>ToString</method>, serializing its Filter Parameters so the string can
///  be passed around and then <var>deserialized</var> through the <method>RestoreFilterFromString</method>
///  method. See also <method>CreateAsString</method> and <class>%iKnow.Filters.FilterWSAPI</class> for 
///  handling filters in non-COS environments.</p>
///  <p>Subclasses should provide an implementation for (at least) <method>BuildSourceFilter</method>,
///  building a bitstring with 1s for those Source IDs satisfying the filter criteria the filter class
///  represents. In their <method>%OnNew</method> implementation, subclasses should make sure to
///  set the <property>DomainId</property> property and call <method>Initialize</method> after 
///  setting all other properties specific to its implementation that influence the outcome of its
///  <method>ToString</method>.</p>
///  <p>Filters can be <b>cached</b> so their calculated bitstrings can be reused (as long as they
///  are still valid) across processes and time. Cache usage can be configured either by setting the 
///  $$$IKPENABLEFILTERCACHE domain parameter, or through a subclass explicitly enabling or
///  disabling it when calling <method>Initialize</method>.</p>
///  <p>Sample Filter implementations include <class>%iKnow.Filters.ExternalIdFilter</class>, 
///  <class>%iKnow.Filters.SentenceCountFilter</class> and <class>%iKnow.Filters.SimpleMetadataFilter</class></p>
///  <p><b>WARNING:</b> When implementing a custom filter class, either make its properties read-only,
///  or override the corresponding Set methods to call <method>ChangeParams</method> to reset the
///  internal representations after property values change. When setting these updateable properties in
///  the class' <method>%OnNew</method> method, use i% syntax to bypass these setters.</p>
Class %iKnow.Filters.Filter Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

///  The domain ID this filter instance is targeting.
Property DomainId As %Integer [ Final ];

///  Whether or not this filter instance is stored in the persistent cache.
Property IsCached As %Integer [ Final, InitialExpression = -1, ReadOnly ];

///  An internal identifier for this Filter instance.
Property FilterId As %Integer [ Internal, ReadOnly ];

Property FilteredBitsGlo As %String [ Internal, Private, ReadOnly ];

Property IsCalculatedGlo As %String [ Internal, Private, ReadOnly ];

Property FilterValidGlo As %String [ Internal, Private, ReadOnly ];

Property FilteredGlo As %String [ Internal, Private, ReadOnly ];

Property FilteredFreqGlo As %String [ Internal, Private, ReadOnly ];

Property FilteredSpreadGlo As %String [ Internal, Private, ReadOnly ];

Property FilteredQParams As %String [ Internal, Private, ReadOnly ];

Property FilteredQRange As %String [ Internal, Private, ReadOnly ];

Property FilteredQResult As %String [ Internal, Private, ReadOnly ];

///  <p>The total number of sources satisfying this filter instances criteria.
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Property FilteredSourceCount As %Integer [ InitialExpression = -1, ReadOnly ];

///  <p>The total number of distinct entities occurring in at least one of the sources satisfying
///  this filter instances criteria.</p>
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Property FilteredEntityUniqueCount As %Integer [ InitialExpression = -1, Private, ReadOnly ];

///  <p>The total number of distinct CRCs occurring in at least one of the sources satisfying
///  this filter instances criteria.</p>
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Property FilteredCrcUniqueCount As %Integer [ InitialExpression = -1, Private, ReadOnly ];

///  <p>The ratio of sources satisfying this filter instances criteria to the total number of sources
///  in this domain.</p>
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Property Selectivity As %Numeric [ InitialExpression = -1, ReadOnly ];

///  <p>This method initializes the data structures this Filter object will be using througout its
///  lifetime as an object instance. If caching is enabled for this object (<var>useCache</var> = 1),
///  it will check if there is already a cached entry corresponding to these filter criteria it can
///  reuse, or create a new cache entry otherwise. If caching is disabled (<var>useCache</var> = 0), 
///  Process-Private Globals will be used for storing this filter instances internals and nothing
///  will be reused. If <var>useCache</var> = -1 (default), the domain default will be used
///  (set through the $$$IKPENABLEFILTERCACHE domain parameter).</p>
Method Initialize(useCache As %Integer = -1) As %Status
{
	// if the FilterId was set previously, the filter is already 
	// properly initialized
	quit:+i%FilterId $$$OK
	
	$$$IKCHECKPRIVREAD
	
	set domainId = i%DomainId
	if (useCache = -1) {
		set i%IsCached = $$$GETPARAM(domainId,$$$IKPENABLEFILTERCACHE,$$$IKPDEFENABLEFILTERCACHE)
	} else {
		set i%IsCached = useCache
	}
	
	if ('i%IsCached) {
		set i%FilterId = $i(^||%IKF.Filter)
		set prefix = "^||%IKF.", suffix="("_i%FilterId_")"
	} else {
		$$$IKTEMPDOMID(i%DomainId,tTempId)
		set prefix = "^IRIS.Temp.IK.Flt."
		if (i%FilterId="") {
			set str = ..ToString(), hash = $zcrc(str,7), id=""
			for {
				set id = $order(^IRIS.Temp.IK.FilterH(tTempId, hash, id))
				quit:id=""
				quit:($lg(^IRIS.Temp.IK.Filter(tTempId,id),1)=str)
			}
		
			set:id="" id=$i(^IRIS.Temp.IK.Filter(tTempId)), ^IRIS.Temp.IK.FilterH(tTempId,hash,id)="", ^IRIS.Temp.IK.Filter(tTempId,id) = $lb(str)
			set i%FilterId = id
		}
		set suffix = "("_tTempId_","_i%FilterId_")"
	}
	
	set i%FilteredBitsGlo = prefix_"Bits"_suffix
	set i%IsCalculatedGlo = prefix_"IsCalc"_suffix
	set i%FilterValidGlo = prefix_"Valid"_suffix
	set i%FilteredGlo = prefix_"Filtered"_suffix
	set i%FilteredFreqGlo = prefix_"Freq"_suffix
	set i%FilteredSpreadGlo = prefix_"Spread"_suffix
	set i%FilteredQParams = prefix_"QParams"_suffix
	set i%FilteredQRange = prefix_"QRange"_suffix
	set i%FilteredQResult = prefix_"QResult"_suffix
	
	set i%Selectivity = -1
	set i%FilteredSourceCount = -1
	set i%FilteredEntityUniqueCount = -1
	set i%FilteredCrcUniqueCount = -1
	
	quit $$$OK
}

///  <p>Utility method to restore a cached filter based on its cached filter ID.</p>
ClassMethod RestoreFilterFromId(domainId As %Integer, filterId As %Integer) As %iKnow.Filters.Filter [ Final ]
{
	$$$IKTEMPDOMID(domainId,tTempId)
	set filterData = $g(^IRIS.Temp.IK.Filter(tTempId, filterId))
	quit:filterData="" ""
	quit ..RestoreFilterFromString($lg(filterData,1))
}

///  <p>Utility method to recreate a filter based on its string representation, which
///  by default corresponds to the filter class name, a pipe character (|) and a filter-specific
///  string containing all parameters required to recreate the string using the <method>%New</method> 
///  method. Subclasses should override <method>RestoreFilterFromStringInternal</method> if this 
///  default behavior is not sufficient.</p>
///  <p>This method is used primarily in SQL and Web Service scenarios, where the filter objects
///  themselves cannot be passed in a SQL statement or SOAP request.</p>
ClassMethod RestoreFilterFromString(filterSpec As %String) As %iKnow.Filters.Filter [ Final ]
{
	quit:$zstrip(filterSpec,"<>WC")="" ""
	set filterClass = $piece(filterSpec, "|", 1)
	quit $classmethod(filterClass, "RestoreFilterFromStringInternal", $e(filterSpec, $length(filterClass)+2, *))
}

///  <p>Default implementation, with the filterParams corresponding to all <method>%New</method> arguments.
///  See also <method>RestoreFilterFromString</method>.</p>
ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	kill tParams
	set tParamCount = $length(filterParams, "|")
	for i = 1:1:tParamCount {
		set tParamValue = $piece(filterParams,"|",i)
		// we can get rid of legacy quotes
		set:($e(tParamValue)="""")&&($e(tParamValue,*)="""") tParamValue = $e(tParamValue,2,*-1)
		set tParams($i(tParams)) = tParamValue
	}
	quit $classmethod($classname(), "%New", tParams...)
}

///  <p>Subclasses should implement this method to build a string representation of the filter
///  instance. It should start with the filter class name, followed by a pipe (|) character and
///  then a string representation that can be interpreted by its <method>RestoreFilterFromStringInternal</method>
///  implementation.</p>
Method ToString() As %String [ Abstract ]
{
}

///  <p>Returns a bitstring representing the Source IDs satisfying this Filters criteria, for
///  the given offset (sourceId\64000+1).</p>
Method GetSourceFilter(offset As %Integer) As %String [ Final ]
{
	do ..Validate($$$IKFSOURCE,.isValid)
	if 'isValid {
		lock:i%IsCached +@i%FilteredBitsGlo@($$$IKFSOURCE):1
		if (i%IsCached && '$test) {
			// if there is already a lock on this global, another filter is populating it,
			// so wait until the lock is removed
			lock +@i%FilteredBitsGlo@($$$IKFSOURCE)
		} else {
			do ..BuildSourceFilter($order(^IRIS.IK.SrcExistsBit(..DomainId,""),-1))
		}
		lock:i%IsCached -@i%FilteredBitsGlo@($$$IKFSOURCE)
	}
	
	quit $g(@i%FilteredBitsGlo@($$$IKFSOURCE, offset))
}

///  <p>Method to be called by the subclass' implementation of <method>BuildSourceBits</method> to
///  register a bitstring of Source IDs at a particular offset.</p> 
Method SetSourceBits(offset As %Integer, bits As %String) As %Status [ Final, Private ]
{
	set:$bitfind(bits,1) @i%FilteredBitsGlo@($$$IKFSOURCE,offset) = bits
	set:'+$g(@i%FilterValidGlo) @i%FilterValidGlo = $$$IKDOMAINU(i%DomainId)
	quit $$$OK
}

///  <p>Retrieves a bitstring representing the Source IDs satisfying this Filters criteria, for
///  the offset (sourceId\64000+1) following the supplied one. The returned number is the next
///  offset (given the direction).</p>
Method GetNextSourceFilterOffset(offset As %Integer = "", Output nextBits As %Integer, direction As %Integer = 1) As %Integer
{
	quit ..GetNextFilterOffset($$$IKFSOURCE, offset, .nextBits, direction)
}

///  <p>This is the primary method that needs to be implemented by an actual <class>%iKnow.Filters.Filter</class>
///  subclass to translate the abstract filter criteria the subclass addresses into a bitstring based on 
///  Source IDs. The subclass' implementation of this method should use <method>SetSourceBits</method>
///  for this purpose, setting the requested bitstrings for each offset up to <var>maxOffset</var>.</p>
Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Abstract, Private ]
{
}

Method GetSecondaryFilter(type As %Integer, offset As %Integer) As %String [ Internal ]
{
	do ..Validate(type,.isValid)
	
	if 'isValid {
		lock:i%IsCached +@i%FilteredBitsGlo@(type):1
		if (i%IsCached && '$test) {
			// if there is already a lock on this global, another filter is populating it,
			// so wait until the lock is removed
			lock +@i%FilteredBitsGlo@(type)
		} else {
			if (type=$$$IKFENTUNI) || (type=$$$IKFCRCUNI) || (type=$$$IKFCCUNI) || (type=$$$IKFSTEMUNI) {
				do ..BuildUniqueFilter(type)
			} elseif (type=$$$IKFENTOCC) || (type=$$$IKFCRCOCC) || (type=$$$IKFPATH) {
				do ..BuildOccurrenceFilter(type)
			} elseif (type=$$$IKFENTOCCC) || (type=$$$IKFENTOCCR) {
				do ..BuildTypedEntOccFilter(type)
			}
		}
		set @i%FilteredBitsGlo@(type) = 1
		lock:i%IsCached -@i%FilteredBitsGlo@(type)
	}
	quit $g(@i%FilteredBitsGlo@(type,offset))
}

Method GetNextFilterOffset(type As %Integer, offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Internal ]
{
	kill nextBits
	do ..Validate(type,.isValid)
	
	if 'isValid {
		lock:i%IsCached +@i%FilteredBitsGlo@(type):1
		if (i%IsCached && '$test) {
			// if there is already a lock on this global, another filter is populating it,
			// so wait until the lock is removed
			lock +@i%FilteredBitsGlo@(type)
		} else {
			if (type=$$$IKFSOURCE) {
				do ..BuildSourceFilter($order(^IRIS.IK.SrcExistsBit(..DomainId,""),-1))
			} elseif (type=$$$IKFENTUNI) || (type=$$$IKFCRCUNI) || (type=$$$IKFCCUNI) || (type=$$$IKFSTEMUNI) {
				do ..BuildUniqueFilter(type)
			} elseif (type=$$$IKFENTOCC) || (type=$$$IKFCRCOCC) || (type=$$$IKFPATH) {
				do ..BuildOccurrenceFilter(type)
			} elseif (type=$$$IKFENTOCCC) || (type=$$$IKFENTOCCR) {
				do ..BuildTypedEntOccFilter(type)
			}
		}
		set @i%FilteredBitsGlo@(type) = 1
		lock:i%IsCached -@i%FilteredBitsGlo@(type)
	}
	quit $order(@i%FilteredBitsGlo@(type,offset), direction, nextBits)
}

///  <p>Returns a bitstring on entUniIDs, representing those unique entities appearing in at least
///  one source satisfying the filter criteria.</p>
Method GetEntityUniqueFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFENTUNI, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on unique entity IDs.</p>
Method GetNextEntityUniqueFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFENTUNI, offset, .nextBits, direction)
}

///  <p>Returns a bitstring on entOccIDs, representing those entity occurrences appearing in a source
///  source satisfying the filter criteria.</p>
Method GetEntityOccurrenceFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFENTOCC, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on entity occurrence IDs.</p>
Method GetNextEntityOccurrenceFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFENTOCC, offset, .nextBits, direction)
}

///  <p>Returns a bitstring on crcUniIDs, representing those unique CRCs appearing in at least
///  one source satisfying the filter criteria.</p>
Method GetCRCUniqueFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFCRCUNI, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on unique CRC IDs.</p>
Method GetNextCRCUniqueFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFCRCUNI, offset, .nextBits, direction)
}

///  <p>Returns a bitstring on crcUniIDs, representing those unique CCs appearing in at least
///  one source satisfying the filter criteria.</p>
Method GetCcUniqueFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFCCUNI, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on unique CC IDs.</p>
Method GetNextCcUniqueFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFCCUNI, offset, .nextBits, direction)
}

///  <p>Returns a bitstring on crcOccIDs, representing those CRC occurrences appearing in a source
///  satisfying the filter criteria.</p>
Method GetCRCOccurrenceFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFCRCOCC, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on CRC occurrence IDs.</p>
Method GetNextCRCOccurrenceFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFCRCOCC, offset, .nextBits, direction)
}

///  <p>Returns a bitstring on path IDs, representing those paths appearing in a source satisfying
///  the filter criteria.</p>
Method GetPathFilter(offset As %Integer) As %String [ Final ]
{
	quit ..GetSecondaryFilter($$$IKFPATH, offset)
}

///  <p>Returns the next offset for which this filter has bits (also returned as <var>nextBits</var>) in its
///  filter on path IDs.</p>
Method GetNextPathFilterOffset(offset As %Integer, Output nextBits As %String, direction As %Integer = 1) As %Integer [ Final ]
{
	quit ..GetNextFilterOffset($$$IKFPATH, offset, .nextBits, direction)
}

///  <p>Builds a filter on entUniIds or crcUniIds, starting from the one on Source IDs.</p>
Method BuildUniqueFilter(type As %Integer) As %Status [ Final, Internal ]
{
	//$$$IKQTIC("BuildUniqueFilter("_type_")")
	//w !,"Filter.BuildUniqueFilter()"
	
	// BDB354 - checking if required globals are generated
	if (type=$$$IKFCCUNI) {
		$$$IKQBCHECKT(i%DomainId,$$$IKBCCUNIALL)
	} elseif (type=$$$IKFENTUNI) {
		$$$IKQBCHECKT(i%DomainId,$$$IKBSRCENTUNI)
	} elseif (type=$$$IKFCRCUNI) {
		$$$IKQBCHECKT(i%DomainId,$$$IKBSRCCRCUNI)
	} elseif (type=$$$IKFSTEMUNI) {
		$$$IKQBCHECKT(i%DomainId,$$$IKBSRCSTEMUNI)
	}
	
	set srcOffset = "", glo = "^IRIS.IK.SrcTo"_$case(type, $$$IKFENTUNI:"Ent", $$$IKFCRCUNI:"Crc", $$$IKFCCUNI:"Cc", $$$IKFSTEMUNI:"Stem")_"UniBit"
	for {
		set srcOffset = ..GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		// loop through source positions
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits, 1, srcPos+1)
			quit:srcPos=0
			
			// compile source ID
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			
			// loop through entity/CRC offsets
			set uniOff = ""
			for {
				set uniOff = $order(@glo@(i%DomainId, srcId, uniOff), 1, uniBits)
				quit:uniOff=""
				
				set filterBits = $g(@i%FilteredBitsGlo@(type, uniOff))
				set @i%FilteredBitsGlo@(type, uniOff) = $bitlogic(uniBits | filterBits)
			}
		}
	}
	
	//$$$IKQTOC("BuildUniqueFilter("_type_")")
	quit $$$OK
}

///  <p>Builds a filter on entity occurrence IDs specifically in a concept or relation role,
///  starting from the one on entity occurrence IDs.</p>
Method BuildTypedEntOccFilter(type As %Integer) As %Status [ Final, Internal ]
{
	//$$$IKQTIC("BuildTypedEntOccFilter("_type_")")
	//w !,"Filter.BuildTypedEntOccFilter()"
	do:'..IsValid($$$IKFENTOCC) ..BuildOccurrenceFilter($$$IKFENTOCC)
	
	set tSC = $prefetchon(^IRIS.IK.EntTypeToOccBit(i%DomainId,0))
	set tSC = $prefetchon(^IRIS.IK.EntTypeToOccBit(i%DomainId,1))
	set off = ""
	for {
		set off = $order(@i%FilteredBitsGlo@($$$IKFENTOCC, off), 1, bits)
		quit:off=""
		
		set tBits0 = $g(^IRIS.IK.EntTypeToOccBit(i%DomainId,0,off)),
			tBits1 = $g(^IRIS.IK.EntTypeToOccBit(i%DomainId,1,off))
		
		if (type = $$$IKFENTOCCC) {
			set @i%FilteredBitsGlo@(type, off) = $bitlogic(bits & ~tBits0 & ~tBits1)
		} else {
			set @i%FilteredBitsGlo@(type, off) = $bitlogic(bits & tBits0 & ~tBits1)
		}
	}
	//$$$IKQTOC("BuildTypedEntOccFilter("_type_")")
	quit $$$OK
}

///  <p>Builds a filter on entOccIds, crcOccIds or pathIds, starting from the one on Source IDs.</p>
Method BuildOccurrenceFilter(type As %Integer = {$$$IKFENTOCC}) As %Status [ Final, Internal ]
{
	//$$$IKQTIC("BuildOccurrenceFilter("_type_")")
	//w !,"Filter.BuildOccurrenceFilter()"
	set idxBase = $case(type, $$$IKFENTOCC:3, $$$IKFCRCOCC:5, $$$IKFPATH:7)
	set idxCount = $case(type, $$$IKFENTOCC:4, $$$IKFCRCOCC:6, $$$IKFPATH:8)
	
	kill ^||%IKF.OccList
	$$$IKSORTBEGIN(^||%IKF.OccList)
	
	set srcOffset="", prevOccOff=0, occBits="", domId=i%DomainId
	for {
		set srcOffset = ..GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		// loop through source positions
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits, 1, srcPos+1)
			quit:srcPos=0
			
			// compile source ID
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			set srcDetails = $g(^IRIS.IK.SrcDetails(domId, srcId))
			continue:srcDetails=""
			
			set occFrom = $li(srcDetails,idxBase)+1
			set occTo = occFrom + $li(srcDetails,idxCount) - 1
			
			set ^||%IKF.OccList(occFrom) = occTo
		}
	}
	set x = $sortend(^||%IKF.OccList)
	
	set occFrom="", prevOccOff=0, occBits=""
	for {
		set occFrom = $order(^||%IKF.OccList(occFrom),1,occTo)
		quit:occFrom=""
		
		$$$IKBITOFFPOS(occFrom,occOff1,occPos1)
		$$$IKBITOFFPOS(occTo,occOff2,occPos2)
		
		for occOff = occOff1:1:occOff2 {
			set from = $s(occOff=occOff1:occPos1, 1:1)
			set to = $s(occOff=occOff2:occPos2, 1:64000)
			
			if (occOff'=prevOccOff) {
				set:prevOccOff @i%FilteredBitsGlo@(type, prevOccOff) = $bitlogic(occBits), occBits=""
				set prevOccOff = occOff
			}
			
			for occPos = from:1:to {
				set $bit(occBits,occPos) = 1
			}
		}
	}
	set:prevOccOff @i%FilteredBitsGlo@(type, prevOccOff) = $bitlogic(occBits)
	kill ^||%IKF.OccList
	
	//$$$IKQTOC("BuildOccurrenceFilter("_type_")")
	quit $$$OK
}

///  <p>Resets all internal representations, forcing further use of this filter to 
///  recalculate results. If a <var>type</var> is supplied, only the bitstrings of that type
///  are reset, including dependent ones. In the case of Source IDs (<var>type</var> = $$$IKFSOURCE),
///  specific offset values can be invalidated separately.</p>
Method Invalidate(type As %Integer = {$$$IKFSOURCE}) As %Status
{
	quit:'+i%FilterId $$$OK
	
	if (type=$$$IKFSOURCE) {
		
		kill @i%FilteredBitsGlo
		kill @i%FilterValidGlo
		kill @i%FilteredGlo
		kill @i%FilteredFreqGlo
		kill @i%FilteredSpreadGlo
		
		kill @i%FilteredQParams
		kill @i%FilteredQRange
		kill @i%FilteredQResult
	
		set i%Selectivity = -1
		set i%FilteredSourceCount = -1
		set i%FilteredEntityUniqueCount = -1
		set i%FilteredCrcUniqueCount = -1
		
	} else {
		
		kill @i%FilteredBitsGlo@(type)
		kill @i%FilteredGlo@(type)
		kill @i%FilteredFreqGlo@(type)
		kill @i%FilteredSpreadGlo@(type)
		
		set:type=$$$IKFENTUNI i%FilteredEntityUniqueCount = -1
		set:type=$$$IKFCRCUNI i%FilteredCrcUniqueCount = -1
		
	}
	quit $$$OK
}

///  <p>This class method is an access point to generate the string representation (as specified in
///  <method>ToString</method>) for <class>%iKnow.Filters.Filter</class> classes, accessible from COS
///  and SQL scenarios that cannot or prefer not to directly instantiate objects through COS.</p>
///  <p>When calling this method, you should supply the <b>Filter Parameters</b> as if calling the
///  <method>%New</method> method of this particular Filter implementation.</p>
///  <p>For Web Service scenario's, use the corresponding method in <class>%iKnow.Filters.FilterWSAPI</class>.</p>
ClassMethod CreateAsString(createParams...) As %String [ Final, SqlProc ]
{
    set filter = ..%New(createParams...)
    quit:filter="" ""
	quit filter.ToString()
}

///  <p>This class enables SQL users to create the string representation of a
///  <class>%iKnow.Filters.GroupFilter</class> composed of multiple subfilters passed in using their
///  respective string representations as the <var>filters...</var> parameter.</p>
///  <p>For Web Service scenario's, use the corresponding method in <class>%iKnow.Filters.FilterWSAPI</class>.</p>
ClassMethod CreateGroupAsString(domainId As %Integer, groupLogic As %Integer = {$$$GROUPFILTERAND}, negated As %Boolean = 0, filters...) As %String [ Final, SqlProc ]
{
	quit:filters="" ""
	
	set groupFilter = ##class(%iKnow.Filters.GroupFilter).%New(domainId, groupLogic, negated)
	quit:groupFilter="" ""
	
	set tSC = $$$OK
	for i=1:1:filters { 
		set tSC = groupFilter.AddSubFilterString(filters(i))
		quit:$$$ISERR(tSC)
	}
	
	quit:$$$ISERR(tSC) ""
	quit groupFilter.ToString()
}

///  Override Set method to invalidate filter upon change
Method DomainIdSet(domainId As %Integer) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:domainId=i%DomainId $$$OK
	$$$CHECKDOMAINEXISTS(domainId)
	set i%DomainId = domainId
	quit ..ChangeParams()
}

///  <p>This method should be called inside *Set methods of subclasses that allow their properties
///  to be changed in the instances lifetime, to make sure it's properly re-initialized.</p>
Method ChangeParams() As %Status [ Private ]
{
	// if parameters change, don't invalidate but just unset the filter ID and
	// re-initialize to check if there's already a cached filter with he new params
	set i%FilterId = ""
	quit ..Initialize(i%IsCached)
}

///  <p>Checks whether this filter is in a valid state and all calculated bitstrings are up-to-date 
///  through a call to <method>IsValid</method>, the result of which is returned as <var>isValid</var>. If
///  the bitstrings of the requested <var>type</var> are invalid, <method>Invalidate</method> is called.</p>
Method Validate(type As %Integer = {$$$IKFSOURCE}, Output isValid As %Boolean = 0) As %Status [ Private ]
{
	set tSC = ..Initialize(i%IsCached)
	set isValid = ..IsValid(type)
	do:'isValid ..Invalidate(type)
	quit tSC
}

///  <p>Checks if this filter for <var>type</var> is still up-to-date with regards to incorporating the
///  most recent source additions and changes. Subclasses might wish to override this method but should 
///  combine their additional checks with the result of this root implementation if they do.</p>
///  <p>If the requested filter is not calculated, this method will return 0.</p>
Method IsValid(type As %Integer = {$$$IKFSOURCE}) As %Boolean
{
	set filterValidU = +$g(@i%FilterValidGlo)
	quit:'filterValidU 0
	
	if (type '= $$$IKFSOURCE) {
		quit:'$d(@i%FilteredBitsGlo@(type)) 0
	}
	
	quit (filterValidU >= $$$IKDOMAINU(i%DomainId))
}

Method SelectivityGet() As %Numeric [ Internal, ServerOnly = 1 ]
{
	do ..Validate($$$IKFSOURCE)
	if (i%Selectivity<0) {
		set srcOffset = 0, total = 0
		for {
			set srcOffset = $order(^IRIS.IK.SrcExistsBit(i%DomainId, srcOffset), 1, srcBits)
			quit:srcOffset=""
			set total = total + $bitcount(srcBits,1)
		}
		set i%Selectivity = $s(total:(..FilteredSourceCount/total), 1:0)
	}
	quit i%Selectivity
}

Method FilteredSourceCountGet() As %Integer [ Internal, ServerOnly = 1 ]
{
	do ..Validate($$$IKFSOURCE)
	if (i%FilteredSourceCount<0) {
		set srcOffset = 0, count = 0
		for {
			set srcOffset = ..GetNextSourceFilterOffset(srcOffset, .srcBits)
			quit:srcOffset=""
			set count = count + $bitcount(srcBits,1)
		}
		set i%FilteredSourceCount = count
	}
	quit i%FilteredSourceCount
}

///  <p>Returns the total number of distinct entities occurring in at least one of the sources satisfying
///  this filter instances criteria.</p>
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Method GetFilteredEntityUniqueCount(ByRef approximate As %Boolean = 0) As %Integer [ Final ]
{
	do ..Validate($$$IKFENTUNI, .isValid)
	if (i%FilteredEntityUniqueCount<0) {
		
		// if we don't have valid bitstrings, but the approximate
		// is OK, return it
		if ('isValid && approximate) {
			quit ..Selectivity * $order(^IRIS.IK.EntUniId(i%DomainId,""),-1)
		}
		
		set offset = 0, count = 0
		for {
			set offset = ..GetNextEntityUniqueFilterOffset(offset, .bits)
			quit:offset=""
			set count = count + $bitcount(bits,1)
		}
		set i%FilteredEntityUniqueCount = count
	}
	set approximate = 0
	quit i%FilteredEntityUniqueCount
}

///  <p>Returns the total number of distinct CRCs occurring in at least one of the sources satisfying
///  this filter instances criteria.</p>
///  <p>This property is used to choose the fastest access path in iKnow Query implementations.</p>
Method GetFilteredCrcUniqueCount(ByRef approximate As %Boolean = 0) As %Integer [ Internal, ServerOnly = 1 ]
{
	do ..Validate($$$IKFCRCUNI, .isValid)
	if (i%FilteredCrcUniqueCount<0) {
		
		// if we don't have valid bitstrings, but the approximate
		// is OK, return it
		if ('isValid && approximate) {
			quit ..Selectivity * $order(^IRIS.IK.EntUniId(i%DomainId,""),-1)
		}
		
		set offset = 0, count = 0
		for {
			set offset = ..GetNextCRCUniqueFilterOffset(offset, .bits)
			quit:offset=""
			set count = count + $bitcount(bits,1)
		}
		set i%FilteredCrcUniqueCount = count
	}
	set approximate = 0
	quit i%FilteredCrcUniqueCount
}

///  <p>Clears a specific filter from the persistent filter cache, if it exists.</p>
ClassMethod ClearCachedFilter(domainId As %Integer, filterId As %Integer) As %Status [ Final, SqlProc ]
{
	$$$IKTEMPDOMID(domainId,tTempId)
	set filterData = $g(^IRIS.Temp.IK.Filter(tTempId,filterId))
	quit:filterData'="" $$$OK
	
	set filterString = $lg(filterData,1)
	quit:filterString="" $$$OK
	kill ^IRIS.Temp.IK.FilterH(tTempId, $zcrc(filterString,7), filterId)
	kill ^IRIS.Temp.IK.Filter(tTempId,filterId)
		
	set prefix = "^IRIS.Temp.IK.Flt."
	for glob = "Valid","Filtered","Bits","Calc","Freq","Spread","QParams","QResult","QRange" {
		kill @(prefix_glob_"("_tTempId_","_filterId_")")
	}
	quit $$$OK
}

///  <p>Clears all filters from the persistent filter cache.</p>
ClassMethod ClearCachedFilters(domainId As %Integer) As %Status [ Final, SqlProc ]
{
	$$$IKTEMPDOMID(domainId,tTempId)
	kill ^IRIS.Temp.IK.FilterH(tTempId), ^IRIS.Temp.IK.Filter(tTempId)
	set prefix = "^IRIS.Temp.IK.Flt."
	for glob = "Valid","Filtered","Bits","Calc","Freq","Spread","QParams","QResult","QRange" {
		kill @(prefix_glob_"("_tTempId_")")
	}
	quit $$$OK
}

///  <p>Returns the total frequency of an entity in the sources satisfying this filter instances
///  criteria, where the entities role is concept (if <var>role</var> = $$$ENTTYPECONCEPT), relation
///  (if <var>role</var> = $$$ENTTYPERELATION) or either of the two (if <var>role</var> = $$$ENTTYPEANY).</p>
Method GetFilteredEntityFrequency(entUniId As %Integer, role As %Integer = {$$$ENTTYPEANY}) As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the entity is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFENTUNI, entUniId),1) 0
	
	set type = $case(role, $$$ENTTYPEANY:$$$IKFENTOCC, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	if '$d(@i%FilteredFreqGlo@(type, entUniId), freq) {
		set freq = 0
		if '..IsValid(type) && $$$IKVERSIONATLEAST(i%DomainId,$$$IKVERSION20122) {
			set srcOff=""
			for {
				set srcOff = ..GetNextSourceFilterOffset(srcOff,.srcBits)
				quit:srcOff=""
				set srcPos=""
				for {
					set srcPos=$bitfind(srcBits,1,srcPos+1)
					quit:'srcPos
					$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
					set details = $g(^IRIS.IK.EntSrcDetails(i%DomainId,srcId,entUniId))
					continue:details=""
					set freq = freq + $case(role, $$$ENTTYPECONCEPT:$lg(details,1), $$$ENTTYPERELATION:$lg(details,2), :$lg(details,1)+$lg(details,2))
				}
			}
		} else {
			
			$$$IKQBCHECKT(i%DomainId,$$$IKBENTUNIBIT)
			
			set off = ""
			for {
				set off = ..GetNextFilterOffset(type, off,.bits)
				quit:off=""
			
				set freq = freq + $bitcount($bitlogic(bits & ^IRIS.IK.EntUniToOccBit(i%DomainId,entUniId,off)),1)
			}
		}
		do ..SaveFilteredFrequency(type, entUniId, freq)
	}
	quit freq
}

///  <p>Returns the total frequency of a stem in the sources satisfying this filter instances
///  criteria, where the stem's role is concept (if <var>pRole</var> = $$$ENTTYPECONCEPT), relation
///  (if <var>pRole</var> = $$$ENTTYPERELATION) or either of the two (if <var>pRole</var> = $$$ENTTYPEANY).</p>
Method GetFilteredStemFrequency(pStemUniId As %Integer, pRole As %Integer = {$$$ENTTYPEANY}) As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the stem is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFSTEMUNI, pStemUniId),1) 0
	
	set type = $case(pRole, $$$ENTTYPEANY:$$$IKFENTOCC, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	if '$d(@i%FilteredFreqGlo@(-type, pStemUniId), freq) {
		set freq = 0
		if '..IsValid(type) && $$$IKVERSIONATLEAST(i%DomainId,$$$IKVERSION20122) {
			set srcOff=""
			for {
				set srcOff = ..GetNextSourceFilterOffset(srcOff,.srcBits)
				quit:srcOff=""
				set srcPos=""
				for {
					set srcPos=$bitfind(srcBits,1,srcPos+1)
					quit:'srcPos
					$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
					set details = $g(^IRIS.IK.StemSrcDetails(i%DomainId,srcId,pStemUniId))
					continue:details=""
					set freq = freq + $case(pRole, $$$ENTTYPECONCEPT:$lg(details,1), $$$ENTTYPERELATION:$lg(details,2), :$lg(details,1)+$lg(details,2))
				}
			}
		} else {
			
			$$$IKQBCHECKT(i%DomainId,$$$IKBSTEMUNIBIT)
			
			set off = ""
			for {
				set off = ..GetNextFilterOffset(type, off,.bits)
				quit:off=""
			
				set freq = freq + $bitcount($bitlogic(bits & ^IRIS.IK.StemUniToOccBit(i%DomainId,pStemUniId,off)),1)
			}
		}
		do ..SaveFilteredFrequency(-type, pStemUniId, freq)
	}
	quit freq
}

///  <p>Returns the total number of sources in which the supplied entity appears that satisfy this
///  filter instances criteria, where its role is concept (if <var>role</var> = $$$ENTTYPECONCEPT), relation
///  (if <var>role</var> = $$$ENTTYPERELATION) or either of the two (if <var>role</var> = $$$ENTTYPEANY).</p>
Method GetFilteredEntitySpread(entUniId As %Integer, role As %Integer = {$$$ENTTYPEANY}, details As %List = "") As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the entity is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFENTUNI, entUniId),1) 0
	
	set type = $case(role, $$$ENTTYPEANY:$$$IKFENTOCC, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	
	if '$d(@i%FilteredSpreadGlo@(type, entUniId), spread) {
		
		if (role '= $$$ENTTYPEANY) {
			// first do a simple check on spreads as only a fraction of entities appear as
			// both Concept and Relation in different sources
			set:(details="") details = $g(^IRIS.IK.EntUniDetails(i%DomainId,entUniId))
			set mixedRoles = 1
			
			if (details'="") {
				if (role=$$$ENTTYPECONCEPT) && '$lg(details,5) { set mixedRoles = 0 }
				if (role=$$$ENTTYPERELATION) && '$lg(details,4) { set mixedRoles = 0 }
			}
		}
		if (role '= $$$ENTTYPEANY) && mixedRoles {
			
			if (..IsValid(type)) {
				
				$$$IKQBCHECKT(i%DomainId,$$$IKBENTUNIBIT)
				
				// if we already have the occurrence-based filter (<type>), merge it to
				// ^IRIS.IK.EntUniToOccBit and loop through the remaining occurrences
				kill ^||%IK.FilteredSpreadSrcs
				set off = "", spread = 0
				for {
					set off = ..GetNextFilterOffset(type,off,.bits)
					quit:off=""
				
					set bits = $bitlogic(bits & ^IRIS.IK.EntUniToOccBit(i%DomainId,entUniId,off))
				
					set pos = 0
					for {
						set pos = $bitfind(bits, 1, pos+1)
						quit:pos=0
					
						$$$IKGETIDOFFPOS(entOccId,off,pos)
						set sentId = $list(^IRIS.IK.EntOccId(i%DomainId, entOccId), 3)
						set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId, sentId)
				
						if '$d(^||%IK.FilteredSpreadSrcs(srcId)) {
							set ^||%IK.FilteredSpreadSrcs(srcId) = ""
							set spread = spread+1
						}
					}
				}
				kill ^||%IK.FilteredSpreadSrcs
			
			} elseif $$$IKVERSIONBEFORE(i%DomainId,$$$IKVERSION20122) {
				
				// for v1 domains, we'll have to go through entity occurrences
				kill ^||%IK.FilteredSpreadSrcs
				set off = "", spread = 0
				for {
					set off = ..GetNextFilterOffset(type,off,.bits)
					quit:off=""
				
					set bits = $bitlogic(bits & ^IRIS.IK.EntUniToOccBit(i%DomainId,entUniId,off))
				
					set pos = 0
					for {
						set pos = $bitfind(bits, 1, pos+1)
						quit:pos=0
					
						$$$IKGETIDOFFPOS(entOccId,off,pos)
						set sentId = $list(^IRIS.IK.EntOccId(i%DomainId, entOccId), 3)
						set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId, sentId)
				
						if '$d(^||%IK.FilteredSpreadSrcs(srcId)) {
							set ^||%IK.FilteredSpreadSrcs(srcId) = ""
							set spread = spread+1
						}
					}
				}
				kill ^||%IK.FilteredSpreadSrcs
				
			} else {
				
				// if it does not exist yet, we're probably better off through 
				// ^IRIS.IK.EntSrcDetails for each filtered source
				set srcOff = "", spread=0, listPos = $case(role, $$$ENTTYPECONCEPT:1, $$$ENTTYPERELATION:2)
				for {
					set srcOff = ..GetNextSourceFilterOffset(srcOff, .srcBits)
					quit:srcOff=""
				
					set srcPos = 0
					for {
						set srcPos = $bitfind(srcBits, 1, srcPos+1)
						quit:srcPos=0
					
						$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
					
						set entSrcDetails = $g(^IRIS.IK.EntSrcDetails(i%DomainId,srcId,entUniId))
						continue:entSrcDetails=""
						set spread = spread + ($lg(entSrcDetails,listPos)>0)
					}
				}
			}
			
		} else {
			
			$$$IKQBCHECKT(i%DomainId,$$$IKBENTUNISRC)
			
			// otherwise, we can simply go through ^||%IK.EntUniToSrcBit
			set off = "", spread = 0
			for {
				set off = ..GetNextSourceFilterOffset(off,.bits)
				quit:off=""
			
				set spread = spread + $bitcount($bitlogic(bits & ^IRIS.IK.EntUniToSrcBit(i%DomainId,entUniId,off)),1)
			}
		}	
		do ..SaveFilteredSpread(type, entUniId, spread)
	}
	quit spread
}

///  <p>Returns the total number of sources in which the supplied stem appears that satisfy this
///  filter instances criteria, where its role is concept (if <var>pRole</var> = $$$ENTTYPECONCEPT), relation
///  (if <var>pRole</var> = $$$ENTTYPERELATION) or either of the two (if <var>pRole</var> = $$$ENTTYPEANY).</p>
Method GetFilteredStemSpread(pStemUniId As %Integer, pRole As %Integer = {$$$ENTTYPEANY}, details As %List = "") As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the entity is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFSTEMUNI, pStemUniId),1) 0
	
	set type = $case(pRole, $$$ENTTYPEANY:$$$IKFENTOCC, $$$ENTTYPECONCEPT:$$$IKFENTOCCC, $$$ENTTYPERELATION:$$$IKFENTOCCR)
	
	if '$d(@i%FilteredSpreadGlo@(-type, pStemUniId), spread) {
		
		if (pRole '= $$$ENTTYPEANY) {
			// first do a simple check on spreads as only a fraction of entities appear as
			// both Concept and Relation in different sources
			set:(details="") details = $g(^IRIS.IK.StemUniDetails(i%DomainId,pStemUniId))
			set mixedRoles = 1
			
			if (details'="") {
				if (pRole=$$$ENTTYPECONCEPT) && '$lg(details,5) { set mixedRoles = 0 }
				if (pRole=$$$ENTTYPERELATION) && '$lg(details,4) { set mixedRoles = 0 }
			}
		}
		if (pRole '= $$$ENTTYPEANY) && mixedRoles {
			
			if (..IsValid(type)) {
				
				$$$IKQBCHECKT(i%DomainId,$$$IKBSTEMUNIBIT)
				
				// if we already have the occurrence-based filter (<type>), merge it to
				// ^IRIS.IK.EntUniToOccBit and loop through the remaining occurrences
				kill ^||%IK.FilteredSpreadSrcs
				set off = "", spread = 0
				for {
					set off = ..GetNextFilterOffset(type,off,.bits)
					quit:off=""
				
					set bits = $bitlogic(bits & ^IRIS.IK.StemUniToOccBit(i%DomainId,pStemUniId,off))
				
					set pos = 0
					for {
						set pos = $bitfind(bits, 1, pos+1)
						quit:pos=0
					
						$$$IKGETIDOFFPOS(entOccId,off,pos)
						set sentId = $list(^IRIS.IK.EntOccId(i%DomainId, entOccId), 3)
						set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId, sentId)
				
						if '$d(^||%IK.FilteredSpreadSrcs(srcId)) {
							set ^||%IK.FilteredSpreadSrcs(srcId) = ""
							set spread = spread+1
						}
					}
				}
				kill ^||%IK.FilteredSpreadSrcs
			
			} elseif $$$IKVERSIONBEFORE(i%DomainId,$$$IKVERSION20122) {
				
				// for v1 domains, we'll have to go through entity occurrences
				kill ^||%IK.FilteredSpreadSrcs
				set off = "", spread = 0
				for {
					set off = ..GetNextFilterOffset(type,off,.bits)
					quit:off=""
				
					set bits = $bitlogic(bits & ^IRIS.IK.StemUniToOccBit(i%DomainId,pStemUniId,off))
				
					set pos = 0
					for {
						set pos = $bitfind(bits, 1, pos+1)
						quit:pos=0
					
						$$$IKGETIDOFFPOS(entOccId,off,pos)
						set sentId = $list(^IRIS.IK.EntOccId(i%DomainId, entOccId), 3)
						set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId, sentId)
				
						if '$d(^||%IK.FilteredSpreadSrcs(srcId)) {
							set ^||%IK.FilteredSpreadSrcs(srcId) = ""
							set spread = spread+1
						}
					}
				}
				kill ^||%IK.FilteredSpreadSrcs
				
			} else {
				
				// if it does not exist yet, we're probably better off through 
				// ^IRIS.IK.StemSrcDetails for each filtered source
				set srcOff = "", spread=0, listPos = $case(pRole, $$$ENTTYPECONCEPT:1, $$$ENTTYPERELATION:2)
				for {
					set srcOff = ..GetNextSourceFilterOffset(srcOff, .srcBits)
					quit:srcOff=""
				
					set srcPos = 0
					for {
						set srcPos = $bitfind(srcBits, 1, srcPos+1)
						quit:srcPos=0
					
						$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
					
						set stemSrcDetails = $g(^IRIS.IK.StemSrcDetails(i%DomainId,srcId,pStemUniId))
						continue:stemSrcDetails=""
						set spread = spread + ($lg(stemSrcDetails,listPos)>0)
					}
				}
			}
			
		} else {
			
			$$$IKQBCHECKT(i%DomainId,$$$IKBSTEMUNISRC)
			
			// otherwise, we can simply go through ^||%IK.StemUniToSrcBit
			set off = "", spread = 0
			for {
				set off = ..GetNextSourceFilterOffset(off,.bits)
				quit:off=""
			
				set spread = spread + $bitcount($bitlogic(bits & ^IRIS.IK.StemUniToSrcBit(i%DomainId,pStemUniId,off)),1)
			}
		}	
		do ..SaveFilteredSpread(-type, pStemUniId, spread)
	}
	quit spread
}

///  <p>Returns the total frequency of a CRC in the sources satisfying this filter instances criteria.</p>
Method GetFilteredCrcFrequency(crcUniId As %Integer) As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the CRC is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFCRCUNI, crcUniId),1) 0
	
	if '$d(@i%FilteredFreqGlo@($$$IKFCRCUNI, crcUniId), freq) {
		set freq = 0
		if '..IsValid($$$IKFCRCOCC) && $$$IKVERSIONATLEAST(i%DomainId,$$$IKVERSION20122) {
			set srcOff=""
			for {
				set srcOff = ..GetNextSourceFilterOffset(srcOff,.srcBits)
				quit:srcOff=""
				set srcPos=""
				for {
					set srcPos=$bitfind(srcBits,1,srcPos+1)
					quit:'srcPos
					$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
					set freq = freq + $lg($g(^IRIS.IK.CrcSrcDetails(i%DomainId,srcId,crcUniId)),1)
				}
			}
		} else {
			
			$$$IKQBCHECKT(i%DomainId,$$$IKBCRCUNIBIT)
			
			set off = ""
			for {
				set off = ..GetNextCRCOccurrenceFilterOffset(off,.bits)
				quit:off=""
		
				set freq = freq + $bitcount($bitlogic(bits & ^IRIS.IK.CrcUniToOccBit(i%DomainId,crcUniId,off)),1)
			}
		}
		do ..SaveFilteredFrequency($$$IKFCRCUNI, crcUniId, freq)
	}
	quit freq
}

///  <p>Returns the total number of sources satisfying this filter instances criteria in which the
///  supplied CRC appears.</p>
Method GetFilteredCrcSpread(crcUniId As %Integer) As %Integer
{
	do ..Validate()
	
	// quick peek if we already know the CRC is never filtered
	quit:'$g(@i%FilteredGlo@($$$IKFCRCUNI, crcUniId),1) 0
	
	if '$d(@i%FilteredSpreadGlo@($$$IKFCRCUNI, crcUniId), spread) {
		
		$$$IKQBCHECKT(i%DomainId,$$$IKBCRCUNISRC)
		
		set off = "", spread = 0
		for {
			set off = ..GetNextSourceFilterOffset(off,.bits)
			quit:off=""
		
			set spread = spread + $bitcount($bitlogic(bits & ^IRIS.IK.CrcUniToSrcBit(i%DomainId,crcUniId,off)),1)
		}
		do ..SaveFilteredSpread($$$IKFCRCUNI, crcUniId, spread)
	}
	quit spread
}

///  <p>Returns the total frequency of a CC in the sources satisfying this filter instances criteria.</p>
Method GetFilteredCcFrequency(ccUniId As %Integer, type As %Integer = {$$$IKFCCUNI}) As %Integer
{
	do ..Validate()
	
	$$$IKQBCHECKT(i%DomainId,$lb($$$IKBCCUNIALL,$$$IKBCCUNIBIT))
	
	if (type = $$$IKFCCCOMBI) {
		set otherCcUniId = +##class(%iKnow.Queries.CcAPI).GetInverse(i%DomainId, ccUniId)
		if 'otherCcUniId || (otherCcUniId=ccUniId) {
			set type = $$$IKFCCUNI
		}
	}
	
	// quick peek if we already know the CC is never filtered
	quit:'$g(@i%FilteredGlo@(type, ccUniId),1) 0
	
	if '$d(@i%FilteredFreqGlo@(type, ccUniId), freq) {
		set off = "", freq = 0
		for {
			set off = ..GetNextCRCOccurrenceFilterOffset(off,.bits)
			quit:off=""
			
			set combinedBits = $g(^IRIS.IK.CcUniToOccBit(i%DomainId,ccUniId,off))
			set:(type=$$$IKFCCCOMBI) combinedBits = $bitlogic(combinedBits | ^IRIS.IK.CcUniToOccBit(i%DomainId,otherCcUniId,off))
			set freq = freq + $bitcount($bitlogic(bits & combinedBits),1)
		}
		do ..SaveFilteredFrequency(type, ccUniId, freq)
		do:(type=$$$IKFCCCOMBI) ..SaveFilteredFrequency(type, otherCcUniId, freq)
	}
	quit freq
}

///  <p>Returns the total number of sources satisfying this filter instances criteria in which the
///  supplied CC appears.</p>
Method GetFilteredCcSpread(ccUniId As %Integer, type As %Integer = {$$$IKFCCUNI}) As %Integer
{
	do ..Validate()
	
	$$$IKQBCHECKT(i%DomainId,$lb($$$IKBCCUNIALL,$$$IKBCCUNISRC))
	
	if (type = $$$IKFCCCOMBI) {
		set otherCcUniId = +##class(%iKnow.Queries.CcAPI).GetInverse(i%DomainId, ccUniId)
		if 'otherCcUniId || (otherCcUniId=ccUniId) {
			set type = $$$IKFCCUNI
		}
	}
	
	// quick peek if we already know the CC is never filtered
	quit:'$g(@i%FilteredGlo@(type, ccUniId),1) 0
	
	if '$d(@i%FilteredSpreadGlo@(type, ccUniId), spread) {
		set off = "", spread = 0
		for {
			set off = ..GetNextSourceFilterOffset(off,.bits)
			quit:off=""
		
			set combinedBits = $g(^IRIS.IK.CcUniToSrcBit(i%DomainId,ccUniId,off))
			set:(type=$$$IKFCCCOMBI) combinedBits = $bitlogic(combinedBits | ^IRIS.IK.CcUniToSrcBit(i%DomainId,otherCcUniId,off))
			set spread = spread + $bitcount($bitlogic(bits & combinedBits),1)
		}
		do ..SaveFilteredSpread(type, ccUniId, spread)
		do:(type=$$$IKFCCCOMBI) ..SaveFilteredSpread(type, otherCcUniId, spread)
	}
	quit spread
}

///  <p>Utility method to explicitly register the filtered frequency for an entity or CRC.
/// Note that for stems, we use -type in order not to mix with the positive values ($$$IKFENTOCC,
/// $$$IKFENTOCCC, $$$IKFENTOCCR) used for entities.</p>
Method SaveFilteredFrequency(type As %Integer, id As %Integer, freq As %Integer) As %Status [ Internal ]
{
	set @i%FilteredFreqGlo@(type, id) = freq
	set @i%FilteredGlo@(type, id) = (freq>0)
	quit $$$OK
}

///  <p>Utility method to explicitly register the filtered spread for an entity or CRC.
/// Note that for stems, we use -type in order not to mix with the positive values ($$$IKFENTOCC,
/// $$$IKFENTOCCC, $$$IKFENTOCCR) used for entities.</p>
Method SaveFilteredSpread(type As %Integer, id As %Integer, spread As %Integer) As %Status [ Internal ]
{
	set @i%FilteredSpreadGlo@(type, id) = spread
	set @i%FilteredGlo@(type, id) = (spread>0)
	quit $$$OK
}

///  <p>Returns whether the <var>id</var> of the given <var>type</var> appears in any source satisfying this
///  filter instances criteria.</p>
Method IsFiltered(id As %Integer, type As %Integer = {$$$IKFSOURCE}) As %Boolean
{
	do ..Validate()
	
	if $d(@i%FilteredGlo@(type, id), isFiltered) {
		quit isFiltered
	}
	
	if (type=$$$IKFSOURCE) {
		
		$$$IKBITOFFPOS(id,off,pos)
		set bits = ..GetSourceFilter(off)
		set isFiltered = $bit(bits, pos)
		
	} elseif (type=$$$IKFCCCOMBI) {
		
		set isFiltered = ..IsFiltered(id, $$$IKFCCUNI)
		if ('isFiltered) {
			set otherId = ##class(%iKnow.Queries.CcAPI).GetInverse(i%DomainId,id)
			if 'otherId {
				set isFiltered = 0
			} else {
				set isFiltered = ..IsFiltered(otherId, $$$IKFCCUNI)
			}
		}
		
	} else {
		// if the full bitstring was not yet calculated or is invalid, it can be easier to 
		// find the answer for this element directly from the source filter
		// if it's an unselective one
		if '..IsValid(type) && (..FilteredSourceCount>20) {
			
			if (type=$$$IKFENTUNI) || (type=$$$IKFCRCUNI) || (type=$$$IKFCCUNI) || (type=$$$IKFSTEMUNI) {
				
				set tGlob = $case(type, $$$IKFENTUNI:$$$IKBENTUNISRC, $$$IKFCRCUNI:$$$IKBCRCUNISRC, $$$IKFCCUNI:$$$IKBCCUNISRC, $$$IKFSTEMUNI:$$$IKBSTEMUNISRC)
				$$$IKQBCHECKT(i%DomainId,tGlob)
				
				set glo = $case(type, $$$IKFENTUNI:"^IRIS.IK.EntUniToSrcBit", $$$IKFCRCUNI:"^IRIS.IK.CrcUniToSrcBit", $$$IKFCCUNI:"^IRIS.IK.CcUniToSrcBit", $$$IKFSTEMUNI:"^IRIS.IK.StemUniToSrcBit")
				set o="", isFiltered=0
				for {
					set o = $o(@glo@(i%DomainId,id,o),1,bits)
					quit:o=""
					set srcBits = ..GetSourceFilter(o)
					set isFiltered = $$$IKHASBIT($bitlogic(bits & srcBits))
					quit:isFiltered
				}
				set isFiltered = isFiltered
				
			} elseif (type=$$$IKFCRCOCC) {
				
				set sentId = +$lg($g(^IRIS.IK.CrcOccId(i%DomainId,id)),5)
				set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId,sentId)
				$$$IKBITOFFPOS(srcId,srcOff,srcPos)
				set isFiltered = $bit(..GetSourceFilter(srcOff),srcPos)
								
			} elseif (type=$$$IKFENTOCC) || (type=$$$IKFENTOCCC) || (type=$$$IKFENTOCCR) {
				
				set details = $g(^IRIS.IK.EntOccId(i%DomainId,id))
				if (type=$$$IKFENTOCCC) && ($lg(details,2)'=$$$ENTTYPECONCEPT) {
					set isFiltered = 0
				} elseif (type=$$$IKFENTOCCR) && ($lg(details,2)'=$$$ENTTYPERELATION) {
					set isFiltered = 0
				} else {
					set sentId = +$lg(details,3)
					set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(i%DomainId,sentId)
					$$$IKBITOFFPOS(srcId,srcOff,srcPos)
					set isFiltered = $bit(..GetSourceFilter(srcOff),srcPos)
				}
				
			} elseif (type=$$$IKFPATH) {
				
				$$$IKQBCHECKT(i%DomainId,$$$IKBPATH)
				
				set srcId = ##class(%iKnow.Queries.PathAPI).GetSourceId(i%DomainId,id)
				$$$IKBITOFFPOS(srcId,srcOff,srcPos)
				set isFiltered = $bit(..GetSourceFilter(srcOff),srcPos)
				
			}
			
		} else {
			// otherwise, go through the normal secondary fi
			$$$IKBITOFFPOS(id,off,pos)
			set bits = ..GetSecondaryFilter(type,off)
			set isFiltered = $bit(bits, pos)
		}
	}
	
	set @i%FilteredGlo@(type, id) = isFiltered
	quit isFiltered
}

///  <p>Returns the first Source ID satisfying this filter isntances criteria, starting from the
///  lowest (direction 1) or highest Source ID (direction -1). Returns "" when no source is filtered.</p>
Method GetFirstFilteredSource(direction As %Integer = 1) As %Integer
{
	set off = ""
chk	set off = ..GetNextSourceFilterOffset(off,.bits,direction)
	quit:'off 0
	set pos = $bitfind(bits,1,0,direction)
	goto:'pos chk
	$$$IKGETIDOFFPOS(srcId,off,pos)
	quit srcId
}

///  <p>Merges this filter instances internal bitstring representation with the supplied
///  global using AND logic.</p>
Method MergeBits(globName As %String, type As %Integer = {$$$IKFSOURCE}) As %Status [ Internal ]
{
	set offset = ""
	for {
		set offset = $order(@globName@(offset),1,bits)
		quit:offset=""
		
		if (type=$$$IKFSOURCE) {
			set filterBits = ..GetSourceFilter(offset)
		} else {
			set filterBits = ..GetSecondaryFilter(type, offset)
		}
		
		set @globName@(offset) = $bitlogic(bits & filterBits)
	}
	quit $$$OK
}

/// pParams has empty positions for the pPage and pPageSize parameters
/// Only use for queries without ByRef or Output parameters (except pResult) !!
Method CheckResultCache(pQueryClass As %String, pQueryName As %String, pParams As %List, pPage As %Integer, pPageSize As %Integer, Output pIsCached, Output pResult) As %Status
{
	set tSC = $$$OK
	try {
		set pIsCached = 0
		quit:'i%IsCached||$d(^||%IK.NoCache)
		
		set tSC = ..Validate()
		quit:$$$ISERR(tSC)
		
		set tHashedParams = $lb(pQueryClass, pQueryName) _ pParams
		set tParamsHash = $zcrc(tHashedParams,7)
		
		// first find key
		set tKey = ""
		for {
			set tKey = $order(@i%FilteredQParams@(tParamsHash,tKey),1,tParams)
			quit:tKey=""
			quit:$listsame(tParams,tHashedParams)
		}
		// no tKey means definitely no cached results, so quit
		quit:'tKey
		
		// otherwise, check if we have all the results we need
		$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
		
		// first check if the result is fully cached
		set pIsCached = +$g(@i%FilteredQRange@(tKey))
		
		// if not cached, check to what extent the paging window is cached
		if ('pIsCached && tUsePaging) {
			// first try to increase tFirst based on the results we already have
			while (tFirst<tLast) {
				set tCFirst = $order(@i%FilteredQRange@(tKey, tFirst+1),-1,tCLast)
				quit:tCFirst=""
				if (tCLast>=tLast) { set pIsCached=1  quit }
				quit:tFirst>tCLast
				set tFirst = tCLast+1
			}
			
			// if not everything is found, decrease tLast by counting backwards if possible
			while 'pIsCached && (tFirst<tLast) {
				set tCFirst = $order(@i%FilteredQRange@(tKey, tLast+1),-1,tCLast)
				quit:tCFirst=""
				if (tCLast>=tLast) { set tLast = tCFirst-1  continue }
				quit
			}
		
			// if not fully cached, execute the query with updated tFirst and tLast to
			// populate the remaining entries
			if 'pIsCached {
				// first build the parameter array
				kill tParams
				set tParamLength = $ll(pParams), tEmptyPosVal=tFirst
				for i=1:1:tParamLength {
					if '$ld(pParams,i) {
						// add -pPage on the first and -pPageSize on the next empty position
						set tParams(i) = -tEmptyPosVal, tEmptyPosVal = tLast
					} else {
						set tParamValue = $lg(pParams,i)
						if (tParamValue'="") && $isobject(tParamValue) && tParamValue.%Extends("%iKnow.Filters.Filter") {
							set tParamValue = tParamValue.ToString()
						}
						set tParams(i) = tParamValue
					}
				}
				
				// ensure the cache is not checked when calling this method
				set ^||%IK.NoCache = 1
				set tSC = $classmethod(pQueryClass, pQueryName, .tResults, pParams...)
				quit:$$$ISERR(tSC)
				
				// if the above method returned fine, the cache should be full
				set pIsCached=1
			}
		}
		
		// now read the results from the cache
		if pIsCached {	
			$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
			
			if (tUsePaging) {
				for i = tFirst:1:tLast {
					$$$IKQMERGERESULT(pResult,i,@i%FilteredQResult@(tKey,i))
				}
			} else {
				// get all entries
				if $g(pResult)="" {
					merge pResult = @i%FilteredQResult@(tKey)
				} else  {
					merge @pResult = @i%FilteredQResult@(tKey)
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// if an error occurred, ensure the result is clean and mark as not cached
	if $$$ISERR(tSC) {
		set pIsCached = 0
		if $g(pResult)="" { kill pResult } else { kill @pResult }
	}
	
	kill ^||%IK.NoCache
	quit tSC
}

/// Same as <method>CheckResultCache</method>, but for single-result queries
/// Only use for queries without ByRef or Output parameters !!
Method CheckResultCacheSingle(pQueryClass As %String, pQueryName As %String, pParams As %List, Output pIsCached, Output pResult) As %Status
{
	set tSC = $$$OK
	try {
		set pIsCached = 0
		quit:'i%IsCached
		
		set tSC = ..Validate()
		quit:$$$ISERR(tSC)
		
		set tHashedParams = $lb(pQueryClass, pQueryName) _ pParams
		set tParamsHash = $zcrc(tHashedParams,7)
		
		// first find key
		set tKey = ""
		for {
			set tKey = $order(@i%FilteredQParams@(tParamsHash,tKey),1,tParams)
			quit:tKey=""
			quit:$listsame(tParams,tHashedParams)
		}
		// no tKey means definitely no cached results, so quit
		quit:'tKey
		
		// check if cached
		set pIsCached = $d(@i%FilteredQResult@(tParamsHash,tKey), pResult)
		kill:'pIsCached pResult
		
		// if not cached, leave it up to the method to calculate the value normally
		// and wait for them to call StoreResultCacheSingle()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// if an error occurred, ensure the result is clean and mark as not cached
	if $$$ISERR(tSC) {
		set pIsCached = 0
		kill pResult
	}
	
	quit tSC
}

Method StoreResultCache(pQueryClass As %String, pQueryName As %String, pParams As %List, pPage As %Integer, pPageSize As %Integer, ByRef pResult) As %Status
{
	set tSC = $$$OK
	try {
		quit:'i%IsCached
		
		set tSC = ..Validate()
		quit:$$$ISERR(tSC)
		
		set tHashedParams = $lb(pQueryClass, pQueryName) _ pParams
		set tParamsHash = $zcrc(tHashedParams,7)
		
		// first find key
		set tKey = ""
		for {
			set tKey = $order(@i%FilteredQParams@(tParamsHash,tKey),1,tParams)
			quit:tKey=""
			quit:$listsame(tParams,tHashedParams)
		}
		if 'tKey {
			set tKey = $i(@i%FilteredQParams)
			set @i%FilteredQParams@(tParamsHash,tKey) = tHashedParams
		}
		
		// then store results
		$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
		if (tUsePaging) {
			set @i%FilteredQRange@(tKey, tFirst) = tLast
		} else {
			set @i%FilteredQRange@(tKey) = 1
		}
		if ($g(pResult)="") {
			merge @i%FilteredQResult@(tKey) = pResult
		} else {
			merge @i%FilteredQResult@(tKey) = @pResult
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method StoreResultCacheSingle(pQueryClass As %String, pQueryName As %String, pParams As %List, pResult) As %Status
{
	set tSC = $$$OK
	try {
		quit:'i%IsCached
		
		set tSC = ..Validate()
		quit:$$$ISERR(tSC)
		
		set tHashedParams = $lb(pQueryClass, pQueryName) _ pParams
		set tParamsHash = $zcrc(tHashedParams,7)
		
		// first find key
		set tKey = ""
		for {
			set tKey = $order(@i%FilteredQParams@(tParamsHash,tKey),1,tParams)
			quit:tKey=""
			quit:$listsame(tParams,tHashedParams)
		}
		if 'tKey {
			set tKey = $i(@i%FilteredQParams)
			set @i%FilteredQParams@(tParamsHash,tKey) = tHashedParams
		}
		
		// then store results
		set @i%FilteredQResult@(tParamsHash,tKey) = pResult
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetNextSrcId(pSrcId As %Integer) As %Integer
{
	set tMaxOff = $order(^IRIS.IK.SrcExistsBit(i%DomainId,""),-1)
	$$$IKBITOFFPOS(pSrcId,tOff,tPos)
	for {
		quit:tMaxOff<tOff
		set tBits = ..GetSourceFilter(tOff)
		set tPos = $bitfind(tBits,1,tPos+1)
		quit:tPos
		set tOff=tOff+1
	}
	quit:tMaxOff<tOff ""
	$$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
	quit tSrcId
}

/// <p>Converts the supplied string <var>pString</var> into a <class>%iKnow.Filters.Filter</class>
/// object. In addition to the normal <method>RestoreFilterFromString</method> functionality (which
/// expects <var>pString</var> to be the output of a <method>ToString</method> call on a filter
/// object), this method supports the following shorthands:</p>
/// <ul>
/// <li>A comma-separated list of source IDs (fe: "123,45,987" or "654"), resulting in a <class>%iKnow.Filters.SourceIdFilter</class></li>
/// <li>A range of source IDs expressed as [from]:[to] (fe: "1:500", which includes source IDs 1 and 500), resulting in a <class>%iKnow.Filters.SourceIdRangeFilter</class></li>
/// <li>A metadata filter condition [field name][operator][value] (fe: "Year>2000" or "Country!=Canada"), resulting in a <class>%iKnow.Filters.SimpleMetadataFilter</class></li>
/// </ul>
/// <p>Note: while covering a majority of common filter operations, the shorthand syntax is meant
/// to simplify exploration through the command-line and does not handle every possible combination
/// of parameters. Application code should therefore always use regular filter constructor methods
/// and the string representations produced by <method>ToString</method> (which this method also
/// accepts).</p>
ClassMethod FromString(pDomainId As %String, pString As %String, Output pFilter As %iKnow.Filters.Filter) As %Status
{
	set tSC = $$$OK, pFilter=""
	try {
		quit:pString=""
		
		if $isobject(pString) {
			set pFilter = pString
			quit
		}
		
		// List of source IDs
		if $listvalid(pString) {
			set pFilter = ##class(%iKnow.Filters.SourceIdFilter).%New(pDomainId, pString)
		} elseif ($zstrip(pString,"*W") ? .(1.N1",")1.N) { 
			set pFilter = ##class(%iKnow.Filters.SourceIdFilter).%New(pDomainId, $lfs(pString))
		}
		
		// Source ID range
		elseif ($zstrip(pString,"*W") ? 1.N1":"1.N) { 
			set pFilter = ##class(%iKnow.Filters.SourceIdRangeFilter).%New(pDomainId, $piece(pString,":",1), $piece(pString,":",2))
		}
		
		// Metadata-based shortform: [fieldname][operator][value]
		elseif (pString ? .E1(1"=",1">",1"<",1"!=",1">=",1"<=",1"=<",1"=>",1"BETWEEN").E) {
			set l = $ll($$$MDALLOPERATORS), tAPI = $$$IKMETADATAAPI(pDomainId)
			for i = 1:1:l {
				set op = $li($$$MDALLOPERATORS,i)
				set tPos = $find(pString,op)
				continue:'tPos
				set tFieldName = $e(pString,1,tPos-$l(op)-1)
				set tFieldId = $classmethod(tAPI, "GetFieldId", pDomainId, tFieldName)
				continue:tFieldId<=0
				set pFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(pDomainId, tFieldName, op, $e(pString,tPos,*))
				if (pFilter="") { set tSC = %objlasterror } // cascade filter-specific errors
				quit
			}
			quit:$$$ISERR(tSC)
		}
		
		// try default
		set:(pFilter="") pFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(pString)
		
		// if nothing worked, return error
		if (pFilter="") { set tSC = $$$ERROR($$$IKInvalidFilter, pString) }

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ToArray(Output pArray, pType As %Integer = {$$$IKFSOURCE}) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pArray
		
		set tOffset = ""
		for {
			set tOffset = ..GetNextFilterOffset(pType, tOffset, .tBits)
			quit:'tOffset
			
			set tPos = 0
			for {
				set tPos = $bitfind(tBits, 1, tPos+1)
				quit:'tPos
				$$$IKGETIDOFFPOS(tID,tOffset,tPos)
				set pArray(tID) = ""
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ToBitstring(Output pArray, pType As %Integer = {$$$IKFSOURCE}) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pArray
		
		set tSC = ..Validate(pType,.tIsValid)
		quit:$$$ISERR(tSC)
		
		if 'tIsValid {
			lock:i%IsCached +@i%FilteredBitsGlo@(pType):1
			if (i%IsCached && '$test) {
				// if there is already a lock on this global, another filter is populating it,
				// so wait until the lock is removed
				lock +@i%FilteredBitsGlo@(pType)
			} else {
				do ..BuildSourceFilter($order(^IRIS.IK.SrcExistsBit(..DomainId,""),-1))
			}
			lock:i%IsCached -@i%FilteredBitsGlo@(pType)
		}
		
		merge pArray = @i%FilteredBitsGlo@(pType)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod CreateFromBitstring(pDomainId As %Integer, ByRef pBitstring) As %iKnow.Filters.Filter
{
	set tIndex = $i(^||%IK.BitmapFilter)
	kill ^||%IK.BitmapFilter(tIndex)
	merge ^||%IK.BitmapFilter(tIndex) = pBitstring
	quit ##class(%iKnow.Filters.BitmapFilter).%New(pDomainId, $name(^||%IK.BitmapFilter(tIndex)))
}

/// Utility method to return a label for this filter instance. Custom filter classes may
/// override this method to return a nicer label in client applications.
Method GetLabel() As %String
{
	quit $classname()
}

}
