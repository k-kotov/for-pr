terraform {
required_version = ">= 1.0"
}


# This template intentionally creates a large number of items via range()
# to reproduce the Terraform error:
# "Call to function \"range\" failed: more than 1024 values were generated"


locals {
# Increase to any value > 1024 to reproduce the error (e.g. 1500)
input_count = 1010


inputs = [for i in range(local.input_count) : {
idx = i
name = "item-${i}"
}]
}


resource "null_resource" "repro" {
# use for_each so Terraform evaluates the locals/range expression
for_each = { for item in local.inputs : item.idx => item }


triggers = {
idx = each.value.idx
name = each.value.name
}


provisioner "local-exec" {
# no-op: just demonstrate resource creation if it ever proceeds
command = "echo creating ${each.value.name}"
}
}
