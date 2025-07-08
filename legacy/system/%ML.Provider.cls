/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// Base class for an ML provider
/// 
Class %ML.Provider Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Provider name
Parameter PROVIDERNAME As %String;

/// Default provider name
Parameter DEFAULTPROVIDER As %String = "AutoML";

/// Type of SQL TRAIN will operate on  Options are "resutset" or "query"
/// If the provider uses resultset, %Train is called with a resultset object for the query
/// If the provider uses query, %TrainQyert is called with the SQL query text
Parameter SQLTYPE As %String [ Constraint = "resultset,query", Flags = ENUM ] = "resultset";

/// 
/// Factory method to create an instance of an ML provider by name
/// 
ClassMethod %CreateProvider(name As %String = "", ByRef provider As %ML.Provider) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim class As %String

		If '..%GetProvider(name,.class) {
			Set status = $$$ERROR($$$MLUnknownProvider,name)
			Quit
		}

		Set provider = $CLASSMETHOD(class,"%New")
		Set status = provider.%OnInit()		

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Look up a provider proper name
/// 
ClassMethod %GetProvider(name As %String = "", ByRef class As %String) As %Boolean
{
	// We may choose to implement a registry of some sort ... but for now we just
	// use the provider name as a subpackage of the %ML package.
	Set:name="" name=..#DEFAULTPROVIDER

	Set class = $SELECT(name[".":name,1:"%ML."_name_".Provider")
	Set class = $LG($GET(^rINDEXCLASS($ZCVT(class,"U"))),2)	// case-correct
		
	Quit (##class(%Dictionary.CompiledClass).%ExistsId(class) && $$IsDerivedFrom^%occLibrary(class,$CLASSNAME()))
}

/// 
/// Returns the provider name (the class name by default)
/// 
Method %GetName() As %String
{
	Quit $SELECT(..#PROVIDERNAME'="":..#PROVIDERNAME,1:$CLASSNAME())
}

/// 
/// Returns an instance of %SQL.Statement to be used for the training query
/// 
Method %GetTrainStatement() As %SQL.Statement
{
	Quit ##class(%SQL.Statement).%New()
}

/// 
/// Adds the default settings for the provider to the settings dynamic object
/// 
ClassMethod %GetDefaultSettings(ByRef settings As %DynamicObject)
{
	RETURN  // no default settings
}

/// 
/// Make sure we clean up
/// 
Method %OnClose() As %Status
{
	Quit ..%OnExit()
}

/// 
/// Initialize a provider
/// 
Method %OnInit() As %Status
{
	Quit $$$OK
}

/// 
/// Shutdown a provider
/// 
Method %OnExit() As %Status
{
	Quit $$$OK
}

/// 
/// Train an ML model
/// 
Method %BeginTraining(model As %ML.Model, data As %SQL.StatementResult, trainingrun As %ML.TrainingRun, ByRef name As %String = "", ByRef trainkey) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

/// 
/// Check for training complete
/// 
Method %WaitForTraining(ByRef trainkey, trainingrun As %ML.TrainingRun, ByRef trainedmodel As %ML.TrainedModel, timeoutMS As %Integer = -1) As %Status [ Abstract ]
{
	Quit $$$ERROR($$$NotImplemented)
}

}
