/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for storing changes to environment
Class %Studio.SourceControl.Change Extends %Persistent [ System = 4 ]
{

/// The <var>MANAGEDEXTENT</var> parameter can be set to 0 (zero) to cause the Extent Manager
/// to ignore this class. If set to 1 then the Extent Manager will register globals used by
/// the class and detect collisions. Unmanaged extents (MANAGEDEXTENT = 0) are not checked.   
/// Currently, only classes using default storage (%Storage.Persistent) can be managed.
/// 
/// This is required since each Namespace will have it's own Change extent
Parameter MANAGEDEXTENT As INTEGER [ Constraint = "0,1", Flags = ENUM ] = 0;

/// This Parameter should be updated when synced from Perforce 
Parameter SrcVer = "$Id: //iris/2025.1.0/databases/sys/cls/Studio/SourceControl/Change.xml#1 $";

/// Revision number of this class when compiled as part of the //custom_ccrs/_common/config/... branch.  
/// This version will not be updated (by design) when the class is integrated to other branches.
/// This allows the user to tell what version of the Studio client tools are in use.
Parameter Version = 29;

/// Action for this change
Property Action As %String(VALUELIST = ",add,edit,predelete,delete,revert") [ Required ];

/// Returns the name of the backup file for this Item in the file system
Property BackupName As %String [ Calculated, SqlComputeCode = {S {*}=$S((({Tier2}))&&($D(^SYS("ChangeControlClass"))):$zobjclassmethod(^SYS("ChangeControlClass"),"BackupName",{InternalName}),1:$zobjclassmethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(),"BackupName",{InternalName})) }, SqlComputed ];

/// User who made this change, and for uncommitted changes this is the person who has it "checked out"
Property ChangedBy As %String;

/// Flag indicating whether or not this change has been committed to Perforce
Property Committed As %Boolean [ InitialExpression = 0, Required ];

Index CommittedMap On Committed [ Type = bitmap ];

/// Flag indicating whether or not this change was committed to Perforce via Source/Change control tools.
/// If ActivelyCommitted = 0 for a committed change, then it might have been either reverted or committed directly by a Perforce client and the 
/// Perforce history should be checked to see whether or not it was committed
Property ActivelyCommitted As %Boolean [ InitialExpression = 0 ];

/// Time when this change was committed to Perforce (either via an ItemSet, the Studio CheckIn page or through a P4V)
/// <P> this value should be set in the form $zdt($H,3) (i.e. "0000-00-00 00:00:00" format)
Property CommittedTime As %TimeStamp [ InitialExpression = {$zdt("0,0",3)} ];

/// Display the CommittedTime field, showing "Uncommitted" for changes that have not yet been committed
Property CommittedTimeDisplay As %String [ Calculated, SqlComputeCode = {S {*}=$S({Committed}:{CommittedTime},1:"uncommitted") }, SqlComputed ];

/// When this change was first created, this CCR was associated with it for tracking purposes (optional field)
Property CCR As %String;

/// Returns the name of this Item in the file system
Property ExternalName As %String [ Calculated, SqlComputeCode = {S {*}=$S(({Tier2})&&($D(^SYS("ChangeControlClass"))):$zobjclassmethod(^SYS("ChangeControlClass"),"ExternalName",{InternalName}),1:$zobjclassmethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(),"ExtName",{InternalName})) }, SqlComputed ];

/// Name used within instance to refer to this changed item
Property InternalName As %String(MAXLEN = 200);

/// Location where this item is stored on disk
Property ItemFile As %String(MAXLEN = 500) [ Required ];

/// Human readable Name referring to this changed item.  This will default to the value if InternalName unless it is explicitly set
Property Name As %String(MAXLEN = 200);

/// Time of when the P4 command was issued to Perforce<BR/>
/// NOTE - a change can have a non-null P4Issued and still have Committed=0 because a 'p4 edit' will check it out but it is not committed until 'p4 submit'
Property P4Issued As %TimeStamp;

/// Utility by which this change was made
Property Source As %String(VALUELIST = ",studio,terminal,trakcare,healthshare,tier2") [ InitialExpression = "studio" ];

/// Determine if current change is sourced from a tier 2 change control environment
Property Tier2 As %Boolean [ Calculated, SqlComputeCode = {S {*}=$S((({Source}="trakcare")||({Source}="healthshare")||({Source}="tier2")):1,1:0)}, SqlComputed ];

/// Last time this change was saved locally
Property UpdatedTime As %TimeStamp [ InitialExpression = {$zdt($H,3)} ];

Index ChangeList On (ItemFile, CommittedTime) [ Data = Action, Unique ];

/// Returns Boolean value indicating whether or not an item is Uncommitted
ClassMethod IsUncommitted(Filename, ByRef ID) As %Boolean
{
	&sql(SELECT ID into :ID FROM Change WHERE ItemFile = :Filename AND Committed = '0')
	If (SQLCODE=0) {
		Quit 1
	} Else {
		Set ID=""
		Quit 0
	}
}

/// Returns uncommited change object
ClassMethod OpenUncommitted(Filename) As %Studio.SourceControl.Change
{
	If ('..IsUncommitted(Filename,.id)) Quit ""
	Quit ..%OpenId(id)
}

/// Retrieves the details from the Uncommitted queue of an Uncommitted item
ClassMethod GetUncommitted(Filename, ByRef Action, ByRef InternalName, ByRef ChangedBy, ByRef Source, ByRef Updated, ByRef P4Issued, ByRef CCR, ByRef Name) As %Status
{
	If '$DATA(Filename) Quit $$$ERROR($$$GeneralError,"'Filename' is a required field")
 	If '..IsUncommitted(Filename) Quit $$$ERROR($$$GeneralError,"Item is not in the Uncommitted queue")
	Set obj=..OpenUncommitted(Filename)
	Set Action=obj.Action
	Set ChangedBy=obj.ChangedBy
	Set InternalName=obj.InternalName
	Set Source=obj.Source
	Set Updated=obj.UpdatedTime
	Set P4Issued=obj.P4Issued
	Set CCR=obj.CCR
	Set Name=obj.Name
	Quit $$$OK
}

/// Sets the details for a new Uncommitted item into the Uncommitted queue
ClassMethod SetUncommitted(Filename, Action, InternalName, ChangedBy, Source, P4Issued As %Boolean, CCR, Name, EnforceSourcesPath = 1) As %Status
{
 	If '$DATA(Filename) Quit $$$ERROR($$$GeneralError,"'Filename' is a required field")
	Set Filename=##class(%File).NormalizeFilename(Filename)
	Set exists=##class(%File).Exists(Filename)
	Set isCSP=($Extract(InternalName)="/")
	If '(exists || (isCSP && (Action = "delete"))) {
		Quit $$$ERROR($$$GeneralError,"File does not exist - "_Filename)
	}
	If (EnforceSourcesPath)&&(($$$isUNIX&&(Filename'[^Sources))||($$$isWINDOWS&&($ZCVT(Filename,"l")'[$ZCVT(^Sources,"l")))) {
		Quit $$$ERROR($$$GeneralError,Filename_" is not in the required path of "_^Sources) 
	}
	If ..IsUncommitted(Filename) {
		Set sc=..UpdateUncommitted(Filename,.Action,.InternalName,.ChangedBy,.Source,,.P4Issued,.CCR,.Name)
	} Else {
		Set obj=..%New()
		Set obj.ItemFile=Filename
		If $D(Action) Set obj.Action=$G(Action)
		If $D(ChangedBy) Set obj.ChangedBy=$G(ChangedBy)
		If $D(InternalName) Set obj.InternalName=$G(InternalName)
		If $D(Source) Set obj.Source=$G(Source)
		If $D(CCR) Set obj.CCR=$G(CCR)
		If $D(Name) Set obj.Name=$G(Name)
		If $G(P4Issued) Set obj.P4Issued=$zdt($H,3)
		Set sc=obj.%Save()
	}
	Quit sc
}

/// Update the details for an Uncommitted item in the Uncommitted queue
ClassMethod UpdateUncommitted(Filename, Action, InternalName, ChangedBy, Source, Updated, P4Issued, CCR, Name) As %Status
{
 	If '$DATA(Filename) Quit $$$ERROR($$$GeneralError,"'Filename' is a required field")
	Set Filename=##class(%File).NormalizeFilename(Filename)
	Set ret=##class(%File).Exists(Filename) If ('ret)&&(Action'="revert") Quit $$$ERROR($$$GeneralError,"File does not exist - "_Filename)
	Set obj=..OpenUncommitted(Filename)
	If '$isobject(obj) Quit $$$ERROR($$$GeneralError,"'"_Filename_"' is not in an uncommitted change")
	If $D(Action) {
		If Action'=obj.Action Set obj.P4Issued=""
		Set obj.Action=$G(Action)
	}
	If $D(ChangedBy) {
		If (ChangedBy=obj.ChangedBy) {
			Set obj.ChangedBy=$G(ChangedBy)
			Set obj.UpdatedTime=$zdt($H,3)
		} Else {
			Quit $$$ERROR($$$GeneralError,"UpdateUncommitted() called on '"_Filename_"' by "_ChangedBy_", which is owned by "_obj.ChangedBy)
		}
	}
	If $D(InternalName) Set obj.InternalName=$G(InternalName)
	If $D(Source) Set obj.Source=$G(Source)
	If $D(CCR) Set obj.CCR=$G(CCR)
	If $D(Name) Set obj.Name=$G(Name)
	If $G(P4Issued) Set obj.P4Issued=$zdt($H,3)
	Set sc=obj.%Save()
	Quit sc
}

/// Removes one or more Uncommitted items from the Uncommitted queue and changes the exported file to Reaonly (except for reverts of Adds, or new CSP files within the Perforce root)
/// <P> Default assumed behavior is that the the change was not reverted, and that it was actively committed to Perforce
/// <P> If the method calling does not know whether it was reverted or committed to Perforce, then it should pass <var>Revert</var> = 0 and <var>ActiveCommit</var> = 0, 
/// indicating that the change might have been reverted and the Perforce history should be checked for the definitive answer.
/// <P>The <var>Revert</var>, <var>ActiveCommit</var>, and <var>CommitCCR</var> arguments only impact the behavior if <code>^SYS("SourceControl","ChangeConfig","KeepHistory")=1</code>, 
/// which means Change objects should have their Committed flag set to 1 and be saved for historical reference, rather than just deleting the Change objects
/// when RemoveUncommitted() is called.
/// <p> Arguments are as follows:
/// <ul>
/// <li><var>FileList</var> - the name of the file to revert, or an array subscripted by filenames (e.g. <code>FileList("C:\Perforce\custom_ccrs\us\ISCX\TESTSYS\cls\User\Test.xml")=""</code>)</li>
/// <li><var>Display</var> - boolean flag controlling whether to display the results to standard output (defaults to '1')</li>
/// <li><var>Revert</var> - boolean flag controlling whether to revert a checkout which would delete the change from the change history table (defaults to '0')</li>
/// <li><var>ActiveCommit</var> - used for historical tracking purposes for the %Studio_SourceControl.Change table</li>
/// <li><var>CommitCCR</var> - used for historical tracking purposes for the %Studio_SourceControl.Change table</li>
/// </ul>
ClassMethod RemoveUncommitted(FileList, Display = 1, Revert = 0, ActiveCommit = 1, CommitCCR) As %Status
{
	If '$DATA(FileList) Quit $$$ERROR($$$GeneralError,"No filenames were passed")
	Set filename=FileList,SCs=$$$OK
	If $DATA(FileList)>1 Set filename=$ORDER(FileList(""))
	While (filename'="") {
		If Display Write !,filename_" removed from uncommitted list"
		If '..IsUncommitted(filename) Set filename=$ORDER(FileList(filename)) continue
		Set obj=..OpenUncommitted(filename)
		If (obj.Tier2)&&($D(^SYS("ChangeControlClass"))) {
			Set changeSourceClass=^SYS("ChangeControlClass")
		} Else {
			Set changeSourceClass=##class(%Studio.SourceControl.Interface).SourceControlClassGet()
		}
		Set backupFile=$zobjclassmethod(changeSourceClass,"BackupName",obj.InternalName)
		If ##class(%File).Exists(backupFile) {
			Set ret=##class(%File).Delete(backupFile)
			If ('ret)&&(Display) Write !,"Error deleting unnecessary local backup copy: "_backupFile
		}
		If ('$G(^SYS("SourceControl","ChangeConfig","KeepHistory")))||(Revert) {
			Set sc=..%DeleteId(obj.%Id())
		} Else {
			If $G(CommitCCR)'="" Set obj.CCR=CommitCCR
			Set obj.P4Issued=$zdt($H,3)
			Set obj.Committed=1	
			Set obj.ActivelyCommitted=ActiveCommit
			Set obj.CommittedTime=$zdt($H,3)
			Set sc=obj.%Save()
			If $$$ISERR(sc) Do $SYSTEM.Status.AppendStatus(SCs, sc) If Display Do $System.Status.DisplayError(sc)
		}
		;# if it is still ReadWrite and it is not a revert of an Add...
		If ('##class(%File).ReadOnly(filename))&&('(Revert&&(obj.Action="add"))) {
			;# if it is not a revert a csp file just added to the Perforce Root (which should stay as-is)...
			If '(Revert&&((obj.Action="add")||(obj.Action="revert"))&&(filename=$SYSTEM.CSP.GetFileName(obj.InternalName))) {
				#; then change to Readonly
				Set sc=##class(%Studio.SourceControl.ISC).SetFileReadOnly(filename) If $$$ISERR(sc) Set SCc=$System.Status.AppendStatus(SCs,sc)
			}
		}
		Set filename=$ORDER(FileList(filename))
	}
	Quit SCs
}

/// Removes all Uncommitted items from the Uncommitted queue
ClassMethod RemoveAllUncommitted(Display = 1, IncludeRevert = 1) As %Status
{
	Set sc=..ListUncommitted(.tFileList,IncludeRevert)
	If $$$ISERR(sc) Quit sc
	Set sc=..RemoveUncommitted(.tFileList,Display,1)
	Quit sc
}

/// Lists the Uncommitted items from the Uncommitted queue
/// <p>Only lists items with action of type 'revert' if the IncludeRevert flag is passed as true
ClassMethod ListUncommitted(ByRef UncommittedList = "", IncludeRevert = 0, RefreshUncommitted = 1) As %Status
{
	//If (RefreshUncommitted) Set sc=..RefreshUncommitted(0) If $$$ISERR(sc) Quit sc
	Do ..BuildNewIndexes()
	Set sql="SELECT ItemFile, Action From %Studio_SourceControl.Change Where Committed='0'"
	Set rset=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set sc=rset.Prepare(sql)
	Set sc=rset.Execute()	
	While (rset.Next()) {
		If ('IncludeRevert)&&(rset.Data("Action")="revert") Continue
		Set UncommittedList(rset.Data("ItemFile"))=rset.Data("Action")
	}
	Quit $$$OK
}

/// Displays a list of Uncommitted items from the Uncommitted queue to the output device
/// <p>Only lists items with action of type 'revert' if the IncludeRevert flag is passed as true
ClassMethod DisplayUncommitted(ByRef UncommittedList, IncludeRevert = 0) As %Status
{
	If (..InstanceVersion() = "2010.1")&&($zu(23,1)=32) { Set oldcol=$zu(23,1,5) }		; Spanish2 collation on 2010.1 must be avoided
	Set sc=$$$OK
	Try {
		If '$DATA(UncommittedList) Set sc=..ListUncommitted(.UncommittedList,IncludeRevert) If $$$ISERR(sc) Quit
		Write $TRANSLATE($JUSTIFY(" ",80)," ","-"),!
		Write "Action",?10,"Internal Name",?60,"Owner",?72,"CCR",!
		Write "Source",?10,"Item",?60,"Last Updated",!
		Write $TRANSLATE($JUSTIFY(" ",80)," ","-"),!
		Set cnt=0,item="", item=$ORDER(UncommittedList(item))
		While (item'="") {
			Set sc=..GetUncommitted(item,.tAction,.tInternalName,.tChangedBy,.tSource,.tUpdated,,.tCCR)	
			If $$$ISERR(sc) Set item=$ORDER(UncommittedList(item)) continue
			If ('IncludeRevert)&&(tAction="revert") Set item=$ORDER(UncommittedList(item)) continue
			Write tAction,?10,tInternalName,?60,tChangedBy,?72,tCCR,!
			If item[^Sources {
				Write tSource,?10,"..."_$E(item,$L(^Sources),$L(item)),?60,tUpdated,!
			} Else {
				Write tSource,?10,item,!
				Write ?60,tUpdated,!
			}
			Set cnt=$INCREMENT(cnt)
			Set item=$ORDER(UncommittedList(item))
		}
		Write $TRANSLATE($JUSTIFY(" ",80)," ","-"),!
		Write "Count = "_cnt,!
		Write "Root  = "_^Sources,!
		Write $TRANSLATE($JUSTIFY(" ",80)," ","-"),!,!
	} Catch err {
		Set sc=err.AsStatus()
		Do $system.Status.DisplayError(sc)	
	}
	
	If $data(oldcol) { Set oldcol=$zu(23,1,oldcol) }

	Quit sc
}

/// Goes through Uncommitted queue and removes any items of action 'edit' or 'add' which are ReadOnly or non-existent on the filesystem
ClassMethod RefreshUncommitted(Display = 1, IncludeRevert = 0) As %Status
{
	Set sc=..ListUncommitted(.tFileList,IncludeRevert,0)
	If $$$ISERR(sc) Quit sc
	Set filename="", filename=$ORDER(tFileList(filename),1,action)
	While (filename'="") {
		Set examine=$Select(action="add":1,action="edit":1,IncludeRevert&&(action="revert"):1,1:0)
		If 'examine Set filename=$ORDER(tFileList(filename),1,action) continue
		If (##class(%File).ReadOnly(filename))||('##class(%File).Exists(filename)) {
			Set sc=..RemoveUncommitted(filename,Display,0,0)	
			If $$$ISERR(sc) s filename="" continue
		}
		Set filename=$ORDER(tFileList(filename),1,action)
	}
	Quit sc
}

/// This callback method is invoked when the current object is added to the SaveSet,
/// either because %Save() was invoked on this object or on an object that references this object.
/// %OnAddToSaveSet can modify the current object. It can also add other objects to the current
/// SaveSet by invoking %AddToSaveSet or remove objects by calling %RemoveFromSaveSet.
/// 
/// <P>If this method returns an error status then %Save() will fail and the transaction
/// will be rolled back.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If ..ChangedBy="" Set ..ChangedBy=$USERNAME
	If ..Name="" Set ..Name=..InternalName
	Quit $$$OK
}

/// Handles all compile-time logic for this class
/// [Previously private]
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

/// Returns value the Major.Minor version for this instance, so it can be used in comparison code which makes sure certain features are used in appropriate versions
ClassMethod InstanceVersion() As %Numeric [ CodeMode = expression ]
{
$P($SYSTEM.Version.GetNumber(),".",1,2)
}

/// Check indexes defined in this class build them if they have never been built.
/// Any errors are thrown as an exception.
ClassMethod BuildNewIndexes() [ CodeMode = objectgenerator, Internal ]
{
 #; compute data and index locations and the list of indexes
	Set tStorage=%compiledclass.Storages.GetAt(1) //it would be more correct to check the StorageStrategy, but we know we only have one storage
	Set tDataLoc=tStorage.DataLocation,tIndexLoc=tStorage.IndexLocation,tIndexList=""
	For tKey=1:1:%compiledclass.Indices.Count() {
		Set tIndex=%compiledclass.Indices.GetAt(tKey)
		If ('tIndex.IdKey) {
			 Set tIndexList=tIndexList_$ListBuild(tIndex.Name)
		}
	}
	Do %code.WriteLine("	Set tIndexList="""" ")
 #; do nothing if there is nothing to do in this namespace (no data)
	Do %code.WriteLine("	If $Data("_tDataLoc_")'=11 { Quit }") 
 #; generate the for loop to check the indexes
	Do %code.WriteLine("	For tIndex="""_$ListToString(tIndexList,""",""")_""" {")
	Do %code.WriteLine("		Set:$Data("_tIndexLoc_"(tIndex))\2=0 tIndexList=tIndexList_$ListBuild(tIndex)")
	Do %code.WriteLine("	}")
 #; now build the indexes if any need to be built
	Do %code.WriteLine("	If tIndexList'="""" {")
	Do %code.WriteLine("		Write ""Building "_%classname_" Indexes in "",$namespace,"": ""_$ListToString(tIndexList,"", ""),!!")
	Do %code.WriteLine("		Set tSC=..%BuildIndices(tIndexList,1,1)")
	Do %code.WriteLine("		If $$$ISERR(tSC) {")
	Do %code.WriteLine("			Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)")
	Do %code.WriteLine("		}")
	Do %code.WriteLine("	}")
 #; all done
	Quit $$$OK
}

Storage Default
{
<Data name="ChangeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Action</Value>
</Value>
<Value name="3">
<Value>Committed</Value>
</Value>
<Value name="4">
<Value>CommittedTime</Value>
</Value>
<Value name="5">
<Value>CCR</Value>
</Value>
<Value name="6">
<Value>InternalName</Value>
</Value>
<Value name="7">
<Value>ItemFile</Value>
</Value>
<Value name="8">
<Value>Name</Value>
</Value>
<Value name="9">
<Value>P4Issued</Value>
</Value>
<Value name="10">
<Value>Source</Value>
</Value>
<Value name="11">
<Value>UpdatedTime</Value>
</Value>
<Value name="12">
<Value>ChangedBy</Value>
</Value>
<Value name="13">
<Value>ActivelyCommitted</Value>
</Value>
</Data>
<DataLocation>^Studio.SourceControl.ChangeD</DataLocation>
<DefaultData>ChangeDefaultData</DefaultData>
<IdLocation>^Studio.SourceControl.ChangeD</IdLocation>
<IndexLocation>^Studio.SourceControl.ChangeI</IndexLocation>
<StreamLocation>^Studio.SourceControl.ChangeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
