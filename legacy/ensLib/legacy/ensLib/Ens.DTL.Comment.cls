/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a container for an annotation which can comment the DTL without being attached
/// to a particular action
Class Ens.DTL.Comment Extends Ens.DTL.Action [ System = 3 ]
{

XData Example
{
<comment/>
}

Parameter TAGNAME = "comment";

Method GenerateCode(pCompiler As Ens.DTL.Compiler) As %Status
{
	Quit $$$OK
}

/// Provide a user readable string which identifies this node
Method DisplayName() As %String
{
	Quit "Comment"
}

}
