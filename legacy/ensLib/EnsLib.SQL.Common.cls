/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSQLTypes)

Class EnsLib.SQL.Common Extends EnsLib.SQL.CommonJ [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Deprecated: use ConnectionAttributes
/// You can set this property in your Operation/Service .OnInit() method to have the options take effect at connect time.
Property ConnectAttrs As %String [ Calculated ];

/// A set of SQL Statement Attribute Options of the form attr:val,attr:val,...
/// Set this property to have the options take effect for every statement subsequently created.
/// Do this in your Business Operation's OnInit() method. For example: Set ..Adapter.StatementAttrs="QueryTimeout:12"
Property StatementAttrs As %String;

Property %ctypeMap As %Integer [ Internal, MultiDimensional ];

Method ConnectAttrsGet() As %String [ CodeMode = expression ]
{
..ConnectionAttributes
}

Method ConnectAttrsSet(val As %String) As %Status
{
 Set ..ConnectionAttributes=val  Quit $$$OK
}

/// True if currently connected to datasource, else False
Property Connected As %Boolean [ InitialExpression = 0 ];

Property IsUnicodeDLL As %Boolean [ InitialExpression = 1 ];

/// Array holding name-to-number mappings for SQL_ATTR_ values
Property attrIDs As %Integer [ MultiDimensional ];

Method DSNSet(dsn As %String) As %Status
{
	Set tConnected = ..Connected
	Do:tConnected ..Disconnect()
	Set i%DSN=dsn
	If tConnected { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGSTATUS(tSC) } ; avoid referencing ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method ConnectedSet(pValue As %Boolean) As %Status
{
	If i%Connected'=pValue {
		Set i%Connected=pValue
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_i%DSN)
	}
	Quit $$$OK
}

/// Connect to the data source
Method Connect(pClientTimeout As %Numeric = 15, pInbound As %Boolean = 0, pJGTimeout As %Numeric = 5) As %Status
{
	Set $ZT="Trap",tSC=$$$OK,tCfg=$this
	Do {
		If ..Connected { Do ..TestConnection() Quit:..Connected }
		If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$ERROR($$$EnsErrNoCredentials,..Credentials) Quit }

		#; find DSN type; get a configuration-settings instance, use it to open a Connection instance
		Set tCfg=..getConfigObj($this,..%CredentialsObj,..%Connection)
		$$$sysTRACE("Connecting to "_..DSN_$S(tCfg.DSN=..DSN:"",1:" ("_tCfg.DSN_")")_" / "_..Credentials_" with timeout="_pClientTimeout)
		Set t0=$ZH
		If tCfg.DSN'[":" {
			#; No Colon; must be ODBC
			Set:'$IsObject(..%Connection)||..%Connection.%Extends("EnsLib.SQL.CommonJ") ..%Connection=##class(%Library.SQLGatewayConnection).%New()
			Set tSC=..%Connection.Connect(tCfg.DSN,..%CredentialsObj.Username,..%CredentialsObj.Password,pClientTimeout)
		} Else {
			#; Has Colon; must be Java
			Set:'$IsObject(..%Connection)||'..%Connection.%Extends("EnsLib.SQL.CommonJ") ..%Connection=tCfg
			Set ..%Connection.%CredentialsObj=..%CredentialsObj
			Set tSC=..%Connection.ConnectJ(pClientTimeout, pInbound, pJGTimeout)
			Set:$$$ISOK(tSC) ..%Connection.%Adapter=$this
		}
		If $$$ISERR(tSC) {
			Set tSC=$S((-1'=pClientTimeout)&&(t0+pClientTimeout'>$zh):
							 $$$ADDSC($$$ERROR($$$EnsErrOutConnectExpired,pClientTimeout,$S(tCfg.DSN'[":":"ODBC",1:"JDBC"),"'"_..DSN_"'"_$S(tCfg.DSN=..DSN:"",1:" ("_tCfg.DSN_")")_" / '"_..Credentials_"'"),tSC)
						, 1: $$$ERROR($$$EnsErrOutConnectFailed,$$$StatusDisplayString(tSC),$S(tCfg.DSN'[":":"ODBC",1:"JDBC"),"'"_..DSN_"'"_$S(tCfg.DSN=..DSN:"",1:" ("_tCfg.DSN_")")_" / '"_..Credentials_"'"))
			Quit
		}
		#; Success
		Set ..Connected=1
		If ..BusinessHost.%LastReportedError [ "ERROR <Ens>ErrOutConnect" {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..%Connection.GetUV(.uv)
			Set ..IsUnicodeDLL = $S($$$ISOK(tSC):uv,1:0)
			#; Set connection options that have been pre-saved
			#; For JDBC the connection attributes are set in EnsLib.SQL.CommonJ::OnConnectProxy()
			If ""'=..ConnectAttrs {
				$$$sysTRACE("Setting Connection Attribute Options "_..ConnectAttrs)
				For i=1:1:$L(..ConnectAttrs,",") { Set tSetting=$P(..ConnectAttrs,",",i), tAttrName=$ZStrip($P(tSetting,":",1),"<>W")  Continue:""=tAttrName
					Set tSC1=..SetConnectAttr(tAttrName, $P(tSetting,":",2))
					If $$$ISERR(tSC1) $$$LOGWARNING("Failed to set connection attribute "_tAttrName_":"_tSetting_"; status = "_$$$StatusDisplayString(tSC1))
				}
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),$S(tCfg.DSN'[":":"ODBC",1:"JDBC"),"'"_..DSN_"'"_$S(tCfg.DSN=..DSN:"",1:" ("_tCfg.DSN_")")_" / '"_..Credentials_"'")
	Goto Exit
}

/// Disconnect from the datasource
Method Disconnect()
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Quit:'..Connected
		$$$sysTRACE("Disconnecting from "_..DSN)
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..%Connection.Disconnect()
			If $$$ISERR(tSC) $$$LOGWARNING("Disconnect() "_$$$StatusDisplayString(tSC))
		} Else { Do ..%Connection.DisconnectJ() }
		Set ..Connected = 0
	} While 0
Exit
	Quit
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method TestConnection(pInbound As %Boolean = 0)
{
	Quit:'..%Connection.%Extends("EnsLib.SQL.CommonJ") ; no meaningful check possible for ODBC
	Do ..TestConnectionJ(pInbound)
}

Method OnTearDown() As %Status
{
	Do ..Disconnect()
	Set:(..%Connection'=$this) ..%Connection=$$$NULLOREF
	Quit $$$OK
}

Method init() As %Status [ Private ]
{
	#; find DSN type; get a configuration-settings instance, use it to check if we are good to go, config-wise
	Set tCfg=..getConfigObj($this,..%CredentialsObj,..%Connection)
	If tCfg.DSN'[":" {
		#; No Colon; must be ODBC
		Set:'$IsObject(..%Connection)||..%Connection.%Extends("EnsLib.SQL.CommonJ") ..%Connection=##class(%Library.SQLGatewayConnection).%New()
	} Else {
		#; Has Colon; must be Java
		Set:'$IsObject(..%Connection)||'..%Connection.%Extends("EnsLib.SQL.CommonJ") ..%Connection=tCfg
		Quit:""=..JGService $$$ERROR($$$EnsErrGeneral,"The JGService setting must be configured in order for this Adapter to work with a JDBC DSN : "_tCfg.DSN)
	}
	Set tSC=..initAdapterJG()  Quit:$$$ISERR(tSC) tSC
	Set ..attrIDs("accessmode") = ..#AccessMode
	Set ..attrIDs("ansiapp") = ..#AnsiApp
	Set ..attrIDs("appparamdesc") = ..#AppParamDesc
	Set ..attrIDs("approwdesc") = ..#AppRowDesc
	Set ..attrIDs("asyncenable") = ..#AsyncEnable
	Set ..attrIDs("autocommit") = ..#AutoCommit
	Set ..attrIDs("autoipd") = ..#AutoIpd
	Set ..attrIDs("concurrency") = ..#Concurrency
	Set ..attrIDs("connectiondead") = ..#ConnectionDead
	Set ..attrIDs("connectiontimeout") = ..#ConnectionTimeout
	Set ..attrIDs("connectionpooling") = ..#ConnectionPooling
	Set ..attrIDs("cpmatch") = ..#CpMatch
	Set ..attrIDs("currentcatalog") = ..#CurrentCatalog
	Set ..attrIDs("cursorscrollable") = ..#CursorScrollable
	Set ..attrIDs("cursorsensitivity") = ..#CursorSensitivity
	Set ..attrIDs("cursortype") = ..#CursorType
	Set ..attrIDs("disconnectbehavior") = ..#DisconnectBehavior
	Set ..attrIDs("enableautoipd") = ..#EnableAutoIpd
	Set ..attrIDs("enlistindtc") = ..#EnlistInDtc
	Set ..attrIDs("enlistinxa") = ..#EnlistInXa
	Set ..attrIDs("impparamdesc") = ..#ImpParamDesc
	Set ..attrIDs("improwdesc") = ..#ImpRowDesc
	Set ..attrIDs("keysetsize") = ..#KeysetSize
	Set ..attrIDs("logintimeout") = ..#LoginTimeout
	Set ..attrIDs("maxlength") = ..#MaxLength
	Set ..attrIDs("maxrows") = ..#MaxRows
	Set ..attrIDs("metadataid") = ..#MetadataId
	Set ..attrIDs("noscan") = ..#NoScan
	Set ..attrIDs("odbccursors") = ..#OdbcCursors
	Set ..attrIDs("odbcversion") = ..#OdbcVersion
	Set ..attrIDs("outputnts") = ..#OutputNts
	Set ..attrIDs("packetsize") = ..#PacketSize
	Set ..attrIDs("parambindtype") = ..#ParamBindType
	Set ..attrIDs("paramsetsize") = ..#ParamsetSize
	Set ..attrIDs("querytimeout") = ..#QueryTimeout
	Set ..attrIDs("quietmode") = ..#QuietMode
	Set ..attrIDs("retrievedata") = ..#RetrieveData
	Set ..attrIDs("rowarraysize") = ..#RowArraySize
	Set ..attrIDs("rowbindtype") = ..#RowBindType
	Set ..attrIDs("rownumber") = ..#RowNumber
	Set ..attrIDs("simulatecursor") = ..#SimulateCursor
	Set ..attrIDs("trace") = ..#Trace
	Set ..attrIDs("tracefile") = ..#Tracefile
	Set ..attrIDs("translatelib") = ..#TranslateLib
	Set ..attrIDs("translatedll") = ..#TranslateLib
	Set ..attrIDs("translateoption") = ..#TranslateOption
	Set ..attrIDs("txnisolation") = ..#TxnIsolation
	Set ..attrIDs("usebookmarks") = ..#UseBookmarks
	Quit $$$OK
}

/// Execute a query. A variable number of parameters may be passed in addition to the
/// query string. Results are returned as a new EnsLib.SQL.GatewayResultSet object in the pRS output argument, unless
/// you pass in a EnsLib.SQL.Snapshot object for the pRS argument. In that case, ExecuteQuery will populate the Snapshot
/// object instead, using the values of its FirstRow and MaxRowsToGet properties to choose the set of rows it will represent.
Method ExecuteQuery(ByRef pRS As EnsLib.SQL.GatewayResultSet, pQueryStatement As %String, pParms...) As %Status
{
	Quit ..ExecuteQueryParmArray(.pRS,pQueryStatement,.pParms)
}

/// Execute a query. Any number of parameters may be passed in the multidimensional pParms array. For DSNs using ODBC drivers that don't support
/// SQLDescribeParam: SqlType, CType, Prec, and Scale may be specified as sub-nodes of the node for each parameter.
/// If the parameters in the pParms array have descriptor subscripts, then these are used and the SQLDescribeParam query is not done.
/// (This is determined by checking for a "SqlType" or "CType" subscript under the first parameter: (pParms(1,"SqlType"))).
Method ExecuteQueryParmArray(ByRef pRS As EnsLib.SQL.GatewayResultSet, pQueryStatement As %String, ByRef pParms) As %Status
{
	If '$$$IsdefObject(pRS) || 'pRS.%IsA("EnsLib.SQL.Snapshot") Kill pRS  Set pRS=$$$NULLOREF
	Set $ZT="Trap", tHS="", tSC=$$$OK, tNetErr=0
	Do {
		#; Connect if not already connected
		Set tSC=..Connect(..ConnectTimeout) If $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed)&&..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1  Quit

		#; Execute the statement
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..privPrepare(.tHS,pQueryStatement,.pParms,,,.tNetErr)  Quit:$$$ISERR(tSC)
			$$$sysTRACE("Executing...")
			Set tSC=..%Connection.Execute(tHS)
		} Else {
			Set tSC=..privPrepareJ(.tHS,pQueryStatement,.pParms,,,.tNetErr)  Quit:$$$ISERR(tSC)
			$$$sysTRACE("Executing...")
			Set tSC=..%Connection.execQuery(tHS)
		}
		Set:$$$SQLCODENeedData=..%Connection.sqlcode tSC=..putLOBStreams(tHS,.pParms)
		Quit:$$$ISERR(tSC)

		#; Succeeded, construct the result set
		Set tRS=##class(EnsLib.SQL.GatewayResultSet).%New()  $$$ASSERT($IsObject(tRS))
		Set tSC=tRS.Initialize(pQueryStatement,$this,tHS,1,"")  Quit:$$$ISERR(tSC)
		
		If $IsObject(pRS) { Set tSC=tRS.GetSnapshot(pRS) Quit:$$$ISERR(tSC) }
		Else { Set pRS = tRS }
		
	} While 0
Exit
	If $$$ISERR(tSC) {
		If 'tNetErr {
			#; if privPrepare() returned tNetErr already, we came direct and tSC is already decorated
			Set tNetErr=..isNetErr($$$StatusText(tSC))
			If tHS'=""&&'tNetErr {
				#; Add SQL detailed errors		
				Set tSC=..addErrorList(tSC,tHS,.tNetErr)
				If 'tNetErr {
					#; Drop the statement; If the drop fails, record that error status too
					Set tSC1=..%Connection.DropStatement(tHS)
					If $$$ISERR(tSC1) {
						Set:'tNetErr tNetErr=..isNetErr($$$StatusText(tSC1))
						Set tSC=$$$ADDSC(tSC,tSC1)
					}
				}
			}
		}
		If tNetErr Do ..Disconnect()  Set:..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1
	}
	Do:'..StayConnected&&'$IsObject(pRS) ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Execute an Update, Insert or Delete. A variable number of parameters may be passed in addition to the
/// query string. The pNumRowsAffected output value is the number of rows affected.
Method ExecuteUpdate(Output pNumRowsAffected As %Integer, pUpdateStatement As %String, pParms...) As %Status
{
	Quit ..ExecuteUpdateParmArray(.pNumRowsAffected,pUpdateStatement,.pParms)
}

/// Execute an Update, Insert or Delete. Any number of parameters may be passed in the multidimensional pParms array. For DSNs using ODBC drivers that don't support
/// SQLDescribeParam: SqlType, CType, Prec, and Scale may be specified as sub-nodes of the node for each parameter.
/// If the parameters in the pParms array have descriptor subscripts, then these are used and the SQLDescribeParam query is not done.
/// (This is determined by checking for a "SqlType" or "CType" subscript under the first parameter: pParms(1,"SqlType") ).
Method ExecuteUpdateParmArray(Output pNumRowsAffected As %Integer, pUpdateStatement As %String, ByRef pParms) As %Status
{
	Set $ZT="Trap", tHS="", tSC=$$$OK, (tNetErr,pNumRowsAffected)=0
	Do {
		#; Connect if not already connected
		Set tSC=..Connect(..ConnectTimeout) If $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed)&&..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1  Quit
		
		#; Execute the statement
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..privPrepare(.tHS,pUpdateStatement,.pParms,,,.tNetErr)  Quit:$$$ISERR(tSC)
			$$$sysTRACE("Executing...")
			Set tSC=..%Connection.Execute(tHS)
		} Else {
			Set tSC=..privPrepareJ(.tHS,pUpdateStatement,.pParms,,,.tNetErr)  Quit:$$$ISERR(tSC)
			$$$sysTRACE("Executing...")
			Set tSC=..%Connection.execUpdate(tHS)
		}
		Set:100=..%Connection.sqlcode tSC=$$$OK
		Set:$$$SQLCODENeedData=..%Connection.sqlcode tSC=..putLOBStreams(tHS,.pParms)
		Quit:$$$ISERR(tSC)

		#; Get the count of rows affected
		Set tNumRowsAffected=..%Connection.RowCount(tHS)
		
		Set tSC=..%Connection.DropStatement(tHS), tHS=""  Quit:$$$ISERR(tSC)
		
		#; Assign the output
		Set pNumRowsAffected=tNumRowsAffected
	} While 0
Exit
	If $$$ISERR(tSC) {
		If 'tNetErr {
			#; if privPrepare() returned tNetErr already, we came direct and tSC is already decorated
			Set tNetErr=..isNetErr($$$StatusText(tSC))
			If tHS'=""&&'tNetErr {
				#; Add SQL detailed errors
				Set tSC=..addErrorList(tSC,tHS,.tNetErr)
				If 'tNetErr {
					#; Drop the statement; If the drop fails, record that error status too
					Set tSC1=..%Connection.DropStatement(tHS)
					If $$$ISERR(tSC1) {
						Set:'tNetErr tNetErr=..isNetErr($$$StatusText(tSC1))
						Set tSC=$$$ADDSC(tSC,tSC1)
					}
				}
			}
		}
		If tNetErr Do ..Disconnect()  Set:..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1
	}
	Do:'..StayConnected ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Execute a stored procedure SQL Call statement. A variable number of parameters may be passed in addition to the
/// query string. Results are returned as a new EnsLib.SQL.Snapshot objects in the pResultSnapshots output list. If you pass in a list with
/// pre-instantiated EnsLib.SQL.Snapshot objects, ExecuteProcedure will populate the Snapshot objects using the values of their FirstRow
/// and MaxRowsToGet properties to limit the set of rows it will retrieve.
/// The pOutputParms list returns the output values of all scalar output and input/output parameters.
/// If the procedure returns a scalar return value and your statement retrieves it, this value will be the first output value.
/// The pIO argument is optional; it is not needed unless the particular ODBC driver omits support for DescribeProcedureColumns.
/// If given it is a text string in which each character corresponds to one of the query parameters. The character 'i' means the
/// corresponding parameter is an Input parameter. The character 'o' means it is an Output parameter, and 'b' means it is Both an Input
/// and an Output parameter. Appending a '*' to the pIO argument prevents the adapter from calling ODBC DescribeProcedureColumns() to
/// get parameter info, forcing the use of the types listed in the pIO string; otherwise the adapter will log warnings if the parameter
/// types listed in pIO differ from those retrieved using DescribeProcedureColumns(). 
/// Appending a '#' to the pIO argument (or passing only '#') prevents the adapter from using cached DescribeColumns() results for the
/// procedure call output, forcing a fresh call to ODBC DescribeColumns() every time the stored procedure is invoked. 
/// This can be necessary if the procedure is capable of returning different sequences of result types from consecutive invocations.
/// After the pIO argument, you should add an argument with the value of each Input or Input/Output parameter.
Method ExecuteProcedure(ByRef pResultSnapshots As %ListOfObjects, Output pOutputParms As %ListOfDataTypes, pQueryStatement As %String, pIO As %String, pInputParms...) As %Status
{
	Quit ..ExecuteProcedureParmArray(.pResultSnapshots,.pOutputParms,pQueryStatement,.pIO,.pInputParms)
}

/// Execute a stored procedure SQL Call statement. Any number of parameters may be passed in the multidimensional pIOParms array. For DSNs using
/// ODBC drivers that don't support SQLDescribeParam: IOType, SqlType, CType, Prec, and Scale may be specified as sub-nodes of the node for each parameter.
/// If pIO is given, it is a string of IO types for the statement parameters as described for ExecuteProcedure() above.
/// If pIO is not given the IO types for the parameters may be given under an "IOType" subscript for each parameter in the pIOParms array. This means that
/// Output parameters must also be included in the array, but the top node for each of these must be left undefined.
/// If the parameters in the pParms array have descriptor subscripts, then these are used and the SQLDescribeParam query is not done.
/// (This is determined by checking for a "SqlType" or "CType" subscript under the first parameter: pParms(1,"SqlType") ).
Method ExecuteProcedureParmArray(ByRef pResultSnapshots As %ListOfObjects, Output pOutputParms As %ListOfDataTypes, pQueryStatement As %String, pIO As %String = "", ByRef pIOParms) As %Status
{
	Set $ZT="Trap", tHS="", tNoDC=0, tSC=$$$OK, (tHasResults,tNetErr)=0  Kill pOutputParms Set pOutputParms=$$$NULLOREF
	Do {
		Set:"#"=$E(pIO,*) $E(pIO,$L(pIO))="", tNoDC=-1 ; remove and remember the trailing '#' if any

		#; Connect if not already connected
		Set tSC=..Connect(..ConnectTimeout) If $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed)&&..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1  Quit

		#; Execute the statement
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..privPrepare(.tHS,pQueryStatement,.pIOParms,pIO,.tOutParmsCount,.tNetErr)  Quit:$$$ISERR(tSC)
			If $$$ISOK(tSC) {
				$$$sysTRACE("Executing...")
				Set tSC=..%Connection.Execute(tHS), tHasResults=1
			}
		} Else {
			Set tSC=..privPrepareJ(.tHS,pQueryStatement,.pIOParms,pIO,.tOutParmsCount,.tNetErr)  Quit:$$$ISERR(tSC)
			If $$$ISOK(tSC) {
				$$$sysTRACE("Executing...")
				Set tSC=..%Connection.execProc(tHS,.tHasResults)
			}
		}
		Set:$$$SQLCODENeedData=..%Connection.sqlcode tSC=..putLOBStreams(tHS,.pIOParms)
		Quit:$$$ISERR(tSC)

		#; construct the result record set snapshot(s)
		If $$$IsdefObject(pResultSnapshots) && pResultSnapshots.%Extends("%Collection.AbstractListOfObj") { Set tRSCount = pResultSnapshots.Count() }
		Else { Set pResultSnapshots = $$$NULLOREF }
		Set (tNumRS,tRes)=1  While tHasResults {
			#; Succeeded, construct the snapshot(s) if any
			$$$sysTRACE("Getting results")
			Set tRS=##class(EnsLib.SQL.GatewayResultSet).%New()  $$$ASSERT($IsObject(tRS))
			Set tSC=tRS.Initialize(pQueryStatement,$this,tHS,0,$S(-1=tNoDC:-1, 1:tRes)), tRes=tRes+1
			If $$$ISERR(tSC) {
				Quit:'$$$StatusEquals(tSC,$$$EnsErrNoSQLColumns)
				Set tSC=..%Connection.MoreResults(tHS)  If 100=..%Connection.sqlcode Set tSC=$$$OK  Quit
				Quit:$$$ISERR(tSC)
				Continue ; there is more; try again for a resultset
			}
			If '$IsObject(pResultSnapshots) Set pResultSnapshots=##class(%ListOfObjects).%New(), tRSCount=0  $$$ASSERT($IsObject(pResultSnapshots))

			Set tSnap=pResultSnapshots.GetAt(tNumRS),tHadSnap=$IsObject(tSnap) Set:tHadSnap&&'tSnap.%Extends("EnsLib.SQL.Snapshot") tSnap=$$$NULLOREF,tHadSnap=0
			If tHadSnap $$$sysTRACE("Using initialized SnapShot "_(tNumRS))
			Set tSC=tRS.GetSnapshot(.tSnap,1) Quit:$$$ISERR(tSC)
			Set tSC=$S(tHadSnap:$$$OK, tNumRS<tRSCount:pResultSnapshots.SetAt(tSnap,tNumRS), 1:pResultSnapshots.Insert(tSnap)) Quit:$$$ISERR(tSC)
			Set tNumRS=tNumRS+1
			Set tSC=..%Connection.MoreResults(tHS)  If 100=..%Connection.sqlcode Set tSC=$$$OK  Quit
			Quit:$$$ISERR(tSC)
		} Set tNumRS=tNumRS-1  Kill tRS

		#; Fetch the return value / output parameter(s) if any
		If $$$ISOK(tSC) && $G(tOutParmsCount) {
			Set tNumParams=pIOParms  For tI=1:1:tNumParams {
				If ..#SQLParamInput'=pIOParms(tI,"IOType") {
					If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
						Set tSC=..%Connection.GetParameter(tHS, tI, .tValue)  Quit:$$$ISERR(tSC)
						Set:""'=tValue tValue=$LI(tValue,1)
					} Else {
						Continue:'$G(pIOParms(tI,"Used"),1)
						Set tOrd=$G(pIOParms(tI,"Ordinal"),tI), tSqlType=$G(pIOParms(tI,"SqlType")), tTypeName=$G(pIOParms(tI,"SqlTypeName")), tIsLOB=pIOParms(tI,"LOB"), tIsBin=pIOParms(tI,"Bin")
						Set tHadSnap=0
						Try {
							If $IsObject(pResultSnapshots),'tIsLOB,##class(EnsLib.SQL.CommonJ).isaRS(tSqlType, tTypeName),(pResultSnapshots.Count()>tNumRS) {
								Set tValue=pResultSnapshots.GetAt(tNumRS+1),tHadSnap=$IsObject(tValue)
								If tHadSnap,'tValue.%Extends("EnsLib.SQL.Snapshot") {Kill tValue Set tHadSnap=0}
								If tHadSnap $$$sysTRACE("Using initialized SnapShot "_(tNumRS+1))
							}
						} Catch e { Set tSC = e.AsStatus()}
						Quit:$$$ISERR(tSC)
						Set tSC=..%Connection.GetParameter(tHS, tOrd, .tValue, tSqlType, tTypeName, tIsLOB, tIsBin)  Quit:$$$ISERR(tSC)
						#; If the returned value was a ResultSet, return it in pResultSnapshots rather than pOutputParms
						If $IsObject(tValue),tValue.%Extends("%Library.IResultSet") {
							If '$IsObject(pResultSnapshots) Set pResultSnapshots=##class(%ListOfObjects).%New(), tRSCount=0  $$$ASSERT($IsObject(pResultSnapshots))
							Set tSC=$S(tHadSnap:$$$OK, tI<tRSCount:pResultSnapshots.SetAt(tValue,tI), 1:pResultSnapshots.Insert(tValue)) Quit:$$$ISERR(tSC)
							$$$sysTRACE("getting parm object "_tI_" / Ordinal "_tOrd_", type "_tSqlType_"("_tTypeName_") / result "_tI_" = '"_tValue_"'")
							Set tNumRS=tNumRS+1
							Kill tValue
							Continue
						}
					}
					If '$$$IsdefObject(pOutputParms) Set pOutputParms=##class(%ListOfDataTypes).%New()  $$$ASSERT($IsObject(pOutputParms))
					Set tSC=pOutputParms.Insert(tValue)  Quit:$$$ISERR(tSC)
					$$$sysTRACE("getting parm "_tI_$S($D(tOrd):" / Ordinal "_tOrd_", type "_tSqlType_"("_tTypeName_")",1:"")_" / output "_pOutputParms.Count()_" = '"_tValue_"'")
					Kill tValue
				}
			}
		}
		#;tSC could be an error from above in For loop. Statement will be dropped in Exit
		Quit:$$$ISERR(tSC) 
 		#; Delete trailing entries in the pResultSnapshots list that came in, if it was longer than the list we actually retrieved
 		If $IsObject(pResultSnapshots) {
			If 'tNumRS { Set pResultSnapshots=$$$NULLOREF }
			Else { For tI=pResultSnapshots.Count():-1:tNumRS+1 { Do pResultSnapshots.RemoveAt(tI) } }
		}
		#; Get the update counts of rows affected
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set pResultSnapshots("UpdateCount")=..%Connection.RowCount(tHS)
		} Else {
			Merge pResultSnapshots("UpdateCount")=..%Connection.%rowcount(tHS)
		}		
		Set tSC=..%Connection.DropStatement(tHS), tHS=""  Quit:$$$ISERR(tSC)
	} While 0
Exit
	If $$$ISERR(tSC) {
		If 'tNetErr {
			#; if privPrepare() returned tNetErr already, we came direct and tSC is already decorated
			Set tNetErr=..isNetErr($$$StatusText(tSC))
			If tHS'=""&&'tNetErr {
				#; Add SQL detailed errors		
				Set tSC=..addErrorList(tSC,tHS,.tNetErr)
	
				#; Drop statement; If the drop fails, record that error status too
				Set tSC1=..%Connection.DropStatement(tHS)
				If $$$ISERR(tSC1) {
					Set:'tNetErr tNetErr=..isNetErr($$$StatusText(tSC1))
					Set tSC=$$$ADDSC(tSC,tSC1)
				}
			}
		}
		If tNetErr Do ..Disconnect()  Set:..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1
	}
	// ElseIf $D(..%rowcount) { Set tParms=$G(pOutputParms) Merge pOutputParms=..%rowcount  Set pOutputParms(1)=pOutputParms, pOutputParms=tParms  ZKill:""=tParms pOutputParms }
	Do:'..StayConnected ..Disconnect()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// <p>Internal common worker method.</p>
/// <p>
/// 	Note that <b>pIO</b> is not needed unless the particular ODBC driver omits support for <b>DescribeProcedureColumns</b>.<br/>
/// 	If <b>pIO</b> is defined, it is a String of IO types for the statement parameters.<br/>
/// 	If <b>pIO</b> is not defined, the IO types for the parameters may be given under an "IOType" subscript for each parameter in the <b>&pParms</b> array.<br/>
/// </p>
/// <p>
/// 	If the parameters in the <b>&pParms</b> array include descriptor subscripts, then these are used and the <b>SQLDescribeParam</b> query is not issued over
/// 	the database connection. (This is determined by checking for a "SqlType" or "CType" subscript under the first parameter: <code>pParms(1,"SqlType")</code> ).
/// </p>
/// <p>
/// 	In terms of the ODBC lifecycle, this method prepares, binds and sets non-stream/LOB parameters.
/// 	<method>ExecuteQueryParmArray</method> and <method>ExecuteProcedureParmArray</method>will be responsible
/// 	for executing the statement, checking for <b>SQL_NEED_DATA</b>, and setting stream/LOB parameters via <method>putLobStreams</method>.
/// </p>
Method privPrepare(Output pHS As %String, pSQLStatement As %String, ByRef pParms = 0, pIO As %String, Output pOutParmsCount As %Integer, Output pNetErr As %Status) As %Status [ Internal, Private ]
{
#define QueryParamsTable(%query)			$$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%QParms",%query)
#dim ex As %Exception.AbstractException

#; Offsets into $List of Parameter descriptors from DescribeParameters()
#define SqlType     1
#define Precision   2  /* ParameterSize */
#define Scale       3  /* DecimalDigits */
#define Nullable    4
#; Extras added in getProcedureParameters
#define IOType      5
#define ParmName    6
#define TypeName    7
#define OrdinalPos  8
#define ParmUsed	9
#define LiteralVal	10

	Set $ZT="Trap", pHS="", tSC=$$$OK
	Do {
		#; Set statement handle to illegal marker value, set up in case of Stored Procedure call
		Set tIsProcedure=$D(pIO)#2, pIO=$G(pIO), pNetErr=0
		$$$sysTRACE("Preparing SQL: """_pSQLStatement_""", IsProcedure="_tIsProcedure_", pIO="""_$G(pIO,"<undefined>")_"""")

		#; Get parameter descriptions by calling DescribeProcedureColumns if needed
		#; -skip calling DescribeProcedureColumns if pParms array contains descriptor info
		#;  or if pIO ends in a '*'
		Set tDPSC=0 ; Set 0 status for simulated error to force calling DescribeParameters()
		If tIsProcedure&&'($D(pParms(1,"SqlType"))#2)&&'($D(pParms(1,"CType"))#2)&&("*"'=$E(pIO,*)) {
			Set tDPSC=..getProcedureParameters(pSQLStatement,.tParmDescs,.pNetErr)
			If $$$ISERR(tDPSC) $$$sysTRACE("getProcedureParameters() returned error "_$S(pNetErr:"net ",1:"")_$$$StatusDisplayString(tDPSC))
			If pNetErr Set tSC=tDPSC, tDPSC=$$$OK  Quit // otherwise no Quit yet...
		}
		Set:"*"=$E(pIO,*) $E(pIO,$L(pIO))="" ;remove the trailing '*' if any

		#; Allocate a statement
		Set tSC=..%Connection.AllocateStatement(.pHS)
		If $$$ISERR(tSC) {
			Set pHS=""
			Set tSC=..addErrorList(tSC,pHS,.pNetErr)
			Quit
		}
		#; Set Statement Attributes
		If ""'=..StatementAttrs {
			For i=1:1:$L(..StatementAttrs,",") { Set tSetting=$P(..StatementAttrs,",",i), tAttrName=$ZStrip($P(tSetting,":",1),"<>W")  Continue:""=tAttrName
				Set tSC1=..%Connection.SetStmtOption(pHS,$G(..attrIDs($ZCVT(tAttrName,"L")),tAttrName), $P(tSetting,":",2))
				If $$$ISERR(tSC1) {
					$$$LOGWARNING("Failed to set statement attribute "_tAttrName_":"_tSetting_"; status = "_$$$StatusDisplayString(tSC))
					Set tSC1=..addErrorList(tSC1,pHS,.pNetErr)
					If pNetErr { Set tSC=tSC1  Quit }
				}
				Else { $$$sysTRACE("Set statement attribute "_tAttrName_":"_tSetting) }
			}
			Quit:$$$ISERR(tSC)
		}
		#; Prepare it
		If ..IsUnicodeDLL { Set tSC=..%Connection.PrepareW(pHS,pSQLStatement) }
		Else { Set tSC=..%Connection.Prepare(pHS,pSQLStatement) }  Quit:$$$ISERR(tSC)
		
		#; Retrieve the description of the parameters (if not using caller's parm subscripts)
		If tIsProcedure || +pParms { ; if (any parms)
			If $D(pParms(1,"SqlType"))#2||($D(pParms(1,"CType"))#2) {
				#; Caller provided info - don't call DescribeParameters
				Set tParmDescsCount=pParms
				$$$sysTRACE("Using caller-provided DescribeParameters subscript values")
			} Else {
				If $$$ISOK(tDPSC) {
					Set tParmDescsCount=$LG($LG(tParmDescs))
				} Else {
					#; Call DescribeParameters (or get its cached results)
					#dim tTableKey As %String
					Set tTableKey=$S($L(pSQLStatement)<=230:pSQLStatement, 1:$E(pSQLStatement,1,220)_".x"_$$$NUM($ZHex($ZCRC($E(pSQLStatement,221,*),7)),8))
					#dim tGetMetatData As %Boolean = 1
					Try {
						If $D($$$QueryParamsTable(tTableKey),tParmDescs) {
							Set tDPSC=$$$OK, tParmDescsCount=$LG($LG(tParmDescs)), tGetMetatData=0
							$$$sysTRACE("Using cached "_tParmDescsCount_" DescribeParameters values ; key="_tTableKey)
						}
					} Catch ex {
						If (ex.Name'="<SUBSCRIPT>") {throw ex}
						Set tTableKey = $system.Encryption.Base64Encode($system.Encryption.SHA1Hash(tTableKey))
						If $D($$$QueryParamsTable(tTableKey),tParmDescs) {
							Set tDPSC=$$$OK, tParmDescsCount=$LG($LG(tParmDescs)), tGetMetatData=0
							$$$sysTRACE("Using cached "_tParmDescsCount_" DescribeParameters values ; key="_tTableKey)
						}
					}
					If tGetMetatData {
						Set tDPSC=..%Connection.DescribeParameters(pHS,.tParmDescs) // No Quit yet...
						If $$$ISOK(tDPSC) {
							Set tParmDescsCount=$LG($LG(tParmDescs))
							$$$ASSERT($LL(tParmDescs)-1=tParmDescsCount) ; Discard the headers element of the list
							Set $$$QueryParamsTable(tTableKey)=tParmDescs
							$$$sysTRACE("DescribeParameters returned "_tParmDescsCount_"; pIO='"_pIO_"', pParms="_+pParms_" ; cacheing with key="_tTableKey)
						} Else {
							$$$sysTRACE("DescribeParameters failed:"_$$$StatusDisplayString(tDPSC))
							Set pNetErr=..isNetErr($$$StatusText(tDPSC))
							Set tDPSC=..addErrorList(tDPSC,pHS,.pNetErr)
							If pNetErr Set tSC=tDPSC, tDPSC=$$$OK  Quit
							Set tParmDescsCount=$S(""=pIO:pParms,1:$L(pIO))
						}
					}
				}
			}
			#; Iterate through the parms and build the bind arguments
			Set (tCallParmsCount,tInParmsCount,pOutParmsCount)=0, tIInParm=1
			For tI=1:1:tParmDescsCount {
				#; Get SqlType, Prec, Scale, etc.
				Set tDesc=$S($$$ISOK(tDPSC):$LI(tParmDescs,tI+1),1:"")
				If ""'=tDesc {
					#; .. from the parameter descriptor from either DescribeParameters() or getProcedureParameters()
					Set tSqlType=+$LI(tDesc,$$$SqlType)
					Set (tPrec,tLength)=+$LI(tDesc,$$$Precision)
					Set tScale=+$LI(tDesc,$$$Scale)
					Set tDPIO=$LG(tDesc,$$$IOType)
					Set tDPName=$LG(tDesc,$$$ParmName,"NameNA")
					Set tTypeName=$LG(tDesc,$$$TypeName,$G(pParms(tI,"SqlTypeName")))
					Set tCType="" ; calculate it out later
					Set tUseLOBLen=0
				} Else {
					#; DescribeParameters failed or we skipped it; use local descriptor declarations if present
					#; .. from extended pParms array nodes if present
					Set tCType=$G(pParms(tI,"CType"))
					Set tSqlType=$G(pParms(tI,"SqlType"))
					#; ensure tCType and tSqlType are numeric for correct binding on export
					Set:""'=tCType tCType = +tCType
					Set:""'=tSqlType tSqlType = +tSqlType
					Set:""=tSqlType tSqlType=tCType, tCType="" ; for back compatibility we support CType used as SqlType
					Set:""=tSqlType tSqlType=$$$SqlVarchar
					Set tScale=+$G(pParms(tI,"Scale"),0)
					Set (tPrec,tLength)=+$G(pParms(tI,"Prec"),255)
					Set tTypeName=$G(pParms(tI,"SqlTypeName"))
					Set (tDPIO,tDPName)=""
					Set tUseLOBLen=$G(pParms(tI,"UseLOBLen"))
				}
				#; Get the CType; Decide what kind of Numeric / Bin / LOB
				Set tUType=$ZCVT(tTypeName,"U")
				Set:""=tCType tCType=$G(..%ctypeMap(tSqlType))
				If ""'=tCType {
					Set tLOB=##class(EnsLib.SQL.GatewayResultSet).%isLOB(tUType,tSqlType,tLength,0,..MaxVarCharLengthAsString)
					Set tBin=(tCType=$$$SqlCBinary)
				} Else {
					Set tLOB=##class(EnsLib.SQL.GatewayResultSet).%isLOB(tUType,tSqlType,tLength,0,..MaxVarCharLengthAsString)
					Set tBin=##class(EnsLib.SQL.GatewayResultSet).%isBin(tUType,tSqlType)
					Set:""=tCType tCType=$Case(tSqlType
						, $$$SqlBigint:$$$SqlCSBigint, $$$SqlCSBigint:$$$SqlCSBigint, $$$SqlCUBigint:$$$SqlCSBigint
						, $$$SqlFloat:$$$SqlCDouble, $$$SqlReal:$$$SqlCDouble, $$$SqlDouble:$$$SqlCDouble
						, :$S(tBin:$$$SqlCBinary,1:$$$SqlCWChar)), ..%ctypeMap(tSqlType)=tCType ; cache it
				}
				If 'tIsProcedure { ##; Non-procedure parameters must be input only
					Set tIO=..#SQLParamInput, (tCallParmsCount,tInParmsCount,tIInParms(tI))=tI
					If $D(pParms(tI))#2 {
						If tLOB {
							Set tSC = ..CoerceStreamParameters(tI,.pParms,tUseLOBLen,.tPrec,.tLength,.tBin,.tCType)  Quit:$$$ISERR(tSC)
							If +tSC = 2 { $$$LOGWARNING("Object value supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tI_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tI_") is not a stream when a stream was expected.") }
						} ElseIf $Case(tCType,$$$SqlCChar:1,$$$SqlCWChar:1,:0) {
							#; make char CType match wide/narrow attribute of supplied parameter value
							Set pParms(tI)=$LB(""_pParms(tI))
							Set tCType=$Case($E(pParms(tI),2),$C(1):$$$SqlCChar, :$$$SqlCWChar)
						}
					} Else { $$$LOGWARNING("Value not supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tI_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tI_")") }
				} Else { ##; Get the IOType
					Set tIO=$E(pIO,tI) $$$ASSERT(""=tIO||$Case(tIO,"i":1,"b":1,"o":1,:0))
					Set tIO=$Case(tIO,"i":..#SQLParamInput,"b":..#SQLParamInputOutput,"o":..#SQLParamOutput,:"")
					If (""'=tDPIO) {
						If ""=tIO { Set tIO=tDPIO }
						ElseIf tDPIO'=tIO { $$$LOGWARNING("IOType '"_tIO_"' from pIO arg '"_pIO_"'("_tI_") does not match value '"_tDPIO_"' reported by DescribeProcedureColumns()") }
					}
					Set:""=tIO tIO=$G(pParms(tI,"IOType"),$S(($D(pParms(tIInParm))#2):..#SQLParamInput,1:..#SQLParamOutput))

					If tIO=..#SQLParamOutput {
						Set:'($D(pParms(tIInParm))#2) tIInParm=tIInParm+1
					} Else {
						Set tInParmsCount=tInParmsCount+1
						If $D(pParms(tIInParm))#2 {
							Set tIInParms(tI)=tIInParm
							If tLOB{
								Set tSC = ..CoerceStreamParameters(tIInParm, .pParms, tUseLOBLen, .tPrec, .tLength, .tBin, .tCType)  Quit:$$$ISERR(tSC)
								If +tSC = 2 { $$$LOGWARNING("Object value supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tI_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tIInParm_") is not a stream when a stream was expected.") }
							} ElseIf $Case(tCType,$$$SqlCChar:1,$$$SqlCWChar:1,:0) {
								#; make char CType match wide/narrow attribute of supplied parameter value
								Set pParms(tIInParm)=$LB(""_pParms(tIInParm))
								Set tCType=$Case($E(pParms(tIInParm),2),$C(1):$$$SqlCChar, :$$$SqlCWChar)
							}
							Set tIInParm=tIInParm+1, tCallParmsCount=tCallParmsCount+1
						} Else { $$$LOGWARNING("Value not supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tI_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tIInParm_")") }
					}
					Set:tIO'=..#SQLParamInput pOutParmsCount=pOutParmsCount+1
				}
				Set:""=$G(pParms(tI,"IOType")) pParms(tI,"IOType")=tIO
				Set:""=$G(pParms(tI,"SqlType")) pParms(tI,"SqlType")=tSqlType
				Set:""=$G(pParms(tI,"SqlTypeName")) pParms(tI,"SqlTypeName")=tTypeName
				Set:""=$G(pParms(tI,"CType")) pParms(tI,"CType")=tCType
				Set:""=$G(pParms(tI,"LOB")) pParms(tI,"LOB")=tLOB
				Set:""=$G(pParms(tI,"Bin")) pParms(tI,"Bin")=tBin
				Set tCTypes(tI) = tCType
				; "Used", "Ordinal" defined only in JDBC
				$$$sysTRACE("Binding "_$S($$$ISOK(tDPSC):"desc",1:"subsc")_" parm "_tI_$S(""'=tDPName:" ("_tDPName_")",1:"")_" : "_tIO_"('"_$Case(tIO,..#SQLParamInput:"i",..#SQLParamInputOutput:"b",..#SQLParamOutput:"o",:"?")_"'), "_tCType_", "_tSqlType_", "_tPrec_", "_tScale_", "_tLength)
				
				Set tSC=..%Connection.BindParameter(pHS,tI,tIO,tCType,tSqlType,tPrec,tScale,tLength)  Quit:$$$ISERR(tSC)
			} Quit:$$$ISERR(tSC)
			Set pParms=tParmDescsCount
			If tInParmsCount'=tCallParmsCount Set tSC=$$$ERROR($$$EnsErrSQLParmCount,tCallParmsCount,tInParmsCount)  Quit
			If tInParmsCount {
				#; Set each input or input/output parameter value
				For tI=1:1:tParmDescsCount {
					If ..#SQLParamOutput'=pParms(tI,"IOType") && '$G(pParms(tI,"LOB")) {
						Set tInParmI=pParms(tIInParms(tI))
						Set tCType = tCTypes(tI)
						If $$$SqlCChar=tCType {
							#; $LB already done in wide/narrow test above
							Set tParmArg=tInParmI,        tAs="as narrow string"
						} ElseIf $$$SqlCWChar=tCType {
							#; $LB already done in wide/narrow test above
							Set tParmArg=tInParmI,        tAs="as wide string"
						} ElseIf ""=tInParmI {
							#; Both $Double & $Decimal convert "" to 0
							Set tParmArg=$LB(""),  tAs="as "_$S($$$SqlCDouble=tCType:"double",1:"decimal")_":null"
						} ElseIf $$$SqlCDouble=tCType {
							Set tParmArg=$LB($Double(tInParmI)),  tAs="as double:"_$Double(tInParmI)
						} Else {
							Set tParmArg=$LB($Decimal(tInParmI)), tAs="as decimal:"_$Decimal(tInParmI)
						}
						$$$sysTRACE("setting parm "_tI_" / input "_tIInParms(tI)_" = '"_tInParmI_"' "_tAs)
						Set tSC=..%Connection.SetParameter(pHS,tParmArg,tI)  Quit:$$$ISERR(tSC)
					}
				}
			}
		} ; endif (any parms)
		If $$$ISERR(tSC) Set:0'=tDPSC&&$$$ISERR(tDPSC) tSC=$$$ADDSC(tSC,tDPSC)  Quit
	} While 0
	Quit tSC
Trap
	Set $ZT=""  Quit $$$EnsSystemError
}

Method CoerceStreamParameters(tIdx As %Integer, ByRef pParms, tUseLOBLen As %Boolean, ByRef tPrec As %Integer, ByRef tLength As %Integer, ByRef tBin As %Boolean, ByRef tCType As %Integer) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	Try {
		If $IsObject(pParms(tIdx)) {
			#; The second formal parameter of ..putLOBStream is %Stream.Object, so check that the user-provided value,
			#; if it is an object, is an instance of %Stream.Object
			If pParms(tIdx).%Extends("%Stream.Object") {
				If tUseLOBLen {
					Set tPrec=2147483647, tLength=$$$SqlLenDataAtExec(pParms(tIdx).Size)
				} Else {
					Set tPrec=0, tLength=$$$SqlDataAtExec
				}
			} Else {
				#; If the user-provided value is an object, but not an instance of %Stream.Object, then it is unclear what
				#; the correct serialization is. The default "toString" serialization of an object is either its %Id or its
				#; swizzle reference - both of which are nonsense values without their appropriate contexts.
				set tSC = $$$ERROR($$$GeneralError, "Not a Stream"), $extract(tSC) = 2
			}
		} Else {
			#; Create the stream from the provided input; it is sensible to treat the user-provided input as a string since
			#; it's confirmed to not be an object.
			Set tStream = $select(tBin: ##class(%Stream.TmpBinary).%New(), 1:##class(%Stream.TmpCharacter).%New())
			Set tSC = tStream.Write(pParms(tIdx))  Quit:$$$ISERR(tSC)
			if ('tBin) {
				#; make char CType match wide/narrow attribute of supplied parameter value
				Set tCType=$Select($Extract($LB(""_pParms(tIdx)),2)=$C(1):$$$SqlCChar, 1:$$$SqlCWChar)		
				Set tBin = (tCType = $$$SqlCChar) ##; slight optimization for narrow byte operations (i.e. ASCII, Latin-1, etc.)
			}
			Set tPrec=2147483647, tLength=$$$SqlLenDataAtExec(tStream.Size)
			Set pParms(tIdx) = tStream
		}
	} Catch ex {
		set tSC = $$$ADDSC(tSC, ex.AsStatus())
	}
	Quit tSC
}

Method addErrorList(pSC, pHS, ByRef pNetErr = 0) As %Status
{
	Set tSC=..%Connection.GetErrorList(pHS, .tErrorList)
	If $$$ISERR(tSC) { Set:'pNetErr pNetErr=..isNetErr($$$StatusText(tSC)) }
	ElseIf ""'=$G(tErrorList) {
		For i=1:1:$LL(tErrorList) { Set tErrorText=$LG(tErrorList,i)
			If ""'=$ZStrip(tErrorText,"<>WC")&&($$$StatusText(pSC)'[tErrorText) {
				Set pSC=$$$ADDSC(pSC, $$$ERROR($$$EnsErrGeneral,tErrorText))
				Set:'pNetErr pNetErr=..isNetErr(tErrorText)
			}
		}
	}
	Quit pSC
}

/// Set AutoCommit on or off for this adapter connection
/// This will only work after the DSN connection is established.
/// Set the ConnectAttrs property in your Operation/Service .OnInit() method if you want to set this at connect time.
Method SetAutoCommit(pAutoCommit = 1) As %Status [ CodeMode = expression ]
{
..SetConnectAttr("AutoCommit",pAutoCommit)
}

Method SetConnectAttr(pAttrName As %String, pVal As %String) As %Status
{
	#; Connect if not already connected
	Set tSC=..Connect(..ConnectTimeout) If $$$ISERR(tSC) Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectFailed)&&..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1  Quit tSC

	$$$sysTRACE("Setting connection attribute "_pAttrName_":"_pVal)
	Set tSC=..%Connection.SetConnectOption($G(..attrIDs($ZCVT(pAttrName,"L")),pAttrName),pVal)
	If $$$ISERR(tSC) {
		Set tHS=""
		Set tSC=..addErrorList(tSC,tHS,.tNetErr)
		If tNetErr Do ..Disconnect()  Set:..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1
	}
	Quit tSC
}

Method Commit() As %Status
{
	$$$sysTRACE("Executing Commit")
	Quit ..%Connection.Transact(0)
}

Method Rollback() As %Status
{
	$$$sysTRACE("Executing Rollback")
	Quit ..%Connection.Transact(1)
}

/// 	Parse the arguments list of a stored procedure query and build a map array of the parameterized args
ClassMethod parseSPQuery(ByRef pQuery As %String, pSubstLiteralVals As %Boolean, Output pProcName, Output pProcRet, Output pArgs, Output pArgMap) As %Status [ Internal ]
{
	Set pProcName=$P($ZStrip(pQuery,"*W"),"("), cp=$F($ZCVT(pProcName,"L"),"call"), pProcRet=("?="=$E(pProcName,cp-6,cp-5)), pProcName=$E(pProcName,cp,*)
	Set ppos=$F(pQuery,"("), tProcArgs=$E(pQuery,ppos,*)
	Set pArgs="(", (pos,pos0,iRaw)=1, iUsed=0  While (pos<=$L(tProcArgs)) && ($E(tProcArgs,pos)'=")") {
		#; skip to next arg, balancing quotes and parentheses
		Set (tParens,tSQuote,tDQuote)=0  While pos<=$L(tProcArgs) {
			Set tCh=$E(tProcArgs,pos)
			If 'tParens&&'tSQuote&&'tDQuote&&$Case(tCh,",":1,")":1,:0) {
				Set tArg=$ZStrip($E(tProcArgs,pos0,pos-1),"<>W")
				If tArg="?" {
					Set iUsed=iUsed+1, pArgMap(iRaw)=iUsed, pArgs=pArgs_"?"
				} Else {
					Set:"'"=$E(tArg)&&("'"=$E(tArg,*)) tArg=$E(tArg,2,*-1)
					Set:pSubstLiteralVals&&'$D(pArgMap(iRaw)) $E(pQuery,ppos-1+pos0,ppos-1+pos-1)="?", ppos=ppos+1-(pos-pos0), pArgMap(-iRaw)=tArg
				}
				Set:tCh="," pos=pos+1, pos0=pos, iRaw=iRaw+1, pArgs=pArgs_","
				Quit
			}
			Set:"("=tCh tParens=tParens+1
			Set:")"=tCh tParens=tParens-1
			Set:"'"=tCh&&'tDQuote&&("\"'=$E(tProcArgs,pos-1)||'tSQuote) tSQuote='tSQuote
			Set:""""=tCh&&'tSQuote&&("\"'=$E(tProcArgs,pos-1)||'tDQuote) tDQuote='tDQuote
			Set pos=pos+1
		}
	} Set pArgs=pArgs_")", pArgMap=iRaw
	Quit:""=pProcName $$$ERROR($$$EnsErrGeneral,"Unable to extract procedure name from procedure call stmt '"_pQuery_"'")
	Quit $$$OK
}

Method getProcedureParameters(ByRef pQuery As %String, Output pParmDescs As %List, Output pNetErr, pSubstLiteralVals As %Boolean = 0) As %Status
{
#define ProcColumnsTable(%proc)			$$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%ProcCols",%proc)
#define ProcColumnsTablePos(%proc,%pos)	$$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%ProcCols",%proc,%pos)
#dim ex As %Exception.AbstractException

	#; From Query string, parse out schema name, proc name, and args list
	Set tHS=""
	Set tSC=..parseSPQuery(pQuery,pSubstLiteralVals,.tProcName,.tProcRet,.tArgs,.tArgMap)  Quit:$$$ISERR(tSC) tSC
	Set tSchema = "", tCatalog = ""
	Set tProcLen = $length(tProcName, ".")
	If tProcLen = 2 {
		Set tSchema = $piece(tProcName, ".")
		Set tProcName = $piece(tProcName, ".", 2)
	}
	ElseIf tProcLen = 3 {
		Set tCatalog = $piece(tProcName, ".")
		Set tSchema = $piece(tProcName, ".", 2)
		Set tProcName = $piece(tProcName, ".", 3)
	}
	ElseIf tProcLen > 3 {
		Quit $$$ERROR($$$ProcedureNameInvalid, tProcName)
	}
	#; See if we've already cached the procedure columns for this procedure
	#dim tTableKey As %String
	Set tTableKey=tCatalog_"."_tSchema_"."_tProcName, tTableKey=$S($L(tTableKey)<=230:tTableKey, 1:$E(tTableKey,1,220)_".x"_$$$NUM($ZHex($ZCRC($E(tTableKey,221,*),7)),8))
	#dim tGetMetatData As %Boolean = 1
	Try {
		If $D($$$ProcColumnsTable(tTableKey),tDescs) {
			Set tGetMetatData = 0
			$$$sysTRACE("Using cached "_$S($D($$$ProcColumnsTablePos(tTableKey,0)):"ret+",1:"")_tDescs_" Procedure Parameters description for proc "_tSchema_"."_tProcName_" ; key="_tTableKey)
		}
	} Catch ex {
		If (ex.Name'="<SUBSCRIPT>") {throw ex}
		Set tTableKey = $system.Encryption.Base64Encode($system.Encryption.SHA1Hash(tTableKey))
		If $D($$$ProcColumnsTable(tTableKey),tDescs) {
			Set tGetMetatData = 0
			$$$sysTRACE("Using cached "_$S($D($$$ProcColumnsTablePos(tTableKey,0)):"ret+",1:"")_tDescs_" Procedure Parameters description for proc "_tSchema_"."_tProcName_" ; key="_tTableKey)
		}
	}
	
	If tGetMetatData {
		If '..%Connection.%Extends("EnsLib.SQL.CommonJ") {
			Set tSC=..getProcColumns(tSchema,tProcName,.tDescs,.pNetErr,tCatalog,tArgMap+tProcRet)
		} Else {
			Set tSC=..getProcColumnsJ(tSchema,tProcName,.tDescs,.pNetErr,tCatalog,tArgMap+tProcRet)
		}
		If $$$ISOK(tSC) {
			Merge $$$ProcColumnsTable(tTableKey)=tDescs
			$$$sysTRACE("Cached "_$S($D($$$ProcColumnsTablePos(tTableKey,0)):"ret+",1:"")_tDescs_" Procedure Parameters description for proc "_tSchema_"."_tProcName_" ; key="_tTableKey)
		} Else {
			$$$sysTRACE("getProcColumns("_tTableKey_") failed:"_$$$StatusDisplayString(tSC))
		}
	}
	If $$$ISERR(tSC) {
		#; if we get here with pNetErr we came direct and tSC is already decorated
		If ""=pNetErr {
			Set pNetErr=..isNetErr($$$StatusText(tSC))
			If tHS'=""&&'pNetErr {
				#; Add (additional) SQL detailed errors		
				Set tSC=..addErrorList(tSC,tHS,.pNetErr)
			}
		}
		Quit tSC
	}
	#;	For this SP call, construct a simulation of the DescribeParams $List($List) result, plus IOType,ParmName
	Set pParmDescs=""
	Set tDesc0=$G($$$ProcColumnsTablePos(tTableKey,0))
	If ""=tDesc0 {
		If tProcRet $$$LOGWARNING("Found no ReturnValue Parameter for query '?="_tSchema_"."_tProcName_tArgs_"'")
	} Else {
		If 'tProcRet {
			If 'pSubstLiteralVals { $$$sysTRACE("Skipping SP return value descriptor because query '"_pQuery_"' doesn't call for it") }
			Else {
				Set cp=$F($ZCVT(pQuery,"L"),"call")-4, cch=$E(pQuery,cp), $E(pQuery,cp)="?="_cch
				Set pParmDescs=pParmDescs_$LB(tDesc0_$LB(0)) ; "Used"=0
			}
		} Else {
			Set pParmDescs=pParmDescs_$LB(tDesc0_$LB(1)) ; "Used"=1
		}
	}
	For i=1:1:tArgMap {
		If $D(tArgMap(i),iUsed) {
			Set tDesc=$G($$$ProcColumnsTablePos(tTableKey,i))
			If ""=tDesc { $$$LOGWARNING("Found no Parameter "_i_" (used as "_iUsed_") for query '"_$S(tProcRet:"?=",1:"")_tSchema_"."_tProcName_tArgs_"'") }
			Else { Set tDesc=tDesc_$LB(1) } ; "Used"=1
			Set pParmDescs=pParmDescs_$LB(tDesc)
		} ElseIf pSubstLiteralVals {
			#; Add literal value to descriptors entry
			Set tDesc=$G($$$ProcColumnsTablePos(tTableKey,i))
			If ""=tDesc { $$$LOGWARNING("Found no Parameter "_i_$S($D(tArgMap(-i),val):" (with literal val "_val_")",1:"")_" for query '"_$S(tProcRet:"?=",1:"")_tSchema_"."_tProcName_tArgs_"'") }
			ElseIf $D(tArgMap(-i),val) { Set tDesc=tDesc_$LB(0,val) } ; "Used"=0, "LiteralVal"=val
			Set pParmDescs=pParmDescs_$LB(tDesc)
		}
	}
	Set pParmDescs=$LB($LB($LL(pParmDescs),"SqlType","Precision","Scale","Nullable","IOType","ParmName"))_pParmDescs
	Quit tSC
}

Method getProcColumns(pSchema As %String, pProcName As %String, Output pColDescs, ByRef pNetErr As %Boolean, pCatalog As %String = "", pExpectedCount As %Integer = 0) As %Status [ Internal ]
{
#; Column Ids for results of DescribeProcedureColumns
#define ProcedureCat     1
#define ProcedureSchema  2
#define ProcedureName    3
#define ColumnName       4
#define ColumnType       5
#define DataType         6
#define TypeName         7
#define ColumnSize       8 /* 2.0=Precision */
#define BufferLength     9 /* 2.0=Length */
#define DecimalDigits   10 /* 2.0=Scale */
#define NumPrecRadix    11
#define Nullable        12
#define Remarks         13
#; ODBC 3.0
#define ColumnDef       14
#define SqlDataType     15
#define SqlDatetimeSub  16
#define CharOctetLength 17
#define OrdinalPosition 18
#define IsNullable      19

	Kill pColDescs  Set pColDescs=0 
	Set tSC=..%Connection.AllocateStatement(.tHS)
	If $$$ISERR(tSC) {
		Set tHS=""
		Set tSC=..addErrorList(tSC,tHS,.tNetErr)
		If tNetErr Do ..Disconnect()  Set:..BusinessHost.%Extends("Ens.BusinessOperation") ..BusinessHost.Retry=1
		Quit tSC
	}
	If ..IsUnicodeDLL { Set tSC=..%Connection.DescribeProcedureColumnsW(tHS,pCatalog,pSchema,pProcName,"") }
	Else { Set tSC=..%Connection.DescribeProcedureColumns(tHS,pCatalog,pSchema,pProcName,"") } Quit:$$$ISERR(tSC) tSC

	#; Fetch the data and store away the relevant bits
	Set tHasReturn = 0
	For tIParam=0:1 {
		Set tSC1=..%Connection.Fetch(tHS)  If 100=..%Connection.sqlcode Set tSC1=$$$OK  Quit
		If $$$ISERR(tSC1) Set tSC=tSC1  Quit

		Kill tParamName
		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$ColumnName,$$$SqlCWChar,.tParamName) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$ColumnName,$$$SqlCChar,.tParamName) }
		#; tParamName is optional; quit only on network error
		If $$$ISERR(tSC) {
			Set pNetErr=..isNetErr($$$StatusText(tSC))
			Set:'pNetErr tSC=..addErrorList(tSC,tHS,.pNetErr)
			Quit:pNetErr
		}
		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$ColumnType,$$$SqlCWChar,.tIOType) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$ColumnType,$$$SqlCChar,.tIOType) }  Quit:$$$ISERR(tSC)

		Continue:tIOType=..#SQLResultCol ; skip columns; only look at params

		If 0 = tIParam {
			If (tIOType = ..#SQLReturnValue) { Set tHasReturn = 1, tIOType = ..#SQLParamOutput }
			Else { Set tIParam=1 }
		}
		If 0'=tIParam&&(tIOType=..#SQLReturnValue) Set tSC=$$$ERROR($$$EnsErrGeneral,"Found ReturnValue Parameter not at ordinal 0; driver is behaving in unexpected manner") Quit

		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$DataType,$$$SqlCWChar,.tType) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$DataType,$$$SqlCChar,.tType) }  Quit:$$$ISERR(tSC)

		Kill tTypeName
		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$TypeName,$$$SqlCWChar,.tTypeName) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$TypeName,$$$SqlCChar,.tTypeName) }
		#; tTypeName is optional; quit only on network error
		If $$$ISERR(tSC) {
			Set pNetErr=..isNetErr($$$StatusText(tSC))
			Set:'pNetErr tSC=..addErrorList(tSC,tHS,.pNetErr)
			Quit:pNetErr
		}
		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$ColumnSize,$$$SqlCWChar,.tSize) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$ColumnSize,$$$SqlCChar,.tSize) }  Quit:$$$ISERR(tSC)

		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$DecimalDigits,$$$SqlCWChar,.tDigits) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$DecimalDigits,$$$SqlCChar,.tDigits) }  Quit:$$$ISERR(tSC)

		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$Nullable,$$$SqlCWChar,.tNullable) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$Nullable,$$$SqlCChar,.tNullable) }  Quit:$$$ISERR(tSC)

		Kill tOrdinalPos
		If ..IsUnicodeDLL { Set tSC=..%Connection.GetDataW(tHS,$$$OrdinalPosition,$$$SqlCWChar,.tOrdinalPos) }
		Else { Set tSC=..%Connection.GetData(tHS,$$$OrdinalPosition,$$$SqlCChar,.tOrdinalPos) }
		#; tOrdinalPos is optional; quit only on network error
		If $$$ISERR(tSC) {
			Set pNetErr=..isNetErr($$$StatusText(tSC))
			Set:'pNetErr tSC=..addErrorList(tSC,tHS,.pNetErr)
			Quit:pNetErr
		}
		Set pColDescs(tIParam)=$LB(tType,tSize,tDigits,tNullable,tIOType,tParamName,tTypeName,tOrdinalPos)
		Set:pColDescs<tIParam pColDescs=tIParam
	}
	If tHS'=""&&'pNetErr {
		#; Add (additional) SQL detailed errors		
		Set:$$$ISERR(tSC) tSC=..addErrorList(tSC,tHS,.pNetErr)

		#; Drop statement; If the drop fails, record that error status too
		If 'pNetErr {
			Set tSC1=..%Connection.DropStatement(tHS)
			If $$$ISERR(tSC1) {
				Set:'pNetErr pNetErr=..isNetErr($$$StatusText(tSC1))
				Set tSC=$$$ADDSC(tSC,tSC1)
			}
		}
	}
	Quit:$$$ISERR(tSC) tSC
	If ('pColDescs)&&('tHasReturn) { $$$LOGWARNING("No Rows returned for DescribeProcedureColumnsW("_tHS_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	ElseIf pExpectedCount && (pExpectedCount > (pColDescs + tHasReturn)) { $$$LOGWARNING("Expected "_pExpectedCount_" columns, but only received "_pColDescs_" from DescribeProcedureColumnsW("_tHS_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	Else { $$$sysTRACE("Got "_$S(tHasReturn:"ret+",1:"")_pColDescs_" rows from DescribeProcedureColumnsW("_tHS_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	Quit $$$OK
}

Method putLOBStreams(pHS As %String, ByRef pIOParms As %String) As %Status
{
	For i=1:1:pIOParms {
		If $G(pIOParms(i,"IOType"))'=..#SQLParamOutput, $G(pIOParms(i,"LOB")) {
			Set tSC=..putLOBStream(pHS,pIOParms(i),$G(pIOParms(i,"Bin")))
		}
	}
	Set tSC=..%Connection.ParamData(pHS,"")
	Set:$$$ISERR(tSC)&&($$$SQLCODESuccessWithInfo=..%Connection.sqlcode) tSC=$$$OK
	Quit tSC
}

Method putLOBStream(pHS As %String, pStream As %Stream.Object, tBin As %Boolean) As %Status
{
	Set tSC=..%Connection.ParamData(pHS,.tInd)  Set:$$$SQLCODENeedData=..%Connection.sqlcode tSC=$$$OK  Quit:$$$ISERR(tSC) tSC
	Set temp=pStream.Read(16000)
	If (temp = "") {
		Set err=..%Connection.PutData(pHS,"")	
	} Else {
		While ""'=temp {
			If ..IsUnicodeDLL&&'tBin { Set tSC=..%Connection.PutDataW(pHS,temp) }
			Else { Set tSC=..%Connection.PutData(pHS,temp) }
			Quit:$$$ISERR(tSC)
			Set temp=pStream.Read(16000)
		}
	}
	Quit tSC
}

ClassMethod ConvertSQLTypeToInt(pSQLType) As %Integer
{
	Quit:(""=pSQLType)||(+pSQLType=pSQLType) pSQLType
	Set tSQLType = $Replace($zcvt(pSQLType,"l"),"_","")
	Quit $Case(tSQLType,
	"sqlunknowntype": $$$SqlUnknownType,
	"sqlchar": $$$SqlChar,
	"sqlnumeric": $$$SqlNumeric,
	"sqldecimal": $$$SqlDecimal,         
	"sqlinteger": $$$SqlInteger,
	"sqlsmallint": $$$SqlSmallint,
	"sqlfloat": $$$SqlFloat,
	"sqlreal": $$$SqlReal,
	"sqldouble": $$$SqlDouble,
	"sqldatetime": $$$SqlDateTime,
	"sqlvarchar": $$$SqlVarchar,
	"sqltypedate": $$$SqlTypeDate,
	"sqltypetime": $$$SqlTypeTime,
	"sqltypetimestamp": $$$SqlTypeTimestamp,
	"sqlwchar": $$$SqlWChar,
	"sqlwvarchar": $$$SqlWVarchar,
	"sqlslongvarchar": $$$SqlWLongVarchar,
	"sqlcwchar": $$$SqlCWChar,
	"sqldate": $$$SqlDate,
	"sqlinterval": $$$SqlInterval,
	"sqltime": $$$SqlTime,
	"sqltimestamp": $$$SqlTimestamp,
	"sqllongvarchar": $$$SqlLongVarchar,
	"sqlbinary": $$$SqlBinary,
	"sqlvarbinary": $$$SqlVarBinary,
	"sqllongvarbinary": $$$SqlLongVarBinary,
	"sqlbigint": $$$SqlBigint,
	"sqltinyint": $$$SqlTinyint,
	"sqlbit": $$$SqlBit,
	"sqlguid": $$$SqlGuid,
	"sqlcodeyear": $$$SqlCodeYear,
	"sqlcodemonth": $$$SqlCodeMonth,
	"sqlcodeday": $$$SqlCodeDay,
	"sqlcodehour": $$$SqlCodeHour,
	"sqlcodeminute": $$$SqlCodeMinute,
	"sqlcodesecond": $$$SqlCodeSecond,
	"sqlcodeyeartomonth": $$$SqlCodeYearToMonth,
	"sqlcodedaytohour": $$$SqlCodeDayToHour,
	"sqlcodedaytominute": $$$SqlCodeDayToMinute,
	"sqlcodedaytosecond": $$$SqlCodeDayToSecond,
	"sqlcodehourtominute": $$$SqlCodeHourToMinute,
	"sqlcodehourtosecond": $$$SqlCodeHourToSecond,
	"sqlcodeminutetosecond": $$$SqlCodeMinuteToSecond,
	"sqlintervalyear": $$$SqlIntervalYear,
	"sqlintervalmonth": $$$SqlIntervalMonth,
	"sqlintervalday": $$$SqlIntervalDay, 
	"sqlintervalhour": $$$SqlIntervalHour,
	"sqlintervalminute": $$$SqlIntervalMinute, 
	"sqlintervalsecond": $$$SqlIntervalSecond, 
	"sqlintervalyeartomonth": $$$SqlIntervalYearToMonth,
	"sqlintervaldaytohour": $$$SqlIntervalDayToHour, 
	"sqlintervaldaytominute": $$$SqlIntervalDayToMinute, 
	"sqlintervaldaytosecond": $$$SqlIntervalDayToSecond,
	"sqlintervalhourtominute": $$$SqlIntervalHourToMinute,
	"sqlintervalhourtosecond": $$$SqlIntervalHourToSecond, 
	"sqlintervalminutetosecond": $$$SqlIntervalMinuteToSecond,
	"sqlunicode": $$$SqlUnicode,
	"sqlunicodevarchar": $$$SqlUnicodeVarchar,
	"sqlunicodelongvarchar": $$$SqlUnicodeLongVarchar,
	"sqlunicodechar": $$$SqlUnicodeChar,
	"sqldb2blob": $$$SqlDB2BLOB,
	"sqldb2clob": $$$SqlDB2CLOB,
	"sqldb2dbclob": $$$SqlDB2DBCLOB,
	"sqldb2xml": $$$SqlDB2XML,
	"sqlcchar": $$$SqlCChar,
	"sqlclong": $$$SqlCLong,
	"sqlcshort": $$$SqlCShort,
	"sqlcfloat": $$$SqlCFloat,
	"sqlcdouble": $$$SqlCDouble,
	"sqlcnumeric": $$$SqlCNumeric,
	"sqlcdefault": $$$SqlCDefault,
	"sqlsignedoffset": $$$SqlSignedOffset,
	"sqlunsignedoffset": $$$SqlUnsignedOffset,
	"sqlcdate": $$$SqlCDate,
	"sqlctime": $$$SqlCTime,
	"sqlctimestamp": $$$SqlCTimeStamp,
	"sqlctypedate": $$$SqlCTypeDate,
	"sqlctypetime": $$$SqlCTypeTime,
	"sqlctypetimestamp": $$$SqlCTypeTimeStamp,
	"sqlcintervalyear": $$$SqlCIntervalYear,
	"sqlcintervalmonth": $$$SqlCIntervalMonth,
	"sqlcintervalday": $$$SqlCIntervalDay,
	"sqlcintervalhour": $$$SqlCIntervalHour,
	"sqlcintervalminute": $$$SqlCIntervalMinute,
	"sqlcintervalsecond": $$$SqlCIntervalSecond,
	"sqlcintervalyeartomonth": $$$SqlCIntervalYearToMonth,
	"sqlcintervaldaytohour": $$$SqlCIntervalDayToHour,
	"sqlcintervaldaytominute": $$$SqlCIntervalDayToMinute,
	"sqlcintervaldaytosecond": $$$SqlCIntervalDayToSecond,
	"sqlcintervalhourtominute": $$$SqlCIntervalHourToMinute,
	"sqlcintervalhourtosecond": $$$SqlCIntervalHourToSecond,
	"sqlcintervalminutetosecond": $$$SqlCIntervalMinuteToSecond,
	"sqlcbinary": $$$SqlCBinary,
	"sqlcbit": $$$SqlCBit,
	"sqlcsbigint": $$$SqlCSBigint,
	"sqlcubigint": $$$SqlCUBigint,
	"sqlctinyint": $$$SqlCTinyint,
	"sqlcslong": $$$SqlCSLong,
	"sqlcsshort": $$$SqlCSShort,
	"sqlcstinyint": $$$SqlCSTinyint,
	"sqlculong": $$$SqlCULong,
	"sqlcushort": $$$SqlCUShort,
	"sqlcutinyint": $$$SqlCUTinyint,
	"sqlcbookmark": $$$SqlCBookmark,
	"sqlcguid": $$$SqlCGuid,
	"sqltypenull": $$$SqlTypeNull,
	"sqlcvarbookmark": $$$SqlCVarBookmark,
	"sqljarray": $$$SqlJArray,
	"sqljbigint": $$$SqlJBigint,
	"sqljbinary": $$$SqlJBinary,
	"sqljbit": $$$SqlJBit,
	"sqljblob": $$$SqlJBLOB,
	"sqljboolean": $$$SqlJBoolean,
	"sqljchar": $$$SqlJChar,
	"sqljclob": $$$SqlJCLOB,
	"sqljdatalink": $$$SqlJDataLink,
	"sqljdate": $$$SqlJDate,
	"sqljdecimal": $$$SqlJDecimal,
	"sqljdistinct": $$$SqlJDistinct,
	"sqljdouble": $$$SqlJDouble,
	"sqljfloat": $$$SqlJFloat,
	"sqljinteger": $$$SqlJInteger,
	"sqljobject": $$$SqlJObject,
	"sqljlongnvarchar": $$$SqlJLongNVarchar,
	"sqljlongvarbinary": $$$SqlJLongVarBinary,
	"sqljlongvarchar": $$$SqlJLongVarchar,
	"sqljnchar": $$$SqlJNChar,
	"sqljnclob": $$$SqlJNCLOB,
	"sqljnull": $$$SqlJNull,
	"sqljnumeric": $$$SqlJNumeric,
	"sqljnvarchar": $$$SqlJNVarchar,
	"sqljother": $$$SqlJOther,
	"sqljreal": $$$SqlJReal,
	"sqljref": $$$SqlJRef,
	"sqljrowid": $$$SqlJRowID,
	"sqljsmallint": $$$SqlJSmallint,
	"sqljsqlxml": $$$SqlJSQLXML,
	"sqljstruct": $$$SqlJStruct,
	"sqljtime": $$$SqlJTime,
	"sqljtimestamp": $$$SqlJTimeStamp,
	"sqljtinyint": $$$SqlJTinyInt,
	"sqljvarbinary": $$$SqlJVarBinary,
	"sqljvarchar": $$$SqlJVarchar,
		: $$$SqlUnknownType)
}

}
