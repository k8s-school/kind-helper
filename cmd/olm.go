/*
Copyright © 2023 Fabrice Jammes fabrice.jammes@k8s-school.fr
*/
package cmd

import (
	"github.com/k8s-school/kind-helper/scripts"
	"github.com/spf13/cobra"
)

// olmCmd represents the olm command
var olmCmd = &cobra.Command{
	Use:   "olm",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		logger.Info("Instal OLM")

		ExecCmd(scripts.OlmInstallScript)
	},
}

func init() {
	installCmd.AddCommand(olmCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// olmCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// olmCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
