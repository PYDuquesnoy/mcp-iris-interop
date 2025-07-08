Include %occStatus

Class Wasabi.Person.API.PersonUtils [ Abstract ]
{

ClassMethod Validate(username As %String, password As %String) As %Boolean
{
	#dim ex as %Exception.SystemException
	#dim user as Employee
	#dim ret as %Boolean
	#dim status as %Status
	#dim sc as %Status
		
	
	try {
		set user = ##class(Wasabi.Data.Person).idxUserNameOpen(username,,.sc)
		$$$THROWONERROR(status,sc)
		
		if user.Password = $system.Encryption.MD5Hash(password) {
			set ret = 1
		}
		else {
			// password wrong
			set ret = 0
		}			
	}
	catch ex {
		// simply passes the exception to the caller
		THROW ex
	}
	
	quit ret
}

ClassMethod GetMatches(lastname As %String = "", firstname As %String = "") As %ResultSet.SQL
{
}

ClassMethod GetOne(id As %String) As Wasabi.Person.API.Person
{
}

ClassMethod Add(cust As Wasabi.Person.API.Person)
{
}

ClassMethod Update(cust As Wasabi.Person.API.Person)
{
}

}

