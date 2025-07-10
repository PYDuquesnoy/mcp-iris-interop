/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This class factors some common attributes for several nodes
Class EnsLib.EDI.SEF.CommonNode Extends EnsLib.EDI.SEF.Node [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the requirement as specified in the standard
Property StdRequirement As %String;

/// This holds the requirement as specifier by the user
Property UsrRequirement As %String;

/// This holds the calculated Actual requirement. It takes
/// into account the user and standard requirement and applies
/// the rules to determine the actual requirement that should be
/// applied when parsing transactions
Property ActRequirement As %String [ Calculated ];

/// This holds the maximum usage, >1 means unlimited repetition
Property RepeatCount As %String;

Method UsrRequirementGet() As %String
{
	#; If user requirement not specified use standard
	If i%UsrRequirement="" Quit ..StdRequirement
	Quit i%UsrRequirement
}

/// This is the accessor for the actual requirement. It applies
/// the rules to determine the actual requirement that should be
/// applied when parsing transactions
Method ActRequirementGet() As %String
{
	#; Standard overides user for mandatory items
	If ..StdRequirement="M" Quit "M"
	
	#; Otherwise, use the user requirement
	Quit $Case(..UsrRequirement,"!":"M","$":"O","-":"O","&":"C",:..UsrRequirement)
}

}
