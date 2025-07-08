/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <P>This class is intended to demonstrate that source control hooks are called on the server
/// when corresponding actions are peformed in Atelier. Enabling this class in the managment
/// portal will write diagnostic information to the Atelier console during events, such as
/// save, compile, etc. Note that the methods in section <B>'Menu Items'</B> here are included for completeness,
/// in reality only those methods in the section marked <B>'Events'</B> will be called.</P>
/// <P>Users wishing to take advantage of server side source control hooks with Atelier should
/// subclass %Studio.SourceControl.Base directly.</P>
Class %Atelier.SourceControl Extends %Studio.SourceControl.Base
{

/// This aids in identifying the hook output amongst other console output
Parameter PREFIX = "*** Atelier Source Control Hook *** ";

/// Check this routine/class/csp file into source control.
Method CheckIn(InternalName As %String, Description As %String = "") As %Status
{
    Write !,..#PREFIX,"CheckIn ",$Get(InternalName)," ",$Get(Description),!
    Quit $$$OK
}

/// Check this routine/class/csp file out of source control.
Method CheckOut(InternalName As %String, Description As %String = "") As %Status
{
    Write !,..#PREFIX,"CheckOut ",$Get(InternalName)," ",$Get(Description),!
    Quit $$$OK
}

/// Undo the checkout of this item.
Method UndoCheckout(InternalName As %String) As %Status
{
    Write !,..#PREFIX,"UndoCheckOut ",$Get(InternalName),!
    Quit $$$OK
}

/// Called to add this item to source control
Method AddToSourceControl(InternalName As %String, Description As %String = "") As %Status
{
   Write !,..#PREFIX,"AddToSourceControl ",$Get(InternalName)," ",$Get(Description),!
    Quit $$$OK
}

/// Called to delete this item from source control
Method RemoveFromSourceControl(InternalName As %String, Description As %String = "") As %Status
{
    Write !,..#PREFIX,"RemoveFromSourceControl ",$Get(InternalName)," ",$Get(Description),!
    Quit $$$OK
}

/// Get the latest version of this file from source control.
Method GetLatest(InternalName As %String) As %Status
{
    Write !,..#PREFIX,"GetLatest ",$Get(InternalName),!
    Quit $$$OK
}

/// Called before the item is saved to the database it is passed
/// a reference to the current temporary storage of this item so that it
/// can be modified before the save completes. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    Write !,..#PREFIX,"OnBeforeSave ",$Get(InternalName)," ",$Get(Location)," ",$Get(Object),!
    
    #; Modify the document comment (for classes only)
    If $zcvt($Piece(InternalName,".",*),"U")="CLS" {
        Set @Location@(4)="Updated at "_$zdt($zts)
        If $Get(..Modified) {
            #; If the client wants to be notified of modifications, tell them
            Set ..Modified(InternalName)=1
        }
    }
    
    Quit $$$OK
}

/// Called in the activated source control class after we have compiled all the classes but before we exit.
/// Note that this is a class method and it does not require the source
/// control class to be instanciated in order for it to be called. By default it will call the <method>OnAfterClassCompile</method>
/// if there is a source control class instanciated, but you can override this to do whatever you require.
/// <var>List</var> is a subscripted array of items that were compiled. <var>Status</var> is the current compile return
/// error %Status, so the callback can check if there was any error in compiling the list of classes.
ClassMethod OnAfterAllClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String, Status As %Status) As %Status
{
    Write !,..#PREFIX,"OnAfterAllClassCompile ",$Get(List)," ",$Get(Level)," ",$Get(qstruct)," ",$Get(Status),!
    Set sc=$$$OK
    If $isobject($get(%SourceControl)) {
        Set tmp=%SourceControl New %SourceControl
        Set sc=tmp.OnAfterClassCompile(.List,Level,.qstruct,.Status)
    }
    Quit sc
}

/// Called in the class compiler after we have compiled all the classes before we exit
/// <var>List</var> is a subscripted array of items that were compiled. <var>Status</var> is the current compile return
/// error %Status, so the callback can check if there was any error in compiling the list of classes.
Method OnAfterClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String, Status As %Status) As %Status
{
    Write !,..#PREFIX,"OnAfterClassCompile ",$Get(List)," ",$Get(Level)," ",$Get(qstruct)," ",$Get(Status),!
    Quit $$$OK
}

/// Called after the compile of the item is done.
Method OnAfterCompile(InternalName As %String) As %Status
{
    Write !,..#PREFIX,"OnAfterCompile ",$Get(InternalName),!
    Quit $$$OK
}

/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
    Write !,..#PREFIX,"OnAfterDelete ",$Get(InternalName),!
    Quit $$$OK
}

/// This is called after the item is loaded but before it is sent to Studio
/// so you have a chance to modify this copy before it appears in the editor.
/// It is passed a reference to the object that represents this item so it
/// can be modified before Studio reads this information.
Method OnAfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    Write !,..#PREFIX,"OnAfterLoad ",$Get(InternalName)," ",$Get(Object),!
    Quit $$$OK
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    Write !,..#PREFIX,"OnAfterSave ",$Get(InternalName)," ",$Get(Object),!
    Quit $$$OK
}

/// This is called if you compile a class and the compilation updates the classes storage.
/// It is called after the storage has been updated so you can determine how to deal with this
/// change in the class. The <var>Location</var> is the global reference to the class definition that was changed.
Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
    Write !,..#PREFIX,"OnAfterStorage ",$Get(InternalName)," ",$Get(Location),!
    Quit $$$OK
}

/// Called in the activated source control class before starting a compile after we have resolved the list of classes
/// but before we have started the compile itself. Note that this is a class method and it does not require the source
/// control class to be instanciated in order for it to be called. By default it will call the <method>OnBeforeClassCompile</method>
/// if there is a source control class instanciated, but you can override this to do whatever you require.
/// Returning an error here will abort the compile.
/// <var>List</var> is a subscripted array of items that will be compiled.
ClassMethod OnBeforeAllClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String) As %Status
{
    Write !,..#PREFIX,"OnBeforeAllClassCompile ",$Get(List)," ",$Get(Level)," ",$get(qstruct),!
    Set sc=$$$OK
    If $isobject($get(%SourceControl)) {
        Set tmp=%SourceControl New %SourceControl
        Set sc=tmp.OnBeforeClassCompile(.List,Level,.qstruct)
    }
    Quit sc
}

/// Called in the class compiler after we have resolved the list of classes to be compiled but
/// before we have started the compile itself.
/// <var>List</var> is a subscripted array of items that will be compiled.
Method OnBeforeClassCompile(List As %String, Level As %Integer, ByRef qstruct As %String) As %Status
{
    Write !,..#PREFIX,"OnBeforeClassCompile ",$Get(List)," ",$Get(Level)," ",$get(qstruct),!
    Quit $$$OK
}

/// Called before the compile of the item is done.
/// It is passed a qstruct which can be inspected and modified.
Method OnBeforeCompile(InternalName As %String, ByRef qstruct As %String) As %Status
{
    Write !,..#PREFIX,"OnBeforeCompile ",$Get(InternalName)," ",$get(qstruct),!
    Quit $$$OK
}

/// Called before an item is deleted. Returning an error code prevents the delete from occurring.
Method OnBeforeDelete(InternalName As %String) As %Status
{
   Write !,..#PREFIX,"OnBeforeDelete ",$Get(InternalName),!
    Quit $$$OK
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
    Write !,..#PREFIX,"OnBeforeLoad ",$Get(InternalName),!
    Quit $$$OK
}

/// Called before Studio checks for the timestamp of an item.
Method OnBeforeTimestamp(InternalName As %String)
{
    Write !,..#PREFIX,"OnBeforeTimeStamp ",$Get(InternalName),!
    Quit
}

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
    Write !,..#PREFIX,"OnMenuItem ",$Get(MenuName)," ",$Get(InternalName)," ",$Get(SelectedText)," ",$Get(Enabled)," ",$Get(DisplayName),!
    
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

}
