/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

IncludeGenerator %ZEN.Utils

/// This is the abstract base class used by all model classes within
/// the Zen Model-View-Controller mechanism.<br>
/// Subclasses of this class are used to implement the Model portion of the Zen 
/// Model-View-Controller mechanism.<br>
/// A DataModel class provides a generic mechanism to take
/// data values from one or more sources (such as from a persistent object,
/// external database, or directly from a global) and place these
/// values into the properties of the DataModel.
Class %ZEN.DataModel.DataModel Extends %RegisteredObject [ Abstract, DependsOn = (%ZEN.Generator, %ZEN.DataModelUtils), Deprecated, System = 3 ]
{

/// If this parameter is true, then this is a read-only data model.
/// Instances of this data model cannot be saved or deleted.
Parameter READONLYMODEL As BOOLEAN = 0;

/// The ID value used to identify a specific instance of DataModel object.<br>
/// The form and possible values of the ID are up the implementor
/// of a specific DataModel class.
Property %id As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ ClientName = dataModelId, Transient ];

/// Number of data series contained within the data model.
Property %seriesCount As %ZEN.Datatype.integer(XMLPROJECTION = "NONE") [ InitialExpression = 1, Transient ];

/// An array containing the display names for data series subscripted by series number (1-based).
Property %seriesNames As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional, Transient ];

/// Create an in-memory instance of a DataModel object and load
/// data into it properties.<br>
/// This is implemented by the subclasses of this class.
/// The signature of this method is designed to match the %OpenId method
/// of persistent classes.
ClassMethod %OpenModel(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Set pSC = $$$ERROR($$$NotImplemented)
	Quit ""
}

/// This callback method is invoked when a DataModel is opened.
/// If implemented, it opens an instance of the data source object
/// used by the DataModel.
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ""
}

/// This callback method is invoked when a DataModel needs a new instance.
/// If implemented, it opens a new (unsaved) instance of the data source object
/// used by the DataModel.
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ""
}

/// This callback method does the actual work of loading values 
/// from the data source into this DataModel object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Save the data in this instance of DataModel back to its original 
/// source, if possible.<br>
/// This is implemented by the subclasses of this class.
Method %SaveModel() As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// This callback method does the actual work of copying values 
/// from the DataModel to the data source.
Method %OnStoreModel(pSource As %RegisteredObject) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// This callback method is called when the DataModel is saved. If
/// implemented, it is responsible for saving changes to the data source.
Method %OnSaveSource(pSource As %RegisteredObject) As %Status
{
	Quit $$$OK
}

/// Delete a given DataModel instance.<br>
/// This is implemented by the subclasses of this class.
ClassMethod %DeleteModel(pID As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// This callback method is invoked when the DataModel is deleted.
/// This is implemented by the subclasses of this class.
ClassMethod %OnDeleteModel(pID As %String) As %Status
{
	Quit $$$OK
}

/// This callback method is called when the DataModel is deleted. If
/// implemented, it is responsible for making the appropriate deletes
/// against the data source.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
	Quit $$$OK
}

/// Returns whether this data model class is readonly.
ClassMethod %IsReadOnly() As %Boolean [ CodeMode = expression ]
{
+..#READONLYMODEL
}

/// Invoke a user-defined named action on this model object.<br>
/// The actual work of perfoming the action is carried out by
/// the <method>%OnInvokeAction</method> callback method.
Method %InvokeAction(pAction As %String, pData As %String) As %Status [ Final ]
{
	Quit ..%OnInvokeAction(pAction, pData)
}

/// Invoke a user-defined named action on this model object.<br>
/// This is implemented by the subclasses of this class.
Method %OnInvokeAction(pAction As %String, pData As %String) As %Status
{
	Quit $$$OK
}

/// Internal method.<br>
/// Called by the dataController to move data into this model.
/// Copies the values in the array <var>pData</var> (subscripted by property name)
/// into this data model.
Method %CopyDataToModel(ByRef pData) As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method.<br>
/// Called by the dataController to get data from this model.
/// Copies the values in the data demo to the array <var>pData</var> (subscripted by property name).
/// <var>pTypes</var> holds type information about the properties, as needed.
Method %CopyDataFromModel(Output pData, Output pTypes) As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Return a list describing the properties within this DataModel.<br>
/// These are returned as an array of the form:<br>
/// pList(propname) = seqno<br>
/// seqno, if present, is the ordinal position of this control on the form.<br>
/// If <var>pExtended</var> is true (1), then the array will include
/// additional nodes for each property. This information is used to 
/// create dynamic forms for this model. The extra nodes may include:<br>
/// pList(name,"%type") = suggested control type for dynaForm<.br>
/// pList(name,"size") = size used for controls.<br>
/// pList(name,"group") = id of group within dynaForm to place control.<br>
/// <var>pContainer</var> is the name of the containing property if this data model
/// is embedded in another data model object.
ClassMethod %GetPropertyInfo(Output pList As %String, pExtended As %Boolean = 0, pContainer As %String = "") As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// This callback method, if present, is called by the <method>%GetPropertyInfo</method>
/// method. This gives subclasses the opportunity to add additional property
/// descriptions to the DataModel.<br>
/// <var>pIndex</var> is the number of elements (plus one) already in the list. 
/// This should be used as a starting sequence number when adding
/// new properties to the list.
ClassMethod %OnGetPropertyInfo(pIndex As %Integer, ByRef pList As %String, pExtended As %Boolean = 0) As %Status [ Abstract ]
{
}

/// Return a comma-delimited list of properties within this DataModel,
/// including any virtual properties provided by the <method>%OnGetPropertyInfo</method>
/// A property may optionally specify a type, such as "Memo:stream".
ClassMethod %GetPropertyList(pModelId As %String) As %String [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method.<br>
/// If a form connected to this DataModel is submitted, this method handles the
/// server-side processing of the submit.
ClassMethod %SubmitHandler(pSubmit As %ZEN.Submit) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// If defined, this callback is called when a form connected to this 
/// DataModel is submitted.<br>
/// The contents of this DataModel will be filled in from the submitted values
/// before this callback is invoked.
Method %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Quit $$$OK
}

}
