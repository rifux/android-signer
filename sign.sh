#!/usr/bin/bash

#
# Copyright (C) 2024 Blinkov `rifux` Vladimir ♪
#
# SPDX-License-Identifier: MIT
#

# Variables
script_dir_output="vendor/lineage-priv"
script_dir_backup="${HOME}/.android-signer-keys"
script_dir_android="$(pwd)"

input_info="/C=US/ST=California/L=San Francisco/O=Android Builder/OU=Building Dep./CN=android.org/emailAddress=user@localhost.localdomain"

certificates=(
    bluetooth
    cts_uicc_2021
    cyngn-app
    cyngn-priv-app
    media
    networkstack
    nfc
    platform
    otakey
    releasekey
    sdk_sandbox
    shared
    testcert
    testkey
    verity
    verifiedboot
)

apex_certificates=(
    com.android.adbd
    com.android.adservices.api
    com.android.adservices
    com.android.appsearch
    com.android.art
    com.android.bluetooth
    com.android.btservices
    com.android.cellbroadcast
    com.android.compos
    com.android.configinfrastructure
    com.android.connectivity.resources
    com.android.conscrypt
    com.android.devicelock
    com.android.extservices
    com.android.graphics.pdf
    com.android.hardware.biometrics.face.virtual
    com.android.hardware.biometrics.fingerprint.virtual
    com.android.hardware.boot
    com.android.hardware.cas
    com.android.hardware.wifi
    com.android.healthfitness
    com.android.hotspot2.osulogin
    com.android.i18n
    com.android.ipsec
    com.android.media
    com.android.mediaprovider
    com.android.media.swcodec
    com.android.nearby.halfsheet
    com.android.networkstack.tethering
    com.android.neuralnetworks
    com.android.ondevicepersonalization
    com.android.os.statsd
    com.android.permission
    com.android.resolv
    com.android.rkpd
    com.android.runtime
    com.android.safetycenter.resources
    com.android.scheduling
    com.android.sdkext
    com.android.support.apexer
    com.android.telephony
    com.android.telephonymodules
    com.android.tethering
    com.android.tzdata
    com.android.uwb
    com.android.uwb.resources
    com.android.virt
    com.android.vndk.current
    com.android.wifi
    com.android.wifi.dialog
    com.android.wifi.resources
    com.google.pixel.camera.hal
    com.google.pixel.vibrator.hal
    com.qorvo.uwb
)

# Text formatting
fmt_purple="\033[35m"
fmt_normal="\033[0m"
fmt_bold="\033[1m"

# Funtions
programm() {
    prompt_workdir
    echo
    prompt_outdir
    echo
    if [ -d "${script_dir_backup}" ]; then
        echo -e "Found keys backup at ${script_dir_backup}"
        if (confirm "Do you want to use them? "); then
            cp -rv ${script_dir_backup}/* ${script_dir_output}/keys
            return 0
        fi
        echo
    fi
    prompt_info
    echo
    gen_certs
    echo
    gen_vendor
    echo
    print_exit
    return 0
}

confirm() {
    read -e -r -p "$1(Y/n): " _confirm_input
    case "$_confirm_input" in
        [yY][eE][sS]|[yY]|"") return 0 ;;
        *) return 1 ;;
    esac
}

prompt_dir() {
    while true; do
        read -e -p "Enter $1 directory: " _prompt_dir
        if [ -d "$_prompt_dir" ]; then
            echo "$_prompt_dir"
            break
        else
            if ! (confirm "This directory does not exist. Do you want to create it? (Y/n): "); then
                continue
            fi
            mkdir -p ${_prompt_dir} && echo "$_prompt_dir"
            break
        fi
    done
}

prompt_workdir() {
    # Directory confirmation
    echo -e "Is ${fmt_bold}${fmt_purple}$(pwd)${fmt_normal}"
    if ! (confirm "right directory with ROM sources? "); then
        script_dir_android=$(prompt_dir "ROM sources")
    fi
}

prompt_outdir() {
    # Directory confirmation
    echo -e "Is ${fmt_bold}${fmt_purple}${script_dir_output}${fmt_normal}"
    if ! (confirm "right signing keys directory? "); then
        script_dir_output=$(prompt_dir "ROM sources")
    fi
}

prompt_info() {
    if (confirm "Do you want to customize the subject? "); then
        while true; do
            # Collecting info
            echo -e ""
            read -e -p "$(echo -e ${fmt_purple})Country Name (2 letter code)           $(echo -e ${fmt_normal})example 'US': "                       var_C
            read -e -p "$(echo -e ${fmt_purple})State or Province Name (full name)     $(echo -e ${fmt_normal})example 'California' or 'Germany': "  var_ST
            read -e -p "$(echo -e ${fmt_purple})Locality Name (eg, city)               $(echo -e ${fmt_normal})example 'San Francisco' or 'Tokyo': " var_L
            read -e -p "$(echo -e ${fmt_purple})Organization Name (eg, company)        $(echo -e ${fmt_normal})example 'Example Inc.': "             var_O
            read -e -p "$(echo -e ${fmt_purple})Organizational Unit Name (eg, section) $(echo -e ${fmt_normal})example 'IT Department': "            var_OU
            read -e -p "$(echo -e ${fmt_purple})Common Name                            $(echo -e ${fmt_normal})example 'example.com': "              var_CN
            read -e -p "$(echo -e ${fmt_purple})Email Address                          $(echo -e ${fmt_normal})example 'contact@example.com': "      var_emailAddress

            # Assembling given info
            local info="/C=${var_C}/ST=${var_ST}/L=${var_L}/O=${var_O}/OU=${var_OU}/CN=${var_CN}/emailAddress=${var_emailAddress}"

            # Data confirmation
            echo -e "\nIs given info correct:\n${fmt_bold}${fmt_purple}${info}${fmt_normal} ?"
            if confirm; then
                input_info=$info
                break
            else
                continue
            fi
        done
    fi
}

gen_certs() {
    echo "Generating certificates..."
    mkdir -pv ${script_dir_backup}

    for certificate in "${certificates[@]}" "${apex_certificates[@]}"; do
        echo | bash <(sed "s/2048/$size/" ./development/tools/make_key)  "$script_dir_backup"/"$certificate" "$input_info"
    done
}

gen_vendor() {
    # Setting up private vendor repo
    mkdir -pv ${script_dir_output}/keys
    cp -rv ${script_dir_backup}/* ${script_dir_output}/keys
    echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := ${script_dir_output}/keys/releasekey" > ${script_dir_backup}/keys.mk
    cat <<EOF > ${script_dir_backup}/keys/BUILD.bazel
    filegroup(
        name = "android_certificate_directory",
        srcs = glob([
            "*.pk8",
            "*.pem",
        ]),
        visibility = ["//visibility:public"],
    )
    cp -rv ${script_dir_backup}/* ${script_dir_output}/keys
EOF
}

print_exit() {
    # Signing
    echo -e "${fmt_purple}NOTICE:${fmt_normal} now generated keys stored at '$(pwd)/${script_dir_output}';\n        make sure '${script_dir_output}/keys/keys.mk' is included somewhere in sources;\n        otherwise, include it or add '-include ${script_dir_output}/keys/keys.mk' to your device mk file."
}

programm