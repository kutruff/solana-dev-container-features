#!/bin/bash
set -e

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# The install.sh script is the installation entrypoint for any dev container 'features' in this repository. 
#
# The tooling will parse the devcontainer-features.json + user devcontainer, and write 
# any build-time arguments into a feature-set scoped "devcontainer-features.env"
# The author is free to source that file and use it however they would like.
set -a
. ./devcontainer-features.env
set +a


if [ ! -z ${_BUILD_ARG_SOLANA} ]; then
    echo "Activating feature 'solana'"

    apt-get update
    apt-get -y install --no-install-recommends libudev-dev build-essential curl pkg-config libssl-dev
    # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>
    SOLANA_VERSION=${_BUILD_ARG_SOLANA_VERSION:-undefined}

    echo "${USERNAME}"    

    su - ${USERNAME} -c "$(curl -sSfL https://release.solana.com/v${SOLANA_VERSION}/install)"
    # sh -c "$(curl -sSfL https://release.solana.com/v${SOLANA_VERSION}/install)"
    export CARGO_HOME="/usr/local/cargo"
    export RUSTUP_HOME="/usr/local/rustup"
    export PATH=${CARGO_HOME}/bin:${PATH}

    cargo install spl-token-cli

    # bash -i -c 'solana config set --url localhost' 
    su - ${USERNAME} -c 'solana config set --url localhost'
    #bash -i -c 'solana config set --keypair $(pwd)/app/dapwords/test_wallets/deployer_wallet.json' 
    # npm i -g @project-serum/anchor-cli
    su - ${USERNAME} -c 'npm i -g @project-serum/anchor-cli'
    #npm i -g pnpm

    tee /usr/hello.sh > /dev/null \
    << EOF
    #!/bin/bash
    RED='\033[0;91m'
    NC='\033[0m' # No Color
    echo -e "\${RED}${GREETING}, \$(whoami)!"
    echo -e "\${NC}"
EOF

    chmod +x /usr/hello.sh
    sudo cat '/usr/hello.sh' > /usr/local/bin/hello
    sudo chmod +x /usr/local/bin/hello
fi


if [ ! -z ${_BUILD_ARG_COLOR} ]; then
    echo "Activating feature 'color'"

    # Build args are exposed to this entire feature set following the pattern:  _BUILD_ARG_<FEATURE ID>_<OPTION NAME>

    if [ "${_BUILD_ARG_COLOR_FAVORITE}" == "red" ]; then
        FAVORITE='\\033[0\;91m'
    fi

    if [ "${_BUILD_ARG_COLOR_FAVORITE}" == "green" ]; then
        FAVORITE='\\033[0\;32m'
    fi

    if [ "${_BUILD_ARG_COLOR_FAVORITE}" == "gold" ]; then
        FAVORITE='\\033[0\;33m'
    fi

    tee /usr/color.sh > /dev/null \
    << EOF
    #!/bin/bash
    NC='\033[0m' # No Color

    FAVORITE=${FAVORITE}
    echo -e "\${FAVORITE} This is my favorite color! \${NC}"
EOF

    chmod +x /usr/color.sh
    sudo cat '/usr/color.sh' > /usr/local/bin/color
    sudo chmod +x /usr/local/bin/color

fi