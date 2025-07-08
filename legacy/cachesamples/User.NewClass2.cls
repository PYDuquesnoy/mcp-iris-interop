Class User.NewClass2 Extends %Persistent
{

ClassMethod montaPupup() As %Status
{
	K ^%KK
	//d ..Run()
	//Q $$$OK

	//S jMenu=%request.Data("menu",1)
	//S jMenu=%request.Data("menu",1)
	S jMenu="[{""icon"":""fa fa-file-o"",""titol"":""Nuevo"",""id"":""mnuNew""},{""icon"":""fa fa-pencil-square-o"",""titol"":""Editar"",""id"":""mnuEdit"",""enabled"":false},{""icon"":""fa fa-trash"",""titol"":""ELiminar"",""id"":""mnuDelete"",""enabled"":true,""sub"":[{""icon"":""fa fa-pencil-square-o"",""titol"":""Excel"",""id"":""mnuExcel"",""enabled"":true}]},{""icon"":""fa fa-search"",""titol"":""Consultar"",""id"":""mnuSearch""}]"	
	
	S ^%KK=jMenu
	
	S COUNT=0
	set tPPGName="^%JSON"
	set tSC=..ToArray(jMenu,tPPGName)
	W "OK - JSON CREATED"
	Q $$$OK
}

/// Recursive Parse: May not handle some "" JSON property names or special json object type like null, unasigned or oref
ClassMethod Parse(tJSON As %DynamicAbstractObject, tPPGName As %String)
{
		//Write "***Parse: tPPGName=",tPPGName,!
		
		set iter = tJSON.%GetIterator()
		while iter.%GetNext(.key , .value ) {
			///write "key = "_key_" , type ="_tJSON.%GetTypeOf(key)_" , value = "_value,!
			if (",object,array,"[(","_tJSON.%GetTypeOf(key)_",")) {
				///parse recursively if object or array
				do ..Parse(value,$name(@tPPGName@(key)))
			}else {
				set @tPPGName@(key)=value
				
				
				//JCL
				S COUNT=COUNT+1
				S ^%KK(COUNT,tPPGName,key)=value
				
				
			}
		}
		//break
}

/// tPPG is the Name of a Process Private Global to Fill with the Data
ClassMethod ToArray(pStr As %String, ByRef tPPGName As %String = "^||JSON") As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	K @tPPGName

	try {
		set tJSON=##class(%DynamicAbstractObject).%FromJSON(pStr)
		do ..Parse(tJSON,tPPGName)
	}catch (errObj) {
		Write "CATCH:",errObj.DisplayString(),!
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

/// Ejemplo
ClassMethod Run() As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		set str(1)="{""Property1"":""value1""}"
		set str(2)="{""object1"":{""property1"":""value1"",""property2"":""value2""},""object2"":{""property1"":""value21"",""property2"":""value22""}}"
		set str(3)="{""Array1"":[{""property1"":""value1"",""property2"":""value2""},{""property1"":""value21"",""property2"":""value22""}]}"
		set str(4)="{ ""Actors"": [ { ""name"": ""Tom Cruise"", ""age"": 56, ""Born At"": ""Syracuse, NY"", ""Birthdate"": ""July 3, 1962"", ""photo"": ""https://jsonformatter.org/img/tom-cruise.jpg"", ""wife"": null, ""weight"": 67.5, ""hasChildren"": true, ""hasGreyHair"": false, ""children"": [ ""Suri"", ""Isabella Jane"", ""Connor"" ] }, { ""name"": ""Robert Downey Jr."", ""age"": 53, ""Born At"": ""New York City, NY"", ""Birthdate"": ""April 4, 1965"", ""photo"": ""https://jsonformatter.org/img/Robert-Downey-Jr.jpg"", ""wife"": ""Susan Downey"", ""weight"": 77.1, ""hasChildren"": true, ""hasGreyHair"": false, ""children"": [ ""Indio Falconer"", ""Avri Roel"", ""Exton Elias"" ] } ] }"
		
		for i=1:1:4 {
			Write !,"JSON text: ",str(i),!
			
			set tPPGName="^||JSON"
			kill @tPPGName
			set tSC=..ToArray(str(i),tPPGName)
			
			zwrite @tPPGName
			write !,!
		}
	}catch(errObj) {
		write "CATCH:",errObj.DisplayString()
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="NewClass2DefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^User.NewClass2D</DataLocation>
<DefaultData>NewClass2DefaultData</DefaultData>
<IdLocation>^User.NewClass2D</IdLocation>
<IndexLocation>^User.NewClass2I</IndexLocation>
<StreamLocation>^User.NewClass2S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

