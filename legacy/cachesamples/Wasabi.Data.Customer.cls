Class Wasabi.Data.Customer Extends Wasabi.Data.Person
{

Property CustomerNumber As %Integer [ Required ];

Index CustomerNumberIndex On CustomerNumber [ Unique ];

Property CompanyName As %String;

Property ContactEmailAddress As Wasabi.Common.DT.Email;

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	s ..ContactEmailAddress=..FirstName_..LastName_"@"_$p(##class(%Library.PopulateUtils).Syllable()," ",1)_##class(%PopulateUtils).ValueList(",.com,.net,.org")
	Quit $$$OK
}

ClassMethod GetOne(id As %String) As Wasabi.Person.API.Person
{

	
	try {
		set obj = ""
		set cust = ##class(Wasabi.Data.Customer).%OpenId(id,,.sc)
		$$$THROWONERROR(sc,sc)
		set obj = ##class(Wasabi.Person.API.Customer).%New()
		set obj.ID = id
		set obj.CompanyName = cust.CompanyName
		set obj.Addresses = cust.Addresses
		set obj.ContactEmailAddress = cust.ContactEmailAddress
		set obj.CustomerNumber = cust.CustomerNumber
		set obj.DOB = cust.DOB
		set obj.FirstName = cust.FirstName
		set obj.Gender = cust.Gender
		set obj.LastName = cust.LastName
		set obj.MiddleInitial = cust.MiddleInitial
		set obj.PhoneNumberSerials = cust.PhoneNumberSerials
		set obj.Suffix = cust.Suffix
		set obj.Title = cust.Title
		set obj.UserName = cust.UserName
		set obj.Password = cust.Password
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
	quit obj
}

ClassMethod Add(cust As Wasabi.Person.API.Person)
{

	
	try {
		set sc = 0
		set obj = ##class(Customer).%New()
		do obj.CopyFrom(cust)
		$$$THROWONERROR(status,obj.%Save())
		}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

ClassMethod Update(cust As Wasabi.Person.API.Person)
{

	
	
	try {		
		set obj = ##class(Wasabi.Data.Customer).%OpenId(cust.ID,,.sc)
		$$$THROWONERROR(status,sc)
		do obj.CopyFrom(cust)
		$$$THROWONERROR(status,obj.%Save())
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

Method CopyFrom(cust As Wasabi.Person.API.Customer)
{

		
		
		set ..Addresses = cust.Addresses
		set ..CompanyName = cust.CompanyName
		set ..ContactEmailAddress = cust.ContactEmailAddress
		set ..CustomerNumber = cust.CustomerNumber
		set ..DOB = cust.DOB
		set ..FirstName = cust.FirstName
		set ..Gender = cust.Gender
		set ..LastName = cust.LastName
		set ..MiddleInitial = cust.MiddleInitial
		set ..PhoneNumberSerials = cust.PhoneNumberSerials
		set ..Suffix = cust.Suffix
		set ..Title = cust.Title
		set ..UserName = cust.UserName
		if ..Password '= cust.Password {
			set ..Password = cust.Password
		}
}

ClassMethod GetMatches(lastname As %String = "", firstname As %String = "") As %ResultSet.SQL
{
	
	try {
		set whereclause = ""
	
		set sql = "select lastname, firstname,dob,gender from wasabi_data.customer"
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

Storage Default
{
<Data name="CustomerDefaultData">
<Subscript>"Customer"</Subscript>
<Value name="1">
<Value>CustomerNumber</Value>
</Value>
<Value name="2">
<Value>CompanyName</Value>
</Value>
<Value name="3">
<Value>ContactEmailAddress</Value>
</Value>
</Data>
<DefaultData>CustomerDefaultData</DefaultData>
<Property name="Age"/>
<Property name="CompanyName"/>
<Property name="ContactEmailAddress"/>
<Property name="CustomerNumber"/>
<Property name="DOB"/>
<Property name="FirstName"/>
<Property name="FullName"/>
<Property name="Gender"/>
<Property name="LastName"/>
<Property name="MiddleInitial"/>
<Property name="Password"/>
<Property name="PhoneNumberSerials"/>
<Property name="Suffix"/>
<Property name="Title"/>
<Property name="UserName"/>
<Type>%Storage.Persistent</Type>
}

}

