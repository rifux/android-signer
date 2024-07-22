#!/usr/bin/bash

#
# Copyright (C) 2024 Blinkov `rifux` Vladimir ♪
#
# SPDX-License-Identifier: MIT
#

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
mkdir -pv ~/.android-certs
for cert in bluetooth media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity verifiedboot; do \
    ./development/tools/make_key ~/.android-certs/$cert "$subject"; \
done

# SETTING UP PRIVATE VENDOR REPO
mkdir -pv vendor/lineage-priv
cp -rv ~/.android-certs vendor/lineage-priv/keys
echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey" > vendor/lineage-priv/keys/keys.mk
cat <<EOF > vendor/lineage-priv/keys/BUILD.bazel
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
echo -e "\n${fmt_purple}NOTICE:${fmt_normal} now generated keys stored at '$(pwd)/vendor/lineage-priv';\n        make sure 'vendor/lineage-priv/keys/keys.mk' is included somewhere in sources;\n        otherwise, iclude it or add '-include vendor/lineage-priv/keys/keys.mk' to your device mk file."
