/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Document class for Zen Application Editor.<br>
/// This document class applies to Zen application classes:
/// It allows the user to view a visual representation of 
/// a Zen Application class.
Class %ZEN.StudioDocument.ZENAppEditorDocument Extends %ZEN.StudioDocument.AbstractDocument [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter DESCRIPTION = "Zen Application Editor";

Parameter EDITORURL = "%25ZEN.StudioDocument.ZENAppEditor.cls";

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "app", DocumentNew = 0, DocumentType = "xedit");

Parameter EXTENSION = ".app";

/// If set, name of superclass used for documents of this type.<br>
Parameter DOCUMENTCLASS = "%ZEN.application";

/// Returns true if this document type is enabled, and false to disable it
ClassMethod IsEnabled() As %Boolean
{
	#; this is an experimental feature and is off by default
	Quit +$G(^%ISC.ZEN("ZENAppEditor"))
}

}
