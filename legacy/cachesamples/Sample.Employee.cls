/// This sample persistent class represents an employee.<br>
Class Sample.Employee Extends Person
{

/// The employee's job title.
Property Title As %String(MAXLEN = 50, POPSPEC = "Title()");

/// The employee's current salary.
Property Salary As %Integer(MAXVAL = 100000, MINVAL = 0);

/// A character stream containing notes about this employee.
Property Notes As %Stream.GlobalCharacter;

/// A picture of the employee
Property Picture As %Stream.GlobalBinary;

// A Column before the Title in the select *  order

Property Tadmin As %String [ InitialExpression = "KKK" ];

/// The company this employee works for.
Relationship Company As Company [ Cardinality = one, Inverse = Employees ];

/// This method overrides the method in <class>Person</class>.<br>
/// Prints the properties <property>Name</property> and <property>Title</property> 
/// to the console.
Method PrintPerson()
{
	Write !,"Name: ", ..Name, ?30, "Title: ", ..Title
	Quit
}

/// writes a .png file containing the picture, if any, of this employee
/// the purpose of this method is to prove that Picture really contains an image
Method WritePicture()
{
	if (..Picture="") {quit}
	set name=$TR(..Name,".") ; strip off trailing period
	set name=$TR(name,", ","__") ; replace commas and spaces
	set filename=name_".png"
	
	set file=##class(%Stream.FileBinary).%New()
	set file.Filename=filename
	do file.CopyFrom(..Picture)
	do file.%Save()
	write !, "Generated file: "_filename
}

Storage Default
{
<Data name="EmployeeDefaultData">
<Subscript>"Employee"</Subscript>
<Value name="1">
<Value>Company</Value>
</Value>
<Value name="2">
<Value>Notes</Value>
</Value>
<Value name="3">
<Value>Salary</Value>
</Value>
<Value name="4">
<Value>Title</Value>
</Value>
<Value name="5">
<Value>Picture</Value>
</Value>
<Value name="6">
<Value>CarLicencePlate</Value>
</Value>
<Value name="7">
<Value>Tadmin</Value>
</Value>
</Data>
<DefaultData>EmployeeDefaultData</DefaultData>
<ExtentSize>100</ExtentSize>
<Property name="%%CLASSNAME">
<AverageFieldSize>17</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Age">
<AverageFieldSize>1.9</AverageFieldSize>
<Selectivity>1.4706%</Selectivity>
</Property>
<Property name="Company">
<AverageFieldSize>1.61</AverageFieldSize>
<Selectivity>5.0000%</Selectivity>
</Property>
<Property name="DOB">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>1.0000%</Selectivity>
</Property>
<Property name="FavoriteColors">
<AverageFieldSize>6.23</AverageFieldSize>
<OutlierSelectivity>.36:</OutlierSelectivity>
<Selectivity>2.3704%</Selectivity>
</Property>
<Property name="Home">
<AverageFieldSize>36.28,City:7.26,State:2,Street:16.69,Zip:5</AverageFieldSize>
<Selectivity>1.0000%,City:3.8462%,State:2.1739%,Street:1.0000%,Zip:1.0000%</Selectivity>
</Property>
<Property name="Name">
<AverageFieldSize>16.26</AverageFieldSize>
<Selectivity>1.0000%</Selectivity>
</Property>
<Property name="Notes">
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="Office">
<AverageFieldSize>36.09,City:7.16,State:2,Street:16.59,Zip:5</AverageFieldSize>
<Selectivity>1.0000%,City:4.1667%,State:2.4390%,Street:1.0000%,Zip:1.0000%</Selectivity>
</Property>
<Property name="Picture">
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="SSN">
<AverageFieldSize>11</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="Salary">
<AverageFieldSize>4.89</AverageFieldSize>
<Selectivity>1.0000%</Selectivity>
</Property>
<Property name="Spouse">
<AverageFieldSize>1.93</AverageFieldSize>
<Selectivity>1.5625%</Selectivity>
</Property>
<Property name="Title">
<AverageFieldSize>20.19</AverageFieldSize>
<Selectivity>1.4286%</Selectivity>
</Property>
<SQLMap name="$Employee">
<BlockCount>-4</BlockCount>
</SQLMap>
<Type>%Storage.Persistent</Type>
}

}

