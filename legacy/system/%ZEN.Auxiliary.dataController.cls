/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used to implement the Controller portion of the Zen 
/// Model-View-Controller mechanism.<br>
/// A dataController component provides a way to establish a connection between
/// a DataModel class and one or more <class>%ZEN.Component.dataView</class> components (such as a form).<br/>
/// When the data associated with the Controller changes, these changes
/// are automatically broadcast to all View components connected to the Controller.<br/>
/// For example, the following XML defines a <class>dataController</class> that
/// will open an instance of the <b>MyApp.MyModel</b> class using
/// an id value of 1. The <class>%ZEN.Component.dynaForm</class> object is bound to the 
/// <class>dataController</class> by setting its controllerId property to
/// the id of the <class>dataController</class>:
/// <example language="html">
/// <dataController id="data" modelClass="MyApp.MyModel" modelId="1"/>
/// <dynaForm id="myForm" controllerId="data"/>
/// </example>
/// In this case, the <class>%ZEN.Component.dynaForm</class> will display
/// a form with controls for every property within the Data Model.
Class %ZEN.Auxiliary.dataController Extends %ZEN.Auxiliary.abstractController [ Deprecated, System = 3 ]
{

/// Name of the DataModel class that provides data for this controller.<br/>
/// You can change this value using the client-side <method>setModelClass</method>
/// method. This will cause a new object to be loaded into the controller.
Property modelClass As %ZEN.Datatype.className(ZENEXPRESSION = 1);

/// Internal property.<br>
/// Used to hold client-side validation code.
Property validationCode As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Transient, internal property used to keep a reference to a DataModel object.
Property %model As %ZEN.DataModel.DataModel(XMLPROJECTION = "none") [ Internal ];

/// Internal method.<br>
/// Get any client-side validate code defined by the model class.
Method %GetClientValidationCode() As %Status [ Internal ]
{
	#; Get JS validation code from the DataModel class
	Set $ZT="Trap"
	Set tCode = ""
	If (..modelClass '= "") {
		Set tCode = $zobjclassmethod($$$ZENVAL(..modelClass),"%GetJSValidationCode")
	}
Done
	Set ..validationCode = tCode _ "/*"_..modelClass_"*/"
	Quit $$$OK
Trap
	#; method does not exist
	Set $ZT=""
	Set tCode = ""
	Goto Done
}

/// Internal method.<br>
/// Acquire data from the associated DataModel object.
/// This is typically called on the server before a page is served in order
/// to get initial values for bound components.
Method %AcquireData() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		Set $ZE = ""
		Set ..modelError = ""
		If '$IsObject(..%model) {
			#; open instance of model
			Set ..%model = ..%CreateModelInstance($$$ZENVAL(..modelClass),$$$ZENVAL(..modelId),.tSC,##this)
			If $$$ISERR(tSC) {
				#; get message for this error
				Set ..modelError = $System.Status.GetErrorText(tSC)
				$$$ZENLOGERROR("MVC: Error creating model instance")

				#; only report system-level errors
				If ($ZE="") {
					Set tSC = $$$OK
				}
				Else {
					Set ..%model = ""
				}
			}
			If $$$ISERR(tSC) Quit

			Set ..dataReadOnly = $S($IsObject(..%model):..%model.%IsReadOnly(),1:0)

			#; apply meta-data to dataBag
			Set tSC = ..%AcquireMetaData()
			If $$$ISERR(tSC) {
				$$$ZENLOGERROR("MVC: Error in %AcquireMetaData")
				Quit
			}

			Set tSC = ..%GetClientValidationCode()
			If $$$ISERR(tSC) {
				$$$ZENLOGERROR("MVC: Error in %GetClientValidationCode")
				Quit
			}
		}
		If $$$ISERR(tSC) Quit

		If ($IsObject(..%model)) {
			#; force our id to match our model
			Set ..modelId = ..%model.%id

			#; copy data into our databag
			Set tSC = ..dataBag.%CopyFromModel(..%model)
			If $$$ISERR(tSC) {
				$$$ZENLOGERROR("MVC: Error in %CopyFromModel")
				Quit
			}
			Set ..dataLoaded = 1
		}
		Else {
			$$$ZENLOGINFO("MVC: No model object")
			Set ..dataLoaded = 0
		}
	} While(0)
Done
	Quit tSC
}

/// Internal method.<br>
/// Acquire meta-data from the associated DataModel object.
/// This may be called before a page is rendered or in response to a
/// client-side change to a dataController.
Method %AcquireMetaData() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do {
		Set tList = ..%GetModelPropertyList(.tSC)
		If $$$ISERR(tSC) Quit
		Set tProps = ""
		Set tTypes = ""
		Set tLabels = ""
		For n = 1:1:$L(tList,",") {
			Set x = $P(tList,",",n)
			Set tProps = tProps _ $S(n=1:"",1:",") _ $P(x,":",1)
			Set tTypes = tTypes _ $S(n=1:"",1:",") _ $P(x,":",2)
			Set tLabels = tLabels _ $S(n=1:"",1:",") _ $P(x,":",3)
		}
		Do ..dataBag.%SetPropertyList(tProps,tTypes,tLabels)
	} While(0)

	Quit tSC
}

/// Internal method.
/// Create an instance of a DataModel object.
/// If <var>pID</var> is "", then this creates a new instance of model.
ClassMethod %CreateModelInstance(pClass As %String, pID As %String, Output pSC As %Status, pController As %ZEN.Auxiliary.dataController) As %ZEN.DataModel.DataModel [ Internal ]
{
	Set tModel = ""
	Set pSC = $$$OK
	Set $ZT="Trap"

	If (pClass '= "") {
		#; make this controller visible to the data model for special cases
		New %dataController
		Set %dataController = pController
		Set tModel = $zobjclassmethod(pClass,"%OpenModel",pID,,.pSC)
	}
Done
	Quit tModel
Trap
	Set $ZT=""
	Set tModel=""
	If $ZE["<METHOD DOES NOT EXIST>" {
		Set pSC=$$$ERROR($$$GeneralError,"Class "_ pClass _ " or a referenced serial class is not a DataModel")
	}
	Else {
		Set pSC=$$$ERROR($$$ObjectScriptError,"%CreateModelInstance: " _ $ZE)
	}
	Goto Done
}

/// Delete an instance of a DataModel object.
ClassMethod %DeleteModelInstance(pClass As %String, pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	If (pClass '= "") {
		Set tSC = $zobjclassmethod(pClass,"%DeleteModel",pID)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<METHOD DOES NOT EXIST>" {
		Set tSC=$$$ERROR($$$GeneralError,"Class "_ pClass _ " is not a DataModel")
	}
	Else {
		Set tSC=$$$ERROR($$$ObjectScriptError,"%DeleteModelInstance: " _ $ZE)
	}
	Goto Done
}

/// Return a comma-delimited list of the properties contained in 
/// the current DataModel class.<br>
/// A property in the list may include type and label information in the form:<br>
/// Prop:type:label
Method %GetModelPropertyList(Output pSC As %Status) As %String
{
	Set $ZT="Trap"
	Set pSC = $$$OK
	Set tList = ""
	If (..modelClass '= "") {
		Set tList = $zobjclassmethod($$$ZENVAL(..modelClass),"%GetPropertyList",$$$ZENVAL(..modelId))
	}
Done
	Quit tList
Trap
	Set $ZT=""
	Set tList = ""
	If $ZE["<METHOD DOES NOT EXIST>" {
		Set pSC=$$$ERROR($$$GeneralError,"Class "_ $$$ZENVAL(..modelClass) _ " is not a DataModel")
	}
	Else {
		Set pSC=$$$ERROR($$$ObjectScriptError,"%GetModelPropertyList: " _ $ZE)
	}
	Goto Done
}

/// Return an array containing information about the properties contained in 
/// the current DataModel.<br>
/// Refer to the <method>%GetPropertyInfo</method> of the <class>%ZEN.DataModel.DataModel</class>
/// for details.
Method %GetModelPropertyInfo(Output pInfo As %String, pExtended As %Boolean = 0) As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Do {
		If (..modelClass '= "") {
			Set tSC = $zobjclassmethod($$$ZENVAL(..modelClass),"%GetPropertyInfo",.pInfo,pExtended,$$$ZENVAL(..modelId))
			If $$$ISERR(tSC) Quit
		}
	} While(0)

Done
	Quit tSC
Trap
	Set $ZT=""
	If $ZE["<METHOD DOES NOT EXIST>" {
		Set tSC=$$$ERROR($$$GeneralError,"Class "_ $$$ZENVAL(..modelClass) _ " is not a DataModel")
	}
	Else {
		Set tSC = $$$ERROR($$$ObjectScriptError,"%GetModelPropertyInfo: " _ $ZE)
	}
	Goto Done
}

/// Save data from this dataController back to the DataModel on the server.
/// Return the id with which the model was saved or '' if it was not saved.
ClientMethod save() [ Language = javascript ]
{
	var id = '';
	this.modelError = '';
	if (this.dataLoaded && !this.isModelReadOnly()) {
		// call server to save data
		this.modelId = this.SaveToServer();
		id = this.modelId;
		// if error, it will be in modelError
		zenInvokeCallbackMethod(this.onsave,this,'onsave','id',this.modelId);

		this.sendEventToViews('dataChange');
	}

	return (''==this.modelError) ? id : '';
}

/// Load new data into this dataController from DataModel on the server.<br>
/// If <var>force</var> is true, then always load data,
/// otherwise only load data if there is no current data or
/// it has been invalidated.<br>
/// Applications should not call this directly. Instead they should use the
/// <method>setModelClass</method>, <method>setModelId</method>, or <method>update</method> methods.
ClientMethod loadModel(force) [ Internal, Language = javascript ]
{
	this.modelError = '';
	if ('' == this.modelClass) {
		this.dataLoaded = false;
		return;
	}

	if (force || !this.dataLoaded) {
		// call server to get new data
		var id = this.LoadFromServer();
		this.modelId = id;
		if ('' != this.modelError) {
			zenInvokeCallbackMethod(this.onerror,this,'onerror');
		}
	}
}

/// Internal method.<br>
/// Load data from the associated DataModel object.<br>
Method LoadFromServer() As %String [ Internal, ZenMethod ]
{
	Set tSC = $$$OK
	Set tID = ""

	Do {
		Set $ZE = ""
		Set tID = $$$ZENVAL(..modelId)

		#; open instance of model
		Set ..%model = ..%CreateModelInstance($$$ZENVAL(..modelClass),tID,.tSC,##this)
		If $$$ISERR(tSC) {
			Set ..modelError = $System.Status.GetErrorText(tSC)
			Set ..dataLoaded = 0
			Set tSC = $$$OK
		}
		Set ..dataReadOnly = $S($IsObject(..%model):..%model.%IsReadOnly(),1:0)
		Set:(..modelError="") ..dataLoaded = 1

		If $IsObject(..%model) {
			If (..modelChanged) {
				#; client needs new meta data
				Set tSC = ..%AcquireMetaData()
				If $$$ISERR(tSC) Quit

				Set ..modelChanged = 0
				Set tSC = ..%GetClientValidationCode()
				If $$$ISERR(tSC) Quit
			}
			#; fill in dataBag from DataModel
			Set tSC = ..dataBag.%CopyFromModel(..%model)
			If $$$ISERR(tSC) Quit
		}
	} While(0)

	If $$$ISERR(tSC) {
		Do:..alertOnError||($ZE'="") ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
		Set ..dataLoaded = 0
		Set tID = ""
	}

	Quit tID
}

/// Internal method.<br>
/// Save data back to the associated DataModel object.
/// Returns the id of the saved object (which could have changed
/// in the case of an insert).
Method SaveToServer() As %String [ Internal, ZenMethod ]
{
	Set tSC = $$$OK
	Set tModelId = $$$ZENVAL(..modelId)
	Set tRet = tModelId

	Do {
		Set $ZE=""
	
		#; open instance of model
		Set tModel = ..%CreateModelInstance($$$ZENVAL(..modelClass),tModelId,.tSC,##this)
		If $$$ISERR(tSC) Quit

		#; copy data to model and save model
		If $IsObject(tModel) {
			Set tSC = ..dataBag.%CopyToModel(tModel)
			If $$$ISERR(tSC) Quit

			#; save the model
			Set tSC = tModel.%SaveModel()
			If $$$ISERR(tSC) Quit

			#; model may have been modified by the save
			#; so copy new values back to client
			Set tSC = ..dataBag.%CopyFromModel(tModel)
			If $$$ISERR(tSC) Quit

			#; return the modelId (it could have changed)
			Set tRet = tModel.%id
		}
	} While(0)

	If $$$ISERR(tSC) {
		Set ..modelError = $System.Status.GetErrorText(tSC)
		Do:..alertOnError||(($ZE'="")&&($E($ZE,1,3)'="<ZS")) ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	}
	Quit tRet
}

/// Ask our associated dataModel to create a new (unsaved) instance.
ClientMethod createNewObject() [ Language = javascript ]
{
	this.modelError = '';
	this.dataLoaded = false;
	if ('' == this.modelClass) {
		return;
	}

	this.modelId = '';
	// call server to get new data
	var id = this.LoadFromServer();
	this.dataLoaded = true;
	zenInvokeCallbackMethod(this.oncreate,this,'oncreate');
	this.sendEventToViews('dataChange');
}

/// Ask our associated dataModel to delete the item with the given id.
/// Returns true if the delete was successful.
/// If the dataModel is readOnly, then the delete will not happen.
ClientMethod deleteId(id) [ Language = javascript ]
{
	this.modelError = '';
	if (this.isModelReadOnly() || '' == id) return false;
	
	// call server to delete data
	var ok = this.DeleteFromServer(id);
	zenInvokeCallbackMethod(this.ondelete,this,'ondelete','id',id,'deleted',ok);
	if (ok) {
		// test for delete of this object
		if (this.modelId == id) {
			this.modelId = '';
			this.sendEventToViews('dataChange');
		}
	}
	return ok;
}

/// Internal method.<br>
/// Ask the associated DataModel object to delete the given item.
Method DeleteFromServer(pID As %String) As %Boolean [ Internal, ZenMethod ]
{
	Set tSC = $$$OK
	Set tOK = 0

	Do {
		Set $ZE=""
		#; delete instance of model
		Set tSC = ..%DeleteModelInstance($$$ZENVAL(..modelClass),pID)
		If $$$ISERR(tSC) { Set tOK = 0 Quit }
		Set tOK = 1
	} While(0)

	If $$$ISERR(tSC) {
		Set ..modelError = $System.Status.GetErrorText(tSC)
		Do:..alertOnError||($ZE'="") ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	}
	
	Quit tOK
}

/// Internal method.<br>
/// Ask the associated DataModel object to perform the given action.
Method ExecuteAction(pAction As %String, pData As %String) As %Boolean [ Internal, ZenMethod ]
{
	Set tSC = $$$OK

	Do {
		Set $ZE = ""
		#; open instance of model
		Set tModel = ..%CreateModelInstance($$$ZENVAL(..modelClass),$$$ZENVAL(..modelId),.tSC,##this)
		If $$$ISERR(tSC) Quit
		
		#; copy client data into model
		Set tSC = ..dataBag.%CopyToModel(tModel)
		If $$$ISERR(tSC) Quit

		#; invoke the action
		Set tSC = tModel.%InvokeAction(pAction,pData)
		If $$$ISERR(tSC) Quit
		
		#; data may have been changed by the action
		Set tSC = ..dataBag.%CopyFromModel(tModel)
		If $$$ISERR(tSC) Quit
		
	} While(0)

	If $$$ISERR(tSC) {
		Set ..modelError = $System.Status.GetErrorText(tSC)
		Do:..alertOnError||($ZE'="") ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
	}
	
	Quit 1
}

/// Internal method.<br>
/// Execute client side validation code for this controller.
ClientMethod execValidationCode(property, value) [ Internal, Language = javascript ]
{
	try {
		if (this.dataLoaded && '' != this.validationCode) {
			var code = this.validationCode + '\nreturn \'\'';
			var func = new Function('property','value',code);
			return func(property,value);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in dataModel validation code.\nProperty: ' + property);
	}
	return '';
}

/// This method lets you set the values of both
/// the <property>modelClass</property> and (if provided) 
/// <property>modelId</property> properties for this controller.
/// This will cause new data to be loaded and any views connected to this controller
/// to refresh.<br>
/// This is useful in cases where both the model class and id need
/// to change as this method changes both with a single call
/// to the server.
ClientMethod setModelClass(cls, id) [ Language = javascript ]
{
	if (null!=id) {
		this.modelId = id;
	}
	this.setProperty('modelClass',cls);
}

/// Return the class name of the current model associated with this dataController.
ClientMethod getModelClass() [ Language = javascript ]
{
	return this.modelClass;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'modelClass':
		this.modelClass = value;
		this.modelChanged = true;
		this.loadModel(true);
		this.sendEventToViews('modelChange');
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
