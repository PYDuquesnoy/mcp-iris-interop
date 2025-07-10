/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Contains the authorization information needed to use a remote system.
Class Ens.Config.Credentials Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Property SystemName As %String(CAPTION = "@Ensemble:SystemNameID@ID", XMLPROJECTION = "ATTRIBUTE");

Property Username As %String(CAPTION = "@Ensemble:Username@Username", MAXLEN = 3640873, XMLPROJECTION = "ATTRIBUTE");

Property Password As %CSP.Util.Passwd(CAPTION = "@Ensemble:Password@Password", MAXLEN = "", XMLPROJECTION = "ATTRIBUTE") [ SqlFieldName = PasswordObject ];

Property PasswordSQL As %String(MAXLEN = "", XMLPROJECTION = "NONE") [ Calculated, SqlComputeCode = {Set {*}= ##class(Ens.Config.Credentials).%OpenId({SystemName}).Password}, SqlComputed, SqlComputeOnChange = Password, SqlFieldName = Password ];

Property statusPwdGet As %Status [ InitialExpression = 1, Internal, Private, Transient ];

Property statusPwdSet As %Status [ InitialExpression = 1, Internal, Private, Transient ];

Property modifiedPwd As %Boolean [ InitialExpression = 0, Internal, Private, Transient ];

Method PasswordGet() As %CSP.Util.Passwd [ ServerOnly = 1 ]
{
	Set tPassword = "", tSC = $$$OK
	Try {
		If (i%SystemName="")||..modifiedPwd {Set tPassword = i%Password Quit}
		If i%Password '= "" {Set tSC = ..PasswordSet(i%Password) Quit:$$$ISERR(tSC)} /* Convert old format on Get*/
		Set tPassword = ##class(%SYS.Ensemble).SecondaryGet(i%SystemName,"Password",.tSC)
	} Catch e {Set tSC = e.AsStatus()}
	Set ..statusPwdGet = tSC
	Quit tPassword
}

Method PasswordSet(Arg As %CSP.Util.Passwd) As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		/* Credentials cannot be saved until SystemName populated */
		If (i%SystemName = "") {Set i%Password = Arg Quit}
		/*	Delay writing password if the password is being updated for an existing credentials
		 	since credentials might not be saved. If not modified and i%Password is not empty then that is data migration
		 */
		If ..%ExistsId(i%SystemName)&&((..modifiedPwd)||(i%Password="")) {
			Set i%Password = Arg, ..modifiedPwd = 1
			Quit
		}
		/* Persist the password but it will be removed if the credentials object is not saved */
		Set tSC = ##class(%SYS.Ensemble).SecondarySet(Arg,i%SystemName,"Password")
		If tSC,(i%Password '= "") {Set i%Password = "", tSC = ..%Save()} /* Remove old pwd from storage */
	} Catch e {Set tSC = e.AsStatus()}
	Set ..statusPwdSet = tSC
	Quit tSC
}

/// Name of Business Partner Profile associated with this item.
Property BusinessPartner As %String(CAPTION = "@Ensemble:BusinessPartner@BusinessPartner", MAXLEN = 255, XMLPROJECTION = "ATTRIBUTE");

Index SystemName On SystemName [ IdKey, PrimaryKey ];

Query List() As %SQLQuery
{
Select ID, %Truncate(Username, 3640820) As Username,'xxx' as Password, BusinessPartner from Ens_Config.Credentials
}

/// Classmethod to create a new credential
ClassMethod SetCredential(pName As %String, pUsername As %String, pPassword As %String, pOverwrite As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Set tObj = $$$NULLOREF
		If ..%ExistsId(pName) {
			If pOverwrite {
				Set tObj = ..%OpenId(pName)
			} Else {
			Set tError = $$$Text("A credential with this ID already exists")
			Set tSC = $$$ERROR($$$EnsErrGeneral, tError) Quit
			}
		} Else {
			Set tObj = ..%New()
		}
		
		If $IsObject($G(tObj)) {
			Set tObj.SystemName = pName
			Set tObj.Username = pUsername
			Set tObj.Password = pPassword
			
			Set tSC = tObj.%Save()
		} Else {
			Set tError = $$$Text("Cannot open or create credential")
			Set tSC = $$$ERROR($$$EnsErrGeneral, tError)
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

ClassMethod GetCredentialsObj(Output pCredObj As Ens.Config.Credentials, pCallerClassname As %String, pCredClassname As %String, pCredentialsID As %String) As %Status
{
	// We allow "none" as a SystemName value to return a fresh empty object for back-compatibility; "" does the same
	Set pCredObj=$$$NULLOREF
	Quit:""=pCredClassname $$$ERROR($$$EnsErrNoCallerCredentials,pCallerClassname)
	Set tLowerID = $ZCVT(pCredentialsID,"L")
	If ""=tLowerID||("none"=tLowerID) {
		#; return a fresh empty object
		Set pCredObj = $classmethod(pCredClassname,"%New")
		Quit:'$IsObject(pCredObj) %objlasterror
		Set pCredObj.SystemName=pCredentialsID
		Quit $$$OK
	}
	#; Get correct case for SystemName
	&sql(SELECT SystemName INTO :tID FROM Ens_Config.Credentials WHERE LOWER(SystemName) = :tLowerID)
	Quit:SQLCODE $$$ERROR($$$EnsErrNoCredentialsSystemName,pCredentialsID,"SQLCODE="_SQLCODE)

	Set pCredObj = $classmethod(pCredClassname,"%OpenId",tID,,.tSC)
	Quit:'$IsObject(pCredObj) $$$ERROR($$$EnsErrNoCredentialsSystemName,pCredentialsID,$$$StatusDisplayString(tSC))
	Quit tSC
}

ClassMethod GetValue(pCredentialsID As %String, pCredentialName As %String) As %String
{
	Set tLowerID = $ZCVT(pCredentialsID,"L")
	Quit:""=tLowerID||("none"=tLowerID) ""
	Quit:""=pCredentialName "<N/A ID '"_tLowerID_"' Credential field name>"
	&sql(SELECT x__classname INTO :tClass FROM Ens_Config.Credentials WHERE LOWER(SystemName) = :tLowerID)
	Quit:+SQLCODE "<N/A Credentials ID '"_tLowerID_"'>"
	Set tClass = $P(tClass,"~",$L(tClass,"~")-1)
	Set tTable = $S(""=tClass:"Ens_Config.Credentials",1:$$$defClassKeyGet(tClass,$$$cCLASSsqltablename))
	
	Set tRS=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set tSC=tRS.Prepare("Select "_pCredentialName_" from "_tTable_" where LOWER(SystemName)='"_tLowerID_"'")
	Set:$$$ISOK(tSC) tSC=tRS.Execute()
	Set:$$$ISOK(tSC) tSC=tRS.Next()
	Quit:$$$ISERR(tSC)||('$D(tRS.Data(pCredentialName))#2) "<N/A ID '"_tLowerID_"' field '"_pCredentialName_"' value>"
	Quit tRS.Data(pCredentialName)
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tID=$$$oidPrimary(oid),tSC=$$$OK
	Try { 
		Set tSC=##class(%SYS.Ensemble).SecondaryDelete(tID,"Password")
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

Trigger OnDelete [ Event = DELETE ]
{
	Set tID={%%ID}
	Try { 
		Set tSC=##class(%SYS.Ensemble).SecondaryDelete(tID,"Password")
	} Catch e {}
	Quit
}

/// Clean up password if credentials object not saved but we already saved the password
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC=$$$OK
	Try { 
		If (..%Id()=""),(i%SystemName'=""),'..%ExistsId(i%SystemName) {
			Set tSC=##class(%SYS.Ensemble).SecondaryDelete(i%SystemName,"Password")
		}
	} Catch e {Set tSC=e.AsStatus()}
	Quit tSC
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	#;Always want to fail if not allowed to set password
	Quit ..statusPwdSet
}

Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		#;If we are an IRIS job then test if can get password and report error accordingingly otherwise open without password.
		If $D($$$EnsJobLocal("ConfigName"))||$D($$$EnsJobLocal("TCPIn.OutsideJob")) {
			Do ..PasswordGet()
			Set tSC = ..statusPwdGet
		}
	} Catch ex { Set tSC = ex.AsStatus()}
	Quit tSC
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	#Dim tSC As %Status = $$$OK
	#Dim ex As %Exception.AbstractException
	
	Try {
		If ..modifiedPwd { 
			Set tSC = ##class(%SYS.Ensemble).SecondarySet(i%Password,i%SystemName,"Password")
			Set ..statusPwdSet = tSC
			If $$$ISERR(tSC) Quit
			Set i%Password = ""
			Set ..modifiedPwd = 0
		}
	} Catch ex {Set tSC = ex.AsStatus()}
	Quit tSC
}

Storage Default
{
<Data name="CredentialsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Password</Value>
</Value>
<Value name="3">
<Value>Username</Value>
</Value>
<Value name="4">
<Value>BusinessPartner</Value>
</Value>
<Value name="5">
<Value>PasswordSQL</Value>
</Value>
</Data>
<DataLocation>^Ens.Conf.CredentialsD</DataLocation>
<DefaultData>CredentialsDefaultData</DefaultData>
<ExtentSize>40</ExtentSize>
<IdLocation>^Ens.Conf.CredentialsD</IdLocation>
<IndexLocation>^Ens.Conf.CredentialsI</IndexLocation>
<StreamLocation>^Ens.Conf.CredentialsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
