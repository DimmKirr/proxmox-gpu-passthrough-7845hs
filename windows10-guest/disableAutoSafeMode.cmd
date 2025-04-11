bcdedit /enum
bcdedit /copy {current} /d "Windows Safe Mode"

bcdedit /set {NEW_GUID} path \Windows\system32\winload.efi
bcdedit /set {NEW_GUID} recoveryenabled Yes
bcdedit /set {NEW_GUID} displaymessageoverride Recovery
bcdedit /set {NEW_GUID} safeboot minimal

bcdedit /timeout 5
bcdedit /default {current}
bcdedit /set {current} recoveryenabled No
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures
reagentc /disable
