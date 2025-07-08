/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides information on the JSON Web Algorithms (as defined in RFC 7518) that are 
/// supported by the JSON Web classes (JWS, JWE, JWK, etc.).
/// 
/// This class is intended for internal use by InterSystems IRIS only.
Class %Net.JSON.JWA Extends %RegisteredObject [ System = 4 ]
{

Parameter SignatureAlgorithms = {$lb("HS256","HS384","HS512","RS256","RS384","RS512","ES256","ES384","ES512")};

Parameter EncryptionAlgorithms = {$lb("A128CBC-HS256","A192CBC-HS384","A256CBC-HS512")};

Parameter KeyAlgorithms = {$lb("RSA1_5","RSA-OAEP","A128KW","A192KW","A256KW","dir")};

/// This method takes an algorithm name and returns an object containing information about that algorithm.
/// <br><br>
/// Input parameters:
/// <ul><li>
/// alg - The name of the algorithm to get information about.
/// </li></ul><br>
/// Return value:
/// <ul><li>
/// A %DynamicObject containing the following fields with information about the provided algorithm:
/// <ul><li>"alg":		The algorithm name.</li>
/// <li>	"kty":	    The type of key consumed by this algorithm. The options are:<br>
/// <ul><li>	"oct":		Symmetric key</li>
/// <li>		"RSA":		RSA key</li>
/// <li>		"EC": 		Elliptic curve key</li></ul></li>
/// <li>	"use":		The use for this algorithm. The options are:<br>
/// <ul><li>	"sig":		This algorithm makes or verifies a digital signature or MAC used as a JWS signature.</li>
/// <li>		"enc":		This algorithm encrypts or decrypts the content or the content encryption key (CEK) of a JWE.</li></ul></li>
/// <li>	"key_ops":		The operations for which this algorithm can be used. The options are:<br>
/// <ul><li>	"sign":			This algorithm computes a digital signature or MAC.</li>
/// <li>		"verify":		This algorithm verifies a digital signature or MAC.</li>
/// <li>		"wrapKey":		This algorithm encrypts a content encryption key.</li>
/// <li>		"unwrapKey":	This algorithm decrypts a content encryption key and, if applicable, validates the decryption.</li>
/// <li>		"encrypt":		This algorithm encrypts content.</li>
/// <li>		"decrypt":		This algorithm decrypts content and, if applicable, validates the decryption.</li></ul></li>
/// <li>	"keysize":	    The length in bits of the key this algorithm requires as input.</li>
/// <li>	"hashsize":	    The length in bits of the hash this algorithm outputs.</li></ul>
/// </li></ul><br>
/// Notes:
/// <ul><li>
/// The first four fields in the return object (alg, kty, use, key_ops) and their values are defined in RFC 7517 (JSON Web Keys).
/// This allows the object returned by this method to be used seamlessly in the construction of JWKs.
/// </li><li>
/// The final two fields (keysize, hashsize) and their values are internal to InterSystems IRIS.
/// </li><li>
/// If given an algorithm that is not supported as a JWA, this method will return a null value.
/// </li><li>
/// If given an algorithm with a misspelled name or with characters whose case doesn't match the case of the characters 
/// in the algorithm name defined in RFC 7518, this method will also return a null value.</li></ul>
ClassMethod GetAlgInfo(alg As %String) As %DynamicObject [ Internal ]
{
	If ($get(alg)="") {
		Return ""
	}

	Set algs={
		"HS256":		{"alg":"HS256",			"kty":"oct",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":256,	"hashsize":256},
		"HS384":		{"alg":"HS384",			"kty":"oct",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":384,	"hashsize":384},
		"HS512":		{"alg":"HS512",			"kty":"oct",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":512,	"hashsize":512},
		"RS256":		{"alg":"RS256",			"kty":"RSA",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":2048,	"hashsize":256},
		"RS384":		{"alg":"RS384",			"kty":"RSA",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":2048,	"hashsize":384},
		"RS512":		{"alg":"RS512",			"kty":"RSA",	"use":"sig",	"key_ops":["sign","verify"],		"keysize":2048,	"hashsize":512},
		"ES256":		{"alg":"ES256",			"kty":"EC",		"use":"sig",	"key_ops":["sign","verify"],		"keysize":512,	"hashsize":256},
		"ES384":		{"alg":"ES384",			"kty":"EC",		"use":"sig",	"key_ops":["sign","verify"],		"keysize":768,	"hashsize":384},
		"ES512":		{"alg":"ES512",			"kty":"EC",		"use":"sig",	"key_ops":["sign","verify"],		"keysize":1056,	"hashsize":512},
		"none":			{"alg":"none",			"kty":"",		"use":"sig",	"key_ops":["sign","verify"],		"keysize":0,	"hashsize":0},
		"RSA1_5":		{"alg":"RSA1_5",		"kty":"RSA",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":2048, "hashsize":0},
		"RSA-OAEP":		{"alg":"RSA-OAEP",		"kty":"RSA",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":2048, "hashsize":0},
		"A128KW":		{"alg":"A128KW",		"kty":"oct",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":128,	"hashsize":0},
		"A192KW":		{"alg":"A192KW",		"kty":"oct",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":192,	"hashsize":0},
		"A256KW":		{"alg":"A256KW",		"kty":"oct",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":256,	"hashsize":0},
		"dir":			{"alg":"dir",			"kty":"oct",	"use":"enc",	"key_ops":["wrapKey","unwrapKey"],	"keysize":0,	"hashsize":0},
		"A128CBC-HS256":{"alg":"A128CBC-HS256",	"kty":"oct",	"use":"enc",	"key_ops":["encrypt","decrypt"],	"keysize":128,	"hashsize":256},
		"A192CBC-HS384":{"alg":"A192CBC-HS384",	"kty":"oct",	"use":"enc",	"key_ops":["encrypt","decrypt"],	"keysize":192,	"hashsize":384},
		"A256CBC-HS512":{"alg":"A256CBC-HS512",	"kty":"oct",	"use":"enc",	"key_ops":["encrypt","decrypt"],	"keysize":256,	"hashsize":512}}

	Return algs.%Get(alg)
}

ClassMethod IsAlgRSA(alg As %String, Output algInfo As %DynamicObject) As %Boolean
{
	Set algInfo = ..GetAlgInfo(alg)
	Return $select($isobject(algInfo):algInfo.kty="RSA", 1:0)
}

ClassMethod IsAlgEC(alg As %String, Output algInfo As %DynamicObject) As %Boolean
{
	Set algInfo = ..GetAlgInfo(alg)
	Return $select($isobject(algInfo):algInfo.kty="EC", 1:0)
}

ClassMethod IsAlgSymmetric(alg As %String, Output algInfo As %DynamicObject) As %Boolean
{
	Set algInfo = ..GetAlgInfo(alg)
	Return $select($isobject(algInfo):algInfo.kty="oct", 1:0)
}

ClassMethod IsAlgAsymmetric(alg As %String, Output algInfo As %DynamicObject) As %Boolean
{
	Set algInfo = ..GetAlgInfo(alg)
	Return $case($select($isobject(algInfo):algInfo.kty, 1:""), "RSA":1, "EC":1, :0)
}

}
