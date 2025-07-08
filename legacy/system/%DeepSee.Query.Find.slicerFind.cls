/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %IFInclude)

Class %DeepSee.Query.Find.slicerFind Extends %SQL.AbstractFind
{

Property qid As %Integer;

/// Find expects <var>pQID</var> in the format $LB(CUBE,slicerKey). The appropriate slotNo to read the slicer from the cache
/// is calculated from the chunk number as needed.
ClassMethod Find(pQID As %List) As %SQL.AbstractFind [ SqlName = slicerFind, SqlProc ]
{
	set f = ..%New()
	set f.qid = pQID
	quit f
}

Method ContainsItem(pItem As %String) As %Boolean
{
    Set tChunk=$$$DeepSeeFactToChunk(pItem), tPos=$$$DeepSeeFactToPos(pItem)
    Set tCubeIndex = $LG(i%qid,1)
	quit $bit($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",$$$DeepSeeFactToCacheSlot(tCubeIndex,pItem),$LG(i%qid,2),tChunk),tPos)
}

Method ReturnBitmapExtentGlobalName() As %String
{
	Set tCubeIndex = $LG(i%qid,1)
	Return $name($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact"))
}

Method GetChunk(pChunk As %Integer) As %Binary
{
    Set tCubeIndex = $LG(i%qid,1)
	quit $g($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",$$$DeepSeeChunkToCacheSlot(tCubeIndex,pChunk),$LG(i%qid,2),pChunk))
}

Method NextChunk(ByRef pChunk As %Integer = "") As %Binary
{
    Set tCubeIndex = $LG(i%qid,1), pChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",pChunk))
	quit $S((pChunk'=""):$g($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",$$$DeepSeeChunkToCacheSlot(tCubeIndex,pChunk),$LG(i%qid,2),pChunk)),1:"")
}

Method PreviousChunk(ByRef pChunk As %Integer = "") As %Binary
{
    Set tCubeIndex = $LG(i%qid,1), pChunk = $O($$$DeepSeeIndexGLVN(tCubeIndex,"$Fact",pChunk),-1)
	quit $S((pChunk'=""):$g($$$DeepSeeMaskGLVN(tCubeIndex,"slicer",$$$DeepSeeChunkToCacheSlot(tCubeIndex,pChunk),$LG(i%qid,2),pChunk)),1:"")
}

}
