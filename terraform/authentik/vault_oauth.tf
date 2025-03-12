resource "authentik_provider_oauth2" "vault" {
  name = "Vault"
  authorization_flow = data.authentik_flow.default-source-authentication.id
  invalidation_flow  = data.authentik_flow.default-source-enrollment.id

  client_id = "PuIEu9d9gKqUFTHFRTSh2kWoT52Mx3FPzNaJfsCp"
  client_secret = var.vault_oauth_secret
  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url = "https://vault.local.001083.xyz/ui/vault/auth/oidc/oidc/callback"
    },
    {
      matching_mode = "strict"
      url = "https://vault.local.001083.xyz/oidc/callback"
    },
    {
      matching_mode = "strict"
      url = "http://localhost:8250/oidc/callback"
    }
  ]
  client_type = "confidential"
}

resource "authentik_application" "vault" {
  name              = "Vault"
  slug              = "vault"
  protocol_provider = authentik_provider_oauth2.vault.id
}
