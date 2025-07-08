/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data object for a DeepSee subjectArea.<br/>
Class %DeepSee.Model.SubjectArea.subjectArea Extends (node, %CSP.Portal.AbstractPortalModel) [ System = 3 ]
{

/// Name of the cube(s) this subject area is based on.<br/>
/// This may contain a csv list of cubes. If so, then this subjectArea is a "compound cube"
/// that forms the logical union of all the cubes in the list. The first cube is the 
/// "primary" base cube.
Property baseCube As %DeepSee.Datatype.string(MAXLEN = 30000, XMLPROJECTION = "attribute");

/// If this is a "compound cube" then this is a csv list of zero or more shared dimension levels
/// that are used to "join" records between cubes when a query contains a reference to a non-shared
/// dimension.<br/>
/// Each level must include dimension, hierarchy, and level. 
/// For example: "[DateOfSale].[H1].[MonthSold]"<br/>
/// This feature can have a serious performance impact and should be used with caution.
Property connectsBy As %DeepSee.Datatype.string(MAXLEN = 30000, XMLPROJECTION = "attribute");

/// This is used as the caption text when utilities display this subject area.
Property caption As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The resource needed to view or edit this cube:<br/>
/// If defined and the current user holds the USE privilege on this resource, then
/// the user may view (run queries against) this item.<br/>
/// If defined and the current user holds the WRITE privilege on this resource, then
/// the user may modify this item.<br/>
Property resource As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// This is the user name of the owner of this subject area.<br/>
/// This is used for determining some privileges for this cube.
Property owner As %DeepSee.Datatype.string(MAXLEN = 250, XMLPROJECTION = "attribute");

/// Dimensions defined for this subject area.
Relationship dimensions As %DeepSee.Model.SubjectArea.dimension(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Measures defined for this subject area.<br/>
Relationship measures As %DeepSee.Model.SubjectArea.measure(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Listings defined for this subject area.<br/>
Relationship listings As %DeepSee.Model.SubjectArea.listing(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Relationships defined for this subject area.
Relationship relationships As %DeepSee.Model.SubjectArea.relationship(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Optional. Name of the default measure for this subject area.
/// This should simple be the name of a measure within the base cube.
/// This measure is used when no other measure is explicitly in context.
Property defaultMeasure As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Optional. Specification of the default member for this subject area.
/// This is used in queries that do not specify enough axis
/// information to be executed.<br/>
/// This should contain an MDX expression:
/// e.g., "[Product].[All Products]"
Property defaultMember As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Optional. This defines a filter applied to this subject area.<br/>
/// This should contain an MDX expression:
/// e.g., "[Product].[Toaster]"
Property filterSpec As %String(MAXLEN = 10000, XMLPROJECTION = "attribute");

/// Calculated members defined for this subject area.<br/>
Relationship calculatedMembers As %DeepSee.Model.SubjectArea.calculatedMember(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Named sets defined for this subject area.<br/>
Relationship namedSets As %DeepSee.Model.SubjectArea.namedSet(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = subjectArea ];

/// Optional. If specified, this is the name of the listing
/// (in the <property>listing</property> list) that
/// is used as the default RETURN clause for DRILLTHROUGH
/// queries against this cube.
Property defaultListing As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Optional. If defined, this is used as the (localized) display value for
/// the built-in %Count measure.
Property countMeasureCaption As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional. If defined, this is used as the logical name for
/// the built-in %Count measure.
Property countMeasureName As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// This setting controls whether the subject area will accept the use of Listing Groups 
/// to define auxiliary listings.
Property disableListingGroups As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Validate this model for logical errors.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		If (..disabled) {
			Quit
		}

		If (..name = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Subject Area must have a name")
			Quit
		}

		If (..baseCube = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Subject Area must have a base cube")
			Quit
		}
		//  if this is a compound cube, validate
		For p=1:1:$L(..baseCube,",") {
			Set tSubCube = $P(..baseCube,",",p)
			If (tSubCube = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Missing cube name in baseCube list")
				Quit
			}
			ElseIf $D(tSubCubeList($$$UPPER(tSubCube))) {
				Set tSC = $$$ERROR($$$GeneralError,"Duplicate cube name in baseCube list: " _ tSubCube)
				Quit
			}
			Else {
				Set tSubCubeList($$$UPPER(tSubCube)) = ""
			}
		}

		// dimensions
		Set tDimCount = ..dimensions.Count()
		For d = 1:1:tDimCount {
			Set tDim = ..dimensions.GetAt(d)
			If (tDim.disabled) {
				Continue
			}
			Set tBaseName = $$$UPPER(tDim.name)
			If (tBaseName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Dimension must have a name: " _ d)
			}
			ElseIf ($D(tDimNames(tBaseName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Dimension with duplicate name: " _ tDim.name)
			}
			Else {
				Set tDimNames(tBaseName) = ""
			}
			
			If ($$$UPPER(tDim.name) = "MEASURES") {
				Set tSC = $$$ERROR($$$GeneralError,"Dimension cannot be called 'Measures': " _ d)
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tDim.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// measures
		Set tMsrCount = ..measures.Count()
		For m = 1:1:tMsrCount {
			Set tMsr = ..measures.GetAt(m)
			If (tMsr.disabled) {
				Continue
			}
			Set tBaseName = $$$UPPER(tMsr.name)
			If (tBaseName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Measure must have a name: " _ m)
			}
			ElseIf ($D(tMsrNames(tBaseName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Measure with duplicate name: " _ tMsr.name)
			}
			Else {
				Set tMsrNames(tBaseName) = ""
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tMsr.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// listings
		Set tListingCount = ..listings.Count()
		For l = 1:1:tListingCount {
			Set tListing = ..listings.GetAt(l)
			If (tListing.disabled) {
				Continue
			}
			Set tBaseName = $$$UPPER(tListing.name)
			If (tBaseName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Listing must have a name: " _ l)
			}
			ElseIf ($D(tListingNames(tBaseName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Listing with duplicate name: " _ tListing.name)
			}
			Else {
				Set tListingNames(tBaseName) = ""
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tListing.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// relationships
		Set tRelationshipCount = ..relationships.Count()
		For r = 1:1:tRelationshipCount {
			Set tRelationship = ..relationships.GetAt(r)
			If (tRelationship.disabled) {
				Continue
			}
			Set tBaseName = $$$UPPER(tRelationship.name)
			If (tBaseName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship must have a name: " _ r)
			}
			ElseIf ($D(tRelationshipNames(tBaseName))) {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship with duplicate name: " _ tRelationship.name)
			}
			Else {
				Set tRelationshipNames(tBaseName) = ""
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tRelationship.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// calculated members
		// we do not check for duplicate names!
		Set tMbrCount = ..calculatedMembers.Count()
		For m = 1:1:tMbrCount {
			Set tMbr = ..calculatedMembers.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tMbr.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Calculated member must have a name: " _ m)
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tMbr.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// named sets
		// we do not check for duplicate names!
		Set tMbrCount = ..namedSets.Count()
		For m = 1:1:tMbrCount {
			Set tMbr = ..namedSets.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			Set tName = $$$UPPER(tMbr.name)
			If (tName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Named set must have a name: " _ m)
			}
			If $$$ISERR(tSC) Quit

			Set tSC = tMbr.%Validate()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
