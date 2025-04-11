#!/bin/bash
# Currently it doesn't seem like this is even needed (as the host doesn't crash)
# So the hooks are empty
## Keeping it for future reference

VM_ID=$1
EXECUTION_PHASE=$2
GPU_DEVICE="0000:66:00.0"
AUDIO_DEVICE_1="0000:66:00.1"
ENCRYPTION_DEVICE="0000:66:00.2"
USB_CONTROLLER_DEVICE="0000:66:00.3"

USB_CONTROLLER_DEVICE2="0000:66:00.4"
AUDIO_COPROCESSOR_DEVICE="0000:66:00.5" # 1022:15e2
AUDIO_DEVICE_2="0000:66:00.6"           # 1022:15e3

GPU_HARDWARE_ID="1002 1900"

function log() {
  # Log to systemd journal (journalctl -t qm -f)
  echo "$EXECUTION_PHASE: $1" | tee >(systemd-cat -t qm)
}

function rescan_pci() {
  echo "1" >/sys/bus/pci/rescan
}

function get_driver_status() {
  local driver="$1"

  if ! lsmod | grep -E -q "${driver//-/_}|${driver//_/-}"; then
    log "Driver $driver (or its variant) is not loaded on the system. Can't continue."
    return 1
  fi
}

# Check if device is somewhat present
function get_device_status() {
  if [[ -d "/sys/bus/pci/devices/$GPU_DEVICE/" ]]; then
    log "OK: Device $GPU_DEVICE is present in the list of PCI devices"
  else
    log "ERROR: Device $GPU_DEVICE not found in PCI devices"
    return 1
  fi

  return 0
}

function get_driver_binding() {
  local device="$1"

  local driver=$(lspci -k -s "$device" | awk -F': ' '/Kernel driver in use:/ {print $2}')

  if [[ -z "$driver" ]]; then
    driver="none"
  fi

  echo "$driver"
}

function unbind_device() {
  local driver="$1"
  local device="$2"

  if [[ -f /sys/bus/pci/drivers/$driver/unbind ]]; then
    if [[ -L /sys/bus/pci/drivers/$driver/$device ]]; then
      log "Attempting to undbind $device from $driver"
      timeout 5s bash -c "echo $device >/sys/bus/pci/drivers/$driver/unbind" || log "Failed to unbind $device from $driver within timeout"
    else
      log "Device $device is not bound to $driver (OK)"
    fi
  else
    log "/sys/bus/pci/drivers/$driver/unbind not found (doesn't support unbind?)"
  fi
}

function bind_device() {
  local driver="$1"
  local device="$2"

  #  get_driver_status "$driver"
  if [[ -d "/sys/bus/pci/devices/$device/" ]]; then
    log "OK: $device is present in the list of PCI devices"
    if [[ -f /sys/bus/pci/drivers/$driver/bind ]]; then
      log "$device: Attempting to bind to $driver"
      echo "$device" >"/sys/bus/pci/drivers/$driver/bind"
    else
      log "$device: $driver bind file not found (no driver loaded?)"
    fi
  else
    log "$device: ERROR, not found in PCI devices"
  fi

}

function switch_driver() {
  local device=$1
  local driver_from=$2
  local driver_to=$3

  local driver=$(get_driver_binding "$device")
  if [[ "$driver" == "$driver_to" ]]; then
    log "$device: already bound to $driver_to"
  else
    log "$device: not bound to $driver_to. Changing to $driver_to"
    unbind_device "$driver_from" "$device"
    sleep 1

    # USB controller attachment to host crashes, so skipping for now. maybe driver is wrong?
    #    if [[ ! ("$device" == "$USB_CONTROLLER_DEVICE" && "$driver_to" == "xhci_hcd") ]]; then

    # Attach to new driver
    bind_device "$driver_to" "$device"
    sleep 1

    local driver=$(get_driver_binding "$device")
    log "$device bound to $(get_driver_binding "$driver")"
  fi

}

log "VM $VM_ID"

if [[ "$EXECUTION_PHASE" == "pre-start" ]]; then
  log "Skipping pre-start phase to avoid host crash"
  # USB Controller
  #  switch_driver "$USB_CONTROLLER_DEVICE" "xhci_hcd" "vfio-pci"
  #  switch_driver "$USB_CONTROLLER_DEVICE2" "xhci_hcd" "vfio-pci"

  #   Encryption Device
  #  switch_driver "$ENCRYPTION_DEVICE" "ccp" "vfio-pci"

  # Audio Coprocessor Device
  #  switch_driver "$AUDIO_COPROCESSOR_DEVICE" "snd_hda_intel" "vfio-pci"

  # Audio Device
  #  switch_driver "$AUDIO_DEVICE_1" "snd_hda_intel" "vfio-pci"

  # GPU
  #  switch_driver "$GPU_DEVICE" "amdgpu" "vfio-pci"

  #rescan_pci

########################################################################################################################
elif [[ "$EXECUTION_PHASE" == "post-stop" ]]; then
  log "Skipping post-stop phase to avoid host crash"
  # Encryption Device
  #  switch_driver "$ENCRYPTION_DEVICE" "vfio-pci" "ccp"
  #
  #  #  # Audio Coprocessor Device
  ##  switch_driver "$AUDIO_COPROCESSOR_DEVICE" "vfio-pci" "snd_hda_intel"
  #
  # Audio
  #switch_driver "$AUDIO_DEVICE_1" "vfio-pci" "snd_hda_intel"

  # GPU
  #switch_driver "$GPU_DEVICE" "vfio-pci" "amdgpu"

  #rescan_pci

#else
#...
fi
