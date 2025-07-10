/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSQLTypes)

/// This class defines features shared by inbound and outbound SQL adapters, of both the ODBC and JDBC varieties
/// It also can be instantiated to represent a collection of config settings used to connect to a JDBC driver.
/// It also offers methods allowing an instance to be used as a Connection object on which JDBC gateway calls can be invoked
Class EnsLib.SQL.CommonJ Extends EnsLib.JavaGateway.Common [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Override to 0 from superclass because we support ODBC as well as JDBC. We will do our own error reporting if it's empty but we are configured for a JDBC DSN.
Parameter REQUIREJGSERVICE As %Boolean = 0;

/// This Data Source Name specifies the external datasource to connect to.
/// If this name matches the name of a JDBC or ODBC 'Object/SQL Gateway connection' configured from the System Management Portal,
/// the parameters from that specification will be used. Otherwise this value may be an ODBC DSN name configured in your OS, or a JDBC URL.
/// Note: if a JDBC URL, then in addition to Credentials the JDBCDriver and JDBCClasspath settings must also be configured, and ConnectionAttributes will also apply if configured.
Property DSN As %String(MAXLEN = 1000);

/// override and hard-code classname
Property JGClientEnsClassname As %String(MAXLEN = 128) [ InitialExpression = "%Net.Remote.Java.JDBCGateway" ];

/// JDBC Driver classname - not used for ODBC DSN connections
/// Note: if using a named SQL Gateway Connection as DSN,  this value is optional but if present
/// will override the value specified in the named JDBC SQL Gateway Connection's set of properties.
Property JDBCDriver As %String(MAXLEN = 1000) [ Required ];

/// Classpath for JDBC driver classname, if needed in addition to the ones configured in the Java Gateway Service
Property JDBCClasspath As %String(MAXLEN = 1000);

/// A set of SQL Connection Attribute options. </br></br>
/// For ODBC they are of the form attr<b>:</b>val<b>,</b>attr<b>:</b>val<b>,</b>...</br>
/// For example, "AutoCommit:1"</br></br>
/// For JDBC they are of the form attr<b>=</b>val<b>;</b>attr<b>=</b>val<b>;</b>...</br>
/// For example, "TransactionIsolationLevel=TRANSACTION_READ_COMMITTED"</br></br>
/// Note: if using a named JDBC SQL Gateway Connection as DSN, this value is optional but if present
/// will override the value specified in the named JDBC SQL Gateway Connection's Properties field.
Property ConnectionAttributes As %String(MAXLEN = "");

/// Number of seconds to wait on each attempt to connect to the database system.
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 15 ];

/// These are the production settings for this object
Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=SQL},DSN:Basic:selector?context={Ens.ContextSearch/DSNs},Credentials:Basic:credentialsSelector,JGService:Connection:selector?context={Ens.ContextSearch/ProductionItems?className=EnsLib.JavaGateway.Service&productionName=@productionId},JDBCDriver:Connection,JDBCClasspath:Connection,ConnectionAttributes:Connection,ConnectTimeout:Connection,-JGClientEnsClassname,-ExtraJGClasspaths,-JGClientConnectSpec";

/// This holds the Gateway Connection (for JDBC it is an instance of this same class that serves as a proxy)
Property %Connection As %RegisteredObject [ Internal ];

/* override type of proxy object */
Property %JGProxy As %Net.Remote.Java.JDBCGateway [ Internal ];

Property sqlcode As %Integer [ InitialExpression = 0, Internal ];

Property updatecount As %Integer;

/// Stores credentials
Property %CredentialsObj As Ens.Config.Credentials [ Internal ];

Property %ConnHandle As %String [ Internal ];

Property %DBName As %String [ Internal ];

Property %rowcount As %Integer [ Internal, MultiDimensional ];

Property %Adapter As EnsLib.SQL.CommonJ [ Internal ];

/// When greater than this length of characters a VARCHAR column is
/// to be treated as a LOB and stored in a stream. <br>
/// The default is 32767. <br>
/// Use -1 to use the system maximum string length of 3641144. <br>
/// Note the system maximum string length may change in future versions
/// and therefore the value used when -1 is selected can change. <br>
/// If the value entered is greater than the maximum system string length
/// then the maximum system string length will be used. <br><br>
/// This setting can be used for example when 'text' columns on the 
/// target system cannot be retrieved as LOBs and it is necessary to 
/// CAST the column as a VARCHAR longer than 32767. <br> 
Property MaxVarCharLengthAsString As %Integer [ InitialExpression = 32767 ];

Parameter LOBChunkSize As %Integer = 16000;

Method DSNSet(dsnstr As %String) As %Status
{
	Set tConnected = ..Connected
	Do:tConnected ..Disconnect()
	Set i%DSN=dsnstr
	Set ..JGClientConnectSpec=dsnstr
	If tConnected Do ..Connect(..%JGConnectTimeout,,..ConnectTimeout) // avoid referencing ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method JDBCClasspathSet(cpath) As %Status
{
	Set i%JDBCClasspath=cpath
	Set ..ExtraJGClasspaths=cpath
	Quit $$$OK
}

/// SQL_PARAM_ IOType values
Parameter SQLParamInput As %Integer = 1;

Parameter SQLParamInputOutput As %Integer = 2;

Parameter SQLResultCol As %Integer = 3;

Parameter SQLParamOutput As %Integer = 4;

Parameter SQLReturnValue As %Integer = 5;

/// SQL_ATTR_ values
Parameter AccessMode As %Integer = 101;

Parameter AnsiApp As %Integer = 115;

Parameter AppParamDesc As %Integer = 10011;

Parameter AppRowDesc As %Integer = 10010;

Parameter AsyncEnable As %Integer = 4;

Parameter AutoCommit As %Integer = 102;

Parameter AutoIpd As %Integer = 10001;

Parameter Concurrency As %Integer = 7;

Parameter ConnectionDead As %Integer = 1209;

Parameter ConnectionTimeout As %Integer = 113;

Parameter ConnectionPooling As %Integer = 201;

Parameter CpMatch As %Integer = 202;

Parameter CurrentCatalog As %Integer = 109;

Parameter CursorScrollable As %Integer = -1;

Parameter CursorSensitivity As %Integer = -2;

Parameter CursorType As %Integer = 6;

Parameter DisconnectBehavior As %Integer = 114;

Parameter EnableAutoIpd As %Integer = 15;

Parameter EnlistInDtc As %Integer = 1207;

Parameter EnlistInXa As %Integer = 1208;

Parameter ImpParamDesc As %Integer = 10013;

Parameter ImpRowDesc As %Integer = 10012;

Parameter KeysetSize As %Integer = 8;

Parameter LoginTimeout As %Integer = 103;

Parameter MaxLength As %Integer = 3;

Parameter MaxRows As %Integer = 1;

Parameter MetadataId As %Integer = 10014;

Parameter NoScan As %Integer = 2;

Parameter OdbcCursors As %Integer = 110;

Parameter OdbcVersion As %Integer = 200;

Parameter OutputNts As %Integer = 10001;

Parameter PacketSize As %Integer = 112;

Parameter ParamBindType As %Integer = 18;

Parameter ParamsetSize As %Integer = 22;

Parameter QueryTimeout As %Integer = 0;

Parameter QuietMode As %Integer = 111;

Parameter RetrieveData As %Integer = 11;

Parameter RowArraySize As %Integer = 27;

Parameter RowBindType As %Integer = 5;

Parameter RowNumber As %Integer = 14;

Parameter SimulateCursor As %Integer = 10;

Parameter Trace As %Integer = 104;

Parameter Tracefile As %Integer = 105;

Parameter TranslateLib As %Integer = 106;

Parameter TranslateOption As %Integer = 107;

Parameter TxnIsolation As %Integer = 108;

Parameter UseBookmarks As %Integer = 12;

/// Create a new configuration-object instance of this class, loading values from the DB if possible
/// This new instance may contain values distinct from those defined in the Adapter if loaded indirectly from a %Library.Sys.SQLConnection object in the DB
ClassMethod getConfigObj(pConfiguredUs As EnsLib.SQL.Common, pCredentials As Ens.Config.Credentials, pConn As %RegisteredObject) As EnsLib.SQL.CommonJ
{
	#; See if the DSN is a SQL Gateway configuration handle
	Set cname=pConfiguredUs.DSN
	&sql(Select isJDBC,url,dsn,usr,pwd,driver,classpath,properties
	 Into :isJDBC,:url,:dsn,:usr,:pwd,:driver,:classpath,:properties
	 From %Library.sys_SQLConnection
	 Where connection_name=:cname)
	If 100=SQLCODE {
		Set tCfg=pConfiguredUs
	} ElseIf 'SQLCODE {
		#; use an instance of ourself to hold the configured gateway values
		If $IsObject(pConn)&&pConn.%Extends("EnsLib.SQL.CommonJ") { Set tCfg=pConn }
		Else { Set tCfg=..%New() }
		If 'isJDBC {
			Set tCfg=pConfiguredUs
			Set tCfg.DSN=dsn
			Set:""=pCredentials.Username pCredentials.Username=usr
			Set:""=pCredentials.Password pCredentials.Password=$System.Encryption.AESBase64Decode(pwd,"3Mandelbrot!")
		} Else {
			Set tCfg.DSN=$S(url[":":"",1:"jdbc://")_url
			Set:""=pCredentials.Username pCredentials.Username=usr
			Set:""=pCredentials.Password pCredentials.Password=$System.Encryption.AESBase64Decode(pwd,"3Mandelbrot!")
			Set tCfg.JDBCDriver=$S(""=pConfiguredUs.JDBCDriver:driver, 1:pConfiguredUs.JDBCDriver)
			Set tCfg.JDBCClasspath=$S(""=pConfiguredUs.JDBCClasspath:classpath, 1:pConfiguredUs.JDBCClasspath)
			Set tCfg.ConnectionAttributes=$S(""=pConfiguredUs.ConnectionAttributes:properties, 1:pConfiguredUs.ConnectionAttributes)
			Set tCfg.JGService=pConfiguredUs.JGService
			If tCfg'=pConn {
				Set tSC=tCfg.initJG()  Quit:$$$ISERR(tSC) pConfiguredUs
				Set tCfg.BusinessHost=pConfiguredUs.BusinessHost
			}
		}
	}
	Quit tCfg
}

/// A shadow of the superclass JavaGateway Adapter Connect() method; in the subclass the SQL Adapter Connect() method overrides the superclass version and calls this one
Method ConnectJ(pClientTimeout As %Numeric = 15, pInbound As %Boolean = 0, pJGTimeout As %Numeric = 5) As %Status
{
	Set tSC=..ConnectJG(pJGTimeout,pInbound)  Quit:$$$ISERR(tSC) tSC
	Quit:..%JavaGateway.Closed $$$ERROR($$$EnsErrGeneral,"Failed to open connection to Java Gateway '"_..JGService_"' ("_..%IOAddr_")")

	Set %objlasterror=$$$OK
	Set ..%JGProxy=$zobjclassmethod(..JGClientEnsClassname,"%New",..%JavaGateway)
	If '$IsObject(..%JGProxy) { Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to instantiate Java Gateway Client class '"_..JGClientEnsClassname_"' "_$$$StatusDisplayString(%objlasterror)) }
	Else {
		Set $ZT="Trap"
		Set tSC=..OnConnectProxy(pClientTimeout,pInbound)
		If $$$ISOK(tSC)  {
			Set i%%IOAddr=..%JGServer_":"_..%JGPort_$S(""=..%JGSSLConfig:"",1:"/SSL="_..%JGSSLConfig)_"+"_..JGClientEnsClassname_":"_..%ClientIOAddr
			Set ..Connected=1, tTxt="Opened JG connection to "_..%IOAddr
			If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
			Kill ..%rowcount
			Set tErrText=$ZStrip(..BusinessHost.%LastReportedError,"*W")
			If tErrText [ "JavaGateway" || (tErrText [ "JDBCGateway") {
				Set ..BusinessHost.%LastReportedError=""
				$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
			}
			Quit $$$OK
		}
	}
Exit
	Set ..%JGProxy=$$$NULLOREF
	Do ..DisconnectJG(pInbound)
	Quit tSC
Trap
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo Exit
}

/// Callback method used in ConnectJ
Method OnConnectProxy(pTimeout As %Numeric, pInbound As %Boolean) As %Status [ Internal ]
{
	Quit:""=..JDBCDriver $$$ERROR($$$EnsErrGeneral,"Unable to connect with empty JDBCDriver setting value")
	Set tSC=..%JavaGateway.%ClassForNameSynch(..JDBCDriver)  Quit:$$$ISERR(tSC) tSC

	#dim tJDBCDriverConnectString = "driver:"_..JDBCDriver

	Set props=..ConnectionAttributes
	If (props'="") {
		If ((props'["user")&&(..%CredentialsObj.Username'="")) {
			Set props=props_";user="_..%CredentialsObj.Username
		}
		If ((props'["password")&&(..%CredentialsObj.Password'="")) {
			Set props=props_";password="_..%CredentialsObj.Password
		}
		Set ..%ConnHandle=..%JGProxy.connectWithPropString(tJDBCDriverConnectString,..DSN,props)
	} Else {
		Set ..%ConnHandle=..%JGProxy.connect(tJDBCDriverConnectString,..DSN,..%CredentialsObj.Username,..%CredentialsObj.Password)
	}
	If $Case(..%ConnHandle,"":1,-1:1,:0) {
		Set tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway connection failed for "_..DSN_" error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Set ..%DBName=$ZCVT(..%JGProxy.getDBName(..%ConnHandle),"U")

    //Quit:""'=tErrTxt $$$ERROR($$$EnsErrGeneral,"Java Gateway Client '"_..JGClientEnsClassname_".Connect("_..JGClientConnectSpec_","_pTimeout_","_pInbound_")' failed with status "_tErrTxt)
    Set ..%ClientIOAddr=..JGClientConnectSpec
    Quit $$$OK
}

/// Disconnect from the Java Gateway Client
Method DisconnectJ(pInbound As %Boolean = 0)
{
	Quit:'..Connected
	Set tSC=$$$OK, tTxt="Disconnecting from "_..%IOAddr
	If ..StayConnected<0 { $$$LOGINFO(tTxt) }
	Else {
		If pInbound&&'..StayConnected { $$$catTRACE("connwait",tTxt) }
		ElseIf ..%logConnections { $$$LOGINFO(tTxt) }
		Else { $$$sysTRACE(tTxt) }
	}
	If '..%JavaGateway.Closed && $IsObject(..%JGProxy) {
		Set $ZT="Trap"
		Set tSC=..OnDisconnectProxy(pInbound)
	}
Exit
	If $$$ISERR(tSC) $$$sysTRACE($$$StatusText(tSC)) ; log it here because nobody will return the error to the calling BP or BS
	Set ..%JGProxy=$$$NULLOREF, ..%ClientIOAddr=""
	Kill ..%rowcount
	Do ..DisconnectJG(pInbound)
	Set ..Connected=0
	Quit
Trap
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	GoTo Exit
}

Method OnDisconnectProxy(pInbound As %Boolean) As %Status [ Internal ]
{
	Quit $$$OK
}

Method TestConnectionJ(pInbound As %Boolean = 0)
{
	If '..Connected Set ..%JGProxy=$$$NULLOREF  Do:'..%JavaGateway.Closed ..%JavaGateway.%Disconnect()  Quit ; force JG class into sync in case it made a mistake
	$$$catTRACE("connwait","Testing Connection to "_..%IOAddr)
	If '..%JavaGateway.Closed && $IsObject(..%JGProxy) {
		Set $ZT="Trap"
		Set ..Connected=..OnIsConnectedProxy(pInbound)
	}
	Quit:..Connected

	Set tTxt=$$$StatusText($$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"JG", ..%IOAddr, "..%JGProxy.IsConnected("_pInbound_")"))
	If ..StayConnected<0 { $$$LOGWARNING(tTxt) } Else { If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } }
	Do ..Disconnect()
Trap  ; if it doesn't support isConnected then we just have to assume it still is connected
	Set $ZT="", tSC=$S($ZE["<ZJGTW>":$$$ERROR($$$EnsErrGeneral,"Java Gateway error:"_$$$StatusDisplayString(%objlasterror)),1:$$$SystemError)
	Set ..Connected=1
	Quit
}

Method OnIsConnectedProxy(pInbound As %Boolean) As %Boolean [ Internal ]
{
	Quit 1
}

/// Internal common worker method of Adapter (Not of Connection).
/// Note that pIO is generally not needed, especially not for JDBC.
/// If pIO is defined, it is a String of IO types for the statement parameters
/// If pIO is not defined, the IO types for the parameters may be given under an "IOType" subscript for each parameter in the pParms array.
/// If the parameters in the pParms array include descriptor subscripts, then these are used and the SQLDescribeParam query is not issued over
/// the database connection. (This is determined by checking for a "SqlType" or "CType" subscript under the first parameter: pParms(1,"SqlType") ).
Method privPrepareJ(Output pHS As %String, pSQLStatement As %String, ByRef pParms = 0, pIO As %String, Output pOutParmsCount As %Integer, Output pNetErr As %Status) As %Status [ Internal, Private ]
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
#define ParmUsed    9
#define LiteralVal  10

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
			#; Note: pSQLStatement will be modified if it contains literal or missing param values - they'll change to '?'s
			Set tSQL=pSQLStatement
			Set tDPSC=..getProcedureParameters(.pSQLStatement,.tParmDescs,.pNetErr,1)
			If pSQLStatement'=tSQL $$$sysTRACE("modified SQL: "_pSQLStatement)
			If $$$ISERR(tDPSC) $$$sysTRACE("getProcedureParameters() returned error "_$S(pNetErr:"net ",1:"")_$$$StatusDisplayString(tDPSC))
			If pNetErr Set tSC=tDPSC, tDPSC=$$$OK  Quit // otherwise no Quit yet...
		}
		Set:"*"=$E(pIO,*) $E(pIO,$L(pIO))="" ;remove the trailing '*' if any

		#; Prepare and Allocate a statement
		If tIsProcedure {
			Set tSC=..%Connection.PrepareProc(.pHS,pSQLStatement)
		} Else {
			Set tSC=..%Connection.Prepare(.pHS,pSQLStatement)
		}
		If $$$ISERR(tSC) Set pHS=""  Quit

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
			Set (tCallParmsCount,tInParmsCount,pOutParmsCount,tICallParm)=0, tIInParm=1
			For tI=1:1:tParmDescsCount {
				#; Get SqlType, SqlTypeName, OrdinalPos, ParmUsed, Prec, Scale, etc.
				Set tDesc=$S($$$ISOK(tDPSC):$LI(tParmDescs,tI+1),1:"")
				Kill tLiteralVal
				If ""'=tDesc {
					#; .. from the parameter descriptor from either DescribeParameters() or getProcedureParameters()
					Set tSqlType=+$LI(tDesc,$$$SqlType)
					Set tPrec=+$LI(tDesc,$$$Precision)
					Set tScale=+$LI(tDesc,$$$Scale)
					Set tPos=+$LG(tDesc,$$$OrdinalPos,tI)
					Set tDPIO=$LG(tDesc,$$$IOType)
					Set tDPName=$LG(tDesc,$$$ParmName,"NameNA")
					Set tTypeName=$LG(tDesc,$$$TypeName)
					Set tParmUsed=$LG(tDesc,$$$ParmUsed,1)
					Set:$LD(tDesc,$$$LiteralVal) tLiteralVal=$LI(tDesc,$$$LiteralVal)
				} Else {
					#; DescribeParameters failed or we skipped it; use local descriptor declarations if present
					#; .. from extended pParms array nodes if present
					Set tSqlType=+$G(pParms(tI,"SqlType"),+$G(pParms(tI,"CType"),$$$SqlVarchar)) ; for back compatibility we support CType used as SqlType
					Set tScale=+$G(pParms(tI,"Scale"),0)
					Set tPrec=+$G(pParms(tI,"Prec"),255)
					Set tTypeName=$G(pParms(tI,"SqlTypeName"),"VARCHAR")
					Set (tDPIO,tDPName)="", tParmUsed=1
					Set tPos=+$G(pParms(tI,"OrdinalPos"),tI)
				}
				#; Get the CType; Decide what kind of Numeric / Bin / LOB
				Set tUType=$ZCVT(tTypeName,"U")
				Set tLOB=##class(EnsLib.SQL.GatewayResultSet).%isLOB(tUType,tSqlType,tPrec,1,..MaxVarCharLengthAsString)
				Set tBin=##class(EnsLib.SQL.GatewayResultSet).%isBin(tUType,tSqlType)
				#; Get the IOType
				If 'tIsProcedure {
					Set tIO=..#SQLParamInput, (tCallParmsCount,tInParmsCount,tIInParms(tI))=tI
					If '($D(pParms(tI))#2) { $$$LOGWARNING("Value not supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tI_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tI_")") }
				} Else {
					If 'tParmUsed { Set tIO="" }
					Else {
						Set tICallParm=tICallParm+1
						Set tIO=$E(pIO,tICallParm) $$$ASSERT(""=tIO||$Case(tIO,"i":1,"b":1,"o":1,:0))
						Set tIO=$Case(tIO,"i":..#SQLParamInput,"b":..#SQLParamInputOutput,"o":..#SQLParamOutput,:"")
					}
					If (""'=tDPIO) {
						If ""=tIO { Set tIO=tDPIO }
						ElseIf tDPIO'=tIO { $$$LOGWARNING("IOType '"_tIO_"' from pIO arg '"_pIO_"'("_tICallParm_") does not match value '"_tDPIO_"' reported by DescribeProcedureColumns()") }
					}
					Set:""=tIO tIO=$G(pParms(tI,"IOType"),$S(($D(pParms(tIInParm))#2):..#SQLParamInput,1:..#SQLParamOutput))

					If (tIO=..#SQLParamOutput)||(tIO=..#SQLReturnValue) {
						Set:'($D(pParms(tIInParm))#2) tIInParm=tIInParm+1
					} ElseIf tParmUsed {
						Set tInParmsCount=tInParmsCount+1
						If $D(pParms(tIInParm))#2 { Set tIInParms(tI)=tIInParm, tIInParm=tIInParm+1, tCallParmsCount=tCallParmsCount+1  }
						Else { $$$LOGWARNING("Value not supplied for "_$Case(tIO,..#SQLParamInput:"Input",..#SQLParamInputOutput:"Input/Output",:"?")_" (code "_tIO_") parameter '"_pIO_"'("_tICallParm_")"_$S(""'=tDPName:" ("_tDPName_")",1:"")_" = input #"_tInParmsCount_" (array index "_tIInParm_")") }
					}
					#; Bind each output parameter
					If (tIO '= ..#SQLParamInput) {
						Set pOutParmsCount=pOutParmsCount+1
						$$$sysTRACE("Binding "_$S($$$ISOK(tDPSC):"desc",1:"subsc")_" output parm "_tI_" / Ordinal "_tPos_$S(""'=tDPName:" ("_tDPName_")",1:"")_" : "_tIO_"('"_$Case(tIO,..#SQLParamInputOutput:"b",..#SQLParamOutput:"o",..#SQLReturnValue:"r",:"?")_"'), "_tSqlType_"("_tTypeName_"), "_tPrec_", "_tScale)
						Set tSC=..%Connection.BindOutputParameter(pHS,tPos,tSqlType,tTypeName)
					}
				}
				#; Set each input or input/output parameter value
				If (tIO = ..#SQLParamInput) || (tIO = ..#SQLParamInputOutput) {
					If '$D(tLiteralVal,val) {
						Set val=$G(pParms($G(tIInParms(tI),-1)))
					}
					$$$sysTRACE("setting parm "_tI_" / input "_$S(tParmUsed:$G(tIInParms(tI),-1),1:"Literal("_tI_")")_" / Ordinal "_tPos_" = '"_val_"'")
					Set tSC=..%Connection.SetParameter(pHS,val,tPos,tSqlType,tLOB,tBin)  Quit:$$$ISERR(tSC)
				}
				Set:""=$G(pParms(tI,"IOType")) pParms(tI,"IOType")=tIO
				Set:""=$G(pParms(tI,"SqlType")) pParms(tI,"SqlType")=tSqlType
				Set:""=$G(pParms(tI,"SqlTypeName")) pParms(tI,"SqlTypeName")=tTypeName
				Set:""=$G(pParms(tI,"LOB")) pParms(tI,"LOB")=tLOB
				Set:""=$G(pParms(tI,"Bin")) pParms(tI,"Bin")=tBin
				Set:""=$G(pParms(tI,"Ordinal")) pParms(tI,"Ordinal")=tPos
				Set:""=$G(pParms(tI,"Used")) pParms(tI,"Used")=tParmUsed
				// Update pParms to ensure that all parameters are tracked
				Set:pParms<tI pParms=tI
			}
			If tInParmsCount'=tCallParmsCount Set tSC=$$$ERROR($$$EnsErrSQLParmCount,tCallParmsCount,tInParmsCount) Quit
		} ; endif (any parms)
		If $$$ISERR(tSC) Set:0'=tDPSC&&$$$ISERR(tDPSC) tSC=$$$ADDSC(tSC,tDPSC)  Quit
	} While 0
	Quit tSC
Trap
	Set $ZT=""  Quit $$$EnsSystemError
}

Method getProcColumnsJ(pSchema As %String, pProcName As %String, Output pColDescs, ByRef pNetErr As %Boolean, pCatalog As %String = "", pExpectedCount As %Integer = 0) As %Status [ Internal ]
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

	Kill pColDescs  Set pColDescs=0, tSC=$$$OK
	$$$sysTRACE("Calling JDBC GW getProcedureColumns("_..%Connection.%ConnHandle_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")")

	Set tHS=..%Connection.%JGProxy.getProcedureColumns(..%Connection.%ConnHandle,pCatalog,pSchema,pProcName,"")
	If tHS=-1 {
		Set tTxt=..%Connection.%JGProxy.getErrorText(), tTxt="JDBC Gateway getProcedureColumns("_..%Connection.%ConnHandle_","""_pCatalog_""","_pSchema_","_pProcName_","""") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Set tHasReturn = 0,tOrdStartsZero = 0 
	For tIParam=0:1 {
		Set tArg=-1  Quit:'..%Connection.%JGProxy.cnext(tHS)

		Set tArg=$$$ColumnType, tIOType=..%Connection.%JGProxy.cgetString(tHS,tArg)
		Quit:..%Connection.%JGProxy.wasError()

		Continue:tIOType=..#SQLResultCol ; skip columns metadata; only look at params

		Kill tParamName
		Set tArg=$$$ColumnName, tParamName=..%Connection.%JGProxy.cgetString(tHS,tArg)
		#; tParamName is optional; quit only on network error
		If ..%Connection.%JGProxy.wasError() {
			Set tTxt=..%Connection.%JGProxy.getErrorText(), tTxt="JDBC Gateway cgetString("_tHS_","_tArg_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
			Set tSC=$$$ERROR($$$RemoteGatewayError,tTxt)
			Set pNetErr=..isNetErr($$$StatusText(tSC))
			Set tSC=..addErrorList(tSC, tHS,.pNetErr)
			Set tArg=0
			Quit:pNetErr
			$$$sysTRACE("optional ParamName "_tIParam_" not available: "_tTxt)
		}
		If 0 = tIParam {
			If (tIOType =..#SQLReturnValue) { Set tHasReturn = 1, tIOType = ..#SQLParamOutput }
			Else { Set tIParam = 1 }
		}
		If 0'=tIParam&&(tIOType=..#SQLReturnValue) Set tSC=$$$ERROR($$$EnsErrGeneral,"Found ReturnValue Parameter not at ordinal 0; driver is behaving in unexpected manner")
		
		Set tArg=$$$DataType, tType=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Set tArg=$$$ColumnSize, tSize=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Set tArg=$$$DecimalDigits, tDigits=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Set tArg=$$$Nullable, tNullable=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Set tArg=$$$TypeName, tTypeName=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Set tArg=$$$OrdinalPosition, tOrdinalPos=..%Connection.%JGProxy.cgetString(tHS,tArg)
		If '..%Connection.%JGProxy.wasError() { Goto NoErr }}}}}}
			Quit
NoErr
		#; Check if we need to account for Parameters being identified as starting at 0
		If 'tHasReturn,tIParam=1,tOrdinalPos=0 Set tOrdStartsZero=1
		Set pColDescs(tIParam)=$LB(tType,tSize,tDigits,tNullable,tIOType,tParamName,tTypeName,tOrdinalPos+$S(tHasReturn:1,tOrdStartsZero:1,1:0))
		Set:pColDescs<tIParam pColDescs=tIParam
	}
	// Get error if cgetString() fails for an argument (i.e. tArg '= -1)
	// cnext() only reports if there are more rows, so we log a warning only if no columns were found
	If (tArg '= -1) {
		Set tTxt=..%Connection.%JGProxy.getErrorText(), tTxt="JDBC Gateway cgetString("_tHS_","_tArg_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Set tSC=$$$ERROR($$$RemoteGatewayError,tTxt)
	}
	If tHS'="" Set tSCDrop=..%Connection.DropResultSet(tHS)  Set:$$$ISERR(tSCDrop) tSC=$$$ADDSC(tSC,tSCDrop)
	Quit:$$$ISERR(tSC) tSC
	If ('pColDescs)&&('tHasReturn) { $$$LOGWARNING("No Rows returned for JDBC GW getProcedureColumns("_..%Connection.%ConnHandle_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	ElseIf pExpectedCount && (pExpectedCount > (pColDescs + tHasReturn)) { $$$LOGWARNING("Expected "_pExpectedCount_" columns, but only received "_pColDescs_" from JDBC GW getProcedureColumns("_..%Connection.%ConnHandle_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	Else { $$$sysTRACE("Got "_$S(tHasReturn:"ret+",1:"")_pColDescs_" rows from JDBC GW getProcedureColumns("_..%Connection.%ConnHandle_","""_pCatalog_""","""_pSchema_""","""_pProcName_""","""")") }
	Quit $$$OK
}

/// Decide whether the text of an error returned from the driver represents
/// a disconnection implying the need to re-connect.
/// Override this method in a subclass if you encounter other error signatures that ought to be in this list, 
/// Also please contact InterSystems so that we may add the new codes to the base IsTextNetworkError() method.
ClassMethod isNetErr(pErrorText As %String) As %Boolean
{
	Set is=##class(%Library.SQLGatewayConnection).IsTextNetworkError(pErrorText)
	/*
		Look to see if we created text to identify the error when calling
		prepareStatement and prepareProc.
		Originally %JGProxy would return an empty error code if could not
		communicate with the Gateway - hence the decision that it was a
		network error if ''.
		%JGProxy then returned a -1 and "Disconnected from Gateway" is added
		if the Gateway object used by %JGProxy was detected as Closed.
	*/
	If 'is {
		#dim tJDBCGatewayErrorReason As %String = $P(pErrorText,"JDBC Gateway ",2)
		Set is = $S(tJDBCGatewayErrorReason="":0,
					tJDBCGatewayErrorReason="prepareStatement() error ''":1,
					tJDBCGatewayErrorReason="prepareProc() error ''":1,
					tJDBCGatewayErrorReason["Disconnected from Gateway":1,
					1:0)
	}
	If is { $$$sysTRACE("Assuming network disconnect error based on: "_pErrorText) }
	Else {  $$$catTRACE("protocol","NOT assuming network disconnect error based on: "_pErrorText) }
	Quit is
}

/* JDBC Connection methods */
Method Prepare(Output pHS As %String, pSQLStatement As %String) As %Status [ Internal ]
{
	Set pHS=..%JGProxy.prepareStatement(..%ConnHandle,pSQLStatement)
	If ""'=pHS&&(pHS'=-1) Kill ..%rowcount(pHS)  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway prepareStatement() error '"_pHS_$S(""=tTxt||($C(0)=tTxt):"'",1:"': "_tTxt)
	/* 
		Add text that disconnected so can be used by isNetErr.
		This is due to change in %JGProxy that now returns -1 and not ""
		if network error communicating with the Gateway.
	*/
	If ..%JGProxy.Gateway.Closed||'..isConnectedToDevice(..%Connection.%JGProxy.Gateway.GatewayDevice) Set tTxt=tTxt_" (Disconnected from Gateway)"
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method PrepareProc(Output pHS As %String, pSQLStatement As %String) As %Status [ Internal ]
{
	Set pHS=..%JGProxy.prepareCall(..%ConnHandle,pSQLStatement)
	If ""'=pHS&&(pHS'=-1) Kill ..%rowcount(pHS)  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway prepareProc() error '"_pHS_$S(""=tTxt||($C(0)=tTxt):"'",1:"': "_tTxt)
	/* 
		Add text that disconnected so can be used by isNetErr.
		This is due to change in %JGProxy that now returns -1 and not ""
		if network error communicating with the Gateway.
	*/
	If ..%JGProxy.Gateway.Closed||'..isConnectedToDevice(..%Connection.%JGProxy.Gateway.GatewayDevice) Set tTxt=tTxt_" (Disconnected from Gateway)"
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method SetParameter(pHS As %String, pValue As %String, pParamNum As %Integer, pSqlType As %Integer, pLOB As %Boolean, pBin As %Boolean) As %Status [ Internal ]
{
	Set dt=pSqlType
	Set:dt=$$$SqlJOther dt=$$$SqlChar
	Set:..%DBName["ORACLE"&&(dt=$$$SqlTypeDate) dt=$$$SqlTypeTimestamp

	If 'pLOB {
		Set tErr=..%JGProxy.setValueDirect(pHS,pParamNum,pValue,dt)  If 'tErr Set ..sqlcode=0  Quit $$$OK
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway setValueDirect("_pHS_","_pParamNum_","_pValue_","_dt_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	} Else {
		Set tErr=..putLOBStreamJ(pHS,pParamNum,pValue,pBin)  If 'tErr Set ..sqlcode=0  Quit $$$OK
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway putLOBStreamJ("_pHS_","_pParamNum_","_pValue_","_pBin_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	}
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method BindOutputParameter(pHS As %String, pNum As %Integer, pType As %Integer, pTypeName As %String) As %Status
{
	Set dt=$$$SqlChar
	//If (pType=-10)!(",9,10,11,91,92,93,1111,2000,"[(","_pType_",")) {
	If $Case(pType
			, $$$SqlWLongVarchar:1
			, $$$SqlDateTime:1
			, $$$SqlInterval:1
			, $$$SqlTimestamp:1
			, $$$SqlTypeDate:1
			, $$$SqlTypeTime:1
			, $$$SqlTypeTimestamp:1
			, $$$SqlJOther:1
			, $$$SqlJObject:1
			, $$$SqlJCLOB:1
			, $$$SqlJBLOB:1 
			, :0) {
		Set dt=pType
		If ..%DBName["ORACLE" {
			If (dt=$$$SqlTypeDate) { Set dt=$$$SqlTypeTimestamp }
			ElseIf (dt=$$$SqlJOther) {
				Set:(pTypeName'="FLOAT")&&(pTypeName'="NVARCHAR2") dt=$$$SqlWLongVarchar
				Set:((pTypeName="FLOAT")!(pTypeName="NVARCHAR2")) dt=$$$SqlChar
			}
		}
	}
	Set tErr=..%JGProxy.registerOutParameter(pHS,pNum,dt)  If 'tErr Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway registerOutParameter("_pHS_","_pNum_","_dt_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method GetParameter(pHS As %String, pNum As %Integer, ByRef pValue As %String, pType As %Integer, pTypeName As %String, pIsLOB As %Boolean = 0, pIsBinary As %Boolean = 0) As %Status
{
	If (pIsLOB),(pTypeName'="NVARCHAR2") {
		Set tMeth="ArgLOB", tSC =..GetArgLOBData(pHS,pNum,pIsBinary,.pValue)
		If $$$ISERR(tSC) Set ..sqlcode=-400  Quit tSC
	} ElseIf (pType>=$$$SqlWVarchar)&&(pType<=$$$SqlChar) {
		Set tMeth="String", pValue=..%JGProxy.stgetString(pHS,pNum)
	} ElseIf (pType>=$$$SqlNumeric)&&(pType<=$$$SqlDouble) {
		Set tMeth="String", pValue=+..%JGProxy.stgetString(pHS,pNum)
	} ElseIf (..%DBName["ORACLE")&&(pType=$$$SqlTypeDate) {
		Set tMeth="Timestamp", pValue=..%JGProxy.stgetTimestamp(pHS,pNum)
	} ElseIf (pType=$$$SqlDateTime)||(pType=$$$SqlTypeDate) {
		Set tMeth="Date", pValue=..%JGProxy.stgetDate(pHS,pNum)
	} ElseIf (pType=$$$SqlInterval)||(pType=$$$SqlTypeTime) {
		Set tMeth="Time", pValue=..%JGProxy.stgetTime(pHS,pNum)
	} ElseIf ..isaRS(pType, pTypeName) {
		Set err=..%JGProxy.getArgRS(pHS,pNum)
		Set tRS=##class(EnsLib.SQL.GatewayResultSet).%New()  $$$ASSERT($IsObject(tRS))
		Set tSCMore=tRS.Initialize("SPArg"_pNum,..%Adapter,pHS,0,pNum)
		Set tMeth="ArgRS", tSC=tRS.GetSnapshot(.pValue,1)  If $$$ISERR(tSC) Set ..sqlcode=-400  Quit tSC
	} ElseIf (pType=$$$SqlTimestamp)!(pType=$$$SqlTypeTimestamp) {
		Set tMeth="Timestamp", pValue=..%JGProxy.stgetTimestamp(pHS,pNum)
	} Else { Set tMeth="String", pValue=..%JGProxy.stgetString(pHS,pNum) }
	If '..%JGProxy.wasError()  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway stget"_tMeth_"("_pHS_","_pNum_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method GetArgLOBData(pHS As %String, ByRef pColNum As %Integer, pIsBinary As %Boolean, Output pValue) As %Status
{
	Set tSC = $$$OK,tPos=0
	Set tMeth=$S(pIsBinary:"getArgBlob",1:"getArgClob")
	Set hLOB=$method(..%JGProxy,tMeth,pHS,pColNum)
	Set:""=hLOB hLOB=-1
	If -1=hLOB {
		Set pValue="", tTxt=..%JGProxy.getErrorText()
		If ""=tTxt||($C(0)=tTxt) Set ..sqlcode=100  Quit $$$OK ; no LOB means null
		Set ..sqlcode=-400, tTxt="JDBC Gateway "_tMeth_"("_pHS_","_pColNum_") error"_tTxt
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Set ..sqlcode = 1
	Set pValue = $S(pIsBinary:##class(%Stream.GlobalBinary).%New(),1:##class(%Stream.GlobalCharacter).%New())
	Set tMeth=$S(pIsBinary:"getArgBlobBytes",1:"getArgClobSubstr")
	While (..sqlcode=1) {
		Set tValueChunk=$method(..%JGProxy,tMeth,pHS,hLOB,tPos+1,..#LOBChunkSize)
		If tValueChunk="" {
			If ..%JGProxy.wasError() {
				Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText()  Set tTxt="JDBC Gateway "_tMeth_"("_pHS_","_hLOB_","_(tPos+1)_","_..#LOBChunkSize_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
				Set tSC=$$$ERROR($$$RemoteGatewayError,tTxt)
				Quit
			}
			If 'tPos Set tValueChunk=$C(0) ; first try is empty: $C(0) means empty string not null (not expected to happen because low level JDBC driver does this conversion already even though that's madness)
			#; Note that this means a legitimate 1-char CLOB stream containing Ascii NUL can't be distinguished from an empty non-null stream
		}
		Set ..sqlcode=$S(""=tValueChunk:100, $L(tValueChunk)<..#LOBChunkSize:0, 1:1)
		#; sqlcode=1 means $$$SqlSuccessWithInfo = "more data to get"
		Set tPos=tPos+$L(tValueChunk)
		Do pValue.Write(tValueChunk)
	}
	Do pValue.Rewind()
	Set ok=..%JGProxy.removeArgLob(pHS,hLOB)
	#;If the output parameter is a LOB then return as string if flag set and <= maxstring length
	#;Implemented for backward compatibility.
	If $G($$$EnsConfig("JDBC","LOBasString",..BusinessHost.%ConfigName),$G($$$EnsConfig("JDBC","LOBasString"),0)),pValue.Size <=$$$MaxLocalLength {
		Set tValue="" While 'pValue.AtEnd {Set tValue=tValue_pValue.Read()}
		Set pValue=tValue
	}
	Quit tSC
}

Method execQuery(pHS As %String) As %Status [ Internal ]
{
	Set tErr=..%JGProxy.execQuery(pHS)  If 'tErr Kill ..%rowcount(pHS)  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway execQuery("_pHS_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method execUpdate(pHS As %String) As %Status [ Internal ]
{
	Set tRowCount=..%JGProxy.execUpdate(pHS)  If tRowCount>=0 Kill ..%rowcount(pHS)  Set ..sqlcode=0, ..%rowcount(pHS)=tRowCount  Quit $$$OK
	Set tTxt=..%JGProxy.getErrorText()
	#;Account for DB2 -1 return when executing a call
	If ((tRowCount=-1)&&((""=tTxt)||($C(0)=tTxt))) Set ..%rowcount(pHS)=-1  Quit $$$OK
	Set ..sqlcode=-400,tTxt="JDBC Gateway execUpdate("_pHS_") error "_tRowCount_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method execProc(pHS As %String, Output pHasResultSet As %Boolean = 0) As %Status [ Internal ]
{
	Set pHasResultSet=..%JGProxy.execute(pHS)  Set:""=pHasResultSet pHasResultSet=-1  If -1=pHasResultSet {
		Set ..sqlcode=-400, pHasResultSet=0, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway SP execute("_pHS_") error "_pHasResultSet_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Kill ..%rowcount(pHS)
	While 'pHasResultSet {
		Set tUpdCount=..%JGProxy.getUpdateCount(pHS)  Set:""=tUpdCount tUpdCount=-1
		Quit:-1=tUpdCount ; proceed if no more Update Counts, otherwise save Update Count and try again
		Do addrowcount(pHS,tUpdCount)
		Set pHasResultSet=..%JGProxy.getMoreResults(pHS)  Set:""=pHasResultSet pHasResultSet=-1 ; proceed if there are Results (or error); otherwise try for another Update Count
	}
	If 'pHasResultSet||((-1'=pHasResultSet)&&(-1'=..%JGProxy.getResultSet(pHS))) Set ..sqlcode=0  Set:pHasResultSet ..%rowcount(pHS)=0  Quit $$$OK  ; start count for ResultSet if needed
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway SP execute "_$S(-1=pHasResultSet:"getMoreResults",1:"getResultSet")_"("_pHS_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt), pHasResultSet=0
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
addrowcount(hs,c)
	If '$D(..%rowcount(hs)) { Set ..%rowcount(hs)=c }
	Else { Set tI=1+$O(..%rowcount(hs,""),-1)  Set:tI=1 tI=2  Set ..%rowcount(hs,tI)=c }
}

Method MoreResults(pHS As %String) As %Status
{
	Do {
		Set tHasResultSet=..%JGProxy.getMoreResults(pHS)  Set:""=tHasResultSet tHasResultSet=-1
		Set tUpdCount=..%JGProxy.getUpdateCount(pHS)  Set:""=tUpdCount tUpdCount=-1  Do:-1'=tUpdCount addrowcount(pHS,tUpdCount)
	} While tHasResultSet'=1 && (tUpdCount'=-1)
	Set ..sqlcode=$Case(tHasResultSet, 0:100, -1:-400, :0)
	If '..sqlcode Set:-1=..%JGProxy.getResultSet(pHS) ..sqlcode=-400
	Do:'..sqlcode addrowcount(pHS,0) ; start count for ResultSet
	Quit:-400'=..sqlcode $$$OK
	Set tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway "_$S(-1=tHasResultSet:"getMoreResults",1:"getResultSet")_"("_pHS_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
addrowcount(hs,c)
	If '$D(..%rowcount(hs)) { Set ..%rowcount(hs)=c }
	Else { Set tI=1+$O(..%rowcount(hs,""),-1)  Set:tI=1 tI=2  Set ..%rowcount(hs,tI)=c }
}

Method GetLastSQLCode() As %Integer [ CodeMode = expression ]
{
..sqlcode
}

/// Return the last retrieved Update,Delete, or Stored Procedure row count values for the given statement handle
Method RowCount(pHS As %String = "", pIndex As %Integer = 1) As %Integer
{
	Quit $S(""=pHS:"",pIndex<=1:$G(..%rowcount(pHS)),1:$G(..%rowcount(pHS,pIndex)))
}

Method FetchAhead(hstmt, nSkip, nFetch) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Method Fetch(pHS As %String) As %Status
{
	Set tErr='..%JGProxy.next(pHS)
	Set ..sqlcode=tErr*100
	If 'tErr {
		Set tI=$O(..%rowcount(pHS,""),-1)
		If tI { Set ..%rowcount(pHS,tI)=..%rowcount(pHS,tI)+1 }
		Else { Set ..%rowcount(pHS)=$G(..%rowcount(pHS))+1 }
		Quit $$$OK
	}
	Quit:'..%JGProxy.wasError() $$$OK
	Set tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway Fetch() error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method GetDataW(pHS As %String, ByRef pColNum As %Integer, pType As %Integer, Output pValue) As %Status
{
	// This is for non-binary GetData only
	If pColNum'["." {
		Set pValue=..%JGProxy.getString(pHS,+pColNum)
		If pValue=""&&..%JGProxy.wasError() {
			Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway getString() error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
			Quit $$$ERROR($$$RemoteGatewayError,tTxt)
		}
		Set ..sqlcode=0, pColNum=pColNum_"."_$L(pValue)
		Quit $$$OK
	}
	#; a dot appended to pColNum signifies a LOB type
	Set hLOB=$P(pColNum,".",3), tPos=+$P(pColNum,".",2), pColNum=$P(pColNum,".")
	If ""=hLOB {
		If 'tPos {
			#; first time
			Set hLOB=..%JGProxy.getClob(pHS,pColNum)  Set:""=hLOB hLOB=-1
			If -1=hLOB {
				Set pValue="", tTxt=..%JGProxy.getErrorText()
				If ""=tTxt||($C(0)=tTxt) Set ..sqlcode=100  Quit $$$OK ; no LOB means null
				Set ..sqlcode=-400, tTxt="JDBC Gateway getClob("_pHS_","_pColNum_") error"_tTxt
				Quit $$$ERROR($$$RemoteGatewayError,tTxt)
			}
		} Else {
			#; Data is finished, return sqlcode 100
			Set ..sqlcode=100, pColNum=pColNum_"."_tPos
			Quit $$$OK
		}
	}
	Set pValue=..%JGProxy.getClobSubstr(pHS,hLOB,tPos+1,..#LOBChunkSize)
	If pValue="" {
		If ..%JGProxy.wasError() {
			Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText()  Set tTxt="JDBC Gateway getClobSubstr("_pHS_","_hLOB_","_(tPos+1)_","_..#LOBChunkSize_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
			Quit $$$ERROR($$$RemoteGatewayError,tTxt)
		}
		If 'tPos Set pValue=$C(0) ; first try is empty: $C(0) means empty string not null (not expected to happen because low level JDBC driver does this conversion already even though that's madness)
		#; Note that this means a legitimate 1-char CLOB stream containing Ascii NUL can't be distinguished from an empty non-null stream
	}
	Set ..sqlcode=$S(""=pValue:100, $L(pValue)<..#LOBChunkSize:0, 1:1)
	#; sqlcode=1 means $$$SqlSuccessWithInfo = "more data to get"
	Set:..sqlcode'=1 ok=..%JGProxy.removeLob(pHS,hLOB), hLOB=""
	Set tPos=tPos+$L(pValue), pColNum=pColNum_"."_tPos_"."_hLOB
	Quit $$$OK
}

Method GetData(pHS As %String, ByRef pColNum As %Integer, pType As %Integer, Output pValue) As %Status
{
	// This is for binary GetData only
	If pColNum'["." {
		Set pValue=..%JGProxy.getBinary(pHS,+pColNum)
		If pValue=""&&..%JGProxy.wasError() {
			Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway getString() error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
			Quit $$$ERROR($$$RemoteGatewayError,tTxt)
		}
		Set ..sqlcode=0, pColNum=pColNum_"."_$L(pValue)
		Quit $$$OK
	}
	#; a dot appended to pColNum signifies a LOB type
	Set hLOB=$P(pColNum,".",3), tPos=+$P(pColNum,".",2), pColNum=$P(pColNum,".")
	If ""=hLOB {
		If 'tPos {
			#; first time
			Set hLOB=..%JGProxy.getBlob(pHS,pColNum)  Set:""=hLOB hLOB=-1
			If -1=hLOB {
				Set pValue="", tTxt=..%JGProxy.getErrorText()
				If ""=tTxt||($C(0)=tTxt) Set ..sqlcode=100  Quit $$$OK ; no LOB means null
				Set ..sqlcode=-400, tTxt="JDBC Gateway getBlob("_pHS_","_pColNum_") error"_tTxt
				Quit $$$ERROR($$$RemoteGatewayError,tTxt)
			}
		} Else {
			#; Data is finished, return sqlcode 100
			Set ..sqlcode=100, pColNum=pColNum_"."_tPos
			Quit $$$OK
		}
	}
	Set pValue=..%JGProxy.getBlobBytes(pHS,hLOB,tPos+1,..#LOBChunkSize)
	If pValue="" {
		If ..%JGProxy.wasError() {
			Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText()  Set tTxt="JDBC Gateway getBlobBytes("_pHS_","_hLOB_","_(tPos+1)_","_..#LOBChunkSize_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
			Quit $$$ERROR($$$RemoteGatewayError,tTxt)
		}
		If 'tPos Set pValue=$C(0) ; first try is empty: $C(0) means empty string not null (not expected to happen because low level JDBC driver does this conversion already even though that's madness)
		#; Note that this means a legitimate 1-byte BLOB stream containing $C(0) can't be distinguished from an empty non-null stream
	}
	Set ..sqlcode=$S(""=pValue:100, $L(pValue)<..#LOBChunkSize:0, 1:1)
	#; sqlcode=1 means $$$SqlSuccessWithInfo = "more data to get"
	Set:..sqlcode'=1 ok=..%JGProxy.removeLob(pHS,hLOB), hLOB=""
	Set tPos=tPos+$L(pValue), pColNum=pColNum_"."_tPos_"."_hLOB
	Quit $$$OK
}

Method DropStatement(pHS As %String) As %Status
{
	Kill:""'=pHS ..%rowcount(pHS)
	Set tErr=..%JGProxy.removeStatement(pHS)  If 'tErr  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway removeStatement("_pHS_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method DropResultSet(pHS As %String) As %Status
{
	Set tErr=..%JGProxy.removeResultSet(pHS)  If 'tErr  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway removeResultSet("_pHS_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method GetErrorList(pHS As %String, Output errorlist As %List) As %Status
{
	Set tTxt=..%JGProxy.getErrorText()
	Set errorlist=$S(""=tTxt:"",1:$LB(tTxt))
	Quit $$$OK
}

Method SetConnectOption(opt, val) As %Status
{
	If opt=..#AutoCommit {
		Set tErr=..%JGProxy.setAutoCommit(..%ConnHandle,val)  If 'tErr  Set ..sqlcode=0  Quit $$$OK
	} Else {
		Quit $$$ERROR($$$NotImplemented,"SetConnectOption",opt, val)
	}
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway SetConnectOption ("_opt_","_val_") error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method SetStmtOption(pHS As %String, opt, val) As %Status
{
	Quit $$$ERROR($$$NotImplemented,"SetStmtOption",opt, val)
}

Method Transact(type) As %Status
{
	Set tErr=$S('type:..%JGProxy.commit(..%ConnHandle),1:..%JGProxy.rollback(..%ConnHandle))  If 'tErr  Set ..sqlcode=0  Quit $$$OK
	Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway "_$S('type:"commit",1:"rollback")_"() error "_tErr_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
	Quit $$$ERROR($$$RemoteGatewayError,tTxt)
}

Method DescribeColumns(pHS As %String, Output pColInfo As %List) As %Status
{
	Set nCols=..%JGProxy.columnCount(pHS), ..sqlcode=0
	If nCols=-1 {
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway columnCount("_pHS_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Set pColInfo=$LB($LB(+nCols,"Name","SqlType","Precision","Scale","Nullable","DataType","DisplaySize","IsMoney")) ; prepend headers row
	Set tSC=$$$OK  For i=1:1:nCols {
		Set tName=..%JGProxy.getColumnName(pHS,i)
		If '..%JGProxy.wasError() { Set tSqlType=..%JGProxy.getColumnType(pHS,i)
		If '..%JGProxy.wasError() { Set tPrecision=..%JGProxy.getPrecision(pHS,i)
		If '..%JGProxy.wasError() { Set tScale=..%JGProxy.getScale(pHS,i)
		If '..%JGProxy.wasError() { Set tNullable=..%JGProxy.isNullable(pHS,i)
		If '..%JGProxy.wasError() { Set tDataType=..%JGProxy.getColumnTypeName(pHS,i)
		If '..%JGProxy.wasError() { Set tDisplaySize=..%JGProxy.getColumnDisplaySize(pHS,i)
		If '..%JGProxy.wasError() { Set tIsMoney=..%JGProxy.isCurrency(pHS,i)
		If '..%JGProxy.wasError() {
			Set pColInfo=pColInfo_$LB($LB(tName,tSqlType,tPrecision,tScale,tNullable,tDataType,tDisplaySize,tIsMoney))
			Continue
		}}}}}}}}
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway getColumnXxx("_pHS_","_i_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Set tSC=$$$ERROR($$$RemoteGatewayError,tTxt)
		Quit
	}
	Quit tSC
}

Method DescribeParameters(pHS As %String, pParmDescs, pParms) As %Status
{
	Set nParms=..%JGProxy.getParameterCount(pHS), ..sqlcode=0
	If nParms=-1 {
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway getParameterCount("_pHS_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Quit $$$ERROR($$$RemoteGatewayError,tTxt)
	}
	Set pParmDescs=$LB($LB(+nParms,"Type","Prec","Scale","Nullable")) ; prepend headers row
	Set tSC=$$$OK  For i=1:1:nParms {
		Set tType=..%JGProxy.getParameterType(pHS,i)
		If '..%JGProxy.wasError() { Set tPrec=..%JGProxy.getParameterPrecision(pHS,i)
		If '..%JGProxy.wasError() { Set tScale=..%JGProxy.getParameterScale(pHS,i)
		If '..%JGProxy.wasError() { Set tNullable=..%JGProxy.isParameterNullable(pHS,i)
		If '..%JGProxy.wasError() {
			Set pParmDescs=pParmDescs_$LB($LB(tType,tPrec,tScale,tNullable))
			Continue
		}}}}
		Set ..sqlcode=-400, tTxt=..%JGProxy.getErrorText(), tTxt="JDBC Gateway getParameterXxx("_pHS_","_i_") error"_$S(""=tTxt||($C(0)=tTxt):"",1:": "_tTxt)
		Set tSC=$$$ERROR($$$RemoteGatewayError,tTxt)
		Quit
	}
	Quit tSC
}

Method putLOBStreamJ(pHS, pParamNum, pValue, pBin) As %Integer [ Internal ]
{
	Set temp=pValue  Set:$IsObject(pValue) temp=pValue.Read(16000)
	Set tErr=..%JGProxy.initStrCont(pHS)  Quit:tErr tErr
	While ""'=temp {
		If 'pBin { Set tErr=..%JGProxy.addString(pHS,temp) }
		Else { Set tErr=..%JGProxy.addByte(pHS,temp) }  Quit:tErr||'$IsObject(pValue)
		Set temp=pValue.Read(16000)
	} Quit:tErr tErr
	If 'pBin { Set tErr=..%JGProxy.setCharacterStream(pHS,pParamNum) }
	Else { Set tErr=..%JGProxy.setBinaryStream(pHS,pParamNum) }  Quit:tErr tErr
	Quit ..%JGProxy.rmStrCont(pHS)
}

/// Helper method to decide if a ResultSet if not a LOB
ClassMethod isaRS(pType As %Integer, pTypeName As %String) As %Boolean [ Internal ]
{
	Quit ((pType=$$$SqlWLongVarchar)!(pType=$$$SqlJOther)!(pType=$$$SqlJObject))&&(pTypeName'="FLOAT")&&(pTypeName'="NVARCHAR2")
}

Method deleteRuntimeAppData() [ Internal ]
{
	Try {
		If $Get($$$ConfigPoolSize(..BusinessHost.%ConfigName))'=1 Quit
		Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%QCols")		; used by EnsLib.SQL.GatewayResultSet
		Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%QParms")		; used by EnsLib.SQL.CommonJ and .Common
		Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"%ProcCols")	; used by EnsLib.SQL.Common
	} Catch {}
}

/// Examines if Connected to device pDevice.
/// Note if pDevice is not a TCP device then returns false.
Method isConnectedToDevice(pDevice As %String = "") As %Boolean [ Internal ]
{
	#dim tCurrentDevice As %String = $IO
	
	#; Default to not connected
	#dim tConnected As %Boolean = 0

	Try {
		Use pDevice
		Set tConnected = $SYSTEM.INetInfo.Connected()
	} Catch {}

	#;Restore entry device
	Use tCurrentDevice

	Return tConnected
}

}
