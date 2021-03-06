# Source in default environment variables
. /demo/default_env.sh

# Source in all functions
. /demo/vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. /demo/initial_root_token
ROLE=short-ttl-${ROOT_ROLE}

PKI_PATH=${INTERMEDIATE_CA_PATH}

# Only try to create the role if it doesn't exist
vault read ${INTERMEDIATE_CA_PATH}/roles/${ROLE} &> /dev/null
if [ $? -gt 0 ];then
  create_role ${ROLE} ${PKI_PATH} ${DEMO_DOMAIN} ${INTERMEDIATE_CERT_TTL}
fi

create_issue_policy ${ROLE} ${PKI_PATH} ${ROOT_PKI_PATH}
echo $(green "Current vault token: ${VAULT_TOKEN}")
echo $(yellow "Shifting to lower privileged token")
# This sets the $TOKEN variable internally
create_token ${ROLE} ${DEFAULT_TOKEN_TTL}
VAULT_TOKEN=$(cat ${LOCAL_MOUNT}/token-${ROLE})
echo $(green "Current vault token: ${VAULT_TOKEN}")

COMMON_NAME=shortttl.${DEMO_DOMAIN}
issue_cert ${COMMON_NAME} 60 ${INTERMEDIATE_CA_PATH} ${ROLE}
echo

echo $(yellow "Testing certificate validity using openssl")
while true;do
  echo -n "$(date +%H:%M:%S): Verifying Certificate: " 
  verify ${COMMON_NAME}
  sleep 5
done
