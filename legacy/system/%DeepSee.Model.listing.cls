/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object that represents a listing for a DeepSee cube.
/// This specifies what is used as the default RETURN clause for DRILLTHROUGH
/// queries against this cube.<br/>
/// If no listings are defined for a cube, then no listing option is provided.
Class %DeepSee.Model.listing Extends %DeepSee.Model.node [ System = 3 ]
{

/// Cube that this listing belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = listings ];

/// Indicates how to display this listing.<br/>
/// "table" (the default) shows the listing as a table.<br/>
/// "map" shows the listing within a map view. For this case, your listing must contain a columns called "Latitude" and "Longitude".<br/>
Property listingType As %String(MAXLEN = 50, VALUELIST = ",table,map", XMLPROJECTION = "attribute") [ InitialExpression = "table" ];

/// Optional. If specified, this is used as the RETURN clause for the DRILLTHROUGH
/// query used for this listing.<br/>
/// For listings based on a Data Connector, this attribute <b>must</b> be supplied.
Property fieldList As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Optional. This is a "^" delimited list of css formatting instructions for the listing.
/// Each piece of the list is applied to its corresponding column in the listing.
Property formatList As %String(MAXLEN = 5000, XMLPROJECTION = "attribute");

/// Optional. If specified, this is used as the %ORDER BY clause for the DRILLTHROUGH
/// query used for this listing.<br/>
/// This is only used if the cube's sourceClass is a persistent class.
Property orderBy As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Optional. If specified, this is the sql statement used for this listing.<br/>
/// This is only used if the cube's sourceClass is a persistent class.
Property sql As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Name of the <class>%DeepSee.DataConnector</class> class that provides the listing data.<br/>
/// If the cube uses a data connector as its sourceClass, then you must specify this value
/// if you wish to show listings for the cube.
/// If not specified, then the primary data connector for cube will be used for listings.
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

	If (..sourceClass'="") {
		If (..fieldList="") {
			Set tSC = $$$ERROR($$$GeneralError,"A listing with a dataSource must specify a fieldList:" _ ..name)
		}
	}

	Quit tSC
}

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-406089
	Set tListingObj = {}
	
	Try {
		// Listings directed at a dataconnector are not compatible with AtScale
		If (..sourceClass'="") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj("Dataconnector listings are not supported for AtScale export:"_..name,$$$msgInfo))
			Set tListingObj = ""
			Quit
		}
		If (..fieldList="") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj("Listing cannot be exported without a fieldList:"_..name,$$$msgInfo))
			Set tListingObj = ""
			Quit
		}

		Set tListingObj.name = ..name
		Set tListingObj.description = ..description _ $S((..description'=""):$C(13,10,13,10),1:"") _ $$$Text("Original expression in IRIS")_": " _ ..fieldList
		
		// DP-407533 - Every listing will be populated with a single participant, the default 
		// count measure which is guranteed to exist.
		Set tListingObj.participants = [].%Push(pAuxiliaryIndex.defaultCountName)
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tListingObj=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tListingObj
}

}
