/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%CSP.RuleBlock</class> class is the super class of all rule
/// generated classes for block structured tags, e.g. csp:if,
/// that represent elements within the DOM model.
Class %CSP.RuleBlock Extends %CSP.Rule [ System = 3 ]
{

/// The object instance for the containing block or "".
Property Container As %CSP.RuleBlock;

/// The label used for the <i>end</i> of this block,
/// e.g. the /csp:if clause for csp:if or after the loop for csp:while
Property EndLabel As %String;

/// The label used for the <i>next</i> block,
/// e.g. the csp:else clause for csp:if or the next iteration for csp:while
Property NextLabel As %String;

/// Get a new block and associated labels for this nested code block.
Method NewBlock()
{
	// Put this block on stack
	Set ..Container=%compiler.Get("%cspblockstack")
	Do %compiler.Set("%cspblockstack",$this)
}

/// Remove the this nested block.
Method RemoveBlock()
{
	Do %compiler.Set("%cspblockstack",..Container)
}

/// Get current block without creating a new one.
Method GetCurrentBlock() As %CSP.RuleBlock
{
	Quit %compiler.Get("%cspblockstack")
}

/// Get a new block label.
Method GetNewLabel() As %String
{
	Set num=%compiler.Get("%csplabel")+1
	Do %compiler.Set("%csplabel",num)
	Set zeroes="",$piece(zeroes,"0",6-$length(num))=""
	Quit $select(%compiler.IsBasic:"",1:"%")_"csp"_zeroes_num
}

}
