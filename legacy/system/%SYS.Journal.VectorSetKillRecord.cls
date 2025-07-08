/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syJrninc, %syGluedef)

/// Journal Vector SET/Vector KILL record related API
Class %SYS.Journal.VectorSetKillRecord Extends %SYS.Journal.SetKillRecord [ System = 4 ]
{

Parameter READONLY = 1;

/// Cluster journal sequence number of the record on a clustered system or 0 otherwise
Property ClusterSequence As %Integer [ Calculated ];

/// Directory path of the database updated by the vector operation 
Property DatabaseName As %SysPath [ Calculated ];

/// Mirror database name of the database updated by the vector operation if it is a mirrored database
Property MirrorDatabaseName As %String [ Calculated ];

/// Extended global reference of the global holding the node which is the target of the vector operation
Property GlobalReference As %VarString [ Calculated ];

/// Global node holding the vector which is the target of the vector operation (<property>GlobalReference</property> minus the namespace)
Property GlobalNode As %VarString [ Calculated ];

/// Number of data values stored in the record. It can be 0, 1 or 2 depending on
/// whether the record is a Vector SET or Vector KILL and whether it is in a transaction.
Property NumberOfValues As %Integer [ Calculated ];

/// (For Vector SET record only) The value the vector element was set to
Property NewValue As %VarString [ Calculated ];

/// (For <property>InTransaction</property> record only) The value of the vector element prior to the vector operation
Property OldValue As %VarString [ Calculated ];

/// The collation of the subscripts in <property>GlobalNode</property>
Property Collation As %Integer [ Calculated ];

/// The index into the vector for set $vector(gref, index, type)=value or kill $vector(gref, index)
Property VecIndex As %Integer [ Calculated ];

/// The string value representing the type of the vector which is the target of the vector operation </property>
Property VecType As %String [ Calculated ];

Method %LoadData(Offset As %String, flag As %Boolean) As %Status [ Private ]
{
	q ##super(Offset,$g(flag))
}

Method VecIndexGet() As %Integer
{
	q $$$JRNVECINDEX(i%Address)
}

Method VecTypeGet() As %String
{
	q $$$JRNVECTYPE(i%Address)
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
	s x=$zu(68,7,1),node=$$$JRNNODE(i%Address)
	#; node may be -1 with invalid i%Address (due to jrnswitch etc.)
	try {
		s node=$name(@node)
	} catch {
		s x=$zu(68,7,x)
		d $zu(96,3,$$$ERGETINVALID) ;exit w/ <CANNOT GET THIS PROPERTY>
	}
	s x=$zu(68,7,x)
	q node
}

Method NumberOfValuesGet() As %Integer [ CodeMode = expression ]
{
$$$JRNNUMDATA(i%Address)
}

/// TRUE if there is a <property>NewValue</property> (including "") in the record
Method ExistsNewValue() As %Boolean [ CodeMode = expression ]
{
(i%Type=$$$JRNVECSET)
}

/// TRUE if there is an <property>OldValue</property> (including "") in the record
Method ExistsOldValue() As %Boolean [ CodeMode = expression ]
{
(..NumberOfValues>1)||((i%Type=$$$JRNVECKILL)&&..NumberOfValues)
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

/// Restore a Vector SET or a Vector KILL
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

Storage JournalVectorSetKill
{
<Type>%CustomStorage</Type>
}

Storage JournalVectorSetKillRecordStorage
{
<Type>%CustomStorage</Type>
}

}
