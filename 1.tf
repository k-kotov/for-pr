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

# Terraform template to simulate Celery/gevent-style blocking or timeout errors
# caused by concurrent network or I/O operations, similar to what appears in logs like:
#   gevent.monitor: Greenlet <Greenlet ...> appears to be blocked

locals {
  # Number of concurrent simulated tasks (adjust to increase concurrency)
  concurrent_tasks = 100

  urls = [for i in range(local.concurrent_tasks) : "https://httpbin.org/delay/${i % 5}"]
}

# Simulate network calls that can hang or timeout.
resource "null_resource" "gevent_block_repro" {
  for_each = toset(local.urls)

  triggers = {
    url = each.key
  }

  provisioner "local-exec" {
    # Each curl simulates a Celery task performing a slow I/O request.
    command = <<EOT
      echo "[Task $$] Starting request to ${each.key}";
      # Introduce random latency or failure to mimic blocking.
      ( curl -s -o /dev/null --max-time $((RANDOM % 20 + 5)) ${each.key} \
        && echo "[Task $$] Done: ${each.key}" ) \
        || echo "[Task $$] Timeout or network block on ${each.key}";
    EOT
  }
}

# Simulate CPU or I/O blocking using sleep — acts like a gevent greenlet stuck in a loop.
resource "null_resource" "gevent_cpu_block" {
  count = local.concurrent_tasks

  provisioner "local-exec" {
    command = <<EOT
      echo "[Task $$] Simulating CPU block...";
      # Tight loop or long sleep to emulate gevent starvation
      sleep $((RANDOM % 10 + 5));
      echo "[Task $$] Finished simulated blocking operation.";
    EOT
  }
}

# Recommended test run:
#   terraform init
#   terraform apply -parallelism=100
# Expected: Some tasks may timeout or hang due to simulated blocking,
#           mimicking Celery/gevent concurrency starvation or timeout behavior.

# You can increase `concurrent_tasks` or network delay to intensify the reproduction.
