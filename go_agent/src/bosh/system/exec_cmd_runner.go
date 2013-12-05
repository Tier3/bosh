package system

import (
	bosherr "bosh/errors"
	boshlog "bosh/logger"
	"bytes"
	"os/exec"
	"strings"
)

type execCmdRunner struct {
}

func NewExecCmdRunner() (cmRunner CmdRunner) {
	return execCmdRunner{}
}

func (run execCmdRunner) RunCommand(cmdName string, args ...string) (stdout, stderr string, err error) {
	return runCmd(cmdName, args, nil)
}

func (run execCmdRunner) RunCommandWithInput(input, cmdName string, args ...string) (stdout, stderr string, err error) {
	return runCmd(cmdName, args, func(cmd *exec.Cmd) {
		cmd.Stdin = strings.NewReader(input)
	})
}

func runCmd(cmdName string, args []string, cmdHook func(*exec.Cmd)) (stdout, stderr string, err error) {
	boshlog.Debug("Cmd Runner", "Running command: %s %s", cmdName, strings.Join(args, " "))

	cmd := exec.Command(cmdName, args...)
	cmdString := strings.Join(append([]string{cmdName}, args...), " ")

	stdoutWriter := bytes.NewBufferString("")
	stderrWriter := bytes.NewBufferString("")
	cmd.Stdout = stdoutWriter
	cmd.Stderr = stderrWriter

	if cmdHook != nil {
		cmdHook(cmd)
	}

	err = cmd.Start()
	if err != nil {
		err = bosherr.WrapError(err, "Starting command %s", cmdString)
		return
	}

	err = cmd.Wait()
	stdout = string(stdoutWriter.Bytes())
	stderr = string(stderrWriter.Bytes())

	boshlog.Debug("Cmd Runner", "Stdout: %s", stdout)
	boshlog.Debug("Cmd Runner", "Stderr: %s", stderr)
	boshlog.Debug("Cmd Runner", "Successful: %t", err == nil)

	if err != nil {
		err = bosherr.WrapError(err, "Running command: '%s', stdout: '%s', stderr: '%s'", cmdString, stdout, stderr)
	}
	return
}
