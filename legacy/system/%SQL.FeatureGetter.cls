/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %msql

Class %SQL.FeatureGetter Extends FT.FeatureGetter
{

/// For a number of SQL features that we want to track, it makes the most sense to loop over certain globals as required in order
/// to gather information, so this is done here whenever FT.Collector calls GetInfo() on this class. Note that in the future,
/// there may be some SQL feature tracking that makes more sense to do via shared memory allocated counters, in which case this method could just be extended to
/// merge from those shared memory locations into the key-value $lb built here. More information on the format of the $lb constructed here can be found in the parent class
ClassMethod GetInfo() As %List [ Internal ]
{
	// only run it once a day
	GOTO:(+$g(^IRIS.Temp.SQLFeatureTracker("Metadata", "CacheLastUpdated")) = +$h) BuildReturnList
    
	// this is the return, read FT.FeatureGetter parent class to understand more about the structure expected
    set list = ""
	set countOfForeignTables = 0
	set countOfShardedTables = 0
	set countOfVectors = 0
	set countOfColumnar = 0
	// TODO: embeddings when out of the project branch
	try {
		// Gets a list of all of the namespaces, we have to look at each namespace's globals to get their local classes
		do List^%SYS.NAMESPACE(.nslist)
		new $namespace // To make sure we end up back in the original namespace after we leave this procedure
		set ns = ""
		for { // loop over namespaces
			set ns = $o(nslist(ns))
			QUIT:ns=""
			CONTINUE:(",%SYS,ENSLIB,HSAALIB,HSCOMMLIB,HSLIB,HSPD,HSPDLIB,HSPILIB,HSSYS,VIEWERLIB,"[(","_ns_","))
			// This method is called every hour by FT.Collector, but this logic is too heavy and we don't need that frequency of stat gathering. Instead
			// we will keep a cache in ^IRIS.Temp.SQLFeatureTracker and just pull from that if we've already run this logic today
			// swapNS returns the number of days since we were last able to use ns
			// If swapNS switched to ns, it returns "", so nsIsUnavailable will be a positive integer (i.e. true) if the namespace isn't able to be used
			set nsIsUnavailable = $$swapNS^%SYS.SQLSRV(ns)
			if 'nsIsUnavailable { // $namespace is now ns! 
				set class = ""
				for {
					set class = $$$comClassNext(class)
					QUIT:class=""
					set foundColumnar = 0, foundVector = 0 		// these two require looping so we'll mark them with a boolean and then increment at the very end of each class' loop so that we don't double count
					if $$$comSharded(class) {
						do $i(countOfShardedTables)
					}
					if $$$UPPER($$$comMemberKeyGet(class, $$$cCLASSparameter, "STORAGEDEFAULT", $$$cPARAMdefault)) = "COLUMNAR" {
						set foundColumnar = 1    // flag for later, if true then we know we might not need to spin through the properties and indices
					}
					if $$$IsAForeignTable(class) {
						do $i(countOfForeignTables)
					}
					// loop over this class' properties for vector (and/or columnar if we didn't find columnar already)
					set property = ""
					for  {
						set property = $$$comMemberNext(class,$$$cCLASSproperty,property) 
						QUIT:property=""  
						QUIT:(foundColumnar && foundVector) // if we already found both don't keep looping
						if $$checkDataType^%apiDDL2($$$comMemberKeyGet(class, $$$cCLASSproperty, property, $$$cPROPtype), $lb("%Library.Vector")) {
							set foundVector = 1
						}
						if $$$UPPER($$$comMemberArrayGet(class, $$$cCLASSproperty, property, $$$cPROPparameter, "STORAGEDEFAULT")) = "COLUMNAR" {
							set foundColumnar = 1
						}
					}
					// for columnar, we also need to check indices potentially
					if 'foundColumnar {
						set index = ""
						for {
							set index = $$$comMemberNext(class, $$$cCLASSindex, index)
							QUIT:index=""
							if $$$UPPER($$$comMemberKeyGet(class, $$$cCLASSindex, index, $$$cINDEXtype)) = "COLUMNAR" {
								set foundColumnar = 1
								QUIT // stop looping
							}
						}
					}
					do:foundColumnar $i(countOfColumnar)
					do:foundVector $i(countOfVectors)
				}
			} else {
				continue
			}
		}
	} catch ex {
		// just report data from the cache if we have it?
		GOTO:$d(^IRIS.Temp.SQLFeatureTracker) BuildReturnList
		RETURN ""
	}
	// update the cache
	set ^IRIS.Temp.SQLFeatureTracker("Metadata", "CacheLastUpdated") = +$h
	set ^IRIS.Temp.SQLFeatureTracker("ForeignTables") = countOfForeignTables
	set ^IRIS.Temp.SQLFeatureTracker("ShardedTables") = countOfShardedTables
	set ^IRIS.Temp.SQLFeatureTracker("VectorTables") = countOfVectors
	set ^IRIS.Temp.SQLFeatureTracker("ColumnarTables") = countOfColumnar
BuildReturnList
	// the third argument is the type, 0 means "use this newest value as the current reported value" as opposed to e.g. summing with a previous value etc.
	set $li(list, 1) = $lb("ForeignTables", $g(^IRIS.Temp.SQLFeatureTracker("ForeignTables"), 0), 0)
	set $li(list, 2) = $lb("ShardedTables", $g(^IRIS.Temp.SQLFeatureTracker("ShardedTables"), 0), 0)
	set $li(list, 3) = $lb("VectorTables", $g(^IRIS.Temp.SQLFeatureTracker("VectorTables"), 0), 0)
	set $li(list, 4) = $lb("ColumnarTables", $g(^IRIS.Temp.SQLFeatureTracker("ColumnarTables"), 0), 0)
	// because we new $namespace, leaving this proc will leave us in the calling namespace
	RETURN list
}

/// For now this is relatively useless for us because we are not tracking stats based on a given period. If/when we add in logic to track the frequency
/// of use more granularly (e.g. # of times a foreign table referenced for a stat collection period) this method will become more necessary
ClassMethod Reset() As %Status [ Internal ]
{
	RETURN $$$OK
}

}
