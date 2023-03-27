<#
.SYNOPSIS
Installs the BeyondCorp Remote Agent

.DESCRIPTION
This script installs the BeyondCorp Remote Agent on Windows using PowerShell.

.NOTES
Copyright 2021 Google LLC
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

.PARAMETER BeyondCorpUser
The user the BeyondCorp Remote Agent will run as. Default is "beyondcorp" if not specified.

.PARAMETER Uninstall
Uninstall BeyondCorp Remote Agent. No other parameters are required.

.EXAMPLE
.\install-beyondcorp.ps1 -BeyondCorpUser someuser

#>

[CmdletBinding()]
param(
    [string]$BeyondCorpUser = "beyondcorp",
    [switch]$Uninstall
)

$BEYONDCORP_REPOSITORIES = "gcr.io/appconnector-external-release"
$REMOTE_AGENT_REPOSITORY = "$($BEYONDCORP_REPOSITORIES)/appconnector_remote_cp"
$REMOTE_AGENT_TAG = "appconnector_dp_rollout_20220801_rc00"
$REMOTE_AGENT_INSTALLER_IMAGE = "$($REMOTE_AGENT_REPOSITORY):$($REMOTE_AGENT_TAG)"
$REMOTE_AGENT_RUNNER_TARGET_IMAGE = "$($REMOTE_AGENT_REPOSITORY):$($REMOTE_AGENT_TAG)"
$REMOTE_AGENT_RUNNER_STABLE_IMAGE = "$($REMOTE_AGENT_REPOSITORY):$($REMOTE_AGENT_TAG)"
$REMOTE_AGENT_INSTALLER_ENTRYPOINT = "/applink_control_runtime/bin/install"
$REMOTE_AGENT_CONTAINER = "bce-control-runtime"
$BEYONDCORP_CONTAINERS = @($REMOTE_AGENT_CONTAINER, "bce-connector", "bce-logagent")
$BEYONDCORP_SERVICE = "beyondcorp"
$BEYONDCORP_DIR = "C:\Program Files\BeyondCorp"

$COLOR_GREEN = [console]::ForegroundColor = "Green"
$COLOR_RED = [console]::ForegroundColor = "Red"
$COLOR_RESET = [console]::ResetColor()

function INFO {
  param([string]$message)
  Write-Host "INFO: $message"
}

function WARN {
  param([string]$message)
  Write-Host "WARN: $message"
}

function ERROR {
  param([string]$message)
  Write-Host "ERROR: $message" -ForegroundColor Red
}

function FATAL {
  param([string]$message)
  Write-Host "FATAL: $message" -ForegroundColor Red
  exit 1
}

function repeat {
  param([string]$char, [int]$count)
  $char * $count
}

function title {
  param([string]$text)
  $len = $text.Length
  repeat "#" ($len + 4)
  Write-Host "# $text #" -ForegroundColor Green
  repeat "#" ($len + 4)
}

function forbid_empty_flag {
  param(
    [string]$value,
    [string]$flagName
  )
  if ([string]::IsNullOrEmpty($value)) {
    ERROR "Empty flag '$flagName' is forbidden."
    echo
    usage
    exit 1
  }
}

function install_complete_message {
  $message = @"
###############################################################################
# BeyondCorp Remote Agent has been successfully installed and started.        #
# Please run the following command to finish enrolling the remote agent:      #
# bce-connctl init                                                           #
#                                                                             #
# Other BeyondCorp service commands:                                          #
# --------------------------------------------------------------------------- #
# Stop service:                                                                 #
# & "sc.exe" stop "beyondcorp"                                                  #
