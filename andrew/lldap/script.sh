NAMESPACE=auth # in which namespace the lldap container will be installed, always use lowercase
LLDAP_JWT_SECRET=Pasture5-_Unfunded5-_Gorgeous5-_Native
LLDAP_LDAP_USER_PASS=Aftermath5-_Everyone5-_Affluent5-_Goatskin # change if wanted
LLDAP_BASE_DN=dc=dunde,dc=live # set your own is wanted

kubectl create secret generic lldap-credentials \
  --from-literal=lldap-jwt-secret=${LLDAP_JWT_SECRET} \
  --from-literal=lldap-ldap-user-pass=${LLDAP_LDAP_USER_PASS} \
  --from-literal=base-dn=${LLDAP_BASE_DN} \
  -n ${NAMESPACE} --dry-run=client -o yaml
