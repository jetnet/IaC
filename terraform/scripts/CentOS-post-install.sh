#!/usr/bin/bash

#
# CentOS post-install setup script for an Azure VM
#

###
# Output function - print message with time stamp
output() {
    printf "%(%F %T)T - $*\n" -1
}

###
# Create swap file function
create_swap() {
    swapfile="/swapfile"
    if [ ! -f "${swapfile}" ]; then
        output "Creating 1Gb-swapfile: ${swapfile}"
        dd if=/dev/zero of=${swapfile} bs=1M count=1024 status=none
        chmod 600 ${swapfile}
        mkswap ${swapfile}
        swapon ${swapfile}

        FSTAB="/etc/fstab"
        [ "Xpermanent" = "X$1" ] && {
            grep -q "${swapfile}" ${FSTAB} || {
                output "Permanent swap: adding swapfile ${swapfile} to ${FSTAB}"
                echo "${swapfile} swap swap defaults 0 0" >> ${FSTAB}
            }
        }
    else
        output "Swap file already exists: ${swapfile}"
        [ "Xpermanent" = "X$1" ] && swapon -a
    fi
}

###
# Main

# Redirect all stderr to stdout
exec 2>&1

output "Post-install script started: $0"

# Must be run as root
ID=`id -u`
[ "X0" = "X${ID}" ] || {
  output "Script must be run as root. Current user ID: ${ID}"
  exit 1
}

# Run sudo without password for the admin user
SUDOERS_FILE="/etc/sudoers.d/waagent"
[ -f "${SUDOERS_FILE}" ] && {
    grep -q "NOPASSWD:" ${SUDOERS_FILE} || {
        output "Turning off sudo-password for admin user"
        sed -i -e 's/ ALL$/ NOPASSWD: ALL/' ${SUDOERS_FILE}
    }
}

# Fix issue with IPv6 DNS requests
NETWORK_FILE="/etc/sysconfig/network"
grep -q "RES_OPTIONS" ${NETWORK_FILE} || {
    output "Setting resolving options in ${NETWORK_FILE}"
    echo "RES_OPTIONS=single-request-reopen" >> ${NETWORK_FILE}
    ifdown eth0 && ifup eth0
}

# Disable IPv6
SYSCTL_FILE="/etc/sysctl.conf"
grep -q "disable_ipv6" ${SYSCTL_FILE} || {
    output "Disabling IPv6 in ${SYSCTL_FILE}"
    echo "net.ipv6.conf.all.disable_ipv6 = 1"     >> ${SYSCTL_FILE}
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> ${SYSCTL_FILE}
    sysctl -p -q
}

# Use IPv4 in yum
YUM_FILE="/etc/yum.conf"
grep -q "ip_resolve" ${YUM_FILE} || {
    output "Disable IPv6 for yum in ${YUM_FILE}"
    echo "ip_resolve=4" >> ${YUM_FILE}
}

# Create swap if total memomy less than 1Gb, otherwise yum update would fail
memsize=`free -t | grep "Total:" | awk '{print $2}'`
output "Total memory, kB: ${memsize}"
[ -n "${memsize}" ] && [ "${memsize}" -lt 1000000 ] && create_swap "permanent"

# Update packages and enable Extra Packages for Enterprise Linux (EPEL)
EPEL_PACKAGE="epel-release"
YUM_PARAMS="-y -q -e 1"
# The azure agent must be excluded from update, otherwise this running script will be killed
YUM_UPDATE_PARAMS="${YUM_PARAMS} --exclude=WALinuxAgent"
rpm -qa ${EPEL_PACKAGE} | grep -q ${EPEL_PACKAGE} || {
    output "Post-install update"
    yum update ${YUM_UPDATE_PARAMS}

    output "Enabling EPEL repo"
    yum install ${EPEL_PACKAGE} ${YUM_PARAMS}
    
    output "Update with EPEL repo"
    yum update ${YUM_UPDATE_PARAMS}
}

# Install extra packages
EXTRA_PACKAGES="jq whois"
for p in ${EXTRA_PACKAGES}; do
    rpm -qa ${p} | grep -q "${p}" || {
        output "Installing package $p"
        yum install ${p} ${YUM_PARAMS}
    }
done


# Install az-cli
p="azure-cli"
rpm -qa ${p} | grep -q "${p}" || {
    output "Installing package $p"
    #yum install centos-release-scl ${YUM_PARAMS}
    #yum install rh-python36 ${YUM_PARAMS}
    #scl enable rh-python36 bash
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat >> /etc/yum.repos.d/azure-cli.repo <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    yum install ${p} ${YUM_PARAMS}
}

# Install kubectl
p="kubectl"
rpm -qa ${p} | grep -q "${p}" || {
    output "Installing package $p"
    cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF
    yum install kubectl ${YUM_PARAMS}
}

output "Post-install script finished"