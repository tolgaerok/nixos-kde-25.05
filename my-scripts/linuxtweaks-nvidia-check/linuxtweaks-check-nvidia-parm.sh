#!/bin/bash

echo -e "\n🧩 NVIDIA Kernel Module Parameters:"
cat /proc/driver/nvidia/params | grep -E "UsePage|StreamMemOP|InitializeSystemMemoryAllocations|DynamicPowerManagement|EnableMSI"

echo -e "\n🖼 DRM Modeset:"
sudo cat /sys/module/nvidia_drm/parameters/modeset

echo -e "\n📊 NVIDIA-SMI:"
nvidia-smi --query-gpu=name,driver_version,power.draw,power.limit,temperature.gpu --format=csv,noheader

echo -e "\n✅ Done."
