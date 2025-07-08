/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "GlobalMapping" activity within a Manifest document
Class %Installer.GlobalMapping Extends %Installer.Mapping [ ServerOnly = 1, System = 3 ]
{

/// Global to map
Property Global As %String(MAXLEN = 128) [ Required ];

/// Source database
Property From As %String [ Required ];

/// Collation to be used for this mapping.  Current codes are:
/// <li>5 - InterSystems IRIS Default</li>
/// <li>10 - German-1</li>
/// <li>11 - Portuguese-1</li>
/// <li>12 - Polish-1</li>
/// <li>13 - German-2</li>
/// <li>14 - Spanish-1</li>
/// <li>15 - Danish-1</li>
/// <li>16 - Cyrillic-1</li>
/// <li>17 - Greek-1</li>
/// <li>18 - Czech-1</li>
/// <li>19 - Czech-2</li>
/// <li>20 - Portuguese-2</li>
/// <li>21 - Finnish-1</li>
/// <li>22 - Japanese-1 (in japanese1.dat)</li>
/// <li>23 - Cyrillic-2</li>
/// <li>24 - Polish-2</li>
/// <li>25 - Chinese1 (reserved for future use)</li>
/// <li>26 - Chinese2 (in Chinese2.dat)</li>
/// <li>27 - French1</li>
/// <li>28 - Finnish2</li>
/// <li>29 - Hungarian1</li>
/// <li>30 - German3</li>
/// <li>31 - Polish3</li>
/// <li>32 - Spanish2</li>
/// <li>33 - Danish2</li>
/// <li>34 - Greek2</li>
/// <li>35 - Finnish3</li>
/// <li>36 - Lithuanian1</li>
/// <li>37 - Cyrillic3</li>
/// <li>38 - Slovenian1</li>
/// <li>39 - Slovenian2</li>
/// The collation is optional, in which case it will be 5, the default.
/// 
Property Collation As %Installer.Integer;

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.GlobalMapping(tNSName,$$$EVAL("_..Global_"),$$$EVAL("_..From_"),$$$EVAL("_..Collation_"))")
	Quit $$$OK
}

}
