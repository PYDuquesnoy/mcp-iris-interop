/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This is the base class for the family of DeepSee time hierarchy level classes.<br/>
/// A time hierarchy class defines the behavior for a level within a hierarchy within 
/// a DeepSee dimension.<br/>
/// The class (non-package) part of a level class *must* be unique.
/// You will get an error when you attempt to compile a cube definition is this is not the case.
Class %DeepSee.Time.AbstractLevel Extends %RegisteredObject [ Abstract, System = 3 ]
{

/// This is a comma-delimited list of user-settable options for this
/// time function.<br/>
/// Options can be defined within a DeepSee cube definition.
Parameter OPTIONLIST As STRING;

/// Type reported back to the UI. This determines what type of control to display
/// for filters based on this class.
Parameter DIMTYPE As STRING;

Parameter CALENDAR As STRING = "gregorian";

Parameter DOMAIN As STRING = "%DeepSee";

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 0
}

/// Return true if this time level is <b>independent</b> of the actual date.
/// For example a Month Number is independent of the actual month while a YearMonth is
/// not.
ClassMethod %IsIndependent() As %Boolean
{
	Quit 0
}

/// Return the number of seconds in one unit of this time level.
ClassMethod %GetPeriodLength() As %Integer
{
	Quit 86400
}

/// Utility method:
/// Convert a time format string to a $ZDT format number.
/// [Previously private]
ClassMethod %FormatToZDTCode(pFormat As %String, pDefault As %Integer) As %Integer [ CodeMode = expression ]
{
$Case(pFormat,"mm/dd/yyyy":1,"dd MMM yyyy":2,"yyyy-mm-dd":3,"dd/mm/yyyy":4,"MMM dd, yyyy":5,"MMM dd yyyy":6,"yyyymmdd":8,"M dd, yyyy":9,:pDefault)
}

/// Return set of possible options for this function.
/// This is return as an array subscripted by option name.
ClassMethod %GetOptionList(Output pList As %String) [ Final ]
{
	Set tOptions = ..#OPTIONLIST
	For n = 1:1:$L(tOptions,",") {
		Set tItem = $P(tOptions,",",n)
		Set:tItem'="" pList(tItem) = ""
	}
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit ""
}

/// Return the type of this level class (used by UI components).
ClassMethod %GetDimType() As %String
{
	Quit ..#DIMTYPE
}

/// Return the calendar that this class uses to calculate the members of the level
ClassMethod %GetCalendar() As %String
{
	// Method added by DTB177
	Quit ..#CALENDAR
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 0

	// find actual values in fact table index
	Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"mbr#",pDimNo,pHierNo,pLevelNo))
	Set tFact = $LG(tInfo,5)
	If (tFact'="") {
		Set tCubeIndex = $$$DeepSeeIndex($$$UPPER(pCube))
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,tFact,""))
		While (tKey '= "") {
			Set tCount = tCount + 1
			Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,tFact,tKey))
		}
	}
	Quit tCount
}

/// Return the member specification for the given member.<br/>
ClassMethod %GetMemberSpec(pMemberId As %String, pCubeName As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %String [ Internal ]
{
	Set tSpec = ""
	
	// JMD1453 return key, not name
	If (pMemberId'="") {
		Set tSpec = "&["_pMemberId_"]"
	}
	Quit tSpec
}

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// This is implemented by subclasses.<br/>
/// A subclass may extend this function and add additional arguments that
/// correspond to user-settable options. Option values will be
/// supplied when DeepSee invokes this method.<br/>
/// <var>pTimeOffset</var> is a time offset (interval) applied to the value.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pOffset As %String = "") As %Integer
{
	Quit pTime
}

/// Convert a level key (logical) value to a display value.
/// <var>pKey</var> is the logical value (the format is up to the implementer
/// of the class, but it must match that returned by the <method>%Convert</method> method.)<br/>
/// <var>Format</var> is an optional format value. This is specified
/// by the Format option when this level is specified within a cube definition.
/// The possible Format values are determined by the class implementor.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Quit pKey
}

/// Convert a level display value to its corresponding key value.
/// The format of the logical and display values are up to the class implementor.<br/>
/// <var>Format</var> is an optional format value. This is specified
/// by the Format option when this level is specified within a cube definition.<br/>
/// The possible Format values are determined by the class implementor.<br/>
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Quit ""
}

/// Convert a level key value into starting and ending base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Quit $$$ERROR($$$GeneralError,"%KeyToBaseRange not implemented by "_..%ClassName(1))
}

/// Given a pair of base values (in $H format) find a key value that lies within the range.
ClassMethod %BaseRangeToKey(Output pKey As %String, pStart As %Date, pEnd As %Date, pOffset As %String = "") As %Status
{
	// default implementation
	Set pKey = ""
	Set tSC = $$$OK
	Try {
		// invert offset
		Set:pOffset'="" pOffset = "-"_pOffset
		Set pKey = ..%Convert(pStart,pOffset)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of members of this level.
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pTimeOffset As %String = "", pFormat As %String = "") As %Status
{
	Quit $$$ERROR($$$GeneralError,"%GetLevelMembers not implemented by "_..%ClassName(1))
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
/// <var>pRelation</var> describes the relation:
/// "lead","lag","first","last"<br/>
/// "lead" and "lag" are relative to <var>pKey</var><br/>
/// "first" and "last" are relative to the first and last members of the level.<br/>
/// <var>pEndKey</var> is the end of the time period implied by the parent level (if applicable).
/// This is used by "first" and "last".<br/>
/// <var>pOffset</var> is an optional offset to apply (in the direction of the relation).<br/>
/// Note: pKey and pEndKey are key values and not $H values.
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	Quit $$$ERROR($$$GeneralError,"%GetRelatedKey not implemented by "_..%ClassName(1)_", relation: " _ pRelation)
}

/// Pull out all members of this level from the Fact table index.
ClassMethod %GetAllMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pFormat As %String = "") As %Status
{
	// find actual values in fact table index
	Set n = 0
	Set tCubeIndex = $$$DeepSeeIndex(pCube)

	//  JMD1041
	If (pStartRange="FIRST") {
		// if start range is "FIRST", return only the first member (skip null)
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,""))
		If (tKey = $$$DeepSeeNullTimeMarker) {
			Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,tKey))
		}
		If (tKey'="") {
			Set pList($I(n)) = $LB(..%KeyToValue(tKey,pFormat),tKey)	// value,key
		}
		Quit $$$OK
	}
	ElseIf (pStartRange="LAST") {
		//  if start range is "LAST", return only the last member
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,""),-1)
		If (tKey = $$$DeepSeeNullTimeMarker) {
			Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,tKey),-1)
		}
		If (tKey'="") {
			Set pList($I(n)) = $LB(..%KeyToValue(tKey,pFormat),tKey)	// value,key
		}
		Quit $$$OK
	}

	// get local copy of index entries
	Kill ^||tKeyList
	Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,""))
	While (tKey'="") {
		Set ^||tKeyList(tKey) = ""
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,tKey))
	}

	// if this is a "shared" dimension, merge with shared index
	If $D($$$DeepSeeMetaGLVN("sharesIndex",tCubeIndex,pFact)) {
		// +DTB070 - Collect the list of all cubes in the shared set 
		Kill tShareSet
		Set tShareCube = $O($$$DeepSeeMetaGLVN("sharesIndex",tCubeIndex,pFact,""),1,tOtherFactNo)
		While (tShareCube'="") {
			Set tShareSet(tShareCube) = tOtherFactNo
			Set tDeepShareCube = $O($$$DeepSeeMetaGLVN("sharesIndex",tShareCube,tOtherFactNo,""),1,tDeepFactNo)
			While (tDeepShareCube'="") {
				Set:(tDeepShareCube'=tCubeIndex) tShareSet(tDeepShareCube) = tDeepFactNo
				Set tDeepShareCube = $O($$$DeepSeeMetaGLVN("sharesIndex",tShareCube,tOtherFactNo,tDeepShareCube),1,tDeepFactNo)
			}
			Set tShareCube = $O($$$DeepSeeMetaGLVN("sharesIndex",tCubeIndex,pFact,tShareCube),1,tOtherFactNo)
		}
		
		// Add every cube's members to the master list of member keys
		Set tShareCube = $O(tShareSet(""),1,tOtherFactNo)
		While (tShareCube'="") {
			Set tKey = $O($$$DeepSeeIndexGLVN(tShareCube,tOtherFactNo,""))
			While (tKey'="") {
				Set ^||tKeyList(tKey) = ""
				Set tKey = $O($$$DeepSeeIndexGLVN(tShareCube,tOtherFactNo,tKey))
			}
			Set tShareCube = $O(tShareSet(tShareCube),1,tOtherFactNo)
		}
		// -DTB070
	}

	// JMD947: restrict by range
	Set tStartKey = ..%Convert(pStartRange)
	Set tEndKey = ..%Convert(pEndRange)
	If (tStartKey'="") {
		Set tStartKey = $O(^||tKeyList(tStartKey),-1)
	}

	// loop over keylist
	Set tKey = $O(^||tKeyList(tStartKey))
	While (tKey'="") {
		If ((tEndKey'="")&&(tKey>tEndKey)) {
			Quit
		}
		If (tKey = $$$DeepSeeNullTimeMarker) {
			Set pList($I(n)) = $LB($$$DeepSeeNullMarker,tKey)	// null markers
		}
		Else {
			Set pList($I(n)) = $LB(..%KeyToValue(tKey,pFormat),tKey)	// value,key
		}
		Set tKey = $O(^||tKeyList(tKey))
	}
	Quit $$$OK
}

/// Pull out the Nth (non-null) member (key) of this level from the Fact table index
/// where N is <var>pIndex</var>.
/// <var>pRelation</var> is "first" or "last"
/// If <var>pOffset</var> offset from the start or end.
ClassMethod %GetNthKey(Output pKey As %String, pCube As %String, pFact As %String, pRelation As %String, pOffset As %Integer = 0) As %Status [ Final ]
{
	Set pKey = ""
	Set tCubeIndex = $$$DeepSeeIndex(pCube)
	Set n = 0
	Set tDir = $S(pRelation="last":-1,1:1)
	Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,""),tDir)
	While (tKey'="") {
		If (tKey '= $$$DeepSeeNullTimeMarker) {
			If (n = pOffset) {
				Set pKey = tKey
				Quit
			}
			Set n = n + tDir
		}
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,tKey),tDir)
	}
	Quit $$$OK
}

}
