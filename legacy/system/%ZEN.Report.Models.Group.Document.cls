/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Models.Group.Document Extends (%RegisteredObject, %XML.Adaptor) [ Deprecated, Inheritance = right, System = 4 ]
{

Parameter XMLNAME = "document";

/// Specifies the height of the document.
Property height As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "11in" ];

/// Specifies the width of the document.
Property width As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "8.5in" ];

/// Specifies the left margin width of the document.
Property marginLeft As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "1.25in" ];

/// Specifies the right margin width of the document.
Property marginRight As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "1.25in" ];

/// Specifies the top margin of the document. This does not include the
/// space left for the header.
Property marginTop As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "1in" ];

/// Specifies the bottom margin of the document. This does not include the
/// space left for the footer.
Property marginBottom As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "1in" ];

/// Specifies the amount of room available for the contents of the &lt;pageheader&gt; tag.
Property headerHeight As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "0" ];

/// Specifies the amount of room available for the contents of the &lt;pagefooter&gt; tag.
Property footerHeight As %ZEN.Datatype.length(XMLPROJECTION = "attribute") [ InitialExpression = "0" ];

}
