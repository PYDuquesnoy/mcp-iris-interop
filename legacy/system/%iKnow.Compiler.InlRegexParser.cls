/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Compiler.InlRegexParser Extends %iKnow.Compiler.InlParser [ Deprecated ]
{

/// Parses from s, adding values to out up to max + epsilon.
/// returns count of objects added to out 
Method ParseToList(s As %Stream.FileCharacter, ByRef out As %List, max As %Integer) As %Integer
{
	//Regex lines look like:
	//static const Char Regex0Str[] = {102, 111, 111, 46, 42, }; // "foo.*"
	Set count = 0
	Set val = ""
	While (count < max) && 's.AtEnd {
		Set line = s.ReadLine()
		Set clist = $P($P(line, "{", 2), ", };", 1)
		If clist="" Continue
		Set len = $L(clist, ", ")
		Set pattern = ""
		For i=1:1:len {
			Set pattern = pattern _ $C(+$P(clist,", ", i))
		}
		Set out = out _ $LB(pattern)
		Set count = count + 1
	}
	Quit count
}

}
