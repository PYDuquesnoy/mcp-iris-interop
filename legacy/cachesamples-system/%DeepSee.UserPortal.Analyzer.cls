/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// UserPortal version of Analyzer
Class %DeepSee.UserPortal.Analyzer Extends %DeepSee.UI.Analyzer [ System = 4 ]
{

/// If true, we are launched from the USER portal.
Parameter USERMODE = 1;

/// URL for Analyzer.
Parameter ANALYZERURL = "_DeepSee.UserPortal.Analyzer.zen";

Parameter DOCBOOKID = "D2ANLY_ch_intro";

}
