/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %syGluedef)

/// Journal SET/KILL record related API
Class %SYS.Journal.SetKillRecord Extends %SYS.Journal.Record [ System = 4 ]
{

Parameter READONLY = 1;

/// Cluster journal sequence number of the record on a clustered system or 0 otherwise
Property ClusterSequence As %Integer [ Calculated ];

/// Directory path of the database updated by the SET or KILL 
Property DatabaseName As %SysPath [ Calculated ];

/// Mirror database name of the database updated by the SET or KILL if it is a mirrored database
Property MirrorDatabaseName As %String [ Calculated ];

/// Extended global reference of the SET or KILL
Property GlobalReference As %VarString [ Calculated ];

/// Global node of the SET or KILL (<property>GlobalReference</property> minus the namespace)
Property GlobalNode As %VarString [ Calculated ];

/// Number of data values stored in the record. It can be 0, 1 or 2 depending on
/// whether the record is a SET or KILL and whether it is in a transaction.
Property NumberOfValues As %Integer [ Calculated ];

/// (For SET record only) The value the global node was set to
Property NewValue As %VarString [ Calculated ];

/// (For <property>InTransaction</property> record only) The value of the global node prior to the SET or KILL
Property OldValue As %VarString [ Calculated ];

/// The collation of the subscripts in <property>GlobalNode</property>
Property Collation As %Integer [ Calculated ];

Method %LoadData(Offset As %String, flag As %Boolean) As %Status [ Private ]
{
	q ##super(Offset,$g(flag))
}

Method ClusterSequenceGet() As %Integer
{
	q $$$JRNCLUSEQ(i%Address)
}

Method DatabaseNameGet() As %String
{
	q $$$JRNDIR(i%Address)
}

Method MirrorDatabaseNameGet() As %String [ CodeMode = expression ]
{
$$$JRNMIRDBNAME(i%Address)
}

Method GlobalReferenceGet() As %String
{
	q $$$JRNNODE(i%Address)
}

Method GlobalNodeGet() As %String
{
	s node=$$$JRNNODE(i%Address)
	i $e(node)="^" {
		s $p(node,"""",2)="" ;clear the database directory
		s node="^"_$p(node,"]",2,*)
	} else {
		#; node may be -1 with invalid i%Address (due to jrnswitch etc.)
		d $zu(96,3,$$$ERGETINVALID) ;exit w/ <CANNOT GET THIS PROPERTY>
	}
	q node
}

Method NumberOfValuesGet() As %Integer [ CodeMode = expression ]
{
$$$JRNNUMDATA(i%Address)
}

/// TRUE if there is a <property>NewValue</property> (including "") in the record
Method ExistsNewValue() As %Boolean [ CodeMode = expression ]
{
(i%Type=$$$JRNSET)||(i%Type=$$$JRNBITSET)||(i%Type=$$$JRNNSET)||(i%Type=$$$JRNMIRSET)||(i%Type=$$$JRNQADD)
}

/// TRUE if there is an <property>OldValue</property> (including "") in the record
Method ExistsOldValue() As %Boolean [ CodeMode = expression ]
{
(..NumberOfValues>1)||(((..TypeName["KILL")||(i%Type=$$$JRNQREM))&&..NumberOfValues)
}

Method NewValueGet() As %String [ CodeMode = expression ]
{
$s(..ExistsNewValue():$$$JRNNEWVAL(i%Address),1:"")
}

Method OldValueGet() As %String [ CodeMode = expression ]
{
$s(..ExistsOldValue():$$$JRNOLDVAL(i%Address),1:"")
}

Method CollationGet() As %Integer
{
	q $$$JRNCOLLATE(i%Address)
}

/// Restore a SET or KILL
Method Restore(Detail As %Integer) As %Status
{
	s $zt="Error"
	s dir=..DatabaseName i dir="" q $$$ERROR($$$JournalRecordBadDirectory)
	s gloref=..GlobalReference s $zt="GloErr" i $g(@gloref) ;test syntax
	i Detail ;TODO more: get value, actually restore this record, etc.
	s $zt="Error"
	q $$$OK
GloErr s $zt="" q $$$ERROR($$$JournalRecordBadGlobalNode) ;various errors
Error s $zt="" 
    q $$$ERROR($$$ObjectScriptError,$ze)
}

Method Fetch(ByRef Row As %List, ByRef Columns As %String, Match As %List = "") As %Boolean [ Internal, PublicList = (col, match, Row, Columns) ]
{
	q ##super(.Row,.Columns,Match)
}

Storage JournalRecordStorage
{
<Type>%Library.CustomStorage</Type>
}

Storage JournalSetKill
{
<Type>%CustomStorage</Type>
}

Storage JournalSetKillRecordStorage
{
<Type>%CustomStorage</Type>
}

}
