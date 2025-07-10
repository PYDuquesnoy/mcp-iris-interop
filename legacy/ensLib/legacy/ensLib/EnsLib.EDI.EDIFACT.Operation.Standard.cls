/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

Class EnsLib.EDI.EDIFACT.Operation.Standard Extends Ens.BusinessOperation [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// String of separator characters to use in encoding outbound documents. Order is ComponentSeparator,DataElementSeparator,EscapeSeparator,RepeatSeparator.<p>
/// Empty string means use the default values of the outbound document.<p>
/// Additional characters will be used to override the Segment Terminator; may be up to 3 chars for output with newlines.<p>
/// '\x' may be used in positions 3 and/or 4 to pad the Separators so that a segment terminator may be specified without specifying an EscapeSeparator and/or RepeatSeparator.<p> 
/// After position 4, '\r' means Ascii 13 (Carriage Return), and '\n' means Ascii 10 (Linefeed / Newline).
Property Separators As %String(MAXLEN = 11) [ InitialExpression = {$$$EDIFACTDefSeparators_$$$EDIFACTDefSegTerminator_"\r\n"} ];

/// Store a set of searchable properties in SearchTable records associated with each document processed.<p>
/// These records will be of the named SearchTable class, if any.
Property SearchTableClass As %String(MAXLEN = 100);

/// Comma-separated string specifying types of Validation to perform; see the class EnsLib.EDI.EDIFACT.Validator for details.<p>
/// Any non-zero string will invoke basic validation.
Property Validation As %String;

Parameter SETTINGS = "Separators,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.EDIFACT.Operation.Standard},Validation";

/* override default value */
/// How long to keep retrying before giving up and returning an error code
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// If SearchTableClass is set, use it to index any replies (including ACKs unless IndexACKs=false)
Parameter IndexReplies As %Boolean = 0;

Method OnInit() As %Status
{
	// parse and unescape \r, \n, \x
	Set tSeps=..Separators, pos=0
	For { Set pos=$F(tSeps,"\",pos)  Quit:'pos  Set c=$E(tSeps,pos)
		Set tNew=$Case($ZCVT(c,"L"), "r":$C(13), "n":$C(10), "x":$Case(pos,4:$C(19),5:$C(20),:"\x"), "\":"\", :"\"_c), $E(tSeps,pos-1,pos)=tNew, pos=pos+$L(tNew)-1
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
	If ""'=..Validation && '$zobjmethod($this,"OnValidate",pDoc,..Validation,.tSC) {
		Set tSC=##class(EnsLib.EDI.EDIFACT.Validator).Validate(pDoc,..Validation)
	} Set:'$D(tSC) tSC=$$$OK
	If $$$ISERR(tSC) {
		Set ..SuspendMessage=1
		Do ..SendAlert(##Class(Ens.AlertRequest).%New($LB(..%ConfigName,"Suspended document "_pDoc.%Id()_" because it failed validation using spec '"_..Validation_"' with error "_$$$StatusDisplayString(tSC))))
		Quit tSC
	}
	If ""'=..SearchTableClass {
		TRY {		
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit $$$OK
}

}
