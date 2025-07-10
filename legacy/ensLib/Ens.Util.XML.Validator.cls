/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occSAX)

Class Ens.Util.XML.Validator Extends %XML.SAX.ContentHandler [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds any error messages from validation of the XML document
Property Errors As list Of %String;

/// This method takes the file/path name of the XML file to be validated and an [optional] schema 
/// spec of the XML schema(s) to be used to validate the document. 
ClassMethod ValidateFile(pTargetFile As %String, pSchemaSpec As %String = "") As %Status
{
	Set tSC=$$$OK
	try {
		#; Read and validate specified file
		Set tThis=..%New() If '$IsObject(tThis) Set tSC=%objlasterror Quit
		Set tSC=##class(%XML.SAX.Parser).ParseFile(pTargetFile,tThis,,,,pSchemaSpec)
		; Note if XML is well-formed but does not match schema, then tSC will be $$$OK but error count will be non-zero.
		For tI=1:1:tThis.Errors.Count() {
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrXMLValidation,tThis.Errors.GetAt(tI)))
		}
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// This method takes a stream of XML to be validated, an entity resolver and an [optional] schema
/// spec to be used to validate the document.
ClassMethod ValidateStream(pTargetStream As %BinaryStream, pResolver As Ens.Util.XML.Resolver, pSchemaSpec As %String = "") As %Status
{
	Set tSC=$$$OK
	try {
		#; Read and validate specified stream
		Set tThis=..%New()  $$$ASSERT($IsObject(tThis))
		Set tSC=##class(%XML.SAX.Parser).ParseStream(pTargetStream,tThis,pResolver,,,pSchemaSpec)
		; Note if XML is well-formed but does not match schema, then tSC will be $$$OK but error count will be non-zero.
		For tI=1:1:tThis.Errors.Count() {
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrXMLValidation,tThis.Errors.GetAt(tI)))
		}
	} catch {
		Set tSC=$$$SystemError
	}
	Quit tSC
}

/// Receive notification of a recoverable parser error.
Method error(error As %Library.String)
{
	Do ..Errors.Insert(error)
	Quit
}

/// Report a fatal XML parsing error.
Method fatalError(fatalerror As %Library.String)
{
	Do ..Errors.Insert(fatalerror)
	Quit
}

/// Receive notification of a parser warning.
Method warning(warning As %Library.String)
{
	Do ..Errors.Insert(warning)
	Quit
}

}
