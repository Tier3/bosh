package action

import (
	"testing"
	"errors"
	"github.com/stretchr/testify/assert"
)

type someTestAction struct {
	Value valueType
	Err error

	SubAction string
	SomeId int
	ExtraArgs argsType
}

type valueType struct {
	Id int
	Success bool
}

type argsType struct {
	User string `json:"user"`
	Password string `json:"pwd"`
	Id int `json:"id"`
}

func (a *someTestAction) IsAsynchronous() bool {
	return false
}

func (a *someTestAction) Run(payloadBytes []byte) (value interface{}, err error) {
	return
}

func (a *someTestAction) RunWithoutPayload(subAction string, someId int, extraArgs argsType) (value valueType, err error) {
	a.SubAction = subAction
	a.SomeId = someId
	a.ExtraArgs = extraArgs

	value = a.Value
	err = a.Err
	return
}

func TestRunnerRunParsesThePayload(t *testing.T) {
	runner := NewRunner()

	expectedValue := valueType{Id: 13, Success: true}
	expectedErr := errors.New("Oops")

	action := &someTestAction{Value: expectedValue, Err: expectedErr}
	payload := `{"arguments":["setup", 123, {"user":"rob:","pwd":"rob123","id":12}]}`

	value, err := runner.Run(action, []byte(payload))

	assert.Equal(t, value, expectedValue)
	assert.Equal(t, err, expectedErr)

	assert.Equal(t, action.SubAction, "setup")
	assert.Equal(t, action.SomeId, 123)
	assert.Equal(t, action.ExtraArgs, argsType{User: "rob", Password: "rob123", Id: 12})
}
