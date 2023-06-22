/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

func createCluster() {

	generateKindConfigFile()

	cmd_tpl := "kind create cluster --config %v"

	cmd := fmt.Sprintf(cmd_tpl, kindConfigFile)

	ExecCmd(cmd)
}

// createCmd represents the create command
var createCmd = &cobra.Command{
	Use:   "create",
	Short: "Create a kind cluster",
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
