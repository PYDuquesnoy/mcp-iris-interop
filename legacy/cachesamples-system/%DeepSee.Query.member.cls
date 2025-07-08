/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class (or its subclass) is used by the DeepSee Query Engine
/// to process members within a DeepSee query.<br/>
/// A <class>member</class> object is not a node within an MDX query graph.<br/>
/// Certain nodes (namely the <class>memberSpec</class> node) will create
/// an instance of <class>member</class> object (based on the type of member) and delegate to it certain member-related
/// tasks. This is how the difference between time and data dimensions is implemented.<br/>
/// This is an abstract class, the actual work is done
/// by subclasses.
Class %DeepSee.Query.member Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// Name of the cube this member belongs to.
Property %cube As %DeepSee.Datatype.string;

/// The tuple object that owns this member.
Property %tuple As %DeepSee.Query.tuple;

/// Array of known value/id/key triplets for each level.
Property %memberSpec As %List [ MultiDimensional ];

/// Dimension # referred to by the tuple.
Property %dimNumber As %Integer;

/// Hierarchy # referred to by the tuple.
Property %hierNumber As %Integer;

/// Level # referred to by the tuple.
Property %levelNumber As %Integer;

/// Name for the all level for this member.
Property %allName As %DeepSee.Datatype.string;

/// Member name or value referred to by the tuple.
Property %name As %DeepSee.Datatype.string;

/// Member id value (optional).
Property %memberId As %DeepSee.Datatype.string;

/// Member key value (optional).
Property %memberKey As %DeepSee.Datatype.string;

/// Member type.<br/>
/// This indicates the context specified by the tuple expression.<br/>
/// The value can be one of the dst macros ($$$dstSet etc.).<br/>
/// This is used to determine which function can be applied to this tuple.
Property %type As %DeepSee.Datatype.string;

/// Aggregate to apply to this measure (if applicable).
Property %aggregate As %DeepSee.Datatype.string;

/// Create an instance of <class>%DeepSee.Query.member</member>.
ClassMethod %CreateMember(pClassName As %String, Output tSC As %Status, pCube As %String, pTuple As %DeepSee.Query.tuple, pDimNo As %Integer, pHierNo As %Integer, pAllName As %String = "") As %DeepSee.Query.member [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tMember = $zobjclassmethod(pClassName,"%New")
		Set tMember.%cube = pCube
		Set tMember.%tuple = pTuple
		Set tMember.%dimNumber = pDimNo
		Set tMember.%hierNumber = pHierNo
		Set tMember.%allName = pAllName
	}
	Catch(ex) {
		Set tMember = ""
		Set tSC = ex.AsStatus()
	}
	Quit tMember
}

/// Set the current level number context for this member.
Method %SetLevelNo(pLevelNo As %Integer) [ Final, Internal ]
{
	Set ..%levelNumber = pLevelNo
}

/// Return the type of this member.
Method %GetType() As %String [ Final, Internal ]
{
	Quit ..%type
}

/// Set the state of this member using the current meta data node.
Method %ApplyState(pType As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%type = pType

		// see if we have found a level
		Set tLastLevel = $O(..%memberSpec(""),-1)
		If (tLastLevel '= "") {
			Set ..%name = $LG(..%memberSpec(tLastLevel),1)
			Set ..%memberId = $LG(..%memberSpec(tLastLevel),2)
			Set ..%memberKey = $LG(..%memberSpec(tLastLevel),3)
			Set ..%levelNumber = tLastLevel
		}
	
		Set:..%levelNumber="" ..%levelNumber = 1
		If ((..%allName'="")&&(..%levelNumber=1)) {
			// this is the all level
			Set ..%name = ..%allName
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Helper method: Get information about the given level from the
/// cube meta data.<br/>
/// As a side effect, set the dependency variable, %dsDepends.
ClassMethod %GetNodeInfo(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, Output pFact As %String, Output pStarClass As %String, Output pStarField As %String, Output pStarSort As %String, Output pRollup As %String, Output pSortDir As %String, Output pFormat As %String, Output pMemberList As %String, Output pStarKeyField As %String) As %Boolean [ Final, Internal ]
{
	// pStarField is the NAME
	// pStarKeyField is the KEY

	Set tExists = 0
	Set tCubeName = $$$UPPER(pCubeName)
	Set (pFact,pStarClass,pStarField,pStarSort,pRollup,pStarKeyField) = ""
	If ((pDimNo'="")&&(pHierNo'="")&&(pLevelNo'="")) {
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",pDimNo,pHierNo,pLevelNo))
		If (tInfo '= "") {
			Set tExists = 1
			Set pFact = $LG(tInfo,5)
			Set pStarClass = $LG(tInfo,6)
			Set pStarField = $LG(tInfo,7) // agg for measure
			Set pStarSort = $LG(tInfo,8)  // type for measure
			Set pRollup = $LG(tInfo,9)    // scale for measure
			Set pSortDir = $LG(tInfo,10)

			Set pMemberList = $LG(tInfo,11)
			Set pFormat = $LG(tInfo,12)
			Set pStarKeyField = $LG(tInfo,12) // node is different for measures and levels

			If ((pFact'="")&&($E(pFact)'="M")) {
				// note dependency along with current timestamp
				Set:$D(%dsDepends) %dsDepends(pFact) = $G($$$DeepSeeResultsGLVN(tCubeName,"fact",pFact))
			}
			If ($D(%dsMeasures)&&($E(pFact)="M")) {
				Set tFormat = $LG(tInfo,12)
				If (tFormat'="") {
					// Note format of this measure (we are in the slicer)
					Set %dsMeasures("format") = tFormat
				}
			}
		}
	}
	Quit tExists
}

/// Helper method: Get the ALL level name for dimension, if present.
/// Also return the localized caption via <var>pCaption</var>.
ClassMethod %GetAllName(pCubeName As %String, pDimNo As %Integer, Output pCaption As %String) As %String [ Final, Internal ]
{
	Set tAllName = ""
	Set tCubeName = $$$UPPER(pCubeName)
	Set pCaption = ""
	If (pDimNo'="") {
		Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",pDimNo,0,0))
		If (tInfo '= "") {
			Set tAllName = $LG(tInfo,4)
		}
		If (tAllName '= "") {
			Set tClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCubeName,.tSC)
			If $$$ISERR(tSC) Quit ""
			Set tDim = $$$UPPER($LG(tInfo,2))
			Set pCaption = $zobjclassmethod(tClassName,"%GetMemberCaption",tDim,$$$UPPER(tAllName))
		}
	}
	Quit tAllName
}

/// Helper method: Get the Null Replacement value for the given level.
/// Also return the localized caption via <var>pCaption</var>.
ClassMethod %GetNullName(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, Output pCaption As %String) As %String [ Final, Internal ]
{
	Set tNullName = ""
	Set tCubeName = $$$UPPER(pCubeName)
	Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",pDimNo,pHierNo,pLevelNo))
	If (tInfo'="") {
		Set tNullName = $LG(tInfo,13)
	}
	Set:tNullName="" tNullName = $$$DeepSeeNullMarker
	Set pCaption = ""
	Quit tNullName
}

/// Helper method: Get the time offset and format values for the given level.
ClassMethod %GetTimeOffset(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, Output pFormat As %String) As %String [ Final, Internal ]
{
	Set tTimeOffset = ""
	Set pFormat = ""
	Set tCubeName = $$$UPPER(pCubeName)
	Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",pDimNo,pHierNo,pLevelNo))
	If (tInfo'="") {
		Set pFormat = $LG(tInfo,14)
		// DTB376 - If no format has been set for this time level in the cube
		// definition use the NLS default format as the default
		If (pFormat="")&&##class(%SYS.NLS.Format).UseLocale() { 
			Set tTimeClass = $LG(tInfo,6)
			Set tLocaleFormat=##class(%SYS.NLS.Format).GetFormatItem("DATEFORMAT") 

			// Only supply the default locale format for certain time classes
			If ($ClassMethod(tTimeClass,"%GetName")="DayMonthYear") { 
				Set pFormat = $Case(tLocaleFormat,1:"mm/dd/y",2:"dd mmm y",3:"y-mm-dd",4:"dd/mm/y",:"")
			}
		}
		
		Set tTimeOffset = $LG(tInfo,15)		// DTB409
	}
	Quit tTimeOffset
}

/// Process the member id, name, and key information for this member.
/// Put the result into <var>pSet</var>.
Method %ProcessMembers(pParent As %Integer, Output pSet As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tExists = ..%GetNodeInfo(..%cube,..%dimNumber, ..%hierNumber, ..%levelNumber, .tFact)
		If (tExists) {
			Set tName = ..%name
			If (tName = ..%allName) {
				// get caption for all name
				Set x = ..%GetAllName(..%cube,..%dimNumber,.tAllCaption)
				Set:tAllCaption'="" tName = tAllCaption
			}
			Set pSet(1) = $LB("mbr",1,1,+pParent,tName,..%memberId,tFact,..%aggregate,..%dimNumber,..%hierNumber,..%levelNumber,,..%memberKey)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// See if there is a member with the given name within the specified
/// dimension,hierarchy, and/or level.<br/>
/// If <var>pLevel</var> is supplied, only look in that level.<br/>
/// Set <var>pFlag</var> true if a member is found.<br/>
/// On return, fills in memberSpec<br/>
/// 	memberSpec(level) = $LB(name,key)<br/>
/// 	<br/>
/// memberSpec(0) = $LB("All Time")<br/>
/// 	memberSpec(1) = $LB(2006,2006)<br/>
/// memberSpec(2) = $LB("Quarter 1", "Q1 2006")<br/>
/// memberSpec(3) = $LB("January","Jan 2006")<br/>
/// 
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%FindMemberByName")
}

/// Find the member with the given key within the given hierarchy.
/// If <var>pRecurse</var> is true, look at the current level and continue through higher levels until a match is found.
Method %FindMemberByKey(pKey As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, Output pMemberValue As %String, pRecurse As %Boolean = 1) As %Status [ Internal ]
{
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%FindMemberByKey")
}

/// Get members and place them into the axis tree.<br/>
/// <var>pRecurse</var>, if 1, indicates that this function is to be called
/// recursively to build a tree of members. If -1, include the All level (if present)
/// and the top level (used by %TOPMEMBERS).</br>
/// <var>pRange</var>, if defined, is an array contains a starting and ending
/// key value.<br/>
/// <var>pMemberList</var>, if defined, is an INLIST used for certain optimized member operations.
ClassMethod %GetMembers(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, pKey As %String, ByRef pNodeNo As %Integer, pRecurse As %Integer = 0, ByRef pRange As %String, ByRef pMemberList) As %Status
{
	// n.b. This is a class method so that it can be
	// called by utilities outside the context of a query.
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%GetMembers")
}

/// Get one member and place it into <var>pSet</var>.<br/>
/// <var>pKey</var>, is the key for the base member to return.</br>
/// <var>pRelation</var> indicates how this member is related to the base member.
/// "same","lead", "lag", etc.<br/>
/// <var>pOffset</var>, is an optional offset to apply to the relation.
ClassMethod %GetRelatedMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pRollupKey As %String, pParent As %Integer, Output pSet As %List, pKey As %String, pRelation As %String, pOffset As %Integer = 0, pValue As %String = "", pAllowMissing As %Integer = 0) As %Status [ Internal ]
{
	// n.b. This is a class method so that it can be
	// called by utilities outside the context of a query.
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%GetRelatedMember")
}

/// Get the parent of the current member and place it into <var>pSet</var>.<br/>
ClassMethod %GetParentMember(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String) As %Status [ Internal ]
{
	// n.b. This is a class method so that it can be
	// called by utilities outside the context of a query.
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%GetParentMember")
}

/// Get the nth child of the current member and place it into <var>pSet</var>.<br/>
/// If <var>pNumber</var> is 1 return the first child; 2 for the second, etc.<br/>
/// If <var>pNumber</var> is -1 return the last child; -2 for the second from end, etc.<br/>
ClassMethod %GetNthChild(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pParent As %Integer, Output pSet As %List, pKey As %String, pNumber As %Integer) As %Status [ Internal ]
{
	Quit $$$ERROR($$$GeneralError,"Unimplemented: "_..%ClassName()_".%GetNthChild")
}

/// Lookup the value of the given dimension property.
ClassMethod %GetPropertyValue(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pProperty As %String, pParent As %Integer, Output pSet As %List, pKey As %String) As %Status [ Internal ]
{
	// Default: return ""
	Set tValue = "@NOPROPERTY"
	Set pSet($I(pSet)) = $LB("lit",1,1,pParent,pProperty,tValue)
	Quit $$$OK
}

/// Find the rollup key for the specified level.
Method %GetRollupKey(pLevelNo As %Integer, pKey As %String, Output pRollupKey As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..%GetParentMember(..%cube,..%dimNumber, ..%hierNumber, pLevelNo, -1,.tSet,pKey)
		If $$$ISERR(tSC) Quit
	
		Set pRollupKey = $LG($G(tSet(1)),6)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the ordinal position of this member within its parent group.
/// For convenience, also return the parent key for this member.
Method %GetMemberOffset(Output pOffset As %Integer, pKey As %String, Output pParentKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pOffset = ""
		Set tSC = ..%GetParentMember(..%cube,..%dimNumber,..%hierNumber,..%levelNumber, -1,.tSet,pKey)
		If $$$ISERR(tSC) Quit

		// get parent key
		Set pParentKey = $LG($G(tSet(1)),6)

		// get members of parent
		// !!! could we pass along the offset and limit the search ?
		Kill tSet
		Set tSC = ..%GetMembers(..%cube,..%dimNumber,..%hierNumber,..%levelNumber,pParentKey,1,.tSet)
		If $$$ISERR(tSC) Quit

		// now find *this* member in the set
		Set n = 0
		Set k = $O(tSet(""))
		While (k '= "") {
			If (pKey = $LG($G(tSet(k)),6)) {
				Set pOffset = n
				Quit
			}
			Set n = n + 1
			Set k = $O(tSet(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if this member supports the given feature.
/// For example, "NOW".
ClassMethod %HasFeature(pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pFeature As %String) As %Boolean
{
	Quit 0
}

/// Test if this member supports the given function.
Method %SupportsFunction(pFunction As %String, Output pMessage As %String) As %Boolean
{
	Set pMessage = ""
	Quit 1
}

}
