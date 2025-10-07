variable "run_id" {
  default = "56"
sesitive = true
  
}


variable "sleep_time" {
  default = 60
}

resource "null_resource" "resource2" {
  count = 5
  provisioner "local-exec" {
    command = "echo $ENV"
    environment = {
      ENV = "Hello World!"
    }
 }
}
