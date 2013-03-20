set -eux

DEVSTACKVM=$(xe vm-list name-label=DevStackOSDomU --minimal)

for VBD in $(xe vbd-list vm-uuid=$DEVSTACKVM --minimal |  sed -e 's/,/ /g')
do
    DEVICE=$(xe vbd-param-get uuid=$VBD param-name=device)
    if [ "$DEVICE" != "xvda" ]
    then
        xe vbd-unplug uuid=$VBD
        VDI=$(xe vbd-param-get uuid=$VBD param-name=vdi-uuid)
        xe vbd-destroy uuid=$VBD
        xe vdi-destroy uuid=$VDI
    fi
done

LOCALSR=$(xe sr-list name-label="Local storage" --minimal)
EXTRA_VDI=$(xe vdi-create name-label=extra-disk-for-os-volumes virtual-size=20GiB sr-uuid=$LOCALSR type=user)
EXTRA_VBD=$(xe vbd-create vm-uuid=$DEVSTACKVM vdi-uuid=$EXTRA_VDI device=autodetect)
xe vbd-plug uuid=$EXTRA_VBD
DEVICE=$(xe vbd-param-get uuid=$EXTRA_VBD param-name=device)

[ "xvdb" = "$DEVICE" ]
