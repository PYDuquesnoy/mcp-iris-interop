/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.UserLibrary.UserData Extends %XML.Adaptor [ Abstract ]
{

Method getIdentifier() As %String
{
	Quit ""
}

Storage Default
{
<Data name="UserDataDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.UserLibrary.UserDataD</DataLocation>
<DefaultData>UserDataDefaultData</DefaultData>
<IdLocation>^%DeepSee.UserLibrary.UserDataD</IdLocation>
<IndexLocation>^%DeepSee.UserLibrary.UserDataI</IndexLocation>
<StreamLocation>^%DeepSee.UserLibrary.UserDataS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
