data "authentik_flow" "default-source-authentication" {
  slug = "default-source-authentication"
}
data "authentik_flow" "default-source-enrollment" {
  slug = "default-source-enrollment"
}

resource "authentik_source_oauth" "github" {
  name                = "Github"
  slug                = "github"
  authentication_flow = data.authentik_flow.default-source-authentication.id
  enrollment_flow     = data.authentik_flow.default-source-enrollment.id

  provider_type   = "github"
  consumer_key    = "Ov23licfzX3iwK2HedzP"
  consumer_secret = var.github_oauth_secret
}

resource "authentik_provider_oauth2" "github" {
  name = "Github"
  authorization_flow = data.authentik_flow.default-source-authentication.id
  invalidation_flow  = data.authentik_flow.default-source-enrollment.id

  client_id = authentik_source_oauth.github.consumer_key
  client_secret = authentik_source_oauth.github.consumer_secret
  jwt_federation_providers = [authentik_provider_oauth2.grafana.id]
  jwt_federation_sources = [authentik_source_oauth.github.uuid]
}