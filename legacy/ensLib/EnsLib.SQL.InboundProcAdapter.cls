/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL database-polling client adapter. Repeatedly executes a sql procedure against a remote database via an ODBC- or JDBC- defined DSN (Data Source Name) and processes each resulting row.
Class EnsLib.SQL.InboundProcAdapter Extends EnsLib.SQL.InboundAdapter [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// A text string in which each character corresponds to one of the query parameters. The character 'i' means the
/// corresponding parameter is an Input parameter. The character 'o' means it is an Output parameter, and 'b' means it is Both an Input
/// and an Output parameter. If the procedure is a function which has a return value, an 'o' should be added in front to account for the return value.
Property IO As %String;

/// The name of the procedure to be called by this Service.  This should include any ? characters used to indicate parameters of the procedure, but
/// should not include any SQL commands (eg. Select) with the exception that the CALL command must be included if ?= is used.<br>
/// Specifying  preceding ?=CALL is optional if the procedure provides a RETURN (Note the Input/Output Setting must include the leading o for the return.)<br>
///  For example the following are valid:<br><br>
///  schema.proc(?,?) with Input/Output of oii - this will result in ? = CALL schema.proc(?,?) <br>
///  schema.proc(?,?) with Input/Output of ii - this will result in CALL schema.proc(?,?) <br>
///  ? = CALL schema.proc(?,?) with Input/Output of oii - this will result in ? = CALL schema.proc(?,?)<br>
///  CALL schema.proc(?,?) with Input/Output of ii - this will result in CALL schema.proc(?,?) <br>
Property Procedure As %String(MAXLEN = 1000);

/// A comma-separated list of property names corresponding to any output parameters of the procedure.
/// If the procedure is a function, each parameter with an IO type of either 'o' or 'b' should have a name specified.
Property OutputParamNames As %String(MAXLEN = "");

/// JDBC escape call syntax requires the statement to be wrapped in {}
Property EscapedCallRequiresBracing As %Boolean [ InitialExpression = 1 ];

Property %KeyValueInParams As %Boolean [ InitialExpression = 0, Private ];

Property %KeyValueInRS As %Boolean [ InitialExpression = 0, Private ];

Property %CurrSnapshots As list Of EnsLib.SQL.Snapshot [ Private ];

Property %CurrSnapshotCount As %Integer [ InitialExpression = 0, Private ];

Property %CurrParams As %ListOfDataTypes [ Internal ];

Parameter DOMAIN = "ENSEMBLE";

Parameter SETTINGS = "-Query,Procedure:Data,IO:Data,OutputParamNames:Data,-DoNotInterruptResultSet,EscapedCallRequiresBracing:Data";

Method OnInit() As %Status
{
	#dim tSC as %Status = $$$OK
	
	Set ..%CurrSnapshots = $$$NULLOREF
	Set ..%CurrParams = $$$NULLOREF
		
	If ""=..Procedure {
		Quit $$$ERROR($$$EnsErrGeneral,"No procedure specified")
	} Else {
		#; Construct query call
		Set ..IO = $zcvt(..IO,"l")

		/* Prepend appropriate CALL if needed */
		#dim tProcedureUpperNoWS = $zcvt($zstrip(..Procedure,"*W"),"U")
		If ($extract(tProcedureUpperNoWS,1,6)'="?=CALL")&&($extract(tProcedureUpperNoWS,1,4)'="CALL") {
			If ("o"=$E(..IO)) && ($L(..IO)>=($L(..Procedure,"?"))) {
				Set ..Query = "? = CALL "_..Procedure
			} Else {
				Set ..Query = "CALL "_..Procedure
			}
		} Else {
			Set ..Query = ..Procedure
		}
		#; Wrap the query in {} if requested
		If ..EscapedCallRequiresBracing && ($extract(tProcedureUpperNoWS)'="{") {
			Set ..Query = "{" _ ..Query _ "}"
		}

		If ($L(..IO)<($L(..Procedure,"?")-1)) {
			$$$LOGWARNING($$$Text("Must specify whether each parameter is input or output in the Input/Output setting"))
		} ElseIf $Translate($zcvt(..IO,"l"),"iob*#","")'="" {
			$$$LOGWARNING($$$Text("Input/Output setting should be a string consisting only of the characters 'i', 'o' and 'b'"))
		}
		
		If ..Query'["?" {
			$$$LOGINFO($$$Text("This procedure does not return output parameters"))
		} ElseIf (","_..OutputParamNames_",")[..KeyFieldName {
			Set ..%KeyValueInParams = 1
		} Else {
			$$$LOGWARNING($$$Text("Key value not found in list of output parameter names"))
		}

	}
	
	Quit ##super()
}

///  Copied from EnsLib.SQL.InboundAdapter, except adjusted to use ExecuteProcedureParmArray and make use of IO and returned parameters
Method OnTask() As %Status
{
	#define ErrorRowTable(%key) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)
	#define DoneRowTable(%key) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)

	#dim tSC As %Status = $$$OK
	#dim tRowID As %String = ""
	#dim i,tOK As %Integer
	#dim tOutputParameters As %ListOfDataTypes = $$$NULLOREF
	#dim ex As %Exception.AbstractException

	Try {
	
		If '..Connected||'$IsObject(..%CurrSnapshots)||(..%CurrSnapshots.Count()=0) {
			Set tSC=..Connect(..ConnectTimeout)
			Quit:""=..Query||'..Connected
			
			#; ExecuteProcedureParmArray does not work if the procedure has neither input nor output parameters
			If ..Query'["?" {
				Set tSC=..ExecuteUpdate(,..Query)	Quit:$$$ISERR(tSC)
				Quit
			}
			
			#; Construct parms array
			Set tSC=..getParms(.tParms,..IO,..ParamSQLTypes) Quit:$$$ISERR(tSC)
			#; Query the database
			Set ..%CurrSnapshots=$$$NULLOREF
			Set tSC=..ExecuteProcedureParmArray(.tResultSnapshots,.tOutputParameters,..Query,..IO,.tParms)  Quit:$$$ISERR(tSC)
			Set ..%CurrSnapshots=tResultSnapshots
			Set ..%CurrParams=tOutputParameters
			Kill ^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey)
		}
		
		#; Start by finding the next snapshot row if there is one
		If ..%CurrSnapshots.Size {
			Do ..GetNextRow()
		}
		
		If ""=..KeyFieldName {
			Set tRowID=""
		} ElseIf (..%KeyValueInParams && ..%CurrParams.Size) {
			For i=1:1:$L(..OutputParamNames,",") {
				If $P(..OutputParamNames,",",i)=..KeyFieldName {
					Set tRowID = ..%CurrParams.GetAt(i)
					#; Don't regard null as a valid value
					If (""=$zstrip(tRowID,"*C")) {
						Set tRowID=""
						#; Maybe the keyfield is present in the result snapshots, otherwise error
						If '..%KeyValueInRS {
							If '..%Row.RowCount || '..%Row.GetColumnID(..KeyFieldName) {
								$$$LOGERROR($$$FormatText($$$Text("Key value not found in parameter '%1'"),..KeyFieldName))
							} Else {
								#; Remember for future that we did find the keyfield in the result snapshots, so we don't error just because we're at the end of the result set
								Set ..%KeyValueInRS = 1
								$$$LOGWARNING($$$FormatText($$$Text("Key value not found in parameter '%1'. Using query results instead."),..KeyFieldName))
							}
						}
					}
					Quit
				}
			}
			If ""'=tRowID {
				#; If we have seen this result before, then don't send it again
				Quit:..CheckAgainstDone(tRowID,"result")

				$$$catTRACE("sql",$$$FormatText($$$Text("Processing output parameters for %1 '%2'"),..KeyFieldName,tRowID))

			}
		}
		#; If KeyField not found in parameter results, check in snapshot rows
		If (""'=..KeyFieldName) && (""=tRowID) {
			#dim tFirstRow As %Boolean = 1
			While ..%CurrSnapshots.Size {
				If 'tFirstRow {
					Do ..GetNextRow()
				}
				Quit:..%Row.AtEnd
				Set tFirstRow = 0
				Set tOneRow = ..%Row.Get(..KeyFieldName)
				If (""=tOneRow||($C(0)=tOneRow)) $$$LOGERROR($$$FormatText($$$Text("Key value not found in field '%1'"),..KeyFieldName)) Quit
				#; If we have seen this row before, continue to the next one
				Continue:..CheckAgainstDone(tOneRow,"row")

				Set tRowID=tOneRow, tOneRow=""
				$$$sysTRACE($$$FormatText($$$Text("About to process row '%1'"),tRowID))
				Quit ; found a good one
			}
			Quit:$$$ISERR(tSC)||(""=tRowID)
			$$$catTRACE("sql",$$$FormatText($$$Text("Processing row %1 '%2'"),..KeyFieldName,tRowID))
		}
		If ('..%CurrParams.Size && '..%Row.RowCount) {
			If (..Query["?") {
				#; Should have returned something
				$$$LOGERROR($$$Text("No output parameters from procedure call"))
			}
			Quit
		}

		Set tSC=..BusinessHost.ProcessInput(..%Row.%ConstructClone())  Quit:$$$ISERR(tSC)
 		
		If ""'=..DeleteQuery {
			#; delete the row, and remove the row from do-not-process list if it is deleted
			Set tSC=$S(""=..KeyFieldName:..ExecuteUpdate(.tOK,..DeleteQuery),1:..ExecuteUpdate(.tOK,..DeleteQuery,tRowID))  Set:$$$ISERR(tSC) tOK=0
			If tOK { Kill:""'=tRowID $$$ErrorRowTable(tRowID) }
			Else { $$$LOGWARNING($$$FormatText($$$Text("Failed to delete row '%1'"),tRowID)) }
		} ElseIf ""'=tRowID {
			Set $$$ErrorRowTable(tRowID)="", ^(tRowID,"done")=1
			Set $$$DoneRowTable(tRowID)=1
		}
		Set:""'=tRowID (..%LastKey, $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlparam","%LastKey"))=tRowID
		Do:('..StayConnected) ..Disconnect()
		
	} Catch ex {
		Set tSC = ex.AsStatus()
		Lock:""'=tRowID -$$$ErrorRowTable(tRowID)
	}
	
	Quit tSC
}

/// Get the next Row from the snapshot results.  This could either be just from calling Next() in the ..%Row object or it could be in the next snapshot from the ..%CurrSnapshots list.
/// If there are no more rows, then clear ..%Row and ..%CurrSnapshots so that we'll try executing the SQL procedure next time OnTask is called
Method GetNextRow() [ Internal ]
{
	#define ErrorRowTable(%key) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)
	#define DoneRowTable(%key) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)

	If '..%Row.Next() {
		If ..%CurrSnapshotCount < ..%CurrSnapshots.Size {
			Set ..%Row = ..%CurrSnapshots.GetAt(..%CurrSnapshotCount+1)
			Set ..%CurrSnapshotCount = ..%CurrSnapshotCount + 1
		} Else {
			Do ..%Row.Clean()
		}
		If '$IsObject(..%Row) {
			#; Create an instance of the one-Row snapshot object so we have something to pass to Service
			Do ..%RowNewObject()  $$$ASSERT($IsObject(..%Row))
		}
		If '..%Row.RowCount {
			#; Done with these Snapshots now
			Do ..%CurrSnapshots.Clear()
			Set ..%CurrSnapshotCount = 0
			Do:'..StayConnected ..Disconnect()

			#; Remove errored and/or processed rows from the globals if they no longer exist
			Set f="" For  Set f=$Order($$$ErrorRowTable(f)) Quit:f=""  if '$G(^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey,f)) If ""'=$G($$$ErrorRowTable(f)) { $$$sysTRACE($$$FormatText($$$Text("Removed absent row '%1' from errored list"),f)) } Kill $$$ErrorRowTable(f)
			Set f="" For  Set f=$Order($$$DoneRowTable(f)) Quit:f=""   if '$G(^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey,f)) $$$sysTRACE($$$FormatText($$$Text("Removed absent row '%1' from processed list"),f))  Kill $$$DoneRowTable(f)
		}
		Do ..%Row.Next()
	}
}

}
