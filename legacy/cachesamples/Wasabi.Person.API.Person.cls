Class Wasabi.Person.API.Person Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right ]
{

Property ID As %String;

Property LastName As %String;

Property FirstName As %String;

Property MiddleInitial As %String;

Property DOB As %Date;

Property Title As %String;

Property Suffix As %String(VALUELIST = ",Jr.,Sr.,M.D.,Esq.,DDS");

Property Gender As %String(DISPLAYLIST = ",Male,Female", VALUELIST = ",1,2");

Property FullName As %String [ Calculated, SqlComputeCode = {set {FullName}={FirstName}_" "_{LastName}}, SqlComputed ];

Property UserName As %String;

Property Password As %String;

Property Addresses As list Of Wasabi.Data.AddressPersistent;

Property PhoneNumberSerials As list Of Wasabi.Data.PhoneNumberSerial;

}

