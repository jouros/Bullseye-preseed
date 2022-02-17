#!/bin/bash


if [ "$1" == "-h" ]; then
         echo ""
         echo "Example: ./virt-install-debian-kickstart.sh -n debianX -d 'debian host' -p './debianX.qcow2' -l '/var/lib/libvirt/images/debian-11.2.0-amd64-netinst.iso' -e './preseed.cfg' 2>&1 | tee out.txt"
         exit 0
fi

if [ "$#" -lt  8 ]; then
	echo ""
        echo "Not enough parameters, check usage with -h"
        exit 9999 
fi

# DPATH is relational to Pool

while getopts n:d:p:l:e: flag
do
        case "${flag}" in
                n) NAME=${OPTARG};;
		d) DESCRIPTION=${OPTARG};;
                p) DPATH=${OPTARG};;
                l) LOCATION=${OPTARG};;
		e) SEED=${OPTARG};;
        esac
done

if [ ! -f "$SEED" ]; then
        echo ""
        echo "preseed.cfg DOES NOT exists: $SEED, check you parameter!" 
        exit 9998
fi

if [ ! -f "$LOCATION" ]; then
        echo ""
        echo "debian-11.2.0-amd64-netinst.iso DOES NOT exists: $LOCATION, check you parameter!" 
        exit 9997
fi

echo ""
echo "#################################################"
echo "Parameters:"
echo ""
echo "NAME        = $NAME";
echo "DESCRIPTION = $DESCRIPTION";
echo "DPATH       = $DPATH";
echo "LOCATION    = $LOCATION";
echo "SEED        = $SEED";
echo ""
echo "################################################"
echo "Starting..."

# no-reboot = stop after install
# debian: target_type=serial, ubuntu can have target_type=virtio
# debian: priority=critical, means that installer will stop only if it has 'critical' problem
# initrd-inject: preseed.cfg file will be injected to root /preseed.cfg
virt-install \
        --virt-type kvm \
        --connect qemu:///system \
        --name "$NAME" \
        --description "$DESCRIPTION" \
        --ram 1024 \
        --vcpus 1 \
        --disk path="$DPATH",pool=guest_images,size=100,format=qcow2,bus=virtio \
	--initrd-inject="$SEED" \
        --os-type linux \
        --network bridge=virbr0 \
        --graphics none \
        --debug \
        --noreboot \
        --console pty,target_type=serial \
	--location "$LOCATION,initrd=install.amd/initrd.gz,kernel=install.amd/vmlinuz" \
	--extra-args "auto console=tty0 console=ttyS0,115200n8 serial DEBIAN_FRONTEND=text priority=critical ks=file:/preseed.cfg" \
        --qemu-commandline='-smbios type=1' \
        --rng /dev/urandom \
	--clock offset=localtime
