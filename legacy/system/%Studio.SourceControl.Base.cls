/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is kept to provide an interface to the <class>%Studio.Extension.Base</class> class
/// which provides the general Studio extension interface.<p>
/// Subclass from this and implement the methods you need for your source control system.
Class %Studio.SourceControl.Base Extends %Studio.Extension.Base [ System = 4 ]
{

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="%CheckOut"/>
<MenuItem Name="%UndoCheckout"/>
<MenuItem Name="%CheckIn" Save="100"/>
<MenuItem Name="%GetLatest"/>
<MenuItem Name="%AddToSourceControl" Save="100"/>
</Menu>
<Menu Name="%SourceContext" Type="1">
<MenuItem Name="%CheckOut"/>
<MenuItem Name="%UndoCheckout"/>
<MenuItem Name="%CheckIn" Save="100"/>
<MenuItem Name="%GetLatest"/>
<MenuItem Name="%AddToSourceControl" Save="100"/>
</Menu>
</MenuBase>
}

/// Used to control which dialogs appear in Studio. If the position is '1'
/// then this dialog will appear and if it is '0' the <method>UserAction</method>
/// will be called to determine what to do. This is included for backward compatibilty.
/// The flags are:<ul>
/// <li>1 : Present dialog on check in</li>
/// <li>2 : Present dialog on check out</li>
/// <li>3 : Ask to add new item to source control</li>
/// <li>4 : Ask to remove deleted item from source control</li></ul>
Parameter Flags As STRING = 1111;

/// Check this routine/class/csp file into source control.
Method CheckIn(InternalName As %String, Description As %String = "") As %Status
{
	Quit $$$OK
}

/// Check this routine/class/csp file out of source control.
Method CheckOut(InternalName As %String, Description As %String = "") As %Status
{
	Quit $$$OK
}

/// Undo the checkout of this item.
Method UndoCheckout(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Called to add this item to source control.
Method AddToSourceControl(InternalName As %String, Description As %String = "") As %Status
{
	Quit $$$OK
}

/// Called to delete this item from source control.
Method RemoveFromSourceControl(InternalName As %String, Description As %String = "") As %Status
{
	Quit $$$OK
}

/// Get the latest version of this file from source control.
Method GetLatest(InternalName As %String) As %Status
{
	Quit $$$OK
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	#; Note if you implement this method yourself you can remove all the code below, this is just included
	#; for backward compatibility with previous versions of the source control hooks.
	#; Get deprecated Flags parameter
	Set flags=..%GetParameter("Flags")
	Set Action=0,Target="",Msg="",Reload=0
	If Type=0 {
		Set menu=$piece(Name,",")
		If menu'="%SourceMenu",menu'="%SourceContext" Quit $$$OK
		Set name=$piece(Name,",",2)
		Set action=$case(name,"%CheckIn":-1,"%CheckOut":0,"%AddToSourceControl":1,"%GetLatest":3,"%UndoCheckout":10,:-2)
		If action=-2 Quit $$$OK
	} ElseIf Type=1 {
		Set action=Name
	}
	#; Do not need source control when deleting an item that is not in source control
	If action=2,'..IsInSourceControl(InternalName) Quit $$$OK
	#; Default to displaying dialog if no Flags parameter defined as this is what previous source control did
	If action<3 {
		If flags="" {
			Set Action=1
		} Else {
			Set Action=+$extract(flags,action+2)
		}
	}
	#; If we do not want the dialog then just call the method here
	If Action=0 {
		Quit ..AfterUserAction(Type,Name,InternalName,1,,.Reload)
	} Else {
		If action>-2,action<3 {
			Set Target=$$$FormatMessage(,"%Studio",$case(action,-1:"CheckInDialog",0:"CheckOutDialog",1:"AddDialog",2:"RemoveDialog"),,InternalName)
		} Else {
			Quit $$$ERROR($$$StudioSourceActionInvalid,Name,InternalName)
		}
	}
	Quit $$$OK
}

Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Set Reload=0
	#; Note if you implement this method yourself you can remove all the code below, this is just included
	#; for backward compatibility with previous versions of the source control hooks.
	If Type=0 {
		Set menu=$piece(Name,",")
		If menu'="%SourceMenu",menu'="%SourceContext" Quit $$$OK
		Set name=$piece(Name,",",2)
		Set action=$case(name,"%CheckIn":-1,"%CheckOut":0,"%AddToSourceControl":1,"%GetLatest":3,"%UndoCheckout":10,:-2)
		If action=-2 Quit $$$ERROR($$$StudioSourceActionInvalid,Name,InternalName)
	} ElseIf Type=1 {
		Set action=Name
	}
	If Answer'=1 Quit $$$OK
	If action=-1 Quit ..CheckIn(InternalName,Msg)
	If action=0 Quit ..CheckOut(InternalName,Msg)
	If action=1 Quit ..AddToSourceControl(InternalName,Msg)
	If action=2 Quit ..RemoveFromSourceControl(InternalName,Msg)
	If action=3 Quit ..GetLatest(InternalName)
	If action=10 Set Reload=1 Quit ..UndoCheckout(InternalName)
	Quit $$$OK
}

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Set menu=$piece(MenuName,","),name=$piece(MenuName,",",2)
	If menu'="%SourceMenu",menu'="%SourceContext" Quit $$$OK
	If InternalName="" Quit $$$OK
	Set sc=..GetStatus(InternalName,.isinsourcecontrol,.editable,.ischeckedout)
	Set isinsourcecontrol=+$get(isinsourcecontrol),editable=+$get(editable),ischeckedout=+$get(ischeckedout)
	If $$$ISERR(sc) Quit sc
	If name="%CheckOut" {
		If ischeckedout||('isinsourcecontrol) Set Enabled=0
	} ElseIf name="%CheckIn" {
		If 'isinsourcecontrol||('ischeckedout) Set Enabled=0
	} ElseIf name="%UndoCheckout" {
		If 'isinsourcecontrol||('ischeckedout) Set Enabled=0
	} ElseIf name="%GetLatest" {
		If ischeckedout||('isinsourcecontrol) Set Enabled=0
	} ElseIf name="%AddToSourceControl" {
		If isinsourcecontrol||(InternalName="") Set Enabled=0
	}
	Quit $$$OK
}

/// Callback invoked when the portal-based Source Control hooks instantiate the source control class.
/// Operations that occur in this callback should be lightweight as the source control class needs to 
/// be instantiated afresh every time a source control action is performed.
Method OnPortalCreate(pUserData As %ZEN.proxyObject = "") As %Status [ CodeMode = objectgenerator ]
{
	If (%compiledclass.Name = "%Studio.SourceControl.Base") {
		Do %code.WriteLine($char(9)_"Quit $$$OK")
		Quit $$$OK
	}
	// Ensure that legacy Ensemble OnEnsembleCreate() method is called if it exists
	Set tDone = 0
	Set tOnEnsembleCreate = %compiledclass.Methods.FindObjectId(%compiledclass.Name _ "||OnEnsembleCreate")
	If (tOnEnsembleCreate) {
		Set tMethod = %compiledclass.Methods.GetAt(tOnEnsembleCreate)
		If ($IsObject(tMethod)) {
			Do %code.WriteLine($char(9)_"Quit ..OnEnsembleCreate(pUserData)")
			Set tDone = 1
		}
	}
	If ('tDone) {
		Do %code.WriteLine($char(9)_"Quit $$$OK")
	}
	Quit $$$OK
}

/// API to give developers control over the HTML environment. Used when viewing a source control popup
/// for the URL in <var>pPageURL</var> from the portal. Developers can specify the following keys in <var>pOptions</var>:
/// <ul><li>IECompatibility - set <code>pOptions("IECompatibility")</code> to 1 to permit IE compatibility
/// mode when rendering the URL. The default behaviour is to force IE to use its most recent rendering engine.</li>
/// <li>CSSLevel - set <code>pOptions("CSSLevel")</code> to 2 to force HTML 4 output, or 3 to force HTML 5 output.
/// The default behaviour is to use HTML5 output when the browser can support it. Note that the values follow the 
/// semantics for the %OnDetermineCSSLevel() callback implemented in <class>%ZEN.Component.abstractPage</class>.</li></ul>
ClassMethod GetPortalPageOptions(pPageURL As %String = "", Output pOptions As %String)
{
}

}
