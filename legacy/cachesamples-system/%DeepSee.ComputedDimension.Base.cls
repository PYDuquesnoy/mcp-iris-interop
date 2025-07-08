/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This is the base class for DeepSee computed dimension classes.<br/>
/// A computed dimension class defines the behavior for a level within a hierarchy within 
/// a DeepSee computed dimension.<br/>
Class %DeepSee.ComputedDimension.Base Extends %RegisteredObject [ System = 3 ]
{

/// Type reported back to the UI. This determines what type of control to display
/// for filters based on this class.
Parameter DIMTYPE As STRING = "text";

/// Controls whether results of <method>%OnComputeBitset</method> can be reused
/// Available values are "NEVER", "CHECK", with NEVER (default) meaning no values
/// are cached and CHECK meaning the timestamp of previous %OnComputeBitset results is
/// compared to the cube's latest update timestamp.
Parameter CACHECOMPUTEDBITSET As STRING [ Constraint = ",NEVER,CHECK", Flags = ENUM ] = "NEVER";

/// Controls the run-time behavior of the dimension.
/// Available values are "BITSET", and "MDX".<br/>
/// BITSET (default) indicates that this class will compute a set of bits that define
/// membership within a given dimension member.<br/>
/// MDX indicates that this class will return a set of valid MDX expressions that will be
/// used to resolve the members of the dimension.
Parameter BEHAVIOR As STRING [ Constraint = ",BITSET,MDX", Flags = ENUM ] = "BITSET";

/// Name of the cube the computed level belongs to.
Property %cube As %DeepSee.Datatype.string;

/// Name of the base cube the computed level belongs to, if ..%cube is a subject area.
/// Otherwise, this property is set to the same value as ..%cube.
Property %baseCube As %DeepSee.Datatype.string;

/// Fact # of the computed level.
Property %factNumber As %Integer;

/// Fact Name associated with the computed level.
/// This is the name of the fact that contains the default search data.
Property %factName As %String;

/// Dimension # of the computed level.
Property %dimNumber As %Integer;

/// Hierarchy # of the computed level.
Property %hierNumber As %Integer;

/// Level # of the computed level.
Property %levelNumber As %Integer;

/// Return the type of this class (used by UI components).
ClassMethod %GetDimType() As %String
{
	Quit ..#DIMTYPE
}

/// Return the behavior of this class.
ClassMethod %GetBehavior() As %String
{
	Quit ..#BEHAVIOR
}

/// Return number of members.
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCube = $$$UPPER(pCube)
	Set tCount = 0
	// count number of pre-defined members
	Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",""))
	While (p'="") {
		Set tCount = tCount + 1
		Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",p))
	}

	Quit tCount
}

/// Given a level name, <var>pLevelName</var>, return the corresponding level number.
/// Return "" if there is no level with the name.
ClassMethod %GetLevelNumber(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelName As %String) As %Integer
{
	Set tCube = $$$UPPER(pCube)
	Set tLevelNo = ""

	// look in cube meta data
	If (pLevelName'="") {
		Set l = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,""),1,tInfo)
		While (l'="") {
			If ($LG(tInfo,1)="l") {
				If ($$$UPPER($LG(tInfo,4))=$$$UPPER(pLevelName)) {
					Set tLevelNo = l
					Quit
				}
			}
			Set l = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,l),1,tInfo)
		}
	}

	Quit tLevelNo
}

/// Create a instance of this dimension class.
ClassMethod %Create(pCube As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %DeepSee.ComputedDimension.Base
{
	Set tObj = ..%New()
	Set tObj.%cube = $$$UPPER(pCube)
	Set tObj.%factNumber = pFactNo
	Set tObj.%dimNumber = pDimNo
	Set tObj.%hierNumber = pHierNo
	Set tObj.%levelNumber = pLevelNo
	
	// BDB313 - base cube name resolution
	set tObj.%baseCube = $$$DeepSeeIndex(pCube)

	// See if there is a fact name for this level
	Set tFactName = ""

	// lookup member name field from meta data
	Set tFactName = $LG($G($$$DeepSeeMetaGLVN("cubes",tObj.%cube,"mbr#",pDimNo,pHierNo,pLevelNo)),7)

	// JMD890: if we are an iKnow dimension, get the name of the iKnow Measure
	If (tFactName'="") {
		Set tIKMsr = $G($$$DeepSeeMetaGLVN("cubes",tObj.%cube,"fact","prop",tFactName,"iKnowMsr"))
		If (tIKMsr'="") {
			Set tFactName = tIKMsr
		}
	}
	Set tObj.%factName = tFactName
	Quit tObj
}

/// Test if <var>pName</var> is a valid member name.
Method %FindComputedMemberByName(pName As %String, Output pFlag As %Boolean, Output pMemberKey As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set tName = $$$UPPER(pName)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the member with the given key value.
Method %FindComputedMemberByKey(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set pMemberName = "Query"

		// There may be a name tacked onto the start of pKey
		If ($L(pKey,":")>1) {
			Set tMemberName = $ZSTRIP($P(pKey,":",1),"<>W")
			
			If $ZSTRIP(tMemberName,"*W")?.AN {
				// DTB342 - Test to see if the found member is a valid key. If so,
				// strip it off and continue to process the real key.
				Set pMemberName = tMemberName
				Set pKey = $ZSTRIP($P(pKey,":",2,999),"<>W")
			}
		}
		
		Set tSC = ..%ComputeBitset(pKey,.pMemberId)
		If $$$ISERR(tSC) Quit
		Set pFlag = 1
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the set of all members (pre-defined and run-time) for this dimension.
/// Sort them according to the sort options in the cube meta data.<br/>
/// <var>pMemberList</var> returns a set of members defined in the cube model:<br/>
/// pMemberList(n) = $LB(id,caption,key,[format])<br/>
Method %GetAllMembers(ByRef pMemberList, pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1366
		// find sortDir
		Set tExists = ##class(%DeepSee.Query.member).%GetNodeInfo(pCube, pDimNo, pHierNo, pLevelNo, .tFact, .tDimClass, .tStarField, .tStarSort, .tRollup, .tSortDir,,.tHasMemberList,.tStarKeyField)
		If ('tExists) {
			// no level
			Quit
		}

		// get set of members for this level
		Kill pMemberList
		Kill tMemberList
		Set tCubeIndex = $$$DeepSeeIndex(pCube)

		Set tSC = ..%GetPredefinedMembers(.tMemberList,tCubeIndex,pDimNo,pHierNo,pLevelNo)
		If $$$ISERR(tSC) Quit

		// ignore rollup and range
		Set tSC = ..%GetComputedMembers(.tMemberList)
		If $$$ISERR(tSC) Quit

		// sort by name
		Set n = $O(tMemberList(""))
		While (n'="") {
			Set data = tMemberList(n)
			If (tSortDir="") {
				// unsorted 
				Set tName = "*"
			}
			ElseIf ((tSortDir="asc#")||(tSortDir="desc#")) {
				Set tName = +$LG(data,2)
			}
			Else {
				Set tName = $LG(data,2)
			}
			Set tMemberListSorted(tName,n) = data
			Set n = $O(tMemberList(n))
		}		

		Set tDir = $S(tSortDir="desc":-1,tSortDir="desc#":-1,1:1)
		Set k = $O(tMemberListSorted(""),tDir)
		While (k'="") {
			Set n = $O(tMemberListSorted(k,""),tDir)
			While (n'="") {
				Set data = $G(tMemberListSorted(k,n))
				Set tID = $LG(data,1)
				Set tName = $LG(data,2)
				Set tKEY = $LG(data,3)
				Set pMemberList($I(pMemberList)) = $LB(tID,tName,tKEY,$LG(data,4))
				Set n = $O(tMemberListSorted(k,n),tDir)
			}
			Set k = $O(tMemberListSorted(k),tDir)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the set of pre-defined members for this dimension.
/// These will be in the cube meta data.<br/>
/// <var>pMemberList</var> returns a set of members defined in the cube model:
/// pMemberList(n) = $LB(id,caption,key,[format])<br/>
ClassMethod %GetPredefinedMembers(ByRef pMemberList, pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1366
		Set tCube = $$$UPPER(pCube)
		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCube,.tSC)
		If $$$ISERR(tSC) Quit

		Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",""),1,data)
		While (p'="") {
			Set tItemName = $LG(data,1)
			Set tItemSpec = $LG(data,2)
			Set tItemCaption = ""
			Set tItemDescription = $LG(data,4)		// DTB219
			If (tCubeClass'="") {
				Set tItemCaption = $classmethod(tCubeClass,"%GetLevelMemberCaption",pDimNo,pHierNo,pLevelNo,tItemName)
			}
			Set:tItemCaption="" tItemCaption = tItemName
			If (tItemCaption'="") {
				If (..#BEHAVIOR="MDX") {
					// for MDX member.spec is the ID
					Set pMemberList($I(pMemberList)) = $LB(tItemSpec,tItemCaption,tItemName,tItemDescription)		// DTB219
				}
				Else {
					// skip ID
					Set pMemberList($I(pMemberList)) = $LB("",tItemCaption,tItemSpec,tItemDescription)		// DTB219
				}
			}
			Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",p),1,data)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the set of members for this computed dimension object.<br/>
/// <var>pMemberList</var> may contain a set of members defined in the cube model:
/// pMemberList(n) = $LB(id,name,key,[format])<br/>
/// If so, use this list, otherwise compute one.
/// <p><var>pRollupKey</var> and <var>pRange</var> can be used to filter the computed
/// members returned, if applicable for this computed dimension.</p>
Method %GetComputedMembers(ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// JMD1366 remove $I
		// Set x = $I(pMemberList)

		// dispatch to subclass
		Set tSC = ..%OnGetComputedMembersFiltered(.pMemberList, pRollupKey, .pRange)
		If $$$ISERR(tSC) Quit

		// let cube class add/remove items from the member list
		Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..%cube)
		If (tCubeClass'="") {
			// find dim name
			Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"mbr#",..%dimNumber,..%hierNumber,..%levelNumber))
			Set tSC = $classmethod(tCubeClass,"%OnGetComputedMembers",$LG(tDimInfo,2),$LG(tDimInfo,3),$LG(tDimInfo,4),.pMemberList, pRollupKey, .pRange)
		}

		Set n = $O(pMemberList(""),1,data)
		While (n'="") {
			// compute IDs
			Set tName = $LG(data,2)
			Set tKEY = $LG(data,3)

			Set tSC = ..%ResolveKey(tKEY,.tKEY)
			If $$$ISERR(tSC) Quit

			If (..#BEHAVIOR="MDX") {
				Set tID =$LG(data,1)
				Set pMemberList(n) = $LB(tID,tName,tKEY)
			}
			Else {
				// bitset
				// JMD1366: skip computing the bit set;
				// have the caller do this later if needed
				//Set tSC = ..%ComputeBitset(tKEY,.tID)
				//If $$$ISERR(tSC) Quit
				Set tID = ""
				Set pMemberList(n) = $LB(tID,tName,tKEY)
			}
			// format
			Set:$LD(data,4) $List(pMemberList(n),4) = $LG(data,4)

			Set pMemberList = n
			Set n = $O(pMemberList(n),1,data)
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the set of members for this computed dimension object.<br/>
/// pMemberList(n) = $LB(id,name,key)<br/>
/// This can be implemented by subclasses.
/// <p>This method is deprecated, implement <method>%OnGetComputedMembersFiltered</method>
/// instead.</p>
Method %OnGetComputedMembers(ByRef pMemberList) As %Status [ Deprecated ]
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the set of members for this computed dimension object satisfying
/// <var>pRollupKey</var> and <var>pRange</var> (if applicable for this implementation).<br/>
/// pMemberList(n) = $LB(id,name,key)<br/>
/// This can be implemented by subclasses.
Method %OnGetComputedMembersFiltered(ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// defaults to ..%OnGetComputedMembers() for backwards compatilbity.
		set tSC = ..%OnGetComputedMembers(.pMemberList)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute a hash key for a given member member.
Method %ComputeIndexKey(pMemberKey As %String) As %String
{
	Quit $ZCRC(pMemberKey,7)
}

/// Build the bitset that corresponds to the given computed dimension "spec".
Method %ComputeBitset(pSpec As %String, Output pIndexKey As %String) As %Status [ CodeMode = objectgenerator, Final, ForceGenerate ]
{
	do %code.WriteLine("	Set tSC = $$$OK")
	do %code.WriteLine("	Try {")
	do %code.WriteLine("		Set pIndexKey = ..%ComputeIndexKey(pSpec)")
	do %code.WriteLine()
	
	// BDB371 - treat cache policy
	if %parameter("CACHECOMPUTEDBITSET")="CHECK" {
		do %code.WriteLine("		// check if data is up-to-date")
		do %code.WriteLine("		set tLastDataUpdate = $g($$$DeepSeeUpdateQueue(""cubes"",..%baseCube,""lastDataUpdate""))")		// DTB422 - Store data updates in the updates global
		do %code.WriteLine("		set tLastIndexUpdate = $g($$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey))")
		do %code.WriteLine("		if (+tLastIndexUpdate>+tLastDataUpdate)||((+tLastIndexUpdate=+tLastDataUpdate)&&($p(tLastIndexUpdate,"","",2)>$p(tLastDataUpdate,"","",2))) QUIT")
		do %code.WriteLine()
	}
	
	do %code.WriteLine("		// delete old data")
	do %code.WriteLine("		Kill $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey)")
	do %code.WriteLine()
	do %code.WriteLine("		Set tSC = ..%OnComputeBitset(pSpec,pIndexKey)")
	do %code.WriteLine("		If $$$ISERR(tSC) Quit")
	do %code.WriteLine()
	
	if %parameter("CACHECOMPUTEDBITSET")="CHECK" {
		do %code.WriteLine("		// update Index timestamp")
		do %code.WriteLine("		set $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey) = $ZTIMESTAMP")
		do %code.WriteLine()
	}
	
	do %code.WriteLine("	}")
	do %code.WriteLine("	Catch(ex) {")
	do %code.WriteLine("		Set tSC = ex.AsStatus()")
	do %code.WriteLine("	}")
	do %code.WriteLine("	Quit tSC")
}

/// Do the actual work of building the bitset.
/// Implemented in subclasses.
Method %OnComputeBitset(pSpec As %String, pIndexKey As %String) As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method.
/// Prepare and execute the given SQL statement and build an index from it.<br/>
/// If optional <var>pRS</var> is supplied, use it to fetch ID values (result set must have an ID column).<br/>
/// If <var>pTranslateIds</var> is true, then translate source id value to fact ids.<br/>
Method %CreateIndexFromSQL(pSQL As %String, pIndexKey As %String, pRS As %SQL.StatementResult = "", pTranslateIds As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		$$$dsSetLogging		// DTB981
		
		Set pSQL = $$$UPPER(pSQL)		// DTB643
		
		// N.B. [DTB295] - This must use the $E() approach since the %SEARCH SQL may allow a string literal with a single, unescaped ] wrapped in a key, eg:
		//   pSQL = "&[SELECT ID FROM HoleFoods_Cube.Fact WHERE MxComment LIKE 'Shopper%]']"
		// In this case the MDX parser would interpret the first ] as the closing of the key and strip off the rest, creating an SQL error.
		// The more permanent fix to render this test obsolete would be done in the %ResolveKey() parser--the completed SQL statement doesn't need to be
		// wrapped in &[] at all.
		if ($e(pSQL,1,2)="&[") { // JSL4431, JSL4447
			Set pSQL=$e(pSQL,3,*)
			Set:$e(pSQL,*)="]" pSQL=$e(pSQL,1,*-1)
		}
		// JMD1366: test for result set
		If $IsObject(pRS) {
			Set tRS = pRS
		}
		Else {
			Set tIsCall = ($$$UPPER($E(pSQL,1,4))="CALL")
			Set tUseChunk = $$$DeepSeeOptimizer($$$searchMsrSqlChunk,1,1)&&'tIsCall
			
			If tUseChunk {
				// DTB643 - Use bitchunk query to directly return queries 
				// DTB717 - Take all remaining pieces after the first FROM
				// DTB972 - Use " FROM " as the $piece delimiter to prevent most errors from literals
				Set pSQL = "SELECT %CHUNK(ID), %BITMAPCHUNK(ID) FROM " _ $P(pSQL," FROM ",2,*) _ " GROUP BY %CHUNK(ID)"
			}
			
			Set ^DeepSee.ComputedSQL = pSQL

			// create query
			Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
			Set tSC = tStatement.%Prepare(pSQL)
			If $$$ISERR(tSC) {
				Set tMsg = $System.Status.GetOneStatusText(tSC)
				Set tSC = $$$ERROR($$$GeneralError,"Invalid SQL used in key expression. Query:" _ pSQL _ " Message:" _ tMsg)
				Quit
			}
			Set tRS = tStatement.%Execute()
		}

		// build bits and file into index
		Set tCurrChunk = 1
		Set tBits = ""
		
		// Determine whether the object returned from %Execute is a resultset (from an SQL statement)
		// or an SQL ProcedureContext (from a CALL statement).
		// If from a CALL statement, need to call %NextResult to get the actual resultset
		If (tRS.%IsA("%ProcedureContext")) {
			Set tRS = tRS.%NextResult()
		}

		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			
			If tUseChunk {
				// DTB643 - Query returned index directly
				Set $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tRS.%GetData(1)) = tRS.%GetData(2)
			}
			Else {
				Set tID = tRS.ID
				If (pTranslateIds) {
					Set x = tID
					// JMD1366 translate sourceId to factId
					Set:tID'="" tID = $O($$$DeepSeeIndexGLVN(..%baseCube,"%sourceId",tID,""))
				}
				If (tID'="") {
					Set tChunk = tID\64000+1
					If (tChunk '= tCurrChunk) {
						Set:tBits'="" $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tCurrChunk) = tBits
						Set tCurrChunk = tChunk
						// pick up bits that may be there as we may not be going in ID order
						Set tBits = $G($$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tCurrChunk))
					}
					Set tOffset = tID#64000+1
					$$$dsBitSet(tBits,tOffset,1)		// DTB981
				}
			}
		}
		Set:tBits'="" $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tCurrChunk) = tBits
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Utility method.
/// Build an index directly from a comparison on a searchable measure. The comparison is supplied by the arguments<br>
/// <var>pSearchMeasureIndex</var> - The name of the searchable index on the searchable measure<br>
/// <var>pComparison</var> - The comparison operator; legal values are SQL numeric comparisons: <,<=,=,=>,>,<><br>
/// <var>pValue</var> - The target value of the comparison. This must be numeric<br>
/// <var>pIndexKey</var> - The key of the new index being constructed out of the searchable measure
Method %CreateIndexFromSearchableMeasure(pSearchMeasureIndex As %String = "", pComparison As %String, pValue As %Numeric, pIndexKey As %String = "") As %Status
{
	// Method added by DTB295
	Set tSC = $$$OK
	Set tCubeKey = $$$UPPER(..%baseCube)	// Always use the base cube since subject areas have no entries in ^DeepSee.Index
	Set tSearchIndex = pSearchMeasureIndex
	
	Try {
		$$$dsSetLogging		// DTB981
		
		// Search for the indexed terms which satisfy the search condition
		// Run each direction separately. The operation is always to OR the results.
		If (pComparison["=") {
		 	// Used by <=,>=,=
		 	If $D($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,pValue)) {
			 	// Loop on all chunks for the equals case
			 	Set tChunk=$order($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,pValue,""))
	            While tChunk'="" {
	                $$$dsBitAorBIntoA($$$DeepSeeIndexGLVN(tCubeKey,..%factNumber,pIndexKey,tChunk),$$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,pValue,tChunk))		// DTB981
	                Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,pValue,tChunk))
	            }
		 	}
		}
		If (pComparison["<") {
			// Used by <=,<,<>
			Set tIndexValue=$O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,""))		// OR index nodes from the smallest value forward, ignore nulls (-1E14)
			While (tIndexValue'="")&&((tIndexValue<pValue)||(tIndexValue=-1E14)) {
				// Loop on all chunks for the less-than case, skip nulls
				If (tIndexValue'=-1E14) {
				 	Set tChunk=$order($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,""))
		            While tChunk'="" {
		                $$$dsBitAorBIntoA($$$DeepSeeIndexGLVN(tCubeKey,..%factNumber,pIndexKey,tChunk),$$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,tChunk))		// DTB981
		                Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,tChunk))
		            }
				}
				Set tIndexValue=$O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue))
			}
		}
		If (pComparison[">") {
			// Used by >=,>,<>
			Set tIndexValue=$O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,""),-1)	// OR index nodes from the largest value backward, ignore nulls (-1E14)
			While (tIndexValue'="")&&((tIndexValue>pValue)||(tIndexValue=-1E14)) {
				// Loop on all chunks for the greater-than case, skip nulls
				If (tIndexValue'=-1E14) {
				 	Set tChunk=$order($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,""))
		            While tChunk'="" {
		                $$$dsBitAorBIntoA($$$DeepSeeIndexGLVN(tCubeKey,..%factNumber,pIndexKey,tChunk),$$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,tChunk))		// DTB981
		                Set tChunk = $O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue,tChunk))
		            }
				}
				Set tIndexValue=$O($$$DeepSeeIndexGLVN(tCubeKey,tSearchIndex,tIndexValue),-1)
			}
		}    
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Return the (SQL) name of the fact table for the current cube.
Method %GetFactTable() As %String
{
	Quit ##class(%DeepSee.Utils).%GetCubeFactTable(..%cube)
}

/// Return the (SQL) name of the source table for the current cube.
Method %GetSourceTable() As %String
{
	// Method added by DTB717
	Quit ##class(%DeepSee.Utils).%GetSQLTableName(##class(%DeepSee.Utils).%GetSourceClass(..%cube))
}

/// Execute a search for members.<br/>
/// Return a list of the form:<br/>
/// pList(n) = $LB(value,key)
Method %MemberSearch(pSearchKey As %String, Output pList As %List) As %Status
{
	Quit ..%MemberSearchByIndex(pSearchKey,.pList)
}

/// Resolve any special tokens or expression in a key value and return the result.
Method %ResolveKey(pSpec As %String, Output pRKey As %String) As %Status
{
	Set tSC = $$$OK
	Set pRKey = pSpec
	Quit tSC
}

/// Apply substitutions to an SQL query string used within a computed dimension expression.<br/>
/// <var>pSubstList</var> is an array of $$$ substitution values, e.g.:<br/>
/// pSubstList("TABLE") = table name<br/>
/// pSubstList("FACT") = fact name<br/>
/// {} can be used to enclose an ObjectScript expression that is evaluated and whose
/// results become part of the SQL text of the query.<br/>
/// [dim].[mbr] can be used to refer to a specific cube element (such as a measure). This is replaced
/// with the fact name that corresponds to the element.<br/>
Method %ProcessSQL(pSQL As %String, ByRef pSubstList, Output pFirstToken As %String, Output pErrorMsg As %String) As %String
{
	Set tOut = ""
	Set tState = 0
	Set tToken = ""
	Set pFirstToken = ""
	Set pErrorMsg = ""
	Set tHaveFirst = 0

	Set tQuote = "'"
	Set tStartBrace = "{"
	Set tEndBrace = "}"
	Set tQuote="'" // JSL4447
	if (pSQL["&[") { // JSL4431, JSL4447
		Set:$e(pSQL,1,2)="&[" pSQL=$e(pSQL,3,*)
		Set:$e(pSQL,*)="]" pSQL=$e(pSQL,1,*-1)
	}
	
	Set p = 1
	While (p <= ($L(pSQL)+1)) {
		Set ch = $E(pSQL,p)
		Set p = p + 1
		If (tState = 0) {
			If (ch = "$") {
				Set tState = 1
				If ('tHaveFirst) {
					Set tHaveFirst = 1
					Set pFirstToken = tToken
				}
				Set tToken = ""
			}
			ElseIf (ch = tStartBrace) {
				Set tState = 5
				If ('tHaveFirst) {
					Set tHaveFirst = 1
					Set pFirstToken = tToken
				}
				Set tToken = ""
			}
			ElseIf (ch = "[") {
				// start of member name
				Set tState = 6
				If ('tHaveFirst) {
					Set tHaveFirst = 1
					Set pFirstToken = tToken
				}
				Set tToken = "["
			}
			ElseIf (ch = tQuote) { // JSL4447
				;Set tToken = tToken _ ch
				Set tOut = tOut _ ch
				Set tState = "0b"
			}
			ElseIf (" +/*-)'" [ ch) {
				Set tOut = tOut _ ch
				If ('tHaveFirst) {
					Set tHaveFirst = 1
					Set pFirstToken = tToken
				}
			}
			Else {
				Set tOut = tOut _ ch
				Set tToken = tToken _ ch
			}
		}
		Elseif (tState = "0b") { // JSL4447
			If (ch = tQuote) {
				;Set tToken = tToken _ ch
				Set tPeek = $E(pSQL, p)
				If (tPeek = tQuote) {
					Set p = p + 1
					;Set tToken = tToken _ tPeek
					Set tOut = tOut _ tPeek
				}
				Else {
					Set tState = 0
					Set tOut = tOut _ ch
					;Set tToken = tToken _ ch
				}
			}
			Else {
				Set tOut = tOut _ ch
				;Set tToken = tToken _ ch
			}

		}
		
		ElseIf (tState = 1) {
			// $
			If (ch = "$") {
				Set tState = 2
			}
			Else {
				Set tState = 0
				Set tOut = tOut _ "$" _ ch
			}
		}
		ElseIf (tState = 2) {
			// $$
			If (ch = "$") {
				Set tState = 3
			}
			Else {
				Set tState = 0
				Set tOut = tOut _ "$$" _ ch
			}
		}
		ElseIf (tState = 3) {
			// $$$
			If (" +/*-)'" [ ch) {
				If ((tToken'="")&&$D(pSubstList($$$UPPER(tToken)))) {
					Set tOut = tOut _ pSubstList($$$UPPER(tToken))
				}
				Else {
					Set tOut = tOut _ "$$$" _ tToken
				}
				Set tToken  = ""
				Set p = p - 1 // process ch
				Set tState = 0
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 4) {
			// quoted string
			If (ch = tQuote) {
				Set tOut = tOut _ ch
				Set tState = 0
			}
			Else {
				Set tOut = tOut _ ch
			}
		}
		ElseIf (tState = 5) {
			// expression in brackets
			// this can be {[dim].[mbr]}
			// or
			// {cos-expression}
			// 
			If (ch = tEndBrace) {
				If ($E(tToken,1,1)="[") {
					// convert dimension reference to fact
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..%cube,tToken,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
					If $$$ISERR(tSC) {
						Set pErrorMsg = $$$FormatText($$$Text("Dimension not found: %1","%DeepSee"),tToken)
						Quit
					}
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..%cube,tDimNo,tHierNo,tLevelNo,.tFactName)
					If $$$ISERR(tSC) {
						Set pErrorMsg = $System.Status.GetOneErrorText(tSC)
						Quit
					}
					If (tDimNo=0) {
						// for measures, find the type of measure
						Set tMsrInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"mbr#",tDimNo,tHierNo,0)
						Set tMsrType = $LG(tMsrInfo,8)
						If (tMsrType="age") {
							// correct search term for date
							Set tAgeToday = +$H-$$$dsReferenceTime
							Set tFactName = "("_tAgeToday_"-"_tFactName_")"
						}
					}
					Set tOut = tOut _ tFactName
				}
				Else {
					// eval expression
					Set tOut = tOut _ ..%Eval(tToken,.pErrorMsg)
					If (pErrorMsg'="") {
						Quit
					}
				}
				Set tToken = ""
				Set tState = 0
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 6) { // [
			// look for closing ]
			If (ch = "]") {
				Set tToken = tToken _ ch
				Set tState = 7
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 7) { // [...]
			// look for closing ]
			If (ch = ".") {
				Set tToken = tToken _ ch
			}
			ElseIf (ch = "[") {
				Set tState = 6
				Set tToken = tToken _ ch
			}
			Else {
				// convert dimension reference to fact
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..%cube,tToken,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
				If $$$ISERR(tSC) {
					Set pErrorMsg = $$$FormatText($$$Text("Dimension not found: %1","%DeepSee"),tToken)
					Quit
				}
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..%cube,tDimNo,tHierNo,tLevelNo,.tFactName)
				If $$$ISERR(tSC) {
					Set pErrorMsg = $System.Status.GetOneErrorText(tSC)
					Quit
				}

				If (tDimNo=0) {
					// for measures, find the type of measure
					Set tMsrInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(..%cube),"mbr#",tDimNo,tHierNo,0)
					Set tMsrType = $LG(tMsrInfo,8)
					If (tMsrType="age") {
						// correct search term for date
						Set tAgeToday = +$H-$$$dsReferenceTime
						Set tFactName = "("_tAgeToday_"-"_tFactName_")"
					}
				}

				Set tOut = tOut _ tFactName
				Set tToken = ""
				Set tState = 0
				Set p = p - 1
			}
		}
	}
	Quit tOut
}

/// Evaluate the given ObjectScript expression.
ClassMethod %Eval(pExpr As %String, Output pErrorMsg As %String) As %String
{
	New %val
	Set %val = ""
	Set pErrorMsg = ""

	Try {
		Set tExpr = "Set %val = "_pExpr
		X tExpr
	}
	Catch(ex) {
		Set tErr = $P($ZE,">",1) _ ">"
		Set tVar = $P($ZE,"*",2)
		Set pErrorMsg = tErr
		Set %val = tErr
		Set:tVar'="" %val = %val_" *"_tVar_" "
		Set %val = %val _ " (" _ pExpr _ ")"
	}
	Quit %val
}

/// Returns the %DeepSee.Query.query object for the current query context, if any
Method %GetCurrentQuery() As %DeepSee.Query.query [ Private ]
{
	quit $g(%query)
}

/// Notifies the computed dimension all facts of a cube referencing are being killed. This method
/// should erase any temporary or cached data the computed dimension implementation has written
/// as part of its "lifetime" for the given cube and dimension coordinates.
/// Indices cached as part of the <parameter>CACHECOMPUTEDBITSET</parameter> setting are taken
/// care of by the default implementation of this method.
ClassMethod %OnKillFacts(pCubeName As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Status [ CodeMode = objectgenerator, ForceGenerate ]
{
	if %parameter("CACHECOMPUTEDBITSET")="CHECK" {
		do %code.WriteLine("	kill $$$DeepSeeIndexGLVN($$$UPPER(pCubeName), pFactNo)")
	}
	do %code.WriteLine("	quit $$$OK")
}

/// Return the member specification for the given member.<br/>
/// Implement this so that %GetFiltersForCellRange will work!
ClassMethod %GetMemberSpec(pMemberId As %String, pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %String [ Internal ]
{
	// JMD1361
	Set tSpec = ""
	Quit tSpec
}

/// Helper method; execute a member search using the set of defined (and run-time) members.
Method %MemberSearchByMembers(pSearchKey As %String, Output pList As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $$$UPPER(..%cube)
		Set pSearchKey = $$$UPPER(pSearchKey)

		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",..%dimNumber,..%hierNumber,..%levelNumber))
		Set tSortDir = $LG(tInfo,10)

		// tMemberList = $LB(id,caption,key,[format])
		Set tSC = ..%GetPredefinedMembers(.tMemberList,tCubeName,..%dimNumber,..%hierNumber,..%levelNumber)
		If $$$ISERR(tSC) Quit

		Set tSC = ..%GetComputedMembers(.tMemberList)
		If $$$ISERR(tSC) Quit

		// sort by name; filter by search key
		Set n = $O(tMemberList(""))
		While (n'="") {
			Set data = tMemberList(n)
			Set tName = $LG(data,2)
			If ((pSearchKey="")||($$$UPPER(tName)[pSearchKey)) {
				If (tSortDir="") {
					// unsorted 
					Set tName = "*"
				}
				ElseIf ((tSortDir="asc#")||(tSortDir="desc#")) {
					Set tName = +tName
				}

				Set tMemberListSorted(tName,n) = data
			}
			Set n = $O(tMemberList(n))
		}

		// copy results
		Set tDir = $S(tSortDir="desc":-1,tSortDir="desc#":-1,1:1)
		Set n = 0
		Set i = $O(tMemberListSorted(""),tDir)
		While (i'="") {
			Set j = $O(tMemberListSorted(i,""),tDir)
			While (j'="") {
				Set data = $G(tMemberListSorted(i,j))
				Set tCaption = $LG(data,2)
				Set tKey = $LG(data,3)
				Set pList($I(tCount)) = $LB(tCaption,tKey)
				Set j = $O(tMemberListSorted(i,j),tDir)
			}
			Set i = $O(tMemberListSorted(i),tDir)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Helper method; execute a member search using the contents of the fact index.
Method %MemberSearchByIndex(pSearchKey As %String, Output pList As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		// e.g.
		// Set pList($I(n)) = $LB("XML","&[WHERE MxText %CONTAINSTERM('XML')]")

		// figure out the actual fact# so that we can loop over the index
		Set tCube = $$$UPPER(..%cube)
		Set tIndexName = ""

		Set f = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",""))
		While (f'="") {
			Set tType = $G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",f,"type"))
			Set tAlias = $G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",f,"alias"))
			If (((..%factName=f)||(..%factName=tAlias))&&(tType="%Text")) {
				Set tIndexName = $G($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",f))
				Quit
			}
			Set f = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",f))
		}

		If (tIndexName="") Quit

		Set tCount = 0
		Set tSearch = " "_$$$UPPER(pSearchKey)
		Set tMaxItems = 100
		Set tText = $O($$$DeepSeeIndexGLVN(..%baseCube,tIndexName,tSearch),-1)
		Set tText = $O($$$DeepSeeIndexGLVN(..%baseCube,tIndexName,tText))
		While ((tText'="")&&(tCount < tMaxItems)) {
			If ($E(tText,1,$L(tSearch))'=tSearch) {
				Quit
			}
			// default behavior: perform a text search
			// JMD901: prepend term so that it is used as Key caption
			Set tTerm = $ZSTRIP(tText,"<>W")
			Set pList($I(tCount)) = $LB(tTerm,"&["_tTerm_":WHERE $$$FACT %CONTAINSTERM('"_tTerm_"')]")
			Set tText = $O($$$DeepSeeIndexGLVN(..%baseCube,tIndexName,tText))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
