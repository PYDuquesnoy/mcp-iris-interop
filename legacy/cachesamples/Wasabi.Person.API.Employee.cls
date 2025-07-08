Class Wasabi.Person.API.Employee Extends Wasabi.Person.API.Person
{

Property SSN As %String;

Property Jobs As list Of Wasabi.Data.Job;

Property Manager As Wasabi.Data.Employee;

Property HireDate As %Date;

Property SeparationDate As %Date;

Property Location As Wasabi.Data.AddressPersistent;

Property Email As Wasabi.Common.DT.Email;

Property Active As %Boolean;

Property Picture As %Stream.GlobalBinary;

}

