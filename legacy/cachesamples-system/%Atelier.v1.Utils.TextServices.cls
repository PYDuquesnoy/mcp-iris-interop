/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides the external interface for retrieving, storing, and compiling
/// documents representing classes, routines, and include files (amongst others).
Class %Atelier.v1.Utils.TextServices
{

/// Given a name, return an array of strings representing the document. On success the
/// returned TextArray will have the 0 subscript set to the number of
/// lines and the subscripts 1-n will contain the actual text.<br>
/// Or, if the pBinary flag is set, the returned TextArray will contain chunks of Base64-encoded data.
/// and the node TextArray("bin") will be set to 1.
ClassMethod GetTextAsArray(pFullName As %String, pFlags As %Integer = 0, Output pTextArray As %String, pBinary As %Boolean = 0) As %Status
{
    Quit $$GetTextAsArray^%apiSRC(.pFullName,.pFlags,.pTextArray,.pBinary)
}

/// This method requires an integer subscripted array containing lines of text which represent an
/// InterSystems IRIS source document (class, include, routine, etc). array(0) should contain a count
/// of lines of text which are defined as array(1) ... array(n).
/// <br>
/// The method will parse the representation and if it is syntactically valid will attempt to 
/// save the resultant document. It returns $$$OK on success and a (possibly composite) error status on
/// failure. Note: a syntactically valid represention may fail to save due to failure to obtain a lock.
/// <br>
/// It is important to realize that this method will replace the existing document if present and therefore
/// must contain a full representation of the document. Also note that the name of the document will be derived from
/// within the text, unless pCategory is CSP or OTH.
/// <br>
/// If the binary flag is specified, the document array contains Base64-encoded chunks of data.
ClassMethod SetTextFromArray(ByRef pDocumentArray As %String, pFlags As %Integer = 0, pDocName As %String, pCategory As %String, pBinary As %Boolean = 0) As %Status [ Internal ]
{
    Quit $$SetTextFromArray^%apiSRC(.pDocumentArray,.pFlags,.pDocName,.pCategory,.pBinary)
}

}
