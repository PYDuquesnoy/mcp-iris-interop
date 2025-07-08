/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Binding.JavaFile Extends %Library.File [ System = 4 ]
{

Property isInterface As %Boolean;

Property createsInterface As %Boolean;

Method IndentAndWriteLine(statement = "", tabNum = 0) As %Status
{
	if ..isInterface {
		if '..createsInterface {q 1}	
	}
	
	s tabs = ""
	for i = 1:1:tabNum {
		s tabs = tabs_"	"	
	}
	q ..WriteLine(tabs_statement)
}

}
