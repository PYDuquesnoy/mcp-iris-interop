/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsRecordMap)

/// Abstract model superclass for Composite and Field objects. This class is needed to allow a collection
/// of both object types to be created.
Class EnsLib.RecordMap.Model.RecordProperty Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/Ensemble/RecordMap";

Parameter XMLSEQUENCE = 1;

/// The name of the Field or Composite.
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Indicate whether the property is required. In the case of Fields, this also indicates
/// whether the property in InterSystems IRIS should be marked as required for successful validation.
Property required As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Field/Composite appears in the records, but should not be mapped to a property in the record object.
Property ignored As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Comments for the property.
Property annotation As %String(MAXLEN = 1024);

/// A non-projected property to indicate what kind of RecordMap is being composed.
Property RecordType As EnsLib.RecordMap.Model.DataType.RecordType(XMLPROJECTION = "NONE");

/// Recursive method to retrieve the greatest depth of this branch of the object graph.
Method GetDepth(Output pHasRepeats As %Boolean) As %Integer [ Internal, ServerOnly = 1 ]
{
	Set pHasRepeats = 0
	Quit 1
}

}
