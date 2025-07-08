/// DataModel class used for test page.
Class ZENTest.DataModel Extends %ZEN.DataModel.ObjectDataModel
{

Property Name As %String(MAXLEN = 40);

Property City As %String(MAXLEN = 40);

/// Enumerated property.
Property Sex As %String(DISPLAYLIST = ",Male,Female,Other", MAXLEN = 1, VALUELIST = ",M,F,O");

/// Stream property.
Property Memo As %GlobalCharacterStream;

/// Object reference property.
Property Employee As ZENDemo.Data.Employee(ZENSQL = "Select %Id,Name From ZENDemo_Data.Employee", ZENSQLLOOKUP = "Select Name From ZENDemo_Data.Employee Where %Id=?");

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If (..%id '= "") {
		Set ..Name = $G(^DataModel.Test(..%id,"Name"))
		Set ..City = $G(^DataModel.Test(..%id,"City"))
		Set ..Sex = $G(^DataModel.Test(..%id,"Sex"))
		Do ..Memo.Write($G(^DataModel.Test(..%id,"Memo")))
		Set id = $G(^DataModel.Test(..%id,"Employee"))
		Set:id'="" ..Employee = ##class(ZENDemo.Data.Employee).%OpenId(id)
	}
	
	Quit tSC
}

/// This callback method does the actual work of copying values 
/// from the DataModel to the data source.<br>
Method %OnStoreModel(pSource As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If (..%id '= "") {
		Set ^DataModel.Test(..%id,"Name") = ..Name
		Set ^DataModel.Test(..%id,"City") = ..City
		Set ^DataModel.Test(..%id,"Sex") = ..Sex
		Set ^DataModel.Test(..%id,"Memo") = ..Memo.Read(32000)
		If $IsObject(..Employee) {
			Set ^DataModel.Test(..%id,"Employee") = ..Employee.%Id()
		}
		Else {
			Set ^DataModel.Test(..%id,"Employee") = ""
		}
	}
	Quit tSC
}

}

