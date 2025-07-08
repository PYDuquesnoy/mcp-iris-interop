/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the base class for the various data controller components
/// used to implement the Controller portion of the Zen 
/// Model-View-Controller mechanism.<br>
Class %ZEN.Auxiliary.abstractController Extends %ZEN.Component.component [ Abstract, Deprecated, System = 3 ]
{

Parameter SYSMODULE = "mvc";

/// This component is not visible.
Parameter DEFAULTVISIBLE = 0;

/// ID value passed to the DataModel class.<br/>
/// You can change this value using the client-side <method>setModelId</method>
/// method. This will cause a new object to be loaded into the controller.
Property modelId As %ZEN.Datatype.string(ZENEXPRESSION = 1) [ Final ];

/// Optional. If a DataModel has multiple dataSeries, then this specifies
/// which DataSeries (1-based) should be used to provide values to DataViews that
/// can only display values from one data series (such as a form).
Property defaultSeries As %ZEN.Datatype.integer(MINVAL = 1) [ Final, InitialExpression = 1 ];

/// onnotifyController event handler:
/// This event is fired when a dataView connected to this dataController
/// raises an event.
Property onnotifyController As %ZEN.Datatype.eventHandler [ Final ];

/// onsave event handler:
/// This event is fired when the <method>save</method> method is called.
/// The parameter, <var>id</var> is passed to the event handler and
/// contains the current model id.
Property onsave As %ZEN.Datatype.eventHandler [ Final ];

/// ondelete event handler:
/// This event is fired when the <method>deleteId</method> method is called.
/// The parameter, <var>id</var> is passed to the event handler and
/// contains id of the deleted object.
Property ondelete As %ZEN.Datatype.eventHandler [ Final ];

/// oncreate event handler:
/// This event is fired when the <method>createNewObject</method> method is called.
Property oncreate As %ZEN.Datatype.eventHandler [ Final ];

/// onerror event handler:
/// This event is fired when the dataController attempts to open an instance
/// of a DataModel and encounters an error.<br>
/// The error message can be found in <property>modelError</property>.
Property onerror As %ZEN.Datatype.eventHandler [ Final ];

/// Most recent error message reported by the DataModel object this
/// dataController is connected to.
/// This is set to a non-empty string after a save, load, or delete operation
/// encounters an error.
Property modelError As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Final ];

/// Setting this to a non-zero value will turn on autoRefresh mode
/// for this dataController. The dataController will reload its
/// data from the server at the periodic interval specified by this
/// property (in milliseconds).<br>
/// This is provided as a convenience for dataController used to drive
/// dashboards or charts; it is of limited use for forms.<br>
/// Setting this to 0 will disable autoRefresh mode.
Property autoRefresh As %ZEN.Datatype.integer(MINVAL = 0) [ Final ];

/// If true, this data controller is read only regardless of whether its
/// corresponding data model is read only or not.
Property readOnly As %ZEN.Datatype.boolean [ Final, InitialExpression = 0 ];

/// If true (the default), then the dataController will display an alert
/// box when it encounters errors invoking server-side functions (such
/// as when saving or deleting).
Property alertOnError As %ZEN.Datatype.boolean [ Final, InitialExpression = 1 ];

/// Internal: id of client-side timer object
Property timerid As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Final, Internal ];

/// Internal property.<br>
/// dataBag used to hold values.
Property dataBag As %ZEN.Auxiliary.dataBag(XMLPROJECTION = "none", ZENSETTING = 0) [ Final, Internal ];

/// Internal property.<br>
/// If true, this controller has loaded data from its model.
Property dataLoaded As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ Final, InitialExpression = 0, Internal ];

/// Internal property.<br>
/// Used to track whether the current model is readonly or not.
/// Use <property>readOnly</property> if you want to set this data controller to be read only.
Property dataReadOnly As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ Final, Internal ];

/// Internal property.<br>
/// If true, client requires updated meta-data from its model.
Property modelChanged As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ Final, InitialExpression = 1, Internal ];

/// Optional. Additional criteria from the client.<br/>
/// This is a proxy object whose contents may be filled by client application code and
/// is available to methods of the controller object.
Property criteria As %ZEN.proxyObject(XMLPROJECTION = "none") [ Internal ];

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; make sure we have a dataBag property
	Set ..dataBag = ##class(%ZEN.Auxiliary.dataBag).%New()
	Do:$IsObject($G(%page)) %page.%AddComponent(..dataBag)
	Quit $$$OK
}

/// Internal method.<br>
/// Acquire data from the associated DataModel object.
/// This is typically called on the server before a page is served in order
/// to get initial values for bound components.
Method %AcquireData() As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method.<br>
/// Acquire meta-data from the associated DataModel object.
/// This may be called before a page is rendered or in response to a
/// client-side change to a dataController.
Method %AcquireMetaData() As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method.
/// Create an instance of a DataModel object.
/// If <var>pID</var> is "", then this creates a new instance of model.
ClassMethod %CreateModelInstance(pClass As %String, pID As %String, Output pSC As %Status, pController As %ZEN.Auxiliary.dataController) As %ZEN.DataModel.DataModel [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Delete an instance of a DataModel object.
ClassMethod %DeleteModelInstance(pClass As %String, pID As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Return a comma-delimited list of the properties contained in 
/// the current DataModel class.<br>
/// A property in the list may include type and label information in the form:<br>
/// Prop:type:label
Method %GetModelPropertyList(Output pSC As %Status) As %String
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Return an array containing information about the properties contained in 
/// the current DataModel.<br>
/// Refer to the <method>%GetPropertyInfo</method> of the <class>%ZEN.DataModel.DataModel</class>
/// for details.
Method %GetModelPropertyInfo(Output pInfo As %String, pExtended As %Boolean = 0) As %Status [ Internal ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Get a data value, by property name, from this dataController.
Method %GetDataByName(pProperty As %String) [ CodeMode = expression ]
{
$Case(pProperty,"%id":$$$ZENVAL(..modelId),"%series":..defaultSeries,:..dataBag.%GetValue(pProperty,..defaultSeries))
}

/// Get a data type, by property name, from this dataController.
Method %GetTypeByName(pProperty As %String) [ CodeMode = expression ]
{
..dataBag.%GetType(pProperty)
}

/// Set a data value, by property name, into this dataController.
Method %SetDataByName(pProperty As %String, pValue As %String)
{
	Do:((pProperty'="%id")&&(pProperty'="%series")) ..dataBag.%SetValue(pProperty,pValue)
}

/// Internal method.<br>
/// Establish a connection between this dataController and a dataView component
ClientMethod register(component) [ Final, Internal, Language = javascript ]
{
	if (null == this._listeners) {
		this._listeners = new Array();
	}

	this._listeners[this._listeners.length] = component;
}

/// Internal method.<br>
/// Break the a connection between this dataController and a dataView component
ClientMethod unregister(component) [ Final, Internal, Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			if (this._listeners[this._listeners.length] == component) {
				this._listeners.splice(n,1);
				break;
			}
		}
	}
}

/// Internal method.<br>
/// This is called by a dataView listener component to notify 
/// this dataController of an event.
/// <var>source</var> is the dataView that sent the event.<br>
/// <var>reason</var> is the name of the event.<br>
/// <var>data1</var>,<var>data2</var>, and <var>data3</var> contain event-specific data passed along with the event.<br>
ClientMethod notifyController(source, reason, data1, data2, data3) [ Final, Internal, Language = javascript ]
{
	// invoke user callback
	var ret = true;
	if (this.onnotifyController) {
		ret = zenInvokeCallbackMethod(this.onnotifyController,this,'onnotifyController','reason',reason,'data1',data1,'data2',data2);
	}

	if (ret) {
		switch (reason) {
		case 'propertyChange':
			// dataView has changed a property value (property,value)
			// update our data and pass this along to other listeners
			// data1 is the property name, data2 is the value, data3 is the series #
			this.setDataByName(data1,data2,data3);
			this.sendEventToViews('dataChange',source,data1,data2,data3);
			break;
		}
	}
}

/// Send an event to all listeners (dataViews) connected to this dataController.
/// <var>reason</var> is the name of the event.<br>
/// <var>source</var>, if not null, if the dataView that raised the event.<br>
/// <var>data1</var>,<var>data2</var>, and <var>data3</var> contain event-specific data passed along with the event.<br>
ClientMethod sendEventToViews(reason, source, data1, data2, data3) [ Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			if (this._listeners[n] && (this._listeners[n]!=source)) {
				this._listeners[n].notifyView(reason,data1,data2,data3);
			}
		}
	}
}

/// Send notification to listeners that the data associated with this dataController has
/// changed.<br>
/// Any dataController methods that change data should call this to notify listeners.
ClientMethod raiseDataChange() [ Language = javascript ]
{
	if (this._listeners) {
		for (var n = 0; n < this._listeners.length; n++) {
			if (this._listeners[n]) {
				this._listeners[n].notifyView('dataChange',null);
			}
		}
	}
}

/// Return true if this controller currently contains data loaded from a DataModel.
ClientMethod hasData() [ Language = javascript ]
{
	return this.dataLoaded;
}

/// Save data from this dataController back to the DataModel on the server.
/// Return the id with which the model was saved or '' if it was not saved.
ClientMethod save() [ Language = javascript ]
{
	return '';
}

/// Reload the data in the dataController from the server.
ClientMethod update() [ Language = javascript ]
{
	this.loadModel(true);
	this.sendEventToViews('dataChange');
}

/// Load new data into this dataController from DataModel on the server.<br>
/// If <var>force</var> is true, then always load data,
/// otherwise only load data if there is no current data or
/// it has been invalidated.<br>
/// Applications should not call this directly. Instead they should use the
/// <method>setModelClass</method>, <method>setModelId</method>, or <method>update</method> methods.
ClientMethod loadModel(force) [ Internal, Language = javascript ]
{
}

/// Internal method.<br>
/// Load data from the associated DataModel object.<br>
Method LoadFromServer() As %String [ Internal, ZenMethod ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Internal method.<br>
/// Save data back to the associated DataModel object.
/// Returns the id of the saved object (which could have changed
/// in the case of an insert).
Method SaveToServer() As %String [ Internal, ZenMethod ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Ask our associated dataModel to create a new (unsaved) instance.
ClientMethod createNewObject() [ Language = javascript ]
{
}

/// Ask our associated dataModel to delete the item with the given id.
/// Returns true if the delete was successful.
/// If the dataModel is readOnly, then the delete will not happen.
ClientMethod deleteId(id) [ Language = javascript ]
{
	return false;
}

/// Internal method.<br>
/// Ask the associated DataModel object to delete the given item.
Method DeleteFromServer(pID As %String) As %Boolean [ Internal, ZenMethod ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Invoke a named <i>action</i> on our associated dataModel.
/// An action is an arbitrary operation that is defined by a 
/// specific dataModel class.
/// <var>data</var> is an arbitary value passed along with the action.
ClientMethod invokeAction(action, data) [ Language = javascript ]
{
	// call server to perform the action
	this.modelError = '';
	var ok = this.ExecuteAction(action,data);
	return(this.modelError == '');
}

/// Internal method.<br>
/// Ask the associated DataModel object to perform the given action.
Method ExecuteAction(pAction As %String, pData As %String) As %Boolean [ Internal, ZenMethod ]
{
	Set tSC = $$$ERROR($$$NotImplemented)
	Set ..modelError = $System.Status.GetErrorText(tSC)
	Do:..alertOnError||($ZE'="") ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	Quit 0
}

/// Test if the current data model is read-only. 
ClientMethod isModelReadOnly() [ Language = javascript ]
{
	return this.dataReadOnly || this.readOnly;
}

/// Return the latest error message encountered by this data controller.
/// Call this after a save, load, or delete operation to test if an error
/// occurred.<br>
/// This will return '' if there is no current error.
ClientMethod getError() [ Language = javascript ]
{
	return this.modelError;
}

/// Test if a given value for a property is valid.
ClientMethod isPropertyValid(property, value) [ Language = javascript ]
{
	var msg = '';
	msg = this.execValidationCode(property, value);
	return msg;
}

/// Internal method.<br>
/// Execute client side validation code for this controller.
ClientMethod execValidationCode(property, value) [ Internal, Language = javascript ]
{
	return '';
}

/// Get the type code for a property given its name.
ClientMethod getTypeByName(property) [ Language = javascript ]
{
	var type = '';
	if (this.dataLoaded) {
		var n = this.dataBag.getPropertyIndex(property);
		if (n >= 0) {
			type = this.dataBag.getPropertyType(n);
		}
	}
	return type;
}

/// dataBag API
/// Get a data value, by property name, from this dataController.
ClientMethod getDataByName(property, series) [ Language = javascript ]
{
	if (this.dataLoaded) {
		series = ('undefined'==typeof series) ? (this.defaultSeries-1) : parseInt(series,10);
		switch(property) {
		case '%id':
			return this.modelId;
		case '%series':
			return this.defaultSeries;
		default:
			return this.dataBag.getValue(property,series);
		}
	}
	
	return null;
}

/// Given a 0-based index, return the corresponding property name.
ClientMethod getPropertyName(n) [ Language = javascript ]
{
	return this.dataBag.getPropertyName(n);
}

/// dataBag API
/// Set a data value, by property name, into this dataController.<br>
/// If <var>property</var> is "%id", then change the id of this controller.<br>
/// If <var>property</var> is "%series", then change the defaultSeries of this controller.
ClientMethod setDataByName(property, value, series) [ Language = javascript ]
{
	switch(property) {
	case '%id':
		this.setModelId(value);
		break;
	case '%series':
		this.setProperty('defaultSeries',value);
		break;
	default:
		// series is 1-based--convert to 0-based.
		this.dataBag.setValue(property,value,(null==series) ? (this.defaultSeries-1) : (series-1));
		break;
	}
}

/// dataSet API
/// Return the number of items in the specified dimension
/// (<var>dim</var> is 1,2, or 3).
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	return this.dataBag.getDimSize(dim);
}

/// dataSet API
/// Return number of dimensions within the dataModel.
/// There are 2 dimensions: The first is the set of properties,
/// the second has a typical size of 1.<br>
/// The second dimension
/// may be larger than 1 in cases where the model serves multiple
/// series for a given model instance. (Such as when providing mulitple
/// data series for charts).
ClientMethod getDimensions() [ Language = javascript ]
{
	return 2;
}

/// dataSet API
/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	switch (dim) {
	case 1:
		return this.dataBag.getPropertyLabel(n);
	case 2:	
		return this.dataBag.getSeriesLabel(n);
	}
	return '';
}

/// dataSet API
/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	if (!this.dataLoaded) {
		return null;
	}
	return this.dataBag.getValueByPosition(parseInt(d1,10),(null==d2) ? 1 : parseInt(d2,10));
}

/// This is a specialized variant of <method>getData</method> that
/// return the data in this controller as an array of arrays (used
/// by charts).
ClientMethod getDataAsArrays() [ Language = javascript ]
{
	if (!this.dataLoaded) {
		return null;
	}
	return this.dataBag.getValuesAsArrays();
}

/// This is a specialized variant of <method>getData</method> that
/// returns the data in this controller as a zenProxy object (associative array).<br/>
/// The return value of this object is a zenProxy object
/// with properties that correspond to the properties of the current
/// Data Model object. The value of each property in the returned
/// object corresponds to the value in the Data Model object.<br/>
/// If the Data Model supports more than one data series, then
/// the <var>series</var> parameter (0-based) specifies which
/// series to use (the default is series 0).<br/>
/// Refer to the <class>%ZEN.proxyObject</class> for more details.
ClientMethod getDataAsObject(series) [ Language = javascript ]
{
	if (!this.dataLoaded) {
		return null;
	}
	series = (null==series) ? 0 : series;
	return this.dataBag.getValuesAsObject(series);
}

/// dataSet API
/// Set the data contained in the specified location.
/// Location is 0-based;
ClientMethod setData(value, d1, d2, d3) [ Language = javascript ]
{
	if (this.dataLoaded) {
		this.dataBag.setValueByPosition(value,parseInt(d1,10),(null==d2) ? 1 : parseInt(d2,10));
	}
}

/// Set the value of the <property>modelId</property> property for this controller.
/// This will cause new data to be loaded and any views connected to this controller
/// to refresh.<br>
/// This is equivalent to calling setProperty('modelId',id) and is defined for
/// convenience.
ClientMethod setModelId(id) [ Language = javascript ]
{
	this.setProperty('modelId',id);
}

/// Return the current model id associated with this dataController.
ClientMethod getModelId() [ Language = javascript ]
{
	return this.modelId;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'modelId':
		this.modelId = value;
		this.loadModel(true);
		this.sendEventToViews('dataChange');
		break;
	case 'alertOnError':
		this.alertOnError = value ? true : false;
		break;
	case 'readOnly':
		this.readOnly = value ? true : false;
		this.sendEventToViews('dataChange');
		break;
	case 'defaultSeries':
		this.defaultSeries = parseInt(value,10);
		this.sendEventToViews('seriesChange');
		break;
	case 'autoRefresh':
		this.autoRefresh = parseInt(value,10);
		this.startAutoRefresh();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// if there is an error, raise event
	if ('' != this.modelError) {
		zenInvokeCallbackMethod(this.onerror,this,'onerror');
	}
	this.startAutoRefresh();
}

/// This client method, if present, is called when this component is
/// removed from the page.
ClientMethod onDelete() [ Language = javascript ]
{
	this.clearAutoRefresh();
}

/// Internal method. Start autoRefresh timer.
ClientMethod startAutoRefresh() [ Final, Internal, Language = javascript ]
{
	this.clearAutoRefresh();
	if (0 != this.autoRefresh) {
		this.timerid = window.setTimeout('zenPage.getComponent('+this.index+').autoRefreshHandler();',this.autoRefresh);
	}
}

/// Internal method. Event handler for the autoRefresh timer.
ClientMethod autoRefreshHandler() [ Final, Internal, Language = javascript ]
{
	this.update();

	// restart
	this.startAutoRefresh();
}

/// Internal method. Clear the autoRefresh timer.
ClientMethod clearAutoRefresh() [ Final, Internal, Language = javascript ]
{
	if (this.timerid) {
		window.clearTimeout(this.timerid);
		this.timerid = null;
	}
}

}
