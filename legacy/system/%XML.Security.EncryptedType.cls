/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Encryption element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.EncryptedType Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/04/xmlenc#";

Parameter ELEMENTQUALIFIED = 1;

Property EncryptionMethod As %XML.Security.EncryptionMethod;

Property KeyInfo As %XML.Security.KeyInfo(REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLREF = 1);

Property Encoding As %xsd.anyURI(XMLPROJECTION = "attribute");

Property Id As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property MimeType As %String(MAXLEN = "", XMLPROJECTION = "attribute");

Property Type As %xsd.anyURI(XMLPROJECTION = "attribute");

/// If encryption is based on X509 certificate, this is the X509 certificate class.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// Encryption algorithm to use.
/// The default is $$$SOAPWSaes128cbc. 
/// Possible values are $$$SOAPWSaes128cbc, $$$SOAPWSaes192cbc, $$$SOAPWSaes256cbc and $$$SOAPWSaes256gcm.
Property Algorithm As %xsd.anyURI(XMLPROJECTION = "none");

/// Size of key.  This property overrides key size that implied by Algorithm.
Property KeySize As %Integer(XMLPROJECTION = "none");

/// RequireBestEntropy - Require best entropy source for initialization 
/// of key generation.
/// If this parameter equals 1, the function will return an error unless the
/// generator's internal state has been seeded using the best source of true entropy (OS dependent). 
Property RequireBestEntropy As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// The symmetric key to be used for encryption.
Property Key As %Binary(XMLPROJECTION = "none") [ Internal ];

/// Set the key transport algorithm to be used to encrypt the symmetric key.
/// The algorithm is reflected in the Algorithm attribute of the EncryptionMethod element of EncryptedKey.
/// Possible values for algortihm are $$$SOAPWSrsaoaep and $$$SOAPWSrsa15
Method SetEncryptionMethod(algorithm As %String)
{
	If algorithm=$$$SOAPWSrsaoaep {
		Set digest=$$$SOAPWSsha1
	} Else {
		Set digest=""
	}
	
	If ..EncryptionMethod="" {
		Set ..EncryptionMethod=##class(%XML.Security.EncryptionMethod).%New()
	}
	Set ..EncryptionMethod.Algorithm=algorithm
	Set ..EncryptionMethod.DigestMethod.Algorithm=digest
}

/// Initialize the symmetric key based on the specified algorithm.
Method InitializeKey(service As %SOAP.WebBase, algorithm As %String) As %Status [ Internal ]
{
	// Check algorithm and compute key size	
	If ..Algorithm="" {
		If $get(algorithm)="" {
			Set (algorithm,..Algorithm)=$$$SOAPWSaes128cbc
		} ElseIf $case(algorithm,$$$SOAPWShmacsha1:1,$$$SOAPWShmacsha256:1,$$$SOAPWShmacsha384:1,$$$SOAPWShmacsha512:1,:0) {
			Set ..Algorithm=$$$SOAPWSaes256cbc
		} Else {
			Set ..Algorithm=algorithm
		}
	} Else {
		If $case(..Algorithm,$$$SOAPWSaes128cbc:0,$$$SOAPWSaes192cbc:0,$$$SOAPWSaes256cbc:0,$$$SOAPWSaes256gcm:0,:1) {
			$$$SOAPLogSecurity("    Invalid Encryption method specified: "_..Algorithm)
			Quit $$$ERROR($$$WSSECURITYInvalidEncAlgo,..Algorithm)
		}
	}
	
	If ..KeySize'="" {
		Set keysize=..KeySize
	} ElseIf ..Algorithm=$$$SOAPWSaes256cbc {
		Set keysize=256/8
	} ElseIf ..Algorithm=$$$SOAPWSaes192cbc {
		Set keysize=192/8
	} ElseIf ..Algorithm=$$$SOAPWSaes256gcm {
		Set keysize=256/8
	} Else {
		Set keysize=128/8
	}
	If ..Key'="" {
		// If key specified, then use the specified key.
		If $length(..Key)'=keysize {
			$$$SOAPLogSecurity("    Invalid Encryption method specified: "_..Algorithm_"(Does not match key size "_keysize_")")
			Quit $$$ERROR($$$WSSECURITYInvalidEncAlgo,..Algorithm_"(Does not match key size "_keysize_")")
		}
	} Else {
		Set ..Key=$system.Encryption.GenCryptRand(keysize,..RequireBestEntropy)
	}

	Quit $$$OK
}

/// Reset the element.
Method Reset() [ Internal ]
{
	Do ##super()
	
	Set ..Key=""
}

}
