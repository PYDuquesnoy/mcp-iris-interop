/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to work with JSON Object Signing and Encryption Headers, as defined
/// in RFC 7515 (and extended in RFC 7516). It also defines the JOSE header parameters that are understood
/// and supported by all JSON Web classes (JWS, JWE, JWK, etc.).
/// 
/// This class is intended for internal use by InterSystems IRIS only.
Class %Net.JSON.JOSE Extends %RegisteredObject [ System = 4 ]
{

/// The registered JOSE header parameters that the JWS/JWE/etc. classes can understand
Parameter JOSESupportedParams [ Internal ] = ",alg,enc,kid,zip,typ,cty,crit,";

/// The extension JOSE header parameters that the JWS/JWE/etc. classes can understand
Parameter JOSESupportedExtensions [ Internal ];

/// This internal helper method ensures that the JOSE header parameters in the provided header object conform to the 
/// specs laid out in RFC 7515 section 4 and (if applicable) RFC 7516 section 4. It also retrieves the key from the 
/// provided JSON Web Key Set that matches the provided header parameters.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// header - The header object whose parameters are being checked.
/// </li><li>
/// JWKS - The JSON Web Key Set that contains the key that corresponds to this header's parameters.
/// </li><li>
/// serialization - The JWS or JWE Serialization format used by the JWS or JWE the provided header is for.
/// Accepted serialization formats are "compact" and "json".
/// </li><li>
/// structure - The JSON web data structure this header is for.
/// Accepted values are "jws" and "jwe".
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// algInfo - An object containing information about the algorithm in the header's "alg" field.
/// </li><li>
/// encInfo - An object containing information about the algorithm in the header's "enc" field.
/// </li><li>
/// JWK - An object representing the JSON Web Key from the provided JWKS that matches the header's "alg" and "kid" fields.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating if the provided header conforms to the specs and the provided JWKS contains a key that can 
/// be used with the algorithm defined in the header's alg field. Success means that the header conforms to the
/// specs and an appropriate key was found in the given JWKS.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// The provided header should be the combination of all of the protected and unprotected headers for a given JWS/JWE.
/// </li><li>
/// If no header is provided, this method will fail.
/// </li><li>
/// If no JWKS is provided this validation will fail unless the header's "alg" value is "none".
/// </li><li>
/// See %Net.JSON.JWA:GetAlgInfo for a description of what the algInfo and encInfo objects contain.
/// </li><li>
/// For a JWS, algInfo will contain information about the algorithm used to sign the JWS.
/// For a JWE, algInfo will contain information about the algorithm used to create or encrypt the CEK.
/// </li><li>
/// For a JWS, encInfo will be empty.
/// For a JWE, encInfo will contain information about the algorithm used to encrypt the content of the JWE.
/// </li><li>
/// For a JWS, JWK will be the key used for signing the JWS.
/// For a JWE, JWK will be the key used for creating or encrypting the CEK.</li></ul>
ClassMethod ValidateHeaderParams(header As %DynamicObject, JWKS As %String, serialization As %String, structure As %String, Output algInfo As %DynamicObject, Output encInfo As %DynamicObject, Output JWK As %DynamicObject) As %Status [ Internal ]
{
    Set algInfo="", encInfo="", JWK=""

    If ($get(header)="") {
        Return $$$ERROR($$$NoHeader)
    }

    If ('$data(serialization)) {
        Return $$$ERROR($$$InvalidSerialization)
    }
    Set serialization=$zconvert(serialization,"L")
    If $case(serialization, "compact":0, "json":0, :1) {
        Return $$$ERROR($$$InvalidSerialization)
    }

    If ('$data(structure)) {
        Return $$$ERROR($$$InvalidStructure)
    }
    Set structure=$zconvert(structure,"L")
    If $case(structure, "jws":0, "jwe":0, :1) {
        Return $$$ERROR($$$InvalidStructure)
    }

    // Make sure that the "alg" parameter is present and the algorithm it denotes is supported.
    Set alg=header.alg
    Set algInfo=##class(%Net.JSON.JWA).GetAlgInfo(alg)
    If (algInfo="") {
		Return $$$ERROR($$$UnsupportedJOSEAlg,alg)
	}
    If (structure="jws") {
        If (algInfo.use'="sig") {
            Return $$$ERROR($$$InvalidSigAlg,alg)
        }
    } ElseIf (structure="jwe") {
        If (algInfo."key_ops".%Get(0)'="wrapKey") {
		    Return $$$ERROR($$$InvalidCEKAlg,alg)
        }
    }

    // Make sure the JWKS contains a key for the given algorithm (and key ID, if present).
    // Note that if the algorithm is "none" there won't be a key so we skip this.
    If (alg'="none") {
        Set kid=header.kid
        If '$data(JWKS) {
            Return $$$ERROR($$$NoJWKS)
        }
        Set sc=##class(%Net.JSON.JWKS).GetJWK(alg,kid,JWKS,.JWK)
        If $$$ISERR(sc) {
            Return sc
        }
        If (JWK="") {
            Return $$$ERROR($$$NoKeyInJWKS,alg,kid)
        }
    }

    // Make sure that if a type value is present, it does not contradict the serialization used.
    Set typ=header.typ
    If ((serialization="compact") && ($zconvert(typ,"L")="jose+json")) {
        Return $$$ERROR($$$CompactSerializationTypeMismatch)
    } ElseIf ((serialization="json") && ($zconvert(typ,"L")="jose")) {
        Return $$$ERROR($$$JSONSerializationTypeMismatch)
    }

    // Make sure any extensions marked as critical are understood by this implementation. If not, return an error.
    Set crit=header.crit
    If (crit'="") {
        Try {
            If (crit.%Size()=0) {
                Return $$$ERROR($$$EmptyJOSECritParam)
            }
            Set iter=crit.%GetIterator()
            While iter.%GetNext(.key,.value) {
                If (..#JOSESupportedExtensions'[(","_key_",")) {
                    Return $$$ERROR($$$UnsupportedJOSEExtension,key)
                }
            }
        } Catch {
            Return $$$ERROR($$$InvalidJOSECritParam)
        }
    }

    // If this header is for a JWE, process the JWE-specific parameters.
    If (structure="jwe") {
        // Make sure that the "enc" parameter is present and the algorithm it denotes is supported.
        Set enc=header.enc
        Set encInfo=##class(%Net.JSON.JWA).GetAlgInfo(enc)
        If (encInfo="") {
            Return $$$ERROR($$$UnsupportedJOSEAlg,enc)
        }
        If (encInfo."key_ops".%Get(0)'="encrypt") {
            Return $$$ERROR($$$InvalidEncAlg,enc)
        }

        // No zip values are supported, so if one is included, return an error.
        Set zip=header.zip
        If (zip'="") {
            Return $$$ERROR($$$UnsupportedJOSEZipParam,zip)
        }
    }

    Return $$$OK
}

/// This internal helper method combines a protected header and up to two unprotected headers into one object.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// protectedHeader - The protected header to combine.
/// </li><li>
/// unprotectedHeader1 - The first unprotected header to combine.
/// </li><li>
/// unprotectedHeader2 - The second unprotected header to combine.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// header - The combined header object.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the headers were successfully combined into one object. Success means that
/// the headers were successfully combined and that no parameters were present in more than one header.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method returns an error if it finds a header parameter that is present in more than one of the headers, as
/// specified in RFC 7515 section 7.2.1 and RFC 7516 section 7.2.1.
/// </li><li>
/// This method can actually take any number of headers. If passed only one header, it will just return that header.</li></ul>
ClassMethod CombineHeaderObjects(protectedHeader As %DynamicObject = "", unprotectedHeader1 As %DynamicObject = "", unprotectedHeader2 As %DynamicObject = "", Output header As %DynamicObject) As %Status [ Internal ]
{
    If ((protectedHeader="") && (unprotectedHeader1="") && (unprotectedHeader2="")) {
        Set header=""
        Return $$$OK
    }

    Try {
        Set header={}
        If (protectedHeader'="") {
            Set iter=protectedHeader.%GetIterator()
            While iter.%GetNext(.key,.value) {
                Do header.%Set(key,value)
            }
        }

        If (unprotectedHeader1'="") {
            Set iter=unprotectedHeader1.%GetIterator()
            While iter.%GetNext(.key,.value) {
                If (header.%IsDefined(key)) {
                    Set header=""
                    Return $$$ERROR($$$DuplicateHeaderParam,key)
                }
                Do header.%Set(key,value)
            }
        }

        If (unprotectedHeader2'="") {
            Set iter=unprotectedHeader2.%GetIterator()
            While iter.%GetNext(.key,.value) {
                If (header.%IsDefined(key)) {
                    Set header=""
                    Return $$$ERROR($$$DuplicateHeaderParam,key)
                }
                Do header.%Set(key,value)
            }
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

}
