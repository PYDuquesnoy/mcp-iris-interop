Import Sample

Include %soap

/// A simple demonstration Web Service<BR>
/// To try this, visit
/// <A href="/csp/samples/SOAP.Demo.cls">/csp/samples/SOAP.Demo.cls</A>
/// This web service inherits from the SOAP.BaseService sample class 
///  to pickup common error handling.
Class SOAP.Demo Extends SOAP.BaseService [ ProcedureBlock ]
{

// The LOCATION parameter is no longer required, since it now defaults to the path used to request the WSDL. 

/// Namespace. Change this to your own namespace when you deploy a service.
Parameter NAMESPACE = "http://tempuri.org";

/// This is the name of our web service.
Parameter SERVICENAME = "SOAPDemo";

/// The list of request SOAP headers that are supported by this web service.
/// Each entry in the comma separated list is of the form "headerElement:headerClassname".
Parameter SOAPHEADERS = "LicenseInfo:SOAP.LicenseInfo";

/// Adds two integers and returns the result.
Method AddInteger(Arg1 As %Integer, Arg2 As %Integer) As %Integer [ WebMethod ]
{
	Quit Arg1 + Arg2
}

Method DivideInteger(Arg1 As %Integer, Arg2 As %Integer) As %Integer [ WebMethod ]
{
	// The fault for division by 0 will be trapped and adjusted by SOAP.BaseService.
	Quit Arg1/Arg2
}

/// Returns a corporate mission statement.
Method Mission() As %String [ WebMethod ]
{
	Quit ##class(%PopulateUtils).Mission()
}

/// Returns the city and state for the given U.S. ZIP Code
/// packaged within a <class>Sample.Address</class> object.
Method LookupCity(zip As %String) As Sample.Address [ WebMethod ]
{
	// Error check that zip code is required.
	If $get(zip)="" {
		// Application specific fault generator from SOAP.BaseService sample.
		Do ..ApplicationError($$$FAULTClient,"Zip code not specified")
	}
	
	// Get LicenseInfo SOAP header and validate it if present.
	Set license = ..HeadersIn.GetAt("LicenseInfo")
	If license '= "" {
		// If any license information return ResponseInfo header
		Set response = ##class(SOAP.ResponseInfo).%New()
		Set response.ResponseCode = 0
		Set response.Response = "City returned"
		Do ..HeadersOut.SetAt(response,"ResponseInfo")

		// If registered user return SubscriptionInfoHeader
		Set registered = license.RegisteredUser
		If registered '= "" {
			Set subscription = ##class(SubscriptionInfo).%New()
			Set subscription.LicenseStatusCode = 0
			Set subscription.LicenseStatus = "Registered user: "_registered.UserID
			Set subscription.LicenseActionCode = 0
			Set subscription.LicenseAction = "Request Executed"
			Set subscription.RemainingHits = 99
			Set subscription.Amount = 0.0
			Do ..HeadersOut.SetAt(subscription,"SubscriptionInfo")
		}
	}

	// create an Address object to hold the result
	Set obj = ##class(Sample.Address).%New()

	// Use embedded SQL to perform the lookup
	&sql(SELECT City,State INTO :city, :state
			FROM Sample.USZipCode
			WHERE ZipCode = :zip )
			
	If (SQLCODE = 0) {
		// success			
		Set obj.City = city
		Set obj.State = state
		Set obj.Zip = zip
	}
	Else {
		// Application specific fault generator from SOAP.BaseService sample.
		Do ..ApplicationError($$$FAULTClient,"Zip code not found: "_zip)
	}

	Quit obj
}

/// Returns data about the person in the database with
/// object ID of <var>id</var>.
Method FindPerson(id As %String) As Sample.Person [ WebMethod ]
{
	// Return an instance of person.  Null is returned for invalid id.
	Quit ##class(Sample.Person).%OpenId(id)
}

/// A sample web method to invoke dynamic SQL to query the Sample.Person class and
///    return the results as a .NET untyped DataSet
Method GetByName(name As %String) As %XML.DataSet [ WebMethod ]
{
 ; Return the results of the Person class' by name.
 Set result=##class(%XML.DataSet).%New()
 Set status=result.Prepare("SELECT ID, Name, DOB, SSN FROM Sample.Person WHERE Name %STARTSWITH ? ORDER BY Name")
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)
 Set result.DataSetName="ListByName"
 Set status=result.Execute(name)
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)
 Quit result
}

/// A sample web method to invoke dynamic SQL to query the Sample.Person class and
/// return the results as a list of objects.
Method GetListByName(name As %String) As Sample.ListOfPersonIdentification [ WebMethod ]
{
 ; Create a result set for the Person class' by name.
 Set result=##class(%ResultSet).%New()
 Set status=result.Prepare("SELECT ID, Name, DOB, SSN FROM Sample.Person WHERE Name %STARTSWITH ? ORDER BY Name")
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)
 Set status=result.Execute(name)
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)

 ; Create a list of objects for the rows and populate the list.
 Set list=##class(Sample.ListOfPersonIdentification).%New()
 While result.Next(.status) {
	Set obj=##class(Sample.PersonIdentification).%New()
	Set obj.ID=result.Get("ID")
	Set obj.Name=result.Get("Name")
	Set obj.DOB=result.Get("DOB")
	Set obj.SSN=result.Get("SSN")
	Do list.Insert(obj)
 }
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)

 ; Return the list of objects.
 Quit list
}

/// A sample web method to invoke the ByName query of the Sample.Person class and
/// return the results as a .NET typed DataSet
Method GetDataSetByName(name As %String) As SOAP.ByNameDataSet [ WebMethod ]
{
 ; Return the results of the Person class' ByName query.
 Set result=##class(SOAP.ByNameDataSet).%New()
 Set status=result.Execute(name)
 If $$$ISERR(status) Do ..StatusError($$$FAULTServer,status)
 Quit result
}

/// A sample class query as a WebMethod that defines a typed dataset that returns Person data 
/// ordered by <property>Name</property>.<br>
/// This query also generates a WebMethod of the same name that may be called using SOAP
/// in order to return a typed .Net DataSet.
Query QueryByName(name As %String) As %SQLQuery(CONTAINID = 1, SELECTMODE = "RUNTIME") [ WebMethod ]
{
 SELECT ID, Name, DOB, SSN
 FROM Sample.Person
 WHERE (Name %STARTSWITH :name)
 ORDER BY Name
}

}

