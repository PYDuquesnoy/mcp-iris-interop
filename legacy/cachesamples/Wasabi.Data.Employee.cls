Class Wasabi.Data.Employee Extends Wasabi.Data.Person
{

Property SSN As %String [ Required ];

Index SSNIndex On SSN [ Unique ];

Property Jobs As list Of Wasabi.Data.Job;

Property Manager As Wasabi.Data.Employee;

Property HireDate As %Date;

Property SeparationDate As %Date;

Property Location As Wasabi.Data.AddressPersistent;

Property Email As Wasabi.Common.DT.Email;

Property Active As %Boolean [ InitialExpression = 1 ];

Property Picture As %Stream.GlobalBinary;

ClassMethod GetOne(id As %String) As Wasabi.Person.API.Person
{

	
	
	try {
		set obj = ""
		set employee = ##class(Wasabi.Data.Employee).%OpenId(id,,.sc)
		$$$THROWONERROR(sc,sc)
	
		set obj = ##class(Wasabi.Person.API.Employee).%New()

		// super-class properties
		set obj.ID = id
		set obj.Addresses          = employee.Addresses
		set obj.DOB                = employee.DOB
		set obj.FirstName          = employee.FirstName
		set obj.Gender             = employee.Gender
		set obj.LastName           = employee.LastName
		set obj.MiddleInitial      = employee.MiddleInitial
		set obj.PhoneNumberSerials = employee.PhoneNumberSerials
		set obj.Suffix             = employee.Suffix
		set obj.Title              = employee.Title
		set obj.UserName           = employee.UserName
		set obj.Password           = employee.Password
		
		// sub-class properties
		set obj.SSN                = employee.SSN
		set obj.Manager            = employee.Manager
		set obj.HireDate           = employee.HireDate
		set obj.SeparationDate     = employee.SeparationDate
		Set obj.Location           = employee.Location
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
	quit obj
}

ClassMethod Add(employee As Wasabi.Person.API.Person)
{

		
	try {
		set sc = 0
		set obj = ##class(Wasabi.Data.Employee).%New()
		do obj.CopyFrom(employee)
		$$$THROWONERROR(status,obj.%Save())

		}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

ClassMethod Update(employee As Wasabi.Person.API.Person)
{

	
	
	try {		
		set obj = ##class(Wasabi.Data.Employee).%OpenId(employee.ID,,.sc)
		$$$THROWONERROR(status,sc)
		do obj.CopyFrom(employee)
		$$$THROWONERROR(status,obj.%Save())
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

Method CopyFrom(employee As Wasabi.Person.API.Employee)
{

		
		// super-class properties
		set ..Addresses          = employee.Addresses
		set ..DOB                = employee.DOB
		set ..FirstName          = employee.FirstName
		set ..Gender             = employee.Gender
		set ..LastName           = employee.LastName
		set ..MiddleInitial      = employee.MiddleInitial
		set ..PhoneNumberSerials = employee.PhoneNumberSerials
		set ..Suffix             = employee.Suffix
		set ..Title              = employee.Title
		set ..UserName           = employee.UserName
		 if ..Password          '= employee.Password 
				{
				  set ..Password = employee.Password
				}
		
		// sub-class properties
		set ..SSN                = employee.SSN
		set ..Jobs               = employee.Jobs
		set ..Manager            = employee.Manager
		set ..HireDate           = employee.HireDate
		set ..SeparationDate     = employee.SeparationDate
		set ..Location           = employee.Location
		set ..Email              = employee.Email
		set ..Active             = employee.Active
		set ..Picture            = employee.Picture
}

ClassMethod GetMatches(lastname As %String = "", firstname As %String = "") As %ResultSet.SQL
{

	
	try {
		set whereclause = ""
	
		set sql = "select lastname, firstname,dob,gender from wasabi_data.employee"
		if lastname '= "" {
			set whereclause = "lastname %startswith ?"
		}
	
		if firstname '= "" {
			if whereclause '= "" {
				set whereclause = whereclause _" and firstname %startswith ?"
			}
			else {
				set whereclause = "firstname %startswith ?"
			}
		}
	
		if whereclause '= "" {
			set sql = sql _" where "_whereclause 
		}
		set rs = ##class(%ResultSet.SQL).%Prepare(sql,.error,,lastname,firstname)
	
		if $isobject(error) {
			$$$THROWONERROR(status,error.Status)
		}
		
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex

	}
	
	
	quit rs
}

ClassMethod Terminate(employee As Wasabi.Person.API.Employee)
{

	
	
	
	try {
		set obj = ##class(Wasabi.Data.Employee).%OpenId(employee.ID,,.sc)
		$$$THROWONERROR(status,sc)
		
		Set obj.Active         = $$$NO
		Set obj.SeparationDate = employee.SeparationDate
		If obj.SeparationDate  = "" 
		   {
			   Set obj.SeparationDate = +$H
		   }
		$$$THROWONERROR(status,obj.%Save())
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

Storage Default
{
<Data name="EmployeeDefaultData">
<Subscript>"Employee"</Subscript>
<Value name="1">
<Value>SSN</Value>
</Value>
<Value name="2">
<Value>Jobs</Value>
</Value>
<Value name="3">
<Value>Manager</Value>
</Value>
<Value name="4">
<Value>HireDate</Value>
</Value>
<Value name="5">
<Value>SeparationDate</Value>
</Value>
<Value name="6">
<Value>Location</Value>
</Value>
<Value name="7">
<Value>Email</Value>
</Value>
<Value name="8">
<Value>Picture</Value>
</Value>
<Value name="9">
<Value>Active</Value>
</Value>
</Data>
<DefaultData>EmployeeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

