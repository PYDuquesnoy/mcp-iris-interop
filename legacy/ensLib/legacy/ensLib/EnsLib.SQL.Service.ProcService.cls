/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Service polls a specified SQL Procedure and processes any output parameters so that they can be set as the values of the properties
/// for some message class or inserted into a json string to be sent to the Target Configuration Items. </br>
/// The Service is meant only for use with Function type Procedures.  For Query type Procedures, use EnsLib.SQL.Service.GenericService.
Class EnsLib.SQL.Service.ProcService Extends EnsLib.SQL.Service.GenericService [ Language = objectscript ]
{

Parameter ADAPTER = "EnsLib.SQL.InboundProcAdapter";

Property Adapter As EnsLib.SQL.InboundProcAdapter;

/* Overridden just to include Output Parameters */
/// Message class to use in generating the request message. If this is set and the query has any output parameters,
/// then a request message of this class will be created and the values from the output parameters and from the query results
/// will be set into the corresponding properties of the request object. The <parameter>OutputParamNames</parameter> setting must be used in order to 
/// pair the output parameters with properties of the message class.
/// If no <parameter>MessageClass</parameter> is specified, then the request message will take the form of an Ens.StreamContainer message
/// containing a json string with any output parameter values as well as the query results (eg. {"ID":"1","Name":"John Smith"})</br>
Property MessageClass As %String(MAXLEN = 1000);

}
