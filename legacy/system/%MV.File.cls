/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include LANG11

Class %MV.File Extends %RegisteredObject [ ServerOnly = 1, System = 4 ]
{

Property %StorageType As %Integer [ InitialExpression = {$$$MVFIOTypeUndef} ];

Property %FileName As %String;

Property %Namespace As %String;

Property %DictFlag As %Integer [ InitialExpression = 0 ];

Property %Global As %String;

Property %Account As %String;

Property %TargetAccount As %String;

Property %TargetFileName As %String;

Property %IsBinary As %Boolean [ InitialExpression = 0 ];

Property %IsTranslated As %Boolean [ InitialExpression = 1 ];

Property %COSName As %String;

Property %LockName As %String;

Property %ClassName As %String;

Property %IndexType As %Integer [ InitialExpression = 0 ];

Property %IndexRoutine As %String;

/// When the file variable is produced as a result of OPENINDEX
/// then the index that was opened is stored here for future use by any select
/// lists. Note that at the moment index storage is restricted to the default
/// of ^INDEXGLOBAL("indexName",... and we may need to review this, though it
/// is unlikely to be an issue
/// 
Property %IndexName As %String;

/// A select list can represent an index. An index stores the actual keys
/// as oppposed to the key values returned by READNEXT in collated encoding
/// sequence such as MV R or SPACE (equivlant to MV L) etc.
/// This property defines the collation in use for the index.
/// 
Property %IndexCollation As %Integer [ InitialExpression = 0 ];

/// Simpler index functions such as BSCAN, expect the file variable to track the last index
/// access. In order to allow this, we store these in an array, subscripted by index name.
/// The top level is used to track when BSCAN walks over the global itself, instead of
/// an index.
/// 
Property %BSCAN As %String [ MultiDimensional ];

/// Flag to determine if index names/collations has been loaded yet
/// 
Property %IndFlag As %Boolean [ InitialExpression = 0 ];

/// $LIST of index names that can be used by index functions
/// 
Property %IndNames As %String;

/// $LIST of index collations that can be used by index functions
/// 
Property %IndColl As %String;

/// String of index MV flags (0->S,1->M) that can be used by index functions
/// 
Property %IndMV As %String;

/// Options (from attribute 6)
/// 
Property %Options As %String;

/// Stores the name of the generated COS routine (including namespace) that must be
/// called if this file descriptor is subject to any of the file trigger processing
/// options described below.
/// 
/// How this works is that when a file is opened the FireTriggers flag is set
/// (if there are ANY triggers). When any MVFIO routine is called it checks to see
/// if this flag is set and if it is, then it checks to see if there are triggers
/// for this specific operation (may do this the other way around). If both tests
/// pass then control is transferred to the named COS routine TriggerRoutine.
/// The first thing the entry point for the particular IO function does is turn
/// that flag off. It is then free to call the BASIC subroutines pre and post
/// operation and call back in to the MVFIO system to do the actual operation
/// (which will this time not fire the COS routine).
/// 
Property %TriggerRoutine As %String;

/// This integer flag stores a number of bits indicating which, if any MVFIO
/// operations must operate trigger subroutines. If the bit corresponding to the
/// operation at hand is set, and the trigger processing is not currently executing
/// then a specific COS routine entry point will be be queued up by the MVFIO C
/// routine and the processing function will DISP to it.
/// 
Property %TriggerOperations As %Integer [ InitialExpression = 0 ];

/// This boolean flag indicates that the MVFIO routines must process trigger calls
/// when it is set to TRUE. The trigger routine itself will clear this flag to call
/// back in to MVFIO to process the operation then set it back to TRUE when the
/// operation is complete. This allows Pre and Post operations to exist for an
/// MVFIO function without interfering with the indexing routine calls.
/// 
Property %FireTriggers As %Integer [ InitialExpression = 0 ];

/// Case preserving form of file name
/// 
Property %CasePreserveName As %String;

/// IO table used for reading or writing to the files in this directory
/// 
Property %IOTable As %String;

/// Namespace for Class
/// 
Property %ClassNamespace As %String;

/// Section Name when not the default data section
/// 
Property %SectionName As %String;

Method Dump() As %Status
{
    #; Display all instance variables for this object
    W "StorageType:"	W:$d(i%%StorageType) ?18,i%%StorageType	W !
    W "FileName:"	W:$d(i%%FileName) ?18,$$outstr(i%%FileName) W !
    W "Namespace:"	W:$d(i%%Namespace) ?18,$$outstr(i%%Namespace) W !
    W "DictFlag:"	W:$d(i%%DictFlag) ?18,i%%DictFlag W !
    W "Global:"		W:$d(i%%Global) ?18,$$outstr(i%%Global) W !
    W "Account:"	W:$d(i%%Account) ?18,$$outstr(i%%Account) W !
    W "TargetAccount:"	W:$d(i%%TargetAccount) ?18,$$outstr(i%%TargetAccount) W !
    W "TargetFileName:"	W:$d(i%%TargetFileName) ?18,$$outstr(i%%TargetFileName) W !
    W "COSName:"	W:$d(i%%COSName) ?18,$$outstr(i%%COSName) W !
    W "LockName:"	W:$d(i%%LockName) ?18,$$outstr(i%%LockName) W !
    W "ClassName:"	W:$d(i%%ClassName) ?18,$$outstr(i%%ClassName) W !
    W "IndexName:"	W:$d(i%%IndexName) ?18,$$outstr(i%%IndexName) W !
    W "IndexCollation:"	W:$d(i%%IndexCollation) ?18,i%%IndexCollation W !
    W "BSCAN:"		W:$d(i%%BSCAN)#10 ?18,i%%BSCAN W !
    If $d(i%%BSCAN)\10 {
	Set n="" For { Set n=$o(i%%BSCAN(n)) Quit:n=""  W ?4,n,?18,i%%BSCAN(n),! }
    }
    W "IndFlag:"	W:$d(i%%IndFlag) ?18,i%%IndFlag W !
    W "IndNames:"	W:$d(i%%IndNames) ?18,$$outstr(i%%IndNames) W !
    W "IndColl:"	W:$d(i%%IndColl) ?18,$$outstr(i%%IndColl) W !
    W "IndMV:"		W:$d(i%%IndMV) ?18,$$outstr(i%%IndMV) W !
    W "Options:"	W:$d(i%%Options) ?18,$$outstr(i%%Options) W !
    W "FireTriggers:"	W:$d(i%%FireTriggers) ?18,i%%FireTriggers W !
    W "CasePreserveName:" W:$d(i%%CasePreserveName) ?18,$$outstr(i%%CasePreserveName) W !
    W "IOTable:"	W:$d(i%%IOTable) ?18,$$outstr(i%%IOTable) W !
    W "ClassNamespace:"	W:$d(i%%ClassNamespace) ?18,$$outstr(i%%ClassNamespace) W !
    W "SectionName:"	W:$d(i%%SectionName) ?18,$$outstr(i%%SectionName) W !
    Quit $$$OK
outstr(str) 
   Set ret="""" F i=1:1:$l(str) Set ret=ret_$s($e(str,i)="""":"""""",1:$e(str,i))
   Quit ret_""""
}

Method UnlockAll() As %Status
{
    #; Unlock all record and file locks for this file variable
    Do $$$DOMVUNLOCKFILE($this)
    Quit $$$OK
}

Method Close() As %Status
{
    #; Close a file variable, unlock all records and close files
    If i%%StorageType=$$$MVFIOTypeSeq {
	#; If it's a sequential file then close it
	Close i%%COSName
    }
    #; Unlock it
    Do $$$DOMVUNLOCKFILE($this)
    Quit $$$OK
}

Method %OnClose() As %Status
{
    If i%%StorageType=$$$MVFIOTypeSeq {
	#; If it's a sequential file then close it
	Close i%%COSName
    }
    #; Unlock it
    Do $$$DOMVUNLOCKFILE($this)
    Quit $$$OK
}

}
