/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Stream class that stores XML character data in global nodes.
Class %XML.GlobalCharacterStream Extends %Library.GlobalCharacterStream [ System = 4 ]
{

/// XML element content "MIXED" for mixed="true" (default) and "STRING" or "ESCAPE" for mixed="false".
/// If CONTENT="STRING" XML special characters are put in a CDATA section during XML export.
/// If CONTENT="ESCAPE" XML special characters are escaped during XML export.
/// If CONTENT="ESCAPE-C14N" XML special characters are escaped during XML export using 
/// the translate table, XMLC, specified for XML Canonicalizaton.
/// The main difference is that CR is escaped as &amp;#13; 
Parameter CONTENT = "MIXED";

/// Controls the translate table used to escape content when CONTENT="MIXED" is specified.
Parameter ESCAPE [ Constraint = "HTML,XML", Flags = ENUM ] = "XML";

}
