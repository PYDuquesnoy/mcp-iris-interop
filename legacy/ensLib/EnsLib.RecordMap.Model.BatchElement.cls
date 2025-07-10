/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class to model the elements used in <class>EnsLib.RecordMap.Model.ComplexBatch</class>.
Class EnsLib.RecordMap.Model.BatchElement Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/Ensemble/RecordMap";

Parameter XMLSEQUENCE = 1;

/// The name of the BatchElement.
Property name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Indicate whether the element is required.
Property required As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Indicate whether the element repeats.
Property repeating As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// If <property>repeating</property> is true, the minimum number of times that the element must appear.
Property minRepeats As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

/// If <property>repeating</property> is true, the maximum number of times that the element must appear.
Property maxRepeats As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

/// Comments for the element.
Property annotation As %String(MAXLEN = 1024);

/// Helper method to indicate whether the element will appear a known number of times. If the element is
/// not required, or may appear a variable number of times, this method will return 0.
Method isExplicitSpec() As %Boolean [ CodeMode = expression, Internal ]
{
$select(..required && ('..repeating || (..maxRepeats = 1)): 1, ..repeating && ..minRepeats && (..minRepeats = ..maxRepeats): 1, 1: 0)
}

/// Basic validation of the properties in the class.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Set tStatus = ##class(EnsLib.RecordMap.Model.ComplexBatch).validatePropertyName(..name)
	If $$$ISERR(tStatus) Quit tStatus
	If ('..repeating) {
		If ..minRepeats Quit $$$ERROR($$$EnsRecordMapErrRepeatCountNotPermitted,"minRepeats")
		If ..maxRepeats Quit $$$ERROR($$$EnsRecordMapErrRepeatCountNotPermitted,"maxRepeats")
	}
	ElseIf (..repeating && ..required) {
		If (..minRepeats = 0) Quit $$$ERROR($$$EnsRecordMapErrRequiredCountZero,"minRepeats")
		If (..maxRepeats = 0) Quit $$$ERROR($$$EnsRecordMapErrRequiredCountZero,"maxRepeats")
	}
	Quit $$$OK
}

}
