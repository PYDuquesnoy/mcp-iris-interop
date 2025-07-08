/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.Studio.DocumentHistory Extends %RegisteredObject [ System = 3 ]
{

ClassMethod Add(DocumentName As %String, Action As %String = 1, Namespace As %String = {$namespace}, Username As %String = {$USERNAME}, MaxItems As %Integer = 100)
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC

	If DocumentName[".",DocumentName'["/" {
		Set DocumentName=$piece(DocumentName,".",1,*-1)_"."_$zconvert($piece(DocumentName,".",*),"l")
	}

	if ("" = Username) {
		set Username = "null" 
	}

	if ($d(^%Studio.DocumentHistory(Namespace,Username,0,DocumentName))>0) {
		d ##class(%SYS.Studio.DocumentHistory).Delete(DocumentName,Namespace,Username)
	}

    s ^%Studio.DocumentHistory(Namespace,Username,1,$h,DocumentName)= Action
    s ^%Studio.DocumentHistory(Namespace,Username,0,DocumentName,$h)= ""
    s ^%Studio.DocumentHistory(Namespace,Username) = $g(^%Studio.DocumentHistory(Namespace,Username)) + 1

	//trim to MaxItems if necessary
	s i=0
    if ($g(^%Studio.DocumentHistory(Namespace,Username)) > MaxItems) {
	    do {
		    s i = 0
	        s time=$o(^%Studio.DocumentHistory(Namespace,Username,1,""))
	        if (time '= "") {
	            s name = ""
	            do {
	            	s name=$o(^%Studio.DocumentHistory(Namespace,Username,1,time,name))
	                if (name '="") {
		                s i = ##class(%SYS.Studio.DocumentHistory).Delete(name,Namespace,Username)
						if (0 = i) {
							k ^%Studio.DocumentHistory(Namespace,Username,1,time,name)
							s ^%Studio.DocumentHistory(Namespace,Username) = $g(^%Studio.DocumentHistory(Namespace,Username))-1
						}
	                  }
	               } while (name '= "") 
	        }
	    } while ((i > 0) &($g(^%Studio.DocumentHistory(Namespace,Username)) > MaxItems))
    }
}

ClassMethod Delete(DocumentName As %String, Namespace As %String = {$namespace}, Username As %String = {$USERNAME}) As %Integer
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC

	if ("" = Username) {
		set Username = "null" 
	}
	set i = 0
    s time = ""
    do {
          s time=$o(^%Studio.DocumentHistory(Namespace,Username,0,DocumentName,time))
          if (time '="") {
          	s i = i+1 
           	k ^%Studio.DocumentHistory(Namespace,Username,1,time,DocumentName)
          }
   	} while (time '= "")

	k ^%Studio.DocumentHistory(Namespace,Username,0,DocumentName)
   	s ^%Studio.DocumentHistory(Namespace,Username) = $g(^%Studio.DocumentHistory(Namespace,Username)) - i
   	
   	Quit i
}

ClassMethod Get(Namespace As %String = {$namespace}, Username As %String = {$USERNAME}, MaxItems As %Integer = 100) As %String
{
	new %SourceControl ; prevent document reload
	
	$$$AddAllRoleTemporary ; verified 9/26/16 STC
	
	if ("" = Username) {
		set Username = "null" 
	}
	
	s time = "", return = ""
    s i = 0
     do {
        s time=$o(^%Studio.DocumentHistory(Namespace,Username,1,time),-1)
        if (time '= "") {
            s name = ""
            do {
               s name=$o(^%Studio.DocumentHistory(Namespace,Username,1,time,name))
               if (name '="") {
      		        s action = $g(^(name))
                	if (##class(%Library.RoutineMgr).Exists(name)) {
                       if (i ) s return = return_","
                       s i = i+1 
                       s return=return_name_":"_action
                   } else {
					d ##class(%SYS.Studio.DocumentHistory).Delete(name,Namespace,Username)
          		   }
              }
            } while ((name '= "") && (i <= MaxItems))
        }
    } while ((time '="") && (i <= MaxItems))
    
    quit return
}

ClassMethod GetWithDate(Namespace As %String = {$namespace}, Username As %String = {$USERNAME}, MaxItems As %Integer = 100) As %String
{
	$$$AddAllRoleTemporary ; verified 9/26/16 STC

	if ("" = Username) {
		set Username = "null" 
	}
	
	s time = "", lasttime = "", return = ""
    s i = 0
     do {
        s time=$o(^%Studio.DocumentHistory(Namespace,Username,1,time),-1)
        if (time '= "") {
	        s name = ""
	        if (+lasttime '= +time) {
	            s return = return_";"_($h - time)_";"
	            set lasttime = time
	            set i = 0
	        }
            do {
               s name=$o(^%Studio.DocumentHistory(Namespace,Username,1,time,name))
               if (name '="") {
                	if (##class(%Library.RoutineMgr).Exists(name)) {
                       if (i ) s return = return_","
                       s i = i+1 
                       s return=return_name
                   } else {
					d ##class(%SYS.Studio.DocumentHistory).Delete(name,Namespace,Username)
          		   }
              }
            } while ((name '= "") && (i <= MaxItems))
        }
    } while ((time '="") && (i <= MaxItems))
    
    quit return
}

ClassMethod Clear(Namespace As %String = {$namespace}, Username As %String = {$USERNAME})
{
	if ((Namespace '= "") && (Username '= "")) {
		k ^%Studio.DocumentHistory(Namespace,Username)
	}
}

}
