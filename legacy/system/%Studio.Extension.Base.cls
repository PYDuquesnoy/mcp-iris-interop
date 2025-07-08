/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio extensibility superclass, this does nothing but provide interface for the real
/// extensibility classes to use. Subclass from this and implement the methods
/// you need.
Class %Studio.Extension.Base Extends %RegisteredObject [ Owner = {%Developer}, System = 4 ]
{

/// Load the optional menu information on class compile. This data is provided as an XData block in the
/// source control class called 'Menu'. The format is:<p>
/// <pre><MenuBase>
/// <Menu Name="TopLevelMenu" Type="0">
/// <MenuItem Name="NameOnMenu" Enabled="1"/>
/// <MenuItem Name="AnotherMenuItem" Enabled="1"/>
/// <MenuItem Separator="0"/>
/// <MenuItem Name="Last"/>
/// </Menu>
/// </MenuBase></pre><p>
/// By default this table will be used by the two queries <query>MainMenus</query>
/// and <query>MenuItems</query> which returns the list of menus to Studio.
Projection Menu As %Studio.Extension.Projection;

/// The username of this source control user.
Property Username As %Library.Username;

/// Version of Studio that is connecting to this server.
Property StudioVersion As %String;

/// $Job number of the main Studio process or blank if this is the main Studio connection.
/// This can be used to help co-ordinate between the jobs if Studio is using another server
/// process for things like find in files or a big compile.
Property MainJob As %String;

/// Can be set to determine if we wish to report the source control status of the document in the project window
/// or in the open dialog. This property should be set when the source control class is initialized.
/// As this can be a large number of callbacks the default is not to call the
/// <method>ItemIconState</method> method at all. Do not enable this unless the information needed is available
/// directly in InterSystems IRIS or the performance will be too slow. Values are:<ul>
/// <li>0 - Disabled</li>
/// <li>1 - Use <method>ItemIconState</method> callback in project window</li>
/// <li>2 - Use <method>ItemIconState</method> callback in open dialog window (and namespace window)</li>
/// <li>3 - Use <method>ItemIconState</method> callback everywhere</li></ul>
Property IconStatus As %Integer [ InitialExpression = 0 ];

/// If the root node is set to 1 then calls to the source control hooks will keep track if the
/// source control hook modifies the document and if it does then it will set
/// %SourceControl.Modified(docname)=1.
Property Modified As %String [ MultiDimensional ];

/// This just calls the <method>Login</method> to perform an initialisation.
/// Note that this is called by Studio automatically via the <class>%Studio.SourceControl.Interface</class>
/// class, do not call %New directly.
Method %OnNew(initval As %String) As %Status [ Final ]
{
	Set ..Username=$listget(initval)
	Set ..MainJob=$listget(initval,3),..StudioVersion=$listget(initval,4)
	Quit ..Login($listget(initval),$listget(initval,2))
}

Method %OnClose() As %Status
{
	Quit ..Logout()
}

/// Perform any login step here.
Method Login(Name As %String, Password As %String) As %Status
{
	Quit $$$OK
}

/// Perform any logout step here.
Method Logout() As %Status
{
	Quit $$$OK
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// This is called after the item is loaded but before it is sent to Studio
/// so you have a chance to modify this copy before it appears in the editor.
/// It is passed a reference to the object that represents this item so it
/// can be modified before Studio reads this information.
Method OnAfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

/// Called before the item is saved to the database it is passed
/// a reference to the current temporary storage of this item so that it
/// can be modified before the save completes. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit $$$OK
}

/// This is called if you compile a class and the compilation updates the class storage.
/// It is called after the storage has been updated so you can determine how to deal with this
/// change in the class. The <var>Location</var> is the global reference to the class definition that was changed.
Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
	Quit $$$OK
}

/// Called before the compile of the item is done.
/// It is passed a qstruct which can be inspected and modified.
Method OnBeforeCompile(InternalName As %String, ByRef qstruct As %String) As %Status
{
	Quit $$$OK
}

/// Called after the compile of the item is done.
Method OnAfterCompile(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Called in the class compiler after we have resolved the list of classes to be compiled but
/// before we have started the compile itself.
/// <var>List</var> is a subscripted array of items that will be compiled.
Method OnBeforeClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String) As %Status
{
	Quit $$$OK
}

/// Called in the class compiler after we have compiled all the classes before we exit.
/// <var>List</var> is a subscripted array of items that were compiled. <var>Status</var> is the current compile return
/// error %Status, so the callback can check if there was any error in compiling the list of classes.
Method OnAfterClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String, Status As %Status) As %Status
{
	Quit $$$OK
}

/// Called in the activated source control class before starting a compile after we have resolved the list of classes
/// but before we have started the compile itself. Note that this is a class method and it does not require the source
/// control class to be instantiated in order for it to be called. By default it will call the <method>OnBeforeClassCompile</method>
/// if there is a source control class instantiated, but you can override this to do whatever you require.
/// Returning an error here will abort the compile.
/// <var>List</var> is a subscripted array of items that will be compiled.
ClassMethod OnBeforeAllClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String) As %Status
{
	Set sc=$$$OK
	If $isobject($get(%SourceControl)) {
		Set tmp=%SourceControl New %SourceControl
		Set sc=tmp.OnBeforeClassCompile(.List,Level,.qstruct)
	}
	Quit sc
}

/// Called in the activated source control class after we have compiled all the classes but before we exit.
/// Note that this is a class method and it does not require the source
/// control class to be instantiated in order for it to be called. By default it will call the <method>OnAfterClassCompile</method>
/// if there is a source control class instantiated, but you can override this to do whatever you require.
/// <var>List</var> is a subscripted array of items that were compiled. <var>Status</var> is the current compile return
/// error %Status, so the callback can check if there was any error in compiling the list of classes.
ClassMethod OnAfterAllClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String, Status As %Status) As %Status
{
	Set sc=$$$OK
	If $isobject($get(%SourceControl)) {
		Set tmp=%SourceControl New %SourceControl
		Set sc=tmp.OnAfterClassCompile(.List,Level,.qstruct,.Status)
	}
	Quit sc
}

/// Called before an item is deleted. Returning an error code prevents the delete from occurring.
Method OnBeforeDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
	Quit $$$OK
}

/// Return information about this entity.
Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
	Set Editable=1,IsCheckedOut=0,UserCheckedOut="",IsInSourceControl=0
	Quit $$$OK
}

/// Return true if this item should be marked as read only.
/// This is called when Studio opens a document. It is set to indicate
/// that the user checked the 'read only' checkbox in the open
/// dialog in Studio.
Method IsReadOnly(InternalName As %String) As %Boolean
{
	Quit 0
}

/// Returns true if this item is in source control and false otherwise.
Method IsInSourceControl(InternalName As %String) As %Boolean
{
	Set IsInSourceControl=0
	Do ..GetStatus(InternalName,.IsInSourceControl)
	Quit IsInSourceControl
}

/// Used to allow Studio to display different icons in open dialog or project window etc.
/// Return values are:<ul>
/// <li>0 - Not in source control</li>
/// <li>1 - In source control, not checked out</li>
/// <li>2 - In source control and checked out so item is editable</li></ul>
Method ItemIconState(InternalName As %String) As %Integer
{
	Quit 0
}

/// Called before Studio checks for the timestamp of an item.
Method OnBeforeTimestamp(InternalName As %String)
{
	Quit
}

/// Convert the internal name, e.g. TEST.MAC, to an external name that is used to export
/// the routine/class/csp item. This is often a filename to write the file out to.
Method ExternalName(InternalName As %String) As %String
{
	Quit InternalName
}

/// Provide a list of the top level menu items that Studio will add when connecting to this namespace.
/// For each of these top level menus Studio will call the <query>MenuItems</query> query to obtain the items in
/// this menu when the top level menu is selected. Each top level menu has a 'Name' and a 'Type'. The
/// type is 0 for regular top level menus and 1 to specify the name of the context submenu that will
/// be added to all the context menus.<p>
/// Note that you can change the SQL statement or implement this query yourself. This is just an example
/// of where you can start.
Query MainMenus(Classname As %String) As %SQLQuery [ SqlProc ]
{
SELECT Name, Type FROM %Studio_Extension.Menu WHERE MenuBase = :Classname
}

/// This query is called by Studio when the top level menu is selected and it returns the list of items
/// that will appear on this menu. It is passed the name of the menu and the name of the current
/// document that has focus or "" if there are no documents open. The fields returned are:<ul>
/// <li>Name - Name of this menu item</li>
/// <li>Enabled - True if this menu item is enabled, false to disable this menu item</li>
/// <li>Save - Flag to see if the current document or all documents should be saved before running this item</li>
/// <li>Separator - True if this is a menu separator</li></ul>
/// Note that you can change the SQL statement or implement this query yourself. This is just an example
/// of where you can start.
Query MenuItems(Classname As %String, MenuName As %String, InternalName As %String, SelectedText As %String) As %SQLQuery [ SqlProc ]
{
SELECT MenuItem_Name, MenuItem_Enabled, MenuItem_Save, MenuItem_Separator FROM %Studio_Extension.Menu_MenuItem WHERE Menu->MenuBase = :Classname AND Menu->Name = :MenuName
}

/// This is called for every menu item returned to Studio to allow the menu to be enabled/disabled without
/// having to write a custom query for <query>MenuItems</query>. The <var>DisplayName</var> of this menu is
/// also passed by reference and this may be modified to change the appearance of this menu item. The <var>MenuName</var>
/// is the main menu name then the submenu name separated by a ','. If <var>Enabled</var> is set to -1 then it will remove
/// this menu item from the list totally, 0 will gray the menu item out, and the default 1 will display the menu item as normal.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Quit $$$OK
}

/// This is called when the user performs an action that may need to interact with
/// the server, such as selecting a menu or adding a new document. This encompases what the deprecated Flags
/// parameter did and allows additional flexibility.<p>
/// The Type argument values are:<ul>
/// <li>0 : Server defined menu item selected</li>
/// <li>1 : Other Studio action</li></ul>
/// When a menu item is selected the Name argument is the name of this menu item in the format
/// '&lt;MainMenu&gt;,&lt;SubMenu&gt;'. For other Studio actions the Name argument is one of:<ul>
/// <li>0 : User has tried to change a document that is locked in source control</li>
/// <li>1 : User has created a new document</li>
/// <li>2 : User has deleted a document</li>
/// <li>3 : User has opened a document</li>
/// <li>4 : User has closed a document</li>
/// <li>5 : User has connected to a new namespace</li>
/// <li>6 : User has selected to import comma delimetered list of documents</li>
/// <li>7 : User has saved a new document for the first time</li></ul>
/// The InternalName argument is the name of the document about which this action occurs.
/// If there is any selected text in the document which has focus this is sent in the SelectedText
/// argument.
/// The Action argument is set by this method to tell Studio what to do. Possible return
/// values for this are:<ul>
/// <li>0 : Do nothing, note that this method can still perform some action such as check
/// an item out of source control, but Studio will not ask for user input.</li>
/// <li>1 : Display the default Studio dialog with a yes/no/cancel button.
/// The text for this dialog is provided in the 'Target' return argument.</li>
/// <li>2 - Run a CSP page/Template. The Target is the full url to the CSP page/Template, as usual the page will be
/// passed the current document name, any selected text, the project name, the namespace.</li>
/// <li>3 - Run an EXE on the client. The Target is the name of an executable file on the client machine.
/// It is the responsibility of the customer to ensure this EXE is installed in a suitable location.</li>
/// <li>4 - Insert the text in Target in the current document at the current selection point.</li>
/// <li>5 - Studio will open the documents listed in Target. If there are multiple documents to open they
/// will be separated with commas. If the document name is 'test.mac:label+10' it will open the document
/// 'test.mac' and goto 'label+10'.</li>
/// <li>6 - Display an alert dialog in Studio with the text from the Target variable.</li>
/// <li>7 - Display a dialog with a textbox and Yes/No/Cancel buttons. The text for this dialog is
/// provided by the 'Target' return argument. The initial text for the textbox is provided by the 
/// 'Msg' return argument.</li></ul>
/// If the <var>Reload</var> argument is set to true then the current document will be reloaded in Studio.
/// This is useful if you change the document to change its attribute so Studio will pick up these changes.
Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	Set Action=0,Target="",Reload=0
	Quit $$$OK
}

/// This is called after the <method>UserAction</method> and after any template is run or dialog is displayed.
/// For a list of input arguments see <method>UserAction</method>.
/// In the case of the dialog the button pushed by the user is passed in Answer:<ul>
/// <li>0 - No</li>
/// <li>1 - Yes</li>
/// <li>2 - Cancel</li></ul>
/// For the dialog that contains a textbox field the text of this field is passed in 'Msg' argument.
/// In the case of a template if the template was closed from the 'x' button then Answer=2 to indicate
/// the user attempted to cancel the operation. Otherwise if the template closed normally by getting
/// to the end Answer=1.
/// For the cases where Studio did not perform any interaction this method is not called.
/// The default implementation is to call the standard source control tags .
/// If the <var>Reload</var> argument is set to true by this method then the current document will be reloaded in Studio.
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Set Reload=0
	Quit $$$OK
}

/// Return 1 if you wish this item to appear as if it is 'generated' when opened in Studio,
/// return 0 to force this item not to appear as 'generated' and return "" to use normal processing.
ClassMethod IsGenerated(Name As %String) As %String
{
	Quit ""
}

}
