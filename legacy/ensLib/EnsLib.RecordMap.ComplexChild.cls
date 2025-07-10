/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Class to implement the behaviour for objects that will be referenced by extensions of
/// <class>EnsLib.RecordMap.ComplexParent</class>, primarily <class>EnsLib.RecordMap.ComplexBatch</class>
/// and <class>EnsLib.RecordMap.ComplexSequence</class>.
/// The main work done here in the various generator methods is to use the "%%ParentRefs" subscript
/// of the main storage node to maintain a list of references to this object. This list is used
/// during the deletion of parents to determine whether this child can be removed.
Class EnsLib.RecordMap.ComplexChild Extends (%Persistent, EnsLib.RecordMap.ComplexBase) [ Abstract, NoExtent, System = 4 ]
{

/// Array to contain an in-memory set of references to parent objects.
/// The contents of this property can be reloaded by calling 
/// <method>%ParentRefsLoad</method>(). If no reloads are performed, the
/// values reflected in this array are only true as of the time the object was loaded.
Property %ParentRefs As %String [ MultiDimensional ];

/// Add a reference to the supplied parent from the specified child ID.
ClassMethod %ParentAdd(pID As %String = "", pParentClass As %String = "", pParentId As %String = "") As %Status [ CodeMode = objectgenerator ]
{
	Set tDataLoc = $$$comMemberKeyGet(%class.Name,$$$cCLASSstorage,"Default",$$$cSDEFdatalocation)
	If tDataLoc = "" {
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
	}
	Else {
		Do %code.WriteLine($c(9)_"If (pID '= """") && (pParentClass '= """") && (pParentId '= """") {")
		Do %code.WriteLine($c(9,9)_"Set "_tDataLoc_"(pID,""%%ParentRefs"",pParentClass,pParentId) = """"")
		Do %code.WriteLine($c(9)_"}")
		Do %code.WriteLine($c(9)_"Quit $$$OK")
	}
	Quit $$$OK
}

/// If the supplied child ID contains a reference to the specified parent, remove the reference.
ClassMethod %ParentRemove(pID As %String = "", pParentClass As %String = "", pParentId As %String = "") As %Status [ CodeMode = objectgenerator ]
{
	Set tDataLoc = $$$comMemberKeyGet(%class.Name,$$$cCLASSstorage,"Default",$$$cSDEFdatalocation)
	If tDataLoc = "" {
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
	}
	Else {
		Do %code.WriteLine($c(9)_"If (pID '= """") && (pParentClass '= """") && (pParentId '= """") {")
		Do %code.WriteLine($c(9,9)_"Kill "_tDataLoc_"(pID,""%%ParentRefs"",pParentClass,pParentId)")
		Do %code.WriteLine($c(9)_"}")
		Do %code.WriteLine($c(9)_"Quit $$$OK")
	}
	Quit $$$OK
}

/// Remove all parent references for a given child ID.
ClassMethod %ParentsClear(pID As %String = "") [ CodeMode = objectgenerator ]
{
	Set tDataLoc = $$$comMemberKeyGet(%class.Name,$$$cCLASSstorage,"Default",$$$cSDEFdatalocation)
	If tDataLoc = "" {
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
	}
	Else {
		Do %code.WriteLine($c(9)_"If (pID '= """") Kill "_tDataLoc_"(pID,""%%ParentRefs"")")
		Do %code.WriteLine($c(9)_"Quit $$$OK")
	}
	Quit $$$OK
}

/// Indicate whether any references exist for a given child ID.
ClassMethod %IsReferenced(pID As %String) As %Boolean [ CodeMode = objectgenerator ]
{
	Set tDataLoc = $$$comMemberKeyGet(%class.Name,$$$cCLASSstorage,"Default",$$$cSDEFdatalocation)
	Set tExpression = "Quit "_$select(tDataLoc = "": "0", 1: "''$data("_tDataLoc_"(pID,""%%ParentRefs""))")
	Do %code.WriteLine($c(9)_tExpression)
	Quit $$$OK
}

/// Load the data from the "%%ParentRefs" subnode into the <property>%ParentRefs</property> multidimensional property.
Method %ParentRefsLoad() As %Status [ CodeMode = objectgenerator ]
{
	Set tDataLoc = $$$comMemberKeyGet(%class.Name,$$$cCLASSstorage,"Default",$$$cSDEFdatalocation)
	If tDataLoc = "" {
		Do %code.WriteLine($c(9)_"Quit $$$ERROR($$$NotImplemented)")
	}
	Else {
		Do %code.WriteLine($c(9)_"Kill ..%ParentRefs")
		Do %code.WriteLine($c(9)_"Set tID = ..%Id()")
		Do %code.WriteLine($c(9)_"If (tID '= """") Merge ..%ParentRefs = "_tDataLoc_"(tID,""%%ParentRefs"")")
		Do %code.WriteLine($c(9)_"Quit $$$OK")
	}
	Quit $$$OK
}

/// Populate <property>%ParentRefs</property> when the object is opened.
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Quit ..%ParentRefsLoad()
}

}
