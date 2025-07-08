Include %occInclude

IncludeGenerator (%occInclude, %occUtility, %occReference2)

Class Wasabi.Common.Test [ Abstract ]
{

ClassMethod PopulateEmployees(nEmployees As %Integer) As %Integer [ Final ]
{
	for nCust=1:1:nEmployees{
	    s employee=##class(Wasabi.Person.API.Employee).%New()
		d ..PopPersonProps(.employee)
        s employee.SSN=(100+$r(899))_(10+$r(89))_(1000+$r(8999))
        s nJobs=$r(3)+1
        for nJ=1:1:nJobs{
	        s nJob=##class(Wasabi.Data.Job).%New()
	        s nJob.JobTitle=##class(%PopulateUtils).Title()
	        s nJob.SecurityRole=##class(%PopulateUtils).String(4)
	        s sc=nJob.%Save()
            d employee.Jobs.InsertObject(nJob.%Oid())
	    }
	    //find a random, active employee to be this person's manager
	    &sql(SELECT min(%ID),max(%ID) INTO :nMinEmpID,:nMaxEmpID from wasabi_data.employee)
	    //if table is empty, set the min and max row IDs to dummy values
	    if SQLCODE=0 {
		    if $g(nMaxEmpID)-$g(nMinEmpID)<=0 s nMinEmpID=0,nMaxEmpID=1 
		    //make 20 attempts to find an employee has active status
		    for nAttempts=1:1:20
		    {
			     s EmpID=nMinEmpID+$r(nMaxEmpID-nMinEmpID)
		     		     
		         &sql(SELECT %ID INTO :MgrID from wasabi_data.employee where %ID=:EmpID and Active=1)
		         
	             if SQLCODE = 0 {
	             	do employee.ManagerSetObjectId(MgrID)            
	             	quit
	             }
		    }
		    //if we had no luck finding an active manager, set manager to be the first ID in the employee table who has Active status
	        if '($IsObject(employee.Manager))
	        {
		        &sql(SELECT %ID INTO :MgrID from wasabi_data.employee where Active=1 order by %ID)
		        if SQLCODE = 0 {
			        	do employee.ManagerSetObjectId(MgrID)            
		        }
		          
	        }
	    }
         s MinHireDay=45000,MaxHireDay=60000
         s employee.HireDate=##class(%PopulateUtils).Date(MinHireDay,MaxHireDay)
         s employee.Active=$r(2)
         if employee.Active=0 s employee.SeparationDate=##class(%PopulateUtils).Date((MaxHireDay+1),($h-1))

         //create a location address for this employee.  If you want all employees to have same location, put this outside the loop
         //and set each employee's address to addr
         d ..PopAddress(.LocaddrOID)
         s addr=##class(Wasabi.Data.AddressPersistent).%Open(LocaddrOID)
         if $IsObject(addr) s employee.Location=addr
         
         s employee.Email=$ZSTRIP((employee.LastName_employee.FirstName),"*P")_"@company.com"

         //using the prepopulated global of binary images for male and females, grab one for this employee
         if employee.Gender=1 d ..GrabRandomPicture(.strRandomPic)
         else  s gn="^zzzWasabiWomanPics" d ..GrabRandomPicture(.strRandomPic,gn)
         d employee.Picture.CopyFromAndSave(strRandomPic)
		 d ##class(Wasabi.Data.Employee).Add(employee)
	}
}

ClassMethod PopulateCustomers(nCustomers As %Integer) As %Integer [ Final ]
{
	for nCust=1:1:nCustomers{
	    s customer=##class(Wasabi.Person.API.Customer).%New()
		d ..PopPersonProps(.customer)
		s customer.CustomerNumber=$r(899999999)+100000000000
        s customer.CompanyName=##class(%PopulateUtils).Company()
        s customer.ContactEmailAddress=$ZSTRIP((customer.LastName_customer.FirstName),"*P")_"@"_$p(##class(%Library.PopulateUtils).Syllable()," ",1)_##class(%PopulateUtils).ValueList(",.com,.net,.org")

		d ##class(Wasabi.Data.Customer).Add(customer)
	}
}

ClassMethod PopPersonProps(ByRef person As %ObjectIdentity) As %Status
{
	 s person.Gender=$r(2)+1
     s person.ID=$r(899999)+100000
     s person.LastName=##class(%PopulateUtils).LastName()
     s person.FirstName=##class(%PopulateUtils).FirstName(person.Gender)
     s person.MiddleInitial=##class(%PopulateUtils).String()
     s person.DOB=##class(%PopulateUtils).Date(30000,60000)
     s person.Title=##class(%PopulateUtils).ValueList(",Dr.,Counselor,Honorable,Judge")
     s person.Suffix=##class(%PopulateUtils).ValueList(",Jr.,Sr.,M.D.,Esq.,DDS")
     s person.UserName=person.LastName_##class(%PopulateUtils).String(4)
     s person.Password=$system.Encryption.MD5Hash(person.Password)

     s nAddr=$r(3)+1
     for nA=1:1:nAddr s sc=..PopAddress(.addrOID) d person.Addresses.InsertObject(addrOID)
     
     s nPhone=$r(3)+1
     for nA=1:1:nPhone s sc=..PopPhoneNumberSerial(.phOREF) d person.PhoneNumberSerials.Insert(phOREF)
     quit $$$OK
}

ClassMethod PopAddress(ByRef addrOID As %ObjectIdentity) As %Status
{
   s addr=##class(Wasabi.Data.AddressPersistent).%New()
   s addr.Street1=##class(%PopulateUtils).Street()
   s addr.Street2=##class(%PopulateUtils).ValueList(",,Suite 100,Dept 1A,Floor 789,,Dept 8C,C92-293,Sector 456,,,Mailroom")
   s addr.City=##class(%PopulateUtils).City()
   s addr.Region=##class(%PopulateUtils).USState()
   s addr.PostalCode=##class(%PopulateUtils).USZip()
   s addr.Country=##class(%PopulateUtils).ValueList(",USA,Canada")
   s sc=addr.%Save()
   s addrOID=addr.%Oid()
   q sc
}

ClassMethod PopPhoneNumberSerial(ph As %RegisteredObject) As %Status
{
	s ph=##class(Wasabi.Data.PhoneNumberSerial).%New()
	s ph.CountryCode="00"_($r(9)+1)
    s ph.PhoneNumberSerial=$r(8999999999)+1000000000
    s ph.Type=##class(%PopulateUtils).ValueList(",HOME,BUSINESS,CELL")
    s ph.Extension=##class(%PopulateUtils).Integer(1000,9999)
    q $$$OK
}

ClassMethod CopyPersonPictureFile2Global(PicFilename As %String, GlobalName As %String = "^zzzWasabiManPics") As %Status
{
	s StreamFile=##class(%Stream.FileBinary).%New()
	s StreamFile.Filename=$g(PicFilename)
	s StreamGloBin=##class(%Stream.GlobalBinary).%New()
	s StreamGloBin.%Location=GlobalName
	s sc=StreamGloBin.CopyFromAndSave(StreamFile) 
	//NOTE:  I'm getting a non-fatal error saying it can't delete a file in the temp dir.  
	q sc
}

ClassMethod SavePersonPicture2File(PicFilename As %String, GlobalName As %String = "^zzzWasabiManPics", ID As %Integer) As %Status
{
	//Use this method to dump populator stream globals to files
	//PicFilename is output file name
	//GlobalName is the global containing the image streams
	//ID is the subscript in the stream global node.
    s StreamGloBinOID=$lb(ID,"%Stream.GlobalBinary",GlobalName)
    s StreamGloBin=##class(%Stream.Object).%Open(StreamGloBinOID)
    s StreamFileBin=##class(%Stream.FileBinary).%New(),StreamFileBin.Filename=PicFilename
    d StreamFileBin.CopyFromAndSave(StreamGloBin)
	q $$$OK
}

ClassMethod SaveGBStream2File(PicFilename As %String, ByRef SGB As %Stream.GlobalBinary) As %Status
{
    s StreamFileBin=##class(%Stream.FileBinary).%New(),StreamFileBin.Filename=PicFilename
    d StreamFileBin.CopyFromAndSave(SGB)
	q $$$OK
}

ClassMethod GrabRandomPicture(ByRef StreamGloBin As %Stream.GlobalBinary, GlobalName As %String = "^zzzWasabiManPics") As %Status
{
	s sc=$$$OK
	//count number of images in picture global 
	s key=$o(@GlobalName@(""))
	while key'=""
	{
		s PicIDArray=$g(PicIDArray)_$lb(key)
		s key=$o(@GlobalName@(key))
	}   
	
    if $ll(PicIDArray)>0
    {
	    //randomly select an ID from the array
	    s whichPicID=$LG(PicIDArray,$R($LL(PicIDArray))+1)
	    if $d(@GlobalName@(whichPicID))
	    {
		   s StreamGloBinOID=$lb(whichPicID,"%Stream.GlobalBinary",GlobalName)
           s SGB=##class(%Stream.Object).%Open(StreamGloBinOID)
           s StreamGloBin=##class(%Stream.GlobalBinary).%New()
           s sc=StreamGloBin.CopyFromAndSave(SGB)
	    }
    }
    //otherwise, there are no pictures for this gender
	
	q sc
}

}

