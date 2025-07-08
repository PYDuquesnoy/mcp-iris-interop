/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// To implement a new routine type to be used by Studio you subclass from this abstract
/// routine class and fill in the methods to perform your own Load/Save/Compile/Delete/Lock
/// functions.
Class %Studio.AbstractDocument Extends %AbstractStream [ Abstract, System = 3 ]
{

/// The extension name, this can be a comma separated list of extensions if this class supports more than one.
/// For details on the projection parameters see <class>%Projection.StudioDocument</class>.
Projection RegisterExtension As %Projection.StudioDocument(DocumentDescription = "", DocumentExtension = "", DocumentIcon = 0, DocumentNew = 0, DocumentType = "", XMLNamespace = "");

/// The body of the routine is held in this stream
Property Code As %GlobalCharacterStream;

/// The name of this routine, this includes the routine extension
Property Name As %String;

/// Timestamp of the current document
Property TimeStamp As %TimeStamp [ Calculated ];

/// Timestamp of the last compile of this document
Property CompileTime As %TimeStamp [ Calculated ];

/// True if this routine is generated from something else
Property Generated As %Boolean;

/// Used to hold the number of times this document is locked.
/// It happens to be used by the default lock implementation but you may ignore this
/// in your subclass if you wish.
Property Locked As %Integer [ InitialExpression = 0 ];

/// Return true if the document is up to date with respect to the compiled version, i.e. if you recompiled this document
/// then the generated compiled code would be the same. Return false if the source document is modified but not compiled
/// or the generated code has been modified manually.
Property UpToDate As %Boolean [ Calculated ];

Method UpToDateGet() As %Boolean
{
	#; Just call the class method which can implement the real logic
	Quit ..IsUpToDate(..Name)
}

/// Delimiter to use when constructing directories for this document type.
/// This only applies if you write the List query. If you override the <method>ItemList</method>
/// then you must insert this into ^IRIS.Temp structure yourself.
/// Note do not use '/' or '\' as a delimiter as these are reserved for CSP files.
Parameter Delimiter = ".";

Method %Load(sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
 Quit $$$OK
}

ClassMethod %DeleteData(soid As %String, concurrency As %Integer) As %Status [ Private, ProcedureBlock = 1 ]
{
	QUIT $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Quit $$$OK
}

/// Set the name property
Method %OnNew(name As %String) As %Status [ Private ]
{
	Set ..Name=name
	#; If the routine does not exist already then do not call Load
	If '##class(%RoutineMgr).Exists(name) Quit $$$OK
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeLoad(name)
	Set sc=..Load()
	If $$$ISERR(sc) Quit sc
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Set sc=tmp.OnAfterLoad(name,$this)
	Quit sc
}

Method SaveStream(SupressBackup As %Boolean = 0, Output Refresh As %Boolean) As %Status
{
	Set Refresh=0
	Set code=..Code
	Do code.Rewind(),$System.Encryption.SHA1HashResult()
	While 'code.AtEnd { Do $system.Encryption.SHA1HashInput($listbuild(code.Read(16000))) }
	Set before=$System.Encryption.SHA1HashResult()
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeSave(..Name,,$this)
	Set sc=..Save()
	If $$$ISERR(sc) Quit sc
	If $isobject($get(%SourceControl)) Do
	. Set tmp=%SourceControl New %SourceControl Set sc=tmp.OnAfterSave(..Name,$this)
	Do code.Rewind(),$System.Encryption.SHA1HashResult()
	While 'code.AtEnd { Do $system.Encryption.SHA1HashInput($listbuild(code.Read(16000))) }
	If $System.Encryption.SHA1HashResult()'=before {
		Set Refresh=1
		If $isobject($get(%SourceControl)),$get(%SourceControl.Modified)=1 Set %SourceControl.Modified(..Name)=1
	}
	Quit sc
}

Method TimeStampGet() As %TimeStamp [ CodeMode = expression, Final ]
{
..TimeStamp(..Name)
}

Method CompileTimeGet() As %TimeStamp [ CodeMode = expression, Final ]
{
..CompileTime(..Name)
}

/// Load the routine in Name into the stream Code
Method Load() As %Status
{
	Quit $$$OK
}

/// Save the routine stored in Code
Method Save() As %Status
{
	Quit $$$OK
}

/// Save this document with a new name.
/// You may want to modify this depending on how this implementation will
/// work for your class.
Method SaveAs(name As %String) As %Status
{
	Set oldname=..Name,..Name=name
	If ..Locked {
		#; We need to try getting the lock on the new name before releasing the old name
		Set locked=..Locked
		#; Set Locked=0 to force the lock to take out a Lock +
		Set ..Locked=0
		Set sc=..Lock()
		If $$$ISERR(sc) Set ..Locked=locked,..Name=oldname Quit sc
		#; Set Locked=1 to force the unlock to remove the Lock +
		Set ..Name=oldname,..Locked=1
		Do ..Unlock()
		Set ..Name=name,..Locked=locked
	}
	Quit ..Save()
}

/// Compile the document, with source control hooks
Method Compile(flags As %String) As %Status
{
	Set sc=$$$qualifierParse("Compiler",.flags,.qstruct) q:$$$ISERR(sc) sc
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(sc) Quit sc
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set sc=tmp.OnBeforeCompile(..Name,.qstruct)
	. If $$$ISERR(sc) Kill errcount Do DecomposeStatus^%apiOBJ(sc,.errcount,.qstruct) $$$IncErrorNums(errcount)
	Do
	. New %SourceControl
	. Set sc=..CompileDocument(.qstruct)
	If $isobject($get(%SourceControl)) Do
	. $$$SuspendErrorCount
	. Set tmp=%SourceControl New %SourceControl
	. Set rc=tmp.OnAfterCompile(..Name)
	. If $$$ISERR(rc) Kill errcount Do DecomposeStatus^%apiOBJ(rc,.errcount,.qstruct) $$$IncErrorNums(errcount) Set sc=$$$ADDSC(sc,rc)
	Quit sc
}

/// CompileDocument is called when the document is to be compiled.
/// It has already called the source control hooks at this point.
Method CompileDocument(ByRef qstruct As %String) As %Status
{
	Quit $$$OK
}

/// Delete the routine 'name' which includes the routine extension
ClassMethod Delete(name As %String) As %Status
{
	Quit $$$OK
}

/// Lock the current routine. The default method just locks the ^ROUTINE global with the name of the routine.
/// If it fails then return a status code of the error, otherise return $$$OK
Method Lock(flags As %String) As %Status
{
	If ..Locked Set ..Locked=..Locked+1 Quit $$$OK
	Lock +^ROUTINE(..Name):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,..Name)
	Set ..Locked=1
	Quit $$$OK
}

/// Lock a document by name.  The default method just locks the ^ROUTINE global with the name of the document.
ClassMethod LockName(name As %String) As %Status
{
	Lock +^ROUTINE(name):0 Else  Quit $$$ERROR($$$CanNotLockRoutine,name)
	Quit $$$OK
}

/// Unlock the current routine. The default method just unlocks the ^ROUTINE global with the name of the routine.
Method Unlock(flags As %String) As %Status
{
	If '..Locked Quit $$$OK
	If ..Locked>1 Set ..Locked=..Locked-1 Quit $$$OK
	Lock -^ROUTINE(..Name)
	Set ..Locked=0
	Quit $$$OK
}

/// Unlock a document by name. The default method just unlocks the ^ROUTINE global with the name of the document.
ClassMethod UnlockName(name As %String) As %Status
{
	Lock -^ROUTINE(name)
	Quit $$$OK
}

/// Return the timestamp of routine 'name' in %TimeStamp format. This is used to determine if the routine has
/// been updated on the server and so needs reloading from Studio. So the format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
	Quit ""
}

/// Return the compile time of routine 'name' in %TimeStamp format. The format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod CompileTime(name As %String) As %TimeStamp
{
	Quit ""
}

/// Return true if the document is up to date with respect to the compiled version, i.e. if you recompiled this document
/// then the generated compiled code would be the same. Return false if the source document is modified but not compiled
/// or the generated code has been modified manually.
ClassMethod IsUpToDate(name As %String) As %Boolean
{
	Quit 1
}

/// Return 1 if the routine 'name' exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
	Quit 0
}

/// This method ties into the open dialog in Studio.
/// It is passed a list of information based on the search criteria from the user and it should
/// populate the ^||%RoutineList(Idx) global with the items it wishes to show in the following format:<p>
/// ^||%RoutineList(Idx,dirtype,order_$char(0)_index)=$listbuild(name,dirsymbol,type,size,date/time,description)
/// <ul>
/// <li>Idx - The index provided in the 'Idx' parameter</li>
/// <li>dirtype - This is 1 if this is a regular openable item and 0 if this is a directory so that
/// directories show up before the other items in the open dialog</li>
/// <li>order - The value based on the sorting order of items, e.g. size or date/time last modified, more information
/// on this below</li>
/// <li>index - An integer index to prevent multiple items with for example the same size from over writing each
/// other.</li>
/// <li>name - The name to display in the open dialog</li>
/// <li>dirsymbol - The symbol to use to navigate directories, for regular items this is "" but for directories
/// this should be the character to append to the directory in order to browse into this directory. Do not use
/// '/' or '\' as these are reserved for CSP files</li>
/// <li>type - This is an integer version of the type of the item, see the list below for details</li>
/// <li>size - The size of this item as an integer</li>
/// <li>date/time - The date/time this item was last modified in %TimeStamp format, or "" if not known</li>
/// </ul>
/// <p>
/// The type of the item which can be one of:
/// <ul>
/// <li>0  - MAC file, a routine containing macros</li>
/// <li>1  - INT file, a standard routine</li>
/// <li>2  - INC file, an include file</li>
/// <li>3  - BAS file, a Cache Basic routine</li>
/// <li>4  - CLS, a class</li>
/// <li>5  - CSP, a Cache Server Page or another file in this directory</li>
/// <li>7  - GBL, a Global</li>
/// <li>8  - PRJ, a Project</li>
/// <li>9  - a Package</li>
/// <li>10 - a CSP application</li>
/// </ul>
/// Further numbers are reserved for future use. User defined items should start at 100.
/// <p>
/// order is one of:
/// <ul>
/// <li>1 - Name of the file non case sensitive (the default)</li>
/// <li>2 - Date/Time the file was saved</li>
/// <li>3 - Size of the file</li>
/// <li>4 - Type of the file i.e. the number from the 'type' list</li>
/// <li>5 - Name of the file case sensitive</li>
/// </ul>.
/// <p>
/// The arguments to this method are:
/// <ul>
/// <li>Idx - Index into ^||%RoutineList to write data</li>
/// <li>Ext - Extension name we are processing</li>
/// <li>Work - Array of pattern match information that we test each item against, root node is $listbuild(mapped) so you can see if we want to return
/// mapped items</li>
/// <li>Start - First possible match, can be used to optimise the query</li>
/// <li>End - Last possible match, can be used to optimise the query</li>
/// <li>Directory - The directory name we are searching</li>
/// <li>Sort - The entry to sort by, same as the list for 'order'</li>
/// <li>System - If true then include the '%' routines/classes</li>
/// <li>Flat - If true then flatten directories to return items inside them, this is used by the
/// 'Namespace' tab in Studio to display all items in the system</li>
/// <li>ShowGenerated - If false then do not show items generated from something else, e.g. do not show TEST.INT
/// if this is compiled from TEST.MAC</li>
/// <li>NewFormat - Returned by reference, if set to true use the new ^||%RoutineList format, else caller will convert output to the new format</li>
/// </ul>
ClassMethod ItemList(Idx As %Integer, Ext As %String, ByRef Work As %String, Start As %String, End As %String, Directory As %String, Sort As %Integer, System As %Boolean, Flat As %Boolean, ShowGenerated As %Boolean, ByRef NewFormat As %Boolean) As %Status
{
	#; This default implementation just requires a query that walks over the list of documents
	#; returning each in turn. It performs the checks on the patterns itself and creates the
	#; ^||%RoutineList global. If you have a more complex case or need more performance you may need
	#; to rewrite this method rather than just writing the iterator.
	Set index="",qHandle="",sc=$$$OK,data="",NewFormat=1
	Set sc=..ListExecute(.qHandle,Directory,Flat,System) If $$$ISERR(sc) Quit sc
	Set sc=..ListFetch(.qHandle,.data,.atend) If $$$ISERR(sc) Quit sc
	While $get(data)'="" {
		Set item=$listget(data)
		Set i=$order(Work(""),1,work)
		While i'="" {
			Set pattern=$list(work),start=$list(work,2),end=$list(work,3)
			If start=""||(start']item),end=""||($extract(item,1,$length(end))']end),pattern=""||(item?@pattern) {
				Set order=$case(Sort,1:$zconvert($piece(item,".",1,$length(item,".")-1),"l"),2:$listget(data,2),3:$listget(data,3),4:100,5:$piece(item,".",1,$length(item,".")-1))
				If order="" Set order=0
				If $listget(data,4)'="" {
					Set order=$piece(item,".",1,$length(item,".")-1)
					Set ^||%RoutineList(Idx,0,$zconvert(order,"U")_$char(0)_$i(%insertidx))=$listbuild(item,..#Delimiter,9,$listget(data,3),$list(data,2),"")
				} Else {
					Set ^||%RoutineList(Idx,1,$zconvert(order,"U")_$char(0)_$i(%insertidx))=$listbuild(item,..#Delimiter,100,$listget(data,3),$list(data,2),"")
				}
				Quit
			}
			Set i=$Order(Work(i),1,work)
		}
		If atend Quit
		Set data=""
		Set sc=..ListFetch(.qHandle,.data,.atend) If $$$ISERR(sc) Quit
	}
	Do ..ListClose(.qHandle)
	Quit sc
}

/// Return other document types that this is related to.
/// Passed a name and you return a comma separated list of the other documents it is related to
/// or "" if it is not related to anything. Note that this can be passed a document of another type
/// for example if your 'test.XXX' document creates a 'test.INT' routine then it will also be called
/// with 'test.INT' so you can return 'test.XXX' to complete the cycle.
ClassMethod GetOther(Name As %String) As %String
{
	Quit ""
}

/// Return other document types that this is related to.
/// Passed a name and you return a comma separated list of the other documents it is related to
/// or "" if it is not related to anything. This goes in opposite direction to <method>GetOther</method>
/// function. It can be called with documents that are not of this document type as with
/// <method>GetOther</method>.
ClassMethod GetPrevious(Name As %String) As %String
{
	Quit ""
}

/// Export this document to the current device in XML format
Method ExportToXML(flags As %String) As %Status
{
	Do ..Code.Rewind()
	Do ..escapeCDataStream(..Code)
	Quit $$$OK
}

/// Passed a stream containing the XML document, this method should insert this
/// into the current document. Once this is done the importer will call Save
/// on the document. This default handler in assumes the export <method>ExportToXML</method>
/// just wrote the data in a CDATA structure
Method ImportFromXML(stream As %RegisteredObject, flags As %String) As %Status
{
	Set data=stream.Read(9)
	If data'="<![CDATA[" Quit $$$ERROR($$$StudioAbstractDocXMLErr)
	Do ..Clear()
	Set trail=stream.Read(2)
	If $extract(trail)=$char(10) {
		Set trail=$extract(trail,2,*)
	} ElseIf trail=$char(13,10) {
		Set trail=""
	}
	While 'stream.AtEnd {
		Set data=trail_stream.Read(32000)
		Set output=$replace(data,"]]]]><![CDATA[>","]]>")
		Do ..Write($extract(output,1,*-14)) Set trail=$extract(output,*-13,*)
	}
	Do ..Write($extract(trail,1,*-3))
	Quit $$$OK
}

/// Utility method to quote any ']]>' inside the code as these end the CDATA section
ClassMethod escapeCData(data As %String) As %String [ Private ]
{
	Quit $replace(data,"]]>","]]]]><![CDATA[>")
}

/// Utility method to quote any ']]>' inside the code as these end the CDATA section
ClassMethod unescapeCData(data As %String) As %String [ Private ]
{
	Quit $replace(data,"]]]]><![CDATA[>","]]>")
}

/// Utility method to escape any ']]>' inside a CDATA section
ClassMethod escapeCDataStream(stream As %Stream.Object) [ Private ]
{
	Set buffer=""
	Write "<![CDATA[",!
	While '(stream.AtEnd) {
		Set buffer=buffer_stream.Read(6500)
		#; Read is small enough this can not get MAXSTRING
		Set output=$replace(buffer,"]]>","]]]]><![CDATA[>")
		Write $extract(output,1,*-2) Set buffer=$extract(output,*-1,*)
	}
	Write buffer_"]]>"
}

Method AtEndGet() As %Boolean [ CodeMode = expression, Final ]
{
..Code.AtEnd
}

Method AtEndSet(val As %Boolean) As %Status [ Final ]
{
	Set ..Code.AtEnd=val
	Quit $$$OK
}

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %String [ CodeMode = expression, Final ]
{
..Code.Read(.len,.sc)
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %String [ CodeMode = expression, Final ]
{
..Code.ReadLine(.len,.sc,.eol)
}

Method Write(data As %String) As %Status [ CodeMode = expression, Final ]
{
..Code.Write(data)
}

Method WriteLine(data As %String) As %Status [ CodeMode = expression, Final ]
{
..Code.WriteLine(data)
}

Method Flush() As %Status [ CodeMode = expression, Final ]
{
..Code.Flush()
}

Method Rewind() As %Status [ CodeMode = expression, Final ]
{
..Code.Rewind()
}

Method SizeGet() As %Integer [ CodeMode = expression, Final ]
{
..Code.Size
}

/// Clear the contents of this Stream from permanent storage. This will remove the permanent stream storage and
/// any temporary stream and initialise the stream to its initial state, including removing all
/// the stream attributes.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method Clear() As %Status [ CodeMode = expression, Final ]
{
..Code.Clear()
}

/// Move to the end of the stream so the next <METHOD>Write</METHOD> will be appended to the end.
/// This allows you to read from a stream, then MoveToEnd() and append new data, where just calling
/// <METHOD>Write</METHOD> after a read will clear the stream before writing new data.
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method MoveToEnd() As %Status [ CodeMode = expression, Final ]
{
..Code.MoveToEnd()
}

/// This query scans over the documents for the Studio open dialog.
/// The arguments are defined in <method>ItemList</method>.<p>
/// This should return a row formed by:<br>
/// $listbuild(name,date/time modified,size,directory delimiter)
/// <ul>
/// <li>name - The name to display in the open dialog</li>
/// <li>date/time modified - In %TimeStamp format the date/time this item was last modified</li>
/// <li>size - The size of this item</li>
/// <li>directory delimiter - If this is not a directory then return "" here, if it is a directory then
/// return the type of delimiter to use when they double click on this directory</li>
/// </ul>
Query List(Directory As %String, Flat As %Boolean, System As %Boolean) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer,directory:%String") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String, Flat As %Boolean, System As %Boolean) As %Status
{
 Quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
 Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListExecute ]
{
 Quit $$$OK
}

/// Override this to support searching inside your document type. By default it will open the document and search the <property>Code</property>.
/// <ul><li><var>Name</var> - Name of document to search</li>
/// <li><var>Pattern</var> - String to search for</li>
/// <li><var>WholeWords</var> - True if we only want to find whole words, false otherwise</li>
/// <li><var>CaseSensitive</var> - True if this is a case sensitive search</li>
/// <li><var>Max</var> - The maximum number of items to find, if we get to this limit stop outputting results and return</li>
/// <li><var>Found</var> - Passed by reference, contains a count of the number of matches we find. Increment by one for each match</li></ul>
/// When a match is found write out the match to the current device using the format <pre>&lt;CrLf&gt;&lt;Name&gt;(&lt;Line offset&gt;): &lt;Match line&gt;</pre>
ClassMethod Search(Name As %String, Pattern As %String, WholeWords As %Boolean, CaseSensitive As %Boolean, Max As %Integer, ByRef Found As %Integer)
{
#define check(%str,%pat,%case,%wild) $s(%wild:$s('%case:$zcvt(%str,"l"),1:%str)?@%pat,'%case:$zcvt(%str,"l")[%pat,1:%str[%pat)
	Set pattern=$select(CaseSensitive:Pattern,1:$zconvert(Pattern,"l"))
	If pattern["?"||(pattern["*")||(WholeWords) {
		Set pattern=##class(%Studio.Project).pattern(pattern,WholeWords),wild=1
	} Else {
		Set wild=0
	}
	Set oref=..%New(Name)
	If oref=$$$NULLOREF Quit
	Set code=oref.Code
	For lineno=1:1 { Quit:code.AtEnd
		Set line=code.ReadLine()
		If $$$check(line,pattern,CaseSensitive,wild) {
			Write $char(13,10)_Name_"("_lineno_"): "_$zstrip(line,"<W") Set Found=Found+1 If Found'<Max Quit
		}
	}
	Quit
}

/// Helper method for <method>Search</method>. Check if this really matches the item we are searching for.
ClassMethod checkMatch(value As %String, Pattern As %String, WholeWords As %Boolean, CaseSensitive As %Boolean) As %Boolean [ Private ]
{
	If 'CaseSensitive Set value=$zconvert(value,"l"),Pattern=$zconvert(Pattern,"l")
	If WholeWords {
		Set found=$find(value,Pattern)
		While found'=0 {
			If $extract(value,found)?.P,$extract(value,found-$length(Pattern)-1)?.P Quit
			Set found=$find(value,Pattern,found)
		}
		If found=0 Quit 0
	}
	Quit value[Pattern
}

/// Override this to support searching inside your document type with a regular expression.
/// By default it will open the document and search the <property>Code</property>.
/// <ul><li><var>Name</var> - Name of document to search</li>
/// <li><var>Matcher</var> - A <class>%Regex.Matcher</class> object initialised with the search expression</li>
/// <li><var>Max</var> - The maximum number of items to find, if we get to this limit stop outputting results and return</li>
/// <li><var>Found</var> - Passed by reference, contains a count of the number of matches we find. Increment by one for each match</li></ul>
/// When a match is found write out the match to the current device using the format <pre>&lt;CrLf&gt;&lt;Name&gt;(&lt;Line offset&gt;): &lt;Match line&gt;</pre>
ClassMethod SearchRegex(Name As %String, Matcher As %Regex.Matcher, Max As %Integer, ByRef Found As %Integer)
{
	Set oref=..%New(Name)
	If oref=$$$NULLOREF Quit
	Set code=oref.Code
	For lineno=1:1 { Quit:code.AtEnd
		Set line=code.ReadLine()
		If Matcher.Match(line) {
			Write $char(13,10)_Name_"("_lineno_"): "_$zstrip(line,"<W")
			Set Found=Found+1 If Found'<Max Quit
		}
	}
	Quit
}

/// Returns true if this document type is enabled, and false to disable it
ClassMethod IsEnabled() As %Boolean
{
	Quit 1
}

ClassMethod LocalizeDescription(ext As %String, ByRef Description As %String(MAXLEN=500)) As %Status
{
	Quit $$$OK
}

/// Return true if this is generated and zero otherwise.
/// Default implementation opens instance to find the property value, it is much more efficient to override this to provide
/// a better implementation.
ClassMethod IsGenerated(name As %String) As %Boolean
{
	If '##class(%RoutineMgr).UserType(name,.cls) Quit 0
	Set rtn=$classmethod(cls,"%New",name)
	If '$isobject(rtn) Quit 0
	Quit rtn.Generated
}

/// Return true if this is mapped from a database other than the default routine database and zero otherwise.
/// Also set the source database in <var>sourcedb</var>.
ClassMethod IsMapped(name As %String, ByRef sourcedb As %String) As %Boolean
{
	Set sourcedb=$namespace
	Quit 0
}

/// Return true if the named global and optional subscripts are mapped from a database other 
/// than the default database and zero otherwise.<br>
/// It also sets the source database in <var>sourcedb</var> <br>
/// Any subscripts will be concatenated as per requirements of the GetGlobalDest API<br>
/// Used by subclasses in implementation of IsMapped()
ClassMethod IsMappedGlobal(globalWithAnySubscripts As %String, ByRef sourcedb As %String) As %Boolean
{
	Set sourcedb = $namespace
	Set globalName = $qsubscript(globalWithAnySubscripts,0)
	If ($qlength(globalWithAnySubscripts)>0) {
		Set subscriptString = ""
		For subscriptNum = 1:1:$qlength(globalWithAnySubscripts) {
			Set subscript = $qsubscript(globalWithAnySubscripts,subscriptNum)
			Set subscriptString = subscriptString _ $Select(subscriptString'="":",",1:"") _ $$$quote(subscript)
		}
	} Else {
		Set subscriptString = "" /* either empty string or acceptable %SYS.Namespace).GetGlobalDest subscript  value */
	}

	Set sourcedb=##class(%SYS.Namespace).GetGlobalDest($namespace,globalName,subscriptString)
	/* Compare the db with default */
	Set isMapped=(sourcedb'=##class(%SYS.Namespace).GetGlobalDest($namespace,"^"))
	/*	prepend ^ to be same as %RoutineMgr::IsMapped macro $$$GBLDBREF
		for implied namespace ^^ requirement when no system specified */
	If $piece(sourcedb,"^") = "" {
		Set sourcedb="^"_sourcedb
	}
	Return isMapped
}

/// Can be used to translate the type of document to be exported to XML.
/// For example if asked to export 'abc.tst' it can:
/// <example>Set items("User.abc.cls")=""</example>
/// Which will cause the XML export to export the class User.abc instead of this abc.tst document.
/// Default behavior is to export the regular document.
ClassMethod TranslateExportName(name As %String, ByRef items As %String) As %Status
{
	Quit $$$OK
}

}
