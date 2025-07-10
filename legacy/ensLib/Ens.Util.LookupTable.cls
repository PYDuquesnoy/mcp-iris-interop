/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class wraps the ^Ens.LookupTable class used by the DTL/BusinessRule Lookup function.<br/>
/// This provides a convenient way to import, export or manipulate lookup data.
Class Ens.Util.LookupTable Extends (%Persistent, %XML.Adaptor) [ Final, Inheritance = right, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter XMLNAME = "entry";

/// Prevent any differentiation between "" and NULL in XML import and export.
Parameter XMLIGNORENULL = 1;

Index IDKEY On (TableName, KeyName) [ IdKey ];

/// Name of the lookup table.
Property TableName As %String(MAXLEN = 255, XMLNAME = "table", XMLPROJECTION = "attribute") [ Required ];

/// Key for entry within the lookup table.
Property KeyName As %String(MAXLEN = 255, XMLNAME = "key", XMLPROJECTION = "attribute") [ Required ];

/// Value associated with this key in the lookup table.
Property DataValue As %String(MAXLEN = 32000, XMLPROJECTION = "content");

/// Delete the contents of the lookup table <var>pTable</var>.
ClassMethod %ClearTable(pTable As %String)
{
	Kill ^Ens.LookupTable(pTable)
}

/// Does table <var>pTable</var> exist?
///  If <var>pCaseInsensitive</var> is 1, this will return true for case-insenstive matches too and
/// <var>pMatch</var> will be the matching value. 
ClassMethod %ExistsTable(pTable As %String, pCaseInsensitive As %Boolean = 0, pCurrent As %String = "", Output pMatch As %String = "") As %Boolean
{
	Quit:'pCaseInsensitive ''$D(^Ens.LookupTable(pTable))
	If ""=pTable { ; pCurrent is the entire name
		Set match = $S(""'=pCurrent:''$D(^Ens.LookupTable(pCurrent)),1:0)
		Set:match pMatch=pCurrent
		Quit match
	} Else {
		Set tLower = pCurrent_$zcvt($E(pTable),"L")
		If tLower = $e($o(^Ens.LookupTable(tLower)),1,$L(tLower)) { ; matches so far
			Set matchL = ..%ExistsTable($E(pTable,2,*),1,tLower,.pMatch)
		} ElseIf $L(pTable)<2 {
			Set matchL = ''$D(^Ens.LookupTable(tLower))
			Set:matchL pMatch = tLower
		}
		Quit:$G(matchL) 1 ; don't waste time on uppercase if already a match
		
		Set tUpper = pCurrent_$zcvt($e(pTable),"U")
		If tUpper = $e($o(^Ens.LookupTable(tUpper)),1,$L(tUpper)) {  ; matches so far
			Set matchU = ..%ExistsTable($E(pTable,2,*),1,tUpper,.pMatch)
		} ElseIf $L(pTable)<2 {
			Set matchU = ''$D(^Ens.LookupTable(tUpper))
			Set:matchU pMatch = tUpper
		}
		Quit $G(matchU,0)
	}
}

/// Import lookup table data from the xml file <var>pFileName</var>.<br/>
/// Lookup data is in the form:
/// <example language="xml!fragment">
/// <lookupTable>
/// <entry table="TableName" key="KeyName">DataValue</entry>
/// </lookupTable>
/// </example>
/// If <parameter>pForceTableName</parameter> is specified then the particular 
/// Lookup Table will be replaced if it exists by the entries being imported and 
/// <parameter>pCount</parameter> subscript ("Deleted") will be the count of table entries in the existing 
/// table that were deleted during the update of the table.<br>
/// If <parameter>pForceTableName</parameter> is not specified and the Lookup Table
/// exists then entries in the <parameter>pFileName</parameter> will be merged 
/// with the existing entries. <br>
/// <parameter>pCount</parameter> is the count of table entries in the import file.<br>
/// <parameter>pCount</parameter> subscript ("Updated")is the count of table entries in the import 
/// file that were used to update the table.<br>
ClassMethod %Import(pFileName As %String = "", pForceTableName As %String = "", ByRef pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Kill pCount
	Set pCount = 0, pCount("Updated") = 0, pCount("Deleted") = 0
	Set reader = ##class(%XML.Reader).%New()
	If $IsObject(pFileName) {
		Set tSC = reader.OpenStream(pFileName) Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tSC = reader.OpenFile(pFileName) Quit:$$$ISERR(tSC) tSC
	}
	Do reader.Correlate("entry",$classname())
	Set tFirstName=""
	Set tForceTableLocked = 0
	Set tInTransaction = 0
	Try {
		TSTART
		Set tInTransaction = 1
		If pForceTableName '= "" {
			Lock +^Ens.LookupTable(pForceTableName):2
			/*	Not clearing the table first - pruning after.
				Using a PPG to record entries to keep because a lookup table can be large
			*/
			Kill ^||enslutKeep
			If '$Test {
				Set tSC = $$$ERROR($$$LockFailedToAcquireExclusive,$name(^Ens.LookupTable(pForceTableName)))
				Quit
			}
			Set tForceTableLocked = 1
			
		}
		While (reader.Next(.entry,.tSC) && $$$ISOK(tSC)) {
			If (""'=pForceTableName) {
				If ""=tFirstName {
					Set tFirstName=entry.TableName
				}
				If tFirstName'=entry.TableName {
					Set tSC = $$$ERROR($$$EnsErrGeneral,"Cannot import entries from more than one table from a single studio document - found entries for tables '"_tFirstName_"' and '"_entry.TableName_"'")
					Quit
				}
				Set entry.TableName=pForceTableName
				Set ^||enslutKeep(entry.KeyName)=""
			}
			#; Optimisation to avoid update if not changed
			If (('$Data(^Ens.LookupTable(entry.TableName, entry.KeyName), tGLVNValue)) || (tGLVNValue '= entry.DataValue)) {
				Set tSC = ..%UpdateValue(entry.TableName,entry.KeyName,entry.DataValue,1)
				Quit:$$$ISERR(tSC)
				Do $Increment(pCount("Updated"))
			}
			Do $Increment(pCount)
		}

		#; Prune table of items not in import file
		If $$$ISOK(tSC) && (""'=pForceTableName) {
			Set tKeyName = ""
			For  {
				Set tKeyName = $Order(^Ens.LookupTable(pForceTableName,tKeyName))
				Quit:(tKeyName="")
				If '$Data(^||enslutKeep(tKeyName)) {
					Set tSC = ##class(Ens.Util.LookupTable).%RemoveValue(pForceTableName, tKeyName)
					Quit:$$$ISERR(tSC)
					Do $Increment(pCount("Deleted"))
				}
			}
		}

		#; Will Trigger Rollback
		Quit:$$$ISERR(tSC)

		TCOMMIT
		Set tInTransaction = 0
	}
	Catch {
		Set tSC = $$$SystemError
	}
	#; If still in transaction then the delock will be put in pending until TROLLBACK finishes
	If tForceTableLocked Lock -^Ens.LookupTable(pForceTableName)
	If tInTransaction {
		Try { TROLLBACK } Catch { Set tSC = $$$ADDSC(tSC,$$$SystemError) }
	}
	Kill ^||enslutKeep
	Quit tSC
}

/// Export lookup table data to file <var>pFileName</var>.
/// If <var>pTableName</var> is provided, then only export that table. <br>
/// Note that the resulting XML file is in legacy format, which is not compatible with Studio.
ClassMethod %Export(pFileName As %String = "", pTableName As %String = "") As %Status
{
	Set tSC = $$$OK
	If $IsObject(pFileName) {
		Set tStream=pFileName
	} ElseIf (pFileName '= "") {
		Set tStream=##class(%IO.FileStream).%New()
		Do tStream.Open(pFileName,"NEW",,"UTF-8",.tSC)
	} Else {
		Set tStream=##class(%IO.DeviceStream).AttachNew(,.tSC)
	}
	Quit:$$$ISERR(tSC) tSC
	Do tStream.WriteLine("<?xml version=""1.0""?>")
	Do tStream.WriteLine("<lookupTable>")

	If (pTableName = "") {
		Set tTableName = $O(^Ens.LookupTable(""))
	} Else {
		Set tTableName = pTableName
	}
	While (tTableName '= "") {
		Set tLocked = 0
		Try {
			Lock +^Ens.LookupTable(tTableName)#"S":2
			If '$Test {
				Set tSC = $$$ERROR($$$LockFailedToAcquireRead,$name(^Ens.LookupTable(tTableName)))
				Quit
			}
			Set tLocked = 1
			Set tKey="" For { Set tKey=$O(^Ens.LookupTable(tTableName,tKey))  Quit:""=tKey
				Set tRecord = ..IDKEYOpen(tTableName,tKey,,.tSC)
				If $$$ISERR(tSC) Quit
				If $IsObject(tRecord) {
					Do tRecord.XMLExportToStream(tStream)
					Do tStream.WriteLine("")
				}
			}
			If $$$ISERR(tSC) Quit
		}
		Catch {
			Set tSC = $$$SystemError
		}
		If tLocked Lock -^Ens.LookupTable(tTableName)#"S"
		If $$$ISERR(tSC) Quit
		Quit:""'=pTableName
		Set tTableName = $O(^Ens.LookupTable(tTableName))
	}
	Do tStream.WriteLine("</lookupTable>")
 	Quit tSC
}

/// Update the value of an existing entry with the supplied TableName and KeyName.
/// If <var>pCreate</var> is true, then the entry will be created if it doesn't already exist.
ClassMethod %UpdateValue(pTableName As %String = "", pKeyName As %String = "", pNewValue As %String = "", pCreate As %Boolean = 1) As %Status
{
	If (pTableName = "") Quit $$$ERROR($$$PropertyRequired,"TableName")
	If (pKeyName = "") Quit $$$ERROR($$$PropertyRequired,"KeyName")

	Set tStatus = $$$OK
	Set tEntry = ..IDKEYOpen(pTableName,pKeyName,,.tStatus)
	If '$IsObject(tEntry) {
		If 'pCreate {
			If '$system.Status.Equals(tStatus,$$$LoadObjectNotFound) {
				Set tStatus1 = $$$ERROR($$$LoadObjectNotFound,$classname(),pTableName_"||"_pKeyName)
				Set tStatus = $$$ADDSC(tStatus,tStatus1)
			}
			Quit tStatus
		}
		Set tEntry = ..%New()
		Set tEntry.TableName = pTableName
		Set tEntry.KeyName = pKeyName
	}
	Set tEntry.DataValue = pNewValue
	Quit tEntry.%Save()
}

/// Remove the lookup value for the supplied TableName and KeyName.
ClassMethod %RemoveValue(pTableName As %String = "", pKeyName As %String = "") As %Status
{
	If (pTableName = "") Quit $$$ERROR($$$PropertyRequired,"TableName")
	If (pKeyName = "") Quit $$$ERROR($$$PropertyRequired,"KeyName")
	Quit ..IDKEYDelete(pTableName,pKeyName)
}

/// Update the timestamp for the table whenever an entry is added or updated.
Trigger OnModify [ Event = INSERT/UPDATE, Time = AFTER ]
{
	Do ..updateTimestamp({TableName})
}

/// Update the timestamp whenever a row is removed from a table. If there
/// are no entries, then remove the timestamp node.
Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	New tData
	Set tData = $data(^Ens.LookupTable({TableName}))
	If tData >= 10 {
		Do ..updateTimestamp({TableName})
	}
	ElseIf tData {
		Kill ^Ens.LookupTable({TableName})
	}
}

/// Helper method for updating the timestamp of a lookup table.
ClassMethod updateTimestamp(pTableName As %String) [ Internal ]
{
	If $G(pTableName) '= "" Set $LI(^Ens.LookupTable(pTableName),1) = $H
}

/// Helper method for getting the timestamp of a lookup table.
ClassMethod getTimestamp(pTableName As %String) As %TimeStamp [ Internal ]
{
	If ($G(pTableName) = "") Quit ""
	Quit $LG($G(^Ens.LookupTable(pTableName)),1)
}

/// List the existing Lookup tables
Query Enumerate() As %Query(ROWSPEC = "Name:%String")
{
}

ClassMethod EnumerateExecute(ByRef qHandle As %Binary) As %Status
{
 	Kill qHandle  Set qHandle=""
 	Quit $$$OK
}

ClassMethod EnumerateClose(ByRef qHandle As %Binary) As %Status
{
	Kill qHandle
 	Quit $$$OK
}

ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 Set $ZT="Trap",tSC=$$$OK
 Do {
	Set Row="", AtEnd=0, qHandle=$O(^Ens.LookupTable(qHandle))
	If qHandle="" Set AtEnd=1 Quit
 	Set Row=$LB(qHandle)
 } While 0
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

Storage SQLStorage
{
<ExtentSize>5000</ExtentSize>
<SQLMap name="Map1">
<Data name="DataValue"/>
<Global>^Ens.LookupTable</Global>
<Subscript name="1">
<Expression>{TableName}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{KeyName}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^Ens.Util.LookupTableS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
