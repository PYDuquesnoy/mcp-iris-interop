/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is only for use by %CPT.Warp.Path
Class %CPT.Warp.PathMatches Extends %RegisteredObject [ System = 4 ]
{

Property Matches As list Of %CPT.Warp.PathMatch [ Internal, Private ];

Method %OnNew(Path As %CPT.Warp.Path, TreeIndex As %Integer, NodeChains As %List) As %Status
{
	#Dim sc,i
	
	For i=1:1:$ListLength(NodeChains) {
		Set match=##class(%CPT.Warp.PathMatch).%New(Path,TreeIndex,$List(NodeChains,i)) If '$IsObject(match) {$$$ThrowStatus(%objlasterror)}
		$$$THROWONERROR(sc,..Matches.Insert(match))
	}
	
	Quit $$$OK
}

Method Any() As %Boolean [ CodeMode = expression, Internal ]
{
..Matches.Count()>0
}

Method FirstMatch() As %CPT.Warp.PathMatch [ Internal ]
{
	If '..Any() {$$$ThrowStatus($$$ERROR($$$GeneralError,"No match for path in tree"))}
	
	Quit ..Matches.GetAt(1)
}

Method Count() As %Integer [ CodeMode = expression, Internal ]
{
..Matches.Count()
}

Method Item(Index As %Integer) As %CPT.Warp.PathMatch [ CodeMode = expression, Internal ]
{
..Matches.GetAt(Index)
}

Method Dump() [ Internal ]
{
	#Dim i
	
	For i=1:1:..Count() {
		Do ..Item(i).Dump()
	}
}

}
