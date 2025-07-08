/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using the property parameters shown here</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Adaptor">Projecting Objects to XML</a>.</p>
/// Property superclass used to hold information about property parameters for %XML.Adaptor.
Class %XML.PropertyParameters [ System = 2 ]
{

/// This is the XML element or attribute name to be used for this property.
Parameter XMLNAME;

/// The type of XML projection for this property. 
/// <ul>
/// <li>
/// NONE indicates that the property is not to be projected to XML. 
/// The XMLPROJECTION for private properties defaults to NONE.  Private properties 
/// are not automatically projected but can be forced to project by specifying a value 
/// for this parameter.			
/// </li>
/// <li>
/// ATTRIBUTE indicates that this property is projected as an attribute.
/// </li>
/// <li>
/// XMLATTRIBUTE indicates that this property is projected as an attribute from the default XML namespace using the xml: prefix.
/// </li>
/// <li>
/// CONTENT indicates that this property is the only element for this class and
/// its value is projected with no enclosing tag as the class' value.
/// </li>
/// <li>
/// ELEMENT indicates that this property is projected as an XML element or, in the
/// case of a collection, a list of element with no wrapping tag.
/// </li>
/// <li>
/// WRAPPED indicates that this property is projected as an XML element with
/// an addtional wrapping tag or, in the case of a collection, a list of elements 
/// wrapped in a tag for the collection.
/// </li>
/// </ul>
/// The XML projection will default to WRAPPED for a list or array collection property 
/// and ELEMENT for other public properties.
/// <p>
/// COLLECTION is now deprecated and replaced by its synonym WRAPPED.
/// ELEMENTREF value is now deprecated and replaced by the use of the XMLREF parameter.
Parameter XMLPROJECTION As STRING [ Constraint = ",NONE,ANY,ATTRIBUTE,XMLATTRIBUTE,CONTENT,ELEMENT,ELEMENTREF,WRAPPED,COLLECTION,XATTRIBUTE,XELEMENT", Flags = ENUM ];

/// How to project references to XML.
/// <ul>
/// <li>
/// SUMMARY indicates that only the summary properies of the referenced class
/// are used to represent the reference.  SUMMARY is the default.  Note that by
/// default all properties are of the referenced class are in the summary.
/// <li>
/// </li>
/// COMPLETE indicates that all properties of the referenced class are used
/// to represent the reference.
/// <li>
/// </li>
/// ID indicates that the id of a persistent or serial class is used to represent 
/// the reference.
/// <li>
/// </li>
/// OID indicates that the oid of a persistent or serial class is used to represent 
/// the reference.  The form of the oid will be classname,id.
/// <li>
/// </li>
/// GUID indicates that the GUID of a persistent class is used to represent the reference.
/// </li>
/// </ul>
/// 
Parameter XMLREFERENCE As STRING [ Constraint = ",SUMMARY,COMPLETE,ID,OID,GUID", Flags = ENUM ];

/// How to interpret the type of this property. 
/// <ul>
/// <li>
/// EXPLICIT indicates that only this property's explicitly specified type in XML
/// will be projected to XML.
/// <li>
/// </li>
/// CHOICE indicates that the schema for this property uses the XML schema choice 
/// group to allow multiple XML types for this property.  The classes for
/// these types are specified by the XMLCHOICELIST parameter or are all subclasses
/// of this property's type if no XMLCHOICELIST parameter.
/// <li>
/// </li>
/// SUBSTITUTIONGROUP indicates that the schema for this property uses the XML schema 
/// substituionGroup to allow multiple XML types for this property.  The classes for
/// these types are all subclasses of this property's type.
/// </li>
/// </ul>
/// 
Parameter XMLTYPECONSTRAINT As STRING [ Constraint = ",EXPLICIT,CHOICE,SUBSTITUTIONGROUP", Flags = ENUM ];

/// The XML name for a collection item.
Parameter XMLITEMNAME;

/// The XML name for the array key of a collection item.
Parameter XMLKEYNAME;

/// A comma-separated list of class names for XMLPROJECTION = CHOICE, ELEMENT-CHOICE or WRAPPED-CHOICE.
Parameter XMLCHOICELIST As CLASSNAME [ Flags = LIST ];

/// Controls whether input and/or output XML projections are done for this property.
/// Default is "INOUT".  Other possible values are "IN", "OUT", "CALC"
/// Calculated properties default to CALC which is like OUT 
/// except input is ignored instead of generating an error.
Parameter XMLIO As STRING [ Constraint = ",INOUT,IN,OUT,CALC", Flags = ENUM ];

/// Specified as true (1) if this property comes from an XML schema reference to a globally defined element.<br>
/// This parameter is deprecated and has been replaced by XMLREF.
Parameter XMLELEMENTREF As BOOLEAN [ Deprecated ];

/// Specified as true (1) if this property comes from an XML schema reference
/// to a globally defined element or attribute.<br>
/// 
/// This parameter is ignored for direct use of XMLExport -- it is only available for use by %XML.Writer
/// or SOAP support.
Parameter XMLREF As BOOLEAN;

/// If XMLREF is true, then REFNAMESPACE is the XML namespace that contains the global element or attribute.
/// However, if the default XML namespace is to be used (the XML namespace of the containing class
/// for primitive types and the actual XML namespaces for complex types), then this parameter may be omitted.<br>
/// 
/// This parameter is ignored for direct use of XMLExport -- it is only available for use by %XML.Writer
/// or SOAP support.
Parameter REFNAMESPACE As STRING;

/// If XMLREF is true, then REFELEMENTQUALIFIED is true if the XML namespace that contains 
/// the global element has elementFormDefault as "qualified" in its schema.
/// If not specified, this parameter defaults to the value of ELEMENTQUALIFIED for the class.
/// <p>
/// This parameter is ignored for direct use of XMLExport -- it is only available for use by %XML.Writer
/// or SOAP support.
Parameter REFELEMENTQUALIFIED As BOOLEAN;

/// The property parameter ELEMENTQUALIFIED may be used to override the ELEMENTQUALFIED parameter of the class.
/// The expected use of the ELEMENTQUALIFIED property parameter is to support the form="[un]qualified"
/// schema construct which allows an indiviual elemnt to be qualified differently that other elements of the class.<br>
/// ELEMENTQUALIFIED will be ignored if XMLREF=1.  REFELEMENTQUALIFIED should be used in that case.
Parameter ELEMENTQUALIFIED As BOOLEAN;

/// XMLPATTERN is a placeholder used to document the pattern facet of XML Schema types.
/// No runtime behavior is currently implemented to support the pattern facet semantics.
/// The XMLPATTERN is only used to include the pattern facet in schemas geenrated based on the class.
Parameter XMLPATTERN As STRING;

/// Controls the line ending behavior for a character stream property. 
/// <ul>
/// <li>
/// If XMLSTREAMMODE="block" (the default), the normalized XML data 
/// is copied unchanged to the stream. 
/// <li>
/// </li>
/// If XMLSTREAMMODE="line", the XML data 
/// is broken into lines separated by the streams LineTerminator sequence.
/// </li>
/// </ul>
Parameter XMLSTREAMMODE As STRING [ Constraint = ",BLOCK,LINE", Flags = ENUM ];

/// The XMLNIL property parameter controls the use for a property of the xsi:nil attribute
/// by XMLExport and the nillable attribute by XMLSchema.
/// <p>
/// If XMLNIL=1, then properties of the class with value = "" (null) are XMLExported
/// in the format &lt;propname xsi:nil="true"/>.
/// <p>
/// The exception is that string properties with value = "" are always exported as
/// &lt;propname/> if the class parameter XMLIGNORENULL=1 even if XMLNIL=1.
/// <p>
/// The XMLNIL property parameter overrides the XMLNIL class parameter for the
/// property where it is specified.
Parameter XMLNIL As STRING [ Constraint = ",0,1", Flags = ENUM ];

/// The XMLNILNOOBJECT parameter allows creation of an object to be skipped for elements
/// with xsi:nil="true".<br>
/// The default of XMLNILNOOBJECT = 0 will always create an object for an element with
/// xsi:nil="true".<br>
/// If XMLNILNOOBJECT = 1, then elements with xsi:nil="true" and no attributes
/// specified will be skipped, i.e. the value of the property will remain "".<br>
/// The XMLNILNOOBJECT property parameter overrides the XMLNILNOOBJECT class parameter for the
/// property where it is specified.
Parameter XMLNILNOOBJECT As STRING [ Constraint = ",0,1", Flags = ENUM ];

}
