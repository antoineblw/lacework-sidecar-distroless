#!/shared/bin/sh

# Copyright 2014-2021 Lacework Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
set -e

export PATH=$PATH:/shared/bin

#
# This script is meant for quick & easy sidecar install via:
#    1. export LaceworkAccessToken="ACCESS_TOKEN"
#    2. sh -c /var/lib/lacework-backup/lacework-sidecar.sh
#    Note: SERVER_URL is the Lacework Server URL specific to your region.
#          The environment variable LaceworkServerUrl will set this value.
#          If not provided, the US URL will be assumed.
#    Note: This script can also be used as an ENTRYPOINT script. It will exec
#          any arguments (aside from a legacy access token and -U SERVER_URL).
# For debugging set the environment variable LaceworkVerbose:
#    export LaceworkVerbose=true

# Agent version
VERSION=5.6.0.8352

TOKEN=""
SERVER_URL=""
#default server url
lw_server_url="https://api.lacework.net"

# extra protection for mktemp: when it fails - returns fallback value
mktemp_safe() {
	TMP_FN=$(mktemp -u -t "XXXXXX")
	if [ "$TMP_FN" = "" ]; then
		echo $2
	else
		FN="${TMP_FN}${1}"
		touch ${FN}
		echo "${FN}"
	fi
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

check_x64() {
	case "$(uname -m)" in
		*64)
			;;
		*)
			echo "ERROR: Lacework currently only supports 64bit platforms"
			exit 200
			;;
	esac
}

check_root_cert() {
	set +e
	echo "INFO: Checking for Go Daddy root certificate"
	GODADDY_ROOT_CERT=$(mktemp_safe .cert /tmp/godaddy.cert)
	LW_INSTALLER_KEY=$(mktemp_safe .cert /tmp/installer_key.cert)
	cat > ${GODADDY_ROOT_CERT} <<-'EOF'
	-----BEGIN CERTIFICATE-----
	MIIEfTCCA2WgAwIBAgIDG+cVMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYTAlVT
	MSEwHwYDVQQKExhUaGUgR28gRGFkZHkgR3JvdXAsIEluYy4xMTAvBgNVBAsTKEdv
	IERhZGR5IENsYXNzIDIgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTQwMTAx
	MDcwMDAwWhcNMzEwNTMwMDcwMDAwWjCBgzELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
	B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHku
	Y29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRpZmljYXRlIEF1
	dGhvcml0eSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv3Fi
	CPH6WTT3G8kYo/eASVjpIoMTpsUgQwE7hPHmhUmfJ+r2hBtOoLTbcJjHMgGxBT4H
	Tu70+k8vWTAi56sZVmvigAf88xZ1gDlRe+X5NbZ0TqmNghPktj+pA4P6or6KFWp/
	3gvDthkUBcrqw6gElDtGfDIN8wBmIsiNaW02jBEYt9OyHGC0OPoCjM7T3UYH3go+
	6118yHz7sCtTpJJiaVElBWEaRIGMLKlDliPfrDqBmg4pxRyp6V0etp6eMAo5zvGI
	gPtLXcwy7IViQyU0AlYnAZG0O3AqP26x6JyIAX2f1PnbU21gnb8s51iruF9G/M7E
	GwM8CetJMVxpRrPgRwIDAQABo4IBFzCCARMwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
	HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFDqahQcQZyi27/a9BUFuIMGU2g/eMB8GA1Ud
	IwQYMBaAFNLEsNKR1EwRcbNhyz2h/t2oatTjMDQGCCsGAQUFBwEBBCgwJjAkBggr
	BgEFBQcwAYYYaHR0cDovL29jc3AuZ29kYWRkeS5jb20vMDIGA1UdHwQrMCkwJ6Al
	oCOGIWh0dHA6Ly9jcmwuZ29kYWRkeS5jb20vZ2Ryb290LmNybDBGBgNVHSAEPzA9
	MDsGBFUdIAAwMzAxBggrBgEFBQcCARYlaHR0cHM6Ly9jZXJ0cy5nb2RhZGR5LmNv
	bS9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAWQtTvZKGEacke+1bMc8d
	H2xwxbhuvk679r6XUOEwf7ooXGKUwuN+M/f7QnaF25UcjCJYdQkMiGVnOQoWCcWg
	OJekxSOTP7QYpgEGRJHjp2kntFolfzq3Ms3dhP8qOCkzpN1nsoX+oYggHFCJyNwq
	9kIDN0zmiN/VryTyscPfzLXs4Jlet0lUIDyUGAzHHFIYSaRt4bNYC8nY7NmuHDKO
	KHAN4v6mF56ED71XcLNa6R+ghlO773z/aQvgSMO3kwvIClTErF0UZzdsyqUvMQg3
	qm5vjLyb4lddJIGvl5echK1srDdMZvNhkREg5L4wn3qkKQmw4TRfZHcYQFHfjDCm
	rw==
	-----END CERTIFICATE-----
	EOF
	reqsubstr="OK"

	if command_exists awk; then
		if command_exists openssl; then
			cert_path=`openssl version -d | grep OPENSSLDIR | awk -F: '{print $2}' | sed 's/"//g'`
			if [ -z "${cert_path}" ]; then
				cert_path="/etc/ssl"
			fi
			cert_ok=`openssl verify -x509_strict ${GODADDY_ROOT_CERT} 2>&1`
			if [ ! -z "${cert_ok##*$reqsubstr*}" ];	then
				openssl x509 -noout -in ${GODADDY_ROOT_CERT} -pubkey > ${LW_INSTALLER_KEY}
				cert_ok=`awk -v cmd='openssl x509 -noout -pubkey | cmp -s ${LW_INSTALLER_KEY}; if [ $? -eq 0 ]; then echo "installed"; fi' '/BEGIN/{close(cmd)};{print | cmd}' < ${cert_path}/certs/ca-certificates.crt`
				if [ "${cert_ok}" != "installed" ]; then
					echo "WARNING: Could not find Go Daddy root certificate"
				fi
			fi
		fi
	fi
	rm -f ${GODADDY_ROOT_CERT}
	rm -f ${LW_INSTALLER_KEY}
	set -e
}

get_serverurl_from_cfg_file() {
	if command_exists awk; then
		if [ -f /var/lib/lacework/config/config.json ]; then
			config_url=$(grep -v "#" /var/lib/lacework/config/config.json)
			config_url=$(echo $config_url | awk 'BEGIN {RS=","} match($0, /serverurl([^,]+)/) { print substr( $0, RSTART, RLENGTH )}')
			config_url=$(echo $config_url | awk 'BEGIN{ORS=""}{print $0}')
			config_url=$(echo $config_url | sed 's/[\} ]//g')
			config_url=$(echo $config_url | awk 'BEGIN {FS="\""} {print $3}')
			if [ ! -z "${config_url}" ]; then
				echo "${config_url}"
				return
			fi
		fi
	fi
	echo ""
}

read_lw_server_url() {
	cfg_url=$(get_serverurl_from_cfg_file)
	if [ ! -z "${cfg_url}" ]; then
		echo "INFO: Using serverurl already set in local config: ${cfg_url}"
		lw_server_url=${cfg_url}
		return
	fi
	if [ ! -z "$SERVER_URL" ];
	then
		lw_server_url=$SERVER_URL
	fi
}

check_lw_connectivity() {
	lw_cfg_url=$(get_serverurl_from_cfg_file)
	if [ -z "${lw_cfg_url}" ]; then
		lw_cfg_url="${lw_server_url}/upgrade/?name=datacollector&version=${VERSION}"
	fi

	set +e
	echo "INFO: Check connectivity to Lacework server"
	if command_exists awk; then
		if command_exists curl; then
			response=`curl -o /dev/null -w "%{http_code}" -sSL ${lw_cfg_url}`
		elif command_exists wget; then
			response=`wget -SO- ${lw_cfg_url} 2>&1 | grep 'HTTP/' | awk '{print $(NF-1)}'`
		elif command_exists busybox && busybox --list-modules | grep -q wget; then
			response="500"
			busybox wget -O- ${lw_cfg_url} 2>&1 > /dev/null
			if [ $? == 0 ]; then
				response="200"
			fi
		else
			echo "WARNING: Connectivity to ${lw_cfg_url} could not be verified"
			# Fake the response
			response="200"
		fi
		if [ "${response}" != "200" ]; then
			echo "WARNING: Unexpected response code from ${lw_cfg_url}: ${response}"
		fi
	fi
	set -e
}

check_root() {
	user=$(whoami)
	if [ "$user" != 'root' ]; then
		echo "ERROR: Please run as the root user"
		exit 500
	fi
}

get_lsb_dist() {
	# perform some very rudimentary platform detection
	if [ -z "$lsb_dist" ] && command_exists lsb_release; then
		lsb_dist="$(lsb_release -si)"
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
		lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
		lsb_dist='debian'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
		lsb_dist='fedora'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
		lsb_dist='oracleserver'
	fi
	if [ -z "$lsb_dist" ]; then
		if [ -r /etc/centos-release ] || [ -r /etc/redhat-release ]; then
			lsb_dist='centos'
		fi
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/system-release ]; then
		lsb_dist="$(cat /etc/system-release | cut -d " " -f 1)"
	fi

	# Convert to all lower
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
}

# Check if this is a forked Linux distro
check_forked() {
	# Check for lsb_release command existence, it usually exists in forked distros
	if command_exists lsb_release; then
		# Check if the `-u` option is supported
		set +e
		lsb_release -a -u > /dev/null 2>&1
		lsb_release_exit_code=$?
		set -e

		# Check if the command has exited successfully, it means we're in a forked distro
		if [ "$lsb_release_exit_code" = "0" ]; then
			# Print info about current distro
			echo "INFO: Using '${lsb_dist}' version '${dist_version}'"

			# Get the upstream release info
			lsb_dist=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'id' | cut -d ':' -f 2 | tr -d '[[:space:]]')
			dist_version=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[[:space:]]')

			# Print info about upstream distro
			echo "INFO: Upstream release is '${lsb_dist}' version '${dist_version}'"
		fi
	fi
}

get_dist_version() {
	case "$lsb_dist" in
		*ubuntu*)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
				dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
			fi
			;;
		*debian*)
			dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
			case "$dist_version" in
				8)
					dist_version="jessie"
					;;
				7)
					dist_version="wheezy"
					;;
			esac
			;;
		*oracleserver*)
			# need to switch lsb_dist to match yum repo URL
			lsb_dist="oraclelinux"
			dist_version="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//')"
			;;
		*fedora*|centos*|*redhatenterprise*|*scientific*)
			dist_version="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//')"
			;;
		*)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
			;;
	esac
}

die() {
	echo "ERROR: " "$@" >&2
	exit 1
}

setup_paths() {
	DisplayVer=$VERSION
	DCSUFFIX=-musl

	if [ ! -d "/var/lib/lacework/${DisplayVer}" ]; then
		mkdir -p "/var/lib/lacework/${DisplayVer}" || die "mkdir failed : /var/lib/lacework"
		cp /var/lib/lacework-backup/${DisplayVer}/datacollector${DCSUFFIX} "/var/lib/lacework/${DisplayVer}/datacollector" || die "cp failed : /var/lib/lacework"
		chmod +x /var/lib/lacework/${DisplayVer}/datacollector
	fi
	if [ ! -f "/var/lib/lacework/datacollector" ]; then
		ln -s "/var/lib/lacework/${DisplayVer}/datacollector" /var/lib/lacework/datacollector || die "ln failed : /var/lib/lacework"
	fi
	if [ ! -d "/var/lib/lacework/config" ]; then
		mkdir -p "/var/lib/lacework/config" || die "mkdir failed : /var/lib/lacework/config"
	fi
	if [ ! -d "/var/log/lacework" ]; then
		mkdir -p "/var/log/lacework" || die "mkdir failed : /var/log/lacework"
	fi
	# For k8s, the config directory is read only (configmap). Failing to change
	# the permissions prevents agent from starting. So ignore errors if any
	chown -R root:root /var/lib/lacework || true
	chown -R root:root /var/log/lacework || true
}

# Customized parameters
write_config() {
	if [ ! -f /var/lib/lacework/config/config.json ]; then
		rbacTokenLen="1-8"
		LwTokenShort=`echo "${TOKEN}" |cut -c${rbacTokenLen}`
		echo "INFO: Using access token: ${LwTokenShort}*** ..."
		echo "INFO: Using server url: $lw_server_url"
		echo "INFO: Writing configuration file"

		(set -x; $sh_c 'mkdir -p /var/lib/lacework/config')
		($sh_c 'echo "+ sh -c Writing config.json in /var/lib/lacework/config"')
		($sh_c "echo \"{\" > /var/lib/lacework/config/config.json")
		($sh_c "echo \" \\\"tokens\\\" : { \\\"AccessToken\\\" : \\\"${TOKEN}\\\" } \"    >> /var/lib/lacework/config/config.json")
		($sh_c "echo \" ,\\\"serverurl\\\" : \\\"${lw_server_url}\\\" \"    >> /var/lib/lacework/config/config.json")
		($sh_c "echo \"}\" >> /var/lib/lacework/config/config.json")
	else
		echo "INFO: Skipping writing config since a config file already exists"
	fi
}

# set permission of file
set_file_permissions() {
	set +e
	if [ -f /var/lib/lacework/config/config.json ]; then
	   chmod 640 /var/lib/lacework/config/config.json
	fi
	set -e
}

do_install() {
	check_x64

	sh_c='sh -c'
	check_root

	lsb_dist=''
	get_lsb_dist

	dist_version=''
	get_dist_version

	read_lw_server_url
	check_lw_connectivity
	check_root_cert

	# Check if this is a forked Linux distro
	check_forked

	echo "INFO: Installing on $lsb_dist ($dist_version)"

	write_config

	# Set config.json's permission to 0640
	set_file_permissions

	setup_paths

	cp /shared/lib/* /lib

	/var/lib/lacework/datacollector &

	if [ ! -z "${LaceworkVerbose}" ]; then
		touch /var/log/lacework/datacollector.log
		tail -f /var/log/lacework/datacollector.log &
	fi

	echo "INFO: Lacework successfully installed and Launched"
}

# Debug output and helpful environment settings.
if [ ! -z "${LaceworkVerbose}" ]; then
	set -x
	whoami
	if [ -f /etc/os-release ]; then
		cat /etc/os-release;
	fi
fi

# First try to find the access token via an environment variable.
if [ ! -z "${LaceworkAccessToken}" ]; then
	TOKEN=`echo ${LaceworkAccessToken} | grep -E '^[A-Za-z0-9][-_A-Za-z0-9]{10,55}[A-Za-z0-9]$' || true`
else
	echo "INFO: Access token not provided in LaceworkAccessToken environment variable"
fi

# Check if access token is passed as the first parameter
if [ -z "${TOKEN}" ]; then
	if [ "$#" -gt 0 ] && [ "${1}" = "${1#-}" ]; then
		TOKEN=`echo ${1} | grep -E '^[A-Za-z0-9][-_A-Za-z0-9]{10,55}[A-Za-z0-9]$' || true`
		if [ ! -z "${TOKEN}" ]; then
			# The first argument parsed as an access token.
			echo "INFO: Access token provided via commandline arguments"
			shift
		fi
	fi
fi

if [ ! -z "${LaceworkServerUrl}" ]; then
	SERVER_URL="${LaceworkServerUrl}"
fi

if [ "$#" -gt 1 ] && [ "${1}" = "-U" ]; then
	echo "INFO: Server url provided via commandline arguments"
	SERVER_URL=${2}
	shift
	shift
fi

# Require a token to be provided by an environment variable, parameter, or configuration.
if [ -z "${TOKEN}" ] && [ ! -f /var/lib/lacework/config/config.json ]; then
	echo "ERROR: Cannot find Lacework access token"
	exit 100
fi

do_install

echo "Docker RUN_CMD = $RUN_CMD"
$RUN_CMD

exit 0
