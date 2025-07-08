/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a computed dimension that uses SQL statements against
/// the cube fact table to resolve members.<br/>
/// For example:<br/>
/// &[SELECT ID FROM $$$TABLE WHERE MxUnitsSold > 4]<br/>
/// -- $$$TABLE is replaced with Fact Table name.<br/>
/// WHERE %SEARCH.&[MxUnitsSold > 4]<br/>
/// -- Expression is used as WHERE clause in query on FactTable 
/// WHERE %SEARCH.&[$$$FACT > 4]<br/>
/// -- $$$Fact is fact defined for the computed dimension.
/// 
Class %DeepSee.ComputedDimension.SQL Extends %DeepSee.ComputedDimension.Base [ System = 4 ]
{

Parameter BEHAVIOR = "SQL";

/// Controls whether results of <method>%OnComputeBitset</method> can be reused
/// Available values are "NEVER", "CHECK", with NEVER meaning no values
/// are cached and CHECK meaning the timestamp of previous %OnComputeBitset results is
/// compared to the cube's latest update timestamp.
Parameter CACHECOMPUTEDBITSET As STRING [ Constraint = ",NEVER,CHECK", Flags = ENUM ] = "CHECK";

/// Resolve any special tokens or expression in a key value and return the result.
Method %ResolveKey(pSpec As %String, Output pRKey As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSQL = ""
		Set tTable = ..%GetFactTable()
		
		// process SQL
		Set tSubstList("TABLE") = tTable
		Set tSubstList("FACT") = ..%factName
	
		Set tSQL = ..%ProcessSQL(pSpec,.tSubstList,.tFirstToken,.tErrorMsg)
		If (tErrorMsg'="") {
			Set tSC = $$$ERROR($$$GeneralError,"Error in key expression: " _ tErrorMsg)
			Quit
		}

		// There can be different forms of query
		// SELECT, CALL or WHERE (WHERE is implied, if neither SELECT nor CALL)
		If (($$$UPPER(tFirstToken)'="SELECT")&&($$$UPPER(tFirstToken)'="CALL")) {		
			If ($$$UPPER(tFirstToken)="WHERE") {
				Set tSQL = "SELECT ID FROM " _ tTable _ " " _ tSQL
			}
			Else {
				Set tSQL = "SELECT ID FROM " _ tTable _ " WHERE " _ tSQL
			}
		}
		Set pRKey = "&["_tSQL_"]" // JSL4431 - enclose in & brackets
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build the bitset that corresponds to the given computed dimension "spec".
Method %OnComputeBitset(pSpec As %String, pIndexKey As %String) As %Status
{
	Set tSC = $$$OK
	Set tCubeKey = $$$UPPER(..%cube)
	
	// DTB295 - A series of tests to see if the direct-index optimization can be used
	Set tSpecIsSingleComparison = 0
	Set tIsSearchable = 0
	Set tValueIsNumeric = 0
	Set tMeasureSpec = ""
	Set tValue = ""
	
	Try {
		Set tSQL = ""
		
		If (..%factNumber = -1) {
			// DTB717 - %SQLRESTRICT dimension. The spec as presented is the restriction, providing a list of IDs
			// that needs to be applied to the fact table's %sourceId field.
			Set tSQLRestrict = pSpec
			
			If ($E(pSpec,1,2)="&[") { // JSL4431
				// DTB112 - removing &[ and ] using $E() is not robust--parse the key to properly expose the identifier
				Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pSpec,.tInfo)
				Set tKeyRestrict = tInfo(1)
			}
			Else {
				Set tKeyRestrict = pSpec
			}
			Set tKeyRestrict = $ZSTRIP(tKeyRestrict,"<>W")		// DTB717 - Strip leading and following white space
			Set tTable = ..%GetFactTable()
			
			// Check the first token of the sql restriction. It must be either a "SELECT" or a "WHERE"
			Set tFirstToken = $$$UPPER($P(tKeyRestrict," ",1))
			If (tFirstToken="SELECT") {
				Set pSpec = "SELECT ID FROM " _ tTable _ " WHERE %sourceId IN (" _ tKeyRestrict _ ")"
			}
			ElseIf (tFirstToken="WHERE") {
				Set tSourceTable = ..%GetSourceTable()
				Set pSpec = "SELECT ID FROM " _ tTable _ " WHERE %sourceId IN (SELECT ID FROM " _ tSourceTable _ " " _ tKeyRestrict _ ")"
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"%SQLRESTRICT statement must begin with either 'SELECT' or 'WHERE'")
				Quit
			}
		}
		
		If $$$DeepSeeOptimizer("searchableMeasureSqlChunk",1,1) {
			// DTB643 - Revert DTB295 to use a single optimized API
			Set tSC = ..%ResolveKey(pSpec,.tSQL)
			If $$$ISERR(tSC) Quit
			
			If ($E(tSQL,1,2)="&[") { // JSL4431
				// DTB112 - removing &[ and ] using $E() is not robust--parse the key to properly expose the identifier
				Do ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tSQL,.tInfo)
				Set pKey = tInfo(1)
			}

			Set tSC = ..%CreateIndexFromSQL(tSQL,pIndexKey)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// DTB295 - Use an ordered list of comparisons to count the comparisons present in the pSpec
			Set tComparisonDefs(1) = "<="
			Set tComparisonDefs(2) = ">="
			Set tComparisonDefs(3) = "<>"
			Set tComparisonDefs(4) = "<"
			Set tComparisonDefs(5) = ">"
			Set tComparisonDefs(6) = "="
			
			Set tSpec = pSpec			// This temp variable will get mangled and thrown away--it is just for counting comparisons
			Kill tComparisons
			Set tComparisonIdx = $O(tComparisonDefs(""),1,tComparisonDef)
			While tComparisonIdx'="" {
				Set tComparisonPos = $Find(tSpec,tComparisonDef)
				While tComparisonPos {
					Set tComparisons($I(tComparisons)) = tComparisonDef
					// Remove the current comparison operator so that "<=" does not get counted as "<=", "<", and "="
					Set tSpec = $Extract(tSpec,0,tComparisonPos-1-$L(tComparisonDef)) _ "##" _ $Extract(tSpec,tComparisonPos,*)
					
					Set tComparisonPos = $Find(tSpec,tComparisonDef)
				}
				
				Set tComparisonIdx = $O(tComparisonDefs(tComparisonIdx),1,tComparisonDef)
			}
			
			If $G(tComparisons)=1 {
				// DTB295 - Only apply the optimization if there is a single comparison in the pSpec.
				// If the pSpec is complex, eg
				//   (x < A) AND (y > B)
				// still use the SQL (non-optimized) approach.
				Set tSpecIsSingleComparison = 1
				Set tComparison = tComparisons(1)
			}

			If +$G(tSpecIsSingleComparison) {
	            // DTB295 - It looks like the pSpec contains one comparison, check to make sure
	            // the first term is in fact a searchable measure and that the value entered is in fact numeric
	            Set tMeasureSpec = $P(pSpec,tComparison,1)
	            Set tValue = $ZSTRIP($P(pSpec,tComparison,2),"<>W")		// DTB335 - $ZStrip instead of +
	            
	            Set tValueIsNumeric = $IsValidNum(tValue) 
	            If tValueIsNumeric {
		            Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeKey,tMeasureSpec,.tDim,.tHier,.tLevel)
		            If $$$ISERR(tSC) Quit
		            
		            // Test to see if we expect an index to be present
		            If (tDim'="")&&(tHier'="")&&(tLevel'="") {
		            	Set tIsSearchable = (tDim=0)&&+$LG($$$DeepSeeMetaGLVN("cubes",tCubeKey,"mbr#",tDim,tHier,tLevel),13)
		            }
	            }
		        
		        Set tUseOptimized = (tIsSearchable&&tValueIsNumeric)
	        
	        	// Perform additional tests to turn off optimization in certain cases
	        	If tUseOptimized && 
	    			( (tDim'="")&&(tHier'="")&&(tLevel'="")&&
	    			($LG($$$DeepSeeMetaGLVN("cubes",tCubeKey,"mbr#",tDim,tHier,tLevel),8)="age")) {
		        	// Age measures require a change in the SQL provided by %ResolveKey
		        	Set tUseOptimized = 0
	        	}
	        }
	        
			If +$G(tUseOptimized) {
				// DTB295 - The index can be constructed directly from a searchable measure
				Set tMeasureNo = $LG($$$DeepSeeMetaGLVN("cubes",tCubeKey,"mbr#",tDim,tHier,tLevel),5)
				
				Set tPropName = $G($$$DeepSeeMetaGLVN("cubes",tCubeKey,"msr#",tMeasureNo))
				
				Set tSQLColumnName = $G($$$DeepSeeMetaGLVN("cubes",tCubeKey,"fact","prop",tPropName,"alias"))
				Set tSearchIndexName = $S(tSQLColumnName'="":tSQLColumnName,1:tPropName)_"Search"
				
				Set tSC = ..%CreateIndexFromSearchableMeasure(tSearchIndexName,tComparison,tValue,pIndexKey)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set tSC = ..%ResolveKey(pSpec,.tSQL)
				If $$$ISERR(tSC) Quit
				
				Set tSC = ..%CreateIndexFromSQL(tSQL,pIndexKey)
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute a search for members.<br/>
/// Return a list of the form:<br/>
/// pList(n) = $LB(value,key)
Method %MemberSearch(pSearchKey As %String, Output pList As %List) As %Status
{
	Quit ..%MemberSearchByMembers(pSearchKey,.pList)
}

}
