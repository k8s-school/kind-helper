package cmd

import (
	"bytes"
	"io"
	"os"
	"os/exec"
	"strings"
	"text/template"
)

const ShellToUse = "bash"

func ExecCmd(command string) (string, string) {

	var stdoutBuf, stderrBuf bytes.Buffer
	if !dryRun {
		logger.Infof("Launch command: %v", command)
		cmd := exec.Command(ShellToUse, "-c", command)

		cmd.Stdout = io.MultiWriter(os.Stdout, &stdoutBuf)
		cmd.Stderr = io.MultiWriter(os.Stderr, &stderrBuf)

		err := cmd.Run()
		if err != nil {
			logger.Fatalf("cmd.Run() failed with %s\n", err)
		}
		logger.Infof("%v", stdoutBuf)
		logger.Infof("%v", stderrBuf)

	} else {
		logger.Infof("Dry run %s", command)
	}
	return stdoutBuf.String(), stderrBuf.String()
}
func format(s string, v interface{}) string {
	t, b := new(template.Template), new(strings.Builder)
	err := template.Must(t.Parse(s)).Execute(b, v)
	if err != nil {
		logger.Fatalf("Error while formatting string %s: %v", s, err)
	}
	return b.String()
}
