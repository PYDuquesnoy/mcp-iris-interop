/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// CSP DOM object that implements CSP server tag.
/// Note that server tag is deprecated.
Class %CSP.TagCacheServer Extends %CSP.TagCache [ Not ProcedureBlock, System = 3 ]
{

/// Writes code into the routine builder object to render the
/// server tag.
Method RenderStartTag() As %Status
{
 Quit ..RenderAsCodeServer()
}

}
