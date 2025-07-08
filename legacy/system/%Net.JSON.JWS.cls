/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to sign and validate JSON Web Signatures, as defined in RFC 7515.
Class %Net.JSON.JWS Extends %RegisteredObject [ System = 4 ]
{

/// This method signs a header and payload to make a JWS.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// protectedHeader - The JOSE Protected Header to use.
/// </li><li>
/// unprotectedHeader - The JOSE Unprotected Header to use.
/// </li><li>
/// payload - The message being signed.
/// </li><li>
/// serialization - The JWS Serialization format to use. 
/// Accepted serialization formats are "compact" and "json".
/// The format type determines the structure of the JWS that is created.
/// This defaults to "compact"
/// </li><li>
/// JWKS - The JSON Web Key Set that contains the key that will be used to sign this JWS.
/// This defaults to the null string. 
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// JWS - The JSON Web Signature that is created.
/// If json serialization is used, this will be a valid JSON string. If compact serialization is used it will be a non-JSON string.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not a JWS was created from the inputs. If this method is unable to create a JWS from the inputs
/// it will return an error indicating why this is. 
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method will fail if provided an empty payload.
/// </li><li>
/// If none of the provided headers contains a kid but in the process of creating the JWS a JWK with a kid is used, that kid
/// will be added to the protected header before the JWS is created.
/// </li><li>
/// If the "compact" serialization format is used, the protected header MUST be present and the unprotected header MUST be absent.
/// If the "json" format is used, at least one of the protected header and unprotected header MUST be present and they both CAN be present.
/// </li><li>
/// Only the JWS Compact Serialization and the flattened syntax of the JWS JSON Serialization are supported for signing (not the general 
/// format of the JWS JSON Serialization).
/// </li><li>
/// Using the default JWKS (which is null) will result in an error in all cases except for when the algorithm "none" is used.</li></ul>
ClassMethod Sign(protectedHeader As %DynamicObject, unprotectedHeader As %DynamicObject, payload As %String, serialization As %String = "compact", JWKS As %String = "", Output JWS As %String) As %Status
{
    Set JWS=""

    If ($get(protectedHeader)="") {
        Set protectedHeader={}
    }
    If ($get(unprotectedHeader)="") {
        Set unprotectedHeader={}
    }

    Try {
        Set unprotectedHeaderSize=unprotectedHeader.%Size()
        If ((protectedHeader.%Size()=0) && (unprotectedHeaderSize=0)) {
            Return $$$ERROR($$$NoHeader)
        }
    } Catch {
        Return $$$ERROR($$$InvalidHeader)
    }

    If ($get(payload)="") {
        Return $$$ERROR($$$NoPayload)
    }

    Set serialization=$zconvert(serialization,"L")
    If $case(serialization, "compact":0, "json":0, :1) {
        Return $$$ERROR($$$InvalidSerialization)
    }

    If (serialization="compact") {
        If (unprotectedHeaderSize'=0) {
            Return $$$ERROR($$$UnprotectedHeadersNotAllowedCompact)
        }
        Return ..SignCompact(protectedHeader,payload,JWKS,.JWS)
    } Else {
        Return ..SignJSON(protectedHeader,unprotectedHeader,payload,JWKS,.JWS)
    }
}

/// This method validates a JWS.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWS - The JSON Web Signature to be validated.
/// </li><li>
/// JWKS - The JSON Web Key Set that contains the key that will be used to validate this JWS.
/// This defaults to the null string.
/// </li><li>
/// acceptUnsecured - A boolean value indicating whether or not to accept JWSs that use the algorithm "none".
/// This defaults to false.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// validations - A dynamic array containing information about the validity of the signatures in the JWS.
/// The validations array contains one DynamicObject for each signature in the JWS, each containing the following fields:
/// <ul>
/// <li>"signature":    The signature this DynamicObject contains information about.</li>
/// <li>"valid":        A boolean indicating whether or not the signature is valid.</li>
/// <li>"error":        A string containing any error message that was generating during the checking of the signature.</li></ul>
/// </li></ul<br>
/// Return value:
/// <ul><li>
/// A boolean indicator of whether or not validation succeeded.
/// If the JWS contains multiple signatures, this method will return true as long as at least one of the signatures is valid.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method will not accept an empty JWS. If provided one, it will return false and the validations array will be null.
/// </li><li>
/// This method supports validation for the JWS Compact Serialization and both the flattened and general syntax of the JWS 
/// JSON Serialization.
/// </li><li>
/// Using the default JWKS (which is null) will result in an error in all cases except for when the algorithm "none" was used (and
/// unsecured JWSs are accepted).
/// </li><li>
/// Some applications may only want to consider a JWS with multiple signatures valid if all of the signatures are valid. Since this
/// method only needs one signature to be valid in order to return true, applications that require all signatures to be valid should
/// use the error field of each signature in the validations array to meet their needs. Specifically, they should check to see if
/// any signature's error field is not null. Any signature whose error field is not null failed to validate (which is why it has an
/// error message), so the presence of any non-null error fields means that at least one signature failed to validate.</li></ul>
ClassMethod Validate(JWS As %String, JWKS As %String = "", acceptUnsecured As %Boolean = 0, Output validations As %DynamicArray) As %Boolean
{
    Set validations=""

    If ($get(JWS)="") {
        Return 0
    }

    If ($extract($zstrip(JWS,"<W"))="{") {
        Set serialization="json"
    } Else {
        Set serialization="compact"
    }

    If (serialization="compact") {
        Return ..ValidateCompact(JWS,JWKS,acceptUnsecured,.validations)
    } Else {
        Return ..ValidateJSON(JWS,JWKS,acceptUnsecured,.validations)
    }
}

/// This private method signs and creates a compact serialized JWS. It is a helper method for Sign() above and
/// should never be called on its own. See Sign() for information on the inputs and outputs.
ClassMethod SignCompact(header As %DynamicObject, payload As %String, JWKS As %String, Output JWS As %String) As %Status [ Private ]
{
    Set JWS=""

    // Make sure the header contains the necessary parameters and that the parameters properly conform to the spec
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"compact","jws",.algInfo,,.JWK)
    If $$$ISERR(sc) {
        Return sc
    }

    // If no kid was provided but one is present in the JWK, add it to the header
    If ((header.alg'="none") && (header.kid="") && (JWK.kid'="")) {
        Set header.kid=JWK.kid
    }

    // Turn the header object into the encoded header string value
    Set jsonheader=header.%ToJSON()
    Set utf8header=$zconvert(jsonheader,"O","UTF8")
    Set b64header=$$$BASE64URLENCODE(utf8header)

    // Create the signature over the encoded header and payload and encode it
    Set b64payload=$$$BASE64URLENCODE(payload)
    Set signingInput=b64header_"."_b64payload
    Set sc=..CreateSignature(algInfo,JWK,signingInput,.signature)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64signature=$$$BASE64URLENCODE(signature)

    // Construct the compact JWS and return
    Set JWS=b64header_"."_b64payload_"."_b64signature
    Return $$$OK
}

/// This private method signs and creates a JSON serialized JWS with flattened syntax. It is a helper method for 
/// Sign() above and should never be called on its own. See Sign() for information on the inputs and outputs.
ClassMethod SignJSON(protectedHeader As %DynamicObject, unprotectedHeader As %DynamicObject, payload As %String, JWKS As %String, Output JWS As %String) As %Status [ Private ]
{
    Set JWS="" 

    // Combine the protected and unprotected headers for validation purposes, verifying that no parameters are present in both
    Set sc=##class(%Net.JSON.JOSE).CombineHeaderObjects(protectedHeader,unprotectedHeader,,.header)
    If $$$ISERR(sc) {
        Return sc
    }

    // Make sure that, taken together, the headers contain the necessary parameters and that the parameters properly conform to the spec
    If (unprotectedHeader.crit'="") {
        Return $$$ERROR($$$UnprotectedJOSECritParam)
    }
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"json","jws",.algInfo,,.JWK)
    If $$$ISERR(sc) {
        Return sc
    }

    // If no kid was provided but one is present in the JWK, add it to the header
    If ((header.alg'="none") && (header.kid="") && (JWK.kid'="")) {
        Set protectedHeader.kid=JWK.kid
    }

    // Turn the protected header object into the required string value
    Set b64header=""
    If (protectedHeader.%Size()>0) {
        Set jsonprotectedHeader=protectedHeader.%ToJSON()
        Set utf8protectedHeader=$zconvert(jsonprotectedHeader,"O","UTF8")
        Set b64header=$$$BASE64URLENCODE(utf8protectedHeader)
    }

    // Create the signature over the encoded header and payload and encode it
    Set b64payload=$$$BASE64URLENCODE(payload)
    Set signingInput=b64header_"."_b64payload
    Set sc=..CreateSignature(algInfo,JWK,signingInput,.signature)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64signature=$$$BASE64URLENCODE(signature)

    // Construct the flattened JSON-serialized JWS and return
    Set JWSObj={}
    If (b64header'="") {
        Set JWSObj.protected=b64header
    }
    If (unprotectedHeader.%Size()>0) {
        Set JWSObj.header=unprotectedHeader
    }
    Set JWSObj.payload=b64payload
    Set JWSObj.signature=b64signature
    Set JWS=JWSObj.%ToJSON()

    Return $$$OK
}

/// This private method validates a compact serialized JWS and returns an object containing information on the validation status of the
/// signature in the JWS. It is a helper method for Validate() above and should never be called on its own. See Validate() for information 
/// on the inputs and outputs.
ClassMethod ValidateCompact(JWS As %String, JWKS As %String, acceptUnsecured As %Boolean, Output validations As %DynamicArray) As %Boolean [ Private ]
{
    // Initialize the output value
    Set validations=[]
    Set sigInfoObj={}
    Set sigInfoObj.alg=""
    Set sigInfoObj.type="sig"
    Set sigInfoObj.signature=""
    Set sigInfoObj.header = ""
    Set sigInfoObj.valid=0
    Set sigInfoObj.error=""
    Do validations.%Push(sigInfoObj)

    // Check that the provided string is a compact format JWS
    If ($length(JWS,".")'=3) {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCompactJWS))
        Return 0
    }

    // Identify the header and convert it from an encoded string into an object
    Try {
        Set b64header=$piece(JWS,".",1)
        Set utf8header=$$$BASE64URLDECODE(b64header)
        Set jsonheader=$zconvert(utf8header,"I","UTF8")
        Set header=##class(%DynamicObject).%FromJSON(jsonheader)
        Set sigInfoObj.header=header
    } Catch {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidHeader))
        Return 0
    }

    // Identify and decode the payload
    Try {
        Set b64payload=$piece(JWS,".",2)
        Set payload=$$$BASE64URLDECODE(b64payload)
    } Catch {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidPayload))
        Return 0
    }
    If (payload="") {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoPayload))
        Return 0
    }

    // Identify and decode the signature
    Try {
        Set b64signature=$piece(JWS,".",3)
        Set signature=$$$BASE64URLDECODE(b64signature)
    } Catch {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidSig))
        Return 0
    }

    // Set the signature return value
    Set sigInfoObj.signature=signature

    // Make sure the header contains the necessary parameters and that the parameters properly conform to the spec
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"compact","jws",.algInfo,,.JWK)
    If $$$ISERR(sc) {
        Set sigInfoObj.error=$System.Status.GetErrorText(sc)
        Return 0
    }
    Set sigInfoObj.alg = algInfo.alg

    // Combine the encoded header and encoded payload to get the input to the signing algorithm
    Set signingInput=b64header_"."_b64payload

    // Validate the signature against the signing input and return the result
    Set sc=..VerifySignature(algInfo,JWK,signingInput,signature,acceptUnsecured)
    If $$$ISOK(sc) {
        Set sigInfoObj.valid=1
        Return 1
    } Else {
        Set sigInfoObj.error=$System.Status.GetErrorText(sc)
        Return 0
    }
}

/// This private method validates a JSON serialized JWS and returns an object containing information on the validation status of each
/// signature in the JWS. It is a helper method for Validate() above and should never be called on its own. See Validate() for information 
/// on the inputs and outputs.
ClassMethod ValidateJSON(JWS As %String, JWKS As %String, acceptUnsecured As %Boolean, Output validations As %DynamicArray) As %Boolean [ Private ]
{
    // Initialize the output value
    Set validations=[]
    Set sigInfoObj={}
    Set sigInfoObj.alg=""
    Set sigInfoObj.type="sig"
    Set sigInfoObj.signature=""
    Set sigInfoObj.header=""
    Set sigInfoObj.valid=0
    Set sigInfoObj.error=""
    Do validations.%Push(sigInfoObj)

    Try {    
        Set JWSObj=##class(%DynamicObject).%FromJSON(JWS)
    } Catch {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidJSONJWS))
        Return 0
    }

    // Identify the payload and decode it
    If ('JWSObj.%IsDefined("payload")) {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoPayload))
        Return 0
    }
    Try {
        Set b64payload=JWSObj.payload
        Set payload=$$$BASE64URLDECODE(b64payload)
    } Catch {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidPayload))
        Return 0
    }
    If (payload="") {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoPayload))
        Return 0
    }

    // Identify all of the signature/protected header/unprotected header sets in the JWS JSON object
    // If the JWS uses general syntax JSON Serialization there could be more than one of these
    Set numSigs=..ExtractAllSignatures(JWSObj,.signatureArray)
    If (numSigs=0) {
        Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoSigs))
        Return 0
    }

    // If here, there were no global JWS errors, so the current sigInfoObj contains no useful information
    // Remove the current sigInfoObj from the validations array and kill it so that each signature can have its own
    Do validations.%Pop()
    Kill sigInfoObj
    
    // For each signature/protected header/unprotected header set identified above, verify that the signature is valid 
    Set containsValidSig=0
    For i=1:1:numSigs {
        // Initialize the output value for this signature
        Set sigInfoObj={}
        Set sigInfoObj.alg=""
        Set sigInfoObj.type="sig"
        Set sigInfoObj.signature=""
        Set sigInfoObj.header=""
        Set sigInfoObj.valid=0
        Set sigInfoObj.error=""
        Do validations.%Push(sigInfoObj)

        // Identify and decode the signature
        Try {
            Set b64signature=signatureArray(i,"signature")
            Set signature=$$$BASE64URLDECODE(b64signature)
        } Catch {
            Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidSig))
            Continue
        }
        Set sigInfoObj.signature=signature

        // Identify the protected header
        Set b64protectedHeader=signatureArray(i,"protected")

        // If present, convert the protected header from an encoded string into an object
        If (b64protectedHeader'="") {
            Try {
                Set utf8protectedHeader=$$$BASE64URLDECODE(b64protectedHeader)
                Set jsonprotectedHeader=$zconvert(utf8protectedHeader,"I","UTF8")
                Set protectedHeader=##class(%DynamicObject).%FromJSON(jsonprotectedHeader)
            } Catch {
                Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidProtectedHeader))
                Continue
            }
        } Else {
            Set protectedHeader=""
        }

        // Identify the unprotected header
        Set unprotectedHeader=signatureArray(i,"header")

        // Verify that, if present, the unprotected header conforms to the specs and, if not present, that
        // the protected header is present
        If (unprotectedHeader'="") {
            Try {
                If (unprotectedHeader.crit'="") {
                    Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$UnprotectedJOSECritParam))
                    Continue
                }
            } Catch {
                Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidUnprotectedHeader))
                Continue
            }
        } Else {
            If (protectedHeader="") {
                Set sigInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoJOSEHeader))
                Continue
            }
        }

        // Combine the protected and unprotected header for validation purposes, verifying that no parameters are present in both
        Set sc=##class(%Net.JSON.JOSE).CombineHeaderObjects(protectedHeader,unprotectedHeader,,.header)
        If $$$ISERR(sc) {
            Set sigInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        }
        Set sigInfoObj.header = header

        // Make sure that, taken together, the headers contain the necessary parameters and properly conform to the spec
        Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"json","jws",.algInfo,,.JWK)
        If $$$ISERR(sc) {
            Set sigInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        }
        Set sigInfoObj.alg = algInfo.alg

        // Combine the encoded protected header and payload to get the input to the signing algorithm
        Set signingInput=b64protectedHeader_"."_b64payload

        // Validate the current signature against the signing input and record the result
        Set sc=..VerifySignature(algInfo,JWK,signingInput,signature,acceptUnsecured)
        If $$$ISERR(sc) {
            Set sigInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        } Else {
            Set sigInfoObj.valid=1
            Set containsValidSig=1
        }   
    }

    // Return true if at least one of the signatures successfully validated, otherwise return false
    If (containsValidSig) {
        Return 1
    } Else {
        Return 0
    }
}

/// This private helper method makes the actual signature for the JWS using the provided algorithm information and JSON Web Key.
ClassMethod CreateSignature(algInfo As %DynamicObject, JWK As %DynamicObject, signingInput As %String, Output signature As %String) As %Status [ Private ]
{
    Set signature=""

    Try {
        If (algInfo.use'="sig") {
            Return $$$ERROR($$$InvalidSigAlg,algInfo.alg)
        } ElseIf (algInfo.kty="oct") {
            // Identify the key value from the provided JWK
            Set key=$$$BASE64URLDECODE(JWK.k)

            // Create the signature using the key value from the provided JWK as the encryption key
            Set signature=$System.Encryption.HMACSHA(algInfo.hashsize,signingInput,key)
            If (signature="") {
                Return $$$ERROR($$$SigCreateError)
            }
        } ElseIf (algInfo.kty="RSA") {
            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // Create the signature using the transformed version of the provided JWK as the encryption key
            Set signature=$System.Encryption.RSASHASign(algInfo.hashsize,signingInput,ASN1)
            If (signature="") {
                Return $$$ERROR($$$OAuth2RSASignatureError,$SYSTEM.Encryption.RSAGetLastError())
            }
        } ElseIf (algInfo.kty="EC") {
            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // Create the ASN.1 format signature using the transformed version of the provided JWK as the encryption key
            Set ASN1Sig=$System.Encryption.ECSHASign(algInfo.hashsize,signingInput,ASN1)
            If (ASN1Sig="") {
                Return $$$ERROR($$$OAuth2ECSignatureError,$SYSTEM.Encryption.ECSHAGetLastError())
            }

            // Convert the signature from ASN.1 format to the JWA format required for the JWS
            Set sc=..ECSigASN1toJWA(ASN1Sig,algInfo.hashsize,.JWASig)
            If $$$ISERR(sc) {
                Return sc
            } Else {
                Set signature=JWASig
            }
        } ElseIf (algInfo.alg="none") {
            // When alg "none" used, no signature is created
            Set signature=""
        } Else {
            Return $$$ERROR($$$InvalidSigAlg,algInfo.kty)
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method converts the given ASN.1-format signature output by the kernel code into the JWA-format signature
/// required by the JWS specs.
ClassMethod ECSigASN1toJWA(ASN1Sig As %String, curveSize As %Integer, Output JWASig As %String) As %Status [ Private ]
{
    Set JWASig=""

    Try {
        Set parsedSig=""

		// Get the signature's sequence byte
        Set seqByte=$extract(ASN1Sig,1)
        If ($ASCII(seqByte)'=48) {
            Return $$$ERROR($$$InvalidASN1Seqbyte,seqByte)
        }
        Set parsedSig=parsedSig_seqByte
		Set pos=2

		// Get the overall signature length byte
        Set sigLen=$extract(ASN1Sig,pos)
        Set parsedSig=parsedSig_sigLen
		Set pos=pos+1

		// For P-521 signatures, the overall length might be represented by multiple bytes
        If $ASCII(sigLen)>=128 {
			Set numSigBytes=$ASCII(sigLen)-128
			Set sigLen=0
			For i=1:1:numSigBytes {
				Set currentSigByte=$extract(ASN1Sig,pos)
				Set sigLen=sigLen+$ASCII(currentSigByte)
				Set parsedSig=parsedSig_currentSigByte
				Set pos=pos+1
			}
		}

		// Get the signature's R integer byte
        Set rInt=$extract(ASN1Sig,pos)
		If $ASCII(rInt)'=2 {
			Return $$$ERROR($$$InvalidASN1Rbyte,rInt)
		}
		Set parsedSig=parsedSig_rInt
		Set pos=pos+1

		// Get the signature's R value length byte
        Set rLen=$extract(ASN1Sig,pos)
		Set parsedSig=parsedSig_rLen
		Set pos=pos+1

        // Get the signature's R value
        Set rVal=$extract(ASN1Sig,pos,pos+$ASCII(rLen)-1)
		Set parsedSig=parsedSig_rVal
		Set pos=pos+$ASCII(rLen)

		// Get the signature's S integer byte
        Set sInt=$extract(ASN1Sig,pos)
		If $ASCII(sInt)'=2 {
			Return $$$ERROR($$$InvalidASN1Sbyte,sInt)
		}
		Set parsedSig=parsedSig_sInt
		Set pos=pos+1

		// Get the signature's S value length byte
        Set sLen=$extract(ASN1Sig,pos)
		Set parsedSig=parsedSig_sLen
		Set pos=pos+1

        // Get the signature's S value
        Set sVal=$extract(ASN1Sig,pos,pos+$ASCII(sLen)-1)
		Set parsedSig=parsedSig_sVal 
        
		// Confirm that the parsed signature matches the provided signature
        If parsedSig'=ASN1Sig {
			Return $$$ERROR($$$ASN1SigParsingError)
		}

        // Note the length the signature must be depending on the curve size being used
        Set requiredSigLen=$case(curveSize,256:64,384:96,512:132,:"")

        // The JWA format requires that R and S each be exactly half the length of the signature, 
        // so normalize their length by adding or removing padding bytes as required
        Set rLen=$ASCII(rLen)
        Set rLenDiff=(requiredSigLen/2)-rLen
        If (rLenDiff<0) {
            Set rVal=$extract(rVal,$zabs(rLenDiff)+1,*)
        } ElseIf (rLenDiff>0) {
            For i=1:1:$zabs(rLenDiff) {
                Set rVal=$char(0)_rVal
            }
        }
        Set R=rVal

        Set sLen=$ASCII(sLen)
        Set sLenDiff=(requiredSigLen/2)-sLen
        If (sLenDiff<0) {
            Set sVal=$extract(sVal,$zabs(sLenDiff)+1,*)
        } ElseIf (sLenDiff>0) {
            For i=1:1:$zabs(sLenDiff) {
                Set sVal=$char(0)_sVal
            }
        }
        Set S=sVal

        // The JWA format signature is simply the R value and S value appended together
        Set charJWASig=R_S
    } Catch ex {
        Return ex.AsStatus()
    }

    // Set the output value
    Set JWASig=charJWASig

    Return $$$OK
}

/// This private helper method verifies the given JWS signature using the provided algorithm information and JSON Web Key.
ClassMethod VerifySignature(algInfo As %DynamicObject, JWK As %DynamicObject, signingInput As %String, signature As %String, acceptUnsecured As %Boolean) As %Status [ Private ]
{
    Try {
        If (algInfo.use'="sig") {
            Return $$$ERROR($$$InvalidSigAlg,algInfo.alg)
        } ElseIf (algInfo.kty="oct") {
            // Identify the key value from the provided JWK
            Set key=$$$BASE64URLDECODE(JWK.k)

            // Create the signature using the key value from the provided JWK as the encryption key and compare it to the provided signature
            If ($System.Encryption.HMACSHA(algInfo.hashsize,signingInput,key)'=signature) {
                Return $$$ERROR($$$OAuth2HMACVerificationError)
            }
        } ElseIf (algInfo.kty="RSA") {
            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // Verify the signature using the transformed version of the provided JWK as the encryption key
            If ('$System.Encryption.RSASHAVerify(algInfo.hashsize,signingInput,signature,ASN1)) {
                Return $$$ERROR($$$OAuth2RSAVerificationError,$System.Encryption.RSAGetLastError())
            }
        } ElseIf (algInfo.kty="EC") {
            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // For elliptic curve signatures, the JWA format used in the JWS is different from the ASN.1 format
            // that the kernel requires. So, convert the signature from JWA format to ASN.1 format
            Set sc=..ECSigJWAtoASN1(signature,algInfo.hashsize,.ASN1Sig)
            If $$$ISERR(sc) {
                Return sc
            }

            // Verify the converted signature using the transformed version of the provided JWK as the encryption key
            If ($System.Encryption.ECSHAVerify(algInfo.hashsize,signingInput,ASN1Sig,ASN1)'=1) {
                Return $$$ERROR($$$OAuth2ECVerificationError,$System.Encryption.ECGetLastError())
            }
        } ElseIf (algInfo.alg="none") {
            If 'acceptUnsecured {
                Return $$$ERROR($$$JWSNotSecured)
            }
            If (signature'="") {
                Return $$$ERROR($$$SigNotNull)
            }
        } Else {
            Return $$$ERROR($$$InvalidSigAlg,algInfo.alg)
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method converts the given JWA-format signature into the ASN.1-format signature required by the kernel code.
ClassMethod ECSigJWAtoASN1(JWASig As %String, curveSize As %Integer, Output ASN1Sig As %String) As %Status [ Private ]
{
    Set ASN1Sig=""

    If (($length(JWASig)'=64) && ($length(JWASig)'=96) && ($length(JWASig)'=132)) {
        Return $$$ERROR($$$InvalidSigLen)
    }

    Try {
        // Parse out the R and S components of the signature
        Set JWASigLength=$length(JWASig)
        Set R=$extract(JWASig,1,(JWASigLength/2))
        Set S=$extract(JWASig,(JWASigLength/2)+1,*)

        // If padding bytes were added to either R or S so that the signature would be the right size, take them off
        While ($extract(R,1)=$char(0)) {
            Set R=$extract(R,2,*)
        }
        While ($extract(S,1)=$char(0)) {
            Set S=$extract(S,2,*)
        }

        // If padding bytes were taken off of either R or S so that the signature would be the right size, add them back
        // Also, add back any padding bytes that are needed for the ASN.1 format but were removed in the previous step
        If ($ASCII($extract(R,1))>=128) {
            Set R=$char(0)_R
        }
        If ($ASCII($extract(S,1))>=128) {
            Set S=$char(0)_S
        }

        // Note the length of the signature overall
        Set sigLen=$length(R)+$length(S)+4

        // Construct the ASN.1 format signature
        Set charASN1Sig=$select(curveSize'=512:$char(48,sigLen,2,$length(R))_R_$char(2,$length(S))_S,1:$char(48,129,sigLen,2,$length(R))_R_$char(2,$length(S))_S)
    } Catch ex {
        Return ex.AsStatus
    }

    // Set the output value
    Set ASN1Sig=charASN1Sig

    Return $$$OK
}

/// This private helper method retrieves all of the signatures and protected and unprotected headers
/// from a JSON serialized JWS.
/// It returns the number of signatures found and outputs an array of all of the signatures,
/// protected headers, and unprotected headers found. 
ClassMethod ExtractAllSignatures(JWSObj As %DynamicObject, Output signatureArray) As %Integer [ Private ]
{
    Set signatureArray=""

    If (JWSObj.%IsDefined("signatures")) {
        Return ..ExtractGeneralFormat(JWSObj,.signatureArray)
    } Else {
        Return ..ExtractFlattenedFormat(JWSObj,.signatureArray)
    }
}

/// This private helper method retrieves all of the signatures and protected and unprotected headers from a 
/// JSON serialized JWS that uses general syntax. 
/// It populates a two-dimensional array to store each signature alongside the corresponding protected 
/// and unprotected header and then returns the number of signatures found.
ClassMethod ExtractGeneralFormat(JWSObj As %DynamicObject, Output signatureArray) As %Integer [ Private ]
{
    Set signatureArray=""
    
    Set i=0
    Set iter=JWSObj.signatures.%GetIterator()
    While iter.%GetNext(.key,.sigObj) {
        Do $increment(i)
        Set signatureArray(i,"signature")=sigObj.signature
        Set signatureArray(i,"header")=sigObj.header
        Set signatureArray(i,"protected")=sigObj.protected
    }

    Return i
}

/// This private helper method retrieves the signature and protected and unprotected header from a 
/// JSON serialized JWS that uses flattened syntax. 
/// In order to ensure compatibility with the general syntax of JSON serialized JWSs, this method 
/// populates a two-dimensional array to store the signature alongside the protected and unprotected header. 
/// It then returns the number of signatures found (which will always either be 0 or 1).
ClassMethod ExtractFlattenedFormat(JWSObj As %DynamicObject, Output signatureArray) As %Integer [ Private ]
{
    Set signatureArray=""

    Set signatureArray(1,"signature")=JWSObj.signature
    Set signatureArray(1,"header")=JWSObj.header
    Set signatureArray(1,"protected")=JWSObj.protected
    
    Return 1
}

}
