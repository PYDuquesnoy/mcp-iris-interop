/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

///  <p>Utility class grouping some utility and informative methods complementing the iKnow 
///  Query APIs.</p>
Class %iKnow.Queries.Utils Extends %RegisteredObject [ Deprecated, System = 4 ]
{

///  <p>Returns a list of the columns returned by the query identified by the <var>queryClass</var> and
///  <var>queryName</var> parameters in the following format: columns(index) = $lb(name,type). If the 
///  supplied parameters do not correspond to a known query, an error is returned.</p>
ClassMethod GetQueryResultColumns(queryClass As %String, queryName As %String, Output columns) As %Status
{
	kill columns
	
    set qRT = ##class(%Dictionary.CompiledParameter).%OpenId(queryClass _"||"_ queryName _ "RT")
    quit:qRT="" $$$ERROR($$$ParameterDoesNotExist, queryClass_"."_queryName_"RT")
    
    set qRTcols = $lfs(qRT.Default,","), ptr = 0
    while $listnext(qRTcols,ptr,col) {
	    set columns($i(columns)) = $lb($p(col,":",1), $p(col,":",2))
    }
    
    quit $$$OK
}

///  <p>Returns a displayable name for most query parameter names in use. If no more readable
///  form is available (for example if it's too trivial), <var>paramName</var> itself is returned.</p>
ClassMethod GetParameterDisplayName(paramName As %String) As %String
{
	quit $case($zconvert(paramName,"U"),
				"PAGE":"page", "PPAGE":"page",
				"PAGESIZE":"page size", "PPAGESIZE":"page size",
				"SETOP":"set operation", "PSETOP":"set operation",
				"ENTTYPE":"entity type", "PENTTYPE":"entity type",
				"SORTTYPE":"sort type", "PSORTTYPE":"sort type",
				"AGGTYPE":"aggregation type", "PAGGTYPE":"aggregation type",
				"FILTERMODE":"filter mode", "PFILTERMODE":"filter mode",
				"POSITIONSTOMATCH":"positions to match", "PPOSITIONSTOMATCH":"positions to match",
				:$zconvert(paramName,"L"))
}

///  <p>Returns a list of the possible parameter values for a number of common query parameters in a
///  variable containing key-displayValue pairs: values(i) = $lb(key, value). The %Boolean returned
///  expresses whether this is a known parameter for which a meaningful list of values can be returned.</p>
///  <p>The optional <var>queryClass</var> and <var>queryName</var> parameters
///  will in some cases limit the possible values to the allowed ones supported by that particular query.</p>
///  <p><b>Note:</b> for the "pageSize" parameter, this method will return a limited number of possible values
///  to make this method more useful for internal purposes, but obviously any positive numeric value will do.</p>
ClassMethod GetParameterValues(paramName As %String, Output values, queryClass As %String = "", queryName As %String = "") As %Boolean
{
	kill values
	set paramName = $zconvert(paramName,"U")
	
	if (paramName = "PAGESIZE") || (paramName = "PPAGESIZE") {
		set values($i(values)) = $lb(10,10)
		set values($i(values)) = $lb(20,20)
		set values($i(values)) = $lb(50,50)
		set values($i(values)) = $lb(100,100)
	} elseif (paramName = "SETOP") || (paramName = "PSETOP") {
		set values($i(values)) = $lb($$$UNION,"union")
		set values($i(values)) = $lb($$$INTERSECT,"intersect")
	} elseif (paramName = "ENTTYPE") || (paramName = "PENTTYPE") {
		set:queryName'="GetTop" values($i(i)) = $lb($$$ENTTYPEANY,"any type")
		set values($i(values)) = $lb($$$ENTTYPECONCEPT,"concept")
		set values($i(values)) = $lb($$$ENTTYPERELATION,"relation")
	} elseif (paramName = "SORTTYPE") || (paramName = "PSORTTYPE") {
		set values($i(values)) = $lb($$$SORTBYDOMAINDEFAULT,"domain default")
		set values($i(values)) = $lb($$$SORTBYFREQUENCY,"frequency")
		set values($i(values)) = $lb($$$SORTBYSPREAD,"spread")
		set:queryClass="%iKnow.Matching.MatchingAPI" values($i(i)) = $lb($$$SORTBYSCORE,"match score")
	} elseif (paramName = "AGGTYPE") || (paramName = "PAGGTYPE") {
		set values($i(values)) = $lb($$$AGGSUM,"sum")
		set values($i(values)) = $lb($$$AGGAVG,"average")
		set values($i(values)) = $lb($$$AGGMIN,"minimum")
		set values($i(values)) = $lb($$$AGGMAX,"maximum")
	} elseif (paramName = "FILTERMODE") || (paramName = "PFILTERMODE") {
		set values($i(values)) = $lb($$$FILTERONLY,"filter only")
		set values($i(values)) = $lb($$$FILTERFREQ,"recalculate frequency")
		set values($i(values)) = $lb($$$FILTERSPREAD,"recalculate spread")
		set values($i(values)) = $lb($$$FILTERALL,"recalculate frequency & spread")
		set values($i(values)) = $lb($$$FILTERFREQANDSORT,"recalculate frequency and resort")
		set values($i(values)) = $lb($$$FILTERSPREADANDSORT,"recalculate spread and resort")
		set values($i(values)) = $lb($$$FILTERALLANDSORT,"recalculate frequency & spread and resort")
	} elseif (paramName = "MODE") || (paramName = "PMODE") {
		if (queryClass = "%iKnow.Queries.EntityAPI") && (queryName = "GetSimilar") {
			set values($i(values)) = $lb($$$USEPARTS,"word-part-based")
			set values($i(values)) = $lb($$$USENGRAMS,"Ngram-based")
			set values($i(values)) = $lb($$$USEWORDS,"word-based")
		}
	} elseif (paramName = "POSITIONSTOMATCH") || (paramName = "PPOSITIONSTOMATCH") {
		set values($i(values)) = $lb($$$USEPOSH,"head only")
		set values($i(values)) = $lb($$$USEPOST,"tail only")
		set values($i(values)) = $lb($$$USEPOSHT,"head or tail")
		set values($i(values)) = $lb($$$USEPOSALL,"any")
		if (queryClass = "%iKnow.Queries.CrcAPI") {
			set values($i(values)) = $lb($$$USEPOSR,"relation only")
			set values($i(values)) = $lb($$$USEPOSHR,"head or relation")
			set values($i(values)) = $lb($$$USEPOSRT,"relation or tail")
		}
	} elseif (paramName = "ALGORITHM") || (paramName = "PALGORITHM") {
		if (queryClass = "%iKnow.Queries.SourceAPI") && (queryName = "GetSimilar") {
			set values($i(values)) = $lb($$$SIMSRCSIMPLE,"simple")
			set values($i(values)) = $lb($$$SIMSRCEQUIVS,"equivalents")
			set values($i(values)) = $lb($$$SIMSRCDOMENTS,"dominant entities")
		} elseif (queryName = "GetNewBySource") {
			set values($i(values)) = $lb($$$NEWENTSIMPLE,"simple")
		}
	}
	
	quit +$d(values)
}

///  <p>This utility method executes a query of one of the primary iKnow query APIs (with the *API suffix),
///  as identified by <var>pQueryClass</var> and <var>pQueryName</var>, and writes the output as a
///  CSV file to <var>pFilename</var>. This will overwrite the output file if it already exists and
///  the output will include a header line containing column names and types.</p>
///  <p><var>pQueryParams...</var> is to contain all the parameters you would normally supply
///  to the query, except for its ByRef <var>result</var> parameter, which is taken care of by
///  this utility.</p>
///  <p>For example, a query defined as <pre>User.MyAPI.GetXByY(ByRef result, domainId As %Integer, x As %String,
///  y As %String)</pre> will be called as follows:</p>
///  <blockQuote><pre>do ##class(%iKnow.Queries.Utils).DumpQueryResult("C:\temp\myFile.csv", 
///  "User.MyAPI", "GetXByY", domainId, x, y)</pre></blockQuote>
ClassMethod DumpQueryResult(pFilename As %String, pQueryClass As %String, pQueryName As %String, pQueryParams...) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = $classmethod(pQueryClass, pQueryName, "^||%IKQ.Result", pQueryParams...)
		quit:$$$ISERR(tSC)
	
		set tFile = ##class(%Stream.FileCharacter).%New()
		set tFile.Filename = pFilename
		
		set tRT = ##class(%Dictionary.ParameterDefinition).%OpenId(pQueryClass_"||"_pQueryName_"RT")
		if (tRT '= "") {
			set tSC = tFile.WriteLine(tRT.Default)
			quit:$$$ISERR(tSC)
			set tRT=""
		}
	
		set i=""
		for {
			set i = $order(^||%IKQ.Result(i),1,tData)
			quit:i=""
		
			set tSC = tFile.WriteLine($lts(tData))
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
	
		set tSC = tFile.%Save()
		set tFile=""
	
	} catch (ex) {
		set tSC = ex.AsStatus()
		set tFile = ""
	}
	quit tSC
}

}
