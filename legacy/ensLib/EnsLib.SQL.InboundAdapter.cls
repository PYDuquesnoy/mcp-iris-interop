/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SQL database polling client adapter. Repeatedly executes a query against a remote database via an ODBC- or JDBC- defined DSN (Data Source Name) and processes each resulting row.
Class EnsLib.SQL.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.SQL.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "ENSEMBLE";

Parameter SERVICEINPUTCLASS = "EnsLib.SQL.Snapshot";

/// The Base query string that will be repeatedly executed to look for new rows
Property Query As %String(MAXLEN = "") [ Required ];

/// A comma-separated list of parameter value specifiers, if any. These correspond to any replaceable ? parameters in the query string.
/// %<varname> refers to Adapter properties such as %LastKey;
/// $<varname> refers to Service class properties;
/// &<varname> refers to persistent values saved between invocations.
Property Parameters As %String(MAXLEN = 1000);

/// A comma-separated list of the SQL data types of each parameter used in the query (eg. SQL_CHAR,SQL_INTEGER).
/// This may be required for the query to execute successfully if the datatypes are not SQL_VARCHAR (the default used when unspecified)
Property ParamSQLTypes As %String(MAXLEN = "");

/// If specified, used to delete rows after processing. Must have exactly one parameter for IDKey value
Property DeleteQuery As %String(MAXLEN = "");

/// The name of the IDKey field in the query's resultset. Must be unique (non-reused) over time if DeleteQuery is empty.
Property KeyFieldName As %String [ InitialExpression = "ID" ];

/// These are the production settings for this object
Parameter SETTINGS = "Query:Data,Parameters:Data,ParamSQLTypes:Data,DeleteQuery:Data,KeyFieldName:Data,MaxVarCharLengthAsString:Data,DoNotInterruptResultSet:Data";

/// If DeleteQuery is empty or fails, the IDKey value of the last retrieved row is recorded here.
/// If you want to use a Query that will return only new ID values and not use a DeleteQuery, use
///  a Parameters specifier that includes "%LastKey" to access this transient value or "&%LastKey" to
///  access a persistent copy of this value.
Property %LastKey As %Numeric [ InitialExpression = 0, Private ];

/// ResultSet carried over to multiple OnTask() calls if multiple rows found
Property %CurrResultSet As EnsLib.SQL.GatewayResultSet [ Private ];

/// Key index for one Adapter instance to Array of RowIDs of rows found in the current execution of its query.
Property %InstKey As %Integer [ Private ];

/// A shell to hold the current row to pass to ProcessInput()
Property %Row As EnsLib.SQL.Snapshot [ Private ];

/// When a ResultSet is being processed the framework checks if the service ought to stop
/// after each Row is processed. <br>
/// Enabling this setting will mean that all Rows in a ResultSet will be processed
/// by the service before checking if it ought to stop. <br>
/// This should only be enabled if each row is processed without synchronous dependence
/// on another business host. <br>
/// It is intended to help where the SQL call that generated the ResultSet is such that
/// all rows returned in the ResultSet are considered immediately processed without a
/// separate SQL update/delete call and hence none of the rows in the ResultSet will
/// be returned by a repeat invocation. <br>
Property DoNotInterruptResultSet As %Boolean [ InitialExpression = 0 ];

Method OnInit() As %Status
{
	Set ..%CurrResultSet=$$$NULLOREF
	
	#; Create an instance of the one-Row snapshot object
	Do ..%RowNewObject()  $$$ASSERT($IsObject(..%Row))
	Set ..%Row.MaxRowsToGet=1

	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set tSC=..init()  Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0&&(..StayConnected<..CallInterval) ..KeepaliveInterval=..StayConnected
	Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.sqlrow") ; clean up on restart
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout,1)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	Set ..%InstKey=$I(^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName))
	Do ..deleteRuntimeAppData()
	Quit $$$OK
}

Method OnTearDown() As %Status
{
	Kill ^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey)
	Quit ##Class(EnsLib.SQL.Common)$this.OnTearDown()
}

/// Parse out parameters by comma-separators, honoring single and double quotes, escaped by doubling
Method getParms(Output pArray, pIO As %String = "", pSQLType As %String = "") As %Status [ Private ]
{
	Kill pArray  Set pArray=0, tParm="", tParms=..Parameters_",", tLen=$L(tParms), qq1=0, qq2=0, lq=0, inq(lq)=0, pIO = $zcvt(pIO,"l")
	For i=1:1:tLen { Set c=$E(tParms,i)
		If ","=c&&('lq||(lq=1&&$Case(inq(1),1:qq1,2:qq2,:0))) {
			Quit:i=tLen&&(""=tParm) ; skip the trailing parm if blank
			Set tParm=$ZStrip(tParm,"<>W"), c1=$E(tParm), tParm=$E(tParm,2,*)
			Set tParm=$Case(c1, "%":$Property($this,"%"_tParm), "$":$Property(..BusinessHost,tParm), "&":$G($$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlparam",tParm)), :c1_tParm)
			Set tIOChar = "", tSQLType = ""
			If ""'=$E(pIO,pArray+1) {
				For {
					Set tIOChar = $E(pIO,pArray+1)
					Quit:""=tIOChar
					Set pArray(pArray+1,"IOType") = $Case(tIOChar,"i":1,"o":4,"b":2,:"")
					Set tSQLType = $P(pSQLType,",",pArray+1)
					If (""'=tSQLType) {
						Set tSQLType = ..ConvertSQLTypeToInt(tSQLType)
						Set pArray(pArray+1,"SqlType") = tSQLType
					}
					If $Case(tIOChar,"i":1,"b":1,:0) {
						Quit
					} Else {
						Set pArray = pArray+1
					}
				}
			}
			If (""=tIOChar)&&(""'=$P(pSQLType,",",pArray+1)) {
				Set tSQLType = ..ConvertSQLTypeToInt($P(pSQLType,",",pArray+1))
				Set pArray(pArray+1,"SqlType") = tSQLType
			}
			Set pArray=pArray+1, pArray(pArray)=tParm, tParm="", lq=0, qq1=0, qq2=0
		} Else {
			If "'"=c { Set:inq(lq)=2&&qq2 lq=lq-1  Set qq2=0
				If inq(lq)=1 { If qq1 { Set qq1=0 } Else { Set qq1=1 } }
				Else { Set lq=lq+1, inq(lq)=1 }
			}
			ElseIf """"=c { Set:inq(lq)=1&&qq1 lq=lq-1  Set qq1=0
				If inq(lq)=2 { If qq2 { Set qq2=0 } Else { Set qq2=1 } }
				Else { Set lq=lq+1, inq(lq)=2 }
			} Else {
				Set:qq1||qq2 lq=lq-1, qq1=0, qq2=0
			}
			Set tParm=tParm_c
		}
	}
	If ""'=tParm {
		#; remove artificial comma, match unbalanced quotes
		Set tParm=$E(tParm,1,*-1)
		For lq=lq:-1:1 Set tParm=tParm_$Case(inq(lq),1:"'",2:"""",:"")
		Set pArray=pArray+1, pArray(pArray)=tParm
	}
	Quit $$$OK
}

Method OnTask() As %Status
{
#define ErrorRowTable(%key) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)
#define DoneRowTable(%key) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)

	Set $ZT="Trap", tSC=$$$OK, tOneRow="" 
	Do {
		If '..Connected||'$IsObject(..%CurrResultSet) {
			Set tSC=..Connect(..ConnectTimeout)
			Quit:""=..Query||'..Connected
			#; Query the database
			#; construct parms array
			Set tSC=..getParms(.tParms,,..ParamSQLTypes) Quit:$$$ISERR(tSC)
			Set ..%CurrResultSet=$$$NULLOREF
			Set tSC=..ExecuteQueryParmArray(.tRS,..Query,.tParms)  Quit:$$$ISERR(tSC)  $$$ASSERT($IsObject(tRS))
			Set ..%CurrResultSet=tRS
			Kill ^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey)
		}
		Set tRowID="",tCount=0  While $IsObject(..%CurrResultSet) {
			Set tSC=..%CurrResultSet.GetSnapshot(..%Row)  Quit:$$$ISERR(tSC)
			Set tCount=..%Row.RowCount
			If 'tCount {
				/* Done with this ResultSet now
					%OnClose() of the result set will call the adapter Disconnect() method
					if '..StayConnected and RS is %Final which is how we initialized it.
				*/
				Set ..%CurrResultSet=$$$NULLOREF

				#; Remove errored and/or processed rows from the globals if they no longer exist
				Set f="" For  Set f=$Order($$$ErrorRowTable(f)) Quit:f=""  if '$G(^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey,f)) If ""'=$G($$$ErrorRowTable(f)) { $$$sysTRACE($$$FormatText($$$Text("Removed absent row '%1' from errored list"),f)) } Kill $$$ErrorRowTable(f)
				Set f="" For  Set f=$Order($$$DoneRowTable(f)) Quit:f=""   if '$G(^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey,f)) $$$sysTRACE($$$FormatText($$$Text("Removed absent row '%1' from processed list"),f))  Kill $$$DoneRowTable(f)
				Quit
			}
			Do ..%Row.Next()
			If ""=..KeyFieldName { Set tRowID="" }
			Else {
				Set tOneRow = ..%Row.Get(..KeyFieldName)
				If (""=tOneRow||($C(0)=tOneRow)) {
					$$$LOGERROR($$$FormatText($$$Text("Key value not found in field '%1'"),..KeyFieldName))
					#; Done with this ResultSet now. See above for comment on Disconnect() if StayConnected is 0
					Set ..%CurrResultSet=$$$NULLOREF
					Quit
				}
				#; If we have seen this row before, continue to the next one
				Continue:..CheckAgainstDone(tOneRow)

				Set tRowID=tOneRow, tOneRow=""
			}
			$$$sysTRACE($$$FormatText($$$Text("About to process row '%1'"),tRowID))
			Quit ; found a good one
		}
		Quit:$$$ISERR(tSC)||$S(""=..KeyFieldName:'tCount, 1:""=tRowID)
 		$$$catTRACE("sql",$$$FormatText($$$Text("Processing row %1 '%2'"),..KeyFieldName,tRowID))

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
	} While (..DoNotInterruptResultSet && $$$ISOK(tSC) && (..%CurrResultSet'=$$$NULLOREF))
Exit
	/*
		Ens.BusinessService::ProcessInput sets ..%WaitForNextCallInterval=0 which
		allows the framework to immediately return to look for next row since there was
		some data.
		Ens.BusinessService::OnTask sets ..%WaitForNextCallInterval=1 at the start of each loop
		Since with DoNotInterruptResultSet we are by passing the resetting in Ens.BusinessService::OnTask 
		we need to set it to 1 here (it may still be 1 if no data found.
	*/
	If ..DoNotInterruptResultSet Set ..BusinessHost.%WaitForNextCallInterval=1
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Lock:""'=tOneRow -$$$ErrorRowTable(tOneRow)
	Goto Exit
}

/// Check the current RowID against the ErrorRowTable and the DoneRowTable to see if this is a new result
/// Return 1 of we should either quit or continue on to the next row.  Return 0 if this RowID is unique.
/// <param>pRowOrResult</param> is used to make sure trace results match for whether this is a parameter result or a query row
Method CheckAgainstDone(pRowID As %String, pRowOrResult As %String = "row") As %Boolean [ Internal ]
{
	#define ErrorRowTable(%key) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)
	#define DoneRowTable(%key) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.sqlrow",%key)
	
	#dim tContinue As %Boolean = 1
	
	Do {
		Set ^IRIS.Temp.Adapter.sqlrow(..BusinessHost.%ConfigName,..%InstKey,pRowID)=1

		Lock +$$$ErrorRowTable(pRowID):0 Else  $$$LOGINFO($$$FormatText($$$Text("Skipping locked %1 '%2'"),pRowOrResult,pRowID)) Quit
		#; Skip the query results we have already processed or that errored; only warn once
		If $G($$$DoneRowTable(pRowID)) If $G(^(pRowID,"done"_$E($G($$$ErrorRowTable(pRowID)),-1))) { Kill ^("done") $$$sysTRACE($$$FormatText($$$Text("Skipping previously processed %1 '%2'"),pRowOrResult,pRowID)) } Lock -$$$ErrorRowTable(pRowID) Quit
		If $G($$$ErrorRowTable(pRowID)) If $G(^(pRowID,"wrn")) { Kill ^("wrn") $$$LOGWARNING($$$FormatText($$$Text("Skipping previously errored %1 '%2'"),pRowOrResult,pRowID)) } Lock -$$$ErrorRowTable(pRowID) Quit
		Set $$$ErrorRowTable(pRowID)=1, ^(pRowID,"wrn") = 1
		Set:""=..DeleteQuery ^("done")=1
		Lock -$$$ErrorRowTable(pRowID)
		
		#; If we didn't quit out by now, then don't need to skip to next RowID
		Set tContinue = 0
		
	} While 0
	
	Quit tContinue
}

ClassMethod GetPersistentValue(pConfigName As %String, pParamName As %String) As %String [ CodeMode = expression ]
{
$G($$$EnsStaticAppData(pConfigName,"adapter.sqlparam",pParamName))
}

ClassMethod SetPersistentValue(pConfigName As %String, pParamName As %String, pValue As %String) As %String
{
	Set tOld=$G($$$EnsStaticAppData(pConfigName,"adapter.sqlparam",pParamName))
	Set ^(pParamName) = pValue
	Quit tOld
}

/// Set persistent value (default name=%LastKey) to new value only if it is currently undefined. Return old value if any.
ClassMethod InitializePersistentValue(pConfigName As %String, pParamName As %String = "%LastKey", pNewValue As %String) As %String
{
	Set tDefined=$D($$$EnsStaticAppData(pConfigName,"adapter.sqlparam",pParamName),tOldVal)
	Quit:tDefined#2 tOldVal
	Set ^(pParamName) = pNewValue
	Quit ""
}

ClassMethod InitializeLastKeyValue(pConfigName As %String, pNewLastKey As %String = 0) As %String [ CodeMode = expression ]
{
..InitializePersistentValue(pConfigName,,pNewLastKey)
}

}
