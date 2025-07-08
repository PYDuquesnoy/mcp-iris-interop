/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A dynaForm (dynamic form) is a specialized type of <class>form</class>
/// that displays form whose controls are drawn automatically based on
/// the contents of <class>dataController</class> associated with the form.<br/>
/// For example:<br/>
/// <example language="html">
/// <dataController id="data" modelClass="ZENMVC.Person"/>
/// <dynaForm controllerId="data" injectControls="before">
/// <button caption="Save"/>
/// </dynaForm>
/// </example>
/// In this case, a form will be displayed with controls for each of the properties
/// in the class <class>ZENMVC.Person</class>.<br/>
/// It is also possible to use dynaForm without a dataController. In
/// this case you must provide an <property>OnGetPropertyInfo</property>
/// server-side callback method to specify the list of controls to display.
Class %ZEN.Component.dynaForm Extends form [ Deprecated, System = 3 ]
{

/// If defined, this is the id of a group within this form in which
/// the dynamically created controls will be injected.
Property defaultGroupId As %ZEN.Datatype.id;

/// Specifies where in the form the automatically created controls are placed
/// relative to other controls that have been manually placed within the form:<br/>
/// <ul>
/// <li>"after" - (default) inject the automatically placed controls after any manually placed controls.</li>
/// <li>"before" - inject the automatically placed controls before any manually placed controls.</li>
/// </ul>
/// This is useful for cases where the dynaForm may define buttons and other controls
/// in addition to those that are automatically created.<br/>
/// If <property>defaultGroupId</property> is defined, then this is ignored.
Property injectControls As %ZEN.Datatype.string(VALUELIST = ",before,after") [ InitialExpression = "after" ];

/// (Optional) Name of Server-side callback method called just before
/// dynamic components are injected into this form.<br/>
/// This callback method behaves in much the same way as the
/// <method>%OnGetPropertyInfo</method> method of the <class>%ZEN.DataModel.ObjectDataModel</class> class.
/// This must be the name of a server-only method in the page
/// class that contains this form component.<br/>
/// For example:
/// <example language="cls!member">
/// Method GetInfo(pIndex As %Integer,ByRef pInfo As %String,pModelId As %String) As %Status
/// {
/// 	// subscript of pInfo is the logical name of the control
/// 	// the value of pInfo(name) is the sequence number (ordinal position of the control).
/// 	// the value of pInfo(name,"%type") is the control type to display
/// 	Set pInfo("Field1") = pIndex
/// 	Set pInfo("Field1","%type") = "textarea"
/// 	
/// 	// the value of pInfo(name,"label") is the control label to display
/// 	Set pInfo("Field2") = pIndex + 1
/// 	Set pInfo("Field2","label") = "Field 2"
/// 	Quit $$$OK
/// }
/// </example>
Property OnGetPropertyInfo As %ZEN.Datatype.delegator(FORMALSPEC = "pIndex:%Integer,&pInfo:%String,pModelId:%String", RETURNTYPE = "%Status");

/// Internal method.<br>
/// Inject additional controls into this when it is added to the page.
/// This is implemented by subclasses.
Method %InjectControls() As %Status [ Internal ]
{
	Set tSC = $$$OK

	Do {
		Set tModelId = ""
		If $IsObject(..%controller) {
			Set tModelId = ..%controller.modelId
			Set tSC = ..%controller.%GetModelPropertyInfo(.tInfo,1)
			If $$$ISERR(tSC) Quit
		}

		#; invoke callback, if present
		#; this gives the page a chance to change (or create) the model
		If (..OnGetPropertyInfo '= "") {
			#; compute index to pass to callback
			Set tIndex = 0
			Set tName = $O(tInfo(""))
			While (tName '= "") {
				Set tSeq = +$G(tInfo(tName))
				Set:tSeq=0 tSeq=1000
				Set:(tSeq>tIndex) tIndex = tSeq
				Set tName = $O(tInfo(tName))
			}
			Set tSC = ..%InvokeGetPropertyInfo(..OnGetPropertyInfo,tIndex,.tInfo,tModelId)
			If $$$ISERR(tSC) Quit
		}

		#; if not in info array, create a control for the modelId
		Set:$G(tInfo("%id"))="" tInfo("%id") = 0
		Set:'$D(tInfo("%id","%type")) tInfo("%id","%type") = "hidden"
		Set:'$D(tInfo("%id","label")) tInfo("%id","label") = "ID"
		Set:'$D(tInfo("%id","readOnly")) tInfo("%id","readOnly") = 1

		#; sort properties by sequence
		Set tName = $O(tInfo(""))
		While (tName '= "") {
			Set tSeq = +$G(tInfo(tName),1000)
			Set tSort(tSeq,tName) = ""
			Set tName = $O(tInfo(tName))
		}

		#; see if form already has components
		Set tFirstChild = ..children.GetAt(1)

		#; now create controls for each property
		Set $ZT = "LocalTrap"
		Set tSeq = $O(tSort(""))
		While (tSeq '= "") {
			Set tName = $O(tSort(tSeq,""))
			While (tName '= "") {
				Set tType = $G(tInfo(tName,"%type"))

				#; skip unsupported types
				If (tType = "") {
					Set tPType = $G(tInfo(tName,"%ptype"))
					If (tPType = $$$ZENMVCARRAY)||(tPType = $$$ZENMVCLIST)||(tPType = $$$ZENMVCBSTREAM) Goto Next
				}

				Set:tType="" tType = "text"

				#; if no package, assume type is a ZEN component
				Set:tType'["." tType="%ZEN.Component."_tType
				
				#; create component, add to form
				Set tControl = $zobjclassmethod(tType,"%New")
				If $IsObject(tControl) {
					Set tControl.id = ..id_"."_tName  // synthesize an id
					Set tControl.name = tName
					Set tControl.label = $TR(tName,"."," ")
					Set tControl.dataBinding = tName

					#; apply non-% values from tInfo
					Set k = $O(tInfo(tName,""))
					While (k'="") {
						Set:($E(k)'="%") $zobjproperty(tControl,k) = $G(tInfo(tName,k))
NextProp
						Set k = $O(tInfo(tName,k))
					}
					
					#; set dynamic flag for control
					Set tControl.dynamic = 1
					
					#; if the property defines %group, then
					#; look for a group with that id and add the control to it.

					Set tGroup = ""
					Set tGroupId = $G(tInfo(tName,"%group"),..defaultGroupId)
					If (tGroupId '= "") {
						Set tGroup = $G(tGroups(tGroupId))
						If (tGroup="") {
							#; look up group
							Set tGroup = %page.%GetComponentById(tGroupId)
						}

						If $IsObject(tGroup) {
							#; add to group and update local index
							Do tGroup.%AddChild(tControl)
							Set tGroups(tGroupId) = tGroup
						}
					}

					#; if control not added to a group, add to form
					If '$IsObject(tGroup) {
						If (..injectControls="before" && $IsObject(tFirstChild)) {
							#; insert before pre-existing controls
							Do ..%AddChildBefore(tControl,tFirstChild)
						}
						Else {
							Do ..%AddChild(tControl)
						}
					}
				}
Next
				Set tName = $O(tSort(tSeq,tName))
			}
			Set tSeq = $O(tSort(tSeq))
			Continue
LocalTrap
			#; invalid type or property for control; 
			#; create label to show error and continue
			#; ignore invalid properties...
			If ($ZE["<PROPERTY DOES NOT EXIST>") {
				Goto NextProp
			}
			Else {
				Set tControl = ##class(%ZEN.Component.label).%New()
				Set tControl.value = "ERROR: " _ $ZE
				Set tControl.dynamic = 1
				Do ..%AddChild(tControl)
			}
			Goto Next				
		}
		Set $ZT = ""
	} While(0)

	Quit tSC
}

/// Internal method.<br>
/// Invoke server-side <property>OnGetPropertyInfo</property> callback.
Method %InvokeGetPropertyInfo(pOnGetPropertyInfo As %String, pIndex As %Integer, ByRef pInfo As %String, pModelId As %String) As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (pOnGetPropertyInfo '= "")) {
		#; get array of values subscripted by control name
		Set tSC = $zobjmethod(tHost,pOnGetPropertyInfo,pIndex,.pInfo,pModelId)
		If $$$ISERR(tSC) Quit tSC
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Done
}

/// Internal method.<br>
/// This is called from the client when it needs to recreate the contents
/// of this form because the underlying DataModel has changed.
Method RecreateForm(pController As %ZEN.Auxiliary.dataController) As %Boolean [ Internal, ZenMethod ]
{
	#; remove all dynamic components from the form
	Do ..%RemoveChildren(1)

	#; get DataModel metadata via controller
	If $IsObject(pController) {
		#; connect to controller
		Set ..%controller = pController

		#; add the new controls
		Set tSC = ..%InjectControls()
		If $$$ISERR(tSC) {
			Do ##class(%ZEN.Utils).%DisplayErrorJS($this,tSC)
			Quit 0
		}
	}
	Quit 1
}

/// Notification that the dataController associated with this form
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2) [ Internal, Language = javascript ]
{
	switch(reason) {
	case 'modelChange':
		// model (meta-data) changed in dataController.
		// reload form and rebind data
		if (null != this.controller) {
			var ok = this.RecreateForm(this.controller);
		}
		break;
	default:
		return this.invokeSuper('notifyViewHandler',arguments);
	}
	return true;
}

/// Called after refreshContents,
/// make sure data is bound to the form.
ClientMethod onRefreshContents() [ Internal, Language = javascript ]
{
	this.bindValues(null,true);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'defaultGroupId':
		form[property] = value;
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
