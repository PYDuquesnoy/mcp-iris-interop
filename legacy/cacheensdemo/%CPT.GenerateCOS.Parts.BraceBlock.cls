/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CPT.GenerateCOS.Parts.BraceBlock Extends %CPT.GenerateCOS.Abstract [ System = 4 ]
{

/// required
Property Commands As list Of %CPT.GenerateCOS.Abstract [ Internal, Private ];

Method AddComponent(Component As %RawString, ComponentType As %String = "") [ Internal ]
{
	#Dim sc
	
	Set sc=..Commands.Insert(Component) If $$$ISERR(sc) {$$$ThrowStatus(sc)}
}

Method RenderTo(Stream As %Stream.Object) [ Internal ]
{
	#Dim sc,i
	
	Set sc=Stream.Write("{") If $$$ISERR(sc) {$$$ThrowStatus(sc)}
	
	For i=1:1:..Commands.Count() {
		$$$RENDERTO(..Commands.GetAt(i),Stream)
	}

	Set sc=Stream.Write("}") If $$$ISERR(sc) {$$$ThrowStatus(sc)}
}

Method DumpTo(Stream As %Stream.Object) [ Internal ]
{
	#Dim sc,i
	
	Set sc=Stream.Write("BraceBlock(") If $$$ISERR(sc) {$$$ThrowStatus(sc)}
	
	For i=1:1:..Commands.Count() {
		If i'=1 {Set sc=Stream.Write(",") If $$$ISERR(sc) {$$$ThrowStatus(sc)}}
		$$$DUMPTO(..Commands.GetAt(i),Stream)
	}

	Set sc=Stream.Write(")") If $$$ISERR(sc) {$$$ThrowStatus(sc)}
}

}
