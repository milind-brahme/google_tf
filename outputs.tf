output "instance_ip" {
  description = "Public IP address of the Hermes VM"
  value       = google_compute_instance.hermes_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Command to connect to your Hermes instance"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.hermes_vm.network_interface[0].access_config[0].nat_ip}"
}
