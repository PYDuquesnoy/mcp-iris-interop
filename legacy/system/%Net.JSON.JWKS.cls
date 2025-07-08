/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to create and manage JSON Web Key Sets, as defined in RFC 7517.
Class %Net.JSON.JWKS Extends %RegisteredObject [ System = 4 ]
{

/// This method creates a new JSON Web Key Set (JWKS).
/// <br><br>
/// Output parameters:
/// <ul><li>
/// JWKS - An empty JWKS.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status value indicating whether or not the JWKS was created, where errors indicate that
/// it wasn't created and describe why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This simply creates an empty JWKS.</li></ul>
ClassMethod InitializeJWKS(Output JWKS As %String) As %Status
{
	Set JWKSObj={"keys":[]}
	Set JWKS=JWKSObj.%ToJSON()

	Return $$$OK
}

/// This internal helper method checks that the provided JSON Web Key Set (JWKS) conforms to the
/// specs laid out in RFC 7517 section 5.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWKS - The JWKS to check for validity.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// JWKSObj - The provided JWKS in object form.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the provided JWKS is valid, where error values indicate that the
/// JWKS is not valid and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method checks that the given JWKS exists, is non-null, is in valid JSON format, and contains a
/// "keys" parameter that is an array.
/// </li><li>
/// This method does not check that the contents of the "keys" array are valid JWKs.
/// </li><li>
/// If the provided JWKS is not valid, then JWKSObj will be null.</li></ul>
ClassMethod IsValid(JWKS As %String, Output JWKSObj As %DynamicObject) As %Status [ Internal ]
{
	Set JWKSObj=""

	// An empty JWKS is not valid
	If ($get(JWKS)="") {
		Return $$$ERROR($$$NoJWKS)
	}

	If $isobject(JWKS) {
		Set obj=JWKS
	} Else {
		// A JWKS in invalid JSON format is not valid
		Try {
			Set obj=##class(%DynamicObject).%FromJSON(JWKS)
		} Catch {
			Return $$$ERROR($$$InvalidJWKS)
		}
	}

	// If it is an array, make sure the first element is a valid JWKS
	If $classname(obj) = "%Library.DynamicArray" {
		Set testObj = obj.%Get(0)
	} Else {
		Set testObj = obj
	}
	// A JWKS without the "keys" parameter is not valid
	If (testObj.keys="") {
		Return $$$ERROR($$$JWKSMissingKeys)
	}

	// A JWKS whose "keys" parameter is not an array is not valid
	If testObj.%GetTypeOf("keys")'="array" {
		Return $$$ERROR($$$JWKSInvalidKeysParam)		
	}

	// If here, JWKS is valid so set output value and return
	Set JWKSObj=obj
	Return $$$OK
}

/// This methods adds a JSON Web Key (JWK) to a JSON Web Key Set (JWKS).
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWK - The JWK to add to the JWKS.
/// </li><li>
/// JWKS - The JWKS to add the JWK into.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the provided JWK was added to the JWKS, where error values 
/// indicate that it was not added and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// If JWKS is null, then a new JWKS will be created and the key will be added to it.
/// </li><li>
/// This method does not add a kid to keys when it puts them in the JWKS. In order to use kids, they must be added before the key is added to the JWKS.
/// For example:<br><pre>
/// Set JWK.kid=1
/// Do ##class(%Net.JSON.JWKS).PutJWK(JWK,.JWKS)</pre></li></ul>
ClassMethod PutJWK(JWK As %DynamicObject, ByRef JWKS As %String) As %Status
{
	If '$data(JWK) { 
		Return $$$ERROR($$$NoJWK)
	}

	Set sc=##class(%Net.JSON.JWK).IsValid(JWK)
	If $$$ISERR(sc) {
		Return sc
	}

	Try {
		If ($get(JWKS)="") {
			Set JWKSObj={"keys":[]}
		} Else {
			Set sc=..IsValid(JWKS,.JWKSObj)
			If $$$ISERR(sc) {
				Return sc
			}
		}

		// make sure "kid" is a string
		If JWK.%IsDefined("kid") && (JWK.%GetTypeOf("kid")'="string") {
			Do JWK.%Set("kid",JWK.kid, "string")
		}
		
		Do JWKSObj.keys.%Push(JWK)
		Set JWKS=JWKSObj.%ToJSON()
	} Catch ex {
		Return ex.AsStatus()
	}

	Return $$$OK
}

/// This method returns a JSON Web Key (JWK) that matches the provided algorithm and/or key ID from the given JSON Web Key Set (JWKS).
/// <br><br>
/// Input parameters:
/// <ul><li>
/// alg - The algorithm of the desired JWK.
/// </li><li>
/// kid - The key ID of the desired JWK.
/// </li><li>
/// JWKS - The JWKS to search for the desired key.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// JWK - The JWK that matches the provided algorithm and/or key ID.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the method was able to use the provided inputs to search the given JWKS, where 
/// error values indicate that it was unable to search and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method uses the following criteria, listed in order of priority, to determine which key to return:<ol>
/// <li> alg/kid combination exact match</li>
/// <li> alg (but not kid) match</li>
/// <li> kid match and the key is for an algorithm with the same key type as alg</li>
/// <li> kid match</li></ol>
/// </li><li>
/// If more than one key is found for a given criterium, then the last key that meets that criterium is returned.
/// </li><li>
/// This method will return an error if it finds a key in the JWKS that is not a valid JWK.
/// </li><li>
/// This method will succeed if no key is found for the given alg/kid, but the JWK output value will be emtpy.</li></ul>
ClassMethod GetJWK(alg As %String, kid As %String, JWKS As %String, Output JWK As %DynamicObject) As %Status
{
	Set JWK=""

	Set hasAlg=($get(alg)'="")
	Set hasKid=($get(kid)'="")

	If ('hasAlg && 'hasKid) {
		Return $$$ERROR($$$NoAlgOrKid)
	}

	If '$data(JWKS) {
		Return $$$ERROR($$$NoJWKS)
	}
	Set sc=..IsValid(JWKS,.JWKSObj)
	If $$$ISERR(sc) {
		Return sc
	}

	If $classname(JWKSObj) = "%Library.DynamicObject" {
		Set JWKSArray = [(JWKSObj)]
	} Else {
		Set JWKSArray = JWKSObj
	}

	// Prepare variables to help with search for JWK
	Set resultValue=""
	Set kty=""
	If hasAlg {
		Set algInfo=##class(%Net.JSON.JWA).GetAlgInfo(alg)
		If (algInfo'="") {
			Set kty=algInfo.kty
		}
	}
	Set exactMatch=0, algMatch=0, keyTypeMatch=0

	Set jwksIter = JWKSArray.%GetIterator()
	While jwksIter.%GetNext(,.JWKSObj) {
		// Execute the search
		Set jwkIter=JWKSObj.keys.%GetIterator()	
		While jwkIter.%GetNext(,.value) {
			Set sc=##class(%Net.JSON.JWK).IsValid(value)
			If $$$ISERR(sc) {
				Return $$$ERROR($$$InvalidJWK,value.%ToJSON())
			}
			If hasAlg {
				If (value.alg=alg) {
					If (hasKid && (value.kid=kid)) {
						// If here, we've found an exact alg/kid match so record it
						Set exactMatch=1
						Set resultValue=value
						Continue
					}
					If 'exactMatch {
						// If here, we've found an alg match and we don't have an exact alg/kid match so record this match
						// exactMatch is checked first so that we don't overwrite an exact alg/kid match when we find a match for alg but not kid
						Set algMatch=1
						Set resultValue=value
						Continue
					}
				}
				If hasKid {
					If ((value.kty=kty) && (value.kid=kid)) {
						If ('exactMatch && 'algMatch) {
							// If here, we've found a key type/kid match and no exact alg/kid match or alg match so record this match
							// exactMatch and algMatch are checked first so that we don't overwrite an exact alg/kid match or alg match
							Set keyTypeMatch=1
							Set resultValue=value
							Continue
						}
					}
				}
			}
			If hasKid {
				If (value.kid=kid) {
					If ('exactMatch && 'algMatch && 'keyTypeMatch) {
						// If here, we've found a kid match so record it
						Set resultValue=value
						Continue
					}	
				}
			}
		}
	}
	
	// If a JWK was found, set the output value
	If (resultValue'="") {
		Set JWK=resultValue
	}
	
	Return $$$OK
}

/// This method removes JSON Web Keys (JWK) that match the provided algorithm and/or key ID from a JSON Web Key Set (JWKS).
/// <br><br>
/// Input parameters:
/// <ul><li>
/// alg - The algorithm of the JWKs that are to be removed from the JWKS.
/// </li><li>
/// kid - The key ID of the JWKs that are to be removed from the JWKS.
/// </li><li>
/// JWKS - The JWKS to remove keys from.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the method was able to use the provided inputs to search the given JWKS to
/// attempt to remove keys, where error values indicate that it was unable to search and describe the reason why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// If both alg and kid are defined, this method will remove only those keys that match both alg and kid.
/// </li><li>
/// If only alg is defined, this method will remove all keys for that algorithm.
/// </li><li>
/// If only kid is defined, this method will remove all keys with that key ID.</li></ul>
ClassMethod RemoveJWK(alg As %String, kid As %String, ByRef JWKS As %String) As %Status
{
	Set hasAlg=($get(alg)'="")
	Set hasKid=($get(kid)'="")

	If ('hasAlg && 'hasKid) {
		Return $$$ERROR($$$NoAlgOrKid)
	}

	If '$data(JWKS) {
		Return $$$ERROR($$$NoJWKS)
	}
	Set sc=..IsValid(JWKS,.JWKSObj)
	If $$$ISERR(sc) {
		Return sc
	}

	// Search for matching keys, depending on what combination of alg and kid was provided
	Set iter=JWKSObj.keys.%GetIterator()
	Set toRemove=""
	If (hasAlg && hasKid) {
		// Both alg and kid: find exact matches
		While iter.%GetNext(.key,.value) {
			If ((value.alg=alg) && (value.kid=kid)) {
				Set toRemove=$lb(key)_toRemove
			}
		}
	} ElseIf hasAlg {
		// Only alg: find alg matches
		While iter.%GetNext(.key,.value) {
			If (value.alg=alg) {
				Set toRemove=$lb(key)_toRemove
			}
		}
	} Else {
		// Only kid: find kid matches
		While iter.%GetNext(.key,.value) {
			If (value.kid=kid) {
				Set toRemove=$lb(key)_toRemove
			}
		}
	}

	// Go through the list of keys to remove and remove them
	// The indices of the keys to remove are stored largest to smallest so that the resizing
	// that happens with %DynamicArray:%Remove() doesn't interfere
	Set i=0
	While $listnext(toRemove,i,pos) {
		Do JWKSObj.keys.%Remove(pos)
	}

	Set JWKS=JWKSObj.%ToJSON()
	Return $$$OK
}

}
