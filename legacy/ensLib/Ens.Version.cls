/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsBuild)

Class Ens.Version [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod GetVersion(IncludeBuild = 1) As %String
{
	set value=$system.Version.GetNumber()
	set $p(value,".",3)=+$p(value,".",3),$p(value,".",4)=..GetBuild()
	Quit value
}

ClassMethod GetMajorVersion() As %String
{
	Quit $system.Version.GetMajor()
}

ClassMethod GetMinorVersion() As %String
{
	Quit $system.Version.GetMinor()
}

ClassMethod GetBuild() As %String
{
	Quit $system.Version.GetCompBuild()
}

}
