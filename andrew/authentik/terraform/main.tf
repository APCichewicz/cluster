terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.12.1"
    }
  }
}

provider "authentik" {
  url   = "https://auth.dunde.live"
  token = "Pglnp7EFIr57BSVsPb5qFM71qT4c6ixkVQuO5uTWreBG9rhXxoPHiqOgd2qu"
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes Cluster 2"
  local = true
}

data "authentik_group" "hr" {
  depends_on = [ authentik_source_ldap.name ]
  name = "hr"
}
data "authentik_flow" "default-invalidation-flow" {
  slug = "default-invalidation-flow"
}
data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}
# User Property Mappings - using only LDAP specific mappings
data "authentik_property_mapping_source_ldap" "user_mappings" {
  managed_list = [
    "goauthentik.io/sources/ldap/default-mail",
    "goauthentik.io/sources/ldap/default-name",
    "goauthentik.io/sources/ldap/openldap-cn",
    "goauthentik.io/sources/ldap/openldap-uid"
  ]
}

# Group Property Mappings
data "authentik_property_mapping_source_ldap" "group_mappings" {
  managed_list = [
    "goauthentik.io/sources/ldap/openldap-cn"
  ]
}

# Add individual mappings for AD mappings using separate data sources
data "authentik_property_mapping_source_ldap" "ad_given_name" {
  name = "authentik default Active Directory Mapping: givenName"
}

data "authentik_property_mapping_source_ldap" "ad_sn" {
  name = "authentik default Active Directory Mapping: sn"
}

# Update your LDAP resource to include the mappings
resource "authentik_source_ldap" "name" {
  name                    = "lldap"
  slug                    = "lldap"
  start_tls               = false
  additional_user_dn      = "ou=people"
  additional_group_dn     = "ou=groups"
  group_object_filter     = "(objectClass=groupOfUniqueNames)"
  group_membership_field  = "member"
  object_uniqueness_field = "uid"
  user_path_template      = "LDAP/users"
  server_uri              = "ldap://lldap-service:3890"
  bind_cn                 = "uid=admin,ou=people,dc=dunde,dc=live"
  bind_password           = "Aftermath5-_Everyone5-_Affluent5-_Goatskin"
  base_dn                 = "dc=dunde,dc=live"
  
  # Add the user property mappings
  property_mappings = concat(
    data.authentik_property_mapping_source_ldap.user_mappings.ids,
    [data.authentik_property_mapping_source_ldap.ad_given_name.id],
    [data.authentik_property_mapping_source_ldap.ad_sn.id]
  )
  
  # Add the group property mappings
  property_mappings_group =   data.authentik_property_mapping_source_ldap.group_mappings.ids
  password_login_update_internal_password = true 
  # Enable sync
  sync_users        = true
  sync_groups       = true
  enabled           = true
}




#####################################################
#################
# Block HR App
#################
#####################################################

resource "authentik_outpost" "outpost" {
  name = "auth-endpoint"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [
    authentik_provider_proxy.proxy.id
  ]
}

# Application
resource "authentik_policy_binding" "app-access-focus" {
  target = authentik_application.fooocus.uuid
  group  = data.authentik_group.hr.id
  order  = 0
}

resource "authentik_provider_proxy" "proxy" {
  name                  = "traefik2"
  mode =  "forward_single"                 
  external_host         = "https://fooocus.dunde.live"
  cookie_domain         = "dunde.live"
  access_token_validity = "hours=24"
  invalidation_flow     = data.authentik_flow.default-invalidation-flow.id
  authorization_flow    = data.authentik_flow.default-authorization-flow.id
}

resource "authentik_application" "fooocus" {
  name = "Fooocus"
  slug = "fooocus"
  protocol_provider = authentik_provider_proxy.proxy.id
}


###########################################################
# GRAFANA BLOCK
###########################################################
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
  #  Required. You can use the output of:
  #     $ openssl rand -hex 16
  client_id     = "2dbf98c039497f21c9d890049596899f"

  # Optional: will be generated if not provided
  client_secret = "f4b428f03f2e927e4786f32663dbc034"

  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow = data.authentik_flow.default-invalidation-flow.id

  allowed_redirect_uris = [{
	matching_mode = "strict",
	url = "https://grafana.dunde.live/login/generic_oauth",
	}]
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

###########################################################
# ARGOCD BLOCK
###########################################################
data "authentik_flow" "default-provider-invalidation" {
  slug = "default-invalidation-flow"
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_provider_oauth2" "argocd" {
  name          = "ArgoCD"
  #  Required. You can use the output of:
  #     $ openssl rand -hex 16
  client_id     = "d408b314019808a4bc1b767886205398"

  # Optional: will be generated if not provided
  client_secret = "787d539a1875f1d6e6e25445a7104c54"
  authorization_flow = data.authentik_flow.default-provider-authorization-implicit-consent.id
  invalidation_flow  = data.authentik_flow.default-provider-invalidation.id

  signing_key = data.authentik_certificate_key_pair.generated.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://argocd.dunde.live/api/dex/callback",
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]
}

resource "authentik_application" "argocd" {
  name              = "ArgoCD"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
}



