package cmd

import (
	"bytes"
	"os/exec"
)

const ShellToUse = "bash"

type OutMsg struct {
	cmd    string
	err    error
	out    string
	errout string
}

func Shellout(command string) (string, string, error) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd := exec.Command(ShellToUse, "-c", command)
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()
	return stdout.String(), stderr.String(), err
}
