/*
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
*/

terraform {
required_version = ">= 1.0"
}


# Terraform template to simulate concurrent or network-intensive operations
# that may cause gevent-like blocking or timeout behavior when executed
# in parallel (e.g., Celery or OpenTofu worker tasks with network IO).


locals {
# Adjust to simulate concurrency (e.g. 50-200)
concurrent_requests = 50


urls = [for i in range(local.concurrent_requests) : "https://example.com/file-${i}.bin"]
}


# Dummy resource to simulate network-heavy operations via local-exec
# Each resource tries to download a file concurrently.
resource "null_resource" "network_repro" {
for_each = toset(local.urls)


triggers = {
url = each.key
}


provisioner "local-exec" {
# Simulate long network operations with curl
command = <<EOT
echo "Simulating network request for ${each.key}";
curl -s -o /dev/null --max-time 300 ${each.key} || echo "Timeout on ${each.key}";
EOT
}
}


# Optional: Artificial delay to simulate I/O blocking
resource "null_resource" "sleep_repro" {
count = local.concurrent_requests


provisioner "local-exec" {
command = "sleep $((RANDOM % 10 + 1)) && echo Sleep done for ${count.index}"
}
}
