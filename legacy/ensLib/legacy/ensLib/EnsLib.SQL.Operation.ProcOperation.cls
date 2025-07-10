/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Operation calls out to a SQL Procedure and generates its response message based on any output parameters returned by the procedure.
/// This Operation should only be used for Function type Procedures.  For Query type Procedures, use EnsLib.SQL.Operation.GenericOperation.
Class EnsLib.SQL.Operation.ProcOperation Extends EnsLib.SQL.Operation.GenericOperation [ Language = objectscript ]
{

/// A text string in which each character corresponds to one of the query parameters. The character 'i' means the
/// corresponding parameter is an Input parameter. The character 'o' means it is an Output parameter, and 'b' means it is Both an Input
/// and an Output parameter. If the procedure is a function which has a return value, an 'o' should be added in front to account for the return value.
Property IO As %String;

/// A comma-separated list of the SQL data types of each parameter used in the query (eg. SQL_CHAR,SQL_INTEGER).
/// This list should include both input and output parameters.
/// This may be required for the query to execute successfully if the datatype are not SQL_VARCHAR (the default used when unspecified)
Property ParamSQLTypes As %String(MAXLEN = "");

/// The name of the procedure to be called by this Operation.  This should include any ? characters used to indicate parameters of the procedure, but
/// should not include any SQL commands (eg. Select) with the exception that the CALL command must be included if ?= is used.<br>
/// Specifying  preceding ?=CALL is optional if the procedure provides a RETURN (Note the Input/Output Setting must include the leading o for the return.)<br>
///  For example the following are valid:<br><br>
///  schema.proc(?,?) with Input/Output of oii - this will result in ? = CALL schema.proc(?,?) <br>
///  schema.proc(?,?) with Input/Output of ii - this will result in CALL schema.proc(?,?) <br>
///  ? = CALL schema.proc(?,?) with Input/Output of oii - this will result in ? = CALL schema.proc(?,?)<br>
///  CALL schema.proc(?,?) with Input/Output of ii - this will result in CALL schema.proc(?,?) <br>
Property Procedure As %String(MAXLEN = "");

/// A comma-separated list of property names corresponding to any output parameters of the procedure.
/// Each parameter with an IO type of either 'o' or 'b' should have a name specified if this Operation will be generating a response message.
Property OutputParamNames As %String(MAXLEN = "");

/* Overridden just to include Output Parameters */
/// Message class to use in generating the response object. If this is set and the query has any output parameters,
/// then a response object of this class will be created and the values from the output parameters
/// will be set into the corresponding properties of the response object. The <property>OutputParamNames</property> setting must be used in order to 
/// pair the output parameters with properties of the message class.
/// If no <property>ResponseClass</property> is specified, then the response object will take the form of an Ens.StreamContainer message with the Stream property
/// containing a json string with any output parameter values.
Property ResponseClass As %String(MAXLEN = 1000);

/* Overridden just to include Output Parameters */
/// Limit warnings about multiple returned rows and truncated data.</br>
/// Give a warning the first time that a call to this Operation returns multiple rows, but do not repeat the warning if any subsequent calls also return multiple rows.
/// Likewise, give one warning per column or output parameter if <property>AllowTruncating</property> is true and returned values must be truncated. </br>
/// This is only relevant when <property>ResponseClass</property> is set because these warning are not issued for json response messages.
Property OnlyWarnOnce As %Boolean [ InitialExpression = 1 ];

/// JDBC escape call syntax requires the statement to be wrapped in {}
Property EscapedCallRequiresBracing As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "-Query,Procedure:Data,InputParameters:Data:sqlParametersTable?querySetting=HostProcedure&classSettingName=HostRequestClass&prependAsterix=1,IO:Data,ParamSQLTypes:Data,OutputParamNames:Data:sqlParametersTable?querySetting=HostProcedure&classSettingName=HostResponseClass,EscapedCallRequiresBracing:Data";

Method OnInit() As %Status
{
	If ""=..Procedure {
		Quit $$$ERROR($$$EnsErrGeneral,"No procedure specified")
	} Else {
		Set ..IO = $zcvt(..IO,"l")

		/* Prepend appropriate CALL if needed - if starts with { do not check. */
		Set tProcedureUpper = $zcvt($zstrip(..Procedure,"*W"),"U")
		If ($extract(tProcedureUpper)'="{")&&($extract(tProcedureUpper,1,6)'="?=CALL")&&($extract(tProcedureUpper,1,4)'="CALL") {
			If ("o"=$E(..IO)) && ($L(..IO)>=($L(..Procedure,"?"))) {
				Set ..Query = "? = CALL "_..Procedure
			} Else {
				Set ..Query = "CALL "_..Procedure
			}
		} Else {
			Set ..Query = ..Procedure
		}
		#; Wrap the query in {} if requested
		If ..EscapedCallRequiresBracing && ($extract(tProcedureUpper)'="{") {
			Set ..Query = "{" _ ..Query _ "}"
		}

		If ($L(..IO)<($L(..Procedure,"?")-1)) {
			$$$LOGWARNING($$$Text("Must specify whether each parameter is input or output in the Input/Output setting"))
		} ElseIf $Translate($zcvt(..IO,"l"),"iob*#","")'="" {
			$$$LOGWARNING($$$Text("Input/Output setting should be a string consisting only of the characters 'i', 'o' and 'b'"))
		}
		
		If ..Query'["?" {
			$$$LOGINFO($$$Text("This procedure does not return output parameters"))
		}
		
	}
	
	Quit ##super()
}

Method OnMessage(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tRequest As %RegisteredObject
	#dim tJSON, tInputParms As %String = ""
	#dim tOutputParms As %ListOfDataTypes
	#dim tSnapshots As %ListOfObjects
	#dim ex As %Exception.AbstractException
	
	Try {
		
		#; ExecuteProcedureParmArray does not work if the procedure has neither input nor output parameters
		If ..Query'["?" {
			Set tSC=..Adapter.ExecuteUpdate(,..Query)
			Quit
		}

		Set tSC = ..getObjectFromRequest(pRequest,.tRequest)	Quit:$$$ISERR(tSC)

		Set:(..InputParameters'="") tSC = ..getParms(.tInputParms,.tRequest,..IO,..ParamSQLTypes)	Quit:$$$ISERR(tSC)

		Set tSC = ..Adapter.ExecuteProcedureParmArray(.tSnapshots,.tOutputParms,..Query,..IO,.tInputParms)
		Quit:$$$ISERR(tSC)

		Set tSC = ..ProcessProcedureResponse(tSnapshots,tOutputParms,..OutputParamNames,.pResponse)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
