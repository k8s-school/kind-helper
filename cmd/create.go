/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

const kindConfigFile = "/tmp/kind-config.yaml"

func createKindConfig() {
	f, e := os.Create(kindConfigFile)
	if e != nil {
		log.Fatal(e)
	}
	defer f.Close()
	log.Println(f)

	kindconfig := `kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  "EphemeralContainers": true
kubeadmConfigPatches:
- |
  apiVersion: kubeadm.k8s.io/v1beta2
  kind: ClusterConfiguration
  metadata:
    name: config
  apiServer:
    certSANs:
    - "127.0.0.1"`

	f.WriteString(kindconfig)
}

func createCluster() {

	createKindConfig()

	var err_out error
	cmd_tpl := "kind create cluster --config %v"

	cmd := fmt.Sprintf(cmd_tpl, kindConfigFile)

	out, errout, err := Shellout(cmd)
	if err != nil {
		err_msg := fmt.Sprintf("error creating kind cluster: %v\n", err)
		err_out = errors.New(err_msg)
	}

	outmsg := OutMsg{
		cmd:    cmd,
		err:    err_out,
		out:    out,
		errout: errout}

	log.Printf("message: %v\n", outmsg)
}

// createCmd represents the create command
var createCmd = &cobra.Command{
	Use:   "create",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Create k8s cluster")
		createCluster()
	},
}

func init() {
	rootCmd.AddCommand(createCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// createCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// createCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
