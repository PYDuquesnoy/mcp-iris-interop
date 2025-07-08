/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// <p>This class offers a read-only implementation for most of the
/// <class>%iKnow.Queries.MetadataI</class> interface in DeepSee-managed domains. It exposes all
/// available dimension levels and measures for the cube managing the domain. This enables
/// iKnow-style query filtering using the result of <method>CreateFilter</method> as a convenient
/// alternative to manually instantiating MDX or SQL-based filter objects.</p>
/// <p>The "virtual" metadata fields exposed this way can be referenced by name or MDX spec and
/// will be resolved as follows:
/// <ol>
/// 	<li>[dimName].[hierName].[levelName]</li>
/// 	<li>dimName.hierName.levelName</li>
/// 	<li>[dimName].[levelName]</li>
/// 	<li>dimName.levelName</li>
/// 	<li>[measures].[msrName]</li>
/// 	<li>levelName</li>
/// 	<li>msrName</li>
/// 	<li>factName</li>
/// </ol>
/// <p>If the spec is not complete (missing hierarchy and/or dimension, the "field name" is
/// resolved as the first level, measure or fact found with a corresponding name. Therefore, it
/// is recommended to use full specifications as soon as there is a potential name conflict.
/// When working with fact names, the values in the cube's Fact table are considered to be the
/// desired results and no star tables will be queried.</p>
/// <p>For iKnow-managed domains, use <class>%iKnow.Queries.MetadataAPI</class>.</p>
/// <p>NOTE: this does not support cube relationships or calculated members</p>
Class %iKnow.DeepSee.MetadataAPI Extends %iKnow.Queries.MetadataI [ Deprecated, System = 4 ]
{

/// Creates a <class>%iKnow.Filters.Filter</class> object for filtering sources according to
/// the provided criteria.
ClassMethod CreateFilter(pDomainId As %Integer, pFieldName As %String, pOperator As %String, pValue As %String, Output pSC As %Status = {$$$OK}) As %iKnow.Filters.Filter
{
	set pSC = $$$OK, tFilter = ""
	try {
		set pOperator = $zstrip(pOperator,"<=>W")
		if '$$$GETPARAMNODEF(pDomainId,$$$IKPDEEPSEEDOMAIN) {
			set pSC = $$$ERROR($$$GeneralError, "Feature only supported for DeepSee-managed domains")
			quit
		}
		
		set tCubeName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSCUBE)
		
		set pSC = ..GetFactInfo(pDomainId, pFieldName, .tFactName, .tType, .tFullSpec)
		quit:$$$ISERR(pSC)
		
		if (tType = "fact") {
			
			// go to fact table using a SqlFilter
			set tQuery = "SELECT ID SourceId FROM "_##class(%DeepSee.Utils).%GetCubeFactTable(tCubeName, .pSC)
			quit:$$$ISERR(pSC)
			
			set tQuery = tQuery _ " WHERE " _ tFactName _ " " _ pOperator
			if ($$$UPPER(pOperator) = $$$MDOPBETWEEN) {
				set tQuery = tQuery _ $p(pValue,$$$MDVALSEPARATOR,1) _ " AND " _ $p(pValue,$$$MDVALSEPARATOR,2)
			} else {
				set tQuery = tQuery _ "'" _ pValue _ "'"
			}
			set tFilter = ##class(%iKnow.Filters.SqlFilter).%New(pDomainId, tQuery)
	
		} elseif (tType = "dimension") {
			
			// TODO: date dimensions could accept more operators and can maybe better be accessed
			// through SQL
			
			if '$lf($lb("=","!="),pOperator) {
				set pSC = $$$ERROR($$$GeneralError, "Only the following operators are supported for this filter type: =, !=")
				quit
			}
			
			set tMDX = tFullSpec _ ".["_pValue_"]"
			set:pOperator="!=" tMDX = tMDX _ ".%NOT"
			set tFilter = ##class(%iKnow.DeepSee.MDXFilter).%New(pDomainId, tMDX)
			
		} else { // tType = "measure"
			
			set tMDX = "%SEARCH.&[" _ tFullSpec _ pOperator _ pValue _ "]"
			set tFilter = ##class(%iKnow.DeepSee.MDXFilter).%New(pDomainId, tMDX)
			
		}
		
		set pSC = $s(tFilter="":%objlasterror, 1:$$$OK)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tFilter
}

/// Returns the full MDX spec for the given <var>pFieldName</var>, which can be used as an
/// identifier for this field.
ClassMethod GetFieldId(pDomainId As %Integer, pFieldName As %String, Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = ..GetFactInfo(pDomainId, pFieldName, .tFactName,, .tFullSpec)
	quit $g(tFullSpec)
}

/// Resolves a metadata field name and returns various pieces of information about it.
ClassMethod GetFactInfo(pDomainId As %Integer, pFieldName As %String, Output pFactName As %String = "", Output pType As %String = "", Output pFullSpec As %String = "", Output pDimType As %String = "") As %Status [ Internal ]
{
	#define StripSquareBrackets(%s) set:$e(%s)="[" %s = $e(%s,2,*-1)
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		quit:'$$$GETPARAMNODEF(pDomainId,$$$IKPDEEPSEEDOMAIN)
		quit:pFieldName=""
		
		set tCubeName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSCUBE)
		set tCubeIndex = $$$UPPER(tCubeName)
		
		set tLength = $l(pFieldName,".")
		if (tLength=3) {
			
			set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName, pFieldName, .tDimNo, .tHierNo, .tLevelNo,,,.tSpecInfo)
			quit:$$$ISERR(tSC)
			
			set pType = "dimension"
			
		} else {
			if ($$$UPPER($p(pFieldName,".",1))="[MEASURES]") {
				
				set tMeasureName = $p(pFieldName,".",2)
				$$$StripSquareBrackets(tMeasureName)
				
				set tInfo = $g($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", "MEASURES", $$$UPPER(tMeasureName)))
				set pType = "measure"
				
			} elseif (tLength=2) {
				
				set tDimName = $$$UPPER($p(pFieldName,".",1))
				$$$StripSquareBrackets(tDimName)
				set tLevelName = $$$UPPER($p(pFieldName,".",2))
				$$$StripSquareBrackets(tLevelName)
				
				set tHierName = ""
				for {
					set tHierName = $order($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", tDimName, tHierName))
					quit:tHierName=""
					
					set tInfo = $g($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", tDimName, tHierName, tLevelName))
					quit:tInfo'=""
				}
				set pType = "dimension"
				
			} else {
				set tName = pFieldName
				$$$StripSquareBrackets(tName)
				set tNameIndex = $$$UPPER(tName)
				
				// check levelName
				set tDimName = "", tInfo=""
				for {
					set tDimName = $order($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", tDimName))
					quit:tDimName=""
					
					set tHierName = ""
					for {
						set tHierName = $order($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", tDimName, tHierName))
						quit:tHierName=""
						
						set tInfo = $g($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", tDimName, tHierName, tNameIndex))
						quit:tInfo'=""
					}
					quit:tInfo'=""
				}
				set:tInfo'="" pType = "dimension"
				
				// check measureName
				if tInfo="" {
					set tInfo = $g($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "mbrs", "MEASURES", tNameIndex))
					set:tInfo'="" pType = "measure"
				}
				
				// check factname
				if tInfo="" && (tName'="") && $d($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "fact", "prop", tName), tFactNo) {
					set tFactName = tName, pType = "fact"
					quit
				}
			}
			
			quit:tInfo=""
			set tDimNo=$lg(tInfo,1), tHierNo=$lg(tInfo,2), tLevelNo=$lg(tInfo,3)
		}
		
		set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(tCubeName, tDimNo, tHierNo, tLevelNo, .pFactName)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%DeepSee.Utils).%GetDimensionSpec(tCubeName, .pFullSpec, tDimNo, tHierNo, tLevelNo)
		quit:$$$ISERR(tSC)
		
		if (pType="dimension") && (pFactName'="") {
			set pDimType = $g($$$DeepSeeMetaGLVN("cubes", tCubeIndex, "fact", "prop", pFactName, "type"))
		} else {
			set pDimType = ""
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit:$$$ISERR(tSC) tSC
	quit $s(pFactName="":$$$ERROR($$$GeneralError, "No cube level, measure or fact name found for given field name '"_pFieldName_"'"), 1:$$$OK)
}

/// Returns the actual value for a given metadata field (by name) and source (by External ID).
ClassMethod GetValue(pDomainId As %Integer, pFieldName As %String, pExternalId As %String, Output pSC As %Status) As %String
{
	set pSC = $$$OK, tValue = ""
	try {
		if '$$$GETPARAMNODEF(pDomainId,$$$IKPDEEPSEEDOMAIN) {
			set pSC = $$$ERROR($$$GeneralError, "Feature only supported for DeepSee-managed domains")
			quit
		}
		
		set tCubeName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSCUBE)
		
		set pSC = ..GetFactInfo(pDomainId, pFieldName, .tFactName, .tType, .tFullSpec, .tDimType)
		quit:$$$ISERR(pSC)
		
		set tSrcId = +pExternalId
		
		if (tType = "fact") || (tType = "measure") || ($e(tDimType)="%") {
			
			set tQuery = "SELECT "_tFactName_" FROM "_##class(%DeepSee.Utils).%GetCubeFactTable(tCubeName, .pSC)
			quit:$$$ISERR(pSC)
			set tQuery = tQuery _ " WHERE ID = " _ tSrcId
			
			set tStatement = ##class(%SQL.Statement).%New()
			set pSC = tStatement.%Prepare(tQuery)
			quit:$$$ISERR(pSC)
			#dim tResult As %SQL.StatementResult = tStatement.%Execute()
			do tResult.%Next(.pSC)
			quit:$$$ISERR(pSC)
			
			set tValue = tResult.%GetData(1)
			
		} else { // (tType = "dimension")
			
			set tQuery = "SELECT d."_tFactName_" FROM "_##class(%DeepSee.Utils).%GetCubeFactTable(tCubeName, .pSC) _ " f, "
			// TODO: check if we don't need to go through ^DeepSee.Cubes("cubes",tCubeIndex,"star",...)
			set tQuery = tQuery _ ##class(%iFind.Utils).QuoteDelimitedIdentifier(##class(%DeepSee.Utils).%GetSQLTableName(tDimType)) _ " d"
			quit:$$$ISERR(pSC)
			set tQuery = tQuery _ " WHERE f.ID = " _ tSrcId _ " AND f." _ tFactName _ " = d.ID"
			
			set tStatement = ##class(%SQL.Statement).%New()
			set pSC = tStatement.%Prepare(tQuery)
			quit:$$$ISERR(pSC)
			set tResult = tStatement.%Execute()
			do tResult.%Next(.pSC)
			quit:$$$ISERR(pSC)
			
			set tValue = tResult.%GetData(1)
			
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tValue
}

Parameter GetFieldsRT [ Internal ] = "mdFieldId:%String,fieldName:%String,supportedOperators:%List,dataType:%String,storage:%Integer,caseSensitive:%Boolean,lovId:%Integer,validateLov:%Boolean,hidden:%Boolean";

/// <p>Returns a list of all the "virtualized" metadata fields exposed for a DeepSee-managed domain
/// in an array: pFields(n) = $lb(fieldName, fullSpec, [dimension|measure]). Please note the
/// returned field names are not necessarily unique across the whole cube, so using
/// the full specificiation (returned as the first column) is safer.</p>
/// <p>Because of the "virtual" nature of these fields, only the fieldName (2nd) and supportedOperators (3rd)
/// output columns are to be taken into account. The <var>pIncludeHidden</var> parameter is ignored.</p>
ClassMethod GetFields(ByRef pFields As %Integer, pDomainId As %Integer, pIncludeHidden As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		kill pFields
		if '$$$GETPARAMNODEF(pDomainId,$$$IKPDEEPSEEDOMAIN) {
			set pSC = $$$ERROR($$$GeneralError, "Feature only supported for DeepSee-managed domains")
			quit
		}
		
		set tCubeName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSCUBE)
		
		set tSC = ##class(%DeepSee.Utils).%GetCubeLevels(tCubeName, .tLevels, 1, 0)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tLevels(i), 1, tLevel)
			quit:i=""
			
			set tType = $li(tLevel,1)
			if tType="m" {
				set pFields($i(tCount)) = $lb("[MEASURES].["_$li(tLevel,3)_"]", $li(tLevel,3), $$$MDALLOPERATORS,,,,,,)
			} elseif (tType="l") {
				set pFields($i(tCount)) = $lb("["_$li(tLevel,2)_"].["_$li(tLevel,3)_"].["_$li(tLevel,4)_"]", $li(tLevel,4), $lb($$$MDOPEQUAL,$$$MDOPNOTEQUAL),,,,,,,)
			}
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetFieldInfoById(pDomainId As %Integer, pFieldId As %String, Output pInfo) As %Status
{
	quit ..GetFieldInfo(pDomainId, pFieldId, .pInfo)
}

ClassMethod GetFieldInfo(pDomainId As %Integer, pFieldName As %String, Output pInfo) As %Status
{
	kill pInfo
	set tSC = $$$OK
	try {
		set tSC = ..GetFactInfo(pDomainId, pFieldName,,, .tSpec)
		set pInfo("SupportedOperators") = $lts($s(($e(tSpec,1,10)="[MEASURES]"):$$$MDALLOPERATORS, 1:$lb($$$MDOPEQUAL,$$$MDOPNOTEQUAL)))
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Use <method>GetValue</method> instead.
ClassMethod GetValueById(pDomainId As %Integer, pFieldId As %Integer, pSrcId As %Integer, Output pSC As %Status) As %String
{
	set pSC = $$$ERROR($$$NotImplemented)
	quit ""
}

ClassMethod SetValue(domainId As %Integer, fieldName As %String, externalId As %String, value As %String) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

ClassMethod SetValueById(domainId As %Integer, fieldId As %Integer, srcId As %Integer, value As %String) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

ClassMethod AddField(domainId As %Integer, fieldName As %String, supportedOperators As %List, dataType As %String = {$$$MDDTSTRING}, storage As %Integer = {$$$MDSTNORMAL}, caseSensitive As %Boolean = 0, lovId As %Integer = -1, validateLov As %Boolean = 1, hidden As %Boolean = 0) As %Integer
{
	quit -1
}

ClassMethod EndBatch(domainId As %Integer) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

ClassMethod StartBatch(domainId As %Integer) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

}
