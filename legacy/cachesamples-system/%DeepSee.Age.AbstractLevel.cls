/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This is the base class for the family of DeepSee age hierarchy level classes.<br/>
/// An age hierarchy class defines the behavior for a level within a hierarchy within 
/// a DeepSee dimension.<br/>
/// The class (non-package) part of a level class *must* be unique.
/// You will get an error when you attempt to compile a cube definition if this is not the case.
Class %DeepSee.Age.AbstractLevel Extends %DeepSee.Time.AbstractLevel [ Abstract, System = 3 ]
{

}
