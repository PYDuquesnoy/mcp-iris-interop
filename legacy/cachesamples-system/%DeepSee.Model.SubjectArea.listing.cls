/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a listing for a DeepSee SubjectArea.<br/>
Class %DeepSee.Model.SubjectArea.listing Extends %DeepSee.Model.SubjectArea.node [ System = 3 ]
{

/// Subject area that this listing belongs to.
Relationship subjectArea As %DeepSee.Model.SubjectArea.subjectArea(XMLPROJECTION = "none") [ Cardinality = one, Inverse = listings ];

/// Indicates how to display this listing.<br/>
/// "table" (the default) shows the listing as a table.<br/>
/// "map" shows the listing within a map view. For this case, your listing must contain a columns called "Latitude" and "Longitude".<br/>
Property listingType As %String(MAXLEN = 50, VALUELIST = ",table,map", XMLPROJECTION = "attribute") [ InitialExpression = "table" ];

/// Optional. If specified, this is used as the RETURN clause for the DRILLTHROUGH
/// query used for this listing.
Property fieldList As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. This is a "^" delimited list of css formatting instructions for the listing.
/// Each piece of the list is applied to its corresponding column in the listing.
Property formatList As %String(MAXLEN = 5000, XMLPROJECTION = "attribute");

/// Optional. If specified, this is used as the %ORDER BY clause for the DRILLTHROUGH
/// query used for this listing.
Property orderBy As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Hidden flag. If true, then this listing will be hidden (not part of the subject area model).
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional. If specified, this is the sql statement used for this listing.
Property sql As %String(MAXLEN = 5000, XMLPROJECTION = "attribute");

/// Name of the <class>%DeepSee.DataConnector</class> class that provides the listing data.<br/>
/// If the cube uses a data connector as its sourceClass, then you must specify this value
/// if you wish to show listings for the cube.
Property sourceClass As %DeepSee.Datatype.className(XMLPROJECTION = "attribute");

/// Optional. The resource needed to view this listing:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view this listing.<br/>
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// SQL selectMode which this SQL listing will use to execute.
/// <br>
/// Possible values are:
/// <ul>
/// <li> 0 for LOGICAL mode.</li>
/// <li> 1 for ODBC mode.</li>
/// <li> 2 for DISPLAY mode.</li>
/// </ul>
Property selectMode As %String(DISPLAYLIST = ",Logical,ODBC,Display", VALUELIST = ",0,1,2", XMLPROJECTION = "attribute") [ InitialExpression = 2 ];

/// Test if this listing's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK
	Quit tSC
}

}
