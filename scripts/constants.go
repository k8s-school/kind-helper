package scripts

import (
	_ "embed"
)

//go:embed olm-install.sh
var OlmInstallScript string

//go:embed argocd-install.sh
var ArgoCDInstallScript string
