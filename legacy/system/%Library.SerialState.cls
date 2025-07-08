/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Serial object interface
Class %Library.SerialState [ Abstract, Not ProcedureBlock, System = 2 ]
{

Parameter SERIALDELIMITER;

Parameter ODBCDELIMITER = ",";

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.CustomSerial";

/// STORAGEINTERFACE defines the type of serialization implemented by this class.
/// The value has to match the classtype of the class that is inheriting the serialization
/// interface.
Parameter STORAGEINTERFACE As STRING [ Constraint = ",persistent,serial", Flags = ENUM ] = "serial";

/// 	Get Serialized State. %GetSerial() can assume that the ID values have already been
/// 	reset for swizzled references since %Oid has already called %ResetAllObject()
Method %GetSerial(force As %Integer = 0) As %String [ Private, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%SerialState::%GetSerial")
}

/// 	Set Serialized State.
Method %SetSerial(val As %String) As %Status [ Private, ServerOnly = 1 ]
{
	QUIT $$$ERROR($$$MethodNotImplemented,"%SerialState::%SetSerial")
}

/// 	LogicalToOdbc()
/// 		Construct a string delimited by ODBCDELIMITER from an object's serialized state.
ClassMethod LogicalToOdbc(%val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	Quit ##class(%Compiler.Storage.Generator.Serial).LogicalToOdbc(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

ClassMethod OdbcToLogical(%val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	Quit ##class(%Compiler.Storage.Generator.Serial).OdbcToLogical(.%mode,.%class,.%property,.%method,.%parameter,.%codemode,.%code,.%classmodify,.%context)
}

}
