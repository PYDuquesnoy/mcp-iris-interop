/// A unit test class for Wasabi.Logic.Inventory.
/// To run this test:
/// do ##class(Wasabi.Logic.Test.InventoryTest).Run()
Class Wasabi.Logic.Test.InventoryTest Extends %UnitTest.TestCase
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

/// Tests GetAvailableQuantity - none.
Method TestNoneGetAvailableQuantity()
{
	try {
		// Get outlet.
		set outlet = ##class(Wasabi.Data.Outlet).%New()
		set status = outlet.%Save()
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
		set quantity = ##class(Wasabi.Logic.Inventory).GetAvailableQuantity(outlet, product)
		set ok = ..AssertEqualsViaMacro(0, 0, quantity, "availableQuantity")

		do ..CleanupOutlet(outlet)
		do ..CleanupProduct(product)
	} catch ex {
		do ..CleanupOutlet(outlet)
		do ..CleanupProduct(product)
		throw ex
	}
}

/// Tests GetAvailableQuantity - normal.
Method TestNormalGetAvailableQuantity()
{
	try {
		// Get outlet.
		set outlet = ##class(Wasabi.Data.Outlet).%New()
		set status = outlet.%Save()
		if $$$ISERR(status) { 
			$$$ThrowStatus(status)
		}
	
		// Get product.
		set product = ##class(Wasabi.Data.Product).%New()
		set status = product.%Save()
		if $$$ISERR(status) { 
			$$$ThrowStatus(status)
		}
	
		// Create OutletProduct.
		set outletProduct = ##class(Wasabi.Data.OutletProduct).%New()
		set quantity = 10
		set completedQuantity = 4
		set expectedAvailableQuantity = quantity - completedQuantity
		set outletProduct.Quantity = quantity
		set outletProduct.QuantityCommitted = completedQuantity
		set outletProduct.Product = product
		set outletProduct.Outlet = outlet
		set status = outletProduct.%Save()
		if $$$ISERR(status) { 
			$$$ThrowStatus(status)
		}
	
		// Test.
		set availableQuantity = ##class(Wasabi.Logic.Inventory).GetAvailableQuantity(outlet, product)
		set ok = ..AssertEqualsViaMacro(0, expectedAvailableQuantity, availableQuantity, "availableQuantity")
		if ('ok) {
			do ..LogMessage("availableQuantity: " _ availableQuantity)
			do ..LogMessage("expectedAvailableQuantity: " _ expectedAvailableQuantity)
		}
		do ..CleanupOutletProduct(outletProduct)
		//do ListAllObjects^%occRun(0)
		do ..CleanupOutlet(outlet)
		do ..CleanupProduct(product)
	} catch ex {
		do ..CleanupOutletProduct(outletProduct)
		do ..CleanupOutlet(outlet)
		do ..CleanupProduct(product)
		throw ex
	}
}

/// Cleans up an outlet.
Method CleanupOutlet(outlet As Wasabi.Data.Outlet) [ Private ]
{
	if ($get(outlet) '= "") {		
		set status = ##class(Wasabi.Data.Outlet).%DeleteId(outlet.%Id())
		do ..AssertStatusOKViaMacro(0, status, "outlet status")
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

/// Cleans up an outletProduct
Method CleanupOutletProduct(outletProduct As Wasabi.Data.OutletProduct) [ Private ]
{
	if ($get(outletProduct) '= "") {
		set status = ##class(Wasabi.Data.OutletProduct).%DeleteId(outletProduct.%Id())
		do ..AssertStatusOKViaMacro(0, status, "outletProduct status")
	}
}

}

