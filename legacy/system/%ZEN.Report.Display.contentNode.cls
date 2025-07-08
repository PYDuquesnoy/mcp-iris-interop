/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The base class is for nodes that use their content.  Such
/// nodes are not aware of any tags they contain.
Class %ZEN.Report.Display.contentNode Extends node [ Abstract, Deprecated, System = 4 ]
{

/// Content for this node.
Property content As %ZEN.Datatype.caption(MAXLEN = "", XMLPROJECTION = "content");

Property parent As %ZEN.Report.Display.node(XMLPROJECTION = "NONE");

Property xpath As %String(XMLPROJECTION = "NONE");

}
