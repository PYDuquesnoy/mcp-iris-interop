/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
Class %Studio.SourceControl.ISC Extends %Studio.SourceControl.Base [ System = 4 ]
{

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: //iris/2025.1.0/databases/sys/cls/Studio/SourceControl/ISC.xml#1 $";

/// Revision number of this class when compiled as part of the //custom_ccrs/_common/config/... branch.  
/// This version will not be updated (by design) when the class is integrated to other branches.
/// This allows the user to tell what version of the Studio client tools are in use. 
Parameter Version = 239;

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="%CheckOut"/>
<MenuItem Name="%UndoCheckout"/>
<MenuItem Name="%CheckIn" Save="100"/> 
<MenuItem Name="%GetLatest"/>
<MenuItem Name="%AddToSourceControl" Save="100"/>
<MenuItem Name="%DisconnectItem" Save="100"/>
<MenuItem Name="%ReconnectItem"/>
<MenuItem Name="Diff"/>
<MenuItem Separator="1"/>
<MenuItem Name="%Disconnect"/>
<MenuItem Name="%Reconnect"/>
<MenuItem Separator="1"/>
<MenuItem Name="CCRFileHistory"/>
<MenuItem Name="CommitChanges" /> 
<MenuItem Name="CCRControls"/>
</Menu>
<Menu Name="%SourceContext" Type="1">
<MenuItem Name="%CheckOut"/>
<MenuItem Name="%UndoCheckout"/>
<MenuItem Name="%CheckIn" Save="100"/>
<MenuItem Name="%GetLatest"/>
<MenuItem Name="%AddToSourceControl" Save="100"/>
<MenuItem Name="%DisconnectItem"/>
<MenuItem Name="%ReconnectItem"/>
</Menu>
</MenuBase>
}

/// Display connection information in the Output display
Method Login(Name As %String, Password As %String) As %Status
{
	Do ..CheckIndexes()
	Do ..GetCredentials() //Has the possible side effect of setting %stP
	Quit $$$OK
}

Method OutputInfo()
{
	Set output=(..MainJob=0)
	If 'output Quit $$$OK
	Write !,"-----------------------------------------------------------------------------"
	Write !,"Source Control class "_$classname()_" is enabled for '"_$namespace_"'"
	Set disconnected=..Disconnected()
	Write !,"This namespace is "_$select(disconnected=2:"Permanently Disconnected from", disconnected=1:"Disconnected from",1:"Connected to")_" Perforce"
	If (disconnected <=1) {
		Set ret=..GetCredentials(.p4user, .p4passwd, .p4workspace, .p4dir, .p4port)
		If p4user'=""||(p4passwd'="")||(p4workspace'="")||(p4dir'="")||(p4port'="") Write !,"Perforce credentials explicitly defined:"
		If p4user'=""      Write !,"   p4user:      "_$get(p4user)
		If p4passwd'=""    Write !,"   p4password:  <defined>"
		If p4workspace'="" Write !,"   p4workspace: "_$get(p4workspace)
		If p4dir'=""       Write !,"   p4directory: "_$get(p4dir)
		If p4port'=""      Write !,"   p4port:      "_$get(p4port)
	} Else {
		Write !,"Current CCR Configuration"
		Write !,"   Organization: "_$get(^SYS("SourceControl","ItemSetConfig","Org"))
		Write !,"   System:       "_$get(^SYS("SourceControl","ItemSetConfig","System"))
		Write !,"   Environment:  "_$get(^SYS("SourceControl","ItemSetConfig","Environment"))
	}
	If $data(^%SYS("SourceControl","InstanceWidePrimaryNamespace"),instancePrimaryNamespace)#2 {
 	   Write !,"   Instance-wide Primary Namespace:  "_instancePrimaryNamespace	
	}
	
	Set locked=##class(%Studio.SourceControl.ISC).Locked()
	If (locked) {
		Write !,"NOTE - Source Control for this namespace is "_$select(locked=2:"ADMINLOCKED",1:"LOCKED")
		Write !,"       All items within this namespace will be treated as Readonly"
		If (locked<2) { Write !,"       Do ##class(%Studio.SourceControl.ISC).Unlock() to change Locked state" }
	}
	If ($get(^SYS("SourceControl","Misc","LockMapped"))){
		Write !,"NOTE - Source Control for this namespace is configured to lock MAPPED items"
		Write !,"       All items mapped from other databases will be treated as Readonly"
	}
	Write !,"^Sources = "_$get(^Sources)
	Write !
}

/// Called before the item is saved to the database. It is passed
/// a reference to the current temporary storage of this item so that it
/// can be modified before the save completes. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Set sc = $$$OK
	If (..ItemLocked(InternalName, .Reason)&&'..IsExcluded(InternalName)) {
		Set sc = $$$ERROR($$$GeneralError,"Cannot save item - "_Reason)
		Quit sc
	}
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		Return ..BeforeProdDecompSave(InternalName)
	}
	Quit sc
}

/// Return OnBeforeSave status for Decomposed Productions by checking modified PTD items
Method BeforeProdDecompSave(InternalName As %String) As %Status [ Private ]
{
	Set sc = $$$OK
	Set name = $Piece(InternalName, ".",1,*-1)
	Do ##class(%Studio.SourceControl.Production).GetModifiedItemsBeforeSave(InternalName,,.productionItems)
	Set key = $order(productionItems(""))
	While (key '= "") {
		// if any modified items in this production class are checked out by a different user, fail the check.
		Set sc = ..GetStatus(key,,.Editable)
		If 'Editable Return $$$ERROR($$$GeneralError, "Item "_InternalName_" is not editable. Check source control output.")
		Set key = $order(productionItems(key))
	}
	Return sc
}

Method OnBeforeLoad(InternalName As %String, display As %Boolean = 1) As %Status
{
	Quit ..Load(InternalName,.display)
}

ClassMethod Load(InternalName As %String, display As %Boolean = 1) As %Status
{
	#Dim sc As %Status = $$$OK
	Try {
		#; Reformat the InternalName to make sure the type is all in upper case and that a leading '/' is included for csp files
		Set InternalName=##class(%Studio.SourceControl.Interface).normalizeName(InternalName)
		#; Lock the load operation
		Lock +^IRIS.Temp.SourceControlLoad(InternalName)
		Set isPTD = 0
		If ..IsDecomposedProduction(InternalName) {
			Set ext = $ZCVT($Piece(InternalName,".",*), "U")
			Quit:ext="CLS" ; Do not load Production Class item if Decomposing Productions
			Set isPTD = 1
		}
		Set filename=..ExtName(InternalName)
		#; File not mapped so nothing to do
		If filename="" Quit
		#; If no file then skip the import
		If '##class(%File).Exists(filename) Write:display !,"File ",filename," not found, skipping import" Quit
		If ##class(%File).GetFileSize(filename)=0 Quit
		Set oldts=##class(%RoutineMgr).TS(InternalName)
		Set filets=##class(%File).GetFileDateModified(filename,1)
		#; If time already matches then no work to do
		If filets=$get(^Sources(0,"FileTimeStamp",InternalName)) {
			New %SourceControl
			If oldts=$get(^Sources(0,"ItemTimeStamp",InternalName)) Quit
			Write:display !,
			"ERROR: Item '"_InternalName_"' has been modified in the database outside of source control.",!,
			"The copy in IRIS no longer matches the version in the file '"_filename_"'.",!,
			"If you are sure the version in IRIS is the copy you want to keep, make a dummy modification and",!,
			"save it to force an export to the external file. Otherwise you must do an import from the external file."		
			Quit
		}
		Set loaded=1
		If InternalName["/" {
			Set sc=..ImportCSPFile(InternalName)
		} ElseIf isPTD {
			Set productionName = $Piece(InternalName, "||")
			Set sc = ##class(%Studio.SourceControl.Production).ImportPTD(filename, productionName)
		} Else {
			#; See if the file contains the correct item
			Set sc=$$Load^%apiOBJ(filename,"fv-d-l",,.imported,1)
			If $$$ISOK(sc) {
				Set name=##class(%Studio.SourceControl.Interface).normalizeName($order(imported("")))
				If name'=InternalName {
					Set loaded=0
				} Else {
					Set sc=$$Load^%apiOBJ(filename,"fv-d-l")
				}
			}
		}
		If loaded {
			Set newts=##class(%RoutineMgr).TS(InternalName)
			If newts'=oldts||($$$ISOK(sc))||($$$GETERRORCODE(sc)=$$$ERRORCODE($$$SAXError)) {
				Set ^Sources(0,"FileTimeStamp",InternalName)=filets
				Set ^Sources(0,"ItemTimeStamp",InternalName)=newts
			}
		}
		If $$$ISERR(sc) Do DecomposeStatus^%apiOBJ(sc,.errors,"d")
		If $$$ISOK(sc),loaded {
			Write !,"Imported '",InternalName,"' from file '",filename,"'"
		}
	} Catch ex {
		Set sc = ex.AsStatus()
	}
	Lock -^IRIS.Temp.SourceControlLoad(InternalName)
	Quit sc
}

Method OnBeforeTimestamp(InternalName As %String)
{
	If '$get(^SYS("SourceControl","Misc","NoAutoLoad")) {
		For i=$zu(41):-1:1 {
			If $Extract($zu(41,i))="C" {
				// Suppress import underneath a CALL-IN stack level
				Return
			}
		}
		Do ..OnBeforeLoad(InternalName,0)
	}
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject) As %Status
{
	#; the Tools -> Import and Tools -> Export GUIs do not always return InternalName of a csp file with a leading '/'; it must be added for other code to work
	If (InternalName["/")&&($E(InternalName)'="/") Set InternalName="/"_InternalName

	Set haschange=$system.CLS.IsMthd("%Studio.SourceControl.Change","IsUncommitted")
	Set filename=..ExternalName(InternalName)
	#; File not mapped so nothing to do
	If filename="" Quit $$$OK
	Set name=$Piece(InternalName,".",1,*-1)
	Set ext=$ZConvert($Piece(InternalName,".",*),"U")

	// If this is a Production class and using Production decomposition, export all modified items
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		$$$ThrowOnError(..AfterProdDecompSave(InternalName))
	}
	#; Do not export the default projects
	If ext="PRJ",$zconvert($extract(name,1,$length("default_")),"l")="default_" Quit $$$OK
	#; By convention items starting with Z,z,%z,%Z are not exported
	If ext'="PRJ",'$$$FileExists(filename) Write !,"File ",filename," not found, skipping export" Quit $$$OK

	If ($get(^SYS("SourceControl","Misc","InsertSrcVer")))&&(ext="CLS") {
		Set cnt=0
		&SQL(SELECT Count(id) INTO :cnt FROM %Dictionary.ParameterDefinition WHERE parent = :name AND Name='SrcVer')
		If ('(SQLCODE < 0))&&(cnt=0) {
			Write !,"Inserting SrcVer parameter into "_InternalName
			Set p=##class(%Dictionary.ParameterDefinition).%New()
			Set p.Name="SrcVer" 
			Do p.parentSetObjectId(name) 
			Set p.Default = "$"_"Id"_"$"	; separate out the string to keep Perforce RCS replacement from happening on this line
			Set p.Description = "Location and Revision of this file in Perforce (Auto-updating)"
			Set sc = p.%Save()
			If $IsObject($Get(%SourceControl)),$Get(%SourceControl.Modified) {
				Set %SourceControl.Modified(InternalName)=1
			}
			If $$$ISERR(sc) { Write !,"Error inserting SrcVer Parameter - "_$system.Status.GetErrorText(sc) }
		}
	}

	If haschange,##class(%Studio.SourceControl.Change).IsUncommitted(filename) {
		Set sc=##class(%Studio.SourceControl.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
		If ($USERNAME=UncommittedUser) {
			#; update performed by file owner; update the timestamp in the Change table
			Set sc=##class(%Studio.SourceControl.Change).UpdateUncommitted(filename,,,$USERNAME)	
		} Else {
			#; most likely, OnAfterSave() called by OnAfterCompile, which was triggered by a non-owner of the file
		}
		If $$$ISERR(sc) { Write !,$system.Status.GetErrorText(sc) }
	} 

	#; If time already matches and this is not a newly created file (no TimeStamp), then there is nothing to do
	If haschange,##class(%RoutineMgr).TS(InternalName)=$get(^Sources(0,"ItemTimeStamp",InternalName)),$get(^Sources(0,"ItemTimeStamp",InternalName))'="" Quit $$$OK 
	If ..ReadOnly(filename) Write !,"File ",filename," is read only, not exporting" Quit $$$OK
	If name["/" {
		#; we copy out CSP files
		Set sc = ..ExportCSPFile(InternalName)
	} ElseIf ext="CLS"||(ext="PRJ")||($zconvert($extract(filename,*-2,*),"l")="xml")||(##class(%RoutineMgr).UserType(InternalName)) {
		If '$$$FileExists(filename) Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
		Set qspec = $g(^SYS("SourceControl","Misc","ExportFlags"),"/diffexport")
		If $zconvert($extract(filename,*-2,*),"l")="cls" {
			Set sc=$$ExportUDL^%apiOBJ(InternalName,filename,"-d "_qspec)
		} ElseIf ext="PTD" {
			Set sc = ##class(%Studio.SourceControl.Production).ExportPTD(InternalName,"ExtName")
		} Else {
			Set sc=$$Export^%occXMLExport(filename,"-d "_qspec,InternalName)
		}
	} Else {
		Set sc=$$Export^%apiRTN(InternalName,filename,"Save for Source Control","WNSK\UTF8\","-d /diffexport")
	}
	If $$$ISOK(sc) {
		Write !,"Exported '",InternalName,"' to file '",filename,"'"
		Set ^Sources(0,"FileTimeStamp",InternalName)=$$$FileDateModifiedUTC(filename,1)
		Set ^Sources(0,"ItemTimeStamp",InternalName)=##class(%RoutineMgr).TS(InternalName)
	} Else {
		Do DecomposeStatus^%apiOBJ(sc,,"d")
		Quit sc
	}
	Quit $$$OK
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	Set sc=$$$OK
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..OnAfterSave(item) If $$$ISERR(sc) Quit
	}
	Quit sc
}

ClassMethod ExportCSPFile(InternalName As %String) As %Status
{
	Set cspFile = $System.CSP.GetFileName(InternalName)
	Set srcFile = ..ExtName(InternalName)
	// Quit if the csp application is defined within the source root
	If (cspFile=srcFile)||($$$isWINDOWS&&($ZCVT(cspFile,"l")=$ZCVT(srcFile,"l"))) Quit $$$OK
	If '(##class(%File).Exists(srcFile)&&..ReadOnly(srcFile)) {
		Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(srcFile))
		If '##class(%File).CopyFile(cspFile, srcFile) {
			Quit $$$ERROR($$$GeneralError,"Unable to export '"_srcFile_"'")
		}
	}
	Quit $$$OK
}

ClassMethod ImportCSPFile(InternalName As %String) As %Status
{
	; Changed to ClassMethod because of MAK2849 change moving calling code to ClassMethod; changes ExportCSPFile as well to match
	Set cspFile = $System.CSP.GetFileName(InternalName)
	Set srcFile = ..ExtName(InternalName)
	// Quit if the csp application is defined within the source root
	If (cspFile=srcFile)||($$$isWINDOWS&&($ZCVT(cspFile,"l")=$ZCVT(srcFile,"l"))) Quit $$$OK
	If ##class(%File).Delete(cspFile) && ##class(%File).CopyFile(srcFile, cspFile) {
		Set sc = ..SetFileWriteable(cspFile)
	} Else {
		Set sc = $$$ERROR($$$GeneralError, "Unable to import '"_srcFile_"'")
	}
	Quit sc
}

/// Method for exporting all relevant PTD items from a Decomposed Production. Called from OnAfterSave.
/// Additionally calls OnAfterSave on each PTD item.
Method AfterProdDecompSave(InternalName As %String) As %Status [ Private ]
{
	do ##class(%Studio.SourceControl.Production).GetModifiedItemsAfterSave(InternalName, .productionItems)
	set key = $order(productionItems(""))
	while (key '= "") {
		// passive check out of decomposed production items
		set itemFilename = ..ExternalName(key)
		set itemBackupName = itemFilename_".bak"
		if (productionItems(key) = "D") {
			if ##class(%Studio.SourceControl.Change).IsUncommitted(itemFilename) {
				$$$ThrowOnError(##class(%Studio.SourceControl.Change).GetUncommitted(itemFilename,.action))
			}
			if $Get(action)["add" {
				$$$ThrowOnError(..UndoCheckout(key))
			} else {
				$$$ThrowOnError(..RemoveFromSourceControl(key))
			}
		} else {
			if ##class(%File).Exists(itemFilename) {
				set wasUncommitted = ##class(%Studio.SourceControl.Change).IsUncommitted(itemFilename)
				if 'wasUncommitted {
					$$$ThrowOnError(..CheckOut(key, "", 0))
				}
			} else {
				$$$ThrowOnError(..AddToSourceControl(key))
			}
			set sc = ..OnAfterSave(key)
			if $$$ISERR(sc) return sc
			if ##class(%File).Compare(itemFilename, itemBackupName) {
				$$$ThrowOnError(..UndoCheckout(key))
			}
		}
		set key = $order(productionItems(key))
	}
	Quit $$$OK
}

/// Return information about this entity.
/// <p>
/// This method checks the current status of the item, seeing whether or not it is in source control (based on an exported
/// copy of the item on disk), and if it is in source control, whether it is currently checked out (based on whether the file
/// is Readonly or not).  
/// <p>
/// If the file is checked out, this method will check to find the value of 
/// $USERNAME for whomever performed <method>CheckOut</method>.  If the current $USERNAME does not match, then the user 
/// will not be permitted to edit the file as it has been checked out by another user.
Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
	Set Editable=1,IsCheckedOut=1,UserCheckedOut=""
	Set filename=..ExternalName(InternalName)
	// Special handling for decomposed Productions
	Set ext = $ZCVT($Piece(InternalName, ".", *),"U")
	Set productionDecomp = ..IsDecomposedProduction(InternalName,,"CLS")
	If productionDecomp {
		Set st = ..GetProdDecompStatus(InternalName,.IsInSourceControl,.Editable,.IsCheckedOut,.UserCheckedOut)
		If 'Editable Return st
	} Else {
		Set IsInSourceControl=(filename'=""&&($$$FileExists(filename)))
	}
	If filename="" Quit $$$OK
	Set backupFile=..BackupName(InternalName)
	#; If the file does not exist then it must be a new item so it is editable.
	If '$$$FileExists(filename) {
		Set IsCheckedOut=0
	} ElseIf ..ReadOnly(filename) {
		// if item is PTD or a production class with decomposition enabled, allow edit without active checkout.
		Set Editable = $Select(productionDecomp:1, ext="PTD":1, 1:0)
		Set IsCheckedOut=0
	}
	If ('IsCheckedOut)&&($$$FileExists(backupFile)) {
		Set ret=$$$FileDelete(backupFile)
		If 'ret Write !,"Error deleting unnecessary local backup copy: "_backupFile
	}

	Set haschange=$system.CLS.IsMthd("%Studio.SourceControl.Change","IsUncommitted")
	#; If it is a CSP file stored in the Perforce root, then the IsInSourceControl might be set improperly and it needs to be confirmed
	If (IsInSourceControl)&&(IsCheckedOut)&&(filename=$$GetFilename^%apiCSP(InternalName)) {
		#; If it is truely IsInSourceControl&&IsCheckedOut then it will be in the uncommitted queue; if not, then correct the flags
		If haschange,'##class(%Studio.SourceControl.Change).IsUncommitted(filename) Set IsInSourceControl=0,IsCheckedOut=0
	}
	
	#; Kill any outdated user edit information, but not deletes or reverts since they may be pending commit from a Disconnected instance
	If haschange,('IsCheckedOut)&&(##class(%Studio.SourceControl.Change).IsUncommitted(filename)) {
		If ('$listfind($listbuild("revert","delete"),##class(%Studio.SourceControl.Change).OpenUncommitted(filename).Action)) Set sc=##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,0,0,0)
	}

	#; Ensure that it isn't locked for editing by someone else
	Set sc=$$$OK
	If haschange,##class(%Studio.SourceControl.Change).IsUncommitted(filename) {
		Set sc=##class(%Studio.SourceControl.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
		If ('sc) {
			Write !,$SYSTEM.Status.GetErrorText(sc)
			Write !,"Removing from uncommitted queue..."
			Set sc=..UndoCheckout(InternalName)
			Set IsCheckedOut=0
		} ElseIf $D(tAction)&&(UncommittedUser'=$USERNAME)&&..IsSharedDevInstance() {
			Set msg="NOTICE: "_InternalName_" is currently checked out by user '"_UncommittedUser_"', and was last updated at "_UncommittedLastUpdated
			Write !,msg
			Set Editable=0
			Set IsInSourceControl=0		;set this to 0 to prevent user from being prompted to Check Out file
			Set UserCheckedOut=UncommittedUser
		}
	}
	#; Ensure that the item isn't Locked
	If ..ItemLocked(InternalName, .Reason) {
		Set msg="NOTICE: "_InternalName_" is being treated as Readonly - "_Reason
		Write !,msg
		Set Editable=0
		Set IsInSourceControl=0		;set this to 0 to prevent user from being prompted to Check Out file
	}
	Quit sc
}

/// Get status for a Decomposed Production class. If called from IDE, set Editable to 0 if any PTD items are checked out by another user.
Method GetProdDecompStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status [ Private ]
{
	Set name = $Piece(InternalName, ".",1,*-1)
	Set prodSettings = ##class(%Studio.SourceControl.Production).CreateInternalName(name,,,1)
	Set prodSettingsFile = ..ExternalName(prodSettings)
	Set IsInSourceControl = ((prodSettingsFile'="")&&($$$FileExists(prodSettingsFile)))
	// Only care about preemptively marking Production Read-Only if in IDE
	Set isEnsPortal = ##class(%Studio.SourceControl.Production).IsEnsPortal()
	If 'isEnsPortal {
		Do ##class(%Studio.SourceControl.Production).GetModifiedItemsBeforeSave(InternalName,,.productionItems)
		Set key = $order(productionItems(""))
		While (key '= "") {
			// if any modified items in this production class are checked out by a different user, fail the check.
			Set st = ..GetStatus(key, .IsInSourceControl, .Editable, .IsCheckedOut, .UserCheckedOut)
			If 'Editable Return st
			Set key = $order(productionItems(key))
		}
	}
	Return $$$OK
}

Method IsInSourceControl(InternalName As %String) As %Boolean [ CodeMode = expression ]
{
..ExtName(InternalName)'=""
}

Method ExternalName(InternalName As %String) As %String [ CodeMode = expression ]
{
..ExtName(InternalName)
}

/// Check this routine/class/csp file into source control.
Method CheckIn(InternalName As %String, Description As %String) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// ** DEPRECATED - Use more secure <method>SecureRunCmd</method> instead<p>
/// Run a shell command and report any error message, return <var>output</var> with 
/// lines as subscripts of the array if <var>stream</var> is false (the default) but if
/// <var>stream</var> is true then we will return the output as a stream to be read by the caller.
ClassMethod RunCmd(cmd As %String, ByRef output As %String, display As %Boolean = 1, stream As %Boolean = 0) As %Status [ Deprecated ]
{
	Set sc=$$$OK,text=cmd
	Kill output
	
	// Make sure that any p4 commands have login/client information, if known
	If $P(cmd," ")="p4" {
		Set p4="p4"	
		
		Set ret=..GetCredentials(.p4user, .p4passwd, .p4workspace, .p4dir, .p4port)
		If 'ret Write !,"NOTICE: Source Control Credentials are not set for '"_$USERNAME_"'"
		 
		If p4user'="" Set p4=p4_" -u "_p4user
		If p4passwd'="" Set p4=p4_" -P "_$$$QuoteName(p4passwd)
		If p4workspace'="" Set p4=p4_" -c "_p4workspace
		If p4dir'="" {
			Set p4=p4_" -d "_$$$QuoteName($zstrip(p4dir,">","\"))
		}
		If p4port'="" Set p4=p4_" -p "_$$$QuoteName(p4port)
		
		Set cmd = p4_" "_$P(cmd," ",2,$L(cmd," "))
	}
	
	If display Write !,"CMD: ",text
	Set errorfile=##class(%File).TempFilename("err"), outputfile=##class(%File).TempFilename("out")
	Set rc=$zf(-1,cmd_" 2> """_errorfile_""" > """_outputfile_"""")
	Set errorstream=##class(%FileCharacterStream).%New(),outputstream=##class(%FileCharacterStream).%New()
	Set errorstream.Filename=errorfile,outputstream.Filename=outputfile
	If errorstream.Size>0 {
		Do errorstream.Rewind()
		Set error=errorstream.Read()
		Set sc=$$$ERROR($$$GeneralError,"Error: "_error)
	}
	Do errorstream.Clear()
	If stream {
		Set output=outputstream,outputstream.RemoveOnClose=1
	} Else {
		If outputstream.Size>0 {
			Do outputstream.Rewind()
			While 'outputstream.AtEnd {
				Set line=outputstream.ReadLine()
				Set output($increment(output))=line
			}
		}
		Do outputstream.Clear()
	}
	Quit sc
}

/// Run a command and report any error message, return <var>output</var> with 
/// lines as subscripts of the array if <var>stream</var> is false (the default) but if
/// <var>stream</var> is true then we will return the output as a stream to be read by the caller.
/// Passed the executable name in <var>cmd</var> and the list of arguments as an integer subscripted
/// local array passed in by reference in <var>args</var>.
ClassMethod SecureRunCmd(cmd As %String, ByRef args, ByRef output As %String, display As %Boolean = 1, stream As %Boolean = 0, input As %String = "") As %Status
{
	Set sc=$$$OK,args=+$get(args)
	Kill output
	
	If display {
		Write !,"CMD: ",cmd
		For i=1:1:args Write " ",args(i)
	}
	// Make sure that any p4 commands have login/client information, if known
	If cmd="p4" {
		Set ret=..GetCredentials(.p4user, .p4passwd, .p4workspace, .p4dir, .p4port)
		If 'ret Write !,"NOTICE: Source Control Credentials are not set for '"_$USERNAME_"'"

		If p4user'="" Set newargs($i(newargs))="-u",newargs($i(newargs))=p4user
		If p4passwd'="" Set newargs($i(newargs))="-P",newargs($i(newargs))=p4passwd
		If p4workspace'="" Set newargs($i(newargs))="-c",newargs($i(newargs))=p4workspace
		If p4dir'="" {
			Set newargs($i(newargs))="-d",newargs($i(newargs))=$zstrip(p4dir,">","\")
		}
		If p4port'="" Set newargs($i(newargs))="-p",newargs($i(newargs))=p4port
		#; Insert original args after these settings
		For i=1:1:args Set newargs($i(newargs))=args(i)
	} Else {
		Merge newargs=args
	}
	
	Set errorfile=##class(%File).TempFilename("err"), outputfile=##class(%File).TempFilename("out")
	Try {
		Set rc=$zf(-100,"/stdout="""_outputfile_""" /stderr="""_errorfile_""""_$s(input'="":" /stdin="""_input_"""",1:""),cmd,.newargs)
	} Catch {
		RETURN $$$ERROR($$$FileDoesNotExist,cmd)
	}
	Set errorstream=##class(%FileCharacterStream).%New(),outputstream=##class(%FileCharacterStream).%New()
	Set errorstream.Filename=errorfile,outputstream.Filename=outputfile
	If errorstream.Size>0 {
		Do errorstream.Rewind()
		Set error=errorstream.Read()
		Set sc=$$$ERROR($$$GeneralError,"Error: "_error)
	}
	Do errorstream.Clear()
	If stream {
		Set output=outputstream,outputstream.RemoveOnClose=1
	} Else {
		If outputstream.Size>0 {
			Do outputstream.Rewind()
			While 'outputstream.AtEnd {
				Set line=outputstream.ReadLine()
				Set output($increment(output))=line
			}
		}
		Do outputstream.Clear()
	}
	Quit sc
}

/// Check this routine/class/csp file out of source control.<br/>
/// Following successful checkout, the copy of the file on disk is loaded into the Namespace, unless <var>Load</var> is false.
Method CheckOut(InternalName As %String, Description As %String, Load As %Boolean = 1) As %Status
{
	Set sc=$$$OK
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		Quit sc
	}
	If ('..Disconnected())&&($get(^SYS("SourceControl","Misc","AutoSync"))) {
		Set sc=..GetLatest(InternalName)
		If ($$$ISERR(sc))&&($system.Status.GetErrorText(sc)'["up-to-date") { Quit sc }
	}
	Set filename=..ExternalName(InternalName)
	If (filename="") || ('##class(%File).ReadOnly(filename)) Quit $$$OK
	Set backupFile=..BackupName(InternalName)
	If $$$FileExists(backupFile) If '$$$FileDelete(backupFile) Write !,"Error deleting backup copy: "_backupFile
	Set ret=$$$FileCopy(filename,backupFile)
	If 'ret Write !,"Error making local backup copy: "_backupFile
	If ..Disconnected() {
		Set sc = ..SetFileWriteable(filename)
		If $$$ISERR(sc) Quit sc
	} Else {
		Set args($i(args))="edit",args($i(args))=filename
		Set p4Issued=1
		
		// Check if item is already checked out and warn user
		Set checkedOutArgs($i(checkedOutArgs)) = "opened", checkedOutArgs($i(checkedOutArgs)) = "-a", checkedOutArgs($i(checkedOutArgs)) = filename
		Set sc = ..SecureRunCmd("p4", .checkedOutArgs, .out)
		
		// sc is 1 if file is checked out in another workspace
		If $$$ISOK(sc) {
			Set line = ""
			Set line = $Order(out(line))
			While line '= "" {
				Set client = $Piece(out(line)," by ",2)
				Write !, "Warning: file "_filename_" is currently checked out by "_client
				Set line = $Order(out(line))
			}
		} ElseIf (sc '[ "not opened anywhere") {
			// Ignore error status from file not being open. Otherwise abort Checkout
			Quit sc
		}
		Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Quit sc
	}
	Set haschange=$system.CLS.IsMthd("%Studio.SourceControl.Change","IsUncommitted")
	If haschange {
		Set sc=##class(%Studio.SourceControl.Change).SetUncommitted(filename, "edit", InternalName,,,$G(p4Issued),$get(%ccrSession),,0)
		If $$$ISERR(sc) Write "Error adding to Uncommitted queue - "_$System.OBJ.DisplayError(sc)
	}
	#; If the file still does not exist or it is not writable then checkout failed
	If ('$$$FileExists(filename))||(..ReadOnly(filename)) Quit $$$ERROR($$$GeneralError,"Checkout failed to make file '"_InternalName_"' writeable in filesystem")
	If (Load) { Set sc=..OnBeforeLoad(InternalName) If $$$ISERR(sc) Quit sc }
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..CheckOut(item,.Description) If $$$ISERR(sc) Quit
	}
	Quit sc
}

Method UndoCheckout(InternalName As %String) As %Status
{
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		Return ..UndoProdDecompCheckout(InternalName)
	}
	Set filename=..ExternalName(InternalName)
	If filename="" Quit $$$OK
	Set backupFile=..BackupName(InternalName)
	Set sc=##class(%Studio.SourceControl.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated,.P4Issued)
	If ($G(tAction)="add")&&(filename'=$System.CSP.GetFileName(InternalName)) {
		#; item wasn't previously in Source Control, and it is not a CSP file stored in the Perforce root, so delete it from the OS
		Set ret=##class(%File).Delete(filename) If 'ret Write !,"Unable to delete file for newly added item - "_filename
	}
	If ..Disconnected() {
		If '##class(%File).Exists(backupFile)  Quit $$$ERROR($$$GeneralError,"Disconnected Revert Failed: Local backup file does not exist")
		If $G(tAction)'="add" {
			Set ret=##class(%File).Delete(filename) If 'ret Quit $$$ERROR($$$GeneralError,"Revert Failed: Unable to delete current file")
			Set ret=##class(%File).CopyFile(backupFile,filename) If 'ret Quit $$$ERROR($$$GeneralError,"Revert Failed: Unable to replace current file with backup copy")
			#; change file back to Readonly
			Set sc=..SetFileReadOnly(filename)
			If $$$ISERR(sc) Quit sc
		}
	} Else {
		Set args($i(args))="revert",args($i(args))=filename
		Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Quit sc
	}
	If ((..Disconnected()=1)&&(P4Issued'="")) {
		#; Change to an uncommitted 'revert' because previous command was issues to Perforce and this is a temporarily Disconnected instance
		Set sc=##class(%Studio.SourceControl.Change).UpdateUncommitted(filename, "revert")
		If $$$ISERR(sc) Write "Error changing uncommitted to 'revert' - "_$System.OBJ.DisplayError(sc)
	} Else {
		#; Remove the item from the list of uncommitted changes; 
		Set sc=##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,1,1)
		If $$$ISERR(sc) Write "Error removing uncommitted file "_filename_" - "_$System.OBJ.DisplayError(sc)
	}
	Set sc=..OnBeforeLoad(InternalName) If $$$ISERR(sc) Quit sc
	// check if we should delete PTD item
	If ..IsDecomposedProduction(InternalName,,"PTD") && '$$$FileExists(filename) {
		Set sc = ##class(%Studio.SourceControl.Production).RemoveItem(InternalName)
		If $$$ISERR(sc) && (sc '[ "ConfigItemNotFound") Quit sc
	}
	If (##class(%File).Exists(backupFile)) {
		Set ret=##class(%File).Delete(backupFile) If 'ret Write !,"Error deleting unnecessary local backup copy: "_backupFile
	}
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..UndoCheckout(item) If $$$ISERR(sc) Quit
	}
	#; Delete from file system if Perforce did not mark it back to ReadOnly as a result of the Revert and it is not a CSP file stored in the Perforce root
	If ('..ReadOnly(filename))&&(filename'=$System.CSP.GetFileName(InternalName))  {
		Set sc=##class(%File).Delete(filename)
		If $$$ISERR(sc) Quit sc	
	}
	#; If the file no longer exists on the file system (due to this being a revert of an "Add") then kill the ^Sources nodes
	If '##class(%File).Exists(filename) {
		Kill ^Sources(0,"FileTimeStamp",InternalName)
		Kill ^Sources(0,"ItemTimeStamp",InternalName)
	} Else {
		Set sc=..Compile(InternalName)
	}
	Quit sc
}

/// Call UndoCheckout for each of a user's uncommitted changes to a Decomposed Production
Method UndoProdDecompCheckout(InternalName As %String) As %Status [ Private ]
{
	Set name = $Piece(InternalName, ".", 1, *-1)
	Set sc = ##class(%Studio.SourceControl.Production).GetUserProductionChanges(name, .items)
	If $$$ISERR(sc) Quit sc
	Set SCs = $$$OK
	Set itemName = $Order(items(""))
	While itemName '= "" {
		Set sc = ..UndoCheckout(itemName)
		Do $System.Status.AppendStatus(SCs, sc)
		Set itemName = $Order(items(itemName))
	}
	Return SCs
}

/// Compiles <var>InternalName</var> if it still exists.
/// Will skip up-to-date files.
Method Compile(InternalName As %String) As %Status
{
	New %SourceControl
	Set parts = $Length(InternalName,".")
	Set name = $Piece(InternalName,".",1,parts-1)
	Set ext = $ZCVT($Piece(InternalName,".",parts), "U")
	Set sc = $$$OK
	If (ext = "CLS") {
		If $$$defClassDefined(name) {
			Set sc = $System.OBJ.Compile(name,"ckud")
		}
	} ElseIf ##class(%Library.RoutineMgr).Exists(InternalName) {
		Set routine = ##class(%Library.RoutineMgr).%New(InternalName)
		Set sc = routine.Compile("ckud")
	}
	Quit sc
}

Method GetLatest(InternalName As %String) As %Status
{
	Set file=..ExternalName(InternalName)
	If file="" Quit $$$OK
	If ..Disconnected() Quit $$$ERROR($$$GeneralError,"Unable to get the latest version of a file while disconnected")
	Set args($i(args))="sync",args($i(args))=file
	Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Quit sc
	Set sc=..OnBeforeLoad(InternalName) If $$$ISERR(sc) Quit sc
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..GetLatest(item) If $$$ISERR(sc) Quit
	}
	Quit sc
}

/// Wrapper around %File:SetReadOnly to return a %Status
ClassMethod SetFileReadOnly(pFile As %String) As %Status
{
	Set result = ##class(%File).SetReadOnly(pFile)
	If 'result {
		Quit $$$ERROR($$$GeneralError,"Unable to make file '"_pFile_"' read-only")
	}
	Quit $$$OK
}

/// Wrapper around %File:SetWriteable to return a %Status
ClassMethod SetFileWriteable(pFile As %String) As %Status
{
	Set result = ##class(%File).SetWriteable(pFile,0)
	If 'result {
		Quit $$$ERROR($$$GeneralError,"Unable to make file '"_pFile_"' writeable")
	}
	Quit $$$OK
}

/// Update the ^Sources information with the file dates after a build
ClassMethod UpdateSources() As %Status
{
	Set sc=$$$qualifierParse("Compiler","asp"_$select($namespace="%SYS":" /mapped=1",1:""),.qstruct) Quit:$$$ISERR(sc) sc
	Do GetClassFullList^%occLibrary(.list,.qstruct)
	Set class=""
	For  {
		Set class=$order(list(class)) Quit:class=""
		Set filename=..ExtName(class_".CLS")
		#; If no file then skip the import
		If filename=""||('##class(%File).Exists(filename)) Continue
		Set ^Sources(0,"FileTimeStamp",class_".CLS")=##class(%File).GetFileDateModified(filename,1)
		Set ^Sources(0,"ItemTimeStamp",class_".CLS")=##class(%RoutineMgr).TS(class_".CLS")
	}
	Set routine=""
	If $extract($namespace)'="^",$namespace'="%SYS" {
		Set ns=$$GetGlobalSourceDatabase^%SYS.SECURITY($name(^ROUTINE))
	} Else {
		Set ns=""
	}

	For  {
		Set routine=$order(^|ns|rINDEX(routine)) Quit:routine=""
		Set type=""
		For  {
			Set type=$order(^|ns|rINDEX(routine,type)) Quit:type=""
			Set filename=..ExtName(routine_"."_type)
			If filename=""||('##class(%File).Exists(filename)) Continue
			Set ^Sources(0,"FileTimeStamp",routine_"."_type)=##class(%File).GetFileDateModified(filename,1)
			Set ^Sources(0,"ItemTimeStamp",routine_"."_type)=##class(%RoutineMgr).TS(routine_"."_type)
		}
	}
	Quit $$$OK
}

/// Job off a background job to update the sources information.
/// It returns -1 if it could not start the job or the $job number if successful.
ClassMethod JobUpdateSources() As %String [ ProcedureBlock = 0 ]
{
	Quit $zutil(66,"USR","JobEntry^"_$zname,10,0,0)=-1
JobEntry()	Do ##class(%Studio.SourceControl.ISC).UpdateSources()
	Quit
}

/// Called to add this item to source control
Method AddToSourceControl(InternalName As %String, Description As %String = "") As %Status
{
	Set sc=$$$OK
	Set filename=..ExternalName(InternalName)
	If filename="" Quit $$$ERROR($$$GeneralError,"Unable to find mapping where item '"_InternalName_"' should go")
	#; If file not there create a blank file now
	Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
	If '##class(%File).Exists(filename) {
		Open filename:"NW":0 Close filename
		If '##class(%File).Exists(filename) Quit $$$ERROR($$$GeneralError,"Unable to create file '"_filename_"'")
		#; If the document is present then export it
		Kill ^Sources(0,"FileTimeStamp",InternalName)
		Kill ^Sources(0,"ItemTimeStamp",InternalName)
		#; Only export if the class or routine has been saved (check by removing the trailing '.CLS')
		If $zcvt($piece(InternalName,".",*),"l")="cls" {
			Set class=$piece(InternalName,".",1,*-1)
			If ##class(%Dictionary.ClassDefinition).%ExistsId(class) {	
				 Do ..OnAfterSave(InternalName)
			} Else {
				#; Need dummy blank class
				Set cls=##class(%Dictionary.ClassDefinition).%New(class,$$$CLASSDEFINITIONVERSION)
				Do cls.%Save()
				Kill cls
				Do ..OnAfterSave(InternalName)
				Do ##class(%Dictionary.ClassDefinition).%DeleteId(class)
			}
		} ElseIf ##class(%RoutineMgr).Exists(InternalName) {	
			 Do ..OnAfterSave(InternalName)
		}
	}
	Set sc=##class(%Studio.SourceControl.Change).SetUncommitted(filename, "add", InternalName,,,('..Disconnected()),$get(%ccrSession),,0)
	If $$$ISERR(sc) Write "Error adding to Uncommitted queue - "_$System.OBJ.DisplayError(sc)

	If '..Disconnected() {
		Set args($i(args))="add",args($i(args))=filename
		Set sc=..SecureRunCmd("p4",.args)
		If $$$ISERR(sc) {
			Set sc2=##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,0,1)
			If $$$ISERR(sc2) Set sc=$SYSTEM.Status.AppendStatus(sc,sc2)
			#; if the file is not ReadOnly and it's not a csp file under the perforce root, then it was created for the first time and should be deleted because p4 threw an error
			If ('..ReadOnly(filename))&&(filename'=$SYSTEM.CSP.GetFileName(InternalName)) Do ##class(%File).Delete(filename)
			Quit sc
		}
	}
	#; create backup file that is identical to the file, to allow UndoCheckout logic to work 
	Set fileBackup=..BackupName(InternalName)
	Set ret=##class(%File).CopyFile(filename,fileBackup) If 'ret Write !,"Error creating backup file - "_fileBackup
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..AddToSourceControl(item,.Description) If $$$ISERR(sc) Quit
	}
	Quit sc
}

/// Called to delete this item from source control
Method RemoveFromSourceControl(InternalName As %String, Description As %String = "") As %Status
{
	Set sc=$$$OK
	
	// If removing a decomposed Production from source control, need to also remove all ptds
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		Set prodName = $piece(InternalName, ".", 1, *-1)
		Set sc = ##class(%Studio.SourceControl.Production).DeleteProductionDefinitionShards(prodName, "RemoveFromSourceControl", "ExtName")
		Quit:$$$ISERR(sc) sc
	}
	
	Set filename=..ExternalName(InternalName)
	If filename="" Quit $$$ERROR($$$GeneralError,"Unable to find mapping where item '"_InternalName_"' was")
	Set fileExists = ##class(%File).Exists(filename)
	Set isCSP = ($Extract(InternalName) = "/")
	If 'isCSP && 'fileExists Quit $$$OK
	If ..Disconnected() {
		Set isAdd = 0
		If ##class(%Studio.SourceControl.Change).IsUncommitted(filename) {
			Set sc = ##class(%Studio.SourceControl.Change).GetUncommitted(filename,.action)
			If $$$ISERR(sc) Quit sc
			If action = "add" {
				Set isAdd = 1
				Set sc = ##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,,1)
				If $$$ISERR(sc) Quit sc
			}
		}
		If 'isAdd {
			Set sc=##class(%Studio.SourceControl.Change).SetUncommitted(filename, "delete", InternalName,,,,$get(%ccrSession),,0)
			If $$$ISERR(sc) Write "Error adding to Uncommitted queue - "_$System.OBJ.DisplayError(sc)
		}
		If (fileExists) {
			Set rc=##class(%File).Delete(filename)
			If 'rc Quit $$$ERROR($$$GeneralError,"Unable to delete file '"_filename_"'")
		}
	} Else {
		Set sc=..GetStatus(InternalName,.isinsourcecontrol,.editable,.ischeckedout) If $$$ISERR(sc) Quit sc
		#; If we wish to delete this we must revert the checkout first
		If ischeckedout {
			Kill args Set args($i(args))="revert",args($i(args))=filename
			Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Quit sc
		}
		#; Check if the file is still present in Perforce, if it is not then we are done and we must have reverted a new file set for 'add', so just delete the local file
		Kill args Set args($i(args))="files",args($i(args))=filename
		Set sc=..SecureRunCmd("p4",.args,,0)
		If $$$ISOK(sc) {
			Kill args Set args($i(args))="delete",args($i(args))=filename
			Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Quit sc
		} ElseIf fileExists {
			Set rc=##class(%File).Delete(filename)
			If 'rc Quit $$$ERROR($$$GeneralError,"Unable to delete file '"_filename_"'")
		}
	}
	If ##class(%RoutineMgr).Exists(InternalName) && '..IsDecomposedProduction(InternalName) {
		Set sc=##class(%RoutineMgr).Delete(InternalName) If $$$ISERR(sc) Quit sc
	}
	Set other=$get(^Sources(0,"ExtraItems",InternalName))
	For i=1:1:$length(other,",") {
		Set item=$piece(other,",",i)
		If item'="" Set sc=..RemoveFromSourceControl(item,.Description) If $$$ISERR(sc) Quit
		If ##class(%RoutineMgr).Exists(InternalName) && '..IsDecomposedProduction(InternalName) {
			Set sc=##class(%RoutineMgr).Delete(InternalName) If $$$ISERR(sc) Quit
		}
	}
	Quit sc
}

/// Return filename of this item
ClassMethod ExtName(InternalName As %String) As %String
{
	Set name=..Name(InternalName)
	Quit $select(name="":"",1:$$$FileNormalizeFilename(^Sources_name))
}

/// Return filename of backup file of this item.
/// <p>
/// At the time of <method>CheckOut</method>, a local backup of the item in its existing state is written to the 
/// file system with a .bak extension.  This file will be used on Disconnected systems to restore to the previous
/// state when <method>UndoCheckout</method> is called.  It can also be used for diffs from the original file state.
ClassMethod BackupName(InternalName As %String) As %String
{
	Quit ..ExtName(InternalName)_".bak"
}

/// Return the name of this item without the prefix to be added by ExtName
ClassMethod Name(InternalName As %String) As %String
{
	If $data(^Sources)'=11 Write !,"^Sources is not set up so hooks will not work; namespace: "_$namespace Quit ""
	Set InternalName=##class(%Studio.SourceControl.Interface).normalizeName(InternalName)
	#; Disconnected items do not have an external name
	If InternalName'="",$get(^Sources(0,"Disconnected",InternalName)) Quit ""
	Set usertype=$system.CLS.IsMthd("%Library.RoutineMgr","UserType")
		
	// For an abstract document, use the GetOther() method to try to determine its "real" class
	If usertype,##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
		// Check for a real abstract document subclass (or GetOther() may not work)
		If $classmethod(docclass,"%IsA","%Studio.AbstractDocument") {
			// Grab the actual name
			Set actualName = $classmethod(docclass,"GetOther",InternalName)
			// The actualName is only valid if we get a single .cls as a result
			If actualName'[",",$ZCVT($P(actualName,".",$L(actualName,".")),"U")="CLS" {
				// We use what GetOther() gives us, thus Demo.Loan.FindRateProcess.bpl becomes Demo.Loan.FindRateProcess.cls
				Set InternalName = actualName
			}
		}
	}	
	
	If $$CheckProtect^%qccServer(InternalName) Quit ""
	If ..IsExcluded(InternalName) Quit ""
	Set nam=$p(InternalName,".",1,*-1),ext=$p(InternalName,".",*),ext=$zcvt(ext,"u")
	If nam=""||(ext="") Quit ""
	
	// If a name is found, exit Do block and perform post-processing
	Do {
		// Any CSP items should be matched against the "/CSP/" mapping in ^Sources
		If InternalName["/" {
			Set filename=$$GetFilename^%apiCSP(InternalName)
			//Find if this csp file is located within the ^Sources tree, and return appropriate value
			If $$$isWINDOWS {
				If $zcvt($extract(filename,1,$length(^Sources)),"l")=$zcvt(^Sources,"l") {
					Set name = $extract(filename,$length(^Sources)+1,*)
					Continue
				}
			} Else {
				If $extract(filename,1,$length(^Sources))=^Sources {
					Set name = $extract(filename,$length(^Sources)+1,*)
					Continue
				}
			}
			//Do not support manipulating files in the /itemsetsourcelink* csp app which are not inside of the namespace's ^Sources tree
			If InternalName["itemsetsourcelink" {
				Write !,"To control files in the /itemsetsourcelink* web app, they must be in this tree: "_^Sources_" ("_InternalName_" is located at "_filename_")"
				Return ""
			}
			// Any CSP items should be matched against the "/CSP/" mapping if the file is not stored in the ^Sources tree
			Set ext="/CSP/"	
		}
		If ext="PRJ",nam["Default_" Return ""
		If (ext="CLS") && ($$$defClassKeyGet(nam,$$$cCLASSgeneratedby)'="") Return ""
		
		// Returned name cannot contain '#'. All returned values replace '#' with '~23~'
		Set default=0
		Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $extract(nam,1,$length(p))=p,($data(^Sources(ext,p),found)#2) Quit
		If $data(found)=0,$data(^Sources(ext,"*"),found),'$get(^Sources(ext,"*","NoFolders")) Set default=1
		If $data(found)=0 Return ""
		If InternalName["/" {
			// If no specific mapping was specified (p=""), then return the whole csp filename; otherwise return the name without the mapped piece
			Set InternalName=$extract(InternalName,$length(p)+2,*)
			Set name = $translate(found_$translate(InternalName,"%","_"),"\","/")
			Continue
		}
		If (ext="DFI") {
			// expected format is <folderName>-<itemName>.<itemType>.DFI; will map to an external file named <folderName>/<itemName>.<itemType>.xml 
			// replace the first '-' with '/' to translate Item Folder into subfolder on disk and leave the other dashes as dashes; converts spaces to '_'
			Set name = $translate(found_$replace($translate(nam,"% ","__"),"-","/",1,1)_".xml","\","/")
			Continue
		}
		If ext="CLS"||(ext="PRJ")||(ext="PTD")||(usertype&&(##class(%RoutineMgr).UserType(InternalName))) {
			Set nam=$translate(nam,"%")
			Set noFolders = $get(^Sources(ext,"*","NoFolders"))
			If 'noFolders Set nam = $translate(nam,".","/")
			// If using sharded Production Exports, export code to /ptd subdirectory and use PTD naming conventions
			If ext = "PTD" {
				Do ##class(%Studio.SourceControl.Production).ParseInternalName(InternalName,noFolders,.filename)
				Set name = $translate(found_filename,"\","/")
				Continue
			}
			#; If match ends in '`' character use UDL/CLS format rather than XML format
			If $extract(found,*)="`" {
				Set name = $translate($e(found,1,*-1)_nam_".cls","\","/")
			} Else {
				Set name = $translate(found_nam_".xml","\","/")
			}
			Continue
		}
		If found["`" {
			Set found=$piece(found,"`")
			Set name = $translate($g(found)_$zconvert($tr(nam,"%","_"),"l")_"."_$zconvert(ext,"l"),"\","/")
			Continue
		}
		If default {
			Set name = $translate($g(found)_$tr(nam,"%.","_/")_"."_$s(ext="INC":"inc",ext="INT":"int",1:"rtn"),"\","/")
			Continue
		}
		Set name = $translate($g(found)_$tr(nam,"%","_")_"."_$s(ext="INC":"inc",ext="INT":"int",1:"rtn"),"\","/")
	} While 0
	// Replace characters reserved in Perforce filenames
	Set name = ..EncodeP4Filename($get(name))
	Return name
}

/// Takes a filename within the local Perforce workspace and returns a best guess as to the InternalName.
/// If the file exists then the method will attempt to open it to find the item name.  If it does not exist (or if it can't open it) then it will try to 
/// determine the item name based on the location in directory tree and the structure of the mappings in ^Sources.<p>
/// If no item in the database can be found to map to the external filename, then if it is a CCR enabled namespace it will return the path
/// translated into the /itemsetsourcelink(_*) import/export format. <p>
/// Unless <var>IgnorePercent</var> argument is set to 0, any %-items will return "".<p>
/// Unless <var>IgnoreNonexistent</var> argument is set to 0, if the item isn't found in the database, then "" will be returned.<p>
/// Known Limitations (if the physical file doesn't exist):
/// <ul>
/// <li>Due to this historical act of stripping '%' from the beginning of package names, if there exists both a %-item and a non-%-item which map to the same
/// location, then "" will be returned as the result is indeterminate without having access to the source file.</li>
/// <li>The method currently will not find matches for multi-tier mappings in ^Sources (e.g. <code>^Sources("HL7","*")="schema/hl7/"</code>, 
/// other than multi-tier mappings under /CSP/</li>
/// </ul>
ClassMethod InternalNameFromExtName(ExtName, IgnorePercent = 1, IgnoreNonexistent = 1) As %String
{
	If $data(^Sources)'=11 Write !,"^Sources is not set up so hooks will not work namespace: "_$namespace Quit ""
	Set InternalName=""
	// Undo encoding of reserved Perforce filename characters
	Set ExtName = ..DecodeP4Filename(ExtName)
	If (##class(%File).Exists(ExtName)) {
		New %SourceControl //don't trigger source hooks with this test load to get the Name
		Set sc=$system.OBJ.Load(ExtName,"-d",,.Name,1)
		If (($data(Name)=1) && ($get(Name) '= "")) || (($data(Name) = 11) && ($order(Name(""), -1) = $order(Name("")))) {
			//only set if a single Name was returned ... ignore multi-item files
			Set nam = $Piece(Name, ".", 1, *-1), ext = $ZCVT($Piece(Name, ".", *),"U")
			Set InternalName=nam_"."_ext
		}
	}
	If (InternalName="") {
		If ($ZCVT(ExtName,"U")'[$ZCVT($G(^Sources),"U")) {
			Quit ""	; file is not in ^Sources so translation cannot occur
		}
		Set name=$extract(ExtName,$length(^Sources)+1,*)
		Set name=$replace(name,"\","/")	; standardize slash direction
		If (name["/") {
			//file is in a subdirectory under the ^Sources root
			Set nam=$piece(name,"/",2,$length(name,"/")),extDir=$piece(name,"/")_"/"
			If nam="" Quit ""
		
			Set queryary=$query(^Sources(""),-1,dir), subscript=$qsubscript(queryary,1)
			While (queryary'="")&&(subscript'=0) {
				If (dir["/")&&(dir=extDir) {
					Set ext=subscript
					Quit
				}
				Set queryary=$query(@queryary,-1,dir)
				If (queryary="") {
					Quit
				}
				Set subscript=$qsubscript(queryary,1)
			}
		} Else {
			//there is no leading directory to remove 
			Set nam=name	
		}

		If ($get(ext)="/CSP/") {
			//loop through to find if any subscripts of /CSP/ match
			Set cspapp = $order(^Sources("/CSP/",""),-1,subdir)
			If (cspapp'="*"){
				Do {
					If $extract(name,1,$length(subdir))=subdir {
						Set InternalName=cspapp_$replace(name,subdir,"/")
						Quit
					}
					Set cspapp = $order(^Sources("/CSP/",cspapp),-1,subdir)
				} While cspapp'="*"
			}
			If InternalName="" {
				//Internal Name is just the remainder after the subdirectory was removed and the leading "/" is added back
				Set InternalName="/"_nam
			}
			If ($length(InternalName,"/")=2) {
				//this was a file dropped directly under /cspapp/ so treat it as a non-mapped file
				Set InternalName = ""
			}
		}
		Set fileExt=$zconvert($piece(nam,".",$length(nam,".")),"L")
		If (InternalName="")&&('$data(ext)=0)&&('$listfind($listbuild("xml","rtn","cls","mac"),fileExt)) {
			//no match found yet, and this is in a subdir for a specific document type (ext), however it is not in a typical export format
			//so treat it as a non-mapped file
			Kill ext			 	
		}
		If $data(ext)=0 {
			//there is no explicit mapping for this subdirectory, so it is externally managed
			//if an a CCR controlled namespace, then translate into /itemsetsetsourcelink format, otherwise quit null
			If ($get(^SYS("SourceControl","ItemSetConfig","Enabled"))) {
				Set ext= "/ItemSetSourceLink/"
				Set InternalName=ExtName
				Set sc=##class(%Studio.SourceControl.ItemSet).NameCVT(.InternalName)
			} Else {
				Quit ""
			}
		}
		If (InternalName="") {
			//take our best guess based on the document extension mapped to that subdirectory
			If ext = "PTD" {
				Do ##class(%Studio.SourceControl.Production).ParseExternalName(ExtName, .InternalName)
				Quit InternalName
			} Else {
				Set nam=$piece(nam,".",1,$length(nam,".")-1)
				Set nam=$translate(nam,"_/","%.")
				Set InternalName=nam_"."_ext
				If (ext="CLS") {	; special handling for possible collissions between % and non-% classes of the same name
					Set alternateInternalName="%"_InternalName
					Set primaryExists=##class(%RoutineMgr).Exists(InternalName), alternateExists=##class(%RoutineMgr).Exists(alternateInternalName)
					If ('primaryExists)&&(alternateExists) { Set InternalName=alternateInternalName }	; it must have been a %-class as one by that name exists
					If (primaryExists)&&(alternateExists) { Quit "" }	;indeterminate as the class exists in % and non-% form in the DB
				}
			}
		}
	}
	If ((IgnorePercent)&&($extract(InternalName)="%")) { Set InternalName = "" }	; don't return a result for % items if instructed to ignore them
	If ((IgnoreNonexistent)&&('##class(%RoutineMgr).Exists(InternalName))) { Set InternalName = "" }	; only return item names which exist in the DB
	Quit InternalName
}

/// Given a filename, returns a valid Perforce filename. </br>
/// Current subsitutions are:
/// <ul>
///  <li>'#' -> '~23~'</li>
///  <li>'@' -> '~40~'</li>
/// </ul>
ClassMethod EncodeP4Filename(filename As %String) As %String
{
	Set p4Filename = $replace(filename,"#","~23~")
	Set p4Filename = $replace(p4Filename,"@","~40~")
	Return p4Filename
}

/// Given a Perforce-compatible filename, returns filename without p4 reserved characters omitted. </br>
/// Current reserved characters are:
/// <ul>
///  <li>'~23~' -> '#'</li>
///  <li>'~40~' -> '@'</li>
/// </ul>
ClassMethod DecodeP4Filename(p4Filename As %String) As %String
{
	Set filename = $replace(p4Filename,"~23~","#")
	Set filename = $replace(filename,"~40~","@")
	Return filename
}

/// Disconnect from Perforce depot.
/// <p>Values for 'Level' parameter are:
/// <ul>
/// <li> 1: Instance is Disconnected but could connect at a future time (default) </li>
/// <li> 2: Instance is Permanently Disconnected (no plans of ever connecting to Perforce) </li> 
/// </ul>
ClassMethod Disconnect(Level As %Integer = 1) As %Status
{
	If (..Disconnected()=Level) Set err="Already disconnected" Write !,err Quit $$$ERROR($$$GeneralError,err)
	If $data(^Sources)'=11 Set err="^Sources is not set up so hooks will not work" Write !,err Quit $$$ERROR($$$GeneralError,err)
	If (Level'=1)&&(Level'=2) Set err="Illegal Value" Write !,err Quit $$$ERROR($$$GeneralError,err)
	Set ^SYS("SourceControl","Disconnected")=Level
	Set sc=##class(%Studio.SourceControl.Change).RefreshUncommitted(0,1)
	Write !,"Disconnected from source control now, changes will be remembered but no p4 commands issues"
	Quit $$$OK
}

/// Reconnect to the Perforce depot and mark all edited as edited.
ClassMethod Reconnect() As %Status
{
	If '..Disconnected() {
		Write !,"Already connected, nothing to do" 
		Set ^SYS("SourceControl","Disconnected")=0 ; ensure that Disconnected state is explicitly set to 0 as "" is interpretted as uninitialized
		Quit $$$ERROR($$$GeneralError,"Already connected")
	}
	If $data(^Sources)'=11 Write !,"^Sources is not set up so hooks will not work" Quit $$$ERROR($$$GeneralError,"^Sources is not set up so hooks will not work")
	Write !,"Reconnecting to source control"
	Kill args Set args($i(args))="info"
	Set sc=..SecureRunCmd("p4",.args) If $$$ISERR(sc) Write !,"Unable to contact Perforce, can not reconnect" Quit $$$ERROR($$$GeneralError,"Unable to contact Perforce, can not reconnect")
	Set rc=$$$OK
	Set query = ##class(%Library.ResultSet).%New("%DynamicQuery.SQL")
    Set qtext = "SELECT ItemFile From %Studio_SourceControl.Change Where P4Issued IS NULL AND Committed='0'"         
    Set sc = query.Prepare(qtext)
    Set sc = query.Execute()
    While (query.Next()) {
		Set filename=query.Get("ItemFile")
		Kill action, InternalName, user, source, updated, p4Issued
		Set sc=##class(%Studio.SourceControl.Change).GetUncommitted(filename, .action, .InternalName, .user, .source, .updated, .p4Issued)		
		Set file=..ExtName($G(InternalName))
		If file="" Continue
		Kill args Set args($i(args))=action,args($i(args))=filename
		Set sc=..SecureRunCmd("p4",.args)
		If $$$ISERR(sc) {
			Write !,"Problem with p4 "_action_" command for ",InternalName
			Do DisplayError^%apiOBJ(sc)
			If $length(rc)<8000 Set rc=$$$ADDSC(rc,sc)
			Continue
		}
		#; Connected mode is now storing record of Uncommitted Changes (except "delete" or "revert"), but marking the commands as having been issued to Perforce
		If (action="delete") {
			Set sc=##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,0,0,1) 
		} ElseIf (action="revert") { 
			#; revert the change from the uncommitted queue
			Set sc=##class(%Studio.SourceControl.Change).RemoveUncommitted(filename,0,1) 
		} Else {
			#; mark that this uncommitted item has had its p4 command issued
			Set sc=##class(%Studio.SourceControl.Change).UpdateUncommitted(filename,,,,,,1)						
		}
	}
	Set sc=##class(%Studio.SourceControl.Change).RefreshUncommitted(0,1)
	Set ^SYS("SourceControl","Disconnected")=0
	Write !,"Reconnected, changes to source files will cause p4 commands to be issued"
	Quit rc
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	Set Action=0,Target="",Msg="",Reload=0
	If Type=0 {
		Set menu=$piece(Name,",")
		If menu'="%SourceMenu",menu'="%SourceContext" Quit $$$OK
		Set name=$piece(Name,",",2)
		Set action=$case(name,"%CheckIn":-1,"%CheckOut":0,"%AddToSourceControl":1,"%GetLatest":3,"%UndoCheckout":4,"%Disconnect":5,"%Reconnect":6,"%DisconnectItem":-3,"%ReconnectItem":-4,"CCRControls":-5,"Diff":-6,"CCRFileHistory":-7,"CommitChanges":-8,:-2)
		If action=-2 Quit $$$OK
	} ElseIf Type=1 {
		Set action=Name
	}
	#; Output connection info on namespace change
	If (Type_","_Name) = "1,5" {
		Do ..OutputInfo()
	}
	#; Do not need source control when deleting an item that is not in source control
	If action=2 {
		Set insource=0
		For i=1:1:$length(InternalName,",") {
			Set item=$zstrip($piece(InternalName,",",i),"<>W") If item="" Continue
			If ..IsInSourceControl(item) Set insource=1
		}
		If 'insource Quit $$$OK
	}
	#; Default to displaying dialog if no Flags parameter defined as this is what previous source control did
	If '(..Disconnected() || ..DefaultCredentialsDefined()) {
		Do ..ValidatePerforceTicket()
	}
	Set ret=..GetCredentials(.p4user,.p4pass)
	If '..Disconnected(),'..DefaultCredentialsDefined(),'$data(%stP),(p4pass="") {
		If 'ret Write !,"NOTICE: There is no Perforce user currently defined"
		Set Msg="<Enter Perforce password for Perforce user '"_p4user_"' if you wish to proceed>"	
	}
	If action=-1 {
		Set Action=2
		Set Item=..Name(InternalName)
		Set Target="/isc/studio/templates/%25Studio.SourceControl.UI.cls?action=Checkin&item="_##class(%CSP.Page).EscapeURL(Item)_"&"
	} ElseIf action=-5 {
		Set Action=2
		Set Target="/isc/studio/templates/%25Studio.SourceControl.UI.cls"
	} ElseIf action=-6 {
		Set Action=2
		Set Target="/isc/studio/templates/%25Studio.SourceControl.UI.cls?action=Diff&file="_##class(%CSP.Page).EscapeURL(..ExtName(InternalName))_"&"
	} ElseIf action=-7 {
		Set Action=3
		Set Target=..GetHistoryLink(InternalName)
	} ElseIf action=-8 {  //CommitChange
		Set Action=2
		Set Target="/isc/studio/templates/%25Studio.SourceControl.UI.cls?action=Bundle"
	} ElseIf (action<3&&(action>-2))||(action=-3)||(action=-4) {
		#; Nothing to do if InternalName is excluded.
		If ..IsExcluded(InternalName) {
			Quit $$$OK
		}
		Set Action=$S(Msg'="":7,1:1)
		Set Target=$$$FormatMessage(,"%Studio",$case(action,-1:"CheckInDialog",0:"CheckOutDialog",1:"AddDialog",2:"RemoveDialog",-3:"DisconnectItemDialog",-4:"ReconnectItemDialog"),,InternalName)
		///for field systems, add additoinal warning on CheckOut if this is any environment other than TEXT
		Set env=$G(^SYS("SourceControl","ItemSetConfig","Environment"))
		If (action=0)&&((env="TEST")||(env="UAT")||(env="LIVE")) {
			Set warning="WARNING:  Changes to '"_env_"' should only be made for critical debug purposes and then reverted"_$C(13,10)
			Set warning=warning_$C(9)_"All permanent changes must originate in 'BASE' and be progressed via Perforce"_$C(13,10,13,10)
			Set Target=warning_Target			
		}
	} ElseIf Msg'="",Type=0,(action=3)||(action=4)||(action=6) {
		// selected action requires p4 password to be set, so prompt
		Set Action=7
		Set Target="Perforce password required to proceed"
	} ElseIf (Type=0)&&(action=4) {
		Set Action=1
		Set Target="Do you really wish to revert "_InternalName_"? All changes since checkout will be lost."
	} ElseIf (Type=1)&&(action=6){
		set nl = $l(InternalName,",")
		for il=1:1:nl {
			set sName = $p(InternalName,",",il)
			If ..IsExcluded(InternalName) {
				continue
			}
			do ..CheckOut(sName,"Import")
		}		
	} Else {
		Quit ..AfterUserAction(0,Name,InternalName,1,,.Reload)
	}
	#; Replace Perforce password prompt with new CSP version (avoiding password in clear text on screen)
	If (Action = 7) {
		Set Action = 2
		Set url = "/isc/studio/templates/%25Studio.SourceControl.UI.cls?action=Login"_
			"&message="_$ZConvert(Target,"O","URL")
		Set Target = url
		Set Msg = ""
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
		Set action=$case(name,"%CheckIn":-1,"%CheckOut":0,"%AddToSourceControl":1,"%GetLatest":3,"%UndoCheckout":4,"%Disconnect":5,"%Reconnect":6,"%DisconnectItem":-3,"%ReconnectItem":-4,"CCRControls":-5,"Diff":-6,"CCRFileHistory":-7,"CommitChanges":-8,:-2)
		If action=-2 Quit $$$ERROR($$$StudioSourceActionInvalid,Name,InternalName)
	} ElseIf Type=1 {
		Set action=Name
	}
	If Answer'=1 Quit $$$OK
	If action=5 Quit ..Disconnect()
	If action=6 Quit ..Reconnect()
	Set sc=$$$OK
	For i=1:1:$length(InternalName,",") {
		Set item=$zstrip($piece(InternalName,",",i),"<>W") If item="" Continue
		Set rc=$$$OK
		If action=-1 Set rc=..CheckIn(item,Msg)
		If action=0 Set rc=..CheckOut(item,Msg)
		If action=1 {
			If $IsObject($Get(%SourceControl)) {
				Kill %SourceControl.Modified
				Set %SourceControl.Modified=1
			}
			Set rc=..AddToSourceControl(item,Msg)
			If $IsObject($Get(%SourceControl)) &&
			  $Get(%SourceControl.Modified($Piece(item,".",1,*-1)_"."_$zcvt($Piece(item,".",*),"U")))=1 {
				Set Reload=1
			}
		}
		If action=2 Set rc=..RemoveFromSourceControl(item,Msg)
		If action=3 Set rc=..GetLatest(item)
		If action=4 && (Answer = 1) Set Reload=1,rc=..UndoCheckout(item)
		If action=-3 Set Reload=1,rc=..DisconnectItem(item)
		If action=-4 Set Reload=1,rc=..ReconnectItem(item)
		If $$$ISERR(rc) {
			//if it was a password related error, kill session variable and clear out the stored ticket
			If (rc["P4PASSWD")||(rc["was logged out") {
				Kill %stP
				Do ..ClearPerforceTicket()
			}
			Set sc=$$$ADDSC(sc,rc)
		}
	}
	Quit sc
}

Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Set menu=$piece(MenuName,","),name=$piece(MenuName,",",2)
	If menu'="%SourceMenu",menu'="%SourceContext" Quit $$$OK
	If InternalName'="" {
		Set sc=..GetStatus(InternalName,.isinsourcecontrol,.editable,.ischeckedout)
		If $$$ISERR(sc) Quit sc
	}
	Set isinsourcecontrol=+$get(isinsourcecontrol),editable=+$get(editable),ischeckedout=+$get(ischeckedout)
	
	// Determine special source control menu options for Production Decomposition
	Set isDecompProd = 0, hasProdChanges = 0
	If ..IsDecomposedProduction(InternalName,,"CLS") {
		Set isDecompProd = 1
		Set productionName = $Piece(InternalName, ".", 1, *-1)
		Do ##class(%Studio.SourceControl.Production).GetUserProductionChanges(productionName,.changes)
		If $Data(changes) {
			Set hasProdChanges = 1
		}
	}
	
	If name="%CheckOut" {
		If isDecompProd Set Enabled = 0					; Do not check out a Production Class if decomposing Productions
		If ('editable)&&(ischeckedout) Set Enabled=0	; InternalName is checked out by a different user
		If ischeckedout||('isinsourcecontrol) Set Enabled=0
		If InternalName="" Set Enabled=0
		If ..ItemLocked(InternalName) Set Enabled=0
	} ElseIf name="%CheckIn" {
		If ('editable)&&(ischeckedout) Set Enabled=0	; InternalName is checked out by a different user
		If ('isDecompProd)&&('isinsourcecontrol||('ischeckedout)) Set Enabled=0
		If isDecompProd&&'hasProdChanges Set Enabled = 0
		If InternalName="" Set Enabled=0
		If ..Disconnected() Set Enabled=0
		If (..Disconnected()=2) Set Enabled=-1 ; Permanently Disconnected don't need to see this menu option
		If ..ItemLocked(InternalName) Set Enabled=0
	} ElseIf name="%UndoCheckout" {
		// Enable if any individual items composing a given Production are checked out when using Production Decomposition
		If isDecompProd {
			If 'hasProdChanges Set Enabled=0		
		} Else {
			Set filename=..ExternalName(InternalName)
			If ##class(%Studio.SourceControl.Change).IsUncommitted(filename) {
				Set sc=##class(%Studio.SourceControl.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
				If tAction="add" { Set DisplayName=$$FormatMessage^%occMessages(,"%Studio","%UndoAdd","Undo Add") }
			}	
			If ('editable)&&(ischeckedout) Set Enabled=0	; InternalName is checked out by a different user
			If 'isinsourcecontrol||('ischeckedout) Set Enabled=0
		}
		If InternalName="" Set Enabled=0
		If ..ItemLocked(InternalName) Set Enabled=0
	} ElseIf name="%GetLatest" {
		If ('editable)&&(ischeckedout) Set Enabled=0	;InternalName is checked out by a different user
		If ischeckedout||('isinsourcecontrol) Set Enabled=0
		If isDecompProd Set Enabled=0
		If InternalName="" Set Enabled=0
		If ..Disconnected() Set Enabled=0
		If (..Disconnected()=2) Set Enabled=-1 ; Permanently Disconnected don't need to see this menu option
		If ..ItemLocked(InternalName) Set Enabled=0
	} ElseIf name="%AddToSourceControl" {
		If isDecompProd Set Enabled = 0
		If ('editable)&&(ischeckedout) Set Enabled=0	;InternalName is checked out by a different user
		If isinsourcecontrol||(InternalName="")||(..Name(InternalName)="") Set Enabled=0
		If InternalName="" Set Enabled=0
		If ..ItemLocked(InternalName) Set Enabled=0
	} ElseIf name="%Disconnect" {
		If (..Disconnected())||(..IsSharedDevInstance())  Set Enabled=0
		If (..Disconnected()=2) Set Enabled=-1	; don't show the menu item for a Permanently Disconnected instance
	} ElseIf name="%Reconnect" {
		If ('..Disconnected()||(..Disconnected()=2)||(..IsSharedDevInstance())) Set Enabled=0
		If (..Disconnected()=2) Set Enabled=-1	; don't show the menu item for a Permanently Disconnected instance
	} ElseIf name="%DisconnectItem" {
		If InternalName="" {
			Set Enabled=-1
		} ElseIf $get(^Sources(0,"Disconnected",InternalName)) {
			Set Enabled=0
		} ElseIf 'isinsourcecontrol {
			Set Enabled=-1
		}
	} ElseIf name="%ReconnectItem" {
		Set Enabled=0
		If InternalName="" {
			Set Enabled=-1
		} ElseIf $get(^Sources(0,"Disconnected",InternalName)) {
			Set Enabled=1
		} ElseIf 'isinsourcecontrol {
			Set Enabled=-1
		}
	} ElseIf name="CCRControls" {
		Set DisplayName="Show CCR Controls"
		If '$get(^SYS("SourceControl","ItemSetConfig","Enabled")) {	
			Set Enabled=-1 ; don't show the menu item unless this is a CCR client (Connected or Disconnected)
		}
	} ElseIf name="CommitChanges" {
		Set DisplayName="Commit Changes via ItemSet"
		If '(..Disconnected()=2) {
			Set Enabled=-1 ; don't show the menu item unless Permanently Disconnected
		}
	} ElseIf name="CCRFileHistory" {
		Set DisplayName="Show CCR File History"
		If '$get(^SYS("SourceControl","ItemSetConfig","Enabled")) || (InternalName = "") {
			Set Enabled=-1 ; don't show the menu item unless this is a CCR client (Connected or Disconnected)
		}
	} ElseIf name="Diff" {
		Set DisplayName="Diff Against Last Version"
		If ('ischeckedout) Set Enabled=0
		If (('isinsourcecontrol)&&('ischeckedout))||(InternalName="")||(..Name(InternalName)="") Set Enabled=0	; if isinsourcecontrol=0 and ischeckedout=1 then it is checked out by another person (so diff should be allowed) 
	}
	Quit $$$OK
}

/// ** DEPRECATED - Use the more secure <method>SecureP4Cmd</method>.
/// Passed a 'p4' command, it runs it with '-ztag' and returns the parsed output
ClassMethod P4Cmd(cmd As %String, Output output As %String) As %Status [ Deprecated ]
{
	Kill out
	Set sc=..RunCmd("p4 -ztag "_cmd,.in,0,1)
	If $$$ISERR(sc) Quit sc
	Set output=1,sc=$$$OK,lastLineWasNonField=0
	
	If in.Size>0 {
		Do in.Rewind()
		While 'in.AtEnd {
			Set line=in.ReadLine()
			If ($extract(line,1,4)'="... ") {
				Set lastLineWasNonField=1
				Continue
			} ElseIf (lastLineWasNonField) {
				Set lastLineWasNonField=0
				//ztag record separators are newline characters, which can also be contained in a multiline field (like Changelist Description)
				//If the current field is already filled for the current record, assume we're now processing the next record
				If $data(output(output,$piece($extract(line,5,*)," "))) Set output=output+1
			} 
			Set line=$extract(line,5,*)
			Set key=$piece(line," ")
			Set value=$piece(line," ",2,*)
			Set output(output,key)=value
		}
	}
	If '$data(output(output)) Set output=output-1
	Quit sc
}

/// Passed a 'p4' by reference list of arguments in <var>args</var>, it runs 'p4' with '-ztag' and returns the parsed output
ClassMethod SecureP4Cmd(ByRef args, Output output As %String) As %Status
{
	Kill out
	Set newargs($i(newargs))="-ztag"
	For i=1:1:args Set newargs($i(newargs))=args(i)
	Set sc=..SecureRunCmd("p4",.newargs,.in,0,1)
	If $$$ISERR(sc) Quit sc
	Set output=1,sc=$$$OK,lastLineWasNonField=0
	
	If in.Size>0 {
		Do in.Rewind()
		While 'in.AtEnd {
			Set line=in.ReadLine()
			If ($extract(line,1,4)'="... ") {
				Set lastLineWasNonField=1
				Continue
			} ElseIf (lastLineWasNonField) {
				Set lastLineWasNonField=0
				//ztag record separators are newline characters, which can also be contained in a multiline field (like Changelist Description)
				//If the current field is already filled for the current record, assume we're now processing the next record
				If $data(output(output,$piece($extract(line,5,*)," "))) Set output=output+1
			} 
			Set line=$extract(line,5,*)
			Set key=$piece(line," ")
			Set value=$piece(line," ",2,*)
			Set output(output,key)=value
		}
	}
	If '$data(output(output)) Set output=output-1
	Quit sc
}

/// This method will accept a Perforce password and will attempt to generate a Perforce ticket tied to this server for use within the hooks.  
/// In the process it will validate a ticket which may already be set, and if it is valid it will keep that ticket.
ClassMethod GeneratePerforceTicket(p4pass As %String = "", ByRef p4ticket As %String) As %Status
{
	//Validate ticket. This tries to log in without a password.
	Set sc = ..ValidatePerforceTicket()
	//If invalid, try to log in with p4pass
	If ($$$ISERR(sc)) {	
		//If not valid, try to get a new one.
		Set file=##class(%Library.FileCharacterStream).%New()
		$$$QuitOnError(file.WriteLine(p4pass))
		$$$QuitOnError(file.%Save())
		Set file.RemoveOnClose = 1
		Set args($i(args))="-s",args($i(args))="login",args($i(args))="-p"
		Set sc=..SecureRunCmd("p4",.args,.out,0,,file.Filename)	//don't display the output since it includes the password in plain text
		/* expected output of 'out' for correct login (incorrect returns sc as an error):
			out=3
			out(1)="Enter password: "
			out(2)="info: 1F312B20CBC503C72DDA242EB267D2AE"
			out(3)="exit: 0"	
		*/
		If ($$$ISOK(sc))&&($get(out)>0) {
			Set i="", i=$order(out(i),1,line)
			While ((line'["info: ")&&(line'["error: ")) {
				Set i=$order(out(i),1,line)
				If i="" Quit
			}
			if (line["info: ") {
				Set ticket=$piece(line,"info: ",2)
				If (..StorePerforceTicket(ticket)) {
					Set sc=..ValidatePerforceTicket()
					Set p4ticket = ticket
				}
			} elseif (line ["error: ") {
				Set:..ClearPerforceTicket() sc=$$$ERROR($$$GeneralError,$piece(line,"error: ",2))
			} else {
				Set sc=$$$ERROR($$$GeneralError,"Perforce output does not include 'info' or 'error' line")
			}
		} Else {
			Set:..ClearPerforceTicket() sc=$$$ERROR($$$GeneralError,"Error: Perforce username and/or password is incorrect")
		}
	}
	Quit sc
}

/// Validate a ticket and return the amount of time remaining for that ticket.
/// If the ticket is not valid it will clear it from the credential store since it is of no use.
ClassMethod ValidatePerforceTicket(ByRef timeRemaining As %String) As %Status
{
	//Determine expiration date/time.
	Set args($i(args))="login",args($i(args))="-s"
	Set sc = ..SecureRunCmd("p4",.args,.out,0)
	If ($$$ISOK(sc)) {
		Set ret=..GetCredentials(.p4User)
		If ($g(out(1)) [ "User "_p4User_" ticket ") {
			Set timeRemaining = $piece(out(1),"expires in ",2)
		} Else {
			//Didn't get expected response...
			Set sc = $$$ERROR($$$GeneralError,"Ticket didn't have expiration date, or something else unexpected happened.")
		}
	} Else {
		Do ..ClearPerforceTicket()
	}
	Quit sc
}

/// Stores a Perforce ticket for future use by the current user
ClassMethod StorePerforceTicket(ticket As %String = "") As %Boolean
{
	If (..GetCredentials(.p4user)) {
		Quit ..SetCredentials($listbuild($USERNAME,p4user),ticket)
	} Else {
		Quit 0
	}
}

/// Clears out a stored Perforce ticket which may be stored for the current user
ClassMethod ClearPerforceTicket() As %Boolean
{
	Kill %stP
	If (..GetCredentials(.p4user)) {
		Quit ..SetCredentials($listbuild($USERNAME,p4user),"")
	} Else {
		Quit 0
	}
}

/// Add the specified items to source control
ClassMethod AddItemsToSourceControl(ByRef items) As %Status
{
	Set sc = $$$OK

	// If any items were specified in list for, add those
	If $L($G(items)) {	
		For i=1:1:$L(items,",") {
			Set item = $P(items,",",i)
			Set items(item)=""
		}
	}
	
	Set isc = ..%New("")
	Set item = ""
	For {
		Set item = $O(items(item))
		Quit:item=""
		
		// This will do an Export/P4 Add for any items that are NOT already in source control
		Set sc2=isc.AddToSourceControl(item)
		
		// Build up a list of errors for the caller
		Set:$$$ISERR(sc2) sc=$$$ADDSC(sc,sc2)
	}
	
	Quit sc
}

/// Add the specified classes to source control
ClassMethod AddClassesToSourceControl(classes As %String) As %Status
{
	For i=1:1:$L(classes,",") {
		Set cls = $P(classes,",",i)
		Set classes(cls_".cls")=""
	}
	
	Quit ..AddItemsToSourceControl(.items)
}

/// Add the specified package(s) to source control
ClassMethod AddPackagesToSourceControl(packages As %String) As %Status
{
	For i=1:1:$L(packages,",") {
		Set package=$P(packages,",",i)
		Do $system.OBJ.GetPackageList(.classes,package,"ars")
		
		Set cls=""
		For {
			Set cls = $O(classes(cls))
			Quit:cls=""
			
			Set items(cls_".cls")=""
		}
	}
	
	Quit ..AddItemsToSourceControl(.items)
}

/// Returns value that shows whether or not this instance is "Disconnected" from Perforce.
/// <p>Return values are:
/// <ul>
/// <li> 0: Instance is Connected</li>
/// <li> 1: Instance is Disconnected but could connect at a future time</li>
/// <li> 2: Instance is Permanently Disconnected (no plans of ever connecting to Perforce) </li> 
/// </ul>
ClassMethod Disconnected() As %Integer [ CodeMode = expression ]
{
$get(^SYS("SourceControl","Disconnected"))
}

/// Returns value that shows whether or not this instance is "Locked".
/// <p>Return values are:
/// <ul>
/// <li> "": Instance has never been Locked or Unlocked (default)</li>
/// <li> 0: Instance is Unlocked</li>
/// <li> 1: Instance is Locked</li>
/// <li> 2: Instance is AdminLocked</li> 
/// </ul>
/// <p>When the instance is Locked or AdminLocked, no changes can be made via Studio.  It is possible to change from Locked to NotLocked via different UIs.
/// When an instance is AdminLocked it should only be possible to unlock it via the <method>Unlock</method> method.
ClassMethod Locked() As %String [ CodeMode = expression ]
{
$get(^SYS("SourceControl","Locked"))
}

/// Returns 1 if <var>InternalName</var> is Locked for one of the following reasons:
/// <ul>
/// <li>It has a LockPackage directive in ^Sources</li>
/// <li>The Namespace is Locked, and there is no BypassLock directive in ^Sources</li>
/// <li>Items Mapped from another Namespace are Locked, and there is no BypassLock directive in ^Sources</li>
/// </ul>
/// <var>Reason</var> will include a string describing why it is locked
ClassMethod ItemLocked(InternalName, ByRef Reason) As %String
{
	Set Reason = ""
	If (..Locked()&&'..HasSourceDirective(InternalName,"BypassLock"))&&'$get(^IRIS.Temp("sscProd",$job,"bypassLock")) {
		Set Reason = "Namespace is LOCKED"
		Quit 1
	}
	If (..HasSourceDirective(InternalName,"LockPackage")) {
		Set Reason = "Package is LOCKED"
		Quit 1
	}
	If ($get(^SYS("SourceControl","Misc","LockMapped")))&&(..IsMapped(InternalName)&&'..HasSourceDirective(InternalName,"BypassLock")) {
		Set Reason = "Item is LOCKED due to being mapped from another Namespace"
		Quit 1
	}
	Set ext = $Piece(InternalName, ".", *)
	Quit 0
}

/// Lock the source control hooks for this instance.
/// <p>The default setting will be "Locked".  Passing a '1' for the Admin parameter will set the instance to AdminLocked. 
/// <p>See <method>Locked</method> for more details.
ClassMethod Lock(Admin As %Boolean = 0) As %Status
{
	Set ^SYS("SourceControl","Locked")=$select(Admin:2,1:1)
	Quit $$$OK
}

/// Unlock the source control hooks for this instance.
ClassMethod Unlock() As %Status
{
	Set ^SYS("SourceControl","Locked")=0
	Quit $$$OK
}

/// Accessor method for accessing Perforce Credentials for current $USERNAME; returns false if no credentials were available.
/// <ul>
/// <li>If there is a user-specific set of credentials defined for the current $USERNAME, these credentials will be returned</li>
/// <li>If a SharedWorkspace has been defined but there are no credentials for the current $USERSAME, then $USERNAME is returned as p4user assuming it's not a shipped username
/// <li>If a SharedWorkspace has been defined, then it will be returned in the p4workspace parameter; otherwise the workspace for the credential set will be returned</li>
/// <li>If credentials exist for this specific $USERNAME, then p4passwd is returned from the the current studio process (the password stored in credentials is ignored)</li>
/// <li>If there is no data at all in ^%SYS("SourceControl","Credentials"), then the method returns 'true', assuming the Environment variables are used to store the credentials</li>
/// </ul>
ClassMethod GetCredentials(ByRef p4user As %String, ByRef p4passwd As %String, ByRef p4workspace As %String, ByRef p4dir As %String, ByRef p4port As %String) As %Boolean
{
	Set defaultUsernames=$listbuild("_SYSTEM","irisusr","_system","Admin","CSPSystem","SuperUser","UnknownUser")
	Set login=$G(^%SYS("SourceControl","Credentials", $USERNAME),$G(^%SYS("SourceControl","Credentials"),$G(^%SYS("SourceRoot",0))))

	// Add login information, if given
	Set p4user = $LG(login,1)
	If ((p4user = "")&&(..GetSharedWorkspace())&&('$listfind(defaultUsernames,$USERNAME))) {
		// user not explicitly defined and this is a Multi-Developer environment; assuming $USERNAME is also Perforce username and password is coming from Studio prompt
		Set p4user = $USERNAME
		Set p4passwd = $System.Encryption.Base64Decode($G(%stP))
	}
	If $get(p4passwd) = "" {
		Set p4passwd = $select($listget(login,2)'="":$listget(login,2),
						$data(%stP):$System.Encryption.Base64Decode($G(%stP)),1:"")
	}
	Set p4workspace = $select(..GetSharedWorkspace(.p4workspace):p4workspace,$listget(login,3)'="":$LG(login,3),1:"")
	Set p4dir = $select(..GetSharedWorkspace("",.p4dir):p4dir,$listget(login,4)'="":$listget(login,4),1:"")
	Set p4port = $LG(login,5)
	
	#; in check for returning valid credentials, set to true if no credential global nodes are set
	Set ret=(p4user'="")||('$D(^%SYS("SourceControl","Credentials")))
	Quit ret
}

/// Accessor method for setting Perforce Credentials, returns false if credentials could not be set.
/// <ul>
/// <li>If p4user is passed as a string, then it (along with the other arguments) will be the default for this instance</li>
/// <li>If p4user is of the form $LB(cacheUser, p4user), then p4user only be used when $USERNAME=cacheUser, and all other arguments will be ignored.  
///   The workspace details should be set via SetSharedWorkspace(), and the user will be prompted for the p4passwd value at runtime</li>
/// <li>If p4user is "" , then the default credentials will be cleared</li>
/// <li>If p4user is of the form $LB(cacheUser,""), then the perforce username for cacheUser will be cleared</li>
/// </ul>
ClassMethod SetCredentials(p4user As %String = "", p4passwd As %String = "", p4workspace As %String = "", p4dir As %String = "", p4port As %String = "") As %Boolean
{
	If $listvalid(p4user)&&($listlength(p4user)=2) {
		#; set up a perforce username assigned to this $USERNAME
		Set cacheuser=$listget(p4user,1), p4user=$listget(p4user,2)
		If p4user="" {
			Kill ^%SYS("SourceControl","Credentials", cacheuser)
		} Else {
			Set credentials = $LB(p4user,p4passwd)
			Set oldp4port = $listget($Get(^%SYS("SourceControl","Credentials", cacheuser)),5)
			If (p4port '= "") {
				Set credentials = credentials_$lb(,,p4port)
			} ElseIf (oldp4port '= "") {
				Set credentials = credentials_$lb(,,oldp4port)
			}
			Set ^%SYS("SourceControl","Credentials", cacheuser) = credentials
		}
	} Else {
		#; set default login (used most often in non-shared development environments)
		Set login=$S(p4user="":"",1:$LB(p4user,p4passwd,p4workspace,p4dir,p4port))
		If (login="") {
			ZKill ^%SYS("SourceControl","Credentials")		//just kill this node but not its subordinates
		} Else {
			Set ^%SYS("SourceControl","Credentials")=login	
		}
	}
	Quit 1
}

/// Method returns true if there are default perforce credentials defined, and false otherwise.<p>
/// NOTE - if there is no credentials data stored at all, the the assumption is made that this is a 
/// single-user system that relies on environment variables for Perforce access, and 'true' will be returned
/// so that the user will not be prompted for credentials or told that none are defined.  Credentials
/// must be stored entirely in environment variables, or entirely in the DB for a given instance.
ClassMethod DefaultCredentialsDefined() As %Boolean [ CodeMode = expression ]
{
($get(^%SYS("SourceControl","Credentials"),$get(^%SYS("SourceRoot",0)))'="")||('$D(^%SYS("SourceControl","Credentials")))
}

/// Accessor method to get the Perforce Shared Workspace if it is defined; if it is not defined, the method returns false.
/// If this method returns false, then the assumption should be made that this is a single-developer instance (not shared by multiple developers).
/// <P>The method will check for the existence of a namespace-specific workspace, and will use that if it exists.  If a namespace
/// specific workspace is not defined, then it will look for an instance-wide Shared Workspace.
/// <P>This also allows a user to retrieve the stored alternate workspace directory root (-d flag in P4)
ClassMethod GetSharedWorkspace(ByRef p4workspace As %String, ByRef p4directory As %String) As %Boolean
{
	Set p4workspace=$get(^%SYS("SourceControl","SharedWorkspace",$Namespace),$Get(^%SYS("SourceControl","SharedWorkspace")))
	Set p4directory=$get(^%SYS("SourceControl","SharedWorkspace","AlternateDirectory",$Namespace),$Get(^%SYS("SourceControl","SharedWorkspace","AlternateDirectory")))
	Quit ''$data(^%SYS("SourceControl","SharedWorkspace"))
}

/// Accessor method for setting Perforce Shared Workspace; returns false if credentials could not be set.
/// <P>If the <var>namespace</var> argument is not passed, then the values will be set for the entire instance.  
/// If it is passed, then the workspace and alternate workspaace directory root will be used just for that specified workspace. 
/// <P>This also allows a user to set the alternate workspace directory root (-d flag in P4).
/// <P><Strong>Important Note:</Strong> Passing <var>p4workspace</var> as "" will clear out all of the shared worspace settings, and will merge them
/// into <code>^%SYS("SourceControl","PriorSharedWorkspace")</code> for future reference.
ClassMethod SetSharedWorkspace(p4workspace As %String = "", p4directory As %String = "", namespace As %String = "") As %Boolean
{
	If p4workspace="" {
		Merge ^%SYS("SourceControl","PriorSharedWorkspace") = ^%SYS("SourceControl","SharedWorkspace")
		Kill ^%SYS("SourceControl","SharedWorkspace")
	} Else {
		//NOTE - it is not supported to define a namespace-specific Perforce workspace for a namespace called "AlternateDirectory" 
		If (namespace = "") {
			// If setting instance-wide shared workspace, store for reference then delete namespace-specific nodes
			Merge ^%SYS("SourceControl","PriorSharedWorkspace") = ^%SYS("SourceControl","SharedWorkspace")
			Kill ^%SYS("SourceControl","SharedWorkspace")
			Set ^%SYS("SourceControl","SharedWorkspace")=p4workspace
			Set ^%SYS("SourceControl","SharedWorkspace","AlternateDirectory")=p4directory
		} Else {
			Set ^%SYS("SourceControl","SharedWorkspace",namespace)=p4workspace
			Set ^%SYS("SourceControl","SharedWorkspace","AlternateDirectory",namespace)=p4directory
		}
	} 
	Quit 1
}

/// Indicates whether or not this instance is configured to accomodate multiple concurrent developers<br/>
/// It is considered a Shared development instance if one of the following is true:</br>
/// <UL>
/// <LI>This is a Connected instance and there is a Shared Workspace defined for this instance or namespace</LI>
/// <LI>This is a Permanently Disconnected Namespace (Permantently Disconnected means it is outside the InterSystems network and we always assume Shared)</LI>
/// </UL>
ClassMethod IsSharedDevInstance() As %Boolean [ CodeMode = expression ]
{
(('..Disconnected())&&..GetSharedWorkspace())||(..Disconnected()=2)
}

/// Disconnect this document from source control
ClassMethod DisconnectItem(InternalName As %String) As %Status
{
	If $get(^Sources(0,"Disconnected",InternalName)) {
		Quit $$$ERROR($$$GeneralError,"Unable to disconnect an item that is already disconnected from source control")
	}
	Set filename=..ExtName(InternalName)
	If filename="" Quit $$$ERROR($$$GeneralError,"No external file found for '"_InternalName_"' so can not disconnect")
	If '##class(%File).Exists(filename) Quit $$$ERROR($$$GeneralError,"File "_filename_" not found, so nothing to disconnect")
	Kill ^Sources(0,"FileTimeStamp",InternalName)
	Kill ^Sources(0,"ItemTimeStamp",InternalName)
	Set ^Sources(0,"Disconnected",InternalName)=1
	Write !,"Item '",InternalName,"' disconnected from source control file '",filename,"'"
	Quit $$$OK
}

/// Reconnect this document from source control
ClassMethod ReconnectItem(InternalName As %String) As %Status
{
	If '$get(^Sources(0,"Disconnected",InternalName)) {
		Quit $$$ERROR($$$GeneralError,"Unable to reconnect an item that is not disconnected from source control")
	}
	Kill ^Sources(0,"Disconnected",InternalName)
	Set filename=..ExtName(InternalName)
	If filename="" Quit $$$ERROR($$$GeneralError,"No external file found for '"_InternalName_"' so can not reconnect")
	If '##class(%File).Exists(filename) Quit $$$ERROR($$$GeneralError,"File "_filename_" not found, so nothing to reconnect")
	Write !,"Item '",InternalName,"' reconnected to source control file '",filename,"'"
	Quit ..Load(InternalName)
}

ClassMethod IsGenerated(InternalName As %String) As %String
{
	If $get(^Sources(0,"Disconnected",InternalName)) Quit 1
	Quit ""
}

/// Return true if this item is mapped from a database other than the default routine database.
/// Also return the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String)
{
	Quit ##class(%RoutineMgr).IsMapped(name,.sourcedb)
}

/// Return %Boolean indicating if given datbase is read only.
/// dbUCI is expected to be a string of the database .dat directory.
ClassMethod IsDBReadOnly(dbDir As %String) As %Boolean
{
	New $Namespace
	Set $Namespace = "%SYS"
	Set dbObj = ##class(SYS.Database).%OpenId(dbDir)
	Return dbObj.ReadOnly
}

/// Returns 1 if <var>InternalName</var> has the specific Source Control <var>Directive</var> in the ^Sources global <br/>
/// Current directives include:
/// <UL>
/// <LI>Exclude - used to exclude a specific item from all source controls i.e. act as though source control is in no way enabled for that package</LI>
/// <LI>LockPackage - used to prevent a specific package from being changed in any way, i.e. a package-specific source control lock</LI>
/// <LI>BypassLock - used to allow a specific package to bypass a Namespace-wide source control lock, i.e. allow a Namespace where only select packages can be edited
///   In addition, BypassLock will allow a specific package to bypass the LockMapped=1 setting which typically treats items mapped from another Namespace as Readonly</LI>
/// <LI>ExcludeDecomposeProduction - used to exclude a specific interoperability production from being stored in source control as decomposed production items</LI>
/// <LI>BaselineInclude - overrides Baseline Export exclusion filters to export custom Tier 1 items normally not exported</LI>
/// <LI>BaselineExclude - overrides Baseline Export behavior to exclude Tier 1 items from a Baseline that would normally be exported</LI>
/// </UL>
/// Example settings would be:<br/>
/// <code>^Sources("DFI","*","Exclude") = 1</code> - exclude any DeepSee Folder Items from Source Control <br/> 
/// <code>^Sources("CLS","HS.Local.SDA3","LockPackage") = 1</code> - Prevent HS.Local.SDA3.* from being edited in the Namespace, for when it is managed in it's own System from another mapped Namespace <br/> 
/// <code>^Sources("CLS","HS.Local.SDA3","BypassLock") = 1</code> - Allow HS.Local.SDA3.* to be edited in a Namespace where ^SYS("SourceControl","Locked")=1<br/>
/// <code>^Sources("CLS","Foo","IncludeBaseline") = 1</code> - Include Foo.* classes in Baseline Export even if default filters would exclude them.<br/>
/// <code>^Sources("CLS","Foo.Bar","IncludeBaseline") = 0</code> - Do not apply BaselineInclude Source Directive to Foo.Bar.* classes.<br/>
ClassMethod HasSourceDirective(InternalName As %String, Directive As %String) As %Boolean
{
	Quit:InternalName="" 0
	Set nam=$p(InternalName,".",1,$l(InternalName,".")-1),ext=$p(InternalName,".",$l(InternalName,".")),ext=$zcvt(ext,"u")
	If (InternalName [ "/") {
		Set ext = "/CSP/"
		Set delim = "/"
	} Else {
		Set delim = "."
	}

	// First pass: check for directive.
	Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $Piece(nam,delim,1,$length(p,delim))=p,$data(^Sources(ext,p)) Quit
	If (p '= "") && ($data(^Sources(ext,p,Directive),directiveFound)#2) && directiveFound {
		Quit 1
	}

	// Second pass: find mapping. (This may be at a less specific level than exclusion.)
	Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $Piece(nam,delim,1,$length(p,delim))=p,($data(^Sources(ext,p),found)#2) Quit

	// If using default mapping, check for default-level exclusion.
	If ($data(found)=0) && ($data(^Sources(ext,"*",Directive),directiveFound)#2) && directiveFound {
		Quit 1
	}
	Quit 0
}

/// Returns 1 if a given Source Directive is in use.
ClassMethod SourceDirectiveExists(directive As %String) As %Boolean
{
	// walk ^Sources to look for given Source Directive, quit once found or top node is null or 0
	Set node1 = $order(^Sources(""),-1)
	While '((node1 = 0) || (node1 = "")) {
		Set node2 = $order(^Sources(node1, ""))
		While node2 '= "" {
			If $data(^Sources(node1,node2,directive)) Return 1
			Set node2 = $order(^Sources(node1,node2))
		}
		Set node1 = $order(^Sources(node1),-1)
	}
	Return 0
}

/// Returns 1 if InternalName is excluded from source control
ClassMethod IsExcluded(InternalName As %String) As %Boolean
{
	Set nam=$p(InternalName,".",1,*-1),ext=$p(InternalName,".",*),ext=$zcvt(ext,"u")
	If (InternalName [ "/") {
		Set ext = "/CSP/"
		Set delim = "/"
	} Else {
		Set delim = "."
	}

	// First pass: check for exclusion.
	Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $Piece(nam,delim,1,$length(p,delim))=p,$data(^Sources(ext,p)) Quit
	If (p '= "") && ($data(^Sources(ext,p,"Exclude"),exclude)#2) && exclude {
		Quit 1
	}

	// Second pass: find mapping. (This may be at a less specific level than exclusion.)
	Set p=$order(^Sources(ext,nam)) For  s p=$order(^Sources(ext,p),-1) Quit:p=""  If $Piece(nam,delim,1,$length(p,delim))=p,($data(^Sources(ext,p),found)#2) Quit

	// If using default mapping, check for default-level exclusion.
	If ($data(found)=0) && ($data(^Sources(ext,"*","Exclude"),exclude)#2) && exclude {
		Quit 1
	}
	Quit 0
}

/// Returns 1 if production decomposition is enabled for this item.
ClassMethod IsDecomposedProduction(pInternalName = "", pExternalName = "", pExt = "") As %Boolean
{
	If (pExt'="") && '((pExt = "PTD")||(pExt="CLS")) Quit 0   // supported extensions are only "CLS" or "PTD"
	Set internalName = $select(
		pInternalName="": ..InternalNameFromExtName(pExternalName),
		1: pInternalName
	)
	
	Set ext = $ZCVT($Piece(internalName,".",*),"U")
	If (pExt'="") && (pExt'=ext) Quit 0   // only proceed if the extension matches pExt or is unspecified
	
	Set name = $Piece(internalName,".",1,*-1)
	If '##class(%EnsembleMgr).IsEnsembleNamespace() 
			|| '$$$comClassDefined("%Studio.SourceControl.Production") 
			|| ('$Get(^SYS("SourceControl","Production","DecomposeProductions"))) 
			|| (internalName = "") {
		Quit 0
	}
	Set productionName = ""
	If ($zconvert(ext,"u") = "CLS")
			&& ##class(%Studio.SourceControl.Production).IsProductionClass(name, "ExtName") {
		Set productionName = name
	} ElseIf ($zconvert(ext,"u") = "PTD") {
		Do ##class(%Studio.SourceControl.Production).ParseInternalName(internalName,,,,,.productionName)
	}
	Quit (productionName '= "") && '..HasSourceDirective(productionName_".cls","ExcludeDecomposeProduction")
}

/// Check if error encountered during Baseline Export is fatal. If not, add to skipped items array
ClassMethod IsFatalBaselineError(name As %String, sc As %Status, ByRef skipped) As %Boolean
{
	If $$$ISERR(sc) {
		Set errorText = $System.Status.GetErrorText(sc)
		Set errorCode = $System.Status.GetErrorCodes(sc)
		// First check for errors exporting an item
		If (errorText [ "Will skip this item") || (errorText [ "skipping this item") {
			Set skipped(name) = errorText
		} ElseIf (errorCode = 5014) && (errorText["CSP versioning") { //$$$FeatureNotSupported
			// Skip items with ";" in the name and continue
			Set skipped(name) = "Filename containing "";"" not supported for baseline export."
		} ElseIf (errorText [ "Package is LOCKED") {
			// Skip items that are not exportable due to package locking
			Set skipped(name) = errorText
		} ElseIf (errorText [ "Namespace is LOCKED") {
			// Skip items that are not exportable due to Namespace locking
			Set skipped(name) = errorText
		} ElseIf (errorText [ "Cannot find any valid checkout options") {
			// Skip items that are invalid for checkout
			Set skipped(name) = errorText
		} Else {
			Return 1
		}
	}
	Return 0
}

/// This method exports all Classes, Routines, Include files, CSP Application files, and Projects files from a namespace into a file structure that can then be added to Source Control.<P>
/// This should be run from the terminal, and the user will be prompted as to whether they want to export to the current ^Sources location or an alternate location (alternate is recommended).<P>
/// The method will then iterate through all Classes, Routines, Include files, CSP Application files and Projects and will export them to ^Sources based on the mappings in the ^Sources global.<P>
/// NOTE - this does not export "Generated" classes. <p>
/// Passing <var>classesOnly</var> as '1' will export only the baseline of the classes.  This is useful for exporting all updated XML after changing to a new class compiler version.<p>
/// Pass <var>interactive</var> as 0 in order to call this programmatically.<p>
/// Pass <var>targetDirectory</var> to specify the directory for export (NOTE - this cannot equal ^Sources for TrakCare exports).<p>
/// Pass boolean <var>changeToReadOnly</var> to control whether the files should be changed to read-only after export (defaults to true).<p>
/// Pass boolean <var>includeMapped</var> to control whether items mapped from other databases should be included in the export (defaults to true).
/// Pass boolean <var>checkOut</var> to contrl whether items exported should also be checked out into source control.
/// Pass <var>skipped</var> to get an array of items skipped for reasons other than expected exclusion, e.g. unsupported external filenames.
/// The default value for this argument will be the inverse of the source hooks LockMapped setting for this namespace (so if nothing is set, then Mapped will be included by default). <p>
ClassMethod BaselineExport(classesOnly As %Boolean = 0, interactive = 1, targetDirectory = {$get(^Sources)}, changeToReadonly As %Boolean = 1, includeMapped As %Boolean = {'$get(^SYS("SourceControl","Misc","LockMapped"))}, checkOut = 0, ByRef skipped) As %Status
{
	Set name="", keepSources=0, answer="", err=""
	If ('$Data(^Sources))&&($length(targetDirectory)=0) {
		If ('interactive) {
			Set msg="Aborting - ^Sources must be defined or 'targetDirectory' must be passed to run this non-interactively"
			Write !,msg
			Quit $$$ERROR($$$GeneralError,msg)
		}
		While ((name="")||('##class(%File).DirectoryExists(name))) {
			Read !,"Enter full directory to export files to: ", name
			Do ##class(%File).CreateDirectoryChain(name)
		}
		Set name=##class(%File).NormalizeDirectory(name)
		Set ^Sources=name
		Set ^Sources("/CSP/","*")="cspapp/"
		Set ^Sources("CLS","*")="cls/"
		Set ^Sources("MAC","*")="rtn/"
		Set ^Sources("INC","*")="inc/"
		Set ^Sources("PRJ","*")="prj/"
		Set ^Sources("RUL","*")="rul/"
		Set ^Sources("DFI","*")="ds/"
	} Else {
		#; Save existing ^Sources global and restore it afterwards
		Write !,"Exporting current ^Sources global so it can be later restored",!
		Set sc=$system.OBJ.Export("Sources.GBL","sources.xml",,.err), keepSources=1
		If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc)
		If err'="" Write !,err
		Quit:('sc)||(err'="") sc
		#; Clear timestamp information so that all exports succeed
		Kill ^Sources(0,"FileTimeStamp")
		Kill ^Sources(0,"ItemTimeStamp")
		Write !,"Current export directory: "_targetDirectory
		Write !,"NOTE: Export of files will fail if Readonly files already exist"
		If (..IsTrakCare()) && $Get(^SYS("SourceControl","Misc","2023TrakCareExport")) {
			Write !,!,$c(27,91,55,109),"WARNING:",$c(27,91,109)," This appears to be a TrakCare namespace.  You must ensure TrakCare"
			Write !,"product classes are properly removed from the export structure before you"
			Write !,"submit anything to Perforce.  A different export directory will be used."
			Set answer="NO"
			If ('interactive)&&(targetDirectory=^Sources) {
				Set msg="Aborting - you must pass in a targetDirectory that is not equal to ^Sources for TrakCare instances."
				Write !,msg
				Quit $$$ERROR($$$GeneralError,msg)
			}
		}
		If (interactive) {
			While ((answer="")||("YyNnQq"'[$extract(answer,1,1))) {Read !,"Use this directory for export? (Y/N) ",answer}
			If "QUIT"[$zconvert(answer,"U") {
				Quit $$$OK
			} ElseIf "NO"[$zconvert(answer,"U") {
				Set sc=0, err=""
				While (name=""||'##class(%File).DirectoryExists(name)) {
					Read !,"Enter full directory path to export files to: ", name
					Do ##class(%File).CreateDirectoryChain(name)
				}
				Set name=##class(%File).NormalizeDirectory(name)
				Set ^Sources=name
			} Else {
				Set ^Sources=targetDirectory	
			}
		} Else {
			Set name=targetDirectory
			Do ##class(%File).CreateDirectoryChain(name)
			Set name=##class(%File).NormalizeDirectory(name)
			Set ^Sources=name
		}
	}
	If (interactive) {
		Set answer=""
		If ($get(^SYS("SourceControl","Misc","LockMapped"))) { Write !,"NOTE: Mapped items are configured as Locked in source control in this namespace" }
		While((answer="")||("YyNn"'[$extract(answer,1,1))) { Read !,"Include items mapped from other databases in Export? (Y/N) ",answer }
		If ("NO"[$zconvert(answer,"U")) { 
			Set includeMapped=0
		} Else {
			Set includeMapped=1
		}
	}
	Set includeMapped=''includeMapped		;# ensure includeMapped is 1 or 0

	If (interactive) {
		Set answer=""
		While((answer="")||("YyNn"'[$extract(answer,1,1))) { Read !,"Change files to Readonly after Export? (Y/N) ",answer }
		If ("NO"[$zconvert(answer,"U")) { 
			Set changeToReadonly=0
		} Else {
			Set changeToReadonly=1
		}
	}
	Set changeToReadonly=''changeToReadonly		;# ensure changeToReadOnly is 1 or 0

	If (interactive) {
		Set answer=""
		While((answer="")||("YyNn"'[$extract(answer,1,1))) { Read !,"Start Export? (Y/N) ",answer }
		If ("NO"[$zconvert(answer,"U")) { 
			If keepSources=1 Set sc=$system.OBJ.Load("sources.xml")
			Quit sc
		}
	}
	Set isTrakCare = ..IsTrakCare()

	#; turn off SrcVer additions to it doesn't make the classes out of date
	If ($data(^SYS("SourceControl","Misc","InsertSrcVer"))#2) {
		Set oldInsertSrcVer=^SYS("SourceControl","Misc","InsertSrcVer")
		Kill ^SYS("SourceControl","Misc","InsertSrcVer")
	}

	If $isobject($get(%SourceControl)) {
		Write !,"Using existing Source Control object",!
	} Else {
		New %SourceControl
		Write !,"Creating Source Control Object..."
		Set sc=##class(%Studio.SourceControl.Interface).SourceControlCreate("","",.created)
		If created {
			Write "Success!",!
		} Else {
			Do $system.OBJ.DisplayError(sc)
			Write !,"Failed!  Quiting BaselineExport().",! Quit $$$ERROR($$$GeneralError,"Could not create Source Control Object")
		}
	}
	Try {
		Write !,"Exporting Classes..."
		Set sc = $$$OK
		Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		Set sql="SELECT ID FROM %Dictionary.ClassDefinition WHERE "
		Set classFilter = "GeneratedBy IS Null AND Deployed = 0"
		Set excludeClasses = "ID %STARTSWITH 'csr.csp.' OR ID %STARTSWITH '%' OR ID %STARTSWITH 'CSPX.' OR ID %STARTSWITH 'Ens.' OR ID %STARTSWITH 'EnsLib.' OR ID %STARTSWITH 'EnsPortal.'"
		If (isTrakCare) {
			// If 2023 TrakCare Export flag is set, use legacy export logic. Otherwise, restrict to Custom.*
			If $Get(^SYS("SourceControl","Misc","2023TrakCareExport")) {
				Write !,"TrakCare Namespace detected. Skipping the following Packages:"
				Write !,"    Report.*"
				Write !,"    TC.*"
				Write !,"    websys.*"
				Write !,"    questionnaire.*"
				Write !,"    Custom.Report.ZEN.questionnaire.* (see LogTrak 83604)"
				Write !,"    gen.* (see JIRA TC-39289)"
				Set excludeClasses = excludeClasses_" OR ID %STARTSWITH 'Report.' OR ID %STARTSWITH 'TC.' OR ID %STARTSWITH 'websys.' OR ID %STARTSWITH 'questionnaire.' OR ID %STARTSWITH 'Custom.Report.ZEN.questionnaire.' OR ID %STARTSWITH 'gen.'"
			} Else {
				Write !,"TrakCare Namespace detected. Restricting export to the following Packages:"
				Write !,"    Custom.*"
				Set classFilter = classFilter_" AND ID %STARTSWITH 'Custom.' "
				Write !,"Skipping the following Packages:"
				Write !,"	 Custom.Report.ZEN.questionnaire.* (see LogTrak 83604)"
				Set excludeClasses="ID %STARTSWITH 'Custom.Report.ZEN.questionnaire'"
			}
		}
		Set classFilter = classFilter_" AND NOT ("_excludeClasses_") "
		Set sql=sql_classFilter
		Do rs.Prepare(sql)
		If (rs.%SQLCODE<0) {
			Write !,"Cannot query Class Dictionary: "_$system.SQL.SQLCODE(rs.%SQLCODE)_" ("_rs.%SQLCODE_")"
			Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
		}
		Do rs.Execute()
		While rs.Next() {
			Set item = rs.Data("ID") _ ".CLS"
			If '..HasSourceDirective(item,"BaselineExclude") {
				Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
				If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
				Set sc = $$$OK
			}
		}
		Do rs.Close()
		Set rs=""
		
		// Export class items with Source Directive 'BaselineInclude'
		Set key = $order(^Sources("CLS",""))
		While key '= "" {
			If $get(^Sources("CLS",key,"BaselineInclude")) && (key '= "*") {
				Set sql = "SELECT ID FROM %Dictionary.ClassDefinition WHERE (ID %STARTSWITH '" _ key _ ".') OR "
				Set sql = sql _ "(ID = '" _ key _ "')"
				Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
				Do rs.Prepare(sql)
				If (rs.%SQLCODE<0) {
					Write !,"Cannot query Class Dictionary: "_$system.SQL.SQLCODE(rs.%SQLCODE)_" ("_rs.%SQLCODE_")"
					Throw ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
				}
				Do rs.Execute()
				While rs.Next() {
					Set item = rs.Data("ID") _ ".CLS"
					// Still need to check HasSourceDirective since BaselineInclude can be disabled at more specific level
					If ..HasSourceDirective(item, "BaselineInclude") {
						Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
						If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
						Set sc = $$$OK
					}
				}
			}
			Set key = $order(^Sources("CLS",key))
		}
		
		If (classesOnly) {
			Write !,!,"classesOnly argument was 1 (true).  Export of the following was skipped:"
			Write !,"  Routines"
			Write !,"  Include Files"
			Write !,"  Business Rules"
			Write !,"  Lookup Tables"
			Write !,"  HL7 Schemas"
			Write !,"  ASTM Schemas"
			Write !,"  X12 Schemas"
			Write !,"  DeepSee Folder Items"
			Write !,"  CSP Applications"
			Write !,"  Projects"
		} Else {
			Write !,!,"Exporting Routines..."
			If (isTrakCare && '$Get(^SYS("SourceControl","Misc","2023TrakCareExport"))) {
				Write !,"TrakCare Namespace detected. Restricting export to the following patterns:"
				Write !,"    Custom.*"
				Write !,"    U*"
				Write !,"    ImplementCCR.*"
			}	
			Write !,"NOTE - Ens* routines are skipped by default."
			Set sc = $$$OK
			Set rs = ##class(%ResultSet).%New("%Routine.RoutineList")
			Do rs.Execute("*.MAC")
			While rs.Next() {
				Continue:rs.Data("Size")=0
				Set item=rs.Data("Name")
				If (isTrakCare && '$Get(^SYS("SourceControl","Misc","2023TrakCareExport"))) {
					#; restrict export to site content patterns and ImplementCCR package, unless explicitly included
					Set baselineInclude = ..HasSourceDirective(item, "BaselineInclude")
					Set name = $Piece(item,".",1,*-1)
					If 'baselineInclude && ($extract(name,1,7)'="Custom.") && ($extract(name,1,1)'="U") && ($extract(name,1,13)'="ImplementCCR.") {
						Continue
					}
				}
				#; ignore auto-generated code generators
				Continue:((item[".G1.MAC")||(item[".G2.MAC"))
				#; ignore auto-generated object/SQL filers
				Continue:((item[".T1.MAC")||(item[".T2.MAC"))
				#; ignore auto-generated SQL routines
				Continue:(item["CacheSql")
				#; ignore auto-generated SQL export routines
				Continue:(item["SQLExport")
				#; ignore mapped Ens* routines
				Continue:($extract(item,1,3)="Ens")
				#; ignore auto-generated Ensemble Routing Rule routines
				Continue:(item["RuleCache.R")
				#; ignore legacy auto-generated TrakCare Component routines
				Continue:($extract(item,1,4)="GCOM")
				#; ignore new-style auto-generated TrakCare Component routines
				Continue:($extract(item,1,4)="gen.")
				If '..HasSourceDirective(item, "BaselineExclude") {
					Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
					If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
					Set sc = $$$OK
				}
			}
			Do rs.Close()
			Set rs=""
			Write !,!,"Exporting Include Files..."
			If (isTrakCare && '$Get(^SYS("SourceControl","Misc","2023TrakCareExport"))) {
				Write !,"TrakCare Namespace detected. Restricting export to the following patterns:"
				Write !,"    Custom.*"
				Write !,"    U*"
			}	
			Write !,"NOTE - Ens* include files are skipped by default."
			Set sc = $$$OK
			Set rs = ##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog")
			Do rs.Execute("*.INC",,,,1,,0)
			While rs.Next() {
				#; skip directories
				Continue:rs.Data("Type")=9
				Continue:rs.Data("Size")=0
				Set item=rs.Data("Name")
				#; ignore mapped Ens* include files
				Continue:($extract(item,1,3)="Ens")

				#; if TrakCare instance and 2023 TrakCare Export flag is set, ignore list of standard TrakCare include files (until they become Generated and all can be automatically ignored)
				#; if flag is not set but still TrakCare instance, restrict to Custom.* and U*
				If (isTrakCare) {
					If ($Get(^SYS("SourceControl","Misc","2023TrakCareExport"))) {
						Set trakINCs=$listbuild("aUTIL1.inc","CHARPAD.inc","SSSYSTEM.inc","SSTP.inc","tkimport.inc","TRAK.inc","webgen.inc","webimport.inc","webSSUserDefWindow.inc","webtrace.inc","webutils.inc","ZCDL.inc","External.hic.OnlineClaim.inc","External.hic.OnlineClaimLogging.inc","External.hic.OnlineClaimUtils.inc","External.hic.OnlineClaimWrapper.inc","web.CDA.inc","websys.SNMP.inc","websys.DataDict.Abstract.inc","Studio.SourceControl.IST.inc","XML.Element.inc")
						If ($listfind(trakINCs,item)) && '..HasSourceDirective(item,"BaselineInclude") {
							Continue
						}
					} Else {
						#; restrict export to site content patterns
						If (($extract(item,1,7)'="Custom.") && ($extract(item,1,1)'="U")) && '..HasSourceDirective(item,"BaselineInclude") {
							Continue
						}
					}
				}
				If '..HasSourceDirective(item,"BaselineExclude") {
					Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
					If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
					Set sc = $$$OK
				}
			}
			Do rs.Close()
			Set rs=""
			If ##class(%Dictionary.CompiledClass).%ExistsId("Ens.Rule.RuleDefinition") {
				Write !,!,"Exporting Business Rules..."
				Set sc = $$$OK
				Set rs = ##class(%ResultSet).%New("Ens.Rule.RuleDefinition:EnumerateRules")
				Do rs.Execute()
				While rs.Next() {
					Set package=rs.Data("Package")
					Set name=rs.Data("Name")
					Set item=package_"."_name_".RUL"
					If '..HasSourceDirective(item,"BaselineExclude") {
						Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
						If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
						Set sc = $$$OK
					}
				}
				Do rs.Close()
				Set rs=""
			}
			Set rs=""
			If ##class(%Dictionary.CompiledClass).%ExistsId("Ens.Util.LookupTableDocument") {
				// only supported in Ensemble 2012.1+
				Write !,!,"Exporting Lookup Tables..."
				Set sc = $$$OK
				Set rs = ##class(%ResultSet).%New("Ens.Util.LookupTableDocument:List")
				Do rs.Execute()
				While rs.Next() {
					Set item=rs.Data("name")
					If '..HasSourceDirective(item,"BaselineExclude") {
						Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
						If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
						Set sc = $$$OK
					}
				}
				Do rs.Close()
				Set rs=""
			}
			Set schemas("EnsLib.EDI.ASTM.SchemaDocument") = $ListBuild("ASTM")
			Set schemas("EnsLib.HL7.SchemaDocument") = $ListBuild("HL7")
			Set schemas("EnsLib.EDI.X12.SchemaDocument") = $ListBuild("X12")
			Set schemaDocumentClass = ""
			For {
				Set schemaDocumentClass = $Order(schemas(schemaDocumentClass),1,schemaInfo)
				If (schemaDocumentClass = "") {
					Quit
				}
				Continue:'##class(%Dictionary.CompiledClass).%ExistsId(schemaDocumentClass)
				Set schemaType = $ListGet(schemaInfo)
				Write !,!,"Exporting ",schemaType," Schemas..."
				Set sc = $$$OK
				Set rs = ##class(%ResultSet).%New(schemaDocumentClass_":List")
				Do rs.Execute()
				While rs.Next() {
					Set item=rs.Data("name")
					Continue:..IsSchemaStandard(item)
					If '..HasSourceDirective(item,"BaselineExclude") {
						Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
						If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
						Set sc = $$$OK
					}
				}
				Do rs.Close()
				Set rs=""
			}
			If ##class(%Dictionary.CompiledClass).%ExistsId("%DeepSee.UserLibrary.Utils") {
				Write !,!,"Exporting DeepSee Folder Items..."
				Set sc=##class(%DeepSee.UserLibrary.Utils).%GetFolderItemList(.itemList,,1)
				// matches subfolders of ds that start with region codes - any 2 letters followed by 'xx' or "XX". (e.g. 'ds/GXXX_Pivot_Tables/...', 'ds/mexx/..'
				Set trakcareExcludedFolderMatcher=##class(%Regex.Matcher).%New("ds\/([A-Za-z]{2}[Xx]{2}[^\/]*)\/.+")
				Set pointer=$order(itemList(""),1,itemID)
				While (pointer'="") {
					Set tItem=##class(%DeepSee.UserLibrary.FolderItem).%OpenId(itemID)
					If $isobject(tItem) {
						If ##class(%Dictionary.CompiledClass).%ExistsId("%DeepSee.UI.FolderItemDocument") {
							Try {
								Set item=tItem.documentName
							} Catch err {
								If err.Name="<PROPERTY DOES NOT EXIST>" {
									// no calculated translation available so hardcode the applicable document name
									Set item=$TR(tItem.fullName,"/","-")_".DFI"
								} Else {
									Do $system.OBJ.DisplayError(err.AsStatus()) Quit 
								}
							}
							If (item["$TRASH") {
								; Exclude pivots deleted via the User Portal
								Write !,"Skipping item in $TRASH: '"_item_"'"
								Set pointer=$order(itemList(pointer),1,itemID)
								Continue	
							}
							If (($extract(%SourceControl.Name(item),0,7)="ds/Ens/")||($extract(%SourceControl.Name(item),0,7)="ds/SYS/")) {
								If '..HasSourceDirective(item,"BaselineInclude") {
									; Exclude system folders
									Set folder = $extract(%SourceControl.Name(item),0,7)
									if '$data(excludedFolders(folder)){
										Set excludedFolders(folder)=1
										Write !,"Skipping System DS folder '"_folder_"'"
									}
									Set pointer=$order(itemList(pointer),1,itemID)
									Continue
								}
							}
							If ((isTrakCare)&&(%SourceControl.Name(item)["/Trak_")) {
								If '..HasSourceDirective(item,"BaselineInclude") {
									; Exclude TrakCare system dashboards
									Write !,"Skipping TrakCare System Dashboard '"_item_"'"
									Set pointer=$order(itemList(pointer),1,itemID)
									Continue
								}
							}
							If ((isTrakCare)&&trakcareExcludedFolderMatcher.Match(%SourceControl.Name(item))) {
								If '..HasSourceDirective(item,"BaselineInclude") {
									; Exclude TrakCare region folders
									Set folder = trakcareExcludedFolderMatcher.Group(1)
									if '$data(excludedFolders(folder)){
										Set excludedFolders(folder)=1
										Write !,"Skipping TrakCare DS folder 'ds/"_folder_"'"
									}
									Set pointer=$order(itemList(pointer),1,itemID)
									Continue
								}
							}
							If '..HasSourceDirective(item, "BaselineExclude") {
								Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
								If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
								Set sc = $$$OK
							}
						} Else {
							//earlier version of DSII which could not be exported via $system.OBJ APIs; export in custom %DeepSee format
							Set item=tItem.fullName
							Set tShortName = $translate(item,"/ .","-_-")
							Set subdir = ##class(%File).NormalizeDirectory(^Sources_"dsi")
							Do ##class(%File).CreateDirectoryChain(subdir)
							Set tFile = ##class(%File).NormalizeFilename(subdir_tShortName_".xml")
							If '..HasSourceDirective(item,"BaselineExclude") {
								Write !,"Exporting '"_item_"' to file '"_tFile
								$$$ThrowOnError(##class(%DeepSee.UserLibrary.Utils).%Export(item,tFile))
							}
						}
					}
					Set pointer=$order(itemList(pointer),1,itemID)
				}
			}
			Write !,!,"Exporting CSP Applications..."
			Set trakCareWebAppPath = ""
			If (isTrakCare) {
				Set trakCareWebAppPath = $classMethod("websys.Configuration", "PathToAppGetStored", 1)
				Write !,"TrakCare Namespace detected. Restricting export to items under app path ##class(websys.Configuration).PathToAppGetStored(1):"
				Write !,"    ",trakCareWebAppPath
			}
			Set sc = $$$OK
			Set rs = ##class(%ResultSet).%New("%CSP.Apps:CSPAppList")
			Do rs.Execute()
			Set cspPaths=""
			While rs.Next() {
				Set app = rs.Data("AppUrl")
				Continue:app["itemsetsourcelink"
				if (trakCareWebAppPath'="" && (($extract(app,0,$length(trakCareWebAppPath))_"/")'=trakCareWebAppPath)) {
					Write !,!,"Skipping export of CSP Application not under the TrakCare app path:",!,"    ",app,!
					Continue
				}
				Set curns=$namespace
				#; Query %SYS to find the physical path for this csp application
				zn "%SYS"
				Set rsc=##class(%ResultSet).%New("Security.Applications:Detail")
				Do rsc.Execute(app)
				Do rsc.Next()
				Set path=rsc.Data("Path")
				If (path="") {
					Write !,!,"CSP Application "_app_" has a NULL CSP Files Physical Path; skipping export",!
					Do rsc.Close()
					Set rsc=""
					zn curns
					Continue
				}
				Set path=##class(%File).NormalizeDirectory(path)
				Do rsc.Close()
				Set rsc=""
				zn curns
				If $data(cspPaths(path)) {
					Write !,!,"Skipping export of CSP Application: "_app,!
					Write "Directory: "_path,!,"Has already been exported as part of "_cspPaths(path),!
				} Else {
					Set cspPaths(path)=app
					Write !,!,"Exporting CSP Application: "_app,!,"From directory: "_path
					Set excludeEnsemble=1
					$$$ThrowOnError(%SourceControl.BaselineCSPDir(path,path,app,changeToReadonly,excludeEnsemble,checkOut,.skipped))
				}
			}
			Do rs.Close()
			Set rs=""
			Write !,!,"Exporting Projects (skipping ItemSet Projects)..."
			Set sc = $$$OK
			Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
			Set sql="SELECT ID FROM %Studio.Project WHERE NOT (ID %STARTSWITH 'Default_')"
			Do rs.Prepare(sql)
			Do rs.Execute()
			While rs.Next() {
				Set item = rs.Data("ID") _ ".PRJ"
				Continue:(($length(item,"_")=4)&&($piece(item,"_")?4A4.6N))		; skip if of the form AAAA####_foo_foo_foo
				Continue:($extract(item,1,8)="EnvInit_") ; skip if Env Init ItemSet prj
				If '..HasSourceDirective(item,"BaselineExclude") {
					Set sc = %SourceControl.BaselineExportItem(item,changeToReadonly,checkOut,includeMapped,.readOnlyDBs)
					If ..IsFatalBaselineError(item,sc,.skipped) $$$ThrowStatus(sc)
					Set sc = $$$OK
				}
			}
			Do rs.Close()
		}
	} Catch err {
		Write !,"Fatal Baseline error Encountered, aborting Baseline",!
		Set sc = err.AsStatus()
		Do $System.Status.DisplayError(sc)
	}
	Set exportDir=^Sources
	If $$$ISERR(sc) {
		Write !,"BaselineExport aborted due to error. Items may have been exported to:"
		Write !,"   ",exportDir
		Write !,"Check the status of these files and address error(s). Then rerun the Baseline."
	}
	If keepSources=1 {
		Kill ^Sources 
		Write !,!,"Restoring original ^Sources global"
		If ..Locked() Set lockflag = (..Locked()-1) 		; capture flag to use when resetting Source Control log; 0 will indicate regular lock and 1 is AdminLocked
		Do ..Unlock()
		Set tempSC=$system.OBJ.Load("sources.xml")
		If $$$ISERR(tempSC) {
			Do $System.Status.DisplayError(tempSC)
			Write !,"Failed to restore ^Sources global. Please check ^Sources. "
			Set sc = $System.Status.AppendStatus(sc, tempSC)
		}
		If $data(lockflag) Do ..Lock(lockflag)			; will pass 0 for regular or 1 for AdminLock
	}
	If $data(oldInsertSrcVer) {
		Set ^SYS("SourceControl","Misc","InsertSrcVer")=oldInsertSrcVer
	}
	if $data(skipped)>1 { // items recorded in skipped array
		Write !,!,"Warning: some items were skipped during the baseline export and may require manual attention"
		
		Set item=$Order(skipped(""),1,msg)
		While (item'="") {
			Write !,item," (",msg,")"
		    Set item = $Order(skipped(item),1,msg)
		}
		Write !!
	}
	If $$$ISOK(sc) {
		Write !,"BaselineExport is complete and the namespace contents have been exported to:"
		Write !,"   ",exportDir
		Write !,"Please move these files to a p4 client and check them into Perforce to populate"
		Write !,"your branch."
	}
	Quit sc
}

ClassMethod IsSchemaStandard(pName As %String = "") As %Boolean [ Internal ]
{
	// Cache needed directory in PPG
	If '$data(^||dbDirectoryCache("HSLIB")) {
		Set tResult = ##class(%SQL.Statement).%ExecDirect(,"SELECT Directory FROM %SYS.DatabaseQuery_FreeSpace() WHERE DataBaseName='HSLIB'")
		Set sc = tResult.%Next()
		Set ^||dbDirectoryCache("HSLIB") = $Select(tResult.%SQLCODE=0:tResult.%Get("Directory"), 1:"")		
	}
	
	Set parts = $Length(pName,".")
	Set category = $Piece(pName,".",1,parts-1)
	Set ext = $Piece(pName,".",parts)
	If (pName = "") {
		Quit 0
	}
	Quit +$Case(ext,
		"AST":$Get(^EnsEDI.ASTM.Description(category,"std"))|| (##class(%SYS.Namespace).GetGlobalDest(,"^EnsEDI.ASTM.Schema",category)=("^"_^||dbDirectoryCache("HSLIB"))),
		"HL7":$Get(^EnsHL7.Description(category,"std")) || (##class(%SYS.Namespace).GetGlobalDest(,"^EnsHL7.Schema",category)=("^"_^||dbDirectoryCache("HSLIB"))),
		"X12":$Get(^EnsEDI.X12.Description(category,"std"))|| (##class(%SYS.Namespace).GetGlobalDest(,"^EnsEDI.X12.Schema",category)=("^"_^||dbDirectoryCache("HSLIB"))),
		:0)
}

/// Export the contents of a CSP directory
/// <var>skipped</var> contains array of items skipped for reasons other than exclusion 
Method BaselineCSPDir(dir As %String, appDir As %String, app As %String, ToReadOnly As %Boolean = 0, useEnsembleExclusionlist As %Boolean = 0, checkOut As %Boolean = 0, ByRef skipped) As %Status
{
	Set rso=##class(%ResultSet).%New("%File:FileSet")
	If (useEnsembleExclusionlist) { Set excludeList=..BaselineExportEnsembleExclude() }
	Do rso.Execute(dir,,,1,)
	While rso.Next() {
		Set name=rso.Data("Name")
		If (rso.Data("Type")="D") {
			Set sc = ..BaselineCSPDir(name,appDir,app,ToReadOnly,useEnsembleExclusionlist,checkOut,.skipped)
			If $$$ISERR(sc) Return sc
		} Else {	
			#; Export csp where internal name like "/csp/namespace/filname.csp" or "/cspapplication/filename.csp"
			Set name=$translate(name,"\","/")
			Set file=$extract(name,$length(appDir),$length(name))
			If (useEnsembleExclusionlist) {
				If $listfind(excludeList,file) {
					// this is on the 'blacklist' for Ensemble, so skip it
					Continue
				}
			}
			If (..IsTrakCare()) {
				Set excludeTrakFolders = $listbuild("/trakcare/web/addins/",
													"/trakcare/web/csp/",
													"/trakcare/web/images/",
													"/trakcare/web/reports/",
													"/trakcare/web/scripts/",
													"/trakcare/web/scripts_gen/",
													"/trakcare/web/styles/")
				Set ptr=0, folderValue="", trakMatch=0
				While $listnext(excludeTrakFolders,ptr,folderValue) {
					If (app_file[folderValue) && '..HasSourceDirective(app_file,"BaselineInclude") {
						Write !,"Skipping core TrakCare file "_app_file
						Set trakMatch=1
						Quit	; quit out of this While loop because a match has been found
					}
				}
				If (trakMatch) { Continue }
			}
			Set name=app_file
			Try {
				If '..HasSourceDirective(name,"BaselineExclude") {
					$$$ThrowOnError(..BaselineExportItem(name,ToReadOnly,checkOut))
				}
			} Catch ex {
				Set sc = ex.AsStatus()
				If ..IsFatalBaselineError(name,sc,.skipped) Return sc
			}
		}
	}
	Do rso.Close()
	Set rso=""
	Quit $$$OK
}

/// Exports a specific item.<br/>
/// If <var>ToReadOnly</var> is true, then the files will be manually changed to ReadOnly afterwards (for use when exporting from LIVE and leaving items uneditable afterwards).<br/>
/// If <var>CheckOut</var> is true, then the Source Control CheckOut/AddToSourceControl logic is used.<br/>
/// If <var>includeMapped</var> is true, then items mapped from other DBs will be exported, otherwise they will be skipped.  
/// The default value for this argument will be the inverse of the source hooks LockMapped setting for this namespace (so if nothing is set, then Mapped will be included by default).
Method BaselineExportItem(InternalName As %String, ToReadOnly As %Boolean = 0, CheckOut As %Boolean = 0, includeMapped As %Boolean = {'$get(^SYS("SourceControl","Misc","LockMapped"))}, ByRef readOnlyDBs) As %Status
{
	New %SourceControl
	Set sc=$$$OK
	If ($get(InternalName)="") { Quit $$$ERROR($$$GeneralError,"InternalName is a required field") }
	Set mapped = ..IsMapped(InternalName,.sourceDB)
	If 'includeMapped {
		If mapped {
			Write !,"'"_InternalName_"' is mapped from another database; skipping this item"
			Quit $$$OK
		}
	} ElseIf mapped {
		// remove prepended ^^ to get database directory
		Set dbDir = $Extract(sourceDB,3,*)
		Set isReadOnly = $get(readOnlyDBs(dbDir))
		// if not yet visited, record whether db is read-only
		If isReadOnly = "" {
			Set isReadOnly = ..IsDBReadOnly(dbDir)
			Set readOnlyDBs(dbDir) = isReadOnly
		}
		If isReadOnly {
			Write !,"'"_InternalName_"' is mapped from a read-only database; skipping this item"
			Quit $$$OK
		}
	}
	
	Set filename = ..ExtName(InternalName)
	If (CheckOut) {
		// Make sure file is read-only prior to attempting checkout
		If '##class(%Studio.SourceControl.Change).IsUncommitted(filename) && '..ReadOnly(filename) {
			Set sc = ..SetFileReadOnly(filename)
			If $$$ISERR(sc) Quit sc
		}
		
		Set (CheckOutEnabled, AddEnabled, UndoEnabled) = 1
		Set sc=..OnMenuItem("%SourceMenu,%CheckOut", InternalName, , .CheckOutEnabled) 
		If $$$ISERR(sc) Quit sc
		Set sc=..OnMenuItem("%SourceMenu,%AddToSourceControl", InternalName, , .AddEnabled) 
		If $$$ISERR(sc) Quit sc
		Set sc=..OnMenuItem("%SourceMenu,%UndoCheckout", InternalName, , .UndoEnabled) 
		If $$$ISERR(sc) Quit sc
		If (CheckOutEnabled) {
			Set sc=..CheckOut(InternalName,,0)
			Set sc=..OnAfterSave(InternalName)
		} ElseIf (AddEnabled) {
			Set sc=..AddToSourceControl(InternalName)	
		} ElseIf (UndoEnabled) {
			Set sc=..OnAfterSave(InternalName)	//since Undo is enabled, it is already checked out so just try to export it again
		} Else {
			Set sc=$$$ERROR($$$GeneralError,"Cannot find any valid checkout options for "_InternalName)
		}
	} Else {
		If filename="" Quit $$$ERROR($$$GeneralError,"Unable to find mapping where item '"_InternalName_"' should go")
	    #; If file not there create a blank file now
	    Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(filename))
	    If '##class(%File).Exists(filename) {
		    Open filename:"NW":0 Close filename
	        If '##class(%File).Exists(filename) Quit $$$ERROR($$$GeneralError,"Unable to create file '"_filename_"'")
		}
	    #; export document
		Set sc=..OnAfterSave(InternalName)
	    If $$$ISERR(sc) Quit sc
	    If ToReadOnly {
		    Set sc=..SetFileReadOnly(filename)
	    }
	}
    Quit sc
}

/// Earlier versions of Ensemble physically copied files into newly created csp applications; these need to be enumerated so they can be skipped by BaselineExport()
Method BaselineExportEnsembleExclude() As %String [ CodeMode = expression ]
{
$listbuild(
				"/ASTM/ASTMSchemaCodeTable.csp",
				"/ASTM/ASTMSchemaComponentStructure.csp",
				"/ASTM/ASTMSchemaDocumentStructure.csp",
				"/ASTM/ASTMSchemaList.csp",
				"/ASTM/ASTMSchemaMain.csp",
				"/ASTM/ASTMSchemaPath.csp",
				"/ASTM/ASTMSchemaRawStructure.csp",
				"/ASTM/ASTMSchemaSegmentStructure.csp",
				"/EDIDocumentView.csp",
				"/EnsEntHL7Search.csp",
				"/EnsEntLog.csp",
				"/EnsEntMessages.csp",
				"/EnsEntMsgDetails.csp",
				"/EnsEntMsgEditResend.csp",
				"/EnsEntMsgResend.csp",
				"/EnsEntMsgTrace.csp",
				"/HL7/HL7SchemaCodeTable.csp",
				"/HL7/HL7SchemaDataStructure.csp",
				"/HL7/HL7SchemaList.csp",
				"/HL7/HL7SchemaMain.csp",
				"/HL7/HL7SchemaMessageStructure.csp",
				"/HL7/HL7SchemaMessageType.csp",
				"/HL7/HL7SchemaPath.csp",
				"/HL7/HL7SchemaRawStructure.csp",
				"/HL7/HL7SchemaSegmentStructure.csp",
				"/SEF/EDISchemaMain.csp",
				"/UtilEnsAbort.csp",
				"/UtilEnsActivityGraph.csp",
				"/UtilEnsBPDefinition.csp",
				"/UtilEnsBPInstances.csp",
				"/UtilEnsBPList.csp",
				"/UtilEnsBPPurge.csp",
				"/UtilEnsBPViewer.csp",
				"/UtilEnsBusinessMetricProperties.csp",
				"/UtilEnsBusinessMetrics.csp",
				"/UtilEnsConfig.csp",
				"/UtilEnsCounters.csp",
				"/UtilEnsCredentials.csp",
				"/UtilEnsCredentialsEditor.csp",
				"/UtilEnsDTLDefinition.csp",
				"/UtilEnsDTLList.csp",
				"/UtilEnsDashboard.csp",
				"/UtilEnsDashboardList.csp",
				"/UtilEnsDashboardView.csp",
				"/UtilEnsDebug.csp",
				"/UtilEnsEDIMain.csp",
				"/UtilEnsEntHL7Search.csp",
				"/UtilEnsFindMsgBank.csp",
				"/UtilEnsHome.csp",
				"/UtilEnsHostWizard.csp",
				"/UtilEnsJobs.csp",
				"/UtilEnsLog.csp",
				"/UtilEnsLogPurge.csp",
				"/UtilEnsLogout.csp",
				"/UtilEnsMA.csp",
				"/UtilEnsMAPurge.csp",
				"/UtilEnsMessages.csp",
				"/UtilEnsMonitor.csp",
				"/UtilEnsMsgCompare.csp",
				"/UtilEnsMsgDetails.csp",
				"/UtilEnsMsgEdit.csp",
				"/UtilEnsMsgEditResend.csp",
				"/UtilEnsMsgPurge.csp",
				"/UtilEnsMsgResend.csp",
				"/UtilEnsMsgSearch.csp",
				"/UtilEnsMsgTrace.csp",
				"/UtilEnsProductionDelete.csp",
				"/UtilEnsProductionModel.csp",
				"/UtilEnsProductionWizard.csp",
				"/UtilEnsProductions.csp",
				"/UtilEnsPubSubDomainEdit.csp",
				"/UtilEnsPubSubDomains.csp",
				"/UtilEnsQList.csp",
				"/UtilEnsQueues.csp",
				"/UtilEnsRoutingRuleEditor.csp",
				"/UtilEnsRoutingRuleList.csp",
				"/UtilEnsRoutingRulePopup.csp",
				"/UtilEnsRuleEditor.csp",
				"/UtilEnsRuleList.csp",
				"/UtilEnsRuleLog.csp",
				"/UtilEnsRuleLogPurge.csp",
				"/UtilEnsRuleOpEdit.csp",
				"/UtilEnsRuleSameNameList.csp",
				"/UtilEnsSesSuspended.csp",
				"/UtilEnsSubscriberEdit.csp",
				"/UtilEnsSubscribers.csp",
				"/UtilEnsSubscriptionEdit.csp",
				"/UtilEnsSubscriptions.csp",
				"/UtilEnsTestingService.csp",
				"/UtilEnsTestingService1.csp",
				"/UtilEnsTestingService2.csp",
				"/UtilEnsTestingService3.csp",
				"/UtilEnsTooltipPopup.csp",
				"/UtilHome.csp",
				"/UtilLogin.csp",
				"/WFHome.csp",
				"/WFRoleBrowser.csp",
				"/WFRoleEditor.csp",
				"/WFRoleMembers.csp",
				"/WFRoles.csp",
				"/WFRolesForUser.csp",
				"/WFTaskAssign.csp",
				"/WFTasklist.csp",
				"/WFTasks.csp",
				"/WFTasksForRole.csp",
				"/WFTasksForUser.csp",
				"/WFUserEditor.csp",
				"/WFUsers.csp",
				"/WFUsersForRole.csp",
				"/WFWorklist.csp",
				"/cspchart.js",
				"/cspgraph.svg",
				"/csputilcookie.js",
				"/csputils.css",
				"/csputilsplain.css",
				"/ensbpl.js",
				"/ensbplcanvas.svg",
				"/ensbpleditor.html",
				"/ensbplshapes.js",
				"/ensdtl.js",
				"/ensdtlcanvas.svg",
				"/ensdtleditor.html",
				"/ensdtlparser.js",
				"/ensrules.js",
				"/enssvg.js",
				"/enstracelegend.html",
				"/enstracelegend.svg",
				"/ensxml.js",
				"/images/InspectorWater256.jpg",
				"/images/add_24.gif",
				"/images/arrow_down.gif",
				"/images/arrow_left.gif",
				"/images/arrow_left2.gif",
				"/images/arrow_right.gif",
				"/images/arrow_right2.gif",
				"/images/arrow_up.gif",
				"/images/back_24.gif",
				"/images/backtriangle.gif",
				"/images/binoculars_24.gif",
				"/images/browse.gif",
				"/images/browse_gray.gif",
				"/images/browse_grayhi.gif",
				"/images/browsehi.gif",
				"/images/clock_24.gif",
				"/images/close_a_24.gif",
				"/images/delete_24.gif",
				"/images/diskette_24.gif",
				"/images/down_24.gif",
				"/images/hidehi.gif",
				"/images/intersys_ensemble.jpg",
				"/images/minus.gif",
				"/images/next_24.gif",
				"/images/nexttriangle.gif",
				"/images/offer_a_add_24.gif",
				"/images/ok_24.gif",
				"/images/plus.gif",
				"/images/spacer.gif",
				"/images/trash_24.gif",
				"/images/up_24.gif",
				"/images/write_24.gif",
				"/productionModel.svg",
				"/svgcheck.js",
				"/svgcheck.vbs",
				"/svggrid.js",
				"/wizard.css",
				"/xsl/DocBookPDFSimple.xsl",
				"/xsl/Ensemble.jpg",
				"/xsl/InterSystems.jpg",
				"/xsl/ProductionDocBookCommon.xsl",
				"/xsl/ProductionDocBookHTML.xsl",
				"/xsl/ProductionDocBookPDF.xsl",
				"/xsl/winansi.entities"
				)
}

/// The initial implementation of DS II did not include source control hooks in the UI, so it is necessary 
/// to do check-out / export DSII classes and Folder Items just prior to submitting the changes to Perforce.<br/>
/// DSCheckpointExport() will check for the last time that DSCheckpointExport() was run, and will check out and export
/// all changes DS II items since that timestamp.  This should work for both Connected and Disconnected instances.</br>
/// If <var>ListOnly</var> is true, then a list will be displayed but nothing will actually be checked out.<br/>
/// If <var>AddNew</var> is true, then all items which are not yet on disk in the local workspace will be marked for 'add'
/// and exported, otherwise, only those already on disk will be exported.<br/>
/// If <var>ExportAll</var> is true, then the timestamp from the previous export will be ignored and all DeepSee work 
/// that is in Source Control will be checked out.<br/>
/// If <var>Interactive</var> is true, then the user will be prompted for their Perforce password if it is a Connected instance.<br/>
ClassMethod DSCheckpointExport(ListOnly As %Boolean = 0, AddNew As %Boolean = 1, ExportAll As %Boolean = 0, Interactive As %Boolean = 1, ByRef skipped) As %Status
{
	Set sc=$$$OK
	If ('##class(%Dictionary.CompiledClass).%ExistsId("%DeepSee.UserLibrary.Utils")) {
		Write "Error - DeepSee packages not found; exiting method",!
		Quit $$$ERROR($$$GeneralError,"DeepSee not installed")
	}
	Write "This method will check out and export DeepSee II items for source control.",!
	Set beginTime=$get(^SYS("SourceControl","Misc","LastDSCheckpoint"),0)
	Set newTime=$h
	If (ExportAll) Set beginTime=0
	If (beginTime=0) {
		Write "Exporting all DeepSee II classes and Folder Items in the namespace",!
	} Else {
		Write "Exporting any DeepSee II classes and Folder Items which have changed since:",!
		Write "   "_$zdatetime(beginTime,3)_" (from ^SYS(""SourceControl"",""Misc"",""LastDSCheckpoint""))",!
	}
	Set itemList=""
	
	For superClass="%DeepSee.CubeDefinition","%DeepSee.SubjectArea" {
		Write !,"Finding all subclasses of "_superClass_"...",!
		Set rset = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:SubclassOf")
		Set sc=rset.Execute(superClass)
		While (rset.Next()) {
			Set subclass=rset.Data("Name")
			Set classObj=##class(%Dictionary.ClassDefinition).%OpenId(subclass,,.sc)
			If $$$ISOK(sc) {
				Set timeChanged=classObj.TimeChanged
				If $system.SQL.DATEDIFF("s",beginTime,timeChanged) > 0 {
					Set subclass=subclass_".CLS"
					Write "   "_subclass_" (changed "_$zdatetime(timeChanged,3)_")",!
					Set itemList=itemList_$listbuild(subclass)
				}
			} Else {
				Write "Error when trying to open Object Definition '"_subclass_"' (skipping this item): "_$system.Status.GetErrorText(sc),!
			}
		}
	}
	
	Write !,"Finding all DeepSee Folder Items...",!
	Set sc=##class(%DeepSee.UserLibrary.Utils).%GetFolderItemList(.itemList,,1)
	Set pointer=$order(itemList(""),1,itemID)
	While (pointer'="") {
		Set tItem=##class(%DeepSee.UserLibrary.FolderItem).%OpenId(itemID)
		If $isobject(tItem) {
			Set timeChangedUTC=$zdatetimeh(tItem.timeModified,3)
			Set timeChanged=$zdatetimeh(timeChangedUTC,-3)
			If $system.SQL.DATEDIFF("s",beginTime,timeChanged) > 0 {
				If (tItem.fullName["$TRASH/") {
					Set skippedList=$get(skippedList)_$listbuild("   SKIPPED: "_tItem.fullName_" (changed "_$zdatetime(timeChanged,3)_")")
				} Else {
					Write "   "_tItem.fullName_" (changed "_$zdatetime(timeChanged,3)_")",!
					If ##class(%Dictionary.CompiledClass).%ExistsId("%DeepSee.UI.FolderItemDocument") {
						Try {
							Set item=tItem.documentName
						} Catch err {
							If err.Name="<PROPERTY DOES NOT EXIST>" {
								// no calculated translation available so hardcode the applicable document name
								Set item=$TR(tItem.fullName,"/","-")_".DFI"
							} Else {
								Do $system.OBJ.DisplayError(err.AsStatus()) Quit 
							}
						}
						Set itemList=itemList_$listbuild(item)
					} Else {
						//earlier version of DSII which could not be exported via $system.OBJ APIs; export in custom %DeepSee format
						Set item=tItem.fullName
						Set tShortName = $translate(item,"/ .","-_-")
						Set subdir = ##class(%File).NormalizeDirectory(^Sources_"dsi")
						Do ##class(%File).CreateDirectoryChain(subdir)
						Set tFile = ##class(%File).NormalizeFilename(subdir_tShortName_".xml") 
						Set legacyDSList=$get(legacyDSList)_$listbuild($listbuild(item,tFile))
					}
				}
			}
		}
		Set pointer=$order(itemList(pointer),1,itemID)
	}
	
	If $data(skippedList) {
		Write !,"The following changed DeepSee Folder Items are excluded from export...",!
		Set ptr=0
		While ($listnext(skippedList,ptr,line)) {
			Write line,!
		}
		Write "   You must manually delete the original items from your Perforce branch.",!
	}

	If (Interactive) {
		Set default="yes" Write "Do you wish check-out and export of these items? ["_default_"] "
		Read ans Write ! If ans="" Set ans=default 
		If $zconvert($extract(ans),"U")="Y" {
			Set ListOnly=0	
		} Else {
			Quit $$$OK
		}
	}
	If ('ListOnly) {
		Write !,"Attempting Checkout and Export....",!
		If ($listlength(itemList)=0)&&('$data(legacyDSList)) {
			Write !,"No updated DeepSee items were found for export",!
		} Else {
			If '##class(%Studio.SourceControl.ISC).Disconnected() {
				Write "This namespace is 'Connected' to Perforce."
				Write "Current branch is stored in:",!
				Write "    "_^Sources,!
				If (Interactive) {
					Set ret=##class(%Studio.SourceControl.ISC).GetCredentials(.pP4user, .pP4pass)
					If (ret)&&($get(pP4pass)="") {
						Write "Please enter password for Perforce user '"_$get(pP4user)_"': "
						Use $p:(:"+S")
						Read pP4pass 
						Use $p:(:"-S")
						Write !
						Set %stP=$System.Encryption.Base64Encode($G(pP4pass))
					} ElseIf ('ret) {
						Write "NOTICE: Source Control Credentials are not set for '"_$USERNAME_"'",!
					}
				}
			}
			If $isobject($get(%SourceControl)) {
				Write !,"Using existing Source Control object",!
			} Else {
				Write !,"Creating Source Control Object..."
				Set sc=##class(%Studio.SourceControl.Interface).SourceControlCreate("","",.created)
				If 'created {
					Write "Failed!  Quiting DSCheckpointExport().",! Quit $$$ERROR($$$GeneralError,"Could not create Source Control Object")
				}
			}
			For itemIndex=1:1:$listlength(itemList) {
				Set item = $listget(itemList,itemIndex)
				Set sc = %SourceControl.BaselineExportItem(item,0,1)
				If ..IsFatalBaselineError(item,sc,.skipped) {
					Do $System.Status.DisplayError(sc)
					Return sc
				}
				Set sc = $$$OK
			}
			If $data(legacyDSList) {
				Write "DSCheckpointExport for DS II items in versions prior to 2012.1 is NOT IMPLEMENTED",!
				/*For itemIndex=1:1:$listlength(legacyDSList) {
					Set itemDetails=$listget(legacyDSList,itemIndex)
					Set item=$listget(itemDetails,1)
					Set tFile=$listget(itemDetails,2)
		
					Write !,"Exporting '"_item_"' to file '"_tFile
					;Set sc=##class(%DeepSee.UserLibrary.Utils).%Export(item,tFile)
				}*/
			}
		}
		If $$$ISOK(sc) {
			Set ^SYS("SourceControl","Misc","LastDSCheckpoint")=newTime
		}
	}
	Quit sc
}

/// Export System Default Settings and Add to Source Control or Check Out
ClassMethod ExportDefaults(productionName As %String, ByRef filename) As %Status
{
	Do {
		Set sc = $$$OK
		
		If productionName = "All" {
			Set productionIDs = ##class(%SQL.Statement).%ExecDirect(.tStatement,"SELECT ID FROM Ens_Config.Production")
			While productionIDs.%Next() {
				Set production = productionIDs.%GetData(1)
				Set tempSC = ..ExportDefaults(production)
				If $$$ISERR(tempSC) {
					If $$$ISOK(sc) {
						Set sc = tempSC
					} Else {
						Set sc = $System.Status.AppendStatus(sc, tempSC)
					}
				}
			}
		} Else {
			Set subdir = "backup/interop/defaults/"
			Set filename = ^Sources_subdir_productionName_".defaults.xml"
			If '##class(%Library.File).DirectoryExists(^Sources_subdir) {
				If '##class(%Library.File).CreateDirectoryChain(^Sources_subdir, .returnCode) {
					Set errorText = "Failed to create System Defaults export directory. "_
									"OS-level return code: "_returnCode
					Set sc = $$$ERROR($$$GeneralError, errorText)
					continue
				}
			}
			
			Set tempSC = ##class(%Studio.SourceControl.ItemSet).GetPathTranslation(.root, .path)
			If $$$ISERR(tempSC) {
				Set errorText = "Failed to get either the ItemSet directory or perforce root. Check CCR client configuration."_
								$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
				Set sc = $$$ERROR($$$GeneralError, errorText)
				continue
			}
		
			Set internalName = path_$P(^Sources, root, 2)_subdir_productionName_".defaults.xml"
		
			New %SourceControl
			Set tempSC = ##class(%Studio.SourceControl.Interface).SourceControlCreate()
			If $$$ISERR(tempSC) {
				Set errorText = "Failed to create Source Control Object. Check CCR client configuration."_
								$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
				Set sc = $$$ERROR($$$GeneralError, errorText)
				continue
			} 
			
			Set tempSC = ##class(%Studio.SourceControl.Interface).GetStatus(internalName, .isinsourcecontrol, .editable)
			If $$$ISERR(tempSC) {
				Set errorText = "Failed to determine if default settings were in Source Control. Check CCR client configuration."_
								$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
				Set sc = $$$ERROR($$$GeneralError, errorText)
				continue
			}
			
			If isinsourcecontrol && 'editable{
				Set tempSC = %SourceControl.CheckOut(internalName)
			} Else {
				Set tempSC = %SourceControl.AddToSourceControl(internalName)
			}
			If $$$ISERR(tempSC) {
				Set errorText = "Failed to add default settings to uncommitted queue. Check CCR client configuration."_
								$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
				Set sc = $$$ERROR($$$GeneralError, errorText)
				continue
			}
			
			Set exportProduction = $case(productionName, "SystemWide":"*", :productionName)
			Set tempSC = ##class(Ens.Config.DefaultSettings).%Export(filename, exportProduction)
			If $$$ISERR(tempSC) {
				Set errorText = "Failed to export "_productionName_" default settings. Check Production configuration."_
								$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
				Set sc = $$$ERROR($$$GeneralError, errorText)
				continue
			}
			
			&sql(SELECT ID into :ID FROM Change WHERE InternalName = :internalName AND Committed = '0')
			Set change = ##class(%Studio.SourceControl.Change).%OpenId(ID)
			
			If isinsourcecontrol && (change.Action = "edit") && ##class(%Library.File).Compare(filename, filename_".bak") {
				Set tempSC = %SourceControl.UndoCheckout(internalName)
				If $$$ISERR(tempSC) {
					Set errorText = "Failed to undo check-out upon detecting up-to-date System Default Settings. Please "_
									"check status of previously exported file and undo check-out."_
									$System.Status.GetErrorCodes(tempSC)_":"_$System.Status.GetErrorText(tempSC)
					Set sc = $$$ERROR($$$GeneralError, errorText)
					continue
				}
			}
		}
	} While (0)
	Quit sc
}

/// Readonly method which will show files marked for User Readonly as readonly even if process is running as root
ClassMethod ReadOnly(filename) As %Boolean
{
	Set readonly=$$$FileReadOnly(filename)
	If ($$$isUNIX) {
		Set sc=..SecureRunCmd("whoami",,.out,0)
		; processes running as root do not get ReadOnly=1 returned even if the 'write' bit is not set.
		; check the user-write bit, and if it is not set, then indicate that the file is readonly
		If ($get(out(1))="root")&&($zboolean($$$FileAttributes(filename),128,1)=0) { Set readonly=1 }
	}
	Quit readonly
}

ClassMethod GetHistoryLink(InternalName) As %String
{
	Set file = ..ExtName(InternalName)
	Set file = $Translate(file,"\","/")
	Set file = $Piece(file,"/custom_ccrs/",2,*)
	Set file = "//custom_ccrs/"_file
	// once minimum supported version has URI translation table, replace $Replace with $ZCVT with table URI
	Quit $$CCRServer^%buildccr_"/ccr/ng/ccr/filehistory/"_$ZCVT($Replace(file,"/","%2F"),"O","URL")
}

/// <p>Takes a Source directory and reconciles it with a Target directory which is under source control:</p>
/// <ul>
/// <li>Files in Source which do not exist in Target will be copied into the Target and AddToSourceControl() will be called </li>
/// <li>Files in Source which exist as Writeable in Target will be skipped</li>
/// <li>Files in Source which exist as ReadWrite in Target will call Checkout() and then copied from Source to Target</li>
/// <li>After all processing, files in Target which are Readonly will call RemoveFromSourceControl()</li>
/// </ul>
/// <p>This will only run if the Namespace is in Permanently Disconnected Mode; for Connected clients, use the p4 reconcile feature in p4V
/// <p>If <var>IgnoreExtension</var> is set then anything with that extension is excluded from reconciliation (e.g. .bak files
/// left over from former local check-outs which didn't get cleaned up for some reason)
/// <p>If the <var>CCR</var> is set then that value is set in the CCR column of the %Studio.SourceControl.Change table for this uncommitted change
ClassMethod DisconnectedReconcile(SourceDir As %String = "", TargetDir As %String = "", IgnoreExtension As %String = "bak", CCR As %String = "", Initialize As %Boolean = 0) As %Status
{
	Set err=$$$OK
	If (..Disconnected()'=2) {
		Set err = $$$ERROR($$$GeneralError,"DisconnectedReconcile() method only intended to be run in Permanently Disconnected Namespaces")
		Do $system.Status.DisplayError(err)	Quit err
	}
	If (CCR'="")&&($$Org^%buildccr'="")&&($zconvert($extract(CCR,1,4),"U")'=$zconvert($$Org^%buildccr,"U")) {
		Set err = $$$ERROR($$$GeneralError,"Passed CCR ("_CCR_") is not for the current Org for this Namespace ("_$$Org^%buildccr_")")
		Do $system.Status.DisplayError(err)	Quit err		
	}
	If ((SourceDir="")||('##class(%File).DirectoryExists(SourceDir))) {
		Set err = $$$ERROR($$$GeneralError,"Source Directory ("_SourceDir_") does not exist")
		Do $system.Status.DisplayError(err)	Quit err
	}
	Set SourceDir = ##class(%File).NormalizeDirectory(SourceDir)

	If ((TargetDir="")||(('##class(%File).DirectoryExists(TargetDir))&&('Initialize))) {
		Set err = $$$ERROR($$$GeneralError,"Target Directory ("_TargetDir_") does not exist")
		Do $system.Status.DisplayError(err)	Quit err
	}
	Set TargetDir = ##class(%File).NormalizeDirectory(TargetDir)
	Set stdSources = ##class(%File).NormalizeDirectory(^Sources)
	//Confirm that TargetDir is located within the Source Workspace
	Set contains = (stdSources = $extract(TargetDir,1,$length(stdSources)))

	If ('contains) {
		Set err = $$$ERROR($$$GeneralError,TargetDir_" (TargetDir) is not a subdirectory of "_^Sources_" (Source Workspace)")
		Do $system.Status.DisplayError(err)	Quit err
	}
	
	Write !,"Commencing Reconciliation:"
	Write !,"    Source: "_SourceDir
	Write !,"    Target: "_TargetDir

	//Confirm there is nothing in the Uncommitted Queue that is under the Target
	/* change to the following once min supported version is no longer 2010.1, and test this section:
	Set rs = ##class(%SQL.Statement).%ExecDirect(.tStatement,"Select ExternalName, Action, User As ChangeUser FROM %Studio_SourceControl.Change Where Committed = 0 AND ItemFile [ ? ",TargetDir)
	If (rs.%SQLCODE<0) {
		Set err = $$$ERROR($$$GeneralError,"Cannot query Uncommitted Queue: "_$system.SQL.SQLCODE(rs.%SQLCODE)_" ("_rs.%SQLCODE_" - "_rs.%Message_")")
		Do $system.Status.DisplayError(err)	Quit err
	}
	*/

	Set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set sql="Select ExternalName, Action, User As ChangeUser FROM %Studio_SourceControl.Change Where Committed = 0 AND ItemFile [ ?"
	Set sc=rs.Prepare(sql)
	If ($$$ISERR(sc)) { Do $system.Status.DisplayError(sc)	Quit sc }
	If (rs.%SQLCODE<0) {
		Set err = $$$ERROR($$$GeneralError,"Cannot query Uncommitted Queue: "_$system.SQL.SQLCODE(rs.%SQLCODE)_" ("_rs.%SQLCODE_")")
		Do $system.Status.DisplayError(err)	Quit err
	}
	Set sc=rs.Execute(TargetDir)
	If ($$$ISERR(sc)) { Do $system.Status.DisplayError(sc)	Quit sc }
	
	If (rs.%Next(.sc)) {
		Write !,!,"Warning: Items in Target are currently checked out:"
		Do {
			If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc)
			Write !,"    "_rs.Data("ChangeUser")_" "_rs.Data("Action")_" "_rs.Data("ExternalName")
		} While rs.%Next(.sc)
		If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc)
		Write !, "Please review and commit or revert before running DisconnectedReconcile()"
		Set err = $$$ERROR($$$GeneralError,"Items currently in uncommitted queue from Target; see log for details")			
	}
	Set sc=rs.Close()
	If ($$$ISERR(sc)) { Do $system.Status.DisplayError(sc)	Quit sc }	
	If $$$ISERR($get(err)) {
		Do $system.Status.DisplayError(err)	Quit err
	}
	
	//Fetch the contents of Source
	Set SourceFiles=""
	Set sc=..DirectoryInventory(SourceDir,.SourceFiles)
	
	//Fetch the contents of Source
	Set TargetFiles=""
	Set sc=..DirectoryInventory(TargetDir,.TargetFiles)

	//Prep the SourceControl object
	If $isobject($get(%SourceControl)) {
		Write !,"Using existing Source Control object for Reconciliation",!
	} Else {
		New %SourceControl
		Write !,"Creating Source Control object for Reconciliation"
		Set sc=##class(%Studio.SourceControl.Interface).SourceControlCreate("","",.created)
		If 'created {
			Do $system.OBJ.DisplayError(sc)
			Write !,"Failed!  Quiting DisconnectedReconcile().",! Quit $$$ERROR($$$GeneralError,"Could not create Source Control Object")
		}
	}
	
	New %ccrSession
	If (CCR'="") { Set %ccrSession = CCR }
	//Loop through SourceFiles and compare to TargerDir to identify adds and edits
	Set file="" 	
	For {
		Set file=$order(SourceFiles(file)) Quit:file=""
		Set ext=$zconvert($piece(file,".",$length(file,".")),"L")
		If (IgnoreExtension'="")&&(ext=IgnoreExtension) {
			//skip the specified ignored extension
			Continue 	
		}		
		Set SourceFile = SourceDir_file
		Set TargetFile = TargetDir_file
		If ('##class(%File).Exists(TargetFile)) {
			Write !, TargetFile_" (add)"
			//Move over contents from Source
			Do ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(TargetFile))
			Set ret=##class(%File).CopyFile(SourceFile,TargetFile)
			If ('ret) {
				Set err = $$$ERROR($$$GeneralError,"Add file could not be copied to "_TargetFile)
				Do $system.Status.DisplayError(err)
				Continue
			}

			//Add to source control
			Set InternalName = ..InternalNameFromExtName(TargetFile)
			If (InternalName = "") {
				Set err = $$$ERROR($$$GeneralError,"Could not translate "_TargetFile_" into InternalName")
				Do $system.Status.DisplayError(err)
				Set ret=##class(%File).Delete(TargetFile)
				If ('ret) {
					Set err = $$$ERROR($$$GeneralError,"Transactional file could not be removed from "_TargetFile)
					Do $system.Status.DisplayError(err)
				}
				Continue
			} 
			Set sc=%SourceControl.AddToSourceControl(InternalName)
			If $$$ISERR(sc) {
				Do $system.Status.DisplayError(sc)
				Continue
			}
		} ElseIf ('##class(%File).Compare(SourceFile,TargetFile)) {
			Write !, TargetFile_" (edit)"
			//Files differ so check out Target
			Set InternalName = ..InternalNameFromExtName(TargetFile)
			If (InternalName = "") {
				Set err = $$$ERROR($$$GeneralError,"Could not translate "_TargetFile_" into InternalName")
				Do $system.Status.DisplayError(err)
				Continue
			} 
			Set sc=%SourceControl.CheckOut(InternalName)
			If $$$ISERR(sc) {
				Do $system.Status.DisplayError(sc)
				Continue
			}			
			//Move over contents from Source
			Set ret=##class(%File).CopyFile(SourceFile,TargetFile,1)
			If ('ret) {
				Set err = $$$ERROR($$$GeneralError,"Edit file could not be copied to "_TargetFile)
				Do $system.Status.DisplayError(err)
				Continue
			}
		}
	}
		
	//Loop through TargetFiles and compare to SourceDir to identify deletes
	Set file="" 	
	For {
		Set file=$order(TargetFiles(file)) Quit:file=""
		Set ext=$zconvert($piece(file,".",$length(file,".")),"L")
		If (IgnoreExtension'="")&&(ext=IgnoreExtension) {
			//skip the specified ignored extension
			Continue 	
		}		
		Set SourceFile = SourceDir_file
		Set TargetFile = TargetDir_file
		If (##class(%File).ReadOnly(TargetFile)&&('##class(%File).Exists(SourceFile))) {
			Write !, TargetFile_" (delete)"
			//Remove from source control
			Set InternalName = ..InternalNameFromExtName(TargetFile)
			If (InternalName = "") {
				Set err = $$$ERROR($$$GeneralError,"Could not translate "_TargetFile_" into InternalName")
				Do $system.Status.DisplayError(err)
				Continue
			} 
			Set sc=%SourceControl.RemoveFromSourceControl(InternalName)
			If $$$ISERR(sc) {
				Do $system.Status.DisplayError(sc)
				Continue
			}
			//Delete the physical file if it still exists for any reason
			If (##class(%File).Exists(TargetFile)) {
				Set ret=##class(%File).Delete(TargetFile)
				If ('ret) {
					Set err = $$$ERROR($$$GeneralError,"Delete file could not be removed from "_TargetFile)
					Do $system.Status.DisplayError(err)
					Continue
				}
			}
		}
	}
	
	Quit $$$OK
}

/// Utility Method to walk directory tree and find all files; returned array is keyed by the file minus the top directory and has a value of the full file
ClassMethod DirectoryInventory(TopDir As %String = "", ByRef Files, CurrentDir As %String = "") As %Status
{
	If (CurrentDir="") { Set CurrentDir=TopDir }
	Set rso=##class(%ResultSet).%New("%File:FileSet")
	Set sc=rso.Execute(CurrentDir,,,1,)
	If $$$ISERR(sc) {
		Quit sc
	}
	While rso.Next() {
		Set name=rso.Data("Name")
		If (rso.Data("Type")="D") {
			Do ..DirectoryInventory(TopDir, .Files, name )
		} Else {	
			Set Files($replace(name,TopDir,""))=name
		}
	}
	Set sc=rso.Close()
	Quit sc
}

/// Handles all compile-time logic for this class
ClassMethod OnToolsCompile() [ CodeMode = objectgenerator, Internal ]
{
 	For i = 1:1:%class.Parameters.Count() {
        If %class.Parameters.GetAt(i).Name = "SrcVer" Set valSrcVer = %class.Parameters.GetAt(i).Default
        If %class.Parameters.GetAt(i).Name = "Version" Set indexVersion=i
    }
    If $D(indexVersion)&&($G(valSrcVer)["//custom_ccrs/_common/config/") {
	    Set %class.Parameters.GetAt(indexVersion).Default = $P($G(valSrcVer),"#",2)+1
	    Do %class.Parameters.GetAt(indexVersion).%Save()
    }
    Quit $$$OK
}

/// Returns true if this namespace is a TrakCare namespace (note - this will also catch a HealthShare VIEWERLIB, but we shouldn't be changing any data in there anyway)
ClassMethod IsTrakCare() As %Boolean [ CodeMode = expression ]
{
##class(%Dictionary.ClassDefinition).%ExistsId("websys.Configuration") && ('$$$comClassDefined("%ZHSLIB.HealthShareMgr") || '$classMethod("%ZHSLIB.HealthShareMgr", "IsHealthShareInstance"))
}

/// Returns the Major.Minor version for this instance, so it can be used in comparison code which makes sure certain features are used in appropriate versions.
ClassMethod InstanceVersion() As %Numeric [ CodeMode = expression ]
{
$P($SYSTEM.Version.GetNumber(),".",1,2)
}

/// Deprecated, do not use; use ..InstanceVersion() instead
ClassMethod Version() As %Numeric [ CodeMode = call, Deprecated, Internal ]
{
..InstanceVersion()
}

/// Called if compilation of the class has modified the storage (or another part of the class)
/// so we need to write out the new version and if the file is not already checked out we need
/// to check it out automatically.
Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
	Set sc=..GetStatus(InternalName,.IsInSourceControl,.Editable,.IsCheckedOut)
	If $$$ISERR(sc) Quit sc
	Write !,"Item '"_InternalName_"' changed during compile so exporting new version. This should be checked in."
	If IsInSourceControl,'IsCheckedOut {
		Set sc=..CheckOut(InternalName,"Document automatically changed by compile",0)
		If $$$ISERR(sc) Quit sc
	}
	Quit ..OnAfterSave(InternalName)
}

ClassMethod CheckIndexes()
{
	Set tInterupt=0
	Try {
		Do ##class(Change).BuildNewIndexes()
		Do ##class(ItemSet).BuildNewIndexes()
	} Catch (tExc) {
		If tExc.Name="<METHOD DOES NOT EXIST>" {
			Set tMethod=$Piece(tExc.Data,",",1),tClass=$Piece(tExc.Data,",",2)
			Write !,"Unable to check indexes. Please upgrade your client tools. The version of ",tClass," installed on this system does not have a valid ",tMethod,"() method." 
		} Else {
			Write !,"Could not complete operation: ",!
			Do tExc.OutputToDevice()
			If (tExc.Name="<INTERRUPT>")||(tExc.Name="<DISCONNECT>")||tExc.Name="<ALARM>" {
				Write tExc.Name_" Detected!",!
				Set tInterupt=1
			}
		}
	}
	If tInterupt=1 {
		Throw tExc
	}
}

}
