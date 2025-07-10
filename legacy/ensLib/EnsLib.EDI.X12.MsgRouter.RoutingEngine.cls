/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.MsgRouter.RoutingEngine Extends EnsLib.EDI.MsgRouter.SegmentedRoutingEngine [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// String specifying types of Validation to perform <p>
/// Set to 1 to block documents that don't pass default validation. Default validation requires a DocType
/// and blocks messages with any other error encountered while mapping the document's 
/// sequence of segments using the X12 schema structure specified by the document's DocType. This is equivalent to 'dm'. <p/>
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
/// 'x' - enforce X12 relational conditions where specified in the schema - Note this is not available when using a new-style only schema <br/>
/// 'n' - perform all validation available to new style schemas.  This is equivalent to 'dmscrlt' <br/>
/// 'a' - perform all available validation. This is equivalent to 'dmscrultv' <br/>
/// 'e' - continue validating after errors are encountered - specify this to scan the entire document and report all errors <br/>
Property Validation As %String(MAXLEN = 20) [ InitialExpression = "dm", Transient ];

/// Override this method to implement your own method for validating a Document.
/// Return non-zero to prevent default validation of the message;
/// return an error code in pStatus to indicate a validation failure.
Method OnValidate(pDoc As EnsLib.EDI.X12.Document, pValSpec As %String, Output pStatus As %Status = {$$$OK}) As %Boolean
{
	Set pStatus=##class(EnsLib.EDI.X12.Util.Validator).Validate(pDoc,pValSpec)
	Quit 1
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
