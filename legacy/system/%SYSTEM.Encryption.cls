/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides class functions to perform data encryption,
/// Base64 encoding, hashing, and generation of message authentication codes.
Class %SYSTEM.Encryption Extends Help [ Abstract, ProcedureBlock, System = 4 ]
{

/// This method performs AES encryption in Galois/Counter mode (GCM).
/// Use with AESGCMDecrypt.
/// <br><br>
/// Input parameters:
/// <br><br>
/// plaintext - String to be encrypted.
/// <br><br>
/// key - Valid AES key.
/// Key must be 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (on Unicode systems, with all character values < 256).<br>
/// When running in FIPS mode, IV must be of length >= 12<br>
/// Note: repeated IVs cause serious vulnerability.
/// <br><br>
/// aad - Additional Associated Data (optional).
/// Additional data associated with the plaintext, also provided during decryption.
/// <br><br>
/// Return value: 16 character tag followed by ciphertext.
/// 
ClassMethod AESGCMEncrypt(plaintext As %String, key As %String, IV As %String, aad As %String = "") As %String
{
	Set isWide=$ZISWIDE(plaintext)
	Set sc = $System.Encryption.AESGCMEncryptInit(key,IV,aad,isWide)
	If $$$ISERR(sc) Quit sc
	Set ciphertext = $System.Encryption.AESGCMEncryptUpdate(plaintext)
	Set tag = $System.Encryption.AESGCMEncryptResult()
	Quit tag_ciphertext
}

/// This method initializes AES encryption in Galois/Counter mode (GCM).
/// Use with AESGCMEncryptUpdate and AESGCMEncryptResult.
/// <br><br>
/// Input parameters:
/// <br><br>
/// key - Valid AES key.
/// Key must be 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (on Unicode systems, with all character values < 256).<br>
/// When running in FIPS mode, IV must be of length >= 12<br>
/// Note: repeated IVs cause serious vulnerability.
/// <br><br>
/// aad - Additional Associated Data (optional).
/// Additional data associated with the plaintext, also provided during decryption.
/// <br><br>
/// iswide (optional) - flag indicating plaintext will include wide chars.
/// 
ClassMethod AESGCMEncryptInit(key As %String, IV As %String, aad As %String, iswide As %Boolean = 0) As %Status [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMEncryptInit(key,IV,aad,iswide)
}

/// This method updates AES encryption in Galois/Counter mode (GCM).
/// Use with AESGCMEncryptInit and AESGCMEncryptResult.
/// <br><br>
/// Input parameters:
/// <br><br>
/// plaintext - String to be encrypted.
/// <br><br>
/// Return value: encrypted ciphertext.
/// 
ClassMethod AESGCMEncryptUpdate(plaintext As %String) As %String [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMEncryptUpdate(plaintext)
}

/// This method retrieves the tag for AES encryption in Galois/Counter mode (GCM).
/// Use with AESGCMEncryptInit and AESGCMEncryptUpdate.
/// <br><br>
/// Return value: encryption tag.
/// 
ClassMethod AESGCMEncryptResult() As %String [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMEncryptResult()
}

/// This method performs AES decryption in Galois/Counter mode (GCM).
/// Use with AESGCMEncrypt.
/// <br><br>
/// Input parameters:
/// <br><br>
/// ciphertext - 16 character tag followed by ciphertext to be decrypted  (on Unicode systems, with all character values < 256).
/// <br><br>
/// key - Valid AES key.
/// Key must be 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (on Unicode systems, with all character values < 256).<br>
/// When running in FIPS mode, IV must be of length >= 12<br>
/// Note: repeated IVs cause serious vulnerability.
/// <br><br>
/// aad - Additional Associated Data (optional).
/// Additional data associated with the plaintext, also provided during encryption.
/// <br><br>
/// wasWide - flag indicating original plaintext included wide chars.
/// <br><br>
/// Return value:  Decrypted original plaintext.
/// 
ClassMethod AESGCMDecrypt(ciphertext As %String, key As %String, IV As %String, aad As %String = "", wasWide As %Boolean = 0) As %String
{
	Set sc = $System.Encryption.AESGCMDecryptInit(key,IV,aad,wasWide)
	If $$$ISERR(sc) Quit sc
	Set plaintext = $System.Encryption.AESGCMDecryptUpdate($E(ciphertext, 17, *))
	Set sc = $System.Encryption.AESGCMDecryptValidate($E(ciphertext, 1, 16))
	If $$$ISERR(sc) Quit sc
	Quit plaintext
}

/// This method initializes AES decryption in Galois/Counter mode (GCM).
/// Use with AESGCMDecryptUpdate and AESGCMDecryptValidate.
/// <br><br>
/// Input parameters:
/// <br><br>
/// key - Valid AES key.
/// Key must be 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (on Unicode systems, with all character values < 256).<br>
/// When running in FIPS mode, IV must be of length >= 12<br>
/// Note: repeated IVs cause serious vulnerability.
/// <br><br>
/// aad - Additional Associated Data (optional).
/// Additional data associated with the plaintext, also provided during encryption.
/// <br><br>
/// wasWide - flag indicating original plaintext included wide chars.
/// 
ClassMethod AESGCMDecryptInit(key As %String, IV As %String, aad As %String = "", wasWide As %Boolean = 0) As %Status [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMDecryptInit(key,IV,aad,wasWide)
}

/// This method updates AES decryption in Galois/Counter mode (GCM).
/// Use with AESGCMDecryptInit and AESGCMDecryptValidate.
/// <br><br>
/// Input parameters:
/// <br><br>
/// ciphertext - String to be decrypted.
/// <br><br>
/// Return value: decrypted plaintext.
/// 
ClassMethod AESGCMDecryptUpdate(plaintext As %String) As %String [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMDecryptUpdate(plaintext)
}

/// This method vaidates the tag for AES decryption in Galois/Counter mode (GCM).
/// Use with AESGCMDecryptInit and AESGCMDecryptValidate.
/// <br><br>
/// Input parameters:
/// <br><br>
/// tag - encryption tag.
/// <br><br>
/// Return value:<br>
/// 1 - AES GCM tag validation passed<br>
/// 0 - AES GCM tag validation did not<br>
/// 
ClassMethod AESGCMDecryptValidate(tag As %String) As %Boolean [ CodeMode = expression, Internal ]
{
$system.Encryption.AESGCMDecryptValidate()
}

/// This method performs AES encryption in Cipher Block Chained (CBC) mode.
/// Use with AESCBCDecrypt.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// plaintext - String to be encrypted.
/// This is padded before encryption to the next mutiple of 16 bytes, using
/// reversible block padding.
/// (See Internet Engineering Task Force Request for Comments 2040 and
/// RSA Laboratories Public-Key Cryptography Standards #7 for more information.)
/// <br><br>
/// key - Valid AES key.
/// Key must be 16, 24, or 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (optional).
/// If this argument is present it must be 16 characters long (on Unicode systems, with all character values < 256).
/// If this argument is omitted (or is an empty string), a null initialization vector is used.
/// <br><br>
/// Return value:  Encrypted ciphertext.
/// <br><br>
/// NOTE:  To AES-CBC encrypt and Base64 encode Unicode strings that may contain wide
/// characters, UTF-8 encode the string first:
/// <br><br>
/// Set text=$ZCONVERT(plaintext,"O","UTF8")<br>
/// Set text=$SYSTEM.Encryption.AESCBCEncrypt(text,key,IV)<br>
/// Set ciphertext=$SYSTEM.Encryption.Base64Encode(text)
/// <br><br>
/// To decode and decrypt, perform these operations in the reverse order:
/// <br><br>
/// Set text=$SYSTEM.Encryption.Base64Decode(ciphertext)<br>
/// Set text=$SYSTEM.Encryption.AESCBCDecrypt(text,key,IV)<br>
/// Set plaintext=$ZCONVERT(text,"I","UTF8")
ClassMethod AESCBCEncrypt(plaintext As %String, key As %String, IV As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.AESCBCEncrypt(plaintext,key,IV)
}

/// This method performs AES decryption in Cipher Block Chained (CBC) mode.
/// Use with AESCBCEncrypt.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// ciphertext - Encrypted ciphertext, as generated by AESCBCEncrypt.
/// <br><br>
/// key - Valid AES key.
/// Key must be 16, 24, or 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (optional).
/// If this argument is present it must be 16 characters long (on Unicode systems, with all character values < 256).
/// If this argument is omitted (or is an empty string), a null initialization vector is used.
/// <br><br>
/// Return value:  Decrypted original plaintext, with block padding removed.
ClassMethod AESCBCDecrypt(ciphertext As %String, key As %String, IV As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.AESCBCDecrypt(ciphertext,key,IV)
}

/// This method performs AES encryption in Cipher Block Chained (CBC) mode on Streams.
/// Use with AESCBCDecryptStream.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// Plaintext  - Stream to be encrypted.
/// The input is padded to the next mutiple of 16 bytes, using
/// reversible block padding.
/// (See Internet Engineering Task Force Request for Comments 2040 and
/// RSA Laboratories Public-Key Cryptography Standards #7 for more information.)
/// <br><br>
/// Ciphertext - Encrypted Stream.
/// <br><br>
/// key - Valid AES key.
/// Key must be 16, 24, or 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (optional).
/// If this argument is present it must be 16 characters long (on Unicode systems, with all character values < 256).
/// If this argument is omitted (or is an empty string), a null initialization vector is used.
/// <br><br>
ClassMethod AESCBCEncryptStream(Plaintext As %Stream.Object, Ciphertext As %Stream.Object, Key As %String, IV As %String) As %Status
{
	Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	Set length=32000
	Set wasWide=0
	If $System.Version.IsUnicode() {
		While 'Plaintext.AtEnd && 'wasWide {
			Set wasWide=$ZISWIDE(Plaintext.Read(length,.sc))
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc
		Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	}
	Set inblock=Plaintext.Read(length,.sc) If $$$ISERR(sc) Quit
	For {
		Set inblock2=Plaintext.Read(length,.sc) If $$$ISERR(sc) Quit
		Set padding='$L(inblock2)
		Set outblock=$System.Encryption.AESCBCEncrypt(inblock,Key,IV,padding,wasWide)
		Set sc=Ciphertext.Write(outblock) If $$$ISERR(sc) Quit
		If (padding) Quit
		Set IV=$E(outblock,*-15,*)
		Set inblock=inblock2
	}
	Quit sc
}

/// This method performs AES decryption in Cipher Block Chained (CBC) mode on Streams.
/// Use with AESCBCEncryptStream.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// Ciphertext - Stream to be decrypted.
/// <br><br>
/// Plaintext - Decrypted Stream, with block padding removed.
/// <br><br>
/// key - Valid AES key.
/// Key must be 16, 24, or 32 characters long (on Unicode systems, with all character values < 256).
/// <br><br>
/// IV - Initialization vector (optional).
/// If this argument is present it must be 16 characters long (on Unicode systems, with all character values < 256).
/// If this argument is omitted (or is an empty string), a null initialization vector is used.
/// <br><br>
ClassMethod AESCBCDecryptStream(Ciphertext As %Stream.Object, Plaintext As %Stream.Object, Key As %String, IV As %String) As %Status
{
	Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	Set length=32000
	Set wasWide=0
	If $System.Version.IsUnicode() {
		While 'Ciphertext.AtEnd && 'wasWide {
			Set wasWide=$ZISWIDE(Ciphertext.Read(length,.sc))
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc
		Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	}
	Set inblock=Ciphertext.Read(length,.sc) If $$$ISERR(sc) Quit
	For {
		Set inblock2=Ciphertext.Read(length,.sc) If $$$ISERR(sc) Quit
		Set padding='$L(inblock2)
		Set outblock=$System.Encryption.AESCBCDecrypt(inblock,Key,IV,padding,wasWide)
		Set sc=Plaintext.Write(outblock) If $$$ISERR(sc) Quit
		If (padding) Quit
		Set IV=$E(inblock,*-15,*)
		Set inblock=inblock2
	}
	Quit sc
}

/// This method performs AES encryption in Cipher Block Chained (CBC) mode
/// using keys managed by InterSystems IRIS and securely stored in shared memory.
/// A random initialization vector is generated for each encryption operation.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// Use with AESCBCManagedKeyDecrypt.
/// <br><br>
/// Input parameters:
/// <br><br>
/// Plaintext - String to be encrypted.
/// This is padded before encryption to the next mutiple of 16 bytes, using
/// reversible block padding.
/// (See Internet Engineering Task Force Request for Comments 2040 and
/// RSA Laboratories Public-Key Cryptography Standards #7 for more information.)
/// <br><br>
/// KeyID - Key identifier.  The specified key must currently be activated.
/// <br><br>
/// Return value:  Encrypted ciphertext with embedded key identifier and initialization vector.
/// <br><br>
/// NOTE:  To AES-CBC encrypt and Base64 encode Unicode strings that may contain wide
/// characters, UTF-8 encode the string first:
/// <br><br>
/// Set text=$ZCONVERT(plaintext,"O","UTF8")<br>
/// Set text=$SYSTEM.Encryption.AESCBCManagedKeyEncrypt(text,key)<br>
/// Set ciphertext=$SYSTEM.Encryption.Base64Encode(text)
/// <br><br>
/// To decode and decrypt, perform these operations in the reverse order:
/// <br><br>
/// Set text=$SYSTEM.Encryption.Base64Decode(ciphertext)<br>
/// Set text=$SYSTEM.Encryption.AESCBCManagedKeyDecrypt(text)<br>
/// Set plaintext=$ZCONVERT(text,"I","UTF8")
ClassMethod AESCBCManagedKeyEncrypt(Plaintext As %String, KeyID As %String) As %String [ CodeMode = expression ]
{
$SYSTEM.Encryption.AESCBCManagedKeyEncrypt(Plaintext, KeyID)
}

/// This method performs AES decryption in Cipher Block Chained (CBC) mode.
/// Use with AESCBCManagedKeyEncrypt.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameter:
/// <br><br>
/// Ciphertext - Encrypted ciphertext, as generated by AESCBCManagedKeyEncrypt.
/// The key used for encryption must currently be activated.
/// <br><br>
/// Return value:  Decrypted original plaintext, with block padding removed.
ClassMethod AESCBCManagedKeyDecrypt(Ciphertext As %String) As %String [ CodeMode = expression ]
{
$SYSTEM.Encryption.AESCBCManagedKeyDecrypt(Ciphertext)
}

/// This method performs AES encryption in Cipher Block Chained (CBC) mode on Streams
/// using keys managed by InterSystems IRIS and securely stored in shared memory.
/// A random initialization vector is generated for each encryption operation.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// Use with AESCBCManagedKeyDecryptStream.
/// <br><br>
/// Input parameters:
/// <br><br>
/// Plaintext  - Stream to be encrypted.
/// The input is padded to the next mutiple of 16 bytes, using
/// reversible block padding.
/// (See Internet Engineering Task Force Request for Comments 2040 and
/// RSA Laboratories Public-Key Cryptography Standards #7 for more information.)
/// <br><br>
/// Ciphertext - Encrypted Stream.
/// <br>
/// Note:  To prevent data corruption on Write, if Ciphertext is a file-based Stream it should be an instance of %Stream.FileBinary.
/// <br><br>
/// KeyID - Key identifier.  The specified key must currently be activated.
/// <br><br>
ClassMethod AESCBCManagedKeyEncryptStream(Plaintext As %Stream.Object, Ciphertext As %Stream.Object, KeyID As %String) As %Status [ ProcedureBlock = 1 ]
{
	Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	Set length=32000
	Set wasWide=0
	If $System.Version.IsUnicode() {
		While 'Plaintext.AtEnd && 'wasWide {
			Set wasWide=$ZISWIDE(Plaintext.Read(length,.sc))
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc
		Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	}
	Set IV=""
	Set inblock=Plaintext.Read(length,.sc) If $$$ISERR(sc) Quit
	For {
		Set inblock2=Plaintext.Read(length,.sc) If $$$ISERR(sc) Quit
		Set padding='$L(inblock2)
		Set outblock=$System.Encryption.AESCBCManagedKeyEncrypt(inblock,KeyID,IV,padding,wasWide)
		Set sc=Ciphertext.Write(outblock) If $$$ISERR(sc) Quit
		if (padding) Quit
		Set IV=$E(outblock,*-15,*)
		Set inblock=inblock2
	}
	Quit sc
}

/// This method performs AES decryption in Cipher Block Chained (CBC) mode on Streams.
/// Use with AESCBCManagedKeyEncryptStream.
/// (See Federal Information Processing Standards Publication 197-upd1
/// and NIST Special Publication 200-38A
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// Ciphertext - Stream to be decrypted, as generated by AESCBCManagedKeyEncryptStream.
/// The key used for encryption must currently be activated.
/// <br><br>
/// Plaintext - Decrypted Stream, with block padding removed.
/// <br><br>
ClassMethod AESCBCManagedKeyDecryptStream(Ciphertext As %Stream.Object, Plaintext As %Stream.Object) As %Status [ ProcedureBlock = 1 ]
{
	Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	Set sc=Plaintext.Rewind() If $$$ISERR(sc) Quit sc
	Set length=32000
	Set wasWide=0
	If $System.Version.IsUnicode() {
		While 'Ciphertext.AtEnd && 'wasWide {
			Set wasWide=$ZISWIDE(Ciphertext.Read(length,.sc))
			 If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc
		Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	}
	Set inblock=Ciphertext.Read(56,.sc) If $$$ISERR(sc) Quit sc
	Set sc=Ciphertext.Rewind() If $$$ISERR(sc) Quit sc
	Set KeyID=$e(inblock,4,3+$a($e(inblock,3)))
	Set IV=""
/// Allow for 56-byte header in first block
	Set length=32000-8
	Set inblock=Ciphertext.Read(length,.sc) If $$$ISERR(sc) Quit
	Set length=32000
	For {
		Set inblock2=Ciphertext.Read(length,.sc) If $$$ISERR(sc) Quit
		Set padding='$L(inblock2)
		Set outblock=$System.Encryption.AESCBCManagedKeyDecrypt(inblock,KeyID,IV,padding,wasWide)
		Set sc=Plaintext.Write(outblock) If $$$ISERR(sc) Quit
		If (padding) Quit
		Set IV=$E(inblock,*-15,*)
		Set inblock=inblock2
	}
	Quit sc
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt instead for new applications.<br><br>
/// Use AES decryption in Electronic Code Book (ECB) mode to decrypt a string.
/// This class method will take an encrypted ciphertext and a key, and return a 
/// decrypted plaintext string. The method will decrypt a ciphertext created by 
/// the AESEncode method.
/// <br><br>
/// Input parameters:
/// <br><br>
/// cipher - This is the encrypted string returned by the AESEncode method. 
/// <br><br>
/// key - Can be any string (8-bit or Unicode) up to 32 characters long. 
/// When using Unicode strings for keys, each character in the string is treated
/// internally as 2 bytes. Thus a 16 character key (32 bytes) is the largest 
/// key which can be used under a Unicode system. Note however, that a 32 
/// character key is allowed to be passed to the function: We simply truncate 
/// it to 16 characters (32 bytes) when generating the cipher. 
/// <br><br>
/// InterSystems IRIS will decrypt the string using either 128/192/256 bit decryption 
/// depending on the size of the key passed to the function. 
/// <br><br>
/// If a 16 byte or less key is passed to the decryption function, it is 
/// padded with nulls ($c(0)) to make it 16 bytes (128 bits) and the decryption 
/// function is called. 
/// <br><br>
/// If a 17-24 byte key is passed to the decryption function, it is padded 
/// with nulls to make it 24 bytes (192 bits), and the decryption function 
/// is called. 
/// <br><br>
/// If a 25-32 byte key is passed to the decryption function, it is padded 
/// with nulls to make it 32 bytes (256 bits) and the decryption function 
/// is called. 
/// <br><br>
/// A key greater than 32 bytes will generate a MAXSTRING error. 
ClassMethod AESDecode(cipher As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESDecode(cipher,key)
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt instead for new applications.<br><br>
/// Use AES encryption in Electronic Code Book (ECB) mode to encrypt a string.
/// This class method provides a native AES encryption. 
/// The AES encryption standard is based on the 
/// Rijndael encryption algorithm. When the text is encrypted it is padded with 
/// nulls ($c(0)) to make the entire text string an even multiple of 16 bytes. 
/// When the ciphertext is decrypted, the decrypted plaintext will contain any trailing 
/// nulls which were used for padding, so a strict string comparison of before 
/// encryption and after encryption may fail because of the trailing nulls on 
/// the decrypted string. Therefore it is recomended that the user of this 
/// function perform their own padding to an even multiple of 16 bytes. 
/// This method returns a ciphertext which is an even multiple of 16 bytes.
/// If a Unicode string (i.e. string containing 
/// characters with ASCII values > 255) is encrypted by this method, it will not 
/// be able to be decrypted by software outside of InterSystems IRIS. However, the string 
/// will be able to be encrypted/decrypted within InterSystems IRIS.
/// <br><br>
/// Input parameters:
/// <br><br>
/// text - Can be any string (8-bit or Unicode) up to 12,000 characters long. 
/// A string longer than 12,000 bytes will generate a MAXSTRING error. 
/// Since encryption is performed on 16 byte quantities, when the string is 
/// encrypted it is padded with nulls ($c(0)) to the next higher multiple 
/// of 16 bytes. 
/// <br><br>
/// key - Can be any string (8-bit or Unicode) up to 32 characters long. 
/// When using Unicode strings for keys, each character in the string is treated
/// internally as 2 bytes. Thus a 16 character key (32 bytes) is the largest 
/// key which can be used under a Unicode system. Note however, that a 32 
/// character key is allowed to be passed to the function: We simply truncate 
/// it to 16 characters (32 bytes) when generating the cipher. 
/// <br><br>
/// InterSystems IRIS will encrypt the string using either 128/192/256 bit encryption 
/// depending on the size of the key passed to the function. 
/// <br><br>
/// If a 16 byte or less key is passed to the encryption function, it is 
/// padded with nulls ($c(0)) to make it 16 bytes (128 bits) and the encryption 
/// function is called. 
/// <br><br>
/// If a 17-24 byte key is passed to the encryption function, it is padded 
/// with nulls to make it 24 bytes (192 bits), and the encryption function 
/// is called. 
/// <br><br>
/// If a 25-32 byte key is passed to the encryption function, it is padded 
/// with nulls to make it 32 bytes (256 bits) and the encryption function 
/// is called. 
/// <br><br>
/// A key greater than 32 bytes will generate a MAXSTRING error. 
ClassMethod AESEncode(text As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESEncode(text,key)
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt instead for new applications.<br><br>
/// This class methods provide an AES encryption which is compatible only within InterSystems IRIS instances. When the string is encrypted, a header is embedded in the encrypted string which contains a CRC of the text, and the length of the $c(0) padding required to make it an even multiple of 16 bytes. When the cipher is decrypted, trailing $c(0)'s are automatically removed, and the CRC of the decrypted string is checked against the header. If they don't match an ILLEGAL VALUE error is generated. This encryption method is less secure than the native RijndaelEncode method since the generation of the ILLEGAL VALUE error will give an indication of whether a decryption succeded or not. However, it does provide for automatic $c(0) handling, and verifies that the decryption did succeed especially if the encrypted data is passed across an unreliable transport medium.
ClassMethod AESCRCEncode(text As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESCRCEncode(text,key)
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt instead for new applications.<br><br>
/// This class methods will decrypt a cipher created by the AESCRCEncode method. When the cipher is decrypted, trailing nulls ($c(0)) are removed from the text, and the crc embedded in the header is checked against the crc of the decrypted string. If they do not match, the string was not successfully decrypted,  and an  ILLEGAL VALUE error is generated. 
/// 
ClassMethod AESCRCDecode(text As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESCRCDecode(text,key)
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt with Base64Encode and Base64Decode instead for new applications.<br><br>
/// This class method is the same as the AESCRCEncode method, with the additional feature that is will take the encrypted string and encode it in base64 format.
ClassMethod AESBase64Encode(text As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESBase64Encode(text,key)
}

/// **DEPRECATED**<br>
/// Use AESCBCEncrypt and AESCBCDecrypt with Base64Encode and Base64Decode instead for new applications.<br><br>
/// This class method is the same as the AESCRCDecode method, with the additional feature that is will first decode the base 64 string, and then decrypt the result. It will only decode ciphers created with the RijndaelBase64Encode method.
ClassMethod AESBase64Decode(cipher As %String, key As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.AESBase64Decode(cipher,key)
}

/// This method performs Base 32 encoding.
/// Use with Base32Decode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameter:
/// <br>
/// Text - String to be encoded<br>
/// Flags - 0 - Pad result with "=" to create an octet (Default).<br>
/// Flags - 1 - Do not pad result with "=".<br>
/// <br><br>
/// Return value:  Encoded string.<br><br>
/// Note: Base 32 encoding is not able to encode a string which contains Unicode (2 byte) characters. If you need
/// to Base 32 encode a Unicode string, you should first translate the string to UTF8 format, then encode it.<br><br>
/// s BinaryText=$ZCONVERT(UnicodeText,"O","UTF8")<br>
/// s Base32Encoded=$system.Encryption.Base32Encode(BinaryText)<br>
/// Now to Decode it:<br>
/// s BinaryText=$system.Encryption.Base32Decode(Base32Encoded)<br>
/// s UnicodeText=$ZCONVERT(BinaryText,"I","UTF8")<br>
ClassMethod Base32Encode(Text As %String, Flags As %Integer = 0) As %String [ CodeMode = expression ]
{
$system.Encryption.Base32Encode(Text,Flags)
}

/// This method performs Base 32 decoding.
/// Use with Base32Encode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameters:
/// <br>
/// Text - Encoded string, as generated by Base32Encode.<br>
/// Flags - 0 - Text must be a fully padded "=" octet.<br>
/// Flags - 1 - Text may not be padded, may contain spaces or "-". Text may also be mixed case. Text
/// entered as 0,1,8 are translated to O,L,B before decoding.
/// <br><br>
/// Return value:  Decoded original string.
ClassMethod Base32Decode(Text As %String, Flags As %Integer = 0) As %String [ CodeMode = expression ]
{
$system.Encryption.Base32Decode(Text,Flags)
}

/// This method performs Base 32 Hex encoding.
/// Use with Base32HexDecode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameter:
/// <br>
/// Text - String to be encoded<br>
/// Flags - 0 - Pad result with "=" to create an octet (Default).<br>
/// Flags - 1 - Do not pad result with "=".<br>
/// <br><br>
/// Return value:  Encoded string.<br><br>
/// Note: Base 32 Hex encoding is not able to encode a string which contains Unicode (2 byte) characters. If you need
/// to Base 32 encode a Unicode string, you should first translate the string to UTF8 format, then encode it.<br><br>
/// s BinaryText=$ZCONVERT(UnicodeText,"O","UTF8")<br>
/// s Base32HexEncoded=$system.Encryption.Base32HexEncode(BinaryText)<br>
/// Now to Decode it:<br>
/// s BinaryText=$system.Encryption.Base32HexDecode(Base32HexEncoded)<br>
/// s UnicodeText=$ZCONVERT(BinaryText,"I","UTF8")<br>
ClassMethod Base32HexEncode(Text As %String, Flags As %Integer = 0) As %String [ CodeMode = expression ]
{
$system.Encryption.Base32HexEncode(Text,Flags)
}

/// This method performs Base 32 Hex decoding.
/// Use with Base32HexEncode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameters:
/// <br>
/// Text - Encoded string, as generated by Base32HexEncode.<br>
/// Flags - 0 - Text must be a fully padded "=" octet.<br>
/// Flags - 1 - Text may not be padded, may contain spaces or "-". Text may also be mixed case. 
/// <br><br>
/// Return value:  Decoded original string.
ClassMethod Base32HexDecode(Text As %String, Flags As %Integer = 0) As %String [ CodeMode = expression ]
{
$system.Encryption.Base32HexDecode(Text,Flags)
}

/// This method performs Base64 encoding.
/// Use with Base64Decode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameter:
/// <br>
/// Text - String to be encoded<br>
/// Flags - 0 - Insert CR/LF after every 76 characters (Default)<br>
/// Flags - 1 - Do not insert CR/LF after every 76 characters. Note: To fulfil RFC 4648, set parameter Flags to 1 - Do not insert CR/LF after every 76 characters.<br>
/// <br><br>
/// Return value:  Encoded string.<br><br>
/// Note: Base 64 encoding is not able to encode a string which contains Unicode (2 byte) characters. If you need
/// to Base 64 encode a Unicode string, you should first translate the string to UTF8 format, then encode it.<br><br>
/// s BinaryText=$ZCONVERT(UnicodeText,"O","UTF8")<br>
/// s Base64Encoded=$system.Encryption.Base64Encode(BinaryText)<br>
/// Now to Decode it:<br>
/// s BinaryText=$system.Encryption.Base64Decode(Base64Encoded)<br>
/// s UnicodeText=$ZCONVERT(BinaryText,"I","UTF8")<br>
ClassMethod Base64Encode(Text As %String, Flags As %Integer = 0) As %String [ CodeMode = expression ]
{
$system.Encryption.Base64Encode(Text,Flags)
}

/// This method performs Base64 decoding.
/// Use with Base64Encode.
/// (See RFC 4648 for more information.)
/// <br><br>
/// Input parameter:
/// <br>
/// Text - Encoded string, as generated by Base64Encode.
/// <br><br>
/// Return value:  Decoded original string.
ClassMethod Base64Decode(Text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.Base64Decode(Text)
}

/// This is a deterministic cryptographic pseudorandom number generator compliant with
/// FIPS 140-3 requirement SP 800-107 "Recommendation for Applications Using Approved Hash 
/// Algorithms" Section 5.5 Random Number (Bit) Generation, which points to SP 800-90A for 
/// approved random bit generators. <br>
/// This implementation is based on the deterministic random bit generator (DRBG) model as 
/// described in [NIST SP 800-90A Rev. 1].
/// <br><br>
/// Input parameters:
/// <br><br>
/// Length - Length of random string to generate.<br><br>
/// RequireBestEntropy - Require best entropy source for initialization (optional).
/// If this parameter equals 1, the function will return an error unless the
/// generator's internal state has been seeded using the best source of true entropy (OS dependent). 
/// <br><br>
/// Return value:  Random string.  (On Unicode systems all values are < 256.)
ClassMethod GenCryptRand(Length As %Integer, RequireBestEntropy As %Boolean) As %String [ CodeMode = expression ]
{
$system.Encryption.GenCryptRand(Length,RequireBestEntropy)
}

/// GenCryptToken() generates a random eight character numeric string which is to be used as a one-shot security token.
/// The user has only one attempt to enter this token after which it must be discarded. It is composed of numerics only 
/// as it was found that users often made errors entering alphanumeric tokens.
/// Return value:  8-character numeric security token
ClassMethod GenCryptToken() As %String [ CodeMode = expression ]
{
$translate($justify($zla($system.Encryption.GenCryptRand(4))#99999999,8)," ","0")
}

/// Calculate a checksum for a numeric string.<br>
/// This method will calculate a checksum for a numeric string using the Luhn Algorithm.<br>
/// More details about the algorithm can be found at http://en.wikipedia.org/wiki/Luhn_algorithm<br>
/// <br><br>
/// Input parameter:
/// <br>
/// Text - String containing nothing but numbers.<br>
/// <br><br>
/// Return value:  1 character string containing the checksum.<br>
/// <br>
/// Examples:<br>
/// s CheckSum=$SYSTEM.Encryption.LuhnCheckSum("37127922268703")<br>
/// CheckSum=1<br>
/// s Validate=$SYSTEM.Encryption.LuhnValidate("371279222687031")<br>
/// Validate=1<br>
ClassMethod LuhnCheckSum(text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.LuhnCheckSum(text)
}

/// Validate that a numeric string passes the Luhn Algorithm.<br>
/// This method will validate that a numeric string passes the Luhn Algorithm.<br>
/// This algorithm is typically used to validate the entry of credit card numbers.<br>
/// More details about the algorithm can be found at http://en.wikipedia.org/wiki/Luhn_algorithm<br>
/// <br><br>
/// Input parameter:
/// <br>
/// Text - String containing nothing but numbers.<br>
/// <br><br>
/// Return values:<br>  
/// 0 - String does not pass the Luhn Algorithm.<br>
/// 1 - String passes the Luhn Algorithm.<br>
/// <br>
/// Examples:<br>
/// s CheckSum=$SYSTEM.Encryption.LuhnCheckSum("37127922268703")<br>
/// CheckSum=1<br>
/// s Validate=$SYSTEM.Encryption.LuhnValidate("371279222687031")<br>
/// Validate=1<br>
/// s Validate=$SYSTEM.Encryption.LuhnValidate("371279222687039")<br>
/// Validate=0<br>
ClassMethod LuhnValidate(text As %String) As %Boolean [ CodeMode = expression ]
{
$system.Encryption.LuhnValidate(text)
}

/// An HMAC-Based One-Time Password Algorithm.<br>
/// This change implements the the HOTP algorithm which is an HMAC-Based One-Time 
/// Password Algorithm. The specification for the algorithm is found in RFC 4226.<br>
/// https://tools.ietf.org/html/rfc4226<br><br>
/// Parameters:<br>
/// Secret - Text string shared between the client and authentication module, typically 160 bits.<br>
/// MovingFactor - The counter, time, or other value that changes on a per use basis.<br>
/// CodeDigits - (default 6) Number of digits to return in the HOTP value. Must be between 6 and 8.<br>
/// AddCheckSum - 0/1 (default 0) - Whether a Luhn Checksum should be added to the end of the HOTP value. 
/// If 1, then the number of digits returned is CodeDigits+1.<br>
/// TruncationOffset - (default 19, dynamic truncation) the offset into the MAC result to begin truncation.
/// If this value is out of the range of 0 ... 15, then dynamic truncation  will be used.
/// Dynamic truncation is when the last 4 bits of the last byte of the MAC are used to 
/// determine the start offset.
/// 
ClassMethod HOTP(Secret As %String, MovingFactor As %Integer, CodeDigits As %Integer = 6, AddCheckSum As %Boolean = 0, TruncationOffset As %Integer = 19) As %String [ CodeMode = expression ]
{
$system.Encryption.HOTP(Secret,MovingFactor,CodeDigits,AddCheckSum,TruncationOffset)
}

/// Generate a TOTP: Time-Based One-Time Password.<br>
/// This method implements the the TOTP algorithm which is an HMAC-Based One-Time 
/// Password Algorithm. The specification for the algorithm is found in RFC 6238.<br>
/// https://tools.ietf.org/html/rfc6238<br><br>
/// Parameters:<br>
/// Secret - Text string shared between the client and authentication module, typically 160 bits.<br>
/// UTCTimeStamp - (default - current $ZTIMESTAMP) UTC time in $H format used to calculate the password.<br>
/// TimeStep -  (default - 30) Waiting time in seconds until the next password is generated.
/// See section 5.2. Validation and Time-Step Size in RFC 6238 for how this value is used.<br>
/// CodeDigits - (default 6) Number of digits to return in the HOTP value. Must be between 6 and 8.<br>
/// AddCheckSum - 0/1 (default 0) - Whether a Luhn Checksum should be added to the end of the HOTP value. 
/// If 1, then the number of digits returned is CodeDigits+1. Note that if a check sum is added,
/// it must be removed from the TOTP value before the Validate() method is called.<br>
/// TruncationOffset - (default 19, dynamic truncation) the offset into the MAC result to begin truncation.
/// If this value is out of the range of 0 ... 15, then dynamic truncation  will be used.
/// Dynamic truncation is when the last 4 bits of the last byte of the MAC are used to 
/// determine the start offset. This is typically not used.<br>
/// Notes:<br>
/// Typically the only parameter passed into this method is the Secret, and the default taken for
/// all the other parameters.<br><br>
/// Examples:<br>
/// Generate a TOTP password for the current time. This generates a 6 digit TOTP value which
/// will pass the TOTPValidate() method for between 61 and 90 seconds (3 TimeStepLimits * 30).<br>
/// s TOTP=$SYSTEM.Encryption.TOTP("12345678901234567890")<br>
/// s Valid=$SYSTEM.Encryption.TOTPValidate(TOTP,"12345678901234567890")<br>
/// Generate a TOTP password for the current time. This generates an 8 digit TOTP value which
/// will pass the TOTPValidate() method for between 61 and 90 seconds (3 TimeStepLimits * 30).
/// Note that if the TimeStep and CodeDigits parameters are specified, then these same values
/// must also be used in the TOTPValidate() method.<br>
/// s TOTP=$SYSTEM.Encryption.TOTP("12345678901234567890",,,8)<br>
/// s Valid=$SYSTEM.Encryption.TOTPValidate(TOTP,"12345678901234567890",,,,8)<br><br>
ClassMethod TOTP(Secret As %String, UTCTimeStamp As %String = {$ztimestamp}, TimeStep As %Integer = 30, CodeDigits As %Integer = 6, AddCheckSum As %Boolean = 0, TruncationOffset As %Integer = 19) As %String [ ProcedureBlock = 1 ]
{
#;Get the number of seconds since the Unix Epoch
 s Seconds=+UTCTimeStamp-47117*(60*60*24)+$p($p(UTCTimeStamp,",",2),".")
#;The counter changes every TimeStep seconds
 s Counter=(Seconds\TimeStep)
 q $system.Encryption.HOTP(Secret,Counter,CodeDigits,AddCheckSum,TruncationOffset)
}

/// Validate TOTP: Time-Based One-Time Password.<br>
/// This method validates a TOTP Time-Based One-Time Password. 
/// The TOTP password generation specification is RFC 6238.<br>
/// https://tools.ietf.org/html/rfc6238<br><br>
/// Parameters:<br>
/// TOTP - Time-Based one-time password to validate.<br>
/// Secret - Text string shared between the client and authentication module, typically 160 bits.<br>
/// TOTPLastValidPasswords - Comma delimited string of valid TOTP passwords which were entered by the user.
/// Once a TOTP password is used once, it can't be used again within the time Step. You must pass in the 
/// last TimeStepLimit number of valid TOTP passwords. So If TimeStepLimit is 3, you must pass in the
/// last 3 valid TOTP passwords to this call in the format "PW1,PW2,PW3" where PW1 is the oldest PW..<br>
/// UTCTimeStamp - (default - current $ZTIMESTAMP) UTC time in $H format used to calculate the password.<br>
/// TimeStep - (default - 30) Waiting time in seconds until the next password is generated.<br>
/// See section 5.2. Validation and Time-Step Size in RFC 6238 for how this value is used.<br>
/// TimeStepLimit - (default - 3) Number of time steps a password is valid for.<br>
/// See section 5.2. Validation and Time-Step Size in RFC 6238 for how this value is used.<br>
/// CodeDigits - (default 6) Number of digits to use in generating and comparing the TOTP value. Must be between 6 and 8.<br>
/// AddCheckSum - 0/1 (default 0) - Whether a Luhn Checksum should be added to the end of the TOTP value. 
/// If 1, then the number of digits returned is CodeDigits+1.<br>
/// TruncationOffset - (default 19, dynamic truncation) the offset into the MAC result to begin truncation.
/// If this value is out of the range of 0 ... 15, then dynamic truncation  will be used.
/// Dynamic truncation is when the last 4 bits of the last byte of the MAC are used to 
/// determine the start offset. This is typically not used.<br><br>
/// This method can be used as an authentication method with Google Authenticator. First create a 
/// unique 160 bit secret as follows:<br><br>
/// Set Secret=$System.Encryption.GenCryptRand(20)<br><br>
/// Now convert the secret to base 32.<br><br>
/// Set SecretBase32=$SYSTEM.Encryption.Base32Encode(Secret)<br><br>
/// Now open the Google Authenticator application on your phone. Select to set up an account.
/// Then enter an account name of your choosing, and the base 32 representation of the secret.
/// Make sure the option is time based. Now as the verification code changes, you can validate
/// it using the Secret generated above as follows:<br><br>
/// Set Valid=$SYSTEM.Encryption.TOTPValidate(GoogleVerificationCode,Secret)<br><br>
/// You can also enter the Secret into Google Authenticator by scanning a QR code which you
/// can generate.
/// First generate the SecretBase32 as described above. Then create an "Issuer" which further identifies
/// the account in Google Authenticatior. Then generate a QR Code in a file 
/// as follows:<br><br>
/// Set FileName="qrcode.png"
/// Set Account="Userxxx"<br>
/// Set Issuer="InterSystemsIRIS-"_##class(%SYS.System).GetNodeName(1)_"-"_##class(%SYS.System).GetInstanceName()<br>
/// Set QRString="otpauth://totp/"_Issuer_":"_Account_"?secret="_SecretBase32_"&issuer="_Issuer<br>
/// Set Status=##Class(%SYS.QRcode).GenerateFile(QRString,FileName)<br><br>
/// Now in Google Authenticator you can create a new account by scanning the QR code.<br>
ClassMethod TOTPValidate(TOTP As %String, Secret As %String, TOTPLastValidPasswords As %String = "", UTCTimeStamp As %String = {$ztimestamp}, TimeStep As %Integer = 30, TimeStepLimit As %Integer = {$$$TOTPDefaultTimeStepLimit}, CodeDigits As %Integer = 6, AddCheckSum As %Boolean = 0, TruncationOffset As %Integer = 19) As %Boolean [ ProcedureBlock = 1 ]
{
 s Status=0
#;A TOTP password can only be used once. We need to protect against the user entering the same password twice
#;within the interval period.
 i (","_TOTPLastValidPasswords_",")[(","_TOTP_",") q Status
#;Get the number of seconds since the Unix Epoch
 s Seconds=+UTCTimeStamp-47117*(60*60*24)+$p($p(UTCTimeStamp,",",2),".")
#;The counter changes every TimeStep seconds
 s Counter=(Seconds\TimeStep)
 f i=0:1:TimeStepLimit-1 {
 	s HOTP=$system.Encryption.HOTP(Secret,Counter+i,CodeDigits,AddCheckSum,TruncationOffset)
	i HOTP=TOTP {
		s Status=1
		q
	}
	continue:i=0   ;Avoid same test for first try
 	s HOTP=$system.Encryption.HOTP(Secret,Counter-i,CodeDigits,AddCheckSum,TruncationOffset)
	i HOTP=TOTP {
		s Status=1
		q
	}
 }
 q Status
}

/// ** DEPRECATED ***<br>
/// This method has been renamed MD5Hash.
ClassMethod MD5Encode(text As %String) As %String [ CodeMode = expression, Deprecated, Internal ]
{
$system.Encryption.MD5Encode(text)
}

/// This method generates a 16-byte hash using the MD5 message digest algorithm.<br>
/// Not available when running in FIPS mode<br>
/// (See Internet Engineering Task Force Request for Comments 1321 for more information.)
/// <br>
/// Note: MD5 is no longer considered secure.  Consider using another algorithm.<br><br>
/// Input parameter:
/// <br>
/// text - String to be hashed.
/// <br><br>
/// Return value:  16-byte MD5 hash.
ClassMethod MD5Hash(text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.MD5Hash(text)
}

/// This method generates a 20-byte hash using U.S. Secure Hash Algorithm 1 (SHA-1).
/// (See Federal Information Processing Standards Publication 180-4
/// and Internet Engineering Task Force Request for Comments 3174
/// for more information.) <br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash. <br>
/// <br>
/// Note: SHA1 is no longer considered secure.  Consider using another algorithm.<br><br>
/// Input parameter:
/// <br>
/// text - String to be hashed.
/// <br><br>
/// Return value:  20-byte SHA-1 hash.
ClassMethod SHA1Hash(text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.SHA1Hash(text)
}

/// This method generates a hash using one of the U.S. Secure Hash Algorithms.
/// (See Federal Information Processing Standards Publication 180-4
/// and Internet Engineering Task Force Request for Comments 3174 and 4634
/// for more information.) <br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash.
/// <br><br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 160 (SHA-1 Note: SHA1 is no longer considered secure.  Consider using another algorithm.)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// text - String to be hashed.
/// <br><br>
/// Return value:  String containing hash value, one byte per character.
ClassMethod SHAHash(bitlength As %Integer, text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.SHAHash(bitlength,text)
}

/// This method generates a 16-byte keyed hash-based message authentication code
/// using the MD5 message digest algorithm.<br>
/// Not available when running in FIPS mode<br>
/// (See Federal Information Processing Standards Publication 198-1 and
/// Internet Engineering Task Force Request for Comments 1321 and 2104
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// text - String for which to generate message authentication code.
/// <br><br>
/// key - Key.
/// <br><br>
/// Return value:  16-byte authentication code.
ClassMethod HMACMD5(text As %String, key As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.HMACMD5(text,key)
}

/// This method generates a 20-byte keyed hash-based message authentication code
/// using U.S. Secure Hash Algorithm 1 (SHA-1).
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].
/// Use $System.Encryption.HMACSHA(160,message, key) if a SHA-1 hash is necessary.
/// <br><br>
/// Input parameters:
/// <br><br>
/// text - String for which to generate message authentication code.
/// <br><br>
/// key - Key.
/// <br><br>
/// Return value:  20-byte authentication code.
ClassMethod HMACSHA1(text As %String, key As %String) As %String [ CodeMode = expression, Deprecated ]
{
$system.Encryption.HMACSHA1(text,key)
}

/// This method generates a keyed hash-based message authentication code
/// using one of the U.S. Secure Hash Algorithms.
/// (See Federal Information Processing Standards Publications 180-4 and 198-1 and
/// Internet Engineering Task Force Request for Comments 2104, 3174, and 4634
/// for more information.)
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].
/// <br><br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired message authentication code.  Legal values are:<br>
/// 160 (SHA-1)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// text - String for which to generate message authentication code.
/// <br><br>
/// key - Key.
/// <br><br>
/// Return value:  String containing message authentication code, one byte per character.
ClassMethod HMACSHA(bitlength As %Integer, text As %String, key As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.HMACSHA(bitlength,text,key)
}

/// This method generates a keyed hash-based message authentication code
/// using one of the U.S. Secure Hash Algorithms.
/// (See Federal Information Processing Standards Publications 180-4 and 198-1 and
/// Internet Engineering Task Force Request for Comments 2104, 3174, and 4634
/// for more information.)
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].
/// <br><br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 160 (SHA-1)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// input - Stream for which to generate message authentication code.<br><br>
/// key - Key.<br><br>
/// Return value:  String containing message authentication code, one byte per character.
ClassMethod HMACSHAStream(bitlength As %Integer, input As %Stream.Object, key As %String, ByRef sc As %Status) As %String
{
	Set sc=input.Rewind() If $$$ISERR(sc) Quit ""
	Do $System.Encryption.HMACSHAStreamReset(bitlength)
	Do $System.Encryption.HMACSHAStreamInit(bitlength, key)
	While 'input.AtEnd {
		Do $System.Encryption.HMACSHAStreamInput(bitlength, input.Read(32000,.sc))
		If $$$ISERR(sc) Quit
	}
	Quit $System.Encryption.HMACSHAStreamResult(bitlength)
}

/// This method generates an encryption key from a password, iteration count, and salt.
/// It uses Password-Based Key Derivation Function 2 (PBKDF2) with HMAC-SHA.
/// This implementation is based on the PBKDF specification as 
/// described in [NIST SP 800-132].
/// (See
/// RSA Laboratories Public-Key Cryptography Standards #5 and
/// Federal Information Processing Standards Publications 180-4 and 198-1
/// for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// Password - User's password
/// <br><br>
/// Iterations - Number of iterations to run
/// <br><br>
/// Salt - Fixed random salt for this user
/// <br><br>
/// KeyLength - Length of encryption key to generate
/// <br><br>
/// bitlength - Length in bits of the underlying HMAC-SHA function (optional).  Legal values are:<br>
/// 160 (SHA-1) (default)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Return value:  Encryption key
ClassMethod PBKDF2(Password As %String, Iterations As %Integer, Salt As %String, KeyLength As %Integer, bitlength As %Integer = 160) As %String [ CodeMode = expression ]
{
$system.Encryption.PBKDF2(Password,Iterations,Salt,KeyLength)
}

/// This method uses
/// the Advanced Encryption Standard (AES) as a primitive to
/// encrypt a plaintext key using a key-encryption key (KEK).<br>
/// See: NIST SP 800-38F, "Recommendation for Block Cipher Modes of Operation: Methods for Key Wrapping",
/// December 2012<br>
/// (https://csrc.nist.gov/publications/detail/sp/800-38f/final)
/// <br><br>
/// Input parameters:
/// <br><br>
/// Key - Plaintext key<br>
/// KEK - Key-encryption key
/// <br><br>
/// Return value:  Encrypted key
/// 
ClassMethod AESKeyWrap(Key As %String, KEK As %String) As %String [ CodeMode = expression ]
{
$SYSTEM.Encryption.AESKeyWrap(Key, KEK)
}

/// This method uses
/// the Advanced Encryption Standard (AES) as a primitive to
/// decrypt an encrypted key using a key-encryption key (KEK).<br>
/// See: NIST SP 800-38F, "Recommendation for Block Cipher Modes of Operation: Methods for Key Wrapping",
/// December 2012<br>
/// (https://csrc.nist.gov/publications/detail/sp/800-38f/final)
/// <br><br>
/// Input parameters:
/// <br><br>
/// EncKey - Encrypted key<br>
/// KEK - Key-encryption key
/// <br><br>
/// Return value:  Plaintext key
/// 
ClassMethod AESKeyUnwrap(EncKey As %String, KEK As %String) As %String [ CodeMode = expression ]
{
$SYSTEM.Encryption.AESKeyUnwrap(EncKey, KEK)
}

/// This method generates a 20-byte hash of a Stream
/// using U.S. Secure Hash Algorithm 1 (SHA-1).
/// (See Federal Information Processing Standards Publication 180-4
/// and Internet Engineering Task Force Request for Comments 3174 for more information.)
/// <br>
/// Note: SHA1 is no longer considered secure.  Consider using another algorithm.<br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash. <br>
/// <br>
/// Input parameter:
/// <br>
/// input - Stream to be hashed.
/// <br><br>
/// Return value:  20-byte SHA-1 hash.
ClassMethod SHA1HashStream(input As %Stream.Object, ByRef sc As %Status) As %String
{
	Quit ..SHAHashStream(160,.input,.sc)
}

/// This method is used with SHA1HashResult
/// to generate a 20-byte hash using U.S. Secure Hash Algorithm 1 (SHA-1)
/// for Streams.
/// These functions could be used, for example, as follows:
/// <br><br>
/// do strm.Rewind()<br>
/// set len=32000<br>
/// set str=strm.Read(.len)<br>
/// while (len>0) {<br>
/// do $System.Encryption.SHA1HashInput(str)<br>
/// set len=32000<br>
/// set str=strm.Read(.len)<br>
/// }<br>
/// set hash=$System.Encryption.SHA1HashResult()<br>
/// <br>
/// Note: SHA1 is no longer considered secure.  Consider using another algorithm.<br><br>
/// Input parameter:
/// <br>
/// text - String to be hashed.
ClassMethod SHA1HashInput(text As %String) [ CodeMode = expression, Internal ]
{
$system.Encryption.SHA1HashInput(text)
}

/// This method is used with SHA1HashInput
/// to generate a 20-byte hash using U.S. Secure Hash Algorithm 1 (SHA-1).
/// for Streams.
/// See SHA1HashInput for an example of usage.
/// <br>
/// Note: SHA1 is no longer considered secure.  Consider using another algorithm.<br><br>
/// Return value:  20-byte SHA-1 hash.
ClassMethod SHA1HashResult() As %String [ CodeMode = expression, Internal ]
{
$system.Encryption.SHA1HashResult()
}

/// This method generates a hash of a Stream using one of the U.S. Secure Hash Algorithms.
/// (See Federal Information Processing Standards Publication 180-4
/// and Internet Engineering Task Force Request for Comments 3174 and 4634
/// for more information.)
/// <br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash. <br>
/// <br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 160 (SHA-1 Note: SHA1 is no longer considered secure.  Consider using another algorithm.)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// input - Stream to be hashed.
/// <br><br>
/// Return value:  String containing hash value, one byte per character.
ClassMethod SHAHashStream(bitlength As %Integer, input As %Stream.Object, ByRef sc As %Status) As %String
{
	Do $System.Encryption.SHAHashReset(bitlength)
	Set sc=input.Rewind() If $$$ISERR(sc) Quit ""
	While 'input.AtEnd {
		Do $System.Encryption.SHAHashInput(bitlength, input.Read(32000,.sc))
		If $$$ISERR(sc) Quit
	}
	Quit $System.Encryption.SHAHashResult(bitlength)
}

/// This method generates the hash of a Stream using the MD5 algorithm.<br>
/// Not available when running in FIPS mode<br>
/// Note: MD5 is no longer considered secure.  Consider using another algorithm.<br>
/// (See the Internet Engineering Task Force Request for Comments 1321
/// for more information.)
/// <br><br>
/// Input parameter:
/// <br><br>
/// input - Stream to be hashed.
/// <br><br>
/// Return value:  String containing hash value, one byte per character.
ClassMethod MD5HashStream(input As %Stream.Object, ByRef sc As %Status) As %String
{
	Do $System.Encryption.MD5HashInit()
	Set sc=input.Rewind() If $$$ISERR(sc) Quit ""
	While 'input.AtEnd {
		Do $System.Encryption.MD5HashUpdate(input.Read(32000,.sc))
		If $$$ISERR(sc) Quit
	}
	Quit $System.Encryption.MD5HashFinal()
}

/// This method generates an RSA-SHA1 digital signature as specified in
/// PKCS #1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5.
/// <br>
/// Note: SHA-1 shall not be used in any new digital signature
/// applications that require at least 80 bits of security strength. Furthermore, SHA-1 shall
/// not be used for the generation of digital signatures after the end of 2013 (NIST Special 
/// Publication 800-107 Recommendation for Applications Using Approved Hash Algorithms) <br> 
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm. 
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].<br><br>
/// Input parameters:
/// <br><br>
/// Data - Data to be signed.
/// <br><br>
/// Key - RSA private key, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Return value:  Digital signature.
/// <br><br>
/// Note:  SHA-1 is deprecated for digital signature generation.
ClassMethod RSASHA1Sign(Data As %String, Key As %String, Password As %String) As %String
{
}

/// This method verifies an RSA-SHA1 digital signature as specified in
/// PKCS #1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5.
/// <br>
/// Note: SHA-1 shall not be used in any new digital signature
/// applications that require at least 80 bits of security strength. Furthermore, SHA-1 shall
/// not be used for the generation of digital signatures after the end of 2013 (NIST Special 
/// Publication 800-107 Recommendation for Applications Using Approved Hash Algorithms) <br> 
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].<br><br>
/// Input parameters:
/// <br><br>
/// Data - Data that was signed.
/// <br><br>
/// Signature - Signature to be verified.
/// <br><br>
/// Certificate - An X.509 certificate containing the RSA public key corresponding to the RSA private key
/// that was used to generate the signature, in PEM encoded or binary DER format.
/// <br><br>
/// CAfile - The name of a file containing trusted Certificate Authority X.509 Certificates in PEM-encoded format, one of which was
/// used to sign the Certificate (optional).
/// <br><br>
/// CRLfile - The name of a file containing X.509 Certificate Revocation Lists in PEM-encoded format that should be checked
/// to verify the status of the Certificate (optional).
/// <br><br>
/// Return value:  1 if the signature was successfully verified, 0 otherwise.
/// <br><br>
/// Note:  This function has an alternate 4-argument usage, where the third and fourth arguments
/// are the RSA public key modulus and exponent in binary format.
ClassMethod RSASHA1Verify(Data As %String, Signature As %String, Certificate As %String, CAfile As %String, CRLfile As %String) As %Boolean
{
}

/// This method generates an RSA-SHA digital signature as specified in
/// RFC 3447 PKCS #1 v2.1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5,
/// using any of the SHA hash functions defined in FIPS 180-4 Secure Hash Standard (SHS).
/// Note: SHA-1 shall not be used in any new digital signature
/// applications that require at least 80 bits of security strength. Furthermore, SHA-1 shall
/// not be used for the generation of digital signatures after the end of 2013 (NIST Special 
/// Publication 800-107 Recommendation for Applications Using Approved Hash Algorithms) <br> 
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 160 (SHA-1)  Note:  SHA-1 is deprecated for digital signature generation.<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data to be signed.
/// <br><br>
/// Key - RSA private key, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Return value:  Digital signature.
ClassMethod RSASHASign(Bitlength As %Integer, Data As %String, Key As %String, Password As %String) As %String
{
}

/// This method verifies an RSA-SHA digital signature as specified in
/// RFC 3447 PKCS #1 v2.1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5,
/// using any of the SHA hash functions defined in FIPS 180-4 Secure Hash Standard (SHS).
/// Note: SHA-1 shall not be used in any new digital signature
/// applications that require at least 80 bits of security strength. Furthermore, SHA-1 shall
/// not be used for the generation of digital signatures after the end of 2013 (NIST Special 
/// Publication 800-107 Recommendation for Applications Using Approved Hash Algorithms) <br> 
/// In general, SHA-1 is no longer considered secure. Consider using another algorithm.
/// This warning is based on the Approved Hash Algorithms requirements as 
/// described in [NIST SP 800-107r1].
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 160 (SHA-1)<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data that was signed.
/// <br><br>
/// Signature - Signature to be verified.
/// <br><br>
/// Certificate/PublicKey - Either<br>
/// An X.509 certificate containing the RSA public key corresponding to the RSA private key
/// that was used to generate the signature, in PEM encoded or binary DER format.<br>
/// or<br>
/// The RSA public key corresponding to the RSA private key
/// that was used to generate the signature, in PEM-encoded PKCS#1 RSAPublicKey format or
/// PEM-encoded SubjectPublicKeyInfo format.<br>
/// (The actual certificate or public key, not the name of a file containing it.)
/// <br><br>
/// CAfile - The name of a file containing trusted Certificate Authority X.509 Certificates in PEM-encoded format, one of which was
/// used to sign the Certificate (optional).
/// <br><br>
/// CRLfile - The name of a file containing X.509 Certificate Revocation Lists in PEM-encoded format that should be checked
/// to verify the status of the Certificate (optional).
/// <br><br>
/// Return value:  1 if the signature was successfully verified, 0 otherwise.
/// <br><br>
/// Note:  This function has an alternate 5-argument usage, where the fourth and fifth arguments
/// are the RSA public key modulus and exponent in binary format.
ClassMethod RSASHAVerify(Bitlength As %Integer, Data As %String, Signature As %String, Certificate As %String, CAfile As %String, CRLfile As %String) As %Boolean
{
}

/// This method performs RSA encryption as specified in
/// PKCS #1 v2.1: RSA Cryptography Specifications, section 7 Encryption Schemes.
/// <br><br>
/// Input parameters:
/// <br><br>
/// Plaintext - Data to be encrypted.
/// <br><br>
/// Certificate/PublicKey - Either<br>
/// An X.509 certificate containing the RSA public key to be used for encryption,
/// in PEM encoded or binary DER format.<br>
/// or<br>
/// The RSA public key to be used for encryption, in PEM-encoded PKCS#1 RSAPublicKey format or
/// PEM-encoded SubjectPublicKeyInfo format.<br>
/// (The actual certificate or public key, not the name of a file containing it.)<br>
/// Note that the length of the plaintext can not be greater than the length of the modulus of
/// the RSA public key minus 42 bytes. 
/// <br><br>
/// CAfile - The name of a file containing trusted Certificate Authority X.509 Certificates in PEM-encoded format, one of which was
/// used to sign the Certificate (optional).
/// <br><br>
/// CRLfile - The name of a file containing X.509 Certificate Revocation Lists in PEM-encoded format that should be checked
/// to verify the status of the Certificate (optional).
/// <br><br>
/// Encoding - PKCS #1 v2.1 encoding method (optional):<br>
/// 	   1 = OAEP (default)<br>
/// 	   2 = PKCS1-v1_5<br>
/// <br><br>
/// Return value:  Ciphertext.
ClassMethod RSAEncrypt(Plaintext As %String, Certificate As %String, CAfile As %String, CRLfile As %String, Encoding As %Integer) As %String
{
}

/// This method performs RSA decryption as specified in
/// PKCS #1 v2.1: RSA Cryptography Specifications, section 7 Encryption Schemes.
/// This is intended primarily for encryption of temporary symmetric encryption keys.
/// <br><br>
/// Input parameters:
/// <br><br>
/// Ciphertext - Data to be decrypted.
/// <br><br>
/// Key - RSA private key corresponding to the RSA public key that was used for encryption, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Encoding - PKCS #1 v2.1 encoding method (optional):<br>
/// 	   1 = OAEP (default)<br>
/// 	   2 = PKCS1-v1_5
/// <br><br>
/// Return value:  Plaintext.
ClassMethod RSADecrypt(Ciphertext As %String, Key As %String, Password As %String, Encoding As %Integer) As %String
{
}

/// **DEPRECATED**<br>
/// This method returns internal error information from the last invocation of RSASHA1Sign(), RSASHA1Verify(),
/// RSAEncrypt(), or RSADecrypt(), if an error occurred and such information was generated.
/// A synonym for RSAGetLastError().
/// <br><br>
/// Return value:  Error string.
ClassMethod RSASHA1GetLastError() As %String [ Deprecated, Internal ]
{
}

/// This method returns internal error information from the last invocation of RSASHA1Sign(), RSASHA1Verify(),
/// RSAEncrypt(), or RSADecrypt(), if an error occurred and such information was generated.
/// <br><br>
/// Return value:  Error string.
ClassMethod RSAGetLastError() As %String
{
}

/// This method returns the length of the modulus of an RSA key.
/// Intended for use with RSAEncrypt().
/// <br><br>
/// Input parameters:
/// <br><br>
/// Input - An X.509 digital certificate containing an RSA public key, in PEM encoded or binary DER format,
/// or an RSA private key, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Return value:  The length of the modulus of the RSA key, in bytes.
ClassMethod RSASize(Input As %String, Password As %String) As %Integer
{
}

/// Elliptic Curve SHA Sign
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data to be signed.
/// <br><br>
/// Key - EC private key, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Return value:  Digital signature in DER-encoded ASN.1 format.
ClassMethod ECSHASign(Bitlength As %Integer, Data As %String, Key As %String, Password As %String) As %String
{
}

/// Elliptic Curve SHA Verify
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data that was signed.
/// <br><br>
/// Signature - Signature to be verified (in DER-encoded ASN.1 format).
/// <br><br>
/// PublicKey<br>
/// The EC public key corresponding to the EC private key
/// that was used to generate the signature, in PEM-encoded format.<br>
/// (The actual public key, not the name of a file containing it.)
/// <br><br>
/// Return value:  1 if the signature was successfully verified, any other value otherwise.
/// 
ClassMethod ECSHAVerify(Bitlength As %Integer, Data As %String, Signature As %String, PublicKey As %String) As %Integer
{
}

/// This method returns internal error information from the last invocation of ECSHASign(), ECSHAVerify(),
/// if an error occurred and such information was generated.
/// <br><br>
/// Return value:  Error string.
ClassMethod ECGetLastError() As %String
{
}

/// This methods returns a string representation of the value of a field in an X.509 digital certificate.
/// <br><br>
/// Input parameters:
/// <br><br>
/// Certificate - An X.509 digital certificate, in PEM encoded or binary DER format.
/// <br><br>
/// Field - The name of the field to be extracted.
/// Legal field names, the sections of RFC 5280 that describe the corresponding fields,
/// the ASN.1 types of the fields, and the value types returned by this function are:
/// <br>
/// "SerialNumber", 4.1.2.2, INTEGER, decimal character string
/// <br>
/// "Issuer", 4.1.2.4, X.501 Name, RFC 2253 conformant string representation
/// <br>
/// "ValidityNotBefore", 4.1.2.5, UTCTime or GeneralizedTime, ODBC time string ("yyyy-MM-dd hh:mm:ss")
/// <br>
/// "ValidityNotAfter", 4.1.2.5, UTCTime or GeneralizedTime, ODBC time string ("yyyy-MM-dd hh:mm:ss")
/// <br>
/// "Subject", 4.1.2.6, X.501 Name, RFC 2253 conformant string representation
/// <br>
/// "SubjectKeyIdentifier", 4.2.1.2, OCTET STRING, byte string
/// <br>
/// "RSAPublicKeyModulus", 4.1.2.7, BIT STRING, byte string
/// <br>
/// "RSAPublicKeyExponent", 4.1.2.7, BIT STRING, byte string
/// <br><br>
/// Also supported are all certificate extensions, using the syntax "Extension:name".
/// A string representation of the extension, if present, is returned.
/// Legal names and the sections of RFC 5280 that describe the corresponding field follow:
/// <br>
/// "Extension:authorityKeyIdentifier", 4.2.1.1
/// <br>
/// "Extension:subjectKeyIdentifier", 4.2.1.2
/// <br>
/// "Extension:keyUsage", 4.2.1.3
/// <br>
/// "Extension:certificatePolicies", 4.2.1.4
/// <br>
/// "Extension:policyMappings", 4.2.1.5
/// <br>
/// "Extension:subjectAltName", 4.2.1.6
/// <br>
/// "Extension:issuerAltName", 4.2.1.7
/// <br>
/// "Extension:subjectDirectoryAttributes", 4.82.1.
/// <br>
/// "Extension:basicConstraints", 4.2.1.9
/// <br>
/// "Extension:nameConstraints", 4.2.1.10
/// <br>
/// "Extension:policyConstraints", 4.2.1.11
/// <br>
/// "Extension:extendedKeyUsage", 4.2.1.12
/// <br>
/// "Extension:crlDistributionPoints", 4.2.1.13
/// <br>
/// "Extension:inhibitAnyPolicy", 4.2.1.14
/// <br>
/// "Extension:freshestCRL", 4.2.1.15
/// <br>
/// "Extension:authorityInfoAccess", 4.2.2.1
/// <br>
/// "Extension:subjectInfoAccess", 4.2.2.2
/// <br>
/// "Extension:nsCertType", deprecated
/// <br><br>
/// Return value:  The value of the field.
ClassMethod X509GetField(Certificate As %String, Field As %String) As %String
{
}

/// This method verifies an X.509 certificate chain with a certificate,
/// a trusted CA certificate file, and optionally a CRL file.
/// It is intended to be used to verify that two SSL/TLS configurations have
/// X.509 certificates and CA files that can be used to establish an SSL/TLS session between them.
/// Note that this method verifies only the certificates, CA files, and optionally CRL files,
/// and not other properties of the SSL/TLS configurations.
/// Intended use case, for a Client verifying that it can connect to,
/// and accept connections from, a Server:
/// <br><br>
/// Client sends Client certificate to Server<br>
/// Server verifies Client certificate with Server CA file<br>
/// Server returns result of verification, along with Server certificate<br>
/// Client verifies Server certificate with Client CA file<br>
/// Client sends result of verification to Server
/// <br><br>
/// Input parameters:
/// <br><br>
/// Certificate - X.509 certificate in PEM or DER format
/// <br><br>
/// CAFile - Name of a file containing trusted Certificate Authority certificates
/// <br><br>
/// CRLFile - Name of a file containing Certificate Revocation lists (optional)
/// <br><br>
/// Return value:  the string "OK" if verification is successful, otherwise a ";" delimited list of error strings
ClassMethod X509VerifyCertChain(Certificate As %String, CAFile As %String, CRLFile As %String) As %String
{
}

/// This method creates a new encryption key and key file, for use with block-level database encryption
/// and/or data element encryption for applications.
/// Note:  Must be run from the system namespace.<br>
/// <br>
/// Input parameters:<br>
/// File - Name of the key file to create.<br>
/// Username - Name of the initial encryption key administrator for the new key file.<br>
/// Password - Password for the initial encryption key administrator for the new key file.
/// This value should always be obtained from a user prompt, never embedded in application code.<br>
/// KeyLength - Length in bytes of the data- and key-encryption keys.  Must be 16, 24, or 32.<br>
/// Status - Parameter passed by reference for the return status.<br>
/// <br>
/// Return value:  On success, the unique key identifier of the new encryption key.
ClassMethod CreateEncryptionKey(File As %String, Username As %String, Password As %String, KeyLength As %Integer, ByRef Status As %Status) As %String
{
	Quit $$Create^EncryptionKey(File, Username, Password, KeyLength, .Status)
}

/// This method creates a new encryption key and key file via a given KMS server, for use with block-level database encryption and/or data element encryption for applications.
/// Note:  Must be run from the system namespace.<br>
/// <br>
/// Input parameters:<br>
/// File - Name of the key file to create.<br>
/// Server - Name of the KMS server. Currently accepted values are "AWS" and "Azure" (case insensitive). <br>
/// ServerKeyID - Key ID of the master key on the server.<br> 
/// KeyLength - Length in bytes of the data- and key-encryption keys.  Must be 16, 24, or 32.<br>
/// Backup - (Passed by reference, optional) info for creating a backup key file.  If specified, it should contain the following entries:
/// 	Backup("File"): Name of the backup key file.<br> 
/// 	Backup("Username"): Name of the initial encryption key administrator for the backup key file.<br>
/// 	Backup("Password"): Password for the initial encryption key administrator for the backup key file.
/// 	This value should always be obtained from a user prompt, never embedded in application code.<br>
/// 	Backup("Desc"): (optional) Description of the key<br>
/// Region - (AWS only) Name of the region, e.g., "us-east-2".<br> 
/// Description - (optional) Description of the key.<br> 
/// Env - (Passed by reference, optional) to specify environment variables to be set for key activation (currently for AWS only), e.g., Env("AWS_CONFIG_FILE")=(path of AWS config file), Env("AWS_SHARED_CREDENTIALS_FILE")=(path of AWS credential file), etc.<br> 
/// Status - Parameter passed by reference for the return status.<br>
/// Return value:  On success, the unique key identifier of the new encryption key.
ClassMethod KMSCreateEncryptionKey(File As %String, Server As %String, ServerKeyID As %String, KeyLength As %Integer, ByRef Backup As %String, Region As %String = "", Description As %String = "", ByRef Env As %String, ByRef Status As %Status) As %String
{
	
	Set Status=$$KMSCreate^EncryptionKey(File,Server,ServerKeyID,KeyLength,.Backup,Region,Description,.Env,.KeyID)
	Quit $g(KeyID)
}

/// This method activates an encryption key for use with data element encryption for applications.
/// Note:  Must be run from the system namespace.<br>
/// <br>
/// Input parameters:<br>
/// File - Name of the key file to use.<br>
/// Username - Name of an encryption key administrator for this key file.<br>
/// Password - Password of this encryption key administrator for this key file.
/// This value should always be obtained from a user prompt, never embedded in application code.<br>
/// <br>
/// Return value:  Return status.
ClassMethod ActivateEncryptionKey(File As %String, Username As %String = "", Password As %String = "") As %Status
{
	Quit $$ActivateMK^EncryptionKey(File, Username, Password)
}

/// This method returns a comma-separated list of the key identifiers of encryption keys
/// currently activated for use with data element encryption for applications.
/// Note:  Must be run from the system namespace.<br>
/// <br>
/// Return value:  Comma-separated list of key identifiers.
ClassMethod ListEncryptionKeys() As %String
{
	Quit $SYSTEM.Security.System.GetMKEncKeyIDList()
}

/// This method deactivates an encryption key currently
/// activated for use with data element encryption for applications.
/// Note:  Must be run from the system namespace.<br>
/// <br>
/// Input parameter:<br>
/// KeyID - Key identifier of key to deactivate.
/// <br>
/// Return value:  Return status.
ClassMethod DeactivateEncryptionKey(KeyID As %String) As %Status
{
	Quit $$DeactivateMK^EncryptionKey(KeyID)
}

/// This method returns a string describing the version of the OpenSSL libraries, including the release date.
ClassMethod OpenSSLVersion() As %String
{
}

/// This method generates a hash of a Stream using one of the U.S. Secure Hash Algorithms - 3.
/// (See Federal Information Processing Standards Publication 202 for more information.) <br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash. <br>
/// <br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// input - Stream to be hashed.
/// <br><br>
/// Return value:  String containing hash value, one byte per character.
ClassMethod SHA3HashStream(bitlength As %Integer, input As %Stream.Object, ByRef sc As %Status) As %String
{
	Do $System.Encryption.SHA3HashReset(bitlength)
	Set sc=input.Rewind() If $$$ISERR(sc) Quit ""
	While 'input.AtEnd {
		Do $System.Encryption.SHA3HashInput(bitlength, input.Read(32000,.sc))
		If $$$ISERR(sc) Quit
	}
	Quit $System.Encryption.SHA3HashResult(bitlength)
}

/// This method generates a keyed hash-based message authentication code
/// using one of the U.S. Secure Hash Algorithms - 3.
/// (See Federal Information Processing Standards Publications 202 for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired message authentication code.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// text - String for which to generate message authentication code.
/// <br><br>
/// key - Key.
/// <br><br>
/// Return value:  String containing message authentication code, one byte per character.
ClassMethod HMACSHA3(bitlength As %Integer, text As %String, key As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.HMACSHA3(bitlength,text,key)
}

/// This method generates a keyed hash-based message authentication code
/// using one of the U.S. Secure Hash Algorithms - 3.
/// (See Federal Information Processing Standards Publications 202 for more information.)
/// <br><br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA3-224)<br>
/// 256 (SHA3-256)<br>
/// 384 (SHA3-384)<br>
/// 512 (SHA3-512)<br><br>
/// input - Stream for which to generate message authentication code.<br><br>
/// key - Key.<br><br>
/// Return value:  String containing message authentication code, one byte per character.
ClassMethod HMACSHA3Stream(bitlength As %Integer, input As %Stream.Object, key As %String, ByRef sc As %Status) As %String
{
	Set sc=input.Rewind() If $$$ISERR(sc) Quit ""
	Do $System.Encryption.HMACSHA3StreamReset(bitlength)
	Do $System.Encryption.HMACSHA3StreamInit(bitlength, key)
	While 'input.AtEnd {
		Do $System.Encryption.HMACSHA3StreamInput(bitlength, input.Read(32000,.sc))
		If $$$ISERR(sc) Quit
	}
	Quit $System.Encryption.HMACSHA3StreamResult(bitlength)
}

/// This method generates a hash using one of the U.S. Secure Hash Algorithms - 3.
/// (See Federal Information Processing Standards Publication 202 for more information.)
/// <br>
/// Use <method>ToHex</method> on the output to make it a hex string <br>
/// and use <method>FromHex</method> to decode a hex hash. <br>
/// <br>
/// Input parameters:
/// <br><br>
/// bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br><br>
/// text - String to be hashed.
/// <br><br>
/// Return value:  String containing hash value, one byte per character.
ClassMethod SHA3Hash(bitlength As %Integer, text As %String) As %String [ CodeMode = expression ]
{
$system.Encryption.SHA3Hash(bitlength,text)
}

/// This method generates an RSA-SHA-3 digital signature as specified in
/// RFC 3447 PKCS #1 v2.1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5,
/// using any of the SHA-3 hash functions defined in FIPS 202 Secure Hash Standard (SHS).
/// <br><br>
/// Note: Not available on systems without OpenSSL v1.1.x
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data to be signed.
/// <br><br>
/// Key - RSA private key, PEM encoded.
/// <br><br>
/// Password - Private key password (optional).
/// <br><br>
/// Return value:  Digital signature.
ClassMethod RSASHA3Sign(Bitlength As %Integer, Data As %String, Key As %String, Password As %String) As %String
{
}

/// This method verifies an RSA-SHA-3 digital signature as specified in
/// RFC 3447 PKCS #1 v2.1: RSA Cryptography Specifications, section 8.1 RSASSA-PKCS1-v1_5,
/// using any of the SHA-3 hash functions defined in FIPS 202 Secure Hash Standard (SHS).
/// <br><br>
/// Note: Not available on systems without OpenSSL v1.1.x
/// <br><br>
/// Input parameters:
/// <br><br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)
/// <br><br>
/// Data - Data that was signed.
/// <br><br>
/// Signature - Signature to be verified.
/// <br><br>
/// Certificate/PublicKey - Either<br>
/// An X.509 certificate containing the RSA public key corresponding to the RSA private key
/// that was used to generate the signature, in PEM encoded or binary DER format.<br>
/// or<br>
/// The RSA public key corresponding to the RSA private key
/// that was used to generate the signature, in PEM-encoded PKCS#1 RSAPublicKey format or
/// PEM-encoded SubjectPublicKeyInfo format.<br>
/// (The actual certificate or public key, not the name of a file containing it.)
/// <br><br>
/// CAfile - The name of a file containing trusted Certificate Authority X.509 Certificates in PEM-encoded format, one of which was
/// used to sign the Certificate (optional).
/// <br><br>
/// CRLfile - The name of a file containing X.509 Certificate Revocation Lists in PEM-encoded format that should be checked
/// to verify the status of the Certificate (optional).
/// <br><br>
/// Return value:  1 if the signature was successfully verified, 0 otherwise.
/// <br><br>
/// Note:  This function has an alternate 5-argument usage, where the fourth and fifth arguments
/// are the RSA public key modulus and exponent in binary format.
ClassMethod RSASHA3Verify(Bitlength As %Integer, Data As %String, Signature As %String, Certificate As %String, CAfile As %String, CRLfile As %String) As %Boolean
{
}

/// This method is used with SHA3HashResult
/// to generate hash string using U.S. Secure Hash Algorithm 3 (SHA-3)
/// for Streams.
/// These functions could be used, for example, as follows:
/// <br><br>
/// do strm.Rewind()<br>
/// set len=32000<br>
/// set str=strm.Read(.len)<br>
/// while (len>0) {<br>
/// do $System.Encryption.SHA3HashInput(224,str)<br>
/// set len=32000<br>
/// set str=strm.Read(.len)<br>
/// }<br>
/// set hash=$System.Encryption.SHA3HashResult(224)<br>
/// <br><br>
/// Input parameter:
/// <br>
/// Bitlength - Length in bits of the desired hash.  Legal values are:<br>
/// 224 (SHA-224)<br>
/// 256 (SHA-256)<br>
/// 384 (SHA-384)<br>
/// 512 (SHA-512)<br>
/// text - String to be hashed.
ClassMethod SHA3HashInput(text As %String) [ CodeMode = expression, Internal ]
{
$system.Encryption.SHA3HashInput(text)
}

/// This method is used with SHA3HashInput
/// to generate a hash string using U.S. Secure Hash Algorithm 3 (SHA-3).
/// for Streams.
/// See SHA3HashInput for an example of usage.
/// <br><br>
/// Return value:  SHA-3 hash.
ClassMethod SHA3HashResult() As %String [ CodeMode = expression, Internal ]
{
$system.Encryption.SHA3HashResult()
}

/// 	This method creates a database encryption key and key file suitable for use only with unattended database encryption key activation at startup. See <method>ActivateAutoEncryptionKey</method> for activating such a key.
/// Must be run from the system namespace.<br>
/// <br>
/// Input parameters:<br>
/// file - Name of the key file to create.<br>
/// bitlength - Size of the AES keys to create, in bits.  Must be 128, 192, or 256.<br>
/// Description - Description of the key.<br>
/// Output parameters:<br>
/// Username and Password - for activating the key via <method>ActivateAutoEncryptionKey</method>.<br>
/// <br>
/// Return value:  Return status.
ClassMethod CreateAutoEncryptionKeyOnly(file As %String, bitlength As %Integer, Description As %String, ByRef Username As %String, ByRef Password As %String) As %Status
{
	
	If $NAMESPACE'="%SYS" {
		Quit $$$ERROR($$$IncorrectNamespace,"%SYS") 
	}
	Quit $$CreateAutoKeyOnly^EncryptionKey(file,bitlength,Description,.Username,.Password)
}

/// 	This method activated a database encryption key and key file suitable for use only with unattended database encryption key activation at startup. See <method>CreateAutoEncryptionKeyOnly</method> for generating such a key.
/// Must be run from the system namespace.<br>
/// <br>
/// Input parameters:<br>
/// file - Name of the key file to create.<br>
/// Username and Password - obtained from <method>CreateAutoEncryptionKeyOnly</method>.<br>
/// iristemp - boolean 0/1.  Encrypt IRISTEMP and IRISLOCALDATA.<br>
/// journal - boolens 0/1.  Encrypt journal files.<br>
/// audit - boolean 0/1.  Encrypt audit database.<br>
/// <br>
/// Return value:  Return status.
ClassMethod ActivateAutoEncryptionKey(file As %String, Username As %String, Password As %String, iristemp As %Boolean, journal As %Boolean, audit As %Boolean) As %Status
{
	
	If $NAMESPACE'="%SYS" {
		Quit $$$ERROR($$$IncorrectNamespace,"%SYS") 
	}
	Quit $$ActivateAutoKey^EncryptionKey(file,Username,Password,iristemp,journal,audit)
}

/// 
/// 	Returns an encoding of a byte string as a hexadecimal string. <br>
/// 	Returned string is twice the length of the input. <br><br>
/// 	Input parameters: <br>
/// 	toEncode - the string that you want to encode. <br>
/// 	<br>
/// 	Return value: An encoded string that is twice the length. 
/// 

ClassMethod ToHex(toEncode As %String = "") As %String
{
}

/// 
/// 	Returns a decoding of a hexadecimal string as a byte string. <br>
/// 	Returned string is half the length of the input. <br><br>
/// 	Input parameters: <br>
/// 	toDecode - the string that you want to decode. <br>
/// 	<br>
/// 	Return value: A decoded string that is half the length of the input.
/// 

ClassMethod FromHex(toDecode As %String = "") As %String
{
}

}
