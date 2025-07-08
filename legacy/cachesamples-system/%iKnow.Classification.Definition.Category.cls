/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.Category Extends node [ Deprecated, System = 3 ]
{

/// A unique name for this classification category.
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// An optional description for this category.
Property description As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE");

/// The total number of records in the corpus in this category. (optional)
Property recordCount As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// Optional property formally describing how records are "selected" for this category.
/// Used when reverse engineering or optimizing a classifier definition.
Property spec As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

}
