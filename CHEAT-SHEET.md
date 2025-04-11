# Troubleshooting Command Cheat Sheet
This document contains commands to help with common troubleshooting tasks

## Proxmox
### Get devices current drivers
```shell
lspci -nnk | grep -A3 "66:00.[0123456]"
```

### Get IOMMU Grouping
```shell
for d in /sys/kernel/iommu_groups/*/devices/0000\:66\:*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf 'IOMMU Group %s ' "$n"
  lspci -nns "${d##*/}"
done
```

## Windows Guest
### Reboot from Windows Safe Mode Cmd
```cmd
wpeutil reboot
```
