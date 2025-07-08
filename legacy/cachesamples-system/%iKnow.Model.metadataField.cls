/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation for metadata fields registered for a specific domain.
/// See also <class>%iKnow.Queries.MetadataI</class> for more information about any specific
/// properties.
Class %iKnow.Model.metadataField Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "field";

/// The <metadata> element this field belongs to.
Relationship metadata As %iKnow.Model.metadata(XMLPROJECTION = "none") [ Cardinality = one, Inverse = fields ];

/// The name of this metadata field, which should be unique within the domain.
Property name As %String(MAXLEN = 150, XMLPROJECTION = "attribute");

/// Any operators this metadata field is to support at runtime for filtering purposes.
Property operators As %String(MAXLEN = 250, XMLPROJECTION = "attribute") [ InitialExpression = {$$$MDOPEQUAL} ];

/// The data type of this metadata field. Any of $$$MDDTSTRING, $$$MDDTNUMBER or $$$MDDTDATE
Property dataType As %String(MAXLEN = 10, XMLPROJECTION = "attribute") [ InitialExpression = {$$$MDDTSTRING} ];

/// Storage type for this metadata field: either $$$MDSTNORMAL for cases where you would use a normal
/// index, $$$MDSTBITMAP where you would use a bitmap index (few different
/// metadata values compared to total # of records)
Property storage As %Integer(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Whether or not this metadata fields content should be treated with case sensitivity.
Property caseSensitive As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..name="") { 
			set tSC = $$$ERROR($$$GeneralError, "Metadata field name is a required field")
			quit
		} else {
			set tFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(pDomainId, ..name)
			if tFieldId {
				set tDefClass = ^IRIS.IK.Sys.Params(pDomainId,$$$IKPDEFINITIONCLASS)
				if '$d(^IRIS.IK.Sys.Definition(tDefClass,"metaField",tFieldId)) {
					set tSC = $$$ERROR($$$IKMDFieldExists, ..name)
					quit
				}
			}
		}
		
		if (..dataType="") {
			set tSC = $$$ERROR($$$GeneralError, "Metadata field data type is a required field")
			quit
		} elseif (..dataType'=$$$MDDTSTRING) && (..dataType'=$$$MDDTDATE) && (..dataType'=$$$MDDTNUMBER) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown metadata field data type: "_..dataType)
			quit
		}
		
		if (..operators="") {
			set tSC = $$$ERROR($$$GeneralError, "Metadata field operators is a required field")
			quit
		} elseif (..operators'="ALL") {
			set ..operators = $$$UPPER(..operators)
			for i = 1:1:$l(..operators,",") {
				set tOperator = $zstrip($piece(..operators,",",i), "<>W")
				if '$lf($$$MDALLOPERATORS, tOperator) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown metadata operator: " _ tOperator)
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
