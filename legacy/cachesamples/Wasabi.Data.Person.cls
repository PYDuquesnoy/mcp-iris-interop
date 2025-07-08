Class Wasabi.Data.Person Extends (%Persistent, Wasabi.Person.API.PersonUtils) [ Abstract, Inheritance = right ]
{

Property LastName As %String;

Property FirstName As %String;

Property MiddleInitial As %String;

Property DOB As %Date;

Property Title As %String;

Property Suffix As %String(VALUELIST = ",Jr.,Sr.,M.D.,Esq.,DDS");

Property Gender As %String(DISPLAYLIST = ",Male,Female", VALUELIST = ",1,2");

Property Age As %Integer [ Calculated, SqlComputeCode = {set {Age}=$h-{DOB}\365}, SqlComputed ];

Property FullName As %String [ Calculated, SqlComputeCode = {set {FullName}={FirstName}_" "_{LastName}}, SqlComputed ];

Property UserName As %String;

Property Password As %String;

Method PasswordSet(Arg As %String) As %Status
{
	set i%Password = $system.Encryption.MD5Hash(Arg)
	Quit $$$OK
}

//NOTE:  Wasabi.Person.Populate has a provision for classname Wasabi.Data.Address.  If this is the class name, it uses a ValueList

//of meaning key names for the array of addresses.  The drawback is that the populator will create a random number of addresses,

//and if the key already exists in the array, the array object gets saved but the person still has a maximum of the number of

//unique key names.  In other words, the address table will have more entries than the number of addresses for all person objects.

Property Addresses As list Of Wasabi.Data.AddressPersistent;

//(POPSPEC = "##class(Wasabi.Data.Person).PopAddress()");

Property PhoneNumberSerials As list Of Wasabi.Data.PhoneNumberSerial;

Index idxUserName On UserName [ Unique ];

ClassMethod CreateRandomAddress(ByRef addr As Wasabi.Data.AddressPersistent) As %Status
{
   s addr=##class(Wasabi.Data.AddressPersistent).%New()
   s addr.Street1=##class(%PopulateUtils).Street()
   s addr.Street2=##class(%PopulateUtils).ValueList(",,Suite 100,Dept 1A,Floor 789,,Dept 8C,C92-293,Sector 456,,,Mailroom")
   s addr.City=##class(%PopulateUtils).City()
   s addr.Region=##class(%PopulateUtils).USState()
   s addr.PostalCode=##class(%PopulateUtils).USZip()
   s addr.Country=##class(%PopulateUtils).ValueList(",CAN,USA")
   s addr.Type=##class(%PopulateUtils).ValueList(",Home,Shipping,Billing")
   q addr.%Save()
}

ClassMethod CreateRandomPhoneNumberSerial(ByRef ph As Wasabi.Data.PhoneNumberSerial) As %Status
{
	s ph=##class(Wasabi.Data.PhoneNumberSerial).%New()
	s ph.CountryCode="00"_($r(9)+1)
    s ph.PhoneNumberSerial=$r(8999999999)+1000000000
    s ph.Type=##class(%PopulateUtils).ValueList(",HOME,BUSINESS,CELL")
    s ph.Extension=##class(%PopulateUtils).Integer(1000,9999)
    q $$$OK
}

Storage Default
{
<Data name="Addresses">
<Attribute>Addresses</Attribute>
<Structure>subnode</Structure>
<Subscript>"Addresses"</Subscript>
</Data>
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>LastName</Value>
</Value>
<Value name="3">
<Value>FirstName</Value>
</Value>
<Value name="4">
<Value>MiddleInitial</Value>
</Value>
<Value name="5">
<Value>DOB</Value>
</Value>
<Value name="6">
<Value>Title</Value>
</Value>
<Value name="7">
<Value>Suffix</Value>
</Value>
<Value name="8">
<Value>Gender</Value>
</Value>
<Value name="9">
<Value>UserName</Value>
</Value>
<Value name="10">
<Value>Password</Value>
</Value>
<Value name="11">
<Value>PhoneNumberSerials</Value>
</Value>
</Data>
<DataLocation>^Wasabi.Data.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Wasabi.Data.PersonD</IdLocation>
<IndexLocation>^Wasabi.Data.PersonI</IndexLocation>
<StreamLocation>^Wasabi.Data.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

