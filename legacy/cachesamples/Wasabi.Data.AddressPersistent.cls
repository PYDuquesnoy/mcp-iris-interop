Class Wasabi.Data.AddressPersistent Extends (%Persistent, Wasabi.Data.Address) [ Inheritance = right ]
{

ClassMethod GetOne(id As %String) As Wasabi.Data.Address
{

		
	try {
		set source = ##class(Wasabi.Data.AddressPersistent).%OpenId(id,,.sc)
		$$$THROWONERROR(status,sc)
		set target = ##class(Wasabi.Person.API.Address).%New()
		set target.ID = id
		set target.City = source.City
		set target.Country = source.Country
		set target.Street1 = source.Street1
		set target.Street2 = source.Street2
		set target.PostalCode = source.PostalCode
		set target.Region = source.Region
		set target.Type = source.Type
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
	quit target
}

ClassMethod Add(addr As Wasabi.Person.API.Address)
{

	
	try {
		set target = ##class(Wasabi.Data.AddressPersistent).%New()
		do target.CopyFrom(addr)
		$$$THROWONERROR(status,target.%Save())
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex

	}
}

ClassMethod Update(addr As Wasabi.Person.API.Address)
{

	
	try {
		set target = ##class(Wasabi.Data.AddressPersistent).%OpenId(addr.ID,,.status)
		$$$THROWONERROR(status,status)
		do target.CopyFrom(addr)
		$$$THROWONERROR(status,target.%Save())
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
}

ClassMethod GetMatches(city As %String = "", region As %String = "") As %ResultSet.SQL
{


	try {
		set whereclause = ""
	
		set sql = "select city, region, street1, street2 from wasabi_data.addresspersistent"
		if city '= "" {
			set whereclause = "city %startswith ?"
		}
	
		if region '= "" {
			if whereclause '= "" {
				set whereclause = whereclause _" and region %startswith ?"
			}
			else {
				set whereclause = "region %startswith ?"
			}
		}
	
		if whereclause '= "" {
			set sql = sql _" where "_whereclause 
		}
	
		set rs = ##class(%ResultSet.SQL).%Prepare(sql,.error,,city,region)
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
<Data name="AddressPersistentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Street1</Value>
</Value>
<Value name="4">
<Value>Street2</Value>
</Value>
<Value name="5">
<Value>City</Value>
</Value>
<Value name="6">
<Value>Region</Value>
</Value>
<Value name="7">
<Value>Country</Value>
</Value>
<Value name="8">
<Value>PostalCode</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.AddressPersDE4AD</DataLocation>
<DefaultData>AddressPersistentDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.AddressPersDE4AD</IdLocation>
<IndexLocation>^Wasabi.Data.AddressPersDE4AI</IndexLocation>
<Property name="City"/>
<Property name="Country"/>
<Property name="PostalCode"/>
<Property name="Region"/>
<Property name="Street1"/>
<Property name="Street2"/>
<Property name="Type"/>
<StreamLocation>^Wasabi.Data.AddressPersDE4AS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

