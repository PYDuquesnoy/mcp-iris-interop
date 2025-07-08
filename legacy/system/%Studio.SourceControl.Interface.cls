/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// This provides the interface that Studio uses to talk to the source control class.
Class %Studio.SourceControl.Interface [ Owner = {%Developer}, System = 3 ]
{

/// Return the name of the source control class we should use for this
/// namespace. If we return "" then source control is not enabled in
/// this namespace.
ClassMethod SourceControlClassGet(namespace As %String) As %String [ Final ]
{
	Quit $$SourceControlClass^%occLibrary(.namespace)
}

/// Set the name of the source control class we should use for this
/// namespace. Set the value to "" to disable source control in this
/// namespace. Set the value to $char(0) to remove the source control node for 
/// this namespace. This is different to setting it to "", which disables it, as
/// removing the node for this namespace will allow a look through to the default
/// source control class for all namespaces.
ClassMethod SourceControlClassSet(val As %String = "", namespace As %String, sys As %Boolean = 0) As %Status [ Final ]
{
	If $get(namespace)="" Set namespace=$namespace
	If val'="",val'=$char(0) {
		Try {
			Do
			. If namespace'=$namespace New $namespace Set $namespace=namespace
			. Set extends=$classmethod(val,"%Extends","%Studio.Extension.Base")
		} Catch {
			Set extends=0
		}
		If 'extends Quit $$$ERROR($$$InvalidStudioClass,val)
	}
	Set sc=$$$OK
	If val=$char(0) {
		Try {
			#; Try to remove the local seeting if it is defined
			If $data(^|namespace|SYS("SourceControlClass"))#10=1 Kill ^|namespace|SYS("SourceControlClass")
			#; Now remove the ^%SYS setting (if defined)
			If $data(^%SYS("SourceControlClass",namespace))#10=1 Kill ^%SYS("SourceControlClass",namespace)
			#; Now the setting in the routine database
			If $data(^|namespace|oddStudioMenu("00-SourceControlClass"))#10=1 Kill ^|namespace|oddStudioMenu("00-SourceControlClass")
		} Catch {
			If $zerror["<PROTECT>" {
				Set sc=$$$ERROR($$$SourceProtect)
			} Else {
				Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
			}
		}
	} Else {
		If $data(^%SYS("SourceControlClass",namespace),oldval)#10=0,'sys {
			Kill oldval
			If $data(^|namespace|oddStudioMenu("00-SourceControlClass"),oldval)#10=0||(oldval'=val) {
				Try {
					Set ^|namespace|oddStudioMenu("00-SourceControlClass")=val
				} Catch {
					If $zerror["<PROTECT>" {
						If $data(oldval) {
							Set sc=$$$ERROR($$$SourceProtect)
						} Else {
							If $data(^%SYS("SourceControlClass",namespace),oldval)#10=0||(oldval'=val) {
								Try {
									Set ^%SYS("SourceControlClass",namespace)=val
								} Catch {
									If $zerror["<PROTECT>" {
										Set sc=$$$ERROR($$$SourceProtect)
									} Else {
										Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
									}
								}
							}
						}
					} Else {
						Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
					}
				}
			}
		} ElseIf oldval'=val {
			#; If the ^%SYS("SourceControlClass",namespace) node is defined and new value is different we must change
			#; this node
			Try {
				Set ^%SYS("SourceControlClass",namespace)=val
			} Catch {
				If $zerror["<PROTECT>" {
					Set sc=$$$ERROR($$$SourceProtect)
				} Else {
					Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
				}
			}
		}
	}
	Quit sc
}

/// Test the creation of the source control class
ClassMethod Test()
{
	Write !,"Studio extention class: ",..SourceControlClassGet(),!
	Set sc=..SourceControlCreate("","",.created)
	If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc)
	Write "Created: ",created,!!
	Write "MainMenus",!
	Do ##class(%ResultSet).RunQuery("%Studio.SourceControl.Interface","MainMenus")
	Write !
	Do {
		Read !,"Submenu to display: ",menu,!
		If menu="" Quit
		Read "Document open: ",document,!
		Do ##class(%ResultSet).RunQuery("%Studio.SourceControl.Interface","MenuItems",menu,document)
	} While 1
	Quit
}

/// Creates an instance of the source control class stored in the local variable
/// '%SourceControl'. This is used by the load/save/compile functions to import/export
/// the routine to the external source control class.<p>
/// It also returns <var>Created</var> which is true if the source control class was created
/// correctly. Then <var>Flags</var> returns an integer set of flags to determine which dialogs
/// to display in Studio. Studio passes its <var>Version</var> to the server so the server can
/// modify its behavior based on this. The server returns <var>Reload</var> which if "" is set
/// in Studio on a per user basis, but if set to 1 or 0 then this forces the auto reload behavior
/// in Studio to follow this server setting. The <var>MainJob</var> is blank if this process is the
/// main Studio connection, but is the $job of the initial Studio connection job if this is a background
/// job for doing things like find in files, or a big compile. By passing the $job of the main
/// process this background process can co-ordinate with the main job.
ClassMethod SourceControlCreate(Name As %String, Password As %String, ByRef Created As %Boolean, ByRef Flags As %Integer, Output Username As %String, Version As %String = "", ByRef Reload As %String, MainJob As %String = "", ByRef IconStatus As %Integer) As %Status [ Final, NotInheritable ]
{
	If $SYSTEM.Security.GetGlobalPermission(,"^SYS")'["READ" {
		#; Can't read our own globals (unprivileged Atelier connection)
		Set Created=0,Flags=0
		Quit $$$OK
	}
	Set Username=$username,Reload=$get(^%SYS("Studio","Reload"),$get(^SYS("Studio","Reload")))
	If '$system.Security.Check("%Development","use") Quit $$$ERROR($$$NoDevloperPriv)
	$$$CheckClassDefRtnIdx(sc)
	If $data(^oddPROJECT,project),$get(project)'=1 Do ##class(%Studio.Project).Normalize()
	Set $ztrap="Trap"
	Set %SourceControl=""
	Set Created=0,Flags=0,IconStatus=0
	Set class=..SourceControlClassGet()
	If class="" Quit $$$OK
	New %objlasterror
	Set %SourceControl=$classmethod(class,"%New",$ListBuild(Name,Password,MainJob,Version))
	If %SourceControl="" Quit $select($get(%objlasterror)'="":%objlasterror,1:$$$ERROR($$$SourceControlClass,class))
	Set Created=1,Flags=15
	Set IconStatus=%SourceControl.IconStatus
	Quit $$$OK
Trap	Set $ztrap=""
	If $zerror["<CLASS DOES NOT EXIST>" Quit $$$ERROR($$$SourceControlClass,class)
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Reformat the InternalName to make sure the type is all in upper case
ClassMethod normalizeName(InternalName As %String) As %String
{
	Set output=""
	For i=1:1:$length(InternalName,",") {
		Set name=$zstrip($piece(InternalName,",",i),"<>W") If name="" Continue
		If name["/" {
			If $extract(name)'="/" Set name="/"_name
		} Else {
			Set ext=$zconvert($piece(name,".",$length(name,".")),"U")
			Set name=$select(name[".":$piece(name,".",1,$length(name,".")-1)_"."_ext,1:name)
		}
		Set output=output_name_","
	}
	Quit $extract(output,1,*-1)
}

/// Return information about this entity. The <var>Reload</var> parameter is returned by this
/// function and is true if the status check changed the item and so may need to be reloaded.
ClassMethod GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String, ByRef Reload As %Boolean) As %Status
{
	If '$isobject($get(%SourceControl)) Quit $$$ERROR($$$SourceControlNotLoggedIn)
	Set InternalName=..normalizeName(InternalName)
	Set ts=##class(%RoutineMgr).TS(InternalName)
	Do
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.GetStatus(InternalName,.IsInSourceControl,.Editable,.IsCheckedOut,.UserCheckedOut)
	Set Reload=(ts'=##class(%RoutineMgr).TS(InternalName))
	Quit rc
}

/// Returns the external name of this file
ClassMethod ExternalName(InternalName As %String) As %String
{
	Set InternalName=..normalizeName(InternalName)
	If $isobject($get(%SourceControl)) {
		Set tmp=%SourceControl New %SourceControl
		Quit tmp.ExternalName(InternalName)
	} Else {
		Quit ""
	}
}

/// Return true if this document is generated from some other item
ClassMethod IsGenerated(InternalName As %String) As %Boolean
{
	Set InternalName=..normalizeName(InternalName)
	If $isobject($get(%SourceControl)) {
		Set tmp=%SourceControl New %SourceControl
		Quit tmp.IsGenerated(InternalName)
	} Else {
		Quit ""
	}
}

/// Called when the user makes a change that may require some source control hook interaction
ClassMethod UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean, ByRef Editable As %Boolean) As %Status
{
	Set Reload=0,Editable=0,protect=0
	If '$isobject($get(%SourceControl)) Set Editable=1 Quit $$$OK
	Set tmp=%SourceControl New %SourceControl
	Set InternalName=..normalizeName(InternalName),Action="",Text="",rc=$$$OK
	#; This is a multiple checkout from import dialog so we do not care about Reload or Editable flags
	If Type'=1||(Name'=6) {
		Set ts=##class(%RoutineMgr).TS(InternalName)
		If Type=1,Name=3,$piece(InternalName,".",$length(InternalName,"."))="CLS",$isobject($get(tmp)) {
			Set protect=$$CheckProtect^%qccServer($piece(InternalName,".",1,$length(InternalName,".")-1))
			If 'protect Set sc=tmp.OnBeforeLoad(InternalName) If $$$ISERR(rc) Goto exit
		}
	}

	Try {
		Set rc=tmp.UserAction(Type,Name,InternalName,SelectedText,.Action,.Target,.Msg,.Reload)
	} Catch {
		If $zerror["<PARAMETER>" {
			Try {
				Set rc=tmp.UserAction(Type,Name,InternalName,SelectedText,.Action,.Target,.Msg)
			} Catch {
				Set rc=$$$ERROR($$$ObjectScriptError,$zerror)
			}
		} Else {
			Set rc=$$$ERROR($$$ObjectScriptError,$zerror)
		}
	}

	If Type'=1||(Name'=6) {
		If $$$ISOK(rc) {
			Set rc=tmp.GetStatus(InternalName,,.Editable)
			If Type=1,Name=3,$piece(InternalName,".",$length(InternalName,"."))="CLS",'protect,$$$ISOK(rc) Set rc=tmp.OnAfterLoad(InternalName)
		}
	}
exit	If 'Reload,Type'=1||(Name'=6) Set Reload=(ts'=##class(%RoutineMgr).TS(InternalName))
	Quit rc
}

/// Called after Studio brings up its default dialog from calling <method>OnUserAction</method> to tell
/// the server what the answer was
ClassMethod AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean, ByRef Editable As %Boolean) As %Status
{
	Set Reload=0,Editable=0
	If '$isobject($get(%SourceControl)) Set Editable=1 Quit $$$OK
	Set tmp=%SourceControl New %SourceControl
	Set InternalName=..normalizeName(InternalName)
	If Type'=1||(Name'=6) Set ts=##class(%RoutineMgr).TS(InternalName)
	
	Try {
		Set rc=tmp.AfterUserAction(Type,Name,InternalName,Answer,Msg,.Reload)
	} Catch {
		If $zerror["<PARAMETER>" {
			Try {
				Set rc=tmp.AfterUserAction(Type,Name,InternalName,Answer,Msg)
			} Catch {
				Set rc=$$$ERROR($$$ObjectScriptError,$zerror)
			}
		} Else {
			Set rc=$$$ERROR($$$ObjectScriptError,$zerror)
		}
	}

	If Type'=1||(Name'=6) {
		If $$$ISOK(rc) Set rc=tmp.GetStatus(InternalName,,.Editable)
		If 'Reload,Type'=1||(Name'=6) Set Reload=(ts'=##class(%RoutineMgr).TS(InternalName))
	}
	
	Quit rc
}

Query MainMenus() As %Query(ROWSPEC = "Name:%String(MAXLEN=32767),Type:%Integer,DisplayName:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod MainMenusExecute(ByRef qHandle As %Binary) As %Status
{
	If '$isobject($get(%SourceControl)) Quit $$$OK
	Set tmp=%SourceControl New %SourceControl
	Quit tmp.MainMenusExecute(.qHandle,$classname(tmp))
}

ClassMethod MainMenusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	If '$isobject($get(%SourceControl)) Set Row="",AtEnd=1 Quit $$$OK
	Set tmp=%SourceControl New %SourceControl
	Set sc=tmp.MainMenusFetch(.qHandle,.Row,.AtEnd) If $$$ISERR(sc) Quit sc
	If Row="" Set AtEnd=1 Quit $$$OK
	Set name=$list(Row)
	If $listlength(Row)<2 Set $list(Row,2)=0
	Set displayname=$$$FormatMessage(,$select($extract(name)="%":"%Studio",1:"Studio"),name)
	If displayname="" Set displayname=name	
	Set rc=tmp.OnMenuItem(name,"","",1,.displayname)
	Set Row=Row_$listbuild(displayname)
	Quit sc
}

ClassMethod MainMenusClose(ByRef qHandle As %Binary) As %Status
{
	If '$isobject($get(%SourceControl)) Quit $$$OK
	Set tmp=%SourceControl New %SourceControl
	Quit tmp.MainMenusClose(.qHandle)
}

Query MenuItems(MenuName As %String(MAXLEN=32767), InternalName As %String(MAXLEN=32767), SelectedText As %String(MAXLEN=32767)) As %Query(ROWSPEC = "Name:%String(MAXLEN=32767),Type:%Integer,DisplayName:%String(MAXLEN=32767),SaveFlag:%String,Separator:%Boolean") [ SqlProc ]
{
}

ClassMethod MenuItemsExecute(ByRef qHandle As %Binary, MenuName As %String(MAXLEN=32767), InternalName As %String(MAXLEN=32767) = "", SelectedText As %String(MAXLEN=32767) = "") As %Status
{
	If '$isobject($get(%SourceControl)) Quit $$$ERROR($$$SourceControlNotLoggedIn)
	Set InternalName=..normalizeName(InternalName)
	Set tmp=%SourceControl New %SourceControl
	Set %MenuName=MenuName,%InternalName=InternalName,%SelectedText=SelectedText
	Quit tmp.MenuItemsExecute(.qHandle,$classname(tmp),MenuName,InternalName,SelectedText)
}

ClassMethod MenuItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tmp=%SourceControl New %SourceControl
loop	Set rc=tmp.MenuItemsFetch(.qHandle,.Row,.AtEnd) If $$$ISERR(rc) Quit rc
	If Row="" Set AtEnd=1 Quit $$$OK
	#; Ensure Row(0) is not bubbled up from the inner Fetch
	Kill Row(0)
	Set name=$listget(Row),enabled=$listget(Row,2)
	#; Provide defaults for old queries
	If $listlength(Row)<3 Set $list(Row,3)="000"
	If $listlength(Row)<4 Set $list(Row,4)=0
	Set displayname=$$$FormatMessage(,$select($extract(name)="%":"%Studio",1:"Studio"),name,,%InternalName)
	If displayname="" Set displayname=name
	Set rc=tmp.OnMenuItem(%MenuName_","_name,%InternalName,%SelectedText,.enabled,.displayname)
	If $$$ISERR(rc) Quit rc
	If enabled=-1 Goto loop
	Set Row=$listbuild($list(Row),enabled,displayname,$list(Row,3),+$listget(Row,4))
	Quit $$$OK
}

ClassMethod MenuItemsClose(ByRef qHandle As %Binary) As %Status
{
	Set tmp=%SourceControl New %SourceControl
	Kill %MenuName,%InternalName,%SelectedText
	Quit tmp.MenuItemsClose(.qHandle)
}

Query ExtensionClasses() As %Query(ROWSPEC = "Name:%String,Description:%String") [ SqlProc ]
{
}

ClassMethod ExtensionClassesExecute(ByRef qHandle As %Binary) As %Status
{
	Set sc=$$GetAllDerivedClasses^%occLibrary("%Studio.Extension.Base",.classes)
	Kill classes("%Studio.SourceControl.Base")
	If $$$ISERR(sc) Quit sc
	Set idx=$increment($$$ISCQUERYTEMP)
	#; Make sure this is cleaned up if the process crashes
	Merge $$$ISCQUERYTEMP(idx)=classes
	Set qHandle=$listbuild(idx,"")
	Quit $$$OK
}

ClassMethod ExtensionClassesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set idx=$listget(qHandle),index=$listget(qHandle,2)
	Set Row="",AtEnd=0
	If idx="" Set AtEnd=1 Quit $$$OK
	Set index=$order($$$ISCQUERYTEMP(idx,index))
	If index="" Set AtEnd=1 Quit $$$OK
	Set desc=$zconvert($translate($piece($$$comClassKeyGet(index,$$$cCLASSdescription),$char(10)),$char(13)),"I","HTML")
	Set Row=$listbuild(index,desc),$list(qHandle,2)=index
	Quit $$$OK
}

ClassMethod ExtensionClassesClose(ByRef qHandle As %Binary) As %Status
{
	Set idx=$listget(qHandle)
	If idx'="" Kill $$$ISCQUERYTEMP(idx)
	Quit $$$OK
}

ClassMethod OnBeforeTimestamp(class As %String(MAXLEN="")) As %Status
{
	If $isobject($get(%SourceControl))=1 {
		Set tmp=%SourceControl New %SourceControl
		Do tmp.OnBeforeTimestamp(class_".CLS")
	}
	Quit $$$OK
}

}
