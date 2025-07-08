/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occInclude

/// 
/// Traits projection
/// 
Class %SYS.Python.Traits Extends %Projection.AbstractProjection [ System = 2 ]
{

/// Defines the IRIS class we're providing traits for
Parameter TARGETSPEC As %String;

/// 
/// Inject traits for this class
/// 
ClassMethod CreateProjection(class As %String, ByRef params As %String) As %Status
{
    #dim status As %Status = $$$OK
    Try {
        Set targetspec = $GET(params("TARGETSPEC"))

        // Iterate over methods in the target class and generate entries in ^%SYS("Python","Mapper")
        If targetspec="" {
           Set status = $$$ERROR($$$GeneralError,"Invalid TARGETSPEC parameter compiling "_class)
           Quit
        }

        Set def = ##class(%Dictionary.CompiledClass).%OpenId(class,,.status)
        Quit:$$$ISERR(status)

        Set matchspec = ""

        // Iterate over the methods
        For n = 1:1:def.Methods.Count() {
            Set method = def.Methods.GetAt(n)

            If 'method.ClassMethod {
               Continue
            }

            Set status = $$gettagrtn^%occDescriptor(class,method.Name,method.RtnLabel,.tag,.rtn)
            Quit:$$$ISERR(status)

            Set matchspec = matchspec _ $LB(method.Name_":"_tag_"^"_rtn)
        }

        Quit:$$$ISERR(status)

        For n = 1:1:$L(targetspec,",") {
            Set target = $P(targetspec,",",n)
            If '##class(%ClassDefinition).%ExistsId(target) {
                Set status = $$$ERROR($$$ClassDoesNotExist,target)
                Quit
            }

            Set ^oddPYTHON(target) = $LTS(matchspec)
        }

    } Catch (exception) {
        Set status = exception.AsStatus()
    }

    Quit status
}

/// 
/// Remove traits for a class
/// 
ClassMethod RemoveProjection(class As %String, ByRef params As %String, recompile As %Boolean) As %Status
{
    #dim status As %Status = $$$OK
    Try {

        Set targetspec = $GET(params("TARGETSPEC"))

        If targetspec="" {
           Set status = $$$ERROR($$$GeneralError,"Invalid TARGETSPEC parameter uncompiling "_class)
           Quit
        }

        // Remove the injected methods
        For n = 1:1:$L(targetspec,",") {
            Set target = $P(targetspec,",",n)
            If '##class(%ClassDefinition).%ExistsId(target) {
                Continue
            }

            Kill ^oddPYTHON(target)
        }


    } Catch (exception) {
        Set status = exception.AsStatus()
    }

    Quit status
}

}
