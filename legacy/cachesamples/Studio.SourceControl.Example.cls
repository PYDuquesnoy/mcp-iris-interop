/// This is an example source control class. It is not intended for use on a real system, but as a code sample
/// showing some useful techniques.<p>
/// In this example each item in Cache is also stored as an XML file in the filesystem and these
/// external files are assumed to be version controlled by a tool. So every time you load an item this will
/// read the latest version of the item from the file, and when you save this item it will be
/// written back to the XML file.<p>
/// In addition, if you check an item out then an entry will be added to a global in Cache to show
/// that this item is checked out, and when you check it in the global entry will be removed.
/// Typically the checkout/checkin would call the external source control package, but setting
/// the global shows the general principle.<p>
Class Studio.SourceControl.Example Extends %Studio.SourceControl.Base [ ProcedureBlock ]
{

/// Before loading any item we check to see if we have a later version in the XML
/// file and if so this is loaded. Note the use of the timestamps in ^MySourceControl
/// is just a performance optimzation to avoid loading the file where it is not needed.
/// We have the '0' subscript which tracks the modified time on the file to avoid loading
/// it when the file has not changed, and the '1' subscript tracks the timestamp on the item in
/// Cache so we do not save it if it is up to date.
Method OnBeforeLoad(InternalName As %String) As %Status
{
 Set filename=..ExternalName(InternalName)
 If filename="" Quit $$$OK

 #; If no file then skip the import
 If '##class(%File).Exists(filename) Write !,"File ",filename," not found, skipping import" Quit $$$OK

 #; If the timestamp on the file is the same as the last time it was imported then there is nothing to do as it is already up to date
 If ##class(%File).GetFileDateModified(filename)=$get(^MySourceControl(0,InternalName)) Quit $$$OK

 #; Call the function to do the load
 Set sc=$system.OBJ.Load(filename,"-l-d")
 If $$$ISOK(sc) {
 Write !,"Imported '",InternalName,"' from file '",filename,"'"
 Set ^MySourceControl(0,InternalName)=##class(%File).GetFileDateModified(filename)
 Set ^MySourceControl(1,InternalName)=##class(%RoutineMgr).TS(InternalName)
 } Else {
 Do $system.Status.DecomposeStatus(sc,.errors,"d")
 }
 Quit sc
}

/// After saving an item in Cache we write this out to the XML file so the external source control
/// tool can see what changes we have made.
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject) As %Status
{
 Set filename=..ExternalName(InternalName)
 If filename="" Quit $$$OK

 #; If the timestamp of the item in Cache has not changed then there is no point in saving it again
 If ##class(%RoutineMgr).TS(InternalName)=$get(^MySourceControl(1,InternalName)) Quit $$$OK

 #; Call the export function
 Set sc=$system.OBJ.Export(InternalName,filename,"-d")
 If $$$ISOK(sc) {
 Write !,"Exported '",InternalName,"' to file '",filename,"'"
 Set ^MySourceControl(0,InternalName)=##class(%File).GetFileDateModified(filename)
 Set ^MySourceControl(1,InternalName)=##class(%RoutineMgr).TS(InternalName)
 } Else {
 Do $system.Status.DecomposeStatus(sc,,"d")
 }
 Quit $$$OK
}

/// Compilation can change a class as it can update the storage information. As such we need
/// to check if the item has changed and save it out again if it has, this is already done
/// by <method>OnAfterSave</method> so just call this.
Method OnAfterCompile(InternalName As %String) As %Status
{
 Quit ..OnAfterSave(InternalName)
}

Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
 Set Editable=0,IsCheckedOut=0,UserCheckedOut=""
 Set filename=..ExternalName(InternalName)
 Set IsInSourceControl=(filename'=""&&(##class(%File).Exists(filename)))
 If 'IsInSourceControl Set Editable=1 Quit $$$OK

 If $data(^MySourceControl(2,InternalName)) Set IsCheckedOut=1,UserCheckedOut=$listget(^MySourceControl(2,InternalName))
 If IsCheckedOut,UserCheckedOut=..Username Set Editable=1
 Quit ..OnBeforeLoad(InternalName)
}

Method IsInSourceControl(InternalName As %String) As %Boolean
{
 Quit 1
}

/// This assumes that your directory structure starts with a directory for the type of each item
/// and then has subdirectories for each '.' in the item name with a base directory added to the
/// start. So 'User.MyClass.cls' maps to '<base>cls/User/MyClass.xml'. You can pick whatever structure
/// you prefer. This example is designed for Windows filenames, you will need to modify it to support
/// Unix or VMS filenames.
Method ExternalName(InternalName As %String) As %String
{
	Set name=$piece(InternalName,".",1,*-1),ext=$zconvert($piece(InternalName,".",*),"l")
	If name="" Quit ""
	If $extract(name)="/"||($extract(name)="\") Set name=$extract(name,2,*)
	If $$$isWINDOWS {
		Quit $get(^MySourceControl("base"),"C:\sources\")_ext_"\"_$translate(name,"./","\\")_".xml"
	} Else {
		Quit $get(^MySourceControl("base"),"/sources/")_ext_"/"_$translate(name,".\","//")_".xml"
	}
}

/// Check this routine/class/csp file into source control.
Method CheckIn(InternalName As %String, Description As %String) As %Status
{
 #; See if we have it checked out
 If '$data(^MySourceControl(2,InternalName)) Quit $$$ERROR($$$GeneralError,"You can not check in an item you have not got checked out")
 If $listget(^MySourceControl(2,InternalName))'=..Username Quit $$$ERROR($$$GeneralError,"User '"_$listget(^MySourceControl(2,InternalName))_"' has this item checked out")

 #; Write out the latest version
 Set sc=..OnAfterSave(InternalName)
 If $$$ISERR(sc) Quit sc

 #; Remove the global to show that we have checked it in
 Kill ^MySourceControl(2,InternalName)
 Quit $$$OK
}

/// Check this routine/class/csp file out of source control.
Method CheckOut(InternalName As %String, Description As %String) As %Status
{
 #; See if anyone has it checked out
 If $data(^MySourceControl(2,InternalName)) {
 If $listget(^MySourceControl(2,InternalName))=..Username {
 Quit $$$ERROR($$$GeneralError,"You already have item '"_InternalName_"' checked out")
 } Else {
 Quit $$$ERROR($$$GeneralError,"Another user '"_$listget(^MySourceControl(2,InternalName))_"' has item '"_InternalName_"' checked out")
 }
 }

 #; Make sure we have the latest version of this item loaded
 Set sc=..OnBeforeLoad(InternalName)
 If $$$ISERR(sc) Quit sc

 #; Mark the global to show that we have it checked out.
 Set ^MySourceControl(2,InternalName)=$listbuild(..Username,Description)
 Quit $$$OK
}

}

