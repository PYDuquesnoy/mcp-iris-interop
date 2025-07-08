/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS.
/// You should not make direct use of it within your applications.
/// There is no guarantee made about either the behavior or future operation of this class.<p>
/// 
/// Manage the sections that compose a CSP page.
Class %CSP.PageBuilder Extends %RegisteredObject [ System = 3 ]
{

/// Stack of default section identifiers in the form <name>,<block number>
Property DefaultSection As %String [ Internal, MultiDimensional ];

/// Section classes identified by name
Property Sections As array Of %CSP.PageSection [ Internal ];

/// Add new default section to the top of the stack of section identifiers.
Method PushDefaultSection(sectionblock As %String) [ Internal ]
{
 Set old=$o(i%DefaultSection(""),-1)
 Set new=$o(i%DefaultSection(""),-1)+1
 Set sectionblock=$tr(sectionblock,":")
 Set name=$p(sectionblock,",",1)
 Set block=+$p(sectionblock,",",2)
 If name="" Set name=$p(i%DefaultSection(old),",",1)
 Set sectionblock=name_","_block
 Set i%DefaultSection(new)=sectionblock
 Set i%DefaultSection=sectionblock
 Quit
}

/// Pop default section from the top of the stack of section identifiers.
Method PopDefaultSection() [ Internal ]
{
 Set last=$o(i%DefaultSection(""),-1)
 Kill i%DefaultSection(last)
 Set i%DefaultSection=$g(i%DefaultSection(last-1))
 Quit
}

/// Get section class for specified section identifier.
/// If no section identfier specified, the get section for default.
Method GetSection(sectionblock As %String) As %CSP.PageSection [ Internal ]
{
 If $g(sectionblock)="" Set sectionblock=i%DefaultSection
 If sectionblock="" Set sectionblock="*"
 Set name=$p(sectionblock,",",1)
 Set block=+$p(sectionblock,",",2)
 Set section=..Sections.GetAt(name)
 If section=$$$NULLOREF {
	If %compiler.PageLanguage="basic" {
		Set section=##class(%CSP.BasicPageSection).%New()
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Set section=##class(%CSP.MVBasicPageSection).%New()
	} Else {
		Set section=##class(%CSP.PageSection).%New()
	}
	Do ..Sections.SetAt(section,name)
 }
 Set section.Block=block
 Quit section
}

}
