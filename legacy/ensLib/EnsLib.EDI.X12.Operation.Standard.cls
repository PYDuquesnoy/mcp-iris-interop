/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

/// This is an abstract superclass for X12 Operations that send an X12 message
Class EnsLib.EDI.X12.Operation.Standard Extends (Ens.BusinessOperation, EnsLib.EDI.X12.Util.IOFraming) [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// String of separator characters to use in encoding outbound documents. Order is DataElementSeparator, ComponentSeparator, RepetitionSeparator.<p>
/// Empty string means use the default values of the outbound document.<p>
/// Additional characters will be used to override the Segment Terminator; may be up to 3 chars for output with newlines.<p>
/// After position 3, '\r' means Ascii 13 (Carriage Return), '\n' means Ascii 10 (Linefeed / Newline), and '\a' means Ascii 30 (Record Separator).<p>
/// You can also pad the separators up to position 3 with \x if you need to specify a line terminator but want
/// your output messages to show less than 3 separators. The separators designated by \x will not be written out.
Property Separators As %String(MAXLEN = 10) [ InitialExpression = {$$$X12DefSeparatorsEsc_$$$X12DefSegTerminator_"\r\n"} ];

/// Store a set of searchable properties in SearchTable records associated with each document processed.<p>
/// These records will be of the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 100);

/// String specifying types of Validation to perform <p>
/// Set to 1 to block documents that don't pass default validation. Default validation blocks messages with any error encountered while mapping the document's 
/// sequence of segments using the X12 schema structure specified by the document's DocType. This is equivalent to 'm'. <p/>
/// All flags relating to fields/components apply only if 's'/'c' also specified
/// (eg. if set to 'dmslt' then the length and datatype of fields will be checked, but the length and datatype of components will not be) <p/>
/// 'd' - require DocType <br/>
/// 'm' - don't tolerate BuildMap segment mapping errors <br/>
/// 's' - enforce segment structures (number and repetition of fields) <br/>
/// 'c' - enforce composite structures (number of components) <br/>
/// 'r' - enforce required fields/components being present <br/>
/// 'u' - enforce non-use of fields/components marked 'Not Used' - Note this is not available when using a new-style only schema <br/>
/// 'l' - enforce field/component length restrictions <br/>
/// 't' - enforce correct datatypes used for field/component values <br/>
/// 'v' - enforce correct code table values used where specified in the schema - Note this is not available when using a new-style only schema <br/>
/// 'x' - enforce relational conditions where specified in the schema - Note this is not available when using a new-style only schema <br/>
/// 'n' - perform all validation available to new style schemas.  This is equivalent to 'dmscrlt' <br/>
/// 'a' - perform all available validation. This is equivalent to 'dmscrultv' <br/>
/// 'e' - continue validating after errors are encountered - specify this to scan the entire document and report all errors <br/>
Property Validation As %String;

Parameter SETTINGS = "Separators,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.X12.Operation.Standard},DefCharEncoding::selector?context={Ens.ContextSearch/CharacterSets},Validation";

/* override default value */
/// How long to keep retrying before giving up and returning an error code
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

Method OnInit() As %Status
{
	#; parse and unescape \a, \x, \r, \n
	Set tSeps=..Separators, pos=2
	For { Set pos=$F(tSeps,"\",pos)  Quit:'pos  Set c=$E(tSeps,pos)
		Set tNew=$Case($ZCVT(c,"L")
						, "a":$C(30)
						, "x":$E($C(17,0),pos-2)
						, "r":$E($C(17,0),pos-2,2)_$C(13)
						, "n":$E($C(17,0),pos-2,2)_$C(10)
						, :"\"_c)
		Set $E(tSeps,pos-1,pos)=tNew, pos=pos+$L(tNew)-1-("\"=$E(tNew,*)&&("\"'=tNew))
	}
	Set ..Separators=tSeps
	Quit $$$OK
}

/// Override this method to implement your own custom method for validating of an incoming Document
Method OnValidate(pDoc As EnsLib.EDI.Document, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

Method validateAndIndex(pDoc As EnsLib.EDI.Document) As %Status
{
	If ""'=..Validation&&'$method($this,"OnValidate",pDoc,..Validation,.tSC) {
		If ..Validation["1" {
			Set tSC = pDoc.BuildMap()
		} ElseIf ..Validation["," {
			// for backwards compatibility - if using commas, probably left-over from when description said string should be comma-separated (even though it did nothing)
			Set tSC = $$$OK
		} Else {
			Set tSC=##class(EnsLib.EDI.X12.Util.Validator).Validate(pDoc,..Validation)
		}
	}
	Set:'$D(tSC) tSC=$$$OK
	If $$$ISERR(tSC) {
		Set ..SuspendMessage=1
		Do ..SendAlert(##Class(Ens.AlertRequest).%New($LB(..%ConfigName,"Suspended X12 message "_pDoc.%Id()_" because it failed validation using spec '"_..Validation_"' with error "_$$$StatusDisplayString(tSC))))
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
