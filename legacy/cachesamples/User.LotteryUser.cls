/// The <CLASS>LotteryUser</CLASS> class represents a user for 
/// the CSP Lottery Example application.
Class User.LotteryUser Extends %Persistent
{

Index UserNameIdx On UserName [ Unique ];

Property UserName As %String [ Required ];

Property LastName As %String [ Required ];

Property FirstName As %String [ Required ];

Property Password As %String [ Private, Required ];

Property VisitCount As %Integer [ InitialExpression = 0 ];

Property TotalBalance As %Integer [ InitialExpression = 0 ];

Property History As list Of LotteryActivity;

/// Change the password for this user.
Method changePassword(pass As %String) As %Integer
{
 Set ..Password=pass
 QUIT
}

/// Test if <var>pass</var> is correct password for this user.
Method testPassword(pass As %String) As %Boolean
{
 Quit (..Password=pass)
}

/// Called by CSP page to add a new user.
ClassMethod addNewUser(UserName As %String, FirstName As %String, LastName As %String, pass As %String) As %Integer
{
 Set user=##class(LotteryUser).%New()
 Set user.UserName=UserName
 Set user.FirstName=FirstName
 Set user.LastName=LastName
 Do user.changePassword(pass)

 Set sc=user.%Save()

 If ($$$ISERR(sc)) &js<alert('Unable to create user.');> QUIT 0

 QUIT 1
}

/// Find the ID of the user with the specified user name.
ClassMethod findUser(UserName As %String) As %String
{
 Set id=""

 ; use embedded SQL to search for user
 &sql(SELECT ID INTO :id FROM LotteryUser Where (UserName = :UserName))

 QUIT id
}

/// Test if the name/password specifies a valid user. If so, return the user's ID.
ClassMethod authenticate(UserName As %String, Password As %String) As %String
{
 Set id=..findUser(UserName)
 If (id'="") Do
 . Set user=..%OpenId(id)
 . If 'user.testPassword(Password) Set id=""

 QUIT id
}

/// Called by CSP page to add a new purchase. Returns amount of purchase.
ClassMethod addPurchase(id As %String, type As %String) As %Float
{
 Set price=0
 If (type="STANDARD") Set price=10
 Else  If (type="DELUXE") Set price=50

 If (price=0) QUIT 0

 Set user=##class(LotteryUser).%OpenId(id)
 If user="" QUIT 0

 Set action=##class(LotteryActivity).%New()
 Set action.TheUser=user
 Set action.ActivityType="PURCHASE"
 Set action.Amount=price
 Set action.Product=type

 Do user.History.Insert(action)

 Set sc=user.%Save()

 QUIT price
}

Storage Default
{
<Data name="LotteryUserDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>FirstName</Value>
</Value>
<Value name="3">
<Value>History</Value>
</Value>
<Value name="4">
<Value>LastName</Value>
</Value>
<Value name="5">
<Value>Password</Value>
</Value>
<Value name="6">
<Value>TotalBalance</Value>
</Value>
<Value name="7">
<Value>UserName</Value>
</Value>
<Value name="8">
<Value>VisitCount</Value>
</Value>
</Data>
<DataLocation>^User.LotteryUserD</DataLocation>
<DefaultData>LotteryUserDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^User.LotteryUserD</IdLocation>
<IndexLocation>^User.LotteryUserI</IndexLocation>
<StreamLocation>^User.LotteryUserS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

