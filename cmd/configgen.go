/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"log"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const KIND string = "kind"
const kindConfigFile = "/tmp/kind-config.yaml"

// configgenCmd represents the configgen command
var configgenCmd = &cobra.Command{
	Use:   "configgen",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		logger.Info("Generate kind configuration file")
		generateKindConfigFile()
	},
}

type KindConfig struct {
	PodSubnet string `mapstructure:"podsubnet"`
	LogLevel  string `mapstructure:"log_level"`
}

func init() {
	rootCmd.AddCommand(configgenCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// configgenCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// configgenCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func getKindConfig() KindConfig {

	var c KindConfig

	if err := viper.UnmarshalKey(KIND, &c); err != nil {
		logger.Fatalf("Error while getting kind configuration: %v", err)
	}

	return c
}

func generateKindConfigFile() {

	c := getKindConfig()
	f, e := os.Create(kindConfigFile)
	if e != nil {
		log.Fatal(e)
	}
	defer f.Close()
	log.Println(f)

	kindconfig := applyTemplate(c)
	f.WriteString(kindconfig)
}

func applyTemplate(sc KindConfig) string {

	// TODO check https://github.com/helm/helm/blob/main/pkg/chartutil/values.go

	cfgTpl := `kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true # disable kindnet
  {{- if not .Values.configmapReload.enabled }}
  checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  {{- end }}
  podSubnet: "{{ .PodSubnet }}" # set to Canal/Calico's default subnet
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    extraArgs:
      enable-admission-plugins: NodeRestriction,ResourceQuota
    certSANs:
      - "127.0.0.1"
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/lib/containerd
      containerPath: /var/lib/containerd
- role: worker
`

	kindconfig := format(cfgTpl, &sc)
	return kindconfig
}
