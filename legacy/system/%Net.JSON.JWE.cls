/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides methods to encrypt and decrypt JSON Web Encryption objects, as defined in RFC 7516.
Class %Net.JSON.JWE Extends %RegisteredObject [ System = 4 ]
{

/// This method encrypts a message and makes a JWE.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// protectedHeader - The JOSE Protected Header to use.
/// </li><li>
/// sharedUnprotectedHeader - The JOSE Shared Unprotected Header to use.
/// </li><li>
/// perRecipientUnprotectedHeader - The JOSE Per-Recipient Unprotected Header to use.
/// </li><li>
/// plaintext - The message being encrypted.
/// </li><li>
/// AAD - any Additional Authenticated Data to input to the content encryption algorithm.
/// This defaults to null.
/// </li><li>
/// serialization - The JWE Serialization format to use. 
/// Accepted serialization formats are "compact" and "json".
/// The format type determines the structure of the JWE that is created.
/// This defaults to "compact"
/// </li><li>
/// JWKS - The JSON Web Key Set that contains the key that will be used to create the content encryption key for this JWE.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// JWE - The JSON Web Encryption that is created.
/// If json serialization is used, this will be a valid JSON string. If compact serialization is used it will be a non-JSON string.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not a JWE was created from the inputs. If this method is unable to create a JWE from the inputs
/// it will return an error indicating why this is. 
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// At least one of the headers must be present and non-null.
/// </li><li>
/// If none of the provided headers contains a kid but in the process of creating the JWE a JWK with a kid is used, that kid
/// will be added to the protected header before the JWE is created.
/// </li><li>
/// This method will fail if provided an empty plaintext.
/// </li><li>
/// If the "compact" serialization format is used, the protected header MUST be present and both unprotected headers MUST be absent.
/// If the "json" format is used, at least one of the protected header and unprotected headers MUST be present and they all CAN be present.
/// </li><li>
/// Only the JWE Compact Serialization and the flattened syntax of the JWE JSON Serialization are supported for encryption (not the general 
/// format of the JWE JSON Serialization).
ClassMethod Encrypt(protectedHeader As %DynamicObject, sharedUnprotectedHeader As %DynamicObject, perRecipientUnprotectedHeader As %DynamicObject, plaintext As %String, AAD As %String = "", serialization As %String = "compact", JWKS As %String, Output JWE As %String) As %Status
{
    Set JWE=""

    If ($get(protectedHeader)="") {
        Set protectedHeader={}
    }
    If ($get(sharedUnprotectedHeader)="") {
        Set sharedUnprotectedHeader={}
    }
    If ($get(perRecipientUnprotectedHeader)="") {
        Set perRecipientUnprotectedHeader={}
    }

    Try {
        Set sharedUprotectedHeaderSize=sharedUnprotectedHeader.%Size()
        Set perRecipientUnprotectedHeaderSize=perRecipientUnprotectedHeader.%Size()
        If ((protectedHeader.%Size()=0) && (sharedUprotectedHeaderSize=0) && (perRecipientUnprotectedHeaderSize=0)) {
            Return $$$ERROR($$$NoHeader)
        }
    } Catch {
        Return $$$ERROR($$$InvalidHeader)
    }

    If ($get(plaintext)="") {
        Return $$$ERROR($$$NoPlaintext)
    }

    If '$data(JWKS) {
        Return $$$ERROR($$$NoJWKS)
    }

    Set serialization=$zconvert(serialization,"L")
    If $case(serialization, "compact":0, "json":0, :1) {
        Return $$$ERROR($$$InvalidSerialization)
    }

    If (serialization="compact") {
        If ((sharedUprotectedHeaderSize'=0) || (perRecipientUnprotectedHeaderSize'=0)) {
            Return $$$ERROR($$$UnprotectedHeadersNotAllowedCompact)
        }
        Return ..EncryptCompact(protectedHeader,plaintext,JWKS,.JWE)
    } Else {
        Return ..EncryptJSON(protectedHeader,sharedUnprotectedHeader,perRecipientUnprotectedHeader,plaintext,AAD,JWKS,.JWE)
    }
}

/// This method decrypts a JWE.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// JWE - The JSON Web Encryption to be decrypted.
/// </li><li>
/// JWKS - The JSON Web Key Set that contains the key that will be used to create the content encryption key needed to validate this JWS.
/// </li></ul><br>
/// Output parameters:
/// <ul><li>
/// plaintext - The decrypted plaintext.
/// </li><li>
/// decryptions - A dynamic array containing information about whether or not each encrypted key in the JWE successfully decrypted the ciphertext.
/// The decryptions array contains one DynamicObject for each encrypted key in the JWE, each containing the following fields:
/// <ul>
/// <li>"encryptedKey": The encrypted key this DynamicObject contains information about.</li>
/// <li>"decrypted":    A boolean indicating whether or not the encrypted key successfully decrypted the ciphertext.</li>
/// <li>"error":        A string containing any error message that was generating during the decryption of the ciphertext.
/// </li></ul></li></ul><br>
/// Return value:
/// <ul><li>
/// A status indicating whether or not the JWE's ciphertext was successfully decrypted. (If there are multiple encrypted keys
/// in the JWE, this method will return a success as long as at least one of the keys successfully decrypts the ciphertext.)
/// If the ciphertext was not successfully decrypted this method will return an error describing why.
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// This method will not accept an empty JWE. If provided one, it will return false and the decryptions array will be null.
/// </li><li>
/// This method supports decryption for the JWE Compact Serialization and both the flattened and general syntax of the JWE
/// JSON Serialization.
/// </li><li>
/// For ease of development, this method returns detailed error messages. However, applications that use this method should take care when
/// passing these errors on to end users, as doing so could allow their application to be used as an oracle for decrypting messages. 
/// Note, in particular, that applications should report formatting errors to the CEK, AAD, and ciphertext of the provided JWE as a single error,
/// as per RFC 7516 section 11.4.
/// </li><li>
/// If the provided JWE contains multiple encrypted keys, this method will succeed and output the plaintext as long as at least one of 
/// the keys successfully decrypted the ciphertext.
/// </li><li>
/// Some applications may only want to consider a JWE with multiple encrypted keys valid if all of the encrypted keys successfully
/// decrypt the ciphertext. Since this method only needs one encrypted key to decrypt the plaintext in order to return the plaintext, 
/// applications that require all encrypted keys to successfully decrypt the ciphertext should use the error field of each encrypted
/// key in the validations array to meet their needs. Specifically, they should check to see if any encrypted key's error field is not 
/// null. Any encrypted key whose error field is not null failed to decrypt the ciphertext (which is why it has an error message), so 
/// the presence of any non-null error fields means that at least one encrypted key failed to decrypt the ciphertext.</li></ul>
ClassMethod Decrypt(JWE As %String, JWKS As %String, Output plaintext As %String, Output decryptions As %DynamicArray) As %Status
{
    Set plaintext="", decryptions=""

    If ($get(JWE)="") {
        Return $$$ERROR($$$NoJWE)
    }

    If ($get(JWKS)="") {
        Return $$$ERROR($$$NoJWKS)
    }

    If ($extract($zstrip(JWE,"<W"))="{") {
        Set serialization="json"
    } Else {
        Set serialization="compact"
    }

    If (serialization="compact") {
        Return ..DecryptCompact(JWE,JWKS,.plaintext,.decryptions)
    } Else {
        Return ..DecryptJSON(JWE,JWKS,.plaintext,.decryptions)
    }
}

/// This private method encrypts and creates a compact serialized JWE. It is a helper method for Encrypt() above and
/// should never be called on its own. See Encrypt() for information on the inputs and outputs.
ClassMethod EncryptCompact(header As %DynamicObject, plaintext As %String, JWKS As %String, Output JWE As %String) As %Status [ Private ]
{
    Set JWE=""

    // Make sure the header contains the necessary parameters and that the parameters properly conform to the spec
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"compact","jwe",.algInfo,.encInfo,.JWK)
    If $$$ISERR(sc) {
        Return sc
    }

    // If no kid was provided but one is present in the JWK, add it to the header
    If ((header.kid="") && (JWK.kid'="")) {
        Set header.kid=JWK.kid
    }

    // Turn the header object into the encoded header string value
    Set jsonheader=header.%ToJSON()
    Set utf8header=$zconvert(jsonheader,"O","UTF8")
    Set b64header=$$$BASE64URLENCODE(utf8header)
    
    // Find or create the content encryption key as required for the CEK algorithm being used
    Set sc=..CreateCEK(algInfo,encInfo,JWK,.CEK)
    If $$$ISERR(sc) {
        Return sc
    }

    // Encrypt the CEK as required and encode the result
    Set sc=..EncryptCEK(algInfo,JWK,CEK,.encryptedCEK)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64encryptedCEK=$$$BASE64URLENCODE(encryptedCEK)

    // All supported content encryption algorithms use AES, so create a random IV of the required length and encode the result
    Set IV=$System.Encryption.GenCryptRand($$$AESBLOCKLEN,1)
    Set b64IV=$$$BASE64URLENCODE(IV)

    // For compact serialized JWEs, the Additional Authenticated Data is just the ASCII representation of the Encoded Protected Header
    Set AAD=b64header

    // Create the ciphertext and authentication tag and encode each
    Set sc=..CreateCiphertext(encInfo,plaintext,CEK,IV,AAD,.ciphertext,.authTag)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64ciphertext=$$$BASE64URLENCODE(ciphertext)
    Set b64authTag=$$$BASE64URLENCODE(authTag)

    // Construct the compact JWE and return
    Set JWE=b64header_"."_b64encryptedCEK_"."_b64IV_"."_b64ciphertext_"."_b64authTag

    Return $$$OK
}

/// This private method encrypts and creates a JSON serialized JWE with flattened syntax. It is a helper method for 
/// Encrypt() above and should never be called on its own. See Encrypt() for information on the inputs and outputs.
ClassMethod EncryptJSON(protectedHeader As %DynamicObject, sharedUnprotectedHeader As %DynamicObject, perRecipientUnprotectedHeader As %DynamicObject, plaintext As %String, JWEAAD As %String, JWKS As %String, Output JWE As %String) As %Status [ Private ]
{
    Set JWE="" 

    // Combine the protected and unprotected headers for validation purposes, verifying that no parameters are present in more than one
    Set sc=##class(%Net.JSON.JOSE).CombineHeaderObjects(protectedHeader,sharedUnprotectedHeader,perRecipientUnprotectedHeader,.header)
    If $$$ISERR(sc) {
        Return sc
    }

    // Make sure that, taken together, the headers contain the necessary parameters and that the parameters properly conform to the spec
    If ((sharedUnprotectedHeader.crit'="") || (perRecipientUnprotectedHeader.crit'="")) {
        Return $$$ERROR($$$UnprotectedJOSECritParam)
    }
    If ((sharedUnprotectedHeader.zip'="") || (perRecipientUnprotectedHeader.zip'="")) {
        Return $$$ERROR($$$UnprotectedJOSEZipParam)
    }
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"json","jwe",.algInfo,.encInfo,.JWK)
    If $$$ISERR(sc) {
        Return sc
    }

    // If no kid was provided but one is present in the JWK, add it to the header
    If ((header.kid="") && (JWK.kid'="")) {
        Set protectedHeader.kid=JWK.kid
    }

    // Turn the protected header object into the required string value
    Set b64header=""
    If (protectedHeader.%Size()>0) {
        Set jsonprotectedHeader=protectedHeader.%ToJSON()
        Set utf8protectedHeader=$zconvert(jsonprotectedHeader,"O","UTF8")
        Set b64header=$$$BASE64URLENCODE(utf8protectedHeader)
    }

    // Find or create the content encryption key as required for the CEK algorithm being used
    Set sc=..CreateCEK(algInfo,encInfo,JWK,.CEK)
    If $$$ISERR(sc) {
        Return sc
    }

    // Encrypt the CEK as required and encode the result
    Set sc=..EncryptCEK(algInfo,JWK,CEK,.encryptedCEK)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64encryptedCEK=$$$BASE64URLENCODE(encryptedCEK)

    // All supported content encryption algorithms use AES, so create a random IV of the required length and encode it
    Set IV=$System.Encryption.GenCryptRand($$$AESBLOCKLEN,1)
    Set b64IV=$$$BASE64URLENCODE(IV)

    // For JSON serialized JWEs, if an AAD is provided the Additional Authenticated Data is the ASCII representation of the 
    // Encoded Protected Header concatenated with the encoded provided AAD. If no AAD is provided, it is just the ASCII
    // representation of the Encoded Protected Header. Note that the AAD field of the JWE will only be populated if an AAD is provided
    Set AAD=b64header
    If (JWEAAD'="") {
        Set AAD=AAD_"."_$$$BASE64URLENCODE(JWEAAD)
        Set b64AAD=$$$BASE64URLENCODE(JWEAAD)
    } Else {
        Set b64AAD=""
    }
    
    // Create the ciphertext and authentication tag and encode each
    Set sc=..CreateCiphertext(encInfo,plaintext,CEK,IV,AAD,.ciphertext,.authTag)
    If $$$ISERR(sc) {
        Return sc
    }
    Set b64ciphertext=$$$BASE64URLENCODE(ciphertext)
    Set b64authTag=$$$BASE64URLENCODE(authTag)

    // Construct the flattened JSON-serialized JWE and return
    Set JWEObj={}
    If (b64header'="") {
        Set JWEObj.protected=b64header
    }
    If (sharedUnprotectedHeader.%Size()>0) {
        Set JWEObj.unprotected=sharedUnprotectedHeader
    }
    If (perRecipientUnprotectedHeader.%Size()>0) {
        Set JWEObj.header=perRecipientUnprotectedHeader
    }
    If (b64encryptedCEK'="") {
        Set JWEObj."encrypted_key"=b64encryptedCEK
    }
    If (b64AAD'="") {
        Set JWEObj.aad=b64AAD
    }
    Set JWEObj.ciphertext=b64ciphertext
    Set JWEObj.iv=b64IV
    Set JWEObj.tag=b64authTag
    Set JWE=JWEObj.%ToJSON()

    Return $$$OK
}

/// This private method decrypts a compact serialized JWE and returns an object containing information on the decryption status of the
/// encrypted key in the JWE. It is a helper method for Decrypt() above and should never be called on its own. See Decrypt() for information 
/// on the inputs and outputs.
ClassMethod DecryptCompact(JWE As %String, JWKS As %String, Output plaintext As %String, Output decryptions As %DynamicArray) As %Status [ Private ]
{
    // Initialize the output values
    Set plaintext=""
    Set decryptions=[]
    Set decryptInfoObj={}
    Set decryptInfoObj.alg=""
    Set decryptInfoObj.enc=""
    Set decryptInfoObj.type="enc"
    Set decryptInfoObj.encryptedKey=""
    Set decryptInfoObj.header=""
    Set decryptInfoObj.decrypted=0
    Set decryptInfoObj.error=""
    Do decryptions.%Push(decryptInfoObj)

    // Check that the provided string is a compact format JWE
    If ($length(JWE,".")'=5) {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCompactJWE))
        Return $$$ERROR($$$InvalidCompactJWE)
    }

    // Identify the header and convert it from an encoded string into an object
    Try {
        Set b64header=$piece(JWE,".",1)
        Set utf8header=$$$BASE64URLDECODE(b64header)
        Set jsonheader=$zconvert(utf8header,"I","UTF8")
        Set header=##class(%DynamicObject).%FromJSON(jsonheader)
        Set decryptInfoObj.header=header
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidHeader))
        Return $$$ERROR($$$InvalidHeader)
    }

    // Identify and decode the CEK
    Try {
        Set b64encryptedKey=$piece(JWE,".",2)
        Set encryptedCEK=$$$BASE64URLDECODE(b64encryptedKey)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidEncryptedKey))
        Return $$$ERROR($$$InvalidEncryptedKey)
    }

    // Identify and decode the initialization vector
    Try {
        Set b64IV=$piece(JWE,".",3)
        Set IV=$$$BASE64URLDECODE(b64IV)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidIV))
        Return $$$ERROR($$$InvalidIV)
    }

    // Identify and decode the ciphertext
    Try {
        Set b64ciphertext=$piece(JWE,".",4)
        Set ciphertext=$$$BASE64URLDECODE(b64ciphertext)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCiphertext))
        Return $$$ERROR($$$InvalidCiphertext)
    }

    // Identify and decode the authentication tag
    Try {
        Set b64authTag=$piece(JWE,".",5)
        Set authTag=$$$BASE64URLDECODE(b64authTag)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidAuthTag))
        Return $$$ERROR($$$InvalidAuthTag)
    }

    // Set the encrypted key return value
    Set decryptInfoObj.encryptedKey=encryptedCEK

    // Make sure the header contains the necessary parameters and that the parameters properly conform to the spec
    Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"compact","jwe",.algInfo,.encInfo,.JWK)
    If $$$ISERR(sc) {
        Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
        Return sc
    }

    Set decryptInfoObj.alg = algInfo.alg
    Set decryptInfoObj.enc = encInfo.alg

    // Decrypt the CEK as required
    Set sc=..DecryptCEK(algInfo,JWK,encryptedCEK,.CEK)
    If $$$ISERR(sc) {
        Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
        Return sc
    }

    // For all supported content encryption algorithms, the CEK contains both the encryption key and MAC key
    // Therefore, confirm that the CEK is the length of two keys
    Set keylen=encInfo.keysize/8
    If ($length(CEK)'=(2*keylen)) {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCEKLen))
        Return $$$ERROR($$$InvalidCEKLen)
    }

    // For compact serialized JWEs, the Additional Authenticated Data is the ASCII representation of the Encoded Protected Header
    Set AAD=b64header

    // Verify the authentication tag, decrypt the ciphertext, and return the result
    Set sc=..DecryptCiphertext(encInfo,ciphertext,authTag,CEK,IV,AAD,.plaintext)
    If $$$ISOK(sc) {
        Set decryptInfoObj.decrypted=1
    } Else {
        Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
    }

    Return sc
}

/// This private method decrypts a JSON serialized JWE and returns an object containing information on the decryption status of each
/// encrypted key in the JWE. It is a helper method for Decrypt() above and should never be called on its own. See Decrypt() for information 
/// on the inputs and outputs.
ClassMethod DecryptJSON(JWE As %String, JWKS As %String, Output plaintext As %String, Output decryptions As %DynamicArray) As %Status [ Private ]
{
    // Initialize the output values
    Set plaintext=""
    Set decryptions=[]
    Set decryptInfoObj={}
    Set decryptInfoObj.alg=""
    Set decryptInfoObj.enc=""
    Set decryptInfoObj.type="enc"
    Set decryptInfoObj.encryptedKey=""
    Set decryptInfoObj.header=""
    Set decryptInfoObj.decrypted=0
    Set decryptInfoObj.error=""
    Do decryptions.%Push(decryptInfoObj)

    Try {
        Set JWEObj=##class(%DynamicObject).%FromJSON(JWE)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidJSONJWE))
        Return $$$ERROR($$$InvalidJSONJWE)
    }
    
    // Identify the ciphertext and decode it
    If ('JWEObj.%IsDefined("ciphertext")) {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoCiphertext))
        Return $$$ERROR($$$NoCiphertext)
    }
    Try {
        Set b64ciphertext=JWEObj.ciphertext
        Set ciphertext=$$$BASE64URLDECODE(b64ciphertext)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCiphertext))
        Return $$$ERROR($$$InvalidCiphertext)
    }

    // Identify the protected header and convert it from an encoded string into an object
    Set b64protectedHeader=JWEObj.protected
    If (b64protectedHeader'="") {
        Try {
            Set utf8protectedHeader=$$$BASE64URLDECODE(b64protectedHeader)
            Set jsonprotectedHeader=$zconvert(utf8protectedHeader,"I","UTF8")
            Set protectedHeader=##class(%DynamicObject).%FromJSON(jsonprotectedHeader)
        } Catch {
            Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidProtectedHeader))
            Return $$$ERROR($$$InvalidProtectedHeader)
        }
    } Else {
        Set protectedHeader=""
    }

    // Identify the shared unprotected header, if present, and verify that it conforms to the spec.
    Set sharedUnprotectedHeader=JWEObj.unprotected
    If (sharedUnprotectedHeader'="") {
        Try {
            If (sharedUnprotectedHeader.crit'="") {
                Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$UnprotectedJOSECritParam))
                Return $$$ERROR($$$UnprotectedJOSECritParam)
            }
            If (sharedUnprotectedHeader.zip'="") {
                Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$UnprotectedJOSEZipParam))
                Return $$$ERROR($$$UnprotectedJOSEZipParam)
            }
        } Catch {
            Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidSharedUnprotectedHeader))
            Return $$$ERROR($$$InvalidSharedUnprotectedHeader)
        }
    }

    // If both shared headers are absent, then the per-recipient unprotected header must be present
    Set needPerRecipientHeader=((sharedUnprotectedHeader="") && (protectedHeader=""))

    // Identify and decode the initialization vector
    Try {
        Set b64IV=JWEObj.iv
        Set IV=$$$BASE64URLDECODE(b64IV)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidIV))
        Return $$$ERROR($$$InvalidIV)
    }

    // Identify and decode the authentication tag
    Try {
        Set b64authTag=JWEObj.tag
        Set authTag=$$$BASE64URLDECODE(b64authTag)
    } Catch {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidAuthTag))
        Return $$$ERROR($$$InvalidAuthTag)
    }

    // For JSON serialized JWEs, the Additional Authenticated Data is the ASCII representation of the Encoded Protected Header
    // concatenated with, if present, the provided encoded JWE AAD
    Set AAD=b64protectedHeader
    Set b64AAD=JWEObj.aad
    If (b64AAD'="") {
        Set AAD=AAD_"."_b64AAD
    }

    // Identify all of the encrypted key/per-recipient unprotected header sets in the JWE JSON object
    // If the JWE uses general syntax JSON serialization there could be more than one of these
    Set numRecipients=..ExtractAllRecipients(JWEObj,.recipientsArray)
    If (numRecipients=0) {
        Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoRecipients))
        Return $$$ERROR($$$NoRecipients)
    }

    // If here, there were no global JWE errors, so the current decryptInfoObj contains no useful information
    // Remove the current decryptInfoObj from the decryptions array and kill it so that each encrypted key can have its own
    Do decryptions.%Pop()
    Kill decryptInfoObj

    // For each encrypted key/per-recipient unprotected header set identified above, decrypt the ciphertext
    Set containsValidDecryption=0
    For i=1:1:numRecipients {
        // Initialize the output value for this recipient
        Set decryptInfoObj={}
        Set decryptInfoObj.alg=""
        Set decryptInfoObj.enc=""
        Set decryptInfoObj.type="enc"
        Set decryptInfoObj.encryptedKey=""
        Set decryptInfoObj.header=""
        Set decryptInfoObj.decrypted=0
        Set decryptInfoObj.error=""
        Do decryptions.%Push(decryptInfoObj)

        // Identify and decode the encrypted CEK
        Try {
            Set b64encryptedKey=recipientsArray(i,"encrypted_key")
            Set encryptedCEK=$$$BASE64URLDECODE(b64encryptedKey)
        } Catch {
            Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidEncryptedKey))
            Continue
        }
        Set decryptInfoObj.encryptedKey=encryptedCEK
        
        // Identify the per-recipient unprotected header
        Set perRecipientUnprotectedHeader=recipientsArray(i,"header")

        // Verify that, if present, the per-recipient unprotected header conforms to the specs and, if not present, 
        // that at least one other header is present
        If (perRecipientUnprotectedHeader'="") {
            Try {
                If (perRecipientUnprotectedHeader.crit'="") {
                    Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$UnprotectedJOSECritParam))
                    Continue
                }
                If (perRecipientUnprotectedHeader.zip'="") {
                    Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$UnprotectedJOSEZipParam))
                    Continue
                }
            } Catch {
                Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidPerRecipientUnprotectedHeader))
                Continue
            }
        } Else {
            If needPerRecipientHeader {
                Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$NoJOSEHeader))
                Continue
            }
        }

        // Combine the protected and unprotected headers for validation purposes, verifying that no parameters are present in more than one
        Set sc=##class(%Net.JSON.JOSE).CombineHeaderObjects(protectedHeader,sharedUnprotectedHeader,perRecipientUnprotectedHeader,.header)
        If $$$ISERR(sc) {
            Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        }
        Set decryptInfoObj.header=header

        // Make sure that, taken together, the headers contain the necessary parameters and properly conform to the spec
        Set sc=##class(%Net.JSON.JOSE).ValidateHeaderParams(header,JWKS,"json","jwe",.algInfo,.encInfo,.JWK)
        If $$$ISERR(sc) {
            Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        }

        Set decryptInfoObj.alg = algInfo.alg
        Set decryptInfoObj.enc = encInfo.alg

        // Decrypt the CEK as required
        Set sc=..DecryptCEK(algInfo,JWK,encryptedCEK,.CEK)
        If $$$ISERR(sc) {
            Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        }

        // For all supported content encryption algorithms, the CEK contains both the encryption key and MAC key
        // Therefore, confirm that the CEK is the length of two keys
        Set keylen=encInfo.keysize/8
        If ($length(CEK)'=(2*keylen)) {
            Set decryptInfoObj.error=$System.Status.GetErrorText($$$ERROR($$$InvalidCEKLen))
            Continue
        }

        // Decrypt the ciphertext and verify the authentication tag
        Set sc=..DecryptCiphertext(encInfo,ciphertext,authTag,CEK,IV,AAD,.decryptedText)
        If $$$ISERR(sc) {
            Set decryptInfoObj.error=$System.Status.GetErrorText(sc)
            Continue
        } Else {
            Set decryptInfoObj.decrypted=1
            Set containsValidDecryption=1
            Set plaintext=decryptedText
        }
    }
    
    // Return with success status if at least one of the recipients successfully decrypted the ciphertext, otherwise return an error
    If containsValidDecryption {
        Return $$$OK
    } Else {
        Return $$$ERROR($$$NoDecryptions)
    }
}

/// This private helper method creates a Content Encryption Key based on the given algorithm information and JWK.
ClassMethod CreateCEK(algInfo As %DynamicObject, encInfo As %DynamicObject, JWK As %DynamicObject, Output CEK As %String) As %Status [ Private ]
{
    Set CEK=""

    Try {
        // We are creating a key for the content encryption algorithm, so use that algorithm's key length
        Set keylen=encInfo.keysize\8

        // If using Direct Encryption, the CEK is the shared symmetric key
        // Otherwise, create a random CEK value
        If (algInfo.alg="dir") {
            Set CEK=$$$BASE64URLDECODE(JWK.k)
        } Else {
            Set CEK=$System.Encryption.GenCryptRand(2*keylen,1)
        }

        // For all supported content encryption algorithms, the CEK contains both the encryption key and MAC key
        // Therefore, it needs to be the length of two keys
        If ($length(CEK)'=(2*keylen)) {
            Return $$$ERROR($$$InvalidCEKLen)
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method encrypts the Content Encryption Key based on the given algorithm information and JWK.
ClassMethod EncryptCEK(algInfo As %DynamicObject, JWK As %DynamicObject, CEK As %String, Output encryptedCEK As %String) As %Status [ Private ]
{
    Set encryptedCEK=""

    Try {
        If (algInfo."key_ops".%Get(0)'="wrapKey") {
            Return $$$ERROR($$$InvalidCEKAlg,algInfo.alg)
        } ElseIf (algInfo.kty="RSA") {
            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // Note the RSA format being used
            If (algInfo.alg="RSA1_5") {
                Set encoding=2
            } Else {
                Set encoding=1
            }

            // Encrypt the CEK using the transformed version of the provided JWK as the encryption key
            Set encryptedCEK=$System.Encryption.RSAEncrypt(CEK,ASN1,"","",encoding)
            If (encryptedCEK="") {
                Return $$$ERROR($$$OAuth2RSAEncryptionError,$System.Encryption.RSAGetLastError())
            }
        } ElseIf (algInfo.kty="oct") {
            // When using "dir" the CEK isn't encrypted
            If (algInfo.alg="dir") {
                Return $$$OK
            }

            // Identify the key value from the provided JWK
            Set sharedKey=$$$BASE64URLDECODE(JWK.k)

            // Encrypt the CEK using the key value from the provided JWK as the encryption key
            Set encryptedCEK=$System.Encryption.AESKeyWrap(CEK,sharedKey)
            If (encryptedCEK="") {
                Return $$$ERROR($$$CEKWrappingError)
            }
        } Else {
            Return $$$ERROR($$$InvalidCEKAlg,algInfo.kty)
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method is what actually encrypts the plaintext using the provided encryption algorithm information and inputs.
/// It outputs both the ciphertext and an authentication tag.
ClassMethod CreateCiphertext(encInfo As %DynamicObject, plaintext As %String, CEK As %String, IV As %String, AAD As %String, Output ciphertext As %String, Output authTag As %String) As %Status [ Private ]
{
    Set ciphertext="", authTag=""

    // Identify the two keys that the CEK contains: the first for creating the authentication tag, the second for the encrypting the plaintext
    Try {
        Set keylen=encInfo.keysize/8
        Set MACKey=$extract(CEK,1,keylen)
        Set encKey=$extract(CEK,keylen+1,2*keylen)
    } Catch {
        Return $$$ERROR($$$InvalidCEKLen)
    }

    // Encrypt the CEK and create the authentication tag
    Try {
        // Determine the input to the encryption algorithm
        // If compression of the plaintext were supported, that would happen here
        Set M=plaintext

        // Compute the ciphertext as required for AES_CBC_HMAC_SHA2 algorithms in RFC 7518 section 5.2.2.1 (since these are the only
        // content encryption algorithms we support)
        Set ciphertext=$System.Encryption.AESCBCEncrypt(M,encKey,IV)

        // Compute the authentication tag as required for AES_CBC_HMAC_SHA2 algorithms in RFC 7518 section 5.2.2.1 (since these are the only
        // content encryption algorithms we support)
        Set hashsize=encInfo.hashsize
        Set AL=$nconvert(8*$length(AAD),"S8",1)
        Set tag=$System.Encryption.HMACSHA(hashsize,AAD_IV_ciphertext_AL,MACKey)
        If (tag="") {
            Return $$$ERROR($$$AuthTagCreationError)
        }
        Set authTag=$extract(tag,1,keylen)
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method decrypts the Content Encryption Key based on the given algorithm information and JWK.
ClassMethod DecryptCEK(algInfo As %DynamicObject, JWK As %DynamicObject, encryptedCEK As %String, Output CEK As %String) As %Status [ Private ]
{
    Set CEK=""

    Try {
        If (algInfo."key_ops".%Get(0)'="wrapKey") {
            Return $$$ERROR($$$InvalidCEKAlg,algInfo.alg)
        } ElseIf (algInfo.alg="dir") {
            // When "dir" used as CEK encryption algorithm, there must not be an encrypted key present
            If (encryptedCEK'="") {
                Return $$$ERROR($$$CEKNotNull)
            }

            // When "dir" used, the CEK is just the shared key in the JWK
            Set CEK=$$$BASE64URLDECODE(JWK.k)
        } ElseIf (algInfo.kty="RSA") {
            // There must be an encrypted key present
            If (encryptedCEK="") {
                Return $$$ERROR($$$MissingEncryptedCEK)
            }

            // Transform the provided JWK into the format understood by the kernel code
            Set sc=##class(%Net.JSON.JWK).JWKtoASN1(JWK,.ASN1)
            If $$$ISERR(sc) {
                Return sc
            }

            // Note the RSA format being used
            If (algInfo.alg="RSA1_5") { 
                Set encoding=2
            } Else {
                Set encoding=1
            }

            // Decrypt the CEK using the transformed version of the provided JWK as the decryption key
            Set CEK=$System.Encryption.RSADecrypt(encryptedCEK,ASN1,"",encoding)
            If (CEK="") {
                Return $$$ERROR($$$OAuth2RSADecryptionError,$System.Encryption.RSAGetLastError())
            }
        } ElseIf (algInfo.kty="oct") {
            // There must be an encrypted key present
            If (encryptedCEK="") {
                Return $$$ERROR($$$MissingEncryptedCEK)
            }

            // Identify the key value from the provided JWK 
            Set sharedKey=$$$BASE64URLDECODE(JWK.k)

            // Decrypt the CEK using the key value from the provided JWK as the decryption key
            Set CEK=$System.Encryption.AESKeyUnwrap(encryptedCEK,sharedKey)
            If (CEK="") {
                Return $$$ERROR($$$CEKUnwrappingError)
            }
        } Else {
            Return $$$ERROR($$$InvalidCEKAlg,algInfo.kty)
        }
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method is what actually decrypts the ciphertext using the provided encryption algorithm information and inputs.
/// Before decrypting the ciphertext, it first verifies the authentication tag.
ClassMethod DecryptCiphertext(encInfo As %DynamicObject, ciphertext As %String, authTag As %String, CEK As %String, IV As %String, AAD As %String, Output plaintext As %String) As %Status [ Private ]
{
    Set plaintext=""

    // Return an error if the JWE's ciphertext is empty
    If (ciphertext="") {
        Return $$$ERROR($$$NoCiphertext)
    }

    // Identify the two keys that the CEK contains: the first for creating the authentication tag, the second for the encrypting the plaintext
    Try {
        Set keylen=encInfo.keysize/8
        Set MACKey=$extract(CEK,1,keylen)
        Set encKey=$extract(CEK,keylen+1,2*keylen)
    } Catch {
        Return $$$ERROR($$$InvalidCEKLen)
    }

    // Decrypt the CEK and verify the authentication tag
    Try {
        // Compute the authentication tag as required for AES_CBC_HMAC_SHA2 algorithms in RFC 7518 section 5.2.2.1 (since these are the only
        // content encryption algorithms we support)
        Set hashsize=encInfo.hashsize
        Set AL=$nconvert(8*$length(AAD),"S8",1)
        Set tag=$System.Encryption.HMACSHA(hashsize,AAD_IV_ciphertext_AL,MACKey)
        Set testTag=$extract(tag,1,keylen)

        // Verify that the computed authentication tag matches the provided authentication tag
        If (testTag'=authTag) {
            Return $$$ERROR($$$InvalidAuthTag)
        }

        // Once the authentication tag is verified, compute the plaintext as required for AES_CBC_HMAC_SHA2 algorithms in RFC 7518 section 
        // 5.2.2.2 (since these are the only content encryption algorithms we support)
        Set plaintext=$System.Encryption.AESCBCDecrypt(ciphertext,encKey,IV)
    } Catch ex {
        Return ex.AsStatus()
    }

    Return $$$OK
}

/// This private helper method retrieves all of the encrypted keys and per-recipient unprotected headers
/// from a JSON serialized JWE.
/// It returns the number of recipients found and outputs an array of all of the encrypted keys and
/// per-recipient unprotected headers found. 
ClassMethod ExtractAllRecipients(JWEObj As %DynamicObject, Output recipientsArray) As %Integer [ Private ]
{
    Set recipientsArray=""

    If (JWEObj.%IsDefined("recipients")) {
        Return ..ExtractGeneralFormat(JWEObj,.recipientsArray)
    } Else {
        Return ..ExtractFlattenedFormat(JWEObj,.recipientsArray)
    }
}

/// This private helper method retrieves all of the encrypted keys and per-recipient unprotected headers from a 
/// JSON serialized JWE that uses general syntax. 
/// It populates a two-dimensional array to store each encrypted key alongside the corresponding per-recipient 
/// unprotected header and then returns the number of recipients found.
ClassMethod ExtractGeneralFormat(JWEObj As %DynamicObject, Output recipientsArray) As %Integer [ Private ]
{
    Set recipientsArray=""

    Set i=0
    Set iter=JWEObj.recipients.%GetIterator()
    While iter.%GetNext(.key,.recipientObj) {
        Do $increment(i)
        Set recipientsArray(i,"header")=recipientObj.header
        Set recipientsArray(i,"encrypted_key")=recipientObj."encrypted_key"
    }

    Return i
}

/// This private helper method retrieves the encrypted key and per-recipient unprotected header from a 
/// JSON serialized JWE that uses flattened syntax. 
/// In order to ensure compatibility with the general syntax of JSON serialized JWEs, this method
/// populates a two-dimensional array to store the encrypted key alongside the per-recipient unprotected header.
/// It then returns the number of recipients found (which will always either be 0 or 1).
ClassMethod ExtractFlattenedFormat(JWEObj As %DynamicObject, Output recipientsArray) As %Integer [ Private ]
{
    Set recipientsArray=""

    Set recipientsArray(1,"header")=JWEObj.header
    Set recipientsArray(1,"encrypted_key")=JWEObj."encrypted_key"
    
    Return 1
}

}
