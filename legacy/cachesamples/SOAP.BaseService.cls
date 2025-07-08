/// SOAP.BaseService is the base class for all sample web services.
/// SOAP.BaseService illustrates moving error handling for all 
/// services into a common base class.
/// Currently SOAP.Demo is the only sample web service.
Class SOAP.BaseService Extends %SOAP.WebService [ Abstract, ProcedureBlock ]
{

/// Namespace.
/// Each web service needs to supply this parameter.
Parameter NAMESPACE = "http://tempuri.org";

/// This is the name of our web service.
/// Each web service needs to supply this parameter.
Parameter SERVICENAME = "SOAPBase";

/// Override to fix the fault for our needs.
/// The OnInternalFault method will be called for all internal Cache errors
/// after the default Cache fault has been created.
ClassMethod OnInternalFault(fault As %SOAP.Fault, status As %Status) [ ServerOnly = 1 ]
{
	Do $system.Status.DecomposeStatus(status,.err)
	Set detail=$c(13,10)_"    <error xmlns='"_..Namespace()_"' >"_$c(13,10)
	Set detail=detail_"<special>Internal error detected.</special>"
	Set detail=detail_"     <text>"_$ZConvert(err(1),"O","HTML")_"</text>"_$c(13,10)
	Set detail=detail_"    </error>"_$c(13,10)
	Set fault.detail=detail
	Set fault.faultstring="Sample Web Service error"
	Quit
}

/// Create our own method to produce application specific SOAP faults.
ClassMethod ApplicationError(code As %String, error As %String, detail As %String = "")
{
	set fault=##class(%SOAP.Fault).%New()
	set fault.faultcode=code
	set fault.detail=detail
	set fault.faultstring=error
	// ReturnFault must be called to send the fault to the client.
	// ReturnFault will not return here.
	do ..ReturnFault(fault)
}

/// Application specific error based on status code
ClassMethod StatusError(code As %String, status As %Status)
{
	Do $system.Status.DecomposeStatus(status,.err)
	Do ..ApplicationError(code,"application error",err(1))
}

}

