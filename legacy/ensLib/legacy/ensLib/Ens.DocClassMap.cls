/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to implement an efficient listing of SearchTables which have stored data for various
/// document types. The primary purpose of this class is to ensure that the removal of documents which
/// may have been indexed can remove all related SearchTable data for the given document.
Class Ens.DocClassMap [ System = 4 ]
{

/// Make a record of the fact that the message class <var>pDocClass</var> has stored data
/// in the extent defined by the class in <var>pSearchTableRoot</var>.
/// <var>pUpdateCache</var> indicates whether the local process cache should be updated.
/// This should generally be performed while within jobs which need to maintain this information
/// for some time. <br>
/// In order to reduce lock waiting time do not treat as fatal if cannot obtain lock immediately.
ClassMethod AddSearchTable(pDocClass As %String, pSearchTableRoot As %String, pUpdateCache As %Boolean = {$data($$$EnsJobLocal)}) As %Status
{
	If ($get(pDocClass) = "") || ($get(pSearchTableRoot) = "") Quit $$$OK
	If $data($$$EnsJobLocal("EnsDocClassMap",pDocClass,"st",pSearchTableRoot)) Quit $$$OK
	Set tSC = $$$OK
	Set tLocked = 0
	Try {
		#; try to see if can get the lock but do not treat as fatal if cannot
		Lock +^Ens.DocClassMap(pDocClass):0
		Set:$Test tLocked = 1
		If tLocked&&'$data(^Ens.DocClassMap(pDocClass,"st",pSearchTableRoot)) {
			Set ^Ens.DocClassMap(pDocClass,"st",pSearchTableRoot) = ""
			Set ^Ens.DocClassMap(pDocClass,"ts") = $zdatetime($ztimestamp,3,,3)
		}
		#; If failed to acquire lock then ..UpdateCache will try again
		If pUpdateCache {
			If $data($$$EnsJobLocal("EnsDocClassMap",pDocClass,"all")) {
				Set tSC = ..UpdateCache(pDocClass)
			}
			Else {
				#; only set local cache if we locked or we know there to be data in DocClassMap
				If tLocked||$data(^Ens.DocClassMap(pDocClass,"st",pSearchTableRoot)) {
					Set $$$EnsJobLocal("EnsDocClassMap",pDocClass,"st",pSearchTableRoot) = ""
					Set $$$EnsJobLocal("EnsDocClassMap",pDocClass,"ts") = $get(^Ens.DocClassMap(pDocClass,"ts"))
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $get(tLocked) Lock -^Ens.DocClassMap(pDocClass)
	Quit tSC
}

/// API to clean up the entries for a given SearchTable extent specified by <var>pSearchTable</var>.
ClassMethod RemoveSearchTable(pSearchTable As %String, pUpdateCache As %Boolean = {$data($$$EnsJobLocal)}) As %Status
{
	Set tIsStream = 0
	Try { Set tIsStream = $classmethod(pSearchTable,"%IsA","%Stream.Object") }
	Catch { Set tIsStream = 0 }
	Set tSearchTableRoot = $select(tIsStream: "%Stream.Object", 1: ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(pSearchTable))
	If tSearchTableRoot '= "" {
		Set tSC = $$$OK
		TSTART
		Try {
			Set tClass = ""
			For {
				Set tClass = $order(^Ens.DocClassMap(tClass))
				Quit:(tClass = "")
				If $data(^Ens.DocClassMap(tClass,"st",tSearchTableRoot)) {
					Set tLocked = 0
					Try {
						Lock +^Ens.DocClassMap(tClass):1
						If '$Test { Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to lock ^Ens.DocClassMap("""_tClass_""")") Quit }
						Set tLocked = 1
						Kill ^Ens.DocClassMap(tClass,"st",tSearchTableRoot)
						Set ^Ens.DocClassMap(tClass,"ts") = $zdatetime($ztimestamp,3,,3)
						If pUpdateCache {
							If $data($$$EnsJobLocal("EnsDocClassMap",tClass,"all")) {
								Set tSC = ..UpdateCache(tClass)
								If $$$ISERR(tSC) Quit
							}
							Else {
								Kill $$$EnsJobLocal("EnsDocClassMap",tClass,"st",pSearchTableRoot)
								Set $$$EnsJobLocal("EnsDocClassMap",tClass,"ts") = $get(^Ens.DocClassMap(tClass,"ts"))
							}
						}
					}
					Catch ex {
						Set tSC = ex.AsStatus()
					}
					If $get(tLocked) Lock -^Ens.DocClassMap(tClass)
					If $$$ISERR(tSC) Quit
				}
			}
		}
		Catch ex {
			Set tSC = ex.AsStatus()
		}
		If $$$ISOK(tSC) {
			TCOMMIT
		}
		Else {
			TROLLBACK
		}
		Quit tSC
	}
	Quit $$$OK
}

/// Returns a flag to indicate whether the cached values for a given document class are currently valid.
ClassMethod IsCacheCurrent(pDocClass As %String) As %Boolean [ CodeMode = expression ]
{
$get(^Ens.DocClassMap(pDocClass,"ts")) = $get($$$EnsJobLocal("EnsDocClassMap",pDocClass,"ts"))
}

/// Update the local in-process cache to ensure that it is valid.
ClassMethod UpdateCache(pDocClass As %String) As %Status
{
	Kill $$$EnsJobLocal("EnsDocClassMap",pDocClass)
	Set tSC = $$$OK
	Set tLocked = 0
	Try {
		Lock +^Ens.DocClassMap(pDocClass)#"S":1
		If '$Test { Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to lock ^Ens.DocClassMap("""_pDocClass_""")") Quit }
		Set tLocked = 1
		Merge $$$EnsJobLocal("EnsDocClassMap",pDocClass,"st") = ^Ens.DocClassMap(pDocClass,"st")
		Set $$$EnsJobLocal("EnsDocClassMap",pDocClass,"all") = 1
		Set $$$EnsJobLocal("EnsDocClassMap",pDocClass,"ts") = $get(^Ens.DocClassMap(pDocClass,"ts"))
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $get(tLocked) Lock -^Ens.DocClassMap(pDocClass)#"S"
	Quit tSC
}

/// Should there be a problem whereby the data in ^Ens.DocClassMap is lost,
/// this method can be invoked to rebuild the data in the DocClassMap. <br/>
/// <var>pRemoveFirst</var> controls whether the current contents of the map
/// are removed before determining any new entries to add. <br/>
/// <var>pCheckExtent</var> controls whether code will check whether the 
/// SearchTable extent contains any data. If it doesn't then the SearchTable
/// won't be added to the DocClassMap. <br/>
/// <var>pVerbose</var> controls whether output is logged to the current device.
ClassMethod RebuildMap(pRemoveFirst As %Boolean = 0, pCheckExtent As %Boolean = 1, pVerbose As %Boolean = 0) As %Status
{
	#define WRITE(%x)	Write:pVerbose !,%x
	Set tSC = $$$OK
	Set tLocked = 0
	New $$$EnsJobLocal
	Try {
		TSTART
		Lock +^Ens.DocClassMap:5
		If '$Test { Set tSC = $$$ERROR($$$EnsErrGeneral,"Unable to lock ^Ens.DocClassMap") Quit }
		Set tLocked = 1
		If pRemoveFirst {
			$$$KillRootNode(^Ens.DocClassMap)
		}
		Set tRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("Ens.SearchTableBase")
		If $$$ISERR(tSC) Quit
		While tRS.Next() {
			Set tSearchTable = tRS.Get("Name")
			If $$$comClassKeyGet(tSearchTable,$$$cCLASSnoextent) {
				$$$WRITE("Ignoring SearchTable '"_tSearchTable_"' as it doesn't define an extent")
				Continue
			}
			Set tIsPersistent = 0
			Try {
				Set tIsPersistent = $classmethod(tSearchTable,"%Extends","%Library.Persistent")
			}
			Catch {}
			If 'tIsPersistent {
				$$$WRITE("Ignoring SearchTable '"_tSearchTable_"' as it is not persistent")
				Continue
			}
			Set tSearchTableExtent = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tSearchTable)
			If tSearchTableExtent = "" {
				$$$WRITE("Ignoring SearchTable '"_tSearchTable_"' as its base extent class could not be determined")
				Continue
			}
			Set tDocClass = $$$comMemberKeyGet(tSearchTable,$$$cCLASSparameter,"DOCCLASS",$$$cPARAMdefault)
			If tDocClass = "" {
				$$$WRITE("Ignoring SearchTable '"_tSearchTable_"' as it doesn't define a DOCCLASS")
				Continue
			}
			If '$$$comClassDefined(tDocClass) {
				$$$WRITE("Ignoring SearchTable '"_tSearchTable_"' as DOCCLASS '"_tDocClass_"' doesn't exist")
				Continue
			}
			Set tAddSearchTable = 1
			If pCheckExtent {
				Set tSearchTableSQLTable = $$$ClassSQLTable(tSearchTable)
				If tSearchTableSQLTable '= "" {
					#dim tTableRS As %SQL.StatementResult
					Set tTableRS = ##class(%SQL.Statement).%ExecDirect(,"SELECT TOP 1 %ID FROM "_tSearchTableSQLTable)
					Do tTableRS.%Next()
					If tTableRS.%SQLCODE = 100 {
						$$$WRITE("Not adding SearchTable '"_tSearchTable_"' as no documents have been indexed")
						Set tAddSearchTable = 0
					}
				}
			}
			
			If tAddSearchTable {
				$$$WRITE("Adding SearchTable '"_tSearchTable_"'...")
				Set tSC = ..AddSearchTable(tDocClass,tSearchTableExtent,0)
				If $$$ISERR(tSC) Quit
				Set tDocClassExtent = ##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tDocClass)
				If (tDocClassExtent '= "") && (tDocClassExtent '= tDocClass) {
					Set tSC = ..AddSearchTable(tDocClassExtent,tSearchTableExtent,0)
					If $$$ISERR(tSC) Quit
				}
			}
			
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $get(tLocked) Lock -^Ens.DocClassMap
	If $$$ISOK(tSC) {
		TCOMMIT
	}
	Else {
		TROLLBACK
	}
	Quit tSC
}

}
