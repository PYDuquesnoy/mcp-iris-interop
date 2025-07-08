/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Extension.TextModelInput Extends ISCExtension [ System = 3 ]
{

Parameter XMLNAME = "X-TextModelInput";

/// This attribute defines whether the MiningField names referred in <property>Fields</property>
/// correspond to text that could contain any of the terms in DictionaryTerms (multiple input fields
/// are concatenated with two line breaks) or refer to inputs already containing the frequencies
/// of the terms in DictionaryTerms.
Property inputType As %DeepSee.PMML.Datatype.String(VALUELIST = ",text,terms", XMLPROJECTION = "ATTRIBUTE");

Property Fields As %DeepSee.PMML.Definition.Util.Array(XMLNAME = "Array", XMLPROJECTION = "ELEMENT");

/// If <property>inputType</property> = "text", this property should define language of this text
/// input as a comma-separated list of two-letter language codes.
Property languages As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "en" ];

}
