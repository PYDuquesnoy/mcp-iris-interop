/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syLDAP, EnsLDAP)

/// General LDAP Utility Class Methods used by <CLASS>EnsLib.LDAP.Adapter.Common</CLASS> and <CLASS>EnsLib.LDAP.Operation.Standard</CLASS>
Class EnsLib.LDAP.Util.General Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Construct possible Distinguished Name concatenating pParent to to the supplied
/// first parameter taken to be a relative distinguished name pRDN <br>
/// If no naming attribute is given for pRDN then the value of the fourth parameter
/// pDefaultRDNAttributeName is used. The default is "cn" <br>
/// The third parameter pEscapeDN if true will lead to the generated DN being escaped
/// according to rfc4514. The default is not to escape. <br>
ClassMethod GenerateDNFromRDNandParent(pRDN As %String = "", pParent As %String = "", pEscapeDN As %Boolean = 0, pDefaultRDNAttributeName As %String = "cn") As %String
{
	#dim tGeneratedDN As %String = $Select($L(pRDN,"=")>1:"",1:(pDefaultRDNAttributeName_"="))_pRDN_$S(""=pParent:"",1:","_pParent)

	If pEscapeDN Return ..EscapeDN(tGeneratedDN)

	Return tGeneratedDN
}

/// Escape DN as per RFC4514 https://www.ietf.org/rfc/rfc4514.txt
ClassMethod EscapeDN(pDNToEscape As %String = "") As %String
{
	#dim tEscaped As %String  = ""
	#dim tCharacterNeedingEscaping As %String

	/*

		distinguishedName = [ relativeDistinguishedName
								*( COMMA relativeDistinguishedName ) ]
		relativeDistinguishedName = attributeTypeAndValue
							*( PLUS attributeTypeAndValue )
		attributeTypeAndValue = attributeType EQUALS attributeValue
		attributeType = descr / numericoid
		attributeValue = string / hexstring

		https://www.ietf.org/rfc/rfc4514.txt
			Can have values in quotes and don't need escaping.
			- a space (' ' U+0020) or number sign ('#' U+0023) occurring at
			the beginning of the string;
			- a space (' ' U+0020) character occurring at the end of the string;
			- one of the characters '"', '+', ',', ';', '<', '>',  or '\'
			(U+0022, U+002B, U+002C, U+003B, U+003C, U+003E, or U+005C, respectively);
			- the null (U+0000) character.

		Other characters may be escaped.

		Each octet of the character to be escaped is replaced by a backslash
		and two hex digits, which form a single octet in the code of the
		character.  Alternatively, if and only if the character to be escaped
		is one of

		' ', '"', '#', '+', ',', ';', '<', '=', '>', or '\'
		(U+0020, U+0022, U+0023, U+002B, U+002C, U+003B,
		U+003C, U+003D, U+003E, U+005C, respectively)

		it can be prefixed by a backslash ('\' U+005C).

	*/

	/*
		Escape logic:

		Parse into AttributeType=AttributeValue and then escape AttributeValue
		Start by parsing into RDNs based on COMMAs
		Then parse into attributeTypeAndValue based on PLUSs
		Then parse into attributeValue based on EQUALSs

	*/

	#dim tDNCommaList = $LISTFROMSTRING(pDNToEscape,",")
	#dim tPtr = 0
	#dim tCountOfRDN = 0
	#dim tListMember
	#dim tRDNArray

	While $LISTNEXT(tDNCommaList,tPtr,tListMember) {
		If '$Data(tListMember)#2 Continue
		#; Account for + within an RDN with commas
		If (tListMember [ "=") &&
		($Find(tListMember,"+")=0 ||($Find(tListMember,"+")>$Find(tListMember,"="))){
			Set tCountOfRDN = tCountOfRDN +1
			Set tRDNArray(tCountOfRDN) = tListMember
		} Else {
			#; Account for erroneous leading ,
			If tCountOfRDN = 0 {
				Set tCountOfRDN = 1
				Set tRDNArray(1) = ""
			}
			#;Add to preceding and escape , if already escaped
			If $E(tRDNArray(tCountOfRDN),*) = "\" {
				Set tRDNArray(tCountOfRDN) = tRDNArray(tCountOfRDN) _ "," _ tListMember
			} Else {
				Set tRDNArray(tCountOfRDN) = tRDNArray(tCountOfRDN) _ "\," _ tListMember
			}
		}
	}

	#; Now we split each RDN on + to get AttributeType=AttributeValue pairs
	#dim tRDNMember As %Integer
	#dim tRDNPlusList As %List
	#dim tAttributeType As %String
	#dim tAttributeValue As %String
	#dim tAttributeMember As %Integer

	#dim tAlreadyEscaped As %Boolean = 0

	For tRDNMember = 1:1:tCountOfRDN {

		Set tRDNPlusList = $LISTFROMSTRING(tRDNArray(tRDNMember),"+")
		Set tPtr = 0
		#dim tCountOfAttribPairs = 0
		Kill tListMember
		#dim tAttributeTypeAndValueArray

		While $LISTNEXT(tRDNPlusList,tPtr,tListMember) {

			If '$Data(tListMember)#2 Continue

			If tListMember [ "=" {

				Set tCountOfAttribPairs = tCountOfAttribPairs +1
				Set tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs) = tListMember

			} Else {

				#; Account for erroneous leading +
				If tCountOfAttribPairs = 0 {
					Set tCountOfAttribPairs = 1
					Set tAttributeTypeAndValueArray(tRDNMember,1) = ""
				}
				#;Add to preceding and escape + if not already escaped
				If $E(tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs),*) = "\" {
					Set tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs) = tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs) _ "+" _ tListMember
				} Else {
					Set tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs) = tAttributeTypeAndValueArray(tRDNMember,tCountOfAttribPairs) _ "\+" _ tListMember
				}

			}

		}

		/*	Now that we have finished with this RDNMember we can
			take each AttributeType=AttributeValue and retrieve Value from everything after first =
			We then escape the Value.
			Put back into the array value.
		*/

		For tAttributeMember = 1:1:tCountOfAttribPairs {

			Set tAttributeType = $Piece(tAttributeTypeAndValueArray(tRDNMember,tAttributeMember),"=")
			Set tAttributeValue = $Piece(tAttributeTypeAndValueArray(tRDNMember,tAttributeMember),"=",2,*)
			#; Escape tAttributeValue:
			#; Escape special characters except ,+ (since already done) using standard $replace. Do \ first
			#;Don't want to escape if already escaped......
			If ($E(tAttributeValue,1,2)="\ ") || ($E(tAttributeValue,*-1,*)="\ ") Continue

			Set tAlreadyEscaped = 0
			For tCharacterNeedingEscaping = "\",$C(34),"#",";","<","=",">",$C(0) {

				If tAttributeValue[("\"_tCharacterNeedingEscaping) {
					Set tAlreadyEscaped = 1
					Quit /*For loop*/
				}
				Set tAttributeValue = $Replace(tAttributeValue,tCharacterNeedingEscaping,("\"_tCharacterNeedingEscaping))

			}

			If tAlreadyEscaped Continue

			#;Undo double \\, and double \\+
			Set tAttributeValue = $Replace(tAttributeValue,"\\,","\,")
			Set tAttributeValue = $Replace(tAttributeValue,"\\+","\+")
			#;Escape leading space of AttributeValue by prefixing "\"
			If $E(tAttributeValue)=" " Set tAttributeValue = "\"_tAttributeValue
			#;Escape trailing space of AttributeValue by preceding space with \
			If $E(tAttributeValue,*)=" " Set $E(tAttributeValue,*) = "\ "
			#;Record Escaped RDNMember
			Set tAttributeTypeAndValueArray(tRDNMember,tAttributeMember) = tAttributeType_"="_tAttributeValue

		}

	}

	#; Then we walk the arrays putting back the + and the ,

	#dim tAttributePair
	For tRDNMember = 1:1:tCountOfRDN {

		Set tAttributeMember = $Order(tAttributeTypeAndValueArray(tRDNMember,""),1,tAttributePair)
		While tAttributeMember'="" {

			Set tEscaped = tEscaped _ tAttributePair_"+"
			Set tAttributeMember = $Order(tAttributeTypeAndValueArray(tRDNMember,tAttributeMember),1,tAttributePair)

		}

		#;remove last +
		Set $E(tEscaped,*)=""
		Set tEscaped = tEscaped _ ","

	}

	#;remove last ,
	Set $E(tEscaped,*)=""

	Return tEscaped
}

/// UnEscape DN as per RFC4514 https://www.ietf.org/rfc/rfc4514.txt
ClassMethod UnEscapeDN(pDNToUnEscape As %String = "") As %String
{
	#;Look to see if no possibility of escape characters
	If pDNToUnEscape '[ "\" Return pDNToUnEscape

	#dim tUnEscaped, tCharacterNeedingEscaping As %String

	#;UnEscape \\
	Set tUnEscaped = $Replace(pDNToUnEscape,"\\","\")
	#;UnEscape leading space of AttributeValue by removing \
	Set tUnEscaped = $Replace(tUnEscaped,"=\ ","= ")

	#;UnEscape trailing space of AttributeValue by removing \
	Set tUnEscaped = $Replace(tUnEscaped,"\ ,"," ,")

	For tCharacterNeedingEscaping = $C(34),"#","+",",",";","<","=",">",$C(0) {

			Set tUnEscaped = $Replace(tUnEscaped,("\"_tCharacterNeedingEscaping),tCharacterNeedingEscaping)

	}

	#;UnEscape trailing space of last AttributeValue by removing \
	If $E(tUnEscaped,*-1,*) = "\ " Set $E(tUnEscaped,*-1,*) = " "

	Return tUnEscaped
}

/// This returns the Relative Distinguished Name from a Distinguished Name
/// accounting for DN being escaped.<br>
/// pDN is assumed to be already escaped<br>
ClassMethod ExtractRDNFromDN(pDN As %String) As %String
{
	If $Length(pDN,"=")<3 Quit pDN

	#dim tRDN As %String
	#dim tSecondRDNPosition As %Integer = 1
	#dim tKeepPiecing As %Boolean = 0

	Do {

		Set tSecondRDNPosition = tSecondRDNPosition + 1
		Set tRDN = 	$Piece(pDN,"=",1,tSecondRDNPosition)

		/*	Find = not preceded by a \ or a + preceding the AttributeType before the =
			e.g where an DN could be: uid=James+gn=jgm,ou=Engineers,dc=SamplePerson,dc=local
			Add Safety check to the While loop to prevent infinite loop
		*/
		Set tKeepPiecing = ($Extract(tRDN,*)="\") || ($Find(tRDN,"+")>$Find(tRDN,","))

 	} While tKeepPiecing && ($Length(pDN,"=")>tSecondRDNPosition)

	#;Then remove 2nd ,AttributeType
	Set tRDN = $Piece(tRDN,",",1,*-1)
	Quit tRDN
}

/// Classify the LDAP Status code using  Ensemble LDAP status information
/// and return the category as output in 5th parameter.
ClassMethod GenerateEnsLDAPStatus(pLastCall As %String = "", pExtraText As %String = "", pLastStatusText As %String = "", pLDAPStatus As %Integer = 0, Output pCategory As %String) As %Status
{

	#dim tGeneratedStatus As %Status = $$$OK
	#dim tCategorizationList As %List

 	If pLDAPStatus = 0 {

 		Set pCategory = $$$EnsLDAPStatusSuccess

 	} ElseIf pLDAPStatus = "" {

 		Set pCategory = $$$EnsLDAPStatusUnknown

 	} Else {

		#; Lookup function on pLDAPStatus
 		Set tCategorizationList = $$$EnsLDAPCategoryandStatus(pLDAPStatus)

 		Set pCategory = $$$EnsLDAPCategory(tCategorizationList)
 		#;All Ensemble LDAP Errors take 4 parameters
 		Set tGeneratedStatus = $$$ERROR($$$EnsLDAPEnsStatus(tCategorizationList),pLastCall,pExtraText,pLastStatusText,pLDAPStatus)
 	}

 	Quit tGeneratedStatus
}

/// Helper method to find Category of OpenLDAP  status and Ensemble Status code corresponding to OpenLDAP  status
ClassMethod getCategoryandEnsStatusFromLDAP(pLDAPStatus As %Integer = 0) As %List [ Internal ]
{

	If pLDAPStatus = "" Set pLDAPStatus = 0
	Quit $Get($$$EnsLDAPStatusGBL(pLDAPStatus),$LB($$$EnsLDAPStatusUnknown,$$$EnsLDAPErrGeneral))
}

/// Method to generate Map between OpenLDAP error status codes and Ensemble LDAP Error Status information.
/// Called by EnsLib.LDAP.Client.Session when created.
ClassMethod initializeEnsLDAPStatusMap() [ Internal ]
{
	#; $LB(Category, Ensemble Error)

	#;Success
	Set $$$EnsLDAPStatusGBL($$$LDAPSUCCESS)=$LB($$$EnsLDAPStatusSuccess,$$$OK)
	Set $$$EnsLDAPStatusGBL($$$LDAPCOMPAREFALSE)=$LB($$$EnsLDAPStatusSuccess,$$$OK)
	Set $$$EnsLDAPStatusGBL($$$LDAPCOMPARETRUE)=$LB($$$EnsLDAPStatusSuccess,$$$OK)

	#;Referral - These are regarded as success. Application code required to check
	Set $$$EnsLDAPStatusGBL($$$LDAPREFERRAL)=$LB($$$EnsLDAPStatusReferral,$$$EnsLDAPErrReferral)
	Set $$$EnsLDAPStatusGBL($$$LDAPREFERRALV2)=$LB($$$EnsLDAPStatusReferral,$$$EnsLDAPErrReferral)

	#;Authorization
	Set $$$EnsLDAPStatusGBL($$$LDAPAUTHMETHODNOTSUPPORTED)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrAuthMethodNotSupported)
	Set $$$EnsLDAPStatusGBL($$$LDAPSTRONGAUTHREQUIRED)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrStrongAuthenticationRequired)
	Set $$$EnsLDAPStatusGBL($$$LDAPADMINLIMITEXCEEDED)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrAdminLimitExceeded)
	Set $$$EnsLDAPStatusGBL($$$LDAPCONFIDENTIALITYREQUIRED)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrConfidentialityRequired)
	Set $$$EnsLDAPStatusGBL($$$LDAPSASLBINDINPROGRESS)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrSASLBindInProgress)
	Set $$$EnsLDAPStatusGBL($$$LDAPINAPPROPRIATEAUTH)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrInappropriateAuth)
	Set $$$EnsLDAPStatusGBL($$$LDAPINVALIDCREDENTIALS)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrInvalidCredentials)
	Set $$$EnsLDAPStatusGBL($$$LDAPINSUFFICIENTRIGHTS)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrInsufficientRights)
	Set $$$EnsLDAPStatusGBL($$$LDAPAUTHUNKNOWN)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrAuthUnknown)
	Set $$$EnsLDAPStatusGBL($$$XLDAPAUTHUNKNOWN)=$LB($$$EnsLDAPStatusAuthorization,$$$EnsLDAPErrAuthUnknown)

	#;LDAP Server Unavailable
	Set $$$EnsLDAPStatusGBL($$$LDAPPROTOCOLERROR)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrProtocol)
	Set $$$EnsLDAPStatusGBL($$$LDAPBUSY)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrBusy)
	Set $$$EnsLDAPStatusGBL($$$LDAPUNAVAILABLE)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrUnavailable)
	Set $$$EnsLDAPStatusGBL($$$LDAPSERVERDOWN)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrServerDown)
	Set $$$EnsLDAPStatusGBL($$$LDAPCONNECTERROR)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrConnect)
	Set $$$EnsLDAPStatusGBL($$$XLDAPSERVERDOWN)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrServerDown)
	Set $$$EnsLDAPStatusGBL($$$XLDAPCONNECTERROR)=$LB($$$EnsLDAPStatusUnavailable,$$$EnsLDAPErrConnect)

	#;Operation
	Set $$$EnsLDAPStatusGBL($$$LDAPOPERATIONSERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrOperation)
	Set $$$EnsLDAPStatusGBL($$$LDAPTIMELIMITEXCEEDED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrTimeLimit)
	Set $$$EnsLDAPStatusGBL($$$LDAPSIZELIMITEXCEEDED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrSizeLimit)
	Set $$$EnsLDAPStatusGBL($$$LDAPUNAVAILABLECRITEXTENSION)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrUnavailableCritExt)
	Set $$$EnsLDAPStatusGBL($$$LDAPPARTIALRESULTS)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrPartialResults)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOSUCHATTRIBUTE)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNoSuchAttribute)
	Set $$$EnsLDAPStatusGBL($$$LDAPUNDEFINEDTYPE)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrUndefinedType)
	Set $$$EnsLDAPStatusGBL($$$LDAPINAPPROPRIATEMATCHING)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrInappropriateMatching)
	Set $$$EnsLDAPStatusGBL($$$LDAPCONSTRAINTVIOLATION)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrConstraintViolation)
	Set $$$EnsLDAPStatusGBL($$$LDAPATTRIBUTEORVALUEEXISTS)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrAttributeOrValueExists)
	Set $$$EnsLDAPStatusGBL($$$LDAPINVALIDSYNTAX)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrInvalidSyntax)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOSUCHOBJECT)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNoSuchObject)
	Set $$$EnsLDAPStatusGBL($$$LDAPALIASPROBLEM)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrAliasProblem)
	Set $$$EnsLDAPStatusGBL($$$LDAPINVALIDDNSYNTAX)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrInvalidDNSSyntax)
	Set $$$EnsLDAPStatusGBL($$$LDAPISLEAF)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrIsLeaf)
	Set $$$EnsLDAPStatusGBL($$$LDAPALIASDEREFPROBLEM)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrAliasDereference)
	Set $$$EnsLDAPStatusGBL($$$LDAPNAMINGVIOLATION)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNamingViolation)
	Set $$$EnsLDAPStatusGBL($$$LDAPOBJECTCLASSVIOLATION)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrObjectClassViolation)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOTALLOWEDONNONLEAF)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNotAllowedOnNonLEAF)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOTALLOWEDONRDN)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNotAllowedOnRDN)
	Set $$$EnsLDAPStatusGBL($$$LDAPALREADYEXISTS)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrAlreadyExists)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOOBJECTCLASSMODS)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNoObjectClassMods)
	Set $$$EnsLDAPStatusGBL($$$LDAPRESULTSTOOLARGE)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrResultsTooLarge)
	Set $$$EnsLDAPStatusGBL($$$LDAPAFFECTSMULTIPLEDSAS)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrAffectsMultipleDSAs)
	Set $$$EnsLDAPStatusGBL($$$LDAPENCODINGERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrEncoding)
	Set $$$EnsLDAPStatusGBL($$$XLDAPENCODINGERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrEncoding)
	Set $$$EnsLDAPStatusGBL($$$LDAPDECODINGERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrDecoding)
	Set $$$EnsLDAPStatusGBL($$$XLDAPDECODINGERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrDecoding)
	Set $$$EnsLDAPStatusGBL($$$LDAPFILTERERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrFilter)
	Set $$$EnsLDAPStatusGBL($$$XLDAPFILTERERROR)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrFilter)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOTSUPPORTED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNotSupported)
	Set $$$EnsLDAPStatusGBL($$$XLDAPNOTSUPPORTED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNotSupported)
	Set $$$EnsLDAPStatusGBL($$$LDAPCONTROLNOTFOUND)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrControlNotFound)
	Set $$$EnsLDAPStatusGBL($$$XLDAPCONTROLNOTFOUND)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrControlNotFound)
	Set $$$EnsLDAPStatusGBL($$$LDAPNORESULTSRETURNED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNoResults)
	Set $$$EnsLDAPStatusGBL($$$XLDAPNORESULTSRETURNED)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrNoResults)
	Set $$$EnsLDAPStatusGBL($$$XLDAPMORERESULTSTORETURN)=$LB($$$EnsLDAPStatusOperation,$$$EnsLDAPErrMoreResultsToReturn)

	#;System
	Set $$$EnsLDAPStatusGBL($$$LDAPUNWILLINGTOPERFORM)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrUnwillingToPerform)
	Set $$$EnsLDAPStatusGBL($$$LDAPLOOPDETECT)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrLoopDetect)
	Set $$$EnsLDAPStatusGBL($$$LDAPSORTCONTROLMISSING)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrSortControlMissing)
	Set $$$EnsLDAPStatusGBL($$$LDAPOFFSETRANGEERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrOffSetRange)
	Set $$$EnsLDAPStatusGBL($$$LDAPVIRTUALLISTVIEWERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrVirtualListView)
	Set $$$EnsLDAPStatusGBL($$$LDAPOTHER)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInternal)
	Set $$$EnsLDAPStatusGBL($$$LDAPLOCALERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrLocal)
	Set $$$EnsLDAPStatusGBL($$$XLDAPLOCALERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrLocal)
	Set $$$EnsLDAPStatusGBL($$$LDAPTIMEOUT)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrTimeout)
	Set $$$EnsLDAPStatusGBL($$$XLDAPTIMEOUT)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrTimeout)
	Set $$$EnsLDAPStatusGBL($$$LDAPUSERCANCELLED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrUserCancelled)
	Set $$$EnsLDAPStatusGBL($$$XLDAPUSERCANCELLED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrUserCancelled)
	Set $$$EnsLDAPStatusGBL($$$LDAPPARAMERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrParam)
	Set $$$EnsLDAPStatusGBL($$$XLDAPPARAMERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrParam)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOMEMORY)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrNoMemory)
	Set $$$EnsLDAPStatusGBL($$$XLDAPNOMEMORY)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrNoMemory)
	Set $$$EnsLDAPStatusGBL($$$LDAPCLIENTLOOP)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrClientLoop)
	Set $$$EnsLDAPStatusGBL($$$XLDAPCLIENTLOOP)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrClientLoop)
	Set $$$EnsLDAPStatusGBL($$$LDAPREFERRALLIMITEXCEEDED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrReferralLimit)
	Set $$$EnsLDAPStatusGBL($$$XLDAPREFERRALLIMITEXCEEDED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrReferralLimit)
	Set $$$EnsLDAPStatusGBL($$$LDAPUNSUPPORTEDOPTION)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrUnsupportOption)
	Set $$$EnsLDAPStatusGBL($$$LDAPUNSUPPORTEDFUNCTIONONPLATFORM)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrUnsupportFunction)
	Set $$$EnsLDAPStatusGBL($$$LDAPINSUFFICIENTMEMORYNEWFAILED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInsufficientMemory)
	Set $$$EnsLDAPStatusGBL($$$LDAPINSUFFICIENTMEMORYNEWFAILED1)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInsufficientMemory)
	Set $$$EnsLDAPStatusGBL($$$LDAPINSUFFICIENTMEMORYMALLOCFAILED)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInsufficientMemory)
	Set $$$EnsLDAPStatusGBL($$$LDAPATTRIBUTESTOOBIG)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrAttributesTooBig)
	Set $$$EnsLDAPStatusGBL($$$LDAPINTERNALERROR)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInternal)
	Set $$$EnsLDAPStatusGBL($$$LDAPINTERNALERROR1)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrInternal)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOSUCHSESSION)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrNoSuchSession)
	Set $$$EnsLDAPStatusGBL($$$LDAPNOSUCHENTRY)=$LB($$$EnsLDAPStatusSystem,$$$EnsLDAPErrNoSuchEntry)
}

}
