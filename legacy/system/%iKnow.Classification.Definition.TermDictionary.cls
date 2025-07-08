/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.TermDictionary Extends node [ Deprecated, System = 3 ]
{

/// The method used to compile the list of terms used by this classifier.
/// (optional, for information purposes only)
Property termSelectionMethod As %String(XMLPROJECTION = "ATTRIBUTE");

/// The list of terms this classifier will consider for picking a category.
Property Terms As list Of Term(XMLPROJECTION = "WRAPPED", XMLTYPECONSTRAINT = "choice");

/// An optional list of metadata properties that need to be appended to the term weights in 
/// the document vector, so they can be taken into account by the classification method.
Property MetadataProperties As list Of MetadataProperty(XMLPROJECTION = "WRAPPED") [ Internal ];

/// If the list of terms contains non-english entries for which the count policy is not "exactCount",
/// set this attribute to the appropriate two-letter language identifier.
Property defaultLanguage As %String(XMLPROJECTION = "ATTRIBUTE");

}
