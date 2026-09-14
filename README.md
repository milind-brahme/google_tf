# Hermes Agent on GCP Free Tier

Terraform configuration to deploy the [Hermes Agent](https://github.com/NousResearch/hermes-agent) on a
Google Cloud **Always Free** eligible `e2-micro` instance (2 shared vCPUs, 1 GB RAM, up to 30 GB standard
persistent disk) in `us-central1`, `us-east1`, or `us-west1`.

Because an `e2-micro` only has 1 GB of physical memory, the startup script configures a **2 GB swap file**
to prevent out-of-memory (OOM) errors during Python virtual environment provisioning and tool execution.
Hermes Agent delegates LLM inference to remote API endpoints (OpenRouter, Nous Portal, Gemini, Anthropic,
etc.), so a micro-tier instance is sufficient for hosting the agent daemon and gateway.

## Files

- `variables.tf` – input variables (project, region, zone, SSH user/key)
- `main.tf` – VPC, subnet, firewall, and the `e2-micro` instance with startup script
- `outputs.tf` – instance IP and ready-to-use SSH command
- `terraform.tfvars.example` – example variable values (copy to `terraform.tfvars`)

## Step-by-Step Instructions

1. **Create your `terraform.tfvars`:**

   ```hcl
   project_id     = "your-gcp-project-id"
   ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... you@example.com"
   ```

2. **Deploy infrastructure:**

   ```bash
   terraform init
   terraform apply
   ```

3. **Log in to the VM:**

   Wait 1–2 minutes after creation for the startup script to complete swap allocation and installer
   execution, then SSH in:

   ```bash
   ssh hermes@<INSTANCE_PUBLIC_IP>
   ```

4. **Run the interactive setup wizard:**

   Launch a `tmux` session so processes persist if you disconnect, then start configuration:

   ```bash
   tmux
   hermes setup
   ```

   During setup:
   - Select your LLM endpoint (e.g., OpenRouter, Anthropic, or Nous Portal OAuth).
   - Provide your API key and pick your default model.
   - Select terminal execution and tool policies.

5. **Start Hermes:**

   - For an **interactive CLI chat session**:

     ```bash
     hermes
     ```

   - For the **persistent messaging/webhook gateway** (Discord, Telegram, Slack):

     ```bash
     hermes gateway
     ```

## Notes

- Only one `e2-micro` instance per billing account/region is covered by the Always Free tier.
- `terraform.tfvars` is git-ignored since it contains your project ID and SSH public key; never commit
  real credentials or private keys.
