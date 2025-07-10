/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

Class EnsLib.EDI.XML.Operation.Standard Extends Ens.BusinessOperation [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/* Keep in sync with comments in method EnsLib.EDI.XML.DOM:domGetSubtree() - except for the C() part which is described in EnsLib.EDI.XML.Document:OutputToIOStream() */
/// String of format specification characters to use in encoding outbound documents.
/// Empty string means use the default behavior. <p/>
/// Format specification characters:<ul>
/// <li>1-9 : indent with this number of spaces (4 is the default with the 'i' format specifier)</li>
/// <li>a : attributes alphabetical</li>
/// <li>c : canonical ; ignores 'eintw'</li>
/// <li>e : close elements even when empty</li>
/// <li>f : full top element not just its contents</li>
/// <li>g : suppress output of empty elements</li>
/// <li>i : indent with 4 spaces unless 't' or 1-9</li>
/// <li>l : output schema information, schema uri and schema location, based on property stored in ..schemaLocation</li>
/// <li>n : newline (lf) after every text-free element</li>
/// <li>o : output unescaped - for instance don't change &lt; to &amp;lt;</li>
/// <li>p : suppress output of namespace prefixes</li>
/// <li>q : use double quotes to set off attribute values if possible</li>
/// <li>s : use stored indentation whitespace (ignores 'it1-9')</li>
/// <li>r : use stored returns / newlines (ignores 'nw')</li>
/// <li>t : indent with tab</li>
/// <li>u : declare prefixes as well as using them</li>
/// <li>w : Windows-style cr/lf newline after every text-free element</li>
/// <li>x : omit namespaces in output</li>
/// <li>C(e) : output an XML header line declaring character encoding e. If e is empty use the encoding defined by the Adapter. If e begins with ! force the output stream's encoding. Note that this will be applied automatically for File Operations configured with a non-UTF-8 Charset</li>
/// </ul>
Property Format As %String;

/// Store a set of searchable properties in SearchTable records associated with each document processed.<p>
/// These records will be of the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 100);

Parameter SETTINGS = "Format:Basic,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.XML.Operation.Standard}";

/// URL of an XSD schema to use to validate the outgoing document
Property Validation As %String(MAXLEN = 850);

/* override default value */
/// How long to keep retrying before giving up and returning an error code
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// Override this method to implement your own custom method for validating of an incoming Document
Method OnValidate(pDoc As EnsLib.EDI.Document, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

Method validateAndIndex(pDoc As EnsLib.EDI.Document) As %Status
{
	If ""=..Validation||'..OnValidate(pDoc,..Validation,.tSC) { /* no default validation */ }
	Set:'$D(tSC) tSC=$$$OK
	If $$$ISERR(tSC) {
		Set ..SuspendMessage=1
		Do ..SendAlert(##Class(Ens.AlertRequest).%New($LB(..%ConfigName,"Suspended document "_pDoc.%Id()_" because it failed validation using spec '"_..Validation_"' with error "_$$$StatusDisplayString(tSC))))
		Quit tSC
	}
	If ""'=..SearchTableClass {
		TRY {		
			Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit $$$OK
}

}
