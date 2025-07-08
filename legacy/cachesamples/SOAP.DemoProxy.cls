Class SOAP.DemoProxy Extends %SOAP.WebClient [ ProcedureBlock ]
{

/// This is the URL used to access the web service.
/// Change <I>localhost</I> to the web service machine's 
/// IP address to access this service.
Parameter LOCATION = "http://localhost/csp/samples/SOAP.Demo.cls";

/// Namespace. Change this to the namespace used by the web service.
Parameter NAMESPACE = "http://tempuri.org";

/// This is the name of the web service.
Parameter SERVICENAME = "SOAPDemo";

/// The list of reesponse SOAP headers that are supported by this web service client.
/// Each entry in the comma separated list is of the form "headerElement:headerClassname".
Parameter SOAPHEADERS = "ResponseInfo:SOAP.ResponseInfo,SubscriptionInfo:SOAP.SubscriptionInfo";

/// Use web service to add two integers and returns the result.
Method AddInteger(Arg1 As %Integer = 0, Arg2 As %Integer = 0) As %Integer [ WebMethod ]
{
	Quit ..WebMethod("AddInteger").Invoke(##this,"http://tempuri.org/SOAP.Demo.AddInteger",Arg1,Arg2)
}

/// Use web service to returns a corporate mission statement.
Method Mission() As %String [ WebMethod ]
{
	Quit ..WebMethod("Mission").Invoke(##this,"http://tempuri.org/SOAP.Demo.Mission")
}

/// Returns the city and state for the given U.S. ZIP Code
/// packaged within a <class>Sample.Address</class> object.
/// The request is sent from a registered user.
Method RegisteredLookupCity(zip As %String, user As %String, password As %String, ByRef remainingHits As %Integer)
{
	// Create registered user license header.
	Set licenseHeader = ##class(SOAP.LicenseInfo).%New()
	Set registered = ##class(SOAP.RegisteredUser).%New()
	Set registered.UserID = user
	Set registered.Password = password
	Set licenseHeader.RegisteredUser = registered
	Do ..HeadersOut.SetAt(licenseHeader,"LicenseInfo")

	// Make LookupCity request
	Set address = ..LookupCity(zip)
	
	// Evaluate response headers
	Set responseInfo = ..HeadersIn.GetAt("ResponseInfo")
	If (responseInfo = "") || (responseInfo.ResponseCode '= 0) {
		Quit ""
	}
	Set subscription = ..HeadersIn.GetAt("SubscriptionInfo")
	If subscription = "" Quit ""
	Set remainingHits = subscription.RemainingHits
	
	Quit address
}

/// Returns the city and state for the given U.S. ZIP Code
/// packaged within a <class>Sample.Address</class> object.
/// The request is sent from an unregistered user.
Method UnregisteredLookupCity(zip As %String, email As %String)
{
	// Create unregistered user license header.
	Set licenseHeader = ##class(SOAP.LicenseInfo).%New()
	Set unregistered = ##class(SOAP.UnregisteredUser).%New()
	Set unregistered.EmailAddress = email
	Set licenseHeader.UnregisteredUser = unregistered
	Do ..HeadersOut.SetAt(licenseHeader,"LicenseInfo")

	// Make LookupCity request
	Quit ..LookupCity(zip)
}

/// Returns the city and state for the given U.S. ZIP Code
/// packaged within a <class>Sample.Address</class> object.
Method LookupCity(zip As %String) As Sample.Address [ WebMethod ]
{
	Quit ..WebMethod("LookupCity").Invoke(##this,"http://tempuri.org/SOAP.Demo.LookupCity",zip)
}

/// Use web service to returns data about the person in the database with
/// object ID of <var>id</var>.
Method FindPerson(id As %String) As Sample.Person [ WebMethod ]
{
	Quit ..WebMethod("FindPerson").Invoke(##this,"http://tempuri.org/SOAP.Demo.FindPerson",id)
}

/// A sample web method to invoke dynamic SQL to query the Sample.Person class and
///    return the results as a .NET untyped DataSet
Method GetByName(name As %String) As %XML.DataSet [ WebMethod ]
{
	Quit ..WebMethod("GetByName").Invoke(##this,"http://tempuri.org/SOAP.Demo.GetByName",name)
}

/// A sample web method to invoke dynamic SQL to query the Sample.Person class and
/// return the results as a list of objects.
Method GetListByName(name As %String) As Sample.ListOfPersonIdentification [ WebMethod ]
{
	Quit ..WebMethod("GetListByName").Invoke(##this,"http://tempuri.org/SOAP.Demo.GetListByName",name)
}

/// A sample web method to invoke the ByName query of the Sample.Person class and
/// return the results as a .NET typed DataSet
Method GetDataSetByName(name As %String) As SOAP.ByNameDataSet [ WebMethod ]
{
	Quit ..WebMethod("GetDataSetByName").Invoke(##this,"http://tempuri.org/SOAP.Demo.GetDataSetByName",name)
}

/// A method to demonstrate using this proxy to act as a 
/// SOAP client to access our SOAP.Demo service.
ClassMethod DemoClient(zip As %String, id As %String) As %Boolean
{
	Set error=0
	Set $ztrap="ErrorTrap" ; handle client error ro SOAP fault.
	
	// Get the web service instance and the proxy class instance for the web service.
	Set proxy=##class(SOAP.DemoProxy).%New()
	Set service=##class(SOAP.Demo).%New()

	// Test AddInteger
	Set SOAPsum=proxy.AddInteger(23,76)
	Set sum=service.AddInteger(23,76)
	Write "AddInteger Test -- Expected sum = 99",!
	If SOAPsum=sum {
		If sum'=99 {
			Set error=1
			Write "    Unexpected sum = ",sum,!
		} Else {
			Write "    Sum = ",sum,!
		}
	} Else {
		Write "    Sums do not match",!
		Write "    Direct sum = ",sum,!
		Write "    SOAP sum = ",sum,!
	}

	// Test LookupCity
	Set SOAPcity=proxy.LookupCity(zip)
	Set city=service.LookupCity(zip)
	Write "LookupCity Test for zip = ",zip,!
	If (city.City=SOAPcity.City) && (city.State=SOAPcity.State) {
		Write "    SOAP and local calls agree.",!
		Write "    City = ",city.City,", State = ",city.State,!
	} Else {
		Write "    SOAP and local calls disagree.",!
		Write "    SOAP  -- City = ",SOAPcity.City,", State = ",SOAPcity.State,!
		Write "    Local -- City = ",city.City,", State = ",city.State,!
		Set error=1
	}
	
	// Test FindPerson
	Set SOAPperson=proxy.FindPerson(id)
	Set person=service.FindPerson(id)
	Write "FindPerson Test for id = ",id,!
	If ..comparePerson(SOAPperson,person) {
		Write "    SOAP and local calls agree.",!
		Do ..printPerson(person,"      ")
	} Else {
		Write "    SOAP and local calls disagree.",!
		Write "      Person returned via local call",!
		Do ..printPerson(person,"      ")
		Write "      Person returned via SOAP call",!
		Do ..printPerson(SOAPperson,"      ")
		Set error=1
	}

	// Test GetListByName
	Set SOAPlist=proxy.GetListByName("a")
	Set list=service.GetListByName("a")
	Write "GetListByName Test for name = a",!
	Set ok=1
	If SOAPlist.Count()'=list.Count() {
		Write "    SOAP and local calls disagree.",!
		Write "    SOAP count = ",SOAPlist.Count(),", local count = ",list.Count(),!
		Set ok=0
	}
	If ok=1 {
		For i=1:1:list.Count() {
			If '..comparePersonIdentification(SOAPlist.GetAt(i),list.GetAt(i)) {
				Set ok=0
				Quit
			}
		}
		If ok {
			Write "    SOAP and local calls agree.",!
		} Else {
			Write "    SOAP and local calls disagree.",!
		}
		For i=1:1:list.Count() {
			Write "    Local person ",i,!
			Do ..printPersonIdentification(list.GetAt(i))
			If 'ok {
				Write "    SOAP person ",i,!
				Do ..printPersonIdentification(SOAPlist.GetAt(i))
			}
		}
	}
	If 'ok Set error=1

	// Test GetByName
	Set SOAPresult=proxy.GetByName("a")
	Set result=service.GetByName("a")
	Write "GetByName Test for name = a",!
	Set ok=1
	If SOAPresult.GetColumnCount()'=result.GetColumnCount() {
		Write "    SOAP and local calls disagree.",!
		Write "    SOAP column count = ",SOAPresult.GetColumnCount(),", local column count = ",result.GetColumnCount(),!
		Set ok=0
	}
	Set status=$$$OK
	If ok=1 {
		For i=1:1:result.GetColumnCount() {
			If result.GetColumnName(i)'=SOAPresult.GetColumnName(i) {
				Set ok=0
				Write "    Column "_i_" name does not match, SOAP="_SOAPresult.GetColumnName(i)_", local="_result.GetColumnName(i),!
				Quit
			}
		}
	}
	If ok=1 {
		Set recnum=0
		While result.Next(.status) {
			Set recnum=recnum+1
			Write "    Record "_recnum,!
			If 'SOAPresult.Next() Set ok=0 Write "    Too few rows in SOAP result, SOAP="_SOAPresult.GetData(i)_", local="_result.GetData(i),! Quit
			For i=1:1:result.GetColumnCount() {
				Write "      "_result.GetColumnName(i)_" = "_result.GetData(i),!
				If result.GetData(i)'=SOAPresult.GetData(i) {
					Set ok=0
					Write "    Column "_i_" does not match",!
					Quit
				}
			}
			If 'ok Quit
		}
		If ok {
			Write "    SOAP and local calls agree.",!
		} Else {
			Write "    SOAP and local calls disagree.",!
		}
	}
	If $$$ISERR(status) Set ok=0 Do $system.OBJ.DisplayError(status)
	If SOAPresult.Next() Set ok=0 Write "Too many rows in SOAP result",!
	If 'ok Set error=1

	// Test GetDataSetByName
	Set SOAPresult=proxy.GetDataSetByName("a")
	Set result=service.GetDataSetByName("a")
	Write "GetDataSetByName Test for name = a",!
	Set ok=1
	If SOAPresult.GetColumnCount()'=result.GetColumnCount() {
		Write "    SOAP and local calls disagree.",!
		Write "    SOAP column count = ",SOAPresult.GetColumnCount(),", local column count = ",result.GetColumnCount(),!
		Set ok=0
	}
	Set status=$$$OK
	If ok=1 {
		For i=1:1:result.GetColumnCount() {
			If result.GetColumnName(i)'=SOAPresult.GetColumnName(i) {
				Set ok=0
				Write "    Column "_i_" name does not match, SOAP="_SOAPresult.GetColumnName(i)_", local="_result.GetColumnName(i),!
				Quit
			}
		}
	}
	If ok=1 {
		Set recnum=0
		While result.Next(.status) {
			Set recnum=recnum+1
			Write "    Record "_recnum,!
			If 'SOAPresult.Next() Set ok=0 Write "    Too few rows in SOAP result, SOAP="_SOAPresult.GetData(i)_", local="_result.GetData(i),! Quit
			For i=1:1:result.GetColumnCount() {
				Write "      "_result.GetColumnName(i)_" = "_result.GetData(i),!
				If result.GetData(i)'=SOAPresult.GetData(i) {
					Set ok=0
					Write "    Column "_i_" does not match",!
					Quit
				}
			}
			If 'ok Quit
		}
		If ok {
			Write "    SOAP and local calls agree.",!
		} Else {
			Write "    SOAP and local calls disagree.",!
		}
	}
	If $$$ISERR(status) Set ok=0 Do $system.OBJ.DisplayError(status)
	If SOAPresult.Next() Set ok=0 Write "Too many rows in SOAP result",!
	If 'ok Set error=1

	// Some missions
	Write "Our local mission is ",service.Mission(),!
	Write "Our SOAP mission is ",proxy.Mission(),!
	If error {
		Write !,"SOAP test failed",!
	} Else {
		Write !,"SOAP test succeeded",!
	}
	Quit error

ErrorTrap
	; Trap any error
	; If the trap was caused by ZTRAP "SOAP", then this is a SOAP error.
	;    The SOAP error $$$SOAPFaultReceived indicates that the server 
	;    returned the SOAP fault specified by the text.
	Set $ztrap=""
	If $ZE["<ZSOAP>" {
		Do $system.OBJ.DisplayError(%objlasterror)
	} else {
		Write "ERROR:  "_$ZE
	}
	Quit 1
}

ClassMethod comparePerson(p1 As Sample.Person, p2 As Sample.Person) As %Boolean
{
	If p1.Name '= p2.Name Quit 0
	If p1.SSN '= p2.SSN Quit 0
	If p1.DOB '= p2.DOB Quit 0
	If '..compareAddress(p1.Home,p2.Home) Quit 0
	If '..compareAddress(p1.Office,p2.Office) Quit 0
	
	Set match=1
	If p1.FavoriteColors.Count() '= p2.FavoriteColors.Count() Quit 0
	For i=1:1:p1.FavoriteColors.Count() {
		If p1.FavoriteColors.GetAt(i) '= p2.FavoriteColors.GetAt(i) Set match=0 Quit
	}
	
	Quit match
}

ClassMethod printPerson(p As Sample.Person, indent As %String)
{
	Write indent,"Name = ",p.Name,!
	Write indent,"SSN = ",p.SSN,!
	Write indent,"DOB = ",$zdate(p.DOB),!
	Write indent,"Home = ",!
	Do ..printAddress(p.Home,indent_"   ")
	Write indent,"Office = ",!
	Do ..printAddress(p.Office,indent_"   ")
	If p.FavoriteColors.Count() '= 0 {
		Write indent,"FavoriteColors",!
		For i=1:1:p.FavoriteColors.Count() {
			Write indent,"   ",p.FavoriteColors.GetAt(i),!
		}
	}
}

ClassMethod compareAddress(a1 As Sample.Address, a2 As Sample.Address) As %Boolean
{
	If a1.Street '= a2.Street Quit 0
	If a1.City '= a2.City Quit 0
	If a1.State '= a2.State Quit 0
	If a1.Zip '= a2.Zip Quit 0
	Quit 1
}

ClassMethod printAddress(a As Sample.Address, indent As %String)
{
	Write indent,"Street = ",a.Street,!
	Write indent,"City = ",a.City,!
	Write indent,"State = ",a.State,!
	Write indent,"Zip = ",a.Zip,!
}

ClassMethod comparePersonIdentification(p1 As Sample.PersonIdentification, p2 As Sample.PersonIdentification) As %Boolean
{
	If p1.ID '= p2.ID Quit 0
	If p1.Name '= p2.Name Quit 0
	If p1.SSN '= p2.SSN Quit 0
	If p1.DOB '= p2.DOB Quit 0
	Quit 1
}

ClassMethod printPersonIdentification(p As Sample.PersonIdentification, indent As %String = "      ")
{
	Write indent,"ID = ",p.ID,!
	Write indent,"Name = ",p.Name,!
	Write indent,"SSN = ",p.SSN,!
	Write indent,"DOB = ",$zdate(p.DOB),!
}

}

