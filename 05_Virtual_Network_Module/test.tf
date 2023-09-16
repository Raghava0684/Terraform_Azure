module "module_test" {
    source = "./modules"
    prefix = "test"
    vnet_cidr_prefix = "10.60.0.0/16"
    subnet1_cidr_prefix = "10.60.1.0/24"
    rgname = "TestRG" 
    subnet = "TestSubnet"
    rglocation = "eastus"  
   
}