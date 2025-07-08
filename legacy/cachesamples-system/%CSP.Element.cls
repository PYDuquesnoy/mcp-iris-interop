/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.Element</b> class is the default class representing an
/// unrecognized tag in the DOM.
Class %CSP.Element Extends %CSP.Rule [ Not ProcedureBlock, System = 3 ]
{

/// Writes code into the routine builder object that will do the
/// default rendering for a begin tag.
Method RenderStartTag() As %Status
{
 Quit ..RenderDefaultStartTag()
}

/// Writes code into the routine builder object that will do the
/// default rendering for an end tag.
Method RenderEndTag() As %Status
{
 Quit ..RenderDefaultEndTag()
}

}
