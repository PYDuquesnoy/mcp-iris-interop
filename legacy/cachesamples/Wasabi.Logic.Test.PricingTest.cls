/// A unit test class for Wasabi.Logic.Pricing.
/// To run this test:
/// do ##class(Wasabi.Logic.Test.PricingTest).Run()
Class Wasabi.Logic.Test.PricingTest Extends %UnitTest.TestCase
{

/// Runs this test.
ClassMethod Run() As %Status
{
	write "Running test", !
	set className = ..%ClassName(1)
	set testcase = className
	set testsuite = className
	set testspec = testsuite _ ":" _ testcase
	set qualifiers = "/load=0/recursive=0"
	set status = ##class(%UnitTest.Manager).RunTest(testspec, qualifiers)
	quit status
}

Method OnBeforeOneTest() As %Status
{
	set status = 1
	quit status
}

Method OnAfterOneTest() As %Status
{
	set status = 1
	quit status
}

/// Tests LookupPrice - some.
Method TestNoneLookupPrice()
{
	try {
		// Get catalog.
		set catalog = ##class(Wasabi.Data.PriceCatalog).%New()
		set status = catalog.%Save()
		if $$$ISERR(status) { 
			$$$ThrowStatus(status)
		}
	
		// Get product.
		set product = ##class(Wasabi.Data.Product).%New()
		set status = product.%Save()
		if $$$ISERR(status) { 
			$$$ThrowStatus(status)
		}
	
		// Test.
		set ex2 = ""
		try {
			set price = ##class(Wasabi.Logic.Pricing).LookupPrice(catalog, product)
		} catch ex2 {
			do ..LogMessage("Caught expected exception: " _ ex2.DisplayString())
		}
		if (ex2 = "") {
			set status = $$$ERROR($$$GeneralError, "Exception expected")
			set ok = ..AssertStatusOKViaMacro(0, status, "status")
		}
		do ..CleanupCatalog(catalog)
		do ..CleanupProduct(product)
	} catch ex {
		do ..CleanupCatalog(catalog)
		do ..CleanupProduct(product)
		throw ex
	}
}

/// Cleans up a catalog.
Method CleanupCatalog(catalog As Wasabi.Data.PriceCatalog) [ Private ]
{
	if ($get(catalog) '= "") {		
		set status = ##class(Wasabi.Data.PriceCatalog).%DeleteId(catalog.%Id())
		do ..AssertStatusOKViaMacro(0, status, "catalog status")
	}
}

/// Cleans up a product.
Method CleanupProduct(product As Wasabi.Data.Product) [ Private ]
{
	if ($get(product) '= "") {
		set status = ##class(Wasabi.Data.Product).%DeleteId(product.%Id())
		do ..AssertStatusOKViaMacro(0, status, "product status")
	}
}

}

