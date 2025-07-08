/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This abstract class defines the common interface needed
/// by dataView components (the View part of the Model-View-Controller
/// architecture).
Class %ZEN.Component.dataView [ Abstract, Deprecated, System = 3 ]
{

/// Optional. The id of the <class>%ZEN.Auxiliary.dataController</class> object that
/// provides data for this dataView component.<br>
/// If provided, this must be the valid id of a <class>%ZEN.Auxiliary.dataController</class> object.
Property controllerId As %ZEN.Datatype.id(COMPONENTTYPE = "dataController");

/// Internal property.<br>
/// Used by client to hold a reference to the associated <class>%ZEN.Auxiliary.dataController</class> object.
Property controller As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// onnotifyView event handler:
/// This event is fired when a dataController connected to this dataView
/// raises an event.
Property onnotifyView As %ZEN.Datatype.eventHandler;

/// Internal property.<br>
/// Used by server to hold a reference to the associated dataController object.
Property %controller As %ZEN.Auxiliary.dataController(XMLPROJECTION = "none");

/// ongetcontroller event handler:<br/>
/// If defined, this provides a way to supply a custom data 
/// controller. This event handler should return an object that implements the controller API.
/// This is an internal setting.<br/>
/// The main API methods that need to be implemented are getDimSize, getLabel, getData,
/// getPropertyName, and notifyController.
Property ongetcontroller As %ZEN.Datatype.eventHandler [ Internal ];

/// Server-side method used by dataView implementation classes to
/// get values from the associated dataController, if present.
/// This is typically called by components on the server before they
/// are initially rendered in order to get initial data values.
Method %AcquireDataFromController() As %Status [ Private ]
{
	Set tSC = $$$OK

	Do {
		#; connect to dataController, if present
		If (..controllerId '= "") {
			#; find dataController component
			If $IsObject(..composite) {
				Set ..%controller = ..composite.%GetChildById(..controllerId)
			}
			Else {
				Set ..%controller = %page.%GetComponentById(..controllerId)
			}
			If $IsObject(..%controller) {
				#; tell dataController to acquire data
				Set tSC = ..%controller.%AcquireData()
				If $$$ISERR(tSC) Quit
			}
		}
	} While(0)
	Quit tSC
}

/// Get the dataController component associated with this dataView, if present.
/// Returns null if no there is no controller.
/// This is used by dataView implementation classes.
ClientMethod getController() [ Language = javascript ]
{
	if (this.ongetcontroller) {
		return zenInvokeCallbackMethod(this.ongetcontroller,this,'ongetcontroller','view',this);
	}
	return (null == this.controller || '' == this.controller) ? null : this.controller;
}

/// If connected, send an event to a dataController.
/// This is used by dataView implementation classes.
/// Possible values of <var>reason</var> include:<br>
/// 'propertyChange' - <var>data1</var> is property name,<var>data2</var> is the new value,<var>data3</var> is the series number (if applicable). 
ClientMethod sendEventToController(reason, data1, data2, data3) [ Language = javascript ]
{
	// if we have a dataController, notify it of the change
	var controller = this.getController();
	if (controller && controller.notifyController) {
		controller.notifyController(this,reason,data1,data2,data3);
	}
}

/// Set the controller id for this dataView and establish a connection
/// to the new controller.
/// This is used by dataView implementation classes.
ClientMethod setControllerId(id) [ Language = javascript ]
{
	this.disconnectFromController();
	this.controllerId = id;
	this.connectToController();
}

/// Internal method.
/// Establish a connection between this dataView and its associated
/// dataController.
ClientMethod connectToController() [ Internal, Language = javascript ]
{
	this.controller = '';
	if (!zenIsMissing(this.controllerId)) {
		if (this.composite) {
			this.controller = this.composite.getChildById(this.controllerId);
		}
		else {
			this.controller = zenPage.getComponentById(this.controllerId);
		}
		if (this.controller && this.controller.register) {
			this.controller.register(this);
		}
		else {
			alert('ZEN: Unable to connect component to dataController (' + this.id + ').');
		}

		if (this.controller) {
			// make sure data is loaded
			if ('' == this.controller.modelError) {
				this.controller.loadModel(false);
			}
		}
	}
}

/// Internal method.
/// Break the connection between this dataView and its associated
/// dataController.
ClientMethod disconnectFromController() [ Internal, Language = javascript ]
{
	if (this.controller && this.controller.unregister) {
		this.controller.unregister(this);
	}

	this.controller = '';
}

/// Internal method.
/// This is called by the dataController associated with this dataView
/// when it sends an event to this dataView.<br>
/// It passes selected events on to an <method>notifyViewHandler</method> method implemented
/// by the actual dataView class.
/// Known events:<br>
/// 'modelChange': Meta-data for model has changed.<br>
/// 'dataChange': Data for model has changed. <var>data1</var> is the
/// name of the changed property or null if all properties have changed.<br>
/// 'seriesChange': the default series for the controller has changed.<br>
ClientMethod notifyView(reason, data1, data2, data3) [ Internal, Language = javascript ]
{
	// invoke user callback
	var ret = true;
	if (this.onnotifyView) {
		ret = zenInvokeCallbackMethod(this.onnotifyView,this,'onnotifyEvent','reason',reason,'data1',data1,'data2',data2,'data3',data3);
	}

	// pass event on
	if (ret && this.notifyViewHandler) {
		this.notifyViewHandler(reason,data1,data2,data3);
	}
}

}
