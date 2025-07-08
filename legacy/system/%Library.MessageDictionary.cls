/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Library.MessageDictionary">String Localization and Message Dictionaries</a>.</p>
/// The <class>%MessageDictionary</class> is introduced to allow easy 
/// localization of program messages and CSP page content.  A %MessageDictionary 
/// is a dictionary of messages.  Each message in the dictionary is any ObjectScript string 
/// and is indexed by any ObjectScript value.  A %MessageDictionary is then defined for each
/// language and domain needed by your application. Each message is indexed by language, 
/// domain and id.
/// <p>In order for a %MessageDictionary object to be created (New'ed), a
/// language and domain must be specified for the message dictionary.
/// The format of the specification string is "&lt;language&gt;:&lt;domain&gt;".  
/// &lt;language&gt; is an optional RFC 1766 language tag.  If not specified the
/// default system language is used.  &lt;domain&gt; is a required domain specification,
/// for example "en-us:titles" or ":names".
Class %Library.MessageDictionary Extends %RegisteredObject [ System = 3 ]
{

Method %OnNew(initvalue) As %Status
{
 If $get(initvalue)="" Quit $$$OK
 Set len=$length(initvalue,":")
 Set domain=$piece(initvalue,":",2)
 If (len=2) && (domain'="") {
	Set language=$piece(initvalue,":",1)
	If language="" Set language=$$$SessionLanguage
	If $$$MessageDictionaryExists(language,domain) {
		Set i%Language=language
		Set i%Domain=domain
		Quit $$$OK
	}
 }
 Quit $$$ERROR($$$InvalidMsgDictSpec,initvalue)
}

/// The <var>Language</var> attribute defines the language of the messages 
/// in the Message Dictionary.  Language is any RFC 1766 defined language tag.  
/// In summary, a language tag is composed of 1 or more parts: 
/// A primary language tag optionally followed by a hyphen (-) 
/// separated secondary subtag.  The Language string will be normalized to all 
/// lower case characters.
Property Language As %String;

/// The <var>Domain</var> attribute defines the logical grouping of messages in the
/// Message Dictionary.  If the domain name begins with %, then the 
/// Message Dictionary is considered a system Message Dictionary that 
/// is visible in all namespaces.  Application Message Dictionaries are 
/// visible in only the namespace in which they are defined.
Property Domain As %String;

/// Import the Message Dictionary(s) in an XML file specified by <var>filepath</var>.
/// All Message Dictionaries in the file will be imported.
/// The "d", display, <var>flag</var> is supported.
/// <p>One or more Message Dictionaries may be specified by the 
/// XML file in the format given by the DTD at &ltinstance base directory&gt\dev\csp\rules\CacheMessages.dtd,
/// or url /studio/rules/CacheMessages.dtd.  The file may contain 
/// Message Dictionaries for only one language and multiple domains.
/// In summary, the file looks like:
/// <example language=xml>
/// <?xml version="1.0" encoding="UTF-8"?>
/// <MsgFile Language="language">
/// <MsgDomain Domain="domain">
/// <Message Id="message_id" Name="message name">message text</Message>
/// .
/// .
/// .
/// </MsgDomain>
/// .
/// .
/// .
/// </MsgFile>
/// </example>
/// <p>We recommend using the UTF-8 encoding for these files whenever possible.  
/// Sometimes local platform encodings, such as shift-jis, are needed for ease 
/// of editing.  The encoding that is picked must be supported by the locale 
/// for the application and be able to express the messages for this file's language.
ClassMethod Import(filepath As %String, flag As %String = "") As %Status
{
 Quit $$Import^%occMessages(filepath,flag)
}

/// Import the Message Dictionary(s) in all of the XML file in the specified 
/// <var>directory</var>.
/// The "d", display, <var>flag</var> is supported.
/// <p>The format of the XML files is described with the <method>Import</method>.
ClassMethod ImportDir(directory As %String, flag As %String = "") As %Status
{
 Quit $$ImportDir^%occMessages(directory,flag)
}

/// Delete all Message Dictionary(s) for the specified languages. 
/// <var>Languages</var> is an optional comma separated list of languages
/// whose Message Dictionaries are to be deleted.
/// If <var>languages</var> is not specified, Message Dictionaries for all 
/// languages are deleted.  The "s", system flag, is an optional flag indicating 
/// whether system "s" or application Message Dictionaries are to be dleeted. 
/// The default value is to delete application Message Dictionaries.  
/// <p>The messages names associated with include files are always deleted, but not 
/// any previously geenrated include files.
/// The "d", display, flag is supported.
ClassMethod Delete(languages As %String = "", flag As %String = "") As %Status
{
 Quit $$Delete^%occMessages(languages,flag)
}

/// Generate an include file mapping the Name attributes of each message in any
/// Message Dictionary to the message id.
/// <p>The name of the include file to be generated is includeName. 
/// The DomainList argument is a comma separated list of names of the domains for which the include file is to generated.
/// If Domain is not specified or "", then all domains are included in the include file.
/// If UseDomainName is true (1), then the domain name as "<domain>" is prepended to the 
/// message code in the include file.
/// The "s", system flag, is an optional flag indicating whether system, "s", 
/// or application Message Dictionaries are to be exported. 
/// The "d", display, flag is supported.
ClassMethod GenerateInclude(includeName As %String, flag As %String = "", DomainList = "", UseDomainName As %Boolean = 0) As %Status
{
 Quit $$GenerateInclude^%occMessages(includeName,flag,DomainList,UseDomainName)
}

/// Export Message Dictionaries to XML file(s).
/// <var>languages</var> is an optional comma separated list of languages.
/// If <var>languages</var> is not specified, all languages are exported.  
/// Each language in the list is exported to a separate file.  The template
/// for the filename is given by the <var>file</var> argument that
/// is of the format "&lt;filepath&gt;.&lt;ext&gt;".
/// The file will be named by concatenating the <var>language</var> to the &lt;filepath&gt; 
/// with an extension of &lt;ext&gt;.
/// The "s", system flag, is an optional flag indicating whether system "s" or application 
/// Message Dictionaries are to be exported.
ClassMethod Export(file As %String, languages As %String = "", flag As %String = "") As %Status
{
 Quit $$Export^%occMessages(file,languages,flag)
}

/// Export Message Dictionaries for the specified languages and domains.
/// <var>fil</var> is the path of the file to be written.
/// <var>domainList</var> is a comma separated list of domains to be exported. 
/// <var>language</var> is an optional language that default to the current session language, $$$SessionLanguage. 
ClassMethod ExportDomainList(file As %String, domainList As %String, language As %String) As %Status
{
 Quit $$ExportDomainList^%occMessages(file,domainList,.language)
}

/// GetLanguages returns a list of all languages that have messages loaded
/// for the specified domain or all languages if domain=""
/// Each language is in the standard RFC1766 format and all in lower case.
/// The "s", system flag, is an optional flag indicating whether languages 
/// supported by system ("s") or application Message Dictionaries are to be 
/// returned. The default value is to return the languages for application 
/// Message Dictionaries.
ClassMethod GetLanguages(domain As %String = "", flag As %String = "") As %ListOfDataTypes
{
 Set rlist=##class(%ListOfDataTypes).%New()
 Do rlist.InsertList($$GetLanguages^%occMessages(domain,flag))
 Quit rlist
}

/// GetDomains returns a list of all domains that have messages loaded for the specified language.  
/// If language="" is specifed, the default language is used.
/// The "s", system flag, is an optional flag indicating whether languages 
/// supported by system ("s") or application Message Dictionaries are to be 
/// returned. The default value is to return the domains for application 
/// Message Dictionaries.
ClassMethod GetDomains(language As %String = "", flag As %String = "") As %ListOfDataTypes
{
 Set rlist=##class(%ListOfDataTypes).%New()
 Do rlist.InsertList($$GetDomains^%occMessages(language,flag))
 Quit rlist
}

/// Get the best language match to a language in the list languages 
/// for the specified domain using HTTP 1.1 matching rules (RFC 2616).
/// The list of languages is a comma separated list of 
/// RFC 1766 format language names.  Each language in the list MAY be 
/// given an associated quality value which represents an estimate of 
/// the user's preference for the languages specified by the input list. 
/// The quality value defaults to "q=1". For example,
/// "da, en-gb;q=0.8, en;q=0.7"
/// would mean: "I prefer Danish, but will accept British English and
/// other types of English."
/// A language from the list matches a supported language tag if
/// it exactly equals the tag, or if it exactly equals a prefix of the
/// tag such that the first tag character following the prefix is "-".
/// The special language "*", if present in the input list,
/// matches every supported language not matched by any other language 
/// present in the list.
/// 
/// The language quality factor assigned to a supported language tag by the
/// is the quality value of the longest language in the list thatt matches 
/// the language-tag.  The language that is returned is the supported language
/// that has been assigned the highest quality factor.
/// 
/// The "s", system flag, is an optional flag indicating whether system, "s", 
/// or application Message Dictionaries are to be matched. 
ClassMethod MatchLanguage(languages As %String, domain As %String = "", flag As %String = "") As %String
{
 Quit $$MatchLanguage^%occMessages(languages,domain,flag)
}

/// Get message text from this Message Dictionary.
/// The default argument is used for the message if no message is found for id.
/// No message formatting is supported by this method.
Method GetMessage(id As %String, default As %String = "") As %String
{
 Quit $$$GetMessage(i%Language,i%Domain,id,default)
}

/// Return the text and id of the next message.
///   The text and id of the message with the next id are returned.
///   If the input id = "", then the text and id of the first message are returned.
///   Return an empty string for the message text and id, if the input id was for the last message.
///   Language is optional and the current language is used if language is "" or not specified.  
///   Language will be converted to lower case before being used.
///   Domain can be a system domain beginning with % or a application domain. 
Method GetNextMessage(ByRef id As %String) As %String
{
 Quit $$GetNextMessage^%occMessages(i%Language,i%Domain,.id)
}

/// Get and format message text from this Message Dictionary.
/// The default argument is used for the message if no message is found for id.
/// If the default argument is not specified, then string for the default language
/// or English is used as the default.
/// Arguments of the form %1, %2, etc will be replaced by arguments
/// that follow the id argument.
Method FormatMessage(id As %String, default As %String, args...) As %String
{
 Quit $$FormatMessage^%occMessages(i%Language,i%Domain,id,.default,args...)
}

/// Format the specified message text.
/// Arguments of the form %1, %2, etc will be replaced by arguments
/// that follow the text argument.
ClassMethod FormatText(text As %String, args...) As %String
{
 Quit $$FormatText^%occMessages(text,args...)
}

/// GetSessionLanguage retrieves the default session language for the messages in the Message Dictionary.
/// The language returned is a RFC 1766 defined language tag.<br> 
/// In summary, a language tag is composed of 1 or more parts: 
/// A primary language tag optionally followed by a hyphen (-) 
/// separated secondary subtag.  The Language string will be normalized to all 
/// lower case characters.
ClassMethod GetSessionLanguage() As %String
{
	Quit $$GetSessionLanguage^%occMessages()
}

/// SetSessionLanguage sets the default session language for the messages in the Message Dictionary.
/// The <var>language</var> argument is a RFC 1766 defined language tag.
/// The return value is the previous default session language.
/// In summary, a language tag is composed of 1 or more parts: 
/// A primary language tag optionally followed by a hyphen (-) 
/// separated secondary subtag.  The Language string will be normalized to all 
/// lower case characters.
ClassMethod SetSessionLanguage(language As %String) As %String
{
	Set previous=$$GetSessionLanguage^%occMessages()
	Do SetSessionLanguage^%occMessages(language)
	Quit previous
}

}
