/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized version of the JSON provider pulls a subset of data from a master JSON provider.
/// This is intended for cases where there is a subset of data within a larger content object and
/// the application needs to see this data independently. A typical case is an array within a containing object.<br/>
/// This component ignores all of the data source callback methods inheritied from the <class>jsonProvider</class> class.
Class %ZEN.Auxiliary.jsonArrayProvider Extends (%ZEN.Auxiliary.jsonProvider, %ZEN.Component.dataView) [ Deprecated, System = 3 ]
{

/// Name of the property within the base JSON model that contains the array projected
/// by this provider.
Property arrayName As %ZEN.Datatype.string [ InitialExpression = "children" ];

/// Draw JSON output.
Method %DrawJSON() As %Status [ Internal ]
{
	Set ..contentType = "array"
	Write "null"
	Quit $$$OK
}

/// Return the client-side JSON data as an object or null.
ClientMethod getContentObject() [ Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		// try to connect to dataController
		this.connectToController();
		controller = this.getController();
	}
	return controller&&controller.getContentObject ? controller.getContentObject() : null;
}

/// Return the array within the content object that supplies the values to a dataView.
ClientMethod getContentArray() [ Internal, Language = javascript ]
{
	var data = this.getContentObject();
	return data && data[this.arrayName] ? data[this.arrayName] : null;
}

}
