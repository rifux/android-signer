#!/usr/bin/bash

#
# Copyright (C) 2024 Blinkov `rifux` Vladimir ♪
#
# SPDX-License-Identifier: MIT
#

# DEFAULT VALUES
script_dir_output="vendor/lineage-priv"
script_dir_backup="${HOME}/.android-signer-keys"

# FORMATTING
fmt_purple="\033[35m"
fmt_normal="\033[0m"
fmt_bold="\033[1m"

# ADDITIONAL FUCTIONS
confirmation_check()
{
    if [[ $script_temp != "" && $script_temp != "y" && $script_temp != "Y" && $script_temp != "yes" ]]; then
        echo -e "\nUser hasn't confirmed the data. ${fmt_purple}Exiting...${fmt_normal}"
        exit
    fi
}

# DIRECTORY CONFIRMATION
echo -e "Is\n${fmt_bold}${fmt_purple}$(pwd)${fmt_normal}"
read -p "right directory with ROM sources? (Y/n): " script_temp
confirmation_check

# INFO COLLECTING
echo -e ""
read -p "$(echo -e ${fmt_purple})Country Name (2 letter code)           $(echo -e ${fmt_normal})example 'US': "                       var_C
read -p "$(echo -e ${fmt_purple})State or Province Name (full name)     $(echo -e ${fmt_normal})example 'California' or 'Germany': "  var_ST
read -p "$(echo -e ${fmt_purple})Locality Name (eg, city)               $(echo -e ${fmt_normal})example 'San Francisco' or 'Tokyo': " var_L
read -p "$(echo -e ${fmt_purple})Organization Name (eg, company)        $(echo -e ${fmt_normal})example 'Example Inc.': "             var_O
read -p "$(echo -e ${fmt_purple})Organizational Unit Name (eg, section) $(echo -e ${fmt_normal})example 'IT Department': "            var_OU
read -p "$(echo -e ${fmt_purple})Common Name                            $(echo -e ${fmt_normal})example 'example.com': "              var_CN
read -p "$(echo -e ${fmt_purple})Email Address                          $(echo -e ${fmt_normal})example 'contact@example.com': "      var_emailAddress

# ASSEMBLING GIVEN INFO
subject="/C=${var_C}/ST=${var_ST}/L=${var_L}/O=${var_O}/OU=${var_OU}/CN=${var_CN}/emailAddress=${var_emailAddress}"

# INFO CONFIRMATION
echo -e "\nIs given info correct:\n${fmt_bold}${fmt_purple}${subject}${fmt_normal} ?"
read -p "Y/n: " script_temp
confirmation_check

# GENERATING KEYS
echo -e "\n${fmt_bold}${fmt_purple}IMPORTANT NOTICE!:${fmt_normal} leave all password input fields empty;\n                   otherwise, signing will fail.\n"
sleep 4
mkdir -pv ${script_dir_backup}
for cert in bluetooth media networkstack nfc platform releasekey sdk_sandbox shared testcert cyngn-priv-app otakey testkey verity verifiedboot; do \
    ./development/tools/make_key ${script_dir_backup}/$cert "$subject"; \
done

# ASKING FOR OUTPUT DIR
echo -e "\nIs ${fmt_bold}${fmt_purple}${script_dir_output}${fmt_normal} right signing keys directory?"
read -p "Y/n: " script_temp
if [[ $script_temp != "" && $script_temp != "y" && $script_temp != "Y" && $script_temp != "yes" ]]; then
    echo -e ""
    while true; do
        read -p "Enter output directory: " script_dir_output
        if [ -d "$script_dir_output" ]; then
            break
        else
            read -p "This directory does not exist. Do you want to create it? (Y/n): " script_temp
            if [[ $script_temp != "" && $script_temp != "y" && $script_temp != "Y" && $script_temp != "yes" ]]; then
                continue
            fi
            break
        fi
    done
fi


# SETTING UP PRIVATE VENDOR REPO
mkdir -pv ${script_dir_output}/keys
cp -rv ${script_dir_backup}/* ${script_dir_output}/keys
echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := ${script_dir_output}/keys/releasekey" > ${script_dir_output}/keys/keys.mk
cat <<EOF > ${script_dir_output}/keys/BUILD.bazel
filegroup(
    name = "android_certificate_directory",
    srcs = glob([
        "*.pk8",
        "*.pem",
    ]),
    visibility = ["//visibility:public"],
)
EOF

# SIGNING
echo -e "\n${fmt_purple}NOTICE:${fmt_normal} now generated keys stored at '$(pwd)/${script_dir_output}';\n        make sure '${script_dir_output}/keys/keys.mk' is included somewhere in sources;\n        otherwise, include it or add '-include ${script_dir_output}/keys/keys.mk' to your device mk file."
