/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.action Extends Ens.Rule.Model.base [ Abstract, System = 3 ]
{

/// 
/// Overriden since actions is a choice and we can also have object properties in subclasses
/// 
/// Arguments:<br>
/// 
///     dynamicObject is the dynamic object with the values to be assigned to the new object.<br>
/// 
///     containerOref is the containing object instance when called from JSONImport.
ClassMethod %JSONNew(dynamicObject As %DynamicObject, containerOref As %RegisteredObject = "") As %RegisteredObject
{

    /*  Dynamic Object item number is one less than list

        and Count() is current number of inserted actions

        We may have either 'actions' or its subclass 'rule'.

    */

    if (containerOref.%IsA("Ens.Rule.Model.rule")) {

        set type =..actionSubClassType(dynamicObject,containerOref)

    } else {

        set type = dynamicObject.actions.%Get(containerOref.actions.Count()).type

    }

    set class = "Ens.Rule.Model."_type

    Return $classmethod(class,"%New")
}

/// 
/// identify current property object being correlated from the JSON object
ClassMethod actionSubClassType(dynamicObject As %DynamicObject, containerOref As %RegisteredObject = "") As %String [ Internal ]
{

    set numberDefined = 0

    /* Currently only need to support rule sub class */

    for property = "constraints","comments" {

        if dynamicObject.%IsDefined(property) {

            set defined(property) = $increment(numberDefined)

            set lastDefined = property

        }

    }

    if (numberDefined = 1) {

        set property = lastDefined

    } else {

        set property = ""

        set iterator = dynamicObject.%GetIterator()

        while (iterator.%GetNext(.property, .value)) {

            if $data(defined(property)) {

                /* take the first one that has not been fully correlated yet */

                if (dynamicObject.%Get(property).%Size()) > ($method($property(containerOref,property),"Count")) {

                    quit

                }

            }

        }

    }

    set type = dynamicObject.%Get(property).%Get(($method($property(containerOref,property),"Count"))).type

    return type
}

}
