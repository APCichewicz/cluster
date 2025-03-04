terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2024.12.1"
    }
  }
}

provider authentik {
  url = "https://authentik.local.001083.xyz"
  token = "sLeT9P3YIdcYIeNa39IS7TI2YeWRhGAgA4979JwDLlZkU3Ashvzq1YRWwWt1"
}

data "authentik_flow" "default-provider-authorization-implicit-consent" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_property_mapping_provider_scope" "scope-email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}

data "authentik_property_mapping_provider_scope" "scope-profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}

data "authentik_property_mapping_provider_scope" "scope-openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

resource "authentik_provider_oauth2" "grafana" {
  name          = "Grafana"
  client_id     = "rtrMrSqlL8TRZR6sEiiU8glYU1rlLBLtYUUWu5uC"
  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url = "https://grafana.local.001083.xyz/login/generic_oauth"
    }
  ]

  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow   = data.authentik_flow.default-provider-authorization-implicit-consent.id  
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "grafana" {
  name              = "Grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
}

resource "authentik_group" "grafana_admins" {
  name    = "Grafana Admins"
}

resource "authentik_group" "grafana_editors" {
  name    = "Grafana Editors"
}

resource "authentik_group" "grafana_viewers" {
  name    = "Grafana Viewers"
}
