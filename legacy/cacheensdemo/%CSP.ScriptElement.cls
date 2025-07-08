/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.ScriptElement</b> class is the class representing
/// unrecognized script tag in the DOM.
Class %CSP.ScriptElement Extends %CSP.Element [ Not ProcedureBlock, System = 3 ]
{

/// Indicates children are in a script tag and writes code into the 
/// routine builder object that will do the default rendering for a begin tag.
Method RenderStartTag() As %Status
{
 Set %compiler.InScript=1
 Quit ..RenderDefaultStartTag()
}

/// Resets script indicator and writes code into the routine builder 
/// object that will do the default rendering for an end tag.
Method RenderEndTag() As %Status
{
 Set %compiler.InScript=0
 Quit ..RenderDefaultEndTag()
}

}
